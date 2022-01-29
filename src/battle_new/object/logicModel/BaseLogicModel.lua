--[[
逻辑层模型基类
@params ObjectLogicModelConstructorStruct 构造数据
--]]
local BaseLogicModel = class('BaseLogicModel')

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseLogicModel:ctor( ... )
	local args = unpack({...})

	self.logicInfo = args

	self:Init()
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化
--]]
function BaseLogicModel:Init()
	self:InitValue()
end
--[[
初始化数值
--]]
function BaseLogicModel:InitValue()
	self:InitInnateProperty()
	self:InitUnitProperty()
end
--[[
初始化固有属性
--]]
function BaseLogicModel:InitInnateProperty()
	self.viewModel = nil
end
--[[
初始化特有属性
--]]
function BaseLogicModel:InitUnitProperty()

end
--[[
初始化展示层模型
--]]
function BaseLogicModel:InitViewModel()

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- state begin --
---------------------------------------------------
--[[
是否被暂停
@return _ bool
--]]
function BaseLogicModel:IsPause()
	return false
end
--[[
暂停
--]]
function BaseLogicModel:PauseLogic()

end
--[[
恢复物体
--]]
function BaseLogicModel:ResumeLogic()
	
end
--[[
内部判断物体是否还存活
@return _ bool 是否存活
--]]
function BaseLogicModel:IsAlive()
	return true
end
--[[
销毁
--]]
function BaseLogicModel:Destroy()
	
end
---------------------------------------------------
-- state end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
主循环逻辑
--]]
function BaseLogicModel:Update(dt)

end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- base info get set begin --
---------------------------------------------------
--[[
获取唯一标识tag
@return _ int
--]]
function BaseLogicModel:GetOTag()
	return self.logicInfo.idInfo.tag
end
--[[
获取战斗元素类型
return _ BattleElementType
--]]
function BaseLogicModel:GetOBattleElementType()
	return self.logicInfo.idInfo.elementType
end
--[[
获取id信息
@return _ ObjectIdStruct
--]]
function BaseLogicModel:GetIdInfo()
	return self.logicInfo.idInfo
end
--[[
获取物体特征信息
@return _ ObjectConstructorStruct
--]]
function BaseLogicModel:GetObjInfo()
	return self.logicInfo.objInfo
end
--[[
获取逻辑层物体与配表关联的id
--]]
function BaseLogicModel:GetObjectConfigId()
	return nil
end
--[[
获取逻辑层物体关联的配表信息
@return _ table
--]]
function BaseLogicModel:GetObjectConfig()
	return nil
end
--[[
获取敌友性 是否是敌军
@params o bool 是否获取初始敌友性
@return _ bool 是否是敌军
--]]
function BaseLogicModel:IsEnemy(o)
	return false
end
--[[
获取物体名字
--]]
function BaseLogicModel:GetObjectName()
	return 'BaseLogicModel_No_Name'
end
---------------------------------------------------
-- base info get set end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
展示层模型
--]]
function BaseLogicModel:GetViewModel()
	return self.viewModel
end
function BaseLogicModel:SetViewModel(viewModel)
	self.viewModel = viewModel
end
--[[
获取展示层tag
--]]
function BaseLogicModel:GetViewModelTag()
	if nil ~= self:GetViewModel() then
		return self:GetViewModel():GetViewModelTag()
	end
	return nil
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseLogicModel
