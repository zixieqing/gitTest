
---
--- Created by xingweihao.
--- DateTime: 20/11/2017 1:32 PM
---

local GameScene = require( 'Frame.GameScene' )
---@class MaterialTranScriptView :GameScene
local MaterialTranScriptView = class('MaterialTranScriptView', GameScene)
function MaterialTranScriptView:ctor(param)
    self.super.ctor(self,'home.MaterialTranScriptView')
    local swallowLayer = display.newLayer(display.cx , display.cy , { ap = display.CENTER , size = display.size , color  = cc.c4b(0,0,0,0) ,enable = true })
    self:addChild(swallowLayer)
    -- 背景图片
    local bgImage = display.newImageView(_res('ui/home/materialScript/material_bg') , display.cx, display.cy)
    self:addChild(bgImage)
    local tableSize  =  cc.size(display.SAFE_RECT.width, 680)
    local tableView = CTableView:create(tableSize)
    tableView:setSizeOfCell(cc.size(404, 680))
    tableView:setAutoRelocate(true)
    tableView:setDirection(eScrollViewDirectionHorizontal)
    tableView:setCountOfCell(0)
    tableView:setPosition(display.center)
    tableView:setAnchorPoint(cc.p(0.5,0.5))
    -- back button
    local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
    backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
    self:addChild(backBtn, 5)
    self:addChild(tableView)
    self.viewData =  {
        tableView = tableView ,
        swallowLayer = swallowLayer ,
        navBack = backBtn
    }
end

return MaterialTranScriptView