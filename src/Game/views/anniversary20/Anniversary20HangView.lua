--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 挂机游戏 视图
]]
local Anniversary20HangView = class('Anniversary20HangView', function()
    return ui.layer({name = 'Game.views.anniversary20.Anniversary20HangView', enableEvent = true})
end)

local RES_DICT = {
    --               = top
    BACK_BTN         = _res('ui/common/common_btn_back.png'),
    COM_TITLE_BAR    = _res('ui/common/common_title.png'),
    COM_TIPS_ICON    = _res('ui/common/common_btn_tips.png'),
    --               = center
    BG_IMAGE         = _res('ui/anniversary20/hang/wonderland_ball_bg.jpg'),
    BTN_CONFIRM      = _res('ui/common/common_btn_orange.png'),
    IMAGE_TABLE      = _res("ui/anniversary20/hang/wonderland_table_bg.png"),
    --               = - center plate
    IMAGE_PLATE      = _res("ui/anniversary20/hang/wonderland_ball_plates.png"),
    IMAGE_WHY        = _res("ui/anniversary20/hang/wonderland_ball_btn_plates.png"),
    IMAGE_PLATE_BG   = _res("ui/anniversary20/hang/wonderland_ball_plates_bg.png"),
    --               = below
    BELOW_BG_IMG     = _res("ui/anniversary20/hang/decorate_bg_down.png"),
    REWAR_BG_IMG     = _res("ui/anniversary20/hang/wonderland_ball_rewards_bg.png"),
    ICON_BG_IMG      = _res("ui/anniversary20/hang/wonderland_ball_rewards_ico_bg.png"),
    REWARD_IMG       = _res("ui/anniversary20/hang/goods_icon_190100.png"),
    PRO_ACTIVE       = _res("ui/anniversary20/hang/allround_bg_bar_active.png"),
    PRO_GREY         = _res("ui/anniversary20/hang/allround_bg_bar_grey.png"),
    GOOD_GOT_IMG     = _res("ui/anniversary20/hang/common_btn_check_selected.png"),
    CHECK_IMG        = _res("ui/anniversary20/hang/common_btn_check_selected.png"),
    --               = topRight hang
    HANG_BG_IMG      = _res("ui/anniversary20/hang/ship_order_bg_order_prize.png"),
    HANG_GOOD_BG     = _res("ui/anniversary20/hang/common_bg_goods.png"),
    GOOD_ICON_BG     = _res("ui/anniversary20/hang/common_frame_goods_1.png"),
    GOOD_ICON_ADD    = _res("ui/anniversary20/hang/wonderland_ball_btn_plus.png"),
    DONATE_BG        = _res("ui/anniversary20/hang/common_bg_tips.png"),
    ARROW_BG         = _res("ui/anniversary20/hang/common_bg_tips_horn.png"),
    SCHEDULER_BG     = _res("ui/anniversary20/hang/wonderland_main_label_countdown.png"),
    --               = animations
    OPEN_VIEW_ANIM   = _spn("ui/anniversary20/hang/effects/wonderland_opening_boom"),
    CART_GO_ANIM     = _spn("ui/anniversary20/hang/effects/wonderland_main_cart_go"),
    CART_BACK_ANIM   = _spn("ui/anniversary20/hang/effects/wonderland_main_cart_back"),
    CART_REDUCE_ANIM = _spn("ui/anniversary20/hang/effects/wonderland_main_cart_reduce"),
    REWARD_BOX_ANIM  = _spn("ui/anniversary20/hang/effects/box_11"),
}


Anniversary20HangView.HANG_STATUE = {
    NONE           = 0,
    HANGING        = 1,
    HANG_REWARD    = 2,
    HANG_START     = 3,
    HANG_END       = 4,
}

local getCakeImagePath = function(formulaId)
    return _res(string.fmt("ui/anniversary20/hang/wonderland_ball_ico_cake_%1.png", formulaId))
end


function Anniversary20HangView:ctor(args)
    -- create view
    self.viewData_ = Anniversary20HangView.CreateView()
    self:addChild(self:getViewData().view)
