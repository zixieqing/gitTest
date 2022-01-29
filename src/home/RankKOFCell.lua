--[[
排行榜3v3试炼排行Cell
--]]
---@class RankKOFCell
local RankKOFCell = class('RankKOFCell', function ()
    local RankKOFCell = CGridViewCell:new()
    RankKOFCell.name = 'home.RankKOFCell'
    RankKOFCell:enableNodeEvents()
    return RankKOFCell
end)

function RankKOFCell:ctor( ... )
    local arg = { ... }
    local size = arg[1]
    self:setContentSize(size)
    local eventNode = display.newLayer(size.width/2 ,size.height/2 , {ap =display.CENTER , size = size  })
    self:addChild(eventNode)
    self.eventNode = eventNode
    -- bg
    self.bg = display.newImageView(_res('ui/common/common_bg_list.png'), size.width/2, size.height/2, {scale9 = true, size = cc.size(1006, 104), capInsets = cc.rect(10, 10, 482, 96)})
    self.eventNode:addChild(self.bg)
    self.rankBg = display.newImageView('ui/home/rank/restaurant_info_bg_rank_num1.png', 82, size.height/2)
    self.eventNode:addChild(self.rankBg, 5)
    self.rankNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', ' ')
    self.rankNum:setHorizontalAlignment(display.TAR)
    self.rankNum:setScale(1.4)
    self.rankNum:setPosition(82, size.height/2 - 3)
    self.eventNode:addChild(self.rankNum, 10)
    -- 头像
    self.avatarIcon = require('common.FriendHeadNode').new({
                                                               enable = true, scale = 0.6, showLevel = true
                                                           })
    display.commonUIParams(self.avatarIcon, {po = cc.p(182, size.height/2)})
    self.eventNode:addChild(self.avatarIcon, 10)

    self.nameLabel = display.newLabel(246, size.height/2, {ap = cc.p(0, 0.5), text = '', fontSize = 22, color = '#87543'})
    self.eventNode:addChild(self.nameLabel, 10)
    self.scoreBg = display.newImageView(_res('ui/home/rank/restaurant_info_bg_rank_awareness.png'), size.width - 20 , size.height/2 , {scale9 = true,ap = display.RIGHT_CENTER , size = cc.size(180,90)} )
    self.eventNode:addChild(self.scoreBg, 5)

    local scoreSize = self.scoreBg:getContentSize()
    -- 胜利的场数
    local winLabel = display.newLabel(self.scoreBg:getContentSize().width/2 ,scoreSize.height/2 , fontWithColor('14' , {fontSize = 22 ,  text = "" , color = '78564b', outline = false }))
    self.scoreBg:addChild(winLabel)
    self.winLabel = winLabel
    -- 卡牌头像
    self.cardTable = {}
    for i=1, 3 do
        local cardHeadNode = require('common.CardHeadNode').new({
                                                                    cardData = {
                                                                        cardId = 200001,
                                                                    },
                                                                    showBaseState = false,
                                                                    showActionState = false,
                                                                    showVigourState = false
                                                                })
        cardHeadNode:setScale(0.43)
        cardHeadNode:setPosition(cc.p(
                360 + 88*i, size.height/2
        ))
        cardHeadNode:setTag(i)
        local cardHeadNodeSize = cardHeadNode:getContentSize()
        local captainMark = display.newImageView(_res('ui/home/teamformation/team_ico_captain.png'), 60 , cardHeadNodeSize.height - 68 , {ap = display.CENTER_BOTTOM })
        captainMark:setScale(1.5)
        cardHeadNode:addChild(captainMark,50)
        self.eventNode:addChild(cardHeadNode, 10)
        table.insert(self.cardTable, cardHeadNode)
        cardHeadNode:setVisible(false)
    end
end
return RankKOFCell