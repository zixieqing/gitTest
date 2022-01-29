--[[
---- TODO ----
@params table {
	isCommon bool 是否是通用调用
}
---- TODO ----
--]]
local Mediator = mvc.Mediator

local TeamFormationMediator = class("TeamFormationMediator", Mediator)


local NAME = "TeamFormationMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
function TeamFormationMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.allTeamsDatas = {} 	--全部的编队信息
	self.clickTag = 0 			--表示当前显示第几编队
	self.clickUnLockTag = 0		--表示需要就锁第几编队
	self.clickHeroTag = 0		--表示点击编队第几个英雄
	self.clickBtn = nil 		--表示当前显示第几编队btn
	self.showPet = false		--表示是否显示堕神信息界面
	self.TteamBtn = {}			--全部的编队按钮
	self.TteamLayout = {}       -- 存储全部的layout UI 
	self.backHome = false		--是否是返回主界面操作

	---- TODO ----
	self.isCommon = false -- 通用调用会显示一个返回按钮
	self.jumpTeamIndex = 1 --初始化界面显示第几个编队
	if params  then
		if params.isCommon then
			self.isCommon = params.isCommon
			self.teamFormationViewTag = 233
		end
		if params.jumpTeamIndex then
			self.jumpTeamIndex = params.jumpTeamIndex
		end
	end
	---- TODO ----
end

TeamFormationScene_ChangeCenterContainer = 'TeamFormationScene_ChangeCenterContainer'
TeamFormationScene_UpdataUI = 'TeamFormationScene_UpdataUI'
function TeamFormationMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.TeamFormation_Name_Callback,
		TeamFormationScene_ChangeCenterContainer,
		SIGNALNAMES.TeamFormation_UnLock_Callback,
		SIGNALNAMES.TeamFormation_switchTeam_Callback,
		TeamFormationScene_UpdataUI,
		SIGNALNAMES.IcePlace_AddCard_Callback,
		SIGNALNAMES.IcePlace_Home_Callback
	}

	return signals
end

function TeamFormationMediator:ProcessSignal(signal )
	local name = signal:GetName()
	if name == SIGNALNAMES.TeamFormation_Name_Callback then
		gameMgr:GetUserInfo().teamFormation[checkint(checktable(signal:GetBody()).teamId)] = {}
		gameMgr:GetUserInfo().teamFormation[checkint(checktable(signal:GetBody()).teamId)] = checktable(signal:GetBody())

		--跨编队上阵，然后点击返回。将之前上阵卡牌数据更新
		for i,v in ipairs(gameMgr:GetUserInfo().teamFormation) do
			if checkint(i) ~= checkint(signal:GetBody().teamId) then
				for ii,vv in ipairs(v.cards) do
					if vv.id then
						for i,vvv in ipairs(signal:GetBody().cards) do
							if vvv.id then
								if vv.id == vvv.id then
									if ii == 1 then
										v.captainId = nil
									end
									vv.id = nil
									break
								end
							end
						end
					end
				end
			end
		end
		--是否是返回主界面操作
		if self.backHome == true then
			self.backHome = false
			self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer_TeamFormation)
		end
		--是否是跳转其他页面。卡牌强化页面
		if self.goMessAndChange == true then
			self.goMessAndChange = false
			local data = self.allTeamsDatas[self.clickTag].cards[self.clickHeroTag]
			local cardData = gameMgr:GetCardDataById(data.id)
			self:GetFacade():RetrieveMediator("Router"):Dispatch({name = "TeamFormationMediator"},
				{name = "CardsListMediatorNew",params = {isFrom = 'TeamFormationMediator',cardId = cardData.cardId}},{isBack = true})
		end
	elseif name == SIGNALNAMES.TeamFormation_UnLock_Callback then--解锁编队
		--解锁编队操作
        local temp_tab = {}
        temp_tab.teamId = table.nums(gameMgr:GetUserInfo().teamFormation)+1
        temp_tab.captainId = 0
        temp_tab.cards = {}
        for i=1,5 do
        	table.insert(temp_tab.cards,{cardId = nil})
        end
        gameMgr:GetUserInfo().teamFormation[table.nums(gameMgr:GetUserInfo().teamFormation)+1] = temp_tab
        self.allTeamsDatas[table.nums(gameMgr:GetUserInfo().teamFormation)] = clone(temp_tab)
        -- print(#gameMgr:GetUserInfo().teamFormation)
		local btn = self.TteamBtn[table.nums(gameMgr:GetUserInfo().teamFormation)]
		if self.allTeamsDatas[table.nums(gameMgr:GetUserInfo().teamFormation)] then
			if btn:getChildByTag(1) then
				btn:removeChildByTag(1)
			end
			self.TteamLayout[btn:getTag()].teamLabel:setVisible(true)
		end
	
	
		self.TteamLayout[btn:getTag()].showImg:setTexture(_res('ui/home/teamformation/newCell/team_img_biaoji.png'))

		--编队小红点处理
		for i,v in ipairs(self.TteamBtn) do
			local layoutViewData = self.TteamLayout[v:getTag()] 
			layoutViewData.newImg:setVisible(false)
		    if app.badgeMgr:IsShowRedPointForUnLockTeam() then
		    	local num = table.nums(gameMgr:GetUserInfo().teamFormation) + 1
		    	if i == num then
		    		layoutViewData.newImg:setVisible(true)
		    	end
		    end
		end

		-- if self.useDiamond == true then
		-- 	self.useDiamond = false
			local deltaDiamond = -1*(self.useDiamond)
       		CommonUtils.DrawRewards({{goodsId = DIAMOND_ID, num = deltaDiamond}})
		-- end
		gameMgr:GetUserInfo().unlockTeamNeed = checktable(signal:GetBody())

	elseif name == TeamFormationScene_ChangeCenterContainer then --保存编队
		local tempEqual = true
		for k,v in pairs(gameMgr:GetUserInfo().teamFormation[self.clickTag].cards) do
			if v then
				if self.allTeamsDatas[self.clickTag].cards[k] then
					if checkint(self.allTeamsDatas[self.clickTag].cards[k].id) ~= checkint(v.id) then
						tempEqual = false
						break
					end
				else
					tempEqual = false
					break
				end
			else
				if self.allTeamsDatas[self.clickTag].cards[k] then
					tempEqual = false
					break
				end
			end
		end
		if tempEqual == false then
			self.backHome = true
			local cards = ''
			for k,v in pairs(self.allTeamsDatas[self.clickTag].cards) do
				if k == 1 then
					if v.id then
						cards = v.id
					else
						cards = ' '
					end
				else
					if v.id then
						cards = cards..','..v.id
					else
						cards = cards..','
					end
				end

			end
			-- print('****** ',cards)
			self:SendSignal(COMMANDS.COMMAND_TeamFormation, { teamId = self.clickTag,cards = cards})
		else
			print('*********** 没有做出改动 ***********')
			self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer_TeamFormation)
		end
	elseif name == SIGNALNAMES.TeamFormation_switchTeam_Callback then--编队卡牌切换
		-- print('*********** 编队卡牌切换 ***********')
		-- dump(signal:GetBody())

	elseif name == TeamFormationScene_UpdataUI then--编队刷新页面
		-- print('********** 编队刷新页面 ***********')
		local datas = self.allTeamsDatas[self.clickTag]
		for i=1,table.nums(self.Ttable) do
			local cell = self.Ttable[i]
			cell:refreshUI(datas.cards[i],self.showPet)
		end
	elseif name == SIGNALNAMES.IcePlace_AddCard_Callback then--将卡牌放入冰场处理
		if not signal:GetBody().errcode then
            gameMgr:SetCardPlace({}, {{id = signal:GetBody().newPlayerCard.playerCardId}}, CARDPLACE.PLACE_ICE_ROOM)
			uiMgr:ShowInformationTips(__('添加成功'))
		end
	elseif name == SIGNALNAMES.IcePlace_Home_Callback then
		local body = checktable(signal:GetBody())
		local icePlace = body.icePlace
		local countNum =  table.nums(icePlace)
		local restaurantMgr =  app.restaurantMgr
		local isHave = false
		for icePlaceId = 1 , countNum  do
			local icePlaceBed = icePlace[tostring(icePlaceId)].icePlaceBed or {}
			local icePlaceBedNum = checkint( icePlace[tostring(icePlaceId)].icePlaceBedNum)
			body.requestData.icePlaceId = icePlaceId
			if icePlaceBedNum > table.nums(icePlaceBed)  then
				isHave = true
			else
				for id , vigourData in pairs(icePlaceBed) do
					local maxVigour = restaurantMgr:getCardVigourLimit(id)
					if checkint(maxVigour) <=  checkint(vigourData.newVigour) then
						isHave = true
						break
					end
				end
			end
			if isHave then
				break
			end
		end
		if isHave then
			app:DispatchSignal(COMMANDS.COMMANDS_ICEPLACE, body.requestData)
		else
			app.uiMgr:ShowInformationTips(__('冰场已满'))
		end

	end
