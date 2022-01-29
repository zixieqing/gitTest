--[[
基础战斗物体view
@params t table {
	tag int obj tag 此tag与战斗物体逻辑层hold的展示层tag对应
	viewInfo ObjectViewConstructStruct 渲染层构造数据
}
--]]
local BaseObjectView = class('BaseObjectView', function ()
	local node = CLayout:create()
	node.name = 'battle.obiectView.BaseObjectView'
	node:enableNodeEvents()
	return node
end)

------------ import ------------
local ExpressionNode = require('common.ExpressionNode')
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseObjectView:ctor( ... )
	local args = unpack({...})
	self.idInfo = {
		tag = args.tag,
		logicTag = args.logicTag
	}
	self.viewInfo = args.viewInfo

	self:InitValue()
	self:InitSpineId()
	self:InitView()
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化数值
--]]
function BaseObjectView:InitValue()
	self.staticViewBox = nil
	self.staticCollisionBox = nil
	self.viewData = {}
	self.avatar = nil

	-- buff图标
	self.buffIcons = {}
	-- 附加效果
	self.attachEffects = {}
	-- 爆点效果
	self.hurtEffects = {}

	self.viewValid = true

	self.forceHideAvatarShadow = false
end
--[[
初始化spine id
--]]
function BaseObjectView:InitSpineId()
	self.spineId = nil

	if nil ~= self:GetVSkinId() then
		local skinConfig = CardUtils.GetCardSkinConfig(self:GetVSkinId())
		if nil ~= skinConfig then
			self.spineId = tostring(skinConfig.spineId)
		end
	end
end
--[[
初始化视图
--]]
function BaseObjectView:InitView()
	-- 创建spine avatar
	self:InitSpineAvatarNode()
	-- 创建其他的ui
	self:InitUI()
end
--[[
创建spine avatar
--]]
function BaseObjectView:InitSpineAvatarNode()

end
--[[
创建ui
--]]
function BaseObjectView:InitUI()

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
view死亡开始
--]]
function BaseObjectView:DieBegin()
	self:KillSelf()
end
--[[
view死亡结束
--]]
function BaseObjectView:DieEnd()
	-- 隐藏自己
	self:setVisible(false)
end
--[[
杀死该单位 隐藏血条能量条阴影
--]]
function BaseObjectView:KillSelf()
	self:SetViewValid(false)
	-- 隐藏周身ui
	self:ShowAllObjectUI(false)
	-- 移除所有的hurt effect
	self:ClearAllHurtEffects()
end
--[[
复活
--]]
function BaseObjectView:Revive()
	self:stopAllActions()
	self:SetViewValid(true)
	-- 显示周身ui
	self:SetObjectVisible(true)
	-- 隐藏身上的attach效果
	self:ShowAllAttachEffects(false)
end
--[[
买活复活
--]]
function BaseObjectView:ReviveFromBuyRevive()
	self:Revive()
	-- 隐藏周身特效
	self:ShowAllObjectUI(false)
	-- 添加一个idle动作
	self:GetAvatar():setToSetupPose()
	self:GetAvatar():setAnimation(0, sp.AnimationName.idle, true)
end
--[[
销毁view
--]]
function BaseObjectView:Destroy()
	self:ClearAllHurtEffects()
	self:setVisible(false)
	self:runAction(cc.RemoveSelf:create())
end
--[[
添加一个attach object view
@params view BaseAttachObjectView
--]]
function BaseObjectView:AddAAttachView(view)

end
--[[
进入下一波
@params nextWave int 下一波
--]]
function BaseObjectView:EnterNextWave(nextWave)
	
end
--[[
刷新一次ui大小 位置
--]]
function BaseObjectView:FixUIState()

end
--[[
杀死view
--]]
function BaseObjectView:KillView()
	-- 设置不可见
	self:SetObjectVisible(false)

	-- 清除动画
	local avatar = self:GetAvatar()
	if nil ~= avatar then
		avatar:clearTracks()
	end
end
--[[
设置引导中高亮
@params highlight bool 是否高亮
--]]
function BaseObjectView:SetObjectHighlightInGuide(highlight)

