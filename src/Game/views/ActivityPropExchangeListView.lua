
-- local CommonDialog = require('common.CommonDialog')
local ActivityPropExchangeListView = class('ActivityPropExchangeListView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.ActivityPropExchangeListView'
	node:enableNodeEvents()
	return node
end)
local GoodNode = require('common.GoodNode')

local COLOR1 = cc.c3b(100,100,200)
local RES_DIR = {
    bg 					= "ui/common/common_bg_2.png",
    title 			    = "ui/common/common_bg_title_2.png",
    goodUnlock          = "ui/home/activity/activity_exchange_bg_goods_notunlock.png",
    goodNormal          = "ui/home/activity/activity_exchange_bg_goods.png",
    timeBg              = "ui/home/activity/activity_exchange_bg_time.png",
    bgTitleLine         = "ui/home/activity/activity_exchange_bg_title_line.png",
    bgTitle             = "ui/home/activity/activity_exchange_bg_title.png",

	btn_orange      	= "ui/common/common_btn_orange.png",
	COOKING_LEVEL_UP    = _res("ui/home/kitchen/cooking_level_up_ico_arrow.png"),

    --------------------------------------------------
    FULL_SERVER_BG      = "ui/home/activity/activity_quanfushua_bg.png",

    --------------------------------------------------
    UNION_TASK_BG       = "ui/union/unionTask/guild_task_bg_list.png",
}

local UI_TAG = {
    PROP_EXCHANGE             = 110120, -- 道具兑换
    FULL_SERVER               = 110121, -- 全服活动
    ACCUMULATIVE_RECHARGE     = 110122, -- 累充活动
    ACTIVITY_QUEST            = 110123, -- 活动副本
    ACCUMULATIVE_CONSUME      = 110124, -- 累消活动
    WHEEL_EXCHANGE            = 110125, -- 转盘次数兑换
    WORLD_BOSS_HUNT_REWARDS   = 110126, -- 世界BOSS狩猎奖励
    UNION_TASK                = 110127, -- 工会任务
	UR_PROBABILITY_UP		  = 110128, -- UR概率UP
}

local CreateCountDownLayer  = nil
local CreateListTiltleBg    = nil

local CreateListCell_       = nil
local CreateTaskCell_ = nil

function ActivityPropExchangeListView:ctor( ... )
    self.args = unpack({...})
    self.viewConfData = self.args.viewConfData
    self:InitialUI()
end

function ActivityPropExchangeListView:InitialUI()

    local CreateView = function ()
        local layer = display.newLayer(0, 0, {size = display.size, ap = display.LEFT_BOTTOM})
        self:addChild(layer)

        local touchView = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 130), enable = true, size = display.size, ap = display.LEFT_BOTTOM, cb = handler(self, self.CloseHandler)})
        layer:addChild(touchView)
        -- bg
        local bg = display.newImageView(_res(RES_DIR.bg), 0, 0 ,{scale9 = true })
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
        local titleBg = display.newImageView(_res(RES_DIR.title), bgSize.width / 2, bgSize.height - 20,{scale9 = true })
        local titleBgSize = titleBg:getContentSize()
        local titleFont = fontWithColor(3, {text = __("限时道具兑换")})
        local title = display.newLabel(titleBgSize.width / 2, titleBgSize.height / 2, titleFont)
        view:addChild(titleBg)
        titleBg:addChild(title)


        -- desc
        local descLabel = display.newLabel(25, bgSize.height - 50, fontWithColor(6, {ap = display.LEFT_TOP, w = bgSize.width - 50}))
        view:addChild(descLabel)
        descLabel:setVisible(false)

        -- local descLabelSize = display.getLabelContentSize(descLabel)
        -- dump(descLabelSize, '2222222getLabelContentSize')
        -- print(bgSize.height - 62 - descLabelSize.height - 8)

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
        local listTiltleBg = display.newImageView(_res(RES_DIR.bgTitle), bgSize.width / 2, titleBg:getPositionY() - 60, {ap = display.CENTER_TOP})
        view:addChild(listTiltleBg)
        local listTiltleBgSize = listTiltleBg:getContentSize()

        -- bgTitleLine
        local listTitleLine = display.newImageView(_res(RES_DIR.bgTitleLine), listTiltleBgSize.width * 0.35, listTiltleBgSize.height / 2)
        listTiltleBg:addChild(listTitleLine)
        listTitleLine:setVisible(false)

        local needMaterialLabel = display.newLabel(20, listTiltleBgSize.height / 2, fontWithColor(16, {text = __("需要材料") , ap = display.LEFT_CENTER  }))
        listTiltleBg:addChild(needMaterialLabel)

        local rewardlLabel = display.newLabel(listTiltleBgSize.width * 0.35 + listTiltleBgSize.width * 0.65 / 2, listTiltleBgSize.height / 2, fontWithColor(16, {text = __("奖励")}))
        listTiltleBg:addChild(rewardlLabel)

        -- list
        local listBgSize = cc.size(692, 508)
        local listBg = display.newImageView(_res(RES_DIR.bgTitleLine), bgSize.width / 2, titleBg:getPositionY() - 98, {scale9 = true, size = listBgSize, ap = display.CENTER_TOP})
        view:addChild(listBg)

        local gridViewSize = cc.size(listBgSize.width * 0.99, listBgSize.height * 0.99)
        local gridViewCellSize = cc.size(listBgSize.width * 0.99, 162)

        local gridView = CGridView:create(gridViewSize)
		gridView:setAnchorPoint(display.CENTER_TOP)
		gridView:setPosition(cc.p(bgSize.width / 2, listBg:getPositionY()))
		gridView:setCountOfCell(0)
        gridView:setColumns(1)
        -- gridView:setBackgroundColor(cc.c3b(100,100,200))
		gridView:setSizeOfCell(gridViewCellSize)
		gridView:setAutoRelocate(true)
		view:addChild(gridView)

        return {
            view               = view,
            title              = title,
            titleBg            = titleBg,
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
        }
    end

    xTry(function ( )
        self.viewData = CreateView( )
        self:initUiState()
	end, __G__TRACKBACK__)

