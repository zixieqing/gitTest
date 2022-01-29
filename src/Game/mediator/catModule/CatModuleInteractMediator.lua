--[[
 * author : panmeng
 * descpt : 猫咪互动控制器
]]
local CatModuleInteractView     = require('Game.views.catModule.CatModuleInteractView')
local CatModuleInteractMediator = class('CatModuleInteractMediator', mvc.Mediator)

function CatModuleInteractMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatModuleInteractMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function CatModuleInteractMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = CatModuleInteractView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    ui.bindClick(self:getViewData().feedBtn, handler(self, self.onClickFeedButtonHandler_))
    ui.bindClick(self:getViewData().playBtn, handler(self, self.onClickPlayButtonHandler_))
    ui.bindClick(self:getViewData().driverBtn, handler(self, self.onClickDriverBtnHandler_))

    -- set data
    self:setFriendCatData(self.ctorArgs_)
end


function CatModuleInteractMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function CatModuleInteractMediator:OnRegist()
    regPost(POST.HOUSE_CAT_FRIEND_PLAY)
    regPost(POST.HOUSE_CAT_FRIEND_AWAY)
end


function CatModuleInteractMediator:OnUnRegist()
    unregPost(POST.HOUSE_CAT_FRIEND_PLAY)
    unregPost(POST.HOUSE_CAT_FRIEND_AWAY)
end


function CatModuleInteractMediator:InterestSignals()
    return {
        POST.HOUSE_CAT_FRIEND_PLAY.sglName,
        POST.HOUSE_CAT_FRIEND_AWAY.sglName,
    }
end
function CatModuleInteractMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.HOUSE_CAT_FRIEND_PLAY.sglName then
        -- consume goods
        app.goodsMgr:DrawRewards(GoodsUtils.GetMultipCostList(CatHouseUtils.CAT_PARAM_FUNCS.LIKE_CONSUME()))

        -- refresh data
        if data.requestData.type == CatHouseUtils.CAT_FRIEND_INTERACT_ACTION.PLYA then
            self:setLeftPlayTimes(self:getLeftPlayTimes() - 1)
            if self:getViewData().catSpineNode then
                self.isControllable_ = false
                self:getViewData().catSpineNode:doPlayAnime(function()
                    self.isControllable_ = true
                    app.uiMgr:ShowInformationTips(string.fmt(__("玩耍成功,_name_很开心,增加了好感度"), {_name_ = self:getFriendCatName()}))
                end)
            end
        else
            self:setLeftFeedTimes(self:getLeftFeedTimes() - 1)
            if self:getViewData().catSpineNode then
                self.isControllable_ = false
                self:getViewData().catSpineNode:doFeedAnime(function()
                    self.isControllable_ = true
                    app.uiMgr:ShowInformationTips(string.fmt(__("喂食成功,_name_很开心,增加了好感度"), {_name_ = self:getFriendCatName()}))
                end)
            end
        end
        
        -- add favorability for each cat of mine
        for _, catModel in pairs(app.catHouseMgr:getCatsModelMap()) do
            if not catModel:isDisableLikeUpdate() then
                if catModel:hasLikeFriendCatData(self:getCatUuid()) then
                    catModel:addLikeFriendCatExp(self:getCatUuid(), catModel:getLikeExpAdd())
                else
                    local friendCatData = clone(self:getFriendCatData())
                    friendCatData.favorabilityExp = catModel:getLikeExpAdd()
                    catModel:addLikeRelationData(friendCatData)
                end
            end
        end

    elseif name == POST.HOUSE_CAT_FRIEND_AWAY.sglName then
        app.uiMgr:ShowInformationTips(string.fmt(__("_name_依依不舍的与您道别了"), {_name_ = self:getFriendCatName()}))
        app:DispatchObservers(SGL.CAT_MODULE_CAT_INTERACTION, {catUuid = self:getCatUuid(), type = CatHouseUtils.CAT_FRIEND_INTERACT_ACTION.DRIVE})
        self:close()

    end
end


-------------------------------------------------
-- get / set

function CatModuleInteractMediator:getViewNode()
    return self.viewNode_
end
function CatModuleInteractMediator:getViewData()
    return self:getViewNode():getViewData()
end


-- friendData
function CatModuleInteractMediator:setFriendCatData(friendCatData)
    self.friendCatData_ = checktable(friendCatData)
    self:updatePageView()
end
function CatModuleInteractMediator:getFriendCatData()
    return checktable(self.friendCatData_)
end
function CatModuleInteractMediator:getFriendCatName()
    return tostring(self:getFriendCatData().name)
end


-- leftFeedTimes
function CatModuleInteractMediator:getLeftFeedTimes()
    return checkint(self:getFriendCatData().leftFeedTimes)
