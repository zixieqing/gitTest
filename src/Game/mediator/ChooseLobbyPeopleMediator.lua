--[[
选择大堂人员。主管，厨师。服务员 钓手
--]]
local Mediator = mvc.Mediator

local ChooseLobbyPeopleMediator = class("ChooseLobbyPeopleMediator", Mediator)

local NAME = "ChooseLobbyPeopleMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
function ChooseLobbyPeopleMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	if params then
		self.chooseType = params.chooseType or 1  -- 1：主管  2：厨师 3：服务员 4：钓手 5：包厢
		self.callback = params.callback or nil
		self.employeeId = params.employeeId
		self.showActionState = true
	end
	self.hideSkill = (self.chooseType == 4)

	self.chooseCardId = nil
	if self.chooseType == 1 then
		self.chooseCardId = gameMgr:GetUserInfo().supervisor[tostring(self.employeeId)]
	elseif self.chooseType == 2 then
		self.chooseCardId = gameMgr:GetUserInfo().chef[tostring(self.employeeId)]
	elseif self.chooseType == 3 then
		self.chooseCardId = gameMgr:GetUserInfo().waiter[tostring(self.employeeId)]
	elseif self.chooseType == 4 then
		if params.friendFish then
			self.chooseCardId = params.friendFish.cardId
		elseif params.card then
			if params.card.cardId then
				self.chooseCardId = params.card.cardId
			else
				self.chooseCardId = gameMgr:GetCardDataById(params.card.playerCardId).cardId
			end
		end
	elseif self.chooseType == 5 then
		self.showActionState = false
		self.from = 2
		self.moduleId = CARD_BUSINESS_SKILL_MODEL_PRIVATEROOM
	end

	if gameMgr:GetCardDataById(self.chooseCardId) and self.chooseType ~= 4 then
		self.chooseCardId = gameMgr:GetCardDataById(self.chooseCardId).cardId
	end

	self.cellClickTag = 1
	self.cellClickImg = nil
	self.skilCellClickTag = 0
	self.skillData = {}
end


function ChooseLobbyPeopleMediator:InterestSignals()
	local signals = {
	}
	return signals
end

function ChooseLobbyPeopleMediator:ProcessSignal(signal )
	local name = signal:GetName()
	local data = signal:GetBody()
end


function ChooseLobbyPeopleMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent = require( 'Game.views.ChooseLobbyPeopleView' ).new({hideSkill = self.hideSkill})
	self:SetViewComponent(viewComponent)
	-- viewComponent:setName('Game.views.ChooseLobbyPeopleView')
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	-- scene:AddGameLayer(viewComponent)
	-- scene:addChild(viewComponent)

	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	self.viewData = viewComponent.viewData

	local gridView = viewData.gridView
	gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))

	viewData.chooseCardBtn:setOnClickScriptHandler(handler(self,self.ChooseCardButtonActions))
	for i,v in ipairs(viewData.buttons) do
		v:setOnClickScriptHandler(handler(self,self.SkillDetailBtnActions))
	end
	self.Tdata = {}
	if not self.hideSkill then
		local Tdata = {}
 		local tempData = {}
 		local McardsData = {}
 		local RcardsData = {}
		for name,val in orderedPairs(gameMgr:GetUserInfo().cards) do
			local cardData = CommonUtils.GetConfig('cards', 'card', val.cardId)
			local qualityId = 1
			if cardData then
				qualityId = checkint(cardData.qualityId)
			end
			val.qualityId = qualityId

			if checkint(self.chooseCardId) == checkint(val.cardId) then
				tempData = val
			else
				if checkint(qualityId) == 1 then
					table.insert(McardsData,val)
				elseif checkint(qualityId) == 2 then
					table.insert(RcardsData,val)
				else
					table.insert(Tdata,val)
				end

			end
		end
		--排序规则： M卡>R卡有技能的>其他卡R卡>SR>UR
		self.Tdata = clone(Tdata)

		sortByMember(self.Tdata, "qualityId", true)
		for i,v in ipairs(RcardsData) do
			if next(CommonUtils.GetBusinessSkillByCardId(v.cardId, {from = self.from, moduleId = self.moduleId})) ~= nil then
				v.hasSkill = 2
			else
				v.hasSkill = 1
			end
		end
		sortByMember(RcardsData, "hasSkill", true)

		for i,v in ipairs(RcardsData) do
			table.insert(self.Tdata,1,v)
		end

		for i,v in ipairs(McardsData) do
			table.insert(self.Tdata,1,v)
		end

		--将当前装备的卡牌置为第一位
		if table.nums(tempData) > 0 then
			table.insert(self.Tdata,1,tempData)
		end
	else
		local chooseCardData = nil
		for k,v in orderedPairs(gameMgr:GetUserInfo().cards) do
			local cardData = CommonUtils.GetConfig('cards', 'card', v.cardId)
			local qualityId = 1
			if cardData then
				qualityId = checkint(cardData.qualityId)
			end
			v.qualityId = qualityId
			if checkint(self.chooseCardId) == checkint(v.cardId) then
				chooseCardData = v
			else
				table.insert( self.Tdata, v )
			end
		end
		sortByMember(self.Tdata, "qualityId", true)
		if chooseCardData then table.insert( self.Tdata, 1, chooseCardData ) end
	end
 	

	gridView:setCountOfCell(table.nums(self.Tdata))
	gridView:reloadData()

	self:UpdataUI(self.Tdata[1])
