--[[
单笔充值活动 view
--]]
local ActivitySinglePayView = class('ActivitySinglePayView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.ActivitySinglePayView'
	node:enableNodeEvents()
	return node
end)
function ActivitySinglePayView:ctor( ... )
    self.args = unpack({...})
    self.isPermanent = self.args.isPermanent -- 是否为常驻活动
    self:InitialUI()
end

function ActivitySinglePayView:InitialUI()
    local isPermanent = self.isPermanent
    local CreateView = function ()
        local layer = display.newLayer(0, 0, {size = display.size, ap = display.LEFT_BOTTOM})
        self:addChild(layer)

        local touchView = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 130), enable = true, size = display.size, ap = display.LEFT_BOTTOM, cb = handler(self, self.CloseHandler)})
        layer:addChild(touchView)
        -- bg
        local bg = display.newImageView(_res("ui/common/common_bg_2.png"), 0, 0)
        local bgSize = bg:getContentSize()
        local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
        local touchView1 = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 0), enable = true, size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		display.commonUIParams(view, {po = cc.p(utils.getLocalCenter(layer))})
		display.commonUIParams(touchView1, {po = cc.p(utils.getLocalCenter(layer))})
        view:addChild(bg)
        layer:addChild(touchView1)
        layer:addChild(view)

        -- title
        local titleBg = display.newImageView(_res("ui/common/common_bg_title_2.png"), bgSize.width / 2, bgSize.height - 20)
        local titleBgSize = titleBg:getContentSize()
        local titleFont = fontWithColor(3, {text = ''})
        local title = display.newLabel(titleBgSize.width / 2, titleBgSize.height / 2, titleFont)
        view:addChild(titleBg)
        titleBg:addChild(title)

        -- desc
        local descLabel = display.newLabel(25, bgSize.height - 50, fontWithColor(6, {ap = display.LEFT_TOP, w = bgSize.width - 50}))
        view:addChild(descLabel)
        descLabel:setVisible(false)

        -- 倒计时
        local counDownViewSize = cc.size(bgSize.width, 25)
        local counDownView = display.newLayer(bgSize.width / 2, titleBg:getPositionY() - 30, {size = counDownViewSize, ap = display.CENTER_TOP})
        
        local leftTimeFont = fontWithColor(16, {text = __('活动剩余时间:')})
		local countDownFont = fontWithColor(10)
		local leftTimeLabel = display.newLabel(0, 0, leftTimeFont)
        local countDownLabel = display.newLabel(0, 0, countDownFont)

		local leftTimeLabelSize = display.getLabelContentSize(leftTimeLabel)
		local countDownLabelSize = display.getLabelContentSize(countDownLabel)

        leftTimeLabel:setPosition(counDownViewSize.width/2 - countDownLabelSize.width/2, counDownViewSize.height/2)
        countDownLabel:setPosition(counDownViewSize.width/2 + leftTimeLabelSize.width/2, counDownViewSize.height/2)
		counDownView:addChild(leftTimeLabel)
		counDownView:addChild(countDownLabel)
        view:addChild(counDownView)
        -- if isPermanent then
        --     counDownView:setVisible(false)
        -- end

        -- tip label
        local tipLabel = display.newLabel(bgSize.width / 2, titleBg:getPositionY() - 40, fontWithColor(16, {ap = display.CENTER}))
        view:addChild(tipLabel)
        tipLabel:setVisible(false)

        -- list title
        local listTiltleBg = display.newImageView(_res("ui/home/activity/activity_exchange_bg_title.png"), bgSize.width / 2, titleBg:getPositionY() - 60, {ap = display.CENTER_TOP})
        view:addChild(listTiltleBg)
        local listTiltleBgSize = listTiltleBg:getContentSize()
        
        -- list
        local listBgSize = cc.size(692, 546)
        local listBgPosY = titleBg:getPositionY() - 60
        -- if isPermanent then
        --     listBgSize = cc.size(692, 576)
        --     listBgPosY = titleBg:getPositionY() - 30
        -- end
        local listBg = display.newImageView(_res("ui/home/activity/activity_exchange_bg_title_line.png"), bgSize.width / 2, listBgPosY, {scale9 = true, size = listBgSize, ap = display.CENTER_TOP})
        view:addChild(listBg)

        local gridViewSize = cc.size(listBgSize.width * 0.99, listBgSize.height * 0.99)
        local gridViewCellSize = cc.size(listBgSize.width, 162)
        local gridView = CGridView:create(gridViewSize)
		gridView:setAnchorPoint(display.CENTER_TOP) 
		gridView:setPosition(cc.p(bgSize.width / 2, listBg:getPositionY())) 
		gridView:setCountOfCell(0)
        gridView:setColumns(1)
		gridView:setSizeOfCell(gridViewCellSize)
		gridView:setAutoRelocate(true)
		view:addChild(gridView)

        return {
            view               = view,
            title              = title,
            descLabel          = descLabel,
            counDownView       = counDownView,
            leftTimeLabel      = leftTimeLabel,
            countDownLabel     = countDownLabel,
            tipLabel           = tipLabel,
            listBgSize         = listBgSize,
            listTiltleBg       = listTiltleBg,
            listBg             = listBg,
            gridView           = gridView,
            bgSize             = bgSize,
            gridViewSize       = gridViewSize,
            gridViewCellSize   = gridViewCellSize,
            counDownViewSize   = counDownViewSize,
        }
    end

    xTry(function ( )
        self.viewData = CreateView( )
	end, __G__TRACKBACK__)
end
function ActivitySinglePayView:CloseHandler()
    PlayAudioByClickClose()
    local mediator = AppFacade.GetInstance():RetrieveMediator("ActivitySinglePayMediator")
    if mediator then
        AppFacade.GetInstance():UnRegsitMediator("ActivitySinglePayMediator")
    end
end
return ActivitySinglePayView