--[[
    被召回Mediator
--]]
local Mediator = mvc.Mediator

local RecalledMediator = class("RecalledMediator", Mediator)

local NAME = "RecalledMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
local dataMgr = AppFacade.GetInstance():GetManager("DataManager")

local function GetFullPath( imgName )
	return _res('ui/home/recall/' .. imgName)
end

function RecalledMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.args = checktable(params) or {}
	if not self.args.veteranChestRewards then
		self.args.veteranChestRewards = {}
	end
    if not self.args.veteranChestLeftBuyTimes then
        self.args.veteranChestLeftBuyTimes = 0
    end
    if not self.args.veteranTaskEndLeftSeconds then
        self.args.veteranTaskEndLeftSeconds = 0
    end
    if not self.args.veteranChestCurrency then
        self.args.veteranChestCurrency = DIAMOND_ID
    end
    if self.args.veteranTaskEndLeftSeconds > self.args.leftSeconds then
        self.showVeteranTime = true
    end
end

function RecalledMediator:InterestSignals()
	local signals = { 
        POST.RECALLED_REWARD_DRAW.sglName ,
        POST.RECALLED_CHEST_BUY.sglName ,
        RECALLED_TASK_TIME_UPDATE_EVENT,
        RECALL_MAIN_TIME_UPDATE_EVENT,
	}

	return signals
end

function RecalledMediator:ProcessSignal( signal )
	local name = signal:GetName() 
    local body = signal:GetBody()
    -- dump(body, name)
    if name == POST.RECALLED_REWARD_DRAW.sglName then
		uiMgr:AddDialog('common.RewardPopup', body)
        for k,v in pairs(self.args.veteranLoginRewards) do
			if checkint(v.id) == checkint(body.requestData.rewardId) then
				v.hasDrawn = 1
				local cell = self.viewComponent.viewData_.gridView:cellAtIndex(k - 1)
                if cell then
                    cell.recvBtn:setScale(0.9)
					cell.recvBtn:setEnabled(false)
					cell.recvBtn:setNormalImage(_res('ui/common/activity_mifan_by_ico.png'))
					display.commonLabelParams(cell.recvBtn, fontWithColor('14', {text = __('已领取')}))
				end
				break
			end
		end
		AppFacade.GetInstance():DispatchObservers(RECALLED_TASK_DRAW_UI)
    elseif name == POST.RECALLED_CHEST_BUY.sglName then
        CommonUtils.DrawRewards({
			{goodsId = self.args.veteranChestCurrency, amount = -1 * self.args.veteranChestPrice * self.args.veteranChestDiscount}
		})
        uiMgr:AddDialog('common.RewardPopup', body)
        self.args.veteranChestLeftBuyTimes = self.args.veteranChestLeftBuyTimes - 1
        self:UpdateBuyBtn()
    elseif name == RECALLED_TASK_TIME_UPDATE_EVENT then
        if self.showVeteranTime then
            local leftSeconds = body.leftSeconds
            self:UpdateTimeLabel(leftSeconds)
        end
    elseif name == RECALL_MAIN_TIME_UPDATE_EVENT then
        if not self.showVeteranTime then
            local leftSeconds = body.leftSeconds
            self:UpdateTimeLabel(leftSeconds)
        end
    end
end

function RecalledMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.RecalledView').new()
	self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData_

    -- 召回专属礼包
    local veteranChestRewards = self.args.veteranChestRewards
    local initPosX = viewData.buyBtn:getPositionX() - (table.nums(veteranChestRewards) - 1) * 110 / 2
    for i=1,table.nums(veteranChestRewards) do
        local goodsIcon = require('common.GoodNode').new({
            id = veteranChestRewards[i].goodsId,
            amount = veteranChestRewards[i].num,
            showAmount = true,
            callBack = function (sender)
                uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = veteranChestRewards[i].goodsId, type = 1})
            end
        })
        goodsIcon:setScale(0.85)
        goodsIcon:setPosition(cc.p(initPosX + (i - 1)*110, 174))
        viewData.view:addChild(goodsIcon)
    end
    if 0 < table.nums(veteranChestRewards) then
	    local oldCostLabel = display.newLabel(0, 0, fontWithColor('14', {text = self.args.veteranChestPrice, fontSize = 22}))
	    viewData.buyBtn:addChild(oldCostLabel)

	    local oldCostIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(self.args.veteranChestCurrency)), 0, 0)
	    oldCostIcon:setScale(0.15)
        viewData.buyBtn:addChild(oldCostIcon)

	    local lineImg = display.newImageView(GetFullPath('takeout_line_complete'), viewData.buyBtn:getContentSize().width / 2, 42)
        viewData.buyBtn:addChild(lineImg)
    
        display.setNodesToNodeOnCenter(viewData.buyBtn, {oldCostIcon, oldCostLabel}, {y = 42})

	    -- 消耗信息
	    local costLabel = display.newLabel(0, 0, fontWithColor('14', {text = self.args.veteranChestPrice * self.args.veteranChestDiscount, fontSize = 22}))
	    viewData.buyBtn:addChild(costLabel)

	    local costIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(self.args.veteranChestCurrency)), 0, 0)
	    costIcon:setScale(0.15)
        viewData.buyBtn:addChild(costIcon)
    
        display.setNodesToNodeOnCenter(viewData.buyBtn, {costIcon, costLabel}, {y = 18})
    end
    self:UpdateBuyBtn()
	self:UpdateTimeLabel(self.showVeteranTime and self.args.veteranTaskEndLeftSeconds or self.args.leftSeconds)
    
    viewData.buyBtn:setOnClickScriptHandler(handler(self,self.onClickBuyButtonHandler))
    viewData.dailyBtn:setOnClickScriptHandler(handler(self,self.onClickDailyTaskButtonHandler))

    local gridView = viewData.gridView
    gridView:setCountOfCell(table.nums(self.args.veteranLoginRewards))
    gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
    gridView:reloadData()
