AutoJunk = {}
AutoJunk.name = "AutoJunk"
AutoJunk.enabled = false

AutoJunk.defaults = {
  CHAT_MESSAGES = true
}

local LAM2 = LibStub("LibAddonMenu-2.0")

function AutoJunk:Initialize()
  AutoJunk.settings = ZO_SavedVars:NewAccountWide("AUTOJUNK_CONFIG", 1, nil, AutoJunk.defaults)
  local panelData = {
    type = "panel",
    name = AutoJunk.name,
  }
  local optionsData = {
    [1] = {
      type = "checkbox",
      name = "Enabled",
      tooltip = "If AutoJunk is enabled.",
      reference = "EnabledCheckboxConfig",
      default = function() return AutoJunk.enabled end,
      getFunc = function() return AutoJunk.enabled end,
      setFunc = function(value) 
        if value then
          AutoJunk.Enable()
        else
          AutoJunk.Disable()
        end
      end,
    },
    [2] = {
         type = "checkbox",
         name = "Chat Messages",
         tooltip = "Display on chat looted items.",
         getFunc = function() return AutoJunk.settings.CHAT_MESSAGES end,
         setFunc = function(value) AutoJunk.settings.CHAT_MESSAGES = value end,
    }
  }
  LAM2:RegisterAddonPanel("AutoJunkOptions", panelData)
  LAM2:RegisterOptionControls("AutoJunkOptions", optionsData)
end
 
function AutoJunk.Enable()
  if AutoJunk.enabled then 
    d("AutoJunk is already enabled.")
  else
    AutoJunk.enabled = true
    EVENT_MANAGER:RegisterForEvent("AutoJunk", EVENT_LOOT_RECEIVED, AutoJunk.MarkItemAsJunk)
    EVENT_MANAGER:RegisterForEvent("AutoJunk", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, AutoJunk.OnSingleSlotUpdate)
    EnabledCheckboxConfig:UpdateValue()
    d("AutoJunk is now enabled.")
  end
end

function AutoJunk.Disable()
  if not AutoJunk.enabled then 
    d("AutoJunk is already disabled.")
  else
    AutoJunk.enabled = false
    EVENT_MANAGER:UnregisterForEvent("AutoJunk", EVENT_LOOT_RECEIVED)
    EVENT_MANAGER:UnregisterForEvent("AutoJunk", EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
    EnabledCheckboxConfig:UpdateValue()
    d("AutoJunk is now disabled.")
  end
end

function AutoJunk.OnAddOnLoaded(event, addonName)
  if addonName == AutoJunk.name then
    AutoJunk:Initialize()
  end
end

function AutoJunk.OnSingleSlotUpdate(_, bagId, slotId, _, _, updateReason)
	if (bagId == BAG_BACKPACK or bagId == BAG_VIRTUAL) and updateReason == INVENTORY_UPDATE_REASON_DEFAULT and IsUnderArrest() == false then
		AutoJunk.lastSingleSlotUpdateSlotId = slotId
		AutoJunk.lastSingleSlotUpdateBagId = bagId
	end
end

function AutoJunk.MarkItemAsJunk(eventCode, lootedBy, itemName, quantity, itemSound, lootType, self, isPickpocket, icon, itemId)
  if AutoJunk.enabled then -- just for precautions
    SetItemIsJunk(AutoJunk.lastSingleSlotUpdateBagId, AutoJunk.lastSingleSlotUpdateSlotId, true)
    if AutoJunk.settings.CHAT_MESSAGES then
      d(zo_strformat("|cFFFFFF[AutoJunk]|r |cBEBEBEMarked|r |cFF0000<<1>>|r |cBEBEBEas Junk.|r", itemName))
    end
  end
end

function AutoJunk.CmdHandler(option)
  local options = {}
  local searchResult = { string.match(option,"^(%S*)%s*(.-)$") }

  for i,v in pairs(searchResult) do
      if (v ~= nil and v ~= "") then
          options[i] = string.lower(v)
      end
  end

  if #options == 0 then 
    if AutoJunk.enabled then
      d("AutoJunk is ENABLED. '/aj disable' to turn it off")
    else 
      d("AutoJunk is DISABLED. '/aj enable' to turn it on")
    end
  end

  if options[1] == "enable" or options[1] == "start" then
    AutoJunk.Enable()
  end

  if options[1] == "disable" or options[1] == "stop" then
    AutoJunk.Disable()
  end
end
  
SLASH_COMMANDS["/aj"] = AutoJunk.CmdHandler

EVENT_MANAGER:RegisterForEvent(AutoJunk.name, EVENT_ADD_ON_LOADED, AutoJunk.OnAddOnLoaded)