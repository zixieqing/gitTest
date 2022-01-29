--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 探索主界面 中介者
]]
---@class Anniversary20ExploreHomeMediator :Mediator
local Anniversary20ExploreHomeMediator = class('Anniversary20ExploreHomeMediator', mvc.Mediator)
local EXPLORE_STATUS = {
    NOT_CLICK     = 1,
    CAN_CLICK     = 2,
    ALREADY_CLICK = 3
}

function Anniversary20ExploreHomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'Anniversary20ExploreHomeMediator', viewComponent)
    self.ctorArgs_ = params or {}
    app.anniv2020Mgr:AddObserver()
    self.pathMaps = {
        {2,1,1,1},
        {1,1,1,1},
        {1,1,1,1},
        {1,1,1,1}
    }
end


-------------------------------------------------
-- life cycle
function Anniversary20ExploreHomeMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.ownerScene_ = app.uiMgr:SwitchToTargetScene('Game.views.anniversary20.Anniversary20ExploreHomeScene')
    self:SetViewComponent(self.ownerScene_)

    -- add listener
    local viewData = self:getViewData()
    ui.bindClick(viewData.backBtn, handler(self, self.onClickBackButtonHandler_))
    ui.bindClick(viewData.titleBtn, handler(self, self.onClickTitleButtonHandler_))
    ui.bindClick(viewData.nextLayout, handler(self, self.onClickNextButtonHandler_) , false)
    ui.bindClick(viewData.rewardTotalLayout , handler(self, self.OnRewardsButtonHandler_))
    ui.bindClick(viewData.giveUpLayout , handler(self, self.OnGiveUpButtonHandler_))
    ui.bindClick(viewData.skillBtn , handler(self, self.OnBuffButtonHandler_))
    self:BindGridClick()
    viewData.doorSpine:registerSpineEventHandler(handler(self, self.SpineCallBack), sp.EventType.ANIMATION_COMPLETE)
    viewData.rewardSpine:registerSpineEventHandler(handler(self, self.RewardSpineCallBack), sp.EventType.ANIMATION_COMPLETE)
    -- update views
    self.isControllable_ = false

    self:getViewNode():showUI(function()
        self:SetAllUpdatePathData()
        ---@type Anniversary20ExploreHomeScene
        local viewComponent = self:GetViewComponent()
        viewComponent:UpdateView(self:GetPathMapsData())
        viewComponent:UpdateRewardTotalLayout()
        -- 判断是否从战斗跳转过来的
        local mapGridId = self.ctorArgs_.mapGridId
        if mapGridId and checkint(mapGridId) > 0 then
            if app.anniv2020Mgr:isExploreingPassedAt(mapGridId) then
                app:DispatchObservers(ANNIVERSARY20_EXPLORE_RESULT_EVENT , {
                    mapGridId  = self.ctorArgs_.mapGridId  , isPassed  = self.ctorArgs_.isPassed
                })
            end
        end
        self.isControllable_ = true
    end)
end


function Anniversary20ExploreHomeMediator:BindGridClick()
    local viewData = self:getViewData()
    local fourMatrixViewData = viewData.fourMatrixViewData
    local DEFINE = FOOD.ANNIV2020.DEFINE
    local rows = DEFINE.EXPLORE_MAP_ROWS
    local col = DEFINE.EXPLORE_MAP_COLS
    for i =1 , rows do
        for j = 1 , col do
            local matrixViewData = fourMatrixViewData[i][j]
            ui.bindClick(matrixViewData.touchNode , handler(self,self.GridClick))
        end
    end
end

