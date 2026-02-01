-- =========================================================
-- Worker Manager Frame
-- =========================================================
-- Manages worker hiring, firing, and task assignment
-- =========================================================

---@class WorkerManagerFrame
---@field hiredWorkersList GuiElement
---@field availableWorkersList GuiElement
---@field workerStatsText GuiElement
---@field hireButton GuiElement
---@field fireButton GuiElement
---@field assignTaskButton GuiElement
---@field selectedWorkerId string
WorkerManagerFrame = {}

local WorkerManagerFrame_mt = Class(WorkerManagerFrame, TabbedMenuFrameElement)

WorkerManagerFrame.CONTROLS = {
    'hiredWorkersList',
    'availableWorkersList',
    'workerStatsText',
    'hireButton',
    'fireButton',
    'assignTaskButton'
}

function WorkerManagerFrame.new(target, customMt)
    local self = TabbedMenuFrameElement.new(target, customMt or WorkerManagerFrame_mt)

    self:registerControls(WorkerManagerFrame.CONTROLS)
    self.selectedWorkerId = nil
    self.workerData = {} -- Store worker data separately
    self.selectedIndex = { hired = -1, available = -1 }

    return self
end

function WorkerManagerFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function WorkerManagerFrame:onFrameOpen()
    WorkerManagerFrame:superClass().onFrameOpen(self)
    self:refreshData()
    
    if FocusManager:getFocusedElement() == nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.hiredWorkersList)
        self:setSoundSuppressed(false)
    end
end

function WorkerManagerFrame:refreshData()
    self:updateWorkerLists()
    self:updateWorkerStats()
    self:updateButtonStates()
end

function WorkerManagerFrame:updateWorkerLists()
    -- Clear existing lists and data
    if self.hiredWorkersList.deleteListItems then
        self.hiredWorkersList:deleteListItems()
    end
    if self.availableWorkersList.deleteListItems then
        self.availableWorkersList:deleteListItems()
    end
    self.workerData = {}
    
    -- Add hired workers
    local hiredWorkers = g_AdvancedFarmLogistics.workers.hiredWorkers or {}
    for i, worker in ipairs(hiredWorkers) do
        local text = string.format("%s (Skill: %d, $%d/hr)", 
            worker.name, worker.skill, worker.wage)
        
        if self.hiredWorkersList.addItem then
            self.hiredWorkersList:addItem(text)
        else
            -- Manual creation
            local textElement = TextElement.new(self.hiredWorkersList)
            textElement:setText(text)
            textElement.workerId = worker.id
            if self.hiredWorkersList.addElement then
                self.hiredWorkersList:addElement(textElement)
            end
        end
        
        -- Store worker data by position
        self.workerData["hired_" .. i] = {
            id = worker.id,
            name = worker.name,
            skill = worker.skill,
            wage = worker.wage
        }
    end
    
    -- Add available workers
    local availableWorkers = g_AdvancedFarmLogistics.workers.availableWorkers or {}
    for i, worker in ipairs(availableWorkers) do
        local text = string.format("%s (Skill: %d, $%d/hr)", 
            worker.name, worker.skill, worker.wage)
        
        if self.availableWorkersList.addItem then
            self.availableWorkersList:addItem(text)
        else
            -- Manual creation
            local textElement = TextElement.new(self.availableWorkersList)
            textElement:setText(text)
            textElement.workerId = worker.id
            if self.availableWorkersList.addElement then
                self.availableWorkersList:addElement(textElement)
            end
        end
        
        -- Store worker data by position
        self.workerData["available_" .. i] = {
            id = worker.id,
            name = worker.name,
            skill = worker.skill,
            wage = worker.wage
        }
    end
end

function WorkerManagerFrame:updateWorkerStats()
    local totalWages = 0
    local totalSkill = 0
    local activeTasks = 0
    
    local hiredWorkers = g_AdvancedFarmLogistics.workers.hiredWorkers or {}
    for _, worker in ipairs(hiredWorkers) do
        totalWages = totalWages + worker.wage * 40 -- Weekly wage (40 hours)
        totalSkill = totalSkill + worker.skill
        
        if g_AdvancedFarmLogistics.workers.workerTasks and g_AdvancedFarmLogistics.workers.workerTasks[worker.id] then
            activeTasks = activeTasks + 1
        end
    end
    
    local avgSkill = #hiredWorkers > 0 and totalSkill / #hiredWorkers or 0
    
    local statsText = string.format(
        "Workers: %d hired, %d available\n" ..
        "Weekly Wages: $%d\n" ..
        "Average Skill: %.1f\n" ..
        "Active Tasks: %d",
        #hiredWorkers,
        #(g_AdvancedFarmLogistics.workers.availableWorkers or {}),
        totalWages,
        avgSkill,
        activeTasks
    )
    
    self.workerStatsText:setText(statsText)
