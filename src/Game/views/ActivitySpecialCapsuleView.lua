--[[
限时超得活动view
--]]
local ActivitySpecialCapusleView = class('ActivitySpecialCapusleView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.ActivitySpecialCapusleView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local function CreateView( )
	local size = cc.size(1035, 637)
	local view = CLayout:create(size)
	-- 背景
	local bg = display.newImageView(_res('ui/home/activity/activity_bg_chaode.png'), size.width/2, size.height/2)
	view:addChild(bg, 1)
	-- 标题
	local title = display.newImageView(_res('ui/home/activity/activity_chaode_ttile.png'), 198, 550)
	view:addChild(title, 10)
	-- 时间
	local timeBg = display.newImageView(_res('ui/home/activity/activity_time_bg.png'), 189, 480 ,{scale9 = cc.size(400,47)})
	view:addChild(timeBg, 3)
	local timeBgSize = timeBg:getContentSize()
	local timeLabel = display.newRichLabel(timeBgSize.width - 20 , timeBgSize.height/2, {r = true,ap = display.RIGHT_CENTER ,  c = {
		{text = __('剩余时间:'), fontSize = 24, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#5b3c25', outlineSize = 1},
		{text = '8天', fontSize = 24, color = '#fed23b', ttf = true, font = TTF_GAME_FONT, outline = '#5b3c25', outlineSize = 1}
	}})
	timeBg:addChild(timeLabel, 10)
	-- 商店
	local shopBtn = display.newButton(966, 590, {n = _res('ui/home/nmain/main_btn_shop.png')})
	view:addChild(shopBtn, 10)
	local shopLabel = display.newLabel(966, 560, {text = __('超得商城'), fontSize = 26, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#5b3c25', outlineSize = 1})
	view:addChild(shopLabel, 10)
	-- 活动规则
	local ruleBg = display.newImageView(_res('ui/home/activity/activity_exchange_bg_rule_title.png'), 90, 160)
	view:addChild(ruleBg, 3)
	local ruleBg  = display.newButton(20,170, { n = _res('ui/home/activity/activity_exchange_bg_rule_title.png') ,enable = true , scale9 = true , ap = display.LEFT_CENTER  } )
	display.commonLabelParams(acivityButton, fontWithColor('14',{text= __('活动规则') , offset = cc.p( -15, 0) ,paddingW = 30}) )
	view:addChild(ruleBg, 9 )
	local triangleBg = display.newImageView(_res('ui/home/activity/activity_chaode_bg_triangle.png'), size.width/2, 225)
	view:addChild(triangleBg, 5)
	local bottomBg = display.newImageView(_res('ui/home/capsule/draw_card_bg_text_tips.png'), size.width/2, 72, {scale9 = true, size = cc.size(size.width - 4, 144)})
	view:addChild(bottomBg, 3)
	--local ruleLabel = display.newLabel(28, 138, {text = __('活动规则'), fontSize = 24, color = '#ffffff', w = 974, ap = cc.p(0, 1)})
	--view:addChild(ruleLabel, 10)
	-- 奖励
	local goodsIcon = require('common.GoodNode').new({id = 890002, amount = 1, showAmount = false})
	goodsIcon:setScale(0.8)
	goodsIcon:setPosition(cc.p(388, 194))
	view:addChild(goodsIcon, 10)
	local voucherNums = display.newImageView(_res('ui/home/activity/activity_chaode_1500.png'), 510, 186)
	view:addChild(voucherNums, 10)
	local rareTitle = display.newImageView(_res('ui/home/activity/activity_chaode_words_exchange.png'), 690, 180)
	view:addChild(rareTitle, 10)
	local rareVoucherIcon = sp.SkeletonAnimation:create(
			'effects/activity/CD.json',
			'effects/activity/CD.atlas',
			1)
		rareVoucherIcon:update(0)
		rareVoucherIcon:setToSetupPose()
		rareVoucherIcon:setAnimation(0, 'idle', true)
		rareVoucherIcon:setPosition(cc.p(690, 272))
	view:addChild(rareVoucherIcon, 10) 	
	local rareVoucherNums = display.newImageView(_res('ui/home/activity/activity_chaode_1.png'), 796, 186)
	view:addChild(rareVoucherNums, 10)
	local purchaseBtn = display.newButton(952, 186, {n = _res('ui/common/common_btn_orange.png')})
	view:addChild(purchaseBtn, 10)
	if CommonUtils.IsGoldSymbolToSystem() then
		CommonUtils.SetCardNameLabelStringByIdUseSysFont(purchaseBtn:getLabel() , {fontSize = 24, colorN = "ffffff" , outline = '#734441'} ,string.format(__('￥%s'), '328') )
	else
		display.commonLabelParams(purchaseBtn, fontWithColor(14, {text = string.format(__('￥%s'), '328')}))
	end

	return {
		view 	  = view,
		shopBtn   = shopBtn,
		purchaseBtn  = purchaseBtn,
		timeLabel = timeLabel
	}
end

function ActivitySpecialCapusleView:ctor( ... )
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
end

return ActivitySpecialCapusleView
