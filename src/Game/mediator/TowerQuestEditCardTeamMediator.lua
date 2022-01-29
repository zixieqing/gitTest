--[[
 * author : kaishiqi
 * descpt : 爬塔 - 编队编辑界面中介者
]]
local TowerModelFactory              = require('Game.models.TowerQuestModelFactory')
local TowerQuestModel                = TowerModelFactory.getModelType('TowerQuest')
local UnitContractModel              = TowerModelFactory.getModelType('UnitContract')
local TowerConfigParser              = require('Game.Datas.Parser.TowerConfigParser')
local TowerQuestEditCardTeamView     = require('Game.views.TowerQuestEditCardTeamView')
local TowerQuestContractMediator     = require('Game.mediator.TowerQuestContractMediator')
local TowerQuestEditCardTeamMediator = class('TowerQuestEditCardTeamMediator', mvc.Mediator)

local DRAG_CHECK_GAP = 10

function TowerQuestEditCardTeamMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TowerQuestEditCardTeamMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function TowerQuestEditCardTeamMediator:Initial(key)
    self.super.Initial(self, key)

    local isIgnoreShowView     = self.ctorArgs_.isIgnoreShowView == true
    self.towerUnitId_          = checkint(self.ctorArgs_.towerUnitId)
    self.cardLibrary_          = checktable(self.ctorArgs_.cardLibrary)
    self.contractIdList_       = checktable(self.ctorArgs_.contractIdList)
    self.chestRewardsMap_      = checktable(self.ctorArgs_.chestRewardsMap)
    self.selectedCardList_     = checktable(self.ctorArgs_.selectedCardList)
    self.selectedSkillList_    = checktable(self.ctorArgs_.selectedSkillList)
    self.selectedContractList_ = checktable(self.ctorArgs_.selectedContractList)

    self.towerHomeMdt_        = self:GetFacade():RetrieveMediator('TowerQuestHomeMediator')
    self.isControllable_      = true
    self.teamCardGuidList_    = {}
    self.teamCardSpineMap_    = {}
    self.libraryCardCellList_ = {}

    -- create view
    local homeScene = self.towerHomeMdt_:getHomeScene()
    self.editView_  = TowerQuestEditCardTeamView.new()
	homeScene:AddDialog(self.editView_)

    local contractArgs = {
        isEditMode           = true,
        towerUnitId          = self.towerUnitId_,
        contractIdList       = self.contractIdList_,
        chestRewardsMap      = self.chestRewardsMap_,
        selectedContractList = self.selectedContractList_
    }
    self.contractMdt_ = TowerQuestContractMediator.new(contractArgs)
    self:GetFacade():RegistMediator(self.contractMdt_)
    self.contractMdt_:GetViewComponent():setAnchorPoint(display.RIGHT_CENTER)
    self.contractMdt_:GetViewComponent():setPosition(display.SAFE_R + 2, display.cy + 28)
    self.editView_:getViewData().contractLayer:addChild(self.contractMdt_:GetViewComponent())
    self.editView_:getViewData().contractView = self.contractMdt_:GetViewComponent()
    self.editView_:getViewData().contractView:setScaleY(0)

    -- init view
    local editViewData = self.editView_:getViewData()
    display.commonUIParams(editViewData.backBtn, {cb = handler(self, self.onClickBackButtonHandler_)})
    display.commonUIParams(editViewData.confirmBtn, {cb = handler(self, self.onClickConfirmButtonHandler_)})
    for i, skillFrame in ipairs(editViewData.pSkillSlotFrameList) do
        display.commonUIParams(skillFrame, {cb = handler(self, self.onClickPSkillFrameButtonHandler_)})
    end

    local touchListener = cc.EventListenerTouchOneByOne:create()
    touchListener:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    touchListener:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    touchListener:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    self.editView_:getEventDispatcher():addEventListenerWithSceneGraphPriority(touchListener, self.editView_)

    -- update view
    self:reloadSkills_()

    -- show ui
    self.isControllable_ = false
    if not isIgnoreShowView then
        self:showUI()
    end
end


function TowerQuestEditCardTeamMediator:CleanupView()
    if self.editView_ then
        local homeScene = self.towerHomeMdt_:getHomeScene()
        homeScene:RemoveDialog(self.editView_)
        self.editView_ = nil
    end
    if self.contractMdt_ then
        self.contractMdt_:close()
        self.contractMdt_ = nil
    end
end


function TowerQuestEditCardTeamMediator:OnRegist()
    regPost(POST.TOWER_UNIT_SET_CONFIG)
end
function TowerQuestEditCardTeamMediator:OnUnRegist()
    unregPost(POST.TOWER_UNIT_SET_CONFIG)
end


function TowerQuestEditCardTeamMediator:InterestSignals()
    return {
        POST.TOWER_UNIT_SET_CONFIG.sglName,
        SGL.TOWER_QUEST_SELECT_CONTRACT,
        'CHANGE_PLAYER_SKILL',
    }
