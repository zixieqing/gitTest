--[[
 * author : panmeng
 * descpt : 猫咪详情界面
]]
local CatModuleCatInfoView     = require('Game.views.catModule.CatModuleCatInfoView')
local CatModuleCatInfoMediator = class('CatModuleCatInfoMediator', mvc.Mediator)

function CatModuleCatInfoMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatModuleCatInfoMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

local LIGTH_ANIM_TAG = CatModuleCatInfoView.LIGHT_ANIM_TAG

-------------------------------------------------
-- inheritance

function CatModuleCatInfoMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    local initArgs       = checktable(self.ctorArgs_)
    local initCatUuid    = initArgs.catUuid
    self.closeCallback_  = initArgs.closeCB
    self.isControllable_ = true

    -- create view
    self.viewNode_ = CatModuleCatInfoView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    ui.bindClick(self:getViewData().lifeBtn, handler(self, self.onClickLifeButtonHandler_))
    ui.bindClick(self:getViewData().studyBtn, handler(self, self.onClickStudyBtnHandler_))
    ui.bindClick(self:getViewData().matchBtn, handler(self, self.onClickMatchBtnHandler_))
    ui.bindClick(self:getViewData().fileBtn, handler(self, self.onClickFileBtnHandler_))
    ui.bindClick(self:getViewData().achieveBtn, handler(self, self.onClickAchieveBtnHandler_))
    ui.bindClick(self:getViewData().releaseBtn, handler(self, self.onClickReleaseBtnHandler_))
    ui.bindClick(self:getViewData().rebirthBtn, handler(self, self.onClickRebirthBtnHandler_))
    ui.bindClick(self:getViewData().nameBtn, handler(self, self.onCkickNameBtnHandler_))
    ui.bindClick(self:getViewData().infoBtn, handler(self, self.onClickInfoBtnHandler_))
    ui.bindClick(self:getViewData().titleBtn, handler(self, self.onClickTitleButtonHandler_))
    ui.bindClick(self:getViewData().guideBtn, handler(self, self.onClickGuideButtonHandler_))

    -- update views
    self:setCatUuid(initCatUuid)

    -- update guide
    if not GuideUtils.IsGuiding() and isGuideOpened('catModule') then
        self:openGuideView_()
    end
end


function CatModuleCatInfoMediator:CleanupView()
    if self:getViewNode() and self:getViewNode().stateTimeUpdate ~= nil then
        self:getViewNode().stateTimeUpdate:stop()
    end

    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function CatModuleCatInfoMediator:OnRegist()
    regPost(POST.HOUSE_CAT_RENAME)
    regPost(POST.HOUSE_CAT_REBIRTH)
    regPost(POST.HOUSE_CAT_REBORN)
    regPost(POST.HOUSE_CAT_FREE)
    regPost(POST.HOUSE_CAT_WORK_DONE)
    regPost(POST.HOUSE_CAT_STUDY_DONE)

end


function CatModuleCatInfoMediator:OnUnRegist()
    unregPost(POST.HOUSE_CAT_RENAME)
    unregPost(POST.HOUSE_CAT_REBIRTH)
    unregPost(POST.HOUSE_CAT_REBORN)
    unregPost(POST.HOUSE_CAT_FREE)
    unregPost(POST.HOUSE_CAT_WORK_DONE)
    unregPost(POST.HOUSE_CAT_STUDY_DONE)
end


function CatModuleCatInfoMediator:InterestSignals()
    return {
        POST.HOUSE_CAT_RENAME.sglName,
        POST.HOUSE_CAT_REBIRTH.sglName,
        POST.HOUSE_CAT_REBORN.sglName,
        POST.HOUSE_CAT_FREE.sglName,
        POST.HOUSE_CAT_WORK_DONE.sglName,
        POST.HOUSE_CAT_STUDY_DONE.sglName,
        SGL.CAT_MODULE_CAT_REFRESH_UPDATE,
        SGL.CAT_MODULE_CAT_LIFE_ACTION_START,
        SGL.CAT_MODEL_UPDATE_AGE,
        SGL.CAT_MODEL_UPDATE_ATTR_NUM,
        SGL.CAT_MODEL_UPDATE_ABILITY_NUM,
        SGL.CAT_MODULE_CAT_STATE_REFRESH,
        SGL.CAT_MODEL_APPEND_STATE,
        SGL.CAT_MODEL_REMOVE_STATE,
        SGL.CAT_MODEL_UPDATE_ALIVE,
        SGL.CAT_MODULE_CAT_PLAY_REFUSE_ANIM,
    }
