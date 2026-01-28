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

local function getFarmId()
    return g_currentMission and g_currentMission.player and g_currentMission.player.farmId or 0
end

local function getVehicle()
    return g_currentMission and g_currentMission.controlledVehicle or nil
end

local function getAllVehicles()
    local vehicles = {}
    if g_currentMission and g_currentMission.vehicles then
        for _, vehicle in pairs(g_currentMission.vehicles) do
            if vehicle and vehicle:getOwnerFarmId() == getFarmId() then
                table.insert(vehicles, vehicle)
            end
        end
    end
    return vehicles
end

-- =====================
-- VEHICLE SPEED SYSTEM
-- =====================
local function applyVehicleSpeedBoost(vehicle, multiplier)
    if not vehicle or not vehicle.setSpeedLimit then return end
    
    -- Store original speed if not already stored
    if not vehicle.originalSpeedLimit then
        vehicle.originalSpeedLimit = vehicle.speedLimit or 100
    end
    
    -- Apply speed boost
    vehicle.speedLimit = vehicle.originalSpeedLimit * multiplier
    vehicle:setSpeedLimit(vehicle.speedLimit)
    
    -- Also boost maxSpeed for physics
    if vehicle.maxSpeed then
        if not vehicle.originalMaxSpeed then
            vehicle.originalMaxSpeed = vehicle.maxSpeed
        end
        vehicle.maxSpeed = vehicle.originalMaxSpeed * multiplier
    end
end

local function resetVehicleSpeed(vehicle)
    if not vehicle then return end
    
    if vehicle.originalSpeedLimit then
        vehicle.speedLimit = vehicle.originalSpeedLimit
        vehicle:setSpeedLimit(vehicle.speedLimit)
        vehicle.originalSpeedLimit = nil
    end
    
    if vehicle.originalMaxSpeed then
        vehicle.maxSpeed = vehicle.originalMaxSpeed
        vehicle.originalMaxSpeed = nil
    end
end

-- =====================
-- VEHICLE FUEL SYSTEM
-- =====================
local function fillVehicleFuel(vehicle)
    if not vehicle or not vehicle.getFillUnits then return 0 end
    local filledAmount = 0
    local fillUnits = vehicle:getFillUnits()
    
    for fillUnitIndex, _ in pairs(fillUnits) do
        local fillType = vehicle:getFillUnitFillType(fillUnitIndex)
        if fillType ~= FillType.UNKNOWN then
            local capacity = vehicle:getFillUnitCapacity(fillUnitIndex)
            local current = vehicle:getFillUnitFillLevel(fillUnitIndex)
            local toFill = capacity - current
            
            if toFill > 0 then
                vehicle:setFillUnitFillLevel(fillUnitIndex, capacity, fillType)
                filledAmount = filledAmount + toFill
            end
        end
    end
    
    return filledAmount
end

local function drainVehicleFuel(vehicle, percentage)
    if not vehicle or not vehicle.getFillUnits then return 0 end
    
    local drainedAmount = 0
    local fillUnits = vehicle:getFillUnits()
    
    for fillUnitIndex, _ in pairs(fillUnits) do
        local fillType = vehicle:getFillUnitFillType(fillUnitIndex)
        if fillType ~= FillType.UNKNOWN then
            local current = vehicle:getFillUnitFillLevel(fillUnitIndex)
            local toDrain = current * (percentage / 100)
            
            if toDrain > 0 then
                vehicle:setFillUnitFillLevel(fillUnitIndex, current - toDrain, fillType)
                drainedAmount = drainedAmount + toDrain
            end
        end
    end
    
    return drainedAmount
end

-- =====================
-- VEHICLE DAMAGE SYSTEM
-- =====================
local function applyVehicleDamage(vehicle, damagePercentage)
    if not vehicle or not vehicle.addDamageAmount then return end  -- This is correct
    
    -- Calculate damage amount (0-1 scale)
    local damageAmount = damagePercentage / 100
    
    -- Apply damage
    vehicle:addDamageAmount(damageAmount)
    
    -- Create visual effect
    if vehicle.getDamageVisualization then
        vehicle:getDamageVisualization()
    end
end  -- This was missing

local function repairVehicleDamage(vehicle)
    if not vehicle or not vehicle.repair then return end  -- Added 'end' here
    
    -- Repair vehicle
    vehicle:repair()
    
    -- Apply repair cost
    local repairCost = math.random(500, 2000)
    g_currentMission:addMoney(-repairCost, getFarmId(), MoneyType.VEHICLE_REPAIR, true)
    
    return repairCost
