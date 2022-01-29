--[[
 * descpt : 创建工会 home 界面
]]

local TagMatchLobbyView = class('TagMatchLobbyView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.TagMatchLobbyView'
	node:enableNodeEvents()
	return node
end)

local CreateView             = nil
local CreatePlayerTeamHeadBg = nil
local CreateDragAreaLayer    = nil
local CreateTeamNode         = nil

local RES_DIR = {
    BG                    = _res("ui/tagMatch/3v3_bg.png"),
    BACK                  = _res("ui/common/common_btn_back"),
    TITLE                 = _res('ui/common/common_title.png'),
    BTN_TIPS              = _res('ui/common/common_btn_tips.png'),
    SCORE_BAR             = _res('ui/tower/tower_btn_myscore.png'),
    BTN_RANK              = _res('ui/home/nmain/main_btn_rank.png'),

    -------------------
    -- attack team res
    ATTACKTEAM_BG_TEAM    = _res("ui/tagMatch/team_frame_touxiangkuang.png"),
    ATTACKTEAM_BG_TEAM_S  = _res("ui/tagMatch/team_img_touxiangkuang_xuanzhong.png"),
    ATTACKTEAM_LINE       = _res("ui/tagMatch/3v3_attackteam_line.png"),
    ATTACKTEAM_MEMBER_BG  = _res("ui/tagMatch/3v3_attackteam_member_bg.png"),
    ATTACKTEAM_NUM        = _res("ui/tagMatch/3v3_attackteam_num.png"),
    BTN_ORANGE            = _res('ui/common/common_btn_orange.png'),
    ATTACKTEAM_TITLE      = _res('ui/common/common_title_5.png'),

    -------------------
    -- oppoent res
    OPPONENT_BG           = _res("ui/tagMatch/3v3_bg_opponent.png"),
    TIME_BG               = _res("ui/tagMatch/3v3_bg_time_.png"),
    REFRESH               = _res('ui/pvc/pvp_board_btn_report.png'),
    OPPONENT_BG_2         = _res("ui/tagMatch/3v3_bg_opponent_2.png"),
    OPPONENT_INFO_TEXT    = _res("ui/tagMatch/3v3_info_bg_text.png"),
    
    -- oppoent cell
    OPPONENT_CELL_BG_NONE = _res('ui/tagMatch/3v3_opponent_bg_none.png'),
    OPPONENT_CELL_BG      = _res("ui/tagMatch/3v3_opponent_bg.png"),
    OPPONENT_CELL_INFO_BG = _res("ui/tagMatch/3v3_opponent_info.png"),
    OPPONENT_CELL_SELECT = _res('ui/mail/common_bg_list_selected.png'),

    INFO_BG               = _res("ui/tagMatch/3v3_info_bg.png"),
    BLEW_FIGHT_BG         = _res("ui/tagMatch/3v3_bg_below_fight.png"),
    ATTACKTEAM_BG         = _res("ui/tagMatch/3v3_attackteam_bg.png"),
    FAIL_NUMBER_BLANK     = _res("ui/tagMatch/3v3_fail_number_blank.png"),
    FAIL_NUMBER_X         = _res("ui/tagMatch/3v3_fail_number_x.png"),
    INFO_ICO_LINE         = _res("ui/tagMatch/3v3_info_ico_line.png"),
    SHIELD_BG             = _res("ui/tagMatch/3v3_shield_bg.png"),
    SHIELD_DEFAULT        = _res("ui/tagMatch/3v3_Shield_default.png"),
    SHIELD_EFFECT_1       = _res("ui/tagMatch/3v3_Shield_effect_1.png"),
    SHIELD_LATTICE_1      = _res("ui/tagMatch/3v3_shield_layer_1.png"),
    SHIELD_LATTICE_2      = _res("ui/tagMatch/3v3_shield_layer_2.png"),
    SHIELD_LATTICE_3      = _res("ui/tagMatch/3v3_shield_layer_3.png"),

    ICON_SHOP             = _res('ui/tagMatch/3v3_ico_pvpstore'),
    LOADING_BG            = _res('ui/tagMatch/3v3_shield_bg_loading'),
}

local BUTTON_TAG = {
    BACK        = 100,
    SHIELD      = 101,
    MODIFY      = 102,
    FIGHT       = 103,
    REPORT      = 104,
    REFRESH     = 105,
    SHOP        = 106,
    RANK        = 107,
}

local OPPONENT_INFO_STATE = {
    NOT_ELIMINATE                         = 0,      -- 没有被淘汰
    ELIMINATE_AND_NOT_OPPONENT_NOT_SWORD  = 1,      -- 被淘汰 并且 没有对手 并且 没有进攻生命
    ELIMINATE_AND_NOT_OPPONENT_NOT_SHIELD = 2       -- 被淘汰 并且 没有对手 并且 没有防守生命
}

function TagMatchLobbyView:ctor( ... )
    self.args = unpack({...})
    self:initialUI()
end

function TagMatchLobbyView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self:getViewData().view)
	end, __G__TRACKBACK__)
end

function TagMatchLobbyView:refreshUI(data, teamId)
    
    -- 更新倒计时
    self:updateCountDown(data.leftSeconds)

    -- 更新对手信息
    self:updateOpponentInfo(data)

    -- -- 更新对手列表
    -- self:updateOppoentList(data.enemyList)

    -- 更新玩家当前的排名
    self:updateCurRankLabel(data.rank)

    -- 更新玩家进攻胜利次数
    self:updateWinTimes(data.winTimes)

    -- 更新玩家剩余刷新次数
    self:updateLeftRefreshTimes(data.leftRefreshTimes, data.maxRefreshTimes)

    -- 更新玩家护甲值
    self:updateShield(checkint(data.shieldPoint), checkint(data.maxShieldPoint))
    
    -- 更新玩家团队头像
    -- self:updateTeamHeadSelectState(teamId)
    
    -- 更新玩家团队头像
    self:updateTeamHead(data.teamInfo.cards, teamId)
    
    -- 更新进攻失败次数
    self:updateSwordPoint(data.swordPoint)
