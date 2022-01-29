---@class display
local display = {}

local director = cc.Director:getInstance()
local view = director:getOpenGLView()

if not view then
    local width = 960
    local height = 640
    if CC_DESIGN_RESOLUTION then
        if CC_DESIGN_RESOLUTION.width then
            width = CC_DESIGN_RESOLUTION.width
        end
        if CC_DESIGN_RESOLUTION.height then
            height = CC_DESIGN_RESOLUTION.height
        end
    end
    view = cc.GLViewImpl:createWithRect("Cocos2d-Lua", cc.rect(0, 0, width, height))
    director:setOpenGLView(view)
end

local framesize = view:getFrameSize()
local textureCache = director:getTextureCache()
local spriteFrameCache = cc.SpriteFrameCache:getInstance()
local animationCache = cc.AnimationCache:getInstance()

-- auto scale
local function checkResolution(r)
    r.width = checknumber(r.width)
    r.height = checknumber(r.height)
    r.autoscale = string.upper(r.autoscale)
    assert(r.width > 0 and r.height > 0,
        string.format("display - invalid design resolution size %d, %d", r.width, r.height))
end

local function setDesignResolution(r, framesize)
    if r.autoscale == "FILL_ALL" then
        view:setDesignResolutionSize(framesize.width, framesize.height, cc.ResolutionPolicy.FILL_ALL)
    else
        local scaleX, scaleY = framesize.width / r.width, framesize.height / r.height
        local width, height = framesize.width, framesize.height
        if r.autoscale == "FIXED_WIDTH" then
            width = framesize.width / scaleX
            height = framesize.height / scaleX
            view:setDesignResolutionSize(width, height, cc.ResolutionPolicy.NO_BORDER)
        elseif r.autoscale == "FIXED_HEIGHT" then
            width = framesize.width / scaleY
            height = framesize.height / scaleY
            view:setDesignResolutionSize(width, height, cc.ResolutionPolicy.NO_BORDER)
        elseif r.autoscale == "EXACT_FIT" then
            view:setDesignResolutionSize(r.width, r.height, cc.ResolutionPolicy.EXACT_FIT)
        elseif r.autoscale == "NO_BORDER" then
            view:setDesignResolutionSize(r.width, r.height, cc.ResolutionPolicy.NO_BORDER)
        elseif r.autoscale == "SHOW_ALL" then
            view:setDesignResolutionSize(r.width, r.height, cc.ResolutionPolicy.SHOW_ALL)
        else
            printError(string.format("display - invalid r.autoscale \"%s\"", r.autoscale))
        end
    end
end

local function setConstants()
    local sizeInPixels = view:getFrameSize()
    display.sizeInPixels = {width = sizeInPixels.width, height = sizeInPixels.height}

    local viewsize = director:getWinSize()
    display.contentScaleFactor = director:getContentScaleFactor()
    display.size               = {width = viewsize.width, height = viewsize.height}
    display.width              = display.size.width
    display.height             = display.size.height
    display.cx                 = display.width / 2
    display.cy                 = display.height / 2
    display.c_left             = -display.width / 2
    display.c_right            = display.width / 2
    display.c_top              = display.height / 2
    display.c_bottom           = -display.height / 2
    display.left               = 0
    display.right              = display.width
    display.top                = display.height
    display.bottom             = 0
    display.center             = cc.p(display.cx, display.cy)
    display.left_top           = cc.p(display.left, display.top)
    display.left_bottom        = cc.p(display.left, display.bottom)
    display.left_center        = cc.p(display.left, display.cy)
    display.right_top          = cc.p(display.right, display.top)
    display.right_bottom       = cc.p(display.right, display.bottom)
    display.right_center       = cc.p(display.right, display.cy)
    display.top_center         = cc.p(display.cx, display.top)
    display.top_bottom         = cc.p(display.cx, display.bottom)

    printInfo(string.format("# display.sizeInPixels         = {width = %0.2f, height = %0.2f}", display.sizeInPixels.width, display.sizeInPixels.height))
    printInfo(string.format("# display.size                 = {width = %0.2f, height = %0.2f}", display.size.width, display.size.height))
    printInfo(string.format("# display.contentScaleFactor   = %0.2f", display.contentScaleFactor))
    printInfo(string.format("# display.width                = %0.2f", display.width))
    printInfo(string.format("# display.height               = %0.2f", display.height))
    printInfo(string.format("# display.cx                   = %0.2f", display.cx))
    printInfo(string.format("# display.cy                   = %0.2f", display.cy))
    printInfo(string.format("# display.left                 = %0.2f", display.left))
    printInfo(string.format("# display.right                = %0.2f", display.right))
    printInfo(string.format("# display.top                  = %0.2f", display.top))
    printInfo(string.format("# display.bottom               = %0.2f", display.bottom))
    printInfo(string.format("# display.c_left               = %0.2f", display.c_left))
    printInfo(string.format("# display.c_right              = %0.2f", display.c_right))
    printInfo(string.format("# display.c_top                = %0.2f", display.c_top))
    printInfo(string.format("# display.c_bottom             = %0.2f", display.c_bottom))
    printInfo(string.format("# display.center               = {x = %0.2f, y = %0.2f}", display.center.x, display.center.y))
    printInfo(string.format("# display.left_top             = {x = %0.2f, y = %0.2f}", display.left_top.x, display.left_top.y))
    printInfo(string.format("# display.left_bottom          = {x = %0.2f, y = %0.2f}", display.left_bottom.x, display.left_bottom.y))
    printInfo(string.format("# display.left_center          = {x = %0.2f, y = %0.2f}", display.left_center.x, display.left_center.y))
    printInfo(string.format("# display.right_top            = {x = %0.2f, y = %0.2f}", display.right_top.x, display.right_top.y))
    printInfo(string.format("# display.right_bottom         = {x = %0.2f, y = %0.2f}", display.right_bottom.x, display.right_bottom.y))
    printInfo(string.format("# display.right_center         = {x = %0.2f, y = %0.2f}", display.right_center.x, display.right_center.y))
    printInfo(string.format("# display.top_center           = {x = %0.2f, y = %0.2f}", display.top_center.x, display.top_center.y))
    printInfo(string.format("# display.top_bottom           = {x = %0.2f, y = %0.2f}", display.top_bottom.x, display.top_bottom.y))
    printInfo("#")
end

function display.setAutoScale(configs)
    if type(configs) ~= "table" then return end

    checkResolution(configs)
    if type(configs.callback) == "function" then
        local c = configs.callback(framesize)
        for k, v in pairs(c or {}) do
            configs[k] = v
        end
        checkResolution(configs)
    end

    setDesignResolution(configs, framesize)

    printInfo(string.format("# design resolution size       = {width = %0.2f, height = %0.2f}", configs.width, configs.height))
    printInfo(string.format("# design resolution autoscale  = %s", configs.autoscale))
    setConstants()
end

if type(CC_DESIGN_RESOLUTION) == "table" then
    display.setAutoScale(CC_DESIGN_RESOLUTION)
end

display.COLOR_WHITE = cc.c3b(255, 255, 255)
display.COLOR_BLACK = cc.c3b(0, 0, 0)
display.COLOR_RED   = cc.c3b(255, 0, 0)
display.COLOR_GREEN = cc.c3b(0, 255, 0)
display.COLOR_BLUE  = cc.c3b(0, 0, 255)

display.AUTO_SIZE      = 0
display.FIXED_SIZE     = 1
display.LEFT_TO_RIGHT  = 0
display.RIGHT_TO_LEFT  = 1
display.TOP_TO_BOTTOM  = 2
display.BOTTOM_TO_TOP  = 3

display.CENTER        = cc.p(0.5, 0.5)
display.LEFT_TOP      = cc.p(0, 1)
display.LEFT_BOTTOM   = cc.p(0, 0)
display.LEFT_CENTER   = cc.p(0, 0.5)
display.RIGHT_TOP     = cc.p(1, 1)
display.RIGHT_BOTTOM  = cc.p(1, 0)
display.RIGHT_CENTER  = cc.p(1, 0.5)
display.CENTER_TOP    = cc.p(0.5, 1)
display.CENTER_BOTTOM = cc.p(0.5, 0)

display.SCENE_TRANSITIONS = {
    CROSSFADE       = cc.TransitionCrossFade,
    FADE            = {cc.TransitionFade, cc.c3b(0, 0, 0)},
    FADEBL          = cc.TransitionFadeBL,
    FADEDOWN        = cc.TransitionFadeDown,
    FADETR          = cc.TransitionFadeTR,
    FADEUP          = cc.TransitionFadeUp,
    FLIPANGULAR     = {cc.TransitionFlipAngular, cc.TRANSITION_ORIENTATION_LEFT_OVER},
    FLIPX           = {cc.TransitionFlipX, cc.TRANSITION_ORIENTATION_LEFT_OVER},
    FLIPY           = {cc.TransitionFlipY, cc.TRANSITION_ORIENTATION_UP_OVER},
    JUMPZOOM        = cc.TransitionJumpZoom,
    MOVEINB         = cc.TransitionMoveInB,
    MOVEINL         = cc.TransitionMoveInL,
    MOVEINR         = cc.TransitionMoveInR,
    MOVEINT         = cc.TransitionMoveInT,
    PAGETURN        = {cc.TransitionPageTurn, false},
    ROTOZOOM        = cc.TransitionRotoZoom,
    SHRINKGROW      = cc.TransitionShrinkGrow,
    SLIDEINB        = cc.TransitionSlideInB,
    SLIDEINL        = cc.TransitionSlideInL,
    SLIDEINR        = cc.TransitionSlideInR,
    SLIDEINT        = cc.TransitionSlideInT,
    SPLITCOLS       = cc.TransitionSplitCols,
    SPLITROWS       = cc.TransitionSplitRows,
    TURNOFFTILES    = cc.TransitionTurnOffTiles,
    ZOOMFLIPANGULAR = cc.TransitionZoomFlipAngular,
    ZOOMFLIPX       = {cc.TransitionZoomFlipX, cc.TRANSITION_ORIENTATION_LEFT_OVER},
    ZOOMFLIPY       = {cc.TransitionZoomFlipY, cc.TRANSITION_ORIENTATION_UP_OVER},
}


