--[[
通用战斗准备界面
@params BattleReadyConstructorStruct 创建战斗选择界面的数据结构
--]]

local SummerActivityReadyView = class('SummerActivityReadyView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.SummerActivityReadyView'
    node:setName('SummerActivityReadyView')
	node:enableNodeEvents()
	return node
end)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local httpMgr = AppFacade.GetInstance():GetManager("HttpManager")

local changeTeamMemberViewTag = 888

local summerActMgr = app.summerActMgr

local RES_DIR = {
	BACK = _res("ui/common/common_btn_back.png"),
	BG_INFORMATION =  _res('ui/common/maps_fight_bg_information.png'),
	TABL_BTN =  _res('ui/common/maps_fight_btn_tab_default.png'),
	SKILL_BG1 = _res('ui/map/team_lead_skill_bg_1.png'),
	SKILL_BG2 = _res('ui/map/team_lead_skill_bg_2.png'),
	SKILL_WORD_BG =  _res('ui/common/team_lead_skill_word_bg.png'),
	FRAME_GOODS =  _res('ui/common/common_frame_goods_1.png'),
	ADD         = _res('ui/common/maps_fight_btn_pet_add.png'),
	BG_TITLE_S =  _res('ui/common/maps_fight_bg_title_s.png'),
 	BG_SWORD1 = _res('ui/common/maps_fight_bg_sword1.png'),
 	BTN_ORANGE = _res('ui/common/common_btn_orange.png'),
}

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
constructor
--]]
function SummerActivityReadyView:ctor( ... )
	local args = unpack({...}) or {}

	self.selectedCenterIdx = nil

	self.stageId = checkint(args.stageId)
	self.star = checkint(args.star)
	self.questBattleType = args.questBattleType

	self.additions = args.additions
	self.teamMembers = args.teamMembers
	self.disableUpdateBackButton = args.disableUpdateBackButton

	self.selectedTeamIdx = nil
	if nil ~= args.teamIdx and 0 ~= args.teamIdx then
		self.selectedTeamIdx = args.teamIdx
	end

	self.recommendCards = args.recommendCards

	self.equipedMagicFoodId = nil
	if nil ~= args.equipedMagicFoodId and 0 ~= args.equipedMagicFoodId then
		self.equipedMagicFoodId = args.equipedMagicFoodId
	end
	
	self.enterBattleRequestCommand = args.enterBattleRequestCommand
	self.enterBattleRequestData = args.enterBattleRequestData
	self.exitBattleRequestCommand = args.exitBattleRequestCommand
	self.exitBattleRequestData = args.exitBattleRequestData
	self.enterBattleResponseSignal = args.enterBattleResponseSignal
	self.exitBattleResponseSignal = args.exitBattleResponseSignal

	self.fromMediatorName = args.fromMediatorName
	self.toMediatorName = args.toMediatorName

	-- 初始化管理器
	self.enterBattleMediator = AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator')
	if not self.enterBattleMediator then
		self.enterBattleMediator = require('Game.mediator.EnterBattleMediator').new({battleReadyView = self, disableUpdateBackButton = self.disableUpdateBackButton})
		AppFacade.GetInstance():RegistMediator(self.enterBattleMediator)
	end
	self.recommendCardNodes = {}
	self.teamCardIds = {}
	self:InitUI()

	-- AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
	-- debug --
	-- self:InitRaidDebug()
	-- debug --
end
function SummerActivityReadyView:destory()
	AppFacade.GetInstance():UnRegsitMediator('EnterBattleMediator')
