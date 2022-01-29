function compareBigVersion(oldVer, newVer)
    local t1 = string.split(oldVer,'.')
    local t2 = string.split(newVer,'.')
    local targetOldVer = ''
    local targetNewVer = ''
    if #t1 < 2 then
        targetOldVer = table.concat({t1[1],0},'.')
    else
        targetOldVer = table.concat({t1[1],t1[2]},'.')
    end
    if #t2 < 2 then
        targetNewVer = table.concat({t2[1],0},'.')
    else
        targetNewVer = table.concat({t2[1],t2[2]},'.')
    end
    return compareVersion(targetOldVer,targetNewVer)
end
--[[--
比较两个版本的大小
-1 为小于
0 为等于
1 为大于
@param ov string old version
@param nv string new version
--]]
function compareVersion( ov, nv )
    -- body
    local t1 = string.split(ov,'.')
    local t2 = string.split(nv,'.')
    local len1 = #t1
    local len2 = #t2
    local result = 0
    local len = len1
    if len1 < len2 then len = len2 end
    for i= 1, len do
        local a ,b = 0,0
        if i <= len1 then a = tonumber(t1[i],10) end
        if i <= len2 then b = tonumber(t2[i],10) end
        if a > b then
            result = 1
            break
        elseif a < b then
            result = -1
            break
        end
    end
    return result
end

local updater = require("update.updater")


local sharedDirector         = cc.Director:getInstance()

--sharedDirector:setProjection(cc.DIRECTOR_PROJECTION2_D)

local function tabletourlencode(t)
    local args = {}
    local i = 1
    for key, value in pairs(t) do
        args[i] = string.urlencode(key) .. '=' .. string.urlencode(value)
        i = i + 1
    end
    return table.concat(args,'&')
end


local PROGRESS_TIMER_BAR = 1
local PROGRESS_TIMER_RADIAL = 0

local us = class('UpdateScene',function()
    local ret =  CLayout:create(display.size)
    ret.name = 'UpdateScene'
    return ret
end)


--[[--
获取文件路径
--]]
local function getFileName(name)
    if string.find(name, '.ccz') then
        return name
    else
        local fname = FTUtils:deletePathExtension(name)
        if FTUtils:isPathExistent(string.format('%s.png',fname)) then
            return string.format('%s.png',fname)
        elseif FTUtils:isPathExistent(string.format('%s.pvr.ccz',fname)) then
            return string.format('%s.pvr.ccz',fname)
        elseif FTUtils:isPathExistent(string.format('%s.jpg',fname)) then
            return string.format('%s.jpg',fname)
        end
    end
end


local DICT = {
    BG = checktable(HOME_THEME_STYLE_DEFINE).LOGIN_BG or "update/update_bg.png",
    BTN_NORMAL = "update/common_btn_orange.png",
    BTN_PRESS = "update/common_btn_orange_disable.png",
    Progress_Bg = "update/update_bg_loading.png",
    Progress_Image = "update/update_ico_loading.png",
    Progress_Top = "update/update_ico_loading_fornt.png",
    Progress_Descr = "update/update_bg_refresh_number.png",
    Dialog_Bg = "update/common_bg_2.png"
}

local function CreateScrollView()
    local view = CLayout:create(display.size)
    view:setName("SCROLL_VIEW")
    local touchLayout = CColorView:create(cc.c4b(0,0,0,0))
    touchLayout:setContentSize(display.size)
    touchLayout:setTouchEnabled(true)
    touchLayout:setPosition(display.center)

    local bg = display.newImageView(_res('update/notice_bg'), 0, 0)
    local cview = CLayout:create(bg:getContentSize())
    cview:setName("CVIEW")
    display.commonUIParams(cview, {po = display.center})
    view:addChild(cview)
    bg:setPosition(FTUtils:getLocalCenter(cview))
    cview:addChild(bg)
    -- 添加标题
    local button = display.newButton(1100,624, {
            n = _res('update/notice_btn_quit')
        })
    cview:addChild(button,2)
    local csize = bg:getContentSize()
    local titleImage = display.newImageView(_res('update/notice_title_bg'),csize.width * 0.5,616)
    cview:addChild(titleImage, 3)
    local loadingTipsLabel = display.newLabel(csize.width * 0.5, 615,
        {text = __('游戏公告'),
        fontSize = 28, color = 'ffdf89', hAlign = display.TAC,ttf = true, font = TTF_GAME_FONT, outline = '5d3c25', outlineSize = 1 })
    cview:addChild(loadingTipsLabel)

    --[[
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
    --]]
    if device.platform == 'ios' or device.platform == 'android' then
        local _webView = ccexp.WebView:create()
        _webView:setAnchorPoint(cc.p(0.5, 0))
        _webView:setPosition(csize.width * 0.5, 44)
        _webView:setContentSize(cc.size(1014, 536))
        _webView:setTag(2345)
        _webView:setScalesPageToFit(true)

        _webView:setOnShouldStartLoading(function(sender, url)
            if string.find(url, "publicNotice.html") then
                return true
            else
                FTUtils:openUrl(url)
                return false
            end
        end)
        _webView:setOnDidFinishLoading(function(sender, url)
            cclog("onWebViewDidFinishLoading, url is ", url)
        end)
        _webView:setOnDidFailLoading(function(sender, url)
            cclog("onWebViewDidFinishLoading, url is ", url)
        end)
        _webView:setName("WEBVIEW")
        cview:addChild(_webView,2)
        if not tolua.isnull(_webView) then
            local originalURL = string.format('http://notice-%s/publicNotice.html?timestamp=%s&channelId=%d&lang=%s&host=%s', NOTICE_HOST, tostring(os.time()),checkint(Platform.id),i18n.getLang(),Platform.serverHost)
            _webView:loadURL(originalURL)
        end
        return {
            view = view,
            button = button,
            _webView = _webView,
        }
    else
        return {
            view = view,
            button = button,
        }
    end
end


local function isElexSdk()
    local platformId = checkint(Platform.id)
    local isQuick = false
    if platformId == ElexIos or platformId == ElexAndroid
        or platformId == ElexAmazon or platformId == ElexThirdPay then
        isQuick = true
    end
    return isQuick
