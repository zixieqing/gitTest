local CardManualVoiceCell = class('home.CardManualVoiceCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'home.CardManualVoiceCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function CardManualVoiceCell:ctor(...)
    local arg = {...}
    local size = arg[1] 
    self:setContentSize(size)
    self:setCascadeOpacityEnabled(true)
    local eventNode = CLayout:create(size)
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode
    self.bg = display.newButton(size.width/2, 35, {n = _res('ui/home/handbook/pokedex_card_voice_btn_default.png')})
    eventNode:addChild(self.bg, 3)
    -- self.selectFrame = display.newImageView(_res('ui/home/handbook/pokedex_card_voice_btn_light.png'), size.width/2, 35)
    -- eventNode:addChild(self.selectFrame, 10)
    self.voiceDefaultIcon = display.newImageView(_res('ui/home/handbook/pokedex_card_voice_ico_default.png'), size.width - 40, 35)
    eventNode:addChild(self.voiceDefaultIcon, 10)
    self.lockIcon = display.newImageView(_res('ui/common/common_ico_lock.png'), size.width - 40, 35)
    eventNode:addChild(self.lockIcon, 10)
    self.lockSpine = sp.SkeletonAnimation:create(
      'effects/handbook/skeleton.json',
      'effects/handbook/skeleton.atlas',
      1)
    self.lockSpine:update(0)
    self.lockSpine:setToSetupPose()
    self.lockSpine:setPosition(cc.p(size.width - 40, 35))
    eventNode:addChild(self.lockSpine, 10)
    self.lockSpine:setVisible(false)
    self.nameLabel = display.newLabel(20, 35, {text = '', fontSize = 24, color = '#5b3c25', ap = cc.p(0, 0.5)})
    eventNode:addChild(self.nameLabel, 10)
end
return CardManualVoiceCell