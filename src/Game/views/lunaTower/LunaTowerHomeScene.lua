--[[
luna塔主界面
--]]
local GameScene = require( "Frame.GameScene" )
local LunaTowerHomeScene = class("LunaTowerHomeScene", GameScene)

------------ import ------------
local ZoomSliderList = require('common.ZoomSliderList')
------------ import ------------

------------ define ------------
local LunaTowerModuleId = JUMP_MODULE_DATA.LUNA_TOWER
local RES_DICT = {
	STAGE_BG	 			= 'ui/lunatower/lunatower_tab_btn_default.png',
	TOWER_BOTTOM 			= 'ui/lunatower/lunatower_tab_down.png',
	STAGE_CLEAR 			= 'ui/lunatower/lunatower_tab_btn_clear.png',
	STAGE_LOCK_COVER 		= 'ui/lunatower/lunatower_tab_lock.png',
	SIGN_MARK_PATH_BOSS 	= 'ui/lunatower/lunatower_icon_boss.png',
	SIGN_MARK_PATH_EX 		= 'ui/lunatower/lunatower_icon_ex.png',
}

local SceneZorder = {
	BASE = 5,
	CENTER = 20,
	TOP = 90
}

local LunaTowerType = {
	EX 			= 1, -- ex类型
	BOSS 		= 2  -- boss类型
}
local SignMarkConfig = {
	[LunaTowerType.EX] = {name = 'EX', signPath = RES_DICT.SIGN_MARK_PATH_EX, iconTag = 101},
	[LunaTowerType.BOSS] = {name = 'BOSS', signPath = RES_DICT.SIGN_MARK_PATH_BOSS, iconTag = 103}
}
-- cell中mark的排列顺序
local CellMarkConfig = {
	{signType = LunaTowerType.BOSS},
	{signType = LunaTowerType.EX}
}
local LunaTowerPassedType = {
	NO 			= 0, -- 未过关
	NO_EX 		= 1, -- 未通过ex关卡
	CLEAR 		= 2  -- 过关
}

local ListSize = cc.size(308, display.height)
local ListCellSize = cc.size(ListSize.width, 175 - 3)
local StageContentSize = cc.size(974, 621)

local RewardsListViewSize = cc.size(650, 110)
local RewardsListCellSize = cc.size(118, 110)

local SpinePositionConfig = {
	[1] = cc.p(252, 254),
	[2] = cc.p(364, 328),
	[3] = cc.p(476, 254),
	[4] = cc.p(588, 328),
	[5] = cc.p(700, 254)
}
------------ define ------------

