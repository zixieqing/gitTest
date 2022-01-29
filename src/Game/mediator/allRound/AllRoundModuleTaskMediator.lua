---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2018/10/15 2:07 PM
---
--[[
扭蛋系统mediator
--]]
local Mediator                      = mvc.Mediator

---@type UIManager
local uiMgr =  app.uiMgr
local gameMgr = app.gameMgr
---@class AllRoundModuleTaskMediator :Mediator
local AllRoundModuleTaskMediator = class("AllRoundModuleTaskMediator", Mediator)
local NAME                          = "AllRoundModuleTaskMediator"
local BUTTON_TAG                    = {
    CLOSE_VIEW = 11001 ,
    TIP_BUTTON = 11002 ,
}
local ALL_CARD_TASK_TYPE = {
    USE_TARGET_NUM_CASH_COW_TASKS                = 1, -- 使用_target_num_次摇钱树
    SUMMON_TARGET_NUM_TIME_CARD_TASKS            = 2, -- 召唤_target_num_次卡牌
    UPGRADE_PET_NUM_TASKS                        = 6, -- 升级任意堕神_target_num_次
    RESTAURANTS_GUSET_NUM_TASKS                  = 7, -- 餐厅招待_target_num_个客人
    COMPLETE_TAKEAWAY_ORDER_TASKS                = 8, -- 完成外卖订单_target_num_次
    COMPLETE_EXPLORE_TASKS                       = 9, -- 完成_target_num_次探索
    PLAYER_LEVEL_TASKS                           = 12, -- 主角等级达到_target_num_
    COLLOECT_PET_NUM_TASKS                       = 13, -- 收集_target_num_个堕灵
    COMPLETE_NORMAL_QUEST_TASKS                  = 14, -- 通关普通关卡_target_num_（关卡ID）
    USE_ANY_EXP_WATER_TASKS                      = 16, -- 使用任意经验药水_target_num_次
    COMPLETE_HARD_QUEST_TASKS                    = 20, -- 通关困难关卡_target_num_（关卡ID）
    IMPROVE_RESTAURANTS_LEVEL_TASKS              = 25, -- 提升餐厅规模至_target_num_
    IMPROVE_RECIPE_NUM_TASKS                     = 26, -- 改良任意菜品_target_num_道
    COLLECT_PET_EGGS_NUM_TASKS                   = 28, -- 收集_target_num_个灵体
    PURIFICATION_PET_EGG_NUM_TASKS               = 29, -- 净化_target_num_个灵体
    COMPLETE_TOWER_NUM_TASKS                     = 31, -- 通关第_target_num_层邪神遗迹
    TO_OVERCOME_OVERLORD_MEAL_NUM_TASKS          = 34, -- 餐厅中战胜_target_num_个吃霸王餐的顾客
    RESTAURANTS_COMPLETE_NUM_TASKS               = 35, -- 餐厅中完成_target_num_个任务
    CUMULATIVE_CUSTOMS_CLEARANCE_TOWER_NUM_TASKS = 41, -- 累计通关邪神遗迹_target_num_层
    COMPLETE_AIRS_NUM_TASKS                      = 47, -- 完成空运_target_num_次
    GOD_TARGET_ID_PET_IMPROVED_LEVEL_TASKS       = 48, -- 将_target_id_个堕神升至_target_num_级
    AREANA_BATTLE_NUMS_TASKS                     = 50, -- 竞技场战斗_target_num_次
    AREANA_BATTLE_WIN_NUMS_TASKS                 = 51, -- 竞技场获胜_target_num_次
    COMPLETE_MATERIAL_COPY_NUM_TASKS             = 87, -- 完成_target_num_次学院补给
    LOGIN_NUM_TASKS                              = 114, -- 累计登陆_target_num_次
    USE_DIAMOND_TASKS                            = 115, -- 累计使用_target_num_个钻石
    COMPLETE_DAILY_TASKS                         = 116, -- 累计完成_target_num_次日常任务
    SWEEP_TOWER_TASKS                            = 117, -- 累计扫荡_target_num_层邪神遗迹
    SERVE_PRIVATE_ROOM_GUEST_TASKS               = 118, -- 包厢招待_target_num_名客人
    FISH_REWARDS_NUM_TASKS                       = 119, -- 钓鱼场收货_target_num_次
    RESTAURANTS_SELL_RECIPE_NUM_TASKS            = 120, -- 餐厅出售_target_num_份食物
    WATERING_PET_EGGS_NUM_TASKS                  = 121, -- 浇灌_target_num_次灵体
    STRENGTHENING_PET_NUM_TASKS                  = 122, -- 累计强化堕神_target_num_次
    EVOLUTION_PET_NUM_TASKS                      = 123, -- 异化堕神_target_num_次
    ADD_UP_BIRTH_PET_NUM_TASKS                   = 124, -- 累计再生堕神_target_num_次
}
local  MODULE_TO_DATA = {
    [tostring(ALL_CARD_TASK_TYPE.SUMMON_TARGET_NUM_TIME_CARD_TASKS)] = {
        jumpView = "drawCards.CapsuleNewMediator",
        openType = JUMP_MODULE_DATA.CAPSULE
    },
    [tostring(ALL_CARD_TASK_TYPE.UPGRADE_PET_NUM_TASKS)] = {
        jumpView = "PetDevelopMediator",
        openType = JUMP_MODULE_DATA.PET
    },
    [tostring(ALL_CARD_TASK_TYPE.RESTAURANTS_GUSET_NUM_TASKS)] = {
        jumpView = "AvatarMediator",
        openType = JUMP_MODULE_DATA.RESTAURANT
    },
    [tostring(ALL_CARD_TASK_TYPE.COMPLETE_TAKEAWAY_ORDER_TASKS)] = {
        jumpView = "HomeMediator",
        openType = JUMP_MODULE_DATA.PUBLIC_ORDER
    },
    [tostring(ALL_CARD_TASK_TYPE.COMPLETE_EXPLORE_TASKS)] = {
        jumpView = "exploreSystem.ExploreSystemMediator",
        openType = JUMP_MODULE_DATA.EXPLORE_SYSTEM
    },
    [tostring(ALL_CARD_TASK_TYPE.COLLOECT_PET_NUM_TASKS)] = {
        jumpView = "PetDevelopMediator",
        openType = JUMP_MODULE_DATA.PET
    },
    [tostring(ALL_CARD_TASK_TYPE.COMPLETE_NORMAL_QUEST_TASKS)] = {
        jumpView = "MapMediator",
        openType = JUMP_MODULE_DATA.NORMAL_MAP
    },
    [tostring(ALL_CARD_TASK_TYPE.COMPLETE_HARD_QUEST_TASKS)] = {
        jumpView = "MapMediator",
        openType = JUMP_MODULE_DATA.DIFFICULTY_MAP
    },
    [tostring(ALL_CARD_TASK_TYPE.IMPROVE_RESTAURANTS_LEVEL_TASKS)] = {
        jumpView = "AvatarMediator",
        openType = JUMP_MODULE_DATA.RESTAURANT
    },
    [tostring(ALL_CARD_TASK_TYPE.IMPROVE_RECIPE_NUM_TASKS)] = {
        jumpView = "RecipeResearchAndMakingMediator",
        openType = JUMP_MODULE_DATA.RESEARCH
    },
    [tostring(ALL_CARD_TASK_TYPE.COLLECT_PET_EGGS_NUM_TASKS)] = {
        jumpView = "TowerQuestHomeMediator",
        openType = JUMP_MODULE_DATA.TOWER
    },
    [tostring(ALL_CARD_TASK_TYPE.PURIFICATION_PET_EGG_NUM_TASKS)] = {
        jumpView = "PetDevelopMediator",
        openType = JUMP_MODULE_DATA.PET
    },
    [tostring(ALL_CARD_TASK_TYPE.COMPLETE_TOWER_NUM_TASKS)] = {
        jumpView = "TowerQuestHomeMediator",
        openType = JUMP_MODULE_DATA.TOWER
    },
    [tostring(ALL_CARD_TASK_TYPE.TO_OVERCOME_OVERLORD_MEAL_NUM_TASKS)] = {
        jumpView = "AvatarMediator",
        openType = JUMP_MODULE_DATA.RESTAURANT
    },
    [tostring(ALL_CARD_TASK_TYPE.RESTAURANTS_COMPLETE_NUM_TASKS)] = {
        jumpView = "AvatarMediator",
        openType = JUMP_MODULE_DATA.RESTAURANT
    },
    [tostring(ALL_CARD_TASK_TYPE.RESTAURANTS_COMPLETE_NUM_TASKS)] = {
        jumpView = "AvatarMediator",
        openType = JUMP_MODULE_DATA.RESTAURANT
    },
    [tostring(ALL_CARD_TASK_TYPE.CUMULATIVE_CUSTOMS_CLEARANCE_TOWER_NUM_TASKS)] = {
        jumpView = "TowerQuestHomeMediator",
        openType = JUMP_MODULE_DATA.TOWER
    },
    [tostring(ALL_CARD_TASK_TYPE.COMPLETE_AIRS_NUM_TASKS)] = {
        jumpView = "HomeMediator",
        openType = JUMP_MODULE_DATA.AIR_TRANSPORTATION
    },
    [tostring(ALL_CARD_TASK_TYPE.GOD_TARGET_ID_PET_IMPROVED_LEVEL_TASKS)] = {
        jumpView = "PetDevelopMediator",
        openType = JUMP_MODULE_DATA.PET
    },
    [tostring(ALL_CARD_TASK_TYPE.AREANA_BATTLE_NUMS_TASKS)] = {
        jumpView = "PVCMediator",
        openType = JUMP_MODULE_DATA.PVC_ROYAL_BATTLE
    },
    [tostring(ALL_CARD_TASK_TYPE.AREANA_BATTLE_WIN_NUMS_TASKS)] = {
        jumpView = "PVCMediator",
        openType = JUMP_MODULE_DATA.PVC_ROYAL_BATTLE
    },
    [tostring(ALL_CARD_TASK_TYPE.COMPLETE_MATERIAL_COPY_NUM_TASKS)] = {
        jumpView = "MaterialTranScriptMediator",
        openType = JUMP_MODULE_DATA.MATERIAL_SCRIPT
    },
    [tostring(ALL_CARD_TASK_TYPE.COMPLETE_DAILY_TASKS)] = {
        jumpView = "HomeMediator",
        openType = JUMP_MODULE_DATA.DAILYTASK
    },
    [tostring(ALL_CARD_TASK_TYPE.SWEEP_TOWER_TASKS)] = {
        jumpView = "TowerQuestHomeMediator",
        openType = JUMP_MODULE_DATA.TOWER

    },
    [tostring(ALL_CARD_TASK_TYPE.SERVE_PRIVATE_ROOM_GUEST_TASKS)] = {
        jumpView = "privateRoom.PrivateRoomHomeMediator",
        openType = JUMP_MODULE_DATA.BOX
    },
    [tostring(ALL_CARD_TASK_TYPE.FISH_REWARDS_NUM_TASKS)] = {
        jumpView = "fishing.FishingGroundMediator",
        openType = JUMP_MODULE_DATA.FISHING_GROUND ,
        params = {queryPlayerId =app.gameMgr:GetUserInfo().playerId }
    },
    [tostring(ALL_CARD_TASK_TYPE.RESTAURANTS_SELL_RECIPE_NUM_TASKS)] = {
        jumpView = "AvatarMediator",
        openType = JUMP_MODULE_DATA.RESTAURANT
    },
    [tostring(ALL_CARD_TASK_TYPE.WATERING_PET_EGGS_NUM_TASKS)] = {
        jumpView = "PetDevelopMediator",
        openType = JUMP_MODULE_DATA.PET
    },
    [tostring(ALL_CARD_TASK_TYPE.STRENGTHENING_PET_NUM_TASKS)] = {
        jumpView = "PetDevelopMediator",
        openType = JUMP_MODULE_DATA.PET
    },
    [tostring(ALL_CARD_TASK_TYPE.EVOLUTION_PET_NUM_TASKS)] = {
        jumpView = "PetDevelopMediator",
        openType = JUMP_MODULE_DATA.PET
    },
    [tostring(ALL_CARD_TASK_TYPE.ADD_UP_BIRTH_PET_NUM_TASKS)] = {
        jumpView = "PetDevelopMediator",
        openType = JUMP_MODULE_DATA.PET
    } ,

}

