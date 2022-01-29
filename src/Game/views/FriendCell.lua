local FriendCell = class('home.FriendCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'home.FriendCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)
local RES_DICT = {
    CHECKBOX_N    = _res('ui/common/common_btn_check_default.png'),
    CHECKBOX_S    = _res('ui/common/common_btn_check_selected.png'),
}

function FriendCell:ctor(...)
    local arg = {...}
    local size = arg[1]
    self:setContentSize(size)
    
    local eventNode = CLayout:create(size)
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode
    
    self.bgBtn = display.newButton(size.width * 0.5, 48,{
        n = _res('ui/home/friend/friends_list_frame_default.png'), useS = false
    })
    self.eventnode:addChild(self.bgBtn)
    -- 头像
    self.avatarIcon = require('common.FriendHeadNode').new({
        enable = true, scale = 0.6, showLevel = true
    })
    display.commonUIParams(self.avatarIcon, {po = cc.p(66, 49)})
    self.eventnode:addChild(self.avatarIcon, 10)
    -- 名称
    self.nameLabel = display.newLabel(115, 56, {text = '', fontSize = 24, color = '#843f11', ap = cc.p(0, 0)})
    self.eventnode:addChild(self.nameLabel, 10)
    -- 签名
    self.signLabel = display.newLabel(115, 13, {text = '', fontSize = 20, color = '#aa8b8b', ap = cc.p(0, 0),w = 320})
    self.eventnode:addChild(self.signLabel, 10)
    -- 选中框
    self.selectedFrame = display.newImageView(_res('ui/home/friend/common_bg_list.png'), size.width*0.5, 48)
    self.eventnode:addChild(self.selectedFrame, 10)   
    self.selectedFrame:setVisible(false)
    self.remindIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), 90, 80)
    self.eventnode:addChild(self.remindIcon ,15)
    -- 复选框
    self.checkbox = display.newCheckBox(size.width - 90, size.height / 2, {ap = display.CENTER , n = RES_DICT.CHECKBOX_N, d = RES_DICT.CHECKBOX_S, s = RES_DICT.CHECKBOX_S})
    self.eventnode:addChild(self.checkbox, 5)
    self.checkbox:setVisible(false)
    -- 置顶图标
    self.setTopIcon = display.newImageView(_res('ui/home/friend/friends_bg_list_top2.png'), size.width - 40, size.height / 2, {ap = display.CENTER})
    self.eventnode:addChild(self.setTopIcon, 5)
    self.setTopIcon:setVisible(false)


end
return FriendCell
