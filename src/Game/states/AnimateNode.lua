local AnimateNode = class("AnimateNode", function()
    -- 66是透明亮
    -- local node = CColorView:create(ccc4FromInt("ff807355"))
    local node = CColorView:create(ccc4FromInt("ff807300"))
    node.name = 'AnimateNode'
    node:enableNodeEvents()
    return node
end)

local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local dataMgr = shareFacade:GetManager("DataManager")
local cardMgr = shareFacade:GetManager("CardManager")
local uiMgr   = shareFacade:GetManager("UIManager")
local httpManager   = shareFacade:GetManager("HttpManager")
--[[
-- args = {
--  size --大小
--  cardId --加载q版的角色文件
--  scale --加载q版的初始大小
--  enable --加载q版是否可点击
--  state --初始状态是什么样的
-- }
--]]


local NEXT_REWARD_CD = 30

local configs = dataMgr:GetConfigDataByFileName("icePlaceEventRates","iceBink")
local clickRate = 0
local movingRate = 0
if configs and next(configs) ~= nil then
    clickRate = checkint(checktable(configs)[tostring(1)].appearRate)
    movingRate = checkint(checktable(configs)[tostring(2)].appearRate)
end

local socket = require('socket')

function AnimateNode:ctor(...)
    local args = unpack({...})
    local size = args.size
    local cardId = args.cardId
    local scale = args.scale or 1.0
    local enable = args.enable == nil and true or args.enable

    self.startTime = socket:gettime()
    self.cardId = cardId
    self.viewData = nil
    self.isMoving = false
    self.mouseJoint = nil
    self:setContentSize(size)
    self:setTouchEnabled(enable)
    local shadowImage = display.newSprite(_res("ui/battle/battle_role_shadow.png"), size.width * 0.5, 0)
    shadowImage:setScale(0.5)
    self:addChild(shadowImage)
    shadowImage:setVisible(false)
    -- spine 节点
    local spineCache = SpineCache(SpineCacheName.GLOBAL)
    local qAvatar = nil
    local cInfo = gameMgr:GetCardDataByCardId(cardId)
    local spinePath = CardUtils.GetCardSpinePathBySkinId(cInfo.defaultSkinId)
    if spineCache:hasSpineCacheData(tostring(cInfo.defaultSkinId)) then
        qAvatar = AssetsUtils.GetCardSpineNode({skinId = cInfo.defaultSkinId, scale = scale, cacheName = SpineCacheName.GLOBAL, spineName = tostring(cInfo.defaultSkinId)})
    else
        qAvatar = AssetsUtils.GetCardSpineNode({skinId = cInfo.defaultSkinId, scale = scale})
    end
    qAvatar:setPosition(cc.p(size.width * 0.5, 0))
    qAvatar:setToSetupPose()
    self:addChild(qAvatar, 10)
    qAvatar:registerSpineEventHandler(handler(self, self.SpineAction), sp.EventType.ANIMATION_COMPLETE)
    local fullFlagSprite = display.newSprite(_res('ui/iceroom/fresh_ico_full_happy.png'),size.width * 0.5, size.height + 45)
    self:addChild(fullFlagSprite, 11)
    fullFlagSprite:setVisible(false)

    -- 上场与下载的逻辑标识图片
    local upOrdownSprite = display.newSprite(_res('ui/iceroom/refresh_ico_add.png'),size.width * 0.1, size.height)
    self:addChild(upOrdownSprite, 11)
    upOrdownSprite:setVisible(false)
    --添加活跃点的数值
    local vigourView = CLayout:create(cc.size(180, 30))
    display.commonUIParams(vigourView, { po = cc.p(size.width * 0.5 + 12, size.height + 10)})
    self:addChild(vigourView, 12)
    vigourView:setVisible(false)
    local progressBG = display.newImageView(_res('ui/home/teamformation/newCell/refresh_bg_tired_2.png'), {
            scale9 = true, size = cc.size(180,28)
        })
    display.commonUIParams(progressBG, {po = cc.p(size.width * 0.5 + 30, 32)})
    vigourView:addChild(progressBG,2)

    local operaProgressBar = CProgressBar:create(_res('ui/home/teamformation/newCell/team_img_leaf_red.png'))
    operaProgressBar:setBackgroundImage(_res('ui/home/teamformation/newCell/team_img_leaf_grey.png'))
    operaProgressBar:setDirection(eProgressBarDirectionLeftToRight)
    operaProgressBar:setAnchorPoint(cc.p(0, 0.5))
    operaProgressBar:setMaxValue(100)
    operaProgressBar:setValue(0)
    operaProgressBar:setPosition(cc.p(6, 30))
    vigourView:addChild(operaProgressBar,5)
    local vigourProgressBarTop =  display.newImageView(_res('ui/home/teamformation/newCell/team_img_leaf_free.png'),0,0,{as = false})
    vigourProgressBarTop:setAnchorPoint(cc.p(0,0.5))
    vigourProgressBarTop:setPosition(cc.p(2,30))
    vigourView:addChild(vigourProgressBarTop,6)

    local vigourLabel = display.newLabel(operaProgressBar:getContentSize().width + 6, operaProgressBar:getPositionY() + 2,fontWithColor(2,{
        ap = display.LEFT_CENTER, fontSize = 14, color = '6c6c6c', text = ""
    }))
    vigourView:addChild(vigourLabel, 6)

    --展示的数据
    self.viewData         = {
        qAvatar           = qAvatar,
        shadowImage       = shadowImage,
        fullFlagSprite    = fullFlagSprite,
        upOrdownSprite    = upOrdownSprite,
        vigourView        = vigourView,
        vigourProgressBar = operaProgressBar,
        vigourLabel       = vigourLabel,
    }
    if touchable then
        self.viewData.shadowImage = shadowImage
    end

    local IdleState = require('Game.states.IdleState')
    local RunState = require('Game.states.RunState')
    local AttackState = require('Game.states.AttackState')
    local WinState = require('Game.states.WinState')
    self.stateMgr = require("Frame.FSMState").new(self, IdleState.new(States.ID_IDLE))

    self.stateMgr:AddState(RunState.new(States.ID_RUN))
    self.stateMgr:AddState(AttackState.new(States.ID_ATTACK))
    self.stateMgr:AddState(WinState.new(States.ID_WIN))

    self.isLocked = true --禁用显示一个
    --是否启动
    self:schedule(function()
        if not self.isLocked then
            local cardInfo = gameMgr:GetCardDataByCardId(checkint(self.cardId))
            if cardInfo then
                local maxVigour = app.restaurantMgr:getCardVigourLimit(cardInfo.id)
                if checkint(cardInfo.vigour) >= maxVigour then
                    self.isLocked = true
                    self:ShowFullEnergy()
                else
                    self.isLocked = false
                end
            end
        end
    end,0.2) --检测是否已经满值
    if enable then
        self:setOnTouchMovedScriptHandler(function(sender, touch)
            xTry(function()
                local p = touch:getLocation()
                local x,y = self:getPosition()
                local distanceX = math.abs( p.x - x )
                local distanceY = math.abs( p.y - y )
                if distanceX > 50 and distanceY > 50 then
                    self.isMoving = true
                    if not self.mouseJoint then
                        local sceneRoot = uiMgr:GetCurrentScene()
                        local body = sceneRoot.viewData._world:GetBodyList()
                        local targetBodyRef = nil
                        while body do
                            local preBody = body
                            body = preBody:GetNext()
                            local udata = preBody:GetUserData()
                            if udata and tolua.type(udata) == 'ccw.CColorView' then
                                local id = udata:getTag()
                                if checkint(id ) == checkint(self.cardId)  then
                                    targetBodyRef = preBody
                                    break
                                end
                            end
                        end
                        if targetBodyRef then
                            local md = b2MouseJointDef:new()
                            md.bodyA = sceneRoot.viewData.groundBody
                            md.bodyB = targetBodyRef
                            md.target = b2Vec2(p.x  / PTM_RATIO, p.y/ PTM_RATIO)
                            md.collideConnected = true
                            md.maxForce = 1000.0 * targetBodyRef:GetMass()
                            self.mouseJoint = sceneRoot.viewData._world:CreateJoint(md)
                            targetBodyRef:SetAwake(true)
                        end
                    end
                    if self.mouseJoint then
                        self.mouseJoint:SetTarget(b2Vec2(p.x/PTM_RATIO,p.y/PTM_RATIO))
                    end
                end
            end, __G__TRACKBACK__)

            return true
        end)

        self:setOnTouchEndedScriptHandler(function(sender, touch)
            xTry(function()
                local p = touch:getLocation()
                if self.isMoving then
                    local sceneRoot = uiMgr:GetCurrentScene()
                    if self.mouseJoint then
                        sceneRoot.viewData._world:DestroyJoint(self.mouseJoint)
                        self.mouseJoint = nil
                    end
                    local iceroomMediator = shareFacade:RetrieveMediator('IceRoomMediator')
                    if iceroomMediator then
                        local leftEventRewardTimes = iceroomMediator.leftEventRewardTimes
                        if leftEventRewardTimes > 0 then
                            local touchTime = socket.gettime()
                            local timeDelta = touchTime - self.startTime
                            if timeDelta >= NEXT_REWARD_CD then
                                self.startTime = touchTime
                                utils.newrandomseed() --种子
                                local no = math.random(1, 1000)
                                if no >= 1 and no <= (movingRate * 10) then
                                    --中了一次概率的逻辑
                                    local playerCardId = gameMgr:GetCardDataByCardId(self.cardId).id
                                    httpManager:Post("IcePlace/IcePlaceEvent",SIGNALNAMES.ICEPLACE_Rewards,{ playerCardId = playerCardId})
                                end
                            end
                        end
                    end
                else
                    --正常的点击动作的逻辑,冒心心
                    --音效
                    CommonUtils.PlayCardSoundByCardId(self.cardId, SoundType.TYPE_ICEROOM_RANDOM, SoundChannel.ICE_ROOM_CLICK)

                    local particle = cc.ParticleSystemQuad:create('effects/red_heart.plist')
                    particle:setPosition(utils.getLocalCenter(self))
                    -- remove
                    particle:setAutoRemoveOnFinish(true)
                    self:addChild(particle, 11)
                    local iceroomMediator = shareFacade:RetrieveMediator('IceRoomMediator')
                    if iceroomMediator then
                        local leftEventRewardTimes = iceroomMediator.leftEventRewardTimes
                        if leftEventRewardTimes > 0 then
                            local touchTime = socket.gettime()
                            local timeDelta = touchTime - self.startTime
                            if timeDelta >= NEXT_REWARD_CD then
                                self.startTime = touchTime
                                utils.newrandomseed() --种子
                                local no = math.random(1, 1000)
                                if no >= 1 and no <= (clickRate * 10) then
                                    --中了一次概率的逻辑
                                    local playerCardId = gameMgr:GetCardDataByCardId(self.cardId).id
                                    httpManager:Post("IcePlace/IcePlaceEvent",SIGNALNAMES.ICEPLACE_Rewards,{ playerCardId = playerCardId})
                                end
                            end
                        end
                    end
                end
                self.isMoving = false
            end, __G__TRACKBACK__)
            return true --继续事件处理
        end)
    end
