local CatModuleCatLifeView     = require('Game.views.catModule.CatModuleCatLifeView')
local CatModuleCatLifeMediator = class('CatModuleCatLifeMediator', mvc.Mediator)

function CatModuleCatLifeMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatModuleCatLifeMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

local RELOAD_GRIDVIEW = 1
local FEED_GOOD_TYPE  = CatModuleCatLifeView.FEED_GOOD_TYPE
local CAT_LIVE_TYPE   = CatModuleCatLifeView.CAT_LIVE_TYPE
local CAT_LIVE_FUNC   = {
    [CAT_LIVE_TYPE.FEED]   = function(self, playerCatId, goodId)
        local canEat = true
        if self:getSelectedFeedGoodType() == FEED_GOOD_TYPE.FOOD then
            local feedLimit = self:getCatModel():getLimitFeedQuality()
            if feedLimit > 0 and GoodsUtils.GetGoodsQualityById() < feedLimit then
                app.uiMgr:ShowInformationTips(__("猫咪进入挑食状态, 不接受该品质的食物"))
                canEat = false
            elseif self:getCatModel():isDisableFeed() then
                app.uiMgr:ShowInformationTips(__("猫咪抑郁不振, 拒绝了你的投喂"))
                canEat = false
            end
        end
        if canEat then
            self:SendSignal(POST.HOUSE_CAT_ACT_FEED.cmdName, {playerCatId = playerCatId, goodsId = goodId})
        else
            AppFacade.GetInstance():DispatchObservers(SGL.CAT_MODULE_CAT_PLAY_REFUSE_ANIM)
        end
    end,
    [CAT_LIVE_TYPE.PLAY]   = function(self, playerCatId, goodId)
        self:SendSignal(POST.HOUSE_CAT_ACT_PLAY.cmdName, {playerCatId = playerCatId, goodsId = goodId})
    end,
    [CAT_LIVE_TYPE.BATH]   = function(self, playerCatId, goodId)
        self:SendSignal(POST.HOUSE_CAT_ACT_SHOWER.cmdName, {playerCatId = playerCatId, goodsId = goodId}) 
    end,
    [CAT_LIVE_TYPE.SLEEP]  = function(self, playerCatId, goodId)
        if self:getCatModel():isDisableSleep() then
            app.uiMgr:ShowInformationTips(__("猫咪陷入亢奋状态, 无法入睡"))
            AppFacade.GetInstance():DispatchObservers(SGL.CAT_MODULE_CAT_PLAY_REFUSE_ANIM)
        else
            self:SendSignal(POST.HOUSE_CAT_ACT_SLEEP.cmdName,  {playerCatId = playerCatId, avatarId = goodId})
        end
    end,
    [CAT_LIVE_TYPE.TOILET] = function(self, playerCatId, goodId) 
        if self:getCatModel():isDisableToilet() then
            app.uiMgr:ShowInformationTips(__("猫咪身体不适，无法正常上厕所"))
            AppFacade.GetInstance():DispatchObservers(SGL.CAT_MODULE_CAT_PLAY_REFUSE_ANIM)
        else
            self:SendSignal(POST.HOUSE_CAT_ACT_TOILET.cmdName, {playerCatId = playerCatId, avatarId = goodId}) 
        end
    end,
}


-------------------------------------------------
-- inheritance

function CatModuleCatLifeMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true
    self.allGoodData_    = {}

    -- create view
    self.viewNode_ = CatModuleCatLifeView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().shopBtn, handler(self, self.onClickShopButtonHandler_))
    ui.bindClick(self:getViewData().useBtn, handler(self, self.onClickUseButtonHandler_))
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    for _, lifeBtn in pairs(self:getViewData().lifeBtnGroup) do
        ui.bindClick(lifeBtn, handler(self, self.onClickGoodTypeButtonHandler_), false)
    end
    for _, titleBtn in pairs(self:getViewData().goodsTypeBtns) do
        titleBtn:setOnClickScriptHandler(handler(self, self.onClickFeedGoodTypeButtonHandler_))
    end
    self:getViewData().goodsGridView:setCellUpdateHandler(function(cellIndex, goodNode)
        local data = self:getGoodDataByType(self:getSelectedCatLiveType(), self:getSelectedFeedGoodType())[cellIndex]
        goodNode:RefreshSelf(data)
        goodNode:updateSelectedImgVisible(data.goodsId == self:getSelectedGoodId())
        goodNode:updateNewImgVisible(data.isNew)
        goodNode:setTag(cellIndex)
    end)
    self:getViewData().goodsGridView:setCellInitHandler(function(goodNode)
        goodNode:alignTo(nil, ui.cc)
        ui.bindClick(goodNode, handler(self, self.onClickGoodBtnHandler_))
    end)
    self:getViewData().illTableView:setCellUpdateHandler(function(cellIndex, cellViewData)
        cellViewData.bg:setVisible(cellIndex % 2 == 0)
        local stateId   = self:getSickIdList()[cellIndex]
        local stateConf = CONF.CAT_HOUSE.CAT_STATUS:GetValue(stateId)
        cellViewData.descr:updateLabel({text = tostring(stateConf.name), reqW = 340})
    end)


    -- update view
    self:setCatUuid(self.ctorArgs_.catUuid)
    self:initGoodDatas()
    self:setSelectedFeedGoodType(FEED_GOOD_TYPE.FOOD)
    self:setSelectedCatLiveType(CAT_LIVE_TYPE.FEED)
