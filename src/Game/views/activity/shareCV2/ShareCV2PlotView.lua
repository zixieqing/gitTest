---@class ShareCV2PlotView
local ShareCV2PlotView = class('ShareCV2PlotView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.ShareCV2PlotView'
	node:enableNodeEvents()
	return node
end)
local newLayer = display.newLayer
local newButton = display.newButton
local newLabel = display.newLabel
local newImageView = display.newImageView
local RES_DICT = {
	CVSHARE_TASK_BG_LOCK          = _res('ui/home/activity/cv2/cvshare_task_bg_lock.png'),
	COMMON_BTN_BLUE_DEFAULT       = _res('ui/common/common_btn_blue_default.png'),
	CVSHARE_TASK_BG               = _res('ui/home/activity/cv2/cvshare_task_bg.png'),
	CVSHARE_TAB_BTN_SELECT        = _res('ui/home/activity/cv2/cvshare_tab_btn_select.png'),
	CVSHARE_TAB_BTN_SELECT_1      = _res('ui/home/activity/cv2/cvshare_tab_btn_select_1.png'),
	CVSHARE_TITLE                 = _res('ui/home/activity/cv2/cvshare_title.png'),
	CVSHARE_TITLE_REWARD          = _res('ui/home/activity/cv2/cvshare_title_reward.png'),
	CVSHARE_BG                    = _res('ui/home/activity/cv2/cvshare_bg.png'),
	CVSHARE_BG_WORDS              = _res('ui/home/activity/cv2/cvshare_bg_words.png'),
	CVSHARE_BG_PLOT               = _res('ui/home/activity/cv2/cvshare_bg_plot.png'),
	CVSHARE_TAB_BTN_DEFAULT       = _res('ui/home/activity/cv2/cvshare_tab_btn_default.png'),
	CVSHARE_TAB_BTN_LOCK          = _res('ui/home/activity/cv2/cvshare_tab_btn_lock.png'),
	SHOP_RECHARGE_LIGHT_RED       = _res('ui/home/commonShop/shop_recharge_light_red.png'),
	CVSHARE_TASK_REWARD_BG        = _res('ui/home/activity/cv2/cvshare_task_reward_bg.png'),
	LUNATOWER_ICON_ARROW          = _res('ui/home/activity/cv2/lunatower_icon_arrow.png'),
	GOODS_ICON_195149             = _res('arts/goods/goods_icon_195149.png'),
	COMMON_HINT_CIRCLE_RED_ICO    = _res('ui/common/common_hint_circle_red_ico.png') ,
	COMMON_BTN_TIPS               = _res('ui/common/common_btn_tips')

}
function ShareCV2PlotView:ctor( ... )
	self:InitUI()
end

