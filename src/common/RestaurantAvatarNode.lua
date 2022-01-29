--[[
 * author : kaishiqi
 * descpt : 餐厅 avatar节点
]]
local RestaurantAvatarNode = class('RestaurantAvatarNode', function()
    local AIMG = 'ui/common/story_tranparent_bg.png'
    local node = display.newImageView(_res(AIMG))
    node.name  = 'RestaurantAvatarNode'
    node:enableNodeEvents()
    node:setCascadeColorEnabled(true)
    node:setCascadeOpacityEnabled(true)
    return node
end)

local DOWNLOAD_EVENT = DOWNLOAD_DEFINE.AVATAR_RES.event

local CreateView = nil


-------------------------------------------------
-- life cycle

function RestaurantAvatarNode:ctor(args)
    -- parse args
    local args   = checktable(args)
    local initX  = checkint(args.x)
    local initY  = checkint(args.y)
    local confId = checkint(args.confId)
    local initAp = args.ap or display.LEFT_BOTTOM
    local enable = args.enable == true

    self.playingAudioId_  = nil  -- 当前音频
    self.animationName_   = nil  -- 当前动画
    self.animationConf_   = nil  -- 动画配表
    self.animationNode_   = nil  -- 动画节点
    self.downloadResPath_ = nil  -- 资源地址
    self.downloadPtlPath_ = nil  -- 粒子地址
    self.isPlayingAudio_  = false  -- 是否 播放音频中
    self.isPlayingAnime_  = false  -- 是否 播放动画中
    self.isControllable_  = true
    self.fullEffectLayer_ = args.effectLayer
    
    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)
    
    -- addlistener
    app:RegistObserver(DOWNLOAD_EVENT, mvc.Observer.new(self.onResDownloadedHandler_, self))
    display.commonUIParams(self, {cb = handler(self, self.onClickAvatarNodeHandler_), animate = false})
    
    -- update view
    self:setAvatarId(confId)
    self:setAnchorPoint(initAp)
    self:setPosition(initX, initY)
    self:setTouchEnabled(enable)
end


CreateView = function()
    local view = display.newLayer()

    local audioLayer = display.newLayer()
    view:addChild(audioLayer)
    
    local avatarLayer = display.newLayer()
    view:addChild(avatarLayer)
    
    local particleLayer = display.newLayer()
    view:addChild(particleLayer)

    return {
        view          = view,
        audioLayer    = audioLayer,
        avatarLayer   = avatarLayer,
        particleLayer = particleLayer,
    }
end


-------------------------------------------------
-- get / set

function RestaurantAvatarNode:getViewData()
    return self.viewData_
end


function RestaurantAvatarNode:getAvatarId()
    return checkint(self.avatarId_)
end
function RestaurantAvatarNode:setAvatarId(avatarId)
    self.avatarId_ = checkint(avatarId)
    self:updateAvatar_()
    self:updateParticle_()
end


function RestaurantAvatarNode:isAnimationNode()
    return next(self.animationConf_ or {}) ~= nil
end


-------------------------------------------------
-- public method


-------------------------------------------------
-- private method

