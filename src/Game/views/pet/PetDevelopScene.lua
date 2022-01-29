--[[
堕神养成场景
--]]
---xxxx
local GameScene = require( "Frame.GameScene" )
local PetDevelopScene = class("PetDevelopScene", GameScene)

------------ import ------------
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local petMgr = AppFacade.GetInstance():GetManager("PetManager")
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
------------ import ------------

------------ define ------------
local PetModuleType = {
	PURGE 			= 1,  -- 灵体净化
	DEVELOP 		= 2,  -- 堕神养成
	SMELTING 		= 3   -- 堕神熔炼
}

local PetModuleZOrder = {
	BG 				= 1,
	CENTER_MODULE 	= 30,
	TOP 			= 90
}

-- 堕神排序规则
local PetSortRule = {
	DEFAULT 		= 0, -- 默认规则
	QUALITY 		= 1, -- 品质
	LEVEL 			= 2, -- 等级
	BREAK_LEVEL 	= 3  -- 强化等级
}

local WateringConfig = {
	MAX_WATERING_VALUE = 50,
	BASE_WATERING_VALUE = 10
}

local RES_DICT = {
	POOL_N     = _res("ui/pet/pet_clean_bg_glass_add.png"),
	POOL_S     = _res("ui/pet/pet_clean_bg_glass.png"),
	POOL_D     = _res('ui/pet/pet_clean_bg_glass_disabled.png'),
	IMG_S_F    = _res('ui/pet/pet_clean_bg_glass_selected.png'),
	IMG_S_BG   = _res('ui/pet/pet_clean_bg_glass_get_2.png'),
	LOCKED_IMG = _res('ui/common/common_ico_lock.png'),
}
------------ define ------------

--[[
constructor
--]]
function PetDevelopScene:ctor(...)

	local args = unpack({...})

	GameScene.ctor(self, 'Game.views.pet.PetDevelopScene')

	self.selectedPetEggIndex = nil
	self.selectedPurgePodIndex = nil
	self.showAwakeWaring = true
	self.petEggDetailLayer = nil
	self.showPetEggDetail = false

	self.selectedPetIndex = nil

	self.wateringMaxValue = 50

	self:InitUI()
end
--[[
初始化ui
--]]
function PetDevelopScene:InitUI()

	local function CreateView()

		local size = display.size
		local selfCenter = cc.p(size.width * 0.5, size.height * 0.5)

		-- 背景底
		local bg = display.newImageView(_res('ui/common/common_bg_card_large_l.jpg'), selfCenter.x, selfCenter.y, {isFull = true})
		self:addChild(bg, PetModuleZOrder.BG)

		-- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height + 100,{n = _res('ui/common/common_title_new.png'),ap = cc.p(0, 0)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('虚盒') ,  fontSize = 30, color = '473227',offset = cc.p(0,-8)})
		self:addChild(tabNameLabel, PetModuleZOrder.TOP)
		local tabNameLabelSize = display.getLabelContentSize(tabNameLabel:getLabel())
		if tabNameLabelSize.width > 180 then
			display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('虚盒') ,  fontSize = 22 , w = 180 ,hAlign = display.TAC, color = '473227',offset = cc.p(0,0)})
		end

		-- tips
		local tipsBtn = display.newButton(tabNameLabel:getContentSize().width - 50, tabNameLabel:getContentSize().height/2 - 10, {n = _res('ui/common/common_btn_tips.png')})
		tabNameLabel:addChild(tipsBtn, 10)

		-- 右下页签
		local tabBg = display.newImageView(_res('ui/pet/card_bg_tabs.png'), 0, 0)
		local tabBgContentSize = tabBg:getContentSize()
		display.commonUIParams(tabBg, {po = cc.p(size.width - tabBgContentSize.width * 0.5, tabBgContentSize.height * 0.5)})
		self:addChild(tabBg, PetModuleZOrder.TOP)

		local moduleTabBtns = {}
		local checkBtnX = size.width - 145
		local tabDatas = {
			{name = __('灵体'), iconPathN = 'ui/pet/pet_btn_soul_default.png', iconPathS = 'ui/pet/pet_btn_soul_selected.png', tag = PetModuleType.PURGE},
			{name = __('堕神'), iconPathN = 'ui/pet/pet_btn_moster_default.png', iconPathS = 'ui/pet/pet_btn_moster_selected.png', tag = PetModuleType.DEVELOP},
		}
		for i,v in ipairs(tabDatas) do
			-- 按钮
			local checkBtn = display.newCheckBox(0, 0, {n = _res(v.iconPathN), s = _res(v.iconPathS)})
			display.commonUIParams(checkBtn, {po = cc.p(checkBtnX, tabBg:getPositionY() + 15)})
			self:addChild(checkBtn, PetModuleZOrder.TOP + 1)
			checkBtn:setName('moduleTabBtn'..i)
			checkBtn:setTag(v.tag)
			moduleTabBtns[v.tag] = checkBtn

			-- 名称标签
			local nameBg = display.newNSprite(_res('ui/cards/propertyNew/card_bar_bg.png'), checkBtn:getPositionX(), checkBtn:getPositionY() - 45)
			self:addChild(nameBg, checkBtn:getLocalZOrder() + 1)
			local nameLabel = display.newLabel(utils.getLocalCenter(nameBg).x, utils.getLocalCenter(nameBg).y - 2, fontWithColor('14', {text = v.name}))
			nameBg:addChild(nameLabel)

			-- 修正x坐标
			checkBtnX = checkBtnX - checkBtn:getContentSize().width + 10
		end

		return {
			tabNameLabel = tabNameLabel,
			moduleTabBtns = moduleTabBtns,
			petPurgeLayer = nil
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

	-- 弹出标题班
	local action = cc.EaseBounceOut:create(cc.MoveTo:create(1,cc.p(display.SAFE_L + 130, display.height - 80)))
	self.viewData.tabNameLabel:runAction(action)

	self.viewData.tabNameLabel:setOnClickScriptHandler(function( sender )
	    PlayAudioByClickClose()
	    uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.PET)]})
	end)
