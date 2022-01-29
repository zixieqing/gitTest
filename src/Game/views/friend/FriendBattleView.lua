--[[
 * author : liuzhipeng
 * descpt : 好友 好友切磋View
--]]
local FriendBattleView = class('FriendBattleView', function ()
	local node = CLayout:create(cc.size(1068, 574))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'Game.views.friend.FriendBattleView'
	node:enableNodeEvents()
	return node
end)
local RES_DICT = {
    TOP_BG           = _res('ui/home/friend/friendBattle/friend_battle_bg_blue.png'),
    BOTTOM_BG        = _res('ui/home/friend/friendBattle/friend_battle_bg_red.png'),
    CENTER_LICHT     = _res('ui/home/friend/friendBattle/friend_battle_img_light_2.png'),
    LIGHT_LINE       = _res('ui/home/friend/friendBattle/friend_battle_img_light.png'),
    VS_IMG           = _res('ui/home/friend/friendBattle/starplan_vs_icon_vs.png'),
    TEAM_LABEL_BG    = _res('ui/home/friend/friendBattle/friend_battle_bg_title_team.png'),
    TEAM_BG          = _res('ui/home/friend/friendBattle/friend_battle_bg_my_team.png'),
    TIPS_ICON        = _res('ui/common/common_btn_tips.png'),
    REPORT_BTN       = _res('ui/pvc/pvp_board_btn_report.png'),
    REPORT_ICON      = _res('ui/pvc/pvp_board_ico_report.png'),
    BATTLE_BTN_BG    = _res('ui/home/friend/friendBattle/friend_battle_bg_button.png'),
    ENEMY_TEAM_BG    = _res('ui/home/friend/friendBattle/friend_battle_bg_team_2.png'),
    ADD_ICON         = _res('ui/common/maps_fight_btn_pet_add.png'),
    CARD_HEAD_BG     = _res('ui/common/kapai_frame_bg_nocard.png'),
    TEAM_ICO_CAPTAIN = _res('ui/home/teamformation/team_ico_captain.png')
}
function FriendBattleView:ctor( ... )
    self:InitUI()
end

