--[[
 * descpt : 夏活 二级地图 界面
]]
local VIEW_SIZE = display.size
local SummerActivitySecondMapView = class('SummerActivitySecondMapView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.summerActivity.SummerActivitySecondMapView'
	node:enableNodeEvents()
	return node
end)

local SummerActivityMapNode = require('Game.views.summerActivity.SummerActivityMapNode')

local summerActMgr = app.summerActMgr

local SA_LOCATION = CommonUtils.GetConfigAllMess('location', 'summerActivity')
local CreateView = nil

local RES_DIR_ = {
    -- ICON_BTN_UNLOCK = _res("ui/home/activity/summerActivity/map/summer_activity_maps_1_icon_btn_unlock.png"),
    -- ICON_BTN        = _res("ui/home/activity/summerActivity/map/summer_activity_maps_1_icon_btn.png"),
    -- MAPS_NAME_BG    = _res('ui/home/activity/activityQuest/activity_maps_name_bg.png'),
    ACTIVITY_SUMMER_MAPS_1004 = _res("ui/home/activity/summerActivity/map/bg/activity_summer_maps_1004.jpg"),
    SUMMER_ACTIVITY_ICON_LAMP = _res('ui/home/activity/summerActivity/map/summer_activity_icon_lamp.png'),

    SPINE_ACTIVITY_TBZH_PATH     =  'ui/home/activity/summerActivity/map/spine/summer_activity_tbzh',
    SPINE_ACTIVITY_DENGLONG_PATH =  'ui/home/activity/summerActivity/map/spine/summer_activity_denglong',
    SPINE_SKELETON_PATH          =  'ui/home/activity/summerActivity/map/spine/skeleton',
}
local RES_DIR = {}
local NODE_POS = {
    {
        location = {x = 120, y = 450}
    },
    {
        location = {x = 340, y = 550}
    },
    {
        location = {x = 580, y = 550}
    },
    {
        location = {x = 840, y = 530}
    },
    {
        location = {x = 1080, y = 560}
    },
    {
        location = {x = 1200, y = 360}
    },
    {
        location = {x = 980, y = 200}
    },
    {
        location = {x = 710, y = 190}
    },
    {
        location = {x = 440, y = 210}
    },
    {
        location = {x = 220, y = 200}
    },
}

function SummerActivitySecondMapView:ctor( ... )
    RES_DIR = summerActMgr:resetResPath(RES_DIR_)
    RES_DIR.SPINE_ACTIVITY_DENGLONG = _spn(RES_DIR.SPINE_ACTIVITY_DENGLONG_PATH)
    RES_DIR.SPINE_ACTIVITY_TBZH = _spn(RES_DIR.SPINE_ACTIVITY_TBZH_PATH)
    RES_DIR.SPINE_SKELETON = _spn(RES_DIR.SPINE_SKELETON_PATH)

    self.args = unpack({...})
    self:initialUI()
end

function SummerActivitySecondMapView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

function SummerActivitySecondMapView:refreshUI(body)
    
end

function SummerActivitySecondMapView:updateBg(chapterId)
    local viewData = self:getViewData()
    local bg = viewData.bg
    bg:setTexture(summerActMgr:getSecondMapBgByChapterId(chapterId))
end

function SummerActivitySecondMapView:updateMapNodes(datas, nodeLocations, unlockId, cb)
    local viewData = self:getViewData()
    local mapNodes = viewData.mapNodes

    local chapterId   = datas.chapterId
    local nodeGroup   = datas.nodeGroup
    local nodeDatas   = datas.node

    for i, mapNode in ipairs(mapNodes) do
        if nodeLocations then
            local posConf = nodeLocations[i] or {x1 = 0, y1 = 0}
            display.commonUIParams(mapNode, {po = cc.p(posConf.x1, 1002 - posConf.y1)})
        end

        local nodeData = nodeDatas[tostring(i)]
        if nodeData then
            if unlockId ~= nil and checkint(i) == checkint(unlockId) then
                self:showUnlockSpine(mapNode, function ()
                    if cb then
                        cb()
                    end
                end)
            else
                self:updateMapNode(mapNode, nodeData, chapterId, datas.curNodeId)
            end
        end
    end

    local contentLayer = viewData.contentLayer
    contentLayer:setVisible(true)
end

function SummerActivitySecondMapView:updateMapNode(mapNode, nodeData, chapterId, curNodeId)
    mapNode:RefreshUI(nodeData, chapterId, curNodeId)
end

