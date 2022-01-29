--[[
背包
]]
local Mediator = mvc.Mediator

local BackPackMediator = class("BackPackMediator", Mediator)

-- MaterialCompose_Callback = 'MaterialCompose_Callback'

local NAME = "BackPackMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local dataMgr = AppFacade.GetInstance():GetManager("DataManager")

local BackpackCell = require('home.BackpackCell')
-- local GoodsSale = require('common.GoodsSale')
-- 活动道具类型（还不知道这个东西是怎么定义的，一个类型对应一个道具还是一类道具，暂时先这么写吧）
local ACTIVITY_GOODS_TYPE = {
	ANNIVERSARY_19_HP = 3,
}
-- 活动道道具在背包是否隐藏
local ACTIVITY_GOODS_HIDE_CONFIG = {
	[tostring(ACTIVITY_GOODS_TYPE.ANNIVERSARY_19_HP)] = true
}

local IGNORE_TYPE_MAP = {
	[GoodsType.TYPE_ARCHIVE_REWARD]       = true,
	[GoodsType.TYPE_AVATAR]               = true,
	[GoodsType.TYPE_THEME]                = true,
	[GoodsType.TYPE_CG_FRAGMENT]          = true,
	[GoodsType.TYPE_PRIVATEROOM_THEME]    = true,
	[GoodsType.TYPE_PRIVATEROOM_SOUVENIR] = true,
	[GoodsType.TYPE_HOUSE_AVATAR]         = true,
	[GoodsType.TYPE_HOUSE_STYLE]          = true,
}
function BackPackMediator:isIgnoreType(goodsType)
	return IGNORE_TYPE_MAP[tostring(goodsType)] == true
end


function BackPackMediator:ctor( viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.backPackDatas = {} --全部背包数据
	self.clickTag = 1001 --选择道具类别
	self.datas = {}
	self.preIndex = 1 --列表第几个
	self.saleNum = 0 --出售数量
	self.saleId = '' --出售物品id

	self.useNum = 0 --使用数量
	self.useId = '' --使用id
	self.gridContentOffset = cc.p(0,0) --滑动层偏移量
end

function BackPackMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.BackPack_Name_Callback,
		SIGNALNAMES.BackPack_SaleGoods_Callback,
		SIGNALNAMES.BackPack_UseGoods_Callback,
		SIGNALNAMES.MaterialCompose_Callback,
		SIGNALNAMES.RecipeCookingMaking_Callback,
		SIGNALNAMES.Updata_BackPack_Callback,
		BACKPACK_OPTIONAL_OPTIONAL_CHEST_DRAW,
	}

	return signals
end

