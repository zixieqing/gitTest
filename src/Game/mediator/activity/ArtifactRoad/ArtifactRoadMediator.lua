--[[
    神器之路Mediator
--]]
local Mediator = mvc.Mediator
---@class ArtifactRoadMediator:Mediator
local ArtifactRoadMediator = class("ArtifactRoadMediator", Mediator)

local NAME = "activity.ArtifactRoad.ArtifactRoadMediator"

local shareFacade = AppFacade.GetInstance()
local uiMgr = app.uiMgr
local gameMgr = app.gameMgr
local artifactMgr =  app.artifactMgr

local RES_DICT          = {
    CORE_ROAD_BG_MAP                = _res('ui/home/activity/ArtifactRoad/core_road_bg_map.png'),
}

function ArtifactRoadMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.datas = checktable(params) or {}
    self.activityId = params.requestData.activityId
end

function ArtifactRoadMediator:InterestSignals()
	local signals = {
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
        EVENT_PAY_MONEY_SUCCESS_UI,
        ARTIFACT_ROAD_MAP_STAGE_CLICK_EVENT,
		POST.ACTIVITY_ARTIFACT_ROAD_SWEEP.sglName ,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
	}

	return signals
end

function ArtifactRoadMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	-- dump(body, name)
    if name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
        local viewData = self:GetViewComponent().viewData
        for k, v in pairs(viewData.moneyNodes) do
            v:updataUi(tonumber(k))
        end
        if self.moneyNodes and shareFacade:RetrieveMediator('EnterBattleMediator') then
            for k, v in pairs(self.moneyNodes) do
                v:updataUi(tonumber(k))
            end
        end
    elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
        local viewData = self:GetViewComponent().viewData
        viewData.moneyNodes[tostring(DIAMOND_ID)]:updataUi(DIAMOND_ID)
        if self.moneyNodes and shareFacade:RetrieveMediator('EnterBattleMediator') then
            self.moneyNodes[tostring(DIAMOND_ID)]:updataUi(DIAMOND_ID)
        end
    elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        local viewData = self:GetViewComponent().viewData
        for k, v in pairs(viewData.moneyNodes) do
            v:updataUi(tonumber(k))
        end
        if self.moneyNodes and shareFacade:RetrieveMediator('EnterBattleMediator') then
            for k, v in pairs(self.moneyNodes) do
                v:updataUi(tonumber(k))
            end
        end
    elseif name == ARTIFACT_ROAD_MAP_STAGE_CLICK_EVENT then
        local questId         = checkint(body.questId)
        if 0 == self.datas.quests[tostring(questId)].isPassed then
            uiMgr:ShowInformationTips(__('前置关卡未达到三星'))
            return
        end
        AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "1006-01"})
        AppFacade.GetInstance():DispatchObservers("DOT_SET_LOG_EVENT" , {eventId = "1006-02"})
        -- 显示编队界面
        local battleReadyData = BattleReadyConstructorStruct.New(
                2,
                gameMgr:GetUserInfo().localCurrentBattleTeamId,
                nil,
                questId,
                CommonUtils.GetQuestBattleByQuestId(questId),
                body.star,
                POST.ACTIVITY_ARTIFACT_ROAD_QUEST_AT.cmdName,
                { questId = questId, activityId = self.activityId },
                POST.ACTIVITY_ARTIFACT_ROAD_QUEST_AT.sglName,
                POST.ACTIVITY_ARTIFACT_ROAD_QUEST_GRADE.cmdName,
                { questId = questId, activityId = self.activityId },
                POST.ACTIVITY_ARTIFACT_ROAD_QUEST_GRADE.sglName,
                NAME,
                NAME
        )
        --------------- 初始化战斗传参 ---------------
        local layer = require('Game.views.activity.ArtifactRoad.ArtifactRoadBattleReadyView').new(battleReadyData)
        layer:setPosition(cc.p(display.cx,display.cy))
        uiMgr:GetCurrentScene():AddDialog(layer)

        local artifactQuest = CommonUtils.GetConfigAllMess('artifactQuest', 'activity')[tostring(questId)]
        self.moneyNodes = layer:AddTopCurrency({ artifactQuest.consumeGoodsId, HP_ID, DIAMOND_ID }, self.datas)
    elseif name == POST.ACTIVITY_ARTIFACT_ROAD_SWEEP.sglName then
        local requestData = body.requestData
        local consumeType = requestData.consumeType
        local questId = requestData.questId
        local delayList = {}
        local data = {}
        if body.sweep then
            for k,v in pairs(body.sweep) do
                for ii, vv  in pairs(v.rewards) do
                    data[#data+1] = vv
                end
            end
        end
        local isHave = false
        if checkint(body.totalMainExp) > 0  then
            isHave = true
            data[#data+1] = {goodsId = EXP_ID, num = (checkint(body.totalMainExp) - gameMgr:GetUserInfo().mainExp)}
        end
        delayList = CommonUtils.DrawRewards(data, true)
        local tag = 2005
        if checkint(requestData.times ) == 1 then
            uiMgr:AddDialog('common.RewardPopup', {rewards = body.sweep['1'].rewards,mainExp = body.sweep['1'].mainExp ,addBackpack = false,delayFuncList_ = delayList})
        else
            local layer = require('Game.views.SweepRewardPopup').new({tag = tag, rewardsData = body , executeAction = true , delayFuncList_ = delayList})
            display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
            uiMgr:GetCurrentScene():AddDialog(layer)
            layer:setTag(tag)
        end

        local stageConf = CommonUtils.GetQuestConf(requestData.questId)
        if 1 == checkint(consumeType) then
            CommonUtils.DrawRewards({ { goodsId = HP_ID, num = -1 * checkint(stageConf.consumeHp) * requestData.times } })
        else
            CommonUtils.DrawRewards({ { goodsId = stageConf.consumeGoodsId, num = -1 * checkint(stageConf.consumeGoodsNum) * requestData.times } })
        end
        local viewData = self:GetViewComponent().viewData
        for k, v in pairs(viewData.moneyNodes) do
            v:updataUi(tonumber(k))
        end
        if self.moneyNodes then
            for k, v in pairs(self.moneyNodes) do
                v:updataUi(tonumber(k))
            end
        end
    end
end

function ArtifactRoadMediator:Initial( key )
	self.super.Initial(self, key)

	local GroupId = self.datas.groupId
	local artifactGroup = CommonUtils.GetConfigAllMess('artifactGroup','activity')[tostring(GroupId)]
	local CardId = artifactGroup.roleId
	local cardData = gameMgr:GetCardDataByCardId(CardId)
    local viewComponent = require('Game.views.activity.ArtifactRoad.ArtifactRoadView').new({CardId = CardId})
	self:SetViewComponent(viewComponent)
    uiMgr:SwitchToScene(viewComponent)
	local viewData = viewComponent.viewData

    if cardData then
        if checkint(cardData.breakLevel) >= 2 and checkint(cardData.isArtifactUnlock) == 1 then
            viewData.UnlockLabel:setString(__('前 往'))
        else
            viewData.UnlockLabel:setString(__('去解锁'))
        end
    end
    viewData.DesrLabel:setString(artifactGroup.descr)

	viewData.ArtifactBtn:setOnClickScriptHandler(function()
        if not cardData then
            uiMgr:ShowInformationTips(__('还未拥有该飨灵'))
        elseif checkint(cardData.breakLevel) < 2 then
			uiMgr:ShowInformationTips(__('飨灵突破等级未达到两星'))
		elseif checkint(cardData.isArtifactUnlock) == 1 then
			artifactMgr:SetCardsList({gameMgr:GetCardDataByCardId(CardId)})
			shareFacade:RetrieveMediator("Router"):Dispatch({name = NAME, params = {activityId = self.activityId}} , { name ="artifact.ArtifactTalentMediator" , params = {playerCardId = CardId} }, {isBack = true})
		else
			artifactMgr:SetCardsList({gameMgr:GetCardDataByCardId(CardId)})
			shareFacade:RetrieveMediator("Router"):Dispatch({name = NAME, params = {activityId = self.activityId}} , { name ="artifact.ArtifactLockMediator" , params = {playerCardId = CardId } }, {isBack = true})
		end
	end)

    local RightPadding = 120
    local artifactQuest = CommonUtils.GetConfigAllMess('artifactQuest', 'activity')
    local MaxWidth = 0
    for i, v in ipairs(artifactGroup.quests) do
        local x = tonumber(artifactQuest[tostring(v)].location.x)
        if x > MaxWidth then
            MaxWidth = x
        end
    end

    local descrScrollView = viewData.descrScrollView
    local ScrollViewContainer = descrScrollView:getContainer()
    --local ScrollViewContainer = display.newLayer(0, 0, {size = cc.size(100, 100), ap = display.LEFT_BOTTOM})
    local BG = display.newImageView(RES_DICT.CORE_ROAD_BG_MAP, 0, 0,
            {
                ap = display.LEFT_BOTTOM,
            })
    local size = BG:getContentSize()

    local BGCount = math.ceil((MaxWidth + RightPadding) / size.width)
    BG:setPositionY((display.height - size.height) / 2)
    ScrollViewContainer:addChild(BG)
    for i = 2, BGCount do
        local BG = display.newImageView(RES_DICT.CORE_ROAD_BG_MAP, (i-1)*size.width, (display.height - size.height) / 2,
        {
            ap = display.LEFT_BOTTOM,
        })
        ScrollViewContainer:addChild(BG)
    end
    --ScrollViewContainer:setPositionY((display.height - size.height) / 2)
    descrScrollView:setContainerSize(cc.size(MaxWidth + RightPadding, size.height))
    --descrScrollView:setContentOffsetToLeft()

    for i, v in ipairs(artifactGroup.quests) do
        if 0 == self.datas.quests[tostring(v)].isPassed then
            local last = artifactGroup.quests[i-1]
            if not last then
                self.datas.quests[tostring(v)].isPassed = 1
            else
                local IsCurrent = self.datas.quests[tostring(last)].isPassed and 3 == self.datas.quests[tostring(last)].grade
                self.datas.quests[tostring(v)].isPassed = IsCurrent and 1 or 0
            end
            break
        end
    end
    local CurrentStage
    for i = table.nums(artifactGroup.quests), 1, -1 do
        if 1 == self.datas.quests[tostring(artifactGroup.quests[i])].isPassed then
            CurrentStage = i
            break
        end
    end
    descrScrollView:setContentOffset(cc.p(artifactQuest[tostring(artifactGroup.quests[CurrentStage])].location.x * -1 + artifactQuest[tostring(artifactGroup.quests[1])].location.x, 0))

    for i, v in ipairs(artifactGroup.quests) do
        local stageNode = require('Game.views.activity.ArtifactRoad.ArtifactRoadMapNode').new({
            questId = v,
            lock = 0 == self.datas.quests[tostring(v)].isPassed,
            isCurrentStage = CurrentStage == i,
            star = tonumber(self.datas.quests[tostring(v)].grade)
        })
        local pos = artifactQuest[tostring(v)].location
        stageNode:setPosition(pos.x, size.height + (display.height - size.height) / 2 - pos.y)
        ScrollViewContainer:addChild(stageNode)
    end
end

function ArtifactRoadMediator:OnRegist(  )
    regPost(POST.ACTIVITY_ARTIFACT_ROAD_SWEEP)
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
end

function ArtifactRoadMediator:OnUnRegist(  )
    unregPost(POST.ACTIVITY_ARTIFACT_ROAD_SWEEP)
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
end

return ArtifactRoadMediator