--
-- File version: @file-revision@
-- Project: @project-revision@
--
if not TinyHunterStats then return end

local L = LibStub("AceLocale-3.0"):GetLocale("TinyHunterStats")
local media = LibStub:GetLibrary("LibSharedMedia-3.0")

TinyHunterStats.fonteffects = {
	["none"] = L["NONE"],
	["OUTLINE"] = L["OUTLINE"],
	["THICKOUTLINE"] = L["THICKOUTLINE"],
}

function TinyHunterStats:Options()
	local options = {
		name = "TinyHunterStats",
	    handler = TinyHunterStats,
	    type = 'group',
	    args = {
			reset = {
				name = L["Reset position"],
				desc = L["Resets the frame's position"],
				type = 'execute',
				func = function() thsframe:ClearAllPoints() thsframe:SetPoint("CENTER", UIParent, "CENTER") end,
				disabled = function() return InCombatLockdown() end,
				order = 1,
			},
			lock = {
				name = L["Lock Frame"],
				desc = L["Locks the position of the text frame"],
				type = 'toggle',
				get = function() return self.db.char.FrameLocked end,
				set = function(info, value)				
					if(value) then
						self.db.char.FrameLocked = true
						thsframe:SetMovable(false)
						fixed = "|cffFF0000"..L["Text is fixed. Uncheck Lock Frame in the options to move!"].."|r"
						thsframe:SetScript("OnDragStart", function() DEFAULT_CHAT_FRAME:AddMessage(fixed) end)
					else
						self.db.char.FrameLocked = false
						thsframe:SetMovable(true)
						thsframe:SetScript("OnDragStart", function() thsframe:StartMoving() end)
						thsframe:SetScript("OnDragStop", function()	thsframe:StopMovingOrSizing() self.db.char.xPosition = thsframe:GetLeft() self.db.char.yPosition = thsframe:GetBottom()	end)
					end
				end,
				disabled = function() return InCombatLockdown() end,
				order = 2,
			},
			record = {
				name = L["Show new records"],
				desc = L["Whether or not to display a message when a record is broken"],
				type = 'toggle',
				get = function() return self.db.char.RecordMsg end,
				set = function(info, value)				
					if(value) then
						self.db.char.RecordMsg = true
					else
						self.db.char.RecordMsg = false
					end
				end,
				disabled = function() return InCombatLockdown() end,
				order = 3,
			},
			text = {
				name = L["Text"],
				desc = L["Text settings"],
				type = 'group',
				order = 1,
				args = {			
					hader = {
						name = L["Text settings"],
						type = 'header',
						order = 1,
					},
					spaceline1 = {
						name = "\n",
						type = 'description',
						order = 2,
					},
					oocalpha = {
						name = L["Text Alpha"].." "..L["out of combat"],
						desc = L["Alpha of the text"].." ("..L["out of combat"]..")",
						width = 'full',
						type = 'range',
						min = 0,
						max = 1,
						step = 0.01,
						isPercent = true,
						get = function() return self.db.char.outOfCombatAlpha end,
						set = function(info, newValue)
							self.db.char.outOfCombatAlpha = newValue
							thsframe:SetAlpha(self.db.char.outOfCombatAlpha)
						end,
						disabled = function() return InCombatLockdown() end,
						order = 3,
					},
					icalpha = {
						name = L["Text Alpha"].." "..L["in combat"],
						desc = L["Alpha of the text"].." ("..L["in combat"]..")",
						width = 'full',
						type = 'range',
						min = 0,
						max = 1,
						step = 0.01,
						isPercent = true,
						get = function() return self.db.char.inCombatAlpha end,
						set = function(info, newValue)
							self.db.char.inCombatAlpha = newValue
							thsframe:SetAlpha(self.db.char.inCombatAlpha)
						end,
						disabled = function() return InCombatLockdown() end,
						order = 4,
					},
					font = {
						name = L["Font"],
						type = 'select',
						get = function() return self.db.char.Font end,
						set = function(info, newValue)
							self.db.char.Font = newValue
							local font = media:Fetch("font", self.db.char.Font)
							thsframe:SetFont(font, self.db.char.Size, self.db.char.FontEffect)
						end,
						values = self.fonts,
						order = 5,
					},
					spaceline2 = {
						name = "",
						type = 'description',
						order = 6,
					},
					fonteffect = {
						name = L["Font border"],
						type = 'select',
						get = function() return self.db.char.FontEffect end,
						set = function(info, newValue)
							self.db.char.FontEffect = newValue
							local font = media:Fetch("font", self.db.char.Font)
							thsframe:SetFont(font, self.db.char.Size, self.db.char.FontEffect)
						end,
						values = self.fonteffects,
						order = 7,
					},
					barfontsize = {
						name = L["Font size"],
						width = 'full',
						type = 'range',
						min = 6,
						max = 32,
						step = 1,
						get = function() return self.db.char.Size end,
						set = function(info, newValue)
							self.db.char.Size = newValue
							local font = media:Fetch("font", self.db.char.Font)
							thsframe:SetFont(font, self.db.char.Size, self.db.char.FontEffect)
						end,
						order = 8,
					},
				},
			},
			style = {
				name = L["Stats"],
				desc = L["Select which stats to show"],
				type = 'group',
				order = 2,
				args = {
					hader = {
						name = L["Stats"],
						type = 'header',
						order = 1,
					},
					spaceline3 = {
						name = "\n",
						type = 'description',
						order = 2,
					},
					ap = {
						name = L["Ranged Attack Power"],
						desc = L["Ranged Attack Power"].." "..L["show/hide"],
						width = 'full',
						type = 'toggle',
						get = function() return self.db.char.Style.Ap end,
						set = function(info, value)				
							if(value) then
								self.db.char.Style.Ap = true
							else
								self.db.char.Style.Ap = false
							end
							self:Stats()
						end,
						disabled = function() return InCombatLockdown() end,
						order = 3,
					},
					crit = {
						name = L["Ranged Critical Chance"],
						desc = L["Ranged Critical Chance"].." "..L["show/hide"],
						width = 'full',
						type = 'toggle',
						get = function() return self.db.char.Style.Crit end,
						set = function(info, value)				
							if(value) then
								self.db.char.Style.Crit = true
							else
								self.db.char.Style.Crit = false
							end
							self:Stats()
						end,
						disabled = function() return InCombatLockdown() end,
						order = 4,
					},
					speed = {
						name = L["Ranged Attack Speed"],
						desc = L["Ranged Attack Speed"].." "..L["show/hide"],
						width = 'full',
						type = 'toggle',
						get = function() return self.db.char.Style.Speed end,
						set = function(info, value)				
							if(value) then
								self.db.char.Style.Speed = true
							else
								self.db.char.Style.Speed = false
							end
							self:Stats()
						end,
						disabled = function() return InCombatLockdown() end,
						order = 5,
					},
					arp = {
						name = L["Armor Penetration"],
						desc = L["Armor Penetration"].." "..L["show/hide"],
						width = 'full',
						type = 'toggle',
						get = function() return self.db.char.Style.Arp end,
						set = function(info, value)				
							if(value) then
								self.db.char.Style.Arp = true
							else
								self.db.char.Style.Arp = false
							end
							self:Stats()
						end,
						disabled = function() return InCombatLockdown() end,
						order = 6,
					},
					maxap = {
						name = L["Highest"].." "..L["Ranged Attack Power"],
						desc = L["Highest"].." "..L["Ranged Attack Power"].." "..L["show/hide"],
						width = 'full',
						type = 'toggle',
						get = function() return self.db.char.Style.MaxAp end,
						set = function(info, value)				
							if(value) then
								self.db.char.Style.MaxAp = true
							else
								self.db.char.Style.MaxAp = false
							end
							self:Stats()
						end,
						disabled = function() return InCombatLockdown() end,
						order = 7,
					},
					maxcrit = {
						name = L["Highest"].." "..L["Ranged Critical Chance"],
						desc = L["Highest"].." "..L["Ranged Critical Chance"].." "..L["show/hide"],
						width = 'full',
						type = 'toggle',
						get = function() return self.db.char.Style.MaxCrit end,
						set = function(info, value)				
							if(value) then
								self.db.char.Style.MaxCrit = true
							else
								self.db.char.Style.MaxCrit = false
							end
							self:Stats()
						end,
						disabled = function() return InCombatLockdown() end,
						order = 8,
					},
					maxspeed = {
						name = L["Highest"].." "..L["Ranged Attack Speed"],
						desc = L["Highest"].." "..L["Ranged Attack Speed"].." "..L["show/hide"],
						width = 'full',
						type = 'toggle',
						get = function() return self.db.char.Style.MaxSpeed end,
						set = function(info, value)				
							if(value) then
								self.db.char.Style.MaxSpeed = true
							else
								self.db.char.Style.MaxSpeed = false
							end
							self:Stats()
						end,
						disabled = function() return InCombatLockdown() end,
						order = 9,
					},
					maxarp = {
						name = L["Highest"].." "..L["Armor Penetration"],
						desc = L["Highest"].." "..L["Armor Penetration"].." "..L["show/hide"],
						width = 'full',
						type = 'toggle',
						get = function() return self.db.char.Style.MaxArp end,
						set = function(info, value)				
							if(value) then
								self.db.char.Style.MaxArp = true
							else
								self.db.char.Style.MaxArp = false
							end
							self:Stats()
						end,
						disabled = function() return InCombatLockdown() end,
						order = 10,
					},
					spaceline4 = {
						name = "\n",
						type = 'description',
						order = 11,
					},
					resetrecords = {
						name = L["Reset records"],
						desc = L["Clears your current records"],
						type = 'execute',
						func = function()
							self.db.char.HighestAp = 0
							self.db.char.HighestCrit = 0
							self.db.char.FastestRg = 500
							self.db.char.HighestArp = 0
							self:Stats()
						end,
						disabled = function() return InCombatLockdown() end,
						order = 12,
					},
				},
			},
		},
	}
	return options
end
