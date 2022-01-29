local GameScene = require('Frame.GameScene')
---@class CardsListViewNew
local CardsListViewNew = class('CardsListViewNew', GameScene)

local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local screenType = {
	{tag = 0, typeDescr = __('全部')},
	{tag = CardUtils.CAREER_TYPE.DEFEND},
	{tag = CardUtils.CAREER_TYPE.ATTACK},
	{tag = CardUtils.CAREER_TYPE.ARROW},
	{tag = CardUtils.CAREER_TYPE.HEART},
	{tag = 5, typeDescr = __('碎片'), bgPath = 'ui/cards/head/card_order_ico_yellow.png', iconPath = 'ui/cards/head/kapai_job_fragment.png'}
}

local sortType = {
	{tag = 0, typeDescr = __('默认')},
	{tag = 1, typeDescr = __('等级')},
	{tag = 2, typeDescr = __('稀有度')},
	{tag = 3, typeDescr = __('灵力')},
	{tag = 4, typeDescr = __('星级')},
	{tag = 5, typeDescr = __('好感度')},
	{tag = 6, typeDescr = __('编队信息')},
}

function CardsListViewNew:ctor( ... )
	GameScene.ctor(self,'views.CardsListViewNew')

	self.args = unpack({...}) or {}
	if  (CommonUtils.GetModuleAvailable(MODULE_SWITCH.ARTIFACT))  and CommonUtils.CheckModuleIsExitByModuleId(MODULE_DATA[tostring(RemindTag.ARTIFACT_TAG)]) then
		if #screenType == 6  then
			screenType[#screenType+1] = {tag = 6, typeDescr = __('神器'), bgPath = 'ui/cards/head/core_ico_core.png'}
		end
	end

	local function CreateView()
		local view = CLayout:create(display.size)
		view:setName('view')
		display.loadImage(_res('ui/home/handbook/pokedex_card_bg.jpg'))
		display.loadImage(_res('ui/home/cardslistNew/card_preview_bg.png') , function()
			local bgPath  = _res('ui/home/cardslistNew/card_preview_bg.png')
			local bgSize  = cc.size(math.max(display.SAFE_R + 60, 1624), 1002)
			local bgPoint = cc.p(display.SAFE_R + 60, display.cy)
			local bgImage = ui.image({img = bgPath, size = bgSize, cut = cc.dir(260, 1, 1080, 1), p = bgPoint, ap = ui.rc})
			if view and not tolua.isnull(view) then
				view:addChild(bgImage, 2)
			end
		end)

		--属性详情立绘
		local scaleRate = (display.width - 1334) / 1334
		local isScaleRole = scaleRate > 0
		local scale = isScaleRole and 1 + scaleRate + 0.06 or 1
		local leftView = CLayout:create(cc.size(1002, display.size.height))
		leftView:setAnchorPoint(cc.p(0, 0.5))
		leftView:setPosition(cc.p(display.SAFE_L, display.size.height * 0.5))
		view:addChild(leftView,1)

		local lsize = leftView:getContentSize()

		-- 立绘
		local heroLayer = display.newLayer(0, 0, {size = lsize, ap = display.LEFT_BOTTOM})
		heroLayer:setScale(scale)
		local heroLayerY = scale > 1 and scaleRate * display.size.height * -1 or 0
		heroLayer:setPositionY(heroLayerY)
		leftView:addChild(heroLayer,2)


		local designSize = cc.size(1334, 750)
		local winSize = display.size
		local deltaHeight = (winSize.height - designSize.height) * 0.5

		local l2dDrawNode = nil
		if GAME_MODULE_OPEN.CARD_LIVE2D then
			l2dDrawNode = require('common.CardSkinL2dNode').new({notRefresh = true})
			leftView:addChild(l2dDrawNode, 2)
		end

		--卡牌立绘
		local secData = {confId = 200001, coordinateType = COORDINATE_TYPE_CAPSULE}
		local heroImg = require('common.CardSkinDrawNode').new(secData)
		heroLayer:addChild(heroImg,2)
		local heroAvataePos = cc.p(heroImg.avatar:getPosition())
		local heroScale = heroImg.avatar:getScale()
		local defaultBg = display.newImageView(_res('ui/home/handbook/pokedex_card_bg.jpg'))
		defaultBg:setPosition(cc.p(heroAvataePos.x ,display.cy))
		defaultBg:setAnchorPoint(cc.p(0, 0.5))
		defaultBg:setScale(heroScale)
		heroLayer:addChild(defaultBg)
		local particleSpine = nil
		if CommonUtils.GetModuleAvailable(MODULE_SWITCH.MARRY) then
			particleSpine = display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly')
			particleSpine:setPosition(cc.p(display.SAFE_L + 380, deltaHeight))
			heroLayer:addChild(particleSpine,2)
			particleSpine:setAnimation(0, 'idle2', true)
			particleSpine:update(0)
			particleSpine:setToSetupPose()
			particleSpine:setVisible(false)
		end

		local voiceTouchArea = display.newLayer(120, display.cy - 280, {size = cc.size(display.width - 2 * display.SAFE_L - 730, display.cy + 160), color = cc.r4b(0), ap = cc.p(0, 0), enable = true})
		leftView:addChild(voiceTouchArea,100)

		--卡牌立绘背景
		local heroBg = app.loadImage.new('ui/common/story_tranparent_bg.png')
		--AssetsUtils.GetCardDrawBgNode(skinId)
	    heroBg:setPosition(cc.p(heroAvataePos.x,display.cy))
	    heroBg:setAnchorPoint(cc.p(0, 0.5))
	    heroBg:setScale(heroScale)
		heroLayer:addChild(heroBg)
		
		--卡牌立绘前景
		local heroFg = app.loadImage.new('ui/common/story_tranparent_bg.png')
		--AssetsUtils.GetCardDrawFgNode(skinId)
	    heroFg:setPosition(cc.p(heroAvataePos.x ,display.cy))
	    heroFg:setAnchorPoint(cc.p(0, 0.5))
	    heroFg:setScale(heroScale)
		heroLayer:addChild(heroFg, 3)
		

 		local rightUpView = display.newLayer(0,0 ,{size = cc.size(525, 480 ) , color1 =cc.r4b()})
		--CLayout:create(cc.size(525, 385 ))
		rightUpView:setAnchorPoint(cc.p(1,1))
		rightUpView:setPosition(cc.p(display.SAFE_R, display.size.height - 5))
		view:addChild(rightUpView, 20)
		-- rightUpView:setBackgroundColor(cc.c4b(0, 128, 0, 255))


		local tempStr = display.newLabel(display.SAFE_R - 600 , 60,
		{text = __('收集度'), fontSize = 22, color = '#ffffff',ap = cc.p(0.5,0)})
		-- rightUpView:addChild(tempStr, 10)
		view:addChild(tempStr, 30)

		local heroNum = display.newLabel(display.SAFE_R - 600 ,30,
		{text = (''), fontSize = 22, color = '#ffffff',ap = cc.p(0.5,0)})
		-- rightUpView:addChild(heroNum, 10)
		view:addChild(heroNum, 30)

		local rightUpViewSize = rightUpView:getContentSize()
		local compeseBtn = display.newButton(0, 0, {ap = display.CENTER,n = _res('ui/common/card_preview_btn_compese.png')})
		display.commonUIParams(compeseBtn, {ap = cc.p(1,1),po = cc.p(rightUpView:getContentSize().width - 20, rightUpView:getContentSize().height - 4)})
		display.commonLabelParams(compeseBtn,{text = __('碎片融合'),ttf = true, hAlign =display.TAC , w = 140 , font = TTF_GAME_FONT, fontSize = 24, color = '#ffffff',outline = '#5c5c5c'})
		rightUpView:addChild(compeseBtn, 6)
		
		local findBtn = nil
		if GAME_MODULE_OPEN.CARD_LIST_FIND then
			findBtn = ui.button({n = _res('ui/ttgame/home/cardgame_main_btn_search.png'), zorder = 20, cut = cc.dir(18,18,18,18), size = cc.size(82,76)})
			view:addList(findBtn):alignTo(rightUpView, ui.lt, {offsetX = 10, offsetY = -78})
		end

		local sortBg = display.newImageView(_res('ui/home/cardslistNew/card_preview_bg_order.png'), 0,0)--kitchen_bg_1 hall_bg_1
		rightUpView:addChild(sortBg)
 		sortBg:setPosition(cc.p(rightUpViewSize.width,rightUpViewSize.height ))
 		sortBg:setAnchorPoint(cc.p(1,1))

		local screenBtn = display.newCheckBox(0, 0,
			{n = _res('ui/home/cardslistNew/card_preview_btn_unselection.png'), s = _res('ui/home/cardslistNew/card_preview_btn_selection.png')})
		display.commonUIParams(screenBtn, {po = cc.p(170, rightUpViewSize.height - 4),ap = cc.p(1,1)})--rightUpViewSize.width - 180
		rightUpView:addChild(screenBtn, 10)

		local screenBtnSize = screenBtn:getContentSize()
		local screenLabel = display.newLabel(screenBtnSize.width -45, utils.getLocalCenter(screenBtn).y + 4,
			fontWithColor(5,{text = __('筛选'),color = 'ffffff',fontSize = 22 , ap = display.RIGHT_CENTER}))
		screenBtn:addChild(screenLabel)

	    local arrowImg = display.newImageView(_res("ui/home/cardslistNew/card_ico_direction.png"),screenBtnSize.width/2 + 40,utils.getLocalCenter(screenBtn).y + 4)
	    arrowImg:setAnchorPoint(cc.p(0,0.5))
	    screenBtn:addChild(arrowImg)

		local sortBtn = display.newCheckBox(0, 0,
			{n = _res('ui/home/cardslistNew/card_preview_btn_unselection.png'), s = _res('ui/home/cardslistNew/card_preview_btn_selection.png')})
		display.commonUIParams(sortBtn, {po = cc.p(330, rightUpViewSize.height - 4),ap = cc.p(1,1)})
		rightUpView:addChild(sortBtn, 10)

		local sortLabel = display.newLabel(utils.getLocalCenter(sortBtn).x+35, utils.getLocalCenter(sortBtn).y + 4,
			fontWithColor(5,{text = __('排序'),color = 'ffffff',fontSize = 22, ap = display.RIGHT_CENTER}))
		sortBtn:addChild(sortLabel)

		local arrowImg = display.newImageView(_res('ui/home/cardslistNew/tujian_selection_select_ico_filter_direction.png'))
		arrowImg:setAnchorPoint(cc.p(0.5,0.5))
		arrowImg:setTag(9)
		arrowImg:setPosition(cc.p(sortBtn:getContentSize().width *0.5 + 50,sortBtn:getContentSize().height *0.5 + 4))
		sortBtn:addChild(arrowImg)
		arrowImg:setVisible(false)


		local rightView = CLayout:create(cc.size(515, display.size.height - 90))
		rightView:setName('rightView')
		rightView:setAnchorPoint(cc.p(1,0))
		rightView:setPosition(cc.p(display.SAFE_R,0))
		view:addChild(rightView, 10)
		-- rightView:setBackgroundColor(cc.c4b(0, 128, 0, 100))
 		rightView:setVisible(false)


 		--卡牌列表
		local taskListSize = cc.size(535, display.size.height - 90)
		local taskListCellSize = cc.size(535, 110)

	   	local gridView = ui.tableView({size = taskListSize, dir = display.SDIR_V})
	   	-- local gridView = CGridView:create(taskListSize)
		gridView:setName('gridView')
	    gridView:setSizeOfCell(taskListCellSize)
	    -- gridView:setColumns(1)
	    gridView:setAutoRelocate(false)
	    gridView:setBounceable(true)
		view:addChild(gridView, 10)
		gridView:setAnchorPoint(cc.p(1, 0))
	    gridView:setPosition(cc.p(display.SAFE_R, 0))
	    -- gridView:setBackgroundColor(cc.c4b(200, 0, 0, 100))
		-- gridView:setVisible(false)

	    --左箭头
	    local leftSwichBtn = display.newButton(0, 0,
	    	{n = _res('ui/home/cardslistNew/card_skill_btn_switch.png'), animate = true})
	    display.commonUIParams(leftSwichBtn, {ap = cc.p(0,0.5),po = cc.p(display.SAFE_L + lsize.width *0.025, 100)})
	    -- leftView:addChild(leftSwichBtn,7)
	    view:addChild(leftSwichBtn,7)
		leftSwichBtn:setTag(1)
		leftSwichBtn:setScale(0.75)
		--右箭头
	    local rightSwichBtn = display.newButton(0, 0,
	    	{n = _res('ui/home/cardslistNew/card_skill_btn_switch.png'), animate = true})
	    display.commonUIParams(rightSwichBtn, {ap = cc.p(0,0),po = cc.p(display.SAFE_L + lsize.width *0.4 + 180, 132)})
	    -- leftView:addChild(rightSwichBtn,7)
	    view:addChild(rightSwichBtn,7)
	    rightSwichBtn:setRotation(-180)
	    rightSwichBtn:setTag(2)
	    rightSwichBtn:setScale(0.75)
		local heroMessBg = display.newImageView(_res('ui/home/cardslistNew/card_bg_grade.png'), 0, 0)
 		heroMessBg:setAnchorPoint(cc.p(0.5,0.5))

 		local heroMessLayout = CLayout:create(cc.size(450,90))
 		-- heroMessLayout:setBackgroundColor((cc.c4b(0, 128, 0, 100)))
 		heroMessLayout:setAnchorPoint(cc.p(0.5,0))
 		heroMessLayout:setPosition(cc.p((rightSwichBtn:getPositionX() - leftSwichBtn:getPositionX()) / 2, display.height*0.5 - 375))
 		leftView:addChild(heroMessLayout,10)
 		heroMessLayout:addChild(heroMessBg,6)
		heroMessBg:setPosition(cc.p(heroMessLayout:getContentSize().width*0.5 + 70,heroMessLayout:getContentSize().height*0.5))
		 
		local voiceWordLayer = display.newLayer(320, heroMessLayout:getPositionY() + 200)
		view:addChild(voiceWordLayer,60)

	    local tempLabel = display.newLabel(60,heroMessBg:getContentSize().height - 20,
	        {text = __('等级：'), fontSize = 20, color = '#ffffff', ap = cc.p(0, 1)})
	    heroMessBg:addChild(tempLabel,6)

	    local heroLvLabel = display.newLabel(140, heroMessBg:getContentSize().height - 20,
	        {text = '', fontSize = 20, color = '#ffffff', ap = cc.p(0.5, 1)})
	    heroMessBg:addChild(heroLvLabel,10)


		local expBarBg = display.newImageView(_res(_res('ui/home/cardslistNew/card_attribute_bg_star.png')))
		display.commonUIParams(expBarBg, {po = cc.p(174, heroMessBg:getContentSize().height*0.5 - 18)})
		heroMessBg:addChild(expBarBg, 5)

		local expBar = cc.ProgressTimer:create(cc.Sprite:create(_res('ui/home/cardslistNew/card_attribute_ico_loading_star.png')))
	 	expBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
	 	expBar:setMidpoint(cc.p(0, 0))
	 	expBar:setBarChangeRate(cc.p(1, 0))
		expBar:setPosition(utils.getLocalCenter(expBarBg))
		expBar:setPercentage(50)
	    expBarBg:addChild(expBar)

	    local heroExpLabel = display.newLabel(utils.getLocalCenter(expBarBg).x, utils.getLocalCenter(expBarBg).y,
	        {text = '', fontSize = 20, color = '#ffffff', ap = cc.p(0.5,0.5)})
	    expBarBg:addChild(heroExpLabel,10)
	    -- upgrade btn
	    local upgradeBtn = display.newButton(0, 0,
	    	{n = _res('ui/home/cardslistNew/card_preview_btn_levelup.png'), animate = false})--, cb = handler(self, self.upgradeBtnCallback)
	    display.commonUIParams(upgradeBtn, {ap = cc.p(0,0.5),po = cc.p(0, heroMessBg:getContentSize().height*0.5 - 5)})
		if isJapanSdk() then
			display.commonLabelParams(upgradeBtn, {text = __('升级'),fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#734441', reqW = 120, offset = cc.p(10, 0)})
		else
			display.commonLabelParams(upgradeBtn, {text = __('升级'),fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#734441'})
		end
	    heroMessLayout:addChild(upgradeBtn,7)


	    local starBg = display.newImageView(_res('ui/home/cardslistNew/card_mani_bg_star.png'),30, display.size.height - 140)

 		local starMessLayout = CLayout:create(cc.size(starBg:getContentSize().width,starBg:getContentSize().height + 40))
 		-- starMessLayout:setBackgroundColor((cc.c4b(0, 128, 0, 200)))
 		starMessLayout:setAnchorPoint(cc.p(0,1))
 		starMessLayout:setPosition(cc.p(30, display.size.height - 140))
 		leftView:addChild(starMessLayout,10)
 		starMessLayout:addChild(starBg,6)
 		starBg:setPosition(cc.p(starMessLayout:getContentSize().width*0.5,starMessLayout:getContentSize().height*0.5 + 34))
 		-- starBg:setVisible(false)

		local qualityImg = display.newImageView(CardUtils.GetCardQualityIconPathByCardId(CardUtils.DEFAULT_CARD_ID),starMessLayout:getContentSize().width*0.5,starMessLayout:getContentSize().height)
		starMessLayout:addChild(qualityImg,10)

 		local starTab = {}
		for i=1,5 do--checkint(dates.breakLevel)
	        local nightStar = display.newImageView(_res('ui/common/kapai_star_white_blank.png'), 0, 0,{ap = cc.p(0.5, 1)})
	        starMessLayout:addChild(nightStar,9)
	        nightStar:setPosition(cc.p(starMessLayout:getContentSize().width*0.5,starMessLayout:getContentSize().height - 30 - 45*(i-1)))

	        local lightStar = display.newImageView(_res('ui/common/common_star_l_ico.png'), 0, 0,{ap = cc.p(0.5, 1)})
	        starMessLayout:addChild(lightStar,10)

	        lightStar:setPosition(cc.p(starMessLayout:getContentSize().width*0.5,starMessLayout:getContentSize().height - 30 - 45*(i-1)))
	        table.insert(starTab,lightStar)
		end

		local modelViewSize =cc.size(150,480)
		local modelView = CLayout:create(modelViewSize)
		modelView:setAnchorPoint(cc.p(1,1))
 		modelView:setPosition(cc.p(display.SAFE_R - 560, display.cy + 360))
 		view:addChild(modelView,10)


 		--  modelView:setBackgroundColor((cc.c4b(0, 100, 0, 200)))
		local dummyBtn = nil
		if GAME_MODULE_OPEN.WOODEN_DUMMY and  CommonUtils.UnLockModule(JUMP_MODULE_DATA.WOODEN_DUMMY) then
			local modelBg = display.newImageView(_res('ui/home/card/card_bg_trestle_big.png'), 90, modelViewSize.height,{ap = cc.p(0.5, 1)})
			modelView:addChild(modelBg)
			local commonLayoutSize = cc.size(109,85)
			local dummyView     = CLayout:create(commonLayoutSize)
			dummyView:setAnchorPoint(cc.p(0.5,0))
			dummyView:setPosition(	cc.p(modelViewSize.width*0.45 , modelViewSize.height - 184))
			modelView:addChild(dummyView,10)
			local dummyBg = display.newImageView(_res('ui/home/card/card_commonframe_icon.png'),commonLayoutSize.width*0.5,42,{ap = cc.p(0.5,0.5)})
			dummyView:addChild(dummyBg)
			local tempImg = display.newImageView(_res('ui/home/card/card_bg_trestle_small.png'),commonLayoutSize.width*0.55,30,{ap = cc.p(0.5,0.5)})
			dummyView:addChild(tempImg,-1)
			dummyBtn = display.newButton(commonLayoutSize.width*0.495,40 , {  n = _res('ui/home/cardslistNew/card_preview_btn_exceries.png')})
			dummyBtn:setScale(0.9)
			dummyView:addChild(dummyBtn)
		end

		local presetTeamView = nil
		local presetTeamBtn = nil
		local presetTeamModuleUnlockList = CommonUtils.GetPresetTeamModuleUnlockList()
		if GAME_MODULE_OPEN.PRESET_TEAM and #presetTeamModuleUnlockList > 0 then
			local commonLayoutSize = cc.size(109,85)
			presetTeamView = CLayout:create(commonLayoutSize)
			presetTeamView:setAnchorPoint(cc.p(0.5,0))
			presetTeamView:setPosition(cc.p(modelViewSize.width * 0.68, modelViewSize.height - 280))
			modelView:addChild(presetTeamView,10)
			local presetTeamBg = display.newImageView(_res('ui/home/card/card_commonframe_icon.png'),commonLayoutSize.width*0.5,42,{ ap = cc.p(0.5,0.5)})
			presetTeamView:addChild(presetTeamBg)
			local tempImg = display.newImageView(_res('ui/home/card/card_bg_trestle_small.png'),commonLayoutSize.width*0.55,30,{ap = cc.p(0.5,0.5)})
			presetTeamView:addChild(tempImg,-1)
			presetTeamBtn = display.newButton(commonLayoutSize.width*0.495,40 , {  n = _res('ui/home/cardslistNew/card_preview_btn_team.png')})
			presetTeamBtn:setScale(0.9)
			presetTeamView:addChild(presetTeamBtn)

			if not CommonUtils.UnLockModule(JUMP_MODULE_DATA.WOODEN_DUMMY) then
				presetTeamView:setPosition(cc.p(modelViewSize.width*0.45 , modelViewSize.height - 184))
			end
		end

		--设置主页看板娘
 		local setMainLayoutHeroBg = display.newImageView(_res('ui/home/card/card_commonframe_icon.png'),modelViewSize.width*0.2, modelViewSize.height - 94,{ap = cc.p(0.5,0)})
        modelView:addChild(setMainLayoutHeroBg)

		local setMainLayoutHeroBtn = display.newButton(0, 0, {ap = display.CENTER,n = _res('ui/cards/love/card_ico_set_cover_normal.png')})
		display.commonUIParams(setMainLayoutHeroBtn, {ap = cc.p(0.5,0),po = cc.p(modelViewSize.width*0.18,modelViewSize.height - 107)})
        modelView:addChild(setMainLayoutHeroBtn, 1)
		local tabNameLabel = display.newButton(display.SAFE_L + 120, display.size.height + 190 ,{n = _res('ui/common/common_title.png'),enable = false,ap = cc.p(0, 1.0)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('飨灵列表'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
		view:addChild(tabNameLabel,10)


		local guideBtn = display.newButton(464 + display.SAFE_L, display.height - 42, {n = _res('guide/guide_ico_book')})
		display.commonLabelParams(guideBtn, fontWithColor(14,{text = __('指南'), fontSize = 28, color = 'ffffff',offset = cc.p(10,-18)}))
		guideBtn:setOnClickScriptHandler(function(sender)
			local guideNode = require('common.GuideNode').new({tmodule = 'card'})
			display.commonUIParams(guideNode, { po = display.center})
			sceneWorld:addChild(guideNode, GameSceneTag.Guide_GameSceneTag)
		end)
		view:addChild(guideBtn,10)


		return {
			view                 = view,
			leftView             = leftView,
			gridView             = gridView,

			voiceTouchArea       = voiceTouchArea,
			rightView            = rightView,
			heroImg              = heroImg,
			l2dDrawNode          = l2dDrawNode,
			particleSpine        = particleSpine,
			heroBg               = heroBg,
			heroFg               = heroFg,
			heroLvLabel          = heroLvLabel,
			expBar               = expBar,
			heroExpLabel         = heroExpLabel,
			starMessLayout       = starMessLayout,
			modelView            = modelView,
			compeseBtn           = compeseBtn,
			heroAvataePos        = heroAvataePos,
			dummyBtn             = dummyBtn,
			presetTeamView       = presetTeamView,
			presetTeamBtn        = presetTeamBtn,

			starTab              = starTab,
			qualityImg           = qualityImg,
			upgradeBtn           = upgradeBtn,
			tabNameLabel         = tabNameLabel,
			screenBtn            = screenBtn,
			screenLabel          = screenLabel,

			rightUpView          = rightUpView,
			heroScale            = heroScale,

			heroNum              = heroNum,
			tempStr              = tempStr,
			sortBtn              = sortBtn,
			sortLabel            = sortLabel,

			arrowImg             = arrowImg,
			findBtn              = findBtn,

			leftSwichBtn         = leftSwichBtn,
			rightSwichBtn        = rightSwichBtn,

			heroMessLayout       = heroMessLayout,
			voiceWordLayer       = voiceWordLayer,
			setMainLayoutHeroBtn = setMainLayoutHeroBtn,

		}
	end
	xTry(function ( )
		self.viewData = CreateView()
		display.commonUIParams(self.viewData.view, {po = display.center})
		self:addChild(self.viewData.view,1)

		local action = cc.EaseBounceOut:create(cc.MoveTo:create(1,cc.p(display.SAFE_L + 120, display.size.height + 2 )))
		self.viewData.tabNameLabel:runAction( action )

		if self.viewData.findBtn then
			self.viewData.findBtn:setOpacity(0)
			self.viewData.findBtn:runAction(
				cc.Sequence:create(
					cc.DelayTime:create(0.6),
					cc.FadeIn:create(0.3)
				)
			)
		end
		self.viewData.rightUpView:setPositionX(display.size.width + 800)
		self.viewData.rightUpView:runAction(cc.Sequence:create(
			cc.DelayTime:create(0.04),
			cc.EaseOut:create(cc.MoveTo:create(0.2, cc.p(display.SAFE_R,display.size.height - 5)), 0.7)
		))
		if CommonUtils.GetModuleAvailable(MODULE_SWITCH.ARTIFACT) then self:CreateArtifactIcon() end
	end, __G__TRACKBACK__)
end
function CardsListViewNew:CreateArtifactIcon()
	local size = cc.size(120 , 140)
	local artifactLayer = display.newLayer(10 , display.cy - 220 , { size = size , color = cc.c4b(0,0,0,0) ,enable = true })
	self.viewData.leftView:addChild(artifactLayer , 100)
	artifactLayer:setVisible(false)
	local coreBtn = display.newImageView(_res('ui/artifact/core_btn_3'), size.width/2 , size.height - 45 , {ap = display.CENTER})
	artifactLayer:addChild(coreBtn)

	local smallArtifactPath = CommonUtils.GetArtifiactPthByCardId("200001")
	local smallArtifact =  FilteredSpriteWithOne:create(smallArtifactPath)
	smallArtifact:setPosition(cc.p(size.width/2 , size.height - 40 ))
	artifactLayer:addChild(smallArtifact)
	smallArtifact:setScale(0.5)

	local coreBtnOne =  FilteredSpriteWithOne:create(_res('ui/artifact/core_btn_1'))
	artifactLayer:addChild(coreBtnOne)
	coreBtnOne:setPosition(cc.p(size.width/2 , size.height - 60 ))
	coreBtnOne:setAnchorPoint(display.CENTER)
	local lockOne = display.newImageView(_res('ui/common/common_ico_lock') ,size.width/2 , size.height - 50 )
	artifactLayer:addChild(lockOne)

	local card_bar_bg = display.newButton( size.width/2 , 50 , {n = _res('avatar/ui/card_bar_bg.png')})
	artifactLayer:addChild(card_bar_bg)
	display.commonLabelParams(card_bar_bg , fontWithColor('14' , {text = __('神器')}))

	local number = display.newImageView(_res('ui/artifact/core_ico_rumber_bg') , size.width/2 , 20 )
	artifactLayer:addChild(number)
	local numberSize = number:getContentSize()
	local numberLabel = display.newRichLabel(numberSize.width/2, numberSize.height/2 , { c = {
		fontWithColor('14', {text = '11'})
	}})
	number:addChild(numberLabel)
	local lockTwo = display.newImageView(_res('ui/common/common_ico_lock') ,0  , numberSize.height/2+3  ,{ap = display.CENTER})
	number:addChild(lockTwo)
	lockTwo:setScale(0.7)
	artifactLayer:runAction(
			cc.RepeatForever:create(cc.Sequence:create({
				cc.EaseSineIn:create(cc.MoveBy:create(2 , cc.p(0,15))),
				cc.EaseSineOut:create(cc.MoveBy:create(2 , cc.p(0,-15)))

			}))
	)
	self.artifactLayer = {
		artifactLayer = artifactLayer ,
		coreBtn = coreBtn ,
		coreBtnOne = coreBtnOne ,
		lockOne = lockOne ,
		number = number ,
		numberLabel = numberLabel ,
		smallArtifact = smallArtifact ,
		lockTwo = lockTwo ,
	}

end
function CardsListViewNew:CreateScreenBoradLayout()
	local screenBtn = self.viewData.screenBtn
	local rightUpView = self.viewData.rightUpView
	local screenBoardImg = display.newImageView(_res('ui/home/cardslistNew/tujian_selection_frame_1.png'), screenBtn:getPositionX(), screenBtn:getPositionY() - screenBtn:getContentSize().height * 0.5
	,{scale9 = true,size = cc.size(160, 56 *table.nums(screenType))})
	local screenBoard = display.newLayer(screenBtn:getPositionX() , screenBtn:getPositionY() - screenBtn:getContentSize().height * 0.5 - 30 ,
			{size = cc.size(screenBoardImg:getContentSize().width,screenBoardImg:getContentSize().height - 16), color1 = cc.r4b(),  ap = cc.p(1, 1)})
	rightUpView:addChild(screenBoard, 15)
	display.commonUIParams(screenBoardImg, {po = utils.getLocalCenter(screenBoard)})
	screenBoard:addChild(screenBoardImg)
	--screenBoard:setVisible(false)
	-- screenBoard:setBackgroundColor(cc.c4b(0, 128, 0, 100))
	-- 排序类型
	local topPadding = 2
	local bottomPadding = 0
	local listSize = cc.size(screenBoard:getContentSize().width, screenBoard:getContentSize().height - topPadding - bottomPadding )
	local cellSize = cc.size(listSize.width, listSize.height / (table.nums(screenType)) )
	local centerPos = nil
	local screenTab = {}
	for i,v in ipairs(screenType) do
		centerPos = cc.p(listSize.width * 0.5, listSize.height  - (i * cellSize.height) + cellSize.height *0.5 )
		local sortTypeBtn = display.newButton(0, 0, {size = cellSize, ap = cc.p(0.5, 0.5) , enable = true })
		display.commonUIParams(sortTypeBtn, {po = cc.p(centerPos)})
		screenBoard:addChild(sortTypeBtn)
		sortTypeBtn:setTag(v.tag)
		table.insert(screenTab,sortTypeBtn)


		local selectIcon = display.newImageView(_res('ui/home/cardslistNew/tujian_selection_select_btn_filter_selected.png'), utils.getLocalCenter(sortTypeBtn).x, utils.getLocalCenter(sortTypeBtn).y)
		--,{scale9 = true,size = cc.size(cellSize.width - 40,cellSize.height)})
		sortTypeBtn:addChild(selectIcon)
		selectIcon:setTag(99)
		selectIcon:setVisible(false)

		if v.tag ~= 0 then
			local descrLabel = display.newLabel(0, 0,
					fontWithColor(5,{text = v.typeDescr or CardUtils.GetCardCareerName(v.tag), ap = cc.p(0, 0.5),fontSize = 22}))

			local careerBg = display.newImageView(_res(v.bgPath or CardUtils.CAREER_ICON_FRAME_PATH_MAP[tostring(v.tag)]), centerPos.x - 25, centerPos.y)
			careerBg:setScale(0.8)
			-- local totalWidth = careerBg:getContentSize().width * careerBg:getScale() + display.getLabelContentSize(descrLabel).width
			display.commonUIParams(careerBg, {po = cc.p(
			-- centerPos.x - totalWidth * 0.5 + careerBg:getContentSize().width * 0.5 * careerBg:getScale(),
					centerPos.x - 40,
					centerPos.y)})
			screenBoard:addChild(careerBg)

			local careerIcon = display.newImageView(_res(v.iconPath or CardUtils.CAREER_ICON_PATH_MAP[tostring(v.tag)]), utils.getLocalCenter(careerBg).x, utils.getLocalCenter(careerBg).y + 2)
			careerIcon:setScale(0.65)
			careerBg:addChild(careerIcon)

			display.commonUIParams(descrLabel, {po = cc.p(careerBg:getPositionX() + careerBg:getContentSize().width * 0.5, careerBg:getPositionY())})
			screenBoard:addChild(descrLabel)


		else
			local descrLabel = display.newLabel(0, 0,
					fontWithColor(5,{text = v.typeDescr, ap = cc.p(0.5, 0.5)}))
			display.commonUIParams(descrLabel, {po = centerPos})
			screenBoard:addChild(descrLabel)
		end

		if i < table.nums(screenType) then
			local splitLine = display.newNSprite(_res('ui/common/tujian_selection_line.png'), centerPos.x, centerPos.y - cellSize.height * 0.5)
			screenBoard:addChild(splitLine)
		end
	end
	local data = {
		screenBoard = screenBoard,
		screenTab = screenTab,
	}
	table.merge(self.viewData,data)
end

function CardsListViewNew:CreateSortLayout()
	local sortBtn = self.viewData.sortBtn
	local rightUpView = self.viewData.rightUpView
	local sortBoardImg = display.newImageView(_res('ui/home/cardslistNew/tujian_selection_frame_1.png'), sortBtn:getPositionX(), sortBtn:getPositionY() - sortBtn:getContentSize().height * 0.5
	,{scale9 = true,size = cc.size(160,56*table.nums(screenType))})
	local sortBoard = display.newLayer(sortBtn:getPositionX() , sortBtn:getPositionY() - sortBtn:getContentSize().height * 0.5 - 30 ,
			{size = cc.size(sortBoardImg:getContentSize().width,sortBoardImg:getContentSize().height - 16), ap = cc.p(1, 1)})

	rightUpView:addChild(sortBoard, 15)
	display.commonUIParams(sortBoardImg, {po = utils.getLocalCenter(sortBoard)})
	sortBoard:addChild(sortBoardImg)
	--sortBoard:setVisible(false)


	-- 排序类型
	local topPadding = 2
	local bottomPadding = 0
	local listSize = cc.size(sortBoard:getContentSize().width, sortBoard:getContentSize().height - topPadding - bottomPadding)
	local cellSize = cc.size(listSize.width, listSize.height / (table.nums(sortType)))
	local centerPos = nil
	local sortTab = {}
	for i,v in ipairs(sortType) do
		centerPos = cc.p(listSize.width * 0.5, listSize.height  - (i * cellSize.height) + cellSize.height *0.5 )
		local sortTypeBtn = display.newCheckBox(0, 0, {size = cellSize, ap = cc.p(0.5, 0.5)})--newButton
		display.commonUIParams(sortTypeBtn, {po = cc.p(centerPos)})
		sortBoard:addChild(sortTypeBtn)
		sortTypeBtn:setTag(v.tag)
		table.insert(sortTab,sortTypeBtn)

		local descrLabel = display.newLabel(0, 0,
				fontWithColor(5,{text = v.typeDescr, ap = cc.p(0.5, 0.5),fontSize = 22}))
		display.commonUIParams(descrLabel, {po = centerPos})
		sortBoard:addChild(descrLabel)


		local selectIcon = display.newImageView(_res('ui/home/cardslistNew/tujian_selection_select_btn_filter_selected.png'), utils.getLocalCenter(sortTypeBtn).x, utils.getLocalCenter(sortTypeBtn).y ,
				{scale9 = true,size = cc.size(cellSize.width - 40,cellSize.height)})
		sortTypeBtn:addChild(selectIcon)
		selectIcon:setTag(99)
		selectIcon:setVisible(false)


		local arrowImg = display.newImageView(_res('ui/home/cardslistNew/tujian_selection_select_ico_filter_direction.png'))
		arrowImg:setAnchorPoint(cc.p(0.5,0.5))
		arrowImg:setTag(9)
		arrowImg:setPosition(cc.p(sortTypeBtn:getContentSize().width *0.5 - 60,sortTypeBtn:getContentSize().height *0.5))
		sortTypeBtn:addChild(arrowImg)
		arrowImg:setVisible(false)


		if i < table.nums(sortType) then
			local splitLine = display.newNSprite(_res('ui/common/tujian_selection_line.png'), centerPos.x, centerPos.y - cellSize.height * 0.5)
			sortBoard:addChild(splitLine)
		end
	end
	local data = {
		sortBoard = sortBoard,
		sortTab = sortTab,
	}
	table.merge(self.viewData ,data)
end

function CardsListViewNew:CreateEatAndContractLayout()
	local modelView     = self.viewData.modelView
	local leftView      = self.viewData.leftView
	local modelViewSize = modelView:getContentSize()
	local commonLayoutSize = cc.size(109,85)
	local listPos       =  nil
	local posY = nil
	if GAME_MODULE_OPEN.WOODEN_DUMMY and CommonUtils.UnLockModule(JUMP_MODULE_DATA.WOODEN_DUMMY) then
		listPos = {
			cc.p(modelViewSize.width*0.65, modelViewSize.height - 280) ,
			cc.p(modelViewSize.width*0.65, modelViewSize.height - 373) ,
		}
		posY = 185
	else
		listPos = {
			cc.p(modelViewSize.width*0.45, modelViewSize.height - 184),
			cc.p(modelViewSize.width*0.65, modelViewSize.height - 280)
		}
		posY = 100
	end

	--喂食
	local eatFoodBtnView = CLayout:create(cc.size(109,85))
	eatFoodBtnView:setAnchorPoint(cc.p(0.5,0))
	eatFoodBtnView:setPosition(listPos[1])
	modelView:addChild(eatFoodBtnView,10)

	-- eatFoodBtnView:setBackgroundColor((cc.c4b(0, 128, 0, 200)))
	eatFoodBtnView:setVisible(false)
	local eatFoodBg = display.newImageView(_res('ui/home/card/card_commonframe_icon.png'),commonLayoutSize.width*0.5,42,{ap = cc.p(0.5,0.5)})
	eatFoodBtnView:addChild(eatFoodBg)

	local tempImg = display.newImageView(_res('ui/home/card/card_bg_trestle_small.png'),commonLayoutSize.width*0.55,30,{ap = cc.p(0.5,0.5)})
	eatFoodBtnView:addChild(tempImg,-1)

	local eatFoodBtn = display.newButton(0, 0, {ap = display.CENTER,n = _res('ui/cards/love/card_attribute_btn_feed.png')})
	display.commonUIParams(eatFoodBtn, {ap = cc.p(0.5,0.5),po = cc.p(commonLayoutSize.width*0.48,44)})
	eatFoodBtnView:addChild(eatFoodBtn, 1)
	eatFoodBtn:setScale(0.7)

	--设置契约
	local contractBtnView = CLayout:create(cc.size(109,85))
	contractBtnView:setAnchorPoint(cc.p(0.5,0))
	contractBtnView:setPosition(listPos[2])
	modelView:addChild(contractBtnView,10)
	-- contractBtnView:setBackgroundColor((cc.c4b(0, 128, 0, 200)))
	contractBtnView:setVisible(false)
	local contractBg = display.newImageView(_res('ui/home/card/card_commonframe_icon.png'),commonLayoutSize.width*0.5,42,{ap = cc.p(0.5,0.5)})
	contractBtnView:addChild(contractBg)

	local tempImg = display.newImageView(_res('ui/home/card/card_bg_trestle_small.png'),commonLayoutSize.width*0.55,30,{ap = cc.p(0.5,0.5)})
	contractBtnView:addChild(tempImg,-1)

	local btnGlowImg = display.newImageView(_res('ui/cards/marry/card_contract_anime_unlock'),commonLayoutSize.width*0.5,commonLayoutSize.height*0.5,{ap = cc.p(0.5,0.5)})
	contractBtnView:addChild(btnGlowImg)
	btnGlowImg:runAction(cc.RepeatForever:create(cc.Sequence:create(
			cc.FadeTo:create(1, 50),
			cc.FadeIn:create(1)
	)))
	btnGlowImg:setVisible(false)

	local contractBtn = display.newButton(0, 0, {ap = display.CENTER,n = _res('ui/cards/love/card_btn_contract_1.png')})
	display.commonUIParams(contractBtn, {ap = cc.p(0.5,0.5),po = cc.p(commonLayoutSize.width*0.49,40)})
	contractBtnView:addChild(contractBtn, 1)
	contractBtn:getLabel():setVisible(false)

	local contractImg = display.newImageView(_res(_res('ui/cards/love/card_btn_contract_1.png')))
	display.commonUIParams(contractImg, {po = cc.p(contractBtn:getContentSize().width * 0.5, contractBtn:getContentSize().height*0.5 )})
	contractBtn:addChild(contractImg, 5)
	contractImg:setVisible(false)

	local loveMessLayout = CLayout:create(cc.size(366,64))
	-- loveMessLayout:setBackgroundColor((cc.c4b(0, 128, 0, 100)))
	loveMessLayout:setAnchorPoint(cc.p(1,1))
	loveMessLayout:setPosition(cc.p(modelView:getPositionX(),modelView:getPositionY() - posY))
	leftView:addChild(loveMessLayout,10)
	loveMessLayout:setVisible(false)

	local loveBarBg = display.newImageView(_res(_res('ui/cards/love/card_love_bg_loading.png')))
	display.commonUIParams(loveBarBg, {po = cc.p(loveMessLayout:getContentSize().width * 0.5, loveMessLayout:getContentSize().height*0.5 - 18)})
	loveMessLayout:addChild(loveBarBg, 5)

	local loveBar = cc.ProgressTimer:create(cc.Sprite:create(_res('ui/cards/love/card_love_ico_loading.png')))
	loveBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
	loveBar:setMidpoint(cc.p(0, 0))
	loveBar:setBarChangeRate(cc.p(1, 0))
	loveBar:setPosition(utils.getLocalCenter(loveBarBg).x ,utils.getLocalCenter(loveBarBg).y )
	loveBar:setAnchorPoint(cc.p(0.5,0.5))
	loveBar:setPercentage(60)
	loveBarBg:addChild(loveBar)
	-- own label
	local loveLabel = display.newLabel(loveBar:getContentSize().width * 0.5,loveBar:getContentSize().height * 0.5 + 4,
			fontWithColor(14,{text = '0/200', fontSize = 20,  ap = cc.p(0.5, 0.5)}))
	loveMessLayout:addChild(loveLabel,10)

	local tempLabel = display.newLabel(66,loveMessLayout:getContentSize().height * 0.5,
			{text = __('好感度'), fontSize = 22, color = '#ffffff', ap = cc.p(0.5, 1)})
	loveBarBg:addChild(tempLabel,10)
	local data = {
		btnGlowImg      = btnGlowImg,
		contractBtn     = contractBtn,
		contractImg     = contractImg,
		eatFoodBtnView  = eatFoodBtnView,
		contractBtnView = contractBtnView,
		loveMessLayout  = loveMessLayout,
		loveLabel       = loveLabel,
		loveBar         = loveBar,
		eatFoodBtn      = eatFoodBtn,
	}
	table.merge(self.viewData ,data )
end

return CardsListViewNew
