--[[
 * author : panmeng
 * descpt : 角色介绍总界面，包含角色之卷，堕神之卷
]]

local RoleIntroductionMainScene = class('RoleIntroductionMainScene', require('Frame.GameScene'))

local RES_DICT = {
    --            = top
    COM_BACK_BTN  = _res('ui/common/common_btn_back.png'),
    COM_TITLE_BAR = _res('ui/common/common_title.png'),
    COM_TIPS_ICON = _res('ui/common/common_btn_tips.png'),
    --            = center
    BG_IMAGE      = _res('ui/collection/roleIntroduction/book_bg.jpg'),
    --            = cell
    NPC_BG       = _res('ui/collection/roleIntroduction/book_btn_npc.png'),
    MONSTER_BG   = _res('ui/collection/roleIntroduction/book_btn_monster.png'),
}

RoleIntroductionMainScene.CELL_MODULE_INFO = {
    {name = __("角色之卷"), bg = RES_DICT.NPC_BG},
    {name = __("堕神之卷"), bg = RES_DICT.MONSTER_BG},
}


function RoleIntroductionMainScene:ctor(args)
    self.super.ctor(self, 'Game.views.collection.roleIntroduction.RoleIntroductionMainScene')

    -- create view
    self.viewData_ = RoleIntroductionMainScene.CreateView()
    self:addChild(self.viewData_.view)

    self:getViewData().moduleTableView:setCellUpdateHandler(handler(self, self.updateModuleCell))
end


function RoleIntroductionMainScene:getViewData()
    return self.viewData_
end


function RoleIntroductionMainScene:showUI(endCB)
    local viewData = self:getViewData()
    viewData.topLayer:setPosition(viewData.topLayerHidePos)
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

-------------------------------------------------------------------------------
-- set/get
-------------------------------------------------------------------------------
function RoleIntroductionMainScene:getModuleInfoByIndex(moduleIndex)
    return checktable(RoleIntroductionMainScene.CELL_MODULE_INFO[moduleIndex])
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function RoleIntroductionMainScene.CreateView()
    local view = ui.layer({bg = RES_DICT.BG_IMAGE, isFull = true})

    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- back button
    local backBtn = ui.button({n = RES_DICT.COM_BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 35, offsetY = -15})

    -- title button
    local titleBtn = ui.title({n = RES_DICT.COM_TITLE_BAR}):updateLabel({fnt = FONT.D1, text = __('角色介绍'), offset = cc.p(0,-10)})
    topLayer:addList(titleBtn):alignTo(backBtn, ui.rc, {offsetX = 2, offsetY = 10})

    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    local moduleTableView = ui.tableView({size = cc.size(display.width, 600), dir = display.SDIR_H, csizeW = math.floor(display.width / 2)})
    centerLayer:addList(moduleTableView):alignTo(nil, ui.cc, {offsetY = -30})

    moduleTableView:setCellCreateHandler(RoleIntroductionMainScene.CreateModuleCell)

    return {
        view            = view,
        --              = top
        topLayer        = topLayer,
        topLayerHidePos = cc.p(topLayer:getPositionX(), 100),
        topLayerShowPos = cc.p(topLayer:getPosition()),
        titleBtn        = titleBtn,
        titleBtnHidePos = cc.p(titleBtn:getPositionX(), titleBtn:getPositionY() + 190),
        titleBtnShowPos = cc.p(titleBtn:getPosition()),
        backBtn         = backBtn,
        --              = center
        centerLayer     = centerLayer,
        moduleTableView = moduleTableView,
    }
end

function RoleIntroductionMainScene.CreateModuleCell(cell)
    local view = cell

    local cellLayer = ui.layer({bg = RES_DICT.NPC_BG, enable = true})
    view:addList(cellLayer):alignTo(nil, ui.cc)

    local moduleBg = cellLayer.bg

    local title = ui.label({fnt = FONT.D20, outline = "#52290e", fontSize = 24, text = "--", ap = ui.cb})
    moduleBg:addList(title):alignTo(nil, ui.cb, {offsetY = 30})

    return {
        moduleBtn = cellLayer,
        title     = title,
        moduleBg  = moduleBg,
    }
end

function RoleIntroductionMainScene:updateModuleCell(cellIndex, cellViewData)
    local moduleInfo = self:getModuleInfoByIndex(cellIndex)

    if moduleInfo.bg then
        cellViewData.moduleBg:setVisible(true)
        cellViewData.moduleBg:setTexture(moduleInfo.bg)
    else
        cellViewData.moduleBg:setVisible(false)
    end
    cellViewData.title:setString(tostring(moduleInfo.name))

    cellViewData.moduleBg:setTag(cellIndex)
end


return RoleIntroductionMainScene
        