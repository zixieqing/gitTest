--[[
 * descpt : 品鉴之旅 探索 中介者
]]
local NAME = 'TastingTourQuestMediator'
local TastingTourQuestMediator = class(NAME, mvc.Mediator)

local AppFacadeInstance = AppFacade.GetInstance()
local uiMgr    = AppFacadeInstance:GetManager('UIManager')
local gameMgr  = AppFacadeInstance:GetManager("GameManager")
local timerMgr = AppFacadeInstance:GetManager("TimerManager")
local tastingTourMgr = AppFacadeInstance:GetManager("TastingTourManager")

local VIEW_TAG = {
    GROUP_TASK      = 1,
    QUEST_DESC      = 2,
}

local GROUP_TASK_TAG = {
    COMPLETED = 1,
    CONDUCT   = 2,
    LOCK  = 3,
}

local QUEST_TASK_TAG = {
    NORMAL      = 1,
    SELECT      = 2,
    COUNT_DOWN  = 3,
}

function TastingTourQuestMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    -- zoneId, stageId
end

-------------------------------------------------
-- inheritance method
function TastingTourQuestMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    self.activeJump = true

    -- create view
    local viewComponent = require('Game.views.tastingTour.TastingTourQuestView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    -- add layer
    self.ownerScene_ = uiMgr:GetCurrentScene()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:getOwnerScene():AddGameLayer(viewComponent)

    -- init data
    self:initData_()
    -- init view
    self:initView_()
    
end

function TastingTourQuestMediator:initData_()

    local args = self:getCtorArgs()
    local zoneId, stageId = args.zoneId or 1 , args.stageId or 1
    
    local groupIndex, questIndex = tastingTourMgr:InitQuestGroupDatas(zoneId, stageId)
    self.datas = tastingTourMgr:GetQuestGroupDatas()
    
    self.curStageId    = stageId
    self.curQuestIndex = args.defQuestIndex or questIndex
    self.curGroupIndex = args.defGroupIndex or groupIndex
    
end

function TastingTourQuestMediator:initView_()
    local viewData = self:getViewData()

    local shallowLayer = viewData.shallowLayer
    display.commonUIParams(shallowLayer, {cb = function ( ... )
        self:GetFacade():UnRegsitMediator(NAME)
    end})

    local ruleBtn = viewData.ruleBtn
    display.commonUIParams(ruleBtn, {cb = handler(self, self.onClickRuleAction)})

    local listLen = #self.datas
    local groupGridView = viewData.groupGridView
    groupGridView:setDataSourceAdapterScriptHandler(handler(self, self.onTaskGroupDataSource))
    groupGridView:setCountOfCell(listLen)
    groupGridView:reloadData()

    if self.curGroupIndex ~= 0 and self.curGroupIndex <= listLen then
        local offsetH = CommonUtils.calcListContentOffset(groupGridView:getContentSize().height, listLen, groupGridView:getSizeOfCell().height, self.curGroupIndex)
        groupGridView:setContentOffset(cc.p(0, offsetH))
    end

    local worldTitleBtn = viewData.worldTitleBtn
    display.commonLabelParams(worldTitleBtn, {text = tastingTourMgr:GetStageNameByStageId(self.curStageId)})

    self:jumpQuestDescLayer(self.curGroupIndex, self.curQuestIndex, true)
end

function TastingTourQuestMediator:CleanupView()
    if self.ownerScene_ and self:getViewData().view:getParent() then
        self.ownerScene_:RemoveDialog(self:GetViewComponent())
        self.ownerScene_ = nil
    end
end


function TastingTourQuestMediator:OnRegist()
    regPost(POST.CUISINE_UNLOCK_CUISINE_GROUP)
    regPost(POST.CUISINE_DRAWGROUPREWARD)
    
    self:enterLayer()
end
function TastingTourQuestMediator:OnUnRegist()
    unregPost(POST.CUISINE_UNLOCK_CUISINE_GROUP)
    unregPost(POST.CUISINE_DRAWGROUPREWARD)
end


function TastingTourQuestMediator:InterestSignals()
    return {
        COUNT_DOWN_ACTION_UI_ACTION_TASTING_TOUR_QUEST,
        POST.CUISINE_UNLOCK_CUISINE_GROUP.sglName,
        POST.CUISINE_DRAWGROUPREWARD.sglName,
    }
end

function TastingTourQuestMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    
    if name == COUNT_DOWN_ACTION_UI_ACTION_TASTING_TOUR_QUEST then
        local viewData = self:getViewData()
        local questDescView = viewData.questDescView
        if questDescView and questDescView:isVisible() then
            local gridView = questDescView.viewData.gridView
            local cells = gridView:getCells()
            if cells and #cells > 0 then
                for i, cell in ipairs(cells) do
                    local questId = cell:getTag()
                    local leftSecondList = tastingTourMgr:GetLeftSecondList()
                    local leftSeconds = checkint(leftSecondList[tostring(questId)])
                    local countDown   = cell.viewData.countDown
                    
                    self:GetViewComponent():updateQuestCountDownUi(countDown, leftSeconds)
                end
            end
        end
    elseif name == POST.CUISINE_UNLOCK_CUISINE_GROUP.sglName then
        -- todo 刷新 grouplist
        local requestData = checktable(body.requestData)
        local groupId     = requestData.groupId
        local index       = requestData.index
        tastingTourMgr:MergeCuisineGroupMaps({[tostring(groupId)] = index})

        local questGroupData        = self.datas[index]
        questGroupData.unlocked     = true

        local viewData = self:getViewData()
        local groupGridView = viewData.groupGridView
        local cell = groupGridView:cellAtIndex(index - 1)
        if cell then
            local viewData = cell.viewData
            local groupState = self:getGroupState(questGroupData.unlocked, questGroupData.isComplete, questGroupData.canUnlock)
            self:GetViewComponent():updateGroupTaskCell(viewData, groupState, questGroupData.groupConfData.frameId or 1)
        end
       
        self.curQuestIndex = 1
        self.curGroupIndex = index
        self.activeJump = true
        self:jumpQuestDescLayer(index, self.curQuestIndex)
    elseif name == POST.CUISINE_DRAWGROUPREWARD.sglName then
        -- todo 更新 group领取状态
        local requestData = checktable(body.requestData)
        local groupRewardId = checkint(requestData.groupRewardId)
        local groupIndex = checkint(requestData.groupIndex)
        tastingTourMgr:SetGroupDrawGroupReward({id = groupRewardId, hasDrawn = 1})
        local rewards = body.rewards or {}

        -- 更新 阶段奖励按钮显示状态
        local viewData = self:getViewData()
        local questDescView = viewData.questDescView
        local questDescViewData = questDescView.viewData
        local rewardBtns = questDescViewData.rewardBtns
        local groupData = self.datas[groupIndex] or {}
        local questIds = groupData.questIds
        local groupConfRewards = groupData.groupConfData.groupRewards or {}
        local fishStarNum = tastingTourMgr:GetGroupStarNumByQuestIds(questIds)

        local oneGroupRewardConf = tastingTourMgr:GetOneGroupRewardConfig(groupRewardId)
        local startNum = checkint(oneGroupRewardConf.starNum)
        local view = require('Game.views.tastingTour.TastingTourQuestStarsRewardView').new({rewards = rewards, startNum = startNum})
        display.commonUIParams(view, {po = display.center, ap = display.CENTER})
        self:getOwnerScene():AddDialog(view)

        self:GetViewComponent():updateGroupRewardBtns(rewardBtns, groupConfRewards, fishStarNum)
    end

end 

-------------------------------------------------
-- get / set

function TastingTourQuestMediator:getCtorArgs()
    return self.ctorArgs_
end

function TastingTourQuestMediator:getViewData()
    return self.viewData_
end

function TastingTourQuestMediator:getOwnerScene()
    return self.ownerScene_
end

function TastingTourQuestMediator:getGroupState(unlocked, isComplete, canUnlock)
    local groupState = GROUP_TASK_TAG.LOCK
    -- local curRestaurantLevel = checkint(gameMgr:GetUserInfo().restaurantLevel)
    -- 如果能解锁  给个 CONDUCT 状态
    if canUnlock then
        groupState = GROUP_TASK_TAG.CONDUCT
    elseif unlocked then
        if isComplete then
            groupState = GROUP_TASK_TAG.COMPLETED
        else
            groupState = GROUP_TASK_TAG.CONDUCT
        end
    end
    
    return groupState
end

-------------------------------------------------
-- public method
function TastingTourQuestMediator:enterLayer()
    
    -- 为0  检查 是否能解锁 当前组
     if self.curGroupIndex == 0 then
        local index = 1
        local data = self.datas[index]
        local groupId = data.groupId
        local groupConfData = data.groupConfData or {}
        local unlockLevel = checkint(groupConfData.level)
        self:checkIsSatisfyUnlockCondition(unlockLevel, groupId, index)
    else
    -- 否则 检查 是否能领取组阶段奖励
        local data = self.datas[self.curGroupIndex]
        if data then
            self:checkDrawGroupRewards(data)
        end
    end
end

-------------------------------------------------
-- private method
function TastingTourQuestMediator:onTaskGroupDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:GetViewComponent():CreateGroupTaskCell()
        display.commonUIParams(pCell.viewData.touchLayer, {cb = handler(self, self.onCilckGroupAction)}) 
    end
     
    xTry(function()
        local questGroupData        = self.datas[index]
        local groupConfData         = questGroupData.groupConfData
        if groupConfData == nil then
            groupConfData = tastingTourMgr:GetGroupConfDataByGroupId(questGroupData.groupId)
            questGroupData.groupConfData = groupConfData
        end
        
        local viewData    = pCell.viewData
        local nameLabel   = viewData.nameLabel
        display.commonLabelParams(nameLabel, {text = tostring(groupConfData.name)})
       
        local groupState = self:getGroupState(questGroupData.unlocked, questGroupData.isComplete, questGroupData.canUnlock)
        
        self:GetViewComponent():updateGroupTaskCell(viewData, groupState, questGroupData.groupConfData.frameId or 1)
        
        local touchLayer  = viewData.touchLayer
        touchLayer:setTag(index)
	end,__G__TRACKBACK__)
    
    return pCell
end

function TastingTourQuestMediator:onQuestTaskDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:GetViewComponent():CreateQuestTaskCell()
        display.commonUIParams(pCell.viewData.touchLayer, {cb = handler(self, self.onCilckQuestAction)})
    end
     
    xTry(function()
        local viewData       = pCell.viewData

        local curQuestDatas  = self.datas[self.curGroupIndex]
        local questIds       = curQuestDatas.questIds
        local serQuestDatas  = curQuestDatas.serQuestDatas
        local questConfDatas = curQuestDatas.questConfDatas
        local questId        = questIds[index]
        local serQuestData   = serQuestDatas[tostring(questId)]
        local questConfData  = questConfDatas[tostring(questId)]
        -- if serQuestData == nil then
        --     serQuestData = tastingTourMgr:GetSerQuestDataByQuestId(questId)
        --     serQuestDatas[tostring(questId)] = serQuestData
        -- end
        if questConfData == nil then
            questConfData = tastingTourMgr:GetQuestConfigDataByQuestId(questId)
            questConfDatas[tostring(questId)] = questConfData
        end

        self:GetViewComponent():updateQuestTaskCell(viewData, questConfData, serQuestData, index == self.curQuestIndex)

        local touchLayer  = viewData.touchLayer
        touchLayer:setTag(index)
        pCell:setTag(checkint(questId))
	end,__G__TRACKBACK__)

    return pCell
    
end

function TastingTourQuestMediator:jumpQuestDescLayer(groupIndex, questIndex)
    -- 所有组都没有解锁  直接解锁第一个

    local curQuestDatas  = self.datas[groupIndex]
    if curQuestDatas == nil then return end
    -- 如果该组不是解锁状态 
    if not curQuestDatas.unlocked then return end
    self:enterQuestDescLayer(groupIndex, questIndex, true)
end

function TastingTourQuestMediator:enterQuestDescLayer(groupIndex, questIndex, isInit)
    local viewData = self:getViewData()
    local questGroupLayer = viewData.questGroupLayer
    local questDescView = viewData.questDescView
    if questDescView == nil then
        viewData.questDescView = self:createQuestDescView()
    end

    if isInit then
        viewData.questDescView:setVisible(true)
        questGroupLayer:setVisible(false)
    else
        self:GetViewComponent():showUiAction(VIEW_TAG.QUEST_DESC)
    end

    self:updateQuestDescView(groupIndex)
    
    -- 如果是主动跳转 发送 SIGNALNAMES.SEND_CURRENT_QUEST_INFO_EVENT 更新 酵母菌
    if self.activeJump then
        self.activeJump = false
        local curQuestDatas  = self.datas[groupIndex]
        local questId        = curQuestDatas.questIds[questIndex] or curQuestDatas.questIds[1]
        self:GetFacade():DispatchObservers(SIGNALNAMES.SEND_CURRENT_QUEST_INFO_EVENT, {questId = questId})
    end
end

function TastingTourQuestMediator:createQuestDescView()
    local viewData = self:getViewData()
    local questDescView = self:GetViewComponent():CreateQuestDescView()
    local view = viewData.view
    view:addChild(questDescView)

    local questDescViewData = questDescView.viewData
    display.commonUIParams(questDescViewData.titleBg, {cb = handler(self, self.onCilckTitleBgAction)})

    local rewardBtns = questDescViewData.rewardBtns
    for i, btn in ipairs(rewardBtns) do
        display.commonUIParams(btn, {cb = handler(self, self.onCilckGroupRewardAction)})
        btn:setTag(i)
    end

    local gridView = questDescViewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self, self.onQuestTaskDataSource))

    return questDescView
