--[[
工会内部排行榜View
--]]
local UnionRankView = class('UnionRankView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.UnionRankView'
    node:enableNodeEvents()
    return node
end)
local function CreateView()
    local bgSize = cc.size(1120, 600)
    local view = CLayout:create(bgSize)
    local maskView = CColorView:create(cc.c4b(0, 0, 0, 0))
    maskView:setTouchEnabled(true)
    maskView:setContentSize(bgSize)
    maskView:setPosition(utils.getLocalCenter(view))
    view:addChild(maskView, -1)
    -- 排行榜列表
    local rankListLayout = CLayout:create(cc.size(250, 600))
    rankListLayout:setPosition(cc.p(bgSize.width/2 - 434, bgSize.height/2))
    view:addChild(rankListLayout, 10)
    local rankListBg = display.newImageView(_res('ui/union/guild_ranking_tab_bg.png'), rankListLayout:getContentSize().width/2, rankListLayout:getContentSize().height/2)
    rankListLayout:addChild(rankListBg, 5)

    local upMask = display.newImageView(_res('ui/home/rank/rank_img_up.png'), 0, rankListLayout:getContentSize().height-2, {ap = cc.p(0, 1)})
    rankListLayout:addChild(upMask, 7)
    local downMask = display.newImageView(_res('ui/home/rank/rank_img_down.png'), 0, 16, {ap = cc.p(0, 0)})
    rankListLayout:addChild(downMask, 7)
    local listViewSize = cc.size(212, 560)
    local listView = CListView:create(listViewSize)
    listView:setDirection(eScrollViewDirectionVertical)
    listView:setAnchorPoint(cc.p(0.5, 0.5))
    listView:setPosition(cc.p(115, rankListLayout:getContentSize().height/2 + 8))
    rankListLayout:addChild(listView, 10)
    -- 排行榜列表
    local rankLayoutSize = cc.size(888, 586)
    local rankLayout = CLayout:create(rankLayoutSize)
    rankLayout:setPosition(cc.p(bgSize.width/2 + 120, bgSize.height/2 + 5))
    view:addChild(rankLayout, 10)
    local rankBg = display.newImageView(_res('ui/common/common_rank_bg.png'), rankLayoutSize.width/2, rankLayoutSize.height/2, {scale9 = true, size = rankLayoutSize})
    rankLayout:addChild(rankBg)
    local titleLabel = display.newLabel(20, 552, {text = '', fontSize = 28, color = '#996032', font = TTF_GAME_FONT, ttf = true, ap = cc.p(0, 0.5)})
    rankLayout:addChild(titleLabel, 10)
    local tipsLabel = display.newLabel(rankLayoutSize.width - 52, 552, fontWithColor(16, {text = __('工会排行榜每小时更新一次'), w = 300 , hAlign = display.TAC,ap = cc.p(1, 0.5)}))
    rankLayout:addChild(tipsLabel, 10)
    local tipsIcon = display.newImageView(_res('ui/common/common_btn_tips.png'), rankLayoutSize.width - 30, 552)
    rankLayout:addChild(tipsIcon, 10)
    local gridViewBg = display.newImageView(_res('ui/common/common_bg_goods.png'), rankLayoutSize.width/2, 12, {ap = cc.p(0.5, 0), scale9 = true, size = cc.size(862, 514)})
    rankLayout:addChild(gridViewBg, 3)
    local gridViewTitleBg = display.newImageView(_res('ui/union/guild_ranking_title.png'), rankLayoutSize.width/2, rankLayoutSize.height - 90, {scale9 = true , size = cc.size(860, 60 )})
    rankLayout:addChild(gridViewTitleBg, 5)
    local rankLabel = display.newLabel(68, rankLayoutSize.height - 90, fontWithColor(6, {text = __('排名')}))
    rankLayout:addChild(rankLabel, 10)
    local playerLabel = display.newLabel(240, rankLayoutSize.height - 90, fontWithColor(6, {text = __('玩家')}))
    rankLayout:addChild(playerLabel, 10)
    local extraLabel = display.newLabel(rankLayoutSize.width - 380, rankLayoutSize.height - 90, fontWithColor(6, {text = ''}))
    rankLayout:addChild(extraLabel, 10)
    local scoreLabel = display.newLabel(rankLayoutSize.width - 104, rankLayoutSize.height - 90, fontWithColor(6, {text = ''}))
    rankLayout:addChild(scoreLabel, 10)   
    local gridViewSize = cc.size(862, 454)
    local gridViewCellSize = cc.size(gridViewSize.width, 112)
    local rankGridView = CGridView:create(gridViewSize)
    rankGridView:setSizeOfCell(gridViewCellSize)
    rankGridView:setAnchorPoint(cc.p(0.5, 0))
    rankGridView:setColumns(1)
    rankLayout:addChild(rankGridView, 10)
    rankGridView:setPosition(cc.p(rankLayoutSize.width/2, 14))
    return {
        view         = view,
        listView     = listView,
        rankLayout   = rankLayout,
        rankGridView = rankGridView,
        titleLabel   = titleLabel,
        extraLabel   = extraLabel,
        scoreLabel   = scoreLabel,
        tipsIcon     = tipsIcon

    }
end
function UnionRankView:ctor( ... )
    self.activityDatas = unpack({...}) or {}
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(utils.getLocalCenter(self))
    eaterLayer:setOnClickScriptHandler(function ()
        AppFacade.GetInstance():UnRegsitMediator('UnionRankMediator')
    end)
    self.eaterLayer = eaterLayer
    self:addChild(eaterLayer, -1)

    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view, 1)
    self.viewData_.view:setPosition(utils.getLocalCenter(self))
end
return UnionRankView
