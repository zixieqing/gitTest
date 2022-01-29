--[[
每日签到活动view
--]]
local ActivityWheelView = class('ActivityWheelView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.ActivityWheelView'
	node:enableNodeEvents()
	return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local function CreateView( self )
	local view = CLayout:create(display.size)
	local sectorNum = #self.args.content
	-- 转盘圆心
	local centerPos = cc.p(display.cx - 12, display.cy - 65)
	-- 屏蔽层
	local maskLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	maskLayer:setTouchEnabled(true)
	maskLayer:setContentSize(cc.size(600, 600))
	maskLayer:setPosition(centerPos)
	maskLayer:setAnchorPoint(0.5, 0.5)
	view:addChild(maskLayer, -1)
	-- 背景
	local bg = display.newImageView(_res('ui/home/activity/activity_turntable_bg.png'), display.cx, display.cy - 10)
	view:addChild(bg, 1)

	-- 创建扇形区域
	local angle = 360/sectorNum
	for i=1, sectorNum do
		local bgType = nil
		if i%2 == 0 then
			bgType = 1
		else
			bgType = 2
		end
		local powerBar = cc.ProgressTimer:create(cc.Sprite:create(_res('ui/home/activity/activity_turntable_bg_' .. tostring(bgType) .. '.png')))
		powerBar:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
		powerBar:setMidpoint(cc.p(0.5, 0.5))
		powerBar:setPercentage(100/sectorNum)
		powerBar:setPosition(centerPos)
		powerBar:setRotation((i-1.5)*angle)
		view:addChild(powerBar, 3)
		local rewards = self.args.content[i]
		local goodsIcon = require('common.GoodNode').new({id = rewards.rewards[1].goodsId, amount = rewards.rewards[1].num, showAmount = true, highlight = rewards.rewards[1].highlight})
		goodsIcon:setScale(1-(90-angle)/130)
		display.commonUIParams(goodsIcon, {animate = false, cb = function (sender)
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = rewards.rewards[1].goodsId, type = 1})
		end})
		local radian = math.rad((i-1)*angle)
		local radius = 160
		local goodsPos = cc.p(centerPos.x + radius*math.sin(radian), centerPos.y + radius*math.cos(radian))
		goodsIcon:setPosition(goodsPos)
		view:addChild(goodsIcon, 6)
	end

	local line = display.newImageView(_res('ui/home/activity/activity_turntable_bg_lines.png'), centerPos.x, centerPos.y)
	view:addChild(line, 5)
	local arrowIcon = display.newImageView(_res('ui/home/activity/activity_turntable_ico_arrow.png'), centerPos.x , centerPos.y)
	view:addChild(arrowIcon, 7)
	local arrowLabel = display.newLabel(centerPos.x, centerPos.y, {text = __('抽奖'), ttf = true, font = TTF_GAME_FONT, color = '#ffdc90', fontSize = 34, outline = '#392210', outlineSize = 1})
	view:addChild(arrowLabel, 10)
	local numLabel = display.newRichLabel(centerPos.x, display.cy + 197, {r = true,
		c = {fontWithColor(16, {text = __('抽奖次数：')}), fontWithColor(10, {text = tostring(self.leftDrawnTimes)})}
	})
	view:addChild(numLabel, 10)
	local timeLabel = display.newRichLabel(centerPos.x, display.cy - 334, {
		c = {}
	})
	view:addChild(timeLabel, 10)
	local tipsBtn = display.newButton(centerPos.x + 90, display.cy + 197, {n = _res('ui/common/common_btn_tips.png')})
	view:addChild(tipsBtn, 10)
	local luckyDrawBtn = display.newButton(centerPos.x, centerPos.y, {n = ''})
	luckyDrawBtn:setContentSize(cc.size(150, 150))
	view:addChild(luckyDrawBtn, 10)
	luckyDrawBtn:setOnClickScriptHandler(function()
		local rewardIndex = math.random(1, 10)
		arrowIcon:runAction(
			cc.Sequence:create(
				cc.EaseSineIn:create(
					cc.RotateBy:create(1, 1080 - arrowIcon:getRotation()%360)
				),
				cc.RotateBy:create(2, 2160),
				cc.EaseSineOut:create(
					cc.RotateBy:create(2, 720+(rewardIndex-1)*angle)
				)
			)
		)
	end)

	local dotSpine = sp.SkeletonAnimation:create('effects/activity/dian.json', 'effects/activity/dian.atlas', 1)
	dotSpine:update(0)
	dotSpine:setAnimation(0, 'idle', true)
	dotSpine:setPosition(cc.p(centerPos.x, centerPos.y - 315))
	view:addChild(dotSpine, 10)

	local lightSpine = sp.SkeletonAnimation:create('effects/activity/guang.json', 'effects/activity/guang.atlas', 1)
	lightSpine:update(0)
	lightSpine:setAnimation(0, 'idle', true)
	lightSpine:setPosition(cc.p(centerPos.x, centerPos.y - 315))
	view:addChild(lightSpine, 10)


	return {
		view 			 = view,
		luckyDrawBtn     = luckyDrawBtn,
		angle            = angle,
		arrowIcon        = arrowIcon,
		numLabel         = numLabel,
		timeLabel        = timeLabel,
		tipsBtn 	     = tipsBtn
	}
end

function ActivityWheelView:ctor( ... )
	self.args = unpack({...}) or {}
	-- 已签到次数
	self.hasDrawnTimes = checkint(self.args.hasDrawnTimes)
	-- 已抽奖次数
	self.hasWheeledTimes = checkint(self.args.hasWheeledTimes)
	-- 抽奖花费点数
	self.wheeledCircle = checkint(self.args.wheeledCircle)
	-- 剩余签到次数
	self.leftDrawnTimes = math.floor((self.hasDrawnTimes - self.hasWheeledTimes * self.wheeledCircle) / self.wheeledCircle)
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(utils.getLocalCenter(self))
	self.eaterLayer = eaterLayer
	self:addChild(eaterLayer, -1)
	self.viewData_ = CreateView( self )
	self:addChild(self.viewData_.view, 1)
	self.viewData_.view:setPosition(utils.getLocalCenter(self))
end
--[[
更新抽奖次数
--]]
function ActivityWheelView:UpdateDrawTime()
	self.hasWheeledTimes = self.hasWheeledTimes - 1
	self.leftDrawnTimes = self.leftDrawnTimes - 1
	local viewData = self.viewData_
	display.reloadRichLabel(viewData.numLabel, {c = {
		fontWithColor(16, {text = __('抽奖次数：')}),
		fontWithColor(10, {text = tostring(self.leftDrawnTimes)})
	}})

end

return ActivityWheelView
