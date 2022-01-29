--[[
 * author : kaishiqi
 * descpt : 测试场景
]]
local socket     = require('socket')
local GameScene  = require('Frame.GameScene')
local DebugScene = class('DebugScene', GameScene)


local function LocalAfterRequest(params)
    app.gameMgr:RemoveLoadingView()

    if string.find(params.url, 'player/checkin') or string.find(params.url, 'Activity/home') then
        funLog(Logger.DEBUG, string.format('[http:back] <<<< %s \n\t%s\n', params.url, '- It\'s toooooooooo long...\n'))
    else
        funLog(Logger.DEBUG, tableToString(params.result.data, string.format('[http:back] <<<< %s', params.url), 10))
    end
    logInfo.add(logInfo.Types.HTTP, string.fmt('<--- netBack %1 %2\n%3', 'POST', params.url, tableToString(params.result, nil, 10)))

    if params.data then
        params.result.data.requestData = {}
        params.result.data.requestData = params.data
    end

    -- dispatch result
    if checkint(params.result.errcode) == 0 then
        app:DispatchObservers(params.signalName, params.result.data)
    
    -- result error
    else
        app.uiMgr:ShowInformationTips(string.format("%s >_< ", tostring(params.result.errmsg)))
        if params.handleError then
            funLog(Logger.INFO, params.result)
            app:DispatchObservers(params.signalName, params.result)
        end
    end
end 


local function LocalPost(_, path, signalName, postDatas, handleErrorSelf, async)
    local postUrl = table.concat({'http://', Platform.ip, '/', path}, '')
    funLog(Logger.DEBUG, tableToString(postDatas or {}, string.format('[http:post] >>>> %s', postUrl), 10))

    -- erese [.fightData]
    local logData = postDatas or {}
    if logData.fightData ~= nil then
        local tempLogData               = clone(logData)
        tempLogData.fightData           = 'It\'s too long ......'
        tempLogData.skadaResult         = 'It\'s too long ......'
        tempLogData.constructorJson     = 'It\'s too long ......'
        tempLogData.playerOperateJson   = 'It\'s too long ......'
        tempLogData.loadedResourcesJson = 'It\'s too long ......'
        logData = tempLogData
    end
    logInfo.add(logInfo.Types.HTTP, string.fmt('---> request %1 %2\n%3', 'POST', postUrl, tableToString(logData)))

    -- show loadingView
    if not async then
        app.gameMgr:ShowLoadingView()
    end

    -- local post
    local postHandler = function()
        local pathWordList = string.split2(path, '/')
        local dataCallback = virtualData[string.format('%s/%s', pathWordList[1], pathWordList[2])]
        if pathWordList[3] and virtualData[string.format('%s/%s/%s', pathWordList[1], pathWordList[2], pathWordList[3])] then
            dataCallback = virtualData[string.format('%s/%s/%s', pathWordList[1], pathWordList[2], pathWordList[3])]
        end
        if dataCallback and type(dataCallback) == 'function' then
            LocalAfterRequest({
                url         = postUrl,
                data        = postDatas,
                result      = dataCallback(postDatas) or {},
                signalName  = signalName,
                handleError = handleErrorSelf,
            })
        end
    end
    scheduler.performWithDelayGlobal(function(dt)
        postHandler()
    end, 0.02)
end


local timeWarningLimit  = 0.1
local timeBreakInfoList = {}
addTimeBreakFunc = function(descr)
    table.insert(timeBreakInfoList, {
        descr  = tostring(descr),
        time   = socket.gettime(),
        memory = collectgarbage('count') / 1024,
    })