-- 这里是设计分辨率，用于和渲染分辨率做比较。
local iPadPro11Size = {width = 1668, height = 2388}
local iphoneXSizes = {
    {width = 375, height = 812},  -- iphone x / iphone xs / iphone 11 pro / iphone 12 mini
    {width = 414, height = 896},  -- iphone xs max / iphone xr / iphone 11 / iphone 11 pro max
    {width = 390, height = 844},  -- iphone 12 / iphone 12 pro
    {width = 428, height = 926},  -- iphone 12 Pro Max
}

local platformId  = cc.Application:getInstance():getTargetPlatform()
for _,iphoneXSize in pairs(iphoneXSizes) do
    local xPixelRatio = math.min(iphoneXSize.width, iphoneXSize.height) / math.max(iphoneXSize.width, iphoneXSize.height)
    local dPixelRatio = math.min(display.size.width, display.size.height) / math.max(display.size.width, display.size.height)
    local isPlatforms = platformId == cc.PLATFORM_OS_WINDOWS or platformId == cc.PLATFORM_OS_MAC or platformId == cc.PLATFORM_OS_IPHONE
    local isIphoneX = isPlatforms and string.format('%.6f', xPixelRatio) == string.format('%.6f', dPixelRatio)
    if isIphoneX then
        display.isIphoneX = isIphoneX
        break
    end
end

display.isFullScreen = display.width / display.height >= 2
display.SAFE_RECT = {x = 0, y = 0, width = display.size.width, height = display.size.height}
if display.isIphoneX then
    local borderW = math.floor(90 * CC_DESIGN_RESOLUTION.height / 1125)
    display.SAFE_RECT = {x = borderW, y = 0, width = display.size.width - borderW*2, height = display.size.height}
end
display.SAFE_L = display.SAFE_RECT.x
display.SAFE_R = display.SAFE_RECT.x + display.SAFE_RECT.width
display.SAFE_T = display.SAFE_RECT.y + display.SAFE_RECT.height
display.SAFE_B = display.SAFE_RECT.y
display.SAFE_CX = display.SAFE_RECT.x + display.SAFE_RECT.width * 0.5
display.SAFE_CY = display.SAFE_RECT.y + display.SAFE_RECT.height * 0.5
printInfo(string.format("# display.SAFE_RECT = {x = %0.2f, y = %0.2f, w = %0.2f, h = %0.2f}", display.SAFE_RECT.x, display.SAFE_RECT.y, display.SAFE_RECT.width, display.SAFE_RECT.height))
printInfo(string.format("# display.SAFE_L    = %0.2f", display.SAFE_L))
printInfo(string.format("# display.SAFE_R    = %0.2f", display.SAFE_R))
printInfo(string.format("# display.SAFE_T    = %0.2f", display.SAFE_T))
printInfo(string.format("# display.SAFE_B    = %0.2f", display.SAFE_B))
printInfo("##")


-- iphoneX mask (debug use)
if display.isIphoneX and platformId ~= cc.PLATFORM_OS_IPHONE then
    local imagePath = 'res/iphoneX_mask_h.png'
    local maskScene = cc.CSceneExtension:create()
    cc.CSceneManager:getInstance():runSuspendScene(maskScene)

    textureCache:addImageAsync(imagePath, function(texture)
        local iphoneXMask = cc.Sprite:create(imagePath)
        local maskImgSize = iphoneXMask:getContentSize()
        local isPortrait  = display.height > display.width
        if isPortrait then
            iphoneXMask:setRotation(90)
            iphoneXMask:setScale(display.size.width / maskImgSize.height)
        else
            iphoneXMask:setScale(display.size.height / maskImgSize.height)
        end
        iphoneXMask:setAnchorPoint(display.CENTER)
        iphoneXMask:setPosition(display.center)
        iphoneXMask:setName('iphoneXMask')
        iphoneXMask:setOpacity(0)
        iphoneXMask:runAction(cc.FadeIn:create(0.2))
        maskScene:addChild(iphoneXMask)

        local keyboardEventListener = cc.EventListenerKeyboard:create()
        keyboardEventListener:registerScriptHandler(function(keyCode, event)
            if keyCode == 26 then  -- left arrow key
                iphoneXMask:setScaleX(math.abs(iphoneXMask:getScaleX()))
            elseif keyCode == 27 then  -- right arrow key
                iphoneXMask:setScaleX(-math.abs(iphoneXMask:getScaleX()))
            end
        end, cc.Handler.EVENT_KEYBOARD_PRESSED)
        maskScene:getEventDispatcher():addEventListenerWithSceneGraphPriority(keyboardEventListener, maskScene)
    end)
end


-- ipadPro11 mask (debug use)
if platformId ~= cc.PLATFORM_OS_IPAD then
    if (iPadPro11Size.width == math.min(display.sizeInPixels.width, display.sizeInPixels.height) and 
        iPadPro11Size.height == math.max(display.sizeInPixels.width, display.sizeInPixels.height)) then
        local imagePath = 'res/ipadPro11_mash_h.png'
        local maskScene = cc.CSceneExtension:create()
        cc.CSceneManager:getInstance():runSuspendScene(maskScene)

        textureCache:addImageAsync(imagePath, function(texture)
            local ipadPro11Mask = cc.Sprite:create(imagePath)
            local maskImgSize   = ipadPro11Mask:getContentSize()
            local isPortrait  = display.height > display.width
            if isPortrait then
                ipadPro11Mask:setRotation(90)
                ipadPro11Mask:setScale(display.size.width / maskImgSize.height)
            else
                ipadPro11Mask:setScale(display.size.height / maskImgSize.height)
            end
            ipadPro11Mask:setAnchorPoint(display.CENTER)
            ipadPro11Mask:setPosition(display.center)
            ipadPro11Mask:setName('ipadPro11Mask')
            ipadPro11Mask:setOpacity(0)
            ipadPro11Mask:runAction(cc.FadeIn:create(0.2))
            maskScene:addChild(ipadPro11Mask)
        end)
    end
end



display.TEXTURES_PIXEL_FORMAT = {}

display.DEFAULT_TTF_FONT        = "Arial"
display.DEFAULT_TTF_FONT_SIZE   = 32