end

function TeamFormationMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.TeamFormationView' ).new({isCommon = self.isCommon})
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	if self.isCommon then
		viewComponent:setTag(self.teamFormationViewTag)
		scene:AddDialog(viewComponent)
	else
		scene:AddGameLayer(viewComponent)
	end
	self.Ttable = {}
	self.TClickTab = {}


	--初始化5个槽位
	local posY = display.size.height - 125-- viewComponent.viewData_.fight_num:getPositionY()
	local cellDistance = (display.SAFE_RECT.width-200)/ 5
	local cellSize = cc.size(1334/6, 630)
	for i=1,5 do
		local cell = require('Game.views.TeamFormationCellNew').new({size = cellSize, isCommon = self.isCommon})
		cell:setName('cell_'..i) 

		cell:setPosition(display.cx - 80 + (i - 3)*cellDistance  ,display.cy -60)
		viewComponent.viewData_.view:addChild(cell,10)

		cell.viewData.bgView:setTouchEnabled(true)
		cell.viewData.bgView:setTag(i)
		cell.viewData.bgView:setOnClickScriptHandler(handler(self,self.CellButtonAction))

		cell.viewData.bgHeroDes:setTouchEnabled(true)
		cell.viewData.modelBtn:setTag(i)
		cell.viewData.modelBtn:setOnClickScriptHandler(handler(self,self.ModelButtonActions))

		cell.viewData.teamCupImg:setTouchEnabled(true)
		cell.viewData.teamCupImg:setTag(i)
		cell.viewData.teamCupImg:setOnClickScriptHandler(handler(self,self.teamCupButtonActions))
		cell.viewData.lvBtn:setTouchEnabled(false)

		if i == 1 then
			-- local teamCaptainImg = display.newImageView(_res('ui/home/teamformation/team_ico_captain.png'), 0, 0)


			local teamCaptainImg = display.newButton(0,0,{n = _res('ui/home/teamformation/team_ico_captain.png')})
			cell.viewData.view:addChild(teamCaptainImg,50)
			teamCaptainImg:setAnchorPoint(cc.p(0.5,0))
			teamCaptainImg:setPosition(cc.p(44 ,cellSize.height - 75 ))

			teamCaptainImg:setTouchEnabled(true)
			teamCaptainImg:setOnClickScriptHandler(function(sender)
				uiMgr:ShowInformationTips(__('队长奖励：进入战斗时获得50能量'))
		    end)


			--cell.viewData.lvBtn:setNormalImage(_res('ui/home/teamformation/newCell/team_dengji_captain.png'))
			--cell.viewData.lvBtn:setSelectedImage(_res('ui/home/teamformation/newCell/team_dengji_captain.png'))
			--cell.viewData.lvBtn:getLabel():setPositionY(cell.viewData.lvBtn:getContentSize().height * 0.5 + 24)
			cell.viewData.lvBtn:setTexture(_res('ui/home/teamformation/newCell/team_dengji_captain.png'))
		end

		table.insert(self.Ttable, cell )
		table.insert(self.TClickTab, false )

		cell.viewData.view:setOpacity(0)
		cell.viewData.view:setPositionY(cell.viewData.view:getPositionY() - 100)
		cell.viewData.view:runAction(
				cc.Sequence:create(cc.DelayTime:create(i*0.05),
				cc.Spawn:create(cc.EaseBounceOut:create(cc.MoveBy:create(0.6, cc.p(0, 100)))
				,cc.FadeIn:create(0.5))--
			))

		cell.viewData.imgHero:setOpacity(0)
		cell.viewData.imgHero:runAction(cc.FadeIn:create(0.5))
	end


	-- viewComponent.belowBg:setPositionY(self.Ttable[1]:getPositionY() - 150)-- - self.Ttable[1]:getContentSize().height* 0.5

	self.viewComponent.viewData_.lookMessBtn:setOnClickScriptHandler(handler(self,self.LookMessBtnCallback))

