-- =========================================================
-- Maintenance System
-- =========================================================
-- Manages equipment maintenance schedules and repairs
-- =========================================================

---@class MaintenanceSystem
MaintenanceSystem = {}

function MaintenanceSystem:initialize()
    self.maintenanceCosts = {}
    self.repairTeams = {}
    self.equipmentDatabase = {}
end

function MaintenanceSystem:registerEquipment(vehicle, maintenanceInterval, criticalComponents)
    if not vehicle or not vehicle.rootNode then
        return nil
    end
    
    local equipmentId = "equip_" .. tostring(vehicle.rootNode)
    
    -- Check if already registered
    if g_AdvancedFarmLogistics.maintenance.equipmentSchedule[equipmentId] then
        return equipmentId
    end
    
    local currentDay = g_currentMission.environment.currentDay
    local interval = maintenanceInterval or g_AdvancedFarmLogistics.settings.maintenanceFrequency
    
    -- Create maintenance schedule
    local schedule = {
        equipmentId = equipmentId,
        vehicle = vehicle,
        maintenanceInterval = interval,
        nextMaintenance = currentDay + interval,
        lastMaintenance = currentDay,
        criticalComponents = criticalComponents or {},
        maintenanceHistory = {}
    }
    
    g_AdvancedFarmLogistics.maintenance.equipmentSchedule[equipmentId] = schedule
    
    -- Initialize breakdown risk
    g_AdvancedFarmLogistics.maintenance.breakdownRisk[equipmentId] = {
        baseRisk = 0.05,
        ageFactor = 0,
        usageFactor = 0,
        totalRisk = 0.05
    }
    
    -- Store in database
    self.equipmentDatabase[equipmentId] = {
        type = vehicle.typeName or "Unknown",
        purchaseDate = currentDay,
        hoursOperated = 0,
        totalRepairCost = 0
    }
    
    return equipmentId
end

function MaintenanceSystem:performMaintenance(equipmentId)
    local schedule = g_AdvancedFarmLogistics.maintenance.equipmentSchedule[equipmentId]
    if not schedule then
        return false, "Equipment not found"
    end
    
    local currentDay = g_currentMission.environment.currentDay
    
    -- Calculate maintenance cost
    local baseCost = 500
    local age = currentDay - schedule.lastMaintenance
    local ageFactor = math.min(5.0, age / 365) -- Up to 5x for very old equipment
    local maintenanceCost = math.floor(baseCost * (1 + ageFactor))
    
    -- Check funds
    local farmMoney = g_currentMission:getFarmMoney(g_AdvancedFarmLogistics:getFarmId())
    if farmMoney < maintenanceCost then
        return false, "Insufficient funds for maintenance"
    end
    
    -- Deduct cost
    g_currentMission:addMoney(-maintenanceCost, g_AdvancedFarmLogistics:getFarmId(), MoneyType.VEHICLE_MAINTENANCE, true)
    
    -- Update schedule
    schedule.lastMaintenance = currentDay
    schedule.nextMaintenance = currentDay + schedule.maintenanceInterval
    
    -- Reset breakdown risk
    if g_AdvancedFarmLogistics.maintenance.breakdownRisk[equipmentId] then
        g_AdvancedFarmLogistics.maintenance.breakdownRisk[equipmentId].totalRisk = 0.05
    end
    
    -- Add to history
    table.insert(schedule.maintenanceHistory, {
        date = currentDay,
        cost = maintenanceCost,
        type = "scheduled"
    })
    
    -- Update equipment database
    if self.equipmentDatabase[equipmentId] then
        self.equipmentDatabase[equipmentId].totalRepairCost = 
            (self.equipmentDatabase[equipmentId].totalRepairCost or 0) + maintenanceCost
    end
    
    -- Add to repair costs history
    g_AdvancedFarmLogistics.maintenance.repairCosts[currentDay] = 
        (g_AdvancedFarmLogistics.maintenance.repairCosts[currentDay] or 0) + maintenanceCost
    
    if g_AdvancedFarmLogistics.settings.showNotifications then
        g_currentMission:addIngameNotification(
            FSBaseMission.INGAME_NOTIFICATION_OK,
            string.format("Maintenance Complete: Equipment #%s (Cost: $%d)", 
                string.sub(equipmentId, 7, 10), maintenanceCost)
        )
    end
    
    return true, "Maintenance completed successfully"