end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- object ui control begin --
---------------------------------------------------
--[[
隐藏自己
@params visible bool 是否可见
--]]
function BaseObjectView:SetObjectVisible(visible)
	self:ShowAllObjectUI(visible)
	self:setVisible(visible)
end
--[[
显示怪物阴影
@params show bool 是否显示
--]]
function BaseObjectView:ShowAvatarShadow(show)

end
--[[
显示周身ui
@params show bool 是否显示
--]]
function BaseObjectView:ShowAllObjectUI(show)
	
end
--[[
显示血条
@params show bool 是否显示
--]]
function BaseObjectView:ShowHpBar(show)

end
--[[
显示能量条
@params show bool 是否显示
--]]
function BaseObjectView:ShowEnergyBar(show)
	
end
--[[
显示所有的buff icon
@params visible bool 是否显示
--]]
function BaseObjectView:ShowAllBuffIcons(visible)
	for i,v in ipairs(self.buffIcons) do
		v:setVisible(visible)
	end
end
--[[
显示所有的被击特效
@params visible bool 是否显示
--]]
function BaseObjectView:ShowAllHurtEffects(visible)
	for k,v in pairs(self.hurtEffects) do
		v:setVisible(visible)
	end
end
--[[
清除所有的被击特效
--]]
function BaseObjectView:ClearAllHurtEffects()
	for k,v in pairs(self.hurtEffects) do
		v:stopAllActions()
		v:clearTracks()
		v:unregisterSpineEventHandler(sp.EventType.ANIMATION_END)
		v:runAction(cc.RemoveSelf:create())
	end
	self.hurtEffects = {}
end
--[[
显示所有的附加效果特效
@params visible bool 是否显示
@params setToSetupPose bool 是否重置动画
--]]
function BaseObjectView:ShowAllAttachEffects(visible)
	for k,v in pairs(self.attachEffects) do
		if false == visible then
			-- 如果是不可见 重置一次动画状态
			v:setToSetupPose()
			v:clearTracks()
		end
		v:setVisible(visible)
	end
end
---------------------------------------------------
-- object ui control end --
---------------------------------------------------

---------------------------------------------------
-- hp energy control begin --
---------------------------------------------------
--[[
刷新血条
@params percent 血量百分比
--]]
function BaseObjectView:UpdateHpBar(percent)
	
end
--[[
刷新能量条
@params percent 能量百分比
--]]
function BaseObjectView:UpdateEnergyBar(percent)
	
end
---------------------------------------------------
-- hp energy control end --
---------------------------------------------------

---------------------------------------------------
-- pause control begin --
---------------------------------------------------
--[[
暂停
--]]
function BaseObjectView:PauseView()

end
--[[
继续
--]]
function BaseObjectView:ResumeView()
	
end
---------------------------------------------------
-- pause control end --
---------------------------------------------------

---------------------------------------------------
-- buff control begin --
---------------------------------------------------
--[[
add buff
@params iconType BuffIconType 图标类型
@params value number 数值
--]]
function BaseObjectView:AddBuff(iconType, value)

end
--[[
remove buff
@params iconType BuffIconType 图标类型
@params value number 数值
--]]
function BaseObjectView:RemoveBuff(iconType, value)

end
--[[
刷新buff坐标
--]]
function BaseObjectView:RefreshBuffIcons()

end
--[[
显示被击特效
@params params table {
	hurtEffectId int 被击特效id
	hurtEffectPos cc.p 被击特效单位坐标
	hurtEffectZOrder int 被击特效层级
}
--]]
function BaseObjectView:ShowHurtEffect(params)

end
--[[
显示附加在人物身上的持续特效
@params v bool 是否可见
@params	bid string buff id
@params params table {
	attachEffectId int 特效id
	attachEffectPos cc.p 特效位置坐标
	attachEffectZOrder int 特效层级
}
--]]
function BaseObjectView:ShowAttachEffect(v, bid, params)

end
--[[
根据effect id移除附加特效
@params effectId int 特效id
--]]
function BaseObjectView:RemoveAttachEffectByEffectId(effectId)
	