TTF_GAME_FONT = 'res/font/FZCQJW.TTF'
TTF_DIALOGUE_FONT = string.format('res/font/%s/ModeMinAStd-B2.ttf',i18n.getLang())
TTF_TEXT_FONT = 'res/font/DroidSansFallback.ttf'
function display.initFontTTF()
    local fileUtils = cc.FileUtils:getInstance()
    if i18n.getLang() == 'en-us' then
        TTF_GAME_FONT = 'res/font/EN-US.TTF'
        TTF_TEXT_FONT = 'res/font/DroidSansFallback.ttf'
        if (not fileUtils:isFileExist(TTF_GAME_FONT) ) and  fileUtils:isFileExist('res/fonts/EN-US.TTF') then
            TTF_GAME_FONT = 'res/fonts/EN-US.TTF'
        end
        if (not fileUtils:isFileExist(TTF_TEXT_FONT) ) and  fileUtils:isFileExist('res/fonts/DroidSansFallback.ttf') then
            TTF_TEXT_FONT = 'res/fonts/DroidSansFallback.ttf'
        end

    elseif i18n.getLang() == 'id-id' then
        TTF_GAME_FONT = 'res/font/TL-PH_ID-ID_MS-MY.TTF'
        TTF_TEXT_FONT = 'res/font/DroidSansFallback.ttf'
        if (not fileUtils:isFileExist(TTF_GAME_FONT) ) and  fileUtils:isFileExist('res/fonts/TL-PH_ID-ID_MS-MY.TTF') then
            TTF_GAME_FONT = 'res/fonts/TL-PH_ID-ID_MS-MY.TTF'
            print("TTF_GAME_FONT = " , TTF_GAME_FONT)
        end

        if (not fileUtils:isFileExist(TTF_TEXT_FONT) ) and  fileUtils:isFileExist('res/fonts/DroidSansFallback.ttf') then
            TTF_TEXT_FONT = 'res/fonts/DroidSansFallback.ttf'
        end
    elseif i18n.getLang() == 'ms-my' then
        TTF_GAME_FONT = 'res/font/TL-PH_ID-ID_MS-MY.TTF'
        TTF_TEXT_FONT = 'res/font/DroidSansFallback.ttf'
        if (not fileUtils:isFileExist(TTF_GAME_FONT) ) and  fileUtils:isFileExist('res/fonts/TL-PH_ID-ID_MS-MY.TTF') then
            TTF_GAME_FONT = 'res/fonts/TL-PH_ID-ID_MS-MY.TTF'
        end

        if (not fileUtils:isFileExist(TTF_TEXT_FONT) ) and  fileUtils:isFileExist('res/fonts/DroidSansFallback.ttf') then
            TTF_TEXT_FONT = 'res/fonts/DroidSansFallback.ttf'
        end
    elseif i18n.getLang() == 'ru-ru' then
        TTF_GAME_FONT = 'res/font/RU-RU.TTF'
        TTF_TEXT_FONT = 'res/font/DroidSansFallback.ttf'
        if (not fileUtils:isFileExist(TTF_GAME_FONT) ) and  fileUtils:isFileExist('res/fonts/RU-RU.TTF') then
            TTF_GAME_FONT = 'res/fonts/RU-RU.TTF'
        end

        if (not fileUtils:isFileExist(TTF_TEXT_FONT) ) and  fileUtils:isFileExist('res/fonts/DroidSansFallback.ttf') then
            TTF_TEXT_FONT = 'res/fonts/DroidSansFallback.ttf'
        end

    elseif i18n.getLang() == 'th-th' then
        TTF_GAME_FONT = 'res/font/TH-TH.TTF'
        TTF_TEXT_FONT = 'res/font/TH-TH.TTF'
        if (not fileUtils:isFileExist(TTF_GAME_FONT) ) and  fileUtils:isFileExist('res/fonts/TH-TH.TTF') then
            TTF_GAME_FONT = 'res/fonts/TH-TH.TTF'
        end

        if (not fileUtils:isFileExist(TTF_TEXT_FONT) ) and  fileUtils:isFileExist('res/fonts/TH-TH.TTF') then
            TTF_TEXT_FONT = 'res/font/TH-TH.TTF'
        end

    elseif i18n.getLang() == 'tl-ph' then
        TTF_GAME_FONT = 'res/font/TL-PH_ID-ID_MS-MY.TTF'
        TTF_TEXT_FONT = 'res/font/DroidSansFallback.ttf'
        if (not fileUtils:isFileExist(TTF_GAME_FONT) ) and  fileUtils:isFileExist('res/fonts/TL-PH_ID-ID_MS-MY.TTF') then
            TTF_GAME_FONT = 'res/fonts/TL-PH_ID-ID_MS-MY.TTF'
        end

        if (not fileUtils:isFileExist(TTF_TEXT_FONT) ) and  fileUtils:isFileExist('res/fonts/DroidSansFallback.ttf') then
            TTF_TEXT_FONT = 'res/font/DroidSansFallback.ttf'
        end
    elseif i18n.getLang() == 'es-es' then
        TTF_GAME_FONT = 'res/font/ES-ES.TTF'
        TTF_TEXT_FONT = 'res/font/ES-ES.TTF'
        if (not fileUtils:isFileExist(TTF_GAME_FONT)) and fileUtils:isFileExist('res/fonts/ES-ES.TTF') then
                TTF_GAME_FONT = 'res/fonts/ES-ES.TTF'
        end
        if not fileUtils:isFileExist(TTF_TEXT_FONT) and  fileUtils:isFileExist('res/fonts/ES-ES.TTF') then
                TTF_TEXT_FONT = 'res/fonts/ES-ES.TTF'
        end
    elseif i18n.getLang() == 'zh-tw' then
        TTF_GAME_FONT = 'res/font/FZCQJW.TTF'
        TTF_TEXT_FONT = 'res/font/DroidSansFallback.ttf'


        if ( not fileUtils:isFileExist(TTF_GAME_FONT)) and  fileUtils:isFileExist('res/fonts/FZCQJW.TTF') then
                TTF_GAME_FONT = 'res/fonts/FZCQJW.TTF'

        end

        if ( not fileUtils:isFileExist(TTF_TEXT_FONT)) and  fileUtils:isFileExist('res/fonts/DroidSansFallback.ttf') then
                TTF_TEXT_FONT = 'res/fonts/DroidSansFallback.ttf'
        end

    elseif 	i18n.getLang() == 'vi-vn' or i18n.getLang() == 'tr-tr' then
        TTF_GAME_FONT = 'res/font/TR-TR_VI-VN.TTF'
        TTF_TEXT_FONT = 'res/font/TR-TR_VI-VN.TTF'
        if (not fileUtils:isFileExist(TTF_GAME_FONT) ) and  fileUtils:isFileExist('res/fonts/TR-TR_VI-VN.TTF') then
                TTF_GAME_FONT = 'res/fonts/TR-TR_VI-VN.TTF'
        end

        if (not fileUtils:isFileExist(TTF_TEXT_FONT)) and fileUtils:isFileExist('res/fonts/TR-TR_VI-VN.TTF') then
                TTF_TEXT_FONT = 'res/fonts/TR-TR_VI-VN.TTF'
        end

    elseif i18n.getLang() == 'ja-jp' then
        TTF_GAME_FONT = string.format('res/font/%s/FZCQJW.TTF',i18n.getLang())
        if not fileUtils:isFileExist(TTF_GAME_FONT) then
            TTF_GAME_FONT = 'res/font/FZCQJW.TTF'
        end
        TTF_TEXT_FONT = string.format('res/font/%s/GenShinGothic-P-Medium.ttf',i18n.getLang())
        if not fileUtils:isFileExist(TTF_TEXT_FONT) then
            TTF_TEXT_FONT = 'res/font/DroidSansFallback.ttf'
        end
    else
        TTF_GAME_FONT = string.format('res/font/%s/FZCQJW.TTF',i18n.getLang())
        TTF_TEXT_FONT = string.format('res/font/%s/DroidSansFallback.ttf',i18n.getLang())
        if not fileUtils:isFileExist(TTF_GAME_FONT) then
            TTF_GAME_FONT = 'res/font/FZCQJW.TTF'
        end
        if not fileUtils:isFileExist(TTF_TEXT_FONT) then
            TTF_TEXT_FONT = 'res/font/DroidSansFallback.ttf'
        end
    end
    if not fileUtils:isFileExist(TTF_TEXT_FONT) then
        TTF_TEXT_FONT = string.gsub(TTF_TEXT_FONT , 'font' , "fonts")
        TTF_TEXT_FONT = string.gsub(TTF_TEXT_FONT , 'res' , "res_sub")
    end
    if not fileUtils:isFileExist(TTF_GAME_FONT) then
        TTF_GAME_FONT  = string.gsub(TTF_GAME_FONT , 'font' , "fonts")
        TTF_GAME_FONT  = string.gsub(TTF_GAME_FONT , 'res' ,  "res_sub")
    end
end
display.initFontTTF()

local PARAMS_EMPTY = {}
local RECT_ZERO = cc.rect(0, 0, 0, 0)

local sceneIndex = 0


---@return cc.CSceneExtension | cc.Scene
function display.newScene(name, params)
    params = params or PARAMS_EMPTY
    sceneIndex = sceneIndex + 1
    local scene
    if not params.physics then
        scene = cc.CSceneExtension:create()
        -- scene = cc.Scene:create()
    else
        scene = cc.Scene:createWithPhysics()
    end
    scene.name_ = string.format("%s:%d", name or "<unknown-scene>", sceneIndex)
    scene:setClassName(name)
    scene:enableNodeEvents()
    scene:setAutoRemoveUnusedTexture(true)
    if params.transition then
        scene = display.wrapSceneWithTransition(scene, params.transition, params.time, params.more)
    end

    return scene
end

