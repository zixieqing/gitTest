local GameScene = require( 'Frame.GameScene' )
local DebugBattleScene = class('DebugBattleScene', GameScene)

------------ import ------------
__Require('battle.controller.BattleConstants')

local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local petMgr = AppFacade.GetInstance():GetManager("PetManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
------------ import ------------

------------ define ------------
local self__ = nil
-- 配表语言配置
local LANGUAGE_TAG = 'zh-cn'
local SRC_PATH = 'publish'

-- 资源路径
local BTN_N = _res('ui/common/common_btn_blue_default.png')
local COMMON_BG = _res('ui/common/common_roles_bg_name.png')
local MARK_ICON = _res('ui/common/common_hint_circle_red_ico.png')

-- 最大己方卡牌数
local MAX_TEAM_MEMBER = 5
-- 最大突破等级
local MAX_BREAK_LEVEL = 5
-- 宠物最大突破等级
local MAX_PET_BREAK_LEVEL = 10
-- 最大携带主动主角技数量
local MAX_ACTIVE_PLAYER_SKILL = 2

-- 编辑卡牌界面tag
local EDIT_CARD_DETAIL_TAG = 3421
-- 编辑宠物界面tag
local EDIT_PET_DETAIL_TAG = 3422
-- 选择宠物界面tag
local CHOOSE_PET_TAG = 3423
-- 友军tag
local FRIEND_TEAM_TAG = 1000
-- 敌军tag
local ENEMY_TEAM_TAG = 2000

-- 本地保存队伍信息的键
local LOCAL_TEAM_SAVE_DATA = 'ZF_LOCAL_TEAM_SAVE_DATA'
local LOCAL_TEAMS_SAVE_DATA = 'ZF_LOCAL_TEAMS_SAVE_DATA'

-- 关卡信息配置
local stageConfigInfo = {
	{low = 0, 		up = 3000, 	moduleName = 'quest', 				configName = 'quest', 				tips = '地图战斗', 		questBattleType = QuestBattleType.MAP},
	{low = 3000, 	up = 4000, 	moduleName = 'union', 				configName = 'godBeastQuest', 		tips = '神兽战', 		questBattleType = QuestBattleType.UNION_BEAST},
	{low = 4000, 	up = 5000, 	moduleName = 'quest', 				configName = 'teamBoss', 			tips = '组队战斗', 		questBattleType = QuestBattleType.RAID},
	{low = 5000, 	up = 6000, 	moduleName = 'material', 			configName = 'quest', 				tips = '材料本战斗', 		questBattleType = QuestBattleType.NORMAL_EVENT},
	{low = 6000, 	up = 7000, 	moduleName = 'restaurant', 			configName = 'quest', 				tips = '霸王餐战斗', 		questBattleType = QuestBattleType.LOBBY},
	{low = 7000, 	up = 7900, 	moduleName = 'summerActivity', 		configName = 'quest', 				tips = '季活战斗', 		questBattleType = QuestBattleType.NORMAL_EVENT},
	{low = 7900, 	up = 8000, 	moduleName = 'union', 				configName = 'partyQuest', 			tips = '工会派对战斗', 	questBattleType = QuestBattleType.UNION_PARTY},
	{low = 8000, 	up = 8999, 	moduleName = 'quest', 				configName = 'plotFightQuest', 		tips = '剧情任务战斗', 	questBattleType = QuestBattleType.PLOT},
	{low = 8998, 	up = 9000, 	moduleName = 'guide', 				configName = 'customizeQuest', 		tips = '自定义战斗', 		questBattleType = QuestBattleType.PERFORMANCE},
	{low = 9000, 	up = 20000, moduleName = 'explore', 			configName = 'exploreQuest', 		tips = '探索战斗', 		questBattleType = QuestBattleType.EXPLORE},
	{low = 20000, 	up = 30000, moduleName = 'worldBossQuest', 		configName = 'quest', 				tips = '世界boss', 		questBattleType = QuestBattleType.WORLD_BOSS},
	{low = 30000, 	up = 99999, moduleName = 'activityQuest', 		configName = 'quest', 				tips = '活动副本', 		questBattleType = QuestBattleType.ACTIVITY_QUEST},
}

-- 属性预览配置
local ObjPPreview = {
	{objp = ObjP.HP},
	{objp = ObjP.ATTACK},
	{objp = ObjP.DEFENCE},
	{objp = ObjP.CRITRATE},
	{objp = ObjP.CRITDAMAGE},
	{objp = ObjP.ATTACKRATE}
}

-- 属性信息配置
local ObjPConfig = {
	[ObjP.HP] = {pname = '生命'},
	[ObjP.ATTACK] = {pname = '攻击'},
	[ObjP.DEFENCE] = {pname = '防御'},
	[ObjP.CRITRATE] = {pname = '暴率'},
	[ObjP.CRITDAMAGE] = {pname = '爆伤'},
	[ObjP.ATTACKRATE] = {pname = '攻速'}
}

-- 宠物属性品质字体颜色
local PetPColor = {
	[PetPQuality.WHITE] 			= '#000000',
	[PetPQuality.GREEN] 			= '#00FF00',
	[PetPQuality.BLUE] 				= '#0000FF',
	[PetPQuality.PURPLE] 			= '#FF00FF',
	[PetPQuality.ORANGE] 			= '#FFA500'
}

local editCardPetCellSize = cc.size(475, 75)

local CardInfoStruct = {
	--[[
	@params cardId int 卡牌id
	--]]
	New = function (cardId)
		-- 初始化技能
		local skills = {}
		local cardConfig = self__:GetConfig('card', 'card', cardId)
		for i,v in ipairs(cardConfig.skill) do
			skills[tostring(v)] = {level = 1}
		end

		local t = {
			cardId = cardId,
			level = 1,
			breakLevel = 1,
			favorLevel = 1,
			skinId = CardUtils.GetCardSkinId(cardId),
			skills = skills,
			pets = {}
		}
		return t
	end
}

local PetInfoStruct = {
	--[[
	@params petId int 宠物id
	--]]
	New = function (petId)
		local t = {
			petId = petId,
			level = 1,
			breakLevel = 1,
			character = 1,
			petp = {
				{ptype = 1, pvalue = 1, pquality = 1, unlock = true},
				{ptype = 1, pvalue = 1, pquality = 1, unlock = false},
				{ptype = 1, pvalue = 1, pquality = 1, unlock = false},
				{ptype = 1, pvalue = 1, pquality = 1, unlock = false}
			},
			attr = {
				{type = 1, num = 1, quality = 1},
				{type = 1, num = 1, quality = 1},
				{type = 1, num = 1, quality = 1},
				{type = 1, num = 1, quality = 1}
			}
		}
		return t
	end
}

local TeamsSaveDataStruct = {
	New = function ()
		local t = {
			friendteams = {},
			defaultfriendteam = ''
		}
		return t
	end
}

local TeamSaveDataStruct = {
	New = function (teamName, teamData)
		local t = {
			teamName = teamName,
			teamData = clone(teamData),
			saveTime = os.time(),
			playerSkill = {
				active = {},
				passive = {}
			}
		}
		return t
	end
}

local TagMatchTeamsSaveDataStruct = {
	New = function (teamsName, teamsInfo)
		local t = {
			teams = {},
			teamsName = teamsName,
			saveTime = os.time()
		}
		for teamIndex, teamInfo in ipairs(teamsInfo) do
			local teamStruct = TeamSaveDataStruct.New(teamsName, teamInfo)
			teamStruct.saveTime = os.time()
			table.insert(t.teams, teamStruct)
		end

		return t
	end
}

local TagMatchAllTeamsSaveDataStruct = {
	New = function ()
		local t = {
			teams = {
				friend = {},
				enemy = {}
			},
			defaultTeamsName = {
				friend = '',
				enemy = ''
			}
		}
		return t
	end
}
------------ define ------------

--[[
constructor
--]]
function DebugBattleScene:ctor( ... )
	self__ = self

	self:InitConfigs()
	self:InitValue()
	self:InitScene()

	-- self:DebugRandom()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化配表数据
--]]
function DebugBattleScene:InitConfigs()
	self.configTables = {}
end
--[[
初始化数据
--]]
function DebugBattleScene:InitValue()
	self.currentEditCardInfo = nil
	self.currentEditCardPetNodes = {}
	self.currentEditPetInfo = nil
	self.currentFriendTeamData = {}
	self.currentFriendTeamName = nil
	self.currentPlayerSkill = {
		active = {},
		passive = {}
	}

	self.currentEditTeamsData = {
		friend = {},
		enemy = {}
	}

	self.currentEditTeamsName = {
		friend = nil,
		enemy = nil
	}

	-- 刷新当前编辑卡牌的回调函数
	self.refreshCurrentCardPPreview = nil
end
--[[
初始化关卡数据
--]]
function DebugBattleScene:InitStageConfig()
	for i,v in ipairs(stageConfigInfo) do
		-- 加载数据
		self:GetConfigTable(v.moduleName, v.configName)
	end
end
--[[
初始化场景
--]]
function DebugBattleScene:InitScene()
	self:setBackgroundColor(cc.c4b(0, 128, 128, 255))

	self.modelLayer = nil

	local modelLayer = display.newLayer(0, 0, {size = self:getContentSize()})
	display.commonUIParams(modelLayer, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(self)})
	self:addChild(modelLayer)
	self.modelLayer = modelLayer

	local debugModelInfo = {
		{name = '关卡模式', callback = function (sender)
			self:InitStageModel()
		end},
		{name = 'pvc模式', callback = function (sender)
			self:InitPVCModel()
		end}
	}

	for i,v in ipairs(debugModelInfo) do
		local btn = display.newButton(0, 0, {n = _res(BTN_N), cb = function (sender)
			v.callback(sender)
		end})

		local cellSize = cc.size(btn:getContentSize().width + 20, btn:getContentSize().height + 20)
		local btnPerLine = math.floor(display.SAFE_RECT.width / cellSize.width)

		display.commonUIParams(btn, {po = cc.p(
			((i - 1) % btnPerLine + 0.5) * cellSize.width,
			display.height - (math.ceil(i / btnPerLine) - 0.5) * cellSize.height
		)})
		local btnLabel = self:GetANewLabel(
			{text = v.name},
			{po = utils.getLocalCenter(btn)},
			btn
		)
		modelLayer:addChild(btn)
	end
end
--[[
初始化默认加载的队伍
--]]
function DebugBattleScene:InitDefaultLoadTeam()
	local teamName = self:GetDefaultLoadTeam()
	if nil ~= teamName and 0 < string.len(teamName) then
		self:LoadFriendTeamByTeamName(teamName)
	end
end
--[[
/***********************************************************************************************************************************\
 * 关卡模式
\***********************************************************************************************************************************/
--]]
--[[
初始化关卡模式
--]]
function DebugBattleScene:InitStageModel()
	self.modelLayer:setVisible(false)
	self:InitCustomizeLayer()
	-- 初始化默认加载的队伍
	self:InitDefaultLoadTeam()