function RestaurantAvatarNode:updateAvatar_()
    -- reset animation data
    self.animationName_  = nil
    self.animationConf_  = nil
    self.animationNode_  = nil
    self.isPlayingAudio_ = false
    self.isPlayingAnime_ = false

    -- stop animation audio
    self:stopAnimationAudio_()

    -- clean download task
    app.downloadMgr:delResTask(self.downloadResPath_)

    -- clean avatar layer
    local avatarSize  = cc.size(0, 0)
    local avatarLayer = self:getViewData().avatarLayer
    avatarLayer:removeAllChildren()

    if self:getAvatarId() > 0 then
        -- update content size
        local locationConf = CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', self:getAvatarId()) or {}
        avatarSize.width  = checkint(locationConf.objectWidth)
        avatarSize.height = checkint(locationConf.objectLength)

        -- record animations conf
        self.animationName_ = checkstr(locationConf.initAnimation)
        self.animationConf_ = CommonUtils.GetConfigNoParser('restaurant', 'avatarAnimation', self:getAvatarId()) or {}

        -------------------------------------------------
        -- update avatar spine
        if self:isAnimationNode() then
            local avatarSpinePath = AssetsUtils.GetRestaurantAvatarSpinePath(self:getAvatarId())
            local isValidity, verifyMap = app.gameResMgr:verifySpine(avatarSpinePath)
            if isValidity then
                -- add spine cache
                if not SpineCache(SpineCacheName.GLOBAL):hasSpineCacheData(avatarSpinePath) then
                    SpineCache(SpineCacheName.GLOBAL):addCacheData(avatarSpinePath, avatarSpinePath, 1)
                end
                
                -- addChild avatar spine
                self.animationNode_ = SpineCache(SpineCacheName.GLOBAL):createWithName(avatarSpinePath)
                self.animationNode_:registerSpineEventHandler(handler(self, self.onAnimationCompleteHandler_), sp.EventType.ANIMATION_COMPLETE)
                self.animationNode_:setPosition(cc.p(avatarSize.width/2, 0))
                avatarLayer:addChild(self.animationNode_)
                self:updateAnimation_()

            else
                -- download avatar spine
                if verifyMap and verifyMap['atlas'] and verifyMap['atlas'].remoteDefine then
                    self.downloadResPath_ = avatarSpinePath
                    app.downloadMgr:addResTask(_spn(avatarSpinePath), DOWNLOAD_EVENT)
                end
                self.isControllable_ = false
            end

        -------------------------------------------------
        -- update avatar image
        else
            local avatarImagePath = AssetsUtils.GetRestaurantBigAvatarPath(self:getAvatarId())
            local isValidity, resRemoteDefine = app.gameResMgr:verifyRes(avatarImagePath)
            if isValidity then
                -- addChild avatar image
                local avatarImage = display.newImageView(avatarImagePath, 0, 0, {ap = display.LEFT_BOTTOM})
                avatarLayer:addChild(avatarImage)

                -- 兼容老逻辑，如果 avatarLocation 表中全部配了物体尺寸就不需要这句话了
                -- Ps：如果做动态下载的话，最好是全配上
                if avatarSize.width == 0 and avatarSize.height == 0 then
                    avatarSize = avatarImage:getContentSize()
                end

            else
                -- downLoad avatar image
                if resRemoteDefine then
                    self.downloadResPath_ = avatarImagePath
                    app.downloadMgr:addResTask(avatarImagePath, DOWNLOAD_EVENT)
                end
            end

        end
    end
    self:setContentSize(avatarSize)
end


function RestaurantAvatarNode:updateParticle_()
    -- clean download task
    app.downloadMgr:delResTask(self.downloadPtlPath_)
    
    -- clean particle layer
    local particleLayer = self:getViewData().particleLayer
    particleLayer:removeAllChildren()

    if self:getAvatarId() > 0 then
        local locationConf = CommonUtils.GetConfigNoParser('restaurant', 'avatarLocation', self:getAvatarId()) or {}
        local particleConf = string.split2(checkstr(locationConf.particle), ',')
        local particleId   = checkstr(particleConf[1])
        local particleX    = checkint(particleConf[2])
        local particleY    = checkint(particleConf[3])

        -- avatar particle
        if string.len(particleId) > 0 then
            local avtarParticlePath = AssetsUtils.GetRestaurantAvatarParticlePath(particleId)
            local isValidity, verifyMap = app.gameResMgr:verifyParticle(avtarParticlePath)
            if isValidity then

                -- addChild avatar particl
                local particleNode  = cc.ParticleSystemQuad:create(avtarParticlePath)
                local particleLayer = self:getViewData().particleLayer
                particleNode:setPosition(cc.p(particleX, particleY))
                particleLayer:addChild(particleNode)

            else
                -- download avatar spine
                if verifyMap and verifyMap['plist'] and verifyMap['plist'].remoteDefine then
                    self.downloadPtlPath_ = avtarParticlePath
                    app.downloadMgr:addResTask(_ptl(avtarParticlePath), DOWNLOAD_EVENT)
                end

            end
        end

    end
end


function RestaurantAvatarNode:toNextAnimation_()
    local animationConf = self.animationConf_[self.animationName_] or {}
    self:switchAnimation_(animationConf.to)
end
function RestaurantAvatarNode:switchAnimation_(animationName)
    self.animationName_ = checkstr(animationName)
    self:updateAnimation_()
end


function RestaurantAvatarNode:updateAnimation_()
    if not self.animationNode_ then return end

    -- play animation
    self.isPlayingAnime_  = true
    local animationConf   = self.animationConf_[self.animationName_] or {}
    local isLoopAnimation = checkint(animationConf.loop) == 1
    -- self.animationNode_:setToSetupPose()  -- 动画说不用我们负责重置状态
    self.animationNode_:setAnimation(0, self.animationName_, isLoopAnimation)

    -- play audio
    self:playAnimationAudio_(animationConf.audioId, animationConf.audioTime)

    -- update controllable
    if self.animationNode_:getAnimationsData()[self.animationName_] and not isLoopAnimation then
        self.isControllable_ = false
    else
        self.isPlayingAnime_ = false
        self:checkAnimationEnded_()
    end

    -- check full effect
    if checkint(animationConf.fullEffectId) > 0 then
        self:createFullEffectAvatar_(animationConf.fullEffectId)
    end
