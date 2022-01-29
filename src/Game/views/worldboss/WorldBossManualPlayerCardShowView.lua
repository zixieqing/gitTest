--[[
 * descpt : 世界BOSS手册 界面
    @params playerInfo  table  玩家数据
    @params title       string 阵容标题
    @params damageTip   string 伤害提示
    
]]
local VIEW_SIZE = display.size
local WorldBossManualPlayerCardShowView = class('WorldBossManualPlayerCardShowView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.union.WorldBossManualPlayerCardShowView'
	node:enableNodeEvents()
	return node
end)

local uiMgr             = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')

local CreateView         = nil
local CreateRankRoleView = nil

local getRankTextByRank  = nil

local RES_DIR = {
    BACK                             = _res("ui/common/common_btn_back"),
    BOOSSTRATEGY_RANKS_BG            = _res("ui/worldboss/manual/boosstrategy_ranks_bg.png"),
    RANKS_NAME_BG                    = _res('ui/worldboss/manual/boosstrategy_ranks_name_bg.png'),
}

local BUTTON_TAG = {
    BACK      = 100, 
    RULE      = 101,
}

local WORLD_BOSS_MANUAL_ENABLED_LIST = 'WORLD_BOSS_MANUAL_ENABLED_LIST'

function WorldBossManualPlayerCardShowView:ctor( ... )
    local data = unpack({...}) or {}
    self.args = data.playerInfo
    self.playerDamage = self.args.playerDamage
    self.title = data.title or __('他(她)的狩猎阵容')
    self.damageTip = data.damageTip or __('历史最高伤害')
    -- self:setSwallowTouches(false)
    self:initialUI()

    AppFacade.GetInstance():DispatchObservers(WORLD_BOSS_MANUAL_ENABLED_LIST, {isEnabled = false})
end

function WorldBossManualPlayerCardShowView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(self.args)
        self:addChild(self.viewData_.view)
        self.viewData_.titleLabel:setString(self.title)
        display.commonLabelParams(self.viewData_.damageTipLabel, {text = self.damageTip})
        self:initView()
        self:refreshView(self.args)
        display.commonUIParams(self:getViewData().backBtn, {cb = handler(self, self.onClickBackBtnAction)})
	end, __G__TRACKBACK__)
end

function WorldBossManualPlayerCardShowView:initView()
    local viewData = self:getViewData()
    local avatarNodes = viewData.avatarNodes

    for i, avatarNode in ipairs(avatarNodes) do
        local avatarBtn = avatarNode.avatarBtn
        display.commonUIParams(avatarBtn, {cb = handler(self, self.onClickAvatarAction)})
        avatarBtn:setTag(i)
    end
end

function WorldBossManualPlayerCardShowView:refreshView(data)
    local viewData = self:getViewData()
    -- logInfo.add(5, tableToString(data))
    self.data = data
    self:updateRankRoleView(viewData, data)

    if self.playerDamage then
        viewData.playerDamageLabel:setVisible(true)
        viewData.damageTipLabel:setVisible(true)
        
        self:updatePlayerDamageLabel(viewData)
    else
        viewData.playerDamageLabel:setVisible(false)
        viewData.damageTipLabel:setVisible(false)
    end

    self:updateAvatarNodes(viewData, data)
    
end

function WorldBossManualPlayerCardShowView:updateRankRoleView(viewData, data)
    local rankRoleView      = viewData.rankRoleView
    local rankRoleViewData  = rankRoleView.viewData

    -- update player head
    local playerHeadNode = rankRoleViewData.playerHeadNode
    playerHeadNode:RefreshUI({
        avatar = data.playerAvatar,
        avatarFrame = data.playerAvatarFrame,
        playerLevel = data.playerLevel,
    })

    -- update player rank
    local playerRank = checkint(data.playerRank)
    local rankLabel      = rankRoleViewData.rankLabel
    display.commonLabelParams(rankLabel, {text = getRankTextByRank(playerRank)})

    -- update base img
    local baseImg        = rankRoleViewData.baseImg
    local imgPath        = string.format('ui/worldboss/manual/boosstrategy_ico_ranking_%s.png', playerRank)
    baseImg:setTexture(_res(imgPath))

    -- update avatar light
    local avatarLight    = rankRoleViewData.avatarLight
    avatarLight:setVisible(playerRank == 1)

    -- update  player name
    local playerName     = data.playerName
    local nameLabel      = rankRoleViewData.nameLabel
    display.commonLabelParams(nameLabel, {text = tostring(playerName)})
