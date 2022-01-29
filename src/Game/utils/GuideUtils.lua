--[[
 * author : kaishiqi
 * descpt : Guide工具类
]]
GuideUtils = {}


--[[
    引导的所有模块的定义
]]
GUIDE_MODULES = {
    MODULE_LOBBY        = 1,    -- 餐厅
    MODULE_DRAWCARD     = 2,    -- 抽卡
    MODULE_TEAM         = 3,    -- 编队
    MODULE_ACCEPT_STORY = 100,  -- 接任务
    MODULE_FINISH_STORY = 101,  -- 领任务
    MODULE_DISCOVERY    = 102,  -- 制作菜品
    MODULE_PET          = 103,  -- 堕神
    MODULE_TALENT       = 1000, -- 天赋
    MODULE_WORLDMAP     = 1001, -- 世界地图
    MODULE_AVATAR       = 1002, -- 餐厅装修
}


--[[
    开放功能类型
]]
GUIDE_ENABLE_FUNC = {

    -- 主界面 上方功能区 普通功能
    HOME_FUNC_BAR_NORMAL = {
        'CheckIsinitCookingStyle',
        'CheckIsHaveSixCards',
        'CheckIsFirstTeamMember',
        'CheckIsFinishedQuest1',
        'CheckIsFinishedStorytPlot1',
        'CheckIsFinishedQuest2',
    },

    -- 主界面 下方功能区 切换功能
    HOME_FUNC_SLIDER_SLIDER = {
        'CheckIsinitCookingStyle',
        'CheckIsHaveSixCards',
        'CheckIsFirstTeamMember',
        'CheckIsFinishedQuest1',
        'CheckIsFinishedStorytPlot1',
        'CheckIsFinishedQuest2',
    },
    -- 主界面 下方功能区 召唤功能
    HOME_FUNC_SLIDER_CAPSULE = {
        'CheckIsinitCookingStyle'
    },

    -- 主界面 下方功能区 编队功能
    HOME_FUNC_SLIDER_TEAMS = {
        'CheckIsinitCookingStyle',
        'CheckIsHaveSixCards'
    },

    -- 主界面 下方功能区 飨灵功能
    HOME_FUNC_SLIDER_CARDS = {
        'CheckIsinitCookingStyle',
        'CheckIsHaveSixCards',
        'CheckIsFirstTeamMember',
        'CheckIsFinishedQuest1',
        'CheckIsFinishedStorytPlot1',
        'CheckIsFinishedQuest2',
    },

    -- 主界面 主线任务功能
    HOME_SCENE_TASK = {
        'CheckIsinitCookingStyle',
        'CheckIsHaveSixCards',
        'CheckIsFirstTeamMember',
        'CheckIsFinishedQuest1'
    },

    -- 主界面 扩展面板 普通功能
    HOME_EXTRA_PANEL_NORMAL = {
        'CheckIsinitCookingStyle',
        'CheckIsHaveSixCards',
        'CheckIsFirstTeamMember',
        'CheckIsFinishedQuest1',
        'CheckIsFinishedStorytPlot1',
        'CheckIsFinishedQuest2',
    },

    -- 主界面 地图面板 普通关卡
    HOME_MAP_PANEL_NORMAL_QUEST = {
        'CheckIsinitCookingStyle',
        'CheckIsHaveSixCards',
        'CheckIsFirstTeamMember'
    },

    -- 餐厅 成员管理界面
    RESTAURANT_PEOPLE_MANAGEMENT = {
        'CheckIsHaveSixCards',
        'CheckIsFirstTeamMember',
        'CheckIsFinishedQuest1',
        'CheckIsFinishedStorytPlot1',
        'CheckIsFinishedQuest2',
    },
}

GuideUtils.GUIDE_VIEW_SIZE     = cc.size(988, 645)

function GuideUtils.GetDirector()
    return require('Frame.lead_visitor.LDirector').GetInstance()
end


