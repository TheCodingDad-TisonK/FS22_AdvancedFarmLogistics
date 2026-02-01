-- =========================================================
-- Supply Chain Manager
-- =========================================================
-- Manages complex supply chains and inventory optimization
-- =========================================================

---@class SupplyChainManager
SupplyChainManager = {}

function SupplyChainManager:initialize()
    self.optimizationAlgorithms = {}
    self.demandForecasting = {}
    self.supplierRelationships = {}
    
    -- Initialize with default products
    self:initializeDefaultProducts()
end

function SupplyChainManager:initializeDefaultProducts()
    -- Set up initial inventory for common farm products
    local defaultInventory = {
        ["seeds"] = 200,
        ["fertilizer"] = 100,
        ["fuel"] = 500,
        ["pesticides"] = 50
    }
    
    for product, quantity in pairs(defaultInventory) do
        g_AdvancedFarmLogistics.logistics.warehouseInventory[product] = quantity
    end
    
    -- Initialize demand forecasting
    local currentDay = g_currentMission.environment.currentDay
    for product, _ in pairs(defaultInventory) do
        self.demandForecasting[product] = {}
        for i = 1, 30 do
            self.demandForecasting[product][currentDay - i] = math.random(5, 20)
        end
    end
end

function SupplyChainManager:optimizeInventory(product, minLevel, maxLevel, leadTime)
    local currentLevel = g_AdvancedFarmLogistics.logistics.warehouseInventory[product] or 0
    local pendingOrders = self:getPendingOrdersForProduct(product)
    local estimatedDailyUsage = self:estimateDailyUsage(product)
    
    -- Calculate reorder point using (s, Q) model
    local safetyStock = estimatedDailyUsage * leadTime * 1.5 -- 50% safety margin
    local reorderPoint = safetyStock + (estimatedDailyUsage * leadTime)
    
    -- Calculate order quantity using EOQ (Economic Order Quantity)
    local orderingCost = 100 -- Fixed cost per order
    local holdingCost = 10 -- Cost to hold one unit for one day
    local annualDemand = estimatedDailyUsage * 365
    
    local eoq = math.sqrt((2 * orderingCost * annualDemand) / holdingCost)
    eoq = math.max(10, math.min(eoq, maxLevel - minLevel))
    
    -- Check if we need to reorder
    if currentLevel + pendingOrders <= reorderPoint then
        local orderQuantity = math.min(eoq, maxLevel - (currentLevel + pendingOrders))
        
        if orderQuantity > 0 then
            self:createPurchaseOrder(product, orderQuantity, leadTime)
            return orderQuantity
        end
    end
    
    return 0
end

function SupplyChainManager:estimateDailyUsage(product)
    -- Analyze historical usage patterns
    local totalUsage = 0
    local dayCount = 0
    
    for day, usage in pairs(self.demandForecasting[product] or {}) do
        totalUsage = totalUsage + usage
        dayCount = dayCount + 1
    end
    
    if dayCount > 0 then
        return totalUsage / dayCount
    end
    
    -- Default estimates for common products
    local defaultEstimates = {
        ["seeds"] = 10,
        ["fertilizer"] = 5,
        ["fuel"] = 20,
        ["pesticides"] = 2
    }
    
    return defaultEstimates[product] or 5
end

