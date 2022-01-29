local GameScene = require( 'Frame.GameScene' )
local DebugScene = class('DebugScene', GameScene)


local PTM_RATIO = 32.0

local VoiceType = {
    RealTime    = 0,
    Messages    = 1,
}

local StateType        = {
    State_JoinRoom     = 'joinRoom',
    State_RoomStatus   = 'roomStatus',
    State_MemberVoice  = 'memberVoice',
    State_Upload       = 'uploadFile', State_Download     = 'downloadFile', State_ApplyMessage = 'applyMessage',
}

local CodeType                        = {
    GV_ON_JOINROOM_SUCC               = 1,
    GV_ON_JOINROOM_TIMEOUT            = 2,
    GV_ON_JOINROOM_SVR_ERR            = 3,
    GV_ON_JOINROOM_UNKNOWN            = 4,
    GV_ON_NET_ERR                     = 5,
    GV_ON_QUITROOM_SUCC               = 6,
    GV_ON_MESSAGE_KEY_APPLIED_SUCC    = 7,
    GV_ON_MESSAGE_KEY_APPLIED_TIMEOUT = 8,
    GV_ON_MESSAGE_KEY_APPLIED_SVR_ERR = 9,
    GV_ON_MESSAGE_KEY_APPLIED_UNKNOWN = 10,
    GV_ON_UPLOAD_RECORD_DONE          = 11,
    GV_ON_UPLOAD_RECORD_ERROR         = 12,
    GV_ON_DOWNLOAD_RECORD_DONE        = 13,
    GV_ON_DOWNLOAD_RECORD_ERROR       = 14,
    GV_ON_PLAYFILE_DONE               = 18,
    GV_ON_ROOM_OFFLINE                = 19,
    GV_ON_UNKNOWN                     = 20,
}




local configs = {['130001'] = {collisionWidth = 190, collisionHeight = 36,otherGoods = 0,appendGoodsNo = 0,positions = {}},
                    ['130002'] = {collisionWidth = 225, collisionHeight = 206,otherGoods = 1,appendGoodsNo = 2,positions = {{x = 75,y = 65},{x = 58,y = 156}},oddId = 'tableware_1'},
                    ['130003'] = {collisionWidth = 190, collisionHeight = 36,otherGoods = 1,appendGoodsNo = 1,positions = {{x = 51,y = 33}},oddId = 'tableware_1'}
                    }



function DebugScene:ctor( ... )
	local args = unpack({...})
	self.super.ctor(self,'views.DebugScene')

	require( "Frame.init" )

    -- local filePath = cc.FileUtils:getInstance():fullPathForFilename("interfaces/" .. 'Player/checkin.json')
    -- local content = io.readfile(filePath)
    -- local jdata = json.decode(content)

    local gameMgr = AppFacade.GetInstance():GetManager('GameManager')

    gameMgr:InitialUserInfo()
    -- gameMgr:UpdatePlayer(jdata.data)
    -- local ttest = {['12']=  'work', ['32'] = 'here', ['3'] = 'ren'}
    -- for name,val in orderedPairs(ttest) do
        -- print('val')
    -- end

    -- local sqlite3 = require('lsqlite3')
    -- local db = sqlite3.open(cc.FileUtils:getInstance():fullPathForFilename('res/Qmsg.db'))
    -- dump(db)

    require('Game.utils.CommonUtils')
    -- local id = ChatUtils.InertChatMessage({sendPlayerId = 1, sendPlayerName = 'work', receivePlayerId = 3, receivePlayerName = 'here',
                                -- content = 'this is test', sendTime = os.time(), msgType = 1})
