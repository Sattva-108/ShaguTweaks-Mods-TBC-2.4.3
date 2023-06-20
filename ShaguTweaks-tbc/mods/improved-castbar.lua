local module = ShaguTweaks:register({
    title = "Improved Castbar",
    description = "Adds a spell icon and remaining cast time to the cast bar.",
    expansions = { ["vanilla"] = true, ["tbc"] = true },
    enabled = nil,
})
local CASTING_BAR_ALPHA = 0.8

module.enable = function(self)
   local _G = ShaguTweaks.GetGlobalEnv()

   Castbars = LibStub("AceAddon-3.0"):NewAddon("ShaguTweaks");

Castbars.SharedMedia = LibStub("LibSharedMedia-3.0");

function Castbars:FrameLayoutRestore(frames)
    for i, frame in pairs(frames) do
        local frameName = frame:GetName();

        -- Position
        local position = self.db.profile[frameName .. "Position"];
        frame:ClearAllPoints();
        frame:SetPoint(position.point, position.parent, position.relpoint, position.x, position.y);

        -- Texture
        local barTexture = self.SharedMedia:Fetch('statusbar', self.db.profile[frameName .. "Texture"]);
        local frameBackdrop = _G[frameName .. "Backdrop"];
        local borderTexture = self.SharedMedia:Fetch('border', self.db.profile[frameName .. "Border"]);
        frame:SetStatusBarTexture(barTexture);
        frameBackdrop:SetBackdrop({edgeFile = borderTexture, edgeSize = 16, tileSize = 16, insets = {bottom = 5, top = 5, right = 5, left = 5}});
        local brightness = self.db.profile[frameName .. "BorderBrightness"];
        frameBackdrop:SetBackdropBorderColor(brightness, brightness, brightness, 1.0);

        -- Dimensions
        frame:SetWidth(self.db.profile[frameName .. "Width"]);
        frame:SetHeight(self.db.profile[frameName .. "Height"]);

        -- Icon position
        local frameIcon = _G[frameName .. "Icon"];
        frameIcon:ClearAllPoints();
        if (self.db.profile[frameName .. "Border"] == "None") then
            frameIcon:SetPoint("RIGHT", frame, "LEFT", 0, 0);
            frameIcon:SetHeight(self.db.profile[frameName .. "Height"]);
            frameIcon:SetWidth(self.db.profile[frameName .. "Height"]);
        else
            frameIcon:SetPoint("RIGHT", frame, "LEFT", -5, 0);
            frameIcon:SetHeight(self.db.profile[frameName .. "Height"] + 5);
            frameIcon:SetWidth(self.db.profile[frameName .. "Height"] + 5);
        end

        -- Visibility
        if (self.db.profile[frameName .. "Show"] == false) then
            frame.showCastbar = false;
        else
            frame.showCastbar = true;
        end
    end
end

function Castbars:FrameCustomize(frames)
    for i, frame in pairs(frames) do
        local frameName = frame:GetName();

        -- Make dragable
        frame:EnableMouse(true);
        frame:SetMovable(true);
        frame:RegisterForDrag("LeftButton");
        frame:SetScript("OnDragStart", function(frame)
            if (self.ConfigMode) then
                frame:StartMoving();
            end
        end);
        frame:SetScript("OnDragStop", function(frame)
            frame:StopMovingOrSizing();
            local position = self.db.profile[frameName .. "Position"];
            position.point, position.parent, position.relpoint, position.x, position.y = frame:GetPoint();
        end);

        -- Adjust spark position
        local frameSpark = _G[frameName .. "Spark"];
        local setPoint = frameSpark.SetPoint;
        frameSpark.SetPoint = function(self, point, relativeFrame, realativePoint, x, y)
            setPoint(self, point, relativeFrame, realativePoint, x, 0);
        end

        -- Adjust text position
        local frameText = _G[frameName .. "Text"];
        frameText:ClearAllPoints();
        frameText:SetPoint("CENTER", frame, "CENTER", 0, 0);

        -- Remove the border
        local frameBorder = _G[frameName .. "Border"];
        frameBorder:SetTexture();

        -- Remove the flash
        local frameFlash = _G[frameName .. "Flash"];
        frameFlash:SetTexture();

        -- Create backdrop
        frame.backdrop = CreateFrame("Frame", frameName .. "Backdrop", frame);
        frame.backdrop:SetPoint("CENTER", frame, "CENTER", 0, 0);

        -- Make icon visible
        local frameIcon = _G[frameName .. "Icon"];
        frameIcon:Show();

        -- Add timer text
        frame.timer = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
        frame.timer:SetPoint("RIGHT", frame, "RIGHT", -5, 0);
        frame.nextupdate = 0.1;

        -- Add latency indication texture
        frame.latency = frame:CreateTexture(nil, "BACKGROUND");
        frame.latency:SetHeight(frame:GetHeight());
        frame.latency:SetPoint("RIGHT", frame, "RIGHT", 0, 0);
        frame.latency:SetTexture(1, 0, 0, 1);

        -- Automatically adjust the height of sub elements
        local setHeight = frame.SetHeight;
        frame.SetHeight = function(self, height)
            frame.backdrop:SetHeight(height + 10);
            frameSpark:SetHeight(2.5 * height);
            frame.latency:SetHeight(height);
            setHeight(self, height);
        end

        -- Automatically adjust the width of sub elements
        local setWidth = frame.SetWidth
        frame.SetWidth = function(self, width)
            frame.backdrop:SetWidth(width + 10);
            setWidth(self, width);
        end

        frame:Hide();
    end