end
function CatModuleCatInfoMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -- 猫咪改名
    if name == POST.HOUSE_CAT_RENAME.sglName then
        if data.requestData.playerCatId == self:getPlayerCatId() then
            -- update goods
            if self:getCatModel():isRenamed() then
                local consumeGoods = {}
                for consumeIndex, consumeData in ipairs(CatHouseUtils.CAT_PARAM_FUNCS.RENAME_CONSUME()) do
                    consumeGoods[consumeIndex] = {goodsId = consumeData.goodsId, num = checkint(consumeData.num) * -1}
                end
                app.goodsMgr:DrawRewards(consumeGoods)
            end

            -- update model
            local newName = tostring(data.requestData.name)
            self:getCatModel():setName(newName)
            self:getCatModel():setRenamed(true)
            -- update view
            self:getViewNode():updateNameView(newName)
        end

    -- 猫咪回归
    elseif name == POST.HOUSE_CAT_REBIRTH.sglName then
        -- update goods
        app.goodsMgr:DrawRewards(GoodsUtils.GetMultipCostList(CatHouseUtils.CAT_PARAM_FUNCS.REBIRTH_CONSUME()))

        -- update data
        self:getCatModel():setRebirth(true)
        self:getCatModel():setGeneration(1)

        -- update view
        self:getViewNode():updateAlgebraView(self:getCatModel())
        self:getViewNode():updateAllAttrData(self:getCatModel())
        self:getViewNode():playLigthAnimation(LIGTH_ANIM_TAG.REBIRTH_DONE, function()
            local attrIndex = 1
            for _, attrConf in pairs(CONF.CAT_HOUSE.CAT_ATTR:GetAll()) do
                local attrAdd = checkint(attrConf.rebirthMax) - checkint(attrConf.max)
                if attrAdd > 0 then
                    local descr = string.fmt(__("_name_ +_value_"), {_name_ = tostring(attrConf.name), _value_ = attrAdd})
                    local attrLabel = CatModuleCatInfoView.CreateFadeLabel(descr, 0.2 * (attrIndex - 1))
                    self:getViewNode():addList(attrLabel):alignTo(nil, ui.cc, {offsetY = 100})
                end
                attrIndex = attrIndex + 1
            end
        end)

    -- 猫咪重生
    elseif name == POST.HOUSE_CAT_REBORN.sglName then
        -- update reborn time
        self:getCatModel():initRebornTimeStamp()

        -- update goods
        app.goodsMgr:DrawRewards(GoodsUtils.GetMultipCostList(CatHouseUtils.CAT_PARAM_FUNCS.REBORN_CONSUME()))

        -- update data
        self:getCatModel():resetPhysicalStatus()
        self:getViewNode():resetStateNodeLayer()

        -- reset syc attr time
        for _, attrModel in pairs(self:getCatModel():getAllAttrModel()) do
            attrModel:setUpdateTimestamp(os.time())
        end
        -- reset attrs
        for attrId, value in pairs(CatHouseUtils.CAT_PARAM_FUNCS.REBORN_ATTR()) do
            self:getCatModel():setAttrNum(attrId, value)
        end

        -- update view
        self:getViewNode():setCatIsDie(self:getCatModel())
        self:getViewNode():updateAllAttrData(self:getCatModel())

    -- 猫咪放生
    elseif name == POST.HOUSE_CAT_FREE.sglName then
        -- update data
        local isAlive = self:getCatModel():isAlive()
        app.catHouseMgr:setCatModel(self:getCatUuid(), nil)

        -- update view
        self.isControllable_ = false
        local stateAmimTag   = isAlive and CatHouseUtils.CAT_STATE_ANIM_TAG.RELEASE_DONE or CatHouseUtils.CAT_STATE_ANIM_TAG.DEAD_DONE
        local stateAmimPopup = require('Game.views.catModule.CatModuleStatePopup').new({animTag = stateAmimTag, endCB = function()
            if isAlive then
                self:getViewNode():showReleaseCatView()
            else
                self:getViewNode():showBuriedCatview()
            end
            self.isControllable_ = true
        end})
        app.uiMgr:GetCurrentScene():AddDialog(stateAmimPopup)

    -- 刷新猫咪数据
    elseif name == SGL.CAT_MODULE_CAT_REFRESH_UPDATE then
        self:getViewNode():updateStateView(self:getCatModel())
        if self:getViewNode().ageDetailView then
            self:getViewNode().ageDetailView.refreshAgeTime(self:getCatModel():getAge(), self:getCatModel():getNextAgeLeftSeconds())
        end

        if self:getCatModel():getStudyingId() > 0 and self:getCatModel():getStudyLeftSeconds() <= 0 then
            self:SendSignal(POST.HOUSE_CAT_STUDY_DONE.cmdName, {playerCatId = self:getPlayerCatId()})
        elseif self:getCatModel():getWorkingId() > 0 and self:getCatModel():getWorkLeftSeconds() <= 0 then
            self:SendSignal(POST.HOUSE_CAT_WORK_DONE.cmdName, {playerCatId = self:getPlayerCatId()})
        end


    -- 刷新猫咪年龄
    elseif name == SGL.CAT_MODEL_UPDATE_AGE then
        if data.catUuid == self:getCatUuid() then
            self:getViewNode():updateAgeView(self:getCatModel())
            self:getViewNode():updateYouthView(self:getCatModel():getAge() <= CatHouseUtils.CAT_YOUTH_AGE_NUM)

            if self:getViewNode().ageDetailView then
                self:getViewNode().ageDetailView.refreshAgeView(self:getCatModel():getAge(), self:getCatModel():getNextAgeLeftSeconds())
            end
        end

    
    -- 猫咪生活交互
    elseif name == SGL.CAT_MODULE_CAT_LIFE_ACTION_START then
        self.isControllable_ = false
        self:playLifeAction(data)


    -- 刷新属性
    elseif name == SGL.CAT_MODEL_UPDATE_ATTR_NUM then
        if data.catUuid == self:getCatUuid() then
            self:getViewNode():updateAttrDataAt(self:getCatModel(), data.attrId)
        end


    -- 刷新能力
    elseif name == SGL.CAT_MODEL_UPDATE_ABILITY_NUM then
        if data.catUuid == self:getCatUuid() then
            self:getViewNode():updateAbilityDataAt(self:getCatModel(), data.abilityId)
        end


    -- 增加新状态
    elseif name == SGL.CAT_MODEL_APPEND_STATE then
        if data.catUuid == self:getCatUuid() then
            self:addStateNode(data.stateId)
            self:getViewData().diseaseImg:setVisible(self:getCatModel():isSicked())
        end


    -- 移除旧状态
    elseif name == SGL.CAT_MODEL_REMOVE_STATE then
        if data.catUuid == self:getCatUuid() then
            self:removeStateNode(data.stateId)
            self:getViewData().diseaseImg:setVisible(self:getCatModel():isSicked())
        end

    
    -- 学习结束
    elseif name == POST.HOUSE_CAT_STUDY_DONE.sglName then
        -- update ability
        local deltaAbilityMap = {}
        for abilityId, abilityValue in pairs(data.ability or {}) do
            deltaAbilityMap[checkint(abilityId)] = checkint(abilityValue) - self:getCatModel():getAbility(abilityId)
            self:getCatModel():setAbility(abilityId, abilityValue)
        end

        -- update study data
        local studyId = self:getCatModel():getStudyingId()
        self:getCatModel():setStudyingId(0)

        -- update view
        self.isControllable_ = false
        local stateAmimPopup = require('Game.views.catModule.CatModuleStatePopup').new({animTag = CatHouseUtils.CAT_STATE_ANIM_TAG.STUDY_DONE, endCB = function()
            local studyAccountPopup = require('Game.views.catModule.CatModuleStudySuccessPopup').new({deltaAbilityMap = deltaAbilityMap, catUuid = self:getCatUuid(), studyId = studyId, catAge = self:getCatModel():getAge()})
            app.uiMgr:GetCurrentScene():AddDialog(studyAccountPopup)
            self.isControllable_ = true
        end})
        app.uiMgr:GetCurrentScene():AddDialog(stateAmimPopup)


    -- 工作结束
    elseif name == POST.HOUSE_CAT_WORK_DONE.sglName then
        local workConfs = CONF.CAT_HOUSE.CAT_WORK:GetValue(self:getCatModel():getWorkingId())
        local careerId  = checkint(workConfs.careerId)
        local rewardsId = checkint(workConfs.rewardGoodsId)
        local careerLvl = self:getCatModel():getCareerLevel(careerId)
        local workConf  = workConfs.careerLevel[tostring(careerLvl)]

        -- update work data
        local incomeRate = self:getCatModel():getWorkIncomeRate()
        self:getCatModel():addCareerExp(careerId, math.floor(workConfs.mainExp * (1 + incomeRate/100)))
        
        self:getCatModel():setWorkingId(0)

        -- add rewards
        CommonUtils.DrawRewards(data.rewards)

        -- update view
        local normalRewardNum = 0
        for rewardIndex, rewardData in pairs(data.rewards) do
            if checkint(rewardData.goodsId) == rewardsId then
                normalRewardNum = checkint(workConf.rewardNum)
                rewardData.num  = rewardData.num - normalRewardNum
                if rewardData.num <= 0 then
                    normalRewardNum = normalRewardNum + rewardData.num
                    table.remove(data.rewards, rewardIndex)
                end
                break
            end
        end
   
        self.isControllable_ = false
        local stateAmimPopup = require('Game.views.catModule.CatModuleStatePopup').new({animTag = CatHouseUtils.CAT_STATE_ANIM_TAG.WORK_DONE, endCB = function()
            if normalRewardNum == 0 and #data.rewards <= 0 then
               app.uiMgr:AddCommonTipNewDialog({
                   text     = __("工作结算"),
                   descr    = __("本周奖励次数已超上限，且无额外奖励获得"),
                   isOnlyOK = true
               })
            else
               local normalRewards = {
                   {goodsId = rewardsId, num = normalRewardNum},
               }
               local workAccountPopup = require('Game.views.catModule.CatModuleWorkRewardPopup').new({
                   normalRewards = normalRewardNum > 0 and normalRewards or {},
                   extraRewards  = data.rewards,
               })
               app.uiMgr:GetCurrentScene():AddDialog(workAccountPopup)
            end
            self.isControllable_ = true
        end})
        app.uiMgr:GetCurrentScene():AddDialog(stateAmimPopup)


    -- 更新存活状态
    elseif name == SGL.CAT_MODEL_UPDATE_ALIVE then
        if data.catUuid == self:getCatUuid() then
            self:getViewNode():setCatIsDie(self:getCatModel())
        end


    -- 拒绝动画
    elseif name == SGL.CAT_MODULE_CAT_PLAY_REFUSE_ANIM then
        if self:getViewNode().catSpineNode_ then
            self:getViewNode().catSpineNode_:doRefuseAnime()
        end

    end
