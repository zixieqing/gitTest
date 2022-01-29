--[[
隐私协议页面
--]]
local PrivacyPolicyView = class('PrivacyPolicyView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.PrivacyPolicyView'
	node:enableNodeEvents()
	return node
end)

local function CreateView( self )
    local view = CLayout:create(display.size)
    local touchLayout = CColorView:create(cc.c4b(0,0,0,255*0.6))
    touchLayout:setContentSize(display.size)
    touchLayout:setTouchEnabled(true)
    touchLayout:setPosition(display.center)
    view:addChild(touchLayout)

    local bg = display.newImageView(_res('update/notice_bg'), 0, 0)
    local cview = CLayout:create(bg:getContentSize())
    display.commonUIParams(cview, {po = display.center})
    view:addChild(cview)
    bg:setPosition(FTUtils:getLocalCenter(cview))
    cview:addChild(bg)
    -- 添加标题
    local quitButton = display.newButton(1100,624, {
            n = _res('update/notice_btn_quit')
        })
    cview:addChild(quitButton,2)
    local csize = bg:getContentSize()
    local titleImage = display.newImageView(_res('update/notice_title_bg'),csize.width * 0.5,616)
    cview:addChild(titleImage, 3)
    local loadingTipsLabel = display.newLabel(csize.width * 0.5, 615, fontWithColor(14,
        {text = __('隐私协议'), reqW = 150 ,hAlign =display.TAC ,
        fontSize = 28, color = 'ffdf89', hAlign = display.TAC,outline = '5d3c25', outlineSize = 1 }))
    cview:addChild(loadingTipsLabel)

    -- 解除协议
    local bottomBtn = display.newButton(csize.width/2, 40, {n = _res('ui/common/common_btn_orange.png'), scale9 = true})
    cview:addChild(bottomBtn, 5)
    
    local webViewSize = nil
    local checkBoxLayout = nil 
    local policyCheckBox = nil 
    local ageCheckBox = nil
    if self.isRevoked then
        webViewSize = cc.size(1014, 500)
        display.commonLabelParams(bottomBtn, fontWithColor(14, {paddingW = 20 ,  text = __('撤销同意')}))
    else
        webViewSize = cc.size(1014, 430)
        display.commonLabelParams(bottomBtn, fontWithColor(14, {text = __('确定')}))
        local checkBoxLayoutSize = cc.size(csize.width, 40)
        local checkBoxLayout = CLayout:create(checkBoxLayoutSize)
        checkBoxLayout:setPosition(csize.width / 2, 135)
        cview:addChild(checkBoxLayout, 5)

		policyCheckBox = display.newCheckBox(75, checkBoxLayoutSize.height/2, {
			n = _res('ui/common/common_btn_check_default.png'),
            s = _res('ui/common/common_btn_check_selected.png')
		})
		checkBoxLayout:addChild(policyCheckBox)
		local policyBtn = display.newButton(100, checkBoxLayoutSize.height/2, {n = _res('update/login_bg_clause.png'), ap = display.LEFT_CENTER, enable = false})
		display.commonLabelParams(policyBtn, {text = __('我已阅读并同意隐私政策条款'), fontSize = 20, color = '#ffffff', ap = display.LEFT_CENTER, offset = cc.p(- 225, 0), reqW = 440})
		checkBoxLayout:addChild(policyBtn)
        
		ageCheckBox = display.newCheckBox(checkBoxLayoutSize.width/2 + 25, checkBoxLayoutSize.height/2, {
			n = _res('ui/common/common_btn_check_default.png'),
            s = _res('ui/common/common_btn_check_selected.png')
		})	
		checkBoxLayout:addChild(ageCheckBox)

        if app.gameMgr:GetUserInfo().isEURegion ~= 2 then

            local ageBtn = display.newButton(checkBoxLayoutSize.width/2 + 50, checkBoxLayoutSize.height/2, {n = _res('update/login_bg_clause.png'), ap = display.LEFT_CENTER, enable = false})
            display.commonLabelParams(ageBtn, {text = __('年满16岁'), fontSize = 20, color = '#ffffff', ap = display.LEFT_CENTER, offset = cc.p(- 225, 0), reqW = 440})
            checkBoxLayout:addChild(ageBtn)
            local tipsLabel = display.newLabel(csize.width/2, 90, fontWithColor(15, {text = __('同意隐私协议并达到16周岁才可进入游戏')}))
            cview:addChild(tipsLabel, 10)
        else
            ageCheckBox:setVisible(false)
        end

    end
    -- 创建webView
    local _webView = nil
    if isElexSdk() and (not isNewUSSdk()) then
        _webView = ccexp.WebView:create()
        _webView:setAnchorPoint(cc.p(0.5, 1))
        _webView:setPosition(csize.width * 0.5, csize.height - 78)
        _webView:setContentSize(webViewSize)
        _webView:setTag(2345)
        _webView:setScalesPageToFit(true)
        _webView:setOnShouldStartLoading(handler(self, self.HandleH5Request))
        cview:addChild(_webView,2)
        _webView:loadURL("https://foodzm-eater.oss-us-west-1.aliyuncs.com/shortplicy.html")

        local label = display.newLabel(0 , 0 , fontWithColor(14, {
            ap= display.LEFT_BOTTOM, text ="Full Privacy Policy" , hAlign =display.TAC ,
            fontSize = 28, color = 'ffdf89', hAlign = display.TAC,outline = '5d3c25', outlineSize = 1
        }))
        local labelSize = display.getLabelContentSize(label)
        local labelLayer = display.newLayer(csize.width-108  , 48 ,  {
            ap = display.RIGHT_BOTTOM ,
            size = labelSize  ,
            color = cc.c4b(0,0,0,0) ,
            enable = true ,
            cb = function()
                local privacyFullLayer = require("Game.views.PrivacyWebView").new({
                  url = "https://foodzm-eater.oss-us-west-1.aliyuncs.com/fullpolicy.html" ,
                  title = "Full Privacy Policy"
                })
                privacyFullLayer:setPosition(display.center)
                app.uiMgr:GetCurrentScene():AddDialog(privacyFullLayer)
            end
        })
        cview:addChild(labelLayer)
        labelLayer:addChild(label)
        local labelSize  = display.getLabelContentSize(label)
        local blueLine = display.newLayer(csize.width-108  , 48,{ap = display.RIGHT_BOTTOM , size= cc.size(labelSize.width  , 2.5 ) , color ="#5b3c35"})
        cview:addChild(blueLine)
    else
        if device.platform == 'ios' or device.platform == 'android' then
            _webView = ccexp.WebView:create()
            _webView:setAnchorPoint(cc.p(0.5, 1))
            _webView:setPosition(csize.width * 0.5, csize.height - 78)
            _webView:setContentSize(webViewSize)
            _webView:setTag(2345)
            _webView:setScalesPageToFit(true)
            cview:addChild(_webView,2)

            if not tolua.isnull(_webView) then
                local apath = cc.FileUtils:getInstance():fullPathForFilename('update/privacyPolicy.html')
                _webView:loadHTMLString( FTUtils:getFileData(apath), "")
                -- _webView:loadFile(apath)
            end
        end
    end


	return {
		view 	       = view,
		quitButton     = quitButton,
        bottomBtn      = bottomBtn,
        policyCheckBox = policyCheckBox,
        ageCheckBox    = ageCheckBox,
        loadingTipsLabel    = loadingTipsLabel,
        _webView       = _webView,
	}
