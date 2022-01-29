
local NAME = 'SunFlowerBibleMediator'
---@class SunFlowerBibleMediator:Mediator
local SunFlowerBibleMediator = class(NAME, mvc.Mediator)
function SunFlowerBibleMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    local sunFlowerData = self:InitConfSunFlowData()
    self:SetConfSunFlowerData(sunFlowerData)
    self.selectType = 1
end

-------------------------------------------------
-- init method
function SunFlowerBibleMediator:Initial(key)
    self.super.Initial(self, key)
    ---@type SunFlowerBibleView
    local viewComponent = require("Game.views.sunFlowerBible.SunFlowerBibleView").new()
    self:SetViewComponent(viewComponent)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    viewComponent:setPosition(display.center)
    
    local viewData = viewComponent.viewData
    display.commonUIParams(viewData.backBtn , {cb = handler(self, self.CloseMediator) })
    display.commonUIParams(viewData.tabLabelName , {cb = function()
       app.uiMgr:ShowIntroPopup({ moduleId = '-81'})
    end})

    viewData.cScrollView:setDataSourceAdapterScriptHandler(handler(self,self.onDataSource))
    self:InitListView()
    self:ReloadGridViewData()
    viewComponent:UpdateView(self.selectType)
end
function SunFlowerBibleMediator:onDataSource(p_convertview , idx)
    local pCell = p_convertview
    local index = idx + 1
    local sunFlowerData = self:GetConfSunFlowerData()
    local data = sunFlowerData[tostring(self.selectType)]
    ---@type SunFlowerBibleView
    local viewComponent = self:GetViewComponent()
    if pCell == nil then
        pCell = viewComponent:CreateCenterCellLayout()
        display.commonUIParams(pCell.viewData.rewardBtn, {cb = handler(self, self.onClickCellAction)})
    end
    xTry(function()
        pCell.viewData.rewardBtn:setTag(checkint(data[index]))
        viewComponent:UpdateCenterCellLayout(pCell)
    end,__G__TRACKBACK__)

    return pCell
end
function SunFlowerBibleMediator:ReloadGridViewData()
    ---@type SunFlowerBibleView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    local cGrideView = viewData.cScrollView
    local sunFlowerData = self:GetConfSunFlowerData()
    cGrideView:setCountOfCell(table.nums(sunFlowerData[tostring(self.selectType)]))
end
function SunFlowerBibleMediator:InitListView()
    local sunFlowerData = self:GetConfSunFlowerData()
    ---@type SunFlowerBibleView
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    for confType, confData in pairs(sunFlowerData) do
        local cellLayout = viewComponent:CreateLeftCellLayout()
        viewData.lScrollView:insertNodeAtLast(cellLayout)
        viewComponent:UpdateLeftCell(cellLayout ,confType )
        cellLayout:setTag(checkint(confType))
        display.commonUIParams(cellLayout , {cb = handler(self, self.LeftCellLayoutClick)})
    end
    viewData.lScrollView:reloadData()
end

function SunFlowerBibleMediator:onClickCellAction(sender)
    local tag = sender:getTag()
    --TODO 弹出跳转方式
	app.uiMgr:AddDialog("Game.views.sunFlowerBible.SunGainPopUp" , {id = tag})
end
function SunFlowerBibleMediator:LeftCellLayoutClick(sender)
    local tag = sender:getTag()
    if self.selectType == tag then
        return
    end
    self.selectType = tag
    self:ReloadGridViewData()
    local viewComponent = self:GetViewComponent()
    viewComponent:UpdateView(tag)

end

function SunFlowerBibleMediator:CloseMediator()
    self:GetFacade():UnRegistMediator(NAME)
end

function SunFlowerBibleMediator:SetConfSunFlowerData(sunFlowerData)
    self.sunFlowerData = sunFlowerData
end

function SunFlowerBibleMediator:GetConfSunFlowerData()
    return self.sunFlowerData
end

function SunFlowerBibleMediator:InitConfSunFlowData()
    local strongTypeConf = CONF.SUN_FLOWR.STRONGER_TYPE:GetAll()
    local keysTable      = table.keys(strongTypeConf)
    local sunFlowerData  = {}
    for i =1 , #keysTable do
        sunFlowerData[tostring(keysTable[i])] = {}
    end
    local strongerConf = CONF.SUN_FLOWR.STRONGER:GetAll()
    local jumpType = 1
    for id, conf  in pairs(strongerConf) do
        jumpType = tostring(conf.type)
        if sunFlowerData[jumpType] then
            sunFlowerData[jumpType][#sunFlowerData[jumpType]+1] = checkint(id)
        end
    end
    for i, oneData in pairs(sunFlowerData) do
        if #oneData > 0 then
            table.sort(oneData , function(a, b )
                return a < b
            end)
        end
    end
    return sunFlowerData
end

function SunFlowerBibleMediator:OnRegist()

end

function SunFlowerBibleMediator:OnUnRegist()
    local viewComponent = self:GetViewComponent()
    self:SetViewComponent(nil)
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return SunFlowerBibleMediator
