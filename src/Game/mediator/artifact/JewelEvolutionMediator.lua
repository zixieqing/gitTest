--[[
	宝石进阶
--]]
local Mediator = mvc.Mediator

local JewelEvolutionMediator = class("JewelEvolutionMediator", Mediator)

local NAME = "artifact.JewelEvolutionMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local artiMgr = AppFacade.GetInstance():GetManager("ArtifactManager")
local parseConfig = artiMgr:GetConfigParse()

local BackpackCell = require('home.BackpackCell')

local EVOLUTION_COST = 3
local MAX_LIMIT = true

function JewelEvolutionMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.jewelsData = {}
	self.clickJewelType = nil
	self.jewelsSpecificData = {}
	self.chooseData	= {}
	self.selectNum = 1
	self.isFirst = 0
	self.chooseModel = 2
end

function JewelEvolutionMediator:InterestSignals()
	local signals = {
		POST.ARTIFACT_GEM_FUSION.sglName,
	}

	return signals
end

function JewelEvolutionMediator:ProcessSignal(signal )
	local name = signal:GetName()
	local body = signal:GetBody()
	-- dump(body, name)
	if name == POST.ARTIFACT_GEM_FUSION.sglName then
		local function showEvolResult(  )
			local consume = {}
			for k,v in pairs(json.decode(body.requestData.gemData)) do
				table.insert( consume,{goodsId = tostring(k), num = 0 - checkint(v)} )
			end
			if next(body.back or {}) then
				for k,v in pairs(body.back) do
					local isFind = false
					for _,vc in pairs(consume) do
						if checkint(vc.goodsId) == checkint(v.goodsId) then
							vc.num = vc.num + v.num
							isFind = true
							break
						end
					end
					if not isFind then
						table.insert( consume, v )
					end
				end
			end
			CommonUtils.DrawRewards(consume)
			uiMgr:AddDialog('common.RewardPopup', body)
		
			local gemstone = artiMgr:GetConfigDataByName(parseConfig.TYPE.GEM_STONE)
			local updateColor = {}
			for _,v in pairs(body.rewards) do
					local goodsId = tostring(v.goodsId)
					local color = gemstone[goodsId].color
					if not updateColor[color] then
						updateColor[color] = 1
					end
					local isHave = false
					for k,jewel in pairs(self.jewelsData[color]) do
						if jewel.goodsId == goodsId then
							jewel.amount = jewel.amount + v.num
							isHave = true
							break
						end
					end
					if not isHave then
						local goodData = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
						table.insert(self.jewelsData[color], {goodsId = goodsId, quality = goodData.quality, amount = v.num, grade = tonumber(gemstone[goodsId].grade), type = tonumber(gemstone[goodsId].type)})
					end
			end
			for _,v in pairs(consume) do
					local color = gemstone[tostring(v.goodsId)].color
					if not updateColor[color] then
						updateColor[color] = 1
					end
					for k,jewel in pairs(self.jewelsData[color]) do
						if checkint(jewel.goodsId) == checkint(v.goodsId) then
							jewel.amount = jewel.amount + v.num
							if 0 == jewel.amount then
								table.remove( self.jewelsData[color],k )
							end
							break
						end
					end
			end
			for k, _ in pairs(updateColor) do
					table.sort(self.jewelsData[k], function ( a, b )
						if a.grade == 10 or b.grade == 10 then
							if a.grade < b.grade then
								return true
							elseif a.grade > b.grade then
								return false
							else
								return a.type < b.type
							end
						end
						if a.grade > b.grade then
							return true
						elseif a.grade < b.grade then
							return false
						else
							return a.type < b.type
						end
					end)
			end
			self:ResetRight(true)
		end
		if 1 == self.chooseModel then	--随机合成
			local viewData = self.viewComponent.viewData_
			for k, v in pairs(viewData.Tcells) do
				v.goodsImg:setVisible(false)
				v.levelBg:setVisible(false)
				v.numLabel:setString('')
				v.hasNumLabel:setString('')
				if self.isBatch then
					v.toggleView:setNormalImage(_res('ui/common/compose_frame_unused.png'))
					v.toggleView:setSelectedImage(_res('ui/common/compose_frame_unused.png'))
				else
					v.toggleView:setNormalImage(_res('ui/common/common_frame_goods_1.png'))
					v.toggleView:setSelectedImage(_res('ui/common/common_frame_goods_1.png'))
				end
			
				viewData.Tarrows[k]:setFilter(GrayFilter:create())
			end
			
			local compSpine = viewData.compSpine
			compSpine:setVisible(true)
			compSpine:update(0)
			compSpine:setAnimation(0, 'idle2', false)
			compSpine:setToSetupPose()
			compSpine:unregisterSpineEventHandler(sp.EventType.ANIMATION_END)

			local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
    		eaterLayer:setTouchEnabled(true)
    		eaterLayer:setContentSize(display.size)
    		eaterLayer:setPosition(cc.p(display.cx, display.cy))
			self.viewComponent:addChild(eaterLayer, 1000)
	
			compSpine:registerSpineEventHandler(function (event)
				eaterLayer:removeFromParent()
				compSpine:setVisible(false)
				showEvolResult()
			end, sp.EventType.ANIMATION_END)
		else
			showEvolResult()
		end
	end
