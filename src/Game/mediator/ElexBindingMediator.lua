--[[
登录注册mediator
--]]
local Mediator = mvc.Mediator
local ElexBindingMediator = class("ElexBindingMediator", Mediator)
local NAME = "ElexBindingMediator"


local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function ElexBindingMediator:ctor( viewComponent )
	self.super:ctor(NAME, viewComponent)
end

function ElexBindingMediator:InterestSignals()
	local signals = {
		POST.ACCOUNT_UNBIND.sglName,
		POST.ACCOUNT_BIND.sglName,
	}
	return signals
end

function ElexBindingMediator:Initial( key )
	self.super.Initial(self,key)
    self.isloaded = false
    local scene = uiMgr:GetCurrentScene()
    local viewComponent  = require( 'Game.views.ElexBindingView' ).new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    viewComponent:setName("ElexBindingView")
    scene:AddDialog(viewComponent)

end

function ElexBindingMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local data = signal:GetBody()
	if POST.ACCOUNT_BIND.sglName == name then
        --绑定
        local requestData = data.requestData
        --更新界面表现
        local loginWay = checkint(requestData.loginWay)
        local view = self:GetViewComponent()
        local button = view.viewData_.view:getChildByName("GOOGLE")
        if loginWay == 2 then
            --facebook
            button = view.viewData_.view:getChildByName("FACEBOOK")
        elseif loginWay == 4  then
            button = view.viewData_.view:getChildByName("APPLE")
        end
        -- local view = self:GetViewComponent()
        -- local button = view.viewData_.view:getChildByName(string.upper(name))
        if button then
            if loginWay == 2 then
                button:setNormalImage(_resEx('update/button_facebook_disabled' , nil,device.platform))
                button:setSelectedImage(_resEx('update/button_facebook_disabled', nil,device.platform))
            elseif loginWay == 3 then
                --gamecenter
                button:setNormalImage(_res(string.format('update/button_gamecenter_disabled')))
                button:setSelectedImage(_res(string.format('update/button_gamecenter_disabled')))
            elseif loginWay == 4 then
                button:setNormalImage(_res(string.format('update/btton_apple_disabled')))
                button:setSelectedImage(_res(string.format('update/btton_apple_disabled')))
            else
                button:setNormalImage(_resEx('update/button_google_disabled',nil, device.platform))
                button:setSelectedImage(_resEx('update/button_google_disabled',nil, device.platform))
            end
        end
    elseif POST.ACCOUNT_UNBIND.sglName == name then
        --解绑定
        local requestData = data.requestData
        local loginWay = checkint(requestData.loginWay)
        local view = self:GetViewComponent()
        local button = view.viewData_.view:getChildByName("GOOGLE")
        if loginWay == 2 then
            --facebook
            button = view.viewData_.view:getChildByName("FACEBOOK")
        elseif loginWay == 4  then
            button = view.viewData_.view:getChildByName("APPLE")
        end
        if button then
            if loginWay == 2 then
                button:setNormalImage(_resEx('update/button_facebook' , nil , device.platform))
                button:setSelectedImage(_resEx('update/button_facebook', nil , device.platform))
            elseif loginWay == 3 then
                button:setNormalImage(_res('update/button_gamecenter'))
                button:setSelectedImage(_res('update/button_gamecenter'))
            elseif  loginWay == 4 then
                button:setNormalImage(_res(string.format('update/btton_apple')))
                button:setSelectedImage(_res(string.format('update/btton_apple')))
            else
                button:setNormalImage(_resEx('update/button_google', nil , device.platform))
                button:setSelectedImage(_resEx('update/button_google', nil , device.platform))
            end
        end
    end
end

function ElexBindingMediator:OnRegist()
    --初始化视图页面
    self.preIndex = 1001
    local view = self:GetViewComponent()
    view.viewData_.buttons[tostring(1001)]:setChecked(true)
    view.viewData_.buttons[tostring(1001)]:setOnClickScriptHandler(handler(self, self.ButtonActions))
    view.viewData_.buttons[tostring(1002)]:setChecked(false)
    view.viewData_.buttons[tostring(1002)]:setOnClickScriptHandler(handler(self, self.ButtonActions))

    view.viewData_.googleButton:setOnClickScriptHandler(handler(self, self.AccountActions))
    view.viewData_.facebookButton:setOnClickScriptHandler(handler(self, self.AccountActions))
    if device.platform == 'ios' then
        view.viewData_.appleButton:setOnClickScriptHandler(handler(self, self.AccountActions))
    end
    self:SwitchTab(1001)
