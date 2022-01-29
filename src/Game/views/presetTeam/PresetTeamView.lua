--- 预设编队视图
---@class PresetTeamView
local PresetTeamView = class('PresetTeamView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.presetTeam.PresetTeamView'
    node:enableNodeEvents()
    return node
end)

------------ import ------------
---@type CardHeadNode
local PresetTeamCell = require('Game.views.presetTeam.PresetTeamCell')
------------ import ------------

------------ define ------------
local app = app
local display = display
local _res = _res
local cc = cc
local CreateView       = nil
local CreateCell = nil
local CreateTabCell    = nil

local RES_DICT = {
    PRESETTEAM_TAB_DEFAULT = _res("ui/presetTeam/presetteam_tab_default.png"),
    PRESETTEAM_TAB_SELECT_FRAME = _res("ui/presetTeam/presetteam_tab_select_frame.png"),
    PRESETTEAM_TAB_SELECT = _res("ui/presetTeam/presetteam_tab_select.png"),
    COMMON_BTN_TIPS = _res('ui/common/common_btn_tips.png')
}

---@type PRESET_TEAM_TYPE
local PRESET_TEAM_TYPE = PRESET_TEAM_TYPE

------------ define ------------


function PresetTeamView:ctor( ... )
    self.args = unpack({...}) or {}
    self:InitUI()
end
--[[
init ui
--]]
function PresetTeamView:InitUI()
    xTry(function ( )
        local args = self.args
        self.viewData_ = CreateView(args.isEditMode, args.isSelectMode, args.moduleTypes)
        self:addChild(self.viewData_.view)
    end, __G__TRACKBACK__)
end

CreateView = function (isEditMode, isSelectMode, moduleTypes)
    local view = display.newLayer()

    local shadowsLayer = display.newLayer(0, 0, {enable = true, color = cc.c4b( 0, 0, 0, 130)})
    view:addChild(shadowsLayer)
    
    local tabBtnCells = {}
    local tipsBtn
    if not (isEditMode or isSelectMode) then
        local tabCellSize = cc.size(185, 69)
        local startPosX = display.cx - 40
        local startPosY = display.cy + 279
        local moduleConf = CommonUtils.GetGameModuleConf()

        local moduleCount = #moduleTypes
        for i = 1, moduleCount do
            local conf = moduleConf[tostring(moduleTypes[i])] or {}
            local tabCellViewData = CreateTabCell(tabCellSize, tostring(conf.descr))
            local tabBtnCell = tabCellViewData.tabBtnCell
            local cellSize = tabBtnCell:getContentSize()
            local params = {index = i, goodNodeSize = cellSize, midPointX = startPosX, midPointY =  startPosY, col = moduleCount, maxCol = moduleCount, scale = 1, goodGap = 10}
            local pos = CommonUtils.getGoodPos(params)
            display.commonUIParams(tabBtnCell, {ap = cc.p(0.5, 0), po = pos})
            view:addChild(tabBtnCell)

            table.insert(tabBtnCells, tabCellViewData)
        end

        local tabBtnCellViewData = tabBtnCells[1]
        local tipsBtnPosX, tipsBtnPosY = startPosX, startPosY
        if tabBtnCellViewData then
            local tabBtnCell = tabBtnCellViewData.tabBtnCell
            tipsBtnPosX, tipsBtnPosY = tabBtnCell:getPositionX() - tabCellSize.width * 0.5 - 30, tabBtnCell:getPositionY() + tabCellSize.height * 0.5
        end
        tipsBtn = display.newButton(tipsBtnPosX, tipsBtnPosY, {n = RES_DICT.COMMON_BTN_TIPS})
        view:addChild(tipsBtn)

        --for i, moduleType in ipairs(moduleTypes) do
        --    local conf = moduleConf[moduleType]
        --    local tabCellViewData = CreateTabCell(tabCellSize, conf.descr)
        --    local tabBtnCell = tabCellViewData.tabBtnCell
        --    local params = {index = i, goodNodeSize = orderCell:getContentSize(), midPointX = bgSize.width / 2, midPointY =  bgSize.height * 0.87, col = 4, maxCol = 4, scale = 1, goodGap = 6}
        --    CommonUtils.getGoodPos(params)
        --    display.commonUIParams(tabBtnCell, {ap = cc.p(0, 0), po = cc.p(startPosX + (i - 1) * 200, startPosY)})
        --    view:addChild(tabBtnCell)
        --
        --    table.insert(tabBtnCells, tabCellViewData)
        --end
    end

    

    return {
        view        = view,
        shadowsLayer = shadowsLayer,
        tabBtnCells = tabBtnCells,
        tipsBtn = tipsBtn,

        tableViews = {},
    }