end
--[[
获取buff icon的路径
@params buffIconId int buff icon的id
@params value number buff的值 如果是负值则要带上后缀
@return path string 
--]]
function BaseObjectView:GetBuffIconPath(buffIconId, value)
	local path = string.format('arts/battlebuffs/buff_icon_%d', checkint(buffIconId))
	if 0 > checknumber(value) then
		local debuffSuffix = '_2'
		path = path .. debuffSuffix
	end
	path = path .. '.png'
	return path
end
--[[
获取buff icon的tag
@params buffIconId int buff icon的id
@params value number buff的值 如果是负值则要带上后缀
@return tag int tag
--]]
function BaseObjectView:GetBuffIconTag(buffIconId, value)
	local tag = checkint(buffIconId)
	if 0 > checknumber(value) then
		tag = tag + BattleTags.BT_DEBUFF
	end
	return tag
end
---------------------------------------------------
-- buff control end --
---------------------------------------------------

---------------------------------------------------
-- object mark begin --
---------------------------------------------------
--[[
显示过关目标相关信息
@params stageCompleteType ConfigStageCompleteType 过关类型
@params show bool 是否显示
--]]
function BaseObjectView:ShowStageClearTargetMark(stageCompleteType, show)
	if ConfigStageCompleteType.SLAY_ENEMY == stageCompleteType then
		self:ShowSlayStageClearTarget(show)
	elseif ConfigStageCompleteType.HEAL_FRIEND == stageCompleteType then
		self:ShowHealStageClearTarget(show)
	end
end
--[[
显示杀戮模式相关信息
@params show bool 是否显示
--]]
function BaseObjectView:ShowSlayStageClearTarget(show)

end
--[[
显示治疗目标信息
@params show bool 是否显示
--]]
function BaseObjectView:ShowHealStageClearTarget(show)

end
--[[
隐藏所有目标mark
--]]
function BaseObjectView:HideAllStageClearTargetMark()
	
end
---------------------------------------------------
-- object mark end --
---------------------------------------------------

---------------------------------------------------
-- expression begin --
---------------------------------------------------
--[[
显示免疫提示
@params immuneType ImmuneType 免疫类型
--]]
function BaseObjectView:ShowImmune(immuneType)

end
--[[
显示表情
@params expressionType ExpressionType 表情类型
--]]
function BaseObjectView:ShowExpression(expressionType)
	local expressionNode = ExpressionNode.new({nodeType = expressionType})
	self:addChild(expressionNode, 20)
	local viewBox = self:GetAvatarStaticViewBox()
	expressionNode:setPosition(cc.p(viewBox.width * 0.55, viewBox.height * 0.85))
	expressionNode:setTag(357)

	local fps = 30
	local oriScale = 0.75
	local deltaP1 = cc.p(30, 30)
	local deltaP2 = cc.p(10, 10)
	local deltaP3 = cc.p(20, 20)
	expressionNode:setScale(0)
	expressionNode:setOpacity(0)

	local actionSeq = cc.Sequence:create(
		cc.Spawn:create(
			cc.ScaleTo:create(10 / fps, oriScale),
			cc.MoveBy:create(10 / fps, deltaP1),
			cc.FadeTo:create(10 / fps, 255)
		),
		cc.MoveBy:create(28 / fps, deltaP2),
		cc.Spawn:create(
			cc.ScaleTo:create(8 / fps, oriScale * 1.1),
			cc.MoveBy:create(8 / fps, deltaP3),
			cc.FadeTo:create(8 / fps, 0)
		),
		cc.RemoveSelf:create()
	)
	expressionNode:runAction(actionSeq)
