--[[
买活抢救场景
--]]
local BaseMiniGameScene = __Require('battle.miniGame.BaseMiniGameScene')
local RescueAllFriendScene = class('RescueAllFriendScene', BaseMiniGameScene)
--[[
@override
--]]
function RescueAllFriendScene:initView()
	BaseMiniGameScene.initView(self)
	self.eaterLayer:setOpacity(0)

	local actionLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	actionLayer:setContentSize(display.size)
	actionLayer:setPosition(utils.getLocalCenter(self))
	self:addChild(actionLayer, 10)
	self.actionLayer = actionLayer
end
--[[
@override
开始游戏
--]]
function RescueAllFriendScene:start()
	if self.args.startCB then
		xTry(function()
			self.args.startCB()
		end, __G__TRACKBACK__)
	end

	local actionSeq = cc.Sequence:create(
		cc.FadeTo:create(0.5, 0),
		cc.CallFunc:create(function ()
			if self.args.callbacks.reviveBegin then
				xTry(function()
					self.args.callbacks.reviveBegin()
				end, __G__TRACKBACK__)
			end
		end),
		cc.DelayTime:create(1.5),
		cc.FadeTo:create(1, 255),
		cc.CallFunc:create(function ()
			if self.args.callbacks.reviveMiddle then
				xTry(function()
					self.args.callbacks.reviveMiddle()
				end, __G__TRACKBACK__)
			end
		end),
		cc.FadeTo:create(1, 0),
		cc.CallFunc:create(function ()
			if self.args.callbacks.reviveEnd then
				xTry(function()
					self.args.callbacks.reviveEnd()
				end, __G__TRACKBACK__)
			end
			self:over()
		end)
	)
	self.actionLayer:runAction(actionSeq)
end
--[[
@override
游戏结束
--]]
function RescueAllFriendScene:over()
	BaseMiniGameScene.over(self)
	print('here rescue scene over<<<<<<<<<<<<<<<<<<<<<<')
end
--[[
@override
update
--]]
function RescueAllFriendScene:update(dt)
	
end
--[[
强制移除
--]]
function RescueAllFriendScene:die()	
	if self.args.dieCB then
		xTry(function()
			self.args.dieCB()
		end, __G__TRACKBACK__)
	end

	if self.touchListener_ then
		self:getEventDispatcher():removeEventListener(self.touchListener_)
		self.touchListener_ = nil
	end

	self:setVisible(false)
	self:stopAllActions()

	local dieActionSeq = cc.Sequence:create(
		cc.DelayTime:create(1 * cc.Director:getInstance():getAnimationInterval()),
		cc.CallFunc:create(function ()

		end),
		cc.RemoveSelf:create()
	)
	self:runAction(dieActionSeq)
end

return RescueAllFriendScene
