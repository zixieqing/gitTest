--[[
 * descpt : 创建工会 home 界面
]]

local TagMatchFightPrepareView = class('TagMatchFightPrepareView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.tagMatch.TagMatchFightPrepareView'
	node:enableNodeEvents()
	return node
end)

local CreateView         = nil
local CreatePlayerLineup = nil
local CreateTeamTitle    = nil
local CreateTeamView     = nil

local RES_DIR = {
    BG                    = _res("ui/tagMatch/3v3_bg.png"),
    BACK                  = _res("ui/common/common_btn_back"),
    MAIN_BG_BLUE          = _res("ui/tagMatch/fightPrepare/3v3_main_bg_blue.png"),
    MAIN_BG_RED           = _res("ui/tagMatch/fightPrepare/3v3_main_bg_red.png"),
    RANKS_BG_2            = _res("ui/tagMatch/fightPrepare/3v3_ranks_bg_2.png"),
    RANKS_BG              = _res("ui/tagMatch/fightPrepare/3v3_ranks_bg.png"),
    BTN_ORANGE            = _res('ui/common/common_btn_orange.png'),
    PRESET_TEAM_ICON      = _res('ui/home/cardslistNew/card_preview_btn_team.png'),
}

local MIN_OFFSET_FLAG = 10

local LOCAL_DRAG_CHANGE_TEAM = 'LOCAL_DRAG_CHANGE_TEAM'

function TagMatchFightPrepareView:ctor( ... )
    self.args = unpack({...})
    self:initData()
    self:initialUI()
end

function TagMatchFightPrepareView:initData()
    
end

function TagMatchFightPrepareView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self:getViewData().view)
	end, __G__TRACKBACK__)
end

function TagMatchFightPrepareView:refreshUI(data)
    local playerAttackData = data.playerAttackData
    self:updatePlayerLineup(playerAttackData)
    
    local oppoentData      = data.oppoentData
    self:updateOpponentLineup(oppoentData)

    self:updateMyTeamTypeIcon(checkint(data.attackTeamId) > 0)
end

function TagMatchFightPrepareView:updatePlayerLineup(playerAttackData)
    local viewData     = self:getViewData()
    local playerLineup = viewData.playerLineup
    local playerLineupViewData = playerLineup.viewData

    local teamViews      = playerLineupViewData.teamViews
    local totalBattlePoint = self:updateAllTeamView(teamViews, playerAttackData)

    local teamTitleLayer = playerLineupViewData.teamTitleLayer
    self:updateTeamTitle(teamTitleLayer, totalBattlePoint)
end

function TagMatchFightPrepareView:updateOpponentLineup(oppoentData)
    local viewData       = self:getViewData()
    local opponentLineup = viewData.opponentLineup

    local opponentLineupViewData = opponentLineup.viewData
    local teamViews      = opponentLineupViewData.teamViews

    local totalBattlePoint = self:updateAllTeamView(teamViews, oppoentData.playerCards, true)

    local teamTitleLayer = opponentLineupViewData.teamTitleLayer
    self:updateTeamTitle(teamTitleLayer, totalBattlePoint, oppoentData)
end

function TagMatchFightPrepareView:updateMyTeamTypeIcon(isPresetTeam)
    local viewData     = self:getViewData()
    local playerLineup = viewData.playerLineup
    local playerLineupViewData = playerLineup.viewData

    local teamTitleLayer = playerLineupViewData.teamTitleLayer
    local presetTeamIcon = teamTitleLayer.viewData.presetTeamIcon
    presetTeamIcon:setVisible(isPresetTeam == true)
end

function TagMatchFightPrepareView:updateTeamTitle(teamTitleLayer, totalMana, playerData)
    local fight_num = teamTitleLayer.viewData.fight_num
    fight_num:setString(totalMana)

    local rivalHeadNode   = teamTitleLayer:getChildByName('rivalHeadNode')
    if rivalHeadNode then
        local playerId          = playerData.playerId
        local playerLevel       = playerData.playerLevel
        local playerAvatar      = playerData.playerAvatar
        local playerAvatarFrame = playerData.playerAvatarFrame
        rivalHeadNode:RefreshUI({
            playerId = playerId,
            avatar = playerAvatar,
            avatarFrame = playerAvatarFrame,
            playerLevel = playerLevel,
        })
    end

    local playerNameLabel = teamTitleLayer:getChildByName('playerNameLabel')
    if playerNameLabel then
        display.commonLabelParams(playerNameLabel, {text = tostring(playerData.playerName)})
    end
    
end

