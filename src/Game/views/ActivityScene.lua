--[[
活动页面Scene
--]]
local GameScene = require( "Frame.GameScene" )
local ActivityScene = class('ActivityScene', GameScene)
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function ActivityScene:ctor(...)
	self.super.ctor(self,'views.ActivityScene')
    local args = unpack({...})
    self.viewData = nil
    local function CreateView()
        local view = display.newLayer()
        self:addChild(view)

        local bg = display.newImageView(_res('arts/stage/bg/main_bg_06.jpg'), display.cx, display.cy, {isFull = true, enable1 = true})
        view:addChild(bg)

        local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = _res('ui/common/common_title_new.png'),enable = false,ap = cc.p(0,1)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('活动'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        view:addChild(tabNameLabel, 10)

        local tabListLayout = CLayout:create(cc.size(250, 640))
        tabListLayout:setPosition(cc.p(display.cx - 510, display.cy - 35))
        view:addChild(tabListLayout, 10)
        
        local activityTabView = require('Game.views.activity.ActivityTabView').new()
        activityTabView:setPosition(cc.p(110, 320))
        tabListLayout:addChild(activityTabView, 100)
        
        local ActivityLayoutSize = cc.size(1035, 637)
        local ActivityLayout = CLayout:create(ActivityLayoutSize)
        ActivityLayout:setPosition(cc.p(display.cx + 120, display.cy - 35))
        view:addChild(ActivityLayout, 10)
        local rankBg = display.newImageView(_res('ui/common/common_rank_bg.png'), ActivityLayoutSize.width/2, ActivityLayoutSize.height/2)
        ActivityLayout:addChild(rankBg)

        local tipsBtn = display.newButton(display.cx - 370, display.cy + 260, {n = _res('ui/common/common_btn_tips')})
        view:addChild(tipsBtn, 10)
        tipsBtn:setVisible(false)

		return { 
            view            = view,
            bg              = bg,
            tabNameLabel    = tabNameLabel,
            tabNameLabelPos = cc.p(tabNameLabel:getPosition()),
            gridView        = gridView,
            ActivityLayout  = ActivityLayout,
            activityTabView = activityTabView,
        }
    end

    self.viewData = CreateView()

    self.viewData.tabNameLabel:setPositionY(display.height + 100)
    local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, self.viewData.tabNameLabelPos))
    self.viewData.tabNameLabel:runAction( action )
end

function ActivityScene:onCleanup()
end

return ActivityScene