end

local isRecorded = false
--[[
--appflyer事件统计的接口的逻辑
--]]
local function appFlyerEventTrack(event_name, params)
    if isElexSdk() then
        local t = {}
        for name,val in pairs(params) do
            table.insert(t, {id = name, value = val})
        end
        if device.platform == 'ios' then
            local text = json.encode(t)
            if text then
                luaoc.callStaticMethod('AppFlyerHelper','trackEvent',{event = event_name,values = text})
            end
        elseif device.platform == 'android' then
            --android平台
            local text = json.encode(t)
            if text then
                luaj.callStaticMethod('com.duobaogame.summer.AppFlyerHelper','trackEvent',{event_name,text})
            end
        end
    end
end

function us:ctor(...)
    self.ipHostPair = {} --ip与域名对照表
    self.ipAddresses = {} --所有的ips地址
    self.startIndex = 1 --开始请求下载的地址位置
    self.tryNum = 1 --尝试次数
    self.userUpdateIps = {} --用户检测更新时所使用的ip列表
    self.traceHost = true
    self.downloadNo = 1 --尝试下载的次数
    local function _sceneHandler(event)
        if event == "enter" then
            self:onEnter()
        elseif event == "cleanup" then
            self:onCleanup()
        elseif event == "exit" then
            self:onExit()

            if DEBUG_MEM then
                print("----------------------------------------")
                print(string.format("LUA VM MEMORY USED: %0.2f KB", collectgarbage("count")))
                cc.Director:getInstance():getTextureCache():getCachedTextureInfo()
                print("----------------------------------------")
            end
        end
    end
    self:registerScriptHandler(_sceneHandler)
    ---创建基础界面
    local function CreateSlashView()
        local view = CLayout:create(display.size)
        view:setBackgroundColor(cc.c4b(255,255,255,255))
        local logoImage = display.newImageView(_res('update/splash_ico_funtoy'))
        display.commonUIParams(logoImage, {po = cc.p(display.cx, display.cy + 20)})
        view:addChild(logoImage)
        -- local textImage = display.newImageView(_res('update/splash_bg_text_web'))
        -- display.commonUIParams(textImage, {ap = display.CENTER_BOTTOM, po = cc.p(display.cx, 10)})
        -- view:addChild(textImage)
        return {
            view = view,
        }
    end

    local function CreateView()
        local __bg = display.newImageView(getFileName(DICT.BG))
        display.commonUIParams(__bg,{ap = display.CENTER, po = cc.p(display.cx, display.cy)})
        self:addChild(__bg)
        -- local scale = display.height / 1002
        --添加logo的文件
        local logoAnimate = sp.SkeletonAnimation:create('update/logo.json', 'update/logo.atlas', 0.92)
        logoAnimate:setPosition(cc.p(__bg:getContentSize().width * 0.5, __bg:getContentSize().height - 470))
        logoAnimate:setToSetupPose()
        logoAnimate:update(0)
        logoAnimate:setAnimation(0, 'logo', false)
        __bg:addChild(logoAnimate)
        logoAnimate:registerSpineEventHandler(function (event)
            if event.animation == "logo" then
                logoAnimate:setAnimation(0, 'xunhuan', true)
            end
        end,sp.EventType.ANIMATION_COMPLETE)

        local roleAnimate = sp.SkeletonAnimation:create('update/mifan.json', 'update/mifan.atlas', 0.92)
        -- roleAnimate:setPosition(cc.p(display.cx, __bg:getContentSize().height - 502))
        roleAnimate:setPosition(cc.p(__bg:getContentSize().width * 0.5, __bg:getContentSize().height - 502))
        roleAnimate:setToSetupPose()
        roleAnimate:update(0)
        roleAnimate:setAnimation(0, 'idle', true)
        __bg:addChild(roleAnimate)

        --显示包版本
        local packageVersion = FTUtils:getAppVersion()
        local version = display.newLabel(display.SAFE_L + 10,40,{ap = cc.p(0,0),fontSize = 18,color = 'ffffff',text = 'V'..tostring(packageVersion)})
        self:addChild(version)
        ---[[--
        --显示小版本号
        ----]]
        local lversion = display.newLabel(display.SAFE_L + 6,22,{ap = cc.p(0,0),fontSize = 18,color = 'ffffff'})
        lversion:setAlignment(cc.TEXT_ALIGNMENT_LEFT)
        lversion:setTag(43333)
        self:addChild(lversion,2)

        local rversion = display.newLabel(display.SAFE_L + 6,4,{ap = cc.p(0,0),fontSize = 18,color = 'ffffff'})
        rversion:setAlignment(cc.TEXT_ALIGNMENT_LEFT)
        rversion:setTag(43334)
        self:addChild(rversion,2)
        --进度条处
        local colorView = CColorView:create(cc.c4b(100,100,100,0))
        colorView:setAnchorPoint(display.CENTER_BOTTOM)
        colorView:setPosition(cc.p(display.cx, 0))
        colorView:setContentSize(cc.size(display.width, 100))
        self:addChild(colorView,4)
        -- 进度条
        local loadingBarBg = display.newImageView(_res('update/update_bg_black.png'), 0, 0, {scale9 = true, size = cc.size(display.width, 209)})
        display.commonUIParams(loadingBarBg, {po = cc.p(display.cx, 0), ap = cc.p(0.5, 0)})
        colorView:addChild(loadingBarBg)
        -- loadingBarBg:setVisible(false)

        local loadingBar = CProgressBar:create(_res(DICT.Progress_Image))
        loadingBar:setBackgroundImage(_res(DICT.Progress_Bg))
        loadingBar:setDirection(0)
        loadingBar:setMaxValue(100)
        loadingBar:setValue(0)
        loadingBar:setPosition(cc.p(display.cx, 105))
        colorView:addChild(loadingBar, 1)

        -- 进度条闪光
        local loadingBarShine = display.newNSprite(_res('update/update_ico_light.png'), 0, loadingBar:getPositionY())
        colorView:addChild(loadingBarShine, 2)
        local percent = loadingBar:getValue() / loadingBar:getMaxValue()
        loadingBarShine:setPositionX(loadingBar:getPositionX() - loadingBar:getContentSize().width * 0.5 + loadingBar:getContentSize().width * percent - 1)
        -- loadingBarShine:setOpacity(255 * percent)
        -- local loadingBarShineActionSeq = cc.RepeatForever:create(cc.Sequence:create(
        --     cc.FadeTo:create(4, 0),
        --     cc.FadeTo:create(4, 255)))
        -- loadingBarShine:runAction(loadingBarShineActionSeq)

        -- 提示
        local loadingTipsBg = display.newImageView(_res('update/loading_bg_tips.png'))
        display.commonUIParams(loadingTipsBg,
        {ap = cc.p(0.5, 1), po = cc.p(loadingBar:getPositionX(), loadingBar:getPositionY() - loadingBar:getContentSize().height * 0.5 - 3)})
        colorView:addChild(loadingTipsBg, 1)

        local padding = cc.p(20, 7)
        local loadingTipsLabel = display.newLabel(padding.x, loadingTipsBg:getContentSize().height - padding.y,
        {text = '',
        fontSize = 20, color = 'ffffff', ap = cc.p(0, 1), hAlign = display.TAC,ttf = true, font = TTF_GAME_FONT,
        w = loadingTipsBg:getContentSize().width - padding.x * 2, h = loadingTipsBg:getContentSize().height - padding.y * 2})
        loadingTipsBg:addChild(loadingTipsLabel)

        local padding = cc.p(colorView:getContentSize().width * 0.5, 7)
        local progressTipsLabel = display.newLabel(padding.x, padding.y,
        {text = '',
        fontSize = 20, color = 'ffffff', ap = cc.p(0.5, 0), hAlign = display.TAC,ttf = true, font = TTF_GAME_FONT,
        w = loadingTipsBg:getContentSize().width - padding.x * 2, h = loadingTipsBg:getContentSize().height - padding.y * 2})
        colorView:addChild(progressTipsLabel,2)

        -- 小人和加载文字
        local avatarAnimationName = 'loading_avatar'
        local animation = cc.AnimationCache:getInstance():getAnimation(avatarAnimationName)
        if nil == animation then
            animation = cc.Animation:create()
            for i = 1, 10 do
                animation:addSpriteFrameWithFile(_res(string.format('update/loading_run_%d.png', i)))
            end
            animation:setDelayPerUnit(0.05)
            animation:setRestoreOriginalFrame(true)
            cc.AnimationCache:getInstance():addAnimation(animation, avatarAnimationName)
        end

        local loadingAvatar = display.newNSprite(_res('update/loading_run_1.png'), 0, 0)
        loadingAvatar:setPositionY(loadingBar:getPositionY() + loadingBar:getContentSize().height * 0.5 + loadingAvatar:getContentSize().width * 0.5 + 10)
        colorView:addChild(loadingAvatar, 5)
        loadingAvatar:runAction(cc.RepeatForever:create(cc.Animate:create(animation)))

        local loadingLabelBg = display.newImageView(_res('update/bosspokedex_name_bg.png'))
        loadingLabelBg:setPositionY(loadingAvatar:getPositionY() - 8)
        colorView:addChild(loadingLabelBg, 4)

        local loadingLabel = display.newLabel(utils.getLocalCenter(loadingLabelBg).x - 20, utils.getLocalCenter(loadingLabelBg).y - 2,
        {text = __('正在载入'), ttf = true, font = TTF_GAME_FONT, fontSize = 24, color = '#ffffff'})
        loadingLabel:enableOutline(ccc4FromInt('290c0c'), 1)
        loadingLabelBg:addChild(loadingLabel)

        local offsetX = -25
        local totalWidth = loadingAvatar:getContentSize().width + loadingLabelBg:getContentSize().width + offsetX
        local baseX = display.cx
        local loadingAvatarX = baseX - totalWidth * 0.5 + loadingAvatar:getContentSize().width * 0.5
        local loadingLabelBgX = loadingAvatarX + loadingAvatar:getContentSize().width * 0.5 + offsetX + loadingLabelBg:getContentSize().width * 0.5
        loadingAvatar:setPositionX(loadingAvatarX)
        loadingLabelBg:setPositionX(loadingLabelBgX)



        return {
            bigVersion    = packageVersion,
            lversionLabel = lversion,
            versionLabel  = rversion,
            colorView     = colorView,
            loadingBar = loadingBar,
            loadingBarShine = loadingBarShine,
            loadingTipsLabel = loadingTipsLabel,
            progressTipsLabel = progressTipsLabel,
        }
    end
    self.viewData = CreateView()
    self.viewData.colorView:setVisible(false)
    local function updateRequest()
        if package.loaded['root.AppSDK'] then
            self:_checkUpdate()
        else
            if SHOW_LAUNCH_LOGO then
                if not DotGameEvent then
                    DotGameEvent = require("root.DotGameEvent")
                end
                DotGameEvent.SendEvent(DotGameEvent.EVENTS.INITIALIZE)
                local slashViewData = CreateSlashView()
                display.commonUIParams(slashViewData.view, {po = display.center})
                self:addChild(slashViewData.view,60)
                self:runAction(cc.Sequence:create(cc.DelayTime:create(SHOW_LOGO_TIME),cc.TargetedAction:create(slashViewData.view, cc.FadeOut:create(1)),
                    cc.TargetedAction:create(slashViewData.view, cc.RemoveSelf:create()),
                        cc.CallFunc:create(function()
                            --执行检测更新
                            self:_checkUpdate()
                        end)))
            else
                self:_checkUpdate()
            end
        end
    end


    local function updateLogical()
        if SHOW_LOGIN_NOTICE and (not package.loaded['root.AppSDK']) then
            local key = string.format('isShowAnnouncement_%s', os.date('%Y-%m-%d'))
            if cc.UserDefault:getInstance():getBoolForKey(key) == false then
                --未出现过公告
                if SHOW_LAUNCH_LOGO then
                    local slashViewData = CreateSlashView()
                    display.commonUIParams(slashViewData.view, {po = display.center})
                    self:addChild(slashViewData.view,60)
                    self:runAction(cc.Sequence:create(cc.DelayTime:create(3),cc.TargetedAction:create(slashViewData.view, cc.FadeOut:create(1)),cc.TargetedAction:create(slashViewData.view, cc.RemoveSelf:create()),
                            cc.CallFunc:create(function()
                                --执行检测更新
                                local viewData = CreateScrollView()
                                display.commonUIParams(viewData.button , {

                                    cb = function(sender)
                                        sender:setEnabled(false)
                                        viewData.view:setVisible(false)
                                        if device.platform == 'ios' or device.platform == 'android' then
                                            viewData._webView:setVisible(false)
                                        end
                                        self:_checkUpdate()
                                    end
                                })
                                display.commonUIParams(viewData.view, {po = display.center})
                                self:addChild(viewData.view,20)
                            end)))
                else
                    local viewData = CreateScrollView()
                    display.commonUIParams( viewData.button, {
                        cb = function(sender)
                            sender:setEnabled(false)
                            viewData.view:setVisible(false)
                            if device.platform == 'ios' or device.platform == 'android' then
                                viewData._webView:setVisible(false)
                            end
                            self:_checkUpdate()
                        end
                    })
                    display.commonUIParams(viewData.view, {po = display.center})
                    self:addChild(viewData.view,20)
                end
            else
                updateRequest()
            end
        else
            updateRequest()
        end
    end
    updateLogical()
