--[[
 * author : xingweihao
 * descpt : 联动商店
--]]
local Mediator = mvc.Mediator
---@class PopShopMediator:Mediator
local PopShopMediator = class("PopShopMediator", Mediator)
---@type UnionShopGoodsCell
local UnionShopGoodsCell = require('home.UnionShopGoodsCell')
local NAME = "PopShopMediator"
function PopShopMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	local args = checktable(params)
	dump(args)
	self.summaryId = args.summaryId
	self.activityId = args.activityId
	self.gridViewData = nil
end

function PopShopMediator:InterestSignals()
	local signals = {
		POST.POP_FARM_MALL.sglName,
		POST.POP_FARM_MALL_BUY.sglName
	}
	return signals
end

function PopShopMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = signal:GetBody()

	if name == POST.POP_FARM_MALL.sglName then
		local products = body.products
		self.gridViewData = products
		---@type PopShopView
		local viewComponent = self:GetViewComponent()
		local viewData_ = viewComponent.viewData_
		viewData_.gridView:setCountOfCell(#self.gridViewData)
		viewData_.gridView:reloadData()
	elseif name == POST.POP_FARM_MALL_BUY.sglName then
		local requestData = body.requestData
		local index = requestData.index
		local productNum = requestData.productNum
		local data = self.gridViewData[index]
		data.leftPurchasedNum = data.leftPurchasedNum - productNum
		local counsumeNum = data.price * productNum
		-- 联动本的道具扣除应该是负数
		CommonUtils.DrawRewards({{
			goodsId = data.currency , num = -counsumeNum }})
		local goodsId = data.goodsId
		local num = productNum
		app:DispatchObservers("POP_BUY_SEED_SUCCESS_EVENT" , {
			goodsId = goodsId ,
			num = num
		})
		app.uiMgr:ShowInformationTips(__('购买种子成功'))
		app.uiMgr:GetCurrentScene():RemoveDialogByTag(5001)
		---@type PopShopView
		local viewComponent = self:GetViewComponent()
		local viewData_ = viewComponent.viewData_
		viewData_.gridView:reloadData()
	end
end
-------------------------------------------------
------------------ inheritance ------------------
function PopShopMediator:Initial( key )
	self.super.Initial(self,key)
	local viewComponent  = require("Game.views.link.popMain.PopShopView").new()
	self:SetViewComponent(viewComponent)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	viewComponent:setPosition(display.center)
	viewComponent.viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self,self.GoodsListDataSource))
	display.commonUIParams(viewComponent.eaterLayer , { enable = true ,  cb = function()
		self:GetFacade():UnRegsitMediator(NAME)
	end})
end

--[[
列表处理
--]]
function PopShopMediator:GoodsListDataSource( p_convertview, idx )
	---@type UnionShopGoodsCell
	local pCell = p_convertview
	local index = idx + 1
	local data = self.gridViewData[index]
	if pCell == nil then
		local cSize = self:GetViewComponent().viewData_.listCellSize
		pCell = UnionShopGoodsCell.new(cSize)
		pCell.sellOut:setVisible(false)
		pCell.goodsIcon.icon:removeAllChildren()
		local seedImage = display.newImageView(_res('ui/link/popMain/goods_icon_seeds_1.png') ,0 ,0  )
		pCell.goodsIcon.icon:addChild(seedImage, 10)
		pCell.seedImage = seedImage
		pCell.bgBtn:setOnClickScriptHandler(handler(self, self.CommodityCallback))
	end
	pCell.bgBtn:setTag(index)
	pCell.sellOut:setVisible(false)
	pCell.goodsIcon.showAmount = false
	pCell.lockMask:setVisible(false)
	pCell.stockLabel:setString("")
	xTry(function()
		if checkint(data.stock) ~= -1 then
			if checkint(data.leftPurchasedNum) > 0 then
				display.commonLabelParams(pCell.stockLabel , {text =string.fmt(__('库存:_num_') ,{_num_ = data.leftPurchasedNum} ) })
			else
				pCell.sellOut:setVisible(true)
				pCell.lockMask:setVisible(true)
			end
		end
		local summaryId = self.summaryId
		local farmSeedConf = CONF.ACTIVITY_POP.FARM_SEED:GetValue(summaryId)
		display.commonLabelParams(pCell.goodsName , { text = farmSeedConf[tostring(data.goodsId)].name})
		display.reloadRichLabel(pCell.priceLabel , { c= {
			fontWithColor(14 , {color ="ffffff" ,text = data.price }),
			{img = CommonUtils.GetGoodsIconPathById(data.currency) , scale = 0.25}
		}})
		if pCell.seedImage then
			pCell.seedImage:setTexture(_res(string.format('ui/link/popMain/goods_icon_seeds_%d.png', checkint(data.goodsId))))
		end
		CommonUtils.AddRichLabelTraceEffect(pCell.priceLabel)
	end,__G__TRACKBACK__)
	return pCell