end


function ElexBindingMediator:SwitchTab(tag)
    local view = self:GetViewComponent()
    if tag == 1001 then
        local channels = gameMgr:GetUserInfo().bindChannels
        if table.nums(channels) > 0 then
            if device.platform == 'ios' then
                if channels['2'] then
                    --存在fb
                    view.viewData_.facebookButton:setNormalImage(_resEx("update/button_facebook_disabled" , nil,device.platform))
                    view.viewData_.facebookButton:setSelectedImage(_resEx("update/button_facebook_disabled" ,nil, device.platform))
                else
                    view.viewData_.facebookButton:setNormalImage(_resEx("update/button_facebook" , nil,device.platform))
                    view.viewData_.facebookButton:setSelectedImage(_resEx("update/button_facebook" ,nil, device.platform))
                end
                if channels['3'] then
                    view.viewData_.googleButton:setNormalImage(_res("update/button_gamecenter_disabled"))
                    view.viewData_.googleButton:setSelectedImage(_res("update/button_gamecenter_disabled"))
                else
                    view.viewData_.googleButton:setNormalImage(_res("update/button_gamecenter"))
                    view.viewData_.googleButton:setSelectedImage(_res("update/button_gamecenter"))
                end

                if channels['4'] then
                    --存在gamecenter
                    view.viewData_.appleButton:setNormalImage(_res("update/btton_apple_disabled"))
                    view.viewData_.appleButton:setSelectedImage(_res("update/btton_apple_disabled"))
                else
                    view.viewData_.appleButton:setNormalImage(_res("update/btton_apple"))
                    view.viewData_.appleButton:setSelectedImage(_res("update/btton_apple"))
                end
            else
                if channels['2'] then
                    --存在fb
                    view.viewData_.facebookButton:setNormalImage(_resEx("update/button_facebook_disabled" ,nil, device.platform))
                    view.viewData_.facebookButton:setSelectedImage(_resEx("update/button_facebook_disabled" , nil,device.platform))
                else
                    view.viewData_.facebookButton:setNormalImage(_resEx("update/button_facebook", nil,device.platform))
                    view.viewData_.facebookButton:setSelectedImage(_resEx("update/button_facebook",nil, device.platform))
                end
                if channels['1'] then
                    view.viewData_.googleButton:setNormalImage(_resEx("update/button_google_disabled" , nil,device.platform))
                    view.viewData_.googleButton:setSelectedImage(_resEx("update/button_google_disabled" , nil,device.platform))
                else
                    view.viewData_.googleButton:setNormalImage(_resEx("update/button_google", nil,device.platform))
                    view.viewData_.googleButton:setSelectedImage(_resEx("update/button_google", nil,device.platform))
                end
            end
        end
    elseif tag == 1002 then
        --切换的逻辑
        view.viewData_.facebookButton:setNormalImage(_resEx("update/button_facebook" ,nil, device.platform ))
        view.viewData_.facebookButton:setSelectedImage(_resEx("update/button_facebook" , nil,device.platform))
        if device.platform == 'ios' then
            view.viewData_.googleButton:setNormalImage(_res("update/button_gamecenter"))
            view.viewData_.googleButton:setSelectedImage(_res("update/button_gamecenter"))

            view.viewData_.appleButton:setNormalImage(_res("update/btton_apple"))
            view.viewData_.appleButton:setSelectedImage(_res("update/btton_apple"))
        else
            view.viewData_.googleButton:setNormalImage(_resEx("update/button_google"  , nil,device.platform))
            view.viewData_.googleButton:setSelectedImage(_resEx("update/button_google"  , nil,device.platform))
        end
    end
end


