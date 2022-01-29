--[[
 * author : kaishiqi
 * descpt : 新抽卡中介者
]]
local CapsuleNewView     = require('Game.views.drawCards.CapsuleNewView')
local PoolPreviewView    = require('Game.views.drawCards.CapsulePoolPreviewView')
local CapsuleNewMediator = class('CapsuleNewMediator', mvc.Mediator)

local DRAW_TYPE_DEFINE = {
    [ACTIVITY_TYPE.DRAW_BASIC_GET]      = {mdtName = 'CapsuleBasicGetMediator'},                                                     -- 基础抽卡
    [ACTIVITY_TYPE.DRAW_NEWBIE_GET]     = {mdtName = 'CapsuleNewPlayerMediator',       homePost = POST.GAMBLING_NEWBIE_ENTER},       -- 新手抽卡
    [ACTIVITY_TYPE.DRAW_TEN_TIMES]      = {mdtName = 'CapsuleTenTimesMediator',        homePost = POST.GAMBLING_TEN_ENTER},          -- 十连抽卡
    [ACTIVITY_TYPE.DRAW_SUPER_GET]      = {mdtName = 'CapsuleSuperGetMediator',        homePost = POST.GAMBLING_SUPER_ENTER},        -- 超得抽卡
    [ACTIVITY_TYPE.DRAW_NINE_GRID]      = {mdtName = 'CapsuleNinePalaceMediator',      homePost = POST.GAMBLING_SQUARE_ENTER},       -- 九宫抽卡
    [ACTIVITY_TYPE.DRAW_EXTRA_DROP]     = {mdtName = 'CapsuleExtraDropMediator',       homePost = POST.GAMBLING_EXTRA_DROP_ENTER},   -- 十连送道具抽卡
    [ACTIVITY_TYPE.DRAW_LIMIT]          = {mdtName = 'CapsuleLimitMediator',           homePost = POST.GAMBLING_LIMIT_ENTER},        -- 限购抽卡
    [ACTIVITY_TYPE.DRAW_SKIN_POOL]      = {mdtName = 'CapsuleSkinMediator',            homePost = POST.GAMBLING_SKIN_ENTER},         -- 皮肤卡池入口
    [ACTIVITY_TYPE.DRAW_CARD_CHOOSE]    = {mdtName = 'CapsuleCardChooseMediator',      homePost = POST.GAMBLING_CARD_CHOOSE},        -- 选卡卡池入口
    [ACTIVITY_TYPE.STEP_SUMMON]         = {mdtName = 'CapsuleStepMediator',            homePost = POST.GAMBLING_SETP},               -- 进阶卡池
    [ACTIVITY_TYPE.DRAW_LUCKY_BAG]      = {mdtName = 'CapsuleLuckyBagMediator',        homePost = POST.GAMBLING_LUCKY_BAG_HOME},     -- 福袋抽卡
    [ACTIVITY_TYPE.DRAW_RANDOM_POOL]    = {mdtName = 'CapsuleRandomPoolMediator',      homePost = POST.GAMBLING_RANDOM_POOL_ENTER},  -- 铸池抽卡
    [ACTIVITY_TYPE.UP_PROBABILITY_UP]   = {mdtName = 'CapsuleURProbabilityUPMediator', homePost = POST.GAMBLING_PROBABILITY_UP},     -- UR概率UP
    [ACTIVITY_TYPE.BINARY_CHOICE]       = {mdtName = 'CapsuleBinaryChoiceMediator',    homePost = POST.GAMBLING_BINARY_CHOICE_HOME}, -- 双抉卡池
    [ACTIVITY_TYPE.BASIC_SKIN_CAPSULE]  = {mdtName = 'CapsuleBasicSkinMediator'},                                                    -- 常驻皮肤卡池
    [ACTIVITY_TYPE.FREE_NEWBIE_CAPSULE] = {mdtName = 'CapsuleFreeNewbieMediator',      homePost = POST.GAMBLING_FREE_NEWBIE_HOME},   -- 免费新手卡池
}
CapsuleNewMediator.DRAW_TYPE_DEFINE = DRAW_TYPE_DEFINE

local CURRENT_DRAW_OVER_TIP_NAME = 'CURREN T_DRAW_OVER_TIP_NAME'

function CapsuleNewMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CapsuleNewMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
    -- 刷新钻石数量
    CommonUtils.RefreshDiamond(self.ctorArgs_)
    -- 重置铸池抽卡状态
    app.capsuleMgr:SetRandomPoolState(true)
end


-------------------------------------------------
-- inheritance method

function CapsuleNewMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true
    self.typeCellDict_   = {}
    self.typeDataList_   = {}
    self.homeDataDict_   = {}
    self.homeSglNameMap_ = {}
    self.contentMdtName_ = nil
    for _, defineData in pairs(DRAW_TYPE_DEFINE) do
        if defineData.homePost then
            self.homeSglNameMap_[defineData.homePost.sglName] = defineData.homePost.sglName
        end
    end

    -- pre set closeTimestamp
    for _, typeList in pairs(self.ctorArgs_) do
        for _, typeData in ipairs(typeList) do
            if typeData.leftSeconds then
                typeData.closeTimestamp_ = os.time() + checkint(typeData.leftSeconds) + 2
            end
        end
    end

    -- create view
	self.capsuleView_ = CapsuleNewView.new()
    self.ownerScene_  = app.uiMgr:GetCurrentScene()
    self.ownerScene_:AddGameLayer(self.capsuleView_)

    -- add listener
    self:getCapsuleViewData().typeListView:setDataSourceAdapterScriptHandler(handler(self, self.onTypeListViewDataHandler_))
    self:getDrawCellViewData().previewBtn:setOnClickScriptHandler(handler(self, self.onClickDrawCellPreviewButtonHandler_))
    self:getDrawCellViewData().ruleInfoBtn:setOnClickScriptHandler(handler(self, self.onClickDrawCellRuleInfoButtonHandler_))

    -- update view
    -- self:reloadTypeList()

    self.isControllable_ = false
    self:getCapsuleView():showUI(function()
        self.isControllable_ = true
    end)
end


function CapsuleNewMediator:CleanupView()
    if self.ownerScene_ then
        if self.capsuleView_ and self.capsuleView_:getParent() then
            self.ownerScene_:RemoveGameLayer(self.capsuleView_)
            self.capsuleView_ = nil
        end
        self.ownerScene_ = nil
    end
end


function CapsuleNewMediator:OnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightHide')

    for _, defineData in pairs(DRAW_TYPE_DEFINE) do
        if defineData.homePost then
            regPost(defineData.homePost)
        end
    end
    self:enterLayer()
end


function CapsuleNewMediator:OnUnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'hide')
    
    for _, defineData in pairs(DRAW_TYPE_DEFINE) do
        if defineData.homePost then
            unregPost(defineData.homePost or {})
        end
    end

    self:GetFacade():UnRegsitMediator(self.contentMdtName_)
    self:stopTypeCountdownUpdate_()
end


function CapsuleNewMediator:InterestSignals()
    local signalList = {
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
        'SHARE_BUTTON_BACK_EVENT',
    }
    for _, sglName in pairs(self.homeSglNameMap_) do
        table.insert(signalList, sglName)
    end
    return signalList
end
function CapsuleNewMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -- check is home signal
    if self.homeSglNameMap_[name] then
        self:resetHomeDataAt_(self:getSelectedIndex(), data)
    else

        -- update money bar
        if name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
            self:getCapsuleView():updateMoneyBar()

        -- common drawRewards
        elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
            self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
        elseif name == 'SHARE_BUTTON_BACK_EVENT' then
            -- 关闭分享界面
            app.uiMgr:GetCurrentScene():RemoveDialogByTag(5361)
        end
    end
end


-------------------------------------------------
-- get / set

function CapsuleNewMediator:getCapsuleView()
    return self.capsuleView_
end
function CapsuleNewMediator:getCapsuleViewData()
    return self:getCapsuleView() and self:getCapsuleView():getViewData() or {}
end
function CapsuleNewMediator:getDrawCellViewData()
    return self:getCapsuleView() and self:getCapsuleView():getDrawCellViewData() or {}
end


function CapsuleNewMediator:getTypeDataList()
    return self.typeDataList_ or {}
end


function CapsuleNewMediator:getHomeDataDict()
    return self.homeDataDict_ or {}
end


function CapsuleNewMediator:getSelectedIndex()
    return self.selectedIndex_ or 0
