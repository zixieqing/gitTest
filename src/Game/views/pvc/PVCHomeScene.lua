--[[
离线pvp主场景
--]]
local GameScene = require( "Frame.GameScene" )
local PVCHomeScene = class("PVCHomeScene", GameScene)

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
------------ import ------------

------------ define ------------
local PVCSceneZorder = {
	BASE = 5,
	CENTER = 20,
	TOP = 90
}
------------ define ------------

--[[
constructor
--]]
function PVCHomeScene:ctor(...)

	local args = unpack({...})

	GameScene.ctor(self, 'Game.views.pvc.PVCHomeScene')

	self:InitUI()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function PVCHomeScene:InitUI()

	local function CreateView()

		local size = display.size
		local selfCenter = cc.p(size.width * 0.5, size.height * 0.5)

		local uiLocationInfo = {
			centerAvatarBgOffsetY = -52,
			bottomTeamBgCenterFixedY = 50,
			leftTimeBgFixedY = 0,
			avatarFixedPL = cc.p(-145, -20),
			avatarFixedPR = cc.p(145, -20),
			infoBoardFixedP = cc.p(0, 0),
			centerMarkFixedP = cc.p(0, -70),
			battleBtnFixedY = 125,
			avatarBottomSplitY = selfCenter.y - 237,
			bottomTeamBgHeight = 100
		}

		-- 背景图
		local bg = display.newImageView(_res('ui/common/pvp_main_bg.jpg'), selfCenter.x, selfCenter.y, {isFull = true})
		self:addChild(bg)

		-- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height + 100,{n = _res('ui/common/common_title_new.png'), enable = true, ap = cc.p(0, 0)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('皇家试炼'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
		self:addChild(tabNameLabel, PVCSceneZorder.TOP)

		tabNameLabel:addChild(display.newImageView(_res('ui/common/common_btn_tips.png'), tabNameLabel:getContentSize().width - 50, tabNameLabel:getContentSize().height/2 - 10))

		-- 返回按钮
		local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = _res('ui/common/common_btn_back.png'), cb = handler(self, self.BackClickHandler)})
		self:addChild(backBtn, PVCSceneZorder.TOP)

		-- guide button 
		local guideBtn = display.newButton(500 + display.SAFE_L, display.height - 42, {n = _res('guide/guide_ico_book.png')})
		display.commonLabelParams(guideBtn, fontWithColor(14, {text = __('指南') , hAlign = display.TAC, fontSize = 28,  offset = cc.p(10,-30) ,reqW =160}))
		self:addChild(guideBtn, PVCSceneZorder.TOP)
		display.commonUIParams(guideBtn, {cb = function(sender)
			local guideNode = require('common.GuideNode').new({tmodule = 'pvp'})
			sceneWorld:addChild(guideNode, GameSceneTag.Guide_GameSceneTag)
		end})

		-------------------------------------------------
		-- 活跃度奖励按钮
		local activeBtnBg = display.newImageView(_res('ui/pvc/pvp_reward_ico_L_default.png'), 0, 0,
			{enable = true, cb = handler(self, self.ActivePointClickHandler)})
		display.commonUIParams(activeBtnBg, {po = cc.p(
			display.SAFE_R - 200,
			size.height - TOP_HEIGHT - activeBtnBg:getContentSize().height * 0.5 - 20
		)})
		self:addChild(activeBtnBg, PVCSceneZorder.TOP)

		local activeRewardIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(191004)), 0, 0)
		activeRewardIcon:setScale((activeBtnBg:getContentSize().width) / activeRewardIcon:getContentSize().width)
		display.commonUIParams(activeRewardIcon, {po = cc.p(
			utils.getLocalCenter(activeBtnBg).x,
			utils.getLocalCenter(activeBtnBg).y + 5
		)})
		activeBtnBg:addChild(activeRewardIcon)

		local activeRewardLabel = display.newLabel(0, 0, {
			text = __('活跃奖励'), fontSize = 22, color = '#ffffff', ttf = true, font = 'font/FZCQJW.TTF', outline = '#412225'
		})
		display.commonUIParams(activeRewardLabel, {po = cc.p(
			utils.getLocalCenter(activeBtnBg).x,
			10
		)})
		activeBtnBg:addChild(activeRewardLabel)

		local maxActivePointLabel = display.newLabel(0, 0,
			{text = '/' .. PVC_ACTIVE_POINT_MAX, fontSize = 22, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#412225'})
		display.commonUIParams(maxActivePointLabel, {ap = cc.p(0, 0.5), po = cc.p(
			activeBtnBg:getPositionX() - 5,
			activeBtnBg:getPositionY() - activeBtnBg:getContentSize().height * 0.5 - 10
		)})
		self:addChild(maxActivePointLabel, PVCSceneZorder.TOP)

		local activePointLabel = display.newLabel(0, 0,
			{text = '0', fontSize = 22, color = '#ffc266', ttf = true, font = TTF_GAME_FONT, outline = '#412225'})
		display.commonUIParams(activePointLabel, {ap = cc.p(1, 0.5), po = cc.p(
			maxActivePointLabel:getPositionX() + 2,
			maxActivePointLabel:getPositionY()
		)})
		self:addChild(activePointLabel, PVCSceneZorder.TOP)

		-- local activePointLabel = display.newRichLabel(0, 0, {r = true, c = {
		-- 	{text = '466', fontSize = 22, color = '#ffc266', ttf = true, font = TTF_GAME_FONT, outline = '#412225'},
		-- 	{text = '/500', fontSize = 22, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#412225'}
		-- }})
		-- display.commonUIParams(activePointLabel, {po = cc.p(
		-- 	activeBtnBg:getPositionX(),
		-- 	activeBtnBg:getPositionY() - activeBtnBg:getContentSize().height * 0.5 - 10
		-- )})
		-- self:addChild(activePointLabel, PVCSceneZorder.TOP)

		-- 勋章商城按钮
		local medalShopBtn = display.newButton(0, 0, {
			n = _res('ui/pvc/pvp_ico_pvpstore.png'),
			cb = handler(self, self.PVCShopClickHandler)
		})
		display.commonUIParams(medalShopBtn, {po = cc.p(
			activeBtnBg:getPositionX() + 120,
			activeBtnBg:getPositionY() + 5
		)})
		self:addChild(medalShopBtn, PVCSceneZorder.TOP)

		local medalShopLabel = display.newLabel(0, 0, {
			text = __('勋章商店'), w = 110, hAlign= display.TAC, ap = display.CENTER_TOP,  fontSize = 22, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#412225'
		})
		display.commonUIParams(medalShopLabel, {po = cc.p(
			utils.getLocalCenter(medalShopBtn).x,
			5
		)})
		medalShopBtn:addChild(medalShopLabel)

		-------------------------------------------------
		-- 左右小人底盘
		local avatarBottomLeft = display.newImageView(_res('ui/pvc/pvp_main_bg_base_blue.png'), 0, 0)
		display.commonUIParams(avatarBottomLeft, {ap = display.RIGHT_CENTER, po = cc.p(
			display.cx - 90,
			uiLocationInfo.avatarBottomSplitY + avatarBottomLeft:getContentSize().height * 0.5
		)})
		self:addChild(avatarBottomLeft, PVCSceneZorder.BASE + 1)

		local avatarBottomRight = display.newImageView(_res('ui/pvc/pvp_main_bg_base_red.png'), 0, 0)
		display.commonUIParams(avatarBottomRight, {ap = display.LEFT_CENTER, po = cc.p(
			display.cx + 90,
			avatarBottomLeft:getPositionY()
		)})
		self:addChild(avatarBottomRight, PVCSceneZorder.BASE + 1)

		-- debug --
		-- local testlayer = display.newLayer(0, 0, {size = cc.size(display.width, display.height), ap = cc.p(0.5, 0.5)})
		-- testlayer:setBackgroundColor(cc.c4b(100, 100, 255, 128))
		-- display.commonUIParams(testlayer, {po = cc.p(
		-- 	display.cx,
		-- 	uiLocationInfo.avatarBottomSplitY + testlayer:getContentSize().height * 0.5
		-- )})
		-- self:addChild(testlayer, 99999)
		-- debug --

		-- 左右小人光
		local avatarLightLeft = display.newImageView(_res('ui/pvc/pvp_main_bg_base_light.png'), 0, 0)
		display.commonUIParams(avatarLightLeft, {ap = cc.p(0.5, 0), po = cc.p(
			avatarBottomLeft:getPositionX() + uiLocationInfo.avatarFixedPL.x - 4,
			avatarBottomLeft:getPositionY() + uiLocationInfo.avatarFixedPL.y - 10
		)})
		self:addChild(avatarLightLeft, PVCSceneZorder.BASE + 5)

		local avatarLightRight = display.newImageView(_res('ui/pvc/pvp_main_bg_base_light.png'), 0, 0)
		display.commonUIParams(avatarLightRight, {ap = cc.p(0.5, 0), po = cc.p(
			avatarBottomRight:getPositionX() + uiLocationInfo.avatarFixedPR.x,
			avatarBottomRight:getPositionY() + uiLocationInfo.avatarFixedPR.y - 8
		)})
		self:addChild(avatarLightRight, PVCSceneZorder.BASE + 5)

		-- debug --
		-- local l = display.newLayer(0, 0, {size = cc.size(150, 150)})
		-- l:setBackgroundColor(cc.c4b(255, 128, 128, 100))
		-- display.commonUIParams(l, {ap = cc.p(0.5, 0), po = cc.p(
		-- 	avatarBottomRight:getPositionX() + uiLocationInfo.avatarFixedPR.x,
		-- 	avatarBottomRight:getPositionY() + uiLocationInfo.avatarFixedPR.y
		-- )})
		-- self:addChild(l, 999)
		-- debug --

		-- 左右点选队伍按钮
		local changeFriendFightTeamBar = display.newButton(0, 0, {n = _res('ui/pvc/pvp_label_change_blue.png'), enable = false ,ap = display.RIGHT_CENTER,})
		display.commonLabelParams(changeFriendFightTeamBar, fontWithColor('18', {  fontSize = 18, text = __('编辑进攻队伍'), paddingW = 40, offset = cc.p(10,0)}))
		display.commonUIParams(changeFriendFightTeamBar, {po = cc.p(
			avatarBottomLeft:getPositionX() - 200,
			uiLocationInfo.avatarBottomSplitY + changeFriendFightTeamBar:getContentSize().height * 0.5
		)})
		self:addChild(changeFriendFightTeamBar, PVCSceneZorder.TOP)

		local changeRivalTeamBar = display.newButton(0, 0, {n = _res('ui/pvc/pvp_label_change_red.png'), enable = false})
		display.commonLabelParams(changeRivalTeamBar, fontWithColor('18', {fontSize = 18, text = __('点击更换对手'), paddingW = 40, offset = cc.p(-10,0) }))
		display.commonUIParams(changeRivalTeamBar, {po = cc.p(
			avatarBottomRight:getPositionX() + 220,
			changeFriendFightTeamBar:getPositionY()
		)})
		self:addChild(changeRivalTeamBar, PVCSceneZorder.TOP)

		-- 左右战斗力值
		local friendTeamBattlePointBg = sp.SkeletonAnimation:create('effects/fire/skeleton.json', 'effects/fire/skeleton.atlas', 1)
		friendTeamBattlePointBg:update(0)
		friendTeamBattlePointBg:setAnimation(0, 'huo', true)
		friendTeamBattlePointBg:setPosition(cc.p(
			size.width * 0.5 - 155,
			uiLocationInfo.avatarBottomSplitY
		))
		self:addChild(friendTeamBattlePointBg, PVCSceneZorder.TOP)

		local friendTeamBattlePointLabel = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', '111123')
		friendTeamBattlePointLabel:setAnchorPoint(cc.p(0.5, 0.5))
		friendTeamBattlePointLabel:setHorizontalAlignment(display.TAC)
		friendTeamBattlePointLabel:setPosition(cc.p(
			friendTeamBattlePointBg:getPositionX(),
			friendTeamBattlePointBg:getPositionY() + 10
		))
		self:addChild(friendTeamBattlePointLabel, PVCSceneZorder.TOP)
		friendTeamBattlePointLabel:setScale(0.7)

		local rivalTeamBattlePointBg = sp.SkeletonAnimation:create('effects/fire/skeleton.json', 'effects/fire/skeleton.atlas', 1)
		rivalTeamBattlePointBg:update(0)
		rivalTeamBattlePointBg:setAnimation(0, 'huo', true)
		rivalTeamBattlePointBg:setPosition(cc.p(
			size.width * 0.5 + 155,
			friendTeamBattlePointBg:getPositionY()
		))
		self:addChild(rivalTeamBattlePointBg, PVCSceneZorder.TOP)

		local rivalTeamBattlePointLabel = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', '111123')
		rivalTeamBattlePointLabel:setAnchorPoint(cc.p(0.5, 0.5))
		rivalTeamBattlePointLabel:setHorizontalAlignment(display.TAC)
		rivalTeamBattlePointLabel:setPosition(cc.p(
			rivalTeamBattlePointBg:getPositionX(),
			rivalTeamBattlePointBg:getPositionY() + 10
		))
		self:addChild(rivalTeamBattlePointLabel, PVCSceneZorder.TOP)
		rivalTeamBattlePointLabel:setScale(0.7)

		-- 左右按鈕
		local changeFriendFightTeamBtn = display.newImageView(_res('ui/tower/path/tower_btn_team_add.png'), 0, 0)
		display.commonUIParams(changeFriendFightTeamBtn, {po = cc.p(
			avatarBottomLeft:getPositionX() + uiLocationInfo.avatarFixedPL.x,
			avatarBottomLeft:getPositionY() + uiLocationInfo.avatarFixedPL.y + changeFriendFightTeamBtn:getContentSize().height * 0.5 + 80
		)})
		self:addChild(changeFriendFightTeamBtn, PVCSceneZorder.BASE + 2)

		local changeFriendFightTeamIcon = display.newNSprite(_res('ui/common/maps_fight_btn_pet_add.png'), 0, 0)
		display.commonUIParams(changeFriendFightTeamIcon, {po = cc.p(
			changeFriendFightTeamBtn:getContentSize().width * 0.5,
			changeFriendFightTeamBtn:getContentSize().height * 0.5 + 5
		)})
		changeFriendFightTeamBtn:addChild(changeFriendFightTeamIcon)

		local changeFriendFightTeamBtnLayer = display.newButton(0, 0, {size = cc.size(220, 300)})
		display.commonUIParams(changeFriendFightTeamBtnLayer, {ap = cc.p(0.5, 0), po = cc.p(
			avatarBottomLeft:getPositionX() + uiLocationInfo.avatarFixedPL.x,
			avatarBottomLeft:getPositionY() + uiLocationInfo.avatarFixedPL.y - 50
		), animate = false, cb = handler(self, self.ChangeFightTeamClickHandler)})
		self:addChild(changeFriendFightTeamBtnLayer, PVCSceneZorder.BASE + 2)

		local changeRivalTeamBtn = display.newImageView(_res('ui/pvc/pvp_main_ico_base_unknow.png'), 0, 0)
		display.commonUIParams(changeRivalTeamBtn, {po = cc.p(
			avatarBottomRight:getPositionX() + uiLocationInfo.avatarFixedPR.x,
			changeFriendFightTeamBtn:getPositionY()
		)})
		self:addChild(changeRivalTeamBtn, PVCSceneZorder.BASE + 2)

		local changeRivalTeamBtnLayer = display.newButton(0, 0, {size = cc.size(220, 300)})
		display.commonUIParams(changeRivalTeamBtnLayer, {ap = cc.p(0.5, 0), po = cc.p(
			avatarBottomRight:getPositionX() + uiLocationInfo.avatarFixedPR.x,
			avatarBottomRight:getPositionY() + uiLocationInfo.avatarFixedPR.y - 50
		), animate = false, cb = handler(self, self.ChangeRivalTeamClickHandler)})
		self:addChild(changeRivalTeamBtnLayer, PVCSceneZorder.BASE + 2)

		-------------------------------------------------
		-- 雕像
		local centerMark = display.newImageView(_res('ui/common/pvp_main_bg_vs.png'), 0, 0)
		display.commonUIParams(centerMark, {po = cc.p(
			selfCenter.x + uiLocationInfo.centerMarkFixedP.x,
			selfCenter.y + uiLocationInfo.centerMarkFixedP.y
		)})
		self:addChild(centerMark, PVCSceneZorder.BASE - 1)

		-- 阵容底
		local bottomTeamBg = display.newImageView(_res('ui/pvc/pvp_main_bg_below.png'), 0, 0)
		display.commonUIParams(bottomTeamBg, {po = cc.p(
			selfCenter.x,
			uiLocationInfo.avatarBottomSplitY - bottomTeamBg:getContentSize().height * 0.5 + 20
		)})
		self:addChild(bottomTeamBg, PVCSceneZorder.BASE)

		-- 换阵容按钮
		local changeFriendFightTeamBtnBottomLayer = display.newButton(0, 0,
			{size = cc.size(display.SAFE_RECT.width - 175, uiLocationInfo.bottomTeamBgHeight)})
		display.commonUIParams(changeFriendFightTeamBtnBottomLayer, {ap = cc.p(1, 0.5), po = cc.p(
			selfCenter.x - 175,
			bottomTeamBg:getPositionY() + uiLocationInfo.bottomTeamBgCenterFixedY
		), animate = false, cb = handler(self, self.ChangeFightTeamClickHandler)})
		self:addChild(changeFriendFightTeamBtnBottomLayer, PVCSceneZorder.BASE + 2)

		-- local target1 = changeFriendFightTeamBtnBottomLayer
		-- local test1 = display.newLayer(target1:getPositionX(), target1:getPositionY(),
		-- 	{size = target1:getContentSize(), ap = target1:getAnchorPoint()})
		-- test1:setBackgroundColor(cc.c4b(100, 100, 255, 100))
		-- target1:getParent():addChild(test1, target1:getLocalZOrder())

		local changeRivalFightTeamBtnBottomLayer = display.newButton(0, 0,
			{size = cc.size(display.SAFE_RECT.width - 175, uiLocationInfo.bottomTeamBgHeight)})
		display.commonUIParams(changeRivalFightTeamBtnBottomLayer, {ap = cc.p(0, 0.5), po = cc.p(
			selfCenter.x + 175,
			changeFriendFightTeamBtnBottomLayer:getPositionY()
		), animate = false, cb = handler(self, self.ChangeRivalTeamClickHandler)})
		self:addChild(changeRivalFightTeamBtnBottomLayer, PVCSceneZorder.BASE + 2)

		-- local target2 = changeRivalFightTeamBtnBottomLayer
		-- local test2 = display.newLayer(target2:getPositionX(), target2:getPositionY(),
		-- 	{size = target2:getContentSize(), ap = target2:getAnchorPoint()})
		-- test2:setBackgroundColor(cc.c4b(100, 255, 255, 100))
		-- target2:getParent():addChild(test2, target2:getLocalZOrder())

		local friendFightTeamEmptyNodes = {}
		local rivalFightTeamEmptyNodes = {}
		-- 友方空阵容
		for i = 1, MAX_TEAM_MEMBER_AMOUNT do
			local friendDefaultHead = display.newNSprite(_res('ui/pvc/pvp_main_ico_nocard.png'), 0, 0)
			display.commonUIParams(friendDefaultHead, {po = cc.p(
				bottomTeamBg:getPositionX() - 215 - (i - 1) * (95),
				bottomTeamBg:getPositionY() + uiLocationInfo.bottomTeamBgCenterFixedY
			)})
			self:addChild(friendDefaultHead, PVCSceneZorder.BASE + 1)

			friendFightTeamEmptyNodes[i] = friendDefaultHead
		end

		-- 敌方空阵容
		for i = 1, MAX_TEAM_MEMBER_AMOUNT do
			local rivalDefaultHead = display.newNSprite(_res('ui/pvc/pvp_main_ico_nocard.png'), 0, 0)
			display.commonUIParams(rivalDefaultHead, {po = cc.p(
				bottomTeamBg:getPositionX() + 215 + (i - 1) * (95),
				bottomTeamBg:getPositionY() + uiLocationInfo.bottomTeamBgCenterFixedY
			)})
			self:addChild(rivalDefaultHead, PVCSceneZorder.BASE + 1)

			rivalFightTeamEmptyNodes[i] = rivalDefaultHead
		end

		-- 挑战按钮
		local battleBtn = require('common.CommonBattleButton').new({
			pattern = 1,
			clickCallback = handler(self, self.DuelClickHandler)
		})
		display.commonUIParams(battleBtn, {po = cc.p(
			selfCenter.x,
			bottomTeamBg:getPositionY() + uiLocationInfo.battleBtnFixedY
		)})
		self:addChild(battleBtn, PVCSceneZorder.TOP)

		-- 剩余挑战次数
		local leftChallengeBg = display.newButton(0, 0, {
			n = _res('ui/pvc/pvp_main_label_add.png'),
			cb = handler(self, self.BuyChallengeTimeClickHandler)
		})
		display.commonUIParams(leftChallengeBg, {po = cc.p(
			battleBtn:getPositionX(),
			battleBtn:getPositionY() - battleBtn:getContentSize().height * 0.5 - 38
		)})
		self:addChild(leftChallengeBg, PVCSceneZorder.TOP)

		local leftChallengeLabel = display.newLabel(0, 0, fontWithColor('18', {text = ''}))
		display.commonUIParams(leftChallengeLabel, {po = cc.p(
			utils.getLocalCenter(leftChallengeBg).x - 20,
			utils.getLocalCenter(leftChallengeBg).y
		)})
		leftChallengeBg:addChild(leftChallengeLabel)

		-- 刷新时间
		local refreshLabel = display.newLabel(0, 0, fontWithColor('18', {fontSize = 20, text = ''}))
		display.commonUIParams(refreshLabel, {po = cc.p(
			leftChallengeBg:getPositionX(),
			leftChallengeBg:getPositionY() + leftChallengeBg:getContentSize().height * 0.5 + 12
		)})
		self:addChild(refreshLabel, PVCSceneZorder.TOP)

		-------------------------------------------------
		-- 左侧信息板
		local friendInfoBoardBg = display.newImageView(_res('ui/pvc/pvp_board_bg.png'), 0, 0)
		local friendInfoBoardLayer = display.newLayer(0, 0, {ap = cc.p(0.5, 0.5), size = friendInfoBoardBg:getContentSize()})
		display.commonUIParams(friendInfoBoardLayer, {po = cc.p(
			display.SAFE_L + friendInfoBoardLayer:getContentSize().width * 0.5,
			uiLocationInfo.avatarBottomSplitY + friendInfoBoardLayer:getContentSize().height * 0.5
		)})
		self:addChild(friendInfoBoardLayer, PVCSceneZorder.TOP)

		display.commonUIParams(friendInfoBoardBg, {po = utils.getLocalCenter(friendInfoBoardLayer)})
		friendInfoBoardLayer:addChild(friendInfoBoardBg)

		-- 中间头像板
		local friendTeamHeadBg = display.newImageView(_res('ui/pvc/pvp_board_bg_defense.png'), 0, 0)
		display.commonUIParams(friendTeamHeadBg, {po = cc.p(
			friendInfoBoardLayer:getContentSize().width * 0.5 + uiLocationInfo.infoBoardFixedP.x,
			friendInfoBoardLayer:getContentSize().height * 0.5 + uiLocationInfo.infoBoardFixedP.x - 15
		)})
		friendInfoBoardLayer:addChild(friendTeamHeadBg)

		local friendTeamSplitLine = display.newNSprite(_res('ui/pvc/pvp_board_bg_line2.png'), 0, 0)
		display.commonUIParams(friendTeamSplitLine, {po = cc.p(
			utils.getLocalCenter(friendTeamHeadBg).x,
			friendTeamHeadBg:getContentSize().height - 45
		)})
		friendTeamHeadBg:addChild(friendTeamSplitLine)

		local friendTeamChangeLabel = display.newLabel(0, 0, {text = __('编辑防守队伍'), fontSize = 20, color = '#95d4da' , w = 195 , hAlign = display.TAC})
		display.commonUIParams(friendTeamChangeLabel, {po = cc.p(
			friendTeamSplitLine:getPositionX(),
			friendTeamSplitLine:getPositionY() + 20
		)})
		friendTeamHeadBg:addChild(friendTeamChangeLabel)

		-- 战报按钮
		local reportBtnPos = cc.p(
			friendTeamHeadBg:getPositionX(),
			friendTeamHeadBg:getPositionY() - friendTeamHeadBg:getContentSize().height * 0.5 - 40
		)
		local reportBtn = display.newButton(0, 0, {n = _res('ui/pvc/pvp_board_btn_report.png'), cb = handler(self, self.CheckRecordClickHandler), scale9 = true })
		display.commonUIParams(reportBtn, {po = reportBtnPos})
		friendInfoBoardLayer:addChild(reportBtn, 10)

		local reportBtnIcon = display.newNSprite(_res('ui/pvc/pvp_board_ico_report.png'), 0, 0)
		display.commonUIParams(reportBtnIcon, {po = cc.p(
			reportBtnIcon:getContentSize().width * 0.5,
			utils.getLocalCenter(reportBtn).y
		)})
		reportBtn:addChild(reportBtnIcon, 5)

		local reportLabel = display.newLabel(0, 0, fontWithColor('14', {fontSize = 22, text = __('战报')}))

		reportBtn:addChild(reportLabel, 6)
		local reportBtnSize = reportBtn:getContentSize()
		local reportLabelSize =  display.getLabelContentSize(reportLabel)
		if reportLabelSize.width +20 > reportBtnSize.width   then
			reportBtn:setContentSize(cc.size(reportLabelSize.width + 20 , reportBtnSize.height))
		end
		display.commonUIParams(reportLabel, {po = cc.p(
				utils.getLocalCenter(reportBtn).x,
				utils.getLocalCenter(reportBtn).y
		)})
		-- 赛季信息
		local pvcInfoSplitLine = display.newNSprite(_res('ui/pvc/pvp_board_bg_line1.png'), 0, 0)
		display.commonUIParams(pvcInfoSplitLine, {po = cc.p(
			friendTeamHeadBg:getPositionX(),
			friendTeamHeadBg:getPositionY() + friendTeamHeadBg:getContentSize().height * 0.5 + 55
		)})
		friendInfoBoardLayer:addChild(pvcInfoSplitLine)

		local pvcInfoTitleLabel = display.newLabel(0, 0, fontWithColor('18', {text = __('本赛季积分') , reqW = 200 }))
		display.commonUIParams(pvcInfoTitleLabel, {po = cc.p(
			pvcInfoSplitLine:getPositionX(),
			pvcInfoSplitLine:getPositionY() + 20
		)})
		friendInfoBoardLayer:addChild(pvcInfoTitleLabel)

		local pvcPointLabel = display.newLabel(0, 0, fontWithColor('7', {text = '100'}))
		friendInfoBoardLayer:addChild(pvcPointLabel)

		local pvcPointIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(PVC_POINT_ID)), 0, 0)
		friendInfoBoardLayer:addChild(pvcPointIcon)
		pvcPointIcon:setScale(0.2)

		display.setNodesToNodeOnCenter(pvcInfoSplitLine, {pvcPointLabel, pvcPointIcon}, {y = - 20})

		-- 首胜礼包
		local firstWinBg = display.newImageView(_res('ui/pvc/pvp_board_label_firstwin.png'), 0, 0)
		display.commonUIParams(firstWinBg, {po = cc.p(
			friendInfoBoardLayer:getPositionX(),
			friendInfoBoardLayer:getPositionY() + friendInfoBoardLayer:getContentSize().height * 0.5 + 5
		)})
		self:addChild(firstWinBg, PVCSceneZorder.TOP + 1)

		local firstWinTitleLabel = display.newLabel(0, 0, fontWithColor('14', {text =  __('今日首胜礼包') , w= 200 , hAlign= display.TAC }))
		display.commonUIParams(firstWinTitleLabel, {po = cc.p(
			firstWinBg:getPositionX(),
			firstWinBg:getPositionY() + 5
		)})
		self:addChild(firstWinTitleLabel, PVCSceneZorder.TOP + 2)

		local firstWinIcon = display.newButton(0, 0, {
			n = _res(CommonUtils.GetGoodsIconPathById(191005)),
			cb = handler(self, self.FirstWinClickHandler)
		})
		display.commonUIParams(firstWinIcon, {po = cc.p(
			firstWinBg:getPositionX(),
			firstWinBg:getPositionY() + firstWinIcon:getContentSize().height * 0.5 - 20
		)})
		self:addChild(firstWinIcon, PVCSceneZorder.TOP + 1)

		------------ 小红点 ------------
		require('common.RemindIcon').addRemindIcon({
			parent = firstWinIcon,
			tag = 821,
			po = cc.p(firstWinIcon:getContentSize().width * 0.75, firstWinIcon:getContentSize().height * 0.75)
		})
		------------ 小红点 ------------

		-------------------------------------------------
		-- 敌方信息背景
		local rivalInfoBg = display.newImageView(_res('ui/pvc/pvp_main_bg_enemyinfo.png'), 0, 0, {scale9 = true, size = cc.size(330+display.SAFE_L,338)})
		display.commonUIParams(rivalInfoBg, {po = cc.p(
			size.width - rivalInfoBg:getContentSize().width * 0.5,
			selfCenter.y - 35
		)})
		self:addChild(rivalInfoBg, PVCSceneZorder.BASE)

		-- 选择对手按钮
		local chooseRivalBtn = display.newImageView(_res('ui/pvc/pvp_main_bg_noenemy.png'), 0, 0, {scale9 = true, size = cc.size(360+display.SAFE_L,88),
			ap = cc.p(1, 0.5), enable = true, animate = false,
			cb = function (sender)
			end
		})
		display.commonUIParams(chooseRivalBtn, {po = cc.p(
			size.width,
			rivalInfoBg:getPositionY()
		)})
		self:addChild(chooseRivalBtn, PVCSceneZorder.BASE)

		local chooseRivalLabel = display.newLabel(0, 0, fontWithColor('14', {text = __('请选择对手')}))
		display.commonUIParams(chooseRivalLabel, {po = cc.p(
			chooseRivalBtn:getContentSize().width * 0.6,
			chooseRivalBtn:getContentSize().height * 0.5
		)})
		chooseRivalBtn:addChild(chooseRivalLabel)

		-- 对手信息板
		local rivalInfoLayerSize = rivalInfoBg:getContentSize()
		local rivalInfoLayer = display.newLayer(0, 0, {ap = cc.p(0.5, 0.5), size = rivalInfoLayerSize})
		display.commonUIParams(rivalInfoLayer, {po = cc.p(
			rivalInfoBg:getPositionX() - display.SAFE_L,
			rivalInfoBg:getPositionY()
		)})
		rivalInfoBg:getParent():addChild(rivalInfoLayer, rivalInfoBg:getLocalZOrder())

		local rivalInfoSplitLine = display.newNSprite(_res('ui/pvc/pvp_main_bg_line3.png'), 0, 0)
		display.commonUIParams(rivalInfoSplitLine, {po = cc.p(
			rivalInfoLayerSize.width - rivalInfoSplitLine:getContentSize().width * 0.5 - 10,
			rivalInfoLayerSize.height - 65
		)})
		rivalInfoLayer:addChild(rivalInfoSplitLine)

		local rivalNameLabel = display.newLabel(0, 0, fontWithColor('3', {text = '测试玩家名'}))
		display.commonUIParams(rivalNameLabel, {ap = cc.p(1, 0.5), po = cc.p(
			rivalInfoLayerSize.width - 10,
			rivalInfoSplitLine:getPositionY() + 20
		)})
		rivalInfoLayer:addChild(rivalNameLabel)

		-- 对手头像
		local rivalHeadScale = 0.65
		local rivalHeadNode = require('common.PlayerHeadNode').new({avatar = '', avatarFrame = '', showLevel = true, playerLevel = 10})
		rivalHeadNode:setScale(rivalHeadScale)
		display.commonUIParams(rivalHeadNode, {po = cc.p(
			rivalInfoLayerSize.width - rivalHeadNode:getContentSize().width * 0.5 * rivalHeadScale - 10,
			rivalInfoSplitLine:getPositionY() - 10 - rivalHeadNode:getContentSize().height * 0.5 * rivalHeadScale
		)})
		rivalInfoLayer:addChild(rivalHeadNode)

		-- 获胜奖励信息
		local winRewardBg = display.newImageView(_res('ui/pvc/pvp_main_bg_getscore.png'), 0, 0)
		display.commonUIParams(winRewardBg, {po = cc.p(
			rivalInfoLayerSize.width - winRewardBg:getContentSize().width * 0.5,
			100
		)})
		rivalInfoLayer:addChild(winRewardBg)

		local rewardTitle = display.newLabel(0, 0, {text = __('获胜可得'), fontSize = 20, color = '#ffb421' ,reqW  =135 })
		display.commonUIParams(rewardTitle, {ap = cc.p(1, 0.5), po = cc.p(
			winRewardBg:getContentSize().width - 10,
			winRewardBg:getContentSize().height - 20
		)})
		winRewardBg:addChild(rewardTitle)

		return {
			------------ view nodes ------------
			tabNameLabel = tabNameLabel,
			bottomTeamBg = bottomTeamBg,
			avatarBottomLeft = avatarBottomLeft,
			avatarBottomRight = avatarBottomRight,
			pvcPointLabel = pvcPointLabel, -- 赛季积分label
			pvcPointIcon = pvcPointIcon,
			pvcInfoSplitLine = pvcInfoSplitLine,
			friendInfoBoardLayer = friendInfoBoardLayer,
			friendTeamHeadBg = friendTeamHeadBg,
			rivalNameLabel = rivalNameLabel,
			rivalHeadNode = rivalHeadNode,
			friendDefenseTeamHeadNode = nil, -- 防御队伍一号位头像
			friendMajorAvatarNode = nil, -- 友方进攻队伍一号位spine
			rivalMajorAvatarNode = nil, -- 敌方进攻队伍一号位spine
			friendFightTeamNodes = {}, -- 友方进攻队伍底部头像
			--[[
			{
				{cardHeadNode = cardHeadNode, captainMark = captainMark},
				{cardHeadNode = cardHeadNode, captainMark = captainMark},
				{cardHeadNode = cardHeadNode, captainMark = captainMark},
				...
			}
			--]]
			rivalRivalTeamNodes = {}, -- 敌方防守队伍底部头像
			winRewardBg = winRewardBg,
			winRewardsNodes = {}, -- 战斗胜利后的奖励node
			friendTeamBattlePointLabel = friendTeamBattlePointLabel,
			rivalTeamBattlePointLabel = rivalTeamBattlePointLabel,
			activePointLabel = activePointLabel,
			activePointRewardsLayer = nil,
			activeBtnBg = activeBtnBg,
			activePointRewardsNodes = {},
			leftChallengeLabel = leftChallengeLabel,
			refreshLabel = refreshLabel,
			firstWinIcon = firstWinIcon,
			avatarLightLeft = avatarLightLeft,
			avatarLightRight = avatarLightRight,
			------------ view data ------------
			uiLocationInfo = uiLocationInfo,
			------------ layer handler ------------
			ShowNoRival = function (show)
				chooseRivalBtn:setVisible(show)
				changeRivalTeamBtn:setVisible(show)
				rivalInfoLayer:setVisible(not show)

				rivalTeamBattlePointBg:setVisible(not show)
				rivalTeamBattlePointLabel:setVisible(not show)

				avatarLightRight:setVisible(show)

				if show then
					-- 移除中间小人
					if nil ~= self.viewData.rivalMajorAvatarNode then
						self.viewData.rivalMajorAvatarNode:removeFromParent()
						self.viewData.rivalMajorAvatarNode = nil
					end
				end

				-- 隐藏头像
				for i,v in ipairs(self.viewData.rivalRivalTeamNodes) do
					v.cardHeadNode:setVisible(false)
					v.captainMark:setVisible(false)
				end

				for i,v in ipairs(rivalFightTeamEmptyNodes) do
					for i,v in ipairs(rivalFightTeamEmptyNodes) do
						-- v:setVisible(show)
					end
				end
			end,
			ShowNoFriendFightTeam = function (show)
				changeFriendFightTeamBtn:setVisible(show)
				friendTeamBattlePointBg:setVisible(not show)
				friendTeamBattlePointLabel:setVisible(not show)

				avatarLightLeft:setVisible(show)

				if show then
					-- 移除中间小人
					if nil ~= self.viewData.friendMajorAvatarNode then
						self.viewData.friendMajorAvatarNode:removeFromParent()
						self.viewData.friendMajorAvatarNode = nil
					end

					-- 隐藏头像
					for i,v in ipairs(self.viewData.friendFightTeamNodes) do
						v.cardHeadNode:setVisible(false)
						v.captainMark:setVisible(false)
					end
				end

				for i,v in ipairs(friendFightTeamEmptyNodes) do
					-- v:setVisible(show)
				end
			end,
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
				uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.PVC)]})
			end})
		end)
	)
	self.viewData.tabNameLabel:runAction(action)

	self:InitActivePointRewardsLayer()
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
刷新界面
@params data table 竞技场主信息
@params curRivalPlayerId int 当前对手id
--]]
function PVCHomeScene:RefreshUI(data, curRivalPlayerId)
	------------ 己方 ------------
	self:RefreshPVCPoint(checkint(data.integral))
	self:RefreshActivePoint(checkint(data.activityPoint))
	self:RefreshActivePointRewardsLayer(checkint(data.activityPoint))
	-- 刷新己方攻防阵容
	self:RefreshFriendDefenseTeam(data.defenseTeam)
	self:RefreshFriendFightTeam(data.fightTeam)
	self:RefreshFirstWinReward(checkint(data.firstWinStatus))
	------------ 己方 ------------

	------------ 敌方 ------------
	-- 刷新敌方信息
	local rivalInfo = nil
	for i,v in ipairs(data.matchOpponent) do
		if nil ~= v.opponentId and 0 ~= checkint(v.opponentId) then
			if curRivalPlayerId == checkint(v.opponentId) then
				rivalInfo = v
			end
		end
	end
	self:RefreshRivalInfo(rivalInfo)
	------------ 敌方 ------------

	------------ 刷新公有信息 ------------
	self:RefreshPVCLeftFightTimes(checkint(data.remainTimes))
	self:RefreshPVCLeftRefreshTime(checkint(data.refreshTime))
	------------ 刷新公有信息 ------------

