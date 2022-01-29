--[[
 * author : liuzhipeng
 * descpt : 新抽卡 - 铸池卡池
]]
local CapsuleRandomPoolMediator = class('CapsuleRandomPoolMediator', mvc.Mediator)

local CreateView = nil
local CapsuleRandomPoolView = require("Game.views.drawCards.CapsuleRandomPoolView")

function CapsuleRandomPoolMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CapsuleRandomPoolMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
    self.showDrawConfirm = true
end


-------------------------------------------------
-- inheritance method

function CapsuleRandomPoolMediator:Initial(key)
    self.super.Initial(self, key)

    self.ownerNode_ = self.ctorArgs_.ownerNode

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = CapsuleRandomPoolView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.drawBtn:setOnClickScriptHandler(handler(self, self.DrawButtonCallback))
        viewData.resetBtn:setOnClickScriptHandler(handler(self, self.ResetButtonCallback))
    end
end


function CapsuleRandomPoolMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function CapsuleRandomPoolMediator:OnRegist()
    regPost(POST.GAMBLING_RANDOM_POOL_REFRESH)
    regPost(POST.GAMBLING_RANDOM_POOL_LUCKY)
    regPost(POST.GAMBLING_RANDOM_POOL_RESET)
end
function CapsuleRandomPoolMediator:OnUnRegist()
    unregPost(POST.GAMBLING_RANDOM_POOL_REFRESH)
    unregPost(POST.GAMBLING_RANDOM_POOL_LUCKY)
    unregPost(POST.GAMBLING_RANDOM_POOL_RESET)
end


function CapsuleRandomPoolMediator:InterestSignals()
    local signals = {
        POST.GAMBLING_RANDOM_POOL_REFRESH.sglName, -- 抽取卡池
        POST.GAMBLING_RANDOM_POOL_LUCKY.sglName,   
        POST.GAMBLING_RANDOM_POOL_RESET.sglName,   
        CAPSULE_RANDOM_POOL_PREVIEW,            
        CAPSULE_RANDOM_POOL_REFRESH,
        CAPSULE_RANDOM_POOL_DRAW,
	}
	return signals
end
function CapsuleRandomPoolMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.GAMBLING_RANDOM_POOL_REFRESH.sglName then
        -- 抽取卡池
        self:PoolsDraw(body)
    elseif name == POST.GAMBLING_RANDOM_POOL_LUCKY.sglName then
        -- 领奖
        self:DrawRewards(body)
    elseif name == POST.GAMBLING_RANDOM_POOL_RESET.sglName then
        -- 重置
        CommonUtils.DrawRewards({
			{goodsId = checkint(self.homeData_.resetConsumeGoodsId), num = -checkint(self.homeData_.resetConsumeNum)}
        })
        self:SendSignal(POST.GAMBLING_RANDOM_POOL_ENTER.cmdName, {activityId = self.homeData_.requestData.activityId})
    elseif name == CAPSULE_RANDOM_POOL_PREVIEW then
        -- 显示抽卡奖励界面
        self:ShowDrawView(body.poolNum)
    elseif name == CAPSULE_RANDOM_POOL_REFRESH then
        -- 刷新卡池
        self:RefreshTargetPool(body.poolNum)
    elseif name == CAPSULE_RANDOM_POOL_DRAW then
        -- 购买奖励
        self:DrawTargetPool(body.poolNum)
    end
end


-------------------------------------------------
-- handler method
function CapsuleRandomPoolMediator:DrawButtonCallback( sender )
    PlayAudioByClickNormal()
    local currentTime = checkint(self.homeData_.refreshTimes)
    local refreshConsume = checktable(self.homeData_.refreshConsume)
    local maxTime = table.nums(refreshConsume)
    if currentTime == maxTime then
        app.uiMgr:ShowInformationTips(__('次数已用完'))
        return 
    end
    local capsuleConsume = refreshConsume[tostring(currentTime + 1)].consume[1]
    --抽取的卡池编号
    local poolNum = currentTime + 1
    if not capsuleConsume or next(capsuleConsume) == nil then
        self:SendSignal(POST.GAMBLING_RANDOM_POOL_REFRESH.cmdName, {activityId = self.homeData_.requestData.activityId, poolNum = poolNum})
        return 
    end
    if app.gameMgr:GetAmountByGoodId(capsuleConsume.goodsId) >= checkint(capsuleConsume.num) then
        -- 道具足够
        if self:GetShowDrawConfirm() and checkint(capsuleConsume.num) > 0 then
            local goodsConf = CommonUtils.GetConfig('goods', 'goods', capsuleConsume.goodsId) or {}
            local goodsName = tostring(goodsConf.name)
	    	local tipsView  = require('common.CommonTip').new({
	    		text  = __('是否确定召唤？'),
	    		descr = string.fmt(__('本次召唤会消耗_num_个_name_'), {_name_ = goodsName, _num_ = capsuleConsume.num}),
	    		callback = function (sender)
	    			self:SetShowDrawConfirm(false)
	    			self:SendSignal(POST.GAMBLING_RANDOM_POOL_REFRESH.cmdName, {activityId = self.homeData_.requestData.activityId, poolNum = poolNum})
	    		end
	    	})
	    	tipsView:setPosition(display.center)
	    	app.uiMgr:GetCurrentScene():AddDialog(tipsView)
	    else
	    	self:SendSignal(POST.GAMBLING_RANDOM_POOL_REFRESH.cmdName, {activityId = self.homeData_.requestData.activityId, poolNum = poolNum})
        end
    else
        -- 道具不足
        app.capsuleMgr:ShowGoodsShortageTips(capsuleConsume.goodsId)
    end