--[[
local id = ChatUtils.InertChatMessage({sendPlayerId = 1, sendPlayerName = 'work', receivePlayerId = 3, receivePlayerName = 'here',
                                content = 'this is test', sendTime = os.time(), msgType = 1})
local id = ChatUtils.InertChatMessage({sendPlayerId = 3, sendPlayerName = 'work', receivePlayerId = 2, receivePlayerName = 'here',
                                content = 'this is test', sendTime = os.time(), msgType = 1})
local id = ChatUtils.InertChatMessage({sendPlayerId = 3, sendPlayerName = 'work', receivePlayerId = 1, receivePlayerName = 'here',
                                content = 'this is test', sendTime = os.time(), msgType = 1})
                                --]]

                                -- dump(ChatUtils.GetChatGroups())
    -- print('-------------xx--------', id)
    -- dump(ChatUtils.GetChatMessages(1,3))

    -- ChatUtils.DeleteChateMessage(2)
    print('--------------------------')
    print('----------------------')
    if device.platform == 'ipad' then
        local function testVideo()
            local videoPlayer = ccexp.VideoPlayer:create()
            videoPlayer:setPosition(display.center)
            videoPlayer:setAnchorPoint(cc.p(0.5, 0.5))
            videoPlayer:setContentSize(display.size)
            -- videoPlayer:addEventListener(onVideoEventCallback)
            self:addChild(videoPlayer)
            local videoFullPath = cc.FileUtils:getInstance():fullPathForFilename("res/piantou.mp4")
            videoPlayer:setFileName(videoFullPath)
            videoPlayer:play()
        end
        -- FTUtils:cancelLocalNotification(111)
        -- FTUtils:pushLocalNotification(json.encode({
        -- id = "111", message = '这是一个测试',delayMs = 6000, isRepeat=0
        -- }))
        local function testVoice()
            local stage = VoiceNode:create(display.size,"1564137035", "3f8719414f1dedc6d1e8ba5892f4927a",
            CCNative:getOpenUDID(),VoiceType.RealTime)

            print('----------------------------xxx----------')
            stage:setBackgroundColor(cc.c4b(100,100,100,190))
            stage:setPosition(cc.p(display.cx,display.cy))
            stage:setLocalZOrder(400)
            self:addChild(stage)
            stage:registScriptHandler(function ( evt )
                dump(evt)
                local state = evt.state
                local code = checkint(evt.code)
                if state and state == StateType.State_JoinRoom then
                    --加入房间成功的逻辑
                    local succ = stage:OpenMic()
                    if succ == 0 then
                        print('--------start say something')
                        stage:OpenSpeaker()
                    end
                else
                end
            end)
            local button = display.newButton(display.cx - 100,display.cy,{
                n = _res('ui/common/common_btn_orange')
            })
            display.commonLabelParams(button, {fontSize = 22, text = '加入队伍',color = '7c7c7c'})
            button:setOnClickScriptHandler(function(sender)
                local succ = stage:JoinTeamRoom("fun_test")
                print( '--------')
                -- local succ = stage:ApplyMessageKey() --开始key然后录音的逻辑
                print( '--------', succ )
                if succ == 0 then
                    --然后开启mic与话桐
                    stage:StartUpdate()
                    print( "===========JoinTeamRoom success ====" )
                    succ = stage:OpenMic()
                    if succ == 0 then
                        stage:OpenSpeaker()
                        print( "===========JoinTeamRoom success 222====" )
                    else
                        print( "error code222", succ )
                    end
                else
                    print( "error code333", succ )
                end
            end)
            button:setLocalZOrder(401)
            self:addChild(button)
            local cbutton = display.newButton(display.cx + 100,display.cy,{
                n = _res('ui/common/common_btn_orange')
            })
            display.commonLabelParams(cbutton, {fontSize = 22, text = '退出队伍',color = '7c7c7c'})
            cbutton:setOnClickScriptHandler(function(sender)
                print('------------')
                stage:QuitRoom('fun_test')
                stage:CloseMic()
                stage:CloseSpeaker()
            end)
            cbutton:setLocalZOrder(401)
            self:addChild(cbutton)
        end
        testVoice()
    else
        SHARE_TYPE = {
            C2DXPlatTypeSinaWeibo = 1,
            C2DXPlatTypeWeChat  = 22, --微信好友
            C2DXPlatTypeWeChatMoments = 23, --微信朋友圈
            C2DXPlatTypeWechatPlatform = 997, --用来判断是否安装微信的逻辑
        }


        -- local loadingImgPath = _res(string.format('arts/common/loading_view_%d', 2))
        -- local __bg = display.newImageView(loadingImgPath)
        -- display.commonUIParams(__bg, {po = display.center})
        -- self:addChild(__bg)

        -- local ShareNode = require('common.ShareNode')
        -- local node = ShareNode.new({visitNode = self})
        -- display.commonUIParams(node, {po = display.center})
        -- self:addChild(node,10)

