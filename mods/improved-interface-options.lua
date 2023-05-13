-- Based on zUI skinning (https://github.com/Ko0z/zUI)
-- Credit to Ko0z (https://github.com/Ko0z/)

local module = ShaguTweaks:register({
    title = "Improved Interface Options",
    description = "Rescales the interface options menu and removes the background.",
    expansions = { ["vanilla"] = true, ["tbc"] = true },
    category = nil,
    enabled = nil,
})
  
module.enable = function(self)
    InterfaceOptionsFrame:SetScript("OnShow", function()
        -- default events
        -- UIOptionsFrame_Load();
		-- InterfaceOptionsFrame_OnLoad (self)
        MultiActionBar_Update();
        MultiActionBar_ShowAllGrids();
        Disable_BagButtons();
        UpdateMicroButtons();

        -- customize
        -- UIOptionsBlackground:Hide()
        InterfaceOptionsFrame:SetScale(1)
    end)
end