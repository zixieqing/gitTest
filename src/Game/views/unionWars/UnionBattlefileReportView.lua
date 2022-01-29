---@class UnionBattlefileReportView
local UnionBattlefileReportView = class('UnionBattlefileReportView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.union.UnionBattlefileReportView'
    node:enableNodeEvents()
    node:setAnchorPoint(display.CENTER)
    return node
end)
local BUTTON_CLICK = {
    BASE_REPORT    = 1001,  -- 基本的战报
    ATTACK_REPORT   = 1002,  -- 进攻的战报
    DEFENCES_REPORT = 1003   -- 防御的战报
}
local RES_DICT = {
    COMMON_BTN_SIDEBAR_COMMON   = _res("ui/common/common_btn_sidebar_common.png"),
    COMMON_BTN_SIDEBAR_SELECTED = _res("ui/common/common_btn_sidebar_selected.png"),
    GVG_WARREPORT_BG_SHUJV      = _res("ui/union/wars/report/gvg_warreport_bg_shujv.png"),
    GVG_WARREPORT_WIN_BG        = _res("ui/union/wars/report/gvg_warreport_win_bg.png"),
    GVG_WARREPORT_LOST_BG       = _res("ui/union/wars/report/gvg_warreport_lost_bg.png"),
    GVG_WARREPORT_VS            = _res("ui/union/wars/report/gvg_warreport_vs.png"),
    GVG_REPORT_ICO_DEFEAT       = _res("ui/union/wars/report/gvg_report_ico_defeat.png"),
    GVG_REPORT_ICO_VICTORY      = _res("ui/union/wars/report/gvg_report_ico_victory.png"),
    GVG_REPORT_TITLE            = _res("ui/union/wars/report/gvg_report_title.png"),
    PVP_REPORT_ICO_LINE         = _res("ui/union/wars/report/pvp_report_ico_line.png"),
}
--[[
constructor
--]]
function UnionBattlefileReportView:ctor(param)
    local param = param or {}
    self.currentTime = getServerTime()
    self.dataSource = {}
    local view = require("common.TitlePanelBg").new({ title = __('战报'), isHideCloseBtn = true , offsetX = -1 ,  offsetY =3 ,  type = 2})
    display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
    self:addChild(view)

    local buttonSize = cc.size(143, 96)
    local buttonLayotSize = cc.size(buttonSize.width, buttonSize.height * 4)
    local swallowButtonLayout = display.newLayer(buttonLayotSize.width / 2, buttonLayotSize.height / 2, { size = buttonLayotSize, enable = true, ap = display.CENTER, color = cc.c4b(0, 0, 0, 0) })
    local buttonLayot = CLayout:create(buttonLayotSize)
    buttonLayot:addChild(swallowButtonLayout)
    buttonLayot:setPosition(display.cx + 350 , display.cy +260)
    buttonLayot:setAnchorPoint(display.LEFT_TOP)
    self:addChild(buttonLayot ,10 )
    local buttonNameTable = {
        { name    =    __('基本') ,tag = BUTTON_CLICK.BASE_REPORT}  ,
        { name  =  __('本场进攻') ,tag = BUTTON_CLICK.ATTACK_REPORT},
        { name  =  __('本场防御') ,tag = BUTTON_CLICK.DEFENCES_REPORT}
    }
    local buttonTable  = {}
    local len = table.nums(buttonNameTable)
    for  i = 1, len do
        local btn = display.newCheckBox(buttonSize.width/2,buttonLayotSize.height -((i -0.5) * buttonSize.height),
                                        {n = RES_DICT.COMMON_BTN_SIDEBAR_COMMON,
                                         s =  RES_DICT.COMMON_BTN_SIDEBAR_SELECTED })
        local label = display.newLabel(buttonSize.width /2 - 5 , buttonSize.height /2 + 25 ,fontWithColor(7,{ fontSize = 22, color = '3c3c3c', ap = display.CENTER , text =buttonNameTable[i].name
        }) )
        btn:addChild(label)
        label:setTag(111)
        btn:setTag(buttonNameTable[i].tag)
        buttonTable[tostring(buttonNameTable[i].tag)] = btn
        buttonLayot:addChild(btn)
    end
    local contentSize = cc.size(700 , 570)
    local contentLayout = display.newLayer(display.cx  , display.cy -25,{ ap = display.CENTER ,  size = contentSize}  )
    local contentLayoutPanel =  view.viewData.view
    local contentLayoutPanelSize = contentLayoutPanel:getContentSize()
    contentLayout:setPosition(contentLayoutPanelSize.width/2 , contentLayoutPanelSize.height/2-25)
    contentLayoutPanel:addChild(contentLayout)
    self.viewData = {
        contentLayout =  contentLayout ,
        buttonTable =  buttonTable ,
        eaterLayer =  view.viewData.eaterLayer ,
    }
