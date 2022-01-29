local GameScene = require( "Frame.GameScene" )
---@class Anniversary19SuppressView : GameScene
local Anniversary19SuppressView = class("Anniversary19SuppressView", GameScene)

local RES_DICT = {
    COMMON_BG_4                     = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_4.png'),
    COMMON_BG_GOODS                 = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_goods.png'),
    COMMON_BG_INPUT_DEFAULT         = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_input_default.png'),
    COMMON_BTN_BACK                 = app.anniversary2019Mgr:GetResPath('ui/common/common_btn_back.png'),
    COMMON_BTN_TIPS                 = app.anniversary2019Mgr:GetResPath('ui/common/common_btn_tips.png'),
    COMMON_TITLE                    = app.anniversary2019Mgr:GetResPath('ui/common/common_title.png'),
    RAID_BOSS_BTN_SEARCH            = app.anniversary2019Mgr:GetResPath('ui/common/raid_boss_btn_search.png'),
    SHOP_BTN_REFRESH                = app.anniversary2019Mgr:GetResPath('ui/home/commonShop/shop_btn_refresh.png'),
    MAIN_BG_MONEY                   = app.anniversary2019Mgr:GetResPath('ui/home/nmain/main_bg_money'),
    MARKET_MAIN_BTN_RESEARCH_DELETE = app.anniversary2019Mgr:GetResPath('ui/home/market/market_main_btn_research_delete.png'),
    TEAM_BTN_SELECTION_UNUSED       = app.anniversary2019Mgr:GetResPath('ui/home/teamformation/choosehero/team_btn_selection_unused.png'),
    GUILD_PET_BG_TIPS_NO_PET        = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/guild_pet_bg_tips_no_pet.png'),
    WONDERLAND_BATTLE_ICO_CAT       = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_battle_ico_cat.png'),
    WONDERLAND_BATTLE_TAB_NORMAL    = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_battle_tab_normal.png'),
    WONDERLAND_BATTLE_TAB_SELECTED  = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_battle_tab_selected.png'),
    WONDERLAND_IMG_FIRE             = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_img_fire.png'),
    WONDERLAND_MAIN_BG              = app.anniversary2019Mgr:GetResPath('ui/anniversary19/home/wonderland_main_bg.jpg'),
}