--[[
constructor
--]]
function LunaTowerHomeScene:ctor(...)

	local args = unpack({...})

	GameScene.ctor(self, 'Game.views.lunaTower.LunaTowerHomeScene')

	self.maxFloor = nil
	self.currentFloor = nil
	self.selectedFloorIndex = nil
	self.onlyShowEX = false

	self.allFloorsData = nil
	self.currentFloorsData = nil
	self.currentRewardsData = nil

	self.exData = nil
	self.currentFloorHp = nil
	self.teamData = nil
	self.playerLevel = nil

	-- 列表回调锁 在一些操蛋操作时上锁 不刷新右侧面板
	self.zoomChangeCallbackLock = false

	self:InitUI()
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function LunaTowerHomeScene:InitUI()

	local function CreateView()

		local moduleData = self:GetLunaTowerModuleData()

		local size = display.size
		local selfCenter = cc.p(size.width * 0.5, size.height * 0.5)

		-- 背景图
		local bg = display.newImageView(_res('ui/lunatower/lunatower_bg.jpg'), selfCenter.x, selfCenter.y, {isFull = true})
		self:addChild(bg)

		-- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height + 100,{n = _res('ui/common/common_title_new.png'), enable = true, ap = cc.p(0, 0)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = moduleData.name, fontSize = 30, color = '473227',offset = cc.p(0,-8)})
		self:addChild(tabNameLabel, SceneZorder.TOP)

		tabNameLabel:addChild(display.newImageView(_res('ui/common/common_btn_tips.png'), tabNameLabel:getContentSize().width - 50, tabNameLabel:getContentSize().height/2 - 10))

		-- 返回按钮
		local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = _res('ui/common/common_btn_back.png'), cb = handler(self, self.BackClickHandler)})
		self:addChild(backBtn, SceneZorder.TOP)

		-- guide button 
		-- local guideBtn = display.newButton(464 + display.SAFE_L, display.height - 42, {n = _res('guide/guide_ico_book.png')})
		-- display.commonLabelParams(guideBtn, fontWithColor(14, {text = __('指南'), fontSize = 28, offset = cc.p(10,-18)}))
		-- self:addChild(guideBtn, SceneZorder.TOP)
		-- display.commonUIParams(guideBtn, {cb = function(sender)
		-- 	local guideNode = require('common.GuideNode').new({tmodule = 'pvp'})
		-- 	sceneWorld:addChild(guideNode, GameSceneTag.Guide_GameSceneTag)
		-- end})

		------------ 角标说明 ------------
		-- 背景图
		local stageSignBg = display.newImageView(_res('ui/lunatower/lunatower_sign_bg.png'), 0, 0)
		display.commonUIParams(stageSignBg, {ap = cc.p(1, 1), po = cc.p(display.SAFE_R - 20, size.height)})
		self:addChild(stageSignBg, SceneZorder.TOP)
		
		local stageSignBgSize = stageSignBg:getContentSize()

		-- 标题文字
		local stageSignTitleLabel = display.newLabel(0, 0, fontWithColor('16', {text = __('角标参考图')}))
		display.commonUIParams(stageSignTitleLabel, {ap = cc.p(0, 1), po = cc.p(15, stageSignBgSize.height - 5)})
		stageSignBg:addChild(stageSignTitleLabel)

		-- 角标信息
		local stageSignConfig = {
			{signType = LunaTowerType.BOSS, fontInfo = {text = __('BOSS'), ttf = true, font = TTF_GAME_FONT, fontSize = 22, color = '#b10202'}},
			{signType = LunaTowerType.EX, fontInfo = {text = __('EX'), ttf = true, font = TTF_GAME_FONT, fontSize = 22, color = '#b10202'}}
		}
		local signAmount = #stageSignConfig
		local signCellWidth = 75

		for i, v in ipairs(stageSignConfig) do
			local icon = display.newSprite(_res(SignMarkConfig[v.signType].signPath), 0, 0)
			display.commonUIParams(icon, {po = cc.p(
				stageSignBgSize.width * 0.5 + ((i - 0.5) - signAmount * 0.5) * signCellWidth, 45
			)})
			stageSignBg:addChild(icon)

			local label = display.newLabel(0, 0, v.fontInfo)
			display.commonUIParams(label, {ap = cc.p(0.5, 1), po = cc.p(icon:getPositionX(), icon:getPositionY() - icon:getContentSize().height * 0.5 + 5)})
			stageSignBg:addChild(label)
		end
		------------ 角标说明 ------------

		------------ 左侧列表 ------------
		local stageDetailBg = display.newImageView(_res('ui/lunatower/lunatower_gate_bg.png'), 0, 0)
		local stageDetailBgSize = stageDetailBg:getContentSize()

		local arrowMark = display.newSprite(_res('ui/lunatower/lunatower_icon_arrow.png'), 0, 0)
		local arrowMarkSize = arrowMark:getContentSize()
		local arrowPadding1 = -5
		local arrowPadding2 = 8

		local totalWidth = arrowMarkSize.width + arrowPadding1 + arrowPadding2 + ListSize.width + stageDetailBgSize.width
		local arrowPosition = cc.p(0, selfCenter.y)

		-- 列表背景
		local listViewBg = display.newImageView(_res('ui/lunatower/lunatower_tower_bg.png'), 0, 0, {scale9 = true, size = ListSize})
		display.commonUIParams(listViewBg, {po = cc.p(
			math.max(display.SAFE_L + ListSize.width * 0.5, selfCenter.x - totalWidth * 0.5 + ListSize.width * 0.5),
			selfCenter.y
		)})
		self:addChild(listViewBg, SceneZorder.CENTER - 2)
		listViewBg:setVisible(false)

		local zoomSliderList = ZoomSliderList.new()
		self:addChild(zoomSliderList, SceneZorder.CENTER - 2)
		zoomSliderList:setPosition(cc.p(
			listViewBg:getPositionX() - ListSize.width * 0.5,
			0
		))

		local sideCount = math.ceil(ListSize.height / ListCellSize.height * 0.5) + 1
		local touchPadding = cc.p(0, (size.height - (sideCount * 2 + 1) * ListCellSize.height - 150) * 0.5)

		zoomSliderList:setBasePoint(cc.p(ListSize.width * 0.5, arrowPosition.y + 25))
		zoomSliderList:setCellSize(ListCellSize)
		zoomSliderList:setScaleMin(1)
		zoomSliderList:setCellSpace(ListCellSize.height)
		zoomSliderList:setCenterIndex(1)
		zoomSliderList:setDirection(ZoomSliderList.D_VERTICAL)
		zoomSliderList:setAlignType(ZoomSliderList.ALIGN_CENTER)
		zoomSliderList:setSideCount(sideCount)
		zoomSliderList:setSwallowTouches(false)
		zoomSliderList:setTouchRectPadding(touchPadding)
		zoomSliderList:setHostCellZOrder(false)
		-- zoomSliderList:setBackgroundColor(cc.c4b(255, 128, 128, 200))

		-- 设置箭头位置
		arrowPosition.x = listViewBg:getPositionX() + listViewBg:getContentSize().width * 0.5 + arrowMarkSize.width * 0.5 + arrowPadding1
		display.commonUIParams(arrowMark, {po = arrowPosition})
		self:addChild(arrowMark, listViewBg:getLocalZOrder())
		------------ 左侧列表 ------------

		------------ 右侧关卡详情 ------------
		display.commonUIParams(stageDetailBg, {po = cc.p(
			math.min(display.SAFE_R - stageDetailBgSize.width * 0.5, selfCenter.x + totalWidth * 0.5 - stageDetailBgSize.width * 0.5),
			arrowPosition.y - 35
		)})
		self:addChild(stageDetailBg, SceneZorder.TOP - 1)

		-- view
		local stageDetailView = display.newLayer(0, 0, {size = stageDetailBgSize})
		display.commonUIParams(stageDetailView, {ap = cc.p(0.5, 0.5), po = cc.p(stageDetailBg:getPositionX(), stageDetailBg:getPositionY())})
		self:addChild(stageDetailView, stageDetailBg:getLocalZOrder())
		-- stageDetailView:setBackgroundColor(cc.c4b(255, 128, 128, 200))

		-- cover
		local stageDetailCoverShadow = display.newImageView(_res('ui/lunatower/lunatower_gate_bg_shadow.png'), 0, 0)
		display.commonUIParams(stageDetailCoverShadow, {po = utils.getLocalCenter(stageDetailView)})
		stageDetailView:addChild(stageDetailCoverShadow, 5)

		-- title
		local stageTitleBg = display.newImageView(_res('ui/lunatower/lunatower_gate_title_bg.png'), 0, 0, {scale9 = true})
		local stageTitleBgSize = stageTitleBg:getContentSize()
		display.commonUIParams(stageTitleBg, {ap = cc.p(0, 1), po = cc.p(0, stageDetailBgSize.height)})
		stageDetailView:addChild(stageTitleBg)

		local stageTitleLabel = display.newLabel(0, 0, {text = 'test floor', ttf = true, font = TTF_GAME_FONT, fontSize = 26, color = '#983200'})
		display.commonUIParams(stageTitleLabel, {ap = cc.p(0, 0.5), po = cc.p(35, stageTitleBgSize.height * 0.5 - 8)})
		stageTitleBg:addChild(stageTitleLabel)

		-- 推荐灵力
		local battlePointBg = display.newImageView(_res('ui/lunatower/lunatower_mana_bg.png'), 0, 0, {scale9 = true})
		battlePointBg:setVisible(false)
		local battlePointBgSize = battlePointBg:getContentSize()
		display.commonUIParams(battlePointBg, {ap = cc.p(1, 1), po = cc.p(stageDetailBgSize.width - 13, stageDetailBgSize.height - 14)})
		stageDetailView:addChild(battlePointBg)

		local battlePointTitleLabel = display.newLabel(0, 0, fontWithColor('18', {text = __('推荐灵力')}))
		display.commonUIParams(battlePointTitleLabel, {ap = cc.p(0.5, 1), po = cc.p(battlePointBgSize.width * 0.5, battlePointBgSize.height - 10)})
		battlePointBg:addChild(battlePointTitleLabel)

		local battlePointLabel = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', '8888888')
		battlePointLabel:setAnchorPoint(cc.p(0.5, 0))
		battlePointLabel:setHorizontalAlignment(display.TAC)
		battlePointLabel:setPosition(cc.p(battlePointTitleLabel:getPositionX() - 5, -5))
		battlePointLabel:setScale(0.85)
		battlePointBg:addChild(battlePointLabel)

		-- 奖励
		local rewardsBg = display.newImageView(_res('ui/lunatower/lunatower_reward_bg.png'), 0, 0)
		display.commonUIParams(rewardsBg, {ap = cc.p(0, 0.5), po = cc.p(
			20, 175 - rewardsBg:getContentSize().height * 0.5
		)})
		stageDetailView:addChild(rewardsBg)

		local rewardsTitleLabel = display.newLabel(0, 0, {text = __('通关奖励'), fontSize = 26, color = '#7c2900'})
		display.commonUIParams(rewardsTitleLabel, {ap = cc.p(0, 0.5), po = cc.p(15, rewardsBg:getContentSize().height * 0.5)})
		rewardsBg:addChild(rewardsTitleLabel)

		-- 奖励列表
		local rewardsListView = CTableView:create(RewardsListViewSize)
		display.commonUIParams(rewardsListView, {ap = cc.p(0, 0.5), po = cc.p(
			rewardsBg:getPositionX() + 5,
			rewardsBg:getPositionY() - rewardsBg:getContentSize().height * 0.5 - 10 - RewardsListViewSize.height * 0.5
		)})
		stageDetailView:addChild(rewardsListView)

		-- rewardsListView:setBackgroundColor(cc.c4b(255, 123, 65, 100))

		rewardsListView:setSizeOfCell(RewardsListCellSize)
		rewardsListView:setCountOfCell(0)
		rewardsListView:setDirection(eScrollViewDirectionHorizontal)
		rewardsListView:setDataSourceAdapterScriptHandler(handler(self, self.RewardsDataAdapter))

		-- 战斗按钮
		local battleButton = require('common.CommonBattleButton').new({
			pattern = 1,
			clickCallback = handler(self, self.BattleClickHandler)
		})
		display.commonUIParams(battleButton, {po = cc.p(
			stageDetailBgSize.width - battleButton:getContentSize().width * 0.5 - 45,
			105
		)})
		stageDetailView:addChild(battleButton)

		-- 中间spine小人
		local spineAvatarList = {}
		local posInfo = 0
		for i = 1, MAX_TEAM_MEMBER_AMOUNT do

			posInfo = SpinePositionConfig[i]

			-- 底座
			local avatarBottom = display.newImageView(_res('ui/common/tower_bg_team_base.png'), 0, 0)
			avatarBottom:setScale(0.85)
			display.commonUIParams(avatarBottom, {po = cc.p(
				posInfo.x, posInfo.y
			)})
			stageDetailView:addChild(avatarBottom, (i % 2) * 2 + 1)

			-- 透明按钮
			local avatarBtn = display.newButton(0, 0, {size = cc.size(150, 200)})
			display.commonUIParams(avatarBtn, {po = cc.p(
				avatarBottom:getPositionX(),
				avatarBottom:getPositionY() + avatarBtn:getContentSize().height * 0.5
			), animate = false, cb = handler(self, self.MonsterDetailClickHandler)})
			avatarBottom:getParent():addChild(avatarBtn, avatarBottom:getLocalZOrder())
			avatarBtn:setTag(i)
			avatarBtn:setVisible(false)

			-- 等级信息
			local levelBg = display.newImageView(_res('ui/lunatower/lunatower_level_bg.png'), 0, 0, {scale9 = true})
			display.commonUIParams(levelBg, {po = cc.p(
				posInfo.x, posInfo.y - 15
			)})
			stageDetailView:addChild(levelBg, avatarBottom:getLocalZOrder())

			local levelLabel = display.newLabel(0, 0, fontWithColor('18', {text = ''}))
			display.commonUIParams(levelLabel, {po = utils.getLocalCenter(levelBg)})
			levelBg:addChild(levelLabel)

			table.insert(spineAvatarList, {avatarBottom = avatarBottom, avatarBtn = avatarBtn, levelBg = levelBg, levelLabel = levelLabel, avatarSpine = nil})

		end
		------------ 右侧关卡详情 ------------

		-- ex关卡筛选按钮
		local onlyEXButton = display.newCheckBox(0, 0, {
			n = _res('ui/lunatower/lunatower_arrow_bg.png'),
			s = _res('ui/lunatower/lunatower_arrow_bg.png')
		})
		display.commonUIParams(onlyEXButton, {po = cc.p(
			listViewBg:getPositionX() - 84,
			45
		)})
		onlyEXButton:setOnClickScriptHandler(handler(self, self.OnlyShowEXClickHandler))
		self:addChild(onlyEXButton, SceneZorder.TOP + 1)

		local yesMark = display.newSprite(_res('ui/common/common_arrow.png'), 0, 0)
		display.commonUIParams(yesMark, {po = cc.p(
			onlyEXButton:getContentSize().width * 0.5 + 5,
			onlyEXButton:getContentSize().height * 0.5 + 5
		)})
		onlyEXButton:addChild(yesMark)
		yesMark:setTag(3)
		yesMark:setVisible(self.onlyShowEX)

		local onlyEXLabel = display.newLabel(0, 0, fontWithColor('16', {text = __('只显示EX关卡')}))
		display.commonUIParams(onlyEXLabel, {ap = cc.p(0, 0.5), po = cc.p(
			onlyEXButton:getPositionX() + onlyEXButton:getContentSize().width * 0.5 + 15,
			onlyEXButton:getPositionY()
		)})
		self:addChild(onlyEXLabel, SceneZorder.TOP + 1)

		-- 遮挡云
		local cloudTop = display.newImageView(_res('ui/lunatower/lunatower_cloud_top.png'), 0, 0)
		display.commonUIParams(cloudTop, {ap = cc.p(0.5, 1), po = cc.p(size.width * 0.5, size.height + 5)})
		self:addChild(cloudTop, SceneZorder.TOP - 2)
		if display.width > cloudTop:getContentSize().width then
			cloudTop:setScaleX(display.width / cloudTop:getContentSize().width)
		end

		local cloudBottom = display.newImageView(_res('ui/lunatower/lunatower_cloud_down.png'), 0, 0)
		display.commonUIParams(cloudBottom, {ap = cc.p(0.5, 0), po = cc.p(size.width * 0.5, -5)})
		self:addChild(cloudBottom, SceneZorder.TOP - 2)
		if display.width > cloudBottom:getContentSize().width then
			cloudBottom:setScaleX(display.width / cloudBottom:getContentSize().width)
		end

		return {
			tabNameLabel = tabNameLabel,
			backBtn = backBtn,
			zoomSliderList = zoomSliderList,
			arrowMark = arrowMark,
			stageTitleLabel = stageTitleLabel,
			battlePointBg = battlePointBg,
			battlePointBgSize = battlePointBgSize,
			battlePointTitleLabel = battlePointTitleLabel,
			battlePointLabel = battlePointLabel,
			rewardsListView = rewardsListView,
			spineAvatarList = spineAvatarList,
			battleButton = battleButton,
			onlyEXButton = onlyEXButton,
			yesMark = yesMark
		}

	end

	xTry(function ( )
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

	-- 弹出标题班
	local action = cc.Sequence:create(
		cc.EaseBounceOut:create(cc.MoveTo:create(1,cc.p(display.SAFE_L + 130, display.height - 80))),
		cc.CallFunc:create(function ()
			display.commonUIParams(self.viewData.tabNameLabel, {cb = function (sender)
				app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[LunaTowerModuleId]})
			end})
		end)
	)
	self.viewData.tabNameLabel:runAction(action)

	-- 初始化一些动画
	self.viewData.arrowMark:runAction(cc.RepeatForever:create(cc.Sequence:create(
		cc.ScaleTo:create(1.5, 0.9),
		cc.ScaleTo:create(1.5, 1)
	)))

	-- 初始化列表的一些回调
	self:InitListViewCallback()

	-- -- debug --
	-- self.viewData.zoomSliderList:setCellCount(100)
	-- self.viewData.zoomSliderList:reloadData()
	-- -- debug --

