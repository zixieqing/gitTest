--[[
抽卡分享界面
@params table {
	cardId int 卡牌id
}
--]]
local CommonShareFrameLayer = require('Game.views.share.CommonShareFrameLayer')
local CapsuleShareLayer = class('CapsuleShareLayer', CommonShareFrameLayer)

--[[
@override
constructor
--]]
function CapsuleShareLayer:ctor(...)
	local args = unpack({...})
	self.cardId = args.cardId
	self.rotate = checkint(args.rotate or 2)
	self.clickStr = args.clickStr or ''
	CommonShareFrameLayer.ctor(self,'Game.views.share.CapsuleShareLayer')
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@overr
初始化ui
--]]
function CapsuleShareLayer:InitUI()
	local cardId = self.cardId
	local rotate = self.rotate
	local clickStr = self.clickStr
	local cardConfig = CommonUtils.GetConfig('cards', 'card', cardId)
	local career = {
		[1] = 'blue',
		[2] = 'red',
		[3] = 'purple',
		[4] = 'green',
	}
	local function CreateView()
		local view = CLayout:create(display.size)
		-- 背景
		local bg = display.newImageView(_res('ui/home/capsule/draw_card_bg.png'), display.cx, display.cy)
		view:addChild(bg, 2)
		local bg2 = display.newImageView(_res('ui/home/capsule/draw_card_bg2.jpg'), display.cx, display.cy)
		view:addChild(bg2, 1)
		local bgMask = display.newImageView(_res('ui/home/capsule/draw_card_bg_mask.png'), display.cx, display.cy)
		view:addChild(bgMask, 6)
		-- 稀有度
		local rareIcon = display.newImageView(CardUtils.GetCardQualityTextPathByCardId(cardId), 192 + display.SAFE_L, display.height - 155, {ap = cc.p(0.5, 0.5)})
		view:addChild(rareIcon, 10)
		-- 名称
		local nameBg = display.newImageView(_res('ui/common/share_bg_name_card.png'), 199 + display.SAFE_L, display.height - 234)
		view:addChild(nameBg, 10)
		local nameLabel = display.newLabel(199 + display.SAFE_L, display.height - 234, fontWithColor(19, {text = cardConfig.name}))
		view:addChild(nameLabel, 10)
		local careerIcon = display.newImageView(_res('ui/home/capsule/card_order_ico_' .. career[checkint(cardConfig.career)] .. '_l.png'), 73 + display.SAFE_L, display.height - 234)
		view:addChild(careerIcon, 10)
		-- cv
		local cvLabel = display.newLabel(55 + display.SAFE_L, display.height - 287, {text = CommonUtils.GetCurrentCvAuthorByCardId(cardId), fontSize = 22, color = '#fca702', ap = cc.p(0, 0.5)})
		view:addChild(cvLabel,10)
		-- 描述
        local descrViewSize  = cc.size(286, 300)
        local descrContainer = cc.ScrollView:create()
        descrContainer:setPosition(cc.p(55 + display.SAFE_L, display.height - 310 - descrViewSize.height))
        descrContainer:setDirection(eScrollViewDirectionVertical)
        -- descrContainer:setAnchorPoint(display.CENTER_TOP)
        descrContainer:setViewSize(descrViewSize)
        view:addChild(descrContainer,10)

        local descrShareLabel = display.newLabel(55 + display.SAFE_L, display.height - 310, {text = cardConfig.descr, fontSize = 22, color = 'ffffff', ap = cc.p(0, 1), w = 286})
        view:addChild(descrShareLabel, 12)
        descrShareLabel:setVisible(false)
		local descrLabel = display.newLabel(0, 0, {hAlign = display.TAL,text = cardConfig.descr, fontSize = 22, color = 'ffffff', ap = cc.p(0, 1), w = descrViewSize.width})
        descrContainer:setContainer(descrLabel)
        local descrScrollTop = descrContainer:getViewSize().height - display.getLabelContentSize(descrLabel).height
        descrContainer:setContentOffset(cc.p(0, descrScrollTop))

		-- 卡牌 背景 / 前景
		local cardSkinId = app.cardMgr.GetCardSkinIdByCardId(cardId)
		local cardBgNode = AssetsUtils.GetCardDrawBgNode(cardSkinId, display.cx, display.cy)
		local cardFgNode = AssetsUtils.GetCardDrawFgNode(cardSkinId, display.cx, display.cy)
		view:addChild(cardBgNode, 3)
		view:addChild(cardFgNode, 5)
		-- 卡牌立绘
		local cardDrawNode = require('common.CardSkinDrawNode').new({confId = cardId, coordinateType = COORDINATE_TYPE_CAPSULE})
		cardDrawNode:setAnchorPoint(cc.p(0.21, 0.5))
		cardDrawNode:setPosition(cc.p(display.width * 0.47, display.height / 2))
		view:addChild(cardDrawNode, 4)

		-- 轮盘
		local dotPos = {
			{x = 151, y = 263},
			{x = 194, y = 254},
			{x = 230, y = 229},
			{x = 252, y = 190},
			{x = 257, y = 146},
			{x = 243, y = 104},
			{x = 214, y = 71},
			{x = 174, y = 53},
			{x = 129, y = 53},
			{x = 89, y = 71},
			{x = 59, y = 103},
			{x = 45, y = 145},
			{x = 50, y = 189},
			{x = 72, y = 228},
			{x = 107, y = 254},
		}
		local clickLabel = {}
		for i = 1, string.len(clickStr), 1 do
			table.insert(clickLabel, string.sub(clickStr, i, i))
		end
		local wheelBg = display.newImageView(_res('ui/home/capsule/share_conjure_metaphysics_plate.png'), display.width - display.SAFE_L - 35, 322, {ap = cc.p(1, 0.5)})
		view:addChild(wheelBg, 10)
		local middleIcon = display.newImageView(_res('ui/home/capsule/share_conjure_metaphysics_full.png'), 151, 157)
		wheelBg:addChild(middleIcon)
		if #clickLabel == 15 then
			middleIcon:setVisible(true)
		else
			middleIcon:setVisible(false)
		end
		for i,v in ipairs(dotPos) do
			local dotBg = display.newImageView(_res('ui/home/capsule/share_conjure_metaphysics_slot.png'), v.x, v.y)
			wheelBg:addChild(dotBg, 3)
			if clickLabel[i] then
				local dot = display.newImageView(_res(string.format('ui/home/capsule/share_conjure_metaphysics_%s.png', clickLabel[i])), v.x, v.y)
				wheelBg:addChild(dot, 3)
				dot:setOpacity(0)
				dot:runAction(
					cc.Sequence:create(
						cc.DelayTime:create(i*0.05),
						cc.FadeIn:create(0.2)
					)
				)
			end
		end
		-- 指针
		local pointerBg = display.newImageView(_res('ui/home/capsule/share_conjure_metaphysics_table.png'), display.width - 10 - display.SAFE_L, 200, {ap = cc.p(1, 0.5)})
		view:addChild(pointerBg, 10)
		local pointer = display.newImageView(_res('ui/home/capsule/share_conjure_metaphysics_arrow.png'), 93, 40, {ap = cc.p(0.785, 0.5)})
		pointerBg:addChild(pointer)
		pointer:setRotation(0)
		pointer:runAction(cc.RotateTo:create(0.2, rotate))
		return {
			view = view,
            descrContainer = descrContainer,
            descrShareLabel = descrShareLabel,
		}
	end

	xTry(function ( )
		self.viewData = CreateView()
		self:addChild(self.viewData.view, 1)
		self.viewData.view:setPosition(display.center)
	end, __G__TRACKBACK__)

end

function CapsuleShareLayer:ShareAction(isVisible)
    if self.viewData.descrContainer then
        self.viewData.descrContainer:setVisible(isVisible)
        self.viewData.descrShareLabel:setVisible(not isVisible)
    end
end
---------------------------------------------------
-- init end --
---------------------------------------------------

return CapsuleShareLayer