end
function RestaurantAvatarNode:checkAnimationEnded_()
    if not self.isPlayingAnime_ and not self.isPlayingAudio_ then
        self.isControllable_ = true
        local animationConf  = self.animationConf_[self.animationName_] or {}
        local isAutoToNext   = checkint(animationConf.autoJump) == 1
        if isAutoToNext then
            self:toNextAnimation_()
        end
    end
end


function RestaurantAvatarNode:stopAnimationAudio_()
    if self.playingAudioId_ then
        self:getViewData().audioLayer:stopAllActions()
        self.playingAudioId_ = nil
        self.isPlayingAudio_ = false
        if self.playingAudioObj_ then
            self.playingAudioObj_:Stop(true)
            self.playingAudioObj_ = nil
        end
    end
end
function RestaurantAvatarNode:playAnimationAudio_(audioId, audioTime)
    self:stopAnimationAudio_()
    
    self.isPlayingAudio_ = true
    self.playingAudioId_ = checkstr(audioId)
    local audioEndedFunc = function()
        self.playingAudioId_ = nil
        self.isPlayingAudio_ = false
        self:checkAnimationEnded_()
    end

    if string.len(self.playingAudioId_) > 0 then
        self.playingAudioObj_ = PlayAudioClip(self.playingAudioId_, true)
        self:getViewData().audioLayer:runAction(cc.Sequence:create(
            cc.DelayTime:create(math.max(checkint(audioTime), 0.1)),
            cc.CallFunc:create(audioEndedFunc)
        ))
    else
        audioEndedFunc()
    end
end


function RestaurantAvatarNode:createFullEffectAvatar_(fullEffectId)
    if not self.fullEffectLayer_ then return end
    
    local avatarEffectId = checkint(fullEffectId)
    if avatarEffectId <= 0 then return end

    local avatarSpinePath = AssetsUtils.GetRestaurantAvatarSpinePath(avatarEffectId)
    local isValidity, verifyMap = app.gameResMgr:verifySpine(avatarSpinePath)
    if isValidity then
        -- effect layer
        local effectLayer = display.newLayer(0, 0, {color = cc.r4b(0), enable = true, size = self.fullEffectLayer_:getContentSize()})
        self.fullEffectLayer_:addChild(effectLayer)

        -- add spine cache
        if not SpineCache(SpineCacheName.GLOBAL):hasSpineCacheData(avatarSpinePath) then
            SpineCache(SpineCacheName.GLOBAL):addCacheData(avatarSpinePath, avatarSpinePath, 1)
        end
        
        -- addChild avatar spine
        local effectAvatar = SpineCache(SpineCacheName.GLOBAL):createWithName(avatarSpinePath)
        effectAvatar:setPosition(utils.getLocalCenter(effectLayer))
        effectLayer:addChild(effectAvatar)
        
        effectAvatar:registerSpineEventHandler(function(event)
            effectLayer:runAction(cc.RemoveSelf:create())
        end, sp.EventType.ANIMATION_COMPLETE)
        effectAvatar:setAnimation(0, 'idle', false)  -- 约定好，所有全屏特效都是 idle

    else
        -- download avatar spine
        if verifyMap and verifyMap['atlas'] and verifyMap['atlas'].remoteDefine then
            app.downloadMgr:addResTask(_spn(avatarSpinePath))
        end
    end
end


-------------------------------------------------
-- handler

function RestaurantAvatarNode:onEnter()
end


function RestaurantAvatarNode:onCleanup()
    -- stop animation audio
    self:stopAnimationAudio_()

    -- clean download task
    app.downloadMgr:delResTask(self.downloadResPath_)
    app.downloadMgr:delResTask(self.downloadPtlPath_)
    
    -- remove download listen
    app:UnRegistObserver(DOWNLOAD_EVENT, self)
end


function RestaurantAvatarNode:onResDownloadedHandler_(signal)
    if tolua.isnull(self) then return end
    local dataBody = signal:GetBody()

    -- check downloaded
    if dataBody.isDownloaded then

        if dataBody.resPath == self.downloadResPath_ then
            if self:isAnimationNode() then
                if app.gameResMgr:verifySpine(self.downloadResPath_) then
                    self:updateAvatar_()
                end
            else
                if app.gameResMgr:verifyRes(self.downloadResPath_) then
                    self:updateAvatar_()
                end
            end

        elseif dataBody.resPath == self.downloadPtlPath_ then
            if app.gameResMgr:verifyParticle(self.downloadPtlPath_) then
                self:updateParticle_()
            end
        end

    end
end


function RestaurantAvatarNode:onClickAvatarNodeHandler_(sender)
    if not self.isControllable_ then return end
    self:toNextAnimation_()
end


function RestaurantAvatarNode:onAnimationCompleteHandler_(event)
    if self.isPlayingAnime_ then
        self.isPlayingAnime_ = false
        self:checkAnimationEnded_()
    end
end


return RestaurantAvatarNode
