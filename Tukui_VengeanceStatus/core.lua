-- don't load if class is wrong
local _, class = UnitClass("player")
if not (class == "WARRIOR" or class == "DRUID" or class == "DEATHKNIGHT" or class == "PALADIN") then return end

local width = 80
local height = 100
local orientation = "VERTICAL" -- "VERTICAL" | "HORIZONTAL"
local showValue = true 
local showMaxValue = false
local showPercent = false

local classcolor = RAID_CLASS_COLORS[class];
local locked = false

local f = CreateFrame("Frame")
f.ScanTip = CreateFrame("GameTooltip","VengeanceStatusScanTip",nil,"GameTooltipTemplate")
f.ScanTip:SetOwner(UIParent, "ANCHOR_NONE")

f.statusBar = {}
f.vengmax = 0
f.player = (UnitName("player")).." - "..(GetRealmName())
f.label = "|cffC495DDVengeance Status: |r"

local function getText()
	local text = ""  
	local vengval = f.statusBar.bar:GetValue() or 0
	
	if showValue then
		if showMaxValue then
			text = string.format("%s/%s", vengval, f.vengmax) 
		else
			text = string.format("%s", vengval) 
		end 
	end
	
	if showPercent then
		if string.len(text) > 0 and vengval > 0 then
			text = string.format("%s (%.2f%%)", text, min(((vengval/f.vengmax)*100),100))
		else
			text = string.format("%.2f%%", min(((vengval/f.vengmax)*100),100))
		end		
	end
	
	return text
end

local function isTank()
	local masteryIndex 
	local tank = false
	
	if class == "DRUID" then
		masteryIndex = GetPrimaryTalentTree()
		if masteryIndex and masteryIndex == 2 then
			local form = GetShapeshiftFormID()
			if form and form == BEAR_FORM then
				tank = true
			end
		end
	elseif class == "DEATHKNIGHT" then
		masteryIndex = GetPrimaryTalentTree()
		if masteryIndex and masteryIndex == 1 then
			tank = true
		end
	elseif class == "PALADIN" then
		masteryIndex = GetPrimaryTalentTree()
		if masteryIndex and masteryIndex == 2 then
			tank = true
		end
	elseif class == "WARRIOR" then
		masteryIndex = GetPrimaryTalentTree()
		if masteryIndex and masteryIndex == 3 then
			tank = true
		end
	end
	
	return tank
end

local function checkTank()
	if isTank() then
		f:RegisterEvent("UNIT_AURA")
		f:RegisterEvent("UNIT_MAXHEALTH")
		f:RegisterEvent("PLAYER_REGEN_ENABLED")
		f:RegisterEvent("PLAYER_REGEN_DISABLED")
	else
		f:UnregisterEvent("UNIT_AURA")
		f:UnregisterEvent("UNIT_MAXHEALTH")
		f:UnregisterEvent("PLAYER_REGEN_ENABLED")
		f:UnregisterEvent("PLAYER_REGEN_DISABLED")
		f.statusBar:Hide()
	end
end

local function getTooltipText(...)
	local text = ""
	for i=1,select("#",...) do
		local rgn = select(i,...)
		if rgn and rgn:GetObjectType() == "FontString" then
			text = text .. (rgn:GetText() or "")
		end
	end
	return text == "" and "0" or text
end

local function SlashHandler(command)
	if command == "" then
		DEFAULT_CHAT_FRAME:AddMessage(f.label..(locked and "locked" or "unlocked"))
		DEFAULT_CHAT_FRAME:AddMessage("/vgs lock")
		DEFAULT_CHAT_FRAME:AddMessage("/vgs unlock")
	elseif command == "unlock" then
		if f.statusBar.locked then
			f.statusBar:EnableMouse(true)
			f.statusBar.locked = false
			locked = false
			DEFAULT_CHAT_FRAME:AddMessage(f.label.."Bar Unlocked.")
	elseif command == "lock" then
		else
			f.statusBar:EnableMouse(false)
			f.statusBar.locked = true
			locked = true
			DEFAULT_CHAT_FRAME:AddMessage(f.label.."Bar Locked.")
		end
	end
end

