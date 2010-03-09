-- $Id: core.lua 550 2010-03-02 15:27:53Z john.d.mann@gmail.com $
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("WORLD_MAP_UPDATE")

local function MapInitialize(self)
	if WorldMapFrame.sizedDown then
		ToggleFrame(WorldMapFrame)
		WorldMapFrameSizeDownButton_OnClick()
		ToggleFrame(WorldMapFrame)
	end

	-- Prevent unwanted frames from showing
	recLib.Kill(BlackoutWorld)
	recLib.Kill(WorldMapQuestDetailScrollFrame)
	recLib.Kill(WorldMapQuestRewardScrollFrame)
	recLib.Kill(WorldMapQuestScrollFrame)
	recLib.Kill(WorldMapBlobFrame)
	recLib.Kill(WorldMapQuestShowObjectives)
	recLib.Kill(WorldMapFrameSizeDownButton)
	recLib.Kill(WorldMapFrameCloseButton)
	recLib.Kill(WorldMapZoneMinimapDropDown)
	recLib.Kill(WorldMapZoomOutButton)
	recLib.Kill(WorldMapLevelDropDown)
	recLib.Kill(WorldMapFrameTitle)
	recLib.Kill(WorldMapContinentDropDown)
	recLib.Kill(WorldMapZoneDropDown)
	recLib.Kill(WorldMapLevelUpButton)
	recLib.Kill(WorldMapLevelDownButton)

	-- Move map to the top left of the screen
	WorldMapPositioningGuide:ClearAllPoints()
	WorldMapPositioningGuide:SetPoint("CENTER", UIParent, "CENTER", 0, 252)

	-- Enable POI
	SetCVar("questPOI", 1)

	-- Allow UI to show in background and make map closeable with Esc key.
	UIPanelWindows["WorldMapFrame"] = {area = "center", pushable = 9}
	WorldMapFrame:SetAttribute("UIPanelLayout-enabled", false)

	-- Resize the map.
	WorldMapFrame:SetScale(0.6)
	WorldMapFrame.scale = 1
	WorldMapFrame.SetScale = recLib.NullFunction

	-- Set our map scale and position
	WorldMapDetailFrame:SetScale(1)
	WorldMapDetailFrame:SetPoint("TOPLEFT", WorldMapPositioningGuide, "TOP", -502, -69)

	-- Sets the button scale - this affects many map addon displays for some reason.
	WorldMapButton:SetScale(1)
	WorldMapButton.SetScale = recLib.NullFunction

	-- Scale the POI frame so icons appear in the proper location.
	WorldMapPOIFrame:SetScale(1)
	WorldMapPOIFrame.ratio = 1
	WorldMapPOIFrame.SetScale = recLib.NullFunction
	WorldMapFrame_SetPOIMaxBounds()
	
	-- Force tooltips to hide when leaving a POI
	--WorldMapQuestPOI_OnLeave = function()
		--WorldMapTooltip:Hide()
	--end

	-- Make the map slightly transparent.
	WorldMapFrame:SetAlpha(0.5)
	WorldMapFrame.SetAlpha = recLib.NullFunction

	-- Let you have character control
	WorldMapFrame:EnableKeyboard(false)
	WorldMapFrame:EnableMouse(false)
	WorldMapFrame.EnableKeyboard = recLib.NullFunction
	WorldMapFrame.EnableMouse = recLib.NullFunction

	-- Spoof map into thinking it does not need to be resized.
	WorldMapFrame.sizedDown = true
	
	tinsert(UISpecialFrames, "WorldMapFrame")
	
	--[[
		WorldMapFrame:HookScript("OnShow", function()
			-- OPTIONAL  Loads background/border art
			WorldMap_LoadTextures()
		end)
	--]]
	
	-- Place a backdrop behind map.
	WorldMapDetailFrame.bg = CreateFrame("Frame", nil, WorldMapDetailFrame)
	WorldMapDetailFrame.bg:SetPoint("TOPLEFT", -10, 10)
	WorldMapDetailFrame.bg:SetPoint("BOTTOMRIGHT", 10, -10)
	WorldMapDetailFrame.bg:SetBackdrop({
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
		edgeFile = [[Interface\Addons\recMedia\caellian\glowtex]], edgeSize = 4,
		insets = {left = 3, right = 3, top = 3, bottom = 3}
	})
	WorldMapDetailFrame.bg:SetFrameStrata("BACKGROUND")
	WorldMapDetailFrame.bg:SetBackdropColor(0, 0, 0, 1)
	WorldMapDetailFrame.bg:SetBackdropBorderColor(0, 0, 0)

	-- Override Blizzard's function with one that keeps the extra panels from showing.
	WorldMapFrame_AdjustMapAndQuestList = recLib.NullFunction
	
	WorldMapButton.cursor_coordinates = WorldMapButton:CreateFontString(nil, "ARTWORK")
	WorldMapButton.cursor_coordinates:SetPoint("BOTTOMLEFT", WorldMapButton, "BOTTOMLEFT", 5, 5)
	WorldMapButton.cursor_coordinates:SetFont(recMedia.fontFace.NORMAL, 18, "OUTLINE")
	WorldMapButton.cursor_coordinates:SetTextColor(0.84, 0.75, 0.65)
	WorldMapButton.timer = 0.125
	
	WorldMapButton:HookScript("OnUpdate", function(self, elapsed)
		self.timer = self.timer - elapsed
		if self.timer > 0 then return end
		self.timer = 0.125
		local CenterX, CenterY = WorldMapDetailFrame:GetCenter()
		local CursorX, CursorY = GetCursorPosition()
		CursorX = ((CursorX / WorldMapFrame:GetScale()) - (CenterX - (WorldMapDetailFrame:GetWidth() / 2))) / 10
		CursorY = (((CenterY + (WorldMapDetailFrame:GetHeight() / 2)) - (CursorY / WorldMapFrame:GetScale())) / WorldMapDetailFrame:GetHeight()) * 100

		if CursorX >= 100 or CursorY >= 100 or CursorX <= 0 or CursorY <= 0 then
			self.cursor_coordinates:SetText(" ")
		else
			self.cursor_coordinates:SetFormattedText("%.1f, %.1f", CursorX, CursorY)
		end
	end)
	
	-- We don't need to run this again.
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

f:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		MapInitialize(self)
		MapInitialize = nil
	elseif event == "WORLD_MAP_UPDATE" then
		-- Update the map with quest data.
		WatchFrame_GetCurrentMapQuests()
		WatchFrame_Update()
		WorldMapFrame_UpdateQuests()
	end
end)