function FriendBattleView:InitUI()
    local function CreateView( )
    	local size = cc.size(1068, 574)
        local view = CLayout:create(size)
        -- mask --
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- mask --
        
        -- 背景 --
        local topBg = display.newImageView(RES_DICT.TOP_BG, size.width / 2, size.height, {ap = cc.p(display.CENTER_TOP)})
        view:addChild(topBg, 1)
        local bottomBg = display.newImageView(RES_DICT.BOTTOM_BG, size.width / 2, 0, {ap = cc.p(display.CENTER_BOTTOM)})
        view:addChild(bottomBg, 1)
        local lightLine = display.newImageView(RES_DICT.LIGHT_LINE, size.width / 2, size.height / 2)
        view:addChild(lightLine, 2)
        local centerLight = display.newImageView(RES_DICT.CENTER_LICHT, size.width / 2, size.height / 2)
        view:addChild(centerLight, 3)
        local vsImg = display.newImageView(RES_DICT.VS_IMG, size.width / 2 + 10, size.height / 2 + 5)
        view:addChild(vsImg, 3)
        local title = display.newLabel(25, 285, {text = __('好友切磋'), fontSize = 50, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#1a54d0', outlineSize = 5, ap = display.LEFT_CENTER})
        title:setRotation(-4)
        view:addChild(title, 10)
        local tipsLabel = display.newLabel(size.width - 320, 290, {text = __('tips:奖励不是最终目的，陪伴才是长久之情。别犹豫，来与好友一起切磋，共同成长吧！'), fontSize = 18, color = '#5a2923', w = 310, ap = display.LEFT_TOP})
        tipsLabel:setRotation(-4)
        view:addChild(tipsLabel, 5)
        -- 背景 --

        -- 我方区域 --
        local teamLabelBg = display.newImageView(RES_DICT.TEAM_LABEL_BG, 430, size.height - 50)
        view:addChild(teamLabelBg, 10)
        local tipsBtn = display.newButton(360, size.height - 50, {n = RES_DICT.TIPS_ICON})
        view:addChild(tipsBtn, 10)
        local teamLabel = display.newLabel(385, size.height - 50, {text = __('我的队伍'), fontSize = 22, color = '#ffefd0', ap = display.LEFT_CENTER, reqW = 130})
        view:addChild(teamLabel, 10)
        local teamBg = display.newImageView(RES_DICT.TEAM_BG, size.width / 2 + 40 , size.height - 150)
        view:addChild(teamBg, 5)
        local battlePointLabel = cc.Label:createWithBMFont('font/team_ico_fight_figure_2.fnt', '0')
        display.commonUIParams(battlePointLabel, {ap = display.RIGHT_CENTER, po = cc.p(size.width - 92, size.height - 58)})
        battlePointLabel:setHorizontalAlignment(display.TAR)
        battlePointLabel:setScale(0.5)
        view:addChild(battlePointLabel, 5)
        -- 卡牌头像背景
        local cardHeadBtnlist = {}
        for i = 1, 5 do
            local cardHeadBtn = display.newButton(250 + i * 130, size.height - 150, {n = RES_DICT.CARD_HEAD_BG})
            cardHeadBtn:setScale(0.68)
            view:addChild(cardHeadBtn, 5)
            local addIcon = display.newImageView(RES_DICT.ADD_ICON, 250 + i * 130, size.height - 150)
            view:addChild(addIcon, 5)
            table.insert(cardHeadBtnlist, cardHeadBtn)
            -- 队长标志
            if i == 1 then
                local captainIcon = display.newImageView(RES_DICT.TEAM_ICO_CAPTAIN, cardHeadBtn:getContentSize().width / 2, cardHeadBtn:getContentSize().height - 6)
                cardHeadBtn:addChild(captainIcon, 5)
            end
        end
        -- cardHeadLayout
        local cardHeadLayoutSize = teamBg:getContentSize()
        local cardHeadLayout = CLayout:create(cardHeadLayoutSize)
        cardHeadLayout:setPosition(cc.p(teamBg:getPositionX(), teamBg:getPositionY()))
        view:addChild(cardHeadLayout, 5)
        -- 我方区域 --

        -- 敌方区域 -- 
        local reportBtn = display.newButton(110, 40, {n = RES_DICT.REPORT_BTN})
        view:addChild(reportBtn, 5)
        display.commonLabelParams(reportBtn, {text = __('战报'), fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, offset = cc.p(10, 0)})
        local reportIcon = display.newImageView(RES_DICT.REPORT_ICON, 25, reportBtn:getContentSize().height / 2)
        reportBtn:addChild(reportIcon, 5)

        local enemyTeamBtn = display.newButton(size.width / 2, 120, {n = RES_DICT.ENEMY_TEAM_BG, useS = false})
        view:addChild(enemyTeamBtn, 5)
        local enemyTeamAddIcon = display.newImageView(RES_DICT.ADD_ICON, enemyTeamBtn:getContentSize().width / 2, enemyTeamBtn:getContentSize().height / 2)
        enemyTeamBtn:addChild(enemyTeamAddIcon, 1)
        -- enemyInformationLayout
        local enemyInformationLayoutSize = cc.size(size.width, 280)
        local enemyInformationLayout = CLayout:create(enemyInformationLayoutSize)
        display.commonUIParams(enemyInformationLayout, {ap = display.CENTER_BOTTOM, po = cc.p(size.width / 2, 0)})
        view:addChild(enemyInformationLayout, 5)
        enemyInformationLayout:setVisible(false)
        local enemyAvatarIcon = require('common.FriendHeadNode').new({enable = false, scale = 0.51, showLevel = false})
        display.commonUIParams(enemyAvatarIcon, {po = cc.p(280, 222)})
        enemyInformationLayout:addChild(enemyAvatarIcon, 5)
        local enemyLevelLabel = display.newLabel(320, 240, {text = '', color = '#ffffff', fontSize = 18, ap = display.LEFT_CENTER})
        enemyInformationLayout:addChild(enemyLevelLabel, 5)
        local enemyNameLabel = display.newLabel(320, 206, {text = '', color = '#ffffff', fontSize = 32, ap = display.LEFT_CENTER})
        enemyInformationLayout:addChild(enemyNameLabel, 5)
        local enemyBattlePointLabel = cc.Label:createWithBMFont('font/team_ico_fight_figure_2.fnt', '0')
        display.commonUIParams(enemyBattlePointLabel, {ap = display.RIGHT_CENTER, po = cc.p(size.width - 250, 200)})
        enemyBattlePointLabel:setHorizontalAlignment(display.TAR)
        enemyBattlePointLabel:setScale(0.5)
        enemyInformationLayout:addChild(enemyBattlePointLabel, 5)
        local enemyTeamClickTipLabel = display.newLabel(size.width / 2, 42, {text = __('点击切换'), color = '#502f24', fontSize = 22})
        enemyInformationLayout:addChild(enemyTeamClickTipLabel, 5)
        -- enemyCardHeadLayout
        local enemyCardHeadLayoutSize = enemyTeamBtn:getContentSize()
        local enemyCardHeadLayout = CLayout:create(enemyCardHeadLayoutSize)
        enemyCardHeadLayout:setPosition(cc.p(enemyTeamBtn:getPositionX(), enemyTeamBtn:getPositionY()))
        view:addChild(enemyCardHeadLayout, 5)
        -- 敌方区域 -- 

        -- 战斗按钮 -- 
        local battleBg = display.newImageView(RES_DICT.BATTLE_BTN_BG, size.width - 130, 120)
        view:addChild(battleBg, 5)
		local battleBtn = require('common.CommonBattleButton').new({
			pattern = 1,
			buttonSkinType = BattleButtonSkinType.BASE
        })
		display.commonUIParams(battleBtn, {po = cc.p(size.width - 130, 120)})
        view:addChild(battleBtn, 5)
        -- 战斗按钮 -- 
    	return {  
            view                   = view,
            tipsBtn                = tipsBtn,
            reportBtn              = reportBtn, 
            enemyTeamBtn           = enemyTeamBtn,
            enemyTeamAddIcon       = enemyTeamAddIcon,
            battleBtn              = battleBtn,  
            cardHeadBtnlist        = cardHeadBtnlist,
            cardHeadLayout         = cardHeadLayout,
            battlePointLabel       = battlePointLabel,
            enemyCardHeadLayout    = enemyCardHeadLayout,
            enemyAvatarIcon        = enemyAvatarIcon,
            enemyLevelLabel        = enemyLevelLabel,
            enemyNameLabel         = enemyNameLabel,
            enemyBattlePointLabel  = enemyBattlePointLabel,
            enemyTeamClickTipLabel = enemyTeamClickTipLabel,
            enemyInformationLayout = enemyInformationLayout,
    	}
    end
    xTry(function ( )
        self.viewData = CreateView( )
        self.viewData.view:setAnchorPoint(cc.p(0, 0))
        self.viewData.view:setPosition(cc.p(0, 0))
        self:addChild(self.viewData.view)
    end, __G__TRACKBACK__)
end
--[[
弹出层样式
--]]
function FriendBattleView:PopupPattern()
    self:setContentSize(display.size)
    self:setAnchorPoint(display.CENTER)
    self:setPosition(display.center)

    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function()
        app:UnRegsitMediator('FriendBattleMediator')
    end)
    self.eaterLayer = eaterLayer

    app.uiMgr:GetCurrentScene():AddDialog(self)

    local viewData = self:GetViewData()
    viewData.view:setAnchorPoint(display.CENTER)
    viewData.view:setPosition(display.center)
    viewData.enemyTeamAddIcon:setVisible(false)
    viewData.enemyTeamClickTipLabel:setVisible(false)
    viewData.enemyTeamBtn:setEnabled(false)
end
--[[
刷新编队
@params team list 编队数据
--]]
function FriendBattleView:RefreshTeam( team )
    self:RefreshCardHeadLayout(team)
    self:RefreshBattlePoint(team)
    self:RefreshCardSpine(team)
end
--[[
刷新cardHeadLayout
--]]
function FriendBattleView:RefreshCardHeadLayout( team )
    local viewData = self:GetViewData()
    viewData.cardHeadLayout:removeAllChildren()
    for i, v in ipairs(team) do
        if v.id and checkint(v.id) > 0 and next(app.gameMgr:GetCardDataById(v.id)) ~= nil then
            local cardHeadNode = require('common.CardHeadNode').new({id = checkint(v.id), showActionState = false})
            cardHeadNode:setPosition(cc.p(78 + 130 * i, viewData.cardHeadLayout:getContentSize().height / 2))
            cardHeadNode:setEnabled(false)
            cardHeadNode:setScale(0.68)
            viewData.cardHeadLayout:addChild(cardHeadNode)
        end
    end
end
--[[
刷新战斗力
--]]
function FriendBattleView:RefreshBattlePoint( team )
    local viewData = self:GetViewData()
    local battlePoint = 0
	for i,v in ipairs(team) do
		if v.id then
			local cardData = app.gameMgr:GetCardDataById(v.id)
			if cardData then
				-- 计算一次战斗力
				battlePoint = battlePoint + app.cardMgr.GetCardStaticBattlePointById(v.id)
			end
		end
    end
    viewData.battlePointLabel:setString(battlePoint)
end
--[[
刷新卡牌spine
优先显示队长spine，如果队长不存在，则显示顺位第一张卡牌。没有卡牌则不显示spine
--]]
function FriendBattleView:RefreshCardSpine( team )
    local viewData = self:GetViewData()
    -- 移除当前spine
    if viewData.view:getChildByName('cardSpine') then
        viewData.view:getChildByName('cardSpine'):runAction(cc.RemoveSelf:create())
    end
    -- 获取显示卡牌的数据库id
    local cardId = nil
    for i, v in ipairs(team) do
        if v.id and checkint(v.id) > 0 then
            cardId = v.id
            break
        end
    end
    -- 判断是否显示
    if not cardId then return end
    -- 根据数据库id，获取皮肤id
    local cardData = app.gameMgr:GetCardDataById(cardId)
    if not cardData then return end
    local qAvatar = AssetsUtils.GetCardSpineNode({skinId = cardData.defaultSkinId, scale = 0.6})
    qAvatar:update(0)
    qAvatar:setToSetupPose()
    qAvatar:setAnimation(0, 'idle', true)
    qAvatar:setName('cardSpine')
    qAvatar:setPosition(cc.p(160, 280))
    viewData.view:addChild(qAvatar, 7)
end
--[[
刷新敌方信息
@params playerData map 编队数据 {
	avatar      string 头像id
	avatarFrame string 头像框id
	level       string 等级
	name        string 名称
	team        list   编队信息
}
--]]
function FriendBattleView:RefreshEnemyInformation( playerData )
    self:RefreshEnemyPlayer(playerData)
    self:RefreshEnemyTeam(checktable(playerData.team))
end
--[[
刷新敌方玩家信息
@params playerData map 编队数据 {
	avatar      string 头像id
	avatarFrame string 头像框id
	level       string 等级
	name        string 名称
	team        list   编队信息
}
--]]
function FriendBattleView:RefreshEnemyPlayer( playerData )
    local viewData = self:GetViewData()
    viewData.enemyAvatarIcon:RefreshSelf({avatar = playerData.avatar, avatarFrame = playerData.avatarFrame})
    viewData.enemyLevelLabel:setString(string.fmt(__('等级:_num_'), {['_num_'] = checkint(playerData.level)}))
    viewData.enemyNameLabel:setString(tostring(playerData.name))
    viewData.enemyInformationLayout:setVisible(true)
    viewData.enemyTeamAddIcon:setVisible(false)
end
--[[
刷新敌方编队
@params team list 编队数据
--]]
function FriendBattleView:RefreshEnemyTeam( team )
    self:RefreshEnemyCardHeadLayout(team)
    self:RefreshEnemyBattlePoint(team) 
end
--[[
刷新enemyCardHeadLayout
--]]
function FriendBattleView:RefreshEnemyCardHeadLayout( team )
    local viewData = self:GetViewData()
    viewData.enemyCardHeadLayout:removeAllChildren()
    for i, v in ipairs(team) do
        if v.cardId and checkint(v.cardId) > 0 then
            local cardHeadNode = require('common.CardHeadNode').new({
                cardData = {
                    cardId = v.cardId,
                    level = v.level,
                    breakLevel = v.breakLevel,
                    skinId = v.skinId
                },
                showBaseState = true,
                showActionState = false,
                showVigourState = false
            })
            cardHeadNode:setPosition(cc.p(-35 + 108 * i, viewData.enemyTeamBtn:getContentSize().height / 2))
            cardHeadNode:setEnabled(false)
            cardHeadNode:setScale(0.55)
            viewData.enemyCardHeadLayout:addChild(cardHeadNode)
        end
    end
end
--[[
刷新敌方编队战斗力
@params team list 编队数据
--]]
function FriendBattleView:RefreshEnemyBattlePoint( team )
    local viewData = self:GetViewData()
    local battlePoint = 0
	for i,v in ipairs(team) do
		if v.cardId then
            -- 计算一次战斗力
            v.playerPetId = nil
            battlePoint = battlePoint + app.cardMgr.GetCardStaticBattlePointByCardData(v)
		end
    end
    viewData.enemyBattlePointLabel:setString(battlePoint)
end
--[[
获取viewData
--]]
function FriendBattleView:GetViewData()
    return self.viewData
end
return FriendBattleView