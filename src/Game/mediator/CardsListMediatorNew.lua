--[[
	卡牌列表
]]
local Mediator = mvc.Mediator

local CardsListMediatorNew = class("CardsListMediatorNew", Mediator)
local CardViewCell = require('home.CardViewCell')

local NAME = "CardsListMediatorNew"
CardsList_ChangeCenterContainer = 'CardsList_ChangeCenterContainer'
CardDetail_StarUp_callback = "CardDetail_StarUp_callback"
CardDetail_ShowStar_callback = "CardDetail_ShowStar_callback"
CardsFragmentCompose_Callback = 'CardsFragmentCompose_Callback'
CardsLove_Callback = 'CardsLove_Callback'
local CardDetailActionSignal	= "CardDetailActionSignal"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local CardsListCellNew = require('Game.views.CardsListCellNew')
local PAGESIZE = 6

--英雄卡牌属性
local propertyData = {
	{pName = ObjP.ATTACK, 	name = __('攻击力'), 	label = nil,path = 'ui/common/role_main_att_ico.png'},
	{pName = ObjP.DEFENCE, 	name = __('防御力'), 	label = nil,path = 'ui/common/role_main_def_ico.png'},
	{pName = ObjP.HP, 		name = __('生命值'), 	label = nil,path = 'ui/common/role_main_hp_ico.png'},
	{pName = ObjP.CRITRATE, name = __('暴击值'), 		label = nil,path = 'ui/common/role_main_baoji_ico.png'},
	{pName = ObjP.CRITDAMAGE, 	name = __('暴伤值'), 	label = nil,path = 'ui/common/role_main_baoshangi_ico.png'},
	{pName = ObjP.ATTACKRATE, 	name = __('攻速值'), 	label = nil,path = 'ui/common/role_main_speed_ico.png'}
}

local screenType = {
	{tag = 0, descr = __('筛选')},
	{tag = 1, descr = CardUtils.GetCardCareerName(CardUtils.CAREER_TYPE.DEFEND)},
	{tag = 2, descr = CardUtils.GetCardCareerName(CardUtils.CAREER_TYPE.ATTACK)},
	{tag = 3, descr = CardUtils.GetCardCareerName(CardUtils.CAREER_TYPE.ARROW)},
	{tag = 4, descr = CardUtils.GetCardCareerName(CardUtils.CAREER_TYPE.HEART)},
	{tag = 5, descr = __('碎片')},
	{tag = 6, descr = __('神器')},
}

local sortType = {
	{tag = 0, descr = __('排序')},
	{tag = 1, descr = __('等级')},
	{tag = 2, descr = __('稀有度')},
	{tag = 3, descr = __('灵力')},
	{tag = 4, descr = __('星级')},
	{tag = 5, descr = __('好感度')},
	{tag = 6, descr = __('编队信息')},
}

function CardsListMediatorNew:ctor(params, viewComponent )
	-- dump(params)
	if params and next(params) ~= nil then
		if not params.x and app.cardMgr.IsHaveCard(params.cardId) then
			self.args = params
		else
			self.args = nil
		end
	else
		self.args = nil
	end
	self.super:ctor(NAME,viewComponent)
	self.clickBtn = nil -- 点击的cell
	self.clickGoToMessBtn = nil --点击cell查看按钮
	self.rightView = nil -- 右边属性堕神技能view
	self.leftView = nil	-- 右边立绘显示view
	self.leftSwichBtn = nil --左箭头
	self.rightSwichBtn = nil--右箭头

	self.composeNum = 0
	self.offsetY = 0
	self.clickTag = 1 --点击cell的tag
	self.oldLevel = 0 --点击升级页面时候的等级
	self.longClickLevel = 0--长按点击升级页面时候的等级
	self.maxLevel = 0	--选择卡牌能达到最高等级
	self.selectSortTag = (params and checkint(params.sortIndex) )  or 0    -- 选取的排列方式
	self.selectPlayerCardId = (params and params.selectPlayerCardId )
	--BshowLevelUpAction == 1 时表示为单击吃经验药水 会播经验条动画
	--BshowLevelUpAction == 2 时表示为长按吃经验药水 不会播经验条动画
	--BshowLevelUpAction == 3 时表示为正常显示进度条经验
	--BshowLevelUpAction == 4 时表示为一键升级
	self.BshowLevelUpAction = 3

	self.modelTag = 1 --选择卡牌详情具体模块

	self.cardDetailMediator = nil

	self.showStar = false -- 是否播放升星动画

	self.sortBtnState = {}--排序按钮状态

	self.TtimeUpdateFunc = nil --喂食倒计时计时器

	self.allCardConfs_ = CommonUtils.GetConfigAllMess('card' , 'card')
end
function CardsListMediatorNew:InterestSignals()
	local signals = {
		CardsList_ChangeCenterContainer,
		CardDetailActionSignal,
		CardDetail_StarUp_callback,
		CardDetail_ShowStar_callback,
		CardsFragmentCompose_Callback,
		CardsLove_Callback,
		EVENT_CARD_MARRY,
		SIGNALNAMES.Hero_LevelUp_Callback,
		SIGNALNAMES.Hero_OneKeyLevelUp_Callback,
		SIGNALNAMES.Hero_Compose_Callback,
		SIGNALNAMES.Hero_SetSignboard_Callback,
		'Hero_Break_show_card_voice_word',
		POST.ALTER_CARD_NICKNAME.sglName , -- 修改飨灵昵称
	}
	return signals
end
function CardsListMediatorNew:ProcessSignal(signal )
	local name = signal:GetName()
	-- dump(name)
	if name == CardsList_ChangeCenterContainer then--刷新列表ui
		-- --更新UI
		if signal:GetBody() == 'showStar' then
			self.showStar = true
		end
		self:UpdataLeftUi(self.clickTag)
		self:UpdataRightUi()

		local pCell = self:GetCellAtIndex(self.clickTag)
		if pCell then
			local skinId   = cardMgr.GetCardSkinIdByCardId(self.cardsData[self.clickTag].cardId)
			local headPath = CardUtils.GetCardHeadPathBySkinId(skinId)
			pCell.headImg:setTexture(headPath)
		end
	elseif name == POST.ALTER_CARD_NICKNAME.sglName then -- 飨灵修改昵称
		local scene = uiMgr:GetCurrentScene()
		scene:RemoveDialogByName('AlterNicknamePopup')

		uiMgr:ShowInformationTips(__('昵称修改成功'))

		local cardData = gameMgr:GetCardDataById(signal:GetBody().requestData.playerCardId)
		cardData.cardName = signal:GetBody().cardName

		if self:GetFacade():RetrieveMediator('CardDetailMediatorNew') then
			self:GetFacade():RetrieveMediator('CardDetailMediatorNew'):updataUi({data =  self.cardsData[self.clickTag]} )
		end
		local curCell = self:GetCellAtIndex(self.clickTag)
		if curCell then
			CommonUtils.SetCardNameLabelStringById(curCell.heroNameLabel, signal:GetBody().requestData.playerCardId, curCell.nameLabelParams)
			display.commonLabelParams(curCell.heroNameLabel ,{reqW = 250})
		end
	elseif name == EVENT_CARD_MARRY then -- 飨灵结婚成功
		if self:GetFacade():RetrieveMediator('CardDetailMediatorNew') then
			local cardData = self.cardsData[self.clickTag] or {}
			local  cardDataTwo = gameMgr:GetCardDataById(cardData.id)
			cardData.favorabilityLevel = cardDataTwo.favorabilityLevel or 1
			self:GetFacade():RetrieveMediator('CardDetailMediatorNew'):updataUi({data = cardData } )
		end
		local curCell = self:GetCellAtIndex(self.clickTag)
		if curCell then
			CommonUtils.SetCardNameLabelStringById(curCell.heroNameLabel, signal:GetBody().playerCardId, curCell.nameLabelParams)
			display.commonLabelParams(curCell.heroNameLabel , { reqW =250  })
		end
		local viewData = self:GetViewComponent().viewData
		local particleSpine = viewData.particleSpine
		if particleSpine then particleSpine:setVisible(true) end

		self.cardsData[self.clickTag].favorabilityLevel = tostring(signal:GetBody().favorabilityLevel)

		local path = string.format('ui/cards/love/card_btn_contract_%d.png',signal:GetBody().favorabilityLevel)
		if not utils.isExistent(path) then
			path = 'ui/cards/love/card_btn_contract_1.png'
		end
		viewData.contractBtn:setNormalImage(_res(path))
		viewData.contractBtn:setSelectedImage(_res(path))
	elseif name == CardsLove_Callback then--刷新好感度等级显示ui
		local viewData = self:GetViewComponent().viewData
		local heroImg = viewData.heroImg
		local btnSpine = sp.SkeletonAnimation:create('effects/contract/lihuihaogan.json', 'effects/contract/lihuihaogan.atlas', 1)
		btnSpine:update(0)
		btnSpine:setAnimation(0, 'play1', false)--shengxing1 shengji
		uiMgr:GetCurrentScene():addChild(btnSpine,100)
		btnSpine:setPosition(cc.p(heroImg:getContentSize().width* 0.25,heroImg:getContentSize().height* 0.5))

		btnSpine:registerSpineEventHandler(function (event)
			if event.animation == "play1" then
				print("====== hit end ====")
				btnSpine:runAction(cc.RemoveSelf:create())
			end
		end, sp.EventType.ANIMATION_END)

		local  showContractAction = signal:GetBody()
		if showContractAction == 1 then--未升级
			local loveLabel = viewData.loveLabel
			local loveBar = viewData.loveBar
			local data  = self.cardsData[self.clickTag]

			local favorabilityData = CommonUtils.GetConfig('cards', 'favorabilityLevel', checkint(data.favorabilityLevel))

			local nowLvExp = (checkint(data.favorability) - CommonUtils.GetConfig('cards', 'favorabilityLevel',data.favorabilityLevel).totalExp)
			-- local needLvExp = (CommonUtils.GetConfig('cards', 'favorabilityLevel',data.favorabilityLevel+1).exp or 999999)

			local needLvExp = 0
			if CommonUtils.GetConfig('cards', 'favorabilityLevel',data.favorabilityLevel+1) then
				needLvExp = (CommonUtils.GetConfig('cards', 'favorabilityLevel',data.favorabilityLevel+1).exp or 999999)
			else
				needLvExp = (CommonUtils.GetConfig('cards', 'favorabilityLevel',data.favorabilityLevel).exp or 999999)
			end

			if nowLvExp < 0 then
				nowLvExp = 0
			end

			loveLabel:setString(nowLvExp..'/'..needLvExp )--..'好感度等级：'..data.favorabilityLevel

			if checkint(data.favorabilityLevel) >= 6 then
				loveBar:setPercentage(100)
			else
				local percent = nowLvExp / needLvExp * 100
				loveBar:setPercentage(percent)
			end
			viewData.contractBtn:getLabel():setString(favorabilityData.name or __('契约'))


			local path = string.format('ui/cards/love/card_btn_contract_%d.png',data.favorabilityLevel)
			if not utils.isExistent(path) then
				path = 'ui/cards/love/card_btn_contract_1.png'
			end
			viewData.contractBtn:setNormalImage(_res(path))
			viewData.contractBtn:setSelectedImage(_res(path))


			local btnGlowImg = viewData.btnGlowImg
			btnGlowImg:setVisible(cardMgr.GetMarriable(data.id))
		else--升级了播升级特效

		end
		uiMgr:GetCurrentScene():RemoveViewForNoTouch()
	elseif name == SIGNALNAMES.Hero_LevelUp_Callback then-- 卡牌升级
		--更新UI
		-- print(' 英雄升级 ')
		local data = checktable(signal:GetBody())
		if data.errcode then--网络请求出错，恢复卡牌数据显示
			self.BshowLevelUpAction = 1
			self:UpdataLeftUi(self.clickTag)
			self:UpdataRightUi()
		else
			PlayAudioClip(AUDIOS.UI.ui_levelup.id)

			local cardData  = gameMgr:GetCardDataById(self.cardsData[self.clickTag].id) or {}
			local oldLevel  = checkint(cardData.level)
			local isLevelUp = checkint(data.level) > oldLevel
			-- dump(data)
			gameMgr:UpdateCardDataById(self.cardsData[self.clickTag].id, {level = data.level,exp = data.exp})

			local num = checkint(data.goodsNum) - gameMgr:GetAmountByGoodId(checkint(data.goodsId))
			CommonUtils.DrawRewards({{goodsId = checkint(data.goodsId), num = num}})
			self.cardsData[self.clickTag].level = data.level
			self.cardsData[self.clickTag].exp = data.exp
			self.BshowLevelUpAction = data.requestData.BshowLevelUpAction
			self:UpdataLeftUi(self.clickTag)
			self:UpdataRightUi()

			if isLevelUp then
				self:showMainCardVoiceWord_(cardData.cardId, SoundType.TYPE_UPGRADE_STAR, false)

				--刷新图鉴
				self:GetFacade():DispatchObservers(SGL.CARD_COLL_RED_DATA_UPDATE, {cardId = self.cardsData[self.clickTag].cardId, taskType = CardUtils.CARD_COLL_TASK_TYPE.LEVEL_NUM, addNum = checkint(data.level) - oldLevel})
			end

		end
		--刷新吃经验药界面（经验品数量刷新
		local cardDetailUpgradePopup = self:GetViewComponent():GetDialogByTag(444)
		if cardDetailUpgradePopup then
			cardDetailUpgradePopup:refreshUI(self.cardsData[self.clickTag])
		end
		if self:GetFacade():RetrieveMediator('CardDetailMediatorNew') then
			self:GetFacade():RetrieveMediator('CardDetailMediatorNew'):updataUi({data =  self.cardsData[self.clickTag]} )
		end
	elseif name == SIGNALNAMES.Hero_OneKeyLevelUp_Callback then--一键升级
		PlayAudioClip(AUDIOS.UI.ui_levelup.id)
		local data = checktable(signal:GetBody())
		gameMgr:UpdateCardDataById(self.cardsData[self.clickTag].id, {level = data.level,exp = data.exp})
		-- dump(data)
		self.cardsData[self.clickTag].level = data.level
		self.cardsData[self.clickTag].exp = data.exp
		for k,v in pairs(data.consumesGoods) do
			gameMgr:UpdateBackpackByGoodIdCoverNum(k, v)
		end
		self.BshowLevelUpAction = 4
		self:UpdataLeftUi(self.clickTag)
		self:UpdataRightUi()
		local cardDetailUpgradePopup = self:GetViewComponent():GetDialogByTag(444)
		if cardDetailUpgradePopup then
			cardDetailUpgradePopup:refreshUI(self.cardsData[self.clickTag])
			cardDetailUpgradePopup:removeFromParent()
		end
		local cardData = gameMgr:GetCardDataById(self.cardsData[self.clickTag].id)
		self:showMainCardVoiceWord_(cardData.cardId, SoundType.TYPE_UPGRADE_STAR)
		if self:GetFacade():RetrieveMediator('CardDetailMediatorNew') then
			self:GetFacade():RetrieveMediator('CardDetailMediatorNew'):updataUi({data =  self.cardsData[self.clickTag]} )
		end

		--刷新图鉴
		self:GetFacade():DispatchObservers(SGL.CARD_COLL_RED_DATA_UPDATE, {cardId = self.cardsData[self.clickTag].cardId, taskType = CardUtils.CARD_COLL_TASK_TYPE.LEVEL_NUM})
	elseif  name == 'Hero_Break_show_card_voice_word' then
		local data = checktable(signal:GetBody())
		self:showMainCardVoiceWord_(data.cardId, SoundType.TYPE_UPGRADE_STAR)
	elseif  name == CardDetail_StarUp_callback then
		self:ShowAddPropertyLabelAction(1)
		-- self:showStarrr()
	elseif  name == CardDetail_ShowStar_callback then
		-- self:showStar()
		self:showStarrr()
	elseif name == SIGNALNAMES.Hero_Compose_Callback then--合成卡牌
		-- dump(signal:GetBody())
		local scene = uiMgr:GetCurrentScene()
		scene:AddViewForNoTouch()

		
		local cardConf = clone(self.allCardConfs_[tostring(signal:GetBody().requestData.cardId)])
		cardConf.id = signal:GetBody().playerCardId
		cardConf.cardId = signal:GetBody().requestData.cardId
		gameMgr:UpdateCardDataById(signal:GetBody().playerCardId, cardConf)



		local goodsid = 0
		goodsid  = checkint(signal:GetBody().requestData.cardId)%200000
		goodsid = goodsid+140000

		local composNum = CommonUtils.GetConfig('cards', 'cardConversion',cardConf.qualityId).composition
		gameMgr:UpdateBackpackByGoodId(goodsid, composNum*(-1))


		self.cardsData[self.composeNum].showFragment = 2
		table.merge(self.cardsData[self.composeNum], gameMgr:GetCardDataByCardId(signal:GetBody().requestData.cardId))
		local viewData = self:GetViewComponent().viewData
		-- uiMgr:ShowInformationTips(('我是合成特效'))
		local heroImg = viewData.heroImg
		local btnSpine = sp.SkeletonAnimation:create('effects/cardCompose/hechen.json', 'effects/cardCompose/hechen.atlas', 1)
		btnSpine:update(0)
		btnSpine:setAnimation(0, 'play', false)--shengxing1 shengji
		uiMgr:GetCurrentScene():addChild(btnSpine,100)
		btnSpine:setPosition(cc.p(heroImg:getContentSize().width* 0.25,heroImg:getContentSize().height* 0.55))

		btnSpine:registerSpineEventHandler(function (event)
			if event.eventData.name == 'effect' then
				local cardId = signal:GetBody().requestData.cardId
				local skinId   = app.cardMgr.GetCardSkinIdByCardId(cardId)
				local drawName = CardUtils.GetCardDrawNameBySkinId(skinId)
				local heroImgS = AssetsUtils.GetCardDrawNode(drawName)
				heroImgS:setAnchorPoint(cc.p(0.5,0.5))
				heroImgS:setScale(heroImg:GetAvatar():getScale())
				heroImgS:setPosition(cc.p(heroImg:GetAvatar():getPositionX()+heroImg:GetAvatar():getContentSize().width*heroImg:GetAvatar():getScale()*0.5,heroImg:GetAvatar():getPositionY()))
				heroImg:getParent():addChild(heroImgS,20)
				heroImgS:setFilterName(filter.TYPES.GRAY)
				heroImgS:runAction(
						cc.Sequence:create(
								cc.DelayTime:create(0.1),
								cc.Spawn:create(
										cc.ScaleTo:create(0.3, 1.1),
										cc.FadeOut:create(0.3)
								),
								cc.CallFunc:create(function ()
									heroImgS:runAction(cc.RemoveSelf:create())
								end)
						)
				)
				self:UpdataLeftUi(self.composeNum)
				viewData.heroMessLayout:setVisible(true)

				self:ScreenCards(0, true, cardId)
				viewData.screenLabel:setString(screenType[1].descr)
				viewData.screenLabel:setColor(ccc3FromInt('#ffffff'))
				scene:RemoveViewForNoTouch()
			end
		end,sp.EventType.ANIMATION_EVENT)

	elseif name == CardsFragmentCompose_Callback then
		xTry(function()
			self.selectPlayerCardId = checktable(self.cardsData[self.clickTag]).id
			self:ScreenCards(0)
			local mediator = self:GetFacade():RetrieveMediator('CardDetailMediatorNew')
			if  mediator then
				mediator:updataUi({data = self.cardsData[self.clickTag],showSkillIndex = 1,showModel = 1 ,isFirst = false, isShowAction = false} )
			end
		end,__G__TRACKBACK__)
	elseif name == SIGNALNAMES.Hero_SetSignboard_Callback then -- 设置主页面看板娘
		local viewData = self:GetViewComponent().viewData
		uiMgr:ShowInformationTips(__('主界面看板娘设置成功'))
		gameMgr:UpdateSignboardByPlayCardId(signal:GetBody().requestData.playerCardId)
		self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer_TeamFormation)

		viewData.setMainLayoutHeroBtn:setNormalImage(_res('ui/cards/love/card_ico_set_cover_active.png'))
		viewData.setMainLayoutHeroBtn:setSelectedImage(_res('ui/cards/love/card_ico_set_cover_active.png'))

	end
