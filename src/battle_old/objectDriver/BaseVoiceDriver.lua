--[[
语音播放驱动基类
@params table {
	owner BaseObject 挂载的战斗物体
	voiceModuleId int 语音模块id
}
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local BaseVoiceDriver = class('BaseVoiceDriver', BaseActionDriver)

------------ import ------------
local audioManager = AppFacade.GetInstance():GetManager("AudioManager")
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseVoiceDriver:ctor( ... )
	BaseActionDriver.ctor(self, ...)
	local args = unpack({...})

	self.voiceModuleId = args.voiceModuleId

	self:Init()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function BaseVoiceDriver:Init()
	BaseActionDriver.Init(self)

	-- 初始化触发器
	self.actionTrigger = {
		[ActionTriggerType.CD] = {}
	}

	-- 停掉语音的触发器
	self.stopActionTrigger = {
		[ActionTriggerType.CD] = {}
	}

	-- 语音数据
	self.voices = {}
	-- 气泡节点
	self.friendDialougeNodes = {}
	self.enemyDialougeNodes = {}

	self.friendDialougeY = 0
	self.enemyDialougeY = 0
	self.dialougeTagCounter = 0

	self:InitValue()
end
--[[
@override
初始化数据
--]]
function BaseVoiceDriver:InitValue()
	-- 根据语音模块id初始化语音数据
	self.voices = {
		['1'] = {id = 1, cardId = 200020, appearTime = 0.5, isEnemy = true, voiceId = 10, time = 0, text = __('狂欢才刚刚开始!')},
		['2'] = {id = 2, cardId = 200037, appearTime = 3.5, isEnemy = false, voiceId = 10, time = 2, text = __('可以安静点吗!')},
		['3'] = {id = 3, cardId = 200004, appearTime = 6, isEnemy = false, voiceId = 15, time = 0, text = __('可恶!')},
		['4'] = {id = 4, cardId = 200048, appearTime = 8, isEnemy = false, voiceId = 15, time = 0, text = __('……还没有……')},
		['5'] = {id = 5, cardId = 200024, appearTime = 11, isEnemy = false, voiceId = 12, time = 0, text = __('不，现在还不能倒下。')},
		-- ['4'] = {id = 4, cardId = 200048, time = 4, isEnemy = false, voiceId = 4, text = '测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试!!!4'},
		-- ['5'] = {id = 5, cardId = 200037, time = 5, isEnemy = false, voiceId = 5, text = '测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试!!!5'}
	}
	-- self.voices = {
	-- 	['1'] = {id = 1, cardId = 200020, appearTime = 0.5, isEnemy = true, voiceId = 10, time = 0, text = '测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试!!!1'},
	-- 	['2'] = {id = 2, cardId = 200004, appearTime = 3, isEnemy = false, voiceId = 15, time = 0, text = '3测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试!!!2'},
	-- 	['3'] = {id = 3, cardId = 200024, appearTime = 5, isEnemy = false, voiceId = 12, time = 0, text = '4测试测试测试测试测试测试测试测试测试测试测试测试测试测试测试!!!3'},
	-- }

	-- 为触发器插入语音cd时间
	for k,v in pairs(self.voices) do
		self.actionTrigger[ActionTriggerType.CD][tostring(v.id)] = v.appearTime
	end
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
@override
是否能进行动作
--]]
function BaseVoiceDriver:CanDoAction()

end
--[[
@override
进入动作
--]]
function BaseVoiceDriver:OnActionEnter()

end
--[[
@override
结束动作
--]]
function BaseVoiceDriver:OnActionExit()

end
--[[
@override
动作进行中
@params dt number delta time
--]]
function BaseVoiceDriver:OnActionUpdate(dt)

end
--[[
@override
动作被打断
--]]
function BaseVoiceDriver:OnActionBreak()
	
end
--[[
@override
消耗做出行为需要的资源
--]]
function BaseVoiceDriver:CostActionResources()

