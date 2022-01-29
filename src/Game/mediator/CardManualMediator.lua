local Mediator = mvc.Mediator

local CardManualMediator = class("CardManualMediator", Mediator)


local NAME = "CardManualMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
---@type AudioManager
local audioMgr = AppFacade.GetInstance():GetManager("AudioManager")
local cardManualVoiceCell = require('home.CardManualVoiceCell')
local CardManualSkinCell = require('home.CardManualSkinCell')
local TABTYPE = {
	story = 1001,
	voice = 1002,
	information = 1003
}
function CardManualMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.datas = params or {}
	self.cardId = self.datas.cardId -- 卡牌id	 
	self.breakLevel = self.datas.breakLevel -- 卡牌突破等级
	self.selectedTabTag = TABTYPE.story -- 选择的页签
	self.selectedVoice = nil -- 选择的音频
	self.playVoice = nil -- 正在播放的音频
	self.voiceViewDatas = {}
	self.storyViewDatas = {}
	self.headNode = nil
	self.voiceDatas = {}
	self.storyDatas = {}

	self.selectedStory = nil -- 当前选中的故事
	------------好感度相关--------------
	self.favorabilityLevel = nil -- 好感度阶级
	self.storyUnlockNum = 0 -- 故事解锁数目
	self.voiceUnlockNum = 0 -- 解锁音频数量
	------------好感度相关--------------
	-------------皮肤相关---------------
	self.cardDatas = CommonUtils.GetConfig('cards', 'card', self.cardId)
	local cardSkinConf =  CommonUtils.GetConfigAllMess('cardSkin' ,'goods')
	self.skinDatas = {}
	for _, v in orderedPairs(self.cardDatas.skin) do
		for _, cardId in pairs(v) do
			-- 加入皮肤检测
			if cardSkinConf[tostring(cardId)] then
				table.insert(self.skinDatas, cardId)
			end
		end
	end
	self.selectedSkinIndex = 1 -- 当前选中的皮肤序号
	self.showSpine = false -- 是否显示spine
	-------------皮肤相关---------------
end

function CardManualMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Collection_CardStoryUnlock_Callback,
		SIGNALNAMES.Collection_CardVoiceUnlock_Callback,
		EVENT_PAY_SKIN_SUCCESS
	}

	return signals
end

function CardManualMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	print(name)
	if name == SIGNALNAMES.Collection_CardStoryUnlock_Callback then
		local datas = signal:GetBody()
		gameMgr:GetUserInfo().cardStory[tostring(datas.requestData.cardStoryId)] = 0
		self.storyUnlockNum = self.storyUnlockNum + 1
		local lockSpine = self.storyViewDatas.storyBtns[self.storyUnlockNum].lockSpine
		lockSpine:update(0)
		lockSpine:setToSetupPose()
		lockSpine:setAnimation(0, 'play', false)
		lockSpine:registerSpineEventHandler(function(event) 
			if event.animation == 'play' then
				lockSpine:setVisible(false)
			end
		end, sp.EventType.ANIMATION_END)
		self:RefreshStoryButtonStatus()
		uiMgr:ShowInformationTips(__('解锁成功'))

	elseif name == SIGNALNAMES.Collection_CardVoiceUnlock_Callback then
		local datas = signal:GetBody()
		gameMgr:GetUserInfo().cardVoice[tostring(datas.requestData.cardVoiceId)] = 0
		self.voiceUnlockNum = self.voiceUnlockNum + 1
		for i,v in ipairs(self.voiceDatas) do
			if v.id == datas.requestData.cardVoiceId then
				local lockSpine = self.voiceViewDatas.gridView:cellAtIndex(i-1).lockSpine
				lockSpine:update(0)
				lockSpine:setToSetupPose()
				lockSpine:setAnimation(0, 'play', false)
				lockSpine:registerSpineEventHandler(function(event) 
					if event.animation == 'play' then
						lockSpine:setVisible(false)
					end
				end, sp.EventType.ANIMATION_END)
				break
			end
		end
		-- 更新解锁数目
		self.voiceViewDatas.collectionLabel:setString(string.fmt(__('语音收集度 _num1_/_num2_'), { ['_num1_'] = self.voiceUnlockNum, ['_num2_'] = table.nums(self.voiceDatas)}))
		uiMgr:ShowInformationTips(__('解锁成功'))
	elseif name == EVENT_PAY_SKIN_SUCCESS then
		self:RefreshSkinList()
	end
end

function CardManualMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.CardManualView' ).new(self.datas)
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	local viewData = viewComponent.viewData
	viewData.backBtn:setOnClickScriptHandler(function (sender)
		if self.playVoice and self.selectedVoice then
			audioMgr:StopAudioClip(self.voiceDatas[self.selectedVoice].roleId, true)
		end
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator("CardManualMediator")  
    end)

	for _,v in pairs(viewData.tabButtons) do
		v:setOnClickScriptHandler(handler(self, self.TabsCallback))
	end
	viewData.cardBtn:setOnClickScriptHandler(handler(self, self.CardButtonCallback))
	viewData.jumpBtn:setOnClickScriptHandler(handler(self, self.JumpButtonCallback))
	viewData.switchBtn:setOnClickScriptHandler(handler(self, self.SwitchButtonCallback))
	viewData.skinGridView:setDataSourceAdapterScriptHandler(handler(self, self.OnSkinDataSourceAction))
	viewData.skinGridView:setCountOfCell(#self.skinDatas)
    viewData.skinGridView:reloadData()
    self:UpdateSkinProgress()
    self:SkinIconButtonCallback(1)
	self:TabsCallback(self.selectedTabTag)
	self:EnterAction()

	CommonUtils.PlayCardSoundByCardId(self.cardId, SoundType.TYPE_HOME_CARD_CHANGE, SoundChannel.CARD_MANUAL)
end
--[[
进入动作
--]]
function CardManualMediator:EnterAction()
	local viewData = self:GetViewComponent().viewData
	viewData.cardDraw:setOpacity(0)
	viewData.cardDraw:runAction(cc.FadeIn:create(0.3))
	viewData.bottomLayout:setOpacity(0)
	viewData.bottomLayout:setPositionY(viewData.bottomLayout:getPositionY() - 100)
	viewData.bottomLayout:runAction(
		cc.Spawn:create(
			cc.FadeIn:create(0.3),
			cc.MoveBy:create(0.3, cc.p(0, 100))
		)
	)
		
	if viewData.particleSpine then
		viewData.particleSpine:setOpacity(0)
		viewData.particleSpine:runAction(cc.Sequence:create(
			cc.DelayTime:create(0.3),
			cc.Show:create(),
			cc.FadeIn:create(0.3)
		))
	end
end
--[[
立绘按钮回调
--]]
function CardManualMediator:CardButtonCallback( sender )
	-- 添加点击音效
	PlayAudioByClickNormal()
	if self.showSpine then 
		local actionList = {
			'idle',
			'run',
			'attack',
			'skill1',
			'skill2'
		}
		local viewData = self:GetViewComponent().viewData
		local qAvatar = viewData.view:getChildByName('cardSpine')
		local tag = qAvatar:getTag()
		if tag == 5 then
			tag = 0
		end
		tag = tag + 1
		qAvatar:update(0)
    	qAvatar:setToSetupPose()
    	qAvatar:setAnimation(0, actionList[tag], true)
		qAvatar:setTag(tag)
	else
		local layer = require('Game.views.CardManualDrawView').new({cardId = self.cardId, skinId = self:GetSkinId(self.selectedSkinIndex)})
		display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = display.center})
		local scene = uiMgr:GetCurrentScene()
		scene:AddDialog(layer)
		layer:setClickCallback(function() 
			-- 添加点击音效
			PlayAudioByClickClose()
			layer:runAction(
				cc.Sequence:create(
					cc.FadeOut:create(0.2),
					cc.RemoveSelf:create()
				)
			)
		end)
		-- 动作
		layer:setOpacity(0)
		layer:runAction(cc.FadeIn:create(0.2))
	end