end
function TowerQuestEditCardTeamMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.TOWER_UNIT_SET_CONFIG.sglName then
        local sglArgs = {
            selectedCardList     = self.teamCardGuidList_,
            selectedSkillList    = self.selectedSkillList_,
            selectedContractList = self.selectedContractList_,
        }
        self:GetFacade():DispatchObservers(SGL.TOWER_QUEST_SET_CARD_TEAM, sglArgs)
        self:close()


    elseif name == SGL.TOWER_QUEST_SELECT_CONTRACT then
        -- update selected contract
        self.selectedContractList_ = checktable(data.contractIdList)

        -- update libraray card status
        for i,v in ipairs(self.cardLibrary_) do
            self:updateLibraryCardCell_(i)
        end

        -- update team card statsu
        for i, cardGuid in ipairs(self.teamCardGuidList_) do
            if checkint(cardGuid) > 0 then
                self:updateTeamSiteStatus_(i)
            end
        end

        -- update skill status
        self:reloadSkills_()


    elseif name == 'CHANGE_PLAYER_SKILL' then
        -- update selected skill
        self.selectedSkillList_ = string.split(data.requestData.skills, ',')
        if data.responseCallback then
            data.responseCallback({
                skill = self.selectedSkillList_
            })
        end

        -- update skill status
        self:reloadSkills_()
    
    end
end


-------------------------------------------------
-- public method

function TowerQuestEditCardTeamMediator:close()
    self.isControllable_ = false
    self.editView_:hideView(function()
        self:GetFacade():UnRegsitMediator(self:GetMediatorName())
    end)
end


function TowerQuestEditCardTeamMediator:showUI()
    self.editView_:showView(
        function()
            self:reloadLibraryCards_()
        end,
        function()
            local cardSpaineActList = {}
            for i = 1, TowerQuestModel.BATTLE_CARD_MAX do
                table.insert(cardSpaineActList, cc.DelayTime:create(0.15))
                table.insert(cardSpaineActList, cc.CallFunc:create(function()
                    self:appendTeamCardAt_(i, self.selectedCardList_[i])
                end))
            end
            table.insert(cardSpaineActList, cc.CallFunc:create(function()
                self.isControllable_ = true
            end))

            local editViewData = self.editView_:getViewData()
            editViewData.teamCardLayer:runAction(cc.Sequence:create(cardSpaineActList))
        end
    )
end


-------------------------------------------------
-- private method

function TowerQuestEditCardTeamMediator:isConformContractCard_(cardGuid)
    local isConform, missCause = true, ''
    if checkint(cardGuid) == 0 then return isConform, missCause end

    local gameMgr  = self:GetFacade():GetManager('GameManager')
    local cardMgr  = self:GetFacade():GetManager('CardManager')
    local cardData = gameMgr:GetCardDataById(cardGuid) or {}
    local cardConf = CommonUtils.GetConfig('cards', 'card', cardData.cardId)
    local cardType = checkint(cardConf.career)

    for i, contractId in ipairs(self.selectedContractList_) do
        local contractConf = checktable(CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.CONTRACT ,'tower'))[tostring(contractId)] or {}
        local contractType = checkint(contractConf.type)
        local contractId   = checkint(contractConf.id)
        
        if contractType == UnitContractModel.TYPE_CARD then
            if contractId == UnitContractModel.ID_CARD_DONT_DEF then
                isConform = cardType ~= CARD_FILTER_TYPE_DEF
                missCause = isConform and '' or __('禁用防御系')

            elseif contractId == UnitContractModel.ID_CARD_DONT_ATK then
                isConform = cardType ~= CARD_FILTER_TYPE_NEAR_ATK
                missCause = isConform and '' or __('禁用力量系')

            elseif contractId == UnitContractModel.ID_CARD_DONT_MAG then
                isConform = cardType ~= CARD_FILTER_TYPE_REMOTE_ATK
                missCause = isConform and '' or __('禁用魔法系')
                
            elseif contractId == UnitContractModel.ID_CARD_DONT_SUP then
                isConform = cardType ~= CARD_FILTER_TYPE_DOCTOR
                missCause = isConform and '' or __('禁用辅助系')
                
            end
        end

        if not isConform then
            return isConform, missCause
        end
    end
    return isConform, missCause
end
function TowerQuestEditCardTeamMediator:isConformContractSkill_(skillId)
    local isConform, missCause = true, ''
    if checkint(skillId) == 0 then return isConform, missCause end

    local gameMgr   = self:GetFacade():GetManager('GameManager')
    local skillConf = CommonUtils.GetConfig('player', 'skill', skillId) or {}
    local skillType = checkint(skillConf.skillKind)

    for i, contractId in ipairs(self.selectedContractList_) do
        local contractConf = CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.CONTRACT ,'tower')[tostring(contractId)] or {}
        local contractType = checkint(contractConf.type)
        local contractId   = checkint(contractConf.id)
        
        if contractType == UnitContractModel.TYPE_TALENT then
            if contractId == UnitContractModel.ID_TALENT_DONT_DAM then
                isConform = skillType ~= TalentType.DAMAGE
                missCause = isConform and '' or __('禁用伤害系')

            elseif contractId == UnitContractModel.ID_TALENT_DONT_SUP then
                isConform = skillType ~= TalentType.SUPPORT
                missCause = isConform and '' or __('禁用辅助系')

            elseif contractId == UnitContractModel.ID_TALENT_DONT_CON then
                isConform = skillType ~= TalentType.CONTROL
                missCause = isConform and '' or __('禁用控制系')
                
            end
        end

        if not isConform then
            return isConform, missCause
        end
    end
    return isConform, missCause
