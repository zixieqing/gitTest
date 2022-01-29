local GameScene = require( "Frame.GameScene" )
local NAME = 'Game.views.anniversary19.Anniversary19ExploreMainView'
local anniversary2019Mgr = app.anniversary2019Mgr
---@class Anniversary19ExploreMainView :GameScene
local Anniversary19ExploreMainView = class("Anniversary19ExploreMainView", GameScene)
Anniversary19ExploreMainView.NAME = NAME
local RES_DICT = {
    WONDERLAND_EXPLORE_MAIN_BG                 = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_bg.jpg'),
    WONDERLAND_EXPLORE_MAIN_ICO_TASK           = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_ico_task.png'),
    WONDERLAND_EXPLORE_MAIN_LABEL_TASK         = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_label_task.png'),
    WONDERLAND_EXPLORE_MAIN_BTN_CONTINUE       = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_btn_continue.png'),
    WONDERLAND_EXPLORE_MAIN_BTN_ENTER          = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_btn_enter.png'),
    WONDERLAND_EXPLORE_MAIN_LABEL_BUFF         = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_label_buff.png'),
    WONDERLAND_EXPLORE_MAIN_BG_ENTRANCE        = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_bg_entrance.png'),
    WONDERLAND_EXPLORE_PAN_BG_1                = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_bg_1.png'),
    WONDERLAND_EXPLORE_PAN_BG_2                = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_bg_2.png'),
    WONDERLAND_EXPLORE_PAN_BG_3                = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_bg_3.png'),
    WONDERLAND_EXPLORE_PAN_BG_RING             = app.anniversary2019Mgr:GetResPath('ui/anniversary19/DreamCycle/wonderland_explore_pan_bg_ring.png'),

    COMMON_TITLE                               = app.anniversary2019Mgr:GetResPath('ui/common/common_title.png'),
    COMMON_BTN_TIPS                            = app.anniversary2019Mgr:GetResPath('ui/common/common_btn_tips.png'),
    BTN_REFRESH                                = app.anniversary2019Mgr:GetResPath('ui/home/commonShop/shop_btn_refresh.png'),
    COMMON_BTN_BACK                            = app.anniversary2019Mgr:GetResPath('ui/common/common_btn_back.png'),

    ----------------------------
    -- spine
    WONDERLAND_EXPLORE_BUFF                      = anniversary2019Mgr.spineTable.WONDERLAND_EXPLORE_BUFF ,
    -- spine

    ----------------------------
}

local display = display

local CreateView     = nil
local CreateExploreNode = nil

local ringSize = cc.size(768, 768)
local middleRingX, middleRingY = ringSize.width * 0.5, ringSize.height * 0.5
local EXPLORE_POS_CONF = {
    -- ringPos                           exploreNodePos                              differencePos    
    {cc.p(display.cx - 566, display.cy + 145), cc.p(middleRingX + 85, middleRingY - 110), cc.p(-314, -554)},
    {cc.p(display.cx - 22,  display.cy - 388), cc.p(middleRingX, middleRingY + 190),      cc.p(436, -212)},
    {cc.p(display.cx + 350, display.cy + 365), cc.p(middleRingX, 190),                    cc.p(-376, 306)},
}

function Anniversary19ExploreMainView:ctor( ... )
    self.super.ctor(self, NAME)

    self.args = unpack({...}) or {}
    self.costText = string.split(__('消耗 |_cost_||_icon_|'), '|')

    self:InitialUI()
end

function Anniversary19ExploreMainView:InitialUI( )
    
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)

        self:addChild(self.viewData_.moneyBar, GameScene.TAGS.TagGameLayer + 1)

	end, __G__TRACKBACK__)
end

function Anniversary19ExploreMainView:UpdateMoneyBarGoodList(args)
    local viewData = self:GetViewData()
    viewData.moneyBar:RefreshUI(args)
end

function Anniversary19ExploreMainView:UpdateMoneyBarGoodNum()
    local viewData = self:GetViewData()
    viewData.moneyBar:updateMoneyBar()
end