end

--[[
    更新倒计时
    @params enemyList 对手数据列表
]]
function TagMatchLobbyView:updateCountDown(leftSeconds)
    leftSeconds           = checkint(leftSeconds)
    local viewData        = self:getViewData()
    local countDownLabel  = viewData.countDownLabel
    display.commonLabelParams(countDownLabel, {text = CommonUtils.getTimeFormatByType(leftSeconds)})
    
end

--[[
    更新对手信息
]]
function TagMatchLobbyView:updateOpponentInfo(data)
    local isOwnEnemy       = data.isOwnEnemy
    local isOwnSwordPoint  = checkint(data.swordPoint) > 0
    local isOwnShieldPoint = checkint(data.shieldPoint) > 0

    local state = OPPONENT_INFO_STATE.NOT_ELIMINATE
    local text = ''
    if not isOwnEnemy then
        if not  isOwnShieldPoint then
            state = OPPONENT_INFO_STATE.ELIMINATE_AND_NOT_OPPONENT_NOT_SHIELD
            text = __('你已经被淘汰了，快去提升实力，在下次演武争取更高名次吧')
        elseif not isOwnSwordPoint then
            state = OPPONENT_INFO_STATE.ELIMINATE_AND_NOT_OPPONENT_NOT_SWORD
            text = __('你已经被淘汰了，快去提升实力，在下次演武争取更高名次吧')
        end
    end

    local viewData             = self:getViewData()
    local gridView             = viewData.gridView
    local opponentInfoTipLayer = viewData.opponentInfoTipLayer

    gridView:setVisible(false)
    opponentInfoTipLayer:setVisible(false)

    if state == OPPONENT_INFO_STATE.NOT_ELIMINATE then
        -- 更新对手列表
        self:updateOppoentList(data.enemyList)
    else
        self:updateOpponentInfoTipLayer(text)
    end
end

--[[
    更新对手列表
    @params enemyList 对手数据列表
]]
function TagMatchLobbyView:updateOppoentList(enemyList)
    local viewData           = self:getViewData()
    local gridView           = viewData.gridView
    local listLen            = #enemyList
    gridView:setVisible(true)
    gridView:setCountOfCell(listLen)
    gridView:setBounceable(listLen > 4)
    gridView:reloadData()
end

--[[
    更新玩家当前的排名
    @params rank 玩家当前的排名
]]
function TagMatchLobbyView:updateCurRankLabel(rank)
    local viewData           = self:getViewData()
    local curRankLabel       = viewData.curRankLabel

    display.commonLabelParams(curRankLabel, {text = self:getRankTextByRank(checkint(rank))})
end

--[[
    更新玩家进攻胜利次数
    @params 玩家进攻胜利次数
]]
function TagMatchLobbyView:updateWinTimes(winTimes)
    local viewData           = self:getViewData()
    local attackVictoryTime  = viewData.attackVictoryTime

    display.commonLabelParams(attackVictoryTime, {text = checkint(winTimes)})
end

--[[
    更新玩家剩余刷新次数
    @params leftRefreshTimes 玩家剩余刷新次数
    @params maxRefreshTimes  玩家最大刷新次数
]]
function TagMatchLobbyView:updateLeftRefreshTimes(leftRefreshTimes, maxRefreshTimes)
    local viewData           = self:getViewData()
    local refreshBtn         = viewData.refreshBtn
    
    local text = string.format(__('换一批(%s/%s)'), checkint(leftRefreshTimes), checkint(maxRefreshTimes))
    display.commonLabelParams(refreshBtn, {text = text})
end

--[[
    更新进攻失败次数
    @params swordPoint 进攻生命值
]]
function TagMatchLobbyView:updateSwordPoint(swordPoint)
    local viewData           = self:getViewData()
    local attackFailImgs     = viewData.attackFailImgs

    swordPoint = math.max(checkint(swordPoint), 0)
    local attackFailTimes    = 3 - swordPoint
    local gameMgr  = AppFacade.GetInstance():GetManager("GameManager")
    local cacheSwordPoint    = math.max(checkint(gameMgr:GetTagMatchSwordPoint()), 0)
    for i, attackFailImg in ipairs(attackFailImgs) do
        local isSuccess = i > attackFailTimes
        if not isSuccess and cacheSwordPoint then
            if i == attackFailTimes and swordPoint ~= checkint(cacheSwordPoint) then
                -- 清除缓存
                gameMgr:SetTagMatchSwordPoint()
                attackFailImg:runAction(cc.Sequence:create({
                    cc.DelayTime:create(0.5), cc.CallFunc:create(function ()
                        attackFailImg:setTexture(RES_DIR.FAIL_NUMBER_X)
                        attackFailImg:setOpacity(0)
                    end), cc.FadeTo:create(0.5, 255)
                }))
            else
                attackFailImg:setTexture(RES_DIR.FAIL_NUMBER_X)
            end
        else
            attackFailImg:setTexture(isSuccess and RES_DIR.FAIL_NUMBER_BLANK or RES_DIR.FAIL_NUMBER_X)
        end
    end
end

