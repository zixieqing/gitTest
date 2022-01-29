--[[
离线pvp主场景
--]]
local GameScene = require( "Frame.GameScene" )
---@class UnionWarsBattleMemberView:GameScene
local UnionWarsBattleMemberView = class("UnionWarsBattleMemberView", function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.unionWars.UnionWarsBattleMemberView'
    node:enableNodeEvents()
    return node
end)

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

local  RES_DICT = {
    PVP_MAIN_BG_ENEMYINFO            = _res("ui/union/wars/pvp/pvp_main_bg_enemyinfo.png"),
    GVG_HP_HEART_1            = _res("ui/union/wars/pvp/gvg_hp_heart_1.png"),
    GVG_DEBUFF_ICON            = _res("ui/union/wars/pvp/gvg_debuff_icon.png"),
    GVG_HP_HEART_2            = _res("ui/union/wars/pvp/gvg_hp_heart_2.png"),
    COMMON_BTN_BACK               = _res('ui/common/common_btn_back.png'),
    COMMON_BTN_TIPS               = _res('ui/common/common_btn_tips.png'),
    DEBUFF_SPINE     =  _spn('ui/union/wars/map/gvg_debuff'),  -- idle1, idle2, idle3

}
local DEBUFF_SPINE_PLAY_DEFINE = {
    'idle1',
    'idle2',
    'idle3',
}
--[[
constructor
--]]
function UnionWarsBattleMemberView:ctor(...)
    GameScene.ctor(self, 'Game.views.pvc.UnionWarsBattleMemberView')

    self:InitUI()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function UnionWarsBattleMemberView:InitUI()
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

    local swallowLayer = display.newButton(display.cx , display.cy , {size = display.size , enable = true })
    self:addChild(swallowLayer)

    local bg = display.newImageView(_res('ui/union/wars/map/gvg_maps_bg_2_1.jpg'), selfCenter.x, selfCenter.y, {isFull = true , enable = true})
    self:addChild(bg)

    local backBtn = display.newButton(59, 695, { enable = true , ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_BACK, d = RES_DICT.COMMON_BTN_BACK, s = RES_DICT.COMMON_BTN_BACK, scale9 = true, size = cc.size(90, 70), tag = 765 })
    display.commonLabelParams(backBtn, {text = "", fontSize = 14, color = '#414146'})
    backBtn:setPosition(display.SAFE_L + 59, display.height + -55)
    self:addChild(backBtn,20)
    -- 标题版
    local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height + 100,{cb = function()
        PlayAudioByClickNormal()
        uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.UNION_WARS)]})
    end , n = _res('ui/common/common_title_new.png'), enable = true, ap = cc.p(0, 0)})
    display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('挑战防御御侍'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
    self:addChild(tabNameLabel, PVCSceneZorder.TOP)

    tabNameLabel:addChild(display.newImageView(RES_DICT.COMMON_BTN_TIPS, tabNameLabel:getContentSize().width - 50, tabNameLabel:getContentSize().height/2 - 10))

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



    local changeFriendFightTeamBar = display.newButton(0, 0, {n = _res('ui/pvc/pvp_label_change_blue.png'), enable = false})
    display.commonLabelParams(changeFriendFightTeamBar, fontWithColor('18', {fontSize = 18, text = __('编辑进攻队伍'), paddingW = 40, offset = cc.p(10,0)}))
    display.commonUIParams(changeFriendFightTeamBar, {po = cc.p(
            avatarBottomLeft:getPositionX() - 220,
            uiLocationInfo.avatarBottomSplitY + changeFriendFightTeamBar:getContentSize().height * 0.5
    )})
    self:addChild(changeFriendFightTeamBar, PVCSceneZorder.TOP)

    -- 左右战斗力值
    local friendTeamBattlePointBg = sp.SkeletonAnimation:create('effects/fire/skeleton.json', 'effects/fire/skeleton.atlas', 1)
    friendTeamBattlePointBg:update(0)
    friendTeamBattlePointBg:setAnimation(0, 'huo', true)
    friendTeamBattlePointBg:setPosition(cc.p(
            size.width * 0.5 - 155,
            uiLocationInfo.avatarBottomSplitY
    ))
    self:addChild(friendTeamBattlePointBg, PVCSceneZorder.TOP)

    local friendTeamBattlePointLabel = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', '')
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

    local rivalTeamBattlePointLabel = cc.Label:createWithBMFont('font/team_ico_fight_figure.fnt', '')
    rivalTeamBattlePointLabel:setAnchorPoint(cc.p(0.5, 0.5))
    rivalTeamBattlePointLabel:setHorizontalAlignment(display.TAC)
    rivalTeamBattlePointLabel:setPosition(cc.p(
            rivalTeamBattlePointBg:getPositionX(),
            rivalTeamBattlePointBg:getPositionY() + 10
    ))
    self:addChild(rivalTeamBattlePointLabel, PVCSceneZorder.TOP)
    rivalTeamBattlePointLabel:setScale(0.7)


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
                                                                   pattern = 6,
                                                                   battleText = __('挑战')
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
            utils.getLocalCenter(leftChallengeBg).x - 10,
            utils.getLocalCenter(leftChallengeBg).y
    )})
    leftChallengeBg:addChild(leftChallengeLabel)

    -- 刷新时间
    local refreshLabel = display.newLabel(0, 0, fontWithColor('18', {fontSize = 20, text = ''}))
    display.commonUIParams(refreshLabel, {po = cc.p(
            leftChallengeBg:getPositionX(),
            leftChallengeBg:getPositionY() + leftChallengeBg:getContentSize().height * 0.5 + 7
    )})
    self:addChild(refreshLabel, PVCSceneZorder.TOP)

    -- 弹出标题班
    local action = cc.Sequence:create(
            cc.EaseBounceOut:create(cc.MoveTo:create(1,cc.p(display.SAFE_L + 130, display.height - 80)))
    )
    tabNameLabel:runAction(action)

    -- 敌方信息背景
    local rivalInfoBg = display.newLayer(0, 0 , {ap = display.CENTER , size = cc.size(370+display.SAFE_L,375) })
    display.commonUIParams(rivalInfoBg, {po = cc.p(
            size.width - rivalInfoBg:getContentSize().width * 0.5,
            selfCenter.y - 35
    )})
    self:addChild(rivalInfoBg, PVCSceneZorder.BASE +1)
    -- 对手信息板
    local rivalInfoLayerSize = rivalInfoBg:getContentSize()
    local rivalBuffTipBtn    = display.newButton( 190 , rivalInfoLayerSize.height - 44, { size = cc.size(50,50)} )
    rivalInfoBg:addChild(rivalBuffTipBtn)


    local debuffSpinePath = RES_DICT.DEBUFF_SPINE.path
    if not SpineCache(SpineCacheName.UNION):hasSpineCacheData(debuffSpinePath) then
        SpineCache(SpineCacheName.UNION):addCacheData(debuffSpinePath, debuffSpinePath, 1)
    end
    local playerDebuffSpine = SpineCache(SpineCacheName.UNION):createWithName(debuffSpinePath)
    playerDebuffSpine:setPosition(cc.p(25,20))
    rivalBuffTipBtn:addChild(playerDebuffSpine)

    local rivalInfoBgImage = display.newImageView(RES_DICT.PVP_MAIN_BG_ENEMYINFO, 0, 0, {scale9 = true, size = cc.size(370+display.SAFE_L,375)})
    display.commonUIParams(rivalInfoBgImage, {po = cc.p(
            size.width - rivalInfoBgImage:getContentSize().width * 0.5+20,
            selfCenter.y - 35
    )})
    self:addChild(rivalInfoBgImage, PVCSceneZorder.BASE)



    local rivalInfoLayer = display.newLayer(0, 0, {ap = cc.p(0.5, 0.5), size = rivalInfoLayerSize})
    display.commonUIParams(rivalInfoLayer, {po = cc.p(
            rivalInfoBg:getPositionX() - display.SAFE_L,
            rivalInfoBg:getPositionY()
    )})
    rivalInfoBg:getParent():addChild(rivalInfoLayer, PVCSceneZorder.BASE)

    local rivalInfoSplitLine = display.newNSprite(_res('ui/pvc/pvp_main_bg_line3.png'), 0, 0)
    display.commonUIParams(rivalInfoSplitLine, {po = cc.p(
            rivalInfoLayerSize.width - rivalInfoSplitLine:getContentSize().width * 0.5 - 10,
            rivalInfoLayerSize.height - 65
    )})
    rivalInfoLayer:addChild(rivalInfoSplitLine)

    -- 对手头像
    local rivalHeadScale = 0.65
    local rivalHeadNode = require('common.PlayerHeadNode').new({avatar = '', avatarFrame = '', showLevel = true, playerLevel = 10})
    rivalHeadNode:setScale(rivalHeadScale)
    display.commonUIParams(rivalHeadNode, {po = cc.p(
            rivalInfoLayerSize.width - rivalHeadNode:getContentSize().width * 0.5 * rivalHeadScale - 10,
            rivalInfoSplitLine:getPositionY() - 10 - rivalHeadNode:getContentSize().height * 0.5 * rivalHeadScale
    )})
    rivalInfoLayer:addChild(rivalHeadNode)

    local rivalNameLabel = display.newLabel(0, 0, fontWithColor('3', {text = '测试玩家名'}))
    display.commonUIParams(rivalNameLabel, {ap = cc.p(1, 0.5), po = cc.p(
            rivalInfoLayerSize.width - 10,
            rivalInfoSplitLine:getPositionY() + 20
    )})
    rivalInfoLayer:addChild(rivalNameLabel)

    local HPLayoutSize = cc.size(56,30)
    local HPLayout = display.newLayer(rivalInfoLayerSize.width - 10 , rivalInfoLayerSize.height/2 , {ap = display.RIGHT_CENTER , size = HPLayoutSize})
    rivalInfoLayer:addChild(HPLayout)
    local hpTable = {}
    for i = 1, 2 do
        local hpImage = display.newImageView(RES_DICT.GVG_HP_HEART_1 ,28 * (i - 0.5 ) , 15  )
        HPLayout:addChild(hpImage)
        hpTable[#hpTable+1] = hpImage
    end

    -- 获胜奖励信息

    local winRewardBg = display.newImageView(_res('ui/pvc/pvp_main_bg_getscore.png'), 0, 0)
    local winRewardBgSize = winRewardBg:getContentSize()
    display.commonUIParams(winRewardBg, {po = cc.p(
            rivalInfoLayerSize.width - winRewardBgSize.width * 0.5,
            100
    )})
    rivalInfoLayer:addChild(winRewardBg)


    local rewardTitle = display.newLabel(0, 0, {text = __('获胜可得'), fontSize = 20, color = '#ffb421'})
    display.commonUIParams(rewardTitle, {ap = cc.p(1, 0.5), po = cc.p(
            winRewardBgSize.width - 10,
            winRewardBgSize.height - 20
    )})
    winRewardBg:addChild(rewardTitle)

    local currencyRichLabel = display.newRichLabel(winRewardBgSize.width - 135, winRewardBgSize.height - 60 , {
        ap = display.LEFT_CENTER,
        c = {
            fontWithColor('14' ,{text = ""})
        }
    })
    winRewardBg:addChild(currencyRichLabel)

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

    -- 换阵容按钮
    local changeFriendFightTeamBtnBottomLayer = display.newLayer(0, 0,
                                                                  {color = cc.c4b(0,0,0,0),  size = cc.size(display.SAFE_RECT.width - 175, uiLocationInfo.bottomTeamBgHeight)})
    display.commonUIParams(changeFriendFightTeamBtnBottomLayer, {ap = cc.p(1, 0.5), po = cc.p(
            selfCenter.x - 175,
            bottomTeamBg:getPositionY() + uiLocationInfo.bottomTeamBgCenterFixedY
    ), animate = false})
    self:addChild(changeFriendFightTeamBtnBottomLayer, PVCSceneZorder.BASE + 2)


    local changeFriendFightTeamBtnLayer = display.newLayer(0, 0, {color = cc.c4b(0,0,0,0), enable = true , size = cc.size(220, 300)})
    display.commonUIParams(changeFriendFightTeamBtnLayer, {ap = cc.p(0.5, 0), po = cc.p(
            avatarBottomLeft:getPositionX() + uiLocationInfo.avatarFixedPL.x,
            avatarBottomLeft:getPositionY() + uiLocationInfo.avatarFixedPL.y - 50
    ), animate = false})
    self:addChild(changeFriendFightTeamBtnLayer, PVCSceneZorder.BASE + 2)


    self.viewData = {
        changeFriendFightTeamBtnBottomLayer = changeFriendFightTeamBtnBottomLayer,
        bg = bg,
        changeFriendFightTeamBtnLayer       = changeFriendFightTeamBtnLayer,
        battleBtn                           = battleBtn,
        rivalHeadNode                       = rivalHeadNode,
        rivalNameLabel                      = rivalNameLabel,
        currencyRichLabel                   = currencyRichLabel,
        hpTable                             = hpTable,
        bottomTeamBg                        = bottomTeamBg,
        avatarBottomRight                   = avatarBottomRight,
        refreshLabel                        = refreshLabel,
        rivalInfoBg                        = rivalInfoBg,
        rivalBuffTipBtn                         = rivalBuffTipBtn,
        uiLocationInfo                      = uiLocationInfo,
        leftChallengeLabel                  = leftChallengeLabel,
        rivalRivalTeamNodes                 = {},
        playerDebuffSpine                   = playerDebuffSpine,
        friendFightTeamNodes                = {},
        friendTeamBattlePointLabel          = friendTeamBattlePointLabel,
        avatarBottomLeft                    = avatarBottomLeft,
        rivalTeamBattlePointLabel           = rivalTeamBattlePointLabel,
        changeFriendFightTeamBtn            = changeFriendFightTeamBtn,
        backBtn                             = backBtn,
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
        end
    }
end


--[[
刷新敌方防守队伍
@params rivalTeamData table 敌方队伍信息
--]]
function UnionWarsBattleMemberView:RefreshRivalDefenseTeam(rivalTeamData)
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
function UnionWarsBattleMemberView:RefreshRivalMajorAvatar(cardData)
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
刷新一号位avatar
@params cardData table 卡牌信息
--]]
function UnionWarsBattleMemberView:RefreshFriendMajorAvatar(cardData)
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
刷新友方进攻队伍
@params friendTeamData table 友方队伍信息
--]]
function UnionWarsBattleMemberView:RefreshFriendFightTeam(friendTeamData)
    -- 刷新友方进攻队伍
    local cid = nil
    local cardData = nil
    local itor = 0
    local cardHeadScale = 0.45
    local battlePoint = 0

    for i,v in ipairs(friendTeamData) do
        local cardHeadNodes = self.viewData.friendFightTeamNodes[i]
        cid = v.id

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
---==============================--
---@Description: 刷新地方的的UI
--==============================--

