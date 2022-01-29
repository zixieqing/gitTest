--[[
常驻单笔充值活动view
--]]
local ActivityPermanentSinglePayView = class('ActivityPermanentSinglePayView', function ()
	local node = CLayout:create(cc.size(1035, 637))
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'home.ActivityPermanentSinglePayView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local function CreateView( )
	local size = cc.size(1035, 637)
	local view = CLayout:create(size)
	-- 背景
	local bg = display.newImageView(_res('ui/home/activity/activity_bg_novice_recharge.jpg'), size.width/2, size.height/2)
	view:addChild(bg, 1)
	-- 时间
	local timeBg = display.newImageView(_res('ui/home/activity/activity_time_bg.png'), 1030, 600, {ap = display.RIGHT_CENTER, scale9 = true, size = isKoreanSdk() and cc.size(268 ,47) or cc.size(400 ,47)})
	local timeBgSize = timeBg:getContentSize()
	view:addChild(timeBg, 5)
	local timeTitleLabel = display.newLabel(25, timeBgSize.height / 2, fontWithColor(18, {text = __('剩余时间:'), ap = display.LEFT_CENTER}))
	local timeTitleLabelSize = display.getLabelContentSize(timeTitleLabel)
	timeBg:addChild(timeTitleLabel, 10)
	local timeLabel = display.newLabel(timeTitleLabel:getPositionX() + timeTitleLabelSize.width + 5, timeTitleLabel:getPositionY(), {text = '', ap = cc.p(0, 0.5), fontSize = 24, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1})
	timeBg:addChild(timeLabel, 10)
    -- 按钮
    local btnBg = display.newImageView(_res('ui/home/activity/novice_recharge_btn_bg.png'), size.width/2, 75)
    view:addChild(btnBg, 3) 
    local btn = display.newButton(size.width/2, 75, {n = _res('ui/common/common_btn_orange.png')})
	view:addChild(btn, 5)
	display.commonLabelParams(btn, fontWithColor(14, {text = __("前 往")}))
	return {
        view 			 = view,
		btn              = btn,
		timeLabel        = timeLabel,
		timeTitleLabel   = timeTitleLabel,
	}
end

function ActivityPermanentSinglePayView:ctor( ... )
	self.viewData_ = CreateView()
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
end

return ActivityPermanentSinglePayView