end
--[[
显示被打断时的效果
@params weakPointId ConfigWeakPointId 弱点效果id
--]]
function BaseObjectView:ShowChantBreakEffect(weakPointId)
	local remindLabelActionSeq = nil
	local remindLabelPath = nil
	local fps = 30

	if ConfigWeakPointId.BREAK == weakPointId then

		self:ShowExpression(ExpressionType.EMBRARASSED)
		remindLabelPath = 'ui/battle/expression_word_3.png'

		local deltaP1 = cc.p(0, 30)
		local deltaP2 = cc.p(0, 80)

		remindLabelActionSeq = cc.Sequence:create(
			cc.Spawn:create(
				cc.FadeTo:create(6 / fps, 255),
				cc.ScaleTo:create(6 / fps, 1)
			),
			cc.MoveBy:create(24 / fps, deltaP1),
			cc.Spawn:create(
				cc.MoveBy:create(7 / fps, deltaP2),
				cc.FadeTo:create(7 / fps, 0)
			),
			cc.RemoveSelf:create()
		)

	elseif ConfigWeakPointId.HALF_EFFECT == weakPointId then

		self:ShowExpression(ExpressionType.SWEAT)
		remindLabelPath = 'ui/battle/expression_word_2.png'

		local deltaP1 = cc.p(0, 20)
		local deltaP2 = cc.p(0, 40)
		local deltaP3 = cc.p(0, -60)

		remindLabelActionSeq = cc.Sequence:create(
			cc.Spawn:create(
				cc.ScaleTo:create(5 / fps, 1),
				cc.FadeTo:create(5 / fps, 255)
			),
			cc.MoveBy:create(19 / fps, deltaP1),
			cc.MoveBy:create(5 / fps, deltaP2),
			cc.Spawn:create(
				cc.FadeTo:create(8 / fps, 0),
				cc.ScaleTo:create(8 / fps, 0),
				cc.MoveBy:create(8 / fps, deltaP3)
			),
			cc.RemoveSelf:create()
		)

	elseif ConfigWeakPointId.NONE == weakPointId then
		
		self:ShowExpression(ExpressionType.PLEASED)
		remindLabelPath = 'ui/battle/expression_word_1.png'

		local deltaP1 = cc.p(0, -10)
		local deltaP2 = cc.p(0, -50)

		remindLabelActionSeq = cc.Sequence:create(
			cc.Spawn:create(
				cc.FadeTo:create(6 / fps, 255),
				cc.ScaleTo:create(6 / fps, 1),
				cc.RotateBy:create(6 / fps, 10)
			),
			cc.MoveBy:create(18 / fps, deltaP1),
			cc.Spawn:create(
				cc.MoveBy:create(12 / fps, deltaP2),
				cc.FadeTo:create(12 / fps, 0)
			),
			cc.RemoveSelf:create()
		)

	end

	if nil ~= remindLabelPath then
		local viewBox = self:GetAvatarStaticViewBox()
		local remindLabel = display.newNSprite(_res(remindLabelPath), viewBox.width * 0.25, viewBox.height * 0.75)
		self:addChild(remindLabel, 20)
		remindLabel:setTag(358)

		remindLabel:setScale(2)
		remindLabel:setOpacity(0)

		if nil ~= remindLabelActionSeq then
			remindLabel:runAction(remindLabelActionSeq)
		end
	end
