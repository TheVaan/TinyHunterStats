-- TinyHunterStats @project-version@ by @project-author@
-- Project revision: @project-revision@
--
-- TinyHunterStats.lua:
-- File revision: @file-revision@
-- Last modified: @file-date-iso@
-- Author: @file-author@

local debug = false
--@debug@
debug = true
--@end-debug@

local AddonName = "TinyHunterStats"
local AceAddon = LibStub("AceAddon-3.0")
local media = LibStub("LibSharedMedia-3.0")
TinyHunterStats = AceAddon:NewAddon(AddonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local ldb = LibStub("LibDataBroker-1.1")
local THSBroker = ldb:NewDataObject(AddonName, {
    type = "data source",
    label = AddonName,
    icon = "Interface\\Icons\\Ability_Hunter_SniperShot",
    text = "--"
    })

local isInFight = false
local SpecChangedPause = GetTime()

local backdrop = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "",
    tile = false, tileSize = 16, edgeSize = 0,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

local function Debug(...)
    if debug then
        local text = ""
        for i = 1, select("#", ...) do
            if type(select(i, ...)) == "boolean" then
                text = text..(select(i, ...) and "true" or "false").." "
            else
                text = text..(select(i, ...) or "nil").." "
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFFCCCC99"..AddonName..": |r"..text)
    end
end

TinyHunterStats.fonts = {}

TinyHunterStats.defaults = {
    char = {
        Font = "Vera",
        FontEffect = "none",
        Size = 12,
        FrameLocked = true,
        yPosition = 200,
        xPosition = 200,
        inCombatAlpha = 1,
        outOfCombatAlpha = .3,
        RecordMsg = true,
        RecordSound = false,
        RecordSoundFile = "Fanfare3",
        Spec1 = {
            HighestAp = 0,
            HighestCrit = "0.00",
            FastestRs = 500,
            HighestFr = "0.00"
        },
        Spec2 = {
            HighestAp = 0,
            HighestCrit = "0.00",
            FastestRs = 500,
            HighestFr = "0.00"
        },
        Style = {
            AP = {
                hunter = true
            },
            Crit = {
                hunter = true
            },
            Speed = {
                hunter = true
            },
            Fr = {
                hunter = true
            },
            showRecords = true,
            showRecordsLDB = true,
            vertical = false,
            labels = false
        },
        Color = {
            ap = {
                r = 1,
                g = 0.803921568627451,
                b = 0
            },
            crit = {
                r = 1.0,
                g = 0,
                b = 0.6549019607843137
            },
            haste = {
                r = 0,
                g = 0.611764705882353,
                b = 1.0
            },
            fr = {
                r = 0.9,
                g = 0.9,
                b = 0.9
            }
        },
        DBver = 3
    }
}

TinyHunterStats.frame = CreateFrame("Frame",AddonName.."Frame",UIParent, "BackdropTemplate")
TinyHunterStats.frame:SetWidth(100)
TinyHunterStats.frame:SetHeight(15)
TinyHunterStats.frame:SetFrameStrata("BACKGROUND")
TinyHunterStats.frame:EnableMouse(true)
TinyHunterStats.frame:RegisterForDrag("LeftButton")

TinyHunterStats.string = TinyHunterStats.frame:CreateFontString()

function TinyHunterStats:SetDragScript()
    if self.db.char.FrameLocked then
        self.frame:SetMovable(false)
        fixed = "|cffFF0000"..L["Text is fixed. Uncheck Lock Frame in the options to move!"].."|r"
        self.frame:SetScript("OnDragStart", function() DEFAULT_CHAT_FRAME:AddMessage(fixed) end)
        self.frame:SetScript("OnEnter", nil)
        self.frame:SetScript("OnLeave", nil)
    else
        self.frame:SetMovable(true)
        self.frame:SetScript("OnDragStart", function() self.frame:StartMoving() end)
        self.frame:SetScript("OnDragStop", function() self.frame:StopMovingOrSizing() self.db.char.xPosition = self.frame:GetLeft() self.db.char.yPosition = self.frame:GetBottom() end)
        self.frame:SetScript("OnEnter", function() self.frame:SetBackdrop(backdrop) end)
        self.frame:SetScript("OnLeave", function() self.frame:SetBackdrop(nil) end)
    end
end

function TinyHunterStats:SetFrameVisible()

    if self.db.char.FrameHide then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -1000, -1000)
    else
        self.frame:ClearAllPoints()
        self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.db.char.xPosition, self.db.char.yPosition)
    end