function display.wrapScene(scene, transition, time, more)
    local key = string.upper(tostring(transition))

    if key == "RANDOM" then
        local keys = table.keys(display.SCENE_TRANSITIONS)
        key = keys[math.random(1, #keys)]
    end

    if display.SCENE_TRANSITIONS[key] then
        local t = display.SCENE_TRANSITIONS[key]
        time = time or 0.2
        more = more or t[2]
        if type(t) == "table" then
            scene = t[1]:create(time, scene, more)
        else
            scene = t:create(time, scene)
        end
    else
        error(string.format("display.wrapScene() - invalid transition %s", tostring(transition)))
    end
    return scene
end

function display.runScene(newScene, transition, time, more)
    if director:getRunningScene() then
        if transition then
            newScene = display.wrapScene(newScene, transition, time, more)
        end
        director:replaceScene(newScene)
    else
        director:runWithScene(newScene)
    end
end

function display.getRunningScene()
    return cc.CSceneManager:getInstance():getRunningScene()
end

---@return cc.Node
function display.newNode()
    return cc.Node:create()
end

---@return cc.Sprite | ccui.Scale9Sprite
function display.newSprite(source, x, y, params)
    local spriteClass = cc.Sprite
    local scale9 = false

    if type(x) == "table" and not x.x then
        -- x is params
        params = x
        x = nil
        y = nil
    end

    local params = params or PARAMS_EMPTY
    if params.scale9 or params.capInsets then
        spriteClass = ccui.Scale9Sprite
        scale9 = true
        params.capInsets = params.capInsets or RECT_ZERO
        params.rect = params.rect or RECT_ZERO
    end

    local sprite
    while true do
        -- create sprite
        if not source then
            sprite = spriteClass:create()
            break
        end

        local sourceType = type(source)
        if sourceType == "string" then
            if string.byte(source) == 35 then -- first char is #
                -- create sprite from spriteFrame
                if not scale9 then
                    sprite = spriteClass:createWithSpriteFrameName(string.sub(source, 2))
                else
                    sprite = spriteClass:createWithSpriteFrameName(string.sub(source, 2), params.capInsets)
                end
                break
            end

            -- create sprite from image file
            if display.TEXTURES_PIXEL_FORMAT[source] then
                cc.Texture2D:setDefaultAlphaPixelFormat(display.TEXTURES_PIXEL_FORMAT[source])
            end
            if not scale9 then
                sprite = spriteClass:create(source)
            else
                sprite = spriteClass:create(source, params.rect, params.capInsets)
            end
            if display.TEXTURES_PIXEL_FORMAT[source] then
                cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_BGR_A8888)
            end
            break
        elseif sourceType ~= "userdata" then
            error(string.format("display.newSprite() - invalid source type \"%s\"", sourceType), 0)
        else
            sourceType = tolua.type(source)
            if sourceType == "cc.SpriteFrame" then
                if not scale9 then
                    sprite = spriteClass:createWithSpriteFrame(source)
                else
                    sprite = spriteClass:createWithSpriteFrame(source, params.capInsets)
                end
            elseif sourceType == "cc.Texture2D" then
                sprite = spriteClass:createWithTexture(source)
            else
                error(string.format("display.newSprite() - invalid source type \"%s\"", sourceType), 0)
            end
        end
        break
    end

    if sprite then
        --        local alias = (params.as or true)
        --        if alias == true then
        --            textureCache:setAliasTexParameters(source)
        --        end
        if x and y then
            sprite:setPosition(checkint(x), checkint(y))
        end
        if params.size then
            local size = {width = checkint(params.size.width),height = checkint(params.size.height)}
            sprite:setContentSize(size)
        end
    else
        error(string.format("display.newSprite() - create sprite failure, source \"%s\"", tostring(source)), 0)
    end

    return sprite
end

---@return cc.SpriteFrame
function display.newSpriteFrame(source, ...)
    local frame
    if type(source) == "string" then
        if string.byte(source) == 35 then -- first char is #
            source = string.sub(source, 2)
        end
        frame = spriteFrameCache:getSpriteFrame(source)
        if not frame then
            error(string.format("display.newSpriteFrame() - invalid frame name \"%s\"", tostring(source)), 0)
        end
    elseif tolua.type(source) == "cc.Texture2D" then
        frame = cc.SpriteFrame:createWithTexture(source, ...)
    else
        error("display.newSpriteFrame() - invalid parameters", 0)
    end
    return frame
end

---@return cc.SpriteFrame[]
function display.newFrames(pattern, begin, length, isReversed)
    local frames = {}
    local step = 1
    local last = begin + length - 1
    if isReversed then
        last, begin = begin, last
        step = -1
    end

    for index = begin, last, step do
        local frameName = string.format(pattern, index)
        local frame = spriteFrameCache:getSpriteFrame(frameName)
        if not frame then
            error(string.format("display.newFrames() - invalid frame name %s", tostring(frameName)), 0)
        end
        frames[#frames + 1] = frame
    end
    return frames
end

local function newAnimation(frames, time)
    local count = #frames
    assert(count > 0, "display.newAnimation() - invalid frames")
    time = time or 1.0 / count
    return cc.Animation:createWithSpriteFrames(frames, time),
        cc.Sprite:createWithSpriteFrame(frames[1])
end

function display.newAnimation(...)
    local params = {...}
    local c = #params
    if c == 2 then
        -- frames, time
        return newAnimation(params[1], params[2])
    elseif c == 4 then
        -- pattern, begin, length, time
        local frames = display.newFrames(params[1], params[2], params[3])
        return newAnimation(frames, params[4])
    elseif c == 5 then
        -- pattern, begin, length, isReversed, time
        local frames = display.newFrames(params[1], params[2], params[3], params[4])
        return newAnimation(frames, params[5])
    else
        error("display.newAnimation() - invalid parameters")
    end
end

---@return cc.Texture2D | void
function display.loadImage(imageFilename, callback)
    if not callback then
        return textureCache:addImage(imageFilename)
    else
        textureCache:addImageAsync(imageFilename, callback)
    end
end

local fileUtils = cc.FileUtils:getInstance()

---@return cc.Texture2D
function display.getImage(imageFilename)
    local fullpath = fileUtils:fullPathForFilename(imageFilename)
    return textureCache:getTextureForKey(fullpath)
end

function display.removeImage(imageFilename)
    textureCache:removeTextureForKey(imageFilename)
end

function display.loadSpriteFrames(dataFilename, imageFilename, callback)
    if display.TEXTURES_PIXEL_FORMAT[imageFilename] then
        cc.Texture2D:setDefaultAlphaPixelFormat(display.TEXTURES_PIXEL_FORMAT[imageFilename])
    end
    if not callback then
        spriteFrameCache:addSpriteFrames(dataFilename, imageFilename)
    else
        spriteFrameCache:addSpriteFramesAsync(dataFilename, imageFilename, callback)
    end
    if display.TEXTURES_PIXEL_FORMAT[imageFilename] then
        cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_BGR_A8888)
    end
end

function display.removeSpriteFrames(dataFilename, imageFilename)
    spriteFrameCache:removeSpriteFramesFromFile(dataFilename)
    if imageFilename then
        display.removeImage(imageFilename)
    end
end

function display.removeSpriteFrame(imageFilename)
    spriteFrameCache:removeSpriteFrameByName(imageFilename)
end

function display.setTexturePixelFormat(imageFilename, format)
    display.TEXTURES_PIXEL_FORMAT[imageFilename] = format
end

function display.setAnimationCache(name, animation)
    animationCache:addAnimation(animation, name)
end

function display.getAnimationCache(name)
    return animationCache:getAnimation(name)
end

function display.removeAnimationCache(name)
    animationCache:removeAnimation(name)
end

function display.removeUnusedSpriteFrames()

    spriteFrameCache:removeUnusedSpriteFrames()
    textureCache:removeUnusedTextures()
end


-------------------------------------------------
-- cocos 扩展
-------------------------------------------------

display.TAL = cc.TEXT_ALIGNMENT_LEFT
display.TAC = cc.TEXT_ALIGNMENT_CENTER
display.TAR = cc.TEXT_ALIGNMENT_RIGHT

local MAC_DEFAULT_SYS_FONT = 'STHeitiSC-Medium'
if i18n.getLang() == 'th-th' then
    MAC_DEFAULT_SYS_FONT  =  'Avenir'
elseif i18n.getLang() == 'ja-jp' then
    MAC_DEFAULT_SYS_FONT  =  'MS Gothic'
end
local WIN_DEFAULT_SYS_FONT = 'Microsoft Yahei'
local app = cc.Application:getInstance()
local target = app:getTargetPlatform()
if target == cc.PLATFORM_OS_ANDROID then
    MAC_DEFAULT_SYS_FONT = 'sans-serif-medium'
end

local checkImagePathFunc = function(source)
    local imgPath = tostring(source)
    local isValidPath = FTUtils:isPathExistent(source) and string.sub(imgPath, -1) ~= '/'
    return isValidPath and imgPath or _res('ui/common/story_tranparent_bg.png')
end

--[[
创建 layer
@param x number
@param y number
@param params table {
size:cc.size            -- content size, default display.size
ap:cc.p                 -- setAnchorPoint, default cc.p(0,0)
color:string            -- 3f color e.g:'#FFCC00'
coEnable:bool           -- setCascadeOpacityEnabled (only use CColorView)
enable:bool             -- is enable touch, default false (only use CColorView)
cb:function(sender)     -- click handler (only use CColorView)
bg:string               -- bgImg path, default nil
isFull:bool             -- isFull, default false (only use bg)
offset:cc.p             -- bgImg offsetPos, default nil (only use BgImage)
scale9:bool             -- is enable 9scale, default false (only use BgImage)
capInsets:cc.rect       -- 9scale center cap size, default nil (only use BgImage)
name: string            -- layer name
enableEvent:bool        -- is enableNodeEvents, default false
}
@return CLayout
]]
---@return CLayout | CColorView
function display.newLayer(x, y, params)
    local params = params or PARAMS_EMPTY
    local layer  = nil

    if params.color then
        local color = type(params.color) == 'string' and ccc3FromInt(params.color) or params.color
        ---@type CColorView 
        layer = CColorView:create(color)

        if params.enable ~= nil then
            layer:setTouchEnabled(params.enable)
        end

        if params.coEnable ~= nil then
            layer:setCascadeOpacityEnabled(params.coEnable)
        end

        if params.cb then
            ---@param sender CColorView
            layer:setOnClickScriptHandler(function(sender)
                sender:setTouchEnabled(false)
                if type(params.cb) == 'function' then
                    sender:setTouchEnabled(true)
                    params.cb(sender)
                end
            end)
        end
    else
        ---@type CLayout
        layer = CLayout:create()

        if params.bg then
            local bg = display.newImageView(params.bg, 0, 0, {scale9 = params.scale9, size = params.size, capInsets = params.capInsets, isFull = params.isFull})
            layer:setContentSize(cc.size(bg:getContentSize().width * bg:getScaleX(), bg:getContentSize().height * bg:getScaleY()))
            bg:setPosition(cc.pAdd(utils.getLocalCenter(layer), params.offset or PointZero))
            layer:addChild(bg)
            layer.bg = bg

            if params.hideBg then
                layer.bg:setVisible(false)
            end

            if params.enable ~= nil then
                layer.bg:setTouchEnabled(params.enable)
            end
        end
    end

    if layer then
        layer:setPosition(checkint(x), checkint(y))

        if not params.bg then
            local size = params.size or display.size
            layer:setContentSize(size)
        end

        local ap = params.ap or display.LEFT_BOTTOM
        layer:setAnchorPoint(ap)
    else
        error(string.format("display.newLayer() - create failure, x:%f y:%f", x, y), 0)
    end
    --[[
    local params = {...}
    local c = #params
    if c == 0 then
    -- /** creates a fullscreen black layer */
    -- static Layer *create();
    layer = CLayout:create()
    elseif c == 1 then
    -- /** creates a Layer with color. Width and height are the window size. */
    -- static LayerColor * create(const Color4B& color);
    layer = CColorView:create(cc.convertColor(params[1], "4b"))
    elseif c == 3 then
    -- /** creates a Layer with color, width and height in Points */
    -- static LayerColor * create(const Color4B& color, GLfloat width, GLfloat height);
    --
    -- /** Creates a full-screen Layer with a gradient between start and end in the direction of v. */
    -- static LayerGradient* create(const Color4B& start, const Color4B& end, const Vec2& v);
    local color1 = cc.convertColor(params[1], "4b")
    local p2 = params[2]
    local p2type = type(p2)
    if p2type == "table" then
    layer = CGradientView:create(color1, cc.convertColor(p2, "4b"), params[3])
    else
    layer = CColorView:create(color1)
    end
    end
    ]]
    if params.name then
        layer.name = tostring(params.name)
    end
    if params.enableEvent then
        layer:enableNodeEvents()
    end
    return layer
end


--[[--
创建 Button
@param x number
@param y number
@params params table {
animate:bool            -- is click animate, default true
enable:bool             -- is clickable, default true
scale9:bool             -- is enable 9scale, default false
isFlipX:bool            -- is flipX, default false
isFlipY:bool            -- is flipY, default false
size:cc.size            -- content size, default nil
ap:cc.p                 -- setAnchorPoint, default nil
n:string                -- normal image
s:string                -- selected imgae
d:string                -- disabled image
cb:function(sender)     -- click handler
}
@return CButton
--]]
---@return CButton
function display.newButton(x,y,params)
    ---@type CButton
    local button = CButton:create()
    local scale9 = false
    local useScelected = true
    if params.useS ~= nil then
        useScelected = params.useS
    end
    if type(x) == "table" and not x.x then
        -- x is params
        params = x
        x = nil
        y = nil
    end
    local params  = params or PARAMS_EMPTY
    local animate = params.animate == nil and true or params.animate
    local enable  = params.enable == nil and true or params.enable
    if params.scale9 or params.capInsets then
        scale9 = true
        params.capInsets = params.capInsets or RECT_ZERO
        params.rect = params.rect or RECT_ZERO
    end
    if scale9 == true then
        button:setScale9Enabled(true)
    end
    local normal = params.n
    local selected = params.s
    local disabled = params.d
    local alias = checkbool(params.as)
    if normal then
        if string.byte(normal) == 35 then -- first char is #
            normal = string.sub(normal, 2)
            button:setNormalSpriteFrameName(normal)
        else
            button:setNormalImage(checkImagePathFunc(normal))
            local normalImage =  button:getNormalImage()
            if normalImage then
                local buttonOriginalSize = normalImage:getContentSize()
                button.originalSize = buttonOriginalSize
            end

            if scale9 then
                button:getNormalImage():setCapInsets(params.capInsets)
                params.size = params.size or button:getNormalImage():getOriginalSize()
            end
            --            if alias == true then
            --                textureCache:setAliasTexParameters(normal)
            --            end
        end
        if scale9 and button:getNormalImage() then
            button:getNormalImage():setCapInsets(params.capInsets)
            params.size = params.size or button:getNormalImage():getOriginalSize()
        end
    end
    if selected then
        if string.byte(selected) == 35 then -- first char is #
            selected = string.sub(selected, 2)
            button:setSelectedSpriteFrameName(selected)
        else
            button:setSelectedImage(checkImagePathFunc(selected))
            --            if alias == true then
            --                textureCache:setAliasTexParameters(selected)
            --            end
        end
    else
        if params.n then
            if string.byte(params.n) == 35 then -- first char is #
                local anormal = string.sub(params.n, 2)
                if useScelected == true then
                    button:setSelectedSpriteFrameName(anormal)
                end
            else
                if useScelected == true then
                    button:setSelectedImage(checkImagePathFunc(params.n))
                    --            if alias == true then
                    --                textureCache:setAliasTexParameters(selected)
                    --            end
                    if button:getSelectedImage() then
                        button:getSelectedImage():setScale(0.97)
                    end
                end
            end
        end
    end
    if disabled then
        if string.byte(disabled) == 35 then -- first char is #
            disabled = string.sub(disabled, 2)
            button:setDisabledSpriteFrameName(disabled)
        else
            button:setDisabledImage(checkImagePathFunc(disabled))
            --            if alias == true then
            --                textureCache:setAliasTexParameters(disabled)
            --            end
        end
    end
    if params.isFlipX ~= nil then
        local isFlipX = params.isFlipX == true and -1 or 1
        button:getNormalImage():setScaleX(isFlipX)
        if button:getSelectedImage() then
            button:getSelectedImage():setScaleX(isFlipX)
        end
        if button:getDisabledImage() then
            button:getDisabledImage():setScaleX(isFlipX)
        end
    end
    if params.isFlipY ~= nil then
        local isFlipY = params.isFlipY == true and -1 or 1
        button:getNormalImage():setScaleY(isFlipY)
        if button:getSelectedImage() then
            button:getSelectedImage():setScaleY(isFlipY)
        end
        if button:getDisabledImage() then
            button:getDisabledImage():setScaleY(isFlipY)
        end
    end
    local cb = params.cb
    if cb then
        ---@param sender CButton
        button:setOnClickScriptHandler(function(sender)
            sender:setEnabled(false)
            if type(cb) == 'function' then
                if animate or true then
                    local fScale = sender:getScaleX()
                    transition.execute(sender,cc.Sequence:create(
                        cc.EaseOut:create(cc.ScaleTo:create(0.03, 0.92*fScale, 0.92*fScale), 0.03),
                        cc.EaseOut:create(cc.ScaleTo:create(0.03, 1*fScale, 1*fScale), 0.03),
                        cc.CallFunc:create(function()
                            sender:setEnabled(true)
                            cb(sender) ---回调 需要根据需求开启按钮状态
                        end)
                    ))
                else
                    sender:setEnabled(true)
                    cb(sender)
                end
            end
        end)
    end
    if button then
        if x and y then
            button:setPosition(checkint(x), checkint(y))
        end
        if params.size then
            local size = {width = checkint(params.size.width),height = checkint(params.size.height)}
            button:setContentSize(size)
        end
        if params.ap then button:setAnchorPoint(params.ap) end
        if params.tag then button:setTag(params.tag) end
        button:setEnabled(enable)

    else
        error("display.newButton() - create sprite failure, source")
    end
    return button
end


--[[--
创建 CImageView or CImageViewScale9
@param source  texture or sprite path
@param x
@param y y坐标
@param params table {
scale9:bool             -- is enable 9scale, default false
capInsets:rect          -- only use scale9 enable
size:cc.size            -- content size, default nil
enable:bool             -- is enable touch, default false
ap:cc.p                 -- setAnchorPoint, default nil
alpha:number            -- alpha number, default nil
scale:number            -- scale number, default nil
scaleX:number           -- scaleX number, default nil
scaleY:number           -- scaleY number, default nil
rotation:number         -- rotation number, default nil
isFull:bool             -- scale to full screen, default false
cb:function(sender)     -- click handler
}
@return CImageView or CImageViewScale9
--]]
---@return CImageView | CImageViewScale9
function display.newImageView(source,x, y, params)
    ---@type CImageView
    local spriteClass = CImageView
    local scale9 = false

    if type(x) == "table" and not x.x then
        -- x is params
        params = x
        x = nil
        y = nil
    end

    local params = params or PARAMS_EMPTY
    if params.scale9 == true or params.capInsets then
        ---@type CImageViewScale9
        spriteClass = CImageViewScale9
        scale9 = true
        params.capInsets = params.capInsets or RECT_ZERO
        params.rect = params.rect or RECT_ZERO
    end

    local sprite
    while true do
        -- create sprite
        if not source then
            sprite = spriteClass:create()
            break
        end

        local sourceType = type(source)
        if sourceType == "string" then
            if string.byte(source) == 35 then -- first char is #
                -- create sprite from spriteFrame
                if not scale9 then
                    sprite = spriteClass:createWithSpriteFrameName(string.sub(source, 2))
                else
                    sprite = spriteClass:createWithSpriteFrameName(string.sub(source, 2), params.capInsets)
                end
                break
            end

            -- create sprite from image file
            if display.TEXTURES_PIXEL_FORMAT[source] then
                cc.Texture2D:setDefaultAlphaPixelFormat(display.TEXTURES_PIXEL_FORMAT[source])
            end
            if not scale9 then
                sprite = spriteClass:create(checkImagePathFunc(source))
            else
                sprite = spriteClass:create(checkImagePathFunc(source), params.rect, params.capInsets)
            end
            if display.TEXTURES_PIXEL_FORMAT[source] then
                cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_BGR_A8888)
            end
            break
        elseif sourceType ~= "userdata" then
            error(string.format("display.newSprite() - invalid source type \"%s\"", sourceType), 0)
        else
            sourceType = tolua.type(source)
            if sourceType == "cc.SpriteFrame" then
                if not scale9 then
                    sprite = spriteClass:createWithSpriteFrame(source)
                else
                    sprite = spriteClass:createWithSpriteFrame(source, params.capInsets)
                end
            elseif sourceType == "cc.Texture2D" then
                sprite = spriteClass:createWithTexture(source)
            else
                error(string.format("display.newSprite() - invalid source type \"%s\"", sourceType), 0)
            end
        end
        break
    end
    local alias = checkbool(params.as)
    if sprite then
        local cb = params.cb
        local me = params.music
        local animate = params.animate == nil and true or params.animate
        if params.enable ~= nil then
            sprite:setTouchEnabled(params.enable)
        end
        --        if alias == true then
        --            textureCache:setAliasTexParameters(source)
        --        end
        if cb then
            ---@param sender CImageView | CImageViewScale9
            sprite:setOnClickScriptHandler(function(sender)
                if me then
                    PlayAudioClip(me)
                end
                sender:setTouchEnabled(false)
                if animate == true then
                    if cb and type(cb) ~= 'function' then
                        local tscale = sender:getScale()
                        transition.execute(sender,cc.Sequence:create(cc.EaseIn:create(cc.ScaleTo:create(0.05,tscale - 0.04),0.05),cc.EaseOut:create(cc.ScaleTo:create(0.05,tscale),0.05),cc.CallFunc:create(function()
                            sender:setTouchEnabled(true)
                        end)))
                    else
                        local tscale = sender:getScale()
                        transition.execute(sender,cc.Sequence:create(cc.EaseOut:create(cc.ScaleTo:create(0.05,tscale - 0.04),0.05),cc.EaseOut:create(cc.ScaleTo:create(0.05,tscale),0.05),cc.CallFunc:create(function()
                            sender:setTouchEnabled(true)
                            cb(sender) ---回调 需要根据需求开启按钮状态
                        end)))
                    end
                else
                    sender:setTouchEnabled(true)
                    cb(sender) ---回调 需要根据需求开启按钮状态
                end
            end)
        end
        if x and y then
            sprite:setPosition(checkint(x), checkint(y))
        end
        if params.size then
            local size = {width = checkint(params.size.width),height = checkint(params.size.height)}
            sprite:setContentSize(size)
        end
        if params.ap then sprite:setAnchorPoint(params.ap) end
        if params.tag then sprite:setTag(params.tag) end
        if params.alpha then sprite:setOpacity(params.alpha) end
        if params.scale then sprite:setScale(params.scale) end
        if params.scaleX then sprite:setScaleX(params.scaleX) end
        if params.scaleY then sprite:setScaleY(params.scaleY) end
        if params.rotation then sprite:setRotation(params.rotation) end

        if params.isFull then
            sprite:setScale(display.width / sprite:getContentSize().width)
            if sprite:getScale() * sprite:getContentSize().height < display.height then
                sprite:setScale(display.height / sprite:getContentSize().height)
            end
        end
    else
        error(string.format("display.newImageView() - create sprite failure, source \"%s\"", tostring(source)), 0)
    end

    return sprite