end
--[[
重置按钮点击回调
--]]
function CapsuleRandomPoolMediator:ResetButtonCallback()
    PlayAudioByClickNormal()
    -- 判断是否可以重置
    local homeData = self.homeData_
    if next(checktable(homeData.pools)) == nil then
        app.uiMgr:ShowInformationTips(__('召唤铸池后即可重置'))
        return 
    end
    -- 判断次数是否足够
    if checkint(homeData.leftResetTimes) == 0 and checkint(homeData.totalResetTimes) ~= -1 then
        app.uiMgr:ShowInformationTips(__('重置次数不足'))
        return
    end
    -- 判断幻晶石是否足够
    if app.gameMgr:GetAmountByGoodId(homeData.resetConsumeGoodsId) < checkint(homeData.resetConsumeNum) then
        -- 道具不足
        app.capsuleMgr:ShowGoodsShortageTips(homeData.resetConsumeGoodsId)
        return 
    end

    local tips = __('是否要重置?')
    -- 判断卡池是否抽满买满
    if table.nums(homeData.pools) ~= 3 then
        tips = __('还有可用的召唤次数或没购买的抽卡内容，确认要重置吗？')
    else
        for k, v in pairs(homeData.pools) do
            if checkint(v.hasDrawn) == 0 then
                tips = __('还有可用的召唤次数或没购买的抽卡内容，确认要重置吗？')
                break
            end
        end
    end
    local commonTip  = require( 'common.CommonTip' ).new({text = tips, callback = function ()
		self:SendSignal(POST.GAMBLING_RANDOM_POOL_RESET.cmdName, {activityId = self.homeData_.requestData.activityId})
	end})
	commonTip:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(commonTip)
end
-------------------------------------------------
-- get /set
--[[
获取是否要弹抽卡确认框
--]]
function CapsuleRandomPoolMediator:GetShowDrawConfirm()
	return self.showDrawConfirm
end
function CapsuleRandomPoolMediator:SetShowDrawConfirm(show)
	self.showDrawConfirm = show
end
-------------------------------------------------
-- private method
--[[
刷新页面
--]]
function CapsuleRandomPoolMediator:RefreshView()
    -- 刷新抽卡按钮
    self:RefreshDrawButton()
    -- 刷新resetLayout
    self:RefreshResetLayout()
    -- 刷新重置按钮状态
    self:RefreshResetBtnState()
    -- 刷新页面
    local view = self:GetViewComponent()
    view:RefreshUI(self.homeData_.pools)
end
--[[
刷新抽卡按钮
--]]
function CapsuleRandomPoolMediator:RefreshDrawButton()
    local view = self:GetViewComponent()
    local currentTime = checkint(self.homeData_.refreshTimes)
    local refreshConsume = checktable(self.homeData_.refreshConsume)
    local maxTime = table.nums(refreshConsume)
    local consume = {}
    if refreshConsume[tostring(currentTime + 1)] then
        consume = refreshConsume[tostring(currentTime + 1)].consume
    end
    view:RefreshDrawButton(currentTime, maxTime, consume)
end
--[[
刷新resetLayout 
--]]
function CapsuleRandomPoolMediator:RefreshResetLayout()
    local view = self:GetViewComponent()
    local leftResetTimes = checkint(self.homeData_.leftResetTimes)
    local totalResetTimes = checkint(self.homeData_.totalResetTimes)
    local resetConsume = {
        goodsId = checkint(self.homeData_.resetConsumeGoodsId),
        num = checkint(self.homeData_.resetConsumeNum)
    }
    view:RefreshResetLayout(leftResetTimes, totalResetTimes, resetConsume)