end

function TastingTourQuestMediator:updateQuestDescView(groupIndex)
    local viewData = self:getViewData()
    local questDescView = viewData.questDescView
    local questDescViewData = questDescView.viewData

    local curQuestDatas = self.datas[groupIndex]
    
    if curQuestDatas.serQuestDatas == nil then
        local serQuestDatas = {}
        local questIds = curQuestDatas.questIds
        
        for i, questId in ipairs(questIds) do
            local serQuestData = tastingTourMgr:GetSerQuestDataByQuestId(questId)
            
            serQuestDatas[tostring(questId)] = serQuestData
        end
        
        curQuestDatas.serQuestDatas = serQuestDatas
    end
    if curQuestDatas.questConfDatas == nil then
        curQuestDatas.questConfDatas = {}
    end
    
    self:GetViewComponent():updateQuestDescView(curQuestDatas, self.curQuestIndex)
    local nameLabel = questDescViewData.nameLabel
    local groupConfData = curQuestDatas.groupConfData or {}
    local groupName      = tostring(groupConfData.name)
    display.commonLabelParams(nameLabel, {text = groupName})

end

-------------------------------------------------
-- check
--[[
    检查是否是解锁group
    @params 点击的group 下标

    @return isUnlockState 是否能解锁   tipText 提示文字
--]] 
function TastingTourQuestMediator:checkIsUnlockGroup(index)
    
    local clickGroupData = self.datas[index]
    local groupConfData  = clickGroupData.groupConfData
    local clickGroupId   = checkint(clickGroupData.groupId)
    local clickGroupIsUnlocked = tastingTourMgr:CheckIsUnlockedGroup(clickGroupId)
    local tipText = nil
    local isUnlockState  = not clickGroupIsUnlocked
    -- 1 检查点击的group是否解锁
    if isUnlockState then
        local preGroupId = clickGroupId - 1
        local preGroupData = {}
        for i, v in ipairs(self.datas) do
            if checkint(v.groupId) == preGroupId then
                preGroupData = v
                break
            end
        end
        
        -- 2 检查上一组group的quest任务是否全部完成
        local preGroupIsComplete = tastingTourMgr:CheckQuestGroupCompleteState(preGroupData.questIds or {})
        if preGroupIsComplete then
            local unlockLevel = checkint(tastingTourMgr:GetGroupConfDataByGroupId(clickGroupId).level)
            tipText = self:checkIsSatisfyUnlockCondition(unlockLevel, clickGroupId, index)
        else
            tipText = __('上一个地区的星牌尚未全部获得，无法开启')
        end
    end
    return isUnlockState, tipText
