--[[
 * author : panmeng
 * descpt : 猫咪 指南 猫咪日常：疾病2
]]
local GuideCatModulePage14 = class('GuideCatModulePage14', function()
    return ui.layer({name = 'Game.views.guide.GuideCatModulePage.GuideCatModulePage14', enableEvent = true})
end)

local RES_DICT = {
    LEFT_CENTER  = _res('guide/catModule/cat_book_life_ball.png'),
    RIGTH_TOP_BG = _res('guide/catModule/cat_book_life_sick.png'),
    LINE_IMG     = _res('guide/guide_line_dotted_1.png'),
}
local CELL_SIZE = cc.size(500, 200)


function GuideCatModulePage14:ctor(args)
    -- create view
    self.viewData_ = GuideCatModulePage14.CreateView()
    self:addChild(self.viewData_.view)
end


function GuideCatModulePage14:getViewData()
    return self.viewData_
end


function GuideCatModulePage14:refreshUI(data)
    local totalCellNum = 0
    for index = 3, table.nums(data) do
        if data[tostring(index)] ~= '' then
            totalCellNum = totalCellNum + 1
        else
            break
        end   
    end

    CELL_SIZE.height   = (GuideUtils.GUIDE_VIEW_SIZE.height - 45) / totalCellNum
    local cellNodeList = {}
    for i = 1, totalCellNum do
        local str = data[tostring(i + 2)]
        local cellNode = GuideCatModulePage14.CreateViewCell(str)
        table.insert(cellNodeList, cellNode)

        if i == totalCellNum then
            cellNode:updateLineImgVisible(false)
        end
    end
    if #cellNodeList > 0 then
        self:getViewData().view:addList(cellNodeList)
        ui.flowLayout(self:getViewData().rightViewP, cellNodeList, {type = ui.flowV, ap = ui.cc})
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function GuideCatModulePage14.CreateView()
    local view = ui.layer({size = GuideUtils.GUIDE_VIEW_SIZE})

    ----------------------------------------------------- left view
    local leftBg = ui.image({img = RES_DICT.LEFT_CENTER})
    view:addList(leftBg):alignTo(nil, ui.cc, {offsetX = -GuideUtils.GUIDE_VIEW_SIZE.width * 0.25, offsetY = -20})

    ----------------------------------------------------- rigth view
    local rightViewP     = cc.p(GuideUtils.GUIDE_VIEW_SIZE.width * 0.73, GuideUtils.GUIDE_VIEW_SIZE.height * 0.47)
    
    return {
        view          = view,
        rightViewP    = rightViewP,
    }
end

function GuideCatModulePage14.CreateViewCell(str)
    local view    = ui.layer({size = CELL_SIZE})
    local strList = string.split(str, ";")
    local iconImg = ui.image({img = _res(string.format("ui/catModule/catInfo/stateIcon/%s.png", tostring(strList[1]))), scale = 0.9})
    view:addList(iconImg):alignTo(nil, ui.lc, {offsetX = 45})

    local descr = ui.label({fnt = FONT.D9, color = "#A98880", text = tostring(strList[3]), ap = ui.lc, w = CELL_SIZE.width - 150})
    view:addList(descr):alignTo(nil, ui.lc, {offsetX = 130, offsetY = -15})

    local title  = ui.label({fnt = FONT.D4, text = tostring(strList[2]), ap = ui.lt})
    local titleW = display.getLabelContentSize(title).width
    view:addList(title):alignTo(descr, ui.lt, {offsetX = titleW, offsetY = 5})

    local lineImg = ui.image({img = RES_DICT.LINE_IMG})
    view:addList(lineImg):alignTo(nil, ui.cb)

    view.updateLineImgVisible = function(self, visible)
        lineImg:setVisible(visible)
    end

    return view
end


return GuideCatModulePage14