end

function ActivityPropExchangeListView:initUiState()
    local tag           = self.viewConfData.tag
    local titleName     = self.viewConfData.title
    local isShowListTitle = checkbool(self.viewConfData.isShowListTitle)

    local title         = self.viewData.title
    local listTiltleBg  = self.viewData.listTiltleBg
    local counDownView  = self.viewData.counDownView
    local descLabel     = self.viewData.descLabel
    local tipLabel      = self.viewData.tipLabel
    
    local listBg        = self.viewData.listBg
    local gridView      = self.viewData.gridView
    local listBgSize    = listBg:getContentSize()
    local contentSize   = gridView:getContentSize()

    listTiltleBg:setVisible(isShowListTitle)
    if isShowListTitle == false then
        local listSize = cc.size(listBgSize.width, listBgSize.height + 38)
        self:updateListSize(listSize)
    end

    if tag == UI_TAG.UNION_TASK or tag == UI_TAG.UR_PROBABILITY_UP then
        counDownView:setVisible(false)
        descLabel:setVisible(true)
        local descLabelSize = display.getLabelContentSize(descLabel)
        local listSize = cc.size(listBgSize.width, descLabel:getPositionY() - descLabelSize.height - 17)
        self:updateListSize(listSize)
    elseif tag == UI_TAG.WORLD_BOSS_HUNT_REWARDS then
        counDownView:setVisible(false)
        listTiltleBg:setVisible(false)
        descLabel:setVisible(false)
        tipLabel:setVisible(true)
    end
    
    display.commonLabelParams(title, {text = titleName })
    local titileSize = display.getLabelContentSize(title)
    local titleBgSize  = self.viewData.titleBg:getContentSize()
    if (titileSize.width  + 60) > titleBgSize.width   then
        self.viewData.titleBg:setContentSize(cc.size(titileSize.width + 60  , titleBgSize.height ))
        title:setPosition(cc.p((titileSize.width + 60)/2 , titleBgSize.height/2))
    end
end

function ActivityPropExchangeListView:updateListSize(listSize)
    if listSize then
        local listBg        = self.viewData.listBg
        local gridView      = self.viewData.gridView

        local gridViewSize = cc.size(listSize.width * 0.99, listSize.height * 0.99)
        listBg:setContentSize(listSize)
        gridView:setContentSize(cc.size(listSize.width * 0.99, listSize.height * 0.99))

        display.commonUIParams(listBg, {po = cc.p(listBg:getPositionX(), listSize.height + 12)})
        display.commonUIParams(gridView, {po = cc.p(gridView:getPositionX(), gridViewSize.height + 12)})
    end
end

function ActivityPropExchangeListView:getViewData()
    return self.viewData
end

function ActivityPropExchangeListView:getArgs()
	return self.args
end

function ActivityPropExchangeListView:CloseHandler()
    local args = self:getArgs()
    PlayAudioByClickClose()
	-- local tag = args.tag
	local mediatorName = args.mediatorName

	local mediator = AppFacade.GetInstance():RetrieveMediator(mediatorName)
	if mediator then
		AppFacade.GetInstance():UnRegsitMediator(mediatorName)
	end

end

