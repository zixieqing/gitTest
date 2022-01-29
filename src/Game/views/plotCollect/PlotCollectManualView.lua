--[[
登录弹窗
--]]
local PlotCollectManualView = class('PlotCollectManualView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.plotCollect.PlotCollectManualView'
	node:enableNodeEvents()
	return node
end)

local RES_DICT = {
    COMMON_BTN_BACK       = _res('ui/common/common_btn_back.png'),
    COMMON_TITLE          = _res('ui/common/common_title_new.png'),
    COMMON_BTN_TIPS       = _res('ui/common/common_btn_tips.png'),
    COMMON_BTN_ORANGE     = _res('ui/common/common_btn_orange.png'),
    RECHARGE_BTN_ARROW    = _res('ui/home/recharge/recharge_btn_arrow.png'),
    PLOT_COLLECT_CG_BG    = _res('ui/home/plotCollect/plot_collect_cg_bg.jpg'),
    PLOT_COLLECT_BOOK     = _res('ui/home/plotCollect/plot_collect_book.jpg'),
    PLOT_COLLECT_BTN_PLOT = _res('ui/home/plotCollect/plot_collect_btn_plot.jpg'),
    PLOT_COLLECT_WORDS_BG = _res('ui/home/plotCollect/plot_collect_words_bg.jpg'),
    
    -- todo 更新背景
    PLOT_COLLECT_BG       = _res('ui/home/plotCollect/plot_collect_bg.jpg'),
}

local CreateView     = nil
local CreateCell_    = nil
local CreateCGView   = nil
local CreateCGCell_  = nil

local VIEW_TYPE = {
    CG      = 1,
    DEFAULT = 0,
}


function PlotCollectManualView:ctor( ... )
    self.args      = unpack({...}) or {}
    self.rightConf = nil
    

	xTry(function ( )
        self.viewData = CreateView(self.args.background)
        self:addChild(self.viewData.view)
	end, __G__TRACKBACK__)
end

