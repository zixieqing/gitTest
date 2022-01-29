--[[
    进阶卡池view
--]]
local CapsuleStepView = class('CapsuleStepView', function ()
    local node = CLayout:create()
    node.name = 'Game.views.drawCards.CapsuleStepView'
    node:enableNodeEvents()
    return node
end)

local RES_DICT = {
    ORANGE_BTN_N                = _res('ui/common/common_btn_big_orange_2.png'),
    ORANGE_BTN_D                = _res('ui/common/common_btn_big_orange_disabled_2.png'),
    SUMMON_STAGE_BG_TURN        = _res('ui/home/capsuleNew/StepSummon/summon_stage_bg_turn.png'),
    SUMMON_STAGE_BG_SELECTED    = _res('ui/home/capsuleNew/StepSummon/summon_stage_bg_slected.png'),
    SUMMON_NEWHAND_LABEL_SALE   = _res('ui/home/capsuleNew/StepSummon/summon_newhand_label_sale.png'),
    SUMMON_NEWHAND_LABEL_SALE_2 = _res('ui/home/capsuleNew/StepSummon/summon_newhand_label_sale_2.png'),
    SUMMON_STAGE_BG_BUTTON      = _res('ui/home/capsuleNew/StepSummon/summon_stage_bg_button.png'),
    SUMMON_STAGE_BG_STAGE_1     = _res('ui/home/capsuleNew/StepSummon/summon_stage_bg_stage_1.png'),
    SUMMON_STAGE_BG_STAGE_2     = _res('ui/home/capsuleNew/StepSummon/summon_stage_bg_stage_2.png'),
    SUMMON_STAGE_BG_STAGE_3     = _res('ui/home/capsuleNew/StepSummon/summon_stage_bg_stage_3.png'),
    SUMMON_STAGE_BG_STAGE_4     = _res('ui/home/capsuleNew/StepSummon/summon_stage_bg_stage_4.png'),
    SUMMON_STAGE_BG_STAGE_5     = _res('ui/home/capsuleNew/StepSummon/summon_stage_bg_stage_5.png'),
    SUMMON_STAGE_BG_STAGE_6     = _res('ui/home/capsuleNew/StepSummon/summon_stage_bg_stage_6.png'),
    SUMMON_IMG_LINE_SALE        = _res('ui/home/capsuleNew/StepSummon/summon_img_line_sale.png'),
    SUMMON_STAGE_BG_END         = _res('ui/home/capsuleNew/StepSummon/summon_stage_bg_end.png'),
}

local app           = app
local uiMgr         = app.uiMgr
local cardMgr       = app.cardMgr
local CommonUtils   = CommonUtils

function CapsuleStepView:ctor( ... )
    local args = unpack({...}) or {}
    local size = args.size
    self:setContentSize(size)
    
    self:initUI(size)
end

