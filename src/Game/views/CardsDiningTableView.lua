--[[
飨灵喂食界面
--]]
local CardsDiningTableView = class('CardsDiningTableView', function ()
	local node = CLayout:create()
	node.name = 'Game.views.CardsDiningTableView'
	node:enableNodeEvents()
	return node
end)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")


--[[

--]]
function CardsDiningTableView:ctor( ... )
	self.args = unpack({...}) or {}
	local size = cc.size(590,550)
	self.viewData = nil
	self:setContentSize(display.size)
	-- self:setBackgroundColor(cc.c4b(100, 100, 100, 255))
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
    eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer


	local function CreateView()
		--滑动层背景图
		local view = CLayout:create()
		view:setPosition(cc.p(display.SAFE_L,0))
		view:setAnchorPoint(cc.p(0,0))
		self:addChild(view)

		-- view:setBackgroundColor(cc.c4b(100, 100, 100, 100))
		local bg = display.newImageView(_res('ui/cards/love/restaurant_kitchen_ico_table.png'), 0, 0,
		{ap = cc.p(0, 0)})
		view:addChild(bg)
		local bgSize = bg:getContentSize()
		view:setContentSize(bgSize)

		--屏蔽触摸层
		local cview = display.newLayer(0,0,{color = cc.c4b(0,0,0,0),enable = true,size = bgSize, ap = cc.p(0,0)})
		view:addChild(cview)


		local showFoodsLayout = {}
		local buttons = {}
		for i=1,3 do
			--桌布
			local tempBtn = display.newButton(120 + 180*(i-1),  206,
				{n = _res('ui/home/lobby/cooking/restaurant_kitchen_ico_dish_default.png')})
			view:addChild(tempBtn)
			tempBtn:setTag(i)
			table.insert(buttons,tempBtn)

			--显示菜谱icon和数量区域
		    local tsize =  tempBtn:getContentSize() -- cc.size(120,160)
			local tempLayout = CLayout:create(tsize)
			tempLayout:setAnchorPoint(cc.p(0.5,0.5))
			tempLayout:setPosition(cc.p(120 + 180*(i-1),  204))
			view:addChild(tempLayout)
            -- tempLayout:setBackgroundColor(cc.c4b(100, 100, 100, 100))
			-- tempLayout:setTag(i)
			--阴影
			local tempImg = display.newImageView(_res("ui/home/lobby/cooking/restaurant_kitchen_ico_dish_shardow.png"),tsize.width * 0.5,  80,--
			{ap = cc.p(0.5, 0.5)})
			tempLayout:addChild(tempImg,1)
			tempImg:setTag(1)
			tempImg:setVisible(false)
			--菜谱icon
			local img = display.newImageView(_res('ui/common/common_ico_lock.png') ,tsize.width * 0.5,  100,--
			{ap = cc.p(0.5, 0.5)})
			img:setScale(0.8)
			tempLayout:addChild(img,2)
			img:setTag(2)
			img:setVisible(false)

			local tempBtn = display.newButton(tsize.width * 0.5,  80,
				{n = _res('ui/cards/love/card_attribute_btn_pet_add.png')})
			tempLayout:addChild(tempBtn)
			tempBtn:setTag(3)
			tempBtn:setScale(0.8)
			tempBtn:setTouchEnabled(false)
            local remainNumLabel = display.newLabel(0, 0, {text = '', fontSize = 28, color = '#4c4c4c', ap = cc.p(0.5, 0.5)})
            display.commonUIParams(remainNumLabel, {po = cc.p(tempLayout:getContentSize().width * 0.5 ,26)})
            remainNumLabel:setName('REMAIN_TIMES_LABEL')
            tempLayout:addChild(remainNumLabel, 5)
            remainNumLabel:setVisible(false)
			table.insert(showFoodsLayout,tempLayout)
		end

		local showTimeBtn = display.newButton(bgSize.width*0.5, 75,
			{n = _res('ui/common/common_btn_orange_disable.png'),ap = cc.p(0.5,0),scale9 = true  })
		view:addChild(showTimeBtn)
		display.commonLabelParams(showTimeBtn,fontWithColor(14,{text = __('喂食'),offset = cc.p(0,0) , paddingW = 20 }))--offset = cc.p(0,10)


		return {
			view 			= view,
			bg 				= bg,
			buttons 		= buttons,
			showFoodsLayout = showFoodsLayout,
			showTimeBtn 	= showTimeBtn,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )

		self.viewData.view:setOpacity(0)
		self.viewData.view:setPositionX(-500)

		self.viewData.view:runAction(
	        cc.Spawn:create(cc.FadeIn:create(0.2),
	        cc.MoveTo:create(0.2, cc.p(0, 0)))
	    )
	end, __G__TRACKBACK__)

end



return CardsDiningTableView
