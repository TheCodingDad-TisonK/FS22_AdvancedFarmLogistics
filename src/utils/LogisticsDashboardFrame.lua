-- =========================================================
-- Logistics Dashboard Frame
-- =========================================================
-- Main dashboard showing overview of logistics operations
-- =========================================================

---@class LogisticsDashboardFrame
---@field systemStatusText GuiElement
---@field supplyChainList GuiElement
---@field deliveryList GuiElement
---@field inventoryList GuiElement
---@field orderSuppliesButton GuiElement
---@field optimizeButton GuiElement
LogisticsDashboardFrame = {}

local LogisticsDashboardFrame_mt = Class(LogisticsDashboardFrame, TabbedMenuFrameElement)

LogisticsDashboardFrame.CONTROLS = {
    'systemStatusText',
    'supplyChainList',
    'deliveryList',
    'inventoryList',
    'orderSuppliesButton',
    'optimizeButton'
}

function LogisticsDashboardFrame.new(target, customMt)
    local self = TabbedMenuFrameElement.new(target, customMt or LogisticsDashboardFrame_mt)

    self:registerControls(LogisticsDashboardFrame.CONTROLS)

    return self
end

function LogisticsDashboardFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function LogisticsDashboardFrame:onFrameOpen()
    LogisticsDashboardFrame:superClass().onFrameOpen(self)
    self:refreshData()
    
    if FocusManager:getFocusedElement() == nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.supplyChainList)
        self:setSoundSuppressed(false)
    end
end

function LogisticsDashboardFrame:refreshData()
    self:updateSystemStatus()
    self:updateSupplyChainList()
    self:updateDeliveryList()
    self:updateInventoryList()
end

function LogisticsDashboardFrame:updateSystemStatus()
    local statusText = string.format(
        "Advanced Farm Logistics Manager v1.0.0.0\n" ..
        "================================\n" ..
        "Active Event: %s\n" ..
        "Supply Chain Efficiency: %.1f%%\n" ..
        "Pending Deliveries: %d\n" ..
        "Workers Hired: %d\n" ..
        "Equipment Tracked: %d\n" ..
        "================================\n" ..
        "Press L to open, 'afl' for console commands",
        g_AdvancedFarmLogistics.events.activeEvent or "None",
        g_AdvancedFarmLogistics.supplyChainManager:calculateSupplyChainEfficiency() * 100,
        g_AdvancedFarmLogistics.logisticsSystem:getPendingDeliveries(),
        #g_AdvancedFarmLogistics.workers.hiredWorkers,
        self:countTrackedEquipment()
    )
    
    self.systemStatusText:setText(statusText)
end

function LogisticsDashboardFrame:updateSupplyChainList()
    self.supplyChainList:deleteListItems()
    
    if not g_AdvancedFarmLogistics or not g_AdvancedFarmLogistics.logistics then
        return
    end
    
    for _, chain in ipairs(g_AdvancedFarmLogistics.logistics.supplyChains) do
        local statusIcon = chain.status == "active" and "✓" or "⚠"
        
        -- Create text for the list item
        local text = string.format("%s %s - %.1f%% efficiency", 
            statusIcon, chain.name, (chain.efficiency or 0) * 100)
        
        -- Add item to list using the list's built-in method
        self.supplyChainList:addItem(text)
        
        -- Get the last added item
        local itemCount = self.supplyChainList:getItemCount()
        if itemCount > 0 then
            local item = self.supplyChainList:getItem(itemCount - 1)
            
            -- Color code based on efficiency
            local efficiency = chain.efficiency or 0
            if efficiency < 0.7 then
                item:setTextColor(1, 0, 0, 1) -- Red
            elseif efficiency < 0.85 then
                item:setTextColor(1, 1, 0, 1) -- Yellow
            else
                item:setTextColor(0, 1, 0, 1) -- Green
            end
        end
    end
    
    if self.supplyChainList:getItemCount() == 0 then
        self.supplyChainList:addItem("No supply chains configured")
        local item = self.supplyChainList:getItem(0)
        if item then
            item:setTextColor(0.7, 0.7, 0.7, 1)
        end
    end
end

