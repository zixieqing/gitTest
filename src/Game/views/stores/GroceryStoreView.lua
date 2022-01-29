--[[
 * author : kaishiqi
 * descpt : 新游戏商店 - 杂货铺商店视图
]]
local GroceryStoreView = class('GroceryStoreView', function()
    return ui.layer({name = 'Game.views.stores.GroceryStoreView'})
end)

local RES_DICT = {
    BTN_BG   = _res('ui/stores/grocery/shop_btn_stall_default.png'),
    TRANS_BG = _res('ui/common/story_tranparent_bg.png'),
    ICON_1   = _res('ui/stores/grocery/shop_stall_ico_1.png'),
    ICON_2   = _res('ui/stores/grocery/shop_stall_ico_2.png'),
    ICON_3   = _res('ui/stores/grocery/shop_stall_ico_3.png'),
    ICON_4   = _res('ui/stores/grocery/shop_stall_ico_4.png'),
    ICON_5   = _res('ui/stores/grocery/shop_stall_ico_5.png'),
    ICON_6   = _res('ui/stores/grocery/shop_stall_ico_6.png'),
    ICON_7   = _res('ui/stores/grocery/shop_stall_ico_7.png'),
    ICON_8   = _res('ui/stores/grocery/shop_stall_ico_8.png'),
    ICON_9   = _res('ui/stores/grocery/shop_stall_ico_9.png'),

}

local ENTRANCE_DEFINE = {
    {name = __('小费商店'), icon = RES_DICT.ICON_1, tag = GAME_STORE_TYPE.RESTAURANT   , id = JUMP_MODULE_DATA.RESTAURANT       , switch = MODULE_SWITCH.RESTAURANT                                                         },
    {name = __('勋章商店'), icon = RES_DICT.ICON_2, tag = GAME_STORE_TYPE.PVP_ARENA    , id = JUMP_MODULE_DATA.PVC_ROYAL_BATTLE , switch = MODULE_SWITCH.PVC_ROYAL_BATTLE                                                   },
    {name = __('通宝商店'), icon = RES_DICT.ICON_3, tag = GAME_STORE_TYPE.KOF_ARENA    , id = JUMP_MODULE_DATA.TAG_MATCH        , switch = MODULE_SWITCH.TAG_MATCH        },
    {name = __('工会商店'), icon = RES_DICT.ICON_4, tag = GAME_STORE_TYPE.UNION        , id = JUMP_MODULE_DATA.GUILD            , switch = MODULE_SWITCH.GUILD                                                              },
    {name = __('竞赛商店'), icon = RES_DICT.ICON_5, tag = GAME_STORE_TYPE.UNION_WARS   , id = JUMP_MODULE_DATA.UNION_WARS       , switch = MODULE_SWITCH.UNION_WARS       , moduleState = GAME_MODULE_OPEN.UNION_WARS       },
    {name = __('水吧商店'), icon = RES_DICT.ICON_6, tag = GAME_STORE_TYPE.WATER_BAR    , id = JUMP_MODULE_DATA.WATER_BAR        , switch = MODULE_SWITCH.HOMELAND         , moduleState = GAME_MODULE_OPEN.WATER_BAR        },
    {name = __('记忆商店'), icon = RES_DICT.ICON_7, tag = GAME_STORE_TYPE.MEMORY       , id = JUMP_MODULE_DATA.MEMORY_STORE     , switch = MODULE_SWITCH.SHOP             , moduleState = GAME_MODULE_OPEN.MEMORY_STORE     },
    {name = __('印记商店'), icon = RES_DICT.ICON_8, tag = GAME_STORE_TYPE.CHAMPIONSHIP , id = JUMP_MODULE_DATA.CHAMPIONSHIP     , switch = MODULE_SWITCH.MODELSELECT                                                        },
    {name = __('演武商店'), icon = RES_DICT.ICON_9, tag = GAME_STORE_TYPE.NEW_KOF_ARENA, id = JUMP_MODULE_DATA.NEW_TAG_MATCH                                              , moduleState = GAME_MODULE_OPEN.NEW_TAG_MATCH    }, 
}

function GroceryStoreView:ctor(size)
    self:setContentSize(size)

    local isUnlockedFunc = function(moduleId)
        if moduleId == JUMP_MODULE_DATA.GUILD or moduleId == JUMP_MODULE_DATA.UNION_WARS then
            return app.gameMgr:IsJoinUnion()

        elseif moduleId == JUMP_MODULE_DATA.CHAMPIONSHIP then
            for _, value in pairs(CONF.COMMON.TRIALS_ENTRANCE:GetAll()) do
                if checkint(value.functionId) == checkint(moduleId) then
                    return CommonUtils.UnLockModule(moduleId)
                end
            end
            return false

        else
            return CommonUtils.UnLockModule(moduleId)
        end
    end

    -- init vars
    self.entranceDefines_ = {}
    for _, define in pairs(ENTRANCE_DEFINE) do
        local isOpenModule = define.moduleState == nil or define.moduleState == true
        if isOpenModule and CommonUtils.GetModuleAvailable(define.switch) then
            if isUnlockedFunc(define.id) then
                table.insert(self.entranceDefines_, define)
            end
        end
    end

    -- create view
    self.viewData_ = GroceryStoreView.CreateView(size)
    self:addChild(self.viewData_.view)

    -- update views
    self.viewData_.subStoreGridView:setCellUpdateHandler(handler(self, self.onUpdateSubStoreCellHandler))
    self.viewData_.subStoreGridView:resetCellCount(#self.entranceDefines_)
end


function GroceryStoreView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- handler

function GroceryStoreView:onUpdateSubStoreCellHandler(cellIndex, cellViewData)
    local entranceDefine = self.entranceDefines_[cellIndex] or {}
    cellViewData.clickArea:setTag(checkint(entranceDefine.tag))
    cellViewData.nameLabel:updateLabel({text = tostring(entranceDefine.name), maxW = 240})
    cellViewData.iconLayer:addAndClear(ui.image({img = entranceDefine.icon}))
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function GroceryStoreView.CreateView(size)
    local view = ui.layer({size = size})
    local cpos = cc.sizep(size, ui.cc)

    local subStoreGridView = ui.gridView({p = cpos, size = size, cols = 2, csizeH = 176})
    subStoreGridView:setCellCreateHandler(GroceryStoreView.CreateListCell)
    view:addChild(subStoreGridView)

    return {
        view             = view,
        subStoreGridView = subStoreGridView,
    }
end


function GroceryStoreView.CreateListCell(cellParent)
    local view = cellParent
    local size = cellParent:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    local frameImage = ui.image({img = RES_DICT.BTN_BG})
    view:addList(frameImage):alignTo(nil, ui.lc, {offsetX = 45, offsetY = -10})

    local nameLabel = ui.label({fnt = FONT.D7, fontSize = 26, color = '#763232', ap = ui.lc})
    view:addList(nameLabel):alignTo(nil, ui.lc, {offsetX = 70, offsetY = -26})

    local iconLayer = ui.layer({size = cc.size(0,0)})
    view:addList(iconLayer):alignTo(nil, ui.rc, {offsetX = -140, offsetY = -5})

    local clickArea = ui.layer({size = size, color = cc.r4b(0), enable = true})
    view:add(clickArea)

    return {
        view      = view,
        clickArea = clickArea,
        nameLabel = nameLabel,
        iconLayer = iconLayer,
    }
end


return GroceryStoreView