end



function Castbars:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("CastbarsDB",
    {
        profile =
        {
            CastingBarFrameShow = true,
            CastingBarFrameWidth = 195,
            CastingBarFrameHeight = 13,
            CastingBarFrameTexture = "Blizzard",
            CastingBarFrameBorder = "Blizzard Dialog",
            CastingBarFrameBorderBrightness = 0.5,
            CastingBarFramePosition = {point = "BOTTOM", relpoint = "BOTTOM", x = 0, y = 200},

            CastingBarTargetFrameShow = true,
            CastingBarTargetFrameWidth = 195,
            CastingBarTargetFrameHeight = 13,
            CastingBarTargetFrameTexture = "Blizzard",
            CastingBarTargetFrameBorder = "None",
            CastingBarTargetFrameBorderBrightness = 0.5,
            CastingBarTargetFramePosition = {point = "CENTER", relpoint = "CENTER", x = 0, y = 200},
        }
    });

    -- LibStub("AceConfig-3.0"):RegisterOptionsTable("Castbars", self:GetOptionsTable());
    -- self.BlizzardOptionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Castbars", "Castbars");

    -- Prevent the UIParent from moving the CastingBarFrame around
    UIPARENT_MANAGED_FRAME_POSITIONS["CastingBarFrame"] = nil;

    -- Create target casting bar
    CreateFrame("StatusBar", "CastingBarTargetFrame", UIParent, "CastingBarFrameTemplate");
    CastingBarTargetFrame:SetScript("OnEvent", function(frame, event, ...)
        if (event == "PLAYER_ENTERING_WORLD") then
            -- self:FrameLayoutRestore(self.frames);
        elseif (event == "PLAYER_TARGET_CHANGED") then
            event = "PLAYER_ENTERING_WORLD"
        end
        CastingBarFrame_OnEvent(frame, event, ...);
    end)
    CastingBarTargetFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
    CastingBarFrame_OnLoad(CastingBarTargetFrame, "target", false);

    self.frames = {CastingBarFrame, CastingBarTargetFrame};

    -- Customize the bars
    self:FrameCustomize(self.frames);

    -- Add timer handling code
    
        if (self.timer) then
            if (self.nextupdate < elapsed) then
                if (self.casting) then
                    self.timer:SetText(format("%.1f", max(self.maxValue - self.value, 0)));
                elseif (self.channeling) then
                    self.timer:SetText(format("%.1f", max(self.value, 0)));
                else
                    self.timer:SetText("");
                end;
                self.nextupdate = 0.1;
            else
                self.nextupdate = self.nextupdate - elapsed;
            end;
        end;
   

   

    self.GetOptionsTableForBar = nil;
    self.GetOptionsTable = nil;
    self.FrameCustomize = nil;
    self.OnInitialize = nil;
end

--[[ ConfigMode Support ]]--

Castbars.CastingBarFrame_OnEvent = CastingBarFrame_OnEvent;
Castbars.DoNothing = function() end;