end
--[[
init ui
--]]
function SummerActivityReadyView:InitUI()

	-- bg mask
	-- local eaterLayer = display.newImageView(_res('ui/common/common_bg_mask.png'), display.cx, display.cy, {enable = true, animate = false})
	local eaterLayer = display.newLayer(display.cx, display.cy, {enable = true, size = display.size, color = '#000000', ap = cc.p(0.5, 0.5)})
	eaterLayer:setOpacity(0.7 * 255)
	self:addChild(eaterLayer, 1)

	-- 返回按钮
	local closeBtn = display.newButton(0, 0, {n = RES_DIR.BACK,
		cb = function (sender)
			-- 发信号 关闭
            sender:setEnabled(false)
            PlayAudioByClickClose()
            self:destory()
		end})
	display.commonUIParams(closeBtn, {po = cc.p(
		display.SAFE_L + closeBtn:getContentSize().width * 0.5 + 30,
		display.height - 18 - closeBtn:getContentSize().height * 0.5
	)})
    closeBtn:setName('BTN_CLOSE')
	self:addChild(closeBtn, 20)
	self.closeBtn = closeBtn

	local centerBgSize = cc.size(630, 185)
	local belongsBgFrameSize = cc.size(375, 215)
	local cardHeadScale = 0.625


	-- center bg
	local centerBg = display.newImageView(RES_DIR.BG_INFORMATION, display.cx, display.height * 0.7,
			{scale9 = true, size = centerBgSize, enable = true, animate = false})
	self:addChild(centerBg, 5)

	-- player skill info
	local belongsBgFrame = display.newImageView(RES_DIR.BG_INFORMATION,
		centerBg:getPositionX() - centerBgSize.width * 0.5 + belongsBgFrameSize.width * 0.5,
		centerBg:getPositionY() - centerBgSize.height * 0.5 - 80 - belongsBgFrameSize.height * 0.5,
		{scale9 = true, size = belongsBgFrameSize})
	belongsBgFrame:setName('belongsBgFrame')
	self:addChild(belongsBgFrame, 5)

	-- hint label
	local hintLabel = display.newLabel(0, 0,
		{text = summerActMgr:getThemeTextByText(__('点击技能图标更改主角技')), fontSize = 20, color = '#c8b3af'})
	display.commonUIParams(hintLabel, {po = cc.p(belongsBgFrameSize.width * 0.5, display.getLabelContentSize(hintLabel).height * 0.5 + 2)})
	belongsBgFrame:addChild(hintLabel)

	-- battle btn
	local battleBtn = require('common.CommonBattleButton').new({
		pattern = 1,
		clickCallback = handler(self, self.EnterBattle)
	})
    battleBtn:setName('BattleBTN')
	display.commonUIParams(battleBtn, {po = cc.p(
		centerBg:getPositionX() + centerBgSize.width * 0.5 - battleBtn:getContentSize().width * 0.5,
		belongsBgFrame:getPositionY()
	)})
	self:addChild(battleBtn, 5)

	-- 消耗体力
	local costHpLabel, costHpIcon, costHpTime = nil, nil, nil
	local stageConf = CommonUtils.GetQuestConf(checkint(self.stageId))
	if self.stageId and stageConf then
		costHpLabel = display.newLabel(0, 0,
			fontWithColor(9, {text = string.format(summerActMgr:getThemeTextByText(__('消耗%d')), checkint(stageConf.consumeNum or stageConf.consumeHp))}))
		self:addChild(costHpLabel, 5)

		local costHpIconPath = CommonUtils.GetGoodsIconPathById(stageConf.consumeGoods or HP_ID)
		if QuestBattleType.ACTIVITY_QUEST == CommonUtils.GetQuestBattleByQuestId(checkint(self.stageId)) then
			costHpIconPath = CommonUtils.GetGoodsIconPathById(ACTIVITY_QUEST_HP)
		end
		costHpIcon = display.newNSprite(_res(costHpIconPath), 0, 0)
		costHpIcon:setScale(0.2)
		self:addChild(costHpIcon, 5)

		costHpTime = display.newLabel(0, 0,
			fontWithColor(9, {text = ''}))
		self:addChild(costHpTime, 5)

		-- display.setNodesToNodeOnCenter(battleBtn, {costHpLabel, costHpIcon}, {y = -15})
	end

	self.viewData = {
		centerBg = centerBg,
		belongsBgFrame = belongsBgFrame,
		hintLabel = hintLabel,
		cardHeadScale = cardHeadScale,
		battleBtn = battleBtn,
		costHpLabel = costHpLabel,
		costHpIcon = costHpIcon,
		costHpTime = costHpTime
	}

	
    self.centerContentData = {
        -- {name = summerActMgr:getThemeTextByText(__('队伍')), tag = 1, initHandler = handler(self, self.InitTeamFormationPanel), showHandler = handler(self, self.ShowTeamFormationPanel)},
        -- {name = summerActMgr:getThemeTextByText(__('主角技')), tag = 1, initHandler = handler(self, self.InitPlayerSkillPanel), showHandler = handler(self, self.ShowPlayerSkillPanel)},
        -- {name = summerActMgr:getThemeTextByText(__('堕神诱饵')), tag = 2, initHandler = handler(self, self.InitMagicFoodPanel), showHandler = handler(self, self.ShowMagicFoodPanel)}
    }
    self:InitStageInfo()
	belongsBgFrame:setVisible(0 < #self.centerContentData)

	self:InitFormationContent()
	self:InitBelongings()

	self:RefreshCenterContent(self.selectedCenterIdx or 1)
end
--[[
初始化编队信息
--]]
function SummerActivityReadyView:InitFormationContent()
	self:InitTeamFormationPanel()

	-- local bgSize = self.viewData.centerBg:getContentSize()
	-- local centerBgPos = cc.p(self.viewData.centerBg:getPositionX(), self.viewData.centerBg:getPositionY())

	-- self.viewData.centerContentTabBtns = {}
	-- for i,v in ipairs(self.centerContentData) do
	-- 	-- 创建标签按钮
	-- 	local tabBtn = display.newCheckBox(0, 0, {n = _res('ui/common/maps_fight_btn_tab_default.png'), s = _res('ui/common/maps_fight_btn_tab_select.png')})
	-- 	display.commonUIParams(tabBtn, {po = cc.p(
	-- 		centerBgPos.x + bgSize.width * 0.5 + 8 - (table.nums(self.centerContentData) - (i - 0.5)) * (tabBtn:getContentSize().width + 5),
	-- 		centerBgPos.y + bgSize.height * 0.5 + tabBtn:getContentSize().height * 0.5 + 5)})
	-- 	self:addChild(tabBtn, 20)
	-- 	tabBtn:setTag(v.tag)
	-- 	table.insert(self.viewData.centerContentTabBtns, tabBtn)
	-- 	tabBtn:setOnClickScriptHandler(handler(self, self.ChangeCenterContentBtnCallback))

	-- 	local tabBtnLabel = display.newLabel(utils.getLocalCenter(tabBtn).x, utils.getLocalCenter(tabBtn).y,
	-- 		{text = v.name, fontSize = fontWithColor('12').fontSize, color = fontWithColor('12').color})
	-- 	tabBtn:addChild(tabBtnLabel)


	-- 	if v.initHandler then
	-- 		v.initHandler()
	-- 	end

	-- 	tabBtn:setVisible(false)
	-- end
end
--[[
初始化编队信息以外的携带物品信息
--]]
function SummerActivityReadyView:InitBelongings()
	local bgSize = self.viewData.belongsBgFrame:getContentSize()
	local centerBgPos = cc.p(self.viewData.belongsBgFrame:getPositionX(), self.viewData.belongsBgFrame:getPositionY())

	-- 创建标签按钮
	self.viewData.centerContentTabBtns = {}
	for i,v in ipairs(self.centerContentData) do
		-- 创建标签按钮
		local tabBtn = display.newCheckBox(0, 0, {n = RES_DIR.TABL_BTN, s = _res('ui/common/maps_fight_btn_tab_select.png')})
		display.commonUIParams(tabBtn, {po = cc.p(
			centerBgPos.x - bgSize.width * 0.5 + tabBtn:getContentSize().width * 0.5 + (i - 1) * (5 + tabBtn:getContentSize().width),
			centerBgPos.y + bgSize.height * 0.5 + tabBtn:getContentSize().height * 0.5 + 5)})
		self:addChild(tabBtn, 20)
		tabBtn:setTag(v.tag)
		table.insert(self.viewData.centerContentTabBtns, tabBtn)
		tabBtn:setOnClickScriptHandler(handler(self, self.ChangeCenterContentBtnCallback))

		local tabBtnLabel = display.newLabel(utils.getLocalCenter(tabBtn).x, utils.getLocalCenter(tabBtn).y,
		fontWithColor(12,{text = v.name}))
		tabBtn:addChild(tabBtnLabel)
		tabBtnLabel:setTag(3)

		if v.initHandler then
			v.initHandler()
		end
	end


end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- player skill control begin --
---------------------------------------------------
--[[
初始化主角技选择
--]]
function SummerActivityReadyView:InitPlayerSkillPanel()
	local bgSize = self.viewData.belongsBgFrame:getContentSize()
	local centerBgPos = cc.p(self.viewData.belongsBgFrame:getPositionX(), self.viewData.belongsBgFrame:getPositionY())

	-- 可选槽
	local canSelectSlotInfo = {
		{descr = summerActMgr:getThemeTextByText(__('技能1')), roundIconPath = RES_DIR.SKILL_BG1},
		{descr = summerActMgr:getThemeTextByText(__('技能2')), roundIconPath = RES_DIR.SKILL_BG2},
	}

	self.equipedPlayerSkills = {}
    if gameMgr:GetUserInfo().skill and type(gameMgr:GetUserInfo().skill) == 'table' then
        for i,v in ipairs(gameMgr:GetUserInfo().skill) do
            self.equipedPlayerSkills[tostring(i)] = {skillId = checkint(v)}
        end
    end

	self.allSkills = self:convertPlayerSkillData(gameMgr:GetUserInfo().allSkill)

	local canSlotAmount = table.nums(canSelectSlotInfo)
	local cellWidth = 160
	local skillIconScale = 1
	local skillInfo = nil
	self.viewData.playerSkillLabelBg = {}
	self.viewData.playerSkillIcons = {}
	self.viewData.equipSkillBtns = {}
	for i,v in ipairs(canSelectSlotInfo) do
		local labelBg = display.newNSprite(RES_DIR.SKILL_WORD_BG, 0, 0)
		display.commonUIParams(labelBg, {po = cc.p(
			centerBgPos.x + ((i - 1) - (canSlotAmount - 1) * 0.5) * cellWidth,
			centerBgPos.y + bgSize.height * 0.5 - 25)})
		self:addChild(labelBg, 10)
		table.insert(self.viewData.playerSkillLabelBg, labelBg)

		local label = display.newLabel(utils.getLocalCenter(labelBg).x, utils.getLocalCenter(labelBg).y,
			fontWithColor(12,{text = v.descr}))
		labelBg:addChild(label)

		local skillIconPos = cc.p(labelBg:getPositionX(), labelBg:getPositionY() - labelBg:getContentSize().height * 0.5 - 75)

		skillInfo = self.equipedPlayerSkills[tostring(i)]
		local skillIcon = require('common.PlayerSkillNode').new({id = nil ~= skillInfo and skillInfo.skillId or 0})
		skillIcon:setScale(skillIconScale)
		display.commonUIParams(skillIcon, {cb = handler(self, self.ChangePlayerSkillCallback), po = cc.p(
			skillIconPos.x,
			skillIconPos.y)})
		skillIcon:setTag(i)
		self:addChild(skillIcon, 10)
		skillIcon:setVisible(false)
		table.insert(self.viewData.playerSkillIcons, skillIcon)

		local equipSkillBtn = display.newButton(0, 0, {n = RES_DIR.FRAME_GOODS})
		display.commonUIParams(equipSkillBtn, {cb = handler(self, self.ChangePlayerSkillCallback), po = cc.p(
			skillIconPos.x,
			skillIconPos.y)})
		equipSkillBtn:setTag(i)
		self:addChild(equipSkillBtn, 10)

		local addIcon = display.newNSprite(RES_DIR.ADD, utils.getLocalCenter(equipSkillBtn).x, utils.getLocalCenter(equipSkillBtn).y)
		equipSkillBtn:addChild(addIcon)

		table.insert(self.viewData.equipSkillBtns, equipSkillBtn)
	end
end
--[[
显示或隐藏主角技信息panel
@params visible bool 是否显示
--]]
function SummerActivityReadyView:ShowPlayerSkillPanel(visible)
	if true == visible then
		for i,v in ipairs(self.viewData.playerSkillLabelBg) do
			v:setVisible(true)
		end
		self.viewData.hintLabel:setString(summerActMgr:getThemeTextByText(__('点击技能图标更改主角技')))
		self.viewData.hintLabel:setVisible(true)

		self:RefreshPlayerSkillPanel()
	else
		for i,v in ipairs(self.viewData.playerSkillLabelBg) do
			v:setVisible(false)
		end
		for i,v in ipairs(self.viewData.equipSkillBtns) do
			v:setVisible(false)
		end
		for i,v in ipairs(self.viewData.playerSkillIcons) do
			v:setVisible(false)
		end
	end
end
--[[
换技能按钮回调
--]]
function SummerActivityReadyView:ChangePlayerSkillCallback(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	AppFacade.GetInstance():DispatchObservers("SHOW_SELECT_PLAYER_SKILL", {
		allSkills = self.allSkills.activeSkill,
		equipedPlayerSkills = self.equipedPlayerSkills,
		slotIndex = tag,
		changeEndCallback = function (responseData)

			-- 刷新本地主角技数据
			gameMgr:UpdatePlayer({skill = responseData.skill})

			self.equipedPlayerSkills = {}
			for i,v in ipairs(gameMgr:GetUserInfo().skill) do
				self.equipedPlayerSkills[tostring(i)] = {skillId = checkint(v)}
			end
			self:RefreshPlayerSkillPanel()
		end
	})
end
--[[
刷新主角技装备情况
--]]
function SummerActivityReadyView:RefreshPlayerSkillPanel()
	local skillId = 0
    if gameMgr:GetUserInfo().skill and type(gameMgr:GetUserInfo().skill) == 'table' then
        for i, v in ipairs(gameMgr:GetUserInfo().skill) do
            skillId = checkint(v)
            if 0 == skillId then
                -- 当前未装备
                self.viewData.equipSkillBtns[i]:setVisible(true)
                self.viewData.playerSkillIcons[i]:setVisible(false)
            else
                self.viewData.equipSkillBtns[i]:setVisible(false)
                self.viewData.playerSkillIcons[i]:setVisible(true)
                self.viewData.playerSkillIcons[i]:RefreshUI({id = skillId})
            end
        end
    end
end
---------------------------------------------------
-- player skill control end --
---------------------------------------------------

---------------------------------------------------
-- formation control begin --
---------------------------------------------------
--[[
初始化编队信息
--]]
function SummerActivityReadyView:InitTeamFormationPanel()
	local bgSize = self.viewData.centerBg:getContentSize()
	local centerBgPos = cc.p(self.viewData.centerBg:getPositionX(), self.viewData.centerBg:getPositionY())

	-- 队伍序号
	local teamFormationLabelBg = display.newButton(0, 0, {n = RES_DIR.BG_TITLE_S, scale9 = true})
	-- local teamFormationLabelBg = display.newImageView(RES_DIR.BG_TITLE_S, 0, 0)
	display.commonUIParams(teamFormationLabelBg, {po = cc.p(
		centerBgPos.x - bgSize.width * 0.5 + 5,
		centerBgPos.y + bgSize.height * 0.5 - 5), ap = display.LEFT_CENTER})
	self:addChild(teamFormationLabelBg, 10)

	local teamFormationLabel = teamFormationLabelBg:getLabel()
	display.commonLabelParams(teamFormationLabelBg, fontWithColor(3,{text = summerActMgr:getThemeTextByText(__('出战队伍')), paddingW = 20}))
	-- local teamFormationLabel = display.newLabel(teamFormationLabelBg:getContentSize().width * 0.4, teamFormationLabelBg:getContentSize().height * 0.5,
	-- 	fontWithColor(3,{text = __('出战队伍')}))
	-- teamFormationLabelBg:addChild(teamFormationLabel)
	-- teamFormationLabel:setVisible(false)

	-- 队伍战斗力
	local teamBattlePointBg = display.newImageView(RES_DIR.BG_SWORD1, 0, 0)
	display.commonUIParams(teamBattlePointBg, {po = cc.p(
		centerBgPos.x + bgSize.width * 0.5 + 10 - teamBattlePointBg:getContentSize().width * 0.5,
		centerBgPos.y + bgSize.height * 0.5)})
	self:addChild(teamBattlePointBg, 10)

	local teamBattlePointLabel = display.newLabel(teamBattlePointBg:getContentSize().width * 0.55, 5,
		fontWithColor(9,{text = string.format(summerActMgr:getThemeTextByText(__('队伍灵力:%d')), 0), ap = cc.p(0.5, 0)}))
	teamBattlePointBg:addChild(teamBattlePointLabel)

	-- 调整队伍
	local changeTeamFormationBtn = display.newButton(0, 0, {n = RES_DIR.BTN_ORANGE, scale9 = true})
	display.commonUIParams(changeTeamFormationBtn, {po = cc.p(
		centerBgPos.x + bgSize.width * 0.5,
		centerBgPos.y - bgSize.height * 0.5 - 15 - changeTeamFormationBtn:getContentSize().height * 0.5),
		ap = display.RIGHT_CENTER,
		cb = function (sender)
			PlayAudioByClickNormal()
			AppFacade.GetInstance():DispatchObservers("SHOW_EDIT_TEAM_LAYER", {teamData = clone(self.teamData[self.selectedTeamIdx].members), recommendCards = self.recommendCards})
			-- self:ShowEditTeamLayer()
		end
	})
	display.commonLabelParams(changeTeamFormationBtn, fontWithColor(14,{text = summerActMgr:getThemeTextByText(__('调整队伍')), paddingW = 20}))
	self:addChild(changeTeamFormationBtn, 10)

	-- -- 前后按钮
	-- local preBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_switch.png'), cb = handler(self, self.ChangeTeamFormationBtnCallback)})
	-- preBtn:setScaleX(-1)
	-- display.commonUIParams(preBtn, {po = cc.p(
	-- 	centerBgPos.x - bgSize.width * 0.5 + preBtn:getContentSize().width * 0.5 - 60,
	-- 	centerBgPos.y)})
	-- self:addChild(preBtn, 20)
	-- preBtn:setTag(1001)

	-- local nextBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_switch.png'), cb = handler(self, self.ChangeTeamFormationBtnCallback)})
	-- display.commonUIParams(nextBtn, {po = cc.p(
	-- 	centerBgPos.x + bgSize.width * 0.5 - nextBtn:getContentSize().width * 0.5 + 60,
	-- 	centerBgPos.y)})
	-- self:addChild(nextBtn, 20)
	-- nextBtn:setTag(1002)

	self.viewData.teamFormationLabelBg = teamFormationLabelBg
	self.viewData.teamBattlePointBg = teamBattlePointBg
	self.viewData.teamFormationLabel = teamFormationLabel
	self.viewData.teamBattlePointLabel = teamBattlePointLabel
	self.viewData.changeTeamFormationBtn = changeTeamFormationBtn
	-- self.viewData.preTeamBtn = preBtn
	-- self.viewData.nextTeamBtn = nextBtn
	self.viewData.teamTabs = {}
	self.viewData.cardHeadNodes = {}

	self:RefreshTeamFormation(self.teamMembers or gameMgr:GetUserInfo().teamFormation)
end
--[[
刷新中间队伍区域
@params data table 队伍信息
--]]
function SummerActivityReadyView:RefreshTeamFormation(data)
	------------ 处理编队数据 ------------
	local teamData = {}
	local teamCardIds = {}
	for tNo, tData in ipairs(data) do
		teamData[tNo] = {teamId = tData.teamId, members = {}}
		for no, card in ipairs(tData.cards) do
			if card.id then
				local id = checkint(card.id)
				local cardData = gameMgr:GetCardDataById(id)
				table.insert(teamData[tNo].members, {id = id, isLeader = id == checkint(tData.captainId)})
				teamCardIds[tostring(cardData.cardId)] = cardData.cardId
			end
		end
	end
	
	self.teamCardIds = teamCardIds
	self.teamData = teamData

	self:RefreshRecommendCardsState()
	self:RefreshTeamTabs()
end
--[[
刷新队伍周围信息
--]]
function SummerActivityReadyView:RefreshTeamTabs()
	-- if table.nums(self.teamData) ~= table.nums(self.viewData.teamTabs) then
	-- 	for i,v in ipairs(self.viewData.teamTabs) do
	-- 		v:removeFromParent()
	-- 	end

	-- 	self.viewData.teamTabs = {}

	-- 	for i,v in ipairs(self.teamData) do
	-- 		local teamCircle = display.newNSprite(_res('ui/common/maps_fight_ico_round_default.png'), 0, 0)
	-- 		self:addChild(teamCircle, 5)
	-- 		table.insert(self.viewData.teamTabs, teamCircle)
	-- 	end

	-- 	display.setNodesToNodeOnCenter(self.viewData.centerBg, self.viewData.teamTabs, {spaceW = 5, y = -15})
	-- end

	self:RefreshTeamSelectedState(self.selectedTeamIdx or 1)
end
--[[
刷新队伍选中状态
--]]
function SummerActivityReadyView:RefreshTeamSelectedState(index)
	
	self.selectedTeamIdx = index

	-- 刷新队伍信息
	-- self.viewData.teamFormationLabel:setString(string.format(summerActMgr:getThemeTextByText(__('出战队伍')), self.selectedTeamIdx))

	self:RefreshTeamInfo(self.teamData[self.selectedTeamIdx])
end
--[[
刷新队伍信息
@params teamData table 队伍信息
--]]
function SummerActivityReadyView:RefreshTeamInfo(teamData)
	-- 刷新头像
	for i,v in ipairs(self.viewData.cardHeadNodes) do
		v:removeFromParent()
	end
	self.viewData.cardHeadNodes = {}

	local bgSize = self.viewData.centerBg:getContentSize()
	local centerBgPos = cc.p(self.viewData.centerBg:getPositionX(), self.viewData.centerBg:getPositionY())

	local totalBattlePoint = 0
	local teamMemberMax = 5
	local paddingX = 10
	local cellWidth = (bgSize.width - paddingX * 2) / teamMemberMax
	local scale = self.viewData.cardHeadScale
	-- logInfo.add(5, tableToString(teamData))
	for i,v in ipairs(teamData.members) do
		local cardHeadNode = require('common.CardHeadNode').new({id = checkint(v.id), showActionState = false, showVigourState = false})
		cardHeadNode:setScale(scale)
		cardHeadNode:setPosition(cc.p(
			(centerBgPos.x - bgSize.width * 0.5 + paddingX) + cellWidth * (i - 0.5),
			centerBgPos.y - bgSize.height * 0.5 + cardHeadNode:getContentSize().height * 0.5 * scale + 15))
		self:addChild(cardHeadNode, 15)

		table.insert(self.viewData.cardHeadNodes, cardHeadNode)
		
		-- 计算战斗力
		totalBattlePoint = totalBattlePoint + cardMgr.GetCardStaticBattlePointById(checkint(v.id))
	end

	-- 刷新战斗力
	self.viewData.teamBattlePointLabel:setString(string.format(summerActMgr:getThemeTextByText(__('队伍灵力:%d')), totalBattlePoint))

end
--[[
显示或隐藏编队信息panel
@params visible bool 是否显示
--]]
function SummerActivityReadyView:ShowTeamFormationPanel(visible)
	self.viewData.teamFormationLabelBg:setVisible(visible)
	self.viewData.teamBattlePointBg:setVisible(visible)
	self.viewData.changeTeamFormationBtn:setVisible(visible)
	-- for i,v in ipairs(self.viewData.teamTabs) do
	-- 	v:setVisible(visible)
	-- end
	for i,v in ipairs(self.viewData.cardHeadNodes) do
		v:setVisible(visible)
	end
	if visible then
		self:RefreshTeamSelectedState(self.selectedTeamIdx or 1)
	else
		-- self.viewData.preTeamBtn:setVisible(visible)
		-- self.viewData.nextTeamBtn:setVisible(visible)
	end
end
---------------------------------------------------
-- formation control end --
---------------------------------------------------

---------------------------------------------------
-- pet food begin --
---------------------------------------------------
--[[
初始化堕神诱饵
--]]
function SummerActivityReadyView:InitMagicFoodPanel()
	local bgSize = self.viewData.belongsBgFrame:getContentSize()
	local centerBgPos = cc.p(self.viewData.belongsBgFrame:getPositionX(), self.viewData.belongsBgFrame:getPositionY())

	-- 选择按钮
	local magicFoodNodeScale = 1
	local equipMagicFoodNode = display.newButton(0, 0, {n = _res('ui/common/common_frame_goods_1.png'), cb = function (sender)
		PlayAudioByClickNormal()
		AppFacade.GetInstance():DispatchObservers("SHOW_SELECT_MAGIC_FOOD", {
			equipedMagicFoodId = self.equipedMagicFoodId,
			equipCallback = handler(self, self.RefreshMagicFoodState)
		})
	end})
	equipMagicFoodNode:setScale(magicFoodNodeScale)
	display.commonUIParams(equipMagicFoodNode, {po = cc.p(centerBgPos.x, centerBgPos.y)})
	self:addChild(equipMagicFoodNode, 15)

	local addIcon = display.newNSprite(_res('ui/common/maps_fight_btn_pet_add.png'), utils.getLocalCenter(equipMagicFoodNode).x, utils.getLocalCenter(equipMagicFoodNode).y)
	equipMagicFoodNode:addChild(addIcon)

	-- 更换按钮
	local changeMagicFoodBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png'), cb = function (sender)
		PlayAudioByClickNormal()
		AppFacade.GetInstance():DispatchObservers("SHOW_SELECT_MAGIC_FOOD", {
			equipedMagicFoodId = self.equipedMagicFoodId,
			equipCallback = handler(self, self.RefreshMagicFoodState)
		})
	end})
	display.commonUIParams(changeMagicFoodBtn, {po = cc.p(centerBgPos.x, centerBgPos.y - bgSize.height * 0.5 + 10 + changeMagicFoodBtn:getContentSize().height * 0.5)})
	display.commonLabelParams(changeMagicFoodBtn, fontWithColor(14,{text = summerActMgr:getThemeTextByText(__('更换诱饵'))}))
	self:addChild(changeMagicFoodBtn, 15)

	self.viewData.equipMagicFoodNode = equipMagicFoodNode
	self.viewData.magicFoodNode = nil
	self.viewData.changeMagicFoodBtn = changeMagicFoodBtn

	self:RefreshMagicFoodState(self.equipedMagicFoodId)