end


function Anniversary20HangView:getViewData()
    return self.viewData_
end


function Anniversary20HangView:showUI(isShowAnim, endCB)
    local callback = function()
        local viewData = self:getViewData()
        viewData.topLayer:setPosition(viewData.topLayerHidePos)
        viewData.topLayer:setVisible(true)
        viewData.titleBtn:setPosition(viewData.titleBtnHidePos)
        viewData.titleBtn:runAction(cc.EaseBounceOut:create(cc.MoveTo:create(1, viewData.titleBtnShowPos)))
        
        local actTime = 0.2
        self:runAction(cc.Sequence:create({
            cc.TargetedAction:create(viewData.topLayer, cc.MoveTo:create(actTime, viewData.topLayerShowPos)),
            cc.CallFunc:create(function()
                if endCB then endCB() end
            end)
        }))
    end

    if isShowAnim then
        self:getViewData().topLayer:setVisible(false)
        local spine = ui.spine({path = RES_DICT.OPEN_VIEW_ANIM, init = "play1", loop = false})
        self:addList(spine):alignTo(nil, ui.cc)

        spine:registerSpineEventHandler(function()
            spine:runAction(cc.RemoveSelf:create())
            callback()
        end, sp.EventType.ANIMATION_COMPLETE)
    else
        callback()
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function Anniversary20HangView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- bgImg / block layer
    local backGroundGroup = view:addList({
        ui.image({img = RES_DICT.BG_IMAGE, p = cpos}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })

    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- back button
    local backBtn = ui.button({n = RES_DICT.BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 30, offsetY = -15})

    -- title button
    local titleBtn = ui.button({n = RES_DICT.COM_TITLE_BAR}):updateLabel({fnt = FONT.D1, text = __('马车之旅'), offset = cc.p(0,-10)})
    topLayer:addList(titleBtn):alignTo(backBtn, ui.rc, {offsetX = 2, offsetY = 10})

    titleBtn:addList(ui.image({img = RES_DICT.COM_TIPS_ICON})):alignTo(nil, ui.rc, {offsetX = -15, offsetY = -10})

    -- moneyBar
    local moneyBar = require('common.CommonMoneyBar').new({})
    moneyBar:reloadMoneyBar({ app.anniv2020Mgr:getShopCurrencyId() }, false, {
        [app.anniv2020Mgr:getShopCurrencyId()] = {hidePlus = true, disable = true}
    })
    topLayer:add(moneyBar)

    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- [imgTable| plateLayer]
    local PLATE_LAYER_SIZE = cc.size(1300, 340)
    local tableGroup = centerLayer:addList({
        ui.image({img = RES_DICT.IMAGE_TABLE, mt = 130}),
        ui.layer({size = PLATE_LAYER_SIZE, mt = -40})
    })
    ui.flowLayout(cc.rep(display.center, 0, -60), tableGroup, {type = ui.flowC, ap = ui.cc})
    
    -- plates
    local plateCells = {}
    local PLATE_ROW_NUM = 2
    local PLATE_COL_NUM = 4
    local plateMapCell = {} -- only for sorting
    local PLATE_CELL_HEIGHT = PLATE_LAYER_SIZE.height / PLATE_ROW_NUM
    local tableLayer = tableGroup[2]
    for plateIndex = 1, CONF.ANNIV2020.HANG_FORMULA:GetLength() do
        local plateCell = Anniversary20HangView.CreatePlateCell(PLATE_CELL_HEIGHT)
        plateCell:setTag(plateIndex)
        tableLayer:add(plateCell)
        table.insert(plateCells, plateCell)

        local colIndex = (plateIndex - 1) % PLATE_ROW_NUM + 1
        if not plateMapCell[colIndex] then
            plateMapCell[colIndex] = {}
        end
        table.insert(plateMapCell[colIndex], plateCell)
    end
    
    for colIndex, plateCells in ipairs(plateMapCell) do
        ui.flowLayout(cc.rep(cc.sizep(tableLayer, ui.ct), 0, -colIndex * PLATE_CELL_HEIGHT), plateCells, {type = ui.flowH, ap = ui.cb, gapW = 20 + colIndex * 50})
        for _, plateCell in ipairs(plateCells) do
            plateCell:setScale(0.9 + (colIndex-1) * 0.1)
        end
    end

    --------------------------------------------------- [below] rewardLayer
    local belowLayer = ui.layer()
    view:addChild(belowLayer)

    -- [imgBg| imgReward| progressNum]
    local clolectText   = string.fmt(__("收集奖励: _current_/_total_"), {_current_ = 0 , _total_ = 0})
    local clolectLabel  = ui.title({n = RES_DICT.ICON_BG_IMG, scale9 = true, mr = 40, mb = 14}):updateLabel({fnt = FONT.D18, text = clolectText, paddingW = 10})
    local clolectLabelW = clolectLabel:getBoundingBox().width
    local collectRewardGroup = belowLayer:addList({
        ui.image({img = RES_DICT.BELOW_BG_IMG, scale9 = true, size = cc.size(display.width, 113) }),
        ui.button({n = RES_DICT.REWARD_IMG, mr = -10 + clolectLabelW/2, mb = 40}),
        clolectLabel,
        ui.layer({size = cc.size(470, 130), mr = 80 + clolectLabelW, mb = 10}),
    })
    ui.flowLayout(cc.sizep(belowLayer, ui.rb), collectRewardGroup, {type = ui.flowC, ap = ui.rb})

    --[rewardSubBg|progressBar]]
    local collectRewardSubLayer = collectRewardGroup[4]
    local collectRewardSubGroup = collectRewardSubLayer:addList({
        ui.image({img = RES_DICT.REWAR_BG_IMG, }),
        ui.pBar({img = RES_DICT.PRO_ACTIVE, bg = RES_DICT.PRO_GREY, value = 0, w = 300, h = 25, mb = 10}),
    })
    ui.flowLayout(cc.sizep(collectRewardSubLayer, ui.cc), collectRewardSubGroup, {type = ui.flowC, ap = ui.cc})

    -- createCollectReward
    local collectRewardSubCells = {}
    local collectRewardSubProgress = collectRewardSubGroup[2]
    for rewardIndex, collectRewardConf in ipairs(CONF.ANNIV2020.HANG_REWARDS:GetValue(1).collects) do
        local goodNode = Anniversary20HangView.CreateCollectRewardCell(collectRewardConf)
        goodNode:setTag(rewardIndex)

        collectRewardSubLayer:add(goodNode)
        table.insert(collectRewardSubCells, goodNode)
    end
    ui.flowLayout(cc.p(collectRewardSubProgress:getPosition()), collectRewardSubCells, {type = ui.flowH, ap = ui.cc, gapW = 70})


    ------------------------------------------------------[rightTop] 
    -------------------------------------- hangMaterialsLayer
    local hangMaterialsLayer = ui.layer()
    view:add(hangMaterialsLayer)
    hangMaterialsLayer:setVisible(false)

    ---- [blockLayer| hangBg| hangGoodBg| btnConfirm]
    local hangMaterialsGroup = hangMaterialsLayer:addList({
        ui.layer({color = cc.r4b(0), enable = true, mr = -display.SAFE_L}),
        ui.image({img = RES_DICT.HANG_BG_IMG, mt = 60}),
        ui.image({img = RES_DICT.HANG_GOOD_BG, mt = 75, mr = 225}),
        ui.button({n = RES_DICT.BTN_CONFIRM, mt = 110, mr = 50}):updateLabel({text = __("挂机"), fnt = FONT.D14, fontSize = 24})
    })
    hangMaterialsGroup[1]:setVisible(false)
    ui.flowLayout(cc.rep(cc.sizep(hangMaterialsLayer, ui.rt), -display.SAFE_L, 0), hangMaterialsGroup, {type = ui.flowC, ap = ui.rt})

    -- hangSelectedMaterials
    local arrText = {__('茶会'), __("街道"), __('城堡')}
    local hangMaterialsGoodCells = {}
    for posIndex = 1, 3 do
        local selectedGoodCell = Anniversary20HangView.CreateMaterialCell(arrText[posIndex])
        selectedGoodCell:setTag(posIndex)
        hangMaterialsLayer:addList(selectedGoodCell)

        table.insert(hangMaterialsGoodCells, selectedGoodCell)
    end
    ui.flowLayout(cc.rep(cc.p(hangMaterialsGroup[3]:getPosition()), 0, -15), hangMaterialsGoodCells, {type = ui.flowH, ap = ui.cc, gapW = 20})

    ----------------------------------- hangMaterialsSubLayer
    local hangMaterialsSubLayer = ui.layer({size = cc.size(333, 111), ap = ui.ct})
    hangMaterialsLayer:addList(hangMaterialsSubLayer):alignTo(imgHangBg, ui.cb, {offsetY = -5})
    hangMaterialsSubLayer:setVisible(false)
    
    -- [bg| arrow]
    local hangDonateBg = hangMaterialsSubLayer:addList({
        ui.image({img = RES_DICT.DONATE_BG}),
        ui.image({img = RES_DICT.ARROW_BG, mt = -54, mr = 115}),
    })
    ui.flowLayout(cc.sizep(hangMaterialsSubLayer, ui.cc), hangDonateBg, {type = ui.flowC, ap = ui.cc})

    local hangMaterialsSubGoodCells = {}
    for posIndex = 1, 3 do
        local goodNode = ui.goodsNode({scale = 0.8})
        goodNode:setTouchEnabled(true)
        hangMaterialsSubLayer:addList(goodNode)
        table.insert(hangMaterialsSubGoodCells, goodNode)
    end
    ui.flowLayout(cc.sizep(hangMaterialsSubLayer, ui.cc), hangMaterialsSubGoodCells, {type = ui.flowH, ap = ui.cc, gapW = 10})

    --------------------------------------- hangingLayer
    local hangingLayer = ui.layer()
    view:add(hangingLayer)
    hangingLayer:setVisible(false)

    --[imgBg | timeTxt | spine]
    local scheduleGroup = hangingLayer:addList({
        ui.title({n = RES_DICT.SCHEDULER_BG, mr = 220, mt = 125, scale9 = true, cut = cc.dir(5, 5, 5, 5)}):updateLabel({text = string.fmt(__("倒计时:_time_"), {_time_ = "01:00:00"}), paddingW = 50, fontSize = 24, offset = cc.p(-30, 0)}),
        ui.spine({path = RES_DICT.CART_REDUCE_ANIM, init = "idle", cache = SpineCacheName.ANNIVERSARY_2020, mt = 350, mr = 610}),
    })
    ui.flowLayout(cc.sizep(hangingLayer, ui.rt), scheduleGroup, {ap = ui.rc, type = ui.flowC})

    --------------------------------------- hangingGetRewardLayer
    local hangRewardLayer = ui.layer({size = cc.size(108, 100), p = cc.rep(display.right_top, - 200, - 170), enable = true, color = cc.r4b(0)})
    view:add(hangRewardLayer)
    hangRewardLayer:setVisible(false)

    -- [spine| title]
    local hangRewardGroup = hangRewardLayer:addList({
        ui.spine({path = RES_DICT.REWARD_BOX_ANIM, init = "idle", cache = SpineCacheName.ANNIVERSARY_2020, mt = 60, ml = 5}),
        ui.title({n = RES_DICT.ICON_BG_IMG, scale9 = true, size = cc.size(90, 25), cut = cc.dir(5, 5, 5, 5), mt = 30}):updateLabel({text = __("点击领取"), fontSize = 22, paddingW = 20})
    })
    ui.flowLayout(cc.sizep(hangRewardLayer, ui.cc), hangRewardGroup, {type = ui.flowV, ap = ui.cc})

    return {
        view                       = view,
        --                         = top
        topLayer                   = topLayer,
        topLayerHidePos            = cc.p(topLayer:getPositionX(), 100),
        topLayerShowPos            = cc.p(topLayer:getPosition()),
        titleBtn                   = titleBtn,
        titleBtnHidePos            = cc.p(titleBtn:getPositionX(), titleBtn:getPositionY() + 190),
        titleBtnShowPos            = cc.p(titleBtn:getPosition()),
        backBtn                    = backBtn,
        --                         = center
        plateCells                 = plateCells,
        --                         = collectLayer
        collectRewardBtn           = collectRewardGroup[2],
        collectRewardProgress      = collectRewardGroup[3],
        collectRewardSubLayer      = collectRewardSubLayer,
        collectRewardSubProgress   = collectRewardSubProgress,
        collectRewardSubCells      = collectRewardSubCells,
        --                         = hangMaterialLayer
        hangConfirmBtn             = hangMaterialsGroup[4],
        hangMaterialsLayer         = hangMaterialsLayer,
        hangMaterialsGoodCells     = hangMaterialsGoodCells,
        --                         = hangMaterialsSubInterfaceLayer
        hangMaterialsSubLayer      = hangMaterialsSubLayer,
        hangMaterialsSubBg         = hangMaterialsGroup[2],
        hangMaterialsSubBlockLayer = hangMaterialsGroup[1],
        hangMaterialsSubGoodCells  = hangMaterialsSubGoodCells,
        --                         = hangingLayer
        hangingLayer               = hangingLayer,
        hangingLeftSecondsText     = scheduleGroup[1],
        --                         = hangRewardLayer
        hangRewardLayer            = hangRewardLayer,
    }