end


function TowerQuestEditCardTeamMediator:reloadSkills_()
    local editViewData = self.editView_:getViewData()
    editViewData.pSkillIconLayer:removeAllChildren()

    for i, skillId in ipairs(self.selectedSkillList_) do
        local skillFrame = editViewData.pSkillSlotFrameList[i]
        local skillNode  = checkint(skillId) > 0 and require('common.PlayerSkillNode').new({id = skillId}) or nil
        if skillFrame and skillNode then
            skillNode:setPosition(skillFrame:getPosition())
            skillNode:setCascadeColorEnabled(true)
            skillNode:setEnabled(false)
            editViewData.pSkillIconLayer:addChild(skillNode)

            if self:isConformContractSkill_(skillId) then
                skillNode:setColor(cc.c3b(255,255,255))
            else
                skillNode:setColor(cc.c3b(100,100,100))
            end
        end
    end
end


function TowerQuestEditCardTeamMediator:reloadLibraryCards_()
    local gameManager  = self:GetFacade():GetManager('GameManager')
    local cardManager  = self:GetFacade():GetManager('CardManager')
    local editViewData = self.editView_:getViewData()
    local libraryCards = self.cardLibrary_ or {}

    -- clean libraray cards
    self.libraryCardCellList_ = {}
    editViewData.libraryCardLayer:removeAllChildren()

    -- create library cards
    for libraryCellIndex, cardGuid in ipairs(libraryCards) do
        local libraryFrame = editViewData.libraryCardFrameList[libraryCellIndex]
        local cardFramePos = libraryFrame and cc.p(libraryFrame:getPosition()) or cc.p(0,0)
        local cellViewData = self.editView_:createLibraryCardCell()
        editViewData.libraryCardLayer:addChild(cellViewData.view)
        cellViewData.view:setPosition(cardFramePos)
        display.commonUIParams(cellViewData.clickArea, {cb = handler(self, self.onClickLibraryCardCellHandler_)})
        self.libraryCardCellList_[libraryCellIndex] = cellViewData

        -- init cell
        cellViewData.clickArea:setTag(libraryCellIndex)

        -- delay create, optimize showing speed
        local createHeadFunc = function(cellViewData, cardGuid)        
            local cardCellSize = cellViewData.view:getContentSize()
            local cardHeadNode = require('common.CardHeadNode').new({id = cardGuid, showActionState = false})
            cardHeadNode:setPosition(cc.p(cardCellSize.width/2, cardCellSize.height/2))
            cardHeadNode:setAnchorPoint(display.CENTER)
            cardHeadNode:setScale(0.65)
            cellViewData.headLayer:addChild(cardHeadNode)
            cellViewData.cardHeadNode = cardHeadNode
        end

        -- update cell
        self:updateLibraryCardCell_(libraryCellIndex)

        cellViewData.view:setScale(0)
        cellViewData.view:runAction(cc.Sequence:create({
            cc.DelayTime:create((libraryCellIndex-1) * 0.05),
            cc.CallFunc:create(function()
                createHeadFunc(cellViewData, cardGuid)
            end),
            cc.ScaleTo:create(0.1, 1)
        }))
    end
end
function TowerQuestEditCardTeamMediator:updateLibraryCardCell_(libraryCardIndex)
    local cellViewData = self.libraryCardCellList_[libraryCardIndex]
    if cellViewData then
        local libraryCards    = self.cardLibrary_ or {}
        local libraryCardGuid = checkint(libraryCards[libraryCardIndex])
        
        if libraryCardGuid > 0 then
            cellViewData.selectLayer:setVisible(self:checkTeamCardIndex_(libraryCardGuid) > 0)

            local isConform, missCause = self:isConformContractCard_(libraryCardGuid)
            if isConform then
                cellViewData.warningLayer:setVisible(false)
            else
                cellViewData.warningLayer:setVisible(true)
                display.commonLabelParams(cellViewData.warningBar, {text = missCause})
            end

        else
            cellViewData.selectLayer:setVisible(false)
            cellViewData.warningLayer:setVisible(false)
        end
    end
end


function TowerQuestEditCardTeamMediator:checkTeamCardIndex_(cardGuid)
    local cardIndex = 0
    for i, v in ipairs(self.teamCardGuidList_) do
        if checkint(v) == checkint(cardGuid) then
            cardIndex = i
            break
        end
    end
    return cardIndex
