local NPCManualRoleListCell = class('home.NPCManualRoleListCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'home.NPCManualRoleListCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function NPCManualRoleListCell:ctor(...)
    local arg = {...}
    local size = arg[1]
    self:setContentSize(size)

    local eventNode = CLayout:create(size)
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode
    self.bgBtn = display.newButton(105, size.height/2, {n = _res('ui/home/handbook/pokedex_npc_bg_card.png'), useS = false})
    eventNode:addChild(self.bgBtn, 5)
    self.frame = display.newImageView(_res('ui/home/handbook/pokedex_monster_frame_card.png'), 105, size.height/2-1)
    eventNode:addChild(self.frame, 10)
    self.newIcon = display.newImageView(_res('ui/card_preview_ico_new_2'), 28, size.height - 25)
    eventNode:addChild(self.newIcon, 10)
    self.questionMark = display.newImageView(_res('ui/home/handbook/compose_ico_unkown.png'), 105, size.height*0.6)
    eventNode:addChild(self.questionMark, 10)
    self.nameLabel = display.newButton(105, 45, {n = _res('ui/home/handbook/pokedex_npc_bg_name_default.png'), enable = false})
    display.commonLabelParams(self.nameLabel, {text = ' ', fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#311717', outlineSize = 1})
    eventNode:addChild(self.nameLabel, 9)
    self.role = display.newImageView(_res('arts/roles/cell/pokedex_npc_draw_1.png'), 105, size.height/2)
    eventNode:addChild(self.role, 7)
end
return NPCManualRoleListCell
