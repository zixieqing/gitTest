--[[
 * author : kaishiqi
 * descpt : 爬塔 - 单元契约界面中介者
]]
local TowerModelFactory          = require('Game.models.TowerQuestModelFactory')
local UnitContractModel          = TowerModelFactory.getModelType('UnitContract')
local TowerQuestContractView     = require('Game.views.TowerQuestContractView')
local TowerConfigParser          = require('Game.Datas.Parser.TowerConfigParser')
local TowerQuestContractMediator = class('TowerQuestContractMediator', mvc.Mediator)

function TowerQuestContractMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TowerQuestContractMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function TowerQuestContractMediator:Initial(key)
    self.super.Initial(self, key)

    local contractIdList    = checktable(self.ctorArgs_.contractIdList)
    local selectedContracts = checktable(self.ctorArgs_.selectedContractList)
    self.isEditMode_        = self.ctorArgs_.isEditMode == true
    self.towerUnitId_       = checkint(self.ctorArgs_.towerUnitId)
    self.chestRewardsMap_   = checktable(self.ctorArgs_.chestRewardsMap)
    self.towerHomeMdt_      = self:GetFacade():RetrieveMediator('TowerQuestHomeMediator')
    self.isControllable_    = self.isEditMode_
    self.contractListCells_ = {}
    self.contractSelectMap_ = {}

    -- check init select status
    local selectedContractMap = {}
    for i,v in ipairs(selectedContracts) do
        selectedContractMap[tostring(v)] = v
    end
    for i, contractId in ipairs(contractIdList) do
        local isSelect = selectedContractMap[tostring(contractId)] ~= nil
        self.contractSelectMap_[i] = isSelect
    end

    -- create view
    self.uiView_ = TowerQuestContractView.new()
    self:SetViewComponent(self.uiView_)

    -- update view
    self:setContractIdList(contractIdList)
    self:updateChestInfo_()
end


function TowerQuestContractMediator:CleanupView()
    if self.uiView_:getParent() then
        self.uiView_:removeFromParent()
    end
end


function TowerQuestContractMediator:OnRegist()
end
function TowerQuestContractMediator:OnUnRegist()
end


function TowerQuestContractMediator:InterestSignals()
    return {
    }
end
function TowerQuestContractMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- get / set

function TowerQuestContractMediator:getContractIdList()
    return self.contractIdList_
end
function TowerQuestContractMediator:setContractIdList(idList)
    self.contractIdList_ = checktable(idList)
    self:updateContractIdList_()
end


-------------------------------------------------
-- public method

function TowerQuestContractMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


function TowerQuestContractMediator:exportSelectedContractIdList()
    local selectedContractIdList = {}
    for i,v in ipairs(self.contractSelectMap_) do
        if v == true then
            table.insert(selectedContractIdList, self:getContractIdList()[i])
        end
    end
    return selectedContractIdList
end


-------------------------------------------------
-- private method

function TowerQuestContractMediator:updateContractIdList_()
    local uiViewData        = self.uiView_:getViewData()
    -- local contractList      = uiViewData.contractList
    -- contractList:removeAllNodes()
    local contractLayer     = uiViewData.contractLayer
    contractLayer:removeAllChildren()
    self.contractListCells_ = {}

    local contractNum = #self:getContractIdList()
    for i, contractId in ipairs(self:getContractIdList()) do
        -- create cell
        local contractCell = self.uiView_:createContractCell()
        -- contractList:insertNodeAtLast(contractCell.view)
        contractCell.view:setPositionY(contractLayer:getContentSize().height - i*contractCell.view:getContentSize().height)
        contractLayer:addChild(contractCell.view)
        self.contractListCells_[i] = contractCell

        -- init cell
        contractCell.view:setTag(i)
        contractCell.footerLine:setVisible(i < contractNum)
        display.commonUIParams(contractCell.view, {cb = handler(self, self.onClickContractCellHandler_), animate = false})

        local contractConf = CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.CONTRACT ,'tower')[tostring(contractId)] or {}
        local contractText = tostring(contractConf.descr)
        display.commonLabelParams(contractCell.textNormolLabel, {text = contractText})
        display.commonLabelParams(contractCell.textSelectLabel, {text = contractText})

        -- update cell
        local isSelected = self.contractSelectMap_[i]
        contractCell.selectIcon:setVisible(isSelected)
        self:updateContractCellStatusAt_(i)
    end
    -- contractList:setDragable(contractNum > 3)
    -- contractList:reloadData()
end


function TowerQuestContractMediator:updateContractCellStatusAt_(index)
    local isSelected   = self.contractSelectMap_[index]
    local contractCell = self.contractListCells_[index]
    
    if contractCell then
        contractCell.textNormolLabel:setVisible(not isSelected)
        contractCell.textSelectLabel:setVisible(isSelected)

        if isSelected then
            contractCell.selectBgImg:stopAllActions()
            contractCell.selectBgImg:setOpacity(0)
            contractCell.selectBgImg:runAction(cc.FadeIn:create(0.2))

            if not contractCell.selectIcon:isVisible() then
                contractCell.checkboxSpine:setVisible(true)
                contractCell.checkboxSpine:setToSetupPose()
                contractCell.checkboxSpine:setAnimation(0, 'play', false)
            else
                contractCell.checkboxSpine:setVisible(false)
            end

        else
            contractCell.selectIcon:setVisible(false)

            contractCell.selectBgImg:stopAllActions()
            contractCell.selectBgImg:setOpacity(100)
            contractCell.selectBgImg:runAction(cc.FadeOut:create(0.2))

            contractCell.checkboxSpine:setVisible(false)
        end
    end