end

function RecalledMediator:UpdateTimeLabel( leftSeconds )
	local viewData = self.viewComponent.viewData_
	if checkint(leftSeconds) <= 0 then
		viewData.timeLabel:setString('00:00:00')
	else
		if checkint(leftSeconds) <= 86400 then
			viewData.timeLabel:setString(string.formattedTime(checkint(leftSeconds),'%02i:%02i:%02i'))
		else
			local day = math.floor(checkint(leftSeconds)/86400)
			local hour = math.floor((leftSeconds - day * 86400) / 3600)
			viewData.timeLabel:setString(string.fmt(__('_day_天_hour_小时'),{_day_ = day, _hour_ = hour}))
		end
	end
end

function RecalledMediator:UpdateBuyBtn(  )
	local viewData = self.viewComponent.viewData_
    local veteranChestRewards = self.args.veteranChestRewards
    viewData.buyBtn:setVisible(0 < table.nums(veteranChestRewards))
    viewData.limitLabel:setVisible(0 < table.nums(veteranChestRewards))
    if 0 < self.args.veteranChestLeftBuyTimes and gameMgr:CheckIsVeteran() then
        viewData.buyBtn:setNormalImage(_res('ui/common/common_btn_green.png'))
        viewData.buyBtn:setSelectedImage(_res('ui/common/common_btn_green.png'))
    else
        viewData.buyBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
        viewData.buyBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
    end
    viewData.limitLabel:setString(string.format(__('限购%d次'), self.args.veteranChestLeftBuyTimes))
end

-- 购买回归礼包
function RecalledMediator:onClickBuyButtonHandler(sender)
    PlayAudioByClickNormal()
    if self:CheckAvailable() then
    else
        uiMgr:ShowInformationTips(__('活动任务已结束'))
        return
    end
    if gameMgr:CheckIsVeteran() then
        if 0 >= self.args.veteranChestLeftBuyTimes then
            uiMgr:ShowInformationTips(__('已达购买上限'))
            return
        end
        local diamond = CommonUtils.GetCacheProductNum(self.args.veteranChestCurrency)
		if diamond < checkint(self.args.veteranChestPrice * self.args.veteranChestDiscount) then
			if GAME_MODULE_OPEN.NEW_STORE then
                app.uiMgr:showDiamonTips()
            else
                local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('幻晶石不足是否去商城购买？'),
                    isOnlyOK = false, callback = function ()
                        app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
                    end})
                CommonTip:setPosition(display.center)
                app.uiMgr:GetCurrentScene():AddDialog(CommonTip)
            end
		else
            self:SendSignal(POST.RECALLED_CHEST_BUY.cmdName,{})
        end
    else
        uiMgr:ShowInformationTips(__('只有老玩家才能购买感恩礼包'))
    end
end

function RecalledMediator:onClickDailyTaskButtonHandler(sender)
	PlayAudioByClickNormal()

    if gameMgr:CheckIsVeteran() then
        if self.args.veteranTaskEndLeftSeconds > 0 then
            gameMgr:GetUserInfo().showRedPointForRecallH5 = false
	        dataMgr:ClearRedDotNofication(tostring(RemindTag.RECALLH5),RemindTag.RECALLH5, "[老玩家召回]onClickDailyTaskButtonHandler")
            AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.RECALLH5})
    
            local mediator = require("Game.mediator.RecallDailyTaskMediator").new(self.args)
            self:GetFacade():RegistMediator(mediator)
        else
            uiMgr:ShowInformationTips(__('活动任务已结束'))
        end
    else
        uiMgr:ShowInformationTips(__('只有老玩家才能接受每日任务'))
    end
end

function RecalledMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local sizee = cc.size(296 * 2, 150)
    local tempData = self.args.veteranLoginRewards[index]
   	if pCell == nil then
        pCell = CGridViewCell:new()
        pCell:setContentSize(sizee)

        local cellBg = display.newImageView(GetFullPath('recall_bg_task'), 296, 75)
        pCell:addChild(cellBg)

		local desrLabel = display.newLabel(18, 130, fontWithColor('16', {ap = display.LEFT_CENTER}))
        pCell:addChild(desrLabel)
        pCell.desrLabel = desrLabel

		local recvBtn = display.newButton(500, 58, {n = _res('ui/common/common_btn_orange.png')})
		pCell:addChild(recvBtn)
        display.commonLabelParams(recvBtn, fontWithColor('14', {text = __('领取')}))
		recvBtn:setOnClickScriptHandler(handler(self,self.CellButtonAction))
		pCell.recvBtn = recvBtn

        pCell.goodsIcon = {}
    end
    xTry(function()
        pCell.desrLabel:setString(tempData.name)
        pCell.recvBtn:setTag(index)
        for k,v in pairs(pCell.goodsIcon) do
            v:setVisible(false)
        end
        pCell.recvBtn:setScale(1)
        if not gameMgr:CheckIsVeteran() then -- 不可领取
			pCell.recvBtn:setEnabled(true)
			pCell.recvBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
			pCell.recvBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
			display.commonLabelParams(pCell.recvBtn, fontWithColor('14', {text = __('领取')}))
        elseif 1 == checkint(tempData.hasDrawn) then -- 已领取
			pCell.recvBtn:setEnabled(false)
			pCell.recvBtn:setNormalImage(_res('ui/common/activity_mifan_by_ico.png'))
			pCell.recvBtn:setScale(0.9)
			display.commonLabelParams(pCell.recvBtn, fontWithColor('7', {fontSize = 22,text = __('已领取')}))
        elseif 2 == checkint(tempData.status) then -- 不可领取
			pCell.recvBtn:setEnabled(true)
			pCell.recvBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
			pCell.recvBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
			display.commonLabelParams(pCell.recvBtn, fontWithColor('14', {text = __('领取')}))
		else
			pCell.recvBtn:setEnabled(true)
			pCell.recvBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
			pCell.recvBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
			display.commonLabelParams(pCell.recvBtn, fontWithColor('14', {text = __('领取')}))
		end
        for i=1,table.nums(tempData.rewards) do
            if pCell.goodsIcon[i] then
                pCell.goodsIcon[i]:setVisible(true)
                pCell.goodsIcon[i]:RefreshSelf({
                    goodsId = tempData.rewards[i].goodsId,
                    amount = tempData.rewards[i].num,
                    showAmount = true,
                })
            else
                local goodsIcon = require('common.GoodNode').new({
                    id = tempData.rewards[i].goodsId,
                    amount = tempData.rewards[i].num,
                    showAmount = true,
                    callBack = function (sender)
                        uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
                    end
                })
                goodsIcon:setPosition(cc.p(62 + (i - 1)*93, 58))
                goodsIcon:setScale(0.8)
                pCell:addChild(goodsIcon)
                pCell.goodsIcon[i] = goodsIcon
            end
        end
	end,__G__TRACKBACK__)
    return pCell
end

--[[
列表的单元格按钮的事件处理逻辑
@param sender button对象
--]]
function RecalledMediator:CellButtonAction( sender )
    PlayAudioByClickNormal()
	local index = sender:getTag()
    self.tag = index
    if not gameMgr:CheckIsVeteran() then -- 非老玩家
        uiMgr:ShowInformationTips(__('只有老玩家才能领取登录奖励'))
        return
    end
	local data  = self.args.veteranLoginRewards[index]
	if data then
		if checkint(data.hasDrawn) == 0 then
			if 2 == checkint(data.status) then
				uiMgr:ShowInformationTips(__('未达到领取条件'))
			else
                if self:CheckAvailable() then
					self:SendSignal(POST.RECALLED_REWARD_DRAW.cmdName,{rewardId = checkint(data.id)})
				else
					uiMgr:ShowInformationTips(__('任务时间已经结束'))
				end
			end
		else
			uiMgr:ShowInformationTips(__('已领取该奖励'))
		end
	end
end

-- 检查登录奖励和感恩礼包能否使用
function RecalledMediator:CheckAvailable(  )
    if self.args.veteranTaskEndLeftSeconds > 0 then
        return true
    elseif self.args.leftSeconds > 0 then
        return true
    end
    return false
end

function RecalledMediator:OnRegist(  )
    regPost(POST.RECALLED_REWARD_DRAW)
    regPost(POST.RECALLED_CHEST_BUY)
end

function RecalledMediator:OnUnRegist(  )
	unregPost(POST.RECALLED_REWARD_DRAW)
	unregPost(POST.RECALLED_CHEST_BUY)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return RecalledMediator