--==============================--
--desc: 播放解锁动画
--@params mapNode  userdata  地图节点
--@params cb  function  动画结束回调
--@return
--==============================--
function SummerActivitySecondMapView:showUnlockSpine(mapNode, cb)
    self.unlockSpineCb = cb
    if mapNode.unlockSpine == nil then

        local spineJson = RES_DIR.SPINE_ACTIVITY_TBZH.json
        local spineAtlas = RES_DIR.SPINE_ACTIVITY_TBZH.atlas
        local unlockSpine = nil
        if CommonUtils.checkIsExistsSpine(spineJson, spineAtlas) then
            unlockSpine = sp.SkeletonAnimation:create(spineJson, spineAtlas, 1)
            unlockSpine:update(0)
            unlockSpine:setPosition(cc.p(mapNode:getContentSize().width / 2, mapNode:getContentSize().height / 2))
            mapNode:addChild(unlockSpine, 5)

            unlockSpine:registerSpineEventHandler(function (event)
                if event.animation == 'idle' then
                    if self.unlockSpineCb then
                        self.unlockSpineCb()
                        self.unlockSpineCb = nil
                    end
                end
            end, sp.EventType.ANIMATION_END)

            mapNode.unlockSpine = unlockSpine
        end
    end
    
    self:playSpine(mapNode.unlockSpine, 'idle')
end


--==============================--
--desc: 播放灯笼动画
--@params mapNode  userdata  地图节点
--@params cb  function  动画结束回调
--@return
--==============================--
function SummerActivitySecondMapView:showLampnSpine(mapNode, cb)
    self.lampnSpineEndCb = cb
    if mapNode.lampnSpine == nil then
        local lampnSpineJson = RES_DIR.SPINE_ACTIVITY_DENGLONG.json
        local lampnSpineAtlas = RES_DIR.SPINE_ACTIVITY_DENGLONG.atlas
        if CommonUtils.checkIsExistsSpine(lampnSpineJson, lampnSpineAtlas) then
            local lampnSpine = sp.SkeletonAnimation:create(lampnSpineJson, lampnSpineAtlas, 1)
            lampnSpine:update(0)
            lampnSpine:setPosition(cc.p(mapNode:getContentSize().width / 2, mapNode:getContentSize().height / 2 - 50))
            mapNode:addChild(lampnSpine, 5)
            -- lampnSpine:setVisible(false)
            lampnSpine:registerSpineEventHandler(function (event)
                if event.animation == 'idle' then
                    if self.lampnSpineEndCb then
                        lampnSpine:setVisible(false)
                        self.lampnSpineEndCb()
                        self.lampnSpineEndCb = nil
                    end
                end
            end, sp.EventType.ANIMATION_END)
            mapNode.lampnSpine = lampnSpine
        end
    end
    self:playSpine(mapNode.lampnSpine, 'idle')
end

function SummerActivitySecondMapView:hideContentLayer()
    local viewData = self:getViewData()
    local contentLayer = viewData.contentLayer
    contentLayer:setVisible(false)
end

