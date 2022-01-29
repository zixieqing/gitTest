---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2018/1/30 上午11:25
---
--[[
通用奖励界面
@params {
    addBackpack = true -是否添加到背包，初始为true
	rewards table 道具列表
    mainExp int 主角经验数值
	closeCallback function 动画结束回调
}22222
--]]
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local gameMgr = AppFacade.GetInstance():GetManager('GameManager')

local RollPopUpReward = class('RollPopUpReward', function ()
    local clb = CLayout:create(cc.size(display.width, display.height))
    clb.name = 'common.RollPopUpReward'
    clb:enableNodeEvents()
    return clb
end)
--[[传入参数格式  {rewardData = {
    {
        rank = 1 ,
        goodsId = DIAMOND_ID,
        playerName = "好好歇息",
        num = 10
    } ,
    {
        rank = 2,
        goodsId = DIAMOND_ID,
        playerName = "好好歇息",
        num = 10
    }
}}--]]
function RollPopUpReward:ctor(...)
    self.args = unpack({...})
    self.rewardData  = self.args.rewardData -- 获得的奖励
    self.closefunction  = nil
    self.isClose = false
    local rewards = self.rewardData
    local createGoods  = function (data,delayTime)

        local rank = checkint(data.rank) > 0  and checkint(data.rank)  or 1
        local name = data.playerName or ""
        local rankColorTable = {
                "#ff591f" ,
                "#ff8e1f" ,
                "#ffc350" ,
                "#e9ff90"
        }
        local goodLayoutSize =  cc.size(130,210)
        local goodLayout  = display.newLayer(0,0,{ap = display.CENTER_TOP , size = goodLayoutSize})
        local goodNode = require('common.GoodNode').new({id = data.goodsId, amount = data.num, showAmount = true })
        display.commonUIParams(goodNode, {animate = false, cb = function (sender)
            uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
        end})
        goodNode:setScale(0.9)
        goodLayout:add(goodNode)
        goodNode:setPosition(goodLayoutSize.width/2 , goodLayoutSize.height -40)
        goodNode:setAnchorPoint(display.CENTER_TOP)
        -- 排行显示的roll点
        local rankLabel = display.newLabel(goodLayoutSize.width/2 , goodLayoutSize.height - 20 ,
            fontWithColor('14',{text = "NO." .. rank  ,color =  rankColorTable[rank] ,outline = "#5b3c25" } ))
        goodLayout:add(rankLabel)

        -- 排行显示的roll点
        local obtainLabel = display.newLabel(goodLayoutSize.width/2 , 47 ,
                                           fontWithColor('14',{text = __('获奖者')  ,fontSize = 22 ,color =  "#ffffff" ,outline = "#5b3c25" } ))
        goodLayout:add(obtainLabel)


        local playerLabel = display.newLabel(goodLayoutSize.width/2 , 15 , { fontSize = 22 , color = "#ffbf37" , text = name})
        goodLayout:add(playerLabel)

        goodLayout:setOpacity(0)


        local seqTable = {}
        local fadeIn = cc.FadeIn:create(0.25)
        local jumpBy = cc.JumpBy:create(0.25,cc.p(0,110),60,1)
        local spawn = cc.Spawn:create(jumpBy,fadeIn)
        seqTable[#seqTable+1] = cc.DelayTime:create(delayTime)
        seqTable[#seqTable+1] = spawn
        local seqAction = cc.Sequence:create(seqTable)
        goodLayout:runAction(seqAction)

        return goodLayout
    end
    local  function createSpineView (rewardsTable)
        -- body
        local size = cc.size(900, 652)
        local ico_dish = CommonUtils.GetRrawRewardsSpineAnimation()
        -- view
        local  spinecallBack = function (event)
            if event.animation ==  'play' then
                ico_dish:setToSetupPose()
            end
        end

        local view = display.newLayer(0, 0, {size = size ,ap = display.CENTER})
        local swallView = display.newLayer(size.width/2,size.height/2,{ ap = display.CENTER , size = cc.size(900 ,300),  color = cc.c4b(0,0,0,0) ,enable = true})
        view:addChild(swallView)
        local  bgLayer = display.newLayer(0, 0, {size = cc.size(display.width,display.height), ap = cc.p(0.5, 0.5), color = cc.c4b(0,0,0,100), enable = true})
        bgLayer:setPosition(utils.getLocalCenter(self))
        self.isTouble  = false
        self:setVisible(true)
        bgLayer:setOnClickScriptHandler(function(sender)
            if self.isTouble then
                self.isTouble = false

            end
        end)
        local setBgLayerClick = function ()
            self.isTouble = true
        end
        local rewardImage = display.newImageView(_res('ui/union/roll/party_roll_reward_words.png'),display.cx, display.height+60)
        self:addChild(rewardImage,2)
        local rewardPoint_Srtart =  cc.p(display.cx ,  display.height+94.6-110)
        local rewardPoint_one = cc.p(display.cx ,  display.cy+300-35.5-110)
        local rewardPoint_Two = cc.p(display.cx ,  display.cy+300+24-110)
        local rewardPoint_Three = cc.p(display.cx ,  display.cy+300-15-110)
        local rewardPoint_Four = cc.p(display.cx ,  display.cy+300-15-110)
        local rewardSequnece = cc.Sequence:create(    -- 获取队列的动画展示
                cc.DelayTime:create(1) ,cc.CallFunc:create(function ( )
                    rewardImage:setVisible(true)
                    rewardImage:setOpacity(0)
                    rewardImage:setPosition(rewardPoint_Srtart)
                end),
                cc.Spawn:create(cc.FadeIn:create(0.2),cc.MoveTo:create(0.2,rewardPoint_one)),
                cc.JumpTo:create(0.1,rewardPoint_Two,10,1) ,
                cc.MoveTo:create(0.1,rewardPoint_Three) ,
                cc.MoveTo:create(0.1,rewardPoint_Four)
        )
        rewardImage:runAction(rewardSequnece)
        local descrScrollView = cc.ScrollView:create()
        descrScrollView:setDirection(eScrollViewDirectionVertical)
        descrScrollView:setViewSize(cc.size(display.width/2, 400))
        descrScrollView:setPosition(cc.p(120,size.height*3/4-25))
        descrScrollView:setAnchorPoint(display.CENTER)
        view:addChild(descrScrollView,0)
        local lightCircle1 = display.newImageView(_res('ui/common/common_reward_light.png'),{ap = display.CENTER})
        lightCircleSize1 = lightCircle1:getContentSize()
        lightCircle1:setPosition(cc.p(display.width/2/2,0))
        descrScrollView:addChild(lightCircle1)
        local delayAction = cc.DelayTime:create(1)
        lightCircle1:setOpacity(0)
        local callfun2 = function ()
            lightCircle1:stopAllActions()
            lightCircle1:runAction(cc.RepeatForever:create(cc.Spawn:create(cc.Sequence:create(cc.FadeTo:create(2.25,100),cc.FadeTo:create(2.25,255)), cc.RotateBy:create(4.5,180))))
        end
        local seqAction1 = cc.Sequence:create(delayAction ,cc.FadeIn:create(0.25),cc.CallFunc:create(callfun2))
        lightCircle1:runAction(seqAction1)
        bgLayer:runAction(cc.Sequence:create(cc.DelayTime:create(1+0.6),cc.CallFunc:create(setBgLayerClick)))
        self:addChild(bgLayer)
        display.commonUIParams(ico_dish, {po = cc.p(size.width/2,size.height/2)})
        view:addChild(ico_dish,1)
        ico_dish:setAnimation(0, 'play', false)
        ico_dish:registerSpineEventHandler(spinecallBack, sp.EventType.ANIMATION_COMPLETE)
        local  count = #rewardsTable
        local width = 130

        local goodsLayoutSize = cc.size(width* count,210)
        local goodLayout =  CLayout:create(goodsLayoutSize)
        goodLayout:setAnchorPoint(display.CENTER)
        goodLayout:setPosition(cc.p(size.width/2,size.height/2))
        for i = 1, count do
            local itemNode = createGoods(rewardsTable[i],0.05*i+1)
            itemNode:setPosition(cc.p(width*(i - 0.5),goodsLayoutSize.height/2))
            goodLayout:addChild(itemNode)
        end
        view:addChild(goodLayout,2)
        self.closefunction = function ()
            ico_dish:setToSetupPose()
            if not self.isClose then  -- 防止多次点击造成的多次删除
                self.isClose = true
                self:runAction( cc.Sequence:create( cc.Hide:create(), cc.DelayTime:create(0.1),cc.Hide:create() ,cc.RemoveSelf:create()) )
            end
        end

        return {
            view = view,
            ico_dish = ico_dish
        }
    end
    local bgSize = cc.size(900, 652)
    local bg = CLayout:create(bgSize)
    bg:setPosition(utils.getLocalCenter(self))
    self:addChild(bg,2)
    xTry(function ()
        local dataTable = rewards
        self:setVisible(true)
        self.viewData = createSpineView(dataTable)

        self.viewData.view:setPosition(utils.getLocalCenter(bg))
        bg:addChild(self.viewData.view)

        local closeLabel = display.newLabel(bgSize.width/2 , 170, { ap = display.CENTER ,fontSize = 22,  text = __('20秒后自动关闭') })
        bg:addChild(closeLabel)
        closeLabel:setOpacity(0)
        closeLabel:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.FadeIn:create(0.5)) )
        -- 关闭界面的按钮
        local closeBtn = display.newButton(bgSize.width/2, 40 , { ap = display.CENTER_BOTTOM, n = _res('ui/common/common_btn_orange')})
        bg:addChild(closeBtn)
        display.commonLabelParams(closeBtn, fontWithColor('14', {text =__('确定') }))
        local currentTime = os.time()
        bg:runAction(
            cc.RepeatForever:create(
                cc.Sequence:create(
                cc.DelayTime:create(0.2),
                cc.CallFunc:create(
                    function ()
                        local nowTime = os.time()
                        local distanceTime  =  nowTime - currentTime
                        if distanceTime >= 20 then
                            if  self.closefunction and type(self.closefunction) == "function" then
                                self.closefunction()
                                bg:stopAllActions()
                            end
                        end
                    end)
                )
            )
        )
        closeBtn:setOpacity(0)
        closeBtn:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.FadeIn:create(0.5)) )
        closeBtn:setOnClickScriptHandler(
            function ()
                local nowTime = os.time()
                if self.isTouble or ( nowTime - currentTime) > 1 then
                    if  self.closefunction and type(self.closefunction) == "function" then
                        self.closefunction()
                    end
                end
        end)
    end, __G__TRACKBACK__)


end

function RollPopUpReward:onEnter()
    PlayAudioClip(AUDIOS.UI.ui_mission.id)
end

return RollPopUpReward
