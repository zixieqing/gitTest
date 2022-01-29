--[[
 * descpt : 探索视图
]]
local VIEW_SIZE = display.size
local GameScene = require('Frame.GameScene')
local ExploreSystemView = class('ExploreSystemView', GameScene)

local appFacadeIns     = AppFacade.GetInstance()
local uiMgr            = appFacadeIns:GetManager("UIManager")
local exploreSystemMgr = appFacadeIns:GetManager("ExploreSystemManager")

local CreateView = nil
local CreateCell_ = nil
local CreateBasicsRewardCell = nil
local CreateStar = nil
local CreateCellSpine = nil

local RES_DIR = {
    BACK                             = _res("ui/common/common_btn_back"),
    TITLE                            = _res('ui/common/common_title.png'),
    TITLE_5                          = _res('ui/common/common_title_5.png'),
    BTN_TIPS                         = _res('ui/common/common_btn_tips.png'),
    BTN_ORANGE                       = _res('ui/common/common_btn_orange.png'),
    BTN_GREEN                        = _res('ui/common/common_btn_green.png'),
    
    BASE_EDIT_BG                     = _res('ui/exploreSystem/explor_base_bg_left_edit.png'),
    BASE_BG_PRIZE_1                  = _res('ui/exploreSystem/explor_base_bg_prize_1.png'),
    BASE_BG_PRIZE_2                  = _res('ui/exploreSystem/explor_base_bg_prize_2.png'),
    BASE_BG                          = _res('ui/exploreSystem/explor_base_bg.png'),
    
    LIST_BG_BLANK                    = _res('ui/exploreSystem/explor_list_bg_blank.png'),
    LIST_BG_BTN_STATE                = _res('ui/exploreSystem/explor_list_bg_btn_state.png'),
    LIST_BG_INSIDE                   = _res('ui/exploreSystem/explor_list_bg_inside.png'),
    LIST_BG_LIST_ACTIVE              = _res('ui/exploreSystem/explor_list_bg_list_active.png'),
    LIST_BG_LIST_DEFAULT             = _res('ui/exploreSystem/explor_list_bg_list_default.png'),
    LIST_BG_LIST_FINISH              = _res('ui/exploreSystem/explor_list_bg_list_finish.png'),
    LIST_BG_MASK                     = _res('ui/exploreSystem/explor_list_bg_mask.png'),
    LIST_BG                          = _res('ui/exploreSystem/explor_list_bg.png'),
    LIST_ICO_STAR                    = _res('ui/exploreSystem/explor_list_ico_star.png'),
    LIST_BG_SELECTED                 =  _res('ui/mail/common_bg_list_selected.png'),

    ICO_QUICK_RECOVERY               = _res('ui/home/lobby/cooking/refresh_ico_quick_recovery.png'),
}

local BUTTON_TAG = {
    BACK               = 100,   -- 返回
    RULE               = 101,   -- 规则
    EDIT               = 102,   -- 编辑队伍 或 领取奖励
    EXPLORE            = 103,   -- 探索 或 撤退
    ACCELERATE_EXPLORE = 104,   -- 快速探索
}

local BASIC_REWARD_CONFS = {
    {fieldName = 'cardExp', goodsId = CARD_EXP_ID},
    {fieldName = 'mainExp', goodsId = EXP_ID},
    {fieldName = 'gold',    goodsId = GOLD_ID},
}

function ExploreSystemView:ctor( ... )
    
    self.args = unpack({...})
    self:initialUI()
end

function ExploreSystemView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

function ExploreSystemView:refreshUI(datas)

    -- 更新下一订单刷新时间
    self:updateNextOrderRefreshTime(datas.nextRefreshTime)

    -- 更新订单列表
    self:updateList(datas.questList)

    -- 更新剩余团队个数
    self:updateLeftTeamCount(datas.totalTeam, datas.surplusTeam)
end

function ExploreSystemView:updateAllCountdown(datas)
    local nextRefreshTime = datas.nextRefreshTime
    self:updateNextOrderRefreshTime(nextRefreshTime)

    local questList = datas.questList
    self:updateListCountdown(questList)
end

--[[
更新下一订单刷新时间
@params nextRefreshTime int 下一单刷新时间剩余秒数
--]]
function ExploreSystemView:updateNextOrderRefreshTime(nextRefreshTime)
    local viewData      = self:getViewData()
    local nextTimeLabel = viewData.nextTimeLabel
    display.commonLabelParams(nextTimeLabel, {text = CommonUtils.getTimeFormatByType(checkint(nextRefreshTime))})
end

function ExploreSystemView:updateListCountdown(questList)
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    local cells = gridView:getCells()

    if cells and #cells > 0 then
        for i, cell in ipairs(cells) do
            local index     = cell:getTag()
            local viewData  = cell.viewData
            local questData = questList[index]
            self:updateQuestStatus(viewData, questData)
        end
    end
end

