--[[
大堂人员管理UI
--]]
local Mediator = mvc.Mediator

local LobbyPeopleManagementMediator = class("LobbyPeopleManagementMediator", Mediator)

local NAME = "LobbyPeopleManagementMediator"
local socketMgr = AppFacade.GetInstance():GetManager('SocketManager')
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
function LobbyPeopleManagementMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
    self.isGuideDispatched = false --是否已分发引导步骤
	self.chooseType = 0--选择类型1：主管。2：厨师。3：服务员
	self.index = 1--选择第几个坑
	self.choseData = {}
	self.TsupervisorMess = {}
	self.TcookerMess = {}
	self.TwaiterMess = {}
	self.unlockMess = {}
	self.isDown = false
	if params.employee then
		self.employee = params.employee
		-- dump(params.employee)
		for i,v in ipairs(params.employee) do
			self.unlockMess[tostring(v)] = v
		end
	end
	self.recipeCooking = params.recipeCooking or {}


	self.waitersTimeMess = params.waiter or {}

	self.TwaiterSwitchTimeUpdateFunc = {} -- 更换剩余秒数table
end


function LobbyPeopleManagementMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Lobby_EmployeeSwitch_Callback,
		SIGNALNAMES.Lobby_EmployeeUnlock_Callback,
	}

	return signals
end

