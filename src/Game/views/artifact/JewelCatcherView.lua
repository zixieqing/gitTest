--[[
	宝石抽取UI
--]]
local GameScene = require( "Frame.GameScene" )

local JewelCatcherView = class('JewelCatcherView', GameScene)

local function GetFullPath( imgName )
	return _res('ui/artifact/' .. imgName)
end

function JewelCatcherView:ctor( ... )
    local args = unpack({ ... })
	--创建页面
	-- local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
    -- eaterLayer:setTouchEnabled(true)
    -- eaterLayer:setContentSize(display.size)
    -- eaterLayer:setPosition(cc.p(display.cx, display.cy))
    -- self:addChild(eaterLayer, -1)
	local function CreateView( ... )
		local view = display.newLayer(display.cx, display.height, {size = display.size, ap = display.CENTER_TOP})
		self:addChild(view)

        -- local bg = display.newImageView(GetFullPath('diamond_draw_bg'), display.cx, display.cy, {isFull = true})
        -- view:addChild(bg)

        -- local tabNameLabel = display.newButton(
        --     display.SAFE_L + 130,
        --     display.height - 80,
        --     {n = _res('ui/common/common_title_new.png'),enable = false,ap = cc.p(0, 0)})
        -- display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('塔可转转乐'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        -- view:addChild(tabNameLabel)
    
	    -- 商店
        local shopBtn = display.newButton(display.SAFE_R - 50, display.height - 50, {n = _res('ui/home/nmain/main_btn_shop.png')})
        shopBtn:setScale(1.2)
	    view:addChild(shopBtn, 10)
        display.commonLabelParams(shopBtn, fontWithColor('14', {text = __('购买'), outline = '#6a4d47', outlineSize = 1, offset = {y = -16}, tag = 123}))
        shopBtn:getChildByTag(123):setScale(1.0 / 1.2)
    
        -- 返回按钮
        local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png"), cb = function (sender)
            PlayAudioByClickClose()
            AppFacade.GetInstance():UnRegsitMediator("JewelCatcherMediator")
        end})
        display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
        view:addChild(backBtn, 21)

        -- local cageImg = display.newImageView(GetFullPath('zhuanlundi'), display.cx, display.cy + 40)
        -- view:addChild(cageImg)

        -- local mouseSpine = sp.SkeletonAnimation:create(
        --     'effects/artifact/zhuanpan.json',
        --     'effects/artifact/zhuanpan.atlas',
        --     1)
        -- mouseSpine:setPosition(cc.p(display.cx, display.cy + 48))
        -- view:addChild(mouseSpine)
        -- mouseSpine:setAnimation(0, 'idle', true)
        -- mouseSpine:update(0)
        -- mouseSpine:setToSetupPose()

        -- local coverImg = display.newImageView(GetFullPath('zhuanlunqian'), display.cx, display.cy + 48)
        -- view:addChild(coverImg)

        local designSize = cc.size(1334, 750)
        local winSize = display.size
        local deltaHeight = (winSize.height - designSize.height) * 0.5

        local cost = args.tenConsumeGoods[1]
        local catherType = '890017'
        if utils.isExistent('effects/artifact/' .. tostring(cost.goodsId) .. '.json') then
            catherType = tostring(cost.goodsId)
        end

        local catcherSpine = sp.SkeletonAnimation:create(
            'effects/artifact/' .. catherType .. '.json',
            'effects/artifact/' .. catherType .. '.atlas',
            1)
        catcherSpine:setPosition(cc.p(display.cx, display.height - deltaHeight - 220))
        view:addChild(catcherSpine)
        catcherSpine:setAnimation(0, 'idle', true)
        catcherSpine:update(0)
        catcherSpine:setToSetupPose()

        view:addChild(display.newImageView(_res('avatar/ui/decorate_bg_down.png'), display.width/2, 0, {ap = display.CENTER_BOTTOM, scale9 = true, size = cc.size(display.width, 110)}))

        -- 抓10次
        local buttonSpine = sp.SkeletonAnimation:create(
            'effects/artifact/anniu.json',
            'effects/artifact/anniu.atlas',
            1)
        buttonSpine:setPosition(cc.p(display.SAFE_L + 196, 138))
        view:addChild(buttonSpine)
        buttonSpine:setAnimation(0, 'idle', true)
        buttonSpine:update(0)
        buttonSpine:setToSetupPose()
        buttonSpine:setScaleX(-1)

        local tenBtn = display.newButton(display.SAFE_L + 197, 139, {n = GetFullPath('diamond_draw_btn_ten')})
        view:addChild(tenBtn)
        -- display.commonLabelParams(tenBtn, {ttf = true, font = TTF_GAME_FONT, text = __('抓10次'), fontSize = 36, color = 'ffffff',outlineszie = 2, outline = '6a4d47'})
        tenBtn:setTag(2)
        
        local tenCostBg = display.newImageView(GetFullPath('diamond_draw_label_cost'), display.SAFE_L + 192, 25)
        view:addChild(tenCostBg)

        local tenLabel = display.newLabel(tenCostBg:getContentSize().width / 2, tenCostBg:getContentSize().height / 2, 
            fontWithColor(19, {text = __('抓10次'), outline = '#3c2621'}))
            tenCostBg:addChild(tenLabel)

        local tenCostLabel = CLabelBMFont:create(cost.num, 'font/small/common_text_num.fnt')
        tenCostLabel:setBMFontSize(40)
	    tenCostBg:addChild(tenCostLabel)

	    local tenCostIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(cost.goodsId)), 0, 0)
	    tenCostIcon:setScale(0.4)
        tenCostBg:addChild(tenCostIcon)

	    display.setNodesToNodeOnCenter(tenBtn, {tenCostLabel, tenCostIcon}, {})
    
        -- 抓1次
        local buttonSpine = sp.SkeletonAnimation:create(
            'effects/artifact/anniu.json',
            'effects/artifact/anniu.atlas',
            1)
        buttonSpine:setPosition(cc.p(display.SAFE_R - 196, 138))
        view:addChild(buttonSpine)
        buttonSpine:setAnimation(0, 'idle', true)
        buttonSpine:update(0)
        buttonSpine:setToSetupPose()

        local oneBtn = display.newButton(display.SAFE_R - 197, 139, {n = GetFullPath('diamond_draw_btn_one')})
        view:addChild(oneBtn)
        -- display.commonLabelParams(oneBtn, {ttf = true, font = TTF_GAME_FONT, text = __('抓1次'), fontSize = 36, color = 'ffffff',outlineszie = 2, outline = '6a4d47'})
        oneBtn:setTag(1)
        
        local oneCostBg = display.newImageView(GetFullPath('diamond_draw_label_cost'), display.SAFE_R - 192, 25)
        view:addChild(oneCostBg)

        local oneLabel = display.newLabel(oneCostBg:getContentSize().width / 2, oneCostBg:getContentSize().height / 2, 
            fontWithColor(19, {text = __('抓1次'), outline = '#3c2621'}))
        oneCostBg:addChild(oneLabel)

        local cost = args.oneConsumeGoods[1]
        local oneCostLabel = CLabelBMFont:create(cost.num, 'font/small/common_text_num.fnt')
        oneCostLabel:setBMFontSize(40)
	    oneCostBg:addChild(oneCostLabel)

	    local oneCostIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(cost.goodsId)), 0, 0)
	    oneCostIcon:setScale(0.4)
        oneCostBg:addChild(oneCostIcon)

	    display.setNodesToNodeOnCenter(oneBtn, {oneCostLabel, oneCostIcon}, {})
    
        -- 必出
        local alwaysBg = display.newImageView(GetFullPath('diamond_draw_label_protect'), display.SAFE_L, 290, {ap = display.LEFT_CENTER})
        view:addChild(alwaysBg)

        local alwaysLabel = display.newLabel(100, 74, {text = args.complexDescr, w = 250 ,reqW = 220 , ap = display.LEFT_CENTER,  fontSize = 24, color = '#ffffff', hAlign = display.TAC})
        alwaysBg:addChild(alwaysLabel)

        local alwaysSpine = sp.SkeletonAnimation:create(
            'effects/artifact/biaoqian.json',
            'effects/artifact/biaoqian.atlas',
            1)
        alwaysSpine:setPosition(cc.p(210, 66))
        alwaysBg:addChild(alwaysSpine)
        alwaysSpine:setAnimation(0, 'idle', true)
        alwaysSpine:update(0)
        alwaysSpine:setToSetupPose()

        -- name
        local nameBg = display.newImageView(GetFullPath('diamond_draw_label_name'), display.cx, 70)
        view:addChild(nameBg)

		local ruleBtn = display.newButton(display.cx - 120, 70, {n = _res('ui/common/common_btn_tips.png')})
        view:addChild(ruleBtn)
        local nameLabel = display.newLabel(display.cx, 70, 
            fontWithColor('14', {ap = display.CENTER ,   text = args.name, fontSize = 32, reqW = 200 ,  color = '#ffffff', outline = '#6a4d47'}  ) )
        view:addChild(nameLabel)

        local cutlineImg = display.newImageView(GetFullPath('diamond_draw_line_2'), display.cx, 44)
        view:addChild(cutlineImg)

        local desrLabel = display.newLabel(display.cx, 24, {text = args.simpleDescr, fontSize = 22, color = '#623737'})
        view:addChild(desrLabel)

        -- 拥有数量
        local ownBg = display.newImageView(GetFullPath('diamond_draw_label_num'), display.width, display.height - 50, {ap = display.RIGHT_CENTER})
        view:addChild(ownBg)

        local cost = args.oneConsumeGoods[1].goodsId
        local ownLabel = CLabelBMFont:create('', 'font/small/common_text_num.fnt')
        display.commonUIParams(ownLabel,{
            ap = cc.p(1, 0.5),
            po = cc.p(display.SAFE_R - 140, display.height - 50)
        })
        ownLabel:setBMFontSize(30)
	    view:addChild(ownLabel)

	    local ownIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(cost)), 0, 0)
        display.commonUIParams(ownIcon,{
            po = cc.p(display.SAFE_R - 120, display.height - 50)
        })
	    ownIcon:setScale(0.25)
        view:addChild(ownIcon)

        local addView = CColorView:create(cc.r4b(0))
        addView:setContentSize(ownBg:getContentSize())
        addView:setTouchEnabled(true)
        view:addChild(addView)
        display.commonUIParams(addView, {ap = display.RIGHT_CENTER, po = cc.p(display.width, display.height - 50), animate = true, cb = function (  )
            PlayAudioByClickNormal()
            app.uiMgr:AddDialog("common.GainPopup", {goodId = cost})
        end})

		return {
            bgView 			= view,
            tabNameLabel    = tabNameLabel,
            shopBtn         = shopBtn,
            backBtn         = backBtn,
            tenBtn          = tenBtn,
            oneBtn          = oneBtn,
            ruleBtn         = ruleBtn,
            ownLabel        = ownLabel,
            mouseSpine      = mouseSpine,
            catcherSpine    = catcherSpine,
		}
	end
	xTry(function()
		self.viewData_ = CreateView()
    end, __G__TRACKBACK__)
end

return JewelCatcherView