end
--[[
显示对话气泡
@params dialogueFrameType int 对话框气泡类型
@params content string 对话内容
@params actionDelay number action延迟
@params disappearCallback function 对话框开始消失时的回调函数
--]]
function BaseObjectView:ShowDialogue(dialogueFrameType, content, actionDelay, disappearCallback)
	local battleRoot = G_BattleRenderMgr:GetBattleRoot()

	local DIALOG_BG = nil

	if BattleConfigUtils:UseElexLocalize() or BattleConfigUtils:UseJapanLocalize() then
		DIALOG_BG = {
			['1'] = {id = 1, name = 'dialogue_bg_1', offset = cc.p(43, 21), size = cc.size(766, 138)},
			['2'] = {id = 2, name = 'dialogue_bg_2', offset = cc.p(87, 36), size = cc.size(650, 144)},
			['3'] = {id = 3, name = 'dialogue_bg_3', offset = cc.p(119, 61), size = cc.size(588,174)},
			['4'] = {id = 4, name = 'dialogue_bg_4', offset = cc.p(69, 74), size = cc.size(530, 140)},
			['5'] = {id = 5, name = 'dialogue_bg_5', offset = cc.p(71, 66), size = cc.size(660,142)},
			['6'] = {id = 6, name = 'dialogue_bg_6', offset = cc.p(68, 45), size = cc.size(662, 140)}
		}
	else
		DIALOG_BG = {
			['1'] = {id = 1, name = 'dialogue_bg_1', offset = cc.p(30, 26), size = cc.size(780, 132)},
			['2'] = {id = 2, name = 'dialogue_bg_2', offset = cc.p(44, 56), size = cc.size(472, 102)},
			['3'] = {id = 3, name = 'dialogue_bg_3', offset = cc.p(57, 53), size = cc.size(436, 128)},
			['4'] = {id = 4, name = 'dialogue_bg_4', offset = cc.p(59, 84), size = cc.size(322, 102)},
			['5'] = {id = 5, name = 'dialogue_bg_5', offset = cc.p(44, 50), size = cc.size(444, 98)},
			['6'] = {id = 6, name = 'dialogue_bg_6', offset = cc.p(68, 46), size = cc.size(498, 126)}
		}
	end

	------------ 创建对话内容 ------------
	-- 对话框初始位置
	local viewBox = self:GetAvatarStaticViewBox()
	local dialogueConfig = DIALOG_BG[tostring(dialogueFrameType)]
	local dialogueFrame = display.newImageView(string.format('arts/stage/ui/%s.png', dialogueConfig.name), 0, 0)
	local dialogueSize = dialogueFrame:getContentSize()
	local contentLabel = display.newLabel(dialogueConfig.offset.x, dialogueSize.height - dialogueConfig.offset.y,
		{fontSize = 22, color = '6c6c6c', text = content, ap = cc.p(0, 1), hAlign = display.TAL,
		w = dialogueConfig.size.width, h = dialogueConfig.size.height}
	)
	dialogueFrame:addChild(contentLabel, 3)

	battleRoot:addChild(dialogueFrame, BATTLE_E_ZORDER.DIALOGUE)

	local dialogueOriginalPos = cc.p(self:getPositionX(), self:getPositionY() + viewBox.height * 0.5)
	display.commonUIParams(dialogueFrame, {po = dialogueOriginalPos})

	local finalScale = 1.25
	local dialoguePos = cc.p(0, self:getPositionY() + viewBox.height * 0.65)
	local battleRootSize = battleRoot:getContentSize()
	if battleRootSize.width * 0.5 < self:getPositionX() then
		-- 人物在战斗场景右半场
		dialoguePos.x = math.max(
			(battleRootSize.width - display.width) * 0.5 + dialogueSize.width * 0.5 * finalScale,
			self:getPositionX() - dialogueSize.width * 0.5 * finalScale - viewBox.width * 0.1
		)
	else
		-- 人物在战斗场景左半场
		dialoguePos.x = math.min(
			(battleRootSize.width + display.width) * 0.5 - dialogueSize.width * 0.5 * finalScale,
			self:getPositionX() + dialogueSize.width * 0.5 * finalScale + viewBox.width * 0.1
		)
	end
	------------ 创建对话内容 ------------

	------------ 对话内容动画 ------------
	-- 初始化对话框动画状态
	dialogueFrame:setOpacity(0)
	contentLabel:setVisible(false)

	local duration = string.utf8len(content) * 0.05
	local dialogueActionSeq = cc.Sequence:create(
		cc.Spawn:create(
			cc.MoveTo:create(0.2, dialoguePos),
			cc.FadeTo:create(0.2, 255)
		),
		cc.CallFunc:create(function ()
			-- 开始打字
			local writer = TypewriterAction:create(duration)
			local typeActionSeq = cc.Sequence:create(
				writer
			)
			contentLabel:runAction(typeActionSeq)
		end),
		cc.ScaleTo:create(duration + 1, 1.03),
		cc.CallFunc:create(function ()
			if nil ~= disappearCallback then
				disappearCallback()
			end
		end),
		cc.Spawn:create(
			cc.ScaleTo:create(0.1, finalScale),
			cc.FadeTo:create(0.1, 0)
		),
		cc.RemoveSelf:create()
	)

	dialogueFrame:runAction(dialogueActionSeq)
	------------ 对话内容动画 ------------
end
---------------------------------------------------
-- expression end --
---------------------------------------------------

---------------------------------------------------
-- tint begin --
---------------------------------------------------
--[[
设置一次物体颜色
@params color cc.c3b
--]]
function BaseObjectView:SetObjectViewColor(color)

end
---------------------------------------------------
-- tint end --
---------------------------------------------------

