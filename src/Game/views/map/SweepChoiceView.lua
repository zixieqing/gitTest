local SweepChoiceView = class('SweepChoiceView', function()
    return ui.layer({name = 'Game.views.map.SweepChoiceView', enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME  = _res('ui/common/common_bg_8.png'),
    BTN_CONFIRM = _res('ui/common/common_btn_orange.png'),
    BTN_NUM     = _res('ui/home/market/market_buy_bg_info.png'),
    BTN_DEL     = _res('ui/home/market/market_sold_btn_sub.png'),
    BTN_ADD     = _res('ui/home/market/market_sold_btn_plus.png'),
    BTN_DISABLE = _res('ui/common/common_btn_orange_disable.png'),
    BTN_MAX     = _res('ui/common/pet_clean_btn_number_small.png'),
    BTN_MIN     = _res('ui/common/pet_clean_btn_number_big.png'),
}


function SweepChoiceView:ctor(args)
    -- create view
    self.viewData_ = SweepChoiceView.CreateView()
    self:addChild(self.viewData_.view)
end


function SweepChoiceView:getViewData()
    return self.viewData_
end

function SweepChoiceView:updateNumHandler(num, stageId)
    -- update num btn
    self:getViewData().numBtn:setText(num)

    -- update cost
    local stageConf  = CommonUtils.GetQuestConf(stageId)
    if not stageConf then
        return
    end
    local consumeNum = checkint(stageConf.consumeHp) * num
    display.reloadRichLabel(self:getViewData().costLabel, {c = {
        {text = __('消耗'), fontSize = 24, color = "#76553b"},
        {text = consumeNum, fontSize = 24, color = app.goodsMgr:GetGoodsAmountByGoodsId(HP_ID) >= consumeNum and "#76553b" or "#DC143C"},
        {img = CommonUtils.GetGoodsIconPathById(HP_ID), scale = 0.2},
    }})
end


function SweepChoiceView:updateLimitNum(limitNum)
    self:getViewData().limitLabel:setString(string.fmt(__("单次上限:_num_"), {_num_ = limitNum}))
end

-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function SweepChoiceView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.r4b(0), enable = true}),
        ui.layer(),
    })

    local backGroundLayer = backGroundGroup[2]
    local bgImg       = ui.image({img = RES_DICT.VIEW_FRAME})
    local bgSize      = bgImg:getContentSize()
    local frameGroup  = backGroundLayer:addList({
        ui.layer({color = cc.r4b(0), enable = true, size = bgSize}),
        bgImg,
        ui.layer({size = bgSize}),
    })
    ui.flowLayout(cc.sizep(backGroundLayer, ui.cc), frameGroup, {type = ui.flowC, ap = ui.cc})
    ------------------------------------------------- [center]
    local centerLayer = frameGroup[3]
    local sweepInfoGroup = centerLayer:addList({
        ui.label({fnt = FONT.D4, text = __("扫荡次数")}),
        ui.layer({size = cc.size(bgSize.width - 50, 70)}),
        ui.label({fnt = FONT.D9, color = "#c7ad9e", text = "--"}),
        ui.rLabel({r = true, c = {{text = string.format(__('消耗%s'), "--"), fontSize = 24, color = "#76553b"}}}),
        ui.button({n = RES_DICT.BTN_CONFIRM, d = RES_DICT.BTN_DISABLE}):updateLabel({fnt = FONT.D14, text = __("扫荡")})
    })
    ui.flowLayout(cc.sizep(centerLayer, ui.cc), sweepInfoGroup, {type = ui.flowV, ap = ui.cc, gapH = 10})


    local sweepNumLayer = sweepInfoGroup[2]
    local sweepNumGroup = sweepNumLayer:addList({
        ui.button({n = RES_DICT.BTN_MIN}):updateLabel({fnt = FONT.D9, color = "#c7ad9e", text = __("最小"), offset = cc.p(0, -35)}),
        ui.button({n = RES_DICT.BTN_DEL, zorder = 2}),
        ui.button({n = RES_DICT.BTN_NUM, zorder = 1, ml = -3, size = cc.size(90, 40), scale9 = true}):updateLabel({fnt = FONT.D14, text = "--"}),
        ui.button({n = RES_DICT.BTN_ADD, zorder = 2, ml = -3}),
        ui.button({n = RES_DICT.BTN_MAX}):updateLabel({fnt = FONT.D9, color = "#c7ad9e", text = __("最大"), offset = cc.p(0, -35)}),
    })
    ui.flowLayout(cc.sizep(sweepNumLayer, ui.cc), sweepNumGroup, {type = ui.flowH, ap = ui.cc})


    return {
        view       = view,
        blockLayer = backGroundGroup[1],
        --         = center
        limitLabel = sweepInfoGroup[3],
        costLabel  = sweepInfoGroup[4],
        sweepBtn   = sweepInfoGroup[5],
        minBtn     = sweepNumGroup[1],
        delBtn     = sweepNumGroup[2],
        numBtn     = sweepNumGroup[3],
        addBtn     = sweepNumGroup[4],
        maxBtn     = sweepNumGroup[5],
    }
end


return SweepChoiceView