function LogisticsDashboardFrame:updateDeliveryList()
    self.deliveryList:deleteListItems()
    
    for _, delivery in ipairs(g_AdvancedFarmLogistics.logistics.activeDeliveries) do
        local statusIcon = "⏳"
        if delivery.status == "delivered" then
            statusIcon = "✓"
        elseif delivery.status == "in_transit" then
            statusIcon = "🚚"
        end
        
        local item = GuiListElement.new(self.deliveryList)
        item:setText(string.format("%s %d %s to %s - %s", 
            statusIcon, 
            delivery.quantity, 
            delivery.product, 
            delivery.destination,
            delivery.status))
        
        self.deliveryList:addItem(item)
    end
    
    if #g_AdvancedFarmLogistics.logistics.activeDeliveries == 0 then
        local item = GuiListElement.new(self.deliveryList)
        item:setText("No active deliveries")
        item:setTextColor(0.7, 0.7, 0.7, 1)
        self.deliveryList:addItem(item)
    end
end

function LogisticsDashboardFrame:updateInventoryList()
    self.inventoryList:deleteListItems()
    
    for product, quantity in pairs(g_AdvancedFarmLogistics.logistics.warehouseInventory) do
        if quantity > 0 then
            local item = GuiListElement.new(self.inventoryList)
            item:setText(string.format("%s: %d units", product, quantity))
            self.inventoryList:addItem(item)
        end
    end
    
    -- Also show pending orders
    for _, order in ipairs(g_AdvancedFarmLogistics.logistics.pendingOrders) do
        if order.status ~= "completed" then
            local item = GuiListElement.new(self.inventoryList)
            item:setText(string.format("⏳ %s: %d (Ordered)", order.product, order.quantity))
            item:setTextColor(0.5, 0.5, 1, 1)
            self.inventoryList:addItem(item)
        end
    end
    
    if self.inventoryList:getItemCount() == 0 then
        local item = GuiListElement.new(self.inventoryList)
        item:setText("Inventory empty")
        item:setTextColor(0.7, 0.7, 0.7, 1)
        self.inventoryList:addItem(item)
    end
end

function LogisticsDashboardFrame:countTrackedEquipment()
    local count = 0
    for _ in pairs(g_AdvancedFarmLogistics.maintenance.equipmentSchedule) do
        count = count + 1
    end
    return count
end

function LogisticsDashboardFrame:onOrderSuppliesClick()
    -- Show order dialog
    g_gui:showTextInputDialog({
        text = "Order supplies. Format: product,quantity\nExample: seeds,100",
        callback = function(inputText)
            if inputText and inputText ~= "" then
                local parts = string.split(inputText, ",")
                if #parts == 2 then
                    local product = string.trim(parts[1])
                    local quantity = tonumber(string.trim(parts[2]))
                    
                    if product and quantity and quantity > 0 then
                        local orderId, cost = g_AdvancedFarmLogistics.supplyChainManager:createPurchaseOrder(
                            product, 
                            quantity, 
                            7 -- 7 day lead time
                        )
                        
                        if orderId then
                            g_gui:showInfoDialog({
                                text = string.format("Order placed!\nOrder ID: %s\nTotal Cost: $%d", 
                                    string.sub(orderId, 1, 8), cost),
                                dialogType = DialogElement.TYPE_INFO
                            })
                            self:refreshData()
                        end
                    end
                end
            end
        end,
        confirmText = "Order",
        cancelText = "Cancel",
        defaultText = "seeds,100"
    })
end

function LogisticsDashboardFrame:onOptimizeClick()
    -- Run supply chain optimization
    local optimizedCount = 0
    
    for product, quantity in pairs(g_AdvancedFarmLogistics.logistics.warehouseInventory) do
        local orderQuantity = g_AdvancedFarmLogistics.supplyChainManager:optimizeInventory(
            product, 
            50, -- min level
            500, -- max level
            7 -- lead time days
        )
        
        if orderQuantity > 0 then
            optimizedCount = optimizedCount + 1
        end
    end
    
    if optimizedCount > 0 then
        g_gui:showInfoDialog({
            text = string.format("Supply chains optimized!\n%d products reordered", optimizedCount),
            dialogType = DialogElement.TYPE_INFO
        })
        self:refreshData()
    else
        g_gui:showInfoDialog({
            text = "No optimization needed - inventory levels are optimal",
            dialogType = DialogElement.TYPE_INFO
        })
    end
end