end
--==============================--
---@Description: 创建基本的公会战报
---@author : xingweihao
---@date : 2019/4/8 10:23 AM
--==============================--

function UnionBattlefileReportView:CreateBaseView()
    local contentLayout = self.viewData.contentLayout
    local contentSize = contentLayout:getContentSize()
    local listView = CListView:create(cc.size(contentSize.width  , contentSize.height -60 ) )
    listView:setPosition(contentSize.width/2, contentSize.height/2 )
    listView:setDirection(eScrollViewDirectionVertical)
    listView:setAnchorPoint(display.CENTER)
    contentLayout:addChild(listView)
    self.baseViewData =  {
        listView = listView
    }
end

function UnionBattlefileReportView:CreateBaseCell()
    local cellSize = cc.size(700, 89)
    local cellLayout = display.newLayer(0,0, {size = cellSize})

    local cellImage = display.newImageView(RES_DICT.GVG_WARREPORT_BG_SHUJV , cellSize.width/2 , cellSize.height/2)
    cellLayout:addChild(cellImage)

    local descrLabel = display.newLabel(20 , cellSize.height * 3/4 , fontWithColor(16, {ap = display.LEFT_CENTER ,  text = "111" }))
    cellLayout:addChild(descrLabel)

    local performanceLabel = display.newLabel(20 , cellSize.height * 1/4 , fontWithColor(10, {ap = display.LEFT_CENTER ,text = "111" }))
    cellLayout:addChild(performanceLabel)
    cellLayout.viewData = {
        cellLayout = cellLayout ,
        cellImage = cellImage ,
        descrLabel = descrLabel ,
        performanceLabel = performanceLabel
    }
    return cellLayout
end
-- 更新基础的基本信息
function UnionBattlefileReportView:UpdateBaseView(baseData)

    if  self.baseViewData.listView and (not tolua.isnull(self.baseViewData.listView)) then
        self.baseViewData.listView:setVisible(true)
        local nodes = self.baseViewData.listView:getNodes()
        -- 战报基本信息为零的时候刷新 ， 不为零的时候不用刷新
        if #nodes == 0  then
            for i = 1, #baseData do
                local cell = self:CreateBaseCell()
                self:UpdateBaseCell(cell , baseData[i].title , baseData[i].descr )
                self.baseViewData.listView:insertNodeAtLast(cell)
            end
            self.baseViewData.listView:reloadData()
        end
    end
end
--==============================--
---@Description: 更新战报的基本信息
---@author : xingweihao
---@date : 2019/4/8 2:23 PM
--==============================--

function UnionBattlefileReportView:UpdateBaseCell(cell ,  descrName , performance)
    local viewData = cell.viewData
    display.commonLabelParams(viewData.descrLabel , {text = descrName })
    display.commonLabelParams(viewData.performanceLabel , {text = performance })
end
--==============================--
---@Description: 创建进攻的公会战报
---@author : xingweihao
---@date : 2019/4/8 10:23 AM
--==============================--