end


function AnimateNode:ShowFullEnergy()
    self.viewData.fullFlagSprite:setVisible(true)
    self:runAction(cc.RepeatForever:create(cc.TargetedAction:create(self.viewData.fullFlagSprite, ShakeAction:create(10,4))))
end

function AnimateNode:HiddenUporDown()
    self.viewData.upOrdownSprite:setVisible(false)
    self.viewData.vigourView:setVisible(false)
    self.viewData.shadowImage:setVisible(true)
    self:setColor(ccc4FromInt("ff807300"))
    self:setOpacity(0)
end
--[[
--是否显示是上场还是下场的逻辑
--]]
function AnimateNode:UporDownFlag(isup)
    if isup == nil then isup = true end
    self.viewData.upOrdownSprite:setVisible(true)
    if isup then
        self.viewData.vigourView:setVisible(false)
        self.viewData.upOrdownSprite:setTexture(_res("ui/iceroom/refresh_ico_add.png"))
    else
        self.viewData.upOrdownSprite:setTexture(_res("ui/iceroom/refresh_ico_remove.png"))
        self.viewData.vigourView:setVisible(true)
        --更新相关的进度数据
        local cardInfo = gameMgr:GetCardDataByCardId(checkint(self.cardId))
        if cardInfo then
            local vigour = checkint(cardInfo.vigour)
            local maxVigour = app.restaurantMgr:getCardVigourLimit(cardInfo.id)
            self.viewData.vigourLabel:setString(string.format('%d/%d',tostring(vigour),maxVigour))
            local ratio = (vigour / maxVigour) * 100
            self.viewData.vigourProgressBar:setValue(rangeId(ratio, 100))
            if (ratio > 40 and (ratio <= 60)) then
                self.viewData.vigourProgressBar:setProgressImage('ui/home/teamformation/newCell/team_img_leaf_yellow.png')
            elseif ratio > 60 then
                self.viewData.vigourProgressBar:setProgressImage('ui/home/teamformation/newCell/team_img_leaf_green.png')
            end
        end
    end
