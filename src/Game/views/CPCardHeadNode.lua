local CardHeadNode = require('common.CardHeadNode')
local CPCardHeadNode = class('CPCardHeadNode', CardHeadNode)

local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function CPCardHeadNode:ctor( ... )
	CPCardHeadNode.super.ctor(self, ...)  
end
--[[
卡牌头像框
@params table 参数集 {
	showStarAndContractLv bool 显示基础信息 -> 星级 契约等级
}
--]]
function CPCardHeadNode:InitValue( ... )
	CPCardHeadNode.super.InitValue(self, ...)  
	local args = unpack({...})

	if checkint(self.specialType) ~= 0 then
		self.showStarAndContractLv = nil
	end

	if nil == self.showStarAndContractLv then
		self.showStarAndContractLv = false
	end
	if nil ~= args.showStarAndContractLv then
		self.showBaseState = false
		self.showStarAndContractLv = true
	end
end

function CPCardHeadNode:InitUI( ... )
	CPCardHeadNode.super.InitUI(self, ...)  

	for i,v in ipairs(self.viewData.stars) do
		v:setVisible(self.showBaseState or self.showStarAndContractLv)
	end

	local size = self.viewData.bg:getContentSize()

	local heartImage = FilteredSpriteWithOne:create()
	heartImage:setCascadeOpacityEnabled(true)
	heartImage:setTexture(_res('ui/prize/collect_prize_contract_ico.png'))
	heartImage:setAnchorPoint(cc.p(0.5, 0.5))
	heartImage:setPosition(cc.p(19, size.height - 14))
	self.viewData.frame:addChild(heartImage)
	heartImage:setVisible(self.showStarAndContractLv)

	local contractLevelLabel = display.newLabel(heartImage:getContentSize().width / 2 - 10, heartImage:getContentSize().height / 2 + 2,
		{text = tostring(self.cardData.favorabilityLevel or '-'), fontSize = 22, color = '#ffffff', outline = '#311717', font = TTF_GAME_FONT, ttf = true, ap = cc.p(0,0.5)})
	heartImage:addChild(contractLevelLabel)
	

	self.viewData.heartImage = heartImage
	self.viewData.contractLevelLabel = contractLevelLabel
end

function CPCardHeadNode:RefreshBaseState( ... )
	CPCardHeadNode.super.RefreshBaseState(self, ...)  

	self.viewData.heartImage:setVisible(self.showStarAndContractLv)
	for i,v in ipairs(self.viewData.stars) do
		v:setVisible(self.showBaseState or self.showStarAndContractLv)
	end

	if not self.showStarAndContractLv then return end

	self.viewData.contractLevelLabel:setString(tostring(self.cardData.favorabilityLevel or '-'))

	for i,v in ipairs(self.viewData.stars) do
		v:removeFromParent()
	end
	self.viewData.stars = {}
	local starAmount = cardMgr.GetCardStar(self.cardId, {breakLevel = self.cardData.breakLevel})
	local psStarAnchorPos = cc.p(19, 29)
	for i = 1, starAmount do
		local star = FilteredSpriteWithOne:create()
		star:setTexture(_res('ui/cards/head/kapai_star_colour.png'))
		star:setScale(0.75 + 0.05 * i)
		star:setAnchorPoint(cc.p(psStarAnchorPos.x / star:getContentSize().width, (star:getContentSize().height - psStarAnchorPos.y) / star:getContentSize().height))
		star:setPosition(cc.p(15 + (i - 1) * 13, 3))
		self.viewData.frame:addChild(star, starAmount - i)
		star:setVisible(self.showBaseState or self.showStarAndContractLv)
		table.insert(self.viewData.stars, star)
	end
end

return CPCardHeadNode