end
--[[
刷新诱饵状态
@params magicFoodId int 魔法食物id
--]]
function SummerActivityReadyView:RefreshMagicFoodState(magicFoodId)
	if nil == magicFoodId then
		self.viewData.equipMagicFoodNode:setVisible(true)
		self.viewData.changeMagicFoodBtn:setVisible(false)
		if self.viewData.magicFoodNode then
			self.viewData.magicFoodNode:setVisible(false)
		end
	else
		self.viewData.equipMagicFoodNode:setVisible(false)
		self.viewData.changeMagicFoodBtn:setVisible(true)
		if self.viewData.magicFoodNode then
			self.viewData.magicFoodNode:removeFromParent()
			self.viewData.magicFoodNode = nil
		end
		self.viewData.magicFoodNode = require('common.GoodNode').new({id = magicFoodId, showAmount = true, amount = gameMgr:GetAmountByGoodId(magicFoodId)})
		self.viewData.magicFoodNode:setScale(0.75)
		display.commonUIParams(self.viewData.magicFoodNode, {po = cc.p(self.viewData.changeMagicFoodBtn:getPositionX(), self.viewData.changeMagicFoodBtn:getPositionY() + 80)})
		self:addChild(self.viewData.magicFoodNode, 15)
	end

	self.equipedMagicFoodId = magicFoodId