function PlotCollectManualView:UpdatePlotList(datas)
    local viewData = self:GetViewData()
    local plotList = viewData.plotList
    plotList:setCountOfCell(#datas)
    plotList:reloadData()
end

function PlotCollectManualView:UpdateCell(viewData, data)
    local nameLabel = viewData.nameLabel
    display.commonLabelParams(nameLabel, {text = tostring(data.name)})

end

function PlotCollectManualView:RefreshRightUI(viewType, data)
    self.datas = data
    self.curCGIndex = 1

    local viewData       = self:GetViewData()
    local rightLayer     = viewData.rightLayer
    local rightLayerSize = viewData.rightLayerSize
    
    rightLayer:setVisible(true)
    
    local cgView = viewData.cgView
    if cgView then
        cgView:setVisible(false)
    end

    local wordBg    = viewData.wordBg
    local recallBtn = viewData.recallBtn
    recallBtn:setTag(checkint(data.id))
    recallBtn:setUserTag(checkint(data.areaId))
    if viewType == VIEW_TYPE.DEFAULT then
        wordBg:setContentSize(cc.size(422, 400))

        recallBtn:setPositionY(60)
    else
        wordBg:setContentSize(cc.size(422, 241))
        recallBtn:setPositionY(rightLayerSize.height * 0.5)
        
        local zoomSliderList
        if cgView == nil then
            local cgViewData = CreateCGView()
            table.merge(viewData, cgViewData)
            -- viewData.cgViewData = cgViewData
            zoomSliderList = cgViewData.zoomSliderList
            
            display.commonUIParams(cgViewData.switchBtn, {cb = handler(self, self.OnClickSwitchBtnAction), animate = false})

            cgView = cgViewData.cgView
            cgView:setPositionY(25)
            viewData.rightLayer:addChild(cgView)

            zoomSliderList:setCellChangeCB(function (p_convertview, idx)
                local pCell = p_convertview
                local index = idx
            
                if pCell == nil then
                    pCell = CreateCGCell_()
                end
                
                self:UpdateCGCell(pCell, index)
                return pCell
            end)
            zoomSliderList:setIndexOverChangeCB(function(sender, index_)
                -- update day
                if self.init then return end
                self.curSelectIndex = index_
            end)
        else
            zoomSliderList = viewData.zoomSliderList
            cgView:setVisible(true)
        end
        local cgIds = data.cgId or {}
        zoomSliderList:setCellCount(#cgIds)
        zoomSliderList:reloadData()
        zoomSliderList:setCenterIndex(self.curCGIndex, true)
    end

    local descLabel      = viewData.descLabel
    display.commonLabelParams(descLabel, {text = tostring(data.descr)})
end

function PlotCollectManualView:UpdateCGCell(cell, index)
    local cgIds = self.datas.cgId or {}
    local cgId  = cgIds[index]
    local cgImg = cell.cgImg
    local path  = _res( string.format("ui/home/cg/completeCG/%s.jpg" , cgId or "loading_view_14_s" ))
    cgImg:setTexture(path)

    local size = cell:getContentSize()
    local cgImgSize = cgImg:getContentSize()
    local scale = math.min(size.width / cgImgSize.width, size.height / cgImgSize.height)
    cgImg:setScale(scale)
end

function PlotCollectManualView:OnClickSwitchBtnAction(sender)
    local cgIds = self.datas.cgId or {}
    local cgCount = #cgIds
    if cgCount > 1 then
        self.curCGIndex = self.curCGIndex + 1
        if self.curCGIndex > cgCount then
            self.curCGIndex = 1
        end
        self:GetViewData().zoomSliderList:setCenterIndex(self.curCGIndex)
    end

end

CreateView = function (background)
    local view = display.newLayer()
    local size = view:getContentSize()

    local shallowLayer = display.newLayer(0, 0, {size = size, color = cc.c4b(0,0,0,0), enable = true})
    view:addChild(shallowLayer)

    local middlePosX, middlePosY = size.width * 0.5, size.height * 0.5
    local bg = display.newImageView(_res(string.format("arts/stage/bg/%s", tostring(background))), middlePosX, middlePosY, {isFull = true})
    view:addChild(bg)

    local backBtn = display.newButton(display.SAFE_L + 57, display.height - 55,
    {
        ap = display.CENTER,
        n = RES_DICT.COMMON_BTN_BACK,
        enable = true,
    })
    view:addChild(backBtn)

    local titleBtn = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE, enable = true, ap = display.LEFT_TOP})
    display.commonLabelParams(titleBtn, {ttf = true, font = TTF_GAME_FONT, text = __('剧情收集'), fontSize = 30, color = '#473227',offset = cc.p(0,-8)})
    view:addChild(titleBtn)

    local tipsImg = display.newNSprite(RES_DICT.COMMON_BTN_TIPS, 250, 30,
    {
        ap = display.CENTER,
    })
    titleBtn:addChild(tipsImg)

    -- manual layer
    local manualLayerSize = cc.size(986, 632)
    local manualLayer = display.newLayer(middlePosX, middlePosY - 30, {size = manualLayerSize, ap = display.CENTER})
    view:addChild(manualLayer)

    local manualBg = display.newNSprite(RES_DICT.PLOT_COLLECT_BOOK, manualLayerSize.width * 0.5, manualLayerSize.height * 0.5)
    manualLayer:addChild(manualBg)
    
    local plotListSize     = cc.size(416, 536)
    local plotListCellSize = cc.size(plotListSize.width, 106)
    local plotList = CTableView:create(plotListSize)
    display.commonUIParams(plotList, {po = cc.p(260, manualLayerSize.height - 40), ap = display.CENTER_TOP})
    plotList:setDirection(eScrollViewDirectionVertical)
    -- plotList:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    plotList:setSizeOfCell(plotListCellSize)
    manualLayer:addChild(plotList)

    local rightLayerSize = cc.size(420, 536)
    local rightLayer = display.newLayer(manualLayerSize.width - 260, manualLayerSize.height - 40, {ap = display.CENTER_TOP, size = rightLayerSize})
    manualLayer:addChild(rightLayer)
    rightLayer:setVisible(false)

    local wordBg = display.newImageView(RES_DICT.PLOT_COLLECT_WORDS_BG, rightLayerSize.width * 0.5, rightLayerSize.height, {ap = display.CENTER_TOP, scale9 = true})
    rightLayer:addChild(wordBg)

    local descTitleLabel = display.newLabel(rightLayerSize.width * 0.5, rightLayerSize.height - 18, fontWithColor(16, {ap = display.CENTER_TOP, text = __('剧情描述')}))
    rightLayer:addChild(descTitleLabel)
    
    local descLabel = display.newLabel(10, rightLayerSize.height - 46, fontWithColor(6, {ap = display.LEFT_TOP, w = rightLayerSize.width - 20}))
    rightLayer:addChild(descLabel)

    local recallBtn = display.newButton(wordBg:getPositionX(), rightLayerSize.height * 0.5, {n = RES_DICT.COMMON_BTN_ORANGE, ap = display.CENTER_TOP})
    display.commonLabelParams(recallBtn, fontWithColor(14, {text = __('回放')}))
    rightLayer:addChild(recallBtn)

    return {
        view           = view,
        backBtn        = backBtn,
        titleBtn       = titleBtn,
        plotList       = plotList,
        wordBg         = wordBg,
        descTitleLabel = descTitleLabel,
        descLabel      = descLabel,
        recallBtn      = recallBtn,
        rightLayer     = rightLayer,
        
        rightLayerSize = rightLayerSize,
    }
