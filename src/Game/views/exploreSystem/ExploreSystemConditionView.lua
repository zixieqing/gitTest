--[[
 * descpt : 探索条件 界面
]]

local ExploreSystemConditionView = class('ExploreSystemConditionView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.exploreSystem.ExploreSystemConditionView'
	node:enableNodeEvents()
	return node
end)

local appFacadeIns     = AppFacade.GetInstance()
local uiMgr            = appFacadeIns:GetManager("UIManager")
local exploreSystemMgr = appFacadeIns:GetManager("ExploreSystemManager")

local RES_DIR = {
    BG_STATE_INACTIVE     = _res('ui/exploreSystem/explor_edit_bg_state_ok.png'),
    BG_CONDITION          = _res('ui/exploreSystem/explor_edit_bg_condition.png'),
    BG_CONCDITION_PRIZE   = _res('ui/exploreSystem/explor_edit_bg_concdition_prize.png'),
    RAID_BOSS_BTN_SEARCH  = _res('ui/common/raid_boss_btn_search.png'),
    ICO_SEARCH_LIGHT      = _res('ui/common/raid_boss_ico_search_light.png'),
    TITLE                 = _res('ui/common/common_title_5.png'),
    LABEL_TITLE           = _res("ui/tower/ready/tower_label_title.png"),
    BTN_WHITE_DEFAULT     = _res('ui/common/common_btn_white_default.png'),
    BG_CONDITION_LIST     = _res('ui/exploreSystem/explor_edit_bg_condition_list.png'),

    BG_CELL_ACTIVE        = _res('ui/exploreSystem/explor_edit_bg_conditiong_list_active.png'),
    BG_CELL_INACTIVE      = _res('ui/exploreSystem/explor_edit_bg_conditiong_list_Inactive.png'),
    ICO_MARK_EMPTY        = _res('ui/tower/team/tower_ico_mark_empty.png'),
    ICO_MARK_SELECTED     = _res('ui/tower/team/tower_ico_mark_selected.png'),

    BTN_ORANGE            = _res('ui/common/common_btn_orange.png'),
    BTN_DISABLE           = _res('ui/common/common_btn_orange_disable.png'),
    
}

local CreateView = nil
local CreateCell = nil

local REFRESH_CARD_LIST   = 'REFRESH_CARD_LIST'
local UPDATE_QUEST_REACH  = 'UPDATE_QUEST_REACH'

local SATISFY_TEAM_CHANGE_CONDITION = 'SATISFY_TEAM_CHANGE_CONDITION'

function ExploreSystemConditionView:ctor( ... )
    self.args = unpack({...}) or {}
    self:initData()
    self:initialUI()
    self:RegisterSignal()
end

function ExploreSystemConditionView:initData()
    self.filterQuestTypes = {}
    -- 当前完成条件数量
    self.curSatisfyConditionCount = 0
    self.conditionData = self.args.conditionData or {}
    self.conditionRewardList = self.args.conditionRewardList or {}
    self.conditionBaseReward = self.args.conditionBaseReward or {}
    self.cardsNum = checkint(self.args.cardsNum)
end

function ExploreSystemConditionView:initConditionData(selectedCardIds)
    self.selectedCardIds = selectedCardIds or {}
    self.satisfyConditionList = exploreSystemMgr:getSatisfyConditionList(self.selectedCardIds, self.conditionData, self.cardsNum)
    self.curSatisfyConditionCount = exploreSystemMgr:getSatisfyConditionCount(self.satisfyConditionList)
    self.curRewardIndex = exploreSystemMgr:getCurConditionRewardIndex(self.conditionRewardList, self.curSatisfyConditionCount)

    -- self.isShowConditionReward = table.nums(self.selectedCardIds) >= self.cardsNum
end

