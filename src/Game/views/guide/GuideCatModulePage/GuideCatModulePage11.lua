--[[
 * author : panmeng
 * descpt : 猫咪 指南 猫咪日常-成长
]]
local GuideCatModulePage11 = class('GuideCatModulePage11', function()
    return ui.layer({name = 'Game.views.guide.GuideCatModulePage.GuideCatModulePage11', enableEvent = true})
end)

local RES_DICT = {
    LEFT_CENTER  = _res('guide/catModule/cat_book_life_grow.png'),
    RIGTH_TOP_BG = _res('guide/catModule/cat_book_love_done.png'),
    MATCH_IMG    = _res('ui/catModule/catInfo/grow_cat_main_ico_love.png'),
    WORK_IMG     = _res('ui/catModule/catInfo/grow_cat_main_ico_work.png'),
    STAR_IMG     = _res('guide/catModule/cat_book_life_win.png'),
    LINE_IMG     = _res('guide/guide_line_dotted_1.png'),
}

local CELL_SIZE   = cc.size(500, 200)

local CELL_DEFINE = {
    RES_DICT.WORK_IMG,
    RES_DICT.MATCH_IMG,
    RES_DICT.STAR_IMG,
}

function GuideCatModulePage11:ctor(args)
    -- create view
    self.viewData_ = GuideCatModulePage11.CreateView()
    self:addChild(self.viewData_.view)
end


function GuideCatModulePage11:getViewData()
    return self.viewData_
end


function GuideCatModulePage11:refreshUI(data)
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
        local cellNode = GuideCatModulePage11.CreateViewCell(str, CELL_DEFINE[i] or CELL_DEFINE[1])
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

function GuideCatModulePage11.CreateView()
    local view = ui.layer({size = GuideUtils.GUIDE_VIEW_SIZE})

    ----------------------------------------------------- left view
    local leftTitle = ui.title({n = RES_DICT.LEFT_CENTER})
    view:addList(leftTitle):alignTo(nil, ui.cc, {offsetX = -GuideUtils.GUIDE_VIEW_SIZE.width * 0.25, offsetY = -20})

    ----------------------------------------------------- rigth view
    local rightViewP     = cc.p(GuideUtils.GUIDE_VIEW_SIZE.width * 0.73, GuideUtils.GUIDE_VIEW_SIZE.height * 0.47)

    return {
        view       = view,
        rightViewP = rightViewP,
    }
end


function GuideCatModulePage11.CreateViewCell(str, img)
    local view    = ui.layer({size = CELL_SIZE})
    local strList = string.split(str, ";")
    local iconImg = ui.title({img = img}):updateLabel({fnt = FONT.D14, fontSize = 28, text = tostring(strList[1]), offset = cc.p(0, -50)})
    view:addList(iconImg):alignTo(nil, ui.lc, {offsetX = 45})

    local descr = ui.label({fnt = FONT.D9, color = "#A98880", text = tostring(strList[2]), ap = ui.lc, w = CELL_SIZE.width - 240})
    view:addList(descr):alignTo(nil, ui.lc, {offsetX = 200, offsetY = 0})

    local lineImg = ui.image({img = RES_DICT.LINE_IMG})
    view:addList(lineImg):alignTo(nil, ui.cb)

    view.updateLineImgVisible = function(self, visible)
        lineImg:setVisible(visible)
    end

    return view
end


return GuideCatModulePage11