end
--[[
刷新活跃度
@params activePoint int 活跃度
--]]
function PVCHomeScene:RefreshActivePoint(activePoint)
	self.viewData.activePointLabel:setString(tostring(activePoint))

	-- local labelInfo = {
	-- 	{text = tostring(activePoint), fontSize = 22, color = '#ffc266', ttf = true, font = TTF_GAME_FONT, outline = '#412225'},
	-- 	{text = '/' .. tostring(PVC_ACTIVE_POINT_MAX), fontSize = 22, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#412225'}
	-- }
	-- display.reloadRichLabel(self.viewData.activePointLabel, {c = labelInfo})
end
--[[
刷新赛季积分
@params point 赛季积分
--]]
function PVCHomeScene:RefreshPVCPoint(point)
	self.viewData.pvcPointLabel:setString(checkint(point))
	display.setNodesToNodeOnCenter(self.viewData.pvcInfoSplitLine, {self.viewData.pvcPointLabel, self.viewData.pvcPointIcon}, {y = - 20})
end
--[[
刷新pvc挑战次数
@params leftTimes int 剩余次数
--]]
function PVCHomeScene:RefreshPVCLeftFightTimes(leftTimes)
	self.viewData.leftChallengeLabel:setString(string.format(__('当前剩余次数: %d/%d'), leftTimes, MAX_PVC_FIGHT_TIMES))
end
--[[
刷新刷新时间
@params leftTime int 剩余刷新秒数
--]]
function PVCHomeScene:RefreshPVCLeftRefreshTime(leftTime)
	local h = math.floor(leftTime / 3600)
	local m = math.floor((leftTime - 3600 * h) / 60)
	local s = leftTime - h * 3600 - m * 60
	self.viewData.refreshLabel:setString(string.format(__('下次刷新还有 %02d:%02d:%02d'), h, m, s))
end
--[[
刷新防守队伍
@params friendTeamData table 友方队伍信息
--]]
function PVCHomeScene:RefreshFriendDefenseTeam(friendTeamData)
	-- 刷新防御队伍
	-- 查找一号位选手
	local cid = nil
	local cardData = nil

	for i,v in ipairs(friendTeamData) do
		cid = self:GetIdByCardDataString(v)
		if nil ~= cid then
			cardData = gameMgr:GetCardDataById(cid)
			if nil ~= cardData then
				-- 第一个找到的成员 刷新防守队伍头像
				if nil == self.viewData.friendDefenseTeamHeadNode then
					local friendDefenseTeamHeadNode = require('common.CardHeadNode').new({
						id = cid,
						showBaseState = true, showActionState = false, showVigourState = false
					})
					friendDefenseTeamHeadNode:setScale(0.6)
					display.commonUIParams(friendDefenseTeamHeadNode, {
						po = cc.p(
							self.viewData.friendTeamHeadBg:getPositionX(),
							self.viewData.friendTeamHeadBg:getPositionY() - 20
						),
						cb = handler(self, self.ChangeDefenseTeamClickHandler),
						animate = false
					})
					self.viewData.friendInfoBoardLayer:addChild(friendDefenseTeamHeadNode, 5)
					self.viewData.friendDefenseTeamHeadNode = friendDefenseTeamHeadNode
				else
					-- 刷新头像
					self.viewData.friendDefenseTeamHeadNode:RefreshUI({id = cid})
				end
				break
			end
		end
	end
end
--[[
刷新友方进攻队伍
@params friendTeamData table 友方队伍信息
--]]
function PVCHomeScene:RefreshFriendFightTeam(friendTeamData)
	-- 刷新友方进攻队伍
	local cid = nil
	local cardData = nil
	local itor = 0
	local cardHeadScale = 0.45
	local battlePoint = 0

	for i,v in ipairs(friendTeamData) do
		local cardHeadNodes = self.viewData.friendFightTeamNodes[i]
		cid = self:GetIdByCardDataString(v)

		if nil ~= cid then
			cardData = gameMgr:GetCardDataById(cid)
			if nil ~= cardData then

				itor = itor + 1
				-- 刷新底部头像
				if nil ~= cardHeadNodes then
					cardHeadNodes.cardHeadNode:setVisible(true)
					cardHeadNodes.cardHeadNode:RefreshUI({id = cid})
				else
					-- 为空 创建一次
					local cardHeadNode = require('common.CardHeadNode').new({
						id = cid,
						showBaseState = true, showActionState = false, showVigourState = false
					})
					cardHeadNode:setScale(cardHeadScale)
					self:addChild(cardHeadNode, PVCSceneZorder.BASE + 1)

					-- 队长mark
					local captainMark = display.newNSprite(_res('ui/home/teamformation/team_ico_captain.png'), 0, 0)
					self:addChild(captainMark, PVCSceneZorder.BASE + 2)

					cardHeadNodes = {cardHeadNode = cardHeadNode, captainMark = captainMark}
					self.viewData.friendFightTeamNodes[i] = cardHeadNodes
				end

				display.commonUIParams(cardHeadNodes.cardHeadNode, {po = cc.p(
					self.viewData.bottomTeamBg:getPositionX() - 215 - (i - 1) * (95),
					self.viewData.bottomTeamBg:getPositionY() + self.viewData.uiLocationInfo.bottomTeamBgCenterFixedY
				)})

				display.commonUIParams(cardHeadNodes.captainMark, {po = cc.p(
					cardHeadNodes.cardHeadNode:getPositionX(),
					cardHeadNodes.cardHeadNode:getPositionY() + cardHeadNodes.cardHeadNode:getContentSize().height * 0.5 * cardHeadScale
				)})
				cardHeadNodes.captainMark:setVisible(1 == i)

				if 1 == itor then
					-- 刷新友方一号位小人
					self:RefreshFriendMajorAvatar(cardData)
				end

				-- 累加战斗力
				battlePoint = battlePoint + cardMgr.GetCardStaticBattlePointById(cid)

			else
				if nil ~= cardHeadNodes then
					cardHeadNodes.cardHeadNode:setVisible(false)
					cardHeadNodes.captainMark:setVisible(false)
				end
			end
		else
			if nil ~= cardHeadNodes then
				cardHeadNodes.cardHeadNode:setVisible(false)
				cardHeadNodes.captainMark:setVisible(false)
			end
		end
	end

	-- 刷新战斗力
	self.viewData.friendTeamBattlePointLabel:setString(tostring(battlePoint))
	-- 显示空状态
	self.viewData.ShowNoFriendFightTeam(0 >= itor)
end
--[[
刷新一号位avatar
@params cardData table 卡牌信息
--]]
function PVCHomeScene:RefreshFriendMajorAvatar(cardData)
	if nil ~= self.viewData.friendMajorAvatarNode then
		self.viewData.friendMajorAvatarNode:removeFromParent()
		self.viewData.friendMajorAvatarNode = nil
	end

	local skinId = checkint(cardData.defaultSkinId)
	local avatar = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 0.5})
	avatar:setPosition(cc.p(
		self.viewData.avatarBottomLeft:getPositionX() + self.viewData.uiLocationInfo.avatarFixedPL.x,
		self.viewData.avatarBottomLeft:getPositionY() + self.viewData.uiLocationInfo.avatarFixedPL.y
	))
	avatar:update(0)
	avatar:setAnimation(0, 'idle', true)
	self:addChild(avatar, PVCSceneZorder.BASE + 2)
	self.viewData.friendMajorAvatarNode = avatar
