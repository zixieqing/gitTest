--[[
 * descpt : 创建新天成演武 home 界面
]]

local NewKofArenaLobbyView = class('NewKofArenaLobbyView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.NewKofArenaLobbyView'
	node:enableNodeEvents()
	return node
end)

local IS_FIRST = {
    YES = 1,
    NO  = 0,
}

local CreateView             = nil
local CreatePlayerTeamHeadBg = nil
local CreateDragAreaLayer    = nil
local CreateTeamNode         = nil
local CreateFingerView       = nil

local RES_DIR = {
    BG            = _res("ui/tagMatchNew/3v3_home_bg.jpg"),
    FIRE_SPINE    = _spn('ui/championship/schedule/skeleton'),
    BACK          = _res("ui/common/common_btn_back"),
    TITLE         = _res('ui/common/common_title.png'),
    BTN_TIPS      = _res('ui/common/common_btn_tips.png'),
    BTN_RANK      = _res('ui/tagMatchNew/3v3_home_btn_red_list.png'),
    BTN_GIFT      = _res('ui/tagMatchNew/3v3_home_btn_gift.png'),
    BTN_GIFT_ICON = _res('ui/tagMatchNew/3v3_home_ico_gift_fight.png'),

    BTN_GIFT_BG             = _res('ui/tagMatchNew/3v3_home_bg_gift.png'),
    BTN_GIFT_PROGRESS_BG    = _res('ui/tagMatchNew/3v3_home_bg_gift_line_bottom'),
    BTN_GIFT_PROGRESS_IN_BG = _res('ui/tagMatchNew/3v3_home_bg_gift_line_up'),
    ICON_BOX                = _res('ui/tagMatchNew/3v3_home_ico_box'),
    ICON_BOX_GRAY           = _res('ui/tagMatchNew/3v3_home_ico_box_gray'),

    -------------------
    -- 我方编队相关资源
    ATTACKTEAM_BG_TEAM    = _res("ui/tagMatch/team_frame_touxiangkuang.png"),
    ATTACKTEAM_BG_TEAM_S  = _res("ui/tagMatch/team_img_touxiangkuang_xuanzhong.png"),
    ATTACKTEAM_LINE       = _res("ui/tagMatch/3v3_attackteam_line.png"),
    ATTACKTEAM_MEMBER_BG  = _res("ui/tagMatch/3v3_attackteam_member_bg.png"),
    ATTACKTEAM_NUM        = _res("ui/tagMatch/3v3_attackteam_num.png"),
    BTN_ORANGE            = _res('ui/common/common_btn_orange.png'),
    ATTACKTEAM_TITLE      = _res('ui/common/common_title_5.png'),
    ATTACKTEAM_BG         = _res("ui/tagMatchNew/3v3_home_bg_bule.png"),
    ATTACKTEAM_HEAD_BG    = _res("ui/tagMatchNew/3v3_home_bg_bule_team.png"),
    MODIFY_TEAM_BAR       = _res("ui/tagMatchNew/3v3_home_bg_team_number.png"),

    ----------------
    --玩家信息资源
    DETAILS_BG         = _res("ui/tagMatchNew/3v3_home_bg_details.png"),
    LV_LINE            = _res("ui/tagMatchNew/3v3_home_line_level.png"),
    FORK_LINE          = _res("ui/tagMatchNew/3v3_home_line_details.png"),
    LINE_OF_CUT        = _res("ui/tagMatchNew/3v3_home_line_red_list.png"),
    LINE_OF_GIFT_TIMES = _res("ui/tagMatchNew/3v3_home_line_gift.png"),
    ICON_SCORE         = _res("ui/home/activity/tagMatchNew/3v3_icon_point.png"),
    ICON_RANK          = _res('ui/home/activity/tagMatchNew/3v3_icon_ranking.png'),
    IN_RANK_BG         = _res('ui/tagMatchNew/3v3_home_bg_details_head.png'),
    -------------------
    -- oppoent res
    OPPONENT_BG           = _res("ui/tagMatchNew/3v3_home_bg_red.png"),
    TIME_BG               = _res("ui/tagMatch/3v3_bg_time_.png"),
    REFRESH               = _res('ui/home/commonShop/shop_btn_refresh.png'),
    OPPONENT_BG_2         = _res("ui/tagMatchNew/3v3_home_bg_enemy.png"),
    OPPONENT_INFO_TEXT    = _res("ui/tagMatch/3v3_info_bg_text.png"),
    
    -- oppoent cell
    OPPONENT_CELL_BG_NONE = _res('ui/tagMatch/3v3_opponent_bg_none.png'),
    OPPONENT_CELL_BG      = _res("ui/tagMatch/3v3_opponent_bg.png"),
    OPPONENT_CELL_INFO_BG = _res("ui/tagMatch/3v3_opponent_info.png"),
    OPPONENT_CELL_SELECT  = _res('ui/mail/common_bg_list_selected.png'),

    BLEW_FIGHT_BG         = _res("ui/tagMatchNew/3v3_home_bg_bottom.png"),
    ICON_SHOP             = _res('ui/tagMatchNew/3v3_home_btn_shop'),
    
    ATTACK_TIMES_BAR      = _res('ui/tagMatchNew/3v3_home_bg_battle_number'),
    REWARD_LOOK_BTN       = _res('ui/tagMatchNew/3v3_home_btn_reward'),

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
    GIFT        = 108,
    LOOK_REWARD = 109,
    ADD_FIGHT_TIMES = 110,
}

function NewKofArenaLobbyView:ctor( ... )
    self.args = unpack({...})
    self:initData()
    self:initialUI()
end

function NewKofArenaLobbyView:initData()
    self.initParamConf  = CONF.NEW_KOF.BASE_PARMS:GetAll()
    self.challengeRewardsConf = CONF.NEW_KOF.CHALLENGE:GetAll()
end

function NewKofArenaLobbyView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self:getViewData().view)
	end, __G__TRACKBACK__)
    --显示奖励弹条
    local isShow = true
    self:showRewardBar(isShow)
end

