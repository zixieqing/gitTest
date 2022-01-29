local CatModuleCatGrowView     = require('Game.views.catModule.CatModuleCatGrowView')
local CatModuleCatGrowMediator = class('CatModuleCatGrowMediator', mvc.Mediator)

function CatModuleCatGrowMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatModuleCatGrowMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

local POSTGRADUATE_TYPE    = CatModuleCatGrowView.POSTGRADUATE_TYPE
local IS_POSTGRADUATE_OPEN = {
    [POSTGRADUATE_TYPE.WORK]  = function(catModel) return catModel:isUnlockWork()  end,
    [POSTGRADUATE_TYPE.STUDY] = function(catModel) return catModel:isUnlockStudy() end,   
}


-------------------------------------------------
-- inheritance

function CatModuleCatGrowMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = CatModuleCatGrowView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().studyBtn, handler(self, self.onClickStudyBtnHandler_))
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    ui.bindClick(self:getViewData().workingBtn, handler(self, self.onClickWorkingBtnHandler_))
    ui.bindClick(self:getViewData().promoBtn, handler(self, self.onClickPromoteBtnHandler_))
    for _, btn in ipairs(self:getViewData().postGraduateBtnMaps) do
        ui.bindClick(btn, handler(self, self.onClickPostgraduateTypeBtnHandler_), false)
    end
    self:getViewData().studyTabView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.view, handler(self, self.onClickPostgraduateCellBtnHandler_))
        cellViewData.damandTableView:setCellUpdateHandler(function(cellIndex, cellNode)
            local abilityData = checktable(cellViewData.requireAbilityList[cellIndex])
            self:getViewNode():updateDamandNode(cellNode, {isAttr = false, damandId = abilityData.id, value = abilityData.value})
        end)
    end)
    self:getViewData().workTabView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.view, handler(self, self.onClickPostgraduateCellBtnHandler_))
        cellViewData.damandTableView:setCellUpdateHandler(function(cellIndex, cellNode)
            local abilityData = cellViewData.requireAbilityList[cellIndex]
            self:getViewNode():updateDamandNode(cellNode, {isAttr = false, damandId = abilityData.id, value = abilityData.value})
        end)
    end)
    self:getViewData().studyTabView:setCellUpdateHandler(function(cellIndex, cellViewData)
        local studyId = checkint(self:getStudyIdList()[cellIndex])
        local isSelected = self:getSelectedPostgraduateType() == POSTGRADUATE_TYPE.STUDY and self:getSelectedPostgraduateId() == studyId
        self:getViewNode():updateStudyCellHandler(cellViewData, studyId, isSelected, self:getCatModel())
    end)
    self:getViewData().workTabView:setCellUpdateHandler(function(cellIndex, cellViewData)
        local workId     = checkint(self:getWorkIdList()[cellIndex])
        local isSelected = self:getSelectedPostgraduateType() == POSTGRADUATE_TYPE.WORK and self:getSelectedPostgraduateId() == workId
        self:getViewNode():updateWorkCellHandler(cellViewData, workId, isSelected, self:getCatModel())
    end)


    -- update view
    self:setCatUuid(self.ctorArgs_.catUuid)
    self:setSelectedPostgraduateType(0)
    for postgradutateType, isOpenFunc in pairs(IS_POSTGRADUATE_OPEN) do
        if isOpenFunc(self:getCatModel()) then
            self:setSelectedPostgraduateType(postgradutateType)
            break
        end
    end  
end


function CatModuleCatGrowMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function CatModuleCatGrowMediator:OnRegist()
    regPost(POST.HOUSE_CAT_STUDY_BEGAN)
    regPost(POST.HOUSE_CAT_WORK_BEGAN)
    regPost(POST.HOUSE_CAT_CAREER_UP)
end


function CatModuleCatGrowMediator:OnUnRegist()
    unregPost(POST.HOUSE_CAT_STUDY_BEGAN)
    unregPost(POST.HOUSE_CAT_WORK_BEGAN)
    unregPost(POST.HOUSE_CAT_CAREER_UP)
end


