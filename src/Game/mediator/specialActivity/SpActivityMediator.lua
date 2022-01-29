--[[
 * author : liuzhipneg
 * descpt : 特殊活动中介者
]]
local SpActivityMediator = class('SpActivityMediator', mvc.Mediator)

local ACTIVITY_TYPE_DEFINE = {
    [ACTIVITY_TYPE.LOGIN_REWARD]        = {mdtName = 'SpActivityLoginPageMediator',           homePost = POST.ACTIVITY_LOGIN_REWARD_HOME},     -- 登录礼包
    [ACTIVITY_TYPE.ITEMS_EXCHANGE]      = {mdtName = 'SpActivityExchangePageMediator',        homePost = POST.ACTIVITY_EXCHANGE_HOME},         -- 道具兑换
    [ACTIVITY_TYPE.CHARGE_WHEEL]        = {mdtName = 'SpActivityWheelPageMediator',           homePost = POST.ACTIVITY_WHEEL_HOME},            -- 大转盘
    [ACTIVITY_TYPE.CUMULATIVE_RECHARGE] = {mdtName = 'SpActivityAccumulativePayPageMediator', homePost = POST.ACTIVITY_ACCUMULATIVE_PAY_HOME}, -- 累充活动
    [ACTIVITY_TYPE.ACTIVITY_QUEST]      = {mdtName = 'SpActivityQuestPageMediator',           homePost = POST.ACTIVITY_QUEST_HOME},            -- 活动副本
    [ACTIVITY_TYPE.BINGGO]              = {mdtName = 'SpActivityBinggoPageMediator',          homePost = POST.ACTIVITY_BINGGO_HOME},           -- 拼图活动
    [ACTIVITY_TYPE.ANNIVERSARY]         = {mdtName = 'SpActivityAnniPageMediator'},                                                            -- 周年庆
    [ACTIVITY_TYPE.ACTIVITY_PREVIEW]    = {mdtName = 'SpActivityPreviewPageMediator',         homePost = POST.ACTIVITY_PREVIEW_HOME},          -- 活动预览
    [ACTIVITY_TYPE.COMMON_ACTIVITY]     = {},                                                                                                  -- 通用活动(只显示背景图)
    [ACTIVITY_TYPE.TEAM_QUEST_ACTIVITY] = {},                                                                                                  -- 组队本活动
    [ACTIVITY_TYPE.DOUNBLE_EXP_NORMAL]  = {},                                                                                                  -- 普通本双倍经验活动
    [ACTIVITY_TYPE.DOUNBLE_EXP_HARD]    = {},                                                                                                  -- 困难本双倍经验活动
    [ACTIVITY_TYPE.ANNIVERSARY_PV]      = {mdtName = 'SpActivityAnniPVMediator',                                                       },      -- 活动pv
    [ACTIVITY_TYPE.DRAW_CARD_CHOOSE]    = {mdtName = 'SpActivityChooseCardPageMediator',                                               },      -- 选卡卡池
    [ACTIVITY_TYPE.DRAW_SKIN_POOL]      = {mdtName = 'SpActivitySkinPoolPageMediator',                                                 },      -- 皮肤卡池
    [ACTIVITY_TYPE.DRAW_RANDOM_POOL]    = {mdtName = 'SpActivityCommonPageMediator',                                                   },      -- 铸池抽卡
    [ACTIVITY_TYPE.BINARY_CHOICE]       = {mdtName = 'SpActivityCommonPageMediator',                                                   },      -- 双抉卡池
    [ACTIVITY_TYPE.SKIN_CARNIVAL]       = {mdtName = 'SpActivityCommonPageMediator',                                                   },      -- 皮肤嘉年华
    [ACTIVITY_TYPE.ANNIVERSARY19]       = {mdtName = 'SpActivityCommonPageMediator',                                                   },      -- 周年庆19
    [ACTIVITY_TYPE.ARTIFACT_ROAD]       = {mdtName = 'SpActivityCommonPageMediator',                                                   },      -- 神器之路
    [ACTIVITY_TYPE.DRAW_SUPER_GET]      = {mdtName = 'SpActivityCommonPageMediator',                                                   },      -- 超得抽卡
    [ACTIVITY_TYPE.LUCK_NUMBER]         = {mdtName = 'SpActivityLuckNumberPageMediator'                                                },      -- 幸运数字
    [ACTIVITY_TYPE.ANNIVERSARY_PV2]     = {mdtName = 'SpActivityAnni19PVMediator',                                                     },      -- 活动pv2
    [ACTIVITY_TYPE.ANNIVERSARY_PV3]     = {mdtName = 'SpActivityAnni20PVMediator',                                                     },      -- 活动pv3
    [ACTIVITY_TYPE.JUMP_JEWEL]          = {mdtName = 'SpActivityCommonPageMediator',                                                   },      -- 塔可跳转活动 
    [ACTIVITY_TYPE.CV_SHARE2]           = {mdtName = 'SpActivityShareCV2Mediator',                                                     },      -- 新CV分享活动
    [ACTIVITY_TYPE.SUMMER_ACTIVITY]     = {mdtName = 'SpActivityCommonPageMediator',                                                   },      -- 夏活
    [ACTIVITY_TYPE.CYCLIC_TASKS]        = {mdtName = 'SpActivityCommonPageMediator',                                                   },      -- 循环任务
    [ACTIVITY_TYPE.SCRATCHER]           = {mdtName = 'SpActivityCommonPageMediator',                                                   },      -- 飨灵刮刮乐
    [ACTIVITY_TYPE.SPRING_ACTIVITY_20]  = {mdtName = 'SpActivityCommonPageMediator',                                                   },      -- 20春活
    [ACTIVITY_TYPE.ANNIVERSARY_20]      = {mdtName = 'SpActivityCommonPageMediator',                                                   },      -- 20周年庆
    [ACTIVITY_TYPE.BATTLE_CARD]         = {mdtName = 'SpActivityCommonPageMediator',                                                   },      -- 战牌
    [ACTIVITY_TYPE.CASTLE_ACTIVITY]     = {mdtName = 'SpActivityCommonPageMediator',                                                   },      -- 古堡迷踪
    

}
SpActivityMediator.ACTIVITY_TYPE_DEFINE = ACTIVITY_TYPE_DEFINE