end
--[[
初始化卡牌组装界面
--]]
function DebugBattleScene:InitCustomizeLayer()
	local layerSize = self:getContentSize()

	------------ m ------------
	self.customizeCardLayers = {}
	self.customizeCardDetailLayers = {}
	self.teamNameLabel = nil
	self.startBattleWaringLabel = nil
	self.totalBattlePointLabel = totalBattlePointLabel
	self.activePlayerSkillNodes = {}
	self.inputStageId = ''

	self.stageIdInputBox = nil
	self.stageDetailLabel = nil
	self.stageDetailBtn = nil
	self.enemyDetailBtn = nil
	------------ m ------------

	local layer = display.newLayer(0, 0, {size = layerSize})
	display.commonUIParams(layer, {po = cc.p(0, 0)})
	-- layer:setBackgroundColor(cc.c4b(255, 25, 25, 100))
	self:addChild(layer)

	local titleLabel = self:GetANewLabel(
		{text = '配置己方卡牌'},
		{ap = cc.p(0, 0.5), po = cc.p(25, layerSize.height - 35)},
		layer,
		100, 200
	)

	local totalBattlePointLabel = self:GetANewLabel(
		{text = '0'},
		{ap = cc.p(0, 0.5), po = cc.p(titleLabel:getPositionX(), titleLabel:getPositionY() - 30)},
		layer
	)
	self.totalBattlePointLabel = totalBattlePointLabel

	local customizeCardLayerSize = cc.size(225, 150)
	local cardPerLine = 5
	for i = 1, MAX_TEAM_MEMBER do
		local customizeCardLayerBtn = display.newLayer(0, 0, {size = customizeCardLayerSize})
		display.commonUIParams(customizeCardLayerBtn, {ap = cc.p(0.5, 1), po = cc.p(
			(customizeCardLayerSize.width + 20) * ((i - 1) % cardPerLine + 1 - 0.5),
			titleLabel:getPositionY() - 55 - (customizeCardLayerSize.height + 20) * (math.ceil(i / (cardPerLine) - 1))
		)})
		titleLabel:getParent():addChild(customizeCardLayerBtn)
		customizeCardLayerBtn:setTag(i)

		local btn = display.newButton(0, 0, {size = customizeCardLayerSize, cb = handler(self, self.EditCardBtnClickHandler)})
		display.commonUIParams(btn, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(customizeCardLayerBtn)})
		customizeCardLayerBtn:addChild(btn, 99)
		-- display.commonUIParams(btn, {ap = cc.p(0.5, 0.5), po = cc.p(customizeCardLayerBtn:getPositionX(), customizeCardLayerBtn:getPositionY())})
		-- layer:addChild(btn)
		btn:setTag(3)

		local bgImg = display.newImageView(COMMON_BG, 0, 0, {scale9 = true, size = cc.size(customizeCardLayerSize.width + 5, customizeCardLayerSize.height + 5)})
		display.commonUIParams(bgImg, {po = utils.getLocalCenter(customizeCardLayerBtn)})
		customizeCardLayerBtn:addChild(bgImg)

		local noLabel = self:GetANewLabel(
			{text = tostring(i)},
			{ap = cc.p(0, 1), po = cc.p(0, customizeCardLayerSize.height)},
			customizeCardLayerBtn
		)

		self.customizeCardLayers[i] = customizeCardLayerBtn
	end

	-- 保存配置按钮
	local saveTeamBtn = display.newButton(0, 0, {n = BTN_N, cb = handler(self, self.SaveTeamBtnClickHandler)})
	display.commonUIParams(saveTeamBtn, {po = cc.p(
		titleLabel:getPositionX() + 250,
		titleLabel:getPositionY()
	)})
	titleLabel:getParent():addChild(saveTeamBtn)
	local saveTeamBtnLabel = self:GetANewLabel(
		{text = '保存配置'},
		{po = utils.getLocalCenter(saveTeamBtn)},
		saveTeamBtn
	)

	-- 读取配置按钮
	local loadTeamBtn = display.newButton(0, 0, {n = BTN_N, cb = handler(self, self.LoadLocalFriendTeam)})
	display.commonUIParams(loadTeamBtn, {po = cc.p(
		saveTeamBtn:getPositionX() + saveTeamBtn:getContentSize().width + 20,
		saveTeamBtn:getPositionY()
	)})
	titleLabel:getParent():addChild(loadTeamBtn)
	local loadTeamBtnLabel = self:GetANewLabel(
		{text = '读取配置'},
		{po = utils.getLocalCenter(loadTeamBtn)},
		loadTeamBtn
	)

	-- 队伍名称
	local teamNameLabel = self:GetANewLabel(
		{text = self.currentFriendTeamName or ''},
		{ap = cc.p(0, 0.5), po = cc.p(loadTeamBtn:getPositionX() + loadTeamBtn:getContentSize().width * 0.5 + 10, loadTeamBtn:getPositionY())},
		titleLabel:getParent()
	)
	self.teamNameLabel = teamNameLabel

	-- 选择关卡
	local inputStageTitleLabel = self:GetANewLabel(
		{text = '选择关卡 输入关卡id'},
		{ap = cc.p(0, 0.5), po = cc.p(titleLabel:getPositionX(), self.customizeCardLayers[#self.customizeCardLayers]:getPositionY() - customizeCardLayerSize.height - 50)},
		layer
	)

	local stageIdInputBox = self:GetANewInputBox()
	self.stageIdInputBox = stageIdInputBox
	display.commonUIParams(stageIdInputBox, {ap = cc.p(0, 0.5), po = cc.p(
		inputStageTitleLabel:getPositionX() + display.getLabelContentSize(inputStageTitleLabel).width + 20,
		inputStageTitleLabel:getPositionY()
	)})
	inputStageTitleLabel:getParent():addChild(stageIdInputBox)
	stageIdInputBox:registerScriptEditBoxHandler(handler(self, self.StageIdInputBoxInputCompleteHandler))

	-- 关卡简介
	local stageDetailLabel = self:GetANewLabel(
		{text = '测试'},
		{ap = cc.p(0, 0.5), po = cc.p(stageIdInputBox:getPositionX() + stageIdInputBox:getContentSize().width + 20, stageIdInputBox:getPositionY())},
		inputStageTitleLabel:getParent()
	)
	self.stageDetailLabel = stageDetailLabel
	self.stageDetailLabel:setVisible(false)

	local stageDetailBtn = display.newButton(0, 0, {n = BTN_N, cb = handler(self, self.StageDetailBtnClickHandler)})
	self.stageDetailBtn = stageDetailBtn
	display.commonUIParams(self.stageDetailBtn, {po = cc.p(
		self.stageDetailLabel:getPositionX() + display.getLabelContentSize(self.stageDetailLabel).width + 10 + self.stageDetailBtn:getContentSize().width * 0.5,
		self.stageDetailLabel:getPositionY()
	)})
	self.stageDetailLabel:getParent():addChild(self.stageDetailBtn)
	self.stageDetailBtn:setVisible(false)

	local stageDetailBtnLabel = self:GetANewLabel(
		{text = '关卡数据'},
		{po = utils.getLocalCenter(self.stageDetailBtn)},
		self.stageDetailBtn
	)

	local enemyDetailBtn = display.newButton(0, 0, {n = BTN_N, cb = handler(self, self.EnemyDetailBtnClickHandler)})
	self.enemyDetailBtn = enemyDetailBtn
	display.commonUIParams(self.enemyDetailBtn, {po = cc.p(
		self.stageDetailBtn:getPositionX() + self.enemyDetailBtn:getContentSize().width + 10,
		self.stageDetailBtn:getPositionY()
	)})
	self.stageDetailLabel:getParent():addChild(self.enemyDetailBtn)
	self.enemyDetailBtn:setVisible(false)

	local enemyDetailBtnLabel = self:GetANewLabel(
		{text = '阵容数据'},
		{po = utils.getLocalCenter(self.enemyDetailBtn)},
		self.enemyDetailBtn
	)

	-- 选择主角技
	local activePlayerSkillNodes = {}
	for i = 1, MAX_ACTIVE_PLAYER_SKILL do
		local skillId = self.currentPlayerSkill.active[tostring(i)]
		local skillConfig = self:GetConfig('player', 'skill', skillId)

		local playerSkillNode = require('common.SkillNode').new({id = skillId})
		display.commonUIParams(playerSkillNode, {po = cc.p(
			50 + playerSkillNode:getContentSize().width * 0.5 + (playerSkillNode:getContentSize().width + 5) * (i - 1),
			20 + playerSkillNode:getContentSize().height * 0.5
		)})
		layer:addChild(playerSkillNode)

		local playerSkillBtn = display.newButton(0, 0, {size = playerSkillNode:getContentSize(), cb = function (sender)
			local index = sender:getTag()
			self:ShowChooseActivePlayerSkill(index)
		end})
		display.commonUIParams(playerSkillBtn, {ap = playerSkillNode:getAnchorPoint(), po = cc.p(
			playerSkillNode:getPositionX(),
			playerSkillNode:getPositionY()
		)})
		playerSkillNode:getParent():addChild(playerSkillBtn)
		playerSkillBtn:setTag(i)

		local nameLabel = self:GetANewLabel(
			{text = skillConfig and skillConfig.name or '未装备'},
			{ap = cc.p(0.5, 0), po = cc.p(playerSkillNode:getPositionX(), playerSkillNode:getPositionY() + playerSkillNode:getContentSize().height * 0.5 + 10)},
			playerSkillNode:getParent()
		)

		local labelBtn = display.newButton(0, 0, {size = display.getLabelContentSize(nameLabel), cb = function (sender)
			local index = sender:getTag()
			local skillId = self.currentPlayerSkill.active[tostring(i)]
			if skillId then
				local skillConfig = self:GetConfig('player', 'skill', skillId)
				if skillConfig then
					uiMgr:ShowInformationTipsBoard({
						targetNode = sender,
						title = skillConfig.name,
						deloscr = skillConfig.descr,
						type = 5
					})
				end
			end
		end})
		display.commonUIParams(labelBtn, {ap = nameLabel:getAnchorPoint(), po = cc.p(
			nameLabel:getPositionX(),
			nameLabel:getPositionY()
		)})
		nameLabel:getParent():addChild(labelBtn, 99)
		labelBtn:setTag(i)

		activePlayerSkillNodes[i] = {
			playerSkillNode = playerSkillNode,
			nameLabel = nameLabel
		}
	end
	self.activePlayerSkillNodes = activePlayerSkillNodes

	-- 战斗按钮
	local battleBtn = require('common.CommonBattleButton').new({
		pattern = 1,
		clickCallback = handler(self, self.BattleBtnClickHandler)
	})
	display.commonUIParams(battleBtn, {po = cc.p(layerSize.width - 20 - battleBtn:getContentSize().width * 0.5, battleBtn:getContentSize().height * 0.5 + 20)})
	layer:addChild(battleBtn)

	local startBattleWaringLabel = self:GetANewLabel(
		{text = '', fontSize = 18, color = '#aa1122', notTTF = true},
		{po = cc.p(battleBtn:getPositionX(), battleBtn:getPositionY() + battleBtn:getContentSize().height * 0.5 + 20)},
		battleBtn:getParent()
	)
	startBattleWaringLabel:setVisible(false)
	self.startBattleWaringLabel = startBattleWaringLabel

end
--[[
/***********************************************************************************************************************************\
 * pvc模式
\***********************************************************************************************************************************/
--]]
--[[
初始化pvc模式
--]]
function DebugBattleScene:InitPVCModel()
	self.modelLayer:setVisible(false)
	self:InitPVCCustomizeLayer()

	-- 默认加载一次出事阵容
	self:LoadDefaultTeams()
end
--[[
加载一次初始阵容
--]]
function DebugBattleScene:LoadDefaultTeams()
	-- friend
	local defaultFriendTeamsName = self:GetDefaultLoadTeamsName(false)
	local teamsInfo = self:GetLocalTeamsSaveDataByTeamsName(false, defaultFriendTeamsName)
	if nil ~= teamsInfo then
		self:LoadTeamsByTeamName(false, defaultFriendTeamsName)
	end

	-- enemy
	local defaultEnemyTeamsName = self:GetDefaultLoadTeamsName(true)
	local teamsInfo = self:GetLocalTeamsSaveDataByTeamsName(true, defaultEnemyTeamsName)
	if nil ~= teamsInfo then
		self:LoadTeamsByTeamName(true, defaultEnemyTeamsName)
	end
end
--[[
初始化卡牌组装界面
--]]
function DebugBattleScene:InitPVCCustomizeLayer()
	local layerSize = self:getContentSize()

	------------ m ------------
	self.pvcScrollView = nil
	------------ m ------------

	local layer = display.newLayer(0, 0, {size = layerSize})
	display.commonUIParams(layer, {po = cc.p(0, 0)})
	-- layer:setBackgroundColor(cc.c4b(255, 25, 25, 100))
	self:addChild(layer)

	-- 初始化两屏的滑动页
	local scrollView = CScrollView:create(display.size)
	scrollView:setDirection(eScrollViewDirectionHorizontal)
	scrollView:setAnchorPoint(cc.p(0.5, 0.5))
	scrollView:setPosition(display.center)
	scrollView:setContainerSize(cc.size(layerSize.width * 2, layerSize.height))
	layer:addChild(scrollView)

	self.pvcScrollView = scrollView

	-- 战斗按钮
	local battleBtn = require('common.CommonBattleButton').new({
		pattern = 1,
		clickCallback = handler(self, self.BattleBtnClickHandler)
	})
	display.commonUIParams(battleBtn, {po = cc.p(layerSize.width - 20 - battleBtn:getContentSize().width * 0.5, battleBtn:getContentSize().height * 0.5 + 20)})
	layer:addChild(battleBtn)

	battleBtn:setTag(QuestBattleType.TAG_MATCH_3V3)

	local startBattleWaringLabel = self:GetANewLabel(
		{text = '', fontSize = 18, color = '#aa1122', notTTF = true},
		{po = cc.p(battleBtn:getPositionX(), battleBtn:getPositionY() + battleBtn:getContentSize().height * 0.5 + 20)},
		battleBtn:getParent()
	)
	startBattleWaringLabel:setVisible(false)
	self.startBattleWaringLabel = startBattleWaringLabel

	-- 初始化编辑本队卡牌界面
	self:InitPVCEditFriendTeamLayer()
	-- 初始化编辑敌队卡牌界面
	self:InitPVCEditEnemyTeamLayer()
end
--[[
初始化编辑己方卡牌界面
--]]
function DebugBattleScene:InitPVCEditFriendTeamLayer()
	local parentNode = self.pvcScrollView
	local layerSize = self:getContentSize()

	------------ m ------------
	self.friendTeamLayer = nil
	self.friendTitleLabel = nil
	self.friendAddTeamBtn = nil
	self.friendTotalBattlePointLabel = nil
	self.friendTeamNameLabel = nil
	self.friendTeamsNodes = {}
	------------ m ------------

	local layer = display.newLayer(0, 0, {size = layerSize})
	display.commonUIParams(layer, {po = cc.p(0, 0)})
	layer:setBackgroundColor(cc.c4b(255, 25, 25, 100))
	parentNode:getContainer():addChild(layer)
	layer:setTag(FRIEND_TEAM_TAG)
	self.friendTeamLayer = layer

	local titleLabel = self:GetANewLabel(
		{text = '配置己方卡牌'},
		{ap = cc.p(0, 0.5), po = cc.p(25, layerSize.height - 35)},
		layer,
		100, 200
	)
	titleLabel:setTag(3)
	self.friendTitleLabel = titleLabel

	local totalBattlePointLabel = self:GetANewLabel(
		{text = '0'},
		{ap = cc.p(0, 0.5), po = cc.p(titleLabel:getPositionX(), titleLabel:getPositionY() - 40)},
		layer
	)
	self.friendTotalBattlePointLabel = totalBattlePointLabel

	-- 保存配置按钮
	local saveTeamBtn = display.newButton(0, 0, {n = BTN_N, cb = handler(self, self.SaveTeamsBtnClickHandler)})
	display.commonUIParams(saveTeamBtn, {po = cc.p(
		titleLabel:getPositionX() + 250,
		titleLabel:getPositionY()
	)})
	titleLabel:getParent():addChild(saveTeamBtn)
	local saveTeamBtnLabel = self:GetANewLabel(
		{text = '保存配置'},
		{po = utils.getLocalCenter(saveTeamBtn)},
		saveTeamBtn
	)

	-- 读取配置按钮
	local loadTeamBtn = display.newButton(0, 0, {n = BTN_N, cb = handler(self, self.LoadTeamsBtnClickHandler)})
	display.commonUIParams(loadTeamBtn, {po = cc.p(
		saveTeamBtn:getPositionX() + saveTeamBtn:getContentSize().width + 20,
		saveTeamBtn:getPositionY()
	)})
	titleLabel:getParent():addChild(loadTeamBtn)
	local loadTeamBtnLabel = self:GetANewLabel(
		{text = '读取配置'},
		{po = utils.getLocalCenter(loadTeamBtn)},
		loadTeamBtn
	)

	-- 队伍名称
	local teamNameLabel = self:GetANewLabel(
		{text = self.currentFriendTeamName or ''},
		{ap = cc.p(0, 0.5), po = cc.p(loadTeamBtn:getPositionX() + loadTeamBtn:getContentSize().width * 0.5 + 10, loadTeamBtn:getPositionY())},
		titleLabel:getParent()
	)
	self.friendTeamNameLabel = teamNameLabel

	-- 增队伍按钮
	local addTeamBtn = display.newButton(0, 0, {n = BTN_N, cb = handler(self, self.AddTeamBtnClickHandler)})
	display.commonUIParams(addTeamBtn, {po = cc.p(
		20 + addTeamBtn:getContentSize().width * 0.5,
		self.friendTitleLabel:getPositionY() - 55 - addTeamBtn:getContentSize().height * 0.5 - (170 * #self.friendTeamsNodes)
	)})
	addTeamBtn:setTag(FRIEND_TEAM_TAG)
	self.friendAddTeamBtn = addTeamBtn
	titleLabel:getParent():addChild(addTeamBtn)
	local saveTeamBtnLabel = self:GetANewLabel(
		{text = '增加队伍'},
		{po = utils.getLocalCenter(addTeamBtn)},
		addTeamBtn
	)
end
--[[
初始化编辑敌方卡牌界面
--]]
function DebugBattleScene:InitPVCEditEnemyTeamLayer()
	local parentNode = self.pvcScrollView
	local layerSize = self:getContentSize()

	------------ m ------------
	self.enemyTeamLayer = nil
	self.enemyTitleLabel = nil
	self.enemyAddTeamBtn = nil
	self.enemyTotalBattlePointLabel = nil
	self.enemyTeamNameLabel = nil
	self.enemyTeamsNodes = {}
	------------ m ------------

	local layer = display.newLayer(0, 0, {size = layerSize})
	display.commonUIParams(layer, {po = cc.p(layerSize.width, 0)})
	layer:setBackgroundColor(cc.c4b(25, 255, 25, 100))
	parentNode:getContainer():addChild(layer)
	layer:setTag(ENEMY_TEAM_TAG)
	self.enemyTeamLayer = layer

	local titleLabel = self:GetANewLabel(
		{text = '配置敌方卡牌'},
		{ap = cc.p(0, 0.5), po = cc.p(25, layerSize.height - 35)},
		layer,
		100, 200
	)
	self.enemyTitleLabel = titleLabel

	local totalBattlePointLabel = self:GetANewLabel(
		{text = '0'},
		{ap = cc.p(0, 0.5), po = cc.p(titleLabel:getPositionX(), titleLabel:getPositionY() - 40)},
		layer
	)
	self.enemyTotalBattlePointLabel = totalBattlePointLabel

	-- 保存配置按钮
	local saveTeamBtn = display.newButton(0, 0, {n = BTN_N, cb = handler(self, self.SaveTeamsBtnClickHandler)})
	display.commonUIParams(saveTeamBtn, {po = cc.p(
		titleLabel:getPositionX() + 250,
		titleLabel:getPositionY()
	)})
	titleLabel:getParent():addChild(saveTeamBtn)
	local saveTeamBtnLabel = self:GetANewLabel(
		{text = '保存配置'},
		{po = utils.getLocalCenter(saveTeamBtn)},
		saveTeamBtn
	)

	-- 读取配置按钮
	local loadTeamBtn = display.newButton(0, 0, {n = BTN_N, cb = handler(self, self.LoadTeamsBtnClickHandler)})
	display.commonUIParams(loadTeamBtn, {po = cc.p(
		saveTeamBtn:getPositionX() + saveTeamBtn:getContentSize().width + 20,
		saveTeamBtn:getPositionY()
	)})
	titleLabel:getParent():addChild(loadTeamBtn)
	local loadTeamBtnLabel = self:GetANewLabel(
		{text = '读取配置'},
		{po = utils.getLocalCenter(loadTeamBtn)},
		loadTeamBtn
	)

	-- 队伍名称
	local teamNameLabel = self:GetANewLabel(
		{text = self.currentFriendTeamName or ''},
		{ap = cc.p(0, 0.5), po = cc.p(loadTeamBtn:getPositionX() + loadTeamBtn:getContentSize().width * 0.5 + 10, loadTeamBtn:getPositionY())},
		titleLabel:getParent()
	)
	self.enemyTeamNameLabel = teamNameLabel

	-- 增减队伍按钮
	local addTeamBtn = display.newButton(0, 0, {n = BTN_N, cb = handler(self, self.AddTeamBtnClickHandler)})
	display.commonUIParams(addTeamBtn, {po = cc.p(
		20 + addTeamBtn:getContentSize().width * 0.5,
		self.enemyTitleLabel:getPositionY() - 55 - addTeamBtn:getContentSize().height * 0.5 - (170 * #self.enemyTeamsNodes)
	)})
	addTeamBtn:setTag(ENEMY_TEAM_TAG)
	self.enemyAddTeamBtn = addTeamBtn
	titleLabel:getParent():addChild(addTeamBtn)
	local saveTeamBtnLabel = self:GetANewLabel(
		{text = '增加队伍'},
		{po = utils.getLocalCenter(addTeamBtn)},
		addTeamBtn
	)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
输入框回调事件
@params eventType 事件类型
--]]
function DebugBattleScene:StageIdInputBoxInputCompleteHandler(eventType)
	if 'return' == eventType then
		self.inputStageId = checkint(string.gsub(self.stageIdInputBox:getText(), ' ', ''))
		print('here input the stage <<<<<<<<<<<<, id :', self.inputStageId)
		self:RefreshStagePreviewUI(self.inputStageId)
	end
end
--[[
关卡详细按钮回调
--]]
function DebugBattleScene:StageDetailBtnClickHandler(sender)
	local stageId = checkint(self.inputStageId)
	local stageConfig = self:GetStageConfigByStageId(stageId)
	local text = tableToString(stageConfig)
	self:ShowATextScrollView(text)
end
--[[
阵容详细按钮回调
--]]
function DebugBattleScene:EnemyDetailBtnClickHandler(sender)
	local stageId = checkint(self.inputStageId)
	local enemyConfig = self:GetConfig('quest', 'enemy', stageId)
	local text = tableToString(enemyConfig)
	self:ShowATextScrollView(text)
end
--[[
编辑卡牌按钮信息回调
--]]
function DebugBattleScene:EditCardBtnClickHandler(sender)
	local teamIdx = sender:getParent():getTag()
	local cardInfo = self.currentFriendTeamData[tostring(teamIdx)]
	self:ShowEditCardView(teamIdx, cardInfo)
end
--[[
编辑队伍卡牌按钮信息回调
--]]
function DebugBattleScene:EditTeamCardBtnClickHandler(sender)
	local isEnemy = ENEMY_TEAM_TAG == sender:getParent():getParent():getParent():getTag()
	local teamIndex = sender:getParent():getParent():getTag()
	local cardIndex = sender:getParent():getTag()
	local cardInfo = self:GetTeamCardInfo(isEnemy, teamIndex, cardIndex)
	self:ShowEditTeamCardView(isEnemy, teamIndex, cardIndex, cardInfo)
end
--[[
保存编队信息按钮回调
--]]
function DebugBattleScene:SaveTeamBtnClickHandler(sender)
	self:SaveCurrentFriendTeam()
end
--[[
保存当前的友军信息
--]]
function DebugBattleScene:SaveCurrentFriendTeam()
	-- 名字弹窗
	local node = self:GetANewPopLayer()
	local bgNode = node:getChildByTag(3)
	local bgNodePos = cc.p(bgNode:getPositionX(), bgNode:getPositionY())
	local bgNodeSize = bgNode:getContentSize()

	local teamnametitleNode, teamnameinputNode = self:GetATitleAndInputBox(
		'输入名称',
		{po = cc.p(bgNodePos.x - 55, bgNodePos.y + 100)},
		node
	)
	if nil ~= self.currentFriendTeamName then
		teamnameinputNode:setText(tostring(self.currentFriendTeamName))
	end
	local waringLabel = self:GetANewLabel(
		{text = '', fontSize = 18, color = '#aa1122', notTTF = true},
		{ap = cc.p(0.5, 0), po = cc.p(teamnameinputNode:getPositionX(), teamnameinputNode:getPositionY() + teamnameinputNode:getContentSize().height * 0.5)},
		node
	)
	waringLabel:setVisible(false)

	teamnameinputNode:registerScriptEditBoxHandler(function (eventType)
		if 'return' == eventType then
			local friendteams = self:GetLocalFriendTeamSaveData()
			local inputText = tostring(teamnameinputNode:getText())

			if nil ~= friendteams[inputText] then
				waringLabel:setVisible(true)
				waringLabel:setString('队伍已存在 保存将覆盖原配置')
			else
				waringLabel:setVisible(false)
			end

			self.currentFriendTeamName = inputText
		end
	end)

	-- 保存按钮
	local saveBtn = display.newButton(0, 0, {n = BTN_N, cb = function (sender)
		self:RemoveANode(node)
		self:SaveCurrentFriendTeamToLocal()
		self.teamNameLabel:setString(self.currentFriendTeamName .. ' 下次自动读取 -> ' .. self:GetDefaultLoadTeam())
	end})
	display.commonUIParams(saveBtn, {po = cc.p(bgNodePos.x, bgNodePos.y - 50)})
	node:addChild(saveBtn)
	local saveBtnLabel = self:GetANewLabel(
		{text = '保存'},
		{po = utils.getLocalCenter(saveBtn)},
		saveBtn
	)
end
--[[
读取本地的友军配置
--]]
function DebugBattleScene:LoadLocalFriendTeam()
	local loaclteamdata = self:GetSortLocalFriendTeamSaveData()

	local node = self:GetANewPopLayer()
	local bgNode = node:getChildByTag(3)
	local bgNodePos = cc.p(bgNode:getPositionX(), bgNode:getPositionY())
	local bgNodeSize = bgNode:getContentSize()

	local listViewSize = cc.size(bgNodeSize.width - 10, bgNodeSize.height - 10)
	local cellSize = cc.size(listViewSize.width, 100)

	local listView = CTableView:create(listViewSize)
	display.commonUIParams(listView, {ap = cc.p(0.5, 0.5), po = bgNodePos})
	node:addChild(listView)

	listView:setSizeOfCell(cellSize)
	listView:setCountOfCell(#loaclteamdata)
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setDataSourceAdapterScriptHandler(function (c, i)
		local cell = c
		local index = i + 1
		local loaclteamdata_ = self:GetSortLocalFriendTeamSaveData()
		local teamData_ = self:GetSortLocalFriendTeamSaveData()[index]

		local teamNameLabel = nil

		if nil == cell then
			cell = CTableViewCell:new()
			cell:setContentSize(cellSize)
			cell:setBackgroundColor(cc.c4b(math.random(255), math.random(255), math.random(255), 128))

			teamNameLabel = self:GetANewLabel(
				{text = teamData_.teamName},
				{ap = cc.p(0, 0.5), po = cc.p(10, cellSize.height * 0.5)},
				cell
			)
			teamNameLabel:setTag(3)

			-- 读取配置按钮
			local loadTeamBtn = display.newButton(0, 0, {n = BTN_N, cb = function (sender)
				local teamIdx = sender:getParent():getTag()
				local teamName = self:GetSortLocalFriendTeamSaveData()[teamIdx].teamName

				-- 记录一次默认读取的队伍
				self:SaveDefaultLoadTeam(teamName)

				self:LoadFriendTeamByTeamName(teamName)
				self:RemoveANode(node)
			end})
			display.commonUIParams(loadTeamBtn, {po = cc.p(
				cellSize.width - 20 - loadTeamBtn:getContentSize().width * 0.5,
				cellSize.height * 0.5
			)})
			cell:addChild(loadTeamBtn)
			local loadTeamBtnLabel = self:GetANewLabel(
				{text = '读取配置'},
				{po = utils.getLocalCenter(loadTeamBtn)},
				loadTeamBtn
			)

			local delTeamBtn = display.newButton(0, 0, {n = BTN_N, cb = function (sender)
				local teamIdx = sender:getParent():getTag()
				local teamName = self:GetSortLocalFriendTeamSaveData()[teamIdx].teamName
				self:DeleteFriendTeamByTeamName(teamName)
				self:RemoveANode(node)
				listView:setCountOfCell(#self:GetSortLocalFriendTeamSaveData())
				listView:reloadData()
			end})
			display.commonUIParams(delTeamBtn, {po = cc.p(
				loadTeamBtn:getPositionX() - loadTeamBtn:getContentSize().width - 10,
				loadTeamBtn:getPositionY()
			)})
			cell:addChild(delTeamBtn)
			local delTeamBtnLabel = self:GetANewLabel(
				{text = '删除配置'},
				{po = utils.getLocalCenter(delTeamBtn)},
				delTeamBtn
			)
		else
			teamNameLabel = cell:getChildByTag(3)
		end

		teamNameLabel:setString(tostring(teamData_.teamName))
		cell:setTag(index)

		return cell
	end)

	listView:reloadData()
end
--[[
保存队伍信息按钮回调
--]]
function DebugBattleScene:SaveTeamsBtnClickHandler(sender)
	local isEnemy = ENEMY_TEAM_TAG == sender:getParent():getTag()

	local teamsNameLabel = nil
	local teamsName = nil

	if isEnemy then
		teamsNameLabel = self.enemyTeamNameLabel
		teamsName = self.currentEditTeamsName.enemy
	else
		teamsNameLabel = self.friendTeamNameLabel
		teamsName = self.currentEditTeamsName.friend
	end

	-- 名字弹窗
	local node = self:GetANewPopLayer()
	local bgNode = node:getChildByTag(3)
	local bgNodePos = cc.p(bgNode:getPositionX(), bgNode:getPositionY())
	local bgNodeSize = bgNode:getContentSize()

	local teamnametitleNode, teamnameinputNode = self:GetATitleAndInputBox(
		'输入名称',
		{po = cc.p(bgNodePos.x - 55, bgNodePos.y + 100)},
		node
	)

	if nil ~= teamsName then
		teamnameinputNode:setText(tostring(teamsName))
	end
	local waringLabel = self:GetANewLabel(
		{text = '', fontSize = 18, color = '#aa1122', notTTF = true},
		{ap = cc.p(0.5, 0), po = cc.p(teamnameinputNode:getPositionX(), teamnameinputNode:getPositionY() + teamnameinputNode:getContentSize().height * 0.5)},
		node
	)
	waringLabel:setVisible(false)

	teamnameinputNode:registerScriptEditBoxHandler(function (eventType)
		if 'return' == eventType then

			local inputText = tostring(teamnameinputNode:getText())
			local teamsData = self:GetLocalTeamsSaveDataByTeamsName(isEnemy, inputText)

			if nil ~= teamsData then
				waringLabel:setVisible(true)
				waringLabel:setString('队伍已存在 保存将覆盖原配置')
			else
				waringLabel:setVisible(false)
			end

			if isEnemy then
				self.currentEditTeamsName.enemy = tostring(teamnameinputNode:getText())
			else
				self.currentEditTeamsName.friend = tostring(teamnameinputNode:getText())
			end
		end
	end)

	-- 保存按钮
	local saveBtn = display.newButton(0, 0, {n = BTN_N, cb = function (sender)
		local teamsAmount = 0
		if isEnemy then
			teamsAmount = #self.currentEditTeamsData.enemy
		else
			teamsAmount = #self.currentEditTeamsData.friend
		end
		if 0 >= teamsAmount then
			waringLabel:setString('必须添加一队')
			waringLabel:setVisible(true)
			return
		else
			waringLabel:setVisible(false)
		end

		self:RemoveANode(node)
		self:SaveTeamsToLocal(isEnemy)

		if isEnemy then
			self.enemyTeamNameLabel:setString(self.currentEditTeamsName.enemy)
		else
			self.friendTeamNameLabel:setString(self.currentEditTeamsName.friend)
		end
	end})
	display.commonUIParams(saveBtn, {po = cc.p(bgNodePos.x, bgNodePos.y - 50)})
	node:addChild(saveBtn)
	local saveBtnLabel = self:GetANewLabel(
		{text = '保存'},
		{po = utils.getLocalCenter(saveBtn)},
		saveBtn
	)
end
--[[
保存队伍信息
@params isEnemy bool 敌友性
--]]
function DebugBattleScene:SaveTeamsToLocal(isEnemy)
	local teamsInfo = nil
	local teamsName = nil

	if isEnemy then
		teamsInfo = self.currentEditTeamsData.enemy
		teamsName = self.currentEditTeamsName.enemy
	else
		teamsInfo = self.currentEditTeamsData.friend
		teamsName = self.currentEditTeamsName.friend
	end

	local str = cc.UserDefault:getInstance():getStringForKey(LOCAL_TEAMS_SAVE_DATA, '')
	local newStr = nil
	local teamsSaveDatalua = nil

	if 0 < string.len(str) then
		teamsSaveDatalua = json.decode(str)
		if isEnemy then
			teamsSaveDatalua.teams.enemy[tostring(teamsName)] = TagMatchTeamsSaveDataStruct.New(teamsName, teamsInfo)
		else
			teamsSaveDatalua.teams.friend[tostring(teamsName)] = TagMatchTeamsSaveDataStruct.New(teamsName, teamsInfo)
		end
	else
		-- 初始化一次
		teamsSaveDatalua = TagMatchAllTeamsSaveDataStruct.New()
		if isEnemy then
			teamsSaveDatalua.teams.enemy[tostring(teamsName)] = TagMatchTeamsSaveDataStruct.New(teamsName, teamsInfo)
		else
			teamsSaveDatalua.teams.friend[tostring(teamsName)] = TagMatchTeamsSaveDataStruct.New(teamsName, teamsInfo)
		end
	end

	-- 记录一次默认队伍
	if isEnemy then
		teamsSaveDatalua.defaultTeamsName.enemy = teamsName
	else
		teamsSaveDatalua.defaultTeamsName.friend = teamsName
	end

	newStr = json.encode(teamsSaveDatalua)

	if nil ~= newStr then
		cc.UserDefault:getInstance():setStringForKey(LOCAL_TEAMS_SAVE_DATA, newStr)
		cc.UserDefault:getInstance():flush()
	end
end
--[[
读取本地保存的队伍信息按钮回调
--]]
function DebugBattleScene:LoadTeamsBtnClickHandler(sender)
	local isEnemy = ENEMY_TEAM_TAG == sender:getParent():getTag()
	local loaclteamsinfo = self:GetSortLocalTeamsSaveData(isEnemy)

	local node = self:GetANewPopLayer()
	local bgNode = node:getChildByTag(3)
	local bgNodePos = cc.p(bgNode:getPositionX(), bgNode:getPositionY())
	local bgNodeSize = bgNode:getContentSize()

	local listViewSize = cc.size(bgNodeSize.width - 10, bgNodeSize.height - 10)
	local cellSize = cc.size(listViewSize.width, 100)

	local listView = CTableView:create(listViewSize)
	display.commonUIParams(listView, {ap = cc.p(0.5, 0.5), po = bgNodePos})
	node:addChild(listView)

	listView:setSizeOfCell(cellSize)
	listView:setCountOfCell(#loaclteamsinfo)
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setDataSourceAdapterScriptHandler(function (c, i)

		local cell = c
		local index = i + 1

		local loaclteamsinfo_ = self:GetSortLocalTeamsSaveData(isEnemy)
		local teamsInfo_ = loaclteamsinfo_[index]

		local teamNameLabel = nil

		if nil == cell then
			cell = CTableViewCell:new()
			cell:setContentSize(cellSize)
			cell:setBackgroundColor(cc.c4b(math.random(255), math.random(255), math.random(255), 128))

			teamNameLabel = self:GetANewLabel(
				{text = teamsInfo_.teamsName},
				{ap = cc.p(0, 0.5), po = cc.p(10, cellSize.height * 0.5)},
				cell
			)
			teamNameLabel:setTag(3)

			-- 读取配置按钮
			local loadTeamBtn = display.newButton(0, 0, {n = BTN_N, cb = function (sender)
				local teamIndex = sender:getParent():getTag()
				local teamsName = self:GetSortLocalTeamsSaveData(isEnemy)[teamIndex].teamsName

				-- 记录一次默认读取的队伍
				self:SaveDefaultLoadTeams(isEnemy, teamsName)
				self:LoadTeamsByTeamName(isEnemy, teamsName)
				self:RemoveANode(node)
			end})
			display.commonUIParams(loadTeamBtn, {po = cc.p(
				cellSize.width - 20 - loadTeamBtn:getContentSize().width * 0.5,
				cellSize.height * 0.5
			)})
			cell:addChild(loadTeamBtn)
			local loadTeamBtnLabel = self:GetANewLabel(
				{text = '读取配置'},
				{po = utils.getLocalCenter(loadTeamBtn)},
				loadTeamBtn
			)

			local delTeamBtn = display.newButton(0, 0, {n = BTN_N, cb = function (sender)
				local teamIndex = sender:getParent():getTag()
				local teamsName = self:GetSortLocalTeamsSaveData(isEnemy)[teamIndex].teamsName
				self:DeleteTeamsByTeamsName(isEnemy, teamsName)
				self:RemoveANode(node)
				listView:setCountOfCell(#self:GetSortLocalTeamsSaveData())
				listView:reloadData()
			end})
			display.commonUIParams(delTeamBtn, {po = cc.p(
				loadTeamBtn:getPositionX() - loadTeamBtn:getContentSize().width - 10,
				loadTeamBtn:getPositionY()
			)})
			cell:addChild(delTeamBtn)
			local delTeamBtnLabel = self:GetANewLabel(
				{text = '删除配置'},
				{po = utils.getLocalCenter(delTeamBtn)},
				delTeamBtn
			)
		else
			teamNameLabel = cell:getChildByTag(3)
		end

		teamNameLabel:setString(tostring(teamsInfo_.teamsName))
		cell:setTag(index)

		return cell

	end)

	listView:reloadData()
end
--[[
点击开始战斗回调
--]]
function DebugBattleScene:BattleBtnClickHandler(sender)
	local tag = sender:getTag()
	if QuestBattleType.TAG_MATCH_3V3 == tag then
		self:StartPVCBattle()
	else
		self:StartBattleByStageId()
	end
end
--[[
以当前数据开始战斗
--]]
function DebugBattleScene:StartBattleByStageId()
	-- 关卡id
	local stageId = checkint(self.inputStageId)
	local stageConfig = self:GetStageConfigByStageId(stageId)
	if nil == stageConfig then
		self.startBattleWaringLabel:setVisible(true)
		self.startBattleWaringLabel:setString('关卡不存在')
		return
	end

	-- 友方阵容
	local hasCard = false
	for k,v in pairs(self.currentFriendTeamData) do
		if v.cardId and 0 ~= checkint(v.cardId) then
			hasCard = true
			break
		end
	end
	if not hasCard then
		self.startBattleWaringLabel:setVisible(true)
		self.startBattleWaringLabel:setString('队伍不能为空')
		return
	end

	self.startBattleWaringLabel:setVisible(false)

	-- 可以进入战斗
	local battleConstructor = require('battleEntry.BattleConstructor').new()
	battleConstructor:InitByDebugBattle(
		stageId,
		self.currentFriendTeamData,
		self.currentPlayerSkill
	)

	dump(self.currentFriendTeamData)

	-- AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = ''},
		{name = 'BattleMediator', params = battleConstructor}
	)
end
--[[
以当前数据开始车轮战
--]]
function DebugBattleScene:StartPVCBattle()
	------------ debug data ------------
	-- local friendTeams = {
	-- 	[1] = {
	-- 		[1] = {
	-- 			cardId = 200001,
	-- 			exp = 1,
	-- 			level = 1,
	-- 			breakLevel = 1,
	-- 			favorAbilityLevel = 1,
	-- 			vigour = 1,
	-- 			skill = {
	-- 				['10001'] = {level = 1},
	-- 				['10002'] = {level = 1},
	-- 				['90001'] = {level = 1}
	-- 			}
	-- 		},
	-- 		[3] = {
	-- 			cardId = 200002,
	-- 			exp = 1,
	-- 			level = 1,
	-- 			breakLevel = 1,
	-- 			favorAbilityLevel = 1,
	-- 			vigour = 1,
	-- 			skill = {
	-- 				['10003'] = {level = 1},
	-- 				['10004'] = {level = 1},
	-- 				['90002'] = {level = 1}
	-- 			}
	-- 		}
	-- 	},
	-- 	[2] = {
	-- 		[3] = {
	-- 			cardId = 200003,
	-- 			exp = 1,
	-- 			level = 1,
	-- 			breakLevel = 1,
	-- 			favorAbilityLevel = 1,
	-- 			vigour = 1,
	-- 			skill = {
	-- 				['10005'] = {level = 1},
	-- 				['10006'] = {level = 1},
	-- 				['90003'] = {level = 1}
	-- 			}
	-- 		}
	-- 	},
	-- 	[3] = {
	-- 		[3] = {
	-- 			cardId = 200004,
	-- 			exp = 1,
	-- 			level = 80,
	-- 			breakLevel = 5,
	-- 			favorAbilityLevel = 1,
	-- 			vigour = 1,
	-- 			skill = {
	-- 				['10007'] = {level = 20},
	-- 				['10008'] = {level = 20},
	-- 				['90004'] = {level = 20}
	-- 			}
	-- 		}
	-- 	}
	-- }
	-- local enemyTeams = {
	-- 	[1] = {
	-- 		[1] = {
	-- 			cardId = 200036,
	-- 			exp = 1,
	-- 			level = 1,
	-- 			breakLevel = 1,
	-- 			favorAbilityLevel = 1,
	-- 			vigour = 1,
	-- 			skill = {
	-- 				['10071'] = {level = 1},
	-- 				['10072'] = {level = 1},
	-- 				['90036'] = {level = 1}
	-- 			}
	-- 		}
	-- 	},
	-- 	[2] = {
	-- 		[1] = {
	-- 			cardId = 200035,
	-- 			exp = 1,
	-- 			level = 60,
	-- 			breakLevel = 5,
	-- 			favorAbilityLevel = 1,
	-- 			vigour = 1,
	-- 			skill = {
	-- 				['10069'] = {level = 10},
	-- 				['10070'] = {level = 10},
	-- 				['90035'] = {level = 10}
	-- 			}
	-- 		}
	-- 	},
	-- 	[3] = {
	-- 		[1] = {
	-- 			cardId = 200034,
	-- 			exp = 1,
	-- 			level = 1,
	-- 			breakLevel = 1,
	-- 			favorAbilityLevel = 1,
	-- 			vigour = 1,
	-- 			skill = {
	-- 				['10067'] = {level = 1},
	-- 				['10068'] = {level = 1},
	-- 				['90034'] = {level = 1}
	-- 			}
	-- 		}
	-- 	}
	-- }

	local friendAllSkills = {}
	local enemyAllSkills = {}
	------------ debug data ------------

	dump(self.currentEditTeamsData)

	-- 检查是否可以进入战斗
	local canStartBattle = true
	local waringStr = ''

	if 0 >= #self.currentEditTeamsData.friend * #self.currentEditTeamsData.enemy then
		canStartBattle = false
		waringStr = '必须添加一支队伍'
	end

	for i,v in ipairs(self.currentEditTeamsData.friend) do
		if nil == next(v) then
			canStartBattle = false
			waringStr = '队伍卡牌不能为空'
			break
		end
	end

	for i,v in ipairs(self.currentEditTeamsData.enemy) do
		if nil == next(v) then
			canStartBattle = false
			waringStr = '队伍卡牌不能为空'
			break
		end
	end

	if not canStartBattle then
		self.startBattleWaringLabel:setVisible(true)
		self.startBattleWaringLabel:setString(waringStr)
		return
	else
		self.startBattleWaringLabel:setVisible(false)
	end

	local battleConstructor = require('battleEntry.BattleConstructor').new()
	battleConstructor:InitDataByDebugTagMatchThreeTeams(
		self.currentEditTeamsData.friend,
		self.currentEditTeamsData.enemy,
		friendAllSkills,
		enemyAllSkills
	)
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = ''},
		{name = 'BattleMediator', params = battleConstructor}
	)
end
--[[
增加一队按钮回调
--]]
function DebugBattleScene:AddTeamBtnClickHandler(sender)
	local tag = sender:getTag()
	local isEnemy = tag == ENEMY_TEAM_TAG
	self:AddATeam(isEnemy)
end
--[[
添加一队
@params isEnemy bool 是否是敌军
--]]
function DebugBattleScene:AddATeam(isEnemy)
	local teamsData = nil

	local parentNode = nil
	local titleLabel = nil
	local addTeamBtn = nil

	local teamsNodes = nil

	if isEnemy then
		teamsData = self.currentEditTeamsData.enemy

		parentNode = self.enemyTeamLayer
		titleLabel = self.enemyTitleLabel
		addTeamBtn = self.enemyAddTeamBtn

		teamsNodes = self.enemyTeamsNodes
	else
		teamsData = self.currentEditTeamsData.friend

		parentNode = self.friendTeamLayer
		titleLabel = self.friendTitleLabel
		addTeamBtn = self.friendAddTeamBtn

		teamsNodes = self.friendTeamsNodes
	end

	local layerSize = parentNode:getContentSize()

	------------ data ------------
	table.insert(teamsData, {})
	------------ data ------------

	------------ view ------------
	-- 创建编辑队伍界面
	local layertable = self:CreateATeamEditorLayer(MAX_TEAM_MEMBER)
	display.commonUIParams(layertable.layer, {ap = cc.p(0.5, 1), po = cc.p(
		layerSize.width * 0.5,
		titleLabel:getPositionY() - 55 - (layertable.layer:getContentSize().height * (#teamsNodes))
	)})
	parentNode:addChild(layertable.layer)
	table.insert(teamsNodes, layertable)

	local teamIndex = #teamsData
	layertable.layer:setTag(teamIndex)

	-- 重置增加队伍按钮
	display.commonUIParams(addTeamBtn, {po = cc.p(
		20 + addTeamBtn:getContentSize().width * 0.5,
		titleLabel:getPositionY() - 55 - addTeamBtn:getContentSize().height * 0.5 - (170 * #teamsNodes)
	)})
	------------ view ------------
end
--[[
删掉一队
@params isEnemy bool 是否是敌军
@params teamIndex int 队伍序号
--]]
function DebugBattleScene:DelATeam(isEnemy, teamIndex)
	local teamsInfo = nil
	local nodes = nil
	local titleLabel = nil
	local addTeamBtn = nil

	if isEnemy then
		teamsInfo = self.currentEditTeamsData.enemy

		nodes = self.enemyTeamsNodes
		titleLabel = self.enemyTitleLabel
		addTeamBtn = self.enemyAddTeamBtn
	else
		teamsInfo = self.currentEditTeamsData.friend

		nodes = self.friendTeamsNodes
		titleLabel = self.friendTitleLabel
		addTeamBtn = self.friendAddTeamBtn
	end

	------------ data ------------
	self:DelTeamInfo(isEnemy, teamIndex)
	------------ data ------------

	------------ view ------------
	local targetTeamNodes = nodes[teamIndex]
	targetTeamNodes.layer:runAction(cc.RemoveSelf:create())
	table.remove(nodes, teamIndex)

	local teamIndex_ = 1
	for k,v in pairs(nodes) do
		v.layer:setPositionY(
			titleLabel:getPositionY() - 55 - (v.layer:getContentSize().height * (teamIndex_ - 1))
		)
		v.layer:setTag(teamIndex_)
		teamIndex_ = teamIndex_ + 1
	end

	-- 重置增加队伍按钮
	display.commonUIParams(addTeamBtn, {po = cc.p(
		20 + addTeamBtn:getContentSize().width * 0.5,
		titleLabel:getPositionY() - 55 - addTeamBtn:getContentSize().height * 0.5 - (170 * #nodes)
	)})

	-- 刷新战斗力
	self:RefreshBattlePointLabel()
	------------ view ------------
end
--[[
上移队伍按钮回调
--]]
function DebugBattleScene:UpTeamBtnClickHandler(sender)
	local isEnemy = ENEMY_TEAM_TAG == sender:getParent():getParent():getTag()
	local teamIndex = sender:getParent():getTag()
	local delta = -1
	self:ChangeTeamIndex(isEnemy, teamIndex, delta)
end
--[[
下移队伍按钮回调
--]]
function DebugBattleScene:DownTeamBtnClickHandler(sender)
	local isEnemy = ENEMY_TEAM_TAG == sender:getParent():getParent():getTag()
	local teamIndex = sender:getParent():getTag()
	local delta = 1
	self:ChangeTeamIndex(isEnemy, teamIndex, delta)
end
--[[
删除队伍按钮回调
--]]
function DebugBattleScene:DelTeamBtnHandler(sender)
	local isEnemy = ENEMY_TEAM_TAG == sender:getParent():getParent():getTag()
	local teamIndex = sender:getParent():getTag()
	self:DelATeam(isEnemy, teamIndex)
end
--[[
变更队伍序号
@params isEnemy bool 
@params teamIndex int 队伍序号
@params delta int 变化的值
--]]
function DebugBattleScene:ChangeTeamIndex(isEnemy, teamIndex, delta)
	local teamsInfo = nil
	local nodes = nil

	if isEnemy then
		teamsInfo = self.currentEditTeamsData.enemy
		nodes = self.enemyTeamsNodes
	else
		teamsInfo = self.currentEditTeamsData.friend
		nodes = self.friendTeamsNodes
	end

	local preTeamIndex = teamIndex
	local currentTeamIndex = preTeamIndex + delta

	if 1 > currentTeamIndex or #teamsInfo < currentTeamIndex then return end

	------------ data ------------
	local targetTeamInfo = teamsInfo[preTeamIndex]
	local otherTeamInfo = teamsInfo[currentTeamIndex]

	teamsInfo[currentTeamIndex] = targetTeamInfo
	teamsInfo[preTeamIndex] = otherTeamInfo
	------------ data ------------

	------------ view ------------
	local targetTeamNodes = nodes[preTeamIndex]
	local otherTeamNodes = nodes[currentTeamIndex]

	nodes[currentTeamIndex] = targetTeamNodes
	nodes[preTeamIndex] = otherTeamNodes


	if nil ~= targetTeamNodes then
		targetTeamNodes.layer:setPositionY(
			targetTeamNodes.layer:getPositionY() - delta * targetTeamNodes.layer:getContentSize().height
		)

		targetTeamNodes.layer:setTag(currentTeamIndex)
	end

	if nil ~= otherTeamNodes then
		otherTeamNodes.layer:setPositionY(
			otherTeamNodes.layer:getPositionY() + delta * otherTeamNodes.layer:getContentSize().height
		)

		otherTeamNodes.layer:setTag(preTeamIndex)
	end

	-- 刷新战斗力
	self:RefreshBattlePointLabel()
	------------ view ------------
end
--[[
刷新战斗力
--]]
function DebugBattleScene:RefreshBattlePointLabel()
	if self.totalBattlePointLabel then
		-- 刷新一次总战力
		local totalBattlePoint = 0
		for k,v in pairs(self.currentFriendTeamData) do
			totalBattlePoint = totalBattlePoint + self:GetCardStaticBattlePoint(v)
		end
		self.totalBattlePointLabel:setString(totalBattlePoint)
	end

	if self.friendTotalBattlePointLabel then
		-- 刷新一次总战力
		local totalBattlePoints = {}
		for teamIndex, teamInfo in pairs(self.currentEditTeamsData.friend) do
			local totalBattlePoint = 0
			for cardIndex, cardInfo in pairs(teamInfo) do
				totalBattlePoint = totalBattlePoint + self:GetCardStaticBattlePoint(cardInfo)
			end
			table.insert(totalBattlePoints, totalBattlePoint)
		end

		local str = '0'

		for i,v in ipairs(totalBattlePoints) do
			if 1 == i then
				str = ''
			end
			str = str .. v .. ' , '
		end

		self.friendTotalBattlePointLabel:setString(str)
	end

	if self.enemyTotalBattlePointLabel then
		-- 刷新一次总战力
		local totalBattlePoints = {}

		for teamIndex, teamInfo in pairs(self.currentEditTeamsData.enemy) do
			local totalBattlePoint = 0
			for cardIndex, cardInfo in pairs(teamInfo) do
				totalBattlePoint = totalBattlePoint + self:GetCardStaticBattlePoint(cardInfo)
			end
			table.insert(totalBattlePoints, totalBattlePoint)
		end

		local str = '0'

		for i,v in ipairs(totalBattlePoints) do
			if 1 == i then
				str = ''
			end
			str = str .. v .. ' , '
		end

		self.enemyTotalBattlePointLabel:setString(str)
	end
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
根据卡牌信息显示一个编辑卡牌的界面
@params teamIdx int 编队位置
@params cardInfo table 卡牌信息
--]]
function DebugBattleScene:ShowEditCardView(teamIdx, cardInfo)
	if nil == cardInfo then
		-- 为空显示第一步选卡
		self:ShowChooseCardLayerForPop(teamIdx)
	else
		-- 不为空显示调整卡牌
		self:ShowEditCardDetailView(teamIdx, cardInfo)
	end
end
--[[
根据队伍卡牌信息显示一个编辑卡牌的界面
@params isEnemy bool 是否是敌军
@params teamIndex int 队伍信息
@params cardIndex int 卡牌序号
@params cardInfo table 卡牌信息
--]]
function DebugBattleScene:ShowEditTeamCardView(isEnemy, teamIndex, cardIndex, cardInfo)
	if nil == cardInfo then
		-- 为空显示第一步选卡
		self:ShowChooseTeamCardLayerForPop(isEnemy, teamIndex, cardIndex)
	else
		-- 不为空显示调整卡牌
		self:ShowEditTeamCardDetailView(isEnemy, teamIndex, cardIndex, cardInfo)
	end
end
--[[
为通用弹出节点添加选卡层
@params teamIdx int 编队位置
--]]
function DebugBattleScene:ShowChooseCardLayerForPop(teamIdx)
	local node = self:GetANewPopLayer()

	local cardsConfigTable = self:GetConfigTable('card', 'card')
	local sk = sortByKey(cardsConfigTable)

	local bgNode = node:getChildByTag(3)

	local gridViewSize = bgNode:getContentSize()
	local cellPerLine = 5
	local gridViewCellSize = cc.size(gridViewSize.width / cellPerLine, gridViewSize.width / cellPerLine)
	local gridView = CGridView:create(gridViewSize)
	gridView:setAnchorPoint(cc.p(0.5, 0.5))
	gridView:setPosition(utils.getLocalCenter(node))
	node:addChild(gridView, 99)

	gridView:setCountOfCell(table.nums(cardsConfigTable))
	gridView:setColumns(cellPerLine)
	gridView:setSizeOfCell(gridViewCellSize)
	gridView:setAutoRelocate(true)
	gridView:setBounceable(true)
	gridView:setDataSourceAdapterScriptHandler(function (c, i)
		local cell = c
		local index = i + 1

		local cardId = checkint(sk[index])
		local cardConfig = cardsConfigTable[tostring(cardId)]
		local cardData = {
			cardId = cardId,
			level = 1,
			breakLevel = 1,
			skinId = CardUtils.GetCardSkinId(cardId)
		}

		local cardHeadNode = nil
		local cardNameLabel = nil
		local cardIdLabel = nil
		local btn = nil

		if nil == cell then
			cell = CGridViewCell:new()
			cell:setContentSize(gridViewCellSize)

			btn = display.newButton(0, 0, {size = gridViewCellSize, cb = function (sender)
				local index = btn:getParent():getTag()
				local cardId = checkint(sk[index])

				self:RemoveANode(node)
				self:ChooseACard(teamIdx, cardId)
			end})
			display.commonUIParams(btn, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(cell)})
			cell:addChild(btn, 99)

			cardHeadNode = require('common.CardHeadNode').new({
				cardData = cardData,
				showBaseState = true
			})
			local scale = (gridViewCellSize.width - 10) / cardHeadNode:getContentSize().width
			cardHeadNode:setScale(scale)
			display.commonUIParams(cardHeadNode, {po = utils.getLocalCenter(cell)})
			cell:addChild(cardHeadNode)
			cardHeadNode:setTag(3)

			cardNameLabel = self:GetANewLabel(
				{text = cardConfig.name},
				{po = cc.p(gridViewCellSize.width * 0.5, 25)},
				cell,
				99, 5
			)

			cardIdLabel = self:GetANewLabel(
				{text = cardConfig.id},
				{po = cc.p(gridViewCellSize.width * 0.5, gridViewCellSize.height - 25)},
				cell,
				99, 7
			)
		else
			cardHeadNode = cell:getChildByTag(3)
			cardNameLabel = cell:getChildByTag(5)
			cardIdLabel = cell:getChildByTag(7)
		end

		cell:setTag(index)
		cardHeadNode:RefreshUI({cardData = cardData, showBaseState = true})
		cardNameLabel:setString(cardConfig.name)
		cardIdLabel:setString(cardConfig.id)

		return cell

	end)

	gridView:reloadData()
end
--[[
为通用弹出节点添加选卡层
@params isEnemy bool 是否是敌军
@params teamIndex int 队伍信息
@params cardIndex int 卡牌序号
--]]
function DebugBattleScene:ShowChooseTeamCardLayerForPop(isEnemy, teamIndex, cardIndex)
	local node = self:GetANewPopLayer()

	local cardsConfigTable = self:GetConfigTable('card', 'card')
	local sk = sortByKey(cardsConfigTable)

	local bgNode = node:getChildByTag(3)

	local gridViewSize = bgNode:getContentSize()
	local cellPerLine = 5
	local gridViewCellSize = cc.size(gridViewSize.width / cellPerLine, gridViewSize.width / cellPerLine)
	local gridView = CGridView:create(gridViewSize)
	gridView:setAnchorPoint(cc.p(0.5, 0.5))
	gridView:setPosition(utils.getLocalCenter(node))
	node:addChild(gridView, 99)

	gridView:setCountOfCell(table.nums(cardsConfigTable))
	gridView:setColumns(cellPerLine)
	gridView:setSizeOfCell(gridViewCellSize)
	gridView:setAutoRelocate(true)
	gridView:setBounceable(true)
	gridView:setDataSourceAdapterScriptHandler(function (c, i)
		local cell = c
		local index = i + 1

		local cardId = checkint(sk[index])
		local cardConfig = cardsConfigTable[tostring(cardId)]
		local cardData = {
			cardId = cardId,
			level = 1,
			breakLevel = 1,
			skinId = CardUtils.GetCardSkinId(cardId)
		}

		local cardHeadNode = nil
		local cardNameLabel = nil
		local cardIdLabel = nil
		local btn = nil

		if nil == cell then
			cell = CGridViewCell:new()
			cell:setContentSize(gridViewCellSize)

			btn = display.newButton(0, 0, {size = gridViewCellSize, cb = function (sender)
				local index = btn:getParent():getTag()
				local cardId = checkint(sk[index])

				self:RemoveANode(node)
				self:ChooseATeamCard(isEnemy, teamIndex, cardIndex, cardId)
			end})
			display.commonUIParams(btn, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(cell)})
			cell:addChild(btn, 99)

			cardHeadNode = require('common.CardHeadNode').new({
				cardData = cardData,
				showBaseState = true
			})
			local scale = (gridViewCellSize.width - 10) / cardHeadNode:getContentSize().width
			cardHeadNode:setScale(scale)
			display.commonUIParams(cardHeadNode, {po = utils.getLocalCenter(cell)})
			cell:addChild(cardHeadNode)
			cardHeadNode:setTag(3)

			cardNameLabel = self:GetANewLabel(
				{text = cardConfig.name},
				{po = cc.p(gridViewCellSize.width * 0.5, 25)},
				cell,
				99, 5
			)

			cardIdLabel = self:GetANewLabel(
				{text = cardConfig.id},
				{po = cc.p(gridViewCellSize.width * 0.5, gridViewCellSize.height - 25)},
				cell,
				99, 7
			)
		else
			cardHeadNode = cell:getChildByTag(3)
			cardNameLabel = cell:getChildByTag(5)
			cardIdLabel = cell:getChildByTag(7)
		end

		cell:setTag(index)
		cardHeadNode:RefreshUI({cardData = cardData, showBaseState = true})
		cardNameLabel:setString(cardConfig.name)
		cardIdLabel:setString(cardConfig.id)

		return cell

	end)

	gridView:reloadData()
end
--[[
选了一张卡
@params teamIdx int 编队位置
@params cardId int 卡牌id
--]]
function DebugBattleScene:ChooseACard(teamIdx, cardId)
	local cardInfo = CardInfoStruct.New(cardId)

	self:ShowEditCardDetailView(teamIdx, cardInfo)
end
--[[
选了一张卡
@params isEnemy bool 是否是敌军
@params teamIndex int 队伍信息
@params cardIndex int 卡牌序号
@params cardId int 卡牌id
--]]
function DebugBattleScene:ChooseATeamCard(isEnemy, teamIndex, cardIndex, cardId)
	local cardInfo = CardInfoStruct.New(cardId)

	self:ShowEditTeamCardDetailView(isEnemy, teamIndex, cardIndex, cardInfo)
end
--[[
显示卡牌编辑信息
@params teamIdx int 编队位置
@params cardInfo table 卡牌信息
--]]
function DebugBattleScene:ShowEditCardDetailView(teamIdx, cardInfo)
	self.currentEditCardInfo = cardInfo

	local cardId = checkint(cardInfo.cardId)
	local cardConfig = self:GetConfig('card', 'card', cardId)

	-- 显示卡牌编辑信息的界面
	local node = self:GetANewPopLayer()
	node:setTag(EDIT_CARD_DETAIL_TAG)
	local bgNode = node:getChildByTag(3)
	local bgNodePos = cc.p(bgNode:getPositionX(), bgNode:getPositionY())
	local bgNodeSize = bgNode:getContentSize()

	-- 编号
	local teamLabel = self:GetANewLabel(
		{text = tostring(teamIdx)},
		{po = cc.p(bgNodePos.x - bgNodeSize.width * 0.5 + 10, bgNodePos.y + bgNodeSize.height * 0.5 - 10)},
		node
	)

	-- 卡牌头像
	local cardHeadNode = require('common.CardHeadNode').new({
		cardData = cardInfo
	})
	display.commonUIParams(cardHeadNode, {po = cc.p(
		bgNodePos.x - bgNodeSize.width * 0.5 + cardHeadNode:getContentSize().width * 0.5 + 20,
		bgNodePos.y + bgNodeSize.height * 0.5 - cardHeadNode:getContentSize().height * 0.5 - 20
	)})
	node:addChild(cardHeadNode)

	-- 属性预览
	local objppreviewnodes = {}
	for i,v in ipairs(ObjPPreview) do
		-- 属性名字
		local nameLabel = self:GetANewLabel(
			{text = ObjPConfig[v.objp].pname},
			{ap = cc.p(0, 0.5), po = cc.p(bgNodePos.x - bgNodeSize.width * 0.5 + 25, cardHeadNode:getPositionY() - cardHeadNode:getContentSize().height * 0.5 - 50 - (35 * (i - 1)))},
			node
		)

		-- 属性值
		local valueLabel = self:GetANewLabel(
			{text = '0', notTTF = true, color = '#000000'},
			{ap = cc.p(0, 0.5), po = cc.p(nameLabel:getPositionX() + 75, nameLabel:getPositionY())},
			node
		)

		objppreviewnodes[i] = {nameLabel = nameLabel, valueLabel = valueLabel}
	end

	local refreshAllObjPPreview = function ()
		local cardInfo = self.currentEditCardInfo
		local objpinfo = CardUtils.GetCardAllFixedP(
			checkint(cardInfo.cardId),
			checkint(cardInfo.level),
			checkint(cardInfo.breakLevel),
			checkint(cardInfo.favorLevel)
		)

		-- 加上宠物的数值
		for i, petInfo in ipairs(self.currentEditCardInfo.pets) do
			for pidx, pinfo in ipairs(petInfo.petp) do
				-- 判断是否解锁
				local lock = petMgr.GetPetPInfo()[pidx].unlockLevel > petInfo.level
				if not lock then
					local objp = PetPConfig[pinfo.ptype].objp
					objpinfo[objp] = objpinfo[objp] + pinfo.pvalue
				end
			end
		end

		for i,v in ipairs(ObjPPreview) do
			local nodes = objppreviewnodes[i]
			nodes.valueLabel:setString(objpinfo[v.objp])
		end
	end

	refreshAllObjPPreview()
	self.refreshCurrentCardPPreview = refreshAllObjPPreview

	-- 输入星级
	local startitleNode, starinputNode = self:GetATitleAndInputBox(
		'星级',
		{ap = cc.p(0, 0.5), po = cc.p(bgNodePos.x - 110, bgNodePos.y + bgNodeSize.height * 0.5 - 50)},
		node,
		cc.size(80, 50)
	)
	starinputNode:setText(cardInfo.breakLevel)
	local starwaringLabel = self:GetANewLabel(
		{text = '', fontSize = 18, color = '#aa1122', notTTF = true},
		{ap = cc.p(0.5, 0), po = cc.p(starinputNode:getPositionX(), starinputNode:getPositionY() + starinputNode:getContentSize().height * 0.5)},
		node
	)
	starwaringLabel:setVisible(false)

	starinputNode:registerScriptEditBoxHandler(function (eventType)
		if 'return' == eventType then
			local inputText = starinputNode:getText()
			local errlog = self:IsInputValueInvalid(inputText)
			if errlog then
				starwaringLabel:setVisible(true)
				starwaringLabel:setString(errlog)
			else
				local value = checkint(inputText)
				if 1 > value or 5 < value then
					starwaringLabel:setVisible(true)
					starwaringLabel:setString('超出范围')
				else
					starwaringLabel:setVisible(false)
					-- 记录缓存
					self.currentEditCardInfo.breakLevel = value
					-- 刷新属性预览
					refreshAllObjPPreview()
				end
			end
		end
	end)

	-- 输入等级
	local leveltitleNode, levelinputNode = self:GetATitleAndInputBox(
		'等级',
		{ap = cc.p(0, 0.5), po = cc.p(startitleNode:getPositionX(), startitleNode:getPositionY() - 75)},
		node,
		cc.size(80, 50)
	)
	levelinputNode:setText(cardInfo.level)

	local levelwaringLabel = self:GetANewLabel(
		{text = '', fontSize = 18, color = '#aa1122', notTTF = true},
		{ap = cc.p(0.5, 0), po = cc.p(levelinputNode:getPositionX(), levelinputNode:getPositionY() + levelinputNode:getContentSize().height * 0.5)},
		node
	)
	levelwaringLabel:setVisible(false)

	levelinputNode:registerScriptEditBoxHandler(function (eventType)
		if 'return' == eventType then
			local cardlevelconfigTable = self:GetConfigTable('card', 'level')
			local inputText = levelinputNode:getText()
			local errlog = self:IsInputValueInvalid(inputText)
			if errlog then
				levelwaringLabel:setVisible(true)
				levelwaringLabel:setString(errlog)
			else
				local value = checkint(inputText)
				if 1 > value or table.nums(cardlevelconfigTable) < value then
					levelwaringLabel:setVisible(true)
					levelwaringLabel:setString('超出范围')
				else
					local breakLevel = checkint(starinputNode:getText())
					if checkint(cardConfig.breakLevel[breakLevel]) < value then
						levelwaringLabel:setVisible(true)
						levelwaringLabel:setString('星级不足')
					else
						levelwaringLabel:setVisible(false)
						-- 记录缓存
						self.currentEditCardInfo.level = value
						-- 刷新属性预览
						refreshAllObjPPreview()
					end
				end
			end
		end
	end)

	-- 输入好感度等级
	local favortitleNode, favorinputNode = self:GetATitleAndInputBox(
		'好感',
		{ap = cc.p(0, 0.5), po = cc.p(startitleNode:getPositionX(), leveltitleNode:getPositionY() - 75)},
		node,
		cc.size(80, 50)
	)
	favorinputNode:setText(cardInfo.favorLevel)

	local favorwaringLabel = self:GetANewLabel(
		{text = '', fontSize = 18, color = '#aa1122', notTTF = true},
		{ap = cc.p(0.5, 0), po = cc.p(favorinputNode:getPositionX(), favorinputNode:getPositionY() + favorinputNode:getContentSize().height * 0.5)},
		node
	)
	favorwaringLabel:setVisible(false)

	favorinputNode:registerScriptEditBoxHandler(function (eventType)
		if 'return' == eventType then
			local cardfavorconfigTable = self:GetConfigTable('card', 'favorabilityLevel')
			local inputText = favorinputNode:getText()
			local errlog = self:IsInputValueInvalid(inputText)
			if errlog then
				favorwaringLabel:setVisible(true)
				favorwaringLabel:setString(errlog)
			else
				local value = checkint(inputText)
				if 1 > value or table.nums(cardfavorconfigTable) < value then
					favorwaringLabel:setVisible(true)
					favorwaringLabel:setString('超出范围')
				else
					favorwaringLabel:setVisible(false)
					-- 记录缓存
					self.currentEditCardInfo.favorLevel = value
					-- 刷新属性预览
					refreshAllObjPPreview()
				end
			end
		end
	end)

	-- 卡牌技能
	local sortskillkey = sortByKey(cardInfo.skills)
	for i,v in ipairs(sortskillkey) do
		local skillId = checkint(v)
		local skillData = cardInfo.skills[v]
		local skillConfig = self:GetConfig('card', 'skill', skillId)
		local skillIcon = require('common.SkillNode').new({
			id = skillId
		})
		display.commonUIParams(skillIcon, {po = cc.p(
			bgNodePos.x - bgNodeSize.width * 0.5 + bgNodeSize.width * 0.6,
			bgNodePos.y + bgNodeSize.height * 0.5 - 50 - (75 * (i - 1))
		)})
		node:addChild(skillIcon)
		local skillIconScale = 0.4
		skillIcon:setScale(skillIconScale)

		local skillNodeBtn = display.newButton(0, 0, {
			size = cc.size(skillIcon:getContentSize().width * skillIconScale, skillIcon:getContentSize().height * skillIconScale),
			cb = function (sender)
				local skillId = sender:getTag()
				local skillData = self.currentEditCardInfo.skills[tostring(skillId)]
				local skillConfig = self:GetConfig('card', 'skill', skillId)
				uiMgr:ShowInformationTipsBoard({
					targetNode = sender,
					title = skillConfig.name,
					descr = cardMgr.GetSkillDescr(skillId, skillData.level),
					type = 5
				})
			end
		})
		display.commonUIParams(skillNodeBtn, {po = cc.p(
			skillIcon:getPositionX(),
			skillIcon:getPositionY()
		)})
		node:addChild(skillNodeBtn, 99)
		skillNodeBtn:setTag(skillId)

		local skilltitleNode, skillinputNode = self:GetATitleAndInputBox(
			'技能等级',
			{ap = cc.p(0, 0.5), po = cc.p(skillIcon:getPositionX() + skillIcon:getContentSize().width * 0.5 * skillIconScale + 5, skillIcon:getPositionY())},
			node,
			cc.size(80, 50)
		)
		skillinputNode:setText(skillData.level)
		skillinputNode:setTag(skillId)

		local skillwaringLabel = self:GetANewLabel(
			{text = '', fontSize = 18, color = '#aa1122', notTTF = true},
			{ap = cc.p(0.5, 0), po = cc.p(skillinputNode:getPositionX(), skillinputNode:getPositionY() + skillinputNode:getContentSize().height * 0.5)},
			node
		)
		skillwaringLabel:setVisible(false)

		skillinputNode:registerScriptEditBoxHandler(function (eventType, sender)
			if 'return' == eventType then
				local skillId = sender:getTag()
				local inputText = skillinputNode:getText()
				local errlog = self:IsInputValueInvalid(inputText)
				if errlog then
					skillwaringLabel:setVisible(true)
					skillwaringLabel:setString(errlog)
				else
					local value = checkint(inputText)
					if 1 > value or table.nums(self:GetConfigTable('card', 'skillLevel')) < value then
						skillwaringLabel:setVisible(true)
						skillwaringLabel:setString('超出范围')
					else
						skillwaringLabel:setVisible(false)
						-- 记录缓存
						self.currentEditCardInfo.skills[tostring(skillId)].level = value
					end
				end
			end

		end)
	end

	-- 堕神编辑
	local x = bgNodePos.x - bgNodeSize.width * 0.5 + bgNodeSize.width * 0.275
	local y = bgNodePos.y + 35
	local editPetNodes = {}

	for i, petInfo in ipairs(cardInfo.pets) do
	-- for i, petInfo in ipairs({
	-- 	{petId = 210001, level = 30, breakLevel = 10, character = 1, petp = {{ptype = 1, pquality = 1, pvalue = 8888}, {ptype = 2, pquality = 2, pvalue = 2}, {ptype = 2, pquality = 2, pvalue = 2}, {ptype = 2, pquality = 2, pvalue = 2}}}
	-- }) do
		local layertable = self:GetAPetInfoCell(i, petInfo, cardId)
		display.commonUIParams(layertable.layer, {ap = cc.p(0, 0.5), po = cc.p(x, y)})
		node:addChild(layertable.layer)

		editPetNodes[i] = layertable

		y = y - (#editPetNodes) * 75
	end
	self.currentEditCardPetNodes = editPetNodes

	local addPetBtn = display.newButton(0, 0, {n = BTN_N, cb = function (sender)
		local index = #self.currentEditCardPetNodes + 1
		local petInfo = cardInfo.pets[index]
		self:ShowEditPetView(index, petInfo, cardInfo.cardId)
	end})
	display.commonUIParams(addPetBtn, {po = cc.p(x + addPetBtn:getContentSize().width * 0.5, y)})
	node:addChild(addPetBtn)
	addPetBtn:setTag(5)

	local addPetBtnLabel = self:GetANewLabel(
		{text = '添加宠物'},
		{po = utils.getLocalCenter(addPetBtn)},
		addPetBtn
	)

	-- 保存按钮
	local saveBtn = display.newButton(0, 0, {n = BTN_N, cb = function (sender)
		-- data --
		self.currentFriendTeamData[tostring(teamIdx)] = self.currentEditCardInfo
		self.currentEditCardInfo = nil
		-- data --

		-- view --
		self:RemoveANode(node)
		self:RefreshCardPreviewCell(teamIdx, self.currentFriendTeamData[tostring(teamIdx)])
		-- view --
	end})
	display.commonUIParams(saveBtn, {po = cc.p(
		bgNodePos.x - bgNodeSize.width * 0.5 + 20 + saveBtn:getContentSize().width * 0.5,
		bgNodePos.y - bgNodeSize.height * 0.5 + 115
	)})
	node:addChild(saveBtn, 99)

	local saveBtnLabel = self:GetANewLabel(
		{text = '保存'},
		{po = utils.getLocalCenter(saveBtn)},
		saveBtn
	)

	-- 删除按钮
	local delBtn = display.newButton(0, 0, {n = BTN_N, cb = function (sender)
		-- data --
		self.currentFriendTeamData[tostring(teamIdx)] = nil
		self.currentEditCardInfo = nil
		-- data --

		-- view --
		self:RemoveANode(node)
		self:RefreshCardPreviewCell(teamIdx, self.currentFriendTeamData[tostring(teamIdx)])
		-- view --
	end})
	display.commonUIParams(delBtn, {po = cc.p(
		saveBtn:getPositionX(),
		saveBtn:getPositionY() - saveBtn:getContentSize().height - 10
	)})
	node:addChild(delBtn, 99)

	local delBtnLabel = self:GetANewLabel(
		{text = '删除'},
		{po = utils.getLocalCenter(delBtn)},
		delBtn
	)
end
--[[
显示卡牌编辑信息
@params isEnemy bool 是否是敌军
@params teamIndex int 队伍信息
@params cardIndex int 卡牌序号
@params cardInfo table 卡牌信息
--]]
function DebugBattleScene:ShowEditTeamCardDetailView(isEnemy, teamIndex, cardIndex, cardInfo)
	self.currentEditCardInfo = cardInfo

	local cardId = checkint(cardInfo.cardId)
	local cardConfig = self:GetConfig('card', 'card', cardId)

	-- 显示卡牌编辑信息的界面
	local node = self:GetANewPopLayer()
	node:setTag(EDIT_CARD_DETAIL_TAG)
	local bgNode = node:getChildByTag(3)
	local bgNodePos = cc.p(bgNode:getPositionX(), bgNode:getPositionY())
	local bgNodeSize = bgNode:getContentSize()

	-- 编号
	local teamLabel = self:GetANewLabel(
		{text = tostring(cardIndex)},
		{po = cc.p(bgNodePos.x - bgNodeSize.width * 0.5 + 10, bgNodePos.y + bgNodeSize.height * 0.5 - 10)},
		node
	)

	-- 卡牌头像
	local cardHeadNode = require('common.CardHeadNode').new({
		cardData = cardInfo
	})
	display.commonUIParams(cardHeadNode, {po = cc.p(
		bgNodePos.x - bgNodeSize.width * 0.5 + cardHeadNode:getContentSize().width * 0.5 + 20,
		bgNodePos.y + bgNodeSize.height * 0.5 - cardHeadNode:getContentSize().height * 0.5 - 20
	)})
	node:addChild(cardHeadNode)

	-- 属性预览
	local objppreviewnodes = {}
	for i,v in ipairs(ObjPPreview) do
		-- 属性名字
		local nameLabel = self:GetANewLabel(
			{text = ObjPConfig[v.objp].pname},
			{ap = cc.p(0, 0.5), po = cc.p(bgNodePos.x - bgNodeSize.width * 0.5 + 25, cardHeadNode:getPositionY() - cardHeadNode:getContentSize().height * 0.5 - 50 - (35 * (i - 1)))},
			node
		)

		-- 属性值
		local valueLabel = self:GetANewLabel(
			{text = '0', notTTF = true, color = '#000000'},
			{ap = cc.p(0, 0.5), po = cc.p(nameLabel:getPositionX() + 75, nameLabel:getPositionY())},
			node
		)

		objppreviewnodes[i] = {nameLabel = nameLabel, valueLabel = valueLabel}
	end

	local refreshAllObjPPreview = function ()
		local cardInfo = self.currentEditCardInfo
		local objpinfo = CardUtils.GetCardAllFixedP(
			checkint(cardInfo.cardId),
			checkint(cardInfo.level),
			checkint(cardInfo.breakLevel),
			checkint(cardInfo.favorLevel)
		)

		-- 加上宠物的数值
		for i, petInfo in ipairs(self.currentEditCardInfo.pets) do
			for pidx, pinfo in ipairs(petInfo.petp) do
				-- 判断是否解锁
				local lock = petMgr.GetPetPInfo()[pidx].unlockLevel > petInfo.level
				if not lock then
					local objp = PetPConfig[pinfo.ptype].objp
					objpinfo[objp] = objpinfo[objp] + pinfo.pvalue
				end
			end
		end

		for i,v in ipairs(ObjPPreview) do
			local nodes = objppreviewnodes[i]
			nodes.valueLabel:setString(objpinfo[v.objp])
		end
	end

	refreshAllObjPPreview()
	self.refreshCurrentCardPPreview = refreshAllObjPPreview

	-- 输入星级
	local startitleNode, starinputNode = self:GetATitleAndInputBox(
		'星级',
		{ap = cc.p(0, 0.5), po = cc.p(bgNodePos.x - 110, bgNodePos.y + bgNodeSize.height * 0.5 - 50)},
		node,
		cc.size(80, 50)
	)
	starinputNode:setText(cardInfo.breakLevel)
	local starwaringLabel = self:GetANewLabel(
		{text = '', fontSize = 18, color = '#aa1122', notTTF = true},
		{ap = cc.p(0.5, 0), po = cc.p(starinputNode:getPositionX(), starinputNode:getPositionY() + starinputNode:getContentSize().height * 0.5)},
		node
	)
	starwaringLabel:setVisible(false)

	starinputNode:registerScriptEditBoxHandler(function (eventType)
		if 'return' == eventType then
			local inputText = starinputNode:getText()
			local errlog = self:IsInputValueInvalid(inputText)
			if errlog then
				starwaringLabel:setVisible(true)
				starwaringLabel:setString(errlog)
			else
				local value = checkint(inputText)
				if 1 > value or 5 < value then
					starwaringLabel:setVisible(true)
					starwaringLabel:setString('超出范围')
				else
					starwaringLabel:setVisible(false)
					-- 记录缓存
					self.currentEditCardInfo.breakLevel = value
					-- 刷新属性预览
					refreshAllObjPPreview()
				end
			end
		end
	end)

	-- 输入等级
	local leveltitleNode, levelinputNode = self:GetATitleAndInputBox(
		'等级',
		{ap = cc.p(0, 0.5), po = cc.p(startitleNode:getPositionX(), startitleNode:getPositionY() - 75)},
		node,
		cc.size(80, 50)
	)
	levelinputNode:setText(cardInfo.level)

	local levelwaringLabel = self:GetANewLabel(
		{text = '', fontSize = 18, color = '#aa1122', notTTF = true},
		{ap = cc.p(0.5, 0), po = cc.p(levelinputNode:getPositionX(), levelinputNode:getPositionY() + levelinputNode:getContentSize().height * 0.5)},
		node
	)
	levelwaringLabel:setVisible(false)

	levelinputNode:registerScriptEditBoxHandler(function (eventType)
		if 'return' == eventType then
			local cardlevelconfigTable = self:GetConfigTable('card', 'level')
			local inputText = levelinputNode:getText()
			local errlog = self:IsInputValueInvalid(inputText)
			if errlog then
				levelwaringLabel:setVisible(true)
				levelwaringLabel:setString(errlog)
			else
				local value = checkint(inputText)
				if 1 > value or table.nums(cardlevelconfigTable) < value then
					levelwaringLabel:setVisible(true)
					levelwaringLabel:setString('超出范围')
				else
					local breakLevel = checkint(starinputNode:getText())
					if checkint(cardConfig.breakLevel[breakLevel]) < value then
						levelwaringLabel:setVisible(true)
						levelwaringLabel:setString('星级不足')
					else
						levelwaringLabel:setVisible(false)
						-- 记录缓存
						self.currentEditCardInfo.level = value
						-- 刷新属性预览
						refreshAllObjPPreview()
					end
				end
			end
		end
	end)

	-- 输入好感度等级
	local favortitleNode, favorinputNode = self:GetATitleAndInputBox(
		'好感',
		{ap = cc.p(0, 0.5), po = cc.p(startitleNode:getPositionX(), leveltitleNode:getPositionY() - 75)},
		node,
		cc.size(80, 50)
	)
	favorinputNode:setText(cardInfo.favorLevel)

	local favorwaringLabel = self:GetANewLabel(
		{text = '', fontSize = 18, color = '#aa1122', notTTF = true},
		{ap = cc.p(0.5, 0), po = cc.p(favorinputNode:getPositionX(), favorinputNode:getPositionY() + favorinputNode:getContentSize().height * 0.5)},
		node
	)
	favorwaringLabel:setVisible(false)

	favorinputNode:registerScriptEditBoxHandler(function (eventType)
		if 'return' == eventType then
			local cardfavorconfigTable = self:GetConfigTable('card', 'favorabilityLevel')
			local inputText = favorinputNode:getText()
			local errlog = self:IsInputValueInvalid(inputText)
			if errlog then
				favorwaringLabel:setVisible(true)
				favorwaringLabel:setString(errlog)
			else
				local value = checkint(inputText)
				if 1 > value or table.nums(cardfavorconfigTable) < value then
					favorwaringLabel:setVisible(true)
					favorwaringLabel:setString('超出范围')
				else
					favorwaringLabel:setVisible(false)
					-- 记录缓存
					self.currentEditCardInfo.favorLevel = value
					-- 刷新属性预览
					refreshAllObjPPreview()
				end
			end
		end
	end)

	-- 卡牌技能
	local sortskillkey = sortByKey(cardInfo.skills)
	for i,v in ipairs(sortskillkey) do
		local skillId = checkint(v)
		local skillData = cardInfo.skills[v]
		local skillConfig = self:GetConfig('card', 'skill', skillId)
		local skillIcon = require('common.SkillNode').new({
			id = skillId
		})
		display.commonUIParams(skillIcon, {po = cc.p(
			bgNodePos.x - bgNodeSize.width * 0.5 + bgNodeSize.width * 0.6,
			bgNodePos.y + bgNodeSize.height * 0.5 - 50 - (75 * (i - 1))
		)})
		node:addChild(skillIcon)
		local skillIconScale = 0.4
		skillIcon:setScale(skillIconScale)

		local skillNodeBtn = display.newButton(0, 0, {
			size = cc.size(skillIcon:getContentSize().width * skillIconScale, skillIcon:getContentSize().height * skillIconScale),
			cb = function (sender)
				local skillId = sender:getTag()
				local skillData = self.currentEditCardInfo.skills[tostring(skillId)]
				local skillConfig = self:GetConfig('card', 'skill', skillId)
				uiMgr:ShowInformationTipsBoard({
					targetNode = sender,
					title = skillConfig.name,
					descr = cardMgr.GetSkillDescr(skillId, skillData.level),
					type = 5
				})
			end
		})
		display.commonUIParams(skillNodeBtn, {po = cc.p(
			skillIcon:getPositionX(),
			skillIcon:getPositionY()
		)})
		node:addChild(skillNodeBtn, 99)
		skillNodeBtn:setTag(skillId)

		local skilltitleNode, skillinputNode = self:GetATitleAndInputBox(
			'技能等级',
			{ap = cc.p(0, 0.5), po = cc.p(skillIcon:getPositionX() + skillIcon:getContentSize().width * 0.5 * skillIconScale + 5, skillIcon:getPositionY())},
			node,
			cc.size(80, 50)
		)
		skillinputNode:setText(skillData.level)
		skillinputNode:setTag(skillId)

		local skillwaringLabel = self:GetANewLabel(
			{text = '', fontSize = 18, color = '#aa1122', notTTF = true},
			{ap = cc.p(0.5, 0), po = cc.p(skillinputNode:getPositionX(), skillinputNode:getPositionY() + skillinputNode:getContentSize().height * 0.5)},
			node
		)
		skillwaringLabel:setVisible(false)

		skillinputNode:registerScriptEditBoxHandler(function (eventType, sender)
			if 'return' == eventType then
				local skillId = sender:getTag()
				local inputText = skillinputNode:getText()
				local errlog = self:IsInputValueInvalid(inputText)
				if errlog then
					skillwaringLabel:setVisible(true)
					skillwaringLabel:setString(errlog)
				else
					local value = checkint(inputText)
					if 1 > value or table.nums(self:GetConfigTable('card', 'skillLevel')) < value then
						skillwaringLabel:setVisible(true)
						skillwaringLabel:setString('超出范围')
					else
						skillwaringLabel:setVisible(false)
						-- 记录缓存
						self.currentEditCardInfo.skills[tostring(skillId)].level = value
					end
				end
			end

		end)
	end

	-- 堕神编辑
	local x = bgNodePos.x - bgNodeSize.width * 0.5 + bgNodeSize.width * 0.275
	local y = bgNodePos.y + 35
	local editPetNodes = {}

	for i, petInfo in ipairs(cardInfo.pets) do
	-- for i, petInfo in ipairs({
	-- 	{petId = 210001, level = 30, breakLevel = 10, character = 1, petp = {{ptype = 1, pquality = 1, pvalue = 8888}, {ptype = 2, pquality = 2, pvalue = 2}, {ptype = 2, pquality = 2, pvalue = 2}, {ptype = 2, pquality = 2, pvalue = 2}}}
	-- }) do
		local layertable = self:GetAPetInfoCell(i, petInfo, cardId)
		display.commonUIParams(layertable.layer, {ap = cc.p(0, 0.5), po = cc.p(x, y)})
		node:addChild(layertable.layer)

		editPetNodes[i] = layertable

		y = y - (#editPetNodes) * 75
	end
	self.currentEditCardPetNodes = editPetNodes

	local addPetBtn = display.newButton(0, 0, {n = BTN_N, cb = function (sender)
		local index = #self.currentEditCardPetNodes + 1
		local petInfo = cardInfo.pets[index]
		self:ShowEditPetView(index, petInfo, cardInfo.cardId)
	end})
	display.commonUIParams(addPetBtn, {po = cc.p(x + addPetBtn:getContentSize().width * 0.5, y)})
	node:addChild(addPetBtn)
	addPetBtn:setTag(5)

	local addPetBtnLabel = self:GetANewLabel(
		{text = '添加宠物'},
		{po = utils.getLocalCenter(addPetBtn)},
		addPetBtn
	)

	-- 保存按钮
	local saveBtn = display.newButton(0, 0, {n = BTN_N, cb = function (sender)
		-- data --
		self:SetTeamCardInfo(isEnemy, teamIndex, cardIndex, self.currentEditCardInfo)
		self.currentEditCardInfo = nil
		-- data --

		-- view --
		self:RemoveANode(node)
		self:RefreshTeamCardPreviewCell(isEnemy, teamIndex, cardIndex, self:GetTeamCardInfo(isEnemy, teamIndex, cardIndex))
		-- view --
	end})
	display.commonUIParams(saveBtn, {po = cc.p(
		bgNodePos.x - bgNodeSize.width * 0.5 + 20 + saveBtn:getContentSize().width * 0.5,
		bgNodePos.y - bgNodeSize.height * 0.5 + 115
	)})
	node:addChild(saveBtn, 99)

	local saveBtnLabel = self:GetANewLabel(
		{text = '保存'},
		{po = utils.getLocalCenter(saveBtn)},
		saveBtn
	)

	-- 删除按钮
	local delBtn = display.newButton(0, 0, {n = BTN_N, cb = function (sender)
		-- data --
		self:SetTeamCardInfo(isEnemy, teamIndex, cardIndex, nil)
		self.currentEditCardInfo = nil
		-- data --

		-- view --
		self:RemoveANode(node)
		self:RefreshTeamCardPreviewCell(isEnemy, teamIndex, cardIndex, self:GetTeamCardInfo(isEnemy, teamIndex, cardIndex))
		-- view --
	end})
	display.commonUIParams(delBtn, {po = cc.p(
		saveBtn:getPositionX(),
		saveBtn:getPositionY() - saveBtn:getContentSize().height - 10
	)})
	node:addChild(delBtn, 99)

	local delBtnLabel = self:GetANewLabel(
		{text = '删除'},
		{po = utils.getLocalCenter(delBtn)},
		delBtn
	)
end
--[[
根据队伍序号刷新卡牌预览
@params teamIdx int 队伍序号
@params cardInfo CardInfoStruct 卡牌信息
--]]
function DebugBattleScene:RefreshCardPreviewCell(teamIdx, cardInfo)
	local node = self.customizeCardLayers[teamIdx]
	local layertable = self.customizeCardDetailLayers[teamIdx]

	if nil == cardInfo then
		if layertable then
			layertable.RefreshTeamCard(cardInfo)
		end
	else
		if nil == layertable then
			layertable = self:GetATeamCardPreviewCell(node, cardInfo)
			self.customizeCardDetailLayers[teamIdx] = layertable
		end

		layertable.RefreshTeamCard(cardInfo)
	end

	-- 刷新一次连携技
	for i = 1, MAX_TEAM_MEMBER do
		local cardInfo = self.currentFriendTeamData[tostring(i)]
		if nil ~= cardInfo then
			local cardId = checkint(cardInfo.cardId)	
			local connectSkillId = CardUtils.GetCardConnectSkillId(cardId)
			if nil ~= connectSkillId then
				local layertable = self.customizeCardDetailLayers[i]
				if nil ~= layertable then
					local cardConfig = self:GetConfig('card', 'card', cardId)
					local connectvalid = true
					for _, connectCardId in ipairs(cardConfig.concertSkill) do
						local exist = false
						for k,v in pairs(self.currentFriendTeamData) do
							if checkint(v.cardId) == checkint(connectCardId) then
								exist = true
								break
							end
						end
						if not exist then
							layertable.connectwaringLabel:setVisible(true)
							layertable.connectwaringLabel:setString('未激活')
							connectvalid = false
							break
						end
					end
					if connectvalid then
						layertable.connectwaringLabel:setVisible(false)
					end
				end
			end
		end
	end
end
--[[
根据队伍序号刷新卡牌预览
@params isEnemy bool 是否是敌军
@params teamIndex int 队伍信息
@params cardIndex int 卡牌序号
@params cardInfo CardInfoStruct 卡牌信息
--]]
function DebugBattleScene:RefreshTeamCardPreviewCell(isEnemy, teamIndex, cardIndex, cardInfo)
	local nodes = nil
	local layertables = nil
	local node = nil
	local layertable = nil

	local teamsInfo = nil

	if isEnemy then
		nodes = self.enemyTeamsNodes[teamIndex].customizeCardLayers
		node = nodes[cardIndex]

		layertables = self.enemyTeamsNodes[teamIndex].customizeCardDetailLayers
		layertable = layertables[cardIndex]
	else
		nodes = self.friendTeamsNodes[teamIndex].customizeCardLayers
		node = nodes[cardIndex]

		layertables = self.friendTeamsNodes[teamIndex].customizeCardDetailLayers
		layertable = layertables[cardIndex]
	end

	if nil == cardInfo then
		if layertable then
			layertable.RefreshTeamCard(cardInfo)
		end
	else
		if nil == layertable then
			layertable = self:GetATeamCardPreviewCell(node, cardInfo)
			layertables[cardIndex] = layertable
		end

		layertable.RefreshTeamCard(cardInfo)
	end

	-- 刷新一次连携技
	for i = 1, MAX_TEAM_MEMBER do
		local cardInfo = self:GetTeamCardInfo(isEnemy, teamIndex, i)
		if nil ~= cardInfo then
			local cardId = checkint(cardInfo.cardId)	
			local connectSkillId = CardUtils.GetCardConnectSkillId(cardId)
			if nil ~= connectSkillId then
				local layertable = layertables[i]
				if nil ~= layertable then
					local cardConfig = self:GetConfig('card', 'card', cardId)
					local connectvalid = true
					for _, connectCardId in ipairs(cardConfig.concertSkill) do
						local exist = false
						for k,v in pairs(self:GetTeamInfo(isEnemy, teamIndex)) do
							if checkint(v.cardId) == checkint(connectCardId) then
								exist = true
								break
							end
						end
						if not exist then
							layertable.connectwaringLabel:setVisible(true)
							layertable.connectwaringLabel:setString('未激活')
							connectvalid = false
							break
						end
					end
					if connectvalid then
						layertable.connectwaringLabel:setVisible(false)
					end
				end
			end
		end
	end
end
--[[
根据关卡id刷新界面
@params stageId int 关卡id
--]]
function DebugBattleScene:RefreshStagePreviewUI(stageId)
	local stageConfig = self:GetStageConfigByStageId(stageId)
	if nil ~= stageConfig then
		if nil ~= self.stageDetailLabel then
			self.stageDetailLabel:setString('关卡 -> ' .. tostring(stageId) .. ', 关卡名 -> ' .. stageConfig.name)
			self.stageDetailLabel:setVisible(true)
		end

		if nil ~= self.stageDetailBtn then
			self.stageDetailBtn:setVisible(true)
			display.commonUIParams(self.stageDetailBtn, {po = cc.p(
				self.stageDetailLabel:getPositionX() + display.getLabelContentSize(self.stageDetailLabel).width + 10 + self.stageDetailBtn:getContentSize().width * 0.5,
				self.stageDetailLabel:getPositionY()
			)})
		end

		if nil ~= self.enemyDetailBtn then
			self.enemyDetailBtn:setVisible(true)
			display.commonUIParams(self.enemyDetailBtn, {po = cc.p(
				self.stageDetailBtn:getPositionX() + self.enemyDetailBtn:getContentSize().width + 10,
				self.stageDetailBtn:getPositionY()
			)})
		end
	else
		if nil ~= self.stageDetailLabel then
			self.stageDetailLabel:setString('未找到关卡 -> ' .. tostring(stageId))
			self.stageDetailLabel:setVisible(true)
		end

		if nil ~= self.stageDetailBtn then
			self.stageDetailBtn:setVisible(false)
		end

		if nil ~= self.enemyDetailBtn then
			self.enemyDetailBtn:setVisible(false)
		end
	end
end
--[[
显示编辑堕神界面
@params petIdx int 宠物序号
@params petInfo table 宠物信息
@params cardId int 对应的卡牌id
--]]
function DebugBattleScene:ShowEditPetView(petIdx, petInfo, cardId)
	-- 隐藏编辑卡牌界面
	if nil ~= self:getChildByTag(EDIT_CARD_DETAIL_TAG) then
		self:getChildByTag(EDIT_CARD_DETAIL_TAG):setVisible(false)
	end

	if nil == petInfo then
		-- 为空第一步选宠物
		self:ShowChoosePetLayerForPop(petIdx, cardId)
	else
		-- 不为空显示调整宠物
		self:ShowEditPetDetailView(petIdx, petInfo, cardId)
	end
end
--[[
添加选宠物层
@params petIdx int 宠物序号
--]]
function DebugBattleScene:ShowChoosePetLayerForPop(petIdx, cardId)
	local node = self:GetANewPopLayer()
	node:setTag(CHOOSE_PET_TAG)

	local petsConfigTable = self:GetConfigTable('pet', 'pet')
	local sk = sortByKey(petsConfigTable)

	local bgNode = node:getChildByTag(3)

	local gridViewSize = bgNode:getContentSize()
	local cellPerLine = 5
	local gridViewCellSize = cc.size(gridViewSize.width / cellPerLine, gridViewSize.width / cellPerLine)
	local gridView = CGridView:create(gridViewSize)
	gridView:setAnchorPoint(cc.p(0.5, 0.5))
	gridView:setPosition(utils.getLocalCenter(node))
	node:addChild(gridView, 99)

	gridView:setCountOfCell(table.nums(petsConfigTable))
	gridView:setColumns(cellPerLine)
	gridView:setSizeOfCell(gridViewCellSize)
	gridView:setAutoRelocate(true)
	gridView:setBounceable(true)

	gridView:setDataSourceAdapterScriptHandler(function (c, i)
		local cell = c
		local index = i + 1

		local petId = checkint(sk[index])
		local petConfig = petsConfigTable[tostring(petId)]
		local petData = {
			petId = petId,
			level = 1,
			breakLevel = 1,
			character = nil
		}

		local petHeadNode = nil
		local petNameLabel = nil
		local petIdLabel = nil
		local exNode = nil
		local btn = nil

		if nil == cell then
			cell = CGridViewCell:new()
			cell:setContentSize(gridViewCellSize)

			btn = display.newButton(0, 0, {size = gridViewCellSize, cb = function (sender)
				local index = btn:getParent():getTag()
				local petId = checkint(sk[index])

				self:RemoveANode(node)
				self:ChooseAPet(petIdx, petId, cardId)
			end})
			display.commonUIParams(btn, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(cell)})
			cell:addChild(btn, 99)

			petHeadNode = require('common.PetHeadNode').new({
				petData = petData,
				showBaseState = false,
				showLockState = false
			})
			local scale = (gridViewCellSize.width - 10) / petHeadNode:getContentSize().width
			petHeadNode:setScale(scale)
			display.commonUIParams(petHeadNode, {po = utils.getLocalCenter(cell)})
			cell:addChild(petHeadNode)
			petHeadNode:setTag(3)

			petNameLabel = self:GetANewLabel(
				{text = petConfig.name},
				{po = cc.p(gridViewCellSize.width * 0.5, 25)},
				cell,
				99, 5
			)

			exNode = display.newNSprite(MARK_ICON, 0, 0)
			display.commonUIParams(exNode, {po = cc.p(gridViewCellSize.width - 20, gridViewCellSize.height - 20)})
			cell:addChild(exNode, 99)
			exNode:setTag(7)

			petIdLabel = self:GetANewLabel(
				{text = petId},
				{po = cc.p(gridViewCellSize.width * 0.5, gridViewCellSize.height - 25)},
				cell,
				99, 9
			)
		else
			petHeadNode = cell:getChildByTag(3)
			petNameLabel = cell:getChildByTag(5)
			exNode = cell:getChildByTag(7)
			petIdLabel = cell:getChildByTag(9)
		end

		cell:setTag(index)
		petHeadNode:RefreshUI({petData = petData})
		petNameLabel:setString(petConfig.name)
		petIdLabel:setString(petId)

		exNode:setVisible(false)
		for i,v in ipairs(petConfig.exclusiveCard) do
			if checkint(v) == cardId then
				exNode:setVisible(true)
				break
			end
		end

		return cell

	end)

	gridView:reloadData()
end
--[[
选了一个宠物
@params petIdx int 宠物序号
@params petId int 宠物序号
@params cardId int 卡牌序号
--]]
function DebugBattleScene:ChooseAPet(petIdx, petId, cardId)
	local petInfo = PetInfoStruct.New(petId)
	self:ShowEditPetDetailView(petIdx, petInfo, cardId)
end
--[[
显示编辑宠物界面
@params petIdx int 宠物序号
@params petInfo table 宠物信息
@params cardId int 卡牌序号
--]]
function DebugBattleScene:ShowEditPetDetailView(petIdx, petInfo, cardId)
	self.currentEditPetInfo = petInfo

	local petId = checkint(petInfo.petId)
	local petConfig = self:GetConfig('pet', 'pet', petId)
	local activeExclusive = false
	for i,v in ipairs(petConfig.exclusiveCard) do
		if checkint(v) == cardId then
			activeExclusive = true
			break
		end
	end

	local node = self:GetANewPopLayer()
	node:setTag(EDIT_PET_DETAIL_TAG)
	local bgNode = node:getChildByTag(3)
	local bgNodePos = cc.p(bgNode:getPositionX(), bgNode:getPositionY())
	local bgNodeSize = bgNode:getContentSize()

	local petHeadNode = require('common.PetHeadNode').new({
		petData = petInfo,
		showBaseState = false,
		showLockState = false
	})
	display.commonUIParams(petHeadNode, {po = cc.p(
		bgNodePos.x - bgNodeSize.width * 0.5 + petHeadNode:getContentSize().width * 0.5 + 20,
		bgNodePos.y + bgNodeSize.height * 0.5 - petHeadNode:getContentSize().height * 0.5 - 20
	)})
	node:addChild(petHeadNode)
	petHeadNode:RefreshUI({petData = petInfo})

	-- 属性设置
	local petppreviewnodes = {}

	local refreshAllObjPPreview = function ()
		for i,v in ipairs(petppreviewnodes) do
			-- 属性类型
			local ptype = self.currentEditPetInfo.petp[i].ptype
			local petpconfig = self:GetPetpconfigByptype(ptype)
			v.ptypewaringLabel:setVisible(true)
			v.ptypewaringLabel:setString(petpconfig.name)

			-- 属性品质
			local pquality = self.currentEditPetInfo.petp[i].pquality
			local petpqualityname = PetPQualityName[pquality]
			v.pqualitywaringLabel:setVisible(true)
			v.pqualitywaringLabel:setString(petpqualityname)

			-- 最终的属性值
			local basevalue = self:GetPetpBasevalue(petId, i, ptype, pquality)
			local lock = petMgr.GetPetPInfo()[i].unlockLevel > petInfo.level
			local fixedpetp = petMgr.GetPetFixedPByPetId(
				petId,
				ptype,
				basevalue,
				pquality,
				petInfo.breakLevel,
				petInfo.character,
				activeExclusive
			)
			self.currentEditPetInfo.petp[i].pvalue = fixedpetp
			self.currentEditPetInfo.attr[i].num = basevalue
			local color = PetPColor[pquality]
			v.pvalueLabel:setColor(ccc3FromInt(color))
			local str = fixedpetp .. ' -> 本命激活:' .. (activeExclusive and '是' or '否')
			if lock then
				str = str .. ' !未解锁!'
			end
			v.pvalueLabel:setString(str)
		end
	end

	for i,v in ipairs(petInfo.petp) do
		local pvalueLabel = nil

		-- 属性标题
		local titleLabel = self:GetANewLabel(
			{text = '属性' .. i},
			{ap = cc.p(0, 0.5), po = cc.p(bgNodePos.x - bgNodeSize.width * 0.5 + 35, petHeadNode:getPositionY() - petHeadNode:getContentSize().height * 0.5 - 125 - (75 * (i - 1)))},
			node
		)

		-- 编辑属性类型
		local ptypetitlenode, ptypeinputnode = self:GetATitleAndInputBox(
			'类型',
			{ap = cc.p(0, 0.5), po = cc.p(titleLabel:getPositionX() + display.getLabelContentSize(titleLabel).width + 10, titleLabel:getPositionY())},
			node,
			cc.size(60, 35)
		)
		ptypeinputnode:setText(v.ptype)
		local ptypewaringLabel = self:GetANewLabel(
			{text = '', fontSize = 18, color = '#aa1122', notTTF = true},
			{ap = cc.p(0.5, 0), po = cc.p(ptypeinputnode:getPositionX() + ptypeinputnode:getContentSize().width * 0.5, ptypeinputnode:getPositionY() + ptypeinputnode:getContentSize().height * 0.5 + 5)},
			node
		)
		ptypewaringLabel:setVisible(false)

		ptypeinputnode:registerScriptEditBoxHandler(function (eventType)
			if 'return' == eventType then
				local inputText = ptypeinputnode:getText()
				local errlog = self:IsInputValueInvalid(inputText)
				if errlog then
					ptypewaringLabel:setVisible(true)
					ptypewaringLabel:setString(errlog)
				else
					local value = checkint(inputText)
					local petpconfig = self:GetPetpconfigByptype(value)
					if nil == petpconfig then
						ptypewaringLabel:setVisible(true)
						ptypewaringLabel:setString('属性不存在')
					else
						ptypewaringLabel:setVisible(true)
						-- 记录缓存
						self.currentEditPetInfo.petp[i].ptype = value
						self.currentEditPetInfo.attr[i].type = value
						-- 刷新属性预览
						refreshAllObjPPreview()
					end
				end
			end
		end)

		-- 编辑属性品质
		local pqualitytitlenode, pqualityinputnode = self:GetATitleAndInputBox(
			'品质',
			{ap = cc.p(0, 0.5), po = cc.p(ptypeinputnode:getPositionX() + ptypeinputnode:getContentSize().width + 10, ptypeinputnode:getPositionY())},
			node,
			cc.size(60, 35)
		)
		pqualityinputnode:setText(v.pquality)
		local pqualitywaringLabel = self:GetANewLabel(
			{text = '', fontSize = 18, color = '#aa1122', notTTF = true},
			{ap = cc.p(0.5, 0), po = cc.p(pqualityinputnode:getPositionX() + pqualityinputnode:getContentSize().width * 0.5, pqualityinputnode:getPositionY() + pqualityinputnode:getContentSize().height * 0.5 + 5)},
			node
		)
		pqualitywaringLabel:setVisible(false)

		pqualityinputnode:registerScriptEditBoxHandler(function (eventType)
			if 'return' == eventType then
				local inputText = pqualityinputnode:getText()
				local errlog = self:IsInputValueInvalid(inputText)
				if errlog then
					pqualitywaringLabel:setVisible(true)
					pqualitywaringLabel:setString(errlog)
				else
					local value = checkint(inputText)
					local petpqualityname = PetPQualityName[value]
					if nil == petpqualityname then
						pqualitywaringLabel:setVisible(true)
						pqualitywaringLabel:setString('品质不存在')
					else
						pqualitywaringLabel:setVisible(true)
						-- 记录缓存
						self.currentEditPetInfo.petp[i].pquality = value
						self.currentEditPetInfo.attr[i].quality = value
						-- 刷新属性预览
						refreshAllObjPPreview()
					end
				end
			end
		end)

		-- 属性最终值预览
		pvalueLabel = self:GetANewLabel(
			{text = 'asdad', fontSize = 18, color = '#aa1122', notTTF = true},
			{ap = cc.p(0, 0.5), po = cc.p(pqualityinputnode:getPositionX() + pqualityinputnode:getContentSize().width + 10, pqualityinputnode:getPositionY())},
			node
		)
		-- pvalueLabel:setVisible(false)

		petppreviewnodes[i] = {
			ptypetitlenode = ptypetitlenode,
			ptypeinputnode = ptypeinputnode,
			ptypewaringLabel = ptypewaringLabel,
			pqualitywaringLabel = pqualitywaringLabel,
			pvalueLabel = pvalueLabel
		}
	end

	-- 输入星级
	local startitleNode, starinputNode = self:GetATitleAndInputBox(
		'星级',
		{ap = cc.p(0, 0.5), po = cc.p(bgNodePos.x - 110, bgNodePos.y + bgNodeSize.height * 0.5 - 50)},
		node
	)
	starinputNode:setText(petInfo.breakLevel)
	local starwaringLabel = self:GetANewLabel(
		{text = '', fontSize = 24, color = '#aa1122', notTTF = true},
		{ap = cc.p(0, 0.5), po = cc.p(starinputNode:getPositionX() + 150, starinputNode:getPositionY())},
		node
	)
	starwaringLabel:setVisible(false)

	starinputNode:registerScriptEditBoxHandler(function (eventType)
		if 'return' == eventType then
			local inputText = starinputNode:getText()
			local errlog = self:IsInputValueInvalid(inputText)
			if errlog then
				starwaringLabel:setVisible(true)
				starwaringLabel:setString(errlog)
			else
				local value = checkint(inputText)
				local petbreaklevelconfigTable = self:GetConfigTable('pet', 'petBreak')
				if 1 > value or table.nums(petbreaklevelconfigTable) < value then
					starwaringLabel:setVisible(true)
					starwaringLabel:setString('超出范围')
				else
					starwaringLabel:setVisible(false)
					-- 记录缓存
					self.currentEditPetInfo.breakLevel = value
					-- 刷新属性预览
					refreshAllObjPPreview()
				end
			end
		end
	end)

	-- 输入等级
	local leveltitleNode, levelinputNode = self:GetATitleAndInputBox(
		'等级',
		{ap = cc.p(0, 0.5), po = cc.p(startitleNode:getPositionX(), startitleNode:getPositionY() - 60)},
		node
	)
	levelinputNode:setText(petInfo.level)

	local levelwaringLabel = self:GetANewLabel(
		{text = '', fontSize = 24, color = '#aa1122', notTTF = true},
		{ap = cc.p(0, 0.5), po = cc.p(levelinputNode:getPositionX() + 150, levelinputNode:getPositionY())},
		node
	)
	levelwaringLabel:setVisible(false)

	levelinputNode:registerScriptEditBoxHandler(function (eventType)
		if 'return' == eventType then
			local petlevelconfigTable = self:GetConfigTable('pet', 'level')
			local inputText = levelinputNode:getText()
			local errlog = self:IsInputValueInvalid(inputText)
			if errlog then
				levelwaringLabel:setVisible(true)
				levelwaringLabel:setString(errlog)
			else
				local value = checkint(inputText)
				if 1 > value or table.nums(petlevelconfigTable) < value then
					levelwaringLabel:setVisible(true)
					levelwaringLabel:setString('超出范围')
				else
					levelwaringLabel:setVisible(false)
					-- 记录缓存
					self.currentEditPetInfo.level = value
					-- 刷新一次所有属性的解锁状态
					local unlockinfo = petMgr.GetPetPInfo()
					for i,v in ipairs(self.currentEditPetInfo.petp) do
						if self.currentEditPetInfo.level >= unlockinfo[i].unlockLevel then
							self.currentEditPetInfo.petp[i].unlock = true
						else
							self.currentEditPetInfo.petp[i].unlock = false
						end
					end
					-- 刷新属性预览
					refreshAllObjPPreview()
				end
			end
		end
	end)

	-- 输入好感度等级
	local favortitleNode, favorinputNode = self:GetATitleAndInputBox(
		'性格',
		{ap = cc.p(0, 0.5), po = cc.p(startitleNode:getPositionX(), leveltitleNode:getPositionY() - 60)},
		node
	)
	favorinputNode:setText(petInfo.character)

	local favorwaringLabel = self:GetANewLabel(
		{text = '', fontSize = 16, color = '#aa1122', notTTF = true},
		{ap = cc.p(0, 0.5), po = cc.p(favorinputNode:getPositionX() + 150, favorinputNode:getPositionY())},
		node
	)
	favorwaringLabel:setVisible(false)

	favorinputNode:registerScriptEditBoxHandler(function (eventType)
		if 'return' == eventType then
			local petcharacterconfigTable = self:GetConfigTable('pet', 'petCharacter')
			local inputText = favorinputNode:getText()
			local errlog = self:IsInputValueInvalid(inputText)
			if errlog then
				favorwaringLabel:setVisible(true)
				favorwaringLabel:setString(errlog)
			else
				local value = checkint(inputText)
				local petcharacterconfig = petcharacterconfigTable[tostring(value)]
				if nil == petcharacterconfig then
					favorwaringLabel:setVisible(true)
					favorwaringLabel:setString('未找到性格')
				else

					favorwaringLabel:setVisible(true)
					favorwaringLabel:setString(petcharacterconfig.name .. ' -> ' .. petMgr.GetFixedPetCharacterDescr(value))
					-- 记录缓存
					self.currentEditPetInfo.character = value
					-- 刷新属性预览
					refreshAllObjPPreview()
				end
			end
		end
	end)

	-- 保存按钮
	local saveBtn = display.newButton(0, 0, {n = BTN_N, cb = function (sender)
		dump(self.currentEditPetInfo)
		-- data --
		self.currentEditCardInfo.pets[petIdx] = clone(self.currentEditPetInfo)
		dump(self.currentEditCardInfo)
		-- data --

		-- view --
		self:RemoveANode(node)
		if nil ~= self:getChildByTag(EDIT_CARD_DETAIL_TAG) then
			-- 向卡牌编辑层添加一个宠物
			self:RefreshEditCardDetailByPets()
			self:getChildByTag(EDIT_CARD_DETAIL_TAG):setVisible(true)
		end
		-- view --
	end})
	display.commonUIParams(saveBtn, {po = cc.p(
		bgNodePos.x + bgNodeSize.width * 0.5 - 20 - saveBtn:getContentSize().width * 0.5,
		bgNodePos.y - bgNodeSize.height * 0.5 + 20 + saveBtn:getContentSize().height * 0.5
	)})
	node:addChild(saveBtn, 99)

	local saveBtnLabel = self:GetANewLabel(
		{text = '保存'},
		{po = utils.getLocalCenter(saveBtn)},
		saveBtn
	)

	-- 删除按钮
	local delBtn = display.newButton(0, 0, {n = BTN_N, cb = function (sender)
		-- data --
		table.remove(self.currentEditCardInfo.pets, petIdx)
		dump(self.currentEditCardInfo)
		-- data --

		-- view --
		self:RemoveANode(node)
		if nil ~= self:getChildByTag(EDIT_CARD_DETAIL_TAG) then
			-- 向卡牌编辑层添加一个宠物
			self:RefreshEditCardDetailByPets()
			self:getChildByTag(EDIT_CARD_DETAIL_TAG):setVisible(true)
		end
		-- view --
	end})
	display.commonUIParams(delBtn, {po = cc.p(
		saveBtn:getPositionX() - saveBtn:getContentSize().width - 20,
		saveBtn:getPositionY()
	)})
	node:addChild(delBtn, 99)

	local delBtnLabel = self:GetANewLabel(
		{text = '删除'},
		{po = utils.getLocalCenter(delBtn)},
		delBtn
	)

	refreshAllObjPPreview()
end
--[[
刷新编辑卡牌界面的宠物信息
--]]
function DebugBattleScene:RefreshEditCardDetailByPets()
	local node = self:getChildByTag(EDIT_CARD_DETAIL_TAG):setVisible(true)
	if nil == node then return end

	local bgNode = node:getChildByTag(3)
	local bgNodePos = cc.p(bgNode:getPositionX(), bgNode:getPositionY())
	local bgNodeSize = bgNode:getContentSize()

	local addPetBtn = node:getChildByTag(5)

	for i,layertable in ipairs(self.currentEditCardPetNodes) do
		layertable.layer:removeFromParent()
	end

	self.currentEditCardPetNodes = {}

	local x = bgNodePos.x - bgNodeSize.width * 0.5 + bgNodeSize.width * 0.275
	local y = bgNodePos.y + 35

	for i, petInfo in ipairs(self.currentEditCardInfo.pets) do
		local layertable = self:GetAPetInfoCell(i, petInfo, self.currentEditCardInfo.cardId)
		display.commonUIParams(layertable.layer, {ap = cc.p(0, 0.5), po = cc.p(x, y)})
		node:addChild(layertable.layer)

		self.currentEditCardPetNodes[i] = layertable

		y = y - (editCardPetCellSize.height + 10)
	end

	display.commonUIParams(addPetBtn, {po = cc.p(x + addPetBtn:getContentSize().width * 0.5, y)})

	-- 刷新卡牌属性
	self.refreshCurrentCardPPreview()
end
--[[
加载队伍
@params teamName string 队伍名称
--]]
function DebugBattleScene:LoadFriendTeamByTeamName(teamName)
	local localteamData = self:GetFriendTeamSaveDataByTeamName(teamName)
	dump(localteamData)

	-- data --
	self.currentFriendTeamData = localteamData.teamData
	self.currentFriendTeamName = localteamData.teamName
	self.currentPlayerSkill = localteamData.playerSkill or {
		active = {},
		passive = {}
	}
	-- data --

	-- view --
	for i = 1, MAX_TEAM_MEMBER do
		self:RefreshCardPreviewCell(i, self.currentFriendTeamData[tostring(i)])
	end
	self.teamNameLabel:setString(self.currentFriendTeamName .. ' 下次自动读取 -> ' .. self:GetDefaultLoadTeam())

	for i = 1, MAX_ACTIVE_PLAYER_SKILL do
		self:RefreshActivePlayerSkillNode(i, self.currentPlayerSkill.active[tostring(i)])
	end
	-- view --
end
--[[
显示主角技选择
@params index int 主角技序号
--]]
function DebugBattleScene:ShowChooseActivePlayerSkill(index)
	local active = {}
	local playerskilltable = self:GetConfigTable('player', 'skill')
	for k,v in pairs(playerskilltable) do
		local skillId = checkint(k)
		if 1 == checkint(v.skillType) then
			table.insert(active, {skillId = skillId})
		end
	end

	table.sort(active, function (a, b)
		return a.skillId < b.skillId
	end)

	local tag = 3477
	local layer = require('debug.DebugSelectPlayerSkillPopup').new({
		allSkills = active,
		equipedPlayerSkills = {
			['1'] = {skillId = self.currentPlayerSkill.active['1']},
			['2'] = {skillId = self.currentPlayerSkill.active['2']}
		},
		slotIndex = index,
		tag = tag,
		changeEndCallback = function (index, skillId)
			-- data --
			self.currentPlayerSkill.active[tostring(index)] = skillId
			-- data --
			self:RefreshActivePlayerSkillNode(index, skillId)
			
			uiMgr:GetCurrentScene():RemoveDialogByTag(tag)
		end
	})
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.cx, display.cy)})
	layer:setTag(tag)
	uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
刷新主角技按钮
@params index int 主角技序号
@params skillId int 主角技按钮
--]]
function DebugBattleScene:RefreshActivePlayerSkillNode(index, skillId)
	local skillConfig = self:GetConfig('player', 'skill', skillId)
	local nodes = self.activePlayerSkillNodes[index]

	if 0 == checkint(skillId) or nil == skillConfig then
		nodes.playerSkillNode:RefreshUI({id = 0})
		nodes.nameLabel:setString('未装备')
	else
		nodes.playerSkillNode:RefreshUI({id = skillId})
		nodes.nameLabel:setString(skillConfig.name)
	end
