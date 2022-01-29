--[[
包厢菜单mediator    
--]]
local Mediator = mvc.Mediator
local PrivateRoomMenuMediator = class("PrivateRoomMenuMediator", Mediator)
local NAME = "privateRoom.PrivateRoomMenuMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local PrivateRoomMenuCell = require('Game.views.privateRoom.PrivateRoomMenuCell')
function PrivateRoomMenuMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	self.privateRoomData = checktable(params)
	self.foodsData = {}
	for k, v in pairs(checktable(self.privateRoomData.foods)) do
		local temp = {}
		temp.goodsId = checkint(k)
		temp.num = checkint(v)
		table.insert(self.foodsData, temp)
	end
	self.gold = checkint(self.privateRoomData.gold)
	self.popularity = checkint(self.privateRoomData.popularity)
	self.rewards = checktable(self.privateRoomData.rewards)
	self.diamondCost = 0
	self.foodConsume = {}
end


function PrivateRoomMenuMediator:InterestSignals()
	local signals = {
		POST.PRIVATE_ROOM_GUEST_SERVE.sglName,
		POST.PRIVATE_ROOM_GUEST_CANCEL.sglName,
		SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
	}
	return signals
end

function PrivateRoomMenuMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	local data = checktable(signal:GetBody())
	if name == POST.PRIVATE_ROOM_GUEST_SERVE.sglName then -- 招待
		if self.diamondCost > 0 then
			table.insert(self.foodConsume, {goodsId = DIAMOND_ID, num = -self.diamondCost})
		end
		CommonUtils.DrawRewards(self.foodConsume)
		AppFacade.GetInstance():DispatchObservers(PRIVATEROOM_SERVE_EVENT, data)
		self:BackAction()
	elseif name == POST.PRIVATE_ROOM_GUEST_CANCEL.sglName then -- 取消
		AppFacade.GetInstance():DispatchObservers(PRIVATEROOM_SERVE_CANCEL)
		self:BackAction()
	elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then -- 刷新
		local viewData = self:GetViewComponent().viewData
		viewData.gridView:setCountOfCell(table.nums(self.foodsData))
		viewData.gridView:reloadData()
	end
end

function PrivateRoomMenuMediator:Initial( key )
	self.super.Initial(self, key)
	-- 创建CarnieCapsulePoolView
	local viewComponent = require( 'Game.views.privateRoom.PrivateRoomMenuView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(viewComponent)
    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.BackAction))
    viewComponent.viewData.abandonBtn:setOnClickScriptHandler(handler(self, self.AbandonBtnCallback))
    viewComponent.viewData.serveBtn:setOnClickScriptHandler(handler(self, self.ServeBtnCallback))
    viewComponent.viewData.popularityBtn:setOnClickScriptHandler(handler(self, self.PopularityBtnCallback))
    viewComponent.viewData.goldBtn:setOnClickScriptHandler(handler(self, self.GoldBtnCallback))
	viewComponent.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.GridViewDataSource))
    self:InitView()
end
--[[
初始化页面
--]]
function PrivateRoomMenuMediator:InitView()
	local guestConf = CommonUtils.GetConfig('privateRoom', 'guest', self.privateRoomData.guestId)
    local viewData = self:GetViewComponent().viewData
	viewData.gridView:setCountOfCell(table.nums(self.foodsData))
	viewData.gridView:reloadData()
	-- 知名度
	local popAddition = app.privateRoomMgr:GetBuffAddition(2)
	local popAddNum = popAddition.souvenir.add + popAddition.theme.add + math.ceil(self.popularity * (popAddition.souvenir.pct + popAddition.theme.pct))
	local popAddStr = ''
	if popAddNum > 0 then
		popAddStr = '+' .. tostring(popAddNum)
	end
	viewData.popularityNum:setString(tostring(self.popularity) .. popAddStr)
	-- 金币
	local goldAddition = app.privateRoomMgr:GetBuffAddition(1)
	local goldAddNum = goldAddition.souvenir.add + goldAddition.theme.add + math.ceil(self.gold * (goldAddition.souvenir.pct + goldAddition.theme.pct))
	local goldAddStr = ''
	if goldAddNum > 0 then
		goldAddStr = '+' .. tostring(goldAddNum)
	end
	viewData.goldNum:setString(tostring(self.gold) .. goldAddStr)
	-- 订单名称
	viewData.nameLabel:setString(string.fmt(__('_name_的订单'), {['_name_'] = guestConf.name}))
	-- 奖励列表
	local rewardLayoutSize = cc.size(90 + (#self.rewards - 1) * 100, 100)
	local rewardLayout = CLayout:create(rewardLayoutSize)
	rewardLayout:setPosition(cc.p(viewData.size.width / 2, 180))
	viewData.view:addChild(rewardLayout, 10) 
	local buffAddition = app.privateRoomMgr:GetBuffAddition(3)
	local additionNum = buffAddition.souvenir.add + buffAddition.theme.add
	for i, v in ipairs(self.rewards) do
		local goodsNode = require('common.GoodNode').new({
			id = checkint(v.goodsId),
			amount = checkint(v.num),
			showAmount = true,
			additionNum = additionNum,
			callBack = function (sender)
				uiMgr:ShowInformationTipsBoard({
					targetNode = sender, iconId = checkint(v.goodsId), type = 1, privateRoomBuff = buffAddition, 
				})
			end
		})
		goodsNode:setPosition(45 + (i - 1) * 100, rewardLayoutSize.height / 2)
		goodsNode:setScale(0.8)
		rewardLayout:addChild(goodsNode) 
	end
end
--[[
菜单列表处理
--]]
function PrivateRoomMenuMediator:GridViewDataSource( p_convertview, idx ) 
	local pCell = p_convertview
    local index = idx + 1
	local cSize = self:GetViewComponent().viewData.gridViewCellSize

    if pCell == nil then
		pCell = PrivateRoomMenuCell.new(cSize)
		pCell.goodsNode:RefreshSelf({callBack = handler(self, self.MenuCellCallback)})
    end
	xTry(function()	
		local data = self.foodsData[index]
		pCell.goodsNode:RefreshSelf({goodsId = data.goodsId, showAmount = false})
		local targetNum = data.num
		local hasNum = app.gameMgr:GetAmountByGoodId(data.goodsId)
		local labelColor = '#5c5c5c'
		if hasNum < targetNum then
			labelColor = '##d23d3d'
		end
		display.reloadRichLabel(pCell.richLabel, {r = true, c = {
			{text = hasNum, color = labelColor, fontSize = 22},
			{text = '/', color = '#5c5c5c', fontSize = 22},
			{text = targetNum, color = '#5c5c5c', fontSize = 22}
		}})
		pCell.goodsNode:setTag(index)
	end,__G__TRACKBACK__)
	return pCell
end
--[[
菜单cell点击回调
--]]
function PrivateRoomMenuMediator:MenuCellCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local data = self.foodsData[tag]
	uiMgr:AddDialog("common.GainPopup", {goodId = data.goodsId})
end
--[[
放弃按钮点击回调
--]]
function PrivateRoomMenuMediator:AbandonBtnCallback( sender )
	PlayAudioByClickNormal()
    local scene = uiMgr:GetCurrentScene()
    local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('是否要放弃该订单？'), isOnlyOK = false, callback = function ()
		self:SendSignal(POST.PRIVATE_ROOM_GUEST_CANCEL.cmdName)
    end})
    CommonTip:setPosition(display.center)
    scene:AddDialog(CommonTip)
