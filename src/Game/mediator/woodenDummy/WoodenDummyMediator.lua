local Mediator = mvc.Mediator
---@class WoodenDummyMediator :Mediator
local WoodenDummyMediator = class("WoodenDummyMediator", Mediator)
local NAME = "woodenDummy.WoodenDummyMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local dummyTypeConf = CommonUtils.GetConfigAllMess('dummyType' , 'player')
local dummyQuestConf = CommonUtils.GetConfigAllMess('dummyQuest' , 'player')
function WoodenDummyMediator:ctor( param, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.recommendIndex = self:GetRecommedIndex()
	self.preIndex = nil
	self.isAction = false
	self.dummyList = nil
	self.dummyData = {}
end
function WoodenDummyMediator:InterestSignals()
	local signals = {
		POST.PLAYER_DUMMYLIST.sglName ,
		POST.PLAYER_TEAM_DUMMYLIST.sglName
	}
	return signals
end

function WoodenDummyMediator:Initial( key )
	self.super.Initial(self,key)
	---@type WoodenDummyScene
	local  viewComponent = require('Game.views.woodenDummy.WoodenDummyScene').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local viewData = viewComponent.viewData
	viewData.navBack:setOnClickScriptHandler(handler(self, self.BackMediatorSaveData))
	uiMgr:SwitchToScene(viewComponent)
end

function WoodenDummyMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local data = signal:GetBody()
	if name == POST.PLAYER_TEAM_DUMMYLIST.sglName  then

		for i = 1, table.nums(dummyTypeConf) do
			self.dummyData[i] = {
				currentIndex = self.recommendIndex ,
				skill = {},
				cards = {}
			}
		end
		for index , v in pairs(data.teamList or {}) do
			local questType = checkint(index)
			if self.dummyData[questType] then
				self.dummyData[questType].cards = v.team
				self.dummyData[questType].skill = v.talents or {}
				self.dummyData[questType].currentIndex = self:GetIndexByQuestId(v.questId)
			end
		end
		local viewData = self.viewComponent.viewData
		self.countNum = table.nums(self.dummyData)
		viewData.tableView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSource))
		viewData.tableView:setCountOfCell(table.nums(self.dummyData))
		viewData.tableView:reloadData()
		viewData.recordBtn:setOnClickScriptHandler(handler(self, self.DummyRecodClick))
	elseif POST.PLAYER_DUMMYLIST.sglName then
		self.dummyList = data.dummyList or {}
		local mediator = require('Game.mediator.woodenDummy.WoodenDummyRecordMeidtor').new({
			dummyRecordsList = self.dummyList
		})
		app:RegistMediator(mediator)



	end
end
--[[
	获取到推荐的顺序
--]]
function WoodenDummyMediator:GetRecommedIndex()
	local index  = math.ceil(app.gameMgr:GetUserInfo().level /10)
	local maxIndex = 1
	-- 获取到挑战关卡的最大索引
	for i, v in pairs(dummyTypeConf) do
		maxIndex = table.nums(dummyTypeConf.stages)
		break
	end
	index = index - 3
	index = index > 0 and index or 1
	maxIndex = index >= maxIndex and maxIndex or index
	return index
end

function WoodenDummyMediator:GetIndexByQuestId(questId)
	questId = checkint(questId)
	local questOneConf = dummyQuestConf[tostring(questId)]
	local questType = questOneConf.type
	local stages = dummyTypeConf[tostring(questType)].stages
	local index = 1
	for i = 1 , #stages do
		if questId == checkint(stages[i]) then
			index = i
			break
		end
	end
	return index
end

function WoodenDummyMediator:GetQuesIdtByIndex(index)
	local stages = dummyTypeConf[tostring(self.preIndex)].stages
	local questId = stages[i]
	return questId
end
-- 退出保存数据
function WoodenDummyMediator:BackMediatorSaveData()
	if self.preIndex then
		---@type BattleScriptTeamMediator
		local mediator =  self:GetFacade():RetrieveMediator("BattleScriptTeamMediator")
		if mediator then
			self:GetFacade():UnRegsitMediator("BattleScriptTeamMediator")
		end
	end
	local router = app:RetrieveMediator("Router")
	router:Dispatch( {name = "woodenDummy.WoodenDummyMediator"},{name = "CardsListMediatorNew"})
end
--[[
	木人桩点击事件回调
--]]
function WoodenDummyMediator:DummyRecodClick(sender)
	if self.dummyList then
		local mediator = require('Game.mediator.woodenDummy.WoodenDummyRecordMeidtor').new({
			dummyRecordsList = self.dummyList
		})
		app:RegistMediator(mediator)
	else
		self:SendSignal(POST.PLAYER_DUMMYLIST.cmdName , {})
	end


