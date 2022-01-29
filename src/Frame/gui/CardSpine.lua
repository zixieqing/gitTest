--[[
 * author : kaishiqi
 * descpt : 卡牌 spine
]]
---@class CardSpine : CLayout
local CardSpine = class('CardSpine', function()
    return display.newLayer(0, 0, {name = 'CardSpine', enableEvent = true})
end)


function CardSpine:ctor(args)
    -- parse args
    local args                  = args or {}
    self.cardConfId_            = checkint(args.confId)
    self.cardSkinId_            = checkint(args.skinId)
    self.cardSkinPath_          = checkstr(args.skinPath)
    self.cardSpineScale_        = args.scale ~= nil and args.scale or 1
    self.spineCacheName_        = args.cacheName
    self.spineAnimationName_    = args.spineName
    self.eventHandlerMap_       = {}
    self.animationList_         = {}

    -- 原始动画的动画信息 [ObjectSpineDataStruct]
    self.oriAnimationInfo_      = args.oriAnimationInfo
    -- 修正素体和目标spine之间spine差异的动画速度
    self.innerFixTimeScale_     = 1
    -- 当前动画的运行时间
    self.currentAnimationTimer_ = 0
    -- 动态加载完毕的回调函数
    self.downloadOverCallback_  = args.downloadOverCallback

    -- 内部嵌套的spine处理事件配置
    self.innerEventHandlerConfig_ = {
        [sp.EventType.ANIMATION_START] = handler(self, self.OnSpineEventStartHandler_)
    }

    -- check spine path
    if string.len(self.cardSkinPath_) == 0 then
        if self.cardConfId_ > 0 then
            self.cardSkinPath_ = CardUtils.GetCardSpinePathByCardId(self.cardConfId_)
        elseif self.cardSkinId_ > 0 then
            self.cardSkinPath_ = CardUtils.GetCardSpinePathBySkinId(self.cardSkinId_)
        end
    end

    -- verify spine
    if string.len(self.cardSkinPath_) > 0 then
        local isValidity, verifyMap = app.gameResMgr:verifySpine(self.cardSkinPath_)
        self.isResValidity_ = isValidity
    end

    -- create display spine
    self.displaySpine_ = self.isResValidity_ and self:createCardSpine_() or self:createBaseSpine_()
    self:addChild(self.displaySpine_)
end


-------------------------------------------------
-- public method

--[[
    @param deltaTime float
]]
function CardSpine:update(deltaTime)
    if self.displaySpine_ then
        self.displaySpine_:update(deltaTime)
    end
end


--[[
    @param trackIndex int
    @param name string
    @param loop bool
]]
function CardSpine:setAnimation(trackIndex, name, loop)
    self.animationList_ = {}
    if self.displaySpine_ then
        self.displaySpine_:setAnimation(trackIndex, name, loop)
        table.insert(self.animationList_, {trackIndex, name, loop})
    end
end


--[[
    @param trackIndex int
    @param name string
    @param loop bool
]]
function CardSpine:addAnimation(trackIndex, name, loop, delay)
    if self.displaySpine_ then
        self.displaySpine_:addAnimation(trackIndex, name, loop, delay or 0)
        table.insert(self.animationList_, {trackIndex, name, loop, delay})
    end
end


function CardSpine:getAnimationsData()
    return self.displaySpine_ and self.displaySpine_:getAnimationsData() or nil
end


function CardSpine:getCurrent()
    return self.displaySpine_ and self.displaySpine_:getCurrent() or nil
end


function CardSpine:clearTracks()
    if self.displaySpine_ then
        self.displaySpine_:clearTracks()
    end
end


function CardSpine:clearTrack(trackIndex)
    if self.displaySpine_ then
        self.displaySpine_:clearTrack(trackIndex)
    end
end


function CardSpine:setToSetupPose()
    if self.displaySpine_ then
        self.displaySpine_:setToSetupPose()
    end
end


function CardSpine:getTimeScale()
    if self.displaySpine_ then
        return self:GetOuterTimeScale_()
    else
        return 0
    end
end
function CardSpine:setTimeScale(scale)
    if self.displaySpine_ then
        self.displaySpine_:setTimeScale(scale * self:GetInnerFixTimeScale_())
    end
