--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 牌店 - 合成中介者
]]
local TTGameTypeFilterLayer     = require('Game.views.ttGame.TripleTriadGameTypeFilterLayer')
local TTGameShopComposeView     = require('Game.views.ttGame.TripleTriadGameShopComposeView')
local TTGameShopComposeMediator = class('TripleTriadGameShopComposeMediator', mvc.Mediator)

local TYPE_ALL = TTGAME_DEFINE.FILTER_TYPE_ALL

function TTGameShopComposeMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TripleTriadGameShopComposeMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function TTGameShopComposeMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.ownerNode_       = self.ctorArgs_.ownerNode
    self.libCardCellDict_ = {}
    self.isControllable_  = true

    self.filterCardStar_ = 1
    self.filterCardType_ = TYPE_ALL
    self.libraryCardMap_ = {}
    self.starCardNumMap_ = {}
    local cardConfFile   = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.CARD_DEFINE)
    for cardId, cardConf in orderedPairs(cardConfFile) do
        local cardConf = cardConfFile[tostring(cardId)] or {}
        local cardStar = checkint(cardConf.star)
        local cardType = checkint(cardConf.type)
        if checkint(cardConf.canCompose) == 1 then
            self.libraryCardMap_[tostring(cardStar)] = self.libraryCardMap_[tostring(cardStar)] or {}
            self.libraryCardMap_[tostring(cardStar)][tostring(TYPE_ALL)] = self.libraryCardMap_[tostring(cardStar)][tostring(TYPE_ALL)] or {}
            self.libraryCardMap_[tostring(cardStar)][tostring(cardType)] = self.libraryCardMap_[tostring(cardStar)][tostring(cardType)] or {}
            table.insert(self.libraryCardMap_[tostring(cardStar)][tostring(TYPE_ALL)], cardConf)
            if cardType ~= TYPE_ALL then
                table.insert(self.libraryCardMap_[tostring(cardStar)][tostring(cardType)], cardConf)
            end
        end
    end

    -- create view
    if self.ownerNode_ then
        -- create view
        self.shopView_ = TTGameShopComposeView.new(self.ownerNode_:getContentSize())
        self.ownerNode_:addChild(self:getShopView())
        self:SetViewComponent(self:getShopView())

        self.ownerScene_      = app.uiMgr:GetCurrentScene()
        self.typeFilterLayer_ = TTGameTypeFilterLayer.new({closeCB = function()
            self:getViewData().typeFilterBtn:setChecked(false)
        end})
        self:getOwnerScene():AddDialog(self:getTypeFilterLayer())

        -- add listen
        display.commonUIParams(self:getViewData().typeFilterBtn, {cb = handler(self, self.onClickTypeFilterButtonHandler_), animate = false})
        self:getViewData().cardGridView:setDataSourceAdapterScriptHandler(handler(self, self.onLibCardGridDataAdapterHandler_))
        self:getTypeFilterLayer():setClickTypeCellCB(handler(self, self.onClickFilterTypeCellHandler_))

        -- update views
        self:getTypeFilterLayer():getTypeCellLayer():setPosition(cc.pAdd(self:getViewData().typeFilterBtn:convertToWorldSpaceAR(PointZero), cc.p(90,-25)))
        self:getTypeFilterLayer():getTypeCellLayer():setAnchorPoint(display.RIGHT_TOP)
        self:getTypeFilterLayer():setSelectFilterType(self:getFilterCardType())
        self:getTypeFilterLayer():closeTypeFilterView()

        self:updateLibraryCardGridData_()
    end
end


function TTGameShopComposeMediator:CleanupView()
    if self:getTypeFilterLayer() and not tolua.isnull(self:getTypeFilterLayer()) then
        self:getTypeFilterLayer():close()
        self.typeFilterLayer_ = nil
    end
end


function TTGameShopComposeMediator:OnRegist()
    regPost(POST.TTGAME_BUY_CARD)
end


function TTGameShopComposeMediator:OnUnRegist()
    unregPost(POST.TTGAME_BUY_CARD)
end


function TTGameShopComposeMediator:InterestSignals()
    return {
        POST.TTGAME_BUY_CARD.sglName,
    }