end
--[[
敌方信息
@params data table
--]]
function PVCHomeScene:RefreshRivalInfo(data)
	if nil == data or nil == data.opponentId or 0 == checkint(data.opponentId) then
		self.viewData.ShowNoRival(true)
	else
		self.viewData.ShowNoRival(false)

		-- 刷新敌方玩家基础信息
		self:RefreshRivalPlayerInfo(data.name, data.level, data.avatar, data.avatarFrame)
		-- 获胜后奖励
		self:RefreshWinRewards(data.winIntegral, data.winMedal)
		-- 刷新敌方防守阵容
		self:RefreshRivalDefenseTeam(data.defenseTeam)
	end
end
--[[
刷新敌方玩家基础信息
@params playerName string 玩家名
@params playerLevel int 玩家等级
@params playerAvatar string 玩家头像url
@params playerAvatarFrame string 玩家头像框
--]]
function PVCHomeScene:RefreshRivalPlayerInfo(playerName, playerLevel, playerAvatar, playerAvatarFrame)
	-- 玩家名
	self.viewData.rivalNameLabel:setString(playerName)
	-- 玩家头像 玩家等级
	self.viewData.rivalHeadNode:RefreshUI({
		avatar = playerAvatar, playerLevel = playerLevel, avatarFrame = playerAvatarFrame
	})