end


function TowerQuestContractMediator:countContractSelectNum_()
    local selectNum = 0
    for k,v in pairs(self.contractSelectMap_) do
        selectNum = selectNum + (v == true and 1 or 0)
    end
    return selectNum
end
function TowerQuestContractMediator:updateChestInfo_()
    local selectNum = self:countContractSelectNum_()
    local unitConf  = checktable(CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.UNIT ,'tower'))[tostring(self.towerUnitId_)] or {}
    local chestId   = checkint(unitConf[string.fmt('chestId%1', selectNum + 1)])  -- 1 is base, 2 is level 1
    local chestConf = CommonUtils.GetConfig('goods', 'chest', chestId) or {}

    -- update chest name
    local uiViewData = self.uiView_:getViewData()
    display.commonLabelParams(uiViewData.chestNameBar, {text = chestConf.name , hAlign = display.TAC , w = 250 , reqH = 40 })

    -- update chest image
    uiViewData.chestImageLayer:removeAllChildren()
    if chestId > 0 then
        local chestImg = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(chestId)), 0, 0, {enable = true})
        chestImg:setPosition(utils.getLocalCenter(uiViewData.chestImageLayer))
        uiViewData.chestImageLayer:addChild(chestImg)
        chestImg:setOnClickScriptHandler(function(sender)
            local actList   = {}
            local waveNum   = 3
            local originPos = utils.getLocalCenter(sender:getParent())
            sender:stopAllActions()
            sender:setPosition(originPos)
            for i=1,10 do
                local targetPos = cc.p(originPos.x + math.random(-waveNum, waveNum), originPos.y + math.random(-waveNum, waveNum))
                table.insert(actList, cc.MoveTo:create(0.02, targetPos))
            end
            table.insert(actList, cc.CallFunc:create(function()
                sender:setPosition(originPos)
            end))
            sender:runAction(cc.Sequence:create(actList))
        end)
    end

    -- update chest level
    for i = 1, #uiViewData.chestLevelHideList do
        local hideIcon = uiViewData.chestLevelHideList[i]
        local showIcon = uiViewData.chestLevelShowList[i]
        if hideIcon then hideIcon:setVisible(i > selectNum) end
        if showIcon then showIcon:setVisible(i <= selectNum) end
    end

    -- check chest effect
    if self.oldContractSelectNum_ ~= nil then
        uiViewData.chestEffectSpine:setToSetupPose()
        if selectNum > checkint(self.oldContractSelectNum_) then
            uiViewData.chestEffectSpine:setAnimation(0, 'play1', false)  -- upgrade
            PlayAudioClip(AUDIOS.UI.ui_relic_levelup.id)
        else
            uiViewData.chestEffectSpine:setAnimation(0, 'play2', false)  -- downgrade
        end
    end

    -- update chest props
    local reloadPropsList = function()
        uiViewData.propsList:removeAllNodes()
        local goodsRewards = checktable(self.chestRewardsMap_[tostring(chestId)])
        local goodsCellW   = uiViewData.propsList:getContentSize().width / 4
        local goodsCellH   = uiViewData.propsList:getContentSize().height
        for i = 1, math.max(#goodsRewards, 4) do
            local cellLayer = display.newLayer(0, 0, {size = cc.size(goodsCellW, goodsCellH)})
            local v = goodsRewards[i]
            if v then
                local goodsNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true, callBack = function(sender)
                    AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
                end})
                goodsNode:setScale(0.8)
                goodsNode:setPosition(goodsCellW/2, goodsCellH/2)
                cellLayer:addChild(goodsNode)
            else
                local emptyNode = self.uiView_.createEmptyGoodsCell()
                emptyNode:setScale(0.8)
                emptyNode:setOpacity(120)
                emptyNode:setPosition(goodsCellW/2, goodsCellH/2)
                cellLayer:addChild(emptyNode)
            end
            uiViewData.propsList:insertNodeAtLast(cellLayer)
        end
        uiViewData.propsList:setDragable(#goodsRewards > 4)
        uiViewData.propsList:reloadData()
    end
    if uiViewData.propsList:getNodeCount() > 0 then
        uiViewData.propsList:setScale(1)
        uiViewData.propsList:stopAllActions()
        uiViewData.propsList:runAction(cc.Sequence:create({
            cc.ScaleTo:create(0.1, 1, 0),
            cc.CallFunc:create(function()
                reloadPropsList()
            end),
            cc.ScaleTo:create(0.1, 1, 1)
        }))
    else
        reloadPropsList()
    end
end


-------------------------------------------------
-- handler

function TowerQuestContractMediator:onClickContractCellHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    local clickIndex = checkint(sender:getTag())
    local isSelected = self.contractSelectMap_[clickIndex] == true
    self.oldContractSelectNum_ = self:countContractSelectNum_()
    self.contractSelectMap_[clickIndex] = not isSelected
    self:updateContractCellStatusAt_(clickIndex)
    self:updateChestInfo_()

    self.isControllable_ = false
    transition.execute(self.uiView_, nil, {delay = 0.3, complete = function()
        self.isControllable_ = true
    end})

    self:GetFacade():DispatchObservers(SGL.TOWER_QUEST_SELECT_CONTRACT, {contractIdList = self:exportSelectedContractIdList()})
end


return TowerQuestContractMediator
