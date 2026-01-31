-- =========================================================
-- Random World Events (version 1.3.0.5)
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
local specialEvents = {
    {name="time_acceleration", minI=1, func=function(intensity) 
        if not RandomWorldEvents.EVENT_STATE.originalTimeScale then 
            RandomWorldEvents.EVENT_STATE.originalTimeScale = g_currentMission.missionInfo.timeScale 
        end 
        g_currentMission.missionInfo.timeScale = RandomWorldEvents.EVENT_STATE.originalTimeScale * (5 * intensity) 
        return "TIME ACCELERATION!" 
    end},
    
    {name="time_slowdown", minI=1, func=function(intensity) 
        if not RandomWorldEvents.EVENT_STATE.originalTimeScale then 
            RandomWorldEvents.EVENT_STATE.originalTimeScale = g_currentMission.missionInfo.timeScale 
        end 
        g_currentMission.missionInfo.timeScale = RandomWorldEvents.EVENT_STATE.originalTimeScale / (2 * intensity) 
        return "TIME SLOWDOWN!" 
    end},
    
    {name="bonus_xp", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.xpBonus = 0.1 * intensity 
        return "XP gain increased!" 
    end},
    
    {name="malus_xp", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.xpMalus = 0.1 * intensity 
        return "XP gain decreased!" 
    end},
    
    {name="money_bonus", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.moneyBonus = 0.1 * intensity 
        return "Money gain increased!" 
    end},
    
    {name="money_malus", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.moneyMalus = 0.1 * intensity 
        return "Money gain decreased!" 
    end},
    
    {name="special_event_festival", minI=1, func=function() 
        return "Festival in town!" 
    end},
    
    {name="equipment_durability_boost", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.durabilityBoost = true 
        return "Equipment durability increased!" 
    end},
    
    {name="equipment_durability_drop", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.durabilityMalus = true 
        return "Equipment durability decreased!" 
    end},
    
    {name="bonus_trade_prices", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.tradeBonus = true 
        return "Better trade prices!" 
    end},
    
    -- 10 NEW SPECIAL EVENTS
    
    {name="animal_productivity_surge", minI=1, func=function(intensity)
        RandomWorldEvents.EVENT_STATE.animalProductivity = 0.25 + 0.10 * intensity
        RandomWorldEvents.EVENT_STATE.animalProductivityDuration = 45 * intensity
        return string.format("Animal productivity surge! +%.0f%% milk/eggs/wool", RandomWorldEvents.EVENT_STATE.animalProductivity * 100)
    end},
    
    {name="supernatural_harvest", minI=2, func=function(intensity)
        local bonus = math.random(10000, 25000) * intensity
        g_currentMission:addMoney(bonus, getFarmId(), MoneyType.OTHER, true)
        RandomWorldEvents.EVENT_STATE.supernaturalGrowth = true
        RandomWorldEvents.EVENT_STATE.supernaturalDuration = 20 * intensity
        return string.format("Supernatural harvest! Mysterious bounty of €%s", g_i18n:formatMoney(bonus, 0, true, true))
    end},
    
    {name="alien_technology", minI=3, func=function(intensity)
        RandomWorldEvents.EVENT_STATE.alienTech = {
            speedBoost = 0.50 + 0.25 * intensity,
            fuelEfficiency = 0.75,
            duration = 30 * intensity
        }
        return string.format("Alien technology discovered! Equipment speed +%.0f%%, Fuel efficiency +%.0f%%",
            RandomWorldEvents.EVENT_STATE.alienTech.speedBoost * 100,
            RandomWorldEvents.EVENT_STATE.alienTech.fuelEfficiency * 100)
    end},
    
    {name="time_portal", minI=4, func=function(intensity)
        -- Jump forward or backward in time
        local timeJump = math.random(-12, 12) * 60 * 60 * 1000 * intensity -- +/- up to 12 hours
        g_currentMission.environment.dayTime = g_currentMission.environment.dayTime + timeJump
        
        if timeJump > 0 then
            return string.format("TIME PORTAL! Jumped forward %.1f hours", timeJump / (60 * 60 * 1000))
        else
            return string.format("TIME PORTAL! Jumped back %.1f hours", math.abs(timeJump) / (60 * 60 * 1000))
        end
    end},
    
    {name="dimensional_rift", minI=3, func=function(intensity)
        -- Random teleportation of vehicles/equipment
        RandomWorldEvents.EVENT_STATE.dimensionalRift = true
        RandomWorldEvents.EVENT_STATE.dimensionalRiftIntensity = intensity
        RandomWorldEvents.EVENT_STATE.dimensionalRiftDuration = 15 * intensity
        return "DIMENSIONAL RIFT! Equipment may teleport randomly!"
    end},
    
    {name="mythical_creature_sighting", minI=1, func=function(intensity)
        RandomWorldEvents.EVENT_STATE.mythicalCreature = {
            type = math.random(1, 4), -- 1: Unicorn, 2: Dragon, 3: Phoenix, 4: Yeti
            luckBonus = 0.20 + 0.10 * intensity,
            duration = 25 * intensity
        }
        local creatureNames = {"Unicorn", "Dragon", "Phoenix", "Yeti"}
        return string.format("MYTHICAL SIGHTING! %s appears bringing +%.0f%% luck!",
            creatureNames[RandomWorldEvents.EVENT_STATE.mythicalCreature.type],
            RandomWorldEvents.EVENT_STATE.mythicalCreature.luckBonus * 100)
    end},
    
    {name="parallel_farm_merge", minI=2, func=function(intensity)
        local parallelBonus = math.random(15000, 35000) * intensity
        g_currentMission:addMoney(parallelBonus, getFarmId(), MoneyType.OTHER, true)
        RandomWorldEvents.EVENT_STATE.parallelResources = 0.15 * intensity
        RandomWorldEvents.EVENT_STATE.parallelDuration = 35 * intensity
        return string.format("PARALLEL FARM MERGE! +€%s and +%.0f%% resources from alternate reality",
            g_i18n:formatMoney(parallelBonus, 0, true, true),
            RandomWorldEvents.EVENT_STATE.parallelResources * 100)
    end},
    
    {name="weather_control_device", minI=3, func=function(intensity)
        RandomWorldEvents.EVENT_STATE.weatherControl = {
            sunnyDays = 3 * intensity,
            rainWhenNeeded = true,
            noStorms = true,
            duration = 60 * intensity
        }
        return string.format("WEATHER CONTROL DEVICE! Perfect weather for %d days", 3 * intensity)
    end},
    
    {name="quantum_entangled_crops", minI=2, func=function(intensity)
        RandomWorldEvents.EVENT_STATE.quantumCrops = {
            growthSpeed = 2.0 + 1.0 * intensity,
            yieldMultiplier = 1.5 + 0.5 * intensity,
            randomMutation = true,
            duration = 40 * intensity
        }
        return string.format("QUANTUM ENTANGLED CROPS! Growth ×%.1f, Yield ×%.1f",
            RandomWorldEvents.EVENT_STATE.quantumCrops.growthSpeed,
            RandomWorldEvents.EVENT_STATE.quantumCrops.yieldMultiplier)
    end},
    
    {name="reality_glitch", minI=1, func=function(intensity)
        -- Various random glitches
        RandomWorldEvents.EVENT_STATE.realityGlitch = {
            floatingObjects = true,
            colorInversion = intensity >= 2,
            gravityFluctuations = intensity >= 3,
            soundDistortion = true,
            duration = 10 * intensity
        }
        return "REALITY GLITCH! Strange phenomena occurring..."
    end}
}

for _, e in pairs(specialEvents) do
    g_RandomWorldEvents:registerEvent({
        name = e.name,
        category = "special",
        weight = 1,
        duration = {min = 10, max = 60},
        minIntensity = e.minI,
        canTrigger = function() return g_currentMission ~= nil end,
        onStart = e.func,
        onEnd = function()
            if RandomWorldEvents.EVENT_STATE.originalTimeScale then
                g_currentMission.missionInfo.timeScale = RandomWorldEvents.EVENT_STATE.originalTimeScale
                RandomWorldEvents.EVENT_STATE.originalTimeScale = nil
            end
            
            RandomWorldEvents.EVENT_STATE.xpBonus = nil
            RandomWorldEvents.EVENT_STATE.xpMalus = nil
            RandomWorldEvents.EVENT_STATE.moneyBonus = nil
            RandomWorldEvents.EVENT_STATE.moneyMalus = nil
            RandomWorldEvents.EVENT_STATE.durabilityBoost = nil
            RandomWorldEvents.EVENT_STATE.durabilityMalus = nil
            RandomWorldEvents.EVENT_STATE.tradeBonus = nil
            RandomWorldEvents.EVENT_STATE.animalProductivity = nil
            RandomWorldEvents.EVENT_STATE.supernaturalGrowth = nil
            RandomWorldEvents.EVENT_STATE.alienTech = nil
            RandomWorldEvents.EVENT_STATE.dimensionalRift = nil
            RandomWorldEvents.EVENT_STATE.mythicalCreature = nil
            RandomWorldEvents.EVENT_STATE.parallelResources = nil
            RandomWorldEvents.EVENT_STATE.weatherControl = nil
            RandomWorldEvents.EVENT_STATE.quantumCrops = nil
            RandomWorldEvents.EVENT_STATE.realityGlitch = nil
            return "Special event ended"
        end
    })
end

print("[SpecialEvents] Loaded 20 special events")
