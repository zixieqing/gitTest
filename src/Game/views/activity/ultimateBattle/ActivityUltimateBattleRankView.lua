--[[
 * author : liuzhipeng
 * descpt : 巅峰对决 排行榜View
--]]
local ActivityUltimateBattleRankView = class('ActivityUltimateBattleRankView', function ()
    local node = CLayout:create(display.size)
    node.name = 'activity.ultimateBattle.ActivityUltimateBattleRankView'
    node:enableNodeEvents()
    return node
end)
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local RES_DICT = {
    MAIN_BG      = _res('arts/stage/bg/main_bg_06.jpg'),
    COMMON_TITLE_NEW = _res('ui/common/common_title_new.png'),
    COMMON_BTN_BACK = _res("ui/common/common_btn_back.png"),
    RANK_BG_LIEBIAO = _res('ui/home/rank/rank_bg_liebiao.png'),
    RANK_IMG_UP = _res('ui/home/rank/rank_img_up.png'),
    RANK_IMG_DOWN = _res('ui/home/rank/rank_img_down.png'),
    COMMON_RANK_BG = _res('ui/common/common_rank_bg.png'),
    RESTAURANT_INFO_BG_RANK_TITLE = _res('ui/home/rank/restaurant_info_bg_rank_title.png'),
    RESTAURANT_INFO_BG_RANK_MINE = _res('ui/home/rank/restaurant_info_bg_rank_mine.png'),
    RESTAURANT_INFO_BG_RANK_AWARENESS = _res('ui/home/lobby/information/restaurant_info_bg_rank_awareness.png'),
    RESTAURANT_INFO_BG_RANK_NUM1 = _res('ui/home/rank/restaurant_info_bg_rank_num1.png'),
    COMMON_BTN_ORANGE = _res('ui/common/common_btn_orange.png'),

    SUMMER_ACTIVITY_ICO_POINT = CommonUtils.GetGoodsIconPathById(app.murderMgr:GetPointGoodsId()),
}

