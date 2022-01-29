---@class Anniversary19SuppressCell : CGridViewCell
local Anniversary19SuppressCell = class('Anniversary19SuppressCell', function ()
    local Anniversary19SuppressCell = CGridViewCell:new()
    Anniversary19SuppressCell:enableNodeEvents()
    return Anniversary19SuppressCell
end)


local RES_DICT = {
    COMMON_BG_LIST                  = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_list.png'),
    COMMON_BTN_ORANGE               = app.anniversary2019Mgr:GetResPath('ui/common/common_btn_orange.png'),
    ACTIVITY_MIFAN_BY_ICO           = app.anniversary2019Mgr:GetResPath('ui/common/activity_mifan_by_ico.png'),
    COOKING_BTN_POKEDEX_2           = app.anniversary2019Mgr:GetResPath('ui/home/kitchen/cooking_btn_pokedex_2.png'),
    TEAM_BTN_SELECTION_UNUSED       = app.anniversary2019Mgr:GetResPath('ui/home/teamformation/choosehero/team_btn_selection_unused.png'),
    WONDERLAND_BATTLE_BOSS2         = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_battle_boss2.png'),
    WONDERLAND_BG_BOSS_BLOOD        = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_bg_boss_blood.png'),
    WONDERLAND_BG_BOSS_BLOOD_2      = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_bg_boss_blood_2.png'),
    WONDERLAND_BG_NAME              = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_bg_name.png'),
    WONDERLAND_BTN_PRIZE            = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_btn_prize.png'),
    WONDERLAND_ICO_SHARE_LINE       = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_ico_share_line.png'),
    WONDERLAND_IMG_BOSS_BLOOD       = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_img_boss_blood.png'),
    WONDERLAND_IMG_BOSS_BLOOD_2     = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_img_boss_blood_2.png'),
}

function Anniversary19SuppressCell:ctor( ... )
	self.args = unpack({...}) or {}

	self:InitUI()
end

