require('config')
require('cocos.init')

local sharedDirector         = cc.Director:getInstance()

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

local d = nil
local SUFFIX = '.tmp'

local writablePath = cc.FileUtils:getInstance():getWritablePath()--最终写入目录 /Documents/res/lua ui

local scheduler = require('cocos.framework.scheduler')

local function initDownloader()
     if not d then d = Updater:new() end
     -- print("after initUpdater:", d)
end

local function cleanUp()
    if d then
        d:unregisterScriptHandler()
        d:delete()
        d = nil
    end
end


local Downloader = class('Downloader',function()
    local ret =  CLayout:create(display.size)
    ret.name = 'Downloader'
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
    BG                  = "update/update_bg.png",
    BTN_NORMAL          = "update/common_btn_orange.png",
    BTN_PRESS           = "update/common_btn_orange_disable.png",
    Progress_Bg         = "update/update_bg_loading.png",
    Progress_Image      = "update/update_ico_loading.png",
    Progress_Top        = "update/update_ico_loading_fornt.png",
    Progress_Descr      = "update/update_bg_refresh_number.png",
    Dialog_Bg           = "update/common_bg_2.png",
    MINI_PROGRESS_IMG   = 'ui/home/home/main_bg_download_data_loading.png',
    MINI_PROGRESS_BG    = 'ui/home/home/main_bg_download_data.png',
    MINI_DOWNLOAD_ARROW = 'ui/home/home/main_ico_download_data_arrow.png',
    MINI_DOWNLOAD_SLOT  = 'ui/home/home/main_ico_download_data.png',
}

local function createRequest( updateURL, callback,data)
    -- print(updateURL)
    local baseversion = FTUtils:getAppVersion()
    local t = FTUtils:getCommParamters({channelId = Platform.id,appVersion=baseversion})
    local preVersion = cc.UserDefault:getInstance():getStringForKey('UPDATE_SUB_VERSION')
    if preVersion then
        t["preVersion"] = preVersion
    end
    local ret = tabletourlencode(t)
    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = 4
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    xhr:setRequestHeader("User-Agent", table.concat({CCNative:getOpenUDID(),baseversion,CCNative:getDeviceName(),target}, ";"))
    -- xhr:setRequestHeader("Host",Platform.serverHost)
    xhr.timeout = 30
    xhr:open("POST",updateURL)
    xhr:registerScriptHandler(function()
        local data = {success = 0}
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            local responseStr = xhr.response
            data.success = 1
            data.response = responseStr
        end
        callback(data)
    end)
    xhr:send(ret)
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

function Downloader:getURLBack(event)
    local isSuccess = checkint(event.success)
    local responseStr = event.response
    if responseStr then
        local reslua = json.decode(responseStr)
        if reslua then
            if checkint(reslua.errcode) == 0 then
                isSuccess = 1
                local backUrl = (reslua.data.url or '')
                if string.find(backUrl, ";") then
                    self.ips = string.split(backUrl, ";")
                    self.zipUrl = self.ips[1] --第一个地址
                else
                    self.zipUrl = backUrl
                end
                self.zipUrl:gsub('%?(.*)', function(v)
                    self.totalBytes = tonumber(v,10)
                end)
                self.zipmd5 = (reslua.data.md5 or '')
                self:startDownloadPackage(self.zipUrl)
            else
                if self.isDownloadRes_ then
                    self:updateProgressTips_(string.fmt(__('检测资源返回数据格式不正确_msg_~~'),{_msg_ = tostring(responseStr)}))
                else
                    self:updateProgressTips_(string.fmt(__('检测更新返回数据格式不正确_msg_~~'),{_msg_ = tostring(responseStr)}))
                end
                if self.viewData.retryBtn then
                    self.viewData.retryBtn:setVisible(true)
                end
                if self.viewData.closeArea then
                    self.viewData.closeArea:setVisible(true)
                end
            end
        else
            if self.isDownloadRes_ then
                self:updateProgressTips_(string.fmt(__('检测资源返回数据格式不正确_msg_~~'),{_msg_ = tostring(responseStr)}))
            else
                self:updateProgressTips_(string.fmt(__('检测更新返回数据格式不正确_msg_~~'),{_msg_ = tostring(responseStr)}))
            end
            if self.viewData.retryBtn then
                self.viewData.retryBtn:setVisible(true)
            end
            if self.viewData.closeArea then
                self.viewData.closeArea:setVisible(true)
            end
        end
    else
        isSuccess = 0
    end
    if isSuccess == 0 then
        self:updateProgressTips_(__('当前网络可能不可用，请稍后重试~~'))
        if self.viewData.retryBtn then
            self.viewData.retryBtn:setVisible(true)
        end
        if self.viewData.closeArea then
            self.viewData.closeArea:setVisible(true)
        end
    end
