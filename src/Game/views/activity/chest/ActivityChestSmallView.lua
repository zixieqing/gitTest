--[[
 * author : xingweihao
 * descpt : 宝箱活动
--]]
---@class ActivityChestSmallView
local ActivityChestSmallView = class('ActivityChestSmallView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.view.activity.chest.ActivityChestSmallView'
	node:enableNodeEvents()
	return node
end)
local CHEST_STATUS = {
	NOT_OPEN     = 1,  --未打开
	DO_OPENING   = 2,  --打开中
	ALREADY_OPEN = 3,  --已打开
}

local RES_DICT={
	COMMON_BG_4                              = _res("ui/common/common_bg_4.png"),
	GOODS_ICON_121001                        = _res("arts/goods/goods_icon_121001.png"),
	BOX_LIST_BG_NAME                         = _res("ui/home/activity/chest/box_list_bg_name.png"),
	COMMON_BTN_ORANGE                        = _res("ui/home/activity/common_btn_orange.png"),
	COMMCON_BG_TEXT                          = _res("ui/common/commcon_bg_text.png"),
	COMMON_BG_FONT_NAME_2                    = _res("ui/cards/skillNew/common_bg_font_name_2.png"),
	COMMON_BTN_GREEN                         = _res("ui/common/common_btn_green.png"),
	COMMON_BTN_ORANGE_DISABLE                = _res("ui/common/common_btn_orange_disable.png")
}

function ActivityChestSmallView:ctor( ... )
	self:InitUI()
end

function ActivityChestSmallView:InitUI()
	local closeLayer = display.newLayer(display.cx, display.cy ,{ap = display.CENTER,size = display.size,color = cc.c4b(0,0,0,175),enable = true})
	self:addChild(closeLayer)
	local centerLayout = display.newLayer(display.cx , display.cy + 18 ,{ap = display.CENTER,size = cc.size(500,612.7)})
	self:addChild(centerLayout)
	local centerSwallowLayer = display.newLayer(250, 306.35 ,{ap = display.CENTER,size = cc.size(500,612.7),color = cc.c4b(0,0,0,0),enable = true})
	centerLayout:addChild(centerSwallowLayer)
	local bgImage = display.newImageView( RES_DICT.COMMON_BG_4 ,250, 306.35,{ap = display.CENTER,scale9 = true,size = cc.size(500 , 612.7)})
	centerLayout:addChild(bgImage)
	local chestImage = display.newImageView( RES_DICT.GOODS_ICON_121001 ,250, 532.35,{ap = display.CENTER})
	centerLayout:addChild(chestImage)
	local chestName = display.newButton(250, 449.35 , {n = RES_DICT.BOX_LIST_BG_NAME,ap = display.CENTER,scale9 = true,size = cc.size(210,37)})
	centerLayout:addChild(chestName)
	display.commonLabelParams(chestName ,fontWithColor(14 , {fontSize = 24,text = '',paddingW  = 20,safeW = 170}))
	local commonImage = display.newImageView( RES_DICT.COMMCON_BG_TEXT ,248.1, 274.55,{ap = display.CENTER,scale9 = true,size = cc.size(442.1 , 299.1)})
	centerLayout:addChild(commonImage)
	local mustRewardTitle = display.newButton(129, 392.35 , {n = RES_DICT.COMMON_BG_FONT_NAME_2,ap = display.CENTER,scale9 = true,size = cc.size(167,26)})
	centerLayout:addChild(mustRewardTitle)
	display.commonLabelParams(mustRewardTitle ,{fontSize = 24,text = __('必定获得'),color = '#7e2b1a',offset = cc.p(-20 , 0),paddingW  = 20,safeW = 127})
	local maybeRewardTitle = display.newButton(129, 246.35 , {n = RES_DICT.COMMON_BG_FONT_NAME_2,ap = display.CENTER,scale9 = true,size = cc.size(167,26)})
	centerLayout:addChild(maybeRewardTitle)
	display.commonLabelParams(maybeRewardTitle ,{fontSize = 24,text = __('可能获得'),color = '#7e2b1a',offset = cc.p(-20 , 0),paddingW  = 20,safeW = 127})
	local leftBtn = display.newButton(141, 49.35001 , {n = RES_DICT.COMMON_BTN_ORANGE,ap = display.CENTER,scale9 = true,size = cc.size(123,59)})
	centerLayout:addChild(leftBtn)
	display.commonLabelParams(leftBtn ,fontWithColor(14 , {fontSize = 24,text = __('解锁'),color = '#ffffff',paddingW  = 20,safeW = 83}))
	local openTimeLabel = display.newLabel(61.5, 73.5 , {fontSize = 22,text = '1',color = '#ce4943',ap = display.CENTER})
	leftBtn:addChild(openTimeLabel)
	local rightBtn = display.newButton(355, 49.35001 , {n = RES_DICT.COMMON_BTN_GREEN,ap = display.CENTER,scale9 = true,size = cc.size(123,59)})
	centerLayout:addChild(rightBtn)
	display.commonLabelParams(rightBtn ,fontWithColor(14 , {fontSize = 24,text = __('立即解锁'),color = '#ffffff',paddingW  = 20,safeW = 83}))
	local costLabel = display.newRichLabel(61.5, 73.5 ,{ap = display.CENTER,c = {fontWithColor(1 , {fontSize = 1,text = '1',color = '#ffffff'})}})
	rightBtn:addChild(costLabel)
	self.viewData = {
		closeLayer                = closeLayer,
		centerLayout              = centerLayout,
		centerSwallowLayer        = centerSwallowLayer,
		bgImage                   = bgImage,
		chestImage                = chestImage,
		chestName                 = chestName,
		commonImage               = commonImage,
		mustRewardTitle           = mustRewardTitle,
		maybeRewardTitle          = maybeRewardTitle,
		leftBtn                   = leftBtn,
		openTimeLabel             = openTimeLabel,
		rightBtn                  = rightBtn,
		costLabel                 = costLabel
	}
