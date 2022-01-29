--[[
    新天成演武 排行榜 视图
--]]
local GameScene = require( "Frame.GameScene" )
---@class NewKofArenaRankScene
local NewKofArenaRankScene = class('NewKofArenaRankScene', GameScene)

local BUTTON_TAG = {
    LAST_WEEK_RANK_BTN = 1001 , -- 查看上周排行
    LOOK_REWARDS       = 1002 , -- 查看排行奖励
    BACK_BTN           = 1003 , -- 返回按钮

}

function NewKofArenaRankScene:ctor(...)
    self.super.ctor(self,'views.NewKofArenaRankScene')
    self.viewData = nil
    local function CreateView()
        local view = display.newLayer(display.cx , display.cy ,{ ap = display.CENTER})
        self:addChild(view)
        view:setPosition(display.center)


        local bg = display.newImageView(_res('arts/stage/bg/main_bg_06.jpg'), display.cx, display.cy, {isFull = true})
        view:addChild(bg, 1)

        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height,{n = _res('ui/common/common_title_new.png'),enable = false,ap = cc.p(0, 1)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('天城演武排行榜'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        view:addChild(tabNameLabel, 10)

        -- back btn
        local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
        backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
        view:addChild(backBtn, 20)
        backBtn:setTag(BUTTON_TAG.BACK_BTN)

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
        local listViewSize = cc.size(250, 610)
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

        --- 顶部的内容
        local titleBg = display.newImageView(_res('ui/home/rank/restaurant_info_bg_rank_title.png'))
        local titleBgSize = titleBg:getContentSize()

        local topLayout = display.newLayer( rankLayoutSize.width/2, rankLayoutSize.height-4, {ap = display.CENTER_TOP , size = titleBgSize , color1 = cc.r4b()  })
        rankLayout:addChild(topLayout,100  )

        topLayout:addChild(titleBg)
        titleBg:setPosition(titleBgSize.width/2 , titleBgSize.height/2)
        -- 上周奖励排行按钮
        local lastWeekRankBtn = display.newButton(titleBgSize.width - 70 ,titleBgSize.height/2 , {tag = BUTTON_TAG.LAST_WEEK_RANK_BTN, n = _res('ui/common/common_btn_white_default.png')})
        topLayout:addChild(lastWeekRankBtn)
        display.commonLabelParams(lastWeekRankBtn, fontWithColor('14' ,{text =__('上周排行榜'), fontSize = 22 }))

        -- 查看奖励的btn
        -- local rewardBtn = display.newButton(titleBgSize.width - 70 , titleBgSize.height/2, {tag = BUTTON_TAG.LOOK_REWARDS, n = _res('ui/common/common_btn_orange.png')})
        -- topLayout:addChild(rewardBtn )
        -- display.commonLabelParams(rewardBtn, fontWithColor('14' ,{text =__('查看奖励') , fontSize = 22}))


        local leftTimeLabel = display.newRichLabel(25, titleBgSize.height/2 , {ap = display.LEFT_CENTER , c= { fontWithColor('10' ,{text = ""  } )} })
        topLayout:addChild(leftTimeLabel )


        local myRankBg = display.newImageView(_res('ui/home/rank/restaurant_info_bg_rank_mine.png'))
        local myRankSize = myRankBg:getContentSize()
        myRankBg:setPosition(cc.p( myRankSize.width/2, myRankSize.height/2))

        -- 自己的myself 内容
        local mySelfLayout = display.newLayer(rankLayoutSize.width/2 ,10 , { ap = display.CENTER_BOTTOM , size =  myRankSize  })
        rankLayout:addChild(mySelfLayout,3)

        mySelfLayout:addChild(myRankBg)

        -- 排行的label
        local notRankLabel = display.newLabel(20 , myRankSize.height/2 ,  fontWithColor('10', {ap = display.LEFT_CENTER , color = '#ba5c5c',text = __("未入榜")  }))
        mySelfLayout:addChild(notRankLabel)
        -- 排名的rankimage
        local rankImage = display.newImageView(_res('ui/home/rank/restaurant_info_bg_rank_num1.png'), 52 ,myRankSize.height/2  )
        mySelfLayout:addChild(rankImage)
        rankImage:setScale(0.8)
        -- 排名
        local rankLabel = display.newLabel(50 ,myRankSize.height/2 , fontWithColor('14',{text = ""}))
        mySelfLayout:addChild(rankLabel)

        -- 玩家的名字
        local playerName = display.newLabel(130, myRankSize.height/2 ,  fontWithColor('10',{ ap = display.LEFT_CENTER ,text = "" , color = "a87543"}))
        mySelfLayout:addChild(playerName)
        -- 赢得场数
        local winTimesLabel = display.newLabel(myRankSize.width - 30 , myRankSize.height/2 ,fontWithColor('14' , {ap = display.RIGHT_CENTER , outline = false , text = "" , color = '5b3c25'}))
        mySelfLayout:addChild(winTimesLabel)


        local gridSize = cc.size(rankLayoutSize.width - 8, 535)
        local gridViewCellSize = cc.size(rankLayoutSize.width - 10, 112)
        -- 刷新gridView
        local gridView = CGridView:create(gridSize)
        gridView:setSizeOfCell(gridViewCellSize)
        gridView:setAnchorPoint(display.CENTER_BOTTOM)
        gridView:setColumns(1)
        gridView:setPosition(cc.p(rankLayoutSize.width/2-5 , 10 ))
        rankLayout:addChild(gridView)
        return {
            view            = view,
            tabNameLabel    = tabNameLabel,
            tabNameLabelPos = cc.p(tabNameLabel:getPosition()),
            listView        = listView,
            gridView        = gridView ,
            rankLayout      = rankLayout,
            -- rewardBtn       = rewardBtn,
            lastWeekRankBtn = lastWeekRankBtn,
            notRankLabel    = notRankLabel ,
            rankImage       = rankImage ,
            playerName      = playerName,
            winTimesLabel   = winTimesLabel,
            mySelfLayout    = mySelfLayout ,
            rankLabel       = rankLabel ,
            leftTimeLabel   = leftTimeLabel ,
            backBtn         = backBtn
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

function NewKofArenaRankScene:onCleanup()

end

return NewKofArenaRankScene