function NewKofArenaLobbyView:refreshUI(data, teamId)

    -- 更新倒计时
    self:updateCountDown(data.leftSeconds)

    -- 更新对手信息
    self:updateOpponentInfo(data)

    -- 更新玩家当前的排名
    self:updateCurRankLabel(data.rank)

    --更新玩家积分
    self:updateCurScoreLabel(data.score)

    --更新段位
    local segmentName = self:getSegmentNameById(data.segmentId)
    self:updateCurGradeLabel(segmentName)

    -- 更新玩家团队头像
    self:updateTeamHead(data.team, teamId)

    --更新剩余攻击次数
    self:updateFightLeftTimes(data.leftAttackTimes)

    --更新剩余保存队伍次数
    self:updateModifyTeamTimes(data.leftSaveTeamTimes)

    --更新挑战次数奖励和进度条
    self:updateChallengeTimes(data.challengeTimes)

    --更新盒子状态（灰色，亮色）
    self:updateBoxState(data.challengeDrawnRewards)

    --更新是否有奖励要领动画
    self:updateHasRewardsToDraw(data.hasRewardsToDraw.isDraw)

    --第一次进入修改编队动画
    local isFirstEnterDefine = LOCAL.NEW_KOF_ARENA.IS_FIRST_ENTER()
    if data.first == IS_FIRST.YES and isFirstEnterDefine:Load() then
        self:updateFirstModifyTeamAction(true)
    else
        local viewData        = self:getViewData()
        viewData.layer:setTouchEnabled(false)
    end
    
    --刷新积分动画
    self:runRefreshScoreEffect(data.score)
end

--展开条切换
function NewKofArenaLobbyView:showRewardBar(isShow)
    local viewData        = self:getViewData()
    local rewardBar  = viewData.rewardBar
    
    local rewardSpreadBar = viewData.rewardSpreadBar
    local rewardSpreadBarImage = viewData.rewardSpreadBarImage
    rewardBar:setVisible(isShow)
    rewardSpreadBar:setVisible(not isShow)
    rewardSpreadBarImage:setVisible(not isShow)
end

function NewKofArenaLobbyView:updateShowRewardBar()
    local viewData        = self:getViewData()
    local rewardBar  = viewData.rewardBar
    local isShow = rewardBar:isVisible()
    self:showRewardBar(not isShow)
end

--[[
    更新倒计时
    @params opponent 对手数据列表
]]
function NewKofArenaLobbyView:updateCountDown(leftSeconds)
    leftSeconds           = checkint(leftSeconds)
    local viewData        = self:getViewData()
    local countDownLabel  = viewData.countDownLabel
    display.commonLabelParams(countDownLabel, {text = CommonUtils.getTimeFormatByType(leftSeconds)})
    
end

--[[
    更新对手信息
]]
function NewKofArenaLobbyView:updateOpponentInfo(data)
    local viewData             = self:getViewData()
    local gridView             = viewData.gridView
    local opponentInfoTipLayer = viewData.opponentInfoTipLayer

    gridView:setVisible(false)
    opponentInfoTipLayer:setVisible(false)

    -- 更新对手列表
    self:updateOppoentList(data.opponent)
end

--[[
    更新对手列表
    @params opponent 对手数据列表
]]
function NewKofArenaLobbyView:updateOppoentList(opponent)
    local viewData           = self:getViewData()
    local gridView           = viewData.gridView
    local listLen            = #opponent
    gridView:setVisible(true)
    gridView:setCountOfCell(listLen)
    gridView:setBounceable(listLen > 4)
    gridView:reloadData()
end

--[[
    更新玩家当前的排名
    @params rank 玩家当前的排名
]]
function NewKofArenaLobbyView:updateCurRankLabel(rank)
    local viewData           = self:getViewData()
    local curRankLabel       = viewData.curRankLabel

    display.commonLabelParams(curRankLabel, {text = self:getRankTextByRank(checkint(rank))})
end


function NewKofArenaLobbyView:updateCurScoreLabel(score)
    local viewData           = self:getViewData()
    local curScoreLabel       = viewData.curScoreLabel
    local score = checkint(self:getInitScore()) + checkint(score)
    display.commonLabelParams(curScoreLabel, {text = tostring(score)})
end

function NewKofArenaLobbyView:updateCurGradeLabel(grade)
    local viewData           = self:getViewData()
    local curLevelText       = viewData.curLevelText

    display.commonLabelParams(curLevelText, {text = tostring(grade)})
end

function NewKofArenaLobbyView:updateFightLeftTimes(leftAttackTimes)
    local viewData           = self:getViewData()
    local attackTimesText       = viewData.attackTimesText
    local maxFightTimes = self:getMaxFightTimes()
    if checkint(leftAttackTimes) > checkint(maxFightTimes) then
        maxFightTimes = leftAttackTimes
    end
    local text = string.format('%s / %s', checkint(leftAttackTimes), checkint(maxFightTimes))
    display.commonLabelParams(attackTimesText, {text = text})
end

--[[
    更新玩家修改编队次数
    @params leftRefreshTimes 玩家剩余修改次数
    @params maxRefreshTimes  玩家最大修改次数
]]
function NewKofArenaLobbyView:updateModifyTeamTimes(leftRefreshTimes)
    local viewData           = self:getViewData()
    local modifyTeamText     = viewData.modifyTeamText
    local maxSaveTeamTimes = self:getMaxSaveTeamTimes()
    local text = string.format('%s / %s', checkint(leftRefreshTimes), checkint(maxSaveTeamTimes))
    modifyTeamText:setString(text)
end


--[[
    更新对手信息
    @params viewData 对手信息 视图数据
    @params data     对手数据
]]
function NewKofArenaLobbyView:updateOppoentDescCell(viewData, data)
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
        local name              = data.name
        display.commonLabelParams(playerName, {text = tostring(name)})

        local integralLabel        = viewData.integralLabel
        local integral              = data.integral
        display.commonLabelParams(integralLabel, {text = tostring(integral)})

        -- update oppoent head
        local playerHeadNode    = viewData.playerHeadNode
        local playerLevel       = data.level
        local playerAvatar      = data.avatar
        local playerAvatarFrame = data.avatarFrame
        playerHeadNode:RefreshSelf({level = playerLevel, avatar = playerAvatar, avatarFrame = playerAvatarFrame})
       
        -- update oppoent rank
        local rank              = viewData.rank
        local playerRank        = data.rank
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
function NewKofArenaLobbyView:updateTeamHead(cards, teamId)
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
function NewKofArenaLobbyView:updateTeamHeadNode(index, teamData)
    local viewData = self:getViewData()

    local dragAreaLayers = viewData.dragAreaLayers
    local dragAreaLayer  = dragAreaLayers[index]

    local memberCount = 0
    local id = 0
    for i, v in ipairs(teamData) do
        if v.id then
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
function NewKofArenaLobbyView:updateTeamHeadSelectState(teamId, isSelect)
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

