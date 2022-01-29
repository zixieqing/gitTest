--[[
 * author : liuzhipeng
 * descpt : 猫屋 繁殖信息View
--]]
local CatHouseBreedInfoView = class('CatHouseBreedInfoView', function ()
    return ui.layer({name = 'Game.views.catHouse.CatHouseBreedInfoView', enableEvent = true, ap = display.CENTER})
end)
-------------------------------------------------
-------------------- define ---------------------
local RES_DICT = {
    BG              = _res('ui/catHouse/breed/grow_birth_bg_book.png'),
    SUCCESS_BG      = _res('ui/catHouse/breed/grow_birth_bg_book_light.png'),
    FAILURE_BG      = _res('ui/catHouse/breed/grow_birth_bg_book_grey.png'),
    CELL_BG_1       = _res('ui/catHouse/breed/grow_birth_bg_book_list_1.png'),
    CELL_BG_2       = _res('ui/catHouse/breed/grow_birth_bg_book_list_2.png'),

}
local CreateTableViewCell = nil
-------------------- define ---------------------
-------------------------------------------------

-------------------------------------------------
------------------ inheritance ------------------
function CatHouseBreedInfoView:ctor( ... )
    self:InitUI()
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
init ui
--]]
function CatHouseBreedInfoView:InitUI()
    local function CreateView()
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        local view = CLayout:create(size)
        bg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bg, 1)
        -- mask
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- 配对成功
        local successBg = display.newImageView(RES_DICT.SUCCESS_BG, size.width / 2 - 5, size.height / 2 + 130)
        view:addChild(successBg, 1)
        local successTitle = display.newLabel(size.width / 2 - 5, size.height / 2 + 237, {text = __('配对成功'), color = '#FFFFFF', fontSize = 24, ttf = true, font = TTF_GAME_FONT, outline = '#A34613', outlineSize = 1})
        view:addChild(successTitle, 1)
        local successDescrLabel = display.newLabel(64, size.height / 2 + 180, {text = __('猫咪已进入生育状态'), color = '#683320', fontSize = 24, ap = display.LEFT_CENTER})
        view:addChild(successDescrLabel, 1)
        local successTableViewSize = cc.size(successBg:getContentSize().width, 145)
        local successTableViewCellSize = cc.size(successTableViewSize.width, 40)
        local successTableView = display.newTableView(size.width / 2, size.height / 2 + 90, {size = successTableViewSize, csize = successTableViewCellSize, dir = display.SDIR_V})
        successTableView:setCellCreateHandler(CreateTableViewCell)
        view:addChild(successTableView, 5)

        -- 配对失败
        local failureBg = display.newImageView(RES_DICT.FAILURE_BG, size.width / 2 - 5, size.width / 2 - 75)
        view:addChild(failureBg, 1)
        local failureTitle = display.newLabel(size.width / 2 - 5, size.height / 2 - 28, {text = __('配对失败'), color = '#FFFFFF', fontSize = 24, ttf = true, font = TTF_GAME_FONT, outline = '#646464', outlineSize = 1})
        view:addChild(failureTitle, 1)
        local failureDescrLabel = display.newLabel(64, size.height / 2 - 82, {text = __('猫咪已解除生育状态'), color = '#683320', fontSize = 24, ap = display.LEFT_CENTER})
        view:addChild(failureDescrLabel, 1)
        local failureTableViewSize = cc.size(failureBg:getContentSize().width, 145)
        local failureTableViewCellSize = cc.size(failureTableViewSize.width, 40)
        local failureTableView = display.newTableView(size.width / 2, size.height / 2 - 175, {size = failureTableViewSize, csize = failureTableViewCellSize, dir = display.SDIR_V})
        failureTableView:setCellCreateHandler(CreateTableViewCell)
        view:addChild(failureTableView, 5)
        return {
            view                = view,
            successTableView    = successTableView,
            failureTableView    = failureTableView,

        }
    end
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
进入动画
--]]
function CatHouseBreedInfoView:EnterAction(  )
    local viewData = self:GetViewData()
    viewData.view:setOpacity(255 * 0.3)
    viewData.view:runAction(
        cc.FadeIn:create(0.2)
    )
end
--[[
刷新列表cell
--]]
function CatHouseBreedInfoView:RefreshListCell( cellViewData, cellIndex, playerCatId )
    local texture = RES_DICT.CELL_BG_2
    if cellIndex % 2 == 0 then
        texture = RES_DICT.CELL_BG_1
    end
    cellViewData.bg:setTexture(texture)
    local catUuid = CatHouseUtils.BuildCatUuid(app.gameMgr:GetPlayerId(), playerCatId)
    local catModel = app.catHouseMgr:getCatModel(catUuid)
    cellViewData.nameLabel:setString(catModel:getName())
end
--[[
创建列表cell
--]]
function CreateTableViewCell( cellParent )
    local view = cellParent
    local size = cellParent:getContentSize()
    local bg = display.newImageView(RES_DICT.CELL_BG_1, size.width / 2, size.height / 2)
    view:addChild(bg, 1)
    local nameLabel = display.newLabel(35, size.height / 2, {text = '', color = '#917256', fontSize = 22, ap = display.LEFT_CENTER})
    view:addChild(nameLabel, 1)
    return {
        size           = size,
        view           = view,
        bg             = bg,
        nameLabel      = nameLabel,
    }
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
获取viewData
--]]
function CatHouseBreedInfoView:GetViewData()
    return self.viewData
end
------------------- get / set -------------------
-------------------------------------------------
return CatHouseBreedInfoView