--[[         local btnView = CLayout:create(cc.size(132,88)) ]]
        -- local button = display.newButton(66,88, {
            -- n = _res('share/common_btn_blue_default'),ap = display.CENTER_TOP
        -- })
        -- display.commonLabelParams(button, fontWithColor(14, {text = __('分 享')}))
        -- btnView:addChild(button,1)
        -- local bgImage = display.newImageView(_res('share/main_bg_go_restaurant'),66,0, {ap = display.CENTER_BOTTOM, scale9 = true, size = cc.size(132, 30)})
        -- local titleLabel = display.newLabel(10, 15, fontWithColor(14,{ap = display.LEFT_CENTER,text = string.fmt(__('奖励%1'), 20), fontSize = 22}))
        -- local goodIconPath = CommonUtils.GetGoodsIconPathById(DIAMOND_ID)
        -- local icon = display.newImageView(goodIconPath,124,15,{ap = display.RIGHT_CENTER})
        -- icon:setScale(0.2)
        -- bgImage:addChild(icon)
        -- bgImage:addChild(titleLabel)
        -- btnView:addChild(bgImage,2)
        -- display.commonUIParams(btnView, {po = display.center})
        -- self:addChild(btnView)

        local preLuaSnapshot = nil
        local function snapshotLuaMemory(sender, menu, value)
            -- 首先统计Lua内存占用的情况
            print("GC前, Lua内存为:", collectgarbage("count"))
            -- collectgarbage()
            -- print("GC后, Lua内存为:", collectgarbage("count"))
            local snapshot = require("snapshot")
            local curLuaSnapshot = snapshot.snapshot()
            local ret = {}
            local count = 0
            if preLuaSnapshot ~= nil then
                for k,v in pairs(curLuaSnapshot) do
                    if preLuaSnapshot[k] == nil then
                        count = count + 1
                        ret[k] = v
                    end
                end
            end
            for k, v in pairs(ret) do
                print(k)
                print(v)
            end
            print ("Lua snapshot diff object count is " .. count)
            preLuaSnapshot = curLuaSnapshot
        end

        local function CreateScrollView()
            local view = CLayout:create(display.size)
            local touchLayout = CColorView:create(cc.c4b(0,0,0,0))
            touchLayout:setContentSize(display.size)
            touchLayout:setTouchEnabled(true)
            touchLayout:setPosition(display.center)

            local bg = display.newImageView(_res('res/update/notice_bg'), 0, 0)
            local cview = CLayout:create(bg:getContentSize())
            display.commonUIParams(cview, {po = display.center})
            view:addChild(cview)
            bg:setPosition(FTUtils:getLocalCenter(cview))
            cview:addChild(bg)
            -- 添加标题
            local button = display.newButton(1100,624, {
                    n = _res('res/update/notice_btn_quit')
                })
            cview:addChild(button,2)
            local csize = bg:getContentSize()
            local titleImage = display.newImageView(_res('res/update/notice_title_bg'),csize.width * 0.5,616)
            cview:addChild(titleImage, 3)
            local loadingTipsLabel = display.newLabel(csize.width * 0.5, 615,
                {text = __('游戏公告'),
                    fontSize = 28, color = 'ffdf89', hAlign = display.TAC,ttf = true, font = _res('res/font/FZCQJW.TTF'), outline = '5d3c25', outlineSize = 2 })
            cview:addChild(loadingTipsLabel)

            local key = string.format('isShowAnnouncement_%s', os.date('%Y-%m-%d'))
            local cbutton = display.newCheckBox(6,6,{
                    n = _res('ui/common/common_btn_check_default.png'),
                    s = _res('ui/common/common_btn_check_selected.png')
                })
            cbutton:setAnchorPoint(cc.p(0,0))
            cbutton:setOnClickScriptHandler(function(sender)
                if sender:isChecked() then
                    cc.UserDefault:getInstance():setBoolForKey(key,true)
                else
                    cc.UserDefault:getInstance():setBoolForKey(key,false)
                end
            end)
            cview:addChild(cbutton,2)

            if cc.UserDefault:getInstance():getBoolForKey(key) == true then
                cbutton:setChecked(true)
            else
                cbutton:setChecked(false)
            end

            local usageLabel = display.newLabel(
                cbutton:getPositionX() + cbutton:getContentSize().width - 5,
                26,
                {
                    color = '#5c5c5c',
                    text = __('今日不再显示此公告'),
                    fontSize = 22
                })
            usageLabel:setAnchorPoint(cc.p(0,0.5))
            cview:addChild(usageLabel,2)

            if device.platform == 'ios' or device.platform == 'android' then
                local _webView = ccexp.WebView:create()
                _webView:setAnchorPoint(cc.p(0.5, 0))
                _webView:setPosition(csize.width * 0.5, 44)
                _webView:setContentSize(cc.size(1014, 536))
                _webView:setTag(2345)
                _webView:setScalesPageToFit(true)

                _webView:setOnShouldStartLoading(function(sender, url)
                    return true
                end)
                _webView:setOnDidFinishLoading(function(sender, url)
                    cclog("onWebViewDidFinishLoading, url is ", url)
                end)
                _webView:setOnDidFailLoading(function(sender, url)
                    cclog("onWebViewDidFinishLoading, url is ", url)
                end)
                cview:addChild(_webView,2)
                if not tolua.isnull(_webView) then
                    local originalURL = string.format('http://notice-%s/%s/publicNotice.html?timestamp=%s', Platform.serverHost, i18n.getLang(),tostring(os.date()))
                    _webView:loadURL(originalURL)
                end
            end
            return {
                view = view,
                button = button,
            }
        end

       -- local guideNode = require('common.GuideNode').new({tmodule = 'tower'})
       -- display.commonUIParams(guideNode, { po = display.center})
       -- self:addChild(guideNode, 10)
       self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function()
            --添加注册mediator的逻辑
            -- local viewData = CreateGuideView()
            -- display.commonUIParams(viewData.view, {po = display.center})
            -- self:addChild(viewData.view, 10)
            -- print('--------------->>>',configs['tower'][1].image)
            -- viewData.preImageView:setTexture(configs['tower'][1].image)
            -- viewData.mapPageView:setCountOfCell(2)
            -- viewData.mapPageView:setDataSourceAdapterScriptHandler(PageViewDataAdapter)
            -- viewData.mapPageView:reloadData()
            -- viewData.mapPageView:setOnPageChangedScriptHandler(handler(self, self.MapPageViewChangedHandler))
            -- display.commonUIParams(viewData.prevBtn, {cb = handler(self, self.ChangeChapterBtnCallback)})
            -- display.commonUIParams(viewData.nextBtn, {cb = handler(self, self.ChangeChapterBtnCallback)})


            -- local AvatarFeedMediator = require( 'Game.mediator.AvatarFeedMediator')
            -- local delegate = AvatarFeedMediator.new({id = 12057})
            -- AppFacade.GetInstance():RegistMediator(delegate)
            -- local view = require('Game.views.restaurant.BuyView').new({avatarId = 107008})
            -- display.commonUIParams(view, {po = display.center})
            -- self:addChild(view,20)

            -- local view = VideoNode:create()
            -- view:setBackgroundColor(cc.c4b(100,100,100,100))
            -- display.commonUIParams(view, {po = display.center})
            -- self:addChild(view,10)
            -- view:PlayVideo(_res('res/eater_video.usm'))

            -- local viewData = CreateScrollView()

            -- viewData.button:setOnClickScriptHandler(function(sender)
                -- viewData.view:setVisible(false)
            -- end)
            local view = require( "Frame.Opera.OperaStage" ).new({id = 290, cb = function(tag)

                end, path = string.format("conf/%s/quest/branchStory.json",i18n.getLang())})
            -- end})
            display.commonUIParams(view, {po = display.center})
            self:addChild(view,20)
            -- cc.utils:captureNode(function(isOk, path)
                -- print('----------->>>', path)
                -- FTUtils:storePhotoAlum(path)
                -- require('root.AppSDK').GetInstance():InvokeShare(SHARE_TYPE.C2DXPlatTypeWeChat,{image = path, title = '测试名', text = '描述文件', type = CONTENT_TYPE.C2DXContentTypeImage})
            -- end, 'test.jpg', self, 1.0)

            -- snapshotLuaMemory()

            -- require('profiler').start()

        end)))

    end
