
--[[
限时超得活动view
--]]
---@class LimitChestGiftView1
local LimitChestGiftView1 = class('LimitChestGiftView1', function ()
    local node = CLayout:create(display.size)
    node:setAnchorPoint(cc.p(0, 0))
    node.name = 'home.LimitChestGiftView1'
    node:enableNodeEvents()
    return node
end)
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager

--local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
function LimitChestGiftView1:CreateView()

    local closeLayer = display.newLayer(display.cx, display.cy , {ap = display.CENTER , size = display.size, enable = true , color = cc.c4b(0,0,0, 100) })
    self:addChild(closeLayer)
    -- 背景的光圈
    local bgImage = display.newImageView(_res('ui/home/activity/activity_xiashitehi_light.png'), display.width/2, display.height/2)
    local bgSize = bgImage:getContentSize()
    bgImage:setPosition(cc.p(bgSize.width/2 , bgSize.height/2))
    local bgLayout = display.newLayer(bgSize.width/2 , bgSize.height/2, { size = bgSize , ap = display.CENTER } )
    bgLayout:addChild(bgImage)
    local bgParentLayout = display.newLayer(display.cx , display.cy , { size = bgSize , ap = display.CENTER})
    bgParentLayout:addChild(bgLayout)

    self:addChild(bgParentLayout)
    -- 吞噬层
    local swallowLayer = display.newLayer(bgSize.width/2 , bgSize.height/2 , {ap = display.CENTER , size = bgSize, enable = true , color = cc.c4b(0,0,0, 0) })
    bgLayout:addChild(swallowLayer)


    -- 盘子
    local dishImage  = display.newImageView(_res('ui/home/activity/activity_xiashitehi_bg.png'), bgSize.width/2, bgSize.height/2)
    bgLayout:addChild(dishImage)
    local qAvatar = sp.SkeletonAnimation:create(_res('effects/xsth_effect.json'), 'effects/xsth_effect.atlas', 1.0)
    qAvatar:setPosition(utils.getLocalCenter(dishImage))
    qAvatar:setToSetupPose()
    qAvatar:setAnimation(0, 'idle', true)
    dishImage:addChild(qAvatar)
    -- 第一个小人
    local onePeople = display.newImageView(_res('ui/home/activity/activity_xiashitehi_ico_1.png'), bgSize.width/2, bgSize.height/2 , { ap = display.CENTER})
    bgParentLayout:addChild(onePeople, 5)
    -- 第二个小人
    local twoPeople = display.newImageView(_res('ui/home/activity/activity_xiashitehi_ico_2.png'), bgSize.width/2, bgSize.height/2   , { ap = display.CENTER})
    bgParentLayout:addChild(twoPeople ,4)
    -- 限时的图片
    local limitImage =  display.newImageView(_res('ui/home/activity/activity_xiashitehi_title.png'))
    local limitImageSize = limitImage:getContentSize()
    -- 倒计时
    local timeButton = display.newButton(0,0,{n = _res('ui/home/activity/activity_xiashitehi_bg_time.png')})
    local timeButtonSize = timeButton:getContentSize()
    local limitLayoutSize = cc.size(math.max(limitImageSize.width ,  timeButtonSize.width ) ,limitImageSize.height +   timeButtonSize.height -10  )
    limitImage:setAnchorPoint(display.CENTER_TOP)
    timeButton:setAnchorPoint(display.CENTER_BOTTOM)
    timeButton:setPosition(cc.p(limitLayoutSize.width/2 , 0 ))
    limitImage:setPosition(cc.p(limitLayoutSize.width/2 , limitLayoutSize.height ))
    -- 限制的
    local limitLayout = display.newLayer(bgSize.width/4 + 90 , bgSize.height - 30 ,  { size = limitLayoutSize ,ap = display.CENTER_TOP })
    limitLayout:addChild(limitImage)
    limitLayout:addChild(timeButton)
    bgParentLayout:addChild(limitLayout,10)
    local buyButton = display.newButton(bgSize.width/2 , 75,{n = _res("ui/common/common_btn_orange.png")  ,  s =  _res("ui/common/common_btn_orange.png") , d =  _res("ui/common/common_btn_orange.png") })
    bgLayout:addChild(buyButton)
    -- 打折的Image
    local discountImage =  display.newImageView(_res('ui/home/activity/activity_xiashitehi_bg_sale.png'),435,123 , {})
    --bgLayout:addChild(discountImage)
    local discountSize = discountImage:getContentSize()
    discountImage:setPosition(discountSize.width/2 , discountSize.height/2)
    local discountLayout = display.newLayer(500,123 ,{ap = display.CENTER , size =discountSize })
    bgLayout:addChild(discountLayout)
    discountLayout:addChild(discountImage)
    discountImage:setScale(1.5)
    -- 折扣的labl

    local discountNumLabel = display.newRichLabel(discountSize.width/2 , discountSize.height/2 +30 , {  c = {
        fontWithColor('14', { fontSize = 60 , color = '#ffe156' ,text = 2 } )

    } ,r = true })
    local discountLabel = display.newLabel(discountSize.width/2 , 40 ,  fontWithColor('14', { fontSize = 30  , text = "off" } ))
    -- listView 拖动
    local  listSize =  cc.size(300, 190)
    local listView = CListView:create(listSize)
    listView:setDirection(eScrollViewDirectionVertical)
    listView:setAnchorPoint(display.CENTER)
    listView:setPosition(cc.p(bgSize.width/2 , bgSize.height /2 ))
    bgLayout:addChild(listView)

    discountLayout:addChild(discountLabel)
    discountLayout:addChild(discountNumLabel)
    -- 价格label
    local priceLbale = display.newLabel(bgSize.width /2 , 150 , {text =string.format( __('原价￥%s') , "648"  )  , fontSize = 28 , color = "#5b3c25" } )
    bgLayout:addChild(priceLbale,2)
    local lineImage = display.newImageView(_res('ui/home/commonShop/shop_sale_line.png'),bgSize.width /2 , 150 , { scale = 1.7} )
    bgLayout:addChild(lineImage ,2)
    priceLbale:setVisible(false)
    lineImage:setVisible(false)
    --bgParentLayout:setVisible(false)
    onePeople:setScale(0.1)
    twoPeople:setScale(0.1)
    bgLayout:setScale(0.1)
    self.viewData_ =  {
        bgParentLayout = bgParentLayout  ,
        priceLbale = priceLbale ,
        bgLayout = bgLayout,
        listView = listView ,
        discountLabel = discountLabel ,
        buyButton = buyButton ,
        onePeople = onePeople ,
        twoPeople = twoPeople ,
        closeLayer = closeLayer ,
        timeButton = timeButton,
        discountNumLabel = discountNumLabel ,
        bgSize = bgSize
    }

