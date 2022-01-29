local Anniversary20SweepView = class('Anniversary20SweepView', function ()
    return ui.layer({name = 'Anniversary20SweepView', enableEvent = true})
end)


local RES_DICT = {
    IMAGE_BG              = _res('ui/anniversary20/sweep/anni_rewards_bg.png'),
    IMAGE_BUTTON_SELECTED = _res('ui/anniversary20/sweep/summer_activity_entrance_rank_tab_selected.png'),
    IMAGE_BUTTON_GREY     = _res('ui/anniversary20/sweep/summer_activity_entrance_rank_tab_unused_grey.png'),
    IMAGE_BUTTON_NORMAL   = _res('ui/anniversary20/sweep/summer_activity_entrance_rank_tab_unused.png'),
    ---                   = gridCell
    GRID_CELL_BG          = _res('ui/anniversary20/sweep/anni_rewards_bg_list.png'),
    COMMON_BTN            = _res('ui/common/common_btn_orange.png'),
    DISABLE_BTN           = _res("ui/common/common_btn_orange_disable.png")
}

function Anniversary20SweepView:ctor()
    self._viewData = Anniversary20SweepView.CreateView()
    self:add(self._viewData.view)

    self:initEntranceDatas_()

    self:getViewData().levelTableView:setCellUpdateHandler(handler(self, self.onUpdateLevelTableCellHanelr_))
end


function Anniversary20SweepView.CreateView()
    local view = ui.layer()

    local SWEEP_LAYER_SIZE = cc.size(904, 740)
    -- blockLayer, sweepBlockLayer, sweepLayer
    local layerGroup = view:addList({
        ui.layer({color = cc.c4b(0, 0, 0, 150), enable = true}),
        ui.layer({size = SWEEP_LAYER_SIZE, enable = true, color = cc.r4b(0)}),
        ui.layer({size = SWEEP_LAYER_SIZE}),
    })
    ui.flowLayout(cc.sizep(view, ui.cc), layerGroup, {type = ui.flowC, ap = ui.cc})

    -- entranceTab Group
    local sweepLayer  = layerGroup[3]
    local chapterBtns = {}
    for entranceIndex, chapterConf in pairs(CONF.ANNIV2020.EXPLORE_ENTRANCE:GetAll()) do
        local titleBtn = Anniversary20SweepView.CreateChapterBtn(chapterConf)
        titleBtn:setTag(checkint(chapterConf.id))
        chapterBtns[checkint(entranceIndex)] = titleBtn
    end
    sweepLayer:addList(chapterBtns)
    ui.flowLayout(cc.rep(cc.sizep(SWEEP_LAYER_SIZE, ui.lt), 60, -60), chapterBtns, {type = ui.flowH, ap = ui.lb})

    -- levelTable group
    local GRID_VIEW_SIZE = cc.resize(SWEEP_LAYER_SIZE, -44, -100)
    local gridViewGroup = sweepLayer:addList({
        ui.image({img = RES_DICT.IMAGE_BG, mt = 20}),
        ui.tableView({size = GRID_VIEW_SIZE, csizeH = 210, auto = true, dir = display.SDIR_V, mt = 20}),
    })
    ui.flowLayout(cc.sizep(sweepLayer, ui.cc), gridViewGroup, {type = ui.flowC, ap = ui.cc})

    local levelTableView = gridViewGroup[2]
    levelTableView:setCellCreateHandler(Anniversary20SweepView.CreateLevelTableCell)

    return {
        view           = view,
        blockLayer     = layerGroup[1],
        levelTableView = gridViewGroup[2],
        chapterBtns    = chapterBtns,
    }
end


function Anniversary20SweepView:getViewData()
    return self._viewData
end


function Anniversary20SweepView:initEntranceDatas_()
    self._chapterDatasMap = {}
    for _, exploreData in pairs(app.anniv2020Mgr:getExploreEntranceDatas()) do
        self._chapterDatasMap[checkint(exploreData.exploreModuleId)] = exploreData
    end

    for index, chapterBtn in ipairs(self:getViewData().chapterBtns) do
        local chapterId   = checkint(chapterBtn:getTag())
        local chapterData = checktable(self._chapterDatasMap[chapterId])
        chapterBtn.isUnlocked = checkint(chapterData.maxFloor) > 0
        chapterBtn:setEnabled(chapterBtn.isUnlocked)
    end
end


function Anniversary20SweepView.CreateChapterBtn(chapterConf)
    local chapterTabText = tostring(chapterConf.name)
    local chapterNLabel  = ui.label({fnt = FONT.D20, fontSize = 20, outline = '#7b482f', text = chapterTabText})
    local chapterSLabel  = ui.label({fnt = FONT.D20, fontSize = 20, outline = '#7b482f', text = chapterTabText})
    local chapterDLabel  = ui.label({fnt = FONT.D20, fontSize = 20, outline = '#4f4f4f', text = chapterTabText})
    local chapterLabelW  = chapterNLabel:getBoundingBox().width
    local chapterTabSize = cc.size(math.max(220, chapterLabelW + 100), 55)
    local chapterTabBtn  = ui.tButton({n = RES_DICT.IMAGE_BUTTON_NORMAL, s = RES_DICT.IMAGE_BUTTON_SELECTED, d = RES_DICT.IMAGE_BUTTON_GREY, scale9 = true, size = chapterTabSize})
    chapterTabBtn:getNormalImage():addList(chapterNLabel):alignTo(nil, ui.cc)
    chapterTabBtn:getSelectedImage():addList(chapterSLabel):alignTo(nil, ui.cc)
    chapterTabBtn:getDisabledImage():addList(chapterDLabel):alignTo(nil, ui.cc)
    return chapterTabBtn