local MODULE_MEDIATOR = {
    [tostring(JUMP_MODULE_DATA.TALENT_CONTROL)]     = {
        jumpView = "TalentMediator"
    },
    [tostring(JUMP_MODULE_DATA.MONEYTREE)]          = { jumpView = "HomeMediator", },
    [tostring(JUMP_MODULE_DATA.AIR_TRANSPORTATION)] = { jumpView = "HomeMediator", },
    [tostring(JUMP_MODULE_DATA.EXPLORE_SYSTEM)]     = { jumpView = "exploreSystem.ExploreSystemMediator" },
    [tostring(JUMP_MODULE_DATA.ARENA)]              = { jumpView = "PVCMediator", },
    [tostring(JUMP_MODULE_DATA.TOWER)]              = { jumpView = "TowerQuestHomeMediator", },
    [tostring(JUMP_MODULE_DATA.PET)]                = { jumpView = "PetDevelopMediator", },
    [tostring(JUMP_MODULE_DATA.BOX)]                = { jumpView = "privateRoom.PrivateRoomHomeMediator", },
    [tostring(JUMP_MODULE_DATA.FISHING_GROUND)]     = { jumpView = "fishing.FishingGroundMediator", params = { queryPlayerId = app.gameMgr:GetUserInfo().playerId } },
    [tostring(JUMP_MODULE_DATA.RESTAURANT)]         = { jumpView = "AvatarMediator", },
    [tostring(JUMP_MODULE_DATA.MATERIAL_SCRIPT)]    = { jumpView = "MaterialTranScriptMediator", },
    [tostring(JUMP_MODULE_DATA.RESEARCH)]           = { jumpView = "RecipeResearchAndMakingMediator", },
    [tostring(JUMP_MODULE_DATA.PVC_ROYAL_BATTLE)]   = { jumpView = "PVCMediator", }
}
--==============================--
---@Description: TODO
---@author : xingweihao
---@date : 2018/10/13 10:22 AM
--==============================--
local taskConfig = CommonUtils.GetConfigAllMess('task', 'cardCall')
function AllRoundModuleTaskMediator:ctor(param, viewComponent)
    self.super:ctor(NAME, viewComponent)
    self.isGoto = false
    self.routeData = param.routeData
    self.routeKeysData = self:GetRoutKesData()
    self.currentData = self:GetCurrentRountData()
    self:SortFunction()
