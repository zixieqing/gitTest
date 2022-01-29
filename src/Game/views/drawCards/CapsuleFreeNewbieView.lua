-------------------------------------------------------------------------------
-- 新抽卡 - 免费新手抽卡 视图
-- 
-- Author: kaishiqi <zhangkai@funtoygame.com>
-- 
-- Create: 2021-09-22 17:44:56
-------------------------------------------------------------------------------

---@class CapsuleFreeNewbieView : CLayout
local CapsuleFreeNewbieView = class('CapsuleFreeNewbieView', function()
    return ui.layer({name = 'CapsuleFreeNewbieView', enableEvent = true})
end)

local RES_DICT = {
    ORANGE_BTN_N      = _res('ui/common/common_btn_big_orange_2.png'),
    ORANGE_BTN_D      = _res('ui/common/common_btn_big_orange_disabled_2.png'),
    BOTTOM_BAR        = _res('ui/home/capsuleNew/common/summon_activity_bg_.png'),
    COUNT_BAR         = _res('ui/home/capsuleNew/skinCapsule/summon_newhand_bg_count.png'),
    DRAW_FINAL_BTN    = _res('ui/home/capsuleNew/freeNewbie/newpool_btn_box.png'),
    DRAW_COUNT_BTN    = _res('ui/home/capsuleNew/freeNewbie/newpool_btn_reward.png'),
    REWARDS_LIGHT_IMG = _res('ui/home/capsuleNew/freeNewbie/newpool_bg_box_light.png'),
    FINAL_TITLE       = _res('ui/common/common_words_congratulations.png'),
    FINAL_LIGHT       = _res('ui/home/capsuleNew/freeNewbie/newpool_bg_card_light.png'),
    FINAL_FRAME       = _res('ui/home/capsuleNew/freeNewbie/newpool_bg_card.png'),
    FINAL_SELECT      = _res('ui/common/common_bg_frame_goods_elected.png'),
    COUNT_PBAR_IMG    = _res('ui/home/capsuleNew/freeNewbie/newpool_line_top.png'),
    COUNT_PBAR_BG     = _res('ui/home/capsuleNew/freeNewbie/newpool_line_under.png'),
    COUNT_BG_FRAME    = _res('ui/common/common_bg_9.png'),
    COUNT_COM_TITLE   = _res('ui/common/common_bg_title_2.png'),
    COUNT_CELL_BG_D   = _res('ui/championship/rank/common_bg_list_unlock.png'),
    COUNT_CELL_BG_N   = _res('ui/championship/rank/common_bg_list.png'),
    DRAW_BTN_N        = _res('ui/common/common_btn_orange.png'),
    DRAW_BTN_D        = _res('ui/common/common_btn_orange_disable.png'),
    DRAW_DISABLE      = _res('ui/common/activity_mifan_by_ico.png'),
}


function CapsuleFreeNewbieView:ctor(size)
    self:setContentSize(size)

    self.viewData_ = CapsuleFreeNewbieView.CreateView(size)
    self:addChild(self:getViewData().view)
end


---@return CapsuleFreeNewbieView.ViewData
function CapsuleFreeNewbieView:getViewData()
    return self.viewData_
end


-- update once/much consumeRLabel
function CapsuleFreeNewbieView:updateConsumeRLabel(isOnce, goodsId, goodsNum)
    local consumeRLabel = isOnce and self:getViewData().onceConsumeRLable or self:getViewData().muchConsumeRLable
    consumeRLabel:reload({
        {fnt = FONT.D7, fontSize = 26, text = __('消耗')},
        {fnt = FONT.D7, fontSize = 26, text = string.fmt(' %1 ', checkint(goodsNum))},
        {img = GoodsUtils.GetIconPathById(goodsId), scale = 0.2},
    })
end


-- update once/much drawButton
function CapsuleFreeNewbieView:updateDrawButtonEnabled(isOnce, isEnabled)
    local drawButton = isOnce and self:getViewData().drawOnceBtn or self:getViewData().drawMuchBtn
    drawButton:setEnabled(isEnabled == true)
end


-- update leftTimes
function CapsuleFreeNewbieView:updateLeftTimesLabel(leftTimes)
    self:getViewData().leftTimesLabel:updateLabel({text = string.fmt(__('剩余抽取次数：_num_'), {_num_ = checkint(leftTimes)})})
end


-- update finalLigt
function CapsuleFreeNewbieView:updateFinalRewardsLight(isShowLight)
    self:getViewData().finalLightImg:setVisible(isShowLight == true)
end


-- update finalEnable
function CapsuleFreeNewbieView:updateFinalRewardsEnable(isEnabled)
    self:getViewData().finalRewardsBtn:setEnabled(isEnabled == true)
