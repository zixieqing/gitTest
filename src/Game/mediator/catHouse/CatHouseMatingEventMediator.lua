--[[
 * author : liuzhipeng
 * descpt : 猫屋 - 交配时间 中介者
]]
local CatHouseMatingEventView     = require('Game.views.catHouse.CatHouseMatingEventView')
local CatHouseMatingEventMediator = class('CatHouseMatingEventMediator', mvc.Mediator)

function CatHouseMatingEventMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatHouseMatingEventMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function CatHouseMatingEventMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    local beInvitedData  = checktable(self.ctorArgs_.beInvitedData)
    self.isControllable_ = true

    -- create view
    self.viewNode_ = CatHouseMatingEventView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddGameLayer(self:getViewNode())

    -- add listener
    self.eventRefreshClocker_ = app.timerMgr.CreateClocker(handler(self, self.onEventRefreshUpdateHandler_))
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    ui.bindClick(self:getViewData().cancelBtn, handler(self, self.onClickCancelButtonHandler_))
    ui.bindClick(self:getViewData().confirmBtn, handler(self, self.onClickConfirmButtonHandler_))
    self:getViewData().catsTableView:setCellUpdateHandler(handler(self, self.onCatsTableViewUpdateHandler_))
    self:getViewData().catsTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.clickArea, handler(self, self.onClickCatsTableCellHandler_))
    end)

    -- init datas
    local catUuidList = table.keys(app.catHouseMgr:getCatsModelMap())
    table.sort(catUuidList, function(aCatUuid, bCatUuid)
        local aCatModel = app.catHouseMgr:getCatModel(aCatUuid)
        local bCatModel = app.catHouseMgr:getCatModel(bCatUuid)
        local aToFriend = aCatModel:isMatingToFriend(beInvitedData) and 1 or 0
        local bToFriend = bCatModel:isMatingToFriend(beInvitedData) and 1 or 0
        return aToFriend > bToFriend
    end)
    self:setBeInvitedEventData(beInvitedData)
    self:setCatIdList(catUuidList)

    -- update views
    local birthMax = CatHouseUtils.CAT_PARAM_FUNCS.BIRTH_REWARD_NUM()
    local birthNum = checkint(app.catHouseMgr:getCatHomeData().matingRewardTimes)
    local rewards  = CatHouseUtils.CAT_PARAM_FUNCS.BIRTH_REWARDS()
    self:setDescrData(table.concat({
        string.fmt('今日交配次数 _num_/_max_', {_num_ = birthNum, _max_ = birthMax}),
        string.fmt('女方获得幼猫，男方获得 %1', tableToString(rewards, '奖励')),
        tableToString(self:getBeInvitedEventData(), '邀请方数据 [HouseCat/home] > beInvited')
    }, '\n'))
end


function CatHouseMatingEventMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function CatHouseMatingEventMediator:OnRegist()
    self.eventRefreshClocker_:start()
end


function CatHouseMatingEventMediator:OnUnRegist()
    self.eventRefreshClocker_:stop()
end


function CatHouseMatingEventMediator:InterestSignals()
    return {
        SGL.CAT_MODULE_CAT_MATING_ANSWER,
    }
end
function CatHouseMatingEventMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == SGL.CAT_MODULE_CAT_MATING_ANSWER then
        local eventData = self:getBeInvitedEventData()
        if data.result == 1 and data.friendCatId == eventData.friendCatId then
            -- 交配成功，更新猫咪数据模型
            local birthConf  = CONF.CAT_HOUSE.CAT_BIRTH:GetValue(eventData.generation)
            local matingTime = checkint(birthConf.birthTime)
            catModel:setMatingData({
                friendId    = checkint(eventData.friendId),    -- 好友id
                friendCatId = checkint(eventData.friendCatId), -- 好友猫咪唯一id
                catId       = checkint(eventData.catId),       -- 猫咪种族
                name        = tostring(eventData.name),        -- 猫咪名字
                gene        = clone(eventData.gene),           -- 猫咪基因
                generation  = checkint(eventData.generation),  -- 猫咪代数
                age         = checkint(eventData.age),         -- 猫咪年龄
                sex         = checkint(eventData.sex),         -- 猫咪性别
                ability     = clone(eventData.ability),        -- 猫咪能力
                attr        = clone(eventData.attr),           -- 猫咪属性
                rebirth     = checkint(eventData.rebirth),     -- 是否回归
                leftSeconds = matingTime,                      -- 剩余时间
                isInvite    = 1,                               -- 是否邀请人
            })
            -- tips
            app.uiMgr:ShowInformationTips(__('成功接受好友的交配邀请'))
        end
    end
