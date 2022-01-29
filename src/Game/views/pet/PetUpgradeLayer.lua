--[[
堕神 升级 强化 洗炼 3tab 单独层
@params table {
	id 主体pet ref id
}
--]]
----xxx
local PetUpgradeLayer = class('PetUpgradeLayer', function()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.pet.PetUpgradeLayer'
	node:enableNodeEvents()
	return node
end)

------------ import ------------
---@type PetManager
local petMgr = AppFacade.GetInstance():GetManager("PetManager")
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
------------ import ------------

------------ define ------------
local TabModuleType = {
	LEVEL 			= 1, -- 升级
	BREAK 			= 2, -- 强化
	PROPERTY 		= 3, -- 洗炼
	EVOLUTION        = 4  -- 异化
}

local PROPERTY_DESC = {
	[1] = __('好惨，非酋附体啊...'),
	[2] = __('原谅色什么的最讨厌了。'),
	[3] = __('今天天气不错呢！'),
	[4] = __('离成功只差一步...'),
	[5] = __('传说！')
}

local tabInfo = {
	[TabModuleType.LEVEL] = {
		name = __('升级'), tag = TabModuleType.LEVEL, npath = 'ui/common/common_btn_sidebar_common.png', spath = 'ui/common/common_btn_sidebar_selected.png'
	},
	[TabModuleType.BREAK] = {
		name = __('强化'), tag = TabModuleType.BREAK, npath = 'ui/common/common_btn_sidebar_common.png', spath = 'ui/common/common_btn_sidebar_selected.png'
	},
	[TabModuleType.PROPERTY] = {
		name = __('炼化'), tag = TabModuleType.PROPERTY, npath = 'ui/common/common_btn_sidebar_common.png', spath = 'ui/common/common_btn_sidebar_selected.png'
	},
	[TabModuleType.EVOLUTION] = {
		name = __('异化'), tag = TabModuleType.EVOLUTION, npath = 'ui/common/common_btn_sidebar_common.png', spath = 'ui/common/common_btn_sidebar_selected.png'
	}

}

local PetSortRule = {
	DEFAULT 			= 0, -- 默认排序
	LOCK 				= 1, -- 是否上锁
	LEVEL 				= 2, -- 等级
	BREAK_LEVEL 		= 3, -- 强化等级
	QUALITY 			= 4  -- 品质
}

local randompFrontAmount = 5
local randompBehindAmount = 4
------------ define ------------

--[[
consturctor
--]]
function PetUpgradeLayer:ctor( ... )
	local args = unpack({...})

	self.mainId = args.id

	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	self.petId = checkint(mainPetData.petId)

	self.selectedTabIndex = nil
	self.mainLayers = {
		[TabModuleType.LEVEL] = nil,
		[TabModuleType.BREAK] = nil,
		[TabModuleType.PROPERTY] = nil,
		[TabModuleType.EVOLUTION] = nil
	}

	------------ level ------------
	self.levelPets = nil -- 保存的是pet ref id
	self.levelSelectedPets = {} -- 保存选中升级狗粮的序号
	------------ level ------------

	------------ break ------------
	self.breakPets = nil -- 保存的是pet ref id
	self.breakSelectedPets = {} -- 保存选中强化狗粮的序号
	------------ break ------------

	------------ prop ------------
	self.selectedPropIndex = nil -- 选择的需要洗炼的属性index
	self.universalNum = 0   -- 所用的万能堕神的数量

	self.animationUpdateHandler = nil
	self.dialLeftAnimationConf = {
		moveYPerFrame = -15,
		moveTimeLeft = 0,
		moveTimeRight = 0,
		targetIndexLeft = nil,
		targetIndexRight = nil
	}
	self.dialAnimationLeftStart = false
	self.dialMoveTimerLeft = 0
	self.moveYPerFrameLeft = 0
	self.dialAnimationRightStart = false
	self.dialMoveTimerRight = 0
	self.moveYPerFrameRight = 0
	self.playedReadyEndSoundEffect = false
	------------ prop ------------

	self:InitLayer()
	AppFacade.GetInstance():RegistObserver(EVENT_GOODS_COUNT_UPDATE, mvc.Observer.new(function (_, signal)
		local data = signal:GetBody()
		local recastCostConfig = petMgr.GetPropRecastCostConfig()
		self:RefreshPropRecastCost(recastCostConfig.num, gameMgr:GetAmountByGoodId(recastCostConfig.goodsId))
	end, self))
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化layer
--]]
function PetUpgradeLayer:InitLayer()

	------------ 计算layer大小 ------------
	-- 大背景图
	local bg = display.newImageView(_res('ui/pet/pet_train_bg.png'), 0, 0)
	local bgSize = bg:getContentSize()

	-- 侧页按钮
	local tabBtnIndentX = -95
	local tempSprite = display.newNSprite(_res('ui/common/common_btn_sidebar_common.png'), 0, 0)
	local tabBtnSize = cc.size(tempSprite:getContentSize().width + tabBtnIndentX, tempSprite:getContentSize().height)

	-- layer size
	local size = cc.size(bgSize.width + tabBtnSize.width, display.size.height )
	self:setContentSize(size)
	-- self:setBackgroundColor(cc.c4b(167, 67, 200, 100))
	------------ 计算layer大小 ------------

	-- 背景图
	display.commonUIParams(bg, {po = cc.p(
		bgSize.width * 0.5,
		size.height * 0.5
	)})
	self:addChild(bg, 5)

	-- 标题
	local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
	display.commonUIParams(titleBg, {po = cc.p(
		bgSize.width - titleBg:getContentSize().width * 0.5 - 140,
		bgSize.height - titleBg:getContentSize().height * 0.5 - 5
	)})
	display.commonLabelParams(titleBg,
		fontWithColor('1' ,{text = '测试', fontSize = 24, color = 'ffffff',offset = cc.p(0, -2)}))
    titleBg:setEnabled(false)
	bg:addChild(titleBg)

	-- 侧页按钮
	local tabBtns = {}
	local petConfig = petMgr.GetPetConfig(self.petId)
	for i,v in ipairs(tabInfo) do
		-- tab按钮
		local isTrue = true
		if v.tag == TabModuleType.EVOLUTION then  -- 判断堕神类型是否显示异化
			if checkint(petConfig.type) == checkint(PetType.BOSS)  then
				isTrue = true
			else
				isTrue = false
			end
		end
		if isTrue then
			local tabBtn = display.newCheckBox(0, 0, {n = _res(v.npath), s = _res(v.spath)})
			display.commonUIParams(tabBtn, {po = cc.p(
					bg:getPositionX() + bgSize.width * 0.5 + tabBtn:getContentSize().width * 0.5 + tabBtnIndentX,
					bg:getPositionY() + bgSize.height * 0.5 - 125 - (i - 1) * tabBtn:getContentSize().height
			)})
			tabBtn:setName('tabBtn'..i)
			tabBtn:setTag(v.tag)
			self:addChild(tabBtn, 4)
			tabBtn:setOnClickScriptHandler(handler(self, self.TabBtnClickCallback))

			tabBtns[v.tag] = tabBtn

			-- tab标签
			local tabLabel = display.newLabel(utils.getLocalCenter(tabBtn).x - 5, utils.getLocalCenter(tabBtn).y,
											  {ttf = true, font = TTF_GAME_FONT, text = v.name, fontSize = 22, color = '3c3c3c', ap = cc.p(0.5, 0)})--e0491a
			tabBtn:addChild(tabLabel)
			tabLabel:setTag(3)
			if checkint(v.tag)  == TabModuleType.EVOLUTION then
				if not  CommonUtils.CheckModuleIsExitByModuleId(JUMP_MODULE_DATA.SMELTING_PET) or not CommonUtils.GetModuleAvailable(MODULE_SWITCH.PET_EVOL) then
					tabBtn:setVisible(false)
				end
			end
		end
	end

	self.viewData = {
		bg = bg,
		titleBg = titleBg,
		tabBtns = tabBtns,
		levelLayer = nil,
		breakLayer = nil,
		propLayer = nil,
	}
end
--[[
初始化升级层
--]]
function PetUpgradeLayer:InitLevelLayer()
	local size = self.viewData.bg:getContentSize()
	local petConfig = petMgr.GetPetConfig(self.petId)
	local mainPetData = gameMgr:GetPetDataById(self.mainId)

	-- 基础layer
	local levelLayer = display.newLayer(size.width * 0.5, display.size.height * 0.5 ,
			{size = size, ap = cc.p(0.5, 0.5)})
	levelLayer:setName('levelLayer')	
	self:addChild(levelLayer, 10)
	-- levelLayer:setBackgroundColor(cc.c4b(255, 0, 0, 20))

	------------ 右侧列表 ------------
	local titleBgPos = cc.p(
		self.viewData.titleBg:getPositionX(),
		self.viewData.titleBg:getPositionY()
	)

	-- 列表
	local gridViewBgSize = cc.size(330, 485-80)
	local gridViewBg = display.newImageView(_res('ui/common/common_bg_goods.png'), 0, 0,
		{size = gridViewBgSize, scale9 = true})
	display.commonUIParams(gridViewBg, {po = cc.p(
		titleBgPos.x,
		titleBgPos.y - self.viewData.titleBg:getContentSize().height * 0.5 - 60 - gridViewBgSize.height * 0.5
	)})
	levelLayer:addChild(gridViewBg)

	local gridViewSize = cc.size(gridViewBgSize.width, gridViewBgSize.height -10)
	local gridPerLine = 3
	local cellSize = cc.size(gridViewSize.width / gridPerLine, gridViewSize.width / gridPerLine  )
	local gridView = CGridView:create(gridViewSize)
	gridView:setName('levelGridView')
	gridView:setAnchorPoint(cc.p(0.5, 0.5))
	gridView:setPosition(cc.p(gridViewBg:getPositionX(), gridViewBg:getPositionY()))
	levelLayer:addChild(gridView, 5)
	-- gridView:setBackgroundColor(cc.c4b(255, 128, 0, 128))

	gridView:setCountOfCell(0)
	gridView:setColumns(gridPerLine)
	gridView:setSizeOfCell(cellSize)
	gridView:setAutoRelocate(false)
	gridView:setDataSourceAdapterScriptHandler(handler(self, self.LevelGridViewDataAdapter))

	local oneKeyBtn = display.newButton(gridViewBg:getPositionX() , 67, {n = _res('ui/common/common_btn_orange.png'), cb = handler(self, self.OneKeyLevelPetLevelClickCallback)})
	oneKeyBtn:setName('oneKeyBtn')
	display.commonLabelParams(oneKeyBtn, fontWithColor('14', {text = __('一键升级')}))
	levelLayer:addChild(oneKeyBtn, 5)
	-- 排序按钮
	local sortBtn = display.newButton(0, 0, {
		n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'),
		cb = handler(self, self.LevelPetSortClickCallback)
	})
	display.commonUIParams(sortBtn, {po = cc.p(
		gridViewBg:getPositionX() + gridViewBgSize.width * 0.5 - sortBtn:getContentSize().width * 0.5,
		gridViewBg:getPositionY() + gridViewBgSize.height * 0.5 + sortBtn:getContentSize().height * 0.5 + 5
	)})
	display.commonLabelParams(sortBtn, fontWithColor('18', {text = __('排序')}))
	levelLayer:addChild(sortBtn, 5)

	local sortBoard = require('common.CommonSortBoard').new({
		targetNode = sortBtn,
		sortRules = {
			-- {sortType = PetSortRule.LOCK, sortDescr = __('上锁'), callbackSignal = 'LEVEL_SORT_PET', defaultSort = SortOrder.DESC},
			{sortType = PetSortRule.QUALITY, sortDescr = __('品质'), callbackSignal = 'LEVEL_SORT_PET', defaultSort = SortOrder.DESC},
			{sortType = PetSortRule.LEVEL, sortDescr = __('等级'), callbackSignal = 'LEVEL_SORT_PET', defaultSort = SortOrder.DESC},
			{sortType = PetSortRule.BREAK_LEVEL, sortDescr = __('强化'), callbackSignal = 'LEVEL_SORT_PET', defaultSort = SortOrder.DESC},
		}
	})
	display.commonUIParams(sortBoard, {ap = cc.p(0.5, 1), po = (
		self:convertToNodeSpace(sortBtn:getParent():convertToWorldSpace(cc.p(sortBtn:getPositionX(), sortBtn:getPositionY() - sortBtn:getContentSize().height * 0.5)))
	)})
	self:addChild(sortBoard, 999)
	sortBoard:setVisible(false)

	-- 数量标签
	local petAmountLabel = display.newLabel(0, 0, fontWithColor('6', {text = '堕神数量:99/100'}))
	display.commonUIParams(petAmountLabel, {ap = cc.p(0, 0), po = cc.p(
		gridViewBg:getPositionX() - gridViewBgSize.width * 0.5,
		gridViewBg:getPositionY() + gridViewBgSize.height * 0.5
	)})
	-- levelLayer:addChild(petAmountLabel, 5)
	------------ 右侧列表 ------------

	------------ 左侧盘子 ------------
	-- 盘子底
	local plateBg = display.newImageView(_res('ui/pet/pet_level_bg.png'), 0, 0)
	display.commonUIParams(plateBg, {po = cc.p(
		445,
		plateBg:getContentSize().height * 0.5 + 95
	)})
	levelLayer:addChild(plateBg, 5)

	local plateBgPos = cc.p(plateBg:getPositionX(), plateBg:getPositionY())

	-- 升级按钮
	local levelBtn = display.newButton(0, 0, {scale9 = true ,n = _res('ui/common/common_btn_orange.png'), cb = handler(self, self.LevelPetLevelClickCallback)})
	levelBtn:setName('levelBtn')
	display.commonUIParams(levelBtn, {po = cc.p(
		plateBgPos.x,
		57
	)})
	display.commonLabelParams(levelBtn, fontWithColor('14', {text = __('升级') , padingW = 20}))
	levelLayer:addChild(levelBtn, 5)

	--local levelLabelSize = display.getLabelContentSize(levelBtn:getLabel())
	--local levelBtnSize = levelBtn:getContentSize()
	--levelBtn:setContentSize(cc.size(levelLabelSize.width+10 , levelBtnSize.height ) )

	-- 中间小人
	local dynamicAvatar = AssetsUtils.GetCartoonNode(petMgr.GetPetDrawIdByPetId(self.petId))
	display.commonUIParams(dynamicAvatar, {ap = cc.p(0.5, 0), po = cc.p(
		plateBgPos.x,
		plateBgPos.y - 95
	)})
	dynamicAvatar:setScale(0.7)
	levelLayer:addChild(dynamicAvatar, 10)

	local avatarBottomPos = cc.p(dynamicAvatar:getPositionX(), dynamicAvatar:getPositionY())

	-- 名字
	local nameLabel = display.newLabel(0, 0, fontWithColor('4', {text = petConfig.name}))
	display.commonUIParams(nameLabel, {po = cc.p(
		avatarBottomPos.x,
		avatarBottomPos.y - display.getLabelContentSize(nameLabel).height * 0.5
	)})
	levelLayer:addChild(nameLabel, 10)

	-- 经验槽
	local curValue, maxValue, curStr, maxStr = self:GetExpBarParams(checkint(mainPetData.level), checkint(mainPetData.exp))

	local expBar = CProgressBar:create(_res('ui/pet/card_preview_ico_loading_fragment_not.png'))
	expBar:setBackgroundImage(_res('ui/pet/card_preview_bg_loading_fragment.png'))
	expBar:setDirection(eProgressBarDirectionLeftToRight)
	expBar:setPosition(cc.p(
		avatarBottomPos.x,
		nameLabel:getPositionY() - display.getLabelContentSize(nameLabel).height * 0.5 - expBar:getContentSize().height * 0.5 - 5
	))
	expBar:setScaleX(2)
	if maxValue < 0 then
		maxValue = 100
	end
	expBar:setMaxValue(maxValue)
	if curValue < 0 then
		curValue = 100
	end
	expBar:setValue(curValue)
	levelLayer:addChild(expBar, 10)

	local expLabel = nil
	if isElexSdk() then
		expLabel  = display.newLabel(0,0 , fontWithColor(14, {text = curStr .. '/' .. maxStr , reqW = 240  }))
	else
		expLabel	= CLabelBMFont:create(
			curStr .. '/' .. maxStr,
			'font/small/common_text_num.fnt'
		)
	end

	expLabel:setBMFontSize(20)
	expLabel:setAnchorPoint(cc.p(0.5, 0.5))
	--expLabel:setPosition(utils.getLocalCenter(expBar))
	expLabel:setPosition(cc.p(
			avatarBottomPos.x,
			nameLabel:getPositionY() - display.getLabelContentSize(nameLabel).height * 0.5 - expBar:getContentSize().height * 0.5 - 5
	))
	levelLayer:addChild(expLabel, 11)
	-- 等级
	local curLevelLabel = display.newLabel(0, 0, fontWithColor('5', {text = string.format(__('等级%d'), checkint(mainPetData.level))}))
	display.commonUIParams(curLevelLabel, {po = cc.p(
		avatarBottomPos.x,
		expBar:getPositionY() - expBar:getContentSize().height * 0.5 - 20
	)})
	levelLayer:addChild(curLevelLabel, 10)

	-- 狗粮槽
	local materialTotalAmount = petMgr.GetPetLevelUpMaxMaterialAmount()
	local radius = plateBg:getContentSize().width * 0.475
	local materialSlotAngle = {
		[1] = 45,
		[2] = 15,
		[3] = -15,
		[4] = -45,
		[5] = -135,
		[6] = -165,
		[7] = 165,
		[8] = 135
	}
	local materialBtns = {}
	--[[
	{
		{slotNode = nil, petNode = nil},
		{slotNode = nil, petNode = nil},
		...
	}
	--]]

	for i = 1, materialTotalAmount do
		local angle = materialSlotAngle[i]
		local materialSlotBg = display.newButton(0, 0, {n = _res('ui/pet/pet_level_bg_goods_selected.png'), cb = handler(self, self.LevelMaterialBtnClickCallback)})
		display.commonUIParams(materialSlotBg, {po = cc.p(
			plateBgPos.x + math.cos(math.rad(angle)) * radius,
			plateBgPos.y + math.sin(math.rad(angle)) * radius
		)})
		-- display.commonLabelParams(materialSlotBg, fontWithColor('5', {text = i}))
		levelLayer:addChild(materialSlotBg, 20)
		materialSlotBg:setTag(i)

		materialBtns[i] = {slotNode = materialSlotBg, petNode = nil}
	end
	------------ 左侧盘子 ------------

	------------ 狗粮全空状态 ------------
	-- 小人
	local emptyGodScale = 0.65
	local petEmptyGod = AssetsUtils.GetCartoonNode(3, gridViewBg:getPositionX(), gridViewBg:getPositionY())
	petEmptyGod:setScale(emptyGodScale)
	levelLayer:addChild(petEmptyGod, 10)

	local petEmptyLabel = display.newLabel(
		petEmptyGod:getPositionX(),
		petEmptyGod:getPositionY() - 424 * 0.5 * emptyGodScale - 40,
		fontWithColor('14', {text = __('没有多余的堕神')}))
	levelLayer:addChild(petEmptyLabel, 10)
	------------ 狗粮全空状态 ------------

	self.viewData.levelLayer = {
		------------ view nodes ------------
		root = levelLayer,
		gridView = gridView,
		sortBtn = sortBtn,
		materialBtns = materialBtns,
		expBar = expBar,
		expLabel = expLabel,
		nextLevelIcon = nextLevelIcon,
		nextLevelLabel = nextLevelLabel,
		curLevelLabel = curLevelLabel,
		sortBoard = sortBoard,
		levelUpgradeSpine = nil,
		dynamicAvatar = dynamicAvatar,
		------------ ui data ------------
		avatarBottomPos = avatarBottomPos,
		levelLabelPosY = curLevelLabel:getPositionY(),
		------------ layer handler ------------
		ShowNoPetMaterial = function (no)
			petEmptyGod:setVisible(no)
			petEmptyLabel:setVisible(no)

			gridViewBg:setVisible(not no)
			gridView:setVisible(not no)
			sortBtn:setVisible(not no)
		end
	}

	self.mainLayers[TabModuleType.LEVEL] = self.viewData.levelLayer
