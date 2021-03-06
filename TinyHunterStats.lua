-- TinyMeleeStats @project-version@ by @project-author@
-- Project revision: @project-revision@
--
-- TinyMeleeStats.lua:
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

local ldb = LibStub("LibDataBroker-1.1");
local THSBroker = ldb:NewDataObject(AddonName, {
	type = "data source",
	label = AddonName,
	icon = "Interface\\Icons\\Ability_Hunter_SniperShot",
	text = "--"
	})

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
			FastestRg = 500,
			HighestFr = "0.00"
		},
		Spec2 = {
			HighestAp = 0,
			HighestCrit = "0.00",
			FastestRg = 500,
			HighestFr = "0.00"
		},
		Style = {
			Ap = true,
			Crit = true,
			Speed = false,
			Fr = true,
			showRecords = true,
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
				r = 1,
				g = 0,
				b = 0.6549019607843137
			},
			speed = {
				r = 0,
				g = 0.611764705882353,
				b = 1
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

TinyHunterStats.thsframe = CreateFrame("Frame",AddonName.."Frame",UIParent)
TinyHunterStats.thsframe:SetWidth(100)
TinyHunterStats.thsframe:SetHeight(15)
TinyHunterStats.thsframe:SetFrameStrata("BACKGROUND")
TinyHunterStats.thsframe:EnableMouse(true)
TinyHunterStats.thsframe:RegisterForDrag("LeftButton")

TinyHunterStats.strings = {
	apString = TinyHunterStats.thsframe:CreateFontString(),
	critString = TinyHunterStats.thsframe:CreateFontString(),
	speedString = TinyHunterStats.thsframe:CreateFontString(),
	frString = TinyHunterStats.thsframe:CreateFontString(),

	apRecordString = TinyHunterStats.thsframe:CreateFontString(),
	critRecordString = TinyHunterStats.thsframe:CreateFontString(),
	speedRecordString = TinyHunterStats.thsframe:CreateFontString(),
	frRecordString = TinyHunterStats.thsframe:CreateFontString()
}

function TinyHunterStats:SetStringColors()
	local c = self.db.char.Color
	self.strings.apString:SetTextColor(c.ap.r, c.ap.g, c.ap.b, 1.0)
	self.strings.critString:SetTextColor(c.crit.r, c.crit.g, c.crit.b, 1.0)
	self.strings.speedString:SetTextColor(c.speed.r, c.speed.g, c.speed.b, 1.0)
	self.strings.frString:SetTextColor(c.fr.r, c.fr.g, c.fr.b, 1.0)

	self.strings.apRecordString:SetTextColor(c.ap.r, c.ap.g, c.ap.b, 1.0)
	self.strings.critRecordString:SetTextColor(c.crit.r, c.crit.g, c.crit.b, 1.0)
	self.strings.speedRecordString:SetTextColor(c.speed.r, c.speed.g, c.speed.b, 1.0)
	self.strings.frRecordString:SetTextColor(c.fr.r, c.fr.g, c.fr.b, 1.0)
end

function TinyHunterStats:SetTextAnchors()
	local offsetX, offsetY = 3, 0
	if (not self.db.char.Style.vertical) then
		self.strings.apString:SetPoint("TOPLEFT", self.thsframe,"TOPLEFT", offsetX, offsetY)
		self.strings.speedString:SetPoint("TOPLEFT", self.strings.apString, "TOPRIGHT", offsetX, offsetY)
		self.strings.frString:SetPoint("TOPLEFT", self.strings.speedString, "TOPRIGHT", offsetX, offsetY)
		self.strings.critString:SetPoint("TOPLEFT", self.strings.frString, "TOPRIGHT", offsetX, offsetY)

		self.strings.apRecordString:SetPoint("TOPLEFT", self.strings.apString, "BOTTOMLEFT")
		self.strings.speedRecordString:SetPoint("TOPLEFT", self.strings.apRecordString, "TOPRIGHT", offsetX, offsetY)
		self.strings.frRecordString:SetPoint("TOPLEFT", self.strings.speedRecordString, "TOPRIGHT", offsetX, offsetY)
		self.strings.critRecordString:SetPoint("TOPLEFT", self.strings.frRecordString, "TOPRIGHT", offsetX, offsetY)
	else
		self.strings.apString:SetPoint("TOPLEFT", self.thsframe,"TOPLEFT", offsetX, offsetY)
		self.strings.speedString:SetPoint("TOPLEFT", self.strings.apString, "BOTTOMLEFT")
		self.strings.frString:SetPoint("TOPLEFT", self.strings.speedString, "BOTTOMLEFT")
		self.strings.critString:SetPoint("TOPLEFT", self.strings.frString, "BOTTOMLEFT")

		self.strings.apRecordString:SetPoint("TOPLEFT", self.strings.apString, "TOPRIGHT", offsetX, offsetY)
		self.strings.speedRecordString:SetPoint("TOPLEFT", self.strings.speedString, "TOPRIGHT", offsetX, offsetY)
		self.strings.frRecordString:SetPoint("TOPLEFT", self.strings.frString, "TOPRIGHT", offsetX, offsetY)
		self.strings.critRecordString:SetPoint("TOPLEFT", self.strings.critString, "TOPRIGHT", offsetX, offsetY)
	end
end

function TinyHunterStats:SetDragScript()
	if self.db.char.FrameLocked then
		self.thsframe:SetMovable(false)
		fixed = "|cffFF0000"..L["Text is fixed. Uncheck Lock Frame in the options to move!"].."|r"
		self.thsframe:SetScript("OnDragStart", function() DEFAULT_CHAT_FRAME:AddMessage(fixed) end)
		self.thsframe:SetScript("OnEnter", nil)
		self.thsframe:SetScript("OnLeave", nil)
	else
		self.thsframe:SetMovable(true)
		self.thsframe:SetScript("OnDragStart", function() self.thsframe:StartMoving() end)
		self.thsframe:SetScript("OnDragStop", function() self.thsframe:StopMovingOrSizing() self.db.char.xPosition = self.thsframe:GetLeft() self.db.char.yPosition = self.thsframe:GetBottom()	end)
		self.thsframe:SetScript("OnEnter", function() self.thsframe:SetBackdrop(backdrop) end)
		self.thsframe:SetScript("OnLeave", function() self.thsframe:SetBackdrop(nil) end)
	end
end

function TinyHunterStats:SetFrameVisible()

	if self.db.char.FrameHide then
		self.thsframe:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -1000, -1000)
	else
		self.thsframe:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.db.char.xPosition, self.db.char.yPosition)
	end