end
--[[
底部页签按钮点击回调
--]]
function CardManualMediator:TabsCallback( sender )
	local tag = 0
	if type(sender) == 'number' then
		tag = sender
	else
		tag = sender:getTag()
		-- 添加点击音效
		PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id) 
		if self.selectedTabTag == tag then
			return
		end 
	end
	-- 添加点击音效
	PlayAudioClip(AUDIOS.UI.ui_click_confirm.id)
	-- 判断音频文件是否存在
	if tag == TABTYPE.voice then
		local voiceLine = CardUtils.GetVoiceLinesConfigByCardId(self.cardId)
		local acbFile = nil
		if voiceLine then
			if audioMgr:GetVoiceType() == PLAY_VOICE_TYPE.CHINESE then
				acbFile = audioMgr:GetVoicePathByName(voiceLine[1].roleIdCn, PLAY_VOICE_TYPE.CHINESE)
			elseif audioMgr:GetVoiceType() == PLAY_VOICE_TYPE.JAPANESE then
				acbFile = audioMgr:GetVoicePathByName(voiceLine[1].roleId, PLAY_VOICE_TYPE.JAPANESE)
			end
		end
        if not utils.isExistent(acbFile) then
			local viewData = self:GetViewComponent().viewData
			viewData.tabButtons['1002']:setChecked(false)
			uiMgr:ShowInformationTips(__('敬请期待'))
			return 
        end
	end
	local viewData = self:GetViewComponent().viewData
	for k, v in pairs( viewData.tabButtons ) do
		local curTag = v:getTag()
		if tag == curTag then
			v:setChecked(true)
			v:setEnabled(false)
		else
			v:setChecked(false)
			v:setEnabled(true)
		end
	end
	self.selectedTabTag = tag
	self:ChangeTabActions(tag)
end
--[[
切换页签
@params tabType int 页签类型
--]]
function CardManualMediator:ChangeTabActions( tabType )
	local viewData = self:GetViewComponent().viewData
	if viewData.view:getChildByTag(2000) then
		local temp = viewData.view:getChildByTag(2000)
		temp:setTag(2001)
		temp:setLocalZOrder(temp:getLocalZOrder() - 1)
		temp:runAction(
			cc.Sequence:create(
				cc.FadeOut:create(0.2),
				cc.RemoveSelf:create()
			)
		)
	end
	-- 清除对话框
	if viewData.view:getChildByTag(6000) then
		viewData.view:getChildByTag(6000):runAction(
			cc.Sequence:create(
				cc.ScaleTo:create(0.1, 0),
				cc.RemoveSelf:create()
			)
		)
	end
	-- 停止正在播放的音频
	if self.playVoice and self.selectedVoice then
		audioMgr:StopAudioClip(self.voiceDatas[self.selectedVoice].roleId, true)
	end
	-- 停止当前动作
	self:GetViewComponent():stopAllActions()
	-- 清除数据
	self.voiceViewDatas = {}
	self.selectedVoice = nil
	self.playVoice = nil
	self.headNode = nil
	self.voiceDatas = {}
	self.storyViewDatas = {}
	self.storyDatas = {}
	self.selectedStory = nil
	local layout = nil 
	if tabType == TABTYPE.story then 
		-- 初始化故事数据
		self:InitStoryDatas(self.cardId)
		-- 创建layout
		self.storyViewDatas = self:CreateRightLayout( tabType )
		self:RefreshStoryButtonStatus()
		viewData.view:addChild(self.storyViewDatas.layout, 10)
		layout = self.storyViewDatas.layout
	elseif tabType == TABTYPE.voice then
		-- 清除本地数据
		-- self.storyViewDatas = {}
		-- self.storyDatas = {}
		-- self.selectedStory = nil
		-- 初始化音频数据
		self:InitVoiceDatas(self.cardId)
		-- 创建layout
		self.voiceViewDatas = self:CreateRightLayout( tabType )
		viewData.view:addChild(self.voiceViewDatas.layout, 10)
		layout = self.voiceViewDatas.layout
	elseif tabType == TABTYPE.information then
		-- 创建layout
		self.informationViewDatas = self:CreateRightLayout( tabType )
		viewData.view:addChild(self.informationViewDatas.layout, 10)
		layout = self.informationViewDatas.layout
	end
	layout:setPositionX(layout:getPositionX() - 200)
	layout:setOpacity(0)
	layout:runAction(
		cc.Spawn:create(
			cc.FadeIn:create(0.2),
			cc.MoveBy:create(0.2, cc.p(200, 0))
		)
	)
