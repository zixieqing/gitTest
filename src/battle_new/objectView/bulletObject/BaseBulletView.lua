--[[
子弹view基类
@params t table {
	tag int obj view tag 此tag与战斗物体逻辑层tag对应
	viewInfo BulletViewConstructorStruct 渲染层构造数据
}
--]]
local BaseBulletView = class('BaseBulletView', function ()
	local node = CLayout:create()
	node.name = 'battle.bullet.BaseBulletView'
	node:enableNodeEvents()
	return node
end)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseBulletView:ctor( ... )
	local args = unpack({...})

	self.tag = args.tag
	self.viewInfo = args.viewInfo

	self.viewData = {}
	self.avatar = nil

	self:InitView()

	self:setVisible(false)
end
---------------------------------------------------
-- init view begin --
---------------------------------------------------
--[[
初始化view
--]]
function BaseBulletView:InitView()
	
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
唤醒view
--]]
function BaseBulletView:Awake()
	self:setVisible(true)
end
--[[
view死亡
--]]
function BaseBulletView:Die()
	self:setVisible(false)
	self:DieEnd()
end
--[[
view 死亡结束
--]]
function BaseBulletView:DieEnd()
	self:Destroy()
end
--[[
销毁view
--]]
function BaseBulletView:Destroy()
	self:setVisible(false)
	self:runAction(cc.RemoveSelf:create())
end
--[[
根据effect id移除附加特效
@params effectId int 特效id
--]]
function BaseBulletView:RemoveAttachEffectByEffectId(effectId)
	
end
---------------------------------------------------
-- view controller end --
---------------------------------------------------

---------------------------------------------------
-- pause control begin --
---------------------------------------------------
--[[
暂停
--]]
function BaseBulletView:PauseView()

end
--[[
继续
--]]
function BaseBulletView:ResumeView()
	
end
---------------------------------------------------
-- pause control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取子弹的tag 该tag对应逻辑层的tag
--]]
function BaseBulletView:GetVTag()
	return self.tag
end
--[[
获取构造的view info
--]]
function BaseBulletView:GetViewInfo()
	return self.viewInfo
end
--[[
获取子弹的特效id
--]]
function BaseBulletView:GetEffectId()
	return self:GetViewInfo().effectId
end
--[[
获取子弹avatar缩放比
--]]
function BaseBulletView:GetAvatarScale()
	return self:GetViewInfo().bulletScale
end
--[[
获取朝向
@return _ bool 是否朝向右
--]]
function BaseBulletView:GetOrientation()
	return self:GetViewInfo().towards
end
--[[
获取avatar
--]]
function BaseBulletView:GetAvatar()
	return self.avatar
end
---------------------------------------------------
-- get set end --
---------------------------------------------------


return BaseBulletView