end


function PrivacyPolicyView:ctor( ... )
    local args = unpack({...})
    self.isRevoked = args.isRevoked == nil or args.isRevoked -- 是否显示解除按钮
    self.callback = args.callback -- 同意协议后的回调
	self.viewData = CreateView( self )
	self:addChild(self.viewData.view, 1)
    self.viewData.view:setPosition(utils.getLocalCenter(self))
    if not self.isRevoked then -- 是否为注销页面
        self.viewData.policyCheckBox:setOnClickScriptHandler(handler(self, self.CheckBoxCallback))  
        self.viewData.ageCheckBox:setOnClickScriptHandler(handler(self, self.CheckBoxCallback))  
    end
    display.commonUIParams(self.viewData.quitButton , { cb = function ()
            if self.viewData._webView then
                self.viewData._webView:setVisible(false)
            end
            if app.gameMgr:GetUserInfo().isEURegion ~= 2 then
                local CommonTip  = require( 'common.NewCommonTip' ).new({
                    text = __('确定要关闭吗？'),
                    extra = __('同意隐私协议并达到16周岁才可进入游戏'),
                    isForced = true,
                    isOnlyOK = false,
                    callback = function ()
                        self:runAction(cc.RemoveSelf:create())
                    end,
                    cancelBack = function ()
                        if self.viewData._webView then
                            self.viewData._webView:setVisible(true)
                        end
                    end
                })
                CommonTip:setPosition(display.center)
                app.uiMgr:GetCurrentScene():AddDialog(CommonTip)
            else
                self:runAction(cc.RemoveSelf:create())
            end
        end
    })
    self.viewData.bottomBtn:setOnClickScriptHandler(function ()
        if self.isRevoked then
            local scene = AppFacade.GetInstance():GetManager("UIManager"):GetCurrentScene()
            local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('若撤销同意我们将暂停该账号的服务，是否确认撤销？'),
                isOnlyOK = false, callback = function ()
                    AppFacade.GetInstance():DispatchObservers(RELEASE_PRIVACY_POLICY)
                end})
            CommonTip:setPosition(display.center)
            scene:AddDialog(CommonTip)
            self:runAction(cc.RemoveSelf:create())
        else
            if self:IsAgreedPolicy() then
                if self.callback then
                    self:callback()
                    self:runAction(cc.RemoveSelf:create())
                end
            -- else
            --     AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTips(__('同意隐私协议并达到16周岁才可进入游戏'))
            end
        end
    end)
    if not self.isRevoked then
        self:RefreshBottomBtnState()
    end
    self:RegistObserver()
