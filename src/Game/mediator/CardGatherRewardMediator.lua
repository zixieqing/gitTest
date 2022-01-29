local Mediator = mvc.Mediator
local socket = require('socket')
---@class CardGatherRewardMediator
local CardGatherRewardMediator = class("CardGatherRewardMediator", Mediator)
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance('AppFacade'):GetManager("CardManager")

local NAME = "CardGatherRewardMediator"

function CardGatherRewardMediator:ctor( params,viewComponent )
    self.super:ctor(NAME,viewComponent)

    if params then
		self.rewardData = params
	end
end

function CardGatherRewardMediator:InterestSignals()
	local signals = {
        SIGNALNAMES.CARD_GATHER_AREA_REWARD_CALLBACK,
        SIGNALNAMES.CARD_GATHER_CP_REWARD_CALLBACK,
	}
	return signals
end

function CardGatherRewardMediator:ProcessSignal( signal )
    local name = signal:GetName()
    -- dump(signal:GetBody())
    if name == SIGNALNAMES.CARD_GATHER_AREA_REWARD_CALLBACK then
        uiMgr:AddDialog('common.RewardPopup', {rewards = signal:GetBody().rewards})
        local data = signal:GetBody()
        local areaReward = CommonUtils.GetConfigAllMess('areaRewards','cardCollection')
        for _, v in pairs(areaReward) do
            if v[tostring(data.requestData.rewardId)] then
                local areaId = v[tostring(data.requestData.rewardId)].areaId
                local areaReceived = string.split(data.received, ",")
                for _, stage in pairs(self.areaAvailable[tostring(areaId)]) do
                    stage.received = false
                    for _, rewardId in pairs(areaReceived) do
                        if tostring(stage.rewardId) == tostring(data.requestData.rewardId) then
                            stage.received = true
                            break
                        end
                    end
                end
                for index, areaData in pairs(self.areaData) do
                    if tostring(areaData.areaId) == tostring(areaId) then
                        self:UpdateAreaProgress(index)
                        break
                    end
                end
                break
            end
        end
        self:CalcRedPoint()
    elseif name == SIGNALNAMES.CARD_GATHER_CP_REWARD_CALLBACK then
        uiMgr:AddDialog('common.RewardPopup', {rewards = signal:GetBody().rewards})
        local data = signal:GetBody()
        local cpId = 0
        local areaId = 0
        local groupRewards = CommonUtils.GetConfigAllMess('groupRewards','cardCollection') or {}
        for k, v in pairs(groupRewards) do
            if v[tostring(data.requestData.rewardId)] then
                cpId = tostring(k)
                break
            end
        end
        local groupMembers = CommonUtils.GetConfigAllMess('groupMembers','cardCollection') or {}
        for k, v in pairs(groupMembers) do
            if v[tostring(cpId)] then
                areaId = tostring(k)
                break
            end
        end
        local cpReceived = string.split(data.received, ",")
        self.available[areaId][cpId].received = cpReceived
        for index, areaData in pairs(self.areaData) do
            if tostring(areaData.areaId) == areaId then
                self:UpdateCPProgress(index)
                break
            end
        end
        self:CalcRedPoint()
    end
end

function CardGatherRewardMediator:Initial( key )
    self.super.Initial(self,key)
    
	local viewComponent = uiMgr:SwitchToTargetScene('Game.views.CardGatherRewardView')
    self:SetViewComponent(viewComponent)
    
	self.viewData = nil
    self.viewData = viewComponent.viewData
    self.viewCollect = {}       --  收集不同的view界面
    self.areaData = {}          --  地区信息
    self.areaTabs = {}          --  地区标签按钮
    self.currentClickCP = {cpId = 0, index = 0}    --  当前选择领取的CP奖励
    -- 计算当前的进度
    self:CalcProgress()
    
    -- 底部地区按钮
    local areaTabsView = self.viewData.areaTabsView
    local totalWidth = 0
    xTry(function()
        for k, v in pairs(self.areaData) do
            local pCell = require('Game.views.AreaCellView').new(self.viewData.cellSize, k, table.nums(self.areaData))
            pCell:UpdateView(v)
            table.insert(self.areaTabs, pCell.viewData.clickLayer)
            pCell.viewData.clickLayer:setTag(checkint(k))
            pCell.viewData.clickLayer:setOnClickScriptHandler(function (sender)
                PlayAudioByClickNormal()
                if not self.viewCollect[sender:getTag()] then
                    self:CellButtonAction(sender) 
                    self:UpdateProgress(sender:getTag())
                else
                    self:CellButtonAction(sender) 
                end
            end)
            areaTabsView:insertNodeAtLast(pCell)
            totalWidth = totalWidth + pCell:getContentSize().width
        end
    end, __G__TRACKBACK__)
    areaTabsView:setContentSize(cc.size(math.min(totalWidth, display.width), areaTabsView:getContentSize().height))
    areaTabsView:reloadData()

    if 0 < table.nums(self.areaTabs) then
        self:CellButtonAction(self.areaTabs[1])
        self:CalcRedPoint()
        for i = 1, table.nums(self.areaTabs) do
            self:UpdateProgress(i)
        end
    end