function BackPackMediator:ProcessSignal(signal )
	local name = signal:GetName()
	--print(name)
	local gridView =  self.viewComponent.viewData_.gridView
	if name == SIGNALNAMES.BackPack_Name_Callback then
		--更新UI
		-- self.backPackDatas = checktable(checktable(signal:GetBody()).packslist)
		-- self:ButtonActions(self.clickTag)
	elseif name == SIGNALNAMES.BackPack_SaleGoods_Callback then --出售物品回调
		CommonUtils.DrawRewards({{goodsId = self.saleId, num = - checkint(self.saleNum)}})
		self.backPackDatas = {}
		for k,v in pairs(gameMgr:GetUserInfo().backpack) do
			if CommonUtils.GetGoodTypeById(v.goodsId) ~= GoodsType.TYPE_ARCHIVE_REWARD then
				if v.amount > 0 then
					table.insert(self.backPackDatas,clone(v))
				end
			end
		end
		self:ButtonActions(self.clickTag)
		-- self.gridContentOffset = self:returnsetContentOffset(self.gridContentOffset,gridView:getContentSize(),gridView:getContainerSize())
		gridView:setContentOffset(self.gridContentOffset)

		local data = CommonUtils.GetConfig('goods', 'goods', self.saleId)

		if signal:GetBody().diamond then --使用类型为幻晶石
			gameMgr:GetUserInfo().diamond =  signal:GetBody().diamond
			self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{diamond = (signal:GetBody().diamond)})
		end
		if signal:GetBody().gold then --使用类型为金币
			gameMgr:GetUserInfo().gold = signal:GetBody().gold
			self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{gold = (signal:GetBody().gold)})
		end
		local str = ''
		if data then
			if data.sellCurrency == '2' then
				str = string.fmt(__('恭喜获得 _value_ 金币'),{_value_ = signal:GetBody().addNum})
			elseif data.sellCurrency == '1' then
				str = string.fmt(__('恭喜获得 _value_ 幻晶石'),{_value_ = signal:GetBody().addNum})
			end
		end
		uiMgr:ShowInformationTips(str)
	elseif name == SIGNALNAMES.BackPack_UseGoods_Callback then--使用物品回调
		local body =  signal:GetBody()

		local requestData = body.requestData
		local useId = requestData.goodsId
		local useNum = requestData.num
		body.requestData = nil
		--local useId
		CommonUtils.DrawRewards({{goodsId = useId, num = - checkint(useNum)}})
		local tempBool = false
		local endPos = cc.p(0,0)
		local data = CommonUtils.GetConfig('goods', 'goods', useId)
		local str = ''
		local rewardId = ''
		if data.effectType == USE_ITEM_TYPE_DIAMOND then --使用类型为幻晶石
			gameMgr:GetUserInfo().diamond = gameMgr:GetUserInfo().diamond + signal:GetBody()[1].num
			rewardId = DIAMOND_ID
			tempBool = true
			endPos = cc.p(display.width - 200,display.height - 50)
			str = string.fmt(__('恭喜获得 _value_ 幻晶石'),{_value_ = signal:GetBody()[1].num})

		elseif data.effectType == USE_ITEM_TYPE_GOLD then --使用类型为金币
			gameMgr:GetUserInfo().gold = gameMgr:GetUserInfo().gold + signal:GetBody()[1].num
			rewardId = GOLD_ID
			tempBool = true
			endPos = cc.p(display.width - 400,display.height - 50)
			str = string.fmt(__('恭喜获得 _value_ 金币'),{_value_ = signal:GetBody()[1].num})

		elseif data.effectType == USE_ITEM_TYPE_HP then --使用类型为体力
			-- gameMgr:GetUserInfo().hp = gameMgr:GetUserInfo().hp + signal:GetBody()[1].num
			gameMgr:UpdateHp(gameMgr:GetUserInfo().hp + signal:GetBody()[1].num)
			rewardId = HP_ID
			tempBool = true
			endPos = cc.p(display.width - 620,display.height - 50)
			str = string.fmt(__('恭喜获得 _value_ 体力'),{_value_ = signal:GetBody()[1].num})
		elseif data.effectType == USE_ITEM_TYPE_EXP then --使用类型为体力
			uiMgr:AddDialog('common.RewardPopup', {rewards = { { goodsId = EXP_ID , num = checkint(data.effectNum)  }}  })
		else--使用大礼包
			data = signal:GetBody()
			if data then
				uiMgr:AddDialog('common.RewardPopup', {rewards = data })
			end
			-- str = __('成功使用大礼包')
		end
		self.backPackDatas = {}
		local type = nil
		for k,v in pairs(gameMgr:GetUserInfo().backpack) do
			type =  CommonUtils.GetGoodTypeById(v.goodsId)
			if not self:isIgnoreType(type) then
				if checkint(v.amount) > 0 then
					table.insert(self.backPackDatas,clone(v))
				end
			end
		end
		if str ~= '' then
			uiMgr:ShowInformationTips(str)
		end
		if tempBool == true then
			local viewData = self.viewComponent.viewData_
			local gridView = viewData.gridView
		    local cell = gridView:cellAtIndex(self.preIndex - 1)
		    local point = cc.p(display.width*0.5,display.height*0.5)
		    if cell then
				point = cell:convertToWorldSpace(utils.getLocalCenter(cell))
			end
			local scene = uiMgr:GetCurrentScene()
		    if scene:GetDialogByTag(555) then
				if data.effectType == USE_ITEM_TYPE_DIAMOND then --使用类型为幻晶石
					self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{diamond = (gameMgr:GetUserInfo().diamond)})
				elseif data.effectType == USE_ITEM_TYPE_GOLD then --使用类型为金币
					self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{gold = (gameMgr:GetUserInfo().gold)})
				elseif data.effectType == USE_ITEM_TYPE_HP then --使用类型为体力
					self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{hp = (gameMgr:GetUserInfo().hp)})
				end
		    	scene:RemoveDialogByTag(555)
		    end
			local posTab = {
				['110001'] =  {--幻晶石包
					cc.p(0,60),
					cc.p(-20,30),
					cc.p(25,30),
					cc.p(-40,-30),
					cc.p(30,-30)
				},
				['120001'] =  {--小金币包
					cc.p(0,60),
					cc.p(-20,30),
					cc.p(25,30),
					cc.p(-40,-30),
					cc.p(30,-30)
				},
				['120002'] =  {--大金币包
					cc.p(0,60),
					cc.p(-20,30),
					cc.p(25,30),
					cc.p(-30,-30),
					cc.p(30,-30),
					cc.p(math.random(10),math.random(90)),
					cc.p(math.random(30),math.random(70)),
					cc.p(math.random(50),math.random(50)),
					cc.p(math.random(70),math.random(30)),
					cc.p(math.random(90),math.random(10))
				},
				['120003'] =  {--小体力药水
					cc.p(0,60),
					cc.p(-20,30),
					cc.p(25,30),
					cc.p(-40,-30),
					cc.p(30,-30)
				},
				['120004'] =  {--中体力药水
					cc.p(0,60),
					cc.p(-20,30),
					cc.p(25,30),
					cc.p(-30,-30),
					cc.p(30,-30),
					cc.p(math.random(10),math.random(90)),
					cc.p(math.random(30),math.random(70)),
					cc.p(math.random(50),math.random(50))
				}
			}
			-- dump(posTab[tostring(self.useId)])
			if posTab[tostring(useId)] then
				for i=1,table.nums(posTab[tostring(useId)]) do
					local iconPath = CommonUtils.GetGoodsIconPathById(rewardId)
					local img= display.newImageView(_res(iconPath),0,0,{as = false})

					img:setPosition(point)
					img:setTag(555)
					scene:AddDialog(img,10)

				 	--    local particle = cc.ParticleSystemQuad:create('effects/jinbi.plist')
				 	--    particle:setAutoRemoveOnFinish(true)
				 	--    particle:setPosition(cc.p(img:getContentSize().width* 0.5,img:getContentSize().height* 0.5))
					--    img:addChild(particle,10)
					local scale = 0.4
					if tostring(useId) == '120002' or tostring(useId) == '120004' then
						scale = 0.3
					end
					img:setScale(0)
					local actionSeq = cc.Sequence:create(
						cc.Spawn:create(
							cc.ScaleTo:create(0.2, scale),
							cc.MoveBy:create(0.3,posTab[tostring(useId)][i])
							),
						cc.MoveBy:create(0.1+i*0.11,cc.p(math.random(15),math.random(15))),
						cc.DelayTime:create(i*0.01),
						cc.Spawn:create(
							cc.MoveTo:create(0.4,endPos ),
							cc.ScaleTo:create(0.4, 0.2)
							),
						cc.CallFunc:create(function ()
								if data.effectType == USE_ITEM_TYPE_DIAMOND then --使用类型为幻晶石
									self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{diamond = (gameMgr:GetUserInfo().diamond)})
								elseif data.effectType == USE_ITEM_TYPE_GOLD then --使用类型为金币
									self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{gold = (gameMgr:GetUserInfo().gold)})
								elseif data.effectType == USE_ITEM_TYPE_HP then --使用类型为体力
									self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{hp = (gameMgr:GetUserInfo().hp)})
								end
		          			end),
						cc.RemoveSelf:create())
					img:runAction(actionSeq)
			    end
			end
		end
		self:ButtonActions(self.clickTag)


		-- dump(gridView:getMinOffset().y)
		-- dump(gridView:getContentOffset().y)
		-- dump(self.gridContentOffset)
		-- self.gridContentOffset = self:returnsetContentOffset(self.gridContentOffset,gridView:getContentSize(),gridView:getContainerSize())
		if self.gridContentOffset.y >= gridView:getMinOffset().y then
			gridView:setContentOffset(self.gridContentOffset)
		else
			self.gridContentOffset = gridView:getContentOffset()
			gridView:setContentOffsetToTop()
		end
	elseif name == SIGNALNAMES.MaterialCompose_Callback
		or name == SIGNALNAMES.RecipeCookingMaking_Callback
		or name == SIGNALNAMES.Updata_BackPack_Callback then

		--道具合成，制作菜品，扫荡后返回背包界面刷新数据
		xTry(function()
			self.backPackDatas = {}
			local type = nil
			for k,v in pairs(gameMgr:GetUserInfo().backpack) do
				type = CommonUtils.GetGoodTypeById(v.goodsId)
				if not self:isIgnoreType(type) then
					if checkint(v.amount) > 0 then
						table.insert(self.backPackDatas,clone(v))
					end
				end
			end
			self:ButtonActions(self.clickTag)

			-- self.gridContentOffset = self:returnsetContentOffset(self.gridContentOffset,gridView:getContentSize(),gridView:getContainerSize())
			gridView:setContentOffset(self.gridContentOffset)
		end,__G__TRACKBACK__)
	elseif name == BACKPACK_OPTIONAL_OPTIONAL_CHEST_DRAW then
		-- 可选礼包领取
		self:OptionalChestDraw(signal:GetBody())
	end
