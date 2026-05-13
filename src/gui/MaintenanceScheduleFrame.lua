-- =========================================================
-- Maintenance Schedule Frame
-- =========================================================
---@class MaintenanceScheduleFrame
MaintenanceScheduleFrame = {}

local MaintenanceScheduleFrame_mt = Class(MaintenanceScheduleFrame, TabbedMenuFrameElement)

MaintenanceScheduleFrame.CONTROLS = { 'maintenanceList', 'equipmentStatsText', 'performMaintenanceButton', 'maintenanceHistoryButton' }

function MaintenanceScheduleFrame.new(target, customMt)
    local self = TabbedMenuFrameElement.new(target, customMt or MaintenanceScheduleFrame_mt)
    self:registerControls(MaintenanceScheduleFrame.CONTROLS)
    self.selectedEquipmentId = nil
    return self
end

function MaintenanceScheduleFrame:initialize()
    self.backButtonInfo = { inputAction = InputAction.MENU_BACK }
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
    -- THE FIX: Auto-register vehicles
    if g_currentMission and g_currentMission.vehicles then
        local farmId = g_AdvancedFarmLogistics:getFarmId()
        for _, vehicle in pairs(g_currentMission.vehicles) do
            if vehicle.getDamageAmount and vehicle.getOwnerFarmId and vehicle:getOwnerFarmId() == farmId then
                g_AdvancedFarmLogistics.maintenanceSystem:registerEquipment(vehicle, g_AdvancedFarmLogistics.settings.maintenanceFrequency)
            end
        end
    end

    if self.maintenanceList.deleteListItems then self.maintenanceList:deleteListItems()
    elseif self.maintenanceList.elements then
        for i = #self.maintenanceList.elements, 1, -1 do self.maintenanceList.elements[i]:delete() end
    end
    
    local currentDay = g_currentMission.environment.currentDay
    local currentVehicleId = nil
    if g_currentMission.controlledVehicle then
        local persistentId = g_currentMission.controlledVehicle.saveId or g_currentMission.controlledVehicle.id
        currentVehicleId = "equip_" .. tostring(persistentId)
    end
    
    local currentIndex = 0
    local selectedIndex = 0

    for equipmentId, schedule in pairs(g_AdvancedFarmLogistics.maintenance.equipmentSchedule) do
        local daysRemaining = schedule.nextMaintenance - currentDay
        local status = daysRemaining <= 0 and "[OVERDUE]" or (daysRemaining <= 7 and "[DUE SOON]" or "[OK]")
        
        -- ORIGINAL VIRTUAL LOGIC RESTORED
        local riskData = g_AdvancedFarmLogistics.maintenance.breakdownRisk[equipmentId]
        local breakdownRisk = riskData and math.floor(riskData.totalRisk * 100) or 0
        
        -- THE FIX: Show actual vehicle name instead of ID number
        local displayName = schedule.vehicleName or "Unknown Vehicle"
        
        local item = TextElement.new(self.maintenanceList)
        item:applyProfile("multiTextOptionSettingsTitle")
        item:setText(string.format("%s %s - Due in %d days | Risk: %d%%", status, displayName, daysRemaining, breakdownRisk))
        item.equipmentId = equipmentId
        
        if daysRemaining <= 0 then item:setTextColor(1, 0, 0, 1)
        elseif daysRemaining <= 7 then item:setTextColor(1, 0.8, 0, 1)
        else item:setTextColor(0, 1, 0, 1) end
        
        if self.maintenanceList.addElement then self.maintenanceList:addElement(item)
        elseif self.maintenanceList.addItem then self.maintenanceList:addItem(item) end
        
        -- THE FIX: Auto-select the vehicle you are driving
        if currentVehicleId and equipmentId == currentVehicleId then
            self.selectedEquipmentId = equipmentId
            selectedIndex = currentIndex
        end
        currentIndex = currentIndex + 1
    end
    
    if currentVehicleId and self.maintenanceList.setSelectedIndex then
        self.maintenanceList:setSelectedIndex(selectedIndex + 1)
    end
    self:updateEquipmentStats()
end

function MaintenanceScheduleFrame:updateEquipmentStats()
    -- ORIGINAL VIRTUAL LOGIC RESTORED
    if self.selectedEquipmentId and g_AdvancedFarmLogistics.maintenance.equipmentSchedule[self.selectedEquipmentId] then
        local schedule = g_AdvancedFarmLogistics.maintenance.equipmentSchedule[self.selectedEquipmentId]
        local dbInfo = g_AdvancedFarmLogistics.maintenanceSystem.equipmentDatabase[self.selectedEquipmentId] or {}
        
        local currentDay = g_currentMission.environment.currentDay
        local daysRemaining = schedule.nextMaintenance - currentDay
        local riskData = g_AdvancedFarmLogistics.maintenance.breakdownRisk[self.selectedEquipmentId]
        local riskPercent = riskData and math.floor(riskData.totalRisk * 100) or 0
        
        local statsText = string.format(
            "--- SELECTED VEHICLE ---\n" ..
            "Model: %s\n" ..
            "Due in: %d days | Breakdown Risk: %d%%\n" ..
            "Total Repair Costs: $%d",
            schedule.vehicleName or "Unknown",
            daysRemaining,
            riskPercent,
            dbInfo.totalRepairCost or 0
        )
        self.equipmentStatsText:setText(statsText)
        return
    end

    local totalEquipment = 0
    local overdueCount = 0
    local dueSoonCount = 0
    local totalRepairCost = 0
    local currentDay = g_currentMission.environment.currentDay
    
    for equipmentId, schedule in pairs(g_AdvancedFarmLogistics.maintenance.equipmentSchedule) do
        totalEquipment = totalEquipment + 1
        local daysRemaining = schedule.nextMaintenance - currentDay
        if daysRemaining <= 0 then overdueCount = overdueCount + 1
        elseif daysRemaining <= 7 then dueSoonCount = dueSoonCount + 1 end
        
        for _, maintenance in ipairs(schedule.maintenanceHistory or {}) do
            totalRepairCost = totalRepairCost + (maintenance.cost or 0)
        end
    end
    
    local statsText = string.format(
        "--- GLOBAL FLEET STATS ---\n" ..
        "Equipment Tracked: %d\n" ..
        "Overdue: %d | Due Soon: %d\n" ..
        "Total Fleet Repair Costs: $%d\n" ..
        "(Select a vehicle above to view its specific stats)",
        totalEquipment, overdueCount, dueSoonCount, totalRepairCost
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
    if selectedItem then return selectedItem.equipmentId end
    return nil
end

function MaintenanceScheduleFrame:onPerformMaintenanceClick()
    local equipmentId = self:getSelectedEquipment()
    if not equipmentId then return end
    
    local costEstimate = g_AdvancedFarmLogistics.maintenanceSystem:getMaintenanceCostEstimate(equipmentId)
    g_gui:showYesNoDialog({
        text = string.format("Perform maintenance on %s?\nEstimated cost: $%d", string.sub(equipmentId, 7, 12), costEstimate),
        callback = function(yes)
            if yes then
                local success, message = g_AdvancedFarmLogistics.maintenanceSystem:performMaintenance(equipmentId)
                if success then g_gui:showInfoDialog({ text = message, dialogType = DialogElement.TYPE_INFO }) self:refreshData()
                else g_gui:showInfoDialog({ text = "Failed: " .. message, dialogType = DialogElement.TYPE_ERROR }) end
            end
        end,
        yesText = "Perform", noText = "Cancel"
    })
end

function MaintenanceScheduleFrame:onMaintenanceHistoryClick()
    local equipmentId = self:getSelectedEquipment()
    if not equipmentId then return end
    
    local schedule = g_AdvancedFarmLogistics.maintenance.equipmentSchedule[equipmentId]
    if not schedule or not schedule.maintenanceHistory then return end
    
    local historyText = "Maintenance History:\n========================\n"
    if #schedule.maintenanceHistory == 0 then historyText = historyText .. "No maintenance history\n"
    else
        for i, maintenance in ipairs(schedule.maintenanceHistory) do
            -- ORIGINAL VIRTUAL LOGIC RESTORED
            local typeText = maintenance.type == "breakdown" and "BREAKDOWN" or "Scheduled"
            local severityText = maintenance.severity and string.format("(Severity: %d)", maintenance.severity) or ""
            historyText = historyText .. string.format("%d. Day %d: %s %s - $%d\n", i, maintenance.date, typeText, severityText, maintenance.cost or 0)
        end
    end
    
    g_gui:showInfoDialog({ text = historyText, dialogType = DialogElement.TYPE_INFO, dialogWidth = 0.4 })
end

-- THE FIX: Bypass the index to fix unclickable buttons
function MaintenanceScheduleFrame:onListSelectionChanged(list, index)
    if list == self.maintenanceList then
        local selectedItem = list:getSelectedElement()
        if selectedItem and selectedItem.equipmentId then self.selectedEquipmentId = selectedItem.equipmentId
        else self.selectedEquipmentId = nil end
        self:updateButtonStates()
        self:updateEquipmentStats()
    end
end