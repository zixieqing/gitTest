--[[
季活免费开门炮的
--]]
---@class ActivitySeasonWelfareView
local ActivitySeasonWelfareView = class('ActivitySeasonWelfareView', function ()
    local node = CLayout:create(display.size)
    node:setAnchorPoint(cc.p(0.5, 0.5))
    node.name = 'home.ActivitySeasonWelfareView'
    node:enableNodeEvents()
    return node
end)
 function ActivitySeasonWelfareView:CreateView( )
    -- 关闭界面
    local  closeLayout =   display.newLayer(display.cx,display.cy,
                                            { ap = display.CENTER , color=  cc.c4b(0,0,0,170) , enable = true })
    self:addChild(closeLayout)
    local size = cc.size(753,541)
    local view = CLayout:create(size)
    -- 吞噬层
    local swallowLayout = display.newLayer(size.width/2 , size.height/2 , { ap = display.CENTER , size = size ,color=  cc.c4b(0,0,0,0) , enable = true })
    view:addChild(swallowLayout)

    -- 背景
    local bg = display.newImageView(_res('ui/home/activity/seasonlive/season_ticket_bg.png'), size.width/2, size.height/2)
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

function ActivitySeasonWelfareView:ctor( ... )
    self.viewData_ =self:CreateView()
    self:addChild(self.viewData_.view, 1)
    self.viewData_.view:setPosition(utils.getLocalCenter(self))
end
return ActivitySeasonWelfareView