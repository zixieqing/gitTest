--[[
图鉴选择页面UI
--]]
local HandbookView = class('HandbookView', function ()
	local node = CLayout:create(cc.size(display.width, 1002))
	node.name = 'home.HandbookView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local function CreateView( )
	local view = CLayout:create(cc.size(display.width, 1002))
	-- local centerIcon = display.newButton(330, 494, {n = _res('ui/home/Handbook/pokedex_main_ico.png'), useS = false})
	-- view:addChild(centerIcon, 5)
	-- local centerLabelBg = display.newImageView(_res('ui/home/Handbook/pokedex_main_name_long.png'), 330, 420)
	-- view:addChild(centerLabelBg, 7)
	-- local centerLabel = display.newLabel(330, 420, {text = __('图鉴总进度100%'), color = 'ffffff', fontSize = 20, font = TTF_GAME_FONT, ttf = true, outline = '311717', outlineSize = 1})
	-- view:addChild(centerLabel, 10)
	return {
		view 			      = view,
	}
end

function HandbookView:ctor( ... )
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(utils.getLocalCenter(self))
	self.eaterLayer = eaterLayer
	self:addChild(eaterLayer, -1)
	self.viewData_ = CreateView(  )
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
end
return HandbookView
