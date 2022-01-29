--[[
剧情对白的入口初始化逻辑功能
---]]
local GameScene = require( 'Frame.GameScene' )
local BootLoader = class('BootLoader', GameScene)

local shareFacade = AppFacade.GetInstance()

local scheduler = require('cocos.framework.scheduler')

local OFFSETY = 150
local OFFSETBOTTOM = 60
local SAFE_GAP = 20

local RED_COLOR = 'f3600f'
local openDebugRect = false

local function CreateVisitorView(location, params)
    local root = CLayout:create(display.size)
    display.commonUIParams(root, {po  = display.center})
    local size = cc.size(638,280) --376
    local view = CLayout:create(size)
    -- view:setBackgroundColor(cc.c4b(100,100,100,100))
    display.commonUIParams(view, {ap = display.LEFT_BOTTOM,po = cc.p(params.x, params.y)})
    root:addChild(view, 5)
    local petImage = display.newNSprite(_res('ui/guide/guide_ico_pet'),0,0)
    view:addChild(petImage,10)
    if location == 1 then
        display.commonUIParams(petImage, {ap = display.LEFT_BOTTOM, po = cc.p(0, 0)})
    else
        petImage:setFlippedX(true)
        display.commonUIParams(petImage, {ap = display.RIGHT_BOTTOM, po = cc.p(size.width, 0)})
    end

    if params.params and table.nums(params.params) > 0 then
        local clipper = cc.ClippingNode:create()
        clipper:setContentSize(display.size)
        display.commonUIParams(clipper, {ap = cc.p(0.5,0.5), po = display.center})
        root:addChild(clipper)

        local area = params.params[1]
        local spriteName = _res('ui/guide/guide_ico_rectangle_2')
        local lsize = cc.size(92,92)
        if area.size then
            lsize = area.size
        end
        local back = cc.LayerColor:create(cc.c4b(0,0,0,153))
        display.commonUIParams(back, {ap = cc.p(0,0),po = cc.p(0,0)})
        clipper:setAnchorPoint(cc.p(0.5,0.5))
        clipper:addChild(back)

        local stencil = cc.Node:create()
        clipper:setStencil(stencil)
        clipper:setInverted(true)

        local sprite = display.newNSprite(spriteName, 0,0,{scale9 = true, capInsets = cc.rect(40,44,10,2), size = cc.size(lsize.width , lsize.height )})
        display.commonUIParams(sprite, {ap = display.LEFT_BOTTOM, po = cc.p(area.x, area.y)})
        stencil:addChild(sprite, 1)

        local sprite = display.newNSprite(spriteName, 0,0,{scale9 = true,  capInsets = cc.rect(40,44,10,2), size = cc.size(lsize.width + 6, lsize.height + 6)})
        display.commonUIParams(sprite,{ap = display.LEFT_BOTTOM, po = cc.p(area.x - 2, area.y - 2)})
        root:addChild(sprite, 3)
    end

    local fontSize = 24
    local len = string.utf8len(tostring(params.text))
    local h = 100
    if len >  0 then
        local lines = math.floor(len / 16) + 1
        local hh = lines * fontSize + (lines - 1) * 8
        if hh > 100 then h = hh end
    end
    local dialogBg = display.newImageView(_res('ui/guide/guide_bg_text'),size.width * 0.5, size.height * 0.5, {
        scale9 = true, size = cc.size(360, h + 34)
    })
    if location == 1 then
        local arrowImage = display.newImageView(_res('ui/guide/guide_ico_text'),80, 10)
        display.commonUIParams(arrowImage, {ap = display.CENTER_TOP})
        dialogBg:addChild(arrowImage,3)
        display.commonUIParams(dialogBg, {ap = display.RIGHT_TOP, po = cc.p(size.width, size.height)})
    else
        local arrowImage = display.newImageView(_res('ui/guide/guide_ico_text'),260, 10)
        display.commonUIParams(arrowImage, {ap = display.CENTER_TOP})
        arrowImage:setFlippedX(true)
        dialogBg:addChild(arrowImage,3)
        display.commonUIParams(dialogBg, {ap = display.LEFT_TOP, po = cc.p(0,size.height)})
    end
    view:addChild(dialogBg,15)

    --添加label进度的位置
    local labelparser = require("Game.labelparser")
    local parsedtable = labelparser.parse(tostring(params.text))
    -- local t = {}
    local text = ''
    for name,val in pairs(parsedtable) do
        -- if val.labelname == 'red' then
            -- table.insert(t, {text = val.content , fontSize = 24, color = RED_COLOR,descr = val.labelname})
        -- else
            -- table.insert(t, {text = val.content , fontSize = 24, color = '#5c5c5c',descr = val.labelname})
        -- end
        text = text .. tostring(val.content)
    end
    -- local descrLabel = display.newRichLabel(0, 0,{w = 27,ap = display.LEFT_TOP, c = t})
    local descrLabel = display.newLabel(0,0, {
        fontSize = 24,color = '5c5c5c', text = text,
        ap = display.LEFT_TOP, w = 340
    })
    -- display.commonUIParams(descrLabel, {po = cc.p(16,dialogBg:getContentSize().height - 14)})
    dialogBg:addChild(descrLabel,2)
    local lheight = display.getLabelContentSize(descrLabel).height
    dialogBg:setContentSize(cc.size(370, lheight + 50))
    display.commonUIParams(descrLabel, {po = cc.p(16,dialogBg:getContentSize().height - 14)})
    -- descrLabel:reloadData()

    --[[ local tipLabel = display.newLabel(0,0, { ]]
        -- fontSize = 24,color = 'ff6768', text = __('点击屏幕任意位置继续'),ttf= true, font = TTF_GAME_FONT
    -- })
    -- if location <= 6 then
        -- display.commonUIParams(tipLabel, {po = cc.p(288,35)})
    -- else
        -- display.commonUIParams(tipLabel, {po = cc.p(258,35)})
    -- end
    --[[ dialogBg:addChild(tipLabel,2) ]]

    return {
        root = root,
        view = view,
        petImage = petImage,
        descrLabel = descrLabel,
    }
