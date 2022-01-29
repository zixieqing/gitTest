--[[
包厢功能 贵宾信息列表 view
--]]
local VIEW_SIZE = display.size
local PrivateRoomGuestInfoListView = class('PrivateRoomGuestInfoListView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.privateRoom.PrivateRoomGuestInfoListView'
	node:enableNodeEvents()
	return node
end)


local CreateView  = nil
local CreateCell_ = nil

local PrivateRoomGuestInfoNode = require("Game.views.privateRoom.PrivateRoomGuestInfoNode")

local RES_DIR = {
    LIST_BG      =  _res('ui/home/handbook/pokedex_monster_list_bg.png'),
}

function PrivateRoomGuestInfoListView:ctor( ... ) 
    
    self.args = unpack({...})
    self:initialUI()
end

function PrivateRoomGuestInfoListView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

function PrivateRoomGuestInfoListView:refreshUI()
    local viewData = self:getViewData()
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()

    local listBgSize = cc.size(display.width, 632)
    local listBgLayer = display.newLayer(size.width / 2, size.height / 2 - 353, {ap = display.CENTER_BOTTOM, size = listBgSize})
    view:addChild(listBgLayer)

    -- list bg image
    local bgImageList = display.newImageView(RES_DIR.LIST_BG, listBgSize.width/2, listBgSize.height/2, {scale9 = true, size = listBgSize})
    listBgLayer:addChild(bgImageList)

    local listSize = cc.size(display.SAFE_RECT.width, 600)
    local listCellSize = cc.size(260, listSize.height)
    local tableView = CTableView:create(listSize)
    display.commonUIParams(tableView, {po = cc.p(listBgSize.width / 2, listBgSize.height / 2), ap = display.CENTER})
    tableView:setDirection(eScrollViewDirectionHorizontal)
    -- tableView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    -- tableView:setAutoRelocate(true)
    tableView:setSizeOfCell(listCellSize)
    listBgLayer:addChild(tableView, 10)

    return {
        view          = view,
        tableView  = tableView,
    }
end

CreateCell_ = function (size)
    local cell = CTableViewCell:new()

    local nodes = {}
    for i = 1, 2 do
        local node = PrivateRoomGuestInfoNode:new()
        display.commonUIParams(node, {po = cc.p(size.width / 2, size.height * 0.75 - (i - 1) * size.height * 0.5), ap = display.CENTER})
        node:setTag(i)
        cell:addChild(node)
        table.insert(nodes, node)
    end

    cell.viewData = {
        nodes = nodes
    }
    return cell
end

function PrivateRoomGuestInfoListView:CreateCell(size)
    return CreateCell_(size)
end

function PrivateRoomGuestInfoListView:getViewData()
	return self.viewData_
end

return PrivateRoomGuestInfoListView