end

function TastingTourQuestMediator:checkIsSatisfyUnlockCondition(unlockLevel, groupId, index)
    local curRestaurantLevel = checkint(gameMgr:GetUserInfo().restaurantLevel)
    local tipText = nil
    if curRestaurantLevel >= unlockLevel then
        -- todo 发送解锁请求
        self:SendSignal(POST.CUISINE_UNLOCK_CUISINE_GROUP.cmdName, {groupId = groupId, index = index})
    else
        tipText = string.fmt(__('餐厅等级不足_num_, 无法开启'), {['_num_'] = unlockLevel})
    end
    return tipText
end

function TastingTourQuestMediator:checkDrawGroupRewards(data)
    local questIds = data.questIds
    local fishStarNum = tastingTourMgr:GetGroupStarNumByQuestIds(questIds)
    local groupConfRewards = data.groupConfData.groupRewards or {}
    local rewardStates = {}
    
    for i, groupRewardId in pairs(groupConfRewards) do
        local rewardState = tastingTourMgr:GetGroupRewardStatus(groupRewardId, fishStarNum)
        -- table.insert(rewardStates, rewardState)
        
        if rewardState == 1 then
            -- 发送请求
            self:SendSignal(POST.CUISINE_DRAWGROUPREWARD.cmdName, {groupRewardId = groupRewardId, groupIndex = self.curGroupIndex})
        end
    end