end


function CardSpine:getBorderBox(customName)
    return self.displaySpine_ and self.displaySpine_:getBorderBox(customName) or nil
end


function CardSpine:findBone(boneName)
    return self.displaySpine_ and self.displaySpine_:findBone(boneName) or nil
end


function CardSpine:setColor(color)
    if self.displaySpine_ then
        self.displaySpine_:setColor(color)
    end
end


function CardSpine:registerSpineEventHandler(handler, eventType)
    self.eventHandlerMap_[eventType] = handler
    self:RegisterSpineEventHandler_(handler, eventType)
end
function CardSpine:unregisterSpineEventHandler(eventType)
    self.eventHandlerMap_[eventType] = nil
    self:UnregisterSpineEventHandler_(eventType)
end
--[[
注册动画回调函数
@params handler function 回调函数
@params eventType sp.EventType 事件类型
--]]
function CardSpine:RegisterSpineEventHandler_(handler, eventType)
    if self.displaySpine_ and not self:HasInnerEventHandlerByEventType_(eventType) then
        self.displaySpine_:registerSpineEventHandler(handler, eventType)
    end
end
--[[
注销动画回调函数
@params eventType sp.EventType 事件类型
--]]
function CardSpine:UnregisterSpineEventHandler_(eventType)
    if self.displaySpine_ and not self:HasInnerEventHandlerByEventType_(eventType) then
        self.displaySpine_:unregisterSpineEventHandler(eventType)
    end
end


-------------------------------------------------
-- private method

function CardSpine:createBaseSpine_()
    local baseCardPath = 'base/baseCard'
    local baseCardName = string.fmt('%1_%2', baseCardPath, self.cardSpineScale_)
    if not SpineCache(SpineCacheName.GLOBAL):hasSpineCacheData(baseCardName) then
        SpineCache(SpineCacheName.GLOBAL):addCacheData(baseCardPath, baseCardName, self.cardSpineScale_)
    end

    local baseSpine = SpineCache(SpineCacheName.GLOBAL):createWithName(baseCardName)

    -- 初始化一次嵌套的事件回调
    self:InitInnerSpineEventHandler_(baseSpine)

    return baseSpine
end


function CardSpine:createCardSpine_()
    local cardSpineNode = nil
    local realSpinePath = utils.deletePathExtension(_res(self.cardSkinPath_ .. '.atlas'))  -- 不能用 json，因为真实 json 文件是 xxxxx.json.zip
    if self.spineCacheName_ then
        if not SpineCache(self.spineCacheName_):hasSpineCacheData(self.spineAnimationName_) then
            SpineCache(self.spineCacheName_):addCacheData(realSpinePath, self.spineAnimationName_, self.cardSpineScale_)
        end
        cardSpineNode = SpineCache(self.spineCacheName_):createWithName(self.spineAnimationName_)
    else
        cardSpineNode = sp.SkeletonAnimation:create(realSpinePath .. '.json', realSpinePath .. '.atlas', self.cardSpineScale_)
    end

    -- 初始化一次嵌套的事件回调
    self:InitInnerSpineEventHandler_(cardSpineNode)

    return cardSpineNode or self:createBaseSpine_()
end