end


function ChooseLobbyPeopleMediator:UpdataUI(data)
    if tolua.isnull(self.viewComponent) then return end
	local clickCardNode = self.viewData.clickCardNode--选中头像
	local nameLabel = self.viewData.nameLabel--名字
	local operaProgressBar = self.viewData.operaProgressBar--新鲜度叶子
	local vigourLabel = self.viewData.vigourLabel--新鲜度数字
	local chooseCardBtn = self.viewData.chooseCardBtn--
	local dialogue_tips = self.viewData.dialogue_tips--

	if data then
		local cardId = checkint(data.cardId)
		local breakLevel = checkint(data.breakLevel)
		local level = checkint(data.level)
		local vigour = checkint(data.vigour)
		local cardConf = CommonUtils.GetConfig('cards', 'card', cardId) or {}
		-- nameLabel:setString(tostring(cardConf.name))
		nameLabel:setString(CommonUtils.GetCardNameById(data.id))
		vigourLabel:setString(vigour)
        local maxVigour = app.restaurantMgr:getCardVigourLimit(data.id)
        local ratio = (vigour / maxVigour) * 100
		operaProgressBar:setValue(ratio)
		if data.id then
			local x , y =  clickCardNode:getPosition()
			clickCardNode:removeFromParent()
			local clickCardNode = require('common.CardHeadNode').new({
				showActionState = self.showActionState,
																		 id = data.id })
			clickCardNode:setScale(0.73)
			clickCardNode:setPosition(cc.p(x , y ))
			self.viewData.clickCardNode = clickCardNode
			self.viewData.cview:addChild(clickCardNode)
			clickCardNode:setName('clickCardNode')
		else
			clickCardNode:RefreshUI({
				cardData = {cardId = cardId,level  = level,breakLevel = breakLevel},
				showActionState = self.showActionState
			})
		end
		if checkint(self.chooseCardId) == checkint(cardId) then
			chooseCardBtn:getLabel():setString(__('换下'))
		else
			if not self.chooseCardId then
				chooseCardBtn:getLabel():setString(__('雇佣'))
			else
				chooseCardBtn:getLabel():setString(__('替换'))
			end
		end

		local HeroId = 0
		local businessModule = 1
		if self.clickTag == 1001 then
			HeroId = self.KitchenAssistantId
			businessModule = 1
		elseif self.clickTag == 1002 then
			HeroId = self.TakeAwayAssistantId
			businessModule = 3
		elseif self.clickTag == 1003 then
			HeroId = self.LobbyAssistantId
			businessModule = 2
		end
		-- 筛选buff效果
		local tempSkill = {}
		self.skillData = {}
		tempSkill = CommonUtils.GetBusinessSkillByCardId(cardId, {from = self.from, moduleId = self.moduleId})
		if tempSkill and not self.hideSkill then
			local t = {'manager','chef','waiter', 'vipwaiter'}
			self.skillData = tempSkill
			dialogue_tips:setVisible(false)
			for i,v in ipairs(self.viewData.buttons) do
				local tabNameLabel = v:getChildByTag(5)
				local tabLvLabel = v:getChildByTag(6)
				local skillImg = v:getChildByTag(7)
				local unlockLabel = v:getChildByTag(8)
				if tempSkill[i] then
					v:setVisible(true)
					v:setEnabled(true)
					tabNameLabel:setString(tempSkill[i].name)
					tabLvLabel:setVisible(false)
					if tempSkill[i].unlock == 0 then
						v:setEnabled(false)
						v:setChecked(true)
						unlockLabel:setString(__('暂未解锁'))
						local grayFilter = GrayFilter:create()
						skillImg:setFilter(grayFilter)
						v:setNormalImage(_res('ui/home/lobby/peopleManage/restaurant_recharge_btn_skill_disabled.png'))
					else
						unlockLabel:setString((' '))
						skillImg:clearFilter()
						v:setNormalImage(_res('ui/home/lobby/peopleManage/restaurant_recharge_btn_skill_default.png'))
					end
					skillImg:setTexture(_res(CommonUtils.GetSkillIconPath(tempSkill[i].skillId)))
					for j=1,4 do
						local typeImg = v:getChildByTag(j+10)
						if tempSkill[i].employee[j] and t[checkint(checktable(tempSkill[i]).employee[j])] then
							typeImg:setVisible(true)
                            typeImg:setTexture(_res('ui/home/lobby/peopleManage/restaurant_manage_ico_'..t[checkint(tempSkill[i].employee[j])]..'.png'))
						else
							typeImg:setVisible(false)
						end

						if tempSkill[i].unlock == 0 then
							local grayFilter = GrayFilter:create()
	        				typeImg:setFilter(grayFilter)
						else
							typeImg:clearFilter()
						end
					end
				else
					v:setVisible(false)
				end
				display.commonLabelParams(tabNameLabel , {reqW = 160})
			end
		else
			for i,v in ipairs(self.viewData.buttons) do
				v:setVisible(false)
			end
			dialogue_tips:setVisible(not self.hideSkill)
		end
	end
