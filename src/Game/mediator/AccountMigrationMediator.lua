--[[
 * author : panmeng
 * descpt : 账号迁移
]]

local AccountMigrationView     = require('Game.views.AccountMigrationView')
local AccountMigrationMediator = class('AccountMigrationMediator', mvc.Mediator)

function AccountMigrationMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'AccountMigrationMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance

function AccountMigrationMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = AccountMigrationView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddGameLayer(self:getViewNode())

    -- add listener
    self.codeRefreshClocker_ = app.timerMgr.CreateClocker(handler(self, self.onCodeRefreshUpdateHandler_))
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    ui.bindClick(self:getViewData().codeBtn, handler(self, self.onClickCodeButtonHandler_))
    ui.bindClick(self:getViewData().commitBtn, handler(self, self.onClickCommitButtonHandler_))
    ui.bindClick(self:getViewData().retryBtn, handler(self, self.onClickRetryBtnHandler_))
    ui.bindClick(self:getViewData().bindingBtn, handler(self, self.onClickBindingBtnHandler_))
    self:getViewData().accountEditBox:registerScriptEditBoxHandler(handler(self, self.onEditBoxStateChangeHandler_))
    self:getViewData().codeEditBox:registerScriptEditBoxHandler(handler(self, self.onEditBoxStateChangeHandler_))

    self:initHomeData_(checkstr(self.ctorArgs_.code))
end


function AccountMigrationMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function AccountMigrationMediator:OnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightHide')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'allhide')

    regPost(POST.TRANSFER_VERIFY_EMAIL)
    regPost(POST.TRANSFER_TO_EMAIL)
end


function AccountMigrationMediator:OnUnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightShow')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'hide')

    unregPost(POST.TRANSFER_VERIFY_EMAIL)
    unregPost(POST.TRANSFER_TO_EMAIL)
end


function AccountMigrationMediator:InterestSignals()
    return {
        POST.TRANSFER_VERIFY_EMAIL.sglName,
        POST.TRANSFER_TO_EMAIL.sglName,
    }
end
function AccountMigrationMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.TRANSFER_VERIFY_EMAIL.sglName then
        -- open clock update retry time
        self:getViewData().codeBtn:setEnabled(false)
        self:setCodeLeftStamp(os.time() + 60)
        self.codeRefreshClocker_:start()
    elseif name == POST.TRANSFER_TO_EMAIL.sglName then
        self.codeRefreshClocker_:stop()
        self:getViewNode():updateResultLayerVisible(true)
        self:getViewNode():resetCodeState()
    end
end


-------------------------------------------------
-- get / set

function AccountMigrationMediator:getViewNode()
    return  self.viewNode_
end
function AccountMigrationMediator:getViewData()
    return self:getViewNode():getViewData()
end


function AccountMigrationMediator:getCodeLeftTime()
    return self:getCodeLeftStamp() - os.time()
end
function AccountMigrationMediator:setCodeLeftStamp(time)
    self.codeLeftStamp_ = time
end
function AccountMigrationMediator:getCodeLeftStamp()
    return checkint(self.codeLeftStamp_)
end

-------------------------------------------------
-- private

function AccountMigrationMediator:initHomeData_(data)
    local isShowResult = data ~= "" 
    self:getViewNode():updateResultLayerVisible(isShowResult)
end



-------------------------------------------------
-- public

function AccountMigrationMediator:close()
    self.codeRefreshClocker_:stop()
    app.router:Dispatch({name = 'AccountMigrationMediator'}, {name = 'HomeMediator'})
end


-------------------------------------------------
-- handler
function AccountMigrationMediator:onCodeRefreshUpdateHandler_()
    local leftTime = self:getCodeLeftTime()
    if leftTime <= 0 then
        --- reset button state
        self:getViewNode():resetCodeBtnState()
        self.codeRefreshClocker_:stop()
    else
        local codeBtnStr = string.fmt(__("_seconds_秒后可重发"), {_seconds_ = tostring(leftTime)})
        self:getViewData().codeBtn:setText(codeBtnStr)
    end
end

function AccountMigrationMediator:onEditBoxStateChangeHandler_(eventType, sender)
    if eventType == "return" then
        local text = string.trim(sender:getText())
        sender:setText(tostring(text))
    end
end

function AccountMigrationMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function AccountMigrationMediator:onClickCommitButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    -- check e-mail address
    local account = self:getViewData().accountEditBox:getText()
    if not string.match(account, "^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+$") then
        app.uiMgr:ShowInformationTips(__("请输入有效的邮箱地址"))
        return
    end

    -- check code is not null
    local code = string.trim(self:getViewData().codeEditBox:getText())
    if code == "" then
        app.uiMgr:ShowInformationTips(__("验证码不能为空！"))
        return
    end
    
    -- send signal
    self:SendSignal(POST.TRANSFER_TO_EMAIL.cmdName, {email = account, code = code})
end


function AccountMigrationMediator:onClickCodeButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    -- check e-mail address
    local account = self:getViewData().accountEditBox:getText()
    if not string.match(account, "^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+$") then
        app.uiMgr:ShowInformationTips(__("请输入有效的邮箱地址"))
        return
    end

    -- send signal
    self:SendSignal(POST.TRANSFER_VERIFY_EMAIL.cmdName, {email = account})
end


function AccountMigrationMediator:onClickRetryBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    -- udpatePage
    self:getViewNode():updateResultLayerVisible(false)
end


function AccountMigrationMediator:onClickBindingBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    FTUtils:openUrl("http://transfer-eater-kr-beta.duobaogame.com/sq_korea/index.html")
end


return AccountMigrationMediator