end
--[[
显示或隐藏堕神诱饵信息panel
@params visible bool 是否显示
--]]
function SummerActivityReadyView:ShowMagicFoodPanel(visible)
	if visible then
		self:RefreshMagicFoodState(self.equipedMagicFoodId)
		self.viewData.hintLabel:setString(summerActMgr:getThemeTextByText(__('点击技能图标更改魔法食物')))
		self.viewData.hintLabel:setVisible(false)
	else
		self.viewData.equipMagicFoodNode:setVisible(false)
		self.viewData.changeMagicFoodBtn:setVisible(false)
		if self.viewData.magicFoodNode then
			self.viewData.magicFoodNode:setVisible(false)
		end
	end
end

---------------------------------------------------
-- pet food end --
---------------------------------------------------

---------------------------------------------------
-- stage info control begin --
---------------------------------------------------
--[[
初始化关卡详情
--]]
function SummerActivityReadyView:InitStageInfo()

	local stageConf = CommonUtils.GetQuestConf(checkint(self.stageId))

	-- 关卡详情底板
	local stageInfoBgSize = cc.size(578, 605)
	local stageInfoBgPos = cc.p(display.SAFE_L + stageInfoBgSize.width * 0.5 + 30, display.height * 0.45)
	local stageInfoBg = display.newImageView(RES_DIR.BG_INFORMATION, 0, 0,
		{scale9 = true, size = stageInfoBgSize, enable = true, animate = false})
	display.commonUIParams(stageInfoBg, {po = stageInfoBgPos})
	self:addChild(stageInfoBg, 5)

	local stageInfoBgLayer = display.newLayer(stageInfoBg:getPositionX(), stageInfoBg:getPositionY(), {ap = stageInfoBg:getAnchorPoint(), size = stageInfoBgSize})
	self:addChild(stageInfoBgLayer, 5)

	-- 分隔线1 关卡信息
	local splitLineStageInfo = display.newNSprite(_res('ui/common/maps_fight_line.png'), stageInfoBgSize.width * 0.5, stageInfoBgSize.height - 70)
	stageInfoBg:addChild(splitLineStageInfo)

	local maxStarLabel = display.newLabel(
		splitLineStageInfo:getPositionX() - splitLineStageInfo:getContentSize().width * 0.5 + 5,
		splitLineStageInfo:getPositionY(),
		{text = summerActMgr:getThemeTextByText(__('今日能力提升飨灵')), fontSize = 24, w = 460, color = '#bba496', ap = cc.p(0, 0)})
	stageInfoBg:addChild(maxStarLabel)
	local maxStarLabelSize = display.getLabelContentSize(maxStarLabel)

	local tipsBtn = display.newButton(maxStarLabel:getPositionX() + maxStarLabelSize.width + 10, maxStarLabel:getPositionY(), {ap = display.LEFT_BOTTOM, n = _res('ui/common/common_btn_tips.png'), cb = handler(self, self.TipsBtnCallback)})	
	stageInfoBgLayer:addChild(tipsBtn)
	
	local recommendCardLayerSize = cc.size(stageInfoBgSize.width, 120)
	local recommendCardLayer = display.newLayer(stageInfoBgSize.width / 2, stageInfoBgSize.height - 145, 
		{ap = display.CENTER, size = recommendCardLayerSize})
	stageInfoBg:addChild(recommendCardLayer)
	self.recommendCardLayer = recommendCardLayer
	-- 推荐卡牌
	if self.recommendCards then
		self:CreateRecommendCards(recommendCardLayer, self.recommendCards)
	end

	-- 天气预报
	local forecastLabel = display.newLabel(
		maxStarLabel:getPositionX(),
		stageInfoBgSize.height * 0.575,
		{text = summerActMgr:getThemeTextByText(__('天气情况')), fontSize = 26, color = '#bba496', ap = cc.p(0, 0.5)})
	stageInfoBg:addChild(forecastLabel)

	-- 分隔线2 关卡掉落
	local splitLineStageReward = display.newNSprite(_res('ui/common/maps_fight_line.png'), stageInfoBgSize.width * 0.5, 235)
	stageInfoBg:addChild(splitLineStageReward)

	
	-- 掉落信息
	local rewardLabel = display.newLabel(
		splitLineStageReward:getPositionX() - splitLineStageReward:getContentSize().width * 0.5 + 5,
		splitLineStageReward:getPositionY() + 20,
		{text = summerActMgr:getThemeTextByText(__('关卡可能掉落')), fontSize = 26, color = '#bba496', ap = cc.p(0, 0.5)})
	stageInfoBg:addChild(rewardLabel)

	local x = 1
	-- 扫荡按钮
	-- if QuestRechallenge.QR_CAN == checkint(stageConf.repeatChallenge) then
	-- 	local sweepBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png'), cb = handler(self, self.SweepBtnCallback)})
	-- 	display.commonUIParams(sweepBtn, {po = cc.p(stageInfoBgPos.x * 0.5, stageInfoBgPos.y - stageInfoBgSize.height * 0.5 + sweepBtn:getContentSize().height * 0.5 + 20)})
	-- 	display.commonLabelParams(sweepBtn, fontWithColor(14,{text = summerActMgr:getThemeTextByText(__('扫荡')})))
	-- 	self:addChild(sweepBtn, 20)
	-- 	x = 2
	-- end

	-- -- 关卡评论
 	-- local commentBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png'), cb = handler(self, self.commentBtnCallBack)})
	-- display.commonUIParams(commentBtn, {po = cc.p(stageInfoBgPos.x * 0.5 * (1 + x), stageInfoBgPos.y - stageInfoBgSize.height * 0.5 + commentBtn:getContentSize().height * 0.5 + 20)})
	-- display.commonLabelParams(commentBtn, fontWithColor(14,{text = summerActMgr:getThemeTextByText( __('关卡评论')}))
	-- self:addChild(commentBtn, 111)
	
	
	local bossDesBtn = self:CraeteBossDescBtn()
	
	if stageConf then
	
		local text = ''
		if checkint(stageConf.questType) == 1 then
			text = summerActMgr:getThemeTextByText(__('完成本关卡，可获得500点游乐园点数。'))
		elseif checkint(stageConf.questType) == 3 then
			text = summerActMgr:getThemeTextByText(__('完成本关卡，根据所造成的伤害折算成游乐园点数，每1000点伤害为1点游乐园点数，不满1000不会计入。'))
		end
		local descrViewSize  = cc.size(stageInfoBgSize.width - 50, 88)
		local descrContainer = cc.ScrollView:create()
		descrContainer:setViewSize(descrViewSize)
		descrContainer:setAnchorPoint(display.LEFT_TOP)
		descrContainer:setDirection(eScrollViewDirectionVertical)
		descrContainer:setPosition(cc.p(rewardLabel:getPositionX(), rewardLabel:getPositionY() - 240))
		-- descrContainer:setBackgroundColor(cc.c4b(23, 67, 128, 128))
		stageInfoBg:addChild(descrContainer)

		local questTipLabel = display.newLabel(0, 0, fontWithColor(18, {w = descrViewSize.width, ap = display.LEFT_TOP, text = text}))
		-- stageInfoBg:addChild(questTipLabel)
		descrContainer:setContainer(questTipLabel)
		local descrScrollTop = descrViewSize.height - display.getLabelContentSize(questTipLabel).height
		descrContainer:setContentOffset(cc.p(0, descrScrollTop))


		local questBattleType = CommonUtils.GetQuestBattleByQuestId(checkint(self.stageId))

		local stageTitleStr = ''
		local bgId = 1

		if QuestBattleType.MAP == questBattleType then

			stageTitleStr = string.format('%s-%s %s', stageConf.cityId, stageConf.position, stageConf.name)

			local cityConf = CommonUtils.GetConfig('quest', 'city', stageConf.cityId)
			bgId = cityConf.backgroundId[stageConf.difficulty]

		elseif QuestBattleType.ACTIVITY_QUEST == CommonUtils.GetQuestBattleByQuestId(checkint(self.stageId)) then

			stageTitleStr = string.format('%s', stageConf.name)

			local zoneId = checkint(stageConf.zoneId)
			local zoneConfig = CommonUtils.GetConfigNoParser('activityQuest', 'questType', zoneId)
			if nil ~= zoneConfig then
				local activityQuestConfig = zoneConfig[tostring(self.stageId)]
				if nil ~= activityQuestConfig then
					bgId = checkint(activityQuestConfig.backgroundId)
				end
			end

		end
		-- 垫上一张背景图
        local bgView = CLayout:create(cc.size(1336,1002))
		local bgPath = string.format('arts/maps/maps_bg_%s', bgId)
        local leftImage = display.newImageView(_res(string.format('%s_01', bgPath)), 0, 0, {ap = display.LEFT_BOTTOM})
        bgView:addChild(leftImage)
        local rightImage = display.newImageView(_res(string.format('%s_02', bgPath)), 1336, 0, {ap = display.RIGHT_BOTTOM})
        bgView:addChild(rightImage)
        display.commonUIParams(bgView,{ap = display.CENTER, po = cc.p(self:getContentSize().width * 0.5, self:getContentSize().height * 0.5)})
        fullScreenFixScale(bgView)
        self:addChild(bgView)

		-- -- 关卡信息
		-- local stageTitleBg = display.newNSprite(_res('ui/common/maps_fight_bg_title.png'), 0, 0)
		-- display.commonUIParams(stageTitleBg, {po = cc.p(
		-- 	self.closeBtn:getPositionX() + self.closeBtn:getContentSize().width * 0.5 + stageTitleBg:getContentSize().width * 0.5 + 10,
		-- 	self.closeBtn:getPositionY())})
		-- self:addChild(stageTitleBg, 5)

		-- local stageTitleLabel = display.newLabel(stageTitleBg:getContentSize().width * 0.4, utils.getLocalCenter(stageTitleBg).y,
		-- 	{text = stageTitleStr, fontSize = 28, color = '#ffffff'})
		-- stageTitleBg:addChild(stageTitleLabel)
		-- self.stageTitleText = stageTitleStr

		-- -- 推荐战力
		-- local recommandLabel = display.newLabel(
		-- 	splitLineStageInfo:getPositionX() + splitLineStageInfo:getContentSize().width * 0.5 - 5,
		-- 	splitLineStageInfo:getPositionY() + 20,
		-- 	{text = string.format(summerActMgr:getThemeTextByText() __('(推荐等级:%d)'), checkint(stageConf.recommendLevel)), fontSize = 22, color = '#ffffff', ap = cc.p(1, 0.5)})
		-- stageInfoBg:addChild(recommandLabel)

		-- if QuestRechallenge.QR_CAN == checkint(stageConf.repeatChallenge) and nil ~= stageConf.allClean then
		-- 	-- 三星条件
		-- 	local itor = 1
		-- 	for k,v in pairs(stageConf.allClean) do
		-- 		local clearData = CommonUtils.GetConfig('quest', 'starCondition', checkint(k))
		-- 		local descr = CommonUtils.GetFixedClearDesc(clearData, v)
		-- 		local pass = table.nums(stageConf.allClean) == self.star
		-- 		local cleanLabelColor = '#ffffff'
		-- 		if pass then
		-- 			cleanLabelColor = '#ffd52c'
		-- 		end
		-- 		local cleanLabel = display.newLabel(maxStarLabel:getPositionX(), splitLineStageInfo:getPositionY() - 30 - (itor - 1) * 35,
		-- 			{text = descr, fontSize = 22, color = cleanLabelColor, ap = cc.p(0, 0.5)})
		-- 		stageInfoBg:addChild(cleanLabel)
		-- 		itor = itor + 1
		-- 	end

		-- 	if 0 < checkint(stageConf.challengeTime) then
		-- 		-- 剩余挑战次数
		-- 		local challengeTimeLabelBg = display.newNSprite(_res('ui/battleready/maps_fight_bg_challenge_times.png'), 0, 0)
		-- 		self:addChild(challengeTimeLabelBg, 5)
		-- 		self.challengeTimeLabelBg = challengeTimeLabelBg

		-- 		local challengeTimeDescrLabel = display.newLabel(0, 0, {
		-- 			text = summerActMgr:getThemeTextByText() __('今日挑战次数'), fontSize = fontWithColor('18').fontSize, color = fontWithColor('18').color, ap = cc.p(0, 0.5)})
		-- 		display.commonUIParams(challengeTimeDescrLabel, {po = cc.p(5, utils.getLocalCenter(challengeTimeLabelBg).y)})
		-- 		challengeTimeLabelBg:addChild(challengeTimeDescrLabel)

		-- 		local challengeTimeLabel = display.newLabel(0, 0, {
		-- 			text = string.format('%d/%d', checkint(gameMgr:GetUserInfo().allQuestChallengeTimes[tostring(self.stageId)]), checkint(stageConf.challengeTime)), fontSize = 22, color = '#ffd52c'})
		-- 		display.commonUIParams(challengeTimeLabel, {po = cc.p(170, utils.getLocalCenter(challengeTimeLabelBg).y)})
		-- 		challengeTimeLabelBg:addChild(challengeTimeLabel)
		-- 		self.challengeTimeLabel = challengeTimeLabel

		-- 		local buyChallengTimeBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_add.png'), cb = function (sender)
		-- 			AppFacade.GetInstance():DispatchObservers("SHOW_BUY_CHALLENGE_TIME", {stageId = self.stageId})
		-- 		end})
		-- 		self:addChild(buyChallengTimeBtn, 5)
		-- 		self.buyChallengTimeBtn = buyChallengTimeBtn
		-- 	end

		-- else
		-- 	local noAllCleanLabel = display.newLabel(
		-- 		maxStarLabel:getPositionX() + 3,
		-- 		splitLineStageInfo:getPositionY() - 50,
		-- 		{text = summerActMgr:getThemeTextByText() __('本关卡无三星过关条件'), fontSize = 22, color = '#c9b4b0', ap = cc.p(0, 0.5)})
		-- 	stageInfoBg:addChild(noAllCleanLabel)
		-- end

		-- 天气情况
		local weatherId = nil
		local weatherIconScale = 0.4
		for i,v in ipairs(stageConf.weatherId) do
			weatherId = checkint(v)
			local weatherConf = CommonUtils.GetConfig('quest', 'weather', weatherId)
			local weatherBtn = display.newButton(0, 0, {
				n = _res(string.format('ui/common/fight_ico_weather_%d.png', checkint(weatherConf.weatherProperty))),
				cb = function (sender)
					uiMgr:ShowInformationTipsBoard({targetNode = sender, title = weatherConf.name, descr = weatherConf.descr, type = 5})
				end
			})
			weatherBtn:setScale(weatherIconScale)
			local pos = self:convertToNodeSpace(stageInfoBg:convertToWorldSpace(cc.p(
				forecastLabel:getPositionX() + display.getLabelContentSize(forecastLabel).width + 10 + weatherBtn:getContentSize().width * weatherIconScale * 0.5 + (((weatherBtn:getContentSize().width * weatherIconScale) + 5) * (i - 1)),
				forecastLabel:getPositionY() + 2)))
			display.commonUIParams(weatherBtn, {po = pos})
			self:addChild(weatherBtn, 15)
		end

		-- 奖励金币和经验
		local iconScale = 0.2
		local goldIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(900002)), 0, 0)
		goldIcon:setScale(iconScale)
		display.commonUIParams(goldIcon, {po = cc.p(splitLineStageReward:getPositionX() + 75 + 120, splitLineStageReward:getPositionY() + 20)})
		stageInfoBg:addChild(goldIcon)

		local goldLabel = display.newLabel(
			goldIcon:getPositionX() + goldIcon:getContentSize().width * 0.5 * iconScale + 5,
			goldIcon:getPositionY(),
			{text = tostring(stageConf.gold), fontSize = 22, color = '#ffffff', ap = cc.p(0, 0.5)})
		stageInfoBg:addChild(goldLabel)

		-- local expIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(EXP_ID)), 0, 0)
		-- expIcon:setScale(iconScale)
		-- display.commonUIParams(expIcon, {po = cc.p(goldIcon:getPositionX() + 120, splitLineStageReward:getPositionY() + 20)})
		-- stageInfoBg:addChild(expIcon)

		-- local mainExp = stageConf.mainExp
		-- if stageConf.firstPassMainExp and checkint(self.stageId) >= gameMgr:GetNewestQuestIdByDifficulty(checkint(stageConf.difficulty)) then
		-- 	mainExp = stageConf.firstPassMainExp

		-- 	local firstLabel = display.newLabel(0, 0, fontWithColor('14', {text = summerActMgr:getThemeTextByText() __('首次通关')}))
		-- 	display.commonUIParams(firstLabel, {ap = cc.p(0, 0), po = cc.p(
		-- 		expIcon:getPositionX() - expIcon:getContentSize().width * 0.5 * iconScale,
		-- 		expIcon:getPositionY() + expIcon:getContentSize().height * 0.5 * iconScale
		-- 	)})
		-- 	stageInfoBg:addChild(firstLabel)
		-- end

		-- local expLabel = display.newLabel(
		-- 	expIcon:getPositionX() + expIcon:getContentSize().width * 0.5 * iconScale + 5,
		-- 	expIcon:getPositionY(),
		-- 	{text = tostring(mainExp), fontSize = 22, color = '#ffffff', ap = cc.p(0, 0.5)})
		-- stageInfoBg:addChild(expLabel)

		local rewardIconPerLine = 5
		local paddingX = -5
		local cellWidth = 105
		local goodNodeScale = 0.9
		local _p = self:convertToNodeSpace(stageInfoBg:convertToWorldSpace(cc.p(splitLineStageReward:getPositionX(), splitLineStageReward:getPositionY())))

		-- 处理奖励信息 有的关卡存在拆分的奖励信息
		local stageRewardsInfo = {}

		if stageConf.hardQuestRewards and 0 < #stageConf.hardQuestRewards then
			-- 插入困难本拆分的奖励
			for i,v in ipairs(stageConf.hardQuestRewards) do
				table.insert(stageRewardsInfo, v)
			end
		end

		if stageConf.rewards and 0 < #stageConf.rewards then
			-- 插入通常奖励
			for i,v in ipairs(stageConf.rewards) do
				table.insert(stageRewardsInfo, v)
			end
		end

		for i,v in ipairs(stageRewardsInfo) do
			if i <= 5 then
				local function callBack(sender)
					AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
				end
				local goodNode = require('common.GoodNode').new({id = checkint(v.goodsId), showAmount = false, callBack = callBack})
				goodNode:setScale(goodNodeScale)
				display.commonUIParams(goodNode, {po = cc.p(
					stageInfoBgPos.x + paddingX + (cellWidth * (((i - 1) % rewardIconPerLine + 1) - (rewardIconPerLine + 1) * 0.5)),
					_p.y - 15 - goodNode:getContentSize().height * (0.5 + math.ceil(i / rewardIconPerLine) - 1) * goodNodeScale)})
				self:addChild(goodNode, 15)
			end
		end
	end

	-- 移动中间块位置
	self.viewData.centerBg:setPosition(cc.p(
		display.SAFE_R - self.viewData.centerBg:getContentSize().width * 0.5 - 50,
		stageInfoBgPos.y + stageInfoBgSize.height * 0.5 - self.viewData.centerBg:getContentSize().height * 0.5)
	)

	-- 移动主角技模块
	self.viewData.belongsBgFrame:setPosition(
		self.viewData.centerBg:getPositionX() - self.viewData.centerBg:getContentSize().width * 0.5 + self.viewData.belongsBgFrame:getContentSize().width * 0.5,
		stageInfoBgPos.y - stageInfoBgSize.height * 0.5 + self.viewData.belongsBgFrame:getContentSize().height * 0.5
	)

	-- 移动进入战斗位置
	local offsetY = nil ~= self.challengeTimeLabelBg and 35 or 0
	display.commonUIParams(self.viewData.battleBtn, {po = cc.p(
		self.viewData.centerBg:getPositionX() + self.viewData.centerBg:getContentSize().width * 0.5 - self.viewData.battleBtn:getContentSize().width * 0.5,
		self.viewData.belongsBgFrame:getPositionY() + offsetY)})

	if nil ~= self.viewData.costHpLabel and nil ~= self.viewData.costHpIcon and nil ~= self.viewData.costHpTime then
		display.setNodesToNodeOnCenter(self.viewData.battleBtn, {self.viewData.costHpLabel, self.viewData.costHpIcon, self.viewData.costHpTime}, {y = -15})
	end

	-- 剩余挑战次数位置
	if nil ~= self.challengeTimeLabelBg and nil ~= self.buyChallengTimeBtn then
		display.commonUIParams(self.challengeTimeLabelBg, {po = cc.p(
			self.viewData.battleBtn:getPositionX() - 25,
			self.viewData.battleBtn:getPositionY() - self.viewData.battleBtn:getContentSize().height * 0.5 - 58)})
		display.commonUIParams(self.buyChallengTimeBtn, {po = cc.p(
			self.challengeTimeLabelBg:getPositionX() + self.challengeTimeLabelBg:getContentSize().width * 0.5 + self.buyChallengTimeBtn:getContentSize().width * 0.5 - 20,
			self.challengeTimeLabelBg:getPositionY())})
	end