end


function ChooseLobbyPeopleMediator:HeadCallback(sender)
    PlayAudioByClickNormal()
	local tag = sender:getParent():getTag()
	if self.cellClickImg then
		self.cellClickImg:setVisible(false)
	end
	local selectImg = sender:getParent():getChildByTag(2346)
	selectImg:setVisible(true)
	self.cellClickTag = tag
	self.cellClickImg = selectImg
	self:UpdataUI(self.Tdata[tag])

	for i,v in ipairs(self.viewData.buttons) do
		v:setChecked(false)
	end

	local skillDesView = self.viewData.skillDesView
	if skillDesView then skillDesView:setVisible(false) end

	self.skilCellClickTag = 0
	GuideUtils.DispatchStepEvent()
end

function ChooseLobbyPeopleMediator:OnDataSourceAction(c, i)
	local cell = c
	local index = i + 1
	local cardHeadNode = nil
	local selectImg = nil
	local id = checkint(self.Tdata[index].id)
	xTry(function()
		local showActionState = self.showActionState
        if nil == cell then
            cell = CGridViewCell:new()
            cell:setContentSize(self.viewData.gridView:getSizeOfCell())

            cardHeadNode = require('common.CardHeadNode').new({id = checkint(id), showActionState = showActionState})
            cardHeadNode:setScale(0.73)
            cardHeadNode:setPosition(utils.getLocalCenter(cell))
            cardHeadNode:setOnClickScriptHandler(handler(self,self.HeadCallback))
            cell:addChild(cardHeadNode)
            cardHeadNode:setTag(2345)
            cardHeadNode:setName('cardHeadNode_'..index)
            selectImg = display.newImageView(_res('ui/common/common_bg_frame_goods_elected.png'),0,0,{as = false})
            selectImg:setScale(1.2)
            selectImg:setPosition(utils.getLocalCenter(cell))
            cell:addChild(selectImg,1)
            selectImg:setVisible(false)
            selectImg:setTag(2346)
            -- clickImg
        else
            cardHeadNode = cell:getChildByTag(2345)
            cardHeadNode:setName('cardHeadNode_'..index)
            selectImg = cell:getChildByTag(2346)
            selectImg:setVisible(false)
            cardHeadNode:RefreshUI({id = checkint(id), showActionState = showActionState})
        end
        if index == self.cellClickTag then
            selectImg:setVisible(true)
            self.cellClickImg = selectImg
        end

        cell:setTag(index)

    end,__G__TRACKBACK__)
    if cell == nil then
        cell = CGridViewCell:new()
    end
	return cell