end

--[[
显示切换卡牌灵力和名字
--]]
function TeamFormationMediator:LookMessBtnCallback(sender)
    PlayAudioByClickNormal()
	local checked = sender:isChecked()
	if not checked then
		self.viewComponent.viewData_.lookMessLabel:setString(__('查看属性'))
	else
		self.viewComponent.viewData_.lookMessLabel:setString(__('返回'))
	end
	for i,v in ipairs(self.allTeamsDatas[self.clickTag].cards) do
		if v.id then
			local CardData = gameMgr:GetCardDataById(v.id)
			local LocalCardData = CommonUtils.GetConfig('cards', 'card', CardData.cardId)

			local show = not checked-- self.Ttable[self.clickHeroTag].viewData.bgHeroMes:isVisible()

			self.Ttable[i].viewData.bgHeroMes:setVisible(not show)

			self.Ttable[i].viewData.bgJob:setVisible(show)
			self.Ttable[i].viewData.lvBtn:setVisible(show)
			self.Ttable[i].viewData.lvLabel:setVisible(show)
			self.Ttable[i].viewData.qualityImg:setVisible(show)

			self.Ttable[i].viewData.starlayout:setVisible(show)


			if next(LocalCardData.concertSkill) ~= nil then
				self.Ttable[i].viewData.teamCupImg:setVisible(show)
				self.Ttable[i].viewData.teamCupRank:setVisible(show)
			end
		end
	end
end




--[[
	刷新当前编队连携技情况
--]]
function TeamFormationMediator:checkTeamCupStutas()
	local showCup = false
	local tempTab = {}
	tempTab = self.allTeamsDatas[self.clickTag].cards
	for k,v in pairs(self.Ttable) do
		v.viewData.teamCupImg:setColor(cc.c4b(100, 100, 100, 100))
		if v.viewData.teamCupImg:getChildByTag(1) then
			v.viewData.teamCupImg:removeChildByTag(1)
		end
	end
	local tempNum = 0
	local cellTab = {}
	for i,v in ipairs(tempTab) do
		tempNum = 0
		if v.id then--判断当前编队位置是否有卡牌
			local CardData = gameMgr:GetCardDataById(v.id)
			for j,vv in ipairs(CommonUtils.GetConfig('cards', 'card', CardData.cardId).concertSkill) do--遍历该卡牌所对应有连携技的卡牌
				local tempBool = false
				for k,vvv in ipairs(clone(tempTab)) do--在重新遍历该编队看是否有匹配卡牌
					if vvv.id then--是否有卡牌
						local CardData = gameMgr:GetCardDataById(vvv.id)
						if checkint(CardData.cardId) == checkint(vv) then--找到对应卡牌id ，
							-- table.insert(cellTab,i)
							tempNum = tempNum + 1
						end
					end
				end
			end


			if tempNum == table.nums(CommonUtils.GetConfig('cards', 'card', CardData.cardId).concertSkill) then--出发连携技
				self.Ttable[i].viewData.teamCupImg:setColor(cc.c4b(255, 255, 255, 255))
				local size = self.Ttable[i].viewData.teamCupImg:getContentSize()
				local spineShine = sp.SkeletonAnimation:create(
					'battle/effect/connect_button_shine.json',
					'battle/effect/connect_button_shine.atlas',
					1.6)
				spineShine:update(0)
				self.Ttable[i].viewData.teamCupImg:addChild(spineShine, 11)
				spineShine:setPosition(cc.p(size.width * 0.5 + 2, size.height * 0.5 + 1))
				spineShine:setToSetupPose()
				spineShine:setAnimation(0, 'idle', true)

				spineShine:setTag(1)
			end
		end
	end
end

--查看连携技详情按钮
function TeamFormationMediator:teamCupButtonActions( sender )
    PlayAudioByClickNormal()
	local tag = sender:getTag()
	local cardTadas = {}
	local data = self.allTeamsDatas[self.clickTag].cards[tag]
	local cardData = gameMgr:GetCardDataById(data.id)

	cardTadas.cardId = cardData.cardId
	cardTadas.id = data.id
	cardTadas.tag = 1234

	local layer = require('Game.views.ShowConcertSkillMes').new(cardTadas)
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	layer:setTag(1234)
	uiMgr:GetCurrentScene():AddDialog(layer)
end