function CapsuleStepView:initUI(size)
    local function CreateView(size)
        local view = display.newLayer(0, 0, {size = size})

        local PaddingX = (size.width - 1044) / 7 + 172
        local PaddingY = 20
        local StepImgs = {true, true, true, true, true, true}
        for i=1,6 do
            local StepImg = display.newImageView(RES_DICT['SUMMON_STAGE_BG_STAGE_' .. i], i * PaddingX - 78, size.height / 2 - 200 + i * PaddingY)
            view:addChild(StepImg)
            StepImgs[i] = StepImg
        end

        local GlowImg = display.newImageView(RES_DICT.SUMMON_STAGE_BG_SELECTED, PaddingX - 78, size.height / 2 - 214 + PaddingY)
        view:addChild(GlowImg)

        local StepLabels = {true, true, true, true, true, true}
        for i=1,6 do
            local StepLabel = display.newLabel(i * PaddingX - 148, size.height / 2 + 15 + i * PaddingY, 
                fontWithColor(7, {text = string.fmt(__('阶段_num_'), {_num_ = i}), ap = cc.p(0, 0.5), fontSize = 24, outline = 'ca2020', outlineSize = 3}))
            view:addChild(StepLabel)
            StepLabels[i] = StepLabel
        end

        local StepDesrLabels = {true, true, true, true, true, true}
        for i=1,6 do
            local StepDesrLabel = display.newLabel(i * PaddingX - 150, size.height / 2 - 11 + i * PaddingY, 
                fontWithColor(7, {text = '', ap = cc.p(0, 1), fontSize = 24, w = 150, hAlign = display.TAL, outline = '593f3f', outlineSize = 2}))
            view:addChild(StepDesrLabel)
            StepDesrLabels[i] = StepDesrLabel
        end

        local SummonView = display.newLayer(0, 0, {size = size})
        view:addChild(SummonView)

        local SummonBtnPos = cc.p(size.width / 2 - 45, 108)

        local SummonBG = display.newImageView(RES_DICT.SUMMON_STAGE_BG_BUTTON, SummonBtnPos.x + 100, SummonBtnPos.y - 20)
        SummonView:addChild(SummonBG)

        local TabletImg = display.newButton(SummonBtnPos.x, SummonBtnPos.y + 50, {n = RES_DICT.SUMMON_STAGE_BG_TURN, enable = false})
        SummonView:addChild(TabletImg)
        display.commonLabelParams(TabletImg, fontWithColor(5, {text = '', offset = cc.p(0, 2)}))

        local RibbonImg = display.newButton(SummonBtnPos.x + 76, SummonBtnPos.y + 16, {n = RES_DICT.SUMMON_NEWHAND_LABEL_SALE, enable = false, scale9 = true, ap = cc.p(0, 0.5)})
        SummonView:addChild(RibbonImg)
        display.commonLabelParams(RibbonImg, {text = '', fontSize = 22})

        local SummonBtn = display.newButton(SummonBtnPos.x, SummonBtnPos.y, {n = RES_DICT.ORANGE_BTN_N, d = RES_DICT.ORANGE_BTN_D})
        display.commonLabelParams(SummonBtn, fontWithColor(14, {fontSize = 26, hAlign = display.TAC, text = __('召唤')}))
        SummonBtn:setEnabled(false)
        SummonView:addChild(SummonBtn)
        
		local CostLabel = display.newLabel(0, 0, fontWithColor(9, {text = '', ap = cc.p(1, 0.5), fontSize = 22}))
        SummonView:addChild(CostLabel)

        local CostIconPath = CommonUtils.GetGoodsIconPathById(DIAMOND_ID)
        local CostIcon = display.newNSprite(_res(CostIconPath), 0, 0)
        CostIcon:setScale(0.2)
        SummonView:addChild(CostIcon)

        display.setNodesToNodeOnCenter(SummonBtn, {CostLabel, CostIcon}, {y = -18})
        
        local CostPosX, CostPosY = CostLabel:getPosition()
		local OriginCostLabel = display.newLabel(CostPosX, CostPosY - 30, fontWithColor(9, {text = 1000, ap = cc.p(1, 0.5), fontSize = 22}))
        SummonView:addChild(OriginCostLabel)

        local CostIconPosX, CostIconPosY = CostIcon:getPosition()
        local OriginCostIconPath = CommonUtils.GetGoodsIconPathById(DIAMOND_ID)
        local OriginCostIcon = display.newNSprite(_res(OriginCostIconPath), CostIconPosX, CostIconPosY - 30)
        OriginCostIcon:setScale(0.2)
        SummonView:addChild(OriginCostIcon)

        local LineImg = display.newImageView(RES_DICT.SUMMON_IMG_LINE_SALE, CostPosX, CostPosY - 30)
        SummonView:addChild(LineImg)

        local ClearView = display.newLayer(0, 0, {size = size})
        view:addChild(ClearView)

        local ClearBG = display.newButton(size.width / 2, 108, {n = RES_DICT.SUMMON_STAGE_BG_END, enable = false})
        ClearView:addChild(ClearBG)
        display.commonLabelParams(ClearBG, fontWithColor(7, {fontSize = 24, color = '#fce6d4', text = __('召唤全部完成')}))

        ClearView:setVisible(false)
        view:setVisible(false)
        return {
            view            = view,
            PaddingX        = PaddingX,
            PaddingY        = PaddingY,
            size            = size,
            StepImgs        = StepImgs,
            GlowImg         = GlowImg,
            StepLabels      = StepLabels,
            StepDesrLabels  = StepDesrLabels,
            SummonView      = SummonView,
            SummonBtn       = SummonBtn,
            TabletImg       = TabletImg,
            RibbonImg       = RibbonImg,
            CostLabel       = CostLabel,
            CostIcon        = CostIcon,
            OriginCostLabel = OriginCostLabel,
            OriginCostIcon  = OriginCostIcon,
            LineImg         = LineImg,
            ClearView       = ClearView,
        }
    end
    xTry(function ( )
		self.viewData = CreateView(size)
        self:addChild(self.viewData.view)
	end, __G__TRACKBACK__)
end

function CapsuleStepView:getViewData()
    return self.viewData
end

function CapsuleStepView:RefreshUI(data)
    local viewData = self:getViewData()
    local view = viewData.view

    view:setVisible(true)
    self:RefreshRound(data)
    self:RefreshSummonView(data)
end

