--         ------------------------------------------
--        |  TinyHunterStats by TheVaan and Marhu_  |
--         ------------------------------------------
--
-- File version: @file-revision@
-- Project: @project-revision@
--

local AceAddon = LibStub("AceAddon-3.0")
local media = LibStub:GetLibrary("LibSharedMedia-3.0")
TinyHunterStats = AceAddon:NewAddon("TinyHunterStats", "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TinyHunterStats")

local ldb = LibStub:GetLibrary("LibDataBroker-1.1");
local TinyHunterStatsBroker = ldb:NewDataObject("TinyHunterStats", { 
	type = "data source",
	label = "TinyHunterStats", 
	icon = "Interface\\Icons\\Ability_Racial_ShadowMeld",
	text = "--"
	})

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
		outOfCombatAlpha = .5,
		RecordMsg = true,
		HighestAp = 0,
		HighestCrit = 0,
		FastestRg = 500,
		HighestFr = 0,
		Style = {
			Ap = true,
			Crit = true,
			Speed = false,
			Fr = true,
			MaxAp = true,
			MaxCrit = true,
			MaxSpeed = false,
			MaxFr = true,
			LDBtext = true
		},
	}
}

thsframe = CreateFrame("Frame","TinyHunterStatsFrame",UIParent)
thsframe:SetWidth(100)
thsframe:SetHeight(15)
thsframe:SetFrameStrata("BACKGROUND")
thsframe:EnableMouse(true)
thsframe:RegisterForDrag("LeftButton")

thsstring = thsframe:CreateFontString()
thsstring:SetFontObject(GameFontNormal)
thsstring:SetPoint("CENTER", thsframe)
thsstring:SetJustifyH("CENTER")
thsstring:SetJustifyV("MIDDLE")

function TinyHunterStats:SetDragScript()
	if self.db.char.FrameLocked then
		thsframe:SetMovable(false)
		fixed = "|cffFF0000"..L["Text is fixed. Uncheck Lock Frame in the options to move!"].."|r"
		thsframe:SetScript("OnDragStart", function() DEFAULT_CHAT_FRAME:AddMessage(fixed) end)
	else
		thsframe:SetMovable(true)
		thsframe:SetScript("OnDragStart", function() thsframe:StartMoving() end)
		thsframe:SetScript("OnDragStop", function()	thsframe:StopMovingOrSizing() self.db.char.xPosition = thsframe:GetLeft() self.db.char.yPosition = thsframe:GetBottom()	end)
	end
end

function TinyHunterStats:InitializeFrame()
	thsframe:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.db.char.xPosition, self.db.char.yPosition)
	local font = media:Fetch("font", self.db.char.Font)
	if not thsstring:SetFont(font, self.db.char.Size, self.db.char.FontEffect) then
		thsstring:SetFont("Fonts\\FRIZQT__.TTF", self.db.char.Size, self.db.char.FontEffect)
	end
	self:SetDragScript()
	self:Stats()
end

function TinyHunterStats:OnInitialize()
	local AceConfigReg = LibStub("AceConfigRegistry-3.0")
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	
	self.db = LibStub("AceDB-3.0"):New("TinyHunterStats", TinyHunterStats.defaults, "char")
	LibStub("AceConfig-3.0"):RegisterOptionsTable("TinyHunterStats", self:Options(), "thscmd")
	media.RegisterCallback(self, "LibSharedMedia_Registered")
	
	self:RegisterChatCommand("ths", function() AceConfigDialog:Open("TinyHunterStats") end)	
	self:RegisterChatCommand("TinyHunterStats", function() AceConfigDialog:Open("TinyHunterStats") end)
	self.optionsFrame = AceConfigDialog:AddToBlizOptions("TinyHunterStats", "TinyHunterStats")
	self.db:RegisterDefaults(self.defaults)
	local version = GetAddOnMetadata("TinyHunterStats","Version")
	local loaded = L["Open the configuration menu with /ths"].."|r"
	DEFAULT_CHAT_FRAME:AddMessage("|cffffd700TinyHunterStats |cff00ff00~v"..version.."~|cffffd700: "..loaded)
	
	TinyHunterStatsBroker.OnClick = function(frame, button)	AceConfigDialog:Open("TinyHunterStats")	end
end