end

------------------------------------------------- createCell
function Anniversary20HangView.CreatePlateCell(cellHeight)
    local plateImg = ui.image({img = RES_DICT.IMAGE_PLATE})

    local layer = ui.layer({size = cc.size(plateImg:getContentSize().width, cellHeight), color = cc.r4b(0), enable = true, ap = ui.cb})
    layer:addList(plateImg):alignTo(nil, ui.cb)

    layer.plate = plateImg
    return layer
end


function Anniversary20HangView.CreateCollectRewardCell(rewardData)
    local confReward = rewardData.rewards[1]
    local goodparams = {goodsId = confReward.goodsId, num = confReward.num, showAmount = true, type = confReward.type, highlight = rewardData.highlight, scale = 0.8}
    local goodNode = ui.goodsNode(goodparams)
    goodNode:setTouchEnabled(true)

    local titleProgress = ui.title({n = RES_DICT.ICON_BG_IMG, size = cc.size(70, 25), scale9 = true, cut = cc.dir(5, 5, 5, 5)}):updateLabel({fontSize = 22})
    goodNode:addList(titleProgress):alignTo(nil, ui.cb, {offsetX = 10, offsetY = -30})

    goodNode.progressNum = titleProgress:getLabel()
    return goodNode
end


function Anniversary20HangView.CreateMaterialCell(titleStr)
    local imgBg = ui.image({img = RES_DICT.GOOD_ICON_BG})
    local layer = ui.layer({size = imgBg:getContentSize(), color = cc.r4b(0), enable = true})

    -- bg, addImg, title
    local hangSelectedCellGroup = layer:addList({
        imgBg,
        ui.image({img = RES_DICT.GOOD_ICON_ADD, ap = ui.cc}),
        ui.label({text = titleStr, fontSize = 22, color = "#473227", mt = -60})
    })
    ui.flowLayout(cc.sizep(layer, ui.cc), hangSelectedCellGroup, {type = ui.flowC, ap = ui.cc})
    return layer
