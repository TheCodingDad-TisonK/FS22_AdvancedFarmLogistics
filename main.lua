-- =========================================================
-- Advanced Farm Logistics Manager (version 1.0.0.0)
-- =========================================================
-- Manage farm logistics with supply chains, AI workers, 
-- maintenance schedules, and logistical challenges.
-- =========================================================
-- Author: LogisticsPro
-- =========================================================
-- COPYRIGHT NOTICE:
-- All rights reserved. Unauthorized redistribution, copying,
-- or claiming this code as your own is strictly prohibited.
-- =========================================================

local modFolder = g_currentModDirectory

---@class AdvancedFarmLogistics
---@field modFolder string
AdvancedFarmLogistics = {
    settings = {
        enabled = true,
        logisticsDifficulty = 3, -- 1-5
        workerAISkill = 2, -- 1-5
        maintenanceFrequency = 30, -- days
        supplyChainComplexity = 2, -- 1-3
        
        enableWorkers = true,
        enableMaintenance = true,
        enableSupplyChain = true,
        enableLogisticsEvents = true,
        
        showNotifications = true,
        showWarnings = true,
        autoHireWorkers = false,
        autoScheduleMaintenance = true,
        
        debugLevel = 0
    },
    
    logistics = {
        supplyChains = {},
        activeDeliveries = {},
        pendingOrders = {},
        warehouseInventory = {}
    },
    
    workers = {
        hiredWorkers = {},
        availableWorkers = {},
        workerTasks = {},
        skillLevels = {}
    },
    
    maintenance = {
        equipmentSchedule = {},
        maintenanceHistory = {},
        breakdownRisk = {},
        repairCosts = {}
    },
    
    events = {
        activeEvent = nil,
        eventStartTime = 0,
        eventDuration = 0,
        eventData = {},
        cooldownUntil = 0
    },
    
    ui = {
        currentScreen = nil,
        refreshNeeded = false
    }
}

AdvancedFarmLogistics.STATE = {
    logistics = {},
    workers = {},
    maintenance = {}
}

-- =====================
-- CORE SYSTEM
-- =====================
function AdvancedFarmLogistics:getFarmId()
    return g_currentMission and g_currentMission.player and g_currentMission.player.farmId or 0
end

function AdvancedFarmLogistics:loadMap()
    ---@diagnostic disable-next-line: lowercase-global
    g_AdvancedFarmLogistics = self
    g_AdvancedFarmLogistics.modFolder = modFolder
    
    self:loadSystems()
    self:loadGUI()
    self:setupConsoleCommands()
    
    print("[AdvancedFarmLogistics] Core system loaded successfully")
    
    -- Load settings
    self:loadSettings()
    
    -- Initialize systems
    self:initializeLogistics()
    self:initializeWorkers()
    self:initializeMaintenance()
    
    -- Show welcome message
    self:showWelcomeMessage()
end

function AdvancedFarmLogistics:loadSystems()
    local systems = {
        "src/utils/LogisticsSystem.lua",
        "src/utils/WorkerAISystem.lua", 
        "src/utils/MaintenanceSystem.lua",
        "src/utils/SupplyChainManager.lua"
    }
    
    for _, system in ipairs(systems) do
        local filePath = Utils.getFilename(system, modFolder)
        if fileExists(filePath) then
            print("[AdvancedFarmLogistics] Loading system: " .. system)
            source(filePath)
            
            -- Initialize the system after loading
            if system == "src/utils/LogisticsSystem.lua" then
                if LogisticsSystem then
                    self.logisticsSystem = LogisticsSystem
                    self.logisticsSystem:initialize()
                    print("[AdvancedFarmLogistics] ✓ LogisticsSystem initialized")
                end
            elseif system == "src/utils/WorkerAISystem.lua" then
                if WorkerAISystem then
                    self.workerAISystem = WorkerAISystem
                    self.workerAISystem:initialize()
                    print("[AdvancedFarmLogistics] ✓ WorkerAISystem initialized")
                end
            elseif system == "src/utils/MaintenanceSystem.lua" then
                if MaintenanceSystem then
                    self.maintenanceSystem = MaintenanceSystem
                    self.maintenanceSystem:initialize()
                    print("[AdvancedFarmLogistics] ✓ MaintenanceSystem initialized")
                end
            elseif system == "src/utils/SupplyChainManager.lua" then
                if SupplyChainManager then
                    self.supplyChainManager = SupplyChainManager
                    self.supplyChainManager:initialize()
                    print("[AdvancedFarmLogistics] ✓ SupplyChainManager initialized")
                end
            end
        else
            print("[AdvancedFarmLogistics] Warning: System not found: " .. system)
        end
    end