end
--[[
/***********************************************************************************************************************************\
 * pet purge layer
\***********************************************************************************************************************************/
--]]
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化净化模块
--]]
function PetDevelopScene:InitPetPurgeLayer()
	local size = display.size
	local baseZOrder = PetModuleZOrder.CENTER_MODULE
	local topSize = AppFacade.GetInstance():RetrieveMediator('AppMediator'):GetTopLayerSize()
	local selectBgHeight = size.height - topSize.height + 22
	local selectBgWidth = 465

	if display.isFullScreen then
		local bgImgWidth = 875
		selectBgWidth = display.width - (display.SAFE_L + bgImgWidth)
	end

	------------ 初始化灵体选择页 ------------
	-- 背景
	local selectBgSize = cc.size(selectBgWidth, selectBgHeight)

	local selectPetEggBgLayer = display.newLayer(size.width - selectBgSize.width * 0.5 - 10, selectBgHeight * 0.5,
			{size = selectBgSize, ap = cc.p(0.5, 0.5)})
	selectPetEggBgLayer:setName('selectPetEggBgLayer')
	self:addChild(selectPetEggBgLayer, baseZOrder + 1)

	local selectPetEggsBg = display.newImageView(_res('ui/common/common_bg_4.png'),
			selectBgSize.width * 0.5,
			selectBgSize.height * 0.5,
			{scale9 = true, size = selectBgSize})
	selectPetEggBgLayer:addChild(selectPetEggsBg)

	local titleBg = display.newImageView(_res('ui/common/common_title_5.png'), 0, 0,{scale9 = true})
	display.commonUIParams(titleBg, {po = cc.p(selectBgSize.width * 0.5, selectBgSize.height - titleBg:getContentSize().height * 0.5 - 15)})
	selectPetEggBgLayer:addChild(titleBg, 5)

	local titleLabel = display.newLabel(0,0, fontWithColor('5', {  text = __('灵体仓库')}))
	titleBg:addChild(titleLabel)
	local titleBgSize = titleBg:getContentSize()
	local titleLabelSize = display.getLabelContentSize(titleLabel)
	titleBg:setContentSize(cc.size(titleLabelSize.width + 60 , titleBgSize.height))
	titleLabel:setPosition(cc.p((titleLabelSize.width + 60 )/2 ,titleBgSize.height/2 ))

	-- 排序按钮
	local sortBtn = display.newButton(0, 0, {
		n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'),
		cb = handler(self, self.PetPurgeSortClickCallback)
	})
	display.commonUIParams(sortBtn, {po = cc.p(selectBgSize.width - sortBtn:getContentSize().width * 0.5 - 10, titleBg:getPositionY())})
	display.commonLabelParams(sortBtn, fontWithColor('18', {text = __('排序')}))
	selectPetEggBgLayer:addChild(sortBtn, 5)
	sortBtn:setVisible(false)

	local sortBoard = require('common.CommonSortBoard').new({
		targetNode = sortBtn,
		sortRules = {
			{sortType = PetSortRule.QUALITY, sortDescr = __('品质'), callbackSignal = 'PET_PURGE_SORT', defaultSort = SortOrder.DESC}
		}
	})
	display.commonUIParams(sortBoard, {ap = cc.p(0.5, 1), po = (
			self:convertToNodeSpace(sortBtn:getParent():convertToWorldSpace(cc.p(sortBtn:getPositionX(), sortBtn:getPositionY() - sortBtn:getContentSize().height * 0.5)))
	)})
	self:addChild(sortBoard, 999)
	sortBoard:setVisible(false)

	-- 列表底
	local gridViewBgSize = cc.size(selectBgSize.width - 20, selectBgSize.height - 68)

	local gridViewBg = display.newImageView(_res('ui/common/common_bg_goods.png'),
			selectBgSize.width * 0.5,
			gridViewBgSize.height * 0.5 + 10,
			{scale9 = true, size = gridViewBgSize})
	selectPetEggBgLayer:addChild(gridViewBg, 1)

	-- 灵体列表
	local gridViewSize = cc.size(gridViewBgSize.width - 10, gridViewBgSize.height - 2)
	local gridPerLine = 4
	if display.isFullScreen then
		gridPerLine = 5
	end
	local cellSize = cc.size(gridViewSize.width / gridPerLine, gridViewSize.width / gridPerLine)
	local gridView = CGridView:create(gridViewSize)
	gridView:setName('gridView')
	gridView:setAnchorPoint(cc.p(0.5, 0.5))
	gridView:setPosition(cc.p(gridViewBg:getPositionX(), gridViewBg:getPositionY()))
	selectPetEggBgLayer:addChild(gridView, 2)
	-- gridView:setBackgroundColor(cc.c4b(255, 128, 0, 128))

	gridView:setCountOfCell(0)
	gridView:setColumns(gridPerLine)
	gridView:setSizeOfCell(cellSize)
	gridView:setAutoRelocate(false)
	gridView:setDataSourceAdapterScriptHandler(handler(self, self.PetPurgeGridViewDataAdapter))

	-- 全空状态
	local emptyGodScale = 0.75
	local petEggEmptyGod = AssetsUtils.GetCartoonNode(3, selectBgSize.width * 0.5, selectBgSize.height * 0.6)
	petEggEmptyGod:setScale(emptyGodScale)
	selectPetEggsBg:addChild(petEggEmptyGod)

	local petEggEmptyLabel = display.newLabel(
		petEggEmptyGod:getPositionX(),
		petEggEmptyGod:getPositionY() - 424 * 0.5 * emptyGodScale - 40,
		fontWithColor('14', {text = __('你还没有灵体')}))
	selectPetEggsBg:addChild(petEggEmptyLabel)
	------------ 初始化灵体选择页 ------------

	------------ 初始化中间内容 ------------
	local purgeFrameLayer = display.newLayer(size.width * 0.5, size.height * 0.5, {size = size, ap = cc.p(0.5, 0.5)})
	purgeFrameLayer:setName('purgeFrameLayer')
	self:addChild(purgeFrameLayer, baseZOrder)

	-- 中间背景
	local designHeight = 1002
	-- local centerPurgePoolBg = display.newImageView(_res('ui/pet/pet_clean_pic_bg.png'), 0, 0)
	-- display.commonUIParams(centerPurgePoolBg,
	-- 	{po = cc.p(centerPurgePoolBg:getContentSize().width * 0.5, centerPurgePoolBg:getContentSize().height * 0.5 + (size.height - designHeight) * 0.5)})
	-- purgeFrameLayer:addChild(centerPurgePoolBg)

	local designHeight = 1002
	local centerPurgePoolPos = cc.p(display.SAFE_L, (size.height - designHeight) * 0.5)
	local centerPurgePoolBg = sp.SkeletonAnimation:create(
			'effects/pet/purgePool.json',
			'effects/pet/purgePool.atlas',
			1
	)
	centerPurgePoolBg:setPosition(centerPurgePoolPos)
	purgeFrameLayer:addChild(centerPurgePoolBg)
	centerPurgePoolBg:update(0)
	centerPurgePoolBg:setAnimation(0, 'idle', true)

	local centerPurgePoolBgBBox = centerPurgePoolBg:getBoundingBox()

	-- 中间层中间坐标坐标
	local poolCenter = cc.p(
			centerPurgePoolPos.x + centerPurgePoolBgBBox.width * 0.5 + 10,
			centerPurgePoolPos.y + centerPurgePoolBgBBox.height * 0.5 + 145
	)
	local poolFixedPos = {
		poolCenter = poolCenter, -- 净化池中间坐标
		poolSize = cc.size(550, 270), -- 净化池尺寸
		purgeBtnPosY = poolCenter.y - 250, -- 净化按钮y坐标
		purgePodPosY = size.height * 0.805, -- 净化池y坐标
		purgePodSize = cc.size(120, 120), -- 器皿大小
		purgePodCenterFixedP = cc.p(-2, 2), -- 器皿中心修正坐标
		purgePodBottomFixedP = cc.p(-2, -40), -- 器皿底部修正坐标
		wateringBtnPos = cc.p(poolCenter.x - 355, poolCenter.y + 160), -- 浇水按钮坐标
		wateringLabelPos = cc.p(poolCenter.x - 355, poolCenter.y + 120), -- 浇水次数坐标
		wateringFreeBgPos = cc.p(poolCenter.x - 1, poolCenter.y + 116), -- 免费浇水坐标
		wateringBarPos = cc.p(poolCenter.x, poolCenter.y + 160), -- 浇水进度条坐标
		petEggNameLabelPos = cc.p(poolCenter.x + 150, poolCenter.y - 195), -- 灵体名字标签坐标
		purgeTimeCounterPos = cc.p(316, 35) -- 中间倒计时坐标
	}

	-- debug --
	-- local testLayer = display.newLayer(poolFixedPos.poolCenter.x, poolFixedPos.poolCenter.y,
	-- 	{size = poolFixedPos.poolSize, ap = cc.p(0.5, 0.5)})
	-- testLayer:setBackgroundColor(cc.c4b(128, 200, 66, 120))
	-- self:addChild(testLayer, baseZOrder - 1)
	-- debug --


	local bottomBg = display.newImageView(_res('ui/pet/pet_clean_bg_console.png'),0, 0)


	local purgeBottomLayerSize = bottomBg:getContentSize()
	local purgeBottomLayer = display.newLayer(poolFixedPos.poolCenter.x, -purgeBottomLayerSize.height,
	{size = purgeBottomLayerSize, ap = cc.p(0.5, 0) })
	purgeFrameLayer:addChild(purgeBottomLayer, 1)
	bottomBg:setPosition(cc.p(purgeBottomLayerSize.width*0.5,purgeBottomLayerSize.height*0.5))
	purgeBottomLayer:addChild(bottomBg)



	local purgeTable =  {name = __('去熔炼'), iconPathN = 'ui/pet/smelting/melting_btn_ronglian.png', iconPathS = 'ui/pet/smelting/melting_btn_ronglian.png', tag = PetModuleType.SMELTING}
	local goSmeltingBtn = display.newCheckBox(110 , 278 -  (display.width/display.height >  1.7  and  130 or 0 ) , { n = _res(purgeTable.iconPathN ) , s = _res(purgeTable.iconPathS)  ,enable = true    } )
	self:addChild(goSmeltingBtn,50)
	goSmeltingBtn:setTag(purgeTable.tag)
	display.commonUIParams(goSmeltingBtn,{cb = handler(self, self.GoToSmeltingClick)})
	if not  CommonUtils.CheckModuleIsExitByModuleId(JUMP_MODULE_DATA.SMELTING_PET) then
		goSmeltingBtn:setVisible(false)
	end
	local goSmeltingBtnSize = goSmeltingBtn:getContentSize()
	local goLabel = display.newLabel(goSmeltingBtnSize.width/2 ,  goSmeltingBtnSize.height/2 ,fontWithColor('14', { text = purgeTable.name}))
	goSmeltingBtn:addChild(goLabel)
	--goSmeltingBtn:setName('moduleTabBtn'..PetModuleType.SMELTING)
	--local moduleTabBtns = self.viewData.moduleTabBtns
	--moduleTabBtns[purgeTable.tag] = goSmeltingBtn

	-- purgeBottomLayer:setBackgroundColor(cc.c4b(128, 200, 66, 120))
	purgeBottomLayer:setName('purgeBottomLayer')
	-- 空状态
	local centerPurgePoolEmptyLabel = display.newLabel(poolFixedPos.poolCenter.x, poolFixedPos.poolCenter.y,
			fontWithColor('14', {text = __('请从右侧仓库中选择一个灵体进行净化'), w = 450 ,  hAlign = display.TAC}))
	purgeFrameLayer:addChild(centerPurgePoolEmptyLabel, 1)
	centerPurgePoolEmptyLabel:setVisible(false)

	-- 底部按钮
	local purgeBg = display.newImageView(_res('ui/pet/pet_clean_bg_button.png'),0, 0)
	purgeBg:setPosition(cc.p(249,55))
	purgeBottomLayer:addChild(purgeBg, 1)

	-- 净化
	local purgeBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png'), cb = handler(self, self.PetEggPurgeClickCallback)})
	display.commonUIParams(purgeBtn, {po = cc.p(249,53)})
	display.commonLabelParams(purgeBtn, fontWithColor('14', {text = __('净化')}))
	-- purgeFrameLayer:addChild(purgeBtn, 2)
	purgeBottomLayer:addChild(purgeBtn, 2)
	purgeBtn:setName('purgeBtn')
	purgeBtn:setVisible(false)


	-- 净化时间
	local purgeTimeLabel = display.newLabel(0, 0,
			{text = '88:88:88', fontSize = 20, color = 'ffffff', font = TTF_GAME_FONT, ttf = true, outline = '734441'})
	display.commonUIParams(purgeTimeLabel, {po = cc.p(purgeBtn:getPositionX(), purgeBtn:getPositionY() - purgeBtn:getContentSize().height * 0.5 - 5)})
	-- purgeFrameLayer:addChild(purgeTimeLabel, 2)
	purgeBottomLayer:addChild(purgeTimeLabel, 2)
	purgeTimeLabel:setVisible(false)

	local awakeBg = display.newImageView(_res('ui/pet/pet_clean_bg_button.png'),0, 0)
	awakeBg:setPosition(cc.p(514,55))
	purgeBottomLayer:addChild(awakeBg, 1)

	-- 直接唤醒
	local awakeBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_white_default.png'), cb = handler(self, self.PetEggAwakeClickCallback)})
	display.commonUIParams(awakeBtn, {po = cc.p(514, 53)})
	display.commonLabelParams(awakeBtn, fontWithColor('14', {text = __('直接唤醒')}))
	-- purgeFrameLayer:addChild(awakeBtn, 2)
	purgeBottomLayer:addChild(awakeBtn, 2)
	awakeBtn:setVisible(false)


	-- 直接唤醒概率
	local awakeLabel = display.newLabel(0, 0,
			{text = '成功率：0%', fontSize = 20, color = 'ffffff', font = TTF_GAME_FONT, ttf = true, outline = '734441'})
	display.commonUIParams(awakeLabel, {po = cc.p(awakeBtn:getPositionX(), awakeBtn:getPositionY() - awakeBtn:getContentSize().height * 0.5 - 5)})
	-- purgeFrameLayer:addChild(awakeLabel, 2)
	purgeBottomLayer:addChild(awakeLabel, 2)
	awakeLabel:setVisible(false)


	local wateringBtnBg = display.newImageView(_res('ui/pet/pet_clean_bg_cleanbtn.png'), 0, 0)
	display.commonUIParams(wateringBtnBg, {po = poolFixedPos.wateringBtnPos})
	purgeFrameLayer:addChild(wateringBtnBg,2)

	-- 浇水按钮
	local wateringBtn = display.newButton(0, 0, {n = _res('ui/pet/pet_clean_btn_clean.png'), cb = handler(self, self.WateringClickCallback)})
	display.commonUIParams(wateringBtn, {po = poolFixedPos.wateringBtnPos})
	display.commonLabelParams(wateringBtn, fontWithColor('14', {text = __('浇灌')}))
	purgeFrameLayer:addChild(wateringBtn, 3)

	local wateringFreeBg = display.newButton(0, 0, {n = _res('ui/pet/pet_clean_bg_freetext.png')})
	display.commonUIParams(wateringFreeBg, {po = poolFixedPos.wateringFreeBgPos})
	display.commonLabelParams(wateringFreeBg, fontWithColor('14', {offset= cc.p(-36,0),ap = cc.p(1,0.5),text = string.fmt(__('今日剩余免费次数__num次'), {__num = 1})}))
	purgeFrameLayer:addChild(wateringFreeBg,4)
	local wateringFreeLabel = wateringFreeBg:getLabel()
	wateringFreeBg:setVisible(false)
	local wateringLabel = display.newButton(0, 0, {n = _res('ui/pet/pet_clean_label_num.png')})
	display.commonUIParams(wateringLabel, {po = poolFixedPos.wateringLabelPos})
	display.commonLabelParams(wateringLabel, fontWithColor('14', {text = ('3/3')}))
	purgeFrameLayer:addChild(wateringLabel,4)
	wateringLabel:setVisible(false)
	local wateringCostLabel = wateringLabel:getLabel()


	local wateringCostItemIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(PET_DEVELOP_WATERING_ID)),
			0, 0)
	wateringCostItemIcon:setScale(0.3)
	wateringCostItemIcon:setAnchorPoint(cc.p(0.5,0))
	wateringBtn:addChild(wateringCostItemIcon)
	wateringCostItemIcon:setTag(7)


	-- 浇水进度条
	local wateringMaxValue = self.wateringMaxValue

	local wateringBar = CProgressBar:create(_res('ui/pet/pet_love_bg_loading.png'))
	wateringBar:setBackgroundImage(_res('ui/pet/pet_love_bg.png'))
	wateringBar:setDirection(eProgressBarDirectionLeftToRight)
	wateringBar:setPosition(poolFixedPos.wateringBarPos)
	wateringBar:setMaxValue(wateringMaxValue)
	wateringBar:setValue(30)
	purgeFrameLayer:addChild(wateringBar, 1)

	-- 进度条刻度
	local wateringBarSize = wateringBar:getContentSize()
	local wateringMarkAmount = 5
	for i = 1, wateringMarkAmount - 1 do
		local wateringMark = display.newNSprite(_res('ui/pet/pet_love_ico_line.png'),
				wateringBarSize.width * (i / wateringMarkAmount),
				wateringBarSize.height * 0.5)
		wateringBar:addChild(wateringMark, 99)
	end

	-- 魔法菜谱
	local magicFoodUnlockConfig = CommonUtils.GetConfigAllMess('petMagicFoodUnlock', 'pet')
	local magicFoodBtn = {}

	local t_ = nil
	for i = 1, table.nums(magicFoodUnlockConfig) do
		t_ = magicFoodUnlockConfig[tostring(i)]
		local magicFoodButton = display.newButton(
				wateringBar:getPositionX() - wateringBarSize.width * 0.5 + wateringBarSize.width * (t_.nutritionNum / wateringMaxValue),
				wateringBar:getPositionY(),
				{cb = handler(self, self.MagicFoodClickCallback)})

		local magicFoodBg = display.newNSprite(_res('ui/pet/pet_love_bg_lock.png'), 0, 0)
		local magicFoodBtnSize = magicFoodBg:getContentSize()
		magicFoodButton:setContentSize(magicFoodBtnSize)
		display.commonUIParams(magicFoodBg, {po = utils.getLocalCenter(magicFoodButton)})
		magicFoodButton:addChild(magicFoodBg, 5)
		magicFoodBg:setTag(3)

		purgeFrameLayer:addChild(magicFoodButton, 3)
		magicFoodButton:setTag(i)
		magicFoodBtn[i] = magicFoodButton

		-- 魔菜道具图标
		local magicFoodIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)), 0, 0)
		display.commonUIParams(magicFoodIcon, {po = utils.getLocalCenter(magicFoodButton)})
		magicFoodIcon:setScale(0.25)
		magicFoodButton:addChild(magicFoodIcon, 10)
		magicFoodIcon:setTag(5)
	end

	-- 名字
	local petEggNameLabel = display.newLabel(
			poolFixedPos.petEggNameLabelPos.x -100,
			poolFixedPos.petEggNameLabelPos.y,
			fontWithColor('14', {text = '', ap = cc.p(0.5, 0.5),}))
	purgeFrameLayer:addChild(petEggNameLabel, 3)


	local centerPurgeTimeCounterBg = display.newButton(0, 0, {n = _res('ui/pet/pet_clean_bg_text.png')})-- pet_clean_bg_clean_time
	display.commonUIParams(centerPurgeTimeCounterBg, {ap = cc.p(0.5,0.5),po = cc.p(260,55)})
	display.commonLabelParams(centerPurgeTimeCounterBg, fontWithColor('6', {fontSize = 20,text = __('剩余时间'),offset = cc.p(-30,12)}))
	-- purgeFrameLayer:addChild(centerPurgeTimeCounterBg, 6)
	purgeBottomLayer:addChild(centerPurgeTimeCounterBg)

	-- 中间净化倒计时
	local centerPurgeTimeCounter = display.newLabel(14, 2,
			fontWithColor('14', {text = '00:00:00',ap = cc.p(0,0),fontSize = 28}))
	centerPurgeTimeCounterBg:addChild(centerPurgeTimeCounter)


	-- 加速按钮

	local accelerateBg = display.newImageView(_res('ui/pet/pet_clean_bg_button.png'),0, 0)
	accelerateBg:setPosition(cc.p(390,55))
	purgeBottomLayer:addChild(accelerateBg, 1)

	local accelerateBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_green.png'), cb = handler(self, self.AcceleratePurgeClickCallback)})
	accelerateBtn:setName('accelerateBtn')
	display.commonUIParams(accelerateBtn, {ap = cc.p(0.5,0.5),po = cc.p(390,53)})
	-- purgeFrameLayer:addChild(accelerateBtn, 6)
	purgeBottomLayer:addChild(accelerateBtn, 6)

	local accelerateBtnSize = accelerateBtn:getContentSize()

	-- 加速消耗
	local accelerateIcon = display.newNSprite(_res('ui/home/lobby/cooking/refresh_ico_quick_recovery.png'), 0, 0)
	display.commonUIParams(accelerateIcon, {po = cc.p(
			8 + accelerateIcon:getContentSize().width * 0.5,
			accelerateBtnSize.height * 0.5)})
	accelerateBtn:addChild(accelerateIcon)

	local accelerateCostLabel = display.newLabel(0, 0,
			{text = 888, fontSize = 20, color = 'ffffff', font = TTF_GAME_FONT, ttf = true, outline = '734441', ap = cc.p(1, 0.5), hAlign = display.TAR})
	accelerateBtn:addChild(accelerateCostLabel)
	accelerateCostLabel:setTag(3)

	local costIconScale = 0.15
	local accelerateCostIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)), 0, 0)
	accelerateCostIcon:setScale(costIconScale)
	display.commonUIParams(accelerateCostIcon, {po = cc.p(
			accelerateBtnSize.width - 5 - accelerateCostIcon:getContentSize().width * 0.5 * costIconScale,
			accelerateBtnSize.height * 0.5
	)})
	accelerateBtn:addChild(accelerateCostIcon)
	accelerateCostIcon:setTag(5)

	display.commonUIParams(accelerateCostLabel, {po = cc.p(
			accelerateCostIcon:getPositionX() - accelerateCostIcon:getContentSize().width * 0.5 * costIconScale,
			accelerateCostIcon:getPositionY()
	)})

	-- 领取按钮
	local drawPetBg = display.newImageView(_res('ui/pet/pet_clean_bg_button.png'),0, 0)
	drawPetBg:setPosition(cc.p(purgeBottomLayer:getContentSize().width*0.5, purgeBottomLayer:getContentSize().height*0.5))
	purgeBottomLayer:addChild(drawPetBg, 1)

	local drawPetBtn = display.newButton(purgeBottomLayer:getContentSize().width*0.5, purgeBottomLayer:getContentSize().height*0.5,
			{n = _res('ui/common/common_btn_orange.png'), cb = handler(self, self.DrawPetClickCallback),ap = cc.p(0.5,0.5)})
	drawPetBtn:setName('drawPetBtn')
	display.commonLabelParams(drawPetBtn, fontWithColor('14', {text = __('领取')}))
	-- purgeFrameLayer:addChild(drawPetBtn, 6)
	purgeBottomLayer:addChild(drawPetBtn, 6)

	-- 中间avatar隐形按钮
	local avatarBtn = display.newButton(poolFixedPos.poolCenter.x, poolFixedPos.poolCenter.y,
			{size = cc.size(poolFixedPos.poolSize.width * 0.75, poolFixedPos.poolSize.height * 0.75), ap = cc.p(0.5, 0.5), cb = handler(self, self.PetAvatarClickCallback)})
	purgeFrameLayer:addChild(avatarBtn)
	avatarBtn:setVisible(false)
	------------ 初始化中间内容 ------------

	------------ 初始化净化池 ------------
	-- 净化池背景
	local purgePodBg = display.newImageView(_res('ui/pet/pet_clean_bg_box.png'), poolFixedPos.poolCenter.x - 12, poolFixedPos.purgePodPosY - 50)
	purgeFrameLayer:addChild(purgePodBg)

	-- 净化池
	local poolTableViewP  = cc.p(poolFixedPos.poolCenter.x - 32, poolFixedPos.purgePodPosY)
	local poolTableView   = ui.tableView({size = cc.size(620, 120), dir = display.SDIR_H, csizeW = 115, p = poolTableViewP})
	poolTableView:setCellCreateHandler(PetDevelopScene.CreatePoolCellNode)
	purgeFrameLayer:add(poolTableView, 3)

	local poolConfig = CommonUtils.GetConfigAllMess('petPond', 'pet')
	local poolNum    = table.nums(poolConfig)
	local btnPosX    = poolNum > 5 and -90 or -100

	local drawAllBtnLayoutSize = cc.size(160 , 70)
	local drawAllBtnLayout = display.newLayer(poolFixedPos.poolCenter.x + 3 * poolFixedPos.purgePodSize.width + btnPosX,
											  poolFixedPos.purgePodPosY -25 ,{size = drawAllBtnLayoutSize , color = cc.c4b(0,0,0,0) , enable = true  })
	purgeFrameLayer:addChild(drawAllBtnLayout, 2)
	display.commonUIParams(drawAllBtnLayout ,{ cb = handler(self, self.PurgePodAllClickCallback)} )
	local drawAllPetBg = display.newImageView(_res('ui/pet/pet_clean_bg_button.png'),drawAllBtnLayoutSize.width/2, drawAllBtnLayoutSize.height/2)
	drawAllBtnLayout:addChild(drawAllPetBg, 1)

	local drawAllBtn = display.newButton(drawAllBtnLayoutSize.width/2 , drawAllBtnLayoutSize.height/2, { n =  _res('ui/common/common_btn_orange.png')})
	drawAllBtnLayout:addChild(drawAllBtn, 1)
	display.commonLabelParams(drawAllBtn , fontWithColor(14,{text = __('全部领取') ,reqW = 115 }))

	------------ 初始化净化池 ------------

	self.viewData.petPurgeLayer = {
		------------ view nodes ------------
		purgeFrameLayer = purgeFrameLayer,
		purgeBottomLayer = purgeBottomLayer,
		purgeBottomLayerSize = purgeBottomLayerSize,
		gridView = gridView,
		centerPurgePoolBg = centerPurgePoolBg,
		waterSpineAnimation = nil,
		laserSpineAnimation = nil,
		steamSpineAnimation = nil,
		petEggSpineAvatar = nil,
		purgeTimeLabel = purgeTimeLabel,
		awakeLabel = awakeLabel,
		wateringBar = wateringBar,
		magicFoodBtn = magicFoodBtn,
		wateringCostLabel = wateringCostLabel,
		wateringFreeLabel = wateringFreeLabel,
		wateringCostItemIcon = wateringCostItemIcon,
		petEggNameLabel = petEggNameLabel,
		centerPurgeTimeCounter = centerPurgeTimeCounter,
		accelerateBtn = accelerateBtn,
		accelerateBg = accelerateBg,
		drawPetBtn = drawPetBtn,
		drawPetBg = drawPetBg,
		sortBoard = sortBoard,
		drawAllBtnLayout = drawAllBtnLayout ,
		drawAllBtn = drawAllBtn ,
		drawAllPetBg = drawAllPetBg ,
		awakeFailSpine = nil,
		------------ view data ------------
		gridViewSize = gridViewSize,
		cellSize = cellSize,
		poolFixedPos = poolFixedPos,
		poolTableView = poolTableView,
		------------ layer handler ------------
		ShowNoPetEgg = function (no)
			-- 显示没有灵体的状态
			-- sortBtn:setVisible(not no)
			gridViewBg:setVisible(not no)
			gridView:setVisible(not no)
			petEggEmptyGod:setVisible(no)
			petEggEmptyLabel:setVisible(no)

			wateringBtn:setVisible(false)
			wateringBtnBg:setVisible(false)
			wateringBar:setVisible(false)
			for i,v in ipairs(magicFoodBtn) do
				v:setVisible(false)
			end
			petEggNameLabel:setVisible(not no)
			centerPurgeTimeCounter:getParent():setVisible(false)
			accelerateBtn:setVisible(false)
			accelerateBg:setVisible(false)
			drawPetBtn:setVisible(false)
			drawPetBg:setVisible(false)
		end,
		ShowNoPetEggInPool = function (no)
			-- 显示没有灵体被选中的状态
			centerPurgePoolEmptyLabel:setVisible(no)

			if no == false then
				local sqeAction = cc.Sequence:create(
						cc.MoveTo:create(0.15,cc.p(poolFixedPos.poolCenter.x,-purgeBottomLayerSize.height)),
						cc.Spawn:create(
								cc.MoveTo:create(0.15,cc.p(poolFixedPos.poolCenter.x,0)),
								cc.CallFunc:create(function ()
									purgeBtn:setVisible(not no)
									awakeBtn:setVisible(not no)
									purgeTimeLabel:setVisible(not no)
									awakeLabel:setVisible(not no)
									avatarBtn:setVisible(not no)
									purgeBg:setVisible(not no)
									awakeBg:setVisible(not no)
								end)
						)
				)
				purgeBottomLayer:runAction(sqeAction)
			else
				local sqeAction = cc.Sequence:create(
						cc.Spawn:create(
								cc.MoveTo:create(0.1,cc.p(poolFixedPos.poolCenter.x,-purgeBottomLayerSize.height)),
								cc.CallFunc:create(function ()
									purgeBtn:setVisible(not no)
									awakeBtn:setVisible(not no)
									purgeTimeLabel:setVisible(not no)
									awakeLabel:setVisible(not no)
									avatarBtn:setVisible(not no)
									purgeBg:setVisible(not no)
									awakeBg:setVisible(not no)
								end)
						)
				)
				purgeBottomLayer:runAction(sqeAction)
			end
			if self.viewData.petPurgeLayer.petEggSpineAvatar then
				self.viewData.petPurgeLayer.petEggSpineAvatar:setVisible(not no)
			end

			for _, podNode in pairs(self.viewData.petPurgeLayer.poolTableView:getCellViewDataDict()) do
				podNode:updateSelectedImgVisible(false)
			end

			wateringBtn:setVisible(false)
			wateringBtnBg:setVisible(false)
			wateringBar:setVisible(false)
			for i,v in ipairs(magicFoodBtn) do
				v:setVisible(false)
			end
			petEggNameLabel:setVisible(not no)
			centerPurgeTimeCounter:getParent():setVisible(false)
			accelerateBtn:setVisible(false)
			accelerateBg:setVisible(false)
			drawPetBtn:setVisible(false)
			drawPetBg:setVisible(false)
		end,
		ShowPoolNoSelectedPetEggInPod = function (no)
			-- 点击培养皿显示中间ui
			centerPurgePoolEmptyLabel:setVisible(no)
			avatarBtn:setVisible(not no)
			wateringBtn:setVisible(not no)
			wateringBtnBg:setVisible(not no)
			wateringBar:setVisible(not no)
			for i,v in ipairs(magicFoodBtn) do
				v:setVisible(not no)
			end
			petEggNameLabel:setVisible(not no)
			centerPurgeTimeCounter:getParent():setVisible(not no)
			accelerateBtn:setVisible(not no)
			accelerateBg:setVisible(not no)
			drawPetBtn:setVisible(false)
			drawPetBg:setVisible(false)
		end,
		ShowSelf = function (show)
			-- 选择页
			selectPetEggBgLayer:setVisible(show)
			-- 中间页
			purgeFrameLayer:setVisible(show)
			if CommonUtils.CheckModuleIsExitByModuleId(JUMP_MODULE_DATA.SMELTING_PET) then
				goSmeltingBtn:setVisible(show)
			end
			if not CommonUtils.GetModuleAvailable(MODULE_SWITCH.PET_EVOL) then
				goSmeltingBtn:setVisible(false)
			end
		end
	}

