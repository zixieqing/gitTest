--[[
 * author : weihao
 * descpt : 猫屋 - 收藏柜 中介者
]]
local CatHouseCollView     = require('Game.views.catHouse.CatHouseCollView')
---@class CatHouseCollMediator:Mediator
local CatHouseCollMediator = class('CatHouseCollMediator', mvc.Mediator)
local Trophy_Info = CONF.CAT_HOUSE.TROPHY_INFO:GetAll()
--[[
{
    friendId = "" , 玩家id
    houseData = {  猫屋数据

    }
}
--]]
function CatHouseCollMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatHouseCollMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
    self.isMyself = false  -- 判断是自己还是还有
    self:SetIsMyself(self.ctorArgs_.friendId)
end


-------------------------------------------------
-- inheritance

function CatHouseCollMediator:Initial(key)
    self.super.Initial(self, key)
    -- init vars
    self.isControllable_ = true
    -- create view
    self:setViewNode(CatHouseCollView.new())
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddGameLayer(self:getViewNode())
    local viewNode_ = self:getViewNode()
    local viewData = viewNode_.viewData
    ui.bindClick(viewData.closeLayer , handler(self, self.onClickBackButtonHandler_), false)
    viewData.scrollView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))
    if not self:IsMyself() then
        self:ReloadGridView()
    end
