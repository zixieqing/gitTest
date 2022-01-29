 --[[
 * descpt : 新探索 中介者
]]
local NAME = 'ExploreSystemMediator'
local ExploreSystemMediator = class(NAME, mvc.Mediator)

--------------- import ---------------
local appFacadeIns     = AppFacade.GetInstance()
local uiMgr            = appFacadeIns:GetManager('UIManager')
local gameMgr          = appFacadeIns:GetManager("GameManager")
local timerMgr         = appFacadeIns:GetManager("TimerManager")
local exploreSystemMgr = appFacadeIns:GetManager("ExploreSystemManager")
--------------- import ---------------

--------------- defult ---------------
local BUTTON_TAG = {
    BACK               = 100,   -- 返回
    RULE               = 101,   -- 规则
    EDIT               = 102,   -- 编辑队伍 或 领取奖励
    EXPLORE            = 103,   -- 探索 或 撤退
    ACCELERATE_EXPLORE = 104,   -- 快速探索
}

local DIALOG_TAG = {
    EDIT_TEAM      = 4000,        -- 编辑团队
    RETREAT_TIP    = 4001,        -- 撤退提示
    SWITCH_CELL    = 4002,        -- 切换cell
    BACK           = 4003,        -- 退出界面
    ACCELERATE     = 4004,        -- 加速探索
    EXPLORE        = 4005,        -- 探索
}

local EXPLORE_TEAM_CHANGE_NOTICE = 'EXPLORE_TEAM_CHANGE_NOTICE'

local CLOSE_CHANGE_TEAM_SCENE   = 'CLOSE_CHANGE_TEAM_SCENE'
-- 控制视图启用
local VIEW_CONTROLLABLE = 'VIEW_CONTROLLABLE'
--------------- defult ---------------

function ExploreSystemMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    self.isNeedReq = next(self.ctorArgs_) == nil 
end

-------------------------------------------------
-- inheritance method
function ExploreSystemMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    self.curSelectOrder  = 1
    self.preCountDownSeconds = 0
    self.exploreDatas = {}
    self.oldQuestId = 0

    -- create view
    local viewComponent = uiMgr:SwitchToTargetScene('Game.views.exploreSystem.ExploreSystemView')
    -- local viewComponent = require('Game.views.exploreSystem.ExploreSystemView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    -- add layer
    self:initOwnerScene_()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    -- self:getOwnerScene():AddDialog(viewComponent)
    

    -- init view
    self:initView_()
    
end

function ExploreSystemMediator:initOwnerScene_()
    self.ownerScene_ = uiMgr:GetCurrentScene()
end


function ExploreSystemMediator:initView_()
    local viewData = self:getViewData()

    local actionBtns = viewData.actionBtns
    for tag, btn in pairs(actionBtns) do
        display.commonUIParams(btn, {cb = handler(self, self.onButtonAction)})
        btn:setTag(checkint(tag))
    end

    local gridView = viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSourceAdapter))

    -- self:GetViewComponent():refreshUI(self.exploreDatas)
    if not self.isNeedReq then
        self:updateUI(self.ctorArgs_)
    end
end

function ExploreSystemMediator:cleanupView()
    local viewComponent = self:GetViewComponent()
    
    exploreSystemMgr:checkRemain(self.exploreDatas.questList or {})
    -- 移除dialog
    for k, v in pairs(DIALOG_TAG) do
        local view = self.ownerScene_:GetDialogByTag(v)
        if view and not tolua.isnull(view) then
            self.ownerScene_:RemoveDialog(view)
        end
    end

    -- if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
    --     self.ownerScene_:RemoveDialog(viewComponent)
    --     self.ownerScene_ = nil
    -- end

    self.ownerScene_ = nil
end


function ExploreSystemMediator:OnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    regPost(POST.EXPLORE_SYSTEM_HOME)
    regPost(POST.EXPLORE_SYSTEM_QUEST_START)
    regPost(POST.EXPLORE_SYSTEM_QUEST_RETREAT)
    regPost(POST.EXPLORE_SYSTEM_QUEST_COMPLETE)
    regPost(POST.EXPLORE_SYSTEM_QUEST_ACCELERATE)

    if self.isNeedReq then
        self:enterLayer()
    end

    if isGuideOpened('explore') then
        local guideNode = require('common.GuideNode').new({tmodule = 'explore'})
        display.commonUIParams(guideNode, { po = display.center})
        sceneWorld:addChild(guideNode, GameSceneTag.Guide_GameSceneTag)
    end
