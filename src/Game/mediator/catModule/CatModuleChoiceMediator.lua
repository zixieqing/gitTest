--[[
 * author : panmeng
 * descpt : 选择猫咪界面
]]
local CatModuleChoiceView     = require('Game.views.catModule.CatModuleChoiceView')
local CatModuleChoiceMediator = class('CatModuleChoiceMediator', mvc.Mediator)

function CatModuleChoiceMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatModuleChoiceMediator', viewComponent)
end


-------------------------------------------------
-- life cycle
function CatModuleChoiceMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = CatModuleChoiceView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddGameLayer(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    -- ui.bindClick(self:getViewData().titleBtn, handler(self, self.onClickTitleButtonHandler_))
    ui.bindClick(self:getViewData().confirmBtn, handler(self, self.onClickConfirmButtonHandler_))
    for _, catCell in pairs(self:getViewData().arrCatCell) do
        ui.bindClick(catCell, handler(self, self.onClickCatCellButtonHandler_))
    end

    -- update views
    self:setSelectedCatId(3)

    self.isControllable_  = false
    local firstOpenDefine = LOCAL.CAT_HOUSE.IS_OPENED_CHOOSE_CAT()
    -- firstOpenDefine:Save(false)
	if firstOpenDefine:Load() then
        self:getViewNode():showUI(function()
            self.isControllable_ = true
        end)
    else
		local storyStage = require('Frame.Opera.OperaStage').new({id = checkint(1), path = string.format("conf/%s/house/catStory.json",i18n.getLang()), guide = true, cb = function(sender)
            firstOpenDefine:Save(true)
            self:getViewNode():showUI(function()
                self.isControllable_ = true
            end)
        end})
        storyStage:setPosition(display.center)
        sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
    end
end


function CatModuleChoiceMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
    if self.catPreviewLayer_ and not tolua.isnull(self.catPreviewLayer_) then
        self.catPreviewLayer_:removeFromParent()
        self.catPreviewLayer_ = nil
    end
end


function CatModuleChoiceMediator:OnRegist()
    regPost(POST.HOUSE_CAT_INIT)
end


function CatModuleChoiceMediator:OnUnRegist()
    unregPost(POST.HOUSE_CAT_INIT)
end


function CatModuleChoiceMediator:InterestSignals()
    return {
        POST.HOUSE_CAT_INIT.sglName,
        POST.HOUSE_CAT_HOME.sglName,
    }
end
function CatModuleChoiceMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.HOUSE_CAT_INIT.sglName then
        -- init catsData
        local catData = data.cat
        app.catHouseMgr:setCatHomeData({
            cats  = {catData},
            genes = catData.gene or {},
        })

        -- set inited
        app.catHouseMgr:setInitedCatModule(true)

        -- add rewards
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = data.rewards, closeCallback = function()
            self:onAdoptCatCallback_(CatHouseUtils.BuildCatUuid(app.gameMgr:GetPlayerId(), catData.playerCatId))
        end})


    elseif name == POST.HOUSE_CAT_HOME.sglName then
        -- 切换场景
        self:TransitionalSceneAction(app.uiMgr:GetCurrentScene(), display.center)

    end
end


-------------------------------------------------
-- get / set

function CatModuleChoiceMediator:getViewNode()
    return self.viewNode_
end
function CatModuleChoiceMediator:getViewData()
    return self:getViewNode():getViewData()
end


function CatModuleChoiceMediator:getSelectedCatId()
    return checkint(self.selectedCatId_)
end
function CatModuleChoiceMediator:setSelectedCatId(catId)
    self.selectedCatId_ = checkint(catId)
    self:getViewNode():updateSelectedState(self:getSelectedCatId())
end


-------------------------------------------------
-- public

function CatModuleChoiceMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function CatModuleChoiceMediator:onAdoptCatCallback_(catUuid)
    self:getViewData().centerLayer:setVisible(false)
    self:getViewData().topLayer:setVisible(false)

    self.catPreviewLayer_ = require('Game.views.catModule.cat.CatPreviewPopup').new({
        isRetain      = true,
        catUuid       = catUuid,
        closeCallback = function()
            self:SendSignal(POST.HOUSE_CAT_HOME.cmdName)
        end,
    })
    app.uiMgr:GetCurrentScene():AddGameLayer(self.catPreviewLayer_)
end


function CatModuleChoiceMediator:TransitionalSceneAction(scene, targetPos)
	self.isControllable_ = false
    
    local prevContentSnapshot = self:createSnapshot_(scene, targetPos)
	app.uiMgr:GetCurrentScene():AddDialog(prevContentSnapshot)
	prevContentSnapshot:setPosition(display.center)
    prevContentSnapshot:setPercentage(100)
	prevContentSnapshot:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(0.05),
            cc.EaseCubicActionIn:create(cc.ProgressTo:create(0.6, 0.01)),
            cc.CallFunc:create(function()
                self.isControllable_ = true
                self:close()
            end),
            cc.RemoveSelf:create()
		)
    )

    local mediator = require("Game.mediator.catModule.CatModuleMainMediator").new()
    app:RegistMediator(mediator)
end
function CatModuleChoiceMediator:createSnapshot_(viewObj, midPos)
	-- create the second render texture for outScene
    local texture = cc.RenderTexture:create(display.width, display.height)
    texture:setPosition(display.cx, display.cy)
    texture:setAnchorPoint(display.CENTER)

    -- render outScene to its texturebuffer
    texture:clear(0, 0, 0, 0)
    texture:begin()
    viewObj:visit()
    texture:endToLua()

    local middle = cc.ProgressTimer:create(texture:getSprite())
    middle:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    -- Setup for a bar starting from the bottom since the midpoint is 0 for the y
    middle:setMidpoint(cc.p(midPos.x / display.width, (display.height - midPos.y) / display.height))
    -- middle:setMidpoint(display.CENTER)
    -- Setup for a vertical bar since the bar change rate is 0 for x meaning no horizontal change
    middle:setBarChangeRate(cc.p(1, 1))
    middle:setPosition(display.cx, display.cy)
    return middle
end


-------------------------------------------------
-- handler

function CatModuleChoiceMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function CatModuleChoiceMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA.TTGAME_ALBUM})
end


function CatModuleChoiceMediator:onClickCatCellButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local catId = sender:getTag()
    self:setSelectedCatId(catId)
end


function CatModuleChoiceMediator:onClickConfirmButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:AddNewCommonTipDialog({text = __("是否领养此猫咪？"), extra = __("确定后不可重新选择\n(猫咪只有种族与外观之间的差异)"), callback = function()
        self:SendSignal(POST.HOUSE_CAT_INIT.cmdName, {catId = self:getSelectedCatId()})
    end})
end


return CatModuleChoiceMediator
