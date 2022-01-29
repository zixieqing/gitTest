--[[
活动每日签到Cell
--]]
---@class BlackGoldCommonGoodsCell
local BlackGoldCommonGoodsCell = class('BlackGoldCommonGoodsCell', function ()
	local BlackGoldCommonGoodsCell = CGridViewCell:new()
	BlackGoldCommonGoodsCell.name = 'home.BlackGoldCommonGoodsCell'
	BlackGoldCommonGoodsCell:enableNodeEvents()
	return BlackGoldCommonGoodsCell
end)
local newImageView = display.newImageView
local newLabel = display.newLabel
local newLayer = display.newLayer
local RES_DICT = {
	COMMON_BTN_ORANGE           = _res('ui/common/common_btn_orange.png'),
	GOLD_BINGO_TZ_ICO_HG_SILVER = _res('ui/home/blackShop/gold_bingo_tz_ico_hg_silver.png'),
	GOLD_CARGO_BG_LOCK_GREY = _res('ui/home/blackShop/gold_cargo_bg_lock_grey.png'),
	GOLD_NOW_COMMON_BG_LOCK     = _res('ui/home/blackShop/gold_now_common_bg_lock.png'),
	GOLD_CARGO_BG_LIST          = _res('ui/home/blackShop/gold_cargo_bg_list.png'),
	COMMON_ICO_LOCK             = _res("ui/common/common_ico_lock.png"),
}

function BlackGoldCommonGoodsCell:ctor()
	local cellSize  = cc.size(172, 235)
	self:setContentSize(cc.size(172, 235))
	self:setCascadeOpacityEnabled(true)
	local cGrideLayout = newLayer(172/2, 235/2,
			{ ap = display.CENTER, size = cc.size(172, 235) })
	self:addChild(cGrideLayout)



	local cgrideimage = newImageView(RES_DICT.GOLD_CARGO_BG_LIST, 85, 117,
			{ ap = display.CENTER, tag = 403})
	cGrideLayout:addChild(cgrideimage)
	local buyBtn  = display.newButton(cellSize.width /2 , cellSize.height/2 , {enable = true ,  size = cellSize})
	cGrideLayout:addChild(buyBtn,5)

	local soldStatusLabel = newLabel(86, 212,
			{ ap = display.CENTER, color = '#ffffff', text = "", fontSize = 22, tag = 405 })
	cGrideLayout:addChild(soldStatusLabel)
	soldStatusLabel:setVisible(false)

	local soldOutLabel = display.newLabel(86, 212 ,fontWithColor(4, {text = __('售罄') , outline = false}) )
	cGrideLayout:addChild(soldOutLabel)
	local icoImage = newImageView(CommonUtils.GetGoodsIconPathById(REPUTATION_ID), 140, 23,
			{ ap = display.CENTER, tag = 407, enable = false })
	cGrideLayout:addChild(icoImage)
	icoImage:setScale(0.2)
	---@type GoodNode
	local goodNode = require("common.GoodNode").new({goodsId = GOLD_ID , showAmount = true })
	cGrideLayout:addChild(goodNode)
	goodNode:setPosition(174 /2 ,235/2+10 )

	local goodsNum = newLabel(86, 23,
			{ ap = display.CENTER, color = '#53341d', text = "", fontSize = 22, tag = 408 })
	cGrideLayout:addChild(goodsNum)

	local goodsName = newLabel(86, 58,
			{ ap = display.CENTER, color = '#53341d', text = "", fontSize = 22, tag = 421 })
	cGrideLayout:addChild(goodsName)

	local lockImage = newImageView(RES_DICT.GOLD_NOW_COMMON_BG_LOCK, 85, 117,
			{ ap = display.CENTER, tag = 422, enable = false })
	cGrideLayout:addChild(lockImage)
	lockImage:setVisible(false)
	local lockIcon = newImageView(RES_DICT.COMMON_ICO_LOCK, 83, 124,
			{ ap = display.CENTER, tag = 423, enable = false })
	lockImage:addChild(lockIcon)
	self.viewData = {
		cGrideLayout = cGrideLayout,
		cgrideimage  = cgrideimage,
		buyBtn       = buyBtn,
		soldOutLabel = soldOutLabel,
		soldStatusLabel  = soldStatusLabel,
		icoImage     = icoImage,
		goodNode     = goodNode,
		goodsNum     = goodsNum,
		goodsName    = goodsName,
		lockImage    = lockImage,
		lockIcon     = lockIcon,
	}
end

function BlackGoldCommonGoodsCell:UpdateView(data)
	local viewData = self.viewData
	local unlockGrade = checkint(data.unlockGrade)
	local goodsNum = checkint(data.goodsNum)
	local titleGrade = app.blackGoldMgr:GetTitleGrade()
	local leftPurchasedNum = checkint(data.leftPurchasedNum)
	local name = CommonUtils.GetConfig('goods' , 'goods', data.goodsId).name
	local color = "#53341D"
	viewData.goodNode:RefreshSelf({goodsId = data.goodsId , num = goodsNum })
	if leftPurchasedNum <=  0  then  -- 没有售罄
		color = "#555555"
		viewData.lockImage:setVisible(false)
		viewData.soldStatusLabel:setVisible(false)
		viewData.soldOutLabel:setVisible(true)
		viewData.cgrideimage:setTexture(RES_DICT.GOLD_CARGO_BG_LOCK_GREY)
	else
		if checkint(unlockGrade) >  titleGrade then
			viewData.lockImage:setVisible(true)
		else
			viewData.lockImage:setVisible(false)
		end
		viewData.soldOutLabel:setVisible(false)
		viewData.soldStatusLabel:setVisible(true)
		viewData.cgrideimage:setTexture(RES_DICT.GOLD_CARGO_BG_LIST)
	end
	display.commonLabelParams(viewData.goodsName , {text = name  ,color = color})
	display.commonLabelParams(viewData.goodsNum , {text = data.price   ,color = color})
	display.commonLabelParams(viewData.soldStatusLabel , {text = leftPurchasedNum .. "/" .. data.stock  })
end



return BlackGoldCommonGoodsCell