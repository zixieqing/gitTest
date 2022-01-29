--[[
主线地图的界面
@params table {
}
--]]
local GameScene = require( 'Frame.GameScene' )
---@class IceRoomScene :GameScene
local IceRoomScene = class('IceRoomScene', GameScene)

local shareFacade = AppFacade.GetInstance()
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")


local AnimateNode = require("Game.states.AnimateNode")

local function CreateItemView()
    local size = cc.size(64,64)
    local view = CLayout:create(size)
    local bgImage = display.newButton(0,0, {
        n = _res("ui/iceroom/refresh_main_role_mask.png")
    })
    display.commonUIParams(bgImage, {po = cc.p(size.width * 0.5, size.height * 0.5)})
    view:addChild(bgImage)
    --roleheader
    local headerNode = require("common.HeaderNode").new({id = 200013})
    display.commonUIParams(headerNode, {po = cc.p(size.width * 0.5, size.height * 0.5)})
    headerNode:setScale(0.6)
    view:addChild(headerNode,1)
    headerNode:setVisible(false)

    local checkedFlag = display.newSprite("ui/iceroom/refresh_mian_ico_correct.png") display.commonUIParams(checkedFlag, {ap = display.CENTER_BOTTOM, po = cc.p(size.width * 0.84,0)})
    view:addChild(checkedFlag,2)
    checkedFlag:setVisible(false)
    local lockSprite = display.newSprite("ui/common/common_ico_lock.png")
    display.commonUIParams(lockSprite, {po = cc.p(size.width * 0.5 ,size.height * 0.5)})
    view:addChild(lockSprite,3)
    lockSprite:setVisible(false)

    return {
        view        = view,
        bgbutton    = bgImage,
        headerNode  = headerNode,
        checkedFlag = checkedFlag,
        lockSprite  = lockSprite
    }
end

local UIORDER = 51

local directions = {cc.p(-2.0,0), cc.p(1,-1.0), cc.p(-2.0,0), cc.p(0, 2.0),
                    cc.p(1.0,2.0), cc.p(-2.0,2.0),cc.p(-2.0, 2.0), cc.p(1.0, 2.0)
                    }

-- local scheduler = require("cocos.framework.scheduler")

