--[[
 * descpt : 工会派对筹备 preview 界面
]]
local VIEW_SIZE = display.size
local UnionPartyPrepareTaskView = class('UnionPartyPrepareTaskView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.union.UnionPartyPrepareTaskView'
	node:enableNodeEvents()
	return node
end)

local UnionConfigParser  = require('Game.Datas.Parser.UnionConfigParser')
local PARTY_SIZE_CONFS   = CommonUtils.GetConfigAllMess(UnionConfigParser.TYPE.PARTY_SIZE, 'union') or {}
local UNION_LV_CONFS     = CommonUtils.GetConfigAllMess(UnionConfigParser.TYPE.LEVEL, 'union') or {}

local CreateView = nil
local CreateCell_ = nil
local CreatePartyTip_ = nil

local CreateChest_ = nil
local getChestPath = nil

local GRAY = cc.c3b(150, 150, 150)
local WHITE = cc.c3b(255, 255, 255)

local RES_DIR = {
    BG                   = _res("ui/union/party/prepare/guild_party_bg_ing.png"),
    TOTAL_INTEGRAL_BG    = _res("ui/union/party/prepare/guild_party_bg_total_integral.png"),
    BAR_ORANGE           = _res("ui/union/party/prepare/guild_party_bar.png"),
    BAR_BG               = _res("ui/union/party/prepare/guild_party_bar_bg.png"),
    INTEGRAL_BG          = _res("ui/union/party/prepare/guild_party_bg_rumber_integral.png"),
    LIST_BG              = _res("ui/union/party/prepare/guild_party_bg_black.png"),
    CELL_BG              = _res("ui/union/party/prepare/guild_party_bg_foods.png"),
    CELL_BG2             = _res("ui/union/party/prepare/guild_party_bg_foods_2.png"),
    CELL_BG_BLACK        = _res("ui/union/party/prepare/guild_party_bg_foods_black.png"),
    GRADE_IMG            = _res('ui/home/kitchen/cooking_grade_ico_4.png'),
    CELL_GOOD_BG         = _res("ui/airship/ship_ico_label_goods_tag.png"),
    ARROW                = _res("ui/common/common_arrow.png"),
    CURRENT_LEVEL_PARTY  = _res('ui/union/party/prepare/guild_party_bg_current_level_party.png'),
}

function UnionPartyPrepareTaskView:ctor( ... )
    self.args = unpack({...}) or {}
    self.partySizeData = {}
    local data = self.args.data or {}
    self:initialUI()
end

function UnionPartyPrepareTaskView:initialUI()
    xTry(function ( )
        
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)

	end, __G__TRACKBACK__)
end

