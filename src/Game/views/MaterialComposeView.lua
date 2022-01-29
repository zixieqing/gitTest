--[[
材料合成弹窗
--]]

local GameScene = require( "Frame.GameScene" )

local MaterialComposeView = class('MaterialComposeView', GameScene)
local GoodPurchaseNode = require('common.GoodPurchaseNode')


local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

--[[
--]]
function MaterialComposeView:ctor( ... )

	self.viewData = nil

	local function CloseSelf(sender)
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator("MaterialComposeMediator")
	end

    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)


	local function CreateView()
		local cview = CLayout:create(cc.size(1046,637))
		-- cview:setBackgroundColor(cc.c4b(0, 128, 0, 255))
		local size  = cview:getContentSize()

        local bgSize = cc.size(display.width, 80)
        local moneyNode = CLayout:create(bgSize)
        display.commonUIParams(moneyNode, {ap = display.CENTER_TOP, po = cc.p(display.cx, display.height)})
        self:addChild(moneyNode,100)

        -- top icon
        local imageImage = display.newImageView(_res('ui/home/nmain/main_bg_money.png'),0,0,{enable = false,
        scale9 = true, size = cc.size(680,54)})
        display.commonUIParams(imageImage,{ap = cc.p(1.0,1.0), po = cc.p(display.width,80)})
        moneyNode:addChild(imageImage)
        local moneyNods = {}
        local iconData =  {HP_ID, GOLD_ID, DIAMOND_ID}
        for i,v in ipairs(iconData) do
            local isShowHpTips = (v == HP_ID) and 1 or -1
            local purchaseNode = GoodPurchaseNode.new({id = v, animate = true, isShowHpTips = isShowHpTips})
            display.commonUIParams(purchaseNode,
            {ap = cc.p(1, 0.5), po = cc.p(bgSize.width - 20 - (( table.nums(iconData) - i) * (purchaseNode:getContentSize().width + 16)), imageImage:getPositionY()- 26)})
            moneyNode:addChild(purchaseNode, 5)
            purchaseNode:setName('purchaseNode' .. i)
            purchaseNode.viewData.touchBg:setTag(checkint(v))
            moneyNods[tostring( v )] = purchaseNode
        end




	    display.commonUIParams(cview, {ap = display.CENTER, po = cc.p(display.size.width * 0.5, display.size.height * 0.5)})
	    self:addChild(cview, 10)

	    local bg = display.newImageView(_res("ui/home/story/task_bg.png"), size.width* 0.5 - 20, size.height* 0.5)
	    cview:addChild(bg)


        local closeBtn = display.newButton(size.width, size.height, {n = _res('ui/home/story/task_btn_quit.png')})
	    display.commonUIParams(closeBtn, {ap = display.RIGHT_TOP,po = cc.p(size.width + 36, size.height - 28)})
	    cview:addChild(closeBtn,10)


		local tabNameLabel = display.newButton( 180, 570,{n = _res('ui/home/story/task_bg_title.png'),enable = false,ap = cc.p(0, 0)})
		display.commonLabelParams(tabNameLabel, {text = __('材料合成'), fontSize = 26, color = '662f2f',offset = cc.p(-40,0)})
		cview:addChild(tabNameLabel)

		local messLayout = CLayout:create(cc.size(444,540))
		messLayout:setAnchorPoint(cc.p(0,0))
		messLayout:setPosition(cc.p(521,60))
		cview:addChild(messLayout)
		-- messLayout:setBackgroundColor(cc.c4b(0, 100, 0, 100))

		local nameLabel = display.newButton( messLayout:getContentSize().width*0.5, 540,{n = _res('ui/common/common_title_5.png'),enable = false,ap = cc.p(0.5, 1), scale9 = true, size = cc.size(186,32)})
		display.commonLabelParams(nameLabel,fontWithColor(4,{text = __('名字')}))
		messLayout:addChild(nameLabel)



 		local line1 = display.newImageView(_res('ui/backpack/materialCompose/item_compose_split_line.png'),
 			messLayout:getContentSize().width*0.5, 500)
		display.commonUIParams(line1, {ap = cc.p(0.5,0.5)})
		messLayout:addChild(line1)

 		local fazhenBg = display.newImageView(_res('ui/home/teamformation/concertSkillMess/biandui_lianxieskill_fazheng.png'),
 			messLayout:getContentSize().width*0.5, messLayout:getContentSize().height*0.51)
		display.commonUIParams(fazhenBg, {ap = cc.p(0.5,0.5)})
		messLayout:addChild(fazhenBg)

		local needMaterialNode = require('home.BackpackCell').new()
	    needMaterialNode:setPosition(cc.p(messLayout:getContentSize().width*0.5,490))
		needMaterialNode:setAnchorPoint(cc.p(0.5,1))
		needMaterialNode:setScale(0.8)
		messLayout:addChild(needMaterialNode)


 		local arrowImg = display.newImageView(_res('ui/cards/skillNew/card_skill_ico_sword.png'),
 			messLayout:getContentSize().width*0.5, 360)
 		arrowImg:setRotation(90)
		display.commonUIParams(arrowImg, {ap = cc.p(0.5,0.5)})
		messLayout:addChild(arrowImg,1)

		local targetMaterialNode = require('home.BackpackCell').new()
	    targetMaterialNode:setPosition(cc.p(messLayout:getContentSize().width*0.5,messLayout:getContentSize().height*0.5))
		targetMaterialNode:setAnchorPoint(cc.p(0.5,0.5))
		messLayout:addChild(targetMaterialNode)

		local targetNum = display.newLabel(messLayout:getContentSize().width*0.5, messLayout:getContentSize().height*0.5 - targetMaterialNode:getContentSize().height* 0.5 - 8,
			{text = '', fontSize = 20, color = '#5c5c5c'})
		messLayout:addChild(targetNum, 11)


		--选择数量
		local btn_num = display.newButton(0, 0, {n = _res('ui/home/market/market_buy_bg_info.png'),scale9 = true, size = cc.size(180, 44)})
		display.commonUIParams(btn_num, {po = cc.p(messLayout:getContentSize().width*0.5, 108),ap = cc.p(0.5,0)})
		display.commonLabelParams(btn_num, {text = '0', fontSize = 28, color = '#7c7c7c'})
		messLayout:addChild(btn_num)

		--减号btn
		local btn_minus = display.newButton(0, 0, {n = _res('ui/home/market/market_sold_btn_sub.png')})
		display.commonUIParams(btn_minus, {po = cc.p(messLayout:getContentSize().width*0.5 - 90, 103),ap = cc.p(0.5,0)})
		messLayout:addChild(btn_minus)
		btn_minus:setTag(1)

		--加号btn
	    local btn_add = display.newButton(0, 0, {n = _res('ui/home/market/market_sold_btn_plus.png')})
		display.commonUIParams(btn_add, {po = cc.p(messLayout:getContentSize().width*0.5 + 90, 103),ap = cc.p(0.5,0)})
		messLayout:addChild(btn_add)
		btn_add:setTag(2)


		local line2 = display.newImageView(_res('ui/backpack/materialCompose/item_compose_split_line.png'),
 			messLayout:getContentSize().width*0.5, 80)
		line2:setFlippedY(true)
		display.commonUIParams(line2, {ap = cc.p(0.5,0.5)})
		messLayout:addChild(line2)


		local composeBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_orange.png")})
		display.commonUIParams(composeBtn, {ap = cc.p(0,0), po = cc.p(260,2)})
		display.commonLabelParams(composeBtn,fontWithColor(14,{text = __('合成')}))
		messLayout:addChild(composeBtn,4)


		local tempImg = display.newImageView(_res('ui/common/commcon_bg_text.png'),65,8,{ap = cc.p(0,0),scale9 = true,size = cc.size(200,50) })
		messLayout:addChild(tempImg,3)

		local castNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')--
	    castNum:setAnchorPoint(cc.p(1, 0))
	    castNum:setHorizontalAlignment(display.TAR)
	    castNum:setPosition(205,15)
	    messLayout:addChild(castNum,4)
	    castNum:setString('0')

	    local goldIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)), 245, 15)
		goldIcon:setScale(0.25)
		goldIcon:setAnchorPoint(cc.p(1, 0))
		messLayout:addChild(goldIcon, 5)

		local listLayout = CLayout:create()
		listLayout:setAnchorPoint(cc.p(0,0))
		listLayout:setPosition(cc.p(55,60))
		cview:addChild(listLayout)
		-- listLayout:setBackgroundColor(cc.c4b(0, 100, 0, 255))


		--滑动层背景图
		local ListBg = display.newImageView(_res('ui/home/story/commcon_bg_text.png'), 0,0,
		{ap = cc.p(0, 0)})
		listLayout:setContentSize(ListBg:getContentSize())
		listLayout:addChild(ListBg)

		local ListBgFrameSize = ListBg:getContentSize()
		-- 添加列表功能
		local taskListSize = cc.size(ListBgFrameSize.width - 2 , ListBgFrameSize.height - 2)

		local listView = CListView:create(taskListSize)
		listView:setDirection(eScrollViewDirectionVertical)
		listView:setBounceable(true)
		listLayout:addChild(listView)
		listView:setAnchorPoint(cc.p(0, 0))
		listView:setPosition(cc.p(ListBg:getPositionX() + 1, ListBg:getPositionY()  + 1))
		-- listView:setBackgroundColor(cc.c4b(0, 128, 0, 100))

		return {
			view = cview,
			listView 			= listView,
			messLayout 			= messLayout,
			closeBtn 			= closeBtn,

			nameLabel 			= nameLabel,
			needMaterialNode 	= needMaterialNode,
			targetMaterialNode	= targetMaterialNode,
			targetNum 			= targetNum,
			btn_num				= btn_num,
			btn_minus			= btn_minus,
			btn_add				= btn_add,
			composeBtn			= composeBtn,
			castNum				= castNum,
			moneyNods 			= moneyNods,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
		self.viewData.closeBtn:setOnClickScriptHandler(CloseSelf)

	end, __G__TRACKBACK__)

end



return MaterialComposeView
