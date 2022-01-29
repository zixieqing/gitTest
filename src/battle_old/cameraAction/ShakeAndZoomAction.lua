--[[
抖屏和缩放预设的镜头效果
--]]
local BaseCameraAction = __Require('battle.cameraAction.BaseCameraAction')
local ShakeAndZoomAction = class('ShakeAndZoomAction', BaseCameraAction)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function ShakeAndZoomAction:ctor( ... )
	BaseCameraAction.ctor(self, ...)
end
---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
@override
进行动作
--]]
function ShakeAndZoomAction:OnActionEnter()
	-- 设置触摸
	BMediator:SetBattleTouchEnable(false)

	-- 是否需要设置全景加速
	if self.needStopGameAccelerate then
		cc.Director:getInstance():getScheduler():setTimeScale(1)
	end

	local staticShakeTime = 1
	local scaleTime = 1.75
	local scale = self:GetCameraActionInfo().cameraActionValue

	local battleScene = BMediator:GetViewComponent()

	------------ 设置一些节点大小 ------------
	local scaledSize = cc.size(
		battleScene:getContentSize().width * battleScene:getScaleX() * scale,
		battleScene:getContentSize().height * battleScene:getScaleY() * scale
	)
	local convertScaleX, convertScaleY = display.width / scaledSize.width, display.height / scaledSize.height

	-- 高亮底层
	local targetNode = battleScene.viewData.effectLayer
	local fixedSize = cc.size(
		targetNode:getContentSize().width * convertScaleX,
		targetNode:getContentSize().height * convertScaleY
	)
	targetNode:setContentSize(fixedSize)
	------------ 设置一些节点大小 ------------

	------------ 前景抖动动画 ------------
	local fgShakeAction = cc.Sequence:create(
		ShakeAction:create(staticShakeTime + scaleTime, 20, 10)
	)
	battleScene.viewData.fgLayer:runAction(fgShakeAction)
	------------ 前景抖动动画 ------------

	------------ 后景抖动动画 ------------
	local bgShakeAction = cc.Sequence:create(
		ShakeAction:create(staticShakeTime + scaleTime, 10, 5)
	)
	battleScene.viewData.bgLayer:runAction(bgShakeAction)
	------------ 后景抖动动画 ------------

	------------ 地图层抖动动画 ------------
	local battleLayerShakeAction = cc.Sequence:create(
		ShakeAction:create(staticShakeTime + scaleTime, 15, 7)
	)
	battleScene.viewData.battleLayer:runAction(battleLayerShakeAction)
	------------ 地图层抖动动画 ------------

	------------ 场景动画 ------------
	local sceneActionSeq = cc.Sequence:create(
		cc.DelayTime:create(staticShakeTime),
		cc.EaseIn:create(cc.ScaleTo:create(scaleTime, scale), 3),
		cc.CallFunc:create(function ()
			self:OnActionExit()
		end)
	)
	battleScene.viewData.fieldLayer:runAction(sceneActionSeq)
	------------ 场景动画 ------------
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

return ShakeAndZoomAction