end

local function CreateTipsWindow(downsize)
    local size = cc.size(742,640)
    local view = CLayout:create(size)
    local __bg = display.newImageView(getFileName(DICT.Dialog_Bg),0,0,{
        scale9 = true, size = size
    })
    display.commonUIParams(__bg,{po = FTUtils:getLocalCenter(view)})
    view:addChild(__bg)
    --其他元素
    local titleLabel = display.newButton(size.width * 0.5, size.height - 22,{
        n = _res('update/common_bg_title_2')
    })
    display.commonLabelParams(titleLabel, {text = __('更新公告'), fontSize = 24, color = 'ffffff',ttf = true, font = TTF_GAME_FONT})
    titleLabel:setEnabled(false)
    view:addChild(titleLabel, 2)

    local bg = display.newImageView(_res('update/commcon_bg_text'),size.width * 0.5, 370, {
        scale9 = true, size = cc.size(682, 436)
    })
    view:addChild(bg)
    local remoteInfo = updater.getRemotePackageInfo()
    local localResInfo = updater.getLocalResInfo()
    local title = (remoteInfo.title or '')
    local __titleLabel = display.newLabel(size.width * 0.5, size.height - 78, {
        text = title, fontSize = 26, color = '5c5c5c',ttf = true, font = TTF_GAME_FONT
    })
    view:addChild(__titleLabel,2)
    -- scroll view
    local scrollView = cc.ScrollView:create()
    scrollView:setViewSize(cc.size(600, 380))
    scrollView:setDirection(2)
    scrollView:setBounceable(false)
    scrollView:setAnchorPoint(cc.p(0,0))
    scrollView:setPosition(cc.p(80, 150))
    view:addChild(scrollView)

    -- message label
    local msgLabel = cc.Label:create()
    msgLabel:setLineBreakWithoutSpace(true)
    msgLabel:setSystemFontSize(24)
    msgLabel:setWidth(600)
    msgLabel:setColor(cc.c3b(100,100,100))
    msgLabel:setAnchorPoint(cc.p(0,0))
    scrollView:setContainer(msgLabel)

    local __descrLabel = display.newLabel(size.width * 0.5,130,{ap = cc.p(0.5,1.0),color = '6c6c6c',fontSize = 20,text = '',w = 600,h = 100,
        ttf = true, font = TTF_GAME_FONT})
    __descrLabel:setLineBreakWithoutSpace(true)
    __descrLabel:setTag(334)
    view:addChild(__descrLabel,2)
    local viewData = {
        view = view,
        scrollView = scrollView,
        contentView = msgLabel,
        __descrLabel = __descrLabel,
    }
    if localResInfo and remoteInfo and type(remoteInfo) == 'table' then
        if remoteInfo.version then
            if remoteInfo.isMaintain and remoteInfo.isMaintain == true then
                --停机维护状态逻辑
                __descrLabel:setString(__('当前服务器正在维护中，稍后才能愉快的玩耍哟~~'))
            else
                --远程的版本前两位为大版本变更判断需强制更新
                if compareBigVersion(FTUtils:getAppVersion(),remoteInfo.appVersion) == -1 then
                    --need force update
                    __descrLabel:setString(__('当前版本过低，不能再愉快的玩耍了，前去下载新版本吧'))

                    local __gotoDownBtn = display.newButton(0,0,{
                        n = getFileName(DICT.BTN_NORMAL),
                        s = getFileName(DICT.BTN_PRESS),
                        cb = function ( sender )
                                FTUtils:openUrl(remoteInfo.forceUpdateURL)
                            end
                    })
                    display.commonLabelParams(__gotoDownBtn,{fontSize = 26,color = '4c4c4c',text = __('前 往'), ttf = true, font = TTF_GAME_FONT})
                    display.commonUIParams(__gotoDownBtn,{po = cc.p(size.width * 0.5,50)})
                    view:addChild(__gotoDownBtn,2)
                else
                    local s = ''
                    if downsize <= ( 1024 * 100) then
                        s = string.fmt(__('_num_以下'), {_num_ = '100K'})
                    elseif downsize > (1024 * 1024) then
                        s = string.format('%dM',(downsize / (1024 * 1024.0)))
                    else
                        s = string.format('%dK',(downsize / 1024.0))
                    end
                    local desrc = string.format(__('检测到新版本此次更新包大小为%s，请在良好网络下进行更新~~'),s)
                    __descrLabel:setString(desrc)

                    local __gotoDownBtn = display.newButton(0,0, {
                        n = getFileName(DICT.BTN_NORMAL),
                        s = getFileName(DICT.BTN_PRESS),
                    })
                    display.commonUIParams(__gotoDownBtn,{po = cc.p(checkint(size.width * 0.5),50)})
                    display.commonLabelParams(__gotoDownBtn,{fontSize = 26,color = '4c4c4c',text = __('确 定'),ttf = true, font = TTF_GAME_FONT})
                    view:addChild(__gotoDownBtn,2)
                    viewData.startDownButton = __gotoDownBtn
                end
            end
            --添加更新信息列表
            local introText = viewData.contentView
            introText:setString((remoteInfo.updateContent or ''))
            -- scroll to top
            local scrollView = viewData.scrollView
            local scrollTop  = scrollView:getViewSize().height - scrollView:getContainer():getContentSize().height
            scrollView:setContentOffset(cc.p(0, scrollTop))
        end
    end
    return viewData