end


--[[--
创建 Sprite or CScale9Sprite
@param source  texture or sprite path
@param x
@param y y坐标
@param params table {
scale9:bool             -- is enable 9scale, default false
size:cc.size            -- content size, default nil
ap:cc.p                 -- setAnchorPoint, default nil
}
@return Sprite or CScale9Sprite
--]]
---@return cc.Sprite
function display.newNSprite(source,x,y,params)
    ---@type cc.Sprite
    local spriteClass = cc.Sprite
    local scale9 = false

    if type(x) == "table" and not x.x then
        -- x is params
        params = x
        x = nil
        y = nil
    end

    local params = params or PARAMS_EMPTY
    if params.scale9 or params.capInsets then
        ---@type CScale9Sprite
        spriteClass = CScale9Sprite
        scale9 = true
        params.capInsets = params.capInsets or RECT_ZERO
        params.rect = params.rect or RECT_ZERO
    end

    local sprite
    while true do
        -- create sprite
        if not source then
            sprite = spriteClass:create()
            break
        end

        local sourceType = type(source)
        if sourceType == "string" then
            if string.byte(source) == 35 then -- first char is #
                -- create sprite from spriteFrame
                if not scale9 then
                    sprite = spriteClass:createWithSpriteFrameName(string.sub(source, 2))
                else
                    sprite = spriteClass:createWithSpriteFrameName(string.sub(source, 2), params.capInsets)
                end
                break
            end

            -- create sprite from image file
            if display.TEXTURES_PIXEL_FORMAT[source] then
                cc.Texture2D:setDefaultAlphaPixelFormat(display.TEXTURES_PIXEL_FORMAT[source])
            end
            if not scale9 then
                sprite = spriteClass:create(checkImagePathFunc(source))
            else
                sprite = spriteClass:create(checkImagePathFunc(source), params.rect, params.capInsets)
            end
            if display.TEXTURES_PIXEL_FORMAT[source] then
                cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_BGR_A8888)
            end
            break
        elseif sourceType ~= "userdata" then
            error(string.format("display.newSprite() - invalid source type \"%s\"", sourceType), 0)
        else
            sourceType = tolua.type(source)
            if sourceType == "cc.SpriteFrame" then
                if not scale9 then
                    sprite = spriteClass:createWithSpriteFrame(source)
                else
                    sprite = spriteClass:createWithSpriteFrame(source, params.capInsets)
                end
            elseif sourceType == "cc.Texture2D" then
                sprite = spriteClass:createWithTexture(source)
            else
                error(string.format("display.newSprite() - invalid source type \"%s\"", sourceType), 0)
            end
        end
        break
    end
    local alias = checkbool(params.as)
    if sprite then
        --        if alias == true then
        --            textureCache:setAliasTexParameters(source)
        --        end
        if x and y then sprite:setPosition(checkint(x), checkint(y)) end
        if params.size then
            local size = {width = checkint(params.size.width),height = checkint(params.size.height)}
            sprite:setContentSize(size)
        end
        if params.ap then sprite:setAnchorPoint(params.ap) end
        if params.tag then sprite:setTag(params.tag) end
    else
        error(string.format("display.newNSprite() - create sprite failure, source \"%s\"", tostring(source)), 0)
    end

    return sprite
