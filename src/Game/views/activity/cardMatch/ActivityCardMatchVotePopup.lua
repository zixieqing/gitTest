--[[
飨灵投票初赛投票弹窗
--]]
local CommonDialog = require('common.CommonDialog')
local ActivityCardMatchVoteCardNode = require('Game.views.activity.cardMatch.ActivityCardMatchVoteCardNode')
---@class ActivityCardMatchVotePopup
local ActivityCardMatchVotePopup = class('ActivityCardMatchVotePopup', CommonDialog)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local CreateView     = nil
local CreateCardNode = nil

local RES_DICT = {
    COMMON_BG_7                     = _res('ui/common/common_bg_7.png'),
    COMMON_BG_TITLE_2               = _res('ui/common/common_bg_title_2.png'),
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    COMMON_TITLE_5                  = _res('ui/common/common_title_5.png'),
    MARKET_BUY_BG_INFO              = _res('ui/home/commonShop/market_buy_bg_info.png'),
    MARKET_SOLD_BTN_PLUS            = _res('ui/home/market/market_sold_btn_plus.png'),
    MARKET_SOLD_BTN_SUB             = _res('ui/home/market/market_sold_btn_sub.png'),
}

function ActivityCardMatchVotePopup:InitialUI()
	self.datas = self.args.data
	self.selectNum  = 1
	self.maxSelectNum = self.args.maxSelectNum
	local size = self.args.size or cc.size(558, 589)
	xTry(function ( )
		self.viewData = CreateView(size)

		self:InitView()

	end, __G__TRACKBACK__)
end

function ActivityCardMatchVotePopup:InitView()
	local viewData = self:GetViewData()
	display.commonUIParams(viewData.numBtn,      {cb = handler(self, self.OnClickNumAction)})
	display.commonUIParams(viewData.minusBtn,    {cb = handler(self, self.OnClickMinusAction)})
	display.commonUIParams(viewData.addBtn,      {cb = handler(self, self.OnClickAddAction)})

	self:RefreshUI()
end

function ActivityCardMatchVotePopup:RefreshUI()
	local viewData = self:GetViewData()
	local datas = self.datas
	self:UpdateCardNode(datas.rankData, datas.cardId)

	local goodsId          = datas.goodsId
	local ownNumLabel           = viewData.ownNumLabel
	local ownNum = CommonUtils.GetCacheProductNum(goodsId)
	--ownNumLabel:setVisible(ownNum > 0)
	display.commonLabelParams(ownNumLabel, {text = string.format(__('拥有:%s'), ownNum)})
	self:UpdatePricePos()

	viewData.goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(goodsId))

	self:UpdateSelectNum()
end

function ActivityCardMatchVotePopup:UpdateCardNode(rankData, cardId)
	local cardNode = self:GetViewData().cardNode
	cardNode:RefreshUI(rankData, cardId)
end

---UpdateSelectNum
---更新选择数量
function ActivityCardMatchVotePopup:UpdateSelectNum()
	local viewData = self:GetViewData()
	local numBtn   = viewData.numBtn
	display.commonLabelParams(numBtn, {text = self.selectNum})
	viewData.purchaseBtn:setUserTag(self.selectNum)
end

---UpdatePricePos
---更新价格位置
function ActivityCardMatchVotePopup:UpdatePricePos()
	local viewData        = self:GetViewData()
	local ownNumLabel     = viewData.ownNumLabel
	local goodsIcon       = viewData.goodsIcon
	local centrePosX      = viewData.centrePosX
	local ownNumLabelSize = display.getLabelContentSize(ownNumLabel)
	local goodsIconSize   = goodsIcon:getContentSize()

	ownNumLabel:setPositionX(centrePosX - goodsIconSize.width * 0.5 * goodsIcon:getScale())
	goodsIcon:setPositionX(centrePosX + ownNumLabelSize.width * 0.5 )
end

---OnClickNumAction
---点击数字事件
---@param sender userdata 按钮
function ActivityCardMatchVotePopup:OnClickNumAction(sender)
	PlayAudioByClickNormal()
	
	local tempData = {}
	tempData.callback = handler(self, self.NumkeyboardCallBack)
	tempData.titleText = __('请输入需要兑换的数量')
	tempData.nums = 3
	tempData.model = NumboardModel.freeModel

	local NumKeyboardMediator = require( 'Game.mediator.NumKeyboardMediator' )
	local mediator = NumKeyboardMediator.new(tempData)
	app:RegistMediator(mediator)
end

---NumkeyboardCallBack
---数字键盘回调
---@param data table
function ActivityCardMatchVotePopup:NumkeyboardCallBack(data)
	if data then
		self.selectNum = self:CheckSelectNum(data)
		self:UpdateSelectNum()
	end
end