--[[     local view = require('Frame.lead_visitor.BootLoader').new({}) ]]
    -- display.commonUIParams(view, {po = display.center})
    -- self:addChild(view, 10)
    -- local dataManager = AppFacade.GetInstance():GetManager("DataManager")
    -- dataManager:InitialDatasAsync(function ( event )
        -- if event.event == 'done' then
            -- local t = CommonUtils.GetConfigAllMess('roleExpressionLocation', 'quest')
            -- dump(t)
        -- elseif event.event == 'progress' then
        -- end
    --[[ end) ]]

--[[     local wifi = CLayout:create(cc.size(40,48)) ]]
    -- wifi:setBackgroundColor(cc.c4b(100,100,100,100))
    -- display.commonUIParams(wifi, {po = cc.p(display.width - 20, display.height - 24)})
    -- self:addChild(wifi, 20)

    -- local wifiIcon = display.newImageView(_res('root/wifi'),20,24)
    -- wifi:addChild(wifiIcon,1)
    -- local label = display.newLabel(20,8, {
        -- fontSize = 16, text = "200ms", color = 'ffffff'
    -- })
    --[[ wifi:addChild(label,2) ]]
    -- local bgPath = 'ui/bg/kitchen_bg_1.png' -- kitchen_bg_1 hall_bg_1
	-- local maskPath = 'ui/bg/kitchen_bg_2.png'
    -- local c = require('Frame.Opera.ColorScreenCommand'):New(1, 'aa0000', 0)
    -- node.m_director:AddCommand(c)
    -- local c2 = require('Frame.Opera.ColorScreenCommand'):New(2, 'ffff00', 1)
    -- node.m_director:AddCommand(c2)

    -- local s1 = require('Frame.Opera.ShakeCommand'):New(1, 5, 2)
    -- node.m_director:AddCommand(s1)
    -- local m1 = require('Frame.Opera.MoveCommand'):New('arts/home_bg.png', 10, 0, 0.5, true)
    -- node.m_director:AddCommand(m1)
    -- node.m_director:AddCommand(require("Frame.Opera.OpenBlackCommand"):New({content = "神明——陷入了永眠……"}))
    -- node.m_director:AddCommand(require("Frame.Opera.EnterStageCommand"):New("role_3"))

    -- node.m_director:AddCommand(require("Frame.Opera.RoleCommand"):New(200002,300,100))
    -- node.m_director:AddCommand(require("Frame.Opera.RoleCommand"):New(200005,900,100))
    -- local t = {
    --     {id = "R1", content = "古代传递宾主之言的人。绍，绍继、接续。介绍指相继传话；为人引进或带入新的事物。见清 袁枚《随园诗话补遗》卷六：“余与和希斋 大司空，全无介绍，而蒙其矜宠特隆。”基本解释[introduce]∶沟通使双方相识或发生联系。 用详细描述来介绍他的研究。",bid = 1},
    --     {id = "R2", content = "古代传递宾主之言的人。绍，绍继、接续。介绍指相继传话；为人引进或带入新的事物。见清 袁枚《随园诗话补遗》卷六：“余与和希斋 大司空，全无介绍，而蒙其矜宠特隆。”基本解释[introduce]∶沟通使双方相识或发生联系。 用详细描述来介绍他的研究。",bid = 1},
    --     {id = "R3", content = "古代传递宾主之言的人。绍，绍继、接续。介绍指相继传话；为人引进或带入新的事物。见清 袁枚《随园诗话补遗》卷六：“余与和希斋 大司空，全无介绍，而蒙其矜宠特隆。”基本解释[introduce]∶沟通使双方相识或发生联系。 用详细描述来介绍他的研究。",bid = 2},
    --     {id = "R4", content = "古代传递宾主之言的人。绍，绍继、接续。介绍指相继传话；为人引进或带入新的事物。见清 袁枚《随园诗话补遗》卷六：“余与和希斋 大司空，全无介绍，而蒙其矜宠特隆。”基本解释[introduce]∶沟通使双方相识或发生联系。 用详细描述来介绍他的研究。",bid = 3},
    --     {id = "R5", content = "古代传递宾主之言的人。绍，绍继、接续。介绍指相继传话；为人引进或带入新的事物。见清 袁枚《随园诗话补遗》卷六：“余与和希斋 大司空，全无介绍，而蒙其矜宠特隆。”基本解释[introduce]∶沟通使双方相识或发生联系。 用详细描述来介绍他的研究。",bid = 2},
    --     {id = "R6", content = "古代传递宾主之言的人。绍，绍继、接续。介绍指相继传话；为人引进或带入新的事物。见清 袁枚《随园诗话补遗》卷六：“余与和希斋 大司空，全无介绍，而蒙其矜宠特隆。”基本解释[introduce]∶沟通使双方相识或发生联系。 用详细描述来介绍他的研究。",bid = 2},
    -- }
    --
    -- local node = require("Game.views.IceRoomScene").new()
    -- display.commonUIParams(node, {po = display.center})
    -- self:addChild(node)
    -- local dataMgr = AppFacade.GetInstance():GetManager("DataManager")
    -- dataMgr:AddRedDotNofication("iceroom", "love")
    -- dataMgr:AddRedDotNofication("iceroom", "love2")
    -- dataMgr:GetRedDotNofication("iceroom", "love")
