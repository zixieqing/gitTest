--[[
NPC图鉴主页面Scene
--]]
local GameScene = require( "Frame.GameScene" )
local RankingListScene = class('RankingListScene', GameScene)
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function RankingListScene:ctor(...)
	self.super.ctor(self,'views.RankingListScene')
    local args = unpack({...})
    self.viewData = nil
    local function CreateView()
        local view = display.newLayer()
        self:addChild(view)

        local bg = display.newImageView(_res('arts/stage/bg/main_bg_06.jpg'), display.cx, display.cy, {isFull = true})
        view:addChild(bg, 1)

        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height,{n = _res('ui/common/common_title_new.png'),enable = false,ap = cc.p(0, 1)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('排行榜'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        view:addChild(tabNameLabel, 10)

        -- back btn
        local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
        backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
        view:addChild(backBtn, 20)

        -- 排行榜列表
        local rankListLayout = CLayout:create(cc.size(250, 640))
        rankListLayout:setPosition(cc.p(display.cx - 510, display.cy - 35))
        view:addChild(rankListLayout, 10)
        local rankListBg = display.newImageView(_res('ui/home/rank/rank_bg_liebiao.png'), rankListLayout:getContentSize().width/2, rankListLayout:getContentSize().height/2)
        rankListLayout:addChild(rankListBg, 5)

        local upMask = display.newImageView(_res('ui/home/rank/rank_img_up.png'), 0, rankListLayout:getContentSize().height-2, {ap = cc.p(0, 1)})
        rankListLayout:addChild(upMask, 7)
        local downMask = display.newImageView(_res('ui/home/rank/rank_img_down.png'), 0, 1, {ap = cc.p(0, 0)})
        rankListLayout:addChild(downMask, 7)
        local listViewSize = cc.size(212, 610)
        local listView = CListView:create(listViewSize)
        listView:setDirection(eScrollViewDirectionVertical)
        listView:setAnchorPoint(cc.p(0.5, 0.5))   
        listView:setPosition(cc.p(115, rankListLayout:getContentSize().height/2))  
        rankListLayout:addChild(listView, 10)
        -- 排行榜列表
        local rankLayoutSize = cc.size(1035, 637)
        local rankLayout = CLayout:create(rankLayoutSize)
        rankLayout:setPosition(cc.p(display.cx + 120, display.cy - 35))
        view:addChild(rankLayout, 10)
        local rankBg = display.newImageView(_res('ui/common/common_rank_bg.png'), rankLayoutSize.width/2, rankLayoutSize.height/2)
        rankLayout:addChild(rankBg)
        local titleBg = display.newImageView(_res('ui/home/rank/restaurant_info_bg_rank_title.png'), rankLayoutSize.width/2, rankLayoutSize.height-4, {ap = cc.p(0.5, 1)})
        rankLayout:addChild(titleBg, 3)

		-- 全空状态
		local bgSize = cc.size(880, 637)
		local emptyView = display.newLayer(bgSize.width * 0.5 - 8, bgSize.height * 0.5 - 40,{size = bgSize, ap = cc.p(0.5,0.5)})
		emptyView:setName('empty')
		rankLayout:addChild(emptyView,20)
	
		local msgEmptyLabel = display.newLabel(
			bgSize.width * 0.58,
			bgSize.height * 0.5,
			fontWithColor('14', {text = __('没有排行榜数据')}))
        emptyView:addChild(msgEmptyLabel)
        emptyView:setVisible(false)
        
		return { 
            view         = view,
            tabNameLabel = tabNameLabel,
            tabNameLabelPos = cc.p(tabNameLabel:getPosition()),
            listView     = listView,
            rankLayout   = rankLayout,
            -- titleLabel   = titleLabel,
            gridView     = gridView,
            emptyView    = emptyView,
            backBtn      = backBtn
        }
    end
    -- colorLayer
    local colorLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
    colorLayer:setTouchEnabled(true)
    colorLayer:setContentSize(display.size)
    colorLayer:setAnchorPoint(cc.p(0.5, 0.5))
    colorLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(colorLayer, -10)
    
    self.viewData = CreateView()

    self.viewData.tabNameLabel:setPositionY(display.height + 100)
    local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, self.viewData.tabNameLabelPos))
    self.viewData.tabNameLabel:runAction( action )
end

function RankingListScene:onCleanup()
end

return RankingListScene