end


--[[--
创建toggleview
@param x
@param y y坐标
@param params table {
scale9:bool             -- is enable 9scale, default false
size:cc.size            -- content size, default nil
n:string                -- normal image
s:string                -- selected imgae
d:string                -- disabled image
}
@return CToggleView
--]]
---@return CToggleView
function display.newToggleView(x,y,params)
    ---@type CToggleView
    local button = CToggleView:create()
    local scale9 = false
    if type(x) == "table" and not x.x then
        -- x is params
        params = x
        x = nil
        y = nil
    end

    local params = params or PARAMS_EMPTY
    if params.scale9 or params.capInsets then
        scale9 = true
        params.capInsets = params.capInsets or RECT_ZERO
        params.rect = params.rect or RECT_ZERO
    end
    if scale9 == true then
        button:setScale9Enabled(true)
    end
    local normal = params.n
    local selected = params.s
    local disabled = params.d
    local alias = checkbool(params.as)
    if normal then
        if string.byte(normal) == 35 then -- first char is #
            normal = string.sub(normal, 2)
            button:setNormalSpriteFrameName(normal)
        else
            button:setNormalImage(checkImagePathFunc(normal))
            --            if alias == true then
            --                textureCache:setAliasTexParameters(normal)
            --            end
            if scale9 and button:getNormalImage() then
                button:getNormalImage():setCapInsets(params.capInsets)
                params.size = params.size or button:getNormalImage():getOriginalSize()
            end
        end
    end
    if selected then
        if string.byte(selected) == 35 then -- first char is #
            selected = string.sub(selected, 2)
            button:setSelectedSpriteFrameName(selected)
        else
            button:setSelectedImage(checkImagePathFunc(selected))
            if scale9 then
                button:getSelectedImage():setCapInsets(params.capInsets)
                params.size = params.size or button:getSelectedImage():getOriginalSize()
            end
            --            if alias == true then
            --                textureCache:setAliasTexParameters(selected)
            --            end
        end
    end
    if disabled then
        if string.byte(disabled) == 35 then -- first char is #
            disabled = string.sub(disabled, 2)
            button:setDisabledSpriteFrameName(disabled)
        else
            button:setDisabledImage(checkImagePathFunc(disabled))
            --            if alias == true then
            --                textureCache:setAliasTexParameters(disabled)
            --            end
        end
    end
    if button then
        if x and y then button:setPosition(checkint(x), checkint(y)) end
        if params.size then button:setContentSize(params.size) end
        if params.ap then button:setAnchorPoint(params.ap) end
        if params.tag then button:setTag(params.tag) end
    else
        error("display.newToggleView() - create sprite failure, source")
    end

    return button
end


--[[--
创建checkbox
@param x
@param y y坐标
@param params table {
size:cc.size            -- content size, default nil
n:string                -- normal image
s:string                -- selected imgae
d:string                -- disabled image
}
@return CCheckBox
--]]
---@return CCheckBox
function display.newCheckBox(x,y,params)
    ---@type CCheckBox
    local button = CCheckBox:create()
    local scale9 = false

    if type(x) == "table" and not x.x then
        -- x is params
        params = x
        x = nil
        y = nil
    end

    local normal = params.n
    local selected = params.s
    local disabled = params.d
    local alias = checkbool(params.as)
    if normal then
        if string.byte(normal) == 35 then -- first char is #
            normal = string.sub(normal, 2)
            button:setNormalSpriteFrameName(normal)
        else
            button:setNormalImage(checkImagePathFunc(normal))
            --            if alias == true then
            --                textureCache:setAliasTexParameters(disabled)
            --            end
        end
    end
    if selected then
        if string.byte(selected) == 35 then -- first char is #
            selected = string.sub(selected, 2)
            button:setCheckedSpriteFrameName(selected)
        else
            button:setCheckedImage(selected)
            --            if alias == true then
            --                textureCache:setAliasTexParameters(selected)
            --            end
        end
    end
    if disabled then
        if string.byte(disabled) == 35 then -- first char is #
            disabled = string.sub(disabled, 2)
            button:setDisabledNormalSpriteFrameName(disabled)
        else
            button:setDisabledNormalImage(disabled)
            button:setDisabledCheckedImage(disabled)
            --            if alias == true then
            --                textureCache:setAliasTexParameters(disabled)
            --            end
        end
    end
    if button then
        if x and y then button:setPosition(checkint(x), checkint(y)) end
        if params.size then button:setContentSize(params.size) end
        if params.ap then button:setAnchorPoint(params.ap) end
        if params.tag then button:setTag(params.tag) end
    else
        error("display.newCheckBox() - create sprite failure, source")
    end

    return button
end


--[[--
创建label标签，CLabel or label
ttf :是否是ttf字体如果是必需提供font地址
@param x number
@param y number
@return CLable
@see display.commonLabelParams
--]]
---@return CLabel
function display.newLabel(x,y,params)
    ---@type CLabel
    local label = CLabel:create()
    display.commonLabelParams(label, params)

    if label then
        if type(x) == "table" and not x.x then
            -- x is params
            params = x
            x = nil
            y = nil
        end
        local x,y  = checkint(x),checkint(y)
        if x and y then
            label:setPosition(x, y)
        end
    else
        error("display.newLabel() - create sprite failure, source")
    end
    return label
end


