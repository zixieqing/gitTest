--[[
活动弹出页 新手单笔充值 view
--]]
local ActivitySinglePayPopupView = class('ActivityFirstTopupPopupView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.ActivitySinglePayPopupView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG       = _res('ui/home/activity/activity_open_bg_danchong.png'),
    BACK_BTN = _res('ui/home/activity/activity_open_btn_quit.png')
}
function ActivitySinglePayPopupView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function ActivitySinglePayPopupView:InitUI()
    local function CreateView()
        -- bg
        local size = cc.size(1300, 787)
        local view = display.newLayer(display.cx - 124, display.cy - 50, {size = size, ap = cc.p(0.5, 0.5)})
        local bg = display.newImageView(RES_DICT.BG, size.width/2, size.height/2)
        view:addChild(bg)
        local titleImg = display.newImageView(_res('ui/home/activity/permanmentSinglePay/activity_recharge_text_title.png'), 220, 320, {ap = cc.p(0, 1)})
        view:addChild(titleImg, 3)
	    -- 时间
        local timeBg = display.newImageView(_res('ui/home/activity/activity_time_bg.png'), 460, size.height - 100, {ap = display.RIGHT_CENTER})
        timeBg:setScale(0.8)
	    local timeBgSize = timeBg:getContentSize()
	    view:addChild(timeBg, 5)
	    local timeTitleLabel = display.newLabel(25, timeBgSize.height / 2, fontWithColor(18, {text = __('剩余时间:'), ap = display.LEFT_CENTER}))
	    local timeTitleLabelSize = display.getLabelContentSize(timeTitleLabel)
	    timeBg:addChild(timeTitleLabel, 10)
	    local timeLabel = display.newLabel(timeTitleLabel:getPositionX() + timeTitleLabelSize.width + 5, timeTitleLabel:getPositionY(), {text = '', ap = cc.p(0, 0.5), fontSize = 24, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	    timeBg:addChild(timeLabel, 10)
        
        -- list
        local listBgSize = cc.size(692, 570)

        local gridViewSize = cc.size(listBgSize.width * 0.99, listBgSize.height * 0.99)
        local gridViewCellSize = cc.size(listBgSize.width, 162)
        local gridView = CGridView:create(gridViewSize)
		gridView:setPosition(cc.p(size.width / 2 + 244, size.height / 2 + 30)) 
		gridView:setCountOfCell(0)
        gridView:setColumns(1)
		gridView:setSizeOfCell(gridViewCellSize)
		gridView:setAutoRelocate(true)
        view:addChild(gridView, 5)
        -- 返回按钮
        local backBtn = display.newButton(size.width - 30, size.height - 60, {n = RES_DICT.BACK_BTN})
        view:addChild(backBtn, 10)

        return {
            view               = view,
            listBgSize         = listBgSize,
            -- listBg             = listBg,
            gridView           = gridView,
            -- bgSize             = bgSize,
            gridViewSize       = gridViewSize,
            gridViewCellSize   = gridViewCellSize,
            timeLabel          = timeLabel,
            backBtn            = backBtn,
        }
    end
    xTry(function ( )
        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
        eaterLayer:setContentSize(display.size)
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setPosition(utils.getLocalCenter(self))
        self.eaterLayer = eaterLayer
        self:addChild(eaterLayer, -1)
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
获取viewData
--]]
function ActivitySinglePayPopupView:GetViewData()
    return self.viewData
end
--[[
进入动画
--]]
function ActivitySinglePayPopupView:EnterAction()
    local viewData = self:GetViewData()
	viewData.view:setScale(0.8)
	viewData.view:runAction(
		cc.Sequence:create(
			cc.EaseBackOut:create(
				cc.ScaleTo:create(0.25, 1)
			)
		)
	)
end
return ActivitySinglePayPopupView