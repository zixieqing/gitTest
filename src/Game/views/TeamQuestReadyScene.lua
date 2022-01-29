--[[
 * author : kaishiqi
 * descpt : 组队副本 - 准备场景
]]
local GameScene = require('Frame.GameScene')
local TeamQuestReadyScene = class('TeamQuestReadyScene', GameScene)

------------ import ------------
local gameMgr           = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr             = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr           = AppFacade.GetInstance():GetManager('CardManager')
local ModelFactory      = require('Game.models.TeamQuestModelFactory')
local TeamCardModel     = ModelFactory.getModelType('TeamCard')
local TeamPlayerModel   = ModelFactory.getModelType('TeamPlayer')
------------ import ------------

------------ define ------------

local RES_DICT = {
    BTN_BACK                = 'ui/common/common_btn_back.png',
    BTN_HINT                = 'ui/common/common_btn_tips.png',
    BG_IMG                  = 'ui/raid/room/raid_room_bg.jpg',
    TITLE_FRAME             = 'ui/raid/room/raid_room_bg_up.png',
    TITLE_BG                = 'ui/raid/room/raid_room_btn_title.png',
}

local CreateView = nil

local difficultyConfig = {
    ['1'] = __('简单'),
    ['2'] = __('普通'),
    ['3'] = __('困难')
}

local cardHeadNodeSize = cc.size(96, 96)
------------ define ------------


function TeamQuestReadyScene:ctor( ... )
    GameScene.ctor(self, 'Game.views.TeamQuestReadyScene')
    
    xTry(function()
		self.viewData_ = CreateView()
		self:addChild(self.viewData_.view)

        -- 初始化战斗按钮的点击回调
        self:getViewData().battleBtn:SetClickCallback(handler(self, self.BattleReadyClickHandler))
        -- 初始化更换房间密码的点击回调
        display.commonUIParams(self:getViewData().passwordIcon, {cb = handler(self, self.ChangePasswordClickHandler)})
        -- 购买挑战次数的点击回调
        display.commonUIParams(self:getViewData().leftChallengeBtn, {cb = handler(self, self.BuyChallengeTimesClickHandler)})
        -- 关卡详情按钮回调
        display.commonUIParams(self:getViewData().titleBtn, {cb = handler(self, self.StageDetailClickHandler)})
        display.commonUIParams(self:getViewData().questDetailBtn, {cb = handler(self, self.StageDetailClickHandler)})
        -- 语音按钮回调
        display.commonUIParams(self:getViewData().micBtn, {cb = handler(self, self.MicBtnClickHandler)})
        display.commonUIParams(self:getViewData().speakerBtn, {cb = handler(self, self.SpeakerBtnClickHandler)})
        -- 好友标识按钮回调
        display.commonUIParams(self:getViewData().friendIcon, {cb = handler(self, self.FriendIconClickHandler)})
        -- spine小人隐藏按钮
        for i,v in ipairs(self:getViewData().avatarNodes) do
            display.commonUIParams(v.avatarBtn, {cb = handler(self, self.SpineAvatarBtnClickHandler)})
        end
        -- 模块说明按钮回调
        display.commonUIParams(self:getViewData().hintBtn, {cb = handler(self, self.RaidHintBtnClickHandler)})

	end, __G__TRACKBACK__)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()
    view:addChild(display.newImageView(_res(RES_DICT.BG_IMG), size.width/2, size.height/2))

    -------------------------------------------------
    -- ui

    local uiLayer = display.newLayer(0, 0)
    view:addChild(uiLayer, 99)

    local uiLayerSize = uiLayer:getContentSize()

    -- title
    local titleFrame = display.newImageView(_res(RES_DICT.TITLE_FRAME), 0, 0)
    display.commonUIParams(titleFrame, {po = cc.p(uiLayerSize.width * 0.5, uiLayerSize.height - titleFrame:getContentSize().height * 0.5)})
    uiLayer:addChild(titleFrame)

    local titleBtn = display.newButton(0, 0, {n = _res(RES_DICT.TITLE_BG)})
    display.commonUIParams(titleBtn, {po = cc.p(
        titleFrame:getPositionX(),
        titleFrame:getPositionY() + titleFrame:getContentSize().height * 0.5 - titleBtn:getContentSize().height * 0.5
    )})
    uiLayer:addChild(titleBtn)

    local titleLabel = display.newLabel(0, 0, fontWithColor('3', {text = 'test title'}))
    display.commonUIParams(titleLabel, {po = cc.p(
        titleBtn:getContentSize().width * 0.5,
        titleBtn:getContentSize().height * 0.5 + 10
    )})
    titleBtn:addChild(titleLabel)

    local settingIcon = display.newNSprite(_res('ui/raid/room/raid_room_ico_setting.png'), 0, 0)
    display.commonUIParams(settingIcon, {po = cc.p(
        titleBtn:getContentSize().width - settingIcon:getContentSize().width * 0.5 - 20,
        titleBtn:getContentSize().height * 0.5 + 10
    )})
    titleBtn:addChild(settingIcon)

    -- hint 
    local hintBtn = display.newButton(0, 0, {n = _res(RES_DICT.BTN_HINT)})
    display.commonUIParams(hintBtn, {po = cc.p(
        titleFrame:getPositionX() - 230,
        titleFrame:getPositionY() + 15
    )})
    uiLayer:addChild(hintBtn)

    -- pwd icon
    local passwordIcon = display.newImageView(_res('ui/raid/room/raid_room_ico_unlock.png'), 0, 0, {enable = true})
    display.commonUIParams(passwordIcon, {po = cc.p(
        titleFrame:getPositionX() + 220,
        titleFrame:getPositionY() + 15
    )})
    uiLayer:addChild(passwordIcon)

    -- room id
    local roomIdLabel = display.newLabel(0, 0, fontWithColor('9', {ap = display.LEFT_CENTER ,  text = 'test room id', color = '#e0b29b'}))
    display.commonUIParams(roomIdLabel, {po = cc.p(
        titleFrame:getContentSize().width * 0.5 - 540,
        titleFrame:getContentSize().height - 20
    )})
    titleFrame:addChild(roomIdLabel)

    -- quest detail
    local questDetailBtn = display.newImageView(_res('ui/raid/room/raid_room_bg_board.png'), 0, 0, {enable = true})
    display.commonUIParams(questDetailBtn, {ap = cc.p(0.5, 1), po = cc.p(
        titleFrame:getPositionX() + 490,
        uiLayerSize.height
    )})
    uiLayer:addChild(questDetailBtn)

    -------------------------------------------------
    -- bottom card info

    -- card member bg
    local cardMemberBgDefaultSize = cc.size(602, 207)
    local cardMemberBg = display.newImageView(_res('ui/raid/room/raid_room_bg_below.png'), 0, 0,
        {scale9 = true, size = cardMemberBgDefaultSize, capInsets = cc.rect(159, 43, 20, 20)})
    display.commonUIParams(cardMemberBg, {po = cc.p(
        display.SAFE_R - cardMemberBg:getContentSize().width * 0.5 + 60,
        cardMemberBg:getContentSize().height * 0.5
    )})
    uiLayer:addChild(cardMemberBg)

    -- battle button
    local battleBtn = require('common.RaidBattleButton').new({pattern = 1})
    display.commonUIParams(battleBtn, {po = cc.p(
        cardMemberBg:getPositionX() + cardMemberBg:getContentSize().width * 0.5 - 158,
        cardMemberBg:getPositionY() + 25
    )})
    uiLayer:addChild(battleBtn)
    battleBtn:SetSelfEnable(false)

    -- left times
    local leftChallengeBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_add.png')})
    display.commonUIParams(leftChallengeBtn, {po = cc.p(
        cardMemberBg:getPositionX() + cardMemberBg:getContentSize().width * 0.5 - 95,
        cardMemberBg:getPositionY() - cardMemberBg:getContentSize().height * 0.5 + 25
    )})
    uiLayer:addChild(leftChallengeBtn)

    local leftChallengeLabel = display.newLabel(0, 0, fontWithColor('9', {text = '剩余次数:test'}))
    display.commonUIParams(leftChallengeLabel, {ap = cc.p(1, 0.5), po = cc.p(
        leftChallengeBtn:getPositionX() - leftChallengeBtn:getContentSize().width * 0.5 - 10,
        leftChallengeBtn:getPositionY() - 5
    )})
    uiLayer:addChild(leftChallengeLabel)

    -- friend icon
    local friendIcon = display.newImageView(_res('ui/raid/room/raid_room_ico_friendoff.png'), 0, 0, {enable = true})
    display.commonUIParams(friendIcon, {po = cc.p(
        cardMemberBg:getPositionX() + cardMemberBg:getContentSize().width * 0.5 - 305,
        cardMemberBg:getPositionY() - 25
    )})
    uiLayer:addChild(friendIcon)
    -- 功能未实装 隐藏图标
    friendIcon:setVisible(false)

    local bottomPaddingL = 150
    local bottomPaddingR = 350
    local cardHeadNodeBgLayerWidth = cardMemberBg:getContentSize().width - bottomPaddingR - bottomPaddingL
    local cardHeadNodeBgLayerHight = 110

    local cardHeadNodeBgLayer = display.newLayer(0, 0, {size = cc.size(cardHeadNodeBgLayerWidth, cardHeadNodeBgLayerHight)})
    display.commonUIParams(cardHeadNodeBgLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
        cardMemberBg:getPositionX() - cardMemberBg:getContentSize().width * 0.5 + bottomPaddingL + cardHeadNodeBgLayerWidth * 0.5,
        cardMemberBg:getPositionY() - 40
    )})
    uiLayer:addChild(cardHeadNodeBgLayer)
    -- cardHeadNodeBgLayer:setBackgroundColor(cc.c4b(255, 0, 0, 100))

    -------------------------------------------------
    -- center

    -- 初始化spine小人底座
    local avatarBottomPos = {
        [1] = {po = cc.p(size.width * 0.5 - 300, size.height * 0.5 - 30), isLeader = true},
        [2] = {po = cc.p(size.width * 0.5, size.height * 0.5 - 30), isLeader = false},
        [3] = {po = cc.p(size.width * 0.5 + 300, size.height * 0.5 - 30), isLeader = false},
        [4] = {po = cc.p(size.width * 0.5 - 150, size.height * 0.5 - 180), isLeader = false},
        [5] = {po = cc.p(size.width * 0.5 + 150, size.height * 0.5 - 180), isLeader = false}
    }

    local avatarNodes = {}

    for i,v in ipairs(avatarBottomPos) do
        local bottomPath = 'ui/common/tower_bg_team_base.png'
        if v.isLeader then
            bottomPath = 'ui/common/tower_bg_team_base_cap.png'
        end
        local bottom = display.newImageView(_res(bottomPath), v.po.x, v.po.y)
        view:addChild(bottom, 1)

        local light = display.newImageView(_res('ui/common/tower_prepare_bg_light.png'), 0, 0)
        display.commonUIParams(light, {po = cc.p(
            utils.getLocalCenter(bottom).x,
            utils.getLocalCenter(bottom).y + light:getContentSize().height * 0.5
        )})
        bottom:addChild(light, 10)

        if v.isLeader then
            local captainMark = display.newNSprite(_res('ui/home/teamformation/team_ico_captain.png'), 0, 0)
            display.commonUIParams(captainMark, {po = cc.p(
                bottom:getPositionX() - (bottom:getContentSize().width * 0.5 + 20),
                bottom:getPositionY() - 5
            )})
            view:addChild(captainMark, 1)
        end

        local avatarBtn = display.newButton(0, 0, {size = cc.size(150, 200)})
        display.commonUIParams(avatarBtn, {ap = cc.p(0.5, 0), po = cc.p(
            bottom:getPositionX(),
            bottom:getPositionY()
        )})
        view:addChild(avatarBtn, 11)

        avatarBtn:setTag(i)

        avatarNodes[i] = {
            bottomNode = bottom,
            lightNode = light,
            avatarBtn = avatarBtn,
            avatarNode = nil,
            connectSkillNode = nil
        }
    end

    -------------------------------------------------
    -- left team member 


    -------------------------------------------------
    -- back button

    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = _res(RES_DICT.BTN_BACK)})
    view:addChild(backBtn)

    -------------------------------------------------
    -- 聊天和语音

    return {
        view                = view,
        backBtn             = backBtn,
        teamIdLabel         = roomIdLabel,
        titleBtn            = titleBtn,
        titleLabel          = titleLabel,
        passwordIcon        = passwordIcon,
        questDetailBtn      = questDetailBtn,
        questDetailLayer    = nil,
        questDetailIcon     = nil,
        questDetailStars    = {},
        leftChallengeLabel  = leftChallengeLabel,
        cardMemberBg        = cardMemberBg,
        cardHeadNodeBgLayer = cardHeadNodeBgLayer,
        selectCardNodes     = {},
        avatarNodes         = avatarNodes,
        teamMemberPreviewLayer = nil,
        teamMemberPreviewNodes = {},
        teamMemberDetailLayer = nil,
        teamMemberDetailNodes = {},
        battleBtn           = battleBtn,
        uiLayer             = uiLayer,
        leftChallengeBtn    = leftChallengeBtn,
        friendIcon          = friendIcon,
        hintBtn             = hintBtn
    }
