-- =========================================================
-- FS22 Random World Events (version 1.0.5.0)
-- =========================================================
-- Adds dynamic random events to FS22
-- =========================================================
-- Author: TisonK
-- =========================================================
-- COPYRIGHT NOTICE:
-- All rights reserved. Unauthorized redistribution, copying,
-- or claiming this code as your own is strictly prohibited.
-- Original author: TisonK
-- =========================================================

RandomWorldEvents = {}
RandomWorldEvents.modName = "FS22_RandomWorldEvents"
RandomWorldEvents.settings = {}
RandomWorldEvents.hasRegisteredSettings = false
RandomWorldEvents.version = "1.0.5.0"

-- =====================
-- DEFAULT CONFIGURATION
-- =====================
RandomWorldEvents.DEFAULT_CONFIG = {
    enabled = true,
    frequency = 5,         
    intensity = 2,          
    showNotifications = true,
    showWarnings = true,
    debugLevel = 1,
    cooldown = 30,           
    lastEventTime = 0,
    
    weatherEvents = true,
    economicEvents = true,
    vehicleEvents = true,
    fieldEvents = true,
    wildlifeEvents = true,
    specialEvents = true,
    
    enabledEvents = {}  
}

RandomWorldEvents.NOTIFICATION_TYPE_BY_CATEGORY = {
    economic = FSBaseMission.INGAME_NOTIFICATION_INFO,
    vehicle  = FSBaseMission.INGAME_NOTIFICATION_WARNING,
    field    = FSBaseMission.INGAME_NOTIFICATION_INFO,
    weather  = FSBaseMission.INGAME_NOTIFICATION_WARNING,
    wildlife = FSBaseMission.INGAME_NOTIFICATION_INFO,
    special  = FSBaseMission.INGAME_NOTIFICATION_CRITICAL
}

