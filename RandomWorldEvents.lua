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
local modFolder = g_currentModDirectory

---@class RandomWorldEvents
---@field modFolder string
RandomWorldEvents = {
    events = {
        enabled = true,
        frequency = 5,
        intensity = 2,
        showNotifications = true,
        showWarnings = true,
        cooldown = 30,
        
        weatherEvents = false, 
        economicEvents = true,
        vehicleEvents = true,
        fieldEvents = true,
        wildlifeEvents = true,
        specialEvents = true,
        
        debugLevel = 1
    },
    
    debug = {
        enabled = false,
        debugLevel = 1,
        showDebugInfo = false
    },
    
    physics = {
        enabled = true,
        wheelGripMultiplier = 1.0,
        articulationDamping = 0.5,
        comStrength = 1.0,
        suspensionStiffness = 1.0,
        showPhysicsInfo = false,
        debugMode = false
    },
    
    delayedMessageTime = 0,
    showDelayedMessage = false,
    needsSave = false,
    saveTime = nil
}

RandomWorldEvents.EVENT_STATE = {
    activeEvent = nil,
    eventStartTime = 0,
    eventDuration = 0,
    eventData = {},
    history = {},
    cooldownUntil = 0
}

-- =====================
-- EVENT SYSTEM CORE 
-- =====================
RandomWorldEvents.EVENTS = {}

function RandomWorldEvents:getFarmId()
    return g_currentMission and g_currentMission.player and g_currentMission.player.farmId or 0
end

function RandomWorldEvents:getVehicle()
    return g_currentMission and g_currentMission.controlledVehicle or nil
end

function RandomWorldEvents:randomDuration(minMinutes, maxMinutes)
    return (math.random(minMinutes, maxMinutes) * 60000)
end

