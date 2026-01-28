-- =========================================================
-- Random World Events (version 1.2.0.0)
-- =========================================================
-- Random events that can occur. Settings can be changed!
-- =========================================================
-- Author: TisonK
-- =========================================================
-- COPYRIGHT NOTICE:
-- All rights reserved. Unauthorized redistribution, copying,
-- or claiming this code as your own is strictly prohibited.
-- Original author: TisonK
-- =========================================================
---@class RandomWorldEventsFrame
---@field eventsEnabled CheckedOptionElement
---@field eventsFrequency TextInputElement
---@field eventsIntensity TextInputElement
---@field eventsCooldown TextInputElement
---@field showNotifications CheckedOptionElement
---@field showWarnings CheckedOptionElement
---@field weatherEvents CheckedOptionElement
---@field economicEvents CheckedOptionElement
---@field vehicleEvents CheckedOptionElement
---@field fieldEvents CheckedOptionElement
---@field wildlifeEvents CheckedOptionElement
---@field specialEvents CheckedOptionElement
---@field triggerEventButtonWrapper GuiElement
---@field boxLayout BoxLayoutElement
RandomWorldEventsFrame = {}

local RandomWorldEventsFrame_mt = Class(RandomWorldEventsFrame, TabbedMenuFrameElement)

RandomWorldEventsFrame.CONTROLS = {
    'eventsEnabled',
    'eventsFrequency',
    'eventsIntensity',
    'eventsCooldown',
    'showNotifications',
    'showWarnings',
    'weatherEvents',
    'economicEvents',
    'vehicleEvents',
    'fieldEvents',
    'wildlifeEvents',
    'specialEvents',
    'triggerEventButtonWrapper',
    'boxLayout'
}

function RandomWorldEventsFrame.new(target, customMt)
    local self = TabbedMenuFrameElement.new(target, customMt or RandomWorldEventsFrame_mt)

    self:registerControls(RandomWorldEventsFrame.CONTROLS)

    return self
end

function RandomWorldEventsFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function RandomWorldEventsFrame:onFrameOpen()
    RandomWorldEventsFrame:superClass().onFrameOpen(self)
    self:updateRandomEvents()

    self.boxLayout:invalidateLayout()

    if FocusManager:getFocusedElement() == nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayout)
        self:setSoundSuppressed(false)
    end
end

function RandomWorldEventsFrame:updateRandomEvents()
    self.eventsEnabled:setIsChecked(g_RandomWorldEvents:getTypeNameValue('events', 'enabled'))
    self.showNotifications:setIsChecked(g_RandomWorldEvents:getTypeNameValue('events', 'showNotifications'))
    self.showWarnings:setIsChecked(g_RandomWorldEvents:getTypeNameValue('events', 'showWarnings'))
    self.weatherEvents:setIsChecked(g_RandomWorldEvents:getTypeNameValue('events', 'weatherEvents'))
    self.economicEvents:setIsChecked(g_RandomWorldEvents:getTypeNameValue('events', 'economicEvents'))
    self.vehicleEvents:setIsChecked(g_RandomWorldEvents:getTypeNameValue('events', 'vehicleEvents'))
    self.fieldEvents:setIsChecked(g_RandomWorldEvents:getTypeNameValue('events', 'fieldEvents'))
    self.wildlifeEvents:setIsChecked(g_RandomWorldEvents:getTypeNameValue('events', 'wildlifeEvents'))
    self.specialEvents:setIsChecked(g_RandomWorldEvents:getTypeNameValue('events', 'specialEvents'))

    self:setElementText(self.eventsFrequency, g_RandomWorldEvents:getTypeNameValue('events', 'frequency'))
    self:setElementText(self.eventsIntensity, g_RandomWorldEvents:getTypeNameValue('events', 'intensity'))
    self:setElementText(self.eventsCooldown, g_RandomWorldEvents:getTypeNameValue('events', 'cooldown'))
end

function RandomWorldEventsFrame:setElementText(element, value)
    element:setText(string.format('%.0f', value))
end

---@param state number
---@param element CheckedOptionElement
function RandomWorldEventsFrame:onCheckClick(state, element)
    local value = state == CheckedOptionElement.STATE_CHECKED

    if element.id == "eventsEnabled" then
        g_RandomWorldEvents:setTypeNameValue("events", "enabled", value)
    else
        g_RandomWorldEvents:setTypeNameValue("events", element.id, value)
    end

    g_RandomWorldEvents:saveSettings()
end

---@param element TextInputElement
function RandomWorldEventsFrame:onEnterPressedTextInput(element)
    local value = tonumber(element.text)
    if value == nil then return end

    if element.id == 'eventsFrequency' then
        value = math.max(1, math.min(10, value))
        g_RandomWorldEvents.events.frequency = value

    elseif element.id == 'eventsIntensity' then
        value = math.max(1, math.min(5, value))
        g_RandomWorldEvents.events.intensity = value

    elseif element.id == 'eventsCooldown' then
        value = math.max(1, math.min(240, value))
        g_RandomWorldEvents.events.cooldown = value
    end

    g_RandomWorldEvents:saveSettings()
    self:setElementText(element, value)
end

function RandomWorldEventsFrame:onTriggerEventClick()
    g_RandomWorldEvents:triggerRandomEvent()
end