--功能模块按钮回调
function TeamFormationMediator:ModelCallback(datas)
	-- dump(datas.tag)
	if datas then
		local tag = datas.tag
		if tag ==  1 then--详情
			local data = self.allTeamsDatas[self.clickTag].cards[self.clickHeroTag]
			local CardData = gameMgr:GetCardDataById(data.id)
			local LocalCardData = CommonUtils.GetConfig('cards', 'card', CardData.cardId)

			local show = self.Ttable[self.clickHeroTag].viewData.bgHeroMes:isVisible()
			self.Ttable[self.clickHeroTag].viewData.bgHeroMes:setVisible(not show)

			self.Ttable[self.clickHeroTag].viewData.bgHeroMes:setTag(self.clickHeroTag)
			self.Ttable[self.clickHeroTag].viewData.bgHeroMes:setTouchEnabled(true)
			self.Ttable[self.clickHeroTag].viewData.bgHeroMes:setOnClickScriptHandler(function(sender)


		    end)

			self.Ttable[self.clickHeroTag].viewData.bgJob:setVisible(show)
			self.Ttable[self.clickHeroTag].viewData.lvBtn:setVisible(show)
			self.Ttable[self.clickHeroTag].viewData.qualityImg:setVisible(show)

			self.Ttable[self.clickHeroTag].viewData.starlayout:setVisible(show)


			if next(LocalCardData.concertSkill) ~= nil then
				self.Ttable[self.clickHeroTag].viewData.teamCupImg:setVisible(show)
				self.Ttable[self.clickHeroTag].viewData.teamCupRank:setVisible(show)
			end
		elseif tag == 2 then--强化
	    	self.viewComponent:runAction(cc.Sequence:create(
	        	cc.DelayTime:create(0.3),
			   	cc.CallFunc:create(function ()
					self:showHeroButtonAction()
				end)))
		elseif tag == 3 then--冰箱
            PlayAudioByClickNormal()
			local data = self.allTeamsDatas[self.clickTag].cards[self.clickHeroTag]
			app:DispatchSignal(COMMANDS.COMMANDS_ICEPLACE_HOME,{ playerCardId = data.id})
			--AppFacade.GetInstance():DispatchSignal(COMMANDS.COMMANDS_ICEPLACE, {icePlaceId = 1, playerCardId = data.id})
		elseif tag == 4 then--未开放
            PlayAudioByClickNormal()
			uiMgr:ShowInformationTips(__('更多功能敬请期待'))
		end
	end

	self.Ttable[self.clickHeroTag].viewData.modelBtn:setChecked(false)

end

--选择卡牌后回调
function TeamFormationMediator:chooseHeroCallBack(data)
	if data.id then
		if GuideUtils.IsGuiding() then
			self:DoChangeCardUI(data)
		else
			local cell = self.Ttable[self.clickHeroTag]
			local btnSpine = sp.SkeletonAnimation:create('effects/chooseBattle/bd2.json', 'effects/chooseBattle/bd2.atlas', 1)
			btnSpine:update(0)
			btnSpine:setAnimation(0, 'play', false)--shengxing1 shengji
			cell:getParent():addChild(btnSpine,100)
			btnSpine:setPosition(cell:getPosition())
			-- btnSpine:setPosition(cc.p(heroImg:getContentSize().width* 0.25,heroImg:getContentSize().height* 0.55))

			btnSpine:registerSpineEventHandler(function (event)
				self:DoChangeCardUI(data)
			end,sp.EventType.ANIMATION_EVENT)
		end
	else
		self:DoChangeCardUI(data)
	end
	PlayAudioClip(AUDIOS.UI.ui_duiwu_sz.id)
end

--选择卡牌后数据处理
function TeamFormationMediator:DoChangeCardUI(data)
	local index = 0
	local isIn = false
	local HeroIndex = 0
	if data.id then
		if gameMgr.userInfo.operationTeamFormation then
			for k,v in ipairs(gameMgr.userInfo.operationTeamFormation) do
				for cardIndex, cardData in ipairs(v.cards) do
					if checkint(cardData.id) == checkint(data.id) then
						isIn = true
						index = k
						HeroIndex = cardIndex
						break
					end
				end
			end
		end
	end
	if isIn then
		if self.clickTag == index then--操作为同一编队
			local cell = self.Ttable[HeroIndex]
			cell:refreshUI({id = nil},self.showPet)
		else
			if self.allTeamsDatas[index].cards[HeroIndex].id then
				gameMgr:DeleteTempFormationDataById(self.allTeamsDatas[index].cards[HeroIndex].id)
			end
		end
	end
	if self.allTeamsDatas[self.clickTag].cards[self.clickHeroTag].id then
		gameMgr:DeleteTempFormationDataById(self.allTeamsDatas[self.clickTag].cards[self.clickHeroTag].id)
	end
    gameMgr:UpdateTeamInfo({id = data.id}, self.clickTag, self.clickHeroTag)

	local cell = self.Ttable[self.clickHeroTag]
	cell:refreshUI(data,self.showPet)
	self:updataFightScore()
	self:checkTeamCupStutas()
	self:updataTeamImg()
    xTry(function()
        CommonUtils.PlayCardSoundByCardId(data.cardId,SoundType.TYPE_TEAM)
    end,__G__TRACKBACK__)
	GuideUtils.DispatchStepEvent()
end


--功能强化按钮
function TeamFormationMediator:showHeroButtonAction()
    PlayAudioByClickNormal()
	local data = self.allTeamsDatas[self.clickTag].cards[self.clickHeroTag]
	local tempEqual = true
	for k,v in pairs(gameMgr:GetUserInfo().teamFormation[self.clickTag].cards) do
		if v then
			if self.allTeamsDatas[self.clickTag].cards[k] then
				if checkint(self.allTeamsDatas[self.clickTag].cards[k].id) ~= checkint(v.id) then
					tempEqual = false
					break
				end
			else
				tempEqual = false
				break
			end
		else
			if self.allTeamsDatas[self.clickTag].cards[k] then
				tempEqual = false
				break
			end
		end
	end
	if tempEqual == false then
		self.goMessAndChange = true
		local cards = ''
		for k,v in pairs(self.allTeamsDatas[self.clickTag].cards) do
			if k == 1 then
				if v.id then
					cards = v.id
				else
					cards = ' '
				end
			else
				if v.id then
					cards = cards..','..v.id
				else
					cards = cards..','
				end
			end

		end
		self:SendSignal(COMMANDS.COMMAND_TeamFormation, { teamId = self.clickTag,cards = cards})
	else
		local cardData = gameMgr:GetCardDataById(data.id)
		self:GetFacade():RetrieveMediator("Router"):Dispatch({name = "TeamFormationMediator"},
				{name = "CardsListMediatorNew",params = {isFrom = 'TeamFormationMediator',cardId = cardData.cardId}},{isBack = true})
	end
