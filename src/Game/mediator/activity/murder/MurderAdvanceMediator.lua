--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）推进(修理)Mediator
]]
local MurderAdvanceMediator = class('MurderAdvanceMediator', mvc.Mediator)

function MurderAdvanceMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'MurderAdvanceMediator', viewComponent)
end
-------------------------------------------------
-- inheritance method

function MurderAdvanceMediator:Initial(key)
    self.super.Initial(self, key)
	local viewComponent = require('Game.views.activity.murder.MurderAdvanceView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = app.uiMgr:GetCurrentScene()
    scene:AddDialog(viewComponent)
    local viewData = viewComponent:GetViewData()
    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.putBtn:setOnClickScriptHandler(handler(self, self.PutButtonCallback))
    self:InitView()
end

function MurderAdvanceMediator:InterestSignals()
    local signals = {
        POST.MURDER_UPGRADE.sglName,
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
	}
	return signals
end
function MurderAdvanceMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.MURDER_UPGRADE.sglName then
        -- 扣除道具
        local config = CommonUtils.GetConfig('newSummerActivity', 'building', body.newClockLevel)
        local consume = clone(config.consume)
        for i, v in ipairs(consume) do
            v.num = -v.num
        end
        CommonUtils.DrawRewards(consume)
        app.murderMgr:SetClockLevel(checkint(body.newClockLevel))
        app:DispatchObservers(MURDER_UPGRADE_EVENT, {newClockLevel = body.newClockLevel})
        app:UnRegsitMediator("MurderAdvanceMediator")
    elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
        self:InitView()
    end
end

function MurderAdvanceMediator:OnRegist()
    regPost(POST.MURDER_UPGRADE)
end
function MurderAdvanceMediator:OnUnRegist()
    -- 移除界面
	local scene = app.uiMgr:GetCurrentScene()
    scene:RemoveDialog(self:GetViewComponent())
    unregPost(POST.MURDER_UPGRADE)
end
-------------------------------------------------
-- handler method
--[[
返回按钮回调
--]]
function MurderAdvanceMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator("MurderAdvanceMediator")
end
--[[
放入按钮点击回调  
--]]
function MurderAdvanceMediator:PutButtonCallback( sender)
    PlayAudioByClickNormal()
    local nextClockLevel = app.murderMgr:GetClockLevel() + 1
    local config = CommonUtils.GetConfig('newSummerActivity', 'building', nextClockLevel)
    for i, v in ipairs(config.consume) do
        if app.gameMgr:GetAmountByIdForce(v.goodsId) < checkint(v.num) then
            app.uiMgr:ShowInformationTips(app.murderMgr:GetPoText(__('道具不足')))
            return
        end
    end
    self:SendSignal(POST.MURDER_UPGRADE.cmdName)
end
-------------------------------------------------
-- get /set

-------------------------------------------------
-- private method
--[[
初始化页面
--]]
function MurderAdvanceMediator:InitView()
    local nextClockLevel = app.murderMgr:GetClockLevel() + 1
    local viewComponent = self:GetViewComponent()
    -- 刷新解锁列表
    viewComponent:RefreshUnlockListView(nextClockLevel)
    -- 刷新需求列表
    viewComponent:RefreshRequirementList(nextClockLevel)
end
-------------------------------------------------
-- public method


return MurderAdvanceMediator