--[[
更新订单列表
@params questList table 探索列表数据
--]]
function ExploreSystemView:updateList(questList)
    questList = questList or {}
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    gridView:setCountOfCell(#questList)
	gridView:reloadData()
end

--[[
更新剩余团队个数
@params totalTeam   int 总团队数
@params surplusTeam int 剩余团队数
--]]
function ExploreSystemView:updateLeftTeamCount(totalTeam, surplusTeam)
    local viewData      = self:getViewData()
    local leftTeamCount = viewData.leftTeamCount
    display.commonLabelParams(leftTeamCount, {text = string.format('%s/%s', checkint(surplusTeam), checkint(totalTeam))}) 
end

--[[
更新条件奖励
@params basicsRewardCell userData 基础奖励Cell
@params data             table    订单数据
--]]
function ExploreSystemView:updateConditionReward(viewData, conditionReward, teamData)
    local conditionRewardLayer         = viewData.conditionRewardLayer
    local conditionRewardEmptyTipLayer = viewData.conditionRewardEmptyTipLayer

    conditionReward = conditionReward or {}

    local extraReward = conditionReward.extraReward or {}
    
    -- 团队数据不是空的 并且 附加奖励 不是空的
    local isShowConditionReward = next(extraReward) ~= nil
    conditionRewardLayer:setVisible(isShowConditionReward)
    conditionRewardEmptyTipLayer:setVisible(not isShowConditionReward)

    if isShowConditionReward then
        
        local conditionGoodsNodes = viewData.conditionGoodsNodes
        local condGoodNodeCount = #conditionGoodsNodes
        local extraRewardCount = #extraReward
        local ergodicTimes = math.max(condGoodNodeCount, extraRewardCount)
        
        local scale = 0.8
        local callBack = function(sender)
            uiMgr:ShowInformationTipsBoard({ targetNode = sender, iconId = sender.goodId, type = 1 })
        end

        local showIndexs = {}
        for i = 1, ergodicTimes do
            local goodNode    = conditionGoodsNodes[i]
            local extraReward = extraReward[i]

            if extraReward then
                if goodNode then
                    goodNode:setVisible(true)
                    goodNode:RefreshSelf(extraReward)
                else
                    local goodNode = require('common.GoodNode').new({id = extraReward.goodsId, amount = extraReward.num, showAmount = true, callBack = callBack})
                    goodNode:setScale(scale)
                    conditionRewardLayer:addChild(goodNode)
                    table.insert(conditionGoodsNodes, goodNode)
                end
                table.insert(showIndexs, i)
            else
                if goodNode then
                    goodNode:setVisible(false)
                end
            end
        end

        local goodNodeSize = nil
        local conditionRewardLayerSize = conditionRewardLayer:getContentSize()
        local midPointX = conditionRewardLayerSize.width / 2
        local midPointY = conditionRewardLayerSize.height / 2
        local showIndexCount = #showIndexs
        for i, index in ipairs(showIndexs) do
            local node = conditionGoodsNodes[i]
            if goodNodeSize == nil then
                goodNodeSize = node:getContentSize()
            end
            local pos = CommonUtils.getGoodPos({index = index, goodNodeSize = goodNodeSize, scale = scale, midPointX = midPointX, midPointY = midPointY, col = showIndexCount, maxCol = 3, goodGap = 10})
            display.commonUIParams(node, {po = pos})
        end
    end
end

--[[
更新所有的基础奖励Cell
@params rewardDatas table 基础奖励
--]]
function ExploreSystemView:updateBasicsRewardCells(conf)
    local viewData = self:getViewData()
    local basicsRewardLayer = viewData.basicsRewardLayer
    local basicsSize = basicsRewardLayer:getContentSize()
    local basicsRewardCells = viewData.basicsRewardCells
    local rewardTotalCount = #BASIC_REWARD_CONFS
    local showCount = 1
    for i = 1, rewardTotalCount do
        local basicRewardConf = BASIC_REWARD_CONFS[i]
        local rewardCount = checkint(conf[basicRewardConf.fieldName])
        local isShowCell = rewardCount > 0

        if basicsRewardCells[i] == nil then
            local basicsRewardCell = CreateBasicsRewardCell()
            display.commonUIParams(basicsRewardCell, {ap = display.CENTER_TOP})
            basicsRewardLayer:addChild(basicsRewardCell)
            
            display.commonUIParams(basicsRewardCell.viewData.iconTouchLayer, {cb = handler(self, self.onClickIconAction)})

            basicsRewardCells[i] = basicsRewardCell
        end

        basicsRewardCells[i]:setVisible(isShowCell)
        if isShowCell then
            self:updateBasicsRewardCell(basicsRewardCells[i], basicRewardConf, rewardCount)
            display.commonUIParams(basicsRewardCells[i], {po = cc.p(basicsSize.width / 2, (rewardTotalCount + 1 - showCount) / rewardTotalCount * basicsSize.height)})
            showCount = showCount + 1
            basicsRewardCells[i].viewData.iconTouchLayer:setTag(basicRewardConf.goodsId)
        end
    end
end

--[[
更新基础奖励Cell
@params cell    userdata cell视图
@params basicRewardConf table 基础奖励配置
@params num   int 奖励数值
--]]
function ExploreSystemView:updateBasicsRewardCell(cell, basicRewardConf, num)
    local viewData     = cell.viewData
    
    local icon         = viewData.icon
    local goodsId      = checkint(basicRewardConf.goodsId)
    local img          = CommonUtils.GetGoodsIconPathById(goodsId)
    icon:setTexture(img)
    icon:setTag(goodsId)
 
    local rewardCount  = viewData.rewardCount
    display.commonLabelParams(rewardCount, {text = tostring(num)})
end

--[[
更新Cell
@params viewData table cell视图数据
@params data     table 探索订单数据
--]]
function ExploreSystemView:updateCell(viewData, data)
    local emptyOrderBg           = viewData.emptyOrderBg
    local orderLayer             = viewData.orderLayer
    
    local isEmptyOrder = next(data) == nil
    emptyOrderBg:setVisible(isEmptyOrder)
    orderLayer:setVisible(not isEmptyOrder)
    if isEmptyOrder then return end

    local status = checkint(data.status)
    if status ~= exploreSystemMgr.QUEST_STATE.CLOSE then
        local confData = data.confData or {}
        local rewards = confData.rewards or {}
        local goodsNode              = viewData.goodsNode
        if next(rewards) ~= nil then
            goodsNode:RefreshSelf(rewards[1])
        else
            logInfo.add(5, "data error")
            logInfo.add(5, tableToString(data))
        end
        
        local titleLabel             = viewData.titleLabel
        display.commonLabelParams(titleLabel, {text = tostring(confData.name)})
        
        self:updateCellStar(viewData, confData)
    end
    
    self:updateQuestStatus(viewData, data)

end

function ExploreSystemView:updateQuestStatus(viewData, data)
    local confData = data.confData or {}
    local cardsNum = checkint(confData.cardsNum)

    local bgListActive           = viewData.bgListActive
    local bgListDefault          = viewData.bgListDefault
    local bgListFinish           = viewData.bgListFinish
    
    bgListActive:setVisible(false)
    bgListDefault:setVisible(false)
    bgListFinish:setVisible(false)

    local nextRefreshTimeLabel   = viewData.nextRefreshTimeLabel
    local orderCompleteTimeLabel = viewData.orderCompleteTimeLabel
    nextRefreshTimeLabel:setVisible(false)

    local spine = viewData.spine
    
    local status = checkint(data.status)
    if status == exploreSystemMgr.QUEST_STATE.PREPARE then
        
        self:updateSpineRunState(viewData, cardsNum, false)
        bgListDefault:setVisible(true)
        nextRefreshTimeLabel:setVisible(true)
        local refreshTime = checkint(data.refreshTime)
        self:updateNextRefreshTimeLabel(nextRefreshTimeLabel, refreshTime)
        local completeTime = checkint(confData.completeTime)
        self:updateOrderCompleteTimeLabel(orderCompleteTimeLabel, completeTime)

    elseif status ==  exploreSystemMgr.QUEST_STATE.ONGOING then

        self:updateSpineRunState(viewData, cardsNum, true)
        local completeTime = checkint(data.completeTime)
        self:updateOrderCompleteTimeLabel(orderCompleteTimeLabel, completeTime)
        bgListActive:setVisible(true)

    elseif status ==  exploreSystemMgr.QUEST_STATE.END then
        
        self:updateSpineRunState(viewData, cardsNum, false)
        bgListFinish:setVisible(true)
        display.commonLabelParams(orderCompleteTimeLabel, {color = '#e65f15', text = __('探索完成')})

    else
        self:updateSpineRunState(viewData, cardsNum, false)
        
        local emptyOrderBg = viewData.emptyOrderBg
        local orderLayer   = viewData.orderLayer
        local isEmptyOrder = true
        emptyOrderBg:setVisible(isEmptyOrder)
        orderLayer:setVisible(not isEmptyOrder)
    end
end

function ExploreSystemView:updateSpineRunState(viewData, cardsNum, isRun)
    local spines = viewData.spines

    local spineCount = #spines

    local count = math.max(spineCount, cardsNum)

    local runSpine = function (spine)
        spine:update(0)
        spine:setToSetupPose()
        if isRun then
            spine:setAnimation(0, 'run', true)
        else
            spine:setAnimation(0, 'idle', false)
        end
    end

    for i = 1, count do
        local spine = spines[i]

        if spine then
            -- spine:addAnimation(0, 'run', true)
            if i > cardsNum then
                spine:setVisible(false)
                spine:setAnimation(0, 'idle', false)
            else
                spine:setVisible(true)
                runSpine(spine)
            end
        else
            if i <= cardsNum then
                local orderLayer = viewData.orderLayer
                local spine = CreateCellSpine()
                display.commonUIParams(spine, {po = cc.p(15 + (i - 1) * 22, 5)})
                orderLayer:addChild(spine)
                runSpine(spine)

                table.insert(spines, spine)
            end
        end

    end
end

function ExploreSystemView:updateNextRefreshTimeLabel(nextRefreshTimeLabel, refreshTime)
    display.commonLabelParams(nextRefreshTimeLabel, {text = string.format(__("%s后消失"), CommonUtils.getTimeFormatByType(refreshTime))})
end

function ExploreSystemView:updateOrderCompleteTimeLabel(orderCompleteTimeLabel, completeTime)
    display.commonLabelParams(orderCompleteTimeLabel, {color = '#4a4a4a', text = CommonUtils.getTimeFormatByType(completeTime, 3)})
end

--[[
更新Cell难度星级
@params viewData table cell视图数据
@params confData table 探索订单配表数据
--]]
function ExploreSystemView:updateCellStar(viewData, confData)
    local starLayer  = viewData.starLayer
    local stars      = viewData.stars
    local starLayerChildCount = starLayer:getChildrenCount()
    local starLayerSize = starLayer:getContentSize()
    local difficulty = checkint(confData.difficulty)
    if starLayerChildCount == 0 then
        for i = 1, difficulty do
            local star = CreateStar()
            local starSize = star:getContentSize()
            display.commonUIParams(star, {po = cc.p((i - 1) * starSize.width, starLayerSize.height / 2)})
            starLayer:addChild(star)
            table.insert(stars, star)
        end
    else
        local maxStarCount = math.max(5, difficulty)
        for i = 1, maxStarCount do
            local star = stars[i]
            if i <= difficulty then
                if star then
                    star:setVisible(true)
                else
                    local star = CreateStar()
                    local starSize = star:getContentSize()
                    display.commonUIParams(star, {po = cc.p((i - 1) * starSize.width, starLayerSize.height / 2)})
                    starLayer:addChild(star)
                    table.insert(stars, star)
                end
            else
                if star then
                    star:setVisible(false)
                end
            end
        end
    end

end

--[[
通过cell index 更新Cell选中状态
@params index int cell 下标
@params isSelect bool 是否选中
--]]
function ExploreSystemView:updateCellSelectStateByIndex(index, isSelect)
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    local cell = gridView:cellAtIndex(index - 1)
    if cell then
        self:updateCellSelectState(cell.viewData, isSelect)
    end
end

--[[
更新Cell选中状态
@params viewData table cell视图数据
@params isSelect bool 是否选中
--]]
function ExploreSystemView:updateCellSelectState(viewData, isSelect)
    local selectFrame            = viewData.selectFrame
    selectFrame:setVisible(isSelect)
end

--[[
更新订单信息
@params data table 订单数据
--]]
function ExploreSystemView:updateOrderInfo(data)
    local status = checkint(data.status)

    local viewData               = self:getViewData()
    
    local teamData = nil
    local conditionReward = nil
    local confData = nil

    if status == exploreSystemMgr.QUEST_STATE.CLOSE then
        teamData = {}
        conditionReward = {}
        confData = {}
    else
        teamData = data.teamData
        confData = data.confData or {}
        
        local conditionRewardList = data.conditionRewardList or {}
        local curRewardIndex = data.curRewardIndex
        conditionReward = conditionRewardList[curRewardIndex] or {extraReward = confData.rewards}
    end

    self:updateBgRunState(data)
    self:updateBtnState(data)
    self:updateCards(viewData, teamData, status, confData.cardsNum)
    self:updateConditionReward(viewData, conditionReward, teamData)
    self:updateBasicsRewardCells(confData)
end

function ExploreSystemView:updateBgRunState(data)
    local status     = checkint(data.status)
    local confData   = data.confData or {}
    local photo      = checkint(confData.photo)
    local questState = exploreSystemMgr.QUEST_STATE

    local viewData   = self:getViewData()
    local explorationView     = viewData.explorationView
    
    if status == questState.ONGOING then
        self:runBg(explorationView, photo)
    else
        self:pauseBg(explorationView, photo)
    end

end
    
--[[
更新按钮状态
@params data table 订单数据
--]]
function ExploreSystemView:updateBtnState(data)
    local status                 = checkint(data.status)
    local viewData               = self:getViewData()
    local actionBtns             = viewData.actionBtns
    local exploreBtn             = actionBtns[tostring(BUTTON_TAG.EXPLORE)]
    local editBtn                = actionBtns[tostring(BUTTON_TAG.EDIT)]
    local accelerateExploreLayer = viewData.accelerateExploreLayer
    local btnLabel               = exploreBtn:getChildByName('btnLabel')

    editBtn:setVisible(false)
    accelerateExploreLayer:setVisible(false)

    local exploreBtnEnable = false
    local btnLabelText = ''
    if status == exploreSystemMgr.QUEST_STATE.CLOSE then
        exploreBtnEnable = false
        -- exploreBtn:setEnabled(false)

        btnLabelText = __('探索')
        editBtn:setVisible(true)
    else
        if status == exploreSystemMgr.QUEST_STATE.PREPARE then
            exploreBtnEnable = data.isCanQuest
            btnLabelText = __('探索')
            -- exploreBtn:setEnabled(data.isCanQuest)
            editBtn:setVisible(true)
            display.commonLabelParams(editBtn, {text = __('编辑队伍')})
        elseif status ==  exploreSystemMgr.QUEST_STATE.ONGOING then
            btnLabelText = __('撤退')
            -- exploreBtn:setEnabled(true)
            exploreBtnEnable = true
            accelerateExploreLayer:setVisible(true)

            self:updateAccelerateExploreLayer(viewData, data)
    
        elseif status ==  exploreSystemMgr.QUEST_STATE.END then
            btnLabelText = __('完成')

            editBtn:setVisible(true)
            exploreBtnEnable = false
            -- exploreBtn:setEnabled(false)
            display.commonLabelParams(editBtn, {text = __('领取')})
        end
    end

    exploreBtn:setNormalImage(exploreBtnEnable and _res('ui/common/mb.png') or _res('ui/common/common_btn_explore_disabled.png'))
    exploreBtn:setDisabledImage(exploreBtnEnable and _res('ui/common/mb_g.png') or _res('ui/common/common_btn_explore_disabled.png'))
    exploreBtn.battleSpine_:setVisible(exploreBtnEnable == true)

    display.commonLabelParams(btnLabel, {text = btnLabelText , reqW = 130})
end

--[[
更新秒探索层
@params viewData table 视图数据
@params data int 剩余时间
--]]
function ExploreSystemView:updateAccelerateExploreLayer(viewData, data)
    local leftTimeLabel          = viewData.leftTimeLabel
    local consumeNum             = viewData.consumeNum
    
    local leftSeconds            = data.completeTime
    local confData               = data.confData or {}
    local accelerateConsume      = confData.accelerateConsume or {}
    local goodsId                = checkint(accelerateConsume.goodsId)
    local num                    = checkint(accelerateConsume.num)

    display.commonLabelParams(leftTimeLabel, {text = CommonUtils.getTimeFormatByType(leftSeconds)})
    
    display.reloadRichLabel(consumeNum, {c = {
        fontWithColor('14',{text = num * math.ceil(leftSeconds / 3600)}),
        {img = CommonUtils.GetGoodsIconPathById(goodsId), scale = 0.2}
    }})
end

--[[
更新卡牌数据
@params viewData table 视图数据
@params teamData table 团队数据
--]]
function ExploreSystemView:updateCards(viewData, teamData, status, cardsNum)
    local teamInfoView = viewData.teamInfoView

    teamInfoView:SetMaxCardNum(cardsNum or MAX_TEAM_MEMBER_AMOUNT)
    
    teamData = teamData or {}
    
    local callback = function ()
        if status == exploreSystemMgr.QUEST_STATE.ONGOING then
            teamInfoView:RunAvatarNodes()
        else
            teamInfoView:StopAvatarNodes()
        end
    end
    
    local avatarRunState = (status == exploreSystemMgr.QUEST_STATE.ONGOING) and 1 or 0
    teamInfoView:SetTeamData(teamData, callback, avatarRunState)
    
end

function ExploreSystemView:setTeamInfoViewShowState(isShow)
    local viewData = self:getViewData()
    local teamInfoView = viewData.teamInfoView
    teamInfoView:setVisible(checkbool(isShow))
end

function ExploreSystemView:pauseBg(explorationView, photo)
    explorationView:setPhoto(photo)
    explorationView:removeBgScheduler()
end

function ExploreSystemView:runBg(explorationView, photo)    
    explorationView:setPhoto(photo)
    explorationView:createBgScheduler()
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    view:addChild(display.newLayer(0, 0, {color = cc.c4b(0), enable = true}))
    -- view:addChild(display.newImageView(RES_DIR.BG, size.width / 2, size.height / 2, {ap = display.CENTER}))

    local explorationView = require( 'Game.views.exploreSystem.ExploreSystemBgView' ).new({photo = 1})
    view:addChild(explorationView)

    -- local oldExplorationView = require( 'Game.views.exploreSystem.ExploreSystemBgView' ).new({photo = 1})
    -- oldExplorationView:setVisible(false)
    -- view:addChild(oldExplorationView, 2)

    local actionBtns = {}
    ----------------------------------
    -- top 
    local topUILayer = display.newLayer()
    view:addChild(topUILayer, 10)

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DIR.BACK})
    topUILayer:addChild(backBtn)
    actionBtns[tostring(BUTTON_TAG.BACK)] = backBtn
    backBtn:setVisible(false)

    -- title button
    local titleBtn = display.newButton(display.SAFE_L + 120, size.height, {n = RES_DIR.TITLE, ap = display.LEFT_TOP})
    local titleBtnSize = titleBtn:getContentSize()
    display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('探索'), offset = cc.p(0, -10)}))
    topUILayer:addChild(titleBtn)
    actionBtns[tostring(BUTTON_TAG.RULE)] = titleBtn

    titleBtn:addChild(display.newImageView(RES_DIR.BTN_TIPS, titleBtnSize.width - 50, titleBtnSize.height / 2 - 10, {ap = display.CENTER}))

    ----------------------------------
    -- content 
    local contentUILayer = display.newLayer()
    view:addChild(contentUILayer, 1)

    -- TeamInfoView
    local teamInfoView = require('common.TeamInfoView').new({avatarOriPos = cc.p(display.SAFE_L + 110, size.height * 0.45), disableClick = true, disableConnectSkill = true})
    display.commonUIParams(teamInfoView,{po = display.center, ap = display.CENTER})
    contentUILayer:addChild(teamInfoView)

    local guideBtn = CommonUtils.GetGuideBtn('explore')
    display.commonUIParams(guideBtn,{po = cc.p(display.SAFE_R - 550 , display.height - 40), ap = display.CENTER})
    contentUILayer:addChild(guideBtn)

    ----------------------------------
    -- bottom 
    local bottomUILayer = display.newLayer()
    view:addChild(bottomUILayer, 10)
    
    local editTeamBg = display.newLayer(display.SAFE_L - 43, 2, {ap = display.LEFT_BOTTOM, bg = RES_DIR.BASE_EDIT_BG})
    local editTeamBgSize = editTeamBg:getContentSize()
    bottomUILayer:addChild(editTeamBg)

    local editBtn = display.newButton(editTeamBgSize.width / 2, editTeamBgSize.height / 2, {ap = display.CENTER, n = RES_DIR.BTN_ORANGE ,scale9 = true ,w =160,  hAlign = display.TAC ,   size = cc.size(170, 70)})
    display.commonLabelParams(editBtn, fontWithColor(14, {text = __('编辑队伍') ,reqW = 155}))
    editTeamBg:addChild(editBtn)
    actionBtns[tostring(BUTTON_TAG.EDIT)] = editBtn
    editBtn:setVisible(false)

    -- accelerate explore layer
    local accelerateExploreLayer = display.newLayer(editTeamBgSize.width / 2, editTeamBgSize.height / 2, {size = editTeamBgSize, ap = display.CENTER})
    editTeamBg:addChild(accelerateExploreLayer)

    accelerateExploreLayer:addChild(display.newLabel(editTeamBgSize.width / 2, editTeamBgSize.height - 30, fontWithColor(3, {text = __('剩余时间')})))
    
    local leftTimeLabel = display.newLabel(editTeamBgSize.width / 2, editTeamBgSize.height - 60, fontWithColor(14, {text = '00:00:00'}))
    accelerateExploreLayer:addChild(leftTimeLabel)

    local accelerateExploreBtn = display.newButton(editTeamBgSize.width / 2, 60, {ap = display.CENTER, n = RES_DIR.BTN_GREEN})
    local accelerateExploreBtnSize = accelerateExploreBtn:getContentSize()
    accelerateExploreLayer:addChild(accelerateExploreBtn)
    actionBtns[tostring(BUTTON_TAG.ACCELERATE_EXPLORE)] = accelerateExploreBtn

    -- 一个小时一张票
    local consumeNum = display.newRichLabel(accelerateExploreBtnSize.width / 2, accelerateExploreBtnSize.height / 2, {ap = display.CENTER})
    accelerateExploreBtn:addChild(consumeNum)

    accelerateExploreLayer:setVisible(false)

    -- reward preview bg
    local rewardPreviewBg = display.newLayer(editTeamBg:getPositionX() + editTeamBgSize.width - 40, 0, {ap = display.LEFT_BOTTOM, bg = RES_DIR.BASE_BG})
    local rewardPreviewBgSize = rewardPreviewBg:getContentSize()
    bottomUILayer:addChild(rewardPreviewBg)

    local rewardTitleConfs = {
        {pos = cc.p(220, rewardPreviewBgSize.height - 30), titleName = __('条件奖励')},
        {pos = cc.p(rewardPreviewBgSize.width - 180, rewardPreviewBgSize.height - 30), titleName = __('基础奖励')},
    }

    for i, rewardTitleConf in ipairs(rewardTitleConfs) do
        local titleBg = display.newImageView(RES_DIR.TITLE_5, 0, 0, {ap = display.CENTER ,scale9 = true })
        local titleBgSize = titleBg:getContentSize()
        display.commonUIParams(titleBg, {po = rewardTitleConf.pos})
        rewardPreviewBg:addChild(titleBg)
        local titleLabel  =  display.newLabel(titleBgSize.width / 2, titleBgSize.height / 2, fontWithColor(5, {text = tostring(rewardTitleConf.titleName) , reqW = 200 }))
        local titleLabelSize = display.getLabelContentSize(titleLabel)
        titleLabelSize.width = titleLabelSize.width > 200 and 200  or titleLabelSize.width
        titleBgSize.width = titleBgSize.width > titleLabelSize.width+ 40 and titleBgSize.width  or titleLabelSize.width+ 40
        titleBg:setContentSize(titleBgSize)
        titleLabel:setPositionX(titleBgSize.width/2)
        titleBg:addChild(titleLabel)

    end

    -- condition reward bg
    local conditionRewardBg = display.newLayer(0, 0, {ap = display.CENTER, bg = RES_DIR.BASE_BG_PRIZE_2})
    local conditionRewardBgSize = conditionRewardBg:getContentSize()
    display.commonUIParams(conditionRewardBg, {po = cc.p(rewardTitleConfs[1].pos.x, rewardPreviewBgSize.height / 2 - 16)})
    rewardPreviewBg:addChild(conditionRewardBg)


    -- condition reward empty tip
    local conditionRewardEmptyTipLayer = display.newLayer(0, 0,{size = conditionRewardBgSize})
    conditionRewardBg:addChild(conditionRewardEmptyTipLayer)
    conditionRewardEmptyTipLayer:addChild(display.newLabel(conditionRewardBgSize.width / 2, conditionRewardBgSize.height / 2 + 5, fontWithColor(5, {color = '#513d27', ap = display.CENTER_BOTTOM, text = __('暂无奖励')})))
    conditionRewardEmptyTipLayer:addChild(display.newLabel(conditionRewardBgSize.width / 2, conditionRewardBgSize.height / 2 + 3, fontWithColor(5, {color = '#e0e0e0', ap = display.CENTER_TOP, text = __('(编辑队伍获取)')})))

    -- condition reward layer
    local conditionRewardLayer = display.newLayer(0, 0,{size = conditionRewardBgSize})
    conditionRewardBg:addChild(conditionRewardLayer)


    -- basics reward layer
    local basicsSize = cc.size(191, conditionRewardBgSize.height)
    local basicsRewardLayer = display.newLayer(rewardPreviewBgSize.width - 180, rewardPreviewBgSize.height / 2 - 16, {ap = display.CENTER, size = basicsSize})
    rewardPreviewBg:addChild(basicsRewardLayer)

    ----------------------------------
    -- right 
    local rightUILayer = display.newLayer()
    view:addChild(rightUILayer,10)

    local listBtnBgSize = cc.size(554, 180)
    local listBtnBg = display.newLayer(display.SAFE_R + 66, 0, {ap = display.RIGHT_BOTTOM, scale9 = true, size = listBtnBgSize, bg = RES_DIR.LIST_BG_BTN_STATE})
    rightUILayer:addChild(listBtnBg, 1)

    -- explore btn
    local exploreBtn = require('common.CommonBattleButton').new({pattern = 4})
    exploreBtn:setPosition(cc.p(listBtnBgSize.width / 2 - 5, listBtnBgSize.height - 76))
    actionBtns[tostring(BUTTON_TAG.EXPLORE)] = exploreBtn
    listBtnBg:addChild(exploreBtn)

    local leftTeamTip = display.newLabel(listBtnBgSize.width / 2 - 35, 14, fontWithColor(5, {ap = display.CENTER, color = '#ccb194', text = __('剩余可派队伍: ')}))
    local leftTeamTipSize = display.getLabelContentSize(leftTeamTip)
    listBtnBg:addChild(leftTeamTip)

    -- left team count
    local leftTeamCount = display.newLabel(leftTeamTip:getPositionX() + leftTeamTipSize.width / 2, leftTeamTip:getPositionY(), fontWithColor(5, {ap = display.LEFT_CENTER, color = '#ffffff', text = '0/0'}))
    listBtnBg:addChild(leftTeamCount)

    -- list bg layer
    local listBgLayerSize = cc.size(461, display.height)
    local listBgLayer = display.newLayer(listBtnBg:getPositionX() - listBtnBgSize.width / 2, 0, {ap = display.CENTER_BOTTOM, size = listBgLayerSize})
    listBgLayer:addChild(display.newImageView(RES_DIR.LIST_BG, listBgLayerSize.width / 2, listBgLayerSize.height / 2, {ap = display.CENTER, scale9 = true, size = listBgLayerSize}))
    rightUILayer:addChild(listBgLayer)

    local nextTimeBgSize = cc.size(383, 63)
    local nextTimeBg = display.newLayer(listBgLayerSize.width / 2, listBgLayerSize.height - 10, {ap = display.CENTER_TOP, size = nextTimeBgSize})
    listBgLayer:addChild(nextTimeBg)

    nextTimeBg:addChild(display.newLabel(nextTimeBgSize.width / 2, nextTimeBgSize.height / 2, fontWithColor(5, {reqW = 380 ,  ap = display.CENTER_BOTTOM, text = __('下批探索任务刷新时间')})))

    -- next time label
    local nextTimeLabel = display.newLabel(nextTimeBgSize.width / 2, nextTimeBgSize.height / 2, fontWithColor(5, {ap = display.CENTER_TOP, text = '--:--:--'}))
    nextTimeBg:addChild(nextTimeLabel)

    listBgLayer:addChild(display.newImageView(RES_DIR.LIST_BG_INSIDE, listBgLayerSize.width / 2, listBgLayerSize.height - 75, {ap = display.CENTER_TOP, scale9 = true}))

    local gridViewSize = cc.size(386, listBgLayerSize.height - listBtnBgSize.height - 23)
    local gridViewCellSize = cc.size(gridViewSize.width, 130)
    local gridView = CGridView:create(gridViewSize)
    gridView:setPosition(cc.p(listBgLayerSize.width / 2, listBgLayerSize.height - 75))
    gridView:setAnchorPoint(display.CENTER_TOP)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setColumns(1)
    listBgLayer:addChild(gridView)

    return {
        view                         = view,
        explorationView              = explorationView,
        -- oldExplorationView          = oldExplorationView,
        actionBtns                   = actionBtns,
        accelerateExploreLayer       = accelerateExploreLayer,
        leftTimeLabel                = leftTimeLabel,
        consumeNum                   = consumeNum,
        nextTimeLabel                = nextTimeLabel,
        leftTeamCount                = leftTeamCount,
        conditionRewardEmptyTipLayer = conditionRewardEmptyTipLayer,
        conditionRewardLayer         = conditionRewardLayer,
        basicsRewardLayer            = basicsRewardLayer,
        gridView                     = gridView,

        teamInfoView                 = teamInfoView,
        
        conditionGoodsNodes          = {},
        basicsRewardCells            = {},
    }
