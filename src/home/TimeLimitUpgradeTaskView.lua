--[[
    限时升级任务
--]]

---@class TimeLimitUpgradeTaskView
local TimeLimitUpgradeTaskView = class('TimeLimitUpgradeTaskView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.TimeLimitUpgradeTaskView'
	node:enableNodeEvents()
	return node
end)

local CreateView, CreateFunctionButton, CreateGoodNode
local display = display
local app = app

local RES_DICT = {
	COMMON_BG_7       = _res('ui/common/common_bg_7.png'),
	COMMON_BG_TITLE_2 = _res('ui/common/common_bg_title_2.png'),
	COMMON_BG_TIME    = _res('ui/common/common_bg_time.png'),
	COMMON_BG_REWARD  = _res('ui/common/common_bg_reward.png'),
	COMMON_BG_REWARD1 = _res('ui/common/common_bg_reward1.png'),
	COMMON_BG_REWARD2 = _res('ui/common/common_bg_reward2.png'),
	ALPHA_IMAGE       = _res('ui/common/story_tranparent_bg.png'),
}

function TimeLimitUpgradeTaskView:ctor( ... )
	self.args = unpack({...}) or {}
	self.isControllable_ = true

	local curKey = app.activityMgr:GetTimeLimitUpgradeConfKey()
	if curKey > 0 then
		local key = app.activityMgr:GetTimeLimitUpgradeTaskLocalKey(curKey)
		cc.UserDefault:getInstance():setBoolForKey(key, true)
		cc.UserDefault:getInstance():flush()
	end

	xTry(function ( )
		self.viewData_ = CreateView()
		display.commonUIParams(self.viewData_.view, {po = display.center, ap = display.CENTER})
		self:addChild(self.viewData_.view)

		self:InitView_()
		self:RefreshUI()
		
	end, __G__TRACKBACK__)

	app:RegistObserver(COUNT_DOWN_ACTION, mvc.Observer.new(self.OnTimerCountdownHandler_, self))

end
	

function TimeLimitUpgradeTaskView:onCleanup()
	app:DispatchObservers(SGL.HANDLER_UPGRADE_LEVEL_POP, {isFromHomeMdt = self.args.isFromHomeMdt})
    app:UnRegistObserver(COUNT_DOWN_ACTION, self)
end

function TimeLimitUpgradeTaskView:InitData_()
	local level = app.gameMgr:GetUserInfo().level
	local timeLimitLvUpgradeConf = CommonUtils.GetConfigAllMess("timeLimitLvUpgrade", "activity")

	local curKey = -1
	for key, value in pairs(timeLimitLvUpgradeConf) do
		local startLv = checkint(value.startLv)
		if level >= startLv then
			curKey = math.max(curKey, startLv)
		end
	end	

	return timeLimitLvUpgradeConf[tostring(curKey)] or {}
end

function TimeLimitUpgradeTaskView:InitView_()
	local viewData = self:GetViewData()
	display.commonUIParams(viewData.closeLayer, {cb = handler(self, self.OnClickCloseLayerAction), animate = false})
end

function TimeLimitUpgradeTaskView:RefreshUI()
	local data = self:InitData_()
	local viewData = self:GetViewData()
	
	local textList = string.split(__("升至|_level_|级获|_bonus_|"), '|')
	local richText = {}
	for key, text in ipairs(textList) do
		if text == "_level_" then
			table.insert(richText, {fontSize = 40, color = '#f14e22', text = tostring(data.targetLv)})
		elseif text == "_bonus_" then
			table.insert(richText, {fontSize = 34, color = '#f14e22', text = __('超豪华礼物！')})
		else
			table.insert(richText, {fontSize = 34, color = '#5b3c25', text = text})
		end
	end	

	display.reloadRichLabel(viewData.targetLevelDescLabel, {c = richText})
	
	--- 更新奖励
	self:UpdateRewardLayer_(viewData, data)


	self:UpdateSuggestTipLayer_(viewData, data)

end

