--[[
	宝石抽取卡池UI
--]]
local GameScene = require( "Frame.GameScene" )

local JewelCatcherPoolView = class('JewelCatcherPoolView', GameScene)
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local function GetFullPath( imgName )
	return _res('ui/artifact/' .. imgName)
end

function JewelCatcherPoolView:ctor( ... )
	--创建页面
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 130))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
	local function CreateView( ... )
		local view = display.newLayer(display.cx, display.height, {size = display.size, ap = display.CENTER_TOP})
		self:addChild(view)

        local bg = display.newImageView(GetFullPath('diamond_draw_bg'), display.cx, display.cy, {isFull = true})
        view:addChild(bg)

        local tabNameLabel = display.newButton(
            display.SAFE_L + 130,
            display.height + 100,
            {n = _res('ui/common/common_title_new.png'),ap = cc.p(0, 0)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('塔可转转乐'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        view:addChild(tabNameLabel)
        tabNameLabel:setOnClickScriptHandler(function ( sender )
            app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.TAG_JEWEL_EVOL)]})
        end)

        local titleSize = tabNameLabel:getContentSize()
        local tipsIcon  = display.newImageView(_res('ui/common/common_btn_tips.png'), titleSize.width - 50, titleSize.height/2 - 7)
        tabNameLabel:addChild(tipsIcon)
    
        local cageImg = display.newImageView(GetFullPath('zhuanlundi'), display.cx, display.cy + 40)
        view:addChild(cageImg)

        local mouseSpine = sp.SkeletonAnimation:create(
            'effects/artifact/zhuanpan.json',
            'effects/artifact/zhuanpan.atlas',
            1)
        mouseSpine:setPosition(cc.p(display.cx, display.cy + 48))
        view:addChild(mouseSpine)
        mouseSpine:setAnimation(0, 'idle', true)
        mouseSpine:update(0)
        mouseSpine:setToSetupPose()

        local coverImg = display.newImageView(GetFullPath('zhuanlunqian'), display.cx, display.cy + 48)
        view:addChild(coverImg)

	    -- 商店
        local shopBtn = display.newButton(display.SAFE_R - 50, display.height - 50, {n = _res('ui/home/nmain/main_btn_shop.png')})
        shopBtn:setScale(1.2)
        view:addChild(shopBtn, 10)
        display.commonLabelParams(shopBtn, fontWithColor('14', {text = __('购买'), outline = '#6a4d47', outlineSize = 1, offset = {y = -16}, tag = 123}))
        shopBtn:getChildByTag(123):setScale(1.0 / 1.2)
    
        -- 返回按钮
        local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
        display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
        view:addChild(backBtn, 21)

        view:addChild(display.newImageView(_res('avatar/ui/decorate_bg_down.png'), display.width/2, 0, {ap = display.CENTER_BOTTOM, scale9 = true, size = cc.size(display.width, 110)}))

        local selectBg = display.newImageView(GetFullPath('diamond_draw_label_select'), 0, 50, {
            ap = display.LEFT_CENTER , scale9 = true ,
            size = cc.size()
        })
        view:addChild(selectBg, 10)
        local selectBgSize = selectBg:getContentSize()
        local selectLabel = display.newLabel(10 + display.SAFE_L, selectBgSize.height * 0.5 ,
            {text = __('选择塔可夹'),fontSize = 26, color = '#ffffff',w = 160 , font = TTF_GAME_FONT, ttf = true, outline = '50261d', outlineSize = 2, ap = display.LEFT_CENTER})
        selectBg:addChild(selectLabel)
        local selectLabelSize = display.getLabelContentSize(selectLabel)
        if selectLabelSize.width > 50 then
            selectBgSize = cc.size(254,70)
            selectBg:setContentSize(selectBgSize)
            selectLabel:setPositionY(selectBgSize.height/2)
        end


        local cellSize = cc.size(350, 390)
		local catcherTabsSize = cc.size(display.width, cellSize.height)
        local catcherTabsView = CListView:create(catcherTabsSize)
		catcherTabsView:setDirection(eScrollViewDirectionHorizontal)
		catcherTabsView:setBounceable(false)
		view:addChild(catcherTabsView, 5)
        display.commonUIParams(catcherTabsView, {ap = display.CENTER_BOTTOM, po = cc.p(display.cx, 0)})
        
		return {
            bgView 			= view,
            tabNameLabel    = tabNameLabel,
            shopBtn         = shopBtn,
            backBtn         = backBtn,
            catcherTabsView = catcherTabsView,
		}
	end
	xTry(function()
		self.viewData_ = CreateView()
    end, __G__TRACKBACK__)
    
	local action = cc.EaseBounceOut:create(cc.MoveTo:create(1,cc.p(display.SAFE_L + 130, display.height - 80)))
	self.viewData_.tabNameLabel:runAction( action )