end
--[[
刷新队伍预览背景层ui
@params maxPlayerAmount int 最大玩家数
--]]
function TeamQuestReadyScene:InitTeamMemberPreviewBg(maxPlayerAmount)
    ------------ 初始化底层 ------------
    -- 切换按钮
    local teamMemberShowBtn = display.newButton(0, 0,
        {n = _res('ui/raid/room/raid_room_bg_team_switch.png'), cb = handler(self, self.TeamMemberDetailSwitchClickHandler)})

    local showBtnArrow = display.newNSprite(_res('ui/common/common_btn_switch.png'), 0, 0)
    display.commonUIParams(showBtnArrow, {po = utils.getLocalCenter(teamMemberShowBtn)})
    teamMemberShowBtn:addChild(showBtnArrow)

    local defaultTeamMemberPreviewBgSize = cc.size(208, 334)
    local defaultTeamMemberMaxAmount = 2

    local paddingTop = 15
    local paddingBottom = 15

    local cellHeight = (defaultTeamMemberPreviewBgSize.height - paddingTop - paddingBottom) / defaultTeamMemberMaxAmount
    local teamMemberPreviewBgSize = cc.size(
        defaultTeamMemberPreviewBgSize.width,
        cellHeight * maxPlayerAmount + paddingTop + paddingBottom
    )

    local teamMemberPreviewLayerSize = cc.size(
        teamMemberPreviewBgSize.width + teamMemberShowBtn:getContentSize().width,
        teamMemberPreviewBgSize.height
    )

    local teamMemberPreviewLayer = display.newLayer(0, 0, {size = teamMemberPreviewLayerSize})
    display.commonUIParams(teamMemberPreviewLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
        display.SAFE_L + teamMemberPreviewLayerSize.width * 0.5 - 60,
        display.height * 0.55
    )})
    self:getViewData().uiLayer:addChild(teamMemberPreviewLayer, 20)
    -- teamMemberPreviewLayer:setBackgroundColor(cc.c4b(math.random(255), math.random(255), math.random(255), 100))

    local teamMemberPreviewBg = display.newImageView(_res('ui/raid/room/raid_room_bg_team.png'), 0, 0,
        {scale9 = true, size = teamMemberPreviewBgSize, capInsets = cc.rect(4, 4, 99, 99)})
    display.commonUIParams(teamMemberPreviewBg, {po = cc.p(
        teamMemberPreviewBgSize.width * 0.5,
        teamMemberPreviewLayerSize.height * 0.5
    )})
    teamMemberPreviewLayer:addChild(teamMemberPreviewBg)

    display.commonUIParams(teamMemberShowBtn, {ap = cc.p(0, 0.5), po = cc.p(
        teamMemberPreviewBg:getPositionX() + teamMemberPreviewBgSize.width * 0.5 - 3,
        teamMemberPreviewBg:getPositionY()
    )})
    teamMemberPreviewLayer:addChild(teamMemberShowBtn)

    self:getViewData().teamMemberPreviewLayer = teamMemberPreviewLayer
    ------------ 初始化底层 ------------

    local parentLayer = teamMemberPreviewLayer
    local layerSize = parentLayer:getContentSize()

    ------------ 初始化默认图标 ------------
    local defaultWaitingIconSize = cc.size(108, 108)
    local waitingIconSize = defaultWaitingIconSize

    for i = 1, maxPlayerAmount do
        local waitingIcon = display.newImageView(_res('ui/raid/room/raid_room_frame_teammate.png'), 0, 0,
            {scale9 = true, size = waitingIconSize, capInsets = cc.rect(4, 4, 99, 99)})
        display.commonUIParams(waitingIcon, {po = cc.p(
            60 + waitingIconSize.width * 0.5 + 5,
            layerSize.height - paddingTop - (i - 1) * cellHeight - waitingIconSize.height * 0.5 - 10
        )})
        parentLayer:addChild(waitingIcon)

        local waitingLabel = display.newLabel(0, 0, fontWithColor('9',
            {text = __('等待玩家加入……'), w = waitingIcon:getContentSize().width - 10, hAlign = display.TAL}))
        display.commonUIParams(waitingLabel, {po = utils.getLocalCenter(waitingIcon)})
        waitingIcon:addChild(waitingLabel)

        local playerReadyMark = display.newNSprite(_res('ui/common/raid_room_ico_ready.png'), 0, 0)
        display.commonUIParams(playerReadyMark, {po = cc.p(
            waitingIcon:getPositionX(),
            waitingIcon:getPositionY()
        )})
        parentLayer:addChild(playerReadyMark, 20)

        self:getViewData().teamMemberPreviewNodes[i] = {
            waitingNode         = waitingIcon,
            playerHeadNode      = nil,
            speakingNode        = nil,
            readyMarkNode       = playerReadyMark,
            nameNode            = nil,
            captainNode         = nil,
            defaultWaitingIconSize = defaultWaitingIconSize,
            levelLimitNode      = nil,
            challengeTimeLimitNode = nil,
            playerHeadNodeBg    = playerHeadNodeBg
        }
    end
    ------------ 初始化默认图标 ------------
