--[[
 * author : panmeng
 * descpt : 猫屋装饰中介
]]
local CatHouseDecorateMediator = class('CatHouseDecorateMediator', mvc.Mediator)

function CatHouseDecorateMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatHouseDecorateMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance

function CatHouseDecorateMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true
    
    -- add listener
    ui.bindClick(self:getViewData().downBtn, handler(self, self.onClickDownButtonHandler_))
    ui.bindClick(self:getViewData().shopButton, handler(self, self.onClickShopButtonHandler_))
    ui.bindClick(self:getViewData().cleanAllBtn, handler(self, self.onClickCleanAllButtonHandler_))
    ui.bindClick(self:getViewData().presetBtn, handler(self, self.onClickPresetBtnHandler_))
    for _, viewData in pairs(self:getViewData().typeBtnViewDataGroup) do
        viewData.titleBtn:setOnClickScriptHandler(handler(self, self.onClickTypeButtonHandler_))
    end
    self:getViewData().avatarTableView:setCellUpdateHandler(handler(self, self.updateCellHandler_))
    self:getViewData().avatarTableView:setCellInitHandler(function(cellViewData)
        cellViewData.frameBtn:setOnClickScriptHandler(handler(self, self.onClickAvatarCellHandler_))
    end)
    self:getViewData().menuTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.confirmBtn, handler(self, self.onClickMenuCellConfirmBtnHandler_), false)
        ui.bindClick(cellViewData.applyBtn, handler(self, self.onClickMenuCellApplyBtnHandler_), false)
        cellViewData.toggleBtn:setOnClickScriptHandler(handler(self, self.onClickMenuToggleBtnHandler_))  
    end)
    self:getViewData().menuTableView:setCellUpdateHandler(handler(self, self.onMenuTabUpdateHandler_))
    
    -- init data
    self:initAvatarLibraryData_()
end


function CatHouseDecorateMediator:CleanupView()
end


function CatHouseDecorateMediator:OnRegist()
    regPost(POST.HOUSE_SUIT_SAVE)
    regPost(POST.HOUSE_SUIT_APPLY)
end


function CatHouseDecorateMediator:OnUnRegist()
    unregPost(POST.HOUSE_SUIT_APPLY)
    unregPost(POST.HOUSE_SUIT_SAVE)
end


function CatHouseDecorateMediator:InterestSignals()
    return {
        POST.HOUSE_SUIT_SAVE.sglName,
        POST.HOUSE_SUIT_APPLY.sglName,
        SGL.BACKPACK_GOODS_REFRESH,
        SGL.CAT_HOUSE_SET_SELECTED_AVATARID,
        SGL.CAT_HOUSE_UPDATE_AVATAR_USE_NUM,
    }
end
function CatHouseDecorateMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == SGL.BACKPACK_GOODS_REFRESH then
        if GoodsType.TYPE_HOUSE_AVATAR == data.goodsType then
            self:onUpdateAvatarTotalNumHandler_(data)
        end

    elseif name == SGL.CAT_HOUSE_SET_SELECTED_AVATARID then
        self:setSelectedAvatarId(checkint(data.avatarId))

    elseif name == SGL.CAT_HOUSE_UPDATE_AVATAR_USE_NUM then
        self:onUpdateAvatarUsedNumHandler_(data)

    elseif name == POST.HOUSE_SUIT_APPLY.sglName then
        local suitId   = tostring(data.requestData.suitId)
        local suitData = clone(app.catHouseMgr:getHomeData().customSuits[suitId])
        app.catHouseMgr:getHomeData().location = suitData
        app.catHouseMgr:setHousePresetSuitId(0)
        self:setDisplayTypeId_(self:getDisplayTypeId_())
    elseif name == POST.HOUSE_SUIT_SAVE.sglName then
        local suitId   = tostring(data.requestData.suitId)
        local suitData = clone(app.catHouseMgr:getHomeData().location)
        app.catHouseMgr:getHomeData().customSuits[suitId] = suitData
        app.uiMgr:ShowInformationTips(__("保存成功"))
        self:reloadAvatarsSuit()

        if checkint(suitId) == app.catHouseMgr:getHousePresetSuitId() then
            app.catHouseMgr:setHousePresetSuitId(checkint(suitId))
        end
    end