end


function SummerActivityReadyView:commentBtnCallBack(sender)
	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.QuestComment_CommentView, {
		stageId = self.stageId,
		stageTitleText = self.stageTitleText
	})
end

function SummerActivityReadyView:BossDescrBtnCallback(sender)
	local bossDetailMediator = require('Game.mediator.BossDetailMediator').new({questId = self.stageId})
    app:RegistMediator(bossDetailMediator)
end

function SummerActivityReadyView:TipsBtnCallback(sender)
	uiMgr:ShowIntroPopup({moduleId = '-5'})
end

---------------------------------------------------
-- stage info control end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
上标签按钮点击回调
--]]
function SummerActivityReadyView:ChangeCenterContentBtnCallback(sender)
	PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id)
	local tag = sender:getTag()
	self:RefreshCenterContent(tag)
end
--[[
刷新整个中间框架
@params index int 序号
--]]
function SummerActivityReadyView:RefreshCenterContent(index)
	local curCenterTabBtn = self.viewData.centerContentTabBtns[index]
	if curCenterTabBtn then
		curCenterTabBtn:setChecked(true)
		display.commonLabelParams(curCenterTabBtn:getChildByTag(3), {color = fontWithColor('13').color})
	end

	if self.selectedCenterIdx == index then return end

	local preCenterTabBtn = self.viewData.centerContentTabBtns[self.selectedCenterIdx]
	if preCenterTabBtn then
		preCenterTabBtn:setChecked(false)
		display.commonLabelParams(preCenterTabBtn:getChildByTag(3), {color = fontWithColor('12').color})
	end

	local curCenterData = self.centerContentData[index]
	if curCenterData and curCenterData.showHandler then
		curCenterData.showHandler(true)
	end

	for i,v in ipairs(self.centerContentData) do
		if (index ~= i) and v.showHandler then
			v.showHandler(false)
		end
	end

	self.selectedCenterIdx = index