end

--返回按钮处理
function CardsListMediatorNew:BackAction()
	if self.args ~= nil then --不为nil时就说明是从编队页面进入。则返回编队页面
		self:GetFacade():BackMediator()
	else--正常卡牌列表返回逻辑
		if self.rightView:isVisible() then
			local mediator = self:GetFacade():RetrieveMediator('CardDetailMediatorNew')
			if mediator then
				mediator:showBackLayerAction1()
			end
			self.rightView:runAction(cc.FadeOut:create(0.5))
			self.rightView:setVisible(false)
			self.gridView:setVisible(true)

			for k,v in pairs(self.gridView:getCells()) do
				if v then
					v:runAction(cc.FadeIn:create(0.8))
				end
			end
			-- self.rightUpView:setTouchEnabled(true)
			self.rightUpView:setVisible(true)
			self.rightUpView:runAction(cc.FadeIn:create(0.3))
			self.leftView:setVisible(true)
			self:GetFacade():UnRegsitMediator("CardSkillMediator")
			self.leftSwichBtn:setVisible(false)
			self.rightSwichBtn:setVisible(false)

			self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")

			local viewComponent = self:GetViewComponent()
			if viewComponent and viewComponent.viewData then
				local viewData = viewComponent.viewData
				if viewData.screenBoard then
					for i,v in ipairs(viewData.screenTab) do
						v:setTouchEnabled(true)
					end
				end
				if viewData.sortBoard then
					for i,v in ipairs(viewData.sortTab) do
						v:setEnabled(true)
					end
				end
				viewData.contractBtnView:runAction(cc.FadeOut:create(0.2))
				viewData.eatFoodBtnView:runAction(cc.FadeOut:create(0.2))
				viewData.contractBtn:setTouchEnabled(false)
				viewData.eatFoodBtn:setTouchEnabled(false)
				viewData.sortBtn:setEnabled(true)
				if viewData.findBtn then
					viewData.findBtn:setVisible(true)
				end
				viewData.screenBtn:setEnabled(true)
				viewData.compeseBtn:setTouchEnabled(true)
				viewData.heroNum:setVisible(true)
				viewData.tempStr:setVisible(true)
				viewData.heroNum:runAction(cc.FadeIn:create(0.3))
				viewData.tempStr:runAction(cc.FadeIn:create(0.3))
				viewData.modelView:setVisible(true)
				viewData.contractBtnView:setVisible(false)
				viewData.eatFoodBtnView:setVisible(false)
				if viewData.presetTeamView then
					local modelViewSize = viewData.modelView:getContentSize()
					if not CommonUtils.UnLockModule(JUMP_MODULE_DATA.WOODEN_DUMMY) then
						viewData.presetTeamView:setPosition(cc.p(modelViewSize.width*0.45 , modelViewSize.height - 184))
					else
						viewData.presetTeamView:setPosition(modelViewSize.width * 0.68, modelViewSize.height - 280)
					end
					-- viewData.presetTeamView:runAction(cc.FadeOut:create(0.2))
				end
				-- 此处不能单独刷新 因为堕神装备的时候会相互挤掉 操作过多的时候 就会有很多卡牌的战力没有刷新的问题
				local gridView = viewData.gridView
				local offsetPos =  gridView:getContentOffset()
				gridView:setAutoRelocate(false)
				gridView:reloadData()
				gridView:setContentOffset(offsetPos)
			end
			--self:UpdataRightUi()
		else
			local shareF = self:GetFacade()
			local router = shareF:RetrieveMediator("Router")
			router:Dispatch({name = NAME},
					{name = "HomeMediator"})
			display.removeUnusedSpriteFrames()
		end
	end
end