end
--[[
刷新重置按钮状态
--]]
function CapsuleRandomPoolMediator:RefreshResetBtnState()
    local viewComponent = self:GetViewComponent()
    local homeData = self.homeData_
    local enabled = true
    if next(checktable(homeData.pools)) == nil then
        enabled = false
    else
        if checkint(homeData.leftResetTimes) == 0 and checkint(homeData.totalResetTimes) ~= -1 then
            enabled = false
        end
    end
    viewComponent:RefreshResetBtnState(enabled)
end
--[[
抽取卡池
@params pools map key:卡池id value:卡池数据
--]]
function CapsuleRandomPoolMediator:PoolsDraw( params )
    local view = self:GetViewComponent()
    -- 判断是抽取还是刷新
    if self.homeData_.pools[tostring(params.requestData.poolNum)] then
        -- 刷新 --
        self.homeData_.pools[tostring(params.requestData.poolNum)] = params.pool
    else
        -- 抽取 --
        -- 扣除道具
        local currentTime = checkint(self.homeData_.refreshTimes)
        local refreshConsume = checktable(self.homeData_.refreshConsume)
        local consume = clone(refreshConsume[tostring(currentTime + 1)].consume)
        for i, v in ipairs(consume) do
            v.num = -v.num
        end
        CommonUtils.DrawRewards(consume)
        -- 刷新本地数据
        self.homeData_.pools[tostring(params.requestData.poolNum)] = params.pool
        self.homeData_.refreshTimes = self.homeData_.refreshTimes + 1
    end
    -- 播放抽卡动画
    local animationData = {
        pool          = params.pool,
        skipAnimation = false,
        activityId    = self.homeData_.requestData.activityId,
        poolNum       = params.requestData.poolNum, 
        option        = self.homeData_.option
    }
    local mediator = require("Game.mediator.drawCards.CapsuleRandomPoolAnimationMediator").new(animationData)
    AppFacade.GetInstance():RegistMediator(mediator)
    -- 刷新抽卡按钮
    self:RefreshDrawButton()
    -- 刷新重置按钮状态
    self:RefreshResetBtnState()
    -- 刷新卡池列表
    view:RefreshPools(self.homeData_.pools)
end
--[[
显示抽卡奖励界面
@params poolNum int 卡池序号
--]]
function CapsuleRandomPoolMediator:ShowDrawView( poolNum )
    if not self.homeData_.pools[tostring(poolNum)] or checkint(self.homeData_.pools[tostring(poolNum)].hasDrawn) == 1 then return end
    local animationData = {
        pool          = self.homeData_.pools[tostring(poolNum)],
        skipAnimation = true,
        activityId    = self.homeData_.requestData.activityId,
        poolNum       = poolNum, 
        option        = self.homeData_.option
    }
    local mediator = require("Game.mediator.drawCards.CapsuleRandomPoolAnimationMediator").new(animationData)
    AppFacade.GetInstance():RegistMediator(mediator)
end
--[[
刷新指定卡池
@params poolNum int 卡池序号
--]]
function CapsuleRandomPoolMediator:RefreshTargetPool( poolNum )
    self:SendSignal(POST.GAMBLING_RANDOM_POOL_REFRESH.cmdName, {activityId = self.homeData_.requestData.activityId, poolNum = poolNum})
end
--[[
领取指定卡池
@params poolNum int 卡池序号
--]]
function CapsuleRandomPoolMediator:DrawTargetPool( poolNum )
    self:SendSignal(POST.GAMBLING_RANDOM_POOL_LUCKY.cmdName, {activityId = self.homeData_.requestData.activityId, poolNum = poolNum})
end
--[[
领奖
@params {
    rewards         list 奖励
    activityRewards list 活动奖励
    diamond         int 钻石数量
}
--]]
function CapsuleRandomPoolMediator:DrawRewards( params )
    -- 扣除道具
    local poolData = self.homeData_.pools[tostring(params.requestData.poolNum)]
    for i, v in ipairs(self.homeData_.option) do
        if checkint(v.poolId) == checkint(poolData.poolId) then
            local consume = clone(v.consume)
            for i, v in ipairs(consume) do
                v.num = -v.num
            end
            CommonUtils.DrawRewards(consume)
        end
    end
    -- 处理活动奖励
    table.insertto(params.rewards, params.activityRewards)
    -- 领取
    app.uiMgr:AddDialog('common.RewardPopup', {rewards = params.rewards})
    -- 刷新卡池列表
    poolData.hasDrawn = 1
    local view = self:GetViewComponent()
    view:RefreshPools(self.homeData_.pools)
end
-------------------------------------------------
-- public method
function CapsuleRandomPoolMediator:resetHomeData( homeData )
    self.homeData_ = homeData
    self:RefreshView()
end


return CapsuleRandomPoolMediator
