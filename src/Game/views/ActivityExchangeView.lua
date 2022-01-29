--[[
道具兑换活动view
--]]
local ActivityExchangeView = class('ActivityExchangeView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.ActivityExchangeView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local ACTIVITY_TAG = {
	FULL_SERVER             = '1',      -- 全服活动类型  其特点  1.显示会获得的奖励  2. 标题美术绘制背景上
	LOBBY_ACTIVITY          = '2',      -- 餐厅活动类型  其特点  1.spine
}

local ACTIVITY_DATA = {
	-- [ACTIVITY_TAG.FULL_SERVER] =
}

local VIEW_SIZE = cc.size(1035, 637)

local CreateViewByTag   = nil
local CreateRewardLayer = nil

local CreateSpineMonster_ = nil
local CreateMenuGood_     = nil

local function CreateCommonView(size)
	local view = CLayout:create(size)

	-- 背景
	local bg = lrequire('root.WebSprite').new({url = '', hpath = _res('ui/home/activity/activity_bg_loading.jpg'), tsize = cc.size(1028,630)})
    -- bg:setVisible(false)
    bg:setAnchorPoint(display.CENTER)
    bg:setPosition(cc.p(size.width/2, size.height/2))
	view:addChild(bg, 1)

	-- local title = display.newImageView(data.TITLE_IMG, 754, 524)
	-- title:setVisible(false)
	-- view:addChild(title, 5)

	local timeBg = display.newImageView(_res('ui/home/activity/activity_time_bg.png'), 1030, 600, {ap = display.RIGHT_CENTER , scale9 = true , size = isKoreanSdk() and cc.size(268 ,47) or cc.size(400 ,47) })
	local timeBgSize = timeBg:getContentSize()
	view:addChild(timeBg, 5)
	local timeTitleLabel = display.newLabel(25, timeBgSize.height / 2, fontWithColor(18, {text = __('剩余时间:'), ap = display.LEFT_CENTER}))
	local timeTitleLabelSize = display.getLabelContentSize(timeTitleLabel)
	timeBg:addChild(timeTitleLabel, 10)
	local timeLabel = display.newLabel(timeTitleLabel:getPositionX() + timeTitleLabelSize.width + 5, timeTitleLabel:getPositionY(), {text = '', ap = cc.p(0, 0.5), fontSize = 22, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	timeBg:addChild(timeLabel, 10)

    -- 立绘
	-- local clipNode = cc.ClippingNode:create()
	-- clipNode:setPosition(cc.p(0, 0))
	-- view:addChild(clipNode, 3)
	-- local stencilNode = display.newNSprite(_res('ui/home/activity/activity_bg_sign.jpg'), size.width/2, size.height/2)
	-- clipNode:setAlphaThreshold(0.1)
	-- clipNode:setStencil(stencilNode)
	-- clipNode:setVisible(false)

	-- local role = CommonUtils.GetRoleNodeById('role_13', 1)
	-- display.commonUIParams(role, {po = cc.p(306, 0)})
	-- role:setScale(0.8)
	-- clipNode:addChild(role)



	-- 跳转按钮
	local enterBtn = display.newButton(754, 191, {ap = display.CENTER, n = _res('ui/common/common_btn_big_orange.png')})
	view:addChild(enterBtn, 10)
	display.commonLabelParams(enterBtn, fontWithColor(14, {text = __('前 往')}))
	local redPoint = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), enterBtn:getContentSize().width-20, enterBtn:getContentSize().height-15)
	redPoint:setName('BTN_RED_POINT')
	redPoint:setVisible(false)
	enterBtn:addChild(redPoint)
	-- 活动规则
	--local ruleTitleBg = display.newImageView(_res('ui/home/activity/activity_exchange_bg_rule_title.png'), 100, 164)
	--view:addChild(ruleTitleBg, 5)
	--local ruleTitleLabel = display.newLabel(88, 168, {text = __('活动规则'), fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	--view:addChild(ruleTitleLabel, 10)
	local ruleTitleBg  = display.newButton(20,170, { n = _res('ui/home/activity/activity_exchange_bg_rule_title.png') ,enable = true , scale9 = true , ap = display.LEFT_CENTER  } )
	display.commonLabelParams(ruleTitleBg, fontWithColor('14',{text= __('活动规则') , offset = cc.p( -15, 0) ,paddingW = 30}) )
	view:addChild(ruleTitleBg, 9 )
	local ruleBg = display.newImageView(_res('ui/home/activity/activity_exchange_bg_rule.png'), size.width/2, 3, {ap = cc.p(0.5, 0)})
	view:addChild(ruleBg, 5)
	local ruleLabel  = display.newLabel(0,0 ,fontWithColor('18', { fontSize = 22, ap =  display.CENTER , w = 970,hAlign = display.TAL, text = "" } )  )
	--ruleImage:addChild(ruleLabel)

	local ruleSize = display.getLabelContentSize( ruleLabel)
	local ruleLayout  = display.newLayer(0, 0,{size = ruleSize ,ap = cc.p(0, 1)})
	ruleLayout:addChild(ruleLabel)
	ruleLabel:setPosition(ruleSize.width/2 ,ruleSize.height/2)
	local listViewSize = cc.size(970 , 130)
	local listView = CListView:create(listViewSize)
	listView:setBounceable(true )
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setAnchorPoint(display.LEFT_TOP)
	listView:setPosition(34, 142)
	view:addChild(listView  , 10 )
	listView:insertNodeAtLast(ruleLayout)
	listView:reloadData()

	return {
		bg        = bg,
		view 	  = view,
		enterBtn  = enterBtn,
		timeLabel = timeLabel,
		timeTitleLabel = timeTitleLabel,
		ruleLabel = ruleLabel,
		timeBg = timeBg ,
		listView = listView ,
		ruleLayout = ruleLayout ,
		-- rewardLayer = rewardLayer,
	}
end

function ActivityExchangeView:ctor( ... )
	local args = unpack({...})
	self.tag = checktable(args).tag

	self.viewData_ = CreateCommonView(VIEW_SIZE)
	self.tagViewData_ = CreateViewByTag(self.tag, VIEW_SIZE)

	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:addChild(self.tagViewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
	self.tagViewData_.view:setPosition(utils.getLocalCenter(self.viewData_.view))

end

function ActivityExchangeView:updateUi(data)

	if self.tag == ACTIVITY_TAG.FULL_SERVER then


	elseif self.tag == ACTIVITY_TAG.LOBBY_ACTIVITY then
		-- self.viewData_.bg:setTexture(_res('ui/home/activity/activity_restaurant_bg.jpg'))
		
	end
end

function ActivityExchangeView:CreateSpineMonster(node, i, id)
	return CreateSpineMonster_(node, i, id)
end

function ActivityExchangeView:CreateMenuGood()
	return CreateMenuGood_()
end

CreateViewByTag = function (tag, size)
	local view = CLayout:create(size)
	local rewardLayer     = nil
	local title           = nil
	local qCardLayer      = nil
	local firstTitle      = nil
	local firstIcon       = nil
	local firstGoodLayer  = nil
	local secondTitle     = nil
	local secondIcon      = nil
	local secondGoodLayer = nil
	if tag == ACTIVITY_TAG.FULL_SERVER then
		-- 奖励预览
		local rewardLayerSize = cc.size(486, 202 + 35)
		rewardLayer = display.newLayer(754, 235, {ap = display.CENTER_BOTTOM, size = rewardLayerSize})
		rewardLayer:setVisible(false)
		view:addChild(rewardLayer, 2)
		local rewardTitle = display.newButton(rewardLayerSize.width/2, rewardLayerSize.height, {n = _res('ui/common/common_title_5.png'), enable = false, ap = display.CENTER_TOP, scale9 = true })
		display.commonLabelParams(rewardTitle, fontWithColor(4, {text = __('奖励一览') , paddingW = 30  }))
		rewardLayer:addChild(rewardTitle)
		local rewardBgImg = display.newImageView(_res('ui/home/activity/activity_bg_prop.png'), rewardLayerSize.width/2, 0, {ap = display.CENTER_BOTTOM})
		rewardLayer:addChild(rewardBgImg)

	elseif tag == ACTIVITY_TAG.LOBBY_ACTIVITY then
		local titleBg = display.newImageView(_res('ui/home/activity/activity_restaurant_title.png'), 80, 550, {ap = display.LEFT_CENTER})
		view:addChild(titleBg)
		title = display.newLabel(titleBg:getContentSize().width / 2, titleBg:getContentSize().height / 2, {text = '神说要有光', ap = display.CENTER, fontSize = 56, color = '#ffdb58'})
		titleBg:addChild(title)

		qCardLayer = display.newLayer(titleBg:getPositionX(), 200, {ap = display.LEFT_BOTTOM, size = cc.size(360, 200)})
		view:addChild(qCardLayer)

		local rewardLayerSize = cc.size(486, 340)
		rewardLayer = display.newLayer(754, 235, {ap = display.CENTER_BOTTOM, size = rewardLayerSize})
		view:addChild(rewardLayer)

		local rewardBgImg = display.newImageView(_res('ui/home/activity/activity_restaurant_bg_prop_2.png'), rewardLayerSize.width/2, 0, {scale9 = true, size = rewardLayerSize, ap = display.CENTER_BOTTOM})
		rewardLayer:addChild(rewardBgImg)

		firstTitle = display.newButton(rewardLayerSize.width/2, rewardLayerSize.height-10, {n = _res('ui/common/common_title_5.png'), enable = false, ap = display.CENTER_TOP, scale9 = true, size = cc.size(186, 31)})
		local firstTitleSize = firstTitle:getContentSize()
		display.commonLabelParams(firstTitle, fontWithColor(16, {text = __('客人爱好')}))
		local firstW = display.getLabelContentSize(firstTitle:getLabel()).width + 70
		firstTitle:setContentSize(cc.size(math.max(firstW, 186), 31))
		rewardLayer:addChild(firstTitle)

		firstIcon = display.newImageView(_res('ui/home/activity/activity_restaurant_ico_like.png'), 0, firstTitleSize.height / 2, {ap = display.LEFT_CENTER})
		firstTitle:addChild(firstIcon)

		firstGoodLayer = display.newLayer(firstTitle:getPositionX(), firstTitle:getPositionY() - firstTitleSize.height - 10, {ap = display.CENTER_TOP, size = cc.size(rewardLayerSize.width, 120)})
		rewardLayer:addChild(firstGoodLayer)

		secondTitle = display.newButton(rewardLayerSize.width/2, rewardLayerSize.height / 2 - 10, {n = _res('ui/common/common_title_5.png'), enable = false, ap = display.CENTER_TOP, scale9 = true, size = cc.size(186, 31)})
		local secondTitleSize = secondTitle:getContentSize()
		display.commonLabelParams(secondTitle, fontWithColor(16, {text = __('额外奖励')}))
		local secondW = display.getLabelContentSize(secondTitle:getLabel()).width + 70
		secondTitle:setContentSize(cc.size(math.max(secondW, 186), 31))
		rewardLayer:addChild(secondTitle)

		secondIcon = display.newImageView(_res('ui/home/activity/activity_restaurant_ico_reward.png'), 0, secondTitleSize.height / 2, {ap = display.LEFT_CENTER})
		secondTitle:addChild(secondIcon)

		secondGoodLayer = display.newLayer(secondTitle:getPositionX(), secondTitle:getPositionY() - secondTitleSize.height - 10, {ap = display.CENTER_TOP, size = cc.size(rewardLayerSize.width, 120)})
		rewardLayer:addChild(secondGoodLayer)
		
		-- for i = 1, 3 do
		-- 	CreateSpineMonster_(qCardLayer, i, id)
		-- end
	end

	return {
		view              = view,
		rewardLayer       = rewardLayer,
		title             = title,
		qCardLayer        = qCardLayer,
		firstIcon         = firstIcon,
		firstGoodLayer    = firstGoodLayer,
		secondTitle       = secondTitle,
		secondIcon        = secondIcon,
		secondGoodLayer   = secondGoodLayer,
	}
end

CreateRewardLayer = function (parent, size, titleCount)
	local rewardLayer = display.newLayer(754, 200, {ap = display.CENTER_BOTTOM, size = size})
	rewardLayer:setVisible(false)
	parent:addChild(rewardLayer, 2)
end

CreateSpineMonster_ = function(node, i, id)
    if node then
		local avatarSpinePath = string.format("avatar/visitors/%s", tostring(id))
		if FTUtils:isPathExistent(string.format("%s.json", avatarSpinePath)) then
			local qAvatar = sp.SkeletonAnimation:create(
				avatarSpinePath .. '.json',
				avatarSpinePath .. '.atlas',
				0.45)
			qAvatar:update(0)
			qAvatar:setAnimation(0, 'run', true)
			qAvatar:setPosition(cc.p(20 + (i - 1) * 140 , 0))
			node:addChild(qAvatar)
		end
    end
end

CreateMenuGood_ = function ()
	
	local goodBg = display.newImageView(_res("ui/airship/ship_ico_label_goods_tag.png"), 0, 0, {ap = display.LEFT_BOTTOM})
	local goodBgSize = goodBg:getContentSize()
	local goodBgLayer = display.newLayer(0, goodBgSize.height / 2, {size = goodBgSize, ap = display.LEFT_CENTER})

	goodBgLayer:addChild(goodBg)

	local callBack = function (sender)
		local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
		uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
	end

	local goodNode = require('common.GoodNode').new({id = 150061, showAmount = false, callBack = callBack})
    goodNode.fragmentImg:setVisible(false)
	goodNode.bg:setVisible(false)
	display.commonUIParams(goodNode, {po = cc.p(goodBgSize.width / 2, goodBgSize.height / 2)})
	goodBgLayer:addChild(goodNode)

	return {
		goodBgLayer = goodBgLayer,
		goodNode    = goodNode,

		goodBgSize  = goodBgSize,
	}

end

function ActivityExchangeView:setRuleText(ruleDescr)
	local viewData_ = self.viewData_
	display.commonLabelParams(viewData_.ruleLabel , {text = ruleDescr})
	if isElexSdk() then
		local ruleSize = display.getLabelContentSize(viewData_.ruleLabel)
		viewData_.ruleLayout:setContentSize(ruleSize)
		viewData_.ruleLabel:setPosition(ruleSize.width/2, ruleSize.height/2)
		viewData_.listView:reloadData()
	end
end
return ActivityExchangeView