end


-------------------------------------------------
-- get / set

---@return CatModuleCatInfoView
function CatModuleCatInfoMediator:getViewNode()
    return  self.viewNode_
end
function CatModuleCatInfoMediator:getViewData()
    return self:getViewNode():getViewData()
end


-- cat uuid
function CatModuleCatInfoMediator:getCatUuid()
    return self.catUuid_
end
function CatModuleCatInfoMediator:setCatUuid(catUuid)
    self.catUuid_  = catUuid
    self.catModel_ = app.catHouseMgr:getCatModel(self:getCatUuid())
    self:updateViewState_()
    app.catHouseMgr:setHouseCatUuid(catUuid)
    -- debug use
    if self:getViewData().openDebugAttrFunc then
        self:getViewData().openDebugAttrFunc(catUuid)
    end
end


---@return HouseCatModel
function CatModuleCatInfoMediator:getCatModel()
    return self.catModel_
end

function CatModuleCatInfoMediator:getPlayerCatId()
    return self:getCatModel():getPlayerCatId()
end


-------------------------------------------------
-- public

function CatModuleCatInfoMediator:close()
    app.catHouseMgr:setHouseCatUuid()
    app:UnRegsitMediator(self:GetMediatorName())
    if self.closeCallback_ then
        self.closeCallback_()
    end
