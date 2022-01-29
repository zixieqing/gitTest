local NPCManualStoryListCell = class('home.NPCManualStoryListCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'home.NPCManualStoryListCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function NPCManualStoryListCell:ctor(...)
    local arg = {...}
    local size = arg[1] 
    self:setContentSize(size)
    
    local eventNode = CLayout:create(size)
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode
    self.bgBtn = display.newButton(52, size.height/2, {n = _res('ui/home/handbook/pokedex_card_btn_life_default.png'), useS = false})
    eventNode:addChild(self.bgBtn, 5)
    self.numIcon = display.newImageView(_res('ui/home/handbook/pokedex_card_ico_life_1.png'), self.bgBtn:getContentSize().width/2, 185)
    self.bgBtn:addChild(self.numIcon, 5)
    self.lockIcon = display.newImageView(_res('ui/common/common_ico_lock.png'), self.bgBtn:getContentSize().width/2, self.bgBtn:getContentSize().height/2)
    self.bgBtn:addChild(self.lockIcon, 5)
    self.lockMask = display.newImageView(_res('ui/home/handbook/pokedex_card_btn_life_love_disabled.png'), 52, size.height/2)
    eventNode:addChild(self.lockMask, 10)
end
return NPCManualStoryListCell