end

function JewelCatcherPoolView:createCatcherTab( ... )
    local args = { ... }
    local catcherData = args[1]
    local cellSize = args[2] or cc.size(350, 390)
    local view = display.newLayer(0, 0, {size = cellSize})
    view:setCascadeOpacityEnabled(true)

    -- 点击的layer
    local clickLayer = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM ,size = cellSize, color = cc.c4b(0,0,0,0) , enable = true })
    view:addChild(clickLayer)
    clickLayer:setTag(123)

    local bgBtn = display.newImageView(GetFullPath('diamond_draw_bg_card_' .. catcherData.showId), cellSize.width - 25, cellSize.height / 2, {ap = display.RIGHT_CENTER})
    bgBtn:setTag(234)
    view:addChild(bgBtn)
    bgBtn:setCascadeOpacityEnabled(true)

    local btnSize = bgBtn:getContentSize()

    local cost = catcherData.oneConsumeGoods[1].goodsId
    local catcherIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(cost)), btnSize.width / 2, btnSize.height - 86, {ap = display.CENTER_TOP})
    bgBtn:addChild(catcherIcon)

    local titleBg = display.newImageView(GetFullPath('diamond_draw_label_card_' .. catcherData.showId)
    , btnSize.width / 2, btnSize.height - 12, {ap = display.CENTER_TOP})
    bgBtn:addChild(titleBg)
    titleBg:setCascadeOpacityEnabled(true)

    local titleSize = titleBg:getContentSize()
    local titleLabel = display.newLabel(titleSize.width / 2, titleSize.height - 30, { w = 270 ,hAlign = display.TAC ,  text = catcherData.name or '', fontSize = 24, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#6f4940', outlineSize = 2})
    titleBg:addChild(titleLabel)

    local ownLabel = display.newLabel(btnSize.width - 26, 136, {text = __('持有'), fontSize = 22, color = '#8f6d53', ap = display.RIGHT_CENTER})
    bgBtn:addChild(ownLabel)

    local cutlineImg = display.newImageView(GetFullPath('diamond_draw_line_1'), btnSize.width - 26, 120, {ap = display.RIGHT_CENTER})
    bgBtn:addChild(cutlineImg)

    local numLabel = CLabelBMFont:create(gameMgr:GetAmountByGoodId(cost), 'font/small/common_text_num.fnt')
    numLabel:setTag(369)
    numLabel:setBMFontSize(30)
    numLabel:setAnchorPoint(cc.p(1, 0.5))
    numLabel:setPosition(cc.p(
    	btnSize.width - 26,
    	100
    ))
    bgBtn:addChild(numLabel)
    numLabel:setTag(checkint(cost))

    local desrLabel = display.newLabel(btnSize.width / 2, 44, {text = catcherData.simpleDescr or '', fontSize = 24, color = '#86574c', hAlign = display.TAC})
    bgBtn:addChild(desrLabel)

    local maskImg = display.newImageView(GetFullPath('diamond_draw_card_bg_mask'), btnSize.width / 2, btnSize.height / 2)
    bgBtn:addChild(maskImg, 10)
    maskImg:setVisible(false)
    view.viewData = {
        numLabel = numLabel
    }
    return view
end

function JewelCatcherPoolView:UpdateCatcherNum()
    local viewData_ = self.viewData_
    local catcherTabsView =  viewData_.catcherTabsView
    local viewTable =  catcherTabsView:getNodes()
    for i = 1, #viewTable do
        local view = viewTable[i]
        local numLabel = view.viewData.numLabel
        local goodsId  = numLabel:getTag()
        numLabel:setString(gameMgr:GetAmountByGoodId(goodsId))
    end
end
return JewelCatcherPoolView