end

function JewelEvolutionMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.artifact.JewelEvolutionView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)

	local gemstone = artiMgr:GetConfigDataByName(parseConfig.TYPE.GEM_STONE)
	local jewels = {}
	for k, v in pairs(gemstone) do
		table.insert(jewels, k)
	end
	local gemstoneColor = artiMgr:GetConfigDataByName(parseConfig.TYPE.GEM_STONE_COLOR)
	for k, v in pairs(gemstoneColor) do
		self.jewelsData[k] = artiMgr:GetGemImbedStatusByColor(k)
	end
	for k, v in pairs(gemstoneColor) do
		table.sort(self.jewelsData[k], function ( a, b )
			if a.grade == 10 or b.grade == 10 then
				if a.grade < b.grade then
					return true
				elseif a.grade > b.grade then
					return false
				else
					return a.type < b.type
				end
			end
			if a.grade > b.grade then
				return true
			elseif a.grade < b.grade then
				return false
			else
				return a.type < b.type
			end
		end)
	end

	local viewData = viewComponent.viewData_

	for k, v in pairs( viewData.Tcells ) do
		v.toggleView:setOnClickScriptHandler(handler(self,self.ButtonActions))
	end
	viewData.targetCell.toggleView:setOnClickScriptHandler(handler(self,self.TargetCellButtonAction))
	viewData.batchButton:setOnClickScriptHandler(handler(self,self.BatchButtonAction))
	viewData.specificButton:setOnClickScriptHandler(handler(self,self.TabButtonAction))
	viewData.randomButton:setOnClickScriptHandler(handler(self,self.TabButtonAction))
	
	viewData.btn_minus:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))
	viewData.btn_add:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))
	viewData.btn_max:setOnClickScriptHandler(handler(self,self.ChooseNumBtnCallback))
	viewData.btn_num:setOnClickScriptHandler(handler(self,self.SetNumBtnCallback))
	
	viewData.evolutionBtn:setOnClickScriptHandler(handler(self,self.EvolutionButtonAction))

	viewData.ruleBtn:setOnClickScriptHandler(function(sender)
		PlayAudioByClickNormal()
		uiMgr:ShowIntroPopup({moduleId = INTRODUCE_MODULE_ID.JEWEL_EVOL})
	end)
	
	local gridView = viewData.gridView
	gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
	gridView:setCountOfCell(table.nums(self.jewelsSpecificData))

	local typeGridView = viewData.typeGridView
	typeGridView:setCountOfCell(table.nums(gemstoneColor))
    typeGridView:setDataSourceAdapterScriptHandler(handler(self,self.OnTypeDataSourceAction))
	typeGridView:reloadData()

	self:cellCallBackActions(1)
end

--[[
	点击批量选择按钮
--]]
function JewelEvolutionMediator:BatchButtonAction( sender )
	PlayAudioByClickNormal()
	self.isBatch = sender:isChecked()
	local label = sender:getChildByTag(1)
	if label then
		if self.isBatch then
			label:setString(__('返回'))
		else
			label:setString(__('批量选择'))
		end
	end
	self:ResetRight(true)
end

--[[
	加减最大选择数量按钮回调
--]]
function JewelEvolutionMediator:ChooseNumBtnCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if next(self.chooseData[tostring(1)]) == nil then
		return
	end

	local data = self.chooseData[tostring(1)]
	local viewData = self.viewComponent.viewData_
	if tag == 1 then--减
		if self.selectNum <= 1 then
			return
		end
		if checkint(self.selectNum) > 1 then
			self.selectNum = self.selectNum - 1
		end
	elseif tag == 2 then--加
		if self.selectNum >= 999 then
			uiMgr:ShowInformationTips(__('已达最大合成上限'))
			return
		end
		if (self.selectNum + 1) * EVOLUTION_COST > data.amount and MAX_LIMIT then
			uiMgr:ShowInformationTips(__('已达最大合成上限'))
			return
		end
		self.selectNum = self.selectNum + 1
	elseif tag == 3 then--最大
		self.selectNum = math.floor(data.amount / EVOLUTION_COST)
		self.selectNum = math.max(1, self.selectNum)
	end

	viewData.purchaseNum:setString(tostring(self.selectNum))
	viewData.targetCell.numLabel:setString(tostring(self.selectNum))

	local cost = self.selectNum * EVOLUTION_COST
	local pcell = viewData.Tcells[1]
	pcell.numLabel:setString('/' .. tostring(cost))
	pcell.hasNumLabel:setString(data.amount)
	pcell.hasNumLabel:setPositionX(pcell.numLabel:getPositionX() - pcell.numLabel:getContentSize().width + 4)
	if cost <= data.amount then
		pcell.hasNumLabel:setBMFontFilePath('font/small/common_text_num.fnt')
	else
		pcell.hasNumLabel:setBMFontFilePath('font/small/common_num_unused.fnt')
	end
