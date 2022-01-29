
---
--- Created by xingweihao.
--- DateTime: 27/09/2017 2:35 PM
--- 交易和探索的修改

local Mediator = mvc.Mediator
---@class PersonInformationMediator :Mediator
local PersonInformationMediator = class("PersonInformationMediator", Mediator)
local NAME = "PersonInformationMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local BUTTON_CLICK = {
    INFORCLICK = 1004 , -- 个人信息点击事件
    SYSTEMCLICK = 1005 , --系统设置
    PUSHCLICK = 1006 ,  -- 推送设置
    OTHER = 1008,       -- 其他
    EXCHANGE_NUM = 100011 , -- 兑换码
}
local PersonTableMediator = {
   [tostring(BUTTON_CLICK.SYSTEMCLICK)]  = "PersonInformationSystemMediator",
   [tostring(BUTTON_CLICK.INFORCLICK)]   = "PersonInformationDetailMediator",
   [tostring(BUTTON_CLICK.EXCHANGE_NUM)] = "ExchangeMediator",
   [tostring(BUTTON_CLICK.OTHER)]        = "PersonOtherMediator"
}
function PersonInformationMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.datas = params or {}
    self.collectMediator = {} -- 用于收集和管理mediator
    self.preIndex = nil  -- 上一次点击
end

function PersonInformationMediator:InterestSignals()
    local signals = {
        EVENT_SDK_LOGIN,
		POST.ACCOUNT_UNBIND.sglName,
		POST.ACCOUNT_BIND.sglName,
        POST.ELEX_USER_CHANNEL_LOGIN.sglName
    }
    return signals
end
function PersonInformationMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type PersonInformationNewView
    self.viewComponent = require("Game.views.PersonInformationNewView").new()
    local viewData = self.viewComponent.viewData
    self:SetViewComponent(self.viewComponent)
    self.viewComponent:setPosition(display.center)
    viewData.closeView:setOnClickScriptHandler(function ()
        PlayAudioByClickClose()
        self:CloseMediator()
    end)

    local scene = uiMgr:GetCurrentScene()
    if scene and not tolua.isnull(scene) and scene.AddDialog then
        scene:AddDialog(self.viewComponent)
    else
        sceneWorld:add(self.viewComponent)
        self.viewComponent:setVisible(false)
        self.viewComponent:stopAllActions()
        self.viewComponent:runAction(cc.Sequence:create(
            cc.DelayTime:create(0.1),
            cc.CallFunc:create(function()
                self:CloseMediator()
            end)
        ))
        return
    end

    self:ButtonAction(viewData.buttonTable[tostring(BUTTON_CLICK.INFORCLICK)])
    if CommonUtils.JuageMySelfOperation(self.datas.playerId) then
        for i, v in pairs(viewData.buttonTable) do
            v:setOnClickScriptHandler(handler(self ,self.ButtonAction))
        end
    else
        viewData.buttonLayot:setVisible(false)
    end
end

-- 关闭mediator
function PersonInformationMediator:CloseMediator()
    for k , v in pairs(self.collectMediator) do
        self:GetFacade():UnRegsitMediator(k)
    end
    self:GetFacade():UnRegsitMediator(NAME)
end
-- 点击事件
function  PersonInformationMediator:ButtonAction(sender)
    local tag = sender:getTag()

    local name = PersonTableMediator[tostring(tag)]
    if not  name then -- 没有该观察者就直接报错
        return
    end
    if   not  self.collectMediator[name] then
        local mediator = require("Game.mediator." .. name).new(self.datas)
        self:GetFacade():RegistMediator(mediator)
        self.viewComponent.viewData.contentLayout:addChild(mediator:GetViewComponent())
        mediator:GetViewComponent():setPosition(cc.p(982/2 , 562/2))
        self.collectMediator[name] = mediator
    end

    if self.preIndex then
        if self.preIndex == tag then
            return
        else
            self:DealWithButtonStatus(self.preIndex , false)
            self:DealWithButtonStatus(tag , true)
            local preName =  PersonTableMediator[tostring(self.preIndex)]
            self.collectMediator[preName]:GetViewComponent():setVisible(false)
            if 'PersonInformationSystemMediator' == preName then
                self.collectMediator[preName]:SetControlSliderEnabled(false)
            end
            self.collectMediator[name]:GetViewComponent():setVisible(true)
            if 'PersonInformationSystemMediator' == name then
                self.collectMediator[name]:SetControlSliderEnabled(true)
            end
            self.preIndex = tag
        end
        PlayAudioByClickNormal()
    else
        self:DealWithButtonStatus(tag , true)
        self.preIndex = tag
    end
    if tag == BUTTON_CLICK.INFORCLICK then
        self.viewComponent.viewData.bg:setTexture(_res('ui/home/infor/personal_information_bg.png'))
    else
        self.viewComponent.viewData.bg:setTexture(_res('ui/common/common_bg_13.png'))
    end