end
-- 展开的动画播放
function LimitChestGiftView1:ExpandAction()
    local viewData_ = self.viewData_
    local onePeople = viewData_.onePeople
    local twoPeople = viewData_.twoPeople
    local bgLayout = viewData_.bgLayout
    local bgParentLayout = viewData_.bgParentLayout
    local mode = 30
    bgParentLayout:runAction(
        cc.Sequence:create(
            cc.CallFunc:create(function ()
                self.isAction = true
            end),
            cc.Spawn:create(
                cc.TargetedAction:create(onePeople ,
                    cc.Spawn:create(
                        cc.Sequence:create(
                            cc.ScaleTo:create(8/mode ,  1.1) ,
                            cc.ScaleTo:create(2/mode , 0.9 ) ,
                            cc.ScaleTo:create(2/mode , 1.05) ,
                            cc.ScaleTo:create(3/mode , 0.95) ,
                            cc.ScaleTo:create(2/mode , 1.0) ,
                            cc.ScaleTo:create(5/mode , 1.0) ,
                            cc.ScaleTo:create(2/mode , 1.0)
                        ) ,
                        cc.Sequence:create(
                            cc.DelayTime:create(5/mode) ,
                            cc.MoveBy:create(5/mode , cc.p(-111.2, -61.91)) ,
                            cc.MoveBy:create(5/mode , cc.p(37.83, 24.61)) ,
                            cc.MoveBy:create(5/mode , cc.p(-199.93, -108.45)) ,
                            cc.MoveBy:create(2/mode , cc.p(67.5, 49.39)) ,
                            cc.MoveBy:create(2/mode , cc.p(-30, 0))
                        )
                    )
                ) ,
                cc.TargetedAction:create(twoPeople ,
                    cc.Spawn:create(
                        cc.Sequence:create(
                            cc.DelayTime:create(5/mode) ,
                            cc.ScaleTo:create(5/mode ,  1.1) ,
                            cc.ScaleTo:create(2/mode ,  0.9) ,
                            cc.ScaleTo:create(3/mode ,  1.05) ,
                            cc.ScaleTo:create(2/mode ,  0.95) ,
                            cc.ScaleTo:create(2/mode ,  1) ,
                            cc.ScaleTo:create(3/mode ,  1.1) ,
                            cc.ScaleTo:create(2/mode ,  1.0)
                        ) ,
                        cc.Sequence:create(
                            cc.DelayTime:create(5/mode) ,
                            cc.MoveBy:create(5/mode , cc.p(44.71, 29.81)) ,
                            cc.MoveBy:create(5/mode , cc.p(35.54, 20.64)) ,
                            cc.MoveBy:create(5/mode , cc.p(187.95, 132.75)) ,
                            cc.MoveBy:create(2/mode , cc.p(-47.1, -30.2)) ,
                            cc.MoveBy:create(2/mode , cc.p(20, 15))
                        )
                    )
                ) ,
                cc.TargetedAction:create(bgLayout ,
                    cc.Sequence:create(
                        cc.DelayTime:create(15/mode) ,
                        cc.ScaleTo:create(5/mode ,1.1 ) ,
                        cc.ScaleTo:create(2/mode ,0.9 ) ,
                        cc.ScaleTo:create(2/mode ,1.0 )
                    )
                )
            ) ,
            cc.CallFunc:create(function ()
                self.isAction = false
            end)
        )
    )



