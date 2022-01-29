local CommonDialog = require('common.CommonDialog')
local MemberShopView = class('MemberShopView', CommonDialog)
local GoodNode = require('common.GoodNode')

local GOOD_SCALE = 0.9  -- 道具缩放
local MAX_COL = 2       -- 最大列数
local RES_DIR = {
	bg 					= "ui/common/common_bg_4.png",
	contentTitleBg 		= "ui/common/common_title_5.png",
	contentTitleBgY 	= "ui/common/common_title_5_yellow.png",
	content_bg      	= "ui/common/commcon_bg_text.png",
	btn_orange      	= "ui/common/common_btn_orange.png",
	btn_default     	= "ui/common/common_btn_white_default.png",
	splitLine       	= "ui/home/commonShop/monthcard_tool_split_line.png",
	downcountBg     	= "ui/common/card_bg_time.png",
	contentSplitLine    = "ui/common/card_line.png",
	commonArrow         = "ui/common/common_arrow.png",
	add                 = "ui/home/kitchen/kitchen_ico_add.png",
}
-- 创建通用 title
local commTitle = function (text, x, y, isYellow)
	local path = isYellow and RES_DIR.contentTitleBgY or RES_DIR.contentTitleBg
	local titleBg = display.newImageView(_res(path), 0, 0 , {scale9 = true })
	local titleBgSize = titleBg:getContentSize()
	local layout = display.newLayer(x, y, {size = titleBgSize})
	layout:addChild(titleBg)

	local titleLabel = display.newLabel(titleBgSize.width/2, titleBgSize.height/2, fontWithColor(16, {text = text}))
	titleBg:addChild(titleLabel)

	local titleLabelSize = display.getLabelContentSize(titleLabel)
	local titleBgReqW =  titleLabelSize.width + 60 > 280 and 280 or titleLabelSize.width + 60
	if titleBgReqW> titleBgSize.width  then
		display.commonLabelParams(titleLabel ,{text = text , reqW = 230})
		titleBg:setContentSize(cc.size(titleBgReqW  ,titleBgSize.height ) )
		titleLabel:setPosition(cc.p(titleBgReqW/2 ,titleBgSize.height/2 ))
	end
	return layout
end

-- 用于计算道具坐标
local getGoodPos = function (index, goodNodeSize, goodX, goodY, col)
	local goodW, goodH = goodNodeSize.width, goodNodeSize.height

	local realIndex = (index - 1) % MAX_COL + 1
	local goodOffsetX = goodW
	local startX = goodX - (col - 1) * (goodOffsetX / 2)
	local x = startX + (realIndex - 1) * goodOffsetX

	local curRow = math.floor((index - 1) / MAX_COL)

	local goodOffsetY = goodH
	local y = goodY - curRow * goodOffsetY
	return cc.p(x, y)
end

-- 创建道具
local createProp = function (parent, goodX, goodY, rewards)
    if not rewards then rewards = {} end
	local goodNodeSize = nil
	local goodGap = 10
	local goodCount = #rewards
	local col = (goodCount > MAX_COL) and MAX_COL or goodCount
	local row = math.floor((goodCount - 1) / MAX_COL) + 1
	-- local goodNode = 1
	local rewardNodes = {}
	for i,v in ipairs(rewards) do
		local function callBack(sender)
			AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
		end
		local goodNode = GoodNode.new({id = v.goodsId, amount = v.num, showAmount = true, callBack = callBack})
		goodNode:setScale(GOOD_SCALE)

		if goodNodeSize == nil then goodNodeSize = goodNode:getContentSize() end

		goodNode:setPosition(getGoodPos(i, goodNodeSize, goodX, goodY, col))
		parent:addChild(goodNode)

		goodNode.arrow = display.newImageView(_res(RES_DIR.commonArrow), goodNode:getContentSize().width / 2 * GOOD_SCALE, goodNode:getContentSize().height / 2 * GOOD_SCALE)
		goodNode.arrow:setVisible(false)
		goodNode:addChild(goodNode.arrow,10)
		if v.mustGoodState ~= nil then
			goodNode:setState(v.mustGoodState)
			goodNode.arrow:setVisible(v.mustGoodState == -1)
		end
		table.insert(rewardNodes, goodNode)
	end
    if goodNodeSize == nil then goodNodeSize = cc.size(0,0) end
	return {row = row, col = col, goodNodeSize = goodNodeSize, rewardNodes = rewardNodes}