function Castbars:Show()
    self.ConfigMode = true;
    CastingBarFrame_OnEvent = self.DoNothing;
    CastingBarFrameText:SetText("Player Castbar")
    CastingBarFrame:SetStatusBarColor(0.0, 1.0, 0.0);
    CastingBarFrame:SetAlpha(1)
    CastingBarFrameSpark:Hide();
    CastingBarFrameFlash:Hide();
    CastingBarFrame.fadeOut = nil;
    CastingBarFrame:Show();
    CastingBarTargetFrameText:SetText("Target Castbar")
    CastingBarTargetFrame:SetStatusBarColor(0.0, 1.0, 0.0);
    CastingBarTargetFrame:SetAlpha(1)
    CastingBarTargetFrameSpark:Hide();
    CastingBarTargetFrameFlash:Hide();
    CastingBarTargetFrame.fadeOut = nil;
    CastingBarTargetFrame:Show();
end

function Castbars:Hide()
    CastingBarFrame:Hide();
    CastingBarTargetFrame:Hide();
    CastingBarFrame_OnEvent = self.CastingBarFrame_OnEvent;
    self.ConfigMode = false;
end

function Castbars:Toggle()
    if (self.ConfigMode) then
        self:Hide();
    else
        self:Show();
    end
end

CONFIGMODE_CALLBACKS = CONFIGMODE_CALLBACKS or {};
CONFIGMODE_CALLBACKS["Castbars"] = function(action)
    if (action == "ON") then Castbars:Show()
    elseif (action == "OFF") then Castbars:Hide() end
end




local DCT = {}
local spellFormat = "%.1f"
local channelFormat = "%.1f"
local channelDelay = "|cffff2020%-.2f|r"
local castDelay = "|cffff2020%.2f|r"

function DCT:Enable()
	local path = GameFontHighlight:GetFont()

	self.castTimeText = CastingBarFrame:CreateFontString(nil, "ARTWORK")
	self.castTimeText:SetPoint("TOPRIGHT", CastingBarFrame, "TOPRIGHT", -10, 0)
	self.castTimeText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	
	local onHide = CastingBarFrame:GetScript("OnHide")
	CastingBarFrame:SetScript("OnHide", function(...)
		if( onHide ) then
			onHide(...)
		end
		
		CastingBarFrame.spellPushback = nil
	end)
end

local orig_CastingBarFrame_OnUpdate = CastingBarFrame_OnUpdate
function CastingBarFrame_OnUpdate(...)
	orig_CastingBarFrame_OnUpdate(...)
	
	if( CastingBarFrame.unit ~= "player" ) then
		return
	end
	
	if( this.casting and CastingBarFrame.maxValue ) then
		if( not this.spellPushback ) then
			DCT.castTimeText:SetText(format(spellFormat, CastingBarFrame.maxValue - GetTime()))
		else
			DCT.castTimeText:SetText("|cffff2020+|r" .. format(castDelay .. " " .. spellFormat, this.spellPushback, CastingBarFrame.maxValue - GetTime()))
		end
		
		DCT.castTimeText:Show()
	elseif( this.channeling and CastingBarFrame.endTime ) then
		if( not this.spellPushback ) then
			DCT.castTimeText:SetText(format(channelFormat, CastingBarFrame.endTime - GetTime()))
		else
			DCT.castTimeText:SetText("|cffff2020-|r" .. format(channelDelay .. " " .. spellFormat, this.spellPushback, CastingBarFrame.endTime - GetTime()))
		end
		
		DCT.castTimeText:Show()
	else
		DCT.castTimeText:Hide()
	end
end

local orig_CastingBarFrame_OnEvent = CastingBarFrame_OnEvent
function CastingBarFrame_OnEvent(event, unit, ...)
	if( unit == "player" ) then
		if( event == "UNIT_SPELLCAST_DELAYED" ) then
			local name, _, _, _, startTime, endTime = UnitCastingInfo(CastingBarFrame.unit)
			if( not name ) then
				this.spellPushback = nil
				return
			end

			this.spellPushback = ( endTime / 1000 ) - CastingBarFrame.maxValue
		elseif( event == "UNIT_SPELLCAST_CHANNEL_UPDATE" ) then
			local name, _, _, _, startTime, endTime = UnitChannelInfo(CastingBarFrame.unit)
			if( not name or not startTime or not this.startTime ) then
				this.spellPushback = nil
				return
			end
			
			this.spellPushback = this.startTime - ( startTime / 1000 )
		elseif( event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" ) then
			this.spellPushback = nil
		end
	end

	orig_CastingBarFrame_OnEvent(event, unit, ...)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
	
		DCT.Enable(DCT)
	
end)

end