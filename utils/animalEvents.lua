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
local animalEvents = {
    {name="animal_health_boost", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.animalHealthBonus = 0.05 * intensity 
        return "Animals are healthier!" 
    end},
    
    {name="animal_health_penalty", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.animalHealthMalus = 0.05 * intensity 
        return "Animals are weaker!" 
    end},
    
    {name="animal_feed_bonus", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.feedBonus = true 
        return "Animals require less feed!" 
    end},
    
    {name="animal_feed_penalty", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.feedMalus = true 
        return "Animals require more feed!" 
    end},
    
    {name="milk_yield_bonus", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.milkBonus = true 
        return "Milk production increased!" 
    end},
    
    {name="milk_yield_penalty", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.milkMalus = true 
        return "Milk production decreased!" 
    end},
    
    {name="egg_yield_bonus", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.eggBonus = true 
        return "Egg production increased!" 
    end},
    
    {name="egg_yield_penalty", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.eggMalus = true 
        return "Egg production decreased!" 
    end},
    
    {name="livestock_sale_bonus", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.livestockSaleBonus = true 
        return "Livestock sales higher!" 
    end},
    
    {name="livestock_sale_penalty", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.livestockSaleMalus = true 
        return "Livestock sales lower!" 
    end},
}

for _, e in pairs(animalEvents) do
    eventId = eventId + 1
    RandomWorldEvents.EVENTS[e.name] = {
        name = e.name,
        category = "wildlife",
        weight = 1,
        duration = {min = 30, max = 120},
        minIntensity = e.minI,
        canTrigger = function() 
            return g_currentMission ~= nil and g_currentMission.animalSystem ~= nil 
        end,
        onStart = e.func,
        onEnd = function()
            RandomWorldEvents.EVENT_STATE.animalHealthBonus = nil
            RandomWorldEvents.EVENT_STATE.animalHealthMalus = nil
            RandomWorldEvents.EVENT_STATE.feedBonus = nil
            RandomWorldEvents.EVENT_STATE.feedMalus = nil
            RandomWorldEvents.EVENT_STATE.milkBonus = nil
            RandomWorldEvents.EVENT_STATE.milkMalus = nil
            RandomWorldEvents.EVENT_STATE.eggBonus = nil
            RandomWorldEvents.EVENT_STATE.eggMalus = nil
            RandomWorldEvents.EVENT_STATE.livestockSaleBonus = nil
            RandomWorldEvents.EVENT_STATE.livestockSaleMalus = nil
            return "Animal event ended"
        end
    }
end

print("[AnimalEvents] 10 animal events loaded")