end
function ExploreSystemMediator:OnUnRegist()
    unregPost(POST.EXPLORE_SYSTEM_HOME)
    unregPost(POST.EXPLORE_SYSTEM_QUEST_START)
    unregPost(POST.EXPLORE_SYSTEM_QUEST_RETREAT)
    unregPost(POST.EXPLORE_SYSTEM_QUEST_COMPLETE)
    unregPost(POST.EXPLORE_SYSTEM_QUEST_ACCELERATE)
    
    self:cleanupView()
    
end

function ExploreSystemMediator:InterestSignals()
    return {
        ------------------ local ------------------
        
        EVENT_LEVEL_UP,       -- 等级提升
        COUNT_DOWN_ACTION,
        EXPLORE_TEAM_CHANGE_NOTICE,
        CLOSE_CHANGE_TEAM_SCENE,
        VIEW_CONTROLLABLE,
        ------------------ local ------------------

        ------------------ server ------------------

        -- 探索主页
        POST.EXPLORE_SYSTEM_HOME.sglName,
        -- 探索开始
        POST.EXPLORE_SYSTEM_QUEST_START.sglName,
        -- 探索撤退
        POST.EXPLORE_SYSTEM_QUEST_RETREAT.sglName,
        -- 探索完成领取奖励
        POST.EXPLORE_SYSTEM_QUEST_COMPLETE.sglName,
        -- 探索加速
        POST.EXPLORE_SYSTEM_QUEST_ACCELERATE.sglName,
        ------------------ server ------------------
    }
end

function ExploreSystemMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()

    -- 等级提升
    if name == EVENT_LEVEL_UP then
        local newLevel, oldLevel = body.newLevel, body.oldLevel
        if exploreSystemMgr:checkIsCanUnlockTeam(newLevel, oldLevel) then
            self:enterLayer() 
        end
    elseif name == CLOSE_CHANGE_TEAM_SCENE then
        self:GetViewComponent():setTeamInfoViewShowState(true)
        self.chooseTeamLayer = nil
    elseif name == VIEW_CONTROLLABLE then
        local isControllable = body.isControllable
        self.isControllable_ = checkbool(isControllable)
    elseif name == COUNT_DOWN_ACTION then
        local timerName = body.timerName
        if timerName == COUNT_DOWN_TAG_EXPLORE_SYSTEM then
            local countdown = body.countdown
            if countdown <= 0 then
                
                self:enterLayer(__('您的订单已经刷新，请重新选择新的任务进行探索'))
            else
                local deltaSeconds = self.preCountDownSeconds - countdown
                self.exploreDatas.nextRefreshTime = checkint(self.exploreDatas.nextRefreshTime) - deltaSeconds
                -- self:updateNextOrderRefreshTime(self.exploreDatas.nextRefreshTime)
                local questList = self.exploreDatas.questList or {}
                local questListLen = #questList
                local isQuestEnd = false
                local isCurOrder = false
                local isNormalUpdate = true
                for i = questListLen, 1, -1 do
                    
                    isCurOrder = i == self.curSelectOrder

                    local questData = questList[i]
                    local status = checkint(questData.status)

                    -- 如果发现可以 领奖状态 直接结束当前循环
                    if status == exploreSystemMgr.QUEST_STATE.END then
                        break
                    elseif status == exploreSystemMgr.QUEST_STATE.PREPARE then
                        questData.refreshTime = checkint(questData.refreshTime) - deltaSeconds
                        if questData.refreshTime <= 0 then
                            questData.status = exploreSystemMgr.QUEST_STATE.CLOSE
                            isNormalUpdate = false

                            self:enterLayer(__('您的任务已经过期，请重新选择新的任务进行探索'))
                            return
                        end
                    elseif status == exploreSystemMgr.QUEST_STATE.ONGOING then
                        questData.completeTime = checkint(questData.completeTime) - deltaSeconds

                        if isCurOrder then
                            self:GetViewComponent():updateAccelerateExploreLayer(self:getViewData(), questData)
                        end
                        if questData.completeTime <= 0 then
                            isNormalUpdate = false
                            questData.status = exploreSystemMgr.QUEST_STATE.END
                        end
                    end
                end

                if isNormalUpdate then
                    self:GetViewComponent():updateAllCountdown(self.exploreDatas)
                else
                    self:updateOrderState(isQuestEnd)
                end
                
                self.preCountDownSeconds = countdown
            end
        end

    elseif name == EXPLORE_TEAM_CHANGE_NOTICE then
        local dataTag = body.dataTag
        
        -- 1.检查团队数据是否改变
        local questList = self.exploreDatas.questList or {}
        local dataIndex = exploreSystemMgr:getQuestIndexByQuestId(questList, dataTag)
        local questData = questList[dataIndex]
        local oldTeamData = questData.teamData or {}
        local teamData = body.teamData or {}
        local isChange = exploreSystemMgr:checkTeamDataIsChange(oldTeamData, teamData)
        -- 2.如果改变则更新卡牌数据
        if isChange then
            questData.isCanQuest = true
            questData.teamData = teamData
        end
        -- 3.更新条件奖励
        local curRewardIndex = body.curRewardIndex
        questData.curRewardIndex = curRewardIndex
        -- 4. 只有数据没有重排序 才会刷新界面
        if dataIndex == self.curSelectOrder then

            local viewComponent = self:GetViewComponent()
            if isChange then
                viewComponent:updateCards(self:getViewData(), teamData, questData.status, checkint(questData.confData.cardsNum))
            end
            
            viewComponent:updateBtnState(questData)
            
            local conditionRewardList = questData.conditionRewardList
            local confData = questData.confData or {}
            local conditionReward = conditionRewardList[curRewardIndex] or {extraReward = confData.rewards}
            -- logInfo.add(5, tableToString(conditionReward))
            viewComponent:updateConditionReward(self:getViewData(), conditionReward, teamData)
        end
        
    elseif name == POST.EXPLORE_SYSTEM_HOME.sglName then
        
        self:updateUI(body)

    elseif name == POST.EXPLORE_SYSTEM_QUEST_START.sglName then
        AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "73-01"})
        self.exploreDatas.surplusTeam = self.exploreDatas.surplusTeam - 1
        self:GetViewComponent():updateLeftTeamCount(self.exploreDatas.totalTeam, self.exploreDatas.surplusTeam)

        local requestData = body.requestData
        local questId = requestData.questId
        -- 开启互斥状态
        local teamData, questData = self:getTeamDataByQuestId(questId)
        gameMgr:SetCardPlace({}, teamData , CARDPLACE.PLACE_EXPLORE_SYSTEM)
        
        --跨编队上阵，然后点击返回。将之前上阵卡牌数据更新
		for i,v in ipairs(gameMgr:GetUserInfo().teamFormation) do
            for ii,vv in ipairs(v.cards) do
                if vv.id then
                    for i,vvv in ipairs(teamData) do
                        if vvv.id then
                            if checkint(vv.id) == checkint(vvv.id) then
                                logInfo.add(5, checkint(vvv.id))
                                -- if ii == 1 then
                                --     v.captainId = nil
                                -- end
                                -- vv.id = nil
                                break
                            end
                        end
                    end
                end
            end
		end

        questData.status = exploreSystemMgr.QUEST_STATE.ONGOING
        local confData = questData.confData or {}
        questData.completeTime = checkint(confData.completeTime)
        
        self:updateOrderState(false)

    elseif name == POST.EXPLORE_SYSTEM_QUEST_RETREAT.sglName then
        -- 解除互斥状态
        local requestData = body.requestData
        local questId = requestData.questId
        local questData = self:relieveTeamByQuestId(questId)
        -- questData.status = exploreSystemMgr.QUEST_STATE.CLOSE
        -- self:updateOrderState(true)
        self:enterLayer()

    elseif name == POST.EXPLORE_SYSTEM_QUEST_COMPLETE.sglName then
        -- body = json.decode([[{"mainExp":326459,"cardsExp":{"456":{"exp":100,"level":2},"444":{"exp":100,"level":2},"471":{"exp":166812,"level":"54"}},"gold":89416491,"baseRewards":[{"goodsId":140038,"type":14,"num":3}],"extraRewards":{"1":[{"goodsId":140038,"type":14,"num":3}]}}]])
        AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "73-02"})
        -- 解除互斥状态
        local requestData = body.requestData or {}
        local questId = requestData.questId
        local questData = self:relieveTeamByQuestId(questId)

        local teamData = {}
        local cardData = nil
        for i, v in ipairs(questData.teamData or {}) do
            cardData = gameMgr:GetCardDataById(v.id)
            table.insert(teamData, cardData)
        end
        
        local extraRewards = body.extraRewards or {}
        local rewards = {}
        local temp = {}
        for i, v in pairs(extraRewards) do
            local goodsId = v.goodsId
            local num = checkint(v.num)
            
            local turnGoodsId = v.turnGoodsId
            if turnGoodsId then
                table.insert(rewards, v)
            else
                if temp[v.goodsId] then
                    temp[v.goodsId].num = temp[v.goodsId].num + num
                else
                    temp[v.goodsId] = v
                end
            end
        end

        local baseRewards = body.baseRewards or {}
        for i, v in ipairs(baseRewards) do
            local goodsId = v.goodsId
            local num = checkint(v.num)
            
            local turnGoodsId = v.turnGoodsId
            if turnGoodsId then
                table.insert(rewards, v)
            else
                if temp[v.goodsId] then
                    temp[v.goodsId].num = temp[v.goodsId].num + num
                else
                    temp[v.goodsId] = v
                end
            end
        end
        
        for k, v in pairs(temp) do
            table.insert(rewards, v)
        end

        -------------------------------------------------------
        -- calc gold addition
        local confData = questData.confData
        local goldCount = 0
        goldCount = goldCount + checkint(confData.gold)

        local conditionRewardList = questData.conditionRewardList or {}
        local curRewardIndex = questData.curRewardIndex
        local conditionReward = conditionRewardList[curRewardIndex] or {extraReward = confData.rewards}
        for i, v in ipairs(conditionReward) do
            if checkint(v.goodsId) == GOLD_ID then
                goldCount = goldCount + checkint(v.num)
            end
        end
        -------------------------------------------------------
        
        local rewardView = require('Game.views.exploreSystem.ExploreSystemRewardView').new({
            teamData = clone(teamData),
            baseRewards = {
                mainExp = checkint(body.mainExp) - CommonUtils.GetCacheProductNum(EXP_ID),
                gold = goldCount,
            },
            trophyData = {
                rewards = rewards,
                mainExp = checkint(body.mainExp),
                cardExp = body.cardsExp or {},
                gold = checkint(body.gold)
            }
        })
        display.commonUIParams(rewardView,{po = display.center, ap = display.CENTER})
        self:getOwnerScene():AddDialog(rewardView)

        self:enterLayer()

        -- 更新道具数量显示
        local reward = {}
        for k,v in pairs(body.baseRewards or {}) do
            table.insert(reward, clone(v))
        end
        for k,v in pairs(body.extraRewards or {}) do
            table.insert(reward, clone(v))
        end
		AppFacade.GetInstance():DispatchObservers(EVENT_GOODS_COUNT_UPDATE, reward)
    elseif name == POST.EXPLORE_SYSTEM_QUEST_ACCELERATE.sglName then
        local requestData = body.requestData
        local questId = requestData.questId
        local questData = self:getQuestDataByQuestId(questId)
        questData.status = exploreSystemMgr.QUEST_STATE.END
        self:updateOrderState(false)

        local consume = body.consume or {}
        for i, v in ipairs(consume) do
            v.num = checkint(v.num) * -1
        end
        CommonUtils.DrawRewards(consume)
    end