function TagMatchFightPrepareView:updateAllTeamView(teamViews, teamDatas, isOppoentTeam)
    local totalBattlePoint = 0
    for i, teamView in ipairs(teamViews) do
        local battlePoint = teamView:refreshTeam(i, teamDatas[tostring(i)], isOppoentTeam)
        totalBattlePoint = totalBattlePoint + battlePoint
    end
    return totalBattlePoint
end

function TagMatchFightPrepareView:showUIAction(cb)
    local viewData               = self:getViewData()
    local playerLineup           = viewData.playerLineup
    local playerLineupViewData   = playerLineup.viewData
    local playerTeamTitleLayer   = playerLineupViewData.teamTitleLayer
    local playerTeamViews        = playerLineupViewData.teamViews

    local playerTeamTitleLayerPosX = playerTeamTitleLayer:getPositionX()
    playerTeamTitleLayer:setPositionX(playerTeamTitleLayerPosX - display.width)

    local playerTeamViewPosXs = {}
    for i, v in ipairs(playerTeamViews) do
        local posX = v:getPositionX()
        table.insert(playerTeamViewPosXs, posX)
        
        v:setOpacity(0)
        v:setPositionX(posX - display.cx)
    end

    local opponentLineup         = viewData.opponentLineup
    local opponentLineupViewData = opponentLineup.viewData
    local opponentTeamTitleLayer = opponentLineupViewData.teamTitleLayer
    local opponentTeamViews      = opponentLineupViewData.teamViews

    local opponentTeamTitleLayerPosX = opponentTeamTitleLayer:getPositionX()
    opponentTeamTitleLayer:setPositionX(opponentTeamTitleLayerPosX + display.width)

    local opponentTeamViewPosXs = {}
    for i, v in ipairs(opponentTeamViews) do
        local posX = v:getPositionX()
        table.insert(opponentTeamViewPosXs, posX)
        v:setPositionX(posX + display.cx)
    end

    local createTeamViewAction = function (teamView, posX, delayTime, moveTime)
        delayTime = delayTime or 0
        moveTime  = moveTime or 8 / 30
        local ac = cc.Sequence:create(
            cc.DelayTime:create(delayTime), cc.Spawn:create(
                cc.FadeTo:create(moveTime, 255),
                cc.MoveTo:create(moveTime, cc.p(posX, teamView:getPositionY()))
            )
        )
        return cc.TargetedAction:create(teamView, ac)
    end
    
    local presetTeamBtn = viewData.presetTeamBtn
    local editTeamBtn   = viewData.editTeamBtn
    local fightBtn      = viewData.fightBtn
    editTeamBtn:setVisible(false)
    fightBtn:setVisible(false)
    editTeamBtn:setOpacity(0)
    fightBtn:setOpacity(0)

    if presetTeamBtn then
        presetTeamBtn:setVisible(false)
        presetTeamBtn:setOpacity(0)
    end

    local createBtnAction = function (btn, delayTime)
        if btn then
            return cc.TargetedAction:create(btn, cc.Sequence:create(
                cc.DelayTime:create(delayTime), cc.CallFunc:create(function ()
                    btn:setVisible(true)
                end), cc.Spawn:create(
                    cc.FadeTo:create(8 / 30, 255)
                )
            ))
        else
            return cc.DelayTime:create(0.001)
        end
    end

    local action = cc.Spawn:create(
        createTeamViewAction(playerTeamTitleLayer, playerTeamTitleLayerPosX, 0.1),
        createTeamViewAction(opponentTeamTitleLayer, opponentTeamTitleLayerPosX, 0.1),

        createTeamViewAction(playerTeamViews[1], playerTeamViewPosXs[1], 0.2),
        createTeamViewAction(opponentTeamViews[1], opponentTeamViewPosXs[1],0.2),
        
        createTeamViewAction(playerTeamViews[2], playerTeamViewPosXs[2], 0.3),
        createTeamViewAction(opponentTeamViews[2], opponentTeamViewPosXs[2], 0.3),

        createTeamViewAction(playerTeamViews[3], playerTeamViewPosXs[3], 0.4),
        createTeamViewAction(opponentTeamViews[3], opponentTeamViewPosXs[3], 0.4),
        
        createBtnAction(editTeamBtn, 0.7),
        createBtnAction(fightBtn, 0.7),
        createBtnAction(presetTeamBtn, 0.7),

        cc.TargetedAction:create(self, cc.Sequence:create(
            cc.DelayTime:create(1),
            cc.CallFunc:create(function ()
            if cb then
                cb()
            end
        end)
        ))
    )
    self:runAction(action)
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    local bg = display.newImageView(RES_DIR.BG, display.cx, display.cy, {ap = display.CENTER, enable = true})
    view:addChild(bg)

    -------------------------------------
    -- top
    local topUILayer = display.newLayer()
    view:addChild(topUILayer)

    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DIR.BACK})
    topUILayer:addChild(backBtn)

    -------------------------------------
    -- content
    local contentUILayer = display.newLayer()
    view:addChild(contentUILayer)
    
    -- player
    local playerLineup = CreatePlayerLineup(-1)
    contentUILayer:addChild(playerLineup)

    -- opponent
    local opponentLineup = CreatePlayerLineup(1)
    contentUILayer:addChild(opponentLineup)

    -------------------------------------
    -- bottom
    local bottomUILayer = display.newLayer()
    view:addChild(bottomUILayer)

    local editTeamBtn = display.newButton(display.SAFE_L + 60, 70, {ap = display.LEFT_CENTER, n = RES_DIR.BTN_ORANGE})
    local editTeamBtnSize = editTeamBtn:getContentSize()
    display.commonLabelParams(editTeamBtn, fontWithColor(14, {text = __('编辑队伍')}))
    bottomUILayer:addChild(editTeamBtn)

    local presetTeamBtn = nil
    if GAME_MODULE_OPEN.PRESET_TEAM and CommonUtils.UnLockModule(JUMP_MODULE_DATA.PRESET_TEAM_TAGMATCH) then
        -- 预设队伍按钮
        presetTeamBtn = require("Game.views.presetTeam.PresetTeamEntranceButton").new({isSelectMode = true, presetTeamType = PRESET_TEAM_TYPE.TAG_MATCH})
        display.commonUIParams(presetTeamBtn, {po = cc.p(
            editTeamBtn:getPositionX() + editTeamBtn:getContentSize().width/2 + 150,
            editTeamBtn:getPositionY()
        )})
        display.commonLabelParams(presetTeamBtn, fontWithColor('14', {text = __('预设队伍')}))
        view:addChild(presetTeamBtn)
    end


    -- local tipLabel = display.newLabel(editTeamBtn:getPositionX() + editTeamBtnSize.width + 10, editTeamBtn:getPositionY(), {
    --     fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1, text = __('拖拽队伍模块可以调整出站顺序'), ap = display.LEFT_CENTER, w = 14 * 23 + 7
    -- })
    -- bottomUILayer:addChild(tipLabel)

    local fightBtn = require('common.CommonBattleButton').new()
    fightBtn:setPosition(display.cx, 120)
    bottomUILayer:addChild(fightBtn)
    

    return {
        view           = view,
        backBtn        = backBtn,
        fightBtn       = fightBtn,
        editTeamBtn    = editTeamBtn,
        playerLineup   = playerLineup,
        opponentLineup = opponentLineup,
        presetTeamBtn  = presetTeamBtn,
    }