end
function BackPackMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.BackPackView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddGameLayer(viewComponent)

	--绑定相关的事件
	local viewData = viewComponent.viewData_
	for k, v in pairs( viewData.buttons ) do
		v:setOnClickScriptHandler(handler(self,self.ButtonActions))
	end
	local gridView = viewData.gridView
	gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))

	--viewData.saleBtn:setOnClickScriptHandler(handler(self,self.ButtonCallback))
	display.commonUIParams(viewData.saleBtn , { cb= handler(self,self.ButtonCallback)})
	viewComponent.compeseImgBtn:setOnClickScriptHandler(handler(self, self.MaterialCompeseBtnCallback))
	if CommonUtils.GetModuleAvailable(MODULE_SWITCH.MATERIALCOMPOSE) then
		viewComponent.compeseLabelBtn:setOnClickScriptHandler(handler(self, self.MaterialCompeseBtnCallback))
	else
		viewComponent.compeseImgBtn:setVisible(false)
		viewComponent.compeseLabelBtn:setVisible(false)
	end

	viewData.getBtn:setVisible(true)
	viewData.getBtn:setEnabled(true)
	viewData.getBtn:setOnClickScriptHandler(handler(self,self.ButtonCallback))

end

--材料合成按钮
function BackPackMediator:MaterialCompeseBtnCallback(sender)
	if CommonUtils.UnLockModule(JUMP_MODULE_DATA.MATERIALCOMPOSE, true) then
		local MaterialComposeMediator = require( 'Game.mediator.MaterialComposeMediator')
		local mediator = MaterialComposeMediator.new()
		self:GetFacade():RegistMediator(mediator)
	end
