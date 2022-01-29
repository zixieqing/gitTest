--[[
 * author : xingweihao
 * descpt : 宝箱活动
--]]
---@class ActivityChestBigView
local ActivityChestBigView = class('ActivityChestBigView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.view.activity.continuous.ActivityChestBigView'
	node:enableNodeEvents()
	return node
end)
local BIG_CHEST_STATUS = {
	NOT_DRAW     = 1, -- 不可以领取
	CAN_DRAW     = 2, -- 可以领取
	ALREADY_DRAW = 3, -- 已经可以领取
}
local RES_DICT={
	COMMON_BG_4                              = _res("ui/common/common_bg_4.png"),
	GOODS_ICON_121001                        = _res("arts/goods/goods_icon_121001.png"),
	BOX_LIST_BG_NAME                         = _res("ui/home/activity/chest/box_list_bg_name.png"),
	COMMON_BTN_ORANGE                        = _res("ui/home/activity/common_btn_orange.png"),
	COMMCON_BG_TEXT                          = _res("ui/common/commcon_bg_text.png"),
	COMMON_BTN_ORANGE_DISABLE                = _res("ui/common/common_btn_orange_disable.png"),
	COMMON_BG_FONT_NAME_2                    = _res("ui/cards/skillNew/common_bg_font_name_2.png"),
	BOX_HOME_BG_BIG_BOX                      = _spn("ui/home/activity/chest/animate/box_home_bg_big_box"),
}
function ActivityChestBigView:ctor( ... )
	self:InitUI()
end
function ActivityChestBigView:InitUI()
	local closeLayer = display.newLayer(display.cx, display.cy ,{ap = display.CENTER,size = display.size,color = cc.c4b(0,0,0,175),enable = true})
	self:addChild(closeLayer)
	local centerLayout = display.newLayer(display.cx,  display.cy ,{ ap = display.CENTER,size = cc.size(500,553.55)})
	self:addChild(centerLayout)
	local hight = 50
	local centerSwallowLayer = display.newLayer(250, 553.55/2 ,{ap = display.CENTER,size = cc.size(500,553.55),color = cc.c4b(0,0,0,0),enable = true})
	centerLayout:addChild(centerSwallowLayer)
	local bgImage = display.newImageView( RES_DICT.COMMON_BG_4 ,250, 553.55/2,{ap = display.CENTER,scale9 = true,size = cc.size(500 , 553.55)})
	centerLayout:addChild(bgImage)
	local chestSpine = sp.SkeletonAnimation:create(RES_DICT.BOX_HOME_BG_BIG_BOX.json ,RES_DICT.BOX_HOME_BG_BIG_BOX.atlas ,1)
	chestSpine:setAnimation(0, 'idle' , true)
	chestSpine:setPosition(250, 350.2+hight)
	centerLayout:addChild(chestSpine)
	local chestName = display.newButton(250, 328.2+hight , {n = RES_DICT.BOX_LIST_BG_NAME,ap = display.CENTER,scale9 = true,size = cc.size(210,37)})
	centerLayout:addChild(chestName)
	display.commonLabelParams(chestName ,fontWithColor(14 , {fontSize = 24,text = '',color = '#7e2b1a',paddingW  = 20,safeW = 170}))
	local commonImage = display.newImageView( RES_DICT.COMMCON_BG_TEXT ,248.1, 166.5 + hight,{ap = display.CENTER,scale9 = true,size = cc.size(442.1 , 201.4)})
	centerLayout:addChild(commonImage)
	local mustRewardTitle = display.newButton(120, 231.2 + hight , {n = RES_DICT.COMMON_BG_FONT_NAME_2,ap = display.CENTER,scale9 = true,size = cc.size(167,26)})
	centerLayout:addChild(mustRewardTitle)
	display.commonLabelParams(mustRewardTitle ,{fontSize = 24,text = __('必定获得'),color = '#7e2b1a',offset = cc.p(-20 , 0),paddingW  = 20,safeW = 127})
	local rewardBtn = display.newButton(250, 1.199997 + hight , {n = RES_DICT.COMMON_BTN_ORANGE,ap = display.CENTER,scale9 = true,size = cc.size(123,59)})
	centerLayout:addChild(rewardBtn)
	display.commonLabelParams(rewardBtn , fontWithColor(14, {text = __('领取')  ,paddingW  = 20,safeW = 83}))
	self.viewData = {
		closeLayer                = closeLayer,
		centerLayout              = centerLayout,
		centerSwallowLayer        = centerSwallowLayer,
		bgImage                   = bgImage,
		chestName                 = chestName,
		commonImage               = commonImage,
		mustRewardTitle           = mustRewardTitle,
		chestSpine                = chestSpine,
		rewardBtn                 = rewardBtn
	}
end

function ActivityChestBigView:UpdateChestName(name)
	local viewData = self.viewData
	display.commonLabelParams(viewData.chestName ,fontWithColor(14 , {
		fontSize = 24,text = name,paddingW  = 20,safeW = 170
	}))
end

function ActivityChestBigView:CreateMustGoodsData(goodsData)
	local viewData = self.viewData
	for i = 1, #goodsData do
		goodsData[i].showAmount = true
		local goodNode = require('common.GoodNode').new(goodsData[i])
		goodNode:setPosition(95 + (i-1) * 103 , 210)
		goodNode:setScale(0.85)
		viewData.centerLayout:addChild(goodNode)
		goodNode:setTag(checkint(goodsData[i].goodsId))
		display.commonUIParams(goodNode, {animate = false ,  cb = function(sender)
			app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender:getTag(), type = 1})
		end})
	end
end

function ActivityChestBigView:RunRewardsAnimate()
	local chestSpine =  self.viewData.chestSpine
	chestSpine:setToSetupPose()
	self.viewData.chestSpine:setAnimation(0, 'play', false)
end

function ActivityChestBigView:UpdateBigButtonStatus(status)
	local rewardBtn = self.viewData.rewardBtn
	local path = RES_DICT.COMMON_BTN_ORANGE
	local text = __('领取')
	if status == BIG_CHEST_STATUS.NOT_DRAW then
		path = RES_DICT.COMMON_BTN_ORANGE_DISABLE
	elseif status == BIG_CHEST_STATUS.ALREADY_DRAW then
		text = __('已领取')
	end
	rewardBtn:setNormalImage(path)
	rewardBtn:setSelectedImage(path)
	display.commonLabelParams(rewardBtn , fontWithColor(14,{text = text }))
end
return ActivityChestBigView