end

function AdvancedFarmLogistics:loadGUI()
    print("[AdvancedFarmLogistics] Starting GUI loading...")
    
    -- First, ensure base GUI classes are available
    if not _G.TabbedMenuWithDetails then
        print("[AdvancedFarmLogistics] WARNING: TabbedMenuWithDetails not available")
    end
    
    if not _G.TabbedMenuFrameElement then
        print("[AdvancedFarmLogistics] WARNING: TabbedMenuFrameElement not available")
    end
    
    -- Create empty tables for GUI classes before loading
    _G.LogisticsDashboardFrame = {}
    _G.WorkerManagerFrame = {}
    _G.MaintenanceScheduleFrame = {}
    _G.LogisticsScreen = {}
    
    -- Load GUI Lua files first
    local guiFiles = {
        {path = "src/gui/LogisticsDashboardFrame.lua", class = 'LogisticsDashboardFrame'},
        {path = "src/gui/WorkerManagerFrame.lua", class = 'WorkerManagerFrame'},
        {path = "src/gui/MaintenanceScheduleFrame.lua", class = 'MaintenanceScheduleFrame'},
        {path = "src/gui/LogisticsScreen.lua", class = 'LogisticsScreen'}
    }
    
    for _, guiFile in ipairs(guiFiles) do
        local filePath = Utils.getFilename(guiFile.path, modFolder)
        if fileExists(filePath) then
            print("[AdvancedFarmLogistics] Loading GUI file: " .. guiFile.path)
            
            -- Clear any previous definition
            _G[guiFile.class] = nil
            
            -- Load the file
            local success, errorMsg = pcall(function()
                source(filePath)
            end)
            
            if success then
                if _G[guiFile.class] then
                    print("[AdvancedFarmLogistics] ✓ GUI class registered: " .. guiFile.class)
                else
                    print("[AdvancedFarmLogistics] ✗ Class defined but not in _G: " .. guiFile.class)
                    -- Try to find it in the global scope
                    for k, v in pairs(_G) do
                        if type(v) == "table" and v.__classname and v.__classname:find(guiFile.class) then
                            _G[guiFile.class] = v
                            print("[AdvancedFarmLogistics] ✓ Found class via __classname: " .. guiFile.class)
                            break
                        end
                    end
                end
            else
                print("[AdvancedFarmLogistics] ✗ Failed to load file: " .. errorMsg)
            end
        else
            print("[AdvancedFarmLogistics] ERROR: GUI file not found: " .. guiFile.path)
        end
    end
    
    -- Verify all classes are loaded
    local missingClasses = {}
    for _, guiFile in ipairs(guiFiles) do
        if not _G[guiFile.class] then
            table.insert(missingClasses, guiFile.class)
        end
    end
    
    if #missingClasses > 0 then
        print("[AdvancedFarmLogistics] WARNING: Missing GUI classes: " .. table.concat(missingClasses, ", "))
        print("[AdvancedFarmLogistics] Will attempt to load XML anyway...")
    end
    
    -- Load XML files after classes are registered
    local xmlFiles = {
        {path = "src/xml/LogisticsDashboardFrame.xml", ref = 'LogisticsDashboard', frameClass = 'LogisticsDashboardFrame'},
        {path = "src/xml/WorkerManagerFrame.xml", ref = 'WorkerManager', frameClass = 'WorkerManagerFrame'},
        {path = "src/xml/MaintenanceScheduleFrame.xml", ref = 'MaintenanceSchedule', frameClass = 'MaintenanceScheduleFrame'},
        {path = "src/xml/LogisticsScreen.xml", ref = 'LogisticsScreen', frameClass = 'LogisticsScreen'}
    }
    
    for _, xmlFile in ipairs(xmlFiles) do
        local filePath = Utils.getFilename(xmlFile.path, modFolder)
        if fileExists(filePath) then
            print("[AdvancedFarmLogistics] Loading XML: " .. xmlFile.path)
            
            -- Check if class exists
            if _G[xmlFile.frameClass] then
                local frameInstance
                
                if xmlFile.ref == 'LogisticsScreen' then
                    -- Main screen needs special parameters
                    frameInstance = _G[xmlFile.frameClass].new(nil, nil, g_messageCenter, g_i18n, g_inputBinding)
                    print("[AdvancedFarmLogistics] Created LogisticsScreen instance")
                else
                    -- Frame references
                    frameInstance = _G[xmlFile.frameClass].new(nil, nil)
                    print("[AdvancedFarmLogistics] Created " .. xmlFile.frameClass .. " instance")
                end
                
                if frameInstance then
                    -- Load the GUI
                    local success, result = pcall(function()
                        g_gui:loadGui(filePath, xmlFile.ref, frameInstance, xmlFile.ref ~= 'LogisticsScreen')
                    end)
                    
                    if success then
                        print("[AdvancedFarmLogistics] ✓ " .. xmlFile.ref .. " loaded successfully")
                    else
                        print("[AdvancedFarmLogistics] ✗ Failed to load " .. xmlFile.ref .. ": " .. tostring(result))
                    end
                else
                    print("[AdvancedFarmLogistics] ✗ Failed to create instance of " .. xmlFile.frameClass)
                end
            else
                print("[AdvancedFarmLogistics] ERROR: Frame class not found: " .. xmlFile.frameClass)
                print("[AdvancedFarmLogistics] Available classes in _G:")
                for k, v in pairs(_G) do
                    if type(v) == "table" then
                        print("  - " .. k)
                    end
                end
            end
        else
            print("[AdvancedFarmLogistics] ERROR: XML file not found: " .. xmlFile.path)
        end
    end
    
    print("[AdvancedFarmLogistics] GUI loading completed")
    
    -- Test if screen can be opened
    if g_gui and g_gui.guis and g_gui.guis.LogisticsScreen then
        print("[AdvancedFarmLogistics] ✓ LogisticsScreen is available in g_gui.guis")
    else
        print("[AdvancedFarmLogistics] ✗ LogisticsScreen NOT available in g_gui.guis")
        print("[AdvancedFarmLogistics] Available GUI screens:")
        for name, _ in pairs(g_gui.guis or {}) do
            print("  - " .. name)
        end
    end
