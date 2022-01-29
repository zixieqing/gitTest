local AssistCell = class('home.AssistCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'home.AssistCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function AssistCell:ctor(...)
    local arg = {...}
    local size = arg[1]
    self:setContentSize(size)
    local eventNodeSize = cc.size(145, 120)
    self.eventNode = CLayout:create(eventNodeSize)
    self.eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(self.eventNode)

    local toggleView = display.newToggleView(eventNodeSize.width * 0.5, eventNodeSize.height * 0.5,{--
        n = _res('ui/home/friend/friends_request_bg_head_default.png'),
        s = _res('ui/home/friend/friends_request_bg_head_select.png')
    })
    self.toggleView = toggleView
    self.eventNode:addChild(self.toggleView)

    -- 头像
    self.avatarIcon = require('common.FriendHeadNode').new({
        enable = false, scale = 0.6, showLevel = true
    })
    display.commonUIParams(self.avatarIcon, {po = cc.p(eventNodeSize.width/2, 70)})
    self.eventNode:addChild(self.avatarIcon, 10)
    self.nameLabel = display.newLabel(eventNodeSize.width/2, 13,
        fontWithColor(6,{tag = 1500, text = '',})
    )
    self.eventNode:addChild(self.nameLabel, 10)

end
return AssistCell