end

CreateCGView = function ()
    local cgViewSize = cc.size(420, 131)
    local cgView = display.newLayer(0, 0, {size = cgViewSize})

    local zoomSliderList = require("common.ZoomSliderList").new()
    cgView:addChild(zoomSliderList)
    zoomSliderList:setCellSize(cc.size(204, 131))
    zoomSliderList:setAlphaMin(210)
    zoomSliderList:setCellSpace(60)
    -- zoomSliderList:setDirection(1)
    zoomSliderList:setCenterIndex(1)
    zoomSliderList:setScaleMin(0.9)
    zoomSliderList:setAlignType(0)
    zoomSliderList:setSideCount(1)
    -- zoomSliderList:setEnabled(false)
    zoomSliderList:setPosition(cc.p(cgViewSize.width * 0.5, cgViewSize.height * 0.5))
    zoomSliderList:setSwallowTouches(false)

    local switchBtn = display.newButton(cgViewSize.width - 10, cgViewSize.height * 0.5, {n = RES_DICT.RECHARGE_BTN_ARROW, ap = display.CENTER})
    switchBtn:setScale(0.7)
    cgView:addChild(switchBtn)

    return {
        cgView         = cgView,
        zoomSliderList = zoomSliderList,
        switchBtn      = switchBtn,
    }
end

CreateCell_ = function (size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    local bg = display.newImageView(RES_DICT.PLOT_COLLECT_BTN_PLOT, size.width * 0.5, size.height * 0.5)
    bg:setTouchEnabled(true)
    cell:addChild(bg)

    local nameLabel = display.newLabel(30, size.height * 0.5, fontWithColor(16, {ap = display.LEFT_CENTER, w = size.width - 60}))
    cell:addChild(nameLabel)

    cell.viewData = {
        bg        = bg,
        nameLabel = nameLabel
    }

    return cell
end

CreateCGCell_ = function ()
    local bg = display.newImageView(RES_DICT.PLOT_COLLECT_CG_BG, 10, 50, {ap = display.CENTER})

    local cgImg = display.newNSprite()
    display.commonUIParams(cgImg, {ap = display.CENTER, po = utils.getLocalCenter(bg)})
    bg:addChild(cgImg)

    bg.cgImg = cgImg


    return bg
end

function PlotCollectManualView:CreateCell(size)
    return CreateCell_(size)
end

function PlotCollectManualView:GetViewData()
	return self.viewData
end

return PlotCollectManualView