end

function testShaderSprite(  )
    local bgSprite = display.newSprite(_res("res/arts/goods/goods_icon_130001.png"))
    display.commonUIParams(bgSprite, {po = display.center})
    -- local scale = 1336 / 1776
    -- bgSprite:setScale(scale)
    local glprogram = cc.GLProgramCache:getInstance():getGLProgram("StrokeOutline")
    if not glprogram then
        glprogram = cc.GLProgram:createWithByteArrays([[
            attribute vec4 a_position;
            attribute vec2 a_texCoord;
            attribute vec4 a_color;

            #ifdef GL_ES
            varying lowp vec4 v_fragmentColor;
            varying mediump vec2 v_texCoord;
            #else
            varying vec4 v_fragmentColor;
            varying vec2 v_texCoord;
            #endif

            void main()
            {
                gl_Position = CC_PMatrix * a_position;
                v_fragmentColor = a_color;
                v_texCoord = a_texCoord;
            }
            ]], [[
                varying vec4 v_fragmentColor;
                varying vec2 v_texCoord;
                uniform float outlineSize;
                uniform vec3 outlineColor;
                uniform vec2 textureSize;
                uniform vec3 foregroundColor;

                int getIsStrokeWithAngelIndex(float cosV, float sinV )
                {
                    int stroke = 0;
                    float a = texture2D(CC_Texture0, vec2(v_texCoord.x + outlineSize * cosV / textureSize.x, v_texCoord.y + outlineSize * sinV / textureSize.y)).a;
                    if (a >= 0.5)
                    {
                        stroke = 1;
                    }

                    return stroke;
                }

                void main()
                {
                    vec4 myC = texture2D(CC_Texture0, vec2(v_texCoord.x, v_texCoord.y));
                    myC.rgb *= foregroundColor;
                    if (myC.a >= 0.5)
                    {
                        gl_FragColor = v_fragmentColor * myC;
                        return;
                    }
                    int strokeCount = 0;
                    strokeCount += getIsStrokeWithAngelIndex(1.0, 0.0);
                    strokeCount += getIsStrokeWithAngelIndex(0.866, 0.5);
                    strokeCount += getIsStrokeWithAngelIndex(0.5, 0.866);
                    strokeCount += getIsStrokeWithAngelIndex(0.0, 1.0);
                    strokeCount += getIsStrokeWithAngelIndex(-0.5, 0.866);
                    strokeCount += getIsStrokeWithAngelIndex(-0.866, 0.5);
                    strokeCount += getIsStrokeWithAngelIndex(-0.1, 0.0);
                    strokeCount += getIsStrokeWithAngelIndex(-0.866, 0.5);
                    strokeCount += getIsStrokeWithAngelIndex(-0.5, -0.866);
                    strokeCount += getIsStrokeWithAngelIndex(0.0, -1.0);
                    strokeCount += getIsStrokeWithAngelIndex(0.5, -0.866);
                    strokeCount += getIsStrokeWithAngelIndex(0.866, -0.5);

                    bool stroke = false;
                    if (strokeCount > 0)
                    {
                        stroke = true;
                    }

                    if (stroke)
                    {
                        myC.rgb = outlineColor;
                        myC.a = 1.0;
                    }

                    gl_FragColor = v_fragmentColor * myC;
                }
            ]]);
        cc.GLProgramCache:getInstance():addGLProgram(glprogram, "StrokeOutline");
    end
    print("====", glprogram)
    local glprogramState = cc.GLProgramState:create(glprogram);
    local outlineColor = cc.c3b(100,255,100)
    local textureSize = bgSprite:getContentSize()
    local foregroundColor = cc.c3b(255,255,255)
    glprogramState:setUniformFloat("outlineSize", 5);
    glprogramState:setUniformVec3("outlineColor", cc.vec3(outlineColor.r / 255.0, outlineColor.g / 255.0, outlineColor.b / 255.0));
    glprogramState:setUniformVec2("textureSize", cc.vec3(textureSize.width, textureSize.height));
    glprogramState:setUniformVec3("foregroundColor", cc.vec3(foregroundColor.r / 255.0, foregroundColor.g / 255.0, foregroundColor.b / 255.0));
    bgSprite:setGLProgramState(glprogramState)
    self:addChild(bgSprite, 3)