end

-- teamTowards int 队伍朝向 1 朝右 -1 朝左
CreatePlayerLineup = function (teamTowards)
    local isLeft = teamTowards == -1
    local playerLineupLayer = display.newLayer()
    -- title
    local teamTitleLayer = CreateTeamTitle(isLeft)
    playerLineupLayer:addChild(teamTitleLayer)

    local ap = isLeft and display.CENTER_TOP or display.CENTER_TOP
    local x = isLeft and display.SAFE_L or display.SAFE_R
    local teamMarkPosSign = isLeft and 1 or -1
    local teamViews = {}
    for i = 1, 3 do
        local teamView = CreateTeamView(nil, nil, teamMarkPosSign)
        local goodParams = {index = i, goodNodeSize = cc.size(100, 150), midPointX = 0, midPointY = display.cy + 200, col = 1, maxCol = 1, scale = 1, goodGap = 0}
		-- display.commonUIParams(bg, {po = CommonUtils.getGoodPos(goodParams)})
        display.commonUIParams(teamView, {ap = ap, po = cc.p(display.cx + teamMarkPosSign * (-1) * 340, CommonUtils.getGoodPos(goodParams).y)})
        playerLineupLayer:addChild(teamView)

        table.insert(teamViews, teamView)
    end

    playerLineupLayer.viewData = {
        teamTitleLayer = teamTitleLayer,
        teamViews      = teamViews,
    }

    return playerLineupLayer
end

