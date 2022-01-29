local CapsuleProbabilityCell = class('home.CapsuleProbabilityCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'home.CapsuleProbabilityCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function CapsuleProbabilityCell:ctor(...)
    local arg = {...}
    local size = arg[1]
    self:setContentSize(size)
    
    self.eventNode = CLayout:create(size)
    self.eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(self.eventNode)
    self.bg = display.newImageView(_res('ui/home/capsule/draw_probability_text_frame.png'), size.width/2, size.height/2 - 2)
    self.eventNode:addChild(self.bg, 1)
    self.nameLabel = display.newLabel(32, size.height/2 - 2, {ap = cc.p(0, 0.5), fontSize = 20, color = '#6d401a', text = ''})
    self.eventNode:addChild(self.nameLabel, 5)
    self.probabilityLabel = display.newLabel(size.width - 32, size.height/2 - 2, {ap = cc.p(1, 0.5), fontSize = 20, color = '#6d401a', text = ''})
    self.eventNode:addChild(self.probabilityLabel, 5)
end
return CapsuleProbabilityCell