end

function testInterface(args)
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
    gameMgr.userInfo.sessionId = "49ca6880f13b3fc161855a721b8b8180"
    httpManager:Post('icePlace/unlockIcePlace', "test", {icePlaceId = 1})
    -- httpManager:Post('icePlace/upgradeDiningTable', "test", {icePlaceId = 1})
    -- httpManager:Post('icePlace/addCardInIcePlace', "test", {icePlaceId = 1, playerCardId = 200001})
end

function DebugScene:testGuide()

    local button = CColorView:create(cc.c4b(10, 10,200,100))
    button:setTouchEnabled(true)
    button:setContentSize(cc.size(120, 60))
    display.commonUIParams(button, {po = display.center})
    button:setOnClickScriptHandler(function(sender)
        print("button clicked ")
    end)
    self:addChild(button)


    local layout = CLayout:create(display.size)
    display.commonUIParams(layout, {po = display.center})

    local nbutton = clone(button)
    layout:addChild(nbutton)
    self:addChild(layout, 10)
end

function DebugScene:testdialog()
    local dialog = require("Frame.Opera.DialogueCommand")
    local t = json.decode(FTUtils:getFileData("res/dialog.json"))
    local span1 = t['1']
    for k,v in pairs(span1) do
        local id = "L3"
        if k % 2 == 0 then
            id = "R3"
        end
        local c = dialog:New(id, 1)
        c:CommandDialogue(v.name, v.descr)
        node.m_director:AddCommand(c)
    end
    -- node.m_director:AddCommand(require("Frame.Opera.ExitStageCommand"):New({200002,200005}, "left"))
    -- node.m_director:AddCommand(require("Frame.Opera.CollisionCommand"):New({200002,200005}))
    node:Start()

    -- local dataMgr = AppFacade.GetInstance():GetManager("DataManager")
    -- local t = dataMgr:GetConfigDataByFileName('unlockType')

    -- local t = dataMgr:GetConfigDataByFileName('icePlaceUpgrade', 'iceBink')
    -- dump(t)