end

function AdvancedFarmLogistics:setupConsoleCommands()
    if g_currentMission then
        addConsoleCommand(
            "afl",                        
            "Advanced Farm Logistics Command", 
            "onConsoleCommand",            
            AdvancedFarmLogistics              
        )
        print("[AdvancedFarmLogistics] Console command 'afl' registered")
    end
end

function AdvancedFarmLogistics:initializeLogistics()
    if self.settings.enableSupplyChain then
        print("[AdvancedFarmLogistics] Supply chain system initialized")
        -- Initialize with basic supply chains
        self.logistics.supplyChains = {
            {
                id = "seed_supply",
                name = "Seed Supply",
                status = "active",
                efficiency = 0.85
            },
            {
                id = "fuel_supply",
                name = "Fuel Supply", 
                status = "active",
                efficiency = 0.90
            },
            {
                id = "fertilizer_supply",
                name = "Fertilizer Supply",
                status = "active",
                efficiency = 0.80
            }
        }
    end
end

function AdvancedFarmLogistics:initializeWorkers()
    if self.settings.enableWorkers then
        print("[AdvancedFarmLogistics] Worker AI system initialized")
        
        -- Initialize worker pool
        self.workers.availableWorkers = {
            {
                id = "worker_001",
                name = "John Smith",
                skill = 2,
                wage = 15,
                specialty = "harvesting"
            },
            {
                id = "worker_002", 
                name = "Maria Garcia",
                skill = 3,
                wage = 20,
                specialty = "planting"
            },
            {
                id = "worker_003",
                name = "David Chen",
                skill = 1,
                wage = 12,
                specialty = "transport"
            }
        }
    end
