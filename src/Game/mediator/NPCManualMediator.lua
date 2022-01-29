local Mediator = mvc.Mediator

local NPCManualMediator = class("NPCManualMediator", Mediator)


local NAME = "NPCManualMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local NPCManualStoryListCell = require('home.NPCManualStoryListCell')
function NPCManualMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.datas = params or {} -- npc数据
	self.selectedStory = nil -- 选择的故事
	self.unlockDatas = {} -- 解锁的故事
end

function NPCManualMediator:InterestSignals()
	local signals = {
	}

	return signals
end

function NPCManualMediator:ProcessSignal(signal )
	local name = signal:GetName()
	print(signal:GetBody())
end

function NPCManualMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.NPCManualView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	viewComponent.viewData.backBtn:setOnClickScriptHandler(function (sender)
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator("NPCManualMediator")
    end)
    self:GetUnlockDatas()
	viewComponent.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAction))
	viewComponent.viewData.gridView:setCountOfCell(table.nums(self.datas.story))
    viewComponent.viewData.gridView:reloadData()
    viewComponent.viewData.roleBtn:setOnClickScriptHandler(handler(self, self.RoleButtonCallback))
    -- 刷新Ui
    viewComponent.viewData.descrLabel:setString(self.datas.descr)
    viewComponent.viewData.nameLabelBg:getLabel():setString(self.datas.roleName)
    local role = CommonUtils.GetRoleNodeById(self.datas.roleId, 1)
  	viewComponent.viewData.npcView:addChild(role, 10)
    local posData = CommonUtils.GetConfigAllMess('role','quest')[self.datas.roleId].takeaway
    role:setPosition(cc.p(posData.x, 1002 - posData.y))
    role:setScale(posData.scale/100)
end
function NPCManualMediator:OnDataSourceAction( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local viewData = self:GetViewComponent().viewData
    local cSize = cc.size(105, 262)

    if pCell == nil then
        pCell = NPCManualStoryListCell.new(cSize)
        pCell.bgBtn:setOnClickScriptHandler(handler(self, self.StoryButtonCallback))
        pCell.numIcon:setTexture(_res('ui/home/handbook/pokedex_card_ico_life_' .. tostring(index) .. '.png'))
    end
    xTry(function()
    	local isLock = true
    	for _,v in ipairs(self.unlockDatas) do
    		if checkint(v) == index then
    			isLock = false
    			break
    		end
    	end
    	pCell.bgBtn:setTag(index)
    	if isLock then
    		pCell.bgBtn:setEnabled(false)
    		pCell.lockIcon:setVisible(true)
    		pCell.lockMask:setVisible(true)
    		pCell.bgBtn:setNormalImage(_res('ui/home/handbook/pokedex_card_btn_life_lock.png'))
    	else
    		pCell.bgBtn:setEnabled(true)
    		pCell.lockIcon:setVisible(false)
    		pCell.lockMask:setVisible(false)
    		pCell.bgBtn:setNormalImage(_res('ui/home/handbook/pokedex_card_btn_life_default.png'))
    	end
	end,__G__TRACKBACK__)
    return pCell
end
--[[
获取剧情解锁列表
--]]
function NPCManualMediator:GetUnlockDatas()
	for i,v in ipairs(self.datas.story) do
		if not CommonUtils.CheckLockCondition(v.unlockType) then
			table.insert(self.unlockDatas, i)
		end
	end
end
--[[
故事列表点击回调
--]]
function NPCManualMediator:StoryButtonCallback( sender )
	-- 添加点击音效
	PlayAudioClip(AUDIOS.UI.ui_window_open.id)
	local tag = sender:getTag()
	local layer = require('Game.views.CardManualStoryView').new()
	layer:setTag(5000)
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = display.center})
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(layer)
	local viewData = layer.viewData_
	layer.eaterLayer:setOnClickScriptHandler(function()
		self.selectedStory = nil
		scene:RemoveDialog(layer)
	end)
	viewData.prevBtn:setOnClickScriptHandler(handler(self, self.StoryPageTurnCallBack))
	viewData.nextBtn:setOnClickScriptHandler(handler(self, self.StoryPageTurnCallBack))
	--------------------------------
	for i,v in ipairs(self.unlockDatas) do
		if checkint(v) == tag then
			self.selectedStory = i
			break
		end
	end
	--------------------------------
	self:StoryPageTurnAction()
