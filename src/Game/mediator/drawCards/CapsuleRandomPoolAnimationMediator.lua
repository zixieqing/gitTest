--[[
铸池抽卡动画mediator    
--]]
local Mediator = mvc.Mediator
local CapsuleRandomPoolAnimationMediator = class("CapsuleRandomPoolAnimationMediator", Mediator)
local NAME = "CapsuleRandomPoolAnimationMediator"
--[[
@params map {
    pool map {
        dropCards list 奖励列表
        hasDrawn  int  是否领取
        isRefresh int  是否刷新
        poolId    int  卡池id
    }
    skipAnimation bool 跳过动画
    activityId    int  活动id
    poolNum       int  卡池编号
    option        list 卡池预览
}
--]]
function CapsuleRandomPoolAnimationMediator:ctor( params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    self.animationData = checktable(params)
end

function CapsuleRandomPoolAnimationMediator:InterestSignals()
	local signals = {
	}
	return signals
end

function CapsuleRandomPoolAnimationMediator:ProcessSignal( signal )
	local name = signal:GetName()
    print(name)
end

function CapsuleRandomPoolAnimationMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require( 'Game.views.drawCards.CapsuleRandomPoolAnimationView' ).new({})
    viewComponent:setPosition(cc.p(display.cx, display.cy))
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
	-- 绑定spine事件
	viewComponent.viewData.capsuleAnimation:registerSpineEventHandler(handler(self, self.SpineEventHandler), sp.EventType.ANIMATION_EVENT)
    viewComponent.viewData.capsuleAnimation:registerSpineEventHandler(handler(self, self.SpineEndHandler), sp.EventType.ANIMATION_END)
    -- 判断是否播放动画
    if self.animationData.skipAnimation then
        self:ShowRewardsView()
    else
        self:ShowEnterAnimation()
    end
end
--[[
转换奖励数据结构
--]]
function CapsuleRandomPoolAnimationMediator:ConvertRewardsData( rewards )
    if not rewards then return end
    return rewardsData
end
--[[
进入动画
--]]
function CapsuleRandomPoolAnimationMediator:ShowEnterAnimation()
    local poolId = self.animationData.pool.poolId
    -- 随机抽选动画图片
    local imageList = {}
    local otherPool = {}
    local randomPool = {}
    for i, v in ipairs(self.animationData.option) do
        if checkint(poolId) ~= checkint(v.poolId) then
            table.insert(otherPool, checkint(v.poolId))
        end
    end
    for i = 1, 4 do
        local randomNum = math.random(1, #otherPool)
        local randomPoolId = otherPool[randomNum]
        table.insert(randomPool, randomPoolId)
        table.remove(otherPool, randomNum)
    end
    table.insert(randomPool, poolId)
    for i, poolId in ipairs(randomPool) do
        local poolConfig = CommonUtils.GetConfig('gambling', 'randBuffChildPool', checkint(poolId))
        table.insert(imageList, poolConfig.poolView)
    end
    local view = self:GetViewComponent()
    view:EnterAnimation(imageList)
end
--[[
显示奖励页面
--]]
function CapsuleRandomPoolAnimationMediator:ShowRewardsView()
    -- 添加领奖界面
    local params = {
        pool = self.animationData.pool,
        poolNum = self.animationData.poolNum
    }
    for i, v in ipairs(self.animationData.option) do
        if checkint(v.poolId) == checkint(self.animationData.pool.poolId) then
            params.option = v
            break
        end
    end
    local mediator = require("Game.mediator.drawCards.CapsuleRandomPoolDrawMediator").new(params)
    AppFacade.GetInstance():RegistMediator(mediator)
end
---------------------------------------------
-------------- spine事件绑定 -----------------
--[[
spine自定义事件回调
--]]
function CapsuleRandomPoolAnimationMediator:SpineEventHandler(event)
    if not event or not event.eventData then return end
    if 'play' == event.eventData.name then
        self:ShowRewardsView()
	end
end
--[[
spine动画播放结束回调
--]]
function CapsuleRandomPoolAnimationMediator:SpineEndHandler(event)
	if event.animation == 'play' or event.animation == 'play2' then
    	self.viewComponent:performWithDelay(
            function ()
                -- 将spine恢复至初始状态
                self:GetViewComponent():RecoverCapsuleIdleState()
            end,
            (1 * cc.Director:getInstance():getAnimationInterval())
        )
	end
end
-------------- spine事件绑定 -----------------
---------------------------------------------
function CapsuleRandomPoolAnimationMediator:OnRegist(  )
    -- 开启背景音乐
    self.bgm = PlayAudioClip(AUDIOS.UI.ui_await.id, true)
end

function CapsuleRandomPoolAnimationMediator:OnUnRegist(  )
	-- 关闭背景音乐
	if self.bgm then
		self.bgm:Stop(true)
        self.bgm = nil
    end   
    app.uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())
end
return CapsuleRandomPoolAnimationMediator