end


local function CreateFingerView(params)
    -- local position = params.position
    local location = params.location
    -- local size = params.size
    local isCircle = params.isCircle
    --是否是圆形
    local view = CLayout:create(display.size)
    -- view:setBackgroundColor(cc.c4b(100,100,100,100))
    if isCircle == nil then isCircle = false end
    local clipper = cc.ClippingNode:create()
    clipper:setContentSize(display.size)
    display.commonUIParams(clipper, {ap = cc.p(0.5,0.5), po = display.center})
    view:addChild(clipper)

    local areas = checktable(params.areas)
    if table.nums(areas) > 1 then
        --多个高亮区域
        local fingerNodes = {}
        local back = cc.LayerColor:create(cc.c4b(0,0,0,100))
        display.commonUIParams(back, {ap = cc.p(0,0),po = cc.p(0,0)})
        clipper:setAnchorPoint(cc.p(0.5,0.5))
        clipper:addChild(back)

        local stencil = cc.Node:create()
        clipper:setStencil(stencil)
        clipper:setInverted(true)
        for idx,val in ipairs(areas) do
            local size = val.size
            local position = cc.p(val.x, val.y)
            local spriteName = _res('ui/guide/guide_ico_rectangle')
            if isCircle then spriteName = _res('ui/guide/guide_ico_circle') end
            local lsize = cc.size(92,92)
            if isCircle then lsize = cc.size(204,204) end
            if size and isCircle == false then
                lsize = size
            end
            -- local layout = CLayout:create(lsize)
            -- layout:setPosition(position)
            -- stencil:addChild(layout)
            --[[ local stencil = CLayout:create(cc.size(lsize.width, lsize.height)) ]]
            -- stencil:setAnchorPoint(cc.p(0.5,0.5))
            -- stencil:setPosition(position)
            -- stencil:setBackgroundColor(cc.c4b(0,0,0,255))
            -- clipper:setStencil(stencil)
            --[[ clipper:setInverted(true) ]]

            local sprite = display.newNSprite(spriteName, 0,0,{scale9 = true, capInsets = cc.rect(40,44,10,2), size = cc.size(lsize.width , lsize.height )})
            display.commonUIParams(sprite, {po = position})
            stencil:addChild(sprite, 1)
            -- local topsprite = display.newNSprite(spriteName, 0,0,{scale9 = true, capInsets = cc.rect(40,44,10,2), size = cc.size(lsize.width + WIDTH * 2, lsize.height + WIDTH *2)})
            local topsprite = display.newNSprite(spriteName, 0,0,{scale9 = true, capInsets = cc.rect(40,44,10,2), size = cc.size(lsize.width, lsize.height)})
            display.commonUIParams(topsprite, {po = position})
            view:addChild(topsprite, 1)
            table.insert(fingerNodes, sprite)
        end
        return {
            view = view,
            clipper = clipper,
            isCircle = isCircle,
            fingerNodes = fingerNodes
        }

    else
        --只有一个
        local fingerNodes = {}
        local area = areas[1]
        local size = area.size
        local position = cc.p(area.x, area.y)
        local spriteName = _res('ui/guide/guide_ico_rectangle')
        if isCircle then spriteName = _res('ui/guide/guide_ico_circle') end
        local lsize = cc.size(92,92)
        if isCircle then lsize = cc.size(204,204) end
        if size and isCircle == false then
            -- if size.width > lsize.width then
            lsize = size
            -- end
        end
        -- local sprite = display.newNSprite(spriteName, 0,0,{scale9 = true, capInsets = cc.rect(40,44,10,2), size = cc.size(lsize.width + WIDTH * 2, lsize.height + WIDTH *2)})
        local sprite = display.newImageView(spriteName, 0,0,{scale9 = true, capInsets = cc.rect(40,44,10,2), size = cc.size(lsize.width, lsize.height)})
        --sprite:setOpacity(150)
        local back = cc.LayerColor:create(cc.c4b(0,0,0,153))
        display.commonUIParams(back, {ap = cc.p(0,0),po = cc.p(0,0)})
        clipper:setAnchorPoint(cc.p(0.5,0.5))
        clipper:addChild(back)
        local stencil = CLayout:create(cc.size(lsize.width, lsize.height))
        stencil:setAnchorPoint(cc.p(0.5,0.5))
        stencil:setPosition(position)
        stencil:setBackgroundColor(cc.c4b(0,0,0,100))
        clipper:setStencil(stencil)
        clipper:setInverted(true)
        display.commonUIParams(sprite, {po = cc.p(position.x - 0.2, position.y - 0.2)})
        view:addChild(sprite, 1)


        local finger = sp.SkeletonAnimation:create('ui/guide/guide_ico_hand.json', 'ui/guide/guide_ico_hand.atlas', 1)
        finger:setAnimation(0, 'idle', true)--
        local fpos = cc.p(position.x + lsize.width * 0.4, position.y - lsize.height * 0.3)
        local tipsBg = display.newImageView(_res('ui/guide/guide_bg_text'), fpos.x, fpos.y,{scale9 = true, size = cc.size(320, 120)})
        view:addChild(tipsBg, 2)
        local labelparser = require("Game.labelparser")
        local parsedtable = labelparser.parse(tostring(params.text))
        -- local t = {}
        local text = ''
        for name,val in pairs(parsedtable) do
            -- if val.labelname == 'red' then
                -- table.insert(t, {text = val.content , fontSize = 23, color = RED_COLOR,descr = val.labelname})
            -- else
                -- table.insert(t, {text = val.content , fontSize = 23, color = '#5c5c5c',descr = val.labelname})
            -- end
            text = text .. tostring(val.content)
        end
        -- local descrLabel = display.newRichLabel(0, 0,{w = 30,ap = display.LEFT_TOP, c = t})
        -- display.commonUIParams(descrLabel, { ap = display.LEFT_TOP, po = cc.p(16,100)})
        -- tipsBg:addChild(descrLabel,2)
        -- descrLabel:reloadData()

        local descrLabel = display.newLabel(9, 100, {fontSize = 24, text= text, w = 300, color = '5c5c5c'})
        display.commonUIParams(descrLabel, { ap = display.LEFT_TOP, po = cc.p(10,100)})
        tipsBg:addChild(descrLabel)
        local lheight = display.getLabelContentSize(descrLabel).height
        if lheight < 120 then lheight = 120 end
        tipsBg:setContentSize(cc.size(320, lheight + 24))
        display.commonUIParams(descrLabel, { po = cc.p(10,lheight + 8)})
        -- finger:setScale(0.75)
        finger:setScale(0.72)
        -- finger:setRotation(30)
        if location == 1 then
            -- finger:setScaleY(-1)
            -- finger:setScaleX(-1)
            --左上
            finger:setRotation(-190)
            fpos = cc.p(position.x -lsize.width * 0.3, position.y + lsize.height * 0.3)
            display.commonUIParams(tipsBg, { po = cc.p(fpos.x - 140, fpos.y + 170)})
        elseif location == 2 then
            --右上
            finger:setRotation(-100)
            fpos = cc.p(position.x + lsize.width * 0.3, position.y + lsize.height * 0.3)
            display.commonUIParams(tipsBg, { po = cc.p(fpos.x + 140, fpos.y + 170)})
        elseif location == 3 then
            finger:setScaleX(-1)
            --下方
            fpos = cc.p(position.x - lsize.width * 0.3, position.y - lsize.height * 0.3)
            display.commonUIParams(tipsBg, { po = cc.p(fpos.x - 140, fpos.y - 180 )})
        else
            fpos = cc.p(position.x + lsize.width * 0.3, position.y - lsize.height * 0.3)
            display.commonUIParams(tipsBg, { po = cc.p(fpos.x + 140, fpos.y -180 )})
        end
        display.commonUIParams(finger, {po = fpos})

        view:addChild(finger,3)

        table.insert(fingerNodes, sprite)
        return {
            view = view,
            clipper = clipper,
            fingerNodes = {sprite},
            isCircle = isCircle,
            descrLabel = descrLabel,
        }

    end