-- =====================
-- EVENT DEFINITIONS
-- =====================
RandomWorldEvents.EVENTS = {
    government_subsidy = {
        name = "event_government_subsidy",
        category = "economic",
        weight = 1.0,
        duration = 0,
        minIntensity = 1,
        canTrigger = function() return g_currentMission ~= nil end,
        onStart = function(intensity)
            local amount = 5000 + (intensity * 2500)
            local farmId = g_currentMission.player.farmId
            g_currentMission:addMoney(amount, farmId, MoneyType.OTHER, true)
            return string.format("Government subsidy! +€%s", g_i18n:formatMoney(amount, 0, true, true))
        end,
        onEnd = function() return "" end
    },
    
    tax_bill = {
        name = "event_tax_bill",
        category = "economic",
        weight = 0.8,
        duration = 0,
        minIntensity = 1,
        canTrigger = function() return g_currentMission ~= nil end,
        onStart = function(intensity)
            local amount = 3000 + (intensity * 1500)
            local farmId = g_currentMission.player.farmId
            g_currentMission:addMoney(-amount, farmId, MoneyType.OTHER, true)
            return string.format("Unexpected tax bill! -€%s", g_i18n:formatMoney(amount, 0, true, true))
        end,
        onEnd = function() return "" end
    },

    market_boom = {
        name = "event_market_boom",
        category = "economic",
        weight = 0.6,
        duration = {min = 120, max = 360},
        minIntensity = 1,
        canTrigger = function() return true end,
        onStart = function(intensity)
            RandomWorldEvents.EVENT_STATE.marketBonus = 0.15 + (intensity * 0.05)
            return string.format(
                "MARKET BOOM! Sell prices +%.1f%%",
                RandomWorldEvents.EVENT_STATE.marketBonus * 100
            )
        end,
        onEnd = function()
            RandomWorldEvents.EVENT_STATE.marketBonus = nil
            return "Market prices stabilized."
        end
    },

    loan_interest_relief = {
        name = "event_loan_interest_relief",
        category = "economic",
        weight = 0.3,
        duration = 0,
        minIntensity = 1,
        canTrigger = function()
            return g_currentMission.player ~= nil
                and g_currentMission.player.farmId ~= nil
        end,
        onStart = function(intensity)
            local amount = 2000 + (intensity * 1500)
            local farmId = g_currentMission.player.farmId
            g_currentMission:addMoney(amount, farmId, MoneyType.LOAN, true)
            return string.format(
                "Loan interest refund! +€%s",
                g_i18n:formatMoney(amount, 0, true, true)
            )
        end,
        onEnd = function() return "" end
    },

    
    vehicle_repair_bill = {
        name = "event_vehicle_repair_bill",
        category = "vehicle",
        weight = 0.9,
        duration = 0,
        minIntensity = 1,
        canTrigger = function() 
            return g_currentMission.controlledVehicle ~= nil 
        end,
        onStart = function(intensity)
            local amount = 1000 + (intensity * 500)
            local farmId = g_currentMission.player.farmId
            g_currentMission:addMoney(-amount, farmId, MoneyType.VEHICLE_REPAIR, true)
            return string.format("Vehicle repair needed! -€%s", g_i18n:formatMoney(amount, 0, true, true))
        end,
        onEnd = function() return "" end
    },

    machinery_wear = {
        name = "event_machinery_wear",
        category = "vehicle",
        weight = 0.6,
        duration = 0,
        minIntensity = 1,
        canTrigger = function()
            return g_currentMission.controlledVehicle ~= nil
        end,
        onStart = function(intensity)
            local vehicle = g_currentMission.controlledVehicle
            if vehicle.addWearAmount ~= nil then
                vehicle:addWearAmount(0.05 * intensity, true)
                return "Machinery wear increased due to heavy use."
            end
            return "Machinery inspection required."
        end,
        onEnd = function() return "" end
    },

    free_vehicle_service = {
        name = "event_free_vehicle_service",
        category = "vehicle",
        weight = 0.4,
        duration = 0,
        minIntensity = 1,
        canTrigger = function()
            return g_currentMission.controlledVehicle ~= nil
        end,
        onStart = function(intensity)
            local vehicle = g_currentMission.controlledVehicle
            if vehicle.setDamageAmount ~= nil then
                vehicle:setDamageAmount(0)
                return "Free vehicle service! Damage fully repaired."
            end
            return "Service team passed through."
        end,
        onEnd = function() return "" end
    },
    
    time_acceleration = {
        name = "event_time_acceleration",
        category = "special",
        weight = 0.7,
        duration = {min = 10, max = 30}, -- minutes
        minIntensity = 1,
        canTrigger = function() return g_currentMission.environment ~= nil end,
        onStart = function(intensity)
            local originalSpeed = g_currentMission.missionInfo.timeScale
            RandomWorldEvents.EVENT_STATE.originalTimeScale = originalSpeed
            local multiplier = 5 * intensity
            g_currentMission.missionInfo.timeScale = originalSpeed * multiplier
            RandomWorldEvents:log("Time accelerated from " .. originalSpeed .. " to " .. g_currentMission.missionInfo.timeScale)
            return string.format("TIME ACCELERATION! Time speed x%d", multiplier)
        end,
        onEnd = function()
            if RandomWorldEvents.EVENT_STATE.originalTimeScale then
                g_currentMission.missionInfo.timeScale = RandomWorldEvents.EVENT_STATE.originalTimeScale
            end
            RandomWorldEvents.EVENT_STATE.originalTimeScale = nil
            return "Time returned to normal."
        end
    },
    
    time_slowdown = {
        name = "event_time_slowdown",
        category = "special",
        weight = 0.5,
        duration = {min = 5, max = 15},
        minIntensity = 1,
        canTrigger = function() return g_currentMission.environment ~= nil end,
        onStart = function(intensity)
            local originalSpeed = g_currentMission.missionInfo.timeScale
            RandomWorldEvents.EVENT_STATE.originalTimeScale = originalSpeed
            g_currentMission.missionInfo.timeScale = originalSpeed / (2 * intensity)
            return "TIME SLOWDOWN! Everything moving slower."
        end,
        onEnd = function()
            if RandomWorldEvents.EVENT_STATE.originalTimeScale then
                g_currentMission.missionInfo.timeScale = RandomWorldEvents.EVENT_STATE.originalTimeScale
            end
            RandomWorldEvents.EVENT_STATE.originalTimeScale = nil
            return "Time returned to normal."
        end
    },
    
    request_weather_change = {
        name = "event_request_weather_change",
        category = "weather",
        weight = 0.8,
        duration = 0,
        minIntensity = 1,
        canTrigger = function() return g_currentMission.environment ~= nil end,
        onStart = function(intensity)
            -- This tries to force a weather change
            if g_currentMission.environment.weather then
                -- Try to trigger rain if possible
                RandomWorldEvents:log("Attempting weather change...")
                return "Weather system anomaly detected!"
            end
            return "Strange weather patterns forming..."
        end,
        onEnd = function() return "" end
    },
    
    field_work_bonus = {
        name = "event_field_work_bonus",
        category = "field",
        weight = 0.6,
        duration = {min = 60, max = 180},
        minIntensity = 1,
        canTrigger = function() return true end,
        onStart = function(intensity)
            RandomWorldEvents.EVENT_STATE.fieldBonus = 0.2 + (intensity * 0.05)
            RandomWorldEvents:log("Field bonus active: " .. (RandomWorldEvents.EVENT_STATE.fieldBonus * 100) .. "%")
            return string.format("FIELD WORK BONUS! +%.1f%% income from fieldwork", RandomWorldEvents.EVENT_STATE.fieldBonus * 100)
        end,
        onEnd = function()
            RandomWorldEvents.EVENT_STATE.fieldBonus = nil
            return "Field bonus ended."
        end
    },

    fertilizer_efficiency = {
        name = "event_fertilizer_efficiency",
        category = "field",
        weight = 0.5,
        duration = {min = 90, max = 240},
        minIntensity = 1,
        canTrigger = function() return true end,
        onStart = function(intensity)
            RandomWorldEvents.EVENT_STATE.fertilizerBonus = 0.2 + (intensity * 0.05)
            return string.format(
                "FERTILIZER EFFICIENCY! Usage -%.1f%%",
                RandomWorldEvents.EVENT_STATE.fertilizerBonus * 100
            )
        end,
        onEnd = function()
            RandomWorldEvents.EVENT_STATE.fertilizerBonus = nil
            return "Fertilizer efficiency normalized."
        end
    },
    
    harvest_quality = {
        name = "event_harvest_quality",
        category = "field",
        weight = 0.4,
        duration = {min = 120, max = 300},
        minIntensity = 1,
        canTrigger = function() return true end,
        onStart = function(intensity)
            RandomWorldEvents.EVENT_STATE.harvestBonus = 0.1 + (intensity * 0.05)
            return string.format(
                "HIGH HARVEST QUALITY! Yield +%.1f%%",
                RandomWorldEvents.EVENT_STATE.harvestBonus * 100
            )
        end,
        onEnd = function()
            RandomWorldEvents.EVENT_STATE.harvestBonus = nil
            return "Harvest quality returned to normal."
        end
    },

    worker_efficiency = {
        name = "event_worker_efficiency",
        category = "special",
        weight = 0.7,
        duration = {min = 30, max = 120},
        minIntensity = 1,
        canTrigger = function() return true end,
        onStart = function(intensity)
            -- Reduce worker costs
            RandomWorldEvents.EVENT_STATE.workerDiscount = 0.3 + (intensity * 0.1)
            return string.format("WORKER EFFICIENCY! Worker costs -%.1f%%", RandomWorldEvents.EVENT_STATE.workerDiscount * 100)
        end,
        onEnd = function()
            RandomWorldEvents.EVENT_STATE.workerDiscount = nil
            return "Worker efficiency period ended."
        end
    },
    
    animal_productivity = {
        name = "event_animal_productivity",
        category = "special",
        weight = 0.5,
        duration = {min = 120, max = 480},
        minIntensity = 2,
        canTrigger = function() return g_currentMission ~= nil end,
        onStart = function(intensity)
            -- Increase animal production
            RandomWorldEvents.EVENT_STATE.animalBonus = 0.25 + (intensity * 0.05)
            return string.format("ANIMAL PRODUCTIVITY! +%.1f%% production", RandomWorldEvents.EVENT_STATE.animalBonus * 100)
        end,
        onEnd = function()
            RandomWorldEvents.EVENT_STATE.animalBonus = nil
            return "Animal productivity returned to normal."
        end
    },

    feed_cost_reduction = {
        name = "event_feed_cost_reduction",
        category = "animal",
        weight = 0.4,
        duration = {min = 120, max = 360},
        minIntensity = 1,
        canTrigger = function() return true end,
        onStart = function(intensity)
            RandomWorldEvents.EVENT_STATE.feedDiscount = 0.25 + (intensity * 0.05)
            return string.format(
                "FEED SUPPLY DEAL! Feed costs -%.1f%%",
                RandomWorldEvents.EVENT_STATE.feedDiscount * 100
            )
        end,
        onEnd = function()
            RandomWorldEvents.EVENT_STATE.feedDiscount = nil
            return "Feed prices returned to normal."
        end
    },
    
    fuel_surplus = {
        name = "event_fuel_surplus",
        category = "economic",
        weight = 0.4,
        duration = {min = 60, max = 240},
        minIntensity = 1,
        canTrigger = function() return true end,
        onStart = function(intensity)
            -- Reduce fuel consumption
            RandomWorldEvents.EVENT_STATE.fuelBonus = 0.4 + (intensity * 0.1)
            return string.format("FUEL SURPLUS! Consumption -%.1f%%", RandomWorldEvents.EVENT_STATE.fuelBonus * 100)
        end,
        onEnd = function()
            RandomWorldEvents.EVENT_STATE.fuelBonus = nil
            return "Fuel surplus ended."
        end
    },

    extended_workday = {
        name = "event_extended_workday",
        category = "special",
        weight = 0.3,
        duration = {min = 30, max = 90},
        minIntensity = 1,
        canTrigger = function()
            return g_currentMission.environment ~= nil
        end,
        onStart = function(intensity)
            RandomWorldEvents.EVENT_STATE.noSleep = true
            return "EXTENDED WORKDAY! Fatigue reduced temporarily."
        end,
        onEnd = function()
            RandomWorldEvents.EVENT_STATE.noSleep = nil
            return "Workday length normalized."
        end
    }

}
-- =====================
-- INTERNAL STATE
-- =====================
RandomWorldEvents.EVENT_STATE = {
    activeEvent = nil,
    eventStartTime = 0,
    eventDuration = 0,
    eventData = {},
    history = {},
    cooldownUntil = 0
}

