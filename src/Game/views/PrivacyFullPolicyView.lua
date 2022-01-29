--[[
隐私协议页面
--]]
local PrivacyFullPolicyView = class('PrivacyFullPolicyView', function ()
	local node = CLayout:create(display.size)
	node.name = 'home.PrivacyFullPolicyView'
	node:enableNodeEvents()
	return node
end)
function PrivacyFullPolicyView:ctor(param)
	self.isScroll = param.isScroll
	self:InitUI()
end

function PrivacyFullPolicyView:InitUI()
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
	self.csize = bg:getContentSize()
	local titleImage = display.newImageView(_res('update/notice_title_bg'),self.csize.width * 0.5,616)
	cview:addChild(titleImage, 3)
	local loadingTipsLabel = display.newLabel(self.csize.width * 0.5, 615, fontWithColor(14,
	                                                                                {text ="Full Privacy Policy", reqW = 150 ,hAlign =display.TAC ,
	                                                                                 fontSize = 28, color = 'ffdf89', hAlign = display.TAC,outline = '5d3c25', outlineSize = 1 }))
	cview:addChild(loadingTipsLabel)
	self.cview = cview
	self:CreateListView()
end
function PrivacyFullPolicyView:CreateListView()
	local listView = CListView:create(cc.size(1014, 500))
	listView:setBounceable(false)
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setPosition(self.csize.width * 0.5,self.csize.height - 78)
	listView:setAnchorPoint(cc.p(0.5, 1))
	self.cview:addChild(listView)
	local prvacyFullSize = cc.size(1014 ,5370 )
	local prvacyFullPolicyLayer = display.newLayer(0,0,{size = prvacyFullSize})
	local height = -25
	for i = 1, 5 do
		local privacyPlolicyImage = display.newImageView(_res(string.format("update/privacyFullPolicy%d.jpg", i)))
		privacyPlolicyImage:setAnchorPoint(display.CENTER_TOP)
		privacyPlolicyImage:setPosition(prvacyFullSize.width/2 ,prvacyFullSize.height -  height )
		height = privacyPlolicyImage:getContentSize().height +  height
		prvacyFullPolicyLayer:addChild(privacyPlolicyImage)
	end

	local width = 27
	local btnTable = {
		[1] = {
			size = cc.size(425,25),
			pos =cc.p(prvacyFullSize.width/2 -150, prvacyFullSize.height - 200),
			url = "http://www.esrb.org/privacy/faq.aspx#10"
		},
		[2] = {
			size = cc.size(115,25),
			pos =cc.p(prvacyFullSize.width/2 -194, prvacyFullSize.height - 265),
			url = "http://cdn-cr-gp.eleximg.com/policy/service.html"
		},
		[3] = {
			size = cc.size(210,25),
			pos =cc.p(prvacyFullSize.width/2-476 , prvacyFullSize.height -1608),
			url = "https://www.adjust.com/terms/privacy-policy/"
		},
		[4] = {
			size = cc.size(210,25),
			pos =cc.p(prvacyFullSize.width/2-476 , prvacyFullSize.height -1608 - width),
			url = "https://aihelp.net/privacypolicy/"
		},
		[5] = {
			size = cc.size(210,25),
			pos =cc.p(prvacyFullSize.width/2-476 , prvacyFullSize.height -1608 - width*2),
			url = "https://bugly.qq.com/v2/contract"
		},
		[6] = {
			size = cc.size(210,25),
			pos =cc.p(prvacyFullSize.width/2-476 , prvacyFullSize.height -1608 - width*3),
			url = "https://aihelp.net/privacypolicy/"
		},
		[7] = {
			size = cc.size(210,25),
			pos =cc.p(prvacyFullSize.width/2-476 , prvacyFullSize.height -1608 - width*4),
			url = "https://www.facebook.com/privacy/explanation"
		},
		[8] = {
			size = cc.size(210,25),
			pos =cc.p(prvacyFullSize.width/2-476 , prvacyFullSize.height -1608 - width*5),
			url = "https://firebase.google.com/support/privacy"
		},
		[9] = {
			size = cc.size(210,25),
			pos =cc.p(prvacyFullSize.width/2-476 , prvacyFullSize.height -1608 - width*6),
			url = "https://developers.google.com/terms/api-services-user-data-policy"
		},
		
		[10] = {
			size = cc.size(210,25),
			pos =cc.p(prvacyFullSize.width/2-476 , prvacyFullSize.height -1608 - width*7),
			url = "https://developers.google.com/games/services/terms"
		},
		[11] = {
			size = cc.size(210,25),
			pos =cc.p(prvacyFullSize.width/2-476 , prvacyFullSize.height -1608 - width*8),
			url = "http://www.talkingdata.com/privacy.jsp?languagetype=zh_en"
		},
		[12] = {
			size = cc.size(210,25),
			pos =cc.p(prvacyFullSize.width/2-476 , prvacyFullSize.height -1608 - width*9),
			url = "https://policies.google.com/privacy"
		},
		[13] = {
			size = cc.size(310,25),
			pos =cc.p(420 , 0),
			url = "https://www.adaptant.io/contacts-locations/"
		}
	}
	for i = 1 , #btnTable do
		local layer = display.newLayer(btnTable[i].pos.x, btnTable[i].pos.y , {enable = display.LEFT_BOTTOM, enable = true ,color =cc.c4b(0,0,0,0) , size = btnTable[i].size , cb  = function(sener)
			local privacyFullLayer = require("Game.views.PrivacyWebView").new({size = webViewSize ,isWebView = true ,  url = btnTable[i].url })
			privacyFullLayer:setPosition(display.center)
			app.uiMgr:GetCurrentScene():AddDialog(privacyFullLayer)
		end })
		layer:setTag(i)
		prvacyFullPolicyLayer:addChild(layer)
	end
	listView:insertNodeAtLast(prvacyFullPolicyLayer)

	listView:reloadData()
	if self.isScroll  then
		listView:setContentOffset(cc.p(0, -500))
	end
end

return PrivacyFullPolicyView