end

-- "none" is only our own option value, the client rejects it as a font flag
function TinyHunterStats:GetFontFlags()
    local effect = self.db.char.FontEffect
    if effect == "none" then
        return ""
    end
    return effect
end

function TinyHunterStats:InitializeFrame()
    local font = media:Fetch("font", self.db.char.Font)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.db.char.xPosition, self.db.char.yPosition)
    self.string:ClearAllPoints()
    self.string:SetPoint("TOPLEFT", self.frame,"TOPLEFT", 0, 0)
    self.string:SetFontObject(GameFontNormal)
    if not self.string:SetFont(font, self.db.char.Size, self:GetFontFlags()) then
        self.string:SetFont("Fonts\\FRIZQT__.TTF", self.db.char.Size, self:GetFontFlags())
    end
    self.string:SetJustifyH("LEFT")
    self.string:SetJustifyV("MIDDLE")

    self:SetDragScript()
    self:SetFrameVisible()
    self:Stats()
end

function TinyHunterStats:OnInitialize()
    local AceConfigReg = LibStub("AceConfigRegistry-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")

    local GetAddOnMetadata = GetAddOnMetadata or (C_AddOns and C_AddOns.GetAddOnMetadata)
    
    self.db = LibStub("AceDB-3.0"):New(AddonName.."DB", TinyHunterStats.defaults, "char")
    LibStub("AceConfig-3.0"):RegisterOptionsTable(AddonName, self:Options(), "thscmd")
    media.RegisterCallback(self, "LibSharedMedia_Registered")

    self:RegisterChatCommand("ths", function() AceConfigDialog:Open(AddonName) end)
    self:RegisterChatCommand(AddonName, function() AceConfigDialog:Open(AddonName) end)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions(AddonName, AddonName)
    self.db:RegisterDefaults(self.defaults)

    local version = GetAddOnMetadata(AddonName,"Version")
    local loaded = L["Open the configuration menu with /ths or /TinyHunterStats"].."|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd700"..AddonName.." |cff00ff00~v"..version.."~|cffffd700: "..loaded)

    THSBroker.OnClick = function(frame, button)	AceConfigDialog:Open(AddonName)	end
    THSBroker.OnTooltipShow = function(tt) tt:AddLine(AddonName) end

    TinyHStatsDB = TinyHStatsDB or {}
    self.Globaldb = TinyHStatsDB
end

function TinyHunterStats:OnEnable()
    self:LibSharedMedia_Registered()
    self:InitializeFrame()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
    self:RegisterEvent("UNIT_AURA", "OnEvent")
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "OnEvent")
    self:RegisterEvent("UNIT_INVENTORY_CHANGED", "OnEvent")
    self:RegisterEvent("UNIT_LEVEL", "OnEvent")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
    self:RegisterEvent("PLAYER_TALENT_UPDATE", "OnEvent")
end

function TinyHunterStats:LibSharedMedia_Registered()
    media:Register("font", "BaarSophia", [[Interface\Addons\TinyHunterStats\Fonts\BaarSophia.ttf]])
    media:Register("font", "LucidaSD", [[Interface\Addons\TinyHunterStats\Fonts\LucidaSD.ttf]])
    media:Register("font", "Teen", [[Interface\Addons\TinyHunterStats\Fonts\Teen.ttf]])
    media:Register("font", "Vera", [[Interface\Addons\TinyHunterStats\Fonts\Vera.ttf]])
    media:Register("sound", "Fanfare1", [[Interface\Addons\TinyHunterStats\Sound\Fanfare.ogg]])
    media:Register("sound", "Fanfare2", [[Interface\Addons\TinyHunterStats\Sound\Fanfare2.ogg]])
    media:Register("sound", "Fanfare3", [[Interface\Addons\TinyHunterStats\Sound\Fanfare3.ogg]])

    for k, v in pairs(media:List("font")) do
        self.fonts[v] = v
    end
