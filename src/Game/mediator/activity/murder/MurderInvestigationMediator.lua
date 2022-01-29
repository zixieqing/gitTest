--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）调查Mediator
]]
local MurderInvestigationMediator = class('MurderInvestigationMediator', mvc.Mediator)

function MurderInvestigationMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'MurderInvestigationMediator', viewComponent)
    self.selectedQuest = app.murderMgr:GetBossDifficulty() -- 选中的关卡
    self.moneyNodes = {}
end
-------------------------------------------------
-- inheritance method

function MurderInvestigationMediator:Initial(key)
    self.super.Initial(self, key)
    local viewComponent = app.uiMgr:SwitchToTargetScene('Game.views.activity.murder.MurderInvestigationView')
	self:SetViewComponent(viewComponent)
    viewComponent:GetViewData().investigationBtn:setOnClickScriptHandler(handler(self, self.InvestigationButtonCallback))
    viewComponent:GetViewData().giftBtn:setOnClickScriptHandler(handler(self, self.GiftButtonCallback))
    viewComponent:GetViewData().backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    -- debug
    if viewComponent:GetViewData().debugBtn then
        viewComponent:GetViewData().debugBtn:setOnClickScriptHandler(handler(self, self.DebugButtonCallback))
    end
    for i, v in ipairs(viewComponent:GetViewData().btnList) do
        v.button:setOnClickScriptHandler(handler(self, self.SelectedButtonCallback))
    end 
    -- 刷新界面
    self:InitView()
end

function MurderInvestigationMediator:InterestSignals()
    local signals = {
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT
	}
	return signals
end
function MurderInvestigationMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI
    or name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then -- 刷新顶部状态栏
        if not tolua.isnull(self.moneyNodes[tostring(DIAMOND_ID)]) then
            self.moneyNodes[tostring(DIAMOND_ID)]:updataUi(DIAMOND_ID)
        end
        if not tolua.isnull(self.moneyNodes[tostring(app.murderMgr:GetMurderGoodsIdByKey("murder_ticket_id"))]) then
            self.moneyNodes[tostring(app.murderMgr:GetMurderGoodsIdByKey("murder_ticket_id"))]:updataUi(app.murderMgr:GetMurderGoodsIdByKey("murder_ticket_id"))
        end
        self:GetViewComponent():UpdateMoneyBar()
    end
end

function MurderInvestigationMediator:OnRegist()
    PlayBGMusic(app.murderMgr:GetBgMusic(AUDIOS.GHOST.Food_ghost_dancing.id))
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
end
function MurderInvestigationMediator:OnUnRegist()
end
-------------------------------------------------
-- handler method
--[[
返回按钮回调
--]]
function MurderInvestigationMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator("MurderInvestigationMediator")
end
--[[
调查按钮点击回调
--]]
function MurderInvestigationMediator:InvestigationButtonCallback( sender )
    PlayAudioByClickNormal()
    local bossId = app.murderMgr:GetUnlockBossId()
    local bossConfig = CommonUtils.GetConfig('newSummerActivity', 'bossSchedule', bossId)
    local str = string.format('pointId%d', self.selectedQuest)
    local questId = checkint(bossConfig[str])
    local battleReadyData = BattleReadyConstructorStruct.New(
        5,
        app.gameMgr:GetUserInfo().localCurrentBattleTeamId,
        app.gameMgr:GetUserInfo().localCurrentEquipedMagicFoodId,
        questId,
        CommonUtils.GetQuestBattleByQuestId(questId),
        nil,
        POST.MURDER_QUEST_AT.cmdName,
        { questId = questId },
        POST.MURDER_QUEST_AT.sglName,
        POST.MURDER_QUEST_GRADE.cmdName,
        { questId = questId },
        POST.MURDER_QUEST_GRADE.sglName,
        'activity.murder.MurderInvestigationMediator', --self.args.isFrom or
        'activity.murder.MurderInvestigationMediator'--self.args.isFrom or
    )
    local layer           = require('Game.views.activity.murder.MurderBattleReadyView').new(battleReadyData)
    layer:setPosition(cc.p(display.cx, display.cy))
    app.uiMgr:GetCurrentScene():AddDialog(layer)

    self.moneyNodes = layer:AddTopCurrency({ app.murderMgr:GetMurderGoodsIdByKey("murder_ticket_id"), DIAMOND_ID }, app.murderMgr:GetHomeData())
end
--[[
奖励预览按钮点击回调
--]]
function MurderInvestigationMediator:GiftButtonCallback( sender )
    PlayAudioByClickNormal()
    local bossId = app.murderMgr:GetUnlockBossId()
    local config = CommonUtils.GetConfig('newSummerActivity', 'bossSchedule', bossId)

    app.uiMgr:ShowInformationTipsBoard({
        showAmount = true,
        iconIds = config.rewards,
        targetNode = sender, type = 4	
    })
end
--[[
选择按钮点击回调
--]]
function MurderInvestigationMediator:SelectedButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    self.selectedQuest = tag
    app.murderMgr:SetBossDifficulty(tag)
    self:RefreshSelectedQuest()