end
--[[
初始化列表回调
--]]
function LunaTowerHomeScene:InitListViewCallback()
	------------ 左侧层列表 ------------
	self.viewData.zoomSliderList:setCellChangeCB(handler(self, self.ZoomSliderListCellChangeCallback))
	self.viewData.zoomSliderList:setIndexPassChangeCB(handler(self, self.ZoomSliderListIndexPassCallback))
	self.viewData.zoomSliderList:setIndexOverChangeCB(handler(self, self.ZoomSliderListIndexOverCallback))
	------------ 左侧层列表 ------------
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
左侧关卡列表格子变换回调 刷新格子
--]]
function LunaTowerHomeScene:ZoomSliderListCellChangeCallback(c, i)
	local cell = c
	local index = i
	local floorId = self:GetFloorIdByIndex(index)

	local bg = nil
	local towerBottom = nil
	local towerTop = nil
	local floorLabel = nil
	local bossSignMark = nil
	local exSignMark = nil
	local lockIcon = nil
	local clearLabel = nil
	local selectedMark = nil
	local lockCover = nil

	if nil == cell then

		cell = display.newLayer(0, 0, {size = ListCellSize})

		-- 背景
		bg = display.newImageView(_res(RES_DICT.STAGE_BG), 0, 0)
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(cell))})
		cell:addChild(bg)
		bg:setTag(3)

		local bgSize = bg:getContentSize()

		-- 底座
		towerBottom = display.newImageView(_res(RES_DICT.TOWER_BOTTOM), 0, 0)
		display.commonUIParams(towerBottom, {ap = cc.p(0.5, 1), po = cc.p(bgSize.width * 0.5, 3)})
		cell:addChild(towerBottom)
		towerBottom:setTag(15)

		-- 层数
		floorLabel = display.newLabel(0, 0, {
			text = string.format(__('%d层'), floorId), ttf = true, font = TTF_GAME_FONT, fontSize = 28, color = '#ffffff', outline = '#5b3c25', outlineSize = 2
		})
		display.commonUIParams(floorLabel, {ap = cc.p(0.5, 0), po = cc.p(bgSize.width * 0.5, bgSize.height * 0.3)})
		bg:addChild(floorLabel, 5)
		floorLabel:setTag(5)

		-- sign mark
		for i, markInfo in ipairs(CellMarkConfig) do
			local icon = display.newSprite(_res(SignMarkConfig[markInfo.signType].signPath), 0, 0)
			bg:addChild(icon, 5)
			icon:setTag(SignMarkConfig[markInfo.signType].iconTag)
		end

		-- lock clear mark
		lockIcon = display.newSprite(_res('ui/common/common_ico_lock.png'), 0, 0)
		display.commonUIParams(lockIcon, {po = cc.p(
			bg:getPositionX() + bgSize.width * 0.5 - 45 - lockIcon:getContentSize().width * 0.5,
			bg:getPositionY() - 35
		)})
		cell:addChild(lockIcon, 20)
		lockIcon:setTag(7)

		clearLabel = display.newLabel(0, 0, {text = __('清除'), ttf = true, font = TTF_GAME_FONT, fontSize = 24, color = '#ff0000'})
		display.commonUIParams(clearLabel, {ap = cc.p(1, 0.5), po = cc.p(
			bg:getPositionX() + bgSize.width * 0.5 - 40, lockIcon:getPositionY()
		)})
		cell:addChild(clearLabel, 20)
		clearLabel:setTag(9)

		-- 选中框
		selectedMark = display.newSprite(_res('ui/lunatower/lunatower_tab_select.png'), 0, 0)
		display.commonUIParams(selectedMark, {po = cc.p(bg:getPositionX(), bg:getPositionY() + 2)})
		cell:addChild(selectedMark, 20)
		selectedMark:setVisible(false)
		selectedMark:setTag(11)

		-- 未解锁遮罩
		lockCover = display.newImageView(_res(RES_DICT.STAGE_LOCK_COVER), 0, 0)
		display.commonUIParams(lockCover, {po = cc.p(bg:getPositionX(), bg:getPositionY())})
		cell:addChild(lockCover, 10)
		lockCover:setTag(13)

	else

		bg = cell:getChildByTag(3)
		towerBottom = cell:getChildByTag(15)
		floorLabel = bg:getChildByTag(5)
		lockIcon = cell:getChildByTag(7)
		clearLabel = cell:getChildByTag(9)
		selectedMark = cell:getChildByTag(11)
		lockCover = cell:getChildByTag(13)

	end

	local isBoss = self:IsBossStageByFloorId(floorId)
	local isEX = self:IsEXStageByFloorId(floorId)
	local isPassed = self:PassedStageByFloorId(floorId)
	local unlock = self:UnlockFloorByFloorId(floorId)

	bossSignMark = bg:getChildByTag(SignMarkConfig[LunaTowerType.BOSS].iconTag)
	exSignMark = bg:getChildByTag(SignMarkConfig[LunaTowerType.EX].iconTag)

	------------ 刷新cell ------------
	-- 层数
	floorLabel:setString(string.format(__('%d层'), floorId))

	-- 未解锁
	lockIcon:setVisible(not unlock)
	lockCover:setVisible(not unlock)

	-- 是否通过
	if LunaTowerPassedType.CLEAR == isPassed then

		-- bg:setName(tostring(LunaTowerPassedType.CLEAR))
		clearLabel:setVisible(true)
		lockCover:setVisible(true)

	else

		-- bg:setName(tostring(LunaTowerPassedType.NO))
		clearLabel:setVisible(false)

	end

	-- boss ex mark
	local showEXMark = isEX and LunaTowerPassedType.NO ~= isPassed
	bossSignMark:setVisible(isBoss)
	exSignMark:setVisible(showEXMark)

	local icons = {}
	if isBoss then
		table.insert(icons, bossSignMark)
	end
	if showEXMark then
		table.insert(icons, exSignMark)
	end
	display.setNodesToNodeOnCenter(bg, icons, {spaceW = 15, y = 30})

	-- 是否选中
	selectedMark:setVisible(index == checkint(self.selectedFloorIndex))

	-- 底座
	towerBottom:setVisible(index == self.viewData.zoomSliderList:getCellCount())
	towerBottom:setLocalZOrder(index + 2)
	------------ 刷新cell ------------

	-- !!! --
	-- 修正一次cell的zorder
	cell:setLocalZOrder(index + 1)
	-- !!! --
	
	return cell