end
--[[
创建右侧Layout
@params tabType int 页签类型
--]]
function CardManualMediator:CreateRightLayout( tabType )
	local size = cc.size(530, 593)
	local layout = CLayout:create(size)
	layout:setPosition(cc.p(display.width - 274 - display.SAFE_L, 118 + (display.height - 750)/2))
	layout:setAnchorPoint(cc.p(0.5, 0))
	layout:setTag(2000)
	
	local cardConf = CardUtils.GetCardConfig(self.datas.cardId)
	local cardDatas = gameMgr:GetCardDataByCardId(self.datas.cardId)
	self.favorabilityLevel = checkint(cardDatas.favorabilityLevel)
	if tabType == TABTYPE.story then -- 故事
		local hideStory = checkint(cardConf.backgroundStory) -- 是否隐藏背景故事
		local storyBgSize = cc.size(520, 324)
		local listViewSize = cc.size(460, 268)
		if hideStory == 1 then
			storyBgSize = cc.size(520, 584)
			listViewSize = cc.size(460, 524)
		end
		local storyBg = display.newImageView(_res("ui/home/handbook/pokedex_card_bg_story.png"), size.width/2, size.height/2)
		layout:addChild(storyBg, 3)
		local descrBg = display.newImageView(_res('ui/home/handbook/pokedex_card_bg_story_about.png'), size.width/2, size.height - 5, {ap = cc.p(0.5, 1), scale9 = true, size = storyBgSize})
		layout:addChild(descrBg, 5)
		local storyTitle = display.newButton(size.width/2, size.height - 30, {n = _res('ui/home/handbook/pokedex_card_title.png') ,enable = false })
		layout:addChild(storyTitle, 10)
		display.commonLabelParams(storyTitle, fontWithColor(16, {text = __('背景故事') , paddingW = 30}))
		local descrLabel = display.newLabel(230, 0,
			{text = cardConf.descr, ap = cc.p(0.5, 0), w = 440, fontSize = 22, color = '#ffeed2'})

		local listView = CListView:create(listViewSize)
		listView:setDirection(eScrollViewDirectionVertical)
		listView:setAnchorPoint(cc.p(0.5, 1))	
		listView:setPosition(cc.p(size.width/2, 538))	
		layout:addChild(listView, 10)

		local labelLayout = CLayout:create(cc.size(listViewSize.width, display.getLabelContentSize(descrLabel).height+5))
		labelLayout:addChild(descrLabel)
		listView:insertNodeAtLast(labelLayout)
		listView:reloadData()
		-- 是否隐藏故事按钮
		if hideStory == 1 then
			return {
				layout    = layout,
				storyBtns = {},
			}
		end
		local storyBtns = {}
		-- 故事button
		for i=1, 5 do
			local storyBtn = display.newButton(59+103*(i-1), 134, {tag = i,n = _res('ui/home/handbook/pokedex_card_btn_life_default.png')})
			layout:addChild(storyBtn, 10)

			storyBtn:setOnClickScriptHandler(handler(self, self.StoryButtonCallback))
			local lockIcon = display.newImageView(_res('ui/common/common_ico_lock.png'), storyBtn:getContentSize().width/2, storyBtn:getContentSize().height/2)
    		storyBtn:addChild(lockIcon, 7)
    		local lockSpine = sp.SkeletonAnimation:create(
    		  'effects/handbook/skeleton.json',
    		  'effects/handbook/skeleton.atlas',
    		  1)
    		lockSpine:update(0)
    		lockSpine:setToSetupPose()
    		lockSpine:setPosition(cc.p(storyBtn:getContentSize().width/2, storyBtn:getContentSize().height/2))
    		storyBtn:addChild(lockSpine, 7)
    		lockSpine:setVisible(false)

    		local lockBtnBg = display.newImageView(_res('ui/home/handbook/pokedex_card_btn_life_lock.png'), storyBtn:getContentSize().width/2, storyBtn:getContentSize().height/2)
    		storyBtn:addChild(lockBtnBg, 5)
   			local lockMask = display.newImageView(_res('ui/home/handbook/pokedex_card_btn_life_love_disabled.png'), storyBtn:getContentSize().width/2, storyBtn:getContentSize().height/2)
   			storyBtn:addChild(lockMask, 10)
   			local numIcon = display.newImageView(_res('ui/home/handbook/pokedex_card_ico_life_' .. tostring(i) .. '.png'), storyBtn:getContentSize().width/2, 185)
			storyBtn:addChild(numIcon, 7)
			-- 是否为特殊故事
			if i < 5 then

			else
				storyBtn:setNormalImage(_res('ui/home/handbook/pokedex_card_btn_life_love_default.png'))
				storyBtn:setSelectedImage(_res('ui/home/handbook/pokedex_card_btn_life_love_default.png'))
			end


   			local btnDatas = {
   				storyBtn  = storyBtn,
   				lockIcon  = lockIcon,
   				lockMask  = lockMask,
   				lockBtnBg = lockBtnBg,
   				lockSpine = lockSpine
   			}
			table.insert(storyBtns, btnDatas)
		end
		return {
			layout    = layout,
			storyBtns = storyBtns,
		}
	elseif tabType == TABTYPE.voice then -- 音频
		local voiceBg = display.newImageView(_res("ui/home/handbook/pokedex_card_bg_voice.png"), size.width/2, size.height/2)
		layout:addChild(voiceBg, 3)
		local cdBg = display.newImageView(_res('ui/home/handbook/pokedex_card_voice_bg_cd.png'), 6, size.height/2, {ap = cc.p(0, 0.5)})
		layout:addChild(cdBg, 4)
		local listBg = display.newImageView(_res('ui/home/handbook/pokedex_card_voice_bg_voice.png'), size.width - 9, 9, {ap = cc.p(1, 0)})
		layout:addChild(listBg, 4)
		local labelBg = display.newImageView(_res('ui/home/handbook/pokedex_card_voice_bg_collect.png'), size.width - 9, size.height - 9, {ap = cc.p(1, 1)})
		layout:addChild(labelBg, 5)
		local collectionLabel = display.newLabel(labelBg:getContentSize().width/2, labelBg:getContentSize().height/2, fontWithColor(16,
			{reqW = 200,text = string.fmt(__('语音收集度 _num1_/_num2_'), { ['_num1_'] = self.voiceUnlockNum, ['_num2_'] = table.nums(self.voiceDatas)})}))
		labelBg:addChild(collectionLabel)
		local cdIcon = display.newImageView(_res('ui/home/handbook/pokedex_card_voice_ico_cd_down.png'), 153, 340)
		layout:addChild(cdIcon, 5)
		local nameBg = display.newImageView(_res('ui/home/handbook/pokedex_card_voice_bg_name.png'), 153, 179)
		layout:addChild(nameBg, 5)
		nameBg:setVisible(false)
		local nameLabel = display.newLabel(153, 179, fontWithColor(18, {text = ''}))
		layout:addChild(nameLabel, 10)
		local headFrame = display.newImageView(_res('ui/home/handbook/pokedex_card_voice_btn_up.png'), 153, 340)
		layout:addChild(headFrame, 7)
		-- 头像
		local skinId   = cardMgr.GetCardSkinIdByCardId(self.cardId)
		local headPath = CardUtils.GetCardHeadPathBySkinId(skinId)
		if utils.isExistent(headPath) then
			-- 裁头像
			layout:setCascadeOpacityEnabled(true)
			local headClipNode = cc.ClippingNode:create()
			headClipNode:setCascadeOpacityEnabled(true)
			headClipNode:setPosition(cc.p(153, 340))
			layout:addChild(headClipNode, 5)
	
			local stencilNode = display.newNSprite(_res('ui/home/handbook/pokedex_card_voice_btn_head.png'), 0, 0)
			stencilNode:setScale(1)
			headClipNode:setAlphaThreshold(0.1)
			headClipNode:setStencil(stencilNode)
	
			local headNode = display.newImageView(headPath, 0, 0)
			headNode:setScale(0.75)
			headClipNode:addChild(headNode)
			self.headNode = headNode
		end
		
		local listSize = listBg:getContentSize()
		local cellSize = cc.size(listSize.width, 76)
		local gridView = CGridView:create(listSize)
		gridView:setCascadeOpacityEnabled(true)
		gridView:setSizeOfCell(cellSize)
		gridView:setColumns(1)
		gridView:setAutoRelocate(true)
		layout:addChild(gridView, 10)
		gridView:setPosition(cc.p(size.width - 9, 9))
		gridView:setAnchorPoint(cc.p(1, 0))
		gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAction))
    	gridView:setCountOfCell(table.nums(self.voiceDatas))
    	gridView:reloadData()
    	return {
    		layout    		= layout,
    		gridView  		= gridView, 
    		nameLabel 		= nameLabel,
    		nameBg    		= nameBg,
    		collectionLabel = collectionLabel
    	}
    elseif tabType == TABTYPE.information then -- 卡牌详情
    	local cardInfo = CommonUtils.GetConfig('collection', 'cardInfo', self.cardId)
		local bg = display.newImageView(_res("ui/home/handbook/pokedex_card_bg_story.png"), size.width/2, size.height/2)
		layout:addChild(bg, 3)
		local descrBg = display.newImageView(_res('ui/home/handbook/pokedex_card_bg_story_about.png'), size.width/2, size.height/2, {scale9 = true, size = cc.size(size.width-10, size.height-10)})
		layout:addChild(descrBg, 5)
		local descrDatas = {
			{name = __('食物'), descr = cardInfo.food},
			{name = __('类型'), descr = cardInfo.type},
			{name = __('发源地'), descr = cardInfo.origin},
			{name = __('诞生年代'), descr = cardInfo.age},
			{name = __('性格'), descr = cardInfo.nature},
			{name = __('身高'), descr = cardInfo.height},
			{name = __('关系')},
		}
		for i,v in ipairs(descrDatas) do
			if i ~= #descrDatas then
				local nameLabel = display.newLabel(50, 590 - 30*i, {ap = cc.p(0, 0.5), text = v.name,reqW =200, fontSize = 22, color = '#f3cea2'})
				layout:addChild(nameLabel, 10)
				local descrLabel = display.newLabel(270, 590 - 30*i, {ap = cc.p(0, 0.5), text = v.descr,reqW = 250 , fontSize = 22, color = '#fff9e6'})
				layout:addChild(descrLabel, 10)
				local line = display.newImageView(_res('ui/home/handbook/pokedex_card_line.png'), size.width/2, 575 - 30*i)
				layout:addChild(line, 10)
			else
				local nameLabel = display.newLabel(50, 550 - 30*i, {ap = cc.p(0, 0.5), text = v.name,reqW =160,  fontSize = 22, color = '#f3cea2', w = 60})
				layout:addChild(nameLabel, 10)
				if not cardInfo.nexus or next(cardInfo.nexus) == nil then
					local emptyLabel = display.newLabel(270, 340, {text = __('（空）'), fontSize = 22, color = '#ffffff', ap = cc.p(0, 0.5)})
					layout:addChild(emptyLabel, 10)
				else
					local index = 0
					for i,v in ipairs(cardInfo.nexus) do
						local datas = string.split(v, '_')
						local isExistCardConfig = app.cardMgr.IsExistConfCard(datas[2])
						if isExistCardConfig  then
							index = index +1
							local headImg = display.newImageView(AssetsUtils.GetCardHeadPath(datas[2]), 68 + index * 94, 340)
							headImg:setScale(0.46)
							layout:addChild(headImg, 8)
							local headBg = display.newImageView(_res('ui/home/handbook/pokedex_card_frame_head_down.png'), 68 + index * 94, 340)
							layout:addChild(headBg, 7)
							local path = _res('ui/home/handbook/pokedex_card_frame_head_green.png')
							if tostring(datas[1]) == 'b' then
								path = _res('ui/home/handbook/pokedex_card_frame_head_red.png')
							end
							local frame = display.newImageView(path, 68 + index * 94, 340)
							layout:addChild(frame, 10)
						end

					end
				end
				local line = display.newImageView(_res('ui/home/handbook/pokedex_card_line.png'), size.width/2, 497 - 30*i)
				layout:addChild(line, 10)
			end
		end
		-- 卡牌介绍 --
		local descrListViewSize = cc.size(450, 276)
        local descrListView = CListView:create(descrListViewSize)
        descrListView:setBounceable(false)
        descrListView:setDirection(eScrollViewDirectionVertical)
        display.commonUIParams(descrListView, {po = cc.p(size.width/2, 8), ap = cc.p(0.5, 0)})
        layout:addChild(descrListView,10)
        -- 信条 --
  		local signTitle = display.newButton(descrListViewSize.width/2, 0, {n = _res('ui/home/handbook/pokedex_card_title_black.png'), ap = cc.p(0.5, 0), enable = false,scale9 = true })
		display.commonLabelParams(signTitle, {text = __('信条'), fontSize = 22, color = '#f3cea2', paddingW = 30})
		local signLabel = display.newLabel(0, 0, {text = cardInfo.motto, fontSize = 22, color = '#fff9e6', ap = cc.p(0.5, 0), w = 450})
		local signLine = display.newImageView(_res('ui/home/handbook/pokedex_card_line.png'), size.width/2, 177)
		-- 简介 --
		local descrTitle = display.newButton(0, 0, {n = _res('ui/home/handbook/pokedex_card_title_black.png'), ap = cc.p(0.5, 0), enable = false,scale9 = true })
		display.commonLabelParams(descrTitle, {text = __('简介'), fontSize = 22, color = '#f3cea2',paddingW = 30})
		local descrLabel = display.newLabel(0, 0, {text = cardInfo.introduce, fontSize = 22, color = '#fff9e6', ap = cc.p(0.5, 0), w = 450})
		-- listViewCell
		local listViewCellSize = cc.size(450,
			5
			+ signTitle:getContentSize().height
			+ 5
			+ display.getLabelContentSize(signLabel).height
			+ 8
			+ signLine:getContentSize().height
			+ 8
			+ descrTitle:getContentSize().height
			+ 5
			+ display.getLabelContentSize(descrLabel).height
			+ 5)
        local listViewCell = CLayout:create(listViewCellSize)
        local posY = 5
        descrLabel:setPosition(listViewCellSize.width/2, posY)
        listViewCell:addChild(descrLabel)
        posY = posY + display.getLabelContentSize(descrLabel).height + 5
        descrTitle:setPosition(listViewCellSize.width/2, posY)
        listViewCell:addChild(descrTitle)
        posY = posY + descrTitle:getContentSize().height + 8
        signLine:setPosition(listViewCellSize.width/2, posY)
        listViewCell:addChild(signLine)
        posY = posY + signLine:getContentSize().height + 8
        signLabel:setPosition(listViewCellSize.width/2, posY)
        listViewCell:addChild(signLabel)
        posY = posY + display.getLabelContentSize(signLabel).height + 5
        signTitle:setPosition(listViewCellSize.width/2, posY)
        listViewCell:addChild(signTitle)
		descrListView:insertNodeAtLast(listViewCell)
		descrListView:reloadData()
		return {
			layout = layout,

		}
	end