end

--[[--
分隔字符串#分隔
--]]
local function split(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos = 0
    -- for each divider found
    local arr = {}
    for st,sp in function() return string.find(input, delimiter, pos, false) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function startParseIp(hosts, cb)
    local ipHostPair = {} --ip与host的对照表
    local ipAddr = {} --ip列表
    if type(hosts) == 'table' and #hosts > 0 then
        local tdomains = {}
        for index,val in pairs(hosts) do
            table.insert(tdomains, {domain = val, cname = true})
        end
        local dd = {appId = '6416',appKey='OBcwkefk',domains = tdomains}
        local jsonStr = json.encode(dd)
        if jsonStr then
            local function parseCallback(event)
                if event.event == 'state' then
                    local t = event.ips
                    local tt = json.decode(t)
                    for name,host in pairs(hosts) do
                        if checktable(tt)[host] then
                            --所有的的ip列表数据
                            for idx,ip in ipairs(tt[host]) do
                                table.insert(ipAddr, ip)
                                ipHostPair[tostring(ip)] = host --对照表
                            end
                        else
                            table.insert(ipAddr, host)
                            ipHostPair[tostring(host)] = host --对照表
                        end
                    end
                    if cb and type(cb) == 'function' then
                        cb(ipAddr, ipHostPair)
                    end
                elseif event.event == 'error' then
                    showAlert(__('警告'),__('传入的域名信息不能为空'),__('确定'))
                end
            end
            updater.parseDomains( jsonStr,parseCallback)
        else
            for name,host in pairs(hosts) do
                table.insert(ipAddr, host)
                ipHostPair[tostring(host)] = host --对照表
            end
            if cb and type(cb) == 'function' then
                cb(ipAddr, ipHostPair)
            end
        end
    end
end

function us:startUpdateRequest(  )
    local remoteResourcesInfo = updater.getRemotePackageInfo()
    local zipInfoUrl = remoteResourcesInfo.patchBaseURL
    local URL = require('cocos.cocos2d.URL')
    local t = URL.parse(zipInfoUrl)
    local lhost = t.host
    local hosts = {lhost}
    if remoteResourcesInfo.backupPatchBaseURL and string.find(remoteResourcesInfo.backupPatchBaseURL, 'http') then
        local n = URL.parse(remoteResourcesInfo.backupPatchBaseURL)
        table.insert(hosts, n.host)
    end
    -- startParseIp(hosts, function(ipAddr, ipHostPair)
    --是否需要备机的逻辑
    self.ipAddresses = hosts
    --记录所有可用的ips地址列表
    -- table.insert( self.ipAddresses )
    -- ipHostPair['116.62.185.117'] = lhost
    -- self.ipHostPair = ipHostPair
    --然后开始下载zip包
    appFlyerEventTrack("DownloadStart",{af_event_start = "downloadStart"})
    self:startDownloadZIP()
    -- end)
end

function us:startDownloadZIP()
    --先验证是否可达如果可达再下载
    local targetHost = self.ipAddresses[self.startIndex]
    if targetHost then
        if not DotGameEvent then
            DotGameEvent = require("root.DotGameEvent")
        end
        DotGameEvent.SendEvent(DotGameEvent.EVENTS.FISRT_LOADING)
        --如果当前ip地址可达时直接下载更新包逻辑
        updater.update(handler(self, self._updateHandler), targetHost, targetHost)
    else
        device.showAlert(__('警告'),__('当前网络不可用，不能进入游戏~~'),__('确定'))
    end
end


function us:Traceroot(host)
    local SDK_CLASS_NAME = "TracerootSDK"
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == 3 then
        SDK_CLASS_NAME = 'com.duobaogame.summer.TracerootSDK'
    end
    if target ~= 0 then
        --执行调用的逻辑
        if target == 2 or target == 4 or target == 5 then
            LuaObjcBridge.callStaticMethod(SDK_CLASS_NAME, "addScriptListener", {listener = handler(self, self.UploadExceptionLog)})
            LuaObjcBridge.callStaticMethod(SDK_CLASS_NAME, "traceroot", {host = host})
        elseif target == 3 then -- android
            LuaJavaBridge.callStaticMethod(SDK_CLASS_NAME, "addScriptListener", {TraceInvoke}, "(I)V")
            LuaJavaBridge.callStaticMethod(SDK_CLASS_NAME, "traceroot", {host}, "(Ljava/lang/String;)V")
        end
    end
end
--[[
--出现下载失败的情况下要执行traceroot的逻辑请求
--@host 要解析出来ip或域名的来着
--]]
function us:UploadExceptionLog()
    local fileUtils = cc.FileUtils:getInstance()
    local filePath = fileUtils:getWritablePath() .. 'log/trace.log'
    if fileUtils:isFileExist(filePath) then
        local content = FTUtils:getFileDataWithoutDec(filePath)
        if content then content = CCCrypto:encodeBase64Lua(content, string.len(content)) end
        if content then
            local updateURL = table.concat({'http://',Platform.ip,'/User/exceptionLog'},'')
            if USE_SSL then
                updateURL = table.concat({'https://',Platform.ip,'/User/exceptionLog'},'')
            end
            local baseversion = FTUtils:getAppVersion()
            local t = FTUtils:getCommParamters({channelId = Platform.id,appVersion=baseversion})
            t.exceptionLog = content
            if DEBUG > 0 then
                dump(t)
            end
            local zlib = require('zlib')
            local tData = json.encode(t)
            local compressed = zlib.deflate(5, 15 + 16)(tData, "finish")
            local ret = tabletourlencode(t)
            local xhr = cc.XMLHttpRequest:new()
            xhr.responseType = 4
            local app = cc.Application:getInstance()
            local target = app:getTargetPlatform()
            xhr:setRequestHeader("User-Agent", table.concat({CCNative:getOpenUDID(),baseversion,CCNative:getDeviceName(),target}, ";"))
            xhr:setRequestHeader('Content-Type', 'application/json')
            -- xhr:setRequestHeader("Host",tostring(Platform.serverHost))
            xhr.timeout = 60
            xhr:open("POST",updateURL)
            xhr:registerScriptHandler(function()
                if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
                    --上传文件的信息，成功后将文件删除
                    FTUtils:deleteFile(filePath)
                end
            end)
            xhr:send(compressed)
        end
    end
end

--[[
--显示重试弹出窗口
--]]
function us:createRetryView(text, isCheckUpdate)
    local view = self:getChildByName("RetryDownloader")
    if not view then
        local size = cc.size(592, 512)
        view = CLayout:create(size)
        display.commonUIParams(view, {po = display.center})
        view:setName("RetryDownloader")
        local bg = display.newImageView(_res("update/common_bg_2"),296, 256)
        bg:setScale(0.8)
        view:addChild(bg)

        local descrLabel = display.newLabel(296, 276, {
            fontSize = 26, color = '6c6c6c', text = tostring(text),
            w = 540
            })
        descrLabel:setName("LABEL")
        view:addChild(descrLabel, 1)

        local okButton = display.newButton(296, 64, {
                n = _res('update/common_btn_orange'),
                s = _res('update/common_btn_orange'),
                cb = function(sender)
                    --重新下载资源
                    view:setVisible(false)
                    self.viewData.loadingTipsLabel:setString(__('开始检测更新中，请稍后...'))
                    self:UpdateRequest() --重试user/update
                end
            })
        display.commonLabelParams(okButton, {fontSize = 28, text = __('重试'), color = "4c4c4c"})
        view:addChild(okButton, 2)
        self:addChild(view, 100)
    end
    view:setVisible(true)
end


function us:UpdateRequest()
    local serverIp = Platform.serverHost
    local lresinfo  = updater.getLocalResInfo()
    local ipLen = #self.userUpdateIps
    if ipLen > 0 then
        serverIp = self.userUpdateIps[self.tryNum]
        Platform.ip = serverIp
    else
        Platform.ip = serverIp
    end
    local updateURL = table.concat({'http://',serverIp,'/User/update/t/',os.time()},'')
    if USE_SSL and (not FOR_REVIEW) then
        updateURL = table.concat({'https://',serverIp,'/User/update/t/',os.time()},'')
    end
    funLog(Logger.DEBUG, "updateURL " .. updateURL)
    local cversion = lresinfo.version
    local baseversion = FTUtils:getAppVersion()
    local t = FTUtils:getCommParamters({channelId = Platform.id,version=cversion,appVersion=baseversion, lang = i18n.getLang()})
    if DEBUG > 0 then
        dump(t)
    end
    if not EVENTLOG then
        EVENTLOG = require('root.EventLog')
    end
    local ret = tabletourlencode(t)
    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = 0
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    xhr:setRequestHeader("User-Agent", table.concat({CCNative:getOpenUDID(),baseversion,CCNative:getDeviceName(),target}, ";"))
    -- xhr:setRequestHeader("Host",tostring(Platform.serverHost))
    xhr.timeout = 8 -- 8秒超时
    xhr:open("POST",updateURL)
    xhr:registerScriptHandler(function()
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            local responseStr = xhr.response
            local reslua = json.decode(responseStr)
            if reslua then
                if checkint(reslua.errcode) == 0 and reslua.data and reslua.data.version and string.len(reslua.data.version) > 0 then
                    self:promoteDownload(reslua.data)
                else
                    EVENTLOG.Log(EVENTLOG.EVENTS.update, {action = 'userUpdate', errmsg = tostring(responseStr),status = tostring(xhr.status), readyState = tostring(xhr.readyState)})
                    self:createRetryView(string.fmt(__('检测更新返回数据格式不正确_error_~~server'), {_error_ = string.urldecode(responseStr)}))
                    self.viewData.loadingTipsLabel:setString(string.fmt(__('检测更新返回数据格式不正确_error_~~'), {_error_ = string.urldecode(responseStr)}))
                end
            else
                EVENTLOG.Log(EVENTLOG.EVENTS.update, {action = 'userUpdate', errmsg = tostring(responseStr),status = tostring(xhr.status), readyState = tostring(xhr.readyState)})
                self:createRetryView(string.fmt(__('检测更新返回数据格式不正确_error_~~data'), {_error_ = string.urldecode(responseStr)}))
                self.viewData.loadingTipsLabel:setString(string.fmt(__('检测更新返回数据格式不正确_error_~~'), {_error_ = string.urldecode(responseStr)}))
            end
        else
            -- EVENTLOG.Log(EVENTLOG.EVENTS.update, {action = 'userUpdate', status = tostring(xhr.status), readyState = tostring(xhr.readyState)})
            self.tryNum = self.tryNum + 1
            if self.tryNum > ipLen then
                self.tryNum = 1 --回归1 然后显示重试窗口
                self:createRetryView(__('当前网络不可用，不能进入游戏~~') .. tostring(xhr.status))
                EVENTLOG.Log(EVENTLOG.EVENTS.update, {action = 'userUpdate', status = tostring(xhr.status), readyState = tostring(xhr.readyState),msg = tostring(xhr.response)})
                self.viewData.loadingTipsLabel:setString(__('当前网络不可用，不能进入游戏~~'))
            else
                self:UpdateRequest()
            end
        end
    end)
    xhr:send(ret)

end
--[[ [> ]]
-- --出现下载失败的情况下要执行traceroot的逻辑请求
-- --@host 要解析出来ip或域名的来着
-- --]]
-- function us:UserActivation()
    -- local shareUserDefault = cc.UserDefault:getInstance()
    -- local isSuccess = shareUserDefault:getBoolForKey('User_activiation', false)
    -- if not isSuccess then
        -- local updateURL = table.concat({'http://',Platform.ip,'/User/activation'},'')
        -- if USE_SSL then
            -- updateURL = table.concat({'https://',Platform.ip,'/User/activation'},'')
        -- end
        -- local baseversion = FTUtils:getAppVersion()
        -- local t = FTUtils:getCommParamters({channelId = Platform.id,appVersion=baseversion})
        -- t.exceptionLog = content
        -- if DEBUG > 0 then
            -- dump(t)
        -- end
        -- local ret = tabletourlencode(t)
        -- local xhr = cc.XMLHttpRequest:new()
        -- xhr.responseType = 4
        -- local app = cc.Application:getInstance()
        -- local target = app:getTargetPlatform()
        -- xhr:setRequestHeader("User-Agent", table.concat({CCNative:getOpenUDID(),baseversion,CCNative:getDeviceName(),target}, ";"))
        -- -- xhr:setRequestHeader("Host",tostring(Platform.serverHost))
        -- xhr.timeout = 60
        -- xhr:open("POST",updateURL)
        -- xhr:registerScriptHandler(function()
            -- if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
                -- --成功激活后写缓存标识
                -- shareUserDefault:setBoolForKey('User_activiation', true)
                -- shareUserDefault:flush()
            -- end
        -- end)
        -- xhr:send(ret)
    -- end