end

local lfs = require"lfs"

--[[
    --计算目录的属性信息
    --]]
function caculateDirSize(path)
    local sum = 0
    local function _rmdir(path)
        if path then
            local iter, dir_obj = lfs.dir(path)
            while true do
                local dir = iter(dir_obj)
                if dir == nil then break end
                if dir ~= "." and dir ~= ".." then
                    local curDir = path..dir
                    local mode = lfs.attributes(curDir, "mode")
                    if mode == "directory" then
                        _rmdir(curDir.."/")
                    elseif mode == "file" then
                        local size = lfs.attributes(curDir, "size")
                        sum = sum + size
                    end
                end
            end
        end
        return sum
    end
    return _rmdir(path)
end

function Downloader:ctor(allDoneCallback, isDownloadRes, isMiniMode)
    self.isDownloadRes_   = isDownloadRes == true
    self.allDoneCallback_ = allDoneCallback
    self.isMiniMode_      = isMiniMode == true
    self.ipIndx = 1
    self.tryNum = 1
    self.ips = {}
    self.totalBytes = 0
    self.startBytes = 0;
    self.uncompressUpdateFun = nil
    self.isStart = false --开始解压的标志

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

        local retryBtn = display.newButton(display.SAFE_R - 200, 60, {n = _res(DICT.BTN_NORMAL)})
        display.commonLabelParams(retryBtn, {fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#734441', text = __('重试')})
        retryBtn:setVisible(false)
        self:addChild(retryBtn)

        return {
            loadingBar = loadingBar,
            loadingBarShine = loadingBarShine,
            loadingTipsLabel = loadingTipsLabel,
            progressTipsLabel = progressTipsLabel,
            retryBtn = retryBtn,
        }
    end

    local function CreateMiniView()
        local view = display.newLayer()
        self:addChild(view)

        local loadingPos = cc.p(display.SAFE_R - 200, 15)
        local loadingBar = CProgressBar:create(_res(DICT.MINI_PROGRESS_IMG))
        loadingBar:setBackgroundImage(_res(DICT.MINI_PROGRESS_BG))
        loadingBar:setPosition(loadingPos)
        loadingBar:setDirection(0)
        loadingBar:setMaxValue(100)
        loadingBar:setValue(0)
        view:addChild(loadingBar)

        local loadingLabel = display.newLabel(loadingPos.x, loadingPos.y, {text = '', fontSize = 20, color = '#00b9bb', hAlign = display.TAC, ttf = true, font = TTF_GAME_FONT})
        view:addChild(loadingLabel)

        local loadingIconPos   = cc.p(loadingPos.x - 175, loadingPos.y)
        local loadingIconSlot  = display.newImageView(_res(DICT.MINI_DOWNLOAD_SLOT), loadingIconPos.x, loadingIconPos.y - 6)
        local loadingIconArrow = display.newImageView(_res(DICT.MINI_DOWNLOAD_ARROW), loadingIconPos.x, loadingIconPos.y + 2)
        view:addChild(loadingIconSlot)
        view:addChild(loadingIconArrow)
        loadingIconArrow:runAction(cc.RepeatForever:create(cc.JumpBy:create(0.8, cc.p(0,0), 6, 1)))

        local closeArea = display.newLayer(loadingPos.x, loadingPos.y, {size = loadingBar:getContentSize(), color = cc.r4b(0), ap = display.CENTER, enable = true})
        view:addChild(closeArea)
        closeArea:setVisible(false)

        return {
            closeArea    = closeArea,
            loadingBar   = loadingBar,
            loadingLabel = loadingLabel,
        }
    end

    if self.isMiniMode_ then
        self.viewData = CreateMiniView()
    else
        self.viewData = CreateView()
    end
    local function updateRequest()
        if not self.isDownloadRes_ and SHOW_LAUNCH_LOGO then
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

    if self.viewData.retryBtn then
        display.commonUIParams(self.viewData.retryBtn, {cb = function(sender)
            self.viewData.retryBtn:setVisible(false)
            updateRequest()
        end})
    end

    if self.viewData.closeArea then
        display.commonUIParams(self.viewData.closeArea, {cb = function(sender)
            if self.errorCallback_ then
                self.errorCallback_()
            end
        end})
    end


    if checkint(Platform.id) == EfunAndroid or checkint(Platform.id) == EfunIos then
        CCVideoView:play('res/efun_launcher.mp4',function()
            updateRequest()
        end)
    else
        updateRequest()
    end


    if not self.uncompressUpdateFun then
        local sub_path = writablePath .. "res_sub/"
        self.uncompressUpdateFun = scheduler.scheduleGlobal(function()
            if self.isStart then
                local curBytes = caculateDirSize(sub_path)
                local progress = curBytes - self.startBytes
                if progress > 0 and self.totalBytes > 0 then
                    self:updateUncompressProgress_(progress, self.totalBytes)
                end
            end
        end,1)
    end
end

function Downloader:setAllDoneCallback(callback)
    self.allDoneCallback_ = callback
end
function Downloader:setErrorCallback(callback)
    self.errorCallback_ = callback
end

function Downloader:updateProgressTips_(text)
    if self.viewData.progressTipsLabel then
        self.viewData.progressTipsLabel:setString(tostring(text))
    end
    if self.viewData.loadingLabel then
        self.viewData.loadingLabel:setString(tostring(text))
    end
end
function Downloader:updateLoadingTips_(text)
    if self.viewData.loadingTipsLabel then
        self.viewData.loadingTipsLabel:setString(tostring(text))
    end
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

--[[--
开始检测更新
--]]
function Downloader:_checkUpdate()
    --开始更新逻辑
    cleanUp()
    initDownloader()
    self:stoptManualUpdateDownloadProgress_()
    --横测看是否obb是否存在的逻辑
    if checkint(Platform.id) == KoreanAndroid or checkint(Platform.id) == KoreanIos then
        local url = table.concat({'https://',Platform.serverHost,'/User/downloadBefore'},'')
        createRequest(url,handler(self,self.getURLBack))

    elseif checkint(Platform.id) == JapanAndroid or checkint(Platform.id) == JapanIos then
        local url = table.concat({'http://',Platform.serverHost,'/User/downloadBefore'},'')
        createRequest(url,handler(self,self.getURLBack))

    else
        -- if device.platform == 'android' then
        -- if self.isDownloadRes_ then
        -- local url = table.concat({'http://',Platform.serverHost,'/User/downloadBefore'},'')
        -- createRequest(url,handler(self,self.getURLBack))
        -- else
        -- luaj.callStaticMethod("com.duobaogame.summer.ObbDownloader", "addScriptListener", {handler(self, self.AndroidEvent)})
        --检测obb的状态的逻辑
        -- luaj.callStaticMethod("com.duobaogame.summer.ObbDownloader",'StartGoogleObb',{})
        -- end
        -- else
        --cdn地址
        local url = table.concat({'http://',Platform.serverHost,'/User/downloadBefore'},'')
        createRequest(url,handler(self,self.getURLBack))
        -- end
    end

    appFlyerEventTrack("SubpackageDownloadBefore",{af_event_start = "SubpackageDownloadBefore"})
    local EventLog = require('root.EventLog')
    EventLog.Log("package")
    -- TODO debug
end


function Downloader:AndroidEvent(event)
    event = json.decode(event)
    local state = event.state
    if state == 'startUncompress' then
        --obb存在开始解压的逻辑
        local obbPath = event.sourcePath
        local ures = (writablePath .. 'res_sub/')
        local shareFileUtils = cc.FileUtils:getInstance()
        if not shareFileUtils:isFileExist(ures) then
            shareFileUtils:createDirectory(ures)
        end

        -- local ures = (writablePath .. 'res/')
        d:registerScriptHandler(handler(self, self.obbUncompressEvent))
        d:startUncompress(obbPath, ures, false)
    elseif state == 'startService' then
        --obb不存在时开启下载服务
        self:updateProgressTips_(__('obb下载服务已开始，开始下载中..'))
    elseif state == 'downloadProgress' then
        --下载的进度显示的逻辑
        local total = tonumber(event.total,10)
        local progress = tonumber(event.progress,10)
        self.viewData.loadingBar:setValue((progress / total) * 100)
        local str = string.format('%.1f %%',(progress / total) * 100)
        local percent = progress * 0.01
        if self.viewData.loadingBarShine then
            self.viewData.loadingBarShine:setPositionX(
                self.viewData.loadingBar:getPositionX() - self.viewData.loadingBar:getContentSize().width * 0.5 +
                self.viewData.loadingBar:getContentSize().width * percent - 1
            )
        end
        self:updateLoadingTips_(string.format(__("资源下载进度%s"),str))
        self:updateProgressTips_(string.format(__("正在下載%sM/%sM"),tostring(math.floor(progress/1024/1024)), tostring(math.floor(total / 1024/1024))))
    elseif state == 'stateChanged' then
        --状态变化可能会成功的逻辑在其中
        local newState = checkint(event.newState)
        if newState == 5 then
            --obb下载完成，开始解压的逻辑
            local obbPath = event.sourcePath
            -- local ures = (writablePath .. 'res/')
            local ures = (writablePath .. 'res_sub/')
            local shareFileUtils = cc.FileUtils:getInstance()
            if not shareFileUtils:isFileExist(ures) then
                shareFileUtils:createDirectory(ures)
            end
            d:registerScriptHandler(handler(self, self.obbUncompressEvent))
            d:startUncompress(obbPath, ures, false)
        elseif newState >= 6 then
            self:updateProgressTips_(string.fmt(__('下载obb遇到问题请稍后重试[_num_]'), { _num_ = newState}))
        end
    end
end

--[[
--obb解压的回调的逻辑
--]]
function Downloader:obbUncompressEvent(event)
    local state = event.event
    local stateValue = ''
    if state == 'success' then
        stateValue = __('解压完成...')
        self:updateProgressTips_(stateValue)
        --写入更新完的标识
        cc.UserDefault:getInstance():setBoolForKey('AndroidGoogleObbUpgrade' .. tostring(FTUtils:getAppVersion()), true)
        cc.UserDefault:getInstance():flush()
        --然后进入更新游戏界面
        cc.LuaLoadChunksFromZIP("res/lib/update.zip")
        require("update.UpdateApp").new("update"):run(true)
        self:runAction(cc.Sequence:create(cc.Hide:create(), cc.RemoveSelf:create()))
    elseif state == 'state' then
        local msg = event.msg
        if msg == 'downloadStart' then
            stateValue = __('开始下载更新...')
        elseif msg == 'downloadDone' then
            stateValue = __('更新包下载完成...')
        elseif msg == 'uncompressStart' then
            stateValue = __('开始解压...')

            -- self.viewData.loadingBar:setValue(100)
            -- if self.viewData.loadingBarShine then
            -- self.viewData.loadingBarShine:setPositionX(
                -- self.viewData.loadingBar:getPositionX() - self.viewData.loadingBar:getContentSize().width * 0.5 +
                -- self.viewData.loadingBar:getContentSize().width - 1)
            -- end
        elseif msg == 'uncompressProgress' then
            --解压进度
            local progress = tonumber(event.progress,10)
            self.viewData.loadingBar:setValue(math.floor(progress * 100))
            local str = string.format('%.1f %%',progress* 100)
            local percent = progress * 0.01
            if self.viewData.loadingBarShine then
                self.viewData.loadingBarShine:setPositionX(
                    self.viewData.loadingBar:getPositionX() - self.viewData.loadingBar:getContentSize().width * 0.5 +
                    self.viewData.loadingBar:getContentSize().width * percent - 1)
            end
        elseif msg == 'uncompressDone' then
            stateValue = __('正在合并资源请耐心等待...')
        else
            stateValue = tostring(event.msg)
        end
        self:updateProgressTips_(stateValue)
    elseif state == 'error' then
        if event.msg then
            ---各类异常消息处理
            local lmsg = tostring(event.msg)
            local clientMsg = ''
            if lmsg == 'errorCreateFile' then
                clientMsg = __('create file failed')
            elseif lmsg == 'errorNetwork' then
                clientMsg = __('network error')
            elseif lmsg == 'errorNetworkUpdateMd5' then
                clientMsg = __('检测更新网络出现异常')
            elseif lmsg == 'errorCurlInit' then
                clientMsg = __('检测更新初始化失败')
            elseif lmsg == 'errorNetworkDownload' then
                clientMsg = __('下载更新包网络出现异常')
            elseif lmsg == 'errorUncompress' then
                clientMsg = __('更新包解压失败')
                if device.platform == 'android' then
                    local allSize = cc.UserDefault:getInstance():getStringForKey("ANDROID_MEMOERY_SIZE")
                    if allSize then
                        clientMsg = clientMsg .. allSize
                    end
                end
            elseif lmsg == 'errorUnknown' then
                clientMsg = __('更新出现未知错误')
            end
            if event.vividMsg then
                clientMsg = string.format('%s%s',clientMsg,tostring(event.vividMsg))
            end
            self:updateProgressTips_(clientMsg)
        end
    end
end

local function isempty(s)
  return s == nil or s == ''
end

function Downloader:startDownloadPackage(url)
    --开始下载逻辑
    local preMd5 = cc.UserDefault:getInstance():getStringForKey("UPDATE_SUB_VERSION_MD5")
    if (not isempty(preMd5)) and (not isempty(self.zipmd5)) and preMd5 == self.zipmd5 then
        --此时表示没有可更新的内容直接进游戏
        if self.isDownloadRes_ then
            cc.UserDefault:getInstance():setBoolForKey('SubpackageRes_' .. tostring(FTUtils:getAppVersion()), true)
        else
            cc.UserDefault:getInstance():setBoolForKey('AndroidGoogleObbUpgrade' .. tostring(FTUtils:getAppVersion()), true)
        end
        cc.UserDefault:getInstance():setStringForKey('UPDATE_SUB_VERSION',tostring(FTUtils:getAppVersion()))
        if self.zipmd5 then
            cc.UserDefault:getInstance():setStringForKey('UPDATE_SUB_VERSION_MD5',self.zipmd5)
        end
        cc.UserDefault:getInstance():flush()
        --然后进入更新游戏界面
        cc.LuaLoadChunksFromZIP("res/lib/update.zip")
        require("update.UpdateApp").new("update"):run(true)
        self:runAction(cc.Sequence:create(cc.Hide:create(), cc.RemoveSelf:create()))
        appFlyerEventTrack("SubpackageDownloadEntrySuccess",{af_event_start = "SubpackageDownloadEntrySuccess"})
        local EventLog = require('root.EventLog')
        EventLog.Log("packageSuccessful")
    else
        local URL = require('cocos.cocos2d.URL')
        local t = URL.parse(tostring(url))
        self.downloadTotalByte_ = checkint(table.keys(t.query or {})[1])

        local resPath = tostring(t.path)
        local lastPos = 0
        for st, sp in function() return string.find(resPath, '/', lastPos, true) end do
            lastPos = sp + 1
        end
        local path = string.sub(resPath, 1, lastPos - 1)
        local name = string.sub(resPath, lastPos)
        self.downloadCachePath_ = writablePath .. name .. '.tmp'

        if url and string.len(url) > 0  then
            self:downloadURL(url,handler(self,self.downloadCallback))
        else
            if self.isDownloadRes_ then
                self:updateProgressTips_(__('获取资源下载地址不正确~~'))
            else
                self:updateProgressTips_(__('获取更新下载地址不正确~~'))
            end
            if self.viewData.retryBtn then
                self.viewData.retryBtn:setVisible(true)
            end
            if self.viewData.closeArea then
                self.viewData.closeArea:setVisible(true)
            end
        end
    end
end

function Downloader:downloadURL(url,handle)
    local URL = require('cocos.cocos2d.URL')
    local t = URL.parse(url)
    local fileName = FTUtils:lastPathComponent(t.path)
    if handle then
        d:registerScriptHandler(handle)
    end
    local uzip = (writablePath .. fileName)
    local ures = (writablePath .. 'res_sub/')
    local shareFileUtils = cc.FileUtils:getInstance()
    if not shareFileUtils:isFileExist(ures) then
        shareFileUtils:createDirectory(ures)
    end

    local needUnzip = 1
    local fmd5 = crypto.md5file(uzip)
    if fmd5 == self.zipmd5 then
        needUnzip = 0 --已下载完成
    end
    if needUnzip == 1 then
        appFlyerEventTrack("SubpackageDownloadStart",{af_event_start = "SubpackageDownloadStart"})
        d:update(url, uzip, ures, false)
    else
        d:startUncompress(uzip, ures, false)
    end
end

function Downloader:downloadCallback(event)
    if tolua.isnull(self) then return end
    local state = event.event
    local stateValue = ''
    local goNext = 0

    -- 下载并解压 成功
    if state == 'success' then
        local URL = require('cocos.cocos2d.URL')
        local t = URL.parse(self.zipUrl)
        local fileName = FTUtils:lastPathComponent(t.path)
        -- local fmd5 = crypto.md5file((writablePath .. fileName))
        -- if fmd5 ~= self.zipmd5 then
            --下载的文件失败不成功
            -- goNext = 1
            -- if self.isDownloadRes_ then
                -- stateValue = __('验证资源包网络出现异常...')
            -- else
                -- stateValue = __('验证更新包网络出现异常...')
            -- end
            -- self:updateProgressTips_(stateValue)
            --失败后删除zip的压缩包文件
            -- local URL = require('cocos.cocos2d.URL')
            -- local t = URL.parse(self.zipUrl)
            -- local fileName = FTUtils:lastPathComponent(t.path)
            -- local fmd5 = crypto.md5file((writablePath .. fileName))
            -- local zip_tmp = (writablePath .. fileName .. SUFFIX)
            -- local zip_zip = (writablePath .. fileName)
            -- local shareFileInstance = cc.FileUtils:getInstance()
            -- if shareFileInstance:isFileExist(zip_tmp) then
                -- FTUtils:deleteFile(zip_tmp)
            -- end
            -- if shareFileInstance:isFileExist(zip_zip) then
                -- FTUtils:deleteFile(zip_zip)
            -- end
            -- else
            if self.zipmd5 and string.len(self.zipmd5) > 0 then
                stateValue = __('解压完成...')
                self:updateProgressTips_(stateValue)
                --写入更新完的标识
                --delete file
                local zipfile = writablePath .. fileName
                FTUtils:deleteFile(zipfile)
                --写入完成标识
                if self.isDownloadRes_ then
                    cc.UserDefault:getInstance():setBoolForKey('SubpackageRes_' .. tostring(FTUtils:getAppVersion()), true)
                else
                    cc.UserDefault:getInstance():setBoolForKey('AndroidGoogleObbUpgrade' .. tostring(FTUtils:getAppVersion()), true)
                end
                cc.UserDefault:getInstance():setStringForKey('UPDATE_SUB_VERSION',tostring(FTUtils:getAppVersion()))
                if self.zipmd5 then
                    cc.UserDefault:getInstance():setStringForKey('UPDATE_SUB_VERSION_MD5',self.zipmd5)
                end
                cc.UserDefault:getInstance():flush()
                --

                appFlyerEventTrack("SubpackageDownloadUncompressSuccess",{af_event_start = "SubpackageDownloadUncompressSuccess"})
                if self.allDoneCallback_ then
                    self.allDoneCallback_()
                else
                    --然后进入更新游戏界面
                    cc.LuaLoadChunksFromZIP("res/lib/update.zip")
                    require("update.UpdateApp").new("update"):run(true)
                    self:runAction(cc.Sequence:create(cc.Hide:create(), cc.RemoveSelf:create()))
                    appFlyerEventTrack("SubpackageDownloadSuccess",{af_event_start = "SubpackageDownloadSuccess"})
                    local EventLog = require('root.EventLog')
                    EventLog.Log("packageSuccessful")
                end
            end
        -- end

    -- 下载进度
    elseif state == 'progress' then
        self:stoptManualUpdateDownloadProgress_()
        self:updateDownloadProgress_(event.progress, event.total)

    -- 下载/解压 状态
    elseif state == 'state' then
        local msg = event.msg
        if msg == 'downloadStart' then
            stateValue = __('开始下载更新...')
            if self.isDownloadRes_ then
                self:startManualUpdateDownloadProgress_()
            end
        elseif msg == 'downloadDone' then
            stateValue = __('更新包下载完成...')
            self.viewData.loadingBar:setValue(100)
            self:updateLoadingTips_(string.format(__("资源下载进度%s"),'100%'))
            self:stoptManualUpdateDownloadProgress_()
        elseif msg == 'uncompressStart' then
            stateValue = __('开始解压...')
            self.viewData.loadingBar:setValue(0)
            self.startBytes = caculateDirSize(writablePath .. "res_sub/")
            self.isStart = true
            if self.viewData.loadingBarShine then
                self.viewData.loadingBarShine:setPositionX(
                self.viewData.loadingBar:getPositionX() - self.viewData.loadingBar:getContentSize().width * 0.5 +
                self.viewData.loadingBar:getContentSize().width - 1)
            end
        elseif msg == 'uncompressDone' then
            self.isStart = false
            self.viewData.loadingBar:setValue(100)
            stateValue = __('正在合并资源请耐心等待...')
        else
            stateValue = tostring(event.msg)
        end
        self:updateProgressTips_(stateValue)

    -- 下载/解压 出错
    elseif state == 'error' then
         ---解压失败后将下载删除，以便下次进入重新下载新patch
        goNext = 1
        if event.msg then
            ---各类异常消息处理
            local lmsg = tostring(event.msg)
            local clientMsg = ''
            if lmsg == 'errorCreateFile' then
                clientMsg = __('create file failed')
            elseif lmsg == 'errorNetwork' then
                clientMsg = __('network error')
            elseif lmsg == 'errorNetworkUpdateMd5' then
                clientMsg = __('检测更新网络出现异常')
            elseif lmsg == 'errorCurlInit' then
                clientMsg = __('检测更新初始化失败')
            elseif lmsg == 'errorNetworkDownload' then
                clientMsg = __('下载更新包网络出现异常')
            elseif lmsg == 'errorUncompress' then
                clientMsg = __('更新包解压失败')
                local URL = require('cocos.cocos2d.URL')
                local t = URL.parse(self.zipUrl)
                local fileName = FTUtils:lastPathComponent(t.path)
                local zipfile = writablePath .. fileName
                FTUtils:deleteFile(zipfile)

                if device.platform == 'android' then
                    local allSize = cc.UserDefault:getInstance():getStringForKey("ANDROID_MEMOERY_SIZE")
                    if allSize then
                        clientMsg = clientMsg .. allSize
                    end
                end
            elseif lmsg == 'errorUnknown' then
                clientMsg = __('更新出现未知错误')
            end
            if event.vividMsg then
                clientMsg = string.format('%s%s',clientMsg,tostring(event.vividMsg))
            end
            self:updateProgressTips_(clientMsg)
        end
        if not isRecorded then
            isRecorded = true
            appFlyerEventTrack("SubpackageDownloadFailed",{af_event_start = "SubpackageDownloadFailed"})
        end
    end
    if goNext == 1 then
        if self.tryNum > 3 then
            if self.ips and next(self.ips) ~= nil then
                self.ipIndx = self.ipIndx + 1
                if self.ipIndx > table.nums(self.ips) then
                    self.ipIndx = 1
                    self.zipUrl = self.ips[self.ipIndx]
                else
                    -- local URL = require('cocos.cocos2d.URL')
                    -- local t = URL.parse(self.zipUrl)
                    -- self.zipUrl = table.concat({'http://',self.ips[self.ipIndx],t.path},'')
                    self.zipUrl = self.ips[self.ipIndx]
                end
                cleanUp()
                initDownloader()
                self:downloadURL(self.zipUrl, handler(self, self.downloadCallback))
            else
                --只有一个地址
                --重试
                cleanUp()
                initDownloader()
                self:downloadURL(self.zipUrl, handler(self, self.downloadCallback))
            end
        else
            --重试
            cleanUp()
            initDownloader()
            self:downloadURL(self.zipUrl, handler(self, self.downloadCallback))
        end
        self.viewData.progressTipsLabel:setString(__('下载更新包网络出现异常...') .. " " .. tostring(self.tryNum) .. " " .. tostring(self.ipIndx))
        self.tryNum = self.tryNum + 1
--[[         local target = cc.Application:getInstance():getTargetPlatform() ]]
        -- if target > 2 and target < 6 then -- ios or andorid 记录新的上报错误
            -- local uploadInfo = string.format("ERROR: %s", tostring(self.zipUrl))
            -- buglyReportLuaException(uploadInfo, uploadInfo)
        --[[ end ]]
    end
end

function Downloader:onEnter()
end

function Downloader:onCleanup()
    self.isStart = false
    if self.uncompressUpdateFun then
        scheduler.unscheduleGlobal(self.uncompressUpdateFun)
        self.uncompressUpdateFun = nil
    end
    cleanUp()
    -- if device.platform == 'android' then
        -- luaj.callStaticMethod("com.duobaogame.summer.ObbDownloader",'removeScriptListener',{})
    -- end
    self:stoptManualUpdateDownloadProgress_()
    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
end


function Downloader:startManualUpdateDownloadProgress_()
    if self.manualUpdateDownloadProgressHandler_ then return end
    self.manualUpdateDownloadProgressHandler_ = scheduler.scheduleGlobal(function()
        if self.downloadCachePath_ and utils.isExistent(self.downloadCachePath_) then
            local downloadCurrentByte = io.filesize(self.downloadCachePath_)
            self:updateDownloadProgress_(downloadCurrentByte, self.downloadTotalByte_)
        end
    end, 1)
end
function Downloader:stoptManualUpdateDownloadProgress_()
    if self.manualUpdateDownloadProgressHandler_ then
        scheduler.unscheduleGlobal(self.manualUpdateDownloadProgressHandler_)
        self.manualUpdateDownloadProgressHandler_ = nil
    end
end


function Downloader:updateUncompressProgress_(currentByte, totalByte, test)
    local total = tonumber(totalByte,10)
    local progress = tonumber(currentByte,10)
    if progress > total then progress = total end
    self.viewData.loadingBar:setValue((progress / total) * 100)
    local str = string.format('%.1f %%',(progress / total) * 100)
    local percent = progress * 0.01
    if self.viewData.loadingBarShine then
        self.viewData.loadingBarShine:setPositionX(
            self.viewData.loadingBar:getPositionX() - self.viewData.loadingBar:getContentSize().width * 0.5 +
            self.viewData.loadingBar:getContentSize().width * percent - 1)
    end
    self:updateLoadingTips_(string.format(__("资源解压进度%s"),str))

    if self.isMiniMode_ then
        self:updateProgressTips_(string.format("%sM / %sM",tostring(math.floor(progress/1024/1024)), tostring(math.floor(total / 1024/1024))))
    else
        self:updateProgressTips_(string.format(__("正在解压%sM/%sM"),tostring(math.floor(progress/1024/1024)), tostring(math.floor(total / 1024/1024))))
    end
end

function Downloader:updateDownloadProgress_(currentByte, totalByte, test)
    local total = tonumber(totalByte,10)
    local progress = tonumber(currentByte,10)
    if progress > total then progress = total end
    self.viewData.loadingBar:setValue((progress / total) * 100)
    local str = string.format('%.1f %%',(progress / total) * 100)
    local percent = progress * 0.01
    if self.viewData.loadingBarShine then
        self.viewData.loadingBarShine:setPositionX(
            self.viewData.loadingBar:getPositionX() - self.viewData.loadingBar:getContentSize().width * 0.5 +
            self.viewData.loadingBar:getContentSize().width * percent - 1)
    end
    self:updateLoadingTips_(string.format(__("资源下载进度%s"),str))

    if self.isMiniMode_ then
        self:updateProgressTips_(string.format("%sM / %sM",tostring(math.floor(progress/1024/1024)), tostring(math.floor(total / 1024/1024))))
    else
        self:updateProgressTips_(string.format(__("正在下載%sM/%sM"),tostring(math.floor(progress/1024/1024)), tostring(math.floor(total / 1024/1024))))
    end
end


return Downloader