end


---------------------------------------------------- refreshHanging
function Anniversary20HangView:updateHangState(state, endCb)
    self:getViewData().hangingLayer:setVisible(state == Anniversary20HangView.HANG_STATUE.HANGING)
    self:getViewData().hangRewardLayer:setVisible(state == Anniversary20HangView.HANG_STATUE.HANG_REWARD)
    self:getViewData().hangMaterialsLayer:setVisible(state == Anniversary20HangView.HANG_STATUE.NONE)

    if state == Anniversary20HangView.HANG_STATUE.HANG_START then
        self:showHangActionSpine_(RES_DICT.CART_GO_ANIM, endCb, "in")

    elseif state == Anniversary20HangView.HANG_STATUE.HANG_END then
        self:showHangActionSpine_(RES_DICT.CART_BACK_ANIM, endCb, "back")
    end
end


function Anniversary20HangView:setHangMaterialsSubLayerTypeAndShow(materialType)
    local materialsConfig = app.anniv2020Mgr:getMaterialsConfigByType(materialType)
    if next(materialsConfig) == nil then
        return
    end

    -- sort material by num
    table.sort(materialsConfig, function(infoA, infoB)
        -- local goodNumA = app.goodsMgr:getGoodsNum(infoA.goodsId)
        -- local goodNumB = app.goodsMgr:getGoodsNum(infoB.goodsId)
        -- return goodNumA > goodNumB
        return checkint(infoA.goodsId) < checkint(infoB.goodsId)
    end)

    -- setInfo
    for posIndex, goodConf in ipairs(materialsConfig) do
        local goodNode = self:getViewData().hangMaterialsSubGoodCells[posIndex]
        if goodNode then
            local goodNum = app.goodsMgr:getGoodsNum(goodConf.goodsId)
            goodNode:RefreshSelf({goodsId = goodConf.goodsId, num = goodNum, showAmount = true})
        end
    end
    self:updateHangMaterialsSubLayerVisible(true)
    self:getViewData().hangMaterialsSubLayer:alignTo(self:getViewData().hangMaterialsGoodCells[materialType], ui.cb, {offsetX = 115, offsetY = -20})