end



--[[
列表的单元格展开功能模块按钮的事件处理逻辑
@param sender button对象
--]]
function TeamFormationMediator:ModelButtonActions( sender )
    PlayAudioByClickNormal()
	if gameMgr:isInDeliveryTeam(self.clickTag) then
		uiMgr:ShowInformationTips(__('该飨灵正在配送外卖中。'))
		sender:setChecked(false)
		return
	end

	
	-- if gameMgr:CheckTeamState(self.clickTag,CARDPLACE.PLACE_EXPLORATION) or gameMgr:CheckTeamState(self.clickTag,CARDPLACE.PLACE_EXPLORE_SYSTEM) then
	-- 	uiMgr:ShowInformationTips(__('该飨灵正在探索中。'))
	-- 	sender:setChecked(false)
	-- 	return
	-- end

	local tag = sender:getTag()
	self.clickHeroTag = tag
	local data = self.allTeamsDatas[self.clickTag].cards[tag]

	local scene = uiMgr:GetCurrentScene()
	local pos = sender:convertToWorldSpace(utils.getLocalCenter(sender))
	if tag == 1 then
		pos.x = pos.x + 50
		pos.y = pos.y + 50
	end
	local TeamFormationModelView = require( 'Game.views.TeamFormationModelView' ).new(clone({id = data.id,pos = pos,tag = tag}))
	TeamFormationModelView:setPosition(display.center)
	scene:AddDialog(TeamFormationModelView)
end
--[[
列表的单元格按钮的事件处理逻辑
@param sender button对象
--]]
function TeamFormationMediator:CellButtonAction( sender )
    PlayAudioByClickNormal()
	if gameMgr:isInDeliveryTeam(self.clickTag) then
		uiMgr:ShowInformationTips(__('该编队正在配送外卖中。不能编辑'))
		return
	end
	
	-- if gameMgr:CheckTeamState(self.clickTag,CARDPLACE.PLACE_EXPLORATION) or gameMgr:CheckTeamState(self.clickTag,CARDPLACE.PLACE_EXPLORE_SYSTEM) then
	-- 	uiMgr:ShowInformationTips(__('该飨灵正在探索中。'))
	-- 	return
	-- end


	local tag = sender:getTag()
    -- if tag == 5 and GuideUtils.IsGuiding() then
    --     return
    -- end
	self.clickHeroTag = tag
	local scene = uiMgr:GetCurrentScene()
	if scene:GetDialogByTag(9999) == nil and self.allTeamsDatas[self.clickTag].cards[tag] then
		local tempData = self.allTeamsDatas[self.clickTag].cards[tag]
		tempData.callback = handler(self, self.chooseHeroCallBack)
		tempData.clickHeroTag = tag
		tempData.teamId = self.clickTag
		local ChooseBattleHeroView  = require( 'Game.views.ChooseBattleHeroView' ).new(tempData)
		ChooseBattleHeroView:setName('ChooseBattleHeroView')
		ChooseBattleHeroView:RefreshUI()
		ChooseBattleHeroView:setPosition(display.center)
		ChooseBattleHeroView:setTag(9999)
		scene:AddDialog(ChooseBattleHeroView)
		GuideUtils.DispatchStepEvent()
		ChooseBattleHeroView.eaterLayer:setOnClickScriptHandler(function (sender)
	    	--关闭页面
	    	if scene:GetDialogByTag(9999) then
				scene:RemoveDialogByTag(9999)
		    end

    	end)
	end

end