end
--[[
--当前节点是否自动播放到下一个功能
--]]
function AnimateNode:AutoPlay()
    return false
end

function AnimateNode:Start()
    self:schedule(function()
        --执行逻辑功能
        self.stateMgr:Update()
    end, 1.0)
end

--[[
--添加喂食特效的逻辑
--]]
function AnimateNode:AddVigourEffect()
    local animateNode = self:getChildByName('AddVigourEffect')
    if animateNode then return end
    PlayAudioClip(AUDIOS.UI.ui_levelup.id)
    local animateNode = sp.SkeletonAnimation:create("arts/effects/xxd.json","arts/effects/xxd.atlas", 0.8)
    animateNode:setAnimation(0, 'idle', false)
    animateNode:setName("AddVigourEffect")
    local size = self:getContentSize()
    display.commonUIParams(animateNode, {ap = display.CENTER_BOTTOM,po = cc.p(size.width * 0.5, 0)})
    animateNode:registerSpineEventHandler(handler(self, self.VigourSpineAction), sp.EventType.ANIMATION_COMPLETE)
    self:addChild(animateNode,10)
end

function AnimateNode:VigourSpineAction(event)
    local animateNode = self:getChildByName('AddVigourEffect')
    if animateNode then
        animateNode:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
        animateNode:runAction(cc.Spawn:create(cc.FadeOut:create(0.1),cc.RemoveSelf:create()))
    end
