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
    print("[LogisticsDashboardFrame] Initialized")
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
    if not g_AdvancedFarmLogistics then
        self.systemStatusText:setText("System not initialized")
        return
    end
    
    local supplyChainEfficiency = 0
    if g_AdvancedFarmLogistics.supplyChainManager then
        supplyChainEfficiency = g_AdvancedFarmLogistics.supplyChainManager:calculateSupplyChainEfficiency() or 0
    end
    
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
        supplyChainEfficiency * 100,
        #(g_AdvancedFarmLogistics.logistics.activeDeliveries or {}),
        #(g_AdvancedFarmLogistics.workers.hiredWorkers or {}),
        self:countTrackedEquipment()
    )
    
    self.systemStatusText:setText(statusText)
end

function LogisticsDashboardFrame:updateSupplyChainList()
    if self.supplyChainList.deleteListItems then
        self.supplyChainList:deleteListItems()
    elseif self.supplyChainList.elements then
        for i = #self.supplyChainList.elements, 1, -1 do
            self.supplyChainList.elements[i]:delete()
        end
    end
    
    if not g_AdvancedFarmLogistics or not g_AdvancedFarmLogistics.logistics then return end
    
    local chains = g_AdvancedFarmLogistics.logistics.supplyChains or {}
    
    for _, chain in ipairs(chains) do
        local statusIcon = chain.status == "active" and "[ACTIVE]" or "[DISRUPTED]"
        local text = string.format("%s %s - %.1f%% efficiency", statusIcon, chain.name, (chain.efficiency or 0) * 100)
        
        local textElement = TextElement.new(self.supplyChainList)
        textElement:applyProfile("multiTextOptionSettingsTitle") -- FIX: Added Profile
        textElement:setText(text)
        
        if self.supplyChainList.addElement then self.supplyChainList:addElement(textElement) end
    end
    
    if #chains == 0 then
        local textElement = TextElement.new(self.supplyChainList)
        textElement:applyProfile("multiTextOptionSettingsTitle") -- FIX: Added Profile
        textElement:setText("No supply chains configured")
        textElement:setTextColor(0.7, 0.7, 0.7, 1)
        if self.supplyChainList.addElement then self.supplyChainList:addElement(textElement) end
    end
end

function LogisticsDashboardFrame:updateDeliveryList()
    -- Clear the list
    if self.deliveryList.deleteListItems then
        self.deliveryList:deleteListItems()
    elseif self.deliveryList.elements then
        for i = #self.deliveryList.elements, 1, -1 do
            self.deliveryList.elements[i]:delete()
        end
    end
    
    if not g_AdvancedFarmLogistics or not g_AdvancedFarmLogistics.logistics then return end
    
    local deliveries = g_AdvancedFarmLogistics.logistics.activeDeliveries or {}
    local pendingOrders = g_AdvancedFarmLogistics.logistics.pendingOrders or {}
    local hasItems = false
    
    -- 1. Draw Active Deliveries
    for _, delivery in ipairs(deliveries) do
        local statusIcon = delivery.status == "delivered" and "[DELIVERED]" or "[IN TRANSIT]"
        local text = string.format("%s %d %s to %s", statusIcon, delivery.quantity or 0, delivery.product or "Unknown", delivery.destination or "Unknown")
        
        local textElement = TextElement.new(self.deliveryList)
        textElement:applyProfile("multiTextOptionSettingsTitle")
        textElement:setText(text)
        
        if self.deliveryList.addElement then self.deliveryList:addElement(textElement) end
        hasItems = true
    end
    
    -- 2. Draw Pending Orders (THE MISSING FIX)
    for _, order in ipairs(pendingOrders) do
        if order.status ~= "completed" then
            local statusIcon = order.status == "arrived" and "[ARRIVED]" or "[ORDERED]"
            local text = string.format("%s %d %s (Arrives Day %d)", statusIcon, order.quantity or 0, order.product or "Unknown", order.estimatedArrival or 0)
            
            local textElement = TextElement.new(self.deliveryList)
            textElement:applyProfile("multiTextOptionSettingsTitle")
            textElement:setText(text)
            textElement:setTextColor(1, 0.8, 0, 1) -- Colors pending orders Yellow for visual distinction
            
            if self.deliveryList.addElement then self.deliveryList:addElement(textElement) end
            hasItems = true
        end
    end
    
    -- 3. Draw Empty State Fallback
    if not hasItems then
        local textElement = TextElement.new(self.deliveryList)
        textElement:applyProfile("multiTextOptionSettingsTitle")
        textElement:setText("No active deliveries or orders")
        textElement:setTextColor(0.7, 0.7, 0.7, 1)
        if self.deliveryList.addElement then self.deliveryList:addElement(textElement) end
    end