end

function CatModuleCatInfoMediator:addStateNode(stateId)
    self:getViewNode():addStateNode(stateId, handler(self, self.onClickStateNodeBtnHandler_))
end

function CatModuleCatInfoMediator:removeStateNode(stateId)
    self:getViewNode():removeStateNode(stateId)
end


-------------------------------------------------
-- private

function CatModuleCatInfoMediator:updateViewState_()
    self:getViewNode():setCatInfo(self:getCatModel())
    for stateId, _ in pairs(self:getCatModel():getPhysicalStatusMap()) do
        self:addStateNode(stateId)
    end
end


function CatModuleCatInfoMediator:playLifeAction(data)
    self:getViewNode():playLifeAnimation(data, function()
        app:DispatchObservers(SGL.CAT_MODULE_CAT_LIFE_ACTION_END)
        self.isControllable_ = true
    end)
end


function CatModuleCatInfoMediator:openGuideView_()
    local guideNode = require('common.GuideNode').new({tmodule = 'catModule'})
    display.commonUIParams(guideNode, { po = display.center})
    app.uiMgr:GetCurrentScene():AddDialog(guideNode)
end


-------------------------------------------------
-- handler

function CatModuleCatInfoMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end
    app:DispatchObservers(SGL.CAT_MODEL_CAT_INFO_VIEW_CLOSE)
    self:close()
