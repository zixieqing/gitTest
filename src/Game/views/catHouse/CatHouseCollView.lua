--[[
 * author : weihao
 * descpt : 猫屋 - 收藏柜 界面
]]

---@class CatHouseCollView : Layer
local CatHouseCollView = class('CatHouseCollView', function()
    return ui.layer({name = 'Game.views.catHouse.CatHouseCollView', enableEvent = true})
end)

local RES_DICT={
    COMMON_BG_TIPS              = _res("ui/catHouse/home/common_bg_tips.png"),
    COMMON_BG_TIPS_HORN         = _res("ui/common/common_bg_tips_horn.png"),
    CAT_COLLEC_LOCKERS_BG       = _res("ui/catHouse/trophy/cat_collec_lockers_bg.png"),
    CAT_COLLEC_LOCKERS_BG_1     = _res("ui/catHouse/trophy/cat_collec_lockers_bg_1.png"),
    CAT_COLLECT_ICO_GIFT        = _res("ui/catHouse/trophy/cat_collect_ico_gift.png"),
    CAT_COLLEC_LOCKERS_BG_2     = _res("ui/catHouse/trophy/cat_collec_lockers_bg_2.png"),
    CAT_COLLEC_LOCKERS_WORDS_BG = _res("ui/catHouse/trophy/cat_collec_lockers_words_bg.png"),
    RESTAURANT_ICO_SELLING_LINE = _res("avatar/ui/restaurant_ico_selling_line.png"),
    COMMON_BG_TITLE_2           = _res("ui/common/common_bg_title_2.png"),
    FILTER_BG                   = _res('ui/home/cardslistNew/tujian_selection_frame_1.png'),
    ARROW_BG                    = _res("ui/anniversary20/hang/common_bg_tips_horn.png"),
    CONFIRM_BTN                 = _res('ui/common/common_btn_orange.png'),
    DISABLE_BTN                 = _res("ui/common/common_btn_orange_disable.png"),
}


function CatHouseCollView:ctor(args)
    -- create view
    self:CreateView()
end

function CatHouseCollView:CreateView()
    local closeLayer = display.newLayer(display.cx, display.cy ,{
        ap = display.CENTER,
        size = display.size,
        color = cc.c4b(0,0,0,175),
        enable = true
    })
    self:addChild(closeLayer,0)
    local centerLayout = display.newLayer(display.cx + 17, display.cy  + -8 ,{
        ap = display.CENTER,
        size = cc.size(681,710)
    })
    self:addChild(centerLayout,0)
    local swallowLayer = display.newLayer(340.5, 355 ,{
        ap = display.CENTER,
        size = cc.size(681,710),
        color = cc.c4b(0,0,0,0),
        enable = true
    })
    centerLayout:addChild(swallowLayer,0)
    local bgImage = display.newImageView( RES_DICT.CAT_COLLEC_LOCKERS_BG ,340.5, 355,{ap = display.CENTER})
    centerLayout:addChild(bgImage,0)

    --local prograssLabel = display.newLabel(410.5, 614 , {
    --    fontSize = 24,
    --    ttf = true,
    --    font = TTF_GAME_FONT,
    --    text = '',
    --    color = '#5b3c25',
    --    ap = display.LEFT_CENTER
    --})
    local prograssLabel = display.newButton(520.5, 550 , {
        n = RES_DICT.CAT_COLLEC_LOCKERS_WORDS_BG
    })
    centerLayout:addChild(prograssLabel,0)
    prograssLabel:setVisible(false)
    local titleLabel = display.newButton(339.5, 619  , { n = RES_DICT.COMMON_BG_TITLE_2})
    display.commonLabelParams(titleLabel , fontWithColor(14, {
        fontSize = 24,
        text = __('收藏柜'),
        offset = cc.p(0, -1),
        ap = display.CENTER
    }))
    centerLayout:addChild(titleLabel,0)
    local gridImage = display.newImageView( RES_DICT.CAT_COLLEC_LOCKERS_BG_1 ,340.5, 313,{
        ap = display.CENTER
    })
    centerLayout:addChild(gridImage,0)
    local scrollView = CGridView:create(cc.size(581.4, 515.1))
    scrollView:setSizeOfCell(cc.size(190 , 257 ))
    scrollView:setColumns(3)
    scrollView:setAutoRelocate(true)
    scrollView:setAnchorPoint(display.CENTER)
    scrollView:setPosition(342.4 , 273)
    centerLayout:addChild(scrollView,0)

    self.viewData = {
        closeLayer                = closeLayer,
        centerLayout              = centerLayout,
        swallowLayer              = swallowLayer,
        bgImage                   = bgImage,
        prograssLabel             = prograssLabel,
        titleLabel                = titleLabel,
        gridImage                 = gridImage,
        scrollView                = scrollView,
    }
