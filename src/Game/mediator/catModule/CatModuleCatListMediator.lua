--[[
 * author : panmeng
 * descpt : 猫咪列表
]]

local CatModuleCatListView     = require('Game.views.catModule.CatModuleCatListView')
local CatModuleCatListMediator = class('CatModuleCatListMediator', mvc.Mediator)

function CatModuleCatListMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatModuleCatListMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

local SORT_TAG = CatModuleCatListView.SORT_TAG

-------------------------------------------------
-- inheritance

function CatModuleCatListMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true
    self.sortType_       = self.ctorArgs_.sortType or SORT_TAG.GAINTIME
    self.selectedCatId_  = self.ctorArgs_.selectedCatId

    -- create view
    self.viewNode_ = CatModuleCatListView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    ui.bindClick(self:getViewData().siftBtn, handler(self, self.onClickSiftBtnHandler_))
    ui.bindClick(self:getFilterViewData().blockLayer, handler(self, self.onClickSortCloseBtnHandler_), false)
    ui.bindClick(self:getViewData().progressAddBtn, handler(self, self.onClickProAddBtnHandler_))
    
    for _, btnCell in pairs(self:getFilterViewData().sortCellNodeMap) do
        ui.bindClick(btnCell, handler(self, self.onClickSortTypeBtnHandler_), false)
    end
    self:getViewData().catGridView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.view, handler(self, self.onClickCatNodeBtnHandler_))
    end)
    self:getViewData().catGridView:setCellUpdateHandler(handler(self, self.onUpdateCatCellHandler_))

    self:initPageView()
    self:setSelectedSortType(self.sortType_, self.ctorArgs_.isReverse)

    -- offset to prev selectIndex
    if self.selectedCatId_ then
        local catGridView = self:getViewData().catGridView
        local containSize = catGridView:getContainerSize()
        local contentSize = catGridView:getContentSize()
        for index, catId in ipairs(self:getCatUuidList()) do
            if catId == self.selectedCatId_ then
                local catCellRow = math.ceil(index / catGridView:getColumns())
                local catCellHeight = catCellRow * catGridView:getSizeOfCell().height
                catGridView:setContentOffset(cc.p(0, -containSize.height + math.max(catCellHeight, contentSize.height)))
                break
            end
        end
    end
end


function CatModuleCatListMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function CatModuleCatListMediator:OnRegist()
    regPost(POST.HOUSE_CAT_EXTEND)
end


function CatModuleCatListMediator:OnUnRegist()
    unregPost(POST.HOUSE_CAT_EXTEND)
end


function CatModuleCatListMediator:InterestSignals()
    return {
        POST.HOUSE_CAT_EXTEND.sglName,
        SGL.CAT_MODULE_CAT_REFRESH_UPDATE,
        SGL.CAT_MODEL_UPDATE_AGE,
        SGL.CAT_MODEL_UPDATE_ALIVE,
    }
end
function CatModuleCatListMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -- 仓库扩容
    if name == POST.HOUSE_CAT_EXTEND.sglName then
        -- udate goods
        app.goodsMgr:DrawRewards(GoodsUtils.GetMultipCostList(CatHouseUtils.CAT_PARAM_FUNCS.WAREHOUSE_CONSUME()))

        -- update data
        app.catHouseMgr:setCatWarehouseCapacity(app.catHouseMgr:getCatWarehouseCapacity() + CatHouseUtils.CAT_WAREHOUSE_EXPAND_NUM)

        -- update view
        self:getViewNode():playExtendAnim()
        self:updateWareHouseNum()


    -- 更新猫咪数据
    elseif name == SGL.CAT_MODULE_CAT_REFRESH_UPDATE then
        -- update time
        self:onBreedRefreshUpdateHandler_()


    -- 更新年龄
    elseif name == SGL.CAT_MODEL_UPDATE_AGE then
        for _, cellViewData in pairs(self:getViewData().catGridView:getCellViewDataDict()) do
            local catId = cellViewData.view.catUuid
            if catId == data.catUuid then
                self:getViewNode():updateCatCellAge(cellViewData, data.catModel:getAge())
                break
            end
        end


    -- 更新存活
    elseif name == SGL.CAT_MODEL_UPDATE_ALIVE then
        for _, cellViewData in pairs(self:getViewData().catGridView:getCellViewDataDict()) do
            local catId = cellViewData.view.catUuid
            if catId == data.catUuid then
                self:getViewNode():updateAliveState(cellViewData, data.catModel:isAlive())
                break
            end
        end


    end