end

function TinyHunterStats:InitializeFrame()
	self.thsframe:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", self.db.char.xPosition, self.db.char.yPosition)
	local font = media:Fetch("font", self.db.char.Font)
	for k, fontObject in pairs(self.strings) do
		fontObject:SetFontObject(GameFontNormal)
		if not fontObject:SetFont(font, self.db.char.Size, self.db.char.FontEffect) then
			fontObject:SetFont("Fonts\\FRIZQT__.TTF", self.db.char.Size, self.db.char.FontEffect)
		end
		fontObject:SetJustifyH("LEFT")
		fontObject:SetJustifyV("MIDDLE")
	end
	self.strings.apString:SetText(" ")
	self.strings.apString:SetHeight(self.strings.apString:GetStringHeight())
	self.strings.apString:SetText("")
	self:SetTextAnchors()
	self:SetStringColors()
	self:SetDragScript()
	self:SetFrameVisible()
	self:Stats()
end

function TinyHunterStats:OnInitialize()
	local AceConfigReg = LibStub("AceConfigRegistry-3.0")
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")

	self.db = LibStub("AceDB-3.0"):New(AddonName.."DB", TinyHunterStats.defaults, "char")
	LibStub("AceConfig-3.0"):RegisterOptionsTable(AddonName, self:Options(), "thscmd")
	media.RegisterCallback(self, "LibSharedMedia_Registered")

	self:RegisterChatCommand("ths", function() AceConfigDialog:Open(AddonName) end)
	self:RegisterChatCommand(AddonName, function() AceConfigDialog:Open(AddonName) end)
	self.optionsFrame = AceConfigDialog:AddToBlizOptions(AddonName, AddonName)
	self.db:RegisterDefaults(self.defaults)
	local version = GetAddOnMetadata(AddonName,"Version")
	local loaded = L["Open the configuration menu with /ths"].."|r"
	DEFAULT_CHAT_FRAME:AddMessage("|cffffd700TinyHunterStats |cff00ff00~v"..version.."~|cffffd700: "..loaded)

	THSBroker.OnClick = function(frame, button)	AceConfigDialog:Open(AddonName)	end
	THSBroker.OnTooltipShow = function(tt) tt:AddLine(AddonName) end

	TinyHStatsDB = TinyHStatsDB or {}
	self.Globaldb = TinyHStatsDB
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
	media:Register("sound", "Fanfare1", [[Interface\Addons\TinyHunterStats\Sound\Fanfare.ogg]])
	media:Register("sound", "Fanfare2", [[Interface\Addons\TinyHunterStats\Sound\Fanfare2.ogg]])
	media:Register("sound", "Fanfare3", [[Interface\Addons\TinyHunterStats\Sound\Fanfare3.ogg]])

	for k, v in pairs(media:List("font")) do
		self.fonts[v] = v
	end