end
--- 处理btn 的状态
function PersonInformationMediator:DealWithButtonStatus(tag , selected)
    local name = PersonTableMediator[tostring(tag)]
    if not  name then -- 没有该观察者就直接报错
        return
    end
    local sender = self.viewComponent.viewData.buttonLayot:getChildByTag(tag)
    local  label = sender:getChildByTag(111)
    local  fontSize = 22
    if display.getLabelContentSize(label ).height > 50  then
        fontSize = 19
    end
    if  sender  then
        if selected then
            sender:setChecked(true)
            sender:setEnabled(false)


            display.commonLabelParams(label,fontWithColor('10',{ fontSize = 19 }))
        else
            sender:setChecked(false)
            sender:setEnabled(true)
            display.commonLabelParams(label,fontWithColor('6',{fontSize = 19 }))
        end
    end
end

function PersonInformationMediator:EnterLayer()
    self:SendSignal(POST.BUSINESS_ORDER.cmdName)
end


function PersonInformationMediator:AccountHandleType(ltype)
    self.handleType = ltype --判断当前的账号操作是绑定还是切换的逻辑
end

function PersonInformationMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
	if POST.ACCOUNT_BIND.sglName == name then
        local requestData = data.requestData
        gameMgr:GetUserInfo().isGuest = 0
        local loginWay = checkint(requestData.loginWay)
        local openId = gameMgr:GetUserInfo().userSdkId
        gameMgr:GetUserInfo().bindChannels[tostring(loginWay)] = {loginWay = loginWay, openId = openId}
        app.badgeMgr:CheckHomeInforRed()
        if isElexSdk() and (not isNewUSSdk()) then
            if gameMgr:GetUserInfo().isBindAccountDrawn == 0  then
                self:SendSignal(POST.PLAYER_ZM_BIND_ACCOUNT.cmdName , {})
            end
        end
    elseif POST.ACCOUNT_UNBIND.sglName == name then
        local requestData = data.requestData
        --更新界面表现
        local loginWay = checkint(requestData.loginWay)
        local bindChannels = gameMgr:GetUserInfo().bindChannels
        bindChannels[tostring(loginWay)] = nil
        if table.nums(bindChannels) == 0 then
            gameMgr:GetUserInfo().isGuest = 1
        end
    elseif POST.ELEX_USER_CHANNEL_LOGIN.sglName == name then
        --渠道信息判断是出什么提示
        local errCode = checkint(data.errcode)
        if errCode == 0 then
            app:UnRegistMediator("ElexBindingMediator")
            --切换成功后的逻辑
            app.audioMgr:stopAndClean()
            uiMgr:PopAllScene()
            sceneWorld:getEventDispatcher():dispatchEvent(cc.EventCustom:new('APP_EXIT'))
        elseif errCode == -99 then
            local scene = uiMgr:GetCurrentScene()
            local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('警告！当前平台未绑定过，无法进行切换操作'),
                isOnlyOK = true, callback = function()
            end})
            CommonTip:setPosition(display.center)
            scene:AddDialog(CommonTip)
        end
    elseif EVENT_SDK_LOGIN == name then
        if isElexSdk() then
            if self.handleType == 2 then
                --切换账号的逻辑
                self:SendSignal(POST.ELEX_USER_CHANNEL_LOGIN.cmdName,{authCode = gameMgr:GetUserInfo().accessToken, uid = gameMgr:GetUserInfo().userSdkId, loginWay = data.loginPlatform})
            elseif self.handleType == 3 or self.handleType == 4 then
                --解绑账号的逻辑
                local userId = tostring(data.userId)
                local loginPlatform = checkint(data.loginPlatform)
                local bindChannels = gameMgr:GetUserInfo().bindChannels
                local gameUserId = gameMgr:GetUserInfo().userId
                local openId = tostring(bindChannels[tostring(loginPlatform)].openId)
                if userId == openId then
                    self:SendSignal(POST.ACCOUNT_UNBIND.cmdName, {userId = gameUserId, openId = openId, name = data.name, loginWay = loginPlatform})
                else
                    --登录fb不是同一个账号不能解绑的操作
                    local scene = uiMgr:GetCurrentScene()
                    local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('警告！当前账号绑定的社交媒体号不相同，无法进行解绑操作'),
                            isOnlyOK = true, callback = function()
                        end})
                        CommonTip:setPosition(display.center)
                        scene:AddDialog(CommonTip)
                    end
                else
                    --绑定账号的逻辑
                    local userId = gameMgr:GetUserInfo().userId
                    local openId = gameMgr:GetUserInfo().userSdkId
                    local loginPlatform = checkint(data.loginPlatform)
                    local loginWay = data.name
                    if loginWay == 'gamecenter' then loginWay = 'google' end
                    self:SendSignal(POST.ACCOUNT_BIND.cmdName, {userId = userId, openId = openId, name = loginWay, loginWay = loginPlatform})
                end
            end
    end
end
function PersonInformationMediator:GoogleBack()
    app:UnRegsitMediator(NAME)
    return true
end
function PersonInformationMediator:OnRegist()
    regPost(POST.ACCOUNT_BIND)
	regPost(POST.ACCOUNT_UNBIND)
    regPost(POST.ELEX_USER_CHANNEL_LOGIN, true)
end

function PersonInformationMediator:OnUnRegist()
    unregPost(POST.ACCOUNT_BIND)
    unregPost(POST.ACCOUNT_UNBIND)
    unregPost(POST.ELEX_USER_CHANNEL_LOGIN)
    for k , v in pairs(PersonTableMediator) do
        self:GetFacade():UnRegsitMediator(v)
    end
    if self.viewComponent and not tolua.isnull(self.viewComponent) then
        self.viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return PersonInformationMediator