---UpdateExploreNode
---更新探索节点
---@param exploreNode table 探索节点
---@param data table 探索数据
---@param exploreModuleId number 探索模块id
function Anniversary19ExploreMainView:UpdateExploreNode(exploreNode, data, exploreModuleId)
    local viewData = exploreNode.viewData
    viewData.bossHeadNode:UpdateBossLevel(data.bossLevel or 1)

    local exploring  = checkint(data.exploring)
    local exploreBtnImg, exploreBtnText, tipText
    if exploring > 0 then
        exploreBtnText = app.anniversary2019Mgr:GetPoText(__('继续探索'))
        exploreBtnImg = RES_DICT.WONDERLAND_EXPLORE_MAIN_BTN_CONTINUE

        local parameterConf      = CommonUtils.GetConfigAllMess('parameter', 'anniversary2') or {}
        local exploreMaxProgress = checkint(parameterConf.exploreMaxFloor)
        tipText = {
            {fontSize = 20, color = '#7b3d28', text = string.format(app.anniversary2019Mgr:GetPoText(__('当前进度：%s/%s')), checkint(data.progress), exploreMaxProgress)}
        }
    else
        exploreBtnText = app.anniversary2019Mgr:GetPoText(__('探索'))
        exploreBtnImg = RES_DICT.WONDERLAND_EXPLORE_MAIN_BTN_ENTER
        
        local exploreConf = CommonUtils.GetConfig('anniversary2', 'explore', exploreModuleId) or {}
        local goodsId    = app.anniversary2019Mgr:GetHPGoodsId()
        tipText = {}
        for k,text in ipairs(self.costText) do
            if '_cost_' == text then
                table.insert(tipText, {text = tostring(exploreConf.consumeNum), fontSize = 20, color = '#7b3d28'})
            elseif '_icon_' == text then
                table.insert(tipText, {img = CommonUtils.GetGoodsIconPathById(goodsId), scale = 0.2})
            elseif string.len(text) > 0 then
                table.insert(tipText, {text = text, fontSize = 20, color = '#7b3d28'})
            end
        end
    end

    local exploreBtn = viewData.exploreBtn
    exploreBtn:setNormalImage(exploreBtnImg)
    exploreBtn:setSelectedImage(exploreBtnImg)
    display.commonLabelParams(exploreBtn, {text = exploreBtnText})

    local tipLabel   = viewData.tipLabel
    display.reloadRichLabel(tipLabel, {c = tipText})
end

---UpdateAuguryDesc
---更新占卜描述文本
---@param viewData table 视图数据
---@param auguryId number 占卜id
function Anniversary19ExploreMainView:UpdateAuguryDesc(viewData, auguryId)
    local exploreAuguryConf = CommonUtils.GetConfig('anniversary2', 'exploreAugury', auguryId) or {}
    local auguryDesc = viewData.auguryDesc
    display.commonLabelParams(auguryDesc, {text = tostring(exploreAuguryConf.descr)})

    local auguryDescWidth = display.getLabelContentSize(auguryDesc).width
    
    if auguryDescWidth > 0 then
        local scrollView    = self:GetViewData().scrollView
        local scrollWidth   = scrollView:getContainerSize().width
        self.scrollTextWidth_ = scrollWidth + auguryDescWidth

        self:StartTextScroll_()
    else
        self:StopTextScroll()
    end

end

---StartTextScroll_
---开启文本滚动
function Anniversary19ExploreMainView:StartTextScroll_()
    if self.scrollTextSchedule_ then return end
    local scrollView = self:GetViewData().scrollView
    local scrollPos_  = scrollView:getContentOffset()

    self.scrollTextSchedule_ = scheduler.scheduleGlobal(function()
        local scrollPos  = scrollView:getContentOffset()
        scrollPos.x      = scrollPos.x - 1
        scrollView:setContentOffset(scrollPos)

        -- limit check
        if scrollPos.x < -self.scrollTextWidth_ then
            scrollView:setContentOffset(cc.p(0, 0))
        end
    end, 0.01)
end

---StopTextScroll
---停止文本滚动
function Anniversary19ExploreMainView:StopTextScroll()
    if self.scrollTextSchedule_ then
        scheduler.unscheduleGlobal(self.scrollTextSchedule_)
        self.scrollTextSchedule_ = nil
    end
end