function UnionWarsBattleMemberView:RefreshEmenyUI(warsSiteModel)
    -- 更新血量信息
    local count = 0
    local playerHP = checkint(warsSiteModel:getPlayerHP())
    for i = 1 ,   #self.viewData.hpTable  do
        count =count +1
        if  count <= playerHP then
            self.viewData.hpTable[i]:setTexture(RES_DICT.GVG_HP_HEART_1)
        else
            self.viewData.hpTable[i]:setTexture(RES_DICT.GVG_HP_HEART_2)
        end
    end
    local playerName = warsSiteModel:getPlayerName()
    local playerLevel = warsSiteModel:getPlayerLevel()
    local playerAvatarFrame = warsSiteModel:getPlayerAvatarFrame()
    local playerAvatar = warsSiteModel:getPlayerAvatar()
    local debuffId = warsSiteModel:getDefendDebuff()
    local debuffSpinePlayName = DEBUFF_SPINE_PLAY_DEFINE[debuffId]
    if debuffId and  checkint(debuffId) > 0   then
        self.viewData.rivalBuffTipBtn:setVisible(true)
        self.viewData.playerDebuffSpine:setAnimation(0, tostring(debuffSpinePlayName), true)
    else
        self.viewData.rivalBuffTipBtn:setVisible(false)
    end
    -- 玩家名
    self.viewData.rivalNameLabel:setString(playerName)
    -- 玩家头像 玩家等级
    self.viewData.rivalHeadNode:RefreshUI({
        avatar = playerAvatar, playerLevel = playerLevel, avatarFrame = playerAvatarFrame
    })
    local unionMgr = app.unionMgr
    local unionWarsModel = unionMgr:getUnionWarsModel()
    local totalAttachNum = unionWarsModel:getTotalAttachNum()
    local leftAttachNum = unionWarsModel:getLeftAttachNum()
    display.commonLabelParams(self.viewData.refreshLabel, {text = __('当前剩余次数')})
    display.commonLabelParams(self.viewData.leftChallengeLabel, {text = string.fmt("_num1_/_num2_" ,{_num1_ = leftAttachNum , _num2_ = totalAttachNum } )})