function TeamFormationMediator:UnLockTeamLayer(tag)
	-- body
	local bgView = self.viewComponent
	local listView = self.viewComponent.viewData_.listView
	if bgView:getChildByTag(99999) then
		bgView:getChildByTag(99999):removeFromParent()
	end
	if bgView:getChildByTag(99998) then
		bgView:getChildByTag(99999):removeFromParent()
	end

	local data = CommonUtils.GetConfig('player','teamUnlock',tag)
	if checkint(data.id) > table.nums(self.allTeamsDatas) + 1 then
		uiMgr:ShowInformationTips(string.fmt(__('需先解锁第_num_编队'),{_num_ = table.nums(self.allTeamsDatas) + 1}))
		return
	end

 	local unlockData = {}
	if data then
		for k,v in pairs(CommonUtils.GetConfig('player','teamUnlock',tag).unlockType) do
			unlockData.unlockType = checkint(k)
			unlockData.unlockNums = checkint(v.targetNum)
		end
	end

	local view = CColorView:create(cc.c4b(100, 200, 200, 0))
	view:setTouchEnabled(true)
	view:setContentSize(cc.size(display.width,display.height))
	view:setAnchorPoint(cc.p(0, 0))
	view:setTag(99999)
	bgView:addChild(view,1000)


	local showView = CLayout:create()
	showView:setTag(99998)
	showView:setAnchorPoint(cc.p(1, 0.5))
	local point = self.TteamBtn[tag]:convertToWorldSpace(cc.p(0,0))
    -- local x = listView:getPositionX() - listView:getContentSize().width
	showView:setPosition(cc.p(point.x,point.y + 45))
 	local bg = display.newImageView(_res('ui/home/teamformation/team_lock_bg.png'),0 , 0 ,
	{ap = cc.p(0.5, 0.5), enable = true})
	local bgSize = bg:getContentSize()
	bg:setPosition(cc.p(bgSize.width * 0.5, bgSize.height * 0.5))
	showView:setContentSize(bgSize)

	bgView:addChild(showView,10001)
	showView:addChild(bg)

	local desBtn = display.newButton( bgSize.width * 0.5 - 15, bgSize.height - 20,{n = _res('ui/common/common_title_2.png'),
		enable = false,ap = cc.p(0.5, 0.5)})
	display.commonLabelParams(desBtn, {text = __('解锁方式'), fontSize = 20, color = '473227',offset = cc.p(0,0)})
	showView:addChild(desBtn)
	local temp_str = ''
	local isLock = true
	if unlockData.unlockType == 1 then
		if unlockData.unlockNums then
			temp_str =  string.fmt(__('等级达到_level_级'),{_level_ = unlockData.unlockNums})
			if gameMgr:GetUserInfo().level >= unlockData.unlockNums then
				isLock = false
			end
		end
		self.useDiamond = 0
	elseif unlockData.unlockType == 3 then
		if unlockData.unlockNums then
			temp_str = string.fmt(__('消耗幻晶石 _value_'),{_value_ = unlockData.unlockNums})
			if gameMgr:GetUserInfo().diamond >= unlockData.unlockNums then
				isLock = false
			end
		end
		self.useDiamond = unlockData.unlockNums
	end


	local tempBtn = display.newButton( bgSize.width * 0.5 - 15, bgSize.height * 0.5,{n = _res('ui/home/teamformation/team_lock_btn_unlock_default.png'),
		enable = true,ap = cc.p(0.5, 0.5)})
	display.commonLabelParams(tempBtn, {ttf = true, font = TTF_GAME_FONT, text = temp_str, fontSize = 24, color = '473227',offset = cc.p(0,0)})
	showView:addChild(tempBtn)

	if isLock then
		tempBtn:setTouchEnabled(false)
		tempBtn:setNormalImage(_res('ui/home/teamformation/team_lock_btn_unlock_disabled.png'))
	else
		tempBtn:setOnClickScriptHandler(function(sender)
            PlayAudioByClickNormal()
			self:SendSignal(COMMANDS.COMMAND_TeamFormation_UnLock,{teamId = table.nums(self.allTeamsDatas) + 1})
			self.viewComponent:getChildByTag(99998):removeFromParent()
			self.viewComponent:getChildByTag(99999):removeFromParent()
		end)
	end

	view:setOnClickScriptHandler(function(sender)
		self.viewComponent:getChildByTag(99998):removeFromParent()
		self.viewComponent:getChildByTag(99999):removeFromParent()
	end)

end

--[[
滑动层编队里按钮的时间处理逻辑
@param sender button对象
--]]
function TeamFormationMediator:ButtonActions( sender )
    if tolua.type(sender) == 'ccw.CButton' then
        PlayAudioByClickNormal()
    end
	local tag = 0
	if type(sender) == 'number' then
		tag = sender
	else
		tag = sender:getTag()
		if #self.allTeamsDatas >= tag then
			sender:getLabel():setVisible(true)
		end
	end
	local datas = self.allTeamsDatas[tag]

	if not datas  then--未解锁
		self:UnLockTeamLayer(tag)
		return
	end
	--点击已经点击过的
	if  self.clickTag == tag then
		return
	end

	if gameMgr:isInDeliveryTeam(tag) then
		self.viewComponent.viewData_.takeWayView:setVisible(true)
		self.viewComponent.viewData_.takeWayQimg:setTexture(_res('ui/home/teamformation/team_ico_takeout.png'))
		self.viewComponent.viewData_.takeWayLabel:getLabel():setString(__('该队伍正在配送外卖中'))
	elseif gameMgr:CheckTeamState(tag,CARDPLACE.PLACE_EXPLORATION) then
		self.viewComponent.viewData_.takeWayView:setVisible(true)
		self.viewComponent.viewData_.takeWayQimg:setTexture(_res('ui/home/teamformation/team_ico_explore.png'))
		self.viewComponent.viewData_.takeWayLabel:getLabel():setString(__('该队伍正在探索中'))
	else
		self.viewComponent.viewData_.takeWayView:setVisible(false)
	end


	local layoutViewData = self.TteamLayout[tag]
	if self.clickBtn then
		local preTag =  self.clickBtn:getTag()
		local preLatoutViewData = self.TteamLayout[preTag]
		display.commonLabelParams(preLatoutViewData.teamLabel, {color = fontWithColor('11').color})
		if preLatoutViewData.chooseImg and (not tolua.isnull(preLatoutViewData.chooseImg)) then
			preLatoutViewData.chooseImg:setVisible(false)
		end
	end
	if type(sender) ~= 'number' then
		self.clickBtn = sender
		display.commonLabelParams(layoutViewData.teamLabel, {color = fontWithColor('9').color})
		if layoutViewData.chooseImg and (not tolua.isnull(layoutViewData.chooseImg)) then
			layoutViewData.chooseImg:setVisible(true)
		end
	end
	if type(sender) ~= 'number' then
		local tempEqual = true
		for k,v in pairs(gameMgr:GetUserInfo().teamFormation[self.clickTag].cards) do
			if v then
				if self.allTeamsDatas[self.clickTag].cards[k] then
					if checkint(self.allTeamsDatas[self.clickTag].cards[k].id) ~= checkint(v.id) then
						tempEqual = false
						break
					end
				else
					tempEqual = false
					break
				end
			else
				if self.allTeamsDatas[self.clickTag].cards[k] then
					tempEqual = false
					break
				end
			end
		end
		self.backHome = false
		if tempEqual == false then
			local cards = ''
			for k,v in pairs(self.allTeamsDatas[self.clickTag].cards) do
				if k == 1 then
					if v.id then
						cards = v.id
					else
						cards = ' '
					end
				else
					if v.id then
						cards = cards..','..v.id
					else
						cards = cards..','
					end
				end

			end
			-- print('****** ',cards)
			self:SendSignal(COMMANDS.COMMAND_TeamFormation, { teamId = self.clickTag,cards = cards})
		else
			-- print('*********** 没有做出改动 ***********')
		-- 	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer_TeamFormation)
		end
	end

	self.clickTag = tag
	self.showPet = false
	if datas then--解锁
		for i=1,table.nums(self.Ttable) do
			local cell = self.Ttable[i]
			cell:refreshUI(datas.cards[i],self.showPet)
		end
	end
	self:updataFightScore()
	self:checkTeamCupStutas()
	self.viewComponent.viewData_.lookMessBtn:setChecked(false)
	self.viewComponent.viewData_.lookMessLabel:setString(__('查看属性'))
	-- self:updataTeamImg()
