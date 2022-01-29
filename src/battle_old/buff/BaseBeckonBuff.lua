--[[
召唤类型基类 此类型为特殊buff 不走basebuff逻辑
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local BaseBeckonBuff = class('BaseBeckonBuff', BaseBuff)

------------ import ------------
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
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
	self.beckonObjIds = self.buffInfo.value
	-- 初始化施法者敌我性 召唤物敌我性与之保持一致
	self.oriIsEnemy = true
	local caster = self:GetBuffCaster()
	if nil ~= caster then
		self.oriIsEnemy = caster:isEnemy(true)
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

	local casterLocation = caster:getLocation()

	local x = 0
	local y = 0
	local r = 0
	local c = 0
	local randomPos = nil
	local oid = 0
	local cardConf = nil

	for i,v in ipairs(self.beckonObjIds) do
		if BMediator:CanCreateBeckonFromBuff() then

			oid = checkint(v)
			cardConf = CardUtils.GetCardConfig(oid)

			-- 创建坐标信息
			randomPos = cc.p(
				BMediator:GetBConf().BATTLE_AREA.x + BMediator:GetBConf().BATTLE_AREA.width - 100,
				BMediator:GetBConf().BATTLE_AREA.y + BMediator:GetRandomManager():GetRandomInt(BMediator:GetBConf().BATTLE_AREA.height)
			)

			x = randomPos.x
			y = randomPos.y
			local cellInfo = BMediator:GetRowColByPos(randomPos)
			r = cellInfo.r
			c = cellInfo.c
			local location = ObjectLocation.New(x, y, r, c)

			-- 创建怪物属性信息
			local objProperty = __Require('battle.object.MonsterProperty').new(MonsterPropertyConstructStruct.New(
				oid,
				caster:getObjectLevel(),
				1,
				1,
				ObjPFixedAttrStruct.New(),
				BMediator:GetBData():getBattleConstructData().enemyFormation.propertyAttr,
				location
			))

			local objFeature = BattleUtils.GetObjFeatureByCareer(checkint(cardConf.career))
			local skinId = CardUtils.GetCardSkinId(oid)

			local objInfo = ObjectConstructorStruct.New(
				oid, location, i, objFeature, checkint(cardConf.career), self.oriIsEnemy,
				objProperty, nil, ArtifactTalentConstructorStruct.New(oid, nil), nil, false, nil,
				skinId, checknumber(cardConf.scale), checkint(cardConf.defaultLayer or 0),
				nil
			)

			local tagInfo = BMediator:GetBData():getBeckonObjTagInfo()

			local o = BMediator:GetABeckonObj(objInfo, tagInfo, self:GetBuffCasterTag(), self.buffInfo.qteTapTime)
			BMediator:GetBattleRoot():addChild(o.view.viewComponent)
			o:awake()

			-- 设置一次当前波数
			o:setObjectWave(caster:getObjectWave())

			BMediator:SendObjEvent(ObjectEvent.OBJECT_CREATED, {tag = o:getOTag()})

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

return BaseBeckonBuff