end

function MaintenanceSystem:handleBreakdown(equipmentId)
    local schedule = g_AdvancedFarmLogistics.maintenance.equipmentSchedule[equipmentId]
    if not schedule then
        return
    end
    
    local currentDay = g_currentMission.environment.currentDay
    
    -- Calculate breakdown severity (1-3)
    local severity = math.random(1, 3)
    
    -- Calculate repair cost (more severe = more expensive)
    local baseRepairCost = 1000
    local repairCost = baseRepairCost * severity * (1 + (currentDay - schedule.lastMaintenance) / 365)
    repairCost = math.floor(repairCost)
    
    -- Apply repair cost
    g_currentMission:addMoney(-repairCost, g_AdvancedFarmLogistics:getFarmId(), MoneyType.VEHICLE_REPAIR, true)
    
    -- Update next maintenance (sooner due to breakdown)
    schedule.nextMaintenance = currentDay + math.max(7, schedule.maintenanceInterval / 2)
    
    -- Add to history
    table.insert(schedule.maintenanceHistory, {
        date = currentDay,
        cost = repairCost,
        type = "breakdown",
        severity = severity
    })
    
    -- Update equipment database
    if self.equipmentDatabase[equipmentId] then
        self.equipmentDatabase[equipmentId].totalRepairCost = 
            (self.equipmentDatabase[equipmentId].totalRepairCost or 0) + repairCost
    end
    
    -- Add to repair costs
    g_AdvancedFarmLogistics.maintenance.repairCosts[currentDay] = 
        (g_AdvancedFarmLogistics.maintenance.repairCosts[currentDay] or 0) + repairCost
    
    if g_AdvancedFarmLogistics.settings.showNotifications then
        g_currentMission:addIngameNotification(
            FSBaseMission.INGAME_NOTIFICATION_CRITICAL,
            string.format("BREAKDOWN: Equipment #%s (Severity: %d, Repair: $%d)", 
                string.sub(equipmentId, 7, 10), severity, repairCost)
        )
    end
    
    return severity, repairCost
end

function MaintenanceSystem:calculateBreakdownRisk(equipmentId)
    local riskData = g_AdvancedFarmLogistics.maintenance.breakdownRisk[equipmentId]
    if not riskData then
        return 0
    end
    
    local schedule = g_AdvancedFarmLogistics.maintenance.equipmentSchedule[equipmentId]
    if not schedule then
        return 0
    end
    
    local currentDay = g_currentMission.environment.currentDay
    local daysSinceMaintenance = currentDay - schedule.lastMaintenance
    local daysUntilNext = schedule.nextMaintenance - currentDay
    
    -- Calculate risk factors
    riskData.ageFactor = math.min(1.0, daysSinceMaintenance / (schedule.maintenanceInterval * 2))
    riskData.usageFactor = 0.3 -- Placeholder, would track actual usage
    
    -- Total risk increases as maintenance becomes overdue
    local overdueFactor = daysUntilNext < 0 and math.abs(daysUntilNext) / 30 or 0
    riskData.totalRisk = riskData.baseRisk + (riskData.ageFactor * 0.3) + (overdueFactor * 0.5)
    riskData.totalRisk = math.min(0.95, riskData.totalRisk)
    
    return riskData.totalRisk
end

function MaintenanceSystem:checkForBreakdowns()
    local breakdowns = {}
    
    for equipmentId, riskData in pairs(g_AdvancedFarmLogistics.maintenance.breakdownRisk) do
        local risk = self:calculateBreakdownRisk(equipmentId)
        
        -- Random chance of breakdown based on risk
        if math.random() < risk * 0.001 then -- Daily check
            local severity, cost = self:handleBreakdown(equipmentId)
            if severity then
                table.insert(breakdowns, {
                    equipmentId = equipmentId,
                    severity = severity,
                    cost = cost
                })
            end
        end
    end
    
    return breakdowns
end

function MaintenanceSystem:getMaintenanceCostEstimate(equipmentId)
    local schedule = g_AdvancedFarmLogistics.maintenance.equipmentSchedule[equipmentId]
    if not schedule then
        return 0
    end
    
    local baseCost = 500
    local currentDay = g_currentMission.environment.currentDay
    local age = currentDay - schedule.lastMaintenance
    local ageFactor = math.min(5.0, age / 365)
    
    return math.floor(baseCost * (1 + ageFactor))
end