end

function CatHouseCollView:CreateCell()
    local cell =  CGridViewCell:new()
    local cellLayout = display.newLayer(139.4, 128.5,{
        ap = display.CENTER,
        size = cc.size(190,257)
    })
    local clickLayer = display.newLayer(95 , 128.5 , {
        ap = display.CENTER,
        size = cc.size(190,257) ,
        color = cc.c4b(0,0,0,0), enable = true
    })
    cellLayout:addChild(clickLayer)
    cell:setContentSize(cc.size(190,257))
    cellLayout:setPosition(95 , 128.5 )
    cell:addChild(cellLayout)

    local drawIcon    = FilteredSpriteWithOne:create(RES_DICT.CAT_COLLECT_ICO_GIFT)
    local showGiftBtn = ui.layer({size = drawIcon:getContentSize(), color = cc.r4b(0), enable = true, p = cc.p(148, 203.5)})
    cellLayout:addList(showGiftBtn, 10)
    showGiftBtn:addList(drawIcon):alignTo(nil, ui.cc)

    local lockerBg = display.newImageView(RES_DICT.CAT_COLLEC_LOCKERS_BG_2 , 95 , -10, {ap = display.CENTER_BOTTOM})
    cellLayout:addChild(lockerBg)
    local trophyLabel = display.newLabel(96, 17 ,fontWithColor(14 , {
        w = 160 , hAlign = display.TAC ,
        fontSize = 22,
        outline = false ,
        text = '',
        ap = display.CENTER
    }))
    cellLayout:addChild(trophyLabel,0)
    local filteredSprite = FilteredSpriteWithOne:create(RES_DICT.CAT_COLLECT_ICO_GIFT)
    cellLayout:addChild(filteredSprite,0)
    filteredSprite:setAnchorPoint(display.CENTER_BOTTOM)
    filteredSprite:setPosition(102 , 40)
    cell.viewData = {
        cell           = cell,
        cellLayout     = cellLayout,
        clickLayer     = clickLayer,
        showGiftBtn    = showGiftBtn,
        drawIcon       = drawIcon,
        trophyLabel    = trophyLabel,
        lockerBg       = lockerBg,
        filteredSprite = filteredSprite
    }
    return cell
end