CreateCountDownLayer = function (parent, bgSize)
    -- 倒计时
    local counDownViewSize = cc.size(bgSize.width, 25)
    local counDownView = display.newLayer(bgSize.width / 2, bgSize.height * 0.9, {size = counDownViewSize, ap = display.CENTER})

    local leftTimeFont = fontWithColor(16, {text = __('活动剩余时间:')})
    local countDownFont = fontWithColor(10, {text = __('14天')})
    local leftTimeLabel = display.newLabel(0, 0, leftTimeFont)
    local countDownLabel = display.newLabel(0, 0, countDownFont)

    local leftTimeLabelSize = display.getLabelContentSize(leftTimeLabel)
    local countDownLabelSize = display.getLabelContentSize(countDownLabel)

    leftTimeLabel:setPosition(counDownViewSize.width/2 - countDownLabelSize.width/2, counDownViewSize.height/2)
    countDownLabel:setPosition(counDownViewSize.width/2 + leftTimeLabelSize.width/2, counDownViewSize.height/2)
    counDownView:addChild(leftTimeLabel)
    counDownView:addChild(countDownLabel)
    parent:addChild(counDownView)

    return {
        leftTimeLabel  = leftTimeLabel,
        countDownLabel = countDownLabel,
        counDownView   = counDownView,
    }

end

CreateListTiltleBg = function (parent, bgSize)
    -- list title
    local listTiltleBg = display.newImageView(_res(RES_DIR.bgTitle), bgSize.width / 2, bgSize.height * 0.84)
    parent:addChild(listTiltleBg)
    local listTiltleBgSize = listTiltleBg:getContentSize()

    -- bgTitleLine
    local listTitleLine = display.newImageView(_res(RES_DIR.bgTitleLine), listTiltleBgSize.width * 0.35, listTiltleBgSize.height / 2)
    listTiltleBg:addChild(listTitleLine)
    listTitleLine:setVisible(false)

    local needMaterialLabel = display.newLabel(listTiltleBgSize.width * 0.35 / 2, listTiltleBgSize.height / 2, fontWithColor(16, {text = __("需要材料")}))
    listTiltleBg:addChild(needMaterialLabel)

    local rewardlLabel = display.newLabel(listTiltleBgSize.width * 0.35 + listTiltleBgSize.width * 0.65 / 2, listTiltleBgSize.height / 2, fontWithColor(16, {text = __("奖励")}))
    listTiltleBg:addChild(rewardlLabel)

    return {
        listTiltleBg        = listTiltleBg,
        listTiltleBgSize    = listTiltleBgSize,
        listTitleLine       = listTitleLine,
        needMaterialLabel   = needMaterialLabel,
        rewardlLabel        = rewardlLabel,
    }
end

CreateListCell_ = function (tag)
    local cell = CGridViewCell:new()

    local bgImg = nil
    if tag == UI_TAG.PROP_EXCHANGE then
        bgImg = _res(RES_DIR.goodNormal)
    elseif tag == UI_TAG.FULL_SERVER then
        bgImg = _res(RES_DIR.FULL_SERVER_BG)
    elseif tag == UI_TAG.UNION_TASK then
        bgImg = _res(RES_DIR.UNION_TASK_BG)
    end

    -- bg
    local bg = display.newImageView(_res(RES_DIR.goodNormal), 0, 0)
    local bgSize = bg:getContentSize()
    -- dump(bgSize,'bgbgbg')
    local bgUnlock = display.newImageView(_res(RES_DIR.goodUnlock), 0, 0)
    local view = display.newLayer(0, 0,{size = bgSize})
    bg:setPosition(cc.p(bgSize.width / 2, bgSize.height / 2))

    bgUnlock:setPosition(cc.p(bgSize.width / 2, bgSize.height / 2))
    bgUnlock:setVisible(false)

    cell:setContentSize(bgSize)
    view:addChild(bg)
    view:addChild(bgUnlock, 2)
    cell:addChild(view)

    -- time bg
    local timeBg = display.newImageView(_res(RES_DIR.timeBg), bgSize.width / 2, bgSize.height, {ap = display.CENTER_TOP})
    view:addChild(timeBg)

    local timeBgSize = timeBg:getContentSize()
    local timeLb = display.newLabel(timeBgSize.width - 10, timeBgSize.height / 2, fontWithColor(18, {text = '', ap = display.RIGHT_CENTER}))
    timeBg:addChild(timeLb)

    -- 兑换
    local exchangeBtn = display.newButton(bgSize.width * 0.88, (bgSize.height - timeBgSize.height) / 2, {n = _res(RES_DIR.btn_orange)})
    display.commonLabelParams(exchangeBtn, fontWithColor(14, {text = __("兑换")}))
    view:addChild(exchangeBtn, 1)

    -- 已兑换
    local exchangeLbFont = fontWithColor(1, {fontSize = 22, color = '#452b1d', text = __('已兑换')})
    local exchangeLb = display.newLabel(bgSize.width * 0.88, (bgSize.height - timeBgSize.height) / 2,exchangeLbFont)
    exchangeLb:setVisible(false)
    view:addChild(exchangeLb)

    -- 材料层
    local materialLayerSize = cc.size(bgSize.width * 0.35, bgSize.height - timeBgSize.height)
    local materialLayer = display.newLayer(0, 0, {size = materialLayerSize, ap = display.LEFT_BOTTOM})
    view:addChild(materialLayer)

    -- 奖励层
    local rewardLayerSize = cc.size(bgSize.width * 0.88 - exchangeBtn:getContentSize().width / 2 - bgSize.width * 0.35, bgSize.height - timeBgSize.height)
    local rewardLayer = display.newLayer(bgSize.width * 0.35, 0, {size = rewardLayerSize, ap = display.LEFT_BOTTOM})
    view:addChild(rewardLayer)

    local iconSize = nil
    for i = 1 ,3 do
        local icon_Up = display.newImageView(RES_DIR.COOKING_LEVEL_UP, 0, 0)
        if iconSize == nil then
            iconSize = icon_Up:getContentSize()
        end
        display.commonUIParams(icon_Up, {po = cc.p(bgSize.width * 0.32 + (i - 0.5) * iconSize.width, bgSize.height/2)})
        view:addChild(icon_Up)
    end

    cell.viewData = {
        bg = bg,
        bgUnlock = bgUnlock,
        timeLb = timeLb,
        exchangeLb = exchangeLb,
        exchangeBtn = exchangeBtn,
        rewardLayer = rewardLayer,
        materialLayer = materialLayer
    }
    return cell
