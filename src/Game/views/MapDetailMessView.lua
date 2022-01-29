--[[
飨灵图鉴故事View
--]]

local MapDetailMessView = class('MapDetailMessView', function()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.MapDetailMessView'
	node:enableNodeEvents()
	node:setCascadeOpacityEnabled(true)
	return node
end)

function MapDetailMessView:ctor( ... )
	self.args = unpack({...}) or {}
	self.viewData_ = nil
	local function CreateView()
		local bgSize = cc.size(482, 599)
		local colorLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
		colorLayer:setTouchEnabled(true)
		colorLayer:setContentSize(bgSize)
		colorLayer:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
		local view = CLayout:create(bgSize)
		view:addChild(colorLayer, -1)
		local bg = display.newImageView(_res('ui/home/handbook/pokede_maps_bg_region_description.png'), bgSize.width/2, bgSize.height/2)
		view:addChild(bg, 1)
		local title = display.newButton(bgSize.width/2, bgSize.height - 40, {n = _res('ui/common/common_title_5'), enable = false,scale9 = true, size = cc.size(186,32)})
		display.commonLabelParams(title, fontWithColor(16, {text = ''}))
		view:addChild(title, 10)

		local listViewSize = cc.size(460, 530)
		local listView = CListView:create(listViewSize)
		listView:setDirection(eScrollViewDirectionVertical)
		listView:setAnchorPoint(cc.p(0.5, 0))
		listView:setPosition(cc.p(bgSize.width/2, 10))
		view:addChild(listView, 5)
		local mask = display.newImageView(_res('ui/home/handbook/pokedex_card_bg_life_up.png'), bgSize.width/2, bgSize.height/2,{scale9 = true,size = bgSize})
		view:addChild(mask, 10)
		-- listView:setBackgroundColor(cc.c4b(100, 200, 100, 128))

		return {
			view      = view,
			listView  = listView,
			title     = title,
			mask 	  = mask,
			bg 	      = bg,
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
	eaterLayer:setOpacity(0)
	self:setOpacity(0)
	self:runAction(cc.FadeIn:create(0.2))
	----------------------------------------
end
return MapDetailMessView