end
--[[
debug按钮点击回调
秋秋用debug按钮，开启后去掉飨灵伤害加成
--]]
function MurderInvestigationMediator:DebugButtonCallback( sender )
    PlayAudioByClickNormal()
    local debugMode = app.murderMgr:GetDebugMode()
    if debugMode then 
        app.uiMgr:ShowInformationTips('开启伤害加成')
        app.murderMgr:CloseDebugMode()
    else
        app.uiMgr:ShowInformationTips('关闭伤害加成')
        app.murderMgr:OpenDebugMode()
    end

end
-------------------------------------------------
-- get /set

-------------------------------------------------
-- private method
--[[
初始化页面
--]]
function MurderInvestigationMediator:InitView()
    local view = self:GetViewComponent()
    local moneyIdMap = {}
    local goodsId = app.murderMgr:GetMurderGoodsIdByKey("murder_ticket_id")
    moneyIdMap[tostring(goodsId)] = goodsId
    view:ReloadMoneyBar(moneyIdMap, false)
    -- 刷新
    self:RefreshDropAddition()
    self:RefreshRole()
    self:RefreshPoint()
    self:RefreshQuestButton()
    self:RefreshSelectedQuest()
end
--[[
刷新掉落加成
--]]
function MurderInvestigationMediator:RefreshDropAddition()
    local viewData = self:GetViewComponent():GetViewData()
    local clockLevel = app.murderMgr:GetClockLevel()
    local buildingConfig = CommonUtils.GetConfig('newSummerActivity', 'building', clockLevel)
    local moduleConfig = app.murderMgr:GetUnlockModuleByType(MURDER_MOUDLE_TYPE.BUFF)
    viewData.buffIcon:setTexture(app.murderMgr:GetResPath(string.format('ui/home/activity/murder/buffIcon/murder_main_clock_ico_buff_%d.png', checkint(moduleConfig.icon))))
    display.reloadRichLabel(viewData.buffNumLabel, {c = {
        {text = app.murderMgr:GetPoText(__('掉落数量')), fontSize = 20, color = '#ffffff'},
        {text = (tonumber(buildingConfig.addition[tostring(app.murderMgr:GetMurderGoodsIdByKey("murder_book_id"))]) + 1) * 100 .. '%', fontSize = 20, color = '#ffc74e'}
    }})
end
--[[
刷新角色
--]]
function MurderInvestigationMediator:RefreshRole()
    local viewData = self:GetViewComponent():GetViewData()
    local bossId = app.murderMgr:GetUnlockBossId()
    local bossConfig = CommonUtils.GetConfig('newSummerActivity', 'bossSchedule', bossId)
    viewData.cardDraw:RefreshAvatar({cardId = checkint(bossConfig.icon)})
    viewData.dialogTextLabel:setString(bossConfig.dialogue)
    viewData.cardDialog:setScale(0.5)
    viewData.cardDialog:runAction(
        cc.Sequence:create(
            cc.EaseBackOut:create(cc.ScaleTo:create(0.5, 1)),
            cc.DelayTime:create(6),
            cc.EaseBackIn:create(cc.ScaleTo:create(0.5, 0.5)),
            cc.RemoveSelf:create()
        )
    )
end
--[[
刷新点数
--]]
function MurderInvestigationMediator:RefreshPoint()
    local viewData = self:GetViewComponent():GetViewData()
    local fullServerPoint = app.murderMgr:GetFullServerPoint()
    local targetPoint = app.murderMgr:GetTargetFullServerPoint()
    viewData.progressBar:setMaxValue(targetPoint)
    viewData.progressBar:setValue(fullServerPoint)
    viewData.progressBarLabel:setString(string.format('%d/%d', math.min(fullServerPoint, targetPoint), targetPoint))
    viewData.rewardDescr:setString(string.fmt(app.murderMgr:GetPoText(__('调查结束时，全服累计取得调查点数达到_num_可获得奖励')), {['_num_'] = targetPoint}))
end
--[[
刷新关卡按钮
--]]
function MurderInvestigationMediator:RefreshQuestButton()
    local viewData = self:GetViewComponent():GetViewData()
    local bossId = app.murderMgr:GetUnlockBossId()
    local bossConfig = CommonUtils.GetConfig('newSummerActivity', 'bossSchedule', bossId)
    for i, v in ipairs(viewData.btnList) do
        local str = string.format('pointId%d', i)
        local questId = bossConfig[str]
        local questConfig = CommonUtils.GetQuestConf(checkint(questId))
        v.costNum:setString(questConfig.consumeNum)
        v.descrLabel:setString(string.fmt(app.murderMgr:GetPoText(__('目标：获得调查点数_num_')), {['_num_'] = checkint(bossConfig.targetPoint[i])}))
    end
end
--[[
刷新选中关卡
--]]
function MurderInvestigationMediator:RefreshSelectedQuest()
    local viewData = self:GetViewComponent():GetViewData()
    for i, v in ipairs(viewData.btnList) do
        self:GetViewComponent():SetCheckBoxSelected(i, self.selectedQuest == i)
    end
end

-------------------------------------------------
-- public method


return MurderInvestigationMediator