end

-------------------------------------------------
-- get / set

function ExploreSystemMediator:getViewData()
    return self.viewData_
end

function ExploreSystemMediator:getOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function ExploreSystemMediator:enterLayer(disableTip)
    if disableTip then
        self:disableChooseTeamLayer(disableTip)
    end
    -- 先移除倒计时  防止多次请求
    exploreSystemMgr:stopExploreSystemCountdown()
    if self.exploreDatas then
        local questList = self.exploreDatas.questList or {}
        local questData = questList[self.curSelectOrder] or {}
        self.oldQuestId = questData.questId or 0
    end
    self:SendSignal(POST.EXPLORE_SYSTEM_HOME.cmdName)
end

function ExploreSystemMediator:updateUI(body)
    self.preCountDownSeconds = checkint(body.nextRefreshTime)
    self.exploreDatas   = exploreSystemMgr:initExploreDatas(body)
    if self.oldQuestId > 0 then
        local newIndex = exploreSystemMgr:getQuestIndexByQuestId(self.exploreDatas.questList, self.oldQuestId) 
        self.oldQuestId = 0
        if newIndex == 0 then
            self.curSelectOrder = 1
        else
            self.curSelectOrder = newIndex
        end
    else
        self.curSelectOrder = 1
    end
    
    self:GetViewComponent():refreshUI(self.exploreDatas)
    self:updateOrderInfo(self.curSelectOrder)