end
function CapsuleNewMediator:setSelectedIndex(index)
    self.selectedIndex_ = checkint(index)
    self:updateTypeIndex_()
end
function CapsuleNewMediator:getTypeIndexByActivityId( activityId )
    if not activityId then return end
    local index = nil
    for i, v in ipairs(self:getTypeDataList()) do
        if checkint(v.data.activityId) == checkint(activityId) then
            index = i
            break
        end
    end
    return index
end


function CapsuleNewMediator:getTypeIndexByType(type)
    if not type then return end
    local index = nil
    local dataKey = self:generateTypeDataKey_(type)
    for i, v in ipairs(self:getTypeDataList()) do
        if v.type == dataKey then
            index = i
            break
        end
    end
    return index
end


-------------------------------------------------
-- public method

function CapsuleNewMediator:reloadTypeList()
    -- local beforeSelectedTypeIndex = self:getSelectedIndex()
    -- local beforeSelectedTypeData  = self:getTypeDataList()[beforeSelectedTypeIndex]

    -- reset all typeData
    self.typeDataList_ = {}

    -------------------------------------------------
    -- activity data
    for _, activityData in ipairs(self.ctorArgs_.activity or {}) do
        if self:calculateTypeLeftSeconds_(activityData) > 0 then
            local dataType = tostring(activityData.type)
            local dataKey  = self:generateTypeDataKey_(dataType, activityData)
            table.insert(self.typeDataList_, {type = dataType, data = activityData, key = dataKey})
        end
    end
    -------------------------------------------------
    -- free newbie
    if next(self.ctorArgs_.freeNewbie or {}) ~= nil and GAME_MODULE_OPEN.FREE_NEWBIE_CAPSULE then
        local dataType = tostring(ACTIVITY_TYPE.FREE_NEWBIE_CAPSULE)
        local dataKey  = self:generateTypeDataKey_(dataType)
        table.insert(self.typeDataList_, {type = dataType, data = {}, key = dataKey})
    end
    -------------------------------------------------
    -- base data
    if self.ctorArgs_.base then
        local dataType = tostring(ACTIVITY_TYPE.DRAW_BASIC_GET)
        local dataKey  = self:generateTypeDataKey_(dataType)
        table.insert(self.typeDataList_, {type = dataType, data = {}, key = dataKey})
    end
    -------------------------------------------------
    -- newbie data
    for _, newbieData in ipairs(self.ctorArgs_.newbie or {}) do
        local dataType = tostring(ACTIVITY_TYPE.DRAW_NEWBIE_GET)
        local dataKey  = self:generateTypeDataKey_(dataType, newbieData)
        table.insert(self.typeDataList_, {type = dataType, data = newbieData, key = dataKey})
    end
    -------------------------------------------------
    -- basicSkin data
    if self.ctorArgs_.cardSkin and GAME_MODULE_OPEN.BASIC_SKIN_CAPSULE then
        local dataType = tostring(ACTIVITY_TYPE.BASIC_SKIN_CAPSULE)
        local dataKey  = self:generateTypeDataKey_(dataType)
        table.insert(self.typeDataList_, {type = dataType, data = {}, key = dataKey})
    end
    -------------------------------------------------
    -- reload typeListView
    local typeListView = self:getCapsuleViewData().typeListView
    typeListView:setCountOfCell(#self:getTypeDataList())
    typeListView:reloadData()

    -- -- check fixed selected
    -- local afterSelectedTypeIndex = 1  -- default selected basic draw
    -- if beforeSelectedTypeData then
    --     for typeIndex, listData in ipairs(self:getTypeDataList()) do
    --         if beforeSelectedTypeData.key == listData.key then
    --             afterSelectedTypeIndex = typeIndex
    --             break
    --         end
    --     end
    -- end
    -- self:setSelectedIndex(afterSelectedTypeIndex)

    -- start countdown
    self:stopTypeCountdownUpdate_()
    if typeListView:getCountOfCell() > 1 then
        self:startTypeCountdownUpdate_()
    end
end

function CapsuleNewMediator:FixedSelected()
    local beforeSelectedTypeIndex = self:getSelectedIndex()
    local beforeSelectedTypeData  = self:getTypeDataList()[beforeSelectedTypeIndex]
    local afterSelectedTypeIndex = 1  -- default selected basic draw
    if beforeSelectedTypeData then
        for typeIndex, listData in ipairs(self:getTypeDataList()) do
            if beforeSelectedTypeData.key == listData.key then
                afterSelectedTypeIndex = typeIndex
                break
            end
        end
    end
    self:setSelectedIndex(afterSelectedTypeIndex)
end

function CapsuleNewMediator:updatePreviewBtnShowState(isShow, isShowTime)
    self:getCapsuleView():updatePreviewBtnShowState(self:getDrawCellViewData(), isShow)
end

function CapsuleNewMediator:updatePreviewBtnName(name)
    self:getCapsuleView():updatePreviewBtnName(self:getDrawCellViewData(), name)
end

-------------------------------------------------
-- private method

function CapsuleNewMediator:enterLayer()
    self:reloadTypeList()

    -- selectIndex
    local selectedIndex = nil
    if self.ctorArgs_.requestData then 
        if self.ctorArgs_.requestData.activityId then
            selectedIndex = self:getTypeIndexByActivityId(self.ctorArgs_.requestData.activityId)
        elseif self.ctorArgs_.requestData.type then
            selectedIndex = self:getTypeIndexByType(self.ctorArgs_.requestData.type)
        end
    else
        self:FixedSelected()
    end
    if selectedIndex then
        self:setSelectedIndex(selectedIndex)
    else
        self:FixedSelected()
    end
end

function CapsuleNewMediator:isActivityType_(drawType)
    return checkint(drawType) > 0
end


function CapsuleNewMediator:generateTypeDataKey_(drawType, typeData)
    -- data key 不能带有index，因为删了中间数据，会变动顺序
    local typeData = typeData or {}
    if drawType == ACTIVITY_TYPE.DRAW_BASIC_GET then
        return tostring(drawType)
    elseif drawType == ACTIVITY_TYPE.DRAW_NEWBIE_GET then
        return string.fmt('%1:%2', tostring(drawType), tostring(typeData.poolName))
    elseif drawType == ACTIVITY_TYPE.FREE_NEWBIE_CAPSULE then
        return tostring(drawType)
    elseif drawType == ACTIVITY_TYPE.BASIC_SKIN_CAPSULE then
        return tostring(drawType)
    end
    return string.fmt('%1:%2', tostring(drawType), tostring(typeData.activityId))
end


function CapsuleNewMediator:generateDrawMdtName_(typeIndex)
    local drawTypeData   = self:getTypeDataList()[typeIndex] or {}
    local drawTypeDefine = DRAW_TYPE_DEFINE[tostring(drawTypeData.type)] or {}
    return string.fmt('%1:%2', checkstr(drawTypeDefine.mdtName), tostring(drawTypeData.key))
end


function CapsuleNewMediator:calculateTypeLeftSeconds_(typeData)
    local targetTime = typeData and checkint(typeData.closeTimestamp_) or 0
    return checkint(targetTime - os.time())
end


function CapsuleNewMediator:resetHomeDataAt_(typeIndex, homeData)
    -- update homeData
    local drawTypeData   = self:getTypeDataList()[typeIndex] or {}
    local drawTypeDefine = DRAW_TYPE_DEFINE[tostring(drawTypeData.type)] or {}
    self:getHomeDataDict()[tostring(drawTypeData.key)] = homeData

    -- reset drawMdt data
    local drawMdtName = self:generateDrawMdtName_(typeIndex)
    local drawHomeMdt = self:GetFacade():RetrieveMediator(drawMdtName)
    local drawType = tostring(drawTypeData.type)
    if drawHomeMdt and drawHomeMdt.resetHomeData then
        local drawData = checktable(drawTypeData.data)
        if self:isActivityType_(drawType) then
            drawHomeMdt:resetHomeData(homeData, drawData.activityId)
        else
            drawHomeMdt:resetHomeData(homeData)
        end
    end

    -- reload moneyBar
    self:getCapsuleView():reloadMoneyBar(homeData.moneyIdMap, self:checkIsDisableMoneyGainByType(drawType))
end


function CapsuleNewMediator:startTypeCountdownUpdate_()
    if self.typeCountdownUpdateHandler_ then return end
    self.typeCountdownUpdateHandler_ = scheduler.scheduleGlobal(function()
        local isSelectClose = false
        local hasDrawClose  = false

        -- update all timeLeft
        for typeIndex, listData in ipairs(self:getTypeDataList()) do
            local drawType = tostring(listData.type)
            local typeData = checktable(listData.data)
            local timeLeft = self:calculateTypeLeftSeconds_(typeData)
            local isSelect = typeIndex == self:getSelectedIndex()

            -- update drawCell
            if isSelect then
                self:getCapsuleView():updateDrawCellTimeLeftInfo(self:getDrawCellViewData(), drawType, timeLeft)
            end

            -- check activity close
            if self:isActivityType_(drawType) and timeLeft <= 0 then
                if not hasDrawClose then
                    hasDrawClose = true
                end
                if not isSelectClose then
                    isSelectClose = isSelect
                end
            end
        end

        -- reload typeList
        if isSelectClose then
            if not app.uiMgr:GetCurrentScene():GetDialogByName(CURRENT_DRAW_OVER_TIP_NAME) then
                local tipsText  = __('当前活动已结束')
                local tipsView = require('common.NewCommonTip').new({text = tipsText, callback = function()
                    self:reloadTypeList()
                    self:FixedSelected()
                end, isForced = true, isOnlyOK = true})
                tipsView:setPosition(display.center)
                tipsView:setName(CURRENT_DRAW_OVER_TIP_NAME)
                app.uiMgr:GetCurrentScene():AddDialog(tipsView)
            end
        elseif hasDrawClose then
            self:reloadTypeList()
            self:FixedSelected()
        end
    end, 1)
end
function CapsuleNewMediator:stopTypeCountdownUpdate_()
    if self.typeCountdownUpdateHandler_ then
        scheduler.unscheduleGlobal(self.typeCountdownUpdateHandler_)
        self.typeCountdownUpdateHandler_ = nil
    end
end


function CapsuleNewMediator:updateTypeIndex_()
    local tweenDurationTime = 0.2
    local nowSelectedIndex  = self:getSelectedIndex()

    -------------------------------------------------
    -- scroll typeListView
    local typeListView = self:getCapsuleViewData().typeListView
    local typeListSize = typeListView:getContentSize()
    local continerSize = typeListView:getContainerSize()
    local typeCellSize = typeListView:getSizeOfCell()
    local typeListOffY = typeListView:getContentOffset().y
    local targetOffset = cc.p(0, -continerSize.height + typeListSize.height + (nowSelectedIndex-1) * typeCellSize.height)
    local isNeedOffset = false
    if targetOffset.y < typeListOffY then
        isNeedOffset = true
    elseif targetOffset.y > typeListOffY + typeListSize.height - typeCellSize.height then
        isNeedOffset = true
        targetOffset.y = targetOffset.y - typeListSize.height + typeCellSize.height
    end
    if isNeedOffset then
        -- typeListView:setContentOffsetInDuration(targetOffset, tweenDurationTime)
        typeListView:setContentOffset(targetOffset)
    end

    -- update all typeCell selected status
    for _, cellViewData in pairs(self.typeCellDict_) do
        local isSelected = cellViewData.view:getTag() == nowSelectedIndex
        self:getCapsuleView():updateTypeCellSelectStatus(cellViewData, isSelected)
    end

    -------------------------------------------------
    -- update drawCell
    self:updateDrawCell_(nowSelectedIndex)
end


function CapsuleNewMediator:updateTypeCell_(index, cell)
    local typeListView = self:getCapsuleViewData().typeListView
    local cellViewData = cell or self.typeCellDict_[typeListView:cellAtIndex(index - 1)]
    local drawTypeData = self:getTypeDataList()[index] or {}

    if cellViewData then
        local drawType = tostring(drawTypeData.type)
        local typeData = checktable(drawTypeData.data)
        self:getCapsuleView():updateTypeCellImage(cellViewData, drawType, typeData)
        self:getCapsuleView():updateTypeCellSelectStatus(cellViewData, self:getSelectedIndex() == index)
    end
end


function CapsuleNewMediator:updateDrawCell_(index)
    local cellViewData = self:getDrawCellViewData()

    local listData    = self:getTypeDataList()[index] or {}
    local drawType    = tostring(listData.type)
    local typeData    = checktable(listData.data)
    local homeData    = self:getHomeDataDict()[tostring(listData.key)]
    local typeDefine  = DRAW_TYPE_DEFINE[tostring(drawType)] or {}
    local drawMdtName = self:generateDrawMdtName_(index)

    -- update preview btn state 
    self:updatePreviewBtnName()
    self:updatePreviewBtnShowState(true)

    -- update content
    if self.contentMdtName_ ~= drawMdtName then

        -- un-regist old contentMdt
        if self.contentMdtName_ then
            self:GetFacade():UnRegsitMediator(self.contentMdtName_)
        end
        
        -- regist new contentMdt
        if typeDefine.mdtName then
            xTry(function()
                local contentMdtClass  = require(string.fmt('Game.mediator.drawCards.%1', typeDefine.mdtName))
                local contentMdtObject = contentMdtClass.new({ownerNode = cellViewData.contentLayer})
                contentMdtObject.mediatorName = drawMdtName
                self:GetFacade():RegistMediator(contentMdtObject)
            end, __G__TRACKBACK__)
        end

        -- update content name
        self.contentMdtName_ = drawMdtName

        -------------------------------------------------
        -- update mdt homeData
        if homeData then
            -- refresh home data
            self:resetHomeDataAt_(index, homeData)
        else
            if drawType == ACTIVITY_TYPE.DRAW_BASIC_GET then
                self:resetHomeDataAt_(index, self.ctorArgs_.base[1])
            elseif drawType == ACTIVITY_TYPE.BASIC_SKIN_CAPSULE then
                self:resetHomeDataAt_(index, self.ctorArgs_.cardSkin[1])
            else
                -- request home post
                if typeDefine.homePost then
                    if self:isActivityType_(drawType) then
                        self:SendSignal(typeDefine.homePost.cmdName, {activityId = typeData.activityId})
                    else
                        self:SendSignal(typeDefine.homePost.cmdName)
                    end
                end
            end
        end
    end
    -- update bgImage
    self:getCapsuleView():updateDrawCellImage(cellViewData, drawType, typeData)
    

    -- update other info
    self:getCapsuleView():updateDrawCellTimeLeftInfo(cellViewData, drawType, self:calculateTypeLeftSeconds_(typeData))
    self:getCapsuleView():updateDrawCellRuleInfoStatus(cellViewData, drawType ~= ACTIVITY_TYPE.DRAW_BASIC_GET)
end


-------------------------------------------------
-- handler

function CapsuleNewMediator:onTypeListViewDataHandler_(p_convertview, idx)
    local index = idx + 1
    local cell  = p_convertview

    -- init cell
    if cell == nil then
        local typeListView = self:getCapsuleViewData().typeListView
        local typeListCell = self:getCapsuleView():createTypeCell(typeListView:getSizeOfCell())
        typeListCell.clickHotspot:setOnClickScriptHandler(handler(self, self.onClickTypeListCellHandler_))

        cell = typeListCell.view
        self.typeCellDict_[cell] = typeListCell
    end

    -- update cell
    local typeListCell = self.typeCellDict_[cell]
    if typeListCell then
        typeListCell.view:setTag(index)
        typeListCell.clickHotspot:setTag(index)
        self:updateTypeCell_(index, typeListCell)
    end
    return cell
end


function CapsuleNewMediator:onClickTypeListCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local typeIndex = sender:getTag()
    if self:getSelectedIndex() ~= typeIndex then
        self:setSelectedIndex(typeIndex)

        self.isControllable_ = false
        self:getCapsuleView():runAction(cc.Sequence:create(
            cc.DelayTime:create(0.2),
            cc.CallFunc:create(function()
                self.isControllable_ = true
            end)
        ))
    end
end


function CapsuleNewMediator:onClickDrawCellRuleInfoButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local typeIndex = self:getSelectedIndex()
    local listData  = self:getTypeDataList()[typeIndex] or {}
    local drawType  = tostring(listData.type)
    local typeData  = checktable(listData.data)

    if drawType == ACTIVITY_TYPE.DRAW_BASIC_GET then
    elseif drawType == ACTIVITY_TYPE.DRAW_NEWBIE_GET then
        app.uiMgr:ShowIntroPopup({moduleId = INTRODUCE_MODULE_ID.DRAW_NEWBIE_INFO})
    elseif drawType == ACTIVITY_TYPE.BASIC_SKIN_CAPSULE then
        app.uiMgr:ShowIntroPopup({moduleId = INTRODUCE_MODULE_ID.BASIC_SKIN_CAPSULE})
    elseif drawType == ACTIVITY_TYPE.FREE_NEWBIE_CAPSULE then
        app.uiMgr:ShowIntroPopup({moduleId = INTRODUCE_MODULE_ID.FREE_NEWBIE_CAPSULE})
    else
        app.uiMgr:ShowIntroPopup({title = typeData.title, descr = typeData.rule})
    end
end


function CapsuleNewMediator:onClickDrawCellPreviewButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local typeIndex = self:getSelectedIndex()
    local listData  = self:getTypeDataList()[typeIndex] or {}
    local drawType  = tostring(listData.type)
    local typeData  = checktable(listData.data)
    local homeData  = self:getHomeDataDict()[tostring(listData.key)] or {}
    local cardPoolDatas = nil
    if drawType == ACTIVITY_TYPE.DRAW_CARD_CHOOSE then
        local mediator = app:RetrieveMediator(self.contentMdtName_)
        if mediator then
            local selectIndex = mediator:getSelectIndex()
            local option = homeData.option or {}
            local data = option[selectIndex] or {}
            cardPoolDatas = {
                preview      = data.preview,
                rate         = data.rate,
                slaveView    = data.slaveView,
                activityType = drawType,
            }
        end
    elseif drawType == ACTIVITY_TYPE.DRAW_SKIN_POOL then
        local mediator = app:RetrieveMediator(self.contentMdtName_)
        if mediator then
            local selectIndex = mediator:GetSelectIndex()
            if selectIndex > 0 then
                local cardSkins = homeData.cardSkins or {}
                local data = cardSkins[selectIndex] or {}
                cardPoolDatas = {
                    preview      = data.preview,
                    rate         = data.rate,
                    slaveView    = data.slaveView,
                    activityType = drawType,
                }
            else
                cardPoolDatas = {
                    preview      = homeData.defaultPoolPreview,
                    rate         = homeData.defaultPoolRate,
                    slaveView    = homeData.defaultPoolSlaveView,
                    activityType = drawType,
                }
            end
        end
    elseif drawType == ACTIVITY_TYPE.DRAW_RANDOM_POOL then
            local option = homeData.option or {}
            local data = option[selectIndex] or {}
            cardPoolDatas = {
                option       = option,
                activityType = drawType,
            }
    else
        cardPoolDatas = {
            preview      = homeData.preview,
            rate         = homeData.rate,
            slaveView    = homeData.slaveView,
            activityType = drawType,
        }
    end
    if cardPoolDatas then
        local poolView  = PoolPreviewView.new({cardPoolDatas = cardPoolDatas})
        app.uiMgr:GetCurrentScene():AddDialog(poolView)
    end
end

function CapsuleNewMediator:checkIsDisableMoneyGainByType(drawType)
    local enableMoneyGainConf = {
        [ACTIVITY_TYPE.DRAW_BASIC_GET]   = true,
        [ACTIVITY_TYPE.DRAW_CARD_CHOOSE] = true,
        [ACTIVITY_TYPE.DRAW_SKIN_POOL]   = true,
        [ACTIVITY_TYPE.DRAW_TEN_TIMES]   = true,
        [ACTIVITY_TYPE.DRAW_LIMIT]       = true,
        [ACTIVITY_TYPE.STEP_SUMMON]      = true,
        [ACTIVITY_TYPE.DRAW_LUCKY_BAG]   = true,
        [ACTIVITY_TYPE.DRAW_EXTRA_DROP]  = true,
        [ACTIVITY_TYPE.DRAW_NINE_GRID]   = true,
        [ACTIVITY_TYPE.DRAW_NEWBIE_GET]  = true,
        [ACTIVITY_TYPE.UP_PROBABILITY_UP] = true,
        [ACTIVITY_TYPE.BINARY_CHOICE]    = true,
        [ACTIVITY_TYPE.DRAW_SUPER_GET]   = true,
        [ACTIVITY_TYPE.DRAW_RANDOM_POOL] = true,
        [ACTIVITY_TYPE.BASIC_SKIN_CAPSULE] = true,
    }

    return not enableMoneyGainConf[drawType]
end

return CapsuleNewMediator