function Anniversary20ExploreHomeMediator:GridClick(sender)
    local tag = sender:getTag()
    local pathMaps = self:GetPathMapsData()
    local DEFINE = FOOD.ANNIV2020.DEFINE
    local col = DEFINE.EXPLORE_MAP_COLS
    local line = math.ceil(tag/col)
    local mod = tag % col
    local colu = mod == 0 and  col or mod
    if pathMaps[line][colu] == EXPLORE_STATUS.NOT_CLICK then
        ---@type Anniversary20ExploreHomeScene
        local viewComponent = self:GetViewComponent()
        viewComponent:RunActionLightAction(pathMaps)
    elseif pathMaps[line][colu] == EXPLORE_STATUS.ALREADY_CLICK then
        app.uiMgr:ShowInformationTips(__('已经通过该关卡'))
    elseif pathMaps[line][colu] == EXPLORE_STATUS.CAN_CLICK then
        local mapGridType = app.anniv2020Mgr:getExploreingMapTypeAt(tag)
        local EXPLORE_TYPE = FOOD.ANNIV2020.EXPLORE_TYPE
        if mapGridType == EXPLORE_TYPE.EMPTY then
            self:SendSignal(POST.ANNIV2020_EXPLORE_NONE.cmdName , { gridId = tag})
        else
            local meditaorPathName = "Game.mediator.anniversary20"
            if mapGridType == EXPLORE_TYPE.MONSTER_NORMAL then
                meditaorPathName = table.concat({meditaorPathName , "Anniversary20ExploreMonsterMediator"} ,".")
            elseif mapGridType == EXPLORE_TYPE.MONSTER_ELITE then
                meditaorPathName = table.concat({meditaorPathName , "Anniversary20ExploreMonsterMediator"} ,".")
            elseif mapGridType == EXPLORE_TYPE.MONSTER_BOSS then
                meditaorPathName = table.concat({meditaorPathName , "Anniversary20ExploreMonsterMediator"} ,".")
            elseif mapGridType == EXPLORE_TYPE.OPTION then
                meditaorPathName = table.concat({meditaorPathName , "Anniversary20QuestionMediator"} ,".")
            elseif mapGridType == EXPLORE_TYPE.CHEST then
                meditaorPathName = table.concat({meditaorPathName , "Anniversary20ChestMediator"} ,".")
            elseif mapGridType == EXPLORE_TYPE.BUFF then
                meditaorPathName = table.concat({meditaorPathName , "Anniversary20ExploreBuffMediator"} ,".")
            end
            local mediator = require(meditaorPathName).new({mapGridId = tag})
            app:RegistMediator(mediator)
        end
    end
end

function Anniversary20ExploreHomeMediator:CleanupView()
end


function Anniversary20ExploreHomeMediator:OnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightHide')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'allhide')

    regPost(POST.ANNIV2020_EXPLORE_GIVE_UP)
    regPost(POST.ANNIV2020_EXPLORE_NONE)
    regPost(POST.ANNIV2020_EXPLORE_NEXT_FLOOR)
end


function Anniversary20ExploreHomeMediator:OnUnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightShow')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'hide')

    unregPost(POST.ANNIV2020_EXPLORE_GIVE_UP)
    unregPost(POST.ANNIV2020_EXPLORE_NONE)
    unregPost(POST.ANNIV2020_EXPLORE_NEXT_FLOOR)
end


function Anniversary20ExploreHomeMediator:InterestSignals()
    return {
        POST.ANNIV2020_EXPLORE_GIVE_UP.sglName,
        ANNIVERSARY20_EXPLORE_RESULT_EVENT ,
        POST.ANNIV2020_EXPLORE_NONE.sglName,
        SGL.CACHE_MONEY_UPDATE_UI ,
        POST.ANNIV2020_EXPLORE_NEXT_FLOOR.sglName,

    }
end
function Anniversary20ExploreHomeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.ANNIV2020_EXPLORE_GIVE_UP.sglName then
        self:close()
    elseif name == POST.ANNIV2020_EXPLORE_NEXT_FLOOR.sglName then
        self:EnterNextFloor(data)
    elseif name == POST.ANNIV2020_EXPLORE_NONE.sglName then
        local requestData = data.requestData
        self:GetFacade():DispatchObservers(ANNIVERSARY20_EXPLORE_RESULT_EVENT, {
            mapGridId  = requestData.gridId , isPassed  = 1
        })
    elseif name == ANNIVERSARY20_EXPLORE_RESULT_EVENT then
        self:CurrentStepComplete(data)
    elseif name == SGL.CACHE_MONEY_UPDATE_UI then
        self:getViewNode():updateMoneyBarGoodNum()
    end