end
--[[
阵容前后按钮点击回调
1001 前
1002 后
--]]
function SummerActivityReadyView:ChangeTeamFormationBtnCallback(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if 1001 == tag then
		self:RefreshTeamSelectedState(math.max(1, self.selectedTeamIdx - 1))
	elseif 1002 == tag then
		self:RefreshTeamSelectedState(math.min(table.nums(self.teamData), self.selectedTeamIdx + 1))
	end
end
--[[
进入战斗
--]]
function SummerActivityReadyView:EnterBattle(sender)
	if QuestBattleType.SEASON_EVENT == self.questBattleType then
		AppFacade.GetInstance():DispatchObservers('ENTER_SEASON_EVENT_BATTLE', {cards = self.teamData[self.selectedTeamIdx].members, questId = self.stageId})
		return
	end
	------------ 本地逻辑判断 ------------
	-- 是否可以进入该关卡
	local canEnter, errLog = CommonUtils.CanEnterStageIdByStageId(self.stageId)
	if not canEnter then
		uiMgr:ShowInformationTips(errLog)
		return
	end

	-- 是否可以复刷
	local stageConf = CommonUtils.GetQuestConf(checkint(self.stageId))
	if stageConf and QuestRechallenge.QR_CAN == checkint(stageConf.repeatChallenge) and 0 < checkint(stageConf.challengeTime) then
		-- 可以复刷的条件
		if QuestRechallengeTime.QRT_NONE == checkint(gameMgr:GetUserInfo().allQuestChallengeTimes[tostring(self.stageId)]) then
			-- 次数不够
			uiMgr:ShowInformationTips(summerActMgr:getThemeTextByText(__('挑战次数不足\n挑战次数每日0:00重置')))
			return
		end
	end
	------------ 本地逻辑判断 ------------

	local selectedTeamData = self.teamData[self.selectedTeamIdx]

	if table.nums(selectedTeamData.members) == 0 then
		-- TODO 跳转编队
		local CommonTip  = require( 'common.CommonTip' ).new({text = summerActMgr:getThemeTextByText(__('队伍不能为空')),isOnlyOK = true})
		CommonTip:setPosition(display.center)
		AppFacade.GetInstance():GetManager("UIManager"):GetCurrentScene():AddDialog(CommonTip)
	else

		-- 如果是工会神兽战 传信号出去 不在里面处理
		if QuestBattleType.UNION_BEAST == self.questBattleType then
			local data = {
				teamIdx = self.selectedTeamIdx
			}
			AppFacade.GetInstance():DispatchObservers('ENTER_UNION_BEAST_BATTLE', data)
			return
		end

		local serverCommand = BattleNetworkCommandStruct.New(
			self.enterBattleRequestCommand,
			self.enterBattleRequestData,
			self.enterBattleResponseSignal,
			self.exitBattleRequestCommand,
			self.exitBattleRequestData,
			self.exitBattleResponseSignal,
			nil,
			nil,
			nil
		)

		local fromToStruct = BattleMediatorsConnectStruct.New(
			self.fromMediatorName,
			self.toMediatorName
		)

		local battleConstructor = require('battleEntry.BattleConstructor').new()

		local canBattle, waringText = battleConstructor:CanEnterBattleByTeamId(self.selectedTeamIdx)
		if not canBattle then
			if nil ~= waringText then
				uiMgr:ShowInformationTips(waringText)
			end
			return
		end

		if QuestBattleType.ROBBERY == self.questBattleType then
		-- if true then
			battleConstructor:InitDataByTakeawayRobbery(self.selectedTeamIdx, serverCommand, fromToStruct)
		elseif QuestBattleType.UNION_PARTY == self.questBattleType then
			battleConstructor:InitDataByUnionParty(self.stageId, self.selectedTeamIdx, serverCommand, fromToStruct)
		else
			battleConstructor:InitByNormalStageIdAndTeamId(self.stageId, self.selectedTeamIdx, serverCommand, fromToStruct)
		end

		GuideUtils.DispatchStepEvent()
		AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)

	end