function f.PLAYER_LOGIN()
	f.vengmax = floor(0.1*UnitHealthMax("player"))
	f.statusBar.bar:SetMinMaxValues(0,f.vengmax)
	f.statusBar.bar:SetValue(0)
	f.statusBar.Text:SetText(getText())
	f:UnregisterEvent("PLAYER_LOGIN")
	if class == "DRUID" then
		f:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	end
	f:RegisterEvent("PLAYER_ALIVE")
	checkTank()
end

function f.ACTIVE_TALENT_GROUP_CHANGED()
	checkTank()
end

function f.UPDATE_SHAPESHIFT_FORM()
	checkTank()
end

function f.PLAYER_ENTERING_WORLD()
	checkTank()
end

function f.PLAYER_ALIVE()
	checkTank()
	f:UnregisterEvent("PLAYER_ALIVE")
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function f.UNIT_MAXHEALTH(...)
	local unit = ...;
	if unit == "player" then
		f.vengmax = floor(0.1*UnitHealthMax("player"))
		f.statusBar.bar:SetMinMaxValues(0,f.vengmax)
		f.statusBar.Text:SetText(getText())
	end
end

function f.UNIT_AURA(...)
	local unit = ...;
	if unit == "player" then
		local n = UnitAura("player", (GetSpellInfo(93098)));
		local vengval = 0
		if n then
			f.ScanTip:ClearLines()
			f.ScanTip:SetUnitBuff("player",n)
			local tipText = getTooltipText(f.ScanTip:GetRegions())
			vengval = tonumber(string.match(tipText,"%d+"))
			f.vengmax = floor(0.1*UnitHealthMax("player"))
		end 
		
		f.statusBar.bar:SetMinMaxValues(0,f.vengmax)
		f.statusBar.bar:SetValue(vengval)

		f.statusBar.Text:SetText(getText())
	end
end

SlashCmdList["VENGEANCESTATUS"] = SlashHandler
SLASH_VENGEANCESTATUS1 = "/vgs"
SLASH_VENGEANCESTATUS2 = "/vengeancestatus"

f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
f:RegisterEvent("UNIT_AURA")
f:RegisterEvent("UNIT_MAXHEALTH")

f:SetScript("OnEvent", 
function(self, event, ...) 
	if self[event] then
		self[event](...)
	end
end)

f.statusBar = CreateFrame("Frame", "VengeanceStatus_StatusBarFrame", UIParent)
f.statusBar:SetWidth(width)
f.statusBar:SetHeight(height)
f.statusBar:SetPoint("CENTER")
f.statusBar:SetClampedToScreen(true)
TukuiDB.SetTemplate(f.statusBar)

f.statusBar.bar = CreateFrame("StatusBar", "VengeanceStatus_StatusBar", UIParent) --f.statusBar)
f.statusBar.bar:SetWidth(width-4)
f.statusBar.bar:SetHeight(height-4)
f.statusBar.bar:SetPoint("CENTER",f.statusBar,"CENTER",0,0)

f.statusBar.bar:SetStatusBarTexture(TukuiCF["media"].normTex);
f.statusBar.bar:SetStatusBarColor(classcolor.r, classcolor.g, classcolor.b, 1);
f.statusBar.bar:SetOrientation(orientation)
	
local bartext = f.statusBar:CreateFontString(nil, "OVERLAY")
f.statusBar.Text = bartext
f.statusBar.Text:SetFontObject("GameFontHighlightSmall")
f.statusBar.Text:SetPoint("CENTER",f.statusBar,"CENTER",0,0)
f.statusBar.Text:SetTextColor(1,1,1)

f.statusBar.bar:SetMinMaxValues(0,1)
f.statusBar.bar:SetValue(1)
	
f.statusBar:SetMovable();
f.statusBar:RegisterForDrag("LeftButton");

f.statusBar:SetScript("OnDragStart", function(self, button) self:StartMoving() end);
f.statusBar:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end);

if not locked then
	f.statusBar:EnableMouse(true)
	f.statusBar.locked = nil
else
	f.statusBar:EnableMouse(false)
	f.statusBar.locked = true
end

f.statusBar:Show();