end

CreateCell_ = function ()
    local cell = CGridViewCell:new()
    local size = cc.size(385, 130)
    cell:setContentSize(size)

    local layerSize = cc.size(373, 127)
    local layer = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = layerSize})
    cell:addChild(layer)

    local touchLayer = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, enable = true, size = layerSize, color = cc.c4b(0,0,0,0)})
    cell:addChild(touchLayer)

    local emptyOrderBg = display.newImageView(RES_DIR.LIST_BG_BLANK, layerSize.width / 2, layerSize.height / 2, {ap = display.CENTER})
    layer:addChild(emptyOrderBg)
    emptyOrderBg:setVisible(false)

    local orderLayer = display.newLayer(layerSize.width / 2, layerSize.height / 2, {ap = display.CENTER, size = layerSize})
    layer:addChild(orderLayer)

    local bgListActive = display.newImageView(RES_DIR.LIST_BG_LIST_ACTIVE, layerSize.width / 2, layerSize.height / 2, {ap = display.CENTER})
    orderLayer:addChild(bgListActive)
    bgListActive:setVisible(false)

    local bgListDefault = display.newImageView(RES_DIR.LIST_BG_LIST_DEFAULT, layerSize.width / 2, layerSize.height / 2, {ap = display.CENTER})
    orderLayer:addChild(bgListDefault)
    -- bgListDefault:setVisible(false)

    local bgListFinish = display.newImageView(RES_DIR.LIST_BG_LIST_FINISH, layerSize.width / 2, layerSize.height / 2, {ap = display.CENTER})
    orderLayer:addChild(bgListFinish)
    bgListFinish:setVisible(false)

    local goodsNode = require('common.GoodNode').new({id = GOLD_ID})
    display.commonUIParams(goodsNode, {ap = display.LEFT_TOP, po = cc.p(5, layerSize.height - 5)})
    goodsNode:setScale(0.6)
    orderLayer:addChild(goodsNode)

    local titleLabel = display.newLabel(73, layerSize.height - 8, fontWithColor(5, {ap = display.LEFT_TOP, color = '#7b4c32', text = '新的一天'}))
    orderLayer:addChild(titleLabel)

    local starLayerSize = cc.size(layerSize.width / 2, 20)
    local starLayer = display.newLayer(73, layerSize.height - 45, {ap = display.LEFT_CENTER, size = starLayerSize})
    orderLayer:addChild(starLayer)

    local nextRefreshTimeLabel = display.newLabel(layerSize.width - 8, 34, fontWithColor(15, {ap = display.RIGHT_BOTTOM}))
    orderLayer:addChild(nextRefreshTimeLabel)

    local orderCompleteTimeLabel = display.newLabel(layerSize.width - 8, 18, fontWithColor(5, {ap = display.RIGHT_CENTER, color = '#e65f15'}))
    orderLayer:addChild(orderCompleteTimeLabel)
    
    -- local spineLayer = display.newLayer(x,y,params)
    -- local spine = sp.SkeletonAnimation:create(
    --     'ui/exploreSystem/spine/ren.json',
    --     'ui/exploreSystem/spine/ren.atlas',
    --     1
    -- )
    -- spine:update(0)
    -- -- spine:addAnimation(0, 'idle', true)
    -- spine:setPosition(cc.p(16, 3))
    -- orderLayer:addChild(spine, 10)

    -- select frame
    local selectFrame = display.newImageView(RES_DIR.LIST_BG_SELECTED, layerSize.width / 2, layerSize.height / 2, {ap = display.CENTER, scale9 = true, size = cc.size(layerSize.width + 7, layerSize.height + 7)})
    layer:addChild(selectFrame)
    selectFrame:setVisible(false)

    cell.viewData = {
        touchLayer             = touchLayer,
        emptyOrderBg           = emptyOrderBg,
        orderLayer             = orderLayer,
        bgListActive           = bgListActive,
        bgListDefault          = bgListDefault,
        bgListFinish           = bgListFinish,
        goodsNode              = goodsNode,
        titleLabel             = titleLabel,
        starLayer              = starLayer,
        nextRefreshTimeLabel   = nextRefreshTimeLabel,
        orderCompleteTimeLabel = orderCompleteTimeLabel,
        selectFrame            = selectFrame,
        
        spines                 = {},
        stars                  = {},
    }

    return cell