end
--[[
移除某层
@params node cc.node
--]]
function DebugBattleScene:RemoveANode(node)
	node:setVisible(false)
	node:runAction(cc.Sequence:create(
		cc.RemoveSelf:create()
	))
end
--[[
加载队伍
@params isEnemy bool 敌友性
@params teamsName string 队伍名称
--]]
function DebugBattleScene:LoadTeamsByTeamName(isEnemy, teamsName)
	local localteamsData = self:GetLocalTeamsSaveDataByTeamsName(isEnemy, teamsName)

	local teamsNameLabel = nil

	------------ data ------------
	if isEnemy then
		self.currentEditTeamsData.enemy = {}
		for teamIndex, teamInfo in ipairs(localteamsData.teams) do
			table.insert(self.currentEditTeamsData.enemy, teamInfo.teamData)
		end
		self.currentEditTeamsName.enemy = localteamsData.teamsName

		teamsNameLabel = self.enemyTeamNameLabel
	else
		self.currentEditTeamsData.friend = {}
		for teamIndex, teamInfo in ipairs(localteamsData.teams) do
			table.insert(self.currentEditTeamsData.friend, teamInfo.teamData)
		end
		self.currentEditTeamsName.friend = localteamsData.teamsName

		teamsNameLabel = self.friendTeamNameLabel
	end
	------------ data ------------

	------------ view ------------
	teamsNameLabel:setString(localteamsData.teamsName)

	-- 刷新队伍成员
	self:RefreshTeamsInfo(isEnemy, localteamsData)
	------------ view ------------