function CatHouseCollView:CreateTipLayout()
    local tipLayer = display.newLayer(display.cx, display.cy ,{ap = display.CENTER,size = display.size})
    self:addChild(tipLayer,10)
    local closeLayer = display.newLayer(display.cx, display.cy ,{
        ap = display.CENTER,
        size = display.size,
        color = cc.c4b(0,0,0,0),
        enable = true ,
        cb = function ()
            tipLayer:setVisible(false)
        end
    })
    tipLayer:addChild(closeLayer,0)
    local tipLayout = display.newLayer(display.cx + 84, display.cy  + 95 ,{
        ap = display.LEFT_CENTER,
        size = cc.size(350,186)
    })
    tipLayer:addChild(tipLayout,0)
    local swallowLayer = display.newLayer(175, 93 ,{
        ap = display.LEFT_CENTER,
        size = cc.size(350,186),
        color = cc.c4b(0,0,0,0),
        enable = true
    })
    tipLayout:addList(swallowLayer,0):alignTo(nil, ui.lc)
    local bgImage = display.newImageView( RES_DICT.COMMON_BG_TIPS ,175, 96.9,{
        ap = display.LEFT_CENTER,
        scale9 = true,
        size = cc.size(357 , 191.8),
        cut = cc.dir(5,5,5,5)
    })
    tipLayout:addList(bgImage,0):alignTo(nil, ui.lc)
    local hornImage = display.newImageView( RES_DICT.COMMON_BG_TIPS_HORN ,-1, 95,{
        ap = display.RIGHT_CENTER
    })
    hornImage:setRotation(-90)
    tipLayout:addChild(hornImage,0)
    local lineImage = display.newImageView( RES_DICT.RESTAURANT_ICO_SELLING_LINE ,175, 151,{
        ap = display.CENTER_BOTTOM
    })
    tipLayout:addChild(lineImage,0)
    local trophyName = display.newLabel(14, 166 , {
        fontSize = 20,
        ttf = true,
        text = '',
        color = '#78564b',
        ap = display.LEFT_CENTER
    })
    tipLayout:addChild(trophyName,0)
    local trophyDescr = display.newLabel(14, 151 , {
        fontSize = 20,
        text = '',color = '#311717',
        w = 320,hAlign = display.TAL,
        ap = display.LEFT_TOP
    })
    tipLayout:addChild(trophyDescr,0)
    local obtainLabel = display.newLabel(306, 8 , {
        fontSize = 20,
        text = '',color = '#323232',
        ap = display.RIGHT_BOTTOM
    })
    tipLayout:addChild(obtainLabel,0)
    self.tipData = {
        tipLayer                  = tipLayer,
        closeLayer                = closeLayer,
        tipLayout                 = tipLayout,
        swallowLayer              = swallowLayer,
        bgImage                   = bgImage,
        hornImage                 = hornImage,
        lineImage                 = lineImage,
        trophyName                = trophyName,
        trophyDescr               = trophyDescr,
        obtainLabel               = obtainLabel
    }
end