function CardSpine:updateDisplaySpine_()
    -- get current status
    local timeScale                     = self:getTimeScale()
    local currentName                   = self:getCurrent()
    local currentAnimationLeftTime      = 0
    local currentScaleX                 = 1
    local currentScaleY                 = 1

    -- clean old spine
    if self.displaySpine_ and not tolua.isnull(self.displaySpine_) then
        -- 当前spine的外部缩放
        currentScaleX = self.displaySpine_:getScaleX()
        currentScaleY = self.displaySpine_:getScaleY()

        -- 计算当前动画剩余的时间
        local currentAnimationInfo = self.displaySpine_:getAnimationsData()[currentName]
        if nil ~= currentAnimationInfo then
            currentAnimationLeftTime = math.max(0, currentAnimationInfo.duration - self:GetCurrentAnimationTimer_())
        end

        -- 注销内部嵌套的spine事件回调
        self:DestroyInnerSpineEventHandler_(self.displaySpine_)

        -- 注销外部的spine事件回调
        for eventType, _ in pairs(self.eventHandlerMap_) do
            self:UnregisterSpineEventHandler_(eventType)
        end
        self.displaySpine_:removeFromParent()
        self.displaySpine_ = nil
    end

    -- create new spine
    self.displaySpine_ = self.isResValidity_ and self:createCardSpine_() or self:createBaseSpine_()
    self.displaySpine_:setTimeScale(timeScale)
    self:addChild(self.displaySpine_)

    -- 同步当前spine状态至原状态
    self.displaySpine_:setScaleX(currentScaleX)
    self.displaySpine_:setScaleY(currentScaleY)

    -- FIXME: 还没想到如何衔接动画
    -- continue animation
    local isFindAnimation = false
    for i, animationConfig in ipairs(self.animationList_) do
        local trackIndex     = animationConfig[1]
        local animationName  = animationConfig[2]
        local animationLoop  = animationConfig[3]
        local animationDelay = animationConfig[4] or 0
        if isFindAnimation then
            self.displaySpine_:addAnimation(trackIndex, animationName, animationLoop, animationDelay)
        else
            if currentName == animationName then
                isFindAnimation = true

                self.displaySpine_:setAnimation(trackIndex, animationName, animationLoop)

                ------------ 拉伸动画速度 计算拉伸的time scale 造成衔接的假象 ------------
                -- /***********************************************************************************************************************************\
                --  * warning 此处确保setAnimation后同一帧调用animation start事件回调 先计算修正的innerTimeScale 再去拉伸动画速度 否则此办法是没用的
                -- \***********************************************************************************************************************************/

                if 0 < currentAnimationLeftTime then
                    local targetAniInfo = self:GetOriSpineAnimationDataByName_(animationName)
                    if nil ~= targetAniInfo then
                        local targetDuration = targetAniInfo.animationDuration
                        local mixFixedTimeScale = targetDuration / currentAnimationLeftTime
                        local newInnerFixedTimeScale = mixFixedTimeScale * self:GetInnerFixTimeScale_()
                        self.displaySpine_:setTimeScale(self:GetOuterTimeScale_() * newInnerFixedTimeScale)
                    end
                end
                ------------ 拉伸动画速度 计算拉伸的time scale 造成衔接的假象 ------------

            end
        end
    end

    -- continue event listen
    for eventType, handler in pairs(self.eventHandlerMap_) do
        self:RegisterSpineEventHandler_(handler, eventType)
    end

    -- 下载完毕的回调函数
    if nil ~= self.downloadOverCallback_ then
        self.downloadOverCallback_()
    end
end


--[[
直接操作spine动画的timescale方法
--]]
function CardSpine:GetTimeScale_()
    return self.displaySpine_ and self.displaySpine_:getTimeScale() or 0
end
function CardSpine:SetTimeScale_(scale)
    if self.displaySpine_ then
        self.displaySpine_:setTimeScale(scale)
    end
end


--[[
修正源动画和素体动画之间的动画时间差异
@params name string 动画名字
--]]
function CardSpine:FixAnimationTimeScaleByName_(name)
    if nil ~= self.displaySpine_ then
        local oriAnimationInfo = self:GetOriSpineAnimationDataByName_(name)
        local curAnimationInfo = self:GetCurSpineAnimationDataByName_(name)

        if nil ~= oriAnimationInfo and nil ~= curAnimationInfo then

            local oriDuration = checknumber(oriAnimationInfo.animationDuration)
            local curDuration = checknumber(curAnimationInfo.duration)

            if 0 ~= oriDuration * curDuration then
                local outerTimeScale = self:GetOuterTimeScale_()
                local innerFixTimeScale = curDuration / oriDuration
                self:SetInnerFixTimeScale_(innerFixTimeScale)
                self:SetTimeScale_(outerTimeScale * innerFixTimeScale)
            end

        end
    end
end


--[[
初始化内部嵌套的事件回调
@params spineNode sp.SkeletonAnimation 目标spine动画节点
--]]
function CardSpine:InitInnerSpineEventHandler_(spineNode)
    for eventType, handler in pairs(self.innerEventHandlerConfig_) do
        spineNode:registerSpineEventHandler(handler, eventType)
    end