end
--[[
刷新队伍详细层背景ui
@params maxPlayerAmount int 最大玩家数
@params playerCardsAmountConfig list 上阵玩家最大的上卡数量
--]]
function TeamQuestReadyScene:InitTeamMemberDetailBg(maxPlayerAmount, playerCardsAmountConfig)
    ------------ 初始化底层 ------------
    local teamMemberShowBtn = display.newButton(0, 0,
        {n = _res('ui/raid/room/raid_room_bg_team_switch.png'), cb = handler(self, self.TeamMemberDetailSwitchClickHandler)})

    local showBtnArrow = display.newNSprite(_res('ui/common/common_btn_switch.png'), 0, 0)
    display.commonUIParams(showBtnArrow, {po = utils.getLocalCenter(teamMemberShowBtn)})
    teamMemberShowBtn:addChild(showBtnArrow)
    showBtnArrow:setScaleX(-1)

    local defaultTeamMemberDetailBgSize = cc.size(208, 334)
    local defaultTeamMemberMaxAmount = 2

    local paddingTop = 15
    local paddingBottom = 15
    local maxPlayerCardsAmount = 0
    for i,v in ipairs(playerCardsAmountConfig) do
        maxPlayerCardsAmount = math.max(maxPlayerCardsAmount, checkint(v))
    end
    local cardHeadNodeCellSize = cc.size(cardHeadNodeSize.width + 5, cardHeadNodeSize.height)

    local cellHeight = (defaultTeamMemberDetailBgSize.height - paddingTop - paddingBottom) / defaultTeamMemberMaxAmount
    local teamMemberDetailBgSize = cc.size(
        defaultTeamMemberDetailBgSize.width + cardHeadNodeCellSize.width * maxPlayerCardsAmount,
        cellHeight * maxPlayerAmount + paddingTop + paddingBottom
    )

    local teamMemberDetailLayerSize = cc.size(
        teamMemberDetailBgSize.width + teamMemberShowBtn:getContentSize().width,
        teamMemberDetailBgSize.height
    )

    local teamMemberDetailLayer = display.newLayer(0, 0, {size = teamMemberDetailLayerSize})
    display.commonUIParams(teamMemberDetailLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
        display.SAFE_L + teamMemberDetailLayerSize.width * 0.5 - 60,
        display.height * 0.55
    )})
    self:getViewData().uiLayer:addChild(teamMemberDetailLayer, 20)
    -- teamMemberDetailLayer:setBackgroundColor(cc.c4b(math.random(255), math.random(255), math.random(255), 200))

    local teamMemberDetailBg = display.newImageView(_res('ui/raid/room/raid_room_bg_team.png'), 0, 0,
        {scale9 = true, size = teamMemberDetailBgSize, capInsets = cc.rect(65, 20, 10, 10)})
    display.commonUIParams(teamMemberDetailBg, {po = cc.p(
        teamMemberDetailBgSize.width * 0.5,
        teamMemberDetailLayerSize.height * 0.5
    )})
    teamMemberDetailLayer:addChild(teamMemberDetailBg)

    display.commonUIParams(teamMemberShowBtn, {ap = cc.p(0, 0.5), po = cc.p(
        teamMemberDetailBg:getPositionX() + teamMemberDetailBg:getContentSize().width * 0.5 - 3,
        teamMemberDetailBg:getPositionY()
    )})
    teamMemberDetailLayer:addChild(teamMemberShowBtn)

    self:getViewData().teamMemberDetailLayer = teamMemberDetailLayer
    ------------ 初始化底层 ------------

    local parentLayer = teamMemberDetailLayer
    local layerSize = parentLayer:getContentSize()

    ------------ 初始化默认图标 ------------
    local defaultWaitingIconSize = cc.size(108, 108)
    local waitingIconSize = cc.size(
        defaultWaitingIconSize.width + cardHeadNodeCellSize.width * maxPlayerCardsAmount,
        defaultWaitingIconSize.height
    )

    for i = 1, maxPlayerAmount do
        local waitingIcon = display.newImageView(_res('ui/raid/room/raid_room_frame_teammate.png'), 0, 0,
            {scale9 = true, size = waitingIconSize, capInsets = cc.rect(4, 4, 99, 99)})
        display.commonUIParams(waitingIcon, {po = cc.p(
            60 + waitingIconSize.width * 0.5 + 5,
            layerSize.height - paddingTop - (i - 1) * cellHeight - waitingIconSize.height * 0.5 - 10
        )})
        parentLayer:addChild(waitingIcon)

        local waitingLabel = display.newLabel(0, 0, fontWithColor('9', {text = __('等待玩家加入……')}))
        display.commonUIParams(waitingLabel, {ap = cc.p(0, 0.5), po = cc.p(
            10,
            utils.getLocalCenter(waitingIcon).y
        )})
        waitingIcon:addChild(waitingLabel)

        local playerReadyMark = display.newNSprite(_res('ui/common/raid_room_ico_ready.png'), 0, 0)
        display.commonUIParams(playerReadyMark, {po = cc.p(
            waitingIcon:getPositionX() - waitingIconSize.width * 0.5 + defaultWaitingIconSize.width * 0.5,
            waitingIcon:getPositionY()
        )})
        parentLayer:addChild(playerReadyMark, 20)
        playerReadyMark:setVisible(false)

        -- 初始化空卡牌槽位
        local cardHeadNodes = {}
        local playerCardsAmount = checkint(playerCardsAmountConfig[i])

        for cardPos = 1, playerCardsAmount do
            local emptyCardHeadBg = display.newImageView(_res('ui/common/kapai_frame_bg_nocard.png'), 0, 0)
            local scale = cardHeadNodeSize.width / emptyCardHeadBg:getContentSize().width
            emptyCardHeadBg:setScale(scale)

            local emptyCardHeadFrame = display.newImageView(_res('ui/common/kapai_frame_nocard.png'), 0, 0)
            display.commonUIParams(emptyCardHeadFrame, {po = utils.getLocalCenter(emptyCardHeadBg)})
            emptyCardHeadBg:addChild(emptyCardHeadFrame)

            local btn = display.newButton(0, 0, {size = cc.size(
                emptyCardHeadBg:getContentSize().width * scale,
                emptyCardHeadBg:getContentSize().height * scale
            )})
            display.commonUIParams(btn, {po = cc.p(
                waitingIcon:getPositionX() - waitingIconSize.width * 0.5 + defaultWaitingIconSize.width + (cardPos - 0.5) * cardHeadNodeCellSize.width,
                waitingIcon:getPositionY()
            )})
            parentLayer:addChild(btn, 20)

            display.commonUIParams(emptyCardHeadBg, {po = cc.p(
                btn:getPositionX(),
                btn:getPositionY()
            )})
            parentLayer:addChild(emptyCardHeadBg, 10)

            cardHeadNodes[cardPos] = {
                btnNode = btn,
                bgNode = emptyCardHeadBg,
                headNode = nil
            }
        end

        self:getViewData().teamMemberDetailNodes[i] = {
            waitingNode         = waitingIcon,
            playerHeadNode      = nil,
            speakingNode        = nil,
            readyMarkNode       = playerReadyMark,
            nameNode            = nil,
            captainNode         = nil,
            cardHeadNodes       = cardHeadNodes,
            defaultWaitingIconSize = defaultWaitingIconSize,
            levelLimitNode      = nil,
            challengeTimeLimitNode = nil,
            playerHeadNodeBg    = nil
        }
    end
    ------------ 初始化默认图标 ------------
end
---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
根据信息刷新界面UI
@params data table {
    teamId int 队伍id号
    password string 密码
    stageId int 关卡id
    leftChallengeTimes int 剩余挑战次数
    maxCardAmount int 可以上阵的卡牌最大数量
    maxPlayerAmount int 最大可以参与的队员
    playerCardsAmountConfig table 战斗人员上卡数量限制
}
--]]
function TeamQuestReadyScene:RefreshUI(data)
    -- 刷新房间id
    self:RefreshTeamId(data.teamId)
    -- 刷新密码
    self:RefreshPasswordIcon(data.password)
    -- 刷新关卡信息
    self:RefreshStageInfoByStageId(data.stageId)
    -- 刷新剩余挑战次数
    self:RefreshLeftTimes(data.leftChallengeTimes)
    -- 刷新底部上阵卡牌槽位
    self:RefreshCardMemberBg(data.maxCardAmount, data.showCaptainMark)
    -- 刷新左侧两个队员展示层
    self:InitTeamMemberPreviewBg(data.maxPlayerAmount)
    -- 刷新左侧两个队员的详细展示层
    self:InitTeamMemberDetailBg(data.maxPlayerAmount, data.playerCardsAmountConfig)

    -- 默认显示队员预览
    self:getViewData().teamMemberPreviewLayer:setVisible(true)
    self:getViewData().teamMemberDetailLayer:setVisible(false)
end
--[[
根据房间id刷新界面
@params id int 房间id
--]]
function TeamQuestReadyScene:RefreshTeamId(id)
    display.commonLabelParams(self:getViewData().teamIdLabel , {reqW =180 ,   text = string.format(__('队伍号: %d'), checkint(id))  })