end
local dumpTimeBreakFunc = function()
    for index, info in ipairs(timeBreakInfoList) do
        local useTime = index == 1 and 0 or (info.time - timeBreakInfoList[index-1].time)
        logs(string.format('%d) %45s | %f %s | %0.2fmb', 
            index,
            info.descr,
            useTime,
            timeWarningLimit - useTime > 0 and ' ' or '*',
            info.memory
        ))
    end
    local a = timeBreakInfoList[1]
    local b = timeBreakInfoList[#timeBreakInfoList - 1]
    logs(b.time - a.time)
end


function DebugScene:ctor(...)
	local args = unpack({...})
    self.super.ctor(self, 'DebugScene')

    -- add bgImg
    local bgPath = _res(HOME_THEME_STYLE_DEFINE and HOME_THEME_STYLE_DEFINE.LOGIN_BG or 'update/update_bg.jpg')
    self.bgImg_  = display.newImageView(bgPath, 0, 0, {enable = true, cb = function(sender)
        PlayUIEffects(AUDIOS.UI.ui_click_normal.id)

        local iconPath = CommonUtils.GetGoodsIconPathById(GOLD_ID)

        local effect1 = function()
            local effectNode = require('common.AbsorbEffectNode').new({
                path     = iconPath,
                num      = 20,
                range    = 40,
                scale    = 0.2,
                beginPos = cc.p(200, 200),
                endedPos = cc.p(display.width - 100, display.height - 100)
            })
            return effectNode
        end

        local effect2 = function()
            local effectNode = require('common.TrackEffectNode').new({
                range    = 200,
                texPath  = iconPath,
                delay    = 0.05,
                lifespan = 2,
                texScale = 0.3,
            })
            effectNode:setPositionX(math.random(display.SAFE_L + 100, display.SAFE_R - 100))
            effectNode:setPositionY(math.random(100, display.height - 100))
            effectNode:runAction(cc.Sequence:create(
                cc.DelayTime:create(2),
                cc.FadeOut:create(1),
                cc.RemoveSelf:create()
            ))
            return effectNode
        end
        
        local effectNode = effect1()
        self:AddGameLayer(effectNode)
    end})
    display.commonUIParams(self.bgImg_, {ap = display.CENTER, po = display.center})
    -- self.bgImg_:setOpacity(100)
    self:AddGameLayer(self.bgImg_)
end


function DebugScene:onEnter2()
    self.bgImg_:setOpacity(100)

    local view = nil
    if app.viewLoader then
        view = app.viewLoader.new('src/Game/views/activity/test.xml')
        view:setPosition(display.center)
        self:AddGameLayer(view)
    end

    if view and view:getViewData() then
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
end
function DebugScene:onEnter()
    -- cc.Director:getInstance():setDisplayStats(true)
    utils.newrandomseed()
    require('Game.utils.CommonUtils')

    local appFacade = AppFacade.GetInstance()
    local gameMgr   = appFacade:GetManager("GameManager")
    local dataMgr   = appFacade:GetManager("DataManager")
    local httpMgr   = appFacade:GetManager("HttpManager")
    local socketMgr = appFacade:GetManager("SocketManager")
    local chatMgr   = appFacade:GetManager("ChatSocketManager")

    -- redefines vars
    NETWORK_LOCAL          = false
    Platform.ip            = '127.0.0.1'
    Platform.TCPHost       = Platform.ip
    Platform.ChatTCPHost   = Platform.ip
    Platform.TTGameTCPHost = Platform.ip
    Platform.TCPPort       = math.random(9601,9650)
    Platform.ChatTCPPort   = math.random(9651,9700)
    Platform.TTGameTCPPort = math.random(9101,9750)

    -- redefines methond
    httpMgr.Post = LocalPost
    chatMgr:setPingDelta(1000)
    socketMgr:setPingDelta(1000)

    -- redefine PacketBuffer.getRandom
    local PacketBuffer = require('cocos.framework.PacketBuffer')
    PacketBuffer.getRandom = function()
        return PacketBuffer.PRE_MASK
    end

    -- init userInfo
    gameMgr:InitialUserInfo()
    gameMgr:CheckLocalPlayer()

    -- add callback listen
    local authorObsObj = mvc.Observer.new(function(_, signal)
        local name = signal:GetName() 
        local data = signal:GetBody()
        
        -------------------------------------------------
        -- user login
        if SIGNALNAMES.Login_Callback == name then
            local serverId = 1
            local userInfo = {
                isGuest   = checkint(data.isGuest),
                userId    = checkint(data.userId),
                serverId  = serverId,
                sessionId = data.sessionId,
                playerId  = data.servers[serverId].playerId
            }
            gameMgr:UpdateAuthorInfo(userInfo)
            
            -- to checkin
            appFacade:DispatchSignal(COMMANDS.COMMAND_Checkin)
            
        -------------------------------------------------
        -- player checkin
        elseif SIGNALNAMES.Checkin_Callback == name then
            gameMgr:UpdatePlayer(data)
            gameMgr:fixLocalGuideData()
            appFacade:StartGame()
            
            -- pre-settings
            CommonUtils.SetControlGameProterty(CONTROL_GAME.CONRROL_MUSIC,   false)
            CommonUtils.SetControlGameProterty(CONTROL_GAME.GAME_MUSIC_EFFECT, not false)
            cc.UserDefault:getInstance():flush()
            
            -- connect chat
            chatMgr:Connect(Platform.ChatTCPHost, Platform.ChatTCPPort)
            
            -- begin test
            scheduler.performWithDelayGlobal(function()
                self:beginTest_()
            end, 0.01)
        end
    end)

    -- add command listen
    local AuthorCommand = require('Game.command.AuthorCommand')
    appFacade:RegistSignal(COMMANDS.COMMAND_Login, AuthorCommand)
    appFacade:RegistSignal(COMMANDS.COMMAND_Checkin, AuthorCommand)
    appFacade:RegistObserver(SIGNALNAMES.Login_Callback, authorObsObj)
    appFacade:RegistObserver(SIGNALNAMES.Checkin_Callback, authorObsObj)

    -- pre-parser confs
    local launchFunc = function()
        require('interfaces.virtualData')
        xTry(function()
            virtualData.launchLocalServer()
        end, function(msg)
            uiMgr:ShowIntroPopup({title = 'launchLocalServer', descr = msg})
            return  msg
        end)
        
        local startGameFunc = function()
            -- user login
            scheduler.performWithDelayGlobal(function(dt)
                appFacade:DispatchSignal(COMMANDS.COMMAND_Login, {uname = 'uname', password = 'upass'})
            end, 0.01)
        end

        if DYNAMIC_LOAD_MODE and DOWNLOAD_DEFINE then
            appFacade:RegistObserver(DOWNLOAD_DEFINE.RES_JSON.event, mvc.Observer.new(function(_, signal)
                local data = signal:GetBody()
                if data.isDownloaded then
                    -- start game
                    uiMgr:removeVerifyInfoPopup()
                    app.gameResMgr:setRemoteResJson(data.downloadData)
                    startGameFunc()
                else
                    -- retry download
                    uiMgr:showVerifyInfoPopup({infoText = __('重新同步资源配置文件')})
                    app.downloadMgr:addUrlTask(DOWNLOAD_DEFINE.RES_JSON.url, DOWNLOAD_DEFINE.RES_JSON.event)
                end
            end))

            uiMgr:showVerifyInfoPopup({infoText = __('正在同步资源配置文件')})
            app.downloadMgr:addUrlTask(DOWNLOAD_DEFINE.RES_JSON.url, DOWNLOAD_DEFINE.RES_JSON.event)

        else
            startGameFunc()
        end
    end
    
    -- begain launch
    local skipPreloadConf  = not false
    local skipLoginCommand = false
    if skipPreloadConf then
        self.bgImg_:setOpacity(100)
        if skipLoginCommand then
            self:beginTest_()
        else
            launchFunc()
        end
    else
        app.dataMgr:InitialDatasAsync(function(event)
            if event.event == 'progress' then
                local progress = (event.progress / 100) * 100
                print(string.format('>>>> Parse Confs %s', string.format('%.1f %%', progress)))
                self.bgImg_:setOpacity(255 - 155 * (event.progress / 100))

            elseif event.event == 'done' then
                print('>>>> Parse Confs done.')
                launchFunc()
                -- app.router:Dispatch({name = "AuthorMediator"}, {name = "AuthorTransMediator", params = {showVideo = false}})
            end
        end)
    end
end


function DebugScene:onExit()
    local appFacade = AppFacade.GetInstance()
    appFacade:UnRegsitSignal(COMMANDS.COMMAND_Login)
    appFacade:UnRegsitSignal(COMMANDS.COMMAND_Checkin)
    appFacade:UnRegistObserver(SIGNALNAMES.Login_Callback)
    appFacade:UnRegistObserver(SIGNALNAMES.Checkin_Callback)
    appFacade:UnRegistObserver(tostring(checktable(checktable(DOWNLOAD_DEFINE).RES_JSON).event))
end


function DebugScene:beginTest_()
    -- self:customConf_()


    -- disable guide
    do
        -- GuideUtils.GetDirector().Start     = function() end
        -- GuideUtils.GetDirector().RealStart = function() end
    end

    
    -- reset local conf
    do
        local COLLECT_COORDINATE = CommonUtils.GetConfigAllMess('collectCoordinate', 'plot') or {}
        COLLECT_COORDINATE["9"] = {
            id     = 9,
            name   = '水吧趣闻',
            areaId = -4,
            pos    = {460, 515},
        }
    
        -- CONF.COMMON.TRIALS_ENTRANCE:GetAll()['6'] = {
        --     id         = 6,
        --     functionId = 113,
        --     name       = '武道会',
        --     descr      = '本地改表1\\本地改表2',
        --     sequence   = 1,
        -- }
    end

    
    -- app:RegistMediator(require('Game.mediator.stores.GameStoresMediator').new({storeType = GAME_STORE_TYPE.GROCERY}))         -- 各种测试
    -- app.gameMgr:SetNewPlotWatchStatus(false)
    -- app:RegistMediator(require('Game.mediator.HomeMediator').new())                    -- 主界面
    -- app:RegistMediator(require('Game.mediator.TowerQuestHomeMediator').new())          -- 爬塔
    -- app:RegistMediator(require('Game.mediator.CardsListMediatorNew').new())            -- 卡牌列表
    -- app.anniversaryMgr:ShowReviewAnimationDialog()                                     -- 周年庆动画
    -- app.anniversary2019Mgr:ShowReviewAnimationDialog()                                 -- 2019周年庆动画
    -- app.router:Dispatch({name = "HomeMediator"}, {name = "WorldMediator"})             -- 世界地图
    -- app.router:Dispatch({name = "AvatarMediator"}, {name = "AvatarMediator"})          -- 餐厅
    -- app.router:Dispatch({name = "UnionLobbyMediator"}, {name = "UnionLobbyMediator"})  -- 工会大厅
    -- app.router:Dispatch({name = "UnionLobbyMediator"}, {name = "unionWars.UnionWarsHomeMediator"})      -- 工会战首页
    -- app.router:Dispatch({name = 'HomeMediator'}, {name = 'MapMediator', params = {currentAreaId = 1}})  -- 二级地图
    -- app.router:Dispatch({name = "HomeMediator"}, {name = "ActivityMediator" ,params = { activityId = ACTIVITY_TYPE.HONEY_BENTO}} )  -- 活动：爱心便当
    -- app.router:Dispatch({name = "HomeMediator"}, {name = "ttGame.TripleTriadGameHomeMediator", params = {backMdt = 'UnionLobbyMediator'}})  -- 打牌游戏
    -- app.router:Dispatch({name = "AuthorMediator"}, {name = "AuthorTransMediator", params = {showVideo = false}})
    -- app.router:Dispatch({name = 'HomeMediator'}, {name = 'waterBar.WaterBarHomeMediator'})              -- 水吧
    -- app.router:Dispatch({name = 'HomeMediator'}, {name = 'plotCollect.PlotCollectMediator'})            -- 剧情收集
    -- app:RetrieveMediator('AppMediator'):SendSignal(POST.FOOD_COMPARE_HOME.cmdName, {activityId = 1})    -- 新飨灵比拼
    -- app.router:Dispatch({name = 'HomeMediator'}, {name = 'championship.ChampionshipHomeMediator', params = {backMediatorName = 'BattleAssembleExportMediator'}})      -- 武道会
    app.router:Dispatch({name = 'HomeMediator'}, {name = 'anniversary20.Anniversary20HomeMediator'})      -- 周年庆2020

    -- app:RegistMediator(require('Game.mediator.anniversary19.Anniversary19StoryMeditaor').new())
    -- app:RegistMediator(require('Game.mediator.anniversary20.Anniversary20StoryMediator').new())


    -- device.showAlert('zxb', string.fmt('%1 | %2', 
    --     tostring(app.gameMgr:GetUserInfo().isOpenedAnniversary2019PV), 
    --     app.anniversary2019Mgr:IsOpenedHomePoster()
    -- ))
    -- app.anniversary2019Mgr:SetOpenedHomePoster(false)
    

    -- test [gain pupup]
    do
        -- app.uiMgr:AddDialog("common.GainPopup", {goodId = 890002})  -- goods/other.json "openType": ["12","40","49","50","55","56","57","58","999"]
    end


    -- test [new game stores]
    do
        -- app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.CARD_SKIN})
        -- app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.SEARCH_PROP, searchGoodsId = SWEEP_QUEST_ID})
        -- app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.GROCERY, subType = GAME_STORE_TYPE.UNION})
    end



    -- test live2d
    do
        -- local testSkinId = 251533
        -- local testLayer = require('Game.views.drawCards.CapsuleSkinSettlementSkinCell').new({ reward = {goodsId = testSkinId} })
        -- testLayer:setPosition(display.center)
        -- self:AddGameLayer(testLayer)

        -- local testSkinId = 250043
        -- local testLayer = require('common.CommonCardGoodsDetailView').new({ goodsId = testSkinId })
        -- testLayer:setPosition(display.center)
        -- self:AddGameLayer(testLayer)

        -- local testBtn = display.newLayer(display.SAFE_R-50, display.height-50, {color = cc.r4b(255), ap = display.RIGHT_TOP, enable = true, size = cc.size(150,100)})
        -- self:AddGameLayer(testBtn)
        -- display.commonUIParams(testBtn, {cb = function(sender)
        --     local textureCache = cc.Director:getInstance():getTextureCache()
        --     textureCache:removeUnusedTextures()
        -- end})
    end


    scheduler.performWithDelayGlobal(function()
        if app:RetrieveMediator('UnionLobbyMediator') then
            app:GetManager('SocketManager'):setPingDelta(99)
            local appMediator = app:RetrieveMediator('AppMediator')
            appMediator:GetViewComponent():initShow(0.01)
            appMediator:GetViewComponent():ChangeState('rightShow')
        end

        -- 测试：动态下载
        -- app.uiMgr:showDownloaderSubRes()
        -- app.router:Dispatch({name = 'HomeMediator'}, {name = 'ResourceDownloadMediator', params = {closeFunc = function()
        --     app.uiMgr:ShowInformationTips('All done!!')
        -- end}})
        -- app.uiMgr:showDownloadResPopup({
        --     isFuzzy = true,
        --     resDatas = {
        --         _ptl('ui/tower/path/particle/chest_floor.plist'),
        --         _spn('ui/tower/path/spine/changjing1'),
        --         _ptl('ui/tower/path/particle/chest_light.plist'),
        --         _spn('ui/tower/path/spine/changjing2'),
        --         _spn('ui/tower/path/spine/changjing3'),
        --         _ptl('ui/tower/path/particle/chest_show.plist'),
        --         _res('ui/tower/path/tower_bg_2_front.png'),
        --         _res('ui/tower/path/tower_bg_2_pillar_1.png'),
        --         _res('ui/tower/path/tower_bg_2_pillar_2.png'),
        --         _res('ui/tower/path/tower_bg_2_pillar_3.png'),
        --         _res('ui/tower/path/tower_bg_2_pillar_4.png'),
        --         _res('ui/tower/path/tower_bg_2.jpg'),
        --         _res('ui/tower/path/tower_bg_path_active.png'),
        --         _res('ui/tower/path/tower_bg_path_locked.png'),
        --         _res('ui/tower/path/tower_btn_team_add.png'),
        --         _res('ui/tower/path/tower_ico_point_bossbase.png'),
        --         _res('ui/tower/path/tower_ico_point_editable.png'),
        --         _res('ui/tower/path/tower_ico_point_finished.png'),
        --         _res('ui/tower/path/tower_ico_point_light.png'),
        --         _res('ui/tower/path/tower_ico_point_locked.png'),
        --         _res('ui/tower/path/tower_label_level_boss.png'),
        --         _res('ui/tower/path/tower_label_level_s.png'),
        --     },
        --     finishCB = function()
        --         app.uiMgr:ShowInformationTips('++++')
        --         logs('+++++')
        --     end
        -- })
        -- app.downloadMgr:addResLazyTask(_spn('ui/tower/path/spine/changjing2'), '----')
        -- scheduler.performWithDelayGlobal(function()
        --     app.downloadMgr:addResTask(_spn('ui/tower/path/spine/changjing1'), '----')
        -- end, 0.2)
        -- app.downloadMgr:addResLazyTask(_res('ui/tower/path/tower_ico_point_bossbase.png'))
        -- app.downloadMgr:addResTask(_res('ui/tower/path/tower_ico_point_editable.png'))
        -- app.downloadMgr:addResLazyTask(_res('ui/tower/path/tower_ico_point_finished.png'))
        -- app.downloadMgr:addResTask(_res('ui/tower/path/tower_ico_point_light.png'))
    end, 0.5)
