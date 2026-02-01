-- =========================================================
-- Logistics System
-- =========================================================
-- Manages supply chains, deliveries, and inventory
-- =========================================================

---@class LogisticsSystem
LogisticsSystem = {}

function LogisticsSystem:initialize()
    self.deliveryVehicles = {}
    self.deliveryRoutes = {}
    self.inventoryLevels = {}
    self.orderHistory = {}
end

function LogisticsSystem:createSupplyChain(name, inputs, outputs, efficiency)
    local chain = {
        id = "chain_" .. string.format("%08x", math.random(0x10000000, 0xffffffff)),
        name = name,
        inputs = inputs or {},
        outputs = outputs or {},
        efficiency = efficiency or 0.85,
        status = "active",
        createdAt = g_currentMission.time
    }
    
    table.insert(g_AdvancedFarmLogistics.logistics.supplyChains, chain)
    return chain.id
end

function LogisticsSystem:scheduleDelivery(product, quantity, destination, priority)
    local delivery = {
        id = "delivery_" .. string.format("%08x", math.random(0x10000000, 0xffffffff)),
        product = product,
        quantity = quantity,
        destination = destination,
        priority = priority or "normal",
        status = "scheduled",
        scheduledTime = g_currentMission.time,
        estimatedDelivery = g_currentMission.time + (2 * 60 * 60 * 1000) -- 2 hours default
    }
    
    table.insert(g_AdvancedFarmLogistics.logistics.activeDeliveries, delivery)
    
    if g_AdvancedFarmLogistics.settings.showNotifications then
        g_currentMission:addIngameNotification(
            FSBaseMission.INGAME_NOTIFICATION_INFO,
            string.format("Delivery Scheduled: %d %s to %s", quantity, product, destination)
        )
    end
    
    return delivery.id
end

function LogisticsSystem:updateDeliveries(dt)
    for i = #g_AdvancedFarmLogistics.logistics.activeDeliveries, 1, -1 do
        local delivery = g_AdvancedFarmLogistics.logistics.activeDeliveries[i]
        
        if delivery.status == "in_transit" then
            -- Simulate delivery progress
            if g_currentMission.time >= delivery.estimatedDelivery then
                delivery.status = "delivered"
                self:completeDelivery(delivery)
                table.remove(g_AdvancedFarmLogistics.logistics.activeDeliveries, i)
            end
            
        elseif delivery.status == "scheduled" then
            -- Start delivery after short delay
            if g_currentMission.time >= delivery.scheduledTime + (5 * 60 * 1000) then
                delivery.status = "in_transit"
                
                if g_AdvancedFarmLogistics.settings.showNotifications then
                    g_currentMission:addIngameNotification(
                        FSBaseMission.INGAME_NOTIFICATION_INFO,
                        string.format("Delivery Started: %s en route", delivery.product)
                    )
                end
            end
        end
    end
end

function LogisticsSystem:completeDelivery(delivery)
    -- Update inventory
    local currentLevel = g_AdvancedFarmLogistics.logistics.warehouseInventory[delivery.product] or 0
    g_AdvancedFarmLogistics.logistics.warehouseInventory[delivery.product] = currentLevel + delivery.quantity
    
    -- Add to order history
    table.insert(g_AdvancedFarmLogistics.logistics.orderHistory, {
        deliveryId = delivery.id,
        product = delivery.product,
        quantity = delivery.quantity,
        completedTime = g_currentMission.time
    })
    
    if g_AdvancedFarmLogistics.settings.showNotifications then
        g_currentMission:addIngameNotification(
            FSBaseMission.INGAME_NOTIFICATION_OK,
            string.format("Delivery Complete: %d %s received", delivery.quantity, delivery.product)
        )
    end
end

function LogisticsSystem:getInventoryLevel(product)
    return g_AdvancedFarmLogistics.logistics.warehouseInventory[product] or 0
end

function LogisticsSystem:getPendingDeliveries()
    local pending = 0
    for _, delivery in ipairs(g_AdvancedFarmLogistics.logistics.activeDeliveries) do
        if delivery.status ~= "delivered" then
            pending = pending + 1
        end
    end
    return pending
end

function LogisticsSystem:calculateEfficiency()
    local totalEfficiency = 0
    local count = 0
    
    for _, chain in ipairs(g_AdvancedFarmLogistics.logistics.supplyChains) do
        if chain.status == "active" then
            totalEfficiency = totalEfficiency + chain.efficiency
            count = count + 1
        end
    end
    
    return count > 0 and totalEfficiency / count or 0
end