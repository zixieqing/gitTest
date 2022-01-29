-- 留言簿
local CommonDialog = require('common.CommonDialog')
local MessageBookView = class('MessageBookView', CommonDialog)
local RES_DIR = {
	bg = _res("ui/common/common_bg_3.png"),
	title_bg = _res("ui/common/common_bg_title_2"),
	visitor_bg = _res('avatar/ui/friends_bg_message_visitor_number.png'),
}

function MessageBookView:InitialUI()
	local function CreateView()
		local bg = display.newImageView(RES_DIR.bg, 0, 0)
		local size = bg:getContentSize()
        local view = display.newLayer(0, 0, {size = size})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg)

		-- title
		local titleBg = display.newImageView(RES_DIR.title_bg, size.width / 2, size.height * 0.969)
		local titleLabel = display.newLabel(0, 0, fontWithColor(3, {text = self.name  }))
		display.commonUIParams(titleLabel, {po = cc.p(utils.getLocalCenter(titleBg))})
		titleBg:addChild(titleLabel)
		view:addChild(titleBg)

		-- 访客提示
		local visitorBg = display.newImageView(RES_DIR.visitor_bg, size.width / 2, size.height * 0.89)
		local visitorBgSize = visitorBg:getContentSize()
		local totalVisitor = display.newLabel(3, visitorBgSize.height / 2, fontWithColor(18, {text = string.format( __('总访客量: %s'), 1111), ap = display.LEFT_CENTER}))
		local todayVisitor = display.newLabel(visitorBgSize.width - 3, visitorBgSize.height / 2, fontWithColor(18, {text = string.format( __('今日访客: %s'), 33), ap = display.RIGHT_CENTER}))
		visitorBg:addChild(totalVisitor)
		visitorBg:addChild(todayVisitor)
		view:addChild(visitorBg)

		local gridViewSize = cc.size(size.width * 0.9, size.height * 0.83)
		local gridViewCellSize = cc.size(gridViewSize.width, 119)
		local msgGridView = CGridView:create(gridViewSize)
		msgGridView:setSizeOfCell(gridViewCellSize)
		msgGridView:setColumns(1)
		-- msgGridView:setAutoRelocate(true)
		-- msgGridView:setBounceable(false)
		-- msgGridView:setBackgroundColor(cc.c3b(100,100,200))
		msgGridView:setAnchorPoint(display.CENTER_BOTTOM)
		msgGridView:setPosition(cc.p(size.width / 2, 14))
		view:addChild(msgGridView)

		return {
			view = view,
			totalVisitor = totalVisitor,
			todayVisitor = todayVisitor,
			msgGridView = msgGridView,
			visitorBg = visitorBg,
		}
	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)
end

--[[
添加没有访客的说明
--]]
function MessageBookView:AddNotVisitorView(str)
	local viewData = self.viewData
	local view = viewData.view
	local centerLayerSize = view:getContentSize()
	local noVisitorView = display.newLayer(centerLayerSize.width/2 , centerLayerSize.height/2 -50 , {
		ap = display.CENTER ,
		size = centerLayerSize
	})
	local qImage = display.newImageView(_res('arts/cartoon/card_q_3') ,centerLayerSize.width/2 , centerLayerSize.height/2+30,{
		scale = 0.7
	} )
	noVisitorView:addChild(qImage)
	local label = display.newLabel(centerLayerSize.width/2 , centerLayerSize.height/2 -150 ,fontWithColor(14 , { color = "#ba5c5c" , fontSize = 30 , ap = display.CENTER ,hAlign= display.TAC ,  text = __('暂无')  ..str }))
	noVisitorView:addChild(label)
	view:addChild(noVisitorView,20)
end

return MessageBookView