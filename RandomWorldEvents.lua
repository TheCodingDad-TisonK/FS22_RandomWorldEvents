-- =========================================================
-- Random World Events (version 1.3.0.0)
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
RandomWorldEvents.eventCounter = 0  

function RandomWorldEvents:getFarmId()
    return g_currentMission and g_currentMission.player and g_currentMission.player.farmId or 0
end

function RandomWorldEvents:getVehicle()
    return g_currentMission and g_currentMission.controlledVehicle or nil
end

function RandomWorldEvents:randomDuration(minMinutes, maxMinutes)
    return (math.random(minMinutes, maxMinutes) * 60000)
end

function RandomWorldEvents:registerEvent(eventData)
    self.eventCounter = self.eventCounter + 1
    self.EVENTS[eventData.name] = eventData
    return eventData.name
end

function RandomWorldEvents:triggerRandomEvent()
    if not self.events.enabled then 
        print("[RWE-DEBUG] Events disabled")
        return false 
    end
    
    if self.EVENT_STATE.activeEvent ~= nil then 
        print("[RWE-DEBUG] Event already active: " .. tostring(self.EVENT_STATE.activeEvent))
        return false 
    end
    
    local available = {}
    for eventId, event in pairs(self.EVENTS) do
        local categoryKey = event.category .. "Events"
        local categoryEnabled = self.events[categoryKey]
        local canTrigger = event.canTrigger()
        local intensityOk = self.events.intensity >= (event.minIntensity or 1)
        
        print(string.format("[RWE-DEBUG] Checking %s: category=%s, key=%s, enabled=%s, canTrigger=%s, intensity=%d/%d", 
            eventId, event.category, categoryKey, tostring(categoryEnabled), tostring(canTrigger), 
            self.events.intensity, event.minIntensity or 1))
        
        if categoryEnabled and canTrigger and intensityOk then
            table.insert(available, eventId)
            print("[RWE-DEBUG]   ✓ Added to available")
        else
            print("[RWE-DEBUG]   ✗ Skipped")
        end
    end
    
    print("[RWE-DEBUG] Available events: " .. #available)
    
    if #available == 0 then 
        print("[RWE-DEBUG] No events available to trigger")
        return false 
    end
    
    local eventId = available[math.random(1, #available)]
    local event = self.EVENTS[eventId]
    
    print("[RWE-DEBUG] Selected event: " .. eventId)
    
    self.EVENT_STATE.activeEvent = eventId
    self.EVENT_STATE.eventStartTime = g_currentMission.time
    
    local duration = 0
    if type(event.duration) == "table" then
        duration = math.random(event.duration.min, event.duration.max) * 60000
    end
    self.EVENT_STATE.eventDuration = duration
    
    print("[RWE-DEBUG] Event duration: " .. (duration / 60000) .. " minutes")
    
    local message = event.onStart(self.events.intensity)
    if message and self.events.showNotifications then
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, message)
    end
    
    print("[RWE-DEBUG] Event triggered successfully: " .. eventId)
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
    self:loadEventModules()
    self:loadGUI()

    if g_currentMission then
        addConsoleCommand(
            "rwe",                        
            "Random World Events Command", 
            "onConsoleCommand",            
            RandomWorldEvents              
        )
        print("[RandomWorldEvents] Console command 'rwe' registered")
    end

    if GameSettings ~= nil and GameSettings.saveToXMLFile ~= nil then
        self.originalSaveToXMLFile = GameSettings.saveToXMLFile
        GameSettings.saveToXMLFile = Utils.overwrittenFunction(
            GameSettings.saveToXMLFile, 
            RandomWorldEvents.saveToXML
        )
    end

    self.delayedMessageTime = g_currentMission.time + 10000
    self.showDelayedMessage = true

    print("[RandomWorldEvents] Core system loaded")

    local totalEvents = self:countEvents()
    local eventBreakdown = self:countEventsByCategory()

    print("[RandomWorldEvents] Total events registered: " .. totalEvents)
    for category, count in pairs(eventBreakdown) do
        print(string.format("[RandomWorldEvents] %s events: %d", category:gsub("^%l", string.upper), count))
    end

    if PhysicsUtils then
        print("[RandomWorldEvents] PhysicsUtils module loaded successfully")
    else
        print("[RandomWorldEvents] WARNING: PhysicsUtils module not loaded")
    end
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

function RandomWorldEvents:countEventsByCategory()
    local counts = {}
    for _, event in pairs(self.EVENTS) do
        local category = event.category or "unknown"
        counts[category] = (counts[category] or 0) + 1
    end
    return counts
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
        local totalEvents = self:countEvents()
        local breakdown = self:countEventsByCategory()
        
        print("[FS22_RandomWorldEvents] >> =============================================================")
        print("[FS22_RandomWorldEvents] >>   Successfully loaded `Random World Events v1.3.0.0`")
        print("[FS22_RandomWorldEvents] >>   Total events: " .. totalEvents)
        print("[FS22_RandomWorldEvents] >>   Original Author: TisonK")
        print("[FS22_RandomWorldEvents] >>   Controls: `F3` to open - `F9` for manual event trigger")
        print("[FS22_RandomWorldEvents] >>   Found a bug? Or got a suggestion? Please create an issue on GitHub!")
        print("[FS22_RandomWorldEvents] >>   https://github.com/TheCodingDad-TisonK/FS22_RandomWorldEvents")
        print("[FS22_RandomWorldEvents] >> =============================================================")
        print("[FS22_RandomWorldEvents] >>   Total events per category:")

        for category, count in pairs(breakdown) do
            print(string.format("[FS22_RandomWorldEvents] >>   %s: %d", category:gsub("^%l", string.upper), count))
        end
        print("[FS22_RandomWorldEvents] >> =============================================================")

        g_currentMission:addIngameNotification(
            FSBaseMission.INGAME_NOTIFICATION_OK,
            "[Random World Events] Mod loaded successfully (" .. totalEvents .. " events)"
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
                print("[RWE-DEBUG] Random chance triggered! Frequency=" .. self.events.frequency .. ", chance=" .. chance)
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

    if self.physics.enabled then
        local vehicle = g_currentMission.controlledVehicle
        if vehicle then
            if PhysicsUtils and PhysicsUtils.applyAdvancedPhysics then
                PhysicsUtils:applyAdvancedPhysics(vehicle)
            else
                self:updatePhysics(vehicle)
            end
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
        print("[RWE-DEBUG] Event ended: " .. tostring(self.EVENT_STATE.activeEvent))
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
        print("[RWE-DEBUG] Manual event trigger (F9) pressed")
        self:triggerRandomEvent()
    end
end

-- =====================
-- CONSOLE COMMANDS
-- =====================

---@usage rwe_test [event_name]
---@param self RandomWorldEvents
function RandomWorldEvents:consoleTestEvent(eventName)
    if not self.events.enabled then
        print("[RWE-Console] Events are disabled. Enable them in settings first.")
        return
    end
    
    if self.EVENT_STATE.activeEvent then
        print("[RWE-Console] An event is already active. Use 'rwe_end' to end it first.")
        return
    end
    
    if not eventName or eventName == "" then
        print("[RWE-Console] Triggering random event...")
        local success = self:triggerRandomEvent()
        if success then
            print("[RWE-Console] Random event triggered successfully")
        else
            print("[RWE-Console] Failed to trigger random event")
        end
        return
    end
    
    local event = self.EVENTS[eventName]
    if not event then
        print(string.format("[RWE-Console] Event '%s' not found", eventName))
        
        print("[RWE-Console] Available events:")
        for name, e in pairs(self.EVENTS) do
            local categoryEnabled = self.events[e.category .. "Events"]
            local canTrigger = e.canTrigger()
            local intensityOk = self.events.intensity >= e.minIntensity
            
            if categoryEnabled and canTrigger and intensityOk then
                print(string.format("  %s (%s)", name, e.category))
            end
        end
        return
    end
    
    local categoryEnabled = self.events[event.category .. "Events"]
    if not categoryEnabled then
        print(string.format("[RWE-Console] Event category '%s' is disabled", event.category))
        return
    end
    
    if not event.canTrigger() then
        print("[RWE-Console] Event cannot trigger at this time")
        return
    end
    
    if self.events.intensity < event.minIntensity then
        print(string.format("[RWE-Console] Event requires intensity %d (current: %d)", 
            event.minIntensity, self.events.intensity))
        return
    end
    
    print(string.format("[RWE-Console] Triggering event: %s", eventName))
    
    self.EVENT_STATE.activeEvent = eventName
    self.EVENT_STATE.eventStartTime = g_currentMission.time
    
    local duration = 0
    if type(event.duration) == "table" then
        duration = math.random(event.duration.min, event.duration.max) * 60000
    end
    self.EVENT_STATE.eventDuration = duration
    
    local message = event.onStart(self.events.intensity)
    if message then
        print("[RWE-Console] " .. message)
        
        if self.events.showNotifications then
            g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, message)
        end
    end
    
    local cooldownMs = self.events.cooldown * 60000
    local frequencyFactor = (11 - self.events.frequency) / 10
    self.EVENT_STATE.cooldownUntil =
        g_currentMission.time + (cooldownMs * frequencyFactor)
    
    print("[RWE-Console] Event triggered successfully")
end

---@param self RandomWorldEvents
function RandomWorldEvents:consoleShowStatus()
    print("=========================================")
    print("Random World Events - Status")
    print("=========================================")
    print("Events enabled: " .. tostring(self.events.enabled))
    print("Frequency: " .. self.events.frequency)
    print("Intensity: " .. self.events.intensity)
    print("Active event: " .. (self.EVENT_STATE.activeEvent or "None"))
    
    if self.EVENT_STATE.activeEvent then
        local elapsed = (g_currentMission.time - self.EVENT_STATE.eventStartTime) / 60000
        local remaining = (self.EVENT_STATE.eventDuration / 60000) - elapsed
        print(string.format("Event progress: %.1f / %.1f minutes", elapsed, self.EVENT_STATE.eventDuration / 60000))
        print(string.format("Time remaining: %.1f minutes", remaining))
    end
    
    print("Cooldown active: " .. tostring(g_currentMission.time < self.EVENT_STATE.cooldownUntil))
    
    if g_currentMission.time < self.EVENT_STATE.cooldownUntil then
        local remaining = (self.EVENT_STATE.cooldownUntil - g_currentMission.time) / 60000
        print(string.format("Cooldown remaining: %.1f minutes", remaining))
    end
    
    print("=========================================")
end

---@param self RandomWorldEvents
function RandomWorldEvents:consoleEndEvent()
    if not self.EVENT_STATE.activeEvent then
        print("[RWE-Console] No active event to end")
        return
    end
    
    local event = self.EVENTS[self.EVENT_STATE.activeEvent]
    print(string.format("[RWE-Console] Ending event: %s", self.EVENT_STATE.activeEvent))
    
    if event and event.onEnd then
        local message = event.onEnd()
        if message then
            print("[RWE-Console] " .. message)
            
            if self.events.showNotifications then
                g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, message)
            end
        end
    end
    
    self.EVENT_STATE.activeEvent = nil
    print("[RWE-Console] Event ended")
end


---@usage rwe_debug [on|off]
---@param self RandomWorldEvents
function RandomWorldEvents:consoleToggleDebug(mode)
    if mode == "on" or mode == "true" or mode == "1" then
        self.debug.enabled = true
        self.debug.showDebugInfo = true
        print("[RWE-Console] Debug mode ENABLED")
    elseif mode == "off" or mode == "false" or mode == "0" then
        self.debug.enabled = false
        self.debug.showDebugInfo = false
        print("[RWE-Console] Debug mode DISABLED")
    else
        self.debug.enabled = not self.debug.enabled
        self.debug.showDebugInfo = self.debug.enabled
        
        local status = self.debug.enabled and "ENABLED" or "DISABLED"
        print("[RWE-Console] Debug mode: " .. status)
    end
end

---@usage rwe_list [category]
---@param self RandomWorldEvents
function RandomWorldEvents:consoleListEvents(categoryFilter)
    print("=========================================")
    print("Random World Events - Available Events")
    print("=========================================")
    
    local categories = {}
    local totalAvailable = 0
    
    for name, event in pairs(self.EVENTS) do
        local cat = event.category or "unknown"
        categories[cat] = categories[cat] or {enabled = 0, disabled = 0}
        
        local categoryEnabled = self.events[cat .. "Events"]
        local canTrigger = event.canTrigger()
        local intensityOk = self.events.intensity >= event.minIntensity
        
        if categoryFilter and cat ~= categoryFilter then
        else
            if categoryEnabled and canTrigger and intensityOk then
                categories[cat].enabled = categories[cat].enabled + 1
                totalAvailable = totalAvailable + 1
            else
                categories[cat].disabled = categories[cat].disabled + 1
            end
        end
    end
    
    for cat, counts in pairs(categories) do
        if counts.enabled + counts.disabled > 0 then
            local catEnabled = self.events[cat .. "Events"]
            print(string.format("%s (%s):", cat:gsub("^%l", string.upper), catEnabled and "ENABLED" or "DISABLED"))
            print(string.format("  Available: %d, Unavailable: %d", counts.enabled, counts.disabled))
            
            if categoryFilter and cat == categoryFilter then
                for name, event in pairs(self.EVENTS) do
                    if event.category == cat then
                        local categoryEnabled = self.events[cat .. "Events"]
                        local canTrigger = event.canTrigger()
                        local intensityOk = self.events.intensity >= event.minIntensity
                        
                        local status = "✓"
                        local reason = ""
                        
                        if not categoryEnabled then
                            status = "✗"
                            reason = "category disabled"
                        elseif not canTrigger then
                            status = "✗"
                            reason = "cannot trigger"
                        elseif not intensityOk then
                            status = "✗"
                            reason = string.format("needs intensity %d", event.minIntensity)
                        end
                        
                        print(string.format("    %s %s - %s", status, name, reason))
                    end
                end
            end
        end
    end
    
    print(string.format("Total available events: %d", totalAvailable))
    print("=========================================")
end

-- =====================
-- CONSOLE COMMANDS
-- =====================
function RandomWorldEvents:onConsoleCommand(...)
    local args = {...}
    if #args == 0 then
        print("Random World Events Commands:")
        print("  rwe status     - Show mod status")
        print("  rwe test [name]- Trigger test event (optional: event name)")
        print("  rwe end        - End current active event")
        print("  rwe debug [on|off] - Toggle debug mode")
        print("  rwe list [category] - List available events")
        return true
    end
    
    local command = args[1]:lower()
    
    if command == "status" then
        self:consoleShowStatus()
    elseif command == "test" then
        local eventName = args[2] or ""
        self:consoleTestEvent(eventName)
    elseif command == "end" then
        self:consoleEndEvent()
    elseif command == "debug" then
        local mode = args[2] or ""
        self:consoleToggleDebug(mode)
    elseif command == "list" then
        local category = args[2] or ""
        self:consoleListEvents(category)
    else
        print(string.format("[RWE-Console] Unknown command: %s", command))
        print("Use 'rwe' without arguments to see available commands.")
    end
    
    return true
end

addModEventListener(RandomWorldEvents)
