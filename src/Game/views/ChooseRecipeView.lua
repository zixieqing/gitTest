--[[
选择做菜ui
--]]
local GameScene = require( "Frame.GameScene" )

local ChooseRecipeView = class('ChooseRecipeView', GameScene)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local CreateStyleTypeBtn = nil
--[[
--]]
function ChooseRecipeView:ctor( ... )

	self.viewData = nil
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)

	-- view:setBackgroundColor(cc.c4b(0, 100, 0, 100))
	-- view:setScale(0.96)

	local function CreateView()
		local view = CLayout:create(display.size)
		-- view:setBackgroundColor(cc.c4b(0, 128, 0, 255))
		local size  = view:getContentSize()
	    display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.size.width * 0.5, display.size.height * 0.5)})
	    self:addChild(view, 10)
	    view:setName('view')
    	local rsize = cc.size(600,674)
		local recipeLayout = CLayout:create(rsize)
		recipeLayout:setAnchorPoint(cc.p(1,0.5))
		recipeLayout:setPosition(cc.p(display.SAFE_R,display.size.height * 0.5))
		view:addChild(recipeLayout,1)
		-- recipeLayout:setBackgroundColor(cc.c4b(0, 100, 0, 100))
		recipeLayout:setName('recipeLayout')
	    local bg = display.newImageView(_res('ui/home/kitchen/cooking_bg.png'), rsize.width* 0.5 ,0)
	    bg:setAnchorPoint(cc.p(0.5,0))
	    recipeLayout:addChild(bg)

        --滑动层背景图
		local ListBg = display.newImageView(_res("ui/common/common_bg_goods.png"), rsize.width * 0.5, rsize.height - 80,--
		{scale9 = true, size = cc.size(560, 570),ap = cc.p(0.5, 1)})	--630, size.height - 20
		recipeLayout:addChild(ListBg)
		local ListBgFrameSize = ListBg:getContentSize()
		--添加列表功能
		local taskListSize = cc.size(ListBgFrameSize.width - 2, ListBgFrameSize.height - 4)
		local taskListCellSize = cc.size(186 , 210)

		local gridView = CGridView:create(taskListSize)
		gridView:setSizeOfCell(taskListCellSize)
		gridView:setColumns(3)
		recipeLayout:addChild(gridView)
		gridView:setAnchorPoint(cc.p(0.5, 1))
		gridView:setPosition(cc.p(ListBg:getPositionX() , ListBg:getPositionY() - 2 ))
		-- gridView:setBackgroundColor(cc.c4b(0, 100, 0, 100))
		gridView:setName('gridView')

		local styleBtn = display.newCheckBox(0, 0,
			{n = _res('ui/home/kitchen/cooking_title_btn.png'), s = _res('ui/home/kitchen/cooking_title_btn.png')})
		display.commonUIParams(styleBtn, {po = cc.p(260, rsize.height - 45 + 26),ap = cc.p(1,1) })--display.LEFT_CENTER
		recipeLayout:addChild(styleBtn, 10)
		local styleLabel = display.newRichLabel(utils.getLocalCenter(styleBtn).x, utils.getLocalCenter(styleBtn).y + 4,
				{c = {
					fontWithColor(14,{fontSize = 22,text = ' '})
				}})
		styleBtn:addChild(styleLabel)
		local styleBoard = display.newLayer(styleBtn:getPositionX(), styleBtn:getPositionY() - styleBtn:getContentSize().height * 0.5 - 28 ,
			{ap = cc.p(1, 1)})
		recipeLayout:addChild(styleBoard, 15)
		local styleTabViewData = self:CreateStyleTab(styleBoard)

		-- local styleDatas =  app.cookingMgr:GetStyleTable()
        -- local styleType = {}
        -- for name,val in pairs(styleDatas) do
        --     if checkint(val.initial) ~= 2 then
        --         --不是魔法菜系的逻辑
		-- 		table.insert(styleType, val)
		-- 		-- styleType[checkint(val.id)] = val
        --     end
        -- end
		-- -- print("------------------>>" , table.nums(styleDatas))
		-- -- dump(styleDatas)
		-- -- sortByMember(styleType, 'id')
		-- local sortStyleType = function (a, b)
		-- 	if not a then return true end
		-- 	if not b then return false end

		-- 	return checkint(a.id) < checkint(b.id)
		-- end
		-- table.sort( styleType, sortStyleType)
		-- -- dump(styleType, 'styleDatas222')
	    -- local bgSize = cc.size(250,67*table.nums(styleType))
		-- local styleBoardImg = display.newImageView(_res('ui/home/kitchen/kitchen_bg_tab_drop.png'), styleBtn:getPositionX() , styleBtn:getPositionY() - styleBtn:getContentSize().height * 0.5
		-- 	,{ scale9 = true ,size = bgSize })
		-- local styleBoard = display.newLayer(styleBtn:getPositionX() + 30 , styleBtn:getPositionY() - styleBtn:getContentSize().height * 0.5 - 28 ,
		-- 	{size = styleBoardImg:getContentSize(), ap = cc.p(1, 1)})
		-- recipeLayout:addChild(styleBoard, 15)
		-- display.commonUIParams(styleBoardImg, {po = utils.getLocalCenter(styleBoard)})
		-- styleBoard:addChild(styleBoardImg)
		-- styleBoard:setVisible(false)

		-- -- 类型
		-- local topPadding = 10
		-- local bottomPadding = 6
		-- local listSize = cc.size(styleBoard:getContentSize().width, styleBoard:getContentSize().height - topPadding - bottomPadding)

		-- local cellSize = cc.size(listSize.width, 63)
		-- local centerPos = nil
		-- local styleTab = {}
		-- local splitLines = {}
		-- for i,v in ipairs(styleType) do
		-- 	centerPos = cc.p(listSize.width * 0.5, listSize.height + bottomPadding - (i - 0.5) * cellSize.height)
		-- 	local sortTypeBtn, splitLine = CreateStyleTypeBtn(styleBoard, v, i < table.nums(styleType))
		-- 	display.commonUIParams(sortTypeBtn, {po = centerPos})
		-- 	if splitLine then
		-- 		display.commonUIParams(splitLine, {po = cc.p(centerPos.x, centerPos.y - cellSize.height * 0.5)})
		-- 		table.insert(splitLines,splitLine)
		-- 	end
		-- 	-- sortTypeBtn:setVisible(false)
		-- 	table.insert(styleTab,sortTypeBtn)
		-- end


	    local msize = cc.size(330,658)
  		local messLayout = CLayout:create(msize)
		messLayout:setAnchorPoint(cc.p(1,0.5))
		messLayout:setPosition(cc.p(display.SAFE_R - rsize.width ,display.size.height * 0.5))
		view:addChild(messLayout)
		messLayout:setVisible(false)
		-- messLayout:setBackgroundColor(cc.c4b(0, 100, 0, 100))
		messLayout:setName('messLayout')
	    local sideBG = display.newImageView(_res('ui/home/lobby/cooking/kitchen_make_side_bg.png'), msize.width* 0.5 ,0)
	    sideBG:setAnchorPoint(cc.p(0.5,0))
	    messLayout:addChild(sideBG)

		local messTouchView = display.newLayer(msize.width * 0.5, 550, {ap = display.CENTER_TOP, color = cc.c4b(0, 0, 0, 0), enable = true, size = cc.size(msize.width + 20, 205)})
		messTouchView:setVisible(false)
	    messLayout:addChild(messTouchView)

		local nameLabel = display.newLabel(10,msize.height - 22,{fontSize = 28 ,  outline = '#4c4c4c', outlineSize = 1,ap = display.LEFT_CENTER ,text = "" })
		messLayout:addChild(nameLabel)
		nameLabel:enableOutline(ccc4FromInt('#734441'), 1)
		local tempLabel = display.newLabel(10,msize.height - 52,fontWithColor('5', {ap = display.LEFT_CENTER ,text = __("餐厅单价："),color = '5c5c5c'}))
		messLayout:addChild(tempLabel)

        local lwidth = display.getLabelContentSize(tempLabel).width + 10
		local saleLabel = cc.Label:createWithBMFont('font/small/common_text_num_2.fnt', '')
		display.commonUIParams(saleLabel, {ap = cc.p(0,0.5)})
		saleLabel:setPosition(cc.p(lwidth + 6,msize.height - 52))
		messLayout:addChild(saleLabel,1)

		local img_money_type = display.newImageView(_res(string.format( "arts/goods/goods_icon_%d.png", GOLD_ID )),0,0,{ap = cc.p(0, 0.5)})
		messLayout:addChild(img_money_type)
		img_money_type:setScale(0.2)
		img_money_type:setPosition(cc.p(saleLabel:getPositionX() + saleLabel:getBoundingBox().width + 5 , msize.height - 52))
		local priceTagBtn = nil
		if isElexSdk() and (not isNewUSSdk()) then
			priceTagBtn = display.newButton(msize.width - 80, msize.height - 52, {n = _res('ui/common/common_btn_tips.png')})
			messLayout:addChild(priceTagBtn)
		end
		local tempLabel = display.newLabel(10,msize.height - 82,fontWithColor('5', {ap = display.LEFT_CENTER ,text = __("进餐时间：") , reqW = 110,color = '5c5c5c'}))
		messLayout:addChild(tempLabel)

		local diningTimeLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
		display.commonUIParams(diningTimeLabel, {ap = cc.p(0,0.5)})
		diningTimeLabel:setPosition(cc.p(120,msize.height - 82))
		messLayout:addChild(diningTimeLabel,1)


        local diningDesLabel = display.newLabel( 150,msize.height - 82,{
            ap = cc.p(0,0.5), fontSize = fontWithColor('11').fontSize , color = '5c5c5c', text = __("秒/份")
        })
        messLayout:addChild(diningDesLabel)
        diningDesLabel:setPosition(cc.p(diningTimeLabel:getPositionX() + diningTimeLabel:getBoundingBox().width + 5 , msize.height - 82))

		local tempBtn = display.newButton(msize.width * 0.5,  512,
			{n = _res('ui/common/common_title_5.png'),enable = false})
		display.commonLabelParams(tempBtn, fontWithColor('4',{text = __('特色')}))
		tempBtn:setAnchorPoint(cc.p(0.5,0))
		messLayout:addChild(tempBtn,1)
		tempBtn:setName('messBtn')


		local TmessLabe = {}
		local config = {__('味道'),__('口感'),__('香味'),__('外观')}
		local keyconfig = {'taste','museFeel','fragrance','exterior'}
		for i=1,4 do
			local temp = display.newButton(0, 0, {n = _res('ui/home/market/market_buy_bg_info.png'),enable = false})
			display.commonUIParams(temp, {po = cc.p(msize.width * 0.5, 470 - 35*(i-1)),ap = cc.p(0.5,0)})
			display.commonLabelParams(temp, fontWithColor('5',{ap = display.LEFT_CENTER,text = __(config[i]),offset = cc.p(-100,0)}))
			messLayout:addChild(temp)

			local tempLabel = display.newLabel(msize.width - 80,485 - 35*(i-1),fontWithColor('5', {ap = display.CENTER ,text = tostring(i)}))
			messLayout:addChild(tempLabel,1)
			TmessLabe[keyconfig[i]] = tempLabel
			-- table.insert(TmessLabe,tempLabel)
		end


		local makeBtn = display.newButton(msize.width * 0.5,  10,
			{n = _res('ui/common/common_btn_orange.png'),enable = true})
		makeBtn:setAnchorPoint(cc.p(0.5,0))
		messLayout:addChild(makeBtn,1)
		display.commonLabelParams(makeBtn,{ttf = true , font = TTF_GAME_FONT ,text = __('制作'), fontSize = 22, color = '#ffffff',offset = cc.p(0,14)})
		makeBtn:setName('makeBtn')

		-- local priceLabel = display.newLabel(16,4,fontWithColor('4', {ap = display.CENTER ,text = "100"}))
		-- priceLabel:setAnchorPoint(cc.p(0,0))
		-- makeBtn:addChild(priceLabel)

		local priceLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
		display.commonUIParams(priceLabel, {ap = cc.p(0,0)})
		priceLabel:setPosition(cc.p(16,4))
		makeBtn:addChild(priceLabel,1)


	    local goldImg = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)), 70 ,4)
	    goldImg:setAnchorPoint(cc.p(0,0))
	    goldImg:setScale(0.2)
	    makeBtn:addChild(goldImg)

		local tempBtn = display.newButton(msize.width * 0.5,  300,
			{n = _res('ui/common/common_title_5.png'),enable = false})
		display.commonLabelParams(tempBtn, fontWithColor('4',{text = __('制作数量')}))
		tempBtn:setAnchorPoint(cc.p(0.5,0))
		messLayout:addChild(tempBtn,1)
		tempBtn:setName('makeNumBtn')

		local canMakeLabel = display.newLabel(msize.width * 0.5,270,fontWithColor('4', {ap = display.CENTER ,text = ""}))
		canMakeLabel:setAnchorPoint(cc.p(0.5,0))
		messLayout:addChild(canMakeLabel,1)

		--选择数量
		local btn_num = display.newButton(0, 0, {
                n = _res('ui/home/market/market_buy_bg_info.png'),
                s = _res('ui/home/market/market_buy_bg_info.png'),
            enable = false,scale9 = true, size = cc.size(180, 44)})
		display.commonUIParams(btn_num, {po = cc.p(msize.width * 0.5, 220),ap = cc.p(0.5,0)})
		display.commonLabelParams(btn_num, {text = '1', fontSize = 28, color = '#7c7c7c'})
		messLayout:addChild(btn_num)

		--减号btn
		local btn_minus = display.newButton(0, 0, {n = _res('ui/home/market/market_sold_btn_sub.png')})
		display.commonUIParams(btn_minus, {po = cc.p(msize.width * 0.5 - 90, 215),ap = cc.p(0.5,0)})
		messLayout:addChild(btn_minus)
		btn_minus:setTag(1)

		--加号btn
	    local btn_add = display.newButton(0, 0, {n = _res('ui/home/market/market_sold_btn_plus.png')})
		display.commonUIParams(btn_add, {po = cc.p(msize.width * 0.5 + 90, 215),ap = cc.p(0.5,0)})
		messLayout:addChild(btn_add)
		btn_add:setTag(2)
		-- local label_add = btn_add:getLabel()

		local tempLabel = display.newLabel(msize.width * 0.5,192,fontWithColor('4', {ap = display.CENTER ,text = __('制作时间')}))
		messLayout:addChild(tempLabel)
		tempLabel:setName('makeTimeLabel')

		local makeTimeBtn = display.newButton(msize.width * 0.5,162,{n= _res('ui/home/lobby/cooking/kitchen_make_bg_info.png') })
		display.commonLabelParams(makeTimeBtn, fontWithColor(4,{text = '2'}))
		messLayout:addChild(makeTimeBtn)

		local tempLabel = display.newLabel(msize.width * 0.5,124,fontWithColor('4', {reqW = 320 ,  ap = display.CENTER ,text = __('消耗厨师新鲜度')}))
		messLayout:addChild(tempLabel)

		local needVigourBtn = display.newButton(msize.width * 0.5,94,{n= _res('ui/home/lobby/cooking/kitchen_make_bg_info.png') })
		display.commonLabelParams(needVigourBtn, fontWithColor(4,{text = '3333'}))
		messLayout:addChild(needVigourBtn)

		local lobbyFestivalTipView = require('Game.views.LobbyFestivalTipView').new()
		lobbyFestivalTipView:setVisible(false)
		display.commonUIParams(lobbyFestivalTipView, {ap = display.RIGHT_CENTER, po = cc.p(-15, 450)})
		messLayout:addChild(lobbyFestivalTipView, 10)

		local closeBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
		display.commonUIParams(closeBtn, {po = cc.p(display.SAFE_L + closeBtn:getContentSize().width * 0.5 + 30,display.size.height - 18 - closeBtn:getContentSize().height * 0.5)})
		view:addChild(closeBtn, 5)

		return {
			view = view,
			closeBtn = closeBtn,--关闭页面按钮
			recipeLayout = recipeLayout,
			styleBtn = styleBtn,
			styleLabel = styleLabel,
			styleBoard = styleBoard,
			styleTab = styleTabViewData.styleTab,
			splitLines = styleTabViewData.splitLines,
			priceTagBtn = priceTagBtn,

			gridView = gridView,

			messLayout = messLayout,
			makeBtn = makeBtn,
			canMakeLabel = canMakeLabel,
			nameLabel = nameLabel,
			saleLabel = saleLabel,
			diningTimeLabel = diningTimeLabel,
			diningDesLabel = diningDesLabel,
			img_money_type = img_money_type,
			TmessLabe = TmessLabe,
			priceLabel= priceLabel,
			btn_num = btn_num,
			btn_minus = btn_minus,
			btn_add = btn_add,
			makeTimeBtn = makeTimeBtn,
			needVigourBtn = needVigourBtn,

			-- 餐厅活动节日特色
			messTouchView        = messTouchView,
			lobbyFestivalTipView = lobbyFestivalTipView,

			listSize = listSize,
			cellSize = cellSize,
		}
	end
	xTry(function ( )
		self.viewData = CreateView( )

	end, __G__TRACKBACK__)