end
--[[
根据敌友性和队伍信息刷新界面
@params isEnemy bool 敌友性
@params teamsInfo list 队伍信息
--]]
function DebugBattleScene:RefreshTeamsInfo(isEnemy, teamsInfo)
	-- 移除当前所有节点
	local nodes = nil

	local parentNode = nil
	local titleLabel = nil
	local addTeamBtn = nil

	if isEnemy then
		nodes = self.enemyTeamsNodes

		parentNode = self.enemyTeamLayer
		titleLabel = self.enemyTitleLabel
		addTeamBtn = self.enemyAddTeamBtn
	else
		nodes = self.friendTeamsNodes

		parentNode = self.friendTeamLayer
		titleLabel = self.friendTitleLabel
		addTeamBtn = self.friendAddTeamBtn
	end

	for i,v in ipairs(nodes) do
		v.layer:setVisible(false)
		v.layer:runAction(cc.RemoveSelf:create())
	end

	-- 按队伍创建
	local layerSize = parentNode:getContentSize()

	for teamIndex, teamInfo in ipairs(teamsInfo.teams) do
		-- 创建编辑队伍界面
		local layertable = self:CreateATeamEditorLayer(MAX_TEAM_MEMBER)
		display.commonUIParams(layertable.layer, {ap = cc.p(0.5, 1), po = cc.p(
			layerSize.width * 0.5,
			titleLabel:getPositionY() - 55 - (layertable.layer:getContentSize().height * (#nodes))
		)})
		parentNode:addChild(layertable.layer)
		table.insert(nodes, layertable)

		layertable.layer:setTag(teamIndex)

		-- 刷新阵容
		for i = 1, MAX_TEAM_MEMBER, 1 do
			local cardInfo = teamInfo.teamData[i]
			self:RefreshTeamCardPreviewCell(isEnemy, teamIndex, i, cardInfo)
		end
	end

	-- 重置增加队伍按钮
	display.commonUIParams(addTeamBtn, {po = cc.p(
		20 + addTeamBtn:getContentSize().width * 0.5,
		titleLabel:getPositionY() - 55 - addTeamBtn:getContentSize().height * 0.5 - (170 * #nodes)
	)})
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据配表模块和名称和id获取配表数据
@params moduleName string 模块名称
@params configName string 配表名称
@params id int id
@return _ table 配表数据
--]]
function DebugBattleScene:GetConfig(moduleName, configName, id)
	local t = self:GetConfigTable(moduleName, configName)
	if nil ~= t then
		return t[tostring(id)]
	else
		return nil
	end
end
--[[
根据配表模块和名称获取配表数据
@params moduleName string 模块名称
@params configName string 配表名称
@return _ table 配表数据
--]]
function DebugBattleScene:GetConfigTable(moduleName, configName)
	return app.dataMgr:GetConfigDataByFileName(configName, moduleName)
	-- return self:ConvertJsonToLuaByFilePath(self:GetConfigPathByMN(moduleName, configName))
end
--[[
根据配表模块和名称获取配表路径
@params moduleName string 模块名称
@params configName string 配表名称
@return _ configPath 配表路径
--]]
function DebugBattleScene:GetConfigPathByMN(moduleName, configName)
	return '/conf/' .. LANGUAGE_TAG .. '/' .. moduleName .. '/' .. configName .. '.json'
end
--[[
根据配表路径获取配表缓存key
@params path str 配表路径
@return configtableKey string 配表缓存key
--]]
function DebugBattleScene:GetConfigCacheKeyByPath(path)
	local configtableKey = nil
	local ss = string.split(path, '/')
	configtableKey = ss[#ss - 1] .. string.split(ss[#ss], '.')[1] .. '_' .. LANGUAGE_TAG
	return configtableKey
end
--[[
根据配表模块和名称获取配表缓存key
@params moduleName string 模块名称
@params configName string 配表名称
@return _ string 配表缓存key
--]]
function DebugBattleScene:GetConfigCacheKeyByMN(moduleName, configName)
	return self:GetConfigCacheKeyByPath(self:GetConfigPathByMN(moduleName, configName))
end
--[[
获取指定路径的配表lua结构
@params filePath string 文件路径
@return _ table 配表lua结构
--]]
function DebugBattleScene:ConvertJsonToLuaByFilePath(filePath)
	local configtableKey = self:GetConfigCacheKeyByPath(filePath)
	if nil == self.configTables[configtableKey] then
		-- 读取一次文件
		local file = assert(io.open(filePath, 'r'), self:GetErrorLog(string.format('cannot find config json file -> %s', filePath)))
		local fileContent = file:read('*a')
		local configtable = json.decode(fileContent)
		file:close()
		self.configTables[configtableKey] = configtable
	end
	return self.configTables[configtableKey]
end
--[[
错误输出
@params content str 输出内容
--]]
function DebugBattleScene:GetErrorLog(content)
	local log = ''
	log = log .. '\n\n--------------------\n↓↓↓ERROR↓↓↓\n--------------------\n     ' .. content .. '\n'
	return log
end
--[[
根据关卡id获取关卡配置
@params stageId int 关卡id
@return stageConfig table 关卡信息
--]]
function DebugBattleScene:GetStageConfigByStageId(stageId)
	local stageConfigInfo = self:GetStageConfigInfoByStageId(stageId)
	local stageConfig = nil
	if nil ~= stageConfigInfo then
		stageConfig = self:GetConfig(stageConfigInfo.moduleName, stageConfigInfo.configName, stageId)
	end
	return stageConfig
end
--[[
根据关卡id获取关卡规则信息
@params stageId int 关卡id
@return info table 关卡规则信息
--]]
function DebugBattleScene:GetStageConfigInfoByStageId(stageId)
	local stageId_ = checkint(stageId)
	local info = nil
	for k,v in pairs(stageConfigInfo) do
		if v.low < stageId_ and v.up > stageId_ then
			info = v
			break
		end
	end
	return info
end
--[[
判断输入的值是否合法
@params inputText string 输入值
@return errlog string 错误信息
--]]
function DebugBattleScene:IsInputValueInvalid(inputText)
	local errlog = nil
	if nil == tonumber(inputText) then
		errlog = '格式不正确'
	else
		local value = tonumber(inputText)
		if 0 < value - math.floor(value) then
			errlog = '必须是整数'
		end
	end

	return errlog
end
--[[
根据宠物属性类型id获取属性配置
@params ptype int 宠物属性id
@return _ table 属性配置
--]]
function DebugBattleScene:GetPetpconfigByptype(ptype)
	return PetPConfig[ptype]
end
--[[
根据宠物id 属性序号 属性品质获取配表中的基础值
@params petId int 宠物id
@params petpIdx int 属性序号
@params ptype int 属性类型
@params pquality int 属性品质
@return basevalue int 基础值
--]]
function DebugBattleScene:GetPetpBasevalue(petId, petpIdx, ptype, pquality)
	local basevalue = 0
	local petConfig = self:GetConfig('pet', 'pet', petId)
	if nil == petConfig then return basevalue end
	return petConfig.attr[tostring(petpIdx)].attrNum[pquality][ptype]
end
--[[
获取本地文件中的队伍信息
--]]
function DebugBattleScene:GetLocalFriendTeamSaveData()
	local str = cc.UserDefault:getInstance():getStringForKey(LOCAL_TEAM_SAVE_DATA, '')
	if 0 < string.len(str) then
		return json.decode(str).friendteams
	else
		return {}
	end
end
--[[
获取排序后的本地文件队伍信息
--]]
function DebugBattleScene:GetSortLocalFriendTeamSaveData()
	local teamSaveDatalua = self:GetLocalFriendTeamSaveData()
	local t_ = {}
	for k,v in pairs(teamSaveDatalua) do
		table.insert(t_, v)
	end
	table.sort(t_, function (a, b)
		return checkint(a.saveTime) > checkint(b.saveTime)
	end)
	return t_
end
--[[
保存当前配置到本地
--]]
function DebugBattleScene:SaveCurrentFriendTeamToLocal()
	local teamData = self.currentFriendTeamData
	local teamName = self.currentFriendTeamName or 'default'
	local playerSkill = self.currentPlayerSkill
	if 0 >= string.len(string.gsub(teamName, ' ', '')) then
		teamName = 'default'
	end

	local str = cc.UserDefault:getInstance():getStringForKey(LOCAL_TEAM_SAVE_DATA, '')
	local newStr = nil
	local teamSaveDatalua = nil

	if 0 < string.len(str) then
		teamSaveDatalua = json.decode(str)
		teamSaveDatalua.friendteams[tostring(teamName)] = TeamSaveDataStruct.New(teamName, teamData)
		teamSaveDatalua.friendteams[tostring(teamName)].saveTime = os.time()
		teamSaveDatalua.friendteams[tostring(teamName)].teamName = teamName

		teamSaveDatalua.friendteams[tostring(teamName)].playerSkill = playerSkill
	else
		-- 初始化一次
		teamSaveDatalua = TeamsSaveDataStruct.New()
		teamSaveDatalua.friendteams[tostring(teamName)] = TeamSaveDataStruct.New(teamName, teamData)
		teamSaveDatalua.friendteams[tostring(teamName)].saveTime = os.time()
		teamSaveDatalua.friendteams[tostring(teamName)].teamName = teamName

		teamSaveDatalua.friendteams[tostring(teamName)].playerSkill = playerSkill
	end

	-- 记录一次默认队伍
	teamSaveDatalua.defaultfriendteam = teamName

	newStr = json.encode(teamSaveDatalua)

	if nil ~= newStr then
		cc.UserDefault:getInstance():setStringForKey(LOCAL_TEAM_SAVE_DATA, newStr)
		cc.UserDefault:getInstance():flush()
	end
end
--[[
删除队伍
@params teamName string 队伍名称
--]]
function DebugBattleScene:DeleteFriendTeamByTeamName(teamName)
	local teamsSaveData = self:GetLocalFriendTeamSaveData()
	if nil ~= teamsSaveData[tostring(teamName)] then
		local str = cc.UserDefault:getInstance():getStringForKey(LOCAL_TEAM_SAVE_DATA, '')
		local teamSaveDatalua = json.decode(str)
		teamSaveDatalua.friendteams[tostring(teamName)] = nil

		if teamName == tostring(teamSaveDatalua.defaultfriendteam) then
			teamSaveDatalua.defaultfriendteam = ''
		end

		local newStr = json.encode(teamSaveDatalua)
		cc.UserDefault:getInstance():setStringForKey(LOCAL_TEAM_SAVE_DATA, newStr)
		cc.UserDefault:getInstance():flush()

		self.teamNameLabel:setString(self.currentFriendTeamName .. ' 下次自动读取 -> ' .. self:GetDefaultLoadTeam())
	end
end
--[[
删除队伍
@params isEnemy bool 敌友性
@params teamsName string 队伍名称
--]]
function DebugBattleScene:DeleteTeamsByTeamsName(isEnemy, teamsName)
	local teamsSaveData = nil
	if isEnemy then
		teamsSaveData = self:GetLocalTeamsSaveData().enemy
	else
		teamsSaveData = self:GetLocalTeamsSaveData().friend
	end

	if nil ~= teamsSaveData[tostring(teamsName)] then
		local str = cc.UserDefault:getInstance():getStringForKey(LOCAL_TEAMS_SAVE_DATA, '')
		local teamsSaveDatalua = json.decode(str)

		if isEnemy then
			teamsSaveDatalua.teams.enemy[tostring(teamsName)] = nil
		else
			teamsSaveDatalua.teams.friend[tostring(teamsName)] = nil
		end

		local newStr = json.encode(teamsSaveDatalua)
		cc.UserDefault:getInstance():setStringForKey(LOCAL_TEAMS_SAVE_DATA, newStr)
		cc.UserDefault:getInstance():flush()

		local defaultTeamsName = self:GetDefaultLoadTeamsName(isEnemy)
		if defaultTeamsName == teamsName then
			self:SaveDefaultLoadTeams(isEnemy, '')
		end

		local teamsNameLabel = nil

		if isEnemy then
			teamsNameLabel = self.enemyTeamNameLabel
		else
			teamsNameLabel = self.friendTeamNameLabel
		end

		teamsNameLabel:setString(self:GetDefaultLoadTeamsName(isEnemy))
	end
end
--[[
保存默认读取的队伍
@params teamName string
--]]
function DebugBattleScene:SaveDefaultLoadTeam(teamName)
	local str = cc.UserDefault:getInstance():getStringForKey(LOCAL_TEAM_SAVE_DATA, '')
	local teamSaveDatalua = json.decode(str)
	teamSaveDatalua.defaultfriendteam = teamName
	newStr = json.encode(teamSaveDatalua)

	cc.UserDefault:getInstance():setStringForKey(LOCAL_TEAM_SAVE_DATA, newStr)
	cc.UserDefault:getInstance():flush()
end
--[[
获取默认读取的队伍
@return teamName string 
--]]
function DebugBattleScene:GetDefaultLoadTeam()
	local str = cc.UserDefault:getInstance():getStringForKey(LOCAL_TEAM_SAVE_DATA, '')
	if 0 < string.len(str) then
		local teamSaveDatalua = json.decode(str)
		return teamSaveDatalua.defaultfriendteam
	else
		return ''
	end
end
--[[
保存默认读取的队伍
@params isEnemy bool 敌友性
@params teamsName string
--]]
function DebugBattleScene:SaveDefaultLoadTeams(isEnemy, teamsName)
	local str = cc.UserDefault:getInstance():getStringForKey(LOCAL_TEAMS_SAVE_DATA, '')
	local teamsSaveDatalua = json.decode(str)
	if isEnemy then
		teamsSaveDatalua.defaultTeamsName.enemy = teamsName
	else
		teamsSaveDatalua.defaultTeamsName.friend = teamsName
	end
	newStr = json.encode(teamsSaveDatalua)

	cc.UserDefault:getInstance():setStringForKey(LOCAL_TEAMS_SAVE_DATA, newStr)
	cc.UserDefault:getInstance():flush()
end
--[[
获取默认读取的队伍
@params ieEnemy bool 敌友性
@return teamName string 
--]]
function DebugBattleScene:GetDefaultLoadTeamsName(isEnemy)
	local str = cc.UserDefault:getInstance():getStringForKey(LOCAL_TEAMS_SAVE_DATA, '')
	if 0 < string.len(str) then
		local teamsSaveDatalua = json.decode(str)
		if isEnemy then
			return teamsSaveDatalua.defaultTeamsName.enemy
		else
			return teamsSaveDatalua.defaultTeamsName.friend
		end
	else
		return ''
	end
end
--[[
根据队伍名称获取队伍信息
@params teamName string 队伍名称
@return teamData table 队伍信息
--]]
function DebugBattleScene:GetFriendTeamSaveDataByTeamName(teamName)
	return self:GetLocalFriendTeamSaveData()[tostring(teamName)]
end
--[[
根据卡牌信息获取战斗力
@params cardInfo table 卡牌信息
@return battlePoint int 卡牌战斗力
--]]
function DebugBattleScene:GetCardStaticBattlePoint(cardInfo)
	local battlePoint = 0
	local cardId = checkint(cardInfo.cardId)
	local level = checkint(cardInfo.level)
	local breakLevel = checkint(cardInfo.breakLevel)
	local favorLevel = checkint(cardInfo.favorLevel)

	------------ 卡牌基础属性 ------------
	local fixedCardPInfo = CardUtils.GetCardAllFixedP(cardId, level, breakLevel, favorLevel)
	------------ 卡牌基础属性 ------------

	------------ 卡牌宠物属性 ------------
	for _, petInfo in ipairs(cardInfo.pets) do
		for _, pinfo in ipairs(petInfo.petp) do
			if pinfo.unlock then
				fixedCardPInfo[PetPConfig[pinfo.ptype].objp] = fixedCardPInfo[PetPConfig[pinfo.ptype].objp] + pinfo.pvalue
			end
		end
	end
	------------ 卡牌宠物属性 ------------

	------------ 根据最终属性计算卡牌战斗力 ------------
	battlePoint = math.floor(fixedCardPInfo[ObjP.ATTACK] * 10 
		+ fixedCardPInfo[ObjP.DEFENCE] * 16.7 
		+ fixedCardPInfo[ObjP.HP] * 1
		+ (fixedCardPInfo[ObjP.CRITRATE] - 100) * 0.17 
		+ (fixedCardPInfo[ObjP.CRITDAMAGE] - 100) * 0.118
		+ (fixedCardPInfo[ObjP.ATTACKRATE] - 100) * 0.109)
	------------ 根据最终属性计算卡牌战斗力 ------------

	return battlePoint
end
--[[
根据敌友性 队伍序号 获取队伍信息
@params isEnemy bool 敌友性
@params teamIndex int 队伍序号
@return _ list 队伍信息
--]]
function DebugBattleScene:GetTeamInfo(isEnemy, teamIndex)
	if isEnemy then
		return self.currentEditTeamsData.enemy[teamIndex]
	else
		return self.currentEditTeamsData.friend[teamIndex]
	end
end
function DebugBattleScene:SetTeamInfo(isEnemy, teamIndex, teamInfo)
	if isEnemy then
		self.currentEditTeamsData.enemy[teamIndex] = teamInfo
	else
		self.currentEditTeamsData.friend[teamIndex] = teamInfo
	end
end
function DebugBattleScene:DelTeamInfo(isEnemy, teamIndex)
	if isEnemy then
		table.remove(self.currentEditTeamsData.enemy, teamIndex)
	else
		table.remove(self.currentEditTeamsData.friend, teamIndex)
	end
end
--[[
根据敌友性 队伍序号 卡牌序号获取卡牌信息
@params isEnemy bool 敌友性
@params teamIndex int 队伍序号
@params cardIndex int 卡牌序号
@return _ table 卡牌信息
--]]
function DebugBattleScene:GetTeamCardInfo(isEnemy, teamIndex, cardIndex)
	local teamInfo = self:GetTeamInfo(isEnemy, teamIndex)
	if nil ~= teamInfo then
		return teamInfo[cardIndex]
	else
		return nil
	end
end
function DebugBattleScene:SetTeamCardInfo(isEnemy, teamIndex, cardIndex, cardInfo)
	local teamInfo = self:GetTeamInfo(isEnemy, teamIndex)
	if nil == teamInfo then
		self:SetTeamData(isEnemy, teamIndex, {})
	end
	if isEnemy then
		self.currentEditTeamsData.enemy[teamIndex][cardIndex] = cardInfo
	else
		self.currentEditTeamsData.friend[teamIndex][cardIndex] = cardInfo
	end
end
--[[
根据敌友性获取本地保存的队伍数据
@params isEnemy bool 敌友性
--]]
function DebugBattleScene:GetLocalTeamsSaveData()
	local str = cc.UserDefault:getInstance():getStringForKey(LOCAL_TEAMS_SAVE_DATA, '')
	if 0 < string.len(str) then
		return json.decode(str).teams
	else
		return nil
	end
end
--[[
根据敌友性和队伍名字获取本地保存的队伍数据
@params isEnemy bool 敌友性
@params teamsName string 队伍名字
--]]
function DebugBattleScene:GetLocalTeamsSaveDataByTeamsName(isEnemy, teamsName)
	local data = self:GetLocalTeamsSaveData()
	if nil ~= data then
		if isEnemy then
			return data.enemy[tostring(teamsName)]
		else
			return data.friend[tostring(teamsName)]
		end
	else
		return nil
	end
end
--[[
获取排序后的本地文件队伍信息
@params isEnemy bool 敌友性
--]]
function DebugBattleScene:GetSortLocalTeamsSaveData(isEnemy)
	local data = self:GetLocalTeamsSaveData()

	if nil ~= data then
		local t_ = {}
		local t__ = nil

		if isEnemy then
			t__ = data.enemy
		else
			t__ = data.friend
		end

		for k,v in pairs(t__) do
			table.insert(t_, v)
		end
		table.sort(t_, function (a, b)
			return checkint(a.saveTime) > checkint(b.saveTime)
		end)
		return t_
	end

	return {}
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- new node begin --
---------------------------------------------------
--[[
根据配置获取文字
@params p table {
	text string 文字内容
	fontSize int 文字大小
	color int 文字颜色
	notTTF bool 是否是ttf
}
@params posInfo table {
	ap cc.p 锚点
	po cc.p 位置
}
@params parentNode cc.node 父节点
@params ... addChild -> 变长参数
--]]
function DebugBattleScene:GetANewLabel(p, posInfo, parentNode, ...)
	local params = {
		text = p.text,
		fontSize = p.fontSize or 24,
		color = p.color or '#ffffff',
		font = 'font/FZCQJW.TTF',
		ttf = not p.notTTF,
		outline = '#311717'
	}
	local label = display.newLabel(0, 0, params)
	if nil ~= posInfo then
		display.commonUIParams(label, posInfo)
	end
	if nil ~= parentNode then
		parentNode:addChild(label, ...)
	end
	return label
end
--[[
获取一个输入框
@params size cc.size 大小
@params hintStr string 提示文字
@return node cc.node 输入框节点
--]]
function DebugBattleScene:GetANewInputBox(size, hintStr)
	local boxSize = size or cc.size(125, 50)
	local node = ccui.EditBox:create(boxSize, COMMON_BG)
	node:setFontSize(28)
	node:setFontColor(ccc3FromInt('#000000'))
	node:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	node:setPlaceHolder(tostring(hintStr or ''))
	node:setPlaceholderFontSize(28)
	node:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
	node:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)

	return node
end
--[[
获取一个显示信息的滑动层
@params text string 文字
@params size cc.size 文本框大小
--]]
function DebugBattleScene:ShowATextScrollView(text, size)
	local size_ = size or cc.size(700, 600)
	local layer = self:GetANewPopLayer(size_)

	local bgImg = layer:getChildByTag(3)

	local textLabel = self:GetANewLabel(
		{text = text, fontSize = 18, notTTF = true, color = '#000000'},
		nil,
		nil
	)

	local scrollView = CScrollView:create(size_)
	scrollView:setDirection(eScrollViewDirectionVertical)
	scrollView:setAnchorPoint(cc.p(0.5, 0.5))
	scrollView:setPosition(cc.p(bgImg:getPositionX(), bgImg:getPositionY()))
	scrollView:setContainerSize(cc.size(size_.width, display.getLabelContentSize(textLabel).height))
	layer:addChild(scrollView)
	-- scrollView:setBackgroundColor(cc.c4b(255, 0, 0, 200))

	display.commonUIParams(textLabel, {ap = cc.p(0, 1), po = cc.p(
		0, scrollView:getContainerSize().height
	)})
	scrollView:getContainer():addChild(textLabel)
	scrollView:getContainer():setPositionY(size_.height - display.getLabelContentSize(textLabel).height)

end
--[[
获取一个通用的弹出层
@params size cc.size 尺寸
--]]
function DebugBattleScene:GetANewPopLayer(size)
	local size_ = size or cc.size(700, 600)
	local layer = display.newLayer(0, 0, {size = self:getContentSize()})
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(self)})
	self:addChild(layer)
	layer:setBackgroundColor(cc.c4b(0, 0, 0, 178))

	local closeBtn = display.newButton(0, 0, {size = layer:getContentSize(), cb = function (sender)
		self:RemoveANode(layer)
		if nil ~= self:getChildByTag(EDIT_CARD_DETAIL_TAG) then
			local aa = self:getChildByTag(EDIT_CARD_DETAIL_TAG)
			if EDIT_PET_DETAIL_TAG == layer:getTag() or
				CHOOSE_PET_TAG == layer:getTag() then
				aa:setVisible(true)
			end
		end
	end})
	display.commonUIParams(closeBtn, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(layer)})
	layer:addChild(closeBtn)

	local bgImg = display.newImageView(COMMON_BG, 0, 0, {scale9 = true, size = size_})
	local coverBtn = display.newButton(0, 0, {size = size_})
	display.commonUIParams(coverBtn, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(layer)})
	layer:addChild(coverBtn)

	display.commonUIParams(bgImg, {po = utils.getLocalCenter(layer)})
	layer:addChild(bgImg)
	bgImg:setTag(3)

	return layer