end

--[[
历史最高伤害
--]]
function WorldBossManualPlayerCardShowView:updatePlayerDamageLabel(viewData, data)
    display.commonLabelParams(viewData.playerDamageLabel, {text = tostring(self.playerDamage)})
end

--[[
更新avatar nodes
--]]
function WorldBossManualPlayerCardShowView:updateAvatarNodes(viewData, data)
    local fight_num         = viewData.fight_num
    local avatarNodes       = viewData.avatarNodes
    local playerCards       = data.playerCards or {}
    
    if next(playerCards) == nil then
		for i, v in ipairs(avatarNodes) do
			self:ClearAvatarNode(i)
		end
	else
		for i = 1, MAX_TEAM_MEMBER_AMOUNT do
			local v = playerCards[i]
			if v then
				local cardData = v
				if nil ~= cardData and 0 ~= checkint(cardData.cardId) then
					local skinId = nil
					if nil == cardData.defaultSkinId then
						skinId = CardUtils.GetCardSkinId(checkint(cardData.cardId))
					else
						skinId = checkint(cardData.defaultSkinId)
					end

					self:RefreshAvatarSpine(i, skinId)
					self:RefreshConnectSkillNode(i, checkint(cardData.cardId))
				end
			else
				-- 移除卡牌
				self:ClearAvatarNode(i)
			end
		end
	end
	
	-- 刷新一次连携技按钮
	self:RefreshAllConnectSkillState(playerCards)
end

--[[
清空卡牌节点
--]]
function WorldBossManualPlayerCardShowView:ClearAvatarNode(teamIndex)
    local viewData       = self:getViewData()
    local avatarNodes    = viewData.avatarNodes
	local nodes = avatarNodes[teamIndex]
	if nil ~= nodes.avatarSpine then
		nodes.avatarSpine:removeFromParent()
		avatarNodes[teamIndex].avatarSpine = nil
	end
	if nil ~= nodes.connectSkillNode then
		nodes.connectSkillNode:removeFromParent()
		avatarNodes[teamIndex].connectSkillNode = nil
	end
	if nil ~= nodes.avatarLight then
		nodes.avatarLight:setVisible(true)
	end
	if nil ~= nodes.avatarBtn then
		nodes.avatarBtn:setVisible(false)
	end
end

--[[
根据序号 卡牌皮肤 刷新卡牌spine小人
@params teamIdx int 编队序号
@params skinId int 皮肤id
--]]
function WorldBossManualPlayerCardShowView:RefreshAvatarSpine(teamIdx, skinId)
    local viewData       = self:getViewData()
    local avatarNodes    = viewData.avatarNodes
    local nodes = avatarNodes[teamIdx]
	if nil ~= nodes.avatarSpine then
		nodes.avatarSpine:removeFromParent()
		avatarNodes[teamIdx].avatarSpine = nil
	end

	if nil ~= nodes.avatarLight then
		nodes.avatarLight:setVisible(false)
	end
	if nil ~= nodes.avatarBtn then
		nodes.avatarBtn:setVisible(true)
	end

    ------------ 卡牌spine小人 ------------
    local avatarSpine = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 0.5})
	avatarSpine:update(0)
	-- avatarSpine:setScaleX(1)
	avatarSpine:setAnimation(0, 'idle', true)
	avatarSpine:setPosition(cc.p(
		nodes.bg:getContentSize().width * 0.5,
		nodes.bg:getContentSize().height * 0.5 + 5
	))
	nodes.bg:addChild(avatarSpine, 5)
    avatarSpine:setScale(0.9)
	avatarNodes[teamIdx].avatarSpine = avatarSpine
	------------ 卡牌spine小人 ------------
end

--[[
根据序号 卡牌id 刷新卡牌连携技按钮
@params teamIdx int 编队序号
@params cardId int 卡牌id
--]]
function WorldBossManualPlayerCardShowView:RefreshConnectSkillNode(teamIdx, cardId)
    local viewData       = self:getViewData()
    local avatarNodes    = viewData.avatarNodes
    local nodes          = avatarNodes[teamIdx]

	if nil ~= nodes.connectSkillNode then
		nodes.connectSkillNode:removeFromParent()
		avatarNodes[teamIdx].connectSkillNode = nil
	end

	------------ 卡牌连携技按钮 ------------
	local connectSkillId = CardUtils.GetCardConnectSkillId(cardId)
	if nil ~= connectSkillId then
		local skillNode = self:GetAConnectSkillNodeBySkillId(connectSkillId)
		display.commonUIParams(skillNode, {po = cc.p(
			nodes.bg:getContentSize().width * 0.5,
			nodes.bg:getContentSize().height * 0.5 + 5
		)})
		nodes.bg:addChild(skillNode, 10)

		avatarNodes[teamIdx].connectSkillNode = skillNode
	end
	------------ 卡牌连携技按钮 ------------