---UpdateRewardLayer_
---@param viewData table 视图数据
---@param data table  activity/timeLimitLvUpgrade 配表数据
function TimeLimitUpgradeTaskView:UpdateRewardLayer_(viewData, data)
    local rewardLayer      = viewData.rewardLayer
    local rewardNodes      = viewData.rewardNodes
    local rewards          = data.rewards or {}
    local rewardCount      = #rewards
    local maxCount = math.max(rewardCount, #rewardNodes)
    local rewardLayerSize = rewardLayer:getContentSize()
    for i = 1, maxCount do
        local reward = rewards[i]
        local rewardNode = rewardNodes[i]
        
        if reward then
            if rewardNode then
                rewardNode:setVisible(true)
                rewardNode:RefreshSelf(reward)
            else
                rewardNode = CreateGoodNode(reward)
                rewardLayer:addChild(rewardNode)
                table.insert(rewardNodes, rewardNode)
            end
            display.commonUIParams(rewardNode, {ap = display.LEFT_CENTER, po = cc.p(36 + (i - 1) * 158, rewardLayerSize.height * 0.5)})
        elseif rewardNode then
            rewardNode:setVisible(false)
        end
    end
end

function TimeLimitUpgradeTaskView:UpdateCountDown(viewData, leftTime)
	display.commonLabelParams(viewData.countDownLabel, {text = CommonUtils.getTimeFormatByType(leftTime, 2)})
end

---UpdateSuggestTipLayer_
---更新提示层
---@param viewData table 视图数据
---@param data table  activity/timeLimitLvUpgrade 配表数据
function TimeLimitUpgradeTaskView:UpdateSuggestTipLayer_(viewData, data)
	local opentaye        = data.opentaye or {}
	local suggestTipLayer = viewData.suggestTipLayer
	local functionBtns = viewData.functionBtns
	local suggestTipLayerSize = suggestTipLayer:getContentSize()
	local startX = suggestTipLayerSize.width - 72
	local moduleConfig = CommonUtils.GetConfigAllMess('module')

	local showCount = 1
	for index = 1, #opentaye do
		local moduleType = opentaye[index]
		local moduleOneConfig = moduleConfig[tostring(moduleType)]
		local functionBtn = functionBtns[index]

		if moduleOneConfig then
			if functionBtn then
				functionBtn.view:setVisible(true)
				functionBtn.view:setTag(checkint(moduleOneConfig.id))
				functionBtn.normalImg:setTexture(_res(string.format('ui/home/levelupgrade/unlockmodule/%s', tostring(moduleOneConfig.iconID))))
				display.commonLabelParams(functionBtn.nameLabel, {text = tostring(moduleOneConfig.name)})
			else
				functionBtn = CreateFunctionButton(moduleOneConfig)
				display.commonUIParams(functionBtn.view, {ap = display.RIGHT_CENTER, po = cc.p(startX - (showCount - 1) * 150, suggestTipLayerSize.height * 0.5)})
				suggestTipLayer:addChild(functionBtn.view)
		
				table.insert(functionBtns, functionBtn)
			end
			showCount = showCount + 1
		elseif functionBtn then
			functionBtn.view:setVisible(false)
		end

	end
	
end

CreateView = function ()
	local view = display.newLayer()
	local size = view:getContentSize()

	local closeLayer = display.newLayer(0, 0,{size = size, color = cc.c4b(0,0,0,130), ap = display.LEFT_BOTTOM, enable = true})
    view:addChild(closeLayer)

	--------------------------------------
	--- 背景和标题相关UI
	local bgSize = cc.size(724, 540)
	local bgLayer = display.newLayer(size.width * 0.5, size.height * 0.5, {size = bgSize, ap = display.CENTER})
	view:addChild(bgLayer)
	

	local blockLayer = display.newLayer(0, 0, {color = cc.c4b(0,0,0,0), enable = true, size = bgSize})
	bgLayer:addChild(blockLayer)

	local bg = display.newImageView(RES_DICT.COMMON_BG_7, bgSize.width * 0.5, bgSize.height * 0.5, {ap = display.CENTER, scale9 = true, size = bgSize})
	bgLayer:addChild(bg)

	-- 标题
	local title = display.newButton(bgSize.width * 0.5, bgSize.height - 20, {n = RES_DICT.COMMON_BG_TITLE_2, enable = false})
	display.commonLabelParams(title, fontWithColor(7, {text = __('等级奖励'), fontSize = 24, offset = cc.p(0, -2)}))
	bgLayer:addChild(title)

	--- 背景和标题相关UI
	--------------------------------------

	--------------------------------------
	--- 内容相关UI
	local layerSize = cc.size(679, 494)
	local middleX, middleY = layerSize.width * 0.5, layerSize.height * 0.5
	local layer = display.newLayer(bgSize.width * 0.5, 0, {size = layerSize, ap = display.CENTER_BOTTOM})
	bgLayer:addChild(layer)

	local targetLevelDescLabel = display.newRichLabel(middleX, layerSize.height - 40, {ap = display.CENTER})
	layer:addChild(targetLevelDescLabel)

	--------------------------------------
	--- 奖励相关UI
	local rewardBgLayerSize = cc.size(657, 230)
	local rewardBgLayer = display.newLayer(middleX, 400, {size = rewardBgLayerSize, ap = display.CENTER_TOP})
	layer:addChild(rewardBgLayer)

	local rewardBg = display.newImageView(RES_DICT.COMMON_BG_REWARD, rewardBgLayerSize.width * 0.5, rewardBgLayerSize.height * 0.5, {ap = display.CENTER})
	rewardBgLayer:addChild(rewardBg)

	local rewardLayer = display.newLayer(rewardBgLayerSize.width * 0.5, rewardBgLayerSize.height - 30, {size = cc.size(657, 120), ap = display.CENTER_TOP})
	rewardBgLayer:addChild(rewardLayer)

	local countDownBg = display.newNSprite(RES_DICT.COMMON_BG_TIME, 657, 230, {ap = display.RIGHT_CENTER})
	rewardBgLayer:addChild(countDownBg)

	local countDownTipLabel = display.newLabel(120, 17, {ap = display.RIGHT_CENTER, fontSize = 20, color = '#5b3c25', text = __('剩余时间:')})
	countDownBg:addChild(countDownTipLabel)

	local countDownLabel = display.newLabel(122, 17, {ap = display.LEFT_CENTER, fontSize = 22, color = '#d23d3d', text = '00:00:00'})
	countDownBg:addChild(countDownLabel)

	-- todo
	-- local tempLayer = display.newLayer(rewardBgLayerSize.width * 0.5, 0, {size = cc.size(rewardBgLayerSize.width, 50), color = cc.c3b(100,100,100), ap = display.CENTER_BOTTOM})
	-- rewardBgLayer:addChild(tempLayer)
	
	local tipBg = display.newImageView(RES_DICT.COMMON_BG_REWARD2, rewardBgLayerSize.width * 0.5, 0, {size = cc.size(rewardBgLayerSize.width, 50), scale9 = true, ap = display.CENTER_BOTTOM})
	rewardBgLayer:addChild(tipBg)

	local tipLabel = display.newLabel(rewardBgLayerSize.width * 0.5, 25, {fontSize = 24, color = '#5b3c25'})
	rewardBgLayer:addChild(tipLabel)

	local suggestTipLayerSize = cc.size(rewardBgLayerSize.width, 132)
	local suggestTipLayer = display.newLayer(middleX, 28, {size = suggestTipLayerSize, ap = display.CENTER_BOTTOM})
	layer:addChild(suggestTipLayer)

	local suggestTipBg = display.newImageView(RES_DICT.COMMON_BG_REWARD1, suggestTipLayerSize.width * 0.5, suggestTipLayerSize.height * 0.5)
	suggestTipLayer:addChild(suggestTipBg)

	local suggestTipLabel = display.newLabel(72, suggestTipLayerSize.height * 0.5, {
		w = 240, ap = display.LEFT_CENTER, text = __('当前升级建议:'), fontSize = 26, color = '#5b3c25'
	})
	suggestTipLayer:addChild(suggestTipLabel)

	--- 奖励相关UI
	--------------------------------------

	--- 内容相关UI
	--------------------------------------
	return {
		view                 = view,
		closeLayer           = closeLayer,
		bgLayer              = bgLayer,
		targetLevelDescLabel = targetLevelDescLabel,
		rewardBgLayer          = rewardBgLayer,
		rewardLayer          = rewardLayer,
		tipLabel             = tipLabel,
		countDownLabel       = countDownLabel,
		suggestTipLayer      = suggestTipLayer,

		rewardNodes            = {},
		functionBtns         = {},
	}
end

CreateFunctionButton = function(moduleConfig)
    local size = cc.size(130, 98)
    local view = display.newButton(0, 0, {n = RES_DICT.ALPHA_IMAGE, scale9 = true, size = size})
    view:setTag(checkint(moduleConfig.id))
	
	local normalImg    = display.newImageView(_res(string.format('ui/home/levelupgrade/unlockmodule/%s', tostring(moduleConfig.iconID))), size.width/2, size.height * 0.5 + 10, {scale = scale, ap = display.CENTER})
	normalImg:setScale(0.6)
	view:addChild(normalImg)

    local nameLabel = display.newLabel(size.width/2, 5, fontWithColor(20, {text = checkstr(moduleConfig.name), fontSize = 22}))
    view:addChild(nameLabel)

    return {
        view       = view,
		normalImg  = normalImg,
		nameLabel  = nameLabel,
    }
end

CreateGoodNode = function (reward)
    local goodNode = require('common.GoodNode').new({id = reward.goodsId, amount = reward.num, showAmount = true, callBack = function (sender)
        app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
    end})
    -- goodNode:setScale(0.8)
    return goodNode
end

function TimeLimitUpgradeTaskView:OnTimerCountdownHandler_(signal)
	local dataBody     = signal:GetBody() or {}
	local timerTag     = dataBody.tag
	local timerName    = tostring(dataBody.timerName)
	if timerName == 'BTN_LEVEL_TASK' then
		self:UpdateCountDown(self:GetViewData(), dataBody.countdown)
	end
end

function TimeLimitUpgradeTaskView:OnClickCloseLayerAction(sender)
	if not self.isControllable_ then return end
	self.isControllable_ = false
	sender:setTouchEnabled(false)
	
	local pos = self.args.pos
	local dt = 0.3
	local bgLayerAction_
	if pos then
		bgLayerAction_ = cc.Spawn:create({
			cc.ScaleTo:create(dt, 0, 0),
			cc.MoveTo:create(dt, pos)
		})
	else
		bgLayerAction_ = cc.ScaleTo:create(dt, 0, 0)
	end
	local viewData = self:GetViewData()
	local bgLayer = viewData.bgLayer
	self:runAction(cc.Sequence:create({
		cc.TargetedAction:create(bgLayer, bgLayerAction_),
		cc.Hide:create(),
		cc.SafeRemoveSelf:create(self)
	}))
end


function TimeLimitUpgradeTaskView:GetViewData()
	return self.viewData_
end

return TimeLimitUpgradeTaskView
