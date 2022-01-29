-------------------------------------------------------------------------------
-- 个人信息 - 领取奖励 中介者
-- 
-- Author: kaishiqi <zhangkai@funtoygame.com>
-- 
-- Create: 2021-07-20 14:31:14
-------------------------------------------------------------------------------

local PersonInformationRewardsView     = require('Game.views.PersonInformationRewardsView')
---@class PersonInformationRewardsMediator : Mediator
local PersonInformationRewardsMediator = class('PersonInformationRewardsMediator', mvc.Mediator)

local RewardContentViewDefine = {
    ['1'] = {initFunc = 'initLvMaxRewardView_'}
}

function PersonInformationRewardsMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'PersonInformationRewardsMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function PersonInformationRewardsMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = PersonInformationRewardsView.new(self)
    self:SetViewComponent(self:getViewNode())

    -- add listener
    self.modifyClocker_ = app.timerMgr.CreateClocker(handler(self, self.onModifyAddressCDUpdateHandler_))
    ---@param cellViewData PersonInformationRewardsView.RewardListCellData
    self:getViewData().rewardListView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.clickArea, handler(self, self.onClickRewardListCellHandler_))
    end)
    self:getViewData().rewardListView:setCellUpdateHandler(handler(self, self.onUpdateRewardListCellHandler_))

    -- update views
    self:setRewwardListData(CONF.DERIVATIVE.SUMMARY:GetIdListUp())
end


function PersonInformationRewardsMediator:CleanupView()
end


function PersonInformationRewardsMediator:OnRegist()
    regPost(POST.DERIVATIVE_HOME)
    regPost(POST.DERIVATIVE_DRAW)
    regPost(POST.DERIVATIVE_ADDRESS)
    
    self:SendSignal(POST.DERIVATIVE_HOME.cmdName)
end


function PersonInformationRewardsMediator:OnUnRegist()
    unregPost(POST.DERIVATIVE_HOME)
    unregPost(POST.DERIVATIVE_DRAW)
    unregPost(POST.DERIVATIVE_ADDRESS)

    self.modifyClocker_:stop()
end


function PersonInformationRewardsMediator:InterestSignals()
    return {
        POST.DERIVATIVE_HOME.sglName,
        POST.DERIVATIVE_DRAW.sglName,
        POST.DERIVATIVE_ADDRESS.sglName,
    }
end
function PersonInformationRewardsMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.DERIVATIVE_HOME.sglName then
        self:setHomeData(data)


    elseif name == POST.DERIVATIVE_DRAW.sglName then
        -- update drawRewards mark
        self:getHomeData().maxLevelRewards = 1

        -- popup rewards
        app.uiMgr:showRewardPopup({rewards = data.rewards, closeCallback = function()
            -- update contentView
            self:updateContentLayer_()
        end})


    elseif name == POST.DERIVATIVE_ADDRESS.sglName then
        -- update address data
        local addressData = self:getHomeData().derivativeAddress[tostring(data.requestData.derivativeId)]
        if not addressData then
            addressData = {}
            self:getHomeData().derivativeAddress[tostring(data.requestData.derivativeId)] = addressData
        end
        addressData.name         = data.requestData.name
        addressData.telephone    = data.requestData.telephone
        addressData.address      = data.requestData.address
        addressData.cd           = checkint(CONF.DERIVATIVE.BASE_PARMS:GetValue('addressCD'))
        addressData.cdTimestamp  = addressData.cd + os.time()

        app.uiMgr:ShowInformationTips(__('保存成功'))

        -- update contentView
        self:updateContentLayer_()

    end
end


-------------------------------------------------
-- get / set

---@return PersonInformationRewardsView
function PersonInformationRewardsMediator:getViewNode()
    return  self.viewNode_
end
---@return PersonInformationRewardsView.ViewData
function PersonInformationRewardsMediator:getViewData()
    return self:getViewNode():getViewData()
end


function PersonInformationRewardsMediator:getHomeData()
    return self.homeData_