end
--[[
获取一个左文字 + 右输入框的组合
@params title string 左边文字
@params size cc.size 大小
@params hintStr string 提示文字
@params posInfo table 位置信息
@params parentNode cc.node 父节点
@return titleNode, inputNode cc.node, cc.node 标题文字节点, 输入框节点 
--]]
function DebugBattleScene:GetATitleAndInputBox(title, posInfo, parentNode, size, hintStr)
	local titleNode = self:GetANewLabel(
		{text = title or '请输入'},
		posInfo,
		parentNode
	)
	local inputNode = self:GetANewInputBox(size)
	parentNode:addChild(inputNode)

	self:FixedInputNodePosByTitleNode(titleNode, inputNode)

	return titleNode, inputNode
end
--[[
根据titleNode位置校准inputNode位置
@params titleNode cc.node
@params inputNode cc.node
--]]
function DebugBattleScene:FixedInputNodePosByTitleNode(titleNode, inputNode)
	display.commonUIParams(inputNode, {ap = cc.p(0, 0.5), po = cc.p(
		titleNode:getPositionX() + (display.getLabelContentSize(titleNode).width * (1 - titleNode:getAnchorPoint().x)) + 20,
		titleNode:getPositionY() + (display.getLabelContentSize(titleNode).height * (0.5 - titleNode:getAnchorPoint().y))
	)})
