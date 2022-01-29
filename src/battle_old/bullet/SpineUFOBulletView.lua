--[[
带spine动画的子弹view 投掷物
@params{
	spineName string 缓存的spine动画名
	avatarScale number 动画缩放
}
--]]
local SpineBaseBulletView = __Require('battle.bullet.SpineBaseBulletView')
local SpineUFOBulletView = class('SpineUFOBulletView', SpineBaseBulletView)

--[[
@override
初始化view
--]]
function SpineUFOBulletView:initView()

	-- 创建spine动画
	local avatar = SpineCache(SpineCacheName.BATTLE):createWithName(self.spineName)
	avatar:setScale(self:getAvatarScale())
	avatar:update(0)

	-- 初始化朝向 全部朝向右
	local sign = (true == self.spineTowards) and 1 or -1
	avatar:setScaleX(sign * math.abs(avatar:getScaleX()))

	-- local viewSize = avatar:getBoundingBox()
	-- dump(viewSize)
	local viewSize = cc.size(0, 0)
	self:setContentSize(viewSize)
	self:setAnchorPoint(cc.p(0.5, 0.5))
	avatar:setPosition(cc.p(viewSize.width * 0.5, viewSize.height * 0.5))
	self:addChild(avatar)

	-- ## debug ## -- 
	-- local collisionBox = avatar:getBorderBox('collisionBox')
	-- local layer = display.newLayer(collisionBox.x, collisionBox.y, {size = cc.size(collisionBox.width, collisionBox.height), color = '#7c7c7c'})
	-- layer:setOpacity(128)
	-- self:addChild(layer, -1)
	-- ## debug ## --

	-- self:setBackgroundColor(cc.c4b(100, 200, 100, 128))

	self.viewData.avatar = avatar

end

return SpineUFOBulletView