function CatModuleCatGrowMediator:InterestSignals()
    return {
        POST.HOUSE_CAT_STUDY_BEGAN.sglName,
        POST.HOUSE_CAT_WORK_BEGAN.sglName,
        POST.HOUSE_CAT_CAREER_UP.sglName,
        SGL.CAT_MODULE_CAT_REFRESH_UPDATE,
        SGL.CAT_MODEL_UPDATE_AGE,
        SGL.CAT_MODEL_UPDATE_STUDY_ID,
        SGL.CAT_MODEL_UPDATE_WORK_ID,
    }
end
function CatModuleCatGrowMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -- 开始学习
    if name == POST.HOUSE_CAT_STUDY_BEGAN.sglName then
        local studyId = data.requestData.studyId

        -- update good
        local consumeConf = CatHouseUtils.GetCatStudyConsume(studyId, self:getCatModel())
        for _, goodsData in pairs(consumeConf) do
            goodsData.num = -goodsData.num
        end
        CommonUtils.DrawRewards(consumeConf)

        -- update studyTime
        self:getCatModel():setLeftActionTimes(self:getCatModel():getLeftActionTimes() - 1)
        self:getCatModel():setStudyLeftSeconds(data.leftSeconds)
        self:getCatModel():setStudyingId(studyId)
        

        -- update attr
        local studyConf = CONF.CAT_HOUSE.CAT_STUDY:GetValue(studyId)
        for attrId, attrValue in pairs(studyConf.consumeAttr or {}) do
            if not self:getCatModel():isDisableAttrReduceAt(attrId) then
                self:getCatModel():setAttrNum(attrId, self:getCatModel():getAttrNum(attrId) - checkint(attrValue))
            end
        end

        -- update view
        self:getViewNode():updateStudyLeftTime(self:getCatModel())
        self:getViewNode():updateStudyCostLabel(self:getSelectedPostgraduateId(), self:getCatModel())

    -- 开始工作
    elseif name == POST.HOUSE_CAT_WORK_BEGAN.sglName then
        local workId      = data.requestData.workId
        local workConf    = CONF.CAT_HOUSE.CAT_WORK:GetValue(workId)
        local careerId    = checkint(workConf.careerId)
        local careerLvl   = self:getCatModel():getCareerLevel(careerId)
        local workLvlConf = workConf.careerLevel[tostring(careerLvl)]
        if not workLvlConf then
            return
        end

        -- update workTime
        self:getCatModel():setLeftActionTimes(self:getCatModel():getLeftActionTimes() - 1)
        self:getCatModel():setWorkLeftSeconds(data.leftSeconds)
        self:getCatModel():setWorkingId(workId)
        

        -- update attr
        for attrId, attrValue in pairs(workLvlConf.consumeAttr or {}) do
            if not self:getCatModel():isDisableAttrReduceAt(attrId) then
                self:getCatModel():setAttrNum(attrId, self:getCatModel():getAttrNum(attrId) - checkint(attrValue))
            end
        end

        -- update view
        self:getViewNode():updateWorkLeftTime(self:getCatModel())

    -- 升职
    elseif name == POST.HOUSE_CAT_CAREER_UP.sglName then
        -- update level data
        local careerId  = data.requestData.careerId
        local curLevel  = self:getCatModel():getCareerLevel(careerId) + 1
        local levelConf = CONF.CAT_HOUSE.CAT_CAREER_LEVEL:GetValue(curLevel)

        self:getCatModel():setCareerLevel(careerId, curLevel)
        self:getCatModel():setCareerExp(careerId, 0)

        -- update table view cell
        for _, workViewData in pairs(self:getViewData().workTabView:getCellViewDataDict()) do
            if workViewData.view:getTag() == self:getSelectedPostgraduateId() then
                self:getViewNode():updateWorkCellHandler(workViewData, self:getSelectedPostgraduateId(), true, self:getCatModel())
                break
            end
        end

        -- update detail page
        self:getViewNode():updateWorkDetailPage(self:getSelectedPostgraduateId(), self:getCatModel())

        -- update view
        app.uiMgr:ShowInformationTips(__("升职成功"))


    -- 刷新猫咪数据
    elseif name == SGL.CAT_MODULE_CAT_REFRESH_UPDATE then
        if self:getSelectedPostgraduateType() == POSTGRADUATE_TYPE.STUDY and self:getCatModel():getStudyingId() > 0 then
            -- update studyTime
            for _, workNode in pairs(self:getViewData().studyTabView:getCellViewDataDict()) do
                if workNode.view:getTag() == self:getCatModel():getStudyingId() then
                    workNode.timeLabel:updateLabel({text = CommonUtils.getTimeFormatByType(self:getCatModel():getStudyLeftSeconds(), 3)})
                    break
                end
            end
        elseif self:getSelectedPostgraduateType() == POSTGRADUATE_TYPE.WORK and self:getCatModel():getWorkingId() > 0 then
            -- update workTime
            for _, workNode in pairs(self:getViewData().workTabView:getCellViewDataDict()) do
                if workNode.view:getTag() == self:getCatModel():getWorkingId() then
                    workNode.timeTitle:updateLabel({text = CommonUtils.getTimeFormatByType(self:getCatModel():getWorkLeftSeconds(), 3)})
                    break
                end
            end
        end


    -- 刷新年龄
    elseif name == SGL.CAT_MODEL_UPDATE_AGE then
        if data.catUuid == self:getCatUuid() then
            -- update table view
            self:setStudyIdList()

            -- update detail view
            self:setSelectedPostgraduateId(self:getStudyIdList()[1])
        end


    -- 学习状态变更
    elseif name == SGL.CAT_MODEL_UPDATE_STUDY_ID then
        if data.catUuid == self:getCatUuid() then
            -- update table view
            self:setStudyIdList()

            -- update detail view
            self:getViewNode():updateStudyLeftTime(self:getCatModel())
        end


    -- 工作状态变更
    elseif name == SGL.CAT_MODEL_UPDATE_WORK_ID then
        if data.catUuid == self:getCatUuid() then
            -- update table view
            self:setWorkIdList()

            -- update detail view
            self:getViewNode():updateWorkLeftTime(self:getCatModel())
        end
        

    end