end
--[[
根据关卡id刷新ui
@params stageId int 关卡id
--]]
function TeamQuestReadyScene:RefreshStageInfoByStageId(stageId)
    local stageConfig = CommonUtils.GetQuestConf(stageId)
    if nil ~= stageConfig then
        local stageFixedName
        self:RefreshTeamName(self:getStageFixedName(stageId))

        -- 刷新关卡信息板
        self:RefreshStageInfoBoard(stageId)
    end
end
--[[
刷新房间名
@params teamName string 房间名
--]]
function TeamQuestReadyScene:RefreshTeamName(teamName)
    --self:getViewData().titleLabel:setString(teamName)
    display.commonLabelParams(self:getViewData().titleLabel , {text = teamName , reqW =300  })
end
--[[
刷新关卡介绍板
@params stageId int 关卡id
--]]
function TeamQuestReadyScene:RefreshStageInfoBoard(stageId)
    local stageConfig = CommonUtils.GetQuestConf(stageId)
    if nil ~= stageConfig then
        if nil == self:getViewData().questDetailLayer then
            local layerSize = cc.size(150, 150)
            local layer = display.newLayer(0, 0, {size = layerSize})
            -- layer:setBackgroundColor(cc.c4b(255, 0, 0, 100))
            display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(
                utils.getLocalCenter(self:getViewData().questDetailBtn).x,
                utils.getLocalCenter(self:getViewData().questDetailBtn).y
            )})
            -- layer:setRotation(-3)
            self:getViewData().questDetailBtn:addChild(layer)

            self:getViewData().questDetailLayer = layer

            local bottomLayer = display.newLayer(0, 0, {size = cc.size(layerSize.width - 30, layerSize.height - 30), color = '#ffffff'})
            display.commonUIParams(bottomLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
                utils.getLocalCenter(layer).x,
                utils.getLocalCenter(layer).y + 15
            )})
            bottomLayer:setTag(3)
            layer:addChild(bottomLayer)

            local monsterIcon = display.newImageView(AssetsUtils.GetCardHeadPath(stageConfig.icon), 0, 0)
            display.commonUIParams(monsterIcon, {po = utils.getLocalCenter(bottomLayer)})
            monsterIcon:setScale((bottomLayer:getContentSize().width - 20) / monsterIcon:getContentSize().width)
            bottomLayer:addChild(monsterIcon)

            self:getViewData().questDetailIcon = monsterIcon
        else
            self:getViewData().questDetailIcon:setTexture(AssetsUtils.GetCardHeadPath(stageConfig.icon))
            for i,v in ipairs(self:getViewData().questDetailStars) do
                v:removeFromParent()
            end
            self:getViewData().questDetailStars = {}
        end

        local bottomLayer = self:getViewData().questDetailLayer:getChildByTag(3)
        -- 威胁星级
        local starAmount = checkint(stageConfig.recommendCombatValue)
        local starScale = 0.8
        for i = 1, starAmount do
            local star = display.newNSprite(_res('ui/home/raidChaptersDetail/boss_info_star_bk.png'), 0, 0)
            display.commonUIParams(star, {po = cc.p(
                bottomLayer:getPositionX() + (i - 0.5 - starAmount * 0.5) * (star:getContentSize().width * starScale + 2),
                bottomLayer:getPositionY() - bottomLayer:getContentSize().height * 0.5 - 15
            )})
            self:getViewData().questDetailLayer:addChild(star)
            star:setScale(starScale)
            table.insert(self:getViewData().questDetailStars, star)
        end
    end
end
--[[
刷新密码标识
@params password string 密码
--]]
function TeamQuestReadyScene:RefreshPasswordIcon(password)
    local hasPwd = string.len(string.gsub(password, ' ', '')) > 0
    if hasPwd then
        self:getViewData().passwordIcon:setTexture(_res('ui/common/common_ico_lock.png'))
    else
        self:getViewData().passwordIcon:setTexture(_res('ui/raid/room/raid_room_ico_unlock.png'))
    end
end
--[[
刷新剩余次数
@params leftTimes int 剩余次数
--]]
function TeamQuestReadyScene:RefreshLeftTimes(leftTimes)
    self:getViewData().leftChallengeLabel:setString(string.format(__('剩余次数:%d'), leftTimes))
end
--[[
根据卡牌数量刷新底部卡牌槽底图
@params maxCardAmount int 最大卡牌数量
@params showCaptainMark bool 是否显示队长标识
--]]
function TeamQuestReadyScene:RefreshCardMemberBg(maxCardAmount, showCaptainMark)
    local bottomPaddingL = 150
    local bottomPaddingR = 350

    local cellSize = cc.size(cardHeadNodeSize.width + 10, cardHeadNodeSize.width + 10)

    local cardHeadNodeBgLayerWidth = maxCardAmount * (cellSize.width)
    local cardHeadNodeBgLayerHight = 110

    local cardMemberBgSize = cc.size(
        bottomPaddingL + cardHeadNodeBgLayerWidth + bottomPaddingR,
        self:getViewData().cardMemberBg:getContentSize().height
    )

    local cardHeadNodeBgLayerSize = cc.size(
        cardHeadNodeBgLayerWidth,
        cardHeadNodeBgLayerHight
    )

    -- 设置底图大小
    self:getViewData().cardMemberBg:setContentSize(cardMemberBgSize)
    self:getViewData().cardHeadNodeBgLayer:setContentSize(cardHeadNodeBgLayerSize)

    -- 重新设置ui位置
    display.commonUIParams(self:getViewData().cardMemberBg, {po = cc.p(
        display.SAFE_R - self:getViewData().cardMemberBg:getContentSize().width * 0.5 + 60,
        self:getViewData().cardMemberBg:getContentSize().height * 0.5
    )})

    display.commonUIParams(self:getViewData().cardHeadNodeBgLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
        self:getViewData().cardMemberBg:getPositionX() - cardMemberBgSize.width * 0.5 + bottomPaddingL + cardHeadNodeBgLayerWidth * 0.5,
        self:getViewData().cardMemberBg:getPositionY() - 40
    )})

    -- 刷新可选槽位按钮
    for i,v in ipairs(self:getViewData().selectCardNodes) do
        if nil ~= v.addNode then
            v.addNode:removeFromParent()
        end

        if nil ~= v.cardHeadNode then
            v.cardHeadNode:removeFromParent()
        end
    end
    self:getViewData().selectCardNodes = {}

    for i = 1, maxCardAmount do
        local addCardBtnImg = display.newImageView(_res('ui/common/kapai_frame_bg_nocard.png'), 0, 0)
        local scale = cardHeadNodeSize.width / addCardBtnImg:getContentSize().width
        addCardBtnImg:setScale(scale)

        local addCardFrame = display.newImageView(_res('ui/common/kapai_frame_nocard.png'), 0, 0)
        display.commonUIParams(addCardFrame, {po = utils.getLocalCenter(addCardBtnImg)})
        addCardBtnImg:addChild(addCardFrame, 10)

        local btnSize = cc.size(
            addCardBtnImg:getContentSize().width * scale,
            addCardBtnImg:getContentSize().height * scale
        )
        local addCardBtn = display.newButton(0, 0, {size = btnSize})
        display.commonUIParams(addCardBtn, {po = cc.p(
            (i - 0.5) * cellSize.width,
            cardHeadNodeBgLayerSize.height * 0.5
        ), cb = handler(self, self.ChangeCardClickHandler)})
        self:getViewData().cardHeadNodeBgLayer:addChild(addCardBtn, 10)
        addCardBtn:setTag(i)

        display.commonUIParams(addCardBtnImg, {po = cc.p(
            addCardBtn:getPositionX(),
            addCardBtn:getPositionY()
        )})
        self:getViewData().cardHeadNodeBgLayer:addChild(addCardBtnImg)

        local addIcon = display.newNSprite(_res('ui/common/maps_fight_btn_pet_add.png'), 0, 0)
        display.commonUIParams(addIcon, {po = utils.getLocalCenter(addCardBtnImg)})
        addIcon:setScale(1 / scale)
        addCardBtnImg:addChild(addIcon)

        if showCaptainMark and 1 == i then
            local captainMark = display.newImageView(_res('ui/home/teamformation/team_ico_captain.png'), 0, 0)
            display.commonUIParams(captainMark, {po = cc.p(
                addCardBtn:getPositionX(),
                addCardBtn:getPositionY() + btnSize.height * 0.5
            )})
            self:getViewData().cardHeadNodeBgLayer:addChild(captainMark, 20)
        end

        self:getViewData().selectCardNodes[i] = {
            addNode = addCardBtn,
            addImgNode = addCardBtnImg,
            cardHeadNode = nil
        }
    end
end
--[[
装备一张卡牌
@params cardModel TeamCardModel 卡牌数据
--]]
function TeamQuestReadyScene:EquipACard(cardModel)
    local cardId = cardModel:getCardId()
    local pos = cardModel:getPlace()
    local skinId = cardModel:getCardSkinId()

    -- 刷新spine小人
    self:RefreshAvatarSpine(pos, skinId)
    -- 刷新连携技
    self:RefreshConnectSkillNode(pos, cardId)