end
--[[
格子滑动时的回调
--]]
function LunaTowerHomeScene:ZoomSliderListIndexPassCallback(sender, index)
	
end
--[[
格子滑动停止时的回调
--]]
function LunaTowerHomeScene:ZoomSliderListIndexOverCallback(sender, index)
	if not self.zoomChangeCallbackLock then
		self:RefreshCellAndStageByIndex(index, false)
	end
end
--[[
奖励列表回调
--]]
function LunaTowerHomeScene:RewardsDataAdapter(c, i)
	local cell = c
	local index = i + 1

	local goodsData = self.currentRewardsData[index]
	local goodsId = checkint(goodsData.goodsId)
	local amount = checkint(goodsData.num)
	
	local goodsNode = nil

	if nil == cell then

		cell = CTableViewCell:new()
		cell:setContentSize(RewardsListCellSize)

		goodsNode = require('common.GoodNode').new({
			id = goodsId,
			amount = amount,
			showAmount = true,
			callBack = function (sender)
				app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = goodsId, type = 1})
			end
		})
		display.commonUIParams(goodsNode, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(cell)})
		cell:addChild(goodsNode)
		goodsNode:setTag(3)

	else

		goodsNode = cell:getChildByTag(3)
		goodsNode:RefreshSelf({
			goodsId = goodsId,
			amount = amount,
			showAmount = true,
			callBack = function (sender)
				app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = goodsId, type = 1})
			end
		})

	end

	return cell
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- refresh begin --
---------------------------------------------------
--[[
刷新整个界面
@params floorData list 所有的层id
@params maxFloor int 开放的最高层数
@params currentFloor int 当前过关的最高层
@params exData map ex关卡信息
@params currentFloorHp map 当前正在挑战的层怪物血量
@params teamData map 服务器保存的编队信息
@params playerLevel int 玩家等级
--]]
function LunaTowerHomeScene:RefreshScene(floorData, maxFloor, currentFloor, exData, currentFloorHp, teamData, playerLevel)
	-- 缓存数据
	self.allFloorsData = floorData
	self.maxFloor = maxFloor
	self.currentFloor = currentFloor
	self.exData = exData
	self.currentFloorHp = currentFloorHp
	self.teamData = teamData
	self.playerLevel = playerLevel

	-- 刷新左侧列表
	self:RefreshFloorListView(floorData)
	-- 跳转
	self:JumpToCellByFloorId(currentFloor + 1)