end
--[[
刷新剩余挑战次数
--]]
function SummerActivityReadyView:RefreshChallengeTime()
	if nil ~= self.challengeTimeLabel then
		local stageConf = CommonUtils.GetQuestConf(checkint(self.stageId))

		self.challengeTimeLabel:setString(string.format(
			'%d/%d',
			checkint(gameMgr:GetUserInfo().allQuestChallengeTimes[tostring(self.stageId)]),
			checkint(stageConf.challengeTime)
		))
	end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
转换激活的主角技数据结构
@params allSkill 所有激活的主角技数据
@return result table 转换后的数据结构
--]]
function SummerActivityReadyView:convertPlayerSkillData(allSkill)
	local skillId = 0
	local skillConf = nil

	local result = {
		activeSkill = {},
		passiveSkill = {}
	}

	for i,v in ipairs(allSkill) do
		skillId = checkint(v)
		skillConf = CommonUtils.GetSkillConf(skillId)
		local skillInfo = {skillId = skillId}
		if ConfigSkillType.SKILL_HALO == checkint(skillConf.property) then
			-- 被动技能
			table.insert(result.passiveSkill, skillInfo)
		else
			-- 主动技能
			table.insert(result.activeSkill, skillInfo)
		end
	end

	return result
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- cocos2dx begin --
---------------------------------------------------
function SummerActivityReadyView:onEnter()

end
function SummerActivityReadyView:onExit()

end
---------------------------------------------------
-- cocos2dx end --
---------------------------------------------------

---------------------------------------------------
-- debug raid begin --
---------------------------------------------------
function SummerActivityReadyView:InitRaidDebug()
	self.debug = {}
	self.debugData = {
		players = {},
		cards = {},
		cardCosted = {},
		captainId = 0,
		inputTeamId = 0,
		inputTeamIp = 0,
		inputTeamPort = 0
	}
	local size = self:getContentSize()
	local searchBtn = display.newButton(size.width * 0.75, size.height * 0.3, {n = 'ui/common/common_btn_orange.png',
		cb = function (sender)
			httpMgr:Post('QuestTeam/create', 'QuestTeam/create', {teamTypeId = 1, teamBossId = 4001, password = ''})
		end})
	display.commonLabelParams(searchBtn, {text = '创建', fontSize = 30, color = '#ffffff'})
	self:addChild(searchBtn, 9999)
	self.debug.searchBtn = searchBtn

	local cardBtn = display.newButton(size.width * 0.6, size.height * 0.3, {n = 'ui/common/common_btn_orange.png',
		cb = function (sender)
			local playerCardId = nil
			local cardId = nil
			for k,v in pairs(gameMgr:GetUserInfo().cards) do
				if not self.debugData.cardCosted[tostring(cardId)] then
					playerCardId = checkint(v.id)
					cardId = checkint(v.cardId)
					break
				end
			end
			-- 上卡
			local cardInfo = gameMgr:GetCardDataById(playerCardId)
			self.debugData.cards[tostring(gameMgr:GetUserInfo().playerId)] = {cardId = checkint(cardId), level = cardInfo.level, breakLevel = cardInfo.breakLevel, skill = cardInfo.skill}
			self.debugData.cardCosted[tostring(cardId)] = true

			local bsm = AppFacade.GetInstance():GetManager("BattleSocketManager")
			bsm:SendPacket(4003, {playerCardId = playerCardId, combatValue = 100})
		end})
	display.commonLabelParams(cardBtn, {text = '上卡', fontSize = 30, color = '#ffffff'})
	cardBtn:setVisible(false)
	self:addChild(cardBtn, 9999)
	self.debug.cardBtn = cardBtn

	local readyBtn = display.newButton(size.width * 0.45, size.height * 0.3, {n = 'ui/common/common_btn_orange.png',
		cb = function (sender)
			local bsm = AppFacade.GetInstance():GetManager("BattleSocketManager")
			bsm:SendPacket(4007, {ready = 1})
		end})
	display.commonLabelParams(readyBtn, {text = '准备', fontSize = 30, color = '#ffffff'})
	readyBtn:setVisible(false)
	self:addChild(readyBtn, 9999)
	self.debug.readyBtn = readyBtn

	local startBtn = display.newButton(size.width * 0.3, size.height * 0.3, {n = 'ui/common/common_btn_orange.png',
		cb = function (sender)
			local bsm = AppFacade.GetInstance():GetManager("BattleSocketManager")
			bsm:SendPacket(4009)
		end})
	display.commonLabelParams(startBtn, {text = '开始', fontSize = 30, color = '#ffffff'})
	startBtn:setVisible(false)
	self:addChild(startBtn, 9999)
	self.debug.startBtn = startBtn

	local joinBtn = display.newButton(size.width * 0.75, size.height * 0.4, {n = 'ui/common/common_btn_orange.png',
		cb = function (sender)
			local tid = self.debug.questTeamIdInput:getText()
			local tip = self.debug.questTeamIpInput:getText()
			local tport = self.debug.questTeamPortInput:getText()
			if string.len(string.gsub(tip, ' ', '')) == 0 then
				tip = 'push.duobaogame.com'
			end
			if string.len(string.gsub(tport, ' ', '')) == 0 then
				tport = '9623'
			end
			self.debugData.inputTeamId = tid
			self.debugData.inputTeamIp = tip
			self.debugData.inputTeamPort = tport

			local makedResponseData = {
				ip = self.debugData.inputTeamIp,
				port = self.debugData.inputTeamPort,
				questTeamId = self.debugData.inputTeamId,
				requestData = {
					password = '',
					teamBossId = 4001
				}
			}
			AppFacade.GetInstance():DispatchObservers('QuestTeam/create', makedResponseData)
		end
	})
	display.commonLabelParams(joinBtn, {text = '加入', fontSize = 30, color = '#ffffff'})
	self:addChild(joinBtn, 9999)
	self.debug.joinBtn = joinBtn

	local questTeamIdInput = ccui.EditBox:create(cc.size(150, 50), _res('ui/author/login_bg_Accounts_info.png'))
	display.commonUIParams(questTeamIdInput, {po = cc.p(size.width * 0.75, size.height * 0.5)})
	self:addChild(questTeamIdInput, 9999)
	questTeamIdInput:setFontSize(fontWithColor('M2PX').fontSize)
	questTeamIdInput:setFontColor(ccc3FromInt('#9f9f9f'))
	questTeamIdInput:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	questTeamIdInput:setPlaceHolder(summerActMgr:getThemeTextByText(__('房间id')))
	questTeamIdInput:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
	questTeamIdInput:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
	questTeamIdInput:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
	questTeamIdInput:setMaxLength(50)
	self.debug.questTeamIdInput = questTeamIdInput

	local questTeamIpInput = ccui.EditBox:create(cc.size(150, 50), _res('ui/author/login_bg_Accounts_info.png'))
	display.commonUIParams(questTeamIpInput, {po = cc.p(size.width * 0.6, size.height * 0.5)})
	self:addChild(questTeamIpInput, 9999)
	questTeamIpInput:setFontSize(fontWithColor('M2PX').fontSize)
	questTeamIpInput:setFontColor(ccc3FromInt('#9f9f9f'))
	questTeamIpInput:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	questTeamIpInput:setPlaceHolder(summerActMgr:getThemeTextByText(__('房间ip')))
	questTeamIpInput:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
	questTeamIpInput:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
	questTeamIpInput:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
	questTeamIpInput:setMaxLength(50)
	self.debug.questTeamIpInput = questTeamIpInput

	local questTeamPortInput = ccui.EditBox:create(cc.size(150, 50), _res('ui/author/login_bg_Accounts_info.png'))
	display.commonUIParams(questTeamPortInput, {po = cc.p(size.width * 0.45, size.height * 0.5)})
	self:addChild(questTeamPortInput, 9999)
	questTeamPortInput:setFontSize(fontWithColor('M2PX').fontSize)
	questTeamPortInput:setFontColor(ccc3FromInt('#9f9f9f'))
	questTeamPortInput:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	questTeamPortInput:setPlaceHolder(summerActMgr:getThemeTextByText(__('房间port')))
	questTeamPortInput:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
	questTeamPortInput:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
	questTeamPortInput:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
	questTeamPortInput:setMaxLength(50)
	self.debug.questTeamPortInput = questTeamPortInput