end

function ExploreSystemMediator:updateOrderState(isQuestEnd)
    local questList = self.exploreDatas.questList or {}
     -- 1.排序之前获取一下当前选中任务的数据ID
     local oldQuestId      = questList[self.curSelectOrder].questId
     -- 2.排序探索任务列表
     exploreSystemMgr:sortQuestList(questList)
     -- 3. 如果是探索任务刷新时间结束 则 至为1 否则 通过数据id 获取选中下标
     self.curSelectOrder = isQuestEnd and 1 or exploreSystemMgr:getQuestIndexByQuestId(questList, oldQuestId)
     
     local questData = questList[self.curSelectOrder]
     -- 4.更新订单信息
     self:updateOrderInfo(self.curSelectOrder)
     -- 5.更新探索任务列表
     if questData.status == exploreSystemMgr.QUEST_STATE.CLOSE then
         self.curSelectOrder = 0
     end
     self:GetViewComponent():updateList(questList)
end

function ExploreSystemMediator:updateOrderInfo(index, oldQuestId)
    local questList = self.exploreDatas.questList or {}
    local data = questList[index] or {}

    exploreSystemMgr:lazyInitQuestData(data)

    -- local oldData = nil
    -- if oldQuestId then
    --     oldData = self:getQuestDataByQuestId(oldQuestId)
    --     self.isControllable_ = false
    -- end
    local oldStatus = nil
    if oldQuestId then
        local oldData = self:getQuestDataByQuestId(oldQuestId)
        oldStatus = oldData.status
    end

    local viewComponent = self:GetViewComponent()
    viewComponent:updateOrderInfo(data)
end

function ExploreSystemMediator:getQuestDataByQuestId(questId)
    local questList = self.exploreDatas.questList or {}
    local index = exploreSystemMgr:getQuestIndexByQuestId(questList, questId)
    local questData = questList[index] or {}
    return questData
end

function ExploreSystemMediator:getTeamDataByQuestId(questId)
    local questData = self:getQuestDataByQuestId(questId)
    local teamData = questData.teamData or {}
    return teamData, questData
end

function ExploreSystemMediator:relieveTeamByQuestId(questId)
    local teamData, questData = self:getTeamDataByQuestId(questId)
    gameMgr:DeleteCardPlace(teamData, CARDPLACE.PLACE_EXPLORE_SYSTEM)
    return questData
end

function ExploreSystemMediator:disableChooseTeamLayer(disableTip)
    if self.chooseTeamLayer and not tolua.isnull(self.chooseTeamLayer) then
        self.chooseTeamLayer:SetDisableTip(disableTip)
    end