end
--[[
--spine动作的逻辑功能
--]]
function AnimateNode:SpineAction(event)
    self.stateMgr:DispatchEvent(States.EID_COMPELETE)
end
--[[
--  喂食成功后的逻辑
--]]
function AnimateNode:FeedSuccess( )
    self.stateMgr:ChangeState(States.ID_WIN) --播放成功的动画
    self:AddVigourEffect()
    --是否加星星
    self:runAction(cc.Sequence:create(cc.DelayTime:create(2), cc.CallFunc:create(function()
        self.stateMgr:ChangeState(States.ID_IDLE) --回归状态
    end)))
end

function AnimateNode:onEnter()

end

function AnimateNode:onCleanup()
    self.viewData.qAvatar:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
    if self.mouseJoint then
        local sceneRoot = uiMgr:GetCurrentScene()
        if sceneRoot.viewData then
            sceneRoot.viewData._world:DestroyJoint(self.mouseJoint)
        end
        self.mouseJoint = nil
    end
    --清除一些角色缓存,主要是冰场中产生的数据
    local cardData = gameMgr:GetCardDataByCardId(self.cardId)
    SpineCache(SpineCacheName.GLOBAL):removeCacheData(tostring(cardData.defaultSkinId))
    display.removeUnusedSpriteFrames() --清除一些缓存
end

return AnimateNode