end

function BootLoader:addLog_(logStr)
    -- 看不下去了，如果调试再打开，平时也输出好烦
    -- logInfo.add(5, tostring(logStr))
end


--[[
-- 如何使用
-- @params {
--  module --引导对应的模块名称id
--  step --对应步的id
--  path --加载的引导配表路径
--}
--]]
function BootLoader:ctor(...)
    local args = unpack({...})
    self.moduleId = args.moduleId
    self.stepId   = args.stepId
    local skipLayout = CLayout:create(display.size)
    skipLayout:setPosition(display.center)
    skipLayout:setName("SKIP_SHOW")
    skipLayout:setVisible(false)
    self:addChild(skipLayout,100)
    local touchView = CColorView:create(cc.c4b(0,0,0,150))
    touchView:setContentSize(display.size)
    touchView:setPosition(display.center)
    touchView:setTouchEnabled(true)
    skipLayout:addChild(touchView)
    local label = display.newLabel(display.cx, display.cy, fontWithColor(14, {text = __('引导出现异常，可以尝试跳过')}))
    skipLayout:addChild(label)
    -- self:setBackgroundColor(cc.c4b(255,255,255,100))
    self.m_director = args.director
    self.m_director:SetStage(self) -- 设置舞台,以便其它的添加操作
    self.isStarting = false --是否已经开始
    self.isTeach = false --是否在老师中
    self.isFinger = false --是否在按钮逻辑中
    self.isLocking = false
    self.isBlockTouch = true --屏蔽一切事件的逻辑
    self.isDisableTouch = false --是否暂时关闭事件处理
    self.isInAction = true --是否正在执行动作action的逻辑

    --测试
    -- local viewData = CreateVisitorView(1,{text = "还有个秘诀就是提升菜品的品质，品质越高的菜，售价会越高."})
    -- self:addChild(viewData.root, 100)

    --[[ self.fingerViewData = CreateFingerView({position = display.center, ]]
    -- size = cc.size(200,200),
    -- location = 4,isCircle = false})
    -- self.fingerViewData.view:setTag(12346)
    -- self:addChild(self.fingerViewData.view, 10)
    -- display.commonUIParams(self.fingerViewData.view, {po = display.center})

    -- HomeMediator#home.HomeLayer#LeftView#Button
    -- dump(self:LocateLocationsByPath('HomeMediator#BottomView#MANAGER'))
    local skipButton = display.newButton(0, 0, {n = _res('arts/stage/ui/opera_btn_skip.png') , scale9 = true })
    -- skipButton:setVisible(false)
    display.commonLabelParams(skipButton, fontWithColor(14,{fontSize = 24, text = __("跳过"), paddingW = 60  }))
    display.commonUIParams(skipButton, {ap = display.RIGHT_CENTER,po = cc.p(display.width - display.SAFE_L, display.height - 44),
    cb = function(sender)
        if self.cb then
            self.cb(3006)
        end
        self.m_director:SkipGuide()
    end})
    local  skipButtonSize  =  skipButton:getContentSize()
    local skipButtonLabel = skipButton:getLabel()
    skipButtonLabel:setAnchorPoint(display.RIGHT_CENTER)
    skipButtonLabel:setPosition(cc.p(skipButtonSize.width -10 , skipButtonSize.height /2 ))
    -- skipButton:setVisible(false)
    local iconSprite = display.newSprite(_res("arts/stage/ui/opera_ico_skip.png"))
    display.commonUIParams(iconSprite, {ap = display.RIGHT_CENTER, po = cc.p(skipButton:getContentSize().width - 10, skipButton:getContentSize().height * 0.5)})
    skipButton:addChild(iconSprite,2)
    skipLayout:addChild(skipButton, 3005,3006)
    self.fingerViewData = nil

    self.m_listener = cc.EventListenerTouchOneByOne:create()
    self.m_listener:setSwallowTouches(true)
    self.m_listener:registerScriptHandler(function(touch, event)
        if DEBUG > 0 then
            local tp = touch:getLocation()
            self:addLog_(string.fmt('---------------->>>> (x = %1; y = %2) isDisableTouch = %3, isInAction = %4, isBlockTouch = %5', checkint(tp.x), checkint(tp.y), self.isDisableTouch, self.isInAction, self.isBlockTouch))
        end
        if not self.isDisableTouch then
            if self.isInAction then
                self:addLog_('>> guide listener touch began ==>> isInAction return true')
                return true
            end
            if not self.isBlockTouch then
                local position = touch:getLocation()
                local isVisible = skipLayout:isVisible()
                local x,y = skipButton:getPosition()
                local s = skipButton:getContentSize()
                local rect = cc.rect(x - s.width * 0.5, y - s.height *0.5, s.width, s.height)
                if isVisible and cc.rectContainsPoint(rect, position) then
                    return false
                else
                    --还需要添加是否是强引导的相关判断的逻辑
                    if self.isFinger and self.isTeach == true and self.fingerViewData then
                        local isVisible = self.fingerViewData.clipper:isVisible()
                        if self.fingerViewData.fingerNodes then
                            local isTouchOk = false
                            local touchLen = table.nums(self.fingerViewData.fingerNodes)
                            local len = touchLen
                            for idx,myFingerNode in ipairs(self.fingerViewData.fingerNodes) do
                                local rect = myFingerNode:getBoundingBox()
                                if rect.width > 120 and rect.height > 120 then
                                    rect = cc.rect(rect.x + SAFE_GAP/2 , rect.y + SAFE_GAP/2, rect.width - SAFE_GAP , rect.height - SAFE_GAP)
                                end
                                if isVisible and cc.rectContainsPoint(rect,position) then
                                    len = len - 1
                                    -- isTouchOk = false
                                    -- break
                                -- else
                                    -- isTouchOk = true
                                    -- break
                                end
                            end
                            if len == touchLen then
                                self:addLog_('>> guide listener touch began ==>> len return true')
                                return true
                            else
                                self:addLog_('>> guide listener touch began ==>> len return false')
                                return false
                            end
                        else
                            if self.isTeach then
                                self:addLog_('>> guide listener touch began ==>> isTeach return true')
                                return true
                            else
                                self:addLog_('>> guide listener touch began ==>> isTeach return false')
                                return false
                            end
                        end
                    else
                        if self.isTeach then
                            self:addLog_('>> guide listener touch began ==>> isTeach2 return true')
                            return true
                        else
                            self:addLog_('>> guide listener touch began ==>> isTeach2 return false')
                            return false
                        end
                    end
                end
            else
                self:addLog_('>> guide listener touch began ==>> isBlockTouch return true')
                return true
            end
        else
            self:addLog_('>> guide listener touch began ==>> isDisableTouch return false')
            return false
        end
    end,cc.Handler.EVENT_TOUCH_BEGAN)
    self.m_listener:registerScriptHandler(function(touch, event)
        if not self.isBlockTouch then
            if self.isTeach and (not self.isFinger) and (not self.isInAction) then
                self.isInAction = true
                self:RemoveMask() --移除当前步的视图
                self:addLog_('>> guide to next -->> touch ended')
                self.m_director:MoveNext()
            end
        end
        --需要进行下一步的操作的逻辑
    end, cc.Handler.EVENT_TOUCH_ENDED)
    self:getEventDispatcher():addEventListenerWithFixedPriority(self.m_listener,-129)
    --点击处理层
    shareFacade:RegistObserver(GUIDE_STEP_EVENT_SYSTEM, mvc.Observer.new(handler(self,self.GuideActionEvent), self))

