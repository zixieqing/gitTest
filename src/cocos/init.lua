--[[
]]
---@class cc
-- Cocos2d
---@field public Ref                        cc.Ref
---@field public Node                       cc.Node
---@field public Label                      cc.Label
---@field public Sprite                     cc.Sprite
---@field public ClippingNode               cc.ClippingNode
---@field public Director                   cc.Director
---@field public GLViewImpl                 cc.GLViewImpl
---@field public FileUtils                  cc.FileUtils
---@field public Texture2D                  cc.Texture2D
---@field public Application                cc.Application
---@field public AnimationCache             cc.AnimationCache
---@field public SpriteFrameCache           cc.SpriteFrameCache
---@field public EventCustom                cc.EventCustom
---@field public EventListenerMouse         cc.EventListenerMouse
---@field public EventListenerCustom        cc.EventListenerCustom
---@field public EventListenerKeyboard      cc.EventListenerKeyboard
---@field public EventListenerTouchOneByOne cc.EventListenerTouchOneByOne
---@field public UserDefault                cc.UserDefault
-- CocosWidget
---@field public CCMsgDelegate                         cc.CCMsgDelegate
---@field public CCBundle                              cc.CCBundle
---@field public CCMsgManager                          cc.CCMsgManager
---@field public CSceneManager                         cc.CSceneManager
---@field public CSceneExtension                       cc.CSceneExtension
---@field public CCSceneExTransition                   cc.CCSceneExTransition
---@field public CCSceneExTransitionEase               cc.CCSceneExTransitionEase
---@field public CCSceneExTransitionOriented           cc.CCSceneExTransitionOriented
---@field public CCSceneExTransitionZoomFlipX          cc.CCSceneExTransitionZoomFlipX
---@field public CCSceneExTransitionZoomFlipY          cc.CCSceneExTransitionZoomFlipY
---@field public CCSceneExTransitionFlipX              cc.CCSceneExTransitionFlipX
---@field public CCSceneExTransitionFlipY              cc.CCSceneExTransitionFlipY
---@field public CCSceneExTransitionFlipAngular        cc.CCSceneExTransitionFlipAngular
---@field public CCSceneExTransitionZoomFlipAngular    cc.CCSceneExTransitionZoomFlipAngular
---@field public CCSceneExTransitionProgress           cc.CCSceneExTransitionProgress
---@field public CCSceneExTransitionProgressInOut      cc.CCSceneExTransitionProgressInOut
---@field public CCSceneExTransitionProgressOutIn      cc.CCSceneExTransitionProgressOutIn
---@field public CCSceneExTransitionProgressVertical   cc.CCSceneExTransitionProgressVertical
---@field public CCSceneExTransitionProgressHorizontal cc.CCSceneExTransitionProgressHorizontal
---@field public CCSceneExTransitionProgressRadialCW   cc.CCSceneExTransitionProgressRadialCW
---@field public CCSceneExTransitionProgressRadialCCW  cc.CCSceneExTransitionProgressRadialCCW
---@field public CCSceneExTransitionFade               cc.CCSceneExTransitionFade
---@field public CCSceneExTransitionFadeTR             cc.CCSceneExTransitionFadeTR
---@field public CCSceneExTransitionFadeBL             cc.CCSceneExTransitionFadeBL
---@field public CCSceneExTransitionFadeUp             cc.CCSceneExTransitionFadeUp
---@field public CCSceneExTransitionFadeDown           cc.CCSceneExTransitionFadeDown
---@field public CCSceneExTransitionSlideInL           cc.CCSceneExTransitionSlideInL
---@field public CCSceneExTransitionSlideInR           cc.CCSceneExTransitionSlideInR
---@field public CCSceneExTransitionSlideInB           cc.CCSceneExTransitionSlideInB
---@field public CCSceneExTransitionSlideInT           cc.CCSceneExTransitionSlideInT
---@field public CCSceneExTransitionSplitCols          cc.CCSceneExTransitionSplitCols
---@field public CCSceneExTransitionSplitRows          cc.CCSceneExTransitionSplitRows
---@field public CCSceneExTransitionMoveInL            cc.CCSceneExTransitionMoveInL
---@field public CCSceneExTransitionMoveInR            cc.CCSceneExTransitionMoveInR
---@field public CCSceneExTransitionMoveInT            cc.CCSceneExTransitionMoveInT
---@field public CCSceneExTransitionMoveInB            cc.CCSceneExTransitionMoveInB
---@field public CCSceneExTransitionTurnOffTiles       cc.CCSceneExTransitionTurnOffTiles
---@field public CCSceneExTransitionCrossFade          cc.CCSceneExTransitionCrossFade
---@field public CCSceneExTransitionRotoZoom           cc.CCSceneExTransitionRotoZoom
---@field public CCSceneExTransitionJumpZoom           cc.CCSceneExTransitionJumpZoom
---@field public CCSceneExTransitionShrinkGrow         cc.CCSceneExTransitionShrinkGrow
---@field public CCSceneExTransitionPageTurn           cc.CCSceneExTransitionPageTurn
cc = cc or {}