end

-- 点击地区按钮回调
function CardGatherRewardMediator:CellButtonAction(sender)
	local index = sender:getTag()
	if index == self.preIndex then return end
	-- 更新按钮状态
	local viewComponent = self:GetViewComponent()
    local listView = viewComponent.viewData.areaTabsView
    local currentCell = listView:getNodeAtIndex(index - 1)
    if currentCell then
        currentCell.viewData.backLight:setVisible(true)
    end
    if self.preIndex then 
	    local preCell = listView:getNodeAtIndex(self.preIndex - 1)
        if preCell then
            preCell.viewData.backLight:setVisible(false)
        end
        if self.viewCollect[self.preIndex] then
            self.viewCollect[self.preIndex]:setVisible(false)
        end
    end
    
    -- 显示地区飨灵详细
    if not self.viewCollect[index] then
        self.viewCollect[index] = viewComponent:CreateCardGatherLayout(self.areaData[index], self.available[tostring(self.areaData[index].areaId)])

        local areaProgress = self:getAreaDetail(self.areaData[index].cpGroups)
        self.viewCollect[index]:setLabelText(self.viewCollect[index].viewData.cardCountLabel, areaProgress.ownCards, areaProgress.totalCards)
        self.viewCollect[index]:setLabelText(self.viewCollect[index].viewData.starCountLabel, areaProgress.starCount, 5 * tonumber(areaProgress.totalCards))
        self.viewCollect[index]:setLabelText(self.viewCollect[index].viewData.contractLevelCountLabel, areaProgress.contractCount, 6 * tonumber(areaProgress.totalCards))
        self.viewCollect[index].viewData.cardCountLabel:setScale(0.8)
        self.viewCollect[index].viewData.starCountLabel:setScale(0.8)
        self.viewCollect[index].viewData.contractLevelCountLabel:setScale(0.8)
        local areaId = self.viewCollect[index].areaData.areaId
        if 0 == table.nums(self.areaAvailable[tostring(areaId)]) then
            self.viewCollect[index].viewData.areaFinishImg:setVisible(false)
        end
        for k, v in pairs(self.areaAvailable[tostring(areaId)]) do
            if not v.available then
                self.viewCollect[index].viewData.areaFinishImg:setVisible(false)
                break
            end
        end
    else
        self.viewCollect[index]:setVisible(true)
    end
    self.preIndex = index
end

-- 更新奖励的进度
function CardGatherRewardMediator:UpdateProgress(index)
    self:UpdateAreaProgress(index)
    self:UpdateCPProgress(index, true)
end