end
--[[
   副本刷新操作
--]]
function WoodenDummyMediator:OnDataSource(p_convertview, idx)
	local index = idx +1
	---@type WoodeDummyCell
	local pcell = p_convertview
	if not  pcell then
		pcell = require("Game.views.woodenDummy.WoodenDummyCell").new()

	end
	xTry(function()
		pcell:UpdateCell(index)
		local currentIndex = checkint(self.dummyData[index].currentIndex)
		local questId = dummyTypeConf[tostring(index)].stages[currentIndex]
		local level =  dummyQuestConf[tostring(questId)].level or 40
		local text = string.fmt(__('等级：_lv_'), {_lv_ = level })
		if self.recommendIndex == self.dummyData[index].currentIndex then
			text = string.fmt(__('等级：_lv_(推荐)'), {_lv_ = level })
		end
		pcell:UpdateLabel(text)
		pcell.viewData.clickLayer:setTag(index)
		pcell.viewData.clickLayer:setOnClickScriptHandler(handler(self, self.CellButtonClick))
		pcell.viewData.chooseDifficultyLayout:setTag(self.dummyData[index].currentIndex)
		pcell.viewData.chooseDifficultyLayout:setOnClickScriptHandler(handler(self, self.SelectDifficultClick))
		pcell.viewData.subcontentLayout:setTag(index)

	end,__G__TRACKBACK__)
	return pcell
end


-- 选中某一个具体的选项
function WoodenDummyMediator:CellButtonClick(sender)
	local tag =  sender:getTag()
	local data = self.dummyData[tag] or {}
	PlayAudioByClickNormal()
	if self.isAction  then
		return
	end
	if data then
		if self.preIndex then
			if self.preIndex == tag then
				return
			end
			self:SetCellAction({index = self.preIndex , isAction = false})
			self.preIndex = nil
			---@type BattleScriptTeamMediator
			local mediator = self:GetFacade():RetrieveMediator("BattleScriptTeamMediator")
			if mediator then
				mediator:GetViewComponent():BottomRunAction(false)
				self.isAction = true
				uiMgr:GetCurrentScene():runAction(
					cc.Sequence:create(    -- 获取队列的动画展示
						cc.DelayTime:create(0.2) ,
						cc.CallFunc:create(function ( )
							self:GetFacade():UnRegsitMediator("BattleScriptTeamMediator")
						end),
						cc.CallFunc:create(function()
							self.isAction = false
						end)
					)
				)
			end
			return
		end
		local sendData = self:ProcessingSendData(data)
		local battleScriptTeamMediator = require("Game.mediator.BattleScriptTeamMediator")
		local mediator = battleScriptTeamMediator.new(sendData)
		self:GetFacade():RegistMediator(mediator)
		local viewComponent = mediator.viewComponent
		if viewComponent and (not tolua.isnull(viewComponent)) then
			viewComponent:BottomRunAction(true)
		end
		self:SetCellAction({index = tag , isAction = true})
		self.preIndex = tag
	end

end
--[[
传入参数 {
        isAction = false
        index = 1
    }
--]]
function WoodenDummyMediator:SetCellAction(data)
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	local cell = nil
	if not  data.pcell then
		cell =  viewData.tableView:cellAtIndex(data.index -1)
	else
		cell  = data.pcell
	end
	if cell and not  tolua.isnull(cell) then
		cell.viewData.bgImageChosen:setVisible(data.isAction)
		local cellLayout = cell:getChildByName("cellLayout")
		if data.isAction then
			cellLayout:runAction(cc.Sequence:create(
					cc.ScaleTo:create(0.1, 0.9),
					cc.ScaleTo:create(0.1, 1.05)
			) )
		else
			cellLayout:runAction(cc.Sequence:create(
					cc.ScaleTo:create(0.1, 0.95),
					cc.ScaleTo:create(0.1, 1)
			) )
		end

	end

end
--[[
    向BattleScriptTeamMediator 传输数据
--]]
function WoodenDummyMediator:ProcessingSendData(data)

	local teamData = { -- 加工具有的基本卡牌数据格式
		{},
		{},
		{},
		{},
		{},
	}
	local equipedPlayerSkills = { -- 加工具有的基本的技能的数据格式
		["1"] =  {},
		["2"] =  {}
	}
	if type ( data.cards) == "string" then
		data.cards = json.decode(data.cards)
	end
	for k , v in pairs ( data.cards or {}) do
		if teamData[checkint(k)] then
			teamData[checkint(k)].id = v
		end
	end
	if type ( data.skill) == "string" then
		data.skill = json.decode(data.skill)
	end
	for k , v in  pairs (data.skill or {}) do
		if equipedPlayerSkills[tostring(k)] then
			equipedPlayerSkills[tostring(k)].skillId = v
		end
	end
	local  needData = {
		teamData = teamData ,
		equipedPlayerSkills = equipedPlayerSkills ,
		attendLeftTimes = data.attendLeftTimes ,
		scriptType = 3,
		attendMaxTimes = data.attendMaxTimes ,
		callback = handler(self, self.BattleCallBack) ,-- 开启战斗的回调设置
		battleType = BATTLE_SCRIPT_TYPE.MATERIAL_TYPE
	}
	return needData