end
function TowerQuestEditCardTeamMediator:appendTeamCardAt_(teamIndex, cardGuid, fromWorldPos)
    -- append for data
    self.teamCardGuidList_[teamIndex] = checkint(cardGuid) > 0 and cardGuid or ''

    -- append for cell
    self:appendTeamSpineAt_(teamIndex, cardGuid, fromWorldPos)

    -- update other views
    self:updateAllTeamCSkillActivateStatus_()

    for i, cellViewData in ipairs(self.libraryCardCellList_) do
        local libraryCellIndex = cellViewData.clickArea:getTag()
        local libraryCardGuid  = self.cardLibrary_[libraryCellIndex]
        if checkint(libraryCardGuid) == checkint(cardGuid) then
            self:updateLibraryCardCell_(libraryCellIndex)
            break
        end
    end
end
function TowerQuestEditCardTeamMediator:removeTeamCardAt_(teamIndex)
    -- remove for data
    local cardGuid = self.teamCardGuidList_[teamIndex]
    self.teamCardGuidList_[teamIndex] = ''

    -- remove for cell
    self:removeTeamSpineAt_(teamIndex, cardGuid)

    -- update other views
    self:updateAllTeamCSkillActivateStatus_()

    for i, cellViewData in ipairs(self.libraryCardCellList_) do
        local libraryCellIndex = cellViewData.clickArea:getTag()
        local libraryCardGuid  = self.cardLibrary_[libraryCellIndex]
        if checkint(libraryCardGuid) == checkint(cardGuid) then
            self:updateLibraryCardCell_(libraryCellIndex)
            break
        end
    end
end
function TowerQuestEditCardTeamMediator:cleanAllSelectedCard_()
    for i = 1, TowerQuestModel.BATTLE_CARD_MAX do
        self:removeTeamCardAt_(i)
    end
end


function TowerQuestEditCardTeamMediator:appendTeamSpineAt_(teamCardIndex, cardGuid, fromWorldPos)
    -- create spine
    local editViewData  = self.editView_:getViewData()
    local gameManager   = self:GetFacade():GetManager('GameManager')
    local cardManager   = self:GetFacade():GetManager('CardManager')
    local teamCardData  = gameManager:GetCardDataById(cardGuid) or {}
    local teamCardSite  = editViewData.teamCardSiteList[teamCardIndex]
    local teamCardSpine = checkint(teamCardData.cardId) > 0 and self.editView_:createCardSpineView(teamCardData.cardId) or nil

    -- init cell
    if teamCardSite and teamCardSpine then
        local cardSpinePos = cc.p(teamCardSite.view:getPosition())
        self.teamCardSpineMap_[tostring(teamCardIndex)] = teamCardSpine
        editViewData.teamCardLayer:addChild(teamCardSpine.view)
        teamCardSpine.view:setPosition(cardSpinePos)

        -- update cSkill
        local cSkillId = checkint(CardUtils.GetCardConnectSkillId(teamCardData.cardId))
        teamCardSpine.skillLayer:removeAllChildren()
        if cSkillId > 0 then
            local skillIconPath = CommonUtils.GetSkillIconPath(CardUtils.GetSkillConfigBySkillId(cSkillId).id)
            teamCardSpine.skillLayer:addChild(display.newImageView(_res(skillIconPath), 0, 0, {scale = 0.2}))
        end

        -- show action
        if fromWorldPos then
            if self.appendingTeamCardHeadNode_ and self.appendingTeamCardHeadNode_:getParent() then
                self.appendingTeamCardHeadNode_:removeFromParent()
                self.appendingTeamCardHeadNode_ = nil
            end
            
            local fromeNodePos = editViewData.teamCardLayer:convertToNodeSpace(fromWorldPos)
            local cardHeadNode = require('common.CardHeadNode').new({id = cardGuid, showActionState = false})
            cardHeadNode:setAnchorPoint(display.CENTER)
            cardHeadNode:setPosition(fromeNodePos)
            cardHeadNode:setEnabled(false)
            cardHeadNode:setScale(0.65)
            editViewData.teamCardLayer:addChild(cardHeadNode)
            self.appendingTeamCardHeadNode_ = cardHeadNode

            local actionTime = 0.2
            teamCardSpine.view:setScaleX(0)
            teamCardSpine.view:runAction(cc.Sequence:create({
                cc.Spawn:create({
                    cc.TargetedAction:create(cardHeadNode, cc.MoveTo:create(actionTime, cc.p(cardSpinePos.x, cardSpinePos.y + 120))),
                    -- cc.TargetedAction:create(cardHeadNode, cc.ScaleTo:create(actionTime, 1)),
                }),
                cc.DelayTime:create(0.1),
                cc.TargetedAction:create(cardHeadNode, cc.ScaleTo:create(0.1, 0, 1)),
                cc.TargetedAction:create(cardHeadNode, cc.RemoveSelf:create()),
                cc.CallFunc:create(function()
                    self.appendingTeamCardHeadNode_ = nil
                    teamCardSite.siteLight:setVisible(false)
                    PlayAudioClip(AUDIOS.UI.ui_relic_cut.id)
                end),
                cc.ScaleTo:create(0.04, 1),
                cc.CallFunc:create(function()
                    self:resortAllTeamSpineZorder_()
                end)
            }))

        else
            teamCardSpine.view:setScaleX(0.5)
            teamCardSpine.view:setScaleY(2)
            teamCardSpine.view:setOpacity(0)
            teamCardSpine.view:setPosition(cardSpinePos.x, display.height)

            teamCardSpine.view:runAction(cc.Sequence:create(
                cc.Sequence:create({
                    cc.FadeIn:create(0.15),
                    cc.MoveTo:create(0.15, cardSpinePos),
                }),
                cc.CallFunc:create(function()
                    PlayAudioClip(AUDIOS.UI.ui_relic_cut.id)
                end),
                cc.ScaleTo:create(0.08, 1.4, 0.6),
                cc.ScaleTo:create(0.08, 0.8, 1.1),
                cc.ScaleTo:create(0.04, 1.1, 0.9),
                cc.ScaleTo:create(0.04, 1),
                cc.CallFunc:create(function()
                    self:resortAllTeamSpineZorder_()
                end)
            ))
        end
    end

    -- update cell
    self:updateTeamSiteStatus_(teamCardIndex)