end

CreateTaskCell_ = function (tag)
    local cell = CGridViewCell:new()

    local bgImg = _res(RES_DIR.FULL_SERVER_BG)
    if tag == UI_TAG.UNION_TASK then
        bgImg = _res(RES_DIR.UNION_TASK_BG)
    end
    -- bg
    local bg = display.newImageView(bgImg, 0, 0)
    local bgSize = bg:getContentSize()
    local view = display.newLayer(0, 0,{size = bgSize})
    bg:setPosition(cc.p(bgSize.width / 2, bgSize.height / 2))

    cell:setContentSize(bgSize)
    view:addChild(bg)
    cell:addChild(view)

    local nameLabel = display.newLabel(20, bgSize.height - 5, {ap = display.LEFT_TOP, fontSize = 22, color = '#5b3c25', font = TTF_GAME_FONT, ttf = true})
    view:addChild(nameLabel)
    nameLabel:setVisible(false)

    local descLabel = display.newLabel(20, bgSize.height - 5, fontWithColor(16, {ap = display.LEFT_TOP}))
    view:addChild(descLabel)

    local descLabelSize = display.getLabelContentSize(descLabel)
    local progressLabel = display.newLabel(descLabel:getPositionX() + descLabelSize.width + 10, descLabel:getPositionY(), fontWithColor(10, {ap = display.LEFT_TOP}))
    view:addChild(progressLabel)

    local propLayer = display.newLayer(0, 0, {size = bgSize, ap = display.LEFT_BOTTOM})
    view:addChild(propLayer)

    local button = display.newButton(bgSize.width - 10, bgSize.height * 0.4, {n = _res(RES_DIR.btn_orange), ap = display.RIGHT_CENTER})
    display.commonLabelParams(button, fontWithColor(14, {text = __("领取")}))
    view:addChild(button)

    local alreadyReceived = display.newButton(button:getPositionX(), button:getPositionY(), {n = _res('ui/common/activity_mifan_by_ico.png'), animate = false, enable = false , ap = display.RIGHT_CENTER})
	display.commonLabelParams(alreadyReceived, fontWithColor(14, {fontSize = 22, text = __('已领取')}))
    alreadyReceived:setScale(0.9)
    alreadyReceived:setVisible(false)
	view:addChild(alreadyReceived)

    cell.viewData = {
        nameLabel          = nameLabel,
        descLabel          = descLabel,
        progressLabel      = progressLabel,
        propLayer          = propLayer,
        button             = button,
        alreadyReceived    = alreadyReceived,
    }
    return cell
end

function ActivityPropExchangeListView:CreateListCell(tag)
	return CreateListCell_(tag)
end

function ActivityPropExchangeListView:CreateTaskCell(tag)
    return CreateTaskCell_(tag)
end

return ActivityPropExchangeListView