end

function UnionWarsBattleMemberView:UpdateBgImage()
    local viewData = self.viewData
    local unionWarsModel = app.unionMgr:getUnionWarsModel()
    local mapIndex  =  unionWarsModel:getMapPageIndex()
    local bgTexture = _res('ui/union/wars/map/gvg_maps_bg_2_1.jpg')
    if checkint(mapIndex)  == 2 then
        bgTexture=_res('ui/union/wars/map/gvg_maps_bg_2_2.jpg')
    end
    viewData.bg:setTexture(bgTexture)
end
function UnionWarsBattleMemberView:UpdateBuffLayout(buildingData)
    local rivalInfoBg = self.viewData.rivalInfoBg
    local commonBgLayout = rivalInfoBg:getChildByName("commonBgLayout")
    local isVisible = false
    if (not commonBgLayout)  then
        local rivalInfoBgSize = rivalInfoBg:getContentSize()
        local defendDebuffId  = buildingData:getDebuffId()
        local skillConf = CommonUtils.GetSkillConf(defendDebuffId) or {}
        local descr = skillConf.descr or ""
        local commonBgSize = cc.size(334,131)
        commonBgLayout = display.newLayer(rivalInfoBgSize.width/2+5,rivalInfoBgSize.height,{size = commonBgSize, ap = display.CENTER_BOTTOM })
        local commonBgImage = display.newImageView(_res('ui/common/commcon_bg_text'),commonBgSize.width/2 , commonBgSize.height/2,{scale9 = true ,size = commonBgSize })
        commonBgLayout:addChild(commonBgImage)
        local hornImage = display.newImageView(_res('ui/common/chat_ico_npc_horn.png') , commonBgSize.width/2 , 2, { ap = display.CENTER_TOP})
        commonBgLayout:addChild(hornImage)
        local buffText = display.newLabel(commonBgSize.width/2 , commonBgSize.height /2 , fontWithColor(8,{ hAlign = display.TAC ,  ap = display.CENTER , text = descr , w= 300 }))
        commonBgLayout:addChild(buffText)
        commonBgLayout:setName("commonBgLayout")
        rivalInfoBg:addChild(commonBgLayout)
    else
        isVisible = commonBgLayout:isVisible()
    end
    commonBgLayout:setVisible(not isVisible)
end
---==============================--
---@Description: 获胜可得的货币
---@param currency number 金币的数量
--==============================--
function UnionWarsBattleMemberView:UpdateWinCurrency(currency)
    display.reloadRichLabel(self.viewData.currencyRichLabel , {
        c =  {
            fontWithColor(14, {text = currency }),
            fontWithColor(14, {text =__('货币') })


        }
    })
end
return UnionWarsBattleMemberView
