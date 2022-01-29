--[[
    pt本排行榜view
--]]
local PTDungeonRankView = class('PTDungeonRankView', function ()
    local node = CLayout:create(display.size)
    node.name = 'PTDungeonRankView'
    node:enableNodeEvents()
    return node
end)
local gameMgr = app.gameMgr

function PTDungeonRankView:ctor(...)
    local args = unpack({...})
    self.viewData = nil
    local function CreateView()
        local view = display.newLayer()
        self:addChild(view)

        local bg = display.newImageView(_res('arts/stage/bg/main_bg_06.jpg'), display.cx, display.cy, {isFull = true})
        view:addChild(bg, 1)

        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height,{n = _res('ui/common/common_title_new.png'),enable = false,ap = cc.p(0, 1)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT,  text = __('pt副本排行榜'), reqW  = 260 ,  fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        view:addChild(tabNameLabel, 10)

        -- back btn
        local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
        backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
        view:addChild(backBtn, 20)

        -- 排行榜页签
        local rankListLayout = CLayout:create(cc.size(250, 640))
        rankListLayout:setPosition(cc.p(display.cx - 510, display.cy - 35))
        view:addChild(rankListLayout, 10)
        local rankListBg = display.newImageView(_res('ui/home/rank/rank_bg_liebiao.png'), rankListLayout:getContentSize().width/2, rankListLayout:getContentSize().height/2)
        rankListLayout:addChild(rankListBg, 5)

        local upMask = display.newImageView(_res('ui/home/rank/rank_img_up.png'), 0, rankListLayout:getContentSize().height-2, {ap = cc.p(0, 1)})
        rankListLayout:addChild(upMask, 7)
        local downMask = display.newImageView(_res('ui/home/rank/rank_img_down.png'), 0, 1, {ap = cc.p(0, 0)})
        rankListLayout:addChild(downMask, 7)

        local expandableListView = CExpandableListView:create(cc.size(212, 610))
        expandableListView:setDirection(eScrollViewDirectionVertical)
        expandableListView:setName('expandableListView')
        expandableListView:setPosition(cc.p(115, rankListLayout:getContentSize().height/2))
        rankListLayout:addChild(expandableListView, 10)
        -- 排行榜页面
        local rankLayoutSize = cc.size(1035, 637)
        local rankLayout = CLayout:create(rankLayoutSize)
        rankLayout:setPosition(cc.p(display.cx + 120, display.cy - 35))
        view:addChild(rankLayout, 10)
        local rankBg = display.newImageView(_res('ui/common/common_rank_bg.png'), rankLayoutSize.width/2, rankLayoutSize.height/2)
        rankLayout:addChild(rankBg)
        local titleBg = display.newImageView(_res('ui/home/rank/restaurant_info_bg_rank_title.png'), rankLayoutSize.width/2, rankLayoutSize.height-4, {ap = cc.p(0.5, 1)})
        rankLayout:addChild(titleBg, 3)

        local endLabel = display.newLabel(28, 600, fontWithColor(16, { w = 220 , hAlign = display.TAL ,  text = __('活动结束剩余时间：'), ap = cc.p(0, 0.5)}))
        rankLayout:addChild(endLabel, 10)
        local timeNum = cc.Label:createWithBMFont('font/common_num_1.fnt', '')
        timeNum:setHorizontalAlignment(display.TAR)
        timeNum:setPosition(250 , 605)
        timeNum:setAnchorPoint(cc.p(0, 0.5))
        timeNum:setScale(1.2)
        rankLayout:addChild(timeNum, 10)
        local timeLabel = display.newLabel(195+timeNum:getContentSize().width*1.2, 600, fontWithColor(16, {ap = cc.p(0, 0.5), text = __('天')}))
        rankLayout:addChild(timeLabel, 10)
        local tipsLabel = display.newLabel(28, 565, fontWithColor(6, {text = __('排行榜每小时更新一次排名'), ap = cc.p(0, 0.5)}))
        rankLayout:addChild(tipsLabel, 10)
        -- 排行榜列表
        local size = cc.size(1035, 637)
        local gridViewSize = cc.size(size.width, 486)
        local gridViewCellSize = cc.size(size.width, 112)
        local gridView = CGridView:create(gridViewSize)
        gridView:setSizeOfCell(gridViewCellSize)
        gridView:setAnchorPoint(cc.p(0.5, 1))
        gridView:setColumns(1)
        -- gridView:setAutoRelocate(true)
        rankLayout:addChild(gridView, 10)
        gridView:setPosition(cc.p(size.width/2, 544))

        local myRankBg = display.newImageView(_res('ui/home/rank/restaurant_info_bg_rank_mine.png'), size.width/2, 35)
        rankLayout:addChild(myRankBg, 1)
        local  playerName = display.newLabel(154, 35, {ap = cc.p(0, 0.5), text = gameMgr:GetUserInfo().playerName, fontSize = 22, color = '#a87543'})
        rankLayout:addChild(playerName, 10)

        local scoreBg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_rank_awareness.png'), 880, 35, {scale9 = true, size = cc.size(260, 31)})
        rankLayout:addChild(scoreBg, 5)

        local scoreNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
        scoreNum:setHorizontalAlignment(display.TAR)
        scoreNum:setPosition(1000, 35)
        scoreNum:setAnchorPoint(cc.p(1, 0.5))
        rankLayout:addChild(scoreNum, 10)
        -- 未入榜
        local playerRankLabel = display.newLabel(88, 35, {text = __('未入榜'), fontSize = 22, color = '#ba5c5c'})
        rankLayout:addChild(playerRankLabel, 10)
        -- 自己的排名
        local rankBg = display.newImageView(_res('ui/home/rank/restaurant_info_bg_rank_num1.png'), 88, 35)
        rankLayout:addChild(rankBg, 5)
        rankBg:setVisible(false)
        rankBg:setScale(0.7)
        local playerRankNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
        playerRankNum:setHorizontalAlignment(display.TAR)
        playerRankNum:setPosition(86, 34)
        rankLayout:addChild(playerRankNum, 10)
        -- 查看奖励
        local rewardBtn = display.newButton(1000,  585, {ap = display.RIGHT_CENTER,  tag = 1002, n = _res('ui/common/common_btn_orange.png')})
        rankLayout:addChild(rewardBtn, 10)
        display.commonLabelParams(rewardBtn, {fontSize = 24, color = 'ffffff', font = TTF_GAME_FONT, ttf = true, outline = '734441', paddingW = 10 ,  text = __('查看奖励')})

        return {
            view         = view,
            tabNameLabel = tabNameLabel,
            tabNameLabelPos = cc.p(tabNameLabel:getPosition()),
            rankLayout   = rankLayout,
            gridView     = gridView,
            backBtn      = backBtn,
            timeNum      = timeNum,
            timeLabel    = timeLabel,
            rewardBtn    = rewardBtn,
            scoreNum     = scoreNum,
            playerRankNum = playerRankNum,
            playerRankLabel = playerRankLabel,
            rankBg       = rankBg,
            expandableListView = expandableListView,
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

function PTDungeonRankView:onCleanup()
end

return PTDungeonRankView