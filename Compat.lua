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
    -- WOW_PROJECT_MOP_CLASSIC = 16 (MoP Classic)
    
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
    elseif projectID == 16 then
        return "MOP_CLASSIC"
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
        elseif tocVersion >= 10000 then
            return "CLASSIC"
        else
            return "UNKNOWN"
        end
    end
end

local WoWVersion = GetWoWVersion()
Compat.WoWVersion = WoWVersion

-- Helper function to safely call APIs
local function SafeCall(func, ...)
    if func then
        local success, result = pcall(func, ...)
        if success then
            return result
        end
    end
    return nil
end

-- Attack Power (Ranged)
function Compat.GetAttackPower(isRanged)
    if isRanged then
        local base, buff, debuff = UnitRangedAttackPower("player")
        return (base or 0) + (buff or 0) + (debuff or 0)
    else
        local base, buff, debuff = UnitAttackPower("player")
        return (base or 0) + (buff or 0) + (debuff or 0)
    end
end

-- Crit Chance (Ranged)
function Compat.GetCritChance(isSpell)
    if isSpell then
        -- Spell crit (not used by hunter, but kept for compatibility)
        local critchance = 0
        for i = 2, 7 do
            local crit = SafeCall(GetSpellCritChance, i)
            if crit and crit > critchance then
                critchance = crit
            end
        end
        return critchance
    else
        -- Ranged crit
        local crit = SafeCall(GetRangedCritChance, "player")
        return crit or 0
    end
end

-- Ranged Weapon Speed
function Compat.GetRangedSpeed()
    if SafeCall(IsRangedWeapon) then
        local speed = SafeCall(UnitRangedDamage, "player")
        if speed and speed > 0 then
            return string.format("%.2f", speed)
        end
    end
    return nil
end

-- Power Regeneration (Focus, Energy, etc.)
function Compat.GetPowerRegen()
    local regen = SafeCall(GetPowerRegen)
    return regen or 0
end

-- Specialization
function Compat.GetActiveSpecGroup()
    if WoWVersion == "RETAIL" or WoWVersion == "MOP_CLASSIC" then
        return SafeCall(GetActiveSpecGroup) or 1
    else
        -- Classic: Always return 1 (no dual spec)
        return 1
    end
end

return Compat