function TinyHunterStats:OnEnable()
	self:LibSharedMedia_Registered()
	self:InitializeFrame()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("UNIT_ATTACK_SPEED", "OnEvent")
	self:RegisterEvent("UNIT_RANGED_ATTACK_POWER", "OnEvent")
	self:RegisterEvent("COMBAT_RATING_UPDATE", "OnEvent")
	self:RegisterEvent("UNIT_AURA", "OnEvent")
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
	
	for k, v in pairs(media:List("font")) do
		self.fonts[v] = v
	end
end

function TinyHunterStats:OnEvent(event, arg1)
	if ((event == "PLAYER_REGEN_ENABLED") or (event == "PLAYER_ENTERING_WORLD")) then
		thsframe:SetAlpha(self.db.char.outOfCombatAlpha)
	end
	if (event == "PLAYER_REGEN_DISABLED") then
		thsframe:SetAlpha(self.db.char.inCombatAlpha)
	end
	if (event == "UNIT_AURA" and arg1 == "player") then
		self:Stats()
	end
	if (event ~= "UNIT_AURA") then
		self:Stats()
	end
end

function TinyHunterStats:Stats()
	local style = self.db.char.Style
	local base, buff, debuff = UnitRangedAttackPower("player")
	local pow = base + buff + debuff
	local crit = string.format("%.2f", GetRangedCritChance("player"))
	local speed = string.format("%.2f", UnitRangedDamage("player"))
	local fr = string.format("%.2f", GetPowerRegen() or 0)
	local recordbrocken = L["Record broken!"]

	if (tonumber(pow) > tonumber(self.db.char.HighestAp)) then
		self.db.char.HighestAp = pow
		if (self.db.char.RecordMsg == true) then
			DEFAULT_CHAT_FRAME:AddMessage(recordbrocken)
			DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000"..L["Ranged Attack Power"]..": |c00ffef00"..self.db.char.HighestAp.."|r")
		end
	end
	if (tonumber(crit) > tonumber(self.db.char.HighestCrit)) then
		self.db.char.HighestCrit = crit
		if (self.db.char.RecordMsg == true) then
			DEFAULT_CHAT_FRAME:AddMessage(recordbrocken)
			DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000"..L["Ranged Critical Chance"]..": |c00ffef00"..self.db.char.HighestCrit.."|r")
		end
	end
	if (tonumber(speed) < tonumber(self.db.char.FastestRg)) then
		self.db.char.FastestRg = speed
		if (self.db.char.RecordMsg == true) then
			DEFAULT_CHAT_FRAME:AddMessage(recordbrocken)
			DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000"..L["Ranged Attack Speed"]..": |c00ffef00"..self.db.char.FastestRg.."|r")
		end
	end
	if (tonumber(fr) > tonumber(self.db.char.HighestFr)) then
		self.db.char.HighestFr = fr
		if (self.db.char.RecordMsg == true) then
			DEFAULT_CHAT_FRAME:AddMessage(recordbrocken)
			DEFAULT_CHAT_FRAME:AddMessage("|cffFF0000"..STAT_FOCUS_REGEN..": |c00ffef00"..self.db.char.HighestFr.."|r")
		end
	end
			
	local stat = ""
	local oldstat = ""
	
	if (style.Ap == true) then
		stat = "|c00990033"..pow.."|r"
	end
	if (style.Crit == true) then
		oldstat = stat
		stat = oldstat.." |c00669900"..crit.."%|r"
	end
	if (style.Speed == true) then
		oldstat = stat
		stat = oldstat.." |c000099FF"..speed.."s|r"
	end
	if (style.Fr == true) then
		oldstat = stat
		stat = oldstat.." |c000033CC"..fr.."|r"
	end
	if (style.MaxAp or style.MaxCrit or style.MaxSpeed or style.MaxHit or style.MaxFr) then
		oldstat = stat
		stat = oldstat.."\n"
	end
	if (style.MaxAp == true) then
		oldstat = stat
		stat = oldstat.."|c00003333"..self.db.char.HighestAp.."|r"
	end
	if (style.MaxCrit == true) then
		oldstat = stat
		stat = oldstat.." |c00CCCC99"..self.db.char.HighestCrit.."%|r"
	end
	if (style.MaxSpeed == true) then
		oldstat = stat
		stat = oldstat.." |c00666699"..self.db.char.FastestRg.."s|r"
	end
	if (style.MaxFr == true) then
		oldstat = stat
		stat = oldstat.." |c00003366"..self.db.char.HighestFr.."|r"
	end
	
	thsstring:SetText(stat)
	if (style.LDBtext) then
		TinyHunterStatsBroker.text = stat
	else
		TinyHunterStatsBroker.text = ""
	end
end