--[[
 * descpt : 创建HOME工会 中介者
]]
local NAME = 'UnionPartyPreparePreviewMediator'
local UnionPartyPreparePreviewMediator = class(NAME, mvc.Mediator)

local uiMgr    = AppFacade.GetInstance():GetManager('UIManager')
local gameMgr  = AppFacade.GetInstance():GetManager("GameManager")
local unionMgr = AppFacade.GetInstance():GetManager("UnionManager")

-- local TAB_CONFIG = {
--     [tostring(TAB_TAG.TAB_LOOKUP_LABOUR_UNION)] = {mediaorName = 'UnionLookupMediator', titleName = __('查找工会')},  
--     [tostring(TAB_TAG.TAB_CREATE_LABOUR_UNION)] = {mediaorName = 'UnionCreateMediator', titleName = __('创建工会')}
-- }
function UnionPartyPreparePreviewMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    
    self.datas = self.ctorArgs_.data or {}
    -- 保存 上次选择 tab 标识
    self.preChoiceTag = nil

end

-------------------------------------------------
-- inheritance method
function UnionPartyPreparePreviewMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    
    -- create view
    local view = require('Game.views.union.UnionPartyPreparePreviewView').new()
    self.viewData_   = view:getViewData()
    local uiManager  = self:GetFacade():GetManager('UIManager')
    self:SetViewComponent(view)

    -- init view
    self:initView()
end

function UnionPartyPreparePreviewMediator:initView()
    local viewData = self:getViewData()

    local needFoods = self.datas.needFoods or {}
    dump(needFoods, 'needFoodsneedFoods')
    local gridView = viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSource))
    gridView:setCountOfCell(#needFoods)
    gridView:reloadData()
end

function UnionPartyPreparePreviewMediator:CleanupView()
    
end


function UnionPartyPreparePreviewMediator:OnRegist()
end
function UnionPartyPreparePreviewMediator:OnUnRegist()
end


function UnionPartyPreparePreviewMediator:InterestSignals()
    return {
        
    }
end

function UnionPartyPreparePreviewMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()

    
end

-------------------------------------------------
-- get / set

function UnionPartyPreparePreviewMediator:getCtorArgs()
    return self.ctorArgs_
end

function UnionPartyPreparePreviewMediator:getViewData()
    return self.viewData_
end

function UnionPartyPreparePreviewMediator:getAppRouter()
    return AppFacade.GetInstance():RetrieveMediator('Router')
end

-------------------------------------------------
-- public method


-------------------------------------------------
-- private method

-------------------------------------------------
-- handler

function UnionPartyPreparePreviewMediator:onDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:GetViewComponent():CreateCell()
    end

    xTry(function()
        local needFoods = self.datas.needFoods or {}
        local data = needFoods[index] or {}
        local viewData = pCell.viewData
        
        -- 更新的菜谱级别
        local grade = checkint(data.grade)
        local gradeImg = viewData.gradeImg
        gradeImg:setTexture(app.cookingMgr:getCookingGradeImg(grade))

        -- 更新道具图片
        local goodsId = data.foodId
        local goodNode = viewData.goodNode
        goodNode:RefreshSelf({goodsId = goodsId})

        local name = goodNode.goodData.name
        local goodName = viewData.goodName
        display.commonLabelParams(goodName, {text = tostring(name)})

        pCell:setTag(index)
	end,__G__TRACKBACK__)
    return pCell
end


return UnionPartyPreparePreviewMediator