end
--[[
刷新故事按钮状态
--]]
function CardManualMediator:RefreshStoryButtonStatus()
	for i,v in ipairs(self.storyViewDatas.storyBtns) do
		if i <= self.storyUnlockNum then
			v.lockIcon:setVisible(false)
			-- v.lockSpine:setVisible(false)
			v.lockMask:setVisible(false)
			v.lockBtnBg:setVisible(false)
			v.storyBtn:setEnabled(true)
		elseif i == self.storyUnlockNum + 1 then
			
			v.lockMask:setVisible(false)
			v.storyBtn:setEnabled(true)
			if i < self.favorabilityLevel then -- 可解锁
				if self:HasCardStory(i) then
					v.lockSpine:setVisible(true)
					v.lockSpine:setAnimation(0, 'idle', true)
					v.lockIcon:setVisible(false)
				else
					-- v.lockSpine:setVisible(false)
					v.lockIcon:setVisible(true)
				end
    		else
				-- v.lockSpine:setVisible(false)
				v.lockIcon:setVisible(true)
			end
			if i < 5 then
				v.lockBtnBg:setVisible(true)
			else
				v.lockBtnBg:setVisible(false)
			end
		else
			v.lockIcon:setVisible(true)
			-- v.lockSpine:setVisible(false)
			v.lockMask:setVisible(true)
			v.storyBtn:setEnabled(false)
			if i < 5 then
				v.lockBtnBg:setVisible(true)
			else
				v.lockBtnBg:setVisible(false)
			end
		end
	end