end

function WorkerManagerFrame:updateButtonStates()
    -- Simple button state management
    local hasHiredSelection = self.selectedIndex.hired >= 0
    local hasAvailableSelection = self.selectedIndex.available >= 0
    
    if self.hireButton then
        self.hireButton:setDisabled(not hasAvailableSelection)
    end
    if self.fireButton then
        self.fireButton:setDisabled(not hasHiredSelection)
    end
    if self.assignTaskButton then
        self.assignTaskButton:setDisabled(not hasHiredSelection)
    end
end

function WorkerManagerFrame:getSelectedHiredWorker()
    if self.selectedIndex.hired >= 0 then
        local dataKey = "hired_" .. (self.selectedIndex.hired + 1)
        if self.workerData[dataKey] then
            return self.workerData[dataKey].id
        end
    end
    return nil
end

function WorkerManagerFrame:getSelectedAvailableWorker()
    if self.selectedIndex.available >= 0 then
        local dataKey = "available_" .. (self.selectedIndex.available + 1)
        if self.workerData[dataKey] then
            return self.workerData[dataKey].id
        end
    end
    return nil
end

function WorkerManagerFrame:onHireClick()
    local workerId = self:getSelectedAvailableWorker()
    if not workerId then return end
    
    local success, message = g_AdvancedFarmLogistics.workerAISystem:hireWorker(workerId)
    
    if success then
        g_gui:showInfoDialog({
            text = message,
            dialogType = DialogElement.TYPE_INFO
        })
        self:refreshData()
    else
        g_gui:showInfoDialog({
            text = "Failed to hire worker: " .. message,
            dialogType = DialogElement.TYPE_ERROR
        })
    end
end

function WorkerManagerFrame:onFireClick()
    local workerId = self:getSelectedHiredWorker()
    if not workerId then return end
    
    local success, message = g_AdvancedFarmLogistics.workerAISystem:fireWorker(workerId)
    
    if success then
        g_gui:showInfoDialog({
            text = message,
            dialogType = DialogElement.TYPE_INFO
        })
        self:refreshData()
    else
        g_gui:showInfoDialog({
            text = "Failed to fire worker: " .. message,
            dialogType = DialogElement.TYPE_ERROR
        })
    end
end

function WorkerManagerFrame:onAssignTaskClick()
    local workerId = self:getSelectedHiredWorker()
    if not workerId then return end
    
    -- Show task assignment dialog
    g_gui:showTextInputDialog({
        text = "Enter task type (planting, harvesting, transport, maintenance):",
        callback = function(inputText)
            if inputText and inputText ~= "" then
                local success, message = g_AdvancedFarmLogistics.workerAISystem:assignTask(
                    workerId, 
                    inputText, 
                    1, -- difficulty
                    "Field 1" -- location
                )
                
                if success then
                    g_gui:showInfoDialog({
                        text = message,
                        dialogType = DialogElement.TYPE_INFO
                    })
                    self:refreshData()
                else
                    g_gui:showInfoDialog({
                        text = "Failed to assign task: " .. message,
                        dialogType = DialogElement.TYPE_ERROR
                    })
                end
            end
        end,
        confirmText = "Assign",
        cancelText = "Cancel",
        defaultText = "harvesting"
    })
end

-- Simplified selection handling
function WorkerManagerFrame:onListClick(list, element)
    if list == self.hiredWorkersList then
        -- Simple index tracking for hired workers
        self.selectedIndex.hired = self:findElementIndex(list, element)
        self.selectedIndex.available = -1
    elseif list == self.availableWorkersList then
        -- Simple index tracking for available workers
        self.selectedIndex.available = self:findElementIndex(list, element)
        self.selectedIndex.hired = -1
    end
    self:updateButtonStates()
end

function WorkerManagerFrame:findElementIndex(list, element)
    if not list or not element then return -1 end
    
    if list.elements then
        for i, elem in ipairs(list.elements) do
            if elem == element then
                return i - 1  -- Convert to 0-based index
            end
        end
    end
    return -1
end