end

--[[
	打开模拟数字键盘
--]]
function JewelEvolutionMediator:SetNumBtnCallback( sender )
	if next(self.chooseData[tostring(1)]) == nil then
		return
	end
	local tempData = {}
	tempData.callback = handler(self, self.numkeyboardCallBack)
	tempData.titleText = __('请输入需要合成材料的数量')
	tempData.nums = 3
	tempData.model = NumboardModel.freeModel

	local NumKeyboardMediator = require( 'Game.mediator.NumKeyboardMediator' ) 
	local mediator = NumKeyboardMediator.new(tempData)
	self:GetFacade():RegistMediator(mediator)
end

--[[
	数字键盘输入完之后的回调
--]]
function JewelEvolutionMediator:numkeyboardCallBack(data)
	if data then
		if data == '' then
			data = '1'
		end
		if checkint(data) <= 0 then
			data = 1
		end

		local chooseData = self.chooseData[tostring(1)]
		if not chooseData then
			return 
		end
		if (checkint(data)) * EVOLUTION_COST > chooseData.amount and MAX_LIMIT then
			uiMgr:ShowInformationTips(__('已达最大合成上限'))
			return
		end
		self.selectNum = checkint(data)
		local viewData = self.viewComponent.viewData_

		viewData.purchaseNum:setString(tostring(self.selectNum))
		viewData.targetCell.numLabel:setString(tostring(self.selectNum))

		local cost = self.selectNum * EVOLUTION_COST
		local pcell = viewData.Tcells[1]
		pcell.numLabel:setString('/' .. tostring(cost))
		pcell.hasNumLabel:setString(chooseData.amount)
		pcell.hasNumLabel:setPositionX(pcell.numLabel:getPositionX() - pcell.numLabel:getContentSize().width + 4)
		if cost <= chooseData.amount then
			pcell.hasNumLabel:setBMFontFilePath('font/small/common_text_num.fnt')
		else
			pcell.hasNumLabel:setBMFontFilePath('font/small/common_num_unused.fnt')
		end
	end
end

--[[
	点击特定合成 随机合成
--]]
function JewelEvolutionMediator:TabButtonAction( sender )
	local tag = sender:getTag()
	sender:setChecked(true)
	if self.chooseModel == tag then return end
	PlayAudioByClickNormal()
	self.chooseModel = tag
	local viewData = self.viewComponent.viewData_
	if 1 == tag then	--随机合成
		viewData.specificButton:setChecked(false)
		display.commonLabelParams(viewData.specificLabel,{color = '#f3d5c1'})
		display.commonLabelParams(viewData.randomLabel,fontWithColor(16))
		viewData.ListTitleBg:setVisible(true)
		viewData.batchButton:setVisible(true)
		viewData.gridView:setContentSize(cc.size(468, 452))
	else	--特定合成
		viewData.randomButton:setChecked(false)
		display.commonLabelParams(viewData.specificLabel,fontWithColor(16))
		display.commonLabelParams(viewData.randomLabel,{color = '#f3d5c1'})
		viewData.ListTitleBg:setVisible(false)
		viewData.batchButton:setVisible(false)
		viewData.gridView:setContentSize(cc.size(468, 507))
	end
	self:ResetBatch()
	self:ResetRight(false)
end

--[[
	合成按钮
--]]
function JewelEvolutionMediator:EvolutionButtonAction( sender )
	PlayAudioByClickNormal()
	local jewelData = {}
	local type = 1
	if self.isBatch then
		if not next(self.chooseData) then
			uiMgr:ShowInformationTips(__('请先放入塔可才能进行合成哦~'))
			return
		end
		local cnt = 0
		for k, v in pairs(self.chooseData) do
			cnt = cnt + v.amount
		end
		if cnt < EVOLUTION_COST then
			uiMgr:ShowInformationTips(__('塔可数量不足，无法进行合成。'))
			return
		end
		type = 2
		for k,v in pairs(self.chooseData) do
			if jewelData[tostring(v.goodsId)] then
				jewelData[tostring(v.goodsId)] = jewelData[tostring(v.goodsId)] + v.amount
			else
				jewelData[tostring(v.goodsId)] = v.amount
			end
		end
	elseif 1 == self.chooseModel then	--随机合成
		if not next(self.chooseData) then
			uiMgr:ShowInformationTips(__('请先放入塔可才能进行合成哦~'))
			return
		end
		for i=1,3 do
			if not self.chooseData[tostring(i)] then
				uiMgr:ShowInformationTips(__('还不够，还不够，快来填满我'))
				return 
			end
		end
		for i=1,3 do
			local jewel = self.chooseData[tostring(i)]
			if jewelData[tostring(jewel.goodsId)] then
				jewelData[tostring(jewel.goodsId)] = jewelData[tostring(jewel.goodsId)] + 1
			else
				jewelData[tostring(jewel.goodsId)] = 1
			end
		end
		type = 2
	else	--特定合成
		if not self.chooseData[tostring(1)] then
			uiMgr:ShowInformationTips(__('请先放入塔可才能进行合成哦~'))
			return
		end
		if self.chooseData[tostring(1)].amount < EVOLUTION_COST * self.selectNum then
			uiMgr:ShowInformationTips(__('塔可数量不足，无法进行合成。'))
			return 
		end
		jewelData[tostring(self.chooseData[tostring(1)].goodsId)] = EVOLUTION_COST * self.selectNum
		type = 1
	end
	local viewData = self.viewComponent.viewData_
	self:SendSignal(POST.ARTIFACT_GEM_FUSION.cmdName, {type = type, gemData = json.encode(jewelData)})