-- 更新地区奖励的进度
function CardGatherRewardMediator:UpdateAreaProgress(index)
    if self.viewCollect[index] then
        local areaId = self.viewCollect[index].areaData.areaId
        local areaReward = CommonUtils.GetConfigAllMess('areaRewards','cardCollection')[tostring(areaId)]
        local progress = self.areaAvailable[tostring(areaId)]
        local chestSpine = self.viewCollect[index].viewData.chestSpine
        self.viewCollect[index].viewData.clickLayer:setTouchEnabled(false)
        -- 没有配置地区奖励
        if 0 == table.nums(progress) then
            chestSpine:setAnimation(0, 'play', true)
        end
        local allRewardReceived = true
        local areaProgress = self:getAreaDetail(self.areaData[index].cpGroups)
        for k, v in pairs(progress) do
            -- 可以领取
            if v.available and not v.received then
                chestSpine:setAnimation(0, 'idle', true)
                allRewardReceived = false
                -- local availableReward = areaReward[tostring(v.rewardId)]
                -- self.viewCollect[index]:setLabelText(self.viewCollect[index].viewData.starCountLabel, areaProgress.starCount, availableReward.require.star)
                -- self.viewCollect[index]:setLabelText(self.viewCollect[index].viewData.contractLevelCountLabel, areaProgress.contractCount, availableReward.require.love)
                self.viewCollect[index].viewData.clickLayer:setTouchEnabled(true)
                self.viewCollect[index].viewData.clickLayer:setOnClickScriptHandler(function (sender)
                    PlayAudioByClickNormal()
                    self:SendSignal(COMMANDS.COMMANDS_CARD_GATHER_AREA_REWARD, {rewardId = v.rewardId})
                end)
                break
            -- 未达到
            elseif not v.available and not v.received then
                chestSpine:setAnimation(0, 'stop', true)
                allRewardReceived = false
                -- local availableReward = areaReward[tostring(v.rewardId)]
                -- self.viewCollect[index]:setLabelText(self.viewCollect[index].viewData.starCountLabel, areaProgress.starCount, availableReward.require.star)
                -- self.viewCollect[index]:setLabelText(self.viewCollect[index].viewData.contractLevelCountLabel, areaProgress.contractCount, availableReward.require.love)
                self.viewCollect[index].viewData.clickLayer:setTouchEnabled(true)
                self.viewCollect[index].viewData.clickLayer:setOnClickScriptHandler(function (sender)
                    PlayAudioByClickNormal()
                    local availableReward = areaReward[tostring(v.rewardId)]
                    local cpGroupReward = clone(availableReward)
                    cpGroupReward.starCount = areaProgress.starCount
                    cpGroupReward.contractCount = areaProgress.contractCount
                    uiMgr:ShowRewardInformationTips({targetNode = sender, type = 11, bgSize = cc.size(320, 231), cpGroupReward = cpGroupReward})
                end)
                break
            end
        end
        -- 所有奖励都已领取
        if allRewardReceived then
            chestSpine:setAnimation(0, 'play', true)
            -- local availableReward = areaReward[tostring(progress[#progress].rewardId)]
            -- self.viewCollect[index]:setLabelText(self.viewCollect[index].viewData.starCountLabel, areaProgress.starCount, availableReward.require.star)
            -- self.viewCollect[index]:setLabelText(self.viewCollect[index].viewData.contractLevelCountLabel, areaProgress.contractCount, availableReward.require.love)
        end
    end
end

-- 更新所有cp奖励的进度
function CardGatherRewardMediator:UpdateCPProgress(index, isFirst)
    if self.viewCollect[index] then
        local CPGroupCells = self.viewCollect[index].viewData.CPGroupCells
        for _, v in pairs(CPGroupCells) do
            local available = self.available[tostring(self.viewCollect[index].areaData.areaId)][tostring(v:getTag())]
            -- 全部领取完
            if table.nums(available.received) >= table.nums(v.viewData.rewardImgs) then
                v:setStarAndHeartVisible(true)
                v:HideProgress()
            else
                for k, rewardImg in pairs(v.viewData.rewardImgs) do
                    local available = self.available[tostring(self.viewCollect[index].areaData.areaId)][tostring(v:getTag())]
                    local isReceived = false
                    -- 已经领取过
                    for _, receivedId in pairs(available.received) do
                        if tonumber(receivedId) == rewardImg:getTag() then
                            v.viewData.completeImages[k]:setVisible(true)
                            v.viewData.backLights[k]:setVisible(false)
                            rewardImg:setVisible(false)
                            v.viewData.clickLayers[k]:setTouchEnabled(false)
                            isReceived = true
                            break
                        end
                    end
                    if isFirst then
                        if not isReceived then
                            -- 可以领取
                            local isAvailable = false
                            for _, availableId in pairs(available.available) do
                                if tonumber(availableId) == rewardImg:getTag() then
                                    rewardImg:stopAllActions()
                                    rewardImg:runAction(cc.RepeatForever:create((cc.JumpBy:create(1, cc.p(0, 0), 10, 1))))
                                    v.viewData.completeImages[k]:setVisible(false)
                                    v.viewData.backLights[k]:setVisible(true)
                                    v.viewData.clickLayers[k]:setTouchEnabled(true)
                                    v.viewData.clickLayers[k]:setOnClickScriptHandler(function (sender)
                                        PlayAudioByClickNormal()
                                        self:SendSignal(COMMANDS.COMMANDS_CARD_GATHER_CP_REWARD, {rewardId = rewardImg:getTag()})
                                    end)
                                    isAvailable = true
                                    break
                                end
                            end
                            -- 不可领取
                            if not isAvailable then
                                v.viewData.completeImages[k]:setVisible(false)
                                v.viewData.backLights[k]:setVisible(false)
                                v.viewData.clickLayers[k]:setTouchEnabled(true)
                                v.viewData.clickLayers[k]:setOnClickScriptHandler(function (sender)
                                    local groupRewards = CommonUtils.GetConfigAllMess('groupRewards','cardCollection')[tostring(v:getTag())][tostring(rewardImg:getTag())]
                                    local cpGroupReward = clone(groupRewards)
                                    cpGroupReward.starCount = available.starCount
                                    cpGroupReward.contractCount = available.contractLevelCount
                                    uiMgr:ShowRewardInformationTips({targetNode = sender, type = 11, bgSize = cc.size(320, 231), cpGroupReward = cpGroupReward})
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end

-- 计算小红点
function CardGatherRewardMediator:CalcRedPoint()
    for index, perAreaData in pairs(self.areaData) do
        self:setRedPointVisible(index, false)
        local areaId = perAreaData.areaId
        for _, v in pairs(self.areaAvailable[tostring(areaId)]) do
            if not v.received and v.available then
                self:setRedPointVisible(index, true)
                break
            end
        end
        for cpId, cpProgress in pairs(self.available[tostring(areaId)]) do
            if table.nums(cpProgress.received) < table.nums(cpProgress.available) then
                self:setRedPointVisible(index, true)
                break
            end
        end
    end
end

-- 设置小红点显示
function CardGatherRewardMediator:setRedPointVisible(index, isVisible)
	local viewComponent = self:GetViewComponent()
    local listView = viewComponent.viewData.areaTabsView
    local preCell = listView:getNodeAtIndex(index - 1)
    preCell.viewData.redPoint:setVisible(isVisible)
end

-- 计算当前的进度
function CardGatherRewardMediator:CalcProgress()
    -- 所有的地区
    local areaData = CommonUtils.GetConfigAllMess('area','cardCollection')
    for _, perArea in pairs(areaData) do
        table.insert(self.areaData, clone(perArea))
    end
    
    table.sort(self.areaData, function (a, b)
        return checkint(a.order) < checkint(b.order)
    end)

    local function pairsByKeys(t)      
        local a = {}      
        for n in pairs(t) do          
            a[#a+1] = n      
        end      
        table.sort(a)      
        local i = 0      
        return function()          
        i = i + 1          
        return a[i], t[a[i]]      
        end  
    end

    -- 不同地区的cp组合
    local areaAvailable = {}
    local groupMembers = CommonUtils.GetConfigAllMess('groupMembers','cardCollection')
    for _, perArea in pairs(self.areaData) do
        perArea.cpGroups = {}
        if groupMembers[tostring(perArea.areaId)] then
            for _, perCPGroup in pairs(groupMembers[tostring(perArea.areaId)]) do
                table.insert(perArea.cpGroups, clone(perCPGroup))
            end
            -- table.sort(perArea.cpGroups, function (a, b)
            --     return checkint(a.order) < checkint(b.order)
            -- end)
        end

        -- 地区收集进度
        local areaProgress = self:getAreaDetail(perArea.cpGroups)
        local areaReward = CommonUtils.GetConfigAllMess('areaRewards','cardCollection')[tostring(perArea.areaId)]
        local progress = {}
        local areaReceived = nil
        if self.rewardData and self.rewardData.areaProgress[tostring(perArea.areaId)] then
            areaReceived = string.split(self.rewardData.areaProgress[tostring(perArea.areaId)].areaReceived, ",")
        end
        for k, v in pairsByKeys(areaReward) do
            local perProgress = {rewardId = v.rewardId, available = false, received = false}
            if areaProgress.starCount >= tonumber(v.require.star) and areaProgress.contractCount >= tonumber(v.require.love) then
                perProgress.available = true
            end
            if areaReceived then
                for _, rewardId in pairs(areaReceived) do
                    if tostring(rewardId) == tostring(v.rewardId) then
                        perProgress.received = true
                        break
                    end
                end
            end
            table.insert(progress, perProgress)
        end
        areaAvailable[tostring(perArea.areaId)] = progress
    end
    self.areaAvailable = areaAvailable
    
    -- cp组合的进度
    local available = {}
    for _, perAreaData in pairs(self.areaData) do
        available[tostring(perAreaData.areaId)] = {}
        for _, perCPGroup in pairs(perAreaData.cpGroups) do
		    local starCount = 0
		    local contractLevelCount = 0
            for _, perCPMember in pairs(perCPGroup.cpMembers) do
                local isHave =  gameMgr:GetCardDataByCardId(tonumber(perCPMember))
                local cardHeadNode = nil
                if isHave then
                    starCount = starCount + isHave.breakLevel
                    contractLevelCount = contractLevelCount + isHave.favorabilityLevel
                end
            end

            local cpProgress = {starCount = starCount, contractLevelCount = contractLevelCount, received = {}, available = {}}
            local groupRewards = CommonUtils.GetConfigNoParser('cardCollection','groupRewards',tostring(perCPGroup.cpId))
            for _, value in pairs(groupRewards) do    
                if starCount >= tonumber(value.require.star) and contractLevelCount >= tonumber(value.require.love) then
                    table.insert(cpProgress.available, value.rewardId)
                end
            end
            if self.rewardData and self.rewardData.groupProgress[tostring(perCPGroup.cpId)] then
                cpProgress.received = string.split(self.rewardData.groupProgress[tostring(perCPGroup.cpId)].groupReceived, ",")
            end
            available[tostring(perAreaData.areaId)][tostring(perCPGroup.cpId)] = cpProgress
        end
    end

    for _, perArea in pairs(self.areaData) do
        table.sort(perArea.cpGroups, function (a, b)
            -- state 0:可领取 1:未达到 2:已领取
            local function getState(perCPReward)
                local cpAvailable = available[tostring(perArea.areaId)][tostring(perCPReward.cpId)]
                local cpRewards = CommonUtils.GetConfigNoParser('cardCollection','groupRewards',tostring(perCPReward.cpId))
                if 0 == table.nums(cpAvailable.available) then
                    return 1
                elseif table.nums(cpAvailable.received) == table.nums(cpRewards) then
                    return 2
                elseif table.nums(cpAvailable.received) < table.nums(cpAvailable.available) then
                    return 0
                else
                    return 1
                end
            end
            local aState = getState(a)
            local bState = getState(b)
            if aState < bState then
                return true
            elseif aState > bState then
                return false
            elseif checkint(a.order) < checkint(b.order) then
                return true
            end
            return false
        end)
    end

    self.available = available
end

-- 获取地区的飨灵总数 星级 契约数
function CardGatherRewardMediator:getAreaDetail(cpGroups)
    local areaProgress = {totalCards = 0, ownCards = 0, starCount = 0, contractCount = 0}
    local totalMembers = {}
    for _, v in pairs(cpGroups) do
        for _, cpId in pairs(v.cpMembers) do
            totalMembers[cpId] = true
        end
    end
    areaProgress.totalCards = table.nums(totalMembers)
    for id, _ in pairs(totalMembers) do
        local isHave =  gameMgr:GetCardDataByCardId(tonumber(id))
        if isHave then
            areaProgress.ownCards = areaProgress.ownCards + 1
            areaProgress.starCount = areaProgress.starCount + isHave.breakLevel 
            areaProgress.contractCount = areaProgress.contractCount + isHave.favorabilityLevel
        end
    end
    return areaProgress
end

function CardGatherRewardMediator:BackAction()
    display.removeUnusedSpriteFrames()
    if CommonUtils.ModulePanelIsOpen() then
        AppFacade.GetInstance():BackHomeMediator({showHandbook = true})
    else
        self:GetFacade():BackMediator()
    end
end

function CardGatherRewardMediator:OnRegist(  )
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    
	local CardGatherRewardCommand = require( 'Game.command.CardGatherRewardCommand' )
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_CARD_GATHER_AREA_REWARD, CardGatherRewardCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_CARD_GATHER_CP_REWARD, CardGatherRewardCommand)
end

function CardGatherRewardMediator:OnUnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_CARD_GATHER_AREA_REWARD)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_CARD_GATHER_CP_REWARD)
end

return CardGatherRewardMediator
