--[[
 * author : kaishiqi
 * descpt : 卡牌 live2d
]]
local CardL2dNode = class('CardL2dNode', function()
    return display.newLayer(0, 0, {name = 'CardL2dNode', enableEvent = true})
end)

-- 是否支持 live2d 的判断
local l2dmgr = LAppLive2DManager and LAppLive2DManager:GetInstance() or nil
-- l2dmgr = nil  -- debug use


function CardL2dNode.InitEnv(rootContainer)
    if l2dmgr and rootContainer then
        if l2dmgr.lAppView_ and tolua.isnull(l2dmgr.lAppView_) == nil then
            l2dmgr.lAppView_ = nil
        end

        if not l2dmgr.lAppView_ then
            local containerSize = rootContainer:getContentSize()
            -- 必须 live2d 模型显示在这里
            -- LAppView 继承自 CLayout
            -- setTouchEnabled 或者 setEnabled 可以控制是否接收touch事件
            l2dmgr.lAppView_ = LAppView:create()
            l2dmgr.lAppView_:setPosition(PointZero)
            l2dmgr.lAppView_:setAnchorPoint(display.LEFT_BOTTOM)
            l2dmgr.lAppView_:setContentSize(display.size)
            l2dmgr.lAppView_:setTouchEnabled(false)
            -- l2dmgr.lAppView_:setBackgroundColor(cc.r4b(220))
            rootContainer:addChild(l2dmgr.lAppView_)

            local screenScale = 1624 * display.height / 750 / display.width
            local scaleMatrix = CubismMatrix44:new()
            scaleMatrix:Scale(screenScale, screenScale)
            -- 很关键 不让scaleMatrix被释放
            l2dmgr.scaleMatrix = scaleMatrix
            l2dmgr:SetViewMatrix(scaleMatrix)
            
            app:DispatchObservers(CARD_LIVE2D_NODE_INIT_ENV, {rootContainer = rootContainer})
        end
    end
end


function CardL2dNode.CleanEnv()
    if l2dmgr then
        -- 释放所有模型
        l2dmgr:ReleaseAllModel()

        if l2dmgr.lAppView_ then
            if not tolua.isnull(l2dmgr.lAppView_) then
                app:DispatchObservers(CARD_LIVE2D_NODE_CLEAN_ENV, {rootContainer = l2dmgr.lAppView_:getParent()})
                l2dmgr.lAppView_:removeFromParent()
            end
            l2dmgr.lAppView_ = nil
        end
    end
end


function CardL2dNode.AppendGlobalLvContainerList(rootContainer)
    GlobalLvContainerList = GlobalLvContainerList or {}
    table.insert(GlobalLvContainerList, rootContainer)