end

function TeamFormationMediator:enterLayer(  )
	gameMgr:GetUserInfo().operationTeamFormation = {}
	gameMgr:GetUserInfo().operationTeamFormation = clone(gameMgr:GetUserInfo().teamFormation)
	self.allTeamsDatas = (gameMgr:GetUserInfo().operationTeamFormation or {})
	self.TteamBtn = {}
	self.TteamLayout = {}
	local tempCellTab = {}
	local cellSize = cc.size(172,150)
	local listView =  self.viewComponent.viewData_.listView
	local containerSize = cc.size(cellSize.width , cellSize.height * 6 + 150 )
	listView:setContainerSize(containerSize)
	listView:setDragable(true)

	--初始化编队列表
	local maxTeamNums = table.nums(CommonUtils.GetConfigAllMess('teamUnlock', 'player')) or ORGANIZE_MAX
	local layout = display.newLayer(0,0,{ ap = display.CENTER_TOP , size = cc.size(cellSize.width , cellSize.height*6)})
	local listContainer = listView:getContainer()
	listContainer:addChild(layout)
	layout:setPosition(cc.p(cellSize.width/2 ,cellSize.height * 6 + 150))
	for i = 1, maxTeamNums do
		local height = cellSize.height * (maxTeamNums+1 - i-0.5)
		local width = cellSize.width/2+4
		local btn = display.newButton(width, height + cellSize.height * 0.5 , {n = _res('ui/home/teamformation/newCell/team_frame_touxiangkuang.png'),
		s = _res('ui/home/teamformation/newCell/team_frame_touxiangkuang.png'), ap = display.CENTER_TOP , enable = true 
		})
		layout:addChild(btn,1)
		btn:setTag(i)
		btn:setOnClickScriptHandler(handler(self,self.ButtonActions))
		-- 第编队
		local teamLabel = display.newLabel(width , height - 50 , fontWithColor(11,{text =  string.fmt(__('第_index_小队'),{_index_ = i}),offset = cc.p(0,-66)}))
		layout:addChild(teamLabel , 11)
		local btnSize = btn:getContentSize()
		local showImg = display.newImageView(_res('ui/home/teamformation/newCell/team_img_biaoji.png'),width , height+22)
		layout:addChild(showImg,2)
		
		local chooseImg = display.newImageView(_res('ui/home/teamformation/newCell/team_img_touxiangkuang_xuanzhong.png'),width , height+20)
		chooseImg:setVisible(false)
		layout:addChild(chooseImg,3)

		local lineImg = display.newImageView(_res('ui/home/teamformation/newCell/team_img_touxiangkuang_line.png'),cellSize.width/2 , height - 60)
		layout:addChild(lineImg,4)

		  --新货的
		local newImg = display.newImageView(_res('ui/common/common_ico_red_point.png'),
		(width - btnSize.width)/2, height + btnSize.height/2,
		{ap = display.LEFT_TOP}
		)
		layout:addChild(newImg , 6)

		newImg:setVisible(false)

	    if app.badgeMgr:IsShowRedPointForUnLockTeam() then
	    	local num = table.nums(gameMgr:GetUserInfo().teamFormation) + 1
	    	if i == num then
	    		newImg:setVisible(true)
	    	end
	    end

		if i == self.jumpTeamIndex then
			self:ButtonActions(i)
			chooseImg:setVisible(true)
			display.commonLabelParams(teamLabel,{color = fontWithColor('9').color})
			self.clickBtn = btn
		end

		local tempBtn = display.newButton(0, 0, {n = _res('ui/cards/propertyNew/card_bar_bg.png'),
			s = _res('ui/cards/propertyNew/card_bar_bg.png')
			,scale9 = true,size = cc.size(100,30)
			})
		display.commonUIParams(tempBtn , {po = cc.p(width , height  ) , ap = display.CENTER_BOTTOM})
		layout:addChild(tempBtn,10)

		local tempBtnSize = tempBtn:getContentSize()
		local tempLabel = display.newLabel(width, height +15 ,{text =  __('外卖中'),fontSize = 20, color = 'ff8420'})
		layout:addChild(tempLabel,11)


		if #self.allTeamsDatas < i then
			showImg:setTexture(_res('ui/common/common_ico_lock.png'))
			tempBtn:setVisible(false)
			tempLabel:setVisible(false)
		else
			if gameMgr:isInDeliveryTeam(i) then
				tempBtn:setVisible(true)
				tempLabel:setVisible(true)
				tempLabel:setString(__('外卖中'))
			else
				tempBtn:setVisible(false)
				tempLabel:setVisible(false)
			end
		end
		self.TteamLayout[#self.TteamLayout+1] = {
			btn = btn , 
			teamLabel = teamLabel , 
			chooseImg = chooseImg , 
			lineImg = lineImg , 
			newImg = newImg , 
			showImg = showImg , 
			tempBtn = tempBtn , 
			tempLabel = tempLabel , 
		}
		table.insert(self.TteamBtn,btn)
	end 
	listView:setContentOffsetToTop()

	-- listView:setVisible(false)
	--进入编队页面选择编队部分执行动画
	--背景
	self.viewComponent.viewData_.ListBg:setScaleY(0)
	for i=1,12 do
		self.viewComponent.viewData_.ListBg:runAction(cc.Sequence:create(cc.DelayTime:create(i*0.03),cc.CallFunc:create(function ()
			self.viewComponent.viewData_.ListBg:setScaleY(i*0.084)
			end)))
	end

	--顶部
	local posx = self.viewComponent.viewData_.lineUp:getPositionX()
	local posy = self.viewComponent.viewData_.lineUp:getPositionY()
	self.viewComponent.viewData_.lineUp:setPositionY(self.viewComponent.viewData_.lineDown:getPositionY())
	self.viewComponent.viewData_.lineUp:runAction( cc.MoveTo:create(0.38,cc.p(posx , posy)) )	
	layout:setOpacity(0)
	layout:setPositionY(layout:getPositionY() - 180)
	layout:runAction(
				cc.Sequence:create(cc.DelayTime:create(0.2),
				cc.Spawn:create(cc.MoveBy:create(0.3, cc.p(0, 180))
				,cc.FadeIn:create(0.5))--
			))
	self:updataTeamImg()