end
--[[
销毁内部嵌套的事件回调
@params spineNode sp.SkeletonAnimation 目标spine动画节点
--]]
function CardSpine:DestroyInnerSpineEventHandler_(spineNode)
    for eventType, handler in pairs(self.innerEventHandlerConfig_) do
        spineNode:unregisterSpineEventHandler(eventType)
    end
end


-------------------------------------------------
-- handler

function CardSpine:onEnter()
    if string.len(self.cardSkinPath_) > 0 and not self.isResValidity_ then

        -- add download listen
        self.downloadEvent_ = string.fmt('%1_%2', DOWNLOAD_DEFINE.CARD_SPINE.event, self.cardSkinPath_)
        app:RegistObserver(self.downloadEvent_, mvc.Observer.new(self.onResDownloadedHandler_, self))

        -- check download res
        app.downloadMgr:addResTask(_spn(self.cardSkinPath_), self.downloadEvent_)
    end
end


function CardSpine:onCleanup()
    if self.downloadEvent_ then
        
        -- clean download task
        app.downloadMgr:delResTask(self.cardSkinPath_)

        -- remove download listen
        app:UnRegistObserver(self.downloadEvent_, self)
    end
end


function CardSpine:onResDownloadedHandler_(signal)
    local dataBody = signal:GetBody()

    if dataBody.isDownloaded and dataBody.resPath == self.cardSkinPath_ then
        -- check downloaded
        if app.gameResMgr:verifySpine(self.cardSkinPath_) then
            self.isResValidity_  = true
            self:updateDisplaySpine_()
        end
    end
end


--[[
动作开始的回调处理 处理一次动画的缩放
@params event table {
    animation string 动画名
    loopCount int 循环次数
    trackIndex int 时间线序号
    type string 回调类型
}
--]]
function CardSpine:OnSpineEventStartHandler_(event)
    if not event then return end

    local animationName = event.animation
    -- 修正一次素体和源之间的动画时间差异
    self:FixAnimationTimeScaleByName_(animationName)

    -- 将事件传出去
    local handler = self.eventHandlerMap_[sp.EventType.ANIMATION_START]
    if nil ~= handler then
        handler(event)
    end
end


-------------------------------------------------
-- get set method

--[[
根据动作名字获取源spine动画信息的信息
@params name string 动画名字
@return _ ObjectSpineAnimationDataStruct spine动画信息
--]]
function CardSpine:GetOriSpineAnimationDataByName_(name)
    if nil ~= self.oriAnimationInfo_ and nil ~= self.oriAnimationInfo_.animationsData then
        return self.oriAnimationInfo_.animationsData[name]
    else
        return nil
    end
end


--[[
根据动作名字获取当前spine动画信息的信息
@params name string 动画名字
--]]
function CardSpine:GetCurSpineAnimationDataByName_(name)
    if nil ~= self.displaySpine_ then
        return self.displaySpine_:getAnimationsData()[tostring(name)]
    else
        return nil
    end
end


--[[
内部修正目标spine和素体之间动作时间上的差异
--]]
function CardSpine:GetInnerFixTimeScale_()
    return self.innerFixTimeScale_
end
function CardSpine:SetInnerFixTimeScale_(scale)
    self.innerFixTimeScale_ = scale
end
function CardSpine:ResetInnerFixTimeScale_()
    self:SetInnerFixTimeScale_(1)
end


--[[
获取外部动画缩放的值
--]]
function CardSpine:GetOuterTimeScale_()
    return self:GetTimeScale_() / self:GetInnerFixTimeScale_()
end


--[[
根据事件类型判断是否存在内部嵌套的spine处理事件
@params eventType sp.EventType
@return _ bool 是否存在内部嵌套的spine处理事件
--]]
function CardSpine:HasInnerEventHandlerByEventType_(eventType)
    return nil ~= self.innerEventHandlerConfig_[eventType]
end


--[[
当前动画运行的时间
--]]
function CardSpine:GetCurrentAnimationTimer_()
    return self.currentAnimationTimer_
end
function CardSpine:SetCurrentAnimationTimer_(time)
    self.currentAnimationTimer_ = time
end
function CardSpine:ResetCurrentAnimationTimer_()
    self.currentAnimationTimer_ = 0
end


return CardSpine