end
-- handler method
--[[
商品点击回调
--]]
function PopShopMediator:CommodityCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local tempdata  = clone(self.gridViewData[tag])
	tempdata.lifeLeftPurchasedNum = tempdata.leftPurchasedNum
	tempdata.todayLeftPurchasedNum = tempdata.leftPurchasedNum
	local isCanPurchase = true
	if checkint(tempdata.stock) ~= -1 and  tempdata.leftPurchasedNum <= 0 then
		isCanPurchase = false
	end
	if not isCanPurchase then
		app.uiMgr:ShowInformationTips(__('购买次数已经用完'))
		return
	end

	local marketPurchasePopup  = require('Game.views.ShopPurchasePopup').new({tag = 5001, mediatorName = "PopShopMediator", data = tempdata, btnTag = tag,showChooseUi = true})
	display.commonUIParams(marketPurchasePopup, {ap =display.CENTER, po = display.center})
	marketPurchasePopup:setTag(5001)
	local farmSeedConf = CONF.ACTIVITY_POP.FARM_SEED:GetValue(self.summaryId)
	local farmOneSeedConf = farmSeedConf[tostring(self.gridViewData[tag].goodsId)]
	local text = farmOneSeedConf.name
	local viewData = marketPurchasePopup.viewData
	display.commonLabelParams(viewData.goodsName , {text = text})
	display.commonLabelParams(viewData.descrLabel , {text = farmOneSeedConf.descr or text})
	app.uiMgr:GetCurrentScene():AddDialog(marketPurchasePopup)
	viewData.goodNode.icon:removeAllChildren()
	viewData.goodNode:setEnabled(false)

	local seedImage = display.newImageView(_res( string.format('ui/link/popMain/goods_icon_seeds_%d.png' , checkint(self.gridViewData[tag].goodsId))) ,0 ,0  )
	viewData.goodNode.icon:addChild(seedImage, 10)

	viewData.purchaseBtn:setOnClickScriptHandler(handler(self, self.PurchaseBtnCallback))
	viewData.purchaseBtn:setTag(tag)
end
--[[
购买按钮点击回调
--]]
function PopShopMediator:PurchaseBtnCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local purchaseNum = sender:getUserTag()
	local datas = self.gridViewData[tag]
	local currency = datas.currency
	local money = CommonUtils.GetCacheProductNum(currency)
	local price = datas.price * checkint(purchaseNum)
	if checkint(money) < checkint(price) then
		local goodOneData = CommonUtils.GetConfig('goods','goods',currency ) or {}
		local des = goodOneData.name or __('货币')
		app.uiMgr:ShowInformationTips(string.fmt(__('_des_不足'),{_des_ = des}))
		return
	end
	self:SendSignal(POST.POP_FARM_MALL_BUY.cmdName ,{
		activityId = self.activityId ,
		productId = datas.productId ,
		productNum = purchaseNum ,
		index = tag
	})
end
function PopShopMediator:EnterLayer()
	self:SendSignal(POST.POP_FARM_MALL.cmdName , {activityId = self.activityId})
end

function PopShopMediator:OnRegist(  )
	regPost(POST.POP_FARM_MALL)
	regPost(POST.POP_FARM_MALL_BUY)
	self:EnterLayer()
end

function PopShopMediator:OnUnRegist(  )
	unregPost(POST.POP_FARM_MALL)
	unregPost(POST.POP_FARM_MALL_BUY)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:runAction(cc.RemoveSelf:create())
	end
end

return PopShopMediator
