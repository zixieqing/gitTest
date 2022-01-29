--[[
包厢主题mediator    
--]]
local Mediator = mvc.Mediator
local PrivateRoomThemeMediator = class("PrivateRoomThemeMediator", Mediator)
local NAME = "privateRoom.PrivateRoomThemeMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local PrivateRoomThemeCell = require('Game.views.privateRoom.PrivateRoomThemeCell')
function PrivateRoomThemeMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	self.themeData = {} -- 商店主题数据
	self.selectedTheme = 1 -- 选中的主题
end


function PrivateRoomThemeMediator:InterestSignals()
	local signals = {
		POST.PRIVATE_ROOM_THEME.sglName,
		POST.PRIVATE_ROOM_THEME_BUY.sglName,
		POST.PRIVATE_ROOM_THEME_SWITCH.sglName,
	}
	return signals
end

function PrivateRoomThemeMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	local data = checktable(signal:GetBody())
	if name == POST.PRIVATE_ROOM_THEME.sglName then -- 主题列表
		self.themeData = checktable(data.products)
		self:InitView()
	elseif name == POST.PRIVATE_ROOM_THEME_BUY.sglName then -- 主题购买
		self:BuyTheme(data)
	elseif name == POST.PRIVATE_ROOM_THEME_SWITCH.sglName then -- 主题切换
		app.privateRoomMgr:SetThemeId(checkint(data.requestData.themeId))
		uiMgr:ShowInformationTips(__('切换成功'))
		AppFacade.GetInstance():DispatchObservers(PRIVATEROOM_SWITCH_THEME)
		self:BackAction()
	end
end

function PrivateRoomThemeMediator:Initial( key )
	self.super.Initial(self, key)
	-- 创建CarnieCapsulePoolView
	local viewComponent = require( 'Game.views.privateRoom.PrivateRoomThemeView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = uiMgr:GetCurrentScene()
	scene:AddGameLayer(viewComponent)
	
	viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.BackAction))
	viewComponent.viewData.previewBtn:setOnClickScriptHandler(handler(self, self.PreviewBtnCallback))
	viewComponent.viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.PurchaseBtnCallback))
	viewComponent.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.GridViewDataSource))
end
--[[
初始化页面
--]]
function PrivateRoomThemeMediator:InitView()
	local viewData = self:GetViewComponent().viewData
	viewData.gridView:setCountOfCell(#self.themeData)
	viewData.gridView:reloadData()
	self:ThemeListCellCallback(self.selectedTheme)
end
--[[
预览按钮点击回调
--]]
function PrivateRoomThemeMediator:PreviewBtnCallback( sender )
	PlayAudioByClickNormal()
	local data = self.themeData[self.selectedTheme]
	local themeId = data.themeId 
	local wallData = app.privateRoomMgr:GetWallData()
	uiMgr:AddDialog("Game.views.privateRoom.PrivateRoomThemePreviewView", {themeId = themeId, wallData = wallData})
end
--[[
购买按钮点击回调
--]]
function PrivateRoomThemeMediator:PurchaseBtnCallback( sender )
	PlayAudioByClickNormal()
	local data = self.themeData[self.selectedTheme]
	local initThemeId = CommonUtils.GetConfig('privateRoom', 'avatarThemeInit', 1).themeId -- 默认主题
	if gameMgr:GetAmountByGoodId(data.themeId) > 0 or checkint(data.themeId) == checkint(initThemeId) then
		-- 使用
		self:SendSignal(POST.PRIVATE_ROOM_THEME_SWITCH.cmdName, {themeId = checkint(data.themeId)})
	else
		-- 购买
		local price = checkint(data.price) * checkint(data.discount)
		if app.gameMgr:GetAmountByIdForce(data.currency) >= price then
			-- 道具足够
			self:SendSignal(POST.PRIVATE_ROOM_THEME_BUY.cmdName, {productId = checkint(data.productId)})
		else
			-- 道具不足
			local config = CommonUtils.GetConfig('goods', 'goods', data.currency) or {}
			app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {['_name_'] = tostring(config.name)}))
		end
		
	end