-- end


--[[--
开始检测更新
--]]
function us:_checkUpdate()
    --开始更新逻辑
    -- self:UserActivation()
    self.viewData.colorView:setVisible(true)
    local lresinfo  = updater.getLocalResInfo()
    if lresinfo then
        self.viewData.lversionLabel:setString(lresinfo.version)
        self.viewData.loadingTipsLabel:setString(__('开始检测更新中，请稍后...'))
        --[[ startParseIp({Platform.serverHost}, function(ipAddr, ipHostPair) ]]
            -- -- if not ipAddr then ipAddr = {} end
            -- -- if table.nums(ipAddr) > 0 then
            -- -- serverIp = ipAddr[1]
            -- -- Platform.ip = ipAddr[1] --固定的接口ip地址
            -- -- else
            -- -- Platform.ip = Platform.serverHost
            -- -- end
            -- local isBreakChannel   = false
            -- local breakChannelList = { Test, Android, PreIos, PreAndroid }
            -- for _, channelId in ipairs(breakChannelList) do
                -- if channelId == Platform.id then
                    -- isBreakChannel = true
                    -- break
                -- end
            -- end
            -- if not isBreakChannel then
            -- end
            -- self.userUpdateIps = ipAddr --用户检测更新所使用的ip列表
            -- self:UpdateRequest()
        --[[ end) ]]
        self.userUpdateIps = {Platform.serverHost}--用户检测更新所使用的ip列表
        self:UpdateRequest()
    end
    appFlyerEventTrack("CheckUpdate",{af_event_start = "checkUpdate"})
    --判断是否是否有上次的文件进行上传的逻辑
    self:UploadExceptionLog()