end
--[[
卸下一张卡牌
@params cardModel TeamCardModel 卡牌数据
--]]
function TeamQuestReadyScene:UnequipACard(cardModel)
    local pos = cardModel:getPlace() 
    local nodes = self:getViewData().avatarNodes[pos]

    --[[
    avatarNodes[i] = {
        bottomNode = bottom,
        lightNode = light
        avatarNode = nil,
        connectSkillNode = nil
    }
    --]]

    if nil ~= nodes.avatarNode then
        nodes.avatarNode:removeFromParent()
        self:getViewData().avatarNodes[pos].avatarNode = nil
    end

    if nil ~= nodes.connectSkillNode then
        nodes.connectSkillNode:removeFromParent()
        self:getViewData().avatarNodes[pos].connectSkillNode = nil
    end

    nodes.lightNode:setVisible(true)
end
--[[
刷新spine小人
@params pos int 卡牌位置
@params skinId int 皮肤id
--]]
function TeamQuestReadyScene:RefreshAvatarSpine(pos, skinId)
    local nodes = self:getViewData().avatarNodes[pos]

    --[[
    avatarNodes[i] = {
        bottomNode = bottom,
        lightNode = light
        avatarNode = nil,
        connectSkillNode = nil
    }
    --]]

    -- 隐藏光
    nodes.lightNode:setVisible(false)

    if nil ~= nodes.avatarNode then
        nodes.avatarNode:removeFromParent()
        self:getViewData().avatarNodes[pos].avatarNode = nil
    end

    ------------ 卡牌spine小人 ------------
    local avatarSpine = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 0.5})
    avatarSpine:update(0)
    avatarSpine:setAnimation(0, 'idle', true)
    avatarSpine:setPosition(cc.p(
        nodes.bottomNode:getContentSize().width * 0.5,
        nodes.bottomNode:getContentSize().height * 0.5 + 5
    ))
    nodes.bottomNode:addChild(avatarSpine, 5)

    self:getViewData().avatarNodes[pos].avatarNode = avatarSpine
    ------------ 卡牌spine小人 ------------
end
--[[
刷新连携技按钮
@params pos int 卡牌位置
@params cardId int 卡牌id
--]]
function TeamQuestReadyScene:RefreshConnectSkillNode(pos, cardId)
    local nodes = self:getViewData().avatarNodes[pos]

    --[[
    avatarNodes[i] = {
        bottomNode = bottom,
        lightNode = light
        avatarNode = nil,
        connectSkillNode = nil
    }
    --]]

    if nil ~= nodes.connectSkillNode then
        nodes.connectSkillNode:removeFromParent()
        self:getViewData().avatarNodes[pos].connectSkillNode = nil
    end

    ------------ 卡牌连携技按钮 ------------
    local connectSkillId = CardUtils.GetCardConnectSkillId(cardId)
    if nil ~= connectSkillId then
        local skillNode = self:GetAConnectSkillNodeBySkillId(connectSkillId)
        display.commonUIParams(skillNode, {po = cc.p(
            nodes.bottomNode:getContentSize().width * 0.5,
            nodes.bottomNode:getContentSize().height * 0.5 + 5
        )})
        nodes.bottomNode:addChild(skillNode, 10)

        self:getViewData().avatarNodes[pos].connectSkillNode = skillNode
    end
    ------------ 卡牌连携技按钮 ------------
end
--[[
根据技能id获取一个连携技图标
@params skillId int 技能id
--]]
function TeamQuestReadyScene:GetAConnectSkillNodeBySkillId(skillId)
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
根据位置刷新连携技状态
@params pos int 卡牌位置
@params enable bool 是否激活
--]]
function TeamQuestReadyScene:RefreshConnectSkillNodeState(pos, enable)
    local nodes = self:getViewData().avatarNodes[pos]
    if nil ~= nodes.connectSkillNode then
        if enable then
            nodes.connectSkillNode:getChildByTag(3):setColor(cc.c4b(255, 255, 255, 255))
        else
            nodes.connectSkillNode:getChildByTag(3):setColor(cc.c4b(100, 100, 100, 100))
        end
    end
end
--[[
根据上卡位置刷新界面
@params index int 上卡序号
@params cardModel TeamCardModel 卡牌数据 
--]]
function TeamQuestReadyScene:RefreshAddCardHeadNode(index, cardModel)
    local nodes = self:getViewData().selectCardNodes[index]

    --[[
    {
        addNode = addCardBtn,
        addImgNode = addCardBtnImg,
        cardHeadNode = nil
    })
    --]]

    local cardId = cardModel:getCardId()
    local cardHeadNode = nodes.cardHeadNode

    if TeamCardModel.REMOVE_CARD_ID == cardId then
        -- 置空
        if nil ~= cardHeadNode then
            cardHeadNode:setVisible(false)
            nodes.addImgNode:setVisible(true)
        end
    else
        if nil == cardHeadNode then
            cardHeadNode = require('common.CardHeadNode').new({
                id = cardModel:getPlayerCardId(),
                showBaseState = true,
                showActionState = false,
                showVigourState = false
            })
            -- cardHeadNode:setScale((nodes.addNode:getContentSize().width + 4) / cardHeadNode:getContentSize().width)
            cardHeadNode:setScale((cardHeadNodeSize.width) / cardHeadNode:getContentSize().width)
            display.commonUIParams(cardHeadNode, {po = cc.p(
                nodes.addNode:getPositionX(),
                nodes.addNode:getPositionY()
            )})
            nodes.addNode:getParent():addChild(cardHeadNode, nodes.addNode:getLocalZOrder() - 1)

            self:getViewData().selectCardNodes[index].cardHeadNode = cardHeadNode
        else
            cardHeadNode:RefreshUI({
                id = cardModel:getPlayerCardId()
            })
            cardHeadNode:setVisible(true)
        end
        nodes.addImgNode:setVisible(false)
    end
end
--[[
根据玩家位置和玩家信息刷新界面
@params pos int 玩家位置
@params playerModel TeamPlayerModel 玩家模型
@params isCaptain bool 是否是队长
--]]
function TeamQuestReadyScene:RefreshTeamMember(pos, playerModel, isCaptain)
    -- 刷新预览界面
    self:RefreshTeamMemberPreviewLayer(checkint(pos), playerModel, isCaptain)
    -- 刷新详细界面
    self:RefreshTeamMemberDetailLayer(checkint(pos), playerModel, isCaptain)
    -- 刷新准备状态
    self:RefreshTeamMemberReadyState(pos, playerModel)
    if playerModel then
        if 0 ~= playerModel:getPlayerId() and checkint(gameMgr:GetUserInfo().playerId) ~= playerModel:getPlayerId() then
            -- 刷新好友状态
            self:RefreshFriendIcon(CommonUtils.GetIsFriendById(checkint(playerModel:getPlayerId())))
        end
    else
        self:RefreshFriendIcon(false)
    end
