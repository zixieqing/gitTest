--[[
分享活动view
--]]
---@class ActivityShareCommonView
local ActivityShareCommonView = class('ActivityShareCommonView', function()
	local node = CLayout:create(display.size)
	node:setAnchorPoint(cc.p(0, 0))
	node.name = 'common.ActivityShareCommonView'
	node:enableNodeEvents()
	return node
end)
--[[
　　{
		---@params  bgPath   string  背景图片路径
		---@params  qrCodePath   string  二维码图片
		---@params  namePath  string 背景图片卡牌名字图片
		---@params  shared  number 是否显示分享奖励
		---@params  shareRewards  table 奖励内容
		---@sglNameEvent string 成功后的回调
		---@title string 分享标题
		---@text string 分享文本
		---@myurl string url地址（可选，默认是nil，官网）
	}
]]
function ActivityShareCommonView:ctor(...)
	self.args         = unpack({ ... })
	self.shareRewards = checktable(self.args.shareRewards[1])
	self.title = self.args.title
	self.text = self.args.text
	self.myurl = self.args.myurl
	self:InitUI()
	self:RegisterSignal()
end
--[[
init ui
--]]
function ActivityShareCommonView:InitUI()
	local function CreateView()
		local view   = display.newLayer(0, 0, { size = display.size, ap = cc.p(0.5, 0.5) })
		local bgPath = self.args.bgPath
		local cg     = display.newImageView(bgPath, display.cx, display.cy)
		view:addChild(cg, 1)
		local namePath = self.args.namePath
		if namePath and  (string.len(namePath) > 0 ) then
			local nameCg   = display.newImageView(namePath, display.cx, display.cy)
			view:addChild(nameCg, 1)
		end

		local backBtn = display.newButton(30 + display.SAFE_L, display.height - 18, { n = _res('ui/common/common_btn_back.png'), ap = cc.p(0, 1) })
		view:addChild(backBtn, 10)
		-- 分享按钮
		local shareLayout = CLayout:create(cc.size(250, 180))
		shareLayout:setPosition(cc.p(display.width - display.SAFE_L - 180, 0))
		shareLayout:setAnchorPoint(cc.p(0.5, 0))
		view:addChild(shareLayout, 5)
		local shareBg = display.newImageView(_res('ui/home/activity/cvShare/share_bg_button.png'), 125, 90)
		shareLayout:addChild(shareBg, 1)
		local shareTipsLabel = display.newLabel(shareLayout:getContentSize().width / 2, 134, fontWithColor(18, { text = __('（分享后聆听飨灵专属故事）') }))
		shareLayout:addChild(shareTipsLabel, 10)
		local shareBtn = display.newButton(shareLayout:getContentSize().width / 2, 92, { n = _res('ui/common/common_btn_blue_default.png') })
		shareLayout:addChild(shareBtn, 10)
		display.commonLabelParams(shareBtn, fontWithColor(14, { text = __('分享') }))
		local rewardLabel = display.newRichLabel(shareLayout:getContentSize().width / 2, 50, { r = true, c = {
			{ text = string.fmt(__('奖励_num_'), { ['_num_'] = tostring(self.shareRewards.num) }), color = '#ffffff', fontSize = 22 },
			{ img = CommonUtils.GetGoodsIconPathById(self.shareRewards.goodsId), scale = 0.2 }
		} })
		shareLayout:addChild(rewardLabel, 10)
		-- 分享图片
		local cgSize        = cg:getContentSize()
		local shareCVLayout = display.newLayer(display.cx, display.cy, { ap = display.CENTER ,  size = cgSize })
		view:addChild(shareCVLayout, -1)
		shareCVLayout:setVisible(false)
		-- 背景图片
		local bgPathImage = display.newImageView(bgPath, cgSize.width / 2, cgSize.height / 2)
		shareCVLayout:addChild(bgPathImage)
		-- 名字
		if namePath and  (string.len(namePath) > 0 ) then
			local namePathImage = display.newImageView(namePath, cgSize.width / 2, cgSize.height / 2 )
			shareCVLayout:addChild(namePathImage)
		end
		local qrCodePath      = self.args.qrCodePath
		if qrCodePath and (string.len(qrCodePath) > 0 ) then
			local qrCodePathImage = display.newImageView(qrCodePath, cgSize.width -20 , 20 , { ap = display.RIGHT_BOTTOM })
			qrCodePathImage:setAnchorPoint(display.RIGHT_BOTTOM)
			shareCVLayout:addChild(qrCodePathImage)
		end
		local logoImage = display.newImageView(_res('share/share_ico_logo'), 20, cgSize.height-20 , { ap = display.LEFT_TOP })
		shareCVLayout:addChild(logoImage)
		return {
			view          = view,
			backBtn       = backBtn,
			shareLayout   = shareLayout,
			shareBtn      = shareBtn,
			shareCVLayout = shareCVLayout,
			rewardLabel   = rewardLabel
		}
	end
	-- eaterLayer
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(cc.p(display.cx, display.cy))
	self:addChild(eaterLayer, -1)
	xTry(function()
		self.viewData_ = CreateView()
		self:addChild(self.viewData_.view)
		self.viewData_.view:setPosition(display.center)
		if checkint(self.args.shared) == 1 then
			self.viewData_.rewardLabel:setVisible(false)
		end
		self.viewData_.backBtn:setOnClickScriptHandler(function(sender)
			PlayAudioByClickClose()
			self:runAction(cc.RemoveSelf:create())
		end)
		self.viewData_.shareBtn:setOnClickScriptHandler(function(sender)
			PlayAudioByClickNormal()
			--     -- 添加分享通用框架
			self.viewData_.shareCVLayout:setVisible(true)
			local node = require('common.ShareNode').new({
				visitNode = self.viewData_.shareCVLayout,
				name = "cv_share.jpg"  ,
				descr = self.text ,
				title = self.title,
				myurl = self.myurl,
			})
			node:setName('ShareNode')
			display.commonUIParams(node, { po = utils.getLocalCenter(self) })
			self:addChild(node, 999)
		end)
		self:EnterAction()
	end, __G__TRACKBACK__)
