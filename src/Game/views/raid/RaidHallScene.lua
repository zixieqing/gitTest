--[[
组队本选择副本界面
@params table {
	raidQuestType RaidQuestType 组队本类型
	showBg bool 是否显示背景图 否显示遮罩
	pattern 1 int 大厅样式 2 房间内样式
}
--]]
local GameScene = require('Frame.GameScene')
local RaidHallScene = class('RaidHallScene', GameScene)

------------ import ------------
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local ZoomSliderList = require('common.ZoomSliderList')
------------ import ------------

------------ define ------------
local zoomSliderListCellSize = cc.size(214, 232)
local DiffBtnTailPath = {
	[RaidQuestDifficulty.EASY] 		= 'ui/raid/hall/raid_difficulty_ico_spoon.png',
	[RaidQuestDifficulty.NORMAL] 	= 'ui/raid/hall/raid_difficulty_ico_spork.png',
	[RaidQuestDifficulty.HARD] 		= 'ui/raid/hall/raid_difficulty_ico_sticks.png'
}
------------ define ------------

--[[
constructor
--]]
function RaidHallScene:ctor( ... )
	local args = unpack({...})

	self.raidQuestType = checkint(args.raidQuestType)
	self.pattern = checkint(args.pattern or 1)

	self.viewData = nil
	self.zoomSliderListCellChangeCB = nil
	self.zoomSliderListIndexPassChangeCB = nil
	self.zoomSliderListIndexOverChangeCB = nil
	self.raidGroupInfo = nil
	self.playerLevel = nil
	self.rareRewardInfo = {}
	self.leftChallengeTimes = 0

	self.currentSelectedDiffIndex = nil
	self.currentSelectedRaidGroupIndex = nil

	self.passwordStr = ''
	self.teamIdStr = ''

	self:InitUI()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function RaidHallScene:InitUI()
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 0.5))
	eaterLayer:setPosition(cc.p(display.cx, display.cy))
	self:addChild(eaterLayer)
	eaterLayer:setVisible(false)
	self.eaterLayer = eaterLayer

	local CreateView = function ()
		-- 创建底层
		local size = self:getContentSize()
		local view = display.newLayer(0, 0, {size = size})
		display.commonUIParams(view, {ap = display.CENTER, po = cc.p(size.width * 0.5, size.height * 0.5)})
		self:addChild(view, 10)

		-- 背景图
		local bg = display.newImageView(_res('ui/raid/hall/raid_bg.jpg'), 0, 0)
		display.commonUIParams(bg, {po = utils.getLocalCenter(view)})
		view:addChild(bg)

		-- back button
		local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = _res('ui/common/common_btn_back.png')})
		self:addChild(backBtn, 99)

		------------ 左侧滑动条 ------------
		local zoomSliderList = ZoomSliderList.new()
		view:addChild(zoomSliderList, 2)
		zoomSliderList:setPosition(cc.p(
			display.SAFE_L,
			0
		))

		zoomSliderList:setBasePoint(cc.p(0, display.cy))
		zoomSliderList:setCellSize(zoomSliderListCellSize)
		zoomSliderList:setScaleMin(0.5)
		zoomSliderList:setCellSpace(120)
		zoomSliderList:setCenterIndex(1)
		zoomSliderList:setDirection(ZoomSliderList.D_VERTICAL)
		zoomSliderList:setAlignType(ZoomSliderList.ALIGN_LEFT)
		zoomSliderList:setSideCount(3)
		zoomSliderList:setSwallowTouches(false)
		-- zoomSliderList:setBackgroundColor(cc.c4b(255, 128, 128, 200)

		local zoomSliderBg = display.newImageView(_res('ui/raid/room/raid_boss_bg_iX.png'), 0, 0)
		display.commonUIParams(zoomSliderBg, {po = cc.p(
			display.SAFE_L + zoomSliderBg:getContentSize().width * 0.5 - 60,
			size.height * 0.5 - 15
		)})
		view:addChild(zoomSliderBg, 1)

		local zoomSliderImg = display.newImageView(_res('ui/raid/room/raid_boss_list_frame_active.png'))
		display.commonUIParams(zoomSliderImg, {po = cc.p(
			display.SAFE_L + zoomSliderImg:getContentSize().width * 0.5 - 40,
			size.height * 0.5
		)})
		view:addChild(zoomSliderImg, 3)
		------------ 左侧滑动条 ------------

		------------ 右侧底板 ------------
		local settingsBg = display.newImageView(_res('ui/raid/hall/raid_bg_difficulty.png'), 0, 0)
		display.commonUIParams(settingsBg, {po = cc.p(
			display.SAFE_R - settingsBg:getContentSize().width * 0.5 + 60,
			display.height * 0.5 - 110
		)})
		view:addChild(settingsBg)
		------------ 右侧底板 ------------

		return {
			view = view,
			zoomSliderList = zoomSliderList,
			stageDetailView = stageDetailView,
			settingsBg = settingsBg,
			difficultyBtns = {},
			leftChallengeTimesLabel = nil,
			leftChallengeTimesBtn = nil,
			bg = bg,
			backBtn = backBtn
		}
	end

	xTry(function ()
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

	-- 初始化右侧选关模块
	self:InitRaidTeamSettingsView()

end
--[[
初始化右侧选关模块
--]]
function RaidHallScene:InitRaidTeamSettingsView()
	if 1 == self.pattern then
		self:InitRaidTeamSettingsViewHall()
	elseif 2 == self.pattern then
		self:InitRaidTeamSettingsViewTeam()
	end
end
--[[
刷新大厅样式
--]]
function RaidHallScene:InitRaidTeamSettingsViewHall()
	local size = self:getContentSize()
	local parentNode = self.viewData.view
	local settingsBgPos = cc.p(
		self.viewData.settingsBg:getPositionX(),
		self.viewData.settingsBg:getPositionY()
	)

	local layerSize = self.viewData.settingsBg:getContentSize()
	local settingsLayer = display.newLayer(0, 0, {size = layerSize})
	display.commonUIParams(settingsLayer, {ap = cc.p(0.5, 0.5), po = settingsBgPos})
	parentNode:addChild(settingsLayer, 1)

	-- 返回按钮回调
	display.commonUIParams(self.viewData.backBtn, {cb = handler(self, self.ExitRaidHallClickHandler)})

	-- 密码底
	local passwordBgPos = cc.p(
		layerSize.width * 0.5,
		layerSize.height * 0.5 + 10
	)
	local passwordBg = display.newImageView(_res('ui/raid/hall/raid_bg_newroom.png'), 0, 0)
	display.commonUIParams(passwordBg, {po = passwordBgPos})
	settingsLayer:addChild(passwordBg)

	-- 设置密码按钮
	local setPwdBtn = display.newCheckBox(0, 0, {
		n = _res('ui/common/gut_task_ico_select.png'),
		s = _res('ui/common/gut_task_ico_hook.png')
	})
	display.commonUIParams(setPwdBtn, {po = cc.p(
		passwordBgPos.x - 45,
		passwordBgPos.y + 70
	)})
	settingsLayer:addChild(setPwdBtn)
	setPwdBtn:setOnClickScriptHandler(handler(self, self.SetPwdBtnClickHandler))

	local setPwdLabel = display.newLabel(0, 0,
		{text = __('设置密码'), fontSize = 22, color = '#e3bf98'})
	display.commonUIParams(setPwdLabel, {ap = cc.p(0, 0.5), po = cc.p(
		setPwdBtn:getPositionX() + setPwdBtn:getContentSize().width * 0.5 + 5,
		setPwdBtn:getPositionY() - 2
	)})
	settingsLayer:addChild(setPwdLabel)

	local pwdLabelBgSize = cc.size(150, 44)
	local pwdLabelCover = display.newLayer(0, 0, {size = pwdLabelBgSize, color = cc.c4b(100, 100, 100, 100), enable = true})
	display.commonUIParams(pwdLabelCover, {ap = cc.p(0.5, 0.5), po = cc.p(
		passwordBgPos.x,
		setPwdBtn:getPositionY() - setPwdBtn:getContentSize().height * 0.5 - 10 - pwdLabelBgSize.height * 0.5
	)})
	settingsLayer:addChild(pwdLabelCover, 10)
	local pwdLabelBg = display.newImageView(_res('ui/common/common_bg_input_default.png'), 0, 0,
		{scale9 = true, size = pwdLabelBgSize, enable = true})
	display.commonUIParams(pwdLabelBg, {po = cc.p(
		pwdLabelCover:getPositionX(),
		pwdLabelCover:getPositionY()
	), cb = handler(self, self.PasswordEditBoxClickHandler)})
	settingsLayer:addChild(pwdLabelBg, 9)

	local passwordLabel = display.newLabel(0, 0, fontWithColor('6', {text = self.passwordStr, w = pwdLabelBgSize.width - 20}))
	display.commonUIParams(passwordLabel, {ap = cc.p(0, 0.5), po = cc.p(
		10,
		pwdLabelBgSize.height * 0.5
	)})
	pwdLabelBg:addChild(passwordLabel)

	-- 创建队伍按钮
	local createTeamBtn = display.newButton(0, 0, {n = _res('ui/raid/hall/raid_btn_newroom.png')})
	display.commonUIParams(createTeamBtn, {po = cc.p(
		passwordBgPos.x,
		passwordBgPos.y - passwordBg:getContentSize().height * 0.5 + 15 + createTeamBtn:getContentSize().height * 0.5
	), cb = handler(self, self.CreateTeamBtnClickHandler)})
	display.commonLabelParams(createTeamBtn, fontWithColor('14', {text = __('创建队伍')}))
	settingsLayer:addChild(createTeamBtn, 9)

	-- 匹配按钮
	local autoMatchBtn = display.newButton(0, 0, {n = _res('ui/raid/hall/raid_btn_auto.png')})
	display.commonUIParams(autoMatchBtn, {po = cc.p(
		passwordBgPos.x,
		passwordBgPos.y - passwordBg:getContentSize().height * 0.5 - autoMatchBtn:getContentSize().height * 0.5
	), cb = handler(self, self.AutoMatchBtnClickHandler)})
	display.commonLabelParams(autoMatchBtn, fontWithColor('14', {text = __('自动匹配')}))
	settingsLayer:addChild(autoMatchBtn, 9)

	-- 剩余次数
	local leftChallengeTimesLabel = display.newLabel(0, 0, {text = '剩余次数:0', fontSize = 22, color = '#fff4db'})
	settingsLayer:addChild(leftChallengeTimesLabel)
	leftChallengeTimesLabel:setVisible(false)

	local leftChallengeTimesBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_add.png'), cb = handler(self, self.BuyChallengeTimesClickHandler)})
	settingsLayer:addChild(leftChallengeTimesBtn)
	leftChallengeTimesBtn:setVisible(false)

	display.setNodesToNodeOnCenter(
		settingsLayer,
		{leftChallengeTimesLabel, leftChallengeTimesBtn},
		{spaceW = 10, y = autoMatchBtn:getPositionY() - autoMatchBtn:getContentSize().height * 0.5 - 20}
	)

	self.viewData.leftChallengeTimesLabel = leftChallengeTimesLabel
	self.viewData.leftChallengeTimesBtn = leftChallengeTimesBtn

	-- 顶部搜索房间
	local searchTeamBg = display.newImageView(_res('ui/raid/hall/raid_boss_IDsearch.png'), 0, 0)
	display.commonUIParams(searchTeamBg, {ap = cc.p(0.5, 1), po = cc.p(
		settingsBgPos.x,
		size.height
	)})
	parentNode:addChild(searchTeamBg, 10)

	local searchTitleLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('查找队伍'), fontSize = 22, color = '#ffdab6'}))
	display.commonUIParams(searchTitleLabel, {po = cc.p(
		utils.getLocalCenter(searchTeamBg).x,
		searchTeamBg:getContentSize().height - 30
	)})
	searchTeamBg:addChild(searchTitleLabel)

	local searchInputBgSize = cc.size(200, 50)
	local searchInputBg = display.newImageView(_res('ui/common/common_bg_input_default.png'), 0, 0, {scale9 = true, size = searchInputBgSize, enable = true})
	display.commonUIParams(searchInputBg, {po = cc.p(
		searchTeamBg:getPositionX() - 20,
		searchTeamBg:getPositionY() - searchTeamBg:getContentSize().height * 0.5 - 20
	), cb = handler(self, self.SearchEditBoxClickHandler)})
	parentNode:addChild(searchInputBg, 15)

	local searchBtn = display.newButton(0, 0, {n = _res('ui/common/raid_boss_btn_search.png')})
	display.commonUIParams(searchBtn, {po = cc.p(
		searchInputBg:getPositionX() + searchInputBgSize.width * 0.5 + 10 + searchBtn:getContentSize().width * 0.5,
		searchInputBg:getPositionY()
	), cb = handler(self, self.SearchClickHandler)})
	parentNode:addChild(searchBtn, 15)

	local searchTeamIdLabel = display.newLabel(0, 0, {text = __('请输入队伍号查找'), fontSize = 20, color = '#9c9c9c', w = searchInputBgSize.width - 10})
	display.commonUIParams(searchTeamIdLabel, {ap = cc.p(0, 0.5), po = cc.p(
		5,
		searchInputBgSize.height * 0.5
	)})
	searchInputBg:addChild(searchTeamIdLabel)

	self.viewData.setPwdBtn = setPwdBtn
	self.viewData.pwdLabelCover = pwdLabelCover
	self.viewData.passwordLabel = passwordLabel
	self.viewData.searchTeamIdLabel = searchTeamIdLabel