--[[--
设置cbutton 中的label或者label中的文字的相关通用参数
ttf :是否是ttf字体如果是必需提供font地址
@param source label or cbutton
@param params table {
offset:cc.p             -- label offset pos, only CButton, default nil
color:string            -- 3f color e.g:'#FFCC00'
text:string             -- text string
fontSize:int            -- font size, @see ccDefines#FontsSize
hAlign:int              -- label setHorizontalAlignment, default cc.TEXT_ALIGNMENT_CENTER
ap:cc.p                 -- setAnchorPoint, default nil
h:number, w:number      -- dimensions size
paddingW:int            -- 填充宽度，只针对按钮有效。默认为nil。如果使用，则会让按钮宽度适应文字宽度并且加上左右两边的填充距离。用于将按钮显示为和文字同样宽度的自适应模式。
maxW:int                -- 文字内容最大的宽度，超出宽度的话会截断并且末尾衔接 "..." 字符
maxL:int                -- 文字内容最大的行数，超出高度的话会截断并且末尾衔接 "..." 字符（多行需要配合设置 w 参数使用，一定要传参 fontSize）
enable:bool             -- is enable touch, default false
reqW :int               -- 要求文字所要达到的宽度 ,超过了就进行缩放
reqH :int               -- 要求文字所要达到的高度 ,超过了就进行缩放
}
--]]
---@param source CLabel | CButton | CToggleView
function display.commonLabelParams(source,params)
    ---@type CLabel
    local label = nil
    if tolua.type(source) == 'ccw.CButton' or tolua.type(source) == 'ccw.CToggleView' then
        label = source:getLabel()
        if params.offset then
            source:setLabelOffset(params.offset)
        end
    else
        label = source
    end
    if label == nil or tolua.isnull(label) then return end
    
    local isBMF = string.len(checkstr(label:getBMFontFilePath())) > 0
    local isTTF = params.ttf == true
    local isKeepOldTTF = false
    if params.ttf == nil then
        local oldTTFConfig = label:getTTFConfig()
        local hasTTFConfig = string.len(oldTTFConfig.fontFilePath) > 0
        isKeepOldTTF = hasTTFConfig and params.font == nil
        if isKeepOldTTF then
            isTTF = true
            params.font     = oldTTFConfig.fontFilePath
            params.fontSize = params.fontSize or oldTTFConfig.fontSize
        end
    end
    if isTTF then
        local fsize = checkint(params.fontSize)
        local scale = 1.0
        local ratio = display.width / display.height
        -- if ratio <= 1.501 then
        --     scale = (display.height / CC_DESIGN_RESOLUTION.height)
        -- end
        fsize = checkint(scale * fsize)
        if not isKeepOldTTF then
            label:setTTFConfig({fontFilePath = params.font,fontSize = fsize})
        end
        -- label:setLineBreakWithoutSpace(true)
        if params.w and params.h then
            label:setDimensions(params.w, params.h)
        elseif params.w then
            label:setWidth(params.w)
        end
        label.originalScale = 1
    else
        local app = cc.Application:getInstance()
        local target = app:getTargetPlatform()
        -- label:setLineBreakWithoutSpace(true)
        if not isBMF then
            if target == cc.PLATFORM_OS_WINDOWS then
                label:setSystemFontName(WIN_DEFAULT_SYS_FONT)
            else
                label:setSystemFontName(MAC_DEFAULT_SYS_FONT)
            end
        end
        local noScale = checkbool(params.noScale)
        if target == cc.PLATFORM_OS_MAC or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD or target == cc.PLATFORM_OS_WINDOWS then
            if params.fontSize then
                local fsize = checkint(params.fontSize)
                local scale = 1.0
                local ratio = display.width / display.height
                -- if ratio <= 1.501 then
                --     scale = (display.height / CC_DESIGN_RESOLUTION.height)
                -- end
                fsize = checkint(scale * fsize)
                if noScale then
                    label:setSystemFontSize(fsize)
                else
                    label:setSystemFontSize(fsize * 2)
                end
            end
            if params.w and params.h then
                if not noScale then
                    label:setDimensions(params.w * 2,params.h * 2)
                    label:setScale(0.5)
                else
                    label:setDimensions(params.w,params.h)
                end
            elseif params.w and not params.h then
                if not noScale then
                    label:setWidth(params.w * 2)
                    label:setScale(0.5)
                else
                    label:setWidth(params.w)
                end
            else
                if not noScale and not isBMF then
                    label:setScale(0.5)
                end
            end
            label.originalScale = 0.5
        else
            if params.fontSize then
                local fsize = checkint(params.fontSize)
                local scale = 1.0
                local ratio = display.width / display.height
                -- if ratio <= 1.501 then
                --     scale = (display.height / CC_DESIGN_RESOLUTION.height)
                -- end
                fsize = checkint(scale * fsize)
                label:setSystemFontSize(fsize)
            end
            if params.w and params.h then
                label:setDimensions(params.w, params.h)
            elseif params.w then
                label:setWidth(params.w)
            end
            label.originalScale = 1
        end
    end
    if params.outline then
        local outlineSize = math.max(1, checkint(params.outlineSize))
        label:enableOutline(ccc4FromInt(params.outline), outlineSize)
        -- label:enableShadow(ccc4FromInt(params.outline))
    end
    if params.color then
        if type(params.color) == 'string' then
            label:setColor(ccc3FromInt(params.color))
        else
            label:setColor(params.color)
        end
    end
    if params.text then
        display.fixLabelText(label, params)
    end

    if params.hAlign then
        label:setHorizontalAlignment(params.hAlign)
    end
    if params.ap then
        label:setAnchorPoint(params.ap)
    end
    if params.tag then
        label:setTag(params.tag)
    end

    if tolua.type(source) == 'ccw.CButton' or tolua.type(source) == 'ccw.CToggleView' then
        if params.paddingW then
            local safeW       = checkint(params.safeW)
            local labelWidth  = math.max(safeW, display.getLabelContentSize(label).width)
            local imgaeWidth  = source:getNormalImage():getContentSize().width
            local paddingW    = checkint(params.paddingW)
            local offset      = params.offset ~= nil and params.offset or cc.p(0, 0)
            local targetWidth = labelWidth + paddingW * 2 + offset.x
            source:setLabelOffset(cc.p(offset.x/2, offset.y))
            if source:isScale9Enabled() then
                source:setContentSize(cc.size(targetWidth, source:getContentSize().height))
            else
                source:getNormalImage():setScaleX(targetWidth / imgaeWidth)
            end
        end

        if params.paddingH then
            local safeH        = checkint(params.safeH)
            local labelHeight  = math.max(safeH, display.getLabelContentSize(label).height)
            if params.vertical == true and i18n.getLang() == 'en-us' then
                labelHeight = math.max(safeH, display.getLabelContentSize(label).width)
            end
            local imgaeHeight  = source:getNormalImage():getContentSize().height
            local paddingH     = checkint(params.paddingH)
            local offset       = params.offset ~= nil and params.offset or cc.p(0, 0)
            local targetHeight = labelHeight + paddingH * 2 + offset.y
            if params.paddingW then
                source:setLabelOffset(cc.p(offset.x/2, offset.y/2))
            else
                source:setLabelOffset(cc.p(offset.x, offset.y/2))
            end
            if source:isScale9Enabled() then
                source:setContentSize(cc.size(source:getContentSize().width, targetHeight))
            else
                source:getNormalImage():setScaleY(targetHeight / imgaeHeight)
            end
        end
    end

    -- local cl = label:getColor()
    -- if cl and label then
    --     if cl.r == 255 and cl.g == 255 and cl.b == 255 then
    --         local t = ccc4FromInt('000000')
    --         t.a = 50
    --         label:enableShadow(t,{ width = 0, height = -1 })
    --     else
    --         local t = ccc4FromInt('ffffff')
    --         t.a = 40
    --         label:enableShadow(t,{ width = 0, height = -1 })
    --     end
    -- end

    if params.enable then
        label:setTouchEnabled(true)
    end
    local lastScale = nil

    if params.reqW then
        if type(params.reqW) == 'number' or tonumber(params.reqW)   then
            local reqW = checkint(params.reqW)
            local labelSize =  display.getLabelContentSize(label)
            if labelSize.width > reqW  then
                local labelScale  = display.getLabelScale(label)
                lastScale = labelScale *  reqW /labelSize.width

            end
        end
    end
    if params.reqH then
        if type(params.reqH) == 'number' or tonumber(params.reqH)   then
            local reqH = checkint(params.reqH)
            local labelSize =  display.getLabelContentSize(label)
            if labelSize.height > reqH  then
                local labelScale  = display.getLabelScale(label)
                if lastScale then
                    lastScale = math.min(labelScale *  reqH /labelSize.height  , lastScale)
                else
                    lastScale = labelScale *  reqH /labelSize.height
                end

            end
        end
    end
    if lastScale then
        label:setScale(lastScale )
    end

    if params.enable then
        label:setTouchEnabled(true)
    end
end

---@param label CLabel
function display.fixLabelText(label, params)
    local str      = tostring(params.text)
    local maxW     = checkint(params.maxW)
    local maxL     = checkint(params.maxL)
    local fontSize = display.getLabelFontSize(label)

    if params.vertical == true then
        if i18n.getLang() == 'en-us' then
            label:setRotation(90)
        else
            local len  = utf8len(str)
            local text = ''
            for i =1 ,len do
                local word = utf8sub(str, i, 1)
                if i ~= len then
                    text = text .. word .. '\n'
                else
                    text = text .. word
                end
            end
            str = text
        end
    end

    label:setString(str)
    if maxW > 0 and display.getLabelContentSize(label).width > maxW then
        local len = utf8len(str)
        for i = len - 1, 1, -1 do
            label:setString(utf8sub(str, 1, i))
            if display.getLabelContentSize(label).width <= maxW then
                len = i
                break
            end
        end
        label:setString(utf8sub(str, 1, len - 1) .. '...')
    end
    if maxL > 0 and fontSize > 0 and math.floor(display.getLabelContentSize(label).height / fontSize) > maxL then
        local len = utf8len(str)

        local testLen    = len
        local labelW     = display.getLabelContentSize(label).width
        local aLineChart = math.floor(labelW / fontSize)
        for i = len - 1, 1, -aLineChart do
            label:setString(utf8sub(str, 1, i))
            if math.floor(display.getLabelContentSize(label).height / fontSize) > maxL then
                testLen = i
            else
                testLen = math.min(testLen + aLineChart, len)
                break
            end
        end
        len = testLen

        for i = len - 1, 1, -1 do
            label:setString(utf8sub(str, 1, i))
            if math.floor(display.getLabelContentSize(label).height / fontSize) <= maxL then
                len = i
                break
            end
        end
        label:setString(utf8sub(str, 1, len - 2) .. '...')
    end
end

---@param animationNode  真实动画表现node
function display.commonUIParams(target, params )
    if target then
        local animate = params.animate == nil and true or params.animate
        if params.po then
            target:setPosition(checkint(params.po.x), checkint(params.po.y))
        end
        if params.ap then
            target:setAnchorPoint(params.ap)
        end
        if params.tag then
            target:setTag(params.tag)
        end
        if params.isFlipX ~= nil then
            local isFlipX = params.isFlipX == true
            target:setScaleX(target:getScaleX() * (isFlipX == true and -1 or 1))
        end
        if params.cb then
            target:setOnClickScriptHandler(function(sender)
                if sender.setEnabled then sender:setEnabled(false) end
                if sender.setTouchEnabled then sender:setTouchEnabled(false) end
                if type(params.cb) == 'function' then
                    if animate or true then
                        print("1l3j13l1j3")
                        local isFlipX = sender:getScaleX() < 0
                        transition.execute(params.animationNode or sender, cc.Sequence:create(
                            cc.EaseOut:create(cc.ScaleTo:create(0.03, (isFlipX and -1 or 1) * 0.97, 0.97), 0.03),
                            cc.EaseOut:create(cc.ScaleTo:create(0.03, (isFlipX and -1 or 1) * 1, 1),0.03),
                            cc.CallFunc:create(function()
                                if sender.setEnabled then sender:setEnabled(true) end
                                if sender.setTouchEnabled then sender:setTouchEnabled(true) end
                                params.cb(sender) ---回调 需要根据需求开启按钮状态
                            end)
                        ))
                    else
                        if sender.setEnabled then sender:setEnabled(true) end
                        if sender.setTouchEnabled then sender:setTouchEnabled(true) end
                        params.cb(sender)
                    end
                end
            end)
        end
        if params.alpha then target:setOpacity(params.alpha) end
        if params.scale then target:setScale(params.scale) end
        if params.scaleX then target:setScaleX(params.scaleX) end
        if params.scaleY then target:setScaleY(params.scaleY) end
        if params.rotation then target:setRotation(params.rotation) end
    end
end

---@return CTextRich
function display.newRichLabel(x, y, params)
    ---@type CTextRich
    local label = CTextRich:create()
    label:setAnchorPoint(display.CENTER)
    if x and y then
        label:setPosition(checkint(x),checkint(y))
    end
    if label and params then
        local ap = params.ap or display.CENTER
        label:setAnchorPoint(ap)
        if params.w then
            label:setMaxLineLength(checkint(params.w))
        end
        if params.sp then
            label:setVerticalSpacing(checkint(params.sp))
        end
        display.insertRichLabel(label, params)
        if params.r and params.r == true then
            label:reloadData()
        end
        if params.tag then label:setTag(params.tag) end
    end
    return label
end