end

--[[
    创建基础奖励Cell
]]
CreateBasicsRewardCell = function ()
    local basicsRewardLayer = display.newLayer(0, 0, {bg = RES_DIR.BASE_BG_PRIZE_1})
    local basicsRewardLayerSize = basicsRewardLayer:getContentSize()

    local iconScale = 0.2
    local icon = display.newImageView('', 50, basicsRewardLayerSize.height / 2, {ap = display.CENTER})
    local iconSize = icon:getContentSize()
    icon:setScale(iconScale)
    basicsRewardLayer:addChild(icon)

    local iconTouchLayer = display.newLayer(icon:getPositionX(), icon:getPositionY(), {ap = display.CENTER, size = cc.size(iconSize.width * iconScale, iconSize.height * iconScale), enable = true, color = cc.c4b(0,100,100,0)})
    basicsRewardLayer:addChild(iconTouchLayer)

    local rewardCount = display.newLabel(basicsRewardLayerSize.width - 66, basicsRewardLayerSize.height / 2, fontWithColor(14, {ap = display.CENTER}))
    basicsRewardLayer:addChild(rewardCount)

    basicsRewardLayer.viewData = {
        icon           = icon,
        iconTouchLayer = iconTouchLayer,
        rewardCount    = rewardCount,
    }
    return basicsRewardLayer
