local Mediator = mvc.Mediator
---@class ReturnWelfareDailyMediator:Mediator
local ReturnWelfareDailyMediator = class("ReturnWelfareDailyMediator", Mediator)

local NAME = "ReturnWelfareDailyMediator"
local app = app
local uiMgr = app.uiMgr

function ReturnWelfareDailyMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
    self.datas = checktable(params) or {}
    self.time = string.split(__('第|_num_|天'), '|')
end

function ReturnWelfareDailyMediator:InterestSignals()
	local signals = { 
		POST.BACK_DRAW_ACCUMULATIVE_LOGIN.sglName,
	}

	return signals
end

function ReturnWelfareDailyMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	-- dump(body, name)
    if name == POST.BACK_DRAW_ACCUMULATIVE_LOGIN.sglName then
        uiMgr:AddDialog('common.RewardPopup', body)
        local accumulativeLoginId = body.requestData.accumulativeLoginId
        for k,v in pairs(self.datas.data.accumulativeLoginRewards) do
            if v.accumulativeLoginId == accumulativeLoginId then
                v.hasDrawn = 1
                break
            end
        end
        self:RefreshUI()
        app:DispatchObservers('EVENT_HOME_RED_POINT')
    end
end

function ReturnWelfareDailyMediator:Initial( key )
	self.super.Initial(self, key)
	-- local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.returnWelfare.ReturnWelfareDailyView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
    -- scene:AddDialog(viewComponent)
    self.datas.parent:addChild(viewComponent)
    
    self:InitUI()
    self:RefreshUI()
    local viewData = viewComponent.viewData
    local data = self.datas.data
    for i,v in ipairs(viewData.drawBtns) do
        v:setTag(data.accumulativeLoginRewards[i].accumulativeLoginId)
        v:setOnClickScriptHandler(handler(self, self.DrawBtnClickHandler))
    end
end

function ReturnWelfareDailyMediator:InitUI(  )
    local viewData = self.viewComponent.viewData

    local data = self.datas.data
    -- local goodsNodes = {true, true, true, true, true, true, true}
    for i,v in ipairs(data.accumulativeLoginRewards) do
        local goodsIcon = require('common.GoodNode').new({
            id = v.rewards[1].goodsId,
            amount = v.rewards[1].num,
            showAmount = true,
            callBack = function (sender)
                uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
            end
        })
        goodsIcon:setPosition(display.cx - 608 + i * 152, 186)
        viewData.view:addChild(goodsIcon)
        -- goodsNodes[i] = goodsIcon
    end
end

function ReturnWelfareDailyMediator:RefreshUI(  )
    local viewData = self.viewComponent.viewData
    
    local data = self.datas.data
    local today = checkint(data.accumulativeLoginDayNum)
    for i,v in ipairs(viewData.timeLabels) do
        local textRich = {}
        for k,text in ipairs(self.time) do
            if '_num_' == text then
                if today == i then
                    local day = {' ', i, ' '}
                    table.insert(textRich, {node = display.newLabel(0, 0, {text = table.concat( day ), fontSize = 40, color = '#feffa1', font = TTF_GAME_FONT, ttf = true, outline = '#6d544c'}), ap = cc.p(0, 0.07)})
                else
                    table.insert(textRich, {text = i, fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#6d544c'})
                end
            elseif '' ~= text then
                table.insert(textRich, {text = text, fontSize = 26, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#6d544c'})
            end
        end
        display.reloadRichLabel(v, {c = textRich})
        if today == i then
            v:setPositionY(315)
        else
            v:setPositionY(306)
        end
    end
    
    if 7 >= today and 0 < today then
        viewData.todayImg:setPositionX(display.cx - 608 + today * 152)
    else
        viewData.todayImg:setVisible(false)
    end

    for i,v in ipairs(viewData.drawBtns) do
        if 0 == checkint(data.accumulativeLoginRewards[i].hasDrawn) and i <= today then
            v:setNormalImage(_res('ui/common/common_btn_orange.png'))
            v:setSelectedImage(_res('ui/common/common_btn_orange.png'))
            display.commonLabelParams(v, fontWithColor(14, {text = __('领取')}))
            v.redPointImg:setVisible(true)
        else
            v:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
            v:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
            if i <= today then
                display.commonLabelParams(v, fontWithColor(14, {text = __('已领取')}))
            else
                display.commonLabelParams(v, fontWithColor(14, {text = __('领取')}))
            end
            v.redPointImg:setVisible(false)
        end
    end
end

function ReturnWelfareDailyMediator:ResetMdt( data )
    self.datas.data = checktable(data) or {}
    self:RefreshUI()
end

function ReturnWelfareDailyMediator:DrawBtnClickHandler(sender)
	PlayAudioByClickNormal()
    local tag = sender:getTag()
    local data = self.datas.data
    local today = checkint(data.accumulativeLoginDayNum)
    for i,v in ipairs(data.accumulativeLoginRewards) do
        if v.accumulativeLoginId == tag then
            if today < i then
                uiMgr:ShowInformationTips(__('不符合领取条件'))
            elseif 0 == checkint(v.hasDrawn) then
                self:SendSignal(POST.BACK_DRAW_ACCUMULATIVE_LOGIN.cmdName, {accumulativeLoginId = tag})
            else
                uiMgr:ShowInformationTips(__('不可重复领取'))
            end
            break
        end
    end
end

function ReturnWelfareDailyMediator:OnRegist(  )
	regPost(POST.BACK_DRAW_ACCUMULATIVE_LOGIN)
end

function ReturnWelfareDailyMediator:OnUnRegist(  )
	unregPost(POST.BACK_DRAW_ACCUMULATIVE_LOGIN)
	-- local scene = uiMgr:GetCurrentScene()
	-- scene:RemoveGameLayer(self.viewComponent)
end

return ReturnWelfareDailyMediator