end

function Anniversary20ExploreHomeMediator:EnterNextFloor(data)
    local viewNode = self:getViewNode()
    -- 重置方格数据
    self.pathMaps = {
        {2,1,1,1},
        {1,1,1,1},
        {1,1,1,1},
        {1,1,1,1}
    }
    -- 删除只有当前层生效的buff
    app.anniv2020Mgr:nextFloorTakeEffectBuff()
    app.anniv2020Mgr:setExploreingMapDatas(data.map)
    if checkint(data.floor) > 0  then
        app.anniv2020Mgr:setExploreingFloor(checkint(data.floor))
    end
    -- 更新 self.pathMaps
    self:SetAllUpdatePathData()
    viewNode.viewData_.nextLayout:setVisible(false)
    viewNode.viewData_.touchLayer:setVisible(false)
    viewNode:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(2),
            cc.CallFunc:create(function()
                -- 更新显示
                viewNode:UpdateView(self:GetPathMapsData())
                viewNode:UpdateRewardTotalLayout()
                viewNode.viewData_.touchLayer:setVisible(true)
            end)
        )
    )

end
---@deprecated 周年庆完成当前步骤完成
function Anniversary20ExploreHomeMediator:CurrentStepComplete(body)
    local mapGridId = checkint(body.mapGridId)
    local mapGridType = app.anniv2020Mgr:getExploreingMapTypeAt(mapGridId)
    local refId = checkint(app.anniv2020Mgr:getExploreingMapRefIdAt(mapGridId))
    local ANNIV2020 = FOOD.ANNIV2020
    local isPassed = checkint(body.isPassed)
    ---@type Anniversary20ExploreHomeScene
    local viewComponent = self:GetViewComponent()
    if isPassed == 1 then
        if mapGridType == ANNIV2020.EXPLORE_TYPE.BUFF then
            if refId == ANNIV2020.EXPLORE_BUFF_TYPE.MAP_ALL then
                self:UpdatePathMapsByBuffId(refId)
            elseif refId == ANNIV2020.EXPLORE_BUFF_TYPE.COMPLETE_TASK then
                viewComponent:UpdateTopLayer()
            end
            viewComponent:UpdateBuffLayout()
        elseif mapGridType ~= ANNIV2020.EXPLORE_TYPE.EMPTY then
            local optionOneConf = ANNIV2020.EXPLORE_TYPE_CONF[mapGridType]:GetValue(refId)
            local rewards = optionOneConf.rewards
            viewComponent:StepRewardAnimation(rewards ,mapGridId )
            --TODO  获取奖励动画
        elseif mapGridType == ANNIV2020.EXPLORE_TYPE.EMPTY then
            app.uiMgr:ShowInformationTips(__('无事发生'))
        end
    end
    -- 如果完成关卡是boss 会有boss剧情 ， 剧情只播放一次
    if mapGridType == ANNIV2020.EXPLORE_TYPE.MONSTER_BOSS then
        local exploreBossConf = ANNIV2020.EXPLORE_TYPE_CONF[mapGridType]:GetValue(refId)
        local storyId = exploreBossConf.story
        app.anniv2020Mgr:checkPlayStory(storyId)
    end
    self:SetUpdatePathMapByMapId(mapGridId , EXPLORE_STATUS.ALREADY_CLICK)
    ---@type  Anniversary20ExploreHomeScene
    local viewComponent = self:GetViewComponent()
    local pathMaps = self:GetPathMapsData()
    viewComponent:UpdateMapImage(pathMaps)
end



-------------------------------------------------
-- get / set
---@return Anniversary20ExploreHomeScene
function Anniversary20ExploreHomeMediator:getViewNode()
    return self.ownerScene_
end
function Anniversary20ExploreHomeMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function Anniversary20ExploreHomeMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())

    app.router:Dispatch(
        {name = 'anniversary20.Anniversary20ExploreHomeMediator'}, 
        {name = 'anniversary20.Anniversary20ExploreMainMediator', params = {needRefresh = true}}
    )