function Anniversary19SuppressView:ctor( ... )
	GameScene.ctor(self, 'Game.views.anniversary19.Anniversary19SuppressView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function Anniversary19SuppressView:InitUI()
	local function CreateView()
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        self:addChild(view)

        local BG = display.newImageView(RES_DICT.WONDERLAND_MAIN_BG, display.cx, display.cy,
        {
            ap = display.CENTER,
        })
        view:addChild(BG)

        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 120))
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setContentSize(display.size)
        eaterLayer:setPosition(cc.p(display.cx, display.cy))
        view:addChild(eaterLayer)
        local spineData = app.anniversary2019Mgr:GetSpinePath("ui/anniversary19/wonderland/animation/wonderland_battle_boss")
        local dropAnimation = sp.SkeletonAnimation:create(spineData.json,spineData.atlas, 1)
        dropAnimation:setPosition(cc.p(display.cx, display.cy))
        dropAnimation:update(0)
        dropAnimation:setAnimation(0, 'animation', true)
        view:addChild(dropAnimation)

        local Image_1 = display.newImageView(RES_DICT.WONDERLAND_BATTLE_ICO_CAT, display.cx - 594, 115,
        {
            ap = display.CENTER,
        })
        view:addChild(Image_1)

        local changeSkinTable = app.anniversary2019Mgr:GetChangeSkinData()
        local isVisible = changeSkinTable.Image_1 == nil and true  or changeSkinTable.Image_1
        Image_1:setVisible(isVisible)

        local nonparticipantBtn = display.newToggleView(display.cx - 576, display.height - 256,
        {
            ap = display.CENTER,
            n = RES_DICT.WONDERLAND_BATTLE_TAB_NORMAL,
            s = RES_DICT.WONDERLAND_BATTLE_TAB_SELECTED,
            enable = true,
        })
        display.commonLabelParams(nonparticipantBtn, {text = app.anniversary2019Mgr:GetPoText(__('未参加')),w=120 , hAlign= display.TAC , fontSize = 22, color = '#7e3b23'})
        nonparticipantBtn:setTag(1)
        nonparticipantBtn:setChecked(true)
        view:addChild(nonparticipantBtn)

        local participantBtn = display.newToggleView(display.cx - 576, display.height - 355,
        {
            ap = display.CENTER,
            n = RES_DICT.WONDERLAND_BATTLE_TAB_NORMAL,
            s = RES_DICT.WONDERLAND_BATTLE_TAB_SELECTED,
            enable = true,
        })
        display.commonLabelParams(participantBtn, {text = app.anniversary2019Mgr:GetPoText(__('已参加')),w=120 , hAlign= display.TAC, fontSize = 22, color = '#deaa83'})
        participantBtn:setTag(2)
        view:addChild(participantBtn)

        local settlementBtn = display.newToggleView(display.cx - 576, display.height - 453,
        {
            ap = display.CENTER,
            n = RES_DICT.WONDERLAND_BATTLE_TAB_NORMAL,
            s = RES_DICT.WONDERLAND_BATTLE_TAB_SELECTED,
            enable = true,
        })
        display.commonLabelParams(settlementBtn, {text = app.anniversary2019Mgr:GetPoText(__('结算')),w=120 , hAlign= display.TAC, fontSize = 22, color = '#deaa83'})
        settlementBtn:setTag(3)
        view:addChild(settlementBtn)

        local scrollBG = display.newImageView(RES_DICT.COMMON_BG_4, display.cx - -67, display.height - 152,
        {
            ap = display.CENTER_TOP,
            scale9 = true, size = cc.size(1160, display.height - 150),
        })
        view:addChild(scrollBG)

        local Image_2 = display.newImageView(RES_DICT.COMMON_BG_GOODS, display.cx - -67, display.height - 162,
        {
            ap = display.CENTER_TOP,
            scale9 = true, size = cc.size(1140, display.height - 166),
        })
        view:addChild(Image_2)

        local Image_3 = display.newImageView(RES_DICT.WONDERLAND_IMG_FIRE, display.cx - -66, 4,
        {
            ap = display.CENTER_BOTTOM,
        })
        view:addChild(Image_3)

        ----------------searchPanel start-----------------
        local searchPanel = display.newLayer(display.cx - -150, display.height - 151,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(500, 100),
            enable = true,
        })
        view:addChild(searchPanel)

        local Text_10 = display.newLabel(139, 66,
        {
            text = app.anniversary2019Mgr:GetPoText(__('输入信息者ID')),
            ap = display.CENTER,
            fontSize = 20,
            color = '#ffffff',
        })
        searchPanel:addChild(Text_10)

        local inputBtn = display.newButton(144, 33,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BG_INPUT_DEFAULT,
            scale9 = true, size = cc.size(220, 44),
            enable = true,
        })
        -- display.commonLabelParams(inputBtn, fontWithColor(14, {text = ''}))
        searchPanel:addChild(inputBtn)

        local searchImage = display.newImageView(RES_DICT.RAID_BOSS_BTN_SEARCH, 231, 32,
        {
            ap = display.CENTER,
        })
        searchPanel:addChild(searchImage)

        local clearBtn = display.newButton(231, 32,
        {
            ap = display.CENTER,
            n = RES_DICT.MARKET_MAIN_BTN_RESEARCH_DELETE,
        })
        searchPanel:addChild(clearBtn)
        clearBtn:setVisible(false)

        local refreshBtn = display.newButton(463, 34,
        {
            ap = display.CENTER,
            n = RES_DICT.SHOP_BTN_REFRESH,
            enable = true,
        })
        -- display.commonLabelParams(refreshBtn, fontWithColor(14, {text = ''}))
        searchPanel:addChild(refreshBtn)

        local filterBtn = display.newButton(344, 33,
        {
            ap = display.CENTER,
            n = RES_DICT.TEAM_BTN_SELECTION_UNUSED,
            enable = true,
        })
        display.commonLabelParams(filterBtn, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('筛选')), fontSize = 26, color = '#ffffff'}))
        searchPanel:addChild(filterBtn)

        local userIDLabel = display.newLabel(42, 33,
        {
            text = '',
            ap = display.LEFT_CENTER,
            fontSize = 22,
            color = '#4c4c4c',
        })
        searchPanel:addChild(userIDLabel)

        -----------------searchPanel end------------------

        local backBtn = display.newButton(display.SAFE_L + 75, display.height - 53,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_BACK,
            enable = true,
        })
        -- display.commonLabelParams(backBtn, fontWithColor(14, {text = ''}))
        view:addChild(backBtn)

		local gridView = CGridView:create(cc.size(1140, display.height - 170))
		gridView:setSizeOfCell(cc.size(1140, 150))
		gridView:setColumns(1)
		gridView:setAutoRelocate(true)
		view:addChild(gridView)
		gridView:setAnchorPoint(cc.p(0, 1.0))
		gridView:setPosition(display.cx - 500, display.height - 164)

        local viewNameLabel = display.newButton(display.SAFE_L + 130, display.height,{ ap = display.LEFT_TOP ,  n = RES_DICT.COMMON_TITLE, d = RES_DICT.COMMON_TITLE, s = RES_DICT.COMMON_TITLE, scale9 = true, capInsets = cc.rect(100, 70, 80, 1) })
        display.commonLabelParams(viewNameLabel, {ttf = true, font = TTF_GAME_FONT, text = app.anniversary2019Mgr:GetPoText(__('柴郡猫的帮助')), fontSize = 30, color = '#473227', offset = cc.p(-20, -10), paddingW = 62})
        view:addChild(viewNameLabel)

		-- 提示按钮
		local tipsImage = display.newImageView(RES_DICT.COMMON_BTN_TIPS, viewNameLabel:getContentSize().width - 42, 29)
        viewNameLabel:addChild(tipsImage)

        -----------------emptyPanel start-----------------
        local emptyPanel = display.newLayer(display.cx - 508, display.height - 156,
        {
            ap = cc.p(0, 1.0),
            size = cc.size(1150, display.height - 160),
            enable = false,
        })
        view:addChild(emptyPanel)

        -----------------emptyImage start-----------------
        local emptyImage = display.newImageView(RES_DICT.GUILD_PET_BG_TIPS_NO_PET, 564, emptyPanel:getContentSize().height / 2 + 60,
        {
            ap = display.CENTER,
        })
        emptyPanel:addChild(emptyImage)

        local Text_12 = display.newLabel(424, 140,
        {
            text = app.anniversary2019Mgr:GetPoText(__('暂未发现boss的梦境，快去仙境之旅寻找！')),
            ap = display.CENTER,
            fontSize = 22,
            color = '#4c4c4c',
            w = 360
        })
        emptyImage:addChild(Text_12)

        ------------------emptyImage end------------------
        ------------------emptyPanel end------------------

        local GoodPurchaseNode = require('common.GoodPurchaseNode')
        -- top icon
        local currencyBG = display.newImageView(RES_DICT.MAIN_BG_MONEY, 0, 0, {enable = false, scale9 = true, size = cc.size(700 + (display.width - display.SAFE_R),54)})
        display.commonUIParams(currencyBG,{ap = cc.p(1.0,1.0), po = cc.p(display.width, display.height)})
        view:addChild(currencyBG)

        local currency = { app.anniversary2019Mgr:GetSuppressHPId(), GOLD_ID, DIAMOND_ID }
        local moneyNodes = {}
        for i,v in ipairs(currency) do
            local purchaseNode = GoodPurchaseNode.new({id = v, animate = true, isEnableGain = true})
            purchaseNode:updataUi(checkint(v))
            display.commonUIParams(purchaseNode,
                    {ap = cc.p(1, 0.5), po = cc.p(display.SAFE_R - 20 - (( #currency - i) * (purchaseNode:getContentSize().width + 16)), currencyBG:getPositionY()- 26)})
            view:addChild(purchaseNode, 5)
            purchaseNode:setName('purchaseNode' .. i)
            purchaseNode.viewData.touchBg:setTag(checkint(v))
            moneyNodes[tostring( v )] = purchaseNode
        end

        local glowAnimation = sp.SkeletonAnimation:create("ui/anniversary19/wonderland/animation/wonderland_battle_guang.json","ui/anniversary19/wonderland/animation/wonderland_battle_guang.atlas", 1)
        glowAnimation:setPosition(cc.p(display.cx + 40, display.cy - (display.height) / 2 + 350))
        glowAnimation:update(0)
        glowAnimation:setAnimation(0, 'animation', true)
        view:addChild(glowAnimation)

        local particle = cc.ParticleSystemQuad:create('ui/anniversary19/wonderland/animation/wonderland_battle_lizi.plist')
        particle:setAutoRemoveOnFinish(true)
        particle:setPosition(cc.p(display.cx, 4))
        view:addChild(particle)

        return {
            view                    = view,
            BG                      = BG,
            nonparticipantBtn       = nonparticipantBtn,
            participantBtn          = participantBtn,
            settlementBtn           = settlementBtn,
            scrollBG                = scrollBG,
            searchPanel             = searchPanel,
            Text_10                 = Text_10,
            inputBtn                = inputBtn,
            searchImage             = searchImage,
            clearBtn                = clearBtn,
            refreshBtn              = refreshBtn,
            filterBtn               = filterBtn,
            userIDLabel             = userIDLabel,
            backBtn                 = backBtn,
            gridView                = gridView,
            viewNameLabel           = viewNameLabel,
            tipsImage               = tipsImage,
            emptyPanel              = emptyPanel,
            emptyImage              = emptyImage,
            moneyNodes              = moneyNodes,
            glowAnimation           = glowAnimation,
            particle                = particle,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()

        local originalPos = cc.p(self.viewData.viewNameLabel:getPosition())
        self.viewData.viewNameLabel:setPositionY(display.height + 100)
		local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, originalPos))
		self.viewData.viewNameLabel:runAction( action )
	end, __G__TRACKBACK__)
end

return Anniversary19SuppressView