end
--[[
根据宠物信息获取一个宠物信息cell结构
@params petIdx int 宠物序号
@params petInfo PetInfoStruct 宠物信息
@params cardId int 卡牌id
@params layertable table
--]]
function DebugBattleScene:GetAPetInfoCell(petIdx, petInfo, cardId)
	local layer = display.newLayer(0, 0, {size = editCardPetCellSize})
	layer:setBackgroundColor(cc.c4b(75, 75, 128, 178))

	local btn = display.newButton(0, 0, {size = editCardPetCellSize, cb = function ()
		print('here check fuck index<<<<<<<<<<<', petIdx)
		self:ShowEditPetView(petIdx, petInfo, cardId)
	end})
	display.commonUIParams(btn, {po = utils.getLocalCenter(layer)})
	layer:addChild(btn, 99)

	local petHeadNode = require('common.PetHeadNode').new({
		petData = petInfo,
		showBaseState = true,
		showLockState = false
	})
	petHeadNode:RefreshUI({petData = petInfo})
	local petHeadNodeScale = (editCardPetCellSize.height - 10) / petHeadNode:getContentSize().width
	petHeadNode:setScale(petHeadNodeScale)
	display.commonUIParams(petHeadNode, {po = cc.p(20 + petHeadNode:getContentSize().width * 0.5 * petHeadNodeScale, editCardPetCellSize.height * 0.5)})
	layer:addChild(petHeadNode)

	local petConfig = self:GetConfig('pet', 'pet', petInfo.petId)
	local activeExclusive = false
	for i,v in ipairs(petConfig.exclusiveCard) do
		if checkint(v) == cardId then
			activeExclusive = true
			break
		end
	end

	local exNode = display.newNSprite(MARK_ICON, 0, 0)
	display.commonUIParams(exNode, {po = cc.p(10, editCardPetCellSize.height - 10)})
	layer:addChild(exNode, 99)
	exNode:setVisible(activeExclusive)

	-- 属性信息
	local pinfonodes = {}
	for i, petpinfo in ipairs(petInfo.petp) do
		local pnameLabel = self:GetANewLabel(
			{text = ObjPConfig[self:GetPetpconfigByptype(petpinfo.ptype).objp].pname, notTTF = true, fontSize = 14, color = '#000000'},
			{ap = cc.p(0, 0.5), po = cc.p(petHeadNode:getPositionX() + petHeadNode:getContentSize().width * 0.5 * petHeadNodeScale + 10 + (90 * (i - 1)), petHeadNode:getPositionY())},
			layer
		)

		local pvalueLabel = self:GetANewLabel(
			{text = petpinfo.pvalue, notTTF = true, fontSize = 14, color = PetPColor[petpinfo.pquality]},
			{ap = cc.p(0, 0.5), po = cc.p(pnameLabel:getPositionX() + 30, pnameLabel:getPositionY())},
			layer
		)

		pinfonodes = {pnameLabel = pnameLabel, pvalueLabel = pvalueLabel}
	end

	local layertable = {
		layer = layer,
		pinfonodes = pinfonodes
	}

	return layertable
