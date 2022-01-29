--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 挂机游戏 中介者
]]
local Anniversary20HangView     = require('Game.views.anniversary20.Anniversary20HangView')
local Anniversary20HangMediator = class('Anniversary20HangMediator', mvc.Mediator)

function Anniversary20HangMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'Anniversary20HangMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

local HANG_STATUE = Anniversary20HangView.HANG_STATUE

-------------------------------------------------
-- inheritance

function Anniversary20HangMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true
    self.selectedMaterialMap_ = {}

    -- create view
    self.viewNode_ = Anniversary20HangView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddGameLayer(self:getViewNode())

    -- add listener
    self.hangRefreshClocker_ = app.timerMgr.CreateClocker(handler(self, self.onHangRefreshUpdateHandler_))
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    ui.bindClick(self:getViewData().titleBtn, handler(self, self.onClickTitleButtonHandler_))
    ui.bindClick(self:getViewData().hangConfirmBtn, handler(self, self.onClickHangConfirmBtnHandler_))
    ui.bindClick(self:getViewData().hangRewardLayer, handler(self, self.onClickHangRewardButtonHandler_))
    ui.bindClick(self:getViewData().hangMaterialsSubBlockLayer, handler(self, self.onClickHangBlockButtonHandler_))
    ui.bindClick(self:getViewData().collectRewardBtn, handler(self, self.onClickCollectRewardBtnHandler_))

    for _, plateCell in ipairs(self:getViewData().plateCells) do
        ui.bindClick(plateCell, handler(self, self.onClickPlateBtnHandler_), false)
    end
    for _, collectRewardCell in ipairs(self:getViewData().collectRewardSubCells) do
		collectRewardCell:setOnClickScriptHandler(handler(self, self.onClickSubCollectRewardBtnHandler_))
    end
    for _, goodCell in ipairs(self:getViewData().hangMaterialsGoodCells) do
        ui.bindClick(goodCell, handler(self, self.onClickHangMaterialsGoodBtnHandler_), false)
    end
    for _, goodCell in ipairs(self:getViewData().hangMaterialsSubGoodCells) do
		goodCell:setOnClickScriptHandler(handler(self, self.onClickHangMaterialsSubGoodBtnHandler_))
    end

    -- update views
    local localDefine = LOCAL.ANNIV2020.IS_ALREADY_PLAY_OPEN_ANIM()
    if not localDefine:Load() then
        localDefine:Save(true)
        self.isControllable_ = false
        self:getViewNode():showUI(true, function() self.isControllable_ = true end)
    else
        self:getViewNode():showUI()
    end
end


function Anniversary20HangMediator:CleanupView()
    self.hangRefreshClocker_:stop()

    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function Anniversary20HangMediator:OnRegist()
    regPost(POST.ANNIV2020_HANG_HOME)
    regPost(POST.ANNIV2020_HANG_DRAW_FINISH)
    regPost(POST.ANNIV2020_HANG_DRAW_COLLECT)
    regPost(POST.ANNIV2020_HANG_HANGING)
    
    self:SendSignal(POST.ANNIV2020_HANG_HOME.cmdName)
end


function Anniversary20HangMediator:OnUnRegist()
    unregPost(POST.ANNIV2020_HANG_HOME)
    unregPost(POST.ANNIV2020_HANG_DRAW_FINISH)
    unregPost(POST.ANNIV2020_HANG_DRAW_COLLECT)
    unregPost(POST.ANNIV2020_HANG_HANGING)
end


function Anniversary20HangMediator:InterestSignals()
    return {
        POST.ANNIV2020_HANG_HOME.sglName,
        POST.ANNIV2020_HANG_DRAW_FINISH.sglName,
        POST.ANNIV2020_HANG_DRAW_COLLECT.sglName,
        POST.ANNIV2020_HANG_HANGING.sglName
    }
end