end

function JewelEvolutionMediator:UpdateJewelData( jewelData, isConsumed )
	local rewards = {}
	for k,v in pairs(jewelData) do
		table.insert( rewards,{goodsId = k, num = isConsumed and -v or v} )
	end
	CommonUtils.DrawRewards(rewards)
end

--[[
	左侧颜色Tab数据
--]]
function JewelEvolutionMediator:OnTypeDataSourceAction( p_convertview,idx )
	local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
	local sizee = cc.size(191 , 83)
	local nameLabel = nil
	local jewelImg = nil
	
    if pCell == nil then
   		pCell = CGridViewCell:new()
   		pButton = display.newButton( sizee.width*0.5, sizee.height*0.5 ,{n = _res('ui/union/lobby/guild_btn_channel_default'),s = _res('ui/union/lobby/guild_btn_channel_select'),ap = cc.p(0.5, 0.5)})
        pCell:addChild(pButton,5)
		pButton:setOpacity(0)
        pButton:setTag(2345)
        pCell:setContentSize(sizee)
		pButton:setOnClickScriptHandler(handler(self,self.cellCallBackActions))

		nameLabel = display.newLabel(0, pButton:getContentSize().height / 2, {font = TTF_GAME_FONT, ttf = true, fontSize = 22, color = '#793e2e'})
		nameLabel:setTag(123)
		pButton:addChild(nameLabel)

		jewelImg = display.newImageView('', 0, pButton:getContentSize().height / 2)
		jewelImg:setScale(0.6)
		jewelImg:setTag(369)
		pButton:addChild(jewelImg)
		local buttonPos = cc.p(pButton:getPosition())
		pButton:setPosition(cc.p(buttonPos.x -80 ,buttonPos.y  ))
		pButton:runAction(
			cc.Sequence:create(
				cc.DelayTime:create((index -1)*0.1),
				cc.Spawn:create(
					cc.FadeIn:create(0.5),
					cc.EaseBackOut:create(cc.MoveTo:create(0.5 ,buttonPos  ))
				)
			)
		)
    else
    	pButton = pCell:getChildByTag(2345)
    	nameLabel = pButton:getChildByTag(123)
    	jewelImg = pButton:getChildByTag(369)
    end
	xTry(function()
		pCell:setTag(index)
		local gemstoneColor = artiMgr:GetConfigDataByName(parseConfig.TYPE.GEM_STONE_COLOR)

		nameLabel:setString(gemstoneColor[tostring(index)].name)
		jewelImg:setTexture(_res('arts/artifact/equipicon/diamond_icon_0' .. tostring(index) .. '_01'))
		local totalLength = display.getLabelContentSize(nameLabel).width + jewelImg:getContentSize().width * math.abs(jewelImg:getScaleX())
		local centerPos = pButton:getContentSize().width / 2 - 10
		jewelImg:setPositionX(centerPos - totalLength / 2 + jewelImg:getContentSize().width * math.abs(jewelImg:getScaleX()) / 2)
		nameLabel:setPositionX(centerPos + totalLength / 2 - display.getLabelContentSize(nameLabel).width / 2)

		-- display.commonLabelParams(pButton, {font = TTF_GAME_FONT, ttf = true, fontSize = 22, color = '#793e2e',text = gemstoneColor[tostring(index)].name})
    	if self.clickJewelType and self.clickJewelType == index then
    		pButton:setNormalImage(_res('ui/union/lobby/guild_btn_channel_select'))
    	else
    		pButton:setNormalImage(_res('ui/union/lobby/guild_btn_channel_default'))
    	end
	end,__G__TRACKBACK__)
    return pCell
end