end


function CatModuleCatLifeMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function CatModuleCatLifeMediator:OnRegist()
    regPost(POST.HOUSE_CAT_ACT_FEED)
    regPost(POST.HOUSE_CAT_ACT_PLAY)
    regPost(POST.HOUSE_CAT_ACT_SHOWER)
    regPost(POST.HOUSE_CAT_ACT_SLEEP)
    regPost(POST.HOUSE_CAT_ACT_TOILET)
end


function CatModuleCatLifeMediator:OnUnRegist()
    unregPost(POST.HOUSE_CAT_ACT_FEED)
    unregPost(POST.HOUSE_CAT_ACT_PLAY)
    unregPost(POST.HOUSE_CAT_ACT_SHOWER)
    unregPost(POST.HOUSE_CAT_ACT_SLEEP)
    unregPost(POST.HOUSE_CAT_ACT_TOILET)
end


function CatModuleCatLifeMediator:InterestSignals()
    return {
        POST.HOUSE_CAT_ACT_FEED.sglName,
        POST.HOUSE_CAT_ACT_PLAY.sglName,
        POST.HOUSE_CAT_ACT_SHOWER.sglName,
        POST.HOUSE_CAT_ACT_SLEEP.sglName,
        POST.HOUSE_CAT_ACT_TOILET.sglName,
        SGL.BACKPACK_GOODS_REFRESH,
        SGL.CAT_MODULE_CAT_LIFE_ACTION_END,
        SGL.CAT_MODEL_APPEND_STATE,
        SGL.CAT_MODEL_REMOVE_STATE,
        SGL.CAT_MODEL_UPDATE_ATTR_NUM,
    }