end

CreateTabCell = function (size, name)
    local tabBtnCell = display.newLayer(0, 0, {ap = cc.p(0.5, 0), size = size})
    
    local tabBtn = display.newButton(92.5, 6.5, {ap = cc.p(0.5, 0), n = RES_DICT.PRESETTEAM_TAB_DEFAULT, scale9 = true, size = cc.size(173, 56)})
    display.commonLabelParams(tabBtn, {fontSize = 24, color = "#763200", text = name})
    tabBtnCell:addChild(tabBtn) 
    
    local frameImg = display.newImageView(RES_DICT.PRESETTEAM_TAB_SELECT_FRAME, 92.5, 0, {ap = cc.p(0.5, 0)})
    frameImg:setVisible(false)
    tabBtnCell:addChild(frameImg)

    return {
        tabBtnCell = tabBtnCell,
        tabBtn = tabBtn,
        frameImg = frameImg,
    }
end

CreateCell = function(cellParent, presetTeamType, isEditMode, isSelectMode)
    local view = cellParent
    local size = cellParent:getContentSize()

    local cell = PresetTeamCell.new({presetTeamType = presetTeamType, isEditMode = isEditMode, isSelectMode = isSelectMode})
    display.commonUIParams(cell, {ap = display.CENTER, po = cc.p(size.width * 0.5, size.height * 0.5)})
    view:addChild(cell)

    return {
        view = view,
        cell = cell
    }
end

---CreateTableViewByType
---根据预设编队类型创建 table view
---@param presetTeamType table 预设编队类型
---@param isEditMode boolean 是否是编辑模式
---@param isSelectMode boolean 是否是选择模式
function PresetTeamView:CreateTableViewByType(presetTeamType, isEditMode, isSelectMode)
    local viewData = self:GetViewData()
    local tableViews = viewData.tableViews
    local tableView = tableViews[presetTeamType]
    if tableView then return end

    local view = viewData.view
    local posY = (isEditMode or isSelectMode) and display.cy + 315 or display.cy + 270

    local csize = self:GetCellSize(presetTeamType, isEditMode, isSelectMode)
    tableView = display.newTableView(display.cx - 5.2, posY, {
        ap = cc.p(0.5, 1),
        size = cc.size(csize.width, 654.6),
        csize = csize,
        dir = display.SDIR_V
    })
    tableView:setCellCreateHandler(function(cellParent)
        return CreateCell(cellParent, presetTeamType, isEditMode, isSelectMode)
    end)
    view:addChild(tableView)

    tableViews[presetTeamType] = tableView

    return tableView
end

---UpdateTabBtnCells
---更新tab按钮显示状态
---@param selectIndex number 选择的下标
function PresetTeamView:UpdateTabBtnShowState(selectIndex)
    local viewData = self:GetViewData()
    local tabBtnCells = viewData.tabBtnCells
    for i, tabBtnCellViewData in ipairs(tabBtnCells) do
        local isSelect = i == selectIndex
        local img = isSelect and RES_DICT.PRESETTEAM_TAB_SELECT or RES_DICT.PRESETTEAM_TAB_DEFAULT
        local fontColor = isSelect and '763200' or 'f2ccb1'
        local tabBtn = tabBtnCellViewData.tabBtn
        tabBtn:setNormalImage(img)
        tabBtn:setSelectedImage(img)
        display.commonLabelParams(tabBtn, {color = fontColor})
        tabBtnCellViewData.frameImg:setVisible(isSelect)
    end
end

---GetCurTableView
---获得当前选择的tableView
---@param presetTeamType PRESET_TEAM_TYPE
function PresetTeamView:GetCurTableView(presetTeamType)
    local viewData = self:GetViewData()
    local tableViews = viewData.tableViews
    return tableViews[presetTeamType]
end

function PresetTeamView:GetCellSize(presetTeamType, isEditMode, isSelectMode)
    local sizeConf = PresetTeamCell.GetPresetTeamConf(presetTeamType, isEditMode, isSelectMode)
    return sizeConf.size
end

function PresetTeamView:GetViewData()
    return self.viewData_
end

return PresetTeamView