end
function CatModuleInteractMediator:setLeftFeedTimes(feedTimes)
    self:getFriendCatData().leftFeedTimes = feedTimes
    -- app:DispatchObservers(SGL.CAT_MODULE_CAT_INTERACTION, {
    --     catUuid   = self:getCatUuid(),
    --     type      = CatHouseUtils.CAT_FRIEND_INTERACT_ACTION.FEED,
    --     feedTimes = self:getLeftFeedTimes()
    -- })
end


-- leftPlayTimes
function CatModuleInteractMediator:getLeftPlayTimes()
    return checkint(self:getFriendCatData().leftPlayTimes)
end
function CatModuleInteractMediator:setLeftPlayTimes(playTimes)
    self:getFriendCatData().leftPlayTimes = playTimes
    -- app:DispatchObservers(SGL.CAT_MODULE_CAT_INTERACTION, {
    --     catUuid   = self:getCatUuid(),
    --     type      = CatHouseUtils.CAT_FRIEND_INTERACT_ACTION.PLYA,
    --     playTimes = self:getLeftPlayTimes()
    -- })
end


-- playerCatId
function CatModuleInteractMediator:getFriendCatId()
    return checkint(self:getFriendCatData().friendCatId)
end


-- friendId
function CatModuleInteractMediator:getFriendId()
    return checkint(self:getFriendCatData().friendId)
end


-- catUuid
function CatModuleInteractMediator:getCatUuid()
    return self:getFriendCatData().friendCatUuid
end


-------------------------------------------------
-- public

function CatModuleInteractMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function CatModuleInteractMediator:updatePageView()
    self:getViewNode():updatePageView(self:getFriendCatData())
end

-------------------------------------------------
-- handler

function CatModuleInteractMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function CatModuleInteractMediator:onClickFeedButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if self:getLeftFeedTimes() <= 0 then
        app.uiMgr:ShowInformationTips(string.fmt(__("喂食失败,_name_已经很饱了"), {_name_ = self:getFriendCatName()}))
        if self:getViewData().catSpineNode then
            self:getViewData().catSpineNode:doRefuseAnime()
        end
        return
    end

    local callback = function()
        if GoodsUtils.CheckMultipCosts(CatHouseUtils.CAT_PARAM_FUNCS.LIKE_CONSUME(), true) then
            self:SendSignal(POST.HOUSE_CAT_FRIEND_PLAY.cmdName, {friendId = self:getFriendId(), friendCatId = self:getFriendCatId(), type = CatHouseUtils.CAT_FRIEND_INTERACT_ACTION.FEED})
        end
    end
    
    app.uiMgr:AddCommonTipDialog({
        text = string.fmt(__("是否花费_goodInfo_对_catName_喂食吗？"), {
            _goodInfo_ = GoodsUtils.GetMultipleConsumeStr(CatHouseUtils.CAT_PARAM_FUNCS.LIKE_CONSUME()),
            _catName_  = self:getFriendCatName(),
        }),
        callback = callback,
    })
end


function CatModuleInteractMediator:onClickPlayButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if self:getLeftPlayTimes() <= 0 then
        app.uiMgr:ShowInformationTips(string.fmt(__("玩耍失败,_name_已经很累了"), {_name_ = self:getFriendCatName()}))
        if self:getViewData().catSpineNode then
            self:getViewData().catSpineNode:doRefuseAnime()
        end
        return
    end

    local callback = function()
        if GoodsUtils.CheckMultipCosts(CatHouseUtils.CAT_PARAM_FUNCS.LIKE_CONSUME(), true) then
            self:SendSignal(POST.HOUSE_CAT_FRIEND_PLAY.cmdName, {friendId = self:getFriendId(), friendCatId = self:getFriendCatId(), type = CatHouseUtils.CAT_FRIEND_INTERACT_ACTION.PLYA})
        end
    end
    
    app.uiMgr:AddCommonTipDialog({
        text = string.fmt(__("是否花费_goodInfo_陪_catName_玩耍吗？"), {
            _goodInfo_ = GoodsUtils.GetMultipleConsumeStr(CatHouseUtils.CAT_PARAM_FUNCS.LIKE_CONSUME()),
            _catName_  = self:getFriendCatName()
        }),
        callback = callback,
    })
end


function CatModuleInteractMediator:onClickDriverBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:AddCommonTipDialog({
        text     = string.fmt(__("是否驱逐_name_？"), {_name_ = self:getFriendCatName()}),
        callback = function()
            self:SendSignal(POST.HOUSE_CAT_FRIEND_AWAY.cmdName, {friendId = self:getFriendId(), friendCatId = self:getFriendCatId()})
        end,
    })
end


return CatModuleInteractMediator
