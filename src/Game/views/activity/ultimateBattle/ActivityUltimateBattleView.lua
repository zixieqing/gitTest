--[[
 * author : liuzhipeng
 * descpt : 巅峰对决 view
--]]
local VIEW_SIZE = cc.size(1035, 637)
local ActivityUltimateBattleView = class('ActivityUltimateBattleView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'home.view.activity.ultimateBattle.ActivityUltimateBattleView'
    node:enableNodeEvents()
    return node
end)

local RES_DICT = {
    TIPS_BTN                     = _res('ui/common/common_btn_tips.png'),
    TITLE_SPLIT_LINE             = _res('ui/home/activity/ultimateBattle/duel_img_line.png'),
    BG                           = _res('ui/home/activity/ultimateBattle/activity_bg_duel.jpg'),
    TIME_BG                      = _res('ui/home/activity/activity_time_bg.png'), 
    RANK_BTN                     = _res('ui/home/nmain/main_btn_rank.png'),
    TEAM_TITLE_BG                = _res('ui/union/party/party/common_bg_title_4.png'),
    SWITCH_BTN_BG                = _res('ui/home/activity/ultimateBattle/duel_bg_arrow_shadow.png'),
    SWITCH_BTN_BG_D              = _res('ui/common/common_bg_direct_disabled_s.png'),
    SWITCH_BTN_BG_N              = _res('ui/common/common_bg_direct_s.png'),
    SWITCH_BTN_N                 = _res('ui/common/common_btn_direct_s.png'),
    SWITCH_BTN_D                 = _res('ui/common/common_btn_direct_disabled_s.png'),
    COMMON_BTN_ORANGE_2          = _res('ui/common/common_btn_big_orange_2.png'),
    LEFT_TIMES_BG                = _res('ui/home/activity/ultimateBattle/duel_bg_num.png'),
    COMMON_ADD_BTN               = _res('ui/common/common_btn_add.png'),
    PRIZE_BG                     = _res('ui/home/activity/ultimateBattle/duel_bg_prize_style_1.png'),
    PRIZE_GOODS_BG               = _res('ui/home/capsuleNew/tenTimes/summon_prize_goods_bg.png'),
    PRIZE_GOODS_BG_LIGHT         = _res('ui/home/capsuleNew/tenTimes/summon_prize_goods_bg_light.png'),
    PRIZE_DRAW_BTN               = _res('ui/home/activity/ultimateBattle/duel_btn_click_get.png'),
    PRIZE_DRAWN_ICON             = _res('ui/common/common_btn_check_selected.png'),
    PRIZE_MASK                   = _res('ui/home/activity/ultimateBattle/duel_bg_prize_mask.png'),
    PRIZE_LOCK_ICON              = _res('ui/common/common_ico_lock.png'),
    PRIZE_NAME_BG                = _res('ui/home/activity/ultimateBattle/duel_bg_text_prize.png'),
    TEAM_BASE                    = _res('ui/common/tower_bg_team_base.png'),
    NAME_LV_BG                   = _res('ui/home/activity/ultimateBattle/duel_bg_name_lv.png'),
    TEAM_POINT_ICO_D             = _res('ui/home/activity/ultimateBattle/duel_ico_point_default.png'),
    TEAM_POINT_ICO_S             = _res('ui/home/activity/ultimateBattle/duel_ico_point_selected.png'),
}
function ActivityUltimateBattleView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function ActivityUltimateBattleView:InitUI()
    local CreateView = function (size)
        local view = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
        -- 背景
        local bg = display.newImageView(RES_DICT.BG, size.width / 2, size.height / 2)
        view:addChild(bg, 1)

        -- 标题
        local dailyTitleLabel = display.newLabel(10, size.height - 35, {text = __('巅峰对决'), fontSize = 50, color = '#7e472f', ap = display.LEFT_CENTER, ttf = true, font = TTF_GAME_FONT})
        view:addChild(dailyTitleLabel, 5)
        local dailyDescrLabel = display.newLabel(10, size.height - 70, fontWithColor(4, {text = __('挑战战队，获取丰厚奖励！'), ap = display.LEFT_TOP, w = 430}))
        view:addChild(dailyDescrLabel, 5)
        local tipsBtn = display.newButton(display.getLabelContentSize(dailyTitleLabel).width + 40, size.height - 43, {n = RES_DICT.TIPS_BTN})
        view:addChild(tipsBtn, 5)

        -- 剩余时间
        local timeBg = display.newImageView(RES_DICT.TIME_BG, 1030, 600, {ap = display.RIGHT_CENTER})
        local timeBgSize = timeBg:getContentSize()
        view:addChild(timeBg, 5)
        local timeTitleLabel = display.newLabel(25, timeBgSize.height / 2, fontWithColor(18, {text = __('剩余时间:'), ap = display.LEFT_CENTER}))
        local timeTitleLabelSize = display.getLabelContentSize(timeTitleLabel)
        timeBg:addChild(timeTitleLabel, 5)
        local timeLabel = display.newLabel(timeTitleLabel:getPositionX() + timeTitleLabelSize.width + 5, timeTitleLabel:getPositionY(), {text = '', ap = cc.p(0, 0.5), fontSize = 24, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
        timeBg:addChild(timeLabel, 5)

        -- 排行榜
        local rankBtn = display.newButton(size.width - 60, size.height - 110, {n = RES_DICT.RANK_BTN})
        view:addChild(rankBtn, 5)
        display.commonLabelParams(rankBtn, fontWithColor(14, {text = __('排行榜'), offset = cc.p(0, - 35)}))

        -- 队伍layout
        local teamLayoutSize = cc.size(size.width, 420)
        local teamLayout = CLayout:create(teamLayoutSize)
        teamLayout:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(teamLayout, 3)

        local teamPointLabel = cc.Label:createWithBMFont('font/team_ico_fight_figure_2.fnt', '')
        teamPointLabel:setAnchorPoint(cc.p(0.5, 0.5))
        teamPointLabel:setHorizontalAlignment(display.TAR)
        teamPointLabel:setPosition(cc.p(teamLayoutSize.width / 2, teamLayoutSize.height - 20))
        teamPointLabel:setScale(0.5)
        teamLayout:addChild(teamPointLabel, 1)

        local teamTitleBg = display.newButton(teamLayoutSize.width / 2, teamLayoutSize.height - 50, {n = RES_DICT.TEAM_TITLE_BG})
        teamTitleBg:setEnabled(false)
        teamLayout:addChild(teamTitleBg, 1)
        
        local teamBg = display.newImageView('', size.width / 2, 120)
        teamLayout:addChild(teamBg, 1)
        
        local pageupBtnShoadow = display.newImageView(RES_DICT.SWITCH_BTN_BG, 70, teamLayoutSize.height / 2)
        pageupBtnShoadow:setScale(-1)
        teamLayout:addChild(pageupBtnShoadow, 5)
        local pageupBtnBg = display.newImageView(RES_DICT.SWITCH_BTN_BG_D, 74, teamLayoutSize.height / 2)
        teamLayout:addChild(pageupBtnBg, 5)
        local pageupBtn = display.newButton(74, teamLayoutSize.height / 2, {n = RES_DICT.SWITCH_BTN_D})
        teamLayout:addChild(pageupBtn, 5)

        local pagedownBtnShadow = display.newImageView(RES_DICT.SWITCH_BTN_BG, teamLayoutSize.width - 70, teamLayoutSize.height / 2)
        teamLayout:addChild(pagedownBtnShadow, 5)
        local pagedownBtnBg = display.newImageView(RES_DICT.SWITCH_BTN_BG_N, teamLayoutSize.width - 74, teamLayoutSize.height / 2)
        teamLayout:addChild(pagedownBtnBg, 5)
        local pagedownBtn = display.newButton(teamLayoutSize.width - 74, teamLayoutSize.height / 2, {n = RES_DICT.SWITCH_BTN_N})
        teamLayout:addChild(pagedownBtn, 5)

        -- 奖励layout
        local rewardsLayoutSize = cc.size(540, 220)
        local rewardsLayout = CLayout:create(rewardsLayoutSize)
        display.commonUIParams(rewardsLayout, {po = cc.p(0, 0), ap = display.LEFT_BOTTOM})
        view:addChild(rewardsLayout, 3)
        local rewardNodeList = {}
        for i = 1, 3 do
            local rewardNodeComponent = self:CreateRewardNode()
            rewardNodeComponent.node:setPosition(cc.p(-70 + i * 220, rewardsLayoutSize.height / 2))
            rewardNodeComponent.node:setVisible(false)
            rewardsLayout:addChild(rewardNodeComponent.node, 1)
            rewardNodeComponent.bgBtn:setTag(i)
            -- rewardNodeComponent.drawBtn:setTag(i)
            table.insert(rewardNodeList, rewardNodeComponent)
        end

        -- 剩余次数
        local leftTimesLabel = display.newLabel(size.width - 220, 90, {text = __('本期剩余次数'), w = 200, hAlign = display.TAR,  fontSize = 22, color = '#69504b', ap = display.RIGHT_CENTER})
        view:addChild(leftTimesLabel, 5)
        local leftTimesNumBg = display.newImageView(RES_DICT.LEFT_TIMES_BG, size.width - 290, 40)
        view:addChild(leftTimesNumBg, 3)
        local leftTimesNumLabel = display.newLabel(size.width - 295, 40, {text = '', fontSize = 24, color = '#ffffff'})
        view:addChild(leftTimesNumLabel, 5)
        local buyTimesBtn = display.newButton(size.width - 230, 41, {n = RES_DICT.COMMON_ADD_BTN})
        view:addChild(buyTimesBtn, 5)
        -- 选择队伍
        local selectTeamBtn = display.newButton(size.width - 110, 60, {n = RES_DICT.COMMON_BTN_ORANGE_2})
        display.commonLabelParams(selectTeamBtn, fontWithColor(14, {text = __('选择队伍'), reqW = 180 , hAlign = display.TAC, fontSize = 32}))
        view:addChild(selectTeamBtn, 5)

        return {
            view                    = view,
            tipsBtn                 = tipsBtn,
            buyTimesBtn             = buyTimesBtn,
            selectTeamBtn           = selectTeamBtn,
            rewardNodeList          = rewardNodeList,
            leftTimesNumLabel       = leftTimesNumLabel,
            teamLayout              = teamLayout,
            timeLabel               = timeLabel,
            teamTitleBg             = teamTitleBg,
            pageupBtnBg             = pageupBtnBg,
            pageupBtn               = pageupBtn,
            pagedownBtnBg           = pagedownBtnBg,
            pagedownBtn             = pagedownBtn,
            teamBg                  = teamBg,
            rankBtn                 = rankBtn,
            teamPointLabel          = teamPointLabel,
        }
    end
    xTry(function ( )
        self.viewData = CreateView(VIEW_SIZE)
        self:addChild(self.viewData.view)
	end, __G__TRACKBACK__)
end
--[[
创建奖励node
--]]
function ActivityUltimateBattleView:CreateRewardNode()
    local nodeSize = cc.size(160, 200)
    local node = CLayout:create(nodeSize)
    local bgBtn = display.newButton(nodeSize.width / 2, nodeSize.height / 2 - 20, {n = RES_DICT.PRIZE_BG})
    node:addChild(bgBtn, 1)
    local goodsBg = display.newImageView(RES_DICT.PRIZE_GOODS_BG, nodeSize.width / 2, nodeSize.height / 2 - 20)
    node:addChild(goodsBg, 1)
    local goodsBgLight = display.newImageView(RES_DICT.PRIZE_GOODS_BG_LIGHT, goodsBg:getContentSize().width / 2, goodsBg:getContentSize().height / 2)
    goodsBg:addChild(goodsBgLight, 1)
    goodsBgLight:runAction(
        cc.RepeatForever:create(
            cc.RotateBy:create(10, 180)
        )
    )
    local goodsIcon = display.newImageView('', nodeSize.width / 2, nodeSize.height / 2 - 20)
    goodsIcon:setScale(0.6)
    node:addChild(goodsIcon, 3)
    -- 领取按钮因为改成了自动领取，又不要了。指不定哪天他们再改回来，代码先留着
    -- local drawBtn = display.newButton(nodeSize.width / 2, nodeSize.height - 75, {n = RES_DICT.PRIZE_DRAW_BTN, ap = display.CENTER_BOTTOM})
    -- node:addChild(drawBtn, 5)
    -- display.commonLabelParams(drawBtn, fontWithColor(14, {text = __("点击领取"), offset = cc.p(0, 7)}))
    local drawnIcon = display.newImageView(RES_DICT.PRIZE_DRAWN_ICON, nodeSize.width / 2, nodeSize.height - 90, {ap = display.CENTER_BOTTOM})
    node:addChild(drawnIcon, 5) 
    local mask = display.newImageView(RES_DICT.PRIZE_MASK, nodeSize.width / 2, nodeSize.height / 2 - 20)
    node:addChild(mask, 5)
    local lockIcon = display.newImageView(RES_DICT.PRIZE_LOCK_ICON, mask:getContentSize().width / 2, mask:getContentSize().height / 2)
    mask:addChild(lockIcon, 1)
    local nameBg = display.newImageView(RES_DICT.PRIZE_NAME_BG, nodeSize.width / 2, 25)
    node:addChild(nameBg, 5)
    local nameLabel = display.newLabel(nodeSize.width / 2, 25, {text = '', fontSize = 24, color = '#ffffff'})
    node:addChild(nameLabel, 5)
    return {
        node        = node,
        bgBtn       = bgBtn,
        goodsBg     = goodsBg,
        -- drawBtn     = drawBtn,
        drawnIcon   = drawnIcon,
        mask        = mask,
        goodsIcon   = goodsIcon,
        nameLabel   = nameLabel,
    }
end
--[[
刷新奖励节点
@params nodeComponent map 节点控件
@params reawrdsData    map 奖励数据 
{
    canDrawn int 是否可以领取
    groupId  int 组别id
    hasDrawn int 是否领取
    rewards  list 奖励（标准格式）
}
--]]
function ActivityUltimateBattleView:RefreshRewardsNode( nodeComponent, reawrdsData )
    if not reawrdsData then
        nodeComponent.node:setVisible(false)
        return 
    end
    if checkint(reawrdsData.hasDrawn) == 1 then
        -- 已领取
        -- nodeComponent.drawBtn:setVisible(false)
        nodeComponent.mask:setVisible(false)
        nodeComponent.goodsBg:setVisible(false)
        nodeComponent.drawnIcon:setVisible(true)

    else
        if checkint(reawrdsData.canDrawn) == 1 then
            -- 可领取
            -- nodeComponent.drawBtn:setVisible(true)
            nodeComponent.mask:setVisible(false)
            nodeComponent.goodsBg:setVisible(true)
            nodeComponent.drawnIcon:setVisible(false)
        else
            -- 不可领取
            -- nodeComponent.drawBtn:setVisible(false)
            nodeComponent.mask:setVisible(true)
            nodeComponent.goodsBg:setVisible(false)
            nodeComponent.drawnIcon:setVisible(false)
        end
    end
    local goodsId = checkint(reawrdsData.rewards[1].goodsId)
    local chestData = CommonUtils.GetConfig('goods', 'chest', reawrdsData.rewards[1].goodsId)
    nodeComponent.goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(chestData.photoId))
    nodeComponent.nameLabel:setString(chestData.name)
    local groupConfig = CommonUtils.GetConfig('ultimateBattle', 'group', reawrdsData.groupId)
    nodeComponent.bgBtn:setNormalImage(_res(string.format('ui/home/activity/ultimateBattle/duel_bg_prize_style_%d.png', groupConfig.display)))
    nodeComponent.bgBtn:setSelectedImage(_res(string.format('ui/home/activity/ultimateBattle/duel_bg_prize_style_%d.png', groupConfig.display)))
end
--[[
刷新剩余次数
--]]
function ActivityUltimateBattleView:RefreshLeftTimes( leftTimes, maxTimes )
    local viewData = self:GetViewData()
    viewData.leftTimesNumLabel:setString(string.format('%d/%d', checkint(leftTimes), checkint(maxTimes)))
end
--[[
刷新剩余时间
--]]
function ActivityUltimateBattleView:UpdateTimeLabel( seconds )
    local viewData = self:GetViewData()
    viewData.timeLabel:setString(CommonUtils.getTimeFormatByType(seconds, 0))
end
--[[
刷新队伍layout
@params {
    cards list 敌人卡牌数据
    name  str 编队名称
    difficulty int 难度（用于显示背景）
    teamNum int 编队数目
    teamId int 编队id
}
--]]
function ActivityUltimateBattleView:RefereshTeamLayout( params )
    local viewData = self:GetViewData()
    display.commonLabelParams(viewData.teamTitleBg, fontWithColor(3, {text = params.name[1] or ''}))

    if checkint(params.teamId) == 1 then
        viewData.pageupBtnBg:setTexture(RES_DICT.SWITCH_BTN_BG_D)
        viewData.pageupBtnBg:setScaleX(1)
        viewData.pageupBtn:setNormalImage(RES_DICT.SWITCH_BTN_D)
        viewData.pageupBtn:setSelectedImage(RES_DICT.SWITCH_BTN_D)
        viewData.pageupBtn:setScaleX(1)
        viewData.pageupBtn:setEnabled(false)
    else
        viewData.pageupBtnBg:setTexture(RES_DICT.SWITCH_BTN_BG_N)
        viewData.pageupBtnBg:setScaleX(-1)
        viewData.pageupBtn:setNormalImage(RES_DICT.SWITCH_BTN_N)
        viewData.pageupBtn:setSelectedImage(RES_DICT.SWITCH_BTN_N)
        viewData.pageupBtn:setScaleX(-1)
        viewData.pageupBtn:setEnabled(true)
    end
    if checkint(params.teamId) >= checkint(params.teamNum) then
        viewData.pagedownBtnBg:setTexture(RES_DICT.SWITCH_BTN_BG_D)
        viewData.pagedownBtnBg:setScaleX(-1)
        viewData.pagedownBtn:setNormalImage(RES_DICT.SWITCH_BTN_D)
        viewData.pagedownBtn:setSelectedImage(RES_DICT.SWITCH_BTN_D)
        viewData.pagedownBtn:setScaleX(-1)
        viewData.pagedownBtn:setEnabled(false)
    else
        viewData.pagedownBtnBg:setTexture(RES_DICT.SWITCH_BTN_BG_N)
        viewData.pagedownBtnBg:setScaleX(1)
        viewData.pagedownBtn:setNormalImage(RES_DICT.SWITCH_BTN_N)
        viewData.pagedownBtn:setSelectedImage(RES_DICT.SWITCH_BTN_N)
        viewData.pagedownBtn:setScaleX(1)
        viewData.pagedownBtn:setEnabled(true)
    end

    if viewData.teamLayout:getChildByName("spineLayout") then
        viewData.teamLayout:getChildByName("spineLayout"):removeFromParent()
    end
    local layoutSize = cc.size(830, 290)
    local layout = CLayout:create(layoutSize)
    layout:setName("spineLayout")
    display.commonUIParams(layout, {ap = display.CENTER_BOTTOM, po = cc.p(viewData.teamLayout:getContentSize().width / 2, 70)})
    viewData.teamLayout:addChild(layout, 4)

    local battlePoint = 0 -- 队伍战斗力
    -- -- spine
    for i, v in ipairs(params.cards) do
        battlePoint = battlePoint + CardUtils.GetCardStaticBattlePointByCardData(v)
        local avatarSpine = AssetsUtils.GetCardSpineNode({skinId = v.defaultSkinId, scale = 0.5})
        avatarSpine:update(0)
        avatarSpine:setAnimation(0, 'idle', true)
        avatarSpine:setPosition(cc.p(-50 + i * 152, 60))
        layout:addChild(avatarSpine, 5)
        local base = display.newImageView(RES_DICT.TEAM_BASE, -50 + i * 152, 52)
        layout:addChild(base, 1)
        local levelBg = display.newButton(-50 + i * 152, 45, {n = RES_DICT.NAME_LV_BG, enable = false})
        display.commonLabelParams(levelBg, {fontSize = 22, color = '#ffffff', text = string.fmt(__('等级:_num_'), {_num_ = v.level})})
        layout:addChild(levelBg, 3)
        local clickBtn = display.newButton(-50 + i * 152, 40, {ap = display.CENTER_BOTTOM, size = cc.size(150, 250)})
        clickBtn:setOnClickScriptHandler(function () 
            PlayAudioByClickNormal()
            local playerCardDetailData = {
                cardData = {
                    breakLevel = v.breakLevel,
                    cardId     = v.cardId,
                    favorLevel = v.favorabilityLevel,
                    level      = v.level,
                    skinId     = v.defaultSkinId,
                    artifactTalent = v.artifactTalent,
                    isArtifactUnlock = v.isArtifactUnlock,
                    bookLevel = v.bookLevel,
                    equippedHouseCatGene = v.equippedHouseCatGene,
                },
                petsData = v.pets,
                viewType = 1,
            }
            local playerCardDetailView = require('Game.views.raid.PlayerCardDetailView').new(playerCardDetailData)
            playerCardDetailView:setTag(2222)
            display.commonUIParams(playerCardDetailView, {ap = cc.p(0.5, 0.5), po = cc.p(
                    display.cx, display.cy
            )})
            app.uiMgr:GetCurrentScene():AddDialog(playerCardDetailView)
        end)
        layout:addChild(clickBtn, 5)
    end
    -- -- 背景
    viewData.teamBg:setTexture(string.format('ui/home/activity/ultimateBattle/duel_bg_team_style_%d.png', checkint(params.difficulty)))
    -- 战斗力
    viewData.teamPointLabel:setString(battlePoint)
    for i = 1, params.teamNum do
        local img = i == params.teamId and RES_DICT.TEAM_POINT_ICO_S or RES_DICT.TEAM_POINT_ICO_D
        local point = display.newImageView(img, layoutSize.width / 2 - (40 * params.teamNum - 20) / 2 + i * 40 - 30, 15)
        layout:addChild(point, 5)
    end
end
--[[
获取viewData
--]]
function ActivityUltimateBattleView:GetViewData()
    return self.viewData
end
return ActivityUltimateBattleView