end

--背包列表数据源
function BackPackMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local viewData = self.viewComponent.viewData_
    local bg = viewData.gridView
    local sizee = cc.size(108, 115)

    if self.datas and index <= table.nums(self.datas) then
        local data = CommonUtils.GetConfig('goods', 'goods', self.datas[index].goodsId)
        if pCell == nil then
            pCell = BackpackCell.new(sizee)
            pCell.toggleView:setOnClickScriptHandler(handler(self,self.CellButtonAction))

            if index <= 20 then
				pCell.eventnode:setPositionY(sizee.height - 800)
			    pCell.eventnode:runAction(
			        cc.Sequence:create(cc.DelayTime:create(index * 0.01),
			        cc.EaseOut:create(cc.MoveTo:create(0.4, cc.p(sizee.width* 0.5,sizee.height * 0.5)), 0.2))
			    )
			else
            	pCell.eventnode:setPosition(cc.p(sizee.width* 0.5,sizee.height * 0.5))
			end
        else
            pCell.selectImg:setVisible(false)
            pCell.eventnode:setPosition(cc.p(sizee.width* 0.5,sizee.height * 0.5))
        end
		xTry(function()

			if self.datas[index].IsNew then
				if self.datas[index].IsNew == 1 then
					pCell.newIcon:setVisible(true)
				else
					pCell.newIcon:setVisible(false)
				end
			else
				pCell.newIcon:setVisible(false)
			end

			local quality = 1
			if data then
				if data.quality then
					quality = data.quality
				end
			end

			local drawBgPath = _res('ui/common/common_frame_goods_'..tostring(quality)..'.png')
			local fragmentPath = _res('ui/common/common_ico_fragment_'..tostring(quality)..'.png')
			if not utils.isExistent(drawBgPath) then
				drawBgPath = _res('ui/common/common_frame_goods_'..tostring(1)..'.png')
				fragmentPath = _res('ui/common/common_ico_fragment_'..tostring(quality)..'.png')
			end
			pCell.fragmentImg:setTexture(fragmentPath)
			pCell.toggleView:setNormalImage(drawBgPath)
			pCell.toggleView:setSelectedImage(drawBgPath)
			pCell.toggleView:setTag(index)
			pCell.toggleView:setScale(0.92)
			pCell:setTag(index)

			if data then
				if tostring(data.type) == GoodsType.TYPE_CARD_FRAGMENT then
					pCell.fragmentImg:setVisible(true)
				else
					pCell.fragmentImg:setVisible(false)
				end
			else
				pCell.fragmentImg:setVisible(false)
			end
			if index == self.preIndex then
				pCell.selectImg:setVisible(true)
			else
				pCell.selectImg:setVisible(false)
			end
			pCell.numLabel:setString(tostring(self.datas[index].amount))

			local node = pCell.toggleView:getChildByTag(111)
			if node then node:removeFromParent() end

			local goodsId   = self.datas[index].goodsId
			local lsize     = pCell.toggleView:getContentSize()
			local goodsNode = CommonUtils.GetGoodsIconNodeById(goodsId, lsize.width * 0.5,lsize.height * 0.5, {scale = 0.55})
			goodsNode:setTag(111)
			pCell.toggleView:addChild(goodsNode)
		end,__G__TRACKBACK__)
        return pCell
    end