end
--[[
	初始化异化界面
--]]
function PetUpgradeLayer:InitEvolutionLayer()
	local size = self.viewData.bg:getContentSize()
	--local petConfig = petMgr.GetPetConfig(self.petId)
	--local mainPetData = gameMgr:GetPetDataById(self.mainId)

	-- 基础layer
	local evoltionLayer = display.newLayer(size.width * 0.5, display.size.height * 0.5 ,
										{size = size, ap = cc.p(0.5, 0.5) ,color1 = cc.r4b()})
	evoltionLayer:setName('evoltionLayer')

	local leftSize = cc.size(680,size.height )
	local leftLayout = display.newLayer(100, 0 ,{ap =display.LEFT_BOTTOM , size = leftSize , color1 = cc.r4b()})
	evoltionLayer:addChild(leftLayout)
	-- 异化按钮
	local evoltionBtn = display.newButton(leftSize.width/2,  55 , { ap = display.CENTER ,  n = _res('ui/common/common_btn_orange') , cb =  handler( self , self.EvoltionClickHandler)})
	display.commonLabelParams(evoltionBtn , fontWithColor('14',{text = __('异化')}))
	leftLayout:addChild(evoltionBtn)

	local evoltionBtnSize = evoltionBtn:getContentSize()
	-- 异化花费的金币
	local costGoldLabel =   display.newRichLabel(evoltionBtnSize.width/2 , 5, {ap = display.CENTER_TOP , r = true , c = {
		fontWithColor('14',{text ="1111"})
	}})
	costGoldLabel:setVisible(false)
	evoltionBtn:addChild(costGoldLabel)

	local evoltionBg = display.newImageView(_res('ui/pet/evoltion/pet_evolution_bg') )
	local evoltionBgSize = evoltionBg:getContentSize()
	local evoltionLayout = display.newLayer(leftSize.width/2 - 35, 95, {ap = display.CENTER_BOTTOM, size = evoltionBgSize, color1 = cc.r4b()})
	leftLayout:addChild(evoltionLayout)
	evoltionBg:setPosition(cc.p(evoltionBgSize.width/2, evoltionBgSize.height/2))
	evoltionLayout:addChild(evoltionBg)
	-- 消耗道具的layout
	local costGoodSize = cc.size(106, 128)
	local costGoodLayout = display.newLayer(63, 295 , {ap = display.CENTER , color1 = cc.r4b() , size = costGoodSize  })
	evoltionLayout:addChild(costGoodLayout)

	local costGoodsLabel = display.newLabel(costGoodSize.width/2 , 12 , fontWithColor('14',{text = '3/4'}))
	costGoodLayout:addChild(costGoodsLabel)

	local goodNode = require("common.GoodNode").new({id = DIAMOND_ID, showAmount = false})
	goodNode:setPosition(costGoodSize.width/2 , costGoodSize.height/2+2)
	display.commonUIParams(goodNode ,{animate = false ,  cb = function()
									  uiMgr:AddDialog('common.GainPopup', { goodsId = EVOLUTION_STONE_ID})
	end})
	goodNode:setScale(0.8)
	goodNode:setAnchorPoint(display.CENTER)
	costGoodLayout:addChild(goodNode)

	local attrTable  = {
		{name = __('品级提升') },
		{name = __('强化上限') },
		{name = __('本命属性') }
	}


	local attrOneSize = cc.size(417,43)
	local attrLayout = display.newLayer(evoltionBgSize.width - 257, 23 , {ap = display.CENTER_BOTTOM,  size = cc.size(attrOneSize.width , attrOneSize.height * 3)  ,color1 = cc.r4b() })
	evoltionLayout:addChild(attrLayout)



	local attrLabelTable = {}
	for i = 1, #attrTable do
		local  attrOneLayout = display.newLayer(attrOneSize.width/2,attrOneSize.height * ( (3-i)+0.5 ) , {ap = display.CENTER, color1 = cc.r4b() , size = attrOneSize })
		attrLayout:addChild(attrOneLayout)
		local oneImage = display.newImageView(_res('ui/pet/pet_promote_bg_list') ,attrOneSize.width/2 , attrOneSize.height/2)
		attrOneLayout:addChild(oneImage)

		local nameLabel = display.newLabel(10,attrOneSize.height/2, fontWithColor( '5' , {text = attrTable[i].name  , ap = display.LEFT_CENTER}) )
		attrOneLayout:addChild(nameLabel)

		local swordImage = display.newImageView(_res('ui/pet/card_skill_ico_sword') ,300  , attrOneSize.height/2 ,{ap = display.CENTER})
		attrOneLayout:addChild(swordImage)
		attrLabelTable[#attrLabelTable+1] = {}
		if i ==1 then
			local curLabel = display.newLabel(attrOneSize.width/2 + 40 ,attrOneSize.height/2 ,  fontWithColor('10', {color = '#82539f', fontSize = 22,ap = display.RIGHT_CENTER , text =__('史 诗') }) )
			attrOneLayout:addChild(curLabel)


			local nextLabel = display.newLabel(attrOneSize.width - 20 ,attrOneSize.height/2 ,  fontWithColor('10', { color = '#b77606',fontSize = 22,ap = display.RIGHT_CENTER , text =__('传 说') }) )
			attrOneLayout:addChild(nextLabel)
			attrLabelTable[#attrLabelTable] = {curLabel  = curLabel , swordImage = swordImage, nextLabel = nextLabel }
		else
			local curLabel = display.newLabel(attrOneSize.width/2 + 40 ,attrOneSize.height/2 ,  fontWithColor('14', { fontSize = 22,ap = display.RIGHT_CENTER , text =__('史诗') }) )
			attrOneLayout:addChild(curLabel)

			local nextLabel = display.newLabel(attrOneSize.width - 20 ,attrOneSize.height/2 ,  fontWithColor('14', { fontSize = 22,ap = display.RIGHT_CENTER , text =__('传说') }) )
			attrOneLayout:addChild(nextLabel)
			attrLabelTable[#attrLabelTable] = {curLabel  = curLabel,swordImage = swordImage , nextLabel = nextLabel }
		end
	end

	local petSize  = cc.size(375,375)
	local petLayout = display.newLayer(358, evoltionBgSize.height , {ap = display.CENTER_TOP , size = petSize , color1 = cc.r4b()})
	evoltionLayout:addChild(petLayout)


	local petNode = require("common.PetHeadNode").new({id = self.mainId ,showBaseState = true ,showLockState = true })
	petNode:setPosition(cc.p(petSize.width/2 , petSize.height/2))
	petLayout:addChild(petNode , 20)





	local costExplainLabel = display.newLabel(costGoodSize.width/2 , costGoodSize.height +20,fontWithColor('10', { color = "#ddcd93" ,display.CENTER_BOTTOM ,w =  120 ,hAlign = display.TAC,text = __('需要材料')}) )
	costGoodLayout:addChild(costExplainLabel)


	local rightSize = cc.size(345,550)

	local rightLayout = display.newLayer(size.width -94, size.height - 45 ,{ap = display.RIGHT_TOP, size = rightSize , color1 = cc.r4b()})
	evoltionLayer:addChild(rightLayout)

	local petImage = AssetsUtils.GetCartoonNode(petMgr.GetPetDrawIdByPetId(self.petId))
	petImage:setPosition(rightSize.width/2 , 320)
	petImage:setAnchorPoint(display.CENTER_BOTTOM)
	rightLayout:addChild(petImage)
	petImage:setScale(0.5)

	local petName = display.newButton(rightSize.width/2 , 285, {n = _res('ui/pet/evoltion/pet_evolution_bg_name') ,enable  = false } )
	display.commonLabelParams(petName, fontWithColor(19))
	rightLayout:addChild(petName)
	
	local thisLiftSize = cc.size(325,233)
	local thisLiftBg = display.newImageView(_res('ui/common/common_bg_goods.png'), thisLiftSize.width/2,thisLiftSize.height/2,
												{ap = display.CENTER , scale9 = true , size = thisLiftSize  })
	local thisLiftLayout = display.newLayer(rightSize.width/2 , 10 , {ap = display.CENTER_BOTTOM, size = thisLiftSize })
	thisLiftLayout:addChild(thisLiftBg)
	rightLayout:addChild(thisLiftLayout)

	local titleBtn = display.newButton(thisLiftSize.width/2 , thisLiftSize.height - 15 , { n  = _res('ui/common/common_title_5') , enable = false,ap = display.CENTER_TOP , scale9 = true  })
	display.commonLabelParams(titleBtn, fontWithColor('5', {text = __('本命飨灵') , paddingW = 20  } ))
	thisLiftLayout:addChild(titleBtn)

	local listSize = cc.size(190,178)
	local  exclusiveCardList= CListView:create(listSize)
	exclusiveCardList:setDirection(eScrollViewDirectionVertical)
	exclusiveCardList:setAnchorPoint(display.CENTER_TOP)
	exclusiveCardList:setPosition(cc.p(thisLiftSize.width/2, thisLiftSize.height - 60 ))
	thisLiftLayout:addChild(exclusiveCardList,10)

	self:addChild(evoltionLayer, 10)
	self.viewData.evoltionLayer ={
		root = evoltionLayer ,
		------------ leftLayout---------------------------------
		goodNode          = goodNode,
		costGoldLabel     = costGoldLabel,
		evoltionBtn       = evoltionBtn,
		costGoodsLabel    = costGoodsLabel,
		attrLabelTable    = attrLabelTable,
		petNode           = petNode,
		costExplainLabel  = costExplainLabel,
		attrOneSize       = attrOneSize,
		petLayout         = petLayout ,
		petSize           = petSize ,

		------------ rightLayout---------------------------------
		petImage          = petImage,
		petName           = petName,
		costGoodLayout    = costGoodLayout ,
		exclusiveCardList = exclusiveCardList

	}
	self.mainLayers[TabModuleType.EVOLUTION] = self.viewData.evoltionLayer
end

--[[
初始化强化层
--]]
function PetUpgradeLayer:InitBreakLayer()
	local size = self.viewData.bg:getContentSize()
	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	-- 基础layer
	local breakLayer = display.newLayer(size.width * 0.5, display.size.height * 0.5 ,
		{size = size, ap = cc.p(0.5, 0.5)})
	breakLayer:setName('breakLayer')
	self:addChild(breakLayer, 10)
	-- breakLayer:setBackgroundColor(cc.c4b(0, 255, 0, 20))

	------------ 右侧列表 ------------
	local titleBgPos = cc.p(
		self.viewData.titleBg:getPositionX(),
		self.viewData.titleBg:getPositionY()
	)

	-- 列表
	local gridViewBgSize = cc.size(330, 538)
	local gridViewBg = display.newImageView(_res('ui/common/common_bg_goods.png'), 0, 0,
		{size = gridViewBgSize, scale9 = true})
	display.commonUIParams(gridViewBg, {po = cc.p(
		titleBgPos.x,
		titleBgPos.y - self.viewData.titleBg:getContentSize().height * 0.5 - 6 - gridViewBgSize.height * 0.5
	)})
	breakLayer:addChild(gridViewBg)

	local gridViewSize = cc.size(gridViewBgSize.width, gridViewBgSize.height)
	local gridPerLine = 3
	local cellSize = cc.size(gridViewSize.width / gridPerLine, gridViewSize.width / gridPerLine)
	local gridView = CGridView:create(gridViewSize)
	gridView:setName('breakGridView')
	gridView:setAnchorPoint(cc.p(0.5, 0.5))
	gridView:setPosition(cc.p(gridViewBg:getPositionX(), gridViewBg:getPositionY()))
	breakLayer:addChild(gridView, 5)
	-- gridView:setBackgroundColor(cc.c4b(255, 128, 0, 128))

	gridView:setCountOfCell(0)
	gridView:setColumns(gridPerLine)
	gridView:setSizeOfCell(cellSize)
	gridView:setAutoRelocate(false)
	gridView:setDataSourceAdapterScriptHandler(handler(self, self.BreakGridViewDataAdapter))

	-- 排序按钮
	local sortBtn = display.newButton(0, 0, {
		n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'),
		cb = handler(self, self.BreakPetSortClickCallback)
	})
	display.commonUIParams(sortBtn, {po = cc.p(
		gridViewBg:getPositionX() + gridViewBgSize.width * 0.5 - sortBtn:getContentSize().width * 0.5,
		gridViewBg:getPositionY() + gridViewBgSize.height * 0.5 + sortBtn:getContentSize().height * 0.5 + 5
	)})
	display.commonLabelParams(sortBtn, fontWithColor('18', {text = __('排序')}))
	breakLayer:addChild(sortBtn, 5)
	sortBtn:setVisible(false)

	local sortBoard = require('common.CommonSortBoard').new({
		targetNode = sortBtn,
		sortRules = {
			{sortType = PetSortRule.LOCK, sortDescr = __('上锁'), callbackSignal = 'BREAK_SORT_PET', defaultSort = SortOrder.DESC},
			{sortType = PetSortRule.LEVEL, sortDescr = __('等级'), callbackSignal = 'BREAK_SORT_PET', defaultSort = SortOrder.DESC},
			{sortType = PetSortRule.BREAK_LEVEL, sortDescr = __('强化'), callbackSignal = 'BREAK_SORT_PET', defaultSort = SortOrder.DESC}
		}
	})
	display.commonUIParams(sortBoard, {ap = cc.p(0.5, 1), po = (
		self:convertToNodeSpace(sortBtn:getParent():convertToWorldSpace(cc.p(sortBtn:getPositionX(), sortBtn:getPositionY() - sortBtn:getContentSize().height * 0.5)))
	)})
	self:addChild(sortBoard, 999)
	sortBoard:setVisible(false)

	-- 数量标签
	local petAmountLabel = display.newLabel(0, 0, fontWithColor('6', {text = '堕神数量:99/100'}))
	display.commonUIParams(petAmountLabel, {ap = cc.p(0, 0), po = cc.p(
		gridViewBg:getPositionX() - gridViewBgSize.width * 0.5,
		gridViewBg:getPositionY() + gridViewBgSize.height * 0.5
	)})
	-- breakLayer:addChild(petAmountLabel, 5)
	------------ 右侧列表 ------------

	------------ 狗粮全空状态 ------------
	-- 小人
	local emptyGodScale = 0.65
	local petEmptyGod = AssetsUtils.GetCartoonNode(3, gridViewBg:getPositionX(), gridViewBg:getPositionY())
	petEmptyGod:setScale(emptyGodScale)
	breakLayer:addChild(petEmptyGod, 10)

	local petEmptyLabel = display.newLabel(
		petEmptyGod:getPositionX(),
		petEmptyGod:getPositionY() - 424 * 0.5 * emptyGodScale - 40,
		fontWithColor('14', {text = __('没有多余的同类堕神')}))
	breakLayer:addChild(petEmptyLabel, 10)
	------------ 狗粮全空状态 ------------

	------------ 左侧展示 ------------
	-- 强化底板
	local breakBg = display.newImageView(_res('ui/pet/pet_promote_bg.png'), 0, 0)
	display.commonUIParams(breakBg, {po = cc.p(
		445,
		breakBg:getContentSize().height * 0.5 + 95
	)})
	breakLayer:addChild(breakBg, 5)

	local breakBgPos = cc.p(breakBg:getPositionX(), breakBg:getPositionY())

	-- 强化按钮
	local breakBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png'), cb = handler(self, self.BreakPetBreakClickCallback)})
	breakBtn:setName('breakBtn')
	display.commonUIParams(breakBtn, {po = cc.p(
		breakBgPos.x,
		57
	)})
	display.commonLabelParams(breakBtn, fontWithColor('14', {text = __('强化')}))
	breakLayer:addChild(breakBtn, 5)

	-- 底坐标
	local breakBottomY = breakBgPos.y + breakBg:getContentSize().height * 0.5 - 50

	-- 中间小人
	local dynamicAvatar = AssetsUtils.GetCartoonNode(petMgr.GetPetDrawIdByPetId(self.petId))
	display.commonUIParams(dynamicAvatar, {ap = cc.p(0.5, 0), po = cc.p(
		breakBgPos.x - breakBg:getContentSize().width * 0.23,
		breakBottomY + 25
	)})
	dynamicAvatar:setScale(0.6)
	breakLayer:addChild(dynamicAvatar, 10)


	-- 小人名字强化信息
	--local mainPetBreakLabel = display.newLabel(0, 0, fontWithColor('18', {text = '测试 +8'}))
	--display.commonUIParams(mainPetBreakLabel, {po = cc.p(
	--	dynamicAvatar:getPositionX(),
	--	breakBottomY + 10
	--)})
	--breakLayer:addChild(mainPetBreakLabel, 10)
	-- mainPetBreakLabel:setVisible(false)
	-- 箭头
	local arrow = display.newNSprite(_res('ui/pet/card_skill_ico_sword_2.png'), 0, 0)
	display.commonUIParams(arrow, {po = cc.p(
		breakBgPos.x,
		breakBottomY + arrow:getContentSize().height * 0.5 + 55
	)})
	breakLayer:addChild(arrow, 20)

	-- 狗粮槽
	local materialBtns = {}
	--[[
	{
		{slotNode = nil, petNode = nil, nameNode = nil},
		{slotNode = nil, petNode = nil, nameNode = nil},
		...
	}
	--]]

	local breakMaterialPath = string.format('ui/common/common_frame_goods_%d.png', petMgr.GetPetQualityByPetId(self.petId))


	local breakMaterialSize = cc.size(216, 155 )
	local breakMaterialLayout = display.newLayer(breakBgPos.x + 20 ,
												 arrow:getPositionY() -80   , {size = breakMaterialSize , color1 = cc.r4b()  })
	breakLayer:addChild(breakMaterialLayout,10)

	local titleBtn = display.newButton(breakMaterialSize.width/2 ,breakMaterialSize.height , { ap = display.CENTER_TOP , n = _res('ui/union/party/party/common_bg_title_4') ,enable = true ,scale9 = true   })
	breakMaterialLayout:addChild(titleBtn)
	display.commonLabelParams(titleBtn , fontWithColor('10', {color = '#ffffff', text = __('需要材料'), paddingW = 25  }))




	local breakMaterialBg = display.newButton(0, 0, {n = _res(breakMaterialPath), cb = handler(self, self.BreakMaterialBtnClickCallback)})
	display.commonUIParams(breakMaterialBg, {po = cc.p(
			breakMaterialSize.width * 1/4   ,
			breakMaterialSize.height/2 - 10
	)})
	breakMaterialLayout:addChild(breakMaterialBg, 10)
	breakMaterialBg:setTag(1)
	breakMaterialBg:setScale(0.9)



	local materialLabel = display.newButton(breakMaterialSize.width * 1/4   , breakMaterialSize.height/2 - 42 ,
		{ n = _res('ui/pet/pet_promote_bg_number_1') })
	breakMaterialLayout:addChild(materialLabel, 100)
	materialLabel:setScale(1.05)
	
	


	-- 消耗道具
	local consumeGoodNode = require("common.GoodNode").new({goodsId = EVOLUTION_STONE_ID })
	breakMaterialLayout:addChild(consumeGoodNode, 11)
	consumeGoodNode:setEnabled(true)
	display.commonUIParams(consumeGoodNode ,{enable = true,animate = false  , cb = function(sender)
		uiMgr:AddDialog("common.GainPopup", {goodId = EVOLUTION_STONE_ID})
	end})
	consumeGoodNode:setPosition(cc.p(breakMaterialSize.width * 3/4   , breakMaterialSize.height/2 - 10))
	consumeGoodNode:setScale(0.9)

	local consumeLabel = display.newButton(breakMaterialSize.width * 3/4   , breakMaterialSize.height/2 - 42 ,
											{ n = _res('ui/pet/pet_promote_bg_number_1') })
	breakMaterialLayout:addChild(consumeLabel, 100)
	consumeLabel:setScale(1.05)


	-- 狗粮名字强化信息
	local materialBreakLabel = display.newLabel(0, 0, fontWithColor('18', {text = '测试 +8'}))
	display.commonUIParams(materialBreakLabel, {po = cc.p(
			breakMaterialSize.width * 1/2   , 2
	)})
	breakMaterialLayout:addChild(materialBreakLabel, 10)
	materialBreakLabel:setVisible(false)





	materialBtns[1] = {slotNode = breakMaterialBg, petNode = nil, nameNode = materialBreakLabel}


  	--堕神性格
	local characterLabel = display.newLabel(0, 0, fontWithColor('15', {text = ' '}))
	display.commonUIParams(characterLabel, {po = cc.p(
		breakBgPos.x,
		breakBgPos.y + 50
	)})
	breakLayer:addChild(characterLabel, 9)
	characterLabel:setVisible(false)

	--强化成功率
	local probabilityLabel = display.newLabel(0, 0, fontWithColor('5', {fontSize = 20 , color = "ffffff",  text = ''}))
	--display.commonUIParams(probabilityLabel, {ap = cc.p(0.5, 0.5), po = cc.p(
	--	breakBgPos.x,
	--	breakBgPos.y + 50
	--)})
	display.commonUIParams(probabilityLabel, {ap = cc.p(0.5, 0.5), color = "ffffff" ,  po = cc.p(
			breakBgPos.x,
			breakBgPos.y - 190
	)})
	breakLayer:addChild(probabilityLabel, 5)


	-- 属性信息
	local petpNodes = {}
	--[[
	{
		{bgNode = nil, lockNode = nil, pNameNode = nil, pValueNode = nil, pChangeNode = nil, pValuePreviewNode = nil},
		{bgNode = nil, lockNode = nil, pNameNode = nil, pValueNode = nil, pChangeNode = nil, pValuePreviewNode = nil},
		...
	}
	--]]
	local levelSize = cc.size(415,41)
	local levelLayout = display.newLayer(breakBg:getPositionX(),breakBg:getPositionY() - breakBg:getContentSize().height * 0.5 + 202 + 0.5 * (41 + 2) -10 ,{ap = display.CENTER,   size =  levelSize , color1 = cc.r4b()})
	breakLayer:addChild(levelLayout, 10)

	local  breakName = display.newLabel(30 , levelSize.height/2 ,fontWithColor('5', {fontSize = 22,  ap = display.LEFT_CENTER ,text =  __('强化等级')}))
	levelLayout:addChild(breakName, 10)

	-- 十级以后显示能量
	local breakPowSize = cc.size(415, 80)

	local breakPowLayout =  display.newLayer(breakBg:getPositionX(),breakBg:getPositionY() - breakBg:getContentSize().height * 0.5 + 202 + 0.5 * (41 + 2) +10, {ap = display.CENTER_BOTTOM , size = breakPowSize } )
	breakLayer:addChild(breakPowLayout, 10)
	breakPowLayout:setName("breakPowLayout")
	local commonTip = display.newButton(45 , 55 , { n = _res('ui/common/common_btn_tips') , cb = function(sender)
		uiMgr:ShowInformationTipsBoard({targetNode = sender,  descr =__('Tips：每次强化失败会增加强化能量，当强化能量达到1000，下次强化必然成功。每次强化成功后强化能量归0。') , type =5} )
	end})
	breakPowLayout:addChild(commonTip)

	local powLabel = display.newRichLabel(65, 55 , {ap = display.LEFT_CENTER , r = true , c= {
		fontWithColor('10' , {text = "好好学习"})
	}})
	breakPowLayout:addChild(powLabel)

	local progressBarOne = CProgressBar:create(_res('ui/pet/pet_promote_bg_loading_2'))
	progressBarOne:setBackgroundImage(_res('ui/pet/pet_promote_bg_loading'))
	progressBarOne:setDirection(eProgressBarDirectionLeftToRight)
	progressBarOne:setAnchorPoint(display.LEFT_CENTER)
	progressBarOne:setPosition(30 , 20 )
	progressBarOne:setMaxValue(1000)
	progressBarOne:setValue(0)
	breakPowLayout:addChild(progressBarOne)
	local progressBarOneSize = progressBarOne:getContentSize()
	local progressLabel = display.newLabel(progressBarOneSize.width/2 ,progressBarOneSize.height/2 ,fontWithColor('14', { text = ""}))
	progressBarOne:addChild(progressLabel,100)

	breakPowLayout.progressBarOne = progressBarOne
	breakPowLayout.progressLabel = progressLabel
	breakPowLayout.powLabel = powLabel
	breakPowLayout:setVisible(false)

	local curBreakLevel = CLabelBMFont:create(
		    '20',
			petMgr.GetPetPropFontPath(1)
	)
	curBreakLevel:setBMFontSize(24)
	curBreakLevel:setAnchorPoint(cc.p(1, 0.5))
	curBreakLevel:setPosition(cc.p(
	276 , levelSize.height/2
	))
	levelLayout:addChild(curBreakLevel)
	curBreakLevel:setVisible(false)

	local levelSkillImage = display.newImageView(_res('ui/pet/card_skill_ico_sword.png') ,  282 , levelSize.height/2 , {ap = display.LEFT_CENTER})
	levelLayout:addChild(levelSkillImage)
	local nextBreakLevel = CLabelBMFont:create(
	'20',
	petMgr.GetPetPropFontPath(1)
	)
	nextBreakLevel:setBMFontSize(24)
	nextBreakLevel:setAnchorPoint(cc.p(0, 0.5))
	nextBreakLevel:setPosition(cc.p(
			325  , levelSize.height/2
	))
	levelLayout:addChild(nextBreakLevel)

	curBreakLevel:setVisible(false)
	nextBreakLevel:setVisible(false)
	levelSkillImage:setVisible(false)
	local  levelTable = { curBreakLevel = curBreakLevel , nextBreakLevel = nextBreakLevel , levelSkillImage = levelSkillImage   }
	--local


	local petpData = petMgr.GetPetAllFixedProps(self.mainId)
	local pAmount = #petpData
	for i,v in ipairs(petpData) do
		-- 属性背景
		local bgNode = display.newImageView(_res('ui/pet/pet_promote_bg_list.png'), 0, 0)
		local p = cc.p(
			breakBg:getPositionX(),
			breakBg:getPositionY() - breakBg:getContentSize().height * 0.5 + 202 - (i - 0.5) * (bgNode:getContentSize().height + 2) - 10
		)
		display.commonUIParams(bgNode, {po = p})
		breakLayer:addChild(bgNode, 10)

		-- 锁定背景
		local lockNode = display.newImageView(_res('ui/pet/pet_promote_bg_list_disabled.png'), 0, 0)
		display.commonUIParams(lockNode, {po = p})
		breakLayer:addChild(lockNode, 10)

		local lockLabel = display.newLabel(0, 0,
			fontWithColor('18', {text = string.format(__('堕神等级达到%d级解锁'), petMgr.GetPetPInfo()[i].unlockLevel) , reqW = 420}))
		display.commonUIParams(lockLabel, {po = utils.getLocalCenter(lockNode)})
		lockNode:addChild(lockLabel)

		local nodes = {
			bgNode = bgNode,
			lockNode = lockNode,
			pNameNode = nil, pValueNode = nil, pChangeNode = nil, pValuePreviewNode = nil
		}
		petpNodes[i] = nodes
	end
	------------ 左侧展示 ------------

	self.viewData.breakLayer = {
		------------ view nodes ------------
		root = breakLayer,
		breakMaterialSize = breakMaterialSize ,
		gridView = gridView,
		materialBtns = materialBtns,
		petpNodes = petpNodes,
		breakCostLabel = nil,
		breakCostIcon = nil,
		breakBtn = breakBtn,
		probabilityLabel = probabilityLabel,
		characterLabel = characterLabel,
		consumeGoodNode = consumeGoodNode ,
		consumeLabel   = consumeLabel ,
		breakMaterialLayout = breakMaterialLayout ,
		materialLabel = materialLabel ,
		sortBoard = sortBoard,
		levelTable = levelTable ,
		dynamicAvatar = dynamicAvatar,
		levelLayout   = levelLayout ,
		breakUpgradeSpine = nil,
		breakUpradeMessSpine = nil,
		breakUpFailSpine = nil,
		------------ ui data ------------
		------------ layer handler ------------
		ShowNoPetMaterial = function (no)
			petEmptyGod:setVisible(no)
			petEmptyLabel:setVisible(no)

			gridViewBg:setVisible(not no)
			gridView:setVisible(not no)
			-- sortBtn:setVisible(not no)
		end
	}

	self.mainLayers[TabModuleType.BREAK] = self.viewData.breakLayer
end
--[[
初始化洗炼层
--]]
function PetUpgradeLayer:InitPropLayer()
	local size = self.viewData.bg:getContentSize()

	-- 基础layer
	local propLayer = display.newLayer(size.width * 0.5, display.size.height * 0.5 ,
		{size = size, ap = cc.p(0.5, 0.5)})
	propLayer:setName('propLayer')
	self:addChild(propLayer, 10)
	-- propLayer:setBackgroundColor(cc.c4b(0, 0, 255, 20))

	local titleBgPos = cc.p(
		self.viewData.titleBg:getPositionX(),
		self.viewData.titleBg:getPositionY() - 90
	)

	------------ 右侧属性表 ------------
	--头像
	local petIcon = require('common.PetHeadNode').new({
		showBaseState = true,
		showLockState = true
	})
	petIcon:setScale(0.8)
	display.commonUIParams(petIcon, {po = cc.p(
		titleBgPos.x,
		titleBgPos.y + 10  )})
	propLayer:addChild(petIcon, 5)

	petIcon:RefreshUI({
		id = self.mainId
	})

	--性格
	local characterLabel = display.newLabel(0, 0, fontWithColor('15', {color = '4c4c4c', text = ' '}))
	display.commonUIParams(characterLabel, {ap = cc.p(0.5,1),po = cc.p(
		petIcon:getContentSize().width * 0.5,
		-2
	)})
	petIcon:addChild(characterLabel)

	local mainPetData = gameMgr:GetPetDataById(self.mainId)
 	local characterConfig = CommonUtils.GetConfig('pet', 'petCharacter', mainPetData.character)
 	local characterStr = string.format(__('性格:%s'), characterConfig.name)
 	characterLabel:setString(characterStr)

	-- 提示
	local hintLabel = display.newLabel(0, 0, fontWithColor('6', {text = __('选择一个需要洗炼的属性')}))
	display.commonUIParams(hintLabel, {po = cc.p(
		titleBgPos.x,
		titleBgPos.y - 75
	)})
	propLayer:addChild(hintLabel, 10)

	-- 列表
	local gridViewBgSize = cc.size(323, 375)
	local gridViewBg = display.newImageView(_res('ui/common/common_bg_goods.png'), 0, 0,
		{size = gridViewBgSize, scale9 = true})
	display.commonUIParams(gridViewBg, {po = cc.p(
		titleBgPos.x,
		hintLabel:getPositionY() - display.getLabelContentSize(hintLabel).height * 0.5 - 5 - gridViewBgSize.height * 0.5
	)})
	propLayer:addChild(gridViewBg, 5)

	local pBtns = {}
	--[[
	{
		{pBtnNode = nil, pNameNode = nil, pValueNode},
		{pBtnNode = nil, pNameNode = nil, pValueNode},
		{pBtnNode = nil, pNameNode = nil, pValueNode},
		...
	}
	--]]
	local pAmount = 4
	local cellSize = cc.size(gridViewBgSize.width, gridViewBgSize.height / pAmount)
	for i = 1, pAmount do
		local pBtn = display.newCheckBox(0, 0, {
			n = _res('ui/pet/pet_refresh_bg_list_attribute.png'),
			s = _res('ui/pet/pet_refresh_bg_list_attribute_selected.png'),
			d = _res('ui/pet/pet_refresh_bg_list_attribute_lock.png')
		})
		display.commonUIParams(pBtn, {po = cc.p(
			gridViewBg:getPositionX(),
			gridViewBg:getPositionY() + gridViewBgSize.height * 0.5 - (i - 0.5) * cellSize.height
		)})
		pBtn:setOnClickScriptHandler(handler(self, self.PropPBtnClickCallback))
		propLayer:addChild(pBtn, 10)
		pBtn:setTag(i)

		pBtns[i] = {
			pBtnNode = pBtn,
			pNameNode = nil,
			pValueNode = nil
		}
	end
	------------ 右侧属性表 ------------

	------------ 左侧转盘 ------------
	-- 转盘底盘
	local propDialBg = display.newImageView(_res('ui/pet/pet_refresh_bg.png'), 0, 0)
	display.commonUIParams(propDialBg, {po = cc.p(
		445,
		propDialBg:getContentSize().height * 0.5 + 95
	)})
	propLayer:addChild(propDialBg, 10)

	local propBgPos = cc.p(propDialBg:getPositionX(), propDialBg:getPositionY())

	local fixedPos = {
		leftCoverPos = cc.p(propBgPos.x - 128, propBgPos.y - 78),
		rightCoverPos = cc.p(propBgPos.x + 130, propBgPos.y - 78),
		dialLeftBottomY = nil,
		dialLeftTopY = nil,
		dialRightBottomY = nil,
		dialRightTopY = nil,
	}

	-- 遮罩
	local leftCover = display.newNSprite(_res('ui/pet/pet_refresh_ico_mask_front.png'), 0, 0)
	display.commonUIParams(leftCover, {po = cc.p(
		fixedPos.leftCoverPos.x,
		fixedPos.leftCoverPos.y
	)})
	propLayer:addChild(leftCover, 9)

	local rightCover = display.newNSprite(_res('ui/pet/pet_refresh_ico_mask_front.png'), 0, 0)
	display.commonUIParams(rightCover, {po = cc.p(
		fixedPos.rightCoverPos.x,
		fixedPos.rightCoverPos.y
	)})
	propLayer:addChild(rightCover, 9)

	-- 洗炼按钮
	local propBtn = display.newButton(0, 0, {
		n = _res('ui/common/common_btn_orange.png'), scale9 = true , cb = handler(self, self.PropRecastClickCallback)})
	propBtn:setName('propBtn')
	display.commonUIParams(propBtn, {po = cc.p(
		propBgPos.x,
		57
	)})
	display.commonLabelParams(propBtn, fontWithColor('14', {text = __('洗炼') , paddingW = 20}))
	propLayer:addChild(propBtn, 5)


	-- 屏蔽层按钮
	local skipDialBtn = display.newButton(0, 0, {size = display.size, animate = false, cb = function (sender)
		self:SkipDialAnimation()
	end})
	display.commonUIParams(skipDialBtn, {po = utils.getLocalCenter(self)})
	propLayer:addChild(skipDialBtn, 999)
	skipDialBtn:setVisible(false)

	-- 箭头
	local arrowR = display.newNSprite(_res('ui/pet/pet_refresh_ico_pointer.png'), 0, 0)
	display.commonUIParams(arrowR, {po = cc.p(
		fixedPos.rightCoverPos.x + 135,
		fixedPos.rightCoverPos.y + 5
	)})
	propLayer:addChild(arrowR, 10)

	local arrowL = display.newNSprite(_res('ui/pet/pet_refresh_ico_pointer.png'), 0, 0)
	display.commonUIParams(arrowL, {po = cc.p(
		fixedPos.leftCoverPos.x - 135,
		fixedPos.leftCoverPos.y + 5
	)})
	arrowL:setFlippedX(true)
	propLayer:addChild(arrowL, 10)

	-- 洗炼属性预览
	local propClipNode = cc.ClippingNode:create()
	propLayer:addChild(propClipNode, 4)

	-- local stencilLayer = display.newLayer(0, 0, {color = '#000000', size = cc.size(
	-- 	propDialBg:getContentSize().width,
	-- 	rightCover:getContentSize().height + 30
	-- )})
	-- stencilLayer:setOpacity(254)
	local stencilLayer = display.newImageView(_res('ui/guide/guide_ico_shape_3.png'), 0, 0)
	stencilLayer:setScaleX(propDialBg:getContentSize().width / stencilLayer:getContentSize().width)
	stencilLayer:setScaleY((rightCover:getContentSize().height + 30) / stencilLayer:getContentSize().height)
	display.commonUIParams(stencilLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
		propDialBg:getPositionX(),
		fixedPos.leftCoverPos.y
	)})

	propClipNode:setAlphaThreshold(0.01)
	propClipNode:setInverted(false)
	propClipNode:setStencil(stencilLayer)

	-- debug --
	-- local t_a = 5
	-- for i = 1, t_a do
	-- 	local t_l = display.newImageView(_res('ui/pet/pet_fresh_bg_list.png'), 0, 0)
	-- 	display.commonUIParams(t_l, {po = cc.p(
	-- 		fixedPos.leftCoverPos.x,
	-- 		fixedPos.leftCoverPos.y + (t_a * 0.5 - (i - 0.5)) * t_l:getContentSize().height
	-- 	)})
	-- 	propClipNode:addChild(t_l, 4)

	-- 	local t_l_l = display.newLabel(0, 0, fontWithColor('1', {text = '未知类型'}))
	-- 	display.commonUIParams(t_l_l, {po = utils.getLocalCenter(t_l)})
	-- 	t_l:addChild(t_l_l)

	-- 	local t_r = display.newImageView(_res('ui/pet/pet_fresh_bg_list.png'), 0, 0)
	-- 	display.commonUIParams(t_r, {po = cc.p(
	-- 		fixedPos.rightCoverPos.x,
	-- 		fixedPos.rightCoverPos.y + (t_a * 0.5 - (i - 0.5)) * t_r:getContentSize().height
	-- 	)})
	-- 	propClipNode:addChild(t_r, 4)

	-- 	local t_r_l = display.newLabel(0, 0, fontWithColor('1', {text = '未知数值'}))
	-- 	display.commonUIParams(t_r_l, {po = utils.getLocalCenter(t_r)})
	-- 	t_r:addChild(t_r_l)
	-- end
	-- debug --

	-- 消耗
	local recastCostConfig = petMgr.GetPropRecastCostConfig()
	local recastCostLabel = display.newLabel(0, 0, fontWithColor('14', {text = '0/0'}))
	propLayer:addChild(recastCostLabel, 5)

	local recastCostIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(recastCostConfig.goodsId)), 0, 0)
	recastCostIcon:setScale(0.25)
	propLayer:addChild(recastCostIcon, 5)

	display.setNodesToNodeOnCenter(propBtn, {recastCostLabel, recastCostIcon}, {y = -15})
	------------ 左侧转盘 ------------


	--描述文字
	local desLabel = display.newLabel(propBgPos.x, size.height - 155, fontWithColor('6', {text = ' '}))
	propLayer:addChild(desLabel, 10)
	local desLabelScale = desLabel:getScale()

	self.viewData.propLayer = {
		------------ view nodes ------------
		root = propLayer,
		pBtns = pBtns,
		recastCostLabel = recastCostLabel,
		recastCostIcon = recastCostIcon,
		propBtn = propBtn,
		propClipNode = propClipNode,
		propDialBg = propDialBg,
		dialLeftNodes = {},
		dialRightNodes = {},
		leftCover = leftCover,
		rightCover = rightCover,
		arrowR = arrowR,
		arrowL = arrowL,
		skipDialBtn = skipDialBtn,
		desLabel = desLabel,
		desLabelScale = desLabelScale,
		------------ ui data ------------
		fixedPos = fixedPos
		------------ layer handler ------------
	}

	self.mainLayers[TabModuleType.PROPERTY] = self.viewData.propLayer
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
根据index 刷新界面
@params index int 序号
--]]
function PetUpgradeLayer:RefreshUIByIndex(index)

	if nil ~= index then
		local currentTab = self.viewData.tabBtns[index]
		if nil ~= currentTab then
			currentTab:setChecked(true)
			currentTab:getChildByTag(3):setColor(ccc3FromInt('e0491a'))
		end
	end

	if index == self.selectedTabIndex then return end

	if nil ~= self.selectedTabIndex then
		local prevTab = self.viewData.tabBtns[self.selectedTabIndex]
		if nil ~= prevTab then
			prevTab:setChecked(false)
			prevTab:getChildByTag(3):setColor(ccc3FromInt('3c3c3c'))
		end
	end

	self.selectedTabIndex = index

	self:RefreshMainLayer(index)

