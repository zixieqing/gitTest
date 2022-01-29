--[[

--]]
local GameScene = require( "Frame.GameScene" )

local MapDetailOverView = class('MapDetailOverView', GameScene)


local SliceBackground = require('common.SliceBackground')

function MapDetailOverView:ctor( ... )
    local args = unpack({...})
	self.viewData = nil


    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
    eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
    self:addChild(eaterLayer, -1)


	local function CreateView( ... )
        local bottomView = SliceBackground.new({size = cc.size(1624,1002),
        pic_path_name = "arts/maps/world/cityBgm_00"..args,
        count = 2,cols = 2})
        display.commonUIParams(bottomView, {po  = display.center})
        self:addChild(bottomView)
        --添加效果层页面

        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.size.height + 2 ,{n = _res('ui/common/common_title.png'),enable = false,ap = cc.p(0, 1.0)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = (''), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        self:addChild(tabNameLabel,5)

        local progressBtn = display.newButton( 180, display.size.height - tabNameLabel:getContentSize().height ,{n = _res('ui/manual/mapoverview/pokedex_world_maps_bg_schedule.png'),enable = false,ap = cc.p(0, 1.0)})
        self:addChild(progressBtn,5)
        progressBtn:setVisible(false)

        local tempLabel = display.newLabel(20,progressBtn:getContentSize().height * 0.5 ,fontWithColor(16,{text = __('探索进度:')}))
        tempLabel:setAnchorPoint(cc.p(0,0.5))
        progressBtn:addChild(tempLabel,5)

        local allProgressLabel = display.newLabel(tempLabel:getPositionX() + tempLabel:getBoundingBox().width + 10,progressBtn:getContentSize().height * 0.5, fontWithColor(16,{text = ('0/999')}))
        allProgressLabel:setAnchorPoint(cc.p(0,0.5))
        progressBtn:addChild(allProgressLabel,5)

        local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
        display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
        self:addChild(backBtn, 5)

        local historyBtn = display.newButton(0, 0, {n = _res("ui/manual/mapoverview/pokedex_maps_ico_book.png")})
        display.commonUIParams(historyBtn, {po = cc.p(display.width - historyBtn:getContentSize().width * 0.5 - 30 - display.SAFE_L, 18 + historyBtn:getContentSize().height * 0.5)})
        display.commonLabelParams(historyBtn, {ttf = true, font = TTF_GAME_FONT, text = __('历史'), fontSize = 20, color = 'ffffff',offset = cc.p(0,-40),outline = '89482f',outlineSize = 2})
        self:addChild(historyBtn, 5)

        local cityPointView = CLayout:create(cc.size(1334,1002))
        display.commonUIParams(cityPointView, {po = cc.p(812,501)})
        bottomView:addChild(cityPointView)
        local cityPoint = {}

        --左箭头
        --local leftSwichBtn = display.newButton(0, 0,
        --    {n = _res('ui/home/cardslistNew/card_skill_btn_switch.png'), animate = true})
        --display.commonUIParams(leftSwichBtn, {ap = cc.p(0.5,0.5),po = cc.p(leftSwichBtn:getContentSize().width * 0.5 + 30, 50)})
        --self:addChild(leftSwichBtn,7)
        --leftSwichBtn:setTag(1)
        --leftSwichBtn:setVisible(false)
        --
        ----右箭头
        --local rightSwichBtn = display.newButton(0, 0,
        --    {n = _res('ui/home/cardslistNew/card_skill_btn_switch.png'), animate = true})
        --display.commonUIParams(rightSwichBtn, {ap = cc.p(0.5,0.5),po = cc.p(display.width - rightSwichBtn:getContentSize().width * 0.5 - 30, 50)})
        --self:addChild(rightSwichBtn,7)
        --rightSwichBtn:setRotation(-180)
        --rightSwichBtn:setTag(2)
        --rightSwichBtn:setEnable(false)


        return {
            tabNameLabel = tabNameLabel,
            backBtn     = backBtn,
            cityPoint   = cityPoint,
            cityPointView = cityPointView,
            historyBtn = historyBtn,
            -- leftSwichBtn = leftSwichBtn,
            -- rightSwichBtn = rightSwichBtn,
            bottomView = bottomView,

        }
	end
    self.viewData = CreateView( )
end


return MapDetailOverView
