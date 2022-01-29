--[[
大堂做菜ui
--]]
local GameScene = require( "Frame.GameScene" )

local LobbyCookingView = class('LobbyCookingView', GameScene)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

--[[
--]]
function LobbyCookingView:ctor( ... )

	self.viewData = nil
	self.eaterLayer = nil
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
	self:addChild(eaterLayer,1)
	self.eaterLayer = eaterLayer

	-- view:setBackgroundColor(cc.c4b(100, 100, 100, 255))
	-- view:setScale(0.96)

	local function CreateView()
		local cview = CLayout:create(display.size)
		-- cview:setBackgroundColor(cc.c4b(0, 128, 0, 255))
		local size  = display.size
		cview:setName('cview')
	    display.commonUIParams(cview, {ap = display.CENTER, po = cc.p(display.size.width * 0.5, display.size.height * 0.5)})
	    self:addChild(cview, 10)

	    local bg = display.newImageView(_res("ui/home/lobby/cooking/restaurant_kitchen_ico_table.png"), size.width* 0.5 ,0)
	    bg:setAnchorPoint(cc.p(0.5,0))
	    cview:addChild(bg)

		local closeBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
		display.commonUIParams(closeBtn, {po = cc.p(display.SAFE_L + closeBtn:getContentSize().width * 0.5 + 30,display.size.height - 18 - closeBtn:getContentSize().height * 0.5)})
		cview:addChild(closeBtn, 5)
		closeBtn:setName('closeBtn')

		--cookLayout 厨师做菜区域
		local cookLayout = CLayout:create(cc.size(686,display.size.height))
		cookLayout:setAnchorPoint(cc.p(0,0))
		cookLayout:setPosition(cc.p(display.cx - 667,0))
		cview:addChild(cookLayout,1)
		-- cookLayout:setBackgroundColor(cc.c4b(0, 128, 0, 100))

		local fireImg = display.newImageView(_res("ui/home/lobby/cooking/restaurant_kitchen_ico_fire.png"), 286, 50, {ap = cc.p(0, 0)})
		cookLayout:addChild(fireImg)
		cookLayout:setName('cookLayout')

		local cooks = {}
		for i=1,2 do
			local t = {}
			local bSize = cc.size(250,display.size.height)
			local tempLayout = CLayout:create(bSize)
			tempLayout:setAnchorPoint(cc.p(0,0.5))
			tempLayout:setPosition(cc.p( 90+330*(i-1),display.size.height*0.5))
			cookLayout:addChild(tempLayout,10)
			-- tempLayout:setBackgroundColor(cc.c4b(0, 128, 0, 100))
			tempLayout:setName('cooktempLayout')

			local timeBtn = display.newButton(bSize.width*0.5,  160,
				{n = _res('ui/home/lobby/cooking/kitchen_make_bg_info.png'),enable = false,scale9 = true,size = cc.size(122,30)})
			tempLayout:addChild(timeBtn)
			display.commonLabelParams(timeBtn,{text = ' ', fontSize = 20, color = '#4c4c4c'})

			local buyBtn = display.newButton(bSize.width*0.5,  110,
				{n = _res('ui/common/common_btn_green.png')})
			tempLayout:addChild(buyBtn)
			display.commonLabelParams(buyBtn,{text = ' ', fontSize = 24, color = '#ffffff'})
			buyBtn:setName('buyBtn_'..i)

			local tempImg = display.newImageView(_res("ui/home/lobby/cooking/refresh_ico_quick_recovery.png"),20, 31,--
			{ap = cc.p(0.5, 0.5)})
			buyBtn:addChild(tempImg)

			local timeImg = display.newImageView(_res("ui/home/nmain/restaurant_kitchen_ico_making.png"),
			 bSize.width*0.18, 160,--
			{ap = cc.p(0.5, 0.5)})
			tempLayout:addChild(timeImg)

			local tempImg1 = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)),120, 31,--
			{ap = cc.p(1, 0.5)})
			buyBtn:addChild(tempImg1)
			tempImg1:setScale(0.2)


			--灶台按钮
			local stoveBtn = display.newButton(bSize.width*0.5,  248,
				{n = _res('ui/home/lobby/cooking/restaurant_kitchen_btn_start_cook.png')})--s = _res('ui/home/lobby/cooking/restaurant_kitchen_btn_start_cook.png')
			tempLayout:addChild(stoveBtn)
			stoveBtn:setName('stoveBtn_'..i)

			local bowlQBg = display.newImageView(_res('ui/common/comon_bg_frame_gey.png'), 0, 0, {scale9 = true, size = cc.size(60,60)})
			display.commonUIParams(bowlQBg, {ap = cc.p(0.5, 0), po = cc.p(106, 32)})
			bowlQBg:setOpacity(0)
			bowlQBg:setCascadeOpacityEnabled(true)
			stoveBtn:addChild(bowlQBg)

			-- stoveBtn:setNormalImage(_res('ui/home/lobby/cooking/restaurant_kitchen_btn_active.png'))

			--q版立绘
			local qBg = display.newImageView(_res('ui/common/comon_bg_frame_gey.png'), 0, 0, {scale9 = true, size = cc.size(157,161)})
			display.commonUIParams(qBg, {ap = cc.p(0.5, 0), po = cc.p(display.cx - 447 + 330*(i-1) ,294)})
			cview:addChild(qBg,-1)
			qBg:setOpacity(0)
			qBg:setCascadeOpacityEnabled(true)


			local qExpressionBg = display.newImageView(_res('ui/common/comon_bg_frame_gey.png'), 0, 0, {scale9 = true, size = cc.size(157,161)})
			display.commonUIParams(qExpressionBg, {ap = cc.p(0.5, 0), po = cc.p(bSize.width*0.65 ,404)})
			tempLayout:addChild(qExpressionBg)
			qExpressionBg:setOpacity(0)
			qExpressionBg:setCascadeOpacityEnabled(true)
			-- qExpressionBg:setVisible(false)
			local expressionAvatar = sp.SkeletonAnimation:create('avatar/animate/common_ico_expression_6.json', 'avatar/animate/common_ico_expression_6.atlas', 1)
		    expressionAvatar:update(0)
		    expressionAvatar:setTag(1)
		    expressionAvatar:setAnimation(0, 'idle', true)
		    expressionAvatar:setPosition(cc.p(qExpressionBg:getContentSize().width * 0.5,qExpressionBg:getContentSize().height * 0.5))
		    qExpressionBg:addChild(expressionAvatar)


			local speakBtn = display.newButton(bSize.width*0.5,  630,
				{n = _res('ui/home/lobby/cooking/common_ico_expression_1.png'), enable = false})
			tempLayout:addChild(speakBtn,1)
			display.commonLabelParams(speakBtn,{text = (' '), fontSize = 20, color = '#5c5c5c',hAlign = cc.TEXT_ALIGNMENT_CENTER,offset = cc.p(0,0),w = 250,h = 50})


		    --顶部显示正在制作菜谱区域
		    local tsize = cc.size(300,170)
			local nowCookRecipeLayout = CLayout:create(tsize)
			nowCookRecipeLayout:setAnchorPoint(cc.p(0.5,1))
			nowCookRecipeLayout:setPosition(cc.p(bSize.width*0.5, display.size.height))
			tempLayout:addChild(nowCookRecipeLayout)
			-- nowCookRecipeLayout:setBackgroundColor(cc.c4b(0, 128, 0, 255))

			local tempImg = display.newImageView(_res("ui/home/lobby/cooking/restaurant_bg_board.png"),0, tsize.height*0.5,--
			{ap = cc.p(0, 0.5)})
			nowCookRecipeLayout:addChild(tempImg)

			----顶部显示正在制作菜谱icon
			local nowCookImg = display.newImageView(CommonUtils.GetGoodsIconPathById(150066+i),121, 180,--
			{ap = cc.p(0.5, 1)})
			nowCookImg:setScale(0.8)
			nowCookRecipeLayout:addChild(nowCookImg)
			--顶部显示正在制作菜谱数量

			local nowCookNumBtn = display.newButton(121,  70,
				{n = _res('ui/common/common_bg_number_1.png')})
			nowCookRecipeLayout:addChild(nowCookNumBtn,1)
			display.commonLabelParams(nowCookNumBtn,{text = '30'..i, fontSize = 20, color = '#ffffff'})

			--顶部显示正在制作菜谱名字
	        local nowCookNameLabel = display.newLabel( 121, 25,{
	            ap = cc.p(0.5,0), fontSize = fontWithColor('18').fontSize , color = fontWithColor('18').color, text = " "
	        })
	        nowCookRecipeLayout:addChild(nowCookNameLabel)


	        --取消正在制作按钮
			local nowCookCloseBtn = display.newButton(0, 0, {n = _res("ui/home/lobby/cooking/restaurant_kitchen_btn_delete_dish.png")})
			display.commonUIParams(nowCookCloseBtn, {po = cc.p(tsize.width - 20 ,tsize.height * 0.75),ap = cc.p(1,0.5)})
			nowCookRecipeLayout:addChild(nowCookCloseBtn, 2)

			t = {
				timeBtn = timeBtn,
				buyBtn = buyBtn,
				timeImg = timeImg,
				stoveBtn =stoveBtn,
				bowlQBg = bowlQBg,
				qBg = qBg,
				nowCookRecipeLayout = nowCookRecipeLayout,
				nowCookImg = nowCookImg,
				nowCookNumBtn = nowCookNumBtn,
				nowCookNameLabel = nowCookNameLabel,
				nowCookCloseBtn = nowCookCloseBtn,
				cooksIndex = i + 1,
				speakBtn = speakBtn,
				qExpressionBg = qExpressionBg,
			}
			table.insert(cooks,t)
		end

		--已制作好菜品区域
		local recipeLayout = CLayout:create(cc.size(660,display.size.height))
		recipeLayout:setAnchorPoint(cc.p(0,0))
		recipeLayout:setPosition(cc.p(display.cx + 19,0))
		cview:addChild(recipeLayout,1)
		-- recipeLayout:setBackgroundColor(cc.c4b(100, 100, 100, 100))
		recipeLayout:setName('recipeLayout')
		local showCooks = {}
		local buttons = {}
		for i=1,4 do
			--桌布
			local tempBtn = display.newButton(90 + 130*(i-1),  204,
				{n = _res('ui/home/lobby/cooking/restaurant_kitchen_ico_dish_default.png')})--s = _res('ui/home/lobby/cooking/restaurant_kitchen_btn_start_cook.png')
			recipeLayout:addChild(tempBtn)
			tempBtn:setTag(i)
			table.insert(buttons,tempBtn)
			tempBtn:setName('tableImg_'..i)

			--显示菜谱icon和数量区域
		    local tsize = cc.size(100,160)
			local cookRecipeLayout = CLayout:create(tsize)
			cookRecipeLayout:setAnchorPoint(cc.p(0.5,0.5))
			cookRecipeLayout:setPosition(cc.p(90 + 130*(i-1),  204))
			recipeLayout:addChild(cookRecipeLayout)
			-- cookRecipeLayout:setBackgroundColor(cc.c4b(100, 100, 100, 100))

			--阴影
			local tempImg = display.newImageView(_res("ui/home/lobby/cooking/restaurant_kitchen_ico_dish_shardow.png"),tsize.width * 0.5,  90,--
			{ap = cc.p(0.5, 0.5)})
			cookRecipeLayout:addChild(tempImg,1)
			tempImg:setTag(3)
			tempImg:setVisible(false)
			--菜谱icon
			local img = display.newImageView(CommonUtils.GetGoodsIconPathById(150060),tsize.width * 0.5,  120,--
			{ap = cc.p(0.5, 0.5)})
			img:setScale(0.8)
			cookRecipeLayout:addChild(img,2)
			img:setTag(1)
			img:setVisible(false)
			--数量
			local tempBtn = display.newButton(tsize.width * 0.5,  20,
				{n = _res('ui/common/common_bg_number_1.png'),enable = false})
			cookRecipeLayout:addChild(tempBtn,1)
			display.commonLabelParams(tempBtn,{text = '30'..i, fontSize = 20, color = '#ffffff'})
			tempBtn:setTag(2)
			tempBtn:setVisible(false)
			table.insert(showCooks,cookRecipeLayout)
		end

		--点击菜谱后显示详情区域
	    local tsize = cc.size(370,325)
		local recipeMessLayout = CLayout:create(tsize)
		recipeMessLayout:setAnchorPoint(cc.p(0.5,0))
		recipeMessLayout:setPosition(cc.p(350,260))
		recipeLayout:addChild(recipeMessLayout,-1)
		recipeMessLayout:setVisible(false)
        -- recipeMessLayout:setBackgroundColor(cc.c4b(100, 100, 100, 100))

		local TrecipeMess = {}
		local lightImg = display.newImageView(_res("ui/home/lobby/cooking/restaurant_kitchen_bg_dish_info.png"),tsize.width * 0.5,  0,--
		{ap = cc.p(0.5, 0)})
		recipeMessLayout:addChild(lightImg,1)

		--信息框
		local messImg = display.newImageView(_res("ui/common/common_bg_tips.png"),tsize.width * 0.5,  tsize.height,--
		{ap = cc.p(0.5, 1)})
		recipeMessLayout:addChild(messImg,1)

		--取消已制作好的菜谱
		local cancelBtn = display.newButton(0, 0, {n = _res("ui/home/lobby/cooking/restaurant_kitchen_btn_delete_dish.png")})
		display.commonUIParams(cancelBtn, {po = cc.p(tsize.width * 0.5 ,58),ap = cc.p(0.5,0.5)})
		recipeMessLayout:addChild(cancelBtn,2)

		--详情菜谱icon
		local recipeFrame = display.newImageView(_res("ui/common/common_frame_goods_5.png"),15,89,--
		{ap = cc.p(0, 0)})
		recipeFrame:setScale(0.8)
		messImg:addChild(recipeFrame,1)

		local recipeImg = display.newImageView(_res("ui/common/common_frame_goods_5.png"),recipeFrame:getContentSize().width*0.5,recipeFrame:getContentSize().height*0.5,--
		{ap = cc.p(0.5, 0.5)})
		recipeImg:setScale(0.6)
		recipeFrame:addChild(recipeImg,1)

		--详情菜谱名字
        local nameLabel = display.newLabel( 115, 152,{
            ap = cc.p(0,0), fontSize = fontWithColor('11').fontSize , color = fontWithColor('11').color, text = " "
        })
        messImg:addChild(nameLabel)


        --餐厅单价
        local tempLabel = display.newLabel( 115, 122,{
            ap = cc.p(0,0), fontSize = fontWithColor('11').fontSize , color = '5c5c5c', text = __("餐厅单价：")
        })
        messImg:addChild(tempLabel)


		local priceLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
		display.commonUIParams(priceLabel, {ap = cc.p(1,0)})
		priceLabel:setPosition(cc.p(messImg:getContentSize().width-50, 120))
		messImg:addChild(priceLabel,1)


		local tempImg = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)),messImg:getContentSize().width-20,122,--
		{ap = cc.p(1, 0)})
		tempImg:setScale(0.2)
		messImg:addChild(tempImg,1)

        --用餐时间
        local tempLabel = display.newLabel( 115, 92,{
            ap = cc.p(0,0), fontSize = fontWithColor('11').fontSize , color = '5c5c5c', text = __("用餐时间：")
        })
        messImg:addChild(tempLabel)



        local tempLabel = display.newLabel( messImg:getContentSize().width-20,92,{
            ap = cc.p(1,0), fontSize = fontWithColor('11').fontSize , color = '5c5c5c', text = __("秒/份")
        })
        messImg:addChild(tempLabel)
        local lwidth = display.getLabelContentSize(tempLabel).width
        local diningTimeLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
        display.commonUIParams(diningTimeLabel, {ap = cc.p(1,0)})
        diningTimeLabel:setPosition(cc.p(messImg:getContentSize().width-20 - lwidth - 4, 90))
        messImg:addChild(diningTimeLabel,1)



        --知名度
        local tempLabel = display.newLabel( 115, 62,{
            ap = cc.p(0,0), fontSize = fontWithColor('11').fontSize , color = '5c5c5c', text = __("知名度：")
        })
        messImg:addChild(tempLabel)

		local profileLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
		display.commonUIParams(profileLabel, {ap = cc.p(1,0)})
		profileLabel:setPosition(cc.p(messImg:getContentSize().width-50, 60))
		messImg:addChild(profileLabel,1)


		local tempImg = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(POPULARITY_ID)),messImg:getContentSize().width-20,62,--
		{ap = cc.p(1, 0)})
		tempImg:setScale(0.2)
		messImg:addChild(tempImg,1)


		local bgImg = display.newImageView(_res("ui/home/lobby/cooking/restaurant_kitchen_bg_tips.png"),tsize.width*0.5 - 4,3,--
		{ap = cc.p(0.5, 0)})
		messImg:addChild(bgImg)

		for i=1,3 do
			local splitLine = display.newNSprite(_res('ui/pet/pet_info_ico_attribute_line.png'), 0, 0,
				{scale9 = true,size =cc.size(228,2),ap = cc.p(0,0)})
			display.commonUIParams(splitLine, {po = cc.p(
				115,
				122 - (i-1)*30
			)})
			messImg:addChild(splitLine)
		end

        --
     --    local tconfig = {
     --    	'味道','口感','香气','外观'
    	-- }
		local tconfig = {__('味道'),__('口感'),__('香味'),__('外观')}
		local keyconfig = {'taste','museFeel','fragrance','exterior'}
    	local Tlabel = {}
    	for i,v in ipairs(tconfig) do
	        local tempLabel = display.newLabel( 33 + 90*(i-1), 32,{
	            ap = cc.p(0.5,0), fontSize = fontWithColor('16').fontSize , color = fontWithColor('16').color, text = tconfig[i]
	        })
	        messImg:addChild(tempLabel,1)

	        -- local numLabel = display.newLabel( 53 + 88*(i-1), 10,{
	        --     ap = cc.p(0.5,0), fontSize = fontWithColor('11').fontSize , color = fontWithColor('11').color, text = tostring(i)
	        -- })
	        -- messImg:addChild(numLabel,1)

			local numLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
			display.commonUIParams(numLabel, {ap = cc.p(0.5,0)})
			numLabel:setPosition(cc.p(33+ 90*(i-1), 0))
			-- numLabel:setScale(0.6)
			messImg:addChild(numLabel,1)

	        Tlabel[tostring(keyconfig[i])] = numLabel
	        -- table.insert(Tlabel,numLabel)
    	end

    	TrecipeMess.cancelBtn = cancelBtn
    	TrecipeMess.recipeImg = recipeImg
    	TrecipeMess.nameLabel = nameLabel
    	TrecipeMess.priceLabel =  priceLabel
    	TrecipeMess.diningTimeLabel = diningTimeLabel
    	TrecipeMess.profileLabel = profileLabel
    	TrecipeMess.Tlabel = Tlabel


		local emptyRecipeBtn = display.newButton(520,  70,
			{n = _res('ui/common/common_btn_orange.png') ,scale9 = true })
		recipeLayout:addChild(emptyRecipeBtn)
		display.commonLabelParams(emptyRecipeBtn,fontWithColor("14",{text = __('清空菜品')  ,w = 120 ,hAlign = display.TAC}))
		local emptyRecipeBtnSize = emptyRecipeBtn:getContentSize()
		local emptyRecipeBtnLabelSize = display.getLabelContentSize(emptyRecipeBtn:getLabel())
		if emptyRecipeBtnLabelSize.height + 10 > emptyRecipeBtnSize.height  then
			emptyRecipeBtn:setContentSize(cc.size(emptyRecipeBtnSize.width , emptyRecipeBtnLabelSize.height + 10))
		end
		-- emptyRecipeBtn:setVisible(false)
        local desLabel = display.newLabel(510 - 62, 80,{
            ap = cc.p(1,0.5), fontSize = fontWithColor('5').fontSize , color = fontWithColor('5').color, text = __('橱窗占位')
        })
        recipeLayout:addChild(desLabel)
        -- desLabel:setVisible(false)
		return {
			view = cview,
			closeBtn = closeBtn,--关闭页面按钮


			cookLayout = cookLayout,--左边做菜区域
			Tcooks = cooks,--左边做菜区域各个ui

			recipeLayout = recipeLayout,--右边已经做好菜的区域
			TshowCooks = showCooks,--显示做好菜的区域的各个ui
			Tbuttons = buttons,--做好菜的桌布按钮

			recipeMessLayout = recipeMessLayout,--点击桌布按钮显示的改菜谱的详情区域
			TrecipeMess = TrecipeMess,--点击桌布按钮显示的改菜谱的详情区域各个ui

			emptyRecipeBtn = emptyRecipeBtn,
			desLabel = desLabel,
		}
	end
	xTry(function ( )
		self.viewData = CreateView( )
		self.eaterLayer = eaterLayer
	end, __G__TRACKBACK__)
end

return LobbyCookingView
