--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）抽奖 领奖Mediator
--]]
local Mediator = mvc.Mediator
local MurderCapsuleRewardMediator = class("MurderCapsuleRewardMediator", Mediator)
local NAME = "MurderCapsuleRewardMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local RES_DICT = {
	SUMMER_ACTIVITY_DAN_PATH = 'ui/home/activity/murder/effect/murder_draw_watch'
} 

function MurderCapsuleRewardMediator:ctor( params, viewComponent )

	RES_DICT.SUMMER_ACTIVITY_DAN = app.murderMgr:GetSpinePath(RES_DICT.SUMMER_ACTIVITY_DAN_PATH)
	
	self.super:ctor(NAME, viewComponent)
	self.rewards = checktable(params.rewards) -- 奖励
	self.backCallback = params.backCallback   -- 动画结束回调
end


function MurderCapsuleRewardMediator:InterestSignals()
	local signals = {
	}
	return signals
end

function MurderCapsuleRewardMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	local datas = checktable(signal:GetBody())
end

function MurderCapsuleRewardMediator:Initial( key )
	self.super.Initial(self, key)
	-- 创建MailPopup
    local viewComponent = require( 'Game.views.activity.murder.MurderCapsuleRewardView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(viewComponent)
	if #self.rewards == 1 then
		self:DrawOneAction()
	elseif #self.rewards > 1 and #self.rewards <= 10 then
		self:DrawTenAction()
	else
		print('数量错误')
	end	
end
--[[
单抽动画
--]]
function MurderCapsuleRewardMediator:DrawOneAction( )
	local viewData = self:GetViewComponent().viewData
	local rewards = self.rewards[1]
	if not rewards then return end
		local eggSpine =  SpineCache(SpineCacheName.MURDER):createWithName(RES_DICT.SUMMER_ACTIVITY_DAN.path)
		eggSpine:update(0)
		eggSpine:setToSetupPose()
		eggSpine:setPosition(cc.p(display.cx, display.cy))
		viewData.view:addChild(eggSpine, 3)
        eggSpine:registerSpineEventHandler(handler(self, self.DrawOneSpineEndHandler), sp.EventType.ANIMATION_END)
        if checkint(rewards.isRare) == 0 then 
            eggSpine:setAnimation(0, 'open1', false)
        elseif checkint(rewards.isRare) == 1 then 
            eggSpine:setAnimation(0, 'open2', false)
        elseif checkint(rewards.isRare) == 2 then 
            eggSpine:setAnimation(0, 'open3', false)
        end
	end
--[[
spine结束回到
--]]
function MurderCapsuleRewardMediator:DrawOneSpineEndHandler( event )
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveViewForNoTouch()
	uiMgr:AddDialog('common.RewardPopup', {rewards = self.rewards, closeCallback = self.backCallback})
	local rewards = self.rewards[1]
	if checkint(rewards.isRare) > 0 and #self.rewards == 1 then
		-- 添加特效
		local cotAnimation = sp.SkeletonAnimation:create(
			'effects/capsule/capsule.json',
			'effects/capsule/capsule.atlas',
			1)
		cotAnimation:update(0)
		cotAnimation:setToSetupPose()
		cotAnimation:setAnimation(0, 'chouka_qian', false)
		cotAnimation:setPosition(display.center)
		-- 结束后移除
		cotAnimation:registerSpineEventHandler(function (event)
			cotAnimation:runAction(cc.RemoveSelf:create())
		end, sp.EventType.ANIMATION_END)
		sceneWorld:addChild(cotAnimation, GameSceneTag.Dialog_GameSceneTag)
	end
	AppFacade.GetInstance():UnRegsitMediator('MurderCapsuleRewardMediator')
end
--[[
十连动画
--]]
function MurderCapsuleRewardMediator:DrawTenAction()
	local eggs = {}
	local viewData = self:GetViewComponent().viewData
	for i, v in ipairs(self.rewards) do
	    -- local eggSpine = sp.SkeletonAnimation:create(
        -- 	RES_DICT.SUMMER_ACTIVITY_DAN.json,
        -- 	RES_DICT.SUMMER_ACTIVITY_DAN.atlas,
		-- 1)	
		local eggSpine = SpineCache(SpineCacheName.MURDER):createWithName(RES_DICT.SUMMER_ACTIVITY_DAN.path)
		eggSpine:setScale(0.6)
		eggSpine:setPosition(cc.p(display.cx, display.cy))
		viewData.view:addChild(eggSpine, 1) 
        if checkint(v.isRare) == 0 then 
            eggSpine:setAnimation(0, 'idle1', false)
        elseif checkint(v.isRare) == 1 then 
            eggSpine:setAnimation(0, 'idle2', false)
        elseif checkint(v.isRare) == 2 then 
            eggSpine:setAnimation(0, 'idle3', false)
        end
		eggSpine:setPosition(cc.p(display.cx - 480 + 250 * ((i - 1) % 5), display.height + 1400 - math.ceil(i/5) * 350))
		-- 下落动画
		eggSpine:runAction(
			cc.Sequence:create(
				cc.DelayTime:create(math.random()), 
				cc.EaseBackOut:create(
					cc.MoveTo:create(1, cc.p(display.cx - 480 + 250 * ((i - 1) % 5), display.cy + 525 - math.ceil(i/5) * 350))
				)
			)
		)
		-- 开启动画
		self:GetViewComponent():performWithDelay(
			function ()
				eggSpine:update(0)
                eggSpine:setToSetupPose()
                if checkint(v.isRare) == 0 then 
                    eggSpine:setAnimation(0, 'open1', false)
                elseif checkint(v.isRare) == 1 then 
                    eggSpine:setAnimation(0, 'open2', false)
                elseif checkint(v.isRare) == 2 then 
                    eggSpine:setAnimation(0, 'open3', false)
                end
				if i == #self.rewards then
					eggSpine:registerSpineEventHandler(handler(self, self.DrawOneSpineEndHandler), sp.EventType.ANIMATION_END)
				end
			end, 
			2.5 + i * 0.1
		)
	end
end	

function MurderCapsuleRewardMediator:OnRegist(  )
	
end

function MurderCapsuleRewardMediator:OnUnRegist(  )
	
	-- 移除界面
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end
return MurderCapsuleRewardMediator