RandomWorldEvents.isLoaded = false
RandomWorldEvents.welcomeTimer = nil
RandomWorldEvents.settingsRetryTimer = nil
RandomWorldEvents.updateInterval = 0

-- =====================
-- UTILITY FUNCTIONS
-- =====================
function RandomWorldEvents:log(msg, level)
    level = level or 1
    if self.settings.debugLevel >= level then
        print("["..self.modName.."] "..tostring(msg))
    end
end

function RandomWorldEvents:printBanner()
    self:log("===================================")
    self:log("Random World Events")
    self:log("Version: "..self.version)
    self:log("Enabled: "..tostring(self.settings.enabled))
    self:log("Frequency: "..self.settings.frequency)
    self:log("Intensity: "..self.settings.intensity)
    self:log("Cooldown: "..self.settings.cooldown.." minutes")
    self:log("===================================")
end

function RandomWorldEvents:isServer()
    return g_currentMission ~= nil and g_currentMission:getIsServer()
end

function RandomWorldEvents:copyTable(t)
    local r = {}
    for k,v in pairs(t) do r[k] = v end
    return r
end

function RandomWorldEvents:i18n(key, fallback)
    if g_i18n and g_i18n:hasText(key) then 
        return g_i18n:getText(key) 
    end
    return fallback or key
end

function RandomWorldEvents:showNotification(message, category)
    if not self.settings.showNotifications then return end
    if g_currentMission == nil then return end

    if message == nil or message == "" then
        message = "Unknown event."
    end

    local notifType = FSBaseMission.INGAME_NOTIFICATION_OK

    if category and self.NOTIFICATION_TYPE_BY_CATEGORY[category] ~= nil then
        notifType = self.NOTIFICATION_TYPE_BY_CATEGORY[category]
    end

    g_currentMission:addIngameNotification(notifType, message)
end



function RandomWorldEvents:showAlert(message)
    if not self.settings.showWarnings then return end
    self:showNotification(message, true)
end

-- =====================
-- SETTINGS SYSTEM
-- =====================
function RandomWorldEvents:getSettingsFilePath()
    local baseDir = getUserProfileAppPath().."modSettings"
    local modDir = baseDir.."/FS22_RandomWorldEvents"
    createFolder(baseDir)
    createFolder(modDir)
    return modDir.."/settings.xml"
end

function RandomWorldEvents:loadSettingsFromXML()
    local filePath = self:getSettingsFilePath()
    local xmlFile = loadXMLFile("settings", filePath)
    
    if xmlFile ~= 0 then
        self.settings.enabled = Utils.getNoNil(getXMLBool(xmlFile, "FS22_RandomWorldEvents.enabled"), self.DEFAULT_CONFIG.enabled)
        self.settings.frequency = Utils.getNoNil(getXMLInt(xmlFile, "FS22_RandomWorldEvents.frequency"), self.DEFAULT_CONFIG.frequency)
        self.settings.intensity = Utils.getNoNil(getXMLInt(xmlFile, "FS22_RandomWorldEvents.intensity"), self.DEFAULT_CONFIG.intensity)
        self.settings.showNotifications = Utils.getNoNil(getXMLBool(xmlFile, "FS22_RandomWorldEvents.showNotifications"), self.DEFAULT_CONFIG.showNotifications)
        self.settings.showWarnings = Utils.getNoNil(getXMLBool(xmlFile, "FS22_RandomWorldEvents.showWarnings"), self.DEFAULT_CONFIG.showWarnings)
        self.settings.debugLevel = Utils.getNoNil(getXMLInt(xmlFile, "FS22_RandomWorldEvents.debugLevel"), self.DEFAULT_CONFIG.debugLevel)
        self.settings.cooldown = Utils.getNoNil(getXMLInt(xmlFile, "FS22_RandomWorldEvents.cooldown"), self.DEFAULT_CONFIG.cooldown)
        self.EVENT_STATE.cooldownUntil = Utils.getNoNil(getXMLFloat(xmlFile, "FS22_RandomWorldEvents.cooldownUntil"), 0)
        
        self.settings.weatherEvents = Utils.getNoNil(getXMLBool(xmlFile, "FS22_RandomWorldEvents.weatherEvents"), self.DEFAULT_CONFIG.weatherEvents)
        self.settings.economicEvents = Utils.getNoNil(getXMLBool(xmlFile, "FS22_RandomWorldEvents.economicEvents"), self.DEFAULT_CONFIG.economicEvents)
        self.settings.vehicleEvents = Utils.getNoNil(getXMLBool(xmlFile, "FS22_RandomWorldEvents.vehicleEvents"), self.DEFAULT_CONFIG.vehicleEvents)
        self.settings.fieldEvents = Utils.getNoNil(getXMLBool(xmlFile, "FS22_RandomWorldEvents.fieldEvents"), self.DEFAULT_CONFIG.fieldEvents)
        self.settings.wildlifeEvents = Utils.getNoNil(getXMLBool(xmlFile, "FS22_RandomWorldEvents.wildlifeEvents"), self.DEFAULT_CONFIG.wildlifeEvents)
        self.settings.specialEvents = Utils.getNoNil(getXMLBool(xmlFile, "FS22_RandomWorldEvents.specialEvents"), self.DEFAULT_CONFIG.specialEvents)
        
        self.settings.enabledEvents = {}
        for eventId, _ in pairs(self.EVENTS) do
            local key = "FS22_RandomWorldEvents.eventEnabled." .. eventId
            local isEnabled = getXMLBool(xmlFile, key)
            self.settings.enabledEvents[eventId] = Utils.getNoNil(isEnabled, true)
        end
        
        delete(xmlFile)
        self:log("Settings loaded from XML: "..filePath, 2)
    else
        self.settings = self:copyTable(self.DEFAULT_CONFIG)
        
        self.settings.enabledEvents = {}
        for eventId, _ in pairs(self.EVENTS) do
            self.settings.enabledEvents[eventId] = true
        end
        
        self:log("Using default settings", 1)
        self:saveSettingsToXML()
    end
end

function RandomWorldEvents:saveSettingsToXML()
    local filePath = self:getSettingsFilePath()
    local xmlFile = createXMLFile("settings", filePath, "FS22_RandomWorldEvents")
    
    if xmlFile ~= 0 then
        setXMLBool(xmlFile, "FS22_RandomWorldEvents.enabled", self.settings.enabled)
        setXMLInt(xmlFile, "FS22_RandomWorldEvents.frequency", self.settings.frequency)
        setXMLInt(xmlFile, "FS22_RandomWorldEvents.intensity", self.settings.intensity)
        setXMLBool(xmlFile, "FS22_RandomWorldEvents.showNotifications", self.settings.showNotifications)
        setXMLBool(xmlFile, "FS22_RandomWorldEvents.showWarnings", self.settings.showWarnings)
        setXMLInt(xmlFile, "FS22_RandomWorldEvents.debugLevel", self.settings.debugLevel)
        setXMLInt(xmlFile, "FS22_RandomWorldEvents.cooldown", self.settings.cooldown)
        setXMLFloat(xmlFile, "FS22_RandomWorldEvents.cooldownUntil", self.EVENT_STATE.cooldownUntil)
        
        setXMLBool(xmlFile, "FS22_RandomWorldEvents.weatherEvents", self.settings.weatherEvents)
        setXMLBool(xmlFile, "FS22_RandomWorldEvents.economicEvents", self.settings.economicEvents)
        setXMLBool(xmlFile, "FS22_RandomWorldEvents.vehicleEvents", self.settings.vehicleEvents)
        setXMLBool(xmlFile, "FS22_RandomWorldEvents.fieldEvents", self.settings.fieldEvents)
        setXMLBool(xmlFile, "FS22_RandomWorldEvents.wildlifeEvents", self.settings.wildlifeEvents)
        setXMLBool(xmlFile, "FS22_RandomWorldEvents.specialEvents", self.settings.specialEvents)
        
        for eventId, isEnabled in pairs(self.settings.enabledEvents) do
            local key = "FS22_RandomWorldEvents.eventEnabled." .. eventId
            setXMLBool(xmlFile, key, isEnabled)
        end
        
        saveXMLFile(xmlFile)
        delete(xmlFile)
        self:log("Settings saved to XML: "..filePath, 2)
    else
        self:log("Failed to create XML file: "..filePath, 1)
    end
end

-- =====================
-- EVENT MANAGEMENT
-- =====================
function RandomWorldEvents:getAvailableEvents()
    local available = {}
    local totalWeight = 0
    
    for eventId, event in pairs(self.EVENTS) do
        local categoryEnabled = self.settings["categoryEnabled"] or true
        if self.settings[event.category .. "Events"] ~= nil then
            categoryEnabled = self.settings[event.category .. "Events"]
        end
        
        local eventEnabled = self.settings.enabledEvents[eventId]
        
        if categoryEnabled and eventEnabled and event.canTrigger() then
            if self.settings.intensity >= event.minIntensity then
                table.insert(available, eventId)
                totalWeight = totalWeight + event.weight
            end
        end
    end
    
    return available, totalWeight
end

function RandomWorldEvents:selectRandomEvent()
    local available, totalWeight = self:getAvailableEvents()
    
    if #available == 0 then
        return nil
    end
    
    local randomWeight = math.random() * totalWeight
    local cumulativeWeight = 0
    
    for _, eventId in ipairs(available) do
        cumulativeWeight = cumulativeWeight + self.EVENTS[eventId].weight
        if randomWeight <= cumulativeWeight then
            return eventId
        end
    end
    
    return available[1]
end

function RandomWorldEvents:triggerEvent(eventId, manual)
    if not self.settings.enabled then return false end
    if self.EVENT_STATE.activeEvent ~= nil then return false end
    
    local event = self.EVENTS[eventId]
    if event == nil then
        self:log("Unknown event: " .. tostring(eventId), 1)
        return false
    end
    
    if not manual and g_currentMission.time > self.EVENT_STATE.cooldownUntil then
        return false
    end
    
    if self.settings.intensity < event.minIntensity then
        self:log("Event " .. eventId .. " requires intensity " .. event.minIntensity, 2)
        return false
    end
    
    self.EVENT_STATE.activeEvent = eventId
    self.EVENT_STATE.eventStartTime = g_currentMission.time
    self.EVENT_STATE.eventData = {}
    
    local duration = 0
    if type(event.duration) == "table" then
        duration = math.random(event.duration.min, event.duration.max) * 60000 
    elseif type(event.duration) == "number" then
        duration = event.duration * 60000
    end
    self.EVENT_STATE.eventDuration = duration
    
    local message = event.onStart(self.settings.intensity)
    if message then
        self:showNotification(self:i18n(event.name, eventId) .. ": " .. message, event.category)
    end
    
    table.insert(self.EVENT_STATE.history, 1, {
        id = eventId,
        name = event.name,
        time = g_currentMission.time,
        duration = duration,
        manual = manual or false
    })
    
    if #self.EVENT_STATE.history > 10 then
        table.remove(self.EVENT_STATE.history, 11)
    end
    
    self:log("Event triggered: " .. eventId .. (manual and " (manual)" or ""), 1)
    
    if not manual then
        local cooldownMs = self.settings.cooldown * 60000
        local frequencyFactor = (11 - self.settings.frequency) / 10 
        self.EVENT_STATE.cooldownUntil = g_currentMission.time + (cooldownMs * frequencyFactor)
    end
    
    return true
end

function RandomWorldEvents:endActiveEvent()
    if self.EVENT_STATE.activeEvent == nil then return end
    
    local eventId = self.EVENT_STATE.activeEvent
    local event = self.EVENTS[eventId]
    
    if event and event.onEnd then
        local message = event.onEnd()
        if message and message ~= "" then
            self:showNotification(self:i18n(event.name, eventId) .. ": " .. message)
        end
    end
    
    self:log("Event ended: " .. eventId, 1)
    self.EVENT_STATE.activeEvent = nil
    self.EVENT_STATE.eventStartTime = 0
    self.EVENT_STATE.eventDuration = 0
    self.EVENT_STATE.eventData = {}