end
function LimitChestGiftView1:CloseAction()
    local viewData_ = self.viewData_
    local onePeople = viewData_.onePeople
    local twoPeople = viewData_.twoPeople
    local bgLayout = viewData_.bgLayout
    local bgParentLayout = viewData_.bgParentLayout
    local bgSize = self.viewData_.bgSize
    local mode = 80
    bgParentLayout:runAction(
        cc.Sequence:create(
            cc.Spawn:create(
                cc.TargetedAction:create(onePeople ,
                    cc.EaseSineOut:create(
                        cc.Spawn:create(
                            cc.ScaleTo:create(10/mode , 0.1 ),
                            cc.MoveTo:create(10/mode , cc.p(bgSize.width/2 , bgSize.height /2))

                        )
                    )
                )
                ,
                cc.TargetedAction:create(twoPeople ,
                    cc.Spawn:create(
                        cc.ScaleTo:create(10/mode , 0.1 ),
                        cc.MoveTo:create(10/mode , cc.p(bgSize.width/2 , bgSize.height /2))

                    )
                ) ,
                cc.TargetedAction:create(bgLayout ,
                    cc.Sequence:create(
                        cc.DelayTime:create(5/mode) ,
                        cc.ScaleTo:create(5/mode ,0.1 )
                    )

                )
            ) ,
            cc.CallFunc:create(
                function ()
                    AppFacade.GetInstance():UnRegsitMediator("LimitGiftMediator")
                end
            )

        )

    )

end
-- 创建礼包获取的内容
function LimitChestGiftView1:needGoods(data)
    data = data or {}
    -- 删除所有的节点
    self.viewData_.listView:removeAllNodes()
    local countNum = table.nums(data)
    if countNum <  6 then
        self.viewData_.listView:setDragable(false)
    end
    if countNum > 0  then

        local bgSize = nil

        if countNum >  3  then
            bgSize =  cc.size(300, 95 )
        else
            bgSize = cc.size(300, 190 )
        end
        local count = 0
        local cell = nil
        local divisor = countNum >  3  and  3  or   countNum
        local width = bgSize.width/divisor
        local height = bgSize.height
        for k ,v  in  pairs(data)  do
            if count == 0  then
                -- cell 的修改
                cell = display.newLayer(0,0 ,{ size = bgSize})
                self.viewData_.listView:insertNodeAtLast(cell)
            end
            count = count + 1

            local  nums = count - divisor

            if nums  == 0 then
                count = 0
            end
            local goodNode = require('common.GoodNode').new({id = v.goodsId,num = v.num, showAmount = true})
            goodNode:setAnchorPoint(cc.p(0.5,0.5))
            cell:addChild(goodNode)
            goodNode:setPosition(cc.p(width * ((count - 0.5)  % divisor) , height /2)  )
            goodNode:setScale(0.8)
            display.commonUIParams(goodNode, {animate = false, cb = function (sender)
                uiMgr:AddDialog("common.GainPopup", {goodId = v.goodsId})
            end})
        end
        self.viewData_.listView:reloadData()

    end
end

function LimitChestGiftView1:ctor( ... )
    self.isAction = true
    self:CreateView()
end


return LimitChestGiftView1