end
--[[
刷新列表
@params floorData list 层信息 id集合
--]]
function LunaTowerHomeScene:RefreshFloorListView(floorData)
	-- 刷新数据
	self.currentFloorsData = floorData

	-- 刷新列表
	local zoomSliderList = self.viewData.zoomSliderList
	zoomSliderList:setCellCount(#floorData)
	zoomSliderList:reloadData()
end
--[[
根据层id跳转到指定格子
@params floodId int 层id
@params force bool 强制跳转
--]]
function LunaTowerHomeScene:JumpToCellByFloorId(floorId, force)
	local index = self:GetIndexByFloorId(floorId)
	self:JumpToCellByIndex(index, force)
end
--[[
根据序号跳转到指定格子
@params index int 序号
@params force bool 强制跳转
--]]
function LunaTowerHomeScene:JumpToCellByIndex(index, force)
	if nil ~= self.selectedFloorIndex and index == self.selectedFloorIndex and true ~= force then return end

	self.viewData.zoomSliderList:setCenterIndex(index, true)

	self:RefreshCellAndStageByIndex(index, force)
end
--[[
根据序号刷新界面
@params index int 序号
@params force bool 强制刷新
--]]
function LunaTowerHomeScene:RefreshCellAndStageByIndex(index, force)
	if nil ~= self.selectedFloorIndex and index == self.selectedFloorIndex and true ~= force then return end

	-- 刷新左侧cell
	if nil ~= self.selectedFloorIndex then
		local preCell = self.viewData.zoomSliderList:cellAtIndex(self.selectedFloorIndex)
		if nil ~= preCell then
			preCell:getChildByTag(11):setVisible(false)
		end
	end

	local curCell = self.viewData.zoomSliderList:cellAtIndex(index)
	if nil ~= curCell then
		curCell:getChildByTag(11):setVisible(true)
	end

	self.selectedFloorIndex = index

	-- 上锁就不刷新面板了 节省开销
	if self.zoomChangeCallbackLock then return end

	-- 该cell对应的层id
	local floorId = self:GetFloorIdByIndex(index)
	local isPassed = self:PassedStageByFloorId(floorId)
	local questId = self:GetCurrentQuestIdByFloorId(floorId)
	local hpData = self:GetHpDataByFloorId(floorId)
	local unlock = self:UnlockFloorByFloorId(floorId)

	-- 刷新右侧关卡详情
	self:RefreshStageDetail(floorId, questId, isPassed, hpData, unlock)
end
--[[
根据关卡id 是否通关 剩余血量信息 刷新右侧关卡信息板
@params floorId int 层id
@params questId int 关卡id
@params isPassed LunaTowerPassedType 是否通关
@params hpData map 血量信息
@params unlock bool 是否解锁了该关卡
--]]
function LunaTowerHomeScene:RefreshStageDetail(floorId, questId, isPassed, hpData, unlock)
	local questConfig = CommonUtils.GetQuestConf(questId)
	if nil == questConfig then return end

	-- 标题
	self.viewData.stageTitleLabel:setString(string.format(__('%d层'), floorId))

	-- 推荐灵力
	self.viewData.battlePointLabel:setString(checkint(questConfig.recommendCombatValue))
	local bpLabelSize = self.viewData.battlePointLabel:getContentSize()
	local fixedWidth = math.max(self.viewData.battlePointBgSize.width, bpLabelSize.width)
	self.viewData.battlePointBg:setContentSize(cc.size(fixedWidth, self.viewData.battlePointBgSize.height))
	local x = fixedWidth * 0.5
	self.viewData.battlePointTitleLabel:setPositionX(x)
	self.viewData.battlePointLabel:setPositionX(x - 10)

	-- 刷新关卡奖励
	local rewards = questConfig.rewards
	self.currentRewardsData = rewards
	self.viewData.rewardsListView:setCountOfCell(#rewards)
	self.viewData.rewardsListView:reloadData()

	-- 刷新spine小人
	local teamData = self:GetEnemyInfo(floorId, isPassed, self.playerLevel)
	self:RefreshStageDetailTeam(teamData, isPassed, hpData)

	-- 刷新战斗按钮
	self:RefreshBattleButton(unlock, isPassed)
end
--[[
刷新关卡详情的spine小人
@params teamData table 队伍信息
@params isPassed LunaTowerPassedType 是否通关
@params hpData map 血量信息
--]]
function LunaTowerHomeScene:RefreshStageDetailTeam(teamData, isPassed, hpData)
	local spineAvatarList = self.viewData.spineAvatarList
	--[[
	{
		{avatarBottom = nil, levelBg = nil, levelLabel = nil, avatarSpine = nil},
		{avatarBottom = nil, levelBg = nil, levelLabel = nil, avatarSpine = nil},
		{avatarBottom = nil, levelBg = nil, levelLabel = nil, avatarSpine = nil},
		...
	}
	--]]

	-- 移除老的spine节点
	local nodes = nil
	for i = 1, MAX_TEAM_MEMBER_AMOUNT do

		nodes = spineAvatarList[i]
		if nil ~= nodes.avatarSpine then
			nodes.avatarSpine:stopAllActions()
			nodes.avatarSpine:setVisible(false)
			nodes.avatarSpine:clearTracks()
			nodes.avatarSpine:removeFromParent()
		end

		spineAvatarList[i].avatarSpine = nil

		-- 隐藏等级信息
		nodes.levelBg:setVisible(false)
		-- 隐藏按钮
		nodes.avatarBtn:setVisible(false)

	end

	for i = 1, MAX_TEAM_MEMBER_AMOUNT do
		nodes = spineAvatarList[i]
		nodes.avatarBottom.cardData = teamData[i]
		nodes.avatarBottom.isPassed = isPassed
		nodes.avatarBottom.hpData   = hpData
		nodes.avatarBottom:stopAllActions()
		nodes.avatarBottom:runAction(cc.Sequence:create(
			cc.DelayTime:create(i * 0.1),
			cc.CallFunc:create(function()
				self:RefreshStageDetailTeam2(i)
			end)
		))
	end

end

function LunaTowerHomeScene:RefreshStageDetailTeam2(i)
	local spineAvatarList = self.viewData.spineAvatarList
	local nodes = spineAvatarList[i]
	local cardData = nodes.avatarBottom.cardData
	local isPassed = nodes.avatarBottom.isPassed
	local hpData = nodes.avatarBottom.hpData

	-- 创建新的spine节点
	local cardId = nil
	-- local cardData = nil
	local skinId = nil
	local skinConfig = nil
	local isCardDead = true
	local hpPercent = 0
	local avatarSpineViewBox = nil
	local headMarkPos = nil

	local towards = -1

	-- for i = 1, MAX_TEAM_MEMBER_AMOUNT do

		-- cardData = teamData[i]
		if nil ~= cardData and 0 ~= checkint(cardData.cardId) then

			-- nodes = spineAvatarList[i]

			cardId = checkint(cardData.cardId)
			skinId = checkint(cardData.defaultSkinId or CardUtils.GetCardSkinId(cardId))

			skinConfig = CardUtils.GetCardSkinConfig(skinId)
			if nil == skinConfig then
				skinId = CardUtils.GetCardSkinId(cardId)
				skinConfig = CardUtils.GetCardSkinConfig(skinId)
			end

			------------ 卡牌spine小人 ------------
			local avatarSpine = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = CARD_DEFAULT_SCALE, spineName = skinId, cacheName = SpineCacheName.TOWER})
			avatarSpine:update(0)
			avatarSpine:setScaleX(towards)
			avatarSpine:setAnimation(0, 'idle', true)
			avatarSpine:setPosition(cc.p(
				nodes.avatarBottom:getContentSize().width * 0.5,
				nodes.avatarBottom:getContentSize().height * 0.5 + 5
			))
			nodes.avatarBottom:addChild(avatarSpine, 5)

			self.viewData.spineAvatarList[i].avatarSpine = avatarSpine
			avatarSpineViewBox = avatarSpine:getBorderBox(sp.CustomName.VIEW_BOX) or cc.rect(0, 0, 0, 0)
			headMarkPos = cc.p(
				0,
				(avatarSpineViewBox.y + avatarSpineViewBox.height)
			)
			------------ 卡牌spine小人 ------------

			------------ 头顶部血条 ------------
			isCardDead = true
			hpPercent = 1
			if LunaTowerPassedType.CLEAR ~= isPassed then

				if nil ~= hpData and nil ~= hpData[tostring(i)] then
					hpPercent = checknumber(hpData[tostring(i)])
				end

				if 0 < hpPercent then
					isCardDead = false
				end

			end

			if isCardDead then
				-- 死亡 创建骷髅头标志
				local deadMark = display.newSprite(_res('ui/battle/battletagmatch/3v3_fighting_head_ico_die.png'), 0, 0)
				display.commonUIParams(deadMark, {po = headMarkPos})
				avatarSpine:addChild(deadMark, 10)
				deadMark:setScaleX(towards)
			else
				-- 未死亡 创建血条
				local hpBar = CProgressBar:create(_res('ui/lunatower/lunatower_enemy_blood_2.png'))
				hpBar:setBackgroundImage(_res('ui/lunatower/lunatower_enemy_blood_1.png'))
				hpBar:setDirection(eProgressBarDirectionLeftToRight)
				hpBar:setPosition(headMarkPos)
				avatarSpine:addChild(hpBar, 10)
				hpBar:setMaxValue(10000)
				hpBar:setValue(hpPercent * 10000)
				hpBar:setScaleX(towards)
			end
			------------ 头顶部血条 ------------

			------------ 刷新其他ui ------------
			nodes.levelLabel:setString(string.format(__('%d级'), cardData.level))
			nodes.levelBg:setVisible(true)

			nodes.avatarBtn:setVisible(true)
			------------ 刷新其他ui ------------

		end

	-- end