--==============================--
--desc: 播放动画
--@params spine  userdata  spine
--@params aniName  string  动画名
--@return
--==============================--
function SummerActivitySecondMapView:playSpine(spine, aniName)
    if spine then
        spine:setVisible(true)
        spine:setToSetupPose()
        spine:addAnimation(0, aniName, false)
    end
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()

    local bg = display.newImageView(RES_DIR.ACTIVITY_SUMMER_MAPS_1004, size.width / 2, size.height / 2, {ap = display.CENTER})
    view:addChild(bg)

    local actionBtns      = {}
    local facilitiesCells = {}
    -------------------------------------------------
    -- content layer
    local contentSize = cc.size(1624, 1002)
    local contentLayer = display.newLayer(size.width / 2, size.height / 2, {size = contentSize, ap = display.CENTER})
    view:addChild(contentLayer)

    local mapNodes = {}
    for i, posConf in ipairs(SA_LOCATION['1']['3']) do
        local node = SummerActivityMapNode.new()
        node:setNodeId(i)
        display.commonUIParams(node, {po = cc.p(posConf.x1, 1002 - posConf.y1), ap = display.CENTER_BOTTOM})
        contentLayer:addChild(node)

        table.insert(mapNodes, node)
    end
    contentLayer:setVisible(false)

    view:addChild(display.newLabel(display.SAFE_L, 10, fontWithColor(18, {ap = display.LEFT_BOTTOM, w = 800 , text = summerActMgr:getThemeTextByText(__('Tips：每次击退了本章节的小丑后，章节内的关卡点都会刷新重置。'))})))

    local cheatBtn = display.newButton(display.SAFE_R - 10, 50, {n = _res('ui/common/common_btn_orange.png'), ap = display.RIGHT_CENTER, scale9 = true})
    display.commonLabelParams(cheatBtn, fontWithColor(14, {text = summerActMgr:getThemeTextByText(__('引出小丑')), outline = '#5b3c25', outlineSize = 1, fontSize = 22, paddingW = 20}))
    view:addChild(cheatBtn)

    cheatBtn:addChild(display.newImageView(RES_DIR.SUMMER_ACTIVITY_ICON_LAMP, -14, 40, {ap = display.CENTER}))

    -------------------------------------------------
    -- content layer
    local paradiseLayerSize = cc.size(1624, 1002)
    local paradiseLayer = display.newLayer(size.width / 2, size.height / 2, {size = paradiseLayerSize, ap = display.CENTER})
    view:addChild(paradiseLayer)

    local skeletonSpineJson = RES_DIR.SPINE_SKELETON.json
    local skeletonSpineAtlas = RES_DIR.SPINE_SKELETON.atlas
    local skeletonSpine = nil
    if CommonUtils.checkIsExistsSpine(skeletonSpineJson, skeletonSpineAtlas) then
        skeletonSpine = sp.SkeletonAnimation:create(skeletonSpineJson, skeletonSpineAtlas, 1)
        skeletonSpine:update(0)
        skeletonSpine:setPosition(cc.p(paradiseLayerSize.width / 2, paradiseLayerSize.height / 2))
        paradiseLayer:addChild(skeletonSpine, 5)
        -- skeletonSpine:addAnimation(0, 'idle2', true)
        skeletonSpine:setVisible(false)
    end

    local bossTextConf = {
        fontWithColor(7, {text = summerActMgr:getThemeTextByText(__('小丑出现了!')), fontSize = 64, color = '#1100b5', ap = display.LEFT_CENTER}),
        fontWithColor(7, {text = summerActMgr:getThemeTextByText(__('小丑出现了!')), fontSize = 64, color = '#ff2828', ap = display.LEFT_CENTER}),
        fontWithColor(7, {text = summerActMgr:getThemeTextByText(__('小丑出现了!')), fontSize = 64, color = '#ffffff', ap = display.LEFT_CENTER}),
    }
    local bossTextLabels = {}
    for i, fontText in ipairs(bossTextConf) do
        local offsetX = (i-1) * 4
        local offsetY = (i-1) * -4
        local label = display.newLabel(200 + offsetX, 360 + offsetY, fontText)
        -- label:setScale(5)
        label:setVisible(false)
        paradiseLayer:addChild(label, 100)
        
        table.insert(bossTextLabels, label)
    end

    local cardDrawNode = require('common.CardSkinDrawNode').new({coordinateType = COORDINATE_TYPE_CAPSULE, notRefresh = true})
    display.commonUIParams(cardDrawNode, {ap = cc.p(0.1, 0.5), po = cc.p(display.width * 0.715, display.height * 0.35)})
    view:addChild(cardDrawNode,2)
    cardDrawNode:setVisible(false)

    return {
        view            = view,
        bg              = bg,
        actionBtns      = actionBtns,
        contentLayer    = contentLayer,
        mapNodes        = mapNodes,
        cheatBtn        = cheatBtn,
        skeletonSpine   = skeletonSpine,
        bossTextLabels  = bossTextLabels,
        -- lampnSpine      = lampnSpine,
        cardDrawNode    = cardDrawNode,
    }
end

function SummerActivitySecondMapView:getViewData()
	return self.viewData_
end