function ActivityUltimateBattleRankView:ctor(...)
    local args = unpack({...})
    self.viewData = nil
    local function CreateView()
        local view = display.newLayer()
        self:addChild(view)

        local bg = display.newImageView(RES_DICT.MAIN_BG, display.cx, display.cy, {isFull = true})
        view:addChild(bg, 1)

        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height,{n = RES_DICT.COMMON_TITLE_NEW,enable = false,ap = cc.p(0, 1)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('排行榜'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        view:addChild(tabNameLabel, 10)

        -- back btn
        local backBtn = display.newButton(0, 0, {n = RES_DICT.COMMON_BTN_BACK})
        backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
        view:addChild(backBtn, 20)

        -- 排行榜页签
        local rankListLayout = CLayout:create(cc.size(250, 640))
        rankListLayout:setPosition(cc.p(display.cx - 510, display.cy - 35))
        view:addChild(rankListLayout, 10)
        local rankListBg = display.newImageView(RES_DICT.RANK_BG_LIEBIAO, rankListLayout:getContentSize().width/2, rankListLayout:getContentSize().height/2)
        rankListLayout:addChild(rankListBg, 5)

        local upMask = display.newImageView(RES_DICT.RANK_IMG_UP, 0, rankListLayout:getContentSize().height-2, {ap = cc.p(0, 1)})
        rankListLayout:addChild(upMask, 7)
        local downMask = display.newImageView(RES_DICT.RANK_IMG_DOWN, 0, 1, {ap = cc.p(0, 0)})
        rankListLayout:addChild(downMask, 7)
        -- local listViewSize = cc.size(212, 610)
        -- local listView = CListView:create(listViewSize)
        -- listView:setDirection(eScrollViewDirectionVertical)
        -- listView:setAnchorPoint(cc.p(0.5, 0.5))   
        -- listView:setPosition(cc.p(115, rankListLayout:getContentSize().height/2))  
        -- rankListLayout:addChild(listView, 10)
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
        local rankBg = display.newImageView(RES_DICT.COMMON_RANK_BG, rankLayoutSize.width/2, rankLayoutSize.height/2)
        rankLayout:addChild(rankBg)
        local titleBg = display.newImageView(RES_DICT.RESTAURANT_INFO_BG_RANK_TITLE, rankLayoutSize.width/2, rankLayoutSize.height-4, {ap = cc.p(0.5, 1)})
        rankLayout:addChild(titleBg, 3)

		local endLabel = display.newLabel(28, 600, fontWithColor(16, {text = __('活动结束剩余时间：'), ap = cc.p(0, 0.5)}))
		rankLayout:addChild(endLabel, 10)
		local timeNum = cc.Label:createWithBMFont('font/common_num_1.fnt', '')
		timeNum:setHorizontalAlignment(display.TAL)
		timeNum:setPosition(display.getLabelContentSize(endLabel).width + 28 , 605)
		timeNum:setAnchorPoint(cc.p(0, 0.5))
        rankLayout:addChild(timeNum, 10)
		local timeNumWidth = display.getLabelContentSize(timeNum).width
		local timeNumX = timeNum:getPositionX()
		local timeLabel = display.newLabel(timeNumX + timeNumWidth + 20  ,  600, fontWithColor(16, {ap = cc.p(0, 0.5), text = __('天')}))
		rankLayout:addChild(timeLabel, 10)
		-- local tipsLabel = display.newLabel(28, 565, fontWithColor(6, {text = __('排行榜每小时更新一次排名'), ap = cc.p(0, 0.5)}))
		-- rankLayout:addChild(tipsLabel, 10)
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
        -- 自身排名
        local myRankBg = display.newImageView(RES_DICT.RESTAURANT_INFO_BG_RANK_MINE, size.width/2, 35)
        rankLayout:addChild(myRankBg, 1)
		local  playerName = display.newLabel(144, 35, {ap = cc.p(0, 0.5), text = gameMgr:GetUserInfo().playerName, fontSize = 22, color = '#a87543'})
		rankLayout:addChild(playerName, 10)


        local scoreTextLabel = display.newLabel(985, 35, {text = "s", fontSize = 30, color = '#5c5c5c'})
        rankLayout:addChild(scoreTextLabel, 10)
        
		local scoreNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
		scoreNum:setHorizontalAlignment(display.TAR)
		scoreNum:setPosition(960, 35)
		scoreNum:setAnchorPoint(cc.p(1, 0.5))
		rankLayout:addChild(scoreNum, 10)
        -- 未入榜
		local playerRankLabel = display.newLabel(88, 35, {text = __('未入榜'), fontSize = 22, color = '#ba5c5c'})
        rankLayout:addChild(playerRankLabel, 10)
        -- 自己的排名
		local rankBg = display.newImageView(RES_DICT.RESTAURANT_INFO_BG_RANK_NUM1, 88, 35)
   		rankLayout:addChild(rankBg, 5)
   		rankBg:setScale(0.7)
		local playerRankNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
		playerRankNum:setHorizontalAlignment(display.TAR)
		playerRankNum:setPosition(88, 35)
		rankLayout:addChild(playerRankNum, 10)
        -- 查看奖励
		local rewardBtn = display.newButton(995, 585, {scale9 = true, ap = display.RIGHT_CENTER ,  tag = 1002, n = RES_DICT.COMMON_BTN_ORANGE})
		rankLayout:addChild(rewardBtn, 10)
		display.commonLabelParams(rewardBtn, {fontSize = 20, color = 'ffffff', font = TTF_GAME_FONT, ttf = true, outline = '734441', paddingW = 10 ,  text = __('查看奖励')})

        return { 
            view         = view,
            tabNameLabel = tabNameLabel,
            tabNameLabelPos = cc.p(tabNameLabel:getPosition()),
            -- listView     = listView,
            rankLayout   = rankLayout,
            -- titleLabel   = titleLabel,
            playerName   = playerName,
            endLabel     = endLabel,
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
            scoreTextLabel  = scoreTextLabel,
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

function ActivityUltimateBattleRankView:onCleanup()
end

return ActivityUltimateBattleRankView