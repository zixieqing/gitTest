--[[
 * author : kaishiqi
 * descpt : 武道会 - 历届冠军中介者
]]
local ChampionshipHistoryChampionView     = require('Game.views.championship.ChampionshipHistoryChampionView')
local ChampionshipHistoryChampionMediator = class('ChampionshipHistoryChampionMediator', mvc.Mediator)

local HISTORY_PROXY_NAME   = FOOD.CHAMPIONSHIP.HISTORY.PROXY_NAME
local HISTORY_PROXY_STRUCT = FOOD.CHAMPIONSHIP.HISTORY.PROXY_STRUCT

function ChampionshipHistoryChampionMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'ChampionshipHistoryChampionMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function ChampionshipHistoryChampionMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isLoadingData_  = false
    self.isControllable_ = true

    -- init model
    self.historyProxy_ = regVoProxy(HISTORY_PROXY_NAME, HISTORY_PROXY_STRUCT)

    -- create view
    self.viewNode_ = ChampionshipHistoryChampionView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    self:getViewNode().historyCellUpdatedCB = handler(self, self.historyCellUpdatedCB_)
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    ui.bindClick(self:getTeamPopupVD().blockLayer, handler(self, self.onClickTeamPopupBlackLayerHandler_), false)
    self:getViewData().historyTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.leaderHeadArea, handler(self, self.onClickHistoryCellLeaderAreaHandler_), false)
    end)
end


function ChampionshipHistoryChampionMediator:CleanupView()
    unregVoProxy(HISTORY_PROXY_NAME)

    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function ChampionshipHistoryChampionMediator:OnRegist()
    regPost(POST.CHAMPIONSHIP_HISTORY)

    self:loadNextPageData_()
end


function ChampionshipHistoryChampionMediator:OnUnRegist()
    unregPost(POST.CHAMPIONSHIP_HISTORY)
end


function ChampionshipHistoryChampionMediator:InterestSignals()
    return {
        POST.CHAMPIONSHIP_HISTORY.sglName,
    }
end
function ChampionshipHistoryChampionMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.CHAMPIONSHIP_HISTORY.sglName then
        -- update loadPageNum
        self.isLoadingData_  = false
        local requestPageNum = self.historyProxy_:get(HISTORY_PROXY_STRUCT.HISTORY_SEND.PAGE)
        self.historyProxy_:set(HISTORY_PROXY_STRUCT.LOADED_PAGE_NUM, requestPageNum)

        -- update takeData
        local TAKE_STRUCT = HISTORY_PROXY_STRUCT.HISTORY_TAKE
        self.historyProxy_:set(TAKE_STRUCT.PAGE_SIZE, data.maxpage)
        self.historyProxy_:set(TAKE_STRUCT.DATA_SIZE, data.range)
        
        -- check pageSize limit
        if requestPageNum <= self.historyProxy_:get(TAKE_STRUCT.PAGE_SIZE) then

            -- append loadPageData
            local pageDataSize = self.historyProxy_:get(HISTORY_PROXY_STRUCT.LOADED_DATA_NUM)
            for dataIndex, dataValue in ipairs(checktable(data.data)) do
                self.historyProxy_:set(TAKE_STRUCT.PAGE_DATA.CHAMPION_DATA, dataValue, pageDataSize + dataIndex)
            end

            -- update loadDataNum
            self.historyProxy_:set(HISTORY_PROXY_STRUCT.LOADED_DATA_NUM, self.historyProxy_:size(TAKE_STRUCT.PAGE_DATA))
        end
    end
end


-------------------------------------------------
-- get / set

function ChampionshipHistoryChampionMediator:getViewNode()
    return  self.viewNode_
end
function ChampionshipHistoryChampionMediator:getViewData()
    return self:getViewNode():getViewData()
end
function ChampionshipHistoryChampionMediator:getTeamPopupVD()
    return self:getViewNode():getTeamPopupVD()
end


-------------------------------------------------
-- public

function ChampionshipHistoryChampionMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function ChampionshipHistoryChampionMediator:loadNextPageData_()
    if self.isLoadingData_ then return end
    self.isLoadingData_ = true
    local loadPageNum   = self.historyProxy_:get(HISTORY_PROXY_STRUCT.LOADED_PAGE_NUM)
    local SEND_STRUCT   = HISTORY_PROXY_STRUCT.HISTORY_SEND
    self.historyProxy_:set(SEND_STRUCT.PAGE, loadPageNum + 1)
    self:SendSignal(POST.CHAMPIONSHIP_HISTORY.cmdName, self.historyProxy_:get(SEND_STRUCT):getData())
end


function ChampionshipHistoryChampionMediator:historyCellUpdatedCB_(cellIndex)
    local pageDataSize = self.historyProxy_:get(HISTORY_PROXY_STRUCT.LOADED_DATA_NUM)
    if cellIndex >= pageDataSize - 1 then  -- check range is length - 1
        local loadedPageNum = self.historyProxy_:get(HISTORY_PROXY_STRUCT.LOADED_PAGE_NUM)
        local totalPageNum  = self.historyProxy_:get(HISTORY_PROXY_STRUCT.HISTORY_TAKE.PAGE_SIZE)
        if loadedPageNum < totalPageNum and self.isLoadingData_ == false then
            self:loadNextPageData_()
        end
    end
end


-------------------------------------------------
-- handler

function ChampionshipHistoryChampionMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function ChampionshipHistoryChampionMediator:onClickTeamPopupBlackLayerHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():hideTeamPopup()
end


function ChampionshipHistoryChampionMediator:onClickHistoryCellLeaderAreaHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local cellIndex = checkint(sender:getTag())
    self:getViewNode():showTeamPopup(cellIndex)
end


return ChampionshipHistoryChampionMediator
