--[[
个人设置 其他页签Mediator
--]]
local Mediator = mvc.Mediator
---@class PersonOtherMediator :Mediator
local PersonOtherMediator = class("PersonOtherMediator", Mediator)
local NAME = "PersonOtherMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local BUTTON_CLICK = {
   CUSTOM_SERVICE    = 1001, -- 客服
   FAQ               = 1002, -- 问题解答
   RANK              = 1003, -- 排行榜
   POLICY            = 1004, -- 用户协议
   HIDE_VIDEO_BTN    = 1005, -- 录像按钮隐藏
   FB                = 1006, -- 跳转到FB
   DISCORD           = 1007, -- 跳转到DISCORD
}
function PersonOtherMediator:ctor( layer, viewComponent )
    self.super:ctor(NAME,viewComponent)
end

function PersonOtherMediator:InterestSignals()
    local signals = {
        RELEASE_PRIVACY_POLICY,
        POST.USER_EUROPEAN_AGREEMENT.sglName
    }
    return signals
end
function PersonOtherMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type PersonOtherView
    self.viewComponent = require('Game.views.PersonOtherView').new()
    self:SetViewComponent(self.viewComponent)
    -- 绑定按钮回调
    for i, v in ipairs(self.viewComponent.viewData.buttons) do
        v:setOnClickScriptHandler(handler(self, self.ButtonAction))
    end
end

function PersonOtherMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == RELEASE_PRIVACY_POLICY then -- 撤销隐私协议
        self:SendSignal(POST.USER_EUROPEAN_AGREEMENT.cmdName, {userId = gameMgr:GetUserInfo().userId, isAgree = 0})
        -- 退出至主页面
    elseif name == POST.USER_EUROPEAN_AGREEMENT.sglName then
        if isElexSdk() then
            --elex平台时
            local AppSDK = require('root.AppSDK')
            AppSDK.GetInstance():QuickLogout()
        end
    end
end

function PersonOtherMediator:ButtonAction(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if tag == BUTTON_CLICK.CUSTOM_SERVICE then  -- 客服
        if isElexSdk() then
            --调用帮助页面接口
            if device.platform == 'android' and FTUtils:getTargetAPIVersion() >= 16 then
                local AppSDK = require('root.AppSDK')
                AppSDK:AIHelper({isSetCustom = true})
            else
                local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
                local userInfo = gameMgr:GetUserInfo()
                ECServiceCocos2dx:setUserId(userInfo.playerId)
                ECServiceCocos2dx:setUserName(userInfo.playerName)
                ECServiceCocos2dx:setServerId(userInfo.serverId)
                local lang = i18n.getLang()
                local tcountry = string.split(lang, '-')[1]
                if not tcountry then tcountry = 'en' end
                if tcountry == 'zh' then tcountry = 'zh_TW' end
                ECServiceCocos2dx:setSDKLanguage(tcountry)
                ECServiceCocos2dx:showElva(tostring(userInfo.playerName),
                    tostring(userInfo.playerId),
                    checkint(userInfo.serverId),
                    "",
                    "1",{["aihelp-custom-metadata"] = {
                            ["aihelp-tags"] = "vip0,s0,and_usa",
                            ["level"] = tostring(userInfo.level),
                            ["playerId"] = tostring(userInfo.playerId),
                            ["server"]  = "0",
                            ["Conversation"] = "1",
                            ["playerName"] = tostring(userInfo.playerName),
                            ["channel"] = "and_usa",
                            ["viplevel"] = "0",
                            ["resVersion"] = tostring(utils.getAppVersion()),
                    }})
            end

        end
    elseif tag == BUTTON_CLICK.FAQ then -- FAQ
        if isElexSdk() then
            local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
            local userInfo = gameMgr:GetUserInfo()
            ECServiceCocos2dx:setUserId(userInfo.playerId)
            ECServiceCocos2dx:setUserName(userInfo.playerName)
            ECServiceCocos2dx:setServerId(userInfo.serverId)
            local lang = i18n.getLang()
            local tcountry = string.split(lang, '-')[1]
            if not tcountry then tcountry = 'en' end
            if tcountry == 'zh' then tcountry = 'zh_TW' end
            local config = {
                showContactButtonFlag = "1" , 
                showConversationFlag = "1" , 
                directConversation = "1"
             }
            ECServiceCocos2dx:setSDKLanguage(tcountry)
            ECServiceCocos2dx:showFAQs(config)
        end
    elseif tag == BUTTON_CLICK.RANK then -- 排行榜
        --调用显示成就的页面
        require("root.AppSDK").GetInstance():PreviewArchivement()
    elseif tag == BUTTON_CLICK.POLICY then -- 用户协议
        local PrivacyPolicyView = require( 'Game.views.PrivacyPolicyView' ).new({isRevoked = true})
        PrivacyPolicyView:setPosition(display.center)
        local scene = uiMgr:GetCurrentScene()
        scene:AddDialog(PrivacyPolicyView)
    elseif tag == BUTTON_CLICK.FB then -- 录像按钮隐藏
        FTUtils:openUrl("https://www.facebook.com/foodfantasygame/")
    elseif tag == BUTTON_CLICK.DISCORD then -- 录像按钮隐藏
        FTUtils:openUrl("https://discord.gg/cj5dDwD")
    elseif tag == BUTTON_CLICK.HIDE_VIDEO_BTN then -- 录像按钮隐藏
        local shareUserDefault = cc.UserDefault:getInstance()
        local isOpen = shareUserDefault:getBoolForKey("ELEX_IOS_RECORD_VIDEO", false)
        if isOpen then
            sender:setText(__('录像按钮开启'))
        else
            sender:setText(__('录像按钮隐藏'))
        end
        shareUserDefault:setBoolForKey("ELEX_IOS_RECORD_VIDEO",(not isOpen))
        shareUserDefault:flush()
    end
end
function PersonOtherMediator:OnRegist()
    regPost(POST.USER_EUROPEAN_AGREEMENT)
end

function PersonOtherMediator:OnUnRegist()
    unregPost(POST.USER_EUROPEAN_AGREEMENT)
end

return PersonOtherMediator