function ExploreSystemConditionView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function ExploreSystemConditionView:initView()
    local viewData = self:getViewData()
    
    local searchBtn = viewData.searchBtn
    display.commonUIParams(searchBtn, {cb = handler(self, self.onClickSearchBtnAction)})
    
    local cancelBtn = viewData.cancelBtn
    display.commonUIParams(cancelBtn, {cb = handler(self, self.onClickCancelBtnAction)})

    local confirmBtn = viewData.confirmBtn
    display.commonUIParams(confirmBtn, {cb = handler(self, self.onClickConfirmBtnAction)})

    local gridView  = viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSourceAdapter))
    gridView:setCountOfCell(#self.conditionData)

    local searchLightLayer = viewData.searchLightLayer
    local searchLight      = viewData.searchLight
    local searchBtn        = viewData.searchBtn
    local searchLightActionSeq = cc.RepeatForever:create(
        cc.Spawn:create(
            cc.TargetedAction:create(searchLight, cc.Sequence:create(
                    cc.ScaleTo:create(0.4, 1.1),
                    cc.ScaleTo:create(0.4, 0.9)
                )
            ),
            cc.TargetedAction:create(searchBtn, cc.Sequence:create(
                cc.ScaleTo:create(0.5, 1.01),
                cc.ScaleTo:create(0.5, 0.99))
            )
        )
    )
    searchLightLayer:runAction(searchLightActionSeq)
    

    self:refreshUI(self.args)
end

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
  gridview data adapter
]]
function ExploreSystemConditionView:onDataSourceAdapter(p_convertview,idx)
    local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
        pCell = CreateCell()
        display.commonUIParams(pCell.viewData.touchLayer, {cb = handler(self, self.onClickCellAction)})
    end
    
    self:updateCell(pCell.viewData, index)

    pCell.viewData.touchLayer:setTag(index)

    return pCell
end

function ExploreSystemConditionView:updateCell(viewData, index)
    local data = self.conditionData[index]

    self:updateCellBg(viewData, index)
    
    local icon      = viewData.icon
    local questType = data.type
    local needNum = checkint(data.number)
    icon:setTexture(exploreSystemMgr:getConditionIcon(questType, needNum))

    local descLabel = viewData.descLabel
    display.commonLabelParams(descLabel, {text = tostring(data.desc) , w =280 })

    self:updateConditionSatisfyState(viewData, self.satisfyConditionList[index])
end

function ExploreSystemConditionView:updateCellBg(viewData, index)
    local bg        = viewData.bg
    local isSelect  = self.filterQuestTypes[tostring(index)] ~= nil
    bg:setTexture(isSelect and RES_DIR.BG_CELL_ACTIVE or RES_DIR.BG_CELL_INACTIVE)
end

function ExploreSystemConditionView:updateConditionSatisfyState(viewData, isSatisfy)
    local conditionSatisfyImg = viewData.conditionSatisfyImg
    conditionSatisfyImg:setTexture(isSatisfy and RES_DIR.ICO_MARK_SELECTED or RES_DIR.ICO_MARK_EMPTY)
end

function ExploreSystemConditionView:updateList()
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    gridView:reloadData()
end