end
--[[
--提示是否有更新包相关的版本对比
--]]
function us:promoteDownload( reslua )
    -- local tt = [[
    --     {"data":{"appVersion":"1.0.0","version":"1.0.92","updateContent":["xxxxx","yyyyy"],"isReview":false,"patchBaseURL":"http://update.duobaogame.com/food/patches1","patches":{"1.0.8":712007},"isMaintain":false,"needRestart":false},"errcode":0,"errmsg":"","rand":"57ea49ca2d71b1474972106","sign":"c961d3b05706af9bf7b9210a2ad05643"}
    -- ]]
    -- reslua = json.decode(tt).data
    _G["FOR_REVIEW"] = reslua.isReview
    if reslua.isMaintain and reslua.isMaintain == true then
        --停机维护状态
        self.viewData.colorView:setVisible(false)
        updater.maintainServer(reslua)
        local warningView = CreateTipsWindow()
        display.commonUIParams(warningView.view,{po = cc.p(display.width * 0.5,display.height * 0.5)})
        self:addChild(warningView.view, 6)
    else
        local result = updater.checkUpdate(reslua)
        local remoteResInfo = updater.getRemotePackageInfo()
        self.viewData.versionLabel:setString(tostring(remoteResInfo.version))
        if result == true then
            --- 如果存在新版本，出提示
            local dsize = updater.getNeededDownloadSize()
            if not EVENTLOG then
                EVENTLOG = require('root.EventLog')
            end
            EVENTLOG.Log(EVENTLOG.EVENTS.update, {size = dsize})
            local warningView = CreateTipsWindow(dsize)
            display.commonUIParams(warningView.view,{po = cc.p(display.width * 0.5,display.height * 0.5)})
            self:addChild(warningView.view, 6)
            if warningView.startDownButton then
                warningView.startDownButton:setOnClickScriptHandler(function ( sender )
                    sender:setEnabled(false)
                    sender:setVisible(false)
                    warningView.view:setVisible(false)
                    --开始解析ip地址并显示下载进度条
                    self.viewData.loadingTipsLabel:setString(__('准备下载游戏资源，请耐心等待...'))
                    self:startUpdateRequest()--开始解析ip并下载zip
                end)
            end
        elseif result == nil then
            self.viewData.loadingTipsLabel:setString(__('检测更新版本比对失败~~'))
        elseif result == false then
            --无更新直接回调
            --播一个动画再进入游戏
            self.viewData.loadingTipsLabel:setString(__('检测游戏更新完成'))
            if us._succHandler then
                us._succHandler()
            end
            self.viewData.colorView:setVisible(false)

            --[[
            local function inVokeAction()
                self.viewData.loadingBar:setValue(100)
                -- local percent = event.progress * 0.01
                local percent = 100
                self.viewData.loadingBarShine:setPositionX(
                self.viewData.loadingBar:getPositionX() - self.viewData.loadingBar:getContentSize().width * 0.5 +
                self.viewData.loadingBar:getContentSize().width * percent - 1)
            end
            local action = cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function()
                inVokeAction()
            end),
            cc.DelayTime:create(0.1),cc.CallFunc:create(function()
                self.viewData.loadingTipsLabel:setString(__('检测游戏更新完成'))
                if us._succHandler then
                    us._succHandler()
                end
                self.viewData.colorView:setVisible(false)
            end))
            self:runAction(action)
            --]]
        end
    end