end
--[[
根据技能id获取一个连携技图标
@params skillId int 技能id
--]]
function WorldBossManualPlayerCardShowView:GetAConnectSkillNodeBySkillId(skillId)
	local node = display.newImageView(_res('ui/home/teamformation/team_ico_skill_circle.png'), 0, 0)

	local skillIcon = display.newImageView(_res(CommonUtils.GetSkillIconPath(skillId)), 0, 0)
	skillIcon:setScale((node:getContentSize().width - 10) / skillIcon:getContentSize().width)
	display.commonUIParams(skillIcon, {po = utils.getLocalCenter(node)})
	skillIcon:setTag(3)
	node:addChild(skillIcon, -1)

	skillIcon:setColor(cc.c4b(100, 100, 100, 100))

	return node
end
--[[
刷新一次所有连携技状态
--]]
function WorldBossManualPlayerCardShowView:RefreshAllConnectSkillState(playerCards)
	local battlePoint = 0
	for i,cardData in ipairs(playerCards) do
        -- 连携技状态
        self:RefreshConnectSkillNodeState(i, playerCards)

        -- 计算一次战斗力
        -- battlePoint = battlePoint + cardMgr.GetCardStaticBattlePointById(v.id)
        battlePoint = battlePoint + cardMgr.GetCardStaticBattlePointByCardData(cardData)
    end
    
    local viewData       = self:getViewData()
    local fight_num         = viewData.fight_num
	-- 设置战斗力标签
	fight_num:setString(tostring(battlePoint))
end

--[[
刷新连携技状态
@params teamIdx int 队伍序号
@params cardId int 卡牌id
--]]
function WorldBossManualPlayerCardShowView:RefreshConnectSkillNodeState(teamIdx, playerCards)
    local viewData       = self:getViewData()
    local avatarNodes    = viewData.avatarNodes
    local nodes          = avatarNodes[teamIdx]

    local cardData       = playerCards[teamIdx]
    local cardId         = checkint(cardData.cardId)

	if nil ~= nodes.connectSkillNode then
		local skillEnable = CardUtils.IsConnectSkillEnable(cardId, playerCards)
		if skillEnable then
			nodes.connectSkillNode:getChildByTag(3):setColor(cc.c4b(255, 255, 255, 255))
		else
			nodes.connectSkillNode:getChildByTag(3):setColor(cc.c4b(100, 100, 100, 100))
		end
	end
end