function Anniversary19SuppressCell:InitUI()
    local function CreateView()
        self:setContentSize(cc.size(1150, 150))
        local view = CLayout:create(cc.size(1140, 144))
        view:setPosition(575, 75)
        self:addChild(view)

        local BG = display.newImageView(RES_DICT.COMMON_BG_LIST, 0, 0,
        {
            ap = display.LEFT_BOTTOM,
            scale9 = true, size = cc.size(1124, 143),
        })
        view:addChild(BG)
        
        local bossImage = FilteredSpriteWithOne:create(RES_DICT.WONDERLAND_BATTLE_BOSS2)
        bossImage:setPosition(cc.p(137, 72))
        view:addChild(bossImage)

        local bossPreviewBtn = display.newButton(27, 28,
        {
            ap = display.CENTER,
            n = RES_DICT.COOKING_BTN_POKEDEX_2,
            enable = true,
        })
        -- display.commonLabelParams(bossPreviewBtn, fontWithColor(14, {text = ''}))
        view:addChild(bossPreviewBtn)

        ------------------myPanel start-------------------
        local myPanel = display.newLayer(179, 8,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(300, 40),
            enable = false,
        })
        view:addChild(myPanel)

        local Image_2 = display.newImageView(RES_DICT.WONDERLAND_BG_NAME, 107, 19,
        {
            ap = display.CENTER,
        })
        myPanel:addChild(Image_2)

        local myNameLabel = display.newLabel(13, 17,
        {
            text = app.anniversary2019Mgr:GetPoText(__('自己发现')),
            ap = display.LEFT_CENTER,
            fontSize = 22,
            color = '#595755',
        })
        myPanel:addChild(myNameLabel)

        -------------------myPanel end--------------------
        -----------------otherPanel start-----------------
        local otherPanel = display.newLayer(177, 8,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(400, 60),
            enable = false,
        })
        view:addChild(otherPanel)

        local Image_2_0 = display.newImageView(RES_DICT.WONDERLAND_BG_NAME, 109, 19,
        {
            ap = display.CENTER,
        })
        otherPanel:addChild(Image_2_0)

        local ownerLabel = display.newLabel(11, 42,
        {
            text = app.anniversary2019Mgr:GetPoText(__('提供者：')),
            ap = display.LEFT_CENTER,
            fontSize = 18,
            color = '#706767',
        })
        otherPanel:addChild(ownerLabel)

        local ownerNameLabel = display.newRichLabel(13, 17,
        {
            -- text = '',
            ap = display.LEFT_CENTER,
            -- fontSize = 22,
            -- color = '#595755',
        })
        otherPanel:addChild(ownerNameLabel)

        ------------------otherPanel end------------------
        local bossNameLabel = display.newRichLabel(184, 120,
        {
            -- text = '',
            ap = display.LEFT_CENTER,
            -- fontSize = 24,
            -- color = '#6c5353',
        })
        view:addChild(bossNameLabel)

        --------------participantPanel start--------------
        local participantPanel = display.newLayer(0, 0,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(1140, 143),
            enable = false,
        })
        view:addChild(participantPanel)

        local rewardPreviewBtn = display.newButton(883, 39,
        {
            ap = display.CENTER,
            n = RES_DICT.WONDERLAND_BTN_PRIZE,
            enable = true,
        })
        display.commonLabelParams(rewardPreviewBtn, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('奖励预览')), fontSize = 21, color = '#ffffff', offset = cc.p(0, -20)}))
        participantPanel:addChild(rewardPreviewBtn)

        local bossBloodBar = CProgressBar:create(RES_DICT.WONDERLAND_IMG_BOSS_BLOOD)
        bossBloodBar:setBackgroundImage(RES_DICT.WONDERLAND_BG_BOSS_BLOOD)
        bossBloodBar:setAnchorPoint(display.CENTER)
        bossBloodBar:setMaxValue(100)
        bossBloodBar:setValue(0)
        bossBloodBar:setDirection(eProgressBarDirectionLeftToRight)
        bossBloodBar:setPosition(cc.p(559, 95))
        bossBloodBar:initText("0", TTF_GAME_FONT, 20, cc.size(800, 30), ccc3FromInt("#ffffff"))
        bossBloodBar:getLabel():setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
        bossBloodBar:getLabel():setVerticalAlignment(cc.TEXT_ALIGNMENT_CENTER)
        bossBloodBar:setShowValueLabel(true)
        participantPanel:addChild(bossBloodBar)

        -----------------sharePanel start-----------------
        local sharePanel = display.newLayer(0, 0,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(1140, 143),
            enable = false,
        })
        participantPanel:addChild(sharePanel)

        local leftCountdownLabel = display.newLabel(1035, 88,
        {
            text = '',
            ap = display.CENTER,
            fontSize = 24,
            color = '#b68686',
        })
        sharePanel:addChild(leftCountdownLabel)

        local shareBtn = display.newButton(1035, 71,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        display.commonLabelParams(shareBtn, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('分享'))}))
        sharePanel:addChild(shareBtn)

        ----------------sharedPanel start-----------------
        local sharedPanel = display.newLayer(0, 0,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(1140, 143),
            enable = false,
        })
        sharePanel:addChild(sharedPanel)

        local Image_3 = display.newImageView(RES_DICT.WONDERLAND_ICO_SHARE_LINE, 1035, 72,
        {
            ap = display.CENTER,
        })
        sharedPanel:addChild(Image_3)

        local Text_2 = display.newLabel(1035, 56,
        {
            text = app.anniversary2019Mgr:GetPoText(__('已分享')),
            ap = display.CENTER,
            fontSize = 24,
            color = '#795953',
            font = TTF_GAME_FONT, ttf = true,
        })
        sharedPanel:addChild(Text_2)

        -----------------sharedPanel end------------------
        ------------------sharePanel end------------------
        ---------------suppressPanel start----------------
        local suppressPanel = display.newLayer(0, 0,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(1140, 143),
            enable = false,
        })
        participantPanel:addChild(suppressPanel)

        local suppressBtn = display.newButton(1035, 71,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        display.commonLabelParams(suppressBtn, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('讨伐'))}))
        suppressPanel:addChild(suppressBtn)

        local countdownLabel = display.newLabel(1034, 115,
        {
            text = '',
            ap = display.CENTER,
            fontSize = 24,
            color = '#b68686',
        })
        suppressPanel:addChild(countdownLabel)

        -------------suppressCostPanel start--------------
        local suppressCostPanel = display.newLayer(0, 0,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(1140, 143),
            enable = false,
        })
        suppressPanel:addChild(suppressCostPanel)

        local anniversary2019Mgr = app.anniversary2019Mgr

        local suppressCostLabel = display.newLabel(1049, 26,
        {
            text = anniversary2019Mgr:GetSuppressHPConsume(),
            ap = display.CENTER,
            fontSize = 24,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#000000',
        })
        suppressCostPanel:addChild(suppressCostLabel)

        local supressCostImage = display.newImageView(CommonUtils.GetGoodsIconPathById(anniversary2019Mgr:GetSuppressHPId()), 1029, 26,
        {
            ap = display.CENTER,
        })
        supressCostImage:setScale(0.2, 0.2)
        suppressCostPanel:addChild(supressCostImage)

        --------------suppressCostPanel end---------------
        ----------------suppressPanel end-----------------
        ---------------participantPanel end---------------
        --------------settlementPanel start---------------
        local settlementPanel = display.newLayer(0, 0,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(1140, 143),
            enable = false,
        })
        view:addChild(settlementPanel)

        local drawBtn = display.newButton(1034, 48,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            d = RES_DICT.ACTIVITY_MIFAN_BY_ICO,
            enable = true,
        })
        display.commonLabelParams(drawBtn, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('领取'))}))
        settlementPanel:addChild(drawBtn)

        local resultLabel = display.newLabel(1035, 104,
        {
            text = '',
            ap = display.CENTER,
            fontSize = 30,
            color = '#249bff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#ffffff',
            outlineSize = 3,
        })
        settlementPanel:addChild(resultLabel)

        local Text_9 = display.newLabel(783, 123,
        {
            text = app.anniversary2019Mgr:GetPoText(__('奖励')),
            ap = display.CENTER,
            fontSize = 22,
            color = '#605148',
        })
        settlementPanel:addChild(Text_9)

        local Image_5 = display.newImageView(RES_DICT.WONDERLAND_ICO_SHARE_LINE, 783, 110,
        {
            ap = display.CENTER,
        })
        Image_5:setScaleX(1.9)
        settlementPanel:addChild(Image_5)

        local settlementBloodBar = CProgressBar:create(RES_DICT.WONDERLAND_IMG_BOSS_BLOOD_2)
        settlementBloodBar:setBackgroundImage(RES_DICT.WONDERLAND_BG_BOSS_BLOOD_2)
        settlementBloodBar:setAnchorPoint(display.CENTER)
        settlementBloodBar:setMaxValue(100)
        settlementBloodBar:setValue(100)
        settlementBloodBar:setDirection(eProgressBarDirectionLeftToRight)
        settlementBloodBar:setPosition(cc.p(402, 95))
        settlementBloodBar:initText("0", TTF_GAME_FONT, 20, cc.size(400, 30), ccc3FromInt("#ffffff"))
        settlementBloodBar:getLabel():setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
        settlementBloodBar:getLabel():setVerticalAlignment(cc.TEXT_ALIGNMENT_CENTER)
        settlementBloodBar:setShowValueLabel(true)
        settlementPanel:addChild(settlementBloodBar)

        local recordBtn = display.newButton(560, 33,
        {
            ap = display.CENTER,
            n = RES_DICT.TEAM_BTN_SELECTION_UNUSED,
            enable = true,
        })
        display.commonLabelParams(recordBtn, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('战报')), fontSize = 26, color = '#ffffff'}))
        settlementPanel:addChild(recordBtn)

        local goodsIcons = {}
        for i = 1, 3 do
		    local goodsIcon = require('common.GoodNode').new({id = DIAMOND_ID, amount = 1, showAmount = true})
		    goodsIcon:setScale(0.8)
		    goodsIcon:setPosition(583 + i * 100, 58)
            settlementPanel:addChild(goodsIcon)
            goodsIcons[i] = goodsIcon
        end
        ---------------settlementPanel end----------------
        return {
            view                    = view,
            BG                      = BG,
            bossImage               = bossImage,
            bossPreviewBtn          = bossPreviewBtn,
            myPanel                 = myPanel,
            myNameLabel             = myNameLabel,
            otherPanel              = otherPanel,
            ownerLabel              = ownerLabel,
            ownerNameLabel          = ownerNameLabel,
            bossNameLabel           = bossNameLabel,
            participantPanel        = participantPanel,
            rewardPreviewBtn        = rewardPreviewBtn,
            bossBloodBar            = bossBloodBar,
            sharePanel              = sharePanel,
            leftCountdownLabel      = leftCountdownLabel,
            shareBtn                = shareBtn,
            sharedPanel             = sharedPanel,
            suppressPanel           = suppressPanel,
            suppressBtn             = suppressBtn,
            countdownLabel          = countdownLabel,
            suppressCostPanel       = suppressCostPanel,
            suppressCostLabel       = suppressCostLabel,
            supressCostImage        = supressCostImage,
            settlementPanel         = settlementPanel,
            drawBtn                 = drawBtn,
            resultLabel             = resultLabel,
            settlementBloodBar      = settlementBloodBar,
            recordBtn               = recordBtn,
            goodsIcons              = goodsIcons,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()

        self.index = -1
	end, __G__TRACKBACK__)
end

return Anniversary19SuppressCell