end

function ChooseRecipeView:CreateStyleTab(styleBoard, endCallback)
	if styleBoard == nil then return end

	if styleBoard:getChildrenCount() > 0 then
		styleBoard:removeAllChildren()
	end

	local styleDatas =  app.cookingMgr:GetStyleTable()
	local styleType = {}
	---@type GameManager
	local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
	local cookingStyles = gameMgr:GetUserInfo().cookingStyles
	for name,val in pairs(styleDatas) do
		if checkint(val.initial) ~= 2 and cookingStyles[tostring(name)]  then
			--不是魔法菜系的逻辑
			table.insert(styleType, val)
			-- styleType[checkint(val.id)] = val
		end
	end
	-- print("------------------>>" , table.nums(styleDatas))
	-- dump(styleDatas)
	-- sortByMember(styleType, 'id')
	local sortStyleType = function (a, b)
		if not a then return true end
		if not b then return false end

		return checkint(a.id) < checkint(b.id)
	end
	table.sort( styleType, sortStyleType)
	-- dump(styleType, 'styleDatas222')

	local bgSize = cc.size(250,67*table.nums(styleType))
	styleBoard:setContentSize(bgSize)
	local styleBoardImg = display.newImageView(_res('ui/home/kitchen/kitchen_bg_tab_drop.png'), 0, 0
		,{ scale9 = true ,size = bgSize })
	display.commonUIParams(styleBoardImg, {po = utils.getLocalCenter(styleBoard)})
	styleBoard:addChild(styleBoardImg)
	styleBoard:setVisible(false)
	-- 类型
	local topPadding = 10
	local bottomPadding = 6
	local listSize = cc.size(styleBoard:getContentSize().width, styleBoard:getContentSize().height - topPadding - bottomPadding)

	local cellSize = cc.size(listSize.width, 63)
	local centerPos = nil
	local styleTab = {}
	local splitLines = {}
	for i,v in ipairs(styleType) do
		centerPos = cc.p(listSize.width * 0.5, listSize.height + bottomPadding - (i - 0.5) * cellSize.height)
		local sortTypeBtn, splitLine = CreateStyleTypeBtn(styleBoard, v, i < table.nums(styleType))
		display.commonUIParams(sortTypeBtn, {po = centerPos})
		if splitLine then
			display.commonUIParams(splitLine, {po = cc.p(centerPos.x, centerPos.y - cellSize.height * 0.5)})
			table.insert(splitLines,splitLine)
		end
		table.insert(styleTab,sortTypeBtn)
	end

	return {
		styleTab = styleTab,
		splitLines = splitLines,
	}