end
-------------------------------------------------
-- private method
function ExploreSystemMediator:onDataSourceAdapter(p_convertview,idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:GetViewComponent():CreateCell()
        display.commonUIParams(pCell.viewData.touchLayer, {cb = handler(self, self.onClickCellAction)})
    end

    local questList = self.exploreDatas.questList or {}
    local data = questList[index] or {}
    local viewData = pCell.viewData
    self:GetViewComponent():updateCell(viewData, data)
    self:GetViewComponent():updateCellSelectState(viewData, self.curSelectOrder == index)

    pCell.viewData.touchLayer:setTag(index)
    pCell:setTag(index)
    return pCell
end

-------------------------------------------------
-- show view
function ExploreSystemMediator:showEditTeamView()
    local questList = self.exploreDatas.questList or {}
    local data = questList[self.curSelectOrder] or {}
    local condition = data.condition
    local confData = data.confData
    local cardsNum = checkint(confData.cardsNum)

    -- logInfo.add(5,tableToString(condition))
    local layer = require('Game.views.exploreSystem.ExploreSystemChangeTeamScene').new({
        teamTowards = -1,
        avatarTowards = 1,
        teamChangeSingalName =  "EXPLORE_TEAM_CHANGE_NOTICE",
        teamInfoViewTag = 1,
        teamData = data.teamData or {},
        conditionData = condition,
        conditionRewardList = data.conditionRewardList,
        conditionBaseReward = {extraReward = confData.rewards},
        dataTag = data.questId,
        maxCardsAmount = cardsNum,
        isCheckCardStatus = true
    })
    layer:setAnchorPoint(cc.p(0.5, 0.5))
    layer:setPosition(display.center)
    layer:setTag(DIALOG_TAG.EDIT_TEAM)
    uiMgr:GetCurrentScene():AddDialog(layer)
    self.chooseTeamLayer = layer

    self:GetViewComponent():setTeamInfoViewShowState(false)
    
end

function ExploreSystemMediator:showCommonTip(text, extra, callback, tag)
    local CommonTip  = require( 'common.NewCommonTip' ).new({
        text = tostring(extra),
        isOnlyOK = false, callback = callback, cancelBack = function ()
            self.isControllable_ = true
        end
    })
    CommonTip:setPosition(display.center)
    CommonTip:setTag(tag)
    self:getOwnerScene():AddDialog(CommonTip)
end

-------------------------------------------------
-- check


-------------------------------------------------
-- handler

function ExploreSystemMediator:onButtonAction(sender)
    if not self.isControllable_ then return end

    local tag = sender:getTag()
    if tag == BUTTON_TAG.BACK then
        local callback = function ()
            PlayAudioByClickClose()
            self:GetFacade():UnRegsitMediator(NAME)
            -- local shareRouter = self:GetFacade():RetrieveMediator("Router")
            -- shareRouter:RegistBackMediators(true)
        end
        
        local questList = self.exploreDatas.questList or {}
        local data = questList[self.curSelectOrder] or {}
        local status = checkint(data.status)

        if status == exploreSystemMgr.QUEST_STATE.PREPARE and data.isCanQuest then
            self:showCommonTip(
                __('探索已编队，退出探索'),
                __('退出探索将清除当前编队信息！'),
                callback, 
                DIALOG_TAG.BACK
            )
        else
            callback()
        end
        
    else
        PlayAudioByClickNormal()
        local questList = self.exploreDatas.questList or {}
        -- if next(questList) == nil then return end
        local data = questList[self.curSelectOrder] or {}
        
        if tag == BUTTON_TAG.RULE then
            uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.EXPLORE_SYSTEM)]})
        elseif tag == BUTTON_TAG.EDIT then
            
            self:handleEditBtn(data)
            
        elseif tag == BUTTON_TAG.EXPLORE then

            self:handleExploreBtn(data)
            
        elseif tag == BUTTON_TAG.ACCELERATE_EXPLORE then
            
            local callback = function ()
                local confData          = data.confData
                local accelerateConsume = confData.accelerateConsume
                if accelerateConsume == nil then return end
                
                local confCompleteTime      = checkint(confData.completeTime)
                local goodsId           = accelerateConsume.goodsId
                -- 1. 获取当前拥有多少
                local ownCount          = CommonUtils.GetCacheProductNum(goodsId)
                -- 2.获取需要消耗多少
                -- 总共消耗多少
                local num               = checkint(accelerateConsume.num)
                -- 获取当前剩余的完成时间
                local completeTime      = data.completeTime
                local consumeCount      = num * math.ceil(completeTime / 3600)
                -- 3.检查数据状态 (只有在探索进行中 才会秒探索)
                if consumeCount > ownCount then
                    if GAME_MODULE_OPEN.NEW_STORE then
                        uiMgr:AddDialog("common.GainPopup", {goodId = goodsId})
                    else
                        uiMgr:ShowInformationTips(__('加速券不足, 请到商店购买'))
                    end
                else
                    self:SendSignal(POST.EXPLORE_SYSTEM_QUEST_ACCELERATE.cmdName, {questId = data.questId})
                end
            end
            self:showCommonTip(
                __('使用加速券'),
                __('是否使用加速券加速完成该探索?'),
                callback, 
                DIALOG_TAG.ACCELERATE
            )
            
        end
    end
end