function LobbyPeopleManagementMediator:ProcessSignal(signal )
	local name = signal:GetName()
	-- print(name)
    dump(signal:GetBody())
	if name == SIGNALNAMES.Lobby_EmployeeSwitch_Callback then
        --更新UI
        local body = signal:GetBody()
        local errorCode = checkint(checktable(body.data).errcode)
        if errorCode == 0 then
            AppFacade.GetInstance():UnRegsitMediator("ChooseLobbyPeopleMediator")
			self.isGuideDispatched = false
            if self.isDown == true then
                --下服务的操作
                self.isDown = false
                if self.chooseType == 1 then--主管
                    gameMgr:DeleteCardPlace({{id = gameMgr:GetUserInfo().supervisor[tostring(self.index)]}}, CARDPLACE.PLACE_ASSISTANT)
                    gameMgr:GetUserInfo().supervisor[tostring(self.index)] = nil
                elseif self.chooseType == 2 then--厨师
                    gameMgr:DeleteCardPlace({{id = gameMgr:GetUserInfo().chef[tostring(self.index)]}}, CARDPLACE.PLACE_ASSISTANT)
                    gameMgr:GetUserInfo().chef[tostring(self.index)] = nil
                    AppFacade.GetInstance():DispatchObservers(RESTAURANT_EVENTS.EVENT_UPDATA_COOKLIMIT_NUM)
                elseif self.chooseType == 3 then--
                    if self.TwaiterSwitchTimeUpdateFunc[tostring(self.index)] then
                        scheduler.unscheduleGlobal(self.TwaiterSwitchTimeUpdateFunc[tostring(self.index)])
                    end
                    local oldCardId = gameMgr:GetUserInfo().waiter[tostring(self.index)]
                    gameMgr:DeleteCardPlace({{id = oldCardId}}, CARDPLACE.PLACE_ASSISTANT)
                    gameMgr:GetUserInfo().waiter[tostring(self.index)] = nil
                    AppFacade.GetInstance():DispatchObservers(RESTAURANT_EVENTS.EVENT_SWITCH_WAITER,{index = self.index,oldCardId = oldCardId})
                end
                gameMgr:GetUserInfo().employee[tostring(self.index)] = nil
                self:UpdataUI( self.choseData )
            else
                gameMgr:GetUserInfo().employee[tostring(self.index)] = self.choseData.id
                local places = gameMgr:GetCardPlace({id = self.choseData.id})
                local scene = uiMgr:GetCurrentScene()
                if places and table.nums(places) > 0 then
                    if places[tostring(CARDPLACE.PLACE_TEAM)] then--该改开在编队中、则从编队卸下
                        gameMgr:DeleteCardPlace({{id = self.choseData.id}}, CARDPLACE.PLACE_TEAM)
                        for i,v in pairs(gameMgr:GetUserInfo().teamFormation) do
                            if v then
                                local bool = false
                                for k,vv in ipairs(v.cards) do
                                    if vv.id then
                                        if checkint(self.choseData.id) == checkint(vv.id) then
                                            vv.id = nil
                                            bool = true
                                            break
                                        end
                                    end
                                end
                                if bool then
                                    break
                                end
                            end
                        end
                    elseif places[tostring(CARDPLACE.PLACE_ICE_ROOM)] then
                        gameMgr:DeleteCardPlace({{id = self.choseData.id}}, CARDPLACE.PLACE_ICE_ROOM)
                    end
                end
                --将该卡牌状态设置为大堂模块
                gameMgr:SetCardPlace({}, {{id = self.choseData.id}} , CARDPLACE.PLACE_ASSISTANT)

                if self.chooseType == 1 then--主管
                    gameMgr:DeleteCardPlace({{id = gameMgr:GetUserInfo().supervisor[tostring(self.index)]}}, CARDPLACE.PLACE_ASSISTANT)
                    gameMgr:GetUserInfo().supervisor[tostring(self.index)] = self.choseData.id
					AppFacade.GetInstance():DispatchObservers(RESTAURANT_EVENTS.EVENT_UPDATA_COOKLIMIT_NUM)

                elseif self.chooseType == 2 then--厨师
                    gameMgr:DeleteCardPlace({{id = gameMgr:GetUserInfo().chef[tostring(self.index)]}}, CARDPLACE.PLACE_ASSISTANT)
                    gameMgr:GetUserInfo().chef[tostring(self.index)] = self.choseData.id
                    AppFacade.GetInstance():DispatchObservers(RESTAURANT_EVENTS.EVENT_UPDATA_COOKLIMIT_NUM)

                elseif self.chooseType == 3 then--服务员
                    if self.TwaiterSwitchTimeUpdateFunc[tostring(self.index)] then
                        scheduler.unscheduleGlobal(self.TwaiterSwitchTimeUpdateFunc[tostring(self.index)])
                    end
                    local isHas = false
                    for k,v in pairs(gameMgr:GetUserInfo().waiter) do
                        if k == tostring(self.index) then
                            isHas = true
                            break
                        end
                    end
                    -- dump(isHas)
                    if isHas == true then--
                        local oldCardId = gameMgr:GetUserInfo().waiter[tostring(self.index)]
                        gameMgr:DeleteCardPlace({{id = gameMgr:GetUserInfo().waiter[tostring(self.index)]}}, CARDPLACE.PLACE_ASSISTANT)
                        gameMgr:GetUserInfo().waiter[tostring(self.index)] = self.choseData.id
                        AppFacade.GetInstance():DispatchObservers(RESTAURANT_EVENTS.EVENT_SWITCH_WAITER,{index = self.index,oldCardId = oldCardId})
                        self.TwaiterMess = {}
                        self.TwaiterMess = gameMgr:GetUserInfo().waiter
                    else
                        gameMgr:GetUserInfo().waiter[tostring(self.index)] = self.choseData.id
                        AppFacade.GetInstance():DispatchObservers(RESTAURANT_EVENTS.EVENT_SWITCH_WAITER,{index = self.index,oldCardId = nil})
                        self.TwaiterMess = {}
                        self.TwaiterMess = gameMgr:GetUserInfo().waiter
                    end

                    -- self:CheckWaiterTime(self.index)
                end
				self:UpdataUI( self.choseData )

				local cardUuid   = checkint(checktable(self.choseData).id)
				if cardUuid > 0 then
					local cardData   = gameMgr:GetCardDataById(self.choseData.id)
					local soundTypes = { SoundType.TYPE_TEAM, SoundType.TYPE_TEAM_CAPTAIN }
					CommonUtils.PlayCardSoundByCardId(cardData.cardId, soundTypes[math.random(#soundTypes)], SoundChannel.AVATAR_QUEST)
				end
            end
            GuideUtils.DispatchStepEvent()
        end
	elseif name == SIGNALNAMES.Lobby_EmployeeUnlock_Callback then--解锁
		-- dump(CommonUtils.GetConfigAllMess('levelUp','restaurant'))
        local body = signal:GetBody()
        local errorCode = checkint(checktable(body.data).errcode)
        if errorCode == 0 then
            table.insert(self.employee,tostring(self.index))
            self.unlockMess[tostring(self.index)] = tostring(self.index)
            self:UpdataUI()
        end
		-- dump(CommonUtils.GetConfigAllMess('levelUp','restaurant'))
	end
end


function LobbyPeopleManagementMediator:Initial( key )

	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.LobbyPeopleManagementView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)

	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	self.viewData = viewComponent.viewData

	self.viewData.backBtn:setOnClickScriptHandler(function( sender )
        PlayAudioByClickNormal()
		GuideUtils.DispatchStepEvent()
		AppFacade.GetInstance():UnRegsitMediator("LobbyPeopleManagementMediator")
	end)


	for i,v in pairs(viewData.cookerAllCellTab) do
		v.qBg:setOnClickScriptHandler(handler(self,self.CookerButtonActions))
		v.chooseCookerBtn:setOnClickScriptHandler(handler(self,self.CookerButtonActions))
	end

	for i,v in pairs(viewData.waiterAllCellTab) do
		v.qBg:setOnClickScriptHandler(handler(self,self.WaiterButtonActions))
		v.chooseWaiterBtn:setOnClickScriptHandler(handler(self,self.WaiterButtonActions))
	end

	--选择主管按钮
	viewComponent.viewData.chooseSupervisorBtn:setOnClickScriptHandler(handler(self,self.SupervisorButtonActions))
	self.viewData.supervisorImg:GetAvatar():setTouchEnabled(true)
	self.viewData.supervisorImg:GetAvatar():setOnClickScriptHandler(handler(self,self.SupervisorButtonActions))--touchLayout


	self:initLayer()
end

function LobbyPeopleManagementMediator:initLayer()
	self.TsupervisorMess = gameMgr:GetUserInfo().supervisor
	self.TcookerMess = gameMgr:GetUserInfo().chef
	self.TwaiterMess = gameMgr:GetUserInfo().waiter

	-- dump(self.TsupervisorMess)
	-- dump(self.TcookerMess)
	-- dump(self.TwaiterMess)





	--主管
	if not self.unlockMess['1'] then
		for i,v in ipairs(self.viewData.skillImg) do
			v:setVisible(false)
		end
		self.viewData.supervisorImg:setVisible(false)
		if self.viewData.particleSpine then
			self.viewData.particleSpine:setVisible(false)
		end
		self.viewData.supervisorLight:setVisible(false)
		self.viewData.chooseSupervisorBtn:setNormalImage(_res('ui/home/lobby/peopleManage/restaurant_manage_btn_add_people_disabled.png'))
  		self.viewData.chooseSupervisorBtn:setSelectedImage(_res('ui/home/lobby/peopleManage/restaurant_manage_btn_add_people_disabled.png'))
	else
		for k,v in orderedPairs(self.TsupervisorMess) do
			self.viewData.supervisorImg:setVisible(true)
			self.viewData.supervisorLight:setVisible(true)
			self.viewData.chooseSupervisorBtn:setVisible(false)
			self.viewData.chooseSupervisorBtn:setNormalImage(_res('ui/home/lobby/peopleManage/restaurant_manage_btn_add_people.png'))
  			self.viewData.chooseSupervisorBtn:setSelectedImage(_res('ui/home/lobby/peopleManage/restaurant_manage_btn_add_people.png'))
			local data = gameMgr:GetCardDataById(v)
			self.viewData.supervisorImg:RefreshAvatar({cardId = data.cardId})
			if cardMgr.GetCouple(gameMgr:GetCardDataByCardId(data.cardId).id) then
				if self.viewData.particleSpine then
					self.viewData.particleSpine:setVisible(true)
				else
					local designSize = cc.size(1334, 750)
					local winSize = display.size
					local deltaHeight = (winSize.height - designSize.height) * 0.5
			
					local particleSpine = display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly')
					-- particleSpine:setTimeScale(2.0 / 3.0)
					particleSpine:setPosition(cc.p(display.SAFE_L + 300,deltaHeight))
					self.viewData.supervisorView:addChild(particleSpine,1)
					particleSpine:setAnimation(0, 'idle2', true)
					particleSpine:update(0)
					particleSpine:setToSetupPose()

					self.viewData.particleSpine = particleSpine
				end
			else
				if self.viewData.particleSpine then
					self.viewData.particleSpine:setVisible(false)
				end
			end
			local tempSkill = {}
			tempSkill = CommonUtils.GetBusinessSkillByCardId(data.cardId)
			if tempSkill then
				local t = {}
				local tbool = false
				for i,v in ipairs(tempSkill) do
					if v.unlock == 1 then
						table.insert(t,v)
					end
				end
				-- if tbool then
				if table.nums(t) > 0 and next(t) ~= nil then
					self.viewData.tipsLabel:setVisible(false)
					for i,v in ipairs(self.viewData.skillImg) do
						local skillImg = v:getChildByTag(1)
						local skillLvLabel = v:getChildByTag(2)
						if t[i] then
							v:setVisible(true)
							v:setPositionX(v:getParent():getContentSize().width*0.5 - (table.nums(t)/2)*v:getContentSize().width*v:getScale() + 100*(i-1))
							skillImg:setTexture(_res(CommonUtils.GetSkillIconPath(t[i].skillId)))
							skillLvLabel:setString(string.fmt(__('等级：_lv_'),{_lv_ = t[i].level}))
							v:setTouchEnabled(true)
							v:setOnClickScriptHandler(function(sender )
								uiMgr:ShowInformationTipsBoard({targetNode = sender, title = t[i].name, descr = t[i].descr, type = 5})
							end)

						else
							v:setVisible(false)
						end
					end
				else
					self.viewData.tipsLabel:setVisible(true)
					for i,v in ipairs(self.viewData.skillImg) do
						v:setVisible(false)
					end
				end
			else
				self.viewData.tipsLabel:setVisible(true)
				for i,v in ipairs(self.viewData.skillImg) do
					v:setVisible(false)
				end
			end
		end
	end


	--厨师
	for i,v in orderedPairs(self.viewData.cookerAllCellTab) do
		v.doorImg:setScaleX(1)
		if self.TcookerMess[i] then
			local data = gameMgr:GetCardDataById(self.TcookerMess[i])
            if data and data.cardId then
                v.qBg:removeAllChildren()
                v.chooseCookerBtn:setVisible(false)
				v.doorImg:setScaleX(0)
                v.addImg:setVisible(true)
                v.lockImg:setVisible(false)
		        v.trashImg1:setVisible(false)
        		v.trashImg2:setVisible(false)
                local qBg = v.qBg
                qBg:removeAllChildren()
                if not qBg:getChildByTag(1) then
					local cardInfo = gameMgr:GetCardDataById(data.id)
					local qAvatar  = AssetsUtils.GetCardSpineNode({skinId = cardInfo.defaultSkinId, scale = 0.4})
                    qAvatar:update(0)
                    qAvatar:setTag(1)
                    qAvatar:setAnimation(0, 'idle', true)
                    qAvatar:setPosition(cc.p(qBg:getContentSize().width * 0.5,-16))
                    qBg:addChild(qAvatar)
                    qBg:setTouchEnabled(true)
                end
                v.qBg:setOnClickScriptHandler(handler(self,self.CookerButtonActions))
                v.chooseCookerBtn:setOnClickScriptHandler(handler(self,self.CookerButtonActions))

				local cardConf = CommonUtils.GetConfig('cards', 'card', data.cardId)
				CommonUtils.SetCardNameLabelStringById(v.nameLabel, data.id, v.nameLabelParams)
                -- v.nameLabel:setString(cardConf.name)
                v.vigourLabel:setString(tostring(data.vigour))
                local maxVigour = app.restaurantMgr:getCardVigourLimit(data.id)
                local ratio = (checkint(data.vigour)/ maxVigour) * 100
                v.operaProgressBar:setValue(ratio)

                v.progressBG:setVisible(true)
                v.vigourProgressBarTop:setVisible(true)
                v.operaProgressBar:setVisible(true)
            end
	    else
	    	if not CommonUtils.CheckLockCondition(CommonUtils.GetConfigNoParser('restaurant','employee',i).unlockType) then--解锁未上阵
   	    		if not self.unlockMess[tostring(i)] then--未解锁
   	    			--TODO
   	    			--显示解锁ui
   	    			v.addImg:setVisible(false)
	    			v.lockImg:setVisible(true)
			        v.trashImg1:setVisible(true)
	        		v.trashImg2:setVisible(true)
   	    		else
		    		v.addImg:setVisible(true)
	    			v.lockImg:setVisible(false)
	    			v.trashImg1:setVisible(false)
	        		v.trashImg2:setVisible(false)
   	    		end

	    	else--未解锁
	    		-- dump(i)
	    		-- dump('未解锁')
	    		v.addImg:setVisible(false)
	    		v.lockImg:setVisible(true)
	    		v.trashImg1:setVisible(true)
        		v.trashImg2:setVisible(true)
	    	end
		end
	end

	--服务员
	for i,v in orderedPairs(self.viewData.waiterAllCellTab) do
		if self.TwaiterMess[i] then
            local data = gameMgr:GetCardDataById(self.TwaiterMess[i])
            if data and data.cardId then
                v.qBg:removeAllChildren()
                v.chooseWaiterBtn:setVisible(false)
                local qBg = v.qBg
                qBg:removeAllChildren()
                if not qBg:getChildByTag(1) then
					local cardInfo = gameMgr:GetCardDataById(data.id)
					local qAvatar  = AssetsUtils.GetCardSpineNode({skinId = cardInfo.defaultSkinId, scale = 0.3})
                    qAvatar:update(0)
                    qAvatar:setTag(1)
                    qAvatar:setAnimation(0, 'idle', true)
                    qAvatar:setPosition(cc.p(qBg:getContentSize().width * 0.5,-16))
                    qBg:addChild(qAvatar)
                    qBg:setTouchEnabled(true)
                end
                v.qBg:setOnClickScriptHandler(handler(self,self.WaiterButtonActions))
                v.chooseWaiterBtn:setOnClickScriptHandler(handler(self,self.WaiterButtonActions))

				local cardConf = CommonUtils.GetConfig('cards', 'card', data.cardId)
				CommonUtils.SetCardNameLabelStringById(v.nameLabel, data.id, v.nameLabelParams)
                -- v.nameLabel:setString(cardConf.name)
                v.vigourLabel:setString(data.vigour)
                v.vigourLabel:setString(tostring(data.vigour))
                local maxVigour = app.restaurantMgr:getCardVigourLimit(data.id)
                local ratio = (checkint(data.vigour)/ maxVigour) * 100
                v.operaProgressBar:setValue(ratio)

                v.progressBG:setVisible(true)
                v.vigourProgressBarTop:setVisible(true)
                v.operaProgressBar:setVisible(true)
            end
	    else
	    	v.switchDesLabel:setString('')
   	    	if not CommonUtils.CheckLockCondition(CommonUtils.GetConfigNoParser('restaurant','employee',i).unlockType) then--解锁未上阵
   	    		if not self.unlockMess[tostring(i)] then--未解锁
   	    			--TODO
   	    			--显示解锁ui
   	    			v.addImg:setVisible(false)
	    			v.lockImg:setVisible(true)
	    		else
		    		v.addImg:setVisible(true)
		    		v.lockImg:setVisible(false)
   	    		end
	    	else--未解锁
	    		-- dump(i)
	    		-- dump('未解锁')
	    		v.addImg:setVisible(false)
	    		v.lockImg:setVisible(true)
	    	end
		end
	end

	-- self:CheckWaiterTime()
end

function LobbyPeopleManagementMediator:CheckWaiterTime(index)
	--服务员
	-- dump(self.waitersTimeMess)
	-- dump(self.TwaiterMess)
	for k,v in pairs(self.TwaiterMess) do
		local timeData = self.waitersTimeMess[v]
		local switchDesLabel = self.viewData.waiterAllCellTab[k].switchDesLabel
		if timeData then
			if checkint(timeData.switchLeftSeconds ) > 0 then
				if index then
					if checkint(index) == checkint(k) then
						dump(index)
						self.TwaiterSwitchTimeUpdateFunc[k] = scheduler.scheduleGlobal(function(dt)
					        --事件的计时器
					        -- dump(k)
					        -- dump(timeData.switchLeftSeconds)
			                if checkint(timeData.switchLeftSeconds ) <= 0 then
			                    scheduler.unscheduleGlobal(self.TwaiterSwitchTimeUpdateFunc[k])
			                    switchDesLabel:setString(" ")
			                else
			                    switchDesLabel:setString(string.formattedTime(checkint(timeData.switchLeftSeconds),'准备中 %02i:%02i:%02i'))
			                    -- timeData.switchLeftSeconds  = timeData.switchLeftSeconds  - 1
			                end
			                -- dump(timeData.switchLeftSeconds)
					    end,1.0)
					    break
					end
				else
					self.TwaiterSwitchTimeUpdateFunc[k] = scheduler.scheduleGlobal(function(dt)
				        --事件的计时器
		                if checkint(timeData.switchLeftSeconds ) <= 0 then
		                    scheduler.unscheduleGlobal(self.TwaiterSwitchTimeUpdateFunc[k])
		                    switchDesLabel:setString(" ")
		                else
		                    switchDesLabel:setString(string.formattedTime(checkint(timeData.switchLeftSeconds),'准备中 %02i:%02i:%02i'))
		                    -- timeData.switchLeftSeconds  = timeData.switchLeftSeconds  - 1
		                end
		                -- dump(timeData.switchLeftSeconds)
				    end,1.0)
				end
			else
				switchDesLabel:setString(" ")
			end
		end
	end
end

function LobbyPeopleManagementMediator:ChooseCallBack( data )
    -- dump(data)
	-- dump(self.index)
	-- dump(self.viewData.cookerAllCellTab)

    if self.isGuideDispatched then return end
    --FIX 这里可能会引起一个bug  未连接时再也不能换人了
    -- self.isGuideDispatched = true
    self.choseData = data
    local employeeId = self.index
	local cardPlayId = 1
	-- 卸货状态

	local unloadErrorCode = 0
	local replaceErrorCode = 0
    if self.chooseType == 1 then  -- 主管
        cardPlayId = gameMgr:GetUserInfo().supervisor[tostring(employeeId)]
    elseif self.chooseType == 2 then  -- 主/副厨
        cardPlayId= gameMgr:GetUserInfo().chef[tostring(employeeId)]
    elseif self.chooseType == 3 then  -- 服务员
		cardPlayId = gameMgr:GetUserInfo().waiter[tostring(employeeId)]
		local waiter = gameMgr:GetUserInfo().waiter
		unloadErrorCode, replaceErrorCode = self:getUnloadAndReplaceErrorCode(waiter, data, cardPlayId)
    end
    -- dump(data.id)
	-- dump(cardPlayId)

	if checkint(data.id) == checkint(cardPlayId) then--操作同一个卡牌。即为卸下操作
		if unloadErrorCode == 0 then
            self.isDown = true
            if GuideUtils.IsGuiding() then
                self:SendSignal(COMMANDS.COMMANDS_Lobby_EmployeeSwitch,{employeeId = employeeId})
            else
                socketMgr:SendPacket( NetCmd.RequestEmploySwich, {employeeId = employeeId})--
            end
		else
			self.isGuideDispatched = false
			local text = self:getUnloadErrorTipByErrorCode(unloadErrorCode)
			if text then
				uiMgr:ShowInformationTips(text)
			end
		end
	else--替换操作
		if replaceErrorCode == 0 then
			local cardData = app.gameMgr:GetUserInfo().cards[tostring(data.id)] or {}
			if not GuideUtils.CheckIsFirstTeamMember({dontShowTips = true}) and (checkint(cardData.cardId) ~= 200011 and checkint(cardData.cardId) ~= 200013) then
				app.uiMgr:ShowInformationTips(__('在组成自己的编队前，请不要打乱飨灵的顺序\n请先前往【编队】逛逛~'))
			else
				self.isDown = false
				if GuideUtils.IsGuiding() then
					self:SendSignal(COMMANDS.COMMANDS_Lobby_EmployeeSwitch,{playerCardId = data.id, employeeId = employeeId})
				else
					socketMgr:SendPacket( NetCmd.RequestEmploySwich, {playerCardId = data.id,employeeId = employeeId})--
				end
			end
		else
			self.isGuideDispatched = false
			local text = self:getReplaceErrorTipByErrorCode(replaceErrorCode)
			if text then
				uiMgr:ShowInformationTips(text)
			end
		end
    end
end

-- 获取卸和替换服务员错误码
function LobbyPeopleManagementMediator:getUnloadAndReplaceErrorCode(waiter, data, cardPlayId)
	local unloadErrorCode = 0
	local replaceErrorCode = 0

	-- 是否是雇佣状态
	local isHire   = checkint(cardPlayId) == 0
	-- 如果有代理店长 并且不是雇佣状态 则检查是否能卸下或替换
	if checkint(gameMgr:GetUserInfo().avatarCacheData.mangerId) > 0 and not isHire then
		-- 能卸人 gameMgr:GetUserInfo().waiter 必大于1
		local waiterNum = 0
		-- 如果拥有多个服务员的话 必须保证有一个服务员的新鲜度 > 0
		-- 1 获取满足 服务员的拥有的新鲜度是否大于0 的个数
		local satisfyConditionCount = 0
		local satisfyConditionWaiter = {}
		for index,waiterId in pairs(waiter) do
			local waiterInfo = gameMgr:GetCardDataById(waiterId)
			if waiterInfo and checkint(waiterInfo.vigour) > 0 then
				satisfyConditionCount = satisfyConditionCount + 1
				satisfyConditionWaiter[tostring(waiterId)] = 1
			end
			waiterNum = waiterNum + 1
		end

		local isUnload = checkint(data.id) == checkint(cardPlayId)

		-- 2. 卸下
		if isUnload then
			-- 2. 只有一个服务员时 （这时不能卸下)
			if waiterNum <= 1 then
				unloadErrorCode = 1
			else
				-- 2.1 如果 满足条件个数 小于等于 1 并且要卸下的卡牌是满足条件的卡牌 则给个错误码
				if satisfyConditionCount <= 1 and satisfyConditionWaiter[tostring(cardPlayId)] then
					unloadErrorCode = 2
				end
			end
		else
		-- 3.替换
			local newWaiterVigour = checkint(data.vigour)

			if newWaiterVigour <= 0 then
				-- 3.1 如果新服务员的新鲜度必须小于等于0, 则给个错误码
				if waiterNum <= 1 then
					replaceErrorCode = 1
				-- 3.2 有多个服务员时 并且 新服务员新鲜度小于等于0 并且 满足条件个数 小于等于 1 并且 要卸下的卡牌是满足条件的卡牌 则给个错误码
				elseif satisfyConditionCount <= 1 and satisfyConditionWaiter[tostring(cardPlayId)] then
					replaceErrorCode = 2
				end
			end

		end
	end

	return unloadErrorCode, replaceErrorCode
end

-- 通过错误码获取卸服务员错误提示
function LobbyPeopleManagementMediator:getUnloadErrorTipByErrorCode(errorCode)
	local text = nil
	if errorCode == 1 then
		text = __('在代理店长工作的期间内，要保证餐厅内起码有一个服务员哦~')
	elseif errorCode == 2 then
		text = __('在代理店长工作的期间内，要保证餐厅内起码有一个能工作的服务员哦~')
	end
	return text
end

-- 通过错误码获取替换服务员错误提示
function LobbyPeopleManagementMediator:getReplaceErrorTipByErrorCode(errorCode)
	local text = nil
	if errorCode == 1 then
		text = __('在代理店长工作的期间内，要保证餐厅内起码有一个能工作的服务员哦~')
	elseif errorCode == 2 then
		text = __('在代理店长工作的期间内，要保证餐厅内起码有一个能工作的服务员哦~')
	end
	return text
end

function LobbyPeopleManagementMediator:UpdataUI( data )
	if self.chooseType == 1 then--主管
		if not self.unlockMess['1'] then
			self.viewData.supervisorImg:setVisible(false)
			if self.viewData.particleSpine then
				self.viewData.particleSpine:setVisible(false)
			end
			self.viewData.supervisorLight:setVisible(false)
			self.viewData.chooseSupervisorBtn:setNormalImage(_res('ui/home/lobby/peopleManage/restaurant_manage_btn_add_people_disabled.png'))
	  		self.viewData.chooseSupervisorBtn:setSelectedImage(_res('ui/home/lobby/peopleManage/restaurant_manage_btn_add_people_disabled.png'))
		else
			self.viewData.chooseSupervisorBtn:setNormalImage(_res('ui/home/lobby/peopleManage/restaurant_manage_btn_add_people.png'))
	  		self.viewData.chooseSupervisorBtn:setSelectedImage(_res('ui/home/lobby/peopleManage/restaurant_manage_btn_add_people.png'))
			if self.TsupervisorMess[tostring(self.index)] then
				self.viewData.supervisorImg:setVisible(true)
				self.viewData.supervisorLight:setVisible(true)
				self.viewData.chooseSupervisorBtn:setVisible(false)
				self.viewData.supervisorImg:RefreshAvatar({cardId = data.cardId})
				if cardMgr.GetCouple(gameMgr:GetCardDataByCardId(data.cardId).id) then
					if self.viewData.particleSpine then
						self.viewData.particleSpine:setVisible(true)
					else
						local designSize = cc.size(1334, 750)
						local winSize = display.size
						local deltaHeight = (winSize.height - designSize.height) * 0.5
				
						local particleSpine = display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly')
						-- particleSpine:setTimeScale(2.0 / 3.0)
						particleSpine:setPosition(cc.p(display.SAFE_L + 300,deltaHeight))
						self.viewData.supervisorView:addChild(particleSpine,1)
						particleSpine:setAnimation(0, 'idle2', true)
						particleSpine:update(0)
						particleSpine:setToSetupPose()
	
						self.viewData.particleSpine = particleSpine
					end
				else
					if self.viewData.particleSpine then
						self.viewData.particleSpine:setVisible(false)
					end
				end
				local tempSkill = {}
				tempSkill = CommonUtils.GetBusinessSkillByCardId(data.cardId)
				if tempSkill then
					local t = {}
					local tbool = false
					for i,v in ipairs(tempSkill) do
						if v.unlock == 1 then
							table.insert(t,v)
						end
					end

					-- dump(t)

					-- if tbool then
					if table.nums(t) > 0 and next(t) ~= nil then
						self.viewData.tipsLabel:setVisible(false)
						for i,v in ipairs(self.viewData.skillImg) do
							local skillImg = v:getChildByTag(1)
							local skillLvLabel = v:getChildByTag(2)
							if t[i] then
								v:setVisible(true)
								v:setTouchEnabled(true)
								v:setPositionX(v:getParent():getContentSize().width*0.5 - (table.nums(t)/2)*v:getContentSize().width*v:getScale() + 100*(i-1))
								skillImg:setTexture(_res(CommonUtils.GetSkillIconPath(t[i].skillId)))
								skillLvLabel:setString(string.fmt(__('等级：_lv_'),{_lv_ = t[i].level}))
								v:setOnClickScriptHandler(function(sender )
									uiMgr:ShowInformationTipsBoard({targetNode = sender, title = t[i].name, descr = t[i].descr, type = 5})
								end)
							else
								v:setVisible(false)
							end
						end
					else
						self.viewData.tipsLabel:setVisible(true)
						for i,v in ipairs(self.viewData.skillImg) do
							v:setVisible(false)
						end
					end
				else
					self.viewData.tipsLabel:setVisible(true)
					for i,v in ipairs(self.viewData.skillImg) do
						v:setVisible(false)
					end
				end
			else
				self.viewData.supervisorImg:setVisible(false)
				if self.viewData.particleSpine then
					self.viewData.particleSpine:setVisible(false)
				end
				self.viewData.supervisorLight:setVisible(false)
				self.viewData.chooseSupervisorBtn:setVisible(true)
				self.viewData.tipsLabel:setVisible(false)
				for i,v in ipairs(self.viewData.skillImg) do
					v:setVisible(false)
				end
			end
		end
	elseif self.chooseType == 2 then--厨师
		local v = self.viewData.cookerAllCellTab[tostring(self.index)]
		v.qBg:removeAllChildren()
		v.chooseCookerBtn:setVisible(false)
		local qBg = v.qBg
		qBg:removeAllChildren()
	    v.progressBG:setVisible(false)
        v.vigourProgressBarTop:setVisible(false)
        v.operaProgressBar:setVisible(false)
		v.nameLabel:setVisible(false)
		v.vigourLabel:setVisible(false)
        v.trashImg1:setVisible(false)
        v.trashImg2:setVisible(false)
		if self.TcookerMess[tostring(self.index)] then
			-- dump('上阵')
			if not qBg:getChildByTag(1) then
				local cardInfo = gameMgr:GetCardDataById(data.id)
				local qAvatar  = AssetsUtils.GetCardSpineNode({skinId = cardInfo.defaultSkinId, scale = 0.4})
			    qAvatar:update(0)
			    qAvatar:setTag(1)
			    qAvatar:setAnimation(0, 'idle', true)
			    qAvatar:setPosition(cc.p(qBg:getContentSize().width * 0.5,-16))
			    qBg:addChild(qAvatar)
			    qBg:setTouchEnabled(true)
			end
			v.qBg:setOnClickScriptHandler(handler(self,self.CookerButtonActions))
			v.chooseCookerBtn:setOnClickScriptHandler(handler(self,self.CookerButtonActions))

			local cardConf = CommonUtils.GetConfig('cards', 'card', data.cardId)
			CommonUtils.SetCardNameLabelStringById(v.nameLabel, data.id, v.nameLabelParams)
			-- v.nameLabel:setString(cardConf.name)
			v.vigourLabel:setString(tostring(data.vigour))
            local maxVigour = app.restaurantMgr:getCardVigourLimit(data.id)
            local ratio = (checkint(data.vigour) / maxVigour) * 100
			v.operaProgressBar:setValue(ratio)

		    v.progressBG:setVisible(true)
	        v.vigourProgressBarTop:setVisible(true)
	        v.operaProgressBar:setVisible(true)
	        v.nameLabel:setVisible(true)
			v.vigourLabel:setVisible(true)


			v.doorImg:setScaleX(1)
			v.doorImg:runAction(
				cc.Sequence:create(cc.DelayTime:create(0.04),
				cc.ScaleTo:create(0.2, 0, 1)
		    ))


	    else
	    	-- dump('卸下')

			v.doorImg:setScaleX(0)
			v.doorImg:runAction(
				cc.Sequence:create(cc.DelayTime:create(0.04),
				cc.ScaleTo:create(0.2, 1, 1)
		    ))

			if not CommonUtils.CheckLockCondition(CommonUtils.GetConfigNoParser('restaurant','employee',self.index).unlockType) then--解锁未上阵
   	    		if not self.unlockMess[tostring(self.index)] then--未解锁
   	    			--TODO
   	    			--显示解锁ui
   	    			v.addImg:setVisible(false)
	    			v.lockImg:setVisible(true)
   	    		else
		    		v.addImg:setVisible(true)
	    			v.lockImg:setVisible(false)
   	    		end

	    	else--未解锁
	    		-- dump(i)
	    		-- dump('未解锁')
	    		v.addImg:setVisible(false)
	    		v.lockImg:setVisible(true)
	    	end

	    	v.chooseCookerBtn:setVisible(true)
		end
	elseif self.chooseType == 3 then--服务员
		-- dump(self.TwaiterMess)
		local v = self.viewData.waiterAllCellTab[tostring(self.index)]
		v.qBg:removeAllChildren()
		v.chooseWaiterBtn:setVisible(false)
		local qBg = v.qBg
		qBg:removeAllChildren()
	    v.progressBG:setVisible(false)
        v.vigourProgressBarTop:setVisible(false)
        v.operaProgressBar:setVisible(false)
		v.nameLabel:setVisible(false)
		v.vigourLabel:setVisible(false)
		v.switchDesLabel:setVisible(false)
		if self.TwaiterMess[tostring(self.index)] then
			if not qBg:getChildByTag(1) then
				local cardInfo = gameMgr:GetCardDataById(data.id)
				local qAvatar  = AssetsUtils.GetCardSpineNode({skinId = cardInfo.defaultSkinId, scale = 0.3})
			    qAvatar:update(0)
			    qAvatar:setTag(1)
			    qAvatar:setAnimation(0, 'idle', true)
			    qAvatar:setPosition(cc.p(qBg:getContentSize().width * 0.5,-16))
			    qBg:addChild(qAvatar)
			    qBg:setTouchEnabled(true)
			end
			v.qBg:setOnClickScriptHandler(handler(self,self.WaiterButtonActions))
			v.chooseWaiterBtn:setOnClickScriptHandler(handler(self,self.WaiterButtonActions))

			local cardConf = CommonUtils.GetConfig('cards', 'card', data.cardId)
			CommonUtils.SetCardNameLabelStringById(v.nameLabel, data.id, v.nameLabelParams)
			-- v.nameLabel:setString(cardConf.name)
			v.vigourLabel:setString(data.vigour)
            local maxVigour = app.restaurantMgr:getCardVigourLimit(data.id)
            local ratio = (checkint(data.vigour) / maxVigour) * 100
            v.operaProgressBar:setValue(ratio)

		    v.progressBG:setVisible(true)
	        v.vigourProgressBarTop:setVisible(true)
	        v.operaProgressBar:setVisible(true)
   	        v.nameLabel:setVisible(true)
			v.vigourLabel:setVisible(true)
			v.switchDesLabel:setVisible(true)
	    else
	    	v.chooseWaiterBtn:setVisible(true)
	    	if not CommonUtils.CheckLockCondition(CommonUtils.GetConfigNoParser('restaurant','employee',self.index).unlockType) then--解锁未上阵
	    		if not self.unlockMess[tostring(self.index)] then--未解锁
	    			--TODO
	    			--显示解锁ui
	    			v.addImg:setVisible(false)
	    			v.lockImg:setVisible(true)
    			else
		    		v.addImg:setVisible(true)
		    		v.lockImg:setVisible(false)
	    		end
    		else--未解锁
	    		-- dump(i)
	    		-- dump('未解锁')
	    		v.addImg:setVisible(false)
	    		v.lockImg:setVisible(true)
    		end
	    end
	end
end


--主管按钮回调
function LobbyPeopleManagementMediator:SupervisorButtonActions( sender )
	PlayAudioByClickNormal()
	if not GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.RESTAURANT_PEOPLE_MANAGEMENT, {isCommon = true}) then return end

	local tag = sender:getTag()
	self.index = tag
	self.chooseType = 1
	if not self.unlockMess[tostring(tag)] then--未解锁
		--当前餐厅等级能够使用主管的数量
		local cookerLimit = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).employeeLimit[LOBBY_SUPERVISOR]
		local needRestaurantLevel = 1
		for i,v in orderedPairs(CommonUtils.GetConfigAllMess('levelUp','restaurant')) do
			if v.employeeLimit and checkint(v.employeeLimit[LOBBY_SUPERVISOR]) == 1 then
				needRestaurantLevel = v.level
				break
			end
		end




		if checkint(cookerLimit) <= 0 then
			uiMgr:ShowInformationTips(string.fmt(__('餐厅等级需达到_num_级才能使用主管位置'),{_num_ = needRestaurantLevel}))
		else
            socketMgr:SendPacket( NetCmd.RequestEmployUnlock,{employeeId = tag})
		end
	else
		local x = {}
		x.chooseType = 1
		x.employeeId = tag
		x.callback = handler(self,self.ChooseCallBack)
        self.isGuideDispatched = false
	    local ChooseLobbyPeopleMediator = require( 'Game.mediator.ChooseLobbyPeopleMediator' )
	    local mediator = ChooseLobbyPeopleMediator.new(x)
	    self:GetFacade():RegistMediator(mediator)
	end
