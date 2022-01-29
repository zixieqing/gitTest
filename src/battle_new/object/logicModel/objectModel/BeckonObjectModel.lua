--[[
召唤add物体的基类
--]]
local CardObjectModel = __Require('battle.object.logicModel.objectModel.CardObjectModel')
local BeckonObjectModel = class('BeckonObjectModel', CardObjectModel)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BeckonObjectModel:ctor( ... )
	CardObjectModel.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化特有属性
--]]
function BeckonObjectModel:InitUnitProperty()
	CardObjectModel.InitUnitProperty(self)

	-- 召唤者tag
	self.beckonerTag = 0
	-- qte 点击次数
	self.qteTapTime = 0
end
--[[
@override
初始化展示层模型
--]]
function BeckonObjectModel:InitViewModel()
	CardObjectModel.InitViewModel(self)

	-- /***********************************************************************************************************************************\
	--  * 这里根据坐标强刷一次朝向 而不是根据敌友性强刷 避免因为某些讨巧的配置导致敌友性为友军
	-- \***********************************************************************************************************************************/
	local battleArea = G_BattleLogicMgr:GetBConf().BATTLE_AREA
	local battleMiddleX = (battleArea.x + battleArea.width) * 0.5
	if battleMiddleX < self:GetLocation().po.x then
		self:SetOrientation(BattleObjTowards.NEGTIVE)
	else
		self:SetOrientation(BattleObjTowards.FORWARD)
	end
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- touch logic begin --
---------------------------------------------------
--[[
被点击事件处理
--]]
function BeckonObjectModel:TouchedHandler()
	self:SetQTETapTime(math.max(0, self:GetQTETapTime() - 1))

	if 0 >= self:GetQTETapTime() then
		-- 点击完毕 物体死亡
		self:DieBegin()
	end
end
---------------------------------------------------
-- touch logic end --
---------------------------------------------------

---------------------------------------------------
-- die logic begin --
---------------------------------------------------
--[[
@override
判断物体是否满足死亡条件
@return result bool 死亡
--]]
function BeckonObjectModel:CanDie()
	return false
end
--[[
杀死自己
@params nature bool 是否是自然死亡 自然死亡不计入传给服务器的死亡列表
--]]
function BeckonObjectModel:KillSelf(nature)
	-- 打断当前动作
	self:BreakCurrentAction()

	-- 设置状态
	self:SetState(OState.DIE)

	-- 停掉除去动画以外所有的handler
	self:UnregistObjectEventHandler()

	-- 广播对象死亡事件
	G_BattleLogicMgr:SendObjEvent(
		ObjectEvent.OBJECT_DIE,
		{
			tag = self:GetOTag(), cardId = self:GetObjectConfigId(), isEnemy = self:IsEnemy(true)
		}
	)

	-- 清除所有qte
	for i = #self.qteBuffs.idx, 1, -1 do
		self.qteBuffs.idx[i]:Die()
	end

	-- 清除所有buff
	self:ClearBuff()

	-- 操作data数据
	G_BattleLogicMgr:GetBData():AddABeckonModelToDust(self, nature)
	G_BattleLogicMgr:GetBData():RemoveABeckonObjLogicModel(self)

	-- 清空能量
	self:AddEnergy(-self:GetEnergy())

	if nature then
		if nil ~= self:GetViewModel() then
			self:GetViewModel():ClearSpineTracks()
			self:GetViewModel():Kill()
		end
	end

	-- 变回原色
	self.tintDriver:OnActionBreak()
end
---------------------------------------------------
-- die logic end --
---------------------------------------------------

---------------------------------------------------
-- revive logic begin --
---------------------------------------------------
--[[
@override
复活 不实现该逻辑
@params reviveHpPercent number 复活时的血量百分比
@params reviveEnergyPercent number 复活时的能量百分比
--]]
function BeckonObjectModel:Revive(reviveHpPercent, reviveEnergyPercent)
	print('!!!!!\n 		waring beckon object can not be revive\n!!!!!')
end
---------------------------------------------------
-- revive logic end --
---------------------------------------------------

---------------------------------------------------
-- obj shift logic begin --
---------------------------------------------------
--[[
物体进入下一波的逻辑
@params nextWave int 下一波序号
--]]
function BeckonObjectModel:EnterNextWave(nextWave)
	self:KillSelf(false)
end
---------------------------------------------------
-- obj shift logic end --
---------------------------------------------------

---------------------------------------------------
-- event handler begin --
---------------------------------------------------
--[[
@override
死亡事件监听
@params ... 
	args table passed args
--]]
function BeckonObjectModel:ObjectEventDieHandler( ... )
	local args = unpack({...})
	local targetTag = args.tag

	if targetTag == self:GetBeckonerTag() then
		self:DieBegin()
		return
	end

	CardObjectModel.ObjectEventDieHandler(self, ...)
end
---------------------------------------------------
-- event handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
qte物体点击次数
--]]
function BeckonObjectModel:GetQTETapTime()
	return self.qteTapTime
end
function BeckonObjectModel:SetQTETapTime(time)
	self.qteTapTime = time
end
--[[
召唤者tag
--]]
function BeckonObjectModel:GetBeckonerTag()
	return self.beckonerTag
end
function BeckonObjectModel:SetBeckonerTag(tag)
	self.beckonerTag = tag
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BeckonObjectModel