end

--[[
--是否无视所有的事件
--]]
function BootLoader:TouchDisable(isable)
    self.isDisableTouch = isable
end

--[[
--移除mask
--]]
function BootLoader:RemoveMask()
    self.isBlockTouch = true --切模块的情况下阻挡事件
    local tipNode = self:getChildByTag(12345)
    if tipNode then
        tipNode:removeFromParent()
    end
    local fingerNode = self:getChildByTag(12346)
    if fingerNode then
        fingerNode:removeFromParent()
        self.fingerViewData = nil
    end
end


function BootLoader:SkipMask()
    local tipNode = self:getChildByTag(12345)
    if tipNode then
        tipNode:removeFromParent()
    end
    local fingerNode = self:getChildByTag(12346)
    if fingerNode then
        fingerNode:removeFromParent()
        self.fingerViewData = nil
    end
    self.isBlockTouch = false--切模块的情况下阻挡事件
end

function BootLoader:StopBlockTouch()
    local tipNode = self:getChildByTag(12345)
    if tipNode then
        tipNode:removeFromParent()
    end
    local fingerNode = self:getChildByTag(12346)
    if fingerNode then
        fingerNode:removeFromParent()
        self.fingerViewData = nil
    end

    self.isBlockTouch = false
    self.isTeach = false--是在老师中
    self.isFinger = false
    self.isInAction = false
