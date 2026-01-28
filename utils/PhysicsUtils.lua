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

---@class PhysicsUtils
PhysicsUtils = {
    TERRAIN_CURVES = {
        asphalt = { grip = 1.1 },
        dirt    = { grip = 0.95 },
        field   = { grip = 0.85 },
        grass   = { grip = 0.9 },
        snow    = { grip = 0.7 },
        default = { grip = 1.0 }
    },
    
    -- Constants
    DAMPING_MULTIPLIER = 0.1,
    COM_ADJUSTMENT = 0.15,
    DEFAULT_GRIP = 1.0
}

-- Cache frequently used functions
local getRotation, setRotation, getTranslation, setTranslation = getRotation, setRotation, getTranslation, setTranslation

-- =====================
-- UTILITY FUNCTIONS
-- =====================

---@param msg string
---@param level? number
function PhysicsUtils:log(msg, level)
    if not g_RandomWorldEvents or not g_RandomWorldEvents.physics then
        return
    end
    
    level = level or 1
    local debugLevel = g_RandomWorldEvents.physics.debugMode and 2 or 0
    
    if debugLevel >= level then
        print("[PhysicsUtils] " .. tostring(msg))
    end
end

---@param value number
---@param min number
---@param max number
---@return number
function PhysicsUtils:clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

---@param a number
---@param b number
---@param t number
---@return number
function PhysicsUtils:lerp(a, b, t)
    return a + (b - a) * self:clamp(t, 0.0, 1.0)
end

---@param value number
---@param decimals? integer
---@return string
function PhysicsUtils:formatNumber(value, decimals)
    decimals = decimals or 2
    return string.format("%." .. tostring(decimals) .. "f", value or 0)
end

---@param terrainType string
---@return number
function PhysicsUtils:getTerrainGrip(terrainType)
    local curve = self.TERRAIN_CURVES[terrainType] or self.TERRAIN_CURVES.default
    return curve.grip
end

-- =====================
-- VEHICLE VALIDATION
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

-- =====================
-- TERRAIN RESPONSE SYSTEM
-- =====================

---@param vehicle table
function PhysicsUtils:applyTerrainResponse(vehicle)
    if not isValidVehicle(vehicle) or not vehicle.wheels then 
        return 
    end
    
    local physics = g_RandomWorldEvents.physics
    if not isPhysicsEnabled(physics) then 
        return 
    end
    
    for wheelIndex, wheel in pairs(vehicle.wheels) do
        if wheel ~= nil and wheel.contact ~= nil and wheel.physics ~= nil then
            local terrain = wheel.contact.groundTypeName or "default"
            local terrainGrip = self:getTerrainGrip(terrain)
            local baseGrip = physics.wheelGripMultiplier or self.DEFAULT_GRIP
            
            -- Apply combined grip
            wheel.physics.frictionScale = baseGrip * terrainGrip
            
            -- Debug logging
            if physics.debugMode then
                self:log(string.format("Wheel %d: Terrain=%s, CombinedGrip=%.2f (Base=%.2f × Terrain=%.2f)", 
                    wheelIndex, terrain, wheel.physics.frictionScale, baseGrip, terrainGrip))
            end
        end
    end
end

-- =====================
-- SUSPENSION SYSTEM
-- =====================

---@param vehicle table
---@param stiffnessMultiplier number
local function applySuspensionAdjustments(vehicle, stiffnessMultiplier)
    if not vehicle.wheels then return end
    
    for _, wheel in pairs(vehicle.wheels) do
        if wheel ~= nil and wheel.suspension ~= nil then
            -- Store original value if not already stored
            if not wheel.suspension.originalSpringForce then
                wheel.suspension.originalSpringForce = wheel.suspension.springForce
            end
            
            -- Apply stiffness multiplier
            wheel.suspension.springForce = wheel.suspension.originalSpringForce * stiffnessMultiplier
        end
    end
end

-- =====================
-- ARTICULATION SYSTEM
-- =====================

---@param vehicle table
---@param dampingFactor number
local function applyArticulationDamping(vehicle, dampingFactor)
    if not vehicle.articulatedAxis then return end
    
    for _, axis in pairs(vehicle.articulatedAxis) do
        if axis ~= nil and axis.jointNode ~= nil then
            local rx, ry, rz = getRotation(axis.jointNode)
            local dampedMultiplier = 1 - (dampingFactor * PhysicsUtils.DAMPING_MULTIPLIER)
            
            setRotation(
                axis.jointNode,
                rx * dampedMultiplier,
                ry,
                rz * dampedMultiplier
            )
        end
    end
end