end


--[[
根据index 刷新列表数据
@params index TabModuleType 
@params petsData list 堕神列表数据
--]]
function PetUpgradeLayer:RefreshPetsDataByIndex(index, petsData)
	if TabModuleType.LEVEL == index then
		self:RefreshLevelLayerGridView(petsData)
	elseif TabModuleType.BREAK == index then
		self:RefreshBreakLayerGridView(petsData)
	end
end
--[[
根据index显示中间主要内容层
@params moduleType TabModuleType 模块类型
--]]
function PetUpgradeLayer:RefreshMainLayer(moduleType)
	if TabModuleType.LEVEL == moduleType then

		self:RefreshLevelLayer()

	elseif TabModuleType.BREAK == moduleType then

		self:RefreshBreakLayer()

	elseif TabModuleType.PROPERTY == moduleType then

		self:RefreshPropLayer()
	elseif  TabModuleType.EVOLUTION == moduleType then
		self:RefreshEvolutionLayer()

	end

	
	-- 刷新顶部标题
	self.viewData.titleBg:getLabel():setString(tabInfo[moduleType].name)

	-- 隐藏其他层
	for moduleType_, layer in pairs(self.mainLayers) do
		if nil ~= layer.root then
			layer.root:setVisible(moduleType_ == moduleType)
		end
	end
