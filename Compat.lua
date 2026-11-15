-- TinyHunterStats Compatibility Layer
-- Provides version-specific API wrappers for different WoW versions

local Compat = {}
TinyHunterStats = TinyHunterStats or {}
TinyHunterStats.Compat = Compat

-- Version detection
local function GetWoWVersion()
    local version, build, date, tocVersion = GetBuildInfo()
    local projectID = WOW_PROJECT_ID or 0

    -- WOW_PROJECT_ID constants:
    -- WOW_PROJECT_MAINLINE = 1 (Retail)
    -- WOW_PROJECT_CLASSIC = 2 (Classic)
    -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5 (TBC Classic)
    -- WOW_PROJECT_WRATH_CLASSIC = 11 (Wrath Classic)
    -- WOW_PROJECT_CATACLYSM_CLASSIC = 14 (Cata Classic)
    -- WOW_PROJECT_MOP_CLASSIC = 16 (MoP Classic, older clients)
    -- WOW_PROJECT_CAMELOT = 18 (WoW Forever)
    -- WOW_PROJECT_MISTS_CLASSIC = 19 (MoP Classic)

    if projectID == 1 then
        return "RETAIL"
    elseif projectID == 2 then
        return "CLASSIC"
    elseif projectID == 5 then
        return "TBC_CLASSIC"
    elseif projectID == 11 then
        return "WRATH_CLASSIC"
    elseif projectID == 14 then
        return "CATA_CLASSIC"
    elseif projectID == 16 or projectID == 19 then
        return "MOP_CLASSIC"
    elseif projectID == 18 then
        return "FOREVER"
    else
        -- Fallback: try to detect from tocVersion
        if tocVersion >= 120000 then
            return "RETAIL"
        elseif tocVersion >= 50000 then
            return "MOP_CLASSIC"
        elseif tocVersion >= 40000 then
            return "CATA_CLASSIC"
        elseif tocVersion >= 30000 then
            return "WRATH_CLASSIC"
        elseif tocVersion >= 20000 then
            return "TBC_CLASSIC"
        elseif tocVersion >= 16000 then
            return "FOREVER"
        elseif tocVersion >= 10000 then
            return "CLASSIC"
        else
            return "UNKNOWN"
        end
    end
end

local WoWVersion = GetWoWVersion()
Compat.WoWVersion = WoWVersion

-- Specializations exist on these clients only
local HAS_SPEC = WoWVersion == "RETAIL" or WoWVersion == "MOP_CLASSIC" or WoWVersion == "FOREVER"

-- Secret values (Midnight and WoW Forever): stat getters can return values
-- that addons must not compare or calculate with. issecretvalue does not
-- exist on older clients.
local issecretvalue = issecretvalue or function() return false end

-- Returns nil if the arguments of pcall failed or any result is secret
local function CheckResults(ok, ...)
    if not ok then
        return nil
    end
    for i = 1, select("#", ...) do
        if issecretvalue((select(i, ...))) then
            return nil
        end
    end
    return ...
end

-- Helper function to safely call APIs, returns the first result
-- (nil if the function is missing, errors or returns a secret value)
local function SafeCall(func, ...)
    if func then
        return (CheckResults(pcall(func, ...)))
    end
    return nil
end

-- Same as SafeCall, but returns all results
local function SafeCallMulti(func, ...)
    if func then
        return CheckResults(pcall(func, ...))
    end
    return nil
end

-- Remembers the last readable results per key. While a stat is unreadable
-- (secret in combat) the last known values are returned instead.
local lastKnown = {}
local function Keep(key, ...)
    if (...) ~= nil then
        lastKnown[key] = { n = select("#", ...), ... }
        return ...
    end
    local last = lastKnown[key]
    if last then
        return unpack(last, 1, last.n)
    end
    return ...
end

-- True while unit stats are returned as secret values
function Compat.StatsAreSecret()
    local func = C_Secrets and C_Secrets.ShouldUnitStatsBeSecret
    return func and SafeCall(func) or false
end

-- Looks up an API in C_SpecializationInfo first, then as a legacy global
local function GetSpecAPI(name)
    local info = C_SpecializationInfo
    return (info and info[name]) or _G[name]
end

-- Attack Power (Ranged)
function Compat.GetAttackPower(isRanged)
    local func = isRanged and UnitRangedAttackPower or UnitAttackPower
    local base, buff, debuff = Keep(isRanged and "rangedap" or "ap", SafeCallMulti(func, "player"))
    return (base or 0) + (buff or 0) + (debuff or 0)
end

-- Crit Chance (Ranged)
function Compat.GetCritChance(isSpell)
    if isSpell then
        -- Spell crit (not used by hunter, but kept for compatibility)
        local critchance
        for i = 2, 7 do
            local crit = SafeCall(GetSpellCritChance, i)
            if crit and (not critchance or crit > critchance) then
                critchance = crit
            end
        end
        return Keep("spellcrit", critchance) or 0
    else
        -- Ranged crit
        return Keep("rangedcrit", SafeCall(GetRangedCritChance, "player")) or 0
    end
end

-- Ranged Weapon Speed
function Compat.GetRangedSpeed()
    if SafeCall(IsRangedWeapon) then
        local speed = Keep("rangedspeed", SafeCall(UnitRangedDamage, "player"))
        if speed and speed > 0 then
            return string.format("%.2f", speed)
        end
    end
    return nil
end

-- Power Regeneration (Focus, Energy, etc.)
function Compat.GetPowerRegen()
    local regen = Keep("powerregen", SafeCall(GetPowerRegen))
    return regen or 0
end

-- Specialization
function Compat.GetActiveSpecGroup()
    if HAS_SPEC then
        local group = SafeCall(GetSpecAPI("GetActiveSpecGroup"))
        if group == 1 or group == 2 then
            return group
        end
    end
    -- Classic: Always return 1 (no dual spec)
    return 1
end

return Compat
