--[[
特殊活动 活动预览页签view
--]]
local SpActivityAnniPageView = class('SpActivityAnniPageView', function ()
    local node = CLayout:create()
    node.name = 'home.SpActivityAnniPageView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    LIST_BG      = _res('ui/home/specialActivity/anni_activity_bg_mask.png'),
    LIST_CELL_BG = _res('ui/home/specialActivity/anni_forecast_bg_list.png'),
    CELL_BTN_BG  = _res('ui/home/specialActivity/anni_forecast_bg_list.png'),
}
local CreateListCell = nil
function SpActivityAnniPageView:ctor( ... )
	local args = unpack({...})
    self.size = args.size
    self:InitUI()
end
 
function SpActivityAnniPageView:InitUI()
    local size = self.size 
    self:setContentSize(size)
    local function CreateView()
        local view = CLayout:create(size)
        local listBg = display.newImageView(RES_DICT.LIST_BG, size.width, size.height / 2, {ap = cc.p(1, 0.5)})
        view:addChild(listBg, 1) 
        local gridViewSize = cc.size(650, math.min(listBg:getContentSize().height, size.height))
        local gridViewCellSize = cc.size(gridViewSize.width, 126)
        local gridView = CGridView:create(gridViewSize)
        gridView:setAnchorPoint(cc.p(1, 0.5))
        gridView:setPosition(cc.p(size.width, size.height / 2))
        gridView:setColumns(1)
        gridView:setSizeOfCell(gridViewCellSize)
        view:addChild(gridView, 5)
        return {      
            view                 = view,
            gridView             = gridView,
        }
    end
    xTry(function ( )
        self.viewData = CreateView()
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self:addChild(self.viewData.view, 1)
	end, __G__TRACKBACK__)
end
CreateListCell = function ( size )
    local view = CGridViewCell:new()
    view:setContentSize(size)
    local bgBtn = display.newButton(size.width, size.height /2, {n  = RES_DICT.CELL_BTN_BG,ap = cc.p(1, 0.5)})
    view:addChild(bgBtn, 1)
    local img = lrequire('root.WebSprite').new({url = '', hpath = '', size = cc.size(424, 124)})
    img:setAnchorPoint(cc.p(1, 0.5))
    img:setPosition(cc.p(size.width, size.height / 2))
	view:addChild(img, 3)
    local activityTitle = display.newLabel(size.width - 130, 78, {text = '', ap = cc.p(1, 0.5), fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#000000', outlineSize = 1})
    view:addChild(activityTitle, 5)
    local timeLabel = display.newLabel(size.width - 130, 60, fontWithColor(8, {text = '', w = 260, ap = cc.p(1, 1), hAlign = cc.TEXT_ALIGNMENT_RIGHT}))
    view:addChild(timeLabel, 5)
    return {
        view           = view,
        bgBtn          = bgBtn,
        img            = img,
        activityTitle  = activityTitle,
        timeLabel      = timeLabel,
    }

end
function SpActivityAnniPageView:CreateListCell(size)
    return CreateListCell(size)
end
return SpActivityAnniPageView