end
--[[
刷新房间内样式
--]]
function RaidHallScene:InitRaidTeamSettingsViewTeam()
	-- 隐藏背景图
	self.viewData.bg:setVisible(false)
	self.eaterLayer:setVisible(true)
	self.eaterLayer:setOpacity(255 * 0.75)

	-- 返回按钮回调
	display.commonUIParams(self.viewData.backBtn, {cb = handler(self, self.CloseSelfClickHandler)})

	local size = self:getContentSize()
	local parentNode = self.viewData.view
	local settingsBgPos = cc.p(
		self.viewData.settingsBg:getPositionX(),
		self.viewData.settingsBg:getPositionY()
	)

	local layerSize = self.viewData.settingsBg:getContentSize()
	local settingsLayer = display.newLayer(0, 0, {size = layerSize})
	display.commonUIParams(settingsLayer, {ap = cc.p(0.5, 0.5), po = settingsBgPos})
	parentNode:addChild(settingsLayer, 1)

	-- 密码底
	local passwordBgPos = cc.p(
		layerSize.width * 0.5,
		layerSize.height * 0.5 + 10
	)
	local passwordBg = display.newImageView(_res('ui/raid/hall/raid_bg_newroom.png'), 0, 0)
	display.commonUIParams(passwordBg, {po = passwordBgPos})
	settingsLayer:addChild(passwordBg)

	-- 设置密码按钮
	local setPwdBtn = display.newCheckBox(0, 0, {
		n = _res('ui/common/gut_task_ico_select.png'),
		s = _res('ui/common/gut_task_ico_hook.png')
	})
	display.commonUIParams(setPwdBtn, {po = cc.p(
		passwordBgPos.x - 45,
		passwordBgPos.y + 70
	)})
	settingsLayer:addChild(setPwdBtn)
	setPwdBtn:setOnClickScriptHandler(handler(self, self.SetPwdBtnClickHandler))
	setPwdBtn:setVisible(false)

	local setPwdLabel = display.newLabel(0, 0,
		{text = __('设置密码'), fontSize = 22, color = '#e3bf98'})
	display.commonUIParams(setPwdLabel, {ap = cc.p(0, 0.5), po = cc.p(
		setPwdBtn:getPositionX() + setPwdBtn:getContentSize().width * 0.5 + 5,
		setPwdBtn:getPositionY() - 2
	)})
	settingsLayer:addChild(setPwdLabel)
	setPwdLabel:setVisible(false)

	local pwdLabelBgSize = cc.size(150, 44)
	local pwdLabelCover = display.newLayer(0, 0, {size = pwdLabelBgSize, color = cc.c4b(100, 100, 100, 100), enable = true})
	display.commonUIParams(pwdLabelCover, {ap = cc.p(0.5, 0.5), po = cc.p(
		passwordBgPos.x,
		setPwdBtn:getPositionY() - setPwdBtn:getContentSize().height * 0.5 - 10 - pwdLabelBgSize.height * 0.5
	)})
	settingsLayer:addChild(pwdLabelCover, 10)
	pwdLabelCover:setVisible(false)

	local pwdLabelBg = display.newImageView(_res('ui/common/common_bg_input_default.png'), 0, 0,
		{scale9 = true, size = pwdLabelBgSize, enable = true})
	display.commonUIParams(pwdLabelBg, {po = cc.p(
		pwdLabelCover:getPositionX(),
		pwdLabelCover:getPositionY()
	), cb = handler(self, self.PasswordEditBoxClickHandler)})
	settingsLayer:addChild(pwdLabelBg, 9)
	pwdLabelBg:setVisible(false)

	local passwordLabel = display.newLabel(0, 0, fontWithColor('6', {text = self.passwordStr, w = pwdLabelBgSize.width - 20}))
	display.commonUIParams(passwordLabel, {ap = cc.p(0, 0.5), po = cc.p(
		10,
		pwdLabelBgSize.height * 0.5
	)})
	pwdLabelBg:addChild(passwordLabel)
	passwordLabel:setVisible(false)

	-- 更改关卡按钮
	local changeStageBtn = display.newButton(0, 0, {n = _res('ui/raid/hall/raid_btn_newroom.png')})
	display.commonUIParams(changeStageBtn, {po = cc.p(
		passwordBgPos.x,
		passwordBgPos.y - passwordBg:getContentSize().height * 0.5 + 15 + changeStageBtn:getContentSize().height * 0.5
	), cb = handler(self, self.ChangeStageClickHandler)})
	display.commonLabelParams(changeStageBtn, fontWithColor('14', {text = __('更改')}))
	settingsLayer:addChild(changeStageBtn, 9)

	-- 剩余次数
	local leftChallengeTimesLabel = display.newLabel(0, 0, {text = '剩余次数:0', fontSize = 22, color = '#fff4db'})
	settingsLayer:addChild(leftChallengeTimesLabel)
	leftChallengeTimesLabel:setVisible(false)

	local leftChallengeTimesBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_add.png'), cb = handler(self, self.BuyChallengeTimesClickHandler)})
	settingsLayer:addChild(leftChallengeTimesBtn)
	leftChallengeTimesBtn:setVisible(false)

	display.setNodesToNodeOnCenter(
		settingsLayer,
		{leftChallengeTimesLabel, leftChallengeTimesBtn},
		{spaceW = 10, y = changeStageBtn:getPositionY() - changeStageBtn:getContentSize().height * 0.5 - 20}
	)

	self.viewData.leftChallengeTimesLabel = leftChallengeTimesLabel
	self.viewData.leftChallengeTimesBtn = leftChallengeTimesBtn
	self.viewData.setPwdBtn = setPwdBtn
	self.viewData.pwdLabelCover = pwdLabelCover
	self.viewData.passwordLabel = passwordLabel
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
根据组队本类型刷新界面
@params raidQuestType RaidQuestType 组队本类型
@params playerLevel int 玩家
@params bossRareReward map boss稀有掉落信息
--]]
function RaidHallScene:RefreshUIByRaidQuestType(raidQuestType, playerLevel, bossRareReward)
	local raidGroupInfo = self:GetFormattedRaidGroupInfo(raidQuestType)
	self.raidGroupInfo = raidGroupInfo
	self.playerLevel = checkint(playerLevel)
	self.rareRewardInfo = bossRareReward or {}

	local zoomSliderList = self.viewData.zoomSliderList
	zoomSliderList:setCellCount(#raidGroupInfo)

	if nil == self.zoomSliderListCellChangeCB then
		self.zoomSliderListCellChangeCB = handler(self, self.ZoomSliderListCellChangeCallback)
		zoomSliderList:setCellChangeCB(self.zoomSliderListCellChangeCB)
	end
	if nil == self.zoomSliderListIndexPassChangeCB then
		self.zoomSliderListIndexPassChangeCB = handler(self, self.ZoomSliderListIndexPassCallback)
		zoomSliderList:setIndexPassChangeCB(self.zoomSliderListIndexPassChangeCB)
	end
	if nil == self.zoomSliderListIndexOverChangeCB then
		self.zoomSliderListIndexOverChangeCB = handler(self, self.ZoomSliderListIndexOverCallback)
		zoomSliderList:setIndexOverChangeCB(self.zoomSliderListIndexOverChangeCB)
	end

	zoomSliderList:reloadData()
end
--[[
左侧列表格子变换回调
--]]
function RaidHallScene:ZoomSliderListCellChangeCallback(c, i)
	local cell = c
	local index = i
	local groupInfo = self:GetRaidGroupInfoByGroupIndex(index)
	local stageId = checkint(groupInfo.quests[1])
	local stageConfig = CommonUtils.GetQuestConf(stageId)

	if nil == cell then
		cell = display.newLayer(0, 0, {size = zoomSliderListCellSize})

		-- 背景
		local bg = display.newImageView(_res('ui/raid/hall/raid_boss_list_frame_bg.png'), 0, 0)
		display.commonUIParams(bg, {po = utils.getLocalCenter(cell)})
		cell:addChild(bg)

		-- 前景
		local fg = display.newImageView(_res('ui/raid/hall/raid_boss_list_frame_default.png'), 0, 0)
		display.commonUIParams(fg, {po = cc.p(
			bg:getPositionX(),
			bg:getPositionY()
		)})
		cell:addChild(fg, 10)

		-- 锁定遮罩
		local lockCover = display.newImageView(_res('ui/raid/hall/raid_boss_list_frame_locked.png'), 0, 0)
		display.commonUIParams(lockCover, {po = cc.p(
			bg:getPositionX(),
			bg:getPositionY()
		)})
		cell:addChild(lockCover, 25)
		lockCover:setTag(3)

		local lockIcon = display.newImageView(_res('ui/common/common_ico_lock.png'), 0, 0)
		display.commonUIParams(lockIcon, {po = cc.p(
			utils.getLocalCenter(lockCover).x,
			utils.getLocalCenter(lockCover).y + 20
		)})
		lockCover:addChild(lockIcon)

		local lockLabel = display.newLabel(0, 0, fontWithColor('18', {text = string.format(__('要求等级%d级'), checkint(groupInfo.unlockLevel))}))
		display.commonUIParams(lockLabel, {ap = cc.p(0.5, 1), po = cc.p(
			lockIcon:getPositionX(),
			lockIcon:getPositionY() - lockIcon:getContentSize().height * 0.5 - 3
		)})
		lockCover:addChild(lockLabel)
		lockLabel:setTag(3)

		-- boss头像
		local bossHeadNode = display.newImageView(CardUtils.GetCardHeadPathBySkinId(stageConfig.skin), 0, 0)
		display.commonUIParams(bossHeadNode, {po = cc.p(
			bg:getPositionX(),
			bg:getPositionY()
		)})
		cell:addChild(bossHeadNode, 5)
		bossHeadNode:setTag(5)

		-- 关卡名称
		local stageNameNode = display.newLabel(0, 0, {text = tostring(stageConfig.name), fontSize = 24, color = '#76534b'})
		display.commonUIParams(stageNameNode, {po = cc.p(
			zoomSliderListCellSize.width * 0.5,
			42
		)})
		cell:addChild(stageNameNode, 20)
		stageNameNode:setTag(7)

		-- 推荐标识
		local recommendMark = display.newNSprite(_res('ui/raid/hall/raid_boss_list_recommend.png'), 0, 0)
		display.commonUIParams(recommendMark, {po = cc.p(
			zoomSliderListCellSize.width,
			zoomSliderListCellSize.height * 0.75
		)})
		cell:addChild(recommendMark, 26)
		recommendMark:setTag(9)

		local recommendLabel = display.newLabel(0, 0, fontWithColor('18', {text = __('推荐')}))
		display.commonUIParams(recommendLabel, {po = cc.p(
			utils.getLocalCenter(recommendMark).x,
			utils.getLocalCenter(recommendMark).y
		)})
		recommendMark:addChild(recommendLabel)
	else
        display.commonLabelParams(cell:getChildByTag(3):getChildByTag(3),{text = string.format(__('要求等级%d级'), checkint(groupInfo.unlockLevel)) , w  = 180 , reqH = 40 , hAlign =display.TAC})
		cell:getChildByTag(5):setTexture(CardUtils.GetCardHeadPathBySkinId(stageConfig.skin))
		display.commonLabelParams(cell:getChildByTag(7) , { reqW = 160 , text = stageConfig.name })
	end
	cell:getChildByTag(3):setVisible(checkint(stageConfig.unlockLevel) > self.playerLevel)
	cell:getChildByTag(9):setVisible(false)


	return cell
end
--[[
格子滑动时的回调
--]]
function RaidHallScene:ZoomSliderListIndexPassCallback(sender, index)

end
--[[
格子滑动停止时的回调
--]]
function RaidHallScene:ZoomSliderListIndexOverCallback(sender, index)
	if nil ~= self.currentSelectedRaidGroupIndex then
		PlayAudioClip(AUDIOS.UI.ui_transport_cut.id)
	end
	-- 保存关卡组序号
	self.currentSelectedRaidGroupIndex = index
	-- 置空难度标签
	self.currentSelectedDiffIndex = nil
	self:RefreshStageDetailByGroupIndex(index)
end
--[[
根据组id跳转
@params groupId int 组id
--]]
function RaidHallScene:JumpByGroupId(groupId)
	local groupIndex = self:GetRaidGroupIndexByGroupId(groupId)

	-- 保存关卡组序号
	self.currentSelectedRaidGroupIndex = groupIndex
	-- 置空难度标签
	self.currentSelectedDiffIndex = nil

	-- 跳转左侧list
	self.viewData.zoomSliderList:setCenterIndex(groupIndex, true)
	-- 刷新中间关卡详情部分
	self:RefreshStageDetailByGroupIndex(groupIndex)
end
--[[
根据关卡id跳转
@params stageId int 关卡id
--]]
function RaidHallScene:JumpByStageId(stageId)
	local diffIndex = self:GetDiffIndexByStageId(stageId)
	local stageConfig = CommonUtils.GetQuestConf(stageId)
	local groupId = checkint(stageConfig.group)
	local groupIndex = self:GetRaidGroupIndexByGroupId(groupId)

	-- 保存关卡组序号
	self.currentSelectedRaidGroupIndex = groupIndex
	-- 置空难度标签
	self.currentSelectedDiffIndex = nil
	-- 跳转左侧list
	self.viewData.zoomSliderList:setCenterIndex(groupIndex, true)
	-- 刷新中间关卡详情部分
	self:RefreshStageDetailByGroupIndex(groupIndex, diffIndex)
end
--[[
根据组序号刷新中部关卡部分
@params groupIndex int 组序号
@params diffIndex int 难度序号
--]]
function RaidHallScene:RefreshStageDetailByGroupIndex(groupIndex, diffIndex)
	local groupInfo = self:GetRaidGroupInfoByGroupIndex(groupIndex)

	-- 刷新右侧选难度按钮
	self:RefreshGroupDifficultyBtn(groupIndex)

	-- 先默认显示第一个难度标签
	local diffIndex = diffIndex or 1
	self:RefreshUIByGroupIndexAndDiffIndex(groupIndex, diffIndex)
end
--[[
根据组序号刷新难度按钮
@params groupIndex int 组序号
--]]
function RaidHallScene:RefreshGroupDifficultyBtn(groupIndex)
	local groupInfo = self:GetRaidGroupInfoByGroupIndex(groupIndex)

	-- 移除老的按钮
	for i,v in ipairs(self.viewData.difficultyBtns) do
		v:removeFromParent()
	end
	self.viewData.difficultyBtns = {}


	local questAmount = #groupInfo.quests
	for i,v in ipairs(groupInfo.quests) do
		local stageId = checkint(v)
		local stageConfig = CommonUtils.GetQuestConf(stageId)
		local difficulty = checkint(stageConfig.difficulty)

		local difficultyBtn = display.newCheckBox(0, 0, {
			n = _res('ui/raid/hall/raid_difficulty_btn_default.png'),
			s = _res('ui/raid/hall/raid_btn_difficulty_active.png')
		})
		display.commonUIParams(difficultyBtn, {ap = cc.p(0.5, 1), po = cc.p(
			self.viewData.settingsBg:getPositionX() + ((i - 0.5) - (questAmount * 0.5)) * 120,
			self.viewData.settingsBg:getPositionY() + self.viewData.settingsBg:getContentSize().height * 0.5 - 33
		)})
		self.viewData.view:addChild(difficultyBtn)
		difficultyBtn:setTag(i)

		difficultyBtn:setOnClickScriptHandler(handler(self, self.DiffBtnClickHandler))

		table.insert(self.viewData.difficultyBtns, difficultyBtn)

		local diffDescrLabel = display.newLabel(0, 0,
			{text = RaidDifficultyDescrConfig[difficulty], fontSize = 26, color = '#c67542', w = 100, ttf = true, hAlign = display.TAC, reqH = 50 , font = TTF_GAME_FONT})
		display.commonUIParams(diffDescrLabel, {po = cc.p(
			difficultyBtn:getContentSize().width * 0.5,
			78
		)})
		difficultyBtn:addChild(diffDescrLabel)
		diffDescrLabel:setTag(3)

		local tailNode = display.newNSprite(_res(DiffBtnTailPath[difficulty]), 0, 0)
		display.commonUIParams(tailNode, {ap = cc.p(0.5, 1), po = cc.p(
			difficultyBtn:getContentSize().width * 0.5,
			60
		)})
		difficultyBtn:addChild(tailNode)
		tailNode:setTag(5)

	end
end
--[[
根据关卡id刷新关卡详情层
@params stageId int 关卡id
--]]
function RaidHallScene:RefreshStageDetailViewByStageId(stageId)
	local stageConfig = CommonUtils.GetQuestConf(stageId)
	local groupId = checkint(stageConfig.group)
	local gotRareReward = checkint(self.rareRewardInfo[tostring(groupId)])

	if nil == self.viewData.stageDetailView then
		-- 关卡详情界面
		local size = self.viewData.view:getContentSize()
		local raidStageDetailView = require('Game.views.raid.RaidStageDetailView').new({
			stageId = stageId,
			gotRareReward = gotRareReward,
			leftNormalDropTimes = self.leftChallengeTimes,
			enableDropWaring = true,
			enableBuyNormalDropTimes = true
		})
		display.commonUIParams(raidStageDetailView, {ap = cc.p(0.5, 0.5), po = cc.p(
			size.width * 0.4,
			size.height * 0.5
		)})
		self.viewData.view:addChild(raidStageDetailView, 10)
		self.viewData.stageDetailView = raidStageDetailView
	else
		self.viewData.stageDetailView:RefreshUI(stageId, gotRareReward, self.leftChallengeTimes)
	end
end
--[[
根据组序号 难度序号刷新界面
@params groupIndex int 组序号
@params diffIndex int 难度序号
--]]
function RaidHallScene:RefreshUIByGroupIndexAndDiffIndex(groupIndex, diffIndex)

	local curDiffBtn = self.viewData.difficultyBtns[diffIndex]
	if nil ~= curDiffBtn then
		-- 设置选中状态
		curDiffBtn:setChecked(true)
		-- 刷新文字和位置
		local diffDescrLabel = curDiffBtn:getChildByTag(3)
		if nil ~= diffDescrLabel then
			diffDescrLabel:setColor(ccc3FromInt('#ffffff'))
			diffDescrLabel:setPositionY(63)
		end
		-- 刷新尾穗位置
		local tailNode = curDiffBtn:getChildByTag(5)
		if nil ~= tailNode then
			tailNode:setPositionY(45)
		end
	end

	if self.currentSelectedRaidGroupIndex == groupIndex and self.currentSelectedDiffIndex == diffIndex then return end

	local preDiffBtn = self.viewData.difficultyBtns[self.currentSelectedDiffIndex]
	if nil ~= preDiffBtn then
		-- 设置选中状态
		preDiffBtn:setChecked(false)
		-- 刷新文字和位置
		local diffDescrLabel = preDiffBtn:getChildByTag(3)
		if nil ~= diffDescrLabel then
			diffDescrLabel:setColor(ccc3FromInt('#c67542'))
			diffDescrLabel:setPositionY(78)
		end
		-- 刷新尾穗位置
		local tailNode = preDiffBtn:getChildByTag(5)
		if nil ~= tailNode then
			tailNode:setPositionY(60)
		end
	end

	self.currentSelectedDiffIndex = diffIndex

	-- 刷新关卡详情
	local stageId = self:GetStageIdByGroupIndexAndDiffIndex(groupIndex, diffIndex)
	self:RefreshStageDetailViewByStageId(stageId)
end
--[[
刷新剩余次数
@params times int 剩余次数
--]]
function RaidHallScene:RefreshLeftChallengeTimes(times)
	self.leftChallengeTimes = times

	self.viewData.leftChallengeTimesLabel:setString(string.format(__('剩余次数:%d'), times))
	-- 刷新一次位置
	display.setNodesToNodeOnCenter(
		self.viewData.leftChallengeTimesLabel:getParent(),
		{self.viewData.leftChallengeTimesLabel, self.viewData.leftChallengeTimesBtn},
		{spaceW = 10, y = self.viewData.leftChallengeTimesLabel:getPositionY()}
	)

	if nil ~= self.viewData.stageDetailView then
		self.viewData.stageDetailView:RefreshLeftNormalDropTimes(times)
	end
end
--[[
设置密码按钮回调
--]]
function RaidHallScene:SetPwd()
	local setPwd = self.viewData.setPwdBtn:isChecked()
	-- 屏蔽设置密码层触摸
	self.viewData.pwdLabelCover:setVisible(not setPwd)
end
--[[
密码框按钮回调
--]]
function RaidHallScene:ShowChangePassword()
	uiMgr:ShowNumberKeyBoard({
		nums = 6,
		model = 2,
		callback = function (str)
			-- print('here check input password', str)
			self.passwordStr = str
			if self.viewData and self.viewData.passwordLabel then
				self.viewData.passwordLabel:setString(self.passwordStr)
			end
		end,
		titleText = __('请输入六位数字密码'),
		defaultContent = self.passwordStr
	})
end
--[[
显示输入房间id
--]]
function RaidHallScene:ShowInputTeamId()
	uiMgr:ShowNumberKeyBoard({
		nums = 10,
		model = 2,
		callback = function (str)
			print('here check input teamid', str)
			self.teamIdStr = str
			self.viewData.searchTeamIdLabel:setString(self.teamIdStr)
		end,
		titleText = __('请输入队伍号'),
		defaultContent = self.teamIdStr
	})
end
--[[
刷新默认的密码
@params defaultPassword string 默认的密码
--]]
function RaidHallScene:RefreshDefaultPassword(password)
	if 0 < string.len(string.gsub(password, ' ', '')) then
		-- 有密码 刷新样式
		self.viewData.setPwdBtn:setChecked(true)
		-- 屏蔽设置密码层触摸
		self.viewData.pwdLabelCover:setVisible(false)
		-- 刷新密码
		self.passwordStr = password
		self.viewData.passwordLabel:setString(self.passwordStr)
	end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
--[[
难度按钮点击回调
--]]
function RaidHallScene:DiffBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local index = sender:getTag()
	self:RefreshUIByGroupIndexAndDiffIndex(self.currentSelectedRaidGroupIndex, index)
end
--[[
创建房间按钮回调
--]]
function RaidHallScene:CreateTeamBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local currentSelectedStageId = self:GetStageIdByGroupIndexAndDiffIndex(self.currentSelectedRaidGroupIndex, self.currentSelectedDiffIndex)
	AppFacade.GetInstance():DispatchObservers('RAID_CREATE_TEAM', {stageId = currentSelectedStageId, password = self.passwordStr})
end
--[[
自动匹配按钮回调
--]]
function RaidHallScene:AutoMatchBtnClickHandler(sender)
	PlayAudioByClickNormal()
	local currentSelectedStageId = self:GetStageIdByGroupIndexAndDiffIndex(self.currentSelectedRaidGroupIndex, self.currentSelectedDiffIndex)
	AppFacade.GetInstance():DispatchObservers('RAID_AUTO_MATCH', {stageId = currentSelectedStageId})
end
--[[
设置密码按钮回调
--]]
function RaidHallScene:SetPwdBtnClickHandler(sender)
	PlayAudioByClickNormal()
	self:SetPwd()
end
--[[
密码框按钮回调
--]]
function RaidHallScene:PasswordEditBoxClickHandler(sender)
	PlayAudioByClickNormal()
	self:ShowChangePassword()
end
--[[
搜索房间输入框按钮回调
--]]
function RaidHallScene:SearchEditBoxClickHandler(sender)
	PlayAudioByClickNormal()
	self:ShowInputTeamId()
end
--[[
搜索按钮回调
--]]
function RaidHallScene:SearchClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('RAID_SEARCH_TEAM', {teamId = self.teamIdStr})
end
--[[
购买次数按钮回调
--]]
function RaidHallScene:BuyChallengeTimesClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('RAID_SHOW_BUY_CHALLENGE_TIMES')
end
--[[
退出大厅按钮回调
--]]
function RaidHallScene:ExitRaidHallClickHandler(sender)
	PlayAudioByClickClose()
	AppFacade.GetInstance():DispatchObservers('EXIT_RAID_HALL')
end
--[[
返回按钮回调
--]]
function RaidHallScene:CloseSelfClickHandler(sender)
	PlayAudioByClickNormal()
	self:CloseSelf()
end
--[[
关闭自己
--]]
function RaidHallScene:CloseSelf()
	uiMgr:GetCurrentScene():RemoveDialog(self)
end
--[[
更改按钮点击回调
--]]
function RaidHallScene:ChangeStageClickHandler(sender)
	PlayAudioByClickNormal()
	-- 弹确认框
	local commonTip = require('common.NewCommonTip').new({
		text = __('确认更改关卡?'),
		callback = function ()
			local currentSelectedStageId = self:GetStageIdByGroupIndexAndDiffIndex(self.currentSelectedRaidGroupIndex, self.currentSelectedDiffIndex)
			AppFacade.GetInstance():DispatchObservers('RAID_CHANGE_STAGE', {stageId = currentSelectedStageId, password = self.passwordStr})
			-- 关闭自己
			self:CloseSelf()
		end
	})
	commonTip:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(commonTip)
end
---------------------------------------------------
-- click handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据组队本类型获取格式化后的组队笨组别的配置
@params raidQuestType RaidQuestType 组队本类型
@return raidGroupInfo list 格式化后的组队本组别信息
--]]
function RaidHallScene:GetFormattedRaidGroupInfo(raidQuestType)
	local raidGroupConfig = CommonUtils.GetConfig('quest', 'teamBossGroup', raidQuestType)
	local raidGroupInfo = {}
	local groupIdsk = sortByKey(raidGroupConfig)
	for _, groupId_ in ipairs(groupIdsk) do
		local groupConf = raidGroupConfig[groupId_]
		local groupInfo = {
			groupId = checkint(groupId_),
			quests = {},
			unlockLevel = checkint(groupConf.unlockLevel)
		}
		for _, stageId_ in pairs(groupConf.quests) do
			table.insert(groupInfo.quests, checkint(stageId_))
		end
		table.sort(groupInfo.quests, function (a, b)
			local stageaConfig = CommonUtils.GetQuestConf(a)
			local stagebConfig = CommonUtils.GetQuestConf(b)
			if checkint(stageaConfig.difficulty) == checkint(stagebConfig.difficulty) then
				return a < b
			else
				return checkint(stageaConfig.difficulty) < checkint(stagebConfig.difficulty)
			end
		end)
		table.insert(raidGroupInfo, groupInfo)
	end

	return raidGroupInfo
