--[[
 * author : liuzhipeng
 * descpt : 猫屋 繁殖Mediator
--]]
local CatHouseBreedMediator = class('CatHouseBreedMediator', mvc.Mediator)
local NAME = 'CatHouseBreedMediator'
function CatHouseBreedMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)

    self.catUuid = checktable(params).catUuid 
end
-------------------------------------------------
-------------------- import ---------------------
-------------------- import ---------------------
-------------------------------------------------

-------------------------------------------------
------------------ inheritance ------------------
function CatHouseBreedMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require('Game.views.catHouse.CatHouseBreedView').new()
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()

    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.catteryGridView:setCellUpdateHandler(handler(self, self.OnUpdateListCellHandler))
    viewData.catteryGridView:setCellInitHandler(handler(self, self.OnInitListCellHandler))
    self:RefreshView()
    self:PreLoadCat(self.catUuid)
end
    
function CatHouseBreedMediator:InterestSignals()
    local signals = {
        POST.HOUSE_CAT_MATING.sglName,
        POST.HOUSE_CAT_MATING_HOUSE.sglName,
        POST.HOUSE_CAT_MATING_END_TO.sglName,
        POST.HOUSE_CAT_MATING_END_BE.sglName,
        POST.HOUSE_CAT_MATING_CANCEL.sglName,
        SGL.CAT_HOUSE_BREED_LIST_SELECTED,
        SGL.CAT_HOUSE_BREED_PAIRING_CANCEL,
        SGL.CAT_MODULE_CAT_REFRESH_UPDATE,
        SGL.CAT_HOUSE_ACCEPT_BREED_INVITE,
        SGL.CAT_HOUSE_HOUSE_LEFT_SECONDS_ZERO
    }
    return signals
end

function CatHouseBreedMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.HOUSE_CAT_MATING.sglName then
        self:ShowBreedInfo(body)
    elseif name == POST.HOUSE_CAT_MATING_END_TO.sglName then
        self:InviterMatingEnd(body)
    elseif name == POST.HOUSE_CAT_MATING_END_BE.sglName then
        self:InviteeMatingEnd(body)
    elseif name == POST.HOUSE_CAT_MATING_HOUSE.sglName then
        self:AddNewBreedData(body.leftSeconds, body.requestData.playerCatId)
    elseif name == POST.HOUSE_CAT_MATING_CANCEL.sglName then
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
        self:DelBreedData(body.requestData.playerCatId)
    elseif name == SGL.CAT_HOUSE_BREED_LIST_SELECTED then
        self:SendSignal(POST.HOUSE_CAT_MATING_HOUSE.cmdName, {playerCatId = body.catModel:getPlayerCatId()})
    elseif name == SGL.CAT_HOUSE_BREED_PAIRING_CANCEL then
        self:SendSignal(POST.HOUSE_CAT_MATING_CANCEL.cmdName, {playerCatId = body.catModel:getPlayerCatId()})
    elseif name == SGL.CAT_MODULE_CAT_REFRESH_UPDATE then
        self:RefreshView()
    elseif name == SGL.CAT_HOUSE_ACCEPT_BREED_INVITE then
        if checkint(body.result) == 1 then
            if app:RetrieveMediator('catHouse.CatHouseBreedChoiceMediator') then
                app:RetrieveMediator('catHouse.CatHouseBreedChoiceMediator'):Close(body.playCatId)
            end
            self:EnterLayer()
        end
    elseif name == SGL.CAT_HOUSE_HOUSE_LEFT_SECONDS_ZERO then
        if app:RetrieveMediator('catHouse.CatHouseBreedChoiceMediator') then
            app:RetrieveMediator('catHouse.CatHouseBreedChoiceMediator'):Close(body.playCatId)
        end
        self:EnterLayer()
    end
end