end
function TowerQuestEditCardTeamMediator:removeTeamSpineAt_(teamCardIndex, cardGuid)
    local editViewData  = self.editView_:getViewData()
    local teamCardSite  = editViewData.teamCardSiteList[teamCardIndex]
    local teamCardSpine = self.teamCardSpineMap_[tostring(teamCardIndex)]
    self.teamCardSpineMap_[tostring(teamCardIndex)] = nil

    if teamCardSite and teamCardSpine then
        if self.appendingTeamCardHeadNode_ and self.appendingTeamCardHeadNode_:getParent() then
            self.appendingTeamCardHeadNode_:removeFromParent()
            self.appendingTeamCardHeadNode_ = nil
        end

        -- do remove action
        local actionTime = 0.3
        teamCardSpine.view:stopAllActions()
        teamCardSpine.view:runAction(cc.Sequence:create({
            cc.Spawn:create({
                cc.MoveTo:create(actionTime, cc.p(teamCardSpine.view:getPositionX(), display.height)),
                cc.ScaleTo:create(actionTime, 0.2, 2),
                cc.FadeOut:create(actionTime)
            }),
            cc.CallFunc:create(function()
                teamCardSite.siteLight:setVisible(true)
            end),
            cc.RemoveSelf:create()
        }))

        -- update cell
        self:updateTeamSiteStatus_(teamCardIndex)
    end
end
function TowerQuestEditCardTeamMediator:updateTeamSiteStatus_(teamCardIndex)
    local editViewData  = self.editView_:getViewData()
    local teamCardSite  = editViewData.teamCardSiteList[teamCardIndex]
    local teamCardSpine = self.teamCardSpineMap_[tostring(teamCardIndex)]

    if teamCardSite and teamCardSpine then
        local hasSkill = #teamCardSpine.skillLayer:getChildren() > 0
        teamCardSpine.skillFrame:setVisible(hasSkill)

        if teamCardSpine.cardSpine then
            local teamCardGuid = checkint(self.teamCardGuidList_[teamCardIndex])
            local isConform, missCause = self:isConformContractCard_(teamCardGuid)
            if isConform then
                teamCardSpine.warningBar:setVisible(false)
                teamCardSpine.cardSpine:setColor(cc.c3b(255, 255, 255))
            else
                teamCardSpine.warningBar:setVisible(true)
                teamCardSpine.cardSpine:setColor(cc.c3b(100, 100, 100))
                display.commonLabelParams(teamCardSpine.warningBar, {text = missCause})
            end
        else
            teamCardSpine.warningBar:setVisible(false)
        end
    end
end
function TowerQuestEditCardTeamMediator:updateAllTeamCSkillActivateStatus_()
    local gameManager = self:GetFacade():GetManager('GameManager')
    local cardManager = self:GetFacade():GetManager('CardManager')

    local formationData = {}
    for i, cardGuid in ipairs(self.teamCardGuidList_) do
        if checkint(cardGuid) > 0 then
            local cardData = gameManager:GetCardDataById(cardGuid) or {}
            table.insert(formationData, {cardId = cardData.cardId, teamIndex = i})
        end
    end

    for i, v in ipairs(formationData) do
        local editViewData   = self.editView_:getViewData()
        local teamCardSite   = editViewData.teamCardSiteList[v.teamIndex]
        local teamCardSpine  = self.teamCardSpineMap_[tostring(v.teamIndex)]
        local isEnableCSkill = CardUtils.IsConnectSkillEnable(v.cardId, formationData) == true
        if teamCardSite and teamCardSpine then
            if isEnableCSkill then
                teamCardSpine.skillLayer:setColor(cc.c3b(255, 255, 255))
            else
                teamCardSpine.skillLayer:setColor(cc.c3b(100, 100, 100))
            end
        end
    end
