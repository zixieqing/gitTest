--[[
常驻单笔充值活动 view
--]]
local ActivityPermanentSinglePayView = class('ActivityPermanentSinglePayView', function ()
	local node = CLayout:create(cc.size(1035, 637))
    node.name = 'Game.views.ActivityPermanentSinglePayView'
    node:enableNodeEvents()
	return node
end)
function ActivityPermanentSinglePayView:ctor( ... )
    self.args = unpack({...})
    self:InitialUI()
end

function ActivityPermanentSinglePayView:InitialUI()
    local CreateView = function ()
        -- bg
        local bgSize = cc.size(1035, 637)
        local view = display.newLayer(bgSize.width/2, bgSize.height/2, {size = bgSize, ap = cc.p(0.5, 0.5)})
        local bg = display.newImageView(_res("ui/home/activity/permanmentSinglePay/activity_bg_novice_recharge.jpg"), bgSize.width/2, bgSize.height/2)
        view:addChild(bg)
        local titleImg = display.newImageView(_res('ui/home/activity/permanmentSinglePay/activity_recharge_text_title.png'), 10, 636, {ap = cc.p(0, 1)})
        view:addChild(titleImg, 3)
	    -- 时间
	    local timeBg = display.newImageView(_res('ui/home/activity/activity_time_bg.png'), 1030, 600, {ap = display.RIGHT_CENTER ,scale9 = true , size = isKoreanSdk() and cc.size(268 ,47) or cc.size(400 ,47)})
	    local timeBgSize = timeBg:getContentSize()
	    view:addChild(timeBg, 5)
	    local timeTitleLabel = display.newLabel(20, timeBgSize.height / 2, fontWithColor(18, {text = __('剩余时间:'), ap = display.LEFT_CENTER}))
	    local timeTitleLabelSize = display.getLabelContentSize(timeTitleLabel)
        timeBg:addChild(timeTitleLabel, 10)
	    local timeLabel = display.newLabel(20 + display.getLabelContentSize(timeTitleLabel).width, timeBgSize.height / 2, {text = '', ap = cc.p(0, 0.5), fontSize = 24, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
        timeBg:addChild(timeLabel, 10)
        
        -- list
        local listBgSize = cc.size(692, 546)
        local listBg = display.newImageView(_res("ui/common/common_bg_goods.png"), bgSize.width / 2 + 150, bgSize.height / 2 - 30, {scale9 = true, size = listBgSize})
        view:addChild(listBg, 3)

        local gridViewSize = cc.size(listBgSize.width * 0.99, listBgSize.height * 0.99)
        local gridViewCellSize = cc.size(listBgSize.width, 162)
        local gridView = CGridView:create(gridViewSize)
		gridView:setPosition(cc.p(bgSize.width / 2 + 150, bgSize.height / 2 - 30)) 
		gridView:setCountOfCell(0)
        gridView:setColumns(1)
		gridView:setSizeOfCell(gridViewCellSize)
		gridView:setAutoRelocate(true)
		view:addChild(gridView, 5)

        return {
            view               = view,
            listBgSize         = listBgSize,
            listBg             = listBg,
            gridView           = gridView,
            bgSize             = bgSize,
            gridViewSize       = gridViewSize,
            gridViewCellSize   = gridViewCellSize,
            timeLabel          = timeLabel,
            timeTitleLabel     = timeTitleLabel,
            timeBgSize         = timeBgSize,
            timeTitleLabelSize = timeTitleLabelSize,
        }
    end

    xTry(function ( )
        self.viewData_ = CreateView( )
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end
return ActivityPermanentSinglePayView