--[[
	点击左侧颜色Tab
--]]
function JewelEvolutionMediator:cellCallBackActions(sender)
    local tag = 1
    if type(sender) == 'number' then
		tag = sender
		local typeGridView = self.viewComponent.viewData_.typeGridView
		local cell = typeGridView:cellAtIndex(tag - 1)
		if cell then
			local pButton = cell:getChildByTag(2345)
			if pButton then
				pButton:setNormalImage(_res('ui/union/lobby/guild_btn_channel_select'))
			end
		end
    else
        PlayAudioByClickNormal()
        tag = sender:getParent():getTag()
        sender:setNormalImage(_res('ui/union/lobby/guild_btn_channel_select'))
    end

	if self.clickJewelType and self.clickJewelType == tag then
		return
	end
	if self.clickJewelType then
        local typeGridView = self.viewComponent.viewData_.typeGridView
		local cell = typeGridView:cellAtIndex(self.clickJewelType - 1)
		if cell then
			local pButton = cell:getChildByTag(2345)
			if pButton then
				pButton:setNormalImage(_res('ui/union/lobby/guild_btn_channel_default'))
			end
		end
	end
	self.clickJewelType = tag
	-- self:ResetBatch()
	self:ResetRight()
end

--[[
	宝石仓库数据
--]]
function JewelEvolutionMediator:OnDataSourceAction( p_convertview,idx )
	local pCell = p_convertview
    local index = idx + 1
	local sizee = cc.size(112, 113)
	if pCell == nil then
		pCell = BackpackCell.new(sizee)
		--pCell.eventnode:setScaleX(0)
		pCell.toggleView:setOnClickScriptHandler(handler(self,self.CellButtonAction))
		pCell.selectImg:setLocalZOrder(2)
		pCell.selectImg:setScale(0.95)
		if index <= 20 and self.isFirst == 1 then
			pCell.eventnode:setOpacity(0)
			pCell.eventnode:setPositionY(sizee.height - 800)
			pCell.eventnode:runAction(
				cc.Sequence:create(cc.DelayTime:create(index * 0.02),
					 cc.Spawn:create(
						 cc.FadeIn:create(0.4),
						 cc.EaseSineOut:create( cc.JumpTo:create(0.4, cc.p(sizee.width* 0.5,sizee.height * 0.5), 0 ,1))
					 )
				)
			)
		else
			pCell.eventnode:setPosition(cc.p(sizee.width* 0.5,sizee.height * 0.5))
		end
		--pCell.eventnode
	end
	xTry(function()
		pCell.maskImg:setVisible(false)
		if 10 == self.jewelsSpecificData[index].grade then
			pCell.maskImg:setVisible(true)
		elseif 1 == self.chooseModel then	--随机合成
			if next(self.chooseData) then
				for k,v in pairs(self.chooseData) do
					pCell.maskImg:setVisible(self.jewelsSpecificData[index].grade ~= v.grade)
					break
				end
			end
		end
		pCell.levelBg:setVisible(true)
		pCell.levelLabel:setString(self.jewelsSpecificData[index].grade)
		pCell.selectImg:setVisible(false)
		pCell.toggleView:setTag(index)
		pCell.numLabel:setString(tostring(self.jewelsSpecificData[index].amount))
		pCell.goodsImg:setVisible(true)
		local node = pCell.goodsImg
		local goodsId = self.jewelsSpecificData[index].goodsId
		local iconPath = CommonUtils.GetGoodsIconPathById(goodsId)
		node:setTexture(_res(iconPath))

		local bgPath = string.format('ui/common/common_frame_goods_%d.png', checkint(self.jewelsSpecificData[index].quality or 1))
		pCell.toggleView:setNormalImage(_res(bgPath))
		pCell.toggleView:setSelectedImage(_res(bgPath))

		if self.isBatch then
			pCell.checkBox:setNormalImage(_res('ui/common/gut_task_ico_select.png'))
			pCell.checkBox:setVisible(true)
		else
			pCell.checkBox:setVisible(false)
		end
		for k,v in pairs(self.chooseData) do
			if v.goodsId == goodsId then
				pCell.selectImg:setVisible(true)
				if self.isBatch then
					pCell.checkBox:setNormalImage(_res('ui/common/gut_task_ico_hook.png'))
				end
				break
			end
		end
	end,__G__TRACKBACK__)
	return pCell
end

