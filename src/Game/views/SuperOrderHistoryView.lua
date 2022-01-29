--[[
超大订单历史界面
--]]
local GameScene = require( "Frame.GameScene" )

local SuperOrderHistoryView = class('SuperOrderHistoryView', GameScene)

function SuperOrderHistoryView:ctor( ... )
	self.args = unpack({...}) or {}
	self.viewData = nil
	local function CreateView()
		local bg = require("common.TitlePanelBg").new({ title = __('历史订单'), type = 7})
		local pageSize  = cc.size(bg:getContentSize().width - 45,bg:getContentSize().height - 50)

	    local pageview = CPageView:create(pageSize)
	    pageview:setAnchorPoint(cc.p(0.5, 0.5))
	    pageview:setPosition(cc.p(pageSize.width * 0.5 + 22,pageSize.height * 0.5 + 10))
	    pageview:setDirection(eScrollViewDirectionHorizontal)
	    pageview:setSizeOfCell(pageSize)
	    bg:addChild(pageview)

    	local showLabel = display.newLabel( bg:getContentSize().width*0.5,bg:getContentSize().height*0.5,
			{ttf = true, font = TTF_GAME_FONT, text = __('无历史记录'), fontSize = 24, color = '#ff481d', ap = cc.p(0.5, 0.5)})
		bg:addChild(showLabel)
		showLabel:setVisible(false)

		--左按钮 common_btn_switch.png
	    local leftBtn = display.newButton(30,pageSize.height * 0.6,{
	        n = _res('ui/common/common_btn_switch.png')
	    })
	    leftBtn:setScale(-1)
	    leftBtn:setTag(1)
	    bg:addChild(leftBtn)

        --右按钮
	    local rightBtn = display.newButton(pageSize.width-20,pageSize.height * 0.6,{
	        n = _res('ui/common/common_btn_switch.png')
	    })
	    rightBtn:setAnchorPoint(cc.p(0.5,0.5))
	    rightBtn:setTag(2)
	    bg:addChild(rightBtn)
		return {
			view 		= bg,
			pageview	= pageview,
			pageSize   	= pageSize,
			showLabel 	= showLabel,
			leftBtn		= leftBtn,
			rightBtn	= rightBtn,
		} 
	end

	local commonBg = require('common.CloseBagNode').new(
	{callback = function ()
		AppFacade.GetInstance():UnRegsitMediator("SuperHistoryMediator")
	end})
	commonBg:setPosition(utils.getLocalCenter(self))
	self:addChild(commonBg)
	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)
	display.commonUIParams(self.viewData.view, {po = display.center})
	commonBg:addContentView(self.viewData.view)	
end

return SuperOrderHistoryView