function CatHouseBreedMediator:OnRegist()
    regPost(POST.HOUSE_CAT_MATING)
    regPost(POST.HOUSE_CAT_MATING_HOUSE)
    regPost(POST.HOUSE_CAT_MATING_END_TO)
    regPost(POST.HOUSE_CAT_MATING_END_BE)
    regPost(POST.HOUSE_CAT_MATING_CANCEL)
    regPost(POST.HOUSE_CAT_SYNC)
    self:EnterLayer()
end

function CatHouseBreedMediator:OnUnRegist()
    unregPost(POST.HOUSE_CAT_MATING)
    unregPost(POST.HOUSE_CAT_MATING_HOUSE)
    unregPost(POST.HOUSE_CAT_MATING_END_TO)
    unregPost(POST.HOUSE_CAT_MATING_END_BE)
    unregPost(POST.HOUSE_CAT_MATING_CANCEL)
    unregPost(POST.HOUSE_CAT_SYNC)
end

function CatHouseBreedMediator:EnterLayer()
    self:SendSignal(POST.HOUSE_CAT_MATING.cmdName)
end

function CatHouseBreedMediator:CleanupView()
    -- 移除界面
    if self:GetViewComponent() and not tolua.isnull(self:GetViewComponent()) then
        self:GetViewComponent():removeFromParent()
        self:SetViewComponent(nil)
    end
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
返回主界面
--]]
function CatHouseBreedMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end
--[[
道具列表刷新
--]]
function CatHouseBreedMediator:OnUpdateListCellHandler( cellIndex, cellViewData )
    local data = self:GetBreedData()[cellIndex] or {state = CatHouseUtils.CAT_BREED_STATE.EMPTY}
    cellViewData.breedListNode:RefreshNode({index = cellIndex, breedData = data})
end
--[[
道具列表cell初始化
--]]
function CatHouseBreedMediator:OnInitListCellHandler( cellViewData )
    cellViewData.breedListNode:SetClickHandler(handler(self, self.CellButtonCallback))
end
--[[
列表cell点击回调
--]]
function CatHouseBreedMediator:CellButtonCallback( sender )
    local tag = sender:getTag()
    local breedData = self:GetBreedData()[tag]
    PlayAudioByClickNormal()
    if breedData.state == CatHouseUtils.CAT_BREED_STATE.FINISH then
        self:MatingEnd(breedData)
    elseif breedData.state == CatHouseUtils.CAT_BREED_STATE.CREATE then
        if app.goodsMgr:GetGoodsAmountByGoodsId(CatHouseUtils.CAT_PARAM_FUNCS.BIRTH_CONSUME()[1].goodsId) >= CatHouseUtils.CAT_PARAM_FUNCS.BIRTH_CONSUME()[1].num then
            local mediator = require("Game.mediator.catHouse.CatHouseBreedChoiceMediator").new({breedData = breedData})
	        app:RegistMediator(mediator)
        else
            local conf = CommonUtils.GetConfig('goods', 'goods', CatHouseUtils.CAT_PARAM_FUNCS.BIRTH_CONSUME()[1].goodsId) or {}
            app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {['_name_'] = tostring(conf.name)}))
        end
    else
        local mediator = require("Game.mediator.catHouse.CatHouseBreedChoiceMediator").new({breedData = breedData})
	    app:RegistMediator(mediator)
    end
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function CatHouseBreedMediator:RefreshView()
    self:ConvertBreedData()
    local viewData = self:GetViewComponent().viewData
    local gridView = viewData.catteryGridView
    local cellAmount = self:CalculateGridViewCellAmount()
    viewData.catteryGridView:resetCellCount(cellAmount, false, true)
