-- =========================================================
-- Logistics Screen
-- =========================================================
-- Main screen for the Advanced Farm Logistics Manager
-- =========================================================

---@class LogisticsScreen
---@field pageLogisticsDashboard LogisticsDashboardFrame
---@field pageWorkerManager WorkerManagerFrame
---@field pageMaintenanceSchedule MaintenanceScheduleFrame
LogisticsScreen = {}
local LogisticsScreen_mt = Class(LogisticsScreen, TabbedMenuWithDetails)

LogisticsScreen.CONTROLS = {
    'pageLogisticsDashboard',
    'pageWorkerManager',
    'pageMaintenanceSchedule'
}

function LogisticsScreen.new(target, customMt, messageCenter, l10n, inputManager)
    local self = TabbedMenuWithDetails.new(target, customMt or LogisticsScreen_mt, messageCenter, l10n, inputManager)

    self:registerControls(LogisticsScreen.CONTROLS)

    return self
end

function LogisticsScreen:onGuiSetupFinished()
    LogisticsScreen:superClass().onGuiSetupFinished(self)

    self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)

    self:setupPages()
    self:setupMenuButtonInfo()
end

function LogisticsScreen:setupPages()
    -- Create page data with proper initialization
    local pages = {}
    
    -- Check if dashboard frame exists and is valid
    if self.pageLogisticsDashboard ~= nil then
        table.insert(pages, {
            frame = self.pageLogisticsDashboard,
            icon = 'dashboard.dds',
            title = 'Dashboard'
        })
    else
        print("[LogisticsScreen] Warning: pageLogisticsDashboard is nil")
    end
    
    -- Check if worker manager frame exists
    if self.pageWorkerManager ~= nil then
        table.insert(pages, {
            frame = self.pageWorkerManager,
            icon = 'workers.dds',
            title = 'Workers'
        })
    else
        print("[LogisticsScreen] Warning: pageWorkerManager is nil")
    end
    
    -- Check if maintenance frame exists
    if self.pageMaintenanceSchedule ~= nil then
        table.insert(pages, {
            frame = self.pageMaintenanceSchedule,
            icon = 'maintenance.dds',
            title = 'Maintenance'
        })
    else
        print("[LogisticsScreen] Warning: pageMaintenanceSchedule is nil")
    end
    
    -- Register each valid page
    for i, pageData in ipairs(pages) do
        local frame = pageData.frame
        
        -- Initialize the frame if it has an initialize method
        if frame.initialize then
            frame:initialize()
        end
        
        self:registerPage(frame, i)
        
        -- Try to load icon, use default if not found
        if g_AdvancedFarmLogistics and g_AdvancedFarmLogistics.modFolder then
            local iconPath = g_AdvancedFarmLogistics.modFolder .. 'src/icons/' .. pageData.icon
            if fileExists(iconPath) then
                self:addPageTab(frame, iconPath)
            else
                -- Use default icon or text
                self:addPageTab(frame, pageData.title)
                print("[LogisticsScreen] Icon not found: " .. iconPath)
            end
        else
            -- Fallback to text if mod folder not available
            self:addPageTab(frame, pageData.title)
            print("[LogisticsScreen] Using text for tab: " .. pageData.title)
        end
    end
    
    -- If no pages were loaded, show error
    if #pages == 0 then
        print("[LogisticsScreen] ERROR: No pages loaded!")
        g_gui:showInfoDialog({
            text = "Logistics Manager Error: No pages could be loaded.",
            dialogType = DialogElement.TYPE_ERROR
        })
    end
end

function LogisticsScreen:setupMenuButtonInfo()
    local onButtonBackFunction = self.clickBackCallback
    self.defaultMenuButtonInfo = {
        {
            inputAction = InputAction.MENU_BACK,
            text = self.l10n:getText("button_back"),
            callback = onButtonBackFunction
        }
    }
    self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
    self.defaultButtonActionCallbacks = {
        [InputAction.MENU_BACK] = onButtonBackFunction,
    }
end

function LogisticsScreen:onButtonBack()
    -- Prevent multiple calls
    if self.isClosing then
        return
    end
    
    self.isClosing = true
    self:close()
end

function LogisticsScreen:close()
    if not self.isClosing then
        self.isClosing = true
    end
    
    -- Use the parent class method to close properly
    if self.exitMenu then
        self:exitMenu()
    else
        g_gui:closeDialogByName("LogisticsScreen")
    end
    print("[LogisticsScreen] Screen closing...")
end

function LogisticsScreen:onOpen()
    LogisticsScreen:superClass().onOpen(self)
    
    -- Reset closing flag
    self.isClosing = false
    
    -- Set current screen reference
    if g_AdvancedFarmLogistics then
        g_AdvancedFarmLogistics.ui.currentScreen = self
    end
    
    -- Refresh data when opening
    if self.pageLogisticsDashboard and self.pageLogisticsDashboard.refreshData then
        self.pageLogisticsDashboard:refreshData()
    end
    if self.pageWorkerManager and self.pageWorkerManager.refreshData then
        self.pageWorkerManager:refreshData()
    end
    if self.pageMaintenanceSchedule and self.pageMaintenanceSchedule.refreshData then
        self.pageMaintenanceSchedule:refreshData()
    end
    
    print("[LogisticsScreen] Screen opened successfully")
end

function LogisticsScreen:onClose()
    LogisticsScreen:superClass().onClose(self)
    if g_AdvancedFarmLogistics then
        g_AdvancedFarmLogistics.ui.currentScreen = nil
    end
    self.isClosing = false
    print("[LogisticsScreen] Screen closed")
end

-- Make sure frames are accessible
function LogisticsScreen:getFrameByName(frameName)
    if frameName == "LogisticsDashboard" then
        return self.pageLogisticsDashboard
    elseif frameName == "WorkerManager" then
        return self.pageWorkerManager
    elseif frameName == "MaintenanceSchedule" then
        return self.pageMaintenanceSchedule
    end
    return nil
end