end
function CatHouseCollMediator:ReloadGridView()
    local trophyList = self:GetTrophy()
    local viewNode_ = self:getViewNode()
    local viewData = viewNode_.viewData
    viewData.scrollView:setCountOfCell(trophyList and #trophyList or 0)
    viewData.scrollView:reloadData()
end
function CatHouseCollMediator:OnDataSource(p_convertview, idx)
    local index = idx + 1
    local pcell = p_convertview
    local isMyself = self:IsMyself()
    if not pcell then
        pcell = self:getViewNode():CreateCell()
    end
    local viewData = pcell.viewData
    local trophys = self:GetTrophy()
    xTry(function()
        local trophy = trophys[index]
        local trophyInfo = Trophy_Info[tostring(trophy.trophyId)]
        local progress = checkint(trophy.progress)
        local targetNum = checkint(trophyInfo.targetNum)
        local name = trophyInfo.name
        viewData.filteredSprite:setTexture(CatHouseUtils.GetTrophyImageByTrophyId(trophy.trophyId))

        if isMyself then
            if progress >= targetNum  then
                if checkint(trophy.hasDrawn) == 1 then
                    viewData.filteredSprite:clearFilter()
                    viewData.drawIcon:clearFilter()
                    viewData.showGiftBtn:setVisible(false)
                else
                    viewData.showGiftBtn:setVisible(true)
                    viewData.filteredSprite:setFilter(GrayFilter:create())
                    viewData.drawIcon:clearFilter()
                end
            else
                viewData.showGiftBtn:setVisible(true)
                viewData.filteredSprite:setFilter(GrayFilter:create())
                viewData.drawIcon:setFilter(GrayFilter:create())
            end
            viewData.showGiftBtn:setTag(index)

        else
            viewData.showGiftBtn:setVisible(false)
            if checkint(trophy.hasDrawn) == 1 then
                viewData.filteredSprite:clearFilter()
                viewData.drawIcon:clearFilter()
            else
                viewData.filteredSprite:setFilter(GrayFilter:create())
                viewData.drawIcon:setFilter(GrayFilter:create())
            end
        end
        display.commonLabelParams(viewData.trophyLabel , { text = name  , w = 170 , hAlign = display.TAC})
        viewData.clickLayer:setTag(index)
        local bgIndex = math.fmod(index , 3)
        bgIndex = bgIndex == 0 and 3 or bgIndex
        local locksBgTables = {
            cc.p(95 , -10) ,
            cc.p(102 , -10),
            cc.p(107 , -10),
        }
        viewData.lockerBg:setTexture(_res(string.format("ui/catHouse/trophy/cat_collec_lockers_bg_%d" , bgIndex +1)))
        viewData.lockerBg:setPosition(locksBgTables[bgIndex])
        ui.bindClick(viewData.showGiftBtn , handler(self, self.ShowGiftClick))
        ui.bindClick(viewData.clickLayer , handler(self, self.CellClick))
    end, __G__TRACKBACK__)
    return pcell
end
function CatHouseCollMediator:CellClick(sender)
    local tag = sender:getTag()
    local trophyList = self:GetTrophy()
    local trophy = trophyList[tag]
    local viewNode_ = self:getViewNode()
    viewNode_:UpdateTipLayout(trophy , sender)
end


function CatHouseCollMediator:ShowGiftClick(sender)
    PlayAudioByClickNormal()

    local tag        = sender:getTag()
    local trophyList = self:GetTrophy()
    local trophy     = trophyList[tag]

    local pos = sender:getParent():convertToWorldSpace(cc.p(sender:getPosition()))
    self:getViewNode():ShowGiftLayout(trophy, handler(self, self.DrawTrophyClick), pos)
end


function CatHouseCollMediator:DrawTrophyClick(trophyData)
    PlayAudioByClickNormal()

    local trophy = checktable(trophyData)
    if not self:IsMyself() then
        app.uiMgr:ShowInformationTips(__('在好友猫屋不能领取奖杯'))
        return
    end
    if checkint(trophy.hasDrawn)  == 1 then
        app.uiMgr:ShowInformationTips(__('奖杯已经领取'))
        return
    end
    local trophyOneConf = Trophy_Info[tostring(trophy.trophyId)]
    if checkint(trophyOneConf.targetNum) > checkint(trophy.progress) then
        app.uiMgr:ShowInformationTips(__('奖杯任务暂未完成'))
        return
    end
    self:SendSignal(POST.HOUSE_TROPHY_DRAW.cmdName , {trophyId = checkint(trophy.trophyId)})
end
function CatHouseCollMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end
---@deprecated 是否是自己
---@param friendId number 玩家的id
function CatHouseCollMediator:SetIsMyself(friendId)
    self.isMyself = CommonUtils.JuageMySelfOperation(friendId)
end

---@deprecated 返回是否是自己
---@return boolean
function CatHouseCollMediator:IsMyself()
    return  self.isMyself
end

---@deprecated 获取奖杯数据
function CatHouseCollMediator:GetTrophy()
    local trophy = self.ctorArgs_.houseData.trophy
    return trophy
end

function CatHouseCollMediator:OnRegist()
    regPost(POST.HOUSE_TROPHY_ENTER)
    regPost(POST.HOUSE_TROPHY_DRAW)

    if self:IsMyself() then
        self:SendSignal(POST.HOUSE_TROPHY_ENTER.cmdName)
    end
end


function CatHouseCollMediator:OnUnRegist()
    unregPost(POST.HOUSE_TROPHY_ENTER)
    unregPost(POST.HOUSE_TROPHY_DRAW)
end


function CatHouseCollMediator:InterestSignals()
    return {
        POST.HOUSE_TROPHY_ENTER.sglName,
        POST.HOUSE_TROPHY_DRAW.sglName,
    }
end
function CatHouseCollMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.HOUSE_TROPHY_ENTER.sglName then
        -- reset data
        app.catHouseMgr:getHomeData().trophy = data.trophy

        -- refresh view
        self:ReloadGridView()

        
    elseif name == POST.HOUSE_TROPHY_DRAW.sglName then
        local requestData = data.requestData
        local trophyId    = checkint(requestData.trophyId)
        local rewards     = data.rewards or {}
        local trophyList  = self:GetTrophy()
        -- 更新奖杯的数据
        local idx  = 1
        for index, trophy in pairs(trophyList) do
            if checkint(trophy.trophyId) == trophyId then
                trophy.hasDrawn = 1
                trophy.drawTimestamp = os.time()
                idx = index
                break
            end
        end
        -- 显示获取的奖励
        if #rewards > 0  then
            app.uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
        end
        -- 更新cell
        local viewNode_ = self:getViewNode()
        local viewData = viewNode_.viewData
        local cell = viewData.scrollView:cellAtIndex(idx -1)
        if cell and (not tolua.isnull(cell)) then
            self:OnDataSource(cell , idx - 1)
        end
    end
end


-------------------------------------------------
-- get / set
---@return CatHouseCollView
function CatHouseCollMediator:getViewNode()
    return  self.viewNode_
end
function CatHouseCollMediator:setViewNode(viewNode_)
    self.viewNode_ = viewNode_
end
function CatHouseCollMediator:getViewData()
    return self:getViewNode():getViewData()
end


function CatHouseCollMediator:getDescrData()
    return self.descrData_
end
function CatHouseCollMediator:setDescrData(descr)
    self.descrData_ = tostring(descr)
    self:updateSelectDescr_()
end


-------------------------------------------------
-- public

function CatHouseCollMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function CatHouseCollMediator:updateSelectDescr_()
    self:getViewNode():updateDescr(self:getDescrData())
end


-------------------------------------------------
-- handler

function CatHouseCollMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    self:close()
end



return CatHouseCollMediator