end

function us:_updateHandler(event)
    local state = event.event
    if state == 'success' then
        -- local stateValue = __('正在合并资源请耐心等待...')
        appFlyerEventTrack("DownloadSuccess",{af_event_start = "DownloadSuccess"})
        updater.updateFinalResInfo()
        self.viewData.colorView:setVisible(false)
        self:UserUpdateEventAction("/User/updateEnd")
        if not DotGameEvent then
            DotGameEvent = require("root.DotGameEvent")
        end
        DotGameEvent.SendEvent(DotGameEvent.EVENTS.FINISH_LOADING)
        if us._succHandler then
            us._succHandler()
        end
    elseif state == 'progress' then
        local total = tonumber(event.total,10)
        local progress = tonumber(event.progress,10)
        if total > 0 then
            self.viewData.loadingBar:setValue((progress / total) * 100)
            local str = string.format('%.1f %%',(progress / total) * 100)
            local percent = progress * 0.01
            self.viewData.loadingBarShine:setPositionX(
            self.viewData.loadingBar:getPositionX() - self.viewData.loadingBar:getContentSize().width * 0.5 +
            self.viewData.loadingBar:getContentSize().width * percent - 1)
            self.viewData.loadingTipsLabel:setString(string.fmt(__("资源下载进度_pro_"),{_pro_ = str}))
            if total > 1024 then
                if progress >= 1024 then
                    self.viewData.progressTipsLabel:setString(string.format(__("正在下载%sk/%sk"),tostring(math.floor(progress/1024)), tostring(math.floor(total / 1024))))
                else
                    self.viewData.progressTipsLabel:setString(__("正在下载100K以下"))
                end
            end
        end
    elseif event.event == 'state' then
        local msg = event.msg
        local stateValue = nil
        if msg == 'downloadStart' then
            stateValue = __('开始下载更新...') .. tostring(self.downloadNo)
        elseif msg == 'downloadDone' then
            stateValue = __('更新包下载完成...')
            EVENTLOG.Log(EVENTLOG.EVENTS.updateSuccessful)
        elseif msg == 'uncompressStart' then
            stateValue = __('开始解压...')
            self.viewData.loadingBar:setValue(100)
            self.viewData.loadingBarShine:setPositionX(
            self.viewData.loadingBar:getPositionX() - self.viewData.loadingBar:getContentSize().width * 0.5 +
            self.viewData.loadingBar:getContentSize().width - 1)
        elseif msg == 'uncompressDone' then
            stateValue = __('解压完成...')
        else
            stateValue = tostring(event.msg)
        end
        self.viewData.loadingTipsLabel:setString(tostring(stateValue))
    elseif state == 'error' then
        ---解压失败后将下载删除，以便下次进入重新下载新patch
        EVENTLOG.Log(EVENTLOG.EVENTS.updateFailed)
        if event.msg then
            ---各类异常消息处理
            local lmsg = tostring(event.msg)
            local clientMsg = ''
            if lmsg == 'errorCreateFile' then
                clientMsg = __('创建文件失败')
            elseif lmsg == 'errorNetwork' then
                clientMsg = __('网络出现异常')
            elseif lmsg == 'errorNetworkUpdateMd5' then
                clientMsg = __('检测更新网络出现异常')
            elseif lmsg == 'errorCurlInit' then
                clientMsg = __('检测更新初始化失败')
            elseif lmsg == 'errorNetworkDownload' then
                clientMsg = __('下载更新包网络出现异常')
            elseif lmsg == 'errorUncompress' then
                clientMsg = __('更新包解压失败')
                updater.removePatchZip()--保证可以删除不需要的zip
            elseif lmsg == 'errorUnknown' then
                clientMsg = __('更新出现未知错误')
            end
            if event.vividMsg then
                clientMsg = string.format('%s%s',clientMsg,tostring(event.vividMsg))
                wwritefile(clientMsg)
            end
            self.viewData.loadingTipsLabel:setString(clientMsg)
            EVENTLOG.Log(EVENTLOG.EVENTS.updateFailed,{errmsg = clientMsg})
        else
            EVENTLOG.Log(EVENTLOG.EVENTS.updateFailed)
        end

        --开始分析host
        local curIp = self.ipAddresses[self.startIndex]
        wwritefile(curIp)
        -- updater.removePatchZip()--保证可以删除不需要的zip
        if self.traceHost then
            self:Traceroot(tostring(curIp))
        end
        self.startIndex = self.startIndex + 1
        if checkint(self.startIndex) <= table.nums(self.ipAddresses) then
            self:startDownloadZIP()
        else
            --最终才去上传防止阻挡下一个数据进行
            self.traceHost = false
            self.startIndex = 1
            self.downloadNo = self.downloadNo + 1
            --再重试下载
            self:startDownloadZIP()
        end
    end