---PlayAugurySpine
---播放占卜spine
---@param auguryId number 占卜id
---@param isInit   boolean 是否是初始化
function Anniversary19ExploreMainView:PlayAugurySpine(auguryId, isInit)
    local viewData    = self:GetViewData()
    local augurySpine = viewData.augurySpine

    local exploreAuguryConf = CommonUtils.GetConfig('anniversary2', 'exploreAugury', auguryId) or {}
    local group = exploreAuguryConf.group
    if not isInit then
        self:StopTextScroll()
        local scrollView    = self:GetViewData().scrollView
        local scrollWidth   = scrollView:getContainerSize().width
        scrollView:setContentOffset(cc.p(-scrollWidth + 60, 0))
        display.commonLabelParams(viewData.auguryDesc, {text = '?????'})
        augurySpine:setAnimation(0, string.format('play%s', group), false)
    end
    augurySpine:addAnimation(0, string.format('idle%s', group), false)
    
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    view:addChild(display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true}))

    local backBtn = display.newButton(display.SAFE_L + 15, display.height - 55,
    {
        ap = display.LEFT_CENTER,
        n = RES_DICT.COMMON_BTN_BACK,
        scale9 = true, size = cc.size(90, 70),
        enable = true,
    })
    view:addChild(backBtn, 10)

    -- 背景
    local middleX, middleY = size.width * 0.5, size.height * 0.5
    local bgImg = display.newNSprite(RES_DICT.WONDERLAND_EXPLORE_MAIN_BG, middleX, middleY, {ap = display.CENTER})
    view:addChild(bgImg)

    -- 标题
    local titleBtn = display.newButton(display.SAFE_L + 130, display.height,{ ap = display.LEFT_TOP ,  n = RES_DICT.COMMON_TITLE, d = RES_DICT.COMMON_TITLE, s = RES_DICT.COMMON_TITLE, scale9 = true, size = cc.size(303, 78) })
    display.commonLabelParams(titleBtn, {ttf = true, reqW = 204,offset = cc.p(-20,-10),font = TTF_GAME_FONT,fontSize = 30 ,   text =  app.anniversary2019Mgr:GetPoText(__('仙境之旅')) ,color = '#473227'})
    view:addChild(titleBtn, 10)
    local titleSize = titleBtn:getContentSize()
    local tipsIcon  = display.newImageView(RES_DICT.COMMON_BTN_TIPS, titleSize.width - 50, titleSize.height/2 - 10)
    titleBtn:addChild(tipsIcon)

    ----------------------------------------------
    --- 探索节点相关UI

    -- explore 节点层
    local exploreNodeLayer = display.newLayer()
    view:addChild(exploreNodeLayer, 1)

    local exploreNodeSize = cc.size(380, 300)
    local exploreNodes = {}
    -- local ringImgs = {}    
    local exploreNodeBgs = {}
    local exploreConf = CommonUtils.GetConfigAllMess('explore', 'anniversary2') or {}
    local index = 1 
    for _, conf in orderedPairs(exploreConf) do
        local ringPos, exploreNodePos, differencePos = unpack(EXPLORE_POS_CONF[index])
        local ringMiddleX, ringMiddleY = ringSize.width * 0.5, ringSize.height * 0.5
        local node = display.newLayer(ringPos.x, ringPos.y, {size = ringSize, ap = display.CENTER})
        node:setName(string.format('node%s', index))
        exploreNodeLayer:addChild(node)
        local ringNode = display.newLayer(ringMiddleX + differencePos.x, ringMiddleY + differencePos.y, {size = ringSize, ap = display.CENTER})
        ringNode:setName('ringNode')
        ringNode:setRotation(-90)
        node:addChild(ringNode)

        local ringImg = display.newNSprite(RES_DICT.WONDERLAND_EXPLORE_PAN_BG_RING, ringMiddleX, ringMiddleY)
        ringImg:setName('ringImg')
        ringNode:addChild(ringImg)
        -- table.insert(ringImgs, ringImg)

        local exploreNodeBg = display.newNSprite(RES_DICT[string.format('WONDERLAND_EXPLORE_PAN_BG_%s', index)], ringMiddleX, ringMiddleY)
        -- exploreNodeBg:setName('exploreNodeBg')
        ringNode:addChild(exploreNodeBg)
        table.insert(exploreNodeBgs, exploreNodeBg)

        local exploreNode = CreateExploreNode(exploreNodeSize, conf)
        exploreNode:setVisible(false)
        exploreNode:setTag(conf.id)
        display.commonUIParams(exploreNode, {ap = display.CENTER, po = cc.p(exploreNodePos.x, exploreNodePos.y)})
        node:addChild(exploreNode)
        table.insert(exploreNodes, exploreNode)
        index = index + 1
    end

    --- 探索节点相关UI
    ----------------------------------------------
    
    -- 委托任务按钮
    local taskBtn = display.newButton(middleX - 90, middleY + 100, {n = RES_DICT.WONDERLAND_EXPLORE_MAIN_ICO_TASK})
    view:addChild(taskBtn)
    taskBtn:setVisible(false)

    local taskLabelBg = display.newNSprite(RES_DICT.WONDERLAND_EXPLORE_MAIN_LABEL_TASK, 78, 0, {ap = display.CENTER_BOTTOM})
    taskBtn:addChild(taskLabelBg)
    local taskLabel = display.newLabel(70, 22, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('梦境剧本')), outline = '#390808', outlineSize = 2}))
    taskLabelBg:addChild(taskLabel)

    ----------------------------------------------
    --- 占卜相关UI

    local auguryLayer = display.newLayer()
    auguryLayer:setPosition(cc.p(300, 0))
    auguryLayer:setVisible(false)
    view:addChild(auguryLayer)

    -- buff
    local spineLayerSize = cc.size(175, 210)
    local spineLayer = display.newLayer(display.SAFE_R - 2, 90, {size = spineLayerSize, ap = display.RIGHT_BOTTOM})
    auguryLayer:addChild(spineLayer)

    anniversary2019Mgr:AddSpineCacheByPath(RES_DICT.WONDERLAND_EXPLORE_BUFF)
    local augurySpine = SpineCache(SpineCacheName.ANNIVERSARY_2019):createWithName(RES_DICT.WONDERLAND_EXPLORE_BUFF)
    augurySpine:setPosition(cc.p(
            spineLayerSize.width * 0.5,
            spineLayerSize.height * 0.5
    ))
    -- augurySpine:setAnimation(0, 'idle1', true)
    spineLayer:addChild(augurySpine)

    -- 刷新按钮
    local refreshBtn = display.newButton(spineLayerSize.width, 0, {n = RES_DICT.BTN_REFRESH, ap = display.RIGHT_BOTTOM})
    spineLayer:addChild(refreshBtn)

    local auguryDescBg = display.newImageView(RES_DICT.WONDERLAND_EXPLORE_MAIN_LABEL_BUFF, display.SAFE_R + 60, 10, {ap = display.RIGHT_BOTTOM})
    -- auguryDescBg:setVisible(false)
    auguryLayer:addChild(auguryDescBg)

    local auguryTitleLabel = display.newLabel(375, 70, {text = app.anniversary2019Mgr:GetPoText(__('魔女的预言')), ap = display.RIGHT_TOP, fontSize = 20, color = '#ffeabf'})
    -- auguryTitleLabel:setVisible(false)
    auguryDescBg:addChild(auguryTitleLabel)

    local contentSize = cc.size(286, 24)
    local scrollPoint = cc.p(388, 40)
    local scrollView  = CScrollView:create(contentSize)
    scrollView:setAnchorPoint(display.RIGHT_TOP)
    scrollView:setPosition(scrollPoint)
    -- scrollView:setBackgroundColor(cc.c3b(100,100,200))
    scrollView:setDragable(false)
    scrollView:setContentOffset(cc.p(-contentSize.width + 60, 0))
    auguryDescBg:addChild(scrollView)

    local auguryDesc = display.newLabel(contentSize.width, 0, fontWithColor(7, {ap = display.LEFT_BOTTOM, fontSize = 22}))
    scrollView:getContainer():addChild(auguryDesc)

    -- local auguryTipLabel = display.newLabel(300, 30, fontWithColor(7, {text = '?????', ap = display.CENTER, fontSize = 22}))
    -- auguryDescBg:addChild(auguryTipLabel)

    --- 占卜相关UI
    ----------------------------------------------

    local moneyBar = require("common.CommonMoneyBar").new()
    
    local titleBtnPos = cc.p(titleBtn:getPosition())
    titleBtn:setPositionY(display.height + 100)
    local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, titleBtnPos))
    titleBtn:runAction( action )
    return {
        view             = view,
        backBtn          = backBtn,
        titleBtn         = titleBtn,
        exploreNodeLayer = exploreNodeLayer,
        exploreNodeBgs   = exploreNodeBgs,
        exploreNodes     = exploreNodes,
        taskBtn          = taskBtn,
        refreshBtn       = refreshBtn,
        auguryLayer      = auguryLayer,
        augurySpine      = augurySpine,
        auguryDescBg     = auguryDescBg,
        scrollView       = scrollView,
        auguryDesc       = auguryDesc,
        moneyBar         = moneyBar,
    }
