--[[
 * author : panmeng
 * descpt : 猫咪深造工作 界面
]]

local CatModuleCatGrowView = class('CatModuleCatGrowView', function()
    return ui.layer({name = 'Game.views.catModule.CatModuleCatGrowView', enableEvent = true})
end)

local RES_DICT = {
    BTN_WORK        = _res('ui/catModule/catInfo/work/grow_cat_work_ico_bag.png'),
    BTN_STUDY       = _res('ui/catModule/catInfo/work/grow_cat_work_ico_book.png'),
    DESCR_BG        = _res('ui/catModule/catInfo/work/grow_cat_work_list_bg_ask.png'),
    BTN_TASK_N      = _res('ui/catModule/catInfo/work/grow_cat_work_list_bg_dark.png'),
    BTN_TASK_S      = _res('ui/catModule/catInfo/work/grow_cat_work_list_bg_light.png'),
    BTN_STUDY_N     = _res('ui/catModule/catInfo/work/grow_cat_study_list_bg_drak.png'),
    BTN_STUDY_S     = _res('ui/catModule/catInfo/work/grow_cat_study_list_bg_light.png'),
    BG_DESCR_N      = _res('ui/catModule/catInfo/work/grow_cat_work_list_bg_position.png'),
    BG_DESCR_S      = _res('ui/catModule/catInfo/work/grow_cat_work_list_bg_position_light.png'),
    BG_TIP          = _res('ui/catModule/catInfo/work/grow_cat_work_list_bg_thing_red.png'),
    BG_GOOD         = _res('ui/catModule/catInfo/work/grow_cat_work_list_bg_thing.png'),
    BG_TIME         = _res('ui/catModule/catInfo/work/grow_cat_work_list_bg_time.png'),
    BG_UP           = _res('ui/catModule/catInfo/work/grow_cat_work_list_ico_position_light.png'),
    BG_TASK         = _res('ui/catModule/catInfo/life/grow_cat_life_bg_wood.png'),
    BG_TASK_DETAIL  = _res('ui/catModule/catInfo/life/grow_cat_life_bg_wood_use.png'),
    GOODS_TIME_ICON = _res('ui/stores/base/shop_ico_time_dark.png'),
    STUDY_N         = _res('ui/catModule/catInfo/work/grow_cat_study_list_pic_book_drak.png'),
    STUDY_S         = _res('ui/catModule/catInfo/work/grow_cat_study_list_pic_book.png'),
    PRO_BG          = _res('ui/catModule/catInfo/work/grow_cat_work_line_lv_under.png'),
    PRO_IMG         = _res('ui/catModule/catInfo/work/grow_cat_work_line_lv_top.png'),
    CONFIRM_BTN     = _res('ui/common/common_btn_orange.png'),
    DISABLE_BTN     = _res('ui/common/common_btn_orange_disable.png'),
    CANCEL_BTN      = _res("ui/common/common_btn_white_default.png"),
    BG_STUDY_NEED   = _res('ui/catModule/catInfo/work/grow_cat_study_list_bg_get.png'),
    BG_STUDY_DETAIL = _res('ui/catModule/catInfo/work/grow_cat_study_list_bg_thing.png'),
    FRAME_DETAIL    = _res('ui/catModule/catInfo/life/grow_cat_life_bg_wood_use.png'),
    COMMON_TITLE_5  = _res('ui/common/common_title_5.png'),
    COST_BG         = _res('ui/catModule/catInfo/work/grow_main_shop_bg_money.png'),
    BTN_ACTION_L    = _res('ui/catModule/catInfo/life/grow_cat_life_btn_module_light.png'),
    BTN_ACTION_N    = _res('ui/catModule/catInfo/life/grow_cat_life_btn_module.png'),
    BTN_ACTION_S    = _res('ui/catModule/catInfo/life/grow_cat_life_btn_module_choose.png'),
    SELECTED_IMG    = _res('ui/catModule/headNode/grow_book_details_btn_cat_light.png'),
    VALUE_BG        = _res('ui/catModule/catInfo/work/grow_birth_sure_bg_number.png'),
    STUDYING_SPINE  = _spn('ui/catModule/catInfo/work/anim/cat_book'),
    WORKING_SPINE   = _spn('ui/catModule/catInfo/work/anim/cat_work'),
}

CatModuleCatGrowView.POSTGRADUATE_TYPE = {
    WORK  = 1, -- 工作
    STUDY = 2, -- 学习
}

local ACTION_DEFINE = {
    [CatModuleCatGrowView.POSTGRADUATE_TYPE.WORK]    = {title = __("工作"), img = RES_DICT.BTN_WORK},
    [CatModuleCatGrowView.POSTGRADUATE_TYPE.STUDY]   = {title = __("学习"), img = RES_DICT.BTN_STUDY},
}

local GetStarIconByCareerLevel = function(starIndex)
    return _res("ui/catModule/catInfo/work/grow_cat_work_ico_star_" .. starIndex .. ".png")
end


function CatModuleCatGrowView:ctor(args)
    -- create view
    self.viewData_ = CatModuleCatGrowView.CreateView()
    self:addChild(self.viewData_.view)
end

-----------------------------------------------------------------------------
-- get/set

function CatModuleCatGrowView:getViewData()
    return self.viewData_
end

-----------------------------------------------------------------------------
-- public
function CatModuleCatGrowView:updateDamandNode(cellViewData, data)
    cellViewData.value:updateLabel({text = data.value})

    local iconPath = ""
    if data.isAttr then
        iconPath = CatHouseUtils.GetCatAttrTypeIconPath(data.damandId)
    else
        iconPath = _res(string.format("ui/catModule/catInfo/abilityIcon/ability_%s.png", data.damandId))
    end
    cellViewData.icon:setTexture(iconPath)
end