function CardsListMediatorNew:Initial( key )
	self.super.Initial(self,key)
	local CardsListViewNew = uiMgr:SwitchToTargetScene('Game.views.CardsListViewNew')
	self:SetViewComponent(CardsListViewNew)

	if not GuideUtils.IsGuiding() then
		--如果在引导的逻辑中时
		if isGuideOpened('card') then
			local guideNode = require('common.GuideNode').new({tmodule = 'card'})
			display.commonUIParams(guideNode, { po = display.center})
			sceneWorld:addChild(guideNode, GameSceneTag.Guide_GameSceneTag)
		end
	end
	--返回按钮
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	--卡牌升级按钮
	viewData.upgradeBtn:setOnClickScriptHandler(handler(self,self.UpgradeBtnCallback))

	--卡牌列表
	local gridView = viewData.gridView
	gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))


	self.rightUpView = viewData.rightUpView
	self.rightView = viewData.rightView
	self.leftView = viewData.leftView
	self.gridView = gridView
	self.leftSwichBtn = viewData.leftSwichBtn
	self.rightSwichBtn = viewData.rightSwichBtn

	viewData.voiceTouchArea:setOnClickScriptHandler(function (  )
		local cardData = gameMgr:GetCardDataByCardId(self.cardsData[self.clickTag].cardId)
		if cardData then
			local id = cardData.id
			CommonUtils.PlayCardSoundByCardId(self.cardsData[self.clickTag].cardId, cardMgr.GetCouple(id) and SoundType.TYPE_JIEHUN or SoundType.TYPE_TOUCH, SoundChannel.HOME_SCENE)
		end

		if viewComponent.viewData.l2dDrawNode then
			if viewComponent.viewData.l2dDrawNode:getLive2dNode() then
				viewComponent.viewData.l2dDrawNode:onClickCallback()
			end
		end
	end)

	self.leftSwichBtn:setOnClickScriptHandler(handler(self,self.changeHeroBtnCallback))
	self.rightSwichBtn:setOnClickScriptHandler(handler(self,self.changeHeroBtnCallback))
	self.leftSwichBtn:setVisible(false)
	self.rightSwichBtn:setVisible(false)
	if viewComponent.artifactLayer then
		viewComponent.artifactLayer.artifactLayer:setVisible(CommonUtils.GetModuleAvailable(MODULE_SWITCH.ARTIFACT))
	end


	--刷新默认第一个卡牌信息
	-- self:UpdataLeftUi(self.clickTag)

	--排序筛选相关绑定viewData
	viewData.screenBtn:setOnClickScriptHandler(handler(self, self.ScreenBtnCallback))



	viewData.sortBtn:setOnClickScriptHandler(handler(self, self.SortBtnCallback))

	if viewData.findBtn then
		viewData.findBtn:setOnClickScriptHandler(handler(self, self.FindBtnCallback))
	end


	if CommonUtils.GetModuleAvailable(MODULE_SWITCH.CARDSFRAGMENTCOMPOSE) then
		viewData.compeseBtn:setOnClickScriptHandler(handler(self, self.CardsFragmentCompeseBtnCallback))
	else
		viewData.compeseBtn:setVisible(false)
	end



	viewData.setMainLayoutHeroBtn:setOnClickScriptHandler(handler(self, self.SetMainLayoutHeroCallback))
	if  GAME_MODULE_OPEN.WOODEN_DUMMY and CommonUtils.UnLockModule(JUMP_MODULE_DATA.WOODEN_DUMMY)  then
		viewData.dummyBtn:setOnClickScriptHandler(handler(self, self.WoodenDummyCallback))
	end

	if viewData.presetTeamBtn then
		viewData.presetTeamBtn:setOnClickScriptHandler(handler(self, self.PresetTeamCallback))
	end

	xTry(function()
		if self.args ~= nil then
			self.isInitedViews_ = true
			self:ScreenCards(self.selectSortTag)
		else
			self.isInitedViews_ = false
			local viewComponent = self:GetViewComponent()
			viewComponent.viewData.heroImg:setOpacity(0)
			viewComponent.viewData.heroBg:setOpacity(0)
			viewComponent.viewData.heroFg:setOpacity(0)
			local showTime   = 0.3
			local showAcList = {
				cc.TargetedAction:create(viewComponent.viewData.heroBg, cc.FadeIn:create(showTime)),
				cc.TargetedAction:create(viewComponent.viewData.heroFg, cc.FadeIn:create(showTime)),
				cc.TargetedAction:create(viewComponent.viewData.heroImg, cc.FadeIn:create(showTime))
			}
			local l2dDrawNode = viewComponent.viewData.l2dDrawNode
			if l2dDrawNode then
				l2dDrawNode:setOpacity(0)
				table.insert(showAcList, cc.TargetedAction:create(viewComponent.viewData.l2dDrawNode, cc.FadeIn:create(showTime)))
			end

			self:ScreenCards(self.selectSortTag)
			viewComponent:runAction(cc.Sequence:create(
				cc.DelayTime:create(0.42),
				cc.CallFunc:create(function()
					self.isInitedViews_ = true
					self:UpdateCardFacade(self.cardsData[self.clickTag])
				end),
				cc.Spawn:create(showAcList)
			))
		end
	end,__G__TRACKBACK__)