end
function CatModuleCatLifeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -- 猫咪喂食
    if name == POST.HOUSE_CAT_ACT_FEED.sglName then
        self.isControllable_ = false

        -- update attr data
        for attrId, attrValue in pairs(data.attr or {}) do
            self:getCatModel():setAttrNum(attrId, attrValue)
        end
        -- del state data
        local recureState = nil
        if checkint(data.eliminateStatusId) > 0 and self:getCatModel():getPhysicalStateLeftSeconds(data.eliminateStatusId) > 0 then
            self:getCatModel():delPhysicalState(data.eliminateStatusId)
            recureState = data.eliminateStatusId
        end
        -- add state data
        local goodConf = CONF.CAT_HOUSE.CAT_GOODS_INFO:GetValue(data.requestData.goodsId)
        if checkint(goodConf.effectStatusId) > 0 and checkint(data.statusLeftSeconds) > 0 then
            self:getCatModel():addPhysicalState(goodConf.effectStatusId, data.statusLeftSeconds)
        end
        -- update age
        local changeAgeId = checkint(goodConf.changeAgeId)
        if changeAgeId > 0 and self:getCatModel():getAge() > changeAgeId then
            local ageConf = CONF.CAT_HOUSE.CAT_AGE:GetValue(changeAgeId)
            self:getCatModel():setNextAgeLeftSeconds(ageConf.growthTime)
            self:getCatModel():setAge(changeAgeId)
            if CatHouseUtils.IsCatEquipped(self:getCatModel():getUuid()) then
                -- 装备中的猫咪年龄改变需要刷新装备信息
                app.catHouseMgr:equipCat(self:getCatModel():getUuid())
            end
        end

        -- update goods
        app.goodsMgr:DrawRewards({
            {goodsId = data.requestData.goodsId, num = -1}
        })

        -- update view
        self:getViewNode():setVisible(false)
        AppFacade.GetInstance():DispatchObservers(SGL.CAT_MODULE_CAT_LIFE_ACTION_START, {
            recureState = recureState,
            goodsId     = data.requestData.goodsId
        })

    -- 猫咪玩耍
    elseif name == POST.HOUSE_CAT_ACT_PLAY.sglName then
        self.isControllable_ = false

        -- update goods
        app.goodsMgr:DrawRewards({
            {goodsId = data.requestData.goodsId, num = -1}
        })

        -- update data
        for attrId, attrValue in pairs(data.attr or {}) do
            self:getCatModel():setAttrNum(attrId, attrValue)
        end

        -- update view
        self:getViewNode():setVisible(false)
        AppFacade.GetInstance():DispatchObservers(SGL.CAT_MODULE_CAT_LIFE_ACTION_START, {
            goodsId = data.requestData.goodsId
        })

    -- 猫咪洗澡
    elseif name == POST.HOUSE_CAT_ACT_SHOWER.sglName then
        self.isControllable_ = false

        -- update goods
        app.goodsMgr:DrawRewards({
            {goodsId = data.requestData.goodsId, num = -1}
        })

        -- update data
        for attrId, attrValue in pairs(data.attr or {}) do
            self:getCatModel():setAttrNum(attrId, attrValue)
        end

        -- update view
        self:getViewNode():setVisible(false)
        AppFacade.GetInstance():DispatchObservers(SGL.CAT_MODULE_CAT_LIFE_ACTION_START, {
            goodsId = data.requestData.goodsId
        })

    -- 猫咪睡觉
    elseif name == POST.HOUSE_CAT_ACT_SLEEP.sglName then
        -- updata data
        self:getCatModel():setSleepLeftSeconds(data.leftSeconds)

        -- update view
        app.uiMgr:ShowInformationTips(__("使用成功"))


    -- 猫咪如厕
    elseif name == POST.HOUSE_CAT_ACT_TOILET.sglName then        
        -- updata data
        self:getCatModel():setToiletLeftSeconds(data.leftSeconds)

        -- update view
        app.uiMgr:ShowInformationTips(__("使用成功"))


    -- 猫咪道具刷新
    elseif name == SGL.BACKPACK_GOODS_REFRESH then
        if GoodsType.TYPE_CAT_GOODS == data.goodsType or GoodsType.TYPE_HOUSE_AVATAR == data.goodsType then
            self:updateGoodData(data)
        end


    -- 生活交互结束
    elseif name == SGL.CAT_MODULE_CAT_LIFE_ACTION_END then
        self:getViewNode():setVisible(true)
        self.isControllable_ = true

    
    -- 新增状态
    elseif name == SGL.CAT_MODEL_APPEND_STATE then
        if data.catUuid == self:getCatUuid() then
            self:resetSickIdList()
            self:getViewNode():updateSickView(self:getCatModel())
        end


    -- 移除状态
    elseif name == SGL.CAT_MODEL_REMOVE_STATE then
        if data.catUuid == self:getCatUuid() then
            self:resetSickIdList()
            self:getViewNode():updateSickView(self:getCatModel())
        end

    
    -- 更新属性值
    elseif name == SGL.CAT_MODEL_UPDATE_ATTR_NUM then
        if data.catUuid == self:getCatUuid() and self:getViewNode():getDisplayAttrId(self:getSelectedCatLiveType()) == checkint(data.attrId) then
            self:getViewNode():updateAttrNum(self:getCatModel(), data.attrId)
        end


    end
end


-------------------------------------------------
-- get / set
function CatModuleCatLifeMediator:getViewNode()
    return  self.viewNode_
end
function CatModuleCatLifeMediator:getViewData()
    return self:getViewNode():getViewData()
end


-- cat uuid
function CatModuleCatLifeMediator:getCatUuid()
    return self.catUuid_
end
function CatModuleCatLifeMediator:setCatUuid(catUuid)
    self.catUuid_  = catUuid
    self.catModel_ = app.catHouseMgr:getCatModel(self:getCatUuid())
    self:resetSickIdList()
    self:getViewNode():updateSickView(self:getCatModel())
end


---@return HouseCatModel
function CatModuleCatLifeMediator:getCatModel()
    return self.catModel_
end
function CatModuleCatLifeMediator:getPlayerCatId()
    return self:getCatModel():getPlayerCatId()
end