function CapsuleStepView:RefreshRound( data )
    local viewData = self:getViewData()
    local size = viewData.size
    local GlowImg = viewData.GlowImg
    local TabletImg = viewData.TabletImg
    local StepImgs = viewData.StepImgs
    local StepLabels = viewData.StepLabels
    local StepDesrLabels = viewData.StepDesrLabels

    local currentStep = math.max(checkint(data.currentStep), 1)
    local step = data.step

    GlowImg:setPosition(currentStep * viewData.PaddingX - 78, size.height / 2 - 214 + currentStep * viewData.PaddingY)
    if self:IsSummonEnd(data) then
        GlowImg:setVisible(false)
        TabletImg:setVisible(false)
    else
        display.commonLabelParams(TabletImg, fontWithColor(5, {text = string.fmt(__('第_num_轮'), {_num_ = data.currentRound})}))
    end

    for i,v in ipairs(step) do
        StepDesrLabels[i]:setString(v.backgroundText)
        StepImgs[i]:setTexture(RES_DICT[string.upper( v.backgroundImage )])
    end
    for i,v in ipairs(StepLabels) do
        if currentStep == i and not self:IsSummonEnd(data) then
            display.commonLabelParams(v, fontWithColor(7, {text = string.fmt(__('阶段_num_'), {_num_ = i}), fontSize = 24, outline = 'ca2020', outlineSize = 3}))
        else 
            display.commonLabelParams(v, fontWithColor(7, {text = string.fmt(__('阶段_num_'), {_num_ = i}), fontSize = 24, outline = '593f3f', outlineSize = 3}))
        end
    end
end

function CapsuleStepView:RefreshSummonView( data )
    local viewData = self:getViewData()
    local SummonView = viewData.SummonView
    local SummonBtn = viewData.SummonBtn
    local RibbonImg = viewData.RibbonImg
    local CostLabel = viewData.CostLabel
    local CostIcon = viewData.CostIcon
    local OriginCostLabel = viewData.OriginCostLabel
    local OriginCostIcon = viewData.OriginCostIcon
    local LineImg = viewData.LineImg
    local ClearView = viewData.ClearView
    
    local currentStep = math.max(checkint(data.currentStep), 1)
    local step = data.step[currentStep]

    if self:IsSummonEnd(data) then
        -- all the summon round clear
        SummonBtn:setEnabled(false)
        SummonView:setVisible(false)
        ClearView:setVisible(true)
    else
        if not next(step.consume or {}) then
            -- free
            CostLabel:setVisible(false)
            CostIcon:setVisible(false)
            OriginCostLabel:setVisible(false)
            OriginCostIcon:setVisible(false)
            LineImg:setVisible(false)
            RibbonImg:setVisible(true)
            RibbonImg:setNormalImage(RES_DICT.SUMMON_NEWHAND_LABEL_SALE_2)
            display.commonLabelParams(RibbonImg, {text = __('免费'), paddingW = 30, offset = cc.p(-8, 2)})
        else
            CostLabel:setVisible(true)
            CostIcon:setVisible(true)
            OriginCostLabel:setVisible(true)
            OriginCostIcon:setVisible(true)
            LineImg:setVisible(true)

            local cost = self:GetCost(step)
            local consume = step.consume[cost]
            local originalConsume = step.originalConsume[cost] or step.originalConsume[1]

            CostLabel:setString(string.format(__('消耗%d'), consume.num))
            local CostIconPath = CommonUtils.GetGoodsIconPathById(consume.goodsId)
            CostIcon:setTexture(CostIconPath)
            display.setNodesToNodeOnCenter(SummonBtn, {CostLabel, CostIcon}, {y = -18})
    
            if tonumber(consume.num) == tonumber(originalConsume.num) then
                -- no discount
                OriginCostLabel:setVisible(false)
                OriginCostIcon:setVisible(false)
                LineImg:setVisible(false)
                RibbonImg:setVisible(false)
            else
                OriginCostLabel:setVisible(true)
                OriginCostIcon:setVisible(true)
                LineImg:setVisible(true)

                OriginCostLabel:setString(originalConsume.num)
                local OriginCostIconPath = CommonUtils.GetGoodsIconPathById(originalConsume.goodsId)
                OriginCostIcon:setTexture(OriginCostIconPath)
        
                local CostPosX, CostPosY = CostLabel:getPosition()
                OriginCostLabel:setPositionX(CostPosX)
                OriginCostIcon:setPositionX(CostIcon:getPositionX())
                LineImg:setPositionX(CostPosX - display.getLabelContentSize(OriginCostLabel).width / 2)
                
                RibbonImg:setNormalImage(RES_DICT.SUMMON_NEWHAND_LABEL_SALE)
                display.commonLabelParams(RibbonImg, {text = string.fmt(__('_num_%折扣'), {_num_ = math.floor((originalConsume.num - consume.num) * 100 / originalConsume.num)}), paddingW = 30, offset = cc.p(-8, 2)})
            end
        end
        display.commonLabelParams(SummonBtn, fontWithColor(14, {text = string.fmt(__('召唤\n_num_次'), {_num_ = step.gamblingTimes})}))

        SummonBtn:setEnabled(true)
    end
end

function CapsuleStepView:IsSummonEnd( data )
    local currentStep = math.max(checkint(data.currentStep), 1)
    if tonumber(data.round) < tonumber(data.currentRound) then
        return true
    end
    return false
end

function CapsuleStepView:GetCost( data )
    for i,v in ipairs(data.consume) do
        if CommonUtils.GetCacheProductNum(v.goodsId) >= tonumber(v.num) or i == table.nums(data.consume) then
            return i
        end
    end
end

return CapsuleStepView