end


-------------------------------------------------
-- update finalRewards

---@param cellViewData CapsuleFreeNewbieView.FinalRewardsCellViewData
function CapsuleFreeNewbieView:updateFinalRewardsCellSelected(cellViewData, isSelected)
    cellViewData.selectedLayer:setVisible(isSelected == true)
end


-------------------------------------------------
-- update countRewards

---@param cellViewData CapsuleFreeNewbieView.CountRewardsCellViewData
function CapsuleFreeNewbieView:updateCountRewardsCellDescr(cellViewData, targetNum)
    local textList = string.split2(string.fmt(__('卡池抽取|_num_|次'), {_num_ = checkint(targetNum)}), '|')
    cellViewData.descrRLabel:reload({
        {fnt = FONT.D6, text = tostring(textList[1])},
        {fnt = FONT.D6, text = tostring(textList[2]), color = '#FF3333'},
        {fnt = FONT.D6, text = tostring(textList[3])},
    })
end


---@param cellViewData CapsuleFreeNewbieView.CountRewardsCellViewData
function CapsuleFreeNewbieView:updateCountRewardsCellGoods(cellViewData, goodsList)
    local goodsDataList = checktable(goodsList)
    for goodsIndex, goodsNode in ipairs(cellViewData.goodsNodeList) do
        local goodsData = goodsDataList[goodsIndex]
        if goodsData then
            goodsNode:setVisible(true)
            goodsNode:RefreshSelf(goodsData)
        else
            goodsNode:setVisible(false)
        end
    end
end


---@param cellViewData CapsuleFreeNewbieView.CountRewardsCellViewData
function CapsuleFreeNewbieView:updateCountRewardsCellState(cellViewData, hasDrawn)
    local isDrawable = hasDrawn ~= true
    cellViewData.bgFrameN:setVisible(isDrawable)
    cellViewData.bgFrameD:setVisible(not isDrawable)
    cellViewData.drawableLayer:setVisible(isDrawable)
    cellViewData.hasDrawnLayer:setVisible(not isDrawable)
end


---@param cellViewData CapsuleFreeNewbieView.CountRewardsCellViewData
function CapsuleFreeNewbieView:updateCountRewardsCellProgress(cellViewData, progressNum, progressMax)
    local maxValue = checkint(progressMax)
    local nowValue = checkint(progressNum)
    cellViewData.targetNumPBar:setMaxValue(maxValue)
    cellViewData.targetNumPBar:setNowValue(nowValue)
    cellViewData.targetNumLabel:updateLabel({text = string.fmt('%1 / %2', nowValue, maxValue)})
    cellViewData.drawRewardsBtn:setEnabled(nowValue >= maxValue)
end


-------------------------------------------------------------------------------
-- view defines
-------------------------------------------------------------------------------

function CapsuleFreeNewbieView.CreateView(size)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)

    view:add(ui.image({img = RES_DICT.BOTTOM_BAR, p = cc.p(cpos.x, 0), ap = ui.cb}))

    -- [ countBar | leftTimesLabel ]
    local countGroup = view:addList({
        ui.image({img = RES_DICT.COUNT_BAR}),
        ui.label({fnt = FONT.D9, color = '#d9c198', mt = 2}),
    })
    ui.flowLayout(cc.p(cpos.x, 20), countGroup, {type = ui.flowC, ap = ui.cc})

    -------------------------------------------------
    -- once info
    local drawOncePos = cc.p(size.width/2 - 200, 120)
    local drawOnceBtn = ui.button({p = drawOncePos, n = RES_DICT.ORANGE_BTN_N, d = RES_DICT.ORANGE_BTN_D})
    drawOnceBtn:updateLabel({fnt = FONT.D14, fontSize = 26, hAlign = display.TAC, text = string.fmt(__('召唤\n_num_次'), {_num_ = 1})})
    drawOnceBtn:setEnabled(false)
    view:addChild(drawOnceBtn)
    
    local onceConsumeRLable = ui.rLabel({p = cc.rep(drawOncePos, 0, -60)})
    view:addChild(onceConsumeRLable)

    -------------------------------------------------
    -- much info
    local drawMuchPos = cc.p(size.width/2 + 200, drawOncePos.y)
    local drawMuchBtn = ui.button({p = drawMuchPos, n = RES_DICT.ORANGE_BTN_N, d = RES_DICT.ORANGE_BTN_D})
    drawMuchBtn:updateLabel({fnt = FONT.D14, fontSize = 26, hAlign = display.TAC, text = string.fmt(__('召唤\n_num_次'), {_num_ = 10})})
    drawMuchBtn:setEnabled(false)
    view:addChild(drawMuchBtn)
    
    local muchConsumeRLable = ui.rLabel({p = cc.p(drawMuchPos.x, onceConsumeRLable:getPositionY())})
    view:addChild(muchConsumeRLable)

    -------------------------------------------------
    -- other fun

    local finalRewardsBtn = ui.button({p = cc.p(size.width - 100, cpos.y + 160), n = RES_DICT.DRAW_FINAL_BTN})
    local finalLightImg   = ui.image({img = RES_DICT.REWARDS_LIGHT_IMG})
    finalRewardsBtn:updateLabel({fnt = FONT.D20, fontSize = 22, text = __('大奖'), offset = cc.p(0, -35)})
    view:addList(finalLightImg):alignTo(finalRewardsBtn, ui.cc)
    view:addChild(finalRewardsBtn)

    finalLightImg:setVisible(false)
    finalLightImg:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.RotateBy:create(1, 45)
    )))
    
    local countRewardsBtn = ui.button({p = cc.p(size.width - 100, cpos.y + 20), n = RES_DICT.DRAW_COUNT_BTN})
    countRewardsBtn:updateLabel({fnt = FONT.D20, fontSize = 22, text = __('奖励'), offset = cc.p(0, -35)})
    view:addChild(countRewardsBtn)

    ---@class CapsuleFreeNewbieView.ViewData
    local viewData = {
        view              = view,
        leftTimesLabel    = countGroup[2],
        drawOnceBtn       = drawOnceBtn,
        drawMuchBtn       = drawMuchBtn,
        onceConsumeRLable = onceConsumeRLable,
        muchConsumeRLable = muchConsumeRLable,
        finalRewardsBtn   = finalRewardsBtn,
        finalLightImg     = finalLightImg,
        countRewardsBtn   = countRewardsBtn,
    }
    return viewData