end

-------------------------------------------------
-- handler

function TastingTourQuestMediator:onClickRuleAction(sender)
    -- self.curGroupIndex
    local stageConf = tastingTourMgr:GetStageConfByStageId(self.curStageId)
    local rewards = stageConf.rewards or {}

    local rewardsLen = #rewards
    local tipLabel = display.newRichLabel(0, 0,
        {ap = display.LEFT_TOP, w = 85, r = true, c = {
            fontWithColor('6', {text = __('每个关卡获得三枚')}),
            {img = _res("ui/tastingTour/quest/fishtravel_main_list_ico_star_s.png"), scale = 0.8},
            fontWithColor('6', {text = __(', 都将获得以下奖励: ')}),
        }
    })

    local maxCol = 3
    local row = math.floor((rewardsLen - 1) / maxCol) + 1
    local labelContentSize = display.getLabelContentSize(tipLabel)
    logInfo.add(5, tableToString(labelContentSize))
    local additionalH = row * 90 + 30
    local contentSize = cc.size(labelContentSize.width + 22, labelContentSize.height + additionalH)
    tipLabel:setPosition(cc.p(10, contentSize.height -10 ))
    
    local layout = display.newLayer(contentSize.width/2, contentSize.height/2, { size = contentSize ,ap = display.RIGHT_BOTTOM ,color = cc.c4b(0,0,0,0)})
    layout:addChild(tipLabel ,2)
    local image  = display.newImageView( _res('ui/common/common_bg_tips_common'),contentSize.width/2,contentSize.height/2, { scale9 = true , ap =  display.CENTER, size = contentSize})
    layout:addChild(image)
    local tipImage = display.newImageView(_res('ui/common/common_bg_tips_horn') , contentSize.width/10 * 9, contentSize.height - 2)
    layout:addChild(tipImage)
    -- tipImage:setScale(-1)
    local pos = cc.p(sender:getPosition())
    local wordPos =  sender:getParent():convertToWorldSpace(pos)
    layout:setName("layout")

    local params = {parent = layout, midPointX = contentSize.width / 2, midPointY = tipLabel:getPositionY() - labelContentSize.height - additionalH / 2 + 10, maxCol = maxCol, scale = 0.8, rewards = rewards, hideCustomizeLabel = true}
    CommonUtils.createPropList(params)

    local closeLayer = display.newLayer(display.cx, display.cy , {ap = display.CENTER , color = cc.c4b(0,0,0,0) , enable = true , cb = function(sender)
        sender:runAction(cc.RemoveSelf:create())
    end})
    uiMgr:GetCurrentScene():AddDialog(closeLayer)
    closeLayer:addChild(layout)

    local senderSize = sender:getContentSize()
    local pos = closeLayer:convertToNodeSpace(wordPos)
    layout:setPosition(cc.p(pos.x + senderSize.width / 2 + contentSize.width * 0.1, pos.y - contentSize.height - senderSize.height / 2))