end

-------------------------------------------------
-- handler

function Anniversary20ExploreHomeMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    app:UnRegsitMediator(self:GetMediatorName())
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightHide')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'allhide')
    app.router:Dispatch(
            {name = 'anniversary20.Anniversary20ExploreHomeMediator'},
            {name = 'anniversary20.Anniversary20HomeMediator'}
    )
end
function Anniversary20ExploreHomeMediator:GetPathMapsData()
    return self.pathMaps
end

function Anniversary20ExploreHomeMediator:SetAllUpdatePathData()
    local buffs = app.anniv2020Mgr:getExploreingBuffs()
    for i, buffId in pairs(buffs) do
        if checkint(buffId) == FOOD.ANNIV2020.EXPLORE_BUFF_TYPE.MAP_ALL then
            self:UpdatePathMapsByBuffId(buffId)
            break
        end
    end
    local mapDatas = app.anniv2020Mgr:getExploreingMapDatas()
    for key, v in pairs(mapDatas) do
        if checkint(v.isPassed) == 1 then
            self:SetUpdatePathMapByMapId(key , EXPLORE_STATUS.ALREADY_CLICK)
        end
    end
end
---@deprecated 更新矩阵数据
function Anniversary20ExploreHomeMediator:SetUpdatePathMapByMapId(mapId , value)
    local DEFINE = FOOD.ANNIV2020.DEFINE
    local rows = DEFINE.EXPLORE_MAP_ROWS
    local col = DEFINE.EXPLORE_MAP_COLS
    local line = math.ceil(mapId/col)
    local colu = mapId % col == 0 and  col or mapId % col
    self.pathMaps[line][colu] = value
    if value == EXPLORE_STATUS.ALREADY_CLICK then
        -- 当前点已经点击 那么分别更新更新当前坐标点的 上下左右 ， 范围是为 1<= x <= 4
        if line > 1 and checkint(self.pathMaps[line-1][colu]) ~= EXPLORE_STATUS.ALREADY_CLICK then
            self.pathMaps[line-1][colu] = EXPLORE_STATUS.CAN_CLICK
        end
        if line < rows and checkint(self.pathMaps[line+1][colu]) ~= EXPLORE_STATUS.ALREADY_CLICK then
            self.pathMaps[line+1][colu] = EXPLORE_STATUS.CAN_CLICK
        end
        if  colu < col and checkint(self.pathMaps[line][colu+1]) ~= EXPLORE_STATUS.ALREADY_CLICK then
            self.pathMaps[line][colu+1] = EXPLORE_STATUS.CAN_CLICK
        end
        if colu > 1 and checkint(self.pathMaps[line][colu-1]) ~= EXPLORE_STATUS.ALREADY_CLICK then
            self.pathMaps[line][colu-1] = EXPLORE_STATUS.CAN_CLICK
        end
    end
end

function Anniversary20ExploreHomeMediator:SpineCallBack(event)
    local viewData_ = self:getViewData()
    local exploreModuleId = app.anniv2020Mgr:getExploringId()
    local animationName = string.format("play1_%d" , exploreModuleId)
    if event.animation ==   animationName then
        viewData_.nextLayout:setVisible(true)
        viewData_.doorSpine:addAnimation(0 ,  string.format("play2_%d" , exploreModuleId) , true)
    elseif event.animation ==  "play3_" .. exploreModuleId then
        viewData_.doorSpine:addAnimation(0 ,  string.format("idle%d" , exploreModuleId) , true)
    end
end

function Anniversary20ExploreHomeMediator:RewardSpineCallBack(event)
    if event.animation ==  "play1" then
        local viewNode = self:getViewNode()
        viewNode:UpdateRewardTotalLayout()
    end