end
function TowerQuestEditCardTeamMediator:resortAllTeamSpineZorder_()
    local teamCardSpineList = {}
    for teamIndex, cardSpine in pairs(self.teamCardSpineMap_) do
        table.insert(teamCardSpineList, cardSpine)
    end

    table.sort(teamCardSpineList, function(aCardSpine, bCardSpine)
        local aCardSpineX = checkint(aCardSpine.view:getPositionX())
        local aCardSpineY = checkint(aCardSpine.view:getPositionY())
        local bCardSpineX = checkint(bCardSpine.view:getPositionX())
        local bCardSpineY = checkint(bCardSpine.view:getPositionY())
        if aCardSpineY == bCardSpineY then
            return aCardSpineX < bCardSpineX
        else
            return aCardSpineY > bCardSpineY
        end
    end)

    for i, cardSpine in ipairs(teamCardSpineList) do
        cardSpine.view:setLocalZOrder(i)
    end
end


-------------------------------------------------
-- handler

function TowerQuestEditCardTeamMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function TowerQuestEditCardTeamMediator:onClickCleanButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:cleanAllSelectedCard_()
end


function TowerQuestEditCardTeamMediator:onClickConfirmButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    local uiMgr = self:GetFacade():GetManager('UIManager')

    -- check team card num
    local teamCardNum = 0
    for i, cardGuid in ipairs(self.teamCardGuidList_) do
        if checkint(cardGuid) > 0 then
            teamCardNum = teamCardNum + 1
        end
    end
    if teamCardNum < TowerQuestModel.BATTLE_CARD_MIN then
        uiMgr:ShowInformationTips(string.fmt(__('出战的飨灵不能少于_num_张'), {_num_ = TowerQuestModel.BATTLE_CARD_MIN}))
        return
    end

    -- check contract for card type
    local isAllCardTypeOk = true
    for i, cardGuid in ipairs(self.teamCardGuidList_) do
        isAllCardTypeOk = self:isConformContractCard_(cardGuid)
        if not isAllCardTypeOk then
            break
        end
    end
    if not isAllCardTypeOk then
        uiMgr:ShowInformationTips(__('队伍中存在不符合契约规则的飨灵'))
        return 
    end

    -- check Contract for skill type
    local isAllSkillTypeOk = true
    for i, skillId in ipairs(self.selectedSkillList_) do
        isAllSkillTypeOk = self:isConformContractSkill_(skillId)
        if not isAllSkillTypeOk then
            break
        end
    end
    if not isAllSkillTypeOk then
        uiMgr:ShowInformationTips(__('技能中存在不符合契约规则的技能'))
        return 
    end

    self.isControllable_ = false
    transition.execute(self.editView_, nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})

    -- save team config
    local cardsData = {}
    for i = 1, TowerQuestModel.BATTLE_CARD_MAX do
        local cardGuid = checkint(self.teamCardGuidList_[i])
        table.insert(cardsData, cardGuid > 0 and cardGuid or '')
    end
    local skillData = {}
    for i = 1, TowerQuestModel.BATTLE_SKILL_MAX do
        local skillId = checkint(self.selectedSkillList_[i])
        table.insert(skillData, skillId > 0 and skillId or '')
    end
    self:SendSignal(POST.TOWER_UNIT_SET_CONFIG.cmdName, {
        cards    = table.concat(cardsData, ','),
        skill    = table.concat(skillData, ','),
        contract = table.concat(self.selectedContractList_, ','),
    })
end


function TowerQuestEditCardTeamMediator:onClickLibraryCardCellHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    local clickCardIndex  = checkint(sender:getTag())
    local libraryCardGuid = checkint(self.cardLibrary_[clickCardIndex])

    -- add / remove library card
    local teamIndex = self:checkTeamCardIndex_(libraryCardGuid)
    if teamIndex > 0 then
        self:removeTeamCardAt_(teamIndex)

    else
        -- check empty team index
        local appendTeamIndex = 0
        for i = 1, TowerQuestModel.BATTLE_CARD_MAX do
            if checkint(self.teamCardGuidList_[i]) == 0 then
                appendTeamIndex = i
                break
            end
        end

        if appendTeamIndex > 0 then
            if self:isConformContractCard_(libraryCardGuid) then
                local senderCenterWorldPos = sender:convertToWorldSpace(cc.p(sender:getContentSize().width/2, sender:getContentSize().height/2))
                self:appendTeamCardAt_(appendTeamIndex, libraryCardGuid, senderCenterWorldPos)

            else
                local uiMgr = self:GetFacade():GetManager('UIManager')
                uiMgr:ShowInformationTips(__('该飨灵不符当前的合契约规则'))
            end

        else
            local uiMgr = self:GetFacade():GetManager('UIManager')
            uiMgr:ShowInformationTips(__('出战队伍已满员'))
        end
    end

    self.isControllable_ = false
    transition.execute(self.editView_, nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})