end

function BootLoader:MoveStep(stepInfo)
    self.isBlockTouch = true
    --初始化页面
    xTry(function()
        funLog(Logger.INFO, tostring(stepInfo.content))
        self:addLog_(string.fmt('id = %1, content = %2', stepInfo.id, tostring(stepInfo.content)))
        -- self.isBlockTouch = false
        local tipNode = self:getChildByTag(12345)
        if tipNode then
            tipNode:removeFromParent()
        end
        local fingerNode = self:getChildByTag(12346)
        if fingerNode then
            fingerNode:removeFromParent()
            self.fingerViewData = nil
        end
        self.isTeach = true --是在老师中
        -------------------------------------------------
        -- 老师讲解
        if checkint(stepInfo.type) == 1 then
            self.isFinger = false
            self.isInAction = true
            local pos = checkint(stepInfo.location[3])
            local arr = string.split(stepInfo.location[2],',')
            if string.len(tostring(stepInfo.delay)) <= 0 then stepInfo.delay = 0.33 end
            if tonumber(stepInfo.delay) == 0 then stepInfo.delay = 0.33 end --初始给个时间
            if stepInfo.delay and tonumber(stepInfo.delay) > 0 then
                -- self.fingerViewData.view:setVisible(false)
                -- self.fingerViewData.clipper:setVisible(false)
                if stepInfo.highlightLocation and table.nums(stepInfo.highlightLocation) > 0 then
                    self:addLog_('--------------->>> ready step')
                    scheduler.performWithDelayGlobal(function()
                        self:addLog_('--------------->>> start step')
                        local len = table.nums(stepInfo.highlightLocation)
                        local params = {}
                        for i=1,len do
                            local path = stepInfo.highlightLocation[i]
                            local positions = self:LocateLocationsByPath(path)
                            -- dump(positions)
                            if #positions > 0 then
                                -- dump(stepInfo.highlight)
                                for name,val in pairs(positions) do
                                    if stepInfo.highlight and table.nums(stepInfo.highlight) >= 2 then
                                        local offsetPos = stepInfo.highlight[1]
                                        local sizeArray = stepInfo.highlight[2]
                                        -- local deltaX = display.width / 1334
                                        -- local deltaY = display.height / 750
                                        -- local npos = cc.pAdd(val.p, cc.p(offsetPos[1] *deltaX, offsetPos[2] * deltaY))
                                        local npos = cc.pAdd(val.p, cc.p(offsetPos[1], offsetPos[2]))
                                        -- local offsetX = checkint(offsetPos[1]) / 1334 * display.width
                                        -- local offsetY = checkint(offsetPos[2]) / 750 * display.height
                                        -- local npos = cc.pAdd(val.p, cc.p(offsetX, offsetY))
                                        table.insert(params, {size = cc.size(sizeArray[1], sizeArray[2]), x = npos.x , y = npos.y })
                                    else
                                        table.insert(params, {size = val.size, x = val.p.x, y = val.p.y})
                                    end
                                end
                            else
                                funLog(Logger.INFO, '--------------->>> guide config error ----------->>>')
                                self:addLog_('--------------->>> guide config error ----------->>>')
                            end
                        end
                        local viewData = CreateVisitorView(pos,{text = tostring(stepInfo.content),params = params, x = checkint(arr[1]), y = checkint(arr[2])})
                        viewData.root:setTag(12345)
                        self:addChild(viewData.root, 10)
                        self.isInAction = false
                        self.isBlockTouch = false
                    end, checkint(stepInfo.delay))
                else
                    self:addLog_('--------------->>> move step')
                    local viewData = CreateVisitorView(pos,{text = tostring(stepInfo.content), x = checkint(arr[1]), y = checkint(arr[2])})
                    viewData.root:setTag(12345)
                    self:addChild(viewData.root, 10)
                    self.isInAction = false
                    self.isBlockTouch = false
                end
            end
        -------------------------------------------------
        -- 强制点击
        elseif checkint(stepInfo.type) == 2 then
            self.isFinger = true
            self.isInAction = true
            local location = checkint(stepInfo.location[2])
            local shapeType = checkint(stepInfo.highlightLocation[1])
            local isCircle = (shapeType == 1)
            --手指引导的相关处理的逻辑
            if string.len(tostring(stepInfo.delay)) <= 0 then stepInfo.delay = 0.33 end
            if tonumber(stepInfo.delay) == 0 then stepInfo.delay = 0.33 end --初始给个时间
            if stepInfo.delay and tonumber(stepInfo.delay) > 0 then
                -- self.fingerViewData.view:setVisible(false)
                -- self.fingerViewData.clipper:setVisible(false)
                self:addLog_('--------------->>> ready step')
                scheduler.performWithDelayGlobal(function()
                    self:addLog_('--------------->>> start step')
                    if not self.fingerViewData then
                        local len = table.nums(stepInfo.highlightLocation)
                        local llen = table.nums(stepInfo.highlight)
                        local fixP = cc.p(0,0)
                        local fixSize = nil
                        if llen > 0 then
                            local posArray = stepInfo.highlight[1]
                            local sizeArray = stepInfo.highlight[2]
                            fixP = cc.p(posArray[1], posArray[2])
                            -- local posX = checkint(posArray[1]) / 1334 * display.width
                            -- local posY = checkint(posArray[2]) / 750 * display.height
                            -- fixP = cc.p(posX, posY)
                            fixSize = cc.size(sizeArray[1], sizeArray[2])
                        end
                        local params = {}
                        for i=1,len do
                            local path = stepInfo.highlightLocation[i]
                            local positions = self:LocateLocationsByPath(path)
                            if #positions > 0 then
                                for name,val in pairs(positions) do
                                    if llen > 0 and fixSize then
                                        local npos = cc.pAdd(val.p, fixP)
                                        table.insert(params, {size = fixSize, x = npos.x ,y = npos.y})
                                    else
                                        table.insert(params, {size = val.size, x = val.p.x, y = val.p.y})
                                    end
                                end
                            else
                                funLog(Logger.INFO, '--------------->>> guide config error ----------->>>')
                                self:addLog_('--------------->>> guide config error ----------->>>')
                            end
                        end
                        if #params > 0 then
                            -- self.fingerViewData = CreateFingerView({position = cc.p(checkint(posArray[1]) * scaleX, display.height - checkint(posArray[2]) * scaleY),
                            self.fingerViewData = CreateFingerView({areas = params, location = location,isCircle = isCircle, text = tostring(stepInfo.content)})
                            self.fingerViewData.view:setTag(12346)
                            self:addChild(self.fingerViewData.view, 10)
                        end
                    end
                    self:addLog_('--------------->>> self.fingerViewData = %1', self.fingerViewData)
                    if self.fingerViewData then
                        -- if self.fingerViewData.descrLabel then
                            -- display.commonLabelParams(self.fingerViewData.descrLabel, {text = tostring(stepInfo.content)})
                        -- end

                        self.fingerViewData.clipper:setVisible(true)
                        self.fingerViewData.view:setVisible(true)
                        display.commonUIParams(self.fingerViewData.view, {po = display.center})
                        -- self.isInAction = false
                        self.isBlockTouch = false
                    else
                        self:addLog_('-------------->>>> 出现异常信息的逻辑')
                        --出现异常，直接移除当前模块的的引导步骤
                        self:StopBlockTouch()
                        self:RemoveTouchEvent()
                        self.m_director:ClearCurModuleSteps()
                        -- self.isInAction = false
                    end

                    self.isInAction = false
                end, checkint(stepInfo.delay))
            end
            -- display.commonUIParams(self.fingerViewData.view, {po = display.center})
        elseif checkint(stepInfo.type) == 3 then
            --类型为3的时候表示进程中需要发奖励才能进行下一步的逻辑
            self.isBlockTouch = true --禁用点击的逻辑
            local goods = stepInfo.goods
            if goods and table.nums(goods) > 0 then
                local stepId = checkint(stepInfo.id)
                app.httpMgr:Post('Player/guide', 'SavePlayerGuide', {module = checkint(stepInfo.guideModuleId), step = stepId, isStart = 1})
            else
                self:addLog_('>> guide to next -->> stepType 3')
                self.m_director:MoveNext(false)
            end
        end
        self:PlayAudioClip(stepInfo)
    end,__G__TRACKBACK__)
    self.isLocking = false
end
function BootLoader:PlayAudioClip(stepInfo)
    if type(stepInfo.voice) == "string"  and (string.len(stepInfo.voice) > 0 ) then
        local redTeaCardId = 200012
        local cuteName = stepInfo.voice
		if CommonUtils.PlayCardPlotSoundById then
			CommonUtils.PlayCardPlotSoundById(redTeaCardId, cuteName, 'guide')
		end

    end
end
function BootLoader:GuideActionEvent(stage, signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == GUIDE_STEP_EVENT_SYSTEM then
        if not self.isLocking then
            --做一次锁定然后向下执行
            self.isLocking = true
            self:addLog_('>> guide to next -->> event')
            self.m_director:MoveNext()
        end
    end
end

function BootLoader:Start(jumpConfId)
    if self.isStarting then return end
    self.isStarting = true --防止重复启动
    -- self.isBlockTouch = false
    self.m_director:BootStart(jumpConfId)
end


--[[
--@paths 定路的相关配置信息
--@return {} --多个坐标信息的逻辑
--]]
function BootLoader:LocateLocationsByPath(locator)
    local positions = {}
    if type(locator) == 'string' then
        if DEBUG > 0 then
            print('------------------>>>', locator)
            self:addLog_('------------------>>>' .. tostring(locator))
        end
        local root = app.uiMgr:GetCurrentScene()
        local child = root
        local node = nil
        local segments = string.split(locator,'#')
        if table.nums(segments) > 0 then
            --如果配置路径够
            for i=1, #segments do
                if DEBUG > 0 then
                    print('---------->>>',segments[i])
                    self:addLog_('---------->>>' .. tostring(segments[i]))
                end
                if string.find(segments[i], 'Mediator') then
                    local mediator = shareFacade:RetrieveMediator(segments[i])
                    if mediator then
                        child = mediator:GetViewComponent()
                    end
                elseif string.find(segments[i], 'sceneWorld') then
                    --最底层的页面
                    child = sceneWorld
                else
                    --单一节点的逻辑
                    if tolua.type(child) == 'ccw.CGridView' or
                        tolua.type(child) == 'ccw.CPageView'
                        or tolua.type(child) == 'ccw.CTableView' then
                        self:addLog_('---->>>' .. tostring(segments[i]))
                        node = child:cellAtIndex(segments[i] - 1)
                    else
                        node = child:getChildByName(segments[i])
                    end
                    if not node then
                        if child.name and child.name == 'GameScene' then
                            node = child:GetGameLayerByName(segments[i])
                            if not node then
                                node = child:GetDialogByName(segments[i])
                            end
                            child = node
                        end
                    else
                        child = node
                    end
                    if not node then
                        break
                    end
                end
            end
            if node then
                local x,y = node:getPosition()
                local pp = cc.p(x, y)
                pp = node:convertToWorldSpaceAR(cc.p(0,0))
                local anchor = node:getAnchorPoint()
                local size = node:getContentSize()
                local tx = checkint(pp.x - size.width * (anchor.x - 0.5))
                local ty = checkint(pp.y - size.height * (anchor.y - 0.5))
                if openDebugRect then
                    local view = CLayout:create(size)
                    view:setBackgroundColor(cc.c4b(255,0,0,100))
                    view:setPosition(cc.p(tx, ty))
                    if sceneWorld:getChildByName('bootLoader_test_rect') then
                        sceneWorld:removeChildByName('bootLoader_test_rect')
                    end
                    view:setName('bootLoader_test_rect')
                    sceneWorld:addChild(view, GameSceneTag.BootLoader_GameSceneTag)
                end
                table.insert(positions, {p = cc.p(tx, ty), size = size})
            end
            if DEBUG > 0 then
                dump(positions)
            end
        end
    elseif type(locator) == 'table' then
        for name,val in pairs(locator) do
            local root = app.uiMgr:GetCurrentScene()
            local child = root
            local segments = string.split(val,'#')
            if table.nums(segments) > 0 then
                for i=1, #segments do
                    funLog(Logger.INFO, '--引导查找节点------->>'.. tostring(segments[i]))
                    self:addLog_('--引导查找节点------->>'.. tostring(segments[i]))
                    if string.find(segments[i], 'Mediator') then
                        local mediator = shareFacade:RetrieveMediator(segments[i])
                        if mediator then
                            child = mediator:GetViewComponent()
                        end
                    else
                        --单一节点的逻辑
                        if tolua.type(child) == 'ccw.CGridView' or
                            tolua.type(child) == 'ccw.CPageView'
                            or tolua.type(child) == 'ccw.CTableView' then
                            node = child:cellAtIndex(segments[i] - 1)
                        else
                            node = child:getChildByName(segments[i])
                        end
                        if not node then
                            if child.name and child.name == 'GameScene' then
                                node = child:GetGameLayerByName(segments[i])
                                if not node then
                                    node = child:GetDialogByName(segments[i])
                                end
                                child = node
                            end
                        else
                            child = node
                        end
                        if not node then
                            funLog(Logger.INFO, '--引导查找节点失败了------->>'.. tostring(segments[i]))
                            self:addLog_('--引导查找节点失败了------->>'.. tostring(segments[i]))
                            break
                        end
                    end
                end
                if node then
                    local x,y = node:getPosition()
                    local pp = node:convertToWorldSpaceAR(cc.p(0,0))
                    local anchor = node:getAnchorPoint()
                    local size = node:getContentSize()
                    local tx = checkint(pp.x - size.width * (anchor.x - 0.5))
                    local ty = checkint(pp.y - size.height * (anchor.y - 0.5))
                    if openDebugRect then
                        local view = CLayout:create(size)
                        view:setBackgroundColor(cc.c4b(0,255,0,100))
                        view:setPosition(cc.p(tx, ty))
                        if sceneWorld:getChildByName('bootLoader_test_rect') then
                            sceneWorld:removeChildByName('bootLoader_test_rect')
                        end
                        view:setName('bootLoader_test_rect')
                        sceneWorld:addChild(view, GameSceneTag.BootLoader_GameSceneTag)
                    end
                    table.insert(positions, {p = cc.p(tx, ty), size = size})
                end
            end
        end
    end
    if #positions == 0 then
        --定位步骤出错了
        if self.m_director:CanSkip() then
            local touchView = self:getChildByName('SKIP_SHOW')
            if touchView then
                touchView:setVisible(true)
            end
            if device.platform == 'ios' and device.platform == 'android' then
                local uid, pid = getUserPlayerId()
                local upLocator = locator
                if type(locator) == 'table' then
                    upLocator = table.concat(locator, ';')
                end
                local crashLog = (tostring(uid) .. tostring(pid) .. "----" .. upLocator)
                buglyReportLuaException(crashLog, crashLog)
            end
        end
    end
    return positions
end

function BootLoader:ShowPlotDialog(storyId)
    local operaArgs = {id = storyId, cb = function(sender)
        --接着向下走引导
        self:addLog_('>> guide to next -->> plot end')
        self.m_director:MoveNext(false)
    end, guide = true}
    if GAME_MODULE_OPEN.NEW_PLOT then
        operaArgs.path = string.format('conf/%s/plot/story0.json', i18n.getLang())
    end
    local stage = require('Frame.Opera.OperaStage').new(operaArgs)
    stage:setPosition(cc.p(display.cx,display.cy))
    sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
    self.isBlockTouch = false
    self.isTeach = false
end

function BootLoader:RemoveTouchEvent()
    funLog(Logger.INFO, '-----------RemoveTouchEvent --------------->>')
    self:addLog_('-----------RemoveTouchEvent --------------->>')
    if self.m_listener then
        self.m_listener:setEnabled(false)
    end
    -- if self.m_listener then
        -- self:getEventDispatcher():removeEventListener(self.m_listener)
        -- self.m_listener = nil
    -- end
end

function BootLoader:RecoverTouchEvent()
    funLog(Logger.INFO, '-----------RecoverTouchEvent --------------->>')
    self:addLog_('-----------RecoverTouchEvent --------------->>')
    if self.m_listener then
        self.m_listener:setEnabled(true)
    end
    -- if self.m_listener then
    -- self:getEventDispatcher():removeEventListener(self.m_listener)
    -- self.m_listener = nil
    -- end
end
--[[
--结束剧情的相关逻辑
--]]
function BootLoader:StopGuide( )
    shareFacade:UnRegistObserver(GUIDE_STEP_EVENT_SYSTEM, self)
    if self.m_listener then
        self:getEventDispatcher():removeEventListener(self.m_listener)
        self.m_listener = nil
    end
end

function BootLoader:onCleanup( )
    --执行清理工作
    self:RemoveTouchEvent()
    self:StopGuide()
end

return BootLoader