function ExploreSystemConditionView:updateReachConditionCountLabel()
    local viewData = self:getViewData()
    local reachConditionCountLabel = viewData.reachConditionCountLabel
    display.commonLabelParams(reachConditionCountLabel, {text = string.format("%s/%s", self.curSatisfyConditionCount, #self.conditionData)})
end

function ExploreSystemConditionView:updateCurReward(cardData)
    local conditionReward = self.conditionRewardList[self.curRewardIndex] or self.conditionBaseReward
    local viewData = self:getViewData()
    local curRewardLayer = viewData.curRewardLayer
    local curRewardLayerSize = curRewardLayer:getContentSize()
    if curRewardLayer:getChildrenCount() > 0 then
        curRewardLayer:removeAllChildren()
    end

    if conditionReward then
        local callBack = function(sender)
            uiMgr:ShowInformationTipsBoard({ targetNode = sender, iconId = sender.goodId, type = 1 })
        end
        local h = curRewardLayerSize.height / 2
        local goodNodeSize = nil
        local scale = 0.8
        local extraReward = conditionReward.extraReward or {}
        local goodsNodes = {}
        for i, v in ipairs(extraReward) do
            local goodNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true, callBack = callBack})
            goodNode:setScale(scale)
            curRewardLayer:addChild(goodNode)
            table.insert(goodsNodes, goodNode)
        end

        display.setNodesToNodeOnCenter(curRewardLayer, goodsNodes, {spaceW = 10})
    end
end

function ExploreSystemConditionView:updateCancelBtn()
    local viewData = self:getViewData()
    local cancelBtn = viewData.cancelBtn
    cancelBtn:setVisible(next(self.filterQuestTypes) ~= nil)
end

function ExploreSystemConditionView:updateConfirmBtn()
    local viewData = self:getViewData()
    local confirmBtn = viewData.confirmBtn
    if table.nums(self.selectedCardIds) >= self.cardsNum then
        confirmBtn:setNormalImage(RES_DIR.BTN_ORANGE)
        confirmBtn:setSelectedImage(RES_DIR.BTN_ORANGE)
    else
        confirmBtn:setNormalImage(RES_DIR.BTN_DISABLE)
        confirmBtn:setSelectedImage(RES_DIR.BTN_DISABLE)
    end
end

function ExploreSystemConditionView:refreshUI(data)
    self:initConditionData(data.selectedCardIds or {})
    self:updateConfirmBtn()
    self:updateList()
    self:updateReachConditionCountLabel()
    self:updateCurReward()
end

---------------------------------------------------
-- view control end --
---------------------------------------------------

----------------------------------------
-- click handler begin --
----------------------------------------

function ExploreSystemConditionView:onClickCancelBtnAction(sender)
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    local cells    = gridView:getCells()
    self.filterQuestTypes = {}
    self:updateCancelBtn()
    appFacadeIns:DispatchObservers(REFRESH_CARD_LIST)
    if cells == nil or next(cells) == nil then return end
    for i, cell in ipairs(cells) do
        cell.viewData.bg:setTexture(RES_DIR.BG_CELL_INACTIVE)
    end
end

function ExploreSystemConditionView:onClickSearchBtnAction(sender)
    local viewData = self:getViewData()
    local conditionRewardView = viewData.conditionRewardView
    
    local params = {curSatisfyConditionCount = self.curSatisfyConditionCount, conditionRewardList = self.conditionRewardList, curRewardIndex = self.curRewardIndex}
    if conditionRewardView then
        conditionRewardView:setVisible(true)
        conditionRewardView:refreshUI(params)
        return
    end
    
    local layer = require('Game.views.exploreSystem.ExploreSystemConditionRewardView').new(params)
    layer:setAnchorPoint(cc.p(0.5, 0.5))
    layer:setPosition(display.center)
    

    uiMgr:GetCurrentScene():AddDialog(layer)

    viewData.conditionRewardView = layer
end

function ExploreSystemConditionView:onClickConfirmBtnAction(sender)
    local isCan = table.nums(self.selectedCardIds) >= self.cardsNum
    if isCan then
        appFacadeIns:DispatchObservers(SATISFY_TEAM_CHANGE_CONDITION, {curRewardIndex = self.curRewardIndex})
    else
        uiMgr:ShowInformationTips(__('阵容未满编'))
    end
end

function ExploreSystemConditionView:onClickCellAction(sender)
    local index = sender:getTag()
    -- logInfo.add(5, 'onClickCellAction index = ' .. index)
    local data = self.conditionData[index]
    local questType = data.type
    if self.filterQuestTypes[tostring(index)] then
        self.filterQuestTypes[tostring(index)] = nil
    else
        self.filterQuestTypes[tostring(index)] = data
    end

    local viewData = self:getViewData()
    local gridView = viewData.gridView
    local cell     = gridView:cellAtIndex(index - 1)
    if cell then
        self:updateCellBg(cell.viewData, index)
    end

    self:updateCancelBtn()

    local cardDatas = exploreSystemMgr:getFilterCards(self.filterQuestTypes)
    appFacadeIns:DispatchObservers(REFRESH_CARD_LIST, {cardDatas = cardDatas})
end
----------------------------------------
-- click handler end --
----------------------------------------

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()

    local conditionSelectStateLayer = display.newLayer(display.SAFE_R + 6, 0, {ap = display.RIGHT_BOTTOM, bg = RES_DIR.BG_STATE_INACTIVE})
    local conditionSelectStateLayerSize = conditionSelectStateLayer:getContentSize()
    view:addChild(conditionSelectStateLayer, 2)

    local confirmBtn = display.newButton(conditionSelectStateLayerSize.width / 2, conditionSelectStateLayerSize.height / 2 - 10, {ap = display.CENTER, n = RES_DIR.BTN_DISABLE})
	display.commonLabelParams(confirmBtn, fontWithColor(14, {text = __('确认')}))
    conditionSelectStateLayer:addChild(confirmBtn)

    -- edit team condition bg
    local editTeamCondBgSize = cc.size(442, display.height - conditionSelectStateLayerSize.height + 26)
    local editTeamCondBg = display.newLayer(display.SAFE_R - conditionSelectStateLayerSize.width / 2, conditionSelectStateLayerSize.height - 26, {ap = display.CENTER_BOTTOM, size = editTeamCondBgSize})
	editTeamCondBg:addChild(display.newImageView(RES_DIR.BG_CONDITION, editTeamCondBgSize.width / 2, editTeamCondBgSize.height / 2, {ap = display.CENTER, scale9 = true, size = editTeamCondBgSize}))
    view:addChild(editTeamCondBg, 1)
    -- logInfo.add(5, tableToString(editTeamCondBgSize))

	-- condition reward bg
	local conditionRewardBg = display.newLayer(editTeamCondBgSize.width / 2, editTeamCondBgSize.height - 94, {ap = display.CENTER, bg = RES_DIR.BG_CONCDITION_PRIZE})
	local conditionRewardBgSize = conditionRewardBg:getContentSize()
    editTeamCondBg:addChild(conditionRewardBg)
    

    -- local conditionRewardSpine = sp.SkeletonAnimation:create('effects/chooseBattle/bd2.json',
    -- 'effects/chooseBattle/bd2.atlas',1)
    -- conditionRewardSpine:setPosition(cc.p(conditionRewardBgSize.width / 2, 500))
    -- editTeamCondBg:addChild(conditionRewardSpine)
    -- conditionRewardSpine:setAnimation(0, 'play', false)

    local searchLightLayerSize = cc.size(134, 134)
    local searchLightLayer = display.newLayer(conditionRewardBgSize.width - 23, conditionRewardBgSize.height - 24, {ap = display.CENTER, size = cc.size(134, 134)})
    conditionRewardBg:addChild(searchLightLayer)
    local searchLight = display.newImageView(RES_DIR.ICO_SEARCH_LIGHT, searchLightLayerSize.width  / 2, conditionRewardBgSize.height / 2, {ap = display.CENTER})
    searchLightLayer:addChild(searchLight)
	-- search btn
    local searchBtn = display.newButton(searchLightLayerSize.width  / 2, conditionRewardBgSize.height / 2, {ap = display.CENTER, n = RES_DIR.RAID_BOSS_BTN_SEARCH})
    searchLightLayer:addChild(searchBtn)


	local conditionRewardTitle = display.newButton(0, 0, {n = RES_DIR.TITLE, animation = false})
    display.commonUIParams(conditionRewardTitle, {po = cc.p(conditionRewardBgSize.width * 0.5, conditionRewardBgSize.height - 20)})
    display.commonLabelParams(conditionRewardTitle, {text = __('当前奖励'), fontSize = 22, color = '#5b3c25'})
    conditionRewardBg:addChild(conditionRewardTitle)

    local curRewardLayer = display.newLayer(conditionRewardBgSize.width / 2, 50, {ap = display.CENTER, size = cc.size(conditionRewardBgSize.width, 100)})
    conditionRewardBg:addChild(curRewardLayer)

	local reachConditionLabel = display.newLabel(120, editTeamCondBgSize.height - 182, fontWithColor(5, {ap = display.CENTER, text = __('达成条件'), color = '#5b3c25'}))
    editTeamCondBg:addChild(reachConditionLabel)
    
	-- reach condition bg
	local reachConditionBg = display.newImageView(RES_DIR.LABEL_TITLE, 11, editTeamCondBgSize.height - 214, {ap = display.LEFT_CENTER})
	local reachConditionBgSize = reachConditionBg:getContentSize()
	editTeamCondBg:addChild(reachConditionBg)

	-- reach condition count label
	local reachConditionCountLabel = display.newLabel(reachConditionBgSize.width / 2, reachConditionBgSize.height / 2, fontWithColor(5, {color = '#ffffff', ap = display.CENTER}))
	reachConditionBg:addChild(reachConditionCountLabel)

	-- cancel btn
	local cancelBtn = display.newButton(conditionRewardBg:getPositionX() + conditionRewardBgSize.width / 2, editTeamCondBgSize.height - 200, {color = '#5b3c25', ap = display.RIGHT_CENTER, n = RES_DIR.BTN_WHITE_DEFAULT, scale9 = true , size = cc.size(170, 60 )})
	display.commonLabelParams(cancelBtn, fontWithColor(5, {text = __('取消选择')}))
    local cancelBtnLabel = cancelBtn:getLabel()
    local cancelBtnLabelSize = display.getLabelContentSize(cancelBtnLabel)
    if cancelBtnLabelSize.width > 170  then
        display.commonLabelParams(cancelBtn, fontWithColor(5, {fontSize = 20, w = 165, hAlign = display.TAC ,  text = __('取消选择')}))
    end
    editTeamCondBg:addChild(cancelBtn)
    cancelBtn:setVisible(false)

    editTeamCondBg:addChild(display.newLabel(editTeamCondBgSize.width / 2, editTeamCondBgSize.height - 254, fontWithColor(5, {color = '#5b3c25', ap = display.CENTER, text = __('达成更多条件可获得更多奖励'), w = 345, hAlign = display.TAC})))

    local conditionListBgSize = cc.size(401, editTeamCondBgSize.height - 300)
    local conditionListBg = display.newLayer(editTeamCondBgSize.width / 2, editTeamCondBgSize.height - 280, {ap = display.CENTER_TOP, size = conditionListBgSize})
    conditionListBg:addChild(display.newImageView(RES_DIR.BG_CONDITION_LIST, conditionListBgSize.width / 2, conditionListBgSize.height / 2, {ap = display.CENTER, scale9 = true, size = conditionListBgSize}))
    editTeamCondBg:addChild(conditionListBg)
    
    local col = 1
	local gridViewCellSize = cc.size(conditionListBgSize.width / col, 100)
    local gridView = CGridView:create(conditionListBgSize)
    gridView:setAnchorPoint(display.CENTER)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setPosition(cc.p(conditionListBgSize.width / 2, conditionListBgSize.height / 2))
    gridView:setColumns(col)
    conditionListBg:addChild(gridView)

    return {
        view                     = view,
        searchLightLayer         = searchLightLayer,
        searchLight              = searchLight,
        curRewardLayer           = curRewardLayer,
        reachConditionCountLabel = reachConditionCountLabel,
        confirmBtn               = confirmBtn,
        searchBtn                = searchBtn,
        cancelBtn                = cancelBtn,
        gridView                 = gridView,
    }
end

CreateCell = function ()
    local cell = CGridViewCell:new()
    local size = cc.size(401, 100)
    cell:setContentSize(size)
    
    local bg = display.newImageView(RES_DIR.BG_CELL_INACTIVE, 0, 0, {ap = display.LEFT_BOTTOM})
    local bgSize = bg:getContentSize()
    local bgLayer = display.newLayer(size.width / 2, size.height / 2, {size = bgSize, ap = display.CENTER})
    cell:addChild(bgLayer)
    bgLayer:addChild(bg)

    local icon = display.newImageView(_res('ui/exploreSystem/icon/explor_term_battle_level_1.png'), 34, bgSize.height / 2, {ap = display.CENTER})
    bgLayer:addChild(icon)

    local descLabel = display.newLabel(65, bgSize.height / 2, fontWithColor(5, {hAlign = display.TAL, ap = display.LEFT_CENTER, w = 265}))
    bgLayer:addChild(descLabel)

    local conditionSatisfyImg = display.newImageView(RES_DIR.ICO_MARK_EMPTY, bgSize.width - 35, bgSize.height / 2, {ap = display.CENTER})
    bgLayer:addChild(conditionSatisfyImg)

    local touchLayer = display.newLayer(bgSize.width / 2, bgSize.height / 2, {size = bgSize, ap = display.CENTER, enable = true, color = cc.c4b(0,0,0,0)})
    bgLayer:addChild(touchLayer)

    cell.viewData = {
        bg                  = bg,
        icon                = icon,
        descLabel           = descLabel,
        touchLayer          = touchLayer,
        conditionSatisfyImg = conditionSatisfyImg,
    }
    return cell
end

function ExploreSystemConditionView:getViewData()
	return self.viewData_
end

--[[
注册信号回调
--]]
function ExploreSystemConditionView:RegisterSignal()

	------------ 更新探索达成条件 ------------
    appFacadeIns:RegistObserver(UPDATE_QUEST_REACH, mvc.Observer.new(function (_, signal)
        local data = signal:GetBody() or {}
        self:refreshUI(data)
	end, self))
	------------ 更新探索达成条件 ------------
	
end
--[[
注销信号
--]]
function ExploreSystemConditionView:UnRegistSignal()
	
	appFacadeIns:UnRegistObserver(UPDATE_QUEST_REACH, self)
	
end

function ExploreSystemConditionView:onCleanup()
	-- 注销信号
    self:UnRegistSignal()
    
    local viewData = self:getViewData()
    local conditionRewardView = viewData.conditionRewardView
    if conditionRewardView and not tolua.isnull(conditionRewardView) then
        uiMgr:GetCurrentScene():RemoveDialog(conditionRewardView)
    end
end

return ExploreSystemConditionView