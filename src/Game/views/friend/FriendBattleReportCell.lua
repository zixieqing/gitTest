--[[
 * author : liuzhipeng
 * descpt : 好友 好友切磋 战报弹窗列表Cell
--]]
local FriendBattleReportCell = class('FriendBattleReportCell', function ()
    local FriendBattleReportCell = CGridViewCell:new()
    FriendBattleReportCell.name = 'home.FriendBattleReportCell'
    FriendBattleReportCell:enableNodeEvents()
    return FriendBattleReportCell
end)
local RES_DICT = {
    CELL_BG            = _res('ui/home/friend/friendBattle/common_bg_list.png'),
    VS_ICON            = _res('ui/home/friend/friendBattle/starplan_vs_icon_vs.png'),
    REPLAY_ICON        = _res('ui/home/friend/friendBattle/starplan_vs_btn_playback_big.png'),
}
function FriendBattleReportCell:ctor( ... )
    local arg = { ... }
    local size = arg[1]
    self:setContentSize(size)
    local eventNode = display.newLayer(size.width/2 ,size.height/2 , {ap =display.CENTER , size = size})
    self:addChild(eventNode)
    self.eventNode = eventNode
    -- 背景
    self.bg = display.newImageView(RES_DICT.CELL_BG, size.width / 2, size.height / 2)
    eventNode:addChild(self.bg, 1)
    -- 进攻方头像
    self.attackerAvatarIcon = require('common.FriendHeadNode').new({enable = true, scale = 0.6, showLevel = false})
    display.commonUIParams(self.attackerAvatarIcon, {po = cc.p(120, size.height / 2 + 10)})
    eventNode:addChild(self.attackerAvatarIcon, 5)
    self.attackerNameLabel = display.newLabel(120, 22, {text = '', color = '#7d7372', fontSize = 20})
    eventNode:addChild(self.attackerNameLabel, 5)
    -- VS
    self.vsIcon = display.newImageView(RES_DICT.VS_ICON, size.width / 2 - 30, size.height / 2 + 20)
    self.vsIcon:setScale(0.4)
    eventNode:addChild(self.vsIcon, 5)
    self.resultLabel = display.newLabel(size.width / 2 - 30, size.height / 2 - 25, {text = '', fontSize = 20, color = '#d65540'})
    eventNode:addChild(self.resultLabel, 5)
    -- 防守方头像
    self.defenderAvatarIcon = require('common.FriendHeadNode').new({enable = true, scale = 0.6, showLevel = false})
    display.commonUIParams(self.defenderAvatarIcon, {po = cc.p(size.width - 180, size.height / 2 + 10)})
    eventNode:addChild(self.defenderAvatarIcon, 5)
    self.defenderNameLabel = display.newLabel(size.width - 180, 22, {text = '', color = '#7d7372', fontSize = 20})
    eventNode:addChild(self.defenderNameLabel, 5)
    -- 回放按钮
    -- self.replayBtn = display.newButton(size.width - 75, size.height / 2 + 10, {n = RES_DICT.REPLAY_ICON})
    -- eventNode:addChild(self.replayBtn, 5)
    self.replayTimeLabel = display.newLabel(size.width - 75, size.height / 2, {text = '', fontSize = 18, color = '#7d7372'})
    eventNode:addChild(self.replayTimeLabel, 5)
end
return FriendBattleReportCell