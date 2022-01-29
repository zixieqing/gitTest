local DRAW_SPINE_NAME = {
	BG_IDLE = 'idle',
	IDLE    = 'idle1',
}

--[[
卡牌半身立绘
@params table {
	skinId int 皮肤id
	coordinateType COORDINATE_TYPE 坐标类型
	cb function 点击回调
}
--]]
---@class CardSkinDrawNode : CLayout
local CardSkinDrawNode = class('CardSkinDrawNode', function ()
	local node = CLayout:create()
	node.name = 'common.CardSkinDrawNode'
	node:enableNodeEvents()
	return node
end)

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
consturctor
--]]
function CardSkinDrawNode:ctor( ... )
	local args = unpack({...}) or {}
	self.coordinateType = args.coordinateType
	self.isShowBg_      = args.showBg == true

	self:InitAvatar()
	self:setClickCallback(args.clickCB)

	if not args.notRefresh then
		self:RefreshAvatar(args)
	end
end
--[[
初始化立绘
--]]
function CardSkinDrawNode:InitAvatar()
	local bgSize = display.size
	self:setContentSize(bgSize)
	self:setAnchorPoint(cc.p(0, 0))

	-- 初始化触摸监听层
	local touchSize  = cc.size(600, bgSize.height)
	self.touchLayout = display.newLayer(0, bgSize.height/2, {color = cc.r4b(0), size = touchSize, ap = display.LEFT_CENTER})
	self:addChild(self.touchLayout, 10)

	self.touchLayout:setOnClickScriptHandler(function(sender)
		if self.clickCB then
			self.clickCB(self:GetSkinCardId())
		end
	end)
end

function CardSkinDrawNode:setClickCallback(clickCB)
	self.clickCB = clickCB
	self.touchLayout:setTouchEnabled(self.clickCB ~= nil)
end

---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- avatar control begin --
---------------------------------------------------
--[[
获取立绘节点
--]]
function CardSkinDrawNode:GetAvatar()
	return self.avatar
end
function CardSkinDrawNode:GetSpine()
	return self.drawSpine_
end
function CardSkinDrawNode:setFilterName(filterName, ...)
	if self:GetAvatar() then
		self:GetAvatar():setFilterName(filterName, ...)

		if self:GetSpine() then
			if filterName == nil then
				self:GetAvatar():setVisible(false)
				self:GetSpine():setVisible(true)
			else
				self:GetAvatar():setVisible(true)
				self:GetSpine():setVisible(false)
			end
		end
	end
end
--[[
刷新立绘节点
@params skinId   int 皮肤id
@params cardId   int 卡牌id（遍历卡牌数据，找到匹配的cardId）
@params confId   int 配表id（直接卡牌牌表，找到匹配的confId）
@params cardUuid int uuid（遍历卡牌数据，找到匹配的uuid）
--]]
function CardSkinDrawNode:RefreshAvatar(params)
	
	-- 立绘路径
	if params.confId then
		self.cardId   = checkint(params.confId)
		self.skinId   = CardUtils.GetCardSkinId(params.confId)
		self.drawName = CardUtils.GetCardDrawNameBySkinId(self.skinId)

	elseif params.skinId then
		local skinConf = CardUtils.GetCardSkinConfig(params.skinId) or {}
		self.cardId    = checkint(skinConf.cardId)
		self.skinId    = params.skinId
		self.drawName  = CardUtils.GetCardDrawNameBySkinId(self.skinId)

	elseif params.cardUuid then
        local cardData = app.gameMgr:GetCardDataById(params.cardUuid) or {}
        self.cardId    = checkint(cardData.cardId)
		self.skinId    = CardUtils.GetCardSkinId(self.cardId)
		self.drawName  = CardUtils.GetCardDrawNameBySkinId(self.skinId)
		
	else
		self.cardId   = checkint(params.cardId)
		self.skinId   = app.cardMgr.GetCardSkinIdByCardId(params.cardId)
		self.drawName = CardUtils.GetCardDrawNameBySkinId(self.skinId)
	end

	if params.showBg then
		self.isShowBg_ = params.showBg == true
	end

	-- 创建/更新 立绘
	if self.avatar then
		self.avatar:setTexture(AssetsUtils.GetCardDrawPath(self.drawName))
	else
		self.avatar = AssetsUtils.GetCardDrawNode(self.drawName)
		self:addChild(self.avatar)
	end

	-- update draw location
	CommonUtils.FixAvatarLocationAtDrawId(self.avatar, self.drawName, self.coordinateType)

	-- 创建/更新 背景spine
	if self.drawSpine_ then
		self:removeChild(self.drawSpine_)
		self.drawSpine_ = nil
	end
	local drawSpineData = CardUtils.GetCardSpineDrawPathBySkinId(self.skinId)
	if drawSpineData then
		local animeName = self.isShowBg_ and DRAW_SPINE_NAME.BG_IDLE or DRAW_SPINE_NAME.IDLE
		self.drawSpine_ = display.newPathSpine(drawSpineData)
		self.drawSpine_:setAnimation(0, animeName, true)
		self:addChild(self.drawSpine_)

		-- update spine location
		local spineScaleNum = self.avatar:getScale()
		local spineOffsetX  = (0.5 - self.avatar:getAnchorPoint().x) * self.avatar:getContentSize().width * spineScaleNum
		local spineOffsetY  = (0.5 - self.avatar:getAnchorPoint().y) * self.avatar:getContentSize().height * spineScaleNum
		local spinePosition = cc.p(self.avatar:getPositionX() + spineOffsetX, self.avatar:getPositionY() + spineOffsetY)
		self.drawSpine_:setPosition(spinePosition)
		self.drawSpine_:setScale(spineScaleNum)
	end

	-- check visible drawImg or drawSpine
	self.avatar:setVisible(drawSpineData == nil)
end

--[[
获取该立绘皮肤对应的卡牌id
@return _ int 卡牌id
--]]
function CardSkinDrawNode:GetSkinCardId()
	return self.cardId
end

---------------------------------------------------
-- avatar control end --
---------------------------------------------------

function CardSkinDrawNode:onCleanup()
    -- if self.touchEventListener then
        -- self:getEventDispatcher():removeEventListener(self.touchEventListener)
    -- end
end

return CardSkinDrawNode
