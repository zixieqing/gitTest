--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）调查Scene
--]]
local GameScene = require('Frame.GameScene')
local MurderInvestigationView = class('MurderInvestigationView', GameScene)
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local RES_DICT = {
	BACK_BTN                        = app.murderMgr:GetResPath("ui/common/common_btn_back"),
	INVESTIGATION_BG 				= app.murderMgr:GetResPath('ui/home/activity/murder/murder_boss_bg.png'),
	MONEY_INFO_BAR       		    = app.murderMgr:GetResPath('ui/home/nmain/main_bg_money.png'),
	TASK_BG  	 	 	 	 	    = app.murderMgr:GetResPath('ui/home/story/task_bg.png'),
	BOSS_REWARDS_BG	 	 	 	 	= app.murderMgr:GetResPath('ui/home/activity/murder/murder_boss_bg_rewards.png'),
	POINT_PROGRESSBAR_BG 	 	    = app.murderMgr:GetResPath('ui/home/activity/murder/murder_boss_rewards_bar_grey.png'),
	POINT_PROGRESSBAR    	 	    = app.murderMgr:GetResPath('ui/home/activity/murder/murder_boss_rewards_bar_active.png'),
	GIFT_ICON   	 	 	        = app.murderMgr:GetResPath('ui/home/activity/murder/murder_boss_ico_rewards.png'),
	LIST_LINE 	 	 	 	 	 	= app.murderMgr:GetResPath('ui/home/activity/murder/murder_boss_list_line.png'),
	LIST_LABEL_BG_DEFAULT 	 	    = app.murderMgr:GetResPath('ui/home/activity/murder/murder_boss_list_label_default.png'),
	LIST_LABEL_BG_SELECTED 	 	    = app.murderMgr:GetResPath('ui/home/activity/murder/murder_boss_list_label_selected.png'),
	LIST_SELECTED_BG	 	 	    = app.murderMgr:GetResPath('ui/home/activity/murder/murder_boss_list_frame_selected.png'),
	INVESTIGATION_BUTTON  	 	 	= app.murderMgr:GetResPath('ui/home/activity/murder/murder_boss_btn_go.png'),
	CHECKBOX_SELECTED 	 	 	 	= app.murderMgr:GetResPath('ui/home/activity/murder/tower_ico_mark_active.png'),
	CHECKBOX_UNSELECTED 	 	 	= app.murderMgr:GetResPath('ui/home/activity/murder/tower_ico_mark_unactive.png'),
	BUFF_BG	 	 	 	 	 	 	= app.murderMgr:GetResPath('ui/home/activity/murder/murder_boss_bg_buff.png'),
	BUFF_ICON  	 	 	 	 	    = app.murderMgr:GetResPath('ui/home/activity/murder/buffIcon/murder_main_clock_ico_buff_1.png'),
	DIALOG_BG	 	 	 	 	 	= app.murderMgr:GetResPath('arts/stage/ui/dialogue_bg_2.png'),
	DEBUG_BTN 	 	 	 	 	    = app.murderMgr:GetResPath('ui/common/common_btn_orange_big.png'),
}
function MurderInvestigationView:ctor( ... )
	local args = unpack({...})
	self:InitUI()