--更新挑战次数与进度条
function NewKofArenaLobbyView:updateChallengeTimes(times)
    local viewData        = self:getViewData()
    local curResidueText  = viewData.curResidueText
    local totalText = viewData.totalText
    local progress = viewData.progressOne
    display.commonLabelParams(curResidueText, {text = checkint(times)})
    local maxRewardTimes = self:getMaxRewardTimes()
    display.commonLabelParams(totalText, {text = string.format(' / %s', checkint(maxRewardTimes))})
    local size = curResidueText:getContentSize()
    local x = curResidueText:getPositionX()
    totalText:setPositionX(x+size.width)
    --更新进度条与宝箱显示
    local percent = (checkint(times)/checkint(maxRewardTimes)) * 100
    progress:setValue(percent)
end

function NewKofArenaLobbyView:runRefreshScoreEffect(score)
    local lastScore = self:getLastScore()
    local score = checkint(score)
    if lastScore then
        local playStr 
        local lastScore = checkint(lastScore)
        if lastScore < score then
            playStr = 'play1'
        elseif lastScore > score then
            playStr = 'play2'
        else
            return
        end
        -- 积分刷新特效
        if not self.scoreRefreshEffect then
            self.scoreRefreshEffect = sp.SkeletonAnimation:create(
                'effects/tagMatchNew/3v3_home_point.json',
                'effects/tagMatchNew/3v3_home_point.atlas',
                1
            )
            local viewData = self:getViewData()
            local msgBg  = viewData.msgBg
            msgBg:addChild(self.scoreRefreshEffect)
            self.scoreRefreshEffect:setToSetupPose()
            self.scoreRefreshEffect:setPosition(cc.p(130,28))
            self.scoreRefreshEffect:setAnchorPoint(cc.p(0.5,0.5))
            self.scoreRefreshEffect:setScale(0.3)
        end
        self.scoreRefreshEffect:setAnimation(0, playStr, false)
    end
    self:setLastScore(score)
end

function NewKofArenaLobbyView:updateBoxState(challengeDrawnRewards)
    local viewData        = self:getViewData()
    local boxRewards  = viewData.boxRewards
    for k, v in pairs(challengeDrawnRewards) do
        for _, p in pairs(boxRewards) do
            if checkint(p:getTag()) == checkint(v) then
                p:setNormalImage(RES_DIR.ICON_BOX_GRAY)
                p:setSelectedImage(RES_DIR.ICON_BOX_GRAY)
            end
        end
    end
end

function NewKofArenaLobbyView:updateHasRewardsToDraw(isShow)
    local viewData        = self:getViewData()
    local rewardBtn  = viewData.rewardBtn
    local size = rewardBtn:getContentSize()
    if not self.rewareEffect then
        self.rewareEffect = sp.SkeletonAnimation:create(
            'effects/tagMatchNew/3v3_home_box.json',
            'effects/tagMatchNew/3v3_home_box.atlas',
            1
        )
        rewardBtn:addChild(self.rewareEffect, 10)
        self.rewareEffect:setToSetupPose()
    end
    local posY
    local str
    if isShow then
        str = "play2"
        posY = size.height/2 - 5
    else
        str = "play1"
        posY = size.height/2 - 15
    end
    self.rewareEffect:setPosition(cc.p(
        size.width/2,posY
    ))
    self.rewareEffect:setAnimation(0, str, true)
end

function NewKofArenaLobbyView:updateFirstModifyTeamAction(isShow)

    local viewData        = self:getViewData()
    local modifyBtn  = viewData.modifyBtn
    if not self.effect then
        local modifyBtnSize = modifyBtn:getContentSize()
        self.effect = sp.SkeletonAnimation:create(
            'effects/tagMatchNew/3v3_home_star.json',
            'effects/tagMatchNew/3v3_home_star.atlas',
            1
        )
        modifyBtn:addChild(self.effect, 100)
        self.effect:setToSetupPose()
        self.effect:setPosition(cc.p(modifyBtnSize.width/2 - 5,modifyBtnSize.height/2 + 6))
        self.effect:setAnchorPoint(cc.p(0.5,0.5))
        self.effect:setAnimation(0, "play1", true)
    end
    self.effect:setVisible(isShow)
    if not isShow then
        self.effect:removeFromParent()
    end
    self:guideView(isShow)
end


function NewKofArenaLobbyView:RemoveMask()
    local viewData        = self:getViewData()
    local fingerNode = viewData.view:getChildByTag(12346)
    if fingerNode then
        fingerNode:removeFromParent()
        self.fingerViewData = nil
    end
end

function NewKofArenaLobbyView:guideView(isShow)
    if not isShow then return end
    local viewData        = self:getViewData()
    local modifyBtn  = viewData.modifyBtn
    local btnSize = modifyBtn:getContentSize()
    local worldPos = modifyBtn:getParent():convertToWorldSpace(cc.p(modifyBtn:getPosition()))
    local params = {
        areas = {
            [1] = {
                size = {
                    width = btnSize.width,
                    height = btnSize.height,
                },
                x = worldPos.x,
                y = worldPos.y
            },
        },
        isCircle = false,
        location = 2,
        text = __("点击此处进行编队")
    }
    self.fingerViewData = CreateFingerView(params)
    self.fingerViewData.view:setTag(12346)
    local size = viewData.view:getContentSize()
    self.fingerViewData.view:setPosition(size.width/2, size.height/2)
    viewData.view:addChild(self.fingerViewData.view, 10)

end

