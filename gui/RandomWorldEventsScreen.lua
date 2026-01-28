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
---@class RandomWorldEventsScreen
---@field pageOptionsEvents RandomWorldEventsFrame
---@field pageOptionsDebug RandomWorldDebugFrame
RandomWorldEventsScreen = {}
local RandomWorldEventsScreen_mt = Class(RandomWorldEventsScreen, TabbedMenuWithDetails)

RandomWorldEventsScreen.CONTROLS = {
    'pageOptionsEvents',
    'pageOptionsDebug',
}

function RandomWorldEventsScreen.new(target, customMt, messageCenter, l10n, inputManager)
    local self = TabbedMenuWithDetails.new(target, customMt or RandomWorldEventsScreen_mt, messageCenter, l10n, inputManager)

    self:registerControls(RandomWorldEventsScreen.CONTROLS)

    return self
end

function RandomWorldEventsScreen:onGuiSetupFinished()
    RandomWorldEventsScreen:superClass().onGuiSetupFinished(self)

    self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)

    self.pageOptionsEvents:initialize()
    self.pageOptionsDebug:initialize()

    self:setupPages()
    self:setupMenuButtonInfo()
end

function RandomWorldEventsScreen:setupPages()
    local pages = {
        {
            self.pageOptionsEvents,
            'settings.dds'
        },
        {
            self.pageOptionsDebug,
            'events.dds'
        },
    }

    for i, _page in ipairs(pages) do
        local page, icon = unpack(_page)
        self:registerPage(page, i)
        self:addPageTab(page, g_RandomWorldEvents.modFolder .. 'icons/' .. icon)
    end
end

function RandomWorldEventsScreen:setupMenuButtonInfo()
    local onButtonBackFunction = self.clickBackCallback
    self.defaultMenuButtonInfo = {
        {
            inputAction = InputAction.MENU_BACK,
            text = self.l10n:getText(InGameMenu.L10N_SYMBOL.BUTTON_BACK),
            callback = onButtonBackFunction
        }
    }
    self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
    self.defaultButtonActionCallbacks = {
        [InputAction.MENU_BACK] = onButtonBackFunction,
    }
end

function RandomWorldEventsScreen:exitMenu()
    self:changeScreen()
end