--[[
	宝石cell点击
--]]
function JewelEvolutionMediator:CellButtonAction( sender )
	PlayAudioByClickNormal()
	local index = sender:getTag()
	local viewData = self.viewComponent.viewData_
	local gridView = viewData.gridView

	local cellData = self.jewelsSpecificData[index]
	if 10 == cellData.grade then
		uiMgr:ShowInformationTips(__('这个塔可已经达到极限了，为什么不试试其它塔可呢'))
		return 
	end
	if self.isBatch then -- 批量合成
		--更新按钮状态
		local cell = gridView:cellAtIndex(index - 1)
		for k, v in pairs(self.chooseData) do
			if cellData.grade ~= v.grade then
				uiMgr:ShowInformationTips(__('也许有些不合适'))
				return 
			end
			if v.goodsId == cellData.goodsId then --取消选择
				cell.checkBox:setNormalImage(_res('ui/common/gut_task_ico_select.png'))
				table.remove(self.chooseData, k)
				cell.selectImg:setVisible(false)
				self:SetGridviewReload(true)
				if next(self.chooseData) then
					viewData.targetCell.levelBg:setVisible(true)
					viewData.targetCell.levelLabel:setString(cellData.grade + 1)
					viewData.targetCell.goodsImg:setScale(1)
					viewData.targetCell.goodsImg:setVisible(true)
					viewData.targetCell.goodsImg:setTexture(_res('ui/common/compose_ico_unkown.png'))
					local cnt = 0
					for k,v in pairs(self.chooseData) do
						cnt = cnt + v.amount
					end
					local geneCnt = math.floor(cnt / 3)
					viewData.targetCell.numLabel:setString(geneCnt)
					self:setEvolBtnGray(geneCnt < 1)
				else
					viewData.targetCell.toggleView:setNormalImage(_res('ui/common/common_frame_goods_1.png'))
					viewData.targetCell.toggleView:setSelectedImage(_res('ui/common/common_frame_goods_1.png'))
					viewData.targetCell.levelBg:setVisible(false)
					viewData.targetCell.numLabel:setString('')
					viewData.targetCell.goodsImg:setVisible(false)
					viewData.targetCell.goodsImg:setScale(0.55)
					self:setEvolBtnGray(true)
				end
				return 
			end
		end
		cell.selectImg:setVisible(true)
		table.insert(self.chooseData, cellData)
		cell.checkBox:setNormalImage(_res('ui/common/gut_task_ico_hook.png'))
		self:SetGridviewReload(true)
		viewData.targetCell.levelBg:setVisible(true)
		viewData.targetCell.levelLabel:setString(cellData.grade + 1)
		viewData.targetCell.goodsImg:setVisible(true)
		viewData.targetCell.goodsImg:setScale(1)
		viewData.targetCell.goodsImg:setTexture(_res('ui/common/compose_ico_unkown.png'))
		local cnt = 0
		for k,v in pairs(self.chooseData) do
			cnt = cnt + v.amount
		end
		local geneCnt = math.floor(cnt / 3)
		viewData.targetCell.numLabel:setString(geneCnt)

		local goodData = CommonUtils.GetConfig('goods', 'goods', cellData.goodsId + 1) or {}
		local bgPath = string.format('ui/common/common_frame_goods_%d.png', checkint(goodData.quality or 1))
		viewData.targetCell.toggleView:setNormalImage(_res(bgPath))
		viewData.targetCell.toggleView:setSelectedImage(_res(bgPath))
		
		self:setEvolBtnGray(geneCnt < 1)
		return 
	end
	--更新按钮状态
	local cell = gridView:cellAtIndex(index - 1)
	local tempIndex = 0
	if 1 == self.chooseModel then	--随机合成
		if EVOLUTION_COST == table.nums(self.chooseData) then
			uiMgr:ShowInformationTips(__('满了，满了，满了，快快合成吧'))
			return
		end
		if next(self.chooseData) then
			for k,v in pairs(self.chooseData) do
				if cellData.grade ~= v.grade then
					uiMgr:ShowInformationTips(__('也许有些不合适'))
					return 
				end
				break
			end
		end
		if 0 < cellData.amount then
			cellData.amount = cellData.amount - 1
			cell.numLabel:setString(tostring(cellData.amount))
		else
			uiMgr:ShowInformationTips(__('再点也没有了'))
			return 
		end
		for i=1,EVOLUTION_COST do
			if not self.chooseData[tostring(i)] then
				tempIndex = i
				break
			end
		end
		cell.selectImg:setVisible(true)
	else	--特定合成
		if cell then
			cell.selectImg:setVisible(true)
		end
		tempIndex = 1
		if self.chooseData[tostring(tempIndex)] then
			local pcell = viewData.Tcells[tempIndex]
			local preIndex = pcell.toggleView:getUserTag()
			local preCell = gridView:cellAtIndex(preIndex - 1)
			if preIndex == index then
				uiMgr:ShowInformationTips(__('已经选中了这个塔可'))
				return 
			end
			if preCell then
				preCell.selectImg:setVisible(false)
			end
		end
		self.selectNum = 1
		viewData.purchaseNum:setString(tostring(self.selectNum))
		local pcell = viewData.Tcells[tempIndex]
		pcell.numLabel:setString('/' .. (self.selectNum * EVOLUTION_COST))
		pcell.hasNumLabel:setString(cellData.amount)
		pcell.hasNumLabel:setPositionX(pcell.numLabel:getPositionX() - pcell.numLabel:getContentSize().width + 4)
		if (self.selectNum * EVOLUTION_COST) <= cellData.amount then
			pcell.hasNumLabel:setBMFontFilePath('font/small/common_text_num.fnt')
			self:setEvolBtnGray(false)
		else
			pcell.hasNumLabel:setBMFontFilePath('font/small/common_num_unused.fnt')
			self:setEvolBtnGray(true)
		end
		local targetCell = viewData.targetCell
		local targetGoodsId = checkint(cellData.goodsId) + 1
		local iconPath = CommonUtils.GetGoodsIconPathById(targetGoodsId)
		targetCell.goodsImg:setTexture(_res(iconPath))
		targetCell.goodsImg:setScale(0.55)
		targetCell.goodsImg:setVisible(true)
		viewData.goodLayer:setVisible(true)
		targetCell.numLabel:setString(tostring(self.selectNum))
		targetCell.levelBg:setVisible(true)
		targetCell.levelLabel:setString(cellData.grade + 1)
		local bgPath = string.format('ui/common/common_frame_goods_%d.png', checkint(cellData.quality or 1))
		targetCell.toggleView:setNormalImage(_res(bgPath))
		targetCell.toggleView:setSelectedImage(_res(bgPath))
	end
	self.chooseData[tostring(tempIndex)] = clone(cellData)
	local cell = viewData.Tcells[tempIndex]
	cell.toggleView:setTag(tempIndex)
	cell.toggleView:setUserTag(index)

	local bgPath = string.format('ui/common/common_frame_goods_%d.png', checkint(cellData.quality or 1))
	cell.toggleView:setNormalImage(_res(bgPath))
	cell.toggleView:setSelectedImage(_res(bgPath))

	cell.levelBg:setVisible(true)
	cell.levelLabel:setString(cellData.grade)
	-- cell.toggleView:setNormalImage(_res('ui/common/common_frame_goods_'..tostring(1)..'.png'))
	-- cell.toggleView:setSelectedImage(_res('ui/common/common_frame_goods_'..tostring(1)..'.png'))

	local iconPath = CommonUtils.GetGoodsIconPathById(cellData.goodsId)
	cell.goodsImg:setTexture(_res(iconPath))
	cell.goodsImg:setVisible(true)

	viewData.Tarrows[tempIndex]:clearFilter()

	if 1 == self.chooseModel then	--随机合成
		if EVOLUTION_COST == table.nums(self.chooseData) then
			viewData.targetCell.levelBg:setVisible(true)
			viewData.targetCell.levelLabel:setString(self.chooseData[tostring(1)].grade + 1)

			local goodData = CommonUtils.GetConfig('goods', 'goods', cellData.goodsId + 1) or {}
			local bgPath = string.format('ui/common/common_frame_goods_%d.png', checkint(goodData.quality or 1))
			viewData.targetCell.toggleView:setNormalImage(_res(bgPath))
			viewData.targetCell.toggleView:setSelectedImage(_res(bgPath))
			
			viewData.targetCell.goodsImg:setScale(1)
			viewData.targetCell.goodsImg:setVisible(true)
			viewData.targetCell.goodsImg:setTexture(_res('ui/common/compose_ico_unkown.png'))
			self:setEvolBtnGray(false)
		end
		self:SetGridviewReload(true)
	end
