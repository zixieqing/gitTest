--[[
 * author : liuzhipeng
 * descpt : 新抽卡 双抉卡池 卡池预览cell
--]]
local CapsuleBinaryChoiceCell = class('Game.views.drawCards.CapsuleBinaryChoiceCell',function ()
    local pageviewcell = CTableViewCell:new()
    pageviewcell.name = 'Game.views.CapsuleBinaryChoiceCell'
    pageviewcell:setCascadeOpacityEnabled(true)
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

local EntryNode = require("common.CardPreviewEntranceNode")

function CapsuleBinaryChoiceCell:ctor(...)
    local arg = {...}
    local size = arg[1] or cc.size(230 , 560)
    self:setContentSize(size)
    self.viewData = nil

	local eventNode = CLayout:create(cc.size(200 , 540))
	eventNode:setCascadeOpacityEnabled(true)
    eventNode:setPosition(cc.p(115, 270))
    self:addChild(eventNode)

    local bg = display.newImageView(CardUtils.GetCardTeamFramePathByCardId(CardUtils.DEFAULT_CARD_ID), size.width * 0.5 ,size.height * 0.5)
    eventNode:addChild(bg, 10)

	local lsize = cc.size(200 , 540)
	local roleClippingNode = cc.ClippingNode:create()
	roleClippingNode:setCascadeOpacityEnabled(true)
	roleClippingNode:setContentSize(cc.size(lsize.width , lsize.height - 10))
	roleClippingNode:setAnchorPoint(0.5, 1)
	roleClippingNode:setPosition(cc.p(size.width / 2, lsize.height +10 ))
	roleClippingNode:setInverted(false)
	eventNode:addChild(roleClippingNode, 1)
	-- cut layer
	local cutLayer = display.newLayer(
		0,
		0,
		{
			size = roleClippingNode:getContentSize(),
			ap = cc.p(0, 0),
			color = '#ffcc00'
		})
	cutLayer:setCascadeOpacityEnabled(true)
	local imgHero = AssetsUtils.GetCardDrawNode()
	imgHero:setCascadeOpacityEnabled(true)
	imgHero:setAnchorPoint(display.LEFT_BOTTOM)


	local imgBg = AssetsUtils.GetCardTeamBgNode(0, 0, 0)
	imgBg:setAnchorPoint(display.LEFT_BOTTOM)

	roleClippingNode:setStencil(cutLayer)
	roleClippingNode:addChild(imgHero,1)
	roleClippingNode:addChild(imgBg)

	local skillFrame = display.newImageView(CardUtils.GetCardCareerIconFramePathByCardId(CardUtils.DEFAULT_CARD_ID),32, 532)
	skillFrame:setCascadeOpacityEnabled(true)
	eventNode:addChild(skillFrame,20)
	local skillIcon = display.newImageView(CardUtils.GetCardCareerIconPathByCardId(CardUtils.DEFAULT_CARD_ID),0, 0)
	skillIcon:setPosition(utils.getLocalCenter(skillFrame))
	skillFrame:addChild(skillIcon,2)

	local path = _res(CardUtils.QUALITY_ICON_PATH_MAP[tostring(CardUtils.QUALITY_TYPE.UR)])
    local qualityIcon = display.newImageView(path, 180, 534)
	eventNode:addChild(qualityIcon,20)

	local entryHeadNode = EntryNode.new({skinId = CardUtils.DEFAULT_SKIN_ID, cardDrawChangeType = 1})
	display.commonUIParams(entryHeadNode, {po = cc.p(170, 54)})
	entryHeadNode:setScale(0.9)
    eventNode:addChild(entryHeadNode,20)
	self.viewData = {
		eventNode     = eventNode,
		bg            = bg,
		imgHero       = imgHero,
		heroBg        = imgBg,
		skillFrame    = skillFrame,
		skillIcon     = skillIcon,
		qualityIcon   = qualityIcon,
		entryHeadNode = entryHeadNode,
	}
end

return CapsuleBinaryChoiceCell