end


-------------------------------------------------
-- get / set

function CatModuleCatGrowMediator:getViewNode()
    return  self.viewNode_
end
function CatModuleCatGrowMediator:getViewData()
    return self:getViewNode():getViewData()
end


function CatModuleCatGrowMediator:getSelectedPostgraduateId()
    return checkint(self.selectedPostgraduateId_)
end
function CatModuleCatGrowMediator:setSelectedPostgraduateId(postgradutateId)
    self.selectedPostgraduateId_ = checkint(postgradutateId)
    self:getViewNode():updateView(self:getSelectedPostgraduateId(), self:getSelectedPostgraduateType(), self:getCatModel())
end

-- futher study btn index
function CatModuleCatGrowMediator:setSelectedPostgraduateType(tabIndex)
    self.selectedPostgraduateType_ = checkint(tabIndex)
    self:getViewData().workTabView:setVisible(self:getSelectedPostgraduateType() == POSTGRADUATE_TYPE.WORK)
    self:getViewData().studyTabView:setVisible(self:getSelectedPostgraduateType() == POSTGRADUATE_TYPE.STUDY)

    if self:getSelectedPostgraduateType() == POSTGRADUATE_TYPE.WORK and not self.taskInit_ then
        self:setWorkIdList()
        self.taskInit_ = true
    elseif self:getSelectedPostgraduateType() == POSTGRADUATE_TYPE.STUDY and not self.studyInit_ then
        self:setStudyIdList()
        self.studyInit_ = true
    end

    for studyIndex, studyBtn in pairs(self:getViewData().postGraduateBtnMaps) do
        studyBtn.setSelectedState(studyIndex == self:getSelectedPostgraduateType())
    end
    local postgradutateId = self.selectedPostgraduateType_ == POSTGRADUATE_TYPE.WORK and self:getWorkIdList()[1] or self:getStudyIdList()[1]
    self:setSelectedPostgraduateId(postgradutateId)
end
function CatModuleCatGrowMediator:getSelectedPostgraduateType()
    return checkint(self.selectedPostgraduateType_ )
end



-- cat uuid
function CatModuleCatGrowMediator:getCatUuid()
    return self.catUuid_
