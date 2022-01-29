--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）棋盘Mediator
]]
local MurderChessboardMediator = class('MurderChessboardMediator', mvc.Mediator)

function MurderChessboardMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'MurderChessboardMediator', viewComponent)
    self.moneyNodes = {}
end
-------------------------------------------------
-- inheritance method

function MurderChessboardMediator:Initial(key)
    self.super.Initial(self, key)
	local viewComponent = require('Game.views.activity.murder.MurderChessboardView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = app.uiMgr:GetCurrentScene()
    scene:AddDialog(viewComponent)
    local viewData = viewComponent:GetViewData()
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TabTipsButtonCallback))
    viewComponent:RefreshChessboard(app.murderMgr:GetClockLevel(), handler(self, self.ChessButtonCallback))
    local moneyIdMap = {}
    local goodsId = app.murderMgr:GetMurderHpId()
    moneyIdMap[tostring(goodsId)] = goodsId
    viewComponent:ReloadMoneyBar(moneyIdMap, false)
    self:ShowFirstEnterStory()
    
end

function MurderChessboardMediator:InterestSignals()
    local signals = {
        MURDER_SWEEP_POPUP_SHOWUP_EVENT,
        'QUEST_SWEEP_OVER',
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
	}
	return signals
end
function MurderChessboardMediator:ProcessSignal(signal)
    local name = signal:GetName()

    local body = signal:GetBody()
    if name == MURDER_SWEEP_POPUP_SHOWUP_EVENT then
        local stageId = body.stageId
        local tag     = 4001
        local layer   = require('Game.views.SweepPopup').new({
            tag                 = tag,
            stageId             = stageId,
            canSweepCB          = handler(self, self.CanSweepCallback),
            sweepRequestCommand = POST.MURDER_SWEEP.cmdName,
            sweepResponseSignal = POST.MURDER_SWEEP.sglName
        })
        display.commonUIParams(layer, { ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5) })
        layer:setTag(tag)
        layer:setName('SweepPopup')
        app.uiMgr:GetCurrentScene():AddDialog(layer)
    elseif name == 'QUEST_SWEEP_OVER' then -- 扫荡完成
        local data = body.responseData
        local stageId      = checkint(data.requestData.questId)
        local consumeHp    = tonumber(CommonUtils.GetQuestConf(checkint(stageId)).consumeHpNum)
        app.activityHpMgr:UpdateHp(app.murderMgr:GetMurderHpId(), -consumeHp * data.requestData.times)
        app.murderMgr:UpdateHomeData()
        self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
    elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
        if not tolua.isnull(self.moneyNodes[tostring(DIAMOND_ID)]) then
            self.moneyNodes[tostring(DIAMOND_ID)]:updataUi(DIAMOND_ID)
        end
        if not tolua.isnull(self.moneyNodes[tostring(app.murderMgr:GetMurderHpId())]) then
            self.moneyNodes[tostring(app.murderMgr:GetMurderHpId())]:updataUi(app.murderMgr:GetMurderHpId())
        end
        self:GetViewComponent():UpdateMoneyBar()
    end
end

function MurderChessboardMediator:OnRegist()
    regPost(POST.MURDER_SWEEP)
end
function MurderChessboardMediator:OnUnRegist()
    unregPost(POST.MURDER_SWEEP)
    -- 移除界面
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end
-------------------------------------------------
-- handler method
--[[
返回按钮回调
--]]
function MurderChessboardMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator("MurderChessboardMediator")
end
--[[
提示按钮点击回调
--]]
function MurderChessboardMediator:TabTipsButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = '-35'})
end
--[[
棋盘点击回调
--]]
function MurderChessboardMediator:ChessButtonCallback( sender )
    local questId = sender:getTag()
    local battleReadyData = BattleReadyConstructorStruct.New(
        4,
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
        'activity.murder.MurderHomeMediator', --self.args.isFrom or
        'activity.murder.MurderHomeMediator'--self.args.isFrom or
    )
    local layer           = require('Game.views.activity.murder.MurderBattleReadyView').new(battleReadyData)
    layer:setPosition(cc.p(display.cx, display.cy))
    app.uiMgr:GetCurrentScene():AddDialog(layer)

    self.moneyNodes = layer:AddTopCurrency({ app.murderMgr:GetMurderHpId(), DIAMOND_ID }, app.murderMgr:GetHomeData())
end
-------------------------------------------------
-- get /set

-------------------------------------------------
-- private method
--[[
判断是否可以扫荡
--]]
function MurderChessboardMediator:CanSweepCallback( stageId, times )
    local consumeHp = checkint(CommonUtils.GetQuestConf(checkint(stageId)).consumeGoodsLoseNum)
    if app.murderMgr:IsMaterialQuestCanSkip(stageId) then
        if app.activityHpMgr:GetHpAmountByHpGoodsId(app.murderMgr:GetMurderHpId()) >= consumeHp * times then
            return true
        else
            app.uiMgr:ShowInformationTips(app.murderMgr:GetPoText(__("道具不足")))
        end
    else
        app.uiMgr:ShowInformationTips(app.murderMgr:GetPoText(__("通关关卡才可开启扫荡功能")))
    end
end
--[[
显示首次进入剧情
--]]
function MurderChessboardMediator:ShowFirstEnterStory()
    local config = CommonUtils.GetConfig('newSummerActivity', 'param', 1)
    app.murderMgr:ShowActivityStory(
        {
            storyId = checkint(config.story2),
        }
    )
end
-------------------------------------------------
-- public method


return MurderChessboardMediator