end


function TowerQuestEditCardTeamMediator:onClickPSkillFrameButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self.isControllable_ = false
    local skillIndex     = checkint(sender:getTag())
    local gameManager    = self:GetFacade():GetManager('GameManager')
    local allSkills      = self:convertPlayerSkillData_(gameManager:GetUserInfo().allSkill)
    local equipedSkills  = {}
	for i = 1, TowerQuestModel.BATTLE_SKILL_MAX do
        local skillId = checkint(self.selectedSkillList_[i])
		equipedSkills[tostring(i)] = {skillId = skillId}
	end
    local skillArgs = {
        allSkills           = allSkills.activeSkill,
		equipedPlayerSkills = equipedSkills,
		slotIndex           = skillIndex,
        tag                 = 4002,
        delayFuncList_ = {
            function()
                self.isControllable_ = true
            end
        }
    }
	local skillPopup = require('Game.views.SelectPlayerSkillPopup').new(skillArgs)
	display.commonUIParams(skillPopup, {ap = display.CENTER, po = display.center, tag = skillArgs.tag})
	self.towerHomeMdt_:getHomeScene():AddDialog(skillPopup)
end
function TowerQuestEditCardTeamMediator:convertPlayerSkillData_(allSkill)
	local result = {
		activeSkill  = {},
		passiveSkill = {}
	}
	for i,v in ipairs(allSkill) do
		local skillId   = checkint(v)
		local skillConf = CommonUtils.GetSkillConf(skillId)
		local skillInfo = {skillId = skillId}
		if ConfigSkillType.SKILL_HALO == checkint(skillConf.property) then
			table.insert(result.passiveSkill, skillInfo)  -- 被动技能
		else
			table.insert(result.activeSkill, skillInfo)  -- 主动技能
		end
	end
	return result
end


function TowerQuestEditCardTeamMediator:isTouchedNode_(node, touchPos)
    local size = node:getContentSize()
    local box  = cc.rect(0, 0, size.width,size.height)
    local tPos = cc.p(node:convertToNodeSpace(touchPos))
    return cc.rectContainsPoint(box, tPos)
end
function TowerQuestEditCardTeamMediator:onTouchBegan_(touch, event)
    if not self.isControllable_ then return true end
    if not self.editView_ then return true end

    local moveActList = function(movePos)
        return cc.Sequence:create({
            cc.MoveTo:create(0.1, movePos),
            cc.CallFunc:create(function()
                self:resortAllTeamSpineZorder_()
            end)
        })
    end

    -- check began moulti touch
    if self.beganTouchId_ and self.beganTouchId_ ~= touch:getId() then
        -- reset to site position
        local editViewData = self.editView_:getViewData()
        local teamCardSite = editViewData.teamCardSiteList[self.touchTeamIndex_]
        if self.dragTeamCardSpine_ and teamCardSite then
            -- self.dragTeamCardSpine_.cardSpine:setToSetupPose()
            -- self.dragTeamCardSpine_.cardSpine:setAnimation(0, 'idle', true)
            self.dragTeamCardSpine_.view:stopAllActions()
            self.dragTeamCardSpine_.view:runAction(moveActList(cc.p(teamCardSite.view:getPosition())))
        end

        -- cancel touch data
        self.touchTeamIndex_    = 0
        self.beganTouchId_      = nil
        self.beganTouchPos_     = nil
        self.isBeganDragTeam_   = false
        self.dragTeamCardSpine_ = nil
        return true

    else
        self.beganTouchId_ = touch:getId()
    end

    self.beganTouchPos_     = touch:getLocation()
    self.touchTeamIndex_    = 0
    self.isBeganDragTeam_   = false
    self.dragTeamCardSpine_ = nil

    -- check touchBegan teamSitelist
    local editViewData = self.editView_ and self.editView_:getViewData() or nil
    for i, teamCardSite in ipairs(editViewData and editViewData.teamCardSiteList or {}) do
        if self:isTouchedNode_(teamCardSite.dragAreaLayer, self.beganTouchPos_) then
            self.touchTeamIndex_    = i
            self.dragTeamCardSpine_ = self.teamCardSpineMap_[tostring(self.touchTeamIndex_)]

            -- set highest zorder
            if self.dragTeamCardSpine_ then
                self.dragTeamCardSpine_.view:setLocalZOrder(100)
            end
            break
        end
    end
    return true