--==============================--
--desc: 显示地图节点改变动画
--@params oldNodeLocations 旧节点坐标列表
--@params nodeLocations    节点坐标列表
--@params cb               动画结束回调
--==============================--
function SummerActivitySecondMapView:showNodesChangeAni(oldDatas, oldNodeLocations, newDatas, nodeLocations, cb)
    local viewData = self:getViewData()
    
    local mapNodes = viewData.mapNodes

    -- 1.先将节点设置为旧的坐标与旧的节点状态
    self:updateMapNodes(oldDatas, oldNodeLocations)

    -- 2. 打乱map node 下标
    local t = shuffle({1,2,3,4,5,6,7,8,9,10})
    -- 3. 以3-3-4分布 初始化 map node状态
    local firstGroupMapIndexs = {}
    local firstGroupAction = {}
    local firstGroupEndAction = {}
    
    local secondGroupMapIndexs = {}
    local secondGroupAction = {}
    local secondGroupEndAction = {}

    local thirdGroupMapIndexs = {}
    local thirdGroupAction = {}
    local thirdGroupEndAction = {}

    for i, v in ipairs(t) do
        local mapIndex = t[i]
        local mapNode  = mapNodes[mapIndex]
        local toPos    = cc.p(0, 200)

        local endPosConf = nodeLocations[mapIndex]

        local ac = cc.Spawn:create({
            cc.TargetedAction:create(mapNode, cc.MoveBy:create(10 / 30, toPos)),
            cc.TargetedAction:create(mapNode, cc.FadeOut:create(10 / 30)),
        })

        local endAc = cc.Spawn:create({
            cc.TargetedAction:create(mapNode, cc.MoveTo:create(10 / 30, cc.p(endPosConf.x1, 1002 - endPosConf.y1))),
            cc.TargetedAction:create(mapNode, cc.FadeIn:create(10 / 30)),
        })
        if i <= 3 then
            table.insert(firstGroupMapIndexs, mapIndex)
            table.insert(firstGroupAction, ac)
            table.insert(firstGroupEndAction, endAc)
        elseif i <= 6 then
            table.insert(secondGroupMapIndexs, mapIndex)
            table.insert(secondGroupAction, ac) 
            table.insert(secondGroupEndAction, endAc)
        else
            table.insert(thirdGroupMapIndexs, mapIndex)
            table.insert(thirdGroupAction, ac)
            table.insert(thirdGroupEndAction, endAc)
        end
    end
    
    local chapterId   = newDatas.chapterId
    local nodeDatas   = newDatas.node
    local curNodeId   = newDatas.curNodeId
    local updateNodesDataCb = function (mapNodeIndexs)
        for i, mapNodeIndex in ipairs(mapNodeIndexs) do
            local nodeData = nodeDatas[tostring(mapNodeIndex)]
            
            local mapNode  = mapNodes[mapNodeIndex]
            self:updateMapNode(mapNode, nodeData, chapterId, curNodeId)
        end
    end
    
    self:runAction(cc.Spawn:create({
        cc.Sequence:create({
            cc.Spawn:create(firstGroupAction),
            cc.CallFunc:create(function ()
                -- todo 更新所有 first_group node data
                updateNodesDataCb(firstGroupMapIndexs)

            end),
            cc.DelayTime:create(10 / 30),
            cc.Spawn:create(firstGroupEndAction),
        }),
        cc.Sequence:create({
            cc.DelayTime:create(5 / 30),
            cc.Spawn:create(secondGroupAction),            
            cc.CallFunc:create(function ()
                -- todo 更新所有 second_group node data
                updateNodesDataCb(secondGroupMapIndexs)

            end),
            cc.DelayTime:create(10 / 30),
            cc.Spawn:create(secondGroupEndAction),
        }),
        cc.Sequence:create({
            cc.DelayTime:create(10 / 30),
            cc.Spawn:create(thirdGroupAction),           
            cc.CallFunc:create(function ()
                -- todo 更新所有 third_group node data
                updateNodesDataCb(thirdGroupMapIndexs)
                
            end),
            cc.DelayTime:create(10 / 30),
            cc.Spawn:create(thirdGroupEndAction),
        }),
        cc.DelayTime:create(40 / 30),
        cc.CallFunc:create(function ()
            if cb then
                cb()
            end
        end)
    }))
end

--==============================--
--desc: 显示剧情出现动画
--@params cardId  int  卡牌id
--@params cb  function  动画结束回调
--@return
--==============================--
function SummerActivitySecondMapView:showPlotAni(cb, cardId)
    PlayAudioClip(AUDIOS.UI.ui_cutin_story.id)
    local aniName = 'idle2'
    local viewData = self:getViewData()
    local skeletonSpine = viewData.skeletonSpine
    local bossTextLabels = viewData.bossTextLabels
    local cardDrawNode = viewData.cardDrawNode

    if cardId and checkint(cardId) > 0 then
        cardDrawNode:RefreshAvatar({confId = cardId})
    end

    local plotConf = {
        {'#ff6a6a', summerActMgr:getThemeTextByText(__('触发新剧情~'))},
        {'#ffa9a9', summerActMgr:getThemeTextByText(__('触发新剧情~'))},
        {'#ffffff', summerActMgr:getThemeTextByText(__('触发新剧情~'))},
    }

    local bossTextLabelPos = {}
    for i, v in ipairs(bossTextLabels) do
        local color, text = unpack(plotConf[i])
        display.commonLabelParams(v, {color = color, text = text})
        v:setOpacity(0)
        table.insert(bossTextLabelPos, {v:getPositionX(), v:getPositionY()})
    end

    local labelAction = function (label)
        local labelPos = cc.p(label:getPositionX(), label:getPositionY())
        label:setOpacity(0)
        label:setPosition(cc.p(label:getPositionX(), 0))
        return {
            cc.DelayTime:create(1/ 30),
            cc.TargetedAction:create(label, cc.Show:create()),
            cc.Spawn:create({
                cc.TargetedAction:create(label, cc.MoveBy:create(15 / 30, cc.p(0, 320))),
                cc.TargetedAction:create(label, cc.FadeIn:create(15 / 30)),
            })
        }
    end
    
    local spawnAction = {}
    local spawnAction1 = {}
    for i, label in ipairs(bossTextLabels) do
        table.insert(spawnAction1, cc.TargetedAction:create(label, cc.MoveBy:create(20 / 30, cc.p(0, 100))))
        -- table.insert(spawnAction1, cc.TargetedAction:create(label, cc.MoveBy:create(20 / 30, cc.p(0, 200))))

        local actionList = labelAction(label)
        for i, v in ipairs(actionList) do
            table.insert(spawnAction, v)
        end
    end

    self:runAction(cc.Sequence:create({
        cc.CallFunc:create(function ()
            self:playSpine(skeletonSpine, aniName)
            cardDrawNode:setVisible(true)
        end),
        cc.DelayTime:create(4 / 30),
        cc.Spawn:create(spawnAction),
        cc.Spawn:create(spawnAction1),
        cc.Spawn:create({
            cc.TargetedAction:create(bossTextLabels[1], cc.MoveBy:create(10 / 30, cc.p(0, 20))),
            cc.TargetedAction:create(bossTextLabels[1], cc.FadeOut:create(10 / 30)),
            cc.TargetedAction:create(bossTextLabels[2], cc.MoveBy:create(10 / 30, cc.p(0, 20))),
            cc.TargetedAction:create(bossTextLabels[2], cc.FadeOut:create(10 / 30)),
            cc.TargetedAction:create(bossTextLabels[3], cc.MoveBy:create(10 / 30, cc.p(0, 20))),
        }),
        cc.TargetedAction:create(bossTextLabels[3], cc.FadeOut:create(5 / 30)),
        cc.CallFunc:create(function ()
            cardDrawNode:setVisible(false)
            if cb then
                cb()
                cb = nil
            end
        end),
        
    }))

end


--==============================--
--desc: 显示boss出现动画
--@params cb  function  视图动画结束回调
--@return 
--==============================--
function SummerActivitySecondMapView:showBossAni(cb)
    PlayAudioClip(AUDIOS.UI.ui_cutin_boss.id)
    local aniName = 'idle1'
    local viewData = self:getViewData()
    local skeletonSpine = viewData.skeletonSpine
    local bossTextLabels = viewData.bossTextLabels

    local labelAction = function (label)
        local labelPos = cc.p(label:getPositionX(), label:getPositionY())
        label:setScale(5)
        label:setPosition(cc.p(labelPos.x, labelPos.y + 300))
        label:setOpacity(255)
        return {
            cc.DelayTime:create(1/ 30),
            cc.TargetedAction:create(label, cc.Show:create()),
            cc.Spawn:create({
                cc.TargetedAction:create(label, cc.ScaleTo:create(5 / 30, 1)),
                cc.TargetedAction:create(label, cc.MoveTo:create(5 / 30, labelPos)),
            })
        }
    end

    local bossConf = {
        {'#1100b5', summerActMgr:getThemeTextByText(__('小丑出现了!'))},
        {'#ff2828', summerActMgr:getThemeTextByText(__('小丑出现了!'))},
        {'#ffffff', summerActMgr:getThemeTextByText(__('小丑出现了!'))},
    }

    local spawnAction = {}
    for i, label in ipairs(bossTextLabels) do
        local color, text = unpack(bossConf[i])
        display.commonLabelParams(label, {color = color, text = text})
        local actionList = labelAction(label)
        for i, v in ipairs(actionList) do
            table.insert(spawnAction, v)
        end
    end

    local spawnAction1 = {}
    for i, label in ipairs(bossTextLabels) do
        table.insert(spawnAction1, cc.TargetedAction:create(label, cc.FadeOut:create(10 / 30)))
    end
    local action = {
        cc.CallFunc:create(function ()
            self:playSpine(skeletonSpine, aniName)        
        end),
        cc.DelayTime:create(35 / 30),
        cc.Spawn:create(spawnAction),
        cc.DelayTime:create(30 / 30),
        cc.Spawn:create(spawnAction1),
        cc.CallFunc:create(function ()
            if cb then
                cb()
                cb = nil
            end
        end)
    }

    self:runAction(cc.Sequence:create(action))
    
end

return SummerActivitySecondMapView