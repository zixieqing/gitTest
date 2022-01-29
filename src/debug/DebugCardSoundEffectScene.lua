local GameScene = require( 'Frame.GameScene' )
local DebugCardSoundEffectScene = class('DebugCardSoundEffectScene', GameScene)
local LANGUAGE_TAG = 'zh-cn'

function DebugCardSoundEffectScene:ctor( ... )
	self.args = unpack({...})

	self:initSoundInfo()

	app.audioMgr:AddCueSheet(AUDIOS.BATTLE.name, AUDIOS.BATTLE.acb, "")
	app.audioMgr:AddCueSheet(AUDIOS.BATTLE2.name, AUDIOS.BATTLE2.acb, "")

	self.avatar = nil
	self.avatarName = nil
	self.avatarAnimationsData = {}
	self.avatarActionButtons = {}
	self.avatarId = nil

	self.playCVSound = true
	self.playSkillSound = true
	self.playHurtSound = true

	self.playSkillSoundName = nil
	self.playHurtSoundName = nil

	self:setBackgroundColor(cc.c4b(0, 128, 128, 255))

	self:initDebugSESceneByFolder()
	app.audioMgr:StopBGMusic(AUDIOS.BGM.name)


end

function DebugCardSoundEffectScene:initDebugSESceneByFolder()

	local size = self:getContentSize()

	-- 底部选择按钮
	local buttomBtnsSize = cc.size(size.width, 100)

	---------------- 选人 ----------------
	-- 获取所有spine文件
	self.debugPath = {}
	local folderPath = 'res/cards/spine/avatar'
	for file in lfs.dir(folderPath) do
		if nil ~= string.find(tostring(file), '.json') then
			local name = string.split(file, '.')[1]
			table.insert(self.debugPath, {path = folderPath .. '/' .. name, name = name})
		end
	end

	local selectAvatarScrollViewSize = cc.size(size.width * 0.5, size.height - buttomBtnsSize.height)
	local selectAvatarScrollViewBtnSize = cc.size(selectAvatarScrollViewSize.height * 0.5, 50)
	local selectAvatarScrollViewContainerSize = cc.size(selectAvatarScrollViewSize.width, selectAvatarScrollViewBtnSize.height * #self.debugPath)

	local selectAvatarScrollView = CScrollView:create(selectAvatarScrollViewSize)
	selectAvatarScrollView:setDirection(eScrollViewDirectionVertical)
	selectAvatarScrollView:setAnchorPoint(cc.p(0, 1))
	selectAvatarScrollView:setPosition(cc.p(0, size.height))
	selectAvatarScrollView:setContainerSize(selectAvatarScrollViewContainerSize)
	self:addChild(selectAvatarScrollView, 20)
	selectAvatarScrollView:getContainer():setPositionY(selectAvatarScrollViewSize.height - selectAvatarScrollViewContainerSize.height)

	-- selectAvatarScrollView:setBackgroundColor(cc.c4b(123, 44, 88, 128))

	for i,v in ipairs(self.debugPath) do
		local btn = display.newButton(selectAvatarScrollViewBtnSize.width * 0.5,
			selectAvatarScrollViewContainerSize.height - selectAvatarScrollViewBtnSize.height * 0.5 - (i - 1) * selectAvatarScrollViewBtnSize.height,
			{size = selectAvatarScrollViewBtnSize, cb = function (sender)
				self:refreshAvatar(sender:getTag())
				self.selectAvatarScrollView:setVisible(not self.selectAvatarScrollView:isVisible())
			end})
		selectAvatarScrollView:getContainer():addChild(btn)
		local nameLabel = display.newLabel(
			selectAvatarScrollViewBtnSize.width * 0.5,
			selectAvatarScrollViewBtnSize.height * 0.5,
			{text = tostring(v.name), fontSize = 30, color = '#ffffff'})
		btn:addChild(nameLabel)
		btn:setTag(i)
	end
	selectAvatarScrollView:setVisible(false)

	local selectAvatarBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		self.selectAvatarScrollView:setVisible(not self.selectAvatarScrollView:isVisible())
	end})
	display.commonLabelParams(selectAvatarBtn, {text = __('选人'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(selectAvatarBtn, {po = cc.p(selectAvatarScrollViewSize.width * 0.5, buttomBtnsSize.height * 0.5)})
	self:addChild(selectAvatarBtn, 99999)
	---------------- 选人 ----------------

	---------------- cv语音 ----------------
	local cvSoundBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		self.playCVSound = not self.playCVSound
		if self.playCVSound then
			display.commonLabelParams(sender, {text = __('cv语音开'), fontSize = 20, color = '#ffffff'})
		else
			display.commonLabelParams(sender, {text = __('cv语音关'), fontSize = 20, color = '#000000'})
		end
	end})
	display.commonLabelParams(cvSoundBtn, {text = __('cv语音开'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(cvSoundBtn, {po = cc.p(size.width - cvSoundBtn:getContentSize().width * 0.5, buttomBtnsSize.height * 0.5 + cvSoundBtn:getContentSize().height)})
	self:addChild(cvSoundBtn)
	---------------- cv语音 ----------------

	---------------- 动作开始的音效 ----------------
	local skillSoundBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		self.playSkillSound = not self.playSkillSound
		if self.playSkillSound then
			display.commonLabelParams(sender, {text = __('技能音效开'), fontSize = 20, color = '#ffffff'})
		else
			display.commonLabelParams(sender, {text = __('技能音效关'), fontSize = 20, color = '#000000'})
		end
	end})
	display.commonLabelParams(skillSoundBtn, {text = __('技能音效开'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(skillSoundBtn, {po = cc.p(size.width - skillSoundBtn:getContentSize().width * 1.5, buttomBtnsSize.height * 0.5 + skillSoundBtn:getContentSize().height)})
	self:addChild(skillSoundBtn)

	local selectSkillSoundScrollViewSize = cc.size(size.width * 0.5, size.height - buttomBtnsSize.height)
	local selectSkillSoundScrollViewBtnSize = cc.size(selectSkillSoundScrollViewSize.height * 0.5, 85)
	local selectSkillSoundScrollViewContainerSize = cc.size(selectSkillSoundScrollViewSize.width, selectSkillSoundScrollViewBtnSize.height * table.nums(self.soundInfo))

	local selectSkillSoundScrollView = CScrollView:create(selectSkillSoundScrollViewSize)
	selectSkillSoundScrollView:setDirection(eScrollViewDirectionVertical)
	selectSkillSoundScrollView:setAnchorPoint(cc.p(0.5, 1))
	selectSkillSoundScrollView:setPosition(cc.p(skillSoundBtn:getPositionX(), size.height))
	selectSkillSoundScrollView:setContainerSize(selectSkillSoundScrollViewContainerSize)
	self:addChild(selectSkillSoundScrollView, 20)
	selectSkillSoundScrollView:getContainer():setPositionY(selectSkillSoundScrollViewSize.height - selectSkillSoundScrollViewContainerSize.height)

	-- selectSkillSoundScrollView:setBackgroundColor(cc.c4b(123, 44, 88, 128))
	local i = 1
	for k,v in pairs(self.soundInfo) do
		local btn = display.newButton(selectSkillSoundScrollViewBtnSize.width * 0.5,
			selectSkillSoundScrollViewContainerSize.height - selectSkillSoundScrollViewBtnSize.height * 0.5 - (i - 1) * selectSkillSoundScrollViewBtnSize.height,
			{size = selectSkillSoundScrollViewBtnSize, cb = function (sender)
				self.selectSkillSoundScrollView:setVisible(not self.selectSkillSoundScrollView:isVisible())
				self.playSkillSoundName = self.soundInfo[tostring(sender:getTag())].filename
				display.commonLabelParams(self.selectSkillSoundLabel, {text = string.format('选择的技能音效->%s', tostring(self.playSkillSoundName)), fontSize = 24, color = '#ffffff'})
			end})
		selectSkillSoundScrollView:getContainer():addChild(btn)
		local nameLabel = display.newLabel(
			selectSkillSoundScrollViewBtnSize.width * 0.5,
			selectSkillSoundScrollViewBtnSize.height,
			{text = tostring(v.filename), fontSize = 30, color = '#9BCD9B', ap = cc.p(0.5, 1)})
		btn:addChild(nameLabel)
		btn:setTag(checkint(v.id))
		local descrLabel = display.newLabel(
			selectSkillSoundScrollViewBtnSize.width * 0.5,
			selectSkillSoundScrollViewBtnSize.height - display.getLabelContentSize(nameLabel).height - 3,
			{text = tostring(v.descr), fontSize = 18, color = '#EEC900', ap = cc.p(0.5, 1), w = btn:getContentSize().width - 10})
		btn:addChild(descrLabel)
		i = i + 1
	end
	selectSkillSoundScrollView:setVisible(false)

	local selectSkillSoundBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		self.selectSkillSoundScrollView:setVisible(not self.selectSkillSoundScrollView:isVisible())
	end})
	display.commonLabelParams(selectSkillSoundBtn, {text = __('选择技能音效'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(selectSkillSoundBtn, {po = cc.p(skillSoundBtn:getPositionX(), buttomBtnsSize.height * 0.5)})
	self:addChild(selectSkillSoundBtn)

	local selectSkillSoundLabel = display.newLabel(display.width * 0.5, display.height - 100,
		{text = string.format('选择的技能音效->%s', tostring(self.playSkillSoundName)), fontSize = 24, color = '#ffffff', ap = cc.p(0, 0.5)})
	self:addChild(selectSkillSoundLabel)
	---------------- 动作开始的音效 ----------------

	---------------- 动作打击音效 ----------------
	local hurtSoundBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		self.playHurtSound = not self.playHurtSound
		if self.playHurtSound then
			display.commonLabelParams(sender, {text = __('打击音效开'), fontSize = 20, color = '#ffffff'})
		else
			display.commonLabelParams(sender, {text = __('打击音效关'), fontSize = 20, color = '#000000'})
		end
	end})
	display.commonLabelParams(hurtSoundBtn, {text = __('打击音效开'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(hurtSoundBtn, {po = cc.p(size.width - hurtSoundBtn:getContentSize().width * 2.5, buttomBtnsSize.height * 0.5 + hurtSoundBtn:getContentSize().height)})
	self:addChild(hurtSoundBtn)

	local selectHurtSoundScrollViewSize = cc.size(size.width * 0.5, size.height - buttomBtnsSize.height)
	local selectHurtSoundScrollViewBtnSize = cc.size(selectHurtSoundScrollViewSize.height * 0.5, 75)
	local selectHurtSoundScrollViewContainerSize = cc.size(selectHurtSoundScrollViewSize.width, selectHurtSoundScrollViewBtnSize.height * table.nums(self.soundInfo))

	local selectHurtSoundScrollView = CScrollView:create(selectHurtSoundScrollViewSize)
	selectHurtSoundScrollView:setDirection(eScrollViewDirectionVertical)
	selectHurtSoundScrollView:setAnchorPoint(cc.p(0.5, 1))
	selectHurtSoundScrollView:setPosition(cc.p(hurtSoundBtn:getPositionX(), size.height))
	selectHurtSoundScrollView:setContainerSize(selectHurtSoundScrollViewContainerSize)
	self:addChild(selectHurtSoundScrollView, 20)
	selectHurtSoundScrollView:getContainer():setPositionY(selectHurtSoundScrollViewSize.height - selectHurtSoundScrollViewContainerSize.height)

	-- selectHurtSoundScrollView:setBackgroundColor(cc.c4b(123, 44, 88, 128))

	i = 1
	for k,v in pairs(self.soundInfo) do
		local btn = display.newButton(selectHurtSoundScrollViewBtnSize.width * 0.5,
			selectHurtSoundScrollViewContainerSize.height - selectHurtSoundScrollViewBtnSize.height * 0.5 - (i - 1) * selectHurtSoundScrollViewBtnSize.height,
			{size = selectHurtSoundScrollViewBtnSize, cb = function (sender)
				self.selectHurtSoundScrollView:setVisible(not self.selectHurtSoundScrollView:isVisible())
				self.playHurtSoundName = self.soundInfo[tostring(sender:getTag())].filename
				display.commonLabelParams(self.selectHurtSoundLabel, {text = string.format('选择的技能音效->%s', tostring(self.playHurtSoundName)), fontSize = 24, color = '#ffffff'})
			end})
		selectHurtSoundScrollView:getContainer():addChild(btn)
		local nameLabel = display.newLabel(
			selectSkillSoundScrollViewBtnSize.width * 0.5,
			selectSkillSoundScrollViewBtnSize.height,
			{text = tostring(v.filename), fontSize = 30, color = '#EEC900', ap = cc.p(0.5, 1)})
		btn:addChild(nameLabel)
		btn:setTag(checkint(v.id))
		local descrLabel = display.newLabel(
			selectSkillSoundScrollViewBtnSize.width * 0.5,
			selectSkillSoundScrollViewBtnSize.height - display.getLabelContentSize(nameLabel).height - 3,
			{text = tostring(v.descr), fontSize = 18, color = '#9BCD9B', ap = cc.p(0.5, 1), w = btn:getContentSize().width - 10})
		btn:addChild(descrLabel)
		i = i + 1
	end
	selectHurtSoundScrollView:setVisible(false)

	local selectHurtSoundBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		self.selectHurtSoundScrollView:setVisible(not self.selectHurtSoundScrollView:isVisible())
	end})
	display.commonLabelParams(selectHurtSoundBtn, {text = __('选择打击音效'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(selectHurtSoundBtn, {po = cc.p(hurtSoundBtn:getPositionX(), buttomBtnsSize.height * 0.5)})
	self:addChild(selectHurtSoundBtn)

	local selectHurtSoundLabel = display.newLabel(display.width * 0.5, selectSkillSoundLabel:getPositionY() - 30,
		{text = string.format('选择的打击音效->%s', tostring(self.playHurtSoundName)), fontSize = 24, color = '#ffffff', ap = cc.p(0, 0.5)})
	self:addChild(selectHurtSoundLabel)
	---------------- 动作打击音效 ----------------

	self.selectAvatarScrollView = selectAvatarScrollView
	self.selectHurtSoundScrollView = selectHurtSoundScrollView
	self.selectSkillSoundLabel = selectSkillSoundLabel
	self.selectSkillSoundScrollView = selectSkillSoundScrollView
	self.selectHurtSoundScrollView = selectHurtSoundScrollView
	self.selectHurtSoundLabel = selectHurtSoundLabel
	self.buttomBtnsSize = buttomBtnsSize

end

function DebugCardSoundEffectScene:refreshAvatar(tag)
	if nil ~= self.avatar then
		self.avatarId = nil

		self.avatar:clearTracks()
		self.avatar:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
		self.avatar:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
		self.avatar:removeFromParent()
		self.avatar = nil

		self.avatarName:removeFromParent()
		self.avatarName = nil

		for k,v in pairs(self.avatarActionButtons) do
			v:removeFromParent()
		end
		self.avatarActionButtons = {}

		self.avatarAnimationsData = {}
	end

	local spineInfo = self.debugPath[tag]
	self.avatarId = checkint(spineInfo.name)

	local path = string.gsub(spineInfo.path, "res/", "")
	self.avatar = sp.SkeletonAnimation:create(path .. '.json', path .. '.atlas', 0.5)
	self:addChild(self.avatar)
	self.avatar:setPosition(cc.p(self:getContentSize().width * 0.25, self.buttomBtnsSize.height * 2))
	self.avatar:setAnimation(0, 'idle', true)

	self.avatar:registerSpineEventHandler(handler(self, self.spineActionStartHandler), sp.EventType.ANIMATION_START)
	self.avatar:registerSpineEventHandler(handler(self, self.spineActionCustomHandler), sp.EventType.ANIMATION_EVENT)

	self.avatarName = display.newLabel(
		self.avatar:getPositionX(),
		self.avatar:getPositionY() - 20,
		{text = tostring(spineInfo.name), fontSize = 22, color = '#ffffff'})
	self:addChild(self.avatarName, 1)

	avatarAnimationsData = self.avatar:getAnimationsData()
	local i, x, y = 1, 1, 1
	local pos = cc.p(0, 0)
	for k,ad in pairs(avatarAnimationsData) do
		self.avatarAnimationsData[tostring(i)] = {animationName = k}
		local btn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
			local tag = sender:getTag()
			if self.avatar then
				local animationName = self.avatarAnimationsData[tostring(tag)].animationName
				self.avatar:setToSetupPose()
				self.avatar:setAnimation(0, animationName, false)
				self.avatar:addAnimation(0, 'idle', true)
			end
		end})

		local btnSize = btn:getContentSize()
		if btnSize.width * i > self:getContentSize().width then
			x = 1
			y = y + 1
		end

		display.commonLabelParams(btn, {text = k, fontSize = 20, color = '#ffffff'})
		display.commonUIParams(btn, {po = cc.p(btnSize.width * (x - 0.5), self:getContentSize().height - btnSize.height * (y - 0.5))})
		self:addChild(btn, 1)
		btn:setTag(i)
		self.avatarActionButtons[tostring(i)] = btn

		i = i + 1
		x = x + 1
	end

end


function DebugCardSoundEffectScene:spineActionStartHandler(event)
	-- dump(event)
	if self:isBattleAcitonByActionName(event.animation) then
		if self.avatarId < 300000 and self.playCVSound then
			CommonUtils.PlayCardSoundByCardId(self.avatarId, SoundType.TYPE_SKILL2)
		end

		if self.playSkillSound then
			print('check skill sound name>>>>>>>>>>>>', self.playSkillSoundName)
			app.audioMgr:PlayAudioClip('battle', tostring(self.playSkillSoundName))
		end
	end
end

function DebugCardSoundEffectScene:spineActionCustomHandler(event)
	-- dump(event)
	if self.playHurtSound and self:isBattleAcitonByActionName(event.animation) and 'cause_effect' == event.eventData.name then
		print('check hurt sound name>>>>>>>>>>>>', self.playHurtSoundName)
		app.audioMgr:PlayAudioClip('battle', tostring(self.playHurtSoundName))
	end
end

function DebugCardSoundEffectScene:isBattleAcitonByActionName(actionName)
	return nil ~= string.find(actionName, 'attack') or nil ~= string.find(actionName, 'skill')
end

function DebugCardSoundEffectScene:initSoundInfo()
	local soundConfigPath = 'src/conf/' .. LANGUAGE_TAG .. '/common/soundEffect.json'
	local file = assert(io.open(soundConfigPath, 'r'), 'cannot find sound config file')
	local fileContent = file:read('*a')
	local configtable = json.decode(fileContent)
	file:close()
	self.soundInfo = configtable

	dump(self.soundInfo)
end

return DebugCardSoundEffectScene