end
--[[
刷新成员预览层
@params pos int 玩家位置
@params playerModel TeamPlayerModel 玩家模型
@params isCaptain bool 是否是队长
--]]
function TeamQuestReadyScene:RefreshTeamMemberPreviewLayer(pos, playerModel, isCaptain)
    local nodes = self:getViewData().teamMemberPreviewNodes[pos]
    local parentLayer = self:getViewData().teamMemberPreviewLayer
    --[[
    {
        waitingNode         = waitingIcon,
        playerHeadNode      = nil,
        speakingNode        = nil,
        readyMarkNode       = playerReadyMark,
        nameNode            = nil,
        captainNode         = nil,
        defaultWaitingIconSize = defaultWaitingIconSize
        levelLimitNode      = nil,
        challengeTimeLimitNode = nil,
        playerHeadNodeBg    = playerHeadNodeBg
    }
    --]]

    if nil == playerModel or 0 == playerModel:getPlayerId() then
        -- 玩家为空 置为等待
        nodes.waitingNode:setVisible(true)

        if nil ~= nodes.playerHeadNodeBg then
            nodes.playerHeadNodeBg:setVisible(false)
        end

    else
        -- 有玩家 刷新界面
        nodes.waitingNode:setVisible(false)

        if nil ~= nodes.playerHeadNode then
            nodes.playerHeadNode:removeFromParent()
            self:getViewData().teamMemberPreviewNodes[pos].playerHeadNode = nil
        end

        local waitingNodeSize = nodes.waitingNode:getContentSize()

        local playerHeadNodeBg = nodes.playerHeadNodeBg
        if nil == playerHeadNodeBg then
            playerHeadNodeBg = display.newLayer(0, 0, {size = waitingNodeSize})
            display.commonUIParams(playerHeadNodeBg, {ap = cc.p(0.5, 0.5), po = cc.p(
                nodes.waitingNode:getPositionX(),
                nodes.waitingNode:getPositionY()
            )})
            parentLayer:addChild(playerHeadNodeBg)

            self:getViewData().teamMemberPreviewNodes[pos].playerHeadNodeBg = playerHeadNodeBg

            -- 准备层
            local readyBgImg = display.newImageView(_res('ui/raid/room/raid_room_frame_ready.png'), 0, 0,
                {scale9 = true, size = waitingNodeSize, capInsets = cc.rect(4, 4, 99, 99)})
            display.commonUIParams(readyBgImg, {po = utils.getLocalCenter(readyBgImg)})
            playerHeadNodeBg:addChild(readyBgImg)
            readyBgImg:setVisible(false)
            readyBgImg:setTag(5)
        end

        playerHeadNodeBg:setVisible(true)

        -- 重新创建底图
        if nil ~= playerHeadNodeBg:getChildByTag(3) then
            playerHeadNodeBg:getChildByTag(3):removeFromParent()
        end

        local bgPath = 'ui/raid/room/raid_room_frame_teammate.png'
        if checkint(gameMgr:GetUserInfo().playerId) == playerModel:getPlayerId() then
            bgPath = 'ui/raid/room/raid_room_frame_self.png'
        end

        local bgImg = display.newImageView(_res(bgPath), 0, 0, {scale9 = true, size = waitingNodeSize, capInsets = cc.rect(4, 4, 99, 99)})
        display.commonUIParams(bgImg, {po = utils.getLocalCenter(playerHeadNodeBg)})
        playerHeadNodeBg:addChild(bgImg)
        bgImg:setTag(3)

        ------------ 玩家头像 ------------
        local playerHeadNode = require('common.PlayerHeadNode').new({
            playerId = checkint(playerModel:getPlayerId()),
            avatar = playerModel:getAvatar(),
            avatarFrame = playerModel:getAvatarFrame(),
            showLevel = true,
            playerLevel = playerModel:getLevel(),
            defaultCallback = true  
        })

        display.commonUIParams(playerHeadNode, {po = cc.p(
            nodes.defaultWaitingIconSize.width * 0.5,
            waitingNodeSize.height * 0.5
        )})
        playerHeadNodeBg:addChild(playerHeadNode, 5)
        self:getViewData().teamMemberPreviewNodes[pos].playerHeadNode = playerHeadNode

        local playerHeadNodeScale = 0.65
        playerHeadNode:setScale(playerHeadNodeScale)
        ------------ 玩家头像 ------------

        local playerHeadNodeSize = cc.size(
            playerHeadNode:getContentSize().width * playerHeadNodeScale,
            playerHeadNode:getContentSize().height * playerHeadNodeScale
        )

        ------------ 等级限制标识 ------------
        local levelLimitNode = nodes.levelLimitNode
        if nil == levelLimitNode then
            levelLimitNode = display.newImageView(_res('ui/raid/room/raid_room_label_warning.png'), 0, 0)
            display.commonUIParams(levelLimitNode, {po = cc.p(
                playerHeadNode:getPositionX(),
                waitingNodeSize.height * 0.75
            )})
            playerHeadNodeBg:addChild(levelLimitNode, 25)

            local levelLimitLabel = display.newLabel(0, 0, fontWithColor('9', {text = __('等级不足')}))
            display.commonUIParams(levelLimitLabel, {po = utils.getLocalCenter(levelLimitNode)})
            levelLimitNode:addChild(levelLimitLabel)

            self:getViewData().teamMemberPreviewNodes[pos].levelLimitNode = levelLimitNode
        end
        ------------ 等级限制标识 ------------

        ------------ 次数限制标识 ------------
        local challengeTimeLimitNode = nodes.challengeTimeLimitNode
        if nil == challengeTimeLimitNode then
            challengeTimeLimitNode = display.newImageView(_res('ui/raid/room/raid_room_label_warning.png'), 0, 0)
            display.commonUIParams(challengeTimeLimitNode, {po = cc.p(
                playerHeadNode:getPositionX(),
                waitingNodeSize.height * 0.45
            )})
            playerHeadNodeBg:addChild(challengeTimeLimitNode, 25)

            local challengeTimeLimitLabel = display.newLabel(0, 0, fontWithColor('9', {text = __('次数不足')}))
            display.commonUIParams(challengeTimeLimitLabel, {po = utils.getLocalCenter(challengeTimeLimitNode)})
            challengeTimeLimitNode:addChild(challengeTimeLimitLabel)

            self:getViewData().teamMemberPreviewNodes[pos].challengeTimeLimitNode = challengeTimeLimitNode
        end
        ------------ 次数限制标识 ------------

        ------------ 玩家名字 ------------
        local nameNode = nodes.nameNode
        if nil == nameNode then
            nameNode = display.newImageView(_res('ui/raid/room/raid_room_label_name.png'), 0, 0,
                {scale9 = true, size = cc.size(waitingNodeSize.width, 25)})
            display.commonUIParams(nameNode, {po = cc.p(
                waitingNodeSize.width * 0.5,
                -nameNode:getContentSize().height * 0.5
            )})
            playerHeadNodeBg:addChild(nameNode, 10)

            self:getViewData().teamMemberPreviewNodes[pos].nameNode = nameNode

            local nameLabel = display.newLabel(0, 0, fontWithColor('9', {text = tostring(playerModel:getName())}))
            display.commonUIParams(nameLabel, {ap = cc.p(0, 0.5), po = cc.p(
                5,
                utils.getLocalCenter(nameNode).y
            )})
            nameNode:addChild(nameLabel)
            nameLabel:setTag(3)
        else
            nameNode:setVisible(true)
            nameNode:getChildByTag(3):setString(tostring(playerModel:getName()))
        end
        ------------ 玩家名字 ------------

        ------------ 其他标识 ------------
        local captainNode = nodes.captainNode
        if nil == captainNode then
            captainNode = display.newNSprite(_res('ui/raid/room/raid_room_label_owner.png'), 0, 0)
            display.commonUIParams(captainNode, {po = cc.p(
                waitingNodeSize.width + captainNode:getContentSize().width * 0.5,
                waitingNodeSize.height - 5 - captainNode:getContentSize().height * 0.5
            )})
            playerHeadNodeBg:addChild(captainNode)

            self:getViewData().teamMemberPreviewNodes[pos].captainNode = captainNode
        end
        captainNode:setVisible(isCaptain)
        ------------ 其他标识 ------------
    end