---@param node CTextRich
function display.insertRichLabel(node, params)
    if params and params.c and type(params.c) == 'table' then
        local app = cc.Application:getInstance()
        local target = app:getTargetPlatform()
        local sysFontName = target == cc.PLATFORM_OS_WINDOWS and WIN_DEFAULT_SYS_FONT or MAC_DEFAULT_SYS_FONT

        for i, v in pairs(params.c) do
            -- if v.tag then
            --     tag = checkint(v.tag)
            -- end
            if v.text then
                local color = cc.c3b(255,255,255)
                if v.color then
                    if type(v.color) == 'string' then
                        color = ccc3FromInt(v.color)
                    else
                        color = v.color
                    end
                end
                local fontName = v.ttf and v.font or sysFontName
                if target == cc.PLATFORM_OS_MAC or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD or target == cc.PLATFORM_OS_WINDOWS then
                    if node.insertElementWithTTF then
                        node:insertElementWithTTF(string.len(v.text) > 0 and v.text or ' ', fontName, checkint(v.fontSize) * 2, color, v.descr)
                    else
                        if v.ttf then
                            node:insertElementWithTTF(string.len(v.text) > 0 and v.text or ' ', fontName, checkint(v.fontSize) * 2, color, v.descr)
                        else
                            node:insertElement(string.len(v.text) > 0 and v.text or ' ', fontName, checkint(v.fontSize) * 2, color, v.descr)
                        end
                    end
                    node:setScale(0.5)
                else
                    if node.insertElementWithTTF then
                        node:insertElementWithTTF(string.len(v.text) > 0 and v.text or ' ', fontName, checkint(v.fontSize), color,v.descr)
                    else
                        if v.ttf then
                            node:insertElementWithTTF(string.len(v.text) > 0 and v.text or ' ', fontName, checkint(v.fontSize), color,v.descr)
                        else
                            node:insertElement(string.len(v.text) > 0 and v.text or ' ', fontName, checkint(v.fontSize), color,v.descr)
                        end
                    end
                end
            elseif v.img then
                if type(v.img) == 'string' then
                    ---@type CImageView
                    local image = CImageView:create(v.img)
                    local scale = 1
                    if v.scale then
                        scale = checknumber(v.scale)
                    end

                    if image then
                        image:setAnchorPoint(display.LEFT_BOTTOM)
                        local imageSize = image:getContentSize()
                        local imgLayer  = display.newLayer()
                        imgLayer:addChild(image)
                        if target == cc.PLATFORM_OS_MAC or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD or target == cc.PLATFORM_OS_WINDOWS then
                            imgLayer:setContentSize(cc.size(imageSize.width * scale * 2, imageSize.height * scale * 2))
                            node:insertElement(imgLayer, imageSize.width * scale * 2)
                            image:setScale(scale * 2)
                        else
                            imgLayer:setContentSize(cc.size(imageSize.width * scale, imageSize.height * scale))
                            node:insertElement(imgLayer, imageSize.width * scale)
                            image:setScale(scale)
                        end
                    end
                    if v.ap then
                        local x = checknumber(v.ap.x)
                        local y = checknumber(v.ap.y)
                        image:setAnchorPoint(cc.p(x ,y))
                    end
                end
            elseif v.node then
                if type(v.node) == 'userdata' then
                    ---@type cc.Node
                    local spriteNode = v.node
                    local scale = 1
                    if v.scale then
                        scale = checknumber(v.scale)
                    end
                    if spriteNode then
                        spriteNode:setAnchorPoint(display.LEFT_BOTTOM)
                        local spriteSize = spriteNode:getContentSize()
                        if target == cc.PLATFORM_OS_MAC or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD or target == cc.PLATFORM_OS_WINDOWS then
                            spriteNode:setContentSize(cc.size(spriteSize.width * scale * 2, spriteSize.height * scale * 2))
                            node:insertElement(spriteNode, spriteSize.width * scale * 2)
                            spriteNode:setScale(scale * 2)
                        else
                            spriteNode:setContentSize(cc.size(spriteSize.width * scale, spriteSize.height * scale))
                            node:insertElement(spriteNode, spriteSize.width * scale)
                            spriteNode:setScale(scale)
                        end
                    end
                    if v.ap then
                        local x = checknumber(v.ap.x)
                        local y = checknumber(v.ap.y)
                        spriteNode:setAnchorPoint(cc.p(x ,y))
                    end
                end
            end
        end
    end
end

---@param node CTextRich
function display.reloadRichLabel(node,params)
    node:removeAllElements()
    display.insertRichLabel(node, params)
    if params.c and #params.c > 0 then
        node:reloadData()
        if (params.width or params.height) and display.setNodeScale then
            display.setNodeScale(node , params)
        end
    end
end
-- 根据节点的boudingBox  设置节点的缩放 本方法最大缩放比例为一 只支持缩小 不支持放大
--[[
{
    width 节点的目标宽度
    height 节点的目标高度
}
]]
---@param node cc.Node
function display.setNodeScale(node , data)
    if node and ( not tolua.isnull(node))  then
        local rect = node:getBoundingBox()
        local nodeSize =  node:getContentSize()
        local scaleLabel  = rect.width /nodeSize.width
        local scale = 1
        if data.width then
            scale = data.width/nodeSize.width
        end
        if data.height then
            scale = data.height/ nodeSize.height > scale and scale or data.height/ nodeSize.height
        end
        scale = scale > scaleLabel and  scaleLabel   or scale
        node:setScale(scale)
    end
end
--[[--
通用的弹出窗口进入的显示功能
@param target cc.Node 弹出的目标节点
@param cb  function 回调方法
--]]
---@param target cc.Node
---@param cb fun():void
function display.animationIn(target,cb)
    target:runAction(cc.Sequence:create(cc.EaseBounceOut:create(cc.Spawn:create(cc.FadeIn:create(0.12),cc.ScaleTo:create(0.12,1.0))),cc.CallFunc:create(cb)))
end

--[[--
--因为ios label作了特殊处理，size被设置了一半，android没有，需要做不同处理 ttf统一未做处理
--]]
---@param label CLabel
function display.getLabelContentSize(label)
    local app = cc.Application:getInstance()
    local contentSize = label:getContentSize()

    if label.getTTFConfig then
        local ttfConfig = label:getTTFConfig()
        if 0 < string.len(string.gsub(ttfConfig.fontFilePath, ' ', '')) then
            return contentSize
        end
    end

    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_MAC or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD or target == cc.PLATFORM_OS_WINDOWS then
        contentSize = cc.size(contentSize.width*0.5,contentSize.height*0.5)
    end
    return contentSize
end

--[[--
--因为ios label作了特殊处理，size被设置了一半，android没有，需要做不同处理 ttf统一未做处理
    获取到
--]]
---@param label CLabel
function display.getLabelScale(label)
    local app = cc.Application:getInstance()
    if label.getTTFConfig then
        local ttfConfig = label:getTTFConfig()
        if 0 < string.len(string.gsub(ttfConfig.fontFilePath, ' ', '')) then
            return 1
        end
    end

    local target = app:getTargetPlatform()
    if target == cc.PLATFORM_OS_MAC or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD or target == cc.PLATFORM_OS_WINDOWS then
        return 0.5
    end
    return 1
end

---@param label CLabel
function display.getLabelFontSize(label)
    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    local fontSize = 0
    local ttfConf = checktable(label:getTTFConfig())
    if ttfConf.fontFilePath and string.len(ttfConf.fontFilePath) > 0 then
        fontSize = tonumber(ttfConf.fontSize)
    else
        fontSize = tonumber(label:getSystemFontSize())
    end
    if target == cc.PLATFORM_OS_MAC or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD or target == cc.PLATFORM_OS_WINDOWS then
        fontSize = fontSize * 0.5
    end
    local scale = 1.0
    local ratio = display.width / display.height
    -- if ratio <= 1.501 then
    --     scale = (display.height / CC_DESIGN_RESOLUTION.height)
    -- end
    fontSize = checkint(scale * fontSize)
    return fontSize
end

---@param node cc.Node
function display.locateMyLog(node)
    local parent = node
    while tolua.type(parent) ~= 'cc.CSceneExtension' do
        cclog('type: '..tolua.type(parent)..'+'..'tag:'..parent:getTag())
        parent = parent:getParent()
    end
end

--[[--
通用的弹出窗口退出显示功能
@param id
@param delayMs
@param title
@param message
--]]
function  display.pushLocalNotification(params)
    -- body
    local tVersion = getTargetAPIVersion()
    if tVersion >= 14 then
        local delayMs = checkint(params.delayMs)
        if (not params.title) or (not params.message) then
            return
        end
        local id = checkint(id)
        local title   = tostring(params.title)
        local message = tostring(params.message)
        if device.platform == 'ios' or device.platform == 'android' then
            FTUtils:pushLocalNotification(json.encode({id = id,delayMs = delayMs,title = title,message = message,ticker = 'summer'}))
        end
    end
end

--[[
将一组横向的node组成一排横向居中对齐目标node
@params targetNode node 对齐目标节点
@params nodes table 节点集
@params params table {
    y number y坐标
    spaceW number 每个node之间的间隔
}
--]]
---@param targetNode cc.Node
---@param nodes cc.Node[]
function display.setNodesToNodeOnCenter(targetNode, nodes, params)
    nodes = checktable(nodes)
    params = params or {}
    local nodesInfo = {}
    local totalLength = 0
    local targetNodeLength = targetNode:getContentSize().width * math.abs(targetNode:getScaleX())
    local spaceW = params.spaceW or 0
    for i,v in ipairs(nodes) do
        -- 计算总长
        local nodeLength = 0
        if 'ccw.CLabel' == tolua.type(v) then
            nodeLength = display.getLabelContentSize(v).width
        else
            nodeLength = v:getContentSize().width * math.abs(v:getScaleX())
        end
        nodeLength = nodeLength + spaceW
        totalLength = totalLength + nodeLength
        table.insert(nodesInfo, {node = v, nodeLength = nodeLength})
    end
    local paddingX = params.paddingW or (targetNodeLength - totalLength) * 0.5
    local preLength = paddingX
    for i,v in ipairs(nodesInfo) do
        local p = cc.p(preLength + v.nodeLength * v.node:getAnchorPoint().x, params.y or utils.getLocalCenter(targetNode).y)
        local parent = v.node:getParent()
        if parent then
            p = parent:convertToNodeSpace(targetNode:convertToWorldSpace(p))
        else
            print('display.setNodesToNodeOnCenter please addChild first')
        end
        v.node:setPosition(p)
        preLength = preLength + v.nodeLength
    end
end



return display
