--[[
大堂信息页面Cell
--]]
local LobbyInformationCell = class('LobbyInformationCell', function ()
	local LobbyInformationCell = CGridViewCell:new()
	LobbyInformationCell.name = 'home.LobbyInformationCell'
	LobbyInformationCell:enableNodeEvents()
	return LobbyInformationCell
end)

function LobbyInformationCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	-- bg
	self.bgBtn = display.newCheckBox(size.width/2, size.height/2, {
        n = _res("ui/home/lobby/information/setup_btn_tab_default.png"), 
        s = _res("ui/home/lobby/information/setup_btn_tab_select.png")
    })
    self.eventNode:addChild(self.bgBtn)
    self.nameLabel = display.newLabel(size.width/2, size.height/2, fontWithColor(4, {text = ''}))
    self.eventNode:addChild(self.nameLabel)
    self.remindIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), size.width - 20, size.height - 20)
    self.eventNode:addChild(self.remindIcon, 10)
    self.remindIcon:setVisible(false)
    
end
return LobbyInformationCell