end


-------------------------------------------------
-- get / set

function CatHouseDecorateMediator:getViewNode()
    return self:GetViewComponent()
end
function CatHouseDecorateMediator:getViewData()
    return self:GetViewComponent():getViewData()
end


function CatHouseDecorateMediator:getDisplayTypeId_()
    return checkint(self.displayTypeId_)
end
function CatHouseDecorateMediator:setDisplayTypeId_(typeId)
    self.displayTypeId_        = checkint(typeId)
    self.displayAvatarListData = checktable(self.avatarDataList_[self.displayTypeId_])

    self:freshAvatarUsedNum()
    self:getViewData().avatarTableView:resetCellCount(#self.displayAvatarListData)
    self:updateTypeBar()
end


function CatHouseDecorateMediator:getSelectedAvatarId()
    return checkint(self.selectedAvatarId_)
end
function CatHouseDecorateMediator:setSelectedAvatarId(selectedAvatarId)
    local oldSelectedAvatarId = self:getSelectedAvatarId()
    self.selectedAvatarId_ = checkint(selectedAvatarId)

    if oldSelectedAvatarId == self.selectedAvatarId_ then
        return
    end

    for _, cellViewData in pairs(self:getViewData().avatarTableView:getCellViewDataDict()) do
        local cellIndex = cellViewData.view:getTag()
        local avatarId  = checkint(self.displayAvatarListData[cellIndex])
        if oldSelectedAvatarId ~= 0 and oldSelectedAvatarId == avatarId then
            self:getViewNode():updateAvatarCellStatus_(cellIndex, cellViewData, self:getSelectedAvatarData(oldSelectedAvatarId))
        elseif self.selectedAvatarId_ ~= 0 and self.selectedAvatarId_ == avatarId then
            self:getViewNode():updateAvatarCellStatus_(cellIndex, cellViewData, self:getSelectedAvatarData())
        end
    end
end


function CatHouseDecorateMediator:getAvatarDisplayType_(goodsId)
    local displayTypeMap = {}
    local avatarConf = CONF.CAT_HOUSE.AVATAR_INFO:GetValue(goodsId)

    for _, displayType in pairs(avatarConf.category or {}) do
        displayTypeMap[checkint(displayType)] = true
    end
    return displayTypeMap
end


function CatHouseDecorateMediator:isFlodAvatar()
    return self.isFlodAvatar_ == true
end
function CatHouseDecorateMediator:setFlodAvatar(isFlod)
    self.isFlodAvatar_ = isFlod == true
    if self.isFlodAvatar_ then
        self:getViewNode():toFoldAvatar_()
    else
        self:getViewNode():toUnfoldAvatar_()
    end
end


function CatHouseDecorateMediator:hasDamagedAvatar()
    local hasDamaged = false
    local allAvatars = checktable(app.catHouseMgr:getHomeData().location)
    for _, avatarData in pairs(allAvatars) do
        if checkint(avatarData.damaged) > 0 then
            hasDamaged = true
            break
        end
    end
    return hasDamaged
end


-------------------------------------------------
-- public

function CatHouseDecorateMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


function CatHouseDecorateMediator:freshAvatarUsedNum()
    local usedAvatars = checktable(app.catHouseMgr:getHomeData().location)
    local usedNumMap = {}

    for _, locationData in pairs(usedAvatars) do
        local avatarId = checkint(locationData.goodsId)
        usedNumMap[checkint(avatarId)] = checkint(usedNumMap[checkint(avatarId)]) + 1
    end

    for avatarId, avatarData in pairs(self.avatarDataMap_) do
        avatarData.usedNum = checkint(usedNumMap[checkint(avatarId)])
    end
end


function CatHouseDecorateMediator:updateShopButtonTip(showRemind)
    local shopButton = self.viewData_.shopButton
    local redPointIcon = shopButton:getChildByName('redPointIcon')

    if redPointIcon then
        local gameMgr = self:GetFacade():GetManager('GameManager')
        redPointIcon:setVisible(showRemind)
    end
end


-------------------------------------------------
-- private

function CatHouseDecorateMediator:initAvatarLibraryData_()
    self.typeHeartDict_  = {}
    self.avatarDataList_ = {}
    self.avatarDataMap_  = {}

    for _, backpackData in ipairs(app.goodsMgr:GetBackpackList()) do
        local totalNum   = checkint(backpackData.amount)
        local goodsId    = checkint(backpackData.goodsId)
        local goodsIsNew = checkint(backpackData.IsNew) == 1
        local goodsType  = CommonUtils.GetGoodTypeById(goodsId)
        if goodsType == GoodsType.TYPE_HOUSE_AVATAR and totalNum > 0 then
            local avatarConf = CONF.CAT_HOUSE.AVATAR_INFO:GetValue(goodsId)
            local avatarData = {avatarId = goodsId, totalNum = totalNum, usedNum = 0}
            self.avatarDataMap_[checkint(goodsId)] = avatarData

            -- insert to all index
            if not self.avatarDataList_[CatHouseUtils.AVATAR_TAB_TYPE.ALL] then
                self.avatarDataList_[CatHouseUtils.AVATAR_TAB_TYPE.ALL] = {}
            end
            table.insert(self.avatarDataList_[CatHouseUtils.AVATAR_TAB_TYPE.ALL], goodsId)

            -- insert to every displayType index
            local avatarDisplayTypeMap = self:getAvatarDisplayType_(goodsId)
            for avatarDislayType, _ in pairs(avatarDisplayTypeMap) do
                avatarDisplayTypeMap = checkint(avatarDislayType)
                if not self.avatarDataList_[avatarDislayType] then
                    self.avatarDataList_[avatarDislayType] = {}
                end
                table.insert(self.avatarDataList_[avatarDislayType], goodsId)

                if goodsIsNew then
                    self.typeHeartDict_[avatarDisplayTypeMap] = self.typeHeartDict_[avatarDisplayTypeMap] or {}
                    self.typeHeartDict_[avatarDisplayTypeMap][goodsId] = true
                end
            end
        end
    end
end


function CatHouseDecorateMediator:updateTypeBar()
    for typeId, typeViewData in pairs(self:getViewData().typeBtnViewDataGroup) do
        typeViewData.titleBtn:setChecked(self:getDisplayTypeId_() == typeId)

        if typeId == CatHouseUtils.AVATAR_TAB_TYPE.ALL then
            local hasHeart = false
            for k, typeHeartMap in pairs(self.typeHeartDict_) do
                hasHeart = table.nums(typeHeartMap) > 0
                if hasHeart then
                    break
                end
            end
            typeViewData.heartIcon:setVisible(hasHeart)
        else
            local typeHeartMap = self.typeHeartDict_[typeId] or {}
            typeViewData.heartIcon:setVisible(table.nums(typeHeartMap) > 0)
        end
    end
end


function CatHouseDecorateMediator:reloadAvatarsSuit()
    self:getViewData().menuTableView:resetCellCount(CatHouseUtils.HOUSE_PARAM_FUNCS.AVATAR_SUIT_MAX())
end


-------------------------------------------------
-- handler

function CatHouseDecorateMediator:onClickCleanAllButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then
        return
    end

    -- local cleanList = {}
    -- for _, avatarInfo in pairs(app.catHouseMgr:getHomeData().location) do
    --     local avatarId   = checkint(avatarInfo.goodsId)
    --     local avatarConf = CONF.CAT_HOUSE.AVATAR_INFO:GetValue(avatarId)
    --     local avatarType = CatHouseUtils.GetAvatarTypeByGoodsId(avatarId)
    --     if avatarType ~= CatHouseUtils.AVATAR_TYPE.WALL and avatarType ~= CatHouseUtils.AVATAR_TYPE.FLOOR then
    --         table.insert(cleanList, {goodsUuid = avatarInfo.goodsUuid, goodsId = avatarInfo.goodsId})
    --     end
    -- end
    app.uiMgr:AddCommonTipDialog({
        descr    = __("是否清除全部家具？"),
        callback = function()
            app.socketMgr:SendPacket(NetCmd.HOUSE_AVATAR_CLEAR)
        end
    })
end


function CatHouseDecorateMediator:onClickTypeButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then
        return
    end

    local typeId = checkint(sender:getParent():getTag())
    if self:getDisplayTypeId_() == typeId then
        sender:setChecked(true)
        return
    end
    self:setDisplayTypeId_(typeId)

    if self:isFlodAvatar() then
        self:setFlodAvatar(false)
    else
        self.isControllable_ = false
        transition.execute(self:getViewNode(), nil, {
            delay    = 0.3,
            complete = function()
                self.isControllable_ = true
            end
        })
    end
end


function CatHouseDecorateMediator:onClickDownButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then
        return
    end

    self:setFlodAvatar(not self:isFlodAvatar())
end


function CatHouseDecorateMediator:onClickShopButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then
        return
    end

    local avatarShopMdt = require('Game.mediator.catHouse.CatHouseAvatarShopMediator').new()
    app:RegistMediator(avatarShopMdt)
end


function CatHouseDecorateMediator:onClickAvatarCellHandler_(sender)
    PlayAudioByClickNormal()
    sender:setChecked(false)
    if not self.isControllable_ then
        return
    end

    local cellIndex = checkint(sender:getParent():getTag())
    local avatarId  = checkint(self.displayAvatarListData[cellIndex])

    local avatarData = self.avatarDataMap_[avatarId]
    local avatarDisplayTypeMap = self:getAvatarDisplayType_(avatarId)
    local avatarType = CatHouseUtils.GetAvatarTypeByGoodsId(avatarId)
    local hasFree = checkint(avatarData.totalNum) > checkint(avatarData.usedNum)
    local usedAvatars = checktable(app.catHouseMgr:getHomeData().location)

    -------------------------------------------------
    -- the onlyone count
    if avatarType == CatHouseUtils.AVATAR_TYPE.WALL or avatarType == CatHouseUtils.AVATAR_TYPE.FLOOR or avatarType == CatHouseUtils.AVATAR_TYPE.CELLING then
        local usedAvatarData = nil
        for _, locationData in pairs(usedAvatars) do
            if CatHouseUtils.GetAvatarTypeByGoodsId(locationData.goodsId) == avatarType then
                usedAvatarData = locationData
                break
            end
        end
        
        if usedAvatarData and avatarId == checkint(usedAvatarData.goodsId) then
            if avatarType == CatHouseUtils.AVATAR_TYPE.CELLING then
                self:GetFacade():DispatchObservers(SGL.CAT_HOUSE_CHANGE_AVATAR_STATUE, {cmdTag = CatHouseUtils.HOUSE_CMD_TAG.TO_REMOVE, goodsId = avatarId, goodsUuid = usedAvatarData.goodsUuid})
            else
                app.uiMgr:ShowInformationTips(__('当前正在使用中'))
            end
        else
            if not usedAvatarData and not self:checkIsCanAppendAvatar() then
                app.uiMgr:ShowInformationTips(__('已达到家具摆放上限'))
                self:setSelectedAvatarId()
            else
                self:GetFacade():DispatchObservers(SGL.CAT_HOUSE_CHANGE_AVATAR_STATUE, {cmdTag = CatHouseUtils.HOUSE_CMD_TAG.TO_APPEND, goodsId = avatarId})
            end
        end
        self:setSelectedAvatarId()

    else
        if checkint(self.selectedAvatarId_) == avatarId then
            sender:setChecked(true)
            return
        end
        if hasFree then
            if not self:checkIsCanAppendAvatar() then
                app.uiMgr:ShowInformationTips(__('已达到家具摆放上限'))
                self:setSelectedAvatarId()
            else
                self:GetFacade():DispatchObservers(SGL.CAT_HOUSE_CHANGE_AVATAR_STATUE, {cmdTag = CatHouseUtils.HOUSE_CMD_TAG.TO_CANCLE})
                self:GetFacade():DispatchObservers(SGL.CAT_HOUSE_CHANGE_AVATAR_STATUE, {cmdTag = CatHouseUtils.HOUSE_CMD_TAG.TO_APPEND, goodsId = avatarId})
                self:setSelectedAvatarId(avatarId)
            end
        else
            app.uiMgr:ShowInformationTips(__('当前家具已经用完'))
            self:setSelectedAvatarId()
        end
    end

    -- update heart cache
    for avatarType, _ in pairs(avatarDisplayTypeMap) do
        if checktable(self.typeHeartDict_[checkint(avatarType)])[checkint(avatarId)] then
            self.typeHeartDict_[checkint(avatarType)][checkint(avatarId)] = nil
        end
    end
    sender:getParent().heartIcon:setVisible(false)
    app.gameMgr:UpdateBackpackNewStatuByGoodId(avatarId)
    self:updateTypeBar()

    -- block control
    self.isControllable_ = false
    transition.execute(self:getViewNode(), nil, {
        delay    = 0.3,
        complete = function()
            self.isControllable_ = true
        end
    })
end


function CatHouseDecorateMediator:onClickPresetBtnHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then
        return
    end
    self:getViewData().presetFrameView:setVisible(true)
    self:GetFacade():DispatchObservers(SGL.CAT_HOUSE_CHANGE_AVATAR_STATUE, {cmdTag = CatHouseUtils.HOUSE_CMD_TAG.TO_CANCLE})
end


function CatHouseDecorateMediator:updateCellHandler_(cellIndex, cellViewData)
    self:getViewNode():updateCellHandler_(cellIndex, cellViewData, self:getAvatarDataByCellIndex(cellIndex))
end


function CatHouseDecorateMediator:getAvatarDataByCellIndex(cellIndex)
    local avatarId = self.displayAvatarListData[cellIndex]
    return self:getSelectedAvatarData(avatarId)
end


function CatHouseDecorateMediator:getSelectedAvatarData(avatarId)
    avatarId = avatarId or self.selectedAvatarId_
    local avatarData = clone(self.avatarDataMap_[avatarId])
    local avatarDisplayTypeMap = self:getAvatarDisplayType_(avatarId)

    local isHasRed = false
    for displayType, _ in pairs(avatarDisplayTypeMap) do
        if self.typeHeartDict_[checkint(displayType)] and self.typeHeartDict_[checkint(displayType)][avatarId] then
            isHasRed = true
        end
    end
    avatarData.isHasRed   = isHasRed
    avatarData.isSelected = checkint(self.selectedAvatarId_) == checkint(avatarId)
    return avatarData
end


function CatHouseDecorateMediator:isPresetViewVisible()
    return self:getViewData().presetFrameView:isVisible()
end


function CatHouseDecorateMediator:updatePresetViewVisible(visible)
    self:getViewData().presetFrameView:setVisible(visible)
    for _, cellViewData in pairs(self:getViewData().menuTableView:getCellViewDataDict()) do
        cellViewData.toggleBtn:setChecked(false)
    end
end

function CatHouseDecorateMediator:checkIsCanAppendAvatar()
    local isCanAppend             = true
    local houseLevelConf          = CONF.CAT_HOUSE.LEVEL_INFO:GetValue(app.catHouseMgr:getHouseLevel())
    local houseAvatarNumLimit     = checkint(houseLevelConf.avatarLimit)
    local houseAvatarUsedTotalNum = 0
    for _, houseAvatarData in pairs(app.catHouseMgr:getHomeData().location or {}) do
        houseAvatarUsedTotalNum = houseAvatarUsedTotalNum + 1
    end

    if houseAvatarUsedTotalNum >= houseAvatarNumLimit then
        isCanAppend = false
    end

    return isCanAppend
end

function CatHouseDecorateMediator:onUpdateAvatarTotalNumHandler_(data)
    --local data = signal:GetBody()
    local goodsId = checkint(data.goodsId)
    local goodsAmount = checkint(data.goodsAmount)

    if self.avatarDataMap_[goodsId] then
        self.avatarDataMap_[goodsId].totalNum = goodsAmount
    else
        self.avatarDataMap_[goodsId] = {avatarId = goodsId, totalNum = goodsAmount, usedNum = 0}

        -- insert to all index
        if not self.avatarDataList_[CatHouseUtils.AVATAR_TAB_TYPE.ALL] then
            self.avatarDataList_[CatHouseUtils.AVATAR_TAB_TYPE.ALL] = {}
        end
        table.insert(self.avatarDataList_[CatHouseUtils.AVATAR_TAB_TYPE.ALL], goodsId)

        -- insert to every displayType index
        local avatarDisplayTypeMap = self:getAvatarDisplayType_(goodsId)
        for avatarDislayType, _ in pairs(avatarDisplayTypeMap) do
            avatarDisplayTypeMap = checkint(avatarDislayType)
            if not self.avatarDataList_[avatarDislayType] then
                self.avatarDataList_[avatarDislayType] = {}
            end
            table.insert(self.avatarDataList_[avatarDislayType], goodsId)

            self.typeHeartDict_[avatarDisplayTypeMap] = self.typeHeartDict_[avatarDisplayTypeMap] or {}
            self.typeHeartDict_[avatarDisplayTypeMap][goodsId] = true
        end
    end
    self.displayAvatarListData = checktable(self.avatarDataList_[self:getDisplayTypeId_()])
    self:getViewData().avatarTableView:resetCellCount(#self.displayAvatarListData)
    self:updateTypeBar()
end


function CatHouseDecorateMediator:onUpdateAvatarUsedNumHandler_(data)
    local avatarIdList = data.goodsIdList
    local avatarIdMap  = {}
    for _, goodsId in pairs(avatarIdList) do
        avatarIdMap[checkint(goodsId)] = true
    end

    self:freshAvatarUsedNum()
    for _, cellViewData in pairs(self:getViewData().avatarTableView:getCellViewDataDict()) do
        local cellIndex = cellViewData.view:getTag()
        local avatarId  = checkint(self.displayAvatarListData[cellIndex])
        if avatarId ~= 0 and avatarIdMap[avatarId] then
            self:getViewNode():updateAvatarCellStatus_(cellIndex, cellViewData, self:getSelectedAvatarData(avatarId))
        end
    end
end


function CatHouseDecorateMediator:onClickMenuCellConfirmBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if table.nums(app.catHouseMgr:getHomeData().location) <= 0 then
        app.uiMgr:ShowInformationTips(__("当前设置为空！"))
        return
    end

    if self:hasDamagedAvatar() then
        app.uiMgr:ShowInformationTips(__('请先修复已破损的家具'))
        return
    end

    local cellIndex = checkint(sender:getParent():getParent():getTag())
    local strTip = __("是否保存当前设置到预设_num_")
    if next(checktable(app.catHouseMgr:getHomeData().customSuits[tostring(cellIndex)])) ~= nil then
        strTip = __("是否替换当前设置到预设_num_")
    end

    local commonTip = require('common.NewCommonTip').new({text = string.fmt(strTip, { _num_ = tostring(cellIndex)}), callback = function ()
        self:SendSignal(POST.HOUSE_SUIT_SAVE.cmdName, {suitId = cellIndex})
    end})
    commonTip:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(commonTip)
end


function CatHouseDecorateMediator:onClickMenuCellApplyBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if self:hasDamagedAvatar() then
        app.uiMgr:ShowInformationTips(__('请先修复已破损的家具'))
        return
    end

    local cellIndex = checkint(sender:getParent():getParent():getTag())
    local commonTip = require('common.NewCommonTip').new({text = string.fmt(__("是否启用预设_num_"), { _num_ = cellIndex}), callback = function ()
        self:SendSignal(POST.HOUSE_SUIT_APPLY.cmdName, {suitId = cellIndex})
    end})
    commonTip:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(commonTip)
end


function CatHouseDecorateMediator:onMenuTabUpdateHandler_(cellIndex, cellViewData)
    local cellInfo = checktable(app.catHouseMgr:getHomeData().customSuits[tostring(cellIndex)])
    self:getViewNode():updateMenuCellStatus(cellViewData, next(cellInfo) == nil)
    cellViewData.view:setTag(cellIndex)
end


function CatHouseDecorateMediator:onClickMenuToggleBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local cellIndex = checkint(sender:getParent():getTag())
    if next(checktable(app.catHouseMgr:getHomeData().customSuits[tostring(cellIndex)])) == nil then
        sender:setChecked(false)
        return
    end

    if app.catHouseMgr:getHousePresetSuitId() == cellIndex then
        sender:setChecked(false)
        app.catHouseMgr:setHousePresetSuitId(0)
    else
        for _, cellViewData in pairs(self:getViewData().menuTableView:getCellViewDataDict()) do
            cellViewData.toggleBtn:setChecked(cellIndex == checkint(cellViewData.view:getTag()))
        end
        app.catHouseMgr:setHousePresetSuitId(cellIndex)
    end
end


return CatHouseDecorateMediator
