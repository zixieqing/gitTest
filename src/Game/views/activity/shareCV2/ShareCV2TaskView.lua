---@class ShareCV2TaskView
local ShareCV2TaskView = class('ShareCV2TaskView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.ShareCV2TaskView'
	node:enableNodeEvents()
	return node
end)
local newLayer = display.newLayer
local newButton = display.newButton
local newLabel = display.newLabel
local newImageView = display.newImageView
local RES_DICT = {
	CVSHARE_CV_FRAME              = _res('ui/home/activity/cv2/cvshare_cv_frame.png'),
	CVSHARE_TITLE                 = _res('ui/home/activity/cv2/cvshare_title.png'),
	CVSHARE_BG                    = _res('ui/home/activity/cv2/cvshare_bg.png'),
	CVSHARE_BTN_GOCOMPLETE        = _res('ui/home/activity/cv2/cvshare_btn_gocomplete.png'),
	BG                            = _res('ui/home/activity/cv2/photoSe/bg.png'),
	CVSHARE_TASK_REWARD_BG        = _res('ui/home/activity/cv2/cvshare_task_reward_bg.png'),
	CG_PUZZLE_ICO_COMPLETED_1     = _res('ui/home/activity/cv2/CG_puzzle_ico_completed_1.png'),
	CVSHARE_TITLE_REWARD          = _res('ui/home/activity/cv2/cvshare_title_reward.png'),
	COMMON_BTN_ORANGE             = _res('ui/common/common_btn_orange.png'),
	COMMON_BTN_BLUE_DEFAULT       = _res('ui/common/common_btn_blue_default.png'),
	POINT_PROGRESSBAR_BG 	 	  = _res('ui/home/activity/murder/murder_boss_rewards_bar_grey.png'),
	POINT_PROGRESSBAR    	 	  = _res('ui/home/activity/murder/murder_boss_rewards_bar_active.png'),
	COMMON_BTN_TIPS               =_res('ui/common/common_btn_tips')
}
function ShareCV2TaskView:ctor( ... )
	self:InitUI()
end

function ShareCV2TaskView:InitUI()

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

	local titleDescrLayout = newLayer(19, 603,
			{ ap = display.LEFT_CENTER,  size = cc.size(761, 52)})
	bgLayout:addChild(titleDescrLayout)

	local titleDescrImage = newImageView(RES_DICT.CVSHARE_TITLE, 0, 26,
			{ ap = display.LEFT_CENTER, tag = 6, enable = false })
	titleDescrLayout:addChild(titleDescrImage)

	local titleLabel = newLabel(30, 26,
	                            { ap = display.LEFT_CENTER, color = '#874311', text = __('收集拼图'), fontSize = 30, tag = 8 })
	titleDescrLayout:addChild(titleLabel)
	local titleLabelSize = display.getLabelContentSize(titleLabel)
	local tipBtn = newButton(titleLabelSize.width + 60 , 26 , { n = RES_DICT.COMMON_BTN_TIPS } )
	titleDescrLayout:addChild(tipBtn)

	local completeLabel = newLabel(963, 586,
			{ ap = display.CENTER, color = '#d23d3d', text = __('完成任务领取碎片宝箱'),w = 350 , hAlign = display.TAC ,   fontSize = 20, tag = 9 })
	bgLayout:addChild(completeLabel)

	local rewardTitle = newButton(963, 616 , { n = RES_DICT.CVSHARE_TITLE_REWARD })
	bgLayout:addChild(rewardTitle)
	display.commonLabelParams(rewardTitle , {text = __('奖励') , fontSize = 24 ,  color = "#5b3c25"})

	local rightLayout = newLayer(968, 566,
			{ ap = display.CENTER_TOP, size = cc.size(369, 550)})
	bgLayout:addChild(rightLayout)

	local rewardBgImage = newImageView(RES_DICT.CVSHARE_TASK_REWARD_BG, 184, 275,
			{ ap = display.CENTER, tag = 14, enable = false })
	rightLayout:addChild(rewardBgImage)

	local completeBtn = newButton(184, 30, { ap = display.CENTER ,  n = RES_DICT.CVSHARE_BTN_GOCOMPLETE, d = RES_DICT.CVSHARE_BTN_GOCOMPLETE, s = RES_DICT.CVSHARE_BTN_GOCOMPLETE, scale9 = true, size = cc.size(373, 64), tag = 15 })
	display.commonLabelParams(completeBtn, fontWithColor(14, {text = __('去完成'), fontSize = 24, color = '#ffffff'}))
	rightLayout:addChild(completeBtn ,10 )

	local cgrideCellSize = cc.size(355, 95)
	local grideView      = CGridView:create(cc.size(369, 535))
	grideView:setSizeOfCell(cgrideCellSize)
	grideView:setColumns(1)
	grideView:setAutoRelocate(true)
	grideView:setAnchorPoint(display.CENTER_TOP )
	grideView:setPosition(369 / 2+ 6 , 550 -5  )
	rightLayout:addChild(grideView)
	grideView:setTag(10)

	local photoLayout = newLayer(40, 110,
			{ ap = display.LEFT_BOTTOM, size = cc.size(730, 458) })
	bgLayout:addChild(photoLayout)

	local photoBgImage = newImageView(RES_DICT.BG, 365, 229,
			{ ap = display.CENTER, tag = 54, enable = false })
	photoLayout:addChild(photoBgImage)
	photoBgImage:setScale(0.45)

	local photoFrameImage = newImageView(RES_DICT.CVSHARE_CV_FRAME, 365, 229,
			{ ap = display.CENTER, tag = 53, enable = false })
	photoLayout:addChild(photoFrameImage)
	photoFrameImage:setLocalZOrder(100)
	closeBtn:setEnabled(false)
	colorLayer:setOpacity(0)
	self:setOpacity(0)
	bgLayout:setScale(0.95)
	self.viewData =  {
		bgLayout                = bgLayout,
		bgImage                 = bgImage,
		titleDescrLayout        = titleDescrLayout,
		titleDescrImage         = titleDescrImage,
		titleLabel              = titleLabel,
		--completeLabel           = completeLabel,
		rightLayout             = rightLayout,
		rewardBgImage           = rewardBgImage,
		completeBtn             = completeBtn,
		photoLayout             = photoLayout,
		photoBgImage            = photoBgImage,
		photoFrameImage         = photoFrameImage,
		closeBtn                = closeBtn ,
		colorLayer              = colorLayer ,
		grideView               = grideView ,
		tipBtn                  = tipBtn ,
	}