end


function Anniversary20HangView:updateHangMaterialsSubLayerVisible(visible)
    self:getViewData().hangMaterialsSubLayer:setVisible(visible)
    self:getViewData().hangMaterialsSubBlockLayer:setVisible(visible)
end


function Anniversary20HangView:updateSelectedMaterial(materialType, goodId)
    local goodSelectedCell = self:getViewData().hangMaterialsGoodCells[materialType]
    if not goodSelectedCell then
        return
    end

    if not goodSelectedCell.goodNode then
        goodSelectedCell.goodNode = ui.goodsNode({scale = 0.8})
        goodSelectedCell:addList(goodSelectedCell.goodNode):alignTo(nil, ui.cc)
    end
    goodSelectedCell.goodNode:RefreshSelf({goodsId = goodId})
    goodSelectedCell.goodNode:setVisible(checkint(goodId) > 0)
end

function Anniversary20HangView:updateSelectedMaterials(mapSelectedMaterials)
    mapSelectedMaterials = mapSelectedMaterials or {}
    for typeIndex = 1, 3 do
        self:updateSelectedMaterial(typeIndex, mapSelectedMaterials[typeIndex])
    end
end


function Anniversary20HangView:refershHangingLeftTime(time)
    local timeText = CommonUtils.getTimeFormatByType(checkint(time))
    self:getViewData().hangingLeftSecondsText:setText(string.fmt(__("倒计时:_time_"), {_time_ = timeText}))
