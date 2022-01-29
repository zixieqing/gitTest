--[[
好友好友求助cell
--]]
local FriendRequestCell = class('home.FriendRequestCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'home.FriendRequestCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function FriendRequestCell:ctor(...)
    local arg = {...}
    local size = arg[1]
    self:setContentSize(size)
    
    local eventNode = CLayout:create(size)
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode
    
    self.bg = display.newImageView(_res('ui/home/friend/friends_list_frame_default.png'), size.width * 0.5, 75,{scale9 = true, size = cc.size(620, 144)})
    self.eventnode:addChild(self.bg)
    -- 头像
    self.avatarIcon = require('common.FriendHeadNode').new({
        enable = false, scale = 0.6, showLevel = true
    })
    display.commonUIParams(self.avatarIcon, {po = cc.p(66, 88)})
    self.eventnode:addChild(self.avatarIcon, 10)
    -- 名称
    self.nameLabel = display.newLabel(115, 100, {text = '', fontSize = 24, color = '#843f11', ap = cc.p(0, 0)})
    self.eventnode:addChild(self.nameLabel, 10)
    -- 捐助
    self.donateLabel = display.newLabel(115, 70, {text = __('向你求助了外卖食物'), ap = cc.p(0, 0), fontSize = 20, color = '#aa8b8b'})
    self.eventnode:addChild(self.donateLabel, 10)
    -- 时间
    self.timeLabel = display.newLabel(25, 22, {text = '', fontSize = 20, color = '#a95e5e', ap = cc.p(0, 0.5)})
    self.eventnode:addChild(self.timeLabel, 10)
    -- 道具
    self.goodsIcon = require('common.GoodNode').new({id = 160001, amount = 1, showAmount = true})
    display.commonUIParams(self.goodsIcon, {po = cc.p(404, 84), animate = false})
    self.goodsIcon:setScale(0.8)
    self.eventnode:addChild(self.goodsIcon, 10)
    -- 数目
    self.amountLabel = display.newLabel(404, 24, fontWithColor(16, {text = ''}) )
    self.eventnode:addChild(self.amountLabel, 10)
    -- 赠送按钮
    self.presentBtn = display.newButton(540, 75, {n = _res('ui/common/common_btn_orange.png')})
    self.eventnode:addChild(self.presentBtn, 10)
    display.commonLabelParams(self.presentBtn, fontWithColor(14, {text = __('赠送')}))
end
return FriendRequestCell