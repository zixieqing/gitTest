--[[
NPC图鉴主页面Mediator
--]]
local Mediator = mvc.Mediator

local NPCManualHomeMediator = class("NPCManualHomeMediator", Mediator)

local NAME = "NPCManualHomeMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local NPCManualRoleListCell = require('home.NPCManualRoleListCell')
function NPCManualHomeMediator:ctor( viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.NPCDatas = {} -- npd解锁数据
	self.unLockNum = 0 -- 解锁数目
end

function NPCManualHomeMediator:InterestSignals() 
	local signals = { 
	}
	return signals
end

function NPCManualHomeMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	print(name)
end


function NPCManualHomeMediator:Initial( key )
	self.super.Initial(self,key)
	local NPCManualHomeScene = uiMgr:SwitchToTargetScene('Game.views.NPCManualHomeScene')
	self:SetViewComponent(NPCManualHomeScene)
	self:ConvertNPCDatas()
	NPCManualHomeScene.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAction))
	NPCManualHomeScene.viewData.gridView:setCountOfCell(table.nums(self.NPCDatas))
    NPCManualHomeScene.viewData.gridView:reloadData()
    NPCManualHomeScene.viewData.collectionBg:getLabel():setString(string.fmt(__('收集进度 _num1_/_num2_'), {['_num1_'] = self.unLockNum, ['_num2_'] = table.nums(self.NPCDatas)}))

end
function NPCManualHomeMediator:OnDataSourceAction( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local viewData = self:GetViewComponent().viewData
    local cSize = viewData.listCellSize

    if pCell == nil then
        pCell = NPCManualRoleListCell.new(cSize)
        pCell.bgBtn:setOnClickScriptHandler(handler(self, self.ListCellCallback))
    end
    xTry(function()
    	pCell.bgBtn:setTag(index)
    	pCell.newIcon:setVisible(false)
    	if self.NPCDatas[index].isLock then
    		pCell.questionMark:setVisible(true)
    		pCell.nameLabel:setVisible(false)
    		pCell.role:setVisible(false)
    	else
    		pCell.questionMark:setVisible(false)
    		pCell.nameLabel:setVisible(true)
    		pCell.nameLabel:getLabel():setString(self.NPCDatas[index].roleName)
    		pCell.role:setVisible(true)
    		pCell.role:setTexture(string.format('arts/roles/cell/pokedex_npc_draw_%d.png', self.NPCDatas[index].id))
    	end
	end,__G__TRACKBACK__)
    return pCell
end
--[[
列表按钮点击回调
--]]
function NPCManualHomeMediator:ListCellCallback( sender )
	-- 添加点击音效
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if self.NPCDatas[tag].isLock then
		local unlockType = nil
		local targetNum = nil 
		for k,v in pairs(self.NPCDatas[tag].unlockType) do
			unlockType = k
			targetNum = v.targetNum
		end
		local unlockTypeDatas = CommonUtils.GetConfigAllMess('unlockType')
		local tips = string.gsub(unlockTypeDatas[unlockType], "_target_num_", targetNum)
		uiMgr:ShowInformationTips(__('现在还不认识这个人哦~' ).. tips)
	else
		local NPCManualMediator = require( 'Game.mediator.NPCManualMediator' )
		local mediator = NPCManualMediator.new(self.NPCDatas[tag])
		AppFacade.GetInstance():RegistMediator(mediator)
	end
end
--[[
转化NPC数据格式
--]]
function NPCManualHomeMediator:ConvertNPCDatas()
	local roleData = CommonUtils.GetConfigAllMess('role', 'collection')
	local unlockTypes = CommonUtils.GetConfigAllMess('unlockType')
	for _, v in orderedPairs(roleData) do
		v.isLock = CommonUtils.CheckLockCondition(v.unlockType)
		if not v.isLock then
			self.unLockNum = self.unLockNum + 1
		end
		v.roleName = CommonUtils.GetConfigAllMess('role','quest')[v.roleId].roleName
		table.insert(self.NPCDatas, v)
	end
end
function NPCManualHomeMediator:OnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
end

function NPCManualHomeMediator:OnUnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")

end
return NPCManualHomeMediator