end


------------------------------------------------------------- refresh plate
function Anniversary20HangView:updatePlateCells()
    for formulaId, plateCell in ipairs(self:getViewData().plateCells) do
        self:updatePlateCell(formulaId, plateCell)
    end
end
function Anniversary20HangView:updatePlateCell(formulaId, plateCell)
    plateCell = plateCell or self:getViewData().plateCells[formulaId]
    if not plateCell then
        return
    end
    if plateCell.img then
        plateCell.img:removeFromParent()
    end

    local isFormulaUnlock = app.anniv2020Mgr:hasHangUnlockFormulaId(formulaId)
    plateCell.img = ui.image({img = isFormulaUnlock and RES_DICT.IMAGE_PLATE_BG or RES_DICT.IMAGE_WHY})

    -- add cake
    if isFormulaUnlock then
        plateCell.img:addList(ui.image({img = getCakeImagePath(formulaId), scale = 0.9})):alignTo(nil, ui.cc, {offsetY = 20})
    end
    
    plateCell.plate:addList(plateCell.img):alignTo(nil, ui.cc, {offsetY = isFormulaUnlock and 0 or 50})
end

------------------------------------------------------------ refreshCollect
function Anniversary20HangView:updateCollectRewards()
    for collectId, _ in ipairs(self:getViewData().collectRewardSubCells) do
        self:updateCollectReward(checkint(collectId))
    end