end

--[[
	法阵上已选择的宝石点击回调
--]]
function JewelEvolutionMediator:ButtonActions( sender )
	local index = sender:getTag()
	
	if not self.chooseData[tostring(index)] then
		return 
	end
	PlayAudioByClickNormal()
	local viewData = self.viewComponent.viewData_
	local cell = viewData.Tcells[index]
	cell.goodsImg:setVisible(false)
	cell.toggleView:setNormalImage(_res('ui/common/common_frame_goods_1.png'))
	cell.toggleView:setSelectedImage(_res('ui/common/common_frame_goods_1.png'))
	cell.levelBg:setVisible(false)
	cell.numLabel:setString('')
	cell.hasNumLabel:setString('')
	-- cell.toggleView:setNormalImage(_res('ui/common/compose_frame_unused.png'))
	-- cell.toggleView:setSelectedImage(_res('ui/common/compose_frame_unused.png'))

	local targetCell = viewData.targetCell
	viewData.targetCell.goodsImg:setScale(0.55)
	targetCell.goodsImg:setVisible(false)
	targetCell.numLabel:setString('')
	targetCell.levelBg:setVisible(false)
	targetCell.toggleView:setNormalImage(_res('ui/common/common_frame_goods_1.png'))
	targetCell.toggleView:setSelectedImage(_res('ui/common/common_frame_goods_1.png'))
	viewData.goodLayer:setVisible(false)
	self:setEvolBtnGray(true)

	self.chooseData[tostring(index)] = nil
	viewData.Tarrows[index]:setFilter(GrayFilter:create())

	local viewData = self.viewComponent.viewData_
	local gridView = viewData.gridView
	local index = sender:getUserTag()
	local cell = gridView:cellAtIndex(index - 1)
	if 1 == self.chooseModel then	--随机合成
		local cellData = self.jewelsSpecificData[index]
		cellData.amount = cellData.amount + 1
		if cell then
			cell.numLabel:setString(tostring(cellData.amount))
		end
		for k,v in pairs(self.chooseData) do
			if v.goodsId == cellData.goodsId then
				return 
			end
		end
		if not next(self.chooseData) then
			self:SetGridviewReload(true)
		end
	end
	if cell then
		cell.selectImg:setVisible(false)
	end