--    assert(event.event ~= "error",
--        string.format("Update error: %s !", updater.stateValue))
end

function us.addListener(handler)
    us._succHandler = handler
    return us
end

function us:onEnter()
    if KEYBOARD_LOGIN_NOTICE then
        local layer = cc.Layer:create()
        layer:setKeyboardEnabled(true)
        layer:setName("NOTICE_VIEW")
        self:addChild(layer, -100)
        local target = cc.Application:getInstance():getTargetPlatform()
        if target >= 2 and target < 6 then
            layer:registerScriptKeypadHandler(handler(self,self.KeyboardEvent))
        end
    end
end
function us:KeyboardEvent(callback)
    if callback ~= 'menuClicked' then
        local view = self:getChildByName("SCROLL_VIEW")
        local layer = self:getChildByName("NOTICE_VIEW")
        if layer then
            layer:unregisterScriptKeypadHandler()
        end
        if view:isVisible() then
            view:setVisible(false)
            if device.platform == 'ios' or device.platform == 'android' then
                local cview = view:getChildByName("CVIEW")
                if cview then
                    local webView = cview:getChildByName("WEBVIEW")
                    webView:setVisible(false)
                end
            end
            self:_checkUpdate()
        end
    end
end

function us:onExit()
    local layer = self:getChildByName("NOTICE_VIEW")
    if layer then
        layer:unregisterScriptKeypadHandler()
    end
end

function us:onCleanup()
    updater.clean()
    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    self:unregisterScriptHandler()
end


return us