function UnionPartyPrepareTaskView:refreshUI(submittedFoods, submitTotalFoodCount, unionLevel)
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    gridView:setCountOfCell(#submittedFoods)
    gridView:reloadData()

    self:initConfData(unionLevel)
    self:updatePrepareState(submitTotalFoodCount, unionLevel)
    
end

function UnionPartyPrepareTaskView:initConfData(unionLevel)
    if next(self.partySizeData) ~= nil then return end

    local unionLevel = unionLevel or 1

    local unionData = UNION_LV_CONFS[tostring(unionLevel)]
    local partyScore = checkint(unionData.partyScore)
    local viewData = self:getViewData()

    self.partySizeData = {}
    for i,v in pairs(PARTY_SIZE_CONFS) do
        local partyLv, percent, name = checkint(v.id), tonumber(v.percent), tostring(v.name)

        -- ui  宝箱写死 不根据配表控制宝箱 宝箱固定为4个
        local scaleProportion = (0.25 * partyLv) / percent
        local stageSocre = percent * partyScore
        self.partySizeData[tostring(partyLv)] = {scaleProportion = scaleProportion, stageSocre = stageSocre, name = name}
    end
    
    -- init ui action
    local chestLayers = viewData.chestLayers
    logInfo.add(4, tableToString(chestLayers))
    for i,chestLayer in ipairs(chestLayers) do
        local partyLv = checkint(chestLayer:getTag())
        local data = self.partySizeData[tostring(partyLv)]

        display.commonUIParams(chestLayer, {cb = function (sneder)
            local uiMgr    = AppFacade.GetInstance():GetManager('UIManager')
            uiMgr:ShowInformationTipsBoard({
                targetNode = chestLayer, type = 5, title = tostring(data.name), descr = {
                    fontWithColor(16, {text = __('积分达到')}),
                    fontWithColor(10, {text = tostring(data.stageSocre)}),
                    fontWithColor(16, {text = __('分可以开启该Party')}),
                }, richTextW = 20, isRich = true
            })
        end})
    end

    self.partyScore = partyScore
end

--==============================--
--desc:刷新箱子 
--time:2018-01-25 08:06:50
--@state: 1 全灰 2 半灰
--@return 
--==============================-- 
function UnionPartyPrepareTaskView:refreshChest(chestLayer, state)
    local chest = chestLayer:getChildByName('chest')
    local intervalBg = chestLayer:getChildByName('intervalBg')
    if chest == nil or intervalBg == nil then return end

    -- chestLayer:setTouchEnabled(false)
    if state == 1 then
        chest:setColor(GRAY)
        intervalBg:setColor(GRAY)
    elseif state == 2 then
        chest:setColor(GRAY)
        intervalBg:setColor(WHITE)
    else
        chest:setColor(WHITE)
        intervalBg:setColor(WHITE)
        -- chestLayer:setTouchEnabled(true)
        -- display.commonUIParams(chestLayer, handler(self, self.))
    end
end

function UnionPartyPrepareTaskView:updatePrepareState(submitTotalFoodCount, unionLevel)
    local viewData = self:getViewData()
    local partIntegralLabel = viewData.partIntegralLabel
    partIntegralLabel:setString(submitTotalFoodCount)

    local totalFoodCount = viewData.totalFoodCount
    display.reloadRichLabel(totalFoodCount, {c = {
        fontWithColor(16, {text = __('工会成员已筹备:')}),
        fontWithColor(10, {text = submitTotalFoodCount}),
        fontWithColor(16, {text = __('份')}),
    }})

    local unionLevel = unionLevel or 1

    -- local unionData = UNION_LV_CONFS[tostring(unionLevel)]
    local partyScore = self.partyScore
    -- todo 更新进度条
    self:updateProgress(submitTotalFoodCount, partyScore)
    -- todo 更新顶部显示
    self:updateChests(submitTotalFoodCount, partyScore)
end

function UnionPartyPrepareTaskView:updateProgress(submitTotalFoodCount, partyScore)
    -- 当前的缩放比例
    local curPartyLv         = 0
    local maxPartyLv         = 0
    local isStage            = false
    for partyLv, partySize in pairs(self.partySizeData) do
        local scaleProportion = tonumber(partySize.scaleProportion)
        local stageSocre = checkint(partySize.stageSocre)
        local lv = checkint(partyLv)
        if submitTotalFoodCount >= stageSocre and curPartyLv < lv then
            curPartyLv = lv
            isStage = submitTotalFoodCount == stageSocre
        end
        maxPartyLv = maxPartyLv + 1
    end
    
    local value = 0
    local scaleProportion = 0
    if isStage then
        scaleProportion = self.partySizeData[tostring(curPartyLv)].scaleProportion
    else
        local nextPartyLv = math.min(curPartyLv + 1, maxPartyLv)
        scaleProportion = self.partySizeData[tostring(nextPartyLv)].scaleProportion
    end
    value = submitTotalFoodCount * scaleProportion
    
    local progressBar = self:getViewData().progressBar
    progressBar:setMaxValue(self.partyScore)
    progressBar:setValue(value)

end

function UnionPartyPrepareTaskView:updateChests(submitTotalFoodCount, partyScore)
    local chestLayers = self:getViewData().chestLayers
    -- 当前阶段数据
    local curStageId = 0
    local curStageScore = 0
    local maxStageId = 0
    for i,chestLayer in ipairs(chestLayers) do
        local intervalBg = chestLayer:getChildByName('intervalBg')
        local intervalLabel = intervalBg:getChildByName('intervalLabel')
        
        local tag = chestLayer:getTag()
        local partySize = PARTY_SIZE_CONFS[tostring(tag)]
        local percent = tonumber(partySize.percent)
        local stageScore = --[[self.partySizeData[tostring(tag)].stageScore]] partyScore * percent
        display.commonLabelParams(intervalLabel, {text = stageScore})
        
        local partyTipBg = chestLayer:getChildByName('partyTipBg')
        partyTipBg:setVisible(false)
        -- 获取最大阶段id
        maxStageId = math.max(maxStageId, i)
        if stageScore > submitTotalFoodCount then
            self:refreshChest(chestLayer, 1)
        else
            if stageScore > curStageScore then
                curStageId = i
                curStageScore = stageScore
            end
            -- 总提交数 大于 每阶所需分数时  先 都变半灰
            self:refreshChest(chestLayer, 2)
        end
    end

    if curStageScore ~= 0 then
        local chestLayer = chestLayers[curStageId]
        local partyTipBg = chestLayer:getChildByName('partyTipBg')
        partyTipBg:setVisible(true)
        self:refreshChest(chestLayer)

        if curStageId == maxStageId then
            AppFacade.GetInstance():DispatchObservers(SGL.UNION_PARTY_PREPARE_REFRESH_UI)
        end
    end
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    local bgSize = cc.size(1315, 619)

    local bgImg = display.newImageView(RES_DIR.BG, display.cx, display.cy, {ap = display.CENTER})
    view:addChild(bgImg)
    
    local bg = display.newLayer(display.cx, display.cy - 50, {ap = display.CENTER, size = bgSize})
    -- local bgSize = bg:getContentSize()
    view:addChild(bg)

    -- 派对总积分
    local totalIntegralBg = display.newImageView(RES_DIR.TOTAL_INTEGRAL_BG, 30, bgSize.height - 100, {ap = display.LEFT_CENTER})
    local totalIntegralBgSize = totalIntegralBg:getContentSize()
    bg:addChild(totalIntegralBg)
    
    local partIntegral = display.newLabel(totalIntegralBgSize.width / 2, totalIntegralBgSize.height - 24, fontWithColor(14, {text = __('派对积分'), ap = display.CENTER, fontSize = 20, color = '#ffffff', outline = '#5b3c25', outlineSize = 1}))
    totalIntegralBg:addChild(partIntegral)

    local partIntegralLabel = display.newLabel(totalIntegralBgSize.width / 2, totalIntegralBgSize.height / 2 - 13, fontWithColor(14, {ap = display.CENTER, fontSize = 28, color = '#feac38', outline = '#5b3c25', outlineSize = 1}))
    totalIntegralBg:addChild(partIntegralLabel)

    -- 进度条
    local progressBar = CProgressBar:create(RES_DIR.BAR_ORANGE)
    progressBar:setBackgroundImage(RES_DIR.BAR_BG)
    progressBar:setPosition(cc.p(totalIntegralBg:getPositionX() + totalIntegralBgSize.width + 10, totalIntegralBg:getPositionY()))
    progressBar:setMaxValue(100)
    progressBar:setAnchorPoint(display.LEFT_CENTER)
    progressBar:setDirection(0)
    progressBar:setValue(0)
    bg:addChild(progressBar)

    -- 4个盒子
    local progressBarSize = progressBar:getContentSize()
    local chestSpace = progressBarSize.width / 4
    local chestStartX = progressBar:getPositionX() + chestSpace - 10
    local checstStartY = progressBar:getPositionY()
    local chestLayers = {}

    for i,partySize in pairs(PARTY_SIZE_CONFS) do
        local percent = tonumber(partySize.percent)
        -- local chestLayerPosx = progressBar:getPositionX() + percent * progressBarSize.width
        local chestLayer = CreateChest_(i, chestStartX + chestSpace * (i - 1), checstStartY, partySize.name)
        chestLayer:setTag(checkint(partySize.id))
        bg:addChild(chestLayer)
        chestLayers[checkint(partySize.id)] = chestLayer
    end

    local totalFoodCount = display.newRichLabel(bgSize.width - 22, bgSize.height - 160, {ap = display.RIGHT_CENTER})
    bg:addChild(totalFoodCount)
    
    -- local alreadyPrepareDesc = display.newLabel(bgSize.width - 22, bgSize.height - 160, fontWithColor(16, {ap = display.RIGHT_CENTER, text = '工会成员已筹备:      份'}))
    -- bg:addChild(alreadyPrepareDesc)

    -- list bg
    local listTitle = display.newButton(bgSize.width / 2, bgSize.height - 145, {n = _res('ui/common/common_title_5.png'), animation = false, ap = display.CENTER_TOP})
    local listTitleSize = listTitle:getContentSize()
    display.commonLabelParams(listTitle, fontWithColor(6, {text = __('筹备菜品')}))
    bg:addChild(listTitle)

    local listBgSize = cc.size(bgSize.width - 46, bgSize.height - 216)
    local listBgLayer = display.newLayer(bgSize.width / 2, listTitle:getPositionY() - listTitleSize.height - 3, {size = listBgSize, ap = display.CENTER_TOP})
    local listBg = display.newImageView(RES_DIR.LIST_BG, listBgSize.width / 2, listBgSize.height / 2, {size = listBgSize, scale9 = true, ap = display.CENTER})
    bg:addChild(listBgLayer)
    listBgLayer:addChild(listBg)

    local gridViewCellSize = cc.size(253, 145)
    local gridView = CGridView:create(cc.size(listBgSize.width - 6,listBgSize.height))
    gridView:setPosition(cc.p(listBgSize.width / 2, listBgSize.height / 2))
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setAnchorPoint(display.CENTER)
    gridView:setColumns(5)
    listBgLayer:addChild(gridView)

    local ruleLabel = display.newLabel(bgSize.width / 2, 10, fontWithColor(6, {ap = display.CENTER_BOTTOM, text = __('每筹备1道菜可增加1点派对积分，达到一定积分可提升派对等级。')}))
    bg:addChild(ruleLabel)
    
    return {
        view              = view,
        partIntegral      = partIntegral,
        partIntegralLabel = partIntegralLabel,
        progressBar       = progressBar,
        chestLayers       = chestLayers,
        totalFoodCount    = totalFoodCount,
        gridView          = gridView,
    }
end

CreateCell_ = function ()
    local cellSize = cc.size(253, 145)
    local cell = CGridViewCell:new()
    -- cell:setBackgroundColor(cc.c3b(100,100,200))
    cell:setContentSize(cellSize)

    local cellBg = display.newImageView(RES_DIR.CELL_BG, cellSize.width / 2, cellSize.height / 2, {ap = display.CENTER})
    cell:addChild(cellBg)
    
    local touchView = display.newLayer(cellSize.width / 2, cellSize.height / 2, {ap = display.CENTER, size = cellSize, color = cc.c4b(0, 0, 0, 0), enable = true})
    cell:addChild(touchView)

    local gradeImg = display.newImageView(RES_DIR.GRADE_IMG, -5, cellSize.height - 8, {ap = display.LEFT_TOP})
    cell:addChild(gradeImg, 1)

    -- 道具
    local goodBg = display.newImageView(RES_DIR.CELL_GOOD_BG, 0, 0, {ap = display.LEFT_BOTTOM})
    local goodBgSize = goodBg:getContentSize()
    local goodLayer = display.newLayer(5, cellSize.height / 2, {ap = display.LEFT_CENTER, size = goodBgSize})
    goodLayer:addChild(goodBg)
    cell:addChild(goodLayer)
    goodLayer:setScale(0.9)

    local goodNode = require('common.GoodNode').new({id = 150061, showAmount = false, callBack = function (sender)
        AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
    end})
    goodNode.fragmentImg:setVisible(false)
    goodNode.bg:setVisible(false)
    display.commonUIParams(goodNode,{po = cc.p(goodBgSize.width / 2, goodBgSize.height / 2), ap = display.CENTER})
    -- goodNode:setScale(1.5)
    goodLayer:addChild(goodNode)

    local prepareDescSize = cc.size(cellSize.width / 2, cellSize.height)
    local prepareDescLayer = display.newLayer(cellSize.width / 2 - 10, cellSize.height / 2, {ap = display.LEFT_CENTER, size = prepareDescSize})
    cell:addChild(prepareDescLayer)
    prepareDescLayer:setVisible(false)
    -- 进度
    local prepareProgress = display.newLabel(3, prepareDescSize.height - 34, fontWithColor(16, {ap = display.LEFT_CENTER, text = __('筹备数量:')}))
    prepareDescLayer:addChild(prepareProgress)

    local progressLabel = display.newLabel(prepareProgress:getPositionX(), prepareProgress:getPositionY() - 26, fontWithColor(14, {ap = display.LEFT_CENTER, fontSize = 26, color = '#ffffff',  outline = '#5B3C25', outlineSize = 1}))
    prepareDescLayer:addChild(progressLabel)

    -- 拥有数
    local ownLabel = display.newLabel(prepareProgress:getPositionX(), 40, {ap = display.LEFT_CENTER, fontSize = 22, color = '#8b7666', text = __('拥有:')})
    local ownLabelSize = display.getLabelContentSize(ownLabel)
    prepareDescLayer:addChild(ownLabel)
    
    local ownCountLabel = display.newLabel(ownLabel:getPositionX() + ownLabelSize.width, ownLabel:getPositionY(), {ap = display.LEFT_CENTER, fontSize = 22, color = '#BB4F07', text = 0})
    prepareDescLayer:addChild(ownCountLabel)

    -- errtip
    local tipLabel = display.newLabel(prepareProgress:getPositionX(), 40, {ap = display.LEFT_CENTER, fontSize = 22, color = '#BB4F07', text = __('暂未学会')})
    prepareDescLayer:addChild(tipLabel)

    -- 黑色遮盖
    local cellBgSize = cellBg:getContentSize()
    local blackCover = display.newImageView(RES_DIR.CELL_BG_BLACK, cellSize.width / 2, cellSize.height / 2, {ap = display.CENTER, scale9 = true, size = cellBgSize})
    cell:addChild(blackCover, 1)

    local arrow = display.newImageView(RES_DIR.ARROW, cellSize.width * 0.75, cellSize.height / 2, {ap = display.CENTER})
    blackCover:addChild(arrow, -1)
    blackCover:setVisible(false)

    cell.viewData = {
        cellBg           = cellBg,
        touchView        = touchView,
        gradeImg         = gradeImg,
        goodNode         = goodNode,
        prepareDescLayer = prepareDescLayer,
        progressLabel    = progressLabel,
        ownLabel         = ownLabel,
        ownCountLabel    = ownCountLabel,
        tipLabel         = tipLabel,
        blackCover       = blackCover,
    }
    return cell
end

CreateChest_ = function (index, x, y, partyName)
    local path = getChestPath(index)
    local chestSize = cc.size(100,100)
    local chestLayer = display.newLayer(x, y, {size = chestSize, ap = display.CENTER, color = cc.c4b(0, 0, 0, 0), enable = true})

    local chest = display.newImageView(path, chestSize.width / 2, 10, {ap = display.CENTER_BOTTOM})
    chest:setName('chest')
    chest:setScale(0.7)
    -- chest:setColor(cc.c3b(150, 150, 150))
    chestLayer:addChild(chest)
    
    local intervalBg = display.newImageView(RES_DIR.INTEGRAL_BG, chestSize.width / 2, 45, {ap = display.CENTER_TOP})
    local intervalBgSize = intervalBg:getContentSize()
    intervalBg:setName('intervalBg')
    -- intervalBg:setColor(cc.c3b(150, 150, 150))
    chestLayer:addChild(intervalBg)

    local intervalLabel = display.newLabel(intervalBgSize.width / 2, intervalBgSize.height / 2, fontWithColor(16, {ap = display.CENTER, text = 11111}))
    intervalLabel:setName('intervalLabel')
    intervalBg:addChild(intervalLabel)

    local partyTipBg, descLabel = CreatePartyTip_(partyName)
    display.commonUIParams(partyTipBg, {po = cc.p(chestSize.width / 2, chestSize.height)})
    chestLayer:addChild(partyTipBg)
    partyTipBg:setName('partyTipBg')
    partyTipBg:setVisible(false)

    return chestLayer
end

CreatePartyTip_ = function (partyName)

    local label = display.newLabel(0, 0, fontWithColor(16, {text = __('当前:'), ap = display.CENTER}))
	local desc = display.newLabel(0, 0, fontWithColor(14, {fontSize = 22, text = partyName, color = '#ffffff', outline = '#5b3c25', outlineSize = 1, ap = display.CENTER}))

	local labelSize = display.getLabelContentSize(label)
	local descSize = desc:getContentSize()

	local partyBg = display.newImageView(RES_DIR.CURRENT_LEVEL_PARTY, 0, 0, {ap = display.CENTER_BOTTOM, animate = false, enable = true, scale9 = true})

	local partyBgSize = partyBg:getContentSize()
	local bgSize = cc.size(descSize.width + 20, partyBgSize.height)
	if partyBgSize.width > bgSize.width then
		bgSize = partyBgSize
	end
	partyBg:setContentSize(bgSize)

	display.commonUIParams(label, {po = cc.p(bgSize.width / 2 - descSize.width / 2, bgSize.height / 2 + 6)})
	display.commonUIParams(desc, {po = cc.p(bgSize.width / 2 + labelSize.width / 2, bgSize.height / 2 + 6)})

	partyBg:addChild(label)
    partyBg:addChild(desc)
    
	return partyBg
end

getChestPath = function (index)
    local path = _res(string.format("ui/union/party/prepare/guild_party_ico_party_%s.png", index))
    if not utils.isExistent(path) then
        path = _res('ui/union/party/prepare/guild_party_ico_party_1.png')
    end
    return path
end

function UnionPartyPrepareTaskView:CreateCell()
    return CreateCell_()
end

function UnionPartyPrepareTaskView:getViewData()
	return self.viewData_
end

return UnionPartyPrepareTaskView