CreateView = function (data)
    local view = display.newLayer()
    local size = view:getContentSize()
    
    view:addChild(display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true}))

    -------------------------------------
    -- top
    local topUILayer = display.newLayer()
    view:addChild(topUILayer, 1)

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DIR.BACK})
    topUILayer:addChild(backBtn)
    -------------------------------------
    -- content
    local contentUILayer = display.newLayer()
    view:addChild(contentUILayer)

    local rankRoleView = CreateRankRoleView()
    display.commonUIParams(rankRoleView, {po = cc.p(display.cx - 370, display.cy + 190), ap = display.CENTER})
    contentUILayer:addChild(rankRoleView)

    local damageTipLabel = display.newLabel(display.cx - 90, display.cy + 210, fontWithColor(19, {ap = display.CENTER, fontSize = 30, color = '#ffffff', outline = '#5b3c25', outlineSize = 1}))
    contentUILayer:addChild(damageTipLabel)

    local titleLabel = display.newLabel(display.cx - 443, display.cy + 40, {ap = display.LEFT_CENTER, fontSize = 22, color = '#e0c5a5', font = TTF_GAME_FONT, ttf = true, text = ''})
    contentUILayer:addChild(titleLabel)

    local playerDamageLabel = display.newLabel(display.cx - 90, display.cy + 150, {text = 22222, ap = display.CENTER, fontSize = 50, color = '#ffb71d', font = TTF_GAME_FONT, ttf = true})
    contentUILayer:addChild(playerDamageLabel)
    
    local fireSpine = sp.SkeletonAnimation:create('effects/fire/skeleton.json', 'effects/fire/skeleton.atlas', 1)
	fireSpine:update(0)
    fireSpine:setAnimation(0, 'huo', true)
    fireSpine:setPosition(cc.p(display.cx + 360, display.cy + 20))
	contentUILayer:addChild(fireSpine)

	local fight_num = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', '')
    display.commonUIParams(fight_num, {ap = cc.p(0.5, 0.5), po = cc.p(fireSpine:getPositionX(), fireSpine:getPositionY() + 10)})
	fight_num:setHorizontalAlignment(display.TAR)
    fight_num:setScale(0.7)
    fight_num:setString(2000)
	contentUILayer:addChild(fight_num, 1)

    local cardsBg = display.newLayer(display.cx, display.cy - 120, {ap = display.CENTER, bg = RES_DIR.BOOSSTRATEGY_RANKS_BG})
    local cardsBgSize = cardsBg:getContentSize()
    contentUILayer:addChild(cardsBg)
    
	-- local teamMarkPosSign = 1
    local p = nil
    local avatarNodes = {}
    
    local goodParams = {goodNodeSize = cc.size(140, cardsBgSize.height), midPointX = cardsBgSize.width / 2, midPointY = cardsBgSize.height * 0.5 - 100, col = MAX_TEAM_MEMBER_AMOUNT, maxCol = MAX_TEAM_MEMBER_AMOUNT, scale = 1, goodGap = 30}
    for i = 1, MAX_TEAM_MEMBER_AMOUNT do
        goodParams.index = i
		p = CommonUtils.getGoodPos(goodParams)
        
		local avatarBgPath = 'ui/common/tower_bg_team_base.png'
		if 1 == i then
			avatarBgPath = 'ui/common/tower_bg_team_base_cap.png'
		end
		local avatarBg = display.newImageView(_res(avatarBgPath),
			p.x,
			p.y)
        cardsBg:addChild(avatarBg, 20 + i % 2)

		local avatarLight = display.newImageView(_res('ui/common/tower_prepare_bg_light.png'), 0, 0)
		display.commonUIParams(avatarLight, {po = cc.p(
			utils.getLocalCenter(avatarBg).x,
			utils.getLocalCenter(avatarBg).y + avatarLight:getContentSize().height * 0.5
		)})
		avatarBg:addChild(avatarLight, 10)

        -- 透明按钮
		local avatarBtn = display.newButton(0, 0, {size = cc.size(150, 200)})
		display.commonUIParams(avatarBtn, {po = cc.p(
			avatarBg:getPositionX(),
			avatarBg:getPositionY() + avatarBtn:getContentSize().height * 0.5
		), animate = false})
		avatarBg:getParent():addChild(avatarBtn, avatarBg:getLocalZOrder())
		avatarBtn:setTag(i)
        avatarBtn:setVisible(false)
        
		-- debug --
		-- local l = display.newLayer(avatarBtn:getPositionX(), avatarBtn:getPositionY(), {size = avatarBtn:getContentSize(), ap = avatarBtn:getAnchorPoint()})
		-- l:setBackgroundColor(cc.c4b(math.random(255), math.random(255), math.random(255), 100))
		-- avatarBtn:getParent():addChild(l, avatarBtn:getLocalZOrder())
		-- debug --
		if 1 == i then
			-- 添加队长标记
			local captainMark = display.newNSprite(_res('ui/home/teamformation/team_ico_captain.png'), 0, 0)
			display.commonUIParams(captainMark, {po = cc.p(
				avatarBg:getPositionX() - (avatarBg:getContentSize().width * 0.5 + 20),
				avatarBg:getPositionY() - 5
			)})
			captainMark:setName('captainMark')
			cardsBg:addChild(captainMark, 100)
		end

		avatarNodes[i] = {bg = avatarBg, avatarLight = avatarLight, avatarBtn = avatarBtn, avatarSpine = nil, connectSkillNode = nil}
    end
    
    local cardInfoTipLabel = display.newLabel(size.width * 0.5, cardsBg:getPositionY() - 160, fontWithColor(18, {text = __('点击飨灵查看详细信息')}))
    contentUILayer:addChild(cardInfoTipLabel)

    return {
        view              = view,
        backBtn           = backBtn,
        rankRoleView      = rankRoleView,
        playerDamageLabel = playerDamageLabel,
        fight_num         = fight_num,
        avatarNodes       = avatarNodes,
        titleLabel        = titleLabel,
        damageTipLabel    = damageTipLabel,
    }