end

--替换按钮
function ChooseLobbyPeopleMediator:ChooseCardButtonActions( sender )
    PlayAudioByClickNormal()
    sender:setEnabled(false)
    transition.execute(sender,cc.Sequence:create(
            cc.DelayTime:create(0.5),
            cc.CallFunc:create(function()
                if sender and not tolua.isnull(sender) then
                    sender:setEnabled(true)
                end
            end)
        ))
    local tag = sender:getTag()
    -- dump(tag)
    -- dump(self.Tdata[self.cellClickTag])
    local id = self.Tdata[self.cellClickTag].id
    if checkint(self.chooseCardId) == checkint(self.Tdata[self.cellClickTag].cardId) then
        --卸下操作
        local places = gameMgr:GetCardPlace({id = id})
        local scene = uiMgr:GetCurrentScene()
        if places and table.nums(places) > 0 then
            if places[tostring(CARDPLACE.PLACE_TEAM)] then
                local temp_str = __('确定将该飨灵放入该职位？')
				local CommonTip  = require( 'common.CommonTip' ).new({descr = __('该飨灵已经在编队中，是否将其移至当前职位。'),text = temp_str,isOnlyOK = false, callback = function ()
					if self.callback then
						self.callback(self.Tdata[self.cellClickTag])
					end
				end})
				CommonTip:setPosition(display.center)
				scene:AddDialog(CommonTip)
            elseif places[tostring(CARDPLACE.PLACE_ASSISTANT)] then
                local id = gameMgr:GetCardDataById(self.chooseCardId).id
                if checkint(self.Tdata[self.cellClickTag].cardId) == checkint(self.chooseCardId) then
                    if self.callback then
                        self.callback(self.Tdata[self.cellClickTag])
                    end
                else
                    uiMgr:ShowInformationTips(__('该飨灵已经在大堂工作。'))
                end
            else
                --非编队中的数据
                local keys = table.keys(places)
                local temp_str = __('确定换下该飨灵？')
                local a,b,temp_descr = gameMgr:GetModuleName(keys[1])
                local CommonTip  = require( 'common.CommonTip' ).new({text = temp_str,isOnlyOK = false, callback = function ()
                    if self.callback then
                        self.callback(self.Tdata[self.cellClickTag])
                    end
                end})
                CommonTip:setPosition(display.center)
                scene:AddDialog(CommonTip)
            end
        else
            --不在任何状态
            if self.callback then
                self.callback(self.Tdata[self.cellClickTag])
            end
        end
	else
		-- 包厢不存在互斥状态
		if self.chooseType == 5 then
            --不在任何状态
            if self.callback then
                self.callback(self.Tdata[self.cellClickTag])
            end
			return 
		end
        if gameMgr:CanSwitchCardStatus({id = id}, CARDPLACE.PLACE_ASSISTANT) then
            local places = gameMgr:GetCardPlace({id = id})
            local scene = uiMgr:GetCurrentScene()
            if places and table.nums(places) > 0 then
                if places[tostring(CARDPLACE.PLACE_TEAM)] then
                    local temp_str = __('确定将该飨灵放入该职位？')
                    local CommonTip  = require( 'common.CommonTip' ).new({descr = __('该飨灵已经在编队中，是否将其移至当前职位。'),text = temp_str,isOnlyOK = false, callback = function ()
                        if self.callback then
                            self.callback(self.Tdata[self.cellClickTag])
                        end
                    end})
                    CommonTip:setPosition(display.center)
                    scene:AddDialog(CommonTip)
                elseif places[tostring(CARDPLACE.PLACE_ASSISTANT)] then
                    local id = gameMgr:GetCardDataById(self.chooseCardId).id
                    if checkint(self.Tdata[self.cellClickTag].cardId) == checkint(self.chooseCardId) then
                        if self.callback then
                            self.callback(self.Tdata[self.cellClickTag])
                        end
                    else
                        uiMgr:ShowInformationTips(__('该飨灵已经在大堂工作。'))
                    end
                else
                    --非编队中的数据
                    local keys = table.keys(places)
                    local temp_str = __('确定将该飨灵放入职位？')
                    local a,b,temp_descr = gameMgr:GetModuleName(keys[1])
                    local CommonTip  = require( 'common.CommonTip' ).new({descr = temp_descr,text = temp_str,isOnlyOK = false, callback = function ()
                        print(temp_str)
                        if self.callback then
                            self.callback(self.Tdata[self.cellClickTag])
                        end
                    end})
                    CommonTip:setPosition(display.center)
                    scene:AddDialog(CommonTip)
                end
            else
                --不在任何状态
                if self.callback then
                    self.callback(self.Tdata[self.cellClickTag])
                end
            end
        else
            local places = gameMgr:GetCardPlace({id = id})
            if places[tostring(CARDPLACE.PLACE_TAKEAWAY)] then
                uiMgr:ShowInformationTips(__('该飨灵正在配送外卖中。'))
            -- elseif places[tostring(CARDPLACE.PLACE_EXPLORATION)] then
			-- 	uiMgr:ShowInformationTips(__('该飨灵正在探索中。'))
			-- elseif places[tostring(CARDPLACE.PLACE_EXPLORE_SYSTEM)] then
            --     uiMgr:ShowInformationTips(__('该飨灵正在探索中。'))
            elseif places[tostring(CARDPLACE.PLACE_ASSISTANT)] then
                uiMgr:ShowInformationTips(__('该飨灵已经在大堂工作。'))
			elseif places[tostring(CARDPLACE.PLACE_FISH_PLACE)] then
				uiMgr:ShowInformationTips(__('该飨灵正在垂钓中。'))
            end
        end
    end