function GuideUtils.DispatchStepEvent()
    AppFacade.GetInstance():DispatchObservers(GUIDE_STEP_EVENT_SYSTEM)
end


--[[
    是否 引导进行中
]]
function GuideUtils.IsGuiding()
    return GuideUtils.GetDirector():IsInGuiding() == true
end


--[[
    获取 正在进行的引导ID
]]
function GuideUtils.GetGuidingId()
    return checkint(GuideUtils.GetDirector().moduleId)
end


--[[
    是否 拥有指定模块数据
    @see GUIDE_MODULES
]]
function GuideUtils.HasModule(moduleId)
    return GuideUtils.GetDirector():FirstModule(moduleId) == true
end


--[[
    切到指定引导模块
    @see GUIDE_MODULES
]]
function GuideUtils.SwitchModule(moduleId, jumpStepId)
    GuideUtils.GetDirector():SwitchModule(moduleId, jumpStepId)
end


--[[
    清空指定模块数据
    @see GUIDE_MODULES
]]
function GuideUtils.ClearModuleData(moduleId)
    GuideUtils.GetDirector():ClearModuleData(moduleId)
end


--[[
    获取 指定模块数据
    @see GUIDE_MODULES
]]
function GuideUtils.GetModuleData(moduleId)
    return GuideUtils.GetDirector():GetModuleData(moduleId)
end


--[[
    开启 显示跳过按钮
]]
function GuideUtils.EnableShowSkip()
    GuideUtils.GetDirector():PublicShowSkip()
end


--[[
    强制 显示跳过按钮
]]
function GuideUtils.ForceShowSkip()
    GuideUtils.GetDirector():PublicForceSkip()
end


-------------------------------------------------

--[[
    根据功能开放定义，检测某项功能是否已启用
    @see GUIDE_ENABLE_FUNC
]]
function GuideUtils.CheckFuncEnabled(funcDefine, checkDataMap)
    -- for _, checkFuncName in ipairs(funcDefine or {}) do
    --     if GuideUtils[checkFuncName] then
    --         if not GuideUtils[checkFuncName](checkDataMap) then
    --             return false
    --         end
    --     end
    -- end
    return true
end


function GuideUtils.CheckIsinitCookingStyle(checkDataMap)
    -- if app.cookingMgr:isUninitCookingStyle() then
    --     app.uiMgr:ShowInformationTips(__('请先前往【餐厅】逛逛~'))
    --     return false
    -- end
    return true
end


function GuideUtils.CheckHaveRestaurantManagementMember(checkDataMap)
    -- local restaurantChefNum   = table.nums(app.gameMgr:GetUserInfo().chef)
    -- local restaurantWaiterNum = table.nums(app.gameMgr:GetUserInfo().waiter)
    -- if restaurantChefNum <= 0 and restaurantWaiterNum <= 0 then
    --     return false
    -- end
    return true
end


function GuideUtils.CheckIsHaveSixCards(checkDataMap)
    -- local CHECK_CARDS_NUM = 6
    -- local haveCardsNum    = table.nums(app.gameMgr:GetUserInfo().cards)
    -- if haveCardsNum < CHECK_CARDS_NUM then
    --     if not checkDataMap or not checkDataMap.dontShowTips then
    --         app.uiMgr:AddNewCommonTipDialog({
    --             text     = string.fmt(__('请先前往【召唤】逛逛~\n您拥有的飨灵少于_num_个'), {_num_ = CHECK_CARDS_NUM}),
    --             isOnlyOK = true,
    --             callback = function()
    --                 app.router:Dispatch({name = 'HomeMediator'}, {name = 'drawCards.CapsuleMediator'})
    --             end
    --         })
    --     end
    --     return false
    -- end
    return true
end