end
--[[
刷新获胜奖励
@params integral int 获胜后的积分
@params medal int 获胜后的勋章
--]]
function PVCHomeScene:RefreshWinRewards(integral, medal)
	local rewardsInfo = {
		{goodsId = PVC_POINT_ID, amount = checkint(integral)},
		{goodsId = PVC_MEDAL_ID, amount = checkint(medal)}
	}

	local goodsIconScale = 0.25
	local nodes = nil

	for i,v in ipairs(rewardsInfo) do
		nodes = self.viewData.winRewardsNodes[i]
		if nil == nodes then
			local goodsIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(v.goodsId)), 0, 0)
			goodsIcon:setScale(0.25)

			local iconPos = cc.p(
				self.viewData.winRewardBg:getContentSize().width - goodsIcon:getContentSize().width * 0.5 * goodsIconScale - 10,
				self.viewData.winRewardBg:getContentSize().height - 55 - (i - 1) * 35
			)

			display.commonUIParams(goodsIcon, {po = iconPos})
			self.viewData.winRewardBg:addChild(goodsIcon)

			local goodsAmountLabel = display.newLabel(0, 0, {text = tostring(v.amount), fontSize = 28, color = '#ffe64a', font = TTF_GAME_FONT, ttf = true})
			display.commonUIParams(goodsAmountLabel, {ap = cc.p(1, 0.5), po = cc.p(
				iconPos.x - goodsIcon:getContentSize().width * 0.5 * goodsIconScale - 5,
				iconPos.y
			)})
			self.viewData.winRewardBg:addChild(goodsAmountLabel)

			self.viewData.winRewardsNodes[i] = {goodsIcon = goodsIcon, goodsAmountLabel = goodsAmountLabel}
		else
			nodes.goodsIcon:setTexture(_res(CommonUtils.GetGoodsIconPathById(v.goodsId)))
			nodes.goodsAmountLabel:setString(tostring(v.amount))
		end
	end