end


function CapsuleFreeNewbieView.CreateFinalRewardsView()
    local view = ui.layer()

    local centerGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150), enable = true}),
        ui.image({img = RES_DICT.FINAL_LIGHT, mb = 358}),
        ui.image({img = RES_DICT.FINAL_TITLE, mb = 260}),
        ui.image({img = RES_DICT.FINAL_FRAME, enable = true}),
        ui.label({fnt = FONT.D14, text = __('请选择奖励'), mb = 160}),
        ui.button({n = RES_DICT.DRAW_BTN_N, d = RES_DICT.DRAW_BTN_D, mt = 150}):updateLabel({fnt = FONT.D14, text = __('领取')}),
        ui.tableView({size = cc.size(760,200), csizeW = 135, dir = ui.SDIR_H, mb = 15, bgColor1 = cc.r4b(150)}),
    })
    ui.flowLayout(display.center, centerGroup, {type = ui.flowC, ap = ui.cc})

    ---@type CTableView | ExDataSourceAdapter
    local rewardTableView = centerGroup[7]
    rewardTableView:setCellCreateHandler(CapsuleFreeNewbieView.CreateFinalRewardsCell)

    ---@class CapsuleFreeNewbieView.FinalRewardsViewData
    local viewData = {
        view            = view,
        blockLayer      = centerGroup[1],
        drawRewardsBtn  = centerGroup[6],
        rewardTableView = rewardTableView,
        selectedIndex   = 0,
    }
    return viewData
end


function CapsuleFreeNewbieView.CreateFinalRewardsCell(cellParent)
    local size = cellParent:getContentSize()
    local cpos = cc.sizep(size, ui.cc)
    local view = ui.layer({size = size})
    cellParent:add(view)
    
    local cardHeadNode = ui.cardHeadNode({p = cpos, scale = 0.6})
    view:addChild(cardHeadNode)

    local selectedLayer = ui.layer({size = size})
    view:addChild(selectedLayer)

    local selectedGroup = selectedLayer:addList({
        ui.layer({color = cc.c4b(0,0,0,150), size = cc.size(100,100), ap = ui.cc}),
        ui.image({img = RES_DICT.FINAL_SELECT}),
    })
    ui.flowLayout(cpos, selectedGroup, {type = ui.flowC, ap = ui.cc})
    
    local clickArea = ui.layer({size = size, color = cc.r4b(0), enable = true})
    view:addChild(clickArea)

    ---@class CapsuleFreeNewbieView.FinalRewardsCellViewData
    local viewData = {
        view          = view,
        cardHeadNode  = cardHeadNode,
        clickArea     = clickArea,
        selectedLayer = selectedLayer,
    }
    return viewData
end