---------------------------------------------------
-- performance begin --
---------------------------------------------------
--[[
开始阶段转换 ConfigPhaseType.TALK_DEFORM 喊话变身
@params dialogueFrameType int 对话框气泡类型
@params content string 对话内容
@params deformTargetViewModelTag int 变身目标的展示层tag
@params callback function 变身结束以后的回调函数
--]]
function BaseObjectView:StartSpeakAndDeform(dialogueFrameType, content, deformTargetViewModelTag, callback)
	local avatar = self:GetAvatar()
	-- 读条动作
	avatar:setToSetupPose()
	avatar:setAnimation(0, sp.AnimationName.chant, true)

	self:ShowDialogue(
		dialogueFrameType,
		content,
		0.2,
		function ()
			------------ 变身光圈 ------------
			local pos = cc.p(
				self:getPositionX(), display.cy
			)

			local deformEffect = SpineCache(SpineCacheName.BATTLE):createWithName(sp.AniCacheName.PHASE_DEFORM_EFFECT)
			deformEffect:setPosition(pos)
			deformEffect:update(0)
			G_BattleRenderMgr:GetBattleRoot():addChild(deformEffect, BATTLE_E_ZORDER.BULLET + 1)
			deformEffect:setAnimation(0, sp.AnimationName.idle, false)

			local effectAnimationsData = SpineCache(SpineCacheName.BATTLE):getAnimationsDataByName(sp.AniCacheName.PHASE_DEFORM_EFFECT)
			local deformTime = effectAnimationsData[sp.AnimationName.idle].duration
			local deformEffectActionSeq = cc.Sequence:create(
				cc.DelayTime:create(deformTime * 0.4),
				cc.CallFunc:create(function ()
					G_BattleRenderMgr:ShakeWorld()
				end),
				cc.DelayTime:create(deformTime * 0.6),
				cc.RemoveSelf:create()
			)
			deformEffect:runAction(deformEffectActionSeq)
			------------ 变身光圈 ------------

			------------ 变身npc处理 ------------
			-- 隐藏变身源
			self:DeformDisappear(
				deformTime * 0.4,
				function ()
					-- 杀死自身obj的渲染层
					self:DieBegin()

					-- 唤醒目标渲染层
					local view = G_BattleRenderMgr:GetAObjectView(deformTargetViewModelTag)
					if nil ~= view then
						view:DeformAppear(0, deformTime * 0.6, function ()
							if nil ~= callback then
								callback()
							end
						end)
					end
				end
			)
			------------ 变身npc处理 ------------
		end
	)
end
--[[
变身出现
@params delayTime number 延迟
@params fadeTime number 消失时间
@params callback function 回调
--]]
function BaseObjectView:DeformAppear(delayTime, fadeTime, callback)
	-- 初始化动画状态
	self:setOpacity(0)
	
	local actionSeqTable = {
		cc.DelayTime:create(delayTime),
		cc.CallFunc:create(function ()
			self:SetObjectVisible(true)
		end),
		cc.FadeTo:create(fadeTime, 255),
		cc.DelayTime:create(1)
	}

	if nil ~= callback then
		table.insert(actionSeqTable, cc.CallFunc:create(callback))
	end

	local actionSeq = cc.Sequence:create(actionSeqTable)
	self:runAction(actionSeq)
end
--[[
变身消失
@params fadeTime number 消失时间
@params callback function 回调
--]]
function BaseObjectView:DeformDisappear(fadeTime, callback)
	local actionSeqTable = {
		cc.FadeTo:create(fadeTime, 0)
	}

	if nil ~= callback then
		table.insert(actionSeqTable, cc.CallFunc:create(callback))
	end

	local actionSeq = cc.Sequence:create(actionSeqTable)
	self:runAction(actionSeq)
end
--[[
喊话逃跑
@params dialogueFrameType int 对话框气泡类型
@params content string 对话内容
@params callback function 逃跑完成后的回调
--]]
function BaseObjectView:StartSpeakBeforeEscape(dialogueFrameType, content, callback)
	-- 直接开始喊话
	self:ShowDialogue(
		dialogueFrameType,
		content,
		0,
		callback
	)
