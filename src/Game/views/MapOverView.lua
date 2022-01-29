--[[

--]]
local GameScene = require( "Frame.GameScene" )

local MapOverView = class('MapOverView', GameScene)


local SliceBackground = require('common.SliceBackground')

function MapOverView:ctor( ... )
    GameScene.ctor(self,'views.MapOverView')
	self.viewData = nil

	local function CreateView( ... )
        local listSize = cc.size(2858,1598)
        local bottomView = SliceBackground.new({size = cc.size(2856,1596),
        pic_path_name = "ui/manual/mapoverview/world_maps",
        count = 4,cols = 2})
        -- display.commonUIParams(bottomView, {po  = display.center})
        -- self:addChild(bottomView)
        bottomView:setContentSize(listSize)


        local maskImg = display.newImageView(_res('ui/manual/mapoverview/pokedex_maps_bg_up.png'),display.width * 0.5,display.height*0.5, {isFull = true})
        display.commonUIParams(maskImg,{ap = cc.p(0.5,0.5)})
        self:addChild(maskImg,20)




        local mapScrollView = CScrollView:create(display.size)
        mapScrollView:setDirection(eScrollViewDirectionBoth)
        mapScrollView:setAnchorPoint(cc.p(0, 0))
        mapScrollView:setPosition(cc.p(0,0))
        self:addChild(mapScrollView)
        mapScrollView:setContentSize(display.size)
        mapScrollView:setContainerSize(listSize)
        mapScrollView:getContainer():addChild(bottomView,5)
        display.commonUIParams(bottomView, {po  = cc.p(listSize.width*0.5,listSize.height*0.5),ap = cc.p(0.5,0.5)})
        -- mapScrollView:getContainer():setBackgroundColor(cc.c4b(200,0,0,100))
        mapScrollView:setBounceable(false)

        local offset = mapScrollView:getMinOffset()
        mapScrollView:setContentOffset(cc.p(offset.x*0.5,offset.y*0.5 ))

        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.size.height + 2 ,{n = _res('ui/common/common_title.png'),enable = false,ap = cc.p(0, 1.0)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('大陆概述'),  reqW = 250, fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        self:addChild(tabNameLabel,25)

        local progressBtn = display.newButton( 180, display.size.height - tabNameLabel:getContentSize().height ,{n = _res('ui/manual/mapoverview/pokedex_world_maps_bg_schedule.png'),enable = false,ap = cc.p(0, 1.0)})
        self:addChild(progressBtn,5)
        progressBtn:setVisible(false)
        local tempLabel = display.newLabel(20,progressBtn:getContentSize().height * 0.5 ,fontWithColor(16,{text = __('总进度:')}))
        tempLabel:setAnchorPoint(cc.p(0,0.5))
        progressBtn:addChild(tempLabel,5)

        local allProgressLabel = display.newLabel(tempLabel:getPositionX() + tempLabel:getBoundingBox().width + 10,progressBtn:getContentSize().height * 0.5, fontWithColor(16,{text = ('0/999')}))
        allProgressLabel:setAnchorPoint(cc.p(0,0.5))
        progressBtn:addChild(allProgressLabel,5)

        local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
        display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
        self:addChild(backBtn, 25)


        local historyBtn = display.newButton(0, 0, {n = _res("ui/manual/mapoverview/pokedex_maps_ico_book.png")})
        display.commonUIParams(historyBtn, {po =  cc.p(display.width - historyBtn:getContentSize().width * 0.5 - 30 - display.SAFE_L, 18 + historyBtn:getContentSize().height * 0.5)})
        display.commonLabelParams(historyBtn, {ttf = true, font = TTF_GAME_FONT, text = __('历史'), fontSize = 20, color = 'ffffff',offset = cc.p(0,-40),outline = '89482f',outlineSize = 2})--
        self:addChild(historyBtn, 25)

        -- local desBg = display.newImageView(_res('ui/manual/mapoverview/pokedex_world_maps_bg_word'),display.width * 0.5,10)
        -- display.commonUIParams(desBg,{ap = cc.p(0.5,0)})
        -- self:addChild(desBg,2)

        -- local listSize = cc.size(desBg:getContentSize().width - 10,desBg:getContentSize().height - 60)

        -- local scrollView = CScrollView:create(listSize)
        -- scrollView:setDirection(eScrollViewDirectionVertical)
        -- scrollView:setAnchorPoint(cc.p(0.5, 0))
        -- scrollView:setPosition(cc.p(desBg:getPositionX(),desBg:getPositionY()+30))
        -- self:addChild(scrollView,3)
        -- scrollView:getContainer():setBackgroundColor(cc.c4b(100,100,100,100))


        -- local desLabel = display.newLabel(listSize.width*0.5,listSize.height - 5, fontWithColor(16,{w = listSize.width*0.8,text = ('')}))
        -- desLabel:setAnchorPoint(cc.p(0.5,1))
        -- scrollView:getContainer():addChild(desLabel,5)
        -- scrollView:setContainerSize(cc.size(listSize.width, desLabel:getBoundingBox().height+20))
        -- desLabel:setPositionY(scrollView:getContainerSize().height - 5)
        -- scrollView:setContentOffsetToTop()

        --添加各个点
        local cityButtons = {}
        local areaDatas = CommonUtils.GetConfigAllMess('worldMapCoordinate', 'collection')
        if areaDatas then
            for nId,val in orderedPairs(areaDatas) do
                local buttonImage = display.newButton(val.position[1], 1598 - val.position[2], {
                    n = _res('ui/world/global_bg_name_city_default')
                })
                buttonImage:setTag(val.id)
                display.commonLabelParams(buttonImage, {fontSize = 20, color = 'b4601d', text = string.format('%s',val.name), font = TTF_GAME_FONT, ttf = true, offset = cc.p(0, -4)})
                bottomView:addChild(buttonImage, 1)
                cityButtons[tostring(val.id)] = buttonImage
            end
        end

        return {
            tabNameLabel = tabNameLabel,
            backBtn     = backBtn,
            cityButtons = cityButtons,
            -- scrollView  = scrollView,
            -- desLabel    = desLabel,

            mapScrollView = mapScrollView,
            bottomView    = bottomView,
            historyBtn = historyBtn,
            maskImg = maskImg
        }
	end
    self.viewData = CreateView( )

end


return MapOverView