end
--[[
获取一个卡牌编队信息预览cell
@params parentNode cc.node 父节点
@params cardInfo table
@return layertable table
--]]
function DebugBattleScene:GetATeamCardPreviewCell(parentNode, cardInfo)
	local cardId = cardInfo.cardId

	local size = parentNode:getContentSize()
	local layer = display.newLayer(0, 0, {size = size})
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(parentNode)})
	parentNode:addChild(layer, 99)
	layer:setTag(13)

	-- 卡牌头像
	local cardHeadNode = require('common.CardHeadNode').new({
		cardData = cardInfo,
		showBaseState = true,
		showActionState = false,
		showVigourState = false
	})
	display.commonUIParams(cardHeadNode, {ap = cc.p(0, 1), po = cc.p(
		15,
		size.height - 15
	)})
	layer:addChild(cardHeadNode)
	local cardHeadNodeScale = 0.5
	cardHeadNode:setScale(cardHeadNodeScale)

	-- 战斗力
	local battlePointLabel = self:GetANewLabel(
		{text = self:GetCardStaticBattlePoint(cardInfo)},
		{ap = cc.p(0, 0.5), po = cc.p(cardHeadNode:getPositionX() + cardHeadNode:getContentSize().width * cardHeadNodeScale, cardHeadNode:getPositionY())},
		layer
	)

	local connectSkillId = CardUtils.GetCardConnectSkillId(cardId)
	local connectSkillNode = require('common.SkillNode').new({
		id = connectSkillId
	})
	display.commonUIParams(connectSkillNode, {ap = cc.p(1, 0), po = cc.p(size.width - 10, 10)})
	layer:addChild(connectSkillNode)
	connectSkillNode:setScale(cardHeadNodeScale)
	connectSkillNode:setVisible(nil ~= connectSkillId)

	local connectSkillBtn = display.newButton(0, 0, {
		size = cc.size(connectSkillNode:getContentSize().width * cardHeadNodeScale, connectSkillNode:getContentSize().height * cardHeadNodeScale),
		cb = function (sender)
			local cardId = sender:getTag()
			if nil ~= CardUtils.GetCardConnectSkillId(cardId) then
				local cardConfig = self:GetConfig('card', 'card', cardId)
				local connectStr = ''
				for i,v in ipairs(cardConfig.concertSkill) do
					local ccardId = checkint(v)
					local ccardConfig = self:GetConfig('card', 'card', ccardId)
					if nil ~= ccardConfig then
						connectStr = connectStr .. ccardConfig.name .. ','
					else
						connectStr = connectStr .. '???,'
					end
				end
				uiMgr:ShowInformationTipsBoard({
					targetNode = sender,
					title = '连携对象',
					descr = connectStr,
					type = 5
				})
			end
		end
	})
	display.commonUIParams(connectSkillBtn, {
		ap = connectSkillNode:getAnchorPoint(),
		po = cc.p(connectSkillNode:getPositionX(), connectSkillNode:getPositionY())
	})
	layer:addChild(connectSkillBtn, 99)
	connectSkillBtn:setTag(cardInfo.cardId)

	local connectwaringLabel = self:GetANewLabel(
		{text = '', fontSize = 16, notTTF = true, color = '#aa1122'},
		{ap = cc.p(0.5, 1), po = cc.p(connectSkillNode:getPositionX() - connectSkillNode:getContentSize().width * 0.5 * cardHeadNodeScale, connectSkillNode:getPositionY() + 10)},
		layer
	)

	local RefreshTeamCard = function (cardInfo)
		if nil == cardInfo then
			layer:setVisible(false)
		else
			layer:setVisible(true)
			cardHeadNode:RefreshUI({
				cardData = cardInfo,
				showBaseState = true
			})

			battlePointLabel:setString(self:GetCardStaticBattlePoint(cardInfo))

			local csid = CardUtils.GetCardConnectSkillId(cardInfo.cardId)
			connectSkillNode:RefreshUI({id = csid})
			connectSkillNode:setVisible(nil ~= csid)

			connectSkillBtn:setTag(cardInfo.cardId)
			connectSkillBtn:setVisible(connectSkillNode:isVisible())

			-- 刷新战斗力
			self:RefreshBattlePointLabel()
		end
	end

	local layertable = {
		layer = layer,
		RefreshTeamCard = RefreshTeamCard,
		connectwaringLabel = connectwaringLabel
	}

	return layertable