end
--[[
故事按钮回调
--]]
function CardManualMediator:StoryButtonCallback( sender )
	-- 添加点击音效
	PlayAudioClip(AUDIOS.UI.ui_window_open.id)
	local tag = sender:getTag()
	if not self:HasCardStory(tag) then
		uiMgr:ShowInformationTips(__('暂未开放'))
		return 
	end
	-- 判断故事是否已解锁	
	if tag > self.storyUnlockNum then -- 锁定
		-- 判断当前是否可解锁
		if tag < self.favorabilityLevel then -- 可解锁
    		self:SendSignal(COMMANDS.COMMAND_Collection_CardStoryUnlock, {cardStoryId = self.storyDatas[tag].id})
    	else
    		uiMgr:ShowInformationTips(string.fmt(__('好感度等级达到_num_解锁'), {['_num_'] = self.favorabilityLevel + 1}))
		end

	else -- 查看
		local storyOneData =  self.storyDatas[tag]
		if storyOneData.spStoryId and string.len(storyOneData.spStoryId) > 0 then
			local  storyId =  storyOneData.spStoryId
			local path = string.format("conf/%s/collection/spStory.json",i18n.getLang())
			local stage = require( "Frame.Opera.OperaStage" ).new({id = storyId, path = path, guide = false, isHideBackBtn = true, cb = function (tag)

			end})
			stage:setPosition(display.center)
			sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
			-- 走剧情的判断
			print("storyOneData.spStoryId = " , storyOneData.spStoryId)
			self.selectedStory = tag
			return
		end
		local layer = require('Game.views.CardManualStoryView').new()
		layer:setTag(5000)
		display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = display.center})
		local scene = uiMgr:GetCurrentScene()
		scene:AddDialog(layer)
		local viewData = layer.viewData_
		layer.eaterLayer:setOnClickScriptHandler(function() 
			-- 添加点击音效
			PlayAudioByClickClose()
			self.selectedStory = nil
			scene:RemoveDialog(layer)
		end)
		viewData.prevBtn:setOnClickScriptHandler(handler(self, self.StoryPageTurnCallBack))
		viewData.nextBtn:setOnClickScriptHandler(handler(self, self.StoryPageTurnCallBack))
		self.selectedStory = tag
		self:StoryPageTurnAction()
	end

end
--[[
判断剧情文案是否存在
--]]
function CardManualMediator:HasCardStory( index )
	local hasCardStory = nil
	if next(self.storyDatas) ~= nil and next(self.storyDatas[index]) ~= nil then
		hasCardStory = true
	else
		hasCardStory = false
	end
	return hasCardStory
end
--[[
切换故事按钮回调
--]]
function CardManualMediator:StoryPageTurnCallBack( sender )
	-- 添加点击音效
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag == 2001 then -- 上翻
		if self.selectedStory <=1 then
			self:StoryPageTurnAction()
		else 
			self.selectedStory = self.selectedStory - 1
			self:StoryPageTurnAction()
		end
	elseif tag == 2002 then -- 下翻
		if self.selectedStory >= 5 then
			self:StoryPageTurnAction()
		else 
			self.selectedStory = self.selectedStory + 1
			self:StoryPageTurnAction()
		end
	end
end
--[[
翻页事件
--]]
function CardManualMediator:StoryPageTurnAction()
	local scene = uiMgr:GetCurrentScene()
	if not scene:GetDialogByTag( 5000 ) then return end
	local layer = scene:GetDialogByTag( 5000 )
	if self.selectedStory <= 1 and self.selectedStory >= self.storyUnlockNum then
		layer.viewData_.prevBtn:setVisible(false)
		layer.viewData_.nextBtn:setVisible(false)
	elseif self.selectedStory <= 1 then
		layer.viewData_.prevBtn:setVisible(false)
		layer.viewData_.nextBtn:setVisible(true)
	elseif self.selectedStory >= self.storyUnlockNum then
		layer.viewData_.prevBtn:setVisible(true)
		layer.viewData_.nextBtn:setVisible(false)
	else
		layer.viewData_.prevBtn:setVisible(true)
		layer.viewData_.nextBtn:setVisible(true)
	end
	self:RefreshStoryUi()
