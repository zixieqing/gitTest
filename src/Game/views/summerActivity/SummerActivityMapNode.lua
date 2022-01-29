--[[
活动副本地图关卡node
--]]
local VIEW_SIZE = cc.size(161, 198)
local SummerActivityMapNode = class('SummerActivityMapNode', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.activityMap.SummerActivityMapNode'
    node:enableNodeEvents()
    node:setCascadeOpacityEnabled(true)
	return node
end)

local summerActMgr = app.summerActMgr

local RES_DIR = {
    -- ICON_BTN        = _res("ui/home/activity/summerActivity/map/summer_activity_maps_1_icon_btn_unlock.png"),
    MAPS_NAME_BG    = _res('ui/home/activity/activityQuest/activity_maps_name_bg.png'),
    -- ICON_BTN_UNLOCK = _res("ui/home/activity/summerActivity/map/summer_activity_maps_1_icon_btn.png"),
    MONSTER_SHADOW  = _res('ui/home/activity/summerActivity/map/summer_activity_shadow.png'),
    PASS_BG         = _res('ui/common/maps_btn_pass_bg.png'),
    BG_FRAME        = _res('ui/home/activity/activityQuest/activity_maps_btn_plot.png')
}
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function SummerActivityMapNode:ctor( ... )
	local args = unpack({...}) or {}
	
	self:InitUI()
end

local CreateView = nil

local NODE_STATUS = {
    UNOPEN           = 0,   -- 未开启
    OPEN_AND_NOTPASS = 1,   -- 打开但未通过
    PASS             = 2,   -- 通过
}

local NODE_TYPES = {
    UNOPEN   = 0,   -- 未开启
    PLOT     = 1,   -- 剧情
    MONSTER  = 2,   -- 怪物
    BOSS     = 3,   -- BOSS
}
--[[
init ui
--]]
function SummerActivityMapNode:InitUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self.viewData_.view)
    end, __G__TRACKBACK__)
end

function SummerActivityMapNode:RefreshUI(data, chapterId, curNodeId)
    local viewData     = self:getViewData()
    
    self.data = data
    self.curNodeId = curNodeId
    local nodeType = data.type

    if viewData.unopenLayer then
        viewData.unopenLayer:setVisible(false)
    end

    if viewData.plotLayer then
        viewData.plotLayer:setVisible(false)
    end

    if viewData.monsterLayer then
        viewData.monsterLayer:setVisible(false)
    end

    if viewData.bossLayer then
        viewData.bossLayer:setVisible(false)
    end

    self:updateForkSpine()

    self:updateTitleLabel(viewData, data)
    if nodeType == NODE_TYPES.UNOPEN then
        self:UpdateUnopenLayer(viewData, data, chapterId)
    elseif nodeType == NODE_TYPES.MONSTER then
        local nodeStaus = checkint(data.status)
        local isPassed = nodeStaus == 2
        if isPassed then
            self:UpdateMonsterLayer(viewData, data)
        else
            self:UpdateBossLayer(viewData, data)
        end
    elseif nodeType == NODE_TYPES.PLOT then
        self:UpdatePlotLayer(viewData,data)
    elseif nodeType == NODE_TYPES.BOSS then
        self:UpdateBossLayer(viewData, data)
    end
    
end

function SummerActivityMapNode:updateForkSpine()
    local viewData = self:getViewData()
    
    if checkint(self.curNodeId) == checkint(self.nodeId) then
        if viewData.forkSpine == nil then
            local contentLayer = viewData.contentLayer
            local forkSpine = sp.SkeletonAnimation:create('arts/effects/map_fighting_fork.json', 'arts/effects/map_fighting_fork.atlas', 1)
            forkSpine:update(0)
            forkSpine:addAnimation(0, 'idle', true)
            contentLayer:addChild(forkSpine, 5)
            forkSpine:setPosition(cc.p(contentLayer:getContentSize().width/2, contentLayer:getContentSize().height - 20))
            viewData.forkSpine = forkSpine
        end
        viewData.forkSpine:setVisible(true)
        viewData.forkSpine:addAnimation(0, 'idle', true)
    elseif viewData.forkSpine then
        viewData.forkSpine:setVisible(false)
    end

end

function SummerActivityMapNode:updateTitleLabel(viewData, data)
    local titleBg    = viewData.titleBg
    local titleLabel = viewData.titleLabel
    display.commonLabelParams(titleLabel, {text = tostring(data.name)})

    local titleBgSize = titleBg:getContentSize()
    local titleLabelSize = display.getLabelContentSize(titleLabel)

    if titleLabelSize.width > (titleBgSize.width - 18) then
        titleBgSize = cc.size(titleLabelSize.width + 18, titleBgSize.height)
        titleBg:setContentSize(titleBgSize)
        display.commonUIParams(titleLabel, {po = cc.p(titleBgSize.width / 2, titleBgSize.height / 2)})
    end

end

function SummerActivityMapNode:UpdateUnopenLayer(viewData, data, chapterId)
    local unopenLayer = viewData.unopenLayer

    local img = summerActMgr:getUnopenImg(chapterId)
    if unopenLayer == nil then
        local contentLayer = viewData.contentLayer
        local contentLayerSize = contentLayer:getContentSize()

        local unopenLayer = display.newLayer(contentLayerSize.width / 2, contentLayerSize.height / 2, {ap = display.CENTER, size = contentLayerSize})
        contentLayer:addChild(unopenLayer)
        
        local imgSize = cc.size(154, 154)
        local imgLayer = display.newLayer(contentLayerSize.width / 2, 5, {
            size = imgSize, enable = true, ap = display.CENTER_BOTTOM, cb = handler(self, self.onBtnAction), color = cc.c4b(0,0,0,0)})
        unopenLayer:addChild(imgLayer)

        local unopenImg = display.newImageView(img, contentLayerSize.width / 2, 5, {ap = display.CENTER_BOTTOM})
        unopenLayer:addChild(unopenImg)

        viewData.unopenImg = unopenImg
        viewData.unopenLayer = unopenLayer
    end

    viewData.unopenLayer:setVisible(true)
    local unopenImg = viewData.unopenImg
    if unopenImg then
        unopenImg:setTexture(img)

        if self.curNodeId then
            if self.curNodeId ~= self.nodeId then
                unopenImg:setColor(cc.c4b(100, 100, 100, 100))
            else
                unopenImg:setColor(cc.c4b(255, 255, 255, 255))
            end
        else
            unopenImg:setColor(cc.c4b(255, 255, 255, 255))
        end

    end

end

function SummerActivityMapNode:UpdatePlotLayer(viewData, data)
    data = data or {}
    local newMonsterId = checkint(data.monsterId)
    local contentLayer = viewData.contentLayer
    if viewData.plotLayer == nil then
        viewData.plotLayer = self:CreateMonsterLayer(contentLayer, newMonsterId)
    else
        viewData.plotLayer:setVisible(true)
        local oldIconMonsterId = viewData.plotLayer:getTag()
        if oldIconMonsterId ~= newMonsterId then
            viewData.plotLayer:runAction(cc.RemoveSelf:create())
            viewData.plotLayer = self:CreateMonsterLayer(contentLayer, newMonsterId)
        end
    end

    local plotLayer = viewData.plotLayer
    local monsterBgBtn = plotLayer:getChildByName('monsterBgBtn')
    if monsterBgBtn then
        local bg = RES_DIR.BG_FRAME
        monsterBgBtn:setNormalImage(bg)
        monsterBgBtn:setSelectedImage(bg)
        local posY = 87
        monsterBgBtn:setPositionY(posY)
    end

    local clearMarkBg  = plotLayer:getChildByName('clearMarkBg')
    if clearMarkBg then
        local nodeStaus = checkint(data.status)
        local isPassed = nodeStaus == 2
        clearMarkBg:setVisible(isPassed)

        local clearMarkLabel  = clearMarkBg:getChildByName('clearMarkLabel')
        if clearMarkLabel then
            display.commonLabelParams(clearMarkLabel, {text = summerActMgr:getThemeTextByText(__('已收录'))})
        end
    end