end
--[[
创建一队编辑队伍
@params maxTeamMember int 最大队伍人数
@return layertable table 节点集合
--]]
function DebugBattleScene:CreateATeamEditorLayer(maxTeamMember)
	local customizeCardLayerSize = cc.size(225, 150)
	local cardPerLine = 5

	local layerSize = cc.size(
		display.width,
		(customizeCardLayerSize.height + 20) * math.ceil(maxTeamMember / cardPerLine)
	)

	local layer = display.newLayer(0, 0, {size = layerSize})
	-- layer:setBackgroundColor(cc.c4b(math.random(255), math.random(255), math.random(255), 128))

	local upTeamBtn = display.newButton(0, 0, {n = BTN_N, cb = handler(self, self.UpTeamBtnClickHandler)})
	display.commonUIParams(upTeamBtn, {po = cc.p(
		layerSize.width - upTeamBtn:getContentSize().width * 0.5,
		layerSize.height - upTeamBtn:getContentSize().height * 0.5
	)})
	upTeamBtn:setScale(0.75)
	layer:addChild(upTeamBtn)
	local saveTeamBtnLabel = self:GetANewLabel(
		{text = '↑'},
		{po = utils.getLocalCenter(upTeamBtn)},
		upTeamBtn
	)

	local downTeamBtn = display.newButton(0, 0, {n = BTN_N, cb = handler(self, self.DownTeamBtnClickHandler)})
	display.commonUIParams(downTeamBtn, {po = cc.p(
		upTeamBtn:getPositionX(),
		upTeamBtn:getPositionY() - upTeamBtn:getContentSize().height * 0.75
	)})
	downTeamBtn:setScale(0.75)
	layer:addChild(downTeamBtn)
	local saveTeamBtnLabel = self:GetANewLabel(
		{text = '↓'},
		{po = utils.getLocalCenter(downTeamBtn)},
		downTeamBtn
	)

	local delTeamBtn = display.newButton(0, 0, {n = BTN_N, cb = handler(self, self.DelTeamBtnHandler)})
	display.commonUIParams(delTeamBtn, {po = cc.p(
		downTeamBtn:getPositionX(),
		downTeamBtn:getPositionY() - downTeamBtn:getContentSize().height * 0.75
	)})
	delTeamBtn:setScale(0.75)
	layer:addChild(delTeamBtn)
	local saveTeamBtnLabel = self:GetANewLabel(
		{text = '删除队伍'},
		{po = utils.getLocalCenter(delTeamBtn)},
		delTeamBtn
	)

	local customizeCardLayers = {}
	for i = 1, maxTeamMember do
		local customizeCardLayerBtn = display.newLayer(0, 0, {size = customizeCardLayerSize})
		display.commonUIParams(customizeCardLayerBtn, {ap = cc.p(0.5, 1), po = cc.p(
			(customizeCardLayerSize.width + 20) * ((i - 1) % cardPerLine + 1 - 0.5),
			layerSize.height - (customizeCardLayerSize.height + 20) * (math.ceil(i / cardPerLine) - 1)
		)})
		layer:addChild(customizeCardLayerBtn)
		customizeCardLayerBtn:setTag(i)

		local btn = display.newButton(0, 0, {size = customizeCardLayerSize, cb = handler(self, self.EditTeamCardBtnClickHandler)})
		display.commonUIParams(btn, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(customizeCardLayerBtn)})
		customizeCardLayerBtn:addChild(btn, 99)
		btn:setTag(3)

		local bgImg = display.newImageView(COMMON_BG, 0, 0, {scale9 = true, size = cc.size(customizeCardLayerSize.width + 5, customizeCardLayerSize.height + 5)})
		display.commonUIParams(bgImg, {po = utils.getLocalCenter(customizeCardLayerBtn)})
		customizeCardLayerBtn:addChild(bgImg)

		local noLabel = self:GetANewLabel(
			{text = tostring(i)},
			{ap = cc.p(0, 1), po = cc.p(0, customizeCardLayerSize.height)},
			customizeCardLayerBtn
		)

		customizeCardLayers[i] = customizeCardLayerBtn
	end

	local layertable = {
		layer 						= layer,
		upTeamBtn 					= upTeamBtn,
		downTeamBtn 				= downTeamBtn,
		delTeamBtn 					= delTeamBtn,
		customizeCardLayers 		= customizeCardLayers,
		customizeCardDetailLayers 	= {}
	}

	return layertable
end
---------------------------------------------------
-- new node end --
---------------------------------------------------

function DebugBattleScene:DebugRandom()
	-- debug --
	local debugrandom = __Require('battle.controller.RandomManagerNew').new()
	debugrandom:SetRandomseed(checkint(string.reverse(os.time())))

	local randomValues = {}

	local range = 100
	local amount = 10000


	print('\n\n====================== start random ======================\n\n')
	for i = 1, amount do
		table.insert(randomValues, debugrandom:GetRandomInt(range))
	end
	print('\n\n====================== over random ======================\n\n')

	print('\n\n====================== start draw random ======================\n\n')
	-- 先框出坐标系
	local borderColor = cc.c4b(0, 0, 0, 1)
	local borderLen = math.min(display.width, display.height) * 0.75
	local ox = display.cx - borderLen * 0.5
	local oy = display.cy - borderLen * 0.5

	local drawNode = cc.DrawNode:create()
	self:addChild(drawNode, 999)
	drawNode:setPosition(cc.p(0, 0))

	drawNode:drawLine(
		cc.p(ox, oy),
		cc.p(ox + borderLen, oy),
		borderColor
	)

	drawNode:drawLine(
		cc.p(ox + borderLen, oy),
		cc.p(ox + borderLen, oy + borderLen),
		borderColor
	)

	drawNode:drawLine(
		cc.p(ox + borderLen, oy + borderLen),
		cc.p(ox, oy + borderLen),
		borderColor
	)

	drawNode:drawLine(
		cc.p(ox, oy + borderLen),
		cc.p(ox, oy),
		borderColor
	)

	for i = 1, amount, 2 do
		local x = randomValues[i]
		local y = randomValues[i + 1]

		print(x, y)

		local posx = ox + borderLen * (x / range)
		local posy = oy + borderLen * (y / range)

		drawNode:drawPoint(cc.p(posx, posy), 2, cc.c4b(math.random(255), math.random(255), math.random(255), 255))
	end

	print('\n\n====================== end draw random ======================\n\n')
	-- debug --
end

return DebugBattleScene
