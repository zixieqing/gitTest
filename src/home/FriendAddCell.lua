local FriendAddCell = class('home.FriendAddCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'home.FriendAddCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function FriendAddCell:ctor(...)
    local arg = {...}
    local size = arg[1]
    self:setContentSize(size)
    
    local eventNode = CLayout:create(size)
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode
    
    self.bgBtn = display.newButton(size.width * 0.5, 48,{
        n = _res('ui/home/friend/friends_list_frame_default.png'), useS = false, enable = false
    })
    self.eventnode:addChild(self.bgBtn)
    -- 头像
    self.avatarIcon = require('common.FriendHeadNode').new({
        enable = true, scale = 0.6, showLevel = true
    })
    display.commonUIParams(self.avatarIcon, {po = cc.p(66, 49)})
    self.eventnode:addChild(self.avatarIcon, 10)
    -- 名称
    self.nameLabel = display.newLabel(115, 56, {text = '你的名字', fontSize = 24, color = '#843f11', ap = cc.p(0, 0)})
    self.eventnode:addChild(self.nameLabel, 10)
    -- 签名
    self.signLabel = display.newLabel(115, 16, {text = __('请求加你为好友'), w = 260 , fontSize = 20, color = '#aa8b8b', ap = cc.p(0, 0), maxW = 320})
    self.eventnode:addChild(self.signLabel, 10)
    -- 同意按钮
    self.consentBtn = display.newButton(400, 49, {n = _res('ui/home/friend/friends_btn_friend_request.png')})
    self.eventnode:addChild(self.consentBtn, 10)

end
return FriendAddCell