function SupplyChainManager:createPurchaseOrder(product, quantity, leadTime)
    local orderId = "order_" .. string.format("%08x", math.random(0x10000000, 0xffffffff))
    
    local supplier = self:selectSupplier(product)
    local unitPrice = self:getMarketPrice(product)
    local orderCost = unitPrice * quantity
    local shippingCost = math.max(50, quantity * 0.1)
    
    local order = {
        id = orderId,
        product = product,
        quantity = quantity,
        leadTime = leadTime or supplier.deliveryTime,
        orderDate = g_currentMission.environment.currentDay,
        status = "pending",
        estimatedArrival = g_currentMission.environment.currentDay + leadTime,
        supplier = supplier,
        unitPrice = unitPrice,
        orderCost = orderCost,
        shippingCost = shippingCost,
        totalCost = orderCost + shippingCost
    }
    
    table.insert(g_AdvancedFarmLogistics.logistics.pendingOrders, order)
    
    -- Record demand
    local currentDay = g_currentMission.environment.currentDay
    self.demandForecasting[product] = self.demandForecasting[product] or {}
    self.demandForecasting[product][currentDay] = (self.demandForecasting[product][currentDay] or 0) + quantity
    
    if g_AdvancedFarmLogistics.settings.showNotifications then
        g_currentMission:addIngameNotification(
            FSBaseMission.INGAME_NOTIFICATION_INFO,
            string.format("Purchase Order: %d %s (Cost: $%d, Arrival: %d days)", 
                quantity, product, order.totalCost, leadTime)
        )
    end
    
    return orderId, order.totalCost
end

function SupplyChainManager:getMarketPrice(product)
    -- Base prices with some randomness
    local basePrices = {
        ["seeds"] = 5,
        ["fertilizer"] = 8,
        ["fuel"] = 1.5,
        ["pesticides"] = 15
    }
    
    local basePrice = basePrices[product] or 10
    
    -- Add market fluctuations
    local fluctuation = (math.random() - 0.5) * 0.2 -- ±10%
    
    return math.floor(basePrice * (1 + fluctuation) * 100) / 100
end

function SupplyChainManager:selectSupplier(product)
    -- Simple supplier selection based on reliability
    local suppliers = {
        {
            name = "AgriSupply Co.",
            reliability = 0.9,
            priceMultiplier = 1.0,
            deliveryTime = 7,
            quality = 0.95
        },
        {
            name = "FarmTech Supplies",
            reliability = 0.85,
            priceMultiplier = 0.95,
            deliveryTime = 10,
            quality = 0.90
        },
        {
            name = "Local Distributor",
            reliability = 0.95,
            priceMultiplier = 1.1,
            deliveryTime = 3,
            quality = 0.98
        }
    }
    
    -- Weighted random selection
    local totalWeight = 0
    for _, supplier in ipairs(suppliers) do
        totalWeight = totalWeight + supplier.reliability
    end
    
    local roll = math.random() * totalWeight
    local cumulative = 0
    
    for _, supplier in ipairs(suppliers) do
        cumulative = cumulative + supplier.reliability
        if roll <= cumulative then
            return supplier
        end
    end
    
    return suppliers[1]
end

function SupplyChainManager:updatePendingOrders()
    local currentDay = g_currentMission.environment.currentDay
    
    for i = #g_AdvancedFarmLogistics.logistics.pendingOrders, 1, -1 do
        local order = g_AdvancedFarmLogistics.logistics.pendingOrders[i]
        
        if order.status == "pending" then
            -- Check if order has arrived
            if currentDay >= order.estimatedArrival then
                order.status = "arrived"
                self:processArrivedOrder(order)
                
                -- Schedule delivery
                g_AdvancedFarmLogistics.logisticsSystem:scheduleDelivery(
                    order.product, 
                    order.quantity, 
                    "Warehouse", 
                    "high"
                )
            end
        elseif order.status == "arrived" then
            -- Check if delivered
            local delivered = false
            for _, delivery in ipairs(g_AdvancedFarmLogistics.logistics.activeDeliveries) do
                if delivery.product == order.product and 
                   delivery.quantity == order.quantity and 
                   delivery.status == "delivered" then
                    delivered = true
                    break
                end
            end
            
            if delivered then
                order.status = "completed"
                table.remove(g_AdvancedFarmLogistics.logistics.pendingOrders, i)
            end
        end
    end
end