end
function ActivityShareCommonView:EnterAction()
	local viewData_ = self.viewData_
	viewData_.view:setOpacity(0)
	viewData_.view:runAction(
			cc.FadeIn:create(0.3)
	)
end
--[[
隐藏分享界面
--]]
function ActivityShareCommonView:HideShareView()
	-- 显示一些全局ui
	AppFacade.GetInstance():DispatchObservers('RAID_SHOW_CHAT_PANEL', { show = true })
	-- 移除分享界面
	if nil ~= self:getChildByName('ShareNode') then
		self:getChildByName('ShareNode'):setVisible(false)
		self:getChildByName('ShareNode'):runAction(cc.RemoveSelf:create())
	end
end
--[[
注册信号
--]]
function ActivityShareCommonView:RegisterSignal()
	------------ 分享返回按钮 ------------
	AppFacade.GetInstance():RegistObserver('SHARE_BUTTON_BACK_EVENT', mvc.Observer.new(function(_, signal)
		self:HideShareView()
	end, self))
	if self.args.sglNameEvent then
		AppFacade.GetInstance():RegistObserver(self.args.sglNameEvent, mvc.Observer.new(function(_, signal)
			self.viewData_.rewardLabel:setVisible(false)
		end, self))
	end
	------------ 分享返回按钮 ------------

end
--[[
销毁信号
--]]
function ActivityShareCommonView:UnRegistSignal()
	AppFacade.GetInstance():UnRegistObserver('SHARE_BUTTON_BACK_EVENT', self)
	if self.args.sglNameEvent then
		AppFacade.GetInstance():UnRegistObserver( self.args.sglNameEvent, self)
	end
end
function ActivityShareCommonView:onCleanup()
	-- 注销信号
	self:UnRegistSignal()
end
return ActivityShareCommonView