end
--[[
刷新详情界面的战斗按钮
@params unlock bool 是否解锁该层
@params isPassed LunaTowerPassedType 是否通关
--]]
function LunaTowerHomeScene:RefreshBattleButton(unlock, isPassed)
	-- 没有解锁直接设置不可点
	if not unlock then

		self.viewData.battleButton:setEnabled(false)
		return

	end

	-- 根据pass类型设置样式
	if LunaTowerPassedType.NO == isPassed then
		
		self.viewData.battleButton:RefreshButton({buttonSkinType = BattleButtonSkinType.BASE})
		self.viewData.battleButton:setEnabled(true)

	elseif LunaTowerPassedType.NO_EX == isPassed then

		self.viewData.battleButton:RefreshButton({buttonSkinType = BattleButtonSkinType.EX})
		self.viewData.battleButton:setEnabled(true)

	else

		self.viewData.battleButton:setEnabled(false)

	end
end
--[[
只显示ex关卡
@params onlyShowEX bool 是否只显示ex关卡
--]]
function LunaTowerHomeScene:ShowEXOnly(onlyShowEX)
	if self.onlyShowEX == onlyShowEX then return end

	-- 强制停止列表滑动 直接停在当前格子
	-- 上锁 此处jump刷新面板没有意义
	self.zoomChangeCallbackLock = true
	self:JumpToCellByIndex(
		self.viewData.zoomSliderList:getCenterIndex(),
		true
	)

	local floorData = nil
	if true == onlyShowEX then
		floorData = self:GetAllEXFloors()
		if 0 >= #floorData then
			app.uiMgr:ShowInformationTips(__('未找到ex关卡!!!'))
			return
		end
	else
		floorData = self.allFloorsData
	end

	self.viewData.yesMark:setVisible(onlyShowEX)

	-- 解锁
	self.zoomChangeCallbackLock = false

	-- 刷新列表
	self:RefreshFloorListView(floorData)
	-- 跳转
	self:JumpToCellByFloorId(self.currentFloor + 1, true)

	self.onlyShowEX = onlyShowEX
