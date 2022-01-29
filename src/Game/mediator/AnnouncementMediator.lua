--[[
公告Mediator
--]]
local Mediator = mvc.Mediator
local AnnouncementMediator = class("AnnouncementMediator", Mediator)
local NAME = "AnnouncementMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local AnnouncementCell = require('home.AnnouncementCell')
local ANNOTYPE = {
	announcement = 1, -- 公告类型
	activity     = 2  -- 活动类型
}
function AnnouncementMediator:ctor( viewComponent )
	self.super:ctor(NAME, viewComponent)
	self.AnnoDatas = {}
	self.datas = {}
	self.preIndex = 1
	self.type = ANNOTYPE.announcement
end

function AnnouncementMediator:InterestSignals()
	local signals = {
	SIGNALNAMES.Announcement_Name_Callback
}
return signals
end

function AnnouncementMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)

	if name == SIGNALNAMES.Announcement_Name_Callback then
		self.AnnoDatas = checktable(checktable(signal:GetBody()).notice)
		local viewData = self:GetViewComponent().viewData
		local gridView = viewData.gridView
		for i=#self.AnnoDatas,1,-1 do
			table.insert(self.datas, self.AnnoDatas[i])
		end
		if next(self.datas) ~= nil then
			self.viewComponent.viewData.emptyView:setVisible(false)
			self.viewComponent.viewData.cView:setVisible(true)
			gridView:setCountOfCell(table.nums(self.datas))
			self:updateDescription(self.preIndex)
			gridView:reloadData()
		else
			self.viewComponent.viewData.emptyView:setVisible(true)
			self.viewComponent.viewData.cView:setVisible(false)
		end
	end
end

function AnnouncementMediator:Initial( key )
	self.super.Initial(self, key)
	local viewComponent = require( 'Game.views.AnnouncementView' ).new()
	self:SetViewComponent(viewComponent)
	-- dump(layer.viewData)
	local gridView = viewComponent.viewData.gridView
	gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAction))
	-- layer.viewData.knowBtn:setOnClickScriptHandler(handler(self, self.KnowButtonCallback))
end
-- function AnnouncementMediator:KnowButtonCallback()
-- 	self.layer:CloseHandler()
-- end
function AnnouncementMediator:OnDataSourceAction(p_convertview,idx)
	local pCell = p_convertview
	local viewData = self:GetViewComponent().viewData
	local bg = viewData.gridView
	local index = idx + 1
	local cSize = cc.size(306,100)
	if self.datas and index <= table.nums(self.datas) then
		local data = self.datas[index]

		if pCell == nil then
			pCell = AnnouncementCell.new(cSize)
			pCell.toggleView:setOnClickScriptHandler(handler(self, self.CellButtonAction))
		else
			pCell.toggleView:setChecked(false)
		end
		
		pCell.toggleView:setTag(index)
		if index == self.preIndex then
			pCell.toggleView:setChecked(true)
		else
			pCell.toggleView:setChecked(false)
		end
		--pCell:setScale(0.6)
		-- 绘制cell
		pCell.titleLabel:setString(tostring(data.title))
		return pCell
	end
end

function AnnouncementMediator:CellButtonAction( sender )
	PlayAudioClip(AUDIOS.UI.ui_click_confirm.id)
	sender:setChecked(true)
	local index = sender:getTag()
	if index == self.preIndex then 
	return end
	-- 更新按钮状态
	local viewData = self:GetViewComponent().viewData
	local gridView = viewData.gridView
	local cell = gridView:cellAtIndex(self.preIndex -1)
	if cell then
	cell.toggleView:setChecked(false)
	end
	self.preIndex = index
	self:updateDescription(self.preIndex) 
end
-- 更新公告详情
function AnnouncementMediator:updateDescription( index )
	if self.datas and table.nums(self.datas) > 0 then
		local viewData = self:GetViewComponent().viewData
		local titleLabel = viewData.titleLabel
		local bodyLabel  = viewData.bodyLabel
		local scrollView = viewData.scrollView
		self.type = tonumber(self.datas[index].type)

		titleLabel:setString(tostring(self.datas[index].subTitle))
		if self.type == ANNOTYPE.activity then
			display.reloadRichLabel(bodyLabel, {c = {
				{text = __('活动时间:') .. '\n', fontSize = 20, color = '#976f64'}, 
				{text = self.datas[index].contentTime .. '\n', fontSize = 20, color = '#6c6c6c'},
				{text = __('活动规则:') .. '\n', fontSize = 20, color = '#976f64'},

				{text = self.datas[index].content, fontSize = 20, color = '#6c6c6c'}
			}})
		elseif self.type == ANNOTYPE.announcement then
			display.reloadRichLabel(bodyLabel, {c = {
			{text = self.datas[index].content, fontSize = 20, color = '#6c6c6c'}	
			}})
		else
			print("类型错误")
		end
		-- scroll to top
		local scrollTop  = scrollView:getViewSize().height - display.getLabelContentSize(scrollView:getContainer()).height
		scrollView:setContentOffset(cc.p(0, scrollTop))		
	end
end

function AnnouncementMediator:EnterLayer(  )
	self:SendSignal(COMMANDS.COMMAND_Announcement)
end

function AnnouncementMediator:OnRegist(  )
	local AnnouncementCommand = require( 'Game.command.AnnouncementCommand' )
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Announcement,AnnouncementCommand)
	self:EnterLayer()
end


-- function AnnouncementMediator:CleanupView()
--     --清除视图
--     if self.viewComponent then
--         local scene = uiMgr:GetCurrentScene()
--         scene:RemoveDialog(self.viewComponent)
--     end
-- end

function AnnouncementMediator:OnUnRegist(  )
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Announcement)
end
return AnnouncementMediator








