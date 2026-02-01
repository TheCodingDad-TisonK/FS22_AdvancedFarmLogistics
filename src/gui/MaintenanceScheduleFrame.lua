-- =========================================================
-- Maintenance Schedule Frame
-- =========================================================
-- Manages equipment maintenance and repair schedules
-- =========================================================

---@class MaintenanceScheduleFrame
---@field maintenanceList GuiElement
---@field equipmentStatsText GuiElement
---@field performMaintenanceButton GuiElement
---@field registerEquipmentButton GuiElement
---@field maintenanceHistoryButton GuiElement
---@field selectedEquipmentId string
MaintenanceScheduleFrame = {}

local MaintenanceScheduleFrame_mt = Class(MaintenanceScheduleFrame, TabbedMenuFrameElement)

MaintenanceScheduleFrame.CONTROLS = {
    'maintenanceList',
    'equipmentStatsText',
    'performMaintenanceButton',
    'registerEquipmentButton',
    'maintenanceHistoryButton'
}

function MaintenanceScheduleFrame.new(target, customMt)
    local self = TabbedMenuFrameElement.new(target, customMt or MaintenanceScheduleFrame_mt)

    self:registerControls(MaintenanceScheduleFrame.CONTROLS)
    self.selectedEquipmentId = nil

    return self
end

function MaintenanceScheduleFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function MaintenanceScheduleFrame:onFrameOpen()
    MaintenanceScheduleFrame:superClass().onFrameOpen(self)
    self:refreshData()
    
    if FocusManager:getFocusedElement() == nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.maintenanceList)
        self:setSoundSuppressed(false)
    end
end

function MaintenanceScheduleFrame:refreshData()
    self:updateMaintenanceList()
    self:updateEquipmentStats()
    self:updateButtonStates()
end

function MaintenanceScheduleFrame:updateMaintenanceList()
    self.maintenanceList:deleteListItems()
    
    local currentDay = g_currentMission.environment.currentDay
    
    for equipmentId, schedule in pairs(g_AdvancedFarmLogistics.maintenance.equipmentSchedule) do
        local daysRemaining = schedule.nextMaintenance - currentDay
        
        local status = "✓"
        local statusColor = "00FF00" -- Green
        if daysRemaining <= 0 then
            status = "⚠"
            statusColor = "FF0000" -- Red
        elseif daysRemaining <= 7 then
            status = "⚠"
            statusColor = "FFFF00" -- Yellow
        end
        
        local riskData = g_AdvancedFarmLogistics.maintenance.breakdownRisk[equipmentId]
        local breakdownRisk = riskData and math.floor(riskData.totalRisk * 100) or 0
        
        local item = GuiListElement.new(self.maintenanceList)
        item:setText(string.format("%s %s - Due in %d days | Risk: %d%%", 
            status, 
            string.sub(equipmentId, 7, 12), -- Short ID
            daysRemaining,
            breakdownRisk))
        
        -- Store equipment ID for selection
        item.equipmentId = equipmentId
        
        -- Color code based on urgency
        if daysRemaining <= 0 then
            item:setTextColor(1, 0, 0, 1) -- Red
        elseif daysRemaining <= 7 then
            item:setTextColor(1, 1, 0, 1) -- Yellow
        else
            item:setTextColor(0, 1, 0, 1) -- Green
        end
        
        self.maintenanceList:addItem(item)
    end
end

function MaintenanceScheduleFrame:updateEquipmentStats()
    local totalEquipment = 0
    local overdueCount = 0
    local dueSoonCount = 0
    local totalRepairCost = 0
    
    local currentDay = g_currentMission.environment.currentDay
    
    for equipmentId, schedule in pairs(g_AdvancedFarmLogistics.maintenance.equipmentSchedule) do
        totalEquipment = totalEquipment + 1
        
        local daysRemaining = schedule.nextMaintenance - currentDay
        if daysRemaining <= 0 then
            overdueCount = overdueCount + 1
        elseif daysRemaining <= 7 then
            dueSoonCount = dueSoonCount + 1
        end
        
        -- Sum repair costs from history
        for _, maintenance in ipairs(schedule.maintenanceHistory or {}) do
            totalRepairCost = totalRepairCost + (maintenance.cost or 0)
        end
    end
    
    local statsText = string.format(
        "Equipment Tracked: %d\n" ..
        "Overdue: %d | Due Soon: %d\n" ..
        "Total Repair Costs: $%d\n" ..
        "Click Register to add current vehicle",
        totalEquipment,
        overdueCount,
        dueSoonCount,
        totalRepairCost
    )
    
    self.equipmentStatsText:setText(statsText)
end

function MaintenanceScheduleFrame:updateButtonStates()
    local hasSelection = self.selectedEquipmentId ~= nil
    self.performMaintenanceButton:setDisabled(not hasSelection)
    self.maintenanceHistoryButton:setDisabled(not hasSelection)
end

function MaintenanceScheduleFrame:getSelectedEquipment()
    local selectedItem = self.maintenanceList:getSelectedElement()
    if selectedItem then
        return selectedItem.equipmentId
    end
    return nil
end

function MaintenanceScheduleFrame:onPerformMaintenanceClick()
    local equipmentId = self:getSelectedEquipment()
    if not equipmentId then return end
    
    -- Get cost estimate
    local costEstimate = g_AdvancedFarmLogistics.maintenanceSystem:getMaintenanceCostEstimate(equipmentId)
    
    -- Show confirmation dialog
    g_gui:showYesNoDialog({
        text = string.format("Perform maintenance on equipment %s?\nEstimated cost: $%d", 
            string.sub(equipmentId, 7, 12), costEstimate),
        callback = function(yes)
            if yes then
                local success, message = g_AdvancedFarmLogistics.maintenanceSystem:performMaintenance(equipmentId)
                
                if success then
                    g_gui:showInfoDialog({
                        text = message,
                        dialogType = DialogElement.TYPE_INFO
                    })
                    self:refreshData()
                else
                    g_gui:showInfoDialog({
                        text = "Failed: " .. message,
                        dialogType = DialogElement.TYPE_ERROR
                    })
                end
            end
        end,
        yesText = "Perform",
        noText = "Cancel"
    })
end

function MaintenanceScheduleFrame:onRegisterEquipmentClick()
    local vehicle = g_currentMission.controlledVehicle
    if not vehicle then
        g_gui:showInfoDialog({
            text = "Please get in a vehicle to register it",
            dialogType = DialogElement.TYPE_WARNING
        })
        return
    end
    
    local equipmentId = g_AdvancedFarmLogistics.maintenanceSystem:registerEquipment(
        vehicle, 
        g_AdvancedFarmLogistics.settings.maintenanceFrequency
    )
    
    if equipmentId then
        g_gui:showInfoDialog({
            text = string.format("Vehicle registered!\nEquipment ID: %s", string.sub(equipmentId, 7, 12)),
            dialogType = DialogElement.TYPE_INFO
        })
        self:refreshData()
    else
        g_gui:showInfoDialog({
            text = "Failed to register vehicle",
            dialogType = DialogElement.TYPE_ERROR
        })
    end
end

function MaintenanceScheduleFrame:onMaintenanceHistoryClick()
    local equipmentId = self:getSelectedEquipment()
    if not equipmentId then return end
    
    local schedule = g_AdvancedFarmLogistics.maintenance.equipmentSchedule[equipmentId]
    if not schedule or not schedule.maintenanceHistory then return end
    
    local historyText = "Maintenance History:\n"
    historyText = historyText .. "========================\n"
    
    if #schedule.maintenanceHistory == 0 then
        historyText = historyText .. "No maintenance history\n"
    else
        for i, maintenance in ipairs(schedule.maintenanceHistory) do
            local typeText = maintenance.type == "breakdown" and "BREAKDOWN" or "Scheduled"
            local severityText = maintenance.severity and string.format("(Severity: %d)", maintenance.severity) or ""
            
            historyText = historyText .. string.format(
                "%d. Day %d: %s %s - $%d\n",
                i,
                maintenance.date,
                typeText,
                severityText,
                maintenance.cost or 0
            )
        end
    end
    
    g_gui:showInfoDialog({
        text = historyText,
        dialogType = DialogElement.TYPE_INFO,
        dialogWidth = 0.4
    })
end

function MaintenanceScheduleFrame:onListSelectionChanged(list, element)
    -- element might be a number (index) or nil
    if list == self.maintenanceList then
        if element and type(element) == "table" then
            self.selectedEquipmentId = element.equipmentId
            self:updateButtonStates()
        else
            self.selectedEquipmentId = nil
            self:updateButtonStates()
        end
    end
end