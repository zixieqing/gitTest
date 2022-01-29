--[[
活动页面Scene
--]]
local GameScene = require( "Frame.GameScene" )
local FacebookInviteView = class('FacebookInviteView', GameScene)
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function FacebookInviteView:ctor(...)
	self.super.ctor(self,'views.FacebookInviteView')
    local args = unpack({...})
    self.viewData = nil
    local function CreateView()
        local view = display.newLayer()
        self:addChild(view)

        local bg = display.newImageView(_res('arts/stage/bg/main_bg_06.jpg'), display.cx, display.cy, {isFull = true, enable1 = true})
        view:addChild(bg)

--[[         local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = _res('ui/common/common_title_new.png'),enable = false,ap = cc.p(0,1)}) ]]
        -- display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('活动'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        -- view:addChild(tabNameLabel, 10)

        local tabListLayout = CLayout:create(cc.size(250, 640))
        tabListLayout:setPosition(cc.p(display.cx - 510, display.cy - 35))
        view:addChild(tabListLayout, 10)
        local rankListBg = display.newImageView(_res('ui/home/rank/rank_bg_liebiao.png'), tabListLayout:getContentSize().width/2, tabListLayout:getContentSize().height/2)
        tabListLayout:addChild(rankListBg, 5)

        local upMask = display.newImageView(_res('ui/home/rank/rank_img_up.png'), 0, tabListLayout:getContentSize().height-2, {ap = cc.p(0, 1)})
        tabListLayout:addChild(upMask, 7)
        local downMask = display.newImageView(_res('ui/home/rank/rank_img_down.png'), 0, 1, {ap = cc.p(0, 0)})
        tabListLayout:addChild(downMask, 7)

        local gridViewSize = cc.size(212, 610)
        local gridViewCellSize = cc.size(gridViewSize.width, 88)
        local gridView = CGridView:create(gridViewSize)
        gridView:setAnchorPoint(cc.p(0.5, 0.5))
        gridView:setSizeOfCell(gridViewCellSize)
        gridView:setPosition(cc.p(115, tabListLayout:getContentSize().height/2))
        gridView:setColumns(1)
        gridView:setAutoRelocate(true)
        tabListLayout:addChild(gridView, 10)

        local ActivityLayoutSize = cc.size(1035, 637)
        ActivityLayout = CLayout:create(ActivityLayoutSize)
        ActivityLayout:setPosition(cc.p(display.cx + 120, display.cy - 35))
        view:addChild(ActivityLayout, 10)
        local rankBg = display.newImageView(_res('share/facebook_bg'), ActivityLayoutSize.width/2, ActivityLayoutSize.height/2)
        ActivityLayout:addChild(rankBg)

		return {
            view           = view,
            bg             = bg,
            -- tabNameLabel   = tabNameLabel,
            -- tabNameLabelPos = cc.p(tabNameLabel:getPosition()),
            gridView       = gridView,
            ActivityLayout = ActivityLayout
        }
    end

    self.viewData = CreateView()

    -- self.viewData.tabNameLabel:setPositionY(display.height + 100)
    -- local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, self.viewData.tabNameLabelPos))
    -- self.viewData.tabNameLabel:runAction( action )
end

return FacebookInviteView