end

--厨房按钮回调
function LobbyPeopleManagementMediator:CookerButtonActions( sender )
    PlayAudioByClickNormal()
	local tag = sender:getTag()
	-- dump(tag)
	self.chooseType = 2
	self.index = tag

    if not CommonUtils.CheckLockCondition(CommonUtils.GetConfigNoParser('restaurant','employee',tag).unlockType) then
        -- self.index = tag

        --该大堂等级对应可以开放最大厨师数量
        if not self.unlockMess[tostring(tag)] then--未解锁
            local cookerLimit = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).employeeLimit[LOBBY_CHEF]
            local needRestaurantLevel = 1
            for i,v in orderedPairs(CommonUtils.GetConfigAllMess('levelUp','restaurant')) do
                if v.employeeLimit and checkint(v.employeeLimit[LOBBY_CHEF]) == (checkint(tag) - 1) then
                    needRestaurantLevel = v.level
                    break
                end
            end

            if checkint(cookerLimit) <= 0 then
                uiMgr:ShowInformationTips(string.fmt(__('餐厅等级需达到_num_级才能使用更多厨师位置'),{_num_ = needRestaurantLevel}))
            else
                if checkint(cookerLimit) >= (checkint(tag) - 1) then
                    socketMgr:SendPacket( NetCmd.RequestEmployUnlock,{employeeId = tag})
                else
                    uiMgr:ShowInformationTips(string.fmt(__('餐厅等级需达到_num_级才能使用更多厨师位置'),{_num_ = needRestaurantLevel}))
                end
            end
        else
            local playerCardId = self.TcookerMess[tostring(tag)]
            if self.recipeCooking[tostring(playerCardId)] then
                uiMgr:ShowInformationTips(__('该飨灵还正在厨师做菜，无法替换'))
                return
            end

            local x = {}
            x.chooseType = 2
            x.employeeId = tag
            x.callback = handler(self,self.ChooseCallBack)
            self.isGuideDispatched = false
            local ChooseLobbyPeopleMediator = require( 'Game.mediator.ChooseLobbyPeopleMediator' )
            local mediator = ChooseLobbyPeopleMediator.new(x)
            self:GetFacade():RegistMediator(mediator)
            GuideUtils.DispatchStepEvent()
        end
    else
        -- dump('未达到解锁条件')
        local targetNum = 0
        for k,v in pairs(CommonUtils.GetConfigNoParser('restaurant','employee',tag).unlockType) do
            targetNum = v.targetNum
        end
        uiMgr:ShowInformationTips(string.fmt(__('餐厅等级需达到_num_级才能解锁'),{_num_ = targetNum}))
    end