end

--[[
	点击目标cell显示介绍
--]]
function JewelEvolutionMediator:TargetCellButtonAction( sender )
	if 1 ~= self.chooseModel then
		local viewData = self.viewComponent.viewData_
		local targetCell = viewData.targetCell
		if targetCell.goodsImg:isVisible() then
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = self.chooseData['1'].goodsId + 1, type = 1})
		end
	end
end

--[[
	重置批量选择按钮
--]]
function JewelEvolutionMediator:ResetBatch(  )
	self.isBatch = false
	local viewData = self.viewComponent.viewData_
	local batchButton = viewData.batchButton
	batchButton:setChecked(false)
	local label = batchButton:getChildByTag(1)
	label:setString(__('批量选择'))
end

--[[
	重置宝石仓库列表 法阵页面
	@params isSetPreOffset 重载gridview时是否维持原来的offset
--]]
function JewelEvolutionMediator:ResetRight( isSetPreOffset )
	local viewData = self.viewComponent.viewData_
	self.jewelsSpecificData = clone(self.jewelsData[tostring(self.clickJewelType)])

	self.chooseData = {}
	self.selectNum = 1
	for k, v in pairs(viewData.Tcells) do
		v.goodsImg:setVisible(false)
		v.levelBg:setVisible(false)
		v.numLabel:setString('')
		v.hasNumLabel:setString('')
		if self.isBatch then
			v.toggleView:setNormalImage(_res('ui/common/compose_frame_unused.png'))
			v.toggleView:setSelectedImage(_res('ui/common/compose_frame_unused.png'))
		else
			v.toggleView:setNormalImage(_res('ui/common/common_frame_goods_1.png'))
			v.toggleView:setSelectedImage(_res('ui/common/common_frame_goods_1.png'))
		end
	
		viewData.Tarrows[k]:setFilter(GrayFilter:create())
	end
	viewData.Tcells[2]:setVisible(1 == self.chooseModel)
	viewData.Tcells[3]:setVisible(1 == self.chooseModel)
	viewData.Tarrows[2]:setVisible(1 == self.chooseModel)
	viewData.Tarrows[3]:setVisible(1 == self.chooseModel)
	viewData.targetCell.goodsImg:setVisible(false)
	viewData.targetCell.goodsImg:setScale(0.55)
	viewData.targetCell.levelBg:setVisible(false)
	viewData.targetCell.numLabel:setString('')
	viewData.targetCell.toggleView:setNormalImage(_res('ui/common/common_frame_goods_1.png'))
	viewData.targetCell.toggleView:setSelectedImage(_res('ui/common/common_frame_goods_1.png'))
	viewData.goodLayer:setVisible(false)

	local gridView = viewData.gridView
	gridView:setCountOfCell(table.nums(self.jewelsSpecificData))
	self:SetGridviewReload(isSetPreOffset)
	
	viewData.kongBg:setVisible(0 == table.nums(self.jewelsSpecificData))
	self:setEvolBtnGray(true)
end

function JewelEvolutionMediator:setEvolBtnGray( isGray )
	local viewData = self.viewComponent.viewData_
	local evolutionBtn = viewData.evolutionBtn
	if isGray then
		evolutionBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
		evolutionBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
	else
		evolutionBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
		evolutionBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
	end
end

--[[
	重载gridview
	@params isSetPreOffset 是否维持原来的offset
--]]
function JewelEvolutionMediator:SetGridviewReload( isSetPreOffset )
	local viewData = self.viewComponent.viewData_
	local gridView = viewData.gridView
	local gridContentOffset = gridView:getContentOffset()
	self.isFirst = self.isFirst + 1
	gridView:reloadData()
	if isSetPreOffset then
		gridContentOffset = self:returnsetContentOffset(gridContentOffset,gridView:getContentSize(),gridView:getContainerSize())
		gridView:setContentOffset(gridContentOffset)
	end
end

--[[
	第一个是移动的距离，容量大小，第三个是内容大小
--]]
function JewelEvolutionMediator:returnsetContentOffset(point,contentSize,containerSize)
	if math.abs(point.y) + contentSize.height > containerSize.height then
		return cc.p(0,contentSize.height - containerSize.height)
	else
		return point
	end
end

function JewelEvolutionMediator:OnRegist(  )
	regPost(POST.ARTIFACT_GEM_FUSION)
end
function JewelEvolutionMediator:OnUnRegist(  )
	unregPost(POST.ARTIFACT_GEM_FUSION)

	local scene = uiMgr:GetCurrentScene()
	if self.viewComponent and (not tolua.isnull(self.viewComponent)) then
		self.viewComponent:stopAllActions()
		scene:RemoveGameLayer(self.viewComponent)
		self.viewComponent = nil
	end

end


return JewelEvolutionMediator
