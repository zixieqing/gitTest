--[[
波数切换场景
@params callbacks table 回调 {
	changeBegin 屏幕黑完回调 开始创建下一波
	changeEnd 黑屏结束回调 开始下一波
}
--]]
local BaseMiniGameScene = __Require('battle.miniGame.BaseMiniGameScene')
local WaveTransitionScene = class('WaveTransitionScene', BaseMiniGameScene)
--[[
@override
--]]
function WaveTransitionScene:initView()
	BaseMiniGameScene.initView(self)

	self.eaterLayer:setVisible(false)
	self.actionLayer = nil

	local actionLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	-- actionLayer:setTouchEnabled(true)
	actionLayer:setContentSize(display.size)
	actionLayer:setPosition(utils.getLocalCenter(self))
	self:addChild(actionLayer, 10)
	self.actionLayer = actionLayer
end
--[[
@override
开始切波
--]]
function WaveTransitionScene:start()
	BaseMiniGameScene.start(self)

	local actionSeq = cc.Sequence:create(
		cc.FadeTo:create(1, 255),
		cc.CallFunc:create(function ()
			if self.args.callbacks.changeBegin then
				self.args.callbacks.changeBegin()
			end
		end)
	)

	self.actionLayer:runAction(actionSeq)
end
--[[
切波继续
--]]
function WaveTransitionScene:ContinueWaveTransition()
	local actionSeq = cc.Sequence:create(
		cc.FadeTo:create(1, 0),
		cc.CallFunc:create(function ()
			if self.args.callbacks.changeEnd then
				self.args.callbacks.changeEnd()
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
function WaveTransitionScene:over()
	BaseMiniGameScene.over(self)
end
--[[
@override
update
--]]
function WaveTransitionScene:update(dt)
	
end

return WaveTransitionScene