end
--[[
开始逃跑
@params targetPos cc.p 逃跑的目标位置
@params walkSpeed number 行走速度
@params callback function 逃跑以后的回调
--]]
function BaseObjectView:StartEscape(targetPos, walkSpeed, callback)
	-- 开始进行逃跑动作
	local distance = cc.pGetDistance(targetPos, cc.p(self:getPositionX(), self:getPositionY()))
	local t = distance / walkSpeed
	local actionSeq = cc.Sequence:create(
		cc.MoveTo:create(t, targetPos),
		cc.CallFunc:create(function ()
			if nil ~= callback then
				callback()
			end
		end)
	)
	self:runAction(actionSeq)
end
--[[
逃跑消失
--]]
function BaseObjectView:OverEscape()
	self:SetObjectVisible(false)
end
--[[
逃跑返回
--]]
function BaseObjectView:EscapeBack()
	self:SetObjectVisible(true)
end
--[[
自定义的变身 -> 消失
@params actionName string 动作名字
@params delayTime number 延迟时间
@params callback function 回调函数
--]]
function BaseObjectView:DeformCustomizeDisappear(actionName, delayTime, callback)
	local avatar = self:GetAvatar()
	local animationData = self:GetSpineAnimationDataByAnimationName(actionName)
	local actionTime = 0
	if nil ~= animationData then
		actionTime = checknumber(animationData.duration)
	end

	local actionSeq = cc.Sequence:create(
		cc.DelayTime:create(delayTime),
		cc.CallFunc:create(function ()
			-- 做动画
			avatar:setToSetupPose()
			avatar:setAnimation(0, actionName, false)
		end),
		cc.DelayTime:create(actionTime),
		cc.CallFunc:create(function ()
			-- 强制隐藏
			self:SetObjectVisible(false)

			if nil ~= callback then
				callback()
			end
		end)
	)

	self:runAction(actionSeq)
end
--[[
自定义的变身 -> 出现
@params actionName string 动作名字
@params delayTime number 延迟时间
@params callback function 回调函数
--]]
function BaseObjectView:DeformCustomizeAppear(actionName, delayTime, callback)
	local avatar = self:GetAvatar()
	local animationData = self:GetSpineAnimationDataByAnimationName(actionName)
	local actionTime = 0
	if nil ~= animationData then
		actionTime = checknumber(animationData.duration)
	end

	local actionSeq = cc.Sequence:create(
		cc.DelayTime:create(delayTime),
		cc.CallFunc:create(function ()
			-- 强制显示
			self:SetObjectVisible(true)

			-- 做动画
			avatar:setToSetupPose()
			avatar:setAnimation(0, actionName, false)
			avatar:addAnimation(0, sp.AnimationName.idle, true)
		end),
		cc.DelayTime:create(actionTime),
		cc.CallFunc:create(function ()
			if nil ~= callback then
				callback()
			end
		end)
	)

	self:runAction(actionSeq)
end
---------------------------------------------------
-- performance end --
---------------------------------------------------

---------------------------------------------------
-- view transform begin --
---------------------------------------------------
--[[
物体开始变形
@params oriSkinId int 源皮肤id
@params oriActionName string 源皮肤变形的动作
@params targetSkinId int 目标皮肤id
@params targetActionName string 目标皮肤变形的衔接动作
--]]
function BaseObjectView:StartViewTransform(oriSkinId, oriActionName, targetSkinId, targetActionName)

end
--[[
物体进行变形替换
@params oriSkinId int 源皮肤id
@params oriActionName string 源皮肤变形的动作
@params targetSkinId int 目标皮肤id
@params targetActionName string 目标皮肤变形的衔接动作
--]]
function BaseObjectView:DoViewTransform(oriSkinId, oriActionName, targetSkinId, targetActionName)
	
end
---------------------------------------------------
-- view transform end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取展示层tag
--]]
function BaseObjectView:GetVTag()
	return self.idInfo.tag
end
--[[
获取逻辑层tag
--]]
function BaseObjectView:GetLogicTag()
	return self.idInfo.logicTag
end
--[[
获取卡牌id
--]]
function BaseObjectView:GetVCardId()
	return self.viewInfo.cardId