end

function RandomWorldEvents:skipCurrentEvent()
    if self.EVENT_STATE.activeEvent ~= nil then
        self:log("Skipping current event: " .. self.EVENT_STATE.activeEvent, 1)
        self:endActiveEvent()
        return true
    end
    return false
end

function RandomWorldEvents:checkEventEnd()
    if self.EVENT_STATE.activeEvent == nil then return end
    if self.EVENT_STATE.eventDuration == 0 then
        self:endActiveEvent()
        return
    end
    
    local elapsed = g_currentMission.time - self.EVENT_STATE.eventStartTime
    if elapsed >= self.EVENT_STATE.eventDuration then
        self:endActiveEvent()
    else
        -- Update event
        local event = self.EVENTS[self.EVENT_STATE.activeEvent]
        if event and event.onUpdate then
            event.onUpdate(elapsed, self.EVENT_STATE.eventDuration)
        end
    end
end

function RandomWorldEvents:checkRandomEvent()
    if not self.settings.enabled then return end
    if self.EVENT_STATE.activeEvent ~= nil then return end
    if g_currentMission.time < self.EVENT_STATE.cooldownUntil then return end
    
    local chance = self.settings.frequency * 0.01
    if math.random() <= chance then
        local eventId = self:selectRandomEvent()
        if eventId then
            self:triggerEvent(eventId, false)
        end
    end
end

-- =====================
-- MOD LIFECYCLE
-- =====================
function RandomWorldEvents:loadMap()
    if g_currentMission == nil then return end
    if self.isLoaded then return end
    
    self:loadSettingsFromXML()
    
    if self.settings.enabled then
        self.welcomeTimer = 5.0 
    end
    
    if self.settings.enabled then
        self.welcomeTimer = 5.0
        
        -- Register hooks
        if self:isServer() then
            self:registerMoneyHooks()
            self:registerVehicleHooks()
        end
    end

    self.isLoaded = true
    addConsoleCommand("events", "Configure Random World Events", "onConsoleCommand", self)
    self:tryRegisterSettings()
    
    self:log("Random World Events loaded successfully", 1)
end

function RandomWorldEvents:update(dt)
    if not self.isLoaded then return end
    
    if self.settingsRetryTimer ~= nil then
        self.settingsRetryTimer = self.settingsRetryTimer - dt
        if self.settingsRetryTimer <= 0 then
            self:tryRegisterSettings()
            self.settingsRetryTimer = nil
        end
    end
    
    if self.welcomeTimer ~= nil then
        self.welcomeTimer = self.welcomeTimer - dt
        if self.welcomeTimer <= 0 then
            self:printBanner()
            if self.settings.enabled then
                self:showNotification("Random World Events mod activated!")
            end
            self.welcomeTimer = nil
        end
    end
    
    self.updateInterval = self.updateInterval + dt
    if self.updateInterval > 30 then
        self.updateInterval = 0
        
        if self.settings.enabled and self:isServer() then
            self:checkRandomEvent()
            self:checkEventEnd()
        end
    end
    
    if self.EVENT_STATE.activeEvent ~= nil then
        local event = self.EVENTS[self.EVENT_STATE.activeEvent]
        if event and event.onUpdate and self.EVENT_STATE.eventDuration > 0 then
            local elapsed = g_currentMission.time - self.EVENT_STATE.eventStartTime
            event.onUpdate(elapsed, self.EVENT_STATE.eventDuration)
        end
    end
end

function RandomWorldEvents:tryRegisterSettings()
    if not self.hasRegisteredSettings then
        if g_modSettingsManager ~= nil then
            self:registerModSettings()
            self.hasRegisteredSettings = true
            self:log("Settings registered in pause menu", 2)
        else
            self.settingsRetryTimer = 2000
            self:log("Settings page not available yet, use console to configure", 1)
        end
    end
end

function RandomWorldEvents:registerVehicleHooks()
    if self._vehicleMotorHooked then
        return
    end
    self._vehicleMotorHooked = true

    VehicleMotor.updateMotor = Utils.overwrittenFunction(
        VehicleMotor.updateMotor,
        function(self, superFunc, dt, ...)
            local result = superFunc(self, dt, ...)

            local state = RandomWorldEvents.EVENT_STATE
            if state and state.wearMultiplier and self.vehicle then
                if self.vehicle.getDamageAmount ~= nil and self.vehicle.setDamageAmount ~= nil then
                    local damage = self.vehicle:getDamageAmount()
                    if damage < 1.0 then
                        local wearIncrease = dt * 0.00001 * state.wearMultiplier
                        self.vehicle:setDamageAmount(
                            math.min(1.0, damage + wearIncrease),
                            false
                        )
                    end
                end
            end

            return result
        end
    )

    self:log("Vehicle motor hook registered", 2)
end