end
--[[
刷新故事页面Ui
--]]
function CardManualMediator:RefreshStoryUi()
	local scene = uiMgr:GetCurrentScene()
	local layer = scene:GetDialogByTag( 5000 )
	local viewData = layer.viewData_
	local storyData = self.storyDatas[self.selectedStory]
	viewData.title:getLabel():setString(storyData.name)

	local descrLabel = display.newLabel(270, 0, {ap = cc.p(0.5, 0), w = 480, text = storyData.descr, color = '#5b3c25', fontSize = 24, noScale = true, ttf = true, font = TTF_TEXT_FONT})
	local descrCell = CLayout:create(cc.size(540, descrLabel:getContentSize().height+5))
	descrCell:addChild(descrLabel)
	viewData.listView:removeAllNodes()
	viewData.listView:insertNodeAtLast(descrCell)
	local placeholderCell = CLayout:create(cc.size(540, 120))
	viewData.listView:insertNodeAtLast(placeholderCell)
	viewData.listView:setContentOffsetToTop()
	viewData.listView:reloadData()
end
--[[
声音列表数据处理
--]]
function CardManualMediator:OnDataSourceAction( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local viewData = self:GetViewComponent().viewData
    local cSize = cc.size(214, 76)
    -- if self.datas and index <= table.nums(self.datas) then
        if pCell == nil then
            pCell = cardManualVoiceCell.new(cSize)
            pCell.bg:setOnClickScriptHandler(handler(self, self.VoiceButtonCallback))
        end
		xTry(function()
			if pCell.eventnode:getChildByTag(4000) then
            	pCell.eventnode:getChildByTag(4000):removeFromParent()
            end
            -- 是否播放
            if self.playVoice and index	== self.playVoice then
            	local layout = CLayout:create(cc.size(214, 76))
            	layout:setCascadeOpacityEnabled(true)
            	layout:setTag(4000)
            	layout:setPosition(utils.getLocalCenter(pCell.eventnode))
            	pCell.eventnode:addChild(layout, 10)
				local voiceIcon = display.newNSprite(_res('ui/home/handbook/pokedex_card_voice_btn_select_1.png'), cSize.width - 40, 35)
				layout:addChild(voiceIcon, 10)
    			local selectFrame = display.newImageView(_res('ui/home/handbook/pokedex_card_voice_btn_light.png'), cSize.width/2, 35)
    			layout:addChild(selectFrame, 10)
 				local animation = cc.Animation:create()
    			for i = 1, 3 do
    			    animation:addSpriteFrameWithFile(_res(string.format('ui/home/handbook/pokedex_card_voice_btn_select_%d.png', i)))
    			end
    			animation:setDelayPerUnit(0.4)
    			voiceIcon:runAction(cc.RepeatForever:create(cc.Animate:create(animation)))
            end
			pCell.nameLabel:setString(string.format('%0.2d', index))
			pCell.bg:setTag(index)
			-- 更新按钮状态
			local datas = self.voiceDatas[index]
			if datas.isLock then
				pCell.lockIcon:setVisible(true)
				pCell.lockSpine:setVisible(false)
				pCell.bg:setSelectedImage(_res('ui/home/handbook/pokedex_card_voice_btn_lock.png'))
				pCell.bg:setNormalImage(_res('ui/home/handbook/pokedex_card_voice_btn_lock.png'))
			else
				-- 判断是否已解锁
				if gameMgr:GetUserInfo().cardVoice[tostring(datas.id)] then
					pCell.lockIcon:setVisible(false)
					pCell.lockSpine:setVisible(false)
					pCell.bg:setSelectedImage(_res('ui/home/handbook/pokedex_card_voice_btn_default.png'))
					pCell.bg:setNormalImage(_res('ui/home/handbook/pokedex_card_voice_btn_default.png'))
				else
					pCell.lockIcon:setVisible(false)
					pCell.lockSpine:setVisible(true)
					pCell.lockSpine:update(0)
					pCell.lockSpine:setToSetupPose()
					pCell.lockSpine:setAnimation(0, 'idle', true)
					pCell.bg:setSelectedImage(_res('ui/home/handbook/pokedex_card_voice_btn_default.png'))
					pCell.bg:setNormalImage(_res('ui/home/handbook/pokedex_card_voice_btn_default.png'))
				end
			end
		end,__G__TRACKBACK__)
        return pCell
    -- end
end
--[[
音频按钮点击回调
--]]
function CardManualMediator:VoiceButtonCallback( sender )
	local tag = sender:getTag()
	local viewData = self:GetViewComponent().viewData
	-- 判断按钮状态
	if self.voiceDatas[tag].isLock then
		PlayAudioByClickNormal()
		uiMgr:ShowInformationTips((string.fmt(__('好感度等级达到_num_解锁'), {['_num_'] = self.voiceDatas[tag].unlockType['8'].targetNum})))
	else
		if gameMgr:GetUserInfo().cardVoice[tostring(self.voiceDatas[tag].id)] then
			-- 停止当前动作
			self:GetViewComponent():stopAllActions()
			self.headNode:stopAllActions()
		
			-- 更新音频名称
			self.voiceViewDatas.nameBg:setVisible(true)
			self.voiceViewDatas.nameLabel:setString(string.format('%0.2d ', tag) .. self.voiceDatas[tag].name)
			local cueSheet = tostring(self.voiceDatas[tag].roleId)
			local cueName = self.voiceDatas[tag].voiceId
			local acbFile = audioMgr:GetVoicePathByName(cueSheet, PLAY_VOICE_TYPE.JAPANESE)
			if audioMgr:GetVoiceType() == PLAY_VOICE_TYPE.CHINESE then
				local cueSheetCn = tostring(self.voiceDatas[tag].roleIdCn)
				if self.voiceDatas[tag].roleIdCn  and string.len(tostring(self.voiceDatas[tag].roleIdCn)) ==  0  then
					uiMgr:ShowInformationTips(__("语音准备中，暂不开放。"))
					return
				end
				if audioMgr:CheckChineseVoiceComplete(string.format('%s.acb', cueSheetCn) ) then
					acbFile = audioMgr:GetVoicePathByName(cueSheetCn, PLAY_VOICE_TYPE.CHINESE)
					if isElexSdk() then
						cueName  = string.match(self.voiceDatas[tag].voiceCodeCn,"cn_(.+)")
						cueSheet =string.match(self.voiceDatas[tag].roleIdCn ,"cn_(.+)")
					else
						cueName  = self.voiceDatas[tag].voiceCodeCn
						cueSheet = self.voiceDatas[tag].roleIdCn
					end
				else
					if not  utils.isExistent(acbFile) then
						uiMgr:ShowInformationTips(__("语音准备中，暂不开放。"))
						return
					else
						uiMgr:ShowInformationTips(__("语音文件不完整，请下载语音包。"))
						return
					end
				end
			end
			if not  utils.isExistent(acbFile) then
				uiMgr:ShowInformationTips(__("语音准备中，暂不开放。"))
			end
			-- 添加播放动画
			if self.playVoice then
				local cell = self.voiceViewDatas.gridView:cellAtIndex(self.playVoice-1)
				if cell and cell.eventnode:getChildByTag(4000) then
					self.voiceViewDatas.gridView:cellAtIndex(self.playVoice-1).eventnode:getChildByTag(4000):removeFromParent()
				end
				-- 停止正在播放的音频
				audioMgr:StopAudioClip(cueSheet, true)
			end
			local eventnode = self.voiceViewDatas.gridView:cellAtIndex(tag-1).eventnode
			local layout = CLayout:create(cc.size(214, 76))
    		layout:setTag(4000)
    		layout:setPosition(utils.getLocalCenter(eventnode))
    		eventnode:addChild(layout, 10)
			local voiceIcon = display.newNSprite(_res('ui/home/handbook/pokedex_card_voice_btn_select_1.png'), 214 - 40, 35)
			local selectFrame = display.newImageView(_res('ui/home/handbook/pokedex_card_voice_btn_light.png'), 107, 35)
   			layout:addChild(selectFrame, 10)
 			local animation = cc.Animation:create()
    		for i = 1, 3 do
    		    animation:addSpriteFrameWithFile(_res(string.format('ui/home/handbook/pokedex_card_voice_btn_select_%d.png', i)))
    		end
    		animation:setDelayPerUnit(0.4)
    		voiceIcon:runAction(cc.RepeatForever:create(cc.Animate:create(animation)))
    		layout:addChild(voiceIcon, 10)
    		-- 播放音频
    		if utils.isExistent(acbFile) then
				audioMgr:AddCueSheet(cueSheet, acbFile)
				audioMgr:PlayAudioClip(cueSheet, cueName)
			end
			-- 获取cue时长
			local time = app.audioMgr:GetPlayerCueTime(cueSheet, cueName)
			if time > 0 then
				self:GetViewComponent():runAction(
					cc.Sequence:create(
						cc.DelayTime:create(tonumber(time)),
						cc.CallFunc:create(function ()
							if self.playVoice then
								local cell = self.voiceViewDatas.gridView:cellAtIndex(self.playVoice-1)
								if cell and cell.eventnode:getChildByTag(4000) then
									cell.eventnode:getChildByTag(4000):removeFromParent()
								end
								-- 清除对话框
								if viewData.view:getChildByTag(6000) then
									viewData.view:getChildByTag(6000):runAction(
										cc.Sequence:create(
											cc.ScaleTo:create(0.1, 0),
											cc.RemoveSelf:create()
											)
										)
								end
								self.headNode:stopAllActions()
								local angle = self.headNode:getRotation()%360
								self.headNode:runAction(cc.RotateBy:create((360-angle)/360, 360-angle))
								-- self.headNode:setRotation(0)
								self.playVoice = nil
							end
						end)
					)
				)
			end
			-- 添加对话框
			if viewData.view:getChildByTag(6000) then
				viewData.view:getChildByTag(6000):removeFromParent()
			end
			local dialogBg = display.newImageView(_res('arts/stage/ui/dialogue_bg_2.png'), 367 + display.SAFE_L, display.cy - 150, {tag = 6000})
			viewData.view:addChild(dialogBg, 10)
			dialogBg:setScale(0.5)
			dialogBg:runAction(
				cc.Sequence:create(
					cc.EaseBackOut:create(cc.ScaleTo:create(0.3, 1)),
					cc.CallFunc:create(function ()
						local dialogString = ''
						if audioMgr:GetVoiceType() == PLAY_VOICE_TYPE.CHINESE then
							dialogString = tostring(self.voiceDatas[tag].descrCn)
						else
							dialogString = tostring(self.voiceDatas[tag].descr)
						end
						local dialogLabel = display.newLabel(70, 160, {ap = cc.p(0, 1), text = self.voiceDatas[tag].descr, fontSize = 24, color = '#5b3c25', w = 720})
						dialogBg:addChild(dialogLabel)
						dialogLabel:setVisible(false)
						dialogLabel:runAction(
							cc.Sequence:create(
								TypewriterAction:create(time*0.3),
								cc.DelayTime:create(0.1),
								cc.CallFunc:create(function ()
									dialogLabel:setVisible(true)
								end)
							)
						)
					end)
				)
			)
    		-- 头像动画
    		self.headNode:runAction(cc.RotateBy:create(time, time*50)
    		)
    		-- 更新本地数据
    		self.selectedVoice = tag 
    		self.playVoice = tag
    	else
    		PlayAudioClip(AUDIOS.UI.ui_tab_change.id)
			-- 解锁音频
			self:SendSignal(COMMANDS.COMMAND_Collection_CardVoiceUnlock, {cardVoiceId = self.voiceDatas[tag].id})
		end
	end
end
--[[
初始化音频数据
@params cardId int 卡牌Id
--]]
function CardManualMediator:InitVoiceDatas( cardId )
	local orderDatas = CommonUtils.GetConfig('collection', 'cardVoiceOrder', cardId)
	self.voiceUnlockNum = 0
	for _, v in ipairs(orderDatas) do
		local voice = CardUtils.GetCardVoiceConfigByCardId(cardId, v)
		voice.isLock = CommonUtils.CheckLockCondition(voice.unlockType)
		table.insert(self.voiceDatas, voice)
		if gameMgr:GetUserInfo().cardVoice[tostring(voice.id)] then
			self.voiceUnlockNum = self.voiceUnlockNum + 1
		end
	end
end
--[[
初始化故事数据
@params cardId int 卡牌Id
--]]
function CardManualMediator:InitStoryDatas( cardId )
	local orderDatas = CommonUtils.GetConfig('collection', 'cardStoryOrder', cardId)
	if not orderDatas then return end
	self.storyUnlockNum = 0
	for _, v in ipairs(orderDatas) do
		if gameMgr:GetUserInfo().cardStory[tostring(v)] then
			self.storyUnlockNum = self.storyUnlockNum + 1
		end
		local story = CardUtils.GetCardStoryConfigByCardId(cardId, v)
		if story then
			table.insert(self.storyDatas, story)
		else
			table.insert(self.storyDatas, {})
		end
	end
end
----------------------------------------------------
-----------------------皮肤切换----------------------
--[[
皮肤列表处理
--]]
function CardManualMediator:OnSkinDataSourceAction( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(125, 140)
    if pCell == nil then
        pCell = CardManualSkinCell.new(cSize)
		pCell.frame:setOnClickScriptHandler(handler(self, self.SkinIconButtonCallback))
    end
	xTry(function()
		pCell.frame:setTag(index)
		local skinId = self:GetSkinId(index)
		local skinConf = CardUtils.GetCardSkinConfig(skinId)
		pCell.headIcon:setTexture(CardUtils.GetCardHeadPathBySkinId(skinId))
		pCell.nameLabel:setString(skinConf.name)
		if app.cardMgr.IsHaveCardSkin(skinId) then
			pCell.lockMask:setVisible(false)
			pCell.lockIcon:setVisible(false)

		else
			pCell.lockMask:setVisible(true)
			pCell.lockIcon:setVisible(true)
		end
		if index == checkint(self.selectedSkinIndex) then
			pCell.selectFrame:setVisible(true)
		else
			pCell.selectFrame:setVisible(false)
		end
		-- 判断滚动状态
		if pCell:IsNeedScroll() then
			if index == checkint(self.selectedSkinIndex) then
				pCell:StartScrollAction()
			else
				pCell:StopScrollAction()
			end
		else
			pCell:StopScrollAction()
		end
	end,__G__TRACKBACK__)
    return pCell
end
--[[
更新外观收集进度
--]]
function CardManualMediator:UpdateSkinProgress()
	local skinNums = 0
	for i,v in ipairs(self.skinDatas) do
		if app.cardMgr.IsHaveCardSkin(self:GetSkinId(i)) then
			skinNums = skinNums + 1
		end
	end
	local progressNum = self:GetViewComponent().viewData.progressNum
	progressNum:setString(string.format('%d/%d', skinNums, #self.skinDatas))
end
--[[
皮肤icon点击回调
--]]
function CardManualMediator:SkinIconButtonCallback( sender )
	local tag = 0
	if type(sender) == 'number' then
		tag = sender
	else
		tag = sender:getTag()
		-- 添加点击音效
		if self.selectedSkinIndex == tag then
			return
		end 
	end
	-- 添加点击音效
	PlayAudioByClickNormal()
	local viewData = self:GetViewComponent().viewData
	-- 清空原有的选中状态
	local lastCell = viewData.skinGridView:cellAtIndex(self.selectedSkinIndex - 1)
	if lastCell then
		lastCell.selectFrame:setVisible(false)
		-- 判断皮肤名是否过长需要滚动
		if lastCell:IsNeedScroll() then
			lastCell:StopScrollAction()
		end
	end
	-- 添加新的选中状态
	local newCell = viewData.skinGridView:cellAtIndex(tag - 1)
	if newCell then
		newCell.selectFrame:setVisible(true)
		-- 判断皮肤名是否过长需要滚动
		if newCell:IsNeedScroll() then
			newCell:StartScrollAction()
		end
	end
	self.selectedSkinIndex = tag
	self:RefreshCardDraw()
	self.showSpine = false
	self:SwitchAction(false)
end
--[[
更新角色立绘
--]]
function CardManualMediator:RefreshCardDraw()
	local viewData = self:GetViewComponent().viewData
	local skinId = self:GetSkinId(self.selectedSkinIndex)
	if app.cardMgr.IsHaveCardSkin(skinId) then
		viewData.jumpLayout:setVisible(false)
		viewData.switchBtn:setVisible(true)
		viewData.cardBtn:setVisible(true)
		viewData.cardDraw:RefreshAvatar({skinId = skinId})
		viewData.cardDraw:setFilterName()
	else
		viewData.jumpLayout:setVisible(true)
		viewData.switchBtn:setVisible(false)
		viewData.cardBtn:setVisible(false)
		viewData.cardDraw:RefreshAvatar({skinId = skinId})
		viewData.cardDraw:setFilterName(filter.TYPES.GRAY)
	end
end
--[[
获取皮肤id
--]]
function CardManualMediator:GetSkinId( index )
	return self.skinDatas[index]
end
--[[
获取按钮点击回调
--]]
function CardManualMediator:JumpButtonCallback( sender )
	uiMgr:AddDialog("common.GainPopup", {goodId = self:GetSkinId(self.selectedSkinIndex)})
end
--[[
切换按钮点击回调
--]]
function CardManualMediator:SwitchButtonCallback( sender )
	self.showSpine = not self.showSpine
	self:SwitchAction(self.showSpine)
end
--[[
切换逻辑
--]]
function CardManualMediator:SwitchAction( isShow )
	local viewData = self:GetViewComponent().viewData
	if isShow then
		viewData.switchBtn:setNormalImage(_res('ui/home/handbook/pokedex_card_btn_card.png'))
		viewData.switchBtn:setSelectedImage(_res('ui/home/handbook/pokedex_card_btn_card.png'))
		viewData.cardDraw:setVisible(false)
		-- 创建spine
		local skinId  = self:GetSkinId(self.selectedSkinIndex)
		local qAvatar = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 0.75})
		qAvatar:setTag(1)
    	qAvatar:update(0)
    	qAvatar:setToSetupPose()
    	qAvatar:setAnimation(0, 'idle', true)
    	qAvatar:setPosition(cc.p(500 + display.SAFE_L, 140))
    	qAvatar:setName('cardSpine')
    	viewData.view:addChild(qAvatar, 9)
	else
		viewData.switchBtn:setNormalImage(_res('ui/home/handbook/pokedex_card_btn_qban.png'))
		viewData.switchBtn:setSelectedImage(_res('ui/home/handbook/pokedex_card_btn_qban.png'))
		viewData.cardDraw:setVisible(true)
		if viewData.view:getChildByName('cardSpine') then
			viewData.view:getChildByName('cardSpine'):runAction(cc.RemoveSelf:create())
		end
	end
end
function CardManualMediator:RefreshSkinList()
	local viewData = self:GetViewComponent().viewData
    viewData.skinGridView:reloadData()
    self:UpdateSkinProgress()
    self:SkinIconButtonCallback(self.selectedSkinIndex)
end
-----------------------皮肤切换----------------------
----------------------------------------------------


function CardManualMediator:OnRegist(  )
	local CardManualCommand = require('Game.command.CardManualCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Collection_CardVoiceUnlock, CardManualCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Collection_CardStoryUnlock, CardManualCommand)
end
function CardManualMediator:OnUnRegist(  )
	-- 称出命令
	local scene = uiMgr:GetCurrentScene()
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Collection_CardVoiceUnlock)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Collection_CardStoryUnlock)

	---@type Facade
	local facade  = self:GetFacade()
	---@type CardEncyclopediaMediator
	local mediator = facade:RetrieveMediator("CardEncyclopediaMediator")

	if mediator then
		mediator:GetViewComponent():runAction(cc.Sequence:create(
				cc.Spawn:create(
					cc.TargetedAction:create( self:GetViewComponent() ,
						cc.Sequence:create(cc.EaseSineInOut:create(cc.FadeOut:create(8/30) ) ,
							cc.CallFunc:create(function ()
								scene:RemoveDialog(self:GetViewComponent())
							end)
						)
					),
					cc.Sequence:create(
						cc.CallFunc:create(function ()
							mediator:GetViewComponent():setOpacity(0)
						end ),
						cc.EaseSineInOut:create(cc.FadeIn:create(8/30))
					)

				)
			)
		)
	else
		scene:RemoveDialog(self:GetViewComponent())
	end
end

return CardManualMediator