function ElexBindingMediator:AccountActions(sender)
    PlayAudioByClickNormal()
    local name = string.lower(sender:getName())
    if self.preIndex == 1002 then
        --切换账号的逻辑
        if gameMgr:GetUserInfo().isGuest == 1 then
        --如果是游客的时候弹出提示
            local scene = uiMgr:GetCurrentScene()
            local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('警告！当前账号未绑定切换会丢失数据，是否继续？'),
                isOnlyOK = false, noNeedRemove = true, callback = function ()
                    local pMediator = AppFacade.GetInstance():RetrieveMediator("PersonInformationMediator")
                    if pMediator then
                        pMediator:AccountHandleType(2)
                        local AppSDK = require('root.AppSDK')
                        AppSDK.GetInstance():InvokeLogin({name = name})
                    end
            end})
            CommonTip:setPosition(display.center)
            scene:AddDialog(CommonTip)
        else
            local scene = uiMgr:GetCurrentScene()
            local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('警告！切换账号可能会导致数据覆盖，是否继续？'),
                isOnlyOK = false, noNeedRemove = true, callback = function ()
                    local pMediator = AppFacade.GetInstance():RetrieveMediator("PersonInformationMediator")
                    if pMediator then
                        pMediator:AccountHandleType(2)
                        local AppSDK = require('root.AppSDK')
                        AppSDK.GetInstance():InvokeLogin({name = name})
                    end
            end})
            CommonTip:setPosition(display.center)
            scene:AddDialog(CommonTip)
        end
    else
        --绑定账号以及解绑的相关逻辑
        local key = 2 -- facebook
        if name == 'google' then
            key = 1
            if device.platform == "ios" then
                key = 3

            end
        elseif name == 'apple' then
            key = 4
        end
        if gameMgr:GetUserInfo().bindChannels[tostring(key)] then
            --这里是解绑的逻辑
            local channelInfo = gameMgr:GetUserInfo().bindChannels[tostring(key)]
                local userId = gameMgr:GetUserInfo().userId
                local loginWay = channelInfo.loginWay
                local openId = channelInfo.openId
                local scene = uiMgr:GetCurrentScene()
                local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('警告！解绑危险是否继续？'),
                        isOnlyOK = false, callback = function ()
                        -- self:SendSignal(POST.ACCOUNT_UNBIND.cmdName, {userId = userId, openId = openId, name = name, loginWay = loginWay})
                        local pMediator = AppFacade.GetInstance():RetrieveMediator("PersonInformationMediator")
                        if pMediator then
                            pMediator:AccountHandleType(3)
                            local AppSDK = require('root.AppSDK')
                            AppSDK.GetInstance():InvokeLogin({name = name, override = false})
                        end

                    end})
                CommonTip:setPosition(display.center)
                scene:AddDialog(CommonTip)
         else
            --不存在,可以直接绑定
            -- if isGuest == 0 then
                -- local scene = uiMgr:GetCurrentScene()
                -- local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('警告！当前账号已绑定是否再次绑定'),
                    -- isOnlyOK = false, callback = function()
                                    -- end})
                -- CommonTip:setPosition(display.center)
                -- scene:AddDialog(CommonTip)
                local pMediator = AppFacade.GetInstance():RetrieveMediator("PersonInformationMediator")
                if pMediator then
                    pMediator:AccountHandleType(1)
                    local AppSDK = require('root.AppSDK')
                    AppSDK.GetInstance():InvokeLogin({name = name})
                end
                -- else
                -- local pMediator = AppFacade.GetInstance():RetrieveMediator("PersonInformationMediator")
                -- if pMediator then
                -- pMediator:AccountHandleType(1)
                -- local AppSDK = require('root.AppSDK')
                -- AppSDK.GetInstance():InvokeLogin({name = name})
                -- end
                -- end
            end
        end
end

function ElexBindingMediator:ButtonActions(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    sender:setChecked(true)
    local view = self:GetViewComponent()
    view.viewData_.buttons[tostring(self.preIndex)]:setChecked(false)
    self:SwitchTab(tag)
    self.preIndex = tag
end

function ElexBindingMediator:OnUnRegist()
    --local scene = uiMgr:GetCurrentScene()
    --scene:RemoveDialogByName("ElexBindingView")
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return ElexBindingMediator