function Anniversary20HangMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.ANNIV2020_HANG_DRAW_COLLECT.sglName then
        -- add collectId
        app.anniv2020Mgr:addHangDrawnCollectId(self.curDrawCollectId)

        -- update collectCell
        self:getViewNode():updateCollectReward(self.curDrawCollectId)

        -- draw rewards
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = data.rewards})


    elseif name == POST.ANNIV2020_HANG_DRAW_FINISH.sglName then
        local formulaId = checkint(data.formulaId)
        if formulaId > 0 then
            app.anniv2020Mgr:addHangUnlockFormulaId(formulaId)
        end

        self.isControllable_ = false
        self:getViewNode():updateHangState(HANG_STATUE.HANG_END, function()
            -- check unlock plate
            if formulaId > 0 then
                self:getViewNode():updatePlateCell(formulaId)
                self:getViewNode():updateCollectProgress()
            end

            -- update status
            self:getViewNode():updateHangState(HANG_STATUE.NONE)

            -- draw rewards
            app.uiMgr:AddDialog('common.RewardPopup', {rewards = data.rewards})

            self.isControllable_ = true
        end)


    elseif name == POST.ANNIV2020_HANG_HANGING.sglName then
        -- const materials
        local materials = app.anniv2020Mgr:getHangingMaterials()
        CommonUtils.DrawRewards({
            {goodsId = materials[1], num = -1},
            {goodsId = materials[2], num = -1},
            {goodsId = materials[3], num = -1},
        })

        -- update hangingTime
        app.anniv2020Mgr:setHangingLeftSeconds(data.hangLeftSeconds)

        -- to hanging status
        self.isControllable_ = false
        self:getViewNode():updateHangState(HANG_STATUE.HANG_START, function()
            self:resetSelectedMaterials_()
            self:startHangingCountdown_()

            self:getViewNode():updateHangState(HANG_STATUE.HANGING)
            self.isControllable_ = true
        end)


    elseif name == POST.ANNIV2020_HANG_HOME.sglName then
        self:initHomeData_(data)

    end
end


-------------------------------------------------
-- get / set

function Anniversary20HangMediator:getViewNode()
    return  self.viewNode_
end
function Anniversary20HangMediator:getViewData()
    return self:getViewNode():getViewData()
end


function Anniversary20HangMediator:getSelectedMaterialMap()
    return self.selectedMaterialMap_
end
function Anniversary20HangMediator:resetSelectedMaterials_()
    self.selectedMaterialMap_ = {}
    self:getViewNode():updateSelectedMaterials()
end


function Anniversary20HangMediator:getSelectedMaterialByType(materialsType)
    return self.selectedMaterialMap_[checkint(materialsType)]
end
function Anniversary20HangMediator:setSelectedHangMaterial(materialsType, goodId)
    self.selectedMaterialMap_[checkint(materialsType)] = checkint(goodId)
    self:getViewNode():updateSelectedMaterial(materialsType, goodId)
    self:getViewNode():updateHangMaterialsSubLayerVisible(false)
end


function Anniversary20HangMediator:getSelectedMaterialsStr()
    if next(self:getSelectedMaterialMap()) == nil then
        return ""
    end
    return table.concat(self:getSelectedMaterialMap(), ',')
end


function Anniversary20HangMediator:getSelectedMaterialsNum()
    if next(self:getSelectedMaterialMap()) == nil then
        return 0
    end
    local materialNum = 0
    for _, _ in pairs(self:getSelectedMaterialMap()) do
        materialNum = materialNum + 1
    end
    return materialNum
end


-------------------------------------------------
-- public

function Anniversary20HangMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function Anniversary20HangMediator:initHomeData_(homeData)
    app.anniv2020Mgr:updateHangHomeData(homeData)

    -- udpate views status
    self:refreshPage_()
end


function Anniversary20HangMediator:refreshPage_()
    -- updateHanging
    local hangingMaterials = app.anniv2020Mgr:getHangingMaterials()
    if hangingMaterials and next(hangingMaterials) ~= nil then

        -- 是否挂机的倒计时已经结束了
        local leftSeconds = app.anniv2020Mgr:getHangingTimestamp() - os.time()
        if leftSeconds <= 0 then
            self:getViewNode():updateHangState(HANG_STATUE.HANG_REWARD)
        else
            self:getViewNode():updateHangState(HANG_STATUE.HANGING)
            self:startHangingCountdown_()
        end
    else
        self:getViewNode():updateHangState(HANG_STATUE.NONE)
    end
    
    -- updateCenter
    self:getViewNode():updatePlateCells()

    -- updateCollect
    self:getViewNode():updateCollectRewards()
    self:getViewNode():updateCollectProgress()
