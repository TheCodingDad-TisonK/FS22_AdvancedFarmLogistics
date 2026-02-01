-- =========================================================
-- Worker AI System
-- =========================================================
-- Manages hired workers, tasks, and AI behavior
-- =========================================================

---@class WorkerAISystem
WorkerAISystem = {}

function WorkerAISystem:initialize()
    self.taskQueue = {}
    self.workerPerformance = {}
    self.skillImprovementRate = 0.01
end

-- function WorkerManagerFrame:updateWorkerLists()
--     -- Clear existing lists
--     self.hiredWorkersList:deleteListItems()
--     self.availableWorkersList:deleteListItems()
    
--     -- Add hired workers
--     for _, worker in ipairs(g_AdvancedFarmLogistics.workers.hiredWorkers) do
--         local text = string.format("%s (Skill: %d, $%d/hr)", 
--             worker.name, worker.skill, worker.wage)
--         self.hiredWorkersList:addItem(text)
--     end
    
--     -- Add available workers
--     for _, worker in ipairs(g_AdvancedFarmLogistics.workers.availableWorkers) do
--         local text = string.format("%s (Skill: %d, $%d/hr)", 
--             worker.name, worker.skill, worker.wage)
--         self.availableWorkersList:addItem(text)
--     end
-- end

function WorkerAISystem:hireWorker(workerId)
    local worker = nil
    local workerIndex = 0
    
    -- Find worker in available pool
    for i, w in ipairs(g_AdvancedFarmLogistics.workers.availableWorkers) do
        if w.id == workerId then
            worker = w
            workerIndex = i
            break
        end
    end
    
    if not worker then
        return false, "Worker not found"
    end
    
    -- Calculate hiring cost (1 week wage)
    local hiringCost = worker.wage * 40 -- 40 hours
    local farmMoney = g_currentMission:getFarmMoney(g_AdvancedFarmLogistics:getFarmId())
    
    if farmMoney < hiringCost then
        return false, "Insufficient funds for hiring"
    end
    
    -- Deduct hiring cost
    g_currentMission:addMoney(-hiringCost, g_AdvancedFarmLogistics:getFarmId(), MoneyType.OTHER, true)
    
    -- Move worker to hired list
    table.insert(g_AdvancedFarmLogistics.workers.hiredWorkers, worker)
    table.remove(g_AdvancedFarmLogistics.workers.availableWorkers, workerIndex)
    
    -- Initialize performance tracking
    self.workerPerformance[workerId] = {
        tasksCompleted = 0,
        efficiency = 1.0,
        lastTaskTime = 0
    }
    
    if g_AdvancedFarmLogistics.settings.showNotifications then
        g_currentMission:addIngameNotification(
            FSBaseMission.INGAME_NOTIFICATION_OK,
            string.format("Worker Hired: %s (Skill: %d, Wage: $%d/hr)", 
                worker.name, worker.skill, worker.wage)
        )
    end
    
    return true, "Worker hired successfully"
end

function WorkerAISystem:fireWorker(workerId)
    local worker = nil
    local workerIndex = 0
    
    -- Find worker in hired list
    for i, w in ipairs(g_AdvancedFarmLogistics.workers.hiredWorkers) do
        if w.id == workerId then
            worker = w
            workerIndex = i
            break
        end
    end
    
    if not worker then
        return false, "Worker not found"
    end
    
    -- Calculate severance (2 weeks wage)
    local severanceCost = worker.wage * 80 -- 80 hours
    g_currentMission:addMoney(-severanceCost, g_AdvancedFarmLogistics:getFarmId(), MoneyType.OTHER, true)
    
    -- Move worker back to available pool
    table.insert(g_AdvancedFarmLogistics.workers.availableWorkers, worker)
    table.remove(g_AdvancedFarmLogistics.workers.hiredWorkers, workerIndex)
    
    -- Remove performance tracking
    self.workerPerformance[workerId] = nil
    
    if g_AdvancedFarmLogistics.settings.showNotifications then
        g_currentMission:addIngameNotification(
            FSBaseMission.INGAME_NOTIFICATION_OK,
            string.format("Worker Fired: %s (Severance: $%d)", worker.name, severanceCost)
        )
    end
    
    return true, "Worker fired"
end

function WorkerAISystem:assignTask(workerId, taskType, difficulty, location)
    local worker = nil
    for _, w in ipairs(g_AdvancedFarmLogistics.workers.hiredWorkers) do
        if w.id == workerId then
            worker = w
            break
        end
    end
    
    if not worker then
        return false, "Worker not found"
    end
    
    -- Check if worker already has a task
    if g_AdvancedFarmLogistics.workers.workerTasks[workerId] then
        return false, "Worker already has an assigned task"
    end
    
    -- Create task
    local task = {
        id = "task_" .. string.format("%08x", math.random(0x10000000, 0xffffffff)),
        type = taskType,
        difficulty = difficulty or 1,
        location = location,
        assignedTime = g_currentMission.time,
        status = "assigned",
        progress = 0,
        workerSkill = worker.skill
    }
    
    g_AdvancedFarmLogistics.workers.workerTasks[workerId] = task
    
    if g_AdvancedFarmLogistics.settings.showNotifications then
        g_currentMission:addIngameNotification(
            FSBaseMission.INGAME_NOTIFICATION_INFO,
            string.format("Task Assigned: %s to %s", taskType, worker.name)
        )
    end
    
    return true, "Task assigned"
end

function WorkerAISystem:updateWorkerPerformance(workerId, taskSuccess, efficiency)
    local performance = self.workerPerformance[workerId]
    if not performance then
        return
    end
    
    if taskSuccess then
        performance.tasksCompleted = performance.tasksCompleted + 1
    end
    
    -- Update efficiency (moving average)
    performance.efficiency = performance.efficiency * 0.9 + (efficiency or 1.0) * 0.1
    performance.lastTaskTime = g_currentMission.time
    
    -- Improve worker skill based on performance
    if taskSuccess and math.random() < 0.2 then
        self:improveWorkerSkill(workerId)
    end
end

function WorkerAISystem:improveWorkerSkill(workerId)
    local worker = nil
    for _, w in ipairs(g_AdvancedFarmLogistics.workers.hiredWorkers) do
        if w.id == workerId then
            worker = w
            break
        end
    end
    
    if worker then
        local oldSkill = worker.skill
        worker.skill = math.min(5.0, worker.skill + self.skillImprovementRate)
        
        -- Increase wage with skill improvement
        if worker.skill > oldSkill + 0.5 then
            worker.wage = math.floor(worker.wage * 1.1)
            
            if g_AdvancedFarmLogistics.settings.showNotifications then
                g_currentMission:addIngameNotification(
                    FSBaseMission.INGAME_NOTIFICATION_OK,
                    string.format("Skill Increase: %s improved to level %.1f (Wage: $%d/hr)", 
                        worker.name, worker.skill, worker.wage)
                )
            end
        end
    end
end

function WorkerAISystem:getWorkerEfficiency(workerId)
    local performance = self.workerPerformance[workerId]
    return performance and performance.efficiency or 1.0
end

function WorkerAISystem:calculateTotalWages()
    local total = 0
    for _, worker in ipairs(g_AdvancedFarmLogistics.workers.hiredWorkers) do
        -- Assume 40 hours per week
        total = total + (worker.wage * 40)
    end
    return total
end