end
--[[
刷新成员详细层
@params pos int 玩家位置
@params playerModel TeamPlayerModel 玩家模型
@params isCaptain bool 是否是队长
--]]
function TeamQuestReadyScene:RefreshTeamMemberDetailLayer(pos, playerModel, isCaptain)
    local nodes = self:getViewData().teamMemberDetailNodes[pos]
    local parentLayer = self:getViewData().teamMemberDetailLayer
    --[[
    {
        waitingNode         = waitingIcon,
        playerHeadNode      = nil,
        speakingNode        = nil,
        readyMarkNode       = playerReadyMark,
        nameNode            = nil,
        captainNode         = nil,
        defaultWaitingIconSize = defaultWaitingIconSize,
        levelLimitNode      = levelLimitNode,
        challengeTimeLimitNode = challengeTimeLimitNode,
        playerHeadNodeBg    = playerHeadNodeBg,
        cardHeadNodes       = {
            btnNode = btn,
            bgNode = emptyCardHeadBg,
            headNode = nil
        }
    }
    --]]

    if nil == playerModel or 0 == playerModel:getPlayerId() then
        -- 玩家为空 置为等待
        nodes.waitingNode:setVisible(true)

        for i,v in ipairs(nodes.cardHeadNodes) do
            v.btnNode:setVisible(false)
            v.bgNode:setVisible(false)
            if nil ~= v.headNode then
                v.headNode:setVisible(false)
            end
        end

        if nil ~= nodes.playerHeadNodeBg then
            nodes.playerHeadNodeBg:setVisible(false)
        end
    else
        for i,v in ipairs(nodes.cardHeadNodes) do
            v.btnNode:setVisible(true)
            v.bgNode:setVisible(true)
        end

        nodes.waitingNode:setVisible(false)

        local waitingNodeSize = nodes.waitingNode:getContentSize()
        -- 移除老node
        if nil ~= nodes.playerHeadNode then
            nodes.playerHeadNode:removeFromParent()
            self:getViewData().teamMemberDetailNodes[pos].playerHeadNode = nil
        end

        local playerHeadNodeBg = nodes.playerHeadNodeBg
        if nil == playerHeadNodeBg then
            -- 创建底层layer
            playerHeadNodeBg = display.newLayer(0, 0, {size = waitingNodeSize})
            display.commonUIParams(playerHeadNodeBg, {ap = cc.p(0.5, 0.5), po = cc.p(
                nodes.waitingNode:getPositionX(),
                nodes.waitingNode:getPositionY()
            )})
            parentLayer:addChild(playerHeadNodeBg)

            self:getViewData().teamMemberDetailNodes[pos].playerHeadNodeBg = playerHeadNodeBg

            -- 准备层
            local readyBgImg = display.newImageView(_res('ui/raid/room/raid_room_frame_ready.png'), 0, 0,
                {scale9 = true, size = waitingNodeSize, capInsets = cc.rect(4, 4, 99, 99)})
            display.commonUIParams(readyBgImg, {po = utils.getLocalCenter(playerHeadNodeBg)})
            playerHeadNodeBg:addChild(readyBgImg)
            readyBgImg:setVisible(false)
            readyBgImg:setTag(5)
        end

        playerHeadNodeBg:setVisible(true)

        -- 重新创建底图
        if nil ~= playerHeadNodeBg:getChildByTag(3) then
            playerHeadNodeBg:getChildByTag(3):removeFromParent()
        end

        local bgPath = 'ui/raid/room/raid_room_frame_teammate.png'
        if checkint(gameMgr:GetUserInfo().playerId) == playerModel:getPlayerId() then
            bgPath = 'ui/raid/room/raid_room_frame_self.png'
        end

        local bgImg = display.newImageView(_res(bgPath), 0, 0, {scale9 = true, size = waitingNodeSize, capInsets = cc.rect(4, 4, 99, 99)})
        display.commonUIParams(bgImg, {po = utils.getLocalCenter(playerHeadNodeBg)})
        playerHeadNodeBg:addChild(bgImg)
        bgImg:setTag(3)

        ------------ 玩家头像 ------------
        local playerHeadNode = require('common.PlayerHeadNode').new({
            playerId = checkint(playerModel:getPlayerId()),
            avatar = playerModel:getAvatar(),
            avatarFrame = playerModel:getAvatarFrame(),
            showLevel = true,
            playerLevel = playerModel:getLevel(),
            defaultCallback = true
        })
        display.commonUIParams(playerHeadNode, {po = cc.p(
            nodes.defaultWaitingIconSize.width * 0.5,
            waitingNodeSize.height * 0.5
        )})
        playerHeadNodeBg:addChild(playerHeadNode, 5)
        self:getViewData().teamMemberDetailNodes[pos].playerHeadNode = playerHeadNode

        local playerHeadNodeScale = 0.65
        playerHeadNode:setScale(playerHeadNodeScale)
        ------------ 玩家头像 ------------

        local playerHeadNodeSize = cc.size(
            playerHeadNode:getContentSize().width * playerHeadNodeScale,
            playerHeadNode:getContentSize().height * playerHeadNodeScale
        )

        ------------ 等级限制标识 ------------
        local levelLimitNode = nodes.levelLimitNode
        if nil == levelLimitNode then
            levelLimitNode = display.newImageView(_res('ui/raid/room/raid_room_label_warning.png'), 0, 0)
            display.commonUIParams(levelLimitNode, {po = cc.p(
                playerHeadNode:getPositionX(),
                waitingNodeSize.height * 0.75
            )})
            playerHeadNodeBg:addChild(levelLimitNode, 25)

            local levelLimitLabel = display.newLabel(0, 0, fontWithColor('9', {text = __('等级不足')}))
            display.commonUIParams(levelLimitLabel, {po = utils.getLocalCenter(levelLimitNode)})
            levelLimitNode:addChild(levelLimitLabel)

            self:getViewData().teamMemberDetailNodes[pos].levelLimitNode = levelLimitNode
        end
        ------------ 等级限制标识 ------------

        ------------ 次数限制标识 ------------
        local challengeTimeLimitNode = nodes.challengeTimeLimitNode
        if nil == challengeTimeLimitNode then
            challengeTimeLimitNode = display.newImageView(_res('ui/raid/room/raid_room_label_warning.png'), 0, 0)
            display.commonUIParams(challengeTimeLimitNode, {po = cc.p(
                playerHeadNode:getPositionX(),
                waitingNodeSize.height * 0.45
            )})
            playerHeadNodeBg:addChild(challengeTimeLimitNode, 25)

            local challengeTimeLimitLabel = display.newLabel(0, 0, fontWithColor('9', {text = __('次数不足')}))
            display.commonUIParams(challengeTimeLimitLabel, {po = utils.getLocalCenter(challengeTimeLimitNode)})
            challengeTimeLimitNode:addChild(challengeTimeLimitLabel)

            self:getViewData().teamMemberDetailNodes[pos].challengeTimeLimitNode = challengeTimeLimitNode
        end
        ------------ 次数限制标识 ------------

        ------------ 玩家名字 ------------
        local nameNode = nodes.nameNode
        if nil == nameNode then
            nameNode = display.newImageView(_res('ui/raid/room/raid_room_label_name.png'), 0, 0,
                {scale9 = true, size = cc.size(waitingNodeSize.width, 25)})
            display.commonUIParams(nameNode, {po = cc.p(
                waitingNodeSize.width * 0.5,
                -nameNode:getContentSize().height * 0.5
            )})
            playerHeadNodeBg:addChild(nameNode, 10)

            self:getViewData().teamMemberDetailNodes[pos].nameNode = nameNode

            local nameLabel = display.newLabel(0, 0, fontWithColor('9', {text = tostring(playerModel:getName())}))
            display.commonUIParams(nameLabel, {ap = cc.p(0, 0.5), po = cc.p(
                5,
                utils.getLocalCenter(nameNode).y
            )})
            nameNode:addChild(nameLabel)
            nameLabel:setTag(3)
        else
            nameNode:setVisible(true)
            nameNode:getChildByTag(3):setString(tostring(playerModel:getName()))
        end
        ------------ 玩家名字 ------------

        ------------ 其他标识 ------------
        local captainNode = nodes.captainNode
        if nil == captainNode then
            captainNode = display.newNSprite(_res('ui/raid/room/raid_room_label_owner.png'), 0, 0)
            display.commonUIParams(captainNode, {po = cc.p(
                waitingNodeSize.width + captainNode:getContentSize().width * 0.5,
                waitingNodeSize.height - 5 - captainNode:getContentSize().height * 0.5
            )})
            playerHeadNodeBg:addChild(captainNode)

            self:getViewData().teamMemberDetailNodes[pos].captainNode = captainNode
        end
        captainNode:setVisible(isCaptain)
        ------------ 其他标识 ------------
    end
end
--[[
刷新等级限制
@params pos int 玩家位置
@params show bool 是否显示等级不足
--]]
function TeamQuestReadyScene:ShowPlayerLevelLimit(pos, show)
    local previewNodes = self:getViewData().teamMemberPreviewNodes[pos]
    if nil ~= previewNodes and nil ~= previewNodes.levelLimitNode then
        previewNodes.levelLimitNode:setVisible(show)
    end

    local detailNodes = self:getViewData().teamMemberDetailNodes[pos]
    if nil ~= detailNodes and nil ~= detailNodes.levelLimitNode then
        detailNodes.levelLimitNode:setVisible(show)
    end
end
--[[
刷新次数限制
@params pos int 玩家位置
@params show bool 是否显示次数不足
--]]
function TeamQuestReadyScene:ShowPlayerChallengeTimeLimit(pos, show)
    local previewNodes = self:getViewData().teamMemberPreviewNodes[pos]
    if nil ~= previewNodes and nil ~= previewNodes.challengeTimeLimitNode then
        -- previewNodes.challengeTimeLimitNode:setVisible(show)
        previewNodes.challengeTimeLimitNode:setVisible(false)
    end

    local detailNodes = self:getViewData().teamMemberDetailNodes[pos]
    if nil ~= detailNodes and nil ~= detailNodes.challengeTimeLimitNode then
        -- detailNodes.challengeTimeLimitNode:setVisible(show)
        detailNodes.challengeTimeLimitNode:setVisible(false)
    end
end
--[[
刷新准备状态
@params pos int 玩家位置
@params playerModel TeamPlayerModel 玩家模型
--]]
function TeamQuestReadyScene:RefreshTeamMemberReadyState(pos, playerModel)
    local previewNodes = self:getViewData().teamMemberPreviewNodes[pos]
    local detailNodes = self:getViewData().teamMemberDetailNodes[pos]

    if nil == playerModel or 0 == playerModel:getPlayerId() then
        ------------ 预览层 ------------
        previewNodes.readyMarkNode:setVisible(false)
        ------------ 预览层 ------------

        ------------ 详情层 ------------
        detailNodes.readyMarkNode:setVisible(false)
        ------------ 详情层 ------------
    else
        local state = playerModel:getStatus()
        local isSelf = checkint(gameMgr:GetUserInfo().playerId) == playerModel:getPlayerId()
        local path = nil

        if TeamPlayerModel.STATUS_READY == state then
            previewNodes.readyMarkNode:setVisible(true)
            detailNodes.readyMarkNode:setVisible(true)

            if nil ~= previewNodes.playerHeadNodeBg then
                if nil ~= previewNodes.playerHeadNodeBg:getChildByTag(3) then
                    previewNodes.playerHeadNodeBg:getChildByTag(3):setVisible(false)
                end
                if nil ~= previewNodes.playerHeadNodeBg:getChildByTag(5) then
                    previewNodes.playerHeadNodeBg:getChildByTag(5):setVisible(true)
                end
            end

            if nil ~= detailNodes.playerHeadNodeBg then
                if nil ~= detailNodes.playerHeadNodeBg:getChildByTag(3) then
                    detailNodes.playerHeadNodeBg:getChildByTag(3):setVisible(false)
                end
                if nil ~= detailNodes.playerHeadNodeBg:getChildByTag(5) then
                    detailNodes.playerHeadNodeBg:getChildByTag(5):setVisible(true)
                end
            end
        else
            previewNodes.readyMarkNode:setVisible(false)
            detailNodes.readyMarkNode:setVisible(false)

            if nil ~= previewNodes.playerHeadNodeBg then
                if nil ~= previewNodes.playerHeadNodeBg:getChildByTag(3) then
                    previewNodes.playerHeadNodeBg:getChildByTag(3):setVisible(true)
                end
                if nil ~= previewNodes.playerHeadNodeBg:getChildByTag(5) then
                    previewNodes.playerHeadNodeBg:getChildByTag(5):setVisible(false)
                end
            end

            if nil ~= detailNodes.playerHeadNodeBg then
                if nil ~= detailNodes.playerHeadNodeBg:getChildByTag(3) then
                    detailNodes.playerHeadNodeBg:getChildByTag(3):setVisible(true)
                end
                if nil ~= detailNodes.playerHeadNodeBg:getChildByTag(5) then
                    detailNodes.playerHeadNodeBg:getChildByTag(5):setVisible(false)
                end
            end
        end
    end
