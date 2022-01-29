local CardDetailView = class('CardDetailView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.CardDetailView'
	node:enableNodeEvents()
	return node
end)


local function CreateView()
	local view = CLayout:create(display.size)
	-- view:setBackgroundColor(cc.c4b(0, 255, 128, 128))
	local bg = display.newImageView(_res('ui/bg/common_loading_bg.png'), display.cx, display.cy)
	view:addChild(bg,-1)


	local pageSize  = cc.size(bg:getContentSize().width * 0.5 - 30,display.size.height)--bg:getContentSize().height - 150
    local pageview = CPageView:create(pageSize)
    pageview:setAnchorPoint(cc.p(0.5, 0.5))
    pageview:setPosition(cc.p(pageSize.width * 0.5 ,view:getContentSize().height * 0.5 ))
    pageview:setDirection(eScrollViewDirectionHorizontal)
    pageview:setSizeOfCell(pageSize)
    view:addChild(pageview)
    pageview:setDragable(false)
    -- pageview:setBackgroundColor(cc.c4b(0, 255, 128, 128))

    -- dump(pageSize.width * 0.5 + 18)
    -- dump(view:getContentSize().height * 0.5)
	--左按钮 common_btn_switch.png
    local leftBtn = display.newButton(60,pageSize.height * 0.56,{
        n = _res('ui/common/common_btn_switch_right.png')
    })
    leftBtn:setScale(-1)
    leftBtn:setTag(1)
    view:addChild(leftBtn,10)

    --右按钮
    local rightBtn = display.newButton(pageSize.width - 90 ,pageSize.height * 0.56,{
        n = _res('ui/common/common_btn_switch_right.png')
    })
    rightBtn:setAnchorPoint(cc.p(0.5,0.5))
    rightBtn:setTag(2)
    view:addChild(rightBtn,10)

	-- local addBtn = display.newButton(pageSize.width * 0.5 + 150,125,{
 --        n = _res('ui/common/common_btn_add.png')
 --    })
 --    addBtn:setAnchorPoint(cc.p(0.5,0.5))
 --    addBtn:setTag(3)
 --    view:addChild(addBtn,10)


	return {
		view = view,
		pageview	= pageview,
		pageSize	= pageSize,
		leftBtn		= leftBtn,
		rightBtn	= rightBtn,
		-- addBtn 		= addBtn,
	} 
end

function CardDetailView:ctor( ... )
	self.args = unpack({...}) or {}

	local eaterLayer = CColorView:create(cc.c4b(100, 0, 200, 100))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	eaterLayer:setPosition(cc.p(display.cx, display.height))
	self:addChild(eaterLayer, 1)
	

	self.viewData = CreateView()
	display.commonUIParams(self.viewData.view, {po = display.center})
	self:addChild(self.viewData.view,10)
end

return CardDetailView