end


--[[
	刷新队伍队长图标
--]]
function TeamFormationMediator:updataTeamImg(  )
	for i,v in pairs(self.allTeamsDatas) do
		local teamBtn = self.TteamBtn[checkint(i)]
		local layoutViewData =  self.TteamLayout[teamBtn:getTag()]
		if teamBtn and (not tolua.isnull(teamBtn))  then
			local oneImage =  layoutViewData.showImg
			local twoImage =  layoutViewData.layoutViewData
			if v.cards[1].id then
				if oneImage then
					local CardData = gameMgr:GetCardDataById(v.cards[1].id)
					local skinId   = cardMgr.GetCardSkinIdByCardId(CardData.cardId)
					local headPath = CardUtils.GetCardHeadPathBySkinId(skinId)
					oneImage:setTexture(headPath)
					oneImage:setScale(0.53)
				end
				if cardMgr.GetCouple(v.cards[1].id) then
					if twoImage then
						twoImage:setVisible(true)
					else
						local teamBtnPos = cc.p(teamBtn:getPosition())
						local layout = teamBtn:getParent()
						local particleSpine = display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly_tx')
						particleSpine:setPosition(teamBtnPos.x , teamBtnPos.y)
						layout:addChild(particleSpine, 12)
						particleSpine:setAnimation(0, 'idle3', true)
						particleSpine:update(0)
						particleSpine:setToSetupPose()
						particleSpine:setTag(124)
						particleSpine:setScale(0.66)
					end
				else
					if twoImage then
						twoImage:setVisible(false)
					end
				end
			else
				if oneImage then
					oneImage:setTexture(_res('ui/home/teamformation/newCell/team_img_biaoji.png'))
					oneImage:setScale(1)
				end
				if twoImage then
					twoImage:setVisible(false)
				end
			end
		end
	end
end

--[[
	刷新战斗力数值
--]]
function TeamFormationMediator:updataFightScore(  )
	local fight_num =  self.viewComponent.viewData_.fight_num
	local tempNum = 0
	local tempTab = {}

	if next(self.allTeamsDatas) ~= nil then
		for i,v in ipairs(self.allTeamsDatas[self.clickTag].cards) do
			if table.nums(v) > 0 then
				table.insert(tempTab,v.id)
			end
		end
	end
	for k,v in ipairs(tempTab) do
		local CardData = gameMgr:GetCardDataById(v)
		local tab = cardMgr.GetCardStaticBattlePointById(checkint(v))
		tempNum = tempNum + tab
	end
	fight_num:setString(tostring(tempNum))
end
function TeamFormationMediator:OnRegist(  )
    if self.isCommon then
        --这里是跳转时的逻辑
    else
        self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
    end
	local TeamFormationCommand = require( 'Game.command.TeamFormationCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_TeamFormation, TeamFormationCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_TeamFormation_UnLock, TeamFormationCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_TeamFormation_switchTeam, TeamFormationCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_ICEPLACE, TeamFormationCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_ICEPLACE_HOME, TeamFormationCommand)

	-- fixed guide
	local cardTeamStepId = checkint(GuideUtils.GetModuleData(GUIDE_MODULES.MODULE_TEAM))
	if not GuideUtils.IsGuiding() and cardTeamStepId == 0 and not GuideUtils.CheckIsFirstTeamMember({dontShowTips = true}) then
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_LOBBY)
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_DRAWCARD)
		GuideUtils.SwitchModule(GUIDE_MODULES.MODULE_TEAM, 66)
	else
		GuideUtils.DispatchStepEvent()
	end
	self:enterLayer()
end
function TeamFormationMediator:OnUnRegist(  )
	-- 称出命令
	local scene = uiMgr:GetCurrentScene()
	if self.isCommon then
        --地图处弹加页面
		if scene and scene.RemoveDialogByTag then scene:RemoveDialogByTag(self.teamFormationViewTag) end
	else
		if scene and scene.RemoveGameLayer then scene:RemoveGameLayer(self.viewComponent) end
        self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	end
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_TeamFormation)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_TeamFormation_UnLock)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_TeamFormation_switchTeam)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_ICEPLACE)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_ICEPLACE_HOME)
    --更新下本地的缓存数据,旧的数据变新的数据
	-- gameMgr:SetCardPlace(gameMgr:getTeamAllCards(), gameMgr:getTeamAllCards(gameMgr:GetUserInfo().operationTeamFormation), CARDPLACE.PLACE_TEAM)
	AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
end

return TeamFormationMediator