-- set/get  cat live type
function CatModuleCatLifeMediator:setSelectedCatLiveType(index)
    local oldSelectedCatLiveType = self:getSelectedCatLiveType()
    self.selectedCatLiveType_ = checkint(index)
    if oldSelectedCatLiveType == self:getSelectedCatLiveType() then
        return
    end
    self:getViewNode():updateGoodLifeBtnStatue(oldSelectedCatLiveType, self:getSelectedCatLiveType())
    self:getViewNode():reSizeGoodsPage(oldSelectedCatLiveType, self:getSelectedCatLiveType())
    self:updatePageView_()
end
function CatModuleCatLifeMediator:getSelectedCatLiveType()
    return checkint(self.selectedCatLiveType_)
end


-- set/get good id
function CatModuleCatLifeMediator:setSelectedGoodData(goodData)
    self.selectedGoodData_ = checktable(goodData)
    self.selectedGoodId_   = checkint(self:getSelectedGoodData().goodsId)
    if self:getSelectedGoodId() > 0 then
        app.gameMgr:UpdateBackpackNewStatuByGoodId(self:getSelectedGoodId())
        self:getSelectedGoodData().isNew = false

        -- update view
        for _, goodNode in pairs(self:getViewData().goodsGridView:getCellViewDataDict()) do
            goodNode:updateSelectedImgVisible(goodNode.goodId == self:getSelectedGoodId())
        end
    end
    
    self:getViewNode():refreshGoodDetailView(self:getSelectedGoodId(), self:getSelectedCatLiveType(), self:getCatModel())
end
function CatModuleCatLifeMediator:getSelectedGoodId()
    return checkint(self.selectedGoodId_)
end
function CatModuleCatLifeMediator:getSelectedGoodData()
    return checktable(self.selectedGoodData_)
end


-- set/get feed good type
function CatModuleCatLifeMediator:setSelectedFeedGoodType(typeIndex)
    local oldFeedGoodTypeIndex   = self:getSelectedFeedGoodType()
    self.selectedFeedGoodTypeId_ = checkint(typeIndex)
    if oldFeedGoodTypeIndex == self:getSelectedFeedGoodType() then
        return
    end
    for _, typeBtn in pairs(self:getViewData().goodsTypeBtns) do
        typeBtn:setChecked(checkint(typeBtn:getTag()) == self.selectedFeedGoodTypeId_)
    end
    self:updatePageView_()
end
function CatModuleCatLifeMediator:getSelectedFeedGoodType()
    return checkint(self.selectedFeedGoodTypeId_)
end


-- get sickId List
function CatModuleCatLifeMediator:getSickIdList()
    return checktable(self.sickIdList_)
end
function CatModuleCatLifeMediator:resetSickIdList()
    self.sickIdList_ = table.keys(self:getCatModel():getSickIdMap())
end


-- isAvatar
function CatModuleCatLifeMediator:isAvatar(catLiveType)
    return catLiveType == CAT_LIVE_TYPE.SLEEP or catLiveType == CAT_LIVE_TYPE.TOILET
end


-------------------------------------------------
-- public

function CatModuleCatLifeMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function CatModuleCatLifeMediator:updatePageView_()
    if not self:getViewNode():getActionByTag(RELOAD_GRIDVIEW) then
        self:getViewNode():runAction(cc.CallFunc:create(function()
            local catLiveType = self:getSelectedCatLiveType()
            local goodsData = self:getGoodDataByType(catLiveType, self:getSelectedFeedGoodType())
            self:getViewData().goodsGridView:resetCellCount(#goodsData)
            self:getViewData().emptyLayer:setVisible(#goodsData <= 0)
            self:setSelectedGoodData(goodsData[1])
        end)):setTag(RELOAD_GRIDVIEW)
    end
end


-- get type good data
function CatModuleCatLifeMediator:getGoodDataByType(goodType, feedGoodType)
    local data             = {}
    local needGoodType     = checkint(goodType)
    local needFeedGoodType = checkint(feedGoodType)

    -- get main type data
    data = self.allGoodData_[needGoodType] or {}

    -- get sub type data
    if needGoodType == CAT_LIVE_TYPE.FEED  then
        data = data[needFeedGoodType] or {}
    end
    return data
end


-- init good data
function CatModuleCatLifeMediator:initGoodDatas()
    for _, backpackData in ipairs(app.goodsMgr:GetBackpackList()) do
        local goodsId     = checkint(backpackData.goodsId)
        local goodType    = CommonUtils.GetGoodTypeById(goodsId)
        local goodQuality = GoodsUtils.GetGoodsQualityById(goodsId)

        local isNew       = checkint(backpackData.IsNew) == 1
        local goodNum     = checkint(backpackData.amount)
        if goodType == GoodsType.TYPE_CAT_GOODS and goodNum > 0 then
            local goodConf = CONF.CAT_HOUSE.CAT_GOODS_INFO:GetValue(goodsId)
            local catLiveType, feedGoodType = self:getCatLiveTypeByGoodSubType(goodConf.type)
            if catLiveType ~= CAT_LIVE_TYPE.OTHER then
                if not self.allGoodData_[catLiveType] then
                    self.allGoodData_[catLiveType] = {}
                end
                if feedGoodType then
                    if not self.allGoodData_[catLiveType][feedGoodType] then
                        self.allGoodData_[catLiveType][feedGoodType] = {}
                    end
                    table.insert(self.allGoodData_[catLiveType][feedGoodType], {goodsId = goodsId, num = goodNum, isNew = isNew, quality = goodQuality})
                else
                    table.insert(self.allGoodData_[catLiveType], {goodsId = goodsId, num = goodNum, isNew = isNew, quality = goodQuality})
                end
            end
        elseif goodType == GoodsType.TYPE_HOUSE_AVATAR then
            local goodConf = CONF.CAT_HOUSE.AVATAR_INFO:GetValue((goodsId))
            if checkint(goodConf.mainType) == CatHouseUtils.AVATAR_TYPE.CATTERY then
                local catLiveType = CAT_LIVE_TYPE.OTHER
                if checkint(goodConf.buffType) == CatHouseUtils.AVATAR_CATTERY_TYPE.CATTERY then
                    catLiveType = CAT_LIVE_TYPE.SLEEP
                elseif checkint(goodConf.buffType) == CatHouseUtils.AVATAR_CATTERY_TYPE.TOILET then
                    catLiveType = CAT_LIVE_TYPE.TOILET
                end

                if not self.allGoodData_[catLiveType] then
                    self.allGoodData_[catLiveType] = {}
                end
                table.insert(self.allGoodData_[catLiveType], {goodsId = goodsId, num = goodNum, isNew = isNew, quality = goodQuality})
            end
        end
    end


    -- sort data
    for catLiveType, goodDatas in pairs(self.allGoodData_ or {}) do
        local sortFunc = function(sortGoodDatas)
            table.sort(sortGoodDatas, function(goodDataA, goodDataB)
                if goodDataA.isNew ~= goodDataB.isNew then
                    return goodDataA.isNew == true
                elseif goodDataA.quality ~= goodDataB.quality then
                    return goodDataA.quality > goodDataB.quality
                else
                    return goodDataA.goodsId > goodDataB.goodsId
                end
            end)
        end
        if catLiveType ~= CAT_LIVE_TYPE.FEED then
            sortFunc(goodDatas)
        else
            for feedType, feedGoodDatas in pairs(goodDatas) do
                sortFunc(feedGoodDatas)
            end
        end
    end
end


-- get cat live type by good type
function CatModuleCatLifeMediator:getCatLiveTypeByGoodSubType(goodSubType)
    local subType = checkint(goodSubType)

    if subType == CatHouseUtils.CAT_GOODS_TYPE.CLEAN_ITEM then
        return CAT_LIVE_TYPE.BATH
    elseif subType == CatHouseUtils.CAT_GOODS_TYPE.DRUG then
        return CAT_LIVE_TYPE.FEED, FEED_GOOD_TYPE.DRUG
    elseif subType == CatHouseUtils.CAT_GOODS_TYPE.FOOD then
        return CAT_LIVE_TYPE.FEED, FEED_GOOD_TYPE.FOOD
    elseif subType == CatHouseUtils.CAT_GOODS_TYPE.TOY then
        return CAT_LIVE_TYPE.PLAY
    else
        return CAT_LIVE_TYPE.OTHER
    end
end


function CatModuleCatLifeMediator:updateGoodData(goodData)
    local catLiveType = CAT_LIVE_TYPE.OTHER
    local catFeedType = nil
    -- find type
    if goodData.goodsType == GoodsType.TYPE_CAT_GOODS then
        local goodsConf   = CONF.CAT_HOUSE.CAT_GOODS_INFO:GetValue(goodData.goodsId)
        catLiveType, catFeedType = self:getCatLiveTypeByGoodSubType(goodsConf.type)
    elseif goodData.goodsType == GoodsType.TYPE_HOUSE_AVATAR then
        local goodConf = CONF.CAT_HOUSE.AVATAR_INFO:GetValue(goodData.goodsId)
        if checkint(goodConf.mainType) == CatHouseUtils.AVATAR_TYPE.CATTERY then
            if checkint(goodConf.buffType) == CatHouseUtils.AVATAR_CATTERY_TYPE.CATTERY then
                catLiveType = CAT_LIVE_TYPE.SLEEP
            elseif checkint(goodConf.buffType) == CatHouseUtils.AVATAR_CATTERY_TYPE.TOILET then
                catLiveType = CAT_LIVE_TYPE.TOILET
            end
        end
    end

    -- find table data
    local goodLiveTypeData = {}
    if not self.allGoodData_[catLiveType] then
        self.allGoodData_[catLiveType] = {}
    end
    goodLiveTypeData = self.allGoodData_[catLiveType]
    if catFeedType then
        if not self.allGoodData_[catLiveType][catFeedType] then
            self.allGoodData_[catLiveType][catFeedType] = {}
        end
        goodLiveTypeData = self.allGoodData_[catLiveType][catFeedType]
    end
    

    -- deal data
    local hasFindGood = false
    for goodIndex, goodsData in ipairs(goodLiveTypeData) do
        if goodsData.goodsId == goodData.goodsId then
            if goodData.goodsAmount <= 0 then
                table.remove(goodLiveTypeData, goodIndex)
                hasFindGood = true
            else
                goodsData.num = goodData.goodsAmount
                hasFindGood = true
            end
            break
        end
    end
    if not hasFindGood and goodData.goodsAmount > 0 then
        table.insert(goodLiveTypeData, 1, {goodsId = goodData.goodsId, num = goodData.goodsAmount, isNew = true, quality = GoodsUtils.GetGoodsQualityById(goodData.goodsId)})
    end

    -- update view
    self:updatePageView_()
end


-------------------------------------------------
-- handler

function CatModuleCatLifeMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function CatModuleCatLifeMediator:onClickUseButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if not self:getCatModel():isAlive() then
        app.uiMgr:ShowInformationTips(__("猫咪已经死亡"))
    elseif not self:getCatModel():isDoNothing() then
        app.uiMgr:ShowInformationTips(__("猫咪正忙"))
    elseif self:getCatModel():isDisableAnything() and self:getSelectedCatLiveType() ~= CAT_LIVE_TYPE.FEED and self:getSelectedFeedGoodType() ~= FEED_GOOD_TYPE.DRUG then
        app.uiMgr:ShowInformationTips(__("猫咪处于负面状态，拒绝了你的行为"))
        AppFacade.GetInstance():DispatchObservers(SGL.CAT_MODULE_CAT_PLAY_REFUSE_ANIM)
    else
        local goodData = self:getSelectedGoodData()
        CAT_LIVE_FUNC[self:getSelectedCatLiveType()](self, self:getPlayerCatId(), goodData.goodsId)
    end

    -- if self:getSelectedGoodData().num > 0 then
    --     local CountChoosePopUp  = require( 'common.CountChoosePopUp' ).new({goodsId = self:getSelectedGoodId(), callback = callback})
    --     CountChoosePopUp:setPosition(display.center)
    --     app.uiMgr:GetCurrentScene():AddDialog(CountChoosePopUp)
    -- else
    --     callback(1)
    -- end
end


function CatModuleCatLifeMediator:onClickGoodTypeButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    sender:setChecked(true)
    self:setSelectedCatLiveType(sender:getTag())
end


function CatModuleCatLifeMediator:onClickFeedGoodTypeButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    sender:setChecked(true)
    self:setSelectedFeedGoodType(sender:getTag())
end



function CatModuleCatLifeMediator:onClickShopButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local shopMdt = nil
    if self:isAvatar(self:getSelectedCatLiveType()) then
        shopMdt = require("Game.mediator.catHouse.CatHouseAvatarShopMediator").new()
    else
        shopMdt = require("Game.mediator.catModule.CatModuleShopMediator").new()
    end
    app:RegistMediator(shopMdt)
end


function CatModuleCatLifeMediator:onClickGoodBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local cellIndex = checkint(sender:getTag())
    local goodData  = self:getGoodDataByType(self:getSelectedCatLiveType(), self:getSelectedFeedGoodType())[cellIndex]
    self:setSelectedGoodData(goodData)
end


return CatModuleCatLifeMediator
