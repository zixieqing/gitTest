local CapsuleURProbabilityUPMediator = class('CapsuleURProbabilityUPMediator', mvc.Mediator)

local CapsuleURProbabilityUPNewView = require("Game.views.drawCards.CapsuleURProbabilityUPNewView")
local RewardsAnimateMediator  = require('Game.mediator.drawCards.CapsuleAnimateMediator')

function CapsuleURProbabilityUPMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CapsuleURProbabilityUPMediator', viewComponent)
    self.ctorArgs_ = checktable(params)

    self.upText = string.split(__('|_quality_image_|飨灵概率提升 |_times_num_| |_times_text_|'), '|')
    self.desrText = string.split(__('根据抽卡次数，|_quality_|飨灵|_name_|出现概率提升'), '|')
    self.probabilityText = string.split(__('概率提升剩余抽卡次数：|_count_|'), '|')
    self.costText = string.split(__('消耗 |_cost_||_icon_|'), '|')
    self.currentText = string.split(__('|_name_| 的概率'), '|')
    self.isControllable_ = false
end


-------------------------------------------------
-- inheritance method

function CapsuleURProbabilityUPMediator:Initial(key)
    self.super.Initial(self, key)

    self.ownerNode_ = self.ctorArgs_.ownerNode

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = CapsuleURProbabilityUPNewView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.rewardBtn:setOnClickScriptHandler(handler(self, self.RewardBtnClickHandler))
        viewData.onceBtn:setOnClickScriptHandler(handler(self, self.SummonBtnClickHandler))
        viewData.tenBtn:setOnClickScriptHandler(handler(self, self.SummonBtnClickHandler))
        viewData.desrBtn:setOnClickScriptHandler(handler(self, self.DesrBtnClickHandler))
        viewData.progress:setOnValueChangedScriptHandler(handler(self, self.ProgressValueChanged))
        viewData.progress:setOnProgressEndedScriptHandler(handler(self, self.ProgressActionEnded))
    end
end


function CapsuleURProbabilityUPMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function CapsuleURProbabilityUPMediator:OnRegist()
    regPost(POST.GAMBLING_PROBABILITY_UP_LUCKY)
end

function CapsuleURProbabilityUPMediator:OnUnRegist()
    unregPost(POST.GAMBLING_PROBABILITY_UP_LUCKY)
end


function CapsuleURProbabilityUPMediator:InterestSignals()
    local signals = {
        POST.GAMBLING_PROBABILITY_UP_LUCKY.sglName,
        'EVENT_PROBABILITY_UP_EXCHANGE',
        'EVENT_SUMMON_ANIMATION_MEDIATOR_CLOSE'
	}
	return signals
end

function CapsuleURProbabilityUPMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.GAMBLING_PROBABILITY_UP_LUCKY.sglName then
        -- 扣除道具
        CommonUtils.DrawRewards({rewards = {goodsId = body.requestData.costGoodsId, num = -body.requestData.costNum}})
        app.gameMgr:GetUserInfo().diamond = checkint(body.diamond)
        self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)

        self.probabilityIncreased = checkint(body.probabilityIncreased)
        -- show rewards animate
        self:GetFacade():RegistMediator(RewardsAnimateMediator.new(body))
    elseif name == 'EVENT_PROBABILITY_UP_EXCHANGE' then
        local viewData = self:GetViewComponent().viewData
        viewData.redPointImg:setVisible(self:CheckRedPoint())
    elseif name == 'EVENT_SUMMON_ANIMATION_MEDIATOR_CLOSE' then
        if 0 < checkint(self.probabilityIncreased) then
            self.isControllable_ = false
            local viewData = self:GetViewComponent().viewData
            local value = viewData.progress:getValue()
            if 100 > value and self.probabilityIncreased > value then
                local newValue = math.min(self.probabilityIncreased, 100)
                viewData.progress:startProgress(newValue, 2 * (newValue - value) * 0.01)
            else
                self:ProgressActionEnded()
            end

            self.probabilityIncreased = 0
        else
            self:ProgressActionEnded()
        end
    end
end

