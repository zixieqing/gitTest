--[[
 * descpt : 夏活首页 中介者
]]
local NAME = 'ptDungeon.PTDungeonHomeMediator'
local PTDungeonHomeMediator = class(NAME, mvc.Mediator)

local uiMgr         = app.uiMgr
local gameMgr       = app.gameMgr
local ptDungeonMgr  = app.ptDungeonMgr


function PTDungeonHomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    self.activityId = checktable(self.ctorArgs_.requestData).activityId
    self.ptId = tostring(self.ctorArgs_.ptId) or '1'
end

-------------------------------------------------
-- inheritance method
function PTDungeonHomeMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    
    -- create view
    local viewComponent = require('Game.views.ptDungeon.PTDungeonHomeView').new()
	self:SetViewComponent(viewComponent)
    uiMgr:SwitchToScene(viewComponent)
    self:initOwnerScene_()
    self.viewData_      = viewComponent:getViewData()

    self:initData_()
    -- init view
    self:initView_()
    
end

function PTDungeonHomeMediator:initOwnerScene_()
    self.ownerScene_ = uiMgr:GetCurrentScene()
end

function PTDungeonHomeMediator:initData_()
    ptDungeonMgr:InitData(self.ctorArgs_, self.activityId)
    self.datas = ptDungeonMgr:GetHomeData()
end

function PTDungeonHomeMediator:initView_()
    local viewData = self:getViewData()

    if viewData.resetBtn then
        viewData.resetBtn:setOnClickScriptHandler(function (  )
            self.clearTodayCard = true
        end)
    end
    display.commonLabelParams(viewData.titleBtn, fontWithColor(1, {text = ptDungeonMgr:GetPTDungeonName(), ttf = true, font = TTF_GAME_FONT}))
    display.commonUIParams(viewData.backBtn, {cb = handler(self, self.onClickBackAction)})
    display.commonUIParams(viewData.titleBtn, {cb = handler(self, self.onClickTitleAction)})
    display.commonUIParams(viewData.fightBtn, {cb = handler(self, self.onClickFightAction)})
    display.commonUIParams(viewData.rankingBtn, {cb = handler(self, self.onClickRankingAction), animate = false})
    display.commonUIParams(viewData.cardTipImg, {cb = handler(self, self.onClickBossDesrAction)})
    viewData.backBtn:setVisible(false)

    viewData.tableView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSourceAdapter))

    self:GetViewComponent():refreshUI(self.datas, self.datas.questId)
    self:GetViewComponent():updateTimeTip(self:getViewData(), app.gameMgr:GetUserInfo().PTDungeonTimerActivityTime)
end

function PTDungeonHomeMediator:cleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        viewComponent:stopAllActions()
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function PTDungeonHomeMediator:OnRegist()
    regPost(POST.PT_DRAW_SECTION, true)
    regPost(POST.PT_RANK, true)
    regPost(POST.PT_BUY_LIVE, true)

    -- self:enterLayer()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
end
function PTDungeonHomeMediator:OnUnRegist()
    unregPost(POST.PT_DRAW_SECTION)
    unregPost(POST.PT_RANK)
    unregPost(POST.PT_BUY_LIVE)
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
    app.activityHpMgr:StopHPCountDown(ptDungeonMgr:GetHPGoodsId())
end


function PTDungeonHomeMediator:InterestSignals()
    return {
        SGL.CACHE_MONEY_UPDATE_UI,
        POST.PT_DRAW_SECTION.sglName,
        COUNT_DOWN_ACTION,
    }
end

function PTDungeonHomeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    if name == SGL.CACHE_MONEY_UPDATE_UI then
        self:GetViewComponent():updateMoneyBarGoodNum()
    elseif name == POST.PT_DRAW_SECTION.sglName then
        local rewards = body.rewards or {}
        if next(rewards) ~= nil then
            uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
        end

        local requestData = body.requestData
        local index = requestData.index

        self.datas.section[index].hasDrawn = 1

        local viewData = self:getViewData()
        local tableView = self:getViewData().tableView
        local cell = tableView:cellAtIndex(index - 1)
        self:GetViewComponent():updateCell(cell.viewData, self.datas.section[index], checknumber(self.datas.point))

    elseif name == COUNT_DOWN_ACTION then
        local timerName = body.timerName
        if timerName == 'PTDungeon' then
            self:GetViewComponent():updateTimeTip(self:getViewData(), body.countdown)
        end
    end
end

-------------------------------------------------
-- get / set

function PTDungeonHomeMediator:getViewData()
    return self.viewData_
end