end


function CatModuleCatInfoMediator:onClickInfoBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():showAgeGradeView(self:getCatModel():getAge(), self:getCatModel():getNextAgeLeftSeconds())
end


function CatModuleCatInfoMediator:onCkickNameBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:AddChangeNamePopup({
        renameCB  = function(newName) 
            self:SendSignal(POST.HOUSE_CAT_RENAME.cmdName, {playerCatId = self:getPlayerCatId(), name = newName})
        end,
        renameConsume = CatHouseUtils.CAT_PARAM_FUNCS.RENAME_CONSUME(),
        isFreeCharge  = not self:getCatModel():isRenamed(),
        preName       = self:getCatModel():getName(), 
    })
end


function CatModuleCatInfoMediator:onClickRebirthBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if not self:getCatModel():isAlive() then
        local rebornConsumes = CatHouseUtils.CAT_PARAM_FUNCS.REBORN_CONSUME()
        app.uiMgr:AddCommonTipDialog({
            text     = __("是否复活猫咪"),
            descr    = string.fmt(__("猫咪已死亡, 复活所需:_goodsInfo_"), {_goodsInfo_ = GoodsUtils.GetMultipleConsumeStr(rebornConsumes)}),
            callback = function()
                if GoodsUtils.CheckMultipCosts(rebornConsumes, true) then
                    self:SendSignal(POST.HOUSE_CAT_REBORN.cmdName, {playerCatId = self:getPlayerCatId()})
                end
            end,
        })
    else
        local catModel = self:getCatModel()
        if not catModel:isDoNothing() then
            app.uiMgr:ShowInformationTips(__("猫咪正忙"))
            return
        end

        local rebirthPopup = require('Game.views.catModule.CatModuleRebirthPopup').new({
            confirmCB = function()
                if GoodsUtils.CheckMultipCosts(CatHouseUtils.CAT_PARAM_FUNCS.REBIRTH_CONSUME(), true) then
                    self:SendSignal(POST.HOUSE_CAT_REBIRTH.cmdName, {playerCatId = self:getPlayerCatId()})
                end
            end
        })
        app.uiMgr:GetCurrentScene():AddDialog(rebirthPopup)
    end
end