end
--[[
    战斗的回调
-- ]]
function WoodenDummyMediator:BattleCallBack(data)
	local mediator = self:GetFacade():RetrieveMediator("BattleScriptTeamMediator")
	if mediator then -- 如果存在就要删除战队编辑界面
		self:GetFacade():UnRegsitMediator("BattleScriptTeamMediator")
	end

	local questType = self.preIndex
	local questId = dummyTypeConf[tostring(questType)].stages[self.dummyData[self.preIndex].currentIndex]
	-- 阵容信息
	local  teamData = {}
	for k, v in pairs(data.cards) do
		teamData[checkint(k)] = checkint(v)
	end
	-- 选择的主角技信息
	local playerSkillData = {
		0, 0

	}
	for k , v in pairs( data.skill  or {}) do
		playerSkillData[checkint(k)] = v
	end
	-- 网络命令
	AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId =string.fmt("1002-M_num_-01" , {_num_ = questType}) })
	AppFacade.GetInstance():DispatchObservers("DOT_SET_LOG_EVENT" , {eventId =string.fmt("1002-M_num_-02" , {_num_ = questType}) })
	local serverCommand = BattleNetworkCommandStruct.New(
			POST.PLAYER_DUMMY_QUEST_AT.cmdName,
			{questId = questId},
			POST.PLAYER_DUMMY_QUEST_AT.sglName,
			POST.PLAYER_DUMMY.cmdName,
			{questId = questId , dummyType = self.preIndex ,playerCards = json.encode(teamData) ,talents = json.encode(playerSkillData)   },
			POST.PLAYER_DUMMY.sglName,
			nil,
			nil,
			nil
	)
	-- 跳转信息
	local fromToStruct = BattleMediatorsConnectStruct.New(
			NAME,
			NAME
	)
	-- 创建战斗构造器
	local battleConstructor = require('battleEntry.BattleConstructor').new()

	battleConstructor:InitStageDataByNormalEvent(
			checkint(questId),
			serverCommand,
			fromToStruct,
			teamData,
			playerSkillData
	)

	battleConstructor:OpenBattle()

end