end

function ActivityChestSmallView:UpdateView(chestId)
	local crBoxConf = CONF.GOODS.CR_BOX:GetValue(chestId)
	self:CreateMaybeGoodsData(crBoxConf.optionalRewards)
	self:CreateMustGoodsData(crBoxConf.fixedRewards)
	self:UpdateChestInfo(crBoxConf)
end

function ActivityChestSmallView:CreateMustGoodsData(goodsData)
	local viewData = self.viewData
	for i = 1, #goodsData do
		goodsData[i].showAmount = true
		local goodNode = require('common.GoodNode').new(goodsData[i])
		goodNode:setPosition(95 + (i-1) * 103 , 320)
		goodNode:setScale(0.85)
		viewData.centerLayout:addChild(goodNode)
		goodNode:setTag(checkint(goodsData[i].goodsId))
		display.commonUIParams(goodNode, {animate = false ,  cb = function(sender)
			app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender:getTag(), type = 1})
		end})
	end
end

function ActivityChestSmallView:CreateMaybeGoodsData(goodsData)
	local viewData = self.viewData
	for i = 1, #goodsData do
		goodsData[i].showAmount = true
		local goodNode = require('common.GoodNode').new(goodsData[i])
		goodNode:setPosition(95 + (i-1) * 103 , 180)
		goodNode:setScale(0.85)
		viewData.centerLayout:addChild(goodNode)
		goodNode:setTag(checkint(goodsData[i].goodsId))
		display.commonUIParams(goodNode, {animate = false ,  cb = function(sender)
			app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender:getTag(), type = 1})
		end})
	end
end


function ActivityChestSmallView:UpdateChestInfo(chestConf)
	local chestImage = _res(string.format('ui/home/activity/chest/%s', chestConf.photoId))
	local viewData = self.viewData
	viewData.chestImage:setTexture(chestImage)
	local chestName = chestConf.name
	display.commonLabelParams(viewData.chestName , {text = chestName})
end

function ActivityChestSmallView:UpdateChestStatus( chestId , status , openLeftSeconds)
	status = checkint(status)
	openLeftSeconds = checkint(openLeftSeconds)
	local viewData = self.viewData
	local crBoxConf = CONF.GOODS.CR_BOX:GetValue(chestId)
	if CHEST_STATUS.NOT_OPEN == status then
		local openTime = crBoxConf.openTime
		self:UpdateOpenTimeLabel(openTime)
		self:UpdateChestTimeDiamond(chestId , openTime)


	elseif status == CHEST_STATUS.DO_OPENING then
		if openLeftSeconds <= 0  then
			local leftBtn = self.viewData.leftBtn
			display.commonLabelParams(leftBtn , {text = __('领取')})
			leftBtn:setNormalImage(RES_DICT.COMMON_BTN_ORANGE)
			leftBtn:setSelectedImage(RES_DICT.COMMON_BTN_ORANGE)
			viewData.openTimeLabel:setVisible(false)
			viewData.rightBtn:setVisible(false)
			local centerLayoutSize = viewData.centerLayout:getContentSize()
			viewData.leftBtn:setPositionX(centerLayoutSize.width/2)
		else
			self:UpdateOpenTimeLabel(openLeftSeconds)
			self:UpdateChestTimeDiamond(chestId , openLeftSeconds)
			local leftBtn = self.viewData.leftBtn
			leftBtn:setNormalImage(RES_DICT.COMMON_BTN_ORANGE_DISABLE)
			leftBtn:setSelectedImage(RES_DICT.COMMON_BTN_ORANGE_DISABLE)
		end
	end
end

function ActivityChestSmallView:UpdateChestTimeDiamond(chestId , openLeftSeconds)
	local crBoxConf = CONF.GOODS.CR_BOX:GetValue(chestId)
	local openConsume = crBoxConf.openConsume
	local openTime = crBoxConf.openTime
	local viewData = self.viewData
	if openConsume[1] then
		local num =  math.ceil(openLeftSeconds/openTime * openConsume[1].num )
		 display.reloadRichLabel(viewData.costLabel , { c = {
			 fontWithColor(14, {text = num}),
			 {img = CommonUtils.GetGoodsIconPathById(openConsume[1].goodsId) , scale = 0.2 }
		 }})
		CommonUtils.AddRichLabelTraceEffect(viewData.costLabel, nil , nil  , {1})
	else
		viewData.rightBtn:setVisible(false)
	end
end

function ActivityChestSmallView:UpdateOpenTimeLabel(openLeftSeconds)
	openLeftSeconds = checkint(openLeftSeconds)
	local viewData = self.viewData
	display.commonLabelParams(viewData.openTimeLabel ,{
		text = CommonUtils.getTimeFormatByType(openLeftSeconds,0)
	} )
end

return ActivityChestSmallView