end

function SummerActivityMapNode:UpdateMonsterLayer(viewData, data)
    data = data or {}
    local newMonsterId = checkint(data.monsterId)
    local contentLayer = viewData.contentLayer
    if viewData.monsterLayer == nil then
        viewData.monsterLayer = self:CreateMonsterLayer(contentLayer, newMonsterId, (data.type == NODE_TYPES.PLOT))
    else
        viewData.monsterLayer:setVisible(true)
        viewData.monsterLayer:runAction(cc.RemoveSelf:create())
        viewData.monsterLayer = self:CreateMonsterLayer(contentLayer, newMonsterId, (data.type == NODE_TYPES.PLOT))
    end

    local nodeStaus = checkint(data.status)
    local isPassed = nodeStaus == 2
    
    local monsterLayer = viewData.monsterLayer
    -- if isPassed then
        local monsterBgBtn = monsterLayer:getChildByName('monsterBgBtn')
        if monsterBgBtn then
            monsterBgBtn:setNormalImage(RES_DIR.PASS_BG)
            monsterBgBtn:setSelectedImage(RES_DIR.PASS_BG)
            monsterBgBtn:setPositionY(78)
        end
    
        local clearMarkBg  = monsterLayer:getChildByName('clearMarkBg')
        if clearMarkBg then
            clearMarkBg:setVisible(isPassed)
    
            local clearMarkLabel  = clearMarkBg:getChildByName('clearMarkLabel')
            if clearMarkLabel then
                display.commonLabelParams(clearMarkLabel, {text = summerActMgr:getThemeTextByText(__('已消灭'))})
            end
        end
    -- else
        
    -- end

end

function SummerActivityMapNode:UpdateBossLayer(viewData, data)
    local bossLayer = viewData.bossLayer
    local newMonsterId = checkint(data.monsterId)
    if bossLayer == nil then
        local contentLayer = viewData.contentLayer
        viewData.bossLayer = self:CreateBossLayer(contentLayer, newMonsterId)
    else
        viewData.bossLayer:setVisible(true)
        
        local bossImg = bossLayer:getChildByName('bossImg')
        if bossImg then
            bossImg:setTexture(AssetsUtils.GetCartoonPath(self:getIconId(newMonsterId)))
        end
    end
end


function SummerActivityMapNode:CreateMonsterLayer(parent, iconMonsterId)

    local parentSize = parent:getContentSize()

    local monsterLayer = display.newLayer(parentSize.width / 2, parentSize.height / 2, {ap = display.CENTER, size = parentSize})
    monsterLayer:setTag(checkint(iconMonsterId))
    parent:addChild(monsterLayer)

    local monsterBgBtn = display.newButton(parentSize.width/2, 77, {ap = display.CENTER, n = RES_DIR.PASS_BG, cb = handler(self, self.onBtnAction)})
    monsterBgBtn:setName('monsterBgBtn')
    monsterLayer:addChild(monsterBgBtn)

    
    local icon = self:getIconId(iconMonsterId)
    -- logInfo.add(5, 'icon = ' .. tostring(icon))
    -- 创建关卡怪物头像
    local headIconBg = display.newImageView(_res('ui/common/maps_btn_pass_head.png'), 0, 0)
    local headIconPath = AssetsUtils.GetCardHeadPath(icon)
    local headIcon = display.newImageView(headIconPath, 0, 0)

    local clippingNode = cc.ClippingNode:create()
    clippingNode:setCascadeOpacityEnabled(true)
	clippingNode:setInverted(false)
	clippingNode:setPosition(cc.p(parentSize.width / 2, parentSize.height / 2 + 2))
	monsterLayer:addChild(clippingNode)
	
	local drawnode = cc.DrawNode:create()
	local radius = 98
	drawnode:drawSolidCircle(cc.p(0,0),radius - 10,0,220,1.0,1.0,cc.c4f(0,0,0,1))
	clippingNode:setStencil(drawnode)
	clippingNode:addChild(headIcon)
	clippingNode:setScale(0.52)

    local clearMarkBg = display.newImageView(_res('ui/map/maps_bg_eliminate.png'), parentSize.width / 2, 85)
    clearMarkBg:setName('clearMarkBg')
    monsterLayer:addChild(clearMarkBg)
    clearMarkBg:setVisible(false)
    if not isElexSdk() then
        local clearMarkLabel = display.newLabel(utils.getLocalCenter(clearMarkBg).x, utils.getLocalCenter(clearMarkBg).y,
            {text = summerActMgr:getThemeTextByText(__('已消灭')), fontSize = fontWithColor('18').fontSize, color = fontWithColor('18').color})
        clearMarkLabel:setName('clearMarkLabel')
        clearMarkBg:addChild(clearMarkLabel)
    end

    return monsterLayer