--[[
选择按钮回调事件
-- ]]
function WoodenDummyMediator:SelectDifficultClick(sender)

	local parentNode = sender:getParent() -- 获取中部的Layout
	local childNode = sender:getChildByName("chooseDifficultyBtn")
	local index = parentNode:getTag()
	if self.preIndex ~= index then  --  如果不相同 就直接相当于选择其他页面
		self:CellButtonClick(parentNode)
		childNode:setChecked(false)
		return
	end
	childNode:setChecked(true)
	childNode:setEnabled(false)
	PlayAudioByClickNormal()
	local currentNode = childNode
	local selectLayer =  display.newLayer(display.cx , display.cy , { ap  = display.CENTER ,size = display.size  })
	uiMgr:GetCurrentScene():AddDialog(selectLayer)
	local swallyerLayer = display.newLayer(display.cx , display.cy ,
			{ ap  = display.CENTER , size = display.size, color = cc.c4b(0,0,0,0) , enable = true , cb = function ()
				childNode:setChecked(false)
				childNode:setEnabled(true)
				selectLayer:removeFromParent()
			end})
	selectLayer:addChild(swallyerLayer)
	local selectBgImage = display.newImageView(_res('ui/home/materialScript/material_selectlist_bg'))
	local selectBgImageSize = selectBgImage:getContentSize()
	selectBgImage:setPosition(cc.p(selectBgImageSize.width/2 ,selectBgImageSize.height/2))
	-- 选择的Layout
	local selectLayout = display.newLayer(selectBgImageSize.width/2 ,selectBgImageSize.height/2 , {
		ap = display.CENTER_BOTTOM,
		size = selectBgImageSize
	})
	selectLayout:addChild(selectBgImage)
	selectLayer:addChild(selectLayout)

	local  pos  = cc.p(currentNode:getPosition())
	pos = currentNode:getParent():convertToWorldSpace(pos)
	pos = cc.p(pos.x , pos.y + 25)
	selectLayout:setPosition(pos)


	local count = table.nums(dummyTypeConf[tostring(self.preIndex)].stages)
	local tableViewCellSize  = cc.size(250 , 70)
	local tableView = CTableView:create(cc.size(selectBgImageSize.width-20 ,selectBgImageSize.height -30 ) )
	tableView:setSizeOfCell(tableViewCellSize)
	tableView:setAutoRelocate(true)
	tableView:setDirection(eScrollViewDirectionVertical)
	tableView:setPosition(display.center)
	tableView:setCountOfCell(count)
	tableView:setAnchorPoint(cc.p(0.5,0.5))
	selectLayout:addChild(tableView)
	tableView:setPosition(selectBgImageSize.width/2 ,selectBgImageSize.height/2+5)
	tableView:setDataSourceAdapterScriptHandler(
		function(p_convertview, idx)
			local pcell = p_convertview 
			local index = idx +1
			if not  pcell then
				pcell = CTableViewCell:new()
				pcell:setContentSize(tableViewCellSize)

				local lineImage = display.newImageView(_res('ui/home/materialScript/material_selectlist_line'),  tableViewCellSize.width/2 , 0)
				pcell:addChild(lineImage)
				local lineImage = display.newImageView(_res('ui/home/materialScript/material_selectlist_line'),  tableViewCellSize.width/2 , tableViewCellSize.height)
				pcell:addChild(lineImage)
				local button = display.newButton(tableViewCellSize.width/2 ,tableViewCellSize.height/2, { size =tableViewCellSize  } )
				pcell:addChild(button)
				pcell.button = button
				local image = display.newImageView(_res("ui/home/materialScript/material_selectlist_label_chosen") ,  tableViewCellSize.width/2 , tableViewCellSize.height/2,{enable = false})
				pcell:addChild(image)
				image:setVisible(false)
				local label = display.newLabel(tableViewCellSize.width/2 ,tableViewCellSize.height/2 , {
					fontSize = 24 ,color = "#723737" , text = ""
				})
				pcell:addChild(label)
				pcell.label = label
				pcell.lineImage = lineImage
				pcell.image = image
			end
			xTry(function()

				local questId = dummyTypeConf[tostring(self.preIndex)].stages[index]
				local level =  dummyQuestConf[tostring(questId)].level or 40
				local text = string.fmt(__('等级：_lv_'), {_lv_ = level })
				if self.recommendIndex == index  then
					text = string.fmt(__('等级：_lv_(推荐)'), {_lv_ = level })
				end
				if self.dummyData[self.preIndex].currentIndex == index then
					pcell.image:setVisible(true)
				else
					pcell.image:setVisible(false)
				end
				pcell.label:setString(text)
				pcell.button:setTag(index)
				pcell.button:setOnClickScriptHandler(function (sender)
					local index = sender:getTag()
					self.dummyData[self.preIndex].currentIndex = index
					---@type WoodenDummyScene
					local viewComponent = self:GetViewComponent()
					local viewData = viewComponent.viewData
					---@type WoodeDummyCell
					local pcell =  viewData.tableView:cellAtIndex(self.preIndex -1 )
					if pcell and (not tolua.isnull(pcell)) then
						local questId = dummyTypeConf[tostring(self.preIndex)].stages[index]
						local level =  dummyQuestConf[tostring(questId)].level or 40
						local text = string.fmt(__('等级：_lv_'), {_lv_ = level })
						if self.recommendIndex == index  then
							text = string.fmt(__('等级：_lv_(推荐)'), {_lv_ = level })
						end
						pcell:UpdateLabel(text)
					end
					currentNode:setChecked(false)
					currentNode:setEnabled(true)
					viewComponent:runAction(cc.TargetedAction:create( selectLayer ,cc.RemoveSelf:create()  ))
					selectLayer:removeFromParent()
				end)
			end
			,__G__TRACKBACK__)
			return pcell
		end
	)

	tableView:reloadData()
end


--[[
    进入的时候材料副本的请求
--]]
function WoodenDummyMediator:EnterLayer()

	self:SendSignal(POST.PLAYER_TEAM_DUMMYLIST.cmdName , {})
end

function WoodenDummyMediator:OnRegist()
	regPost(POST.PLAYER_DUMMYLIST)
	regPost(POST.PLAYER_TEAM_DUMMYLIST)
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
	self:EnterLayer()
end

function WoodenDummyMediator:OnUnRegist()
	if self.viewComponent and not  tolua.isnull(self.viewComponent) then
		self.viewComponent:runAction(cc.RemoveSelf:create())
	end
	unregPost(POST.PLAYER_DUMMYLIST)
	unregPost(POST.PLAYER_TEAM_DUMMYLIST)
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")

end

return WoodenDummyMediator




