--[[
铸池抽卡领奖mediator    
--]]
local Mediator = mvc.Mediator
local CapsuleRandomPoolDrawMediator = class("CapsuleRandomPoolDrawMediator", Mediator)
local NAME = "CapsuleRandomPoolDrawMediator"
local NewPlayerRewardCell     = require("Game.views.drawCards.NewPlayerRewardCell")
local PoolPreviewView         = require('Game.views.drawCards.CapsulePoolPreviewView')
function CapsuleRandomPoolDrawMediator:ctor( params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    self.rewardsData = checktable(params)
end

function CapsuleRandomPoolDrawMediator:InterestSignals()
	local signals = {
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
	}
	return signals
end

function CapsuleRandomPoolDrawMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    print(name)
    if name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then -- 刷新顶部状态栏
        self:GetViewComponent():UpdateMoneyBar()
    end
end

function CapsuleRandomPoolDrawMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require( 'Game.views.drawCards.CapsuleRandomPoolDrawView' ).new()
    viewComponent:setPosition(cc.p(display.cx, display.cy))
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()
    viewData.previewBtn:setOnClickScriptHandler(handler(self, self.PreviewButtonCallback))
    viewData.refreshBtn:setOnClickScriptHandler(handler(self, self.RefreshButtonCallback))
    viewData.drawBtn:setOnClickScriptHandler(handler(self, self.DrawButtonCallback))
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    -- 刷新界面
    self:InitView()
end

function CapsuleRandomPoolDrawMediator:InitView()
    local view = self:GetViewComponent()
    local rewardsData = self.rewardsData
    local poolConfig = CommonUtils.GetConfig('gambling', 'randBuffChildPool', checkint(self.rewardsData.pool.poolId))
    local moneyIdMap = {}
    local goodsId = rewardsData.option.consume[1].goodsId
    moneyIdMap[tostring(goodsId)] = goodsId
    view:ReloadMoneyBar(moneyIdMap, false)
    view:GetViewData().titleLabel:setString(poolConfig.name)
    view:RefreshLeftRefreshTimes(rewardsData.pool.isRefresh)
    view:RefreshDrawConsume(rewardsData.option.consume)
    view:ShowRewards(rewardsData.pool.dropCards)
end
---------------------------------------------
----------------- method --------------------
----------------- method --------------------
---------------------------------------------

---------------------------------------------
---------------- callback -------------------
--[[
预览按钮回调
--]]
function CapsuleRandomPoolDrawMediator:PreviewButtonCallback( sender )
    PlayAudioByClickNormal()
    local poolView  = PoolPreviewView.new({cardPoolDatas = self.rewardsData.option})
    app.uiMgr:GetCurrentScene():AddDialog(poolView)
end
--[[
刷新按钮回调
--]]
function CapsuleRandomPoolDrawMediator:RefreshButtonCallback( sender )
    PlayAudioByClickNormal()
    if checkint(self.rewardsData.pool.isRefresh) == 1 then
        app.uiMgr:ShowInformationTips(__('刷新次数不足'))
    else
        local text = __('是否重铸当前卡池？')
        local descrRich = {
            {text = __('重铸会改变卡池类型，请慎重选择。'), color = '#d23d3d'}
        }
        local callback = function ()
            AppFacade.GetInstance():DispatchObservers(CAPSULE_RANDOM_POOL_REFRESH, {poolNum = self.rewardsData.poolNum})
            AppFacade.GetInstance():UnRegsitMediator("CapsuleRandomPoolDrawMediator")
        end
        -- 显示购买弹窗
        local layer = require('common.CommonTip').new({
            text = text,
            defaultRichPattern = true,
            callback = callback,
            descrRich = descrRich,
        })
        layer:setPosition(display.center)
        app.uiMgr:GetCurrentScene():AddDialog(layer)
    end
end
--[[
领取按钮回调
--]]
function CapsuleRandomPoolDrawMediator:DrawButtonCallback( sender )
    PlayAudioByClickNormal()
    local capsuleConsume = self.rewardsData.option.consume[1] or {}
    if next(capsuleConsume) ~= nil and  app.gameMgr:GetAmountByGoodId(capsuleConsume.goodsId) >= checkint(capsuleConsume.num) then
        -- 道具足够
        -- if self:GetShowDrawConfirm() then
            local goodsConf = CommonUtils.GetConfig('goods', 'goods', capsuleConsume.goodsId) or {}
            local goodsName = tostring(goodsConf.name)
            local tipsView  = require('common.CommonTip').new({
                text  = __('是否确定召唤？'),
                descr = string.fmt(__('本次召唤会消耗_num_个_name_'), {_name_ = goodsName, _num_ = capsuleConsume.num}),
                callback = function (sender)
                    AppFacade.GetInstance():DispatchObservers(CAPSULE_RANDOM_POOL_DRAW, {poolNum = self.rewardsData.poolNum})
                    AppFacade.GetInstance():UnRegsitMediator("CapsuleRandomPoolDrawMediator")
                end
            })
            tipsView:setPosition(display.center)
            app.uiMgr:GetCurrentScene():AddDialog(tipsView)
        -- else
        --     self:SendSignal(POST.GAMBLING_LUCKY_BAG_PREVIEW.cmdName, {activityId = self.homeData_.requestData.activityId})
        -- end
    else
        -- 道具不足
        app.capsuleMgr:ShowGoodsShortageTips(capsuleConsume.goodsId)
    end
end
--[[
返回按钮回调
--]]
function CapsuleRandomPoolDrawMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    AppFacade.GetInstance():UnRegsitMediator("CapsuleRandomPoolDrawMediator")
end
---------------- callback -------------------
---------------------------------------------

---------------------------------------------
---------------- get / set ------------------

---------------- get / set ------------------
---------------------------------------------
function CapsuleRandomPoolDrawMediator:OnRegist(  )
end

function CapsuleRandomPoolDrawMediator:OnUnRegist(  )
    AppFacade.GetInstance():UnRegsitMediator("CapsuleRandomPoolAnimationMediator")
    app.uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())
end
return CapsuleRandomPoolDrawMediator