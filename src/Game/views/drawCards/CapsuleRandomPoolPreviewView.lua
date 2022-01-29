--[[
随机卡池卡池预览页面view
--]]
local CapsuleRandomPoolPreviewView = class('CapsuleRandomPoolPreviewView', function ()
    local node = CLayout:create(display.size)
    node.name = 'CapsuleRandomPoolPreviewView'
    node:setPosition(display.center)
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG              = _res('ui/common/common_bg_13.png'), 
    LIST_BG         = _res('ui/common/commcon_bg_text.png'),
    PROBABILITY_BG  = _res('ui/home/capsuleNew/randomPool/summon_bg_chance_line.png'),
    PROBABILITY_BTN = _res('ui/home/capsule/draw_probability_btn.png'),

    CELL_BTN_BG_N   = _res('ui/home/lobby/information/setup_btn_tab_default.png'),
    CELL_BTN_BG_S   = _res('ui/home/lobby/information/setup_btn_tab_select.png'), 

    LIST_TYPE_BG    = _res('ui/home/capsuleNew/randomPool/b_type_bg_name.png'), 

}
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local CreateTypeCell = nil
--[[

--]]
function CapsuleRandomPoolPreviewView:ctor( ... )
    self.args = unpack({...}) or {}
    self.cardPoolDatas = self.args.cardPoolDatas
    self.previewList_ = {}
    self.rateList_ = {}
    self.poolRateList_ = {}
    self.preIndex = 1 -- 选择的卡池
    self.typeCellDict_ = {}
    self:ConvertPoolData(self.cardPoolDatas.option)
    self:InitUI()
    self:RefreshListView()