end
--[[
设置不可触摸
@params canTouch bool 是否可以触摸
--]]
function LunaTowerHomeScene:SetCanTouch(canTouch)
	self.viewData.zoomSliderList:setEnabled(canTouch)
end
---------------------------------------------------
-- refresh end --
---------------------------------------------------

---------------------------------------------------
-- click callback begin --
---------------------------------------------------
--[[
返回按钮回调
--]]
function LunaTowerHomeScene:BackClickHandler(sender)
	PlayAudioByClickClose()
	AppFacade.GetInstance():DispatchObservers('EXIT_LUNA_TOWER_HOME')
end
--[[
显示ex关卡按钮回调
--]]
function LunaTowerHomeScene:OnlyShowEXClickHandler(sender)
	PlayAudioByClickNormal()
	self:ShowEXOnly(not self.onlyShowEX)
end
--[[
战斗按钮回调
--]]
function LunaTowerHomeScene:BattleClickHandler(sender)
	PlayAudioByClickNormal()

	local floorId = self:GetFloorIdByIndex(self.selectedFloorIndex)
	local isPassed = self:PassedStageByFloorId(floorId)
	local questId = self:GetCurrentQuestIdByFloorId(floorId, isPassed)

	-- 跳出编辑编队界面
	AppFacade.GetInstance():DispatchObservers(
		'LT_SHOW_EDIT_TEAM_MEMBER',
		{floorId = floorId, questId = questId, isEX = (isPassed == LunaTowerPassedType.NO_EX)}
	)
end
--[[
怪物详情按钮回调
--]]
function LunaTowerHomeScene:MonsterDetailClickHandler(sender)
	PlayAudioByClickNormal()

	local index = sender:getTag()
	local floorId = self:GetFloorIdByIndex(self.selectedFloorIndex)
	local isPassed = self:PassedStageByFloorId(floorId)
	local questId = self:GetCurrentQuestIdByFloorId(floorId, isPassed)

	local teamData = self:GetEnemyInfo(floorId, isPassed, self.playerLevel)

	AppFacade.GetInstance():DispatchObservers(
		'SHOW_LUNA_TOWER_MONSTER_DETAIL',
		{floorId = floorId, questId = questId, monsterInfo = teamData[index]}
	)
end
---------------------------------------------------
-- click callback end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取模块信息
@return _ table 模块信息
--]]
function LunaTowerHomeScene:GetLunaTowerModuleData()
	local moduleData = CommonUtils.GetConfigAllMess('module')[LunaTowerModuleId] or {}
	return moduleData
end
--[[
根据id获取塔的配置信息
@params floorId int 层数id
@return _ config
--]]
function LunaTowerHomeScene:GetFloorConfigByFloorId(floorId)
	return CommonUtils.GetConfig('lunaTower', 'floor', floorId)
