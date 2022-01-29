--[[
带spine动画的激光型子弹
@params{
	spineName string 缓存的spine动画名
	actionName string 动作名称
}
--]]
local SpineBaseBulletView = __Require('battle.bullet.SpineBaseBulletView')
local SpineLaserBulletView = class('SpineLaserBulletView', SpineBaseBulletView)

--[[
@override
constructor
--]]
function SpineLaserBulletView:ctor( ... )
	local args = unpack({...})

	self.viewData = {}
	self.spineName = args.spineName or 'effect_320001'
	self.actionName = args.actionName
	self.avatarScale = args.avatarScale

	self:initView()
end
--[[
@override
初始化view
--]]
function SpineLaserBulletView:initView()

	-- 创建spine动画 激光类型动画分三段

	local laserEffectData = SpineCache(SpineCacheName.BATTLE):getAnimationsDataByName(self.spineName)

	------------ 激光尾 附加在施法者身上的效果 可以不存在 ------------
	local laserEnd = nil
	if nil ~= laserEffectData[self.actionName .. sp.LaserAnimationName.laserEnd] then
		-- 存在 创建激光尾
		laserEnd = SpineCache(SpineCacheName.BATTLE):createWithName(self.spineName)
	end
	------------ 激光尾 附加在施法者身上的效果 可以不存在 ------------

	------------ 激光束 此段必须存在 激光特效本体 ------------
	local avatar = SpineCache(SpineCacheName.BATTLE):createWithName(self.spineName)
	avatar:update(0)
	local viewBox = avatar:getBorderBox(sp.CustomName.VIEW_BOX)
	local laserOriSize = cc.size(viewBox.width, viewBox.height)
	------------ 激光束 此段必须存在 激光特效本体 ------------

	------------ 激光头 附加在受法者身上的效果 可以不存在 ------------
	local laserHead = nil
	if nil ~= laserEffectData[self.actionName .. sp.LaserAnimationName.laserHead] then
		-- 存在 创建激光尾
		laserHead = SpineCache(SpineCacheName.BATTLE):createWithName(self.spineName)
	end
	------------ 激光头 附加在受法者身上的效果 可以不存在 ------------

	-- 处理view
	self:setContentSize(laserOriSize)
	self:setAnchorPoint(0, 0.5)

	if nil ~= laserEnd then
		laserEnd:setPosition(cc.p(0, laserOriSize.height * 0.5))
		self:addChild(laserEnd)
	end

	avatar:setPosition(cc.p(0, laserOriSize.height * 0.5))
	self:addChild(avatar)

	if nil ~= laserHead then
		laserHead:setVisible(false)
	end

	self.viewData.avatar = avatar
	self.viewData.laserEnd = laserEnd
	self.viewData.laserHead = laserHead
	self.viewData.laserOriSize = laserOriSize

	-- self:setBackgroundColor(cc.c4b(200, 200, 200, 128))

end
--[[
@override
view死亡
--]]
function SpineLaserBulletView:die()
	-- 隐藏 激光尾 激光束 加在本node上的元素 
	self:setVisible(false)
	-- 隐藏 激光头 不是加在本node上的元素
	self.viewData.laserHead:setVisible(false)
end
--[[
@override
销毁view
--]]
function SpineLaserBulletView:destroy()
	-- 销毁 激光头 不是加在本node上的元素
	self.viewData.laserHead:removeFromParent()
	-- 销毁 激光尾 激光束 加在本node上的元素 
	self:runAction(cc.RemoveSelf:create())
end

return SpineLaserBulletView