end

function DebugScene:createPhysics()
    --[[
    -- 下面是测试物理引擎
    --]]
   local gravity = b2Vec2(0.0, 0.0)
   local _world = b2World:new_local(gravity)
     -- 允许静止的物体休眠
    _world:SetAllowSleeping(true)
    -- 开启连续物理检测，使模拟更加的真实
    -- _world:SetContinuousPhysics(true)
    local listener = CContactListener:new() --需要的时候删除掉
    listener:registerScriptContactHandler(function (type, contact)
        print("LUA: Contact")
        if type == BEGIN_CONTACT then
            print('begin')
        else
            print('end')
        end

        -- copy out contact data
        local function printPos(fixture)
            local pos = fixture:GetBody():GetPosition();
            print(pos.x, pos.y)
        end
        printPos(contact:GetFixtureA())
        printPos(contact:GetFixtureB())
    end)
    _world:SetContactListener(listener)

    --创建边界
    --[[ local groundBodyRef = b2BodyDef:new_local() ]]
    -- groundBodyRef.position = b2Vec2(0,0)
    -- local groundBody = _world:CreateBody(groundBodyRef)
    -- local groundEdge = b2EdgeShape:new_local()
    -- local boxShapeDef = b2FixtureDef:new_local()
    -- boxShapeDef.shape = groundEdge

    -- local winSize = cc.Director:getInstance():getWinSize();
    -- groundEdge:Set(b2Vec2(0,0), b2Vec2(winSize.width/PTM_RATIO, 0))
    -- groundBody:CreateFixture(boxShapeDef)

    -- groundEdge:Set(b2Vec2(0,0), b2Vec2(0, winSize.height/PTM_RATIO))
    -- groundBody:CreateFixture(boxShapeDef)

    -- groundEdge:Set(b2Vec2(0, winSize.height/PTM_RATIO), b2Vec2(winSize.width/PTM_RATIO, winSize.height/PTM_RATIO))
    -- groundBody:CreateFixture(boxShapeDef)

    -- groundEdge:Set(b2Vec2(winSize.width/PTM_RATIO, winSize.height/PTM_RATIO), b2Vec2(winSize.width/PTM_RATIO, 0))
    -- groundBody:CreateFixture(boxShapeDef)

    local debugDraw = B2DebugDrawLayer:create(_world, 32)
    self:add(debugDraw, 9999, 9999)
    local bgSprite = display.newSprite("res/ui/iceroom/refresh_bg_1_02.png")
    display.commonUIParams(bgSprite, {po = display.center})
    -- local scale = 1336 / 1776
    -- bgSprite:setScale(scale)
    self:addChild(bgSprite, 3)

    --水果墙
    local offsetY = (1002 - display.height) / 2
    local offsetX = (1334 - display.width) / 2

    local fruitImage = display.newSprite("res/ui/iceroom/refresh_bg_1_01.png")
    display.commonUIParams(fruitImage, {po = cc.p(display.cx, display.height - fruitImage:getContentSize().height * 0.5 + offsetY)})
    -- local scale = 1336 / 1776
    -- fruitImage:setScale(scale)
    self:addChild(fruitImage, 4)

    local actionNode = require("Game.states.AnimateNode").new({size = cc.size(150, 150),
        name = "cards/spine/avatar/200001", scale = 0.38})
    actionNode:setAnchorPoint(cc.p(0.5, 0.2))
    actionNode:setPosition(cc.p(display.cx, display.cy))
    self:addChild(actionNode, 5)
    --创建body与shape
    local personDef = b2BodyDef:new_local()
    personDef.type = b2_dynamicBody
    personDef.position:Set(display.cx/PTM_RATIO, (display.cy - 30)/PTM_RATIO)
    personDef.userData = actionNode
    local _body = _world:CreateBody(personDef)
    -- local polygonShape = b2PolygonShape:new_local()
    -- -- local boxShapeDef = b2FixtureDef:new_local()
    -- boxShapeDef.density = 1.0
    -- boxShapeDef.friction = 1.0
    -- boxShapeDef.restitution = 1.0
    -- boxShapeDef.shape = polygonShape
    -- polygonShape:SetAsBox(150 / PTM_RATIO, 75/ PTM_RATIO)
    -- _body:CreateFixture(boxShapeDef)

    local circle = b2CircleShape:new_local()
    circle.m_radius = 40/ PTM_RATIO

    local shapeDef = b2FixtureDef:new_local()
    shapeDef.shape = circle
    shapeDef.density = 1.0
    shapeDef.friction = 0.2
    shapeDef.restitution = 0.8
    _body:CreateFixture(shapeDef)
    _body:SetLinearVelocity(b2Vec2(0,5))
    -- _body:SetAngularVelocity(15)

    local instance = GB2ShapeCache:getInstance()
    instance:addShapesWithFile("ui/iceroom/test.plist")
    --水果墙
    local topLeft = display.newSprite(_res('ui/iceroom/refresh_bg_1_top_left.png'))
    local cellSize = topLeft:getContentSize()
    display.commonUIParams(topLeft, {po = cc.p(cellSize.width * 0.5 - offsetX, display.height - cellSize.height * 0.5 + offsetY)})
    self:addChild(topLeft,1)
    --  --创建body与shape
    local sbodyDef = b2BodyDef:new_local()
    sbodyDef.type = b2_staticBody
    sbodyDef.position:Set(topLeft:getPositionX()/PTM_RATIO, topLeft:getPositionY()/PTM_RATIO)
    sbodyDef.userData = topLeft
    local _body3 = _world:CreateBody(sbodyDef)
    instance:addFixturesToBody(_body3,"refresh_bg_1_top_left")

    local topRight = display.newSprite(_res('ui/iceroom/refresh_bg_1_top_right.png'))
    display.commonUIParams(topRight, {po = cc.p(display.width - cellSize.width * 0.5 + offsetX, display.height - cellSize.height * 0.5 + offsetY)})
    self:addChild(topRight,1)
    --  --创建body与shape
    local rightDef = b2BodyDef:new_local()
    rightDef.type = b2_staticBody
    rightDef.position:Set(topRight:getPositionX()/PTM_RATIO, topRight:getPositionY()/PTM_RATIO)
    rightDef.userData = topRight
    local _body3 = _world:CreateBody(rightDef)
    instance:addFixturesToBody(_body3,"refresh_bg_1_top_right")

    local bottomLeft = display.newSprite(_res('ui/iceroom/refresh_bg_1_bottom_left.png'))
    display.commonUIParams(bottomLeft, {po = cc.p(cellSize.width * 0.5 - offsetX, cellSize.height * 0.5 - offsetY)})
    self:addChild(bottomLeft,1)
    --  --创建body与shape
    local bottomDef = b2BodyDef:new_local()
    bottomDef.type = b2_staticBody
    bottomDef.position:Set(bottomLeft:getPositionX()/PTM_RATIO, bottomLeft:getPositionY()/PTM_RATIO)
    bottomDef.userData = bottomLeft
    local _body3 = _world:CreateBody(bottomDef)
    instance:addFixturesToBody(_body3,"refresh_bg_1_bottom_left")

    local bottomRight = display.newSprite(_res('ui/iceroom/refresh_bg_1_bottom_right.png'))
    display.commonUIParams(bottomRight, {po = cc.p(display.width - cellSize.width * 0.5 + offsetX, cellSize.height * 0.5 - offsetY)})
    self:addChild(bottomRight,1)
    --  --创建body与shape
    local brightDef = b2BodyDef:new_local()
    brightDef.type = b2_staticBody
    brightDef.position:Set(bottomRight:getPositionX()/PTM_RATIO, bottomRight:getPositionY()/PTM_RATIO)
    brightDef.userData = bottomLeft
    local _body3 = _world:CreateBody(brightDef)
    instance:addFixturesToBody(_body3,"refresh_bg_1_bottom_right")



    -- tick
    local function tick(dt)
        _world:Step(dt, 10, 10)
        actionNode:setPosition(cc.p(_body:GetPosition().x * PTM_RATIO, _body:GetPosition().y * PTM_RATIO))
    end

    cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick, 0, false)


    --下面是测试tips
    -- local function animation(text, time, pos)
    --     -- body
    --     self:runAction(cc.Sequence:create(
    --     cc.DelayTime:create(time),
    --     cc.CallFunc:create(function()
            -- local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
            -- uiMgr:ShowInformationTips(text)
        -- end)))
    -- end
    -- animation(__("这是一个测试显示的tips小条"),1)
    -- animation(__("这是一个测试显示的tips小条2"),2)
    -- animation(__("这是一个测试显示的tips小条3"),3)
    --

    --测试状态机逻辑
    -- local node = require("Game.states.AnimateNode").new({size = cc.size(200, 200),
    --     name = "cards/spine/avatar/200001", scale = 0.38})
    -- node:setPosition(cc.p(display.cx, display.cy))
    -- self:addChild(node, 10)
end

return DebugScene
