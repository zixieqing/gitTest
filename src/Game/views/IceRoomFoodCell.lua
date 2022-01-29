local IceRoomFoodCell = class('IceRoomFoodCell',function ()
    local pageviewcell = CLayout:create()
    pageviewcell.name = 'views.IceRoomFoodCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local uiMgr   = shareFacade:GetManager("UIManager")
local httpManager = AppFacade.GetInstance():GetManager("HttpManager")


function IceRoomFoodCell:ctor(...)
    local args = unpack({...})
    self.id = checkint(args.id) -- goodsId
    local size = cc.size(122,136)
    self:setContentSize(size)

    self.viewData = nil
    self.isMoving = false --是否是拖动的操作功能
    self.touchImage = nil
    self.contactBodyRef = nil --碰撞到的对象

    xTry(function()
        local view = CLayout:create(size)
        view:setPosition(utils.getLocalCenter(self))
        self:addChild(view)

        local eventNode = CColorView:create(cc.c4b(10,10,100,0))
        eventNode:setContentSize(size)
        eventNode:setTouchEnabled(true)
        eventNode:setPosition(utils.getLocalCenter(self))
        self:addChild(eventNode,40)

        --goodsIcon
        local goodsIcon = display.newSprite(_res(string.format("arts/goods/goods_icon_%d.png", self.id)))
        display.commonUIParams(goodsIcon, {ap = display.CENTER, po = cc.p(size.width * 0.5, 86)})
        goodsIcon:setScale(0.9)
        view:addChild( goodsIcon, 3)

        local numberBg = display.newSprite(_res("ui/common/common_bg_number_01.png"))
        display.commonUIParams(numberBg, { po = cc.p( size.width * 0.5, 20)})
        view:addChild( numberBg, 3)
        
        local no = gameMgr:GetAmountByGoodId(self.id)
        local numberLabel = display.newLabel(numberBg:getContentSize().width * 0.5 - 10,12, fontWithColor(14,{fontSize = 20, text = tostring(no)}))
        numberBg:addChild(numberLabel, 4)

        self.viewData   = {
            view        = view,
            -- rankBg      = rankBg,
            goodsIcon   = goodsIcon,
            numberBg    = numberBg,
            numberLabel = numberLabel
        }

        local sceneRoot = uiMgr:GetCurrentScene()
        local Distance  = 100
        eventNode:setOnTouchMovedScriptHandler(function(sender, touch)
            xTry(function()
                self.isMoving = true
                local p = touch:getLocation()
                if p.y > 134 then
                    sceneRoot:PauseWorld(true)
                    if not self.touchImage then
                        self.touchImage = display.newSprite(_res(string.format("arts/goods/goods_icon_%d.png", self.id)))
                        self.touchImage:setPosition(cc.p(p.x,p.y))
                        self.touchImage:setScale(0.9)
                        sceneRoot:addChild(self.touchImage,10000)
                    end
                    self.touchImage:setPosition(p)
                    local roles = sceneRoot:GetRolesCount()
                    if roles and table.nums(roles) > 0 then
                        --计算碰撞到某一个人物对象
                        local tempNode = nil
                        local shape = (50 * 50 + 50 * 50)
                        for k,v in pairs(roles) do
                            v:setOpacity(0)
                            local x,y = v:getPosition()
                            local deltaX = math.abs( p.x - x )
                            local deltaY = math.abs( p.y - y )
                            if deltaX < Distance and deltaY < Distance then
                                local area = (deltaX * deltaX + deltaY + deltaY)
                                if shape > area then
                                    shape = area
                                    tempNode = v
                                end
                            end
                        end
                        if tempNode then
                            --存在碰撞的最小节点
                            tempNode:setColor(ccc3FromInt("ff8073"))
                            tempNode:setOpacity(102)
                            self.contactBodyRef = tempNode
                        end
                    end
                else
                    --需要移除的操作
                   if self.touchImage then
                        self.touchImage:removeFromParent()
                        self.touchImage = nil
                    end
                end
            end, __G__TRACKBACK__)
            
            return false
        end)

        local Distance = 110 + 100 --碰撞距离
        eventNode:setOnTouchEndedScriptHandler(function(sender, touch)
            xTry(function()
                local p = touch:getLocation()
                if p.y > 134 then
                    --表明是在场上的逻辑 然后进行判断
                    if self.isMoving then
                        --判断是否碰到某个角色对象
                        if self.touchImage then
                            self.touchImage:removeFromParent()
                            self.touchImage = nil
                        end
                        if self.contactBodyRef then
                            --存在碰撞到的对象
                            self.contactBodyRef:setOpacity(0)
                            local no = gameMgr:GetAmountByGoodId(checkint(self.id))
                            if no > 0 then
                                local cardId = self.contactBodyRef:getTag() -- cardId
                                local cardInfo = gameMgr:GetCardDataByCardId(cardId)
                                if cardInfo then
                                    local maxVigour = app.restaurantMgr:getCardVigourLimit(cardInfo.id)
                                    if checkint(cardInfo.vigour) < maxVigour then
                                        httpManager:Post("backpack/cardVigourMagicFoodRecover",SIGNALNAMES.Hero_AddVigour_Callback,{ playerCardId = cardInfo.id,goodsId = self.id,num = 1})
                                    else
                                        uiMgr:ShowInformationTips(__('当前的他的活力值已满'))
                                    end
                                end
                            else
                                uiMgr:AddDialog("common.GainPopup", {goodId = self.id})
                            end
                            
                            --请求 播放相关的动画 然后去掉引用
                            self.contactBodyRef = nil --去掉引用
                        end
                    end
                    sceneRoot:PauseWorld(false)
                else
                    --移除的操作
                    if self.isMoving then
                        sceneRoot:PauseWorld(false)
                    else
                        --tips的操作
                        uiMgr:ShowInformationTipsBoard({targetNode = self, iconId = self.id, type = 1})
                    end
                end
                self.isMoving = false --是否是拖动操作结束
                print('========= end=======',p.x, p.y)
            end, __G__TRACKBACK__)
            return false --继续事件处理
        end)
    end,__G__TRACKBACK__)
    
end

function IceRoomFoodCell:UpdateCount(  )
    local no = gameMgr:GetAmountByGoodId(self.id)
    self.viewData.numberLabel:setString(tostring(no))
end

return IceRoomFoodCell
