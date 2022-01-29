--[[
包厢陈列墙view
--]]
local PriviateRoomWallView = class('PriviateRoomWallView', function ()
    local node = CLayout:create()
    node.name = 'home.PriviateRoomWallView'
    node:enableNodeEvents()
    return node
end)
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local RES_DICT = {
    WALL_BG = _res('ui/privateRoom/vip_wall_bg.png'),

}
function PriviateRoomWallView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
    self.selectedIdx = nil -- 被选中
end
--[[
init ui
--]]
function PriviateRoomWallView:InitUI()
    local function CreateView()
        local bg = display.newImageView(RES_DICT.WALL_BG, 0, 0)
        local bgSize = bg:getContentSize()
        local view = CLayout:create(bgSize)
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setTouchEnabled(true)
        mask:setContentSize(bgSize)
        mask:setPosition(cc.p(bgSize.width / 2, bgSize.height / 2))
        view:addChild(mask, -1)
        bg:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
        view:addChild(bg, 1)
        local souvenirs = {}
        local giftConf = CommonUtils.GetConfigAllMess('giftPosition', 'privateRoom')
        for k, v in pairs(giftConf) do
            local size = cc.size(v.width, v.height)
            node = require('Game.views.privateRoom.PrivateRoomSouvenirNode').new({size = size, scale = checkint(v.scale) / 100, id = checkint(v.id)})
            node:setPosition(cc.p(v.x, v.y))
            view:addChild(node, 5)
            souvenirs[tostring(k)] = node
        end
        return {
            bgSize           = bgSize,
            view             = view,
            souvenirs        = souvenirs,
        }
    end
    xTry(function ( )
        self.viewData = CreateView( )
        self:setContentSize(self.viewData.bgSize)
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(utils.getLocalCenter(self))
    end, __G__TRACKBACK__)
end
--[[
刷新陈列墙
@params wallData map 纪念品数据
--]]
function PriviateRoomWallView:RefreshWall( wallData )
    for k, v in pairs(self.viewData.souvenirs) do
        if wallData[tostring(k)] and wallData[tostring(k)] ~= '' then
            v:SetGoods(checkint(wallData[tostring(k)]))
        else
            v:SetGoods()
        end
    end
end
--[[
纪念品点击回调
--]]
function PriviateRoomWallView:SetSouvenirNodeOnClick( callback )
    for k, v in pairs(self.viewData.souvenirs) do
        v:SetOnClick(callback)
    end 
end
--[[
选中纪念品
@params id int 纪念品位置id
--]]
function PriviateRoomWallView:SetSouvenirNodeSelected( id )
    if not id then return end
    if self.selectedIdx then
        self.viewData.souvenirs[tostring(self.selectedIdx)]:SetSelected(false)
    end
    self.viewData.souvenirs[tostring(id)]:SetSelected(true)
    self.selectedIdx = checkint(id)
end
--[[
设置陈列品是否可以点击
--]]
function PriviateRoomWallView:SetSouvenirsEnabled( isEnabled )
    for i, v in pairs(self.viewData.souvenirs) do
        v.viewData.frame:setEnabled(isEnabled)
    end
end
return PriviateRoomWallView