-- =====================
-- CENTER OF MASS SYSTEM
-- =====================

---@param vehicle table
---@param comStrength number
---@return number loadFactor
local function adjustCenterOfMass(vehicle, comStrength)
    if vehicle.massNode == nil or vehicle.getFillUnits == nil then
        return 0
    end
    
    local totalFill = 0
    local capacity = 0
    
    -- Calculate total load
    local fillUnits = vehicle:getFillUnits()
    if fillUnits ~= nil then
        for _, unit in pairs(fillUnits) do
            if unit ~= nil then
                totalFill = totalFill + (vehicle:getFillUnitFillLevel(unit) or 0)
                capacity = capacity + (vehicle:getFillUnitCapacity(unit) or 0)
            end
        end
    end
    
    -- Adjust center of mass based on load
    if capacity > 0 then
        local loadFactor = totalFill / capacity
        local strength = comStrength * loadFactor
        local verticalAdjustment = strength * PhysicsUtils.COM_ADJUSTMENT
        
        local x, y, z = getTranslation(vehicle.massNode)
        setTranslation(vehicle.massNode, x, y - verticalAdjustment, z)
        
        return loadFactor
    end
    
    return 0
end

-- =====================
-- MAIN PHYSICS APPLIER
-- =====================

---@param vehicle table
function PhysicsUtils:applyAdvancedPhysics(vehicle)
    -- Validate vehicle
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
    
    -- Apply terrain-based grip
    self:applyTerrainResponse(vehicle)
    
    -- Apply suspension stiffness
    if physics.suspensionStiffness then
        applySuspensionAdjustments(vehicle, physics.suspensionStiffness)
    end
    
    -- Apply articulation damping
    if physics.articulationDamping then
        applyArticulationDamping(vehicle, physics.articulationDamping)
    end
    
    -- Adjust center of mass
    if physics.comStrength then
        local loadFactor = adjustCenterOfMass(vehicle, physics.comStrength)
        
        -- Debug logging for COM adjustments
        if physics.debugMode and loadFactor > 0 then
            self:log(string.format("COM: Strength=%.2f, LoadFactor=%.2f, VerticalAdj=%.3f", 
                physics.comStrength, loadFactor, physics.comStrength * loadFactor * self.COM_ADJUSTMENT))
        end
    end
    
    -- Show physics info if enabled
    if physics.showPhysicsInfo then
        self:showPhysicsInfo(vehicle)
    end
end

-- =====================
-- DEBUG INFO DISPLAY
-- =====================

---@param vehicle table
function PhysicsUtils:showPhysicsInfo(vehicle)
    if not isValidVehicle(vehicle) then 
        return 
    end
    
    local physics = g_RandomWorldEvents.physics
    if not physics then return end
    
    -- Get vehicle info
    local vehicleName = vehicle.getName and vehicle:getName() or "Vehicle"
    local speed = vehicle.lastSpeedReal or 0
    local speedKmh = speed * 3.6
    
    -- Prepare detailed info
    local info = string.format(
        "Physics Info - %s (%.1f km/h):\n" ..
        "Grip: %.2f\n" ..
        "Suspension: %.2f\n" ..
        "COM Strength: %.2f\n" ..
        "Damping: %.2f",
        vehicleName,
        speedKmh,
        physics.wheelGripMultiplier or 1.0,
        physics.suspensionStiffness or 1.0,
        physics.comStrength or 1.0,
        physics.articulationDamping or 0.5
    )
    
    -- Add terrain info if available
    if vehicle.wheels then
        local wheelCount = 0
        local avgGrip = 0
        
        for _, wheel in pairs(vehicle.wheels) do
            if wheel ~= nil and wheel.physics ~= nil then
                wheelCount = wheelCount + 1
                avgGrip = avgGrip + (wheel.physics.frictionScale or 1.0)
            end
        end
        
        if wheelCount > 0 then
            avgGrip = avgGrip / wheelCount
            info = info .. string.format("\nWheels: %d, Avg Grip: %.2f", wheelCount, avgGrip)
        end
    end
    
    -- Display info
    if g_currentMission and g_currentMission.addHelpText then
        g_currentMission:addHelpText(info)
    elseif physics.debugMode then
        print(info)
    end
end

-- =====================
-- INTEGRATION WITH MAIN MOD
-- =====================

RandomWorldEvents.originalUpdatePhysics = RandomWorldEvents.originalUpdatePhysics or RandomWorldEvents.updatePhysics

---@param vehicle table
function RandomWorldEvents:updatePhysics(vehicle)
    PhysicsUtils:applyAdvancedPhysics(vehicle)
end