end
--[[
列表的单元格按钮的事件处理逻辑
@param sender button对象
--]]
function BackPackMediator:CellButtonAction( sender )
    -- sender:setChecked(true)
	local viewData = self.viewComponent.viewData_
	local gridView = viewData.gridView
    local index = sender:getTag()
    local cell = gridView:cellAtIndex(index- 1)
    if cell then
        cell.selectImg:setVisible(true)
        cell.newIcon:setVisible(false)
        gameMgr:UpdateBackpackNewStatuByGoodId(self.datas[index].goodsId)
        self.datas[index].IsNew = 0
    end

    if index == self.preIndex then return end
    --更新按钮状态
    local cell = gridView:cellAtIndex(self.preIndex - 1)
    if cell then
        cell.selectImg:setVisible(false)
    end
    self.preIndex = index
    self.gridContentOffset = gridView:getContentOffset()
    -- dump(self.gridContentOffset)
    self:updateDescription(self.preIndex)
end
--[[
主页面tab按钮的事件处理逻辑
@param sender button对象
--]]
function BackPackMediator:ButtonActions( sender )
	local tag = 0
	local temp_data = {}
	if type(sender) == 'number' then
		tag = sender
	else
		PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id)
		tag = sender:getTag()
		if self.clickTag == tag then
			return
		else
			self.preIndex = 1
		end
	end

	local viewData = self.viewComponent.viewData_
	local bgZorder = viewData.bgView:getLocalZOrder()
	for k, v in pairs( viewData.buttons ) do
		local curTag = v:getTag()
		if tag == curTag then
			v:setChecked(true)
			v:setEnabled(false)
		else
			v:setChecked(false)
			v:setEnabled(true)
		end
	end
	sortByMember(self.backPackDatas, "goodsId", true)



    if tag == 1001 then
        temp_data = self.backPackDatas
		self:SortByAllGoods( temp_data )
    else
        for k, item in pairs( self.backPackDatas ) do
            local data = CommonUtils.GetConfig('goods', 'goods', item.goodsId)
            if data then
                if tag == 1002 and tostring(data.type) == GoodsType.TYPE_CARD_FRAGMENT then
                    -- dump(data.type)
                    table.insert(temp_data,item)
                elseif tag == 1003 then
                    --道具列表
                    local ttype = tostring(data.type)
                    if ttype == GoodsType.TYPE_GOODS_CHEST then
                        --道具列表
                        table.insert(temp_data, 1, item)
                    elseif ttype == GoodsType.TYPE_EXP_ITEM or ttype == GoodsType.TYPE_UN_STABLE or ttype == GoodsType.TYPE_ACTIVITY
                        or ttype == GoodsType.TYPE_OTHER or ttype == GoodsType.TYPE_MONEY then
						table.insert(temp_data,item)
					elseif item.goodsId == MID_AUTUMN_BOX_ID then
                        table.insert(temp_data, 1, item)
                    elseif ttype == GoodsType.TYPE_DIAMOND or ttype == GoodsType.TYPE_GOLD then
                        table.insert(temp_data, 1, item)
                    end
                elseif tag == 1004 and tostring(data.type) == GoodsType.TYPE_FOOD_MATERIAL then
                    table.insert(temp_data,item)
                elseif tag == 1005 and tostring(data.type) == GoodsType.TYPE_UPGRADE_ITEM then
                    table.insert(temp_data,item)
                elseif tag == 1006 and (tostring(data.type) == GoodsType.TYPE_MAGIC_FOOD or tostring(data.type) == GoodsType.TYPE_FOOD)  then
                    if tostring(data.type) == GoodsType.TYPE_MAGIC_FOOD then
                        table.insert(temp_data,1,item)
                    else
                        table.insert(temp_data,item)
                    end
                end
            end
        end
    end

	local viewData = self.viewComponent.viewData_
	local gridView = viewData.gridView
	self.clickTag = tag
	self.datas = temp_data
	-- self.preIndex = 1
	-- print(table.nums(temp_data))
	-- dump(self.datas)
	self.gridContentOffset = gridView:getContentOffset()
    if temp_data and table.nums(temp_data) > 0 then
    	-- sortByMember(self.datas, "goodsId", true)
        gridView:setCountOfCell(table.nums(self.datas))

        self:updateDescription(self.preIndex)
        gridView:reloadData()
        viewData.kongBg:setVisible(false)
		viewData.bgView:setVisible(true)
    else
        self.datas = {}
        gridView:setCountOfCell(table.nums(self.datas))
        gridView:reloadData()
		viewData.bgView:setVisible(false)
        viewData.kongBg:setVisible(true)
    end
    -- self.gridContentOffset = gridView:getContentOffset()
    -- dump(self.gridContentOffset)
