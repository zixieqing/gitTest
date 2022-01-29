--[[
 * author : liuzhipeng
 * descpt : KFC签到活动 View
--]]
---@class ActivityJPWishView
local ActivityJPWishView = class('ActivityJPWishView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'activity.ActivityJPWishView'
	node:enableNodeEvents()
	return node
end)
local FRUIT_POS ={
	cc.p(114,313),
	cc.p(151,408),
	cc.p(243,544),
	cc.p(284,352),
	cc.p(380,554),
	cc.p(450,400),
	cc.p(577,531),
	cc.p(727,508),
	cc.p(727,360),
	cc.p(851,360),

}
local RES_DICT = {
	LOADING_BG                              = _res('ui/home/activity/activity_bg_loading.jpg'),
	TIME_BG                                 = _res('ui/home/activity/activity_time_bg.png'),
	ACTIVITY_PRAY_BG_TIME_RIPE              = _res('ui/home/activity/pray/activity_pray_bg_time_ripe.png'),
	ACTIVITY_PRAY_BG_GOODS_NUMBER           = _res('ui/home/activity/pray/activity_pray_bg_goods_number.png'),
	ACTIVITY_PRAY_BG_TIME                   = _res('ui/home/activity/pray/activity_pray_bg_time.png'),
	ACTIVITY_PRAY_BG                        = _res('ui/home/activity/pray/activity_pray_bg.png'),
	ACTIVITY_PRAY_BG_INFO                   = _res('ui/home/activity/pray/activity_pray_bg_info.png'),
	ACTIVITY_PRAY_IMG_LIGHT                 = _res('ui/home/activity/pray/activity_pray_img_light.png'),
	ACTIVITY_PRAY_IMG_FRUIT_LEAF_UNRIPE_1   = _res('ui/home/activity/pray/activity_pray_img_fruit_leaf_unripe_1.png'),
	ACTIVITY_PRAY_IMG_FRUIT_LEAF_UNRIPE_2   = _res('ui/home/activity/pray/activity_pray_img_fruit_leaf_unripe_2.png'),
	ACTIVITY_PRAY_IMG_FRUIT_RIPE_1          = _res('ui/home/activity/pray/activity_pray_img_fruit_ripe_1.png'),
	ACTIVITY_PRAY_IMG_FRUIT_RIPE_2          = _res('ui/home/activity/pray/activity_pray_img_fruit_ripe_2.png'),
	ACTIVITY_PRAY_IMG_FRUIT_RIPE_SHADOW_1   = _res('ui/home/activity/pray/activity_pray_img_fruit_ripe_shadow_1.png'),
	ACTIVITY_PRAY_IMG_FRUIT_RIPE_SHADOW_2   = _res('ui/home/activity/pray/activity_pray_img_fruit_ripe_shadow_2.png'),
	ACTIVITY_PRAY_IMG_FRUIT_SHADOW_UNRIPE_1 = _res('ui/home/activity/pray/activity_pray_img_fruit_shadow_unripe_1.png'),
	ACTIVITY_PRAY_IMG_FRUIT_SHADOW_UNRIPE_2 = _res('ui/home/activity/pray/activity_pray_img_fruit_shadow_unripe_2.png'),
	ACTIVITY_PRAY_IMG_FRUIT_UNRIPE_1        = _res('ui/home/activity/pray/activity_pray_img_fruit_unripe_1.png'),
	ACTIVITY_PRAY_IMG_FRUIT_UNRIPE_2        = _res('ui/home/activity/pray/activity_pray_img_fruit_unripe_2.png'),
	BUTTON_N                                = _res('ui/common/common_btn_big_orange_2.png'),
	REWAED_TITLE                            = _res('ui/common/common_title_5.png'),
	COMMON_BG_TIPS                          = _res('ui/common/chat_bg_npc.png'),
	REWARD_LIST_BG                          = _res('ui/common/common_bg_list.png'),
	COMMON_BG_TIPS_HORN                     = _res('ui/common/common_bg_tips_horn.png')
}
local CreateView    = nil
local CreateRewardCell = nil
function ActivityJPWishView:ctor( ... )
	local args = unpack({...}) or {}
	self.viewData_ = CreateView()
	display.commonUIParams(self.viewData_.view, {po = cc.p(0,0), ap = display.LEFT_BOTTOM})
	self:addChild(self.viewData_.view, 1)
end

