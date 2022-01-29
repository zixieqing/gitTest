---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by pengjixian.
--- DateTime: 2018/10/29 2:35 PM
---
local RankSaiMoeTypeCell = class('NewRankCell', function ()
    local RankSaiMoeTypeCell = CExpandableNode:new()
    RankSaiMoeTypeCell.name = 'home.RankSaiMoeTypeCell'
    RankSaiMoeTypeCell:enableNodeEvents()
    return RankSaiMoeTypeCell
end)

function RankSaiMoeTypeCell:ctor( ... )
    local arg = { ... }
    local size = arg[1]
    self.childNode = nil
    self:setContentSize(size)
    local maskLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
    maskLayer:setTouchEnabled(true)
    maskLayer:setContentSize(size)
    maskLayer:setPosition(utils.getLocalCenter(self))
    maskLayer:setAnchorPoint(0.5, 0.5)
    self:addChild(maskLayer, -1)
    self.buttonLayout = display.newLayer(0,0,{size = cc.size(size.width, 78), enable = true, color = cc.r4b(0), ap = cc.p(0.5, 0.5)})
    self.buttonLayout:setPosition(cc.p(size.width/2, size.height - 50))
    self:addChild(self.buttonLayout, 10)
    self.selectedImg = display.newImageView(_res('ui/home/rank/rank_btn_tab_select.png'), size.width/2, 39)
    self.buttonLayout:addChild(self.selectedImg, 10)
    self.selectedImg:setVisible(false)
    self.unselectedImg = display.newImageView(_res('ui/home/rank/rank_btn_tab_default.png'), size.width/2, 39)
    self.buttonLayout:addChild(self.unselectedImg, 10)
    self.nameLabel = display.newLabel(size.width/2, 39, fontWithColor(14, {text = ''}))
    self.buttonLayout:addChild(self.nameLabel, 10)
    self.arrowIcon = display.newImageView(_res('ui/home/rank/rank_ico_arrow.png'), 180, 39)
    self.arrowIcon:setRotation(270)
    self.buttonLayout:addChild(self.arrowIcon, 10)
    self.arrowIcon:setVisible(false)
end

return RankSaiMoeTypeCell