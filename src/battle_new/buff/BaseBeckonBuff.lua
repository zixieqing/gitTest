--[[
召唤类型基类 此类型为特殊buff 不走basebuff逻辑
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local BaseBeckonBuff = class('BaseBeckonBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化
--]]
function BaseBeckonBuff:Init()
	self:InitValue()
end
--[[
@override
初始化数值
--]]
function BaseBeckonBuff:InitValue()
	-- 初始化施法者敌我性 召唤物敌我性与之保持一致
	self.oriIsEnemy = true
	local caster = self:GetBuffCaster()
	if nil ~= caster then
		self.oriIsEnemy = caster:IsEnemy(true)
	end
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
造成效果
--]]
function BaseBeckonBuff:CauseEffect()
	local caster = self:GetBuffCaster()
	if not caster then return end

	local casterLocation = caster:GetLocation()
	local isEnemy = self:IsCasterEnemy()

	local bdata = G_BattleLogicMgr:GetBData()

	local x = 0
	local y = 0
	local r = 0
	local c = 0
	local cardId = nil
	local cardConfig = nil

	for _, cardId_ in ipairs(self:GetBeckonIds()) do
		if G_BattleLogicMgr:CanCreateBeckonFromBuff() then

			cardId = checkint(cardId_)
			cardConfig = CardUtils.GetCardConfig(cardId)

			-- 创建一个随机的初始坐标
			local randomPos = cc.p(
				G_BattleLogicMgr:GetBConf().BATTLE_AREA.x + G_BattleLogicMgr:GetBConf().BATTLE_AREA.width - 100,
				G_BattleLogicMgr:GetBConf().BATTLE_AREA.y + G_BattleLogicMgr:GetRandomManager():GetRandomInt(G_BattleLogicMgr:GetBConf().BATTLE_AREA.height)
			)

			x = randomPos.x
			y = randomPos.y
			local cellInfo = G_BattleLogicMgr:GetRowColByPos(randomPos)
			r = cellInfo.r
			c = cellInfo.c
			local location = ObjectLocation.New(x, y, r, c)

			-- 创建卡牌属性信息
			local objProperty = __Require('battle.object.ObjProperty').new(CardPropertyConstructStruct.New(
				cardId,
				caster:GetObjectLevel(),
				1,
				1,
				nil,
				nil,
				nil,
				nil,
				ObjPFixedAttrStruct.New(),
				G_BattleLogicMgr:GetFormationPropertyAttr(isEnemy),
				location
			))

			local objFeature = BattleUtils.GetObjFeatureByCareer(checkint(cardConfig.career))
			local skinId = CardUtils.GetCardSkinId(cardId)

			local objInfo = ObjectConstructorStruct.New(
				cardId, location, i, objFeature, checkint(cardConfig.career), isEnemy,
				objProperty, nil, ArtifactTalentConstructorStruct.New(cardId, nil), nil, false, nil,
				skinId, checknumber(cardConfig.scale), checkint(cardConfig.defaultLayer or 0),
				nil
			)

			local tag = bdata:GetTagByTagType(isEnemy and BattleTags.BT_BECKON or BattleTags.BT_FRIEND)
			local o = G_BattleLogicMgr:GetABeckonObj(tag, objInfo)

			-- 设置一次当前波数
			o:SetObjectWave(caster:GetObjectWave())
			-- 设置一次队伍序号
			o:SetObjectTeamIndex(caster:GetObjectTeamIndex())

			---------- 设置一些召唤物的外部变量 ----------
			-- 召唤者
			o:SetBeckonerTag(self:GetBuffCasterTag())
			-- 点击次数
			o:SetQTETapTime(self:GetBuffInfo().qteTapTime)
			---------- 设置一些召唤物的外部变量 ----------

			-- 发送创建物体的事件
			G_BattleLogicMgr:SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = tag})

			---------- view ----------
			-- 创建view
			G_BattleLogicMgr:RenderCreateABeckonObjectView(o:GetViewModelTag(), o:GetOTag(), objInfo)
			-- 刷新view
			o:InitObjectRender()
			---------- view ----------

			-- 直接唤醒物体
			o:AwakeObject()

		else

			break

		end
	end

	return 0
end
--[[
@override
主逻辑更新
--]]
function BaseBeckonBuff:OnBuffUpdateEnter(dt)

end
--[[
@override
恢复效果
@params casterTag int 施法者tag
@return result number 恢复效果以后的结果
--]]
function BaseBeckonBuff:OnRecoverEffectEnter(casterTag)
	return 0
end
--[[
@override
添加buff对应的展示
--]]
function BaseBeckonBuff:AddView()
	
end
--[[
@override
移除buff对应的展示
--]]
function BaseBeckonBuff:RemoveView()
	
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取召唤add的id集合
@return _ list
--]]
function BaseBeckonBuff:GetBeckonIds()
	return self.buffInfo.value
end
--[[
获取施法者的敌友性
@return _ bool 是否是敌人
--]]
function BaseBeckonBuff:IsCasterEnemy()
	return self.oriIsEnemy
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseBeckonBuff
