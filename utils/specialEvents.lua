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
}

for _, e in pairs(specialEvents) do
    eventId = eventId + 1
    RandomWorldEvents.EVENTS[e.name] = {
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
            return "Special event ended"
        end
    }
end

print("[SpecialEvents] 10 special events loaded")