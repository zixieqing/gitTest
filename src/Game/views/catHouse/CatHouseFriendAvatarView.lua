--[[
 * author : panmeng
 * descpt : 好友猫屋 预览功能
]]
local AvatarLayer              = require('Game.views.catHouse.CatHouseAvatarView')
local CatHouseFriendAvatarView = class('CatHouseFriendAvatarView', function()
    return ui.layer({name = 'Game.views.catHouse.CatHouseFriendAvatarView', enableEvent = true})
end)

local RES_DICT = {
    COM_BACK_BTN  = _res('ui/common/common_btn_back.png'),
    INFO_BTN      = _res('ui/catHouse/home/cat_house_ico_information.png'),
    COLL_BTN      = _res('ui/catHouse/home/cat_house_ico_collect.png'),
    FUNC_NAME_BAR = _res('ui/catHouse/home/cat_icon_name_bg.png'),
}


function CatHouseFriendAvatarView:ctor(args)
    -- create view
    self.viewData_ = CatHouseFriendAvatarView.CreateView()
    self:addChild(self.viewData_.view)
end


function CatHouseFriendAvatarView:getViewData()
    return self.viewData_
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatHouseFriendAvatarView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150)}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })

    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    local avatarLayer = AvatarLayer.new()
    centerLayer:add(avatarLayer)

    local funBtnGroup = centerLayer:addList({
        ui.button({n = RES_DICT.INFO_BTN}),
        ui.button({n = RES_DICT.COLL_BTN}),
    })
    ui.flowLayout(cc.p(display.SAFE_R - 30, 20), funBtnGroup, {type = ui.flowH, gapW = 10, ap = ui.rb})

    local infoGroup = {__("信息"), __("收藏")}
    for btnIndex, funBtn in ipairs(funBtnGroup) do
        local title = ui.title({img = RES_DICT.FUNC_NAME_BAR, size = cc.size(100, 28), cut = cc.dir(5, 5, 5, 5)})
        title:updateLabel({fnt = FONT.D14, fontSize = 22, text = tostring(infoGroup[btnIndex]), reqW = 90})
        funBtn:addList(title):alignTo(nil, ui.cb, {offsetY = -10})
    end

    ------------------------------------------------- [top]
    local topLayer = ui.layer()
    view:add(topLayer)

    -- back button
    local backBtn = ui.button({n = RES_DICT.COM_BACK_BTN})
    topLayer:addList(backBtn):alignTo(nil, ui.lt, {offsetX = display.SAFE_L + 30, offsetY = -15})


    return {
        view            = view,
        backBtn         = backBtn,
        --              = center
        centerLayer     = centerLayer,
        infoBtn         = funBtnGroup[1],
        collBtn         = funBtnGroup[2],
        avatarLayer     = avatarLayer,
    }
end


return CatHouseFriendAvatarView