end


-------------------------------------------------
-- get / set

---@return CatHouseMatingEventView
function CatHouseMatingEventMediator:getViewNode()
    return  self.viewNode_
end
function CatHouseMatingEventMediator:getViewData()
    return self:getViewNode():getViewData()
end


-- catId list
function CatHouseMatingEventMediator:getCatIdList()
    return self.catIdList_
end
function CatHouseMatingEventMediator:setCatIdList(catIdList)
    self.catIdList_ = checktable(catIdList)
    self:getViewData().catEmpthLabel:setVisible(#self:getCatIdList() <= 0)
    self:getViewData().catsTableView:resetCellCount(#self:getCatIdList())
end


-- myself catUuid
function CatHouseMatingEventMediator:getMyselfCatUuid()
    return self.myselfCatUuid_
end
function CatHouseMatingEventMediator:setMyselfCatUuid(catUuid)
    self.myselfCatUuid_ = catUuid
    self:getViewData().myselfCatHeadNode:setCatUuid(catUuid)
end


-- beInvited data
function CatHouseMatingEventMediator:getBeInvitedEventData()
    return checktable(self.beInvitedData_)
end
function CatHouseMatingEventMediator:setBeInvitedEventData(eventData)
    self.beInvitedData_ = checktable(eventData)
    self:getViewData().friendCatHeadNode:setCatData(self.beInvitedData_)
end


function CatHouseMatingEventMediator:getDescrData()
    return self.descrData_
end
function CatHouseMatingEventMediator:setDescrData(descr)
    self.descrData_ = tostring(descr)
    self:updateSelectDescr_()
end


-------------------------------------------------
-- public

function CatHouseMatingEventMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function CatHouseMatingEventMediator:updateSelectDescr_()
    self:getViewNode():updateDescr(self:getDescrData())
end


-------------------------------------------------
-- handler

function CatHouseMatingEventMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function CatHouseMatingEventMediator:onClickConfirmButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if self:getMyselfCatUuid() > 0 then
        app.catHouseMgr:replyCatMatingRequest(self:getBeInvitedEventData().friendCatId, self:getMyselfCatUuid())
    else
        app.uiMgr:ShowInformationTips(__('请先选择一直猫咪'))
    end
end


function CatHouseMatingEventMediator:onClickCancelButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:close()
end


function CatHouseMatingEventMediator:onEventRefreshUpdateHandler_()
    local leftSeconds = self:getBeInvitedEventData().timestamp - os.time()
    if leftSeconds <= 0 then
        self:close()
    else
        self:getViewData().timeTitle:updateLabel({text = CommonUtils.getTimeFormatByType(leftSeconds)})
    end
end



function CatHouseMatingEventMediator:onCatsTableViewUpdateHandler_(cellIndex, cellViewData)
    local catUuid  = self:getCatIdList()[cellIndex]
    local catModel = app.catHouseMgr:getCatModel(catUuid)
    cellViewData.view:setTag(catUuid)
    cellViewData.clickArea:setTag(catUuid)
    -- update catHeadNode
    cellViewData.catHeadNode:setCatUuid(catUuid)
    -- update matingTips
    cellViewData.matingTips:setVisible(not catModel:isMatingToFriend(self:getBeInvitedEventData()))
end


function CatHouseMatingEventMediator:onClickCatsTableCellHandler_(sender)
    PlayAudioByClickNormal()
    local catUuid  = checkint(sender:getTag())
    local catModel = app.catHouseMgr:getCatModel(catUuid)
    if catModel:checkMatingToFriend(self:getBeInvitedEventData(), true) then
        self:setMyselfCatUuid(catUuid)
    end
end


return CatHouseMatingEventMediator