end
--[[
刷新敌方防守队伍
@params rivalTeamData table 敌方队伍信息
--]]
function PVCHomeScene:RefreshRivalDefenseTeam(rivalTeamData)
	local cardHeadScale = 0.45
	local itor = 0
	local battlePoint = 0

	-- 隐藏头像
	for i, cardData in ipairs(self.viewData.rivalRivalTeamNodes) do
		if nil ~= cardData then
			cardData.cardHeadNode:setVisible(false)
			cardData.captainMark:setVisible(false)
		end
	end
	for i, cardData in ipairs(rivalTeamData) do
		local cardHeadNodes = self.viewData.rivalRivalTeamNodes[i]
		local cardId = checkint(cardData.cardId)
		if 0 ~= cardId then
			itor = itor + 1

			if nil ~= cardHeadNodes then
				cardHeadNodes.cardHeadNode:setVisible(true)
				cardHeadNodes.cardHeadNode:RefreshUI({
					cardData = {cardId = checkint(cardData.cardId), favorabilityLevel = checkint(cardData.favorabilityLevel), level = checkint(cardData.level), breakLevel = checkint(cardData.breakLevel), skinId = checkint(cardData.defaultSkinId)}
				})
			else
				-- 为空 创建一次
				local cardHeadNode = require('common.CardHeadNode').new({
					cardData = {cardId = checkint(cardData.cardId), favorabilityLevel = checkint(cardData.favorabilityLevel), level = checkint(cardData.level), breakLevel = checkint(cardData.breakLevel), skinId = checkint(cardData.defaultSkinId)},
					showBaseState = true, showActionState = false, showVigourState = false
				})
				cardHeadNode:setScale(cardHeadScale)
				self:addChild(cardHeadNode, PVCSceneZorder.BASE + 1)

				-- 队长mark
				local captainMark = display.newNSprite(_res('ui/home/teamformation/team_ico_captain.png'), 0, 0)
				self:addChild(captainMark, PVCSceneZorder.BASE + 2)

				cardHeadNodes = {cardHeadNode = cardHeadNode, captainMark = captainMark}
				self.viewData.rivalRivalTeamNodes[i] = cardHeadNodes
			end

			display.commonUIParams(cardHeadNodes.cardHeadNode, {po = cc.p(
				self.viewData.bottomTeamBg:getPositionX() + 215 + (i - 1) * (95),
				self.viewData.bottomTeamBg:getPositionY() + self.viewData.uiLocationInfo.bottomTeamBgCenterFixedY
			)})

			display.commonUIParams(cardHeadNodes.captainMark, {po = cc.p(
				cardHeadNodes.cardHeadNode:getPositionX(),
				cardHeadNodes.cardHeadNode:getPositionY() + cardHeadNodes.cardHeadNode:getContentSize().height * 0.5 * cardHeadScale
			)})
			cardHeadNodes.captainMark:setVisible(1 == i)

			if 1 == itor then
				-- 刷新敌方一号位小人
				self:RefreshRivalMajorAvatar(cardData)
			end

			-- 累加战斗力
			battlePoint = battlePoint + cardMgr.GetCardStaticBattlePointByCardData(cardData)

		else
			if nil ~= cardHeadNodes then
				cardHeadNodes.cardHeadNode:setVisible(false)
				cardHeadNodes.captainMark:setVisible(false)
			end
		end
	end

	-- 刷新战斗力
	self.viewData.rivalTeamBattlePointLabel:setString(tostring(battlePoint))