end

-- Pause records while the spec group changes (SetActiveSpecGroup moved into C_SpecializationInfo)
local function OnSetActiveSpecGroup()
    SpecChangedPause = GetTime() + 60
    TinyHunterStats:ScheduleTimer("Stats", 62)
    Debug("Set SpecChangedPause")
end
if C_SpecializationInfo and C_SpecializationInfo.SetActiveSpecGroup then
    hooksecurefunc(C_SpecializationInfo, "SetActiveSpecGroup", OnSetActiveSpecGroup)
elseif SetActiveSpecGroup then
    hooksecurefunc("SetActiveSpecGroup", OnSetActiveSpecGroup)
end

function TinyHunterStats:OnEvent(event, arg1)
    if (event == "PLAYER_ENTERING_WORLD") then
        self:UseTinyXStats()
    end
    if ((event == "PLAYER_REGEN_ENABLED") or (event == "PLAYER_ENTERING_WORLD")) then
        self.frame:SetAlpha(self.db.char.outOfCombatAlpha)
        isInFight = false
    end
    if (event == "PLAYER_REGEN_DISABLED") then
        self.frame:SetAlpha(self.db.char.inCombatAlpha)
        isInFight = true
    end
    if (event == "UNIT_AURA" and arg1 == "player") then
        self:ScheduleTimer("Stats", .8)
    end
    if (event ~= "UNIT_AURA") then
        self:Stats()
    end

end

function TinyHunterStats:UseTinyXStats()

    if self.Globaldb.NoXStatsPrint then return end

    local text = {}
    text[1] = "|cFF00ff00"..L["Please use TinyXStats, it's an all in one Stats Addon."].."|r"
    text[2] = "https://curseforge.com/wow/addons/tinystats"
    text[3] = "|cFF00ff00"..L["In future this will be updated first."].."|r"
    for i = 1, 3 do
        DEFAULT_CHAT_FRAME:AddMessage("|cFFCCCC99"..AddonName..": |r"..text[i])
    end

end

local function HexColor(stat)

    local c = TinyHunterStats.db.char.Color[stat]
    local hexColor = string.format("|cff%2X%2X%2X", 255*c.r, 255*c.g, 255*c.b)
    return hexColor

end

local function MsgRecord(name,value)
    if (TinyHunterStats.db.char.RecordMsg == true) then
        DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000"..L["Record broken!"]..": "..name..": |c00ffef00"..value.."|r")
        return true
    end
end

local function SetRecordLabel(label)
    if not TinyHunterStats.db.char.Style.labels or TinyHunterStats.db.char.Style.vertical then
        label = ""
    end
    return label
end

local function SetLabel(color,label)
    local style = TinyHunterStats.db.char.Style
    TinyHunterStats.CString = TinyHunterStats.CString..HexColor(color)..(style.labels and label or "")
    TinyHunterStats.RString = TinyHunterStats.RString..HexColor(color)..SetRecordLabel(label)
    TinyHunterStats.ldbString = TinyHunterStats.ldbString..HexColor(color)..(style.labels and label or "")
    TinyHunterStats.ldbRecord = TinyHunterStats.ldbRecord..HexColor(color)..(style.labels and label or "")
end

local function SetValues(Value,Highest)
    TinyHunterStats.CString = TinyHunterStats.CString..Value
    TinyHunterStats.RString = TinyHunterStats.RString..Highest
    TinyHunterStats.ldbString = TinyHunterStats.ldbString..Value.." "
    TinyHunterStats.ldbRecord = TinyHunterStats.ldbRecord..Highest.." "
end