---OnClickMinusAction
---减号事件
---@param sender userdata 按钮
function ActivityCardMatchVotePopup:OnClickMinusAction(sender)
	PlayAudioByClickNormal()
	self.selectNum = self:CheckSelectNum(self.selectNum - 1)
	self:UpdateSelectNum()
end

---OnClickAddAction
---加号事件
---@param sender userdata 按钮
function ActivityCardMatchVotePopup:OnClickAddAction(sender)
	PlayAudioByClickNormal()
	local selectNum = self.selectNum + 1
	if selectNum > self.maxSelectNum then
		uiMgr:ShowInformationTips(string.format(__('最多投%s次'), self.maxSelectNum))
		return
	end
	self.selectNum = self:CheckSelectNum(self.selectNum + 1)
	self:UpdateSelectNum()
end


---CheckSelectNum
---检查选择数量
---@param num number
function ActivityCardMatchVotePopup:CheckSelectNum(num)
	return math.max(math.min(checkint(num), checkint(self.maxSelectNum)), 1)
end

CreateView = function (size)
	------------------view start-------------------

	local centrePosX = size.width * 0.5
	local centrePosY = size.height * 0.5

	local view = display.newLayer(0, 0, {size = size})

	local bg = display.newNSprite(RES_DICT.COMMON_BG_7, centrePosX, size.height * 0.5 ,
	{
		ap = display.CENTER,
	})
	view:addChild(bg)

	local title = display.newButton(centrePosX, 543,
	{
		ap = display.CENTER,
		n = RES_DICT.COMMON_BG_TITLE_2,
		scale9 = true, size = cc.size(256, 36),
		enable = false,
	})
	display.commonLabelParams(title, fontWithColor(7, {text = __('兑换'), fontSize = 24, offset = cc.p(0, -2)}))
	view:addChild(title)

	local cardNode = ActivityCardMatchVoteCardNode.new()
	display.commonUIParams(cardNode, {ap = display.CENTER, po = cc.p(centrePosX, centrePosY + 114)})
	view:addChild(cardNode)

	--兑换数量标签
	local exchangeNumTipLabel = display.newLabel(centrePosX - 105, 230, fontWithColor(16, {text = __('兑换数量'), ap = display.RIGHT_CENTER}))
	view:addChild(exchangeNumTipLabel)

	local numBtn = display.newButton(centrePosX + 20, exchangeNumTipLabel:getPositionY(),
	{
		ap = display.CENTER,
		n = RES_DICT.MARKET_BUY_BG_INFO,
		enable = true, scale9 = true, size = cc.size(180, 44)
	})
	display.commonLabelParams(numBtn, {text = '1', fontSize = 28, color = '#7c7c7c'})
	view:addChild(numBtn)

	local minusBtn = display.newButton(215, exchangeNumTipLabel:getPositionY(),
	{
		ap = display.CENTER,
		n = RES_DICT.MARKET_SOLD_BTN_SUB,
		scale9 = true, size = cc.size(52, 53),
		enable = true,
	})
	view:addChild(minusBtn)

	local addBtn = display.newButton(378, exchangeNumTipLabel:getPositionY(),
	{
		ap = display.CENTER,
		n = RES_DICT.MARKET_SOLD_BTN_PLUS,
		scale9 = true, size = cc.size(52, 53),
		enable = true,
	})
	view:addChild(addBtn)

	local purchaseBtn = display.newButton(centrePosX, 140,
	{
		ap = display.CENTER,
		n = RES_DICT.COMMON_BTN_ORANGE,
		scale9 = true, size = cc.size(123, 62),
		enable = true,
	})
	display.commonLabelParams(purchaseBtn, fontWithColor(14, {text = __('投票')}))
	view:addChild(purchaseBtn)

	local ownNumLabel = display.newLabel(centrePosX, 70,
			{
				ap = display.CENTER,
				fontSize = 22,
				color = '#5c5c5c',
			})
	view:addChild(ownNumLabel)

	local goodsIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(GOLD_ID), centrePosX, ownNumLabel:getPositionY())
	goodsIcon:setScale(0.2)
	view:addChild(goodsIcon)

	-------------------view end--------------------
	return {
		view        = view,
		bg          = bg,
		title       = title,
		cardNode    = cardNode,
		numBtn      = numBtn,
		minusBtn    = minusBtn,
		addBtn      = addBtn,
		ownNumLabel = ownNumLabel,
		purchaseBtn = purchaseBtn,
		goodsIcon   = goodsIcon,

		centrePosX  = centrePosX,
	}

end

CreateCardNode = function (goodsId)
    local goodIcon = ActivityCardMatchVoteCardNode.new({id = goodsId, avatarId = goodsId, nType = nType, configInfo = locationConfig, enable = false})
    return goodIcon
end

function ActivityCardMatchVotePopup:GetViewData()
	return self.viewData
end

return ActivityCardMatchVotePopup