end
--[[
@override
刷新触发器
@params actionTriggerType ActionTriggerType 技能触发类型
@params delta number 变化量
--]]
function BaseVoiceDriver:UpdateActionTrigger(actionTriggerType, delta)
	if ActionTriggerType.CD == actionTriggerType then
		for sheetName, countdown in pairs(self.stopActionTrigger[ActionTriggerType.CD]) do
			self.stopActionTrigger[ActionTriggerType.CD][sheetName] = math.max(0, countdown - delta)
			if 0 >= self.stopActionTrigger[ActionTriggerType.CD][sheetName] then
				-- 停掉当前语音
				audioManager:StopEffect(sheetName, true)

				self.stopActionTrigger[ActionTriggerType.CD][sheetName] = nil
			end
		end


		for id, countdown in pairs(self.actionTrigger[ActionTriggerType.CD]) do
			self.actionTrigger[ActionTriggerType.CD][id] = math.max(0, countdown - delta)
			if 0 >= self.actionTrigger[ActionTriggerType.CD][id] then
				-- 播放语音 显示对话气泡
				local voiceData = self.voices[tostring(id)]
				self:PlayVoice(checkint(id))

				-- 从数据中移除
				self.actionTrigger[ActionTriggerType.CD][id] = nil
			end
		end
	end
end
--[[
@override
重置所有触发器
--]]
function BaseVoiceDriver:ResetActionTrigger()

end
--[[
@override
操作触发器
--]]
function BaseVoiceDriver:GetActionTrigger()

end
function BaseVoiceDriver:SetActionTrigger()
	
end
--[[
根据 语音id 播放语音
@params id int 语音id
--]]
function BaseVoiceDriver:PlayVoice(id)
	local voiceData = self.voices[tostring(id)]

	local voicesConf = CardUtils.GetVoiceLinesConfigByCardId(voiceData.cardId)
	local voiceConf = nil

	if nil ~= voicesConf then
		for i,v in ipairs(voicesConf) do
			if voiceData.voiceId == checkint(v.groupId) then
				voiceConf = v
			end
		end
	end

	if nil ~= voiceConf then
		local cueSheet = tostring(voiceConf.roleId)
		local cueName = voiceConf.voiceId
		local acbFile = string.format('sounds/%s.acb', cueSheet)
		if utils.isExistent(acbFile) then
			audioManager:AddCueSheet(cueSheet, acbFile)
			audioManager:PlayAudioClip(cueSheet, cueName)

			-- 如果时间配置的不为0 则认为是程序需要掐掉一部分的语音
			if 0 < voiceData.time then
				self.stopActionTrigger[ActionTriggerType.CD][tostring(cueSheet)] = voiceData.time
			end
		end
	end

	self:ShowDialougeNode(voiceData.cardId, voiceData.text, voiceData.isEnemy, voiceData.time)
