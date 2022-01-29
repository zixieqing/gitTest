--[[
NPC图鉴立绘展示界面
@params table {
	cardId 卡牌id
	breakLevel 突破等级
}
--]]
local GameScene = require( "Frame.GameScene" )
local NPCManualView = class("NPCManualView", GameScene)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function NPCManualView:ctor( ... )
	GameScene.ctor(self, 'Game.views.NPCManualView')
	self.args = unpack({...})
	self:InitUI()
end
--[[
init ui
--]]
function NPCManualView:InitUI()

	local cardConf = CardUtils.GetCardConfig(self.cardId)

	local function CreateView()
		local view = CLayout:create(display.size)
		view:enableNodeEvents()
		-- bg mask
		local bgMask = display.newImageView(_res('ui/home/handbook/pokedex_npc_bg.jpg'), utils.getLocalCenter(self).x, utils.getLocalCenter(self).y, {isFull = true})
		view:addChild(bgMask)

        local npcView = CLayout:create(cc.size(1334, 1002))
        display.commonUIParams(npcView, {po = display.center})
        view:addChild(npcView)

        local tabNameLabel = display.newButton(0, 0,{n = _res('ui/common/common_title_new.png'),enable = false,ap = cc.p(0, 0)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('角色介绍'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})

        tabNameLabel:setPosition(cc.p(130 + display.SAFE_L, display.height + 100))
        view:addChild(tabNameLabel, 10)
		-- back btn
		local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
		display.commonUIParams(backBtn, {po = cc.p(backBtn:getContentSize().width * 0.5 + 30 + display.SAFE_L, display.height - 53)})
		view:addChild(backBtn, 20)
		-- card btn
		local roleBtn = display.newButton(380 + display.SAFE_L, display.cy, {scale9 = true, size = cc.size(540, display.height*0.8)})
		view:addChild(roleBtn, 10)
		-- name label
		local nameLabelBg = display.newButton(248 + display.SAFE_L, 62, {n = _res('ui/home/capsule/draw_card_bg_name.png'), enable = false, ap = cc.p(0, 0)})
		view:addChild(nameLabelBg, 5)
		display.commonLabelParams(nameLabelBg, {text = '', fontSize = 28, color = 'fff1cb', font = TTF_GAME_FONT, ttf = true, offset = cc.p(-40, -2)})
		-- 背景故事
		local size = cc.size(530, 593)
		local layout = CLayout:create(size)
		layout:setPosition(cc.p(display.width - 274 - display.SAFE_L, 118 + (display.height - 750)/2))
		layout:setAnchorPoint(cc.p(0.5, 0))
		view:addChild(layout, 10)
		local storyBg = display.newImageView(_res("ui/home/handbook/pokedex_card_bg_story.png"), size.width/2, size.height/2)
		layout:addChild(storyBg, 3)
		local descrBg = display.newImageView(_res('ui/home/handbook/pokedex_card_bg_story_about.png'), size.width/2, size.height - 5, {ap = cc.p(0.5, 1)})
		layout:addChild(descrBg, 5)
		local storyTitle = display.newButton(size.width/2, size.height - 30, {n = _res('ui/home/handbook/pokedex_card_title.png') ,scale9 = true })
		layout:addChild(storyTitle, 10)
		display.commonLabelParams(storyTitle, fontWithColor(16, {text = __('背景故事')  , paddingW = 20 }))
		local descrLabel = display.newLabel(50, layout:getContentSize().height - 70,
			{text = '', ap = cc.p(0, 1), w = 440, fontSize = 22, color = '#ffeed2'})
		layout:addChild(descrLabel, 10)
		-- 剧情列表
        local listSize = cc.size(size.width-5, 262)
        local listCellSize = cc.size(105, 262)
        local gridView = CTableView:create(listSize)
        gridView:setSizeOfCell(listCellSize)
        gridView:setAutoRelocate(true)
        gridView:setDirection(eScrollViewDirectionHorizontal)
        gridView:setAnchorPoint(cc.p(0.5, 0))
        gridView:setPosition(cc.p(listSize.width/2+4, 0))
        layout:addChild(gridView, 10)
		return {
			view         = view,
			backBtn      = backBtn,
			tabNameLabel = tabNameLabel,
			descrLabel   = descrLabel,
			nameLabelBg  = nameLabelBg,
			layout       = layout,
			gridView     = gridView,
            npcView      = npcView,
			roleBtn      = roleBtn
		}

	end
	-- eaterLayer
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
	xTry(function ( )
		self.viewData = CreateView( )
		self:addChild(self.viewData.view)
		self.viewData.view:setPosition(display.center)
    	local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, cc.p(130 + display.SAFE_L, display.height - 80)))
    	self.viewData.tabNameLabel:runAction( action )
	end, __G__TRACKBACK__)
end
return NPCManualView
