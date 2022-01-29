--[[
飨灵图鉴故事View
--]]

local CardManualStoryView = class('CardManualStoryView', function()
	local node = CLayout:create(display.size)
	node.name = 'common.CardManualStoryView'
	node:enableNodeEvents()
	node:setCascadeOpacityEnabled(true)
	return node
end)

function CardManualStoryView:ctor( ... )
	self.args = unpack({...}) or {}
	self.viewData_ = nil
	local function CreateView()
		local bgSize = cc.size(650, 693)
		local colorLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
		colorLayer:setTouchEnabled(true)
		colorLayer:setContentSize(bgSize)
		colorLayer:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
		local view = CLayout:create(bgSize)
		view:addChild(colorLayer, -1)
		local bg = display.newImageView(_res('ui/home/handbook/pokedex_card_bg_life.jpg'), bgSize.width/2, bgSize.height/2, {})
		view:addChild(bg, 1)
		local title = display.newButton(bgSize.width/2, 655, {n = _res('ui/common/common_title_5'), enable = false})
		display.commonLabelParams(title, fontWithColor(16, {text = ''}))
		view:addChild(title, 10)
		local line = display.newImageView(_res('ui/home/kitchen/kitchen_tool_split_line.png'), bgSize.width/2, 606, {ap = cc.p(0.5, 0)})
		view:addChild(line, 10)
		local listViewSize = cc.size(540, 585)
		local listView = CListView:create(listViewSize)
		listView:setDirection(eScrollViewDirectionVertical)
		listView:setAnchorPoint(cc.p(0.5, 0))
		listView:setPosition(cc.p(bgSize.width/2, 15))
		view:addChild(listView, 5)
		local mask = display.newImageView(_res('ui/home/handbook/pokedex_card_bg_life_up.png'), bgSize.width/2, bgSize.height/2)
		view:addChild(mask, 10)
		local prevBtn = display.newButton(30, 40, {tag = 2001, n = _res('ui/home/cardslistNew/card_skill_btn_switch.png')})
		view:addChild(prevBtn, 10)
		prevBtn:setScale(0.8)
		local nextBtn = display.newButton(bgSize.width - 30, 40, {tag = 2002, n = _res('ui/home/cardslistNew/card_skill_btn_switch.png')})
		nextBtn:setScaleY(0.8)
		nextBtn:setScaleX(-0.8)
		view:addChild(nextBtn, 10)

		return {
			view      = view,
			prevBtn	  = prevBtn,
			nextBtn   = nextBtn,
			listView  = listView,
			title     = title,
			mask 	  = mask,
		}
	end
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	eaterLayer:setCascadeOpacityEnabled(true)
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(utils.getLocalCenter(self))
	self:addChild(eaterLayer, -1)
	self.eaterLayer = eaterLayer
	self.viewData_ = CreateView()
	display.commonUIParams(self.viewData_.view, {po = display.center})
	self:addChild(self.viewData_.view, 1)
	----------------------------------------
	self:setOpacity(0)
	self:runAction(cc.FadeIn:create(0.2))
	----------------------------------------
end
return CardManualStoryView