end


function DebugScene:customConf_()
    ExcelUtils.RefreshConfCache(
        -- {json = 'plot/collectCoordinate', excel = '/Users/kaishiqi/Downloads/p2_food/功能/剧情/新剧情/新主线收录坐标表.xlsx', export = true},
        -- {json = 'plot/storyReward',       excel = '/Users/kaishiqi/Downloads/p2_food/功能/剧情/新剧情/关卡剧情关联表.xlsx', export = true},
        -- {json = 'plot/story0',            excel = '/Users/kaishiqi/Downloads/p2_food/功能/剧情/新剧情/新主线_0章.xlsx', export = true},
        -- {json = 'quest/questStory',       excel = '/Users/kaishiqi/Downloads/p2_food/功能/剧情/主线剧情文案2.xlsx', export = true},

        -- {json = 'newSummerActivity/mainStoryCollection',   excel = '/Users/kaishiqi/Downloads/19夏活剧情收录表.xlsx', export = true},
        -- {json = 'newSummerActivity/branchStoryCollection', excel = '/Users/kaishiqi/Downloads/19夏活剧情收录表.xlsx', export = true},

        -- {json = 'restaurant/avatar',          excel = '/Users/kaishiqi/Downloads/p2_food/功能/餐厅动态avatar/餐厅avatar信息表.xlsx', export = true},
        -- {json = 'restaurant/avatarLocation',  excel = '/Users/kaishiqi/Downloads/p2_food/功能/餐厅动态avatar/餐厅avatar位置表.xlsx', export = true},
        -- {json = 'restaurant/avatarAnimation', excel = '/Users/kaishiqi/Downloads/p2_food/功能/餐厅动态avatar/餐厅avatar动画表.xlsx', export = true},
        {json = 'module'}
    )
end


return DebugScene
