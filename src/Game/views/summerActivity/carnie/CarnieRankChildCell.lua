local CarnieRankChildCell = class('home.CarnieRankChildCell',function ()
    local pageviewcell = CLayout:create()
    pageviewcell.name = 'home.CarnieRankChildCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function CarnieRankChildCell:ctor(...)
    local arg = {...}
    local size = arg[1]
    self:setContentSize(size)
    
    local eventNode = CLayout:create(size)
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode
    
    self.bgBtn = display.newButton(size.width * 0.5, size.height * 0.5,{
        n = _res('ui/home/rank/rank_btn_2_default.png')
    })
    self.eventnode:addChild(self.bgBtn)
end
return CarnieRankChildCell
