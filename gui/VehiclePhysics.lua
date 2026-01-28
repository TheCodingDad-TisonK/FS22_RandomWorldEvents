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
VehiclePhysics = {}

function VehiclePhysics:update(vehicle)
    if vehicle == nil then
        return
    end

    if vehicle.getIsActiveForPhysics == nil then
        return
    end

    if not vehicle:getIsActiveForPhysics() then
        return
    end

    local physics = g_RandomWorldEvents.physics
    if not physics or not physics.enabled then
        return
    end

    if vehicle.wheels and physics.wheelGripMultiplier then
        for _, wheel in pairs(vehicle.wheels) do
            if wheel.physics ~= nil then
                wheel.physics.frictionScale = physics.wheelGripMultiplier
            end
        end
    end

    if vehicle.wheels and physics.suspensionStiffness then
        for _, wheel in pairs(vehicle.wheels) do
            if wheel.suspension ~= nil then
                wheel.suspension.springForce = wheel.suspension.springForce * physics.suspensionStiffness
            end
        end
    end

    if vehicle.articulatedAxis and physics.articulationDamping then
        for _, axis in pairs(vehicle.articulatedAxis) do
            if axis.jointNode then
                local rx, ry, rz = getRotation(axis.jointNode)
                setRotation(
                    axis.jointNode,
                    rx * (1 - physics.articulationDamping * 0.1),
                    ry,
                    rz * (1 - physics.articulationDamping * 0.1)
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
        end
    end

    if physics.showPhysicsInfo then
        self:showPhysicsInfo(vehicle)
    end
end


function VehiclePhysics:showPhysicsInfo(vehicle)
    if g_RandomWorldEvents.physics.debugMode then
        print(string.format("Vehicle Physics: Grip=%.2f, Suspension=%.2f, COM=%.2f", 
            g_RandomWorldEvents.physics.wheelGripMultiplier or 1.0,
            g_RandomWorldEvents.physics.suspensionStiffness or 1.0,
            g_RandomWorldEvents.physics.comStrength or 1.0
        ))
    end
end