end

function AdvancedFarmLogistics:initializeMaintenance()
    if self.settings.enableMaintenance then
        print("[AdvancedFarmLogistics] Maintenance system initialized")
        
        -- Initialize maintenance schedule
        self.maintenance.equipmentSchedule = {}
        self.maintenance.breakdownRisk = {}
    end
end

function AdvancedFarmLogistics:showWelcomeMessage()
    if g_currentMission and self.settings.showNotifications then
        g_currentMission:addIngameNotification(
            FSBaseMission.INGAME_NOTIFICATION_OK,
            "[Advanced Farm Logistics] Mod loaded - Press L to open"
        )
    end
    
    print("==============================================")
    print("Advanced Farm Logistics Manager v1.0.0.0")
    print("==============================================")
    print("Features loaded:")
    print("  • Supply Chain Management: " .. tostring(self.settings.enableSupplyChain))
    print("  • Worker AI System: " .. tostring(self.settings.enableWorkers))
    print("  • Maintenance Scheduling: " .. tostring(self.settings.enableMaintenance))
    print("  • Logistics Events: " .. tostring(self.settings.enableLogisticsEvents))
    print("==============================================")
    print("Controls: L = Open Logistics Manager")
    print("==============================================")
end

-- =====================
-- SETTINGS MANAGEMENT
-- =====================
function AdvancedFarmLogistics:loadSettings()
    local filePath = g_modSettingsDirectory .. 'AdvancedFarmLogistics.xml'
    
    if not fileExists(filePath) then
        print("[AdvancedFarmLogistics] No settings file found, using defaults")
        return
    end
    
    local xmlFile = loadXMLFile('AdvancedFarmLogistics', filePath)
    if xmlFile == nil or xmlFile == 0 then
        print('[AdvancedFarmLogistics] Failed to load settings XML')
        return
    end
    
    -- Load settings
    self.settings.enabled = Utils.getNoNil(getXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.enabled'), true)
    self.settings.logisticsDifficulty = Utils.getNoNil(getXMLInt(xmlFile, 'AdvancedFarmLogistics.settings.logisticsDifficulty'), 3)
    self.settings.workerAISkill = Utils.getNoNil(getXMLInt(xmlFile, 'AdvancedFarmLogistics.settings.workerAISkill'), 2)
    self.settings.maintenanceFrequency = Utils.getNoNil(getXMLInt(xmlFile, 'AdvancedFarmLogistics.settings.maintenanceFrequency'), 30)
    self.settings.supplyChainComplexity = Utils.getNoNil(getXMLInt(xmlFile, 'AdvancedFarmLogistics.settings.supplyChainComplexity'), 2)
    
    self.settings.enableWorkers = Utils.getNoNil(getXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.enableWorkers'), true)
    self.settings.enableMaintenance = Utils.getNoNil(getXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.enableMaintenance'), true)
    self.settings.enableSupplyChain = Utils.getNoNil(getXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.enableSupplyChain'), true)
    self.settings.enableLogisticsEvents = Utils.getNoNil(getXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.enableLogisticsEvents'), true)
    
    self.settings.showNotifications = Utils.getNoNil(getXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.showNotifications'), true)
    self.settings.showWarnings = Utils.getNoNil(getXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.showWarnings'), true)
    self.settings.autoHireWorkers = Utils.getNoNil(getXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.autoHireWorkers'), false)
    self.settings.autoScheduleMaintenance = Utils.getNoNil(getXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.autoScheduleMaintenance'), true)
    
    delete(xmlFile)
    print('[AdvancedFarmLogistics] Settings loaded successfully')
end

function AdvancedFarmLogistics:saveSettings()
    local filePath = g_modSettingsDirectory .. 'AdvancedFarmLogistics.xml'
    local xmlFile = createXMLFile('advancedFarmLogisticsSettings', filePath, 'AdvancedFarmLogistics')
    
    if xmlFile == nil or xmlFile == 0 then
        print('AdvancedFarmLogistics.saveSettings: Failed to create XML file')
        return
    end
    
    -- Save settings
    setXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.enabled', self.settings.enabled)
    setXMLInt(xmlFile, 'AdvancedFarmLogistics.settings.logisticsDifficulty', self.settings.logisticsDifficulty)
    setXMLInt(xmlFile, 'AdvancedFarmLogistics.settings.workerAISkill', self.settings.workerAISkill)
    setXMLInt(xmlFile, 'AdvancedFarmLogistics.settings.maintenanceFrequency', self.settings.maintenanceFrequency)
    setXMLInt(xmlFile, 'AdvancedFarmLogistics.settings.supplyChainComplexity', self.settings.supplyChainComplexity)
    
    setXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.enableWorkers', self.settings.enableWorkers)
    setXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.enableMaintenance', self.settings.enableMaintenance)
    setXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.enableSupplyChain', self.settings.enableSupplyChain)
    setXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.enableLogisticsEvents', self.settings.enableLogisticsEvents)
    
    setXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.showNotifications', self.settings.showNotifications)
    setXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.showWarnings', self.settings.showWarnings)
    setXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.autoHireWorkers', self.settings.autoHireWorkers)
    setXMLBool(xmlFile, 'AdvancedFarmLogistics.settings.autoScheduleMaintenance', self.settings.autoScheduleMaintenance)
    
    saveXMLFile(xmlFile)
    delete(xmlFile)
    print('[AdvancedFarmLogistics] Settings saved successfully')
end

-- =====================
-- UPDATE FUNCTION
-- =====================
function AdvancedFarmLogistics:update(dt)
    if not self.settings.enabled then
        return
    end
    
    -- Don't update systems when our screen is open to prevent conflicts
    if g_gui:getIsGuiVisible() then
        local currentGui = g_gui.currentGui
        if currentGui and currentGui.__classname and currentGui.__classname == "LogisticsScreen" then
            return -- Skip updates when our screen is open
        end
    end
    
    -- Update logistics systems
    self:updateLogistics(dt)
    self:updateWorkers(dt)
    self:updateMaintenance(dt)
    self:updateEvents(dt)
    
    -- Check for UI refresh
    if self.ui.refreshNeeded then
        self.ui.refreshNeeded = false
    end

    if self.logisticsSystem then
        self.logisticsSystem:updateDeliveries(dt)
    end
    
    if self.supplyChainManager then
        self.supplyChainManager:updatePendingOrders()
    end
    
    if self.maintenanceSystem then
        self.maintenanceSystem:checkForBreakdowns()
    end
end

function AdvancedFarmLogistics:updateLogistics(dt)
    if not self.settings.enableSupplyChain then
        return
    end
    
    -- Update supply chain efficiency
    for _, chain in ipairs(self.logistics.supplyChains) do
        if chain.status == "active" then
            -- Simulate efficiency fluctuations
            if math.random() < 0.001 then
                chain.efficiency = math.max(0.5, math.min(1.0, chain.efficiency + (math.random() - 0.5) * 0.1))
            end
        end
    end
end

function AdvancedFarmLogistics:updateWorkers(dt)
    if not self.settings.enableWorkers then
        return
    end
    
    -- Update worker tasks and performance
    for workerId, task in pairs(self.workers.workerTasks) do
        if task.status == "working" then
            -- Update task progress
            task.progress = (task.progress or 0) + (dt / 1000) * 0.1
            
            if task.progress >= 1.0 then
                task.status = "completed"
                self:completeWorkerTask(workerId, task)
            end
        end
    end
end

function AdvancedFarmLogistics:updateMaintenance(dt)
    if not self.settings.enableMaintenance then
        return
    end
    
    -- Check for equipment needing maintenance
    local currentDay = g_currentMission.environment.currentDay
    for equipmentId, schedule in pairs(self.maintenance.equipmentSchedule) do
        if schedule.nextMaintenance <= currentDay then
            self:triggerMaintenanceNeeded(equipmentId)
        end
    end
end

function AdvancedFarmLogistics:updateEvents(dt)
    if not self.settings.enableLogisticsEvents then
        return
    end
    
    -- Check for random logistics events
    if g_currentMission.time > (self.events.cooldownUntil or 0) then
        local chance = 0.0001 * self.settings.logisticsDifficulty
        if math.random() < chance then
            self:triggerLogisticsEvent()
            self.events.cooldownUntil = g_currentMission.time + (24 * 60 * 60 * 1000) -- 24 hour cooldown
        end
    end
    
    -- Update active event
    if self.events.activeEvent and g_currentMission.time > (self.events.eventStartTime + self.events.eventDuration) then
        self:endCurrentEvent()
    end
end

-- =====================
-- EVENT SYSTEM
-- =====================
function AdvancedFarmLogistics:triggerLogisticsEvent()
    local events = {
        {
            name = "supply_chain_disruption",
            probability = 0.3,
            action = function()
                -- Random supply chain disruption
                local chains = {"seed_supply", "fuel_supply", "fertilizer_supply"}
                local affectedChain = chains[math.random(1, #chains)]
                
                for _, chain in ipairs(self.logistics.supplyChains) do
                    if chain.id == affectedChain then
                        chain.efficiency = math.max(0.3, chain.efficiency * 0.7)
                        chain.status = "disrupted"
                        
                        if self.settings.showNotifications then
                            g_currentMission:addIngameNotification(
                                FSBaseMission.INGAME_NOTIFICATION_OK,
                                "Supply Chain Disruption: " .. chain.name .. " efficiency reduced!"
                            )
                        end
                        break
                    end
                end
                
                return "Supply chain disruption detected!"
            end,
            duration = 2 * 60 * 60 * 1000 -- 2 hours
        },
        {
            name = "worker_strike",
            probability = 0.2,
            action = function()
                -- Worker strike event
                if #self.workers.hiredWorkers > 0 then
                    local affectedWorkers = math.min(2, #self.workers.hiredWorkers)
                    
                    if self.settings.showNotifications then
                        g_currentMission:addIngameNotification(
                            FSBaseMission.INGAME_NOTIFICATION_OK,
                            "Worker Strike: " .. affectedWorkers .. " workers on strike!"
                        )
                    end
                    
                    return "Worker strike affecting operations!"
                end
                return nil
            end,
            duration = 1 * 60 * 60 * 1000 -- 1 hour
        },
        {
            name = "equipment_breakdown",
            probability = 0.25,
            action = function()
                -- Random equipment breakdown
                if self.settings.showNotifications then
                    g_currentMission:addIngameNotification(
                        FSBaseMission.INGAME_NOTIFICATION_OK,
                        "Equipment Breakdown: Critical machinery needs repair!"
                    )
                end
                
                return "Equipment breakdown - urgent maintenance required!"
            end,
            duration = 30 * 60 * 1000 -- 30 minutes
        },
        {
            name = "market_opportunity",
            probability = 0.25,
            action = function()
                -- Positive market opportunity
                if self.settings.showNotifications then
                    g_currentMission:addIngameNotification(
                        FSBaseMission.INGAME_NOTIFICATION_OK,
                        "Market Opportunity: Favorable prices detected!"
                    )
                end
                
                return "Market opportunity - increased profitability available!"
            end,
            duration = 3 * 60 * 60 * 1000 -- 3 hours
        }
    }
    
    -- Select random event based on probabilities
    local totalProb = 0
    for _, event in ipairs(events) do
        totalProb = totalProb + event.probability
    end
    
    local roll = math.random() * totalProb
    local cumulative = 0
    local selectedEvent = nil
    
    for _, event in ipairs(events) do
        cumulative = cumulative + event.probability
        if roll <= cumulative then
            selectedEvent = event
            break
        end
    end
    
    if selectedEvent then
        self.events.activeEvent = selectedEvent.name
        self.events.eventStartTime = g_currentMission.time
        self.events.eventDuration = selectedEvent.duration
        
        local message = selectedEvent.action()
        if message then
            print("[AdvancedFarmLogistics] Event triggered: " .. selectedEvent.name)
        end
    end
end

function AdvancedFarmLogistics:endCurrentEvent()
    if not self.events.activeEvent then
        return
    end
    
    -- Restore normal operations based on event type
    local eventName = self.events.activeEvent
    
    if eventName == "supply_chain_disruption" then
        -- Restore supply chain efficiency
        for _, chain in ipairs(self.logistics.supplyChains) do
            if chain.status == "disrupted" then
                chain.efficiency = math.min(1.0, chain.efficiency * 1.3)
                chain.status = "active"
            end
        end
        
        if self.settings.showNotifications then
            g_currentMission:addIngameNotification(
                FSBaseMission.INGAME_NOTIFICATION_OK,
                "Supply Chain Restored: Normal operations resumed"
            )
        end
        
    elseif eventName == "worker_strike" then
        -- Workers return to work
        if self.settings.showNotifications then
            g_currentMission:addIngameNotification(
                FSBaseMission.INGAME_NOTIFICATION_OK,
                "Strike Resolved: Workers have returned"
            )
        end
    end
    
    print("[AdvancedFarmLogistics] Event ended: " .. eventName)
    self.events.activeEvent = nil
end

-- =====================
-- WORKER MANAGEMENT
-- =====================
function AdvancedFarmLogistics:completeWorkerTask(workerId, task)
    -- Calculate payment and performance
    local worker = self.workers.hiredWorkers[workerId]
    if worker then
        local payment = worker.wage * (task.difficulty or 1) * (worker.skill or 1)
        g_currentMission:addMoney(-payment, self:getFarmId(), MoneyType.OTHER, true)
        
        -- Improve worker skill
        if math.random() < 0.3 then
            worker.skill = math.min(5, (worker.skill or 1) + 0.1)
        end
    end
    
    -- Remove completed task
    self.workers.workerTasks[workerId] = nil
end

function AdvancedFarmLogistics:triggerMaintenanceNeeded(equipmentId)
    if self.settings.showWarnings then
        g_currentMission:addIngameNotification(
            FSBaseMission.INGAME_NOTIFICATION_OK,
            "Maintenance Required: Equipment #" .. equipmentId .. " needs service"
        )
    end
end

-- =====================
-- INPUT/KEY CONTROLS
-- =====================
function AdvancedFarmLogistics:keyEvent(unicode, sym, modifier, isDown)
    if not isDown then
        return
    end
    
    -- Check if ESC is pressed while our screen is open
    if sym == 27 then -- ESC key
        if g_gui:getIsGuiVisible() then
            local currentGui = g_gui.currentGui
            if currentGui and currentGui.__classname and currentGui.__classname == "LogisticsScreen" then
                -- Close our screen
                currentGui:close()
                return true -- Consume the event
            end
        end
    end
    
    -- L key to open/close
    if sym == 108 then -- L key
        if g_gui:getIsGuiVisible() then
            local currentGui = g_gui.currentGui
            if currentGui and currentGui.__classname and currentGui.__classname == "LogisticsScreen" then
                -- Close if already open
                currentGui:close()
            else
                -- Open if not open
                g_gui:showGui('LogisticsScreen')
            end
        else
            -- Open if no GUI is visible
            g_gui:showGui('LogisticsScreen')
        end
        return true -- Consume the event
    end
end

-- =====================
-- CONSOLE COMMANDS
-- =====================
function AdvancedFarmLogistics:onConsoleCommand(...)
    local args = {...}
    if #args == 0 then
        print("Advanced Farm Logistics Commands:")
        print("  afl status      - Show system status")
        print("  afl workers     - List workers")
        print("  afl supply      - Show supply chains")
        print("  afl maintenance - Show maintenance schedule")
        print("  afl event       - Trigger test event")
        return true
    end
    
    local command = args[1]:lower()
    
    if command == "status" then
        self:consoleShowStatus()
    elseif command == "workers" then
        self:consoleListWorkers()
    elseif command == "supply" then
        self:consoleShowSupplyChains()
    elseif command == "maintenance" then
        self:consoleShowMaintenance()
    elseif command == "event" then
        self:triggerLogisticsEvent()
        print("[AFL-Console] Test event triggered")
    else
        print("[AFL-Console] Unknown command: " .. command)
    end
    
    return true
end

function AdvancedFarmLogistics:consoleShowStatus()
    print("=========================================")
    print("Advanced Farm Logistics - Status")
    print("=========================================")
    print("System: " .. (self.settings.enabled and "ENABLED" or "DISABLED"))
    print("Active Event: " .. (self.events.activeEvent or "None"))
    print("Hired Workers: " .. #self.workers.hiredWorkers)
    print("Active Supply Chains: " .. #self.logistics.supplyChains)
    print("Pending Maintenance: " .. self:countPendingMaintenance())
    print("=========================================")
end

function AdvancedFarmLogistics:consoleListWorkers()
    print("=========================================")
    print("Workers - Hired: " .. #self.workers.hiredWorkers)
    print("=========================================")
    
    for _, worker in ipairs(self.workers.hiredWorkers) do
        print(string.format("  %s - Skill: %d, Wage: $%d/hr", 
            worker.name, worker.skill, worker.wage))
    end
    
    print("=========================================")
    print("Available Workers: " .. #self.workers.availableWorkers)
    print("=========================================")
end

function AdvancedFarmLogistics:consoleShowSupplyChains()
    print("=========================================")
    print("Supply Chains")
    print("=========================================")
    
    for _, chain in ipairs(self.logistics.supplyChains) do
        print(string.format("  %s - Status: %s, Efficiency: %.0f%%", 
            chain.name, chain.status, chain.efficiency * 100))
    end
    
    print("=========================================")
end

function AdvancedFarmLogistics:consoleShowMaintenance()
    print("=========================================")
    print("Maintenance Schedule")
    print("=========================================")
    
    local pending = 0
    for _, schedule in pairs(self.maintenance.equipmentSchedule) do
        local daysRemaining = schedule.nextMaintenance - g_currentMission.environment.currentDay
        if daysRemaining <= 7 then
            print(string.format("  Equipment #%d - Due in %d days (URGENT)", 
                schedule.equipmentId, daysRemaining))
            pending = pending + 1
        end
    end
    
    if pending == 0 then
        print("  All maintenance up to date")
    end
    
    print("=========================================")
end

function AdvancedFarmLogistics:countPendingMaintenance()
    local count = 0
    local currentDay = g_currentMission.environment.currentDay
    
    for _, schedule in pairs(self.maintenance.equipmentSchedule) do
        if schedule.nextMaintenance <= currentDay + 7 then
            count = count + 1
        end
    end
    
    return count
end

-- =====================
-- REGISTRATION
-- =====================
addModEventListener(AdvancedFarmLogistics)