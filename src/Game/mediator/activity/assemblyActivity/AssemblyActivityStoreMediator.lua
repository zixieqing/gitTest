--[[
 * author : liuzhipeng
 * descpt : 活动 组合活动 商城Mediator
--]]
local AssemblyActivityStoreMediator = class('AssemblyActivityStoreMediator', mvc.Mediator)
local NAME = 'activity.assemblyActivity.AssemblyActivityStoreMediator'

local STORE_TAB_TYPE = {
    DIAMOND = 1, -- 钻石商店
    GIFT    = 2, -- 礼包商店
}
local STORE_MDT_DEFINE = {
    [tostring(STORE_TAB_TYPE.DIAMOND)] = {mdtName = 'activity.assemblyActivity.AssemblyActivityStoreDiamondMediator', key = 'goods'},
    [tostring(STORE_TAB_TYPE.GIFT)]    = {mdtName = 'activity.assemblyActivity.AssemblyActivityStoreGiftMediator',    key = 'chests'},
}
function AssemblyActivityStoreMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    local args = checktable(params)
    self.activityId = checkint(args.activityId)
    self.selctedTabType = STORE_TAB_TYPE.DIAMOND
    self.contentMdtName_ = nil
    self.isControllable_ = true
end
-------------------------------------------------
------------------ inheritance ------------------
function AssemblyActivityStoreMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require('Game.views.activity.assemblyActivity.AssemblyActivityStoreView').new()
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData

    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    for i, v in ipairs(viewComponent.viewData.tabList) do
        v:setOnClickScriptHandler(handler(self, self.TabButtonCallback))
    end
end
    
function AssemblyActivityStoreMediator:InterestSignals()
    local signals = {
        POST.ASSEMBLY_ACTIVITY_MALL_HOME.sglName,
    }
    return signals
end
function AssemblyActivityStoreMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.ASSEMBLY_ACTIVITY_MALL_HOME.sglName then
        self.dataTimestamp_ = os.time()
        self:SetHomeData(body)
        self:RefreshTab()
    end
end

function AssemblyActivityStoreMediator:OnRegist()
    regPost(POST.ASSEMBLY_ACTIVITY_MALL_HOME)
    self:EnterLayer()
end
function AssemblyActivityStoreMediator:OnUnRegist()
    unregPost(POST.ASSEMBLY_ACTIVITY_MALL_HOME)
    -- 移除商城mediator
    if self.contentMdtName_ then
        self:GetFacade():UnRegsitMediator(self.contentMdtName_)
    end
    -- 移除界面
    local scene = app.uiMgr:GetCurrentScene()
    scene:RemoveDialog(self:GetViewComponent())
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
返回主界面
--]]
function AssemblyActivityStoreMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end
--[[
页签按钮点击回调
--]]
function AssemblyActivityStoreMediator:TabButtonCallback( sender ) 
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if tag ~= self:GetSelectedTabIndex() then
        self:SetSelectedTabIndex(tag)
        self:RefreshTab()
    end
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function AssemblyActivityStoreMediator:InitView()

end
--[[
初始化顶部货币栏
--]]
function AssemblyActivityStoreMediator:InitMoneyBar()
    local viewComponent = self:GetViewComponent()
    local moneyIdMap = {}
    viewComponent:InitMoneyBar(moneyIdMap)
end
--[[
刷新tab
--]]
function AssemblyActivityStoreMediator:RefreshTab()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshTab(self:GetSelectedTabIndex())
    -- 刷新商品列表
    self:RefreshItemsList()
    -- 更新顶部货币栏
    self:InitMoneyBar()
end
--[[
刷新商品列表
--]]
function AssemblyActivityStoreMediator:RefreshItemsList()
    if self.contentMdtName_ then
        self:GetFacade():UnRegsitMediator(self.contentMdtName_)
    end
    local mdtDefine = STORE_MDT_DEFINE[tostring(self.selctedTabType)]
    local homeData = self:GetHomeData()
    local viewData = self:GetViewComponent():GetViewData()
    if not mdtDefine then return end
    -- 创建商城mediator
    local curStoreMediator = require(string.format('Game.mediator.%s', mdtDefine.mdtName)).new({size = viewData.listSize, ownerNode = viewData.listLayout, activityId = self.activityId})
    app:RegistMediator(curStoreMediator)
    self.contentMdtName_ = mdtDefine.mdtName
    local storeTypeData = {
        dataTimestamp = self.dataTimestamp_,
        storeData = homeData[mdtDefine.key]
    }
    curStoreMediator:setStoreData(storeTypeData)
end
--[[
进入页面
--]]
function AssemblyActivityStoreMediator:EnterLayer()
    self:SendSignal(POST.ASSEMBLY_ACTIVITY_MALL_HOME.cmdName, {activityId = self.activityId})
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function AssemblyActivityStoreMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function AssemblyActivityStoreMediator:GetHomeData()
    return self.homeData
end
--[[
设置选中的标签
--]]
function AssemblyActivityStoreMediator:SetSelectedTabIndex( selctedTabType )
    if not selctedTabType then return end
    self.selctedTabType = checkint(selctedTabType)
end
--[[
获取选中的标签
--]]
function AssemblyActivityStoreMediator:GetSelectedTabIndex()
    return self.selctedTabType
end
--[[
获取当前所选页面的商品
--]]
function AssemblyActivityStoreMediator:GetCurrentProducts()
    local homeData = self:GetHomeData()
    return checktable(homeData.products)[tostring(self:GetSelectedTabIndex())]
end
------------------- get / set -------------------
-------------------------------------------------
return AssemblyActivityStoreMediator