end

function MemberShopView:InitialUI()
	local vipData = self:getArgs().vipData
	local function CreateView()

		-- bg
		local bgSize = cc.size(584, 651)
		local bg = display.newImageView(_res(RES_DIR.bg), 0, 0,
			{scale9 = true, size = bgSize})
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg, 5)

		-- title
		local titleFont = fontWithColor(2, {color = '5b3c25'})
		local titleLabel = display.newLabel(bgSize.width / 2, bgSize.height * 0.94, titleFont)
		view:addChild(titleLabel, 5)

		-- splitLine
		local splitLine = display.newImageView(_res(RES_DIR.splitLine), bgSize.width / 2, bgSize.height * 0.9)
		view:addChild(splitLine, 5)

		-- content bg
		local contentBgSize = cc.size(568, 446)
		local contentBg = display.newImageView(_res(RES_DIR.content_bg), (bgSize.width - contentBgSize.width) / 2, bgSize.height * 0.19,
			{scale9 = true, size = contentBgSize, ap = display.LEFT_BOTTOM})
		-- display.commonUIParams(contentBg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(contentBg, 5)

		local scrollViewSize = cc.size(contentBgSize.width * 0.98, contentBgSize.height * 0.98)
		-- local contentViewSize = cc.size(scrollViewSize.width, scrollViewSize.height)
		local contentView = display.newLayer(0, 0, {size = scrollViewSize, ap = display.LEFT_BOTTOM})

		-- dump(contentView:getContentSize())

		local scrollView = CScrollView:create(scrollViewSize)
		scrollView:setDirection(eScrollViewDirectionVertical)
		scrollView:setAnchorPoint(display.CENTER_BOTTOM)
		scrollView:setPosition(cc.p(bgSize.width / 2, bgSize.height * 0.19))
		-- scrollView:setBackgroundColor(cc.c3b(100,100,200))
		view:addChild(scrollView, 5)
		scrollView:setContainerSize(scrollViewSize)
		scrollView:setContentOffset(cc.p(0, 0))
		scrollView:getContainer():addChild(contentView)

		-- 购买立即获得
		local mustGoodX = contentBgSize.width * 0.25
		local mustGoodY = contentBgSize.height * 0.77
		local dailyRewardTitle = commTitle(__('购买立即获得'), mustGoodX, contentBgSize.height * 0.94, true)
		contentView:addChild(dailyRewardTitle)
		
		local mustRewards =  {{goodsId = checktable(GAME_MODULE_OPEN).DUAL_DIAMOND and PAID_DIAMOND_ID or DIAMOND_ID, type = 90, num = vipData.diamond, mustGoodState = vipData.mustGoodState}}
		local mustGoodParams = createProp(contentView, mustGoodX, mustGoodY, mustRewards)

		-- display.newLayer((bgSize.width - contentBgSize.width) / 2, bgSize.height * 0.19, {size = contentBgSize, ap = display.LEFT_BOTTOM})
		-- 每日奖励
		local goodX = contentBgSize.width * 0.75
		local goodY = contentBgSize.height * 0.77
		local dailyRewardTitle = commTitle(__('每日奖励'), goodX, contentBgSize.height * 0.94)
		contentView:addChild(dailyRewardTitle)

		local rewards = vipData.rewards
		local dailyGoodParams = createProp(contentView, goodX, goodY, rewards)

		local goodNodeSize = dailyGoodParams.goodNodeSize
		local realCol = mustGoodParams.col + dailyGoodParams.col
		local realRow = math.max(mustGoodParams.row, dailyGoodParams.row)

		-- 加号
		local addPosX = (realCol % 2 == 0) and contentBgSize.width / 2 or (contentBgSize.width  / 2 - goodNodeSize.height * 0.25)
		local add = display.newImageView(_res(RES_DIR.add), addPosX, goodY - (realRow - 1) * goodNodeSize.height / 2)
		contentView:addChild(add)

		local listOffsetY = realRow * goodNodeSize.height * GOOD_SCALE

		local rewardTipsLable = display.newLabel(contentBgSize.width / 2, contentBgSize.height * 0.77 - listOffsetY + 10, fontWithColor(15, {text = __("(每日奖励可以在日常任务中领取)"), hAlign = display.TAC,w = 540 , color = '#b1b1b1'}))
		contentView:addChild(rewardTipsLable)

		-- 内容分割线
		-- local contentSplitLinePosY = rewardTipsLable:getPositionY() - display.getLabelContentSize(rewardTipsLable).height - 10
		-- local contentSplitLine = display.newImageView(_res(RES_DIR.contentSplitLine), contentBgSize.width / 2, contentSplitLinePosY)
		-- contentView:addChild(contentSplitLine)

		local contentSplitLinePosY =  rewardTipsLable:getPositionY() - 30
		local contentSplitLine = display.newImageView(_res(RES_DIR.contentSplitLine), contentBgSize.width / 2, contentSplitLinePosY)
		contentSplitLine:setScaleY(2)
		contentView:addChild(contentSplitLine)

		-- 御史特权
		local privilegeTitlePosY = contentSplitLinePosY - 30
		local privilegeTitle = commTitle(__('御侍特权'), contentBgSize.width / 2, privilegeTitlePosY)
		contentView:addChild(privilegeTitle)

		local contentTopHeight = dailyRewardTitle:getContentSize().height * 2 + listOffsetY + display.getLabelContentSize(rewardTipsLable).height + 100
		-- local l = display.newLayer(scrollViewSize.width/2,scrollViewSize.height, {size = cc.size(scrollViewSize.width, height),color=cc.c3b(100,100,200),ap = display.CENTER_TOP})
		-- contentView:addChild(l)
		-- local listSize = cc.size(contentBgSize.width * 0.8, privilegeTitlePosY -  40--[[(2 - (realRow - 1)) * goodNodeSize.height * GOOD_SCALE]])
        -- local cellSize = cc.size(contentBgSize.width * 0.8, 30)
		-- local tableView = CTableView:create(listSize)
        -- tableView:setSizeOfCell(cellSize)
        -- tableView:setDirection(eScrollViewDirectionVertical)
        -- -- tableView:setBackgroundColor(cc.c3b(100,100,200))
        -- tableView:setAnchorPoint(cc.p(0, 0))
        -- tableView:setPosition(cc.p((contentBgSize.width - listSize.width)/2, goodNodeSize.height * 0.2))
		-- contentView:addChild(tableView)

		-- local listView = CListView:create(listSize)
        -- listView:setPosition(cc.p((contentBgSize.width - listSize.width)/2, goodNodeSize.height * 0.2))
        -- listView:setBounceable(true)
		-- listView:setAnchorPoint(cc.p(0, 0))
        -- contentView:addChild(listView)
		-- color=cc.c3b(100,100,200)
		local descLayerSize = cc.size(scrollViewSize.width, 20 * 30)
		local descLayer = display.newLayer(contentBgSize.width * 0.5, privilegeTitlePosY -  40, {size = descLayerSize, ap = display.CENTER_TOP})
		contentView:addChild(descLayer)

		-- 购买 取消 按钮
		local cancelBtn = display.newButton(bgSize.width * 0.3, 80, { n = _res(RES_DIR.btn_default)})
        display.commonLabelParams(cancelBtn, fontWithColor(14, {text = __("取消")}))
        view:addChild(cancelBtn, 5)

		local buyBtn = display.newButton(bgSize.width * 0.7, cancelBtn:getPositionY(), { n = _res(RES_DIR.btn_orange)})
        display.commonLabelParams(buyBtn, fontWithColor(14, {text = __("购买")}))
        view:addChild(buyBtn, 5)

		local downCountBgSize = cc.size(bgSize.width, 50)
		local downCountLayer = display.newLayer(bgSize.width / 2, 0, {ap = display.CENTER_BOTTOM, size = cc.size(bgSize.width, 50)})
        view:addChild(downCountLayer, 5)
		downCountLayer:setVisible(false)

		local leftTimeFont = fontWithColor(14, {fontSize = 28, color = 'ffffff', outline = '5b3c25', outlineSize = 1, text = __('剩余时间:')})
		local countDownFont = fontWithColor(14, {fontSize = 28, color = 'ffe081', outline = '5b3c25', outlineSize = 1, text = '29天'})
		local leftTimeLabel = display.newLabel(0, 0, leftTimeFont)
        local countDownLabel = display.newLabel(0, 0, countDownFont)

		local leftTimeLabelSize = display.getLabelContentSize(leftTimeLabel)
		local countDownLabelSize = display.getLabelContentSize(countDownLabel)

        leftTimeLabel:setPosition(405 - countDownLabelSize.width/2, downCountBgSize.height / 2)
        countDownLabel:setPosition(405 + leftTimeLabelSize.width/2, downCountBgSize.height / 2)
		downCountLayer:addChild(leftTimeLabel)
		downCountLayer:addChild(countDownLabel)

		-- local downCountBgSize = downCountBg:getContentSize()

		-- local leftTimeFont = fontWithColor(14, {fontSize = 28, color = 'ffffff', outline = '5b3c25', outlineSize = 1, text = __('剩余时间:')})
		-- local countDownFont = fontWithColor(14, {fontSize = 28, color = 'ffe081', outline = '5b3c25', outlineSize = 1, text = ''})
		-- local leftTimeLabel = display.newLabel(0, 0, leftTimeFont)
        -- local countDownLabel = display.newLabel(0, 0, countDownFont)

		-- local leftTimeLabelSize = display.getLabelContentSize(leftTimeLabel)
		-- local countDownLabelSize = display.getLabelContentSize(countDownLabel)

        -- leftTimeLabel:setPosition(downCountBgSize.width / 2 - countDownLabelSize.width/2, downCountBgSize.height / 2)
        -- countDownLabel:setPosition(downCountBgSize.width / 2 + leftTimeLabelSize.width/2, downCountBgSize.height / 2)
		-- downCountBg:addChild(leftTimeLabel)
		-- downCountBg:addChild(countDownLabel)
		return {
			view               = view,
			titleLabel         = titleLabel,
			scrollView         = scrollView,
			contentView        = contentView,
			contentTopHeight   = contentTopHeight,
			descLayer          = descLayer,
			mustRewardNodes    = mustGoodParams.rewardNodes,
			buyBtn             = buyBtn,
			cancelBtn          = cancelBtn,
			downCountLayer     = downCountLayer,
			leftTimeLabel      = leftTimeLabel,
			countDownLabel     = countDownLabel,

			bgSize             = bgSize,
			downCountBgSize    = downCountBgSize,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)


end

function MemberShopView:getArgs()
	return self.args
end

function MemberShopView:CloseHandler()
	local args = self:getArgs()
	-- local tag = args.tag
	local mediatorName = args.mediatorName

	local mediator = AppFacade.GetInstance():RetrieveMediator(mediatorName)
	if mediator then
		AppFacade.GetInstance():UnRegsitMediator(mediatorName)
	end

end


return MemberShopView