end
--[[
init ui
--]]
function CapsuleRandomPoolPreviewView:InitUI()
    local function CreateView()
        local bg = display.newImageView(RES_DICT.BG, 0, 0, {enable = true})
        local size = bg:getContentSize()
        local view = CLayout:create(size)
        bg:setPosition(cc.p(size.width/2, size.height/2))
        view:addChild(bg, 1)
        -- 标题
        local titleBg = display.newButton(size.width / 2, size.height - 28, {scale9 = true, n = _res('ui/common/common_bg_title_2.png'), enable = false})
        view:addChild(titleBg, 1)
        display.commonLabelParams(titleBg, fontWithColor(1,{fontSize = 24, text = __('卡池类型'), color = 'ffffff'}))
        -- 卡池列表
        local gridViewSize = cc.size(220, 515)
        local gridViewCellSize = cc.size(gridViewSize.width, 90)
        local gridView = CGridView:create(gridViewSize)
        gridView:setSizeOfCell(gridViewCellSize)
        gridView:setColumns(1)
        gridView:setAnchorPoint(cc.p(0.5, 0))
        gridView:setPosition(cc.p(160, 62))
        view:addChild(gridView, 1)
        -- 卡池概率
        local probabilityBg = display.newImageView(RES_DICT.PROBABILITY_BG, 160, 60, {ap = cc.p(0.5, 0)})
        view:addChild(probabilityBg, 1)
        local probabilityBtn = display.newButton(160, 38, {n = RES_DICT.PROBABILITY_BTN, scale9 = true, size = cc.size(126, 31)})
        view:addChild(probabilityBtn, 2)
        display.commonLabelParams(probabilityBtn, {text = __('卡池概率'), color = '#ffffff', fontSize = 20})
        -- 详情列表
        local listViewSize = cc.size(756, 550)
        local listViewBg = display.newImageView(RES_DICT.LIST_BG, 652, 25, {ap = cc.p(0.5, 0), size = listViewSize, scale9 = true})
        view:addChild(listViewBg, 1)
        
        local listView = CListView:create(listViewSize)
		listView:setBounceable(false)
        listView:setDirection(eScrollViewDirectionVertical)
        display.commonUIParams(listView, {ap = cc.p(0.5, 0)})
		listView:setPosition(cc.p(652, 25))
		view:addChild(listView, 2)
        return {
            view             = view, 
            gridView         = gridView,
            gridViewCellSize = gridViewCellSize, 
            listView         = listView,
            listViewSize     = listViewSize,
            probabilityBtn   = probabilityBtn,
        }
    end 
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function()
        PlayAudioByClickClose()
        if self.args.closeAction then
            AppFacade.GetInstance():DispatchObservers(CAPSULE_SHOW_CAPSULE_UI)
        end
        self:stopAllActions()
        self:runAction(cc.RemoveSelf:create())
    end)
    xTry(function ( )
        self.viewData_ = CreateView( )
        self:addChild(self.viewData_.view)
        self.viewData_.view:setPosition(display.center)
        self.viewData_.probabilityBtn:setOnClickScriptHandler(handler(self, self.PoolProbabilityBtnCallback))
        self.viewData_.gridView:setDataSourceAdapterScriptHandler(handler(self, self.GridViewDataSource))
        self.viewData_.gridView:setCountOfCell(#checktable(self.cardPoolDatas.option))
        self.viewData_.gridView:reloadData()
    end, __G__TRACKBACK__)
end
--[[
转换卡池数据
--]]
function CapsuleRandomPoolPreviewView:ConvertPoolData( data )
    -- 卡池预览
    for _, poolData in ipairs(checktable(data)) do
        local temp = {
            guarantee = {}, -- 保底卡池
            normal = {},    -- 通常卡池
        }
        -- 把卡池预览数据分类
        for _, preview in ipairs(checktable(poolData.preview)) do
            if checkint(preview.isGuaranteed) == 1 then
                -- 保底卡池
                table.insert(temp.guarantee, preview)
            else
                -- 通常卡池
                table.insert(temp.normal, preview)
            end
        end
        table.insert(self.previewList_, temp)
        table.insert(self.rateList_, poolData.rate)
    end
    -- 卡池概率
    local poolIdMap = {}
    for i, v in ipairs(data) do
        poolIdMap[tostring(v.poolId)] = true
    end
    local poolConfig = CommonUtils.GetConfigAllMess('randBuffChildPool', 'gambling')
    local rate = {}
    for k, v in orderedPairs(poolConfig) do
        -- 筛选出当前活动的卡池
        if poolIdMap[tostring(v.id)] then 
            local temp = {
                descr = v.name,
                rate = v.displayPro,
            }
            table.insert(rate, temp)
        end
    end
    self.poolRateList_ = rate
end
--[[
卡池预览排序
--]]
function CapsuleRandomPoolPreviewView:SortPreviewData( preview )
    local previewData = clone(preview)
    table.sort(previewData, function (a, b)
        local confA = CommonUtils.GetConfig('goods', 'goods', a.cardId)
        local confB = CommonUtils.GetConfig('goods', 'goods', b.cardId)
        if checkint(a.probabilityUp) ~= checkint(b.probabilityUp) then
            return checkint(a.probabilityUp) > checkint(b.probabilityUp)
        end
        if checkint(a.rare) ~= checkint(b.rare) then
            return checkint(a.rare) > checkint(b.rare)
        end
        if checkint(confA.quality) ~= checkint(confB.quality) then
            return checkint(confA.quality) > checkint(confB.quality)
        end
        return checkint(a.cardId) > checkint(b.cardId)
    end)
    return previewData
end
--[[
gridView数据处理
--]]
function CapsuleRandomPoolPreviewView:GridViewDataSource( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    if not pCell then
    	local cSize = self:GetViewData().gridViewCellSize
        local typeListCell = CreateTypeCell(cSize)
        typeListCell.button:setOnClickScriptHandler(handler(self, self.TabButtonCallback))
        pCell = typeListCell.view
        self.typeCellDict_[pCell] = typeListCell
    end
    xTry(function()
        local typeListCell = self.typeCellDict_[pCell]
        if typeListCell then
            local poolData = self.cardPoolDatas.option[index]
            local poolConfig = CommonUtils.GetConfig('gambling', 'randBuffChildPool', checkint(poolData.poolId))
            typeListCell.button:setTag(index)
            typeListCell.poolNameLabel:setScale(display.getLabelScale(typeListCell.poolNameLabel))
            display.commonLabelParams(typeListCell.poolNameLabel, {text = poolConfig.name, reqW = 200})
            typeListCell.poolDescrLabel:setString(poolConfig.descr1)
            self:RefreshTypeCell(typeListCell, index == self.preIndex)
        end
	end,__G__TRACKBACK__)	
	return pCell
end
--[[
刷新cell
@parmas typeCell map  
@params selected bool 是否选中
--]]
function CapsuleRandomPoolPreviewView:RefreshTypeCell( typeCell, selected )
    if selected then
        typeCell.button:setNormalImage(RES_DICT.CELL_BTN_BG_S)
        typeCell.button:setSelectedImage(RES_DICT.CELL_BTN_BG_S)
        typeCell.poolNameLabel:setColor(ccc3FromInt('#ffffff'))
        typeCell.poolDescrLabel:setColor(ccc3FromInt('#ffffff'))
    else
        typeCell.button:setNormalImage(RES_DICT.CELL_BTN_BG_N)
        typeCell.button:setSelectedImage(RES_DICT.CELL_BTN_BG_N)
        typeCell.poolNameLabel:setColor(ccc3FromInt('#76553b'))
        typeCell.poolDescrLabel:setColor(ccc3FromInt('#896d5f'))
    end
end
--[[
刷新listView
--]]
function CapsuleRandomPoolPreviewView:RefreshListView()
    local viewData = self:GetViewData()
    local listView = viewData.listView
    local listViewSize = viewData.listViewSize
    local index = self.preIndex
    local poolData = self.cardPoolDatas.option[index]
    local previewData = self.previewList_[index]
    local rateData = self.rateList_[index]
    local poolConfig = CommonUtils.GetConfig('gambling', 'randBuffChildPool', checkint(poolData.poolId))
    -- 清空listView
    listView:removeAllNodes()
    -- 创建内容layer
    local layer = CLayout:create()
    local descrLabel = display.newLabel(0, 0, fontWithColor(6, {text = poolConfig.descr2, w = 720, ap = cc.p(0, 1)}))
    layer:addChild(descrLabel, 1) 
    local probabilityBtn = display.newButton(0, 0, {n = RES_DICT.PROBABILITY_BTN, cb = handler(self, self.ProbabilityBtnCallback)})
    layer:addChild(probabilityBtn, 5)
    display.commonLabelParams(probabilityBtn, {text = __('概率'), color = '#ffffff', fontSize = 20})
    -- 计算layer大小
    local spaceA_H = 10
    local descrLabel_H = display.getLabelContentSize(descrLabel).height
    local spaceB_H = 50
    local rewardsBg_H = 46
    local layerSize_H = spaceA_H + descrLabel_H + spaceB_H

    local guaranteeLayout = nil
    local str = __('卡池内容')
    if previewData.guarantee and next(previewData.guarantee) ~= nil then
        guaranteeLayout = self:CreateRewardLayout(previewData.guarantee, __('以下飨灵每次十连保底获得其中一张'))
        layer:addChild(guaranteeLayout, 1)
        layerSize_H = layerSize_H + guaranteeLayout:getContentSize().height 
        str = __('其他飨灵')
    end
    local normalLayout = self:CreateRewardLayout(previewData.normal, str)
    layer:addChild(normalLayout, 1)
    layerSize_H = layerSize_H + normalLayout:getContentSize().height 

    local layerSize = cc.size(listViewSize.width, layerSize_H)
    layer:setContentSize(layerSize)
    -- 调整ui
    local temp_H = layerSize_H - spaceA_H
    display.commonUIParams(descrLabel, {po = cc.p(18, temp_H)})
    temp_H = temp_H - descrLabel_H - spaceB_H
    display.commonUIParams(probabilityBtn, {po = cc.p(listViewSize.width - 66, temp_H - rewardsBg_H / 2)})
    if guaranteeLayout then
        display.commonUIParams(guaranteeLayout, {po = cc.p(listViewSize.width / 2, temp_H), ap = cc.p(0.5, 1)})
        temp_H = temp_H - guaranteeLayout:getContentSize().height 
    end
    display.commonUIParams(normalLayout, {po = cc.p(listViewSize.width / 2, temp_H), ap = cc.p(0.5, 1)})
    listView:insertNodeAtLast(layer)
    listView:reloadData()
    listView:setContentOffsetToTop()

end
--[[
创建奖励列表Layout
@params cardDatas table 卡牌数据
title string 标题
--]]
function CapsuleRandomPoolPreviewView:CreateRewardLayout( cardDatas, title )
    -- 排序
    cardDatas = self:SortPreviewData(cardDatas)
    local cardNum = #checktable(cardDatas) -- 卡牌数目
    local viewData = self:GetViewData()
    local layout_W = viewData.listViewSize.width -- 容器宽
    local cardSpace = 30 -- 卡牌间距
    local verticalSpace = 16 -- 卡牌行间距
    local column = 5 -- 列
    local row = math.ceil(cardNum/column) -- 行
    local cardSize = cc.size(108, 108) -- 卡牌头像尺寸
    local scale = 1 -- 头像缩放比
    local space_H = 10 -- 留空高度
    local rewardsBg_H = 46 -- 标题栏高度
    local space_W = (layout_W - (column * (cardSize.width * scale)) - ((column - 1) * cardSpace)) / 2 -- 留空宽度
    local layoutSize = cc.size(layout_W, space_H + rewardsBg_H + (row * (cardSize.height * scale + 16)))
    
    local layout = CLayout:create(layoutSize)
    local rewardsBg = display.newImageView(RES_DICT.LIST_TYPE_BG, layoutSize.width / 2, layoutSize.height, {scale9 = true, size = cc.size(725, 44), ap = cc.p(0.5, 1)})
    layout:addChild(rewardsBg, 1)
    local rewardsTitle = display.newLabel(15, rewardsBg:getContentSize().height / 2, fontWithColor(6, {text = tostring(title), ap = cc.p(0, 0.5)}))
    rewardsBg:addChild(rewardsTitle, 1)

    local CreateGoodsNode = function ( i )
        local v = cardDatas[i]
        local goodsNode = require('common.GoodNode').new({
            id = v.cardId,
            showAmount = false,
            highlight = checkint(v.rare),
            callBack = function (sender) -- icon点击回调
                local goodsConf = CommonUtils.GetConfig('goods', 'goods', v.cardId)
                if tostring(goodsConf.type) == GoodsType.TYPE_CARD then
                    -- 卡牌类型
                    local cardPreviewView = require('common.CardPreviewView').new({
                        confId = v.cardId
                    })
                    display.commonUIParams(cardPreviewView, {ap = display.CENTER, po = display.center})
                    app.uiMgr:GetCurrentScene():AddDialog(cardPreviewView)
                elseif tostring(goodsConf.type) == GoodsType.TYPE_CARD_SKIN then
                    -- 皮肤类型
                    local layer = require('common.CommonCardGoodsDetailView').new({
                        goodsId = v.cardId
                    })
                    display.commonUIParams(layer, {ap = display.CENTER, po = display.center})
                    app.uiMgr:GetCurrentScene():AddDialog(layer)
                else
                    -- 其他
                    AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.cardId, type = 1})
                end

            end,
        })
        local cardRow = math.ceil(i/column)
        local cardColumn = i - (cardRow - 1) * column
        goodsNode:setAnchorPoint(cc.p(0, 1))
        goodsNode:setPosition(cc.p(space_W + (cardColumn - 1) * (cardSize.width * scale + cardSpace), layoutSize.height - space_H - rewardsBg_H - (cardRow - 1) * (cardSize.height * scale + verticalSpace)))
        layout:addChild(goodsNode, 1)
        -- 概率up
        if checkint(v.probabilityUp) == 1 then
            local upBg = display.newImageView(_res('ui/home/capsuleNew/common/summon_detail_bg_up.png'), goodsNode:getContentSize().width / 2, 20)
            upBg:setScale(0.9)
            goodsNode:addChild(upBg, 10)
            local upLabel = display.newLabel(upBg:getContentSize().width / 2, upBg:getContentSize().height / 2, {text = __('出现率up'), fontSize = 22, color = '#ffe08b'})
            upBg:addChild(upLabel, 1)
        end
    end

    local count = cardNum
    local index = 20
    if count > 20 then
        for i =1 , 20 do
            CreateGoodsNode(i)
        end
        layout:runAction(cc.Repeat:create(
            cc.Sequence:create(
                cc.DelayTime:create(0.04),
                cc.CallFunc:create(
                    function()
                        index = index +1
                        CreateGoodsNode(index)
                    end
                )
            ) , count - 20
        )
        )
    else
        for i =1 , count do
            CreateGoodsNode(i)
        end
    end

    return layout