end
--[[
根据id判断该层是否是boss关
@params floorId int 层数id
@params _ bool 是否是boss关
--]]
function LunaTowerHomeScene:IsBossStageByFloorId(floorId)
	local floorConfig = self:GetFloorConfigByFloorId(floorId)
	if nil == floorConfig or nil == floorConfig.questId then return false end

	if 2 == #floorConfig.questId then
		return true
	else
		return false
	end
end
--[[
根据id判断该层是否是ex关卡
@params floorId int 层数id
@params _ bool 是否是ex关
--]]
function LunaTowerHomeScene:IsEXStageByFloorId(floorId)
	return self:IsBossStageByFloorId(floorId)
end
--[[
根据序号判断是否通过该关卡
@params floorId int 层数id
@return _ LunaTowerPassedType 通过类型
--]]
function LunaTowerHomeScene:PassedStageByFloorId(floorId)
	-- 目标层数大于通过层数 未通过
	if floorId > self.currentFloor then
		return LunaTowerPassedType.NO
	end

	-- 小于
	if not self:IsEXStageByFloorId(floorId) then
		return LunaTowerPassedType.CLEAR
	else

		if nil == self.exData or nil == self.exData[tostring(floorId)] then return LunaTowerPassedType.NO end

		local exStageData = self.exData[tostring(floorId)]
		local isPassed = checkint(exStageData.isPassed)

		if 1 == isPassed then
			return LunaTowerPassedType.CLEAR
		elseif 0 == isPassed then
			return LunaTowerPassedType.NO_EX
		end
		
		return LunaTowerPassedType.NO

	end

end
--[[
判断是否解锁了该层
@params floorId int 层数id
@params _ bool 是否解锁了该层
--]]
function LunaTowerHomeScene:UnlockFloorByFloorId(floorId)
	return (self.maxFloor >= floorId) and ((self.currentFloor + 1) >= floorId)
end
--[[
根据序号获取对应序号的层id
@params index int 序号
@return _ floorId int 层id
--]]
function LunaTowerHomeScene:GetFloorIdByIndex(index)
	return self.currentFloorsData[index]
end
--[[
根据层id获取列表序号
@params floorId int 层id
@params index int 列表序号
--]]
function LunaTowerHomeScene:GetIndexByFloorId(floorId)
	local index = #self.currentFloorsData
	for index_, floorId_ in ipairs(self.currentFloorsData) do
		if floorId_ == floorId then
			return index_
		end
	end
	return index
end
--[[
根据层id获取当前对应的关卡id
@params floorId int 层id
@params isPassed LunaTowerPassedType 是否通关
@return questId int 关卡id
--]]
function LunaTowerHomeScene:GetCurrentQuestIdByFloorId(floorId, isPassed)
	local questId = nil
	local floorConfig = self:GetFloorConfigByFloorId(floorId)

	if nil == floorConfig or nil == floorConfig.questId then return nil end

	if self:IsEXStageByFloorId(floorId) then

		local isPassed_ = isPassed or self:PassedStageByFloorId(floorId)
		if LunaTowerPassedType.NO == isPassed_ then
			questId = floorConfig.questId[1]
		else
			questId = floorConfig.questId[2]
		end

	else

		questId = floorConfig.questId[1]

	end

	return nil ~= questId and checkint(questId) or nil
end
--[[
根据层id获取对应的敌人配置
@params floorId int 层id
@params isPassed LunaTowerPassedType 是否通关
@return enemyId int 敌方配置id
--]]
function LunaTowerHomeScene:GetCurrentEnemyIdByFloorId(floorId, isPassed)
	local enemyId = nil
	local floorConfig = self:GetFloorConfigByFloorId(floorId)

	if nil == floorConfig or nil == floorConfig.enemyId then return nil end

	if self:IsEXStageByFloorId(floorId) then

		local isPassed_ = isPassed or self:PassedStageByFloorId(floorId)
		if LunaTowerPassedType.NO == isPassed_ then
			enemyId = floorConfig.enemyId[1]
		else
			enemyId = floorConfig.enemyId[2]
		end

	else

		enemyId = floorConfig.enemyId[1]

	end

	return enemyId
end
--[[
根据层id获取血量信息
@params floorId int 层id
@return hpData map 血量信息
--]]
function LunaTowerHomeScene:GetHpDataByFloorId(floorId)
	if floorId == self.currentFloor + 1 then
		return self.currentFloorHp
	end

	if nil ~= self.exData[tostring(floorId)] then
		return self.exData[tostring(floorId)].hp
	end

	return nil
end
--[[
获取当前层中的所有ex层
@return exFloors list<floorId> 所有的ex层
--]]
function LunaTowerHomeScene:GetAllEXFloors()
	local exFloors = {}
	for _, floorId in ipairs(self.allFloorsData) do
		if self:IsEXStageByFloorId(floorId) then
			table.insert(exFloors, floorId)
		end
	end
	return exFloors
end
--[[
获取当前选定的关卡信息
@return floorId, questId, enemyId int, int, int 层id, 关卡id, 敌军id
--]]
function LunaTowerHomeScene:GetCurrentStageInfo()
	local floorId = self:GetFloorIdByIndex(self.selectedFloorIndex)
	local isPassed = self:PassedStageByFloorId(floorId)
	local questId = self:GetCurrentQuestIdByFloorId(floorId, isPassed)
	local enemyId = self:GetCurrentEnemyIdByFloorId(floorId, isPassed)

	return floorId, questId, enemyId
end
--[[
获取当前显示的阵容信息
@params floorId int 层id
@params isPassed LunaTowerPassedType 是否通关
@params playerLevel int 玩家等级
--]]
function LunaTowerHomeScene:GetEnemyInfo(floorId, isPassed, playerLevel)
	floorId = floorId or self:GetFloorIdByIndex(self.selectedFloorIndex)
	isPassed = isPassed or self:PassedStageByFloorId(floorId)
	playerLevel = playerLevel or self.playerLevel

	local cardLevel = nil
	local skillLevel = nil
	local levelInfo = CommonUtils.GetConfig('battle', 'cardLevel', playerLevel)
	if nil ~= levelInfo then
		cardLevel = checkint(levelInfo.level)
		skillLevel = checkint(levelInfo.skillLevel)
	end

	return CardUtils.GetCustomizeEnemyOneTeamById(
		self:GetCurrentEnemyIdByFloorId(floorId, isPassed),
		cardLevel, skillLevel
	)
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return LunaTowerHomeScene