end


function Anniversary20SweepView:getSweepConfs()
    return checktable(self.sweepConfs_)
end
function Anniversary20SweepView:setSweepConfs(sweepConfs)
    self.sweepConfs_ = checktable(sweepConfs)
    self:getViewData().levelTableView:resetCellCount(table.nums(self.sweepConfs_))
end


function Anniversary20SweepView:setSelectedTabIndex(chapterId)
    self.selectedTabIndex = chapterId
    for chapterId, chapterBtn in ipairs(self:getViewData().chapterBtns) do
        local isSelected = chapterId == self.selectedTabIndex
        if isSelected and chapterBtn.isUnlocked == false then
            chapterBtn:setEnabled(true)
        end
        
        chapterBtn:setChecked(isSelected)
    end
end


----------------------------------------------------------------------- gridCell
function Anniversary20SweepView.CreateLevelTableCell(cellParent)
    local size = cellParent:getContentSize()
    local cell = ui.layer({size = size})
    cellParent:addChild(cell)

    local gridCenterGroup = cell:addList({
        ui.image({img = RES_DICT.GRID_CELL_BG, scale9 = true}),
        ui.label({fontSize = 24, color = "#aa7522", mb = 80}),
    })
    ui.flowLayout(cc.sizep(size, ui.cc), gridCenterGroup, {type = ui.flowC, ap = ui.cc})

    local gridLeftGroup = cell:addList({
        ui.label({color = "#c0934e", text = __("可获得:"), fontSize = 24}),
        ui.layer({size = cc.size(size.width - 300, size.height - 100)}),
    })
    ui.flowLayout(cc.rep(cc.sizep(size, ui.lt), 60, -50), gridLeftGroup, {type = ui.flowV, ap = ui.lb})

    local gridRightGroup = cell:addList({
        ui.button({n = RES_DICT.COMMON_BTN, d = RES_DICT.DISABLE_BTN, scale9 = true}):updateLabel({fnt = FONT.D20, fontSize = 24, outline = "#7b482f", text = __("扫荡"), paddingW = 20}),
        ui.rLabel({mt = 15})
    })
    ui.flowLayout(cc.rep(cc.sizep(size, ui.rc), -140, 0), gridRightGroup, {type = ui.flowV, ap = ui.cb})

    return {
        view            = cell,
        titleLabel      = gridCenterGroup[2],
        rewardLayer     = gridLeftGroup[2],
        sweepBtn        = gridRightGroup[1],
        sweepCostRLable = gridRightGroup[2],
        gridRewardCells = {},
    }
end


function Anniversary20SweepView:onUpdateLevelTableCellHanelr_(cellIndex, cellViewData)
    if cellViewData == nil then return end

    local sweepConf  = checktable(self:getSweepConfs()[checkint(cellIndex)])

    -- update rewards
    local sweepRewards  = checktable(sweepConf.rewards)
    local rewardCells   = cellViewData.gridRewardCells
    local needRewardNum = table.nums(sweepRewards)
    for rewardIndex = 1, math.max(needRewardNum, #rewardCells) do
        local rewardNode = rewardCells[rewardIndex]
        local rewardData = checktable(sweepRewards[rewardIndex])
        if not rewardNode then
            rewardNode = ui.goodsNode({defaultCB = true})
            table.insert(cellViewData.gridRewardCells, rewardNode)

            local goodSize = rewardNode:getContentSize()
            cellViewData.rewardLayer:addList(rewardNode):alignTo(nil, ui.lc, {offsetX = (goodSize.width + 15) * (rewardIndex - 1), offsetY = -6})
        end
		
		if rewardIndex > needRewardNum then
			rewardNode:setVisible(false)
		else
			rewardNode:RefreshSelf({goodsId = checkint(rewardData.goodsId), num = checkint(rewardData.num), showAmount = true})
			rewardNode:setVisible(true)
        end
    end

    -- update cost
    cellViewData.sweepCostRLable:reload({
        {img = GoodsUtils.GetIconPathById(app.anniv2020Mgr:getHpGoodsId()), scale = 0.2},
        {text = " x" .. tostring(sweepConf.consumeNum), fontSize = 22, color = "#ab7624"},
    })

    -- update title
    cellViewData.titleLabel:setString(string.fmt("_min_ - _max_", {_min_ = checkint(sweepConf.floorMin), _max_ = checkint(sweepConf.floorMax)}))

    -- update btnStatue
    local chapterData = checktable(self._chapterDatasMap[self.selectedTabIndex])
    local isEnable = checkint(chapterData.maxFloor) >= checkint(sweepConf.floorMax)
	local btnColor = isEnable and '#7b482f' or '#4f4f4f'
    cellViewData.sweepBtn:getLabel():enableOutline(ccc4FromInt(btnColor), 2)
    cellViewData.sweepBtn:setEnabled(isEnable)
    cellViewData.sweepBtn:setTag(cellIndex)
end


return Anniversary20SweepView