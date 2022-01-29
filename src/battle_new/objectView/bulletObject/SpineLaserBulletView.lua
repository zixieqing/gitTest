--[[
带spine动画laser子弹view类
@params t table {
	tag int obj view tag 此tag与战斗物体逻辑层tag对应
	viewInfo BulletViewConstructorStruct 渲染层构造数据
}
--]]
local BaseSpineBulletView = __Require('battle.objectView.bulletObject.BaseSpineBulletView')
local SpineLaserBulletView = class('SpineLaserBulletView', BaseSpineBulletView)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
@override
constructor
--]]
function SpineLaserBulletView:ctor( ... )
	BaseSpineBulletView.ctor(self, ...)

	self.laserPart = nil
end

---------------------------------------------------
-- init view begin --
---------------------------------------------------

---------------------------------------------------
-- init view end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
修正激光束的长度
@params length number 长度
--]]
function SpineLaserBulletView:FixLaserBodyLength(length)
	if sp.LaserAnimationName.laserBody == self:GetLaserPart() then
		local oriLaserBodyViewBox = self:GetAvatar():getBorderBox(sp.CustomName.VIEW_BOX)
		if nil ~= oriLaserBodyViewBox then
			local fixedScaleX = length / oriLaserBodyViewBox.width
			self:GetAvatar():setScaleX(fixedScaleX)
		end
	end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
设置激光的部位类型
@params part sp.LaserAnimationName
--]]
function SpineLaserBulletView:SetLaserPart(part)
	if nil == self.laserPart then
		self.laserPart = part

		local size = self:getContentSize()

		-- 在这里处理一次锚点
		if sp.LaserAnimationName.laserHead == part then

			self:setAnchorPoint(cc.p(0.5, 0.5))
			self:GetAvatar():setPosition(cc.p(size.width * 0.5, size.height * 0.5))

		else

			self:setAnchorPoint(0, 0.5)
			self:GetAvatar():setPosition(cc.p(0, size.height * 0.5))
			
		end
	end
end
function SpineLaserBulletView:GetLaserPart()
	return self.laserPart
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return SpineLaserBulletView
