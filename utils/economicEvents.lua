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

local function getFarmMoney()
    local farmId = getFarmId()
    if farmId > 0 then
        local farm = g_farmManager:getFarmById(farmId)
        return farm and farm.money or 0
    end
    return 0
end

-- =====================
-- ECONOMIC EVENTS (15)
-- =====================
local economicEvents = {
    {name="government_subsidy", minI=1, func=function(intensity) 
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
    
    -- NEW EVENTS BELOW
    
    {name="tax_refund", minI=1, func=function(intensity) 
        local farmMoney = getFarmMoney()
        local refundAmount = math.min(farmMoney * 0.05 * intensity, 10000)
        if refundAmount > 100 then
            g_currentMission:addMoney(refundAmount, getFarmId(), MoneyType.OTHER, true)
            return string.format("Tax refund! +€%s", g_i18n:formatMoney(refundAmount, 0, true, true))
        end
        return "Small tax refund processed"
    end},
    
    {name="price_fixing", minI=2, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.priceFixing = 0.15 + 0.05 * intensity
        RandomWorldEvents.EVENT_STATE.priceFixingDuration = 15 * intensity  -- minutes
        return string.format("Price fixing scandal! Sell prices fixed at +%.0f%%", RandomWorldEvents.EVENT_STATE.priceFixing * 100)
    end},
    
    {name="loan_interest", minI=1, func=function(intensity) 
        local farmMoney = getFarmMoney()
        local interest = farmMoney * 0.02 * intensity
        if interest > 100 then
            g_currentMission:addMoney(-interest, getFarmId(), MoneyType.LOAN_INTEREST, true)
            return string.format("Loan interest due! -€%s", g_i18n:formatMoney(interest, 0, true, true))
        end
        return "Minimal loan interest charged"
    end},
    
    {name="export_opportunity", minI=3, func=function(intensity) 
        local bonus = 0.25 + 0.05 * intensity
        RandomWorldEvents.EVENT_STATE.exportBonus = bonus
        RandomWorldEvents.EVENT_STATE.exportDuration = 30 * intensity
        return string.format("Export opportunity! +%.0f%% on all exports", bonus * 100)
    end},
    
    {name="economic_crisis", minI=4, func=function(intensity) 
        -- Double negative effects for high intensity
        RandomWorldEvents.EVENT_STATE.economicCrisis = {
            marketMalus = 0.2 + 0.1 * intensity,
            loanPenalty = 0.05 * intensity,
            duration = 60 * intensity
        }
        return string.format("ECONOMIC CRISIS! Market -%.0f%%, loans +%.0f%%", 
            RandomWorldEvents.EVENT_STATE.economicCrisis.marketMalus * 100,
            RandomWorldEvents.EVENT_STATE.economicCrisis.loanPenalty * 100)
    end},
    
    {name="stock_market_windfall", minI=2, func=function(intensity) 
        local windfall = math.random(5000, 15000) * intensity
        g_currentMission:addMoney(windfall, getFarmId(), MoneyType.OTHER, true)
        return string.format("Stock market windfall! +€%s", g_i18n:formatMoney(windfall, 0, true, true))
    end},
    
    {name="trade_embargo", minI=3, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.tradeEmbargo = {
            importPenalty = 0.3 + 0.1 * intensity,
            duration = 45 * intensity
        }
        return string.format("Trade embargo! Import costs +%.0f%%", RandomWorldEvents.EVENT_STATE.tradeEmbargo.importPenalty * 100)
    end},
    
    {name="currency_devaluation", minI=2, func=function(intensity) 
        -- Makes exports cheaper (good) but imports expensive (bad)
        RandomWorldEvents.EVENT_STATE.currencyDeval = {
            exportBonus = 0.15 * intensity,
            importMalus = 0.10 * intensity,
            duration = 20 * intensity
        }
        return string.format("Currency devaluation! Exports +%.0f%%, Imports +%.0f%%", 
            RandomWorldEvents.EVENT_STATE.currencyDeval.exportBonus * 100,
            RandomWorldEvents.EVENT_STATE.currencyDeval.importMalus * 100)
    end},
    
    {name="government_grant", minI=1, func=function(intensity) 
        local grant = 7500 + intensity * 2500
        g_currentMission:addMoney(grant, getFarmId(), MoneyType.OTHER, true)
        return string.format("Government research grant! +€%s", g_i18n:formatMoney(grant, 0, true, true))
    end},
    
    {name="inflation_spike", minI=3, func=function(intensity) 
        RandomWorldEvents.EVENT_STATE.inflation = {
            purchaseCostIncrease = 0.2 + 0.05 * intensity,
            duration = 25 * intensity
        }
        return string.format("Inflation spike! Purchase costs +%.0f%%", RandomWorldEvents.EVENT_STATE.inflation.purchaseCostIncrease * 100)
    end}
}

-- =====================
-- REGISTER ECONOMIC EVENTS
-- =====================
for _, e in pairs(economicEvents) do
    g_RandomWorldEvents:registerEvent({
        name = e.name,
        category = "economic",
        weight = 1,
        duration = {min = 15, max = 60},
        minIntensity = e.minI,
        canTrigger = function() return g_currentMission ~= nil end,
        onStart = e.func,
        onEnd = function()
            -- Clear all economic event states
            RandomWorldEvents.EVENT_STATE.marketBonus = nil
            RandomWorldEvents.EVENT_STATE.marketMalus = nil
            RandomWorldEvents.EVENT_STATE.seedDiscount = nil
            RandomWorldEvents.EVENT_STATE.fertilizerDiscount = nil
            RandomWorldEvents.EVENT_STATE.fuelDiscount = nil
            RandomWorldEvents.EVENT_STATE.equipmentDiscount = nil
            RandomWorldEvents.EVENT_STATE.priceFixing = nil
            RandomWorldEvents.EVENT_STATE.exportBonus = nil
            RandomWorldEvents.EVENT_STATE.economicCrisis = nil
            RandomWorldEvents.EVENT_STATE.tradeEmbargo = nil
            RandomWorldEvents.EVENT_STATE.currencyDeval = nil
            RandomWorldEvents.EVENT_STATE.inflation = nil
            return "Economic event ended"
        end
    })
end

-- =====================
-- ECONOMIC UPDATE SYSTEM
-- =====================
RandomWorldEvents.originalEconomicUpdate = RandomWorldEvents.originalEconomicUpdate or RandomWorldEvents.update

function RandomWorldEvents:updateEconomicEffects(dt)
    -- Apply ongoing economic effects
    local eventState = self.EVENT_STATE
    
    -- Apply price fixing effect (increases sell prices)
    if eventState.priceFixing then
        -- This would need to integrate with the game's price system
        -- For now, it's just a notification effect
        if g_currentMission.time % 30000 < 100 then  -- Every 30 seconds
            print(string.format("[EconomicEvent] Price fixing active: +%.0f%% sell prices", 
                eventState.priceFixing * 100))
        end
    end
    
    -- Apply export bonus
    if eventState.exportBonus then
        if g_currentMission.time % 30000 < 100 then
            print(string.format("[EconomicEvent] Export bonus active: +%.0f%% on exports", 
                eventState.exportBonus * 100))
        end
    end
    
    -- Apply economic crisis effects
    if eventState.economicCrisis then
        if g_currentMission.time % 45000 < 100 then  -- Every 45 seconds
            print(string.format("[EconomicEvent] Economic crisis: Market -%.0f%%, Loans +%.0f%%", 
                eventState.economicCrisis.marketMalus * 100,
                eventState.economicCrisis.loanPenalty * 100))
        end
    end
    
    -- Apply trade embargo
    if eventState.tradeEmbargo then
        if g_currentMission.time % 35000 < 100 then
            print(string.format("[EconomicEvent] Trade embargo: Import costs +%.0f%%", 
                eventState.tradeEmbargo.importPenalty * 100))
        end
    end
    
    -- Apply currency devaluation
    if eventState.currencyDeval then
        if g_currentMission.time % 25000 < 100 then
            print(string.format("[EconomicEvent] Currency devalued: Exports +%.0f%%, Imports +%.0f%%", 
                eventState.currencyDeval.exportBonus * 100,
                eventState.currencyDeval.importMalus * 100))
        end
    end
    
    -- Apply inflation
    if eventState.inflation then
        if g_currentMission.time % 20000 < 100 then
            print(string.format("[EconomicEvent] Inflation: Purchase costs +%.0f%%", 
                eventState.inflation.purchaseCostIncrease * 100))
        end
    end
end

-- Integrate with main update
RandomWorldEvents.originalUpdate = RandomWorldEvents.originalUpdate or RandomWorldEvents.update

function RandomWorldEvents:update(dt)
    self:originalUpdate(dt)
    self:updateEconomicEffects(dt)
end

print("[EconomicEvents] Loaded 20 advanced economic events")
print("[EconomicEvents] Features: Tax system, market manipulation, trade effects, inflation, economic crises")