local function FormatRString()
    if TinyHunterStats.db.char.Style.vertical then
        if TinyHunterStats.db.char.Style.showRecords then
            TinyHunterStats.CString = TinyHunterStats.CString.." ("..TinyHunterStats.RString..")|n"
            TinyHunterStats.RString = ""
        else
            TinyHunterStats.CString = TinyHunterStats.CString.."|n"
            TinyHunterStats.RString = ""
        end
    else
        TinyHunterStats.CString = TinyHunterStats.CString.." "
        TinyHunterStats.RString = TinyHunterStats.RString.." "
    end
end

local function GetAttackPower()
    return TinyHunterStats.Compat.GetAttackPower(true)
end

local function GetCrit()
    return TinyHunterStats.Compat.GetCritChance(false)
end

local function GetRangedSpeed(spec)
    local fastestSpeed = TinyHunterStats.db.char[spec].FastestRs
    local speed = TinyHunterStats.Compat.GetRangedSpeed()
    if speed then
        return speed, fastestSpeed
    else
        return "N/A", fastestSpeed
    end
end

function TinyHunterStats:Stats()
    Debug("Stats()")
    local style = self.db.char.Style
    local spec = "Spec"..TinyHunterStats.Compat.GetActiveSpecGroup()
    local pow = GetAttackPower()
    local crit = string.format("%.2f",GetCrit())
    local speed, fastestSpeed = GetRangedSpeed(spec)
    local fr = string.format("%.2f", TinyHunterStats.Compat.GetPowerRegen() or 0)

    local recordIsBroken = false

    if SpecChangedPause <= GetTime() then
        if (style.AP.hunter and tonumber(pow) > tonumber(self.db.char[spec].HighestAp)) then
            self.db.char[spec].HighestAp = pow
            recordIsBroken = MsgRecord(STAT_ATTACK_POWER,pow) or recordIsBroken
        end
        if (style.Crit.hunter and tonumber(crit) > tonumber(self.db.char[spec].HighestCrit)) then
            self.db.char[spec].HighestCrit = crit
            recordIsBroken = MsgRecord(RANGED_CRIT_CHANCE,crit) or recordIsBroken
        end
        if (style.Speed.hunter) then
            if (tonumber(speed) and (tonumber(speed) < tonumber(self.db.char[spec].FastestRs))) then
                self.db.char[spec].FastestRs = speed
                recordIsBroken = MsgRecord(STAT_ATTACK_SPEED,speed) or recordIsBroken
                fastestSpeed = self.db.char[spec].FastestRs
            end
        end
        if (style.Fr.hunter and tonumber(fr) > tonumber(self.db.char[spec].HighestFr)) then
            self.db.char[spec].HighestFr = fr
            recordIsBroken = MsgRecord(STAT_FOCUS_REGEN,fr) or recordIsBroken
        end
    else
        Debug("rekords skipped SpecChangedPause")
    end

    if ((recordIsBroken == true) and (self.db.char.RecordSound == true)) then
        PlaySoundFile(media:Fetch("sound", self.db.char.RecordSoundFile),"Master")
    end

    self.ldbString = ""
    self.ldbRecord = ""
    self.CString = ""
    self.RString = ""

    if (style.AP.hunter) then
        SetLabel("ap",L["Ap:"])
        SetValues(pow,self.db.char[spec].HighestAp)
        FormatRString()
    end
    if (style.Speed.hunter) then
        SetLabel("haste",L["Speed:"])
        SetValues(speed.."s",fastestSpeed.."s")
        FormatRString()
    end
    if (style.Fr.hunter) then
        SetLabel("fr",L["FR:"])
        SetValues(fr,self.db.char[spec].HighestFr)
        FormatRString()
    end
    if (style.Crit.hunter) then
        SetLabel("crit",L["Crit:"])
        SetValues(crit.."%",self.db.char[spec].HighestCrit.."%")
        FormatRString()
    end

    if style.showRecords then
        if not style.vertical then
            self.CString = self.CString.."|n"..self.RString
        end
    end

    if style.showRecordsLDB then
        self.ldbString = self.ldbString.."|n"..self.ldbRecord
    end

    self.string:SetText(self.CString)

    THSBroker.text = self.ldbString.."|r"
    
end