end

--服务员按钮回调
function LobbyPeopleManagementMediator:WaiterButtonActions( sender )
	PlayAudioByClickNormal()
    local tag = sender:getTag()
    -- dump(tag)
	self.chooseType = 3
	self.index = tag
	if not  CommonUtils.CheckLockCondition(CommonUtils.GetConfigNoParser('restaurant','employee',tag).unlockType) then
		-- self.index = tag
		if not self.unlockMess[tostring(tag)] then--未解锁
			local cookerLimit = CommonUtils.GetConfigNoParser('restaurant','levelUp',gameMgr:GetUserInfo().restaurantLevel).employeeLimit[LOBBY_WAITER]
			local needRestaurantLevel = 1
			for i,v in orderedPairs(CommonUtils.GetConfigAllMess('levelUp','restaurant')) do
				if v.employeeLimit and  checkint(v.employeeLimit[LOBBY_WAITER]) == (checkint(tag) - 3) then
					needRestaurantLevel = v.level
					break
				end
			end
			-- dump(CommonUtils.GetConfigAllMess('levelUp','restaurant'))
			if checkint(cookerLimit) <= 0 then
				uiMgr:ShowInformationTips(string.fmt(__('餐厅等级需达到_num_级才能使用更多服务员位置'),{_num_ = needRestaurantLevel}))
			else
				if checkint(cookerLimit) >= (checkint(tag) - 3) then
                    socketMgr:SendPacket( NetCmd.RequestEmployUnlock,{employeeId = tag})
				else
					uiMgr:ShowInformationTips(string.fmt(__('餐厅等级需达到_num_级才能使用更多服务员位置'),{_num_ = needRestaurantLevel}))
				end
			end
		else
			local isFirstWaiter = checkint(tag) - 3 == 1
			if isFirstWaiter or GuideUtils.CheckFuncEnabled(GUIDE_ENABLE_FUNC.RESTAURANT_PEOPLE_MANAGEMENT, {isCommon = true}) then
				local x = {}
				x.chooseType = 3
				x.employeeId = tag
				x.callback = handler(self,self.ChooseCallBack)
				self.isGuideDispatched = false
				local ChooseLobbyPeopleMediator = require( 'Game.mediator.ChooseLobbyPeopleMediator' )
				local mediator = ChooseLobbyPeopleMediator.new(x)
				self:GetFacade():RegistMediator(mediator)
				GuideUtils.DispatchStepEvent()
			end
		end
   	else
		-- dump('未解锁')
		local targetNum = 0
		for k,v in pairs(CommonUtils.GetConfigNoParser('restaurant','employee',tag).unlockType) do
			targetNum = v.targetNum
		end
		-- uiMgr:ShowInformationTips(__('大堂等级不足--'..targetNum))
		uiMgr:ShowInformationTips(string.fmt(__('餐厅等级需达到_num_级才能解锁'),{_num_ = targetNum}))
	end
end
function LobbyPeopleManagementMediator:GoogleBack()
	app:UnRegistMediator(NAME)
	return false
end
function LobbyPeopleManagementMediator:OnRegist(  )
    local LobbyPeopleManagementCommand = require( 'Game.command.LobbyPeopleManagementCommand')
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Lobby_EmployeeSwitch, LobbyPeopleManagementCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_Lobby_EmployeeUnlock, LobbyPeopleManagementCommand)
end

function LobbyPeopleManagementMediator:OnUnRegist(  )
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Lobby_EmployeeSwitch)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_Lobby_EmployeeUnlock)
	--称出命令

	for i,v in pairs(self.TwaiterSwitchTimeUpdateFunc) do
	    if v then
	        scheduler.unscheduleGlobal(v)
	    end
	end
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

return LobbyPeopleManagementMediator