function SpActivityMediator:ctor(params, viewComponent)
	self.super.ctor(self, 'SpActivityMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function SpActivityMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true
    self.typeCellDict_   = {}
    self.typeDataList_   = {}
    self.homeDataDict_   = {}
    self.homeSglNameMap_ = {}
    self.contentMdtName_ = nil
    for _, defineData in pairs(ACTIVITY_TYPE_DEFINE) do
        if defineData.homePost then
            self.homeSglNameMap_[defineData.homePost.sglName] = defineData.homePost.sglName
        end
    end
    -- pre set closeTimestamp
    for _, typeData in ipairs(self.ctorArgs_.activity) do
        if ACTIVITY_TYPE_DEFINE[typeData.type] and typeData.leftSeconds  then
            typeData.closeTimestamp_ = os.time() + checkint(typeData.leftSeconds) + 2
        end
    end
    -- create scene
    local viewComponent = app.uiMgr:SwitchToTargetScene('Game.views.specialActivity.SpActivityScene')
    self:SetViewComponent(viewComponent)
    -- add listener
    self:getActivityViewData().typeListView:setDataSourceAdapterScriptHandler(handler(self, self.onTypeListViewDataHandler_))
    self:getDrawCellViewData().ruleInfoBtn:setOnClickScriptHandler(handler(self, self.onClickDrawCellRuleInfoButtonHandler_))

    self.isControllable_ = false
    self:GetViewComponent():showUI(function()
    self.isControllable_ = true
    end)
end


function SpActivityMediator:CleanupView()
end


function SpActivityMediator:OnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightHide')

    for _, defineData in pairs(ACTIVITY_TYPE_DEFINE) do
        if defineData.homePost then
            regPost(defineData.homePost)
        end
    end
    self:enterLayer()
end


function SpActivityMediator:OnUnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'hide')

    for _, defineData in pairs(ACTIVITY_TYPE_DEFINE) do
        if defineData.homePost then
            unregPost(defineData.homePost or {})
        end
    end

    self:GetFacade():UnRegsitMediator(self.contentMdtName_)
    self:stopTypeCountdownUpdate_()
end


function SpActivityMediator:InterestSignals()
    local signalList = {
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
    }
    for _, sglName in pairs(self.homeSglNameMap_) do
        table.insert(signalList, sglName)
    end
    return signalList
end
function SpActivityMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -- check is home signal
    if self.homeSglNameMap_[name] then
        self:resetHomeDataAt_(self:getSelectedIndex(), data)
    else
        -- update money bar
        if name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
            self:refreshCurrencyBar()
        elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then

        end
    end
end


-------------------------------------------------
-- get / set
function SpActivityMediator:getActivityViewData()
    return self:GetViewComponent() and self:GetViewComponent():getViewData() or {}
end
function SpActivityMediator:getDrawCellViewData()
    return self:GetViewComponent() and self:GetViewComponent():getDrawCellViewData() or {}
end


function SpActivityMediator:getTypeDataList()
    return self.typeDataList_ or {}
end


function SpActivityMediator:getHomeDataDict()
    return self.homeDataDict_ or {}
end


function SpActivityMediator:getSelectedIndex()
    return self.selectedIndex_ or 0
