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
---@class PhysicsUtils
PhysicsUtils = {
    TERRAIN_CURVES = {
        asphalt = { grip = 1.1 },
        dirt    = { grip = 0.95 },
        field   = { grip = 0.85 },
        grass   = { grip = 0.9 },
        snow    = { grip = 0.7 }
    }
}

function PhysicsUtils:log(msg, level)
    level = level or 1
    local debugLevel = g_RandomWorldEvents.physics.debugMode and 2 or 0
    if debugLevel >= level then
        print("[PhysicsUtils] " .. tostring(msg))
    end
end

function PhysicsUtils:clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

function PhysicsUtils:lerp(a, b, t)
    return a + (b - a) * t
end

function PhysicsUtils:formatNumber(value, decimals)
    decimals = decimals or 2
    return string.format("%." .. decimals .. "f", value)
end

function PhysicsUtils:getTerrainGrip(terrainType)
    local curve = self.TERRAIN_CURVES[terrainType]
    return curve and curve.grip or 1.0
end

function PhysicsUtils:applyTerrainResponse(vehicle)
    if not vehicle or not vehicle.wheels then 
        return 
    end
    
    local physics = g_RandomWorldEvents.physics
    if not physics.enabled then return end
    
    for _, wheel in pairs(vehicle.wheels) do
        if wheel.contact ~= nil and wheel.physics ~= nil then
            local terrain = wheel.contact.groundTypeName
            local terrainGrip = self:getTerrainGrip(terrain)
            local baseGrip = physics.wheelGripMultiplier or 1.0
            wheel.physics.frictionScale = baseGrip * terrainGrip
            
            if physics.debugMode then
                self:log(string.format("Wheel %d: Terrain=%s, Grip=%.2f", 
                    wheel.wheelIndex or 0, terrain or "unknown", wheel.physics.frictionScale))
            end
        end
    end
end

function PhysicsUtils:applyAdvancedPhysics(vehicle)
    if not vehicle or vehicle.getIsActiveForPhysics == nil then 
        return 
    end
    
    if not vehicle:getIsActiveForPhysics() then
        return
    end
    
    local physics = g_RandomWorldEvents.physics
    if not physics.enabled then return end
    
    self:applyTerrainResponse(vehicle)
    
    if vehicle.wheels and physics.suspensionStiffness then
        for _, wheel in pairs(vehicle.wheels) do
            if wheel.suspension ~= nil then
                local originalForce = wheel.suspension.originalSpringForce or wheel.suspension.springForce
                wheel.suspension.originalSpringForce = originalForce
                wheel.suspension.springForce = originalForce * physics.suspensionStiffness
            end
        end
    end
    
    if vehicle.articulatedAxis and physics.articulationDamping then
        for _, axis in pairs(vehicle.articulatedAxis) do
            if axis.jointNode then
                local dampingFactor = physics.articulationDamping
                local rx, ry, rz = getRotation(axis.jointNode)
                setRotation(
                    axis.jointNode,
                    rx * (1 - dampingFactor * 0.1),
                    ry,
                    rz * (1 - dampingFactor * 0.1)
                )
            end
        end
    end
    
    if vehicle.massNode and vehicle.getFillUnits ~= nil and physics.comStrength then
        local totalFill = 0
        local capacity = 0
        
        for _, unit in pairs(vehicle:getFillUnits()) do
            totalFill = totalFill + vehicle:getFillUnitFillLevel(unit)
            capacity = capacity + vehicle:getFillUnitCapacity(unit)
        end
        
        if capacity > 0 then
            local loadFactor = totalFill / capacity
            local strength = physics.comStrength * loadFactor
            
            local x, y, z = getTranslation(vehicle.massNode)
            setTranslation(vehicle.massNode, x, y - strength * 0.15, z)
            
            if physics.debugMode then
                self:log(string.format("COM: Load=%.1f/%.1f, Factor=%.2f, Strength=%.2f", 
                    totalFill, capacity, loadFactor, strength))
            end
        end
    end
    
    if physics.showPhysicsInfo then
        self:showPhysicsInfo(vehicle)
    end
end

function PhysicsUtils:showPhysicsInfo(vehicle)
    if not vehicle then return end
    
    local physics = g_RandomWorldEvents.physics
    
    local info = string.format(
        "Physics Info:\n" ..
        "Grip: %.2f\n" ..
        "Suspension: %.2f\n" ..
        "COM Strength: %.2f\n" ..
        "Damping: %.2f",
        physics.wheelGripMultiplier or 1.0,
        physics.suspensionStiffness or 1.0,
        physics.comStrength or 1.0,
        physics.articulationDamping or 0.5
    )
    
    if g_currentMission.addHelpText then
        g_currentMission:addHelpText(info)
    end
end

RandomWorldEvents.originalUpdatePhysics = RandomWorldEvents.originalUpdatePhysics or RandomWorldEvents.updatePhysics
function RandomWorldEvents:updatePhysics(vehicle)
    PhysicsUtils:applyAdvancedPhysics(vehicle)
end

print("[PhysicsUtils] Physics system loaded with terrain response")