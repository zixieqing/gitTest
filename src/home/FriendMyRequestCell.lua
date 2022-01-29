--[[
好友我的求助cell
--]]
local FriendMyRequestCell = class('home.FriendMyRequestCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'home.FriendMyRequestCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function FriendMyRequestCell:ctor(...)
    local arg = {...}
    local size = arg[1]
    self:setContentSize(size)
    
    local eventNode = CLayout:create(size)
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode
    
    self.bg = display.newImageView(_res('ui/home/friend/friends_bg_help_frame_2.png'), size.width * 0.5, 75,{})
    self.eventnode:addChild(self.bg)
    -- 头像
    self.avatarIcon = require('common.FriendHeadNode').new({
        enable = true, scale = 0.6, showLevel = true
    })
    display.commonUIParams(self.avatarIcon, {po = cc.p(66, 88)})
    self.eventnode:addChild(self.avatarIcon, 10)
    -- 名称
    self.nameLabel = display.newLabel(115, 100, {text = '', fontSize = 24, color = '#843f11', ap = cc.p(0, 0)})
    self.eventnode:addChild(self.nameLabel, 10)
    -- 捐助
    self.donateLabel = display.newLabel(115, 70, fontWithColor(10, {text = __('捐助了你'), ap = cc.p(0, 0)}))
    self.eventnode:addChild(self.donateLabel, 10)
    -- 时间
    self.timeLabel = display.newLabel(25, 22, {text = '', fontSize = 20, color = '#a95e5e', ap = cc.p(0, 0.5)})
    self.eventnode:addChild(self.timeLabel, 10)
    -- 求助
    self.helpLabel = display.newLabel(22, 126, {text = __('正在求助'), fontSize = 24, color = '#843f11', ap = cc.p(0, 1)})
    self.eventnode:addChild(self.helpLabel, 10)
    -- 道具
    self.goodsIcon = require('common.GoodNode').new({id = 160001, amount = 1, showAmount = true})
    display.commonUIParams(self.goodsIcon, {po = cc.p(310, 84), animate = false, cb = function (sender)
        app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = 160001, type = 1})
    end})
    self.goodsIcon:setScale(0.8)
    self.eventnode:addChild(self.goodsIcon, 10)

end
return FriendMyRequestCell