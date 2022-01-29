--[[
奖励列表页面Cell
--]]
local LobbyRewardListCell = class('LobbyRewardListCell', function ()
	local LobbyRewardListCell = CGridViewCell:new()
	LobbyRewardListCell.name = 'home.LobbyRewardListCell'
	LobbyRewardListCell:enableNodeEvents()
	return LobbyRewardListCell
end)

function LobbyRewardListCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	self.bg = display.newImageView(_res('ui/common/common_bg_list.png'), size.width/2, size.height/2, {scale9 = true, size = cc.size(440, 90), capInsets = cc.rect(10, 10, 482, 96)})
   	self.eventNode:addChild(self.bg) 
   	self.numLabel = display.newLabel(70, size.height/2, {text = '第一名', fontSize = 20, color = '#5c5c5c', w =100})
   	self.eventNode:addChild(self.numLabel)
    
end
return LobbyRewardListCell