end

CreateExploreNode = function (size, conf)
    local node = display.newLayer(0, 0, {size = size})

    local id = conf.id
    local bossHeadNode = require('Game.views.anniversary19.Anniversary19ExploreBossHeadNode').new({exploreModuleId = id})
	display.commonUIParams(bossHeadNode, {ap = display.CENTER_TOP, po = cc.p(size.width * 0.5, size.height)})
	node:addChild(bossHeadNode, 1)

    local exploreContentLayerSize = cc.size(380, 224)
    local middleX, middleY = exploreContentLayerSize.width * 0.5, exploreContentLayerSize.height * 0.5
    --探索内容
    local exploreContentLayer = display.newLayer(size.width * 0.5, 0, {ap = display.CENTER_BOTTOM, size = exploreContentLayerSize})
    node:addChild(exploreContentLayer)

    --探索内容背景
    local exploreContentBg = display.newNSprite(RES_DICT.WONDERLAND_EXPLORE_MAIN_BG_ENTRANCE,
            middleX, middleY)
    exploreContentLayer:addChild(exploreContentBg)

    --探索标题名称
    local exploreTitleName = display.newLabel(middleX, middleY + 25,
            fontWithColor(1, {text = tostring(conf.name), fontSize = 24, color = '#b07b04'}))
    exploreContentLayer:addChild(exploreTitleName)

    --探索按钮
    local exploreBtn = display.newButton(middleX, 78, {n = RES_DICT.WONDERLAND_EXPLORE_MAIN_BTN_ENTER})
    display.commonLabelParams(exploreBtn, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('探索')), outline = '#692f2f', outlineSize = 2}))
    exploreContentLayer:addChild(exploreBtn)

    --探索提示标签
    local tipLabel = display.newRichLabel(middleX, 38)
    exploreContentLayer:addChild(tipLabel)

    node.viewData = {
        bossHeadNode     = bossHeadNode,
        -- exploreTitleName = exploreTitleName,
        exploreBtn       = exploreBtn,
        tipLabel         = tipLabel,
    }
    return node