end

function SummerActivityMapNode:CreateBossLayer(parent, iconMonsterId)

    local parentSize = parent:getContentSize()
    local bossLayer = display.newLayer(parentSize.width / 2, parentSize.height / 2, {ap = display.CENTER, size = parentSize})
    bossLayer:setTag(checkint(iconMonsterId))
    parent:addChild(bossLayer)

    local bossImg = AssetsUtils.GetCartoonNode(self:getIconId(iconMonsterId), parentSize.width / 2, 15, {ap = display.CENTER_BOTTOM})
    bossImg:setScale(0.45)
    bossImg:setName('bossImg')
    bossLayer:addChild(bossImg)

    local bossBtn = display.newLayer(parentSize.width / 2, 0, {size = cc.size(160,160), color = cc.r4b(0), enable = true, ap = display.CENTER_BOTTOM, cb = handler(self, self.onBtnAction)})
    bossBtn:setName('bossBtn')
    bossLayer:addChild(bossBtn)

    return bossLayer
end

CreateView = function (size)
    -- local color = cc.c4b(math.random(255), math.random(255), math.random(255), 255)
    local view = display.newLayer(0,0,{size = size})

    local titleBgSize = cc.size(100, 28)
    local titleBg = display.newImageView(_res('ui/home/activity/activityQuest/activity_maps_name_bg.png'), size.width / 2, 28, {ap = display.CENTER_TOP, scale9 = true, size = titleBgSize})
    titleBg:setCascadeOpacityEnabled(true)
    view:addChild(titleBg)
    
    local titleLabel = display.newLabel(titleBgSize.width / 2, titleBgSize.height / 2, fontWithColor(20, {ap = display.CENTER, fontSize = 22, outline = '#5b3c25', outlineSize = 1}))
    titleBg:addChild(titleLabel)

    local contentLayer = display.newLayer(size.width / 2, 28, {ap = display.CENTER_BOTTOM, size = cc.size(size.width, size.height - 28)})
    view:addChild(contentLayer)

    -- 节点阴影
    local shadow = display.newImageView(RES_DIR.MONSTER_SHADOW, size.width / 2, 12, {ap = display.CENTER_BOTTOM})
    -- shadow:setScale(0.7)
    contentLayer:addChild(shadow)
    
    return {
        view         = view,
        contentLayer = contentLayer,
        titleBg      = titleBg,
        titleLabel   = titleLabel,
    }
end


function SummerActivityMapNode:getIconId(iconMonsterId)
    local iconMonsterConf = CardUtils.GetCardConfig(iconMonsterId) or {}
    local icon = tostring(iconMonsterConf.drawId or iconMonsterId)
    return icon
end

function SummerActivityMapNode:getViewData()
    return self.viewData_
end

function SummerActivityMapNode:setNodeId(id)
    if id then
        self.nodeId = id
    end
end

function SummerActivityMapNode:onBtnAction(sender)
    local parent = sender:getParent()
    local tag = parent:getTag()
    
    AppFacade.GetInstance():DispatchObservers('SUMMER_ACTIVITY_CLICK_MAP_NODE_EVENT', {data = self.data, nodeId = self.nodeId})
end

return SummerActivityMapNode