end
--[[
刷新敌方一号位avatar
@params cardData table 卡牌信息
--]]
function PVCHomeScene:RefreshRivalMajorAvatar(cardData)
	if nil ~= self.viewData.rivalMajorAvatarNode then
		self.viewData.rivalMajorAvatarNode:removeFromParent()
		self.viewData.rivalMajorAvatarNode = nil
	end

	local skinId = checkint(cardData.defaultSkinId)
	local avatar = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 0.5})
	avatar:setPosition(cc.p(
		self.viewData.avatarBottomRight:getPositionX() + self.viewData.uiLocationInfo.avatarFixedPR.x,
		self.viewData.avatarBottomRight:getPositionY() + self.viewData.uiLocationInfo.avatarFixedPR.y
	))
	avatar:setScaleX(-1)
	avatar:update(0)
	avatar:setAnimation(0, 'idle', true)
	self:addChild(avatar, PVCSceneZorder.BASE + 2)
	self.viewData.rivalMajorAvatarNode = avatar
end
--[[
初始化活跃度进度条
--]]
function PVCHomeScene:InitActivePointRewardsLayer()
	-- 背景
	local bg = display.newImageView(_res('ui/pvc/pvp_board_bg_scorereward.png'), 0, 0, {scale9 = true })
	local size = bg:getContentSize()
	bg:setContentSize(cc.size(size.width +10  , size.height + 5 ))
	local layer = display.newLayer(0, 0, {size = size})
	display.commonUIParams(layer, {ap = cc.p(1, 0.5), po = cc.p(
		self.viewData.activeBtnBg:getPositionX() + self.viewData.activeBtnBg:getContentSize().width * 0.5,
		self.viewData.activeBtnBg:getPositionY() - 2
	)})
	self.viewData.activeBtnBg:getParent():addChild(layer, self.viewData.activeBtnBg:getLocalZOrder() - 1)

	self.viewData.activePointRewardsLayer = layer

	display.commonUIParams(bg, {po = utils.getLocalCenter(layer)})
	layer:addChild(bg, 1)

	-- 进度条
	local activePointBar = CProgressBar:create(_res('ui/pvc/pvp_reward_bar_active.png'))
	activePointBar:setBackgroundImage(_res('ui/pvc/pvp_reward_bar_grey.png'))
	activePointBar:setDirection(eProgressBarDirectionLeftToRight)
	activePointBar:setPosition(cc.p(
		size.width - self.viewData.activeBtnBg:getContentSize().width * 0.5 - activePointBar:getContentSize().width * 0.5 + 5,
		size.height * 0.5 + 2
	))
	layer:addChild(activePointBar, 5)
	activePointBar:setTag(3)

	activePointBar:setMaxValue(PVC_ACTIVE_POINT_MAX)
	activePointBar:setValue(0)

	-- 活跃度图标
	local activeIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(PVC_ACTIVE_POINT_ID)), 0, 0)
	display.commonUIParams(activeIcon, {po = cc.p(
		activePointBar:getPositionX() - activePointBar:getContentSize().width * 0.5,
		activePointBar:getPositionY() + 5
	)})
	activeIcon:setScale(0.3)
	layer:addChild(activeIcon, 20)

	-- 点数变化
	local splitLine = display.newNSprite(_res('ui/pvc/pvp_main_bg_line3.png'), 0, 0)
	display.commonUIParams(splitLine, {po = cc.p(
		75,
		activePointBar:getPositionY()
	)})
	splitLine:setScaleX(0.5)
	layer:addChild(splitLine, 5)

	local winPointLabel = display.newLabel(0, 0, {text = __('胜利+20'), fontSize = 20, color = '#faeac9'  , ap = display.LEFT_CENTER})
	display.commonUIParams(winPointLabel, { po = cc.p(
		splitLine:getPositionX()-50 ,
		splitLine:getPositionY() + 30
	)})
	layer:addChild(winPointLabel, 5)

	local losePointLabel = display.newLabel(0, 0, {text = __('失败+8'), fontSize = 20, color = '#c0c0c0',ap = display.LEFT_CENTER})
	display.commonUIParams(losePointLabel, { po = cc.p(
		splitLine:getPositionX()-50,
		splitLine:getPositionY() -25
	)})
	layer:addChild(losePointLabel, 5)

	-- 创建奖励预览
	local activePointBarSize = activePointBar:getContentSize()
	local rewardsConfig = CommonUtils.GetConfigAllMess('activityPointReward', 'arena')
	local amount = table.nums(rewardsConfig)
	local rewardId = nil
	local rewardConfig = nil
	local activeRewardBtns = {}
	for i = 1, amount do

		rewardId = i
		rewardConfig = rewardsConfig[tostring(rewardId)]

		if i ~= amount then
			local rewardBg = display.newImageView(_res('ui/pvc/pvp_reward_ico_default.png'), 0, 0,
				{enable = true, cb = handler(self, self.ActivePointRewardPreviewClickHandler)})
			display.commonUIParams(rewardBg, {po = layer:convertToNodeSpace(activePointBar:convertToWorldSpace(cc.p(
				activePointBarSize.width * (checkint(rewardConfig.activePoint) / PVC_ACTIVE_POINT_MAX),
				activePointBarSize.height * 0.5
			)))})
			layer:addChild(rewardBg, 21)

			rewardBg:setTag(checkint(rewardConfig.id))

			local rewardIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(191004)), 0, 0)
			display.commonUIParams(rewardIcon, {po = cc.p(
				utils.getLocalCenter(rewardBg).x,
				utils.getLocalCenter(rewardBg).y + 3
			)})
			rewardIcon:setScale(rewardBg:getContentSize().width / rewardIcon:getContentSize().width)
			rewardBg:addChild(rewardIcon, 5)

			local arrow = display.newNSprite(_res('ui/pvc/pvp_reward_ico_right.png'), 0, 0)
			display.commonUIParams(arrow, {po = cc.p(
				utils.getLocalCenter(rewardBg).x,
				utils.getLocalCenter(rewardBg).y
			)})
			rewardBg:addChild(arrow, 10)

			local activePointLabelBg = display.newImageView(_res('ui/pvc/pvp_reward_laber_num.png'), 0, 0)
			display.commonUIParams(activePointLabelBg, {po = cc.p(
				rewardBg:getPositionX(),
				rewardBg:getPositionY() - rewardBg:getContentSize().height * 0.5 + 7
			)})
			layer:addChild(activePointLabelBg, 21)

			local activePointLabel = display.newLabel(0, 0,
				{text = tostring(rewardConfig.activePoint), fontSize = 22, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#412225'})
			display.commonUIParams(activePointLabel, {po = cc.p(
				utils.getLocalCenter(activePointLabelBg).x,
				utils.getLocalCenter(activePointLabelBg).y
			)})
			activePointLabelBg:addChild(activePointLabel, 21)

			self.viewData.activePointRewardsNodes[i] = {bgNode = rewardBg, arrowNode = arrow}

			activeRewardBtns[tostring(rewardId)] = rewardBg
		else
			self.viewData.activeBtnBg:setTag(checkint(rewardConfig.id))
			activeRewardBtns[tostring(rewardId)] = self.viewData.activeBtnBg
		end
	end

	self.viewData.activeRewardBtns = activeRewardBtns

	-- 初始化状态
	layer:setVisible(false)

	-- 创建一个吃触摸的层
	local touchLayer = display.newLayer(0, 0, {size = self:getContentSize()})
	display.commonUIParams(touchLayer, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(self)})
	self:addChild(touchLayer, 999)

	-- touchLayer:setBackgroundColor(cc.c4b(255, 0, 180, 100))

	self.viewData.activePointTouchLayer = touchLayer

	touchLayer:setVisible(layer:isVisible())

	touchLayer:setOnTouchBeganScriptHandler(function (sender, touch)
		if not self.viewData.activePointRewardsLayer then
			-- 不做处理
		else
			local touchPos = touch:getLocation()
			local touchedRewardsLayer = cc.rectContainsPoint(
				self.viewData.activePointRewardsLayer:getBoundingBox(),
				self.viewData.activePointRewardsLayer:getParent():convertToNodeSpace(touchPos)
			)
			if not touchedRewardsLayer then
				self:ShowActivePointRewardsLayer(false)
			end
		end

		return true
	end)
end
--[[
显示活跃度奖励预览层
@params show bool 是否显示
--]]
function PVCHomeScene:ShowActivePointRewardsLayer(show)
	PlayAudioClip(AUDIOS.UI.ui_window_open.id)
	self.viewData.activePointRewardsLayer:setVisible(show)
	self.viewData.activePointTouchLayer:setVisible(show)
end
--[[
刷新活跃度预览
@params activePoint int 活跃度点数
--]]
function PVCHomeScene:RefreshActivePointRewardsLayer(activePoint)
	local rewardsId = nil
	local rewardsConfig = nil
	-- 刷新奖励预览
	for i,v in ipairs(self.viewData.activePointRewardsNodes) do
		rewardsId = i
		rewardsConfig = CommonUtils.GetConfig('arena', 'activityPointReward', rewardsId)
		if activePoint >= checkint(rewardsConfig.activePoint) then
			v.bgNode:setTexture(_res('ui/pvc/pvp_reward_ico_got.png'))
			v.arrowNode:setVisible(true)
		else
			v.bgNode:setTexture(_res('ui/pvc/pvp_reward_ico_default.png'))
			v.arrowNode:setVisible(false)
		end
	end
	-- 刷新进度条
	self.viewData.activePointRewardsLayer:getChildByTag(3):setValue(activePoint)
end
--[[
根据id显示活跃度奖励预览
@params id int 奖励id
--]]
function PVCHomeScene:ShowActivePointRewardDetail(id)
	local rewards = CommonUtils.GetConfig('arena', 'activityPointReward', id).rewards
	uiMgr:ShowInformationTipsBoard({
		targetNode = self.viewData.activeRewardBtns[tostring(id)],
		iconIds = rewards,
		type = 4
	})
end
--[[
刷新首胜奖励状态
@params state int 0 未达成 1 未领取 2 已领取
--]]
function PVCHomeScene:RefreshFirstWinReward(state)
	self.viewData.firstWinIcon:getChildByTag(821):setVisible(1 == checkint(state))
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- click callback begin --
---------------------------------------------------
--[[
更换防守队伍点击回调
--]]
function PVCHomeScene:ChangeDefenseTeamClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('SHOW_CHANGE_FRIEND_DEFENSE_TEAM')
end
--[[
点击更换进攻队伍回调
--]]
function PVCHomeScene:ChangeFightTeamClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('SHOW_CHANGE_FRIEND_FIGHT_TEAM')
end
--[[
点击更换对手回调
--]]
function PVCHomeScene:ChangeRivalTeamClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('SHOW_SELECT_RIVAL')
end
--[[
点击活跃度大按钮回调
--]]
function PVCHomeScene:ActivePointClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('SHOW_ACTIVE_POINT_DETAIL', {show = not self.viewData.activePointRewardsLayer:isVisible()})
end
--[[
点击活跃度奖励按钮回调
--]]
function PVCHomeScene:ActivePointRewardPreviewClickHandler(sender)
	PlayAudioByClickNormal()
	local id = sender:getTag()
	self:ShowActivePointRewardDetail(id, sender)
end
--[[
点击战斗按钮回调
--]]
function PVCHomeScene:DuelClickHandler(sender)
	AppFacade.GetInstance():DispatchObservers('READY_TO_DUEL')
end
--[[
首胜按钮回调
--]]
function PVCHomeScene:FirstWinClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('DRAW_FIRST_WIN_REWARD')
end
--[[
购买进攻次数按钮回调
--]]
function PVCHomeScene:BuyChallengeTimeClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('BUY_CHALLENGE_TIME')
end
--[[
查看竞技场战报按钮回调
--]]
function PVCHomeScene:CheckRecordClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('SHOW_CHECK_RECORD')
end
--[[
查看竞技场商城
--]]
function PVCHomeScene:PVCShopClickHandler(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('SHOW_PVC_SHOP')
end
--[[
返回键回调
--]]
function PVCHomeScene:BackClickHandler(sender)
	PlayAudioByClickClose()
	AppFacade.GetInstance():DispatchObservers('EXIT_PVC_HOME')
end
---------------------------------------------------
-- click callback end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据字符串获取卡牌的数据库id
@params s string 字符串
@return _ int 卡牌数据库id
--]]
function PVCHomeScene:GetIdByCardDataString(s)
	if 0 >= string.len(string.gsub(s, ' ', '')) then
		return nil
	else
		return checkint(s)
	end
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return PVCHomeScene