CreateView = function ()
	local size = cc.size(1035, 637)
	local view = CLayout:create(size)

	local bg = display.newImageView(RES_DICT.ACTIVITY_PRAY_BG , 1035/2,637/2)
	view:addChild(bg, 1)
	local bgSize = bg:getContentSize()

	local bgInfor = display.newImageView(RES_DICT.ACTIVITY_PRAY_BG_INFO , bgSize.width/2 , 0 , {ap = display.CENTER_BOTTOM})
	bg:addChild(bgInfor)

	local fruitsLayout = display.newLayer(0,0,{ap = display.LEFT_BOTTOM , size = cc.size(1035, 637)  })
	view:addChild(fruitsLayout, 1)

	local fruitLightImage = display.newImageView(RES_DICT.ACTIVITY_PRAY_IMG_LIGHT , bgSize.width/2 , bgSize.height , {ap = display.CENTER_TOP})
	view:addChild(fruitLightImage, 12)

	local timeBg = display.newImageView(RES_DICT.TIME_BG, 1030, 600, {ap = display.RIGHT_CENTER})
	local timeBgSize = timeBg:getContentSize()
	view:addChild(timeBg, 5)
	local timeTitleLabel = display.newLabel(135, timeBgSize.height / 2, fontWithColor(18, {text = __('剩余时间:'), ap = display.RIGHT_CENTER}))
	timeBg:addChild(timeTitleLabel, 10)
	local timeLabel = display.newLabel(timeTitleLabel:getPositionX() + 5, timeTitleLabel:getPositionY(), {text = '', ap = cc.p(0, 0.5), fontSize = 22, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	timeBg:addChild(timeLabel, 10)
	
	
	
	local wishBtn = display.newButton(920, 78, {ap = display.CENTER, n = RES_DICT.BUTTON_N})
	view:addChild(wishBtn, 10)
	display.commonLabelParams(wishBtn, fontWithColor(14, {fontSize = 30,  text = __('祈愿') ,outline = '#404e2c' , outlineSize = 2}))

	local freeLabel = display.newLabel(920 , 22 , {fontSize = 24 , text = "" })
	view:addChild(freeLabel, 10)

	local prayBgGoods = display.newButton(920, 142,{ n = RES_DICT.ACTIVITY_PRAY_BG_GOODS_NUMBER } )
	view:addChild(prayBgGoods, 10)
	display.commonLabelParams(prayBgGoods , fontWithColor(14,{text = "" , offset = cc.p(-10,-2)}))

	local goodImage= display.newImageView(CommonUtils.GetGoodsIconPathById(DIAMOND_ID) , 120 , 25)
	goodImage:setScale(0.35)
	prayBgGoods:addChild(goodImage)
	goodImage:setVisible(false)

	local prayDescrLabel = display.newLabel(30, 63, {ap = display.LEFT_TOP ,fontSize = 24 , w = 600 , hAlign = display.TAL,  color = "#dfefd9" , text = __('每天可以祈愿,树上最多10个祈愿果')})
	view:addChild(prayDescrLabel, 10)

	local prayLabel = display.newLabel(30 ,70 , fontWithColor(14, { ap = display.LEFT_BOTTOM ,fontSize = 60 ,  text =__('祈愿树') ,color = "#fffac0" , outline = '#404e2c' , outlineSize = 4 }) )
	view:addChild(prayLabel, 10)
	return {
		bg              = bg,
		view 	        = view,
		goodImage 	    = goodImage,
		timeLabel       = timeLabel,
		fruitsLayout    = fruitsLayout,
		prayBgGoods     = prayBgGoods ,
		freeLabel     = freeLabel,
		prayDescrLabel  = prayDescrLabel,
		wishBtn        = wishBtn
	}
end

function ActivityJPWishView:setTimeLabel(seconds)
	local viewData = self:getViewData()
	local timeLabel = viewData.timeLabel
	timeLabel:setString(CommonUtils.getTimeFormatByType(seconds))
end

function ActivityJPWishView:UpdateRuleLable(detail)
	local viewData = self:getViewData()
	local prayDescrLabel = viewData.prayDescrLabel
	if string.len(detail) > 0 then
		prayDescrLabel:setString(detail)
	end
end

function ActivityJPWishView:CreateFruit()
	local button = display.newButton(0,0, {ap = display.CENTER , color = cc.c4b(0,0,0,0), size = cc.size(100,100)})
	local shadowImage = display.newImageView(RES_DICT.ACTIVITY_PRAY_IMG_FRUIT_SHADOW_UNRIPE_1 , 50,50)
	button:addChild(shadowImage , 1)
	shadowImage:setName("shadowImage")
	local fruitImage = display.newImageView(RES_DICT.ACTIVITY_PRAY_IMG_FRUIT_UNRIPE_1 , 50,50)
	button:addChild(fruitImage , 2)
	fruitImage:setName("fruitImage")
	local leafImage = display.newImageView(RES_DICT.ACTIVITY_PRAY_IMG_FRUIT_LEAF_UNRIPE_1 , 50,50)
	button:addChild(leafImage , 3)
	leafImage:setName("leafImage")

	local timeLabel = display.newButton(50 , -10 , { n = RES_DICT.ACTIVITY_PRAY_BG_TIME , scale9 = true , size = cc.size(120, 31) })
	button:addChild(timeLabel , 3)
	display.commonLabelParams(timeLabel , fontWithColor(14,{fontSize = 22,  text = ""}))
	timeLabel:setName("timeLabel")
	return  button
end
-- 删除果实
function ActivityJPWishView:RemoveFruitByFruitId(fruitId )
	local fruitId = checkint(fruitId)
	local fruitsLayout = self.viewData_.fruitsLayout
	local fruitLayout = fruitsLayout:getChildByTag(fruitId)

	if fruitLayout and (not tolua.isnull(fruitLayout)) then
		fruitLayout:stopAllActions()
		fruitLayout:runAction(cc.RemoveSelf:create())
	end
end
-- 添加果实
function ActivityJPWishView:AddFruits(fruits)
	local fruitsLayout = self.viewData_.fruitsLayout
	for i, v in pairs(fruits) do
		local fruitId = checkint(v.fruitId)
		local fruitLayout = fruitsLayout:getChildByTag(fruitId)
		if fruitLayout and (not tolua.isnull(fruitLayout)) then

		else
			local button = self:CreateFruit()
			local curentTime = os.time()
			local distanceTime = curentTime - v.recordTime
			local isRipe = distanceTime  >=  checkint(v.matureLeftSeconds)
			self:UpdateFruitIndex(button , v , isRipe)
			fruitsLayout:addChild(button , fruitId)
			display.commonUIParams(button , {
				cb = function(sender)
					AppFacade.GetInstance():DispatchObservers("PRAY_EVENT" , {fruitId = sender:getTag()})
				end
			})
			button:setTag(fruitId)
			button:setPosition(FRUIT_POS[fruitId])
			self:setFruitTimeLabel( v.fruitId , checkint(v.matureLeftSeconds) - distanceTime)
		end
	end
end

function ActivityJPWishView:UpdateFruitIndex( fruitLayout ,data , isRipe)
	local index = data.fruitIcon  --TODO  后面依据服务端的字段复制
 	local shadowImage  = fruitLayout:getChildByName("shadowImage")
	local fruitImage  = fruitLayout:getChildByName("fruitImage")
	local leafImage  = fruitLayout:getChildByName("leafImage")
	local timeLabel  = fruitLayout:getChildByName("timeLabel")
	if isRipe then
		leafImage:setVisible(false)
		timeLabel:setVisible(false)
		shadowImage:setTexture(_res(string.format("ui/home/activity/pray/activity_pray_img_fruit_ripe_shadow_%d" , checkint(index)) ))
		fruitImage:setTexture(_res(string.format("ui/home/activity/pray/activity_pray_img_fruit_ripe_%d" , checkint(index)) ))
	else
		leafImage:setVisible(true)
		timeLabel:setVisible(true)
		leafImage:setTexture(_res(string.format("ui/home/activity/pray/activity_pray_img_fruit_leaf_unripe_%d" , checkint(index)) ))
		shadowImage:setTexture(_res(string.format("ui/home/activity/pray/activity_pray_img_fruit_shadow_unripe_%d" , checkint(index)) ))
		fruitImage:setTexture(_res(string.format("ui/home/activity/pray/activity_pray_img_fruit_unripe_%d" , checkint(index)) ))
	end
end
function ActivityJPWishView:setFruitTimeLabel(fruitId , distanceTime)
	local fruitsLayout = self.viewData_.fruitsLayout
	local fruitLayout = fruitsLayout:getChildByTag(fruitId)
	local timeLabel  = fruitLayout:getChildByName("timeLabel")
	if distanceTime >= 0  then
		local str = timeLabel:getLabel():getString()
		if distanceTime <= 86400 then
			display.commonLabelParams(timeLabel , fontWithColor(14 , {fontSize = 22 , text = CommonUtils.getTimeFormatByType(distanceTime)}))
		else
			if string.len(str) < 1   then
				display.commonLabelParams(timeLabel , fontWithColor(14 , {fontSize = 22 , text = CommonUtils.getTimeFormatByType(distanceTime)}))
			end
		end
	end
end

function ActivityJPWishView:CreateBgTips()
	local size = cc.size(230 , 72)
	local tipLayout = display.newLayer(0,0, {size = size })
	tipLayout:setName("tipLayout")
	local tipBgImage = display.newImageView(RES_DICT.COMMON_BG_TIPS ,size.width/2 , size.height/2, {scale9 = true , size =cc.size(230,70)}  )
	tipLayout:addChild(tipBgImage)

	local ripeLabel = display.newLabel(size.width/2 , size.height * 3/4 , fontWithColor(5,{text = __('成熟倒计时')}))
	tipLayout:addChild(ripeLabel)

	local timeLabel = display.newButton( size.width/2 , size.height * 1/4+ 10 , { n = RES_DICT.ACTIVITY_PRAY_BG_TIME_RIPE } )
	display.commonLabelParams(timeLabel , fontWithColor(14, {text = ""}))
	tipLayout:addChild(timeLabel)
	timeLabel:setName("timeLabel")
	local hornImage = display.newImageView(RES_DICT.COMMON_BG_TIPS_HORN ,25 , 2  )
	tipLayout:addChild(hornImage)
	hornImage:setScaleY(-1)
	return tipLayout
end

function ActivityJPWishView:UpdateBgTips(fruitId)
	local view = self.viewData_.view
	local tipLayout = view:getChildByName("tipLayout")
	if not tipLayout then
		tipLayout =  self:CreateBgTips()
		view:addChild(tipLayout , 13)

	end
	if not fruitId  then
		fruitId = tipLayout:getTag()
	end
	local pos = FRUIT_POS[fruitId]
	tipLayout:setTag(fruitId)

	local fruitsLayout = self.viewData_.fruitsLayout
	local fruitLayout = fruitsLayout:getChildByTag(fruitId)
	tipLayout:setVisible(true)
	tipLayout:setPosition(pos.x -20  , pos.y + 10 )
	local timeLabel = tipLayout:getChildByName("timeLabel")
	if fruitLayout then
		local timeLabel1 = fruitLayout:getChildByName("timeLabel")
		display.commonLabelParams(timeLabel , {text =timeLabel1:getLabel():getString()})
	end
end

function ActivityJPWishView:SetBgVisible(isVisible)
	local view = self.viewData_.view
	local tipLayout = view:getChildByName("tipLayout")
	if tipLayout then
		tipLayout:setVisible(isVisible)
	end
end
function ActivityJPWishView:getBgTipTag()
	local view = self.viewData_.view
	local tipLayout = view:getChildByName("tipLayout")
	local tag = 0
	if  tipLayout  then
		tag = tipLayout:getTag()
	end

	return tag
end
function ActivityJPWishView:GetBgVisible()
	local view = self.viewData_.view
	local tipLayout = view:getChildByName("tipLayout")
	local isVisible = false
	if tipLayout then
		isVisible = tipLayout:isVisible()
	end
	return isVisible
end

----=======================----
--@author : xingweihao
--@date : 2019-08-15 10:38 
--@Description 更新剩余的次数
--@params: leftTimes 剩余次数 ， totalTimes 总次数
--@return
---=======================----
function ActivityJPWishView:UpdateLeftTimes(leftTimes , totalTimes)
	local viewData_  = self.viewData_
	display.commonLabelParams(viewData_.freeLabel ,{text = string.fmt(__('今日剩余次数 _num1_ /_num2_' ) , {_num1_ = leftTimes , _num2_ = totalTimes })})
end

function ActivityJPWishView:UpdateGoods(goodId, goodNums)
	local viewData_  = self.viewData_
	local ownerNum = CommonUtils.GetCacheProductNum(goodId)
	display.commonLabelParams(viewData_.prayBgGoods,{text = ownerNum ..'/' ..  goodNums  } )
	local goodImage = self.viewData_.goodImage
	goodImage:setTexture(CommonUtils.GetGoodsIconPathById(goodId))
	goodImage:setVisible(true)
end

function ActivityJPWishView:UpdateBgTipsTime(distanceTime)
	local view = self.viewData_.view
	local tipLayout = view:getChildByName("tipLayout")
	local timeLabel = tipLayout:getChildByName("timeLabel")
	display.commonLabelParams(timeLabel , fontWithColor(14 , {text  = CommonUtils.getTimeFormatByType(distanceTime)}))
end

function ActivityJPWishView:getViewData()
	return self.viewData_
end

return ActivityJPWishView