end
function SpActivityMediator:setSelectedIndex(index)
    self.selectedIndex_ = checkint(index)
    self:updateTypeIndex_()
end

function SpActivityMediator:getSpActivityOpenTime(  )
	for i, v in ipairs(checktable(self.ctorArgs_.activity)) do
		if v.type == ACTIVITY_TYPE.SP_ACTIVITY then	
			return v.fromTime
		end
    end
    return 0
end
-------------------------------------------------
-- public method

function SpActivityMediator:reloadTypeList()
    local beforeSelectedTypeIndex = self:getSelectedIndex()
    local beforeSelectedTypeData  = self:getTypeDataList()[beforeSelectedTypeIndex]

    -- reset all typeData
    self.typeDataList_ = {}
    
    -------------------------------------------------
    -- activity data
    for _, activityData in ipairs(self.ctorArgs_.activity or {}) do
        if ACTIVITY_TYPE_DEFINE[activityData.type] and self:calculateTypeLeftSeconds_(activityData) > 0 and activityData.fromTime >= self:getSpActivityOpenTime() then
            local dataType = tostring(activityData.type)
            local dataKey  = self:generateTypeDataKey_(dataType, activityData)
            table.insert(self.typeDataList_, {type = dataType, data = activityData, key = dataKey})
        end
    end
    -------------------------------------------------
    
    -- reload typeListView
    local typeListView = self:getActivityViewData().typeListView
    typeListView:setCountOfCell(#self:getTypeDataList())
    typeListView:reloadData()
    
    -- check fixed selected
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

    -- start countdown
    self:stopTypeCountdownUpdate_()
    if typeListView:getCountOfCell() > 1 then
        self:startTypeCountdownUpdate_()
    end
end


-------------------------------------------------
-- private method
function SpActivityMediator:enterLayer()
    -- update view
    self:reloadTypeList()
    self:RefreshTitle()
end

--[[
刷新标题
--]]
function SpActivityMediator:RefreshTitle()
    local viewComponent = self:GetViewComponent()
    for i, v in ipairs(self.ctorArgs_.activity) do
        if v.type == ACTIVITY_TYPE.SP_ACTIVITY then
            viewComponent:RefreshTitleLabel(v.title[i18n.getLang()])
            break
        end
    end
end
function SpActivityMediator:isActivityType_(drawType)
    return true
end


function SpActivityMediator:generateTypeDataKey_(drawType, typeData)
    -- data key 不能带有index，因为删了中间数据，会变动顺序
    local typeData = typeData or {}
    if drawType == ACTIVITY_TYPE.DRAW_BASIC_GET then
        return tostring(drawType)
    elseif drawType == ACTIVITY_TYPE.DRAW_NEWBIE_GET then
        return string.fmt('%1:%2', tostring(drawType), tostring(typeData.name))
    end
    return string.fmt('%1:%2', tostring(drawType), tostring(typeData.activityId))
end


function SpActivityMediator:generateDrawMdtName_(typeIndex)
    local drawTypeData   = self:getTypeDataList()[typeIndex] or {}
    local drawTypeDefine = ACTIVITY_TYPE_DEFINE[tostring(drawTypeData.type)] or {}
    return string.fmt('%1:%2', checkstr(drawTypeDefine.mdtName), tostring(drawTypeData.key))
end


function SpActivityMediator:calculateTypeLeftSeconds_(typeData)
    local targetTime = typeData and checkint(typeData.closeTimestamp_) or 0
    return checkint(targetTime - os.time())
end


function SpActivityMediator:resetHomeDataAt_(typeIndex, homeData)
    -- update homeData
    local drawTypeData   = self:getTypeDataList()[typeIndex] or {}
    --local drawTypeDefine = ACTIVITY_TYPE_DEFINE[tostring(drawTypeData.type)] or {}
    self:getHomeDataDict()[tostring(drawTypeData.key)] = homeData
    
    -- reset drawMdt data
    local drawMdtName = self:generateDrawMdtName_(typeIndex)
    local drawHomeMdt = self:GetFacade():RetrieveMediator(drawMdtName)
    if drawHomeMdt and drawHomeMdt.resetHomeData then
        local drawType = tostring(drawTypeData.type)
        local drawData = checktable(drawTypeData.data)
        if self:isActivityType_(drawType) then
            drawHomeMdt:resetHomeData(homeData, drawData.activityId)
        else
            drawHomeMdt:resetHomeData(homeData)
        end
    end
end


function SpActivityMediator:startTypeCountdownUpdate_()
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
                self:GetViewComponent():updateDrawCellTimeLeftInfo(self:getDrawCellViewData(), drawType, timeLeft)
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
                end, isForced = true, isOnlyOK = true})
                tipsView:setPosition(display.center)
                tipsView:setName(CURRENT_DRAW_OVER_TIP_NAME)
                app.uiMgr:GetCurrentScene():AddDialog(tipsView)
            end
        elseif hasDrawClose then
            self:reloadTypeList()
        end
    end, 1)
