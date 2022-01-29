--[[
 * author : liuzhipeng
 * descpt : 图鉴 飨灵收集册Mediator
--]]
local CardAlbumMediator = class('CardAlbumMediator', mvc.Mediator)
local NAME = "cardAlbum.CardAlbumMediator"
function CardAlbumMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.selectedTab = 1
end
-------------------------------------------------
------------------ inheritance ------------------
function CardAlbumMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = app.uiMgr:SwitchToTargetScene('Game.views.collection.cardAlbum.CardAlbumScene')
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData
    viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
    viewData.tabTableView:setCellInitHandler(handler(self,self.OnInitTabListCellHandler))
    viewData.tabTableView:setCellUpdateHandler(handler(self,self.OnUpdateTabListCellHandler))
    viewData.cardTableView:setCellUpdateHandler(handler(self,self.OnUpdateCardListCellHandler))
    viewData.taskBtn:setOnClickScriptHandler(handler(self, self.TaskButtonCallback))
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    self:InitView()
end

function CardAlbumMediator:InterestSignals()
    local signals = {
        'CARD_ALBUM_TASK_DRAW_SIGNAL'
    }
    return signals
end
function CardAlbumMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == 'CARD_ALBUM_TASK_DRAW_SIGNAL' then
        self:DrawTaskResponseHandler(body)
    end
end

function CardAlbumMediator:OnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
end
function CardAlbumMediator:OnUnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
提示按钮点击回调
--]]
function CardAlbumMediator:TipsButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = INTRODUCE_MODULE_ID.CARD_ALBUM})
end
--[[
返回主界面
--]]
function CardAlbumMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
   self:GetFacade():BackHomeMediator()
end
--[[
页签列表初始化处理
--]]
function CardAlbumMediator:OnInitTabListCellHandler( cellViewData )
    cellViewData.btn:setOnClickScriptHandler(handler(self, self.TabButtonCallback))
end
--[[
页签按钮点击回调
--]]
function CardAlbumMediator:TabButtonCallback( sender )
	PlayAudioByClickNormal()
    local tag = sender:getTag()
	if self.selectedTab == tag then
		return
	end
    self:SwitchTab(tag)
end
--[[
页签列表数据处理
--]]
function CardAlbumMediator:OnUpdateTabListCellHandler( cellIndex, cellViewData )
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    local cellData = homeData[cellIndex]
    cellViewData.btn:setTag(cellIndex)
    cellViewData.titleLabel:setString(cellData.name)
    viewComponent:RefreshTabSelectedState(cellViewData.view, cellIndex == self.selectedTab)
    cellViewData.remindIcon:setRemindTag(app.badgeMgr:GetCardCollTaskGroupRemindTag(cellData.id))
end
--[[
卡牌列表数据处理
--]]
function CardAlbumMediator:OnUpdateCardListCellHandler( cellIndex, cellViewData )
    local homeData = self:GetHomeData()
    local cardId = homeData[self.selectedTab].cardIds[cellIndex]
    cellViewData.cardNode:RefreshNode({cardId = cardId})
end
--[[
任务按钮点击回调
--]]
function CardAlbumMediator:TaskButtonCallback( sender )
    PlayAudioByClickNormal()
    local homeData = self:GetHomeData()
    local selectedHomeData = homeData[self.selectedTab]
    local mediator = require("Game.mediator.collection.cardAlbum.CardAlbumTaskMediator").new(selectedHomeData)
    app:RegistMediator(mediator)
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function CardAlbumMediator:InitView()
    local viewComponent = self:GetViewComponent()
    -- 初始化数据
    self:ConvertConfData()
    local homeData = self:GetHomeData()
    -- 刷新页签列表
    viewComponent.viewData.tabTableView:resetCellCount(#homeData)
    self:SwitchTab(self.selectedTab)
end
--[[
转换配表数据
--]]
function CardAlbumMediator:ConvertConfData()
    local conf = CONF.CARD.CARD_COLL_BOOK:GetAll()
    local cardCollectionBook = app.gameMgr:GetUserInfo().cardCollectionBookMap
    local homeData = {}
    for k, v in pairs(clone(conf)) do
        -- 插入任务解锁数据
        v.unlockTask = cardCollectionBook[checkint(v.id)] or {}
        table.insert(homeData, v)
    end
    table.sort(homeData, function (a, b)
        return checkint(a.id) < checkint(b.id)
    end)
    self:SetHomeData(homeData)
end
--[[
切换页签
--]]
function CardAlbumMediator:SwitchTab( tag )
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:GetViewData()
    local homeData = self:GetHomeData()
    local oldCell = viewData.tabTableView:cellAtIndex(self.selectedTab - 1)
    viewComponent:RefreshTabSelectedState(oldCell, false)
    local cell = viewData.tabTableView:cellAtIndex(tag - 1)
    viewComponent:RefreshTabSelectedState(cell, true)
    self.selectedTab = tag
    self:RefreshContentLayout(homeData[tag])
end
--[[
刷新contentLayout
--]]
function CardAlbumMediator:RefreshContentLayout( params )
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:GetViewData()
    viewData.cardTableView:resetCellCount(#params.cardIds)
    viewData.taskBtnRemindIcon:setRemindTag(app.badgeMgr:GetCardCollTaskGroupRemindTag(params.id))
    local level = table.nums(params.unlockTask) + 1
    viewComponent:RefershCurrentLevel(level)
end
--[[
任务领取处理
--]]
function CardAlbumMediator:DrawTaskResponseHandler( responseData )
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    local bookData = nil
    for i, v in ipairs(homeData) do
        if checkint(v.id) == checkint(responseData.bookId) then
            bookData = v
            break
        end
    end
    if not bookData then return end

    for i, v in ipairs(responseData.taskIdList) do
        bookData.unlockTask[checkint(v)] = true
    end
    -- 刷新页面
    self:RefreshContentLayout(homeData[self.selectedTab])
    -- 刷新列表
    local offset = viewComponent.viewData.tabTableView:getContentOffset()
    viewComponent.viewData.tabTableView:reloadData()
    viewComponent.viewData.tabTableView:setContentOffset(offset)
    -- 升级弹窗
    app.uiMgr:AddDialog('Game.views.collection.cardAlbum.CardAlbumUpgradePopup',{level = table.nums(bookData.unlockTask) + 1 - #responseData.taskIdList, newLevel = table.nums(bookData.unlockTask) + 1})
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function CardAlbumMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function CardAlbumMediator:GetHomeData()
    return self.homeData
end

------------------- get / set -------------------
-------------------------------------------------
return CardAlbumMediator