end

-- =====================
-- VEHICLE TOOL SYSTEM
-- =====================
local function applyToolBonus(vehicle)
    if not vehicle or not vehicle.getAttachedImplements then return end
    
    local implements = vehicle:getAttachedImplements()
    local bonusCount = 0
    
    for _, implement in ipairs(implements) do
        local object = implement.object
        if object then
            -- Store original wear amount if not already stored
            if not object.originalWearAmount then
                object.originalWearAmount = object.wearAmount or 0
            end
            
            -- Reduce wear (make tool more durable)
            object.wearAmount = (object.originalWearAmount or 0) * 0.5
            bonusCount = bonusCount + 1
            
            -- Visual effect: slight glow
            if object.setVisibility then
                -- Could add visual effect here
            end
        end
    end
    
    return bonusCount
end

local function resetToolBonus(vehicle)
    if not vehicle or not vehicle.getAttachedImplements then return end
    
    local implements = vehicle:getAttachedImplements()
    
    for _, implement in ipairs(implements) do
        local object = implement.object
        if object and object.originalWearAmount then
            object.wearAmount = object.originalWearAmount
            object.originalWearAmount = nil
        end
    end
end

-- =====================
-- VEHICLE CLEANING SYSTEM
-- =====================
local function cleanVehicle(vehicle)
    if not vehicle or not vehicle.getDirtAmount then return 0 end
    
    local dirtBefore = vehicle:getDirtAmount() or 0
    local dirtReduced = dirtBefore
    
    -- Clean the vehicle
    vehicle:setDirtAmount(0)
    
    -- Clean attached implements too
    if vehicle.getAttachedImplements then
        local implements = vehicle:getAttachedImplements()
        for _, implement in ipairs(implements) do
            local object = implement.object
            if object and object.setDirtAmount then
                object:setDirtAmount(0)
            end
        end
    end
    
    return dirtReduced
end

-- =====================
-- VEHICLE UPGRADE SYSTEM
-- =====================
local function applyVisualUpgrade(vehicle)
    if not vehicle then return false end
    
    -- Store original color if not already stored
    if not vehicle.originalColor then
        vehicle.originalColor = {vehicle:getColor()}
    end
    
    -- Apply special color (gold tint)
    local r, g, b = unpack(vehicle.originalColor)
    vehicle:setColor(r * 1.2, g * 1.1, b * 0.9)  -- Gold tint
    
    -- Add particle effect
    if g_effectManager then
        local x, y, z = getWorldTranslation(vehicle.rootNode)
        g_effectManager:spawnEffect("sparkleEffect", vehicle.rootNode, x, y + 3, z)
    end
    
    return true
end

local function resetVisualUpgrade(vehicle)
    if not vehicle or not vehicle.originalColor then return end
    
    -- Restore original color
    local r, g, b = unpack(vehicle.originalColor)
    vehicle:setColor(r, g, b)
    vehicle.originalColor = nil
end

-- =====================
-- VEHICLE AI SYSTEM
-- =====================
local function applyAISpeedBoost()
    if not g_currentMission or not g_currentMission.vehicles then return 0 end
    
    local boostedCount = 0
    local vehicles = g_currentMission.vehicles
    
    for _, vehicle in pairs(vehicles) do
        if vehicle and vehicle:getOwnerFarmId() ~= getFarmId() then  -- Only other farm vehicles
            if vehicle.speedLimit then
                if not vehicle.originalAISpeed then
                    vehicle.originalAISpeed = vehicle.speedLimit
                end
                vehicle.speedLimit = vehicle.originalAISpeed * 1.5
                boostedCount = boostedCount + 1
            end
        end
    end
    
    return boostedCount
end

local function resetAISpeedBoost()
    if not g_currentMission or not g_currentMission.vehicles then return end
    
    local vehicles = g_currentMission.vehicles
    
    for _, vehicle in pairs(vehicles) do
        if vehicle and vehicle.originalAISpeed then
            vehicle.speedLimit = vehicle.originalAISpeed
            vehicle.originalAISpeed = nil
        end
    end
end

