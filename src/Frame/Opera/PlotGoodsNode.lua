--[[
 * author : kaishiqi
 * descpt : 主线剧情 - 道具节点
]]
local PlotGoodsNode = class('PlotGoodsNode', function()
	local goodsNode = display.newLayer()
	return goodsNode
end)

local RES_DICT = {
	DESCR_FRAME = _res('arts/stage/ui/club/clue_bg_text.png'),
	DESCR_TITLE = _res('ui/common/common_bg_title_3.png')
}

local plotGoodsConfs = CommonUtils.GetConfigAllMess('plotGoods','plot') or {}

local CreateOldView  = nil
local CreateNewView  = nil
local CreateGoodsImg = nil


function PlotGoodsNode:ctor(args)
	local args    = checktable(args)
	self.goodsId_ = args.id or 'wupin_1'

	self:setContentSize(display.size)
	self:setAnchorPoint(display.CENTER)

	local plotGoodsConf = plotGoodsConfs[tostring(self.goodsId_)]
	if GAME_MODULE_OPEN.NEW_PLOT and plotGoodsConf then
		self.viewData_ = CreateNewView(plotGoodsConf.icon)
		self:addChild(self.viewData_.view)

		display.commonLabelParams(self.viewData_.descrLabel, {text = tostring(plotGoodsConf.descr)})
		display.commonLabelParams(self.viewData_.titleBar, {text = tostring(plotGoodsConf.name), paddingW = 55,offset = cc.p(0,-4)})

	else
		self.viewData_ = CreateOldView(self.goodsId_)
		self:addChild(self.viewData_.view)
	end

	self:setScale(0)
	self:showGoods()
end


CreateGoodsImg = function(goodsId)
	return display.newImageView(_res(string.fmt('arts/goods/%1', goodsId)))
end


CreateOldView = function(goodsId)
	local view = display.newLayer()
	local size = view:getContentSize()

	local goodsImg = CreateGoodsImg(goodsId)
	goodsImg:setPosition(size.width/2, size.height/2)
	view:addChild(goodsImg)

	return {
		view     = view,
		goodsImg = goodsImg,
	}
end


CreateNewView = function(goodsId)
	local view = display.newLayer()
	local size = view:getContentSize()

	local goodsImg = CreateGoodsImg(goodsId)
	goodsImg:setPosition(size.width/2 - 400, size.height/2)
	view:addChild(goodsImg)

	local descrFrame = display.newLayer(size.width/2 + 200, size.height/2, {ap = display.CENTER, bg = RES_DICT.DESCR_FRAME})
	view:addChild(descrFrame)

	local descrFrameSize = descrFrame:getContentSize()
	local goodsTitleBar  = display.newButton(descrFrameSize.width/2, descrFrameSize.height - 40, {n = RES_DICT.DESCR_TITLE, scale9 = true})
	display.commonLabelParams(goodsTitleBar, fontWithColor(4, {text = ''}))
	descrFrame:addChild(goodsTitleBar)

	local descrLabelWidth = descrFrameSize.width - 70
	local goodsDescrPoint = cc.p(descrFrameSize.width/2, goodsTitleBar:getPositionY() - goodsTitleBar:getContentSize().height/2 - 10)
	local goodsDescrLabel = display.newLabel(goodsDescrPoint.x, goodsDescrPoint.y, fontWithColor(5, {color = '#9e8567', ap = display.CENTER_TOP, hAlign = display.TAL, w = descrLabelWidth}))
	descrFrame:addChild(goodsDescrLabel)

	return {
		view       = view,
		titleBar   = goodsTitleBar,
		descrLabel = goodsDescrLabel,
	}
end


function PlotGoodsNode:getViewData()
	return self.viewData_
end


function PlotGoodsNode:showGoods()
	self:runAction(cc.Sequence:create(
		cc.DelayTime:create(0.08),
		cc.FadeIn:create(0.33),
		cc.Spawn:create(
			cc.MoveBy:create(0.13, cc.p(0, 56)), 
			cc.ScaleTo:create(0.13, 0.84)
		),
		cc.ScaleTo:create(0.066, 1.08),
		cc.Spawn:create(
			cc.MoveBy:create(0.033, cc.p(0, 4)), 
			cc.ScaleTo:create(0.033, 0.99)
		),
		cc.ScaleTo:create(0.099, 1.02),
		cc.Spawn:create(
			cc.MoveBy:create(0.099, cc.p(0, -44)), 
			cc.ScaleTo:create(0.099, 1)
		),
		cc.MoveBy:create(0.033, cc.p(0, 9)),
		cc.MoveBy:create(0.033, cc.p(0, -4))
    ))
end


return PlotGoodsNode 