end
function PrivacyPolicyView:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == SGL.PRIVACY_POLICY_WEBVIW_SHOW_EVENT then
        local viewData = self.viewData
        if viewData._webView and (not tolua.isnull(viewData._webView)) then
            viewData._webView:setVisible(body.isVisible)
        end
    end
end
function PrivacyPolicyView:HandleH5Request(webview,url)
    local scheme = 'liuzhipeng'
    local urlInfo = string.split(url, '://')
    if 2 == table.nums(urlInfo) then
        if urlInfo[1] == scheme then
            local urlParams = string.split(urlInfo[2], '&')
            local params = {}
            for k,v in pairs(urlParams) do
                local param = string.split(v, '=')
                -- 构造表单做get请求 所以结尾多一个？
                params[param[1]] = string.split(param[2], '?')[1]
            end
            if params.action then
                if 'getPrivacy' == params.action then
                    local privacyFullLayer = require("Game.views.PrivacyWebView").new({
                      url =  "https://foodzm-eater.oss-us-west-1.aliyuncs.com/fullpolicy.html?#security6" ,
                      title = "Full Privacy Policy"
                    })
                    privacyFullLayer:setPosition(display.center)
                    app.uiMgr:GetCurrentScene():AddDialog(privacyFullLayer)
                elseif 'getServe' == params.action then
                    local privacyFullLayer = require("Game.views.PrivacyWebView").new({
                      url = "https://foodzm-eater.oss-us-west-1.aliyuncs.com/service.html" ,
                      title = "WebView Content"
                    })
                    privacyFullLayer:setPosition(display.center)
                    app.uiMgr:GetCurrentScene():AddDialog(privacyFullLayer)
                elseif  'getAdaptant' == params.action then
                    local privacyFullLayer = require("Game.views.PrivacyWebView").new({
                        url = "https://www.adaptant.io/contacts-locations/." ,
                        title = "WebView Content"
                    })
                    privacyFullLayer:setPosition(display.center)
                    app.uiMgr:GetCurrentScene():AddDialog(privacyFullLayer)
                else
                    return true
                end
            end
            return false
        end
    end
    return true
end
--[[
判断条款是否完全同意
--]]
function PrivacyPolicyView:IsAgreedPolicy()
    local policyChecked = self.viewData.policyCheckBox:isChecked()
    local ageChecked = true
    if app.gameMgr:GetUserInfo().isEURegion ~= 2 then
        ageChecked = self.viewData.ageCheckBox:isChecked()
    end
    local isAgreed = policyChecked and ageChecked
    return isAgreed
end
--[[
选中框点击回调
--]]
function PrivacyPolicyView:CheckBoxCallback()
    self:RefreshBottomBtnState()
end
--[[
更新按钮状态
--]]
function PrivacyPolicyView:RefreshBottomBtnState()
    local bottomBtn = self.viewData.bottomBtn
    if self:IsAgreedPolicy() then
        bottomBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
        bottomBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
    else
        bottomBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
        bottomBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
    end
end
function PrivacyPolicyView:RegistObserver()
    AppFacade.GetInstance():RegistObserver(SGL.PRIVACY_POLICY_WEBVIW_SHOW_EVENT, mvc.Observer.new(self.ProcessSignal , self) )
end
function PrivacyPolicyView:onCleanup()
    AppFacade.GetInstance():UnRegistObserver(SGL.PRIVACY_POLICY_WEBVIW_SHOW_EVENT , self)
end
return PrivacyPolicyView