function CatHouseCollView:CreateShowGiftLayout(trophyData, drawCB, pos)
    local trophyId   = trophyData.trophyId
    local trophyConf = CONF.CAT_HOUSE.TROPHY_INFO:GetValue(trophyId)
    local giftConf   = checktable(trophyConf.rewards)
    assert(next(giftConf) ~= nil, 'can not find giftReward in local = ' .. trophyId)

    local view      = ui.layer()
    local viewGroup = view:addList({
        ui.layer({color = cc.r4b(0), enable = true, cb = function() view:runAction(cc.RemoveSelf:create()) end}),
        ui.layer()
    })

    ----------------- goodsNode
    local giftLayer = viewGroup[2]
    local giftCells = {}
    local giftScale = 0.8
    for _, goodsData in pairs(giftConf or {}) do
        local goodsNode = ui.goodsNode({id = goodsData.goodsId, num = goodsData.num, showAmount = true, scale = giftScale, defaultCB = true})
        table.insert(giftCells, goodsNode)
    end

    ---------------- drawBtn
    local drawGiftBtn = ui.button({n = RES_DICT.CONFIRM_BTN, d = RES_DICT.DISABLE_BTN, cb = function()
        if drawCB then drawCB(trophyData) end
        view:runAction(cc.RemoveSelf:create())
    end}):updateLabel({fnt = FONT.D14, text = __("领取")})
    local isCanDraw   = checkint(trophyData.progress) >= checkint(trophyConf.targetNum)
    drawGiftBtn:setEnabled(isCanDraw)

    ---------------- calculate size
    local giftSize    = giftCells[1]:getContentSize()
    local viewSize    = cc.size((giftSize.width * giftScale + 5) * #giftCells + drawGiftBtn:getContentSize().width + 30, giftSize.height * giftScale + 30)
    table.insert(giftCells, drawGiftBtn)

    ---------------- create layer
    local frame = ui.layer({size = viewSize, bg = RES_DICT.FILTER_BG, scale9 = true, ap = ui.ct, p = cc.rep(pos, 20, -15)})
    giftLayer:addList(frame)
    local arrow = ui.image({img = RES_DICT.ARROW_BG})
    giftLayer:addList(arrow):alignTo(frame, ui.ct, {offsetY = -14})

    frame:addList(giftCells)
    ui.flowLayout(cc.sizep(viewSize, ui.cc), giftCells, {type = ui.flowH, ap = ui.cc, gapW = 5})

    return view
end

function CatHouseCollView:ShowGiftLayout(trophyData, drawCB, pos)
    local view = self:CreateShowGiftLayout(trophyData, drawCB, pos)
    self:addList(view)
end

---@param data table 奖杯数据
---@deprecated 显示奖杯的信息
function CatHouseCollView:UpdateTipLayout(data,sender)
    if not self.tipData then
        self:CreateTipLayout()
    end
    local parent = sender:getParent()
    local worldPos = parent:convertToWorldSpace(cc.p(sender:getPosition()))
    local nodePos = self.tipData.tipLayer:convertToNodeSpace(worldPos)
    self.tipData.tipLayout:setPosition(cc.p(nodePos.x +100 , nodePos.y) )
    self.tipData.tipLayer:setVisible(true)
    local trophyConf = CONF.CAT_HOUSE.TROPHY_INFO:GetAll()
    local trophyOneConf = trophyConf[tostring(data.trophyId)]
    local name = trophyOneConf.name
    local descr = trophyOneConf.descr
    display.commonLabelParams(self.tipData.trophyName , {fontSize = 20,text = name})
    display.commonLabelParams(self.tipData.trophyDescr , {color = cc.c3b(81,80,80), fontSize = 20,text = descr})
    local progress = checkint(data.progress)
    local targetNum = checkint(trophyOneConf.targetNum)
    display.commonLabelParams(self.viewData.prograssLabel , {fontSize = 22,
        text = string.fmt(__('进度:_num1_/_num2_' ) , { _num1_ = math.min(progress, targetNum) , _num2_ = targetNum})
    })
    self.viewData.prograssLabel:setVisible(true)
    if checkint(data.hasDrawn) == 1 then
        display.commonLabelParams(self.tipData.obtainLabel , {
            color = cc.c3b(188,129,110),
            text = __('获得日期：') .. os.date(__('%Y年%m月%d日'), checkint(data.drawTimestamp) - getServerTimezone() + getClientTimezone())
        })
    else
        display.commonLabelParams(self.tipData.obtainLabel , {
            color = cc.c3b(188,129,110),
            text = __('暂未获取')
        })
    end

    local descrSize = display.getLabelContentSize(self.tipData.trophyDescr)
    local maxH      = descrSize.height + 100
    self.tipData.tipLayout:setContentSize(cc.size(self.tipData.tipLayout:getContentSize().width, maxH))
    self.tipData.bgImage:setContentSize(cc.size(self.tipData.bgImage:getContentSize().width, maxH))
    self.tipData.swallowLayer:setContentSize(cc.size(self.tipData.swallowLayer:getContentSize().width, maxH))
    self.tipData.bgImage:alignTo(nil, ui.lc)
    self.tipData.swallowLayer:alignTo(nil, ui.lc)
    self.tipData.hornImage:alignTo(nil, ui.lc, {offsetX = -25, offsetY = 10})
    self.tipData.trophyName:alignTo(nil, ui.ct, {offsetY = -10})
    self.tipData.lineImage:alignTo(nil, ui.ct, {offsetY = -40})
    self.tipData.trophyDescr:alignTo(nil, ui.ct, {offsetY = -50})
    self.tipData.obtainLabel:alignTo(nil, ui.rb, {offsetY = 10, offsetX = -5})
end

function CatHouseCollView:getViewData()
    return self.viewData_
end


return CatHouseCollView