end
function PersonInformationRewardsMediator:setHomeData(homeData)
    self.homeData_ = checktable(homeData)

    for _, addressData in pairs(self:getHomeData().derivativeAddress or {}) do
        if addressData.cd then
            addressData.cdTimestamp = checkint(addressData.cd) + os.time()
        end
    end

    if self:getSelectCellIndex() == 0 then
        self:setSelectCellIndex(1)
    end
end


function PersonInformationRewardsMediator:getRewwardListData()
    return self.rewardListData_
end
function PersonInformationRewardsMediator:setRewwardListData(listData)
    self.rewardListData_ = checktable(listData)
    self:getViewData().rewardListView:resetCellCount(#self:getRewwardListData(), true)
end


function PersonInformationRewardsMediator:getSelectCellIndex()
    return checkint(self.selectCellIndex_)
end
function PersonInformationRewardsMediator:setSelectCellIndex(cellIndex)
    self.selectCellIndex_ = checkint(cellIndex)
    self:getViewNode():updateRewardListSelectIndex()
    self:updateContentLayer_()
end


-------------------------------------------------
-- private

function PersonInformationRewardsMediator:updateContentLayer_()
    local rewardCellId  = checkint(self:getRewwardListData()[self:getSelectCellIndex()])
    local contentDefine = RewardContentViewDefine[tostring(rewardCellId)] or {}
    self:getViewData().contentLayer:removeAllChildren()
    
    if contentDefine.initFunc and self[contentDefine.initFunc] then
        self[contentDefine.initFunc](self)
    end
end


function PersonInformationRewardsMediator:initLvMaxRewardView_()
    local isDrawRewards = checkint(self:getHomeData().maxLevelRewards) == 1
    if isDrawRewards then
        self:initAddressView_()
    else
        -- create view
        self:getViewNode():updateContentView(PersonInformationRewardsView.CreateLvMaxView)

        -- update view
        local rewardCellId = checkint(self:getRewwardListData()[self:getSelectCellIndex()])
        self:getViewNode():updateLvMaxRewardView(rewardCellId)
        
        ---@type PersonInformationRewardsView.LvMaxViewData
        local lvMaxViewData = self:getViewNode():getContentViewData()
        ui.bindClick(lvMaxViewData.drawRewardBtn, handler(self, self.onClickLvMaxDrawRewardButtonHandler_))
        ui.bindClick(lvMaxViewData.rewardPreviewBtn, handler(self, self.onClickRewardPreviewButtonHandler_))
    end
end


function PersonInformationRewardsMediator:initAddressView_()
    local rewardCellId = checkint(self:getRewwardListData()[self:getSelectCellIndex()])
    local addressData  = self:getHomeData().derivativeAddress[tostring(rewardCellId)] or {}

    if checkstr(addressData.expressNo) == '' then
        -- create view
        self:getViewNode():updateContentView(PersonInformationRewardsView.CreateAddressInputView)

        -- update view
        self:getViewNode():updateAddressInputView(rewardCellId, addressData)

        local currentTime = os.time()
        local targetTime  = checkint(addressData.cdTimestamp)
        local leftSeconds = targetTime - currentTime
        if leftSeconds > 0 then
            self.modifyClocker_:start()
        end

        ---@type PersonInformationRewardsView.AddressInputViewData
        local inputViewData = self:getViewNode():getContentViewData()
        ui.bindClick(inputViewData.rewardPreviewBtn, handler(self, self.onClickRewardPreviewButtonHandler_))
        ui.bindClick(inputViewData.updateAddressBtn, handler(self, self.onClickUpdateAddressButtonHandler_))
    else
        -- create view
        self:getViewNode():updateContentView(PersonInformationRewardsView.CreateAddressShowView)

        -- update view
        self:getViewNode():updateAddressShowView(rewardCellId, addressData)

        ---@type PersonInformationRewardsView.AddressShowViewData
        local showViewData = self:getViewNode():getContentViewData()
        ui.bindClick(showViewData.rewardPreviewBtn, handler(self, self.onClickRewardPreviewButtonHandler_))
        ui.bindClick(showViewData.copyExpressNoBtn, handler(self, self.onClickCopyExpressNoButtonHandler_))
    end
end


-------------------------------------------------
-- handler

function PersonInformationRewardsMediator:onClickRewardListCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local rewardCellIndex = checkint(sender:getTag())
    self:setSelectCellIndex(rewardCellIndex)
end


---@param cellIndex    integer
---@param cellViewData PersonInformationRewardsView.RewardListCellData
function PersonInformationRewardsMediator:onUpdateRewardListCellHandler_(cellIndex, cellViewData)
    if not cellViewData then return end
    cellViewData.view:setTag(cellIndex)
    cellViewData.clickArea:setTag(cellIndex)
    
    local rewardCellId = checkint(self:getRewwardListData()[cellIndex])
    self:getViewNode():updateRewardListCell(cellIndex, cellViewData, rewardCellId)
end


function PersonInformationRewardsMediator:onClickLvMaxDrawRewardButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local rewardCellId = checkint(self:getRewwardListData()[self:getSelectCellIndex()])
    local summaryConf  = CONF.DERIVATIVE.SUMMARY:GetValue(rewardCellId)
    local targetLevel  = checkint(summaryConf.level)
    local currentLevel = checkint(app.gameMgr:GetUserInfo().level)

    if currentLevel >= targetLevel then
        self:SendSignal(POST.DERIVATIVE_DRAW.cmdName)
    else
        app.uiMgr:ShowInformationTips(string.fmt(__('需要达到_num_级才可以领取礼包哦~'), {_num_ = targetLevel}))
    end
end


function PersonInformationRewardsMediator:onClickUpdateAddressButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    ---@type PersonInformationRewardsView.AddressInputViewData
    local inputViewData = self:getViewNode():getContentViewData()
    local nameText      = inputViewData.nameEditBox:getText()
    local phoneText     = inputViewData.phoneEditBox:getText()
    local addressText   = inputViewData.addressEditBox:getText()

    if nameText == '' then
        app.uiMgr:ShowInformationTips(__('请输入收件人信息'))
        return
    end

    if phoneText == '' then
        app.uiMgr:ShowInformationTips(__('请输入手机信息'))
        return
    end

    if checkint(phoneText) == 0 or string.len(phoneText) ~= 11 then
        app.uiMgr:ShowInformationTips(__('请输入正确的手机号'))
        return
    end

    if addressText == '' then
        app.uiMgr:ShowInformationTips(__('请输入地址信息'))
        return
    end

    app.uiMgr:AddNewCommonTipDialog({text = __('确认保存填写的信息?'), callback = function()
        local rewardCellId = checkint(self:getRewwardListData()[self:getSelectCellIndex()])
        self:SendSignal(POST.DERIVATIVE_ADDRESS.cmdName, {
            derivativeId = rewardCellId,
            name         = nameText,
            telephone    = phoneText,
            address      = addressText,
        })
    end})
end


function PersonInformationRewardsMediator:onModifyAddressCDUpdateHandler_()
    local rewardCellId = checkint(self:getRewwardListData()[self:getSelectCellIndex()])
    local addressData  = self:getHomeData().derivativeAddress[tostring(rewardCellId)] or {}
    local currentTime  = os.time()
    local targetTime   = checkint(addressData.cdTimestamp)
    local leftSeconds  = targetTime - currentTime

    if leftSeconds >= 0 then
        self:getViewNode():updateAddressModifyTime(addressData)
    else
        self.modifyClocker_:stop()
        self:getViewNode():updateAddressInputView(rewardCellId, addressData)
    end
end


function PersonInformationRewardsMediator:onClickCopyExpressNoButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local rewardCellId = checkint(self:getRewwardListData()[self:getSelectCellIndex()])
    local addressData  = self:getHomeData().derivativeAddress[tostring(rewardCellId)] or {}
    FTUtils:storePasteboard(tostring(addressData.expressNo))

    app.uiMgr:ShowInformationTips(__('已复制快递单号到粘贴板'))
end


function PersonInformationRewardsMediator:onClickRewardPreviewButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local rewardCellId = checkint(self:getRewwardListData()[self:getSelectCellIndex()])
    app.uiMgr:AddDialog('Game.views.PersonInformationRewardsPreviewPopup', {derivativeId = rewardCellId})
end


return PersonInformationRewardsMediator
