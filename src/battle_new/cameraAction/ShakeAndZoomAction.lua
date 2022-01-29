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
	-- 屏蔽触摸
	self:SetGameTouchEnable(false)

	-- 恢复游戏加速
	if self:NeedStopGameAccelerate() then
		G_BattleLogicMgr:RenderSetTempTimeScaleHandler(1)
	end

	local scale = self:GetCameraActionInfo().cameraActionValue

	--***---------- 刷新渲染层 ----------***--
	-- TODO --
	-- 此处传的tag暂时使用id
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'CameraActionShakeAndZoom',
		self:GetOwnerTag(), self:GetCameraActionId(), scale
	)
	-- TODO --
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

return ShakeAndZoomAction