---@param catModel HouseCatModel
function CatModuleCatGrowView:updateStudyCellHandler(cellViewData, studyId, isSelected, catModel)
    cellViewData.selectedImg:setVisible(isSelected)
    cellViewData.view:setTag(studyId)

    local studyConf = CONF.CAT_HOUSE.CAT_STUDY:GetValue(studyId)
    if next(studyConf) == nil then
        return
    end

    -- update title
    cellViewData.titleLabel:updateLabel({text = studyConf.name, reqW = 400})
    

    -- update require demand
    local requireAbilityList = {}
    for abilityId, abilityValue in pairs(studyConf.requireAbility) do
        table.insert(requireAbilityList, {id = abilityId, value = abilityValue})
    end
    cellViewData.emptyTip:setVisible(#requireAbilityList <= 0)
    cellViewData.requireAbilityList = requireAbilityList
    cellViewData.damandTableView:resetCellCount(#requireAbilityList, true)
    cellViewData.damandTableView:setTouchable(cellViewData.damandTableView:isDragable())
    -- local abilityIndex = 1
    -- for abilityId, abilityValue in pairs(studyConf.requireAbility) do
    --     if cellViewData.abilityNodes[abilityIndex] then
    --         cellViewData.abilityNodes[abilityIndex].refreshSelf(false, abilityId, abilityValue)
    --         cellViewData.abilityNodes[abilityIndex]:setVisible(true)
    --     else
    --     end
    --     abilityIndex = abilityIndex + 1
    -- end
    -- for index = abilityIndex, #cellViewData.abilityNodes do
    --     cellViewData.abilityNodes[index]:setVisible(false)
    -- end

    -- check is studuing
    local isStudying = studyId == catModel:getStudyingId()
    cellViewData.bg:setChecked(isStudying)
    cellViewData.readingStatue:setChecked(isStudying)
    cellViewData.timeIcon:setVisible(not isStudying)
    cellViewData.workingActionLayer:setVisible(isStudying)
    cellViewData.workingActionLayer:removeAllChildren()
    if isStudying then
        local studySpine = ui.spine({path = RES_DICT.STUDYING_SPINE, init = "play1", cache = SpineCacheName.CAT_HOUSE})
        cellViewData.workingActionLayer:addList(studySpine):alignTo(nil, ui.lb, {offsetX = 50, offsetY = -5})
    end
    
    -- update time
    local timeSeconds = checkint(studyConf.duration)
    if isStudying then
        timeSeconds = catModel:getStudyLeftSeconds()
    end
    cellViewData.timeLabel:updateLabel({text = CommonUtils.getTimeFormatByType(timeSeconds, 3)})
end


---@param catModel HouseCatModel
function CatModuleCatGrowView:updateWorkCellHandler(cellViewData, workId, isSelected, catModel)
    cellViewData.view:setTag(workId)
    cellViewData.selectedImg:setVisible(isSelected)

    local workConfs   = CONF.CAT_HOUSE.CAT_WORK:GetValue(workId)
    local careerId    = checkint(workConfs.careerId)
    local careerLevel = catModel:getCareerLevel(careerId)
    local careerConf  = CONF.CAT_HOUSE.CAT_CAREER_INFO:GetValue(careerId)[tostring(careerLevel)]
    if not careerConf then
        return
    end
    
    -- update title,name,starLvl,
    cellViewData.workPosLabel:updateLabel({text = careerConf.groupName, reqW = 400})
    cellViewData.workNameLabel:updateLabel({text = careerConf.name, reqW = 400})
    cellViewData.starIcon:setTexture(GetStarIconByCareerLevel(careerLevel))

    -- update loadingBar,exp
    local nextLevelConf = CONF.CAT_HOUSE.CAT_CAREER_LEVEL:GetValue(careerLevel + 1)
    local curLevelConf  = CONF.CAT_HOUSE.CAT_CAREER_LEVEL:GetValue(careerLevel)
    local isCanUp       = false
    if next(nextLevelConf) == nil then
        cellViewData.progress:setString("MAX")
        cellViewData.loadingBar:setValue(100)
    else
        local careerExp = catModel:getCareerExp(careerId)
        local totalExp  = checkint(nextLevelConf.exp)
        cellViewData.progress:setString(string.fmt("_num1_/_num2_", {_num1_ = careerExp, _num2_ = totalExp}))
        cellViewData.loadingBar:setValue(careerExp / totalExp * 100)
    end
    cellViewData.iconUp:setVisible(isCanUp)
    cellViewData.loadingLayer:setChecked(isCanUp)

    -- update damand
    local requireAbilityList = {}
    for abilityId, abilityValue in pairs(careerConf.requireAbility) do
        table.insert(requireAbilityList, {id = abilityId, value = abilityValue})
    end
    cellViewData.requireAbilityList = requireAbilityList
    cellViewData.damandTableView:resetCellCount(#requireAbilityList, true)
    cellViewData.damandTableView:setTouchable(cellViewData.damandTableView:isDragable())
    cellViewData.emptyTip:setVisible(#requireAbilityList <= 0)
    -- local damandIndex = 1
    -- for abilityId, abilityValue in pairs(careerConf.requireAbility) do
    --     if cellViewData.damandNodes[damandIndex] then
    --         cellViewData.damandNodes[damandIndex].refreshSelf(true, abilityId, abilityValue)
    --         cellViewData.damandNodes[damandIndex]:setVisible(true)
    --     end
    --     damandIndex = damandIndex + 1
    -- end
    -- for index = damandIndex, #cellViewData.damandNodes do
    --     cellViewData.damandNodes[index]:setVisible(false)
    -- end

    -- check is working
    local curLevelWorkConf = workConfs.careerLevel[tostring(careerLevel)]
    local isWorking = checkint(workConfs.id) == catModel:getWorkingId()
    cellViewData.bg:setChecked(isWorking)
    cellViewData.timeIcon:setVisible(not isWorking)
    cellViewData.workingActionLayer:setVisible(isWorking)
    cellViewData.workingActionLayer:removeAllChildren()
    if isWorking then
        local studySpine = ui.spine({path = RES_DICT.WORKING_SPINE, init = "play1", cache = SpineCacheName.CAT_HOUSE})
        cellViewData.workingActionLayer:addList(studySpine):alignTo(nil, ui.lb, {offsetX = 50, offsetY = -5})
    end
    
    -- update time
    local timeSeconds = checkint(curLevelWorkConf.duration)
    if isWorking then
        timeSeconds = catModel:getWorkLeftSeconds()
    end
    cellViewData.timeTitle:updateLabel({text = CommonUtils.getTimeFormatByType(timeSeconds, 3)})
end


---@param catModel HouseCatModel
function CatModuleCatGrowView:updateView(postgradutateId, postgradutateType, catModel)
    self:getViewData().studyDetailLayer:setVisible(postgradutateType == self.POSTGRADUATE_TYPE.STUDY and postgradutateId > 0)
    self:getViewData().taskDetailLayer:setVisible(postgradutateType == self.POSTGRADUATE_TYPE.WORK and postgradutateId > 0)

    if postgradutateType == self.POSTGRADUATE_TYPE.STUDY then
        self:updateStudyDetailPage(postgradutateId, catModel)
        for _, cellViewData in pairs(self:getViewData().studyTabView:getCellViewDataDict()) do
            cellViewData.selectedImg:setVisible(checkint(cellViewData.view:getTag()) == postgradutateId)
        end
    elseif postgradutateType == self.POSTGRADUATE_TYPE.WORK then
        self:updateWorkDetailPage(postgradutateId, catModel)
        for _, cellViewData in pairs(self:getViewData().workTabView:getCellViewDataDict()) do
            cellViewData.selectedImg:setVisible(checkint(cellViewData.view:getTag()) == postgradutateId)
        end
    end
end


---@param catModel HouseCatModel
function CatModuleCatGrowView:updateStudyDetailPage(studyId, catModel)
    -- update time
    local studyConf = CONF.CAT_HOUSE.CAT_STUDY:GetValue(studyId)
    if next(studyConf) == nil then
        return
    end
    self:getViewData().studyDetailTimeLabel:updateLabel({text = CommonUtils.getTimeFormatByType(checkint(studyConf.duration), 3)})

    -- update damand
    -- local abilityIndex = 1
    -- for abilityId, abilityValue in pairs(studyConf.consumeAttr) do
    --     if self:getViewData().studyDetailDamandNodes[abilityIndex] then
    --         self:getViewData().studyDetailDamandNodes[abilityIndex].refreshSelf(true, abilityId, abilityValue)
    --         self:getViewData().studyDetailDamandNodes[abilityIndex]:setVisible(true)
    --     end
    --     abilityIndex = abilityIndex + 1
    -- end
    -- for index = abilityIndex, #self:getViewData().studyDetailDamandNodes do
    --     self:getViewData().studyDetailDamandNodes[index]:setVisible(false)
    -- end
    local consumeAttrList = {}
    for attrId, attrValue in pairs(studyConf.consumeAttr) do
        table.insert(consumeAttrList, {id = attrId, value = attrValue})
    end
    self:getViewData().studyDamandTableView:setCountOfCell(#consumeAttrList)
    self:getViewData().studyDamandTableView:setCellUpdateHandler(function(cellIndex, cellViewData)
        local attrData = consumeAttrList[cellIndex]
        self:updateDamandNode(cellViewData, {isAttr = true, damandId = attrData.id, value = attrData.value})
    end)
    self:getViewData().studyDamandTableView:setTouchable(self:getViewData().studyDamandTableView:isDragable())

    -- update cost
    self:updateStudyCostLabel(studyId, catModel)

    -- check is can work
    self:updateStudyLeftTime(catModel)
end
function CatModuleCatGrowView:updateStudyLeftTime(catModel)
    local leftStudyNum = catModel:getLeftActionTimes()
    local maxStudyNum  = CatHouseUtils.CAT_PARAM_FUNCS.MAX_ACTION_TIMES()
    display.reloadRichLabel(self:getViewData().studyLeftTime, {c = {
        fontWithColor('9',{color = "#a88b72", text = __("今日深造次数:")}),
        fontWithColor('9',{color = "#c02b13", text = string.fmt("_num1_/_num2_", {_num1_ = leftStudyNum, _num2_ = maxStudyNum})}),
    }})
    self:getViewData().studyBtn:setEnabled(leftStudyNum > 0 and catModel:getStudyingId() <= 0 and catModel:isUnlockStudy())
end
function CatModuleCatGrowView:updateStudyCostLabel(studyId, catModel)
    local costLabelList = {}
    local contentW      = 0
    self:getViewData().costRichLayer:removeAllChildren()
    for _, goodsData in ipairs(CatHouseUtils.GetCatStudyConsume(studyId, catModel)) do
        local text = ui.label({fnt = FONT.D14, text = string.fmt("_num1_/_num2_", {_num1_ = goodsData.num, _num2_ = app.goodsMgr:GetGoodsAmountByGoodsId(goodsData.goodsId)})})
        table.insert(costLabelList, text)

        local imgScale = 0.4
        local image    = ui.image({img = CommonUtils.GetGoodsIconPathById(goodsData.goodsId), scale = imgScale})
        table.insert(costLabelList, image)
        contentW = display.getLabelContentSize(text).width + image:getContentSize().width * imgScale
    end
    self:getViewData().costRichBg:setVisible(#costLabelList > 0)
    if #costLabelList > 0 then
        self:getViewData().costRichBg:setContentSize(cc.size(contentW + 20, 30))
        self:getViewData().costRichLayer:setContentSize(cc.size(contentW + 20, 30))
        self:getViewData().costRichLayer:addList(costLabelList)
        ui.flowLayout(cc.sizep(self:getViewData().costRichLayer, ui.cc), costLabelList, {type = ui.flowH, ap = ui.cc})
    end
end


---@param catModel HouseCatModel
function CatModuleCatGrowView:updateWorkDetailPage(workId, catModel)
    -- update base goods
    local workConfs = CONF.CAT_HOUSE.CAT_WORK:GetValue(workId)
    if next(workConfs) == nil then
        return
    end
    
    local careerId    = checkint(workConfs.careerId)
    local careerLevel = catModel:getCareerLevel(careerId)
    local workConf    = workConfs.careerLevel[tostring(careerLevel)]
    if not workConf or next(workConf) == nil then
        return
    end
    self:getViewData().taskGoodNode:RefreshSelf({goodsId = workConfs.rewardGoodsId, num = workConf.rewardNum})

    -- update damand
    -- local damandIndex = 1
    -- for attrId, attrValue in pairs(workConf.consumeAttr) do
    --     if self:getViewData().workDetailDamandNodes[damandIndex] then
    --         self:getViewData().workDetailDamandNodes[damandIndex].refreshSelf(true, attrId, attrValue)
    --         self:getViewData().workDetailDamandNodes[damandIndex]:setVisible(true)
    --     end
    --     damandIndex = damandIndex + 1
    -- end
    -- for index = damandIndex, #self:getViewData().studyDetailDamandNodes do
    --     self:getViewData().workDetailDamandNodes[index]:setVisible(false)
    -- end
    local consumeAttrList = {}
    for attrId, attrValue in pairs(workConf.consumeAttr) do
        table.insert(consumeAttrList, {id = attrId, value = attrValue})
    end
    self:getViewData().taskDamandTableView:setCellUpdateHandler(function(cellIndex, cellViewData)
        local attrData = consumeAttrList[cellIndex]
        self:updateDamandNode(cellViewData, {isAttr = true, damandId = attrData.id, value = attrData.value})
    end)
    self:getViewData().taskDamandTableView:resetCellCount(#consumeAttrList, true)
    self:getViewData().taskDamandTableView:setTouchable(self:getViewData().taskDamandTableView:isDragable())

    -- update time
    self:getViewData().taskDetailTimeLabel:updateLabel({text = CommonUtils.getTimeFormatByType(checkint(workConf.duration), 3)})

    -- check can promote
    local careerExp     = catModel:getCareerExp(careerId)
    local nextLevelConf = CONF.CAT_HOUSE.CAT_CAREER_LEVEL:GetValue(careerLevel + 1)

    local isCanUp       = false
    if next(nextLevelConf) ~= nil then
        isCanUp = careerExp >= checkint(nextLevelConf.exp)
    end
    self:getViewData().promoBtn:setEnabled(isCanUp and catModel:getWorkingId() ~= checkint(workId))

    -- check can work
    self:updateWorkLeftTime(catModel)
end
---@param catModel HouseCatModel
function CatModuleCatGrowView:updateWorkLeftTime(catModel)
    local leftWorkNum = catModel:getLeftActionTimes()
    local maxWorkNum  = CatHouseUtils.CAT_PARAM_FUNCS.MAX_ACTION_TIMES()
    self:getViewData().workingTimes:setString(string.fmt("_num1_/_num2_", {_num1_ = leftWorkNum, _num2_ = maxWorkNum}))
    self:getViewData().workingBtn:setEnabled(leftWorkNum > 0 and catModel:getWorkingId() <= 0 and catModel:isUnlockWork()) 
end
-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------
function CatModuleCatGrowView.CreateDamandNode(parent)
    local view = ui.layer({size = cc.size(130, 80), color = cc.r4b(0)})
    parent:addList(view):alignTo(nil, ui.cc)

    local bg   = ui.image({img = RES_DICT.VALUE_BG})
    view:addList(bg):alignTo(nil, ui.rb)

    local attrPath    = CatHouseUtils.GetCatAttrTypeIconPath(101)
    local icon        = ui.image({img = attrPath})
    view:addList(icon):alignTo(nil, ui.lb)

    local value  = ui.label({fnt = FONT.D14, text = "--"})
    view:addList(value):alignTo(bg, ui.cc)
    return {
        view  = view,
        icon  = icon,
        value = value,
    }
end


function CatModuleCatGrowView.CreateTaskCell(cellParent)
    local size    = cellParent:getContentSize()
    local bgFrame = cellParent:addList({
        ui.layer{size = size, color = cc.r4b(0), enable = true},
        ui.layer{size = size}
    })
    local view = bgFrame[2]

    local bg = ui.tButton({n = RES_DICT.BTN_TASK_N, s = RES_DICT.BTN_TASK_S})
    view:addList(bg):alignTo(nil, ui.cc)
    bg:setTouchEnabled(false)

    local selectedImg = ui.image({img = RES_DICT.SELECTED_IMG, scale9 = true, size = size})
    selectedImg:setVisible(false)
    bg:addList(selectedImg):alignTo(nil, ui.cc)

    view.updateSelectedStatue = function(visible)
        selectedImg:setVisible(visible)
    end

    local infoGroup = view:addList({
        ui.label({fnt = FONT.D4, color = "#fcf0e5", text = "--", mt = 12, ml = 25, ap = ui.lc}),
        ui.tButton({n = RES_DICT.BG_DESCR_N, s = RES_DICT.BG_DESCR_S}),
        ui.label({fnt = FONT.D4, color = "#683320", text = __("岗位要求")}),
        ui.layer({size = cc.size(510, 95)}),
        ui.title({n = RES_DICT.BG_TIME}):updateLabel({fnt = FONT.D4, color = "#998467", text = "--", ap = ui.rc, offset = cc.p(240, 0)})
    })
    ui.flowLayout(cc.rep(cc.sizep(view, ui.lt), 12, 0), infoGroup, {type = ui.flowV, ap = ui.lb})

    local needLabel = infoGroup[3]
    needLabel:setAnchorPoint(ui.cc)
    needLabel:setPositionX(size.width * 0.5)

    -- 星星图标
    local starIcon = ui.image({img = GetStarIconByCareerLevel(1)})
    view:addList(starIcon):alignTo(nil, ui.rt, {offsetX = -30})

    -- 工作名 进度条，进度
    local loadingLayer = infoGroup[2]
    local taskName = ui.label({fnt = FONT.D4, color = "#683320", text = "--", ap = ui.lc})
    loadingLayer:addList(taskName):alignTo(nil, ui.lt, {offsetX = 25, offsetY = -1})
    loadingLayer:setTouchEnabled(false)

    local loadingBar = ui.pBar({bg = RES_DICT.PRO_BG, img = RES_DICT.PRO_IMG})
    loadingLayer:addList(loadingBar):alignTo(nil, ui.lb, {offsetX = 25, offsetY = 3})

    local progress = ui.label({fnt = FONT.D4, fontSize = 18, color = "#865b35", text = "--", ap = ui.lc})
    loadingLayer:addList(progress):alignTo(loadingBar, ui.rc, {offsetX = 10})

    -- 晋升按钮
    local iconUp = ui.image({img = RES_DICT.BG_UP})
    loadingLayer:addList(iconUp):alignTo(nil, ui.lc, {offsetX = -10})

    -- 工作剩余时间 工作中动画
    local timeTitle = infoGroup[5]
    local timeIcon = ui.image({img = RES_DICT.GOODS_TIME_ICON})
    timeTitle:addList(timeIcon):alignTo(nil, ui.lc, {offsetX = 25})

    local workingActionLayer = ui.layer({size = timeTitle:getContentSize()})
    timeTitle:addList(workingActionLayer)

    -- damand layer
    local damandLayer     = infoGroup[4]
    local damandTableView = ui.tableView({size = cc.resize(damandLayer:getContentSize(), -10, 0), csizeW = 130, dir = display.SDIR_H})
    damandLayer:addList(damandTableView):alignTo(nil, ui.cc)
    damandTableView:setCellCreateHandler(CatModuleCatGrowView.CreateDamandNode)

    local emptyTip     = ui.label({fnt = FONT.D14, color = "#ffffff", text = __("无工作能力需求"), reqW = damandLayer:getContentSize().width - 20})
    damandLayer:addList(emptyTip):alignTo(nil, ui.cc)
    -- local damandNodes = {}
    -- for i = 1, 2 do
    --     local damandNode = CatModuleCatGrowView.CreateDamandNode()
    --     damandLayer:add(damandNode)
    --     table.insert(damandNodes, damandNode)
    -- end
    ui.flowLayout(cc.sizep(damandLayer, ui.cc), damandNodes, {type = ui.flowH, ap = ui.cc, gapW = 50})

    return {
        view               = bgFrame[1],
        bg                 = bg,
        workPosLabel       = infoGroup[1],
        iconUp             = iconUp,
        loadingBar         = loadingBar,
        progress           = progress,
        workNameLabel      = taskName,
        timeTitle          = timeTitle,
        timeIcon           = timeIcon,
        workingActionLayer = workingActionLayer,
        selectedImg        = selectedImg,
        damandTableView    = damandTableView,
        loadingLayer       = loadingLayer,
        starIcon           = starIcon,
        damandLayer        = damandLayer,
        emptyTip           = emptyTip,
    }
end


function CatModuleCatGrowView.CreateStudyCell(cellParent)
    local size = cellParent:getContentSize()
    local bgFrame = cellParent:addList({
        ui.layer{size = size, color = cc.r4b(0), enable = true},
        ui.layer{size = size}
    })
    local view = bgFrame[2]
    -- local view = ui.layer({size = size, color = cc.r4b(0), enable = true})
    -- cellParent:addList(view):alignTo(nil, ui.cc)

    local bg = ui.tButton({n = RES_DICT.BTN_STUDY_N, s = RES_DICT.BTN_STUDY_S})
    view:addList(bg):alignTo(nil, ui.cc)
    bg:setTouchEnabled(false)

    -- selected img
    local selectedImg = ui.image({img = RES_DICT.SELECTED_IMG, scale9 = true, size = cc.resize(size, -10, 0)})
    selectedImg:setVisible(false)
    view:addList(selectedImg, 10):alignTo(nil, ui.cc)

    view.updateSelectedStatue = function(visible)
        selectedImg:setVisible(visible)
    end

    -- title / descr / demand layer / timedescr
    local infoGroup = view:addList({
        ui.label({fnt = FONT.D4, color = "#fcf0e5", text = "--", mt = 15, ml = 30, ap = ui.lc}),
        ui.label({fnt = FONT.D4, color = "#683320", text = __("学习需求:"), mt = 20, ml = 30}),
        ui.layer({bg = RES_DICT.BG_STUDY_NEED, ml = 25}),
        ui.title({n = RES_DICT.BG_TIME, mt = 25}):updateLabel({fnt = FONT.D4, color = "#998457", text = "--", ap = ui.rc, offset = cc.p(240, 0)}),
    })
    ui.flowLayout(cc.rep(cc.sizep(view, ui.lt), 12, 0), infoGroup, {type = ui.flowV, ap = ui.lb})

    -- damand layer
    local damandLayer  = infoGroup[3]
    local emptyTip     = ui.label({fnt = FONT.D14, color = "#ffffff", text = __("暂无学习需求"), reqW = damandLayer:getContentSize().width - 20})
    damandLayer:addList(emptyTip):alignTo(nil, ui.cc)
    local damandTableView = ui.tableView({size = cc.resize(damandLayer:getContentSize(), -10, 0), csizeW = 130, dir = display.SDIR_H})
    damandLayer:addList(damandTableView):alignTo(nil, ui.cc)
    damandTableView:setCellCreateHandler(CatModuleCatGrowView.CreateDamandNode)
    -- local abilityNodes = {}
    -- for i = 1, 2 do
    --     local abilityNode = CatModuleCatGrowView.CreateDamandNode()
    --     damandLayer:add(abilityNode)
    --     table.insert(abilityNodes, abilityNode)
    -- end
    -- ui.flowLayout(cc.sizep(damandLayer, ui.lc), abilityNodes, {type = ui.flowH, ap = ui.lc})

    -- time icon
    local timeTitle = infoGroup[4]
    local timeIcon = ui.image({img = RES_DICT.GOODS_TIME_ICON})
    timeTitle:addList(timeIcon):alignTo(nil, ui.lc, {offsetX = 30})

    -- doing action
    local workingActionLayer = ui.layer({size = timeTitle:getContentSize()})
    timeTitle:addList(workingActionLayer)

    -- is doing icon
    local readingStatue = ui.tButton({n = RES_DICT.STUDY_N, s = RES_DICT.STUDY_S})
    view:addList(readingStatue):alignTo(nil, ui.rc, {offsetX = -20})
    readingStatue:setTouchEnabled(false)

    return {
        view               = bgFrame[1],
        bg                 = bg,
        titleLabel         = infoGroup[1],
        descrLabel         = infoGroup[2],
        timeLabel          = timeTitle,
        timeIcon           = timeIcon,
        workingActionLayer = workingActionLayer,
        selectedImg        = selectedImg,
        readingStatue      = readingStatue,
        damandTableView    = damandTableView,
        damandLayer        = damandLayer,
        emptyTip           = emptyTip,
    }
end


function CatModuleCatGrowView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- blockLayer | centerLayer | taskDetail | study detail
    local frameGroup = view:addList({
        ui.layer({color = cc.c4b(0, 0, 0, 130), enable = true}),
        ui.layer(),
        ui.layer(),
        ui.layer(),
    })

    ------------------------------------------------- [centerLayer]
    local centerLayer    = frameGroup[2]
    local taskLayer      = ui.layer({bg = RES_DICT.BG_TASK, scale9 = true, size = cc.size(550, 750)})
    local taskLayerSize  = taskLayer:getContentSize()
    local taskFrameGroup = centerLayer:addList({
        ui.layer({size = taskLayerSize, color = cc.r4b(0), enable = true}),
        taskLayer,
    })
    ui.flowLayout(cc.rep(cc.sizep(centerLayer, ui.rc), -display.SAFE_L, 0), taskFrameGroup, {type = ui.flowC, ap = ui.rc})

    local workTabView = ui.tableView({dir = display.SDIR_V, csizeH = 251, size = cc.resize(taskLayerSize, -20, -100)})
    taskLayer:addList(workTabView):alignTo(nil, ui.cc, {offsetY = 10})
    workTabView:setCellCreateHandler(CatModuleCatGrowView.CreateTaskCell)

    local studyTabView = ui.tableView({dir = display.SDIR_V, csizeH = 251, size = cc.resize(taskLayerSize, -20, -100)})
    taskLayer:addList(studyTabView):alignTo(nil, ui.cc, {offsetY = 10})
    studyTabView:setCellCreateHandler(CatModuleCatGrowView.CreateStudyCell)

    --------------------------------------------------[postgradutate btns]
    local POSTGRADUATE_BTN_SIZE     = cc.size(120, 130 * #ACTION_DEFINE - 10)
    local postgraduateBtnFrameGroup = centerLayer:addList({
        ui.layer({size = POSTGRADUATE_BTN_SIZE, enable = true, color = cc.r4b(0)}),
        ui.layer({size = POSTGRADUATE_BTN_SIZE}),
    })
    ui.flowLayout(cc.rep(cc.sizep(centerLayer, ui.lt), display.SAFE_L, -50), postgraduateBtnFrameGroup, {type = ui.flowC, ap = ui.lt})

    local postgraduateBtnLayer = postgraduateBtnFrameGroup[2]
    local postgraduateBtnGroup = {}
    local postGraduateBtnMaps  = {}
    for btnTag, btnDefine in ipairs(ACTION_DEFINE) do
        local postgraduateBtn = CatModuleCatGrowView.CreatePostgraduateBtn(btnDefine, btnTag)
        table.insert(postgraduateBtnGroup, postgraduateBtn)
        postGraduateBtnMaps[btnTag] = postgraduateBtn
    end
    postgraduateBtnLayer:addList(postgraduateBtnGroup)
    ui.flowLayout(cc.sizep(postgraduateBtnLayer, ui.cc), postgraduateBtnGroup, {type = ui.flowV, ap = ui.cc, gapH = 10})

    ------------------------------------------------- [taskDetail Layer]
    local taskDetailLayer    = frameGroup[3]
    local workDetailViewData = CatModuleCatGrowView.CreateWorkDetailView()
    taskDetailLayer:addList(workDetailViewData.view):alignTo(nil, ui.rc, {offsetX = -taskLayerSize.width - display.SAFE_L})

    ------------------------------------------------- [study detail Layer]
    local studyDetailLayer    = frameGroup[4]
    local studyDetailViewData = CatModuleCatGrowView.CreateStudyDetailView()
    studyDetailLayer:addList(studyDetailViewData.view):alignTo(nil, ui.rc, {offsetX = -taskLayerSize.width - display.SAFE_L})
    

    return {
        view                   = view,
        blockLayer             = frameGroup[1],
        workTabView            = workTabView,
        studyTabView           = studyTabView,
        postGraduateBtnMaps    = postGraduateBtnMaps,
        studyDetailLayer       = studyDetailLayer,
        studyDamandTableView   = studyDetailViewData.studyDamandTableView,
        studyDetailDamandLayer = studyDetailViewData.studyDetailDamandLayer,
        studyDetailTimeLabel   = studyDetailViewData.studyDetailTimeLabel,
        studyBtn               = studyDetailViewData.studyBtn,
        studyLeftTime          = studyDetailViewData.studyLeftTime,
        costRichBg             = studyDetailViewData.costRichBg,
        costRichLayer          = studyDetailViewData.costRichLayer,
        taskDetailLayer        = taskDetailLayer,
        taskGoodNode           = workDetailViewData.taskGoodNode,
        taskDetailTimeLabel    = workDetailViewData.taskDetailTimeLabel,
        taskDamandTableView    = workDetailViewData.taskDamandTableView,
        workDetailDamandLayer  = workDetailViewData.workDetailDamandLayer,
        promoBtn               = workDetailViewData.promoBtn,
        workingBtn             = workDetailViewData.workingBtn,
        workingTimes           = workDetailViewData.workingTimes,
    }
end


function CatModuleCatGrowView.CreatePostgraduateBtn(btnDefine, btnTag)
    local postgraduateBtn = ui.tButton({n = RES_DICT.BTN_ACTION_N, s = RES_DICT.BTN_ACTION_S})
    postgraduateBtn:setTag(btnTag)
        
    -- selected img
    local selectedImg = ui.image({img = RES_DICT.BTN_ACTION_L})
    selectedImg:setVisible(false)
    postgraduateBtn:addList(selectedImg):alignTo(nil, ui.cc)

    -- icon
    local icon = ui.image({img = btnDefine.img, scale = 0.8})
    postgraduateBtn:addList(icon):alignTo(nil, ui.cc)

    -- title
    local btnDesc = ui.label({fnt = FONT.D14, outline = "#50262b", text = btnDefine.title, reqW = 120})
    postgraduateBtn:addList(btnDesc):alignTo(nil, ui.cb, {offsetY = 10})

    postgraduateBtn.setSelectedState = function(visible)
        selectedImg:setVisible(visible)
        postgraduateBtn:setChecked(visible)
    end

    return postgraduateBtn
end


function CatModuleCatGrowView.CreateStudyDetailView()
    local studyBgLayer     = ui.layer({bg = RES_DICT.FRAME_DETAIL})
    local studyLayerSize   = studyBgLayer:getContentSize()

    local view = ui.layer({size = studyLayerSize})
    local studyFrameGroup  = view:addList({
        ui.layer({size = studyLayerSize, enable = true, color = cc.r4b(0)}),
        studyBgLayer,
        ui.layer({bg = RES_DICT.BG_STUDY_DETAIL, ml = 5, scale9 = true, size = cc.size(370, 529), mt = 20}),
    })
    ui.flowLayout(cc.sizep(view, ui.cc), studyFrameGroup, {type = ui.flowC, ap = ui.cc})

    local studyLayer = studyFrameGroup[3]
    local studyInfoGroup = studyLayer:addList({
        ui.title({n = RES_DICT.COMMON_TITLE_5, mt = -70}):updateLabel({fnt = FONT.D4, text = __("所需消耗"), paddingW = 40}),
        ui.label({fnt = FONT.D4, text = __("学习耗时"), mt = 60}),
        ui.title({n = RES_DICT.DESCR_BG, scale9 = true, size = cc.size(370, 50), cut = cc.dir(5, 5, 5, 5)}):updateLabel({fnt = FONT.D14, text = "--", ap = ui.lc, offset = cc.p(-170, 0)}),
        ui.label({fnt = FONT.D4, text = __("学习消耗"), mt = 60}),
        ui.layer({bg = RES_DICT.DESCR_BG, size = cc.size(370, 100), scale9 = true}),
        ui.rLabel({r = true, c = {{text = __("今日深造次数:"), fnt = FONT.D4}}, mt = 100}),
        ui.button({n = RES_DICT.CONFIRM_BTN, d = RES_DICT.DISABLE_BTN}):updateLabel({fnt = FONT.D14, text = __("学习"), reqW = 110}),
        ui.image({img = RES_DICT.COST_BG, scale9 = true, mt = 30}),
    })
    ui.flowLayout(cc.sizep(studyLayer, ui.ct), studyInfoGroup, {type = ui.flowV, ap = ui.cb})

    studyInfoGroup[2]:setAnchorPoint(ui.lc)
    studyInfoGroup[2]:setPositionX(10)
    studyInfoGroup[4]:setAnchorPoint(ui.lc)
    studyInfoGroup[4]:setPositionX(10)

    local costRichBg = studyInfoGroup[8]
    local costRichLayer = ui.layer({size = costRichBg:getContentSize()})
    costRichLayer:setName("textLayer")
    costRichBg:addList(costRichLayer)

    -- damand layer
    local studyDetailDamandLayer  = studyInfoGroup[5]
    local studyDamandTableView    = ui.tableView({size = cc.resize(studyDetailDamandLayer:getContentSize(), -10, 0), csizeW = 130, dir = display.SDIR_H})
    studyDetailDamandLayer:addList(studyDamandTableView):alignTo(nil, ui.cc)
    studyDamandTableView:setCellCreateHandler(CatModuleCatGrowView.CreateDamandNode)
    -- local studyDetailDamandNodes = {}
    -- for i = 1, 2 do
    --     local damandNode = CatModuleCatGrowView.CreateDamandNode()
    --     studyDetailDamandLayer:add(damandNode)
    --     table.insert(studyDetailDamandNodes, damandNode)
    -- end
    -- ui.flowLayout(cc.sizep(studyDetailDamandLayer, ui.cc), studyDetailDamandNodes, {type = ui.flowH, ap = ui.cc})

    return {
        studyDetailDamandLayer = studyDetailDamandLayer,
        studyDamandTableView   = studyDamandTableView,
        studyDetailTimeLabel   = studyInfoGroup[3],
        studyBtn               = studyInfoGroup[7],
        studyLeftTime          = studyInfoGroup[6],
        costRichBg             = costRichBg,
        costRichLayer          = costRichLayer,
        view                   = view,
    }
end


function CatModuleCatGrowView.CreateWorkDetailView()
    local taskDetailBgLayer    = ui.layer({bg = RES_DICT.BG_TASK_DETAIL, size = cc.size(400, 720), scale9 = true})
    local taskDetailLayerSize  = taskDetailBgLayer:getContentSize()

    local view = ui.layer({size = taskDetailLayerSize})
    local taskDetailFrameGroup = view:addList({
        ui.layer({size = taskDetailLayerSize, color = cc.r4b(0), enable = true}),
        taskDetailBgLayer,
        ui.layer({bg = RES_DICT.BG_GOOD, scale9 = true, size = cc.size(380, 300), mt = -170, ml = 3}),
        ui.layer({size = taskDetailLayerSize})
    })
    ui.flowLayout(cc.sizep(view, ui.cc), taskDetailFrameGroup, {type = ui.flowC, ap = ui.cc})

    local taskDetailInfoLayer = taskDetailFrameGroup[4]
    local taskDetailInfoGroup = taskDetailInfoLayer:addList({
        ui.title({n = RES_DICT.BG_TIP}):updateLabel({fnt = FONT.D9, color = "#DDBC89", text = __("有几率带回杂物"), reqW = 240}),
        ui.title({n = RES_DICT.COMMON_TITLE_5}):updateLabel({fnt = FONT.D4, text = __("基础奖励"), paddingW = 40}),
        ui.layer({size = cc.size(360, 100)}),
        ui.title({n = RES_DICT.COMMON_TITLE_5, mt = 40}):updateLabel({fnt = FONT.D4, text = __("需要消耗"), paddingW = 40}),
        ui.label({fnt = FONT.D4, text = __("工作耗时"), mt = 20}),
        ui.title({n = RES_DICT.DESCR_BG, scale9 = true, size = cc.size(370, 50), cut = cc.dir(5, 5, 5, 5)}):updateLabel({fnt = FONT.D14, text = "--", ap = ui.lc, offset = cc.p(-170, 0)}),
        ui.label({fnt = FONT.D4, text = __("工作消耗"), mt = 20}),
        ui.layer({bg = RES_DICT.DESCR_BG, size = cc.size(370, 100), scale9 = true}),
        ui.layer({size = cc.size(380, 80), mt = 70}),
    })
    ui.flowLayout(cc.rep(cc.sizep(taskDetailInfoLayer, ui.ct), 0, 0), taskDetailInfoGroup, {type = ui.flowV, ap = ui.cb})

    local taskDetailBtnLayer = taskDetailInfoGroup[9]
    local taskDetailBtnGroup = taskDetailBtnLayer:addList({
        ui.button({n = RES_DICT.CANCEL_BTN, d = RES_DICT.DISABLE_BTN}):updateLabel({fnt = FONT.D14, text = __("升职"), reqW = 110}),
        ui.button({n = RES_DICT.CONFIRM_BTN, d = RES_DICT.DISABLE_BTN}):updateLabel({fnt = FONT.D14, text = __("打工"), reqW = 110})
    })
    ui.flowLayout(cc.sizep(taskDetailBtnLayer, ui.cc), taskDetailBtnGroup, {type = ui.flowH, ap = ui.cc, gapW = 80})

    -- goods layer
    local taskGoodLayer = taskDetailInfoGroup[3]
    local taskGoodNode  = ui.goodsNode({defaultCB = true, showAmount = true, scale = 0.75})
    taskGoodLayer:addList(taskGoodNode):alignTo(nil, ui.cc)

    -- damand layer
    local taskDetailDamandLayer  = taskDetailInfoGroup[8]
    local taskDamandTableView    = ui.tableView({size = cc.resize(taskDetailDamandLayer:getContentSize(), -10, 0), csizeW = 130, dir = display.SDIR_H})
    taskDetailDamandLayer:addList(taskDamandTableView):alignTo(nil, ui.cc)
    taskDamandTableView:setCellCreateHandler(CatModuleCatGrowView.CreateDamandNode)
    -- local workDetailDamandNodes = {}
    -- for i = 1, 3 do
    --     local damandNode = CatModuleCatGrowView.CreateDamandNode()
    --     taskDetailDamandLayer:add(damandNode)
    --     table.insert(workDetailDamandNodes, damandNode)
    -- end
    -- ui.flowLayout(cc.sizep(taskDetailDamandLayer, ui.cc), workDetailDamandNodes, {type = ui.flowH, ap = ui.cc, gapW = -13})


    taskDetailInfoGroup[5]:setAnchorPoint(ui.lc)
    taskDetailInfoGroup[5]:setPositionX(30)
    taskDetailInfoGroup[7]:setAnchorPoint(ui.lc)
    taskDetailInfoGroup[7]:setPositionX(30)

    local workingTipGroup = taskDetailInfoLayer:addList({
        ui.label({fnt = FONT.D9, color = "#a88b72", text = __("今日深造次数"), reqW = 200}),
        ui.label({fnt = FONT.D9, color = "#c02b13", text = "--"}),
    })
    ui.flowLayout(cc.rep(cc.sizep(taskDetailInfoLayer, ui.cb), 100, 80), workingTipGroup, {type = ui.flowV, ap = ui.cb})

    return {
        taskGoodNode           = taskGoodNode,
        taskDetailTimeLabel    = taskDetailInfoGroup[6],
        workDetailDamandLayer  = taskDetailDamandLayer,
        taskDamandTableView    = taskDamandTableView,
        promoBtn               = taskDetailBtnGroup[1],
        workingBtn             = taskDetailBtnGroup[2],
        workingTimes           = workingTipGroup[2],
        view                   = view,
    }
end


return CatModuleCatGrowView
