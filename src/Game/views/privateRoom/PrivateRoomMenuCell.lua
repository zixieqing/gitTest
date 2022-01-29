--[[
包厢菜单页面cell
--]]
local PrivateRoomMenuCell = class('PrivateRoomMenuCell', function ()
    local PrivateRoomMenuCell = CGridViewCell:new()
	PrivateRoomMenuCell.name = 'home.PrivateRoomMenuCell'
    PrivateRoomMenuCell:enableNodeEvents()
	return PrivateRoomMenuCell
end)
local RES_DICT = {
}
function PrivateRoomMenuCell:ctor( ... )
	local arg = { ... }
    local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	self.goodsNode = require('common.GoodNode').new({id = 0, showAmount = false, callBack = function(sender)end})
	self.goodsNode:setPosition(size.width / 2, size.height - 55)
	self.goodsNode:setScale(0.8)
	self.eventNode:addChild(self.goodsNode, 1) 
	self.richLabel = display.newRichLabel(size.width / 2, 15)
	self.eventNode:addChild(self.richLabel, 1)
end
return PrivateRoomMenuCell