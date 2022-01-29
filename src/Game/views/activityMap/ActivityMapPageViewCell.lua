--[[
活动副本地图标签页
@params table {
	size cc.size 页签大小
}
--]]
local ActivityMapPageViewCell = class('ActivityMapPageViewCell', function ()
	local node = CPageViewCell:new()
    node.name = 'Game.views.activityMap.ActivityMapPageViewCell'
    node:setName('ActivityMapPageViewCell')
    return node
end)

function ActivityMapPageViewCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
    self.eventNode = CLayout:create(size)
    self.eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(self.eventNode)
    -- 背景 --
    self.bgView = CLayout:create(cc.size(1336, 1002))
    self.leftImage = display.newImageView(_res('arts/maps/maps_bg_2_01.png'), 0, 0, {ap = display.LEFT_BOTTOM})
    self.bgView:addChild(self.leftImage)
    self.rightImage = display.newImageView(_res('arts/maps/maps_bg_2_02.png'), 1336, 0, {ap = display.RIGHT_BOTTOM})
    self.bgView:addChild(self.rightImage)
    display.commonUIParams(self.bgView,{ap = display.CENTER, po = cc.p(self:getContentSize().width * 0.5, self:getContentSize().height * 0.5)})
    fullScreenFixScale(self.bgView)
    self.eventNode:addChild(self.bgView)
    self.stageNodeTable = {}
end

return ActivityMapPageViewCell