end
function CardL2dNode.PopupGlobalLvContainerList(rootContainer, isNeedToNextLvContainer)
    if GlobalLvContainerList then
        -- to popup list
        for i = table.nums(GlobalLvContainerList), 1, -1 do
            local lvContainer = GlobalLvContainerList[i]
            if lvContainer == rootContainer or tolua.isnull(lvContainer) then
                table.remove(GlobalLvContainerList, i)
            end
        end
        
        -- to next lvContainer
        if #GlobalLvContainerList > 0 and isNeedToNextLvContainer then
            -- init l2d env
            local lastLvContainer = GlobalLvContainerList[#GlobalLvContainerList]
            app.cardL2dNode.InitEnv(lastLvContainer)

            if lastLvContainer.refreshFunc then
                lastLvContainer.refreshFunc()
            end
        end
    end
end


function CardL2dNode.GetEnvView()
    if l2dmgr then
        return l2dmgr.lAppView_
    else
        return nil
    end
end


-------------------------------------------------
-- life cycle

function CardL2dNode:ctor(args)
    -- parse args
    local args   = args or {}
    local roleId = args.roleId
    self.bgMode_ = args.bgMode == true

    if string.match(roleId, '^%d+') then
        if CommonUtils.GetGoodTypeById(roleId) == GoodsType.TYPE_CARD_SKIN then
            local skinConf = CardUtils.GetCardSkinConfig(roleId) or {}
            self.cardId_   = checkint(skinConf.cardId)
            self.skinId_   = checkint(roleId)
        else
            self.cardId_ = checkint(roleId)
            self.skinId_ = CardUtils.GetCardSkinId(self.cardId_)
            if string.find(roleId, '_') then
                self.skinId_ = roleId
            elseif self.skinId_ == 0 then
                self.skinId_ = roleId
            end
        end
        self.isCard_   = true
        self.drawName_ = CardUtils.GetCardDrawNameBySkinId(self.skinId_)
    else
        self.isCard_   = false
        self.roleId_   = roleId
        self.drawName_ = tostring(self.roleId_)
    end
    
    self.aliasName_    = string.fmt('l2d_%1_%2', tostring(self.drawName_), ID(self))
    self.l2dMotion_    = args.faceId
    self.motionMap_    = {}
    self.textureList_  = {}
    self.prototype_    = {}
    self.isInited_     = false
    self.isReleased_   = false
    self.worldPos_     = nil
    self.selfScaleX_   = nil
    self.selfScaleY_   = nil
    self.delayMotion_  = nil
    self.loadedModel_  = false
    self.modelTexture_ = nil
end


function CardL2dNode:initView()
    if self.isInited_ then return end
    self.isInited_ = true

    -- create view
    if l2dmgr and l2dmgr.lAppView_ then
        self:loadModle_()
    else
        if l2dmgr == nil then
            self:createL2dErrorView('l2dmgr Null')
        elseif not l2dmgr.lAppView_ then
            self:createL2dErrorView('l2d not InitEnv')
        else
            self:createL2dErrorView()
        end
    end

    -- init views
    self:setMotion(self.l2dMotion_)
end


function CardL2dNode:createL2dErrorView(errorMsg)
    local nodeSize  = self:getContentSize()
    local centerPos = cc.p(nodeSize.width/2, nodeSize.height/2)
    local l2dErrMsg = errorMsg and errorMsg .. '\n' or ''
    self:addChild(display.newLayer(centerPos.x, centerPos.y, {color = cc.r4b(150), size = cc.size(400, 600), ap = display.CENTER}))
    self:addChild(display.newLabel(centerPos.x, centerPos.y, {fontSize = 64, color = '#FFFFFF', text = l2dErrMsg .. self:getAliasName()}))
end


-------------------------------------------------
-- get / set

function CardL2dNode:isCard()
    return self.isCard_
end


function CardL2dNode:getAliasName()
    return self.aliasName_
end


function CardL2dNode:isBgMode()
    return self.bgMode_ == true
end


function CardL2dNode:getMotionList()
    return table.keys(self.motionMap_ or {})
end


-------------------------------------------------
-- public

function CardL2dNode:setMotion(motionName)
    self.l2dMotion_ = checkstr(motionName)
    if l2dmgr and string.len(self.l2dMotion_) > 0 then

        local live2dModel = l2dmgr:GetModelByName(self:getAliasName())
        if live2dModel and self.loadedModel_ then

            -- 停止所有动作
            live2dModel:StopAllMotions()

            -- 开始一个动作
            -- 第一个参数是model3.json里面motions的组别
            -- 第二个参数是组别里面的index 从0开始
            -- 第三个参数是动作优先级
            -- 优先级有1，2，3
            -- 优先级与当前播放动作优先级相同不会播放动作（继续当前动作）
            -- 优先级比当前播放动作优先级高会播放动作（停止当前动作）
            -- 优先级为3时会强制播放动作（停止当前动作）
            -- 第四个参数表示是否循环
            if next(self.motionMap_[tostring(self.l2dMotion_)] or {}) then
                if next(self.motionMap_[tostring(self.l2dMotion_)][1] or {}) then
                    live2dModel:StartMotion(self.l2dMotion_, 0, 3, false)
                else
                    logInfo.add(logInfo.Types.ERROR, string.fmt('[live2d %1] motion %2 index %d does not exist', self:getAliasName(), motionName, 0))
                end
            else
                logInfo.add(logInfo.Types.ERROR, string.fmt('[live2d %1] motion group %2 does not exist', self:getAliasName(), motionName))
            end
                
        else
            self.delayMotion_ = self.l2dMotion_
        end

    end
end


-------------------------------------------------
-- private

function CardL2dNode:overrideFunc_(funcName, bindFunc)
    if not self.prototype_[funcName] then
        self.prototype_[funcName] = self[funcName]
        self[funcName] = function(obj, ...)
            self.prototype_[funcName](obj, ...)
            if bindFunc then bindFunc(...) end
        end
    end
end


function CardL2dNode:releaseModle_()
    if self.isReleased_ then return end

    if l2dmgr then
        -- 释放自身模型
        for i = 1, l2dmgr:GetModelCount() do
            local l2dIndex = i - 1  -- index begin from 0
            local l2dModel = l2dmgr:GetModel(l2dIndex)
            if l2dModel:GetModelName() == self:getAliasName() then
                l2dmgr:ReleaseModel(l2dIndex)
                break
            end
        end

        -- 释放纹理
        if self.modelTexture_ and not tolua.isnull(self.modelTexture_) then
            -- self.modelTexture_:onNodeEvent("exit", nil)
            self.modelTexture_:removeFromParent()
        end
        self.modelTexture_ = nil
    end

    self:unscheduleUpdate()
end


function CardL2dNode:loadModle_()
    self:releaseModle_()
    
    if l2dmgr then
        local live2dAliasName = self:getAliasName()
        local live2dModelDir  = CardUtils.GetCardLive2dModelDir(self.drawName_, self:isBgMode())
        local live2dModelName = CardUtils.GetCardLive2dModelName(self.drawName_)
        local live2dModelPath = CardUtils.GetCardLive2dModelPath(self.drawName_, self:isBgMode())

        if CardUtils.IsExistentGetCardLive2dModel(self.drawName_, self:isBgMode()) then
            --[[
                加载模型的参数有3个
                1、模型文件所在文件夹路径
                2、模型model3.json文件名
                3、别名 string
            ]]
            self:stopAllActions()
            self:runAction(cc.CallFunc:create(function()
                l2dmgr:LoadAssets(live2dModelDir, live2dModelName, live2dAliasName)

                local live2dModel = l2dmgr:GetModelByName(self:getAliasName())
                live2dModel:MakeRenderingTarget()

                local children = cc.Director:getInstance():getRunningScene():getChildren()
                for k, v in pairs(children) do
                    if "cc.RenderTexture" == tolua.type(v) then
                        v:removeFromParent(false)
                        v:setCascadeOpacityEnabled(true)
                        if l2dmgr.lAppView_ and not tolua.isnull(l2dmgr.lAppView_) then
                            l2dmgr.lAppView_:addChild(v)
                            self.modelTexture_ = v
                            -- self.modelTexture_:onNodeEvent("exit", function (obj)
                            --     print('self.modelTexture_:onExit', self.drawName_)
                            --     if self.modelTexture_ and not tolua.isnull(self.modelTexture_) then
                            --         self.modelTexture_:onNodeEvent("exit", nil)
                            --         self:releaseModle_()
                            --         self.modelTexture_ = nil
                            --         self.isReleased_   = true
                            --     end
                            -- end)

                            -- cache texture
                            for _, texturePath in ipairs(self.textureList_) do
                                local textureImg = display.newImageView(live2dModelDir .. texturePath)
                                textureImg:setVisible(false)
                                self.modelTexture_:addChild(textureImg)
                            end
                        end
                        break
                    end
                end

                self.loadedModel_ = true
                
                -- update motion
                if self.delayMotion_ then
                    self:setMotion(self.delayMotion_)
                    self.delayMotion_ = nil
                end
                
                -- update l2dModel
                self:onUpdateModel_()
            end))

            -- motionMap
            local model3Json = json.decode(FTUtils:getFileData(live2dModelPath))
            if model3Json and model3Json.FileReferences then
                self.motionMap_   = model3Json.FileReferences.Motions or {}
                self.textureList_ = model3Json.FileReferences.Textures or {}
            else
                self.motionMap_   = {}
                self.textureList_ = {}
            end

            self:scheduleUpdateWithPriorityLua(handler(self, self.onUpdateModel_), 0)
            
        else
            self:unscheduleUpdate()
            self:createL2dErrorView('not Existent')
        end
    end
end


-------------------------------------------------
-- handler

function CardL2dNode:onEnter()
    self:initView()

    if APP_WINDOW_RESIZE then
        AppFacade.GetInstance():RegistObserver(APP_WINDOW_RESIZE, mvc.Observer.new(self.onWindowResize_, self))
    end
end


function CardL2dNode:onExit()
    self:releaseModle_()
    self.isReleased_ = true
end


function CardL2dNode:onCleanup()
    if APP_WINDOW_RESIZE then
        AppFacade.GetInstance():UnRegistObserver(APP_WINDOW_RESIZE, self)
    end
end


function CardL2dNode:onWindowResize_(signal)
    local data = signal:GetBody()
    -- win最小化时会传入 size(0,0) 如果这时候调用 live2dModel:MakeRenderingTarget() 会报无效尺寸的错误。所以这里做个容错。
    if checkint(data.frameSize.width) > 0 and checkint(data.frameSize.height) > 0 then
        self.isInited_   = false
        self.worldPos_   = nil
        self.selfScaleX_ = nil
        self.selfScaleY_ = nil
        self:initView()
    end
end


function CardL2dNode:onUpdateModel_()
    if l2dmgr then
        local live2dModel = l2dmgr:GetModelByName(self:getAliasName())
        if live2dModel and self.loadedModel_ then

            if not tolua.isnull(self:getParent()) then
                -- 设置位置 屏幕中心是0，0
                -- 按距离屏幕中心的百分比设置位置
                -- live2dModel:GetModelMatrix():SetPosition(0, 0)
                local pos = self:getParent():convertToWorldSpace(cc.p(self:getPositionX(), self:getPositionY()))
                if self.worldPos_ and self.worldPos_.x == checkint(pos.x) and self.worldPos_.y == checkint(pos.y) then
                else
                    local size = self:getContentSize()
                    local screenScale = display.height / 750
                    local posX = (pos.x + size.width / 2 - display.cx) / 812 / screenScale
                    local posY = (pos.y + size.height / 2 - display.cy) / 375 / screenScale
                    live2dModel:GetModelMatrix():SetPosition(posX, posY)
                    self.worldPos_ = cc.p(checkint(pos.x), checkint(pos.y))
                end
            end

            -- 暂时只实现根据自身缩放2️而缩放模型，以后有需要再写成任意一个父级变化自己就更新
            if self.selfScaleX_ and self.selfScaleY_ and self.selfScaleX_ == self:getScaleX() and self.selfScaleY_ == self:getScaleY() then
            else
                -- 缩放 scale 不指定的话 模型会根据屏幕大小进行缩放 就是说不一定为1
                live2dModel:GetModelMatrix():Scale(self:getScaleX(), self:getScaleY())
                self.selfScaleX_ = self:getScaleX()
                self.selfScaleY_ = self:getScaleY()
            end

            -- if not tolua.isnull(self:getParent()) then
                -- live2dModel:SetSpriteColor(1, 1, 1, self:getOpacity() / 255)
            -- end

        end
    end
end


return CardL2dNode