-- =====================
-- VEHICLE EVENTS
-- =====================
local vehicleEvents = {
    {
        name = "vehicle_speed_boost",
        minI = 1,
        func = function(intensity)
            local vehicle = getVehicle()
            if vehicle then
                local multiplier = 1.2 + (intensity * 0.1)
                applyVehicleSpeedBoost(vehicle, multiplier)
                RandomWorldEvents.EVENT_STATE.vehicleSpeedBoost = {vehicle = vehicle, multiplier = multiplier}
                return string.format("Vehicle speed boost! +%.0f%% speed", (multiplier - 1) * 100)
            end
            return "Vehicle speed boost available (get in a vehicle)"
        end
    },
    
    {
        name = "vehicle_fuel_bonus",
        minI = 1,
        func = function(intensity)
            local vehicle = getVehicle()
            if vehicle then
                local filledAmount = fillVehicleFuel(vehicle)
                if filledAmount > 0 then
                    return string.format("Fuel tanks filled! +%.1fL", filledAmount)
                else
                    return "Vehicle already fully fueled"
                end
            end
            return "Free fuel available (get in a vehicle)"
        end
    },
    
    {
        name = "vehicle_fuel_penalty",
        minI = 1,
        func = function(intensity)
            local vehicle = getVehicle()
            if vehicle then
                local drainPercent = 20 + (intensity * 10)
                local drainedAmount = drainVehicleFuel(vehicle, drainPercent)
                if drainedAmount > 0 then
                    return string.format("Fuel leak! -%.0f%% fuel lost", drainPercent)
                else
                    return "Vehicle has no fuel to drain"
                end
            end
            return "Fuel penalty avoided (no vehicle)"
        end
    },
    
    {
        name = "vehicle_accident",
        minI = 1,
        func = function(intensity)
            local vehicle = getVehicle()
            if vehicle then
                local damagePercent = 10 + (intensity * 5)
                applyVehicleDamage(vehicle, damagePercent)
                
                -- Add repair bill
                local repairCost = math.random(500, 1500) * intensity
                g_currentMission:addMoney(-repairCost, getFarmId(), MoneyType.VEHICLE_REPAIR, true)
                
                RandomWorldEvents.EVENT_STATE.vehicleAccident = {vehicle = vehicle, damagePercent = damagePercent}
                return string.format("Minor accident! %.0f%% damage, €%d repair bill", damagePercent, repairCost)
            end
            return "Accident avoided (no vehicle)"
        end
    },
    
    {
        name = "vehicle_repair_bill",
        minI = 1,
        func = function(intensity)
            local vehicles = getAllVehicles()
            local totalCost = 0
            local repairedCount = 0
            
            for _, vehicle in ipairs(vehicles) do
                if vehicle and vehicle.getDamageAmount then
                    local damage = vehicle:getDamageAmount() or 0
                    if damage > 0.1 then  -- Only repair if significantly damaged
                        local cost = repairVehicleDamage(vehicle)
                        totalCost = totalCost + cost
                        repairedCount = repairedCount + 1
                    end
                end
            end
            
            if repairedCount > 0 then
                return string.format("Vehicle%s repaired! Total cost: €%d", repairedCount > 1 and "s" or "", totalCost)
            else
                return "All vehicles in good condition (no repair needed)"
            end
        end
    },
    
    {
        name = "vehicle_free_upgrade",
        minI = 1,
        func = function(intensity)
            local vehicle = getVehicle()
            if vehicle then
                local upgraded = applyVisualUpgrade(vehicle)
                if upgraded then
                    RandomWorldEvents.EVENT_STATE.vehicleUpgrade = {vehicle = vehicle}
                    return "Vehicle visual upgrade applied! (Golden tint)"
                end
            end
            return "Free upgrade available (get in a vehicle)"
        end
    },
    
    {
        name = "vehicle_cleaning_bonus",
        minI = 1,
        func = function(intensity)
            local vehicles = getAllVehicles()
            local cleanedCount = 0
            local totalDirt = 0
            
            for _, vehicle in ipairs(vehicles) do
                local dirtRemoved = cleanVehicle(vehicle)
                if dirtRemoved > 0 then
                    cleanedCount = cleanedCount + 1
                    totalDirt = totalDirt + dirtRemoved
                end
            end
            
            if cleanedCount > 0 then
                return string.format("%d vehicle%s cleaned! All dirt removed", cleanedCount, cleanedCount > 1 and "s" or "")
            else
                return "Vehicles already clean"
            end
        end
    },
    
    {
        name = "vehicle_tool_bonus",
        minI = 1,
        func = function(intensity)
            local vehicle = getVehicle()
            if vehicle then
                local bonusCount = applyToolBonus(vehicle)
                if bonusCount > 0 then
                    RandomWorldEvents.EVENT_STATE.vehicleToolBonus = {vehicle = vehicle}
                    return string.format("Tool durability doubled! %d implement%s affected", bonusCount, bonusCount > 1 and "s" or "")
                else
                    return "No tools attached to vehicle"
                end
            end
            return "Tool bonus available (get in a vehicle with attachments)"
        end
    },
    
    {
        name = "vehicle_ai_speed_boost",
        minI = 1,
        func = function(intensity)
            local boostedCount = applyAISpeedBoost()
            if boostedCount > 0 then
                RandomWorldEvents.EVENT_STATE.aiSpeedBoost = true
                return string.format("AI vehicles move faster! %d vehicle%s affected", boostedCount, boostedCount > 1 and "s" or "")
            else
                return "No AI vehicles found"
            end
        end
    },
    
    {
        name = "vehicle_engine_trouble",
        minI = 2,
        func = function(intensity)
            local vehicle = getVehicle()
            if vehicle then
                -- Reduce engine power temporarily
                if vehicle.getMotor then
                    local motor = vehicle:getMotor()
                    if motor then
                        if not motor.originalPower then
                            motor.originalPower = motor.maxPower or 100
                        end
                        motor.maxPower = motor.originalPower * (1 - (0.1 * intensity))
                        
                        RandomWorldEvents.EVENT_STATE.engineTrouble = {
                            vehicle = vehicle,
                            motor = motor,
                            originalPower = motor.originalPower
                        }
                        
                        return string.format("Engine trouble! -%.0f%% power", intensity * 10)
                    end
                end
            end
            return "Engine trouble avoided (no vehicle)"
        end
    }
}