function UnionBattlefileReportView:CreateAttackAndDefencesView()
    local contentLayout =self.viewData.contentLayout
    local contentSize = contentLayout:getContentSize()
    local attackSize = cc.size(700, 570 )
    local attackView = display.newLayer(contentSize.width/2 , contentSize.height/2 , {ap = display.CENTER , size = attackSize  })
    contentLayout:addChild(attackView)

    local reportTitleImage = display.newImageView(RES_DICT.GVG_REPORT_TITLE ,attackSize.width/2 , attackSize.height , {ap = display.CENTER_TOP} )
    attackView:addChild(reportTitleImage)
    local distanceWith  = 80
    -- 进攻工会的名称
    local attackUnionName = display.newLabel((contentSize.width - distanceWith) / 4  , contentSize.height - 20 , fontWithColor(10, {text = "" , color = "#003f94" ,fontSize = 24 }))
    attackView:addChild(attackUnionName)

    -- 防守工会的名称
    local defenceUnionName = display.newLabel((contentSize.width - distanceWith) / 4 * 3  , contentSize.height - 20 , fontWithColor(10, {text = "" , color = "#8c0000" , fontSize = 24 }))
    attackView:addChild(defenceUnionName)
    local listSize = cc.size(contentSize.width , contentSize.height - 50 )
    local gridView =  CGridView:create(listSize)
    gridView:setPosition(contentSize.width/2, 0 )
    gridView:setDirection(eScrollViewDirectionVertical)
    gridView:setAnchorPoint(display.CENTER_BOTTOM)
    gridView:setColumns(1)
    gridView:setAutoRelocate(true)
    attackView:addChild(gridView)
    gridView:setSizeOfCell(cc.size(700 , 120 ))
    self.attackDefenceViewData = {
        attackView = attackView ,
        gridView = gridView ,
        attackUnionName = attackUnionName ,
        reportTitleImage = reportTitleImage ,
        defenceUnionName = defenceUnionName
    }
end

function UnionBattlefileReportView:CreateAttackCell()
    local cellSize = cc.size(700 , 120 )
    local cellLayout = CGridViewCell:new()
    cellLayout:setContentSize(cellSize)
    local cellImage = display.newImageView(RES_DICT.GVG_WARREPORT_WIN_BG , cellSize.width/2 , cellSize.height/2 )
    cellLayout:addChild(cellImage)
    local widthDistance = 50
    local resultLabel = display.newLabel( widthDistance , cellSize.height - 20 , fontWithColor(10, {text = "1111"}) )
    cellLayout:addChild(resultLabel)

    local resultImage = display.newImageView(RES_DICT.GVG_REPORT_ICO_VICTORY ,widthDistance,cellSize.height/2  ,{ap = display.CENTER})
    cellLayout:addChild(resultImage)
    local widthDistance2 = 85
    local lineImage = display.newImageView(RES_DICT.PVP_REPORT_ICO_LINE ,  widthDistance2, cellSize.height/2 )
    cellLayout:addChild(lineImage,20)

    local timeLabel = display.newLabel(190 , cellSize.height - 60, fontWithColor(8, {ap = display.LEFT_CENTER ,  text = "111"}))
    cellLayout:addChild(timeLabel)

    local attackLayout = self:CreatePlayerInfo()
    cellLayout:addChild(attackLayout)
    attackLayout:setPosition(90 ,cellSize.height/2)
    local vsImage = display.newImageView(RES_DICT.GVG_WARREPORT_VS , 355 , cellSize.height/2 )
    cellLayout:addChild(vsImage,10)
    local vsImageSize = vsImage:getContentSize()
    local vsLabel = display.newLabel(vsImageSize.width/2 , vsImageSize.height/2 , fontWithColor(10, {fontSize = 24 , color = "#ff0000" , text = "VS"}))
    vsImage:addChild(vsLabel)
    local defenseLayout  = self:CreatePlayerInfo()
    cellLayout:addChild(defenseLayout)
    defenseLayout:setPosition(390 ,cellSize.height/2)
    cellLayout.viewData = {
        cellImage             = cellImage,
        resultLabel           = resultLabel,
        timeLabel             = timeLabel,
        resultImage           = resultImage,
        attackLayout          = attackLayout,
        defenseLayout         = defenseLayout,
        attackPlayerHeadNode  = attackLayout.viewData.playerHeadNode,
        attackPlayerName      = attackLayout.viewData.playerName,
        defensePlayerHeadNode = defenseLayout.viewData.playerHeadNode,
        defensePlayerName     = defenseLayout.viewData.playerName,
    }
    return cellLayout
end

function UnionBattlefileReportView:CreatePlayerInfo()
    local playerLayoutSize = cc.size(150 , 120 )
    local playerHeadLayout = display.newLayer(90, playerLayoutSize.height/2 ,
                                              {ap = display.LEFT_CENTER , size = playerLayoutSize })
    local playerHeadNode = require('common.PlayerHeadNode').new({})
    playerHeadLayout:addChild(playerHeadNode)
    playerHeadNode:setScale(0.6)
    playerHeadNode:setPosition(50 ,  playerLayoutSize.height/2)
    local widthDistance = 100
    local playerName = display.newLabel(widthDistance , playerLayoutSize.height - 30 ,fontWithColor(10, {text = "11111" , fontSize = 22 , ap = display.LEFT_CENTER }) )
    playerHeadLayout:addChild(playerName)
    playerHeadLayout.viewData = {
        playerHeadNode = playerHeadNode ,
        playerName = playerName
    }
    return playerHeadLayout
