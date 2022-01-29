--[[
带spine动画的子弹view基类
@params{
	spineName string 缓存的spine动画名
	avatarScale number 动画缩放
}
--]]
local BaseBulletView = __Require('battle.bullet.BaseBulletView')
local SpineBaseBulletView = class('SpineBaseBulletView', BaseBulletView)
--[[
@override
constructor
--]]
function SpineBaseBulletView:ctor( ... )
	local args = unpack({...})

	self.viewData = {}
	self.spineName = args.spineName or 'effect_200001'
	self.avatarScale = args.avatarScale
	self.spineTowards = args.spineTowards

	self:initView()
end
--[[
@override
初始化view
--]]
function SpineBaseBulletView:initView()

	-- 创建spine动画
	local avatar = SpineCache(SpineCacheName.BATTLE):createWithName(self.spineName)
	avatar:setScale(self:getAvatarScale())
	avatar:update(0)

	-- 初始化朝向 全部朝向右
	local sign = (true == self.spineTowards) and 1 or -1
	avatar:setScaleX(sign * math.abs(avatar:getScaleX()))

	-- local viewSize = avatar:getBoundingBox()
	-- dump(viewSize)
	local viewSize = cc.size(20, 20)
	self:setContentSize(viewSize)
	self:setAnchorPoint(cc.p(0.5, 0))
	avatar:setPosition(cc.p(viewSize.width * 0.5, 0))
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
---------------------------------------------------
-- view controller begin --
---------------------------------------------------
--[[
获取子弹avatar缩放比
--]]
function SpineBaseBulletView:getAvatarScale()
	return self.avatarScale
end
---------------------------------------------------
-- view controller end --
---------------------------------------------------


return SpineBaseBulletView
