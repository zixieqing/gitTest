local Mediator = mvc.Mediator
---@class RobberyDetailMediator:Mediator
local RobberyDetailMediator = class("RobberyDetailMediator", Mediator)
local NAME = "RobberyDetailMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
function RobberyDetailMediator:ctor(param,viewComponent)
	self.super:ctor(NAME,viewComponent)
	if not  param then
		self.type  =1
	end
	local param = param or {}
	self.param = param
	self.data = {}
	self.robberyDetailView   = nil
	self.preIndex = 0
	self.privateOrder = CommonUtils.GetConfigAllMess('privateOrder','takeaway')
	self.publicOrder = CommonUtils.GetConfigAllMess('publicOrder','takeaway')
end
function RobberyDetailMediator:InterestSignals()
	local signals = { 
		SIGNALNAMES.RobberyDetailView_Name_Callback,
		SIGNALNAMES.RobberyOneDetailView_Name_Callback
		}

	return signals
end
function RobberyDetailMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == SIGNALNAMES.RobberyDetailView_Name_Callback then
        local robberyData = self:SortRobberyHistory(data)
		self.data = robberyData
		self:RefreshRobberyDetailView(self.data)
	elseif name == SIGNALNAMES.RobberyOneDetailView_Name_Callback then

		local robberyData = self:SortRobberyHistory(data)
		self.data = robberyData
		self:RefreshRobberyDetailView(self.data)
    end
end

--==============================--
--desc: 刷新打劫详情的界面
--time:2017-05-09 10:36:57
--@data:
--return 
--==============================--
function RobberyDetailMediator:RefreshRobberyDetailView(data)
	local isRunActionEnd = false  
	local returnNodeAction = function ( node , i  )
		local nodeSize = node:getContentSize()
		local mod = i % 2 == 0 and 2 or 1
		local endPos = cc.p(node:getPositionX(),node:getPositionY())
		node:setPosition(endPos)			

		local spawn = cc.CallFunc:create(function ( )
			node:setPosition(endPos)
		end)
		return spawn
	end
	local callback = function (i, isAction)

		if data[i].type == 2 then
			local mod = i % 2 == 0 and 2 or 1 
			data[i].takeawayId = data[i].takeawayId  or "1" 
			data[i].orderName = checkint(data[i].orderType )  == 1  and (self.privateOrder[data[i].takeawayId].name or " ") or (self.publicOrder[data[i].takeawayId].name or " ") 
			local cellView = self.viewComponent:createListCellView(mod , data[i])
			data[i].result = checkint(data[i].result) 
			data[i].createTime = checkint(data[i].createTime) 
			self.viewComponent.gainListView:insertNodeAtLast(cellView)
			if isAction then
				local actions =  returnNodeAction(cellView.contentView,i)
				cellView.contentView:runAction(actions)
			end

			if cellView.contentView then
				cellView.contentView:setTag(i)
				
				cellView.contentView:setOnClickScriptHandler(function (sender)
					local tag = sender:getTag()
					if self.preIndex  == tag then
						return 
					else
						 self.preIndex = tag
					end
					
					if 	not  self.robberyDetailView  then
						self.robberyDetailView = self.viewComponent:createOneRoberryDetailView()
						self.viewComponent.bgLayer:runAction(cc.MoveBy:create(0.2,cc.p(-50,0 )))
					else 
						self.robberyDetailView.bgLayout:stopAllActions()
						self.robberyDetailView.bgLayout:setVisible(false)
					end	
					--刷线某次防御的详情		
					self.viewComponent:updateOneRobberyDetailView(data[i],self.robberyDetailView )
					self.robberyDetailView.bgLayout:runAction(cc.Sequence:create(cc.DelayTime:create(0.2),cc.CallFunc:create(
						function ( )
							self.robberyDetailView.bgLayout:setVisible(true)
						end
					))) 
				end)
			end
		elseif data[i].type == 1 then
			local cellView = self.viewComponent:createListCellView(3 , data[i])
			self.viewComponent.gainListView:insertNodeAtLast(cellView)
			if isAction then
				local actions =  returnNodeAction(cellView.contentView ,i )
				cellView:runAction(actions)
			end
		end

	end
	local count= #data
	local cellNum = 5  
	if count < cellNum then
		for i =1 , count do 
			callback(i,true)
		end
		self.viewComponent.gainListView:reloadData()
	elseif count >= cellNum  then
		for i = 1 , cellNum do
			callback(i,true)
		end
		self.viewComponent.gainListView:reloadData()
		local readyNum = cellNum
		self.viewComponent.contentView:runAction(cc.Repeat:create(cc.Sequence:create(cc.DelayTime:create(0.05),cc.CallFunc:create(
			function ()
			 	readyNum = readyNum + 1
				callback(readyNum)
				-- if isRunActionEnd then
					if readyNum % 5 == 0 then
					 self.viewComponent.gainListView:reloadData()
					elseif readyNum == count then
						self.viewComponent.gainListView:reloadData()
					end			 
				-- end
				
			end
		)),count - cellNum))
	end
	