end



function Anniversary20HangMediator:startHangingCountdown_()
    self.hangRefreshClocker_:start()
end


function Anniversary20HangMediator:onHangRefreshUpdateHandler_()
    local curTime = app.anniv2020Mgr:getHangingTimestamp() - os.time()

    if curTime <= 0 then
        self.hangRefreshClocker_:stop()
        self:getViewNode():updateHangState(HANG_STATUE.HANG_REWARD)

    else
        self:getViewNode():refershHangingLeftTime(curTime)
    end
end


-------------------------------------------------
-- handler

function Anniversary20HangMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function Anniversary20HangMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA.ANNIV20_HANG})
end


function Anniversary20HangMediator:onClickHangConfirmBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if self:getSelectedMaterialsNum() < 3 then
        app.uiMgr:ShowInformationTips(__("挂机材料不足"))
        return
    end

    if app.anniv2020Mgr:isClosed() then
        app.uiMgr:ShowInformationTips(__('当前活动已结束'))
        return
    end

    -- 加入通用弹窗
    local hangingTimeText = CommonUtils.getTimeFormatByType(app.anniv2020Mgr:getHangCountdownTime(), 3)
    local hangingTipsNode = require('common.NewCommonTip').new({
        text     =  __('是否确认挂机?'),
        extra    =  string.fmt(__('挂机时长_time_'), {_time_ = hangingTimeText}),
        callback = function (sender)
            self:getViewNode():updateHangMaterialsSubLayerVisible(false)
            app.anniv2020Mgr:setHangingMaterials(self.selectedMaterialMap_)
            self:SendSignal(POST.ANNIV2020_HANG_HANGING.cmdName, {materials = self:getSelectedMaterialsStr()})
        end
    })
    hangingTipsNode:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(hangingTipsNode)
end


function Anniversary20HangMediator:onClickHangMaterialsGoodBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self.curOpenMaterialType = checkint(sender:getTag())
    self:getViewNode():setHangMaterialsSubLayerTypeAndShow(self.curOpenMaterialType)
end


function Anniversary20HangMediator:onClickHangMaterialsSubGoodBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local goodNum = app.goodsMgr:getGoodsNum(sender.goodId)
    if goodNum <= 0 then
        app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {_name_ = GoodsUtils.GetGoodsNameById(sender.goodId)}))
    else
        self:setSelectedHangMaterial(self.curOpenMaterialType, sender.goodId)
    end
end


function Anniversary20HangMediator:onClickCollectRewardBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():updateCollectRewardLayerStatue()
end


function Anniversary20HangMediator:onClickSubCollectRewardBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local collectId = checkint(sender:getTag())
    local hangRewardConfs = CONF.ANNIV2020.HANG_REWARDS:GetValue(1)
    local rewardConf = checktable(hangRewardConfs.collects[collectId])
    
    if app.anniv2020Mgr:hasHangDrawnCollectId(collectId) or checkint(rewardConf.targetNum) > app.anniv2020Mgr:getHangUnlockFormulaIdNum() then
        app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
    else
        self.curDrawCollectId = collectId
        self:SendSignal(POST.ANNIV2020_HANG_DRAW_COLLECT.cmdName, {collectId = collectId})
    end
end


function Anniversary20HangMediator:onClickPlateBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local formulaId = checkint(sender:getTag())
    if not app.anniv2020Mgr:hasHangUnlockFormulaId(formulaId) then
        app.uiMgr:ShowInformationTips(__("请先解锁该配方"))
        return
    end

    local formulaConf = checktable(CONF.ANNIV2020.HANG_FORMULA:GetValue(formulaId))
    local storyId = checkint(formulaConf.storyId)
    if app.anniv2020Mgr:isStoryUnlocked(storyId) then
        app.anniv2020Mgr:playStory(storyId)
    else
        app.anniv2020Mgr:toUnlockStory(storyId, function()
            app.anniv2020Mgr:playStory(storyId)
        end)
    end
end


function Anniversary20HangMediator:onClickHangRewardButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:SendSignal(POST.ANNIV2020_HANG_DRAW_FINISH.cmdName)
end


function Anniversary20HangMediator:onClickHangBlockButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewNode():updateHangMaterialsSubLayerVisible(false)
end


return Anniversary20HangMediator