end

function SummerActivityReadyView:CraeteBossDescBtn()
	local questData = CommonUtils.GetQuestConf(self.stageId or 1) or {}
	local questType = questData.questType

	if checkint(questType) == 3 then
	
		local size = cc.size(100, 100)
		local layer = display.newLayer(display.SAFE_L + 460, display.height - 95, {size = size, color = cc.c4b(0,0,0,0), enable = true, cb = handler(self, self.BossDescrBtnCallback)})
		self:addChild(layer, 20)
	
		layer:addChild(display.newImageView(_res('ui/common/maps_boss_head_1.png'), size.width / 2, size.height / 2, {ap = display.CENTER}))
	
		local iconMonsterConf = CardUtils.GetCardConfig(questData.icon) or {}
		local icon = tostring(iconMonsterConf.drawId or questData.icon)
		local headIconPath = AssetsUtils.GetCardHeadPath(icon)
		local headIcon = display.newImageView(headIconPath, 0, 0)
	
		local clippingNode = cc.ClippingNode:create()
		clippingNode:setInverted(false)
		clippingNode:setPosition(utils.getLocalCenter(layer))
		layer:addChild(clippingNode)
		
		local drawnode = cc.DrawNode:create()
		local radius = size.width - 10
		drawnode:drawSolidCircle(cc.p(0,0),radius - 10,0,220,1.0,1.0,cc.c4f(0,0,0,1))
		clippingNode:setStencil(drawnode)
		clippingNode:addChild(headIcon)
		clippingNode:setScale(0.5)
	
		layer:addChild(display.newImageView(_res('ui/common/maps_boss_head_2.png'), size.width / 2, size.height / 2, {ap = display.CENTER}))
	
		local bossName = display.newButton(size.width / 2, 13, {ap = display.CENTER_TOP, n = _res('ui/common/maps_boss_name.png'), enable = false})
		display.commonLabelParams(bossName, fontWithColor(9, {text = summerActMgr:getThemeTextByText(__('BOSS详情')), paddingW = 20}))
		layer:addChild(bossName)
		
	end

end

function SummerActivityReadyView:CreateRecommendCards(parent, recommendCards)
	if parent:getChildrenCount() > 0 then parent:removeAllChildren() end

	local scale = 0.6
	local parentSize = parent:getContentSize()
	local count = table.nums(recommendCards)
	for i = 1, count do
		local cardId = checkint(recommendCards[i])
		if cardId > 0 then
			local node = self:CreateRecommendCard(cardId, scale)
			display.commonUIParams(node, {po = cc.p(80 + 130 * (i-1), parentSize.height / 2)})
			parent:addChild(node)
			-- table.insert(self.recommendCardNodes, node)
			self.recommendCardNodes[tostring(cardId)] = node
		end
	end
	
end

function SummerActivityReadyView:CreateRecommendCard(cardId, scale)
	local size = cc.size(120,120)
	local layer = display.newLayer(0, 0, {size = size, ap = display.CENTER})

	local cardNodeData = {cardData = {cardId = cardId}, showBaseState = true, showActionState = false, showRecommendState = true}
	local cardHeadNode = require('common.CardHeadNode').new(cardNodeData)
	display.commonUIParams(cardHeadNode, {po = cc.p(size.width / 2, size.height / 2), ap = display.CENTER})
	cardHeadNode:setScale(scale)
	layer:addChild(cardHeadNode)

	local recommendImg = display.newImageView(_res('ui/common/summer_activity_mvpxiangling_icon_unlock.png'), size.width - 22 , size.height - 20)
	layer:addChild(recommendImg, 20)

	local frameSpine = sp.SkeletonAnimation:create('effects/activity/biankuang.json', 'effects/activity/biankuang.atlas', 1)
	frameSpine:update(0)
	-- frameSpine:setScale(scale)
	-- frameSpine:setAnimation(0, 'idle', true)
	display.commonUIParams(frameSpine, {po = cc.p(size.width / 2, size.height / 2)})
	layer:addChild(frameSpine,10)
	frameSpine:setVisible(false)
	
	layer.viewData = {
		cardHeadNode = cardHeadNode,
		recommendImg = recommendImg,
		frameSpine = frameSpine,
	}
	return layer
end

function SummerActivityReadyView:RefreshRecommendCards(recommendCards)
	self.recommendCardNodes = {}
	self.recommendCards = recommendCards
	self:CreateRecommendCards(self.recommendCardLayer, recommendCards)
	self:RefreshRecommendCardsState()
end

function SummerActivityReadyView:RefreshRecommendCardsState()
	for cardId, node in pairs(self.recommendCardNodes) do
		local viewData = node.viewData
		local recommendImg = viewData.recommendImg
		local frameSpine = viewData.frameSpine
		local isRecommend = self.teamCardIds[tostring(cardId)]

		if isRecommend then
			recommendImg:setTexture(_res('ui/common/summer_activity_mvpxiangling_icon.png'))
			frameSpine:setVisible(true)
			frameSpine:setAnimation(0, 'idle', true)
		else
			recommendImg:setTexture(_res('ui/common/summer_activity_mvpxiangling_icon_unlock.png'))
			frameSpine:setVisible(false)
		end
	end
end

function SummerActivityReadyView:DebugEnter(randomseed)
	local members = {}
	-- 获取有序位置
	local t = sortByKey(self.debugData.players)
	local playerInfo = nil
	local cardInfo = nil
	for i,v in ipairs(t) do
		playerInfo = self.debugData.players[v]
		cardInfo = self.debugData.cards[tostring(playerInfo.playerId)]
		local cardData = clone(cardInfo)
		cardData.isLeader = checkint(playerInfo.playerId) == checkint(self.debugData.captainId)
		cardData.playerId = checkint(playerInfo.playerId)
		table.insert(members, cardData)
	end
	-- 我方激活的主角技
	local playerSkillInfo = {
		activeSkill = {},
		passiveSkill = {}
	}
	local friendFormationData = FormationStruct.New(
		1,
		members,
		playerSkillInfo
	)
	------------ 初始化战斗信息 ------------
	local startRaidBattleData = StartRaidBattleStruct.New(
		1,
		self.stageId,
		randomseed,
		self.debugData.cards,
		friendFormationData,
		checkint(self.debugData.captainId),
		checkint(self.debugData.captainId),
		self.fromMediatorName,
		self.toMediatorName
	)
	------------ 初始化战斗信息 ------------


	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = startRaidBattleData.fromMediatorName},
		{name = 'RaidBattleMediator', params = startRaidBattleData}
	)

end
---------------------------------------------------
-- debug raid end --
---------------------------------------------------

return SummerActivityReadyView
