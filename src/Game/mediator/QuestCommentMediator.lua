--[[
公告Mediator
--]]
local Mediator = mvc.Mediator
local QuestCommentMediator = class("QuestCommentMediator", Mediator)
local NAME = "QuestCommentMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local QuestCommentCell = require('home.QuestCommentCell')

function QuestCommentMediator:ctor(param, viewComponent )
	self.super:ctor(NAME, viewComponent)
	self.AnnoDatas = {}
	self.lock = param.lock
	self.stageTitleText = param.stageTitleText
	self.datas = {}
	self.preIndex = 1
	self.pageSize = 10 
	self.questId = param.stageId
	self.pageNum = 1
	self.discusstype = 2  
	self.totalPage = 0 
	self.cellView = nil 
	self.editbox = nil 
	self.viewTag = {
		leftButton = 20,
		rightButton = 21,
		hotComment = 2, 
		myComment  = 3,
		NewComment = 1,
		sendeMessage = 22
	}
	self.commmonlist = {}
	self.tableCell = {}
	self.praise = 1
end

function QuestCommentMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.QuestComment_Discuss,
		SIGNALNAMES.QuestComment_DiscussList,
		SIGNALNAMES.QuestComment_DiscussAct,
	}
	return signals
end
function QuestCommentMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	-- 创建MailPopup
	local tag = 5001
	local layer = require( 'Game.views.QuestCommentView' ).new({stageTitleText = self.stageTitleText})
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	layer:setTag(tag)
	scene:AddDialog(layer)
	self.layer = layer
	self:SetViewComponent(layer)
	-- dump(layer.viewData)
	local gridView = self.layer.viewData.gridView
	self.viewData  =  self.layer.viewData
	--左右翻页事件的添加
	local leftButton = self.viewData.leftButton
	leftButton:setOnClickScriptHandler(handler(self,self.TurnPageRightOrLeft))
	leftButton:setTag(self.viewTag.leftButton)
	local rightButton = self.viewData.rightButton
	rightButton:setOnClickScriptHandler(handler(self,self.TurnPageRightOrLeft))
	rightButton:setTag(self.viewTag.rightButton)
	self.editbox = self.viewData.editbox
	-- 拉取评论分类的监听事件
	for i = 1, #self.viewData.toggleTable do
		local toggleView = self.viewData.toggleTable[i]
		toggleView:setOnClickScriptHandler(handler(self,self.commentClick))
	end
	-- 给评论添加监听事件
	self.viewData.sendMessage:setOnClickScriptHandler(handler(self,self.setSendMessage))
	self:setCommentToggleViewStatus()
end
function QuestCommentMediator:setSendMessage(sender)
	self:clickDelay(sender) -- 设置按钮不能连续点击
	if string.len(self.editbox:getText()) == 0 or self.editbox:getText() == '' then
        
        uiMgr:ShowInformationTips(__('消息不能为空~'))
        return
    end
	if CommonUtils.CheckIsDisableInputDay() then
		return
	end
    local text = self.editbox:getText()
    if utf8len(text) > 120 then
        text = utf8sub(text,1,120)
    end
    self.editbox:setText('')
    local ntime = os.time()
    text = string.gsub(text,'\r\n','')
    text = string.gsub(text,'\n','')
	self:SendSignal(COMMANDS.COMMANDS_QuestComment_Disscuss,{questId = self.questId , content = text})
end
-- 切换按钮状态
function QuestCommentMediator:setCommentToggleViewStatus()
	for i = 1, #self.viewData.toggleTable do
		local toggleView = self.viewData.toggleTable[i]
		local data = toggleView.data
		local label = toggleView:getChildByTag(1)
		if data.tag == self.discusstype then
			toggleView:setChecked(true)
			toggleView:setNormalImage(_res('ui/map/comment/comment_tab_selected.png'))
			toggleView:setSelectedImage(_res('ui/map/comment/comment_tab_selected.png'))
			if label then
				label:setColor(ccc3FromInt(data.fontTable.selectStatus.color))
			end 
		else
			toggleView:setChecked(false)
			toggleView:setNormalImage(_res('ui/map/comment/comment_tab_unused.png'))
			toggleView:setSelectedImage(_res('ui/map/comment/comment_tab_selected.png'))
			if label then
				label:setColor(ccc3FromInt(data.fontTable.normalStatus.color))
			end 
		end
	end