end
--[[
根据 卡牌id 描述文字 敌友性 显示对话气泡
@params cardId int 卡牌id
@params text string 描述文字
@params isEnemy bool 敌友性
@params time number 语音时间
--]]
function BaseVoiceDriver:ShowDialougeNode(cardId, text, isEnemy, time)
	local layerSize = cc.size(325, 85)
	local layer = display.newLayer(0, 0, {size = layerSize, ap = cc.p(0.5, 0.5)})
	BMediator:GetViewComponent():addChild(layer, 99999)

	self.dialougeTagCounter = self.dialougeTagCounter + 1
	layer:setTag(self.dialougeTagCounter)

	local bg = display.newImageView(_res('ui/common/common_bg_tips_common.png'), layerSize.width * 0.5, layerSize.height * 0.5,
		{scale9 = true, size = layerSize})
	layer:addChild(bg)

	-- 卡牌头像
	local cardHeadBg = display.newImageView(_res('ui/cards/head/kapai_frame_bg.png'), 0, 0)
	local cardHeadScale = (layerSize.height - 10) / cardHeadBg:getContentSize().height
	cardHeadBg:setScale(cardHeadScale)
	layer:addChild(cardHeadBg)

	local cardHeadCover = display.newImageView(_res(CardUtils.CAREER_HEAD_FRAME_PATH_MAP[tostring(CardUtils.QUALITY_TYPE.UR)]), 0, 0)
	cardHeadCover:setScale(cardHeadScale)
	layer:addChild(cardHeadCover, 10)

	local headIcon = display.newImageView(CardUtils.GetCardHeadPathByCardId(cardId), 0, 0)
	headIcon:setScale(cardHeadScale)
	layer:addChild(headIcon, 5)

	-- 翻译文字
	local descrLabel = display.newLabel(0, 0, fontWithColor('6', {text = text}))
	layer:addChild(descrLabel)

	local x = 0
	local y = 0

	local textW = 0
	local textH = 0
	local textAlign = display.TAC
	local textPos = cc.p(0, 0)
	local textAp = cc.p(0, 0)

	local dislougeMoveX = 0

	local cardHeadPos = cc.p(0, 0)

	local cacheNodes = nil

	if isEnemy then
		dislougeMoveX = -layerSize.width
		x = display.width - layerSize.width * 0.5 - dislougeMoveX
		y = display.height - layerSize.height * 0.5 - (layerSize.height) * self.enemyDialougeY

		cardHeadPos.x = layerSize.width - 5 - cardHeadBg:getContentSize().width * 0.5 * cardHeadScale
		cardHeadPos.y = layerSize.height * 0.5

		local headIconLeftBorderX = cardHeadPos.x - cardHeadBg:getContentSize().width * 0.5 * cardHeadScale
		textAp = cc.p(0, 1)
		textAlign = display.TAL
		textW = headIconLeftBorderX - 20
		textH = layerSize.height - 20
		textPos.x = headIconLeftBorderX * 0.5 - textW * 0.5
		textPos.y = layerSize.height * 0.5 + textH * 0.5

		self.enemyDialougeY = self.enemyDialougeY + 1

		cacheNodes = self.enemyDialougeNodes
	else
		dislougeMoveX = layerSize.width
		x = layerSize.width * 0.5 - dislougeMoveX
		y = display.height - layerSize.height * 0.5 - (layerSize.height) * self.friendDialougeY

		cardHeadPos.x = cardHeadBg:getContentSize().width * 0.5 * cardHeadScale + 5
		cardHeadPos.y = layerSize.height * 0.5

		local headIconRightBorderX = cardHeadPos.x + cardHeadBg:getContentSize().width * 0.5 * cardHeadScale
		textAp = cc.p(0, 1)
		textAlign = display.TAL
		textW = layerSize.width - headIconRightBorderX - 20
		textH = layerSize.height - 20
		textPos.x = (layerSize.width - headIconRightBorderX) * 0.5 + headIconRightBorderX - textW * 0.5
		textPos.y = layerSize.height * 0.5 + textH * 0.5

		self.friendDialougeY = self.friendDialougeY + 1

		cacheNodes = self.friendDialougeNodes
	end

	display.commonUIParams(layer, {po = cc.p(x, y)})

	display.commonUIParams(cardHeadBg, {po = cardHeadPos})
	display.commonUIParams(cardHeadCover, {po = cardHeadPos})
	display.commonUIParams(headIcon, {po = cardHeadPos})

	display.commonLabelParams(descrLabel, {w = textW, h = textH, hAlign = textAlign})
	display.commonUIParams(descrLabel, {ap = textAp, po = textPos})

	-- 插入缓存
	table.insert(cacheNodes, 1, layer)

	local actionSeq = cc.Sequence:create(
		cc.EaseOut:create(cc.MoveBy:create(0.2, cc.p(dislougeMoveX, 0)), 5),
		cc.DelayTime:create(2),
		cc.FadeTo:create(0.5, 0),
		cc.Hide:create(),
		cc.CallFunc:create(function ()
			-- 将自己从缓存队列中移除 并将所有节点上移一位
			for i = #cacheNodes, 1, -1 do
				if layer:getTag() == cacheNodes[i]:getTag() then
					table.remove(cacheNodes, i)
					if isEnemy then
						self.enemyDialougeY = self.enemyDialougeY - 1
					else
						self.friendDialougeY = self.friendDialougeY - 1
					end
					break
				end
			end

			-- 将所有缓存node上移
			for i,v in ipairs(cacheNodes) do
				local y = display.height - layerSize.height * 0.5 - (layerSize.height) * (#cacheNodes - i)
				local moveActionSeq = cc.Sequence:create(
					cc.EaseIn:create(cc.MoveTo:create(0.2, cc.p(v:getPositionX(), y)), 5)
				)
				v:runAction(moveActionSeq)
			end
		end),
		cc.RemoveSelf:create()
	)
	layer:runAction(actionSeq)
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据配置信息获取语音数据
@params voiceConfig table 语音配置信息
--]]
function BaseVoiceDriver:ConvertVoiceDataByConfig(voiceConfig)

end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseVoiceDriver
