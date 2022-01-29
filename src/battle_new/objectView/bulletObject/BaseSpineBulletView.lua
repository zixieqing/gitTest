--[[
带spine动画的子弹view基类
@params t table {
	tag int obj view tag 此tag与战斗物体逻辑层tag对应
	viewInfo BulletViewConstructorStruct 渲染层构造数据
}
--]]
local BaseBulletView = __Require('battle.objectView.bulletObject.BaseBulletView')
local BaseSpineBulletView = class('BaseSpineBulletView', BaseBulletView)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
@override
constructor
--]]
function BaseSpineBulletView:ctor( ... )
	BaseBulletView.ctor(self, ...)
end

---------------------------------------------------
-- init view begin --
---------------------------------------------------
--[[
@override
初始化view
--]]
function BaseSpineBulletView:InitView()

	local viewSize = cc.size(20, 20)
	self:setContentSize(viewSize)
	self:setAnchorPoint(cc.p(0.5, 0))

	local spineCacheName = BattleUtils.GetEffectAniNameById(self:GetEffectId())

	-- 创建spine动画
	local avatar = SpineCache(SpineCacheName.BATTLE):createWithName(spineCacheName)
	if avatar then
		avatar:setScale(self:GetAvatarScale())
		avatar:update(0)
		
		-- 初始化朝向 全部朝向右
		local sign = (true == self:GetOrientation()) and 1 or -1
		avatar:setScaleX(sign * math.abs(avatar:getScaleX()))
		avatar:setPosition(cc.p(viewSize.width * 0.5, 0))
		self:addChild(avatar)
	else
		if checkint(DEBUG) > 0 then
			error(string.format('[battle] can not create spine %s', tostring(spineCacheName)))
		end
	end

	-- ## debug ## -- 
	-- local collisionBox = avatar:getBorderBox('collisionBox')
	-- local layer = display.newLayer(collisionBox.x, collisionBox.y, {size = cc.size(collisionBox.width, collisionBox.height), color = '#7c7c7c'})
	-- layer:setOpacity(128)
	-- self:addChild(layer, -1)
	-- ## debug ## --

	-- self:setBackgroundColor(cc.c4b(100, 200, 100, 128))

	self.avatar = avatar

end
---------------------------------------------------
-- init view begin --
---------------------------------------------------

---------------------------------------------------
-- pause control begin --
---------------------------------------------------
--[[
暂停
--]]
function BaseSpineBulletView:PauseView()
	
end
--[[
继续
--]]
function BaseSpineBulletView:ResumeView()
	
end
---------------------------------------------------
-- pause control end --
---------------------------------------------------

return BaseSpineBulletView
