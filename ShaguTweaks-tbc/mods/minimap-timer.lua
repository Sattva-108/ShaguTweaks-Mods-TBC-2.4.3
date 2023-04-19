local _G = ShaguTweaks.GetGlobalEnv()

local module = ShaguTweaks:register({
  title = "MiniMap Timer",
  description = "Adds a togglable timer to the minimap clock. Left click the clock to toggle the timer. Left click the timer to start or right click to reset.",
  expansions = { ["vanilla"] = true, ["tbc"] = true },
  category = "World & MiniMap",
  enabled = nil,
})

-- create frame to avoid MinimapButtonBag addons hooking my own Frames. 
local MTframeWidth = Minimap:GetWidth()
local MTframeHeight = 1 -- replace with the actual height of your frame

local MTclusterWidth = Minimap:GetWidth() * Minimap:GetScale()
local MTclusterHeight = Minimap:GetHeight() * Minimap:GetScale()

local MTwidthScale = MTframeWidth / MTclusterWidth
local MTheightScale = MTframeHeight / MTclusterHeight

local MTstyleFrame = CreateFrame("Frame", nil, Minimap)
MTstyleFrame:SetPoint("CENTER", Minimap, "BOTTOM")

MTstyleFrame:SetSize(MTclusterWidth * MTwidthScale, MTclusterHeight * MTheightScale)


-- locals for adjusting minimap timer based on minimap scale, width
local frameWidth = Minimap:GetWidth() + 8 -- replace with the actual width of your frame
local frameHeight = 30 -- replace with the actual width of your frame

local clusterWidth = MinimapCluster:GetWidth() * MinimapCluster:GetScale()
local clusterHeight = MinimapCluster:GetHeight() * MinimapCluster:GetScale()

local widthScale = frameWidth / clusterWidth
local heightScale = frameHeight / clusterHeight

--create minimap timer frame
MinimapTimer = CreateFrame("BUTTON", "Timer", MTstyleFrame)
MinimapTimer:Hide()
MinimapTimer:SetFrameLevel(64)

-- MinimapTimer:SetWidth(width)
-- MinimapTimer:SetHeight(23)
MinimapTimer:SetSize(clusterWidth * widthScale, clusterHeight * heightScale)

MinimapTimer:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 8, edgeSize = 16,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
MinimapTimer:SetBackdropBorderColor(.9,.8,.5,1)
MinimapTimer:SetBackdropColor(.4,.4,.4,1)

module.enable = function(self)
  MinimapTimer:EnableMouse(true)
  local timertext = MinimapTimer:CreateFontString("Status", "LOW", "GameFontNormal")
  timertext:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
  timertext:SetFontObject(GameFontWhite)
  timertext:SetAllPoints(MinimapTimer)

  local timermax = 99 * 3600 + 59 * 60 + 59 -- 99:59:59
  local timerstarted = nil
  local timerelapsed = nil
  local timerpaused = nil
  
local function formattime(e, speedup)
  if e then
    local speedup = 1 -- for testing purpose, 1 = normal timer speed.
    local t = floor(e * speedup) -- Multiply elapsed time by the speedup factor
    local h = floor(mod(t, 86400) / 3600)
    local m = floor(mod(t, 3600) / 60)
    local s = floor(mod(t, 60))
    return h, m, s
  else
    return 0, 0, 0
  end
end

local function updatetext()
  local h, m, s = formattime(timerelapsed)
  local color_inactive = "7f7f7f" -- Lowered alpha color (grey)

  -- Hiding hours if its not active
  -- Change color of m, s if they are not active.
  if h == 0 and m == 0 and s == 0 then
    timertext:SetText(format("|cff%s%02d : |r|cff%s%02d|r", color_inactive, m, color_inactive, s))
   -- Change color of m if it's not active.   
  elseif h == 0 and m == 0 and s > 0 then
    timertext:SetText(format("|cff%s%02d : |r%02d", color_inactive, m, s))
   -- Do not change color if both m and s are active.
  elseif h == 0 and m > 0 then
    timertext:SetText(format("%02d : %02d", m, s))
   -- Do not change color all h, m, s are active.
  elseif h > 0 then
    timertext:SetText(format("%02d : %02d : %02d", h, m, s))  
  end
end

  local function starttimer()
    timerstarted = GetTime()
    ElapsedTimer:Show()
  end

  local function stoptimer()
    ElapsedTimer:Hide()
  end

  local function resettimer()
    stoptimer()
    timerstarted = nil
    timerelapsed = nil
    timerpaused = nil
    updatetext()    
  end

  local function pausetimer()
    stoptimer()
    timerpaused = GetTime()
  end

  local function continuetimer()
    timerstarted = timerstarted + (GetTime() - timerpaused)
    timerpaused = nil
    ElapsedTimer:Show()
  end

  local function hidetimer()
    resettimer()
    MinimapTimer:Hide()
  end

  ElapsedTimer = CreateFrame("FRAME", nil, MinimapTimer)
  ElapsedTimer:Hide()
  ElapsedTimer:SetScript("OnUpdate", function()
    timerelapsed = GetTime() - timerstarted    
    if timerelapsed > timermax then
      timerelapsed = timermax
      this:Hide()
    else
      updatetext()
    end
  end)  

  MinimapTimer:RegisterForClicks("LeftButtonDown","RightButtonDown")
  MinimapTimer:SetScript("OnClick", function()
      if (arg1 == "LeftButton") then
        if timerpaused then
          continuetimer()          
        elseif not timerstarted then
          starttimer()
        else
          pausetimer()
        end        
      elseif (arg1 == "RightButton") then
        resettimer()
      end
  end)

  local function setuptimer()
    local function toggle()
      resettimer()
      if not MinimapTimer:IsVisible() then
        MinimapTimer:Show()
      else
        MinimapTimer:Hide()
      end
    end

    if TimeManagerClockButton and TimeManagerClockButton:IsVisible() then
      MinimapTimer:SetPoint("TOP", TimeManagerClockButton, "BOTTOM", 1, -15)
      TimeManagerClockButton:SetScript("OnMouseDown", toggle)
    elseif GameTimeFrame:IsVisible() then
      MinimapTimer:SetPoint("TOP", Minimap, "BOTTOM", 1, -20)
      GameTimeFrame:SetScript("OnMouseDown", toggle)
    else
      MinimapTimer:SetPoint("TOP", Minimap, "BOTTOM", 1, -20)
      MinimapTimer:Show()
    end
  end

  local events = CreateFrame("Frame", nil, UIParent)
    events:RegisterEvent("PLAYER_ENTERING_WORLD")

    events:SetScript("OnEvent", function()
      setuptimer()      
    end)
end