end
function SpActivityMediator:stopTypeCountdownUpdate_()
    if self.typeCountdownUpdateHandler_ then
        scheduler.unscheduleGlobal(self.typeCountdownUpdateHandler_)
        self.typeCountdownUpdateHandler_ = nil
    end
end


function SpActivityMediator:updateTypeIndex_()
    --local tweenDurationTime = 0.2
    local nowSelectedIndex  = self:getSelectedIndex()

    -------------------------------------------------
    -- scroll typeListView
    local typeListView = self:getActivityViewData().typeListView
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
        self:GetViewComponent():updateTypeCellSelectStatus(cellViewData, isSelected)
    end

    -------------------------------------------------
    -- update drawCell
    self:updateDrawCell_(nowSelectedIndex)
end


function SpActivityMediator:updateTypeCell_(index, cell)
    local typeListView = self:getActivityViewData().typeListView
    local cellViewData = cell or self.typeCellDict_[typeListView:cellAtIndex(index - 1)]
    local drawTypeData = self:getTypeDataList()[index] or {}

    if cellViewData then
        local drawType = tostring(drawTypeData.type)
        local typeData = checktable(drawTypeData.data)
        self:GetViewComponent():updateTypeCellImage(cellViewData, drawType, typeData)
        self:GetViewComponent():updateTypeCellSelectStatus(cellViewData, self:getSelectedIndex() == index)
    end
end


function SpActivityMediator:updateDrawCell_(index)
    local cellViewData = self:getDrawCellViewData()

    local listData    = self:getTypeDataList()[index] or {}
    local drawType    = tostring(listData.type)
    local typeData    = checktable(listData.data)
    local homeData    = self:getHomeDataDict()[tostring(listData.key)]
    local typeDefine  = ACTIVITY_TYPE_DEFINE[tostring(drawType)] or {}
    local drawMdtName = self:generateDrawMdtName_(index)

    -- update content
    if self.contentMdtName_ ~= drawMdtName then

        -- un-regist old contentMdt
        if self.contentMdtName_ then
            self:GetFacade():UnRegsitMediator(self.contentMdtName_)
        end

        -- regist new contentMdt
        if typeDefine.mdtName then
            xTry(function()
                local contentMdtClass  = require(string.fmt('Game.mediator.specialActivity.%1', typeDefine.mdtName))
                local contentMdtObject = contentMdtClass.new({ownerNode = cellViewData.contentLayer, typeData = typeData})
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
    self:GetViewComponent():updateDrawCellImage(cellViewData, drawType, typeData)

    -- update other info
    self:GetViewComponent():updateDrawCellTimeLeftInfo(cellViewData, drawType, self:calculateTypeLeftSeconds_(typeData))
    local rule = listData and checkstr(listData.data.detail[i18n.getLang()]) or ''
    self:GetViewComponent():updateDrawCellRuleInfoStatus(cellViewData, string.len(rule) > 0)
end
--[[
更新货币栏
--]]
function SpActivityMediator:refreshCurrencyBar()
    if self:GetViewComponent() then
        self:GetViewComponent():RefreshCurrencyBar()
    end
end
-------------------------------------------------
-- handler
--[[
活动页签列表数据处理
--]]
function SpActivityMediator:onTypeListViewDataHandler_(p_convertview, idx)
    local index = idx + 1
    local cell  = p_convertview

    -- init cell
    if cell == nil then
        local typeListView = self:getActivityViewData().typeListView
        local typeListCell = self:GetViewComponent():createTypeCell(typeListView:getSizeOfCell())
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

--[[
活动页签cell点击回调
--]]
function SpActivityMediator:onClickTypeListCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local typeIndex = sender:getTag()
    if self:getSelectedIndex() ~= typeIndex then
        self:setSelectedIndex(typeIndex)

        self.isControllable_ = false
        self:GetViewComponent():runAction(cc.Sequence:create(
            cc.DelayTime:create(0.2),
            cc.CallFunc:create(function()
                self.isControllable_ = true
            end)
        ))
    end
end
--[[
活动页签规则说明按钮点击回调
--]]
function SpActivityMediator:onClickDrawCellRuleInfoButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    local typeIndex = self:getSelectedIndex()
    local listData  = self:getTypeDataList()[typeIndex] or {}
    --local drawType  = tostring(listData.type)
    local typeData  = checktable(listData.data)
    app.uiMgr:ShowIntroPopup({title = typeData.title[i18n.getLang()], descr = typeData.detail[i18n.getLang()]})
end
-- handler
-------------------------------------------------
return SpActivityMediator
