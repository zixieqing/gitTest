--[[
 * author : liuzhipeng
 * descpt : 好友 好友切磋 选择对手弹窗列表Cell
--]]
local FriendBattleChooseEnemyCell = class('FriendBattleChooseEnemyCell', function ()
    local FriendBattleChooseEnemyCell = CGridViewCell:new()
    FriendBattleChooseEnemyCell.name = 'home.FriendBattleChooseEnemyCell'
    FriendBattleChooseEnemyCell:enableNodeEvents()
    return FriendBattleChooseEnemyCell
end)
local RES_DICT = {
    CELL_BG            = _res('ui/home/friend/friendBattle/friend_battle_bg_choice_team.png'),
    NAME_BG            = _res('ui/home/friend/friendBattle/friend_battle_bg_name.png'),
}
function FriendBattleChooseEnemyCell:ctor( ... )
    local arg = { ... }
    local size = arg[1]
    self:setContentSize(size)
    local eventNode = display.newLayer(size.width/2 ,size.height/2 , {ap =display.CENTER , size = size})
    self:addChild(eventNode)
    self.eventNode = eventNode
    -- 背景
    self.bgBtn = display.newButton(size.width / 2, size.height / 2, {n = RES_DICT.CELL_BG, useS = false})
    eventNode:addChild(self.bgBtn, 1)
    -- 头像
    self.avatarIcon = require('common.FriendHeadNode').new({enable = false, scale = 0.6, showLevel = false})
    display.commonUIParams(self.avatarIcon, {po = cc.p(76, size.height / 2 + 20)})
    eventNode:addChild(self.avatarIcon, 5)
    -- 等级
    self.levelLabel = display.newLabel(76, 44, {text = '', color = '#c68656', fontSize = 22})
    eventNode:addChild(self.levelLabel, 5)
    -- 名称
    local nameBg = display.newImageView(RES_DICT.NAME_BG, 120, 130, {ap = display.LEFT_CENTER})
    eventNode:addChild(nameBg, 1)
    self.nameLabel = display.newLabel(125, 132, {text = '', fontSize = 22, color = '#ffffff', ap = display.LEFT_CENTER})
    eventNode:addChild(self.nameLabel, 1)
    -- 战斗力
    self.battlePointLabel = cc.Label:createWithBMFont('font/team_ico_fight_figure_2.fnt', '0')
    self.battlePointLabel:setAnchorPoint(display.RIGHT_CENTER)
    self.battlePointLabel:setHorizontalAlignment(display.TAR)
    self.battlePointLabel:setPosition(cc.p(size.width - 60, 135))
    self.battlePointLabel:setScale(0.5)
    eventNode:addChild(self.battlePointLabel, 5)
    -- 编队为空提示
    self.emptyTipsLabel = display.newLabel(size.width / 2 + 10, size.height / 2 - 20, fontWithColor(4, {text = __('对方暂未设置编队')}))
    eventNode:addChild(self.emptyTipsLabel, 5)
    -- cardLayout
    local cardLayoutSize = cc.size(440, 95)
    self.cardLayout = CLayout:create(cardLayoutSize)
    self.cardLayout:setPosition(size.width / 2 + 36, size.height / 2 - 16)
    self.cardLayout:setBackgroundColor(cc.r4b())
    eventNode:addChild(self.cardLayout, 5)
end
return FriendBattleChooseEnemyCell