function CatModuleCatInfoMediator:onClickReleaseBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if app.catHouseMgr:isPlaceCatInHouse(self:getCatUuid()) then
        app.uiMgr:ShowInformationTips(__("请先将猫咪从小屋中撤下,再进行此行为"))
        return
    end
    if CatHouseUtils.IsCatEquipped(self:getCatUuid()) then
        app.uiMgr:ShowInformationTips(__("请先将猫咪从天选位撤下,再进行此行为"))
        return
    end

    local commonTipParams = {}
    if not self:getCatModel():isAlive() then
        commonTipParams = {
            text     = __("是否埋葬猫咪"),
            descr    = __("猫咪已死亡,埋葬后将从列表中删除"),
            callback = function()
                if table.nums(app.catHouseMgr:getCatsModelMap()) <= 1 then
                    app.uiMgr:ShowInformationTips(__("这是您的唯一一只猫咪,埋葬后您就是没猫的人了~"))
                else
                    self:SendSignal(POST.HOUSE_CAT_FREE.cmdName, {playerCatId = self:getPlayerCatId()})
                end
            end,
        }
    else

        local catModel = self:getCatModel()
        if not catModel:isDoNothing() then
            app.uiMgr:ShowInformationTips(__("猫咪正忙"))
            return
        end

        commonTipParams = {
            text     = __("是否确认放生？"),
            callback = function()
                if table.nums(app.catHouseMgr:getCatsModelMap()) <= 1 then
                    app.uiMgr:ShowInformationTips(__("这是您的唯一一只猫咪,放生后您就是没猫的人了~"))
                else
                    self:SendSignal(POST.HOUSE_CAT_FREE.cmdName, {playerCatId = self:getPlayerCatId()})
                end
            end,
        }
    end
    app.uiMgr:AddCommonTipDialog(commonTipParams)
end


function CatModuleCatInfoMediator:onClickAchieveBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if self:getCatModel():isUnlockAchievement() and self:getCatModel():getAchievementId() > 0 then
        local achieveMdt = require('Game.mediator.catModule.CatModuleAchievementMediator').new({
            achieveId = self:getCatModel():getAchievementId(),
            hasDraw   = self:getCatModel():isAchievementDrawn(),
            catUuid   = self:getCatUuid(),
        })
        app:RegistMediator(achieveMdt)

    else
        app.uiMgr:ShowInformationTips(__("猫咪暂未解锁成就任务"))
    end
end


function CatModuleCatInfoMediator:onClickFileBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local fileMdt = require('Game.mediator.catModule.CatModuleRecordMediator').new({catUuid = self:getCatUuid()})
    app:RegistMediator(fileMdt)
end


function CatModuleCatInfoMediator:onClickMatchBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    -- local catModel = self:getCatModel()
    -- if not catModel:isDoNothing() then
    --     app.uiMgr:ShowInformationTips(__("猫咪正忙"))
    --     return
    -- end

    local mediator = require("Game.mediator.catHouse.CatHouseBreedMediator").new({catUuid = self:getCatUuid()})
	app:RegistMediator(mediator)
end


function CatModuleCatInfoMediator:onClickStudyBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local studyMdt = require('Game.mediator.catModule.CatModuleCatGrowMediator').new({catUuid = self:getCatUuid()})
    app:RegistMediator(studyMdt)
end


function CatModuleCatInfoMediator:onClickLifeButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    -- local catModel = self:getCatModel()
    -- if not catModel:isDoNothing() then
    --     app.uiMgr:ShowInformationTips(__("猫咪正忙"))
    --     return
    -- end

    local lifeMdt = require('Game.mediator.catModule.CatModuleCatLifeMediator').new({catUuid = self:getCatUuid()})
    app:RegistMediator(lifeMdt)
end


function CatModuleCatInfoMediator:onClickStateNodeBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():showStateDetailView(sender, self:getCatModel():getPhysicalStateDeathTimestamp(sender.stateId), self:getCatModel():getPhysicalStateLeftSeconds(sender.stateId))
end


function CatModuleCatInfoMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.CAT_HOUSE)]})
end


function CatModuleCatInfoMediator:onClickGuideButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:openGuideView_()
end


return CatModuleCatInfoMediator