end
--[[
根据关卡组别获取组别序号
@params raidGroupId int 组id
@return groupIndex int 组序号
--]]
function RaidHallScene:GetRaidGroupIndexByGroupId(raidGroupId)
	local groupIndex = 1
	for i,v in ipairs(self.raidGroupInfo) do
		if checkint(v.groupId) == checkint(raidGroupId) then
			groupIndex = i
			break
		end
	end
	return groupIndex
end
--[[
根据组序号获取组信息
@params groupIndex int 组序号
--]]
function RaidHallScene:GetRaidGroupInfoByGroupIndex(groupIndex)
	return self.raidGroupInfo[groupIndex]
end
--[[
根据组序号和难度序号获取关卡id
@params groupIndex int 组序号
@params diffIndex int 难度序号
--]]
function RaidHallScene:GetStageIdByGroupIndexAndDiffIndex(groupIndex, diffIndex)
	local stageId = nil
	local groupInfo = self:GetRaidGroupInfoByGroupIndex(groupIndex)
	if nil ~= groupInfo then
		stageId = groupInfo.quests[diffIndex]
	end
	return stageId
end
--[[
根据关卡id获取难度序号
@params stageId int 关卡id
@params _ int 难度序号
--]]
function RaidHallScene:GetDiffIndexByStageId(stageId)
	local stageConfig = CommonUtils.GetQuestConf(stageId)
	local groupInfo = self:GetRaidGroupInfoByGroupIndex(self:GetRaidGroupIndexByGroupId(checkint(stageConfig.group)))
	if nil ~= groupInfo then
		for i,v in ipairs(groupInfo.quests) do
			if v == checkint(stageId) then
				return i
			end
		end
	end
	return 1
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return RaidHallScene