end

--全部tab页签  进行排序
function BackPackMediator:SortByAllGoods( sortData )
	for k,v in pairs(sortData) do
		local data = CommonUtils.GetConfig('goods', 'goods', v.goodsId)
        if data then
	        if tostring(data.type) == GoodsType.TYPE_CARD_FRAGMENT then
		        v.sortIndex = 5
	        elseif tostring(data.type) == GoodsType.TYPE_GOODS_CHEST then
		        v.sortIndex = 7
	        elseif tostring(data.type) == GoodsType.TYPE_FOOD_MATERIAL then
		        v.sortIndex = 3
	        elseif tostring(data.type) == GoodsType.TYPE_UPGRADE_ITEM then
		        v.sortIndex = 4
	        elseif (tostring(data.type) == GoodsType.TYPE_MAGIC_FOOD or tostring(data.type) == GoodsType.TYPE_FOOD)  then
		        v.sortIndex = 2
	        elseif tostring(data.type) == GoodsType.TYPE_OPTIONAL_CHEST then
		        v.sortIndex = 8
	        else
		        v.sortIndex = 6
	        end
        end
	end
	table.sort(self.backPackDatas, function(a, b)
		local as = checkint(checktable(a).sortIndex)
		local bs = checkint(checktable(b).sortIndex)
		local ao = 0
		local bo = 0
		if a.order then
			ao = checkint(a.order)
		end
		if b.order then
			bo = checkint(b.order)
		end
		if as == bs then
			return ao > bo
		else
			return as > bs
		end
    end)
end



--[[
	第一个是移动的距离，容量大小，第三个是内容大小
--]]
function BackPackMediator:returnsetContentOffset(point,contentSize,containerSize)
	-- dump(point)
	-- dump(contentSize.height)
	-- dump(containerSize.height)
	if math.abs(point.y) + contentSize.height > containerSize.height then
		return cc.p(0,contentSize.height - containerSize.height)
	else
		return point
	end
end
--[[
出售物品界面确认出售按钮回调
@param num 出售数量
--]]

function BackPackMediator:sureSaleCallBack( GoodNum , GoodId )
	self.saleNum = GoodNum
	self.saleId = GoodId
	self:SendSignal(COMMANDS.COMMAND_BackPack_Sale,{goodsId = GoodId,num = GoodNum})