end
function TTGameShopComposeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.TTGAME_BUY_CARD.sglName then
        local exchegeCardId = checkint(data.requestData.battleCardId)
        local cardDataIndex = checkint(data.requestData.cardDataIndex)
        
        -- consume currency
        local consumeData  = {}
        local cardConfInfo = self:getFilterCardDatas()[cardDataIndex] or {}
        for goodsId, num in pairs(cardConfInfo.compose) do
            table.insert(consumeData, {
                goodsId = goodsId,
                num     = -num,
            })
        end
        CommonUtils.DrawRewards(consumeData)

        -- draw rewards
        app.uiMgr:AddDialog('Game.views.ttGame.TripleTriadGamePackageRewardsPopup', {rewards = {
            {turnGoodsId = exchegeCardId, num = 1}
        }, composeMode = true})

        -- update cache count
        app:DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI, {})

        -- updat card cell
        self:updateLibraryCardCell_(cardDataIndex)
    end
end


-------------------------------------------------
-- get / set

function TTGameShopComposeMediator:getOwnerScene()
    return self.ownerScene_
end


function TTGameShopComposeMediator:getShopView()
    return self.shopView_
end
function TTGameShopComposeMediator:getViewData()
    return self:getShopView():getViewData()
end


function TTGameShopComposeMediator:getTypeFilterLayer()
    return self.typeFilterLayer_
end
function TTGameShopComposeMediator:getTypeLayerViewData()
    return self:getTypeFilterLayer():getViewData()
end


function TTGameShopComposeMediator:getFilterCardDatas()
    return self.filterCardDatas_
end
function TTGameShopComposeMediator:setFilterCardDatas(data)
    self.filterCardDatas_ = checktable(data)
    self:updateLibraryCardGridView_()
end


function TTGameShopComposeMediator:getFilterCardStar()
    return self.filterCardStar_
end
function TTGameShopComposeMediator:setFilterCardStar(star)
    self.filterCardStar_ = checkint(star)
    self:updateLibraryCardGridData_()
    self:updateLibraryCardGridView_()
end


function TTGameShopComposeMediator:getFilterCardType()
    return self.filterCardType_
end
function TTGameShopComposeMediator:setFilterCardType(typeId)
    self.filterCardType_ = checkint(typeId)
    self:updateLibraryCardGridData_()
    self:updateLibraryCardGridView_()
    self:getTypeFilterLayer():setSelectFilterType(self:getFilterCardType())

    local typeConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.CARD_CAMP, typeId)
    self:getShopView():updateFilterButtonLabel(typeConfInfo.name)
end


function TTGameShopComposeMediator:getStarCardNumMap()
    return self.starCardNumMap_
end


-------------------------------------------------
-- public

function TTGameShopComposeMediator:hide()
    local viewComponent = self:GetViewComponent()
    if viewComponent then
        viewComponent:setVisible(false)
    end
end
function TTGameShopComposeMediator:show()
    local viewComponent = self:GetViewComponent()
    if viewComponent then
        viewComponent:setVisible(true)
    end
end


-------------------------------------------------
-- private

function TTGameShopComposeMediator:updateLibraryCardGridData_()
    self.starCardNumMap_ = {}
    for starNum = 1, TTGAME_DEFINE.STAR_MAXIMUM do
        local starCardMap  = self.libraryCardMap_[tostring(starNum)] or {}
        local typeCardList = starCardMap[tostring(self:getFilterCardType())] or {}
        self.starCardNumMap_[tostring(starNum)] = #typeCardList
    end
    
    local starCardMap = self.libraryCardMap_[tostring(self:getFilterCardStar())] or {}
    self:setFilterCardDatas(starCardMap[tostring(self:getFilterCardType())])
