local Anniversary20SweepView     = require('Game.views.anniversary20.Anniversary20SweepView')
local Anniversary20SweepMediator = class('Anniversary20SweepMediator', mvc.Mediator)


function Anniversary20SweepMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'Anniversary20SweepMediator', viewComponent)
end


function Anniversary20SweepMediator:Initial(key)
    self.super.Initial(self, key)
    self.isControllable_ = true

    -- create view
    self.viewNode_ = Anniversary20SweepView.new()
    self:SetViewComponent(self:getViewNode())

    local scene = app.uiMgr:GetCurrentScene()
    scene:AddDialog(self:getViewNode())

    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBlockBtnHandler_), false)
    self:getViewData().levelTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.sweepBtn, handler(self, self.onClickExploreSweepButtonHandler_))
    end)
    for _, chapterBtn in ipairs(self:getViewData().chapterBtns) do
        chapterBtn:setOnClickScriptHandler(handler(self, self.onClickChapterBtnHandler_))
    end

    -- init views
    self:initEntranceStatus_()
end


function Anniversary20SweepMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function Anniversary20SweepMediator:OnRegist()
    regPost(POST.ANNIV2020_EXPLORE_SWEEP)
end


function Anniversary20SweepMediator:OnUnRegist()
    unregPost(POST.ANNIV2020_EXPLORE_SWEEP)
end


function Anniversary20SweepMediator:InterestSignals()
    return {
        POST.ANNIV2020_EXPLORE_SWEEP.sglName,
    }
end


function Anniversary20SweepMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.ANNIV2020_EXPLORE_SWEEP.sglName then
        -- 更新消耗
        CommonUtils.DrawRewards({
            { goodsId = app.anniv2020Mgr:getHpGoodsId(), num = -self._selectedSweepCellConsume}
        })
        
        -- draw rewards
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = data.rewards})
    end
end


-------------------------------------------------------------------
-- public

function Anniversary20SweepMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------------------------
-- set/get
function Anniversary20SweepMediator:getViewData()
    return self:getViewNode():getViewData()
end
function Anniversary20SweepMediator:getViewNode()
    return self.viewNode_
end


function Anniversary20SweepMediator:getSelectedChapterId()
    return checkint(self.selectedChapterId_)
end
function Anniversary20SweepMediator:setSelectedChapterId(chapterId)
    self.selectedChapterId_ = chapterId
    self:getViewNode():setSelectedTabIndex(chapterId)

    local sweepChapterConfs = app.anniv2020Mgr:getExploreSweepConfsAt(self:getSelectedChapterId())
    self:getViewNode():setSweepConfs(sweepChapterConfs)
end


--------------------------------------------------------------------------------
-- private

function Anniversary20SweepMediator:initEntranceStatus_()
    -- select default 1
    self:setSelectedChapterId(1)
end


--------------------------------------------------------------------------------
-- handler

function Anniversary20SweepMediator:onClickBlockBtnHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function Anniversary20SweepMediator:onClickChapterBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    sender:setChecked(true)

    local targetChapterId = checkint(sender:getTag())
    if self:getSelectedChapterId() ~= targetChapterId then
        self:setSelectedChapterId(targetChapterId)
    end
end


function Anniversary20SweepMediator:onClickExploreSweepButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local cellIndex  = checkint(sender:getTag())
    local sweepConfs = app.anniv2020Mgr:getExploreSweepConfsAt(self:getSelectedChapterId())
    local sweepConf  = checktable(sweepConfs[cellIndex])

    local hpAmount = app.goodsMgr:getGoodsNum(app.anniv2020Mgr:getHpGoodsId())
    if hpAmount < checkint(sweepConf.consumeNum) then
        local goodsName = GoodsUtils.GetGoodsNameById(app.anniv2020Mgr:getHpGoodsId())
        app.uiMgr:ShowInformationTips(string.fmt(__('_name_不足'), {_name_ = goodsName}))
        return
    end

    self._selectedSweepCellConsume = checkint(sweepConf.consumeNum)
    self:SendSignal(POST.ANNIV2020_EXPLORE_SWEEP.cmdName, {sweepId = checkint(sweepConf.id)})
end


return Anniversary20SweepMediator