--[[
    更新玩家护甲值
    @params shieldPoint 防守生命值
    @params maxShieldPoint 最大防守生命值
    @params isPlayTornAni  是否开启动画
]]
function TagMatchLobbyView:updateShield(shieldPoint, maxShieldPoint, isPlayTornAni)
    local viewData          = self:getViewData()
    local lattices          = viewData.lattices
    local shieldSpine       = viewData.shieldSpine
    local shieldLabel       = viewData.shieldLabel
    
    shieldPoint = math.max(shieldPoint, 0)

    display.commonLabelParams(shieldLabel, {text = string.format("%s/%s", shieldPoint, maxShieldPoint)})

    local shieldStage = 1
    if shieldPoint <= 7 and shieldPoint > 3 then
        shieldStage = 2
    elseif shieldPoint >= 0 and shieldPoint <= 3 then
        shieldStage = 3
    end
    
    if shieldPoint <= 0 then
        shieldSpine:addAnimation(0, 'end4', false)
    else
        if isPlayTornAni then
            shieldSpine:addAnimation(0, 'end' .. shieldStage, false)
            shieldSpine:addAnimation(0, 'play' .. shieldStage, false)
            shieldSpine:addAnimation(0, 'idle' .. shieldStage, true)
        else
            shieldSpine:addAnimation(0, 'idle' .. shieldStage, true)
        end
    end

    local latticeImgName = 'SHIELD_LATTICE_' .. shieldStage
    for i, lattice in ipairs(lattices) do
        if i <= shieldPoint then
            lattice:setVisible(true)
            lattice:setTexture(RES_DIR[latticeImgName])
        else
            lattice:setVisible(false)
        end
    end

end

--[[
    更新对手信息
    @params viewData 对手信息 视图数据
    @params data     对手数据
]]
function TagMatchLobbyView:updateOppoentDescCell(viewData, data)
    local playerProfileUI  = viewData.playerProfileUI
    local emptyUI          = viewData.emptyUI
    local isShowPlayerInfo = data and next(data) ~= nil

    playerProfileUI:setVisible(isShowPlayerInfo)
    emptyUI:setVisible(not isShowPlayerInfo)

    local bg = viewData.bg
    bg:setTexture(isShowPlayerInfo and RES_DIR.OPPONENT_CELL_BG or RES_DIR.OPPONENT_CELL_BG_NONE)

    if isShowPlayerInfo then
        -- update oppoent name
        local playerName        = viewData.playerName
        local name              = data.playerName
        display.commonLabelParams(playerName, {text = tostring(name)})

        -- update oppoent head
        local playerHeadNode    = viewData.playerHeadNode
        local playerId          = data.playerId
        local playerLevel       = data.playerLevel
        local playerAvatar      = data.playerAvatar
        local playerAvatarFrame = data.playerAvatarFrame
        playerHeadNode:RefreshSelf({level = playerLevel, avatar = playerAvatar, avatarFrame = playerAvatarFrame})
       
        -- update oppoent rank
        local rank              = viewData.rank
        local playerRank        = data.playerRank
        display.commonLabelParams(rank, {text = self:getRankTextByRank(checkint(playerRank))})

        -- update oppoent battlePoint
        local battlePoint       = viewData.battlePoint
        local playerBattlePoint = data.playerBattlePoint
        display.commonLabelParams(battlePoint, {text = checkint(playerBattlePoint)})
    end

end

--[[
    更新团队头像
    @params cards 团队卡牌信息
]]
function TagMatchLobbyView:updateTeamHead(cards, teamId)
    local viewData = self:getViewData()
    local dragAreaLayers = viewData.dragAreaLayers

    for i, dragAreaLayer in ipairs(dragAreaLayers) do
        local teamData = cards[tostring(i)] or {}
        self:updateTeamHeadNode(i, teamData)

        self:updateTeamHeadSelectState(i, checkint(teamId) == i)
    end
end

--[[
    更新团队头像节点
    @params index     团队下标
    @params teamData  团队数据
]]
function TagMatchLobbyView:updateTeamHeadNode(index, teamData)
    local viewData = self:getViewData()

    local dragAreaLayers = viewData.dragAreaLayers
    local dragAreaLayer  = dragAreaLayers[index]

    local memberCount = 0
    local id = 0
    for i, v in ipairs(teamData) do
        if v and v.id then
            if id == 0 then
                id = checkint(v.id)
            end
            memberCount = memberCount + 1
        end
    end

    -- 创建 或 更新 团队头像
    local dragAreaLayerViewData = dragAreaLayer.viewData
    if id > 0 then
        local cardHeadNodeData = {
            id = id,
            showBaseState = false, showActionState = false, showVigourState = false
        }
        local teamHeadNode = dragAreaLayerViewData.teamHeadNode
        if teamHeadNode then
            teamHeadNode:setVisible(true)
            local cardHeadNode = teamHeadNode.viewData.cardHeadNode
            cardHeadNode:RefreshUI(
                cardHeadNodeData
            )
        else
            local dragAreaLayerSize = dragAreaLayer:getContentSize()
            dragAreaLayerViewData.teamHeadNode = CreateTeamNode(cardHeadNodeData, false, cc.size(dragAreaLayerSize.width, dragAreaLayerSize.height))
            display.commonUIParams(dragAreaLayerViewData.teamHeadNode, {ap = display.CENTER, po = cc.p(dragAreaLayerSize.width / 2, dragAreaLayerSize.height / 2)})
            dragAreaLayer:addChild(dragAreaLayerViewData.teamHeadNode)
        end

    else
        local teamHeadNode = dragAreaLayerViewData.teamHeadNode
        if teamHeadNode then
            teamHeadNode:setVisible(false)
        end
    end

    -- 更新团队数量
    local memberLabel = dragAreaLayerViewData.memberLabel
    local labelColor = memberCount >= MAX_TEAM_MEMBER_AMOUNT and '#000000' or '#d23d3d'
    display.commonLabelParams(memberLabel, {text = string.format('%s/%s', memberCount, MAX_TEAM_MEMBER_AMOUNT), color = labelColor})
   
end

--[[
    更新团队头像选中状态
    @params teamId 团队id
]]
function TagMatchLobbyView:updateTeamHeadSelectState(teamId, isSelect)
    teamId = checkint(teamId)
    if teamId <= 0 then
        return
    end
    local viewData = self:getViewData()
    local playerTeamHeadBgs = viewData.playerTeamHeadBgs
    local playerTeamHeadBg = playerTeamHeadBgs[teamId]
    local playerTeamHeadBgViewData = playerTeamHeadBg.viewData
    local selectBg = playerTeamHeadBgViewData.selectBg

    selectBg:setVisible(isSelect)
end

function TagMatchLobbyView:updateOpponentInfoTipLayer(text)
    local viewData = self:getViewData()
    local opponentInfoTipLayer = viewData.opponentInfoTipLayer
    local opponentInfoTipLayerViewData = opponentInfoTipLayer.viewData

    opponentInfoTipLayer:setVisible(true)
    if opponentInfoTipLayerViewData then
        local tipLabel = opponentInfoTipLayerViewData.tipLabel
        display.commonLabelParams(tipLabel, {text = text})
    else
        self:createOpponentInfoTipLayer(text)
    end
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    local actionBtns = {}
    
    local bg = display.newImageView(RES_DIR.BG, display.cx, display.cy, {ap = display.CENTER, enable = true})
    view:addChild(bg)

    -------------------------------------
    -- top
    local topUILayer = display.newLayer()
    view:addChild(topUILayer)

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DIR.BACK})
    topUILayer:addChild(backBtn)
    -- actionBtns[tostring(BUTTON_TAG.BACK)] = backBtn

    -- title button
    local titleBtn = display.newButton(display.SAFE_L + 120, size.height, {n = RES_DIR.TITLE, reqW = 200 ,  ap = display.LEFT_TOP })
    display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('天城演武'), offset = cc.p(0, -10) , reqW = 175 }))
    topUILayer:addChild(titleBtn)

    local titleSize = titleBtn:getContentSize()
    local titleRuleBtn = display.newButton(titleBtn:getPositionX() + titleSize.width - 50, titleBtn:getPositionY() - titleSize.height/2 - 10, {n = RES_DIR.BTN_TIPS})
    topUILayer:addChild(titleRuleBtn)
    -- titleBtn:addChild(display.newImageView(RES_DIR.BTN_TIPS, titleSize.width - 50, titleSize.height/2 - 10))

    -- medal shop btn
    local tagMatchShopBtn = display.newButton(0, 0, {n = RES_DIR.ICON_SHOP})
    display.commonUIParams(tagMatchShopBtn, {po = cc.p(display.SAFE_R - 240, size.height - 8), ap = display.RIGHT_TOP})
    topUILayer:addChild(tagMatchShopBtn)
    tagMatchShopBtn:setVisible(false)

    local medalShopLabel = display.newLabel(0, 0, {text = __('通宝商店'), fontSize = 22, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#412225'})
    display.commonUIParams(medalShopLabel, {po = cc.p(utils.getLocalCenter(tagMatchShopBtn).x, -4)})
    tagMatchShopBtn:addChild(medalShopLabel)
    actionBtns[tostring(BUTTON_TAG.SHOP)] = tagMatchShopBtn

    -- cur rank label
    local scoreBarSize = cc.size(236 + display.width - display.SAFE_R, 66)
    topUILayer:addChild(display.newImageView(RES_DIR.SCORE_BAR, display.width, size.height - 10, {ap = display.RIGHT_TOP, scale9 = true, size = scoreBarSize, capInsets = cc.rect(235,0,1,1)}))
    topUILayer:addChild(display.newLabel(display.SAFE_R - 80, size.height - 28, fontWithColor(9, {ap = display.RIGHT_CENTER, text = __('当前排名')})))

    local curRankLabel = display.newLabel(display.SAFE_R - 80, size.height - 63, fontWithColor(9, {ap = display.RIGHT_CENTER, text = '----'}))
    topUILayer:addChild(curRankLabel)

    -- rank button
    local rankBtn = display.newButton(display.SAFE_R + 5, size.height, {n = RES_DIR.BTN_RANK, ap = display.RIGHT_TOP})
    -- display.commonLabelParams(rankBtn, fontWithColor(14, {fontSize = 23, text = __('排行榜'), offset = cc.p(0, -46)}))
    topUILayer:addChild(rankBtn)
    actionBtns[tostring(BUTTON_TAG.RANK)] = rankBtn
    -- 

    -------------------------------------
    -- attackteam Bg

    local attackteamUILayer = display.newLayer()
    view:addChild(attackteamUILayer)

    local attackteamBgLayer = display.newLayer(display.SAFE_R + 10, size.height / 2 - 40, {ap = display.RIGHT_CENTER, bg = RES_DIR.ATTACKTEAM_BG})
    local attackteamBgLayerSize = attackteamBgLayer:getContentSize()
    attackteamUILayer:addChild(attackteamBgLayer)

    local attackteamTitle = display.newButton(0, 0, {n = RES_DIR.ATTACKTEAM_TITLE, animation = false ,scale9 = true })
    display.commonUIParams(attackteamTitle, {po = cc.p(attackteamBgLayerSize.width / 2 + 5, attackteamBgLayerSize.height - 43)})
    display.commonLabelParams(attackteamTitle, fontWithColor(5, {text = __('出战顺序') ,paddingW = 20 }))
    attackteamBgLayer:addChild(attackteamTitle)
    
    attackteamBgLayer:addChild(display.newLabel(attackteamTitle:getPositionX(), attackteamBgLayerSize.height - 86, {ap = display.CENTER, w = 160 ,hAlign = display.TAC,  fontSize = 20, color = '#ffe6cc', text = __('点击查看阵容')}))

    local playerTeamHeadBgLayerSize = cc.size(189, attackteamBgLayerSize.height - 241)
    local playerTeamHeadBgLayer = display.newLayer(128, attackteamBgLayerSize.height - 116, {ap = display.CENTER_TOP, size = playerTeamHeadBgLayerSize})
    attackteamBgLayer:addChild(playerTeamHeadBgLayer)

    local dragAreaLayers    = {}
    local playerTeamHeadBgs = {}
    for i = 1, 3 do
        local offsetY = (i - 1) * 152
        local playerTeamHeadBg = CreatePlayerTeamHeadBg(i)
        display.commonUIParams(playerTeamHeadBg, {po = cc.p(0, playerTeamHeadBgLayerSize.height - offsetY), ap = display.LEFT_TOP})
        playerTeamHeadBgLayer:addChild(playerTeamHeadBg)
        table.insert(playerTeamHeadBgs, playerTeamHeadBg)

        local dragAreaLayer = CreateDragAreaLayer()
        display.commonUIParams(dragAreaLayer, {po = cc.p(108, playerTeamHeadBgLayerSize.height - 52 - offsetY), ap = display.CENTER})
        playerTeamHeadBgLayer:addChild(dragAreaLayer)
        dragAreaLayer:setTag(i)
        table.insert(dragAreaLayers, dragAreaLayer)
    end

    local modifyBtn = display.newButton(128, 70, {ap = display.CENTER, n = RES_DIR.BTN_ORANGE , scale9 = true })
    display.commonLabelParams(modifyBtn, fontWithColor(14, {text = __('修改') , paddingW = 20 }))
    attackteamBgLayer:addChild(modifyBtn)
    actionBtns[tostring(BUTTON_TAG.MODIFY)] = modifyBtn

    local presetTeamBtn = nil
    if GAME_MODULE_OPEN.PRESET_TEAM and CommonUtils.UnLockModule(JUMP_MODULE_DATA.PRESET_TEAM_TAGMATCH) then
        -- 预设队伍按钮
        presetTeamBtn = require("Game.views.presetTeam.PresetTeamEntranceButton").new({isSelectMode = true, presetTeamType = PRESET_TEAM_TYPE.TAG_MATCH})
        display.commonUIParams(presetTeamBtn, {po = cc.p(
            modifyBtn:getPositionX(),
            modifyBtn:getPositionY() + modifyBtn:getContentSize().height/2 + 55
        )})
        display.commonLabelParams(presetTeamBtn, fontWithColor('14', {text = __('预设队伍')}))
        attackteamBgLayer:addChild(presetTeamBtn)
    end

    -------------------------------------
    -- 对手选择列表
    local opponentUILayer = display.newLayer()
    view:addChild(opponentUILayer)

    local opponentBgLayer = display.newLayer(display.cx - 108, size.height / 2 - 124, {ap = display.CENTER_BOTTOM, bg = RES_DIR.OPPONENT_BG})
    local opponentBgLayerSize = opponentBgLayer:getContentSize()
    opponentUILayer:addChild(opponentBgLayer)

    -- 倒计时背景
    local timeBg = display.newImageView(RES_DIR.TIME_BG, 2, opponentBgLayerSize.height - 40, {ap = display.LEFT_CENTER})
    local timeBgSize = timeBg:getContentSize()
    opponentBgLayer:addChild(timeBg)

    local countDownTipLabel = display.newLabel(18, timeBgSize.height / 2, fontWithColor(18, {ap = display.LEFT_CENTER, text = __('离结束还有: ')}))
    local countDownTipLabelSize = display.getLabelContentSize(countDownTipLabel)
    timeBg:addChild(countDownTipLabel)

    local countDownLabel = display.newLabel(countDownTipLabel:getPositionX() + countDownTipLabelSize.width, timeBgSize.height / 2, fontWithColor(14, {ap = display.LEFT_CENTER, text = '--:--:--'}))
    timeBg:addChild(countDownLabel)

    local refreshBtn = display.newButton(opponentBgLayerSize.width - 18, opponentBgLayerSize.height - 40, {n = RES_DIR.REFRESH, ap = display.RIGHT_CENTER})
    display.commonLabelParams(refreshBtn, fontWithColor(14))
    opponentBgLayer:addChild(refreshBtn)
    actionBtns[tostring(BUTTON_TAG.REFRESH)] = refreshBtn

    -- opponent list layer
    local opponentListLayer = display.newLayer(opponentBgLayerSize.width / 2, opponentBgLayerSize.height / 2 - 30, {ap = display.CENTER, bg = RES_DIR.OPPONENT_BG_2})
    local opponentListLayerSize = opponentListLayer:getContentSize()
    opponentBgLayer:addChild(opponentListLayer)

    local gridViewCellSize = cc.size(opponentListLayerSize.width / 4, opponentListLayerSize.height)
    local gridView = CGridView:create(opponentListLayerSize)
    gridView:setPosition(cc.p(opponentListLayerSize.width / 2, opponentListLayerSize.height/ 2))
    gridView:setAnchorPoint(display.CENTER)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setColumns(4)
    opponentListLayer:addChild(gridView)

    local opponentInfoTipLayer = display.newLayer(opponentListLayerSize.width / 2, opponentListLayerSize.height / 2, {ap = display.CENTER, size = opponentListLayerSize})
    opponentListLayer:addChild(opponentInfoTipLayer)

    -------------------------------------
    -- 对手信息展示
    local infoBgLayer = display.newLayer(opponentBgLayer:getPositionX(), size.height / 2 - 106, {ap = display.CENTER_TOP, bg = RES_DIR.INFO_BG})
    local infoBgLayerSize = infoBgLayer:getContentSize()
    opponentUILayer:addChild(infoBgLayer)

    local attackInfoLayerSize = cc.size(254, 238)
    local attackInfoLayer = display.newLayer(153, infoBgLayerSize.height / 2 - 8, {ap = display.CENTER, size = attackInfoLayerSize})
    infoBgLayer:addChild(attackInfoLayer)

    attackInfoLayer:addChild(display.newLabel(attackInfoLayerSize.width / 2, attackInfoLayerSize.height - 20, fontWithColor(4, {ap = display.CENTER, reqW = 200 , text = __('进攻胜场')})))

    -- 进攻胜利次数
    local attackVictoryTime = display.newLabel(attackInfoLayerSize.width / 2, attackInfoLayerSize.height - 50, fontWithColor(14, {ap = display.CENTER}))
    attackInfoLayer:addChild(attackVictoryTime)

    attackInfoLayer:addChild(display.newImageView(RES_DIR.INFO_ICO_LINE, attackInfoLayerSize.width / 2, attackInfoLayerSize.height - 70, {ap = display.CENTER}))

    attackInfoLayer:addChild(display.newLabel(attackInfoLayerSize.width / 2, attackInfoLayerSize.height - 86, fontWithColor(4, {ap = display.CENTER, text = __('失败次数')})))

    local attackFailImgs = {}
    local imgW = attackInfoLayerSize.width / 3 - 10
    for i = 1, 3 do
        local failImg = display.newImageView(RES_DIR.FAIL_NUMBER_BLANK, 14 + imgW / 2 + (i - 1) * imgW, 106, {ap = display.CENTER})
        attackInfoLayer:addChild(failImg)
        table.insert(attackFailImgs, failImg)
    end

    -- 战报
    local reportBtn = display.newButton(attackInfoLayerSize.width / 2, 35, {n = _res('ui/pvc/pvp_board_btn_report.png')})
    display.commonLabelParams(reportBtn, fontWithColor(14, {text = __('战报') , reqW = 120  }))
    attackInfoLayer:addChild(reportBtn)
    actionBtns[tostring(BUTTON_TAG.REPORT)] = reportBtn

    local reportBtnIcon = display.newImageView(_res('ui/pvc/pvp_board_ico_report.png'), 0, 0)
    display.commonUIParams(reportBtnIcon, {po = cc.p(reportBtnIcon:getContentSize().width * 0.5 - 20, utils.getLocalCenter(reportBtn).y)})
    reportBtn:addChild(reportBtnIcon, 5)

    infoBgLayer:addChild(display.newImageView(RES_DIR.BLEW_FIGHT_BG, infoBgLayerSize.width - 18, 4, {ap = display.RIGHT_BOTTOM}))

    local shieldSpine = sp.SkeletonAnimation:create(
            'effects/tagMatch/dun.json',
            'effects/tagMatch/dun.atlas',
        1
    )
    shieldSpine:update(0)
    shieldSpine:setPosition(cc.p(390, infoBgLayerSize.height / 2))
    infoBgLayer:addChild(shieldSpine, 1)
    
    local shieldSpineTouchView = display.newLayer(405, infoBgLayerSize.height / 2, {ap = display.CENTER, size = cc.size(200, 200), enable = true, color = cc.c4b(0,0,0,0)})
    infoBgLayer:addChild(shieldSpineTouchView, 10)
    actionBtns[tostring(BUTTON_TAG.SHIELD)] = shieldSpineTouchView

    local shieldBg = display.newImageView(RES_DIR.SHIELD_BG, 450, infoBgLayerSize.height / 2, {ap = display.LEFT_CENTER ,scale9 = true , size = cc.size(380 ,128)})
    local shieldBgSize = shieldBg:getContentSize()
    infoBgLayer:addChild(shieldBg)

    shieldBg:addChild(display.newLabel(shieldBgSize.width / 2, shieldBgSize.height + 20, {ap = display.CENTER, fontSize = 24, color = '#ffebc4', text = __('防守队伍')}))

    shieldBg:addChild(display.newLabel(shieldBgSize.width / 2, shieldBgSize.height - 20, {ap = display.CENTER, fontSize = 22, color = '#dfc3a0', text = __('剩余护甲层数')}))

    local loadingBg = display.newImageView(RES_DIR.LOADING_BG, shieldBgSize.width / 2, shieldBgSize.height / 2, {ap = display.CENTER})
    shieldBg:addChild(loadingBg)

    -- shield lattice
    local lattices = {}
    for i = 1, 10 do
        local params = {index = i, goodNodeSize = cc.size(24,12), midPointX = shieldBgSize.width / 2, midPointY = shieldBgSize.height / 2, col = 10, maxCol = 10, scale = 1, goodGap = 1.5}
        local pos = CommonUtils.getGoodPos(params)
        local lattice = display.newImageView(RES_DIR.SHIELD_LATTICE_1, pos.x, pos.y, {ap = display.CENTER})
        shieldBg:addChild(lattice)
        table.insert(lattices, lattice)
        lattice:setVisible(false)
    end

    -- shield 剩余个数
    local shieldLabel = display.newLabel(shieldBgSize.width - 36, shieldBgSize.height / 2, {ap = display.LEFT_CENTER, fontSize = 22, color = '#ffffff'})
    shieldBg:addChild(shieldLabel)

    shieldBg:addChild(display.newLabel(shieldBgSize.width / 2, 0, {ap = display.CENTER_BOTTOM, fontSize = 20, color = '#dfc3a0', text = __('防守失败扣除一层, 耗尽视作失败') , w   = 350, reqH = 60   }))

    -- rule
    local ruleBtn = display.newButton(infoBgLayerSize.width - 50, infoBgLayerSize.height - 46, {n = _res('ui/common/common_btn_tips.png')})
    infoBgLayer:addChild(ruleBtn)
    
    -- fight
    local fightBtn = require('common.CommonBattleButton').new()
    fightBtn:setPosition(infoBgLayerSize.width - 180, 95)
    infoBgLayer:addChild(fightBtn)
    -- fightBtn:setEnabled(false)
    actionBtns[tostring(BUTTON_TAG.FIGHT)] = fightBtn

    return {
        view                 = view,
        backBtn              = backBtn,
        ruleBtn              = ruleBtn,
        titleRuleBtn         = titleRuleBtn,
        actionBtns           = actionBtns,
        countDownLabel       = countDownLabel,
        gridView             = gridView,
        opponentInfoTipLayer = opponentInfoTipLayer,
        shieldSpine          = shieldSpine,
        shieldSpineTouchView = shieldSpineTouchView,
        shieldLabel          = shieldLabel,
        lattices             = lattices,
        curRankLabel         = curRankLabel,
        refreshBtn           = refreshBtn,
        attackVictoryTime    = attackVictoryTime,
        attackFailImgs       = attackFailImgs,
        playerTeamHeadBgs    = playerTeamHeadBgs,
        dragAreaLayers       = dragAreaLayers,
    }
end

CreatePlayerTeamHeadBg = function (index)
    local size = cc.size(189, 138)
    local layer = display.newLayer(0, 0, {size = size})

    local attackTeamNum = display.newImageView(RES_DIR.ATTACKTEAM_NUM, 0, size.height - 8, {ap = display.LEFT_TOP})
    local attackTeamNumSize = attackTeamNum:getContentSize()
    layer:addChild(attackTeamNum)

    local infoLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	display.commonUIParams(infoLabel, {ap = display.LEFT_CENTER, po = cc.p(5, attackTeamNumSize.height / 2)})
	infoLabel:setString(string.format("%s.", index))
	attackTeamNum:addChild(infoLabel)

    local teamBgLayer = display.newLayer(attackTeamNumSize.width + 5, size.height, {ap = display.LEFT_TOP, bg = RES_DIR.ATTACKTEAM_BG_TEAM})
    local teamBgSize = teamBgLayer:getContentSize()
    layer:addChild(teamBgLayer)

    -- 选中背景
    local selectBg = display.newImageView(RES_DIR.ATTACKTEAM_BG_TEAM_S, teamBgSize.width / 2, teamBgSize.height / 2, {ap = display.CENTER})
    teamBgLayer:addChild(selectBg)
    selectBg:setVisible(false)

    local clickLayer = display.newLayer(teamBgSize.width / 2, teamBgSize.height / 2, {ap = display.CENTER, size = teamBgSize, color = cc.c4b(0,0,0,0), enable = true})
    teamBgLayer:addChild(clickLayer)

    if index ~= 3 then
        local teamLine = display.newImageView(RES_DIR.ATTACKTEAM_LINE, teamBgLayer:getPositionX() + teamBgSize.width / 2, teamBgLayer:getPositionY() - teamBgSize.height - 16, {ap = display.CENTER_TOP})
        layer:addChild(teamLine)
    end

    layer.viewData = {
        selectBg     = selectBg,
        clickLayer   = clickLayer,
    }

    return layer
end

CreateDragAreaLayer = function ()
    local size = cc.size(103, 104)
    local dragAreaLayer = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = size, color = cc.c4b(0, 0, 0, 0)})

    local memberBg = display.newImageView(RES_DIR.ATTACKTEAM_MEMBER_BG, size.width / 2, 0, {ap = display.CENTER_BOTTOM})
    local memberBgSize = memberBg:getContentSize()
    dragAreaLayer:addChild(memberBg, 1)

    local memberLabel = display.newLabel(memberBgSize.width / 2, memberBgSize.height / 2 - 2, {ap = display.CENTER, fontSize = 20, color = '#000000'})
    memberBg:addChild(memberLabel)

    dragAreaLayer.viewData = {
        memberLabel = memberLabel
    }

    return dragAreaLayer
end

CreateTeamNode = function (cardHeadNodeData, isCaptain, teamEmptyNodeSize)
    local cardHeadLayerSize = cc.size(81, 81)
    local cardHeadLayer = display.newLayer(0, 0, {size = cardHeadLayerSize})

    local cardHeadNode = require('common.CardHeadNode').new(cardHeadNodeData)
    cardHeadNode:setScale(teamEmptyNodeSize.width / cardHeadNode:getContentSize().width)
    cardHeadNode:setPosition(cc.p(cardHeadLayerSize.width / 2, cardHeadLayerSize.height / 2))
    cardHeadLayer:addChild(cardHeadNode)
    cardHeadNode:setName('cardHeadNode')
    
    -- if isCaptain then
    --     -- 队长mark
    --     local cardHeadNode = cardHeadNode:getContentSize()
    --     local captainMark = display.newImageView(_res('ui/home/teamformation/team_ico_captain.png'), cardHeadLayerSize.width / 2, cardHeadLayerSize.height / 2 - 5, {ap = display.CENTER_BOTTOM})
    --     cardHeadLayer:addChild(captainMark)
    -- end

    cardHeadLayer.viewData = {
        cardHeadNode = cardHeadNode
    }
    return cardHeadLayer
end

function TagMatchLobbyView:createOpponentInfoTipLayer(text)
    local viewData = self:getViewData()
    local opponentInfoTipLayer = viewData.opponentInfoTipLayer

    local infoTipSize = opponentInfoTipLayer:getContentSize()

    local imgPaths = {
        'ui/battle/label_btn_stronger.png',
        'ui/battle/label_btn_break.png',
        'ui/battle/label_btn_upper.png',
        'ui/battle/label_pet_stronger.png',
    }

    local tipImg = display.newImageView(RES_DIR.OPPONENT_INFO_TEXT, infoTipSize.width / 2, infoTipSize.height / 2 + 50, {ap = display.CENTER})
    local tipImgSize = tipImg:getContentSize()
    opponentInfoTipLayer:addChild(tipImg)

    local tipLabel = display.newLabel(tipImgSize.width / 2, tipImgSize.height / 2, fontWithColor(9, {ap = display.CENTER, text = text}))
    tipImg:addChild(tipLabel)

    local imgCount = #imgPaths
    for i = 1, imgCount do
        local imgPath = imgPaths[i]
        local img = display.newImageView(_res(imgPath), 0, 0, {ap = display.CENTER})
        local imgSize = img:getContentSize()
        local pos = CommonUtils.getGoodPos({index = i, goodNodeSize = imgSize, midPointX = infoTipSize.width / 2, midPointY = imgSize.height / 2 + 10, col = imgCount, maxCol = imgCount, goodGap = 20})
        display.commonUIParams(img, {po = pos})

        opponentInfoTipLayer:addChild(img)
    end

    opponentInfoTipLayer.viewData = {
        tipLabel = tipLabel,
    }
