--[[
包厢陈列墙展示view
--]]
local PriviateRoomWallShowView = class('PriviateRoomWallShowView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.PriviateRoomWallShowView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BTN_BACK          = _res('ui/common/common_btn_back.png'),
}
function PriviateRoomWallShowView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function PriviateRoomWallShowView:InitUI()
    local function CreateView()
        local size = display.size
        local view = CLayout:create(size)
        local wallView = require('Game.views.privateRoom.PrivateRoomWallView').new()
		wallView:setPosition(display.center)
        view:addChild(wallView, 5) 
        -- back button
        local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = _res(RES_DICT.BTN_BACK)})
        self:addChild(backBtn, 10)
        return {
            view             = view,
            wallView         = wallView,
            backBtn          = backBtn,
        }
    end
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view, 1)
        self.viewData.view:setPosition(utils.getLocalCenter(self))
    end, __G__TRACKBACK__)
end
return PriviateRoomWallShowView