end
--[[
主题列表处理
--]]
function PrivateRoomThemeMediator:GridViewDataSource( p_convertview, idx ) 
	local pCell = p_convertview
    local index = idx + 1
	local cSize = self:GetViewComponent().viewData.listCellSize

    if pCell == nil then
		pCell = PrivateRoomThemeCell.new(cSize)
		pCell.themeBg:setOnClickScriptHandler(handler(self, self.ThemeListCellCallback))
    end
	xTry(function()	
		local data = self.themeData[index]
		local themeConf = CommonUtils.GetConfig('privateRoom', 'avatarTheme', data.themeId)
		pCell.themeImg:setTexture(_res(string.format('avatar/privateRoom/vip_theme_pic_%d_s.jpg', checkint(data.themeId))))
		pCell.titleLabel:setString(themeConf.name)
		-- 折扣
		local discount = (themeConf.discount * 100) or 80
		if data.discount then
			discount = data.discount * 100
		end
		pCell.discountBg:setVisible(discount ~= 100)
		display.commonLabelParams(pCell.discountLabel, {text = string.fmt(__('_num_折'),{_num_ = discount / 10})})
		-- 是否拥有
		if gameMgr:GetAmountByGoodId(data.themeId) > 0 then
			pCell.ownBg:setVisible(true)
		else
			pCell.ownBg:setVisible(false)
		end
		pCell.themeFrame:setVisible(self.selectedTheme == index)
		pCell.lockBg:setVisible(false)
		pCell.lockTitle:setVisible(false)
		pCell.themeBg:setTag(index)
	end,__G__TRACKBACK__)
	return pCell
end
--[[
主题列表点击回调
--]]
function PrivateRoomThemeMediator:ThemeListCellCallback( sender )
	local tag = 0
	local viewData = self:GetViewComponent().viewData
	local gridView = viewData.gridView
	if type(sender) == 'number' then
		tag = sender
	else
		tag = sender:getTag()
		if self.selectedTheme == tag then
			gridView:cellAtIndex(tag - 1).themeFrame:setVisible(true)
			return
		else
			-- 添加点击音效
			PlayAudioByClickNormal()
		end
	end
	if gridView:cellAtIndex(self.selectedTheme - 1) then
		gridView:cellAtIndex(self.selectedTheme - 1).themeFrame:setVisible(false)
	end
	gridView:cellAtIndex(tag - 1).themeFrame:setVisible(true)
	self.selectedTheme = tag
	self:RefreshDetailsLayout()
end
--[[
刷新主题详情
--]]
function PrivateRoomThemeMediator:RefreshDetailsLayout()
	local data = self.themeData[self.selectedTheme]
	if not data or next(data) == nil then return end
	self:GetViewComponent():RefreshDetailsLayout(data)
end
--[[
购买主题
--]]
function PrivateRoomThemeMediator:BuyTheme( rewardsData )
	local data = {}
	-- 刷新本地数据
	for i, v in ipairs(self.themeData) do
		if checkint(v.productId) == checkint(rewardsData.requestData.productId) then
			data = v
			break
		end
	end
	local price = checkint(data.price * data.discount)
	table.insert(rewardsData.rewards, {goodsId = checkint(data.currency), num = -price})
	CommonUtils.DrawRewards(rewardsData.rewards)
	-- 刷新页面
	local viewComponent = self:GetViewComponent()
	viewComponent:RefreshGridView()
	self:RefreshDetailsLayout()
	uiMgr:ShowInformationTips(__('购买成功'))
end
function PrivateRoomThemeMediator:BackAction()
	PlayAudioByClickClose()
	AppFacade.GetInstance():UnRegsitMediator("privateRoom.PrivateRoomThemeMediator")
end
function PrivateRoomThemeMediator:EnterAction()
	local viewComponent = self:GetViewComponent()
	viewComponent.viewData.view:setScale(0.8)
	viewComponent.viewData.view:runAction(
		cc.Sequence:create(
			cc.EaseBackOut:create(
				cc.ScaleTo:create(0.3, 1)
			)
		)
	)
end
function PrivateRoomThemeMediator:EnterLayer(  )
	self:EnterAction()
	self:SendSignal(POST.PRIVATE_ROOM_THEME.cmdName)
end
function PrivateRoomThemeMediator:OnRegist(  )
	regPost(POST.PRIVATE_ROOM_THEME)
	regPost(POST.PRIVATE_ROOM_THEME_BUY)
	regPost(POST.PRIVATE_ROOM_THEME_SWITCH)
	
	self:EnterLayer()
end

function PrivateRoomThemeMediator:OnUnRegist(  )
	regPost(POST.PRIVATE_ROOM_THEME)
	regPost(POST.PRIVATE_ROOM_THEME_BUY)
	regPost(POST.PRIVATE_ROOM_THEME_SWITCH)
	-- 移除界面
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self:GetViewComponent())
end
return PrivateRoomThemeMediator