end
--[[
获取spineid
--]]
function BaseObjectView:GetVSpineId()
	return self.spineId
end
--[[
获取皮肤id
--]]
function BaseObjectView:GetVSkinId()
	return self.viewInfo.skinId
end
--[[
获取卡牌avatar缩放比
--]]
function BaseObjectView:GetAvatarScale()
	return self.viewInfo.avatarScale
end
--[[
获取avatar相对于卡牌的缩放比
--]]
function BaseObjectView:GetSpineAvatarScale2Card()
	return self.viewInfo.avatarScale2Card
end
--[[
获取敌友性
@return _ bool 敌友性
--]]
function BaseObjectView:GetVEnemy()
	return self.viewInfo.isEnemy
end
--[[
获取缓存后的spine名称
@params spineId int 传入的spineId 当本地没有对应的spine文件时 做相对处理
@return spineName string 处理过的缓存的spine动画名 
--]]
function BaseObjectView:GetSpineNameBySpineId(spineId, cardId)
	return tostring(spineId)
end
--[[
获取卡牌spine修正后的边界框信息
@params borderBox string 边界框名字
@return box cc.rect 边界框信息
--]]
function BaseObjectView:GetAvatarBorderBox(borderBox)
	return cc.rect(0, 0, 0, 0)
end
--[[
获取卡牌spine静态碰撞框信息
@return box cc.rect 边界框信息
--]]
function BaseObjectView:GetAvatarStaticCollisionBox()
	return self.staticCollisionBox
end
--[[
获取卡牌spine静态碰撞框信息
@return box cc.rect 边界框信息
--]]
function BaseObjectView:GetAvatarStaticViewBox()
	return self.staticViewBox
end
--[[
根据单位坐标点获取人物对应坐标
@params up cc.p 单位坐标
--]]
function BaseObjectView:ConvertUnitPosToRealPos(up)
	if not up then return cc.p(0, 0) end
	local viewBox = self:GetAvatarStaticCollisionBox()
	return cc.p(viewBox.x + viewBox.width * up.x, viewBox.y + viewBox.height * up.y)
end
--[[
获取核心人物层
@return cc.node
--]]
function BaseObjectView:GetAvatar()
	return self.avatar
end
--[[
获取是否强制隐藏物体阴影
--]]
function BaseObjectView:GetForceHideAvatarShadow()
	return self.forceHideAvatarShadow
end
function BaseObjectView:SetForceHideAvatarShadow(force)
	self.forceHideAvatarShadow = force
end
--[[
根据骨骼名字获取骨骼的坐标信息
@params boneName string 骨骼名字
@return result {
	name,
	x, y, worldX, worldY,
	scaleX, scaleY, rotation
}
--]]
function BaseObjectView:FindBoneInAvatar(boneName)
	return nil
end
--[[
根据骨骼名字获取骨骼的世界坐标
@params boneName string 骨骼名字
@return worldPos cc.p 世界坐标
--]]
function BaseObjectView:FindBoneInAvatarByWorldPos(boneName)
	return nil
end
--[[
设置渲染层模型可用
--]]
function BaseObjectView:SetViewValid(valid)
	self.viewValid = valid
end
function BaseObjectView:GetViewValid()
	return self.viewValid
end
--[[
获取动画信息
@params animationName string 动画的动作名
@return _ table 动画信息
--]]
function BaseObjectView:GetSpineAnimationDataByAnimationName(animationName)
	local avatar = self:GetAvatar()
	if nil ~= avatar then
		return avatar:getAnimationsData()[tostring(animationName)]
	end
	return nil
end
---------------------------------------------------
-- get set end --
---------------------------------------------------






































































---------------------------------------------------
-- action logic begin --
---------------------------------------------------

--[[
开始逃跑
--]]
function BaseObjectView:escape()
	
end

--[[
逃跑后出现
--]]
function BaseObjectView:escapeDisappear()
	self:setVisible(true)
end
--[[
强制隐藏
--]]
function BaseObjectView:forceHide()
	self:setVisible(false)
end
--[[
强制显示
--]]
function BaseObjectView:forceShow()
	self:setVisible(true)
end
---------------------------------------------------
-- action logic end --
---------------------------------------------------

return BaseObjectView