function RandomWorldEvents:triggerRandomEvent()
    if not self.events.enabled then return false end
    if self.EVENT_STATE.activeEvent ~= nil then return false end
    
    local available = {}
    for eventId, event in pairs(self.EVENTS) do
        local categoryEnabled = self.events[event.category .. "Events"]
        if categoryEnabled and event.canTrigger() and self.events.intensity >= event.minIntensity then
            table.insert(available, eventId)
        end
    end
    
    if #available == 0 then return false end
    
    local eventId = available[math.random(1, #available)]
    local event = self.EVENTS[eventId]
    
    self.EVENT_STATE.activeEvent = eventId
    self.EVENT_STATE.eventStartTime = g_currentMission.time
    
    local duration = 0
    if type(event.duration) == "table" then
        duration = math.random(event.duration.min, event.duration.max) * 60000
    end
    self.EVENT_STATE.eventDuration = duration
    
    local message = event.onStart(self.events.intensity)
    if message and self.events.showNotifications then
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, message)
    end
    
    return true
end

-- =====================
-- PHYSICS SYSTEM CORE
-- =====================
function RandomWorldEvents:updatePhysics(vehicle)
    if not self.physics.enabled or vehicle == nil then 
        return 
    end

    if vehicle.getIsActiveForPhysics == nil or not vehicle:getIsActiveForPhysics() then
        return
    end

    if vehicle.wheels and self.physics.wheelGripMultiplier then
        local grip = self.physics.wheelGripMultiplier
        for _, wheel in pairs(vehicle.wheels) do
            if wheel.physics ~= nil then
                wheel.physics.frictionScale = grip
            end
        end
    end

    if vehicle.wheels and self.physics.suspensionStiffness then
        for _, wheel in pairs(vehicle.wheels) do
            if wheel.suspension ~= nil then
                local originalForce = wheel.suspension.originalSpringForce or wheel.suspension.springForce
                wheel.suspension.originalSpringForce = originalForce
                wheel.suspension.springForce = originalForce * self.physics.suspensionStiffness
            end
        end
    end
end

-- =====================
-- FS22 LIFECYCLE
-- =====================
function RandomWorldEvents:loadMap()
    ---@diagnostic disable-next-line: lowercase-global
    g_RandomWorldEvents = self
    g_RandomWorldEvents.modFolder = modFolder

    self:loadFromXML()

    if GameSettings ~= nil and GameSettings.saveToXMLFile ~= nil then
        self.originalSaveToXMLFile = GameSettings.saveToXMLFile
        GameSettings.saveToXMLFile = Utils.overwrittenFunction(
            GameSettings.saveToXMLFile, 
            RandomWorldEvents.saveToXML
        )
    end

    self:loadEventModules()
    
    self:loadGUI()
    
    self.delayedMessageTime = g_currentMission.time + 10000
    self.showDelayedMessage = true
    
    print("[RandomWorldEvents] Core system loaded")
    print("[RandomWorldEvents] Total events registered: " .. self:countEvents())
end

function RandomWorldEvents:loadEventModules()
    local eventModules = {
        "utils/economicEvents.lua",
        "utils/vehicleEvents.lua", 
        "utils/fieldEvents.lua",
        "utils/animalEvents.lua",
        "utils/specialEvents.lua",
        "utils/PhysicsUtils.lua"
    }
    
    for _, module in ipairs(eventModules) do
        local filePath = Utils.getFilename(module, modFolder)
        if fileExists(filePath) then
            source(filePath)
            print("[RandomWorldEvents] Loaded module: " .. module)
        else
            print("[RandomWorldEvents] Warning: Module not found: " .. module)
        end
    end
end

function RandomWorldEvents:countEvents()
    local count = 0
    for _ in pairs(self.EVENTS) do
        count = count + 1
    end
    return count
end

function RandomWorldEvents:loadGUI()
    local guiLuaFiles = {
        {path = "gui/RandomWorldEventsScreen.lua"},
        {path = "gui/RandomWorldEventsFrame.lua"},
        {path = "gui/RandomWorldDebugFrame.lua"}
    }
    
    for _, guiFile in ipairs(guiLuaFiles) do
        local filePath = Utils.getFilename(guiFile.path, modFolder)
        if fileExists(filePath) then
            source(filePath)
            print("[RandomWorldEvents] Loaded GUI Lua: " .. guiFile.path)
        else
            print("[RandomWorldEvents] Warning: GUI Lua file not found: " .. guiFile.path)
        end
    end
    
    local xmlFiles = {
        {path = "xml/RandomWorldEventsFrame.xml", ref = 'RandomWorldEventsFrame', frameClass = 'RandomWorldEventsFrame'},
        {path = "xml/RandomWorldDebugFrame.xml", ref = 'RandomWorldDebugFrame', frameClass = 'RandomEventsDebugFrame'},
        {path = "xml/RandomWorldEventsScreen.xml", ref = 'RandomWorldEventsScreen', frameClass = 'RandomWorldEventsScreen'}
    }
    
    for _, xmlFile in ipairs(xmlFiles) do
        local filePath = Utils.getFilename(xmlFile.path, modFolder)
        if fileExists(filePath) then
            if _G[xmlFile.frameClass] then
                if xmlFile.ref == 'RandomWorldEventsScreen' then
                    g_gui:loadGui(filePath, xmlFile.ref, _G[xmlFile.frameClass].new(nil, nil, g_messageCenter, g_i18n, g_inputBinding))
                else
                    g_gui:loadGui(filePath, xmlFile.ref, _G[xmlFile.frameClass].new(nil, nil), true)
                end
                print("[RandomWorldEvents] Loaded GUI XML: " .. xmlFile.path)
            else
                print("[RandomWorldEvents] Error: Frame class not found: " .. xmlFile.frameClass)
            end
        else
            print("[RandomWorldEvents] Warning: GUI XML file not found: " .. xmlFile.path)
        end
    end
end

-- =====================
-- XML SETTINGS
-- =====================
local function getXMLSettingBool(xmlFile, type, name, default)
    g_RandomWorldEvents:setTypeNameValue(type, name, Utils.getNoNil(getXMLBool(xmlFile, 'RandomEvents.' .. type .. '.' .. name), default))
end

local function setXMLSettingBool(xmlFile, type, name)
    local value = g_RandomWorldEvents:getTypeNameValue(type, name)
    setXMLBool(xmlFile, 'RandomEvents.' .. type .. '.' .. name, value)
end

local function getXMLSettingFloat(xmlFile, type, name, default)
    g_RandomWorldEvents:setTypeNameValue(type, name, Utils.getNoNil(getXMLFloat(xmlFile, 'RandomEvents.' .. type .. '.' .. name), default))
end

local function setXMLSettingFloat(xmlFile, type, name)
    local value = g_RandomWorldEvents:getTypeNameValue(type, name)
    setXMLFloat(xmlFile, 'RandomEvents.' .. type .. '.' .. name, value)
end

function RandomWorldEvents.saveToXML()
    local filePath = g_modSettingsDirectory .. 'RandomWorldEvents.xml'
    print('[RandomWorldEvents] Attempting to save to: ' .. filePath)
    
    local xmlFile = createXMLFile('advancedGameplaySetting', filePath, 'RandomEvents')

    if xmlFile == nil or xmlFile == 0 then
        print('RandomWorldEvents.saveToXML: Failed to create XML file')
        return
    end

    setXMLSettingBool(xmlFile, 'events', 'enabled')
    setXMLSettingFloat(xmlFile, 'events', 'frequency')
    setXMLSettingFloat(xmlFile, 'events', 'intensity')
    setXMLSettingBool(xmlFile, 'events', 'showNotifications')
    setXMLSettingBool(xmlFile, 'events', 'showWarnings')
    setXMLSettingFloat(xmlFile, 'events', 'cooldown')
    setXMLSettingBool(xmlFile, 'events', 'weatherEvents')
    setXMLSettingBool(xmlFile, 'events', 'economicEvents')
    setXMLSettingBool(xmlFile, 'events', 'vehicleEvents')
    setXMLSettingBool(xmlFile, 'events', 'fieldEvents')
    setXMLSettingBool(xmlFile, 'events', 'wildlifeEvents')
    setXMLSettingBool(xmlFile, 'events', 'specialEvents')
    setXMLSettingFloat(xmlFile, 'events', 'debugLevel')

    setXMLSettingBool(xmlFile, 'debug', 'enabled')
    setXMLSettingFloat(xmlFile, 'debug', 'debugLevel')
    setXMLSettingBool(xmlFile, 'debug', 'showDebugInfo')

    setXMLSettingBool(xmlFile, 'physics', 'enabled')
    setXMLSettingFloat(xmlFile, 'physics', 'wheelGripMultiplier')
    setXMLSettingFloat(xmlFile, 'physics', 'articulationDamping')
    setXMLSettingFloat(xmlFile, 'physics', 'comStrength')
    setXMLSettingFloat(xmlFile, 'physics', 'suspensionStiffness')
    setXMLSettingBool(xmlFile, 'physics', 'showPhysicsInfo')
    setXMLSettingBool(xmlFile, 'physics', 'debugMode')

    print('RandomWorldEvents: Saving XML configuration ..')
    saveXMLFile(xmlFile)
    delete(xmlFile)
    print('[RandomWorldEvents] Settings saved successfully')
end

function RandomWorldEvents:loadFromXML()
    local filePath = g_modSettingsDirectory .. 'RandomWorldEvents.xml'
    print('[RandomWorldEvents] Attempting to load from: ' .. filePath)

    if not fileExists(filePath) then
        print('[RandomWorldEvents] No settings file found, using defaults')
        return
    end

    local xmlFile = loadXMLFile('RandomWorldEvents', filePath)
    if xmlFile == nil or xmlFile == 0 then
        print('RandomWorldEvents.loadFromXML: Failed to load XML file')
        return
    end

    getXMLSettingBool(xmlFile, 'events', 'enabled', true)
    getXMLSettingFloat(xmlFile, 'events', 'frequency', 5)
    getXMLSettingFloat(xmlFile, 'events', 'intensity', 2)
    getXMLSettingBool(xmlFile, 'events', 'showNotifications', true)
    getXMLSettingBool(xmlFile, 'events', 'showWarnings', true)
    getXMLSettingFloat(xmlFile, 'events', 'cooldown', 30)
    getXMLSettingBool(xmlFile, 'events', 'weatherEvents', true)
    getXMLSettingBool(xmlFile, 'events', 'economicEvents', true)
    getXMLSettingBool(xmlFile, 'events', 'vehicleEvents', true)
    getXMLSettingBool(xmlFile, 'events', 'fieldEvents', true)
    getXMLSettingBool(xmlFile, 'events', 'wildlifeEvents', true)
    getXMLSettingBool(xmlFile, 'events', 'specialEvents', true)
    getXMLSettingFloat(xmlFile, 'events', 'debugLevel', 1)

    getXMLSettingBool(xmlFile, 'debug', 'enabled', false)
    getXMLSettingFloat(xmlFile, 'debug', 'debugLevel', 1)
    getXMLSettingBool(xmlFile, 'debug', 'showDebugInfo', false)

    getXMLSettingBool(xmlFile, 'physics', 'enabled', true)
    getXMLSettingFloat(xmlFile, 'physics', 'wheelGripMultiplier', 1.0)
    getXMLSettingFloat(xmlFile, 'physics', 'articulationDamping', 0.5)
    getXMLSettingFloat(xmlFile, 'physics', 'comStrength', 1.0)
    getXMLSettingFloat(xmlFile, 'physics', 'suspensionStiffness', 1.0)
    getXMLSettingBool(xmlFile, 'physics', 'showPhysicsInfo', false)
    getXMLSettingBool(xmlFile, 'physics', 'debugMode', false)

    delete(xmlFile)
    print('[RandomWorldEvents] Settings loaded successfully')
end

---@param type string
---@param name string
---@param value any
function RandomWorldEvents:setTypeNameValue(type, name, value)
    if self[type] then
        self[type][name] = value
    else
        print("Warning: Type '" .. type .. "' not found in RandomWorldEvents")
    end
end

function RandomWorldEvents:getTypeNameValue(type, name)
    if self[type] then
        return self[type][name]
    end
    return nil
end

function RandomWorldEvents:saveSettings()
    self.needsSave = true
    self.saveTime = g_currentMission.time + 1000
end

-- =====================
-- UPDATE FUNCTION
-- =====================
function RandomWorldEvents:update(dt)
    if self.showDelayedMessage and g_currentMission.time > self.delayedMessageTime then
        print("[FS22_RandomWorldEvents] >> =============================================================")
        print("[FS22_RandomWorldEvents] >>   Successfully loaded `Random World Events v1.2.0.0`")
        print("[FS22_RandomWorldEvents] >>   Total events: " .. self:countEvents())
        print("[FS22_RandomWorldEvents] >>   Original Author: TisonK")
        print("[FS22_RandomWorldEvents] >>   Controls: `F3` to open - `F9` for manual event trigger")
        print("[FS22_RandomWorldEvents] >>   Found a bug? Or got a suggestion? Please create an issue on GitHub!")
        print("[FS22_RandomWorldEvents] >>   https://github.com/TheCodingDad-TisonK/FS22_RandomWorldEvents")
        print("[FS22_RandomWorldEvents] >> =============================================================")

        g_currentMission:addIngameNotification(
            FSBaseMission.INGAME_NOTIFICATION_OK,
            "[Random World Events] Mod loaded successfully (" .. self:countEvents() .. " events)"
        )

        self.showDelayedMessage = false
    end

    if self.needsSave and self.saveTime and g_currentMission.time > self.saveTime then
        RandomWorldEvents.saveToXML()
        self.needsSave = false
        self.saveTime = nil
    end

    if self.events.enabled then
        if g_currentMission.time > (self.EVENT_STATE.cooldownUntil or 0) then
            local chance = self.events.frequency * 0.001
            if math.random() <= chance then
                self:triggerRandomEvent()
                local cooldownMs = self.events.cooldown * 60000
                local frequencyFactor = (11 - self.events.frequency) / 10
                self.EVENT_STATE.cooldownUntil =
                    g_currentMission.time + (cooldownMs * frequencyFactor)
            end
        end
    end

    if self.EVENT_STATE.activeEvent then
        self:applyActiveEventEffects()
    end

    -- Physics
    if self.physics.enabled then
        local vehicle = g_currentMission.controlledVehicle
        if vehicle then
            self:updatePhysics(vehicle)
        end
    end

    if self.EVENT_STATE.activeEvent and g_currentMission.time > (self.EVENT_STATE.eventStartTime + (self.EVENT_STATE.eventDuration or 0)) then
        local event = self.EVENTS[self.EVENT_STATE.activeEvent]
        if event and event.onEnd then
            local message = event.onEnd()
            if message and self.events.showNotifications then
                g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, message)
            end
        end
        self.EVENT_STATE.activeEvent = nil
    end
end

function RandomWorldEvents:applyActiveEventEffects()
    -- event files overrides this
end

function RandomWorldEvents:keyEvent(unicode, sym, modifier, isDown)
    if not isDown then
        return
    end

    if sym == 284 then -- F3
        g_gui:showGui('RandomWorldEventsScreen')
    elseif sym == 289 then -- F8
        DebugUtil.printTableRecursively(g_RandomWorldEvents)
    elseif sym == 290 then -- F9
        self:triggerRandomEvent()
    end
end

addModEventListener(RandomWorldEvents)
