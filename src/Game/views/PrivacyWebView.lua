--[[
隐私协议页面
--]]
local PrivacyWebView = class('PrivacyWebView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.PrivacyWebView'
	node:enableNodeEvents()
	return node
end)

function PrivacyWebView:InitUI ()
	local touchLayout = CColorView:create(cc.c4b(0,0,0,255*0.6))
	touchLayout:setContentSize(display.size)
	touchLayout:setTouchEnabled(true)
	touchLayout:setPosition(display.center)
	self:addChild(touchLayout)
	local bg = display.newImageView(_res('update/notice_bg'), 0, 0)
	local cview = CLayout:create(bg:getContentSize())
	display.commonUIParams(cview, {po = display.center})
	self:addChild(cview)
	bg:setPosition(FTUtils:getLocalCenter(cview))
	cview:addChild(bg)
	-- 添加标题
	local quitButton = display.newButton(1100,624, {
		n = _res('update/notice_btn_quit') , enable = true , 
		cb = function()
			self:runAction(cc.RemoveSelf:create())
		end
	})
	cview:addChild(quitButton,2)
	local csize = bg:getContentSize()
	local titleImage = display.newImageView(_res('update/notice_title_bg'),csize.width * 0.5,616)
	cview:addChild(titleImage, 3)
	local loadingTipsLabel = display.newLabel(csize.width * 0.5, 615, fontWithColor(14,
	                                                                                {text = self.title , reqW = 150 ,hAlign =display.TAC ,
	                                                                                 fontSize = 28, color = 'ffdf89', hAlign = display.TAC,outline = '5d3c25', outlineSize = 1 }))
	cview:addChild(loadingTipsLabel)
	if device.platform == 'ios' or device.platform == 'android' then
		local  webViewSize = cc.size(1014, 500)
		local _webView = ccexp.WebView:create()
		_webView:setAnchorPoint(cc.p(0.5, 1))
		_webView:setPosition(csize.width * 0.5, csize.height - 78)
		_webView:setContentSize(webViewSize)
		_webView:setTag(2345)
		_webView:setScalesPageToFit(true)
		cview:addChild(_webView,2)
		_webView:loadURL(self.url)
	end
end

function PrivacyWebView:ctor( param)
	self.url = param.url
	self.title = param.title or "WebView Content"
	self:InitUI()
	app:DispatchObservers(SGL.PRIVACY_POLICY_WEBVIW_SHOW_EVENT  , {isVisible = false})
end

function PrivacyWebView:onCleanup()
	app:DispatchObservers(SGL.PRIVACY_POLICY_WEBVIW_SHOW_EVENT  , {isVisible = true})
end
return PrivacyWebView