function IceRoomScene:ctor( ... )
	self.super.ctor(self,'views.IceRoomScene')
	self.viewData = nil
    local args = unpack({...})
    self.mediator = args.mediator
    self.isHolding = false --是否暂停世界
    self.isMoving  = false --是否正在移动的操作中
    self.isPause   = false --是否暂停世界
    self.contactBody = nil --碰撞对象body的信息
    self.roomId = checkint(args.roomId)
    self.stateId  = States.ID_RUN

    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setAnchorPoint(cc.p(0.5, 0.5))
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)

    local listener = CContactListener:new() --需要的时候删除掉
    listener:registerScriptContactHandler(function (atype, contact)
        if atype == 1 then
            if self.isHolding then --是否上更换人或者是喂食操作的时才计算碰撞
                print('begin')
                local fixtureA = contact:GetFixtureA()
                local fixtureB = contact:GetFixtureB()
                local bodyA = fixtureA:GetBody()
                local bodyB = fixtureB:GetBody()
                local nodeA = bodyA:GetUserData()
                local nodeB = bodyB:GetUserData()
                if tolua.type(nodeA) == 'ccw.CColorView' and tolua.type(nodeB) == 'ccw.CColorView' then
                    --开始进行更换角色的操作
                    -- print("a = %d, b = %d", bodyA:GetType(), bodyB:GetType())
                    if bodyA:GetType() == 0 then --如果是静态物体
                        if self.contactBody then
                            --将状态还原
                            self.contactBody:setColor(ccc3FromInt("ff8073"))
                            self.contactBody:setOpacity(0)
                        end
                        self.contactBody = nodeA
                        self.contactBody:setColor(ccc3FromInt("ff8073"))
                        self.contactBody:setOpacity(102)
                    else
                        if self.contactBody then
                            --将状态还原
                            self.contactBody:setColor(ccc3FromInt("ff8073"))
                            self.contactBody:setOpacity(0)
                        end
                        self.contactBody = nodeB
                        self.contactBody:setColor(ccc3FromInt("ff8073"))
                        self.contactBody:setOpacity(102)
                    end
                end
            end
        else
           -- print('end')
        end
    end)
    local gravity = b2Vec2(0.0, 0.0)
    local _world = b2World:new(gravity)
    -- 允许静止的物体休眠
    _world:SetAllowSleeping(true)
    -- 开启连续物理检测，使模拟更加的真实
    _world:SetContinuousPhysics(true)
    -- _world:SetContactListener(listener)
    -- Create edges around the entire screen
    -- local debugDraw = B2DebugDrawLayer:create(_world, 32)
    -- self:add(debugDraw, 9999 , 9999)
    local function CreateView()
        --[[
        -- 下面是测试物理引擎
        --]]
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        self:addChild(view)

        local tabNameLabel = display.newButton(display.SAFE_L + 120, display.size.height + 190 ,{n = _res('ui/common/common_title.png'),enable = false,ap = cc.p(0, 1.0)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('冰 场'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        self:addChild(tabNameLabel,UIORDER)

        local SliceBackground = require('common.SliceBackground')
        --添加地图层的逻辑,cc.p(684,408)
        local bgSprite = SliceBackground.new({size = cc.size(1624,1002),
            pic_path_name = "ui/iceroom/refresh_bg_1_02",
            count = 2, cols = 2,
        })
        display.commonUIParams(bgSprite,{ap = display.CENTER, po = display.center})
        view:addChild(bgSprite, 3)
        --水果墙
        local offsetY = (1002 - display.height) / 2
        local offsetX = (1334 - display.width) / 2
        local fruitImage = SliceBackground.new({size = cc.size(1624,1002),
            pic_path_name = "ui/iceroom/refresh_bg_1_01",
            count = 2, cols = 2,
        })
        display.commonUIParams(fruitImage, {ap = display.CENTER,po = cc.p(display.cx, display.height - 501 + offsetY)})
        view:addChild(fruitImage, 4)

        --构建bottom的相关UI逻辑
        local bottomSprite = display.newSprite(_res('ui/iceroom/refresh_main_bg.png'))
        display.commonUIParams(bottomSprite, {ap = display.CENTER_BOTTOM, po = cc.p(display.cx, -36)})
        self:addChild(bottomSprite, UIORDER)
        local titleLabel = display.newLabel(bottomSprite:getContentSize().width * 0.5, 140, {ttf = true, font = TTF_GAME_FONT,text = __('第一层：速冻室'), fontSize = 22, color = 'ffffff'})
        bottomSprite:addChild(titleLabel, 2)
        titleLabel:enableOutline(ccc4FromInt("815437"), 2)
        --hero button
        local heroButton = display.newButton(display.cx - 544, 90, {
            n = _res("ui/iceroom/refresh_main_ico_cards.png")
        })
        heroButton:setTag(200)
        display.commonLabelParams(heroButton, {ttf = true, font = TTF_GAME_FONT, text = __('疲劳的飨灵') ,w =250 , hAlign =display.TAC, fontSize = 24, color = 'ffffff',offset = cc.p(6,-60)})
        self:addChild(heroButton, UIORDER + 1)
        heroButton:getLabel():enableOutline(ccc4FromInt("815437"), 2)
        local IceButton = display.newButton(display.width* 0.818, 84, {
            n = _res("ui/iceroom/refresh_main_ico_charge_scene.png")
        })
        IceButton:setTag(201)
        IceButton:setVisible(false)
        display.commonLabelParams(IceButton, {ttf = true, font = TTF_GAME_FONT, text = __('切换场景'), fontSize = 22, color = 'ffffff',offset = cc.p(0,-76)})
        self:addChild(IceButton, UIORDER + 1)

        -- 冰场解锁按钮单独加入
        local unlockIcePlaceBtn = display.newButton(display.cx + 410 , 74 , {n = _res("avatar/ui/restaurant_main_anime_decorate")})
        unlockIcePlaceBtn:setTag(203)
        self:addChild(unlockIcePlaceBtn, UIORDER + 2)
        local unlockIcePlaceBtnSize = unlockIcePlaceBtn:getContentSize()
        local icePlacetitle = display.newButton(unlockIcePlaceBtnSize.width/2 , 20 , {n = _res("ui/iceroom/restaurant_main_bg_decorate") })
        unlockIcePlaceBtn:addChild(icePlacetitle)
        display.commonLabelParams(icePlacetitle ,{ttf = true, font = TTF_GAME_FONT, text = __('扩建'), fontSize = 22, color = 'ffffff'})


        -- 切换层级
        local pliesImage = display.newImageView(_res('ui/iceroom/refresh_bg_number_plies.png'))
        local pliesImageSize = pliesImage:getContentSize()
        pliesImage:setPosition(pliesImageSize.width/2 , pliesImageSize.height/2)
        local pliesLayout = display.newLayer(display.cx + 600, display.cy , {ap = display.CENTER , size = pliesImageSize})
        pliesLayout:addChild(pliesImage)
        self:addChild(pliesLayout, UIORDER + 1)


        local lastBtn = display.newButton(pliesImageSize.width/2 ,pliesImageSize.height - 40 , {n = _res('ui/common/common_btn_switch.png'),d = _res('ui/common/common_btn_switch_disabled')  })
        pliesLayout:addChild(lastBtn)
        lastBtn:setRotation(-90)
        lastBtn:setTag(204)


        local nextBtn = display.newButton(pliesImageSize.width/2 ,40 , {n =    _res('ui/common/common_btn_switch.png') , d = _res('ui/common/common_btn_switch_disabled') })
        pliesLayout:addChild(nextBtn)
        nextBtn:setRotation(90)
        nextBtn:setTag(205)

        local floorLabel = display.newLabel(pliesImageSize.width/2 , pliesImageSize.height/2 , fontWithColor(14, {text = 2 , fontSize = 40}))
        pliesLayout:addChild(floorLabel)

        local foodButton = display.newButton(display.cx + 570, 74, {
            n = _res("ui/iceroom/refresh_main_ico_eat_food.png")
        })
        foodButton:setTag(202)




        display.commonLabelParams(foodButton, {ttf = true, font = TTF_GAME_FONT, text = __('喂食'), fontSize = 22, color = 'ffffff',offset = cc.p(0,-24)})
        foodButton:getLabel():enableOutline(ccc4FromInt("815437"), 2)
        self:addChild(foodButton, UIORDER + 2)

        --冰场的8个位置点
        local roleNodes = CColorView:create(cc.c4b(0,0,0,0))
        roleNodes:setContentSize(cc.size(680,80))
        roleNodes:setTouchEnabled(true)
        roleNodes:setTag(3333)
        display.commonUIParams(roleNodes, {po = cc.p(display.width * 0.497, 44)})
        self:addChild(roleNodes, UIORDER + 1)

        local rolesItems = {}
        for i=1 , 8 do
            local x = (i -1 ) * 78 + 54
            local itemData = CreateItemView()
            display.commonUIParams(itemData.view,{po = cc.p(x + 10, 40)})
            roleNodes:addChild(itemData.view,2)
            if i > checkint(self.mediator:RetriveBedNums()) then
                itemData.lockSprite:setVisible(true)
            end
            table.insert(rolesItems, itemData)
        end

        if ChatUtils.IsModuleAvailable() then
            local chatBtn = require('common.CommonChatPanel').new({state = 3})
            display.commonUIParams(chatBtn, {po = cc.p(display.SAFE_L + 4, display.cy), ap = display.LEFT_CENTER})
            self:addChild(chatBtn)
        end

        return {
            view            = view,
            _world          = _world,
			contactListener = listener,
            tabNameLabel    = tabNameLabel,
            bottomSprite    = bottomSprite,
            heroButton      = heroButton,
            unlockIcePlaceBtn = unlockIcePlaceBtn ,
            titleLabel = titleLabel ,
            -- iceButton       = IceButton,
            foodButton      = foodButton,
            roleNodes       = roleNodes,
            rolesItems      = rolesItems,
            lastBtn = lastBtn ,
            nextBtn = nextBtn ,
            floorLabel = floorLabel ,
            mouseJoint      = nil, --拖动移动点
		}
	end

	xTry(function ( )
		self.viewData = CreateView( )
        local action = cc.EaseBounceOut:create(cc.MoveTo:create(1,cc.p(display.SAFE_L + 120, display.size.height + 2 )))
	    self.viewData.tabNameLabel:runAction( action )
        self:ContructNewPhysicWorld(_world)
        -- tick
        local function tick(dt)
            if not self.isPause then --是否暂停世界
                _world:Step(dt, 1, 1)
                --更新相关物理对象的位置
                local body = _world:GetBodyList()
                while body do
                    local preBody = body
                    body = preBody:GetNext()
                    local ptype = preBody:GetType()
                    if ptype == 2 then
                        local pos = preBody:GetLinearVelocity()
                        -- print(pos.x, pos.y)
                        --是否添加速度为0时再运动的逻辑
                        local udata = preBody:GetUserData()
                        if preBody and udata then
                            udata:setPosition(cc.p(preBody:GetPosition().x * PTM_RATIO, preBody:GetPosition().y * PTM_RATIO))
                        end
                    end
                end
            end
        end
        shareFacade:RegistObserver(SIGNALNAMES.ICEROOM_MOVE_EVENT, mvc.Observer.new(handler(self,self.MoveEeventAction), self))
        -- self.tickHandle  = scheduler.scheduleUpdateGlobal(tick)
        self:onUpdate(tick)
        self:schedule(function()
            shareFacade:DispatchSignal(COMMANDS.COMMANDS_ICEPLACE,{}, "home")
        end, 180)
        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        local listener = cc.EventListenerCustom:create('ShakeOver',function(event)
            if not self.isMoving then
                self:ApplyVelocity() --只有在没有移动的情况下抖动才能算正常的速度移动操作
            end
        end)
        eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
        cc.CSceneManager:getInstance():getRunningScene():setMultiTouchEnabled(true) --fix mulity click
	end, __G__TRACKBACK__)
end

--[[
--  更换新的contactbody
--]]
function IceRoomScene:ReplaceCard( newId )
    -- body
    -- print("=======replaceId", newId)
    --然后所有开始运动
    self:RemoveBody(self.contactBody:getTag())
    self.contactBody = nil
    if self.viewData.mouseJoint then
        self.viewData._world:DestroyJoint(self.viewData.mouseJoint)
        self.viewData.mouseJoint = nil
    end
end
--[[
-- 卸载指定的一张卡牌
--]]
function IceRoomScene:UnLoadCard(cardId)
    self:RemoveBody(cardId)
    --删除cancact body
    self.contactBody = nil --去除concact body 碰撞对象body的信息
    if self.viewData.mouseJoint then
        self.viewData._world:DestroyJoint(self.viewData.mouseJoint)
        self.viewData.mouseJoint = nil
    end
end
--[[
    移动对象的相关逻辑
--]]
function IceRoomScene:MoveEeventAction(target, signal )
    self.isMoving = true
    local body = signal.body
    if body.event == 'finish' then
        --新的逻辑，直接添加角色q版
        self.isHolding = false
        -- print("----finish---------")
        --如果在送外卖的时候是不是可以上冰场的操作
        if not gameMgr:CanSwitchCardStatus({cardId = body.id}, CARDPLACE.PLACE_ICE_ROOM) then
            --如果不能换的卡来做判断
            self:RemoveBody(checkint(body.id))
            if self.contactBody then
                --如果是替换的操作
                self.contactBody = nil
                if self.viewData.mouseJoint then
                    self.viewData._world:DestroyJoint(self.viewData.mouseJoint)
                    self.viewData.mouseJoint = nil
                end
            end
            shareFacade:GetManager("UIManager"):ShowInformationTips(__("当前飨灵正在忙碌中，不能添加到冰场~~"))
        else
            --新逻辑
            if self.contactBody then
                --如果是替换的操作
                self.contactBody = nil
                if self.viewData.mouseJoint then
                    self.viewData._world:DestroyJoint(self.viewData.mouseJoint)
                    self.viewData.mouseJoint = nil
                end
            end
            local roles = self:GetRolesCount()
            local bedsLen = self.mediator:RetriveBedNums()
            local hasOn = 0
            if table.nums(roles) < bedsLen then
                local id = checkint(body.id)
                -- self:AddOrReplaceDynamic(id, body.position )
                for k,v in pairs(roles) do
                    local card = gameMgr:GetCardDataByCardId(v:getTag())
                    if card then
                        if checkint(id) == checkint(card.cardId) then
                            hasOn = 1 --如果已经上场过
                            break
                        end
                    end
                end
                if hasOn == 1 then
                    shareFacade:GetManager("UIManager"):ShowInformationTips(__('不能上场相同的飨灵'))
                else
                    local card = gameMgr:GetCardDataByCardId(id)
                    if card then
                        self:AddOrReplaceDynamic(id, body.position )
                        shareFacade:DispatchSignal(COMMANDS.COMMANDS_ICEPLACE, {icePlaceId = self.roomId, playerCardId = card.id}, "addCard")
                    end
                end
            else
                --移除当前节点然后弹出解锁卡槽的逻辑
                -- self:RemoveBody(checkint(body.id))
                --1.tips
                if table.nums(roles) > 8 then
                    shareFacade:GetManager("UIManager"):ShowInformationTips(__("当前冰场卡槽已满，可以尝试更换哟~~"))
                else
                    --2.弹出解锁面板
                    shareFacade:GetManager("UIManager"):ShowInformationTips(__("当前卡槽不足不能添加"))
                end
            end
--[[
            if self.contactBody then
                --更换的操作
                --先发送请求，成功后再进行更换操作
                local ncard = gameMgr:GetCardDataByCardId(body.id)
                local ocard = gameMgr:GetCardDataByCardId(self.contactBody:getTag())
                if ncard and ocard then
                    shareFacade:DispatchSignal(COMMANDS.COMMANDS_ICEPLACE,{icePlaceId = self.roomId,oldPlayerCardId = ocard.id,playerCardId = ncard.id}, 'removeCard')
                end

            else
                --上场的操作,这里是一个添加操作，需要计算当前在场上的数量 如果操出数量显示一个提示的逻辑
                local roles = self:GetRolesCount()
                local bedsLen = self.mediator:RetriveBedNums()
                local hasOn = 0
                if table.nums(roles) <= bedsLen then
                    for k,v in pairs(roles) do
                        local card = gameMgr:GetCardDataByCardId(v:getTag())
                        if card then
                            if checkint(body.id) == checkint(card.id) then
                                hasOn = 1 --如果已经上场过
                                break
                            end
                        end
                    end
                    if hasOn == 1 then
                        shareFacade:GetManager("UIManager"):ShowInformationTips(__('不能上场相同的飨灵'))
                    else
                        local card = gameMgr:GetCardDataByCardId(body.id)
                        if card then
                            shareFacade:DispatchSignal(COMMANDS.COMMANDS_ICEPLACE, {icePlaceId = self.roomId, playerCardId = card.id}, "addCard")
                        end
                    end
                else
                    --移除当前节点然后弹出解锁卡槽的逻辑
                    self:RemoveBody(checkint(body.id))
                    --1.tips
                    if table.nums(roles) > 8 then
                        shareFacade:GetManager("UIManager"):ShowInformationTips(__("当前冰场卡槽已满，可以尝试更换哟~~"))
                    else
                        --2.弹出解锁面板
                        shareFacade:GetManager("UIManager"):ShowInformationTips(__("当前卡槽不足不能添加"))
                    end
                end
            end
        --]]
        end
        self.isMoving = false
    elseif body.event == 'show' then --显示物理人物
        -- print('========one time')
        local id = checkint(body.id)
        self:AddOrReplaceDynamic(id, body.position )
    elseif body.event == 'move' then -- move
        self.isHolding = true --正在长按中
        if self.viewData.mouseJoint then
            self.viewData.mouseJoint:SetTarget(b2Vec2(body.position.x/PTM_RATIO, body.position.y/PTM_RATIO))
        end
    elseif body.event == 'remove' then
        --记得清除状态
        self.isHolding = false
        self:RemoveBody(checkint(body.id))
        if self.contactBody then
            self.contactBody:setColor(ccc3FromInt("ff8073"))
            self.contactBody:setOpacity(0)
            self.contactBody = nil
        end
    end
end

function IceRoomScene:SetSwithBtnStatus(lastEnable , nextEnable)
    local lastBtn = self.viewData.lastBtn
    local nextBtn = self.viewData.nextBtn
    lastBtn:setEnabled(lastEnable)
    nextBtn:setEnabled(nextEnable)
end
function IceRoomScene:UpdateCurrentFloorLabel(roomId)
    display.commonLabelParams(self.viewData.floorLabel , {text = roomId})
    display.commonLabelParams(self.viewData.titleLabel , {text = string.fmt(__('第_num1_层：速冻室') , {_num1_ = CommonUtils.GetChineseNumber(roomId)}) })
end

function IceRoomScene:UpdateRoomId(roomId)
   self.roomId = roomId
end
--[[
-- 获取到当前场上所有的卡牌角色的id列表
-- @return {nodes,nodes}
--]]
function IceRoomScene:GetRolesCount( )
    local roles = {}
    local body = self.viewData._world:GetBodyList()
    while body do
        local preBody = body
        body = preBody:GetNext()
        local ptype = preBody:GetType()
        local udata = preBody:GetUserData()
        if udata and tolua.type(udata) == 'ccw.CColorView' then
           table.insert( roles,udata)
        end
    end
    return roles
end

function IceRoomScene:PauseWorld( isPause )
    self.isPause = isPause
end
--[[
    更新冰场界面上面的角色人物添加上去
--]]
function IceRoomScene:AddIceRoomBodes()
    --cardId是否提供了， 如果是未提供表示是全部是数据节点
    --如果提供了要改下具体的一个节点的状态
    --delete joint
    if self.viewData.mouseJoint then
        self.viewData._world:DestroyJoint(self.viewData.mouseJoint)
        self.viewData.mouseJoint = nil
    end
    --开启运动逻辑
    local index = 1
    local body = self.viewData._world:GetBodyList()
    print("AddIceRoomBodes = ")
    dump(body)
    while body do
        local preBody = body
        body = preBody:GetNext()
        local ptype = preBody:GetType()
        local udata = preBody:GetUserData()
        if udata and tolua.type(udata) == 'ccw.CColorView' then
            preBody:SetType(b2_dynamicBody)
            local p = directions[math.random(8)]
            preBody:SetLinearVelocity(b2Vec2(p.x,p.y))
            --是否添加速度为0时再运动的逻辑
            udata:HiddenUporDown()
            udata:setTouchEnabled(true)
            udata:setPosition(cc.p(preBody:GetPosition().x * PTM_RATIO, preBody:GetPosition().y * PTM_RATIO))
            --更新最下方的显示逻辑
            if index <= table.nums(self.viewData.rolesItems) then
                local cId = udata:getTag()
                local itemNode = self.viewData.rolesItems[index]
                itemNode.headerNode:setVisible(true)
                itemNode.lockSprite:setVisible(false)
                itemNode.headerNode:updateImageView(cId)
                --还要判断活力值是否已满
                local cardInfo = gameMgr:GetCardDataByCardId(cId)
                if cardInfo then
                    local maxVigour = app.restaurantMgr:getCardVigourLimit(cardInfo.id)
                    if checkint(cardInfo.vigour) >= maxVigour then
                        itemNode.checkedFlag:setVisible(true)
                    else
                        itemNode.checkedFlag:setVisible(false)
                    end
                end
            end
            index = index + 1
        end
    end
end
--[[
--更新底部条显示
--]]
function IceRoomScene:FreshBottomNodes( bedsData )
    if bedsData.icePlaceBed then
        local maxLen = checkint(bedsData.icePlaceBedNum)
        local curUpLen = table.nums(checktable(bedsData.icePlaceBed))
        for k,itemNode in pairs(self.viewData.rolesItems) do
            if k <= curUpLen then
                --已上阵的人物
                local Id = table.keys(bedsData.icePlaceBed)[k] --当前位置的数据id值
                local cardInfo = gameMgr:GetCardDataById(Id)
                if cardInfo then
                    itemNode.headerNode:setVisible(true)
                    itemNode.headerNode:updateImageView(cardInfo.cardId)
                    --还要判断活力值是否已满
                    local maxVigour = app.restaurantMgr:getCardVigourLimit(cardInfo.id)
                    if checkint(cardInfo.vigour) >= maxVigour then
                        itemNode.checkedFlag:setVisible(true)
                    else
                        itemNode.checkedFlag:setVisible(false)
                    end
                end
            else
                if k <= maxLen then
                    --解锁的状态
                    itemNode.checkedFlag:setVisible(false)
                    itemNode.headerNode:setVisible(false)
                    itemNode.lockSprite:setVisible(false)
                else
                    --是锁定的状态
                    itemNode.checkedFlag:setVisible(false)
                    itemNode.headerNode:setVisible(false)
                    itemNode.lockSprite:setVisible(true)
                end
            end
        end
    end
end

function IceRoomScene:SetIcePlaceBtnIsVisible(isVisible)
    self.viewData.unlockIcePlaceBtn:setVisible(isVisible)
end
--[[
--初始化一个节点对象为运动状态
--]]
function IceRoomScene:ApplyVelocity()
    if self.stateId == States.ID_RUN then
        self.stateId = States.ID_IDLE --回复原始状态
    else
        self.stateId = States.ID_RUN --回复原始状态
    end
    local body = self.viewData._world:GetBodyList()
    local targetBody = nil
    while body do
        local preBody = body
        body = preBody:GetNext()
        local udata = preBody:GetUserData()
        if preBody and udata and tolua.type(udata) == "ccw.CColorView" then --调整在冰场上的所有节点的移动动作逻辑
            if udata.stateMgr then --如果是一个合法的节点的逻辑
                local p = directions[math.random(8)]
                preBody:SetLinearVelocity(b2Vec2(p.x,p.y))
                if self.stateId == States.ID_IDLE then
                    udata.stateMgr:ChangeState(States.ID_RUN)
                else
                    udata.stateMgr:ChangeState(States.ID_IDLE)
                end
            end
        end
    end

end

--[[
--删除要移除的卡牌的id
--]]
function IceRoomScene:RemoveBody(cardId)
    if type(cardId) == 'string' then cardId = checkint(cardId) end
    if self.viewData.mouseJoint then
        self.viewData._world:DestroyJoint(self.viewData.mouseJoint)
        self.viewData.mouseJoint = nil
    end
    local body = self.viewData._world:GetBodyList()
    while body do
        local preBody = body
        body = preBody:GetNext()
        local udata = preBody:GetUserData()
        if udata and tolua.type(udata) == 'ccw.CColorView' then
            local id = udata:getTag()
            if id == cardId then
                self.viewData._world:DestroyBody(preBody)
                udata:removeFromParent()
            else
                --是否添加速度为0时再运动的逻辑
                udata:HiddenUporDown()
                udata:setTouchEnabled(true)
                preBody:SetType(b2_dynamicBody)
                local p = directions[math.random(8)]
                preBody:SetLinearVelocity(b2Vec2(p.x,p.y))
            end
        end
    end

end

function IceRoomScene:ContructNewPhysicWorld( _world )
    --构建物理场景初始
    -- local offsetY = (1002 - display.height) / 2
    -- local offsetX = (1334 - display.width) / 2
    local instance = GB2ShapeCache:getInstance()
    instance:addShapesWithFile("ui/iceroom/test.plist")
    --水果墙
    local topLeft = display.newSprite(_res('ui/iceroom/refresh_bg_1_03.png'))
    local cellSize = topLeft:getContentSize()
    display.commonUIParams(topLeft, {po = cc.p(display.cx, display.cy)})
    self.viewData.view:addChild(topLeft,1)
    --  --创建body与shape
    local sbodyDef = b2BodyDef:new_local()
    sbodyDef.type = b2_staticBody
    sbodyDef.position:Set(topLeft:getPositionX()/PTM_RATIO, topLeft:getPositionY()/PTM_RATIO)
    sbodyDef.userData = topLeft
    local _body3 = _world:CreateBody(sbodyDef)
    instance:addFixturesToBody(_body3,"refresh_bg_1_03")
    self.viewData.groundBody = _body3
end


--[[
--创建一个card的角色
--{position, cardId}
--]]
function IceRoomScene:AddOrReplaceDynamic(id, position)
    --列出所有动态对象静止先再显示下的状态
    local body = self.viewData._world:GetBodyList()
    while body do
        local preBody = body
        body = preBody:GetNext()
        local ptype = preBody:GetType()
        if ptype == 2 then --如果是动态对象物体，然后变成静止状态
            local pos = preBody:GetLinearVelocity()
            -- preBody:SetLinearVelocity(b2Vec2(0,0))
            preBody:SetType(b2_staticBody)
            --是否添加速度为0时再运动的逻辑
            local udata = preBody:GetUserData()
            if preBody and udata then --表示是在场上的节点
                if udata:getTag() == checkint(id) then
                    self.viewData._world:DestroyBody(preBody)
                    udata:removeFromParent()
                else
                    -- udata:UporDownFlag(false)
                    -- udata:setPosition(cc.p(preBody:GetPosition().x * PTM_RATIO, preBody:GetPosition().y * PTM_RATIO))
                end
            end
        end
    end

    if position.x < 200 then position.x = 200 end
    if position.x < 200 then position.x = 200 end
    if position.x > display.width - 200 then position.x = display.width - 200 end

    if checkint(id) > 0 then
        local nodeView = self:getChildByTag(checkint(id))
        if not nodeView then
            local actionNode = AnimateNode.new({size = cc.size(120, 150),scale = 0.38, cardId = id})
            actionNode:setAnchorPoint(cc.p(0.5, 0.3))
            actionNode:setPosition(cc.p(position.x, position.y))
            self:addChild(actionNode, 50)
            actionNode:setTag(checkint(id))
            -- actionNode:UporDownFlag()
            --创建body与shape
            local personDef = b2BodyDef:new_local()
            -- personDef.type = b2_staticBody
            personDef.type = b2_dynamicBody
            personDef.position:Set(position.x/PTM_RATIO, (position.y )/PTM_RATIO)
            personDef.userData = actionNode
            local _body = self.viewData._world:CreateBody(personDef)
            -- local polygonShape = b2PolygonShape:new_local()
            -- local boxShapeDef = b2FixtureDef:new_local()
            -- boxShapeDef.density = 1.0
            -- boxShapeDef.friction = 1.0
            -- boxShapeDef.restitution = 1.0
            -- boxShapeDef.shape = polygonShape
            -- polygonShape:SetAsBox(150 / PTM_RATIO, 75/ PTM_RATIO)
            -- _body:CreateFixture(boxShapeDef)

            local circle = b2CircleShape:new_local()
            circle.m_radius = 50 / PTM_RATIO

            local shapeDef = b2FixtureDef:new_local()
            shapeDef.shape = circle
            shapeDef.density = 1.0
            shapeDef.friction = 0.3
            shapeDef.restitution = 0.6
            _body:CreateFixture(shapeDef)
            -- _body:SetLinearVelocity(b2Vec2(1,1))
            _body:SetAngularVelocity(10)

            --创建链接点
            local md = b2MouseJointDef:new()
            md.bodyA = self.viewData.groundBody
            md.bodyB = _body
            md.target = b2Vec2(position.x  / PTM_RATIO, position.y/ PTM_RATIO)
            md.collideConnected = true
            md.maxForce = 1000.0 * _body:GetMass()
            self.viewData.mouseJoint = self.viewData._world:CreateJoint(md)
            _body:SetAwake(true)
        end
    end
end

--[[
--构建冰场的数据值
--]]
function IceRoomScene:AddCardAtLocation( cardId, position)
    local actionNode = AnimateNode.new({size = cc.size(120, 150),scale = 0.38,
     cardId = cardId, enable = true})
    actionNode:setAnchorPoint(cc.p(0.5, 0.3))
    actionNode:setPosition(cc.p(position.x, position.y))
    self:addChild(actionNode, 50)
    actionNode:setTag(checkint(cardId))
    --创建body与shape
    local personDef = b2BodyDef:new_local()
    -- personDef.type = b2_staticBody
    personDef.type = b2_dynamicBody
    personDef.angle = 0
    personDef.position:Set(position.x/PTM_RATIO, (position.y )/PTM_RATIO)
    personDef.userData = actionNode
    local _body = self.viewData._world:CreateBody(personDef)

    -- local polygonShape = b2PolygonShape:new_local()
    -- local boxShapeDef = b2FixtureDef:new_local()
    -- boxShapeDef.density = 10
    -- boxShapeDef.friction = 1.0
    -- boxShapeDef.restitution = 1.0
    -- boxShapeDef.shape = polygonShape
    -- polygonShape:SetAsBox(70 / PTM_RATIO, 70/ PTM_RATIO)
    -- _body:CreateFixture(boxShapeDef)

    local circle = b2CircleShape:new_local()
    circle.m_radius = 50 / PTM_RATIO
    local shapeDef = b2FixtureDef:new_local()
    shapeDef.shape = circle
    shapeDef.density = 1.0
    shapeDef.friction = 0.3
    shapeDef.restitution = 0.6
    _body:CreateFixture(shapeDef)
    -- local p = directions[math.random(8)]
    -- _body:SetLinearVelocity(b2Vec2(p.x,p.y))
    -- _body:SetAngularVelocity(10)
end

function IceRoomScene:SwitchIceRoom(sender)
   if sender then
        local body = self.viewData._world:GetBodyList()
        while body do
            local preBody = body
            body = preBody:GetNext()
            self.viewData._world:DestroyBody(preBody)
        end
   end
end

--[[
--添加显示更新数据vigour的信息
--@visible 是否是显示状态的逻辑
--]]
function IceRoomScene:VigourUpdate(visible)
    local body = self.viewData._world:GetBodyList()
    while body do
        local preBody = body
        body = preBody:GetNext()
        local ptype = preBody:GetType()
        if ptype == 2 then --如果是动态对象物体，然后变成静止状态
            --是否添加速度为0时再运动的逻辑
            local udata = preBody:GetUserData()
            if preBody and udata then --表示是在场上的节点
                if visible then
                    udata:UporDownFlag((not visible))
                else
                    udata:HiddenUporDown()
                end
            end
        end
    end
end


function IceRoomScene:onCleanup(  )
    -- scheduler.unscheduleGlobal(self.tickHandle)
    -- scheduler.unscheduleGlobal(self.schdulerHandle)
    cc.CSceneManager:getInstance():getRunningScene():setMultiTouchEnabled(false) --fix mulity click
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    eventDispatcher:removeCustomEventListeners('ShakeOver')
    shareFacade:UnRegistObserver(SIGNALNAMES.ICEROOM_MOVE_EVENT,self)
    if self.viewData then
        if self.viewData.mouseJoint then
            self.viewData._world:DestroyJoint(self.viewData.mouseJoint)
            self.viewData.mouseJoint = nil
        end
        if self.viewData.contactListener then
            self.viewData.contactListener:delete() --清除碰撞器
            self.viewData.groundBody = nil
            self.viewData._world:delete() -- 删除物理世界
        end
    end
    local instance = GB2ShapeCache:getInstance()
    instance:reset()
    shareFacade:UnRegsitMediator("IceRoomMediator")
end

return IceRoomScene