function ShareCV2PlotView:InitUI()
	local colorLayer =  newLayer(display.cx , display.cy ,
			{ ap = display.CENTER, color = cc.c4b(0,0,0,175), size = display.size , enable = true })
	self:addChild(colorLayer)

	local closeBtn = newButton(display.cx , display.cy  , { size = display.size , ap = display.CENTER })
	self:addChild(closeBtn)

	local bgLayout = newLayer(display.cx , display.cy ,
			{ ap = display.CENTER, size = cc.size(1163, 669) })
	self:addChild(bgLayout)
	local sawllowLayer = newButton(1163 /2 , 669/2 , { size =  cc.size(1163, 669) ,enable = true  })
	bgLayout:addChild(sawllowLayer)
	local bgImage = newImageView(RES_DICT.CVSHARE_BG, 592, 326,
			{ ap = display.CENTER, tag = 7, enable = false })
	bgLayout:addChild(bgImage)

	local titleDescrLayout = newButton(19, 603,
			{ ap = display.LEFT_CENTER, size = cc.size(761, 52) })
	bgLayout:addChild(titleDescrLayout)

	local titleDescrImage = newImageView(RES_DICT.CVSHARE_TITLE, 0, 26,
			{ ap = display.LEFT_CENTER, tag = 28, enable = false })
	titleDescrLayout:addChild(titleDescrImage)

	local titleLabel = newLabel(30, 26,
			{ ap = display.LEFT_CENTER, color = '#874311', text = __('分享情节'), fontSize = 26, tag = 29 })
	titleDescrLayout:addChild(titleLabel)

	--local tipBtn = newButton(200 ,26 , { n = RES_DICT.COMMON_BTN_TIPS } )
	--titleDescrLayout:addChild(tipBtn)

	local completeLabel = newLabel(963, 586,
			{ ap = display.CENTER, color = '#d23d3d', text = __('分享语音领奖励'), fontSize = 20, tag = 9 })
	bgLayout:addChild(completeLabel)

	local rewardTitle = newButton(963, 616 , { n = RES_DICT.CVSHARE_TITLE_REWARD })
	bgLayout:addChild(rewardTitle)

	display.commonLabelParams(rewardTitle , {text = __('奖励') , fontSize = 24 ,  color = "#5b3c25"})

	local rightLayout = newLayer(968, 566,
			{ ap = display.CENTER_TOP, size = cc.size(369, 550), enable = true })
	bgLayout:addChild(rightLayout)

	local rewardBgImage = newImageView(RES_DICT.CVSHARE_TASK_REWARD_BG, 184, 275,
			{ ap = display.CENTER, tag = 35, enable = false })
	rightLayout:addChild(rewardBgImage)

	local cgrideCellSize = cc.size(355, 95)
	local grideView      = CGridView:create(cc.size(369, 480))
	grideView:setSizeOfCell(cgrideCellSize)
	grideView:setColumns(1)
	grideView:setAutoRelocate(true)
	grideView:setAnchorPoint(display.CENTER_TOP )
	grideView:setPosition(369 / 2+ 6 , 550 -5  )
	rightLayout:addChild(grideView)
	grideView:setTag(10)

	local centerLayout = newLayer(266, 16,
			{ ap = display.LEFT_BOTTOM, size = cc.size(513, 550)})
	bgLayout:addChild(centerLayout)

	local plotBgImage = newImageView(RES_DICT.CVSHARE_BG_PLOT, 256, 275,
			{ ap = display.CENTER, tag = 63, enable = false })
	centerLayout:addChild(plotBgImage)

	local plotWorldImage = newImageView(RES_DICT.CVSHARE_BG_WORDS, 256, 324,
			{ ap = display.CENTER, tag = 64, enable = false })
	centerLayout:addChild(plotWorldImage)


	local listSize = cc.size( 440, 400)
	local plotWordLayout = newLayer(0,0, { size = listSize })
	local plotName = newLabel(listSize.width/2, listSize.height,
			{ ap = display.CENTER_TOP, color = '#5b3c25', text = "", fontSize = 22, tag = 65 })
	plotWordLayout:addChild(plotName)
	local plotDescr = newLabel(43, 477,
			{ ap = display.LEFT_TOP, color = '#5b3c25', w = 440,hAlign= display.TAL ,  text = "", fontSize = 22, tag = 66 })
	plotWordLayout:addChild(plotDescr)



	local wordList = CListView:create(listSize)
	wordList:setPosition(cc.p(256, 527))
	wordList:setDirection(eScrollViewDirectionVertical)
	wordList:setAnchorPoint(display.CENTER_TOP)
	wordList:setBounceable(true)
	centerLayout:addChild(wordList)
	wordList:insertNodeAtLast(plotWordLayout)


	local firstShareCV = newLabel(140, 59,
			{ ap = display.RIGHT_CENTER, color = '#5b3c25', text = __('首次分享'), fontSize = 24, tag = 67 })
	centerLayout:addChild(firstShareCV)

	local shareCVBtn = newButton(434, 58, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_BLUE_DEFAULT, d = RES_DICT.COMMON_BTN_BLUE_DEFAULT, s = RES_DICT.COMMON_BTN_BLUE_DEFAULT, scale9 = true, size = cc.size(123, 62), tag = 68 })
	display.commonLabelParams(shareCVBtn, fontWithColor(14, {text = __('分享'), fontSize = 24, color = '#ffffff'}))
	centerLayout:addChild(shareCVBtn)
	---@type GoodNode[]
	local goodNodes = {}
	for i = 1, 2 do
		local goodNode = require("common.GoodNode").new({
			goodsId = GOLD_ID , showAmount = true , num = 0
		})
		goodNodes[#goodNodes+1] = goodNode
		centerLayout:addChild( goodNode)
		goodNode:setScale(0.8)
		goodNode:setPosition(150+ (i -0.5 ) * 100 , 58 )
	end
	local pgrideCellSize = cc.size(198, 90)
	local pgrideView     = CGridView:create(cc.size(369, 480))
	pgrideView:setSizeOfCell(pgrideCellSize)
	pgrideView:setColumns(1)
	pgrideView:setAutoRelocate(true)
	pgrideView:setAnchorPoint(display.CENTER_TOP )
	pgrideView:setPosition( 220 , 566  )
	bgLayout:addChild(pgrideView)

	closeBtn:setEnabled(false)
	colorLayer:setOpacity(0)
	self:setOpacity(0)
	bgLayout:setScale(0.95)

	self.viewData =  {
		bgLayout                = bgLayout,
		bgImage                 = bgImage,
		colorLayer              = colorLayer,
		plotWordLayout          = plotWordLayout ,
		titleDescrLayout        = titleDescrLayout,
		titleDescrImage         = titleDescrImage,
		titleLabel              = titleLabel,
		completeLabel           = completeLabel,
		rightLayout             = rightLayout,
		rewardBgImage           = rewardBgImage,
		centerLayout            = centerLayout,
		plotBgImage             = plotBgImage,
		plotWorldImage          = plotWorldImage,
		plotName                = plotName,
		plotDescr               = plotDescr,
		firstShareCV            = firstShareCV,
		shareCVBtn              = shareCVBtn,
		pgrideView              = pgrideView,
		grideView               = grideView,
		closeBtn                = closeBtn,
		listSize                = listSize ,
		goodNodes               = goodNodes,
		wordList                = wordList ,
	}
end
function ShareCV2PlotView:CreatePlotCell()
	local cellSize =  cc.size(198, 90)
	local cell =  CGridViewCell:new()
	cell:setCascadeOpacityEnabled(true)
	local plotLayout = newButton(cellSize.width/2, cellSize.height/2 ,
			{ ap = display.CENTER, size = cc.size(188, 81)})
	cell:addChild(plotLayout)
	local plotBtn = newImageView(RES_DICT.CVSHARE_TAB_BTN_DEFAULT, 93, 39,
			{ ap = display.CENTER, tag = 58, enable = false })
	plotLayout:addChild(plotBtn)

	local unlockLabel = newLabel(94, 40,
			{ ap = display.CENTER, color = '#5b3c25', text = "", fontSize = 24, tag = 59 })
	plotLayout:addChild(unlockLabel,10)

	local lockLabel = newLabel(94, 40,
			{ ap = display.CENTER, color = '#5b3c25', text = "", fontSize = 24, tag = 60 })
	plotLayout:addChild(lockLabel)

	local plotSelectImage = newButton( 94, 40,
			{ ap = display.CENTER, tag = 61, enable = false , n =  RES_DICT.CVSHARE_TAB_BTN_SELECT })
	plotLayout:addChild(plotSelectImage)
	plotSelectImage:setVisible(false)
	local plotSelectImageSize = plotSelectImage:getContentSize()
	local plotSelectBtn  = newImageView(RES_DICT.CVSHARE_TAB_BTN_SELECT_1, plotSelectImageSize.width/2, plotSelectImageSize.height/2,
			{ ap = display.CENTER, tag = 58, enable = false})
	plotSelectImage:addChild(plotSelectBtn)

	local arrowImage = newImageView(RES_DICT.LUNATOWER_ICON_ARROW , 228 ,  40 , {ap = display.RIGHT_CENTER})
	plotSelectImage:addChild(arrowImage)

	local redImage = newImageView(RES_DICT.COMMON_HINT_CIRCLE_RED_ICO ,178 , 70  )
	plotLayout:addChild(redImage)
	redImage:setVisible(false)
	cell.viewData = {
		plotBtn         = plotBtn,
		plotLayout         = plotLayout,
		unlockLabel     = unlockLabel,
		lockLabel       = lockLabel,
		arrowImage     = arrowImage ,
		redImage       = redImage ,
		plotSelectImage = plotSelectImage 
	}
	return  cell
end
function ShareCV2PlotView:EnterAction()
	self:runAction(
		cc.Spawn:create(
			cc.TargetedAction:create(self.viewData.colorLayer ,
				cc.Sequence:create(
					cc.FadeTo:create(0.3 , 175 ) ,
					cc.DelayTime:create(0.2)
				)
			),
			cc.Sequence:create(
				cc.FadeIn:create(0.3) ,
				cc.DelayTime:create(0.2)
			),
			cc.TargetedAction:create(self.viewData.bgLayout ,
				cc.EaseSineInOut:create(
					cc.Sequence:create(
						cc.ScaleTo:create(0.4 , 1.05) ,
						cc.ScaleTo:create(0.1 , 1)  ,
						cc.CallFunc:create(
							function()
								self.viewData.closeBtn:setEnabled(true)
							end
						)
					)
				)
			)
		)
	)
end
function ShareCV2PlotView:UpdateCell( cell , data)
	local viewData = cell.viewData
	if checkint(data.isOpened) == 1 then
		viewData.plotBtn:setTexture(RES_DICT.CVSHARE_TAB_BTN_DEFAULT)
		display.commonLabelParams(viewData.unlockLabel , { text = data.name})
		viewData.lockLabel:setVisible(false)
		viewData.unlockLabel:setVisible(true)
	else
		viewData.plotBtn:setTexture(RES_DICT.CVSHARE_TAB_BTN_LOCK)
		viewData.plotSelectImage:setVisible(false)
		viewData.lockLabel:setVisible(true)
		viewData.unlockLabel:setVisible(false)
		display.commonLabelParams(viewData.lockLabel , { w = 150 ,hAlign = display.TAC ,  text = string.fmt(__('第_day_天解锁') , {_day_ =  data.openDay }) })
	end
end

function ShareCV2PlotView:UpdateCenterUI(data )
	if checkint(data.hasDrawnShareRewards) == 1 then
		for i, v in pairs(self.viewData.goodNodes) do
			v:setVisible(false)
		end
		self.viewData.firstShareCV:setVisible(false)
	else
		for i, v in pairs(self.viewData.goodNodes) do
			v:setVisible(false)
		end
		for i, v in pairs(data.shareRewards) do
			if self.viewData.goodNodes[i] then
				self.viewData.goodNodes[i]:setVisible(true)
				self.viewData.goodNodes[i]:RefreshSelf(v)
			end
		end
		self.viewData.firstShareCV:setVisible(true)
	end
	display.commonLabelParams(self.viewData.plotName , { text = data.name })
	display.commonLabelParams(self.viewData.plotDescr , { text = data.displayWords })
	local plotDescrSize = display.getLabelContentSize(self.viewData.plotDescr)
	local plotWordSize = nil
	if (plotDescrSize.height + 40) > self.viewData.listSize.height  then
		plotWordSize = cc.size( 440 , plotDescrSize.height + 40)
	else
		plotWordSize = self.viewData.listSize
	end
	self.viewData.plotWordLayout:setContentSize(plotWordSize)
	self.viewData.plotName:setPosition(plotWordSize.width/2 , plotWordSize.height)
	self.viewData.plotDescr:setPosition( 0 , plotWordSize.height - 40 )
	self.viewData.wordList:reloadData()
	self.viewData.wordList:setContentOffsetToTop()
end
function ShareCV2PlotView:UpdatePlotCellSelect(preIndex ,currentIndex )
	local viewData = self.viewData
	local preCell = viewData.pgrideView:cellAtIndex(preIndex -1)
	if preCell and (not tolua.isnull(preCell)) then
		preCell.viewData.plotSelectImage:setVisible(false)
	end
	local currentCell = viewData.pgrideView:cellAtIndex(currentIndex -1)
	if currentCell and (not tolua.isnull(currentCell)) then
		currentCell.viewData.plotSelectImage:setVisible(true)
	end
end

---SetCellRedIsVisible 控制cell 的红点显示
---@param index number
---@param isVisible boolean
function ShareCV2PlotView:SetCellRedIsVisible(index , isVisible )
	local viewData = self.viewData
	local cell = viewData.pgrideView:cellAtIndex(index -1)
	cell.viewData.redImage:setVisible(isVisible)
end

return ShareCV2PlotView