end
function CatModuleCatGrowMediator:setCatUuid(catUuid)
    self.catUuid_  = catUuid
    self.catModel_ = app.catHouseMgr:getCatModel(self:getCatUuid())
end


---@return HouseCatModel
function CatModuleCatGrowMediator:getCatModel()
    return self.catModel_
end
function CatModuleCatGrowMediator:getPlayerCatId()
    return self:getCatModel():getPlayerCatId()
end

-- cat set careerData
function CatModuleCatGrowMediator:setWorkIdList()
    self.workIdList_ = CONF.CAT_HOUSE.CAT_WORK:GetIdList()
    local workingId  = self:getCatModel():getWorkingId()
    table.sort(self:getWorkIdList(), function(workIdA, workIdB)
        if checkint(workIdA) == workingId then
            return true
        elseif checkint(workIdB) == workingId then
            return false
        else
            local workConfA = CONF.CAT_HOUSE.CAT_WORK:GetValue(workIdA)
            local workConfB = CONF.CAT_HOUSE.CAT_WORK:GetValue(workIdB)
            local careerLvlA = self:getCatModel():getCareerLevel(workConfA.careerId)
            local careerLvlB = self:getCatModel():getCareerLevel(workConfB.careerId)
            if careerLvlA ~= careerLvlB then
                return careerLvlA > careerLvlB
            else
                return workIdA > workIdB
            end
        end
    end)
    self:getViewData().workTabView:resetCellCount(#self:getWorkIdList())
end
function CatModuleCatGrowMediator:getWorkIdList()
    return checktable(self.workIdList_)
end


-- cat set studyData
function CatModuleCatGrowMediator:setStudyIdList()
    self.studyIdList_ = app.catHouseMgr:getStudyIdListByAgeId(self:getCatModel():getAge())
    local studyingId  = self:getCatModel():getStudyingId()
    table.sort(self:getStudyIdList(), function(studyIdA, studyIdB)
        if studyIdA == studyingId then
            return true
        elseif studyIdB == studyingId then
            return false
        else
            return studyIdA > studyIdB
        end
    end)
    self:getViewData().studyTabView:resetCellCount(#self:getStudyIdList())


    if studyingId > 0 and self:getStudyIdList()[1] ~= studyingId then
        table.insert(self.studyIdList_, studyingId)
    end

end
function CatModuleCatGrowMediator:getStudyIdList()
    return checktable(self.studyIdList_)
end
-------------------------------------------------
-- public

function CatModuleCatGrowMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private
--[[
    猫咪 检测能否工作
]]
function CatModuleCatGrowMediator:checkWorkEnable(workId, isShowTips)
    -- 有工作次数 && 工作属性消耗 && 岗位能力要求 && 活着 && 空闲中
    local becauseDescr  = ''
    local workEnable    = true
    local leadToDisease = false
    if not self:getCatModel():isAlive() then
        becauseDescr = __('猫咪已经死亡')
        workEnable  = false
    elseif self:getCatModel():isSicked() then
        becauseDescr = __('您的猫病了,无法完成您的要求')
        workEnable  = false
    elseif not self:getCatModel():isDoNothing() then
        becauseDescr = __('猫咪正在忙碌中')
        workEnable  = false
    elseif self:getCatModel():getLeftActionTimes() <= 0 then
        becauseDescr = __('今日猫咪打工次数用完')
        workEnable  = false
    else
        local workConfs        = CONF.CAT_HOUSE.CAT_WORK:GetValue(workId)
        local careerId         = checkint(workConfs.careerId)
        local careerLvl        = self:getCatModel():getCareerLevel(careerId)
        local careerConf       = CONF.CAT_HOUSE.CAT_CAREER_INFO:GetValue(careerId)[tostring(careerLvl)]
        local workConf         = workConfs.careerLevel[tostring(careerLvl)]
        local abilityDescrList = {}
        for abilityId, abilityValue in pairs (careerConf.requireAbility) do
            local attrConf  = CONF.CAT_HOUSE.CAT_ABILITY:GetValue(abilityId)
            local currValue = self:getCatModel():getAbility(abilityId)
            local needValue = checkint(abilityValue)
            if currValue < needValue then
                table.insert(abilityDescrList, string.fmt(__('_name_不足_num_'), {_name_ = tostring(attrConf.name), _num_ = needValue}))
            end
        end
        if #abilityDescrList > 0 then
            becauseDescr = table.concat(abilityDescrList, ',')
            workEnable   = false
        end

        if workEnable then
            local attrDescrList = {}
            for attrId, attrValue in pairs (workConf.consumeAttr) do
                local attrConf  = CONF.CAT_HOUSE.CAT_ATTR:GetValue(attrId)
                local currValue = self:getCatModel():getAttrNum(attrId)
                local needValue = checkint(attrValue)
                if currValue < needValue then
                    table.insert(attrDescrList, string.fmt(__('_name_不足_num_'), {_name_ = tostring(attrConf.name), _num_ = needValue}))
                end

                if not leadToDisease and currValue - needValue < CatHouseUtils.ATTR_LEAD_TO_DISEASE_LIMIT then
                    leadToDisease = true
                end
            end
            if #attrDescrList > 0 then
                becauseDescr = table.concat(attrDescrList, ',')
                workEnable  = false
            end
        end
    end
    if isShowTips and not workEnable then
        app.uiMgr:ShowInformationTips(string.fmt(__('_because_，不能工作'), {_because_ = becauseDescr}))
    end
    return workEnable, leadToDisease
end


--[[
    猫咪 检测能否学习
]]
function CatModuleCatGrowMediator:checkStudyEnable(studyId, isShowTips)
    -- 有学习次数 && 学习属性消耗 && 学习道具消耗 && 学习能力要求 && 活着 && 空闲中
    local becauseDescr  = ''
    local studyEnable   = true
    local leadToDisease = false
    if not self:getCatModel():isAlive() then
        becauseDescr = __('猫咪已经死亡')
        studyEnable  = false
    elseif self:getCatModel():isSicked() then
        becauseDescr = __('您的猫病了,无法完成您的要求')
        studyEnable  = false
    elseif not self:getCatModel():isDoNothing() then
        becauseDescr = __('猫咪正在忙碌中')
        studyEnable  = false
    elseif self:getCatModel():getLeftActionTimes() <= 0 then
        becauseDescr = __('今日猫咪学习次数用完')
        studyEnable  = false
    else
        local consumeConf = CatHouseUtils.GetCatStudyConsume(studyId, self:getCatModel())
        for _, goodsData in ipairs(consumeConf) do
            if app.goodsMgr:GetGoodsAmountByGoodsId(goodsData.goodsId) < checkint(goodsData.num) then
                local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsData.goodsId)
                becauseDescr = string.format(__('%s不足'), goodsConfig.name)
                studyEnable  = false
                break
            end
        end

        local studyConf  = CONF.CAT_HOUSE.CAT_STUDY:GetValue(studyId)
        if studyEnable then
            local abilityDescrList = {}
            for abilityId, abilityValue in pairs (studyConf.requireAbility) do
                local attrConf  = CONF.CAT_HOUSE.CAT_ABILITY:GetValue(abilityId)
                local currValue = self:getCatModel():getAbility(abilityId)
                local needValue = checkint(abilityValue)
                if currValue < needValue then
                    table.insert(abilityDescrList, string.fmt(__('_name_不足_num_'), {_name_ = tostring(attrConf.name), _num_ = needValue}))
                end
            end
            if #abilityDescrList > 0 then
                becauseDescr = table.concat(abilityDescrList, ',')
                studyEnable  = false
            end
        end

        if studyEnable then
            local attrDescrList = {}
            for attrId, attrValue in pairs (studyConf.consumeAttr) do
                local attrConf  = CONF.CAT_HOUSE.CAT_ATTR:GetValue(attrId)
                local currValue = self:getCatModel():getAttrNum(attrId)
                local needValue = checkint(attrValue)
                if currValue < needValue then
                    table.insert(attrDescrList, string.fmt(__('_name_不足_num_'), {_name_ = tostring(attrConf.name), _num_ = needValue}))
                end

                if not leadToDisease and currValue - needValue < CatHouseUtils.ATTR_LEAD_TO_DISEASE_LIMIT then
                    leadToDisease = true
                end

            end
            if #attrDescrList > 0 then
                becauseDescr = table.concat(attrDescrList, ',')
                studyEnable  = false
            end
        end
    end
    if isShowTips and not studyEnable then
        app.uiMgr:ShowInformationTips(string.fmt(__('_because_，不能学习'), {_because_ = becauseDescr}))
    end
    return studyEnable, leadToDisease
end


-------------------------------------------------
-- handler

function CatModuleCatGrowMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function CatModuleCatGrowMediator:onClickStudyBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local studyConf      = CONF.CAT_HOUSE.CAT_STUDY:GetValue(self:getSelectedPostgraduateId())
    local maxAge         = CatHouseUtils.CAT_PARAM_FUNCS:AGE_MAX()
    local leftAgeSeconds = self:getCatModel():getNextAgeLeftSeconds()

    if self:getCatModel():getAge() == CatHouseUtils.CAT_YOUTH_AGE_NUM and checkint(studyConf.duration) > leftAgeSeconds  then
        local ageConf = CONF.CAT_HOUSE.CAT_AGE:GetValue(self:getCatModel():getAge() + 1)
        app.uiMgr:ShowInformationTips(string.fmt(__("猫咪即将进入_name_, 当前剩余时间无法完成学习"), {_name_ = tostring(ageConf.name)}))
    else
        local isStudyEnable, leadToDisease = self:checkStudyEnable(self:getSelectedPostgraduateId(), true)
        if isStudyEnable then
            local callback = function()
                self:SendSignal(POST.HOUSE_CAT_STUDY_BEGAN.cmdName, {playerCatId = self:getPlayerCatId(), studyId = self:getSelectedPostgraduateId()})
            end
            if leadToDisease then
                app.uiMgr:AddCommonTipDialog({
                    text     = string.fmt(__("本次_name_可能会导致疾病的产生, 是否继续"), {_name_ = __("学习")}),
                    callback = callback,
                })
            else
                callback()
            end
        end   
    end
end


function CatModuleCatGrowMediator:onClickPostgraduateTypeBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local postgradutateType = checkint(sender:getTag())
    if IS_POSTGRADUATE_OPEN[postgradutateType](self:getCatModel()) then
        sender:setChecked(true)
        self:setSelectedPostgraduateType(postgradutateType)
    else
        sender:setChecked(false)
        app.uiMgr:ShowInformationTips(__("功能暂未解锁"))
    end
end


function CatModuleCatGrowMediator:onClickPostgraduateCellBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:setSelectedPostgraduateId(sender:getTag())
end


function CatModuleCatGrowMediator:onClickWorkingBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local isWorkEnable, leadToDisease = self:checkWorkEnable(self:getSelectedPostgraduateId(), true)
    if isWorkEnable then
        local callback = function()
            self:SendSignal(POST.HOUSE_CAT_WORK_BEGAN.cmdName, {playerCatId = self:getPlayerCatId(), workId = self:getSelectedPostgraduateId()})
        end
        if leadToDisease then
            app.uiMgr:AddCommonTipDialog({
                text     = string.fmt(__("本次_name_可能会导致疾病的产生, 是否继续"), {_name_ = __("工作")}),
                callback = callback,
            })
        else
            callback()
        end
    end
end


function CatModuleCatGrowMediator:onClickPromoteBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local workId       = self:getSelectedPostgraduateId()
    local workConfs    = CONF.CAT_HOUSE.CAT_WORK:GetValue(workId)
    local careerId     = checkint(workConfs.careerId)
    local careerLvl    = self:getCatModel():getCareerLevel(careerId)
    if careerLvl >= CatHouseUtils.CAT_PARAM_FUNCS.CAREER_LEVEL_MAX() then
        app.uiMgr:ShowInformationTips(__("已达到最大职业等级"))
    else
        local confirmCB = function()
            self:SendSignal(POST.HOUSE_CAT_CAREER_UP.cmdName, {playerCatId = self:getPlayerCatId(), careerId = careerId})
        end
        local promotePopup = require('Game.views.catModule.CatModulePromotePopup').new({careerId = careerId, catUuid = self:getCatUuid(), confirmCB = confirmCB})
        app.uiMgr:GetCurrentScene():AddDialog(promotePopup)
    end
end

return CatModuleCatGrowMediator