end

function ShareCV2TaskView:CreatePrograssLayout()
	local progressSize =  cc.size(1163, 669)
	local progressLayout = newLayer(progressSize.width/2 , progressSize.height/2 , {
		size = progressSize , ap = display.CENTER
	} )
	self.viewData.bgLayout:addChild(progressLayout)
	local collectionDescrLabel = newLabel(112, 63,
			{ ap = display.CENTER, color = '#5b3c25', text = __('收集进度'),w = 140,hAlign = display.TAC ,  fontSize = 26, tag = 11 })
	progressLayout:addChild(collectionDescrLabel)

	local collectionLabel = newLabel(391, 31,
			{ ap = display.CENTER, color = '#5b3c25', text = "", fontSize = 22, tag = 12 })
	progressLayout:addChild(collectionLabel)

	local progressBar = CProgressBar:create(RES_DICT.POINT_PROGRESSBAR)
	progressBar:setBackgroundImage(RES_DICT.POINT_PROGRESSBAR_BG)
	progressBar:setDirection(eProgressBarDirectionLeftToRight)
	progressBar:setAnchorPoint(cc.p(0.5, 0.5))
	progressBar:setPosition(cc.p(391, 63))
	progressBar:setScaleX(1.15)
	progressLayout:addChild(progressBar,1)
	local compositionBtn = newButton(698, 57, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_ORANGE, d = RES_DICT.COMMON_BTN_ORANGE, s = RES_DICT.COMMON_BTN_ORANGE })
	display.commonLabelParams(compositionBtn, fontWithColor(14, {text = __('合成'), fontSize = 24, color = '#ffffff'}))
	progressLayout:addChild(compositionBtn)
	display.commonUIParams(compositionBtn , { cb = function()
				AppFacade.GetInstance():DispatchObservers("COMPOUND_PHOTO_EVENT" , {})
	end})
	table.merge( self.viewData ,
	{
		progressLayout = progressLayout ,
		collectionDescrLabel = collectionDescrLabel ,
		collectionLabel = collectionLabel ,
		compositionBtn = compositionBtn ,
		progressBar = progressBar
	})
end