end
--[[
根据本玩家状态设置按钮样式
@params isCaptain bool 是否是队长
@params state RaidPlayerState 玩家状态
--]]
function TeamQuestReadyScene:SetBattleButtonState(isCaptain, state)
    if isCaptain then
        if RaidPlayerState.CANNOT_START == state then

            self:getViewData().battleBtn:SetText(__('开始'))
            self:getViewData().battleBtn:SetSelfEnable(false)

        elseif RaidPlayerState.CAN_START == state then

            self:getViewData().battleBtn:SetText(__('开始'))
            self:getViewData().battleBtn:SetSelfEnable(true)

        elseif RaidPlayerState.STARTED == state then



        end
    else
        if RaidPlayerState.CANNOT_START == state then

            self:getViewData().battleBtn:SetText(__('准备'))
            self:getViewData().battleBtn:SetSelfEnable(false)

        elseif RaidPlayerState.CAN_START == state then

            self:getViewData().battleBtn:SetText(__('准备'))
            self:getViewData().battleBtn:SetSelfEnable(true)
            self:getViewData().battleBtn:ShowBattleSpine(false)

        elseif RaidPlayerState.STARTED == state then

            self:getViewData().battleBtn:SetText(__('取消'))
            self:getViewData().battleBtn:SetSelfEnable(true)
            self:getViewData().battleBtn:ShowBattleSpine(true)

        end
    end
end
--[[
刷新队员详情界面卡牌头像
@params playerPos int 玩家位置
@params cardIndex int 上卡序号
@params cardModel TeamCardModel 卡牌数据
--]]
function TeamQuestReadyScene:RefreshTeamMemberCard(playerPos, cardIndex, cardModel)
    -- print('here check fuck card info change <<<<<<<<<<<<<<<<<', playerPos, cardIndex)
    local nodes = self:getViewData().teamMemberDetailNodes[playerPos]
    --[[
    {
        waitingNode         = waitingIcon,
        playerHeadNode      = nil,
        speakingNode        = nil,
        readyMarkNode       = playerReadyMark,
        nameNode            = nil,
        captainNode         = nil,
        defaultWaitingIconSize = defaultWaitingIconSize,
        levelLimitNode      = levelLimitNode,
        challengeTimeLimitNode = challengeTimeLimitNode,
        playerHeadNodeBg    = playerHeadNodeBg,
        cardHeadNodes       = {
            btnNode = btn,
            bgNode = emptyCardHeadBg,
            headNode = nil
        }
    }
    --]]

    if nil ~= nodes and nil ~= nodes.cardHeadNodes then
        local cardNodes = nodes.cardHeadNodes[cardIndex]
        -- dump(cardNodes)

        if nil ~= cardNodes then
            local cardId = checkint(cardModel:getCardId())

            if TeamCardModel.REMOVE_CARD_ID == cardId then

                cardNodes.bgNode:setVisible(true)
                cardNodes.btnNode:setVisible(false)
                if nil ~= cardNodes.headNode then
                    cardNodes.headNode:setVisible(false)
                end

            else
                cardNodes.bgNode:setVisible(false)
                cardNodes.btnNode:setVisible(true)
                if nil == cardNodes.headNode then
                    local cardHeadNode = require('common.CardHeadNode').new({
                        cardData = {
                            cardId = cardModel:getCardId(),
                            level = cardModel:getLevel(),
                            breakLevel = cardModel:getBreakLevel(),
                            skinId = cardModel:getCardSkinId()
                        },
                        showBaseState = true,
                        showActionState = false,
                        showVigourState = false
                    })
                    cardHeadNode:setScale((cardHeadNodeSize.width) / cardHeadNode:getContentSize().width)
                    display.commonUIParams(cardHeadNode, {po = cc.p(
                        cardNodes.bgNode:getPositionX(),
                        cardNodes.bgNode:getPositionY()
                    )})
                    cardNodes.bgNode:getParent():addChild(cardHeadNode, cardNodes.bgNode:getLocalZOrder() + 1)

                    self:getViewData().teamMemberDetailNodes[playerPos].cardHeadNodes[cardIndex].headNode = cardHeadNode
                else
                    cardNodes.headNode:RefreshUI({
                        cardData = {
                            cardId = cardModel:getCardId(),
                            level = cardModel:getLevel(),
                            breakLevel = cardModel:getBreakLevel(),
                            skinId = cardModel:getCardSkinId()
                        },
                        showBaseState = true,
                        showActionState = false,
                        showVigourState = false
                    })
                    cardNodes.headNode:setVisible(true)
                end
            end
        end
    end
end
--[[
刷新好友标识
@params isFriend bool 是否是好友
--]]
function TeamQuestReadyScene:RefreshFriendIcon(isFriend)
    local friendIconPath = ''
    if isFriend then
        friendIconPath = 'ui/raid/room/raid_room_ico_friendon.png'
    else
        friendIconPath = 'ui/raid/room/raid_room_ico_friendoff.png'
    end
    self:getViewData().friendIcon:setTexture(friendIconPath)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
--[[
更换卡牌按钮回调
--]]
function TeamQuestReadyScene:ChangeCardClickHandler(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    AppFacade.GetInstance():DispatchObservers('RAID_SHOW_CHOOSE_CARD_VIEW', {index = tag})
end
--[[
准备开始战斗按钮回调
--]]
function TeamQuestReadyScene:BattleReadyClickHandler(sender)
   PlayAudioByClickNormal()
   AppFacade.GetInstance():DispatchObservers('RAID_BATTLE_READY')
end
--[[
更改密码按钮回调
--]]
function TeamQuestReadyScene:ChangePasswordClickHandler(sender)
    PlayAudioByClickNormal()
    AppFacade.GetInstance():DispatchObservers('RAID_SHOW_CHANGE_PASSWORD')
end
--[[
队伍详情展开按钮
--]]
function TeamQuestReadyScene:TeamMemberDetailSwitchClickHandler(sender)
    PlayAudioByClickNormal()
    self:getViewData().teamMemberPreviewLayer:setVisible(not self:getViewData().teamMemberPreviewLayer:isVisible())
    self:getViewData().teamMemberDetailLayer:setVisible(not self:getViewData().teamMemberDetailLayer:isVisible())
end
--[[
购买剩余次数按钮回调
--]]
function TeamQuestReadyScene:BuyChallengeTimesClickHandler()
    PlayAudioByClickNormal()
    AppFacade.GetInstance():DispatchObservers('RAID_SHOW_BUY_CHALLENGE_TIMES')
end
--[[
查看关卡按钮回调
--]]
function TeamQuestReadyScene:StageDetailClickHandler(sender)
    PlayAudioByClickNormal()
    AppFacade.GetInstance():DispatchObservers('RAID_SHOW_STAGE_DETAIL')
end
--[[
好友标识按钮回调
--]]
function TeamQuestReadyScene:FriendIconClickHandler(sender)
    PlayAudioByClickNormal()
    AppFacade.GetInstance():DispatchObservers('RAID_SHOW_FRIEND_REMIND_BOARD')
end
--[[
spine小人按钮回调
--]]
function TeamQuestReadyScene:SpineAvatarBtnClickHandler(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    AppFacade.GetInstance():DispatchObservers('RAID_SHOW_PLAYER_CARD_DETAIL', {cardPos = tag})
end
--[[
模块说明按钮回调
--]]
function TeamQuestReadyScene:RaidHintBtnClickHandler(sender)
    PlayAudioByClickNormal()
    uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.THREETWORAID)]})
end
---------------------------------------------------
-- click handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
function TeamQuestReadyScene:getViewData()
    return self.viewData_
end
--[[
根据关卡id获取修正后的关卡名称
@params stageId int 关卡id
@return nameStr string 修正后的关卡名称
--]]
function TeamQuestReadyScene:getStageFixedName(stageId)
    local nameStr = ''
    local stageConfig = CommonUtils.GetQuestConf(stageId)
    if stageConfig then
        nameStr = string.format('%s(%s)', tostring(stageConfig.name), difficultyConfig[tostring(stageConfig.difficulty)])
    end
    return nameStr
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- cocos2dx handler begin --
---------------------------------------------------
function TeamQuestReadyScene:onEnter()
    GameScene.onEnter(self)
    -- 延迟发送信号 连接实时语音
    self:runAction(cc.Sequence:create(
        cc.DelayTime:create(0.3),
        cc.CallFunc:create(function ()
            -- 初始化聊天板

            AppFacade.GetInstance():DispatchObservers('RAID_CONNECT_REAL_TIME_VOICE_CHAT')
        end)
    ))
end
---------------------------------------------------
-- cocos2dx handler end --
---------------------------------------------------


return TeamQuestReadyScene