function CapsuleURProbabilityUPMediator:ProgressValueChanged(sender, value)
    local viewData = self:GetViewComponent().viewData
    local width = sender:getContentSize().width
    local pos = value * width / 100 + sender:getPositionX() - width / 2
    viewData.progressBG:setPositionX(pos)
    viewData.progressLabel:setString(string.format("%d%%", checkint(value)))
end

function CapsuleURProbabilityUPMediator:ProgressActionEnded(sender)
    local viewData = self:GetViewComponent().viewData
    self:SendSignal(POST.GAMBLING_PROBABILITY_UP.cmdName, {activityId = self.data.requestData.activityId})
end

function CapsuleURProbabilityUPMediator:RewardBtnClickHandler(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then
        return 
    end
	local mediator = require( 'Game.mediator.ActivityPropExchangeMediator').new({data = {activityId = self.data.requestData.activityId, tag = 110127, isAddDialog = true, activityHomeDatas = self.data}})
	AppFacade.GetInstance():RegistMediator(mediator)
end

function CapsuleURProbabilityUPMediator:SummonBtnClickHandler(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then
        return 
    end
    local tag = sender:getTag()
    local data = self.data
    local cost = 1 == tag and CommonUtils.GetCapsuleConsume(data.oneConsume) or CommonUtils.GetCapsuleConsume(data.tenConsume)
    if app.gameMgr:GetAmountByGoodId(cost.goodsId) >= cost.num then
        self:SendSignal(POST.GAMBLING_PROBABILITY_UP_LUCKY.cmdName, {activityId = self.data.requestData.activityId, type = tag, costGoodsId = cost.goodsId, costNum = cost.num})
    else
        app.capsuleMgr:ShowGoodsShortageTips(cost.goodsId)
    end
end

function CapsuleURProbabilityUPMediator:DesrBtnClickHandler(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then
        return 
    end
    local data = self.data
    local cardData = CommonUtils.GetConfig('cards', 'card', data.probabilityUpCardId)
    local quality = cardData.qualityId
    local cardRare = CommonUtils.GetConfig('cards', 'quality', quality).quality
    local desrText = {}
    for k,text in ipairs(self.desrText) do
        if '_quality_' == text then
            table.insert(desrText, cardRare)
        elseif '_name_' == text then
            table.insert(desrText, cardData.name)
        elseif '' ~= text then
            table.insert(desrText, text)
        end
    end

    app.uiMgr:ShowInformationTipsBoard({targetNode = sender, descr = table.concat( desrText ), type = 5, isOnlyDescr = true, bgSize = cc.size(260, 300)})
end


-------------------------------------------------
-- private method
--[[
刷新页面
--]]
function CapsuleURProbabilityUPMediator:RefreshView()
    -- 刷新页面
    local data = self.data
    local viewData = self:GetViewComponent().viewData
    viewData.upicon:RefreshSelf({id = data.probabilityUpCardId})
    viewData.timesLabel:setString(string.format('(%d/%d) ', checkint(data.urDropTimes), checkint(data.maxUrDropTimes)) .. __('次'))
    
    local textRich = {}
    local cardData = CommonUtils.GetConfig('cards', 'card', data.probabilityUpCardId)
    local quality = cardData.qualityId
    for k,text in ipairs(self.upText) do
        if '_quality_image_' == text then
            table.insert(textRich, {img = CardUtils.QUALITY_TEXT_PATH_MAP[tostring(quality)], scale = 0.45, ap = cc.p(0, 0.27)})
        elseif '_times_num_' == text then
            table.insert(textRich, {node = display.newLabel(0, 0, {text = data.urMultiple, fontSize = 40, color = '#ffd042', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25'}), ap = cc.p(0, 0.07)})
        elseif '_times_text_' == text then
            table.insert(textRich, {node = display.newLabel(0, 0, {text = __('倍'), fontSize = 24, color = '#ffd042', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25'})})
        elseif '' ~= text then
            table.insert(textRich, {node = display.newLabel(0, 0, {text = text, fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25'})})
        end
    end
    display.reloadRichLabel(viewData.upLabel, {c = textRich})
    CommonUtils.SetNodeScale(viewData.upLabel , {width = 310 })

    if checkint(data.maxUrDropTimes) <= checkint(data.urDropTimes) then
        viewData.desrBG:setFilter(GrayFilter:create())
    else
        viewData.desrBG:clearFilter()
    end
    local cardRare = checktable(CommonUtils.GetConfig('cards', 'quality', quality)).quality
    if checkint(data.probabilityIncreasedLeftTimes) <= 0 then
        viewData.desrLabel:setString(__('概率已达到最大上限100%'))
    else
        local desrText = {}
        for k,text in ipairs(self.probabilityText) do
            if '_count_' == text then
                table.insert(desrText, checkint(data.probabilityIncreasedLeftTimes))
            elseif '' ~= text then
                table.insert(desrText, text)
            end
        end
        viewData.desrLabel:setString(table.concat( desrText ))
    end

    local capsuleOneConsume = CommonUtils.GetCapsuleConsume(data.oneConsume)
    local costOneText = {}
    for k,text in ipairs(self.costText) do
        if '_cost_' == text then
            table.insert(costOneText, fontWithColor(18, {text = tostring(capsuleOneConsume.num)}))
        elseif '_icon_' == text then
            table.insert(costOneText, {img = CommonUtils.GetGoodsIconPathById(capsuleOneConsume.goodsId), scale = 0.2})
        elseif '' ~= text then
            table.insert(costOneText, fontWithColor(18, {text = text}))
        end
    end
    display.reloadRichLabel(viewData.onceLabel, {c = costOneText})

    local capsuleTenConsume = CommonUtils.GetCapsuleConsume(data.tenConsume)
    local costTenText = {}
    for k,text in ipairs(self.costText) do
        if '_cost_' == text then
            table.insert(costTenText, fontWithColor(18, {text = tostring(capsuleTenConsume.num)}))
        elseif '_icon_' == text then
            table.insert(costTenText, {img = CommonUtils.GetGoodsIconPathById(capsuleTenConsume.goodsId), scale = 0.2})
        elseif '' ~= text then
            table.insert(costTenText, fontWithColor(18, {text = text}))
        end
    end
    display.reloadRichLabel(viewData.tenLabel, {c = costTenText})

    viewData.progress:setValue(checkint(data.probabilityIncreased))
    viewData.progressLabel:setString(string.format("%d%%", checkint(data.probabilityIncreased)))

    viewData.currentTopLabel:setString(string.format( __("当前%s飨灵中"), tostring(cardRare) ))
    local currentText = {}
    for k,text in ipairs(self.currentText) do
        if '_name_' == text then
            table.insert(currentText, fontWithColor(10, {text = cardData.name}))
        elseif '' ~= text then
            table.insert(currentText, fontWithColor(16, {text = text}))
        end
    end
    display.reloadRichLabel(viewData.currentBottomLabel, {c = currentText})

    local labelWidth = display.getLabelContentSize(viewData.currentTopLabel).width
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_MAC or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD or target == cc.PLATFORM_OS_WINDOWS then
        labelWidth = math.max(labelWidth, viewData.currentBottomLabel:getContentSize().width / 2) + 26
    else
        labelWidth = math.max(labelWidth, viewData.currentBottomLabel:getContentSize().width) + 26
    end
    viewData.progressBG:setContentSize(cc.size(labelWidth, 68))
    local width = viewData.progress:getContentSize().width
    local pos = viewData.progress:getValue() * width / 100 + viewData.progress:getPositionX() - width / 2
    viewData.progressBG:setPositionX(pos)
    viewData.currentTopLabel:setPositionX(labelWidth / 2)
    viewData.currentBottomLabel:setPositionX(labelWidth / 2)
    viewData.progressArrow:setPositionX(labelWidth / 2)

    viewData.redPointImg:setVisible(self:CheckRedPoint())

    self.isControllable_ = true
end

function CapsuleURProbabilityUPMediator:CheckRedPoint()
    for k, v in pairs(self.data.exchange) do
        if checkint(v.hasDrawn) == 0 and checkint(v.progress) >= checkint(v.targetId) then
            return true
        end
    end
    return false
end

-------------------------------------------------
-- public method
function CapsuleURProbabilityUPMediator:resetHomeData( homeData )
    for k, v in pairs(homeData.exchange) do
        v.targetNum = v.targetId
    end
    self.data = homeData
    self:RefreshView()
end

return CapsuleURProbabilityUPMediator
