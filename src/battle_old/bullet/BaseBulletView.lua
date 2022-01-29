--[[
子弹view基类
--]]
local BaseBulletView = class('BaseBulletView', function ()
	local node = CLayout:create()
	node.name = 'battle.bullet.BaseBulletView'
	node:enableNodeEvents()
	return node
end)
--[[
constructor
--]]
function BaseBulletView:ctor( ... )
	local args = unpack({...})

	self.viewData = {}
	self.avatarScale = args.avatarScale

	self:initView()
end
---------------------------------------------------
-- init view begin --
---------------------------------------------------
--[[
初始化view
--]]
function BaseBulletView:initView()
	
	local function CreateView()

		self:setContentSize(cc.size(0, 0))

		return {

		}
	end

	xTry(function ()	
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

end
---------------------------------------------------
-- init view end --
---------------------------------------------------

---------------------------------------------------
-- view controller begin --
---------------------------------------------------
--[[
view死亡
--]]
function BaseBulletView:die()
	self:setVisible(false)
end
--[[
销毁view
--]]
function BaseBulletView:destroy()
	self:runAction(cc.RemoveSelf:create())
	-- self:setVisible(false)
end
---------------------------------------------------
-- view controller end --
---------------------------------------------------


return BaseBulletView