end

CreateStyleTypeBtn = function (parent, data, isCreateLine)
	if data == nil then return end

	local sortTypeBtn = display.newButton(0, 0, {n = _res('ui/home/kitchen/kitchen_btn_tab_drop.png'), ap = cc.p(0.5, 0.5) })--,size = cellSize --,scale9 = true , size = cc.size(190,61)
	parent:addChild(sortTypeBtn)
	sortTypeBtn:setTag(data.id)
	-- table.insert(styleTab,sortTypeBtn)
	--local data  = CommonUtils.GetConfigNoParser('cooking','style',v.id)
	display.commonLabelParams(sortTypeBtn, fontWithColor('5',{text = data.name}))

	-- local descrLabel = display.newLabel(0, 0,
	-- 	fontWithColor(5,{text = data.name, ap = cc.p(0.5, 0.5)}))
	-- display.commonUIParams(descrLabel, {po = utils.getLocalCenter(sortTypeBtn)})
	-- -- styleBoard:addChild(descrLabel)
	-- sortTypeBtn:addChild(descrLabel)
	local splitLine = nil
	if isCreateLine then
		splitLine = display.newNSprite(_res('ui/common/tujian_selection_line.png'), 0, 0)
		parent:addChild(splitLine)
	end

	return sortTypeBtn, splitLine
end

return ChooseRecipeView