-- =====================
-- REGISTER VEHICLE EVENTS
-- =====================
for _, e in pairs(vehicleEvents) do
    g_RandomWorldEvents:registerEvent({
        name = e.name,
        category = "vehicle",
        weight = 1,
        duration = {min = 10, max = 30},
        minIntensity = e.minI,
        canTrigger = function() 
            -- Always allow vehicle events to trigger
            return g_currentMission ~= nil
        end,
        onStart = e.func,
        onEnd = function()
            -- Clean up active vehicle effects
            local eventData = RandomWorldEvents.EVENT_STATE
            
            -- Reset speed boost
            if eventData.vehicleSpeedBoost then
                resetVehicleSpeed(eventData.vehicleSpeedBoost.vehicle)
                eventData.vehicleSpeedBoost = nil
            end
            
            -- Reset visual upgrade
            if eventData.vehicleUpgrade then
                resetVisualUpgrade(eventData.vehicleUpgrade.vehicle)
                eventData.vehicleUpgrade = nil
            end
            
            -- Reset tool bonus
            if eventData.vehicleToolBonus then
                resetToolBonus(eventData.vehicleToolBonus.vehicle)
                eventData.vehicleToolBonus = nil
            end
            
            -- Reset AI speed boost
            if eventData.aiSpeedBoost then
                resetAISpeedBoost()
                eventData.aiSpeedBoost = nil
            end
            
            -- Reset engine trouble
            if eventData.engineTrouble then
                local motor = eventData.engineTrouble.motor
                local originalPower = eventData.engineTrouble.originalPower
                if motor and originalPower then
                    motor.maxPower = originalPower
                end
                eventData.engineTrouble = nil
            end
            
            return "Vehicle event ended"
        end
    })
end

-- =====================
-- UPDATE INTEGRATION
-- =====================
RandomWorldEvents.originalUpdate = RandomWorldEvents.originalUpdate or RandomWorldEvents.update

function RandomWorldEvents:update(dt)
    self:originalUpdate(dt)
    
    -- Apply active vehicle effects
    local eventData = self.EVENT_STATE
    
    if eventData.vehicleSpeedBoost then
        local vehicle = g_currentMission.controlledVehicle
        if vehicle and vehicle == eventData.vehicleSpeedBoost.vehicle then
            applyVehicleSpeedBoost(vehicle, eventData.vehicleSpeedBoost.multiplier)
        end
    end
    
    -- Show visual effects for active events
    if eventData.vehicleUpgrade then
        local vehicle = eventData.vehicleUpgrade.vehicle
        if vehicle and g_currentMission.time % 2000 < 100 then  -- Every 2 seconds
            local x, y, z = getWorldTranslation(vehicle.rootNode)
            if g_effectManager then
                g_effectManager:spawnEffect("sparkleEffect", vehicle.rootNode, x, y + 2, z)
            end
        end
    end
end

print("[VehicleEvents] Loaded 10 vehicle events with real implementations")
print("[VehicleEvents] Features: Speed boost, fuel management, damage system, visual upgrades, AI control")
