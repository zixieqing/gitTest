--[[
飨灵收集奖励页面UI
--]]
local GameScene = require( "Frame.GameScene" )

local CardGatherRewardView = class('CardGatherRewardView', GameScene)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function CardGatherRewardView:ctor()
	GameScene.ctor(self,'views.CardEncyclopediaView')
    self:InitUI()
end

local CellWidth = 300
local CellHeight = 160

function CardGatherRewardView:InitUI( ... )
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(utils.getLocalCenter(self))
	self.eaterLayer = eaterLayer
	self:addChild(eaterLayer, -1)

	local function CreateView( )
		local view = CLayout:create(display.size)
		display.commonUIParams(view, {po = display.center})
		self:addChild(view)
		
		-- 背景
		local bg = display.newImageView(_res('ui/home/handbook/pokedex_card_bg.jpg'), display.cx, display.cy, {isFull = true})
		view:addChild(bg)

		-- cp组合背景
		local cardBG = display.newImageView(_res('ui/prize/collect_prize_bg_cp.png'), display.cx + 140, display.cy - 76
			, { scale9 = true, size = cc.size(1000,718), ap = cc.p(0.5, 0.5) })
		view:addChild(cardBG)
	
    	-------------------------------------------------
    	-- 下面的范围
		local areaTabsSize = cc.size(display.width , CellHeight)
		local areaTabsCellSize = cc.size(CellWidth, CellHeight)

		-- 底下地区选择背景
		local areaBG = display.newImageView(_res('ui/prize/collect_prize_bg_area.png'), display.cx, -40, {ap = cc.p(0.5, 0)})
		view:addChild(areaBG, 2)

		-- 地区选择
		local areaTabsView = CListView:create(areaTabsSize)
		areaTabsView:setDirection(eScrollViewDirectionHorizontal)
		areaTabsView:setBounceable(false)
		view:addChild(areaTabsView, 5)
		display.commonUIParams(areaTabsView, {ap = display.CENTER_BOTTOM, po = cc.p(display.cx, 0)})

		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.size.height + 2 ,{n = _res('ui/common/common_title.png'),enable = false,ap = cc.p(0, 1)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('飨灵收集'), fontSize = 30,reqW = 240 , color = '473227',offset = cc.p(0,-8)})
		view:addChild(tabNameLabel,5)

		return {
			view 			      	= view,
			cardBG					= cardBG,
			areaTabsView 			= areaTabsView,
			cellSize				= areaTabsCellSize,
			tabNameLabel 			= tabNameLabel,
			tabNameLabelPos 		= cc.p(tabNameLabel:getPosition()),
		}
	end

	self.viewData = CreateView( )

    self.viewData.tabNameLabel:setPositionY(display.height + 100)
    local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, self.viewData.tabNameLabelPos))
	self.viewData.tabNameLabel:runAction( action )
end

function CardGatherRewardView:CreateCardGatherLayout( areaData, available )
	local CPGroupView = require('Game.views.CPGroupView').new(areaData, available)
	CPGroupView:setPosition(display.center)
	CPGroupView:setAnchorPoint(cc.p(0.5, 0.5))
	self.viewData.view:addChild(CPGroupView, 1)

    return CPGroupView
end

return CardGatherRewardView
