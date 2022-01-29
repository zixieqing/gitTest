--[[
战斗数据转换工具类 配表 -> struct
--]]
local BattleStructConvertUtils = {}
BSCUtils = BattleStructConvertUtils

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- skillEffectType -> SkillSpineEffectStruct
-- 技能的特效配置数据
---------------------------------------------------
--[[
@params skillId int 技能id 为-1代表攻击
@params config table 配表结构
@params wave int 波数
@params skinId int 卡牌皮肤id（可选）
--]]
function BattleStructConvertUtils.GetSkillSpineEffectStruct(skillId, config, wave, skinId)
	-- 如果传入的非法值 则初始化成默认状态
	if nil == config or nil == config[tostring(skillId)] then

		-- 初始化默认数据结构
		local actionName = sp.AnimationName.attack
		local hurtEffectData = {}
		local attachEffectData = {}

		if ATTACK_2_SKILL_ID ~= skillId then
			-- 技能特效 初始化一次各个buff的默认值
			actionName = BSCUtils.GetSpineAniNameByActionId('1')
			local skillConfig = CommonUtils.GetSkillConf(skillId)
			assert(skillConfig, '\n**************\n cannot find skill conf, skillId : ' .. skillId)

			if skillConfig.type and next(skillConfig.type) then
				for buffType,_ in pairs(skillConfig.type) do
					hurtEffectData[buffType] = {}
					attachEffectData[buffType] = {}
				end
			end
		end

		return SkillSpineEffectStruct.New(
			skillId, nil, nil, actionName,
			nil, nil, nil, nil, nil,
			hurtEffectData, attachEffectData,
			nil, nil, nil
		)

	else

		local effectConfig = config[tostring(skillId)]

		------------ 发射的子弹特效基础信息 ------------
		-- 子弹的类型
		local bulletType = ConfigEffectBulletType.BASE
		-- 子弹的基础类型
		local causeType = ConfigEffectCauseType.BASE
		-- 动作名 动作id为-1时代表攻击动作
		local actionName = BSCUtils.GetSpineAniNameByActionId(effectConfig.actionId)


		-- 子弹特效的id
		local effectId = nil
		-- 子弹特效的动作名
		local effectActionName = BSCUtils.GetSpineAniNameByActionId(effectConfig.effectNo)
		-- 子弹特效的zorder
		local effectZOrder = checkint(effectConfig.effectLayer)
		-- 子弹的缩放
		local effectScale = checknumber(effectConfig.effectScale)
		-- 子弹的相对位置
		local effectPos = cc.p(0.5, 0)
		if 2 == #effectConfig.effectLocation then
			effectPos = cc.p(checknumber(effectConfig.effectLocation[1]), checknumber(effectConfig.effectLocation[2]))
		end

		-- 判断本地文件 是否存在对应的文件 存在则初始化 不存在则保持默认
		-- 修正后的动作名
		local fixedActionName = effectActionName
		-- /***********************************************************************************************************************************\
		--  * 激光类型的命名不同 做出特殊处理
		if ConfigEffectBulletType.SPINE_LASER == checkint(effectConfig.effectType) then
			fixedActionName = fixedActionName .. sp.LaserAnimationName.laserBody
		end
		-- \***********************************************************************************************************************************/

		local skillEffectId = effectConfig.effectId
		if skinId then
			skillEffectId = BRUtils.CheckCardSkillEffectIdBySkinId(skinId, skillEffectId)
		end
		local hasAnimation = BattleUtils.SpineInCache(skillEffectId, SpineType.EFFECT, wave)
			and BattleUtils.SpineHasAnimationByName(skillEffectId, SpineType.EFFECT, fixedActionName)
		if true == hasAnimation then
			bulletType = checkint(effectConfig.effectType)
			causeType = checkint(effectConfig.causeType)
			effectId = skillEffectId
		else
			effectActionName = nil
		end
		------------ 发射的子弹特效基础信息 ------------

		------------ 每个buff的爆点和附加特效 ------------
		-- 爆点效果 击中时显示的效果
		local hurtEffectData = nil
		-- 附加效果 持续时显示的效果
		local attachEffectData = nil

		if ATTACK_2_SKILL_ID == skillId then

			hurtEffectData = HurtEffectStruct.New()
			attachEffectData = AttachEffectStruct.New()

			local econfig = effectConfig.effect
			if nil ~= econfig then

				------------ 被击爆点 ------------
				local hitEffectId = checkint(econfig.hitEffect)
				if 0 ~= hitEffectId and true == BattleUtils.SpineInCache(hitEffectId, SpineType.HURT, wave) then

					-- id
					hurtEffectData.effectId = hitEffectId
					-- zorder
					hurtEffectData.effectZOrder = checkint(econfig.hitEffectLayer)
					-- 相对坐标
					hurtEffectData.effectPos = cc.p(0.5, 0)
					if 2 == #econfig.hitEffectLocation then
						hurtEffectData.effectPos = cc.p(
							checknumber(econfig.hitEffectLocation[1]),
							checknumber(econfig.hitEffectLocation[2])
						)
					end
					-- 爆点音效
					local effectSoundEffectId = BattleUtils.GetFilteredStringBySpace(effectConfig.soundHitEffect)
					if nil ~= effectSoundEffectId then
						hurtEffectData.effectSoundEffectId = tostring(effectConfig.soundHitEffect)
					end
				end
				------------ 被击爆点 ------------

				------------ 附加特效 ------------
				local addEffectId = checkint(econfig.addEffect)
				if 0 ~= addEffectId and BattleUtils.SpineInCache(addEffectId, SpineType.HURT, wave) then

					-- id
					attachEffectData.effectId = addEffectId
					-- zorder
					attachEffectData.effectZOrder = checkint(econfig.addEffectLayer)
					-- 相对坐标
					attachEffectData.effectPos = cc.p(0.5, 0)
					if 2 == #econfig.addEffectLocation then
						attachEffectData.effectPos = cc.p(
							checknumber(econfig.addEffectLocation[1]),
							checknumber(econfig.addEffectLocation[2])
						)
					end
					-- 附加效果音效
					local effectSoundEffectId = BattleUtils.GetFilteredStringBySpace(effectConfig.soundAddEffect)
					if nil ~= effectSoundEffectId then
						attachEffectData.effectSoundEffectId = tostring(effectConfig.soundAddEffect)
					end

				end
				------------ 附加特效 ------------

			end

		else

			local skillConfig = CommonUtils.GetSkillConf(skillId)
			assert(skillConfig, '\n**************\n cannot find skill conf, skillId : ' .. skillId)
			
			-- 技能特效
			hurtEffectData = {}
			attachEffectData = {}

			local econfig = nil

			if skillConfig.type and next(skillConfig.type) then
				for buffType, _ in pairs(skillConfig.type) do
					local hurtEffectData_ = HurtEffectStruct.New()
					local attachEffectData_ = AttachEffectStruct.New()

					econfig = effectConfig.effect[buffType]
					if nil ~= econfig then

						------------ 被击爆点 ------------
						local hitEffectId = checkint(econfig.hitEffect)
						if 0 ~= hitEffectId and true == BattleUtils.SpineInCache(hitEffectId, SpineType.HURT, wave) then

							-- id
							hurtEffectData_.effectId = hitEffectId
							-- zorder
							hurtEffectData_.effectZOrder = checkint(econfig.hitEffectLayer)
							-- 相对坐标
							hurtEffectData_.effectPos = cc.p(0.5, 0)
							if 2 == #econfig.hitEffectLocation then
								hurtEffectData_.effectPos = cc.p(
									checknumber(econfig.hitEffectLocation[1]),
									checknumber(econfig.hitEffectLocation[2])
								)
							end
							-- 爆点音效
							local effectSoundEffectId = BattleUtils.GetFilteredStringBySpace(effectConfig.soundHitEffect)
							if nil ~= effectSoundEffectId then
								hurtEffectData_.effectSoundEffectId = tostring(effectConfig.soundHitEffect)
							end
						end
						------------ 被击爆点 ------------

						------------ 附加特效 ------------
						local addEffectId = checkint(econfig.addEffect)
						if 0 ~= addEffectId and BattleUtils.SpineInCache(addEffectId, SpineType.HURT, wave) then

							-- id
							attachEffectData_.effectId = addEffectId
							-- zorder
							attachEffectData_.effectZOrder = checkint(econfig.addEffectLayer)
							-- 相对坐标
							attachEffectData_.effectPos = cc.p(0.5, 0)
							if 2 == #econfig.addEffectLocation then
								attachEffectData_.effectPos = cc.p(
									checknumber(econfig.addEffectLocation[1]),
									checknumber(econfig.addEffectLocation[2])
								)
							end
							-- 附加效果音效
							local effectSoundEffectId = BattleUtils.GetFilteredStringBySpace(effectConfig.soundAddEffect)
							if nil ~= effectSoundEffectId then
								attachEffectData_.effectSoundEffectId = tostring(effectConfig.soundAddEffect)
							end

						end
						------------ 附加特效 ------------

						hurtEffectData[buffType] = hurtEffectData_
						attachEffectData[buffType] = attachEffectData_

					end

				end
			end

		end
		------------ 每个buff的爆点和附加特效 ------------

		------------ 动作时音效 ------------
		local actionSE = BattleUtils.GetFilteredStringBySpace(effectConfig.startEffect)
		if nil ~= actionSE then
			actionSE = tostring(effectConfig.startEffect)
		end

		local actionVoice = BattleUtils.GetFilteredStringBySpace(effectConfig.soundCard)
		if nil ~= actionVoice then
			actionVoice = tostring(effectConfig.soundCard)
		end

		local actionCauseSE = BattleUtils.GetFilteredStringBySpace(effectConfig.soundEffect)
		if nil ~= actionCauseSE then
			actionCauseSE = tostring(effectConfig.soundEffect)
		end
		------------ 动作时音效 ------------

		-- 返回数据结构
		return SkillSpineEffectStruct.New(
			skillId, bulletType, causeType, actionName,
			effectId, effectActionName, effectZOrder, effectScale, effectPos,
			hurtEffectData, attachEffectData,
			actionSE, actionVoice, actionCauseSE
		)
	end
end
--[[
根据所填的动作id获取spine文件中对应的动作名
@params actionId string id
@return _ string 动作名
--]]
function BattleStructConvertUtils.GetSpineAniNameByActionId(actionId)
	if ATTACK_2_SKILL_ID == checkint(actionId) then
		return sp.AnimationName.attack
	elseif 0 < checkint(actionId) then
		return sp.AnimationName.skill .. tostring(actionId)
	end
end



























