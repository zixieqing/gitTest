--[[
活动 道具兑换加长版 view
--]]
local ActivityExchangeLargeView = class('ActivityExchangeLargeView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.ActivityExchangeLargeView'
	node:enableNodeEvents()
	return node
end)
function ActivityExchangeLargeView:ctor( ... )
    self.args = unpack({...})
    self:InitialUI()
end

function ActivityExchangeLargeView:InitialUI()
    local isLarge = self.args.isLarge
    local hideTimer = self.args.hideTimer
    local CreateView = function ()
        local layer = display.newLayer(0, 0, {size = display.size, ap = display.LEFT_BOTTOM})
        self:addChild(layer)

        local touchView = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 130), enable = true, size = display.size, ap = display.LEFT_BOTTOM, cb = handler(self, self.CloseHandler)})
        layer:addChild(touchView)
        -- bg
        local bgImg = nil
        if isLarge then
            bgImg = _res("ui/common/common_bg_5.png")
        else
            bgImg = _res("ui/common/common_bg_2.png")
        end
        local bg = display.newImageView(bgImg, 0, 0)
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
        -- local titleBgSize = titleBg:getContentSize()
        local titleFont = fontWithColor(3, {text = __("限时道具兑换")})
        local title = display.newLabel(0, 0, titleFont)
        local titleBg = display.newImageView(_res("ui/common/common_bg_title_2.png"), bgSize.width / 2, bgSize.height - 20, {scale9 = true, size = cc.size(display.getLabelContentSize(title).width + 50, 36)})
        title:setPosition(cc.p(titleBg:getContentSize().width / 2, titleBg:getContentSize().height / 2))
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

        -- tip label
        local tipLabel = display.newLabel(bgSize.width / 2, titleBg:getPositionY() - 40, fontWithColor(16, {ap = display.CENTER}))
        view:addChild(tipLabel)
        tipLabel:setVisible(false)

        -- list title
        local titleBgImg = nil
        if isLarge then
            titleBgImg = _res("ui/home/activity/activity_exchange_bg_goods.pngactivity_exchange_bg_title_xl.png")
        else
            titleBgImg = _res("ui/home/activity/activity_exchange_bg_title.png")
        end
        local listTiltleBg = display.newImageView(titleBgImg, bgSize.width / 2, titleBg:getPositionY() - 60, {ap = display.CENTER_TOP})
        view:addChild(listTiltleBg)
        local listTiltleBgSize = listTiltleBg:getContentSize()
        
        -- bgTitleLine
        local listTitleLine = display.newImageView(_res("ui/home/activity/activity_exchange_bg_title_line.png"), listTiltleBgSize.width * 0.35, listTiltleBgSize.height / 2)
        listTiltleBg:addChild(listTitleLine)

        local needMaterialLabel = display.newLabel(listTiltleBgSize.width * 0.35 / 2, listTiltleBgSize.height / 2, fontWithColor(16, {text = __("需要材料"), reqW = 230}))
        listTiltleBg:addChild(needMaterialLabel)

        local rewardlLabel = display.newLabel(listTiltleBgSize.width * 0.35 + listTiltleBgSize.width * 0.65 / 2, listTiltleBgSize.height / 2, fontWithColor(16, {text = __("奖励")}))
        listTiltleBg:addChild(rewardlLabel)
        if isLarge then 
            listTitleLine:setPositionX(650)
            needMaterialLabel:setPositionX(322)
            rewardlLabel:setPositionX(870)
        end
        -- list
        local listBgSize = cc.size(692, 508)
        if hideTimer then
            counDownView:setVisible(false)
            listTiltleBg:setPositionY(listTiltleBg:getPositionY() + 37)
            listBgSize.height = 548
        end
        if isLarge then
            listBgSize.width = 1085
        end
        local listBg = display.newImageView(_res("ui/home/activity/activity_exchange_bg_title_line.png"), bgSize.width / 2, listTiltleBg:getPositionY() - 36, {scale9 = true, size = listBgSize, ap = display.CENTER_TOP})
        view:addChild(listBg)

        local gridViewSize = cc.size(listBgSize.width * 0.99, listBgSize.height * 0.99)
        local gridViewCellSize = cc.size(listBgSize.width * 0.99, 162)

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
            listTiltleBg       = listTiltleBg,
            listBg             = listBg,
            gridView           = gridView,
            bgSize             = bgSize,
            gridViewCellSize   = gridViewCellSize,
            counDownViewSize   = counDownViewSize,

            listTiltleBg       = listTiltleBg,
        }
    end

    xTry(function ( )
        self.viewData = CreateView( )
	end, __G__TRACKBACK__)
end

function ActivityExchangeLargeView:CloseHandler()
    PlayAudioByClickClose()
    local mediator = AppFacade.GetInstance():RetrieveMediator("ActivityExchangeLargeMediator")
    if mediator then
        AppFacade.GetInstance():UnRegsitMediator("ActivityExchangeLargeMediator")
    end
end
return ActivityExchangeLargeView