CreateTeamTitle = function (isLeft)
    local teamTitleLayerSize = cc.size(display.width, 72)
    local teamTitleLayer = display.newLayer(display.cx, display.height - 130, {ap = display.CENTER, size = cc.size(display.width, 72)})

    local x               = nil
    local ap              = nil
    local ap1             = nil
    local bg              = nil
    local teamMarkPosSign = nil
    local x1              = nil
    local presetTeamIcon  = nil
    
    if isLeft then
        teamMarkPosSign = 1
        x = 0
        ap = display.LEFT_CENTER
        ap1 = display.RIGHT_CENTER
        bg = RES_DIR.MAIN_BG_RED
        x1 = display.SAFE_L

        local myTeamLabel = display.newLabel(x1 + teamMarkPosSign * 60, teamTitleLayerSize.height / 2, {ap = ap, fontSize = 30, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1, text = __('我的阵容')})
        teamTitleLayer:addChild(myTeamLabel)

        local teamIconX = myTeamLabel:getPositionX() + display.getLabelContentSize(myTeamLabel).width + 50
        presetTeamIcon = display.newImageView(RES_DIR.PRESET_TEAM_ICON, teamIconX, myTeamLabel:getPositionY())
        teamTitleLayer:addChild(presetTeamIcon)
        presetTeamIcon:setVisible(false)
    else
        x = display.width
        ap = display.RIGHT_CENTER
        ap1 = display.LEFT_CENTER
        bg = RES_DIR.MAIN_BG_BLUE
        teamMarkPosSign = -1
        x1 = display.SAFE_R

        -- player head
        local rivalHeadScale = 0.65
		local rivalHeadNode = require('common.PlayerHeadNode').new({showLevel = true})
        rivalHeadNode:setScale(rivalHeadScale)
		display.commonUIParams(rivalHeadNode, {po = cc.p(x1 - 15, teamTitleLayerSize.height / 2 + 20), ap = ap})
        teamTitleLayer:addChild(rivalHeadNode)
        rivalHeadNode:setName('rivalHeadNode')
        
        -- player name
        local playerNameLabel = display.newLabel(x1 - 140, teamTitleLayerSize.height / 2 - 16, fontWithColor(3, {fontSize = 22, ap = ap}))
        playerNameLabel:setName('playerNameLabel')
        teamTitleLayer:addChild(playerNameLabel)
    end

    local bgImg = display.newImageView(bg, x + 60 * teamMarkPosSign * (-1), teamTitleLayerSize.height / 2, {ap = ap})
    teamTitleLayer:addChild(bgImg, -1)

    -- 总灵力
    local totalManaLayerSize = cc.size(230, teamTitleLayerSize.height)
    local totalManaLayer = display.newLayer(x1 + teamMarkPosSign * 610, teamTitleLayerSize.height / 2, {ap = ap1, size = totalManaLayerSize})
    teamTitleLayer:addChild(totalManaLayer)

    local totalManaLabel = display.newLabel(0, totalManaLayerSize.height / 2 - 25 , {ap = display.LEFT_BOTTOM, fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1, text = __('总灵力: ')})
    local totalManaLabelSize = display.getLabelContentSize(totalManaLabel)
    totalManaLayer:addChild(totalManaLabel)

    local fireSpine = sp.SkeletonAnimation:create('effects/fire/skeleton.json', 'effects/fire/skeleton.atlas', 1)
	fireSpine:update(0)
    fireSpine:setAnimation(0, 'huo', true)
    fireSpine:setPosition(cc.p(totalManaLabelSize.width + 80, totalManaLabel:getPositionY()))
	totalManaLayer:addChild(fireSpine)

	local fight_num = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', '')
    display.commonUIParams(fight_num, {ap = cc.p(0.5, 0.5), po = cc.p(fireSpine:getPositionX(), totalManaLabel:getPositionY() + 10)})
	fight_num:setHorizontalAlignment(display.TAR)
    fight_num:setScale(0.7)
	totalManaLayer:addChild(fight_num, 1)

    teamTitleLayer.viewData = {
        fight_num = fight_num,
        presetTeamIcon = presetTeamIcon,
    }

    return teamTitleLayer
end

CreateTeamView = function (teamId, teamCards, teamMarkPosSign)
    -- local 
    -- teamCards = teamCards or {
    --     [1] = 525,
    --     [2] = 525,
    --     [3] = 525,
    --     [4] = 525,
    --     [5] = 525,
    -- }
    local teamView = require("Game.views.tagMatch.TagMatchDefensiveTeamView").new({teamId = teamId or 1, teamDatas = teamCards or {}, teamMarkPosSign = teamMarkPosSign})
    -- teamView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    -- teamView:setScaleX(teamMarkPosSign)
    return teamView
end

function TagMatchFightPrepareView:getViewData()
	return self.viewData_
end

return TagMatchFightPrepareView