end

--技能详情按钮
function ChooseLobbyPeopleMediator:SkillDetailBtnActions( sender )
    PlayAudioByClickNormal()
	for i,v in ipairs(self.viewData.buttons) do
		v:setChecked(false)
	end
	local tag = sender:getTag()
	sender:setChecked(true)
	if self.skilCellClickTag == tag then
		return
	end
	local btn = self.viewData.buttons[tag]
	local skillDesView = self.viewData.skillDesView
	local desLabel = self.viewData.desLabel
	skillDesView:setVisible(true)
	skillDesView:setPosition(cc.p(btn:getPositionX()+175,btn:getPositionY()+40))
	desLabel:setString(self.skillData[tag].descr)
	local typeLabel = self.viewData.typeLabel

	local t = {__('主管'),__('厨师'),__('服务员'), __('包厢服务员')}
	local str = ''
	for j=1,4 do
		if self.skillData[tag].employee[j] then
			if j == table.nums(self.skillData[tag].employee) then
				str = str..t[checkint(self.skillData[tag].employee[j])]
			else
				str = str..t[checkint(self.skillData[tag].employee[j])]..','
			end
		end
	end
    if str ~= '' then
        typeLabel:setString(string.fmt(__('适用职业：_value_'),{_value_ = str}))
    end
	self.skilCellClickTag = tag
end


function ChooseLobbyPeopleMediator:OnRegist(  )
end

function ChooseLobbyPeopleMediator:OnUnRegist(  )
	--称出命令
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return ChooseLobbyPeopleMediator