end

function LogisticsDashboardFrame:updateInventoryList()
    if self.inventoryList.deleteListItems then
        self.inventoryList:deleteListItems()
    elseif self.inventoryList.elements then
        for i = #self.inventoryList.elements, 1, -1 do
            self.inventoryList.elements[i]:delete()
        end
    end
    
    if not g_AdvancedFarmLogistics or not g_AdvancedFarmLogistics.logistics then return end
    
    local hasInventory = false
    local warehouseInventory = g_AdvancedFarmLogistics.logistics.warehouseInventory or {}
    
    for product, quantity in pairs(warehouseInventory) do
        if quantity > 0 then
            local text = string.format("%s: %d units", product, quantity)
            local textElement = TextElement.new(self.inventoryList)
            textElement:applyProfile("multiTextOptionSettingsTitle") -- FIX: Added Profile
            textElement:setText(text)
            
            if self.inventoryList.addElement then self.inventoryList:addElement(textElement) end
            hasInventory = true
        end
    end
    
    if not hasInventory then
        local textElement = TextElement.new(self.inventoryList)
        textElement:applyProfile("multiTextOptionSettingsTitle") -- FIX: Added Profile
        textElement:setText("Inventory empty")
        textElement:setTextColor(0.7, 0.7, 0.7, 1)
        if self.inventoryList.addElement then self.inventoryList:addElement(textElement) end
    end
end

function LogisticsDashboardFrame:countTrackedEquipment()
    if not g_AdvancedFarmLogistics or not g_AdvancedFarmLogistics.maintenance then
        return 0
    end
    
    local count = 0
    for _ in pairs(g_AdvancedFarmLogistics.maintenance.equipmentSchedule or {}) do
        count = count + 1
    end
    return count
end

function LogisticsDashboardFrame:onOrderSuppliesClick()
    if not g_AdvancedFarmLogistics or not g_AdvancedFarmLogistics.supplyChainManager then
        g_gui:showInfoDialog({
            text = "Supply chain system not available",
            dialogType = DialogElement.TYPE_ERROR
        })
        return
    end
    
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
                                    string.sub(orderId, 1, 8), cost or 0),
                                dialogType = DialogElement.TYPE_INFO
                            })
                            self:refreshData()
                        else
                            g_gui:showInfoDialog({
                                text = "Failed to place order",
                                dialogType = DialogElement.TYPE_ERROR
                            })
                        end
                    else
                        g_gui:showInfoDialog({
                            text = "Invalid format. Use: product,quantity",
                            dialogType = DialogElement.TYPE_ERROR
                        })
                    end
                else
                    g_gui:showInfoDialog({
                        text = "Invalid format. Use: product,quantity",
                        dialogType = DialogElement.TYPE_ERROR
                    })
                end
            end
        end,
        confirmText = "Order",
        cancelText = "Cancel",
        defaultText = "seeds,100"
    })
end

function LogisticsDashboardFrame:onOptimizeClick()
    if not g_AdvancedFarmLogistics or not g_AdvancedFarmLogistics.supplyChainManager then
        g_gui:showInfoDialog({
            text = "Supply chain system not available",
            dialogType = DialogElement.TYPE_ERROR
        })
        return
    end
    
    local optimizedCount = 0
    
    local warehouseInventory = g_AdvancedFarmLogistics.logistics.warehouseInventory or {}
    for product, quantity in pairs(warehouseInventory) do
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