function ShareCV2TaskView:CreateShareLayout()
	local shareLayoutSize =  cc.size(1163, 669)
	local shareLayout  = newLayer(shareLayoutSize.width/2 , shareLayoutSize.height/2 , {
		size = shareLayoutSize, ap = display.CENTER
	} )
	self.viewData.bgLayout:addChild(shareLayout)
	local collectCompleteLabel = newLabel(130, 20,
			{ ap = display.CENTER , color = '#27a19b', text = __('收集完成！'), fontSize = 24, tag = 11 })
	shareLayout:addChild(collectCompleteLabel)

	local firstShareLabel = newLabel(400, 62 , { ap = display.RIGHT_CENTER , color = '#5b3c25', text = __('首次分享奖励'), fontSize = 22, tag = 11 } )
	shareLayout:addChild(firstShareLabel)

	local shareBtn = newButton(698, 57, { ap = display.CENTER ,  n = RES_DICT.COMMON_BTN_BLUE_DEFAULT, d = RES_DICT.COMMON_BTN_BLUE_DEFAULT, s = RES_DICT.COMMON_BTN_BLUE_DEFAULT })
	display.commonLabelParams(shareBtn,  fontWithColor(14,{text = __('分享'), fontSize = 24, color = '#ffffff'}))
	shareLayout:addChild(shareBtn)

	local completeImage  = newImageView(RES_DICT.CG_PUZZLE_ICO_COMPLETED_1 , 120, 70 )
	shareLayout:addChild(completeImage)
	completeImage:setScale(0.4)


	display.commonUIParams(shareBtn , { cb = function()
			app:DispatchObservers("ACTIVITY_CVSHARE2_SHARED_BTN_EVENT"  , {})
	end})
	---@type GoodNode[]
	local goodNodes = {}
	table.merge( self.viewData ,
	{
		shareLayout = shareLayout ,
		goodNodes  = goodNodes , 
		collectCompleteLabel = collectCompleteLabel ,
		firstShareLabel = firstShareLabel ,
		shareBtn = shareBtn
	})
end
function ShareCV2TaskView:EnterAction()
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
function ShareCV2TaskView:UpdatePhotoLayout( data )
	local index = 0
	for i = #data ,  1 , -1 do
		local v = data[i]
		if checkint(v.progress) >= checkint(v.targetNum)  then
			index = i
			break 
		end
	end
	if index > 0  then
		local v = data[index]
		self.viewData.photoBgImage:setTexture(_res(string.format('ui/home/activity/cv2/photoSe/%s' , tostring( v.picture)  )))
	end
end

function ShareCV2TaskView:UpdateUI(compound , collectShareRewardsHasDrawn ,collectShareRewards ,collectedNum , totalNum  )
	compound = checkint(compound)
	if compound == 0 then
		-- 未合成
		if (not  self.viewData.progressLayout ) or ( tolua.isnull(self.viewData.progressLayout)) then
			self:CreatePrograssLayout()
			self:UpdatePrograssLayout(collectedNum ,totalNum )
		end
	elseif compound == 1 then
		-- 已经合成
		self.viewData.completeBtn:setVisible(false)
		local seqTable = {}
		if (  self.viewData.progressLayout ) and  ( not tolua.isnull(self.viewData.progressLayout)) then
			seqTable[#seqTable+1] =cc.TargetedAction:create(self.viewData.progressLayout , cc.Sequence:create(
					cc.FadeOut:create(0.5) ,
					cc.Hide:create()
			))
			self.viewData.progressLayout:setVisible(false)
		end
		if ( not  self.viewData.shareLayout ) or  (  tolua.isnull(self.viewData.shareLayout)) then
			self:CreateShareLayout()
			self.viewData.shareLayout:setOpacity(0)
			seqTable[#seqTable+1] = cc.FadeIn:create(0.5)
			self.viewData.shareLayout:runAction(cc.Sequence:create( seqTable))
		end
		self:UpdateShareLayout(collectShareRewardsHasDrawn , collectShareRewards)
	end
end
function ShareCV2TaskView:UpdateShareLayout(collectShareRewardsHasDrawn , collectShareRewards)
	collectShareRewardsHasDrawn = checkint(collectShareRewardsHasDrawn)
	if collectShareRewardsHasDrawn == 1 then
		for i, goodsNode in pairs(self.viewData.goodNodes) do
			goodsNode:setVisible(false)
		end
		self.viewData.firstShareLabel:setVisible(false)
	else
		---@type GoodNode[]
		local goodNodes = self.viewData.goodNodes
		if  #goodNodes == 0  then
			for i, v in pairs(collectShareRewards) do
				local goodNode = require("common.GoodNode").new({
					goodsId = DIAMOND_ID , num = 0 , showAmount = true
				})
				goodNode:setPosition(cc.p(610 - (i - 0.5 ) *  100,55 ))
				self.viewData.shareLayout:addChild(goodNode)
				goodNode:setScale(0.8)
				goodNodes[#goodNodes+1] = goodNode
			end
		end
		for i, v in pairs(collectShareRewards) do
			goodNodes[i]:RefreshSelf(v)
			display.commonUIParams(goodNodes[i] , { animate = false  ,  cb = function(sender)
				app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
			end})
		end
	end

end

function ShareCV2TaskView:UpdatePrograssLayout(collectedNum , totalNum)
	totalNum = checkint(totalNum)
	collectedNum = checkint(collectedNum)
	self.viewData.progressBar:setMaxValue(totalNum)
	self.viewData.progressBar:setValue(collectedNum)
	if checkint(collectedNum) == checkint(totalNum) then
		--self.viewData.completeBtn:setVisible(false)
	end
	display.commonLabelParams(self.viewData.collectionLabel , { text = table.concat( {collectedNum ,totalNum  } , '/')})
end
return ShareCV2TaskView