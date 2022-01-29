--[[
 * author : kaishiqi
 * descpt : 测试场景
]]
local GameScene  = require('Frame.GameScene')
local DebugScene = class('DebugScene', GameScene)


function DebugScene:ctor()
    self.super.ctor(self, 'DebugScene')
    
    -- init views
    self:AddGameLayer(ui.image({img = 'update/update_bg.jpg', p = display.center, isFull = true}))
    self:AddGameLayer(ui.layer({color = '#00000096'}))
    
    -- back button
    self.backBtn_ = ui.button({x = display.SAFE_L + 75, y = display.height - 52, n = 'ui/common/common_btn_back.png'})
    display.commonUIParams(self.backBtn_, {cb = function(sender)
        PlayAudioByClickClose()
        app:RegistMediator(require('Game.mediator.AuthorMediator').new())
    end})
    self:AddGameLayer(self.backBtn_)

    -- init userInfo
    app.gameMgr:InitialUserInfo()
    app.gameMgr:CheckLocalPlayer()
end


function DebugScene:onEnter()
    self:showDebugView()
    -- self:testSpine_()
end
function DebugScene:onExit()
end


function DebugScene:showDebugView()
    local testFuncLayer = display.newLayer() 
    self:AddGameLayer(testFuncLayer)

    local testFuncDefines = {
        {name = 'live2d预览', func = handler(self, self.live2dBrowser_)},
        {name = '全剧情测试',  func = handler(self, self.allStoryBrowser_)},
        {name = '音频浏览器',  func = handler(self, self.acbBrowser_)},
        {name = '餐厅主题',    func = handler(self, self.testAvatar_)},
        {name = '主界面主题',  func = handler(self, self.testHomeTheme_)},
        {name = 'VoProxy',   func = handler(self, self.testVoProxy_)},
        {name = '视图布局',    func = handler(self, self.testLayout_)},
        {name = '模拟战斗',    func = handler(self, self.testBattle_)},
        {name = 'Spine测试',  func = handler(self, self.testSpine_)},
        {name = 'Shader测试', func = handler(self, self.testShader_)},
        {name = 'ViewLoader', func = handler(self, self.testViewLoader_)},
        -- setBlendFunc
        {name = 'DebugScene2', func = function()
            app.uiMgr:SwitchToTargetScene('debug.DebugScene2')
        end, retain = true},
    }
    local TEST_BTN_COLS = 5
    local TEST_BTN_ROWS = math.ceil(#testFuncDefines / TEST_BTN_COLS)
    local TEST_BTN_GAPH = 50
    local TEST_BTN_GAPW = 20
    local TEST_BTN_SIZE = cc.size(180, 80)
    local TEST_BTN_OFFX = (TEST_BTN_COLS/2-0.5) * (TEST_BTN_SIZE.width + TEST_BTN_GAPW)
    local TEST_BTN_OFFY = (TEST_BTN_ROWS/2-0.5) * (TEST_BTN_SIZE.height + TEST_BTN_GAPH)
    for index, define in ipairs(testFuncDefines) do
        local funcBtnRow  = math.ceil(index / TEST_BTN_COLS)
        local funcBtnCol  = (index-1) % TEST_BTN_COLS + 1
        local testFuncBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png'), scale9 = true, size = TEST_BTN_SIZE})
        display.commonLabelParams(testFuncBtn, fontWithColor(19, {text = tostring(define.name)}))
        testFuncBtn:setPositionX(display.cx - TEST_BTN_OFFX + (funcBtnCol-1) * (TEST_BTN_SIZE.width + TEST_BTN_GAPW))
        testFuncBtn:setPositionY(display.cy + TEST_BTN_OFFY - (funcBtnRow-1) * (TEST_BTN_SIZE.height + TEST_BTN_GAPH))
        testFuncBtn:setTag(index)
        testFuncLayer:addChild(testFuncBtn)
        testFuncBtn:setOnClickScriptHandler(function(sender)
            local funcIndex = sender:getTag()
            local funcFunc  = testFuncDefines[funcIndex].func
            local isRetain  = testFuncDefines[funcIndex].retain
            if not isRetain then
                testFuncLayer:runAction(cc.RemoveSelf:create())
                self.backBtn_:setVisible(false)
            end
            funcFunc()
        end)
    end
    self.backBtn_:setVisible(true)
end


function DebugScene:addCloseButton_(parentNode, closeCB)
    local closeBtn = display.newButton(display.SAFE_R - 40, 50, {})
    display.commonLabelParams(closeBtn, fontWithColor(20, {outlineSize = 8, text = 'x'}))
    display.commonUIParams(closeBtn, {cb = function(sender)
        -- close
        parentNode:removeFromParent()
        if closeCB then closeCB() end
        -- reload self
        unrequire('debug.DebugScene3')
        local d3 = require('debug.DebugScene3')
        for key, _ in pairs(d3) do
            self[key] = d3[key]
        end
        -- show
        self:showDebugView()
    end})
    parentNode:addChild(closeBtn, 100)
    return closeBtn
end


function DebugScene:addScrollDescrView_(parentNode)
    -- table view
    local tableSize = display.SAFE_SIZE
    local tableView = ui.tableView({bgColor = cc.c4b(33,66,99,200), size = tableSize, ap = ui.cc, csizeH = 28, dir = display.SDIR_V, p = display.center})
    parentNode:addChild(tableView)

    tableView.sourceData = {}

    tableView:setCellCreateHandler(function(cellParent)
        local view = cellParent
        local size = view:getContentSize()
        local cpos = cc.sizep(size, ui.cc)

        local logLabel = ui.label({p = cc.p(5,0), fnt = FONT.TEXT20, color = '#CCCCCC', ap = ui.lb})
        logLabel:setSystemFontName('Menlo')
        view:addChild(logLabel)

        return {
            view     = view,
            logLabel = logLabel,
        }
    end)

    tableView:setCellUpdateHandler(function(cellIndex, cellViewData)
        if cellViewData == nil then return end
        local logInfoText = tableView.sourceData[cellIndex] or ''
        cellViewData.logLabel:setString(checkstr(logInfoText))
    end)
    
    -- update views
    tableView.updateDescr = function(obj, descr)
        obj.sourceData = {}
        obj:appendDescr(descr)
    end
    tableView.appendDescr = function(obj, descr)
        local sourceLen = #obj.sourceData
        local descrList = string.split(tostring(descr), '\n')
        for i,v in ipairs(descrList) do
            obj.sourceData[sourceLen + i] = v
        end
        obj:resetCellCount(sourceLen + #descrList)
        obj:setContentOffsetToBottom()
    end

    return tableView
end


-------------------------------------------------------------------------------
-- live2d
-------------------------------------------------------------------------------
function DebugScene:live2dBrowser_()
    -- override
    local originFunc1 = CardUtils.GetCardDrawNameBySkinId
    CardUtils.GetCardDrawNameBySkinId = function(skinId)
        if CardUtils.GetCardSkinConfig(skinId) then
            return originFunc1(skinId)
        else
            return skinId
        end
    end

    -- browser layer
    local browserLayer = display.newLayer()
    self:AddGameLayer(browserLayer)

    browserLayer:addChild(display.newLabel(display.SAFE_R - 40, display.height - 30, fontWithColor(3, {ap = display.RIGHT_CENTER, text = '资源路径 res/arts/live2d/...'})))

    -- close button
    self:addCloseButton_(browserLayer, function()
        app.cardL2dNode.CleanEnv()
    end)
    
    local DEFALUT_SCALE = 0.55
    self.browserData_ = {
        cardId   = 0,      -- 正在观看的卡牌id
        bgMode   = false,  -- 背景模式（是否观看背景）
        l2dNode  = nil,    -- live2d node
        scaleBar = nil,
        touchPos = nil,
    }

    -------------------------------------------------
    -- live2d layer
    local l2dLayer = display.newLayer()
    browserLayer:addChild(l2dLayer)

    local touchListener = cc.EventListenerTouchOneByOne:create()
    touchListener:setSwallowTouches(true)
    touchListener:registerScriptHandler(function(touch, event)
        if self.browserData_.l2dNode and checkint(touch:getLocation().x) > display.SAFE_L + 250 then
            self.browserData_.touchPos = touch:getLocation()
            self.browserData_.l2dNodeX = self.browserData_.l2dNode:getPositionX()
            self.browserData_.l2dNodeY = self.browserData_.l2dNode:getPositionY()
        end
        return true
    end, cc.Handler.EVENT_TOUCH_BEGAN)
    touchListener:registerScriptHandler(function(touch, event)
        if self.browserData_.touchPos then
            local beganPos = self.browserData_.touchPos
            local movedPos = touch:getLocation()
            self.browserData_.l2dNode:setPositionX(self.browserData_.l2dNodeX + (movedPos.x - beganPos.x))
            self.browserData_.l2dNode:setPositionY(self.browserData_.l2dNodeY + (movedPos.y - beganPos.y))
        end
    end, cc.Handler.EVENT_TOUCH_MOVED)
    touchListener:registerScriptHandler(function(touch, event)
        self.browserData_.touchPos = nil
    end, cc.Handler.EVENT_TOUCH_ENDED)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(touchListener, l2dLayer)


    -- motion layer
    local motionLayer = display.newLayer()
    browserLayer:addChild(motionLayer)
    
    -- init l2d env
    app.cardL2dNode.InitEnv(l2dLayer)

    -- show l2d model
    local scaleL2dModel = function(scaleNum)
        if self.browserData_.l2dNode then
            self.browserData_.l2dNode:setScale(scaleNum)
        end
        if self.browserData_.scaleBar then
            self.browserData_.scaleBar:setText(string.format('%0.2f', scaleNum))
        end
    end

    local showL2dModel = function()
        if self.browserData_.l2dNode then
            self.browserData_.l2dNode:removeFromParent()
        end

        --
        local l2dCardId   = self.browserData_.cardId
        local l2dName     = self.browserData_.name
        local showBgMode  = self.browserData_.bgMode
        local l2dCardNode = app.cardL2dNode.new({roleId = l2dCardId == -1 and l2dName or l2dCardId, bgMode = showBgMode})
        l2dCardNode:setAnchorPoint(display.LEFT_BOTTOM)
        l2dCardNode:setScale(DEFALUT_SCALE)
        l2dLayer:addChild(l2dCardNode)


        --
        motionLayer:removeAllChildren()
        local btnGapY = 62
        local offsetY = display.cy - (#l2dCardNode:getMotionList() / 2 - 0.5) * btnGapY
        for index, motionName in ipairs(l2dCardNode:getMotionList()) do
            local motionBtn = display.newButton(display.SAFE_R - 100, offsetY + (index-1) * btnGapY, {n = 'ui/common/common_btn_white_default_2.png', scale9 = true, size = cc.size(180,62)})
            display.commonLabelParams(motionBtn, fontWithColor(1, {text = motionName}))
            motionBtn:setName(motionName)
            display.commonUIParams(motionBtn, {cb = function(sender)
                l2dCardNode:setMotion(sender:getName())
            end})
            motionLayer:addChild(motionBtn)
        end

        --
        self.browserData_.l2dNode = l2dCardNode
        scaleL2dModel(DEFALUT_SCALE)
    end

    
    -------------------------------------------------
    -- control layer
    local controlLayer = display.newLayer()
    browserLayer:addChild(controlLayer)
    
    local bgControlLayer = display.newLayer()
    controlLayer:addChild(bgControlLayer)
    bgControlLayer:setVisible(false)

    local haveBgBtn = display.newButton(display.cx + 200, display.height - 50, {n = 'ui/common/common_btn_white_default.png'})
    local noneBgBtn = display.newButton(display.cx - 200, display.height - 50, {n = 'ui/common/common_btn_white_default.png'})
    display.commonLabelParams(noneBgBtn, fontWithColor(14, {text = '无背景'}))
    display.commonLabelParams(haveBgBtn, fontWithColor(14, {text = '有背景'}))
    bgControlLayer:addChild(haveBgBtn)
    bgControlLayer:addChild(noneBgBtn)

    display.commonUIParams(haveBgBtn, {cb = function(sender)
        self.browserData_.bgMode = true
        showL2dModel()
    end})
    display.commonUIParams(noneBgBtn, {cb = function(sender)
        self.browserData_.bgMode = false
        showL2dModel()
    end})


    local scaleNumBar = display.newButton(display.cx, display.height - 50, {n = 'ui/home/market/market_buy_bg_info.png', scale9 = true, size = cc.size(150, 40)})
    display.commonLabelParams(scaleNumBar, fontWithColor(1, {text = tostring(DEFALUT_SCALE)}))
    controlLayer:addChild(scaleNumBar)
    self.browserData_.scaleBar = scaleNumBar

    local plusBtn  = display.newButton(display.cx + 80, display.height - 50, {n = 'ui/home/market/market_sold_btn_plus.png'})
    local minusBtn = display.newButton(display.cx - 80, display.height - 50, {n = 'ui/home/market/market_sold_btn_sub.png'})
    controlLayer:addChild(minusBtn)
    controlLayer:addChild(plusBtn)

    display.commonUIParams(scaleNumBar, {cb = function(sender)
        local l2dCardNode = self.browserData_.l2dNode
        if l2dCardNode then
            scaleL2dModel(DEFALUT_SCALE)
            l2dCardNode:setPosition(PointZero)
        end
    end})
    display.commonUIParams(plusBtn, {cb = function(sender)
        local l2dCardNode = self.browserData_.l2dNode
        if l2dCardNode then
            scaleL2dModel(math.min(3, l2dCardNode:getScale() + 0.05))
        end
    end})
    display.commonUIParams(minusBtn, {cb = function(sender)
        local l2dCardNode = self.browserData_.l2dNode
        if l2dCardNode then
            scaleL2dModel(math.max(0, l2dCardNode:getScale() - 0.05))
        end
    end})


    -------------------------------------------------
    -- card listView
    local cardListSize = cc.size(200, display.height)
    local cardListView = CListView:create(cardListSize)
    cardListView:setDirection(eScrollViewDirectionVertical)
    cardListView:setBackgroundColor(cc.c4b(255,255,255,100))
    cardListView:setPosition(cc.p(display.SAFE_L + 110, display.cy))
    browserLayer:addChild(cardListView)

    local lFileSystem = require('lfs')
    local l2dResPath  = 'res/arts/live2d'
    if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_MAC then
        if utils.isExistent(l2dResPath) then
            l2dResPath = app.fileUtils:fullPathForFilename(l2dResPath)
        else
            l2dResPath = app.fileUtils:getWritablePath() .. l2dResPath
        end
    end

    -- local drawNameMap  = {}
    -- local cardConfs    = CommonUtils.GetConfigAllMess('cardSkin', 'goods') or {}
    -- local monsterConfs = CommonUtils.GetConfigAllMess('monsterSkin', 'monster') or {}
    -- for skinId, cardConf in pairs(cardConfs) do
    --     drawNameMap[tostring(cardConf.drawId)] = {cardId = skinId, isMonster = false}
    -- end
    -- for skinId, monsterConf in pairs(monsterConfs) do
    --     drawNameMap[tostring(monsterConf.drawId)] = {cardId = monsterConf.cardId, isMonster = true}
    -- end
    
    local cardsMaps = {}
    for file in lFileSystem.dir(l2dResPath) do
        if file ~= '.' and file ~= '..' then
            local attr = lFileSystem.attributes(l2dResPath ..'/'.. file)
            if attr and attr.mode == 'directory' then
                local hasBg  = string.match(file, '_bg') ~= nil
                local name   = string.gsub(file, '_bg', '')
                local cardId = name--drawNameMap[name] and checkint(drawNameMap[name].cardId) or -1
                cardsMaps[tostring(cardId)] = cardsMaps[tostring(cardId)] or {}
                cardsMaps[tostring(cardId)].name   = name
                cardsMaps[tostring(cardId)].cardId = cardId
                cardsMaps[tostring(cardId)].hasBg  = cardsMaps[tostring(cardId)].hasBg == true and true or hasBg
            end
        end
    end

    local cardsList = table.values(cardsMaps)
    table.sort(cardsList, function(a, b)
        local aName = checkint(string.split2(a.name, '_')[1])
        local bName = checkint(string.split2(b.name, '_')[1])
        return aName < bName
        -- return checkint(a.cardId) < checkint(b.cardId)
    end)
    local cellSize  = cc.size(cardListSize.width, 62)
    local btnSize  = cc.size(cellSize.width-8, cellSize.height-4)
    for index, cardData in ipairs(cardsList) do
        local listCell = display.newLayer(0, 0, {size = cellSize})
        local cardBtn  = display.newButton(cellSize.width/2, cellSize.height/2, {n = 'ui/common/common_btn_white_default_s.png', scale9 = true, size = btnSize})
        display.commonLabelParams(cardBtn, fontWithColor(1, {text = cardData.name}))
        cardBtn:setTag(index)
        display.commonUIParams(cardBtn, {cb = function(sender)
            local selectData = cardsList[sender:getTag()]
            self.browserData_.cardId = selectData.cardId
            self.browserData_.name   = selectData.name
            self.browserData_.bgMode = false
            bgControlLayer:setVisible(selectData.hasBg)
            showL2dModel()
        end})
        listCell:addChild(cardBtn)
        cardListView:insertNodeAtLast(listCell)
    end
    cardListView:reloadData()
end


-------------------------------------------------------------------------------
-- story
-------------------------------------------------------------------------------
function DebugScene:allStoryBrowser_()
    -- confParserDefine['plot/story0'].excelPath = '/Users/kaishiqi/Downloads/p2_food/功能/剧情' .. confParserDefine['plot/story0'].excelPath

    -- pre-settings
    app.gameMgr:InitialUserInfo()
    app.gameMgr:UpdatePlayer({playerId = 1, playerName = 'Debuger'})
    CommonUtils.SetControlGameProterty(CONTROL_GAME.CONRROL_MUSIC, true)
    CommonUtils.SetControlGameProterty(CONTROL_GAME.GAME_MUSIC_EFFECT, true)
    cc.UserDefault:getInstance():flush()

    local storyBrowserDefines = {
        { name = '新主线剧情', json = {
            'plot/story0',
            'plot/story1',
            'plot/story2',
            'plot/story3',
            'plot/story4',
            'plot/story5',
        }},
        -- { name = '旧主线',     json = 'quest/questStory' },
        -- { name = '旧支线',     json = 'quest/branchStory' },
        { name = '老春活：年夜饭', json = 'seasonActivity/springStory' },
        { name = '19春活：古　堡', json = 'springActivity/story' },
        { name = '20春活：花　园', json = 'springActivity2020/story' },
        { name = '18夏活：打年兽', json = 'summerActivity/summerStory' },
        { name = '19夏活：杀人案', json = 'newSummerActivity/story' },
        { name = '2018 周年庆',   json = 'anniversary/anniversaryStory' },
        { name = '2019 周年庆',   json = 'anniversary2/story' },
        { name = '2020 周年庆',   json = 'anniversary2020/story' },
        { name = 'SP飨灵剧情',    json = 'collection/spStory' },
        { name = '活动副本',      json = {
            { path = 'activityQuest/cardWords', sub = 50, idx = 1 },
        }},
        { name = '飨灵比拼',      json = 'cardComparison/comparisonStory' },
        { name = '联动种菜',      json = 'activity/farmStory' },
        { name = 'PT本',         json = 'pt/story' },
        { name = '腊八',         json = 'activity/festivalStory' },
        { name = '酒吧',         json = 'bar/customerStory' },
        { name = '往期活动剧情',  json = {
            { path = 'plot/historyActivityDailyStory', sub = 10, idx = 1 },
            { path = 'plot/historyActivityPTStory', sub = 3, idx = 55 },
            { path = 'plot/historyActivityStory', sub = 20,  idx = 101},
        }},
    }

    local storySupportDefines = {
        -- { name = '新主线：序章四选一语音', json = 'plot/storyVoice' },
        -- { name = '新主线收录坐标表',      json = 'plot/collectCoordinate' },
        -- { name = '关卡剧情关联表',        json = 'plot/storyReward' },
        { name = '剧情物品道具表',        json = 'plot/plotGoods' },
        { name = '角色ID表',             json = 'plot/role' },
    }

    self.browserData_ = {
        selectStoryBtn  = nil,
        chapterGridData = nil,
        chapterGridView = nil,
        excelListView   = nil,
    }

    -- root panel
    local CONTENT_SIZE   = cc.size(1000, 720)
    local STORY_BTN_SIZE = cc.size(220, 42)
    local rootPanel      = display.newLayer()
    self:AddGameLayer(rootPanel)

    -- close button
    self:addCloseButton_(rootPanel, function()
        StopBGMusic()
    end)
    
    
    -- story btn list
    local listSize = cc.size(STORY_BTN_SIZE.width, CONTENT_SIZE.height - 20)
    local listView = ui.listView({size = listSize})
    listView:setPositionX(display.cx - CONTENT_SIZE.width/2 + STORY_BTN_SIZE.width/2 + 6)
    listView:setPositionY(display.cy)
    listView:setAnchorPoint(display.RIGHT_CENTER)
    -- listView:setBackgroundColor(cc.r4b(150))
    rootPanel:addChild(listView)
    
    for index, storyDefine in ipairs(storyBrowserDefines) do
        local aRowNode = ui.layer({size = cc.resize(STORY_BTN_SIZE, 0, 4)})
        listView:insertNodeAtLast(aRowNode)
        
        local storyBtn = display.newToggleView(0, 0, {scale9 = true, size = STORY_BTN_SIZE, n = 'ui/home/kitchen/cooking_prop_bar_1.png', s = 'ui/home/kitchen/cooking_prop_bar_2.png'})
        display.commonLabelParams(storyBtn, fontWithColor(4, {text = tostring(storyDefine.name)}))
        storyBtn:setPosition(utils.getLocalCenter(aRowNode))
        storyBtn:setTag(index)
        aRowNode:addChild(storyBtn)

        local onClickStoryBtn = function(sender)
            if self.browserData_.selectStoryBtn then
                self.browserData_.selectStoryBtn:setChecked(false)
            end
            
            local storyDefine  = storyBrowserDefines[sender:getTag()]
            local jsonFileList = type(storyDefine.json) == 'table' and storyDefine.json or {storyDefine.json}
            local chaptersData = {}
            for index, jsonFile in ipairs(jsonFileList) do
                local jsonDefine = type(jsonFile) == 'table' and jsonFile or {path = jsonFile}
                local nameList   = string.split2(jsonDefine.path, '/')
                if jsonDefine.idx ~= nil and jsonDefine.sub ~= nil then
                    for subIndex = jsonDefine.idx, jsonDefine.idx + jsonDefine.sub do
                        -- getRealConfigData()-- TODO
                        local storyConfs = CommonUtils.GetConfigAllMess(nameList[2] .. subIndex, nameList[1]) or {}
                        for index, chapterId in ipairs(table.keys(storyConfs)) do
                            table.insert(chaptersData, {storyJsonFile = jsonDefine.path .. subIndex, storyChapterId = chapterId})
                        end
                    end
                else
                    local storyConfs = CommonUtils.GetConfigAllMess(nameList[2], nameList[1]) or {}
                    for index, chapterId in ipairs(table.keys(storyConfs)) do
                        table.insert(chaptersData, {storyJsonFile = jsonDefine.path, storyChapterId = chapterId})
                    end
                end
            end
            table.sort(chaptersData, function(a, b) return checkint(a.storyChapterId) < checkint(b.storyChapterId) end)
            
            self.browserData_.selectStoryBtn  = sender
            self.browserData_.chapterGridData = chaptersData
            self.browserData_.chapterGridView:setCountOfCell(#chaptersData)
            self.browserData_.chapterGridView:reloadData()
            self.browserData_.excelListView:setCountOfCell(#storySupportDefines + #jsonFileList)
            self.browserData_.excelListView:reloadData()

            sender:setChecked(true)
        end
        storyBtn:setOnClickScriptHandler(onClickStoryBtn)
        storyBtn.onClickStoryBtn = onClickStoryBtn
    end
    listView:reloadData()
    

    -- content panel
    local contentPanel = display.newLayer(0, 0, {bg = 'ui/home/kitchen/cooking_bg_make.png', scale9 = true, size = CONTENT_SIZE, ap = display.CENTER})
    contentPanel:setPositionX(display.cx + STORY_BTN_SIZE.width/2)
    contentPanel:setPositionY(display.cy)
    rootPanel:addChild(contentPanel)
    
    local excelSize    = cc.size(CONTENT_SIZE.width - 30, CONTENT_SIZE.height/2 - 20)
    local chapterSize  = cc.size(CONTENT_SIZE.width - 30, CONTENT_SIZE.height/2 - 20)
    local excelPanel   = display.newLayer(CONTENT_SIZE.width/2, CONTENT_SIZE.height/2, {size = excelSize, ap = display.CENTER_BOTTOM, color1 = cc.r4b(50)})
    local chapterPanel = display.newLayer(CONTENT_SIZE.width/2, CONTENT_SIZE.height/2, {size = chapterSize, ap = display.CENTER_TOP, color1 = cc.r4b(50)})
    contentPanel:addChild(excelPanel)
    contentPanel:addChild(chapterPanel)
    
    excelPanel:addChild(display.newLabel(50, excelSize.height - 30, fontWithColor(1, {color = '#78564b', ap = display.LEFT_CENTER, text = '加载Excel'})))
    chapterPanel:addChild(display.newLabel(50, excelSize.height - 30, fontWithColor(1, {color = '#78564b', ap = display.LEFT_CENTER, text = '章节选择'})))
    excelPanel:addChild(display.newImageView('ui/home/kitchen/cooking_line_name.png', excelSize.width/2, excelSize.height - 50, {scale9 = true, size = cc.size(excelSize.width - 40, 2)}))
    chapterPanel:addChild(display.newImageView('ui/home/kitchen/cooking_line_name.png', chapterSize.width/2, chapterSize.height - 50, {scale9 = true, size = cc.size(chapterSize.width - 40, 2)}))


    -- chapter gridView
    local chapterCellSize = cc.size(66+5, 50)
    local chapterCellCPos = cc.p(chapterCellSize.width/2, chapterCellSize.height/2)
    local chapterGridSize = cc.size(chapterSize.width - 40, chapterSize.height - 55)
    local chapterGridView = ui.gridView({size = chapterGridSize})
    chapterGridView:setColumns(math.floor(chapterGridSize.width / chapterCellSize.width))
    chapterGridView:setDirection(eScrollViewDirectionVertical)
    chapterGridView:setAnchorPoint(display.CENTER_BOTTOM)
    chapterGridView:setPositionX(chapterSize.width/2)
    -- chapterGridView:setBackgroundColor(cc.r4b(150))
    chapterGridView:setSizeOfCell(chapterCellSize)
    chapterPanel:addChild(chapterGridView)
    self.browserData_.chapterGridView = chapterGridView

    chapterGridView:setDataSourceAdapterScriptHandler(function(pCell, index)
        local chapterCell  = pCell
        local chapterIndex = index + 1
        
        if chapterCell == nil then
            chapterCell = CGridViewCell:new()
            chapterCell:setContentSize(chapterCellSize)

            local chapterCellBgSize = cc.size(chapterCellSize.width - 4, chapterCellSize.height - 4)
            local chapterCellBgNode = display.newLayer(chapterCellCPos.x, chapterCellCPos.y, {color = '#336b6b', size = chapterCellBgSize, ap = display.CENTER, enable = true})
            chapterCellBgNode:setName('chapterCellBgNode')
            chapterCell:addChild(chapterCellBgNode)

            display.commonUIParams(chapterCellBgNode, {cb = function(sender)
                local chapterIndex = sender:getTag()
                local defineIndex  = self.browserData_.selectStoryBtn:getTag()
                local chapterId    = checkint(self.browserData_.chapterGridData[chapterIndex].storyChapterId)
                local jsonFile     = checkstr(self.browserData_.chapterGridData[chapterIndex].storyJsonFile)
                local jsonPath     = string.fmt('conf/%1/%2.json', i18n.getLang(), jsonFile)
                local storyStage   = require('Frame.Opera.OperaStage').new({id = checkint(chapterId), path = jsonPath, isReview = true, isHideBackBtn = true})
                display.commonUIParams(storyStage, {po = display.center})
                self:AddGameLayer(storyStage)
            end})

            local chapterCellLabel = display.newLabel(chapterCellCPos.x, chapterCellCPos.y, fontWithColor(10, {fontSize = 24, color = '#f9f7e8', hAlign = display.TAC}))
            chapterCellLabel.reqw  = chapterCellBgSize.width - 10
            chapterCellLabel:setName('chapterCellLabel')
            chapterCell:addChild(chapterCellLabel)
        end
        
        local chapterCellBgNode = chapterCell:getChildByName('chapterCellBgNode')
        -- chapterCellBgNode:setOpacity((chapterIndex%2 == 0) and 210 or 180)
        chapterCellBgNode:setColor((chapterIndex%2 == 0) and ccc3FromInt('#ff8b8b') or ccc3FromInt('#61bfad'))
        chapterCellBgNode:setTag(chapterIndex)
        
        local storyChapterId   = checkint(self.browserData_.chapterGridData[chapterIndex].storyChapterId)
        local chapterCellLabel = chapterCell:getChildByName('chapterCellLabel')
        display.commonLabelParams(chapterCellLabel, {text = tostring(storyChapterId), reqW = chapterCellLabel.reqw})
        chapterCellLabel:setTag(chapterIndex)
        
        return chapterCell
    end)


    -- excel listView
    local excelListSize = cc.size(excelSize.width - 40, excelSize.height - 55)
    local excelCellSize = cc.size(excelListSize.width, 64)
    local excelCellCPos = cc.p(excelCellSize.width/2, excelCellSize.height/2)
    local excelListView = ui.tableView({size = excelListSize})
    excelListView:setDirection(eScrollViewDirectionVertical)
    excelListView:setAnchorPoint(display.CENTER_BOTTOM)
    excelListView:setPositionX(chapterSize.width/2)
    -- excelListView:setBackgroundColor(cc.r4b(150))
    excelListView:setSizeOfCell(excelCellSize)
    excelPanel:addChild(excelListView)
    self.browserData_.excelListView = excelListView

    excelListView:setDataSourceAdapterScriptHandler(function(pCell, index)
        local defineIndex    = self.browserData_.selectStoryBtn:getTag()
        local storyDefine    = storyBrowserDefines[defineIndex]
        local jsonFileList   = type(storyDefine.json) == 'table' and storyDefine.json or {storyDefine.json}
        local excelListCell  = pCell
        local excelListIndex = index + 1
        local isStoryExcel   = excelListIndex <= #jsonFileList
        local jsonIndex      = isStoryExcel and excelListIndex or (excelListIndex - #jsonFileList)
        local supportDefine  = storySupportDefines[jsonIndex]
        local storyJsonFile  = jsonFileList[jsonIndex]
        local jsonDefine     = type(storyJsonFile) == 'table' and storyJsonFile or {path = storyJsonFile}
        local confJsonFile   = isStoryExcel and jsonDefine.path or supportDefine.json
        local confDefine     = confParserDefine[confJsonFile] or {}

        if excelListCell == nil then
            excelListCell = CTableViewCell:new()
            excelListCell:setContentSize(excelCellSize)

            local excelCellBgSize = cc.size(excelCellSize.width - 4, excelCellSize.height - 4)
            local excelCellBgNode = display.newLayer(excelCellCPos.x, excelCellCPos.y, {color = cc.c4b(255,255,255,255), size = excelCellBgSize, ap = display.CENTER, enable = true})
            excelCellBgNode:setName('excelCellBgNode')
            excelListCell:addChild(excelCellBgNode)
            
            local excelCellLabel = display.newLabel(10, excelCellCPos.y, fontWithColor(10, {fontSize = 24, color = '#4f3a4b', ap = display.LEFT_CENTER, text = 'xxxxx'}))
            excelCellLabel:setName('excelCellLabel')
            excelListCell:addChild(excelCellLabel)
            
            local refreshExcelBtn = display.newButton(excelCellSize.width - 10, excelCellCPos.y + 4, {ap = display.RIGHT_CENTER, n = 'ui/home/commonShop/shop_btn_refresh.png'})
            refreshExcelBtn:setName('refreshExcelBtn')
            excelListCell:addChild(refreshExcelBtn)

            display.commonUIParams(refreshExcelBtn, {cb = function(sender)
                ExcelUtils.RefreshConfCache( {json = sender.confJsonFile, export = true} )

                if sender.isStoryExcel then
                    self.browserData_.selectStoryBtn:onClickStoryBtn()
                end
            end})
        end

        local excelCellBgNode = excelListCell:getChildByName('excelCellBgNode')
        excelCellBgNode:setOpacity((excelListIndex%2 == 0) and 255 or 150)

        local refreshExcelBtn = excelListCell:getChildByName('refreshExcelBtn')
        refreshExcelBtn.isStoryExcel = isStoryExcel
        refreshExcelBtn.confJsonFile = confJsonFile
        
        local excelCellLabel = excelListCell:getChildByName('excelCellLabel')
        local excelPath      = string.sub(tostring(confDefine.excelPath), #confParserDefine.DOC_PATCH + 1)
        display.commonLabelParams(excelCellLabel, {text = string.fmt('%1（%2）', excelPath, tostring(confDefine.sheetName))})

        refreshExcelBtn:setVisible(next(confDefine) ~= nil)

        if isStoryExcel then
            excelCellBgNode:setColor(ccc3FromInt('#bea1a5'))
            excelCellLabel:setColor(ccc3FromInt('#4f3a4b'))
        else
            excelCellBgNode:setColor(ccc3FromInt('#cccccc'))
            excelCellLabel:setColor(ccc3FromInt('#5b5d5f'))
        end 
        
        return excelListCell
    end)
end


-------------------------------------------------------------------------------
-- acb
-------------------------------------------------------------------------------
function DebugScene:acbBrowser_()
    local acbPath = {
        'music/BGM',
        'music/Sound',
        'sounds',
        'sounds/zh-cn',
    }

    self.browserData_ = {
        fileTitleLabel = nil,
        clipListView   = nil,
        addAcbNameMap  = {},
        playCueSheet   = nil,
        playCueName    = nil,
    }

    local audioEngine = CriAtom:GetInstance()
    -- audioEngine:SetAcfFileName(AUDIOS.ACF)
    -- audioEngine:Setup()

    local rootPanel = display.newLayer()
    self:AddGameLayer(rootPanel)

    -- close button
    self:addCloseButton_(rootPanel, function()
        if self.browserData_.playCueSheet then
            local playPlayerEngine = audioEngine:RetrivePlayer(self.browserData_.playCueSheet)
            if playPlayerEngine then
                playPlayerEngine:Stop(nil)
            end
        end
    end)
    
    -- clip info
    local PATH_GAP_W  = 220
    local ACB_CLIP_W = display.SAFE_RECT.width - #acbPath * PATH_GAP_W
    local titleLabel = display.newLabel(display.SAFE_R - ACB_CLIP_W, display.height - 20, fontWithColor(7, {ap = display.LEFT_CENTER}))
    rootPanel:addChild(titleLabel)
    self.browserData_.fileTitleLabel = titleLabel

    local clipListSize = cc.size(ACB_CLIP_W, display.height - 40)
    local clipCellSize = cc.size(ACB_CLIP_W, 40)
    local clipListView = CListView:create(clipListSize)
    clipListView:setDirection(eScrollViewDirectionVertical)
    clipListView:setBackgroundColor(cc.c4b(0,0,0,150))
    clipListView:setPositionX(display.SAFE_R - ACB_CLIP_W)
    clipListView:setAnchorPoint(display.LEFT_BOTTOM)
    rootPanel:addChild(clipListView)
    self.browserData_.clipListView = clipListView

    -- file info
    local lFileSystem   = require('lfs')
    local fileListList  = {}
    local selectAcbCell = nil
    for index, pach in ipairs(acbPath) do
        local titleLabel = display.newLabel(display.SAFE_L + (index-1)*PATH_GAP_W, display.height - 20, fontWithColor(7, {text = pach, ap = display.LEFT_CENTER}))
        rootPanel:addChild(titleLabel)

        local fileListSize = cc.size(PATH_GAP_W, display.height - 40)
        local fileCellSize = cc.size(fileListSize.width, 40)
        local fileListView = CListView:create(fileListSize)
        fileListView:setDirection(eScrollViewDirectionVertical)
        fileListView:setBackgroundColor(cc.c4b(255,255,255,150))
        fileListView:setPositionX(titleLabel:getPositionX())
        fileListView:setAnchorPoint(display.LEFT_BOTTOM)
        fileListView:setTag(index)
        rootPanel:addChild(fileListView)
        fileListList[index] = fileListView
        
        local acbFilePath = 'res/' .. pach
        if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_MAC then
            acbFilePath = app.fileUtils:getWritablePath() .. acbFilePath
        end
        
        local fileArray = {}
        for file in lFileSystem.dir(acbFilePath) do
            if file ~= '.' and file ~= '..' then
                local attr = lFileSystem.attributes(acbFilePath ..'/'.. file)
                if attr and attr.mode == 'file' and utils.getPathExtension(file) == '.acb' then
                    table.insert(fileArray, file)
                end
            end
        end
        table.sort(fileArray)

        -------------------------------------------------
        -- list
        for _, file in ipairs(fileArray) do
            local filePureName = utils.deletePathExtension(file)
            local fileCellNode = display.newLayer(0, 0, {size = fileCellSize, color = cc.r4b(50), enable = true})
            fileCellNode:setName(pach .. '/' .. file)
            fileCellNode:setUserTag(index)
            fileListView:insertNodeAtLast(fileCellNode)

            local fileNameLabel = display.newLabel(fileCellSize.width/2, fileCellSize.height/2, fontWithColor(14, {color = '#FFFFCC', text = filePureName}))
            fileCellNode:addChild(fileNameLabel)

            display.commonUIParams(fileCellNode, {cb = function(sender)
                local acbFilePath = sender:getName()
                local acbFileName = string.gsub(acbFilePath, '.*/', '')
                local acbPureName = utils.deletePathExtension(acbFileName)
                display.commonLabelParams(self.browserData_.fileTitleLabel, {text = '/' .. acbFileName})

                -- update all fileList
                for _, otherFileListView in ipairs(fileListList) do
                    if otherFileListView:getTag() == sender:getUserTag() then
                        otherFileListView:setBackgroundColor(cc.c4b(255,255,255,200))
                    else
                        otherFileListView:setBackgroundColor(cc.c4b(255,255,255,100))
                    end
                end

                -- update select acbCell
                if selectAcbCell then
                    selectAcbCell:stopAllActions()
                    selectAcbCell:setOpacity(50)
                end
                selectAcbCell = sender
                selectAcbCell:runAction(cc.RepeatForever:create(cc.Sequence:create(
                    cc.FadeTo:create(0.25, 255),
                    cc.FadeTo:create(0.25, 50)
                )))
                
                -- load acb file
                if not self.browserData_.addAcbNameMap[acbPureName] then
                    audioEngine:AddCueSheet(acbPureName, acbFilePath, '')
                    self.browserData_.addAcbNameMap[acbPureName] = true
                end

                -- load all cue info
                local acbFileRef  = audioEngine:GetAcb(acbPureName)
                local cueInfoList = acbFileRef:GetCueInfoList()
                self.browserData_.clipListView:removeAllNodes()
                table.sort(cueInfoList, function(a, b)
                    return a.name < b.name
                end)
                for index, cueInfo in ipairs(cueInfoList) do
                    local cueNameText = tostring(cueInfo.name)
                    local cueCellNode = display.newLayer(0, 0, {size = clipCellSize, color = cc.r4b(50), enable = true})
                    cueCellNode:setName(acbPureName .. '/' .. cueNameText)
                    self.browserData_.clipListView:insertNodeAtLast(cueCellNode)

                    local isLoopPlay    = checkint(cueInfo.time) < 0
                    local timeDataList  = string.split2(tostring(checkint(cueInfo.time)/1000), '.')
                    local timeCueName   = string.format('%02d.%03d") %s', checkint(timeDataList[1]), checkint(timeDataList[2]), cueNameText)
                    local loopCueName   = string.format('--loop--) %s', cueNameText)
                    local cueNameString = isLoopPlay and loopCueName or timeCueName
                    local cueNameLabel  = display.newLabel(0, clipCellSize.height/2, fontWithColor(14, {color = '#FFFFCC', text = cueNameString, ap = display.LEFT_CENTER}))
                    cueCellNode:addChild(cueNameLabel)

                    display.commonUIParams(cueCellNode, {cb = function(sender)
                        local nameList = string.split2(sender:getName(), '/')
                        local cueSheet = nameList[1]
                        local cueName  = nameList[2]
                        
                        -- stop old player
                        if self.browserData_.playCueSheet then
                            local playPlayerEngine = audioEngine:RetrivePlayer(self.browserData_.playCueSheet)
                            if playPlayerEngine then
                                playPlayerEngine:Stop(nil)
                            end
                        end

                        -- create new player
                        local playerEngine = audioEngine:RetrivePlayer(cueSheet)
                        if not playerEngine then
                            playerEngine = audioEngine:CreatePlayer(cueSheet)
                        end

                        -- play acb cue
                        local acbRef = audioEngine:GetAcb(cueSheet)
                        if acbRef then
                            playerEngine:SetCue(acbRef, cueName)
                            playerEngine:SetVolume(0.8)
                            playerEngine:Start(false)
                        end

                        -- cache play data
                        self.browserData_.playCueSheet = cueSheet
                        self.browserData_.playCueName  = cueName
                    end})
                end
                self.browserData_.clipListView:reloadData()

            end})
        end
        fileListView:reloadData()
    end
end


-------------------------------------------------------------------------------
-- avatar
-------------------------------------------------------------------------------
function DebugScene:testAvatar_()
    local testLayer = display.newLayer()
    app.uiMgr:GetCurrentScene():AddDialog(testLayer)

    local customerIdList      = CONF.AVATAR.CUSTOMER:GetIdList()
    local avatarThemeIdList   = CONF.AVATAR.THEME_DEFINE:GetIdListDown()
    testLayer.isShowCustomer_ = false

    -- create view
    local avatarThemeGridView = ui.gridView({size = cc.resize(display.SAFE_SIZE, -10, 0), cols = 2, csizeH = 180, dir = display.SDIR_V})
    testLayer:addList(avatarThemeGridView):alignTo(nil, ui.cc)

    -- init cell
    avatarThemeGridView:setCellCreateHandler(function(cellParent)
        local view = cellParent
        local size = cellParent:getContentSize()
        local cpos = cc.sizep(size, ui.cc)

        local imgLayer   = view:addList(ui.layer({p = cpos}))
        local frameImg   = view:addList(ui.image({p = cpos, img = _res('avatar/ui/avatarShop/avator_goods_bg_l.png')}))
        local titleLabel = frameImg:addList(ui.title({p = cc.p(12,16), ap = ui.lb, img = _res('avatar/ui/avatarShop/avator_goods_bg_title_name.png')}):updateLabel({fnt = FONT.TEXT36, color = '#f9f7e8'}))
        local clickArea  = view:addList(ui.layer({size = size, color = cc.r4b(0), enable = true}))

        ui.bindClick(clickArea, function(sender)
            local themeId      = avatarThemeIdList[sender:getTag()]
            local themeConf    = CONF.AVATAR.THEME_DEFINE:GetValue(themeId)
            local partsConf    = CONF.AVATAR.THEME_PARTS:GetValue(themeId)
            local officialConf = CONF.AVATAR.OFFICIAL:GetAll()
            
            -- clean officialConf
            for key, _ in pairs(officialConf) do
                officialConf[key] =nil
            end

            -- reset officialConf
            officialConf.name            = themeConf.name
            officialConf.restaurantLevel = themeConf.id
            officialConf.location        = {}
            officialConf.seat            = {}
            local avatarPartsIndex       = 1
            local SCENE_BOUNDING_BOX_L   = 100
            local SCENE_BOUNDING_BOX_R   = 1300
            local avatarChairPoint       = cc.p(SCENE_BOUNDING_BOX_L, 500)
            local avatarDecorPoint       = cc.p(SCENE_BOUNDING_BOX_R, 200)
            for avatarId, avatarNum in pairs(partsConf) do
                local avatarConf   = CONF.AVATAR.DEFINE:GetValue(avatarId)
                local locationConf = CONF.AVATAR.LOCATION:GetValue(avatarId)
                local avatarNode   = require('Game.views.restaurant.DragNode').new({id = avatarPartsIndex, avatarId = avatarId, configInfo = locationConf})
                local avatarWidth  = checkint(avatarNode:getContentSize().width)
                local avatarPoint  = { x = 0, y = 0 }

                if checkint(avatarConf.mainType) == RESTAURANT_AVATAR_TYPE.CHAIR then
                    avatarPoint.x = avatarChairPoint.x
                    avatarPoint.y = avatarChairPoint.y
                    
                    if testLayer.isShowCustomer_ then
                        for visitorIndex, additionConf in ipairs(locationConf.additions) do
                            local seatId  = string.format('%d_%d', checkint(avatarNode.id), visitorIndex)
                            officialConf.seat[seatId] = {
                                customerUuid = avatarPartsIndex * 100 + visitorIndex,
                                customerId   = customerIdList[math.random(#customerIdList)],
                                isEating     = RESTAURANT_EAT_STATS.EATING,
                                recipeId     = 220001,  -- conf/cooking/recipe.json
                                leftSeconds  = 0,
                            }
                        end
                    end
                    
                    if avatarChairPoint.x + avatarWidth > SCENE_BOUNDING_BOX_R then
                        avatarChairPoint.x = SCENE_BOUNDING_BOX_L
                        avatarChairPoint.y = avatarChairPoint.y - 150
                    else
                        avatarChairPoint.x = avatarChairPoint.x + avatarWidth + 50
                    end

                elseif checkint(avatarConf.mainType) == RESTAURANT_AVATAR_TYPE.DECORATION then
                    if avatarDecorPoint.x - avatarWidth < SCENE_BOUNDING_BOX_L then
                        avatarDecorPoint.x = SCENE_BOUNDING_BOX_R - avatarWidth
                        avatarDecorPoint.y = avatarDecorPoint.y + 150
                    else
                        avatarDecorPoint.x = avatarDecorPoint.x - avatarWidth - 50
                    end

                    avatarPoint.x = avatarDecorPoint.x
                    avatarPoint.y = avatarDecorPoint.y
                end

                officialConf.location[tostring(avatarPartsIndex)] = {
                    id       = avatarPartsIndex,
                    goodsId  = avatarId,
                    location = avatarPoint,
                }
                avatarPartsIndex = avatarPartsIndex + 1
            end

            -- show avatar
            cc.Director:getInstance():getScheduler():setTimeScale(2)
            scheduler.performWithDelayGlobal(function()
                cc.Director:getInstance():getScheduler():setTimeScale(1)
            end, 2)
            app:RegistMediator(require('Game.mediator.FriendAvatarMediator').new({friendId = -1}))
        end)
        
        return {
            view       = view,
            imgLayer   = imgLayer,
            titleLabel = titleLabel,
            clickArea  = clickArea,
        }
    end)

    -- update cell
    avatarThemeGridView:setCellUpdateHandler(function(cellIndex, cellViewData)
        if cellViewData == nil then return end

        cellViewData.clickArea:setTag(cellIndex)

        local themeId   = avatarThemeIdList[cellIndex]
        local themeConf = CONF.AVATAR.THEME_DEFINE:GetValue(themeId)
        cellViewData.imgLayer:addAndClear(CommonUtils.GetGoodsIconNodeById(themeId))
        cellViewData.titleLabel:updateLabel({text = string.fmt('%1 : %2', themeConf.id, themeConf.name), paddingW = 50})
        cellViewData.titleLabel:getLabel():setPositionX(cellViewData.titleLabel:getLabel():getPositionX() - 30)
    end)

    -- reload themeGridView
    avatarThemeGridView:resetCellCount(#avatarThemeIdList)

    -- showDebug tButton
    local showDebugCButton = ui.tButton({p = cc.p(display.SAFE_R - 150, 50), n = _res('ui/home/infor/setup_btn_bg_open.png'), s = _res('ui/home/infor/setup_btn_bg_close.png')})
    showDebugCButton:add(ui.label({p = cc.rep(cc.sizep(showDebugCButton, ui.cc), 0, 0), fnt = FONT.D19, fontSize = 20, text = 'debug'}))
    showDebugCButton:setChecked(RESTAURANT_AVATAR_NODE_DEBUG == true)
    testLayer:add(showDebugCButton)
    showDebugCButton:setOnClickScriptHandler(function(sender)
        RESTAURANT_AVATAR_NODE_DEBUG = sender:isChecked()
    end)

    -- showCustomer tButton
    local showCustomerCButton = ui.tButton({p = cc.p(display.SAFE_R - 300, 50), n = _res('ui/home/infor/setup_btn_bg_open.png'), s = _res('ui/home/infor/setup_btn_bg_close.png')})
    showCustomerCButton:add(ui.label({p = cc.rep(cc.sizep(showCustomerCButton, ui.cc), 0, 0), fnt = FONT.D19, fontSize = 20, text = '客人'}))
    showCustomerCButton:setChecked(testLayer.isShowCustomer_ == true)
    testLayer:add(showCustomerCButton)
    showCustomerCButton:setOnClickScriptHandler(function(sender)
        testLayer.isShowCustomer_ = sender:isChecked()
    end)

    -- close button
    self:addCloseButton_(testLayer)
end


-------------------------------------------------------------------------------
-- proxy
-------------------------------------------------------------------------------
function DebugScene:testVoProxy_()
    local testType  = 'test1'
    local dumpInfo  = {}
    local eventData = {}


    -- post data
    while testType == 'test1' do
        local mallData = {
            products               = {},               -- 商品列表
            refreshDiamond         = math.random(99),  -- 刷新钻石单价
            refreshLeftTimes       = math.random(9),   -- 手动刷新剩余次数
            nextRefreshLeftSeconds = math.random(99),  -- 下一次自动刷新剩余秒数
        }
        local moneyConfs  = CommonUtils.GetConfigAllMess('money', 'goods')
        local chestConfs  = CommonUtils.GetConfigAllMess('chest', 'goods')
        local moneyIdList = table.keys(moneyConfs)
        local chestIdList = table.keys(chestConfs)
        for i = 1, 5 do
            local priceNum   = math.random(999)
            local goodsId    = chestIdList[math.random(#chestIdList)]
            local currencyId = moneyIdList[math.random(#moneyIdList)]
            table.insert(mallData.products, {
                productId = i,                -- 商品id
                currency  = currencyId,       -- 货币
                goodsId   = goodsId,          -- 道具id
                goodsNum  = math.random(99),  -- 道具数量
                price     = priceNum,         -- 价格
                purchased = math.random(0,1), -- 购买状态（0:未购买 1:已购买）
                sale      = {                 -- 多价格（key为货币, value为价格）
                    [tostring(currencyId)] = priceNum,
                }, 
            })
        end
        logs(tableToString(mallData, 'Bar/mall', 10))


        local PROXY_NAME   = FOOD.WATER_BAR.MARKET.PROXY_NAME
        local PROXY_NAME2  = FOOD.WATER_BAR.MARKET.PROXY_NAME .. '_2'
        local PROXY_STRUCT = FOOD.WATER_BAR.MARKET.PROXY_STRUCT
        local mallVoProxy  = require('Frame.VoProxy').new(PROXY_NAME, PROXY_STRUCT)
        local mallVoProxy2 = require('Frame.VoProxy').new(PROXY_NAME2, PROXY_STRUCT)
        table.insert(dumpInfo, mallVoProxy:dump())


        eventData = {
            [PROXY_NAME] = {
                [PROXY_STRUCT.MARKET_HOME_TAKE.REFRESH_DIAMOND] = function(_, signal)
                    logs('1_voEvent.target >> ' .. signal:GetBody().target:getName())
                    logs('1_voEvent.root >> ' .. signal:GetBody().root:getName())
                end,
            },
            [PROXY_NAME2] = {
                [PROXY_STRUCT.MARKET_HOME_TAKE.REFRESH_DIAMOND] = function(_, signal)
                    logs('2_voEvent.target >> ' .. signal:GetBody().target:getName())
                    logs('2_voEvent.root >> ' .. signal:GetBody().root:getName())
                end,
            },
        }
        for proxyName, voDefineMap in pairs(eventData) do
            VoProxy.EventBind(proxyName, voDefineMap, self)
        end


        table.insert(dumpInfo, '---- set ----')
        mallVoProxy:set(PROXY_STRUCT.REFRESH_TIMESTAMP, os.time())
        mallVoProxy:set(PROXY_STRUCT.MARKET_HOME_TAKE, mallData)
        mallVoProxy2:set(PROXY_STRUCT.MARKET_HOME_TAKE, mallData)
        -- mallVoProxy:set(PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS, {})
        table.insert(dumpInfo, tableToString(mallVoProxy:getData(), 'voProxy:data', 10))
        
        table.insert(dumpInfo, '---- get ----')
        table.insert(dumpInfo, 'size of : ' .. PROXY_STRUCT._key .. ' = ' .. mallVoProxy:size(PROXY_STRUCT))  -- 2 (REFRESH_TIMESTAMP, MALL_HOME_TAKE)
        table.insert(dumpInfo, 'size of : ' .. PROXY_STRUCT.MARKET_HOME_TAKE._key .. ' = ' .. mallVoProxy:size(PROXY_STRUCT.MARKET_HOME_TAKE)) -- 4
        table.insert(dumpInfo, 'size of : ' .. PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS._key .. ' = ' .. mallVoProxy:size(PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS)) -- 5
        table.insert(dumpInfo, 'size of : ' .. PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS.PRODUCT_DATA._key .. ' = ' .. mallVoProxy:size(PROXY_STRUCT.MARKET_HOME_TAKE.PRODUCTS.PRODUCT_DATA, 1)) -- 10
        break
    end


    -- test data
    while testType == 'test2' do
        local PROXY_NAME   = 'PROXY_STRUCT'
        local PROXY_STRUCT = { _map = 1, _key = PROXY_NAME,
            INT = { _int = 1, _key = 'int' },  -- test integer
            NUM = { _num = 1, _key = 'num' },  -- test number
            STR = { _str = 1, _key = 'str' },  -- test string
            BOL = { _bol = 1, _key = 'bol' },  -- test boolean
            LST = { _lst = 1, _key = 'lst' },  -- test empty list
            MAP = { _map = 1, _key = 'map' },  -- test empty map
            REWARDS = { _lst = 1, _key = 'rewards',  -- goods rewards
                GOODS = { _map = 1, _key = '$',      -- goods data
                    ID  = { _int = 1, _key = 'goodsId'}, -- goods id
                    NUM = { _int = 1, _key = 'num'},     -- goods num
                },
            },
            BACKPACK = { _map = 1, _key = 'backpack',  -- backpack map (goodsId key)
                COUNT = { _int = 1, _key = '$' },      -- goods count
            },
            T_LIST = { _lst = 1, _key = 't_list',
                SUB_L1 = { _lst = 1, _key = '$',
                    SUB_L2 = { _lst = 1, _key = '$',
                        NUM = { _int = 1, _key ='$' },
                    },
                },
            },
            T_MAP = { _map = 1, _key = 't_map',
                AREA = { _map = 1, _key = '$',
                    QUEST = { _map = 1, _key = '$',
                        POS = { _map = 1, _key = 'pos',
                            POSX = { _int = 1, _key ='x' },
                            POSY = { _int = 1, _key ='y' },
                        },
                        NAME = { _str = 1, _key = 'name'},
                    },
                },
            },
        }

        local testVoProxy = require('Frame.VoProxy').new(PROXY_NAME, PROXY_STRUCT)
        table.insert(dumpInfo, testVoProxy:dump())


        table.insert(dumpInfo, '\n\n====== base test ======')
        do
            table.insert(dumpInfo, '\n---- default ----')
            table.insert(dumpInfo, '#.INT = ' .. tostring(testVoProxy:get(PROXY_STRUCT.INT)))  -- 0
            table.insert(dumpInfo, '#.NUM = ' .. tostring(testVoProxy:get(PROXY_STRUCT.NUM)))  -- 0
            table.insert(dumpInfo, '#.STR = ' .. tostring(testVoProxy:get(PROXY_STRUCT.STR)))  -- ''
            table.insert(dumpInfo, '#.BOL = ' .. tostring(testVoProxy:get(PROXY_STRUCT.BOL)))  -- false
    
    
            table.insert(dumpInfo, '\n---- set ----')
            testVoProxy:set(PROXY_STRUCT.INT, 3)
            testVoProxy:set(PROXY_STRUCT.NUM, math.pi)
            testVoProxy:set(PROXY_STRUCT.STR, os.date('%Y-%m-%d',0))
            testVoProxy:set(PROXY_STRUCT.BOL, 1 < 10)
            table.insert(dumpInfo, '#.INT = ' .. tostring(testVoProxy:get(PROXY_STRUCT.INT)))  -- 3
            table.insert(dumpInfo, '#.NUM = ' .. tostring(testVoProxy:get(PROXY_STRUCT.NUM)))  -- 3.1415926
            table.insert(dumpInfo, '#.STR = ' .. tostring(testVoProxy:get(PROXY_STRUCT.STR)))  -- 1970-01-01
            table.insert(dumpInfo, '#.BOL = ' .. tostring(testVoProxy:get(PROXY_STRUCT.BOL)))  -- true

            -- table.insert(dumpInfo, '\n---- reset / update diff ----')
            -- table.insert(dumpInfo, '#.DIFF > all (default) = ' .. tableToString(testVoProxy:get(PROXY_STRUCT.DIFF):getData()))
            -- {
            --     map1 = { size = { width = 0, height = 0} },
            --     map2 = { size = { width = 0, height = 0} },
            --     map3 = { size = { width = 0, height = 0} },
            -- }
        end


        table.insert(dumpInfo, '\n\n====== list test ======')
        do
            -- table.insert(dumpInfo, '#.REWARDS = ' .. tableToString(testVoProxy:get(PROXY_STRUCT.REWARDS)))  -- return VoProxy object
            -- table.insert(dumpInfo, '#.REWARDS > all = ' .. tableToString(testVoProxy:get(PROXY_STRUCT.REWARDS):getData()))  -- return {}
    
            local rewardsData = {}
            for i = 1, math.random(3,6) do
                table.insert(rewardsData, {goodsId = 900000 + i, num = 10 * i})
            end
            testVoProxy:set(PROXY_STRUCT.REWARDS, rewardsData)
            table.insert(dumpInfo, '#.REWARDS > all = ' .. tableToString(testVoProxy:get(PROXY_STRUCT.REWARDS):getData()))  -- { {goodsId = 900001, num = 10}, ... }
    
            table.insert(dumpInfo, '\n---- list get ----')
            table.insert(dumpInfo, '#.REWARDS > size = ' .. testVoProxy:size(PROXY_STRUCT.REWARDS))  -- [3-6]
            table.insert(dumpInfo, '#.REWARDS.GOODS > size = ' .. testVoProxy:size(PROXY_STRUCT.REWARDS.GOODS))  -- 0. (error: GOODS not set)
            
            table.insert(dumpInfo, '#.REWARDS[?].data = ' .. tableToString(testVoProxy:get(PROXY_STRUCT.REWARDS.GOODS):getData()))  -- nil. (error: GOODS not set)
            table.insert(dumpInfo, '#.REWARDS[2].data = ' .. tableToString(testVoProxy:get(PROXY_STRUCT.REWARDS.GOODS, 2):getData()))  -- {goodsId = 900001, num = 20}
            
            table.insert(dumpInfo, '\n---- list del ----')
            table.insert(dumpInfo, '#.REWARDS[1].del')
            -- testVoProxy:del(PROXY_STRUCT.REWARDS, 1) -- error: empty effect 
            testVoProxy:del(PROXY_STRUCT.REWARDS.GOODS, 1)
            -- table.insert(dumpInfo, '#.REWARDS > all = ' .. tableToString(testVoProxy:get(PROXY_STRUCT.REWARDS):getData()))  -- all data
    
            table.insert(dumpInfo, '\n---- list for ----')
            local GOODS_STRUCT = PROXY_STRUCT.REWARDS.GOODS
            for i = 1, testVoProxy:size(PROXY_STRUCT.REWARDS) do
                local goodsVoProxy  = testVoProxy:get(GOODS_STRUCT, i)
                table.insert(dumpInfo, '#.REWARDS['..i..'].goodsId  = ' .. goodsVoProxy:get(GOODS_STRUCT.ID))   -- 900002-900006
                table.insert(dumpInfo, '#.REWARDS['..i..'].goodsNum = ' .. goodsVoProxy:get(GOODS_STRUCT.NUM))  -- 20-60
            end

            table.insert(dumpInfo, '\n---- reset / upate ----')
            testVoProxy:get(PROXY_STRUCT.REWARDS):update({
                {goodsId = 911111, num = 111},
                {goodsId = 922222, num = 222},
            })
            table.insert(dumpInfo, '#.REWARDS > reset1 = ' .. tableToString(testVoProxy:get(PROXY_STRUCT.REWARDS):getData()))
            --[[{
                {goodsId = 911111, num = 111},
                {goodsId = 922222, num = 222},
            }]]
            
            testVoProxy:set(PROXY_STRUCT.REWARDS, {
                {goodsId = 900010, num = 11},
                {goodsId = 900020, num = 22},
                {goodsId = 900030, num = 33},
            })
            table.insert(dumpInfo, '#.REWARDS > reset2 = ' .. tableToString(testVoProxy:get(PROXY_STRUCT.REWARDS):getData()))
            --[[{
                {goodsId = 900010, num = 11},
                {goodsId = 900020, num = 22},
                {goodsId = 900030, num = 33},
            }]]

            testVoProxy:set(PROXY_STRUCT.REWARDS, {})
            table.insert(dumpInfo, '#.REWARDS > reset3 = ' .. tableToString(testVoProxy:get(PROXY_STRUCT.REWARDS):getData()))
            --[[
                {}
            ]]
        end


        table.insert(dumpInfo, '\n\n====== map test ======')
        do
            local backpackMap = {}
            for i = 1, 5 do
                backpackMap[tostring(800000 + i)] = 100 * i
            end
            testVoProxy:set(PROXY_STRUCT.BACKPACK, backpackMap)
            table.insert(dumpInfo, '#.BACKPACK > all = ' .. tableToString(testVoProxy:get(PROXY_STRUCT.BACKPACK):getData()))  -- { [800001] = 100, ... }
    
            table.insert(dumpInfo, '\n---- map get ----')
            table.insert(dumpInfo, '#.BACKPACK > size = ' .. testVoProxy:size(PROXY_STRUCT.BACKPACK))  -- 5
            table.insert(dumpInfo, '#.BACKPACK.COUNT > size = ' .. testVoProxy:size(PROXY_STRUCT.BACKPACK.COUNT))  -- 0. (error: COUNT not set)
    
            table.insert(dumpInfo, '\n---- map del ----')
            table.insert(dumpInfo, '#.BACKPACK["800001"].del')
            -- testVoProxy:del(PROXY_STRUCT.BACKPACK, '800001') -- error: empty effect 
            testVoProxy:del(PROXY_STRUCT.BACKPACK.COUNT, '800001')
    
            table.insert(dumpInfo, '\n---- map for ----')
            local COUNT_STRUCT = PROXY_STRUCT.BACKPACK.COUNT
            for goodsId, _ in pairs(testVoProxy:get(PROXY_STRUCT.BACKPACK):getData()) do
                local goodsCount  = testVoProxy:get(COUNT_STRUCT, goodsId)
                table.insert(dumpInfo, '#.BACKPACK["' .. goodsId .. '"] = ' .. goodsCount)   -- [800002-800005] = 200-500
            end
        end


        table.insert(dumpInfo, '\n\n====== mixture list ======')
        do
            testVoProxy:set(PROXY_STRUCT.T_LIST, {
                { {111, 112, 113, 114, 115}, {121, 122, 123, 124}, {131, 132, 133} },
                { {211, 212, 213, 214},      {221, 222, 223},      {231, 232},     {241} },
            })
            table.insert(dumpInfo, 'size : T_LIST = ' .. testVoProxy:size(PROXY_STRUCT.T_LIST)) -- 2
            table.insert(dumpInfo, 'size : T_LIST[1] = ' .. testVoProxy:size(PROXY_STRUCT.T_LIST.SUB_L1, 1)) -- 3
            table.insert(dumpInfo, 'size : T_LIST[2] = ' .. testVoProxy:size(PROXY_STRUCT.T_LIST.SUB_L1, 2)) -- 4
            table.insert(dumpInfo, 'size : T_LIST[1][3] = ' .. testVoProxy:get(PROXY_STRUCT.T_LIST.SUB_L1, 1):size(PROXY_STRUCT.T_LIST.SUB_L1.SUB_L2, 3))  -- 3
            table.insert(dumpInfo, 'size : T_LIST[2][4] = ' .. testVoProxy:get(PROXY_STRUCT.T_LIST.SUB_L1, 2):size(PROXY_STRUCT.T_LIST.SUB_L1.SUB_L2, 4))  -- 1

            local SUB_L1 = PROXY_STRUCT.T_LIST.SUB_L1
            local SUB_L2 = PROXY_STRUCT.T_LIST.SUB_L1.SUB_L2
            table.insert(dumpInfo, 'value : T_LIST[2][3][1] = ' .. testVoProxy:get(SUB_L1, 2):get(SUB_L2, 3):get(SUB_L2.NUM, 1)) -- 231
            table.insert(dumpInfo, 'value : T_LIST[1][1][5] = ' .. testVoProxy:get(SUB_L1, 1):get(SUB_L2, 1):get(SUB_L2.NUM, 5)) -- 115

            -- testVoProxy:del(SUB_L2.NUM, 1)  -- error: SUB_L1 not set
            testVoProxy:get(SUB_L1, 1):get(SUB_L2, 3):del(SUB_L2.NUM, 1)
            testVoProxy:get(SUB_L1, 1):del(SUB_L2, 2)
            testVoProxy:del(SUB_L1, 2)
            table.insert(dumpInfo, 'size : T_LIST = ' .. tableToString(testVoProxy:get(PROXY_STRUCT.T_LIST):getData()))
            -- {
            --     { {111, 112, 113, 114, 115}, {132, 133} },
            -- }
        end


        table.insert(dumpInfo, '\n\n====== mixture map ======')
        do
            testVoProxy:set(PROXY_STRUCT.T_MAP, {
                ['area1'] = {
                    ['1'] = { name = '1-1', pos = { x = 111, y = 112 } },
                    ['2'] = { name = '1-2', pos = { x = 121, y = 122 } },
                    ['3'] = { name = '1-3', pos = { x = 131, y = 132 } },
                },
                ['area2'] = {
                    ['4'] = { name = '2-1', pos = { x = 211, y = 212 } },
                    ['5'] = { name = '2-2', pos = { x = 221, y = 222 } },
                    ['6'] = { name = '2-3', pos = { x = 231, y = 232 } },
                    ['7'] = {},
                },
            })
            table.insert(dumpInfo, 'size : T_MAP = ' .. testVoProxy:size(PROXY_STRUCT.T_MAP)) -- 2
            table.insert(dumpInfo, 'size : T_MAP[area1] = ' .. testVoProxy:size(PROXY_STRUCT.T_MAP.AREA, 'area1')) -- 3
            table.insert(dumpInfo, 'size : T_MAP[area2] = ' .. testVoProxy:size(PROXY_STRUCT.T_MAP.AREA, 'area2')) -- 4
            table.insert(dumpInfo, 'size : T_MAP[area1][2] = ' .. testVoProxy:get(PROXY_STRUCT.T_MAP.AREA, 'area1'):size(PROXY_STRUCT.T_MAP.AREA.QUEST, '2'))  -- 2
            table.insert(dumpInfo, 'size : T_MAP[area2][7] = ' .. testVoProxy:get(PROXY_STRUCT.T_MAP.AREA, 'area2'):size(PROXY_STRUCT.T_MAP.AREA.QUEST, '7'))  -- 2

            local AREA  = PROXY_STRUCT.T_MAP.AREA
            local QUEST = PROXY_STRUCT.T_MAP.AREA.QUEST
            testVoProxy:get(AREA, 'area1'):get(QUEST, '2'):set(QUEST.POS.POSX, 3)
            testVoProxy:get(AREA, 'area1'):get(QUEST, '2'):get(QUEST.POS):set(QUEST.POS.POSX, 3)
            table.insert(dumpInfo, 'value : T_MAP[area1][2].pos.x = ' .. testVoProxy:get(AREA, 'area1'):get(QUEST, '2'):get(QUEST.POS.POSX)) -- 3
            table.insert(dumpInfo, 'value : T_MAP[area1][3].pos.x = ' .. testVoProxy:get(AREA, 'area1'):get(QUEST, '3'):get(QUEST.POS.POSX)) -- 131
            table.insert(dumpInfo, 'value : T_MAP[area1][1].pos.x = ' .. testVoProxy:get(AREA, 'area1'):get(QUEST, '1'):get(QUEST.POS.POSX)) -- 111
            table.insert(dumpInfo, 'value : T_MAP[area2][7].pos.x = ' .. testVoProxy:get(AREA, 'area2'):get(QUEST, '7'):get(QUEST.POS.POSX)) -- 0
            table.insert(dumpInfo, 'value : T_MAP[area2][7].name = ' .. testVoProxy:get(AREA, 'area2'):get(QUEST, '7'):get(QUEST.NAME)) -- ''
            table.insert(dumpInfo, 'value : T_MAP[area2][7].name = ' .. tableToString(testVoProxy:get(AREA, 'area2'):get(QUEST, '7'):get(QUEST.POS):getData())) -- {x = 0, y = 0}
        end


        table.insert(dumpInfo, '\n---- root data ----')
        table.insert(dumpInfo, tableToString(testVoProxy:getData(), 'root', 10))
        break
    end


    -- view
    do
        local testLayer = display.newLayer()
        app.uiMgr:GetCurrentScene():AddDialog(testLayer)

        -- descr view
        local descrView = self:addScrollDescrView_(testLayer)
        descrView:updateDescr(#dumpInfo > 0 and table.concat(dumpInfo, '\n>> ') or 'test empty...')

        -- close button
        self:addCloseButton_(testLayer, function()
            for proxyName, voDefineMap in pairs(eventData) do
                VoProxy.EventUnbind(proxyName, voDefineMap, self)
            end
        end)
    end
end


-------------------------------------------------------------------------------
-- layout
-------------------------------------------------------------------------------
function DebugScene:testLayout_()
    local testLayer = display.newLayer()
    app.uiMgr:GetCurrentScene():AddDialog(testLayer)

    testLayer:addChild(display.newLayer(display.cx, display.cy, {color = cc.c4b(0,0,0,255), ap = display.CENTER, size = cc.size(display.width, 2)}))
    testLayer:addChild(display.newLayer(display.cx, display.cy, {color = cc.c4b(0,0,0,255), ap = display.CENTER, size = cc.size(2, display.height)}))

    local testFunc = nil
    local flowGapW = 0
    local flowGapH = 0
    local flowType = display.FLOW_H
    local flowAp   = display.CENTER
    local testType = 'test3'
    
    -- test flowLayout
    while testType == 'test1' do
        local rectTestList = {}
        for i = 1, 5 do
            local rectAPos = cc.p( math.random(0,2)*0.5, math.random(0,2)*0.5 )
            local rectSize = cc.size(math.random(2,4) * 30, math.random(2,4) * 30)
            local rectNode = display.newLayer(display.cx*0, display.cy*0, {size = rectSize, ap = rectAPos, color = cc.r4b(200)})
            testLayer:addChild(rectNode)
            table.insert(rectTestList, rectNode)
        end
        rectTestList[1]:setMarginR(10)
        rectTestList[1]:setMarginL(20)
        rectTestList[1]:setMarginT(100)
        rectTestList[1]:setMarginB(200)
        rectTestList[2]:setMarginL(20)
        rectTestList[2]:setMarginT(100)
        rectTestList[2]:setMarginB(20)
        rectTestList[2]:setMarginR(200)
        
        testFunc = function()
            display.flowLayout(display.center, rectTestList, {type = flowType, ap = flowAp, gapW = flowGapW, gapH = flowGapH})
        end
        testFunc()
        break
    end

    -- test alignTo
    while testType == 'test2' do
        local rectNode1Ap = cc.p( math.random(0,2)*0.5, math.random(0,2)*0.5 )
        local rectNode2Ap = cc.p( math.random(0,2)*0.5, math.random(0,2)*0.5 )
        local rectNode1 = display.newLayer(display.cx, display.cy, {size = cc.size(200, 200), color = cc.r4b(255), ap = rectNode1Ap})
        local rectNode2 = display.newLayer(0, 0, {size = cc.size(150, 250), color = cc.r4b(255), ap = rectNode2Ap})
        testLayer:addChild(rectNode2)
        testLayer:addChild(rectNode1)
        
        testFunc = function()
            rectNode2:alignTo(rectNode1, flowAp, {offsetX = flowGapW + flowGapH, inside = flowType == display.FLOW_V})
        end
        testFunc()
        break
    end


    while testType == 'test3' do
        local RES_DICT = {
            VIEW_FRAME    = _res('ui/common/card_love_feed_ico_star.png'),
            INFO_TITLE    = _res('ui/common/common_title_5.png'),
            TAB_BTN_N     = _res('ui/home/lobby/information/setup_btn_tab_default.png'),
            TAB_BTN_S     = _res('ui/home/lobby/information/setup_btn_tab_select.png'),
            INFO_FRAME    = _res('ui/home/lobby/information/restaurant_info_bg_awareness.png'),
            CONFIRM_BTN_N = _res('ui/common/common_btn_orange.png'),
            BILL_TITLE    = _res('ui/home/lobby/information/restaurant_info_bar_title.png'),
        }


        -- local tabFuncBtn  = display.newToggleView(display.cx, display.cy,{n = RES_DICT.TAB_BTN_N, s = RES_DICT.TAB_BTN_S})
        -- local tabFuncLabel = display.newLabel(0,0,FONT.TEXT24({color = '#760000', text = 'define.name'}))--:alignTo(tabFuncBtn, display.CENTER, {parent = true})
        -- tabFuncBtn:getNormalImage():addChild(tabFuncLabel)
        -- testLayer:addChild(tabFuncBtn)

        -- testFunc = function()
        --     tabFuncLabel:alignTo(tabFuncBtn, flowAp, {parent = true, inside = flowType == display.FLOW_V})
        -- end
        -- testFunc()


        -- local popularitySize  = cc.size(300, 120)
        -- local popularityLayer = display.newLayer(display.cx, display.cy, {bg = RES_DICT.INFO_FRAME, scale9 = true, size = popularitySize, ap = display.LEFT_CENTER, capInsets = cc.rect(5,5,735,185)})
        -- testLayer:add(popularityLayer)
        
        -- local popularityIcon  = CommonUtils.GetGoodsIconNodeById(FOOD.GOODS.DEFINE.WATER_BAR_POPULARITY_ID, 0, 0, {ap1 = display.LEFT_CENTER, scale1 = 0.25})
        -- popularityLayer:add(popularityIcon)

        -- testFunc = function()
        --     popularityIcon:alignTo(popularityLayer, flowAp, {offsetX1 = 25, offsetY1 = -15, parent = true, inside = flowType == display.FLOW_V})
        -- end
        -- testFunc()

        testLayer:add( ui.label({fnt = FONT.D20, text = '煎饼馃子', p = display.center}) )

        testLayer:add( ui.image({img = CommonUtils.GetGoodsIconPathById(150138), p = display.center }) )
        
        testLayer:add( ui.cardSpineNode({confId = 200004, init = 'idle', cacheName = SpineCacheName.BATTLE, spineName = 200004, p = cc.rep(display.center, 0, -200) }) )
        testLayer:add( ui.cardSpineNode({confId = 200277, init = 'idle', cacheName = SpineCacheName.BATTLE, spineName = 200277, p = cc.rep(display.center, -450, -200) }) )
        testLayer:add( ui.cardSpineNode({confId = 200278, init = 'idle', cacheName = SpineCacheName.BATTLE, spineName = 200278, p = cc.rep(display.center, 450, -200) }) )


        local cardSkinId = 252780
        local teamBgPath = CardUtils.GetCardTeamBgPathBySkinId(cardSkinId)
        local headPath   = CardUtils.GetCardHeadPathBySkinId(cardSkinId)
		local drawPath   = CardUtils.GetCardDrawPathBySkinId(cardSkinId)
        local drawBgPath = CardUtils.GetCardDrawBgPathBySkinId(cardSkinId)
        local drawFgPath = CardUtils.GetCardDrawFgPathBySkinId(cardSkinId)
        testLayer:addList({
            ui.image({p = display.center, scale = 0.6, img = drawBgPath}),
            ui.image({p = display.center, scale = 0.6, img = drawPath}),
            ui.image({p = display.center, scale = 0.6, img = drawFgPath}),
            ui.image({p = cc.p(display.SAFE_L + 200, display.cy), img = headPath}),
            ui.image({p = cc.p(display.SAFE_R - 200, display.cy), img = teamBgPath}),
        })


        local skillSpinePath = AssetsUtils.GetCardSkillSpinePath('200057_9')
        local realSpinePath = utils.deletePathExtension(_res(skillSpinePath .. '.atlas'))  -- 不能用 json，因为真实 json 文件是 xxxxx.json.zip
        SpineCache(SpineCacheName.BATTLE):addCacheData(realSpinePath, skillSpinePath, 1)

        local avatar = SpineCache(SpineCacheName.BATTLE):createWithName(skillSpinePath)
        avatar:update(0)
        avatar:setPosition(cc.p(display.SAFE_L + 200, 200))
        avatar:setAnimation(0, 'attack', true)
        -- avatar:setAnimation(0, 'attack_end', true)
        -- avatar:setAnimation(0, 'skill1', true)
        -- avatar:setAnimation(0, 'skill2', true)
        testLayer:add( avatar )


        break
    end


    -- anchor rect
    local apRectCommon = {color = cc.c4b(255,255,255,30), size = cc.size(150,150), enable = true}
    local apRectParams = function(params) table.merge(params, apRectCommon); return params end
    local apRectBtnLT = display.newLayer(display.SAFE_L, display.cy*2, apRectParams({ap = cc.p(0.0,1.0)}))
    local apRectBtnLC = display.newLayer(display.SAFE_L, display.cy*1, apRectParams({ap = cc.p(0.0,0.5)}))
    local apRectBtnLB = display.newLayer(display.SAFE_L, display.cy*0, apRectParams({ap = cc.p(0.0,0.0)}))
    local apRectBtnRT = display.newLayer(display.SAFE_R, display.cy*2, apRectParams({ap = cc.p(1.0,1.0)}))
    local apRectBtnRC = display.newLayer(display.SAFE_R, display.cy*1, apRectParams({ap = cc.p(1.0,0.5)}))
    local apRectBtnRB = display.newLayer(display.SAFE_R, display.cy*0, apRectParams({ap = cc.p(1.0,0.0)}))
    local apRectBtnCT = display.newLayer(display.width/2, display.cy*2, apRectParams({ap = cc.p(0.5,1.0)}))
    local apRectBtnCC = display.newLayer(display.width/2, display.cy*1, apRectParams({ap = cc.p(0.5,0.5)}))
    local apRectBtnCB = display.newLayer(display.width/2, display.cy*0, apRectParams({ap = cc.p(0.5,0.0)}))
    local apRectList  = {apRectBtnLT, apRectBtnLC, apRectBtnLB, apRectBtnRT, apRectBtnRC, apRectBtnRB, apRectBtnCT, apRectBtnCC, apRectBtnCB}
    for index, apRectBtn in ipairs(apRectList) do
        apRectBtn:setOnClickScriptHandler(function(sender)
            flowAp = sender:getAnchorPoint()
            testFunc()
        end)
    end
    testLayer:addList(apRectList, 100)


    -- control rect
    local coRectCommon = {size = cc.size(40,40), enable = true, ap = display.CENTER}
    local coRectParams = function(params) table.merge(params, coRectCommon); return params end
    local coRectBtnL   = display.newLayer(display.cx*0.5, display.cy*0.5, coRectParams({color = cc.c4b(0,255,255,255)}))
    local coRectBtnC   = display.newLayer(display.cx*1.0, display.cy*0.5, coRectParams({color = cc.c4b(255,255,0,255)}))
    local coRectBtnR   = display.newLayer(display.cx*1.5, display.cy*0.5, coRectParams({color = cc.c4b(0,255,255,255)}))
    local coRectList   = {coRectBtnL, coRectBtnC, coRectBtnR}
    testLayer:addList(coRectList, 100)

    coRectBtnL:setOnClickScriptHandler(function(sender)
        if flowType == display.FLOW_H then
            flowGapW = flowGapW + 10
        elseif flowType == display.FLOW_V then
            flowGapH = flowGapH + 10
        end
        testFunc()
    end)
    coRectBtnR:setOnClickScriptHandler(function(sender)
        if flowType == display.FLOW_H then
            flowGapW = flowGapW - 10
        elseif flowType == display.FLOW_V then
            flowGapH = flowGapH - 10
        end
        testFunc()
    end)
    coRectBtnC:setOnClickScriptHandler(function(sender)
        if flowType == display.FLOW_H then
            flowType = display.FLOW_V
        elseif flowType == display.FLOW_V then
            flowType = display.FLOW_C
        elseif flowType == display.FLOW_C then
            flowType = display.FLOW_H
        end
        testFunc()
    end)

    -- close button
    self:addCloseButton_(testLayer)


    -- local mainCardNode = ui.cardDrawNode({x = display.cx/2, notRefresh = true, showBg1 = true})
    -- mainCardNode:RefreshAvatar({skinId = 252000 + 1})
    -- testLayer:addChild(mainCardNode)
end


-------------------------------------------------------------------------------
-- homeTheme
-------------------------------------------------------------------------------
function DebugScene:testHomeTheme_()
    local cardUuid = 12345
    app.gameMgr:InitialUserInfo()
    app.gameMgr:UpdatePlayer({playerId = 1002, playerName = 'TestTheme', level = 99, defaultCardId = cardUuid, cards = {
        [tostring(cardUuid)] = {
            id            = cardUuid,
            cardId        = 200023,
            defaultSkinId = 250230,
        }
    }})
    
    local themeKeyArray     = {}
    local isControllable    = true
    self.selectThemeIdx_    = self.selectThemeIdx_ or 0
    HOME_THEME_STYLE_DEFINE = {}

    for themeKey, themeDefine in pairs(HOME_THEME_STYLE_MAP) do
        table.insert(themeKeyArray, {
            themeKey    = themeKey,
            themeDefine = themeDefine,
        })
    end
    table.sort(themeKeyArray, function(a, b)
        return tostring(a.themeDefine.descr) > tostring(b.themeDefine.descr)
    end)
    

    -------------------------------------------------
    local testLayer = ui.layer()
    app.uiMgr:GetCurrentScene():AddDialog(testLayer)


    -- home layer
    local homeLayer = ui.layer()
    testLayer:add(homeLayer)

    local switchBtn = ui.button({n = _res('ui/union/lobby/guild_home_btn_channel.png')}):updateLabel({fnt = FONT.D18, text = '更改主题 ▾', offset = cc.p(0,-26)})
    testLayer:addList(switchBtn):alignTo(nil, ui.ct, {offsetX = -200, offsetY = -2})
    
    local themeLabel = ui.label({fnt = FONT.D3, color = '#FFEEBC', text = '当前主题'})
    switchBtn:addList(themeLabel):alignTo(nil, ui.cc, {offsetY = 16})

    local closeBtn = ui.button({n = _res('ui/home/nmain/main_btn_warning_close.png')})
    testLayer:addList(closeBtn):alignTo(switchBtn, ui.rc, {offsetX = -8, offsetY = 17})

    local tipsLabel = ui.label({fnt = FONT.D3, text = 'Ps：除了【去经营】和【返回】\n其他功能入口别乱点，纯展示！'})
    testLayer:addList(tipsLabel):alignTo(nil, ui.lb, {offsetX = display.SAFE_L + 20, offsetY = 15})


    -- theme list
    local themeListLayer = ui.layer()
    testLayer:add(themeListLayer, 99)
    themeListLayer:setVisible(false)

    local themeBlockLayer = ui.layer({color = cc.c4b(0,0,0,0), enable = true})
    themeListLayer:add(themeBlockLayer)

    local themeListPanel = ui.layer({bg = _res('ui/union/lobby/guild_bg_channel.png'), ap = ui.ct})
    themeListLayer:addList(themeListPanel):alignTo(switchBtn, ui.cb, {offsetY = 33})

    local themeTableView = ui.tableView({size = cc.resize(themeListPanel, -70, -6), dir = display.SDIR_V, csizeH = 80, bgColor1 = cc.r4b(150)})
    themeListPanel:addList(themeTableView):alignTo(nil, ui.cc)
    themeTableView:setCellCreateHandler(function(cellParent)
        local view = cellParent
        local size = cellParent:getContentSize()
        local cpos = cc.sizep(size, ui.cc)

        local centerGroup = view:addList({
            ui.image({img = 'ui/union/lobby/guild_btn_channel_default.png'}),
            ui.image({img = 'ui/union/lobby/guild_btn_channel_select.png'}),
            ui.label({fnt = FONT.D4}),
            ui.layer({size = size, color = cc.r4b(0), enable = true}),
        })
        ui.flowLayout(cpos, centerGroup, {type = ui.flowC, ap = ui.cc})
        
        return {
            view      = view,
            frameN    = centerGroup[1],
            frameS    = centerGroup[2],
            nameLabel = centerGroup[3],
            clickArea = centerGroup[4],
        }
    end)

    -- handler
    local hideThemeListFunc = function()
        isControllable = false
        themeListPanel:setScaleY(1)
        themeListLayer:setVisible(true)
        themeListLayer:stopAllActions()
        themeListLayer:runAction(cc.Sequence:create(
            cc.TargetedAction:create(themeListPanel, cc.ScaleTo:create(0.1, 1, 0)),
            cc.CallFunc:create(function()
                themeListLayer:setVisible(false)
                isControllable = true
            end)
        ))
    end
    local showThemeListFunc = function()
        isControllable = false
        themeListPanel:setScaleY(0)
        themeListLayer:setVisible(true)
        themeListLayer:stopAllActions()
        themeListLayer:runAction(cc.Sequence:create(
            cc.TargetedAction:create(themeListPanel, cc.ScaleTo:create(0.1, 1, 1)),
            cc.CallFunc:create(function()
                isControllable = true
            end)
        ))
    end
    local updateHomeSceneFunc = function()
        isControllable = false
        homeLayer:removeAllChildren()
        closeBtn:setVisible(self.selectThemeIdx_ ~= 0)
        unrequire('home.HomeThemeFunction')
        
        -- home scene
        local homeScene = require('home.HomeScene').new({})
        homeScene:setPosition(display.center)
        -- homeScene:directInit()
        homeScene:delayInit()
        homeScene.isHomeControllable = function(obj)
            return true
        end
        homeLayer:add(homeScene)

        -- waimai spine
        local longxiaPath  = _spn(HOME_THEME_STYLE_DEFINE.LONGXIA_SPINE or 'ui/home/takeaway/longxiache')
        local waimaiPath   = _spn(HOME_THEME_STYLE_DEFINE.WAIMAI_SPINE or 'ui/home/carexplore/waimai')
        local longxiaSpine = ui.spine({path = longxiaPath, init = 'idle'})
        local waimaiSpine  = ui.spine({path = waimaiPath, init = 'idle'})
        homeScene:getMapPanel():addList(longxiaSpine):alignTo(nil, ui.cc, {offsetX = 200, offsetY = -30})
        homeScene:getMapPanel():addList(waimaiSpine):alignTo(nil, ui.cc, {offsetX = 200, offsetY = 140})
        longxiaSpine:setScale(0)
        waimaiSpine:setScale(0)
        

        -- top layer
        local topLayer = require('home.HomeTopLayer').new()
        topLayer:setPosition(cc.p(display.cx, display.height))
        topLayer:setAnchorPoint(ui.ct)
        topLayer:setControllable(false)
        topLayer:initShow()
        homeLayer:add(topLayer)

        -- action
        homeLayer:stopAllActions()
        homeLayer:runAction(cc.Sequence:create(
            cc.DelayTime:create(0.5),
            cc.Spawn:create(
                cc.TargetedAction:create(waimaiSpine, cc.ScaleTo:create(0.2, 1)),
                cc.TargetedAction:create(longxiaSpine, cc.ScaleTo:create(0.2, 1))
            ),
            cc.CallFunc:create(function()
                isControllable = true
            end)
        ))
    end
    local switchThemeData = function(newThemeIndex)
        local oldSelect      = self.selectThemeIdx_
        local newSelect      = newThemeIndex
        local themeData      = themeKeyArray[newSelect] or {}
        local themeDefine    = themeData.themeDefine or {}
        self.selectThemeIdx_ = newSelect
        themeTableView:updateCellViewData(oldSelect)
        themeTableView:updateCellViewData(newSelect)
        themeLabel:updateLabel({text = self.selectThemeIdx_ == 0 and '默认无主题' or tostring(themeDefine.descr)})
        HOME_THEME_STYLE_DEFINE = themeDefine
        updateHomeSceneFunc()
    end
    

    ui.bindClick(themeBlockLayer, function(sender)
        PlayAudioByClickClose()
        if not isControllable then return end
        hideThemeListFunc()
    end, false)

    ui.bindClick(switchBtn, function(sender)
        PlayAudioByClickNormal()
        if not isControllable then return end
        if themeListLayer:isVisible() then
            hideThemeListFunc()
        else
            showThemeListFunc()
        end
    end)

    ui.bindClick(closeBtn, function(sender)
        PlayAudioByClickNormal()
        switchThemeData(0)
    end)

    themeTableView:setCellUpdateHandler(function(cellIndex, cellViewData)
        if cellViewData == nil then return end
        local themeData    = themeKeyArray[cellIndex]
        local themeKey     = themeData.themeKey
        local themeDefine  = themeData.themeDefine
        local hasThemeFunc = HOME_THEME_STYLE_MAP[themeKey].EXTRA_PANEL_THEME_FUNC
        local descrPrefix  = (hasThemeFunc and '*' or '')
        cellViewData.clickArea:setTag(cellIndex)
        cellViewData.frameS:setVisible(self.selectThemeIdx_ == cellIndex)
        cellViewData.nameLabel:updateLabel({text = descrPrefix .. tostring(themeDefine.descr)})

    end)
    themeTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.clickArea, function(sender)
            PlayAudioByClickNormal()
            if not isControllable then return end
            if self.selectThemeIdx_ ~= sender:getTag() then
                switchThemeData(sender:getTag())
            end
        end)
    end)

    -- update views
    themeTableView:resetCellCount(#themeKeyArray)
    switchThemeData(self.selectThemeIdx_)
    

    -- close button
    self:addCloseButton_(testLayer)
end


-------------------------------------------------------------------------------
-- battle
-------------------------------------------------------------------------------
function DebugScene:testBattle_()
    local testLayer = ui.layer()
    app.uiMgr:GetCurrentScene():AddDialog(testLayer)

    -- pre-settings
    app.gameMgr:InitialUserInfo()
    app.gameMgr:UpdatePlayer({playerId = 1, playerName = 'Debuger'})
    CommonUtils.SetControlGameProterty(CONTROL_GAME.CONRROL_MUSIC, false)
    CommonUtils.SetControlGameProterty(CONTROL_GAME.GAME_MUSIC_EFFECT, false)
    cc.UserDefault:getInstance():flush()


    local runType = 's'
    -- local runType = 'c'
    -- local runType = 'v2'

    -- app.gameMgr:UpdatePlayer({localBattleAccelerate = 1})


    local isIgnorePrint = not false
    local isReadFile = true
    local replayData = {
        constructor    = nil, -- 构造器json
        friendTeamJson = nil, -- 友方阵容json
        enemyTeamJson  = nil, -- 敌方阵容json
        resources      = nil, -- 加载资源表json
        playerOperate  = nil, -- 玩家手操信息json
        fromToStruct   = nil, -- 跳转信息
    }


    if isReadFile then
        local filePath  = 'data_battle_request'
        local filePath  = 'data_battle_request2'
        local tableData = {}
        
        if FTUtils:isPathExistent(filePath) then
            local battlelog = io.readfile(cc.FileUtils:getInstance():fullPathForFilename(filePath))
            tableData = json.decode(battlelog)
            dump(tableData, 'tableData')
            for key, value in pairs(tableData) do
                logs('..battlelogFile)', key)
            end
        else
            runType = nil
            app.uiMgr:AddNewCommonTipDialog({text = string.fmt('filePath = %1', filePath), extra = 'file not existent!!' ,isOnlyOK = true, isForced = true})
        end

        replayData.friendTeamJson = tableData.friendTeamJson
        replayData.enemyTeamJson  = tableData.enemyTeamJson
        replayData.resources      = tableData.resources
        replayData.constructor    = tableData.constructor
        replayData.playerOperate  = tableData.playerOperate

        while not true do
            local teamsLog   = io.readfile(cc.FileUtils:getInstance():fullPathForFilename('data_Championship_replayOverall'))
            local teamsTable = json.decode(teamsLog)
            -- dump(teamsTable, 'teamsTable', 3)
        
            local roundText   = '2'
            local resultLog   = io.readfile(cc.FileUtils:getInstance():fullPathForFilename('data_Championship_replayDetail '))
            local resultTable = json.decode(resultLog)
            -- dump(resultTable, 'resultTable', 3)

            replayData.friendTeamJson = json.encode({teamsTable.data[roundText].friendTeam})
            replayData.enemyTeamJson  = json.encode({teamsTable.data[roundText].enemyTeam})
            replayData.resources      = resultTable.data.loadedResources
            replayData.constructor    = resultTable.data.constructor
            replayData.playerOperate  = resultTable.data.playerOperate
            -- print(tableToString(replayData, '--== replayData ==--'))
            -- replayData.playerOperate = string.trim(([[{
            --     [0]={[1]={["maxParams"]=0,["managerName"]="G_BattleLogicMgr",["functionName"]="RenderReadyStartNextWaveHandler",["variableParams"]={}}},
            --     [47]={[1]={["maxParams"]=0,["managerName"]="G_BattleLogicMgr",["functionName"]="RenderStartNextWaveHandler",["variableParams"]={}}},
            --     [207]={[1]={["maxParams"]=3,["managerName"]="G_BattleLogicMgr",["functionName"]="ConnectCISceneEnter",["variableParams"]={[1]=1001,[2]=90165,[3]=1}}},
            --     [292]={[1]={["maxParams"]=3,["managerName"]="G_BattleLogicMgr",["functionName"]="ConnectCISceneExit",["variableParams"]={[1]=1001,[2]=90165,[3]=1}}},
            -- }]]))

            -- local resultLog   = io.readfile(cc.FileUtils:getInstance():fullPathForFilename('1'))
            -- local resultTable = json.decode(resultLog)
            -- replayData.resources = resultTable.mergedRes[checkint(roundText)]
            -- replayData.constructor = resultTable.constructor[checkint(roundText)]
            -- replayData.playerOperate = resultTable.operateStr[checkint(roundText)]
            break
        end

    else
        -- local randomseed = nil
        -- randomseed = 2922919951
        -- __THE_WORLD__TOKIYO_TOMARE__ = true
        
        -- team data
        local friendDefines = {
            { skinId = 250125, level = 10 }, -- 红茶（连携技：后空翻射击）
            { skinId = 250234, level = 10 }, -- 牛奶（连携技：聚集光球爆炸）
            { skinId = 250033, level = 10 }, -- 咖啡（连携技：打出一摊咖啡）
            { skinId = 250154, level = 10 }, -- 巧克力（连携技：后空翻放出玫瑰圈）
            { skinId = 250084, level = 10 }, -- 提拉米苏（连携技：召海豚大面积回血）
            -- { skinId = 252770, level = 1 },  -- 薯片：pop子（连携技：蓄力放出大薯片）
        }
        local enemyDefines  = {
            -- { skinId = 250125, level = 10 }, -- 红茶（连携技：后空翻射击）
            -- { skinId = 250234, level = 10 }, -- 牛奶（连携技：聚集光球爆炸）
            -- { skinId = 250033, level = 10 }, -- 咖啡（连携技：打出一摊咖啡）
            -- { skinId = 250154, level = 10 }, -- 巧克力（连携技：后空翻放出玫瑰圈）
            -- { skinId = 250084, level = 10 }, -- 提拉米苏（连携技：召海豚大面积回血）
            { skinId = 252770, level = 1 },  -- 薯片：pop子（连携技：蓄力放出大薯片）
            { skinId = 252780, level = 1 },  -- 巧克力棒：pipi美（连携技：旋转棒子放冲击波）
            { skinId = 251740, level = 1 },  -- 樱花茶：小樱（连携技：召唤火鸟喷火）
            { skinId = 251750, level = 1 },  -- 瑞士卷：小可（连携技：后空翻重重砸下蛋糕）
        }
        -- friendDefines = {
        --     { skinId = 251750, level = 1 },  -- 瑞士卷：小可（连携技：后空翻重重砸下蛋糕）
        --     { skinId = 251740, level = 1 },  -- 樱花茶：小樱（连携技：召唤火鸟喷火）
        -- }
        -- enemyDefines  = {
        --     { skinId = 252780, level = 1 },  -- 巧克力棒：pipi美（连携技：旋转棒子放冲击波）
        --     { skinId = 252770, level = 1 },  -- 薯片：pop子（连携技：蓄力放出大薯片）
        -- }
        local createCardData = function(cardDefine)
            local skinConf = CardUtils.GetCardSkinConfig(cardDefine.skinId)
            local cardConf = CardUtils.GetCardConfig(skinConf.cardId)
            local cardData = {
                id            = math.random(99999),
                level         = cardDefine.level,
                breakLevel    = checkint(cardDefine.blevel),
                cardId        = skinConf.cardId,
                defaultSkinId = cardDefine.skinId,
                skill         = {},
            }
            for i,v in ipairs(cardConf.skill or {}) do
                cardData.skill[tostring(v)] = {level = 40}
            end
            return cardData
        end
        local enemyTeamData  = {}
        local friendTeamData = {}
        for cardIndex, cardDefine in ipairs(friendDefines) do
            friendTeamData[cardIndex] = createCardData(cardDefine)
        end
        for cardIndex, cardDefine in ipairs(enemyDefines) do
            enemyTeamData[cardIndex] = createCardData(cardDefine)
        end
        replayData.friendTeamJson = json.encode({friendTeamData}) -- 友方阵容json
        replayData.enemyTeamJson  = json.encode({enemyTeamData})  -- 敌方阵容json


        -- constructor
        local battleConstructor = require('battleEntry.BattleConstructorEx').new()
        battleConstructor:InitByCommonData(
            0,                                      -- 关卡 id
            -- QuestBattleType.FRIEND_BATTLE,          -- 战斗类型
            QuestBattleType.CHAMPIONSHIP_PROMOTION, -- 战斗类型
            ConfigBattleResultType.ONLY_RESULT,     -- 结算类型
            ----
            {},                                     -- 友方阵容
            {},                                     -- 敌方阵容
            ----
            nil,                                    -- 友方携带的主角技
            nil,                                    -- 友方所有主角技
            nil,                                    -- 敌方携带的主角技
            nil,                                    -- 敌方所有主角技
            ----
            nil,                                    -- 全局buff
            nil,                                    -- 卡牌能力增强信息
            ----
            nil,                                    -- 已买活次数
            nil,                                    -- 最大买活次数
            false,                                  -- 是否开启买活
            ----
            randomseed,                             -- 随机种子
            false,                                  -- 是否是战斗回放
            ----
            nil,                                    -- 与服务器交互的命令信息
            nil                                     -- 跳转信息
        )
        replayData.constructor = battleConstructor:CalcRecordConstructData()


        -- resources data
        local friendLoadedRes = battleConstructor:CalcLoadSpineResOneTeam(
            nil,           -- 关卡id
            nil,           -- 战斗类型
            friendDefines, -- 队伍数据
            true           -- 检查连携
        )
        local enemyLoadedRes = battleConstructor:CalcLoadSpineResOneTeam(
            nil,          -- 关卡id
            nil,          -- 战斗类型
            enemyDefines, -- 队伍数据
            true          -- 检查连携
        )
        local loadedResArray = {
            string.gsub(friendLoadedRes, '{%[1%]={(.*)}}', '%1'),
            string.gsub(enemyLoadedRes, '{%[1%]={(.*)}}', '%1'),
        }
        replayData.resources = string.fmt('{[1]={%1}}', table.concat(loadedResArray, ','))

        -- 2 : 1
        -- replayData.playerOperate = string.trim([[{
        --     [0]={[1]={["maxParams"]=0,["managerName"]="G_BattleLogicMgr",["functionName"]="RenderReadyStartNextWaveHandler",["variableParams"]={}}},
        --     [47]={[1]={["maxParams"]=0,["managerName"]="G_BattleLogicMgr",["functionName"]="RenderStartNextWaveHandler",["variableParams"]={}}},
        --     [571]={[1]={["maxParams"]=3,["managerName"]="G_BattleLogicMgr",["functionName"]="ConnectCISceneEnter",["variableParams"]={[1]=1,[2]=90012,[3]=1}}},
        --     [656]={[1]={["maxParams"]=3,["managerName"]="G_BattleLogicMgr",["functionName"]="ConnectCISceneExit",["variableParams"]={[1]=1,[2]=90012,[3]=1}}}
        -- }]])
        -- 1 : 2
        -- replayData.playerOperate = string.trim([[{
        --     [0]={[1]={["maxParams"]=0,["managerName"]="G_BattleLogicMgr",["functionName"]="RenderReadyStartNextWaveHandler",["variableParams"]={}}},
        --     [47]={[1]={["maxParams"]=0,["managerName"]="G_BattleLogicMgr",["functionName"]="RenderStartNextWaveHandler",["variableParams"]={}}},
        --     [664]={[1]={["maxParams"]=3,["managerName"]="G_BattleLogicMgr",["functionName"]="ConnectCISceneEnter",["variableParams"]={[1]=1001,[2]=90012,[3]=1}}},
        --     [749]={[1]={["maxParams"]=3,["managerName"]="G_BattleLogicMgr",["functionName"]="ConnectCISceneExit",["variableParams"]={[1]=1001,[2]=90012,[3]=1}}}
        -- }]])
        -- 5 : 4
        replayData.playerOperate = string.trim([[{
            [0]={[1]={["maxParams"]=0,["managerName"]="G_BattleLogicMgr",["functionName"]="RenderReadyStartNextWaveHandler",["variableParams"]={}}},
            [47]={[1]={["maxParams"]=0,["managerName"]="G_BattleLogicMgr",["functionName"]="RenderStartNextWaveHandler",["variableParams"]={}}},
            [397]={[1]={["maxParams"]=3,["managerName"]="G_BattleLogicMgr",["functionName"]="ConnectCISceneEnter",["variableParams"]={[1]=1,[2]=90012,[3]=1}}},
            [482]={[1]={["maxParams"]=3,["managerName"]="G_BattleLogicMgr",["functionName"]="ConnectCISceneExit",["variableParams"]={[1]=1,[2]=90012,[3]=1}}},
            [517]={[1]={["maxParams"]=3,["managerName"]="G_BattleLogicMgr",["functionName"]="ConnectCISceneEnter",["variableParams"]={[1]=1004,[2]=90175,[3]=2}}},
            [602]={[1]={["maxParams"]=3,["managerName"]="G_BattleLogicMgr",["functionName"]="ConnectCISceneExit",["variableParams"]={[1]=1004,[2]=90175,[3]=2}}},
            [791]={[1]={["maxParams"]=3,["managerName"]="G_BattleLogicMgr",["functionName"]="ConnectCISceneEnter",["variableParams"]={[1]=1001,[2]=90277,[3]=3}}},
            [876]={[1]={["maxParams"]=3,["managerName"]="G_BattleLogicMgr",["functionName"]="ConnectCISceneExit",["variableParams"]={[1]=1001,[2]=90277,[3]=3}}}
        }]])
    end
    

    local CLOSE_TEST_BATTLE_MDT = 'CLOSE_TEST_BATTLE_MDT'
    if not app.router.Dispatch_ then
        app.router.Dispatch_ = app.router.Dispatch
        app.router.Dispatch = function(ojb, from, to, isBack, handleErrorSelf)
            if to.name ~= CLOSE_TEST_BATTLE_MDT then
                app.router:Dispatch_(from, to, isBack, handleErrorSelf)
            else
                app.router:ClearMediators()
                app.uiMgr:SwitchToTargetScene(DEBUG_SCENE_NAME)
            end
        end
    end


    -------------------------------------------------
    -- server
    if runType == 's' then
        lfs.chdir(device.writablePath .. 'src/')
        unrequire('Game.utils.CommonUtils')  -- 据说会污染战斗中的 CommonUtils 重定义，所以要先卸一下
        require('battleEntryServer.BattleEntry')

        local print_temp = nil
        if isIgnorePrint then
            print_temp = print
            print = function(...) end
        end

        -- local resultJson = G_BattleChecker:RunOneBattle(nil,
        local resultJson = G_BattleChecker:CalcOneBattle(nil,
            replayData.constructor,
            replayData.friendTeamJson,
            replayData.enemyTeamJson,
            replayData.resources
            -- replayData.playerOperate
        )
        if print_temp then
            print = print_temp
        end
        print('+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+')
        print(resultJson)
        print('+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+')


        require('Game.utils.CommonUtils')
        require('battle_new.util.BattleReportUtils')
        local resultData  = json.decode(resultJson)
        local operateList = {}
        for frameKey, value in pairs(String2TableNoMeta(resultData.operateStr)) do
            operateList[frameKey] = json.encode(value)
        end
        local operateStr  = tableToString(operateList, '--== operate ==--', 10)
        local skadaDescr  = tableToString(json.decode(resultData.skadaResult), '--== skadaResult ==--', 10)
        local fightDescr  = tableToString(BattleReportUtils.decodeReport(resultData.fightData), '--== fightData ==--', 10)
        local constructor = tableToString(String2TableNoMeta(resultData.constructorJson), '--== constructor ==--', 10)
        local descrView   = self:addScrollDescrView_(testLayer)
        descrView:appendDescr('battleResult = ' .. resultData.battleResult)
        descrView:appendDescr(constructor)
        descrView:appendDescr(operateStr)
        descrView:appendDescr(skadaDescr)
        descrView:appendDescr(fightDescr)
        

    -------------------------------------------------
    -- client
    elseif runType == 'c' then
        -- 跳转参数
        replayData.fromToStruct = BattleMediatorsConnectStruct.New(
            CLOSE_TEST_BATTLE_MDT, -- from mdt
            CLOSE_TEST_BATTLE_MDT  -- to mdt
        )

        -- 手操信息
        local operateList = {
            '[0]={[1]={["maxParams"]=0,["managerName"]="G_BattleLogicMgr",["functionName"]="RenderReadyStartNextWaveHandler",["variableParams"]={}}},',
            '[47]={[1]={["maxParams"]=0,["managerName"]="G_BattleLogicMgr",["functionName"]="RenderStartNextWaveHandler",["variableParams"]={}}}',
        }
        replayData.playerOperate = replayData.playerOperate or string.fmt('{%1}', table.concat(operateList, ''))
        
        -- 回放战斗
        local battleConstructor = require('battleEntry.BattleConstructor').new()
        battleConstructor:OpenReplay(
            nil,                        -- 关卡id
            replayData.constructor,    -- 构造器json
            replayData.friendTeamJson, -- 友方阵容json
            replayData.enemyTeamJson,  -- 敌方阵容json
            replayData.resources,      -- 加载资源表json
            replayData.playerOperate,  -- 玩家手操信息json
            replayData.fromToStruct    -- 跳转信息
        )

        app:RegistObserver('BATTLE_REPLAY_OVER', mvc.Observer.new(function(context, signal)
            local data       = signal:GetBody()
            local isPassed   = data.isPassed
            local resultData = data.commonParams
            
            require('battle_new.util.BattleReportUtils')
            logs('--== isPassed ==--', isPassed)
            logt(json.decode(resultData.skadaResult), '--== skadaResult ==--', 10)
            logt(BattleReportUtils.decodeReport(resultData.fightData), '--== fightData ==--')

            app:UnRegistObserver('BATTLE_REPLAY_OVER', self)
        end, self))


    -------------------------------------------------
    -- test view : replayResult
    elseif runType == 'v1' then
        require('battle_new.util.BattleConfigUtils')
        require('battle_new.util.BattleUtils')
        local className = 'battle_new.view.BattleReplayResultView'
        local layer = require(className).new({
            trophyData    = {},
            teamData      = {
                { skinId = 252770, favorLevel = 6 }
            },
            enemyTeamData = {
                { skinId = 252780, favorLevel = 6 }
            },
            -- battleResult = 3, -- win
            battleResult = 4, -- lost
        })
        display.commonUIParams(layer, {ap = cc.p(0, 0), po = cc.p(0, 0)})
        testLayer:add(layer)


    -------------------------------------------------
    -- test view : cutinScene
    elseif runType == 'v2' then
        require('battle_new.util.BattleResUtils')
        for i,v in ipairs(BRUtils.GetCardCutinSceneConfig()) do
            if not SpineCache(SpineCacheName.BATTLE):hasSpineCacheData(v.path) then
                SpineCache(SpineCacheName.BATTLE):addCacheData(v.path, v.cacheName, v.scale)
            end
        end

        local sceneTag = 103
        local skinId   = 250125
        local skinConf = CardUtils.GetCardSkinConfig(skinId)
        local cardConf = CardUtils.GetCardConfig(skinConf.cardId)
        local cardId   = cardConf.cardId
        local skillId  = cardConf.skill[3]
        local otherSId = { skinId }
        for _, concertCardId in ipairs(cardConf.concertSkill) do
            table.insert(otherSId, CardUtils.GetCardDefaultSkinIdByCardId(concertCardId))
        end
        local params = {
            ownerTag        = 1001,
            tag             = sceneTag,
            mainSkinId      = skinId,
            otherHeadSkinId = otherSId,
            isEnemy         = true,
            startFrame      = 396,
            durationFrame   = ANITIME_CUTIN_SCENE,  -- 86
            overCB = function()
                scheduler.unscheduleGlobal(self.updateHandler_)
                self.updateHandler_ = nil
                logs('over')
            end,
        }
        local layer = __Require('battle.miniGame.CutinScene').new(params)
        testLayer:add(layer)
        layer:start()

        self.updateHandler_ = scheduler.scheduleGlobal(function(dt)
            layer:update(dt)
        end, 1/30)
    end


    -- close button
    local closeBtn  = self:addCloseButton_(testLayer)
    local sceneName = checkstr(app.uiMgr:GetCurrentScene().contextName)
    if sceneName == 'Game.views.LoadingView' then
        cc.Director:getInstance():setDisplayStats(true)
        ui.bindClick(closeBtn, function()
            CommonUtils.SetControlGameProterty(CONTROL_GAME.CONRROL_MUSIC, false)
            CommonUtils.SetControlGameProterty(CONTROL_GAME.GAME_MUSIC_EFFECT, false)
            cc.UserDefault:getInstance():flush()
            if G_BattleMgr then
                G_BattleMgr:QuitBattle()
            end
            cc.Director:getInstance():setDisplayStats(false)
        end)
    end
end


-------------------------------------------------------------------------------
-- spine
-------------------------------------------------------------------------------
function DebugScene:testSpine_()
    local testLayer = display.newLayer()
    app.uiMgr:GetCurrentScene():AddDialog(testLayer)

    local RES_DICT = {
        TAB_BTN_N = _res('ui/home/market/market_bg_choice_type_default.png'),
        TAB_BTN_S = _res('ui/home/market/market_bg_choice_type_selected.png'),
        EXT_BTN_N = _res('ui/common/tujian_btn_selection_unused.png'),
        EXT_BTN_S = _res('ui/common/tujian_btn_selection_choosed.png'),
        COMBOX_BG = _res('ui/common/common_bg_a.png'),
        SLIDER_S  = _res('ui/home/infor/setup_volume_btn.png'),
        SLIDER_P  = _res('ui/home/infor/setup_bar_exp_1.png'),
        SLIDER_BG = _res('ui/home/infor/setup_bar_exp_2.png'),
    }

    local spineExampleDefines = {
        {id = 'goblin',   name = '哥布林',  path = 'res_sub/spine/goblins/goblins',   init = 'walk',      offset = cc.p(0,-100)},
        {id = 'mao',      name = '简单猫',  path = 'res_sub/spine/mao/mao',           init = 'idle',      offset = cc.p(0,-150), scale = 0.5},
        {id = 'mtest',    name = 'M测试',   path = 'res_sub/spine/mtest/test',        init = 'idle',      offset = cc.p(0,-100)},
        {id = 'hero',     name = '小英雄',  path = 'res_sub/spine/heroes/heroes',     init = 'idle',      offset = cc.p(0,-150), scale = 0.5},
        {id = 'spineboy', name = '平滑过度', path = 'res_sub/spine/spineboy/spineboy', init = 'idle',      offset = cc.p(-200,-150), scale = 0.6},
        {id = 'meshes',   name = '网格变形', path = 'res_sub/spine/meshes/orangegirl', init = 'animation', offset = cc.p(0,-240)},
        {id = '310000',   name = '猫demo',  path = 'res_sub/spine/cat/310000',        init = 'idle',      offset = cc.p(0,-200), scale = 1},
    }

    -------------------------------------------------
    -- right info

    local infoTableSize = cc.size(200, display.height - 40 - 100)
    local rightInfoGroup = testLayer:addList({
        ui.label({fnt = FONT.D20, fontSize = 30, text = '额外控制', hAlign = display.TAC, w = infoTableSize.width}),
        ui.listView({size = infoTableSize, dir = display.SDIR_V, bgColor = '#FFFFFF99'}),
    })
    ui.flowLayout(cc.p(display.SAFE_R, display.height), rightInfoGroup, {type = ui.flowV, ap = ui.rb})

    
    local refreshExtraInfoList = function(exampleDefine)
        local cellsArray     = {}
        local extraInfoList  = rightInfoGroup[2]
        local extraInfoListW = extraInfoList:getContentSize().width
        local reloadCallback = nil
        extraInfoList:removeAllNodes()
        
        -------------------------------------------------
        -- goblins
        if exampleDefine.id == 'goblin' then
            cellsArray = {
                ui.label({fnt = FONT.D1, color = '#734441', text = '更改皮肤'}),
                ui.button({n = RES_DICT.EXT_BTN_N}):updateLabel({fnt = FONT.D19, text = 'goblin'}),
                ui.button({n = RES_DICT.EXT_BTN_N}):updateLabel({fnt = FONT.D19, text = 'goblingirl'}),
                ui.label({fnt = FONT.D1, color = '#734441', text = '更改凹槽'}),
                ui.button({n = RES_DICT.EXT_BTN_N}):updateLabel({fnt = FONT.D19, text = 'dagger'}),
                ui.button({n = RES_DICT.EXT_BTN_N}):updateLabel({fnt = FONT.D19, text = 'spear'}),
            }

            for _, skinBtn in ipairs({cellsArray[2], cellsArray[3]}) do
                ui.bindClick(skinBtn, function(sender)
                    testLayer.runingSpineNode:setSkin(sender:getText())
                end)
            end
            for _, soltBtn in ipairs({cellsArray[5], cellsArray[6]}) do
                ui.bindClick(soltBtn, function(sender)
                    if testLayer.runingSpineNode.setAttachment then
                        testLayer.runingSpineNode:setAttachment('left-hand-item', sender:getText())
                    else
                        app.uiMgr:ShowInformationTips('!! Spine.setAttachment not support !!')
                    end
                end)
            end


            -- 挂点测试
            local testNode = ui.layer({size = cc.size(100, 100), color = cc.r4b(150), ap1 = ui.cc})
            testLayer.runingSpineNode:add(testNode)
            testNode:scheduleUpdateWithPriorityLua(function(dt)
                local boneData = testLayer.runingSpineNode:findBone('spear3')
                testNode:setPositionX(boneData.worldX)
                testNode:setPositionY(boneData.worldY)
                testNode:setRotation(boneData.rotation)
            end, 0)


            reloadCallback = function()
                cellsArray[2]:toOnClickScriptHandler()
            end

        -------------------------------------------------
        -- mao
        elseif exampleDefine.id == 'mao' then
            local mixedSkinList = {
                { name = 'mix11', skins = { 'body', 'erduo1', 'yanjing1' } },
                { name = 'mix12', skins = { 'body', 'erduo1', 'yanjing2' } },
                { name = 'mix21', skins = { 'body', 'erduo2', 'yanjing1' } },
                { name = 'mix22', skins = { 'body', 'erduo2', 'yanjing2' } },
            }

            table.insert(cellsArray, ui.label({fnt = FONT.D1, color = '#734441', text = '混合换皮'}))
            for mixedIndex, mixedData in ipairs(mixedSkinList) do
                table.insert(cellsArray, ui.button({n = RES_DICT.EXT_BTN_N, tag = mixedIndex}):updateLabel({fnt = FONT.D19, text = mixedData.name}))
            end

            for cellIndex = 2, #cellsArray do
                ui.bindClick(cellsArray[cellIndex], function(sender)
                    local mixedSkinIndex = sender:getTag()
                    local mixedSkinData  = mixedSkinList[mixedSkinIndex]
                    if testLayer.runingSpineNode.setMixedSkins then
                        testLayer.runingSpineNode:setMixedSkins(mixedSkinData.name, mixedSkinData.skins)
                        testLayer.runingSpineNode:setSlotsToSetupPose()
                    else
                        app.uiMgr:ShowInformationTips('!! Spine.setMixedSkins not support !!')
                    end
                end)
            end

            reloadCallback = function()
                cellsArray[2]:toOnClickScriptHandler()
            end

        -------------------------------------------------
        -- mtest
        elseif exampleDefine.id == 'mtest' then
            local skinTypeMap = {
                hat  = {name = '帽子', names = { 'bigHat',   'smallHat' } },
                hair = {name = '头发', names = { 'blueHair', 'redHair'  } },
                eye  = {name = '眼睛', names = { 'blueEye',  'yellowEye'} },
            }
    
            -- default
            local applySkinMap = {}
            for type, define in pairs(skinTypeMap) do
                applySkinMap[type] = define.names[1]
            end

            local partBtnArray = {}
            for type, define in pairs(skinTypeMap) do
                table.insert(cellsArray, ui.label({fnt = FONT.D1, color = '#734441', text = define.name}))
                for _, name in ipairs(define.names) do
                    local partBtn = ui.tButton({n = RES_DICT.EXT_BTN_N, s = RES_DICT.EXT_BTN_S, nLabel = {fnt = FONT.D14, text = name}})
                    partBtn.partName = name
                    partBtn.partType = type
                    table.insert(partBtnArray, partBtn)
                    table.insert(cellsArray, partBtn)
                end
            end

            for _, partBtn in ipairs(partBtnArray) do
                ui.bindClick(partBtn, function(sender)
                    local skinName = sender.partName
                    local skinType = sender.partType
                    applySkinMap[skinType] = skinName
                    
                    local skinList  = table.values(applySkinMap)
                    local mixedName = table.concat(skinList, ',')
                    if testLayer.runingSpineNode.setMixedSkins then
                        testLayer.runingSpineNode:setMixedSkins(mixedName, skinList)
                        testLayer.runingSpineNode:setToSetupPose()
                        -- testLayer.runingSpineNode:setBonesToSetupPose()
                        -- testLayer.runingSpineNode:setSlotsToSetupPose()
                    else
                        app.uiMgr:ShowInformationTips('!! Spine.setMixedSkins not support !!')
                    end
        
                    for _, tButton in ipairs(partBtnArray) do
                        local isSelected = false
                        for _, name in pairs(applySkinMap) do
                            if tButton.partName == name then
                                isSelected = true
                                break
                            end
                        end
                        tButton:setChecked(isSelected)
                    end
                end, false)
            end

            reloadCallback = function()
                partBtnArray[1]:toOnClickScriptHandler()
            end

        -------------------------------------------------
        -- hero
        elseif exampleDefine.id == 'hero' then
            cellsArray = {
                ui.button({n = RES_DICT.EXT_BTN_N}):updateLabel({fnt = FONT.D19, text = '挥剑'}),
                ui.button({n = RES_DICT.EXT_BTN_N}):updateLabel({fnt = FONT.D19, text = '随机'}),
                ui.button({n = RES_DICT.EXT_BTN_S}):updateLabel({fnt = FONT.D19, text = '换肤'}),
            }

            ui.bindClick(cellsArray[1], function(sender)
                sender.playCount = sender.playCount and (sender.playCount + 1) or 1
                testLayer.runingSpineNode:setAnimation(5, sender.playCount % 2 == 0 and 'meleeSwing2' or 'meleeSwing1', false)
            end)

            ui.bindClick(cellsArray[2], function(sender)
                if not testLayer.runingSpineNode.getSkeletonData then
                    app.uiMgr:ShowInformationTips('!! Spine.getSkeletonData not support !!')
                    return
                end
                if not testLayer.runingSpineNode.setMixNewSkin then
                    app.uiMgr:ShowInformationTips('!! Spine.setMixNewSkin not support !!')
                    return
                end
                if not testLayer.runingSpineNode.findSkin then
                    app.uiMgr:ShowInformationTips('!! Spine.findSkin not support !!')
                    return
                end

                local parts = {}
                local skins = testLayer.runingSpineNode:getSkeletonData().skins
                local slots = testLayer.runingSpineNode:getSkeletonData().slots
                table.removebyvalue(skins, 'default')

                for slotIndex, slotName in ipairs(slots) do
                    local skinName = skins[math.random(#skins)]
                    local skinData = testLayer.runingSpineNode:findSkin(skinName)
                    for _, data in ipairs(skinData.attachments[slotName] or {}) do
                        table.insert(parts, {
                            skinName  = skinName,
                            slotIndex = data.slotIndex,
                            entryName = data.name,
                        })
                    end
                end
                testLayer.runingSpineNode:setMixNewSkin('random-skin', parts)
            end)

            ui.bindClick(cellsArray[3], function(sender)
                local skinArray = testLayer.runingSpineNode:getSkeletonData().skins
                table.removebyvalue(skinArray, 'default')

                local skinListLayer = ui.layer()
                testLayer:add(skinListLayer, 99)

                local skinBlockLayer = ui.layer({color = cc.r4b(0), enable = true})
                skinListLayer:add(skinBlockLayer)
                ui.bindClick(skinBlockLayer, function(sender)
                    skinListLayer:runAction(cc.RemoveSelf:create(true))
                end)

                local skinListSize  = cc.size(220, 480)
                local skinListPanel = ui.layer({bg = RES_DICT.COMBOX_BG, ap = ui.ct, cut = cc.dir(20,20,20,20), size = skinListSize})
                skinListLayer:addList(skinListPanel)
                skinListPanel:setPosition(cc.pAdd(sender:convertToWorldSpaceAR(PointZero), cc.p(0, 30)))

                local skinTableView = ui.tableView({size = cc.resize(skinListSize, -16, -20), dir = display.SDIR_V, csizeH = 40})
                skinListPanel:addList(skinTableView):alignTo(nil, ui.cc, {offsetX = 2})
                skinTableView:setCellCreateHandler(function(cellParent)
                    local view = cellParent
                    local size = cellParent:getContentSize()
                    local cpos = cc.sizep(size, ui.cc)

                    local nameBtn = ui.colorBtn({size = size, color = cc.r4b(0)}):updateLabel({fnt = FONT.D4})
                    view:addList(nameBtn):alignTo(nil, ui.cc)
                    
                    return {
                        view    = view,
                        nameBtn = nameBtn,
                    }
                end)
                skinTableView:setCellUpdateHandler(function(cellIndex, cellViewData)
                    if cellViewData == nil then return end
                    local skinName = tostring(skinArray[cellIndex])
                    cellViewData.nameBtn:updateLabel({text = skinName})
                    cellViewData.nameBtn:setTag(cellIndex)
                end)
                skinTableView:setCellInitHandler(function(cellViewData)
                    ui.bindClick(cellViewData.nameBtn, function(sender)
                        local skinName = tostring(sender:getText())
                        testLayer.runingSpineNode:setSkin(skinName)
                    end)
                end)

                skinListPanel:setScaleY(0)
                skinListPanel:runAction(cc.ScaleTo:create(0.1, 1))
                skinTableView:resetCellCount(#skinArray)
            end)

            reloadCallback = function()
                testLayer.runingSpineNode:setSkin('Assassin')
                testLayer.runingSpineNode:setAnimation(0, 'run', true)
            end

        -------------------------------------------------
        -- spineboy
        elseif exampleDefine.id == 'spineboy' then
            cellsArray = {
                ui.slider({sImg = RES_DICT.SLIDER_S, pImg = RES_DICT.EXT_BTN_N, bg = RES_DICT.EXT_BTN_S}),
                ui.label({fnt = FONT.D19, ap = ui.cb}),
                ui.slider({sImg = RES_DICT.SLIDER_S, pImg = RES_DICT.EXT_BTN_N, bg = RES_DICT.EXT_BTN_S}),
                ui.label({fnt = FONT.D19, ap = ui.cb}),
                ui.button({n = RES_DICT.EXT_BTN_N}):updateLabel({fnt = FONT.D19, text = 'jump'}),
                ui.button({n = RES_DICT.EXT_BTN_N}):updateLabel({fnt = FONT.D19, text = 'run'}),
                ui.button({n = RES_DICT.EXT_BTN_N}):updateLabel({fnt = FONT.D19, text = 'walk'}),
            }

            local speedLabel   = cellsArray[2]
            local speedSlider  = cellsArray[1]
            local defMixLabel  = cellsArray[4]
            local defMixSlider = cellsArray[3]
            speedSlider:setMinValue(0)
            speedSlider:setMaxValue(200)
            defMixSlider:setMinValue(0)
            defMixSlider:setMaxValue(100)
            
            local updateTimeScaleFunc = function(timeScale)
                speedLabel:updateLabel({text = '速度：' .. timeScale})
                speedSlider:setNowValue(timeScale * 100)
                testLayer.runingSpineNode:setTimeScale(timeScale)
                testLayer.runingSpineNode2:setTimeScale(timeScale)
            end

            local updateDefaultMixFunc = function(defaultMix)
                defMixLabel:updateLabel({text = '过度：' .. defaultMix})
                defMixSlider:setNowValue(defaultMix * 100)
                if testLayer.runingSpineNode.setDefaultMix then
                    testLayer.runingSpineNode:setDefaultMix(defaultMix)
                else
                    app.uiMgr:ShowInformationTips('!! Spine.setDefaultMix not support !!')
                end
            end
            
            speedSlider:setOnValueChangedScriptHandler(function(sender, value)
                updateTimeScaleFunc(value / 100)
            end)

            defMixSlider:setOnValueChangedScriptHandler(function(sender, value)
                updateDefaultMixFunc(value / 100)
            end)

            for _, animeBtn in ipairs({cellsArray[5], cellsArray[6], cellsArray[7]}) do
                ui.bindClick(animeBtn, function(sender)
                    local animeDataMap  = testLayer.runingSpineNode:getAnimationsData()
                    local animeDuration = animeDataMap[sender:getText()].duration
                    testLayer.runingSpineNode:setAnimation(0, sender:getText(), false)
                    testLayer.runingSpineNode2:setAnimation(0, sender:getText(), false)
                    testLayer.runingSpineNode:addAnimation(0, 'idle', true, animeDuration)
                    testLayer.runingSpineNode2:addAnimation(0, 'idle', true, animeDuration)
                end)
            end
            
            reloadCallback = function()
                testLayer.runingSpineNode2 = ui.spine({path = _spn(exampleDefine.path), init = exampleDefine.init, scale = exampleDefine.scale})
                testLayer.runingSpineNode2:setPositionX(testLayer.runingSpineNode:getPositionX() + 400)
                testLayer.runingSpineNode2:setPositionY(testLayer.runingSpineNode:getPositionY())
                testLayer:add(testLayer.runingSpineNode2)
                
                testLayer.runingSpineNode2:add(ui.label({fnt = FONT.D20, text = '生硬的'}))
                testLayer.runingSpineNode:add(ui.label({fnt = FONT.D20, text = '平滑的'}))
                
                updateTimeScaleFunc(1)
                updateDefaultMixFunc(0)

                testLayer.cleanCallback = function()
                    if testLayer.runingSpineNode2 then
                        testLayer.runingSpineNode2:removeFromParent()
                        testLayer.runingSpineNode2 = nil
                    end
                end
            end

        -------------------------------------------------
        -- meshes
        elseif exampleDefine.id == 'meshes' then
            cellsArray = {
                ui.tButton({n = RES_DICT.EXT_BTN_N, s = RES_DICT.EXT_BTN_S, nLabel = {fnt = FONT.D19, text = '网格开关'}}),
            }

            cellsArray[1]:setOnCheckScriptHandler(function(sender, bChecked)
                if testLayer.runingSpineNode.setDebugMeshesEnabled then
                    testLayer.runingSpineNode:setDebugMeshesEnabled(bChecked)
                else
                    app.uiMgr:ShowInformationTips('!! Spine.setDebugMeshesEnabled not support !!')
                end
            end)

        -------------------------------------------------
        -- 310000
        elseif exampleDefine.id == '310000' then
            local skinTypeMap = {
                body  = {name = '身体', names = { '1body',  '2body',  '3body',  '4body',  '5body'  } },
                ear   = {name = '耳朵', names = { '1ear',   '2ear',   '3ear',   '4ear',   '5ear'   } },
                eye   = {name = '眼镜', names = { '1eye',   '2eye',   '3eye',   '4eye',   '5eye'   } },
                head  = {name = '头部', names = { '1head',  '2head',  '3head',  '4head',  '5head'  } },
                weiba = {name = '尾巴', names = { '1weiba', '2weiba', '3weiba', '4weiba', '5weiba' } },
            }

            -- default
            local applySkinMap = {}
            for type, define in pairs(skinTypeMap) do
                applySkinMap[type] = define.names[1]
            end

            local partBtnArray = {}
            for type, define in pairs(skinTypeMap) do
                table.insert(cellsArray, ui.label({fnt = FONT.D1, color = '#734441', text = define.name}))
                for _, name in ipairs(define.names) do
                    local partBtn = ui.tButton({n = RES_DICT.EXT_BTN_N, s = RES_DICT.EXT_BTN_S, nLabel = {fnt = FONT.D14, text = name}})
                    partBtn.partName = name
                    partBtn.partType = type
                    table.insert(partBtnArray, partBtn)
                    table.insert(cellsArray, partBtn)
                end
            end

            for _, partBtn in ipairs(partBtnArray) do
                ui.bindClick(partBtn, function(sender)
                    local skinName = sender.partName
                    local skinType = sender.partType
                    applySkinMap[skinType] = skinName
                    
                    local skinList  = table.values(applySkinMap)
                    local mixedName = table.concat(skinList, ',')
                    if testLayer.runingSpineNode.setMixedSkins then
                        testLayer.runingSpineNode:setMixedSkins(mixedName, skinList)
                        testLayer.runingSpineNode:setToSetupPose()
                        -- testLayer.runingSpineNode:setBonesToSetupPose()
                        -- testLayer.runingSpineNode:setSlotsToSetupPose()
                    else
                        app.uiMgr:ShowInformationTips('!! Spine.setMixedSkins not support !!')
                    end
        
                    for _, tButton in ipairs(partBtnArray) do
                        local isSelected = false
                        for _, name in pairs(applySkinMap) do
                            if tButton.partName == name then
                                isSelected = true
                                break
                            end
                        end
                        tButton:setChecked(isSelected)
                    end
                end, false)
            end

            reloadCallback = function()
                partBtnArray[1]:toOnClickScriptHandler()
            end

        end
        
        -------------------------------------------------
        for _, rowCell in ipairs(cellsArray) do
            local rowNode = ui.layer({size = cc.size(extraInfoListW, rowCell:getContentSize().height)})
            rowNode:addList(rowCell):alignTo(nil, ui.cc)
            extraInfoList:insertNodeAtLast(ui.layer({size = cc.size(extraInfoListW, 10)}))
            extraInfoList:insertNodeAtLast(rowNode)
        end
        extraInfoList:reloadData()

        if reloadCallback then
            reloadCallback()
        end
    end

    -------------------------------------------------
    -- left info
    local infoTableSize = cc.size(200, display.cy - 40)
    local leftInfoGroup = testLayer:addList({
        ui.label({fnt = FONT.D20, fontSize = 30, text = '测试列表', hAlign = display.TAC, w = infoTableSize.width}),
        ui.tableView({size = infoTableSize, csizeH = 40, dir = display.SDIR_V, bgColor = '#FFFFFF99'}),
        ui.label({fnt = FONT.D20, fontSize = 30, text = '动画列表', hAlign = display.TAC, w = infoTableSize.width}),
        ui.tableView({size = infoTableSize, csizeH = 40, dir = display.SDIR_V, bgColor = '#FFFFFF99'}),
    })
    ui.flowLayout(cc.p(display.SAFE_L, display.cy), leftInfoGroup, {type = ui.flowV, ap = ui.lc})


    local exampleTableView = leftInfoGroup[2]
    local animateTableView = leftInfoGroup[4]

    exampleTableView:setCellCreateHandler(function(cellParent)
        local view = cellParent
        local size = cellParent:getContentSize()
        local area = ui.colorBtn({size = size, color = cc.r4b(10)}):updateLabel({fnt = FONT.D1, color = '#734441', text ='----'})
        view:addList(area):alignTo(nil, ui.cc)
        return {
            view = view,
            area = area,
        }
    end)
    animateTableView:setCellCreateHandler(exampleTableView:getCellCreateHandler())

    exampleTableView:setCellUpdateHandler(function(cellIndex, cellViewData)
        local exampleDefine = checktable(spineExampleDefines[cellIndex])
        cellViewData.area:updateLabel({text = tostring(exampleDefine.name)})
        cellViewData.area:setTag(cellIndex)
        cellViewData.view:setTag(cellIndex)
    end)

    animateTableView:setCellUpdateHandler(function(cellIndex, cellViewData)
        local animateName = tostring(testLayer.runingAniList[cellIndex])
        cellViewData.area:updateLabel({text = animateName})
        cellViewData.area:setTag(cellIndex)
        cellViewData.view:setTag(cellIndex)
    end)

    exampleTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.area, function(sender)
            if testLayer.runingSpineNode then
                testLayer.runingSpineNode:removeFromParent()
                testLayer.runingSpineNode = nil
            end
            if testLayer.cleanCallback then
                testLayer.cleanCallback()
                testLayer.cleanCallback = nil
            end

            local exampleDefine = checktable(spineExampleDefines[sender:getTag()])
            if utils.isExistent(_spn(exampleDefine.path).atlas) then
                testLayer.runingSpineNode = ui.spine({path = _spn(exampleDefine.path), init = exampleDefine.init, scale = exampleDefine.scale})
                testLayer.runingSpineNode:setPositionX(display.cx + (exampleDefine.offset and exampleDefine.offset.x or 0))
                testLayer.runingSpineNode:setPositionY(display.cy + (exampleDefine.offset and exampleDefine.offset.y or 0))
                testLayer:add(testLayer.runingSpineNode)
    
                local animationsDataMap = testLayer.runingSpineNode:getAnimationsData()
                testLayer.runingAniList = table.keys(animationsDataMap)
                table.sort(testLayer.runingAniList, function(a, b) return a < b end)
                animateTableView:resetCellCount(#testLayer.runingAniList)
    
                refreshExtraInfoList(exampleDefine)
            else
                app.uiMgr:ShowInformationTips(string.fmt('path [%1] not find !!', exampleDefine.path))
            end
            
        end)
    end)

    animateTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.area, function(sender)
            if testLayer.runingSpineNode then
                local animateName = tostring(testLayer.runingAniList[sender:getTag()])
                testLayer.runingSpineNode:setAnimation(0, animateName, true)
                testLayer.runingSpineNode:setToSetupPose()
            end
        end)
    end)

    exampleTableView:resetCellCount(#spineExampleDefines)


    -------------------------------------------------
    local descrView = self:addScrollDescrView_(testLayer)
    descrView:setLocalZOrder(1)
    descrView:setVisible(false)

    -- debug info
    local debugInfoGroup = testLayer:addList({
        ui.tButton({n = RES_DICT.TAB_BTN_N, s = RES_DICT.TAB_BTN_S, nLabel = {fnt = FONT.D14, text = '显示骨骼'}, zorder = 1}),
        ui.tButton({n = RES_DICT.TAB_BTN_N, s = RES_DICT.TAB_BTN_S, nLabel = {fnt = FONT.D14, text = '显示凹槽'}, zorder = 1}),
        ui.tButton({n = RES_DICT.TAB_BTN_N, s = RES_DICT.TAB_BTN_S, nLabel = {fnt = FONT.D14, text = '显示详情'}, zorder = 1}),
    })
    ui.flowLayout(cc.p(display.cx, 30), debugInfoGroup, {type = ui.flowH, ap = ui.cb, gapW = 80})

    debugInfoGroup[1]:setOnClickScriptHandler(function(sender)
        if testLayer.runingSpineNode then
            testLayer.runingSpineNode:setDebugBonesEnabled(not testLayer.runingSpineNode:getDebugBonesEnabled())
        end
    end)
    debugInfoGroup[2]:setOnClickScriptHandler(function(sender)
        if testLayer.runingSpineNode then
            testLayer.runingSpineNode:setDebugSlotsEnabled(not testLayer.runingSpineNode:getDebugSlotsEnabled())
        end
    end)
    debugInfoGroup[3]:setOnClickScriptHandler(function(sender)
        if descrView:isVisible() then
            descrView:setVisible(false)
        else
            descrView:setVisible(true)

            if testLayer.runingSpineNode then
                if testLayer.runingSpineNode then
                    local descrArray = {}
                    local spineNode  = testLayer.runingSpineNode
                    
                    table.insert(descrArray, tableToString(spineNode:getSkeletonData(), '--== getSkeletonData ==--', 10))
        
                    table.insert(descrArray, '@@@@@@@@@@ @@@@@@@@@@ slots @@@@@@@@@@ @@@@@@@@@@')
                    for slotIndex, slotName in ipairs(spineNode:getSkeletonData().slots) do
                        table.insert(descrArray, tableToString(spineNode:findSlot(slotName), '[slot_' .. slotIndex .. '] ' .. slotName, 10))
                    end

                    table.insert(descrArray, '@@@@@@@@@@ @@@@@@@@@@ bones @@@@@@@@@@ @@@@@@@@@@')
                    for boneIndex, boneName in ipairs(spineNode:getSkeletonData().bones) do
                        table.insert(descrArray, tableToString(spineNode:findBone(boneName), '[bone_' .. boneIndex .. '] ' .. boneName, 10))
                    end

                    table.insert(descrArray, '@@@@@@@@@@ @@@@@@@@@@ skins @@@@@@@@@@ @@@@@@@@@@')
                    for skinIndex, skinName in ipairs(spineNode:getSkeletonData().skins) do
                        table.insert(descrArray, tableToString(spineNode:findSkin(skinName), '[skin_' .. skinIndex .. '] ' .. skinName, 10))
                    end
                    
                    table.insert(descrArray, '@@@@@@@@@@ @@@@@@@@@@ attachments @@@@@@@@@@ @@@@@@@@@@')
                    for slotName, attachmentList in pairs(spineNode:findSkin('default').attachments) do
                        if #attachmentList > 1 then
                            for attachmenIndex, attachmentData in ipairs(attachmentList) do
                                table.insert(descrArray, tableToString(spineNode:getAttachment(slotName, attachmentData.attachment), '[attachment] ' .. slotName .. ' | ' .. attachmentData.attachment))
                            end
                        end
                    end

                    table.insert(descrArray, '@@@@@@@@@@ @@@@@@@@@@ animations @@@@@@@@@@ @@@@@@@@@@')
                    table.insert(descrArray, tableToString(spineNode:getAnimationsData(), 'animations'))
                    
                    -- logs('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ error test')
                    -- logt(spineNode:findSlot(''), 'findSlot > empty')
                    -- logt(spineNode:findBone(''), 'findBone > empty')
                    -- logt(spineNode:findSkin(''), 'findSkin > empty')
                    -- logt(spineNode:findSlot('kai'), 'findSlot > kai')
                    -- logt(spineNode:findBone('kai'), 'findBone > kai')
                    -- logt(spineNode:findSkin('kai'), 'findSkin > kai')
                    -- logt(spineNode:getAttachment('kai', 'shi'), 'getAttachment > kai , shi')
                    -- logt(spineNode:getAttachment('left-hand-item', 'shi'), 'getAttachment > left-hand-item , shi')
                    -- logt(spineNode:setAttachment('kai', 'shi'), 'setAttachment > kai , shi')
                    -- logt(spineNode:setAttachment('left-hand-item', 'shi'), 'setAttachment > left-hand-item , shi')
                    -- logt(spineNode:setMixedSkins('kai', {}), 'setMixedSkins > kai, {}')  -- true ???
                    -- logt(spineNode:setMixedSkins('kai', {'a','b'}), 'setMixedSkins > kai, {a,b}')
                    descrView:updateDescr(table.concat(descrArray, '\n'))
                else
                    descrView:updateDescr('!! spine.getSkeletonData not support !!')
                end
            else
                descrView:updateDescr('runingSpineNode is nil')
            end
        end

    end)


    -- close button
    self:addCloseButton_(testLayer)
end


-------------------------------------------------------------------------------
-- shader
-------------------------------------------------------------------------------
function DebugScene:testShader_()
    local testLayer = display.newLayer()
    app.uiMgr:GetCurrentScene():AddDialog(testLayer)

    local imageLayer = ui.layer()
    testLayer:add(imageLayer)
    
    local defaultVertex   = io.readfile(cc.FileUtils:getInstance():fullPathForFilename('res_sub/shader/default.vsh'))
    local defaultFragment = io.readfile(cc.FileUtils:getInstance():fullPathForFilename('res_sub/shader/default.fsh'))

    local RES_DICT = {
        TAB_BTN_N = _res('ui/home/market/market_bg_choice_type_default.png'),
        TAB_BTN_S = _res('ui/home/market/market_bg_choice_type_selected.png'),
        EXT_BTN_N = _res('ui/common/tujian_btn_selection_unused.png'),
        EXT_BTN_S = _res('ui/common/tujian_btn_selection_choosed.png'),
        COMBOX_BG = _res('ui/common/common_bg_a.png'),
        SLIDER_S  = _res('ui/home/infor/setup_volume_btn.png'),
        SLIDER_P  = _res('ui/home/infor/setup_bar_exp_1.png'),
        SLIDER_BG = _res('ui/home/infor/setup_bar_exp_2.png'),
        SRC_IMG_1 = _res('update/force_update.png'),
        SRC_IMG_2 = _res('update/mifan.png'),
    }

    local shaderExampleDefines = {
        {id = 'default',    name = '默认' },
        {id = 'test',       name = '测试',      fshPath = 'res_sub/shader/test.fsh'},
        {id = 'gray',       name = '颜色：灰色', fshPath = 'res_sub/shader/gray.fsh'},
        {id = 'sepia',      name = '颜色：老旧', fshPath = 'res_sub/shader/color-sepia.fsh'},
        {id = 'negative',   name = '颜色：负色', fshPath = 'res_sub/shader/color-negative.fsh'},
        {id = 'bloom',      name = '颜色：曝光', fshPath = 'res_sub/shader/color-bloom.fsh'},
        {id = 'contrast',   name = '颜色：对比', fshPath = 'res_sub/shader/color-contrast.fsh'},
        {id = 'saturation', name = '颜色：饱和', fshPath = 'res_sub/shader/color-saturation.fsh'},
        {id = 'blackWhite', name = '颜色：黑白', fshPath = 'res_sub/shader/color-blackWhite.fsh'},
        {id = 'edge',       name = '颜色：边缘', fshPath = 'res_sub/shader/color-edgeDetection.fsh'},
        {id = 'emboss',     name = '颜色：浮雕', fshPath = 'res_sub/shader/color-emboss.fsh'},
        {id = 'celSha',     name = '颜色：色差', fshPath = 'res_sub/shader/color-celShading.fsh'},
        {id = 'horizontal', name = '扫描线',    fshPath = 'res_sub/shader/horizontalColor.fsh'},
        {id = 'blur',       name = '模糊',      fshPath = 'res_sub/shader/blur.fsh'},
        {id = 'outline',    name = '描边',      fshPath = 'res_sub/shader/outline.fsh'},
        {id = 'noisy',      name = '噪点',      fshPath = 'res_sub/shader/noisy.fsh'},
        {id = 'ripple',     name = '水波纹',    fshPath = 'res_sub/shader/ripple.fsh'},
        {id = 'wring',      name = '歪曲',      fshPath = 'res_sub/shader/wring.fsh'},
        {id = 'grass',      name = '扭动草',    fshPath = 'res_sub/shader/grass.fsh'},
    }

    local filterExampleDefines = {
        {id = 'default',       name = '默认' },
        {id = 'gray',          name = '灰色',       class = GrayFilter},
        {id = 'rgb',           name = '染色',       class = RGBFilter},
        {id = 'hue',           name = '色度',       class = HueFilter},
        {id = 'brightness',    name = '亮度',       class = BrightnessFilter},  -- 变亮有bug，透明也会变白
        {id = 'saturation',    name = '饱和度',      class = SaturationFilter},
        {id = 'contrast',      name = '对比度',      class = ContrastFilter},  -- 变暗有bug，透明也会变暗
        {id = 'exposure',      name = '曝光',       class = ExposureFilter},
        {id = 'gamma',         name = '伽马',       class = GammaFilter},
        {id = 'haze',          name = '朦胧',       class = HazeFilter},
        {id = 'sepia',         name = '深褐色',     class = SepiaFilter},      -- 没效果？
        {id = 'gaussianVBlur', name = '高斯模糊-纵', class = GaussianVBlurFilter},
        {id = 'gaussianHBlur', name = '高斯模糊-横', class = GaussianHBlurFilter},
        {id = 'zoomBlur',      name = '放大模糊',    class = ZoomBlurFilter},
        {id = 'motionBlur',    name = '运动模糊',    class = MotionBlurFilter},
        {id = 'sharpen',       name = '尖锐',       class = SharpenFilter},
    }

    -------------------------------------------------
    -- right info

    local infoTableSize = cc.size(200, display.height - 40 - 100)
    local rightInfoGroup = testLayer:addList({
        ui.label({fnt = FONT.D20, fontSize = 30, text = '额外控制', hAlign = display.TAC, w = infoTableSize.width}),
        ui.listView({size = infoTableSize, dir = display.SDIR_V, bgColor = '#FFFFFF99'}),
    })
    ui.flowLayout(cc.p(display.SAFE_R, display.height), rightInfoGroup, {type = ui.flowV, ap = ui.rb})

    
    local refreshExampleSource = function()
        if testLayer.runingImageNode then
            testLayer.runingImageNode:removeFromParent()
            testLayer.runingImageNode = nil
        end
        if testLayer.cleanCallback then
            testLayer.cleanCallback()
            testLayer.cleanCallback = nil
        end
        if testLayer.sourceImgPath then
            -- testLayer.runingImageNode = ui.image({img = testLayer.sourceImgPath, p = display.center})
            testLayer.runingImageNode = FilteredSpriteWithOne:create(testLayer.sourceImgPath)
            testLayer.runingImageNode:setPosition(display.center)
            imageLayer:add(testLayer.runingImageNode)
        end
    end

    local refreshExampleResault = function()
        if testLayer.runingImageNode then

            -- reset filter
            local glProgram      = cc.GLProgram:createWithByteArrays(defaultVertex, defaultFragment)
            local glProgramState = cc.GLProgramState:getOrCreateWithGLProgram(glProgram)
            testLayer.runingImageNode:setGLProgram(glProgram)
            testLayer.runingImageNode:setGLProgramState(glProgramState)
            -- clear filter
            testLayer.runingImageNode:clearFilter()

            -- to shader
            if testLayer.shaderParamsMap and next(testLayer.shaderParamsMap) ~= nil then
                glProgram      = testLayer.shaderParamsMap.glProgram
                glProgramState = testLayer.shaderParamsMap.glProgramState
                testLayer.runingImageNode:setGLProgram(glProgram)
                testLayer.runingImageNode:setGLProgramState(glProgramState)
            end

            -- to filter
            if testLayer.filterParamsMap and next(testLayer.filterParamsMap) ~= nil then
                testLayer.filterParamsMap.filterObj = testLayer.filterParamsMap.filterClass:create()
                if testLayer.filterParamsMap.paramList then
                    testLayer.filterParamsMap.filterObj:setParameter(unpack(testLayer.filterParamsMap.paramList))
                end
                testLayer.runingImageNode:setFilter(testLayer.filterParamsMap.filterObj)
            end

        end
    end


    local refreshExtraInfoList = function(exampleDefine, exampleType)
        local cellsArray     = {}
        local extraInfoList  = rightInfoGroup[2]
        local extraInfoListW = extraInfoList:getContentSize().width
        local reloadCallback = nil
        extraInfoList:removeAllNodes()

        local isShaderExample     = exampleType == 'shader'
        local isFilterExample     = exampleType == 'filter'
        local propertyDefines     = {}
        testLayer.filterParamsMap = {}
        testLayer.shaderParamsMap = {}
        
        if isShaderExample then
            local shaderVertex   = defaultVertex
            local shaderFragment = defaultFragment
            if exampleDefine.fshPath then
                shaderFragment = io.readfile(cc.FileUtils:getInstance():fullPathForFilename(exampleDefine.fshPath))
            end
            local textureSize                        = testLayer.runingImageNode:getTexture():getContentSizeInPixels()
            testLayer.shaderParamsMap.glProgram      = cc.GLProgram:createWithByteArrays(shaderVertex, shaderFragment)
            testLayer.shaderParamsMap.glProgramState = cc.GLProgramState:getOrCreateWithGLProgram(testLayer.shaderParamsMap.glProgram)
            testLayer.shaderParamsMap.glProgramState:setUniformVec2('resolution', cc.p(textureSize.width, textureSize.height))
            testLayer.shaderParamsMap.glProgramState:setUniformVec2('center', cc.p(display.cx, display.cy))

            -------------------------------------------------
            -- blur
            if exampleDefine.id == 'blur' then
                propertyDefines = {
                    {type = 'slider', name = '半径', key = 'blurRadius', min = 0, max = 80, init = 10, rate = 1},
                    {type = 'slider', name = '采样', key = 'sampleNum',  min = 0, max = 8,  init = 4,  rate = 1},
                }

            -------------------------------------------------
            -- bloom | emboss
            elseif exampleDefine.id == 'bloom' or exampleDefine.id == 'emboss' then
                propertyDefines = {
                    {type = 'slider', name = '程度', key = 'intensity', min = 0, max = 200, init = 0.35, rate = 0.01},
                }

            -------------------------------------------------
            -- outline
            elseif exampleDefine.id == 'outline' then
                local outlineSize  = cc.p(0.02, 0.02)
                local outlineColor = cc.vec3(1, 1, 1)
                propertyDefines = {
                    {type = 'slider', name = '范围-X', key = 'outlineSize',  subKey = 'x', min = 0, max = 100, init = outlineSize,  rate = 0.001},
                    {type = 'slider', name = '范围-Y', key = 'outlineSize',  subKey = 'y', min = 0, max = 100, init = outlineSize,  rate = 0.001},
                    {type = 'slider', name = '颜色-R', key = 'outlineColor', subKey = 'x', min = 0, max = 100, init = outlineColor, rate = 0.01},
                    {type = 'slider', name = '颜色-G', key = 'outlineColor', subKey = 'y', min = 0, max = 100, init = outlineColor, rate = 0.01},
                    {type = 'slider', name = '颜色-B', key = 'outlineColor', subKey = 'z', min = 0, max = 100, init = outlineColor, rate = 0.01},
                }

                reloadCallback = function()
                    testLayer.shaderParamsMap.glProgramState:setUniformVec3("foregroundColor", cc.vec3(1,1,1))
                end

            -------------------------------------------------
            -- noisy
            elseif exampleDefine.id == 'noisy' then
                propertyDefines = {
                    {type = 'slider', name = '半径', key = 'intensity', min = 0, max = 100, init = 0.05, rate = 0.01},
                }

            -------------------------------------------------
            -- ripple | grass | wring
            elseif exampleDefine.id == 'ripple' or exampleDefine.id == 'grass' or exampleDefine.id == 'wring' then
                propertyDefines = {
                    {type = 'slider', name = '流动', key = 'u_time', min = 0, max = 100, init = 0.1, rate = 0.1},
                }

            -------------------------------------------------
            -- test
            elseif exampleDefine.id == 'test' then
                propertyDefines = {
                    {type = 'slider', name = '半径', key = 'intensity', min = 0, max = 100, init = 0.5, rate = 0.01},
                }

            end
        end

        if isFilterExample then
            if exampleDefine.class then
                testLayer.filterParamsMap.filterClass = exampleDefine.class
            end

            -------------------------------------------------
            -- colors
            if exampleDefine.id == 'gray' then
                testLayer.filterParamsMap.paramList = { cc.c4b(0.299, 0.587, 0.114, 0) }
                propertyDefines = {
                    {type = 'slider', name = '颜色-R', subKey = 'r', min = 0, max = 1000,  index = 1, rate = 0.001},
                    {type = 'slider', name = '颜色-G', subKey = 'g', min = 0, max = 1000,  index = 1, rate = 0.001},
                    {type = 'slider', name = '颜色-B', subKey = 'b', min = 0, max = 1000,  index = 1, rate = 0.001},
                    {type = 'slider', name = '颜色-A', subKey = 'a', min = 0, max = 1000,  index = 1, rate = 0.001},
                }
            elseif exampleDefine.id == 'rgb' then
                testLayer.filterParamsMap.paramList = { 0.5, 0.5, 0.5 }
                propertyDefines = {
                    {type = 'slider', name = '颜色-R', min = 0, max = 100, index = 1, rate = 0.01},
                    {type = 'slider', name = '颜色-G', min = 0, max = 100, index = 2, rate = 0.01},
                    {type = 'slider', name = '颜色-B', min = 0, max = 100, index = 3, rate = 0.01},
                }
            elseif exampleDefine.id == 'hue' then
                testLayer.filterParamsMap.paramList = { 50 }
                propertyDefines = {
                    {type = 'slider', name = '偏移', min = -180, max = 180, index = 1, rate = 1},
                }
            elseif exampleDefine.id == 'brightness' then
                testLayer.filterParamsMap.paramList = { -0.5 }
                propertyDefines = {
                    {type = 'slider', name = '偏移', min = -100, max = 100, index = 1, rate = 0.01},  -- 变亮有bug，透明也会变白
                }
            elseif exampleDefine.id == 'saturation' then
                testLayer.filterParamsMap.paramList = { 2 }
                propertyDefines = {
                    {type = 'slider', name = '偏移', min = 0, max = 200, index = 1, rate = 0.01},
                }
            elseif exampleDefine.id == 'contrast' then
                testLayer.filterParamsMap.paramList = { 2 }
                propertyDefines = {
                    {type = 'slider', name = '偏移', min = 0, max = 400, index = 1, rate = 0.01},  -- 变暗有bug，透明也会变暗
                }
            elseif exampleDefine.id == 'exposure' then
                testLayer.filterParamsMap.paramList = { 1 }
                propertyDefines = {
                    {type = 'slider', name = '偏移', min = -10, max = 10, index = 1, rate = 0.1},
                }
            elseif exampleDefine.id == 'gamma' then
                testLayer.filterParamsMap.paramList = { 3 }
                propertyDefines = {
                    {type = 'slider', name = '偏移', min = 0, max = 30, index = 1, rate = 0.1},
                }
            elseif exampleDefine.id == 'haze' then
                testLayer.filterParamsMap.paramList = { 0, 0 }
                propertyDefines = {
                    {type = 'slider', name = '距离', min = -50, max = 50, index = 1, rate = 0.01},
                    {type = 'slider', name = '倾斜', min = -50, max = 50, index = 2, rate = 0.01},
                }
            -- blurs
            elseif exampleDefine.id == 'gaussianVBlur' then
                testLayer.filterParamsMap.paramList = { 2 }
                propertyDefines = {
                    {type = 'slider', name = '像素', min = 0, max = 10, index = 1, rate = 1},
                }
            elseif exampleDefine.id == 'gaussianHBlur' then
                testLayer.filterParamsMap.paramList = { 2 }
                propertyDefines = {
                    {type = 'slider', name = '像素', min = 0, max = 10, index = 1, rate = 1},
                }
            elseif exampleDefine.id == 'zoomBlur' then
                testLayer.filterParamsMap.paramList = { 1, 1, 1 }
                propertyDefines = {
                    {type = 'slider', name = '大小',   min = 0, max = 10, index = 1, rate = 1},
                    {type = 'slider', name = '中心-X', min = 0, max = 10, index = 2, rate = 1},
                    {type = 'slider', name = '中心-Y', min = 0, max = 10, index = 3, rate = 1},
                }
            elseif exampleDefine.id == 'motionBlur' then
                testLayer.filterParamsMap.paramList = { 2, 30 }
                propertyDefines = {
                    {type = 'slider', name = '大小', min = 0, max = 10, index = 1, rate = 1},
                    {type = 'slider', name = '角度', min = 0, max = 360, index = 2, rate = 1},
                }
            -- others
            elseif exampleDefine.id == 'sharpen' then
                testLayer.filterParamsMap.paramList = { 2, 10 }
                propertyDefines = {
                    {type = 'slider', name = '锐度', min = 0, max = 10, index = 1, rate = 1},
                    {type = 'slider', name = '总数', min = 0, max = 20, index = 2, rate = 1},
                }
            end
        end

        for index, define in ipairs(propertyDefines) do
            if define.type == 'slider' then
                local slider = ui.slider({sImg = RES_DICT.SLIDER_S, pImg = RES_DICT.EXT_BTN_N, bg = RES_DICT.EXT_BTN_S})
                local label  = ui.label({fnt = FONT.D19, ap = ui.cb})
                table.insert(cellsArray, slider)
                table.insert(cellsArray, label)

                slider:setMinValue(checkint(define.min))
                slider:setMaxValue(checkint(define.max))
                slider.label  = label
                slider.define = define

                local updateSliderValueFunc = function(sender, value)
                    local sliderValue = checkint(value)
                    local propertyNum = sliderValue * checknumber(sender.define.rate)
                    sender:setNowValue(sliderValue)
                    sender.label:updateLabel({text = sender.define.name .. '：' .. propertyNum})

                    if isShaderExample and testLayer.shaderParamsMap.glProgramState then
                        if sender.define.subKey then
                            sender.define.init[sender.define.subKey] = propertyNum
                            if table.nums(sender.define.init) == 2 then
                                testLayer.shaderParamsMap.glProgramState:setUniformVec2(sender.define.key, sender.define.init)
                            elseif table.nums(sender.define.init) == 3 then
                                testLayer.shaderParamsMap.glProgramState:setUniformVec3(sender.define.key, sender.define.init)
                            end
                        else
                            testLayer.shaderParamsMap.glProgramState:setUniformFloat(sender.define.key, propertyNum)
                        end
                    end

                    if isFilterExample then
                        local paramValue = testLayer.filterParamsMap.paramList[sender.define.index]
                        if sender.define.subKey then
                            paramValue[sender.define.subKey] = propertyNum
                        else
                            testLayer.filterParamsMap.paramList[sender.define.index] = propertyNum
                        end
                        refreshExampleResault()
                    end
                end

                slider:setOnValueChangedScriptHandler(function(sender, value)
                    updateSliderValueFunc(sender, sender:getNowValue())
                end)

                if isShaderExample then
                    if define.subKey then
                        updateSliderValueFunc(slider, define.init[define.subKey] / define.rate)
                    else
                        updateSliderValueFunc(slider, define.init / define.rate)
                    end
                end

                if isFilterExample then
                    local paramValue = testLayer.filterParamsMap.paramList[define.index]
                    if define.subKey then
                        updateSliderValueFunc(slider, paramValue[define.subKey] / define.rate)
                    else
                        updateSliderValueFunc(slider, paramValue / define.rate)
                    end
                end
            end
        end
        
        -------------------------------------------------
        for _, rowCell in ipairs(cellsArray) do
            local rowNode = ui.layer({size = cc.size(extraInfoListW, rowCell:getContentSize().height)})
            rowNode:addList(rowCell):alignTo(nil, ui.cc)
            extraInfoList:insertNodeAtLast(ui.layer({size = cc.size(extraInfoListW, 10)}))
            extraInfoList:insertNodeAtLast(rowNode)
        end
        extraInfoList:reloadData()

        if reloadCallback then
            reloadCallback()
        end

        refreshExampleResault()
    end


    -------------------------------------------------
    -- left info
    local infoTableSize = cc.size(200, display.cy - 40)
    local leftInfoGroup = testLayer:addList({
        ui.label({fnt = FONT.D20, fontSize = 30, text = '测试shader', hAlign = display.TAC, w = infoTableSize.width}),
        ui.tableView({size = infoTableSize, csizeH = 40, dir = display.SDIR_V, bgColor = '#FFFFFF99'}),
        ui.label({fnt = FONT.D20, fontSize = 30, text = '测试滤镜', hAlign = display.TAC, w = infoTableSize.width}),
        ui.tableView({size = infoTableSize, csizeH = 40, dir = display.SDIR_V, bgColor = '#FFFFFF99'}),
    })
    ui.flowLayout(cc.p(display.SAFE_L, display.cy), leftInfoGroup, {type = ui.flowV, ap = ui.lc})


    local shaderExampleTableView = leftInfoGroup[2]
    shaderExampleTableView:setCellCreateHandler(function(cellParent)
        local view = cellParent
        local size = cellParent:getContentSize()
        local area = ui.colorBtn({size = size, color = cc.r4b(10)}):updateLabel({fnt = FONT.D1, color = '#734441', text ='----'})
        area.color = area:addList(ui.layer({size = size, color = '#00000033'}))
        view:addList(area):alignTo(nil, ui.cc)
        area.color:setVisible(false)
        return {
            view = view,
            area = area,
        }
    end)
    shaderExampleTableView:setCellUpdateHandler(function(cellIndex, cellViewData)
        local exampleDefine = checktable(shaderExampleDefines[cellIndex])
        cellViewData.area:updateLabel({text = tostring(exampleDefine.name)})
        cellViewData.area:setTag(cellIndex)
        cellViewData.view:setTag(cellIndex)
    end)
    shaderExampleTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.area, function(sender)
            if testLayer.oldExampleBtn then testLayer.oldExampleBtn.color:setVisible(false) end
            testLayer.oldExampleBtn = sender
            testLayer.oldExampleBtn.color:setVisible(true)
            local exampleDefine = checktable(shaderExampleDefines[sender:getTag()])
            refreshExtraInfoList(exampleDefine, 'shader')
        end)
    end)
    shaderExampleTableView:resetCellCount(#shaderExampleDefines)


    local filterExampleTableView = leftInfoGroup[4]
    filterExampleTableView:setCellCreateHandler(shaderExampleTableView:getCellCreateHandler())
    filterExampleTableView:setCellUpdateHandler(function(cellIndex, cellViewData)
        local exampleDefine = checktable(filterExampleDefines[cellIndex])
        cellViewData.area:updateLabel({text = tostring(exampleDefine.name)})
        cellViewData.area:setTag(cellIndex)
        cellViewData.view:setTag(cellIndex)
    end)
    filterExampleTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.area, function(sender)
            if testLayer.oldExampleBtn then testLayer.oldExampleBtn.color:setVisible(false) end
            testLayer.oldExampleBtn = sender
            testLayer.oldExampleBtn.color:setVisible(true)
            local exampleDefine = checktable(filterExampleDefines[sender:getTag()])
            refreshExtraInfoList(exampleDefine, 'filter')
        end)
    end)
    filterExampleTableView:resetCellCount(#filterExampleDefines)


    -------------------------------------------------
    -- debug info
    local debugInfoGroup = testLayer:addList({
        ui.tButton({n = RES_DICT.TAB_BTN_N, s = RES_DICT.TAB_BTN_S, nLabel = {fnt = FONT.D14, text = '图源1'}, tag = 1}),
        ui.tButton({n = RES_DICT.TAB_BTN_N, s = RES_DICT.TAB_BTN_S, nLabel = {fnt = FONT.D14, text = '图源2'}, tag = 2}),
    })
    ui.flowLayout(cc.p(display.cx, 30), debugInfoGroup, {type = ui.flowH, ap = ui.cb, gapW = 80})

    for i = 1, #debugInfoGroup do
        ui.bindClick(debugInfoGroup[i], function(sender)
            testLayer.sourceImgPath = RES_DICT['SRC_IMG_' .. checkint(sender:getTag())]
            if testLayer.oldSrcImgBtn then testLayer.oldSrcImgBtn:setChecked(false) end
            testLayer.oldSrcImgBtn = sender
            testLayer.oldSrcImgBtn:setChecked(true)
            refreshExampleSource()
            refreshExampleResault()
        end, false)
    end
    debugInfoGroup[1]:toOnClickScriptHandler()


    -- close button
    self:addCloseButton_(testLayer)
end


-------------------------------------------------------------------------------
-- viewLoader
-------------------------------------------------------------------------------
function DebugScene:testViewLoader_()
    local testLayer = display.newLayer()
    app.uiMgr:GetCurrentScene():AddDialog(testLayer)

    
    local ViewLoader = require('Frame.gui.ViewLoader')
    local view = ViewLoader.new('src/Game/views/activity/test.xml')
    
    if view and view:getViewData() then
        view:setPosition(display.center)
        testLayer:add(view)

        if view:getViewData().btn1 then
            -- view:getViewData().btn1:setEnabled(true)
            -- local size = view:getViewData().btn1:getContentSize()
            -- logs(tableToString(size, '===='))
            -- view:getViewData().btn1:setSelectedImage('ui/common/common_btn_orange.png')
            -- view:getViewData().btn1:setScale9Enabled(true)
            -- view:getViewData().btn1:setEnabled(false)
            view:getViewData().btn1:setOnClickScriptHandler(function(sender)
            -- display.commonUIParams(view:getViewData().btn1, {cb = function(sender)
                logs('logStr')
            end)
        end

        -- for index, view in ipairs(view:getViewData().pb:getChildren()) do
        --     print(index, view:getLocalZOrder())
        -- end

        if view:getViewData().gri then
            view:getViewData().gri:setCellInitHandler(function(cellViewData)
                display.commonUIParams(cellViewData.cbt, {cb = function(sender)
                    logs(sender:getTag())
                end})
            end)
            view:getViewData().gri:setCellUpdateHandler(function(cellIndex, cellViewData)
                cellViewData.cbt:setTag(cellIndex)
                cellViewData.lab:setString(cellIndex)
            end)
        end

        
        -- 重新写一套组件映射，可以明确组件方法，也可以统一底层。比如：统一字体，所有复杂容器类添加empty界面 等
        -- 每个控件有个获取真实大小尺寸的方法，contentSize * scale
        -- 每个 set 方法 return self，可以实现 xxx:setA():setB():setC() 的链式调用效果
        -- 每个 set 方法可以判断是否影响更新内容，如果更改了内容就动态布局一次
        --[[
            HStack, VStack
            Spacer() -- 底部添加一个 spacer ，将内容推到屏幕顶端
            .offset(x /y)
            .frame(width / height)  -- 强制指定宽高
            .padding(top / left / right / bootom)
            .edgesIgnoringSafeArea(top / left / right / bootom)

            Stack & 布局
            HStack：水平排布它的子元素的一个容器视图。
            VStack：垂直排布它的子元素的一个容器视图。
            ZStack：层叠排布它的子元素的一个容器视图。(布局方式类似绝对定位)
            Spacer：一个弹性的空白间距元素，会充满容器元素的主轴方向
            Divider：一个虚拟的分界元素 完整列表可以参考：View Layout and Presentation

            layout
            align 对齐方式（是否换行取决于父容器有没有frameSize）
            padding
            offset
            先确定内容，更新size；再遍历对齐坐标

            layout才有排列方法，设置排列方案的话？
            每个控件都有个自己的更新内容方法，更改后执行被绑定的回调
        ]]



        -- local s = CSlider:create()
        -- view:getViewData().view:addChild(s)

        -- local x = display.newImageView('ui/common/story_tranparent_bg.png', 0, 0, {scale9 =true})
        -- -- local x = display.newImageView('ui/common/common_btn_white_default.png', 0, 0, {scale9 =true})
        -- -- local x = CImageViewScale9:create(_res('ui/common/story_tranparent_bg.png'))
        -- x:initWithFile('ui/common/common_btn_white_default.png')
        -- -- x:updateDisplayedColor()
        -- -- x:updateWithBatchNode()
        -- -- x:updateDisplayedOpacity()
        -- -- x:resizableSpriteWithCapInsets()
        -- x:setContentSize(cc.size(200,200))
        -- view:getViewData().view:addChild(x)

        -- local btn = CButton:create()
        -- btn:setScale9Enabled(true)
        -- btn:setSelectedImage('ui/common/common_btn_orange.png')
        -- btn:setNormalImage('ui/common/common_btn_white_default.png')
        -- -- if not btn:getSelectedImage() then
        -- --     btn:setSelectedImage('ui/common/common_btn_white_default.png')
        -- --     btn:getSelectedImage():setScale(0.97)
        -- -- end
        -- btn:setContentSize(cc.size(200,200))
        -- btn:setPosition(200,200)
        -- -- local btn = display.newButton(200, 200, {n='ui/common/common_btn_white_default.png', s='ui/common/common_btn_orange.png', scale9a=true, size = cc.size(200,200)})
        -- view:getViewData().view:addChild(btn)
        -- btn:setOnClickScriptHandler(function(sender)
        -- -- display.commonUIParams(view:getViewData().btn1, {cb = function(sender)
        --     logs('btn')
        -- end)
        -- print(btn:getChildrenCount())
    end

    
    -- close button
    self:addCloseButton_(testLayer)
end


return DebugScene

--[[
    m
        sub(evtId : str, obj : any, cb : function)
        unsub(evtId ; str, obj : any)
        publish(evtId : str, args : tab)

    v
        getVM()
            .vm = require('.vms.xxVM')  -- new vm
        getComps()
            {...}
            
        onShow()
            .vm:bind(self)
            .vm:regUIEvts()
        onHide()
            .vm:unbind(self)
            .vm:unregUI()
        onCreate()
            .vm = getVM()
    
    vm
        onCreate()
            .m = modelMgr:GetM('xxx')  -- new m

    uiMgr:openView(vName)
        v = require('.vs.' .. vName).new()  -- new v
        v:onCreate()

    -------------------------
                        mgr              v                 vm               m
    life            openView     ->    new()
                                    onCreate()
                                        .vm       =      new()
                                                        onCreate()
                                                            .m       =     new()
                                                            .evtCfg  = {cmpName, cbName, evtType}
                                                            .dataCfg = {mName, mEvtId, compName}
                                                            -->> rx hashmap for compName
                                                            for cfg in .dataCfg
                                                                .bProps[cfg.compName] = rx.new(cfg.compName)
    show                             onShow()
                                .vm:bind(self)   ->      bind(v)
                                                            .bView = v
                                                            -->> each comps : [compName]rx.sub(comp.refresh)
                                                            for comp in v:getComps()
                                                                .compName2Comp[comp.name] = comp
                                                                rxProp = .bProps[comp.name]
                                                                table.insert(.bindSubs, rxProp:sub(function(data)
                                                                    comp:refresh(data)
                                                                end))
                                                            -- each .dataCfg >> [cfg.mName]m.sub(cfg.mEvtId, onRefreshData)
                                                            for cfg in .dataCfg
                                                                m = mMgr:get(cfg.mName)
                                                                m:sub(cfg.mEvtId, self, onRefreshData)
                                                                .name2Models[cfg.mName] = m
                                                            slef:onBind()
                                                        onBind()
                                                            .m:sub(mEvtId, self, onHandler)
                                                        onRefreshData(rawData)
                                                            -- each .dataCfg >> [compName]rx.set(rawData)
                                                            for cfg in .dataCfg
                                                                rxProp = .bProps[cfg.compName]
                                                                rxProp:set(rawData)
                                .vm:regUI()      ->      regUI()
                                                            for cfg in .evtCfg
                                                                comp   = .compName2Comp[cfg.compName]
                                                                cbFunc = sefl[cfg.cbName]
                                                                comp:onXXXHandler(handler(self, cbFunc))
    click                       comp:click()     ->      cbName()
                                                            .m:setXX()  ->  setXX()
                                                                                self:publish(mEvtId, arg1, arg2)
                                                        onHandler(arg1, arg2)
                                                            .bView:xxx()
    updateV                    .comp:refresh(data)
    getValue
]]