function PTDungeonHomeMediator:getOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function PTDungeonHomeMediator:enterLayer()
    self:SendSignal(POST.PT_HOME.cmdName, {activityId = self.activityId})
end

-------------------------------------------------
-- private method
function PTDungeonHomeMediator:onDataSourceAdapter(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1

    local viewComponent = self:GetViewComponent()
	if pCell == nil then
		local tableView = self:getViewData().tableView
        pCell = viewComponent:CreateCell(tableView:getSizeOfCell())
        
        display.commonUIParams(pCell.viewData.storyTouchView, {cb = handler(self, self.onClickStoryAction)})
        display.commonUIParams(pCell.viewData.drawBtn, {cb = handler(self, self.onClickDrawBtnAction)})
    end
    
    local viewData = pCell.viewData
    viewData.drawBtn:setTag(index)
    viewData.storyTouchView:setTag(index)
    local section = self.datas.section or {}
    viewComponent:updateCell(viewData, section[index], checknumber(self.datas.point))

	return pCell
end

--==============================--
--desc: 显示战斗预览界面
--@params questId 关卡id
--@return
--==============================--
function PTDungeonHomeMediator:showBattleReady(questId)
	local PTQuest = CommonUtils.GetQuestConf(questId)
    local activityId = self.activityId
    if not activityId then
        uiMgr:ShowInformationTips('没有activityId')
    end
    -- 显示编队界面
    local battleReadyData = BattleReadyConstructorStruct.New(
            2,
            app.gameMgr:GetUserInfo().localCurrentBattleTeamId,
            nil,
            questId,
            CommonUtils.GetQuestBattleByQuestId(questId),
            nil,
            POST.PT_QUEST_AT.cmdName,
            { questId = questId, activityId = activityId },
            POST.PT_QUEST_AT.sglName,
            POST.PT_QUEST_GRADE.cmdName,
            { questId = questId, activityId = activityId },
            POST.PT_QUEST_GRADE.sglName,
            NAME,
            NAME
	)
    --------------- 初始化战斗传参 ---------------
    local layer = require('Game.views.ptDungeon.PTDungeonBattleReadyView').new(battleReadyData)
    layer:setPosition(cc.p(display.cx,display.cy))
	app.uiMgr:GetCurrentScene():AddDialog(layer)
	
	layer:AddTopCurrency({ self.datas.hpGoodsId, DIAMOND_ID }, {consumeGoods = self.datas.hpGoodsId})
    layer:RefreshRecommendCards(self.clearTodayCard and {} or CommonUtils.GetConfigAllMess('cardAddition', 'pt')[self.ptId])
    
end

-------------------------------------------------
-- check

-------------------------------------------------
-- handler

function PTDungeonHomeMediator:onClickTitleAction()
    uiMgr:ShowIntroPopup({moduleId = '-21'})
end

function PTDungeonHomeMediator:onClickFightAction(sender)
    self:showBattleReady(self.datas.questId)
end 

function PTDungeonHomeMediator:onClickRankingAction(sender)
    local mediator = require( 'Game.mediator.ptDungeon.PTDungeonRewardPreviewMediator').new(self.ctorArgs_)
    app:RegistMediator(mediator)
end

function PTDungeonHomeMediator:onClickBossDesrAction(sender)
    uiMgr:ShowIntroPopup({moduleId = '-22'})
end

function PTDungeonHomeMediator:onClickDrawBtnAction(sender)
    local index = sender:getTag()
    local section  = self.datas.section or {}
    local curPoint = checknumber(self.datas.point)
    
    local data = section[index] or {}
    local targetNum  = checknumber(data.targetNum)
    local hasDrawn   = checkint(data.hasDrawn) > 0
    if hasDrawn then
        uiMgr:ShowInformationTips(__('已领取'))
    else
        if curPoint >= targetNum then
            self:SendSignal(POST.PT_DRAW_SECTION.cmdName, {activityId = self.activityId, sectionId = data.sectionId, index = index})
        else
            uiMgr:ShowInformationTips(__('pt不足'))
        end
    end
end

function PTDungeonHomeMediator:onClickStoryAction(sender)
    local index = sender:getTag()
    local section  = self.datas.section or {}
    local data = section[index] or {}
    local plot = data.plot
    if plot == nil then
        return
    end

    if checknumber(self.datas.point) < checkint(data.targetNum) then
        uiMgr:ShowInformationTips(__('剧情未解锁'))
        return
    end
    ptDungeonMgr:ShowOperaStage(plot)
end

function PTDungeonHomeMediator:onClickBackAction(sender)
    app:UnRegsitMediator(NAME)
end

return PTDungeonHomeMediator