end
--==============================--
---@Description: 更新进攻和防御的view
---@param dataSource table @刷新列表的数据
---@param attackUnionName string @进攻方公会名
---@param defenceUnionName string @防御方工会名称  type 1 .主动进攻 2.被动防御
---@author : xingweihao
---@date : 2019/4/10 10:48 AM
--==============================--
function UnionBattlefileReportView:UpdateAttackAnDefenceView(dataSource , attackUnionName , defenceUnionName  )
    if self.attackDefenceViewData  then
        local viewData = self.attackDefenceViewData
        self.attackDefenceViewData.attackView:setVisible(true )
        local isVisible = false
        if #dataSource> 0  then
            self.dataSource = dataSource
            isVisible = true
        else
            if not self.attackDefenceViewData.emptyLabel then
                local emptyLabel = display.newRichLabel(350 , 470 , { r = true ,
                  c= { {img = _res('arts/cartoon/card_q_3.png') , scale = 0.8, ap = cc.p(0.0,0.5)},
                       fontWithColor('14', { fontSize = 30 , ap = cc.p(-10,0), text = __('暂无战报记录')})
                  }})
                self.attackDefenceViewData.attackView:addChild(emptyLabel,1000)
                self.attackDefenceViewData.emptyLabel = emptyLabel
                CommonUtils.AddRichLabelTraceEffect(emptyLabel)
            end
        end
        if self.attackDefenceViewData.emptyLabel then
            self.attackDefenceViewData.emptyLabel:setVisible(not isVisible)
            viewData.reportTitleImage:setVisible(isVisible)
        end
        viewData.attackUnionName:setVisible(isVisible)
        viewData.defenceUnionName:setVisible(isVisible)
        display.commonLabelParams(viewData.attackUnionName , {text = attackUnionName })
        display.commonLabelParams(viewData.defenceUnionName , {text = defenceUnionName })
        viewData.gridView:setDataSourceAdapterScriptHandler(handler(self , self.OnDataSource))
        viewData.gridView:setCountOfCell(#dataSource)
        viewData.gridView:reloadData()
    end
end

function UnionBattlefileReportView:OnDataSource(cell , idx  )
    local index = idx + 1
    local data = self.dataSource[index]
    if not cell then
        cell = self:CreateAttackCell()
    end
    local viewData = cell.viewData
    local text = ""
    local bgTexture = ""
    local resultImage = ""
    if checkint(data.isPassed) >= 1 then
        text = __('胜利')
        bgTexture = RES_DICT.GVG_WARREPORT_WIN_BG
        resultImage = RES_DICT.GVG_REPORT_ICO_VICTORY
    else
        text = __('失败')
        bgTexture = RES_DICT.GVG_WARREPORT_LOST_BG
        resultImage = RES_DICT.GVG_REPORT_ICO_DEFEAT
    end
    display.commonLabelParams(viewData.resultLabel , {text = text})
    viewData.cellImage:setTexture(bgTexture)
    viewData.resultImage:setTexture(resultImage)
    local diatanceTime =  self.currentTime - checkint(data.unionBattleEndTime)
    local distanceTable = string.formattedTime(diatanceTime)
    if  checkint(distanceTable.h)  >= 24 then
        display.commonLabelParams(viewData.timeLabel , {text = string.fmt(__('_num_天前') , {_num_ = math.floor(distanceTable.h/24) }) })
    elseif  checkint(distanceTable.h)  > 0 then

        display.commonLabelParams(viewData.timeLabel , {text = string.fmt(__('_num_小时前') , {_num_ = math.floor(distanceTable.h) }) })
    else
        display.commonLabelParams(viewData.timeLabel , {text = string.fmt(__('_num_分钟前') , {_num_ = math.floor(distanceTable.m) }) })
    end

    display.commonLabelParams(viewData.defensePlayerName , {text = data.defenseData.playerName})
    display.commonLabelParams(viewData.attackPlayerName ,{text = data.attackData.playerName} )

    viewData.attackPlayerHeadNode:RefreshUI(data.attackData)
    viewData.defensePlayerHeadNode:RefreshUI(data.defenseData)
    return cell
end




return UnionBattlefileReportView