end

function TastingTourQuestMediator:onCilckGroupAction(sender)
    if not self.isControllable_ then return end
    PlayAudioByClickNormal()

    local tag = sender:getTag()

    local isUnlockState, tipText = self:checkIsUnlockGroup(tag)
    if isUnlockState then
        if tipText then
            uiMgr:ShowInformationTips(tipText)
        end
        return
    end
    if self.curGroupIndex == tag then return end
    self.curGroupIndex = tag

    self:enterQuestDescLayer(tag, self.curQuestIndex)

end

function TastingTourQuestMediator:onCilckGroupRewardAction(sender)
    local tag = sender:getTag()
    -- 1.获取当前的GroupID
    local curGroupData = self.datas[self.curGroupIndex]
    local questIds = curGroupData.questIds or {}
    local groupConfData = curGroupData.groupConfData or {}
    local groupRewards = groupConfData.groupRewards or {}
    local groupRewardId = groupRewards[tostring(tag)]
    
    local fishStarNum = tastingTourMgr:GetGroupStarNumByQuestIds(questIds)
    local rewardStaus = tastingTourMgr:GetGroupRewardStatus(groupRewardId, fishStarNum)
    
    if rewardStaus == 1 then
        self:SendSignal(POST.CUISINE_DRAWGROUPREWARD.cmdName, {groupRewardId = groupRewardId, groupIndex = self.curGroupIndex})
    else
        local oneGroupRewardConf = tastingTourMgr:GetOneGroupRewardConfig(groupRewardId)
        local rewards = oneGroupRewardConf.rewards or {}
        local tag = 111
        local listTipText = {
            fontWithColor(4, {fontSize = 18, text = string.fmt(__('当前篇章收集_num_枚'), {['_num_'] = oneGroupRewardConf.starNum})}),
            {img = _res("ui/tastingTour/quest/fishtravel_main_list_ico_star_s.png"), scale = 0.93},
            fontWithColor(4, {fontSize = 18, text = __('奖励')}),
        }
        local layer = require('common.RewardDetailPopup').new({tag = tag, rewards = rewards, viewType = 2, listTipText = listTipText})
        	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
        layer:setTag(tag)
        uiMgr:GetCurrentScene():AddDialog(layer)
    end
end

function TastingTourQuestMediator:onCilckQuestAction(sender)
    if not self.isControllable_ then return end
    PlayAudioByClickNormal()

    local tag = sender:getTag()
    if tag == self.curQuestIndex then return end

    local viewData = self:getViewData()
    local questDescView = viewData.questDescView
    local gridView = questDescView.viewData.gridView

    -- 更新旧的cell 的选择状态
    self:GetViewComponent():updateQuestCellSelectState(gridView, self.curQuestIndex - 1, false)
    
    -- 更新新的cell 的选择状态
    self:GetViewComponent():updateQuestCellSelectState(gridView, tag - 1, true)
    
    local questIds = self.datas[self.curGroupIndex].questIds
    local questId  = questIds[tag]
    self:GetFacade():DispatchObservers(SIGNALNAMES.SEND_CURRENT_QUEST_INFO_EVENT, {questId = questId})
    self.curQuestIndex = tag

end

function TastingTourQuestMediator:onCilckTitleBgAction(sender)
    if not self.isControllable_ then return end
    PlayAudioByClickNormal()

    self:GetViewComponent():showUiAction(VIEW_TAG.GROUP_TASK)

    self.curGroupIndex = nil
    self.activeJump = true
end

return TastingTourQuestMediator