end
--[[
	刷新神器的icon
--]]
function CardsListMediatorNew:RefreshArtifactIcon()
	local cardData = self.cardsData[self.clickTag] or {}
	local cardConf = CardUtils.GetCardConfig(cardData.cardId)
	local isHave = false
	if  cardConf and checkint(cardConf.artifactStatus) > 0  then
		local qualityId = checkint(cardConf.qualityId)
		if  qualityId  ~= 1 then  -- 如果不是M卡
			local isExist = CommonUtils.CheckModuleIsExitByMouduleTag(MODULE_DATA[tostring(RemindTag.ARTIFACT_TAG)])
			if isExist then
				---@type CardsListViewNew
				local viewComponent = self:GetViewComponent()
				local artifactLayer = viewComponent.artifactLayer
				if artifactLayer and  artifactLayer.artifactLayer  then
					isHave = true
					artifactLayer.artifactLayer:setVisible(true and CommonUtils.GetModuleAvailable(MODULE_SWITCH.ARTIFACT))
					artifactLayer.lockOne:setVisible(false)
					artifactLayer.coreBtnOne:clearFilter()
					artifactLayer.smallArtifact:clearFilter()
					artifactLayer.number:setVisible(false)
					local cardData =  self.cardsData[self.clickTag] or  {}
					local cardId = cardData.cardId
					local breakLevel =  checkint(cardData.breakLevel)
					local smallArtifactPath = CommonUtils.GetArtifiactPthByCardId(cardId)
					artifactLayer.smallArtifact:setTexture(smallArtifactPath)
					local isUnLock = CommonUtils.UnLockModule(RemindTag.ARTIFACT_TAG)
					if breakLevel < 2  or (not isUnLock)  then
						artifactLayer.coreBtnOne:setFilter(GrayFilter:create())
						artifactLayer.coreBtn:setTexture(_res('ui/artifact/core_btn_3'))
						artifactLayer.lockOne:setVisible(true)
						-- 神器碎片的路径
						artifactLayer.smallArtifact:setFilter(GrayFilter:create())
						artifactLayer.artifactLayer:setOnClickScriptHandler(function()
							local isUnLock = CommonUtils.UnLockModule(RemindTag.ARTIFACT_TAG , true)
							if isUnLock then
								uiMgr:ShowInformationTips(__('飨灵突破等级未达到两星'))
								return
							end
						end)
					else
						---@type ArtifactManager
						local artifactMgr =  AppFacade.GetInstance():GetManager("ArtifactManager")
						-- 获取到神器是否解锁
						local isArtifactUnlock =checkint( cardData.isArtifactUnlock)
						if  isArtifactUnlock == 1  then
							artifactLayer.coreBtn:setTexture(_res('ui/artifact/core_btn_3'))
							artifactLayer.artifactLayer:setOnClickScriptHandler(function()
								artifactMgr:SetCardsList(self.cardsData)
								AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
										{name = "CardsListMediatorNew", sortIndex = 0 ,params = { selectPlayerCardId = cardData.id , x = 1}} , { name ="artifact.ArtifactTalentMediator" , params = {playerCardId = cardData.id } }, {isBack = true})
							end)
						elseif isArtifactUnlock == 0  then
							artifactLayer.coreBtn:setTexture(_res('ui/artifact/core_btn_3'))
							if breakLevel < 2  then
								artifactLayer.smallArtifact:setFilter(GrayFilter:create())
								artifactLayer.coreBtnOne:setFilter(GrayFilter:create())
								artifactLayer.lockOne:setVisible(true)
								artifactLayer.number:setVisible(true)
								artifactLayer.coreBtn:setTexture(_res('ui/artifact/core_btn_3'))
							else
								artifactLayer.lockOne:setVisible(false)
								artifactLayer.number:setVisible(true)
								artifactLayer.coreBtn:setTexture(_res('ui/artifact/core_btn_2'))
							end
							local artifactFragmentId  = CommonUtils.GetArtifactFragmentsIdByCardId(cardId)
							local ownNum = CommonUtils.GetCacheProductNum(artifactFragmentId)
							local needData = artifactMgr:GetArtifactConsumeByCardId(cardId)
							local  cData  = {}
							if checkint(needData.num)  <=  ownNum  then
								cData[#cData+1] = fontWithColor(10 , {text = ownNum .. "/" ..  needData.num , color = "#ffffff" , fontSize =20 })
							else
								cData[#cData+1] = fontWithColor(10 , {text = ownNum , color = "#ffcf3d" , fontSize =20 })
								cData[#cData+1] = fontWithColor(10 , {text = "/" ..  needData.num , color = "#ffffff" , fontSize =20 })
							end
							display.reloadRichLabel(artifactLayer.numberLabel , {
								c = cData
							})
							if ownNum >= 1000   then
								artifactLayer.numberLabel:setAnchorPoint(display.LEFT_CENTER)
								artifactLayer.numberLabel:setPositionX( 15)
							else
								artifactLayer.numberLabel:setAnchorPoint(display.CENTER)
								artifactLayer.numberLabel:setPositionX( 60)
							end
							artifactLayer.artifactLayer:setOnClickScriptHandler(function()
								local isUnLock = CommonUtils.UnLockModule(RemindTag.ARTIFACT_TAG , true)
								if not isUnLock then
									return
								end
								artifactMgr:SetCardsList(self.cardsData)
								AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "CardsListMediatorNew", sortIndex = 0 ,params = { selectPlayerCardId = cardData.id , x = 1}} ,
										{ name ="artifact.ArtifactLockMediator" , params = {playerCardId = cardData.id } }, {isBack = true})
							end)
						end
					end

				end
			end
		end
	end
	if not isHave  then
		---@type CardsListViewNew
		local viewComponent = self:GetViewComponent()
		local artifactLayer = viewComponent.artifactLayer
		if artifactLayer and artifactLayer.artifactLayer then
			artifactLayer.artifactLayer:setVisible(not CommonUtils.GetModuleAvailable(MODULE_SWITCH.ARTIFACT))
		end
	end
end


function CardsListMediatorNew:hideMainCardVoiceWord_()
	local viewData = self:GetViewComponent().viewData
	local voiceWordLayer = viewData.voiceWordLayer
	local tipeNode       = voiceWordLayer and voiceWordLayer:getChildByName('TIP_NODE') or nil
	if voiceWordLayer and tipeNode and tipeNode:getParent() then
		voiceWordLayer:removeChild(tipeNode)
	end
end
function CardsListMediatorNew:showMainCardVoiceWord_(cardId, soundType, isShowWord)
	self:hideMainCardVoiceWord_()
	-- play voice
	local viewData = self:GetViewComponent().viewData
	local voiceWordLayer = viewData.voiceWordLayer
	local time, voiceId = CommonUtils.PlayCardSoundByCardId(cardId, soundType, SoundChannel.BATTLE_RESULT)
	if checkint(time) > 0 and isShowWord ~= false then
		local voiceNode = require('common.VoiceWordNode').new({cardId = cardId, time = time + 1, voiceId = voiceId})
		voiceNode:setPosition(0,0)
		voiceNode:setName('TIP_NODE')
		if voiceWordLayer then
			voiceWordLayer:addChild(voiceNode)
		end
	end
end

--预设编队点击回调--
function CardsListMediatorNew:PresetTeamCallback(sender)
	 local PresetTeamMediator = require( 'Game.mediator.presetTeam.PresetTeamMediator')
	 -- local PresetTeamMediator = require( 'Game.mediator.presetTeam.PresetTeamEditTeamMediator')
	 local presetTeamTypes = CommonUtils.GetPresetTeamModuleUnlockList()
	 local mediator = PresetTeamMediator.new({presetTeamTypes = presetTeamTypes})
	 self:GetFacade():RegistMediator(mediator)
end
	

--设置主界面看板娘--
function CardsListMediatorNew:WoodenDummyCallback(sender)
	---@type Router
	local router = app:RetrieveMediator("Router")
	router:Dispatch({name = "CardsListMediatorNew"}, {name = "woodenDummy.WoodenDummyMediator"})
end

--设置主界面看板娘--
function CardsListMediatorNew:SetMainLayoutHeroCallback(sender)
	local data  = self.cardsData[self.clickTag]
	if not gameMgr:GetCardDataByCardId(data.cardId) then
		uiMgr:ShowInformationTips(__('未拥有该飨灵'))
	else
		if data then
			if gameMgr:GetUserInfo().signboardId then
				if checkint(gameMgr:GetUserInfo().signboardId) == checkint(data.id) then
					uiMgr:ShowInformationTips(__('主界面看板娘设置成功'))
				else
					self:SendSignal(COMMANDS.COMMAND_Hero_SetSignboard, { playerCardId = data.id})
				end
			else
				self:SendSignal(COMMANDS.COMMAND_Hero_SetSignboard, { playerCardId = data.id})
			end
		end
	end
end

--契约按钮--
function CardsListMediatorNew:ContractBtnCallback(sender)
	PlayAudioByClickNormal()
	local data  = self.cardsData[self.clickTag]
	if cardMgr.GetCouple(data.id) then
		local CardContractCompleteMediator = require( 'Game.mediator.CardContractCompleteMediator')
		local mediator = CardContractCompleteMediator.new({data = data})
		self:GetFacade():RegistMediator(mediator)

		PlayBGMusic(AUDIOS.BGM.Food_Vow.id)
	else
		local CardContractDetailMediator = require( 'Game.mediator.CardContractDetailMediator')
		local mediator = CardContractDetailMediator.new(data)
		self:GetFacade():RegistMediator(mediator)
	end
end

--喂食按钮--
function CardsListMediatorNew:EatFoodBtnCallback(sender)
	PlayAudioByClickNormal()
	local viewData = self:GetViewComponent().viewData
	local loveMessLayout = viewData.loveMessLayout
	local modelView = viewData.modelView

	loveMessLayout:setVisible(true)
	loveMessLayout:setOpacity(0)
	local posx = modelView:getPositionX() - 110

	loveMessLayout:setPositionX(posx+200)
	local posY = 100
	if GAME_MODULE_OPEN.WOODEN_DUMMY and CommonUtils.UnLockModule(JUMP_MODULE_DATA.WOODEN_DUMMY) then
		posY = 185
	end
	loveMessLayout:runAction(
			cc.Spawn:create(cc.FadeIn:create(0.2),
					cc.MoveTo:create(0.2, cc.p(posx, modelView:getPositionY() - posY)))
	)

	-- end
	local function showStar( )
		-- loveMessLayout:setVisible(false)
		loveMessLayout:runAction(
				cc.Spawn:create(cc.FadeOut:create(0.15),
						cc.MoveTo:create(0.2, cc.p(posx+500,  modelView:getPositionY() - posY)))
		)

		loveMessLayout:setOpacity(0)
	end

	if not AppFacade.GetInstance():RetrieveMediator('CardsDiningTableMediator') then
		local CardsDiningTableMediator = require( 'Game.mediator.CardsDiningTableMediator')
		local mediator = CardsDiningTableMediator.new({callback = showStar,cardData = self.cardsData[self.clickTag]})
		self:GetFacade():RegistMediator(mediator)
	else
		AppFacade.GetInstance():UnRegsitMediator("CardsDiningTableMediator")
	end
end

--碎片融合--
function CardsListMediatorNew:CardsFragmentCompeseBtnCallback(sender)
	PlayAudioByClickNormal()
	if CommonUtils.UnLockModule(JUMP_MODULE_DATA.CARDSFRAGMENTCOMPOSE, true) then
		local CardsFragmentComposeMediator = require( 'Game.mediator.CardsFragmentComposeMediator')
		local mediator = CardsFragmentComposeMediator.new()
		self:GetFacade():RegistMediator(mediator)
	end
end

--[[
排序按钮回调
--]]
function CardsListMediatorNew:SortBtnCallback(sender)
	PlayAudioByClickNormal()
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	local checked = sender:isChecked()
	if not  viewData.sortBoard then
		viewComponent:CreateSortLayout()
		for i,v in ipairs(viewData.sortTab) do
			v:setOnClickScriptHandler(handler(self, self.SortTypeBtnCallback))
			table.insert(self.sortBtnState,false)
		end

	end
	self:ShowSortBoard(checked)
	local str = ''
	if not checked then
		str = '#ffffff'
	else
		str = '#ffcf96'
	end
	viewData.sortLabel:setColor(ccc3FromInt(str))
end


function CardsListMediatorNew:preBuildFindCardMap_()
	self:reindexFindCardMap_()
	
	self.findCardList_ = self.findCardMap_ and table.keys(self.findCardMap_) or {}
	if i18n.getLang() == 'zh-cn' or i18n.getLang() == 'zh-tw' then
		if self.pylib_ == nil then
			self.pylib_ = require('libs.pinyin.pinyin')
		end

		table.sort(self.findCardList_, function(a, b)
			local aAlpha = self.pylib_.getPinyin(a)
			local bAlpha = self.pylib_.getPinyin(b)
			if aAlpha ~= '' and bAlpha ~= '' then
				return aAlpha < bAlpha
			else
				return a < b
			end
		end)
	else
		table.sort(self.findCardList_, function(a, b)
			return a < b
		end)
	end
end
function CardsListMediatorNew:reindexFindCardMap_()
	self.findCardMap_ = {}
	for cardIndex, cardData in pairs(self.cardsData or {}) do
		local cardName = ''
		local cardConf = self.allCardConfs_[tostring(cardData.cardId)] or {}
		if cardData.id then
			cardName  = CommonUtils.GetCardNameById(cardData.id)
		else
			cardName = tostring(cardConf.name)
		end
		local firstChar = utf8sub(cardName, 1, 1)
		self.findCardMap_[firstChar] = self.findCardMap_[firstChar] or {}
		table.insert(self.findCardMap_[firstChar], cardIndex)
	end
end
--[[
	查找卡牌按钮回调
]]
function CardsListMediatorNew:FindBtnCallback(sender)
	PlayAudioByClickNormal()
	
	self.findCardIdx_ = 1
	self.findCardKey_ = nil
	app.uiMgr:AddDialog('Game.views.CardsListFindNew', {
		clickCellCB = function(cellIndex)
			local viewData = self.viewComponent.viewData
			if viewData and viewData.gridView then
				local charsKey  = tostring(self.findCardList_[cellIndex])
				if self.findCardKey_ ~= charsKey then
					self.findCardIdx_ = 1
					self.findCardKey_ = charsKey
				end
				local indexList = self.findCardMap_[charsKey] or {}
				local viewIndex = checkint(indexList[self.findCardIdx_])
				viewData.gridView:setContentOffsetAt(viewIndex)
				if self.findCardIdx_ >= #indexList then
					self.findCardIdx_ = 1
				else
					self.findCardIdx_ = self.findCardIdx_ + 1
				end
			end
		end, 
		clickResultCB  = handler(self, self.searchResultCellClick), 
		firstCharsList = self.findCardList_, 
		charsCountMap  = self.findCardMap_, 
		cardsMap       = self.cardsData
	})
end


function CardsListMediatorNew:searchResultCellClick(cellIndex)
	local viewData = self.viewComponent.viewData
	if viewData and viewData.gridView then
		local viewIndex = checkint(cellIndex)
		viewData.gridView:setContentOffsetAt(viewIndex)
	end
end
--[[
显示排序板
@params visible bool 是否显示排序板
--]]
function CardsListMediatorNew:ShowSortBoard(visible)
	local viewData = self:GetViewComponent().viewData
	viewData.sortBtn:setChecked(visible)
	-- viewData.sortBoard:setVisible(visible)
	if visible == true then
		viewData.sortBoard:setScaleY(0)
		for i=1,10 do
			viewData.sortBoard:runAction(cc.Sequence:create(cc.DelayTime:create(i*0.01),cc.CallFunc:create(function ()
				viewData.sortBoard:setScaleY(i*0.1)
			end)))
		end
		viewData.sortBoard:setVisible(visible)
	else
		viewData.sortBoard:setScaleY(1)
		viewData.sortBoard:setVisible(visible)
	end


	local str = viewData.sortLabel:getString()
	local index = 0
	for i,v in ipairs(sortType) do
		if str == v.descr then
			index = i
			break
		end
	end

	for i,v in ipairs(viewData.sortTab) do
		local sortIcon = v:getChildByTag(9)
		local selectIcon = v:getChildByTag(99)
		if sortIcon then
			selectIcon:setVisible(false)
			sortIcon:setVisible(false)
			if i == index then
				selectIcon:setVisible(true)
				if i ~= 1 and i ~= 7 then
					sortIcon:setVisible(true)
				end
			end
		end
	end
end

--[[
排序按钮点击回调
--]]
function CardsListMediatorNew:SortTypeBtnCallback(sender)
	PlayAudioByClickNormal()
	local viewData = self:GetViewComponent().viewData
	local tag = sender:getTag()
	self.sortBtnState[tag+1] = sender:isChecked()
	viewData.sortLabel:setString(sortType[tag + 1].descr)
	viewData.sortLabel:setColor(ccc3FromInt('#ffffff'))
	self:ShowSortBoard(false)
	self:SortAction(tag+1,sender:getChildByTag(9),viewData.arrowImg)
end
function CardsListMediatorNew:SortAction(tag,btn,arrowImg)
	if tag ~= 7 and  tag ~= 1 then
		arrowImg:setVisible(true)
	else
		arrowImg:setVisible(false)
	end
	local sortRuleTable = {
		{ sort = { "showFragment", "qualityId", "breakLevel", "level", "battlePoint", "favorabilityLevel", "cardId" }, ignoreLowUp = true },
		{ sort = { "showFragment", "level", "qualityId", "breakLevel", "battlePoint", "favorabilityLevel", "cardId" }, ignoreLowUp = false },
		{ sort = { "showFragment", "qualityId", "breakLevel", "level", "battlePoint", "favorabilityLevel", "cardId" }, ignoreLowUp = false },
		{ sort = { "showFragment", "battlePoint", "qualityId", "breakLevel", "level", "favorabilityLevel", "cardId" }, ignoreLowUp = false },
		{ sort = { "showFragment", "breakLevel", "qualityId", "level", "battlePoint", "favorabilityLevel", "cardId" }, ignoreLowUp = false },
		{ sort = { "showFragment", "favorabilityLevel", "breakLevel", "qualityId", "level", "battlePoint", "cardId" }, ignoreLowUp = false },
		{ sort = { "showFragment", "teamIndex", "qualityId", "breakLevel", "level", "battlePoint", "cardId" }, ignoreLowUp = false },
	}
	for i, v in pairs(self.cardsData) do
		if  v.id then
			v.battlePoint = cardMgr.GetCardStaticBattlePointById(checkint(v.id))
		else
			v.battlePoint = 0
			v.favorabilityLevel = 0
		end
		v.id                = tonumber(v.id)
		v.teamIndex         = v.teamIndex and tonumber(v.teamIndex) or 99
		v.favorabilityLevel = tonumber(v.favorabilityLevel)
		v.battlePoint       = tonumber(v.battlePoint)
		v.level             = tonumber(v.level)
		v.breakLevel        = tonumber(v.breakLevel)
		v.cardId            = tonumber(v.cardId)
		v.qualityId         = tonumber(v.qualityId)
		v.showFragment      = tonumber(v.showFragment)

	end
	local sort =  sortRuleTable[tag].sort
	local ignoreLowUp = sortRuleTable[tag].ignoreLowUp
	if not  ignoreLowUp then
		if self.sortBtnState[tag] then
			btn:setRotation(180)
			arrowImg:setRotation(180)
		else
			btn:setRotation(0)
			arrowImg:setRotation(0)
		end
	end
	if tag == 7  then
		-- 如果为7 强制设置为false
		self.sortBtnState[tag] = false
	end
	table.sort(self.cardsData, function(a, b )
		local r
		if  a[sort[1]] ==  b[sort[1]] then
			if  a[sort[2]] ==  b[sort[2]] then
				if  a[sort[3]] ==  b[sort[3]] then
					if  a[sort[4]] ==  b[sort[4]] then
						if  a[sort[5]] ==  b[sort[5]] then
							if  a[sort[6]] ==  b[sort[6]] then
								r = a[sort[7]] < b[sort[7]]
							else
								r = a[sort[6]] > b[sort[6]]
							end
						else
							r = a[sort[5]] > b[sort[5]]
						end
					else
						r = a[sort[4]] > b[sort[4]]
					end
				else
					r = a[sort[3]] > b[sort[3]]
				end
			else
				if ignoreLowUp then
					r = a[sort[2]] > b[sort[2]]
				else
					if self.sortBtnState[tag] then
						r = a[sort[2]] > b[sort[2]]
					else
						r = a[sort[2]] < b[sort[2]]
					end
				end
			end
		else
			r = a[sort[1]] >  b[sort[1]]
		end
		return r
	end)
	for i, v in pairs(self.cardsData) do
		v.battlePoint = nil
		if v.teamIndex == 10000 then
			v.teamIndex = nil
		end
	end
	self.clickTag = 1
	local viewData = self.viewComponent.viewData
	if viewData then
		if viewData.findBtn then
			self:reindexFindCardMap_()
		end
		viewData.gridView:setCountOfCell(table.nums(self.cardsData))
		viewData.gridView:reloadData()
	end
	self:UpdataLeftUi(self.clickTag)
end


--[[
筛选按钮回调
--]]
function CardsListMediatorNew:ScreenBtnCallback(sender)
	PlayAudioByClickNormal()
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	local checked = sender:isChecked()
	if not  viewData.screenBoard then
		viewComponent:CreateScreenBoradLayout()
		for i,v in ipairs(viewData.screenTab) do
			v:setOnClickScriptHandler(handler(self, self.ScreenTypeBtnCallback))
		end
	end
	self:ShowScreenBoard(checked)
	local str = ''
	if not checked then
		str = '#ffffff'
	else
		str = '#ffcf96'
	end
	viewData.screenLabel:setColor(ccc3FromInt(str))
end
--[[
显示筛选排序板
@params visible bool 是否显示排序板
--]]
function CardsListMediatorNew:ShowScreenBoard(visible)
	local viewData = self:GetViewComponent().viewData
	viewData.screenBtn:setChecked(visible)
	if visible == true then
		viewData.screenBoard:setScaleY(0)
		for i=1,10 do
			viewData.screenBoard:runAction(cc.Sequence:create(cc.DelayTime:create(i*0.01),cc.CallFunc:create(function ()
				viewData.screenBoard:setScaleY(i*0.1)
			end)))
		end
		viewData.screenBoard:setVisible(visible)
	else
		viewData.screenBoard:setScaleY(1)
		viewData.screenBoard:setVisible(visible)
	end

	local str = viewData.screenLabel:getString()
	local index = 0
	for i,v in ipairs(screenType) do
		if str == v.descr then
			index = i
			break
		end
	end

	for i,v in ipairs(viewData.screenTab) do
		local selectIcon = v:getChildByTag(99)
		if selectIcon then
			selectIcon:setVisible(false)
			if i == index then
				selectIcon:setVisible(true)
			end
		end
	end
end

--[[
筛选按钮点击回调
--]]
function CardsListMediatorNew:ScreenTypeBtnCallback(sender)
	PlayAudioByClickNormal()
	local viewData = self:GetViewComponent().viewData
	local tag = sender:getTag()
	self:ScreenCards(tag)
	viewData.screenLabel:setString(screenType[tag + 1].descr)
	viewData.screenLabel:setColor(ccc3FromInt('#ffffff'))
	self:ShowScreenBoard(false)
end

--[[
排序整个界面
@params pattern int 排序模式
0 默认所有卡牌按照 id 排序
1 所有坦克
2 所有近战 dps
3 所有远程 dps
4 所有治疗
5 碎片
--]]
function CardsListMediatorNew:ScreenCards(pattern,state, cardId)
	local tag = pattern
	-- self.Tdata = {}
	local Tdata = {}
	local canComposeCards = {}
	self.canComposeCards = {}
	self.selectSortTag = pattern
	local cardConf = self.allCardConfs_
	local cardConversionConf = CommonUtils.GetConfigAllMess('cardConversion' ,'card' )
	---@type table<string, number> @[ cardId : id ]
	local cardIdTable = {
	}
	for i, v in pairs(gameMgr:GetUserInfo().cards) do
		cardIdTable[tostring(v.cardId)] =  v.id
	end
	for cardId, cardOneConf in pairs(cardConf) do
		local cardData = {}
		cardData.qualityId = cardOneConf.qualityId
		cardData.career = cardOneConf.career
		if not  cardIdTable[cardId] then
			local composNum =checkint((cardConversionConf[cardData.qualityId] or {}).composition)
			local num = checkint(gameMgr:GetAmountByGoodId(cardOneConf.fragmentId))
			if num  > 0 then
				cardData.showFragment = 1
				cardData.breakLevel = 0
				cardData.cardId = cardId
				cardData.isNew = 1
				cardData.level = 1
				cardData.favorabilityLevel = 1
				cardData.favorability = 0
				if composNum <= num   then
					table.insert(canComposeCards,cardData)
				else
					table.insert(Tdata,cardData)
				end
			end
		else
			cardData.showFragment = 2
			table.merge(cardData, gameMgr:GetCardDataById(cardIdTable[cardId]))
			table.insert(Tdata,cardData)
		end
	end
	for i,v in ipairs(canComposeCards) do
		if v then
			if checkint(v.career) == tag then
				table.insert(self.canComposeCards,v)
			elseif tag == 0 then
				table.insert(self.canComposeCards,v)
			elseif tag == CARD_FILTER_TYPE_SUIPIAN and v.showFragment == 1 then
				table.insert(self.canComposeCards,v)
			elseif tag == CARD_FILTER_TYPE_ARTIACT then
				local cardConf = cardConf[tostring(v.cardId)]
				if checkint(cardConf.artifactStatus)  == 1   then
					table.insert(self.canComposeCards,v)
				end
			end
		end
	end

	self.cardsData = {}
	for i,v in ipairs(Tdata) do
		if v then
			if checkint(v.career) == tag then
				table.insert(self.cardsData,v)
			elseif tag == 0 then
				table.insert(self.cardsData,v)
			elseif tag == CARD_FILTER_TYPE_SUIPIAN and v.showFragment == 1 then
				table.insert(self.cardsData,v)
			elseif tag ==  CARD_FILTER_TYPE_ARTIACT   then
				local cardConf = cardConf[tostring(v.cardId)]
				if checkint(cardConf.artifactStatus)  == 1   then
					table.insert(self.cardsData,v)
				end
			end
		end
	end


	for i,v in ipairs(self.cardsData) do
		local places = {}
		if v.id then
			places = gameMgr:GetCardPlace({id = v.id})
		end
		if places[tostring(CARDPLACE.PLACE_TEAM)] then
			local teamInfo = nil
			teamInfo = gameMgr:GetTeamInfo({id = v.id},true)
			if teamInfo then
				v.teamIndex = teamInfo.teamId or 1
			else
				v.teamIndex = 99
			end
		else
			v.teamIndex = 99
		end
	end

	local cardBattleTable = { }
	for i, cardData in pairs(self.cardsData) do
		cardData.level = tonumber(cardData.level)
		cardData.breakLevel = tonumber(cardData.breakLevel)
		cardData.isNew = tonumber(cardData.isNew)
		cardData.cardId = tonumber(cardData.cardId)
		cardData.qualityId = tonumber(cardData.qualityId)
		cardData.showFragment = tonumber(cardData.showFragment)
	end
	local al =  0
	local bl =  0
	local ab =  0
	local bb =  0
	local an =  0
	local bn =  0
	local aid = 0
	local bid = 0
	local ak =  0
	local bk =  0
	local r = nil
	local aq = 0
	local bq = 0
	local af = 0
	local bf = 0
	table.sort(self.cardsData, function(a, b)
		r = nil
		al =  checkint(a.level)
		bl =  checkint(b.level)
		ab =  checkint(a.breakLevel)
		bb =  checkint(b.breakLevel)
		an =  a.isNew
		bn =  b.isNew
		aid = checkint(a.cardId)
		bid = checkint(b.cardId)
		ak =  0
		bk =  0
		aq = checkint(a.qualityId)
		bq = checkint(b.qualityId)
		af = checkint(a.showFragment)
		bf = checkint(b.showFragment)
		if af == bf then
			if an == bn then
				if aq == bq then
					if ab == bb then
						if al == bl then
							if not cardBattleTable[tostring(a.id)]   then
								cardBattleTable[tostring(a.id)] = cardMgr.GetCardStaticBattlePointById(a.id)
							end
							ak = cardBattleTable[tostring(a.id)]
							if not cardBattleTable[tostring(b.id)] then
								cardBattleTable[tostring(b.id)] = cardMgr.GetCardStaticBattlePointById(b.id)
							end
							bk = cardBattleTable[tostring(b.id)]
							if ak == bk then
								r = aid < bid--卡牌cardId升序
							else
								r = ak > bk --卡牌战斗力降序
							end
						else
							r = al > bl--卡牌等级降序
						end
					else
						r = ab > bb--卡牌突破等级降序
					end
				else
					r = aq > bq--卡牌稀有度降序
				end
			else
				r = an > bn--新获得卡牌排在最前
			end
		else
			r = af > bf
		end
		return r
	end)
	--将和合成卡牌信息插到列表最前头

    local level = checkint(gameMgr:GetUserInfo().level)
    local unlockPetLevel = CommonUtils.GetModuleOpenLevel(RemindTag.PET)
    if level > unlockPetLevel then
        --27级之后碎片才拍最前面
		for i,v in ipairs(canComposeCards) do
			if v then
				if checkint(v.career) == tag then
					table.insert(self.cardsData,1,v)
				elseif tag == 0 then
					table.insert(self.cardsData,1,v)
				elseif tag == CARD_FILTER_TYPE_SUIPIAN then
					table.insert(self.cardsData,1,v)
				end
			end
		end
    else
        for i,v in ipairs(canComposeCards) do
            if v then
                if tag == CARD_FILTER_TYPE_DEF and checkint(v.career) == tag then
                    table.insert(self.cardsData, v)
                elseif tag == CARD_FILTER_TYPE_NEAR_ATK and checkint(v.career) == tag then
                    table.insert(self.cardsData, v)
                elseif tag == CARD_FILTER_TYPE_REMOTE_ATK and checkint(v.career) == tag then
                    table.insert(self.cardsData, v)
                elseif tag == CARD_FILTER_TYPE_DOCTOR and checkint(v.career) == tag then
                    table.insert(self.cardsData, v)
                elseif tag == 0 then
                    table.insert(self.cardsData, v)
                elseif tag == CARD_FILTER_TYPE_SUIPIAN then
                    table.insert(self.cardsData, v)
                end
            end
        end
    end

	if not state then
		self.clickTag = 1
		local selectPlayerCardId = checkint( self.selectPlayerCardId )
		if self.selectPlayerCardId and selectPlayerCardId > 0  then
			for i, v in pairs(self.cardsData) do
				if v.id and checkint(v.id ) == selectPlayerCardId then
					self.clickTag = i
					self.selectPlayerCardId = nil
					break
				end
			end
		end
		self:UpdataLeftUi(self.clickTag)
	else
		if cardId then
			for i, v in pairs(self.cardsData) do
				if v.cardId and checkint(v.cardId) == checkint(cardId) then
					self.clickTag = i
					break
				end
			end
		end
	end
	local viewData = self:GetViewComponent().viewData
	if self.args == nil then
		if viewData.findBtn then
			self:preBuildFindCardMap_()
		end
		viewData.gridView:setCountOfCell(table.nums(self.cardsData))
		viewData.gridView:reloadData()
		-- 不为一的时候 就偏移
		if self.clickTag  ~= 1 then
			local tempNumm =  viewData.gridView:getContentOffset().y
			local offsetNum = viewData.gridView:getSizeOfCell().height * (self.clickTag  - 1)
			viewData.gridView:setContentOffset(cc.p(0,tempNumm+offsetNum))
		end
	end
	local heroAllNum = table.nums(cardConf)
	local heroNum = viewData.heroNum
	heroNum:setString(string.fmt(('_value1_/_value2_'), {_value1_ = table.nums(gameMgr:GetUserInfo().cards),_value2_ = heroAllNum}))
end


--长按吃经验药时经验条ui显示逻辑
function CardsListMediatorNew:RefreshCardExpForClient(newLevel,totalExp)
	local viewData = self:GetViewComponent().viewData
	local expBar = viewData.expBar
	local heroLvLabel = viewData.heroLvLabel
	local heroExpLabel = viewData.heroExpLabel
	if checkint(self.longClickLevel) < checkint(newLevel) then
		local progressAction = cc.Sequence:create(
				cc.ProgressTo:create(0.3, 100),
				cc.CallFunc:create(function ()
					expBar:setPercentage(0)
					heroLvLabel:setString(string.format(('%d/%d'), checkint(newLevel),self.maxLevel))
				end))
		expBar:runAction(progressAction)
		self.longClickLevel = newLevel
	else
		heroLvLabel:setString(string.format(('%d/%d'), checkint(self.longClickLevel),self.maxLevel))
		local percent = (checkint(totalExp) - CommonUtils.GetConfig('cards', 'level',self.longClickLevel).totalExp) / CommonUtils.GetConfig('cards', 'level',self.longClickLevel+1).exp * 100
		local progressAction = cc.Sequence:create(
				cc.ProgressTo:create(0.3, percent))
		expBar:runAction(progressAction)

		self.longClickLevel = newLevel
	end

	local nowLvExp = (checkint(totalExp) - CommonUtils.GetConfig('cards', 'level',self.longClickLevel).totalExp)
	if nowLvExp < 0 then
		nowLvExp = 0
	end
	local needLvExp = (CommonUtils.GetConfig('cards', 'level',self.longClickLevel+1).exp or 999999)
	heroExpLabel:setString(string.format(('%d/%d'), nowLvExp,needLvExp))
end

--经验条ui刷新显示逻辑
function CardsListMediatorNew:RefreshCardExp(oldLevel,maxLevel)
	local viewData =  self:GetViewComponent().viewData
	local expBar = viewData.expBar
	local heroLvLabel = viewData.heroLvLabel
	if checkint(self.oldLevel) < checkint(self.cardsData[self.clickTag].level) then
		local progressAction = cc.Sequence:create(
				cc.ProgressTo:create(0.3, 100),
				cc.CallFunc:create(function ()
					expBar:setPercentage(0)
					heroLvLabel:setString(string.format(('%d/%d'), checkint(self.oldLevel),maxLevel))
					self:RefreshCardExp(self.oldLevel,maxLevel)
				end))
		expBar:runAction(progressAction)
		self.oldLevel = self.oldLevel + 1

		local btnSpine = sp.SkeletonAnimation:create('effects/shengxing/shengxing.json', 'effects/shengxing/shengxing.atlas', 1)
		btnSpine:update(0)
		btnSpine:setAnimation(0, 'shengji', false)--shengxing1 shengji
		uiMgr:GetCurrentScene():addChild(btnSpine,100)
		btnSpine:setPosition(cc.p(0,0))

		btnSpine:registerSpineEventHandler(function (event)
			if event.animation == "shengji" then
				print("====== hit end ====")
				btnSpine:runAction(cc.RemoveSelf:create())
			end
		end, sp.EventType.ANIMATION_END)
	else
		local percent = (checkint(self.cardsData[self.clickTag].exp) - CommonUtils.GetConfig('cards', 'level',self.cardsData[self.clickTag].level).totalExp) / CommonUtils.GetConfig('cards', 'level',self.cardsData[self.clickTag].level+1).exp * 100
		local progressAction = cc.Sequence:create(
				cc.ProgressTo:create(0.3 * percent * 0.01, percent))
		expBar:runAction(progressAction)
		self.oldLevel = self.cardsData[self.clickTag].level
	end
end


--左右箭头按钮回调
function CardsListMediatorNew:changeHeroBtnCallback(pSender)
	-- PlayAudioByClickNormal()

	local tag = pSender:getTag()
	local offsetY = 0
	local tempNum = 0
	self.offsetY = offsetY
	display.removeUnusedSpriteFrames()
	local curCell = self:GetCellAtIndex(self.clickTag)
	if curCell then
		curCell.toggleView:setChecked(false)
		curCell.selectGoBg:setVisible(false)
		curCell:setLocalZOrder(1)
	end
	local offsetNum = 0
	if tag == 1 then --左
		if self.clickTag ~= 1 then
			self.clickTag = self.clickTag - 1
			tempNum = -1
			offsetNum = self.gridView:getSizeOfCell().height*(-1)
		else
			self.clickTag = table.nums(self.cardsData)
			offsetNum = 0
		end
	else -- 右
		if self.clickTag ~=  table.nums(self.cardsData) then
			self.clickTag = self.clickTag + 1
			tempNum = 1
			offsetNum = self.gridView:getSizeOfCell().height
		else
			self.clickTag = 1
			offsetNum = 0
		end
	end


	local tempBool = 0
	if not gameMgr:GetCardDataByCardId(self.cardsData[self.clickTag].cardId) then--未拥有卡牌
		if tag == 1 then --左
			local index = 1 + table.nums(self.canComposeCards)
			for i=table.nums(self.cardsData),1,-1 do
				if self.cardsData[i].id then
					index = i
					break
				end
			end
			self.clickTag = index
			tempBool = 1
		else
			local index = 1 + table.nums(self.canComposeCards)
			for i,v in ipairs(self.cardsData) do
				if v.id then
					index = i
					break
				end
			end
			self.clickTag = index
			tempBool = 2
			-- self.gridView:setContentOffsetToTop()
		end
	end

	------------ 移动外部list至置顶当前格 ------------
	local offsetX = 0
	local offsetY = math.min(0, math.min(0, self.gridView:getContentSize().height - table.nums(self.cardsData) * self.gridView:getSizeOfCell().height) + ((self.clickTag - 1) * self.gridView:getSizeOfCell().height))
	self.gridView:setContentOffset(cc.p(offsetX, offsetY))
	------------ 移动外部list至置顶当前格 ------------

	-- if tempBool == 0 then
	-- 	local tempNum = self.gridView:getContentOffset().y
	-- 	if offsetNum ~= 0 then
	-- 		self.gridView:setContentOffset(cc.p(0,tempNum+offsetNum))
	-- 	end

	-- 	if self.gridView:getContentOffset().y > 0 then
	-- 		self.gridView:setContentOffsetToBottom()
	-- 	end

	-- 	if self.clickTag == 1 then
	-- 		self.gridView:setContentOffsetToTop()
	-- 	elseif self.clickTag == table.nums(gameMgr:GetUserInfo().cards) then
	-- 		self.gridView:setContentOffsetToBottom()
	-- 	end
	-- elseif tempBool == 1 then
	-- 	self.gridView:setContentOffsetToBottom()
	-- elseif tempBool == 2 then
	-- 	-- 最后跳到第一个
	-- 	-- self.gridView:setContentOffsetToTop()
	-- 	local offsetX = 0
	-- 	local offsetY = -((table.nums(self.cardsData) - self.clickTag + 1) * self.gridView:getSizeOfCell().height) + self.gridView:getContentSize().height
	-- 	self.gridView:setContentOffset(cc.p(offsetX, offsetY))
	-- end

	local curCell = self:GetCellAtIndex(self.clickTag)
	if curCell and gameMgr:GetCardDataByCardId(self.cardsData[self.clickTag].cardId) then
		curCell.toggleView:setChecked(true)
		curCell.selectGoBg:setVisible(true)
		curCell:setLocalZOrder(2)
	else
		return
	end

	if self.modelTag == 1 then
		if tag == 1 then --左
			offsetY = 30
		else -- 右
			offsetY = -30
		end
		local viewData = self:GetViewComponent().viewData
		local l2dDrawNode = viewData.l2dDrawNode
		if l2dDrawNode then
			l2dDrawNode:cleanL2dNode()
		end

		local heroImg = viewData.heroImg
		heroImg.avatar:runAction(cc.Sequence:create(
				cc.Spawn:create(
						cc.FadeOut:create(0.2),
						cc.MoveTo:create(0.2,cc.p(heroImg.avatar:getPositionX() + offsetY,heroImg.avatar:getPositionY()))
				),
				cc.CallFunc:create(function ()
					self.offsetY = offsetY
					self:UpdataLeftUi(self.clickTag)
				end)
		))
		self:GetFacade():RetrieveMediator('CardDetailMediatorNew'):updataUi({data = self.cardsData[self.clickTag],showSkillIndex = 1,showModel = 1 ,isFirst = true, isShowAction = false} )
	elseif self.modelTag == 2 then
		self:UpdataLeftUi(self.clickTag)
		self:GetFacade():DispatchObservers("REMOVE_QBG_SPINE_EVENT")
		self:GetFacade():RetrieveMediator('CardDetailMediatorNew'):updataUi({data = self.cardsData[self.clickTag],showSkillIndex = 1,showModel = 1 ,isFirst = false, isShowAction = false} )
	else--if self.modelTag == 3 then
		self:UpdataLeftUi(self.clickTag)
		self:GetFacade():RetrieveMediator('CardDetailMediatorNew'):updataUi({data = self.cardsData[self.clickTag],showSkillIndex = 1,showModel = 1 ,isFirst = false, isShowAction = false} )
	end

	CommonUtils.PlayCardSoundByCardId(self.cardsData[self.clickTag].cardId, SoundType.TYPE_HOME_CARD_CHANGE, SoundChannel.HOME_SCENE)
end

--弹出吃经验升级页面按钮回调
function CardsListMediatorNew:UpgradeBtnCallback(pSender)
	PlayAudioByClickNormal()
	if CommonUtils.UnLockModule(RemindTag.CARDLEVELUP, true) then
		self.oldLevel = self.cardsData[self.clickTag].level
		self.longClickLevel = self.cardsData[self.clickTag].level
		self.cardsData[self.clickTag].callback = handler(self, self.RefreshCardExpForClient)
		local layer  = require( 'home.CardDetailUpgradePopup' ).new(self.cardsData[self.clickTag])
		layer:setPosition(display.center)
		layer:setTag(444)
		self:GetViewComponent():AddDialog(layer)
	end
end

--卡牌列表cell具体信息查看点击回调
function CardsListMediatorNew:GoToHeroMessLayer( sender )
	if not self.isInitedViews_ then return end
	local tag = 1
	if type(sender) ~= 'number' then
		tag = sender:getTag()
	else
		tag = sender
	end

	for k,v in pairs(self.gridView:getCells()) do
		if v then
			v:setCascadeOpacityEnabled(true)
			v:runAction(cc.FadeOut:create(0.8))
		end
	end
	if self.args == nil then
		local cell = self:GetCellAtIndex(tag)
		if cell then
			cell.newImg:setVisible(false)
		end
	end
	self.cardsData[self.clickTag].isNew = 1
	if gameMgr:GetCardDataByCardId(self.cardsData[self.clickTag].cardId) then
		gameMgr:GetCardDataByCardId(self.cardsData[self.clickTag].cardId).isNew = 1
	end

	self.gridView:setVisible(false)
	self.rightUpView:runAction(cc.FadeOut:create(0.3))
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	if not viewData.contractBtnView then
		viewComponent:CreateEatAndContractLayout()
		self:UpdataLeftUi(self.clickTag)
		viewData.eatFoodBtn:setOnClickScriptHandler(handler(self, self.EatFoodBtnCallback))
		viewData.contractBtn:setOnClickScriptHandler(handler(self, self.ContractBtnCallback))
	end
	viewData.heroNum:runAction(cc.FadeOut:create(0.3))
	viewData.tempStr:runAction(cc.FadeOut:create(0.3))
	viewData.screenBtn:setChecked(false)
	if viewData.screenBoard then
		viewData.screenBoard:setVisible(false)
		for i,v in ipairs(viewData.screenTab) do
			v:setTouchEnabled(false)
		end
	end
	viewData.screenBtn:setEnabled(false)

	viewData.sortBtn:setChecked(false)
	if viewData.sortBoard then
		viewData.sortBoard:setVisible(false)
		for i,v in ipairs(viewData.sortTab) do
			v:setEnabled(false)
		end
	end
	viewData.sortBtn:setEnabled(false)
	if viewData.findBtn then
		viewData.findBtn:setVisible(false)
	end

	viewData.compeseBtn:setTouchEnabled(false)

	viewData.contractBtnView:setVisible(true)
	viewData.contractBtn:setTouchEnabled(true)
	viewData.eatFoodBtnView:setVisible(true)
	viewData.eatFoodBtn:setTouchEnabled(true)
	
	viewData.contractBtnView:runAction(cc.FadeIn:create(0.8))
	viewData.eatFoodBtnView:runAction(cc.FadeIn:create(0.8))

	if viewData.presetTeamView then
		local modelViewSize = viewData.modelView:getContentSize()
		if not CommonUtils.UnLockModule(JUMP_MODULE_DATA.WOODEN_DUMMY) then
			viewData.presetTeamView:setPosition(cc.p(modelViewSize.width*0.65, modelViewSize.height - 373))
		else
			viewData.presetTeamView:setPosition(modelViewSize.width * 0.65, modelViewSize.height - 466)
		end
		viewData.presetTeamView:setOpacity(0)
		viewData.presetTeamView:runAction(cc.FadeIn:create(0.8))
	end


	self.rightView:setVisible(true)
	self.rightView:runAction(cc.FadeIn:create(0.8))

	if self.cardDetailMediator == nil then
		local CardDetailMediator = require( 'Game.mediator.CardDetailMediatorNew')
		local mediator = CardDetailMediator.new({self.cardsData,tag,self.rightView})
		self:GetFacade():RegistMediator(mediator)

		self.cardDetailMediator = CardDetailMediator
	else

		self:GetFacade():RetrieveMediator('CardDetailMediatorNew'):updataUi({data = self.cardsData[self.clickTag],showSkillIndex = 1 ,isFirst = true, isShowAction = true})
	end
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
	if self.args then
		if self.args.isFrom then
			self.leftSwichBtn:setVisible(false)
			self.rightSwichBtn:setVisible(false)
		end
	else
		self.leftSwichBtn:setVisible(true)
		self.rightSwichBtn:setVisible(true)
	end

	CommonUtils.PlayCardSoundByCardId(self.cardsData[self.clickTag].cardId, SoundType.TYPE_HOME_CARD_CHANGE, SoundChannel.HOME_SCENE)
end

--卡牌列表cell具体信息查看点击回调
--modelTag 点击是什么模块，1是 堕神，2是属性 ，3是技能
function CardsListMediatorNew:ShowSkillUi(data )--,modelTag,index
	-- dump(data)
	-- dump(index)
	local bool = true
	if data.modelTag == 2 then
		bool = false
	end
	self:UpdataSkillUi(data.index or 1)
	self.modelTag = data.modelTag
	self.leftView:setVisible(bool)
	local viewData = self:GetViewComponent().viewData
	viewData.modelView:setVisible(bool)
end

--刷新当前卡牌技能描述和立绘
--index 当前卡牌第几个技能
--切换卡牌刷新页面方法
function CardsListMediatorNew:UpdataSkillUi( index )
	-- dump(data)
	local data  = self.cardsData[self.clickTag]
	local mediator = self:GetFacade():RetrieveMediator("CardSkillMediator")
	if  mediator then
		mediator:UpdataSkillUi(data  , index )
	end

end


--刷新当前卡牌技能描述和立绘
--skillIndex 当前卡牌第几个技能
--当前卡牌进行技能相关操作时刷新页面方法
function CardsListMediatorNew:UpdataSkillUi_1( skillIndex , model)
	if not model then
		return
	end
	local data  = self.cardsData[self.clickTag]
	local mediator = self:GetFacade():RetrieveMediator("CardSkillMediator")
	if  mediator then
		mediator:UpdataSkillUi_1(data  , skillIndex , model )
	end
end

--[[
--点击位置的cell节点
--]]
function CardsListMediatorNew:GetCellAtIndex(clickTag)
	local cellIndex = checkint(clickTag - 1)
	local dataLen = table.nums(self.cardsData)
	if cellIndex < 0 then cellIndex = 0 end
	if cellIndex >= dataLen then cellIndex = dataLen - 1 end
	local curCell = self.gridView:cellAtIndex(cellIndex)
	return curCell
end

--卡牌列表cell点击回调
function CardsListMediatorNew:CellButtonAction( sender )
	sender:setChecked(not sender:isChecked())
	if not self.isInitedViews_ then return end
	-- dump(self.gridView:getContentOffset().y)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local curCell = self:GetCellAtIndex(self.clickTag)
	local tCell = self:GetCellAtIndex(tag)
	if curCell then
		curCell.toggleView:setChecked(false)
		curCell.selectGoBg:setVisible(false)
		curCell:setLocalZOrder(1)
	end

	if tCell then
		tCell.toggleView:setChecked(true)
		tCell.selectGoBg:setVisible(true)
		tCell:setLocalZOrder(2)
	end

	if self.clickTag == tag then
		tCell.newImg:setVisible(false)
		self.cardsData[self.clickTag].isNew = 1
		if gameMgr:GetCardDataByCardId(self.cardsData[self.clickTag].cardId) then
			gameMgr:GetCardDataByCardId(self.cardsData[self.clickTag].cardId).isNew = 1
			self:GoToHeroMessLayer(self.clickTag)
		else
			curCell.selectGoBg:setVisible(false)
		end
	else
		self.clickTag = tag
		self:UpdataLeftUi(tag)
	end
	GuideUtils.DispatchStepEvent()
end


--[[
展示属性变化飘字动画
typee : 1 为升星飘字变化属性 2 为升级飘字变化属性 int
--]]
function CardsListMediatorNew:ShowAddPropertyLabelAction(typee)
	local data  = self.cardsData[self.clickTag]
	local tab1 = {}
	local tab2 = {}

	local cardId = checkint(data.cardId)
	local level = checkint(data.level)
	local breakLevel = checkint(data.breakLevel)
	local favorLevel = checkint(data.favorabilityLevel)
	local bookData = app.cardMgr.GetBookDataByCardId(cardId)
	if typee == 1 then

		tab1 = CardUtils.GetCardAllFixedP(
				cardId, level, math.max(0, breakLevel - 1), favorLevel,
				data.pets, data.artifactTalent, bookData
		)

		tab2 = CardUtils.GetCardAllFixedP(
				cardId, level, breakLevel, favorLevel,
				data.pets, data.artifactTalent, bookData
		)

	elseif typee == 2 then

		tab1 = CardUtils.GetCardAllFixedP(
				cardId, (checkint(self.oldLevel)), breakLevel, favorLevel,
				data.pets, data.artifactTalent, bookData
		)

		tab2 = CardUtils.GetCardAllFixedP(
				cardId, level, breakLevel, favorLevel,
				data.pets, data.artifactTalent, bookData
		)

	end
	local tempTab = {}
	local bool = false
	for i,v in ipairs(propertyData) do
		local curProp = tab1[v.pName]
		local breakedProp = tab2[v.pName]
		local deltaProp = breakedProp - curProp
		if deltaProp > 0 then
			local tempStr = v.name..'  +  '..deltaProp
			table.insert(tempTab,tempStr)
			bool = true
		end
	end
	local function show( index )
		-- body
		if index <= 0 then
			return
		end
		local tempLabel = display.newLabel(350 , display.height * 0.65 ,--639f20
				{text = tempTab[index],ttf = true, font = TTF_GAME_FONT ,fontSize = 30, color = '#ffffff', ap = cc.p(0.5, 0.5)})
		tempLabel:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		self:GetViewComponent():addChild(tempLabel,10)

		local j = cc.ScaleTo:create(0.5,0.1)
		local k = cc.FadeIn:create(0.5)
		local l = cc.ScaleTo:create(0.5,1.2)
		local i = cc.Sequence:create(cc.DelayTime:create(0.5),
				cc.CallFunc:create(function ()
					show(index - 1)
				end))
		local a = cc.Spawn:create(j,k,l,i)

		local m = cc.MoveBy:create(0.6,cc.p(0,150))
		local n = cc.FadeOut:create(0.5)
		local b = cc.Spawn:create(m,n)
		local sequenceAction = cc.Sequence:create(a,b,
				cc.CallFunc:create(function ()
					tempLabel:runAction(cc.RemoveSelf:create())
				end))
		tempLabel:runAction(sequenceAction)
	end

	if bool == true then
		show(table.nums(tempTab))
	end
end

--刷新卡牌列表选择卡牌详情
function CardsListMediatorNew:UpdataRightUi()
	local cell = self:GetCellAtIndex(self.clickTag)
	if cell then
		-- local num = cardMgr.GetCardStaticBattlePoint(self.cardsData[self.clickTag].cardId, self.cardsData[self.clickTag].level, self.cardsData[self.clickTag].breakLevel,self.cardsData[self.clickTag].favorabilityLevel)
		local num = cardMgr.GetCardStaticBattlePointById(checkint(self.cardsData[self.clickTag].id))
		cell.heroFightLabel:setString(string.fmt(__('灵力：_lv_'),{_lv_ = num}))
		cell.heroLvLabel:setString(string.fmt(__('_lv_级'),{_lv_ = self.cardsData[self.clickTag].level}))
	end
end
--刷新卡牌立绘和背景
function CardsListMediatorNew:UpdataLeftUi(index)
	local data  = self.cardsData[index]
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	local heroLvLabel = viewData.heroLvLabel
	local heroExpLabel = viewData.heroExpLabel
	local expBar = viewData.expBar
	local qualityImg = viewData.qualityImg
	local starTab = viewData.starTab

	local contractBtn = viewData.contractBtn
	local btnGlowImg = viewData.btnGlowImg
	local setMainLayoutHeroBtn = viewData.setMainLayoutHeroBtn
	local loveLabel = viewData.loveLabel
	local loveBar = viewData.loveBar
	if data then
		self:hideMainCardVoiceWord_()

		setMainLayoutHeroBtn:setNormalImage(_res('ui/cards/love/card_ico_set_cover_normal.png'))
		setMainLayoutHeroBtn:setSelectedImage(_res('ui/cards/love/card_ico_set_cover_normal.png'))
		if gameMgr:GetUserInfo().signboardId then
			if checkint(gameMgr:GetUserInfo().signboardId) == checkint(data.id)  then
				setMainLayoutHeroBtn:setNormalImage(_res('ui/cards/love/card_ico_set_cover_active.png'))
				setMainLayoutHeroBtn:setSelectedImage(_res('ui/cards/love/card_ico_set_cover_active.png'))
			end
		end

		--未拥有卡牌隐藏升级经验框
		local cell = self:GetCellAtIndex(index)
		if not gameMgr:GetCardDataByCardId(data.cardId) then
			viewData.heroMessLayout:setVisible(false)
			if self.args == nil then
				if cell then
					cell.selectGoBg:setVisible(false)
				end
			end
			setMainLayoutHeroBtn:setVisible(false)
		else
			viewData.heroMessLayout:setVisible(true)
			if self.args == nil then
				if cell then
					cell.selectGoBg:setVisible(true)
				end
			end
			setMainLayoutHeroBtn:setVisible(true)
		end

		--契约是否满级
		local favorabilityData = CommonUtils.GetConfig('cards', 'favorabilityLevel', checkint(data.favorabilityLevel)) or {}
		-- dump(data.favorabilityLevel)
		local nowLvExp = (checkint(data.favorability) - checkint(favorabilityData.totalExp))
		local needLvExp = 0
		if CommonUtils.GetConfig('cards', 'favorabilityLevel',data.favorabilityLevel+1) then
			needLvExp = (CommonUtils.GetConfig('cards', 'favorabilityLevel',data.favorabilityLevel+1).exp or 999999)
		else
			needLvExp = (CommonUtils.GetConfig('cards', 'favorabilityLevel',data.favorabilityLevel).exp or 999999)
		end
		if nowLvExp < 0 then
			nowLvExp = 0
		end
		if  loveLabel then
			loveLabel:setString(nowLvExp..'/'..needLvExp )--..'好感度等级：'..data.favorabilityLevel
			if checkint(data.favorabilityLevel) >= 6 then
				loveBar:setPercentage(100)
				loveLabel:setString('')
			else
				local percent = nowLvExp / needLvExp * 100
				loveBar:setPercentage(percent)
			end


			local path = string.format('ui/cards/love/card_btn_contract_%d.png',data.favorabilityLevel)
			if not utils.isExistent(path) then
				path = 'ui/cards/love/card_btn_contract_1.png'
			end
			contractBtn:getLabel():setString(favorabilityData.name or __('契约'))
			contractBtn:setTag(index)
			contractBtn:setNormalImage(_res(path))
			contractBtn:setSelectedImage(_res(path))
			btnGlowImg:setVisible(cardMgr.GetMarriable(data.id))
		end

		-- 刷新卡牌形象
		if self.isInitedViews_ then
			self:UpdateCardFacade(data)
		else
			-- preload first card textures
			local cardSkinId = app.cardMgr.GetCardSkinIdByCardId(data.cardId)
			local drawName   = CardUtils.GetCardDrawNameBySkinId(cardSkinId)
			if CardUtils.IsShowCardLive2d(cardSkinId) and gameMgr:GetCardDataByCardId(data.cardId) then
				local textureList = CardUtils.GetCardLive2dTextureList(drawName, true)
				for _, texturePath in ipairs(textureList) do
					display.loadImage(texturePath)
				end
			else
				local drawBgPath  = CardUtils.GetCardDrawBgPathBySkinId(cardSkinId)
				local drawFgPath  = CardUtils.GetCardDrawFgPathBySkinId(cardSkinId)
				local drawImgPath = AssetsUtils.GetCardDrawPath(drawName)
				display.loadImage(drawImgPath)
				display.loadImage(drawBgPath)
				display.loadImage(drawFgPath)
			end
		end
		
		--等级和经验
		local breakLevel = data.breakLevel
		local maxLevel = self.allCardConfs_[tostring(data.cardId)].breakLevel[checkint(breakLevel)+1] or 120
		self.maxLevel = maxLevel

		heroLvLabel:setString(string.format(('%d/%d'), checkint(data.level),maxLevel))

		local nowLvExp = (checkint(data.exp) - CommonUtils.GetConfig('cards', 'level',data.level).totalExp)
		local needLvExp = 0
		if checkint(data.level) >= table.nums(CommonUtils.GetConfigAllMess('level','cards')) then
			needLvExp = CommonUtils.GetConfig('cards', 'level',data.level).exp
		else
			needLvExp = CommonUtils.GetConfig('cards', 'level',data.level+1).exp
		end
		if nowLvExp < 0 then
			nowLvExp = 0
		end
		heroExpLabel:setString(string.format(('%d/%d'), nowLvExp,needLvExp))

		if  self.BshowLevelUpAction and self.BshowLevelUpAction == 1 then
			self.BshowLevelUpAction = 3
			self:ShowAddPropertyLabelAction(2)
			self:RefreshCardExp(self.oldLevel,maxLevel)
		elseif  self.BshowLevelUpAction and self.BshowLevelUpAction == 2 then
			self:ShowAddPropertyLabelAction(2)
			local btnSpine = sp.SkeletonAnimation:create('effects/shengxing/shengxing.json', 'effects/shengxing/shengxing.atlas', 1)
			btnSpine:update(0)
			btnSpine:setAnimation(0, 'shengji', false)--shengxing1 shengji
			uiMgr:GetCurrentScene():addChild(btnSpine,100)
			btnSpine:setPosition(cc.p(0,0))
			btnSpine:registerSpineEventHandler(function (event)
				if event.animation == "shengji" then
					print("====== hit end ====")
					btnSpine:runAction(cc.RemoveSelf:create())
				end
			end, sp.EventType.ANIMATION_END)
			self.BshowLevelUpAction = 3
			self.oldLevel = data.level
		elseif  self.BshowLevelUpAction and self.BshowLevelUpAction == 4 then
			self:ShowAddPropertyLabelAction(2)
			local btnSpine = sp.SkeletonAnimation:create('effects/shengxing/shengxing.json', 'effects/shengxing/shengxing.atlas', 1)
			btnSpine:update(0)
			btnSpine:setAnimation(0, 'shengji', false)--shengxing1 shengji
			uiMgr:GetCurrentScene():addChild(btnSpine,100)
			btnSpine:setPosition(cc.p(0,0))
			btnSpine:registerSpineEventHandler(function (event)
				if event.animation == "shengji" then
					print("====== hit end ====")
					btnSpine:runAction(cc.RemoveSelf:create())
				end
			end, sp.EventType.ANIMATION_END)
			self.BshowLevelUpAction = 3

			local percent = nowLvExp / needLvExp * 100
			expBar:setPercentage(percent)
		else
			local percent = nowLvExp / needLvExp * 100
			expBar:setPercentage(percent)
		end

		--品级
		qualityImg:setTexture(CardUtils.GetCardQualityIconPathByCardId(data.cardId))

		--星级

		if self.showStar == true then
			self.showStar = false
		else
			for i,v in ipairs(starTab) do
				v:setVisible(true)
				if i > checkint(data.breakLevel) then
					v:setVisible(false)
				end
			end
		end
	end
	self:RefreshArtifactIcon()

end

function CardsListMediatorNew:UpdateCardFacade(data)
	local viewComponent = self:GetViewComponent()
	local viewData      = viewComponent.viewData
	local heroImg       = viewData.heroImg
	local heroBg        = viewData.heroBg
	local heroFg        = viewData.heroFg
	local l2dDrawNode   = viewData.l2dDrawNode
	local particleSpine = viewData.particleSpine
	--立绘和背景
	if not gameMgr:GetCardDataByCardId(data.cardId) then
		heroImg:GetAvatar():setFilterName(filter.TYPES.GRAY)
		if particleSpine then particleSpine:setVisible(false) end
	else
		heroImg:GetAvatar():setFilterName()
		if particleSpine then particleSpine:setVisible((cardMgr.GetCouple(data.id))) end
	end
	heroImg:RefreshAvatar({cardId = data.cardId, showBg = true})
	local cardSkinId = app.cardMgr.GetCardSkinIdByCardId(data.cardId)
	local drawBgPath = CardUtils.GetCardDrawBgPathBySkinId(cardSkinId)
	local drawFgPath = CardUtils.GetCardDrawFgPathBySkinId(cardSkinId)
	heroBg:setTexture(drawBgPath)
	heroFg:setTexture(drawFgPath)

	if l2dDrawNode then
		if CardUtils.IsShowCardLive2d(cardSkinId) and gameMgr:GetCardDataByCardId(data.cardId) then
			l2dDrawNode:refreshL2dNode({cardId = data.cardId, bgMode = true, motion = "Start"})
			heroImg:setVisible(false)
			heroBg:setVisible(not CardUtils.IsExistentGetCardLive2dModelAtSkinId(cardSkinId, true))
			heroFg:setVisible(false)
		else
			l2dDrawNode:cleanL2dNode()
			heroImg:setVisible(true)
			heroBg:setVisible(true)
			heroFg:setVisible(true)
		end
	end

	if self.offsetY ~= 0 then
		heroImg.avatar:setPositionX(heroImg.avatar:getPositionX()+(-1*(self.offsetY)))
		heroImg.avatar:runAction(cc.Spawn:create(
				cc.FadeIn:create(0.2),
				cc.MoveTo:create(0.2,cc.p(heroImg.avatar:getPositionX()+(self.offsetY),heroImg.avatar:getPositionY()))
		))
		self.offsetY = 0
	end
end

--显示卡牌星级.和刷新是否可升星红点
function CardsListMediatorNew:showStarrr()
	local data  = self.cardsData[self.clickTag]
	local viewData = self:GetViewComponent().viewData
	local starTab = viewData.starTab
	for i,v in ipairs(starTab) do
		v:setVisible(true)
		if i > checkint(data.breakLevel) then
			v:setVisible(false)
		end
	end

	local goodsid = 0
	goodsid  = checkint(data.cardId) % 200000
	goodsid = goodsid+140000
	local cell = self:GetCellAtIndex(self.clickTag)
	if cell then
		if checkint(data.breakLevel) + 1 >= table.nums(self.allCardConfs_[tostring(data.cardId)].breakLevel) then
			cell.redImg:setVisible(false)
		else
			if checkint(gameMgr:GetAmountByGoodId(goodsid)) >= checkint(CommonUtils.GetConfig('cards', 'cardBreak',data.qualityId).breakConsume[data.breakLevel+1]) and gameMgr:GetUserInfo().gold >= checkint(CommonUtils.GetConfig('cards', 'cardBreak',data.qualityId).breakGoldConsume[data.breakLevel+1]) then
				cell.redImg:setVisible(true)
			else
				cell.redImg:setVisible(false)
			end
		end
	end
end

--碎片合成卡牌按钮回调
function CardsListMediatorNew:ComposeHeroCallBack(pSender)
	local tag = pSender:getTag()
	if self.clickTag == tag then
		--添加一个融合判断提示
		self.composeNum = tag
		local data  = self.cardsData[tag]
		if not GuideUtils.IsGuiding() then
			local scene = uiMgr:GetCurrentScene()
			local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('是否使用碎片进行融合操作'),
																	 isOnlyOK = false, callback = function ()
					self:SendSignal(COMMANDS.COMMAND_Hero_Compose_Callback, { cardId = data.cardId})
				end})
			CommonTip:setPosition(display.center)
			scene:AddDialog(CommonTip)
		else
			self:SendSignal(COMMANDS.COMMAND_Hero_Compose_Callback, { cardId = data.cardId})
		end
	end