end
--[[
    根据BuffId 修改pathMaps 的数据
--]]
function Anniversary20ExploreHomeMediator:UpdatePathMapsByBuffId(buffId)
    local EXPLORE_BUFF_TYPE = FOOD.ANNIV2020.EXPLORE_BUFF_TYPE
    local DEFINE = FOOD.ANNIV2020.DEFINE
    local rows = DEFINE.EXPLORE_MAP_ROWS
    local col = DEFINE.EXPLORE_MAP_COLS
    if checkint(buffId) == EXPLORE_BUFF_TYPE.MAP_ALL then
        for i = 1 , rows do
            for j = 1, col do
                if self.pathMaps[i][j] ~= EXPLORE_STATUS.ALREADY_CLICK then
                    self.pathMaps[i][j] = EXPLORE_STATUS.CAN_CLICK
                end
            end
        end
    end
end
function Anniversary20ExploreHomeMediator:SendNextFloorEvent()
    local explorModuleId = app.anniv2020Mgr:getExploringId()
    local viewData = self:getViewData()
    viewData.doorSpine:setToSetupPose()
    viewData.doorSpine:setAnimation(0, "play3_" .. explorModuleId , false)
    local isLastFloor = app.anniv2020Mgr:isExploreingLastFloor()
    if isLastFloor then
        self:close()
    else
        self:SendSignal(POST.ANNIV2020_EXPLORE_NEXT_FLOOR.cmdName , {})
    end

end
function Anniversary20ExploreHomeMediator:ShowRewardPopLayer()
    local mediator = require("Game.mediator.anniversary20.Anniversary20ExploreTotalRewardsMediator").new()
    app:RegistMediator(mediator)
end
function Anniversary20ExploreHomeMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA.ANNIV20_EXPLORE})
end

function Anniversary20ExploreHomeMediator:onClickNextButtonHandler_(sender)
    PlayAudioByClickNormal()
    sender:setEnabled(false)
    transition.execute(sender,cc.Sequence:create(
        cc.EaseOut:create(cc.ScaleTo:create(0.03,  0.97, 0.97), 0.03),
        cc.EaseOut:create(cc.ScaleTo:create(0.03,   1, 1),0.03),
        cc.DelayTime:create(0.8),
        cc.CallFunc:create(function()
           sender:setEnabled(true)
        end)
    ))
    if not self.isControllable_ then return end
    local floor = app.anniv2020Mgr:getExploreingFloor()
    local isRewards = false
    if floor % FOOD.ANNIV2020.DEFINE.EXPLORE_FLOOR_BOSS == 0 then
        local isPassed =  app.anniv2020Mgr:isExploreingFloorPassed()
        isRewards = isPassed
    end
    if isRewards then
        self:ShowRewardPopLayer()
    else
        self:SendNextFloorEvent()
    end

end

function Anniversary20ExploreHomeMediator:OnRewardsButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    self:ShowRewardPopLayer()
end
function Anniversary20ExploreHomeMediator:OnGiveUpButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    local tipsText = __('确定放弃当前关卡吗？')
    local extra =__('tips:奖励每通关10层可手动领取一次，放弃探索则无法获取当前奖励')
    local tipsView = require('common.NewCommonTip').new({text = tipsText, extra = extra , callback = function()
        self:SendSignal(POST.ANNIV2020_EXPLORE_GIVE_UP.cmdName)
    end})
    tipsView:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(tipsView)
end

function Anniversary20ExploreHomeMediator:OnBuffButtonHandler_(sender)
    PlayAudioByClickClose()
    local buffs = app.anniv2020Mgr:getExploreingBuffs()
    local ANNIV2020 = FOOD.ANNIV2020
    local buffConf = ANNIV2020.EXPLORE_TYPE_CONF[ANNIV2020.EXPLORE_TYPE.BUFF]:GetAll()
    for index , buffId in pairs(buffs) do
        local buffType = checkint(buffConf[tostring(buffId)].type)
        if buffType == 1 then
            local view =  require("Game.views.anniversary20.Anniversary20ExploreBuffDescrView").new({ buffId = buffId })
            view:setPosition(display.center)
            app.uiMgr:GetCurrentScene():AddDialog(view)
            break
        end
    end
end

return Anniversary20ExploreHomeMediator