CreateFingerView = function(params)
    local location = params.location
    local isCircle = params.isCircle
    --是否是圆形
    local view = CLayout:create(display.size)
    view:setBackgroundColor(cc.c4b(100,100,100,100))
    if isCircle == nil then isCircle = false end
    local clipper = cc.ClippingNode:create()
    clipper:setContentSize(display.size)
    display.commonUIParams(clipper, {ap = cc.p(0.5,0.5), po = display.center})
    view:addChild(clipper)

    local areas = checktable(params.areas)
    local fingerNodes = {}
    local area = areas[1]
    local size = area.size
    local position = cc.p(area.x, area.y)
    local spriteName = _res('ui/guide/guide_ico_rectangle')
    if isCircle then spriteName = _res('ui/guide/guide_ico_circle') end
    local lsize = cc.size(92,92)
    if isCircle then lsize = cc.size(204,204) end
    if size and isCircle == false then
        lsize = size
    end
    local sprite = display.newImageView(spriteName, 0,0,{scale9 = true, capInsets = cc.rect(40,44,10,2), size = cc.size(lsize.width, lsize.height)})
    local back = cc.LayerColor:create(cc.c4b(0,0,0,153))
    display.commonUIParams(back, {ap = cc.p(0,0),po = cc.p(0,0)})
    clipper:setAnchorPoint(cc.p(0.5,0.5))
    clipper:addChild(back)
    local stencil = CLayout:create(cc.size(lsize.width, lsize.height))
    stencil:setAnchorPoint(cc.p(0.5,0.5))
    stencil:setPosition(position)
    stencil:setBackgroundColor(cc.c4b(0,0,0,100))
    clipper:setStencil(stencil)
    clipper:setInverted(true)
    display.commonUIParams(sprite, {po = cc.p(position.x - 0.2, position.y - 0.2)})
    view:addChild(sprite, 1)


    local finger = sp.SkeletonAnimation:create('ui/guide/guide_ico_hand.json', 'ui/guide/guide_ico_hand.atlas', 1)
    finger:setAnimation(0, 'idle', true)--
    local fpos = cc.p(position.x + lsize.width * 0.4, position.y - lsize.height * 0.3)
    local tipsBg = display.newImageView(_res('ui/guide/guide_bg_text'), fpos.x, fpos.y,{scale9 = true, size = cc.size(374, 120)})
    view:addChild(tipsBg, 2)
    local labelparser = require("Game.labelparser")
    local parsedtable = labelparser.parse(tostring(params.text))
    local t = {}
    for name,val in pairs(parsedtable) do
        if val.labelname == 'red' then
            table.insert(t, {text = val.content , fontSize = 23, color = RED_COLOR,descr = val.labelname})
        else
            table.insert(t, {text = val.content , fontSize = 23, color = '#5c5c5c',descr = val.labelname})
        end
    end
    local descrLabel = display.newRichLabel(0, 0,{w = 30,ap = display.LEFT_TOP, c = t})
    display.commonUIParams(descrLabel, { ap = display.LEFT_TOP, po = cc.p(16,100)})
    tipsBg:addChild(descrLabel,2)
    descrLabel:reloadData()

    if location == 1 then
        --左上
        finger:setRotation(-190)
        fpos = cc.p(position.x -lsize.width * 0.3, position.y + lsize.height * 0.3)
        display.commonUIParams(tipsBg, { po = cc.p(fpos.x - 140, fpos.y + 170)})
    elseif location == 2 then
        --右上
        finger:setRotation(-100)
        fpos = cc.p(position.x + lsize.width * 0.3, position.y + lsize.height * 0.3)
        display.commonUIParams(tipsBg, { po = cc.p(fpos.x + 140, fpos.y + 170)})
    elseif location == 3 then
        finger:setScaleX(-1)
        --下方
        fpos = cc.p(position.x - lsize.width * 0.3, position.y - lsize.height * 0.3)
        display.commonUIParams(tipsBg, { po = cc.p(fpos.x - 140, fpos.y - 180 )})
    else
        fpos = cc.p(position.x + lsize.width * 0.3, position.y - lsize.height * 0.3)
        display.commonUIParams(tipsBg, { po = cc.p(fpos.x + 140, fpos.y -180 )})
    end
    display.commonUIParams(finger, {po = fpos})

    view:addChild(finger,3)

    table.insert(fingerNodes, sprite)
    return {
        view = view,
        clipper = clipper,
        fingerNodes = {sprite},
        isCircle = isCircle,
        descrLabel = descrLabel,
    }
end



CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    local actionBtns = {}
    
    local spineFire = ui.spine({path = RES_DIR.FIRE_SPINE, init = 'budo_vs_fire', p = cc.p(display.cx, display.cy)})
    view:addChild(spineFire,99)
    local bg = display.newImageView(RES_DIR.BG, display.cx, display.cy, {ap = display.CENTER, enable = true})
    view:addChild(bg)
    local layer = display.newLayer( display.cx, display.cy, {size= size,ap = display.CENTER,enable = true,color = '#ffffff'})
    layer:setOpacity(0)
    view:addChild(layer,99999)

    -------------------------------------
    -- 顶部块
    local topUILayer = display.newLayer()
    view:addChild(topUILayer,2)

    -- 返回按钮
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DIR.BACK})
    topUILayer:addChild(backBtn)

    -- 标题
    local titleBtn = display.newButton(display.SAFE_L + 120, size.height, {n = RES_DIR.TITLE, ap = display.LEFT_TOP})
    display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('天城演武'), offset = cc.p(0, -10)}))
    topUILayer:addChild(titleBtn)

    -- local titleSize = titleBtn:getContentSize()
    -- local titleRuleBtn = display.newButton(titleBtn:getPositionX() + titleSize.width - 50, titleBtn:getPositionY() - titleSize.height/2 - 10, {n = RES_DIR.BTN_TIPS})
    -- topUILayer:addChild(titleRuleBtn)

    local BOTTOM_ALLIGN_Y = size.height - 100

    -- 商店按钮
    local tagMatchShopBtn = display.newButton(0, 0, {n = RES_DIR.ICON_SHOP})
    display.commonUIParams(tagMatchShopBtn, {po = cc.p(display.SAFE_R - 50, BOTTOM_ALLIGN_Y), ap = display.RIGHT_BOTTOM})
    topUILayer:addChild(tagMatchShopBtn)

    local medalShopLabel = display.newLabel(0, 0, {text = __('演武商店'), fontSize = 22, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#412225'})
    display.commonUIParams(medalShopLabel, {po = cc.p(utils.getLocalCenter(tagMatchShopBtn).x, -4)})
    tagMatchShopBtn:addChild(medalShopLabel)
    actionBtns[tostring(BUTTON_TAG.SHOP)] = tagMatchShopBtn

    --战斗奖励短条
    local rewardBar = display.newImageView(RES_DIR.BTN_GIFT_BG, display.SAFE_R - 200, BOTTOM_ALLIGN_Y, {ap = display.RIGHT_BOTTOM})
    topUILayer:addChild(rewardBar)
    local rewardBarSize = rewardBar:getContentSize()

    local curResidueTitle = display.newLabel(30, rewardBarSize.height/2 + 15, {ap = display.LEFT_CENTER, fontSize = 22, color = '#e28f4b', font = TTF_TEXT_FONT, ttf = true,text = __('次数')})
    rewardBar:addChild(curResidueTitle)
    curResidueTitle.x, curResidueTitle.y = curResidueTitle:getPosition()
    local splitLine = display.newImageView(RES_DIR.LINE_OF_GIFT_TIMES, 0, curResidueTitle.y - 18, {ap = display.LEFT_CENTER,scale = 1.5})
    rewardBar:addChild(splitLine)

    --战斗奖励剩余次数
    local curResidueText = display.newLabel(curResidueTitle.x - 8, curResidueTitle.y - 33, {ap = display.LEFT_CENTER, fontSize = 20, color = '#ffc75f', font = TTF_GAME_FONT, ttf = true, outline = '#471c21', outlineSize = 1})
    rewardBar:addChild(curResidueText)

    local totalText = display.newLabel(curResidueTitle.x + 20, curResidueTitle.y - 33, {ap = display.LEFT_CENTER, fontSize = 20, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#471c21', outlineSize = 1})
    rewardBar:addChild(totalText)

    --战斗奖励展开条
    local rewardSpreadBarImage = display.newImageView(RES_DIR.BTN_GIFT_BG, display.SAFE_R - 200, BOTTOM_ALLIGN_Y, {ap = display.RIGHT_BOTTOM, scale9 = true, size = cc.size(rewardBarSize.width * 3.6, rewardBarSize.height)})
    local rewardSpreadBarSize = rewardSpreadBarImage:getContentSize()
    topUILayer:addChild(rewardSpreadBarImage)

    --战斗奖励按钮
    local rewardBtn = display.newButton(0, 0, {n = RES_DIR.BTN_GIFT})
    display.commonUIParams(rewardBtn, {po = cc.p(display.SAFE_R - 160, BOTTOM_ALLIGN_Y), ap = display.RIGHT_BOTTOM})
    topUILayer:addChild(rewardBtn)
    actionBtns[tostring(BUTTON_TAG.GIFT)] = rewardBtn

    local rewardLabel = display.newLabel(0, 0, {text = __('战斗奖励'), fontSize = 22, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#412225'})
    display.commonUIParams(rewardLabel, {po = cc.p(utils.getLocalCenter(rewardBtn).x, -4)})
    rewardBtn:addChild(rewardLabel)

    --内layer
    local rewardSpreadBar =  display.newLayer(display.SAFE_R - 200, BOTTOM_ALLIGN_Y, { ap = display.RIGHT_BOTTOM, scale9 = true, size = cc.size(rewardBarSize.width * 3.6, rewardBarSize.height)})
    topUILayer:addChild(rewardSpreadBar)
    --进度条
    local progressOne = CProgressBar:create(RES_DIR.BTN_GIFT_PROGRESS_IN_BG)
    local progressSize = progressOne:getContentSize()
    progressOne:setBackgroundImage(RES_DIR.BTN_GIFT_PROGRESS_BG)
    progressOne:setDirection(eProgressBarDirectionLeftToRight)
    progressOne:setAnchorPoint(display.CENTER)
    progressOne:setPosition(cc.p(rewardSpreadBarSize.width/2 -20, rewardSpreadBarSize.height/2))
    -- progressOne:setValue(100)
    rewardSpreadBar:addChild(progressOne)
    --图标
    progressOne:addChild(display.newImageView(RES_DIR.BTN_GIFT_ICON, 0 + 30, progressSize.height/2, {ap = display.RIGHT_CENTER}),22)

    local rewardBoxLayer = display.newLayer(rewardSpreadBarSize.width/2 -20, rewardSpreadBarSize.height/2, {size = progressSize,ap = display.CENTER})
    rewardSpreadBar:addChild(rewardBoxLayer)

    --盒子奖励
    local conf = CONF.NEW_KOF.CHALLENGE:GetAll()
    local boxRewards = {}
    for k, v in pairs(conf) do
        local max = tostring(table.nums(conf))
        local maxRewardTimes = conf[max].targetNum
        local percent = v.targetNum / maxRewardTimes 
        local offsetX = percent * progressSize.width - k * 10
        local box = display.newButton(offsetX, progressSize.height/2, {n = RES_DIR.ICON_BOX, ap = display.LEFT_CENTER})
        rewardBoxLayer:addChild(box)
        box:setTag(v.id)
        local boxSize = box:getContentSize()
        local tagetNumText = display.newLabel(boxSize.width, 10, {ap = display.RIGHT_BOTTOM, fontSize = 20,text = tostring(v.targetNum)})
        box:addChild(tagetNumText)
        table.insert(boxRewards, box)
    end
  
    -------------------------------------
    -- 中部区域（含匹配对手信息+ 自己排名信息）
    
    local middleUILayer = display.newLayer()
    view:addChild(middleUILayer)

    ---中部整个红色背景
    local middleUIBg = display.newLayer(display.cx, size.height / 2 + 50, {ap = display.CENTER, bg = RES_DIR.OPPONENT_BG})
    local middleBgSize = middleUIBg:getContentSize()
    middleUILayer:addChild(middleUIBg)

    ---倒计时
    local countDownTipLabel = display.newLabel(middleBgSize.width/2, middleBgSize.height - 30, {ap = display.CENTER_TOP, fontSize = 22, color = "cb6062",text = __('离结束还有: ')})
    middleUIBg:addChild(countDownTipLabel)
    local countDownLabel = display.newLabel(middleBgSize.width/2 - 5, middleBgSize.height - 55, {ap = display.CENTER_TOP, fontSize = 24, color = 'ffffff', text = '--:--:--'})
    middleUIBg:addChild(countDownLabel)

    --刷新按钮
    local refreshBtn = display.newButton(middleBgSize.width - 45, middleBgSize.height - 50, {n = RES_DIR.REFRESH, ap = display.RIGHT_CENTER})
    middleUIBg:addChild(refreshBtn)
    actionBtns[tostring(BUTTON_TAG.REFRESH)] = refreshBtn

    local textParams  = {ap = display.CENTER, fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#471c21', outlineSize = 1}
    
    --段位
    local curLevelTitle = display.newLabel(50, middleBgSize.height - 40, {ap = display.LEFT_CENTER, fontSize = 22, color = '#e28f4b', font = TTF_TEXT_FONT, ttf = true})
    curLevelTitle:setString(__('段位'))
    middleUIBg:addChild(curLevelTitle)
    curLevelTitle.x, curLevelTitle.y = curLevelTitle:getPosition()

    local lvLineBg = display.newImageView(RES_DIR.LV_LINE, curLevelTitle.x, curLevelTitle.y - 20, {ap = display.LEFT_CENTER})
    middleUIBg:addChild(lvLineBg)

    local curLevelText = display.newLabel(curLevelTitle.x, curLevelTitle.y - 40, {ap = display.LEFT_CENTER, fontSize = 24, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#471c21', outlineSize = 1})
    middleUIBg:addChild(curLevelText)

    --奖励预览按钮
    local lookRewardBtn = display.newButton(130, middleBgSize.height - 355, {n = RES_DIR.REWARD_LOOK_BTN})
    middleUIBg:addChild(lookRewardBtn)
    actionBtns[tostring(BUTTON_TAG.LOOK_REWARD)] = lookRewardBtn
    local lookRewardLabel = display.newLabel(0, 0, {text = __('奖励预览'), fontSize = 22, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#412225'})
    display.commonUIParams(lookRewardLabel, {po = cc.p(utils.getLocalCenter(lookRewardBtn).x, -4)})
    lookRewardBtn:addChild(lookRewardLabel)

    ---玩家排名信息
    local alignHeight = middleBgSize.height - 110
    local msgBg = display.newLayer(130, alignHeight, {bg = RES_DIR.DETAILS_BG, ap = display.CENTER_TOP})
    local bgSize = msgBg:getContentSize()
    middleUIBg:addChild(msgBg)

    -- 当前排名
    --公用UI参数（排名，积分）
    local titleParams = {ap = display.CENTER, fontSize = 22, color = '#873b12', font = TTF_TEXT_FONT, ttf = true}

    local commonX = bgSize.width/2 + 10
    --当前排名
    local bgBar = display.newImageView(RES_DIR.IN_RANK_BG, commonX,  bgSize.height/2 + 80 + 24, {ap = display.CENTER_TOP})
    msgBg:addChild(bgBar)
    local curRankTitle = display.newLabel(commonX, bgSize.height/2 + 80, titleParams)
    curRankTitle:setString(__('当前排名'))
    msgBg:addChild(curRankTitle)
    local titleY = curRankTitle:getPositionY()
    msgBg:addChild(display.newImageView(RES_DIR.LINE_OF_CUT, commonX,  titleY-20, {ap = display.CENTER_TOP}))
    msgBg:addChild(display.newImageView(RES_DIR.ICON_RANK, commonX - 40,  titleY-20, {ap = display.RIGHT_CENTER, scale = 0.4}))

    local curRankLabel = display.newLabel(commonX, titleY-40, textParams)
    curRankLabel:setString("1000")
    msgBg:addChild(curRankLabel)

    local forkLine = display.newImageView(RES_DIR.FORK_LINE, commonX,  bgSize.width/2, {ap = display.CENTER_TOP})
    msgBg:addChild(forkLine)

    -- 当前积分
    local bgScoreBar = display.newImageView(RES_DIR.IN_RANK_BG, commonX,  bgSize.height/2 -20 + 24, {ap = display.CENTER_TOP})
    msgBg:addChild(bgScoreBar)
    local curScoreTitle = display.newLabel(commonX, bgSize.height / 2 - 20 , titleParams)
    curScoreTitle:setString(__('当前积分'))
    msgBg:addChild(curScoreTitle)
    local titleY = curScoreTitle:getPositionY()
    msgBg:addChild(display.newImageView(RES_DIR.LINE_OF_CUT, commonX,  titleY-20, {ap = display.CENTER_TOP}))
    msgBg:addChild(display.newImageView(RES_DIR.ICON_SCORE, commonX - 40,  titleY-20, {ap = display.RIGHT_CENTER,  scale = 0.4}))
    local curScoreLabel = display.newLabel(commonX, titleY-40, textParams)
    msgBg:addChild(curScoreLabel)

   

    -- 排行榜按钮
    local rankBtn = display.newButton(curRankTitle:getPositionX() + 70, curRankTitle:getPositionY(), {n = RES_DIR.BTN_RANK, ap = display.CENTER,scale = 7})
    msgBg:addChild(rankBtn)
    actionBtns[tostring(BUTTON_TAG.RANK)] = rankBtn

    -- 对手列表
    local opponentListLayer = display.newLayer(middleBgSize.width / 2 + 80, alignHeight, {ap = display.CENTER_TOP, bg = RES_DIR.OPPONENT_BG_2})
    local opponentListLayerSize = opponentListLayer:getContentSize()
    middleUIBg:addChild(opponentListLayer)

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
    -- 我方编队信息栏（底部）
    local attackteamUILayer = display.newLayer()
    view:addChild(attackteamUILayer)

    -- 蓝色底板
    local buleBar = display.newImageView(RES_DIR.ATTACKTEAM_BG,-30,30,{ap = display.LEFT_BOTTOM})
    local attackteamBgLayerSize = buleBar:getContentSize()
    attackteamUILayer:addChild(buleBar)

    -- 装饰框
    attackteamUILayer:addChild(display.newImageView(RES_DIR.BLEW_FIGHT_BG, size.width/2, 0, {ap = display.CENTER_BOTTOM}))

    local attackteamBgLayer = display.newLayer(display.cx, 30, {ap = display.CENTER_BOTTOM,size = {width = middleBgSize.width, height = attackteamBgLayerSize.height}})
    attackteamUILayer:addChild(attackteamBgLayer)

    -- 修改编队按钮
    local modifyBtn = display.newButton(130, attackteamBgLayerSize.height/2 - 20, {ap = display.CENTER, n = RES_DIR.BTN_ORANGE})
    display.commonLabelParams(modifyBtn, fontWithColor(14, {text = __('修改编队')}))
    attackteamBgLayer:addChild(modifyBtn)
    actionBtns[tostring(BUTTON_TAG.MODIFY)] = modifyBtn

    -- 修改编队次数限制
    local modifyBar = display.newImageView(RES_DIR.MODIFY_TEAM_BAR, modifyBtn:getPositionX(), modifyBtn:getPositionY() - 50, {ap = display.CENTER})
    local modifyBarSize = modifyBar:getContentSize()
    attackteamBgLayer:addChild(modifyBar)
    local modifyTeamText = display.newLabel(modifyBarSize.width/2, modifyBarSize.height/2, {ap = display.CENTER, color = "ffc75f", text = "3/5", fontSize = 20})
    modifyBar:addChild(modifyTeamText)

    local presetTeamBtn = nil
    if GAME_MODULE_OPEN.PRESET_TEAM and CommonUtils.UnLockModule(JUMP_MODULE_DATA.PRESET_TEAM_TAGMATCH) then
        -- 预设队伍按钮
        presetTeamBtn = require("Game.views.presetTeam.PresetTeamEntranceButton").new({isSelectMode = true, presetTeamType = PRESET_TEAM_TYPE.TAG_MATCH})
        display.commonUIParams(presetTeamBtn, {po = cc.p(
            modifyBtn:getPositionX(),
            modifyBtn:getPositionY() + modifyBtn:getContentSize().height/2 + 35
        )})
        display.commonLabelParams(presetTeamBtn, fontWithColor('14', {text = __('预设编队')}))
        attackteamBgLayer:addChild(presetTeamBtn)
    end

    -- 战报按钮
    local reportBtn = display.newButton(size.width / 2 + 330, 45, {n = _res('ui/pvc/pvp_board_btn_report.png')})
    display.commonLabelParams(reportBtn, fontWithColor(14, {text = __('战报')}))
    attackteamUILayer:addChild(reportBtn)
    actionBtns[tostring(BUTTON_TAG.REPORT)] = reportBtn
    local reportBtnIcon = display.newImageView(_res('ui/pvc/pvp_board_ico_report.png'), 0, 0)
    display.commonUIParams(reportBtnIcon, {po = cc.p(reportBtnIcon:getContentSize().width * 0.5 - 20, utils.getLocalCenter(reportBtn).y)})
    reportBtn:addChild(reportBtnIcon, 5)

    -- 战斗按钮
    local fightBtn = require('common.CommonBattleButton').new()
    fightBtn:setPosition(display.cx + middleBgSize.width/2 - 170, 120)
    attackteamUILayer:addChild(fightBtn)
    actionBtns[tostring(BUTTON_TAG.FIGHT)] = fightBtn

    --攻击次数限制
    local attackTimesBar = display.newLayer(fightBtn:getPositionX(), fightBtn:getPositionY() - 90,{bg = RES_DIR.ATTACK_TIMES_BAR, ap = display.CENTER})
    local attackTimesBarSize = attackTimesBar:getContentSize()
    attackteamUILayer:addChild(attackTimesBar)
    local attackTimesText = display.newLabel(attackTimesBarSize.width/2, attackTimesBarSize.height/2, {ap = display.CENTER, color = "ffc75f", text = "5/5", fontSize = 20})
    attackTimesBar:addChild(attackTimesText)
    local attackTimtesAddBtn = display.newButton(attackTimesBarSize.width + 10, attackTimesBarSize.height/2, {n = _res('ui/common/common_btn_add.png'),ap = display.RIGHT_CENTER})
    attackTimesBar:addChild(attackTimtesAddBtn)
    actionBtns[tostring(BUTTON_TAG.ADD_FIGHT_TIMES)] = attackTimtesAddBtn

    local playerTeamHeadBgLayer = display.newLayer(attackteamBgLayerSize.width/2 , attackteamBgLayerSize.height/2 , {ap = display.CENTER,size = attackteamBgLayerSize})
    attackteamBgLayer:addChild(playerTeamHeadBgLayer)

    local dragAreaLayers    = {}
    local playerTeamHeadBgs = {}
    for i = 1, 3 do
        local offsetX = 430 + (i - 1) * 200
        local playerTeamHeadBg = CreatePlayerTeamHeadBg(i)
        display.commonUIParams(playerTeamHeadBg, {po = cc.p(offsetX , attackteamBgLayerSize.height/2 ), ap = display.CENTER})
        playerTeamHeadBgLayer:addChild(playerTeamHeadBg)
        table.insert(playerTeamHeadBgs, playerTeamHeadBg)

        local dragAreaLayer = CreateDragAreaLayer()
        display.commonUIParams(dragAreaLayer, {po = cc.p(offsetX , attackteamBgLayerSize.height/2 + 20 ), ap = display.CENTER})
        playerTeamHeadBgLayer:addChild(dragAreaLayer)
        dragAreaLayer:setTag(i)
        table.insert(dragAreaLayers, dragAreaLayer)
    end

    return {
           view                 = view,
           backBtn              = backBtn,
        -- titleRuleBtn         = titleRuleBtn,
           actionBtns           = actionBtns,
           countDownLabel       = countDownLabel,
           gridView             = gridView,
           opponentInfoTipLayer = opponentInfoTipLayer,
           curRankLabel         = curRankLabel,
           curLevelText         = curLevelText,
           refreshBtn           = refreshBtn,
           playerTeamHeadBgs    = playerTeamHeadBgs,
           dragAreaLayers       = dragAreaLayers,
           presetTeamBtn        = presetTeamBtn,
           attackTimesText      = attackTimesText,
           rewardSpreadBar      = rewardSpreadBar,
           rewardBar            = rewardBar,
           curScoreLabel        = curScoreLabel,
           curResidueText       = curResidueText,
           totalText            = totalText,
           modifyTeamText       = modifyTeamText,
           progressOne          = progressOne,
           boxRewards           = boxRewards,
           rewardBoxLayer       = rewardBoxLayer,
           rewardSpreadBarImage = rewardSpreadBarImage,
           rewardBtn            = rewardBtn,
           modifyBtn            = modifyBtn,
           msgBg                = msgBg,
           layer     =layer,
    }
end

CreatePlayerTeamHeadBg = function (index)
    --蓝色底板
    local layer = display.newLayer(0, 0, {ap = display.LEFT_TOP, bg = RES_DIR.ATTACKTEAM_HEAD_BG})
    local size = layer:getContentSize()

    --头像框
    local teamHeadLayer = display.newLayer(size.width/2, size.height - 8, {ap = display.CENTER_TOP, bg = RES_DIR.ATTACKTEAM_BG_TEAM})
    local teamBgSize = teamHeadLayer:getContentSize()
    layer:addChild(teamHeadLayer)

    --队伍序号
    local infoLabel = display.newLabel(0,0, {ap = display.CENTER_BOTTOM, fontSize = 24, color = '#ffffff', text = 1})
	infoLabel:setString(string.fmt(__("队伍_num_"), {_num_ = index}))
    display.commonUIParams(infoLabel, {po = cc.p(utils.getLocalCenter(teamHeadLayer).x, -35)})
	teamHeadLayer:addChild(infoLabel)
    
    -- 选中背景
    local selectBg = display.newImageView(RES_DIR.ATTACKTEAM_BG_TEAM_S, teamBgSize.width / 2, teamBgSize.height / 2, {ap = display.CENTER})
    teamHeadLayer:addChild(selectBg)
    selectBg:setVisible(false)

    local clickLayer = display.newLayer(teamBgSize.width / 2, teamBgSize.height / 2, {ap = display.CENTER, size = teamBgSize, color = cc.c4b(0,0,0,0), enable = true})
    teamHeadLayer:addChild(clickLayer)

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


    cardHeadLayer.viewData = {
        cardHeadNode = cardHeadNode
    }
    return cardHeadLayer
end


function NewKofArenaLobbyView:CreateOppoentDescCell(headClick)
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

    local playerName = display.newLabel(size.width / 2, size.height - 30, fontWithColor(5, {ap = display.CENTER}))
    playerProfileUI:addChild(playerName)

    local scoreBg = display.newImageView(_res("ui/tagMatchNew/3v3_home_ico_piont_small.png"),0,bgSize.height,{ap = display.LEFT_CENTER})
	playerProfileUI:addChild(scoreBg)
    local textParams  = {ap = display.CENTER, fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#471c21', outlineSize = 1}
	local integralLabel = display.newLabel(scoreBg:getContentSize().width/2, scoreBg:getContentSize().height/2,textParams)
	scoreBg:addChild(integralLabel)

    local playerHeadNode = require('common.FriendHeadNode').new({
        enable = true, scale = 0.6, showLevel = true, callback = function (playerHeadNode)
            headClick(playerHeadNode)
        end
    })

    display.commonUIParams(playerHeadNode,{po = cc.p(size.width / 2, size.height - 120), ap = display.CENTER})
    playerProfileUI:addChild(playerHeadNode)
    playerHeadNode:setScale(0.8)

    local battlePointBg = display.newImageView(RES_DIR.OPPONENT_CELL_INFO_BG, size.width / 2, 100, {ap = display.CENTER})
    local battlePointBgSize = battlePointBg:getContentSize()
    playerProfileUI:addChild(battlePointBg)

    local battlePointLabel = display.newLabel(10, battlePointBgSize.height / 2, {ap = display.LEFT_CENTER, fontSize = 22, color = '#c9a78f', text = __('灵力：')})
    local battlePointLabelSize = display.getLabelContentSize(battlePointLabel)
    battlePointBg:addChild(battlePointLabel)
    
    local battlePoint = display.newLabel(battlePointLabel:getPositionX() + battlePointLabelSize.width, battlePointBgSize.height / 2, {ap = display.LEFT_CENTER, fontSize = 22, color = '#ffffff', text = 1})
    battlePointBg:addChild(battlePoint)

    local rankBg = display.newImageView(RES_DIR.OPPONENT_CELL_INFO_BG, size.width / 2, 60, {ap = display.CENTER})
    local bgSize = rankBg:getContentSize()
    playerProfileUI:addChild(rankBg)

    local rankLabel = display.newLabel(10, battlePointBgSize.height / 2, {ap = display.LEFT_CENTER, fontSize = 22, color = '#c9a78f', text = __('排名：')})
    local rankLabelSize = display.getLabelContentSize(rankLabel)
    rankBg:addChild(rankLabel)
    
    local rank = display.newLabel(rankLabel:getPositionX() + rankLabelSize.width, bgSize.height / 2, {ap = display.LEFT_CENTER, fontSize = 22, color = '#ffffff', text = 1})
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
        integralLabel = integralLabel,
    }
    return cell
end

function NewKofArenaLobbyView:getViewData()
	return self.viewData_
end

function NewKofArenaLobbyView:getRankTextByRank(rank)
    local text = ''
    if rank <= 0 then
        text = __('未入榜')
    else
        text = tostring(rank)
    end
    return text
end

--获取段位名称
function NewKofArenaLobbyView:getSegmentNameById(segment)
    self.segmentConf  = CONF.NEW_KOF.SEGMENT:GetAll()
    segment = checkint(segment)
    for k, v in pairs(self.segmentConf) do
        if segment == checkint(v.id) then
            return v.name
        end
    end
end

--获取初始积分
function NewKofArenaLobbyView:getInitScore()
    return self.initParamConf.initIntegral
end

--获取最大战斗奖励次数
function NewKofArenaLobbyView:getMaxRewardTimes()
    local len = self:getMaxRewardNums()
    return self.challengeRewardsConf[tostring(len)].targetNum
end

--获取最大奖励数
function NewKofArenaLobbyView:getMaxRewardNums()
    return table.nums(self.challengeRewardsConf)
end


--获取最大修改编队次数
function NewKofArenaLobbyView:getMaxSaveTeamTimes()
    return self.initParamConf.teamTimes
end

--获取最大进攻次数
function NewKofArenaLobbyView:getMaxFightTimes()
    return self.initParamConf.challengeTimes
end

function NewKofArenaLobbyView:getLastScore()
    return cc.UserDefault:getInstance():getIntegerForKey('NEW_KOF_LAST_SCORE')
end
function NewKofArenaLobbyView:setLastScore(score)
    cc.UserDefault:getInstance():setIntegerForKey('NEW_KOF_LAST_SCORE', checkint(score))
    cc.UserDefault:getInstance():flush()
end

return NewKofArenaLobbyView