end
--[[
切换故事按钮回调
--]]
function NPCManualMediator:StoryPageTurnCallBack( sender )
	-- 添加点击音效
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag == 2001 then -- 上翻
		if self.selectedStory <=1 then
			self:StoryPageTurnAction()
		else
			self.selectedStory = self.selectedStory - 1
			self:StoryPageTurnAction()
		end
	elseif tag == 2002 then -- 下翻
		if self.selectedStory >= table.nums(self.datas.story) then
			self:StoryPageTurnAction()
		else
			self.selectedStory = self.selectedStory + 1
			self:StoryPageTurnAction()
		end
	end
end
--[[
翻页事件
--]]
function NPCManualMediator:StoryPageTurnAction()
	local scene = uiMgr:GetCurrentScene()
	if not scene:GetDialogByTag( 5000 ) then return end
	local layer = scene:GetDialogByTag( 5000 )
	if self.selectedStory <= 1 and self.selectedStory >= table.nums(self.unlockDatas) then
		layer.viewData_.prevBtn:setVisible(false)
		layer.viewData_.nextBtn:setVisible(false)
	elseif self.selectedStory <= 1 then
		layer.viewData_.prevBtn:setVisible(false)
		layer.viewData_.nextBtn:setVisible(true)
	elseif self.selectedStory >= table.nums(self.unlockDatas) then
		layer.viewData_.prevBtn:setVisible(true)
		layer.viewData_.nextBtn:setVisible(false)
	else
		layer.viewData_.prevBtn:setVisible(true)
		layer.viewData_.nextBtn:setVisible(true)
	end
	self:RefreshStoryUi()
end
--[[
刷新故事页面Ui
--]]
function NPCManualMediator:RefreshStoryUi()
	local scene = uiMgr:GetCurrentScene()
	local layer = scene:GetDialogByTag( 5000 )
	local viewData = layer.viewData_
	local storyData = self.datas.story[checkint(self.unlockDatas[self.selectedStory])]
	viewData.title:getLabel():setString(storyData.name)
	local story = string.gsub(storyData.descr,'_name_', gameMgr:GetUserInfo().playerName)
	local descrLabel = display.newLabel(270, 0, {ap = cc.p(0.5, 0), w = 480, text = story, color = '#5b3c25', fontSize = 24})
	local descrCell = CLayout:create(cc.size(540, display.getLabelContentSize(descrLabel).height+5))
	descrCell:addChild(descrLabel)
	viewData.listView:removeAllNodes()
	viewData.listView:insertNodeAtLast(descrCell)
	local placeholderCell = CLayout:create(cc.size(540, 120))
	viewData.listView:insertNodeAtLast(placeholderCell)
	viewData.listView:setContentOffsetToTop()
	viewData.listView:reloadData()
end
--[[
立绘按钮回调
--]]
function NPCManualMediator:RoleButtonCallback( sender )
	-- 添加点击音效
	PlayAudioByClickNormal()
	local layer = require('Game.views.NPCManualDrawView').new(self.datas)
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = display.center})
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(layer)
	local viewData = layer.viewData_
	layer.eaterLayer:setOnClickScriptHandler(function()
		-- 添加点击音效
		PlayAudioByClickClose()
		layer:runAction(
			cc.Sequence:create(
				cc.FadeOut:create(0.2),
				cc.RemoveSelf:create()
			)
		)
	end)
	-- 动作
	layer:setOpacity(0)
	layer:runAction(cc.FadeIn:create(0.2))
end
function NPCManualMediator:OnRegist(  )
end
function NPCManualMediator:OnUnRegist(  )
	-- 称出命令
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end
return NPCManualMediator
