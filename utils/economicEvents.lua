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

local eventId = 0

local function getFarmId()
    return g_currentMission and g_currentMission.player and g_currentMission.player.farmId or 0
end

local function getVehicle()
    return g_currentMission and g_currentMission.controlledVehicle or nil
end

local function randomDuration(minMinutes, maxMinutes)
    return (math.random(minMinutes, maxMinutes) * 60000)
end

-- =====================
-- ECONOMIC EVENTS (10)
-- =====================
local economicEvents = {
    {name="government_subsidy",      minI=1, func=function(intensity) 
        local amount = 5000 + intensity * 2500 
        g_currentMission:addMoney(amount, getFarmId(), MoneyType.OTHER, true) 
        return string.format("Government subsidy! +€%s", g_i18n:formatMoney(amount, 0, true, true)) 
    end},
    
    {name="market_boom", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.marketBonus = 0.1 + intensity * 0.05 
        return string.format("MARKET BOOM! +%.0f%% sell price", RandomWorldEvents.EVENT_STATE.marketBonus * 100) 
    end},
    
    {name="market_crash", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.marketMalus = 0.1 + intensity * 0.05 
        return string.format("MARKET CRASH! -%.0f%% sell price", RandomWorldEvents.EVENT_STATE.marketMalus * 100) 
    end},
    
    {name="sudden_expense", minI=1, func=function(intensity) 
        local amount = 2000 + 1000 * intensity 
        g_currentMission:addMoney(-amount, getFarmId(), MoneyType.OTHER, true) 
        return string.format("Unexpected expense! -€%s", g_i18n:formatMoney(amount, 0, true, true)) 
    end},
    
    {name="farmer_donation", minI=1, func=function(intensity) 
        local amount = 1000 * intensity 
        g_currentMission:addMoney(amount, getFarmId(), MoneyType.OTHER, true) 
        return string.format("Farmers donated €%s", g_i18n:formatMoney(amount, 0, true, true)) 
    end},
    
    {name="seed_discount", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.seedDiscount = 0.1 + 0.05 * intensity 
        return string.format("Seed discount active! -%.0f%%", RandomWorldEvents.EVENT_STATE.seedDiscount * 100) 
    end},
    
    {name="fertilizer_discount", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.fertilizerDiscount = 0.1 + 0.05 * intensity 
        return string.format("Fertilizer discount! -%.0f%%", RandomWorldEvents.EVENT_STATE.fertilizerDiscount * 100) 
    end},
    
    {name="fuel_discount", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.fuelDiscount = 0.1 + 0.05 * intensity 
        return string.format("Fuel discount! -%.0f%%", RandomWorldEvents.EVENT_STATE.fuelDiscount * 100) 
    end},
    
    {name="equipment_discount", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.equipmentDiscount = 0.1 + 0.05 * intensity 
        return string.format("Equipment discount! -%.0f%%", RandomWorldEvents.EVENT_STATE.equipmentDiscount * 100) 
    end},
    
    {name="insurance_bonus", minI=1, func=function(intensity) 
        local amount = 3000 + intensity * 1000
        g_currentMission:addMoney(amount, getFarmId(), MoneyType.OTHER, true)
        return string.format("Insurance payout! +€%s", g_i18n:formatMoney(amount, 0, true, true))
    end},
}

for _, e in pairs(economicEvents) do
    eventId = eventId + 1
    RandomWorldEvents.EVENTS[e.name] = {
        name = e.name,
        category = "economic",
        weight = 1,
        duration = 0, 
        minIntensity = e.minI,
        canTrigger = function() return g_currentMission ~= nil end,
        onStart = e.func,
        onEnd = function()
            RandomWorldEvents.EVENT_STATE.marketBonus = nil
            RandomWorldEvents.EVENT_STATE.marketMalus = nil
            RandomWorldEvents.EVENT_STATE.seedDiscount = nil
            RandomWorldEvents.EVENT_STATE.fertilizerDiscount = nil
            RandomWorldEvents.EVENT_STATE.fuelDiscount = nil
            RandomWorldEvents.EVENT_STATE.equipmentDiscount = nil
            return "Economic event ended"
        end
    }
end

-- =====================
-- VEHICLE EVENTS (10)
-- =====================
local vehicleEvents = {
    {name="vehicle_repair_bill", minI=1, func=function(intensity) 
        local v = getVehicle() 
        if v then 
            g_currentMission:addMoney(-(1000 + 500 * intensity), getFarmId(), MoneyType.VEHICLE_REPAIR, true) 
        end 
        return "Vehicle repair needed!" 
    end},
    
    {name="vehicle_upgrade", minI=1, func=function() 
        return "Vehicle upgraded! (Visual effect only)" 
    end},
    
    {name="fuel_bonus", minI=1, func=function() 
        local v = getVehicle() 
        if v then 
            for _, u in pairs(v:getFillUnits()) do 
                v:setFillUnitFillLevel(u, v:getFillUnitCapacity(u), true) 
            end 
        end 
        return "Vehicle tanks filled!" 
    end},
    
    {name="vehicle_speed_boost", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.speedBoost = 1.1 + 0.05 * intensity 
        return string.format("Vehicle speed +%.0f%%!", (RandomWorldEvents.EVENT_STATE.speedBoost - 1) * 100) 
    end},
    
    {name="vehicle_fuel_penalty", minI=1, func=function(intensity) 
        local v = getVehicle() 
        if v then 
            for _, u in pairs(v:getFillUnits()) do 
                v:setFillUnitFillLevel(u, math.max(0, v:getFillUnitFillLevel(u) - 100 * intensity), true) 
            end 
        end 
        return "Vehicle fuel reduced!" 
    end},
    
    {name="vehicle_accident", minI=1, func=function(intensity) 
        return "Vehicle minor accident! Repair soon!" 
    end},
    
    {name="vehicle_free_upgrade", minI=1, func=function() 
        return "Vehicle free upgrade! (Visual effect only)" 
    end},
    
    {name="vehicle_cleaning_bonus", minI=1, func=function() 
        return "Vehicle cleaned for free!" 
    end},
    
    {name="vehicle_tool_bonus", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.toolBonus = true
        return "Attached implements upgraded!" 
    end},
    
    {name="vehicle_ai_speed_boost", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.aiSpeedBoost = 1.1 + 0.05 * intensity 
        return "AI vehicles move faster!" 
    end},
}

for _, e in pairs(vehicleEvents) do
    eventId = eventId + 1
    RandomWorldEvents.EVENTS[e.name] = {
        name = e.name,
        category = "vehicle",
        weight = 1,
        duration = {min = 10, max = 30},
        minIntensity = e.minI,
        canTrigger = function() return getVehicle() ~= nil end,
        onStart = e.func,
        onEnd = function()
            RandomWorldEvents.EVENT_STATE.speedBoost = nil
            RandomWorldEvents.EVENT_STATE.aiSpeedBoost = nil
            RandomWorldEvents.EVENT_STATE.toolBonus = nil
            return "Vehicle event ended"
        end
    }
end

RandomWorldEvents.originalUpdate = RandomWorldEvents.originalUpdate or RandomWorldEvents.update
function RandomWorldEvents:update(dt)
    self:originalUpdate(dt)
    
    if self.EVENT_STATE.activeEvent then
        local vehicle = g_currentMission.controlledVehicle
        if vehicle and self.EVENT_STATE.speedBoost then
            vehicle.maxSpeed = (vehicle.originalMaxSpeed or vehicle.maxSpeed) * self.EVENT_STATE.speedBoost
        end
    end
end

print("[EventManager] Loaded 20 events (10 Economic, 10 Vehicle)")