end
--[[
转换breedData
--]]
function CatHouseBreedMediator:ConvertBreedData()
    local catModelMap = app.catHouseMgr:getCatsModelMap()
    local breedData = {}
    -- 第一个位置是固定的，用于新建配对
    local empty = {
        state = CatHouseUtils.CAT_BREED_STATE.CREATE
    }
    table.insert(breedData, empty)
    for id, catModel in pairs(catModelMap) do
        local state = nil
        if catModel:hasMatingData() then
            if catModel:getMatingLeftSeconds() <= 0 then
                state = CatHouseUtils.CAT_BREED_STATE.FINISH
            else
                state = CatHouseUtils.CAT_BREED_STATE.BREEDING
            end
            table.insert(breedData, {state = state, catModel = catModel})
        else
            if catModel:isMatingInviteEmpty() then
                if catModel:getHouseLeftSeconds() > 0 then
                    state = CatHouseUtils.CAT_BREED_STATE.PAIRING
                    table.insert(breedData, {state = state, catModel = catModel})
                end
            else
                state = CatHouseUtils.CAT_BREED_STATE.PAIRING
                table.insert(breedData, {state = state, catModel = catModel})
            end
        end
    end
    self:SetBreedData(breedData)
end
--[[
计算列表cell数量
@return amount int 数量
--]]
function CatHouseBreedMediator:CalculateGridViewCellAmount()
    local breedData = self:GetBreedData()
    local amount = #breedData
    local remainder = amount % 3
    if remainder ~= 0 then
        amount = amount + 3 - remainder
    end
    return amount
end
--[[
新增breedData
@params matingHouseLeftSeconds int 生育等待时间
@params playerCatId int 玩家猫咪id
--]]
function CatHouseBreedMediator:AddNewBreedData( matingHouseLeftSeconds, playerCatId )
    -- 扣除道具
    app.goodsMgr:DrawRewards({
        {goodsId = CatHouseUtils.CAT_PARAM_FUNCS.BIRTH_CONSUME()[1].goodsId, num = -1}
    })
    -- 更新数据
    local catUuid = CatHouseUtils.BuildCatUuid(app.gameMgr:GetPlayerId(), playerCatId)
    local catModel = app.catHouseMgr:getCatModel(catUuid)
    local breedData = self:GetBreedData()
    catModel:cleanMatingInvite()
    catModel:setHouseLeftSeconds(matingHouseLeftSeconds)
    local args = {
        state = CatHouseUtils.CAT_BREED_STATE.PAIRING,
        catModel = catModel
    }
    app:DispatchObservers(SGL.CAT_HOUSE_BREED_REFRESH_CHOICE_VIEW, args)
    table.insert(breedData, args)
    self:RefreshView()
end
--[[
删除breedData
--]]
function CatHouseBreedMediator:DelBreedData( playerCatId )
    local breedData = self:GetBreedData()
    local index = nil
    for i, v in ipairs(breedData) do
        if v.catModel and checkint(v.catModel:getPlayerCatId()) == checkint(playerCatId) then
            v.catModel:setHouseLeftSeconds(0)
            v.catModel:cleanMatingInvite()
            index = i
            break
        end
    end
    if index then
        table.remove(breedData, index)
        self:RefreshView()
    end
end
--[[
邀请者交配结束
    requestData map 请求数据
    cats        map 新生猫咪信息
    birthCdTime int 生育cd时间
--]]
function CatHouseBreedMediator:InviterMatingEnd( params )
    app.catHouseMgr:catMatingEnd(params.requestData.playerCatId, params.birthCdTime)
    app.catHouseMgr:checkSyncCatDataByMatingEnded(params.requestData.playerCatId)
    self:RefreshView()
    -- 猫咪可能一次生育多只小猫
    self.newCatList = {}
    for i, v in ipairs(params.cats) do
        table.insert(self.newCatList, v.playerCatId)
        v.outLeftTimes    = CatHouseUtils.CAT_PARAM_FUNCS.OUT_MAX()
        v.outMaxTimes     = CatHouseUtils.CAT_PARAM_FUNCS.OUT_MAX()
        v.leftActionTimes = CatHouseUtils.CAT_PARAM_FUNCS.MAX_ACTION_TIMES()
        app.catHouseMgr:setCatModel(v.playerCatId, v)
    end
    self:ShowCatPreview()
