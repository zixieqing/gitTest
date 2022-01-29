--[[
持续性效果子弹 大雾风沙类效果 渲染层模型
@params t table {
	tag int obj view tag 此tag与战斗物体逻辑层tag对应
	viewInfo BulletViewConstructorStruct 渲染层构造数据
}
--]]
local BaseSpineBulletView = __Require('battle.objectView.bulletObject.BaseSpineBulletView')
local SpinePersistenceBulletView = class('SpinePersistenceBulletView', BaseSpineBulletView)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
@override
constructor
--]]
function SpinePersistenceBulletView:ctor( ... )
	BaseSpineBulletView.ctor(self, ...)
end

---------------------------------------------------
-- view controller begin --
---------------------------------------------------
--[[
唤醒view
--]]
function SpinePersistenceBulletView:Awake()
	-- 初始化动画状态
	self:setOpacity(0)

	local appearActionSeq = cc.Sequence:create(
		cc.Show:create(),
		cc.FadeTo:create(0.5, 255)
	)

	self:runAction(appearActionSeq)
end
--[[
view死亡
--]]
function SpinePersistenceBulletView:Die()
	local disappearActionSeq = cc.Sequence:create(
		cc.FadeTo:create(0.5, 0),
		cc.Hide:create(),
		cc.CallFunc:create(function ()
			self:DieEnd()
		end)
	)

	self:runAction(disappearActionSeq)
end
--[[
销毁view
--]]
function SpinePersistenceBulletView:Destroy()
	self:setVisible(false)
	self:runAction(cc.RemoveSelf:create())
end
---------------------------------------------------
-- view controller end --
---------------------------------------------------

return SpinePersistenceBulletView