end
--==============================--
--desc:对打劫数据进行排序， 被打劫的放在最前面，打劫数据放在后面
--@param  data 属于打劫的总的数据
--time:2017-05-09 10:25:58
--@data:
--return 
--==============================--
function RobberyDetailMediator:SortRobberyHistory(data)
    local beRobberyTable = {} -- 被打劫数据表
	local robberyTable = {} --打劫数据表
	local robberyData  = clone(data.orders)

	for k , v in pairs(robberyData)  do 
		if v.type == 2 then 
			table.insert(beRobberyTable ,#beRobberyTable+1, v )
		elseif   v.type == 1 then 
			table.insert(robberyTable ,#robberyTable+1, v )
		end
	end
	local callback = function (a , b )
		a.createTime = a.createTime or 0 
		b.createTime = b.createTime or 0 
		if a.createTime < b.createTime then
			return true
		else 
			return false 
		end
	end
	table.sort(robberyTable ,callback  )
	table.sort(beRobberyTable ,callback  )
	local allRobberyData = clone(beRobberyTable)
	local count = #beRobberyTable
	for i =1 , #robberyTable do
		table.insert(allRobberyData , count+ i,robberyTable[i] )
	end
	return  allRobberyData
end
function RobberyDetailMediator:Initial( key )
	self.super.Initial(self,key)
	local viewComponent  = require( 'Game.views.RobberyDetailView' ).new()
	self:SetViewComponent(viewComponent)
	local tag  = 8888
	local scene =  uiMgr:GetCurrentScene()

	scene:AddDialog(viewComponent)
	viewComponent:setPosition(cc.p(display.width/2,display.height/2))
	viewComponent:setTag(tag)
	self.viewComponent = viewComponent
	self.viewComponent.contentView:setOnClickScriptHandler(function ()
		  	self.viewComponent.bgLayer:runAction(
    		cc.Sequence:create(
    			cc.EaseExponentialOut:create(
    				cc.ScaleTo:create(0.2, 1.1)
    			),
    			cc.ScaleTo:create(0.1, 1),
    			cc.TargetedAction:create(self.viewComponent, cc.RemoveSelf:create())
    		)
    	)
		AppFacade.GetInstance():UnRegsitMediator("RobberyDetailMediator")
	end)
end


function RobberyDetailMediator:ButtonActions( sender )
end
--[[
	进入本界面获取请求，刷新界面数据
--]]
function RobberyDetailMediator:EnterLayer()
	if self.type  == 1 then
		self:SendSignal(COMMANDS.COMMAND_RobberyDetailView_Name_Callback)
	end

end
function RobberyDetailMediator:OnRegist(  )
	local RobberyCommand  = require('Game.command.RobberyCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_RobberyDetailView_Name_Callback, RobberyCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_RobberyOneDetaiView_Name_Callback, RobberyCommand)
	self:EnterLayer()
end

function RobberyDetailMediator:OnUnRegist(  )	
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_RobberyDetailView_Name_Callback)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_RobberyOneDetaiView_Name_Callback)
end

return RobberyDetailMediator
