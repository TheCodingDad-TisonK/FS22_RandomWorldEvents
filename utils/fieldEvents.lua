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
local fieldEvents = {
    {name="crop_yield_bonus", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.yieldBonus = 0.05 * intensity 
        return string.format("Crop yield +%.0f%%!", RandomWorldEvents.EVENT_STATE.yieldBonus * 100) 
    end},
    
    {name="crop_yield_penalty", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.yieldMalus = 0.05 * intensity 
        return string.format("Crop yield -%.0f%%!", RandomWorldEvents.EVENT_STATE.yieldMalus * 100) 
    end},
    
    {name="fertilizer_bonus", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.fertilizerBonus = true 
        return "Fertilizer effect doubled!" 
    end},
    
    {name="fertilizer_penalty", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.fertilizerMalus = true 
        return "Fertilizer effect halved!" 
    end},
    
    {name="seed_growth_bonus", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.seedBonus = true 
        return "Seeds grow faster!" 
    end},
    
    {name="seed_growth_penalty", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.seedMalus = true 
        return "Seeds grow slower!" 
    end},
    
    {name="harvest_bonus", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.harvestBonus = true 
        return "Harvest increased!" 
    end},
    
    {name="harvest_penalty", minI=1, func=function() 
        RandomWorldEvents.EVENT_STATE.harvestMalus = true 
        return "Harvest reduced!" 
    end},
    
    {name="field_sale_bonus", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.fieldSaleBonus = 0.05 * intensity 
        return "Field sales increased!" 
    end},
    
    {name="field_sale_penalty", minI=1, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.fieldSaleMalus = 0.05 * intensity 
        return "Field sales decreased!" 
    end},
}

for _, e in pairs(fieldEvents) do
    eventId = eventId + 1
    RandomWorldEvents.EVENTS[e.name] = {
        name = e.name,
        category = "field",
        weight = 1,
        duration = {min = 30, max = 120},
        minIntensity = e.minI,
        canTrigger = function() 
            return g_currentMission ~= nil and 
                   g_currentMission.fieldController ~= nil and 
                   #g_currentMission.fieldController.fields > 0 
        end,
        onStart = e.func,
        onEnd = function()
            RandomWorldEvents.EVENT_STATE.yieldBonus = nil
            RandomWorldEvents.EVENT_STATE.yieldMalus = nil
            RandomWorldEvents.EVENT_STATE.fertilizerBonus = nil
            RandomWorldEvents.EVENT_STATE.fertilizerMalus = nil
            RandomWorldEvents.EVENT_STATE.seedBonus = nil
            RandomWorldEvents.EVENT_STATE.seedMalus = nil
            RandomWorldEvents.EVENT_STATE.harvestBonus = nil
            RandomWorldEvents.EVENT_STATE.harvestMalus = nil
            RandomWorldEvents.EVENT_STATE.fieldSaleBonus = nil
            RandomWorldEvents.EVENT_STATE.fieldSaleMalus = nil
            return "Field event ended"
        end
    }
end

print("[FieldEvents] 10 field events loaded")