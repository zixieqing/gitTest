--[[
每日签到活动view
--]]
local ActivityDailyBonusView = class('ActivityDailyBonusView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.ActivityDailyBonusView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local function CreateView( )
	local size = cc.size(1035, 637)
	local view = CLayout:create(size)
	-- 背景
	local bg = display.newImageView(_res('ui/home/activity/activity_bg_sign.jpg'), size.width/2, size.height/2)
	view:addChild(bg, 1)
	local topBg = display.newImageView(_res('ui/home/activity/activity_sign_title.png'), 5, size.height - 5, {ap = cc.p(0, 1)})
	view:addChild(topBg, 5)
	-- local signInLabel = display.newLabel(25, topBg:getContentSize().height/2, fontWithColor(16, {ap = cc.p(0, 0.5), text = __('本月已累计签到        天')}))
	-- topBg:addChild(signInLabel, 10)
	local signInNum = display.newRichLabel(25, topBg:getContentSize().height/2, {
            ap = display.LEFT_CENTER,
        c = {
            fontWithColor(16, {text = __('本月已累计签到')}),
            {fontSize = 30, color = '#d23d3d', text = ''}
        }
    })
	topBg:addChild(signInNum, 10)
	local timeBg = display.newImageView(_res('ui/home/activity/activity_sign_bg_refresh.png'), topBg:getContentSize().width - 2, topBg:getContentSize().height/2, {ap = cc.p(1, 0.5)})
	topBg:addChild(timeBg, 5)
	local timeLabel = display.newLabel(timeBg:getContentSize().width/2+10, timeBg:getContentSize().height/2, fontWithColor(16, {text = __('每日0点刷新') ,reqW = 190 , w = 250 , hAlign =display.TAC}))
	timeBg:addChild(timeLabel, 10)
	-- 奖励列表
	local gridViewBg = display.newImageView(_res('ui/home/activity/activity_sign_bg_reward.png'), 5, 5, {ap = cc.p(0, 0)})
	view:addChild(gridViewBg, 5)
    local gridViewSize = cc.size(600, 565)
    local gridViewCellSize = cc.size(120, 120)
    local gridView = CGridView:create(gridViewSize)
    gridView:setAnchorPoint(cc.p(0, 0))
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setPosition(cc.p(8.5, 5))
    gridView:setColumns(5)
    gridView:setAutoRelocate(true)
    view:addChild(gridView, 10)
    -- 卡牌立绘
	local clipNode = cc.ClippingNode:create()
	clipNode:setPosition(cc.p(0, 0))
	view:addChild(clipNode, 3)
	local stencilNode = display.newNSprite(_res('ui/home/activity/activity_bg_sign.jpg'), size.width/2, size.height/2)
	clipNode:setAlphaThreshold(0.1)
	clipNode:setStencil(stencilNode)

	local cardDrawNode = require('common.CardSkinDrawNode').new({coordinateType = COORDINATE_TYPE_TEAM, notRefresh = true})
	cardDrawNode:setPosition(cc.p(718, 420))
	if (display.size.width / display.size.height) <= (1024 / 768) then
		cardDrawNode:setScale(0.78)
		cardDrawNode:setPosition(cc.p(670, 325))
	else
		cardDrawNode:setScale(0.9)
    end

	clipNode:addChild(cardDrawNode)
	-- 转盘按钮
	local turntableBtn = display.newButton(969, 609, {n = _res('ui/home/activity/activity_sign_btn_turntable.png')})
	turntableBtn:setVisible(false)
	view:addChild(turntableBtn, 10)
	local turntableLabel = display.newLabel(969, 570, {fontSize = 22, color = 'ffffff', font = TTF_GAME_FONT, ttf = true, outline = '4e2e1e', outlineSize = 1, text = __('幸运大转盘')})
	view:addChild(turntableLabel, 10)
	turntableLabel:setVisible(false)
	local turntableBg = display.newImageView(_res('ui/home/activity/activity_sign_bg_rember.png'), 969, 540)
	view:addChild(turntableBg, 10)
	turntableBg:setVisible(false)
	local turntableNum = display.newRichLabel(969, 540, {})
	view:addChild(turntableNum, 10)
	turntableNum:setVisible(false)

	return {
		view 			 = view,
		turntableBtn     = turntableBtn,
		gridView         = gridView,
		signInNum        = signInNum,
		cardDrawNode     = cardDrawNode,
		turntableLabel   = turntableLabel,
		turntableNum     = turntableNum,
		turntableBg      = turntableBg
	}
end

function ActivityDailyBonusView:ctor( ... )
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
end

return ActivityDailyBonusView