end
function Anniversary20HangView:updateCollectReward(collectId)
    local goodNode = self:getViewData().collectRewardSubCells[checkint(collectId)]
    if not goodNode then
        return
    end

    local hasDrawReward = app.anniv2020Mgr:hasHangDrawnCollectId(checkint(collectId))
    if goodNode.hasDrawLayer then
        goodNode.hasDrawLayer:setVisible(hasDrawReward)

    elseif hasDrawReward then
        local hasDrawLayerGroup = goodNode:addList({
            ui.layer({size = cc.size(100, 100), color = cc.c4b(0, 0, 0, 150)}),
            ui.image({img = RES_DICT.CHECK_IMG})
        }, 9)
        ui.flowLayout(cc.rep(cc.sizep(goodNode, ui.cc), 11, 11), hasDrawLayerGroup, {type = ui.flowC, ap = ui.cc})
        goodNode.hasDrawLayer = hasDrawLayerGroup[1]
    end
end
function Anniversary20HangView:updateCollectProgress()
    for collectId, _ in ipairs(self:getViewData().collectRewardSubCells) do
        self:updateCollectRewardProgress(collectId)
    end

    local rewardConfs = CONF.ANNIV2020.HANG_REWARDS:GetValue(1)
    local maxCollectNum = checkint(rewardConfs.collects[#rewardConfs.collects].targetNum)
    local curCollectNum = app.anniv2020Mgr:getHangUnlockFormulaIdNum()
    self:getViewData().collectRewardSubProgress:setValue(math.floor(curCollectNum / maxCollectNum * 100))

    --self:getViewData().collectRewardProgress:updateLabel({fnt = FONT.D18, text = string.fmt(__("收集奖励: _current_/_total_"), {_current_ = curCollectNum , _total_ = maxCollectNum}), paddingW = 10})
    self:getViewData().collectRewardProgress:setText(string.fmt(__("收集奖励: _current_/_total_"), {_current_ = curCollectNum , _total_ = maxCollectNum}))
end
function Anniversary20HangView:updateCollectRewardProgress(collectId)
    local goodNode = self:getViewData().collectRewardSubCells[checkint(collectId)]
    if not goodNode or not goodNode.progressNum then
        return
    end
    local rewardConfs = CONF.ANNIV2020.HANG_REWARDS:GetValue(1)
    local curRewardConf = checktable(rewardConfs.collects[checkint(collectId)])

    local cakeCollectNum = app.anniv2020Mgr:getHangUnlockFormulaIdNum()
    goodNode.progressNum:setString(math.min(checkint(curRewardConf.targetNum), cakeCollectNum) .. " / " .. checkint(curRewardConf.targetNum))
end


function Anniversary20HangView:updateCollectRewardLayerStatue()
    local visible = self:getViewData().collectRewardSubLayer:isVisible()
    self:getViewData().collectRewardSubLayer:setVisible(not visible)
end

--------------------------------------------------------- addSpine
function Anniversary20HangView:showHangActionSpine_(path, endCb, initName)
    if not self:getViewData().spineLayer then
        self:getViewData().spineLayer = ui.layer({color = cc.c4b(0, 0, 0, 150), enable = true})
        self:getViewData().view:addChild(self:getViewData().spineLayer)
    else
        self:getViewData().spineLayer:setVisible(true)
    end

    local spine = ui.spine({path = path, init = initName, loop = false, cache = SpineCacheName.ANNIVERSARY_2020})
    self:getViewData().spineLayer:addList(spine):alignTo(nil, ui.cc)

    spine:registerSpineEventHandler(function()
        self:getViewData().spineLayer:setVisible(false)
        spine:runAction(cc.RemoveSelf:create())
        if endCb then
            endCb()
        end
    end, sp.EventType.ANIMATION_COMPLETE)
end


return Anniversary20HangView