end
--[[
卡池页签按钮回调
--]]
function CapsuleRandomPoolPreviewView:TabButtonCallback( sender )
    local index = sender:getTag()
    PlayAudioClip(AUDIOS.UI.ui_click_confirm.id)
    if index == self.preIndex then return end
    self:SwitchPool(index)
end
--[[
概率按钮点击回调
--]]
function CapsuleRandomPoolPreviewView:ProbabilityBtnCallback( sender )
    PlayAudioByClickNormal()
    local capsuleProbabilityView = require( 'Game.views.drawCards.CapsuleProbabilityView' ).new({rate = self.rateList_[self.preIndex]})
    local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(capsuleProbabilityView)
end
--[[
卡池概率按钮点击回调
--]]
function CapsuleRandomPoolPreviewView:PoolProbabilityBtnCallback( sender )
    PlayAudioByClickNormal()
    local capsuleProbabilityView = require( 'Game.views.drawCards.CapsuleProbabilityView' ).new({rate = self.poolRateList_})
    local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(capsuleProbabilityView)
end
--[[
切换卡池
@params index 卡池编号
--]]
function CapsuleRandomPoolPreviewView:SwitchPool( index )
    local viewData = self:GetViewData()
	--更新按钮状态
    local gridView = viewData.gridView
    local cell = gridView:cellAtIndex(self.preIndex - 1)
    local typeCell = self.typeCellDict_[cell]
    if typeCell then
        self:RefreshTypeCell(typeCell,false)
	end
    local selectedCell = gridView:cellAtIndex(index - 1)
    local selectedTypeCell = self.typeCellDict_[selectedCell]
    if selectedTypeCell then
        self:RefreshTypeCell(selectedTypeCell,true)
    end
    self.preIndex = index
    self:RefreshListView()
end
--[[
创建gridViewCell
@params size cc.size cell尺寸
--]]
CreateTypeCell = function(size)
    local view = CGridViewCell:new()
    view:setContentSize(size)
    local button = display.newButton(size.width / 2, size.height / 2, {n = RES_DICT.CELL_BTN_BG_N})
    view:addChild(button, 1)
    local poolNameLabel = display.newLabel(size.width / 2, size.height - 26, fontWithColor(4, {text = ''}))
    view:addChild(poolNameLabel, 1)
    local poolDescrLabel = display.newLabel(size.width / 2, 26, {text = '', color = '#896d5f', fontSize = 20})
    view:addChild(poolDescrLabel, 1)
    return {
        view           = view,
        button         = button,
        poolNameLabel  = poolNameLabel,
        poolDescrLabel = poolDescrLabel,
    }
end
--[[
获取viewData
--]]
function CapsuleRandomPoolPreviewView:GetViewData()
    return self.viewData_
end
return CapsuleRandomPoolPreviewView