end

function Anniversary19ExploreMainView:ShowAction(cb)
    local viewData         = self:GetViewData()
    local exploreNodeLayer = viewData.exploreNodeLayer
    local exploreNodeBgs   = viewData.exploreNodeBgs
    local exploreNodes     = viewData.exploreNodes

    local ringNodeActions   = {}
    local otherActions   = {}
    
    local dTime = 0.6
    -- 起点到终点的时候ring和bg123一起从-90°转到0°
    -- 然后ring不动bg123保持缓慢转圈圈
    for index, exploreNode in ipairs(exploreNodes) do
        local ringPos, exploreNodePos, differencePos = unpack(EXPLORE_POS_CONF[index])

        local nodeName = string.format('node%s', index)
        local node = exploreNodeLayer:getChildByName(nodeName)

        local ringNode = node:getChildByName('ringNode')
        table.insert(ringNodeActions, cc.TargetedAction:create(ringNode, cc.RotateTo:create(dTime, 0)))
        table.insert(ringNodeActions, cc.TargetedAction:create(ringNode, cc.MoveBy:create(dTime, cc.p(-differencePos.x, -differencePos.y))))

        table.insert(otherActions, cc.TargetedAction:create(exploreNode, cc.Show:create()))
    end

    local auguryLayer = viewData.auguryLayer
    table.insert(otherActions, cc.TargetedAction:create(auguryLayer, cc.Sequence:create(
        cc.Show:create(),
        cc.MoveTo:create(0.3, cc.p(0, 0))
    )))
    local taskBtn = viewData.taskBtn
    table.insert(otherActions, cc.TargetedAction:create(taskBtn, cc.Show:create()))
    
    self:runAction(cc.Sequence:create(
        cc.Spawn:create(ringNodeActions),
        cc.CallFunc:create(function ()
            
            for index, exploreNodeBg in ipairs(exploreNodeBgs) do
                local actionSeq = cc.RepeatForever:create(cc.RotateBy:create(3, 15))
                exploreNodeBg:runAction(actionSeq)
            end
        end),
        cc.Spawn:create(otherActions),
        cc.CallFunc:create(function () 
            if cb then cb() end
        end)
    )) 
end

function Anniversary19ExploreMainView:GetViewData()
    return self.viewData_
end

return  Anniversary19ExploreMainView