function GuideUtils.CheckIsFirstTeamMember(checkDataMap)
    -- local CHECK_CARDS_NUM = 4
    -- local teamCardsInfo   = app.gameMgr:getTeamCardsInfo(1) or {}
    -- local teamCardIdList  = table.valuesAt(teamCardsInfo, 'id')
    -- if app.gameMgr:GetUserInfo().newestQuestId <= 1 then
    --     if #teamCardIdList < CHECK_CARDS_NUM then
    --         if not checkDataMap or not checkDataMap.dontShowTips then
    --             app.uiMgr:AddNewCommonTipDialog({
    --                 text     = string.fmt(__('请先前往【编队】逛逛~\n将第一编队组成_num_人小队'), {_num_ = CHECK_CARDS_NUM}),
    --                 isOnlyOK = true,
    --                 callback = function()
    --                     app.router:Dispatch({name = 'HomeMediator'}, {name = 'TeamFormationMediator', params = checkDataMap})
    --                 end
    --             })
    --         end
    --         return false
    --     end
    -- end
    return true
end


function GuideUtils.CheckIsFinishedQuest1(checkDataMap)
    -- if app.gameMgr:GetUserInfo().newestQuestId <= 1 then
    --     if not checkDataMap or not checkDataMap.dontShowTips then
    --         local areaPointConf = CommonUtils.GetConfig('common', 'areaFixedPoint', 1) or {}
    --         app.uiMgr:AddNewCommonTipDialog({
    --             text     = string.fmt(__('请先前往【_name_】逛逛~\n您需要打通1-1关卡'), {_name_ = tostring(areaPointConf.name)}),
    --             isOnlyOK = true,
    --             callback = function()
    --                 -- reset cache data
    --                 app.gameMgr:UpdatePlayer({localCurrentQuestId = 0})
    --                 app.router:Dispatch({name = 'HomeMediator'}, {name = 'MapMediator', params = {currentAreaId = 1}})
    --             end
    --         })
    --     end
    --     return false
    -- end
    return true
end


function GuideUtils.CheckIsFinishedStorytPlot1(checkDataMap)
    -- if app.gameMgr:GetUserInfo().newestQuestId <= CONDITION_LEVELS.ACCEPT_STORY_TASK then
    --     local CHECK_QUEST_ID = 1
    --     local newestPlotTask = app.gameMgr:GetUserInfo().newestPlotTask or {}
    --     if checkint(newestPlotTask.taskId) <= CHECK_QUEST_ID and checkint(newestPlotTask.status) <= 1 then -- status (1 未接受 2 未完成 3 已完成)
    --         if not checkDataMap or not checkDataMap.dontShowTips then
    --             local questPlotConf = CommonUtils.GetConfig('quest', 'questPlot', CHECK_QUEST_ID) or {}
    --             app.uiMgr:AddNewCommonTipDialog({
    --                 text     = string.fmt(__('请先前往【任务】逛逛~\n接受任务【_name_】'), {_name_ = tostring(questPlotConf.name)}),
    --                 isOnlyOK = true,
    --                 callback = function()
    --                     app.router:Dispatch({name = 'HomeMediator'}, {name = 'StoryMissionsMediator'})
    --                 end
    --             })
    --         end
    --         return false
    --     end
    -- end
    return true
end


function GuideUtils.CheckIsFinishedQuest2(checkDataMap)
    -- if app.gameMgr:GetUserInfo().newestQuestId <= 2 then
    --     if not checkDataMap or not checkDataMap.dontShowTips then
    --         local areaPointConf = CommonUtils.GetConfig('common', 'areaFixedPoint', 1) or {}
    --         app.uiMgr:AddNewCommonTipDialog({
    --             text     = string.fmt(__('请先前往【_name_】逛逛~\n您需要打通1-2关卡'), {_name_ = tostring(areaPointConf.name)}),
    --             isOnlyOK = true,
    --             callback = function()
    --                 -- reset cache data
    --                 app.gameMgr:UpdatePlayer({localCurrentQuestId = 0})
    --                 app.router:Dispatch({name = 'HomeMediator'}, {name = 'MapMediator', params = {currentAreaId = 1}})
    --             end
    --         })
    --     end
    --     return false
    -- end
    return true
end