end

CreateStar = function ()
    local star = display.newImageView(RES_DIR.LIST_ICO_STAR, 0, 0, {ap = display.LEFT_CENTER})
    return star
end

CreateCellSpine = function ()
    local spine = sp.SkeletonAnimation:create(
        'ui/exploreSystem/spine/ren.json',
        'ui/exploreSystem/spine/ren.atlas',
        1
    )
    spine:update(0)
    return spine
end

function ExploreSystemView:showUI(data, oldData, callback)
    local viewData = self:getViewData()
    local explorationView     = viewData.explorationView
    local oldExplorationView = viewData.oldExplorationView

    local status     = checkint(data.status)
    local confData   = data.confData
    local photo      = checkint(confData.photo)
    local questState = exploreSystemMgr.QUEST_STATE

    local oldPhoto   = nil
    if oldData then
        local oldConfData   = oldData.confData
        if oldConfData then
            oldPhoto            = checkint(oldConfData.photo)
        end
    end
    explorationView:removeBgScheduler()

    local showActionUI = function ()
        local deltaTime = 0.35
        oldExplorationView:setVisible(true)
        self:runAction(cc.Sequence:create({
            cc.Spawn:create(
                cc.TargetedAction:create(oldExplorationView, cc.EaseIn:create(cc.MoveTo:create(deltaTime, cc.p(display.width, 0)), deltaTime)),
                cc.CallFunc:create(function()
                    if callback then
                        callback()
                    end
                end)
            ),
            cc.DelayTime:create(0.1),
            cc.CallFunc:create(function ()
                oldExplorationView:setVisible(false)
                oldExplorationView:setPosition(cc.p(0,0))

                if status == questState.ONGOING then
                    explorationView:createBgScheduler()
                end
            end)
        }))
    end

    if oldPhoto then
        explorationView:setPhoto(photo)
        oldExplorationView:setPhoto(oldPhoto)

        showActionUI()
    else
        if status == questState.ONGOING then
            explorationView:createBgScheduler()
        end
        if callback then
            callback()
        end
    end

    
end

function ExploreSystemView:onClickIconAction(sender)
    local goodsId = sender:getTag()
    uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = goodsId, type = 1})
end

function ExploreSystemView:CreateCell()
    return CreateCell_()
end

function ExploreSystemView:getViewData()
	return self.viewData_
end

return ExploreSystemView