end


-------------------------------------------------
-- get / set

function CatModuleCatListMediator:getViewNode()
    return  self.viewNode_
end
function CatModuleCatListMediator:getViewData()
    return self:getViewNode():getViewData()
end


function CatModuleCatListMediator:getFilterViewData()
    return self:getViewNode():getFilterViewData()
end


function CatModuleCatListMediator:setSelectedSortType(sortType, isReverse)
    self.selectedSortType_ = checkint(sortType)

    self.isCurChooseReverse_ = self:getViewNode():setSelectedSortType(self:getSelectedSortType(), isReverse)
    self:sortCatListData(self:getSelectedSortType(), self:isCurChooseReverse())
    self:getViewData().catGridView:resetCellCount(#self:getCatUuidList())
end
function CatModuleCatListMediator:getSelectedSortType()
    return checkint(self.selectedSortType_)
end


function CatModuleCatListMediator:isCurChooseReverse()
    return checkbool(self.isCurChooseReverse_)
end

function CatModuleCatListMediator:getCatUuidList()
    return checktable(self.catUuidList_)
end


-------------------------------------------------
-- public

function CatModuleCatListMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end

function CatModuleCatListMediator:initPageView()
    self:updateWareHouseNum()

    self.catUuidList_ = table.keys(app.catHouseMgr:getCatsModelMap())
    self:getViewData().catGridView:resetCellCount(table.nums(app.catHouseMgr:getCatsModelMap()))
end

function CatModuleCatListMediator:updateWareHouseNum()
    self:getViewNode():setCatWarehouseCapacity(table.nums(app.catHouseMgr:getCatsModelMap()), app.catHouseMgr:getCatWarehouseCapacity())
end


-------------------------------------------------
-- private
function CatModuleCatListMediator:sortCatListData(sortType, isAsc)
    local SORT_FUNC = {
        [SORT_TAG.ALGEBRA]  = {'getGeneration'},
        [SORT_TAG.GAINTIME] = {'getCreateTime'},
        [SORT_TAG.AGE]      = {'getAge'},
        [SORT_TAG.STATUE]   = {'isDie', 'isSicked', 'isMating', 'isWorking', 'isStudying', 'isOutGoing', 'isSleeping', 'isToileting'},
        --优先级来 死亡→生病→交配→工作→学习→外出→睡觉→厕所
    }
    if #self:getCatUuidList() <= 1 then
        return
    end
    table.sort(self:getCatUuidList(), function(catIdA, catIdB)
        local modelA = app.catHouseMgr:getCatModel(catIdA)
        local modelB = app.catHouseMgr:getCatModel(catIdB)

        if not modelB then
            return false
        end

        local isExchange     = nil
        local funcNameGroup  = SORT_FUNC[sortType]
        for _, funcName in ipairs(funcNameGroup) do
            local catValueA = modelA[funcName](modelA)
            local catValueB = modelB[funcName](modelB)

            if catValueA ~= catValueB then
                if type(catValueA) == 'boolean' then
                    if isAsc then
                        isExchange = catValueA
                    else
                        isExchange = catValueB
                    end
                    break 
                else
                    if isAsc then
                        isExchange = catValueA > catValueB
                    else
                        isExchange = catValueA < catValueB
                    end
                    break 
                end
            end
        end

        if isExchange ~= nil then
            return isExchange
        else
            return catIdA > catIdB
        end
    end)
end


function CatModuleCatListMediator:onUpdateCatCellHandler_(cellIndex, cellViewData)
    -- 获取到猫咪的数据
    local catUuid = self:getCatUuidList()[cellIndex]
    self:getViewNode():updateCatCellHandler(cellIndex, cellViewData, catUuid)
end


function CatModuleCatListMediator:onBreedRefreshUpdateHandler_()
    for _, cellViewData in pairs(self:getViewData().catGridView:getCellViewDataDict()) do
        local catId    = cellViewData.view.catUuid
        local catModel = app.catHouseMgr:getCatModel(catId)
        self:getViewNode():refreshBreedTime(cellViewData, catModel)
    end
end


-------------------------------------------------
-- handler

function CatModuleCatListMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:close()
end


function CatModuleCatListMediator:onClickCatNodeBtnHandler_(sender)
    PlayAudioByClickNormal()

    local catUuid = sender.catUuid
    local closeCB = function()
        local catListMdt = require('Game.mediator.catModule.CatModuleCatListMediator').new({selectedCatId = catUuid, sortType = self:getSelectedSortType(), isReverse = self:isCurChooseReverse() and 1 or 0})
        app:RegistMediator(catListMdt)
    end
    local catHouseInfoMdt = require('Game.mediator.catModule.CatModuleCatInfoMediator').new({catUuid = catUuid, closeCB = closeCB})
    app:RegistMediator(catHouseInfoMdt)
    self:close()
end


function CatModuleCatListMediator:onClickSiftBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():setFilterLayerVisible(true)
end


function CatModuleCatListMediator:onClickSortCloseBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():setFilterLayerVisible(false)
end


function CatModuleCatListMediator:onClickSortTypeBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:setSelectedSortType(sender:getTag())
end


function CatModuleCatListMediator:onClickProAddBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local maxWarehouseOpacity  = CatHouseUtils.CAT_PARAM_FUNCS.WAREHOUSE_MAX_NUM()
    local initWarehouseOpacity = CatHouseUtils.CAT_PARAM_FUNCS.WAREHOUSE_INIT_NUM()
    local expandCostConfs      = CatHouseUtils.CAT_PARAM_FUNCS.WAREHOUSE_CONSUME()
    app.uiMgr:AddCommonTipDialog({
        descr    = string.fmt(__("使用_goodsInfo_购买_num_个仓库位置(可购次数_num1_/_num2_)"), {
                _goodsInfo_ = GoodsUtils.GetMultipleConsumeStr(expandCostConfs),
                _num_       = CatHouseUtils.CAT_WAREHOUSE_EXPAND_NUM,
                _num1_      = maxWarehouseOpacity - app.catHouseMgr:getCatWarehouseCapacity(),
                _num2_      = maxWarehouseOpacity - initWarehouseOpacity,
            }) ,
        callback = handler(self, self.onClickConsumeBtnHandler_),
        text = string.fmt(__("是否扩充_num_个仓库位置"), {_num_ = CatHouseUtils.CAT_WAREHOUSE_EXPAND_NUM}),
    })
end


function CatModuleCatListMediator:onClickConsumeBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local maxCathouseOpacity = CatHouseUtils.CAT_PARAM_FUNCS.WAREHOUSE_MAX_NUM()
    if CatHouseUtils.CAT_PARAM_FUNCS.WAREHOUSE_MAX_NUM() - app.catHouseMgr:getCatWarehouseCapacity() <= 0 then
        app.uiMgr:ShowInformationTips(__("可购次数不足"))
    else
        if GoodsUtils.CheckMultipCosts(CatHouseUtils.CAT_PARAM_FUNCS.WAREHOUSE_CONSUME(), true) then
            self:SendSignal(POST.HOUSE_CAT_EXTEND.cmdName)
        end 
    end
end


return CatModuleCatListMediator