end
--[[
上菜按钮点击回调
--]]
function PrivateRoomMenuMediator:ServeBtnCallback( sender )
	PlayAudioByClickNormal()
	local isEnough = true -- 道具是否满足
	self.diamondCost = 0  -- 补足所需钻石
	self.foodConsume = {} -- 消耗的菜品
	for i, v in ipairs(self.foodsData) do
		local goodsNum = app.gameMgr:GetAmountByGoodId(v.goodsId)
		if goodsNum < checkint(v.num) then
			isEnough = false
			local goodsConf = CommonUtils.GetConfig('goods', 'goods', v.goodsId)
			self.diamondCost = self.diamondCost + (checkint(goodsConf.diamondValue) * (checkint(v.num) - goodsNum))
			table.insert(self.foodConsume, {goodsId = v.goodsId, num = -goodsNum})
		else
			table.insert(self.foodConsume, {goodsId = v.goodsId, num = -v.num})
		end
	end
	if isEnough then
		self:SendSignal(POST.PRIVATE_ROOM_GUEST_SERVE.cmdName)
	else
    	-- 显示购买弹窗
    	local descrRich = {
    	    {text = __('此项操作将会扣除您')},
    	    {text = tostring(self.diamondCost), fontSize = fontWithColor('15').fontSize, color = '#ff0000'},
    	    {text = __('幻晶石!')},
    	}
    	local costInfo = {goodsId = DIAMOND_ID, num = self.diamondCost}
    	local commonTip = require('common.CommonTip').new({
    	    textRich = {
    	        {text = __('道具不足，是否花费幻晶石补足?')}
    	    },
    	    descrRich = descrRich,
    	    defaultRichPattern = true,
    	    costInfo = costInfo,
    	    callback = function ()
				if gameMgr:GetAmountByGoodId(DIAMOND_ID) >= self.diamondCost then
					self:SendSignal(POST.PRIVATE_ROOM_GUEST_SERVE.cmdName)
				else
					if GAME_MODULE_OPEN.NEW_STORE then
						app.uiMgr:showDiamonTips()
					else
						uiMgr:ShowInformationTips(__('幻晶石不足'))
					end
				end
    	    end
    	})
    	commonTip:setPosition(display.center)
    	local scene = uiMgr:GetCurrentScene()
		scene:AddDialog(commonTip, 10)
	end
end
--[[
知名度按钮点击回调
--]]
function PrivateRoomMenuMediator:PopularityBtnCallback( sender )
	PlayAudioByClickClose()
	local addition = app.privateRoomMgr:GetBuffAddition(2)
	uiMgr:ShowInformationTipsBoard({
		targetNode = sender, type = 15, privateRoomBuff = addition, iconId = POPULARITY_ID, originNum = self.popularity
	})
end
--[[
金币按钮点击回调
--]]
function PrivateRoomMenuMediator:GoldBtnCallback( sender )
	PlayAudioByClickClose()
	local addition = app.privateRoomMgr:GetBuffAddition(1)
	uiMgr:ShowInformationTipsBoard({
		targetNode = sender, type = 15, privateRoomBuff = addition, iconId = GOLD_ID, originNum = self.gold
	})
end
function PrivateRoomMenuMediator:BackAction()
	PlayAudioByClickClose()
	AppFacade.GetInstance():UnRegsitMediator("privateRoom.PrivateRoomMenuMediator")
end
function PrivateRoomMenuMediator:EnterAction()
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
function PrivateRoomMenuMediator:OnRegist(  )
	regPost(POST.PRIVATE_ROOM_GUEST_SERVE)
	regPost(POST.PRIVATE_ROOM_GUEST_CANCEL)
	self:EnterAction()
end

function PrivateRoomMenuMediator:OnUnRegist(  )
	unregPost(POST.PRIVATE_ROOM_GUEST_SERVE)
	unregPost(POST.PRIVATE_ROOM_GUEST_CANCEL)
	-- 移除界面
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end
return PrivateRoomMenuMediator