end

CreateRankRoleView = function (rank, playerHeadData, playerName)
    local layerSize = cc.size(140, 170)
    local layer = display.newLayer(0, 0, {size = layerSize})

    local rankLabel = display.newLabel(layerSize.width / 2, layerSize.height - 20, {ap = display.CENTER, fontSize = 24, font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
    layer:addChild(rankLabel)

    local playerHeadNode = require('common.PlayerHeadNode').new({showLv = true})
    display.commonUIParams(playerHeadNode, {po = cc.p(layerSize.width / 2, layerSize.height - 78), ap = display.CENTER})
    playerHeadNode:setScale(0.5)
    layer:addChild(playerHeadNode, 1)

    -- local imgPath = string.format('ui/worldboss/manual/boosstrategy_ico_ranking_%s.png', rank)
    local baseImg = display.newImageView('', layerSize.width / 2, 50, {ap = display.CENTER})
    layer:addChild(baseImg)

    -- if rank == 1 then
    local avatarLight = display.newImageView(_res('ui/common/tower_prepare_bg_light.png'), 0, 0)
    display.commonUIParams(avatarLight, {po = cc.p(65, 15), ap = display.CENTER_BOTTOM})
    avatarLight:setScale(0.8)
    baseImg:addChild(avatarLight)
    avatarLight:setVisible(false)
    -- end

    local nameBg = display.newImageView(RES_DIR.RANKS_NAME_BG, layerSize.width / 2, 28, {ap = display.CENTER_TOP})
    local nameBgSize = nameBg:getContentSize()
    layer:addChild(nameBg)

    local nameLabel = display.newLabel(nameBgSize.width / 2, nameBgSize.height / 2, {ap = display.CENTER, color = '#ffffff', fontSize = 20, text = tostring(playerName)})
    nameBg:addChild(nameLabel)

    layer.viewData = {
        playerHeadNode = playerHeadNode,
        rankLabel      = rankLabel,
        baseImg        = baseImg,
        avatarLight    = avatarLight,
        nameLabel      = nameLabel,
    }
    return layer
end

function WorldBossManualPlayerCardShowView:getViewData()
	return self.viewData_
end

function WorldBossManualPlayerCardShowView:onClickBackBtnAction(sender)
    AppFacade.GetInstance():DispatchObservers(WORLD_BOSS_MANUAL_ENABLED_LIST, {isEnabled = true})
    if self and not tolua.isnull(self) then
        uiMgr:GetCurrentScene():RemoveDialog(self)
    end
end

function WorldBossManualPlayerCardShowView:onClickAvatarAction(sender)
    local index         = sender:getTag()
    local playerCards   = self.data.playerCards or {}

    local cardData = playerCards[index]
    local skinId = nil
    if nil == cardData.defaultSkinId then
        skinId = CardUtils.GetCardSkinId(checkint(cardData.cardId))
    else
        skinId = checkint(cardData.defaultSkinId)
    end
    local playerCardDetailData = {
        cardData = {
            breakLevel = cardData.breakLevel,
            cardId     = cardData.cardId,
            favorLevel = cardData.favorabilityLevel,
            level      = cardData.level,
            skinId     = skinId,
			artifactTalent = cardData.artifactTalent,
            bookLevel = cardData.bookLevel,
            equippedHouseCatGene = cardData.equippedHouseCatGene,
        },
        petsData = cardData.pets,
        playerData = {
            playerAvatar      = self.data.playerAvatar,
            playerAvatarFrame = self.data.playerAvatarFrame,
            playerId          = self.data.playerId,
            playerLevel       = self.data.playerLevel,
            playerName        = self.data.playerName,
        },
        viewType = 1,
    }
    local playerCardDetailView = require('Game.views.raid.PlayerCardDetailView').new(playerCardDetailData)
    playerCardDetailView:setTag(2222)
    display.commonUIParams(playerCardDetailView, {ap = cc.p(0.5, 0.5), po = cc.p(
        display.cx, display.cy
    )})
    uiMgr:GetCurrentScene():AddDialog(playerCardDetailView)
    -- logInfo.add(5, tableToString(cardData))
end

getRankTextByRank = function (rank)
    local text = ''
    if rank == 1 then
        text = __('第一名')
    elseif rank == 2 then
        text = __('第二名')
    elseif rank == 3 then
        text = __('第三名')
    end
    return text
end

return WorldBossManualPlayerCardShowView