end
function TTGameShopComposeMediator:updateLibraryCardGridView_()
    local ttGameShopMediator = self:GetFacade():RetrieveMediator('TripleTriadGameShopMediator')
    if ttGameShopMediator then
        ttGameShopMediator:getShopView():updateFilterStarStatus(self:getFilterCardStar(), self:getStarCardNumMap())
    end
    self:getViewData().cardGridView:setCountOfCell(#self:getFilterCardDatas())
    self:getViewData().cardGridView:reloadData()
end


function TTGameShopComposeMediator:updateLibraryCardCell_(cellIndex, viewData)
    local cardGridView   = self:getViewData().cardGridView
    local cellViewData   = viewData or self.libCardCellDict_[cardGridView:cellAtIndex(cellIndex - 1)]
    local filterCardData = self:getFilterCardDatas()[checkint(cellIndex)] or {}

    if cellViewData then
        local hasLibraryCard = app.ttGameMgr:hasBattleCardId(filterCardData.id)
        cellViewData.lockLayer:setVisible(not hasLibraryCard)
        cellViewData.haveLayer:setVisible(hasLibraryCard)

        local exchangeId = checkint(table.keys(filterCardData.compose or {})[1])
        display.commonLabelParams(cellViewData.priceLabel, {text = tostring(filterCardData.compose[tostring(exchangeId)])})
        
        local exchangeIconPath = CommonUtils.GetGoodsIconPathById(exchangeId)
        cellViewData.cIconLayer:removeAllChildren()
        cellViewData.cIconLayer:addChild(display.newImageView(_res(exchangeIconPath), 0, 0, {ap = display.LEFT_CENTER}))

        cellViewData.cardNode:setCardId(filterCardData.id)
        if hasLibraryCard then
            cellViewData.cardNode:setOpacity(255)
            cellViewData.cardNode:toDisableStatus()
            cellViewData.cardNode:showHaveCardMark()
        else
            cellViewData.cardNode:setOpacity(155)
            cellViewData.cardNode:toNormalStatus()
            cellViewData.cardNode:hideHaveCardMark()
        end
        cellViewData.bgFrame:setVisible(not hasLibraryCard)
    end
end


-------------------------------------------------
-- handler

function TTGameShopComposeMediator:onLibCardGridDataAdapterHandler_(cell, idx)
    local pCell = cell
    local index = idx + 1

    if pCell == nil then
        local cellNodeSize = self:getViewData().cardGridView:getSizeOfCell()
        local cellViewData = TTGameShopComposeView.CreateCardCell(cellNodeSize)
        display.commonUIParams(cellViewData.hotspot, {cb = handler(self, self.onClickLibraryCardCellHandler_)})

        pCell = cellViewData.view
        self.libCardCellDict_[pCell] = cellViewData
    end
    
    local cellViewData = self.libCardCellDict_[pCell]
    cellViewData.view:setTag(index)
    cellViewData.hotspot:setTag(index)
    self:updateLibraryCardCell_(index, cellViewData)
    return pCell
end


function TTGameShopComposeMediator:onClickStarFilterCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if self:getFilterCardStar() ~= sender:getTag() then
        self:setFilterCardStar(sender:getTag())
    end
end


function TTGameShopComposeMediator:onClickTypeFilterButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    self:getViewData().typeFilterBtn:setChecked(true)
    self:getTypeFilterLayer():showTypeFilterView()
end


function TTGameShopComposeMediator:onClickFilterTypeCellHandler_(typeId)
    self:getTypeFilterLayer():closeTypeFilterView()

    self:setFilterCardType(typeId)
end


function TTGameShopComposeMediator:onClickLibraryCardCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local cardDataIndex  = checkint(sender:getTag())
    local filterCardData = self:getFilterCardDatas()[cardDataIndex] or {}
    local clickLibCardId = checkint(filterCardData.id)
    local hasLibraryCard = app.ttGameMgr:hasBattleCardId(filterCardData.id)

    if hasLibraryCard then
        app.uiMgr:ShowInformationTips(__('您已拥有该卡牌，不可再次兑换'))
    else
        local exchangeId = checkint(table.keys(filterCardData.compose or {})[1])
        local consumeNum = checkint(filterCardData.compose[tostring(exchangeId)])
        local goodsConf  = CommonUtils.GetConfig('goods', 'goods', exchangeId) or {}
        local tipString  = string.fmt(__('是否愿意花费_num_【_name_】兑换该战牌？'), {_num_ = consumeNum, _name_ = tostring(goodsConf.name)})
        local commonTip  = require('common.NewCommonTip').new({text = tipString, callback = function()
            if consumeNum > app.gameMgr:GetAmountByIdForce(exchangeId) then
                app.uiMgr:ShowInformationTips(string.fmt(__('_des_不足'), {_des_ = tostring(goodsConf.name)}))
            else
                self.isControllable_ = false
                transition.execute(self:getShopView(), nil, {delay = 0.3, complete = function()
                    self.isControllable_ = true
                end})
                self:SendSignal(POST.TTGAME_BUY_CARD.cmdName, {battleCardId = clickLibCardId, cardDataIndex = cardDataIndex})
            end
        end})
        commonTip:setPosition(display.center)
        app.uiMgr:GetCurrentScene():AddDialog(commonTip)
    end
end



return TTGameShopComposeMediator