end
--[[
初始化培养皿状态
@params data table 所有培养皿数据
--]]
function PetDevelopScene:InitPurgePods(data)
	local poolConfig = CommonUtils.GetConfigAllMess('petPond', 'pet')
	self.viewData.petPurgeLayer.poolTableView:setCellInitHandler(function(podNode)
		ui.bindClick(podNode, handler(self, self.PurgePodClickCallback))
	end)
	self.viewData.petPurgeLayer.poolTableView:resetCellCount(table.nums(poolConfig), true)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
根据模块类型刷新界面
@params moduleType PetModuleType 模块类型
@params data table {
	------------ 灵体净化 ------------
	petEggs = {},
	selectedPetEggIndex int 选择的灵体序号
	------------ 堕神养成 ------------
	pets = {},
	selectedPetIndex int 选择的堕神序号
}
@params doAction bool 是否做动画
--]]
function PetDevelopScene:RefreshSceneByModuleType(moduleType, data, doAction)
	if PetModuleType.PURGE == moduleType then

		-- 灵体净化
		self.viewData.petPurgeLayer.ShowSelf(true)
		self:RefreshPetEggs(data.petEggs)
		self:RefreshPetPurgeCenterByIndex(data.selectedPetEggIndex)

		-- 隐藏另一个模块
		if self.viewData.petDevelopLayer then
			self.viewData.petDevelopLayer.ShowSelf(false)
		end
		local mediator = AppFacade.GetInstance():RetrieveMediator("PetSmeltingMediator")
		if  mediator then
			AppFacade.GetInstance():UnRegsitMediator("PetSmeltingMediator")
		end
	elseif PetModuleType.DEVELOP == moduleType then

		-- 堕神养成
		self.viewData.petDevelopLayer.ShowSelf(true)
		self:RefreshPets(data.pets)
		self:RefreshPetDevelopDetailByIndex(0 < #self.pets and data.selectedPetIndex or nil)

		-- 隐藏另一个模块
		if self.viewData.petPurgeLayer then
			self.viewData.petPurgeLayer.ShowSelf(false)
		end
		local mediator = AppFacade.GetInstance():RetrieveMediator("PetSmeltingMediator")
		if  mediator then
			AppFacade.GetInstance():UnRegsitMediator("PetSmeltingMediator")
		end
	end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- pet purge control begin --
---------------------------------------------------
--[[
灵体选择view handler
--]]
function PetDevelopScene:PetPurgeGridViewDataAdapter(c, i)
	local cell = c
	local index = i + 1
	local goodsIcon = nil
	local borderIcon = nil
	local petEggData = {}
	if #self.petEggs >= index then
		petEggData = self.petEggs[index]
	end

	if nil == cell then
		cell = CGridViewCell:new()
		cell:setContentSize(self.viewData.petPurgeLayer.cellSize)
		-- cell:setBackgroundColor(cc.c4b(math.random(255), math.random(255), 100, 100))

		-- goods icon
		goodsIcon = require('common.GoodNode').new({
			goodsId = petEggData.goodsId,
			amount = petEggData.amount,
			showAmount = true,
			callBack = handler(self, self.PetEggClickCallback)
		})
		goodsIcon:setScale((self.viewData.petPurgeLayer.cellSize.width - 10) / goodsIcon:getContentSize().width)
		goodsIcon:setAnchorPoint(cc.p(0.5, 0.5))
		goodsIcon:setPosition(utils.getLocalCenter(cell))
		goodsIcon:setTag(3)
		cell:addChild(goodsIcon)

		-- border
		borderIcon = display.newNSprite(_res('ui/common/common_bg_frame_goods_elected.png'),
				utils.getLocalCenter(cell).x, utils.getLocalCenter(cell).y)
		borderIcon:setScale((self.viewData.petPurgeLayer.cellSize.width) / borderIcon:getContentSize().width)
		cell:addChild(borderIcon, 5)
		borderIcon:setTag(5)
	end

	------------ 处理最下的空cell ------------
	if index > #self.petEggs then

		cell:setVisible(false)

	else

		cell:setVisible(true)
		goodsIcon = cell:getChildByTag(3)
		goodsIcon:RefreshSelf({
			goodsId = petEggData.goodsId,
			amount = petEggData.amount
		})

		borderIcon = cell:getChildByTag(5)
		borderIcon:setVisible(self.selectedPetEggIndex and self.selectedPetEggIndex == index)

	end
	------------ 处理最下的空cell ------------

	cell:setTag(index)
	return cell
end
--[[
刷新堕神净化选择页面
@params petEggs table {
	{goodsId = xxx, amount = xxx},
	{goodsId = xxx, amount = xxx},
	...
}
@params onlyGridView bool 是否只是刷新列表
--]]
function PetDevelopScene:RefreshPetEggs(petEggs, onlyGridView)
	self.petEggs = petEggs

	------------ 为最下添加一行空cell ------------
	local petEggAmount = #self.petEggs
    if petEggAmount > 0 then
        local addedRow = 2
        local cellPerLine = self.viewData.petPurgeLayer.gridView:getColumns()
        local addedCell = math.ceil(petEggAmount / cellPerLine) * cellPerLine - petEggAmount + (addedRow - 1) * cellPerLine + 1

        self.viewData.petPurgeLayer.gridView:setCountOfCell(petEggAmount + addedCell)
    else
        self.viewData.petPurgeLayer.gridView:setCountOfCell(0)
    end
	local container = self.viewData.petPurgeLayer.gridView:getContainer()
	if container and table.nums(container:getChildren())  > 0 then
		local gridContentOffset = self.viewData.petPurgeLayer.gridView:getContentOffset()
		self.viewData.petPurgeLayer.gridView:reloadData()
		local contentSize = container:getContentSize()
		local height =  self.viewData.petPurgeLayer.gridView:getContentSize().height
		if (contentSize.height - height)  < math.abs(gridContentOffset.y) then
			gridContentOffset.y = - (contentSize.height - height)
		end
		self.viewData.petPurgeLayer.gridView:setContentOffset(gridContentOffset)

	else
		self.viewData.petPurgeLayer.gridView:reloadData()
	end

	------------ 为最下添加一行空cell ------------

	if not onlyGridView then
		self.viewData.petPurgeLayer.ShowNoPetEgg(0 == #self.petEggs)
	end
end
--[[
根据点击序号刷新净化ui
@params index int 列表中的index
--]]
function PetDevelopScene:RefreshPetPurgeCenterByIndex(index)
	-- if index == 1 then index = nil end
	-- 空状态
	self.viewData.petPurgeLayer.ShowNoPetEggInPool(nil == index)

	-- 净化池无内容 中间做动画
	self:DoPurgePoolAnimation('idle', true)

	-- 置空培养皿选择
	self.selectedPurgePodIndex = nil

	if index == self.selectedPetEggIndex then return end

	if nil ~= index then
		-- 当前节点显示选中
		local curCell = self.viewData.petPurgeLayer.gridView:cellAtIndex(index - 1)
		if nil ~= curCell then
			curCell:getChildByTag(5):setVisible(true)
		end
	end

	if nil ~= self.selectedPetEggIndex then
		-- 之前节点取消选中
		local preCell = self.viewData.petPurgeLayer.gridView:cellAtIndex(self.selectedPetEggIndex - 1)
		if nil ~= preCell then
			preCell:getChildByTag(5):setVisible(false)
		end

		self:SetShowAwakeWaring(true)
	end

	self.selectedPetEggIndex = index

	local petEggId = nil
	if nil ~= self.selectedPetEggIndex then
		local petEggData = self.petEggs[self.selectedPetEggIndex]
		petEggId = checkint(petEggData.goodsId)
		-- 刷新中间灵体信息
		self:RefreshPetPurgePoolBySelectPetEgg(petEggId)
	end

	-- 刷新详情界面
	self:ShowPetEggDetailLayer(petEggId, nil ~= self.selectedPetEggIndex)
end
--[[
刷新中间净化池状态 选中灵体
@params goodsId int 灵体的goods id
--]]
function PetDevelopScene:RefreshPetPurgePoolBySelectPetEgg(goodsId)
	local petEggId = goodsId
	local petEggConfig = CommonUtils.GetConfig('pet', 'petEgg', petEggId)

	if nil ~= self.viewData.petPurgeLayer.petEggSpineAvatar then
		self.viewData.petPurgeLayer.petEggSpineAvatar:removeFromParent()
	end

	-- 创建新的spine动画
	local petEggAvatar = nil
	local petEggSpinePath = petMgr.GetPetEggSpinePathByPetEggId(petEggId)
	local pos = cc.p(
			self.viewData.petPurgeLayer.poolFixedPos.poolCenter.x,
			self.viewData.petPurgeLayer.poolFixedPos.poolCenter.y - self.viewData.petPurgeLayer.poolFixedPos.poolSize.height * 0.25)

	-- 创建中间spine avatar
	petEggAvatar = sp.SkeletonAnimation:create(
			string.format('%s.json', petEggSpinePath),
			string.format('%s.atlas', petEggSpinePath),
			1)
	petEggAvatar:setPosition(pos)
	self.viewData.petPurgeLayer.purgeFrameLayer:addChild(petEggAvatar, self.viewData.petPurgeLayer.centerPurgePoolBg:getLocalZOrder() - 5)

	petEggAvatar:setAnimation(0, 'idle', true)

	self.viewData.petPurgeLayer.petEggSpineAvatar = petEggAvatar

	-- 刷新净化时间
	self.viewData.petPurgeLayer.purgeTimeLabel:setString(
			CommonUtils.GetFormattedTimeBySecond(petMgr.GetPetEggCleanTimeById(petEggId), ':'))

	-- 直接唤醒概率
	local rate = petMgr.GetPetEggAwakeSuccessRateById(petEggId)
	self.viewData.petPurgeLayer.awakeLabel:setString(string.fmt(__('成功率：_num_%'),{ _num_ = rate * 100} ))

	-- 刷新灵体名字
	self.viewData.petPurgeLayer.petEggNameLabel:setString(petEggConfig.name)
end
--[[
根据id刷新上方培养皿状态
@params purgePodId int 培养皿id
@params podData table 培养皿数据
--]]
function PetDevelopScene:RefreshPurgePodById(purgePodId, podData)
	local podNode = self:GetPurgePodNodeByPurgePodId(purgePodId)
	if podNode then
		self:RefreshPurgePod(podNode, podData)
	end
end
--[[
刷新上方培养皿状态
@params podNode cc.Node 培养明节点
@params podData table 培养皿数据
--]]
function PetDevelopScene:RefreshPurgePod(podNode, podData)
	if not podNode then return end

	local isUnlocked = podData ~= nil
	podNode:updateUnLockedStatue(isUnlocked)
	-- podNode:updateIconChecked(false)
	podNode:updateSelectedImgVisible(false)
	podNode:updateFinishStatue(false)

	local eggData = checktable(podData)
	local hasEgg  = checkint(eggData.petEggId) > 0 
	if not hasEgg then
		podNode:setPoolEmpty(true)
	else
		podNode:updatePetIcon(eggData.petEggId)
		self:RefreshPurgePodByCounter(podNode, checkint(podData.cdTime))
	end
end
--[[
根据倒计时刷新培养皿状态
@params podNode cc.Node 培养皿节点
@params leftTime int 剩余秒数
--]]
function PetDevelopScene:RefreshPurgePodByCounter(podNode, leftTime)
	if not podNode then return end

	local leftTimeStr = leftTime <= 0 and __('净化完成') or CommonUtils.GetFormattedTimeBySecond(leftTime, ':')
	podNode:updateLeftTime(leftTimeStr)
	podNode:updateIconChecked(leftTime <= 0)
	podNode:updateFinishStatue(leftTime <= 0)
end
--[[
解锁一个培养皿
@params purgePodId int 培养皿id
--]]
function PetDevelopScene:UnlockAPurgePod(purgePodId)
	local podNode = self:GetPurgePodNodeByPurgePodId(purgePodId)
	if not podNode then return end

	podNode:updateUnLockedStatue(true)
end
--[[
根据选中的培养皿index以及培养皿信息 免费浇灌次数 刷新ui
@params index int 培养皿序号
@params purgePodData table 培养皿数据 {
	cdTime int
	nutrition string
	petEggId int
	pondId int
}
@params freeWateringTime int 免费浇灌次数
--]]
function PetDevelopScene:RefreshCenterPurgePoolByIndex(index, purgePodData, freeWateringTime)
	if index == self.selectedPurgePodIndex then return end

	-- 消除当前灵体选择状态
	self:RefreshPetPurgeCenterByIndex(nil)
	self.viewData.petPurgeLayer.ShowPoolNoSelectedPetEggInPod(nil == purgePodData or nil == purgePodData.petEggId)
	if nil == index then
		-- 隐藏详情
		self:ShowPetEggDetailLayer(nil, false)
	end

	if index then
		local curPurgePod = self:GetPurgePodNodeByPurgePodId(index)
		if curPurgePod then
			curPurgePod:updateSelectedImgVisible(true)
		end
	end

	if self.selectedPurgePodIndex then
		local prePurgePod = self:GetPurgePodNodeByPurgePodId(self.selectedPurgePodIndex)
		if prePurgePod then
			prePurgePod:updateSelectedImgVisible(false)
		end
	end

	self.selectedPurgePodIndex = index

	if nil ~= purgePodData and nil ~= freeWateringTime then
		self:RefreshPurgePool(purgePodData, freeWateringTime)
	end

end
--[[
根据培养皿信息刷新中间净化池
@params purgePodData table 培养皿数据 {
	cdTime int
	nutrition string
	petEggId int
	pondId int
	magicFoods string 魔菜信息
}
@params freeWateringTime int 免费浇灌次数
--]]
function PetDevelopScene:RefreshPurgePool(purgePodData, freeWateringTime)
	local petEggConfig = CommonUtils.GetConfig('pet', 'petEgg', checkint(purgePodData.petEggId))

	-- 刷新中间spine
	if nil ~= self.viewData.petPurgeLayer.petEggSpineAvatar then
		self.viewData.petPurgeLayer.petEggSpineAvatar:removeFromParent()
	end

	-- 隐藏详情
	self:ShowPetEggDetailLayer(checkint(purgePodData.petEggId), false)

	-- 创建新的spine动画
	local petEggAvatar = nil
	local spineId = checkint(petEggConfig.drawId)
	if not utils.isExistent(_res(string.format('pet/spine/%d.json', spineId))) then
		spineId = 240012
	end

	local petEggSpinePath = petMgr.GetPetEggSpinePathByPetEggId(checkint(purgePodData.petEggId))
	local pos = cc.p(
			self.viewData.petPurgeLayer.poolFixedPos.poolCenter.x,
			self.viewData.petPurgeLayer.poolFixedPos.poolCenter.y - self.viewData.petPurgeLayer.poolFixedPos.poolSize.height * 0.25)

	-- 创建中间spine avatar
	petEggAvatar = sp.SkeletonAnimation:create(
			string.format('%s.json', petEggSpinePath),
			string.format('%s.atlas', petEggSpinePath),
			1)
	petEggAvatar:setPosition(pos)
	self.viewData.petPurgeLayer.purgeFrameLayer:addChild(petEggAvatar, self.viewData.petPurgeLayer.centerPurgePoolBg:getLocalZOrder() - 5)

	local idleAnimationName = 'idle'
	if 0 >= checkint(purgePodData.cdTime) then
		idleAnimationName = 'idle2'
	end
	petEggAvatar:setAnimation(0, idleAnimationName, true)

	self.viewData.petPurgeLayer.petEggSpineAvatar = petEggAvatar

	-- 刷新灵体名字
	self.viewData.petPurgeLayer.petEggNameLabel:setString(petEggConfig.name)

	-- 刷新浇灌次数 新鲜度
	self:RefreshWateringBar(checkint(purgePodData.nutrition), freeWateringTime)

	-- 刷新魔法菜品插槽
	self:RefreshMagicFoodSlot(checkint(purgePodData.nutrition), purgePodData.magicFoods)


	if 0 >= checkint(purgePodData.cdTime) then
		local fixedPos = self.viewData.petPurgeLayer.poolFixedPos
		local sqeAction = cc.Sequence:create(
			cc.MoveTo:create(0.15,cc.p(fixedPos.poolCenter.x,-self.viewData.petPurgeLayer.purgeBottomLayerSize.height)),
			cc.Spawn:create(
				cc.MoveTo:create(0.15,cc.p(fixedPos.poolCenter.x,0)),
				cc.CallFunc:create(function ()
					self.viewData.petPurgeLayer.accelerateBtn:setVisible(false)
					self.viewData.petPurgeLayer.accelerateBg:setVisible(false)
					self.viewData.petPurgeLayer.drawPetBtn:setVisible(true)
					self.viewData.petPurgeLayer.drawPetBg:setVisible(true)
					self.viewData.petPurgeLayer.centerPurgeTimeCounter:getParent():setVisible(false)
					-- 改变堕神动作
					if nil ~= self.viewData.petPurgeLayer.petEggSpineAvatar and self.viewData.petPurgeLayer.petEggSpineAvatar:isVisible() then
						self.viewData.petPurgeLayer.petEggSpineAvatar:setToSetupPose()
						self.viewData.petPurgeLayer.petEggSpineAvatar:setAnimation(0, 'idle2', true)
					end
 		  		end)
				)
		)
		self.viewData.petPurgeLayer.purgeBottomLayer:runAction(sqeAction)

	else
		local fixedPos = self.viewData.petPurgeLayer.poolFixedPos
		local sqeAction = cc.Sequence:create(
				cc.MoveTo:create(0.15,cc.p(fixedPos.poolCenter.x,-self.viewData.petPurgeLayer.purgeBottomLayerSize.height)),
				cc.Spawn:create(
						cc.MoveTo:create(0.15,cc.p(fixedPos.poolCenter.x,0)),
						cc.CallFunc:create(function ()
							self.viewData.petPurgeLayer.accelerateBtn:setVisible(true)
							self.viewData.petPurgeLayer.accelerateBg:setVisible(true)
							self.viewData.petPurgeLayer.drawPetBtn:setVisible(false)
							self.viewData.petPurgeLayer.drawPetBg:setVisible(false)
						end)
				)
		)
		self.viewData.petPurgeLayer.purgeBottomLayer:runAction(sqeAction)
	end


	-- 刷新倒计时
	self:RefreshCenterPurgePoolCounter(checkint(purgePodData.cdTime))

	-- 净化池有内容 中间做动画
	self:DoPurgePoolAnimation('idle2', true)
end
--[[
刷新中间倒计时
@params second int 剩余秒数
--]]
function PetDevelopScene:RefreshCenterPurgePoolCounter(second)
	self.viewData.petPurgeLayer.centerPurgeTimeCounter:setString(CommonUtils.GetFormattedTimeBySecond(second))

	if 0 >= second then
		-- 净化完成 显示领取按钮
		self.viewData.petPurgeLayer.accelerateBtn:setVisible(false)
		self.viewData.petPurgeLayer.accelerateBg:setVisible(false)
		self.viewData.petPurgeLayer.drawPetBtn:setVisible(true)
		self.viewData.petPurgeLayer.drawPetBg:setVisible(true)
		self.viewData.petPurgeLayer.centerPurgeTimeCounter:getParent():setVisible(false)
		-- 改变堕神动作
		if nil ~= self.viewData.petPurgeLayer.petEggSpineAvatar and self.viewData.petPurgeLayer.petEggSpineAvatar:isVisible() then
			self.viewData.petPurgeLayer.petEggSpineAvatar:setToSetupPose()
			self.viewData.petPurgeLayer.petEggSpineAvatar:setAnimation(0, 'idle2', true)
		end

	else
		-- 净化未完成 显示加速按钮
		self.viewData.petPurgeLayer.accelerateBtn:setVisible(true)
		self.viewData.petPurgeLayer.accelerateBg:setVisible(true)
		self.viewData.petPurgeLayer.drawPetBtn:setVisible(false)
		self.viewData.petPurgeLayer.drawPetBg:setVisible(false)

		-- 刷新净化消耗幻晶石
		-- 1分钟 = 1幻晶石
		local costGoodsId, costGoodsAmount = self:GetAccelerateCost(second)
		self.viewData.petPurgeLayer.accelerateBtn:getChildByTag(3):setString(costGoodsAmount)
		self.viewData.petPurgeLayer.accelerateBtn:getChildByTag(5):setTexture(_res(CommonUtils.GetGoodsIconPathById(costGoodsId)))

	end
end
--[[
刷新浇灌次数 新鲜度
@params wateringValue int 浇灌新鲜度
@params freeWateringTime int 免费浇灌次数
--]]
function PetDevelopScene:RefreshWateringBar(wateringValue, freeWateringTime)
	-- 刷新进度条
	self.viewData.petPurgeLayer.wateringBar:setValue(math.min(self.wateringMaxValue, wateringValue))

	if 0 < freeWateringTime then
		-- 刷新文字
		local maxFreeWateringTime = 3

		self.viewData.petPurgeLayer.wateringFreeLabel:setString(string.fmt(__('今日剩余免费次数__num次'), {__num = freeWateringTime}))
		self.viewData.petPurgeLayer.wateringFreeLabel:getParent():setVisible(true)
		self.viewData.petPurgeLayer.wateringCostLabel:getParent():setVisible(false)
		self.viewData.petPurgeLayer.wateringCostItemIcon:setVisible(false)
	else
		-- 刷新浇灌消耗
		self.viewData.petPurgeLayer.wateringFreeLabel:getParent():setVisible(false)

		self.viewData.petPurgeLayer.wateringCostLabel:getParent():setVisible(true)
		self.viewData.petPurgeLayer.wateringCostLabel:setString(string.format('%d/1', gameMgr:GetAmountByGoodId(PET_DEVELOP_WATERING_ID)))
		self.viewData.petPurgeLayer.wateringCostItemIcon:setVisible(true)
	end
end
--[[
刷新魔法菜品插槽
@params wateringValue int 浇水值
@params magicFoodData string 魔菜信息
--]]
function PetDevelopScene:RefreshMagicFoodSlot(wateringValue, magicFoodData)
	local equipedMagicFood = {}
	if nil ~= magicFoodData and string.len(string.gsub(magicFoodData, " ", "")) > 0 then
		local str = string.split(magicFoodData, ',')
		for i,v in ipairs(str) do
			equipedMagicFood[i] = checkint(v)
		end
	end

	local magicFoodUnlockConfig = CommonUtils.GetConfigAllMess('petMagicFoodUnlock', 'pet')
	for i = 1, table.nums(magicFoodUnlockConfig) do
		self:RefreshAMagicFoodSlot(i, wateringValue, equipedMagicFood[i])
	end
end
--[[
刷新单个魔菜插槽
@params index int 序号
@params wateringValue int 浇水值
@params magicFoodId int 魔菜id
--]]
function PetDevelopScene:RefreshAMagicFoodSlot(index, wateringValue, magicFoodId)
	local magicFoodNode = self.viewData.petPurgeLayer.magicFoodBtn[index]
	local magicFoodUnlockConfig = CommonUtils.GetConfig('pet', 'petMagicFoodUnlock', index)
	-- 判断是否解锁
	if wateringValue >= checkint(magicFoodUnlockConfig.nutritionNum) then

		-- 解锁了该节点
		if nil ~= magicFoodId and 0 ~= magicFoodId then

			-- 有装备魔菜
			magicFoodNode:getChildByTag(3):setTexture(_res('ui/pet/pet_love_bg_active.png'))

			magicFoodNode:getChildByTag(5):setVisible(true)
			magicFoodNode:getChildByTag(5):setTexture(_res(CommonUtils.GetGoodsIconPathById(magicFoodId)))

		else

			-- 未装备魔菜
			magicFoodNode:getChildByTag(3):setTexture(_res('ui/pet/pet_love_bg_add.png'))

			magicFoodNode:getChildByTag(5):setVisible(false)

		end

	else
		-- 未解锁
		magicFoodNode:getChildByTag(3):setTexture(_res('ui/pet/pet_love_bg_lock.png'))

		magicFoodNode:getChildByTag(5):setVisible(false)
	end
end
--[[
解锁魔法菜品插槽
@params index int 魔法菜品插槽序号
--]]
function PetDevelopScene:UnlockAMagicFoodSlot(index)
	uiMgr:ShowInformationTips(string.format(__('成功解锁%d号魔法菜品槽位'), index))

	self.viewData.petPurgeLayer.magicFoodBtn[index]:getChildByTag(3):setTexture(_res('ui/pet/pet_love_bg_add.png'))
end
--[[
显示堕神蛋对应的可能出现的堕神
@params petEggId int 堕神蛋id
@params show bool 是否显示
--]]
function PetDevelopScene:ShowPetEggDetailLayer(petEggId, show)
	if show then
		if nil == petEggId then return end
		if nil ~= self.petEggDetailLayer then
			self.petEggDetailLayer:removeFromParent()
			self.petEggDetailLayer = nil
		end

		local petEggDetailLayer = require('Game.views.pet.PetEggDetailLayer').new({
			petEggId = petEggId
		})
		local fixedPos = self.viewData.petPurgeLayer.poolFixedPos
		local position = cc.p(
				self.viewData.petPurgeLayer.poolFixedPos.poolCenter.x,
				math.min(
						fixedPos.poolCenter.y + fixedPos.poolSize.height * 0.6,
						fixedPos.purgePodPosY - fixedPos.purgePodSize.height * 0.5 - petEggDetailLayer:getContentSize().height * 0.5)
		)
		petEggDetailLayer:setPosition(position)
		petEggDetailLayer:setAnchorPoint(cc.p(0.5, 0.5))
		self.viewData.petPurgeLayer.purgeFrameLayer:addChild(petEggDetailLayer, 100)

		self.petEggDetailLayer = petEggDetailLayer
	else
		if nil ~= self.petEggDetailLayer then
			self.petEggDetailLayer:removeFromParent()
			self.petEggDetailLayer = nil
		end
	end
	self.showPetEggDetail = show
end
--[[
播加速动画
--]]
function PetDevelopScene:DoAccelerate()
	------------ 净化池动画 ------------
	PlayAudioClip(AUDIOS.UI.ui_evolution_speedup.id)
	self:DoPurgePoolAnimation('play', false, 0)
	------------ 净化池动画 ------------

	------------ 小人动画 ------------
	if nil ~= self.viewData.petPurgeLayer.petEggSpineAvatar then
		self.viewData.petPurgeLayer.petEggSpineAvatar:setToSetupPose()
		self.viewData.petPurgeLayer.petEggSpineAvatar:setAnimation(0, 'play', false)
		self.viewData.petPurgeLayer.petEggSpineAvatar:addAnimation(0, 'idle2', true)
	end
	------------ 小人动画 ------------

	------------ 烟动画 ------------
	local waterSpineAnimation = self.viewData.petPurgeLayer.waterSpineAnimation

	if nil == waterSpineAnimation then
		waterSpineAnimation = sp.SkeletonAnimation:create(
				'effects/pet/qwpy_shui.json',
				'effects/pet/qwpy_shui.atlas',
				1
		)
		waterSpineAnimation:setPosition(cc.p(0, 0))
		self.viewData.petPurgeLayer.centerPurgePoolBg:addChild(waterSpineAnimation, 99)

		self.viewData.petPurgeLayer.waterSpineAnimation = waterSpineAnimation
	end

	waterSpineAnimation:setToSetupPose()
	waterSpineAnimation:setAnimation(0, 'idle', false)
	------------ 烟动画 ------------

	------------ 激光动画 ------------
	local laserSpineAnimation = self.viewData.petPurgeLayer.laserSpineAnimation
	if nil == laserSpineAnimation then
		laserSpineAnimation = sp.SkeletonAnimation:create(
				'effects/pet/qwpy_guang.json',
				'effects/pet/qwpy_guang.atlas',
				1
		)
		laserSpineAnimation:setPosition(cc.p(0, 0))
		self.viewData.petPurgeLayer.centerPurgePoolBg:addChild(laserSpineAnimation, 99)

		self.viewData.petPurgeLayer.laserSpineAnimation = laserSpineAnimation
	end

	laserSpineAnimation:setToSetupPose()
	laserSpineAnimation:setAnimation(0, 'idle', false)
	------------ 激光动画 ------------

	------------ 蒸汽 ------------
	local steamSpineAnimation = self.viewData.petPurgeLayer.steamSpineAnimation
	if nil == steamSpineAnimation then
		steamSpineAnimation = sp.SkeletonAnimation:create(
				'effects/pet/qwpy_yan.json',
				'effects/pet/qwpy_yan.atlas',
				1
		)
		steamSpineAnimation:setPosition(cc.p(0, 0))
		self.viewData.petPurgeLayer.centerPurgePoolBg:addChild(steamSpineAnimation, 99)

		self.viewData.petPurgeLayer.steamSpineAnimation = steamSpineAnimation
	end

	steamSpineAnimation:setToSetupPose()
	steamSpineAnimation:setAnimation(0, 'idle', false)
	------------ 蒸汽 ------------

end
--[[
中间净化池做动画
@params animationName string 动画名字
@params loop bool 是否循环
@params cdTime int 剩余秒数
--]]
function PetDevelopScene:DoPurgePoolAnimation(animationName, loop, cdTime)
	self.viewData.petPurgeLayer.centerPurgePoolBg:setToSetupPose()
	self.viewData.petPurgeLayer.centerPurgePoolBg:setAnimation(0, animationName, loop)

	if not loop and cdTime then
		-- 为做完该动画后添加一个继续的idle状态
		local animationDuration = self.viewData.petPurgeLayer.centerPurgePoolBg:getAnimationsData()[animationName].duration
		if math.ceil(animationDuration) >= cdTime then
			-- 动画时间大于结束时间 接idle2
			self.viewData.petPurgeLayer.centerPurgePoolBg:addAnimation(0, 'idle2', true)
		else
			-- 动画时间小于结束时间 接idle2
			self.viewData.petPurgeLayer.centerPurgePoolBg:addAnimation(0, 'idle2', true)
		end
	end
end
--[[
播浇水动画
@params isCritical bool 是否暴击
--]]
function PetDevelopScene:DoPurgeWatering(isCritical)
	------------ 堕神动画 ------------
	local petEggAniamtionName = 'weishi'
	local soundEffectId = AUDIOS.UI.ui_irrigate_bubble.id
	if isCritical then
		petEggAniamtionName = 'weishi2'
		soundEffectId = AUDIOS.UI.ui_irrigate_splash.id
	end

	if nil ~= self.viewData.petPurgeLayer.petEggSpineAvatar then
		self.viewData.petPurgeLayer.petEggSpineAvatar:setToSetupPose()
		self.viewData.petPurgeLayer.petEggSpineAvatar:setAnimation(0, petEggAniamtionName, false)
		self.viewData.petPurgeLayer.petEggSpineAvatar:addAnimation(0, 'idle', true)
	end
	------------ 堕神动画 ------------

	------------ 净化池动画 ------------
	local waterSpineAnimation = self.viewData.petPurgeLayer.waterSpineAnimation

	if nil == waterSpineAnimation then
		waterSpineAnimation = sp.SkeletonAnimation:create(
				'effects/pet/qwpy_shui.json',
				'effects/pet/qwpy_shui.atlas',
				1
		)
		waterSpineAnimation:setPosition(cc.p(0, 0))
		self.viewData.petPurgeLayer.centerPurgePoolBg:addChild(waterSpineAnimation, 99)

		self.viewData.petPurgeLayer.waterSpineAnimation = waterSpineAnimation
	end

	waterSpineAnimation:setToSetupPose()
	waterSpineAnimation:setAnimation(0, 'idle', false)

	PlayAudioClip(soundEffectId)
	------------ 净化池动画 ------------
end
--[[
显示排序板
@params show bool 是否显示排序版
--]]
function PetDevelopScene:ShowPetPurgeSortBoard(show)
	self.viewData.petPurgeLayer.sortBoard:setVisible(show)
end
--[[
直接唤醒失败动画
--]]
function PetDevelopScene:DoAwakeFail()
	local awakeFailSpine = self.viewData.petPurgeLayer.awakeFailSpine
	if nil == awakeFailSpine then
		local pos = cc.p(
				self.viewData.petPurgeLayer.poolFixedPos.poolCenter.x,
				self.viewData.petPurgeLayer.poolFixedPos.poolCenter.y - self.viewData.petPurgeLayer.poolFixedPos.poolSize.height * 0
		)

		awakeFailSpine = sp.SkeletonAnimation:create(
				'effects/pet/pet_awake_fail.json',
				'effects/pet/pet_awake_fail.atlas',
				1
		)
		awakeFailSpine:setPosition(pos)
		self.viewData.petPurgeLayer.purgeFrameLayer:addChild(awakeFailSpine, self.viewData.petPurgeLayer.centerPurgePoolBg:getLocalZOrder())

		self.viewData.petPurgeLayer.awakeFailSpine = awakeFailSpine
	end

	awakeFailSpine:setToSetupPose()
	awakeFailSpine:setAnimation(0, 'play1', false)
end
--[[
批量唤醒失败动画
--]]
function PetDevelopScene:DoBatchAwakeFail()
	local awakeFailSpine = self.viewData.petPurgeLayer.awakeFailSpine
	if nil == awakeFailSpine then
		local pos = cc.p(
				self.viewData.petPurgeLayer.poolFixedPos.poolCenter.x,
				self.viewData.petPurgeLayer.poolFixedPos.poolCenter.y - self.viewData.petPurgeLayer.poolFixedPos.poolSize.height * 0
		)

		awakeFailSpine = sp.SkeletonAnimation:create(
				'effects/pet/pet_awake_fail.json',
				'effects/pet/pet_awake_fail.atlas',
				1
		)
		awakeFailSpine:setPosition(pos)
		self.viewData.petPurgeLayer.purgeFrameLayer:addChild(awakeFailSpine, self.viewData.petPurgeLayer.centerPurgePoolBg:getLocalZOrder())

		self.viewData.petPurgeLayer.awakeFailSpine = awakeFailSpine
	end

	awakeFailSpine:setToSetupPose()
	awakeFailSpine:setAnimation(0, 'play2', false)
end
---------------------------------------------------
-- pet purge control end --
---------------------------------------------------

---------------------------------------------------
-- pet purge click handler begin --
---------------------------------------------------
--[[
灵体图标点击回调
--]]
function PetDevelopScene:PetEggClickCallback(sender)
	PlayAudioByClickNormal()
	local index = sender:getParent():getTag()
	self:RefreshPetPurgeCenterByIndex(index)
	GuideUtils.DispatchStepEvent()
end

function PetDevelopScene:GoToSmeltingClick(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('GO_TO_SMELTING_EVENT', {})
end
--[[
培养皿回调
--]]
function PetDevelopScene:PurgePodClickCallback(sender)
	PlayAudioByClickNormal()
	local id = sender:getTag()
	AppFacade.GetInstance():DispatchObservers('PET_PURGE_POD_CLICK_CALLBACK', {purgePodId = id})
end
--[[
培养皿回调
--]]
function PetDevelopScene:PurgePodAllClickCallback(sender)
	PlayAudioByClickNormal()
	local id = sender:getTag()
	AppFacade.GetInstance():DispatchObservers('PET_PURGE_POD_All_CLICK_CALLBACK', {purgePodId = id})
end
--[[
唤醒按钮点击回调
--]]
function PetDevelopScene:PetEggAwakeClickCallback(sender)
	PlayAudioByClickNormal()
	local petEggData = self.petEggs[self.selectedPetEggIndex]
	if petEggData then
		AppFacade.GetInstance():DispatchObservers('PET_EGG_AWAKE_CLICK_CALLBACK', {petEggId = petEggData.goodsId, amount = petEggData.amount})
	end
	self:ShowPetEggDetailLayer(nil, false)
end
--[[
净化按钮点击回调
--]]
function PetDevelopScene:PetEggPurgeClickCallback(sender)
	PlayAudioByClickNormal()
	local petEggData = self.petEggs[self.selectedPetEggIndex]
    if petEggData then
        AppFacade.GetInstance():DispatchObservers('PET_EGG_PURGE_CLICK_CALLBACK', {petEggId = petEggData.goodsId, amount = petEggData.amount})
    end
end
--[[
浇灌按钮回调
--]]
function PetDevelopScene:WateringClickCallback(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('WATERING_CLICK_CALLBACK', {purgePodId = self.selectedPurgePodIndex})
end
--[[
魔菜按钮回调
--]]
function PetDevelopScene:MagicFoodClickCallback(sender)
	PlayAudioByClickNormal()
	local index = sender:getTag()
	AppFacade.GetInstance():DispatchObservers('CHECK_MAGIC_FOOD_CLICK_CALLBACK', {purgePodId = self.selectedPurgePodIndex, magicFoodSlotIndex = index})
end
--[[
加速按钮回调
--]]
function PetDevelopScene:AcceleratePurgeClickCallback(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('ACCELERATE_PURGE_CLICK_CALLBACK', {purgePodId = self.selectedPurgePodIndex})
end
--[[
领取按钮回调
--]]
function PetDevelopScene:DrawPetClickCallback(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('DRAW_PET_AFTER_PURGE', {purgePodId = self.selectedPurgePodIndex})
end
--[[
avatar按钮
--]]
function PetDevelopScene:PetAvatarClickCallback(sender)
	PlayAudioByClickNormal()
	local data = {show = not self.showPetEggDetail}
	if self.selectedPetEggIndex then
		data.selectedPetEggIndex = self.selectedPetEggIndex
	elseif self.selectedPurgePodIndex then
		data.selectedPurgePodIndex = self.selectedPurgePodIndex
	end
	AppFacade.GetInstance():DispatchObservers('SHOW_PET_EGG_DETAIL', data)
end
--[[
排序按钮回调
--]]
function PetDevelopScene:PetPurgeSortClickCallback(sender)
	PlayAudioByClickNormal()
	self:ShowPetPurgeSortBoard(not self.viewData.petPurgeLayer.sortBoard:isVisible())
end
---------------------------------------------------
-- pet purge click handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取当前选中的灵体序号
@return _ int 当前选中的灵体序号
--]]
function PetDevelopScene:GetCurrentSelectedPetEggIndex()
	return self.selectedPetEggIndex
end
--[[
获取当前选中的培养皿序号
--]]
function PetDevelopScene:GetCurrentSelectedPurgePodIndex()
	return self.selectedPurgePodIndex
end
--[[
获取加速净化需要消耗的道具和数量 -> 1分钟1钻
@params second int 剩余秒数
@return goodsId, amount int, int 道具id 数量
--]]
function PetDevelopScene:GetAccelerateCost(second)
	return DIAMOND_ID, math.ceil(second / 180)
end
--[[
根据培养皿id获取培养皿节点
@params purgePodId int 培养皿id
@return _ cc.Node 培养皿节点
--]]
function PetDevelopScene:GetPurgePodNodeByPurgePodId(purgePodId)
	local purgePosCell = self.viewData.petPurgeLayer.poolTableView:cellAtIndex(purgePodId - 1)
	local purgePosNode = self.viewData.petPurgeLayer.poolTableView:getCellViewDataDict()[purgePosCell]
	return purgePosNode
end
--[[
唤醒警告
--]]
function PetDevelopScene:GetShowAwakeWaring()
	return self.showAwakeWaring
end
function PetDevelopScene:SetShowAwakeWaring(b)
	self.showAwakeWaring = b
end
---------------------------------------------------
-- get set end --
---------------------------------------------------
--[[
/***********************************************************************************************************************************\
 * pet develop layer
\***********************************************************************************************************************************/
--]]
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化堕神养成层
--]]
function PetDevelopScene:InitPetDevelopLayer()
	local size = display.size
	local baseZOrder = PetModuleZOrder.CENTER_MODULE
	local topSize = AppFacade.GetInstance():RetrieveMediator('AppMediator'):GetTopLayerSize()
	local selectBgHeight = size.height - topSize.height + 22
	local selectBgWidth = 465

	if display.isFullScreen then
		local bgImgWidth = 875
		selectBgWidth = display.width - (display.SAFE_L + bgImgWidth)
	end

	------------ 初始化灵体选择页 ------------
	-- 背景
	local selectBgSize = cc.size(selectBgWidth, selectBgHeight)
	local selectPetLayer = display.newLayer(size.width - selectBgSize.width * 0.5 - 10, selectBgHeight * 0.5,
			{size = selectBgSize, ap = cc.p(0.5, 0.5)})
	selectPetLayer:setName('selectPetLayer')
	self:addChild(selectPetLayer, baseZOrder + 1)

	local selectPetBg = display.newImageView(_res('ui/common/common_bg_4.png'),
			selectBgSize.width * 0.5,
			selectBgSize.height * 0.5,
			{scale9 = true, size = selectBgSize})
	selectPetLayer:addChild(selectPetBg, 5)

	local titleBg = display.newImageView(_res('ui/common/common_title_5.png'), 0, 0)
	display.commonUIParams(titleBg, {po = cc.p(selectBgSize.width * 0.5, selectBgSize.height - titleBg:getContentSize().height * 0.5 - 15)})
	selectPetLayer:addChild(titleBg, 10)

	local titleLabel = display.newLabel(utils.getLocalCenter(titleBg).x, utils.getLocalCenter(titleBg).y, fontWithColor('5', {  text = __('堕神之家') ,reqW = 130 }))
	titleBg:addChild(titleLabel)


	-- 排序按钮
	local sortBtn = display.newButton(0, 0, {
		n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'),
		cb = handler(self, self.PetDevelopSortClickCallback)
	})
	display.commonUIParams(sortBtn, {po = cc.p(selectBgSize.width - sortBtn:getContentSize().width * 0.5 - 10, titleBg:getPositionY())})
	display.commonLabelParams(sortBtn, fontWithColor('18', {text = __('排序')}))
	selectPetLayer:addChild(sortBtn, 10)

	local sortBoard = require('common.CommonSortBoard').new({
		targetNode = sortBtn,
		sortRules = {
			{sortType = PetSortRule.QUALITY, sortDescr = __('品质'), callbackSignal = 'PET_DEVELOP_SORT', defaultSort = SortOrder.DESC},
			{sortType = PetSortRule.LEVEL, sortDescr = __('等级'), callbackSignal = 'PET_DEVELOP_SORT', defaultSort = SortOrder.DESC},
			{sortType = PetSortRule.BREAK_LEVEL, sortDescr = __('强化'), callbackSignal = 'PET_DEVELOP_SORT', defaultSort = SortOrder.DESC}
		}
	})
	display.commonUIParams(sortBoard, {ap = cc.p(0.5, 1), po = (
			self:convertToNodeSpace(sortBtn:getParent():convertToWorldSpace(cc.p(sortBtn:getPositionX(), sortBtn:getPositionY() - sortBtn:getContentSize().height * 0.5)))
	)})
	self:addChild(sortBoard, 999)
	sortBoard:setVisible(false)

	-- 列表底
	local gridViewBgSize = cc.size(selectBgSize.width - 20, selectBgSize.height - 68)

	local gridViewBg = display.newImageView(_res('ui/common/common_bg_goods.png'),
			selectBgSize.width * 0.5,
			gridViewBgSize.height * 0.5 + 10,
			{scale9 = true, size = gridViewBgSize})
	selectPetLayer:addChild(gridViewBg, 6)

	-- 灵体列表
	local gridViewSize = cc.size(gridViewBgSize.width, gridViewBgSize.height - 2)
	local gridPerLine = 1
	local cellSize = cc.size(gridViewSize.width / gridPerLine, 111)
	local gridView = CGridView:create(gridViewSize)
	gridView:setName('petGridView')
	gridView:setAnchorPoint(cc.p(0.5, 0.5))
	gridView:setPosition(cc.p(gridViewBg:getPositionX(), gridViewBg:getPositionY()))
	selectPetLayer:addChild(gridView, 7)
	-- gridView:setBackgroundColor(cc.c4b(255, 128, 0, 128))

	gridView:setCountOfCell(10)
	gridView:setColumns(gridPerLine)
	gridView:setSizeOfCell(cellSize)
	gridView:setAutoRelocate(false)
	gridView:setDataSourceAdapterScriptHandler(handler(self, self.PetDevelopGridViewDataAdapter))

	-- 全空状态
	local emptyGodScale = 0.75
	local petEmptyGod = AssetsUtils.GetCartoonNode(3, selectBgSize.width * 0.5, selectBgSize.height * 0.6)
	petEmptyGod:setScale(emptyGodScale)
	selectPetBg:addChild(petEmptyGod)

	local petEmptyLabel = display.newLabel(
			petEmptyGod:getPositionX(),
			petEmptyGod:getPositionY() - 424 * 0.5 * emptyGodScale - 40,
			fontWithColor('14', {text = __('你还没有堕神')}))
	selectPetBg:addChild(petEmptyLabel)

	-- 堕神上限
	local petAmountLabel = display.newLabel(0, 0, fontWithColor('5', {text = string.format(__('数量 %d/%d'), 0, 0), fontSize = 20}))
	display.commonUIParams(petAmountLabel, {ap = cc.p(0, 0.5), po = cc.p(
			15,
			titleBg:getPositionY()
	)})
	selectPetLayer:addChild(petAmountLabel, 10)
	------------ 初始化灵体选择页 ------------

	------------ 初始化详细属性侧页 ------------
	local designHeight = 750

	-- 书页夹层
	local bookTop = display.newImageView(_res('ui/pet/pet_info_bg_layer_front.png'), 0, 0)
	bookTop:setScaleY(display.height / designHeight)
	display.commonUIParams(bookTop, {po = cc.p(
			selectPetLayer:getPositionX() - selectPetLayer:getContentSize().width * 0.5 + 32,
			selectPetLayer:getPositionY() + 35
	)})
	self:addChild(bookTop, selectPetLayer:getLocalZOrder() - 1)

	local bookBottom = display.newImageView(_res('ui/pet/pet_info_bg_layer_back.png'), 0, 0)
	bookBottom:setScaleY(display.height / designHeight)
	display.commonUIParams(bookBottom, {po = cc.p(
			selectPetLayer:getPositionX() - 20,
			selectPetLayer:getPositionY() + 15
	)})
	self:addChild(bookBottom, selectPetLayer:getLocalZOrder() - 3)

	-- 正中层
	local bookMiddle = display.newImageView(_res('ui/pet/pet_info_bg_layer_middle.png'), 0, 0)
	display.commonUIParams(bookMiddle, {po = cc.p(
			selectPetLayer:getPositionX() - selectPetLayer:getContentSize().width * 0.5 - bookMiddle:getContentSize().width * 0.5 + 45,
			selectPetLayer:getPositionY() + 10
	)})
	self:addChild(bookMiddle, selectPetLayer:getLocalZOrder() - 2)

	-- 正中层layer
	local mLayerSize = cc.size(275, 555)
	local mLayerPos = cc.p(bookMiddle:getPositionX() - 22, 	bookMiddle:getPositionY())
	local bookMiddleLayer = display.newLayer(mLayerPos.x, mLayerPos.y, {size = mLayerSize, ap = cc.p(0.5, 0.5)})
	self:addChild(bookMiddleLayer, bookMiddle:getLocalZOrder())
	-- bookMiddleLayer:setBackgroundColor(cc.c4b(55, 55, 55, 120))

	-- debug --
	-- local testLayer = display.newLayer(0, 0, {size = cc.size(275, 555)})
	-- display.commonUIParams(testLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
	-- 	bookMiddle:getPositionX() - 22,
	-- 	bookMiddle:getPositionY()
	-- )})
	-- testLayer:setBackgroundColor(cc.c4b(55, 55, 55, 100))
	-- self:addChild(testLayer, selectPetLayer:getLocalZOrder() + 2)
	-- debug --

	-- 性格
	local characterBg = display.newImageView(_res('ui/pet/pet_info_bg_character.png'), 0, 0)
	display.commonUIParams(characterBg, {po = cc.p(
			mLayerSize.width * 0.5,
			mLayerSize.height - characterBg:getContentSize().height * 0.5 - 3
	)})
	bookMiddleLayer:addChild(characterBg)

	-- 分隔线
	local characterSplitLine = display.newNSprite(_res('ui/pet/pet_info_ico_attribute_line.png'), 0, 0)
	display.commonUIParams(characterSplitLine, {po = cc.p(
			characterBg:getContentSize().width * 0.5,
			characterBg:getContentSize().height * 0.575
	)})
	characterSplitLine:setScaleX((characterBg:getContentSize().width - 40) / characterSplitLine:getContentSize().width)
	characterBg:addChild(characterSplitLine)

	-- 性格文字
	local characterLabel = display.newLabel(0, 0, fontWithColor('5', {text = '性格:测试'}))
	display.commonUIParams(characterLabel, {ap = cc.p(0.5, 0), po = cc.p(
			characterSplitLine:getPositionX(),
			characterSplitLine:getPositionY() + characterSplitLine:getContentSize().height * 0.5
	)})
	characterBg:addChild(characterLabel)

	-- 性格描述
	local characterDescrLabel = display.newLabel(0, 0,
			fontWithColor('6', {text = string.format('(%s)', '测试性格+100%'), w = characterBg:getContentSize().width - 30, hAlign = display.TAC}))
	characterDescrLabel:setAnchorPoint(cc.p(0, 0))
	-- display.commonUIParams(characterDescrLabel, {ap = cc.p(0.5, 0), po = cc.p(
	-- 	characterSplitLine:getPositionX(),
	-- 	characterSplitLine:getPositionY() - characterSplitLine:getContentSize().height * 0.5 - 10
	-- )})
	-- characterBg:addChild(characterDescrLabel)

	local listViewSize = cc.size(characterBg:getContentSize().width - 30, 50)
	local listView = CListView:create(listViewSize)
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setBounceable(false)
	listView:setAnchorPoint(cc.p(0.5, 0))
	listView:setPosition(cc.p(mLayerSize.width * 0.5, mLayerSize.height - characterBg:getContentSize().height*0.9))
	bookMiddleLayer:addChild(listView, 10)
	local labelLayout = CLayout:create(cc.size(listViewSize.width, display.getLabelContentSize(characterDescrLabel).height+5))
	labelLayout:addChild(characterDescrLabel)
	listView:insertNodeAtLast(labelLayout)
	listView:reloadData()
	-- 堕神属性
	local cellHeight = 42
	local petPInfo = petMgr.GetPetPInfo()
	local petPAmount = #petPInfo
	local petPNodes = {}
	--[[
	petPNodes = {
		{lockNode = nil, iconNode = nil, nameNode = nil, valueNode},
		{lockNode = nil, iconNode = nil, nameNode = nil, valueNode},
		{lockNode = nil, iconNode = nil, nameNode = nil, valueNode},
		...
	}
	--]]

	for i = 1, petPAmount do
		-- 分隔线
		local petPSplitLine = display.newNSprite(_res('ui/pet/pet_info_ico_attribute_line.png'), 0, 0)
		display.commonUIParams(petPSplitLine, {po = cc.p(
				characterBg:getPositionX(),
				characterBg:getPositionY() - characterBg:getContentSize().height * 0.5 - (i * cellHeight) - 5
		)})
		bookMiddleLayer:addChild(petPSplitLine)

		-- 锁定页
		local lockBg = display.newNSprite(_res('ui/pet/pet_info_ico_attribute_lock.png'), 0, 0)
		display.commonUIParams(lockBg, {po = cc.p(
				characterBg:getPositionX(),
				characterBg:getPositionY() - characterBg:getContentSize().height * 0.5 - ((i - 0.5) * cellHeight) - 5
		)})
		bookMiddleLayer:addChild(lockBg)

		local lockLabel = display.newLabel(0, 0, fontWithColor('18', {text = string.format(__('堕神等级%d级解锁'), petPInfo[i].unlockLevel) , reqW = 290}))
		display.commonUIParams(lockLabel, {po = utils.getLocalCenter(lockBg)})
		lockBg:addChild(lockLabel)

		petPNodes[i] = {lockNode = lockBg}
	end

	-- 跟随状态
	local equipedLabel = display.newLabel(0, 0, fontWithColor('5', {text = __('跟随')}))
	display.commonUIParams(equipedLabel, {po = cc.p(
			characterBg:getPositionX(),
			225
	)})
	bookMiddleLayer:addChild(equipedLabel)

	local equipedIconBg = display.newNSprite(_res('ui/pet/pet_info_bg_frame_1.png'), 0, 0)
	display.commonUIParams(equipedIconBg, {po = cc.p(
			characterBg:getPositionX(),
			equipedLabel:getPositionY() - 17 - equipedIconBg:getContentSize().height * 0.5
	)})
	bookMiddleLayer:addChild(equipedIconBg)

	local equipedIcon = display.newNSprite(_res('ui/common/common_frame_goods_1.png'), 0, 0)
	display.commonUIParams(equipedIcon, {po = cc.p(
			equipedIconBg:getPositionX(),
			equipedIconBg:getPositionY()
	)})
	equipedIcon:setScale(0.9)
	bookMiddleLayer:addChild(equipedIcon)

	local equipEmptyIcon = display.newNSprite(_res('ui/common/compose_ico_unkown.png'), 0, 0)
	display.commonUIParams(equipEmptyIcon, {po = utils.getLocalCenter(equipedIcon)})
	equipedIcon:addChild(equipEmptyIcon)

	-- 本命飨灵
	local exclusiveScrollView = ui.scrollView({size = cc.size(mLayerSize.width, 110), dir = display.SDIR_V})
	bookMiddleLayer:addList(exclusiveScrollView):alignTo(nil, ui.cb, {offsetY = -10})

	local exclusiveCardLabel = ui.label({fnt = FONT.D6, fontSize = 20, w = mLayerSize.width - 10, ap = ui.lt, hAlign = display.TAC})
	exclusiveScrollView:getContainer():add(exclusiveCardLabel)

	------------ 初始化详细属性侧页 ------------

	------------ 初始化左侧堕神页 ------------
	local petPreviewLayer = display.newLayer(0, 0, {size = size})
	petPreviewLayer:setName('purgeFrameLayer')
	display.commonUIParams(petPreviewLayer, {ap = cc.p(0.5, 0.5), po = cc.p(size.width * 0.5, size.height * 0.5)})
	self:addChild(petPreviewLayer, baseZOrder - 5)

	local petPreviewBg = display.newImageView(_res('ui/pet/pet_info_bg_pet_place.png'), 0, 0)
	display.commonUIParams(petPreviewBg, {po = cc.p(
			display.SAFE_L + petPreviewBg:getContentSize().width * 0.5,
			petPreviewBg:getContentSize().height * 0.5 - 125
	)})
	petPreviewLayer:addChild(petPreviewBg, 4)

	-- 展示堕神层的坐标
	local petPos = cc.p(
			petPreviewBg:getPositionX() - 159,
			petPreviewBg:getPositionY() - 147
	)
	local petPreviewNormalPos = cc.p(petPreviewLayer:getPositionX(), petPreviewLayer:getPositionY())
	local petPreviewNonePos = cc.p(
			petPreviewLayer:getPositionX() + (display.width - selectBgSize.width - 600),
			petPreviewLayer:getPositionY()
	)

	local petFixedPos = {
		petPos = petPos, -- 堕神展示spine的脚底坐标
		petLockBtnPos = cc.p(petPos.x - 200, petPos.y - 18), -- 锁定按钮坐标
		petDeleteBtnPos = cc.p(petPos.x + 200, petPos.y - 18), -- 删除按钮坐标
		petDevBtnPos = cc.p(petPos.x, petPos.y - 170), -- 培养按钮坐标
		petLevelPos = cc.p(petPos.x - 115, petPos.y - 55), -- 等级图标坐标
		petPreviewNormalPos = petPreviewNormalPos, -- 展示层正常坐标
		petPreviewNonePos = petPreviewNonePos -- 展示层缩进坐标
	}

	-- debug --
	-- local layer = display.newLayer(petPos.x, petPos.y, {size = cc.size(20, 20), color = 'abcd12', ap = cc.p(0.5, 0.5)})
	-- petPreviewLayer:addChild(layer, 999)
	-- debug --

	-- 上锁按钮
	local lockBtn = display.newButton(petFixedPos.petLockBtnPos.x, petFixedPos.petLockBtnPos.y,
			{n = _res('ui/pet/pet_info_btn_unlock.png'), cb = handler(self, self.LockPetClickCallback)})
	petPreviewLayer:addChild(lockBtn, 5)

	-- 放生按钮
	local deleteBtn = display.newButton(petFixedPos.petDeleteBtnPos.x, petFixedPos.petDeleteBtnPos.y,
			{n = _res('ui/pet/pet_info_btn_delete.png'), cb = handler(self, self.DeletePetClickCallback)})
	petPreviewLayer:addChild(deleteBtn, 5)

	-- 培养按钮
	local devBtn = display.newButton(petFixedPos.petDevBtnPos.x, petFixedPos.petDevBtnPos.y,
			{n = _res('ui/common/common_btn_orange.png'), cb = handler(self, self.DevelopPetClickCallback)})
	devBtn:setName('devBtn')
	display.commonLabelParams(devBtn, fontWithColor('14', {text = __('培养')}))
	petPreviewLayer:addChild(devBtn, 5)

	-- 底部等级信息
	-- 等级
	local levelIcon = display.newNSprite(_res('ui/pet/pet_info_bg_levelnum.png'), petFixedPos.petLevelPos.x, petFixedPos.petLevelPos.y)
	petPreviewLayer:addChild(levelIcon, 5)

	local levelLabel = display.newLabel(utils.getLocalCenter(levelIcon).x - 2, utils.getLocalCenter(levelIcon).y,
			fontWithColor('14', {text = '88'}))
	levelIcon:addChild(levelLabel)

	-- 名字
	local petNameLabel = display.newLabel(0, 0, fontWithColor('14', {text = '测试名字'}))
	display.commonUIParams(petNameLabel, {ap = cc.p(0, 0.5), po = cc.p(
			levelIcon:getPositionX() + levelIcon:getContentSize().width * 0.5 + 15,
			levelIcon:getPositionY()
	)})
	petPreviewLayer:addChild(petNameLabel, 5)

	-- 强化等级
	local breakLevelLabel = CLabelBMFont:create(
			'+0',
			'font/common_num_1.fnt'
	)
	breakLevelLabel:setBMFontSize(24)
	breakLevelLabel:setAnchorPoint(cc.p(0, 0.5))
	breakLevelLabel:setPosition(cc.p(
			petNameLabel:getPositionX() + display.getLabelContentSize(petNameLabel).width + 5,
			petNameLabel:getPositionY()
	))
	petPreviewLayer:addChild(breakLevelLabel, 5)
	------------ 初始化左侧堕神页 ------------

	self.viewData.petDevelopLayer = {
		------------ view nodes ------------
		gridView = gridView,
		bookMiddleLayer = bookMiddleLayer,
		characterLabel = characterLabel,
		characterDescrLabel = characterDescrLabel,
		listView = listView,
		listViewSize = listViewSize,
		labelLayout = labelLayout,
		petPNodes = petPNodes,
		exclusiveCardLabel = exclusiveCardLabel,
		exclusiveScrollView = exclusiveScrollView,
		petPreviewLayer = petPreviewLayer,
		petNameLabel = petNameLabel,
		levelLabel = levelLabel,
		breakLevelLabel = breakLevelLabel,
		lockBtn = lockBtn,
		equipedIconBg = equipedIconBg,
		equipedIcon = equipedIcon,
		equipedCardHeadNode = nil,
		previewAvatar = nil,
		petAmountLabel = petAmountLabel,
		sortBoard = sortBoard,
		------------ view data ------------
		petFixedPos = petFixedPos,
		------------ layer handler ------------
		ShowNoPet = function (no)
			-- 显示没有堕神的状态
			-- 左侧选择页部分
			sortBtn:setVisible(not no)
			gridViewBg:setVisible(not no)
			gridView:setVisible(not no)

			petEmptyGod:setVisible(no)
			petEmptyLabel:setVisible(no)

			-- 中间属性板部分
			bookMiddle:setVisible(not no)
			bookMiddleLayer:setVisible(not no)

			-- 左侧展示层
			-- petPreviewLayer:setPosition(no and petFixedPos.petPreviewNonePos or petFixedPos.petPreviewNormalPos)
			levelIcon:setVisible(not no)
			petNameLabel:setVisible(not no)
			breakLevelLabel:setVisible(false)
			if nil ~= self.viewData.petDevelopLayer.previewAvatar then
				self.viewData.petDevelopLayer.previewAvatar:setVisible(not no)
			end
		end,
		ShowNoPetSelect = function (no)
			-- 中间属性板部分
			bookMiddle:setVisible(not no)
			bookMiddleLayer:setVisible(not no)

			-- 左侧展示层
			-- petPreviewLayer:setPosition(no and petFixedPos.petPreviewNonePos or petFixedPos.petPreviewNormalPos)
			levelIcon:setVisible(not no)
			petNameLabel:setVisible(not no)
			breakLevelLabel:setVisible(false)
			if nil ~= self.viewData.petDevelopLayer.previewAvatar then
				self.viewData.petDevelopLayer.previewAvatar:setVisible(not no)
			end
		end,
		ShowSelf = function (show)
			-- 选择页
			selectPetLayer:setVisible(show)
			bookTop:setVisible(show)
			bookBottom:setVisible(show)
			-- 属性页
			bookMiddle:setVisible(show)
			bookMiddleLayer:setVisible(show)
			-- 展示页
			petPreviewLayer:setVisible(show)
		end
	}

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- pet develop control begin --
---------------------------------------------------
--[[
刷新堕神选择页面
@params pets table 堕神数据
--]]
function PetDevelopScene:RefreshPets(pets)
	self.pets = pets

	self.viewData.petDevelopLayer.ShowNoPet(0 >= #self.pets)

	------------ 为最下添加一行空cell ------------
	local petAmount = #self.pets
	local addedRow = 2
	local cellPerLine = self.viewData.petDevelopLayer.gridView:getColumns()
	local addedCell = math.ceil(petAmount / cellPerLine) * cellPerLine - petAmount + (addedRow - 1) * cellPerLine + 1
	self.viewData.petDevelopLayer.gridView:setCountOfCell(petAmount + addedCell)
	self.viewData.petDevelopLayer.gridView:reloadData()
	------------ 为最下添加一行空cell ------------

	-- 刷新最大数量
	self:RefreshPetAmount(#self.pets, CommonUtils.getVipTotalLimitByField('petNumLimit'))

	-- if self.gridContentOffset then
	-- 	self.viewData.petDevelopLayer.gridView:setContentOffset(self.gridContentOffset)
	-- end
end
--[[
刷新cell
--]]
function PetDevelopScene:PetDevelopGridViewDataAdapter(c, i)
	local cell = c
	local index = i + 1

	if nil == cell then
		cell = require('Game.views.pet.PetSelectCell').new({
			size = self.viewData.petDevelopLayer.gridView:getSizeOfCell(),
			callback = handler(self, self.PetCellClickCallback)
		})
		cell:setContentSize(self.viewData.petDevelopLayer.gridView:getSizeOfCell())
		-- cell:setBackgroundColor(cc.c4b(math.random(255), math.random(255), math.random(255), 100))
	end

	------------ 处理最下的空cell ------------
	if index > #self.pets then

		cell:setVisible(false)

	else

		cell:setVisible(true)
		local petData = self.pets[index]
		cell:RefreshUI({
			id = petData.id
		})

	end
	------------ 处理最下的空cell ------------

	cell:getChildByTag(3):setVisible(self.selectedPetIndex and (index == self.selectedPetIndex))

	cell:setTag(index)

	return cell
end
--[[
根据选中的堕神index刷新堕神养成界面
@params index int 堕神index
--]]
function PetDevelopScene:RefreshPetDevelopDetailByIndex(index)

	-- 空状态
	self.viewData.petDevelopLayer.ShowNoPetSelect(nil == index)

	if index == self.selectedPetIndex then return end

	if nil ~= index then
		local curCell = self.viewData.petDevelopLayer.gridView:cellAtIndex(index - 1)
		if nil ~= curCell then
			curCell:getChildByTag(3):setVisible(true)
		end
	end

	if nil ~= self.selectedPetIndex then
		local preCell = self.viewData.petDevelopLayer.gridView:cellAtIndex(self.selectedPetIndex - 1)
		if nil ~= preCell then
			preCell:getChildByTag(3):setVisible(false)
		end
	end

	self.selectedPetIndex = index

	if nil ~= index then
		local petData = self.pets[self:GetCurrentSelectedPetIndex()]
		self:RefreshPetInfoBySelectPet(petData)
		self:RefreshPetPreview(petData)
	end

end
--[[
刷新左侧堕神展示页
@params petData table 堕神信息
--]]
function PetDevelopScene:RefreshPetPreview(petData)
	local petId = checkint(petData.petId)
	local petConfig = petMgr.GetPetConfig(petId)

	-- 刷新堕神名字
	self.viewData.petDevelopLayer.petNameLabel:setString(petConfig.name)

	-- 刷新堕神等级
	self:RefreshPetPreviewLevel(petData.level)

	-- 刷新堕神强化等级
	self:RefreshPetPreviewBreakLevel(checkint(petData.breakLevel))

	-- 刷新上锁状态
	self:RefreshPetPreviewLock(0 ~= checkint(petData.isProtect))

	-- 刷新中间spine avatar
	self:RefreshPetPreviewAvatar(checkint(petData.petId))
end
--[[
刷新展示页堕神等级
@params level int 等级
--]]
function PetDevelopScene:RefreshPetPreviewLevel(level)
	self.viewData.petDevelopLayer.levelLabel:setString(tostring(level))
end
--[[
刷新强化等级
@params breakLabel int 强化等级
--]]
function PetDevelopScene:RefreshPetPreviewBreakLevel(breakLevel)
	self.viewData.petDevelopLayer.breakLevelLabel:setVisible(0 ~= breakLevel)
	self.viewData.petDevelopLayer.breakLevelLabel:setString(string.format('+%d', breakLevel))

	local alignNode = self.viewData.petDevelopLayer.petNameLabel
	self.viewData.petDevelopLayer.breakLevelLabel:setPosition(cc.p(
			alignNode:getPositionX() + display.getLabelContentSize(alignNode).width + 5,
			alignNode:getPositionY()
	))
end
--[[
刷新上锁状态
--]]
function PetDevelopScene:RefreshPetPreviewLock(lock)
	local path = 'ui/pet/pet_info_btn_unlock.png'
	if lock then
		path = 'ui/pet/pet_info_btn_lock.png'
	end
	self.viewData.petDevelopLayer.lockBtn:setNormalImage(path)
	self.viewData.petDevelopLayer.lockBtn:setSelectedImage(path)
end
--[[
刷新spine avatar
@params petId int 堕神id
--]]
function PetDevelopScene:RefreshPetPreviewAvatar(petId)
	if nil ~= self.viewData.petDevelopLayer.previewAvatar then
		self.viewData.petDevelopLayer.previewAvatar:removeFromParent()
		self.viewData.petDevelopLayer.previewAvatar = nil
	end

	local petPath = petMgr.GetPetSpineAvatarPathByPetId(petId)
	local avatar  = AssetsUtils.GetCardSpineNode({skinPath = petPath, scale = 0.5})
	avatar:setScaleX(-1 * avatar:getScaleX())
	avatar:setPosition(self.viewData.petDevelopLayer.petFixedPos.petPos)
	self.viewData.petDevelopLayer.petPreviewLayer:addChild(avatar, 1)

	avatar:update(0)
	avatar:setToSetupPose()
	avatar:setAnimation(0, 'idle', true)

	self.viewData.petDevelopLayer.previewAvatar = avatar
end
--[[
根据选中的堕神信息刷新中间详细信息
@params petData table 堕神信息
--]]
function PetDevelopScene:RefreshPetInfoBySelectPet(petData)
	-- 刷新性格
	self:RefreshPetInfoCharacter(checkint(petData.character))

	-- 刷新六属性
	self:RefreshAllPetProperty(petData)

	-- 刷新本命信息
	self:RefreshPetExclusiveCards(checkint(petData.petId))

	-- 刷新跟随图标
	self.viewData.petDevelopLayer.equipedIconBg:setTexture(
			_res(string.format('ui/pet/pet_info_bg_frame_%d.png', petMgr.GetPetQualityByPetId(checkint(petData.petId))))
	)

	-- 刷新跟随状态
	self:RefreshEquipedState(petData.playerCardId)
end
--[[
刷新所有属性
@params petData table 堕神信息
--]]
function PetDevelopScene:RefreshAllPetProperty(petData)
	local petPInfo = petMgr.GetPetPInfo()
	local petPNodes = self.viewData.petDevelopLayer.petPNodes

	local petPData = petMgr.GetPetAllFixedProps(checkint(petData.id))

	for i,v in ipairs(petPData) do
		-- 判断是否解锁
		petPNodes[i].lockNode:setVisible(not v.unlock)

		-- 刷新单条属性
		self:RefreshAPetProperty(
				checkint(petData.petId),
				i,
				v.ptype,
				v.pvalue,
				v.pquality,
				v.unlock
		)
	end
end
--[[
刷新单条属性
@params petId int 堕神配表id
@params propIndex int 属性序号
@params propId PetP 属性id
@params propValue int 属性数值
@params unlock bool 是否解锁
--]]
function PetDevelopScene:RefreshAPetProperty(petId, propIndex, propId, propValue, propQuality, unlock)
	local petPNode = self.viewData.petDevelopLayer.petPNodes[propIndex]
	local propConfig = PetPConfig[propId]

	-- 属性图标
	if nil == petPNode.iconNode then
		local iconNode = display.newNSprite(_res(propConfig.iconPath), 0, 0)
		display.commonUIParams(iconNode, {po = cc.p(
				5 + iconNode:getContentSize().width * 0.5,
				petPNode.lockNode:getPositionY()
		)})
		self.viewData.petDevelopLayer.bookMiddleLayer:addChild(iconNode)

		self.viewData.petDevelopLayer.petPNodes[propIndex].iconNode = iconNode
	else
		petPNode.iconNode:setTexture(_res(propConfig.iconPath))
	end
	petPNode.iconNode:setVisible(unlock or false)

	-- 属性名字
	if nil == petPNode.nameNode then
		local nameNode = display.newLabel(0, 0, fontWithColor('5', {text = propConfig.name}))
		display.commonUIParams(nameNode, {ap = cc.p(0, 0.5), po = cc.p(
				petPNode.iconNode:getPositionX() + petPNode.iconNode:getContentSize().width * 0.5 + 15,
				petPNode.iconNode:getPositionY()
		)})
		self.viewData.petDevelopLayer.bookMiddleLayer:addChild(nameNode)

		self.viewData.petDevelopLayer.petPNodes[propIndex].nameNode = nameNode
	else
		petPNode.nameNode:setString(propConfig.name)
	end
	petPNode.nameNode:setVisible(unlock or false)

	-- 属性值
	if nil ~= petPNode.valueNode then
		if propQuality == petPNode.valueNode:getTag() then
			petPNode.valueNode:setString(tostring(math.floor(propValue)))
		else
			petPNode.valueNode:removeFromParent()
			petPNode.valueNode = nil
		end
	end

	if nil == petPNode.valueNode then
		local valueNode = CLabelBMFont:create(
				tostring(math.floor(propValue)),
				petMgr.GetPetPropFontPath(propQuality)
		)
		valueNode:setBMFontSize(26)
		valueNode:setAnchorPoint(cc.p(1, 0.5))
		valueNode:setPosition(cc.p(
				self.viewData.petDevelopLayer.bookMiddleLayer:getContentSize().width - 10,
				petPNode.iconNode:getPositionY()
		))
		self.viewData.petDevelopLayer.bookMiddleLayer:addChild(valueNode)
		valueNode:setTag(propQuality)

		self.viewData.petDevelopLayer.petPNodes[propIndex].valueNode = valueNode
	end
	petPNode.valueNode:setVisible(unlock or false)

end
--[[
刷新性格
@params characterId int 性格id
--]]
function PetDevelopScene:RefreshPetInfoCharacter(characterId)
	local characterConfig = CommonUtils.GetConfig('pet', 'petCharacter', characterId)

	if nil == characterConfig then
		return
	end

	-- 性格名字
	self.viewData.petDevelopLayer.characterLabel:setString(characterConfig.name)

	-- 性格描述
	self.viewData.petDevelopLayer.characterDescrLabel:setString(petMgr.GetFixedPetCharacterDescr(characterId))
	self.viewData.petDevelopLayer.labelLayout:setContentSize(cc.size(self.viewData.petDevelopLayer.listViewSize.width, display.getLabelContentSize(self.viewData.petDevelopLayer.characterDescrLabel).height+5))
	self.viewData.petDevelopLayer.listView:reloadData()
end
--[[
根据堕神id刷新本命信息
@params petId int 堕神id
--]]
function PetDevelopScene:RefreshPetExclusiveCards(petId)
	local viewData  = self.viewData.petDevelopLayer
	local petConfig = petMgr.GetPetConfig(petId)

	if nil == petConfig.exclusiveCard or 0 == #petConfig.exclusiveCard then
		viewData.exclusiveCardLabel:setString(__('暂无本命飨灵'))
	else
		local petExclusiveCardsStr = ''
		local cardConfig = nil
		for i,v in ipairs(petConfig.exclusiveCard) do
			cardConfig = CardUtils.GetCardConfig(checkint(v))
			if nil ~= cardConfig then
				petExclusiveCardsStr = petExclusiveCardsStr .. tostring(cardConfig.name)
				if i ~= #petConfig.exclusiveCard then
					petExclusiveCardsStr = petExclusiveCardsStr .. ','
				end
			end
		end
		viewData.exclusiveCardLabel:setString(string.format(__('本命飨灵:%s'), petExclusiveCardsStr))
	end

	local descrSize      = display.getLabelContentSize(viewData.exclusiveCardLabel)
    local scrollViewSize = viewData.exclusiveScrollView:getContentSize()
    local containerH     = math.max(scrollViewSize.height, descrSize.height + 10)
    viewData.exclusiveScrollView:setContainerSize(cc.size(scrollViewSize.width, math.max(containerH, scrollViewSize.height)))
    viewData.exclusiveCardLabel:setPosition(cc.p(5, containerH - 5))
	viewData.exclusiveScrollView:setContentOffsetToTop()
end
--[[
根据卡牌刷新跟随状态
@params equipedCardId int 卡牌id
--]]
function PetDevelopScene:RefreshEquipedState(equipedCardId)
	local noEquipCard = false
	if nil == equipedCardId or 0 == checkint(equipedCardId) then
		noEquipCard = true
	end

	-- 空状态
	self.viewData.petDevelopLayer.equipedIcon:setVisible(noEquipCard)

	-- 非空 卡牌头像
	if not noEquipCard then
		if nil == self.viewData.petDevelopLayer.equipedCardHeadNode then
			-- 创建一个卡牌头像
			local cardHead = require('common.CardHeadNode').new({
				id = equipedCardId,
				showBaseState = true,
				showActionState = true,
				showVigourState = true
			})
			cardHead:setPosition(cc.p(
					self.viewData.petDevelopLayer.equipedIconBg:getPositionX(),
					self.viewData.petDevelopLayer.equipedIconBg:getPositionY()
			))
			cardHead:setScale(0.55)
			self.viewData.petDevelopLayer.bookMiddleLayer:addChild(cardHead, 10)

			self.viewData.petDevelopLayer.equipedCardHeadNode = cardHead
		else
			-- 刷新卡牌头像
			self.viewData.petDevelopLayer.equipedCardHeadNode:RefreshUI({id = equipedCardId})
		end
	end

	if nil ~= self.viewData.petDevelopLayer.equipedCardHeadNode then
		self.viewData.petDevelopLayer.equipedCardHeadNode:setVisible(not noEquipCard)
	end
end
--[[
根据cell index 刷新某个单元格状态
--]]
function PetDevelopScene:RefreshPetGridViewCellByIndex(index)
	local cell = self.viewData.petDevelopLayer.gridView:cellAtIndex(index - 1)

	if cell then
		if index > #self.pets then
			cell:setVisible(false)
		else
			cell:setVisible(true)
			local petData = self.pets[index]
			cell:RefreshUI({
				id = checkint(petData.id)
			})
		end
	end
end
--[[
刷新堕神数量状态
@params curAmount int 当前拥有的数量
@params maxAmount int 最大数量
--]]
function PetDevelopScene:RefreshPetAmount(curAmount, maxAmount)
	self.viewData.petDevelopLayer.petAmountLabel:setString(string.format(__('数量 %d/%d'), curAmount, maxAmount))
end
--[[
显示排序板
@params show bool 是否显示排序版
--]]
function PetDevelopScene:ShowPetDevelopSortBoard(show)
	self.viewData.petDevelopLayer.sortBoard:setVisible(show)
end
---------------------------------------------------
-- pet develop control end --
---------------------------------------------------

---------------------------------------------------
-- pet develop click handler begin --
---------------------------------------------------
--[[
堕神栏点击回调
--]]
function PetDevelopScene:PetCellClickCallback(sender)
	PlayAudioByClickNormal()
	local index = sender:getParent():getTag()
	-- self.gridContentOffset = self.viewData.petDevelopLayer.gridView:getContentOffset()
	self:RefreshPetDevelopDetailByIndex(index)
end
--[[
锁定按钮回调
--]]
function PetDevelopScene:LockPetClickCallback(sender)
	PlayAudioByClickNormal()
	local id = self:GetCurrentSelectedPetId()
	AppFacade.GetInstance():DispatchObservers('LOCK_PET', {id = id})
end
--[[
删除按钮回调
--]]
function PetDevelopScene:DeletePetClickCallback(sender)
	PlayAudioByClickNormal()
	local id = self:GetCurrentSelectedPetId()
	local quality =  app.petMgr.GetPetQualityById(id)
	if quality <= PetPQuality.BLUE then
		local viewData = self:CreateDelView(sender)
		viewData.batchDelBtn:setOnClickScriptHandler(function(sender)
			self:CreateDelPopView()
			viewData.swallowLayer:setEnabled(false)
			viewData.layer:runAction(
					cc.RemoveSelf:create()
			)
		end)
		viewData.singleDelBtn:setOnClickScriptHandler(function(sender)
			AppFacade.GetInstance():DispatchObservers('DELETE_PET', {id = id})
			viewData.swallowLayer:setEnabled(false)
			viewData.layer:runAction(
					cc.RemoveSelf:create()
			)
		end)
	else
		AppFacade.GetInstance():DispatchObservers('DELETE_PET', {id = id})
	end
end

function PetDevelopScene:CreateDelPopView()
	local qualitys = {}
	local selectFunc = function (sender)
		local checked = sender:isChecked()
		local tag = sender:getTag()
		local selectImage = sender:getChildByName("selectImage")
		if checked then
			qualitys[tostring(tag)] = tag
			selectImage:setTexture(_res('ui/common/common_btn_check_selected'))
		else
			qualitys[tostring(tag)] = nil
			selectImage:setTexture(_res('ui/common/common_btn_check_default'))
		end
	end
	local newCommonTip = require("common.NewCommonTip").new({
		isOnlyOK = true  ,
		btnTextR =__('放生') ,
		text = __('请选择批量放生哪种类型的堕神') ,
		textOffset = cc.p(0, 45),
		callback =
		function()
			local qualityPets = {}
			for i, qualityId in pairs(qualitys) do
				local qualityPetsData = self:GetDelPetsByQuality(qualityId)
				for i, id in pairs(qualityPetsData) do
					qualityPets[#qualityPets+1] = id
				end
			end
			AppFacade.GetInstance():DispatchObservers('DELETE_ONE_KIND_PET', {petsData = qualityPets})
		end
	})
	newCommonTip:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(newCommonTip)
	local view =  newCommonTip.view
	local viewSize = view:getContentSize()
	local centerLayoutSize =  cc.size(330, 100 )
	local centerLayout = display.newLayer(viewSize.width/2 , viewSize.height/2 , { ap = display.CENTER,   size = centerLayoutSize})
	view:addChild(centerLayout)

	local whiteBtn = display.newCheckBox(centerLayoutSize.width/2 , centerLayoutSize.height/4*3 ,{ n = _res('ui/pet/oneDel/pet_batch_bg_unselected') , s =  _res('ui/pet/oneDel/pet_batch_bg_selected')})
	centerLayout:addChild(whiteBtn)
	whiteBtn:setTag(1)
	local whiteBtnSize = whiteBtn:getContentSize()
	local whitleLabel = display.newLabel(whiteBtnSize.width/2 , whiteBtnSize.height/2 , fontWithColor(6 , {text = __('白色堕神')}))
	whiteBtn:addChild(whitleLabel)
	whitleLabel:setName("label")

	local whiteImage = display.newImageView(_res('ui/common/common_btn_check_default') ,whiteBtnSize.width , whiteBtnSize.height/2, {ap = display.RIGHT_CENTER} )
	whiteBtn:addChild(whiteImage)
	whiteImage:setName("selectImage")
	whiteBtn:setOnClickScriptHandler(selectFunc)

	local blueBtn = display.newCheckBox(centerLayoutSize.width/2 , centerLayoutSize.height/4,{ n = _res('ui/pet/oneDel/pet_batch_bg_unselected') , s =  _res('ui/pet/oneDel/pet_batch_bg_selected')})
	centerLayout:addChild(blueBtn)
	blueBtn:setTag(3)
	blueBtn:setOnClickScriptHandler(selectFunc)
	local blueLabel = display.newLabel(whiteBtnSize.width/2 , whiteBtnSize.height/2 , fontWithColor(6 , {text = __('蓝色堕神')}))
	blueBtn:addChild(blueLabel)
	blueLabel:setName("label")

	local blueImage = display.newImageView(_res('ui/common/common_btn_check_default') ,whiteBtnSize.width , whiteBtnSize.height/2, {ap = display.RIGHT_CENTER} )
	blueBtn:addChild(blueImage)
	blueImage:setName("selectImage")


end

function PetDevelopScene.CreatePoolCellNode(cellParent)
	local finishImg = ui.image({img = RES_DICT.IMG_S_BG})
	cellParent:addList(finishImg):alignTo(nil, ui.cc)

	local petIcon = ui.image({img = _res(petMgr.GetPetEggHeadPathByPetEggId(210001))})
	cellParent:addList(petIcon):alignTo(nil, ui.cc)	

	local bgNode = ui.tButton({n = RES_DICT.POOL_N, s = RES_DICT.POOL_S, d = RES_DICT.POOL_D})
	bgNode:setTouchEnabled(false)
	cellParent:addList(bgNode):alignTo(nil, ui.cc)

	local size = bgNode:getContentSize()
	petIcon:setScale((size.width - 40) / petIcon:getContentSize().width)
	local poolNode = ui.layer({size = size, color = cc.r4b(0), enable = true})
	cellParent:addList(poolNode):alignTo(nil, ui.cc)

	local selectedImg = ui.image({img = RES_DICT.IMG_S_F})
	cellParent:addList(selectedImg):alignTo(nil, ui.cc)

	local lockedImg = ui.image({img = RES_DICT.LOCKED_IMG})
	cellParent:addList(lockedImg):alignTo(nil, ui.cc, {offsetY = 10})

	local leftTimeLabel = ui.label({fnt = FONT.D14, fontSize = 18, outline = '734441', text = "--"})
	cellParent:addList(leftTimeLabel):alignTo(nil, ui.cb, {offsetY = 13})		

	poolNode.updateUnLockedStatue = function(poolNode, visible)
		lockedImg:setVisible(not visible)
		poolNode:updateIconEnabled(visible)
	end

	poolNode.updateSelectedImgVisible = function(poolNode, visible)
		selectedImg:setVisible(visible)
	end

	poolNode.updateFinishStatue = function(poolNode, visible)
		finishImg:setVisible(visible)
		poolNode:updateIconChecked(visible)
	end

	poolNode.updateLeftTime = function(poolNode, str)
		leftTimeLabel:setVisible(str ~= nil)
		if str then
			leftTimeLabel:setString(str)
		end
	end

	poolNode.updatePetIcon = function(poolNode, petId)
		petIcon:setVisible(petId ~= nil)
		if petId then
			petIcon:setTexture(_res(petMgr.GetPetEggHeadPathByPetEggId(petId)))
		end
	end

	poolNode.setPoolEmpty = function(poolNode, isEmpty)
		poolNode:updateFinishStatue(false)
		poolNode:updateSelectedImgVisible(false)
		poolNode:updateLeftTime()
		poolNode:updatePetIcon()
		poolNode:updateIconChecked(false)
	end

	poolNode.updateIconChecked = function(poolNode, isChecked)
		bgNode:setChecked(isChecked)
	end
	poolNode.updateIconEnabled = function(poolNode, isEnabled)
		bgNode:setEnabled(isEnabled)
	end

	return poolNode
end

function PetDevelopScene:CreateDelView(sender)
	local layer = display.newLayer(display.cx , display.cy , {ap = display.CENTER, size = display.size })
	local swallowLayer = display.newButton(display.cx , display.cy , {ap = display.CENTER, size = display.size , cb = function()
		layer:runAction(cc.RemoveSelf:create())
	end })
	layer:addChild(swallowLayer)
	app.uiMgr:GetCurrentScene():AddDialog(layer)
	local delSize = cc.size(380, 180)
	local delLayer = display.newLayer(delSize.width/2 , delSize.height/2 ,{ap = display.CENTER_BOTTOM , size = delSize})
	local goodText = display.newImageView(_res("ui/common/commcon_bg_text.png") , delSize.width/2 , delSize.height/2 , {scale9 = true , size = delSize})
	delLayer:addChild(goodText)

	local tipHorn = display.newImageView(_res("ui/common/common_bg_tips_horn"), delSize.width/2 , 11 ,{ap= display.CENTER_BOTTOM })
	delLayer:addChild(tipHorn)
	tipHorn:setScaleY(-1)

	local singleDelBtn = display.newButton(delSize.width/4 , delSize.height/2 +24, {ap = display.CENTER , n = _res('ui/pet/oneDel/pet_btn_put_out_single')})
	delLayer:addChild(singleDelBtn)

	display.commonLabelParams(singleDelBtn , fontWithColor(8, {text =__('直接放生') , w = 150 , hAlign = display.TAC, ap = display.CENTER ,  offset = cc.p(0, -72 )}))

	local batchDelBtn = display.newButton(delSize.width/4 * 3 , delSize.height/2 +24, {ap = display.CENTER , n = _res('ui/pet/oneDel/pet_btn_put_out_batch')})
	delLayer:addChild(batchDelBtn)
	display.commonLabelParams(batchDelBtn , fontWithColor(8, {text =__('批量放生') , w = 150 , hAlign = display.TAC, ap = display.CENTER,  offset = cc.p(0, -72 )}))

	local pos = cc.p(sender:getPosition())
	local parent = sender:getParent()
	local worldPos = parent:convertToWorldSpace(pos)
	local delPos = layer:convertToNodeSpace(worldPos)
	delPos.y = delPos.y + 40
	layer:addChild(delLayer)
	delLayer:setPosition(delPos)
	local viewData = {
		layer = layer ,
		swallowLayer = swallowLayer ,
		singleDelBtn = singleDelBtn ,
		batchDelBtn = batchDelBtn ,
	}
	return viewData
end
function PetDevelopScene:GetDelPetsByQuality(qualityId)
	qualityId = qualityId
	local pets = app.gameMgr:GetUserInfo().pets
	local qualityPets = {}
	for id, petData	 in pairs(pets) do
		-- 去除装备和加锁的堕神
		if checkint(petData.isProtect) == 0  and  checkint(petData.playerCardId) <= 0  then
			local aQuality = app.petMgr.GetPetQualityByPetId(petData.petId)
			if qualityId == checkint(aQuality)  then
				qualityPets[#qualityPets+1] = id
			end
		end
	end
	return qualityPets
end
--[[
培养按钮回调
--]]
function PetDevelopScene:DevelopPetClickCallback(sender)
	PlayAudioByClickNormal()
	local id = self:GetCurrentSelectedPetId()
	AppFacade.GetInstance():DispatchObservers(EVENT_UPGRADE_PET, {id = id})
	-- GuideUtils.DispatchStepEvent()
end
--[[
排序按钮回调
--]]
function PetDevelopScene:PetDevelopSortClickCallback(sender)
	PlayAudioByClickNormal()
	self:ShowPetDevelopSortBoard(not self.viewData.petDevelopLayer.sortBoard:isVisible())
end
---------------------------------------------------
-- pet develop click handler end --
---------------------------------------------------

---------------------------------------------------
-- pet develop get set begin --
---------------------------------------------------
--[[
获取当前选中的堕神序号
--]]
function PetDevelopScene:GetCurrentSelectedPetIndex()
	return self.selectedPetIndex
end
--[[
获取当前选中的堕神信息
--]]
function PetDevelopScene:GetCurrentSelectedPetId()
	local idx = self:GetCurrentSelectedPetIndex()
	if nil == idx or nil == self.pets[idx] then
		return nil
	end
	return checkint(self.pets[idx].id)
end
---------------------------------------------------
-- pet develop get set end --
---------------------------------------------------

return PetDevelopScene
