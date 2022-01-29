--[[
召唤物基类
无法被攻击 逻辑上不被索敌 只能点击杀死
--]]
local BaseObj = __Require('battle.object.CardObject')
local BaseBeckonObj = class('BaseBeckonObj', BaseObj)
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
--[[
@override
constructor
--]]
function BaseBeckonObj:ctor( ... )
	local args = unpack({...})
	self.beckonerTag = args.beckonerTag
	self.qteTapTime = checkint(args.qteTapTime)

	BaseObj.ctor(self, ...)
end
--[[
@override
--]]
function BaseBeckonObj:initView()
	local viewClassName = 'battle.objectView.BeckonView'

	local viewInfo = ObjectViewConstructStruct.New(
		self:getOCardId(),
		self:getOSkinId(),
		self.objInfo.avatarScale,
		BMediator:GetSpineAvatarScale2CardByCardId(self:getOCardId()),
		self:isEnemy(true)
	)
	local view = __Require(viewClassName).new({
		tag = self:getOTag(),
		viewInfo = viewInfo
	})
	
	view:setTouchedSelfCallback(handler(self, self.touchedSelfHandler))
	self.view.viewComponent = view
	self.view.avatar = view:getAvatar()
	self.view.animationsData = self.view.avatar:getAnimationsData()
	self.view.hpBar = view.viewData.hpBar
	self.view.energyBar = view.viewData.energyBar

	self:DoSpineAnimation(false, nil, sp.AnimationName.idle, true)

	-- 初始化朝向
	if self:isEnemy() then
		self:changeOrientation(false)
	else
		self:changeOrientation(true)
	end

	-- 设置血条数值
	self.view.hpBar:setMaxValue(self:getMainProperty():getOriginalHp())
	self.view.hpBar:setValue(self:getMainProperty():getCurrentHp())

	-- 设置能量条数值
	self.view.energyBar:setMaxValue(MAX_ENERGY)
	self.view.energyBar:setValue(self:getEnergy():ObtainVal())

	-- 设置zorder
	self.view.viewComponent:setPosition(self.objInfo.oriLocation.po)
	self:updateLocation()

end
--[[
@override
死亡事件回调
@params evt table
@params ... table {
	tag int died-obj tag
}
--]]
function BaseBeckonObj:objDieEventHandler(...)
	local args = unpack({...})
	local tTag = checkint(args.tag)
	-- 检查光环
	local halo = nil
	for i = #self.halos.idx, 1, -1 do
		halo = self.halos.idx[i]
		if halo:HasHaloOuterPileByCasterTag(tTag) then
			halo:OnRecoverEffectEnter(tTag)
		end
	end
	if nil ~= self.attackDriver:GetAttackTargetTag() and (tTag == checkint(self.attackDriver:GetAttackTargetTag())) then
		self.attackDriver:SetAttackTargetTag(nil)
		if sp.AnimationName.run == self.view.avatar:getCurrent() then
			self:DoSpineAnimation(true, nil, sp.AnimationName.idle, true)
		end
	end
	if tTag == self.beckonerTag then
		-- 召唤者死亡 移除自己
		self:dieBegin()
	end
end
--[[
@override
进入下一波
@params nextWave int 下一波
--]]
function BaseBeckonObj:enterNextWave(nextWave)
	self:killSelf(false)
end
--[[
点击回调
--]]
function BaseBeckonObj:touchedSelfHandler()
	if OState.DIE ~= self:getState() then
		self.qteTapTime = self.qteTapTime - 1
		if self.qteTapTime <= 0 then
			-- 播放弹飞音效
			PlayBattleEffects(AUDIOS.BATTLE.ty_beattack_tanfei.id)
			self:dieBegin()
		end
	end
end
--[[
@override
杀死该对象 处理数据结构
@params nature bool 是否是自然死亡 自然死亡不计入传给服务器的死亡列表
--]]
function BaseBeckonObj:killSelf(nature)
	---------- logic ----------
	-- 设置状态
	self:setState(OState.DIE)
	-- 停掉除spine以外所有handler
	self:unregisterObjEventHandler()
	-- 从存活的索敌对象中移除该物体
	BMediator:GetBData():addADeadBeckonObj(self)
	BMediator:GetBData():removeABeckonObj(self)
	-- 对象死亡 广播事件
	BMediator:SendObjEvent(ObjectEvent.OBJECT_DIE, {tag = self:getOTag(), cardId = self:getOCardId(), isEnemy = self:isEnemy()})
	-- 清除所有qte
	for i = #self.qteBuffs.idx, 1, -1 do
		self.qteBuffs.idx[i]:die()
	end
	-- 清除所有buff
	self:clearBuff()
	
	if nature then
		if nil ~= self:GetViewModel() then
			self:GetViewModel():ClearSpineTracks()
			self:GetViewModel():Kill()
		end
	end
	---------- logic ----------

	---------- view ----------
	-- 变回原色
	self.view.avatar:setColor(cc.c3b(255, 255, 255))
	-- 移除当前hold的ciscene
	if nil ~= self.ciScene then
		self.ciScene:die()
	end
	---------- view ----------
end
--[[
@override
死亡结束
--]]
function BaseBeckonObj:dieEnd()
	BaseObj.dieEnd(self)
end
--[[
@override
复活 不实现该逻辑
@params reviveHpPercent number 复活时的血量百分比
@params reviveEnergyPercent number 复活时的能量百分比
--]]
function BaseBeckonObj:revive(reviveHpPercent, reviveEnergyPercent)
	print('!!!!!\n 		waring beckon object can not be revive\n!!!!!')
end


return BaseBeckonObj