function RandomWorldEvents:registerMoneyHooks()
    if self._moneyHooked then
        return
    end
    self._moneyHooked = true

    local originalAddMoney = g_currentMission.addMoney

    g_currentMission.addMoney = function(mission, amount, farmId, moneyType, addToStatistics, ...)
        local modifiedAmount = amount
        local state = RandomWorldEvents.EVENT_STATE

        if state then
            if state.fieldBonus and
               (moneyType == MoneyType.HARVESTING or moneyType == MoneyType.FIELD_WORK) then
                modifiedAmount = modifiedAmount * (1 + state.fieldBonus)
            end

            if state.workerDiscount and moneyType == MoneyType.HIRE_COSTS then
                modifiedAmount = modifiedAmount * (1 - state.workerDiscount)
            end

            if state.animalBonus and
               (moneyType == MoneyType.ANIMAL_INCOME or moneyType == MoneyType.ANIMAL_PRODUCTS) then
                modifiedAmount = modifiedAmount * (1 + state.animalBonus)
            end

            if state.fuelBonus and moneyType == MoneyType.FUEL then
                modifiedAmount = modifiedAmount * (1 - state.fuelBonus)
            end
        end

        if modifiedAmount ~= amount then
            RandomWorldEvents:log(
                string.format(
                    "Money modified (%s): %.0f → %.0f",
                    tostring(moneyType),
                    amount,
                    modifiedAmount
                ),
                2
            )
        end

        return originalAddMoney(
            mission,
            modifiedAmount,
            farmId,
            moneyType,
            addToStatistics,
            ...
        )
    end

    self:log("Money hooks registered", 2)
end


-- =====================
-- SETTINGS MENU
-- =====================
function RandomWorldEvents:registerModSettings()
    if g_modSettingsManager == nil then return false end
    
    local settings = {
        {
            key = "eventsEnabled",
            name = "Enable Events",
            tooltip = "Enable or disable all random events",
            type = "checkbox",
            default = self.DEFAULT_CONFIG.enabled,
            current = self.settings.enabled,
            onChange = function(value)
                self.settings.enabled = value
                self:saveSettingsToXML()
            end
        },
        {
            key = "eventsFrequency",
            name = "Event Frequency",
            tooltip = "How often events occur (1=rare, 10=often)",
            type = "list",
            default = self.DEFAULT_CONFIG.frequency,
            current = self.settings.frequency,
            values = {
                {name = "Very Rare", value = 1},
                {name = "Rare", value = 2},
                {name = "Infrequent", value = 3},
                {name = "Below Average", value = 4},
                {name = "Average", value = 5},
                {name = "Above Average", value = 6},
                {name = "Frequent", value = 7},
                {name = "Very Frequent", value = 8},
                {name = "Extremely Frequent", value = 9},
                {name = "Constant", value = 10}
            },
            onChange = function(value)
                self.settings.frequency = value
                self:saveSettingsToXML()
            end
        },
        {
            key = "eventsIntensity",
            name = "Event Intensity",
            tooltip = "How strong events are (1=mild, 5=extreme)",
            type = "list",
            default = self.DEFAULT_CONFIG.intensity,
            current = self.settings.intensity,
            values = {
                {name = "Very Mild", value = 1},
                {name = "Mild", value = 2},
                {name = "Medium", value = 3},
                {name = "Strong", value = 4},
                {name = "Extreme", value = 5}
            },
            onChange = function(value)
                self.settings.intensity = value
                self:saveSettingsToXML()
            end
        },
        {
            key = "eventsCooldown",
            name = "Event Cooldown",
            tooltip = "Minimum minutes between events",
            type = "list",
            default = self.DEFAULT_CONFIG.cooldown,
            current = self.settings.cooldown,
            values = {
                {name = "5 minutes", value = 5},
                {name = "15 minutes", value = 15},
                {name = "30 minutes", value = 30},
                {name = "60 minutes", value = 60},
                {name = "120 minutes", value = 120}
            },
            onChange = function(value)
                self.settings.cooldown = value
                self:saveSettingsToXML()
            end
        },
        {
            key = "eventsNotifications",
            name = "Show Notifications",
            tooltip = "Show event notifications",
            type = "checkbox",
            default = self.DEFAULT_CONFIG.showNotifications,
            current = self.settings.showNotifications,
            onChange = function(value)
                self.settings.showNotifications = value
                self:saveSettingsToXML()
            end
        },
        {
            key = "eventsWarnings",
            name = "Show Warnings",
            tooltip = "Show warning notifications",
            type = "checkbox",
            default = self.DEFAULT_CONFIG.showWarnings,
            current = self.settings.showWarnings,
            onChange = function(value)
                self.settings.showWarnings = value
                self:saveSettingsToXML()
            end
        },
        {
            key = "eventsDebug",
            name = "Debug Level",
            tooltip = "Debug logging level",
            type = "list",
            default = self.DEFAULT_CONFIG.debugLevel,
            current = self.settings.debugLevel,
            values = {
                {name = "OFF", value = 0},
                {name = "BASIC", value = 1},
                {name = "VERBOSE", value = 2}
            },
            onChange = function(value)
                self.settings.debugLevel = value
                self:saveSettingsToXML()
            end
        }
    }
    
    g_modSettingsManager:addModSettings(self.modName, settings, "Random World Events")
    return true
end

-- =====================
-- CONSOLE COMMANDS
-- =====================
function RandomWorldEvents:onConsoleCommand(...)
    local args = {...}
    if #args == 0 then
        print(self:i18n("events_mod_console_help", "Type 'events help' for commands"))
        return true
    end
    
    local action = args[1]:lower()
    
    if action == "help" or action == "?" then
        print(self:i18n("events_mod_console_help", "See modDesc for help text"))
        
    elseif action == "status" then
        print("=== Random World Events Status ===")
        print("Enabled: " .. tostring(self.settings.enabled))
        print("Frequency: " .. self.settings.frequency .. " (1-10)")
        print("Intensity: " .. self.settings.intensity .. " (1-5)")
        print("Cooldown: " .. self.settings.cooldown .. " minutes")
        print("Active Event: " .. (self.EVENT_STATE.activeEvent or "None"))
        print("Notifications: " .. tostring(self.settings.showNotifications))
        print("Debug Level: " .. self.settings.debugLevel)
        print("Event Categories:")
        print("  Weather: " .. tostring(self.settings.weatherEvents))
        print("  Economic: " .. tostring(self.settings.economicEvents))
        print("  Vehicle: " .. tostring(self.settings.vehicleEvents))
        print("  Field: " .. tostring(self.settings.fieldEvents))
        print("  Wildlife: " .. tostring(self.settings.wildlifeEvents))
        print("  Special: " .. tostring(self.settings.specialEvents))
        
    elseif action == "enable" then
        if args[2] then
            local eventType = args[2]:lower()
            if self.settings[eventType .. "Events"] ~= nil then
                self.settings[eventType .. "Events"] = true
                self:saveSettingsToXML()
                print(eventType:gsub("^%l", string.upper) .. " events enabled")
            elseif self.EVENTS[eventType] ~= nil then
                self.settings.enabledEvents[eventType] = true
                self:saveSettingsToXML()
                print("Event '" .. eventType .. "' enabled")
            else
                print("Unknown event type: " .. eventType)
            end
        else
            self.settings.enabled = true
            self:saveSettingsToXML()
            print("All events enabled")
        end
        
    elseif action == "disable" then
        if args[2] then
            local eventType = args[2]:lower()
            if self.settings[eventType .. "Events"] ~= nil then
                self.settings[eventType .. "Events"] = false
                self:saveSettingsToXML()
                print(eventType:gsub("^%l", string.upper) .. " events disabled")
            elseif self.EVENTS[eventType] ~= nil then
                self.settings.enabledEvents[eventType] = false
                self:saveSettingsToXML()
                print("Event '" .. eventType .. "' disabled")
            else
                print("Unknown event type: " .. eventType)
            end
        else
            self.settings.enabled = false
            self:saveSettingsToXML()
            print("All events disabled")
        end
        
    elseif action == "trigger" and args[2] then
        local eventId = args[2]:lower()
        if self.EVENTS[eventId] then
            if self:triggerEvent(eventId, true) then
                print("Event triggered: " .. eventId)
            else
                print("Failed to trigger event: " .. eventId)
            end
        else
            print("Unknown event: " .. eventId)
            print("Use 'events list' to see available events")
        end
        
    elseif action == "list" then
        print("=== Available Events ===")
        local categories = {
            "weather", "economic", "vehicle", "field", "wildlife", "special"
        }
        
        for _, category in ipairs(categories) do
            if self.settings[category .. "Events"] then
                print(category:gsub("^%l", string.upper) .. " Events:")
                for eventId, event in pairs(self.EVENTS) do
                    if event.category == category and self.settings.enabledEvents[eventId] then
                        local enabledStr = self.settings.enabledEvents[eventId] and "[ENABLED]" or "[DISABLED]"
                        print("  " .. eventId .. " " .. enabledStr .. " - " .. self:i18n(event.name, eventId))
                    end
                end
            end
        end
        
    elseif action == "frequency" and args[2] then
        local freq = tonumber(args[2])
        if freq and freq >= 1 and freq <= 10 then
            self.settings.frequency = freq
            self:saveSettingsToXML()
            print("Frequency set to: " .. freq)
        else
            print("Frequency must be between 1 and 10")
        end
        
    elseif action == "intensity" and args[2] then
        local intensity = tonumber(args[2])
        if intensity and intensity >= 1 and intensity <= 5 then
            self.settings.intensity = intensity
            self:saveSettingsToXML()
            print("Intensity set to: " .. intensity)
        else
            print("Intensity must be between 1 and 5")
        end
        
    elseif action == "test" then
        print("Testing random event...")
        local eventId = self:selectRandomEvent()
        if eventId then
            self:triggerEvent(eventId, true)
            print("Test event triggered: " .. eventId)
        else
            print("No events available to test")
        end
        
    elseif action == "reload" then
        self:loadSettingsFromXML()
        print("Settings reloaded from XML")
        
    elseif action == "skip" then
        if self:skipCurrentEvent() then
            print("Current event skipped")
        else
            print("No active event to skip")
        end
        
    elseif action == "history" then
        print("=== Recent Events ===")
        if #self.EVENT_STATE.history == 0 then
            print("No recent events")
        else
            for i, event in ipairs(self.EVENT_STATE.history) do
                local timeStr = string.format("%.1f", (g_currentMission.time - event.time) / 60000) .. "m ago"
                local name = self:i18n(event.name, event.id)
                local manualStr = event.manual and " (manual)" or ""
                print(i .. ". " .. name .. manualStr .. " - " .. timeStr)
            end
        end
        
    else
        print("Unknown command. Type 'events help' for commands.")
    end
    
    return true
end

-- =====================
-- GLOBAL REGISTRATION
-- =====================
g_RandomWorldEvents = RandomWorldEvents
addModEventListener(RandomWorldEvents)