function CapsuleFreeNewbieView.CreateCountRewardsView()
    local view = ui.layer()

    local blockLayer = ui.layer({color = cc.c4b(0,0,0,150), enable = true})
    view:addChild(blockLayer)

    local contentSize  = cc.size(860, 520)
    local contentCpos  = cc.sizep(contentSize, ui.cc)
    local contentLayer = ui.layer({p = display.center, ap = ui.cc, size = contentSize, bg = RES_DICT.COUNT_BG_FRAME, scale9 = true, enable = true})
    view:addChild(contentLayer)

    local titleBar = ui.title({img = RES_DICT.COUNT_COM_TITLE}):updateLabel({fnt = FONT.D3, text = __('奖励一览'), paddingW = 60, safeW = 120, offset = cc.p(0,-2)})
    contentLayer:addList(titleBar):alignTo(nil, ui.ct, {offsetY = -4})

    local rewardTableView = ui.tableView({size = cc.resize(contentSize, -40, -54), csizeH = 135, dir = ui.SDIR_V, bgColor1 = cc.r4b(150)})
    rewardTableView:setCellCreateHandler(CapsuleFreeNewbieView.CreateCountRewardsCell)
    contentLayer:addList(rewardTableView):alignTo(nil, ui.cc, {offsetY = -20})

    ---@class CapsuleFreeNewbieView.CountRewardsViewData
    local viewData = {
        view            = view,
        blockLayer      = blockLayer,
        rewardTableView = rewardTableView,
    }
    return viewData
end


function CapsuleFreeNewbieView.CreateCountRewardsCell(cellParent)
    local size = cellParent:getContentSize()
    local cpos = cc.sizep(size, ui.cc)
    local view = ui.layer({size = size})
    cellParent:add(view)

    local bgSize   = cc.resize(size, -18, -16)
    local bgFrameN = ui.image({img = RES_DICT.COUNT_CELL_BG_N, scale9 = true, size = bgSize, p = cpos})
    local bgFrameD = ui.image({img = RES_DICT.COUNT_CELL_BG_D, scale9 = true, size = bgSize, p = cpos})
    view:addChild(bgFrameN)
    view:addChild(bgFrameD)

    local descrRLabel = ui.rLabel({p = cc.p(30, cpos.y), ap = ui.lc})
    view:addChild(descrRLabel)

    local drawableLayer = ui.layer()
    local hasDrawnLayer = ui.layer()
    view:addChild(drawableLayer)
    view:addChild(hasDrawnLayer)

    local hasDrawnIntro = ui.title({p = cc.p(size.width - 90, cpos.y), n = RES_DICT.DRAW_DISABLE}):updateLabel({fnt = FONT.D7, fontSize = 24, text = __('已领取')})
    hasDrawnIntro:setRotation(-8)
    hasDrawnLayer:addChild(hasDrawnIntro)

    local drawRewardsBtn = ui.button({n = RES_DICT.DRAW_BTN_N, d = RES_DICT.DRAW_BTN_D}):updateLabel({fnt = FONT.D14, text = __('领取')})
    drawableLayer:addList(drawRewardsBtn):alignTo(hasDrawnIntro, ui.cc, {offsetY = -15})
    
    local targetNumPBar = ui.pBar({img = RES_DICT.COUNT_PBAR_IMG, bg = RES_DICT.COUNT_PBAR_BG, dir = ui.PDIR_LR})
    drawableLayer:addList(targetNumPBar):alignTo(hasDrawnIntro, ui.cc, {offsetY = 26})

    local targetNumLabel = ui.label({fnt = FONT.D8, ap = ui.rb})
    drawableLayer:addList(targetNumLabel):alignTo(targetNumPBar, ui.rt, {offsetX = -8})

    ---@type GoodNode[]
    local goodsNodeList = {}
    for goodsIndex = 1, 4 do
        goodsNodeList[goodsIndex] = ui.goodsNode({scale = 0.8, defaultCB = true, showAmount = true})
    end
    view:addList(goodsNodeList)
    ui.flowLayout(cc.p(size.width - 180, cpos.y), goodsNodeList, {type = ui.flowH, ap = ui.rc, gapW = 10})
    goodsNodeList = table.reverse(goodsNodeList)

    ---@class CapsuleFreeNewbieView.CountRewardsCellViewData
    local viewData = {
        view           = view,
        bgFrameN       = bgFrameN,
        bgFrameD       = bgFrameD,
        descrRLabel    = descrRLabel,
        goodsNodeList  = goodsNodeList,
        drawableLayer  = drawableLayer,
        hasDrawnLayer  = hasDrawnLayer,
        drawRewardsBtn = drawRewardsBtn,
        targetNumPBar  = targetNumPBar,
        targetNumLabel = targetNumLabel,
    }
    return viewData
end


return CapsuleFreeNewbieView