end
function AllRoundModuleTaskMediator:GetRoutKesData()
    local routeKeysData = {}
    for i, v in ipairs(self.routeData.tasks) do
        routeKeysData[tostring(v.taskId)] = v
    end
    return routeKeysData
end
function AllRoundModuleTaskMediator:GetCurrentRountData()
    local routerConfig = CommonUtils.GetConfigAllMess('route' ,'cardCall')
    local groupConfig  = CommonUtils.GetConfigAllMess('group' ,'cardCall')
    local routerOneConfig = routerConfig[tostring(self.routeData.routeId)]
    local currentData = {}
    for k, v in pairs(routerOneConfig) do
        local groupData = groupConfig[tostring(v)] or {}
        local isHave = false
        for i = 1, table.nums(groupData) do
            local taskId = groupData[tostring(i)]
            local taskData = self.routeKeysData[tostring(taskId)]
            if taskData and  checkint(taskData.hasDrawn) == 0  then
                local data = clone( self.routeKeysData[tostring(taskId)])
                data.difficulty = i  -- 难度
                data.kind = k
                currentData[#currentData+1] = data
                isHave = true
                break
            end
        end
        if not  isHave then
            local count =  table.nums(groupData)
            local taskId = groupData[tostring(count)]
            local data = clone( self.routeKeysData[tostring(taskId)])
            if data then
                data.difficulty = count   -- 难度
                data.kind = k
                currentData[#currentData+1] = data
            end
        end
    end
    return currentData
end
function AllRoundModuleTaskMediator:InterestSignals()
    local signals = {
        POST.CARD_CALL_DRAW_TASK_REWARD.sglName ,
    }
    return signals
end

function AllRoundModuleTaskMediator:ProcessSignal(signal)
    local data  = signal:GetBody()
    local name = signal:GetName()
    if name == POST.CARD_CALL_DRAW_TASK_REWARD.sglName then
        self:DrawTaskRequestCallBack(data)
    end

end
function AllRoundModuleTaskMediator:DrawTaskRequestCallBack(data)
   uiMgr:AddDialog('common.RewardPopup', data)
    local requestData = data.requestData
    local taskId = requestData.taskId
    local kind = requestData.kind
    local difficulty = requestData.difficulty
    self.routeKeysData[tostring(taskId)].hasDrawn = 1
    local taskData = nil
    local index = 0
    for k, v in pairs(self.currentData) do
        if checkint(v.taskId) == checkint(taskId) then
            taskData = v
            taskData.kind = kind
            v.hasDrawn = 1
            index = k
            break
        end
    end
    local groupConfig  = CommonUtils.GetConfigAllMess('group' ,'cardCall')
    local  groupOneConfig = groupConfig[tostring(kind)]
    self:GetFacade():DispatchObservers( ALL_DRAW_TASK_REWARD_EVENT  , { routeId = self.routeData.routeId , taskId = taskId })
    if difficulty <  table.nums(groupOneConfig) then
        difficulty = difficulty + 1
        local taskId =  groupOneConfig[tostring(difficulty)]
        taskData = clone(self.routeKeysData[tostring(taskId)])
        if taskData then
            taskData.difficulty = difficulty
            taskData.kind = kind
            self.currentData[index] = taskData
        end
    end
    self:SortFunction()
    ---@type AllRoundModuleTaskView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    viewData.tableView:reloadData()
end

function AllRoundModuleTaskMediator:SortFunction()
    table.sort(self.currentData , function(aTaskData , bTaskData)
        local isTrue  = true
        if checkint(aTaskData.hasDrawn) ==  checkint(bTaskData.hasDrawn) then
            if  checkint(aTaskData.hasDrawn)  == 1 then
                if checkint(aTaskData.taskId) >= checkint(bTaskData.taskId)  then
                     isTrue = false
                else
                    isTrue = true
                end
            else
                local aReady = 0
                local bReady = 0
                if checkint(aTaskData.progress)  >=  checkint(aTaskData.targetNum) then
                    aReady = 1
                end
                if checkint(bTaskData.progress)  >=  checkint(bTaskData.targetNum) then
                    bReady = 1
                end
                if aReady == bReady  then
                    if checkint(aTaskData.taskId) > checkint(bTaskData.taskId)  then
                        isTrue = false
                    else
                        isTrue = true
                    end
                else
                    isTrue = aReady > bReady and true or false
                end
            end
        else
            if checkint(aTaskData.hasDrawn) >  checkint(bTaskData.hasDrawn)  then
                isTrue = false
            else
                isTrue = true
            end
        end
        return isTrue
    end)
end
function AllRoundModuleTaskMediator:Initial(key)
    self.super.Initial(self, key)
    ---@type AllRoundModuleTaskView
    local viewComponent = require('Game.views.allRound.AllRoundModuleTaskView').new()
    self:SetViewComponent(viewComponent)
    uiMgr:GetCurrentScene():AddDialog(viewComponent)
    viewComponent:setPosition(display.center)
    local viewData = viewComponent.viewData
    local closeLayout = viewData.closeLayout
    closeLayout:setTag(BUTTON_TAG.CLOSE_VIEW)
    display.commonUIParams(closeLayout , { cb = handler(self, self.ButtonAction)})
    self:UpdateUI()
    self:CreateRouterLayout()
end
function AllRoundModuleTaskMediator:CreateRouterLayout()
    local routeId = self.routeData.routeId
    local rewardConfig = CommonUtils.GetConfigAllMess('reward' , 'cardCall')
    local rewardOneConfig = rewardConfig[tostring(routeId)]
    local openTypeTable  =  rewardOneConfig.openType
    local moduleConfig = CommonUtils.GetConfigAllMess('module')
    ---@type AllRoundModuleTaskView
    local viewComponent = self:GetViewComponent()
    local viewComponentViewData = viewComponent.viewData

    for i = 1, #openTypeTable do
        local moduleOneConfig = moduleConfig[tostring(openTypeTable[i])]
        local name  = moduleOneConfig.name
        local iconId = moduleOneConfig.iconID
        local functionLayout = viewComponent:CreateFunctionLayout()
        local viewData = functionLayout.viewData
        viewData.functionImage:setTexture(_res( string.format('ui/home/levelupgrade/unlockmodule/%s' , iconId) ))
        display.commonUIParams(viewData.functionImage , { animate = false,cb = handler(self, self.ModuleCallBack)})
        viewData.functionImage:setTag(checkint(openTypeTable[i]) )
        viewData.functionImage:setScale(0.8)
        display.commonLabelParams(viewData.functionLabel, {text = name})
        viewComponentViewData.leftLayout:addChild(viewData.functionLayout)
        viewData.functionLayout:setPosition(167/2, 637 - 110 - ((i -1) * 140 )  )
    end

end
function AllRoundModuleTaskMediator:ModuleCallBack(sender )
    if self.isGoto then
        return
    end
    local openType = sender:getTag()
    if CommonUtils.UnLockModule(openType,true) then
        local jumpView = MODULE_MEDIATOR[tostring(openType)].jumpView
        local params = MODULE_MEDIATOR[tostring(openType)].params or {}
        if jumpView then
            sceneWorld:runAction(
                    cc.Sequence:create(
                        cc.CallFunc:create(function()
                                self.isGoto = true
                        end),
                        cc.DelayTime:create(2) ,
                        cc.CallFunc:create(function()
                            self.isGoto = false
                        end)
                    )
            )
            if jumpView == "HomeMediator" then
                app:BackHomeMediator()
            elseif jumpView == "MapMediator" then
                self:ShowEnterStageView(taskConfigData.targetId)
            elseif jumpView == "RecipeResearchAndMakingMediator" then
                app:BackHomeMediator()
                local router = app:RetrieveMediator('Router')
                router:Dispatch({}, {name = jumpView})
            else
                ---@type Router
                local router = app:RetrieveMediator('Router')
                router:Dispatch({}, {name = jumpView , params = params } )
            end

        end
    end
end
function AllRoundModuleTaskMediator:ButtonAction(sender)
    local tag = sender:getTag()
    if tag == BUTTON_TAG.CLOSE_VIEW  then
        self:GetFacade():UnRegsitMediator(NAME)
    end
end

function AllRoundModuleTaskMediator:UpdateUI()
    ---@type AllRoundModuleTaskView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local tableView = viewData.tableView
    local RES_DICT = {
        ALLROUND_ICO_BOOK_1     = _res('ui/home/allround/allround_ico_book_1.png'),
        ALLROUND_ICO_BOOK_2     = _res('ui/home/allround/allround_ico_book_2.png'),
        ALLROUND_ICO_BOOK_3     = _res('ui/home/allround/allround_ico_book_3.png'),
        ALLROUND_ICO_BOOK_4     = _res('ui/home/allround/allround_ico_book_4.png'),
    }
    local moduleTable = {
        {tag = 1, name = __('日常路线') , image = RES_DICT.ALLROUND_ICO_BOOK_4 ,pos = cc.p(display.cx + 407, display.cy + -148)},
        {tag = 2, name = __('战斗路线') , image = RES_DICT.ALLROUND_ICO_BOOK_3 ,pos = cc.p(display.cx + 452, display.cy + 228)},
        {tag = 3, name = __('经营路线') , image = RES_DICT.ALLROUND_ICO_BOOK_1 ,pos = cc.p(display.cx + -412, display.cy + 120)},
        {tag = 4, name = __('堕神路线') , image = RES_DICT.ALLROUND_ICO_BOOK_2 ,pos = cc.p(display.cx + -331, display.cy + -198)}
    }
    viewData.moduleImage:setTexture( moduleTable[ checkint(self.routeData.routeId)].image)
    display.commonLabelParams(viewData.moduleName , fontWithColor(14, {text = moduleTable[ checkint(self.routeData.routeId)].name }))
    tableView:setCountOfCell(#self.currentData+1)
    tableView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))
    tableView:reloadData()
end
function AllRoundModuleTaskMediator:OnDataSource(cell , idx)
    local index = idx +1
    local taskData = self.currentData[index] or {}
    local taskId = taskData.taskId
    local sizee =  cc.size(883,140)
    xTry(function()
        if not cell then
            ---@type AllRoundModuleTaskView
            local viewComponent  = self:GetViewComponent()
            cell = CTableViewCell:new()
            cell:setContentSize(sizee)
            local listCell =viewComponent:CreateListCell()
            listCell:setName("listCell")
            listCell:setPosition(sizee.width/2 , sizee.height/2 )
            cell:addChild(listCell)
            local viewData = listCell.viewData
            display.commonUIParams(viewData.rewardBtn , {cb = handler(self, self.DrawTaskRewards ) , animate = false})
        end
        if   table.nums(taskData) ==  0  then
            cell:setVisible(false)
            return cell
        else
            cell:setVisible(true)
        end
        local taskConfigData = taskConfig[tostring(taskId)] or {}
        local progress = checkint(taskData.progress)
        local targetNum = checkint(taskData.targetNum)
        local hasDrawn = checkint(taskData.hasDrawn)
        local difficulty = taskData.difficulty
        local rewards = taskConfigData.rewards
        local listCell = cell:getChildByName("listCell")
        local viewData = listCell.viewData
        local rewardLayout = viewData.rewardLayout
        local prorassLabel = viewData.prorassLabel
        local completeConditions = viewData.completeConditions
        local prograssImage = viewData.prograssImage
        local barImage = viewData.barImage
        local starTable = viewData.starTable
        local underCellImage = viewData.underCellImage
        local alreadyRewardImage = viewData.alreadyRewardImage
        local rewardBtn = viewData.rewardBtn
        --local topCellImage = viewData.topCellImage
        underCellImage:setVisible(false)
        alreadyRewardImage:setVisible(false)
        --topCellImage:setVisible(false)
        rewardLayout:removeAllChildren()
        rewardBtn:setTag(index)
        rewardBtn:setVisible(true)
        for i, v in pairs(rewards) do
            local data = clone(v )
            data.showAmount = true
            local goodNode = require('common.GoodNode').new(data)
            goodNode:setPosition(80 * (i - 0.5 ) , 40 )
            goodNode:setScale(0.7)
            display.commonUIParams(goodNode , {animate = false ,  cb = function(sender)
               uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
            end})
            rewardLayout:addChild(goodNode)
        end
        local starFullNum = math.floor( checkint(taskConfigData.starNum) / 2)
        local mode = difficulty %2
        local imageTable = {}
        for i = 1, starFullNum do
            imageTable[#imageTable+1] = _res('ui/home/allround/allround_ico_star_full')
        end
        if mode > 0  then
            imageTable[#imageTable+1] = _res('ui/home/allround/allround_ico_star_half')
        end
        for i = #imageTable , 5 do
            imageTable[#imageTable+1] = _res('ui/home/allround/allround_ico_star_empty')
        end
        for i = 1, #starTable  do
            starTable[i]:setTexture(imageTable[i])
        end
        display.commonLabelParams(prorassLabel , {text = string.format('%d/%d' , checkint(progress) , checkint(targetNum)) })
        if checkint(taskConfigData.showProgress)   == 1 then
            prograssImage:setMaxValue(targetNum)
            prograssImage:setValue(progress)
            prograssImage:setVisible(true)
            prorassLabel:setVisible(true)
            barImage:setVisible(true)
        else
            prograssImage:setVisible(false)
            prorassLabel:setVisible(false)
            barImage:setVisible(false)
        end
        local descr = self:GetSubTaskDecer(taskId)
        display.commonLabelParams(completeConditions , {text =  descr , hAlign = display.TAL , w= 370  })
        if hasDrawn == 1 then
            alreadyRewardImage:setVisible(true)
            underCellImage:setVisible(true)
            rewardBtn:setVisible(false)
        else
            if checkint(progress) >= targetNum then
                underCellImage:setVisible(true)
                --topCellImage:setVisible(true)
                rewardBtn:setVisible(true)
                rewardBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
                rewardBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
                rewardBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
                display.commonLabelParams(rewardBtn , {text = __('领取')})
                display.commonUIParams(viewData.rewardBtn , {cb = handler(self, self.DrawTaskRewards ) , animate = false})
            else

                underCellImage:setVisible(true)
                local taskType = taskConfigData.taskType
                if MODULE_TO_DATA[tostring(taskType)]  then
                    rewardBtn:setVisible(true)
                    rewardBtn:setNormalImage(_res('ui/common/common_btn_white_default.png'))
                    rewardBtn:setSelectedImage(_res('ui/common/common_btn_white_default.png'))
                    rewardBtn:setSelectedImage(_res('ui/common/common_btn_white_default.png'))
                    display.commonLabelParams(rewardBtn, {text = __('去完成')})
                    display.commonUIParams(viewData.rewardBtn , {cb = handler(self, self.DrawTaskRewards ) , animate = true})
                else
                    rewardBtn:setNormalImage(_res('ui/common/common_btn_orange_disable'))
                    rewardBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable'))
                    rewardBtn:setDisabledImage(_res('ui/common/common_btn_orange_disable'))
                    display.commonLabelParams(rewardBtn, {text = __('领取')})
                    display.commonUIParams(viewData.rewardBtn , {cb = handler(self, self.DrawTaskRewards ) , animate = true})
                end
            end
        end
    end,__G__TRACKBACK__)
    return cell
end
function AllRoundModuleTaskMediator:TaskCallBack(sender)
    if self.isGoto then
        return
    end
    local tag = sender:getTag()
    local taskData = self.currentData[tag]
    -- 模块的前往
    local taskConfigData = taskConfig[tostring(taskData.taskId )] or {}
    local taskType = taskConfigData.taskType
    if  MODULE_TO_DATA[tostring(taskType)] then
        local jumpView =  MODULE_TO_DATA[tostring(taskType)].jumpView
        local openType = MODULE_TO_DATA[tostring(taskType)].openType
        local params = MODULE_TO_DATA[tostring(taskType)].params or {}
        if CommonUtils.UnLockModule(openType,true) then
            sceneWorld:runAction(
                    cc.Sequence:create(
                            cc.CallFunc:create(function()
                                self.isGoto = true
                            end),
                            cc.DelayTime:create(2) ,
                            cc.CallFunc:create(function()
                                self.isGoto = false
                            end)
                    )
            )
            if jumpView == "HomeMediator" then
                app:BackHomeMediator()
            elseif jumpView == "MapMediator" then
                self:ShowEnterStageView(taskConfigData.targetNum)
            elseif jumpView == "RecipeResearchAndMakingMediator" then
                app:BackHomeMediator()
                local router = app:RetrieveMediator('Router')
                router:Dispatch({}, {name = jumpView})
            else
                ---@type Router
                local router = app:RetrieveMediator('Router')

                router:Dispatch({}, {name = jumpView , params = params })
            end
        end
    else
       uiMgr:ShowInformationTips(__('暂无前往方式'))
    end
end
function AllRoundModuleTaskMediator:DrawTaskRewards(sender)
    local tag = sender:getTag()
    local taskData = self.currentData[tag]
    local progress = checkint(taskData.progress)
    local targetNum = checkint(taskData.targetNum)
    if progress >= targetNum then
        self:SendSignal(POST.CARD_CALL_DRAW_TASK_REWARD.cmdName , {kind = taskData.kind,  difficulty = taskData.difficulty , taskId = taskData.taskId  })
    else
        self:TaskCallBack(sender)
    end
end
--[[
关卡点击回调
@params stageId int 关卡id
--]]
function AllRoundModuleTaskMediator:ShowEnterStageView(stageId)
    PlayAudioByClickNormal()
    local stageId = checkint(stageId)
    local stageConf = CommonUtils.GetConfig('quest', 'quest', stageId)
    local questType = checkint(stageConf.questType)
    --------------- 初始化战斗传参 ---------------
    local battleReadyData = BattleReadyConstructorStruct.New(
            2,
            gameMgr:GetUserInfo().localCurrentBattleTeamId,
            gameMgr:GetUserInfo().localCurrentEquipedMagicFoodId,
            stageId,
            CommonUtils.GetQuestBattleByQuestId(stageId),
            nil,
            POST.QUEST_AT.cmdName,
            {questId = stageId},
            POST.QUEST_AT.sglName,
            POST.QUEST_GRADE.cmdName,
            {questId = stageId},
            POST.QUEST_GRADE.sglName,
            'allRound.AllRoundHomeMediator',
            "allRound.AllRoundHomeMediator"
    )
    --------------- 初始化战斗传参 ---------------
    if questType == QUEST_DIFF_NORMAL then
        if checkint(stageId)  > gameMgr:GetUserInfo().newestQuestId then
           uiMgr:ShowInformationTips(__('先通关前置关卡'))
            return
        end
    elseif questType == QUEST_DIFF_HARD then
        if checkint(stageId)  > gameMgr:GetUserInfo().newestHardQuestId then
           uiMgr:ShowInformationTips(__('先通关前置关卡'))
            return
        end
    end
    local layer = require('Game.views.BattleReadyView').new(battleReadyData)
    layer:setPosition(cc.p(display.cx,display.cy))
    uiMgr:GetCurrentScene():AddDialog(layer)
    --addChild(layer, battleReadyViewZOrder - 1)
end
function AllRoundModuleTaskMediator:GetSubTaskDecer(taskId)
    local  taskConfig = CommonUtils.GetConfigAllMess('task','cardCall')
    local taskConfigData = taskConfig[tostring(taskId)]
    if taskConfigData then
        local taskType =checkint(taskConfigData.taskType)
        local descr = taskConfigData.name
        if taskType == ALL_CARD_TASK_TYPE.COMPLETE_NORMAL_QUEST_TASKS or
        taskType == ALL_CARD_TASK_TYPE.COMPLETE_HARD_QUEST_TASKS then
           local targetNum = checkint(taskConfigData.targetNum)
            local quetOneConfig = CommonUtils.GetQuestConf(targetNum) or {}
            local name = quetOneConfig.name or ""
            descr = string.gsub(descr , '_target_num_' ,name )
        else
            descr = string.gsub(descr , '_target_num_' , taskConfigData.targetNum )
        end
        local _x, _y = string.find(descr , '_target_id_')
        if _x then
            descr = string.gsub(descr ,'_target_id_', taskConfigData.targetId )
        end
        return descr
    end
    return ""
end
function AllRoundModuleTaskMediator:OnRegist()
    regPost(POST.CARD_CALL_DRAW_TASK_REWARD)
end
function AllRoundModuleTaskMediator:OnUnRegist()
    unregPost(POST.CARD_CALL_DRAW_TASK_REWARD)
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:stopAllActions()
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return AllRoundModuleTaskMediator