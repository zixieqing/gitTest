--[[
推荐好友cell
--]]
local FriendCommendCell = class('home.FriendCommendCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'home.FriendCommendCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function FriendCommendCell:ctor(...)
    local arg = {...}
    local size = arg[1]
    self:setContentSize(size)
    
    local eventNode = CLayout:create(size)
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode
    
    self.bgBtn = display.newImageView(_res('ui/home/friend/friends_list_frame_default.png'), size.width * 0.5, size.height * 0.5 - 4,{
        scale9 = true, size = cc.size(280, 100), capInsets = cc.rect(10, 10,  410, 79)
    })
    self.eventnode:addChild(self.bgBtn)
    -- 头像
    self.avatarIcon = require('common.FriendHeadNode').new({
        enable = true, scale = 0.6, showLevel = true
    })
    display.commonUIParams(self.avatarIcon, {po = cc.p(56, 50)})
    self.eventnode:addChild(self.avatarIcon, 10)
    -- 名称
    self.nameLabel = display.newLabel(105, 59, {text = '你的名字', fontSize = 24, color = '#843f11', ap = cc.p(0, 0)})
    self.eventnode:addChild(self.nameLabel, 10)
    -- 添加按钮
    self.addBtn = display.newButton(248, 34, {n = _res('ui/home/friend/friends_ico_add.png')})
    self.eventnode:addChild(self.addBtn, 10)
    -- 已发送
    self.sendLabel = display.newLabel(270, 10, {text = __('已发送'), fontSize = 20, color = '#aa8b8b', ap = cc.p(1, 0)})
    self.eventnode:addChild(self.sendLabel, 10)


end
return FriendCommendCell