end
--[[
刷新升级层数据
@params pets list 堕神数据集 
--]]
function PetUpgradeLayer:RefreshLevelLayerGridView(pets)
	self.levelPets = pets

	self.viewData.levelLayer.gridView:setCountOfCell(#self.levelPets)
	self.viewData.levelLayer.gridView:reloadData()

	self.viewData.levelLayer.ShowNoPetMaterial(0 >= #self.levelPets)
end
--[[
刷新强化层数据
--]]
function PetUpgradeLayer:RefreshBreakLayerGridView(pets)
	self.breakPets = pets or self.breakPets

	self.viewData.breakLayer.gridView:setCountOfCell(#self.breakPets)
	self.viewData.breakLayer.gridView:reloadData()

	self.viewData.breakLayer.ShowNoPetMaterial(0 >= #self.breakPets)


	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	if checkint(mainPetData.breakLevel) < petMgr.GetPetMaxBreakLevelById(self.mainId) then
		-- 强化等级已满 无法添加
		local deltaBreakLevel = petMgr.GetDeltaBreakLevel()
		self:RefreshPetAllPPreview(
			petMgr.GetPetAllBaseProps(self.mainId),
			mainPetData.breakLevel + deltaBreakLevel,
			checkint(mainPetData.character)
		)
	end
end
--[[
刷新升级层
--]]
function PetUpgradeLayer:RefreshLevelLayer()
	if nil == self.viewData.levelLayer then
		-- 为空 初始化一次
		self:InitLevelLayer()
	else
		-- 刷新界面

	end
end
--[[
刷新强化层
--]]
function PetUpgradeLayer:RefreshBreakLayer()
	if nil == self.viewData.breakLayer then
		-- 为空 初始化一次
		self:InitBreakLayer()
	else
		-- 刷新界面

	end
	-- 刷新堕神属性
	self:RefreshPetAllPData(petMgr.GetPetAllFixedProps(self.mainId))
	self:RefreshBreakLevel()
	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	if checkint(mainPetData.breakLevel) < petMgr.GetPetMaxBreakLevelById(self.mainId) then
		-- 强化等级已满 无法添加
		local deltaBreakLevel = petMgr.GetDeltaBreakLevel()
		self:RefreshPetAllPPreview(
			petMgr.GetPetAllBaseProps(self.mainId),
			mainPetData.breakLevel + deltaBreakLevel,
			checkint(mainPetData.character)
		)
	end
	self:RefreshBreakConsumeShow()
	self:RefreshBreakPow()
	-- 刷新强化消耗
	self:RefreshBreakCost(checkint(gameMgr:GetPetDataById(self.mainId).breakLevel) + 1)
	-- 刷新堕神突破等级
	self:RefreshBreakMainPetLevel(gameMgr:GetPetDataById(self.mainId).breakLevel)
end

function PetUpgradeLayer:RefreshBreakPow()
	local breakLayer = self.viewData.breakLayer
	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	if checkint(mainPetData.breakLevel) >= 10  and checkint(mainPetData.breakLevel) < 20   then
		local petConfig = petMgr.GetPetConfig(mainPetData.petId)
		if checkint(petConfig.type) == PetType.BOSS then

		else
			return
		end
	else
		if checkint(mainPetData.breakLevel) == 20 then
			local breakLayer =  breakLayer.root
			if breakLayer then
				local breakPowLayout = breakLayer:getChildByName("breakPowLayout")
				breakPowLayout:setVisible(false)

			end
		end
		return
	end

	if breakLayer then
		local breakLayer =  breakLayer.root
		if breakLayer then
			local breakPowLayout = breakLayer:getChildByName("breakPowLayout")
			if breakPowLayout and (not tolua.isnull(breakPowLayout)) then
				local breakConfig = CommonUtils.GetConfig('pet', 'petBreak', mainPetData.breakLevel+1)

				local maxSuccessTimes =  checkint(breakConfig.maxSuccessTimes)
				local breakTimes = checkint(mainPetData.breakTimes)
				local powOneValue = math.floor(1000  / ( maxSuccessTimes -1))
				local powValue =  powOneValue * breakTimes
				local progressBarOne = breakPowLayout.progressBarOne
				local progressLabel = breakPowLayout.progressLabel
				local powLabel = breakPowLayout.powLabel
				breakPowLayout:setVisible(true)
				powValue = powValue >1000 and 1000 or powValue
				progressBarOne:setValue(powValue)
				display.commonLabelParams(progressLabel , {text = string.format("%d/%d" ,powValue,1000 )})
				display.reloadRichLabel(powLabel , { c = {
					fontWithColor('8' , {text = __('强化能量')}),
					fontWithColor('6' , {text = string.format(__('(失败+%d)') , powOneValue) })
				}})
			end
		end
	end
	
end
--[[
	刷新突破的消耗显示
--]]
function PetUpgradeLayer:RefreshBreakConsumeShow()
	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	if checkint(mainPetData.breakLevel) >=  petMgr.GetPetMaxBreakLevelById(self.mainId) then
		-- 强化等级已满 无法添加
		local petConfig = petMgr.GetPetConfig(mainPetData.petId) or {}
		if checkint(petConfig.type)  ==  PetType.BOSS  and  checkint(mainPetData.isEvolution) == 0  then

		else
			local nodes = self.viewData.breakLayer.breakMaterialLayout
			nodes:setVisible(false)
			return
		end
	end
	local index =1
	local nodes = self.viewData.breakLayer.materialBtns[index]
	local slotNode = nodes.slotNode
	local nameNode = nodes.nameNode

	local petNum = petMgr.GetPetBreakUpMaxMaterialAmountByBreakLevel(checkint(mainPetData.breakLevel)  + 1)
	if petNum >  1  then
		nameNode:setVisible(false)
		local breakLayer = self.viewData.breakLayer
		local consumeLabel = breakLayer.consumeLabel
		local materialLabel = breakLayer.materialLabel
		local consumeGoodNode = breakLayer.consumeGoodNode
		local breakMaterialSize = breakLayer.breakMaterialSize
		consumeLabel:setVisible(true)
		materialLabel:setVisible(true)
		consumeGoodNode:setVisible(true)
		display.commonLabelParams(materialLabel ,  fontWithColor('10',{color = '#ffffff' , text = string.format('%d/%d',0 , petNum )}))
		local petCostConfig = petMgr.GetBreakCostConfig(checkint(mainPetData.breakLevel)  + 1)
		local evolutionNum = 0
		local ownEvolutionNum = CommonUtils.GetCacheProductNum(EVOLUTION_STONE_ID)
		for i, v in pairs(petCostConfig) do
			if checkint(v.goodsId) == EVOLUTION_STONE_ID  then
				evolutionNum = checkint(v.num)
			end
		end
		display.commonLabelParams(consumeLabel,  fontWithColor('10',{color = '#ffffff' , text = string.format('%d/%d',ownEvolutionNum , evolutionNum )}))
		local mPosY =  materialLabel:getPositionY()
		local mNPosY = slotNode:getPositionY()
		slotNode:setPosition(cc.p(breakMaterialSize.width /4 , mNPosY))
		materialLabel:setPosition(cc.p(breakMaterialSize.width /4 , mPosY))
	else
		local breakLayer = self.viewData.breakLayer
		local consumeLabel = breakLayer.consumeLabel
		local materialLabel = breakLayer.materialLabel
		local consumeGoodNode = breakLayer.consumeGoodNode
		local breakMaterialSize = breakLayer.breakMaterialSize
		materialLabel:setVisible(false)
		consumeLabel:setVisible(false)
		consumeGoodNode:setVisible(false)
		local posY = slotNode:getPositionY()
		slotNode:setPosition(breakMaterialSize.width /2 ,posY )
	end
end
--[[
刷新洗炼层
--]]
function PetUpgradeLayer:RefreshPropLayer()
	if nil == self.viewData.propLayer then
		-- 为空 初始化一次
		self:InitPropLayer()
	else
		-- 刷新界面
	end
	-- 刷新堕神属性
	self:RefreshPropAllPBtn(petMgr.GetPetAllFixedProps(self.mainId))
	-- 刷新选择状态
	self:RefreshRecastPropByIndex(1)
	-- 刷新道具
	local recastCostConfig = petMgr.GetPropRecastCostConfig()
	self:RefreshPropRecastCost(recastCostConfig.num, gameMgr:GetAmountByGoodId(recastCostConfig.goodsId))
end
--[[
	刷新异化的属性
--]]
function PetUpgradeLayer:RefreshEvolutionLayer()
	if nil == self.viewData.evoltionLayer then
		-- 为空 初始化一次
		self:InitEvolutionLayer()
	else
		-- 刷新界面
	end
	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	local isEvolution = checkint(mainPetData.isEvolution)
	if isEvolution ==1  then
		self:RefreshAlreadyEvolutionLayer(mainPetData)

	else
		self:RefreshNotEvolutionLayer(mainPetData)
	end
end
function PetUpgradeLayer:EvolutionAction()
	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	local evoltionLayer = self.viewData.evoltionLayer
	local petLayout = evoltionLayer.petLayout
	local petSize = evoltionLayer.petSize
	local attrLabelTable = evoltionLayer.attrLabelTable
	local petNode = evoltionLayer.petNode
	local attrOneSize    = evoltionLayer.attrOneSize
	-- 突破效果
	local spineActionA = sp.SkeletonAnimation:create('effects/pet/bianyi_attack.json', 'effects/pet/bianyi_attack.atlas',1)
	petLayout:addChild(spineActionA ,2)
	spineActionA:setAnimation(0, 'attack' , false  )
	spineActionA:setPosition(cc.p(petSize.width/2, petSize.height/2))
	local spineActionloop = sp.SkeletonAnimation:create('effects/pet/bianyi_loop.json', 'effects/pet/bianyi_loop.atlas',1)
	petLayout:addChild(spineActionloop ,1)
	spineActionloop:setName("spineActionloop")
	spineActionloop:setToSetupPose()
	spineActionloop:setAnimation(0, 'idle2' , true  )
	spineActionloop:setPosition(cc.p(petSize.width/2, petSize.height/2))

	local clonePetNode = require("common.PetHeadNode").new({id = mainPetData.id})
	clonePetNode:setScaleX(0)
	petLayout:addChild(clonePetNode , 10 )
	clonePetNode:setPosition(petSize.width/2, petSize.height/2)

	local spawnTable  = {}
	spawnTable[#spawnTable+1] =  cc.Sequence:create(
			cc.ScaleTo:create(0.15, 0,1),
			cc.TargetedAction:create(clonePetNode, cc.Sequence:create(cc.ScaleTo:create(0.15, 1,1) , cc.EaseSineInOut:create(cc.Sequence:create(cc.ScaleTo:create(0.15, 1.5) ,cc.ScaleTo:create(0.15, 1) ) ))  ),
			cc.DelayTime:create(0.7)

	)

	for i = 1, 3 do
		spawnTable[#spawnTable+1] = cc.TargetedAction:create(attrLabelTable[i].curLabel, cc.Sequence:create(cc.FadeOut:create(0.25), cc.DelayTime:create(1.05) ))
		spawnTable[#spawnTable+1] = cc.TargetedAction:create(attrLabelTable[i].swordImage, cc.Sequence:create( cc.DelayTime:create(0.35), cc.FadeOut:create(0.25),cc.DelayTime:create(0.7)))
		spawnTable[#spawnTable+1] = cc.TargetedAction:create(attrLabelTable[i].nextLabel,
			 cc.Sequence:create(
					 cc.DelayTime:create(0.5),
					 cc.EaseSineInOut:create(cc.MoveTo:create(0.6, cc.p(attrOneSize.width/2 + 50 , attrOneSize.height/2 )) ) ,
					 cc.CallFunc:create(function()
						 petNode:RefreshUI({id = self.mainId })
						 petNode:setScale(1)
						 clonePetNode:setVisible(false)
						 clonePetNode:runAction(cc.RemoveSelf:create())
						 self:RefreshAlreadyEvolutionLayer(mainPetData)
					 end)
			 ))
	end
	petNode:runAction(
		cc.Spawn:create(spawnTable)
	)


end
--- 已经异化界面刷新
function PetUpgradeLayer:RefreshAlreadyEvolutionLayer(mainPetData)
	local evoltionLayer = self.viewData.evoltionLayer
	local petId = mainPetData.petId
	local petConfig = petMgr.GetPetConfig(petId)
	--堕神异化消耗

	local petImage       = evoltionLayer.petImage
	local costGoodLayout = evoltionLayer.costGoodLayout
	local petNode        = evoltionLayer.petNode
	local attrLabelTable = evoltionLayer.attrLabelTable
	local attrOneSize    = evoltionLayer.attrOneSize
	local evoltionBtn    = evoltionLayer.evoltionBtn
	local costGoodsLabel = evoltionLayer.costGoodsLabel
	local costGoldLabel  = evoltionLayer.costGoldLabel
	local goodNode       = evoltionLayer.goodNode
	local petName        = evoltionLayer.petName
	local petLayout      = evoltionLayer.petLayout
	local petSize        = evoltionLayer.petSize


	petNode:RefreshUI({id = self.mainId })
	local attrTextTable = {
		__('传 说'),
		 "+".. tostring(petConfig.evolutionMaxBreakLevel) ,
		 "+".. tonumber(petConfig.evolutionExclusiveAddition) * 100 .. '%'

	}
	local spineActionloop = petLayout:getChildByName("spineActionloop")
	if not  spineActionloop then
		spineActionloop = sp.SkeletonAnimation:create('effects/pet/bianyi_loop.json', 'effects/pet/bianyi_loop.atlas',1)
		petLayout:addChild(spineActionloop ,1)
		spineActionloop:setToSetupPose()
		spineActionloop:setName("spineActionloop")
		spineActionloop:setAnimation(0, 'idle2' , true  )
		spineActionloop:setPosition(cc.p(petSize.width/2, petSize.height/2))
	end
	local costGoods = petMgr.GetEvoltuionCostConfig(petId)
	for i, v in pairs(costGoods) do
		if checkint(v.goodsId) == GOLD_ID  then
			costGoldLabel:setVisible(false)
		else
			goodNode:RefreshSelf(v)
			local needNum  =  v.num
			local ownNum = CommonUtils.GetCacheProductNum(v.goodsId)
			display.commonLabelParams(costGoodsLabel , {text = string.format("%d/%d" , checkint(ownNum) ,checkint(needNum) ) })
			costGoodLayout:setVisible(true)
		end
	end
	for i = 1, 3 do
		attrLabelTable[i].swordImage:setVisible(false)
		attrLabelTable[i].curLabel:setVisible(false)
		attrLabelTable[i].nextLabel:setVisible(true)
		display.commonLabelParams(attrLabelTable[i].nextLabel ,{    text = attrTextTable[i]} )
		attrLabelTable[i].nextLabel:setPosition(attrOneSize.width/2 + 50 , attrOneSize.height/2 )
	end
	petImage:setTexture(AssetsUtils.GetCartoonPath(petMgr.GetPetDrawIdByPetId(petId)))

	display.commonLabelParams(evoltionBtn , { text = __('已异化')})

	evoltionBtn:setNormalImage(_res('ui/common/common_btn_orange_disable'))
	evoltionBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable'))
	evoltionBtn:setDisabledImage(_res('ui/common/common_btn_orange_disable'))
	petName:setNormalImage(_res('ui/pet/evoltion/pet_evolution_bg_name_finish'))
	petName:setSelectedImage(_res('ui/pet/evoltion/pet_evolution_bg_name_finish'))
	petName:setDisabledImage(_res('ui/pet/evoltion/pet_evolution_bg_name_finish'))
	display.commonLabelParams(petName , {text = petConfig.name})
	-- 刷新本命属性显示
	self:RefreshEvolutionExclusiveCardUI(mainPetData)
end
function PetUpgradeLayer:RefreshNotEvolutionLayer(mainPetData)
	local evoltionLayer = self.viewData.evoltionLayer
	local petId = mainPetData.petId
	local petConfig = petMgr.GetPetConfig(petId)
	--堕神异化消耗

	local petImage       = evoltionLayer.petImage
	local costGoodLayout = evoltionLayer.costGoodLayout
	local petNode        = evoltionLayer.petNode
	local attrLabelTable = evoltionLayer.attrLabelTable
	local attrOneSize    = evoltionLayer.attrOneSize
	local petName        = evoltionLayer.petName
	local goodNode       = evoltionLayer.goodNode
	local costGoodsLabel = evoltionLayer.costGoodsLabel
	local costGoldLabel  = evoltionLayer.costGoldLabel
	local petLayout      = evoltionLayer.petLayout
	local petSize        = evoltionLayer.petSize

	local costGoods = petMgr.GetEvoltuionCostConfig(petId)
	if next(costGoods) ~= nil    then
		for i, v in pairs(costGoods) do
			if checkint(v.goodsId) == GOLD_ID  then
				display.reloadRichLabel(costGoldLabel , { c =  {
					{ text = CommonUtils.GetCacheProductNum(GOLD_ID ) },
					{ img = CommonUtils.GetGoodsIconPathById(GOLD_ID ) , scale = 0.2},
				}})
				costGoldLabel:setVisible(true)
				CommonUtils.AddRichLabelTraceEffect(costGoldLabel , nil , nil , {1})
			else
				goodNode:RefreshSelf(v)
				local needNum  =  v.num
				local ownNum = CommonUtils.GetCacheProductNum(v.goodsId)
				display.commonLabelParams(costGoodsLabel , {text = string.format("%d/%d" , checkint(ownNum) ,checkint(needNum) ) })
				costGoodLayout:setVisible(true)
				--display.commonUIParams(goodNode, {animate = false, cb = function (sender)
				--	uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
				--end})
			end
		end

	else
		costGoodLayout:setVisible(false)
	end
	local spineActionloop = petLayout:getChildByName("spineActionloop")
	if not  spineActionloop then
		spineActionloop = sp.SkeletonAnimation:create('effects/pet/bianyi_loop.json', 'effects/pet/bianyi_loop.atlas',1)
		petLayout:addChild(spineActionloop ,1)
		spineActionloop:setName("spineActionloop")
		spineActionloop:setAnimation(0, 'idle1' , true  )
		spineActionloop:setPosition(cc.p(petSize.width/2, petSize.height/2))
	end

	petNode:RefreshUI({id = self.mainId })
	local attrTextTable = {
		{ cur  =  __('史 诗'),  next  =  __('传 说')},
		{  cur = "+".. tostring(petConfig.normalMaxBreakLevel),next = "+".. tostring(petConfig.evolutionMaxBreakLevel) } ,
		{  cur = "+".. tonumber(petConfig.normalExclusiveAddition) * 100 .. '%',next = "+".. tonumber(petConfig.evolutionExclusiveAddition) * 100 .. '%' } ,


	}


	for i = 1, 3 do
		display.commonLabelParams(attrLabelTable[i].nextLabel ,{po = cc.p(attrOneSize.width/2 , attrOneSize.height/2 ) ,  text = attrTextTable[i].next} )
		display.commonLabelParams(attrLabelTable[i].curLabel ,{po = cc.p(attrOneSize.width/2 , attrOneSize.height/2 ) ,  text = attrTextTable[i].cur} )
	end
	petImage:setTexture(AssetsUtils.GetCartoonPath(petMgr.GetPetDrawIdByPetId(petId)))
	display.commonLabelParams(petName , {text = petConfig.name})
	-- 刷新本命属性显示
	self:RefreshEvolutionExclusiveCardUI(mainPetData)
end

--[[
	刷新本命属性的显示
--]]
function PetUpgradeLayer:RefreshEvolutionExclusiveCardUI(mainPetData)
	local evoltionLayer = self.viewData.evoltionLayer
	local exclusiveCardList = evoltionLayer.exclusiveCardList
	local petId = mainPetData.petId
	local petConfig = petMgr.GetPetConfig(petId)
	local count =  #petConfig.exclusiveCard
	local name = ""
	local cellSize = cc.size(190, 30 )
	exclusiveCardList:removeAllNodes()
	for i =1 ,count  do
		local cardConfig =  CommonUtils.GetConfigAllMess('card','goods')
		local cardOneConfig = cardConfig[tostring(petConfig.exclusiveCard[i])] or {}
		name  = cardOneConfig.name
		if name  then
			--name  = name  .. ","
			local cardLayout = display.newLayer(0,0,{ size = cellSize ,ap = display.CENTER_TOP, color1 = cc.r4b()})
			local label = display.newLabel(cellSize.width/2,cellSize.height/2,fontWithColor('16',{ text = name  }))
			cardLayout:addChild(label)
			exclusiveCardList:insertNodeAtLast(cardLayout)
		end

	end
	exclusiveCardList:reloadData()
end

--- 未异化界面刷新




--[[
/***********************************************************************************************************************************\
 * level layer
\***********************************************************************************************************************************/
--]]
--[[
堕神升级列表处理
--]]
function PetUpgradeLayer:LevelGridViewDataAdapter(c, i)
	local cell = c
	local index = i + 1
	local petIcon = nil
	local borderIcon = nil
	local id = self.levelPets[index]

	if nil == cell then
		local cellSize = self.viewData.levelLayer.gridView:getSizeOfCell()

		cell = CGridViewCell:new()
		cell:setContentSize(cellSize)
		-- cell:setBackgroundColor(cc.c4b(math.random(255), math.random(255), math.random(255), 100))

		-- 堕神头像
		petIcon = require('common.PetHeadNode').new({
			showBaseState = true,
			showLockState = true
		})
		petIcon:setScale((cellSize.width - 5) / petIcon:getContentSize().width)
		display.commonUIParams(petIcon, {po = cc.p(cellSize.width * 0.5, cellSize.height * 0.5),
			cb = handler(self, self.LevelPetIconClickCallback), animate = false})
		cell:addChild(petIcon)
		petIcon:setTag(3)

		-- 选中状态
		borderIcon = display.newNSprite(_res('ui/common/common_bg_frame_goods_elected.png'), cellSize.width * 0.5, cellSize.height * 0.5)
		borderIcon:setScale((cellSize.width + 5) / borderIcon:getContentSize().width)
		cell:addChild(borderIcon, 5)
		borderIcon:setTag(5)
	else
		petIcon = cell:getChildByTag(3)
		borderIcon = cell:getChildByTag(5)
	end

	-- 刷新堕神头像
	petIcon:RefreshUI({
		id = id
	})

	-- 刷新选中状态
	borderIcon:setVisible(self:GetLevelPetSelectedById(id))

	cell:setTag(index)

	return cell
end
--[[
根据id刷新所选升级狗粮选择状态
@params id int 堕神数据库id
@params selected bool 是否选择
--]]
function PetUpgradeLayer:RefreshLevelPetIconSelectById(id, selected)
	local index = self:GetLevelPetIndexById(id)

	------------ data ------------
	self:SetLevelPetSelectedById(id, selected)
	------------ data ------------

	------------ view ------------
	local curCell = self.viewData.levelLayer.gridView:cellAtIndex(index - 1)
	if nil ~= curCell then
		curCell:getChildByTag(5):setVisible(selected)
	end
	------------ view ------------
end
--[[
刷新槽位状态
@params index int 序号
@params id int 堕神id
--]]
function PetUpgradeLayer:RefreshLevelMaterialSlotByIndex(index, id)
	local nodes = self.viewData.levelLayer.materialBtns[index]
	local slotNode = nodes.slotNode
	local petNode = nodes.petNode

	if nil ~= petNode then
		petNode:setVisible((nil ~= id))
	end

	if nil == id then return end

	if nil == petNode then
		petNode = require('common.PetHeadNode').new({
			id = id,
			showBaseState = true,
			showLockState = true
		})
		petNode:setScale((slotNode:getContentSize().width - 5) / petNode:getContentSize().width)
		display.commonUIParams(petNode, {po = utils.getLocalCenter(slotNode)})
		slotNode:addChild(petNode)
		self.viewData.levelLayer.materialBtns[index].petNode = petNode
	else
		petNode:RefreshUI({
			id = id
		})
	end
end
--[[
清空插槽选择状态
--]]
function PetUpgradeLayer:ClearLevelMaterialSlot()
	local nodes = self.viewData.levelLayer.materialBtns
	for i,v in ipairs(nodes) do
		self:RefreshLevelMaterialSlotByIndex(i, nil)
	end
end
--[[
升级成功
@params pets list 堕神数据集
@params levelUp bool 是否升了级
--]]
function PetUpgradeLayer:DoLevelUpgrade(pets, levelUp)
	------------ data ------------
	-- 清空列表选择数据
	self:ClearLevelPetSelected()
	------------ data ------------

	------------ view ------------
	PlayAudioClip(AUDIOS.UI.ui_star.id)

	-- 清空插槽选择状态
	self:ClearLevelMaterialSlot()
	-- 刷新一次列表
	self:RefreshLevelLayerGridView(pets)
	-- 刷新等级
	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	self:RefreshExpLabel(checkint(mainPetData.exp))
	self:RefreshLevelLabel(checkint(mainPetData.level))

	-- 升级动画
	local levelUpgradeAnimationName = 'play2'
	local levelUpgradeSpine = self.viewData.levelLayer.levelUpgradeSpine
	if nil == levelUpgradeSpine then
		levelUpgradeSpine = sp.SkeletonAnimation:create(
			'effects/pet/shengxing.json',
			'effects/pet/shengxing.atlas',
			1
		)
		levelUpgradeSpine:setPosition(cc.p(
			self.viewData.levelLayer.dynamicAvatar:getPositionX(),
			self.viewData.levelLayer.dynamicAvatar:getPositionY() + self.viewData.levelLayer.dynamicAvatar:getContentSize().height * 0.3
		))
		self.viewData.levelLayer.dynamicAvatar:getParent():addChild(
			levelUpgradeSpine,
			self.viewData.levelLayer.dynamicAvatar:getLocalZOrder()
		)

		self.viewData.levelLayer.levelUpgradeSpine = levelUpgradeSpine
	end

	levelUpgradeSpine:setToSetupPose()
	levelUpgradeSpine:setAnimation(0, levelUpgradeAnimationName, false)
	------------ view ------------
end
--[[
刷新经验值文字
@params exp int 变化后的经验总值
--]]
function PetUpgradeLayer:RefreshExpPreview(exp)
	-- 刷新经验值文字
	self:RefreshExpLabel(exp)
	-- 刷新等级预览
	self:RefreshLevelPreview(exp)
end
--[[
根据当前经验值刷新经验值label
@params exp 当前经验总值
--]]
function PetUpgradeLayer:RefreshExpLabel(exp)
	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	local curValue, maxValue, curStr, maxStr = self:GetExpBarParams(checkint(mainPetData.level), exp)

	-- 经验文字
	self.viewData.levelLayer.expLabel:setString(string.format('%s/%s', curStr, maxStr))

	-- 经验条
	self.viewData.levelLayer.expBar:setMaxValue(maxValue)
	self.viewData.levelLayer.expBar:setValue(math.min(curValue, maxValue))
end
--[[
根据当前经验值刷新等级预览
@params exp 当前经验总值
--]]
function PetUpgradeLayer:RefreshLevelPreview(exp)
	local mainPetData = gameMgr:GetPetDataById(self.mainId)

	-- 如果经验值变化为0 隐藏这一步
	if exp == checkint(mainPetData.exp) then
		if nil ~= self.viewData.levelLayer.nextLevelLabel then
			self.viewData.levelLayer.nextLevelIcon:setVisible(false)
			self.viewData.levelLayer.nextLevelLabel:setVisible(false)

			display.commonUIParams(self.viewData.levelLayer.curLevelLabel, {po = cc.p(
				self.viewData.levelLayer.avatarBottomPos.x,
				self.viewData.levelLayer.levelLabelPosY
			)})
		end

		return
	end

	-- 计算等级
	local targetLevel = checkint(mainPetData.level)
	local targetLevelConfig = CommonUtils.GetConfig('pet', 'level', targetLevel)
	while exp >= checkint(targetLevelConfig.totalExp) do
		targetLevel = targetLevel + 1
		targetLevelConfig = CommonUtils.GetConfig('pet', 'level', targetLevel)
		if not targetLevelConfig then
			break
		end
	end

	targetLevel = targetLevel - 1

	-- 刷新ui
	if nil == self.viewData.levelLayer.nextLevelLabel then
		-- 升级图标
		local nextLevelIcon = display.newNSprite(_res('ui/pet/card_skill_ico_sword.png'), 0, 0)
		self.viewData.levelLayer.root:addChild(nextLevelIcon, 10)
		self.viewData.levelLayer.nextLevelIcon = nextLevelIcon

		-- 等级label
		local nextLevelLabel = display.newLabel(0, 0, fontWithColor('5', {text = string.format(__('等级%d'), targetLevel)}))
		self.viewData.levelLayer.root:addChild(nextLevelLabel, 10)
		self.viewData.levelLayer.nextLevelLabel = nextLevelLabel
	else
		self.viewData.levelLayer.nextLevelIcon:setVisible(true)
		self.viewData.levelLayer.nextLevelLabel:setVisible(true)

		self.viewData.levelLayer.nextLevelLabel:setString(string.format(__('等级%d'), targetLevel))
	end

	display.commonUIParams(self.viewData.levelLayer.nextLevelIcon, {po = cc.p(
		self.viewData.levelLayer.avatarBottomPos.x,
		self.viewData.levelLayer.levelLabelPosY
	)})

	display.commonUIParams(self.viewData.levelLayer.curLevelLabel, {po = cc.p(
		self.viewData.levelLayer.avatarBottomPos.x - self.viewData.levelLayer.nextLevelIcon:getContentSize().width * 0.5 - 40,
		self.viewData.levelLayer.levelLabelPosY
	)})

	display.commonUIParams(self.viewData.levelLayer.nextLevelLabel, {po = cc.p(
		self.viewData.levelLayer.avatarBottomPos.x + self.viewData.levelLayer.nextLevelIcon:getContentSize().width * 0.5 + 40,
		self.viewData.levelLayer.levelLabelPosY
	)})
end
--[[
刷新当前等级label
@params level int 等级
--]]
function PetUpgradeLayer:RefreshLevelLabel(level)
	if nil ~= self.viewData.levelLayer.nextLevelLabel then
		self.viewData.levelLayer.nextLevelIcon:setVisible(false)
		self.viewData.levelLayer.nextLevelLabel:setVisible(false)

		display.commonUIParams(self.viewData.levelLayer.curLevelLabel, {po = cc.p(
			self.viewData.levelLayer.avatarBottomPos.x,
			self.viewData.levelLayer.levelLabelPosY
		)})
	end

	self.viewData.levelLayer.curLevelLabel:setString(string.format(__('等级%d'), level))
end
--[[
/***********************************************************************************************************************************\
 * break layer
\***********************************************************************************************************************************/
--]]
--[[
堕神强化列表处理
--]]
function PetUpgradeLayer:BreakGridViewDataAdapter(c, i)
	local cell = c
	local index = i + 1
	local petIcon = nil
	local borderIcon = nil
	local petLabel = nil
	local id = self.breakPets[index]

	if nil == cell then
		local cellSize = self.viewData.levelLayer.gridView:getSizeOfCell()

		cell = CGridViewCell:new()
		cell:setContentSize(cellSize)
		-- cell:setBackgroundColor(cc.c4b(math.random(255), math.random(255), math.random(255), 100))

		-- 堕神头像
		petIcon = require('common.PetHeadNode').new({
			showBaseState = true,
			showLockState = true
		})


		petIcon:setScale((cellSize.width - 5) / petIcon:getContentSize().width)
		display.commonUIParams(petIcon, {po = cc.p(cellSize.width * 0.5, cellSize.height * 0.5),
			cb = handler(self, self.BreakPetIconClickCallback), animate = false})
		cell:addChild(petIcon)
		petIcon:setTag(3)
		-- 堕神的label
		petLabel = display.newLabel(cellSize.width - 5 , 5 , fontWithColor('14', {fontSize = 22, ap = display.RIGHT_BOTTOM , text = ''}) )
		cell:addChild(petLabel,100)
		petLabel:setVisible(false)
		petLabel:setTag(10)
		-- 选中状态
		borderIcon = display.newNSprite(_res('ui/common/common_bg_frame_goods_elected.png'), cellSize.width * 0.5, cellSize.height * 0.5)
		borderIcon:setScale((cellSize.width + 5) / borderIcon:getContentSize().width)
		cell:addChild(borderIcon, 5)
		borderIcon:setTag(5)
	else
		petIcon = cell:getChildByTag(3)
		borderIcon = cell:getChildByTag(5)
		petLabel = cell:getChildByTag(10)
	end

	-- 刷新堕神头像
	if   type( self.breakPets[index] ) == 'number' then
		petIcon:RefreshUI({
							  id = id,
							  showLockState = true,
							  showBaseState = true
						  })
		petIcon:setVisible(true)
		petLabel:setVisible(false)
		display.commonUIParams(petIcon, { cb = handler(self, self.BreakPetIconClickCallback)})
	else
		petIcon:RefreshUI({
							  showLockState = false,
							  showBaseState = false
						  })
		petLabel:setVisible(true)
		local selectNum = self:GetSelectPetNum()
		local selectIdPetNum =  table.nums(self.breakSelectedPets)
		selectNum  = selectNum - selectIdPetNum
		local countNum = CommonUtils.GetCacheProductNum(UNIVERSAL_PET_ID)
		display.commonLabelParams(petLabel , fontWithColor('14' , {fontSize = 22, text =  countNum -  selectNum }))
		petIcon.viewData.bg:setTexture( string.format('ui/common/common_frame_goods_%d.png', 5))
		petIcon.viewData.headIcon:setTexture(CommonUtils.GetGoodsIconPathById(UNIVERSAL_PET_ID))
	end


	-- 刷新选中状态
	borderIcon:setVisible(self:GetBreakPetSelectedById(id))

	cell:setTag(index)

	return cell
end
--[[
根据id刷新所选升级狗粮选择状态
@params id int 堕神数据库id
@params selected bool 是否选择
--]]
function PetUpgradeLayer:RefreshBreakPetIconSelectById(id, selected)
	local index = self:GetBreakPetIndexById(id)

	------------ data ------------
	self:SetBreakPetSelectedById(id, selected)
	------------ data ------------

	------------ view ------------
	local curCell = self.viewData.breakLayer.gridView:cellAtIndex(index - 1)
	if nil ~= curCell then
		curCell:getChildByTag(5):setVisible(selected)
	end
	------------ view ------------
end
--[[
刷新选择万能堕神的状态

--]]
function PetUpgradeLayer:RefreshBreakUniveralPet()
	local petNum = self:GetUniversalPet()
	local selected =   petNum > 0 or false
	local count = CommonUtils.GetCacheProductNum(UNIVERSAL_PET_ID)
	------------ view ------------
	local curCell = self.viewData.breakLayer.gridView:cellAtIndex(0)
	if nil ~= curCell then
		curCell:getChildByTag(5):setVisible(selected)
		local petLabel = curCell:getChildByTag(10)
		if petLabel then
			display.commonLabelParams(petLabel ,fontWithColor( '14', {fontSize = 22,  text = count - petNum }))
		end
	end
	------------ view ------------
end


--[[
根据id刷新强化槽位堕神
@params index int 槽位序号
@params id int 堕神id
@params isUnversal 是否是万能堕神
--]]
function PetUpgradeLayer:RefreshBreakMaterialSlotByIndex(index, id, isUnversal)
	index = 1
	local petUid = id
	local nodes = self.viewData.breakLayer.materialBtns[index]
	local slotNode = nodes.slotNode
	local petNode = nodes.petNode
	local isShow = nil ~= id or isUnversal ~= nil
	slotNode:setVisible(not isShow)
	local showBaseState = true
	local showLockState = true
	local name = ""
	local breakLevel = 0
	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	local petNum = petMgr.GetPetBreakUpMaxMaterialAmountByBreakLevel(checkint(mainPetData.breakLevel)  + 1)
	if petNum >  1  then
		local materialLabel = self.viewData.breakLayer.materialLabel
		showBaseState = false
		showLockState = false
		if isUnversal then
			id = self.mainId
		end
		local selectNum = self:GetSelectPetNum()
		if nil ~= petNode then
			local isVisible = selectNum > 0
			petNode:setVisible(isVisible)
			slotNode:setVisible(not isVisible)
		end
		display.commonLabelParams(materialLabel , {text = string.format('%d/%d' ,selectNum,petNum ) })
	else
		if nil ~= petNode then
			petNode:setVisible(isShow)
		end
		if petUid  then
			local petData = gameMgr:GetPetDataById(id)
			local petConfig = petMgr.GetPetConfig(checkint(petData.petId))
			name = petConfig.name
			breakLevel = petData.breakLevel
		elseif isUnversal then
			id = self.mainId
			showBaseState = false
			showLockState = false
			local univeralConfig = CommonUtils.GetConfig('goods','goods', UNIVERSAL_PET_ID)
			name = univeralConfig.name
		end
	end
	if not  isShow then
		return
	end
	if nil == petNode then

		petNode = require('common.PetHeadNode').new({
			id = id,
			showBaseState = showBaseState,
			showLockState = showLockState,
		})
		petNode:setScale(0.9)
		display.commonUIParams(petNode, {cb = handler(self, self.BreakMaterialBtnClickCallback),
			po = cc.p(slotNode:getPositionX(), slotNode:getPositionY())})
		slotNode:getParent():addChild(petNode, slotNode:getLocalZOrder() + 1)
		petNode:setTag(index)

		self.viewData.breakLayer.materialBtns[index].petNode = petNode

	else
		display.commonUIParams(petNode, {cb = handler(self, self.BreakMaterialBtnClickCallback),
										 po = cc.p(slotNode:getPositionX(), slotNode:getPositionY())})
		petNode:setTag(index)
		petNode:RefreshUI({
			id = id,
			showBaseState = showBaseState,
			showLockState = showLockState,
		})
		petNode:setScale(0.9)

	end


end
--[[
刷新所有属性信息 -> {bgNode = nil, lockNode = nil, pNameNode = nil, pValueNode = nil, pChangeNode = nil, pValuePreviewNode = nil}
@params pdata list 属性信息集合
--]]
function PetUpgradeLayer:RefreshPetAllPData(pdata)
	for i,v in ipairs(pdata) do
		self:RefreshPetAPData(i, v)
	end
	
end
function PetUpgradeLayer:RefreshBreakLevel()
	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	local breakLevel     = mainPetData.breakLevel
	local maxBreakLevel  = petMgr.GetPetMaxBreakLevelByPetId(mainPetData.petId)
	local breakLayer     = self.viewData.breakLayer
	local levelTable     = breakLayer.levelTable
	local curBreakLevel  = levelTable.curBreakLevel
	local nextBreakLevel = levelTable.nextBreakLevel
	local levelSkillImage= levelTable.levelSkillImage

	if  checkint(breakLevel)  >= checkint(maxBreakLevel)  then
		nextBreakLevel:setVisible(true)
		local posY = nextBreakLevel:getPositionY()
		nextBreakLevel:setPosition(cc.p(385 , posY))
		nextBreakLevel:setString(tostring(breakLevel))
		nextBreakLevel:setAnchorPoint(display.RIGHT_CENTER)
	else
		curBreakLevel:setVisible(true)
		nextBreakLevel:setVisible(true)
		levelSkillImage:setVisible(true)
		curBreakLevel:setString(tostring(breakLevel) )
		nextBreakLevel:setString(tostring(breakLevel+1))
	end
end
--[[
刷新单条属性信息
@params index int 属性序号
@params pdata table 单条属性信息
--]]
function PetUpgradeLayer:RefreshPetAPData(index, pdata)
	local nodes = self.viewData.breakLayer.petpNodes[index]

	nodes.lockNode:setVisible(not pdata.unlock)
	nodes.bgNode:setVisible(pdata.unlock)

	local pname = PetPConfig[pdata.ptype].name

	if pdata.unlock then
		-- 解锁
		------------ 属性名 ------------
		if nil == nodes.pNameNode then
			local pNameNode = display.newLabel(0, 0, fontWithColor('5', {text = pname}))
			display.commonUIParams(pNameNode, {ap = cc.p(0, 0.5), po = cc.p(
				30,
				utils.getLocalCenter(nodes.bgNode).y
			)})
			nodes.bgNode:addChild(pNameNode)

			self.viewData.breakLayer.petpNodes[index].pNameNode = pNameNode
		else
			nodes.pNameNode:setString(pname)
		end
		------------ 属性名 ------------

		------------ 属性值 ------------
		if nil ~= nodes.pValueNode then
			if pdata.pquality ~= nodes.pValueNode:getTag() then
				nodes.pValueNode:removeFromParent()
				self.viewData.breakLayer.petpNodes[index].pValueNode = nil
			else
				nodes.pValueNode:setString(math.floor(pdata.pvalue))
				nodes.pValueNode:setPosition(cc.p(
					nodes.bgNode:getContentSize().width - 30,
					utils.getLocalCenter(nodes.bgNode).y - 2
				))
			end
		end

		if nil == nodes.pValueNode then
			-- 属性值
			local pValueNode = CLabelBMFont:create(
				math.floor(pdata.pvalue),
				petMgr.GetPetPropFontPath(pdata.pquality)
			)
			pValueNode:setBMFontSize(24)
			pValueNode:setAnchorPoint(cc.p(1, 0.5))
			pValueNode:setPosition(cc.p(
				nodes.bgNode:getContentSize().width - 30,
				utils.getLocalCenter(nodes.bgNode).y - 2
			))
			nodes.bgNode:addChild(pValueNode, 5)
			pValueNode:setTag(pdata.pquality)

			self.viewData.breakLayer.petpNodes[index].pValueNode = pValueNode
		end
		------------ 属性值 ------------
	end
end
--[[
刷新属性预览 -> {bgNode = nil, lockNode = nil, pNameNode = nil, pValueNode = nil, pChangeNode = nil, pValuePreviewNode = nil}
@params pdata list 属性信息集合
@params breakLevel int 强化等级
@params characterId int 性格id
--]]
function PetUpgradeLayer:RefreshPetAllPPreview(pdata, breakLevel, characterId)
	for i,v in ipairs(pdata) do
		if v.unlock then
			self:RefreshPetAPPreview(i, v, breakLevel, characterId)
		end
	end
end
--[[
刷新单条属性预览
@params index int 属性序号
@params pdata table 单条属性信息
@params breakLevel int 强化等级
@params characterId int 性格id
--]]
function PetUpgradeLayer:RefreshPetAPPreview(index, pdata, breakLevel, characterId)
	local nodes = self.viewData.breakLayer.petpNodes[index]

	-- 计算修正后属性值
	local pGrowValue = math.floor(petMgr.GetPetFixedPByPetId(
		self.petId,
		pdata.ptype,
		pdata.pvalue,
		pdata.pquality,
		breakLevel,
		characterId,
		false,
		checkint(pdata.isEvolution)
	))

	------------ 属性变化图标 ------------
	if nil == nodes.pChangeNode then
		local pChangeNode = display.newNSprite(_res('ui/pet/card_skill_ico_sword.png'), 0, 0)
		display.commonUIParams(pChangeNode, {po = cc.p(
			nodes.bgNode:getContentSize().width * 0.725,
			utils.getLocalCenter(nodes.bgNode).y
		)})
		nodes.bgNode:addChild(pChangeNode)

		self.viewData.breakLayer.petpNodes[index].pChangeNode = pChangeNode
	else
		nodes.pChangeNode:setVisible(true)
	end
	------------ 属性变化图标 ------------

	------------ 属性变化值 ------------
	if nil ~= nodes.pValuePreviewNode then
		if pdata.pquality ~= nodes.pValuePreviewNode:getTag() then
			nodes.pValuePreviewNode:removeFromParent()
			self.viewData.breakLayer.petpNodes[index].pValuePreviewNode = nil
		else
			nodes.pValuePreviewNode:setString(pGrowValue)
			nodes.pValueNode:setPosition(cc.p(
				nodes.bgNode:getContentSize().width - 30,
				utils.getLocalCenter(nodes.bgNode).y - 2
			))
			nodes.pValuePreviewNode:setVisible(true)
		end
	end

	if nil == nodes.pValuePreviewNode then
		-- 属性值
		local pValuePreviewNode = CLabelBMFont:create(
			pGrowValue,
			petMgr.GetPetPropFontPath(pdata.pquality)
		)
		pValuePreviewNode:setBMFontSize(24)
		pValuePreviewNode:setAnchorPoint(cc.p(0, 0.5))
		pValuePreviewNode:setPosition(cc.p(
			nodes.pChangeNode:getPositionX() + nodes.pChangeNode:getContentSize().width * 0.5 + 5,
			utils.getLocalCenter(nodes.bgNode).y - 2
		))
		nodes.bgNode:addChild(pValuePreviewNode, 5)
		pValuePreviewNode:setTag(pdata.pquality)

		self.viewData.breakLayer.petpNodes[index].pValuePreviewNode = pValuePreviewNode
	end
	------------ 属性变化值 ------------

	------------ 属性值 ------------
	nodes.pValueNode:setPosition(cc.p(
		nodes.pChangeNode:getPositionX() - nodes.pChangeNode:getContentSize().width * 0.5 - 5,
		utils.getLocalCenter(nodes.bgNode).y - 2
	))
	------------ 属性值 ------------

end
--[[
清除属性预览 -> {bgNode = nil, lockNode = nil, pNameNode = nil, pValueNode = nil, pChangeNode = nil, pValuePreviewNode = nil}
--]]
function PetUpgradeLayer:ClearPetPPreview()
	for i, nodes in ipairs(self.viewData.breakLayer.petpNodes) do
		------------ 属性值 ------------
		if nil ~= nodes.pValueNode then
			nodes.pValueNode:setPosition(cc.p(
				nodes.bgNode:getContentSize().width - 30,
				utils.getLocalCenter(nodes.bgNode).y - 2
			))
		end
		------------ 属性值 ------------

		------------ 属性预览图标 ------------
		if nil ~= nodes.pChangeNode then
			nodes.pChangeNode:setVisible(false)
		end
		------------ 属性预览图标 ------------

		------------ 属性预览值 ------------
		if nil ~= nodes.pValuePreviewNode then
			nodes.pValuePreviewNode:setVisible(false)
		end
		------------ 属性预览值 ------------
	end
end
--[[
刷新突破等级
@params breakLevel int 强化等级
--]]
function PetUpgradeLayer:RefreshBreakMainPetLevel(breakLevel)
	local petConfig = petMgr.GetPetConfig(self.petId)
	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	--self.viewData.breakLayer.mainPetBreakLabel:setString(string.format('%s +%d', petConfig.name, breakLevel))

	local strProbability = petMgr.GetBreakProbabilityConfig(breakLevel)
	if strProbability == 0 then
		self.viewData.breakLayer.probabilityLabel:setString('')
		self.viewData.breakLayer.characterLabel:setString('')
	else
		if checkint(mainPetData.breakLevel) == checkint(breakLevel) then
			self.viewData.breakLayer.probabilityLabel:setString('')
		else
			self.viewData.breakLayer.probabilityLabel:setString( string.fmt(__('强化成功率 _num_%'),{_num_ = strProbability}))
		end

	 	local characterConfig = CommonUtils.GetConfig('pet', 'petCharacter', mainPetData.character)
	 	local characterStr = string.format(__('性格:%s'), characterConfig.name)
	 	self.viewData.breakLayer.characterLabel:setString(characterStr)
	end
end
--[[
刷新突破消耗
@params breakLevel int 突破等级
--]]
function PetUpgradeLayer:RefreshBreakCost(breakLevel)
	if breakLevel > petMgr.GetPetMaxBreakLevelById(self.mainId) then
		-- 超过最大强化等级
		if nil ~= self.viewData.breakLayer.breakCostLabel then
			self.viewData.breakLayer.breakCostLabel:setVisible(false)
		end

		if nil ~= self.viewData.breakLayer.breakCostIcon then
			self.viewData.breakLayer.breakCostIcon:setVisible(false)
		end

		return
	end
	local breakCostGoldConfig = nil
	local breakCostUniversalConfig = nil 
	for i, v in pairs(petMgr.GetBreakCostConfig(breakLevel)) do
		if checkint(v.goodsId) == GOLD_ID then
			breakCostGoldConfig = v
		elseif checkint(v.goodsId) == EVOLUTION_STONE_ID then
			breakCostUniversalConfig = v
		end
	end

	if breakCostUniversalConfig then
		--local consumeGoodNode = self.viewData.breakLayer.consumeGoodNode
		local consumeLabel = self.viewData.breakLayer.consumeLabel
		local countNum = CommonUtils.GetCacheProductNum(EVOLUTION_STONE_ID)
		display.commonLabelParams(consumeLabel , fontWithColor('10', { color = '#fffffff' , text = string.format('%d/%d', countNum ,breakCostUniversalConfig.num )}))
	end
	------------ 强化消耗数量 ------------
	local costLabel = self.viewData.breakLayer.breakCostLabel
	local costIcon = self.viewData.breakLayer.breakCostIcon
	if not  breakCostGoldConfig then
		if costLabel ~=nil  then
			costLabel:setVisible(false)
		end
		if costIcon ~=nil  then
			costIcon:setVisible(false)
		end
		return 
	end
	if nil == costLabel then
		costLabel = display.newLabel(0, 0, fontWithColor('14', {text = breakCostGoldConfig.num}))
		self.viewData.breakLayer.root:addChild(costLabel, 5)

		self.viewData.breakLayer.breakCostLabel = costLabel
	else
		costLabel:setString(breakCostGoldConfig.num)
	end
	costLabel:setVisible(true)
	------------ 强化消耗数量 ------------

	------------ 强化消耗道具 ------------

	local scale = 0.25
	if nil == costIcon then
		costIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(breakCostGoldConfig.goodsId)), 0, 0)
		self.viewData.breakLayer.root:addChild(costIcon, 5)		

		self.viewData.breakLayer.breakCostIcon = costIcon
	else
		costIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(breakCostGoldConfig.goodsId)))
	end
	costIcon:setScale(scale)
	costIcon:setVisible(true)
	------------ 强化消耗道具 ------------

	display.setNodesToNodeOnCenter(self.viewData.breakLayer.breakBtn, {costLabel, costIcon}, {y = -15})
end
--[[
	刷新突破界面的道具消耗
--]]
function PetUpgradeLayer:RefreshBreakLayerGoods()
	-- 只有该对象存在的时候才会刷新
	if  self.viewData.breakLayer then
		local breakLayer = self.viewData.breakLayer
		local consumeLabel = breakLayer.consumeLabel
		-- 刷新异化石
		self:RefreshBreakUniveralPet()
		if consumeLabel and (not tolua.isnull(consumeLabel)) then
			local mainPetData = gameMgr:GetPetDataById(self.mainId)
			local breakLevel = checkint(mainPetData.breakLevel) +1
			local petConfig = petMgr.GetPetConfig(mainPetData.petId)
			if checkint(petConfig.type) == PetType.BOSS  then
				if breakLevel > 20  then
					return
				end
			end
			local ownEvolutionNum = CommonUtils.GetCacheProductNum(EVOLUTION_STONE_ID)
			local evolutionNum =  0
			for i, v in pairs(petMgr.GetBreakCostConfig(breakLevel) or {}) do
				if checkint(v.goodsId) == EVOLUTION_STONE_ID then
					evolutionNum = v.num
				end
			end
			display.commonLabelParams(consumeLabel,  fontWithColor('10',{color = '#ffffff' , text = string.format('%d/%d',ownEvolutionNum , evolutionNum )}))
		end
	end
end
--[[
	刷新异化界面的道具数量
--]]
function PetUpgradeLayer:RefreshEvolutionLayerGoods()
	if  self.viewData.evoltionLayer then
		local breakLayer = self.viewData.evoltionLayer
		local costGoodsLabel = breakLayer.costGoodsLabel
		local mainPetData = gameMgr:GetPetDataById(self.mainId)
		local petId = mainPetData.petId
		-- 刷新异化石
		local costGoods = petMgr.GetEvoltuionCostConfig(petId)
		for i, v in pairs(costGoods) do
			if checkint(v.goodsId) == EVOLUTION_STONE_ID  then
				local needNum  =  v.num
				local ownNum = CommonUtils.GetCacheProductNum(v.goodsId)
				display.commonLabelParams(costGoodsLabel , {text = string.format("%d/%d" , checkint(ownNum) ,checkint(needNum) ) })
			end
		end
	end
end


--[[
强化成功
@params pets list 堕神数据集
@params success bool 是否强化成功
--]]
function PetUpgradeLayer:DoBreakLevel(pets, success)
	------------ data ------------
	-- 清空列表选择状态
	self:ClearBreakPetSelected()
	------------ data ------------

	------------ view ------------
	-- 清空插槽选择状态
	self:RefreshBreakMaterialSlotByIndex(1, nil)
	-- 刷新一次列表
	self:RefreshBreakLayerGridView(pets)
	self:RefreshBreakPow()
	local petData = gameMgr:GetPetDataById(self.mainId)
	local petpData = petMgr.GetPetAllFixedProps(self.mainId)
	-- 刷新主pet突破等级
	--self:RefreshBreakMainPetLevel(petData.breakLevel)
	-- 清空属性预览
	self:ClearPetPPreview()

	self:RefreshBreakMainPetLevel(petData.breakLevel)

	-- -- 刷新属性
	self:RefreshPetAllPData(petpData)
	self:RefreshBreakLevel()
	self.viewData.breakLayer.ShowNoPetMaterial(0 >= #self.breakPets)
	local mainPetData = gameMgr:GetPetDataById(self.mainId)
	local deltaBreakLevel = petMgr.GetDeltaBreakLevel()

	-- 达到满强化后不刷新属性预览
	if checkint(mainPetData.breakLevel) < petMgr.GetPetMaxBreakLevelById(self.mainId) then
		self:RefreshPetAllPPreview(
			petMgr.GetPetAllBaseProps(self.mainId),
			mainPetData.breakLevel + deltaBreakLevel,
			checkint(mainPetData.character)
		)
	end

	self:RefreshBreakConsumeShow()
	-- 刷新突破消耗
	self:RefreshBreakCost(checkint(petData.breakLevel) + 1)

	if success then
		PlayAudioClip(AUDIOS.UI.ui_star.id)
		PlayAudioClip(AUDIOS.UI.ui_strengthen_success.id)
		
		-- 强化动画
		local breakUpgradeSpine = self.viewData.breakLayer.breakUpgradeSpine
		if nil == breakUpgradeSpine then
			breakUpgradeSpine = sp.SkeletonAnimation:create(
				'effects/pet/shengxing.json',
				'effects/pet/shengxing.atlas',
				1
			)
			breakUpgradeSpine:setPosition(cc.p(
				self.viewData.breakLayer.dynamicAvatar:getPositionX(),
				self.viewData.breakLayer.dynamicAvatar:getPositionY() + self.viewData.breakLayer.dynamicAvatar:getContentSize().height * 0.2
			))
			self.viewData.breakLayer.dynamicAvatar:getParent():addChild(
				breakUpgradeSpine,
				self.viewData.breakLayer.dynamicAvatar:getLocalZOrder()
			)

			self.viewData.breakLayer.breakUpgradeSpine = breakUpgradeSpine
		end

		breakUpgradeSpine:setToSetupPose()
		breakUpgradeSpine:setAnimation(0, 'play1', false)


		local breakUpradeMessSpine = self.viewData.breakLayer.breakUpradeMessSpine
		if nil == breakUpradeMessSpine then
			breakUpradeMessSpine = sp.SkeletonAnimation:create(
				'effects/chooseBattle/bd2.json',
				'effects/chooseBattle/bd2.atlas',
				0.8
			)
			breakUpradeMessSpine:setRotation(90)
			breakUpradeMessSpine:setPosition(cc.p(
				self.viewData.breakLayer.breakBtn:getPositionX(),
				self.viewData.breakLayer.breakBtn:getPositionY() + 140 + self.viewData.breakLayer.breakBtn:getContentSize().height * 0.2
			))

			self.viewData.breakLayer.breakBtn:getParent():addChild(
				breakUpradeMessSpine,
				100
			)

			self.viewData.breakLayer.breakUpradeMessSpine = breakUpradeMessSpine
		end

		breakUpradeMessSpine:setToSetupPose()
		breakUpradeMessSpine:setAnimation(0, 'play', false)

	else
		PlayAudioClip(AUDIOS.UI.ui_strengthen_failure.id)

		local nodes = self.viewData.breakLayer.materialBtns[1]
		local slotNode = nodes.slotNode

		local breakUpFailSpine = self.viewData.breakLayer.breakUpFailSpine
			if nil == breakUpFailSpine then
			local pos = cc.p(
				slotNode:getPositionX(),
				slotNode:getPositionY() + slotNode:getContentSize().height * 0.2
			)

			breakUpFailSpine = sp.SkeletonAnimation:create(
				'effects/pet/pet_awake_fail.json',
				'effects/pet/pet_awake_fail.atlas',
				1
			)
			breakUpFailSpine:setPosition(pos)
			slotNode:getParent():addChild(
				breakUpFailSpine,
				100
			)

			self.viewData.breakLayer.breakUpFailSpine = breakUpFailSpine
		end

		breakUpFailSpine:setToSetupPose()
		breakUpFailSpine:setAnimation(0, 'play1', false)
	end

	------------ view ------------
end
--[[
/***********************************************************************************************************************************\
 * prop layer
\***********************************************************************************************************************************/
--]]
--[[
刷新所有洗炼属性按钮
@params pdata list 属性信息集合
--]]
function PetUpgradeLayer:RefreshPropAllPBtn(pdata)
	for i,v in ipairs(pdata) do
		self:RefreshPropAPBtn(i, v)
	end
end
--[[
刷新单条属性按钮 -> {pBtnNode = nil, pNameNode = nil, pValueNode}
@params index int 属性序号
@params pdata table 单条属性信息
--]]
function PetUpgradeLayer:RefreshPropAPBtn(index, pdata)
	local nodes = self.viewData.propLayer.pBtns[index]
	if nodes == nil then return end
	
	nodes.pBtnNode:setEnabled(pdata.unlock)

	------------ 属性名字 ------------
	local pNameNode = nodes.pNameNode
	if nil == pNameNode then
		pNameNode = display.newLabel(0, 0, fontWithColor('4', {text = PetPConfig[pdata.ptype].name}))
		display.commonUIParams(pNameNode, {ap = cc.p(0, 0.5), po = cc.p(
			35,
			nodes.pBtnNode:getContentSize().height * 0.5
		)})
		nodes.pBtnNode:addChild(pNameNode)

		self.viewData.propLayer.pBtns[index].pNameNode = pNameNode
	else
		pNameNode:setString(PetPConfig[pdata.ptype].name)
	end
	local pNameNodeSize = display.getLabelContentSize(pNameNode)
	local scale = 120 /  pNameNodeSize.width  > 1 and 1 or  (120 /  pNameNodeSize.width)
	local currentScale =  pNameNode:getScale()
	pNameNode:setScale(scale * currentScale)
	pNameNode:setVisible(pdata.unlock)
	------------ 属性名字 ------------

	------------ 属性值 ------------
	local pValueNode = nodes.pValueNode

	if nil ~= pValueNode and pdata.pquality ~= pValueNode:getTag() then
		pValueNode:removeFromParent()
		pValueNode = nil
	end
	if nil == pValueNode then
		pValueNode = CLabelBMFont:create(
			math.floor(pdata.pvalue),
			petMgr.GetPetPropFontPath(pdata.pquality)
		)
		pValueNode:setBMFontSize(20)
		pValueNode:setAnchorPoint(cc.p(1, 0.5))
		pValueNode:setPosition(cc.p(
			nodes.pBtnNode:getContentSize().width - 35,
			pNameNode:getPositionY()
		))
		nodes.pBtnNode:addChild(pValueNode, 5)
		pValueNode:setTag(pdata.pquality)

		self.viewData.propLayer.pBtns[index].pValueNode = pValueNode
	else
		pValueNode:setString(math.floor(pdata.pvalue))
	end
	pValueNode:setVisible(pdata.unlock)
	------------ 属性值 ------------

	------------ 提示 ------------
	local unlockNode = nodes.unlockNode
	if nil == unlockNode then
		unlockNode = display.newLabel(0, 0, fontWithColor('6', {text = string.format(__('%d级解锁'), petMgr.GetPetPInfo()[index].unlockLevel)}))
		display.commonUIParams(unlockNode, {po = utils.getLocalCenter(nodes.pBtnNode)})
		nodes.pBtnNode:addChild(unlockNode)

		self.viewData.propLayer.pBtns[index].unlockNode = unlockNode
	end
	unlockNode:setVisible(not pdata.unlock)
	------------ 提示 ------------
end
--[[
根据序号选择需要洗炼的属性
@params index int 序号
--]]
function PetUpgradeLayer:RefreshRecastPropByIndex(index)

	if nil ~= index then
		local curNode = self.viewData.propLayer.pBtns[index]
		if nil ~= curNode then
			curNode.pBtnNode:setChecked(true)
		end
	end

	if index == self.selectedPropIndex then return end

	if nil ~= self.selectedPropIndex then
		local preNode = self.viewData.propLayer.pBtns[self.selectedPropIndex]
		if nil ~= preNode then
			preNode.pBtnNode:setChecked(false)
		end
	end

	self.selectedPropIndex = index

	-- 刷新预览版
	if nil ~= index then
		self:RefreshPropDial()
	end

end
--[[
刷新洗炼消耗
@params costNum int 消耗数量
@params goodsNum int 道具数量
--]]
function PetUpgradeLayer:RefreshPropRecastCost(costNum, goodsNum)
	if self.viewData.propLayer and (not tolua.isnull(self.viewData.propLayer.recastCostLabel)) then
		self.viewData.propLayer.recastCostLabel:setString(string.format('%d/%d', costNum, goodsNum))
		display.setNodesToNodeOnCenter(
				self.viewData.propLayer.propBtn,
				{self.viewData.propLayer.recastCostLabel, self.viewData.propLayer.recastCostIcon},
				{y = -15}
		)
	end
end
--[[
刷新转盘属性
--]]
function PetUpgradeLayer:RefreshPropDial()
	self:RefreshPropDialLeft()
	self:RefreshPropDialRight()
end
--[[
刷新转盘正面属性左部分
--]]
function PetUpgradeLayer:RefreshPropDialLeft()
	local frontAmount = randompFrontAmount + randompBehindAmount

	local nodes = self.viewData.propLayer.dialLeftNodes
	local fixedPos = self.viewData.propLayer.fixedPos
	local parentNode = self.viewData.propLayer.propClipNode
	-- local parentNode = self.viewData.propLayer.root

	local node = nil

	for i = 1, frontAmount do
		node = nodes[i]

		local randomPetPType = petMgr.GetRandomPropType()
		local name = PetPConfig[randomPetPType].name

		if nil == node then
			-- 背景node
			local bgNode = display.newImageView(_res('ui/pet/pet_fresh_bg_list.png'), 0, 0)
			display.commonUIParams(bgNode, {po = cc.p(
				fixedPos.leftCoverPos.x,
				fixedPos.leftCoverPos.y + (frontAmount * 0.5 - (i - 0.5)) * bgNode:getContentSize().height
			)})
			parentNode:addChild(bgNode, 99)

			if i == frontAmount then
				self.viewData.propLayer.fixedPos.dialLeftBottomY = bgNode:getPositionY()
			elseif 1 == i then
				self.viewData.propLayer.fixedPos.dialLeftTopY = bgNode:getPositionY()
			end

			-- 文字node
			local labelNode = display.newLabel(0, 0, fontWithColor('1', {text = tostring(name)}))
			display.commonUIParams(labelNode, {po = utils.getLocalCenter(bgNode)})
			bgNode:addChild(labelNode)

			self.viewData.propLayer.dialLeftNodes[i] = {bgNode = bgNode, labelNode = labelNode, ptype = randomPetPType}
		else
			-- 刷新一次属性类型
			self.viewData.propLayer.dialLeftNodes[i].labelNode:setString(tostring(name))
			self.viewData.propLayer.dialLeftNodes[i].ptype = randomPetPType
		end
	end
end
--[[
刷新转盘正面属性右部分
--]]
function PetUpgradeLayer:RefreshPropDialRight()
	local petData = gameMgr:GetPetDataById(self.mainId)

	local frontAmount = randompFrontAmount + randompBehindAmount

	local nodes = self.viewData.propLayer.dialRightNodes
	local fixedPos = self.viewData.propLayer.fixedPos
	local parentNode = self.viewData.propLayer.propClipNode


	-- local parentNode = self.viewData.propLayer.root

	local node = nil
	for i = 1, frontAmount do
		node = nodes[i]
		local randompvalue, randompquality, randomptype = petMgr.GetRandomPropValue(self.petId, self.selectedPropIndex)
		local fixedpvalue = math.floor(petMgr.GetPetFixedPByPetId(
			self.petId,
			randomptype,
			randompvalue,
			randompquality,
			checkint(petData.breakLevel),
			checkint(petData.character),
			false,
			checkint(petData.isEvolution)
		))
		if nil == node then
			-- 背景node
			local bgNode = display.newImageView(_res('ui/pet/pet_fresh_bg_list.png'), 0, 0)
			display.commonUIParams(bgNode, {po = cc.p(
				fixedPos.rightCoverPos.x,
				fixedPos.rightCoverPos.y + (frontAmount * 0.5 - (i - 0.5)) * bgNode:getContentSize().height
			)})
			parentNode:addChild(bgNode, 99)

			if i == frontAmount then
				self.viewData.propLayer.fixedPos.dialRightBottomY = bgNode:getPositionY()
			elseif 1 == i then
				self.viewData.propLayer.fixedPos.dialRightTopY = bgNode:getPositionY()
			end

			-- 文字node
			local labelNode = CLabelBMFont:create(
				fixedpvalue,
				petMgr.GetPetPropFontPath(randompquality)
			)
			labelNode:setBMFontSize(28)
			labelNode:setAnchorPoint(cc.p(0.5, 0.5))
			labelNode:setPosition(utils.getLocalCenter(bgNode))
			bgNode:addChild(labelNode)
			labelNode:setTag(randompquality)

			self.viewData.propLayer.dialRightNodes[i] = {bgNode = bgNode, labelNode = labelNode, pvalue = fixedpvalue, pquality = randompquality}
		else
			if randompquality ~= node.labelNode:getTag() then
				node.labelNode:removeFromParent()

				local labelNode = CLabelBMFont:create(
					fixedpvalue,
					petMgr.GetPetPropFontPath(randompquality)
				)
				labelNode:setBMFontSize(28)
				labelNode:setAnchorPoint(cc.p(0.5, 0.5))
				labelNode:setPosition(utils.getLocalCenter(node.bgNode))
				node.bgNode:addChild(labelNode)
				labelNode:setTag(randompquality)

				self.viewData.propLayer.dialRightNodes[i].labelNode = labelNode
			else
				node.labelNode:setString(fixedpvalue)
			end

			self.viewData.propLayer.dialRightNodes[i].pvalue = fixedpvalue
			self.viewData.propLayer.dialRightNodes[i].pquality = randompquality
		end
	end


end
--[[
做转盘动画
@params pindex int 属性序号
@params ptype PetP 属性类型
@params pvalue number 属性基础值
@params pquality PetPQuality 属性品质
--]]
function PetUpgradeLayer:DoPropUpgrade(pindex, ptype, pvalue, pquality)
	-- -- 刷新单条属性
	-- local petPData = petMgr.GetPetAllFixedProps(self.mainId)
	-- self:RefreshPropAPBtn(pindex, petPData[pindex])
	local desLabel = self.viewData.propLayer.desLabel
	local oriScale = self.viewData.propLayer.desLabelScale
	desLabel:stopAllActions()
	desLabel:setScale(oriScale)
	desLabel:setString('')
	-- 获取当前属性预览转盘对应的左右目标值
	local targetIndexLeft, targetIndexRight = self:GetTargetDialIndex(pindex, ptype, pvalue, pquality)
	self.dialLeftAnimationConf.targetIndexLeft = targetIndexLeft
	self.dialLeftAnimationConf.targetIndexRight = targetIndexRight

	-- self:FixDialPosition(targetIndexLeft, targetIndexRight)

	self:StartDialAnimation(targetIndexLeft, targetIndexRight)
end
--[[
根据目标属性信息获取左右对应的目标值
@params pindex int 属性序号
@params ptype PetP 属性类型
@params pvalue number 属性基础值
@params pquality PetPQuality 属性品质
@return left, right int, int 左右目标值
--]]
function PetUpgradeLayer:GetTargetDialIndex(pindex, ptype, pvalue, pquality)
	local left = self:GetTargetDialIndexLeft(ptype)
	local right = self:GetTargetDialIndexRight(pvalue, pquality, ptype)

	return left, right
end
--[[
根据目标属性信息获取左对应的目标值
@params ptype PetP 属性类型
@return left 左目标值
--]]
function PetUpgradeLayer:GetTargetDialIndexLeft(ptype)
	local left = nil
	local nodes = self.viewData.propLayer.dialLeftNodes
	--[[
	{
		{bgNode = bgNode, labelNode = labelNode, ptype = randomPetPType},
		{bgNode = bgNode, labelNode = labelNode, ptype = randomPetPType},
		...
	}
	--]]

	local stencilNode = self.viewData.propLayer.propClipNode:getStencil()
	local topY = stencilNode:getPositionY() + stencilNode:getContentSize().height * 0.5
	local bottomY = stencilNode:getPositionY() - stencilNode:getContentSize().height * 0.5
	local hidedNodesIndex = {}

	for i,v in ipairs(nodes) do
		if ptype == v.ptype then
			left = i
			break
		end

		-- 判断是否是可以暗改的节点
		if topY < v.bgNode:getPositionY() - v.bgNode:getContentSize().height * 0.5 or
			bottomY > v.bgNode:getPositionY() + v.bgNode:getContentSize().height * 0.5 then
			-- 插入暗改节点idx
			table.insert(hidedNodesIndex, i)
		end
	end

	-- 如果未找到可以让转盘定位的节点 暗改一个节点
	if nil == left then
		local randomChangeNodeIndex = hidedNodesIndex[math.random(#hidedNodesIndex)]
		local node = nodes[randomChangeNodeIndex]

		-- 暗改描述和数据
		node.labelNode:setString(PetPConfig[ptype].name)
		self.viewData.propLayer.dialLeftNodes[randomChangeNodeIndex].ptype = ptype

		left = randomChangeNodeIndex
	end

	return left
end
--[[
根据目标属性信息获取右对应的目标值
@params pvalue number 属性基础值
@params pquality PetPQuality 属性品质
@params ptype PetP 属性类型
@return right 右目标值
--]]
function PetUpgradeLayer:GetTargetDialIndexRight(pvalue, pquality, ptype)
	local right = nil
	local nodes = self.viewData.propLayer.dialRightNodes
	--[[
	{
		{bgNode = bgNode, labelNode = labelNode, pvalue = randompvalue, pquality = randompquality},
		{bgNode = bgNode, labelNode = labelNode, pvalue = randompvalue, pquality = randompquality},
		...
	}
	--]]

	local stencilNode = self.viewData.propLayer.propClipNode:getStencil()
	local topY = stencilNode:getPositionY() + stencilNode:getContentSize().height * 0.5
	local bottomY = stencilNode:getPositionY() - stencilNode:getContentSize().height * 0.5
	local hidedNodesIndex = {}

	local petData = gameMgr:GetPetDataById(self.mainId)
	local fixedpvalue = math.floor(petMgr.GetPetFixedPByPetId(
		self.petId,
		ptype,
		pvalue,
		pquality,
		checkint(petData.breakLevel),
		checkint(petData.character),
		false,
		checkint(petData.isEvolution)
	))

	for i,v in ipairs(nodes) do
		if fixedpvalue == v.pvalue and pquality == v.pquality then
			right = i
			break
		end

		-- 判断是否是可以暗改的节点
		if topY < v.bgNode:getPositionY() - v.bgNode:getContentSize().height * 0.5 or
			bottomY > v.bgNode:getPositionY() + v.bgNode:getContentSize().height * 0.5 then
			-- 插入暗改节点idx
			table.insert(hidedNodesIndex, i)
		end
	end

	-- 如果未找到可以让转盘定位的节点 暗改一个节点
	if nil == right then
		-- 暗改描述和数据
		local randomChangeNodeIndex = hidedNodesIndex[math.random(#hidedNodesIndex)]
		local node = nodes[randomChangeNodeIndex]

		if pquality ~= node.labelNode:getTag() then
			node.labelNode:removeFromParent()

			local labelNode = CLabelBMFont:create(
				tostring(fixedpvalue),
				petMgr.GetPetPropFontPath(pquality)
			)
			labelNode:setBMFontSize(28)
			labelNode:setAnchorPoint(cc.p(0.5, 0.5))
			labelNode:setPosition(utils.getLocalCenter(node.bgNode))
			node.bgNode:addChild(labelNode)
			labelNode:setTag(pquality)

			self.viewData.propLayer.dialRightNodes[randomChangeNodeIndex].labelNode = labelNode
		else
			node.labelNode:setString(tostring(fixedpvalue))
		end

		self.viewData.propLayer.dialRightNodes[randomChangeNodeIndex].pvalue = fixedpvalue
		self.viewData.propLayer.dialRightNodes[randomChangeNodeIndex].pquality = pquality

		right = randomChangeNodeIndex
	end
	return right

end
--[[
跳过转盘动画
--]]
function PetUpgradeLayer:SkipDialAnimation()
	self:OverDialAnimationLeft()
	self:OverDialAnimationRight()

	self:FixDialPosition(self.dialLeftAnimationConf.targetIndexLeft, self.dialLeftAnimationConf.targetIndexRight)
end
--[[
根据目标单元序号做转盘动画
@params leftIndex int 左序号
@params rightIndex int 右序号
--]]
function PetUpgradeLayer:StartDialAnimation(leftIndex, rightIndex)
	PlayAudioClip(AUDIOS.UI.ui_regenerate_loop.id)
	self.playedReadyEndSoundEffect = false

	self.viewData.propLayer.skipDialBtn:setVisible(true)

	if nil == self.animationUpdateHandler then
		self.animationUpdateHandler = scheduler.scheduleUpdateGlobal(handler(self, self.Update))
	end

	self:StartDialAnimationLeft(leftIndex)
	self:StartDialAnimationRight(rightIndex)
end
--[[
开始左侧转盘动画
@params index int 需要对准的指针的序号
--]]
function PetUpgradeLayer:StartDialAnimationLeft(index)
	-- 开始动画
	self.dialLeftAnimationConf.moveTimeLeft = math.random(1.5, 2)
	self.dialMoveTimerLeft = self.dialLeftAnimationConf.moveTimeLeft
	self.moveYPerFrameLeft = self.dialLeftAnimationConf.moveYPerFrame
	self.dialAnimationLeftStart = true
end
--[[
开始右侧转盘动画
@params index int 需要对准指针的序号
--]]
function PetUpgradeLayer:StartDialAnimationRight(index)
	-- 开始动画
	self.dialLeftAnimationConf.moveTimeRight = self.dialLeftAnimationConf.moveTimeLeft + 0.5
	self.dialMoveTimerRight = self.dialLeftAnimationConf.moveTimeRight
	self.moveYPerFrameRight = self.dialLeftAnimationConf.moveYPerFrame
	self.dialAnimationRightStart = true
end
--[[
停止转盘动画
--]]
function PetUpgradeLayer:OverDialAnimation()
	StopAudioClip(AUDIOS.UI.name)
	PlayAudioClip(AUDIOS.UI.ui_regenerate_result.id)

	-- 刷新单条属性
	local petPData = petMgr.GetPetAllFixedProps(self.mainId)
	self:RefreshPropAPBtn(self.selectedPropIndex, petPData[self.selectedPropIndex])

	local desLabel = self.viewData.propLayer.desLabel
	local oriScale = self.viewData.propLayer.desLabelScale

	desLabel:runAction(cc.Sequence:create(
		cc.ScaleTo:create(0.2, oriScale * 1.5),
		cc.ScaleTo:create(0.2, oriScale)
	))
	desLabel:setString(tostring(PROPERTY_DESC[checkint(checktable(petPData[self.selectedPropIndex]).pquality)]))

	self.viewData.propLayer.skipDialBtn:setVisible(false)
end
--[[
停止左转盘动画
--]]
function PetUpgradeLayer:OverDialAnimationLeft()
	self.dialMoveTimerLeft = 0
	self.moveYPerFrameLeft = 0
	self.dialAnimationLeftStart = false

	if not self.dialAnimationRightStart then
		self:OverDialAnimation()
	end
end
--[[
停止右转盘动画
--]]
function PetUpgradeLayer:OverDialAnimationRight()
	self.dialMoveTimerRight = 0
	self.moveYPerFrameRight = 0
	self.dialAnimationRightStart = false

	if not self.dialAnimationLeftStart then
		self:OverDialAnimation()
	end
end
--[[
刷新一次左格子位置
@params deltaY number 变化的y坐标
--]]
function PetUpgradeLayer:UpdateDialLeftByDeltaY(deltaY)
	local nodes = self.viewData.propLayer.dialLeftNodes
	local fixedPos = self.viewData.propLayer.fixedPos

	local y = nil
	local nextPosY = nil

	for i,v in ipairs(nodes) do
		if nil == nextPos then
			nextPosY = v.bgNode:getPositionY() + deltaY
		else
			nextPosY = nextPosY - v.bgNode:getContentSize().width
		end

		if fixedPos.dialLeftBottomY >= nextPosY then
			-- 超过底线修正位置
			nextPosY = nextPosY + (randompFrontAmount + randompBehindAmount) * v.bgNode:getContentSize().height
			self:ShakeArrowLeft()
		end

		v.bgNode:setPositionY(nextPosY)

		-- 判断是否需要停止动画
		if self.dialLeftAnimationConf.targetIndexLeft == i then
			if self.dialMoveTimerLeft <= -1.5 and
				math.abs(nextPosY - fixedPos.leftCoverPos.y) <= v.bgNode:getContentSize().height * 0.15 then
				self:OverDialAnimationLeft()
			end
		end

	end

end
--[[
刷新一次右格子位置
@params deltaY number 变化的y坐标
--]]
function PetUpgradeLayer:UpdateDialRightByDeltaY(deltaY)
	local nodes = self.viewData.propLayer.dialRightNodes
	local fixedPos = self.viewData.propLayer.fixedPos

	local y = nil
	local nextPosY = nil

	for i,v in ipairs(nodes) do
		if nil == nextPos then
			nextPosY = v.bgNode:getPositionY() + deltaY
		else
			nextPosY = nextPosY - v.bgNode:getContentSize().width
		end

		if fixedPos.dialRightBottomY >= nextPosY then
			-- 超过底线修正位置
			nextPosY = nextPosY + (randompFrontAmount + randompBehindAmount) * v.bgNode:getContentSize().height
			self:ShakeArrowRight()
		end

		v.bgNode:setPositionY(nextPosY)

		-- 判断是否需要停止动画
		if self.dialLeftAnimationConf.targetIndexRight == i then
			if self.dialMoveTimerRight <= -1.5 and
				math.abs(nextPosY - fixedPos.rightCoverPos.y) <= v.bgNode:getContentSize().height * 0.15 then
				self:OverDialAnimationRight()
			end
		end
	end

end
--[[
校准转盘格子左右位置 传入序号为对准指针序号
@params leftIndex int 左序号
@params rightIndex int 右序号
--]]
function PetUpgradeLayer:FixDialPosition(leftIndex, rightIndex)
	self:FixDialPositionLeft(leftIndex)
	self:FixDialPositionRight(rightIndex)
end
--[[
校准转盘格子左位置
@params index int 对准指针的序号
--]]
function PetUpgradeLayer:FixDialPositionLeft(index)
	local nodes = self.viewData.propLayer.dialLeftNodes
	local fixedPos = self.viewData.propLayer.fixedPos

	local nodesAmount = #nodes
	local idx = nil
	local centerIdx = (nodesAmount + 1) * 0.5

	for i,v in ipairs(nodes) do
		idx = ((i - index) + centerIdx - 1) % nodesAmount + 1
		display.commonUIParams(v.bgNode, {po = cc.p(
			v.bgNode:getPositionX(),
			fixedPos.leftCoverPos.y + (nodesAmount * 0.5 - (idx - 0.5)) * v.bgNode:getContentSize().height
		)})
	end
end
--[[
校准转盘格子右位置
@params index int 对准指针的序号
--]]
function PetUpgradeLayer:FixDialPositionRight(index)
	local nodes = self.viewData.propLayer.dialRightNodes
	local fixedPos = self.viewData.propLayer.fixedPos

	local nodesAmount = #nodes
	local idx = nil
	local centerIdx = (nodesAmount + 1) * 0.5

	for i,v in ipairs(nodes) do
		idx = ((i - index) + centerIdx - 1) % nodesAmount + 1
		display.commonUIParams(v.bgNode, {po = cc.p(
			v.bgNode:getPositionX(),
			fixedPos.leftCoverPos.y + (nodesAmount * 0.5 - (idx - 0.5)) * v.bgNode:getContentSize().height
		)})
	end
end
--[[
抖一次左指针
--]]
function PetUpgradeLayer:ShakeArrowLeft()
	local actionNode = self.viewData.propLayer.arrowL

	-- 恢复原状
	actionNode:stopAllActions()
	actionNode:setRotation(0)

	local actionSeq = cc.Sequence:create(
		cc.RotateTo:create(0.1, 30),
		cc.RotateTo:create(0.1, 0),
		cc.CallFunc:create(function ()
			-- self:ShakeArrowLeft()
		end)
	)
	actionNode:runAction(actionSeq)
end
--[[
抖一次右指针
--]]
function PetUpgradeLayer:ShakeArrowRight()
	local actionNode = self.viewData.propLayer.arrowR

	-- 恢复原状
	actionNode:stopAllActions()
	actionNode:setRotation(0)

	local actionSeq = cc.Sequence:create(
		cc.RotateTo:create(0.1, -30),
		cc.RotateTo:create(0.1, 0),
		cc.CallFunc:create(function ()
			-- self:ShakeArrowRight()
		end)
	)
	actionNode:runAction(actionSeq)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
--[[
tab页签按钮回调
--]]
function PetUpgradeLayer:TabBtnClickCallback(sender)
	PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id)
	local index = sender:getTag()
	if index == TabModuleType.EVOLUTION then
		local mainPetData = gameMgr:GetPetDataById(self.mainId)
		if checkint(mainPetData.breakLevel) >=10 then
			sender:setChecked(true)
		else
			sender:setChecked(false)
			uiMgr:ShowInformationTips(__("当前堕神强化等级未达到+10，无法进行异化。"))
			return
		end
	end
	AppFacade.GetInstance():DispatchObservers('PET_UPGRADE_CHANGE_TAB', {index = index})
end
--[[
升级页 狗粮槽按钮
--]]
function PetUpgradeLayer:LevelMaterialBtnClickCallback(sender)
	PlayAudioByClickNormal()
	local index = sender:getTag()
	AppFacade.GetInstance():DispatchObservers('LEVEL_SELECT_PET_SLOT', {index = index})
end
--[[
升级页 堕神头像按钮
--]]
function PetUpgradeLayer:LevelPetIconClickCallback(sender)
	PlayAudioByClickNormal()
	local index = sender:getParent():getTag()
	AppFacade.GetInstance():DispatchObservers('LEVEL_SELECT_PET_BY_PET_ICON', {index = index})
end
--[[
升级页 堕神升级按钮
--]]
function PetUpgradeLayer:LevelPetLevelClickCallback(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('LEVEL_UPGRADE')
end
--[[
升级页 堕神升级按钮
--]]
function PetUpgradeLayer:OneKeyLevelPetLevelClickCallback(sender)
	PlayAudioByClickNormal()
	--AppFacade.GetInstance():DispatchObservers('LEVEL_UPGRADE')
	AppFacade.GetInstance():DispatchObservers('ONE_KEY_LEVEL_UPGRADE')
end
--[[
升级页 排序按钮
--]]
function PetUpgradeLayer:LevelPetSortClickCallback(sender)
	PlayAudioByClickNormal()
	self.viewData.levelLayer.sortBoard:setVisible(not self.viewData.levelLayer.sortBoard:isVisible())
end

--[[
升级页 排序按钮
--]]
function PetUpgradeLayer:EvoltionClickHandler(sender)
	PlayAudioByClickNormal()
	local mainPetData =  gameMgr:GetPetDataById(self.mainId) or {}
	if checkint(mainPetData.isEvolution ) == 1 then
		uiMgr:ShowInformationTips(__('已经异化成功'))
	else
		local petId = mainPetData.petId
		local costGoods = petMgr.GetEvoltuionCostConfig(petId)

		if next(costGoods) ~= nil    then
			for i, v in pairs(costGoods) do
				local needNum  =  costGoods[1].num
				local ownNum = CommonUtils.GetCacheProductNum(v.goodsId)
				if ownNum < checkint(needNum) then
					if checkint(v.goodsId)  == GOLD_ID then
						uiMgr:ShowInformationTips(__('金币不足'))
					else
						uiMgr:ShowInformationTips(__('异化石不足'))
					end
					return
				end

			end
		end
		AppFacade.GetInstance():DispatchSignal(POST.PET_EVOLUTION.cmdName ,{playerPetId = self.mainId })
	end

end


--[[
强化页 堕神头像按钮
--]]
function PetUpgradeLayer:BreakPetIconClickCallback(sender)
	PlayAudioByClickNormal()
	local index = sender:getParent():getTag()
	AppFacade.GetInstance():DispatchObservers('BREAK_SELECT_PET_BY_PET_ICON', {index = index})
end
--[[
强化页 狗粮槽按钮
--]]
function PetUpgradeLayer:BreakMaterialBtnClickCallback(sender)
	PlayAudioByClickNormal()
	local index = sender:getTag()
	AppFacade.GetInstance():DispatchObservers('BREAK_SELECT_PET_SLOT', {index = index})
end
--[[
强化页 堕神强化按钮
--]]
function PetUpgradeLayer:BreakPetBreakClickCallback(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('BREAK_UPGRADE')
end
--[[
强化页 排序按钮
--]]
function PetUpgradeLayer:BreakPetSortClickCallback(sender)
	PlayAudioByClickNormal()
	self.viewData.breakLayer.sortBoard:setVisible(not self.viewData.breakLayer.sortBoard:isVisible())
end
--[[
属性按钮回调
--]]
function PetUpgradeLayer:PropPBtnClickCallback(sender)
	PlayAudioByClickNormal()
	local index = sender:getTag()
	self:RefreshRecastPropByIndex(index)
end
--[[
洗炼按钮回调
--]]
function PetUpgradeLayer:PropRecastClickCallback(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('PROP_RECAST', {resetAttrNum = self.selectedPropIndex})
end
---------------------------------------------------
-- click handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据堕神id获取对应的升级cell序号
@params id pet id
@return index int
--]]
function PetUpgradeLayer:GetLevelPetIndexById(id)
	for i,v in ipairs(self.levelPets) do
		if checkint(id) == v then
			return i
		end
	end
	return nil
end
--[[
根据堕神id获取对应的强化cell序号
@params id pet id
@return index int
--]]
function PetUpgradeLayer:GetBreakPetIndexById(id)
	for i,v in ipairs(self.breakPets) do
		if checkint(id) == v then
			return i
		end
	end
	return nil
end
--[[
根据堕神等级 经验获取经验条显示参数
@params level int 等级
@params exp int 经验
@return curValue, maxValue, curStr, maxStr int, int, string, string 当前值 最大值 当前显示文字 最大显示文字
--]]
function PetUpgradeLayer:GetExpBarParams(level, exp)
	local petMaxLevel = petMgr.GetPetMaxLevel()
	if level >= petMaxLevel then
		-- 达到最大等级
		local curNeedExp = petMgr.GetLevelUpNeedExpByLevel(level - 1)
		return curNeedExp, curNeedExp, __('max'), __('max')
	else
		-- 未达到最大等级
		local needExp = petMgr.GetLevelUpNeedExpByLevel(level)
		local curExp = petMgr.GetHasExpByLevelAndTotalExp(level, exp)
		return curExp, needExp, tostring(curExp), tostring(needExp)
	end
end

------------ 升级狗粮的选中状态 ------------
function PetUpgradeLayer:SetLevelPetSelectedById(id, selected)
	if selected then
		self.levelSelectedPets[tostring(id)] = true
	else
		self.levelSelectedPets[tostring(id)] = nil
	end
end
function PetUpgradeLayer:GetLevelPetSelectedById(id)
	return self.levelSelectedPets[tostring(id)]
end
function PetUpgradeLayer:ClearLevelPetSelected()
	for k,v in pairs(self.levelSelectedPets) do
		self:SetLevelPetSelectedById(checkint(k), false)
	end
end

------------ 强化狗粮的选中状态 ------------
function PetUpgradeLayer:SetBreakPetSelectedById(id, selected)
	if selected then
		self.breakSelectedPets[tostring(id)] = true
	else
		self.breakSelectedPets[tostring(id)] = nil
	end
end
--[[
	添加万能堕神
--]]
function PetUpgradeLayer:SetUniversalPetNum(PetNum)
	self.universalNum = PetNum
end

--[[
	获取万能堕神
--]]
function PetUpgradeLayer:GetUniversalPet()
	return self.universalNum
end
function PetUpgradeLayer:GetSelectPetNum()
	local selectNum =  table.nums(self.breakSelectedPets)
	local count = self:GetUniversalPet()
	return selectNum + count
end


--[[
	重置万能堕神
--]]
function PetUpgradeLayer:ResetUniversalPet()
	self.universalNum = 0
	return self.universalNum
end


function PetUpgradeLayer:GetBreakPetSelectedById(id)
	return self.breakSelectedPets[tostring(id)]
end
function PetUpgradeLayer:ClearBreakPetSelected()
	for k,v in pairs(self.breakSelectedPets) do
		self:SetBreakPetSelectedById(checkint(k), false)
	end
	self:ResetUniversalPet()
end


---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- update logic begin --
---------------------------------------------------
function PetUpgradeLayer:Update(dt)
	-- print('here check fuck mark', self.dialAnimationLeftStart, self.dialAnimationRightStart)

	if self.dialAnimationLeftStart then
		self.dialMoveTimerLeft = self.dialMoveTimerLeft - dt
		local moveY = self.moveYPerFrameLeft
		if 0 >= self.dialMoveTimerLeft then
			-- 该停了
			if not self.playedReadyEndSoundEffect then
				-- 停止转轮音效
				StopAudioClip(AUDIOS.UI.name)
				PlayAudioClip(AUDIOS.UI.ui_regenerate_end.id)
				self.playedReadyEndSoundEffect = true
			end
			self.moveYPerFrameLeft = math.min(-1, self.moveYPerFrameLeft + 0.1)
		end
		self:UpdateDialLeftByDeltaY(moveY)
	end

	if self.dialAnimationRightStart then
		self.dialMoveTimerRight = self.dialMoveTimerRight - dt
		local moveY = self.moveYPerFrameRight
		if 0 >= self.dialMoveTimerRight then
			-- 该停了
			if not self.playedReadyEndSoundEffect then
				-- 停止转轮音效
				StopAudioClip(AUDIOS.UI.name)
				PlayAudioClip(AUDIOS.UI.ui_regenerate_end.id)
				self.playedReadyEndSoundEffect = true
			end
			self.moveYPerFrameRight = math.min(-1, self.moveYPerFrameRight + 0.1)
		end
		self:UpdateDialRightByDeltaY(moveY)
	end
end
---------------------------------------------------
-- update logic end --
---------------------------------------------------
--[[
cocos2dx event handler
--]]
function PetUpgradeLayer:onEnter()

end
function PetUpgradeLayer:onExit()
	AppFacade.GetInstance():UnRegistObserver(EVENT_GOODS_COUNT_UPDATE, self)
end
function PetUpgradeLayer:onCleanup()
	if nil ~= self.animationUpdateHandler then
		scheduler.unscheduleGlobal(self.animationUpdateHandler)
		self.animationUpdateHandler = nil
	end
end


return PetUpgradeLayer
