local NextDeliveryView = class('home.NextDeliveryView',function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.NextDeliveryView'
    node:enableNodeEvents()
    return node
end)
function NextDeliveryView:ctor()
    self.areaData  = CommonUtils.GetConfigAllMess('area','common')
    self:initUI()
end
local takeawayInstance = AppFacade.GetInstance():GetManager('TakeawayManager')
function NextDeliveryView:initUI()
        -- 点击关比层
    self:removeAllChildren()
    local data = takeawayInstance:GetDatas().nextPublicOrder 
    local Num = 0 
    if data then
        if  data.orderId then
            Num = 1
        end
    end
    self.privateTime = checkint(takeawayInstance:GetDatas().nextPrivateOrderRefreshTime)  
    self.privateTime  =  self.privateTime <= -1  and -1 or self.privateTime
    local closeView  = display.newLayer(display.width/2,display.height/2,{ap = cc.p(0.5, 0.5) ,color = cc.c4b(0,0,0,100) , enable = true ,  size  = cc.size(display.width ,display.height)})
    closeView:setOnClickScriptHandler( function (sender)
        sender:setTouchEnabled(false)
        self:runAction(cc.RemoveSelf:create())
    end)
    self:addChild(closeView)
    local width = 460
    local nextPublicLayoutSize  =  cc.size(width,120)  -- 下部区域
    local topSize = cc.size(width,46)   -- 顶部区域
    self.cellSize =  cc.size(width,120)  -- 中间区域
    if self.privateTime <= -1 and Num == 1 then
        nextPublicLayoutSize = cc.size(width,0) 
    end
    local bgSize = cc.size(width,self.cellSize.height*Num+ nextPublicLayoutSize.height + topSize.height)
    self.bgSize = bgSize 
    self.topSize = topSize
    --显示区域的layout
    local bgLayout = CLayout:create(bgSize)
    bgLayout:setAnchorPoint(cc.p(1,1))
    bgLayout:setPosition(cc.p(display.width - 40 ,display.height -160))
    self:addChild(bgLayout)
    local hornImage =  display.newImageView(_res('ui/common/common_bg_tips_horn.png'), bgSize.width -40 , bgSize.height -2)
    bgLayout:addChild(hornImage,3)
    
    local sallowView  = display.newLayer(bgSize.width/2,bgSize.height/2,{ap = cc.p(0.5, 0.5) ,color = cc.c4b(0,0,0,0),cc.size(bgSize.width ,bgSize.height) ,enable = true}) 
    bgLayout:addChild(sallowView)
    local bgImage = display.newImageView(_res('ui/common/common_bg_tips.png') , bgSize.width /2 , bgSize.height/2 ,{ scale9 = true , size  = cc.size(bgSize.width ,bgSize.height)})
    bgLayout:addChild(bgImage)
    -- 顶部的Layout 
    local topLayout = CLayout:create(topSize)
    topLayout:setPosition(cc.p( bgSize.width/2, bgSize.height - topSize.height/2))
    bgLayout:addChild(topLayout)

    local titleBgImage  = display.newImageView(_res('ui/common/common_title_2.png'),topSize.width/2, topSize.height /2)
    topLayout:addChild(titleBgImage)

    local tipsImage =   display.newImageView(_res('ui/common/common_btn_tips.png'),topSize.width - 30, topSize.height /2)
    topLayout:addChild(tipsImage)
    local  titleText = display.newLabel(topSize.width /2 , topSize.height /2 , fontWithColor(4,{text = __('外卖倒计时')}))
    topLayout:addChild(titleText)
    if Num == 0 then
        local middleLayout = self:updateCell(data)
        bgLayout:addChild(middleLayout)
    end
    if self.privateTime <=  -1  and Num == 1  then
        return
    end
    local bottomLayout =  CLayout:create(nextPublicLayoutSize)
    bottomLayout:setPosition(cc.p(nextPublicLayoutSize.width/2,nextPublicLayoutSize.height/2))
    bgLayout:addChild(bottomLayout)

    local countDownText = display.newLabel(nextPublicLayoutSize.width/2 ,nextPublicLayoutSize.height/2 + 30, fontWithColor(14,{text  = __('下一笔外卖订单倒计时')}))
    bgLayout:addChild(countDownText,3)
    countDownText:setVisible(false)
    local coutDownImage = display.newImageView(_res('ui/home/nmain/main_sandglas_bg_time.png'), nextPublicLayoutSize.width/2 , nextPublicLayoutSize.height/2 -5)

    bgLayout:addChild(coutDownImage)
    local coutDownImageSize = coutDownImage:getContentSize()
    local coutDownLable = display.newLabel(coutDownImageSize.width/2, coutDownImageSize.height/2, fontWithColor(10,{ text = '00:00:00'}))
    coutDownImage:addChild(coutDownLable)
    coutDownLable:setVisible(false)
    coutDownImage:setVisible(false)

    if self.privateTime <= 0   then
        countDownText:setString(__('暂无订单信息'))
        countDownText:setVisible(true)
        coutDownImage:setVisible(false)
        return
    end 
    
    

    local callback_two  = function()
        local callback = function ()
            self.privateTime = self.privateTime - 1
            if self.privateTime <= 0  then
                self.privateTime = 0 
                
                coutDownLable:setString('00:00:00')
                coutDownImage:setVisible(false)
                return
            end
            
            local str =  self:ChangeTimeFormat(self.privateTime)
            coutDownLable:setString(str)

        end
        local seqTable  ={}
        seqTable[#seqTable+1] = cc.DelayTime:create(1)
        seqTable[#seqTable+1] = cc.CallFunc:create(callback)
        local seqAction = cc.Sequence:create(seqTable)
        countDownText:setVisible(true)
        coutDownImage:setVisible(true)
        coutDownLable:setVisible(true)
        local str =  self:ChangeTimeFormat(self.privateTime)
        coutDownLable:setString(str)
        coutDownLable:stopAllActions()
        coutDownLable:runAction(cc.RepeatForever:create(seqAction))
    end
    coutDownLable:stopAllActions()
    coutDownLable:runAction( cc.Sequence:create(cc.CallFunc:create(callback_two)  ) )

end

function NextDeliveryView:ProcessSignal(nextPublicLayoutSize)
    self:initUI()
end
function NextDeliveryView:ChangeTimeFormat( remainSeconds )
    local hour   = math.floor(remainSeconds / 3600)
    local minute = math.floor((remainSeconds - hour*3600) / 60)
    local sec    = (remainSeconds - hour*3600 - minute*60)
    return string.format("%.2d:%.2d:%.2d", hour, minute, sec)
end
function NextDeliveryView:updateCell (datas)
    datas = datas or {}
    local listLayout  = CLayout:create(cc.size(self.cellSize.width , self.cellSize.height*1))
    if not datas.roleId then
        return listLayout  
    end 
   
    listLayout:setPosition(cc.p(self.bgSize.width/2, self.bgSize.height - self.topSize.height - self.cellSize.height/2))
    listLayout:setAnchorPoint(cc.p(0.5,0.5))
    local bgCell = display.newImageView(_res('ui/home/nmain/main_bg_sandglas_order.png'), self.cellSize.width /2 , self.cellSize.height/2)
    -- local iconPath =  {_res('ui/home/nmain/main_sandglas_bg_global.png') ,_res('ui/home/nmain/main_sandglas_bg_reguler.png')}
    listLayout:addChild(bgCell)
    if datas.roleId then
        local iconImage  = display.newImageView(_res('ui/home/nmain/main_sandglas_bg_global.png'),70, bgCell:getContentSize().height * 0.5 )
        bgCell:addChild(iconImage)
        local roleId = CommonUtils.GetConfigAllMess('role','takeaway')[tostring(datas.roleId)].realRoleId
        local roleImageNode = display.newImageView(_res(string.format('arts/roles/head/%s_head_1',roleId)),iconImage:getContentSize().width * 0.5, iconImage:getContentSize().height * 0.5 -10)
        roleImageNode:setScale(0.45)
        local publicStr =  display.newLabel( iconImage:getContentSize().width * 0.5 , 0, fontWithColor(14,{text  = __('超级订单')}))
        iconImage:addChild(roleImageNode,4)
        iconImage:addChild(publicStr)
    end 
    local countDownText = display.newLabel(self.cellSize.width - 70 ,self.cellSize.height/2 + 20, fontWithColor(11,{text  = __('开始倒计时')}))
    listLayout:addChild(countDownText,3)

    local coutDownImage = display.newImageView(_res('ui/home/nmain/main_sandglas_bg_time.png'), self.cellSize.width -70 , self.cellSize.height/2 -5)

    listLayout:addChild(coutDownImage)
    local coutDownImageSize = coutDownImage:getContentSize()
    local coutDownLable = display.newLabel(coutDownImageSize.width/2, coutDownImageSize.height/2,fontWithColor(10,{ text = '00:00:00'}))
    coutDownImage:addChild(coutDownLable)
    self.publicTime = checkint(takeawayInstance:GetDatas().nextPublicOrderRefreshTime)  

    local callback = function ()
        self.publicTime = self.publicTime - 1
        if self.publicTime <= 0  then
            self.publicTime = 0 
            coutDownLable:setString('00:00:00')
            return
        end
        local str =  self:ChangeTimeFormat(self.publicTime)
        coutDownLable:setString(str)
    end
    local seqTable  ={}
    seqTable[#seqTable+1] = cc.DelayTime:create(1)
    seqTable[#seqTable+1] = cc.CallFunc:create( callback)
    local seqAction = cc.Sequence:create(seqTable)
    coutDownLable:runAction(cc.RepeatForever:create(seqAction))
    local str = self.areaData[tostring(datas.areaId)].name

    local areaLabel  = display.newLabel(self.cellSize.width /2 , self.cellSize.height /2 ,fontWithColor(11,{ ap = cc.p(0.5,0.5) ,text  = str}))
    listLayout:addChild(areaLabel , 2)
   return listLayout
end
function NextDeliveryView:onEnter()
    AppFacade.GetInstance():RegistObserver(FRESH_TAKEAWAY_POINTS, mvc.Observer.new(self.ProcessSignal, self))
end
function NextDeliveryView:onCleanup()
    AppFacade.GetInstance():UnRegistObserver(FRESH_TAKEAWAY_POINTS, self)
end


return NextDeliveryView