function ExploreSystemMediator:handleEditBtn(data)
    local questState = exploreSystemMgr.QUEST_STATE
    local status = data.status and checkint(data.status) or questState.CLOSE
    if status == questState.PREPARE then
        self:showEditTeamView()
    elseif status == questState.END then
        -- todo 领奖励
        local questId = data.questId

        self:SendSignal(POST.EXPLORE_SYSTEM_QUEST_COMPLETE.cmdName, {questId = questId})

    elseif status == questState.CLOSE then
        uiMgr:ShowInformationTips(__('请耐心等待下一批任务刷新'))
    end
end

function ExploreSystemMediator:handleExploreBtn(data)
    local questState = exploreSystemMgr.QUEST_STATE
    local status = data.status and checkint(data.status) or questState.CLOSE
    local questId = data.questId
    if status == questState.PREPARE then
        -- 处理探索

        -- 1.检查是否有可派遣的队伍
        local surplusTeam = self.exploreDatas.surplusTeam
        if surplusTeam <= 0 then
            local additionalTeamCount = checkint(CommonUtils.getVipTotalLimitByField('exploreSystemTeamLimit'))
            local extra = additionalTeamCount > 0 and __('当前没有可派队伍了！') or __('当前没有可派队伍了！（购买月卡能使队伍上限+1）')
            local callback = function ()
                
            end
            self:showCommonTip(
                __('出征队伍已满，继续探索'),
                extra,
                callback, 
                DIALOG_TAG.EXPLORE
            )
            return
        end
        
        local teamData = data.teamData
        local cards = {}
        local count = 0
        for i, v in ipairs(teamData) do
            if checkint(v.id) then
                table.insert(cards, v.id)
                count = count + 1
            end
        end
        if count ~= checkint(data.confData.cardsNum) then
            uiMgr:ShowInformationTips(__("请完成编队后在进行探索"))
            return
        end
        self:SendSignal(POST.EXPLORE_SYSTEM_QUEST_START.cmdName, {questId = questId, cards = json.encode(cards)})

    elseif status == questState.ONGOING then

        local callback = function ()
            self:SendSignal(POST.EXPLORE_SYSTEM_QUEST_RETREAT.cmdName, {questId = questId})
        end
        self:showCommonTip(
            __('是否放弃当前的挑战进度'),
            __('撤退将失去所有奖励。'),
            callback, 
            DIALOG_TAG.RETREAT_TIP
        )
    elseif status == questState.END then
        uiMgr:ShowInformationTips(__("请通过领取来获取奖励"))
    elseif status == questState.CLOSE then
        
    end

end

function ExploreSystemMediator:onClickCellAction(sender)
    
    if not self.isControllable_ then return end
    
    local index = sender:getTag()
    local questList = self.exploreDatas.questList or {}
    local data = questList[index] or {}
    local questId = data.questId
    local questState = exploreSystemMgr.QUEST_STATE
    local status = data.status and checkint(data.status) or questState.CLOSE
    if status == questState.CLOSE then
        return
    end
    if self.curSelectOrder == index then return end

    -- self.isControllable_ = false

    local callback = function (oldQuestId)
        -- 检查一下数据状态
        status = checkint(data.status)
        if status == questState.CLOSE then
            -- self.isControllable_ = true
            return
        end
        
        local viewComponent = self:GetViewComponent()
        viewComponent:updateCellSelectStateByIndex(self.curSelectOrder, false)
        viewComponent:updateCellSelectStateByIndex(index, true)
        self:updateOrderInfo(index, oldQuestId)
        self.curSelectOrder = index

    end

    local oldData = questList[self.curSelectOrder] or {}
    local oldStatus = checkint(oldData.status)
    local oldQuestId = oldData.questId
    if oldStatus == questState.PREPARE and oldData.isCanQuest then
        self:showCommonTip(
            __('探索已编队，切换任务'),
            __('切换到其他探索将清除当前编队信息！'),
            function ()
                -- data.teamData = {}
                callback(oldQuestId)
                local oData = self:getQuestDataByQuestId(oldQuestId)
                oData.teamData = {}
                oData.isCanQuest = false
            end, 
            DIALOG_TAG.SWITCH_CELL
        )
    else
        callback(oldQuestId)       
    end

    -- local questList = self.exploreDatas.questList or {}
    -- local data = questList[index] or {}
    -- viewComponent:updateOrderInfo(data) 
end

return ExploreSystemMediator