end
function TowerQuestEditCardTeamMediator:onTouchMoved_(touch, event)
    if not self.beganTouchPos_ then return end
    if not self.editView_ then return true end

    -- check drag began
    if self.touchTeamIndex_ > 0 and self.isBeganDragTeam_ == false and
        (math.abs(self.beganTouchPos_.x - touch:getLocation().x) >= DRAG_CHECK_GAP or 
        math.abs(self.beganTouchPos_.y - touch:getLocation().y) >= DRAG_CHECK_GAP) then
        self.isBeganDragTeam_ = true

        if self.dragTeamCardSpine_ and self.dragTeamCardSpine_.cardSpine then
            self.dragTeamCardSpine_.cardSpine:setToSetupPose()
            self.dragTeamCardSpine_.cardSpine:setAnimation(0, 'run', true)
        end
    end
    
    -- update drag spine
    if self.isBeganDragTeam_ and self.dragTeamCardSpine_ then
        local editViewData = self.editView_:getViewData()
        local teamCardSite = editViewData.teamCardSiteList[self.touchTeamIndex_]
        self.dragTeamCardSpine_.view:setPositionX(teamCardSite.view:getPositionX() - self.beganTouchPos_.x + touch:getLocation().x)
        self.dragTeamCardSpine_.view:setPositionY(teamCardSite.view:getPositionY() - self.beganTouchPos_.y + touch:getLocation().y)
    end
end
function TowerQuestEditCardTeamMediator:onTouchEnded_(touch, event)
    if checkint(self.touchTeamIndex_) <= 0 then return end
    if not self.editView_ then return true end

    -- check touchEnded teamSitelist
    local endedTeamIndex = 0
    local editViewData   = self.editView_:getViewData()
    for i, teamCardSite in ipairs(editViewData.teamCardSiteList or {}) do
        if self:isTouchedNode_(teamCardSite.dragAreaLayer, touch:getLocation()) then
            endedTeamIndex = i
            break
        end
    end

    -------------------------------------------------
    -- drag ended check
    if self.isBeganDragTeam_ then
        local moveActList = function(movePos)
            return cc.Sequence:create({
                cc.MoveTo:create(0.1, movePos),
                cc.CallFunc:create(function()
                    self:resortAllTeamSpineZorder_()
                end)
            })
        end

        -- check endedTeamIndex
        if endedTeamIndex > 0 and self.touchTeamIndex_ ~= endedTeamIndex then
            local editViewData  = self.editView_:getViewData()
            local beganCardSite = editViewData.teamCardSiteList[self.touchTeamIndex_]
            local endedCardSite = editViewData.teamCardSiteList[endedTeamIndex]

            -- update drag spine position
            if self.dragTeamCardSpine_ then
                self.dragTeamCardSpine_.cardSpine:setToSetupPose()
                if endedTeamIndex == 1 then  -- No.1 is captain
                    self.dragTeamCardSpine_.cardSpine:setAnimation(0, 'win', false)
                    self.dragTeamCardSpine_.cardSpine:addAnimation(0, 'idle', true)
                else
                    self.dragTeamCardSpine_.cardSpine:setAnimation(0, 'idle', true)
                end
                
                self.dragTeamCardSpine_.view:stopAllActions()
                self.dragTeamCardSpine_.view:runAction(moveActList(cc.p(endedCardSite.view:getPosition())))
            end

            -- update target spine position
            local endedTeamCardSpine = self.teamCardSpineMap_[tostring(endedTeamIndex)]
            if endedTeamCardSpine then
                if self.touchTeamIndex_ == 1 then  -- No.1 is captain
                    endedTeamCardSpine.cardSpine:setToSetupPose()
                    endedTeamCardSpine.cardSpine:setAnimation(0, 'win', false)
                    endedTeamCardSpine.cardSpine:addAnimation(0, 'idle', true)
                end

                endedTeamCardSpine.view:stopAllActions()
                endedTeamCardSpine.view:runAction(moveActList(cc.p(beganCardSite.view:getPosition())))
            end

            -- switch team card data
            local tempTeamCardGuid  = self.teamCardGuidList_[self.touchTeamIndex_]
            self.teamCardGuidList_[self.touchTeamIndex_]           = self.teamCardGuidList_[endedTeamIndex]
            self.teamCardGuidList_[endedTeamIndex]                 = tempTeamCardGuid
            self.teamCardSpineMap_[tostring(self.touchTeamIndex_)] = endedTeamCardSpine
            self.teamCardSpineMap_[tostring(endedTeamIndex)]       = self.dragTeamCardSpine_
        else
            -- reset to site position
            local editViewData = self.editView_:getViewData()
            local teamCardSite = editViewData.teamCardSiteList[self.touchTeamIndex_]
            if self.dragTeamCardSpine_ and teamCardSite then
                self.dragTeamCardSpine_.cardSpine:setToSetupPose()
                self.dragTeamCardSpine_.cardSpine:setAnimation(0, 'idle', true)
                self.dragTeamCardSpine_.view:stopAllActions()
                self.dragTeamCardSpine_.view:runAction(moveActList(cc.p(teamCardSite.view:getPosition())))
            end
        end

    -------------------------------------------------
    -- touch ended check
    else
        -- check click same teamIndex
        if self.touchTeamIndex_ == endedTeamIndex then
            self:removeTeamCardAt_(endedTeamIndex)
        end
    end

    self.touchTeamIndex_ = 0
    self.beganTouchId_   = nil
    self.beganTouchPos_  = nil
    self.isControllable_ = false
    transition.execute(self.editView_, nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})
end


return TowerQuestEditCardTeamMediator
