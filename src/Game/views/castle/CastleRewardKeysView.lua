--[[
季活免费开门炮的
--]]
---@class CastleRewardKeysView
local CastleRewardKeysView = class('CastleRewardKeysView', function ()
    local node = CLayout:create(display.size)
    node:setAnchorPoint(cc.p(0.5, 0.5))
    node.name = 'home.CastleRewardKeysView'
    node:enableNodeEvents()
    return node
end)
function CastleRewardKeysView:CreateView( )
    -- 关闭界面
    local  closeLayout =   display.newLayer(display.cx,display.cy,
                                            { ap = display.CENTER , color=  cc.c4b(0,0,0,170) , enable = true })
    self:addChild(closeLayout)
    local size = cc.size(850  ,570)
    local view = CLayout:create(size)
    -- 吞噬层
    local swallowLayout = display.newLayer(size.width/2 , size.height/2 , { ap = display.CENTER , size = size ,color=  cc.c4b(0,0,0,0) , enable = true })
    view:addChild(swallowLayout)
    local closeLabel = display.newLabel(size.width/2 , 5 , {ap = display.CENTER_TOP , text = app.activityMgr:GetCastleText(__('点击任意空白处关闭')) , color = "#ffffff" , fontSize = 20 })
    view:addChild(closeLabel)
    -- 背景
    local bg = display.newImageView(app.activityMgr:CastleResEx('ui/castle/common/castle_bg_common_board.png'), size.width/2, size.height/2,{
        size = size , scale9 = true ,capInsets = cc.rect(120, 120, 30, 30)
    })
    view:addChild(bg, 1)


    -- 活动规则
    local gridViewSize = cc.size(672, 482)
    local gridViewCellSize = cc.size(224, 482)
    local gridView = CTableView:create(gridViewSize)
    gridView:setAnchorPoint(display.CENTER)
    gridView:setDirection(eScrollViewDirectionHorizontal)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setPosition(cc.p(size.width/2, size.height/2))
    gridView:setBounceable(false)
    gridView:setAutoRelocate(true)
    view:addChild(gridView, 10)
    return {
        view 	  = view,
        closeLayout = closeLayout ,
        gridView  = gridView
    }
end

function CastleRewardKeysView:ctor( ... )
    self.viewData_ =self:CreateView()
    self:addChild(self.viewData_.view, 1)
    self.viewData_.view:setPosition(utils.getLocalCenter(self))
end
return CastleRewardKeysView