function SupplyChainManager:processArrivedOrder(order)
    -- Apply supplier reliability check
    if math.random() < (1 - order.supplier.reliability) then
        local issueTypes = {
            "delayed",
            "partial_shipment",
            "quality_issue"
        }
        
        local issue = issueTypes[math.random(1, #issueTypes)]
        
        if g_AdvancedFarmLogistics.settings.showNotifications then
            local messages = {
                delayed = string.format("Supplier Delay: %s order will arrive late", order.product),
                partial_shipment = string.format("Partial Shipment: %s order incomplete", order.product),
                quality_issue = string.format("Quality Issue: %s order has defects", order.product)
            }
            
            g_currentMission:addIngameNotification(
                FSBaseMission.INGAME_NOTIFICATION_OK,
                messages[issue]
            )
        end
        
        -- Adjust order based on issue
        if issue == "partial_shipment" then
            order.quantity = math.floor(order.quantity * 0.8)
        elseif issue == "quality_issue" then
            order.quantity = math.floor(order.quantity * 0.9)
        end
    end
end

function SupplyChainManager:getPendingOrdersForProduct(product)
    local total = 0
    
    for _, order in ipairs(g_AdvancedFarmLogistics.logistics.pendingOrders) do
        if order.product == product and order.status ~= "completed" then
            total = total + order.quantity
        end
    end
    
    return total
end

function SupplyChainManager:calculateSupplyChainEfficiency()
    local totalEfficiency = 0
    local chainCount = 0
    
    for _, chain in ipairs(g_AdvancedFarmLogistics.logistics.supplyChains) do
        totalEfficiency = totalEfficiency + chain.efficiency
        chainCount = chainCount + 1
    end
    
    -- Factor in inventory optimization
    local inventoryScore = self:calculateInventoryEfficiencyScore()
    local orderFulfillment = self:calculateOrderFulfillmentRate()
    
    local overallEfficiency = 0
    if chainCount > 0 then
        overallEfficiency = (totalEfficiency / chainCount) * 0.6 + 
                           inventoryScore * 0.2 + 
                           orderFulfillment * 0.2
    else
        overallEfficiency = inventoryScore * 0.5 + orderFulfillment * 0.5
    end
    
    return math.min(1.0, overallEfficiency)
end

function SupplyChainManager:calculateInventoryEfficiencyScore()
    local totalProducts = 0
    local optimalProducts = 0
    
    for product, level in pairs(g_AdvancedFarmLogistics.logistics.warehouseInventory) do
        totalProducts = totalProducts + 1
        
        -- Check if inventory is within reasonable bounds
        local estimatedUsage = self:estimateDailyUsage(product)
        local daysSupply = level / (estimatedUsage > 0 and estimatedUsage or 1)
        
        if daysSupply >= 7 and daysSupply <= 30 then
            optimalProducts = optimalProducts + 1
        end
    end
    
    return totalProducts > 0 and optimalProducts / totalProducts or 1.0
end

function SupplyChainManager:calculateOrderFulfillmentRate()
    local completedOrders = 0
    local totalOrders = 0
    
    -- Check if orderHistory exists
    if not g_AdvancedFarmLogistics.logistics.orderHistory then
        return 1.0
    end
    
    -- Check last 30 days of order history
    local currentDay = g_currentMission and g_currentMission.environment.currentDay or 0
    local startDay = currentDay - 30
    
    for _, order in ipairs(g_AdvancedFarmLogistics.logistics.orderHistory) do
        if order.orderDate and order.orderDate >= startDay then
            totalOrders = totalOrders + 1
            if order.status == "completed" then
                completedOrders = completedOrders + 1
            end
        end
    end
    
    return totalOrders > 0 and completedOrders / totalOrders or 1.0
end

function SupplyChainManager:getInventoryValue()
    local totalValue = 0
    
    for product, quantity in pairs(g_AdvancedFarmLogistics.logistics.warehouseInventory) do
        local unitPrice = self:getMarketPrice(product)
        totalValue = totalValue + (quantity * unitPrice)
    end
    
    return totalValue
end