end

function TagMatchLobbyView:CreateOppoentDescCell()
    local size = cc.size(259, 317)
    local cell = CGridViewCell:new()
    cell:setContentSize(size)

    local bg = display.newImageView(RES_DIR.OPPONENT_CELL_BG_NONE, size.width / 2, size.height / 2, {ap = display.CENTER})
    local bgSize = bg:getContentSize()
    cell:addChild(bg)

    local selectFrame = display.newImageView(RES_DIR.OPPONENT_CELL_SELECT, size.width / 2 -1, size.height / 2 + 2, {size = cc.size(bgSize.width + 4, bgSize.height), scale9 = true,ap = display.CENTER})
    cell:addChild(selectFrame)
    selectFrame:setVisible(false)

    local clickLayer = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = bgSize, color = cc.c4b(0,0,0,0), enable = true})
    cell:addChild(clickLayer)

    -----------------------------
    -- player profile
    local playerProfileUI = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = size})
    cell:addChild(playerProfileUI)
    -- playerProfileUI:setVisible(false)

    local playerName = display.newLabel(size.width / 2, size.height - 30, fontWithColor(5, {ap = display.CENTER}))
    playerProfileUI:addChild(playerName)

    -- local headerNode = require('root.CCHeaderNode').new({bg = _res('ui/home/infor/setup_head_bg_2.png'), isPre = true})
    -- display.commonUIParams(headerNode,{po = cc.p(size.width / 2, size.height - 120), ap = display.CENTER})
    -- playerProfileUI:addChild(headerNode)
    -- headerNode:setScale(0.8)
    local playerHeadNode = require('common.FriendHeadNode').new({
        enable = false, scale = 0.6, showLevel = true
    })
    display.commonUIParams(playerHeadNode,{po = cc.p(size.width / 2, size.height - 120), ap = display.CENTER})
    playerProfileUI:addChild(playerHeadNode)
    playerHeadNode:setScale(0.8)

    local battlePointBg = display.newImageView(RES_DIR.OPPONENT_CELL_INFO_BG, size.width / 2, 100, {ap = display.CENTER})
    local battlePointBgSize = battlePointBg:getContentSize()
    playerProfileUI:addChild(battlePointBg)

    local battlePointLabel = display.newLabel(10, battlePointBgSize.height / 2, {ap = display.LEFT_CENTER, fontSize = 22, color = '#c9a78f', text = __('灵力   :')})
    local battlePointLabelSize = display.getLabelContentSize(battlePointLabel)
    battlePointBg:addChild(battlePointLabel)
    
    local battlePoint = display.newLabel(battlePointLabel:getPositionX() + battlePointLabelSize.width, battlePointBgSize.height / 2, {ap = display.LEFT_CENTER, fontSize = 22, color = '#ffffff', text = 1})
    battlePointBg:addChild(battlePoint)

    local rankBg = display.newImageView(RES_DIR.OPPONENT_CELL_INFO_BG, size.width / 2, 60, {ap = display.CENTER})
    local rankBgSize = rankBg:getContentSize()
    playerProfileUI:addChild(rankBg)

    local rankLabel = display.newLabel(10, battlePointBgSize.height / 2, {ap = display.LEFT_CENTER, fontSize = 22, color = '#c9a78f', text = __('排名   :')})
    local rankLabelSize = display.getLabelContentSize(rankLabel)
    rankBg:addChild(rankLabel)
    
    local rank = display.newLabel(rankLabel:getPositionX() + rankLabelSize.width, rankBgSize.height / 2, {ap = display.LEFT_CENTER, fontSize = 22, color = '#ffffff', text = 1})
    rankBg:addChild(rank)

    local emptyUI = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = size})
    emptyUI:setVisible(false)
    cell:addChild(emptyUI)

    local emptyPlayerTip = display.newLabel(28, size.height / 2, {ap = display.LEFT_CENTER, fontSize = 22, w = 22 * 9, color = '#ffe8d7', text = __('没有配置到适合对手')})
    emptyUI:addChild(emptyPlayerTip)

    cell.viewData = {
        bg              = bg,
        clickLayer      = clickLayer,
        selectFrame     = selectFrame,
        playerProfileUI = playerProfileUI,
        playerName      = playerName,
        playerHeadNode  = playerHeadNode,
        battlePoint     = battlePoint,
        rank            = rank,
        emptyUI         = emptyUI,
    }
    return cell
end

function TagMatchLobbyView:getViewData()
	return self.viewData_
end

function TagMatchLobbyView:getRankTextByRank(rank)
    local text = ''
    if rank <= 0 then
        text = __('未入榜')
    else
        text = tostring(rank)
    end
    return text
end

return TagMatchLobbyView