require "cocos.cocos2d.Cocos2d"
require "cocos.cocos2d.Cocos2dConstants"
require "cocos.cocos2d.functions"

--__G__TRACKBACK__ = function(msg)
--    local msg = debug.traceback(msg, 3)
--    print(msg)
--    return msg
--end

-- opengl
require "cocos.cocos2d.Opengl"
require "cocos.cocos2d.OpenglConstants"
-- audio
require "cocos.cocosdenshion.AudioEngine"
-- cocosstudio
if nil ~= ccs then
    require "cocos.cocostudio.CocoStudio"
end
-- ui
if nil ~= ccui then
    require "cocos.ui.GuiConstants"
    require "cocos.ui.experimentalUIConstants"
end

-- extensions
require "cocos.extension.ExtensionConstants"
-- network
require "cocos.network.NetworkConstants"
-- Spine
if nil ~= sp then
    require "cocos.spine.SpineConstants"
end

require "cocos.cocos2d.deprecated"
require "cocos.cocos2d.DrawPrimitives"

-- Lua extensions
require "cocos.cocos2d.bitExtend"

if CC_LOAD_DEPRECATED_API then
    -- CCLuaEngine
    require "cocos.cocos2d.DeprecatedCocos2dClass"
    require "cocos.cocos2d.DeprecatedCocos2dEnum"
    require "cocos.cocos2d.DeprecatedCocos2dFunc"
    require "cocos.cocos2d.DeprecatedOpenglEnum"

    -- register_cocostudio_module
    if nil ~= ccs then
        require "cocos.cocostudio.DeprecatedCocoStudioClass"
        require "cocos.cocostudio.DeprecatedCocoStudioFunc"
    end


    -- register_cocosbuilder_module
    require "cocos.cocosbuilder.DeprecatedCocosBuilderClass"

    -- register_cocosdenshion_module
    require "cocos.cocosdenshion.DeprecatedCocosDenshionClass"
    require "cocos.cocosdenshion.DeprecatedCocosDenshionFunc"

    -- register_extension_module
    require "cocos.extension.DeprecatedExtensionClass"
    require "cocos.extension.DeprecatedExtensionEnum"
    require "cocos.extension.DeprecatedExtensionFunc"

    -- register_network_module
    require "cocos.network.DeprecatedNetworkClass"
    require "cocos.network.DeprecatedNetworkEnum"
    require "cocos.network.DeprecatedNetworkFunc"

    -- register_ui_moudle
    if nil ~= ccui then
        require "cocos.ui.DeprecatedUIEnum"
        require "cocos.ui.DeprecatedUIFunc"
    end
end
-- cocosbuilder
require "cocos.cocosbuilder.CCBReaderLoad"

-- physics3d
require "cocos.physics3d.physics3d-constants"

if CC_USE_FRAMEWORK then
    require "cocos.framework.init"
end