end
--[[
主页面出售，获取按钮的事件处理
@param sender button对象
--]]
function BackPackMediator:ButtonCallback( sender )
	local tag = sender:getTag()
	local scene = uiMgr:GetCurrentScene()
	if tag == 1 then 		-- 出售
		if scene:GetDialogByTag(9999) == nil and table.nums(self.datas) > 0 then
			-- local tempData = self.datas[self.preIndex]
			local tempData = CommonUtils.GetConfig('goods', 'goods', self.datas[self.preIndex].goodsId)
			tempData.amount = self.datas[self.preIndex].amount
			tempData.callback = handler(self, self.sureSaleCallBack)
			local GoodsSale  = require( 'common.GoodsSale' ).new(tempData)
			GoodsSale:RefreshUI()
			GoodsSale:setPosition(display.center)
			scene:AddDialog(GoodsSale)

		end
	elseif tag == 2 then 	-- 获取
			uiMgr:AddDialog('common.GainPopup', {goodId = self.datas[self.preIndex].goodsId,isFrom = 'BackPackMediator'})
	elseif tag == 3 then
		if self.datas[self.preIndex].goodsId == MID_AUTUMN_BOX_ID then -- 中秋礼盒
			local RecordInfoMediator = require( 'Game.mediator.RecordInfoMediator')
			local mediator = RecordInfoMediator.new(MID_AUTUMN_BOX_ID)
			self:GetFacade():RegistMediator(mediator)
			return
		end
		if CommonUtils.GetGoodTypeById(self.datas[self.preIndex].goodsId) == GoodsType.TYPE_OPTIONAL_CHEST then
			-- 显示选择弹窗
			app.uiMgr:AddDialog("Game.views.BackPackOptionalPopup", {goodsId = self.datas[self.preIndex].goodsId})
			return 
		end
		if gameMgr:GetAmountByGoodId(self.datas[self.preIndex].goodsId) == 1 then--数量为1直接使用，不出弹框
			local data = CommonUtils.GetConfig('goods', 'goods', self.datas[self.preIndex].goodsId)
			if data.effectType == USE_ITEM_TYPE_DIAMOND then --使用类型为幻晶石
				PlayAudioClip(AUDIOS.UI.ui_diamond.id)
			elseif data.effectType == USE_ITEM_TYPE_GOLD then --使用类型为金币
				PlayAudioClip(AUDIOS.UI.ui_coin.id)
			end

    		self.useNum = 1
			self.useId = self.datas[self.preIndex].goodsId
	    	self:SendSignal(COMMANDS.COMMAND_BackPack_Use,{goodsId = self.datas[self.preIndex].goodsId,num = 1})
		else
			local function callback( num )
				local data = CommonUtils.GetConfig('goods', 'goods', self.datas[self.preIndex].goodsId)
				if data.effectType == USE_ITEM_TYPE_DIAMOND then --使用类型为幻晶石
					PlayAudioClip(AUDIOS.UI.ui_diamond.id)
				elseif data.effectType == USE_ITEM_TYPE_GOLD then --使用类型为金币
					PlayAudioClip(AUDIOS.UI.ui_coin.id)
				end

				self.useId = self.datas[self.preIndex].goodsId
				self.useNum = gameMgr:GetAmountByGoodId(self.useId)
		    	self:SendSignal(COMMANDS.COMMAND_BackPack_Use,{goodsId = self.datas[self.preIndex].goodsId,num = num})
			end

			local scene = uiMgr:GetCurrentScene()
			local CountChoosePopUp  = require( 'common.CountChoosePopUp' ).new({goodsId = self.datas[self.preIndex].goodsId, callback = callback})
			CountChoosePopUp:setPosition(display.center)
			scene:AddDialog(CountChoosePopUp,10)
		end
	end
