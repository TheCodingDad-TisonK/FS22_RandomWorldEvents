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
---@class RandomEventsDebugFrame
---@field physicsEnabled CheckedOptionElement
---@field wheelGripMultiplier TextInputElement
---@field articulationDamping TextInputElement
---@field comStrength TextInputElement
---@field suspensionStiffness TextInputElement
---@field showPhysicsInfo CheckedOptionElement
---@field debugMode CheckedOptionElement
---@field boxLayout BoxLayoutElement
RandomEventsDebugFrame = {}

local RandomEventsDebugFrame_mt = Class(RandomEventsDebugFrame, TabbedMenuFrameElement)

RandomEventsDebugFrame.CONTROLS = {
    'physicsEnabled',
    'wheelGripMultiplier',
    'articulationDamping',
    'comStrength',
    'suspensionStiffness',
    'showPhysicsInfo',
    'debugMode',
    'boxLayout'
}

function RandomEventsDebugFrame.new(target, customMt)
    local self = TabbedMenuFrameElement.new(target, customMt or RandomEventsDebugFrame_mt)

    self:registerControls(RandomEventsDebugFrame.CONTROLS)

    return self
end

function RandomEventsDebugFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function RandomEventsDebugFrame:onFrameOpen()
    RandomEventsDebugFrame:superClass().onFrameOpen(self)
    self:updateRandomEvents()

    self.boxLayout:invalidateLayout()

    if FocusManager:getFocusedElement() == nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayout)
        self:setSoundSuppressed(false)
    end
end

function RandomEventsDebugFrame:updateRandomEvents()
    self.physicsEnabled:setIsChecked(g_RandomWorldEvents:getTypeNameValue('physics', 'enabled'))
    self.showPhysicsInfo:setIsChecked(g_RandomWorldEvents:getTypeNameValue('physics', 'showPhysicsInfo'))
    self.debugMode:setIsChecked(g_RandomWorldEvents:getTypeNameValue('physics', 'debugMode'))

    self:setElementText(self.wheelGripMultiplier, g_RandomWorldEvents:getTypeNameValue('physics', 'wheelGripMultiplier'))
    self:setElementText(self.articulationDamping, g_RandomWorldEvents:getTypeNameValue('physics', 'articulationDamping'))
    self:setElementText(self.comStrength, g_RandomWorldEvents:getTypeNameValue('physics', 'comStrength'))
    self:setElementText(self.suspensionStiffness, g_RandomWorldEvents:getTypeNameValue('physics', 'suspensionStiffness'))
end

function RandomEventsDebugFrame:setElementText(element, value)
    element:setText(string.format('%.2f', value))
end

---@param state number
---@param element CheckedOptionElement
function RandomEventsDebugFrame:onCheckClick(state, element)
    g_RandomWorldEvents:setTypeNameValue('physics', element.id, state == CheckedOptionElement.STATE_CHECKED)
    g_RandomWorldEvents:saveSettings()
end

---@param element TextInputElement
function RandomEventsDebugFrame:onEnterPressedTextInput(element)
    local value = tonumber(element.text)

    if value ~= nil then
        if value < 0.1 then
            value = 0.1
        end
        if value > 5.0 then
            value = 5.0
        end
        g_RandomWorldEvents.physics[element.id] = value
    end

    self:setElementText(element, g_RandomWorldEvents:getTypeNameValue('physics', element.id))
    g_RandomWorldEvents:saveSettings() 
end