end
function QuestCommentMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local data = signal:GetBody()
	if name == SIGNALNAMES.QuestComment_Discuss then
		uiMgr:ShowInformationTips(__('发表评论成功~'))
		if self.pageNum == 1 then
			local data =  {questId = self.questId,pageSize = self.pageSize,pageNum = self.pageNum,type = self.discusstype}
			self:SendSignal(COMMANDS.COMMANDS_QuestComment_DisscussList,data)
		end
	elseif name == SIGNALNAMES.QuestComment_DiscussList then
		self.totalPage = data["pageTotal"]
		self.layer.viewData.gridView:removeAllNodes()
		self.tableCell = {}
		self.commmonlist = data.discussions
		self:updateCheckPointLayout(data["pageTotal"])
		if table.nums(data.discussions) == 0 then
	        local layout = CLayout:create()
	        layout:setContentSize(self.layer.viewData.gridView:getContentSize())
	        layout:setBackgroundColor(cc.c4b(255,226,224,255))

	        local label = display.newLabel(layout:getContentSize().width/2, layout:getContentSize().height/2, {
	            fontSize = 24, color = '#4c4c4c', text = __('暂时没有评论哦~')})
	        layout:addChild(label)
	        self.layer.viewData.gridView:insertNodeAtLast(layout)
	        self.layer.viewData.gridView:reloadData()
	        return
    	end
		for i = 1 , #data.discussions do
			local cell = QuestCommentCell.new()
			table.insert(self.tableCell,#self.tableCell+1,cell) 
			local isEvenNum = i % 2
			if  i == 0  then
				isEvenNum = true 
			end
			data.mediator  = self 
			cell.thumbUp:setOnClickScriptHandler(handler(self,self.setUpdatethumbUp))
			cell:updateCellUI(data.discussions[i],isEvenNum)
			            
			self.layer.viewData.gridView:insertNodeAtLast(cell)
		end
		self.layer.viewData.gridView:reloadData()
	elseif name == SIGNALNAMES.QuestComment_DiscussAct then
		if tolua.isnull(self.cellView) then
			return
		end
		local seqTable = {}
		seqTable[#seqTable+1] = cc.ScaleTo:create(0.2,0.3)
		seqTable[#seqTable+1] = cc.ScaleTo:create(0.4,1.2)
		seqTable[#seqTable+1] = cc.ScaleTo:create(0.1,1)
		local seqAction = transition.sequence(seqTable)
		self.cellView.thumbUp:runAction(seqAction)
		self.cellView.data.upQty = self.cellView.data.upQty + 1 
		local text = self.cellView.data.upQty
		self.cellView.thumbUpNum:setString(text)
		self.cellView.thumbUp:setNormalImage(_res('ui/map/comment/comment_zan_red.png'))
		self.cellView = nil

	end
end
--点赞按钮事件
function QuestCommentMediator:setUpdatethumbUp(sender)

	self.cellView = sender:getParent():getParent()
	if  self.lock then
		uiMgr:ShowInformationTips(__('你还没有通关该关卡~'))
		return 		
	end
	if self.cellView.data.act ~= 0 then
		uiMgr:ShowInformationTips(__('你已经评论过这条了哦~'))
		return 
	end
	self.cellView.data.act = self.praise
    self:SendSignal(COMMANDS.COMMANDS_QuestComment_DisscussAct,{discussionId = self.cellView.data.discussionId , act = self.praise})
end
function QuestCommentMediator:updateCheckPointLayout(pageTotal)
	if pageTotal then
		self.layer.viewData.pageName:setString(string.format("%d/%d",checkint(self.pageNum),checkint(pageTotal)))
	end
end
-- 点击锁定按钮节点
function QuestCommentMediator:clickDelay(sender)
	sender:setEnabled(false)
	local callback = function ()
		sender:setEnabled(true)
	end
	local seqTable = {}
	seqTable[#seqTable+1]  = cc.DelayTime:create(0.25)
	seqTable[#seqTable+1]  = cc.CallFunc:create(callback)
	local seqAction = transition.sequence(seqTable)
	sender:runAction(seqAction)
end
--左右翻页事件
function QuestCommentMediator:TurnPageRightOrLeft (sender) 
	self:clickDelay(sender)
	local tag = sender:getTag()
	if self.totalPage ~=0 then
		if tag == self.viewTag.leftButton then
			if self.pageNum == 1 and  self.totalPage  ~= 0 then
				uiMgr:ShowInformationTips(__('已经是首页了哦~'))
				return
			end
			if self.pageNum > 1 then
				self.pageNum = self.pageNum -1
			end 
		end
		if tag == self.viewTag.rightButton then
			if self.pageNum == checkint(self.totalPage)  and  self.totalPage ~= 0 then
				uiMgr:ShowInformationTips(__('已经是最后一页了哦~'))
				return
			end
			if self.pageNum < self.totalPage then
				self.pageNum = self.pageNum + 1
			end 
		end
		self:SendSignal(COMMANDS.COMMANDS_QuestComment_DisscussList,{questId = self.questId ,pageNum = self.pageNum ,  pageSize = self.pageSize , type = self.discusstype})
	else
		return
	end
end
function QuestCommentMediator:commentClick(sender)  -- 评论点击事件
	local tag   = sender:getTag()
	if self.discusstype == tag then
		return 
	end
	self.pageNum = 1 
	self.discusstype = tag
	self:setCommentToggleViewStatus()
	dump({questId = self.questId ,pageNum = self.pageNum ,  pageSize = self.pageSize , type = self.discusstype})
	self:SendSignal(COMMANDS.COMMANDS_QuestComment_DisscussList,{questId = self.questId ,pageNum = self.pageNum ,  pageSize = self.pageSize , type = self.discusstype})
end

function QuestCommentMediator:EnterLayer()
	self:SendSignal(COMMANDS.COMMANDS_QuestComment_DisscussList,{questId = self.questId ,pageNum = self.pageNum ,  pageSize = self.pageSize , type = self.discusstype})
end

function QuestCommentMediator:OnRegist(  )
	local QuestCommentCommand = require( 'Game.command.QuestCommentCommand' )
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_QuestComment_Disscuss,QuestCommentCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_QuestComment_DisscussAct,QuestCommentCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_QuestComment_DisscussList,QuestCommentCommand)
	self:EnterLayer()
end

function QuestCommentMediator:OnUnRegist(  )
	            
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_QuestComment_Disscuss)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_QuestComment_DisscussAct)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_QuestComment_DisscussList)
	uiMgr:GetCurrentScene():RemoveDialogByTag(5001)
end

function QuestCommentMediator:GoogleBack()
	app:UnRegsitMediator(NAME)
	return false
end
return QuestCommentMediator