end
--[[
主页面详情描述页面
@param index int下标
--]]
function BackPackMediator:updateDescription( index )
	if self.datas and table.nums(self.datas) > 0 then
		if not self.datas[index] then
			self.preIndex = self.preIndex - 1
			self:updateDescription( self.preIndex )
			local gridView = self.viewComponent.viewData_.gridView
			local pCell = gridView:cellAtIndex(table.nums(self.datas) - 1)
			if pCell then
	            -- pCell.toggleView:setChecked(true)
	            pCell.selectImg:setVisible(true)
	        end
	        -- dump(self.gridContentOffset)
	        gridView:setContentOffset(self.gridContentOffset)
			return
		end

		local data = CommonUtils.GetConfig('goods', 'goods', self.datas[index].goodsId)
		local viewData = self.viewComponent.viewData_

		local reward_rank 	=  viewData.reward_rank
		local DesNameLabel 	=  viewData.DesNameLabel
		-- local DesTypeLabel 	=  viewData.DesTypeLabel
		local DesNumLabel 	=  viewData.DesNumLabel
		local DesPriceLabel =  viewData.DesPriceLabel
		local DesLabel 		=  viewData.DesLabel
		local saleBtn 		=  viewData.saleBtn
		local fragmentImg 	=  viewData.fragmentImg
		fragmentImg:setVisible(false)
		saleBtn:setTag(1)
		saleBtn:getLabel():setString(__('出售'))
		if data then
			--物品材料等级
			local quality = checkint(data.quality) % CARD_BREAK_MAX
			if quality <= 0 then
				quality = 1
			end
			local bgPath = string.format('ui/common/common_frame_goods_%d.png', checkint(data.quality or 1))
			reward_rank:setTexture(_res(bgPath))
			reward_rank:setTexture(_res(bgPath))

			local fragmentPath = string.format('ui/common/common_ico_fragment_%d.png', checkint(data.quality or 1))
			fragmentImg:setTexture(_res(fragmentPath))

			if data.type then
				if tostring(data.type) == GoodsType.TYPE_CARD_FRAGMENT then
					fragmentImg:setVisible(true)
				end
			end
			--物品图片
			local position = cc.sizep(reward_rank:getContentSize(), ui.cc)
			local goodsId  = self.datas[index].goodsId
			local imgIcon  = reward_rank:getChildByName("icon")
			if not tolua.isnull(imgIcon) then
				imgIcon:removeFromParent()
			end
			imgIcon = CommonUtils.GetGoodsIconNodeById(goodsId, position.x, position.y, {scale = 0.5})
			reward_rank:addChild(imgIcon)
			imgIcon:setName("icon")

	        --物品名称
			DesNameLabel:setString(data.name)

			--物品类型
	        local temp_type_src = ''
	        local ttype = CommonUtils.GetGoodTypeById(self.datas[index].goodsId)
	        temp_type_src = CommonUtils.GetConfig('goods', 'type', ttype).type

			-- DesTypeLabel:setString(string.fmt(__('类型:_name_'), {_name_ = temp_type_src}))

			--物品数量
			DesNumLabel:setString(string.fmt(__('数量: _name_'), {_name_ = self.datas[index].amount}))

			--物品价格
			saleBtn:setVisible(true)
			if data.canSell == '1' then
				if data.sellCurrency == '2' then
					DesPriceLabel:setString(string.fmt(__('售价: _num_金币'), {_num_ = (data.goldValue or  '--')}))

				elseif data.sellCurrency == '1' then
					DesPriceLabel:setString(string.fmt(__('数量: _num_幻晶石'), {_num_ = (data.diamondValue or  '--')}))
				end
			else
				saleBtn:setVisible(false)
				DesPriceLabel:setString(__('售价: --'))
			end


			DesLabel:setString(data.descr)

			local tempType = CommonUtils.GetGoodTypeById(self.datas[index].goodsId)
			local canUse = CommonUtils.GetConfig('goods', 'type', tempType).canUse
			if canUse == '1'  then
				saleBtn:setTag(3)
				saleBtn:getLabel():setString(__('使用'))
				saleBtn:setVisible(true)
			end

		else
			-- dump(self.datas[index].goodsId)
			DesLabel:setString(__('物品不存在。'))
		end
	end
end

--[[
可选礼包领取
@params body map {
	goodsId int    道具id
	choices string 选择的奖励(多个逗号分隔)
}
--]]
function BackPackMediator:OptionalChestDraw( body )
	self:SendSignal(COMMANDS.COMMAND_BackPack_Use,{goodsId = body.goodsId, num = 1, choices = body.choices})
end
function BackPackMediator:EnterLayer()
	local tag = 1001
	local viewData = self.viewComponent.viewData_
	for k, v in pairs( viewData.buttons ) do
		local curTag = v:getTag()
		if tag == curTag then
			v:setChecked(true)
		else
			v:setChecked(false)
		end
	end
	self.backPackDatas = {}
	local type = nil
	local activityGoodsConf = CommonUtils.GetConfigAllMess('activity' , 'goods')
	for k,v in pairs(gameMgr:GetUserInfo().backpack) do
		type = CommonUtils.GetGoodTypeById(v.goodsId)
		if type == GoodsType.TYPE_ACTIVITY then
			-- 如果为活动道具，根据活动道具类型决定是否显示在背包中
			local activityType = tostring(activityGoodsConf[tostring(v.goodsId)])
			if not ACTIVITY_GOODS_HIDE_CONFIG[activityType] then
				if v.amount > 0  then
					table.insert(self.backPackDatas,clone(v))
				end
			end
		elseif not self:isIgnoreType(type) then
			if GoodsUtils.IsHiddenGoods(v.goodsId) then
			else
				if v.amount > 0  then
					table.insert(self.backPackDatas,clone(v))
				end
			end
		end
	end
	self:ButtonActions(self.clickTag)
end
function BackPackMediator:OnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
	local BackPackCommand = require( 'Game.command.BackPackCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_BackPack_Sale, BackPackCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_BackPack_Use, BackPackCommand)
	self:EnterLayer()
end
function BackPackMediator:OnUnRegist(  )
	--称出命令
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	-- self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_BackPack)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_BackPack_Sale)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_BackPack_Use)

	AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
end

return BackPackMediator
