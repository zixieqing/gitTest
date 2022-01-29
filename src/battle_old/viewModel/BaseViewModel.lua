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
	self.position = {x = 0, y = 0}
	-- 朝向
	self.towards = BattleObjTowards.FORWARD

	-- 死亡标志位
	self.isDie = false


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
	BMediator:GetBData():addAObjViewModel(self, self:GetLogicOwnerTag())
end
--[[
杀死展示层模型
--]]
function BaseViewModel:Kill()
	self:SetDie(true)
	BMediator:GetBData():removeAObjViewModel(self, self:GetLogicOwnerTag())
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
------------ logic相关 ------------
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
	return self.position
end
--[[
设置坐标
@params p cc.p
--]]
function BaseViewModel:SetPosition(p)
	self.position = p
end
--[[
获取x坐标
@return _ number
--]]
function BaseViewModel:GetPositionX()
	return self.position.x
end
--[[
设置x坐标
@params x number
--]]
function BaseViewModel:SetPositionX(x)
	self.position.x = x
end
--[[
获取y坐标
@return _ number
--]]
function BaseViewModel:GetPositionY()
	return self.position.y 
end
--[[
设置y坐标
@params y number
--]]
function BaseViewModel:SetPositionY(y)
	self.position.y = y
end
--[[
获取朝向
@return _ BattleObjTowards 朝向
--]]
function BaseViewModel:GetTowards()
	return self.towards
end
--[[
设置朝向
@params towards BattleObjTowards 朝向
--]]
function BaseViewModel:SetTowards(towards)
	self.towards = towards
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
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- override cocos2dx begin --
---------------------------------------------------

---------------------------------------------------
-- override cocos2dx end --
---------------------------------------------------

return BaseViewModel
