--[[
 * author : liuzhipeng
 * descpt : 特殊活动 活动预告页签mediator
]]
local SpActivityPreviewPageMediator = class('SpActivityPreviewPageMediator', mvc.Mediator)

local CreateView = nil
local SpActivityPreviewPageView = require("Game.views.specialActivity.SpActivityPreviewPageView")

function SpActivityPreviewPageMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'SpActivityPreviewPageMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function SpActivityPreviewPageMediator:Initial(key)
    self.super.Initial(self, key)
    self.ownerNode_ = self.ctorArgs_.ownerNode
    self.typeData_  = self.ctorArgs_.typeData
    self.activityCellDict_ = {}
    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = SpActivityPreviewPageView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = view.viewData
        viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.ActivityGridViewDataSource))
    end
end


function SpActivityPreviewPageMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function SpActivityPreviewPageMediator:OnRegist()
end
function SpActivityPreviewPageMediator:OnUnRegist()
end


function SpActivityPreviewPageMediator:InterestSignals()
    local signals = {
	}
	return signals
end
function SpActivityPreviewPageMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
end


-------------------------------------------------
-- handler method
--[[
预告列表处理
--]]
function SpActivityPreviewPageMediator:ActivityGridViewDataSource(p_convertview, idx)
    local index = idx + 1
    local cell  = p_convertview

    -- init cell
    if cell == nil then
        local gridView = self:GetViewComponent().viewData.gridView
        local pCell = self:GetViewComponent():CreateListCell(gridView:getSizeOfCell())
        pCell.bgBtn:setOnClickScriptHandler(handler(self, self.CellButtonCallback))
        cell = pCell.view
        self.activityCellDict_[cell] = pCell
    end
	xTry(function()
        -- update cell
        local pCell = self.activityCellDict_[cell]
        if pCell then
            local data = self.homeData_.content[index]
            pCell.activityTitle:setString(data.name)
            pCell.timeLabel:setString(string.format('%s~%s', data.begin, data['end']))
            if data.img and string.len(data.img) > 0 then
                pCell.img:setWebURL(data.img)
            end
            pCell.bgBtn:setTag(index)
        end
	end,__G__TRACKBACK__)
    return cell
end
function SpActivityPreviewPageMediator:CellButtonCallback( sender )
    PlayAudioByClickNormal()
    local index = sender:getTag()
    app.uiMgr:AddDialog("Game.views.specialActivity.SpActivityPreviewDescrView", {data = self.homeData_.content[index]})
end
-------------------------------------------------
-- get /set
-------------------------------------------------
-- private method
--[[
刷新页面
--]]
function SpActivityPreviewPageMediator:RefreshView()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    viewData.gridView:setCountOfCell(#self.homeData_.content)
    viewData.gridView:reloadData()
end
-------------------------------------------------
-- public method
function SpActivityPreviewPageMediator:resetHomeData(homeData)
    self.homeData_ = homeData
    self:RefreshView()
end


return SpActivityPreviewPageMediator