end
--卡牌列表数据
function CardsListMediatorNew:OnDataSourceAction(p_convertview,idx)
	local pCell = p_convertview
	local index = idx + 1
	local sizee = cc.size(545,107)
	if pCell == nil then
		pCell = CardsListCellNew.new()
		pCell.toggleView:setOnClickScriptHandler(handler(self,self.CellButtonAction))
		pCell.selectGoBg:setOnClickScriptHandler(handler(self,self.GoToHeroMessLayer))
		if index <= 9 and checkint(self.clickTag) == 1 then
			pCell.eventnode:setPositionX(sizee.width + 800)
			pCell.eventnode:runAction(cc.Sequence:create(
				cc.DelayTime:create(index * 0.025),
				cc.EaseOut:create(cc.MoveTo:create(0.2, cc.p(sizee.width* 0.5 + 8,sizee.height * 0.5)), 0.7)
			))
		else
			pCell.eventnode:setPosition(cc.p(sizee.width* 0.5 + 8,sizee.height * 0.5))
		end
	else
		pCell.eventnode:setPosition(cc.p(sizee.width* 0.5 + 8,sizee.height * 0.5))
		pCell.toggleView:setChecked(false)
		pCell.selectGoBg:setVisible(false)
	end

	xTry(function()
		pCell:setOpacity(255)
		pCell.toggleView:setTag(index)
		pCell.selectGoBg:setTag(index)
		if self.clickTag == index then
			pCell.toggleView:setChecked(true)
			pCell.selectGoBg:setVisible(true)
			pCell:setLocalZOrder(2)
		else
			pCell.toggleView:setChecked(false)
			pCell.selectGoBg:setVisible(false)
			pCell:setLocalZOrder(1)
		end

		--是否是新卡牌
		if self.cardsData[index].isNew == 2 then
			pCell.newImg:setVisible(true)
		else
			pCell.newImg:setVisible(false)
		end

		local cardId = self.cardsData[index].cardId

		pCell:setUserTag(checkint(self.cardsData[index].cardId))
		pCell:setTag(index)
		--是否满足可升星条件
		local goodsid = 0
		goodsid = checkint(cardId)%200000
		goodsid = goodsid+140000

		if checkint(self.cardsData[index].breakLevel)+1 >= table.nums(self.allCardConfs_[tostring(cardId)].breakLevel) then
			pCell.redImg:setVisible(false)
		else
			if checkint(gameMgr:GetAmountByGoodId(goodsid)) >= checkint(CommonUtils.GetConfig('cards', 'cardBreak',self.cardsData[index].qualityId).breakConsume[self.cardsData[index].breakLevel+1]) and gameMgr:GetUserInfo().gold >= checkint(CommonUtils.GetConfig('cards', 'cardBreak',self.cardsData[index].qualityId).breakGoldConsume[self.cardsData[index].breakLevel+1]) then
				pCell.redImg:setVisible(true)
			else
				pCell.redImg:setVisible(false)
			end
		end

		local cardConf = CardUtils.GetCardConfig(cardId)
		local bgJobStr = basename(CardUtils.GetCardCareerIconFramePathByCardId(cardId))
		if bgJobStr and string.len(bgJobStr) > 0  then
			pCell.bgJob:setSpriteFrame(bgJobStr)
		end
		local jobImgStr = basename(CardUtils.GetCardCareerIconPathByCardId(cardId))
		if jobImgStr and string.len(jobImgStr) > 0  then
			pCell.jobImg:setSpriteFrame(jobImgStr)
		end
		local headRankImgImgStr = basename(CardUtils.GetCardQualityHeadFramePathByCardId(cardId))
		if headRankImgImgStr and string.len(headRankImgImgStr) > 0  then
			pCell.headRankImg:setSpriteFrame(headRankImgImgStr)
		end
		local skinId   = cardMgr.GetCardSkinIdByCardId(cardId)
		local headPath = CardUtils.GetCardHeadPathBySkinId(skinId)
		pCell.headImg:setTexture(headPath)

		if self.cardsData[index].id then
			CommonUtils.SetCardNameLabelStringById(pCell.heroNameLabel, self.cardsData[index].id, pCell.nameLabelParams)
		else
			CommonUtils.SetCardNameLabelStringByIdUseTTF(pCell.heroNameLabel, 0, pCell.nameLabelParams, cardConf.name)
		end
		if pCell.particleSpine then pCell.particleSpine:setVisible(cardMgr.GetCouple(self.cardsData[index].id)) end

		pCell.fragmentBtn:setOnClickScriptHandler(handler(self,self.ComposeHeroCallBack))
		pCell.fragmentBtn:setTag(index)
		if not gameMgr:GetCardDataByCardId(cardId) then--未拥有卡牌
			-- pCell.toggleView:setChecked(false)
			pCell.selectGoBg:setVisible(false)
			-- pCell:setLocalZOrder(2)
			pCell.toggleView:setNormalImage(_res('ui/home/cardslistNew/card_preview_bg_list_unslected_1.png'))
			pCell.heroLvLabel:setVisible(false)
			pCell.heroFightLabel:setVisible(false)
			pCell.stateLabel:setVisible(false)
			pCell.redImg:setVisible(false)
			pCell.fragmentBtn:setVisible(true)
			pCell.fragmentBarBg:setVisible(true)
			pCell.fragmentBar:setVisible(true)
			pCell.fragmentLabel:setVisible(true)
			local composNum = CommonUtils.GetConfig('cards', 'cardConversion',self.cardsData[index].qualityId).composition
			pCell.fragmentLabel:setString(string.fmt(('_num1_/_num2_'),{_num1_ = gameMgr:GetAmountByGoodId(goodsid) ,_num2_ = composNum}))
			pCell.fragmentBar:setPercentage(( gameMgr:GetAmountByGoodId(goodsid) / composNum ) * 100)
			if checkint(gameMgr:GetAmountByGoodId(goodsid)) >= checkint(composNum) then--满足碎片数量条件
				pCell.fragmentBtn:getLabel():setString(__('可合成'))
				-- pCell.fragmentBtn:setVisible(true)
				pCell.fragmentBar:setSprite(cc.Sprite:create(_res('ui/home/cardslistNew/card_preview_ico_loading_fragment.png')))
			else
				pCell.fragmentBtn:getLabel():setString(__('获取'))
				pCell.fragmentBtn:setOnClickScriptHandler(function()
					PlayAudioByClickNormal()
					uiMgr:AddDialog('common.GainPopup', {goodId = tonumber(goodsid)})
				end)
				-- pCell.fragmentBtn:setVisible(false)
				pCell.fragmentBar:setSprite(cc.Sprite:create(_res('ui/home/cardslistNew/card_preview_ico_loading_fragment_not.png')))
			end

			local grayFilter = GrayFilter:create()
			pCell.headImg:setFilter(grayFilter)
			pCell.headRankImg:setFilter(grayFilter)
		else
			pCell.toggleView:setNormalImage(_res('ui/home/cardslistNew/card_preview_bg_list_unslected.png'))
			pCell.heroFightLabel:setVisible(true)
			pCell.heroLvLabel:setVisible(true)
			pCell.fragmentBarBg:setVisible(false)
			pCell.fragmentBar:setVisible(false)
			pCell.fragmentLabel:setVisible(false)
			pCell.fragmentBtn:setVisible(false)
			pCell.headImg:clearFilter()
			pCell.headRankImg:clearFilter()
			local num = cardMgr.GetCardStaticBattlePointById(checkint(self.cardsData[index].id))
			pCell.heroFightLabel:setString(string.fmt(__('灵力：_lv_'),{_lv_ = num}))
			pCell.heroLvLabel:setString(string.fmt(__('_lv_级'),{_lv_ = self.cardsData[index].level}))

			local places = {}
			if self.cardsData[index].id then
				places = gameMgr:GetCardPlace({id = self.cardsData[index].id})
			end
			if places[tostring(CARDPLACE.PLACE_TEAM)] then
				pCell.stateLabel:setVisible(true)
				local teamInfo = nil
				teamInfo = gameMgr:GetTeamInfo({id = self.cardsData[index].id},false)
				if teamInfo then
					pCell.stateLabel:getLabel():setString(string.format(__('第%d编队'), checkint(teamInfo.teamId)))
				else
					pCell.stateLabel:setVisible(false)
				end
			else
				local keys = table.keys(places)
				local name,state = gameMgr:GetModuleName(keys[1])
				if name then
					pCell.stateLabel:setVisible(true)
					pCell.stateLabel:getLabel():setString(name)
				else
					pCell.stateLabel:setVisible(false)
				end
			end
			-- 检测模块是否存在
		end
		if CommonUtils.GetModuleAvailable(MODULE_SWITCH.ARTIFACT) then
			local artifactIcon = pCell.artifactIcon
			local artifactStatus =  checkint(cardConf.artifactStatus)
			if artifactStatus == 1 then
				if checkint(self.cardsData[index].isArtifactUnlock)  == 1  then
					artifactIcon:setVisible(true)
					artifactIcon:setOpacity(255)
				else
					artifactIcon:setVisible(true)
					artifactIcon:setOpacity(125)
				end
				artifactIcon:setTexture(CommonUtils.GetArtifiactPthByCardId(cardId))
			else
				artifactIcon:setVisible(false)
			end
		end
	end,__G__TRACKBACK__)
	return pCell
end

function CardsListMediatorNew:OnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
	local CardsListCommand = require( 'Game.command.CardsListCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Hero_Compose_Callback, CardsListCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Hero_SetSignboard, CardsListCommand)
	regPost(POST.ALTER_CARD_NICKNAME)
	--从卡牌页面进入时显示
	if self.args ~= nil then
		local clickTag = 1
		local cardId = checkint(self.args.cardId)
		if cardId > 0 then
			for index , cardData in pairs(self.cardsData) do
				if checkint(cardData.cardId)  == cardId  then
					clickTag = index
					break
				end
			end
		end
		self.clickTag = clickTag
		self:UpdataLeftUi(self.clickTag)
		self:GoToHeroMessLayer( self.clickTag )
	end
end

function CardsListMediatorNew:OnUnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Hero_Compose_Callback)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Hero_SetSignboard)
	unregPost(POST.ALTER_CARD_NICKNAME)
	if self.TtimeUpdateFunc then
		scheduler.unscheduleGlobal(self.TtimeUpdateFunc)
	end
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return CardsListMediatorNew
