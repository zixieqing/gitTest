--[[
飨灵图鉴大图View
--]]
local CardManualDrawView = class('CardManualDrawView', function()
	return display.newLayer(0, 0, {name = 'common.CardManualDrawView'})
end)

local RES_DICT = {
	DEFAULT_CARD_BG = _res('ui/home/handbook/pokedex_card_bg_xl.jpg'),
	DEFAULT_BOSS_BG = _res('ui/home/handbook/pokedex_boss_bg_xl.jpg'),
}

local ROTATION   = display.width > display.height and -90 or 0
local FORCE_SIZE = display.width > display.height and cc.size(display.height, display.width) or cc.size(display.width, display.height)

function CardManualDrawView:ctor(args)
	local initArgs = checktable(args)

	self:initDrawView()
	self:setClickCallback(initArgs.clickCB)

	self:refreshDrawView(initArgs)
end


function CardManualDrawView:initDrawView()
	-- default bgView
	self.defaultCardBgView_ = display.newImageView(RES_DICT.DEFAULT_CARD_BG, display.cx, display.cy, {rotation = ROTATION})
	self.defaultBossBgView_ = display.newImageView(RES_DICT.DEFAULT_BOSS_BG, display.cx, display.cy, {rotation = ROTATION})
	self:setRotation90FullSceneScale_(self.defaultCardBgView_)
	self:setRotation90FullSceneScale_(self.defaultBossBgView_)
	self:addChild(self.defaultCardBgView_)
	self:addChild(self.defaultBossBgView_)

	-- touch layer
	self.touchLayout_ = display.newLayer(0, 0, {color = cc.r4b(0), enable = true})
	self:addChild(self.touchLayout_, 10)
	
	self.touchLayout_:setOnClickScriptHandler(function(sender)
		if self.clickCB_ then
			self.clickCB_()
		end
	end)
end


function CardManualDrawView:setRotation90FullSceneScale_(viewObj)
	viewObj:setScale(display.width / viewObj:getContentSize().height)
	if viewObj:getScale() * viewObj:getContentSize().height < display.height then
		viewObj:setScale(display.height / viewObj:getContentSize().width)
	end
end


function CardManualDrawView:setClickCallback(clickCB)
	self.clickCB_ = clickCB
	if self.touchLayout_ then
		self.touchLayout_:setTouchEnabled(self.clickCB_ ~= nil)
	end
end


function CardManualDrawView:isObtain(isObtain)
	self.isObtain_ = not (isObtain == false)
	if self.drawView_ then
		if self.isObtain_ then
			self.drawView_:setFilterName()
		else
			self.drawView_:setFilterName(filter.TYPES.GRAY)
		end
	end
end


--[[
	刷新立绘节点
	@params skinId int 皮肤id
	@params cardId int 卡牌id（读取自身数据）
	@params confId int 配表id（直接读卡牌表）
]]
function CardManualDrawView:refreshDrawView(params)

	-- update cardId / skinId
	if params.confId then
		self.cardId_ = checkint(params.confId)
		self.skinId_ = CardUtils.GetCardSkinId(self.cardId_)
		
	elseif params.skinId then
		local skinConf = CardUtils.GetCardSkinConfig(params.skinId) or {}
		self.cardId_   = checkint(skinConf.cardId)
		self.skinId_   = checkint(params.skinId)

	else
		self.cardId_ = checkint(params.cardId)
		self.skinId_ = app.cardMgr.GetCardSkinIdByCardId(self.cardId_)
	end

	-- update default bg
	local isMonster = CardUtils.IsMonsterCard(self.cardId_)
	self.defaultCardBgView_:setVisible(not isMonster)
	self.defaultBossBgView_:setVisible(isMonster)

	-- update drawBgView
	if self.drawBgView_ then
		self.drawBgView_:setTexture(CardUtils.GetCardDrawBgPathBySkinId(self.skinId_))
	else
		self.drawBgView_ = AssetsUtils.GetCardDrawBgNode(self.skinId_, display.cx, display.cy, {forceSize = FORCE_SIZE, isMaxRation = true})
		self.drawBgView_:setRotation(ROTATION)
		self:addChild(self.drawBgView_)
	end

	-- update drawView
	local drawName = CardUtils.GetCardDrawNameBySkinId(self.skinId_)
	if self.drawView_ then
		self.drawView_:setTexture(AssetsUtils.GetCardDrawPath(drawName))
	else
		self.drawView_ = AssetsUtils.GetCardDrawNode(drawName, display.cx, display.cy)
		self.drawView_:setRotation(ROTATION)
		self:addChild(self.drawView_)
	end
	if self.drawBgView_ and self.drawBgView_.displayImg_ then
		-- 根据背景进行一次缩放
		local scale = self.drawBgView_.displayImg_:getScaleX()
		self.drawView_:setScale(scale)
	end
	self:isObtain(params.obtain)

	-- update drawFgView
	if self.drawFgView_ then
		self.drawFgView_:setTexture(CardUtils.GetCardDrawFgPathBySkinId(self.skinId_))
	else
		self.drawFgView_ = AssetsUtils.GetCardDrawFgNode(self.skinId_, display.cx, display.cy, {forceSize = FORCE_SIZE, isMaxRation = true})
		self.drawFgView_:setRotation(ROTATION)
		self:addChild(self.drawFgView_)
	end

	-- update trademarkView
	local skinConf = CardUtils.GetCardSkinConfig(params.skinId) or {}
	if skinConf.trademark and skinConf.trademark ~= '' then
		if self.trademarkView_ then
			self.trademarkView_:setTexture(CardUtils.GetCardTrademarkPath(skinConf.trademark))
		else
			self.trademarkView_ = AssetsUtils.GetCardTrademarkNode(skinConf.trademark, display.width, display.cy)
			self.trademarkView_:setRotation(ROTATION)
			self.trademarkView_:setAnchorPoint(display.CENTER_BOTTOM)
			self:addChild(self.trademarkView_)
		end
	end
end


return CardManualDrawView
