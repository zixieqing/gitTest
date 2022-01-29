--[[
描述通用展示层模型的基类
@params viewModelInfo ObjectViewModelConstructorStruct 卡牌展示层构造数据
--]]
local BaseViewModel = class('BaseViewModel')

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseViewModel:ctor( ... )
	local args = unpack({...})
	
	self:Init()
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化逻辑
--]]
function BaseViewModel:Init()
	self:InitValue()
end
--[[
初始化数值
--]]
function BaseViewModel:InitValue()
	self:InitInnnateValue()
	self:InitUnitValue()
end
--[[
初始化固有属性
--]]
function BaseViewModel:InitInnnateValue()
	-- 坐标
	self.v_position = {x = 0, y = 0}
	-- 朝向
	self.v_towards = BattleObjTowards.FORWARD
	-- 旋转
	self.v_rotate = 0

	-- 死亡标志位
	self.isDie = false

	-- 动画缩放
	self.animationTimeScale = 1


	-- 回调函数信息
	self.eventListeners = {}
end
--[[
初始化特有属性
--]]
function BaseViewModel:InitUnitValue()
	
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
注册事件回调
@params eventType 事件类型
@params callback function 回调函数
--]]
function BaseViewModel:RegistEventListener(eventType, callback)
	if nil == self.eventListeners[eventType] then
		self.eventListeners[eventType] = {}
	end
	table.insert(self.eventListeners[eventType], callback)
end
--[[
注销事件回调
@params eventType 事件类型
--]]
function BaseViewModel:UnregistEventListener(eventType)
	self.eventListeners[eventType] = nil
end
--[[
发送事件
@params eventType 事件类型
@params ... 变长参数
--]]
function BaseViewModel:SendEvent(eventType, ...)
	-- print('\n\n-----------------------------\nhere get spine event\n-----------------------------\n', eventType, ...)
	-- dump(...)
	-- print('\n\n')
	if nil ~= self.eventListeners[eventType] then
		for _, cb in ipairs(self.eventListeners[eventType]) do
			cb(eventType, ...)
		end
	end
end
--[[
逻辑更新
--]]
function BaseViewModel:Update(dt)
	
end
--[[
唤醒展示层模型
--]]
function BaseViewModel:Awake()
	self:SetDie(false)
	G_BattleLogicMgr:GetBData():AddAObjViewModel(self, self:GetViewModelTag())
end
--[[
杀死展示层模型
--]]
function BaseViewModel:Kill()
	self:SetDie(true)
	G_BattleLogicMgr:GetBData():RemoveAObjViewModel(self, self:GetViewModelTag())
end
--[[
替换动画内容
--]]
function BaseViewModel:InnerChangeViewModel()

end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
------------ logic相关 ------------
--[[
获取展示层tag
--]]
function BaseViewModel:GetViewModelTag()
	return nil
end
--[[
获取当前展示层对应的逻辑层模型
@return _ BaseObject
--]]
function BaseViewModel:GetLogicOwner()
	return nil
end
--[[
获取当前展示层对应的逻辑层模型tag
@return _ int tag
--]]
function BaseViewModel:GetLogicOwnerTag()
	return nil
end
------------ transform相关 ------------
--[[
获取坐标
@return _ cc.p
--]]
function BaseViewModel:GetPosition()
	return self.v_position
end
--[[
设置坐标
@params p cc.p
--]]
function BaseViewModel:SetPosition(p)
	self:SetPositionX(p.x)
	self:SetPositionY(p.y)
end
--[[
获取x坐标
@return _ number
--]]
function BaseViewModel:GetPositionX()
	return self.v_position.x
end
--[[
设置x坐标
@params x number
--]]
function BaseViewModel:SetPositionX(x)
	self.v_position.x = x
end
--[[
获取y坐标
@return _ number
--]]
function BaseViewModel:GetPositionY()
	return self.v_position.y 
end
--[[
设置y坐标
@params y number
--]]
function BaseViewModel:SetPositionY(y)
	self.v_position.y = y
end
--[[
获取朝向
@return _ BattleObjTowards 朝向
--]]
function BaseViewModel:GetTowards()
	return self.v_towards
end
--[[
设置朝向
@params towards BattleObjTowards 朝向
--]]
function BaseViewModel:SetTowards(towards)
	self.v_towards = towards
end
--[[
设置旋转
@params angle number 角度
--]]
function BaseViewModel:SetRotate(angle)
	self.v_rotate = angle
end
--[[
获取角度
@return _ number 角度
--]]
function BaseViewModel:GetRotate()
	return self.v_rotate
end
--[[
是否死亡
--]]
function BaseViewModel:IsDie()
	return self.isDie
end
function BaseViewModel:SetDie(die)
	self.isDie = die
end
--[[
根据动作名判断是否存在该动作信息
@params animationName string 动作名
--]]
function BaseViewModel:HasAnimationByName(animationName)
	return false
end
--[[
获取动画的速度缩放
@return _ number 速度缩放
--]]
function BaseViewModel:GetAnimationTimeScale()
	return self.animationTimeScale
end
--[[
设置动画的速度缩放
@params timeScale number
--]]
function BaseViewModel:SetAnimationTimeScale(timeScale)
	self.animationTimeScale = timeScale
end
--[[
获取碰撞框信息
@return box cc.rect 边界框信息
--]]
function BaseViewModel:GetStaticCollisionBox()
	return nil
end
--[[
获取ui框信息
@return box cc.rect 边界框信息
--]]
function BaseViewModel:GetStaticViewBox()
	return nil
end
--[[
根据骨骼名获取骨骼的信息
@params boneName string
@return _ table
--]]
function BaseViewModel:GetBoneDataByBoneName(boneName)
	return nil
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- animation begin --
---------------------------------------------------
--[[
获取当前正在运行的动画名字
--]]
function BaseViewModel:GetRunningAnimationName()
	return nil
end
---------------------------------------------------
-- animation end --
---------------------------------------------------

---------------------------------------------------
-- override cocos2dx begin --
---------------------------------------------------

---------------------------------------------------
-- override cocos2dx end --
---------------------------------------------------

return BaseViewModel