end

local orgSetActiveSpecGroup = SetActiveSpecGroup;
function SetActiveSpecGroup(...)
	SpecChangedPause = GetTime() + 60
	Debug("Set SpecChangedPause")
	return orgSetActiveSpecGroup(...)
end

function TinyHunterStats:OnEvent(event, arg1)
	if (event == "PLAYER_ENTERING_WORLD") then
		self:UseTinyXStats()
	end
	if ((event == "PLAYER_REGEN_ENABLED") or (event == "PLAYER_ENTERING_WORLD")) then
		self.thsframe:SetAlpha(self.db.char.outOfCombatAlpha)
	end
	if (event == "PLAYER_REGEN_DISABLED") then
		self.thsframe:SetAlpha(self.db.char.inCombatAlpha)
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

local function GetSpeed()
	-- If no ranged attack then set to n/a
	--local hasRelic = UnitHasRelicSlot("player");
	--local rangedTexture = GetInventoryItemTexture("player", 18);
	--if ( rangedTexture and not hasRelic ) then
	if IsRangedWeapon() then
		local speed = UnitRangedDamage("player")
		if speed >= 0.01 then
			return string.format("%.2f",speed )
		else
			return 500
		end
	else
		return NOT_APPLICABLE
	end

end

function TinyHunterStats:Stats()
	Debug("Stats()")
	local style = self.db.char.Style
	local base, buff, debuff = UnitRangedAttackPower("player")
	local pow = base + buff + debuff
	local crit = string.format("%.2f", GetRangedCritChance("player"))
	local speed = GetSpeed()
	local fr = string.format("%.2f", GetPowerRegen() or 0)
	local spec = "Spec"..GetActiveSpecGroup()
	local recordbrocken = "|cffFF0000"..L["Record broken!"]..": "
	local recordIsBroken = false

	if SpecChangedPause <= GetTime() then
		if (tonumber(pow) > tonumber(self.db.char[spec].HighestAp)) then
			self.db.char[spec].HighestAp = pow
			if (self.db.char.RecordMsg == true) then
				DEFAULT_CHAT_FRAME:AddMessage(recordbrocken..STAT_ATTACK_POWER..": |c00ffef00"..self.db.char[spec].HighestAp.."|r")
				recordIsBroken = true
			end
		end
		if (tonumber(crit) > tonumber(self.db.char[spec].HighestCrit)) then
			self.db.char[spec].HighestCrit = crit
			if (self.db.char.RecordMsg == true) then
				DEFAULT_CHAT_FRAME:AddMessage(recordbrocken..RANGED_CRIT_CHANCE..": |c00ffef00"..self.db.char[spec].HighestCrit.."|r")
				recordIsBroken = true
			end
		end
		if (tonumber(speed) and (tonumber(speed) < tonumber(self.db.char[spec].FastestRg))) then
			self.db.char[spec].FastestRg = speed
			if (self.db.char.RecordMsg == true) then
				DEFAULT_CHAT_FRAME:AddMessage(recordbrocken..STAT_ATTACK_SPEED..": |c00ffef00"..self.db.char[spec].FastestRg.."|r")
				recordIsBroken = true
			end
		end
		if (tonumber(fr) > tonumber(self.db.char[spec].HighestFr)) then
			self.db.char[spec].HighestFr = fr
			if (self.db.char.RecordMsg == true) then
				DEFAULT_CHAT_FRAME:AddMessage(recordbrocken..STAT_FOCUS_REGEN..": |c00ffef00"..self.db.char[spec].HighestFr.."|r")
				recordIsBroken = true
			end
		end
	end

	if ((recordIsBroken == true) and (self.db.char.RecordSound == true)) then
		PlaySoundFile(media:Fetch("sound", self.db.char.RecordSoundFile),"Master")
	end

	local ldbString = ""
	local ldbRecord = ""

	if (style.showRecords) then ldbRecord = "|n" end

	if (style.Ap == true) then
		local apTempString = ""
		local apRecordTempString = ""
		ldbString = ldbString..HexColor("ap")
		if (style.labels) then
			apTempString = apTempString..L["Ap:"].." "
			ldbString = ldbString..L["Ap:"].." "
		end
		apTempString = apTempString..pow
		ldbString = ldbString..pow.." "
		if (style.showRecords) then
			ldbRecord = ldbRecord..HexColor("ap")
			if (style.vertical) then
				apRecordTempString = apRecordTempString.."("..self.db.char[spec].HighestAp..")"
				if (style.labels) then
					ldbRecord = ldbRecord..L["Ap:"].." "
				end
				ldbRecord = ldbRecord..self.db.char[spec].HighestAp.." "
			else
				if (style.labels) then
					apRecordTempString = apRecordTempString..L["Ap:"].." "
					ldbRecord = ldbRecord..L["Ap:"].." "
				end
				apRecordTempString = apRecordTempString..self.db.char[spec].HighestAp
				ldbRecord = ldbRecord..self.db.char[spec].HighestAp.." "
			end
		end
		self.strings.apString:SetText(apTempString)
		self.strings.apRecordString:SetText(apRecordTempString)
	else
		self.strings.apString:SetText("")
		self.strings.apRecordString:SetText("")
	end
	if (style.Speed == true) then
		local speedTempString = ""
		local speedRecordTempString = ""
		ldbString = ldbString..HexColor("speed")
		if (style.labels) then
			speedTempString = speedTempString..L["Speed:"].." "
			ldbString = ldbString..L["Speed:"].." "
		end
		speedTempString = speedTempString..speed.."s"
		ldbString = ldbString..speed.."s "
		if (style.showRecords) then
			ldbRecord = ldbRecord..HexColor("speed")
			if (style.vertical) then
				if (style.labels) then
					ldbRecord = ldbRecord..L["Speed:"].." "
				end
				speedRecordTempString = speedRecordTempString.."("..self.db.char[spec].FastestRg.."s)"
				ldbRecord = ldbRecord..self.db.char[spec].FastestRg.."s "
			else
				if (style.labels) then
					speedRecordTempString = speedRecordTempString..L["Speed:"].." "
					ldbRecord = ldbRecord..L["Speed:"].." "
				end
				speedRecordTempString = speedRecordTempString..self.db.char[spec].FastestRg.."s"
				ldbRecord = ldbRecord..self.db.char[spec].FastestRg.."s "
			end
		end
		self.strings.speedString:SetText(speedTempString)
		self.strings.speedRecordString:SetText(speedRecordTempString)
	else
		self.strings.speedString:SetText("")
		self.strings.speedRecordString:SetText("")
	end
	if (style.Fr == true) then
		local frTempString = ""
		local frRecordTempString = ""
		ldbString = ldbString..HexColor("fr")
		if (style.labels) then
			frTempString = frTempString..L["Fr:"].." "
			ldbString = ldbString..L["Fr:"].." "
		end
		frTempString = frTempString..fr
		ldbString = ldbString..fr.." "
		if (style.showRecords) then
			ldbRecord = ldbRecord..HexColor("fr")
			if (style.vertical) then
				if (style.labels) then
					ldbRecord = ldbRecord..L["Fr:"].." "
				end
				frRecordTempString = frRecordTempString.."("..self.db.char[spec].HighestFr..")"
				ldbRecord = ldbRecord..self.db.char[spec].HighestFr.." "
			else
				if (style.labels) then
					frRecordTempString = frRecordTempString..L["Fr:"].." "
					ldbRecord = ldbRecord..L["Fr:"].." "
				end
				frRecordTempString = frRecordTempString..self.db.char[spec].HighestFr
				ldbRecord = ldbRecord..self.db.char[spec].HighestFr.." "
			end
		end
		self.strings.frString:SetText(frTempString)
		self.strings.frRecordString:SetText(frRecordTempString)
	else
		self.strings.frString:SetText("")
		self.strings.frRecordString:SetText("")
	end
	if (style.Crit == true) then
		local critTempString = ""
		local critRecordTempString = ""
		ldbString = ldbString..HexColor("crit")
		if (style.labels) then
			critTempString = critTempString..L["Crit:"].." "
			ldbString = ldbString..L["Crit:"].." "
		end
		critTempString = critTempString..crit.."%"
		ldbString = ldbString..crit.."% "
		if (style.showRecords) then
			ldbRecord = ldbRecord..HexColor("crit")
			if (style.vertical) then
				if (style.labels) then
					ldbRecord = ldbRecord..L["Crit:"].." "
				end
				critRecordTempString = critRecordTempString.."("..self.db.char[spec].HighestCrit.."%)"
				ldbRecord = ldbRecord..self.db.char[spec].HighestCrit.."% "
			else
				if (style.labels) then
					critRecordTempString = critRecordTempString..L["Crit:"].." "
					ldbRecord = ldbRecord..L["Crit:"].." "
				end
				critRecordTempString = critRecordTempString..self.db.char[spec].HighestCrit.."%"
				ldbRecord = ldbRecord..self.db.char[spec].HighestCrit.."% "
			end
		end
		self.strings.critString:SetText(critTempString)
		self.strings.critRecordString:SetText(critRecordTempString)
	else
		self.strings.critString:SetText("")
		self.strings.critRecordString:SetText("")
	end

	THSBroker.text = ldbString..ldbRecord.."|r"
	
end
