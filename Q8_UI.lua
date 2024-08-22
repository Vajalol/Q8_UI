-- Create the main frame for the addon
local Q8_UI = CreateFrame("Frame", "Q8_UIFrame", UIParent)
Q8_UI:SetPoint("CENTER")  -- Position the frame in the center of the screen
Q8_UI:SetSize(200, 50)  -- Set the initial size of the frame
Q8_UI:SetMovable(true)  -- Allow the frame to be moved by the player
Q8_UI:EnableMouse(true)  -- Enable mouse interaction for dragging
Q8_UI:RegisterForDrag("LeftButton")  -- Allow dragging with the left mouse button
Q8_UI:SetScript("OnDragStart", Q8_UI.StartMoving)  -- Start moving the frame when dragging starts
Q8_UI:SetScript("OnDragStop", Q8_UI.StopMovingOrSizing)  -- Stop moving the frame when dragging stops

-- Default settings for the addon
Q8_UI_Settings = {
    showTargets = true,  -- Whether to show who is targeting the player
    colorizeActionBars = true,  -- Whether to colorize action bars and frames based on class color
}

-- Function to update the display of players targeting you
local function UpdateTargeting()
    -- If the setting is disabled, return immediately
    if not Q8_UI_Settings.showTargets then return end

    local numGroupMembers = GetNumGroupMembers()  -- Get the number of players in your group/raid
    Q8_UIFrame:Hide()  -- Initially hide the frame

    -- If there are group members, check who is targeting you
    if numGroupMembers > 0 then
        local index = 1  -- Index to track the position of each targeting player in the UI
        for i = 1, numGroupMembers do
            local unit = "raid"..i  -- Check each raid member (for a party, you could use "party" instead)
            if UnitExists(unit) and UnitIsUnit("player", unit.."target") then  -- If the unit exists and is targeting the player
                local name = UnitName(unit)  -- Get the name of the targeting player
                local _, class = UnitClass(unit)  -- Get the class of the targeting player
                local classColor = RAID_CLASS_COLORS[class]  -- Get the class color

                -- If the name and class color are available, display them
                if name and classColor then
                    -- Create or reuse a font string to display the player's name and class icon
                    local targetFrame = _G["Q8_UITarget"..index] or Q8_UIFrame:CreateFontString("Q8_UITarget"..index, "OVERLAY", "GameTooltipText")
                    targetFrame:SetPoint("TOPLEFT", Q8_UIFrame, "TOPLEFT", 10, -index * 20)  -- Position the name
                    -- Add the class icon before the name
                    targetFrame:SetText("|TInterface\\TargetingFrame\\UI-Classes-Circles:16:16:0:0:256:256:64:128:64:128|t " .. name)
                    -- Set the text color to the class color
                    targetFrame:SetTextColor(classColor.r, classColor.g, classColor.b)
                    targetFrame:Show()  -- Show the target frame
                    
                    -- Adjust the height of the main frame to fit all targeting players
                    Q8_UIFrame:SetHeight(index * 20)
                    Q8_UIFrame:Show()  -- Show the main frame
                    index = index + 1  -- Move to the next position for the next targeting player
                end
            end
        end

        -- Hide any unused target frames to prevent clutter
        for i = index, numGroupMembers do
            local unusedFrame = _G["Q8_UITarget"..i]
            if unusedFrame then
                unusedFrame:Hide()
            end
        end
    end
end

-- Function to colorize action bars and other UI elements based on the player's class
local function ColorizeActionBars()
    -- If the setting is disabled, return immediately
    if not Q8_UI_Settings.colorizeActionBars then return end

    local _, playerClass = UnitClass("player")  -- Get the player's class
    local classColor = RAID_CLASS_COLORS[playerClass]  -- Get the class color for the player

    -- Colorize each action button
    for i = 1, 12 do
        local button = _G["ActionButton"..i]  -- Get each action button
        if button then
            button:GetNormalTexture():SetVertexColor(classColor.r, classColor.g, classColor.b)  -- Set the button color
        end
    end

    -- Function to apply color to specific frames
    local function ColorizeFrame(frame)
        if frame then
            if frame.SetBackdropBorderColor then
                frame:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b)  -- Set the border color
            end
            if frame.SetBackdropColor then
                frame:SetBackdropColor(classColor.r * 0.3, classColor.g * 0.3, classColor.b * 0.3)  -- Set the background color
            end
        end
    end

    -- Apply the color to common UI elements
    ColorizeFrame(PlayerFrame)
    ColorizeFrame(TargetFrame)
    -- Add more frames as needed, such as MainMenuBar, Minimap, etc.
end

-- Function to create and load the settings panel
local function Q8_UI_SettingsPanel_OnLoad(panel)
    panel.name = "Q8_UI"  -- Set the name of the panel for the Interface Options

    -- Create a title for the settings panel
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Q8_UI Settings")

    -- Checkbox to toggle showing targeting players
    local showTargetsCheckbox = CreateFrame("CheckButton", "Q8_UI_ShowTargetsCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
    showTargetsCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
    showTargetsCheckbox.Text:SetText("Show Targeting Players")
    showTargetsCheckbox:SetChecked(Q8_UI_Settings.showTargets)
    showTargetsCheckbox:SetScript("OnClick", function(self)
        Q8_UI_Settings.showTargets = self:GetChecked()  -- Save the setting
        UpdateTargeting()  -- Apply changes immediately
    end)

    -- Checkbox to toggle colorizing action bars
    local colorizeActionBarsCheckbox = CreateFrame("CheckButton", "Q8_UI_ColorizeActionBarsCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
    colorizeActionBarsCheckbox:SetPoint("TOPLEFT", showTargetsCheckbox, "BOTTOMLEFT", 0, -8)
    colorizeActionBarsCheckbox.Text:SetText("Colorize Action Bars")
    colorizeActionBarsCheckbox:SetChecked(Q8_UI_Settings.colorizeActionBars)
    colorizeActionBarsCheckbox:SetScript("OnClick", function(self)
        Q8_UI_Settings.colorizeActionBars = self:GetChecked()  -- Save the setting
        ColorizeActionBars()  -- Apply changes immediately
    end)

    -- Add the settings panel to the Interface Options
    InterfaceOptions_AddCategory(panel)
end

-- Create the settings panel and load its content
local Q8_UI_SettingsPanel = CreateFrame("Frame", "Q8_UI_SettingsPanel", UIParent)
Q8_UI_SettingsPanel_OnLoad(Q8_UI_SettingsPanel)

-- Register events to update targeting when certain conditions change
Q8_UI:RegisterEvent("PLAYER_TARGET_CHANGED")
Q8_UI:RegisterEvent("GROUP_ROSTER_UPDATE")
Q8_UI:RegisterEvent("UNIT_TARGET")
Q8_UI:SetScript("OnEvent", UpdateTargeting)

-- Apply settings when the addon is loaded
ColorizeActionBars()

-- Create a slash command to open the settings panel
SLASH_Q8UI1 = "/Q8_UI"
SlashCmdList["Q8UI"] = function(msg)
    InterfaceOptionsFrame_OpenToCategory("Q8_UI")  -- Open the Q8_UI settings panel
    InterfaceOptionsFrame_OpenToCategory("Q8_UI")  -- Call it twice due to a WoW bug that sometimes doesn't open the panel on the first try
end