end

function CatHouseBreedMediator:ShowCatPreview()
    local catList = self.newCatList
    if next(catList) ~= nil then
        local playerCatId = catList[1]
        table.remove(catList, 1)
        self:GetViewComponent():BreedEndAnimation(playerCatId, handler(self, self.ShowCatPreview))
    end
end
--[[
受邀者交配结束
@params {
    requestData map 请求数据
    rewards list 返还奖励
    birthCdTime int 生育cd时间
}
--]]
function CatHouseBreedMediator:InviteeMatingEnd( params )
    if params.rewards and next(params.rewards) ~= nil then
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = params.rewards})
    else
        app.uiMgr:ShowInformationTips(__('今日奖励获取已达上限'))
    end
    app.catHouseMgr:catMatingEnd(params.requestData.playerCatId, params.birthCdTime)
    app.catHouseMgr:checkSyncCatDataByMatingEnded(params.requestData.playerCatId)
    self:RefreshView()
end
--[[
展示生育详情页面
responseData map {
    tips list 提示列表 {
        playerCatId int 玩家猫咪id
        type int 1:成功 2:失败
    }
}
--]]
function CatHouseBreedMediator:ShowBreedInfo( responseData )
    if not responseData.tips or next(responseData.tips) == nil then return end
    local mediator = require('Game.mediator.catHouse.CatHouseBreedInfoMediator').new({tips = responseData.tips})
    app:RegistMediator(mediator)
end
--[[
预载一只猫咪
--]]
function CatHouseBreedMediator:PreLoadCat( catUuid )
    if not catUuid then return end

    local breedData = self:GetBreedData()
    for i, v in ipairs(breedData) do
        if v.catModel and v.catModel:getUuid() == catUuid then
            if v.state == CatHouseUtils.CAT_BREED_STATE.FINISH then
                self:MatingEnd(v)
                return
            else
                local mediator = require("Game.mediator.catHouse.CatHouseBreedChoiceMediator").new({breedData = v})
                app:RegistMediator(mediator)
                return
            end
        end
    end

    if app.goodsMgr:GetGoodsAmountByGoodsId(CatHouseUtils.CAT_PARAM_FUNCS.BIRTH_CONSUME()[1].goodsId) >= CatHouseUtils.CAT_PARAM_FUNCS.BIRTH_CONSUME()[1].num then
        local mediator = require("Game.mediator.catHouse.CatHouseBreedChoiceMediator").new({breedData = breedData[1], catUuid = catUuid})
        app:RegistMediator(mediator)
    else
        local conf = CommonUtils.GetConfig('goods', 'goods', CatHouseUtils.CAT_PARAM_FUNCS.BIRTH_CONSUME()[1].goodsId) or {}
        app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {['_name_'] = tostring(conf.name)}))
    end
end
--[[
生育完成
--]]
function CatHouseBreedMediator:MatingEnd( breedData )
    if checkint(breedData.catModel:getMatingData().isInvite) == 1 then
        -- 邀请者
        if table.nums(app.catHouseMgr:getCatsModelMap()) < app.catHouseMgr:getCatWarehouseCapacity() then
            self:SendSignal(POST.HOUSE_CAT_MATING_END_TO.cmdName, {playerCatId = breedData.catModel:getPlayerCatId()})
        else
            app.uiMgr:ShowInformationTips(__('仓库已满，无法领取'))
        end
    else
        -- 被邀请者
        self:SendSignal(POST.HOUSE_CAT_MATING_END_BE.cmdName, {playerCatId = breedData.catModel:getPlayerCatId()})
    end
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置breedData
--]]
function CatHouseBreedMediator:SetBreedData( breedData )
    self.breedData = checktable(breedData)
end
--[[
获取breedData
--]]
function CatHouseBreedMediator:GetBreedData()
    return self.breedData or {}
end
------------------- get / set -------------------
-------------------------------------------------
return CatHouseBreedMediator