end
--[[
初始化ui
--]]
function MurderInvestigationView:InitUI()
	local CreateView = function ()
		local size = display.size
		local view = CLayout:create(size)
		view:setPosition(size.width / 2, size.height / 2)
		-- 背景
		local bg = display.newImageView(RES_DICT.INVESTIGATION_BG, size.width / 2, size.height / 2)
		view:addChild(bg, 1)
		-- 角色立绘
		local cardDraw = require( "common.CardSkinDrawNode" ).new({confId = 200001, coordinateType = COORDINATE_TYPE_CAPSULE})
		cardDraw:setPositionX(50 + display.SAFE_L)
		view:addChild(cardDraw, 2)
		-- 对话框
		local cardDialog = display.newImageView(RES_DICT.DIALOG_BG, 400 + display.SAFE_L, display.cy - 200)
		view:addChild(cardDialog, 10)
		local dialogTextLabel = display.newLabel(50, 160, {text = '', fontSize = 24, color = '#542626', w = 600, ap = display.LEFT_TOP})
		cardDialog:addChild(dialogTextLabel, 1)
		-- taskLayout
		local taskLayoutSize = cc.size(580, 650)
		local taskLayout = CLayout:create(taskLayoutSize)
		display.commonUIParams(taskLayout, {po = cc.p(size.width - display.SAFE_L, size.height / 2 - 40), ap = display.RIGHT_CENTER})
		view:addChild(taskLayout, 5)
		local taskBg = display.newImageView(RES_DICT.TASK_BG, 0, taskLayoutSize.height / 2, {ap = display.LEFT_CENTER})
		taskLayout:addChild(taskBg, 1) 
		-- 全服点数
		local rewardsBg = display.newImageView(RES_DICT.BOSS_REWARDS_BG,taskLayoutSize.width / 2 - 40, taskLayoutSize.height + 40, {scale9 = true  , size = cc.size(587, 210), ap = display.CENTER_TOP})
		taskLayout:addChild(rewardsBg, 3)
		local progressBar = CProgressBar:create(RES_DICT.POINT_PROGRESSBAR)
		progressBar:setBackgroundImage(RES_DICT.POINT_PROGRESSBAR_BG)
		progressBar:setDirection(eProgressBarDirectionLeftToRight)
		progressBar:setAnchorPoint(cc.p(0.5, 0.5))
		progressBar:setPosition(cc.p(290, 125))
		rewardsBg:addChild(progressBar,1)
		local progressBarLabel = display.newLabel(300, 125, {text = '0/0', fontSize = 20, color = '#ffffff'})
		rewardsBg:addChild(progressBarLabel, 1)
		local giftBtn = display.newButton(taskLayoutSize.width - 110, taskLayoutSize.height - 45, {n = RES_DICT.GIFT_ICON})
		taskLayout:addChild(giftBtn, 3)
		local rewardDescr = display.newLabel(60, 105, {text = '', fontSize = 20, color = '#ffedd9', ap = display.LEFT_TOP, w = 400, reqH = 55})
		rewardsBg:addChild(rewardDescr, 3)
		-- 选择难度
		local choiceDifficultyLabel = display.newLabel(55, 465, {text = app.murderMgr:GetPoText(__('选择调查难度')), fontSize = 22, color = '#a35f29', ap = display.LEFT_CENTER})
		taskLayout:addChild(choiceDifficultyLabel, 3)
		local costLabel = display.newLabel(460, 465, {text = app.murderMgr:GetPoText(__('消耗')), fontSize = 22, color = '#a35f29', ap = display.RIGHT_CENTER})
		taskLayout:addChild(costLabel, 3)
		local btnList = {}
		for i = 1, 4 do
			local line = display.newImageView(RES_DICT.LIST_LINE, 260, 435 - (i - 1) * 80)
			taskLayout:addChild(line, 1)
			local difficulty = {
				app.murderMgr:GetPoText(__('简单')),
				app.murderMgr:GetPoText(__('普通')),
				app.murderMgr:GetPoText(__('困难'))
			}
			if i == 4 then break end
			local nameBg = display.newImageView(RES_DICT.LIST_LABEL_BG_DEFAULT, 105, 402 - (i - 1) * 80, {ap = display.LEFT_CENTER})
			taskLayout:addChild(nameBg, 2)
			local nameLabel = display.newLabel(110, 402 - (i - 1) * 80, {text = difficulty[i], fontSize = 22, color = '#5e301a', ap = display.LEFT_CENTER})
			taskLayout:addChild(nameLabel, 3)
			local descrLabel = display.newLabel(110, 372 - (i - 1) * 80, {text = '', fontSize = 20, color = '#ffbd72', ap = cc.p(0, 0.5)})
			taskLayout:addChild(descrLabel, 3)
			local costNum = CLabelBMFont:create(1, 'font/small/common_text_num.fnt')
			costNum:setBMFontSize(22)
			costNum:setAnchorPoint(display.RIGHT_CENTER)
			costNum:setPosition(cc.p(430, 402 - (i - 1) * 80))
			taskLayout:addChild(costNum, 3)
			local goodsIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(app.murderMgr:GetMurderGoodsIdByKey("murder_ticket_id")),450, 402 - (i - 1) * 80)
			taskLayout:addChild(goodsIcon, 3)
			goodsIcon:setScale(0.18)
			local selectedBg = display.newImageView(RES_DICT.LIST_SELECTED_BG, 260, 395 - (i - 1) * 80)
			selectedBg:setVisible(false)
			taskLayout:addChild(selectedBg, 1)
			local button = display.newButton(260, 395 - (i - 1) * 80, {n = 'empty', size = cc.size(442, 80)})
			taskLayout:addChild(button, 3)
			button:setTag(i)
			local checkbox = display.newImageView(RES_DICT.CHECKBOX_SELECTED, 80, 398 - (i - 1) * 80)
			taskLayout:addChild(checkbox, 3)
			local btnComponent = {
				nameLabel = nameLabel,
				descrLabel = descrLabel,
				costNum = costNum,
				goodsIcon = goodsIcon,
				selectedBg = selectedBg,
				button = button,
				checkbox = checkbox,
			}
			table.insert(btnList, btnComponent)
		end
		-- 调查按钮
		local investigationBtn = display.newButton(240, 135, {n = RES_DICT.INVESTIGATION_BUTTON})
		taskLayout:addChild(investigationBtn, 3)
		display.commonLabelParams(investigationBtn, {text = app.murderMgr:GetPoText(__('调查')), fontSize = 30, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#643126', outlineSize = 2, offset = cc.p(20, -6)})
		
		-- buff
		local buffBg = display.newImageView(RES_DICT.BUFF_BG, display.SAFE_L, size.height - 55, {ap = display.LEFT_CENTER})
		view:addChild(buffBg, 3)
		local buffIcon = display.newImageView(RES_DICT.BUFF_ICON, 200, buffBg:getContentSize().height / 2)
		buffIcon:setScale(0.7)
		buffBg:addChild(buffIcon, 1) 
		local buffDescrLabel = display.newLabel(245, buffBg:getContentSize().height - 30, {text = app.murderMgr:GetPoText(__('写着证据的卷宗掉落UP！')), fontSize = 20, color = '#ffffff', ap = display.LEFT_CENTER})
		buffBg:addChild(buffDescrLabel, 1)
		local buffNumLabel = display.newRichLabel(245, 30, {
			ap = display.LEFT_CENTER,
		})
		buffBg:addChild(buffNumLabel, 1)
		-- debug
		local debugBtn = nil 
		if DEBUG > 0 then
			debugBtn = display.newButton(260, 50,
			{
				ap = display.CENTER,
				n = RES_DICT.DEBUG_BTN, 
			})
			display.commonLabelParams(debugBtn, fontWithColor(14, 
			{
				text = '秋秋专用',
				ap = display.CENTER,
				fontSize = 26,
				color = '#ffffff',
				font = TTF_GAME_FONT, ttf = true,
				outline = '#5b3c25',
			}))
			taskLayout:addChild(debugBtn, 10)
		end
		-- top ui layer
		local topUILayer = display.newLayer()
		topUILayer:setPositionY(190)
		view:addChild(topUILayer, 10)
		-- money barBg
		local moneyBarBg = display.newImageView(app.murderMgr:GetResPath(RES_DICT.MONEY_INFO_BAR), display.width, display.height, {ap = display.RIGHT_TOP, scale9 = true, size = cc.size(1, 54)})
		topUILayer:addChild(moneyBarBg)
		-- money layer
		local moneyLayer = display.newLayer()
		topUILayer:addChild(moneyLayer)
		-- 返回按钮
        local backBtn = display.newButton(0, 0, {n = RES_DICT.BACK_BTN})
        display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
        view:addChild(backBtn, 10)
		return {
			view 	          = view,
			topUILayer		  = topUILayer,
			moneyBarBg        = moneyBarBg,
			moneyLayer        = moneyLayer,
			btnList           = btnList,
			investigationBtn  = investigationBtn,
			buffIcon 		  = buffIcon,
			buffNumLabel      = buffNumLabel,
			cardDraw 	      = cardDraw,
			cardDialog 	      = cardDialog,
			dialogTextLabel   = dialogTextLabel,
			progressBar       = progressBar,
			progressBarLabel  = progressBarLabel,
			rewardDescr 	  = rewardDescr,
			giftBtn 	 	  = giftBtn,
			backBtn           = backBtn,
			debugBtn 	      = debugBtn,
		}
	end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
	xTry(function ()
		self.viewData = CreateView()
		self:addChild(self.viewData.view)
		self:EnterAction()
	end, __G__TRACKBACK__)
end
--[[
入场动画
--]]
function MurderInvestigationView:EnterAction()
	self.viewData.topUILayer:runAction(cc.MoveTo:create(0.4, cc.p(0, 0)))
end
--[[
重载货币栏
--]]
function MurderInvestigationView:ReloadMoneyBar(moneyIdMap, isDisableGain)
    if moneyIdMap then
        moneyIdMap[tostring(GOLD_ID)]         = nil
        moneyIdMap[tostring(DIAMOND_ID)]      = nil
        moneyIdMap[tostring(PAID_DIAMOND_ID)] = nil
        moneyIdMap[tostring(FREE_DIAMOND_ID)] = nil
    end
    
    -- money data
    local moneyIdList = table.keys(moneyIdMap or {})
    table.insert(moneyIdList, GOLD_ID)
    table.insert(moneyIdList, DIAMOND_ID)
    
    -- clean moneyLayer
    local moneyBarBg = self:GetViewData().moneyBarBg
    local moneyLayer = self:GetViewData().moneyLayer
    moneyLayer:removeAllChildren()
    
    -- update moneyLayer
    local MONEY_NODE_GAP = 16
    local moneyLayerSize = moneyLayer:getContentSize()
    local moneryBarSize  = cc.size(20, moneyBarBg:getContentSize().height)
    for i = #moneyIdList, 1, -1 do
        local moneyId = checkint(moneyIdList[i])
        local isDisable = moneyId ~= GOLD_ID and moneyId ~= DIAMOND_ID and isDisableGain
        local moneyNode = GoodPurchaseNode.new({id = moneyId, animate = true, disable = isDisable, isEnableGain = not isDisableGain})
        moneyNode.viewData.touchBg:setTag(checkint(moneyId))
        moneyNode:setPosition(display.SAFE_R - moneryBarSize.width, moneyLayerSize.height - 26)
        moneyNode:setAnchorPoint(display.RIGHT_CENTER)
        moneyNode:setName(moneyId)
        moneyLayer:addChild(moneyNode)

        moneryBarSize.width = moneryBarSize.width + moneyNode:getContentSize().width + MONEY_NODE_GAP
    end

    -- update moneyBarBg
    moneryBarSize.width = 40 + moneryBarSize.width + (display.width - display.SAFE_R)
    moneyBarBg:setContentSize(moneryBarSize)

    -- update money value
    self:UpdateMoneyBar()
end
--[[
更新货币栏
--]]
function MurderInvestigationView:UpdateMoneyBar()
    for _, moneyNode in ipairs(self:GetViewData().moneyLayer:getChildren()) do
        local moneyId = checkint(moneyNode:getName())
        moneyNode:updataUi(moneyId)
    end
end
--[[
设置选中框是否选中
@params index int 序号
@params isSelected bool 是否选中
--]]
function MurderInvestigationView:SetCheckBoxSelected( index, isSelected )
	local viewData = self:GetViewData()
	local btnComponent = viewData.btnList[index]
	if isSelected then
		btnComponent.checkbox:setTexture(RES_DICT.CHECKBOX_SELECTED)
		btnComponent.nameLabel:setColor(ccc3FromInt('#ffffff'))
		btnComponent.descrLabel:setColor(ccc3FromInt('#ffbd72'))
	else
		btnComponent.checkbox:setTexture(RES_DICT.CHECKBOX_UNSELECTED)
		btnComponent.nameLabel:setColor(ccc3FromInt('#5e301a'))
		btnComponent.descrLabel:setColor(ccc3FromInt('#ac7f5b'))
	end
	btnComponent.selectedBg:setVisible(isSelected)
	
end
--[[
获取viewData
--]]
function MurderInvestigationView:GetViewData()
	return self.viewData
end
return MurderInvestigationView
