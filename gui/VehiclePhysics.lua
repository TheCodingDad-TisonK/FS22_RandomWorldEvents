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

---@class VehiclePhysics
VehiclePhysics = {}

-- Cache frequently accessed values for better performance
local getRotation, setRotation, getTranslation, setTranslation = getRotation, setRotation, getTranslation, setTranslation

-- Constants for physics adjustments
local DAMPING_MULTIPLIER = 0.1
local COM_VERTICAL_ADJUSTMENT = 0.15
local MIN_PHYSICS_VALUE = 0.01
local MAX_PHYSICS_VALUE = 10.0

-- =====================
-- VALIDATION FUNCTIONS
-- =====================

---@param vehicle table
---@return boolean
local function isValidVehicle(vehicle)
    return vehicle ~= nil 
        and type(vehicle) == "table" 
        and vehicle.getIsActiveForPhysics ~= nil
end

---@param physics table
---@return boolean
local function isPhysicsEnabled(physics)
    return physics ~= nil 
        and type(physics) == "table" 
        and physics.enabled == true
end

---@param value number
---@param min number
---@param max number
---@return number
local function clampPhysicsValue(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

---@param value number
---@return number
local function safePhysicsMultiplier(value)
    return clampPhysicsValue(value or 1.0, MIN_PHYSICS_VALUE, MAX_PHYSICS_VALUE)
end

-- =====================
-- CORE PHYSICS FUNCTIONS
-- =====================

---@param wheel table
---@param gripMultiplier number
local function applyWheelGrip(wheel, gripMultiplier)
    if wheel ~= nil and wheel.physics ~= nil then
        wheel.physics.frictionScale = safePhysicsMultiplier(gripMultiplier)
    end
end

---@param wheel table
---@param stiffnessMultiplier number
local function applySuspensionStiffness(wheel, stiffnessMultiplier)
    if wheel ~= nil and wheel.suspension ~= nil then
        local safeStiffness = safePhysicsMultiplier(stiffnessMultiplier)
        wheel.suspension.springForce = wheel.suspension.springForce * safeStiffness
    end
end

---@param axis table
---@param damping number
local function applyArticulationDamping(axis, damping)
    if axis ~= nil and axis.jointNode ~= nil then
        local safeDamping = clampPhysicsValue(damping or 0.5, 0.0, 1.0)
        local rx, ry, rz = getRotation(axis.jointNode)
        
        setRotation(
            axis.jointNode,
            rx * (1 - safeDamping * DAMPING_MULTIPLIER),
            ry,
            rz * (1 - safeDamping * DAMPING_MULTIPLIER)
        )
    end
end

---@param vehicle table
---@param comStrength number
local function adjustCenterOfMass(vehicle, comStrength)
    if vehicle.massNode == nil or vehicle.getFillUnits == nil then
        return
    end
    
    local totalFill = 0
    local capacity = 0
    
    -- Safely iterate through fill units
    local fillUnits = vehicle:getFillUnits()
    if fillUnits ~= nil then
        for _, unit in pairs(fillUnits) do
            if unit ~= nil then
                totalFill = totalFill + (vehicle:getFillUnitFillLevel(unit) or 0)
                capacity = capacity + (vehicle:getFillUnitCapacity(unit) or 0)
            end
        end
    end
    
    if capacity > 0 then
        local loadFactor = totalFill / capacity
        local safeStrength = safePhysicsMultiplier(comStrength)
        local verticalAdjustment = safeStrength * loadFactor * COM_VERTICAL_ADJUSTMENT
        
        local x, y, z = getTranslation(vehicle.massNode)
        setTranslation(vehicle.massNode, x, y - verticalAdjustment, z)
    end
end

-- =====================
-- MAIN UPDATE FUNCTION
-- =====================

---@param vehicle table
function VehiclePhysics:update(vehicle)
    -- Early exit if vehicle is invalid
    if not isValidVehicle(vehicle) then
        return
    end
    
    -- Check if vehicle is active for physics
    if not vehicle:getIsActiveForPhysics() then
        return
    end
    
    -- Get physics settings
    local physics = g_RandomWorldEvents.physics
    if not isPhysicsEnabled(physics) then
        return
    end
    
    -- Apply wheel grip adjustments
    if vehicle.wheels ~= nil and physics.wheelGripMultiplier ~= nil then
        for _, wheel in pairs(vehicle.wheels) do
            if wheel ~= nil then
                applyWheelGrip(wheel, physics.wheelGripMultiplier)
            end
        end
    end
    
    -- Apply suspension stiffness
    if vehicle.wheels ~= nil and physics.suspensionStiffness ~= nil then
        for _, wheel in pairs(vehicle.wheels) do
            if wheel ~= nil then
                applySuspensionStiffness(wheel, physics.suspensionStiffness)
            end
        end
    end
    
    -- Apply articulation damping for articulated vehicles
    if vehicle.articulatedAxis ~= nil and physics.articulationDamping ~= nil then
        for _, axis in pairs(vehicle.articulatedAxis) do
            if axis ~= nil then
                applyArticulationDamping(axis, physics.articulationDamping)
            end
        end
    end
    
    -- Adjust center of mass based on load
    if physics.comStrength ~= nil then
        adjustCenterOfMass(vehicle, physics.comStrength)
    end
    
    -- Show physics info if enabled
    if physics.showPhysicsInfo then
        self:showPhysicsInfo(vehicle)
    end
end

-- =====================
-- DEBUG & INFO FUNCTIONS
-- =====================

---@param vehicle table
function VehiclePhysics:showPhysicsInfo(vehicle)
    if not isValidVehicle(vehicle) then
        return
    end
    
    local physics = g_RandomWorldEvents.physics
    if not physics or not physics.debugMode then
        return
    end
    
    -- Collect physics data
    local grip = safePhysicsMultiplier(physics.wheelGripMultiplier)
    local suspension = safePhysicsMultiplier(physics.suspensionStiffness)
    local comStrength = safePhysicsMultiplier(physics.comStrength)
    local damping = clampPhysicsValue(physics.articulationDamping or 0.5, 0.0, 1.0)
    
    -- Format vehicle info
    local vehicleName = vehicle.getName and vehicle:getName() or "Unknown Vehicle"
    local speed = vehicle.lastSpeedReal or 0
    local speedKmh = speed * 3.6
    
    -- Print detailed physics info
    print(string.format("[VehiclePhysics] %s - Speed: %.1f km/h", vehicleName, speedKmh))
    print(string.format("[VehiclePhysics]   Grip: %.2f, Suspension: %.2f, COM: %.2f, Damping: %.2f", 
        grip, suspension, comStrength, damping))
    
    -- Show wheel count if available
    if vehicle.wheels ~= nil then
        local wheelCount = 0
        for _ in pairs(vehicle.wheels) do
            wheelCount = wheelCount + 1
        end
        print(string.format("[VehiclePhysics]   Wheels: %d", wheelCount))
    end
    
    -- Show load information if available
    if vehicle.getFillUnits ~= nil then
        local totalFill = 0
        local capacity = 0
        local fillUnits = vehicle:getFillUnits()
        
        if fillUnits ~= nil then
            for _, unit in pairs(fillUnits) do
                if unit ~= nil then
                    totalFill = totalFill + (vehicle:getFillUnitFillLevel(unit) or 0)
                    capacity = capacity + (vehicle:getFillUnitCapacity(unit) or 0)
                end
            end
            
            if capacity > 0 then
                local loadPercentage = (totalFill / capacity) * 100
                print(string.format("[VehiclePhysics]   Load: %.1f/%.1f (%.1f%%)", 
                    totalFill, capacity, loadPercentage))
            end
        end
    end
end

-- =====================
-- UTILITY FUNCTIONS
-- =====================

---@return table
function VehiclePhysics:getPhysicsSettings()
    if g_RandomWorldEvents and g_RandomWorldEvents.physics then
        return {
            enabled = g_RandomWorldEvents.physics.enabled or false,
            wheelGripMultiplier = safePhysicsMultiplier(g_RandomWorldEvents.physics.wheelGripMultiplier),
            suspensionStiffness = safePhysicsMultiplier(g_RandomWorldEvents.physics.suspensionStiffness),
            articulationDamping = clampPhysicsValue(g_RandomWorldEvents.physics.articulationDamping or 0.5, 0.0, 1.0),
            comStrength = safePhysicsMultiplier(g_RandomWorldEvents.physics.comStrength),
            showPhysicsInfo = g_RandomWorldEvents.physics.showPhysicsInfo or false,
            debugMode = g_RandomWorldEvents.physics.debugMode or false
        }
    end
    
    return {
        enabled = false,
        wheelGripMultiplier = 1.0,
        suspensionStiffness = 1.0,
        articulationDamping = 0.5,
        comStrength = 1.0,
        showPhysicsInfo = false,
        debugMode = false
    }
end

---@param vehicle table
---@return boolean
function VehiclePhysics:isVehicleEligible(vehicle)
    if not isValidVehicle(vehicle) then
        return false
    end
    
    -- Check if vehicle has wheels (most vehicles should)
    if vehicle.wheels == nil then
        return false
    end
    
    -- Check if vehicle is active for physics
    if not vehicle:getIsActiveForPhysics() then
        return false
    end
    
    return true
end
