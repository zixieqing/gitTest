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

local AvatarPopUpReward = class('AvatarPopUpReward', function ()
	local clb = CLayout:create(cc.size(display.width, display.height))
    clb.name = 'common.AvatarPopUpReward'
    clb:enableNodeEvents()
    return clb
end)
---传入参数格式  {rewardData = {} ,consumeData{}}
function AvatarPopUpReward:ctor(...)
	self.args = unpack({...})
	self.consumeData  =  self.args.consumeData -- 传消耗品
	self.rewardData  = self.args.rewardData -- 获得的奖励
	self.msg = self.args.msg

	CommonUtils.DrawRewards( self.rewardData)
	self.closefunction  = nil
	local rewards = self.rewardData
	local createGoods  = function (data,delayTime)
		local goodNode = require('common.GoodNode').new({id = data.goodsId, amount = data.num, showAmount = true })
		display.commonUIParams(goodNode, {animate = false, cb = function (sender)
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
		end})
		goodNode:setScale(0.8)
		goodNode:setOpacity(0)
		local seqTable = {}
		local fadeIn = cc.FadeIn:create(0.25)
		local jumpBy = cc.JumpBy:create(0.25,cc.p(0,150),60,1)
		local spawn = cc.Spawn:create(jumpBy,fadeIn)
		seqTable[#seqTable+1] = cc.DelayTime:create(delayTime)
		seqTable[#seqTable+1] = spawn
		local seqAction = cc.Sequence:create(seqTable)
		goodNode:runAction(seqAction)
		return goodNode
	end
	local function createConumseView(datas)

		local distanceWidth = 100
		local num = table.nums(datas)  >= 1 and table.nums(datas) or 1
		local needSize = cc.size(distanceWidth*num,108)
		local bgSize = cc.size(needSize.width , 140)
		local bgLayout = CLayout:create(bgSize)
		local layout = CLayout:create(needSize)
		local swallowLayer = display.newLayer(bgSize.width/2,bgSize.height/2, { ap = display.CENTER ,color = cc.c4b(0,0,0,0), enable = true})
		bgLayout:addChild(swallowLayer)
		bgLayout:addChild(layout)
		layout:setAnchorPoint(display.CENTER_BOTTOM)
		layout:setPosition(cc.p(bgSize.width/2 ,0))
		local commontitleImage = display.newImageView('ui/common/common_title_5.png',bgSize.width/2 , bgSize.height , { ap = display.CENTER_TOP})
		bgLayout:addChild(commontitleImage)
		local commontitleImageSize = commontitleImage:getContentSize()
		local label = display.newLabel(commontitleImageSize.width/2,commontitleImageSize.height/2, fontWithColor(10,{text = __('总共售出')}))
		commontitleImage:addChild(label)
		for i =1 , #datas do
			local data = datas[i]
			data.goodsId = app.cookingMgr:GetFoodIdByRecipeId(data.goodsId) or data.goodsId
			local goodNode = require('common.GoodNode').new({id = data.goodsId, amount = data.num, showAmount = true})
				display.commonUIParams(goodNode, {animate = false, cb = function (sender)
					uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
					-- uiMgr:AddDialog("common.GainPopup", {goodId = data.goodsId})
			end})
			-- goodNode:setVisible(false)
			goodNode:setAnchorPoint(cc.p(0.5,0.5))
			goodNode:setPosition(cc.p((i-0.5)*distanceWidth ,needSize.height/2))
			goodNode:setScale(0.8)
			layout:addChild(goodNode)
		end

		return bgLayout
	end
	local  function createSpineView (rewardsTable)
		-- body
		local size = cc.size(900, 652)
		-- sp.SpineAnimationCache:getInstance():addCacheData('effects/rewardgoods/skeleton.json', 'effects/rewardgoods/skeleton.atlas', 'rewardicon', 1)
		-- local ico_dish  = sp.SpineAnimationCache:getInstance():createWithName('rewardicon')
		local ico_dish = CommonUtils.GetRrawRewardsSpineAnimation()
		-- view
		local  spinecallBack = function (event)
			if event.animation ==  'play' then
				ico_dish:setToSetupPose()
			end
		end

		-- local view = display.newLayer(0, 0, {size = size, ap = cc.p(0.5, 0.5 ) ,color = cc.r4b()})
		local view = display.newLayer(0, 0, {size = size ,ap = display.CENTER})
		local swallView = display.newLayer(size.width/2,size.height/2,{ ap = display.CENTER , size = cc.size(900 ,300),  color = cc.c4b(0,0,0,0) ,enable = true})
		view:addChild(swallView)
		local  bgLayer = display.newLayer(0, 0, {size = cc.size(display.width,display.height), ap = cc.p(0.5, 0.5), color = cc.c4b(0,0,0,100), enable = true})
		bgLayer:setPosition(utils.getLocalCenter(self))
		local isTouble  = false
		self:setVisible(true)
		bgLayer:setOnClickScriptHandler(function(sender)
			if isTouble then
				isTouble = false
				self.closefunction()
			end
        end)
		local setBgLayerClick = function ()
			isTouble = true
			-- bgLayer:setTouchEnabled(true)
		end
		if self.msg and self.msg ~="" then
			local offsetY = 28 * ((#rewardsTable / 5) <= 1 and 0 or 1)
			local  msgLabel = display.newLabel(size.width/2, size.height/2+80 + offsetY, fontWithColor('9',{ fontSize = 24 ,  text = self.msg }) )
			msgLabel:setOpacity(0)
			msgLabel:runAction( cc.Sequence:create(cc.DelayTime:create(1.2), cc.FadeIn:create(0.3)) )
			view:addChild(msgLabel,2)
		end
		local rewardImage = display.newImageView(_res('ui/common/common_avatar_bunissnes_report.png'),display.cx, display.height+60)
    	self:addChild(rewardImage,2)
		local rewardPoint_Srtart =  cc.p(display.cx ,  display.height+94.6-110)
        local rewardPoint_one = cc.p(display.cx ,  display.cy+300-35.5-110)
        local rewardPoint_Two = cc.p(display.cx ,  display.cy+300+24-110)
        local rewardPoint_Three = cc.p(display.cx ,  display.cy+300-15-110)
        local rewardPoint_Four = cc.p(display.cx ,  display.cy+300-15-110)
        local rewardSequnece = cc.Sequence:create(    -- 获取队列的动画展示
            cc.DelayTime:create(0.3) ,cc.CallFunc:create(function ( )
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
		local delayAction = cc.DelayTime:create(0.3)
		lightCircle1:setOpacity(0)
		local callfun2 = function ()
			lightCircle1:stopAllActions()
			lightCircle1:runAction(cc.RepeatForever:create(cc.Spawn:create(cc.Sequence:create(cc.FadeTo:create(2.25,100),cc.FadeTo:create(2.25,255)), cc.RotateBy:create(4.5,180))))
		end
    	local seqAction1 = cc.Sequence:create(delayAction ,cc.FadeIn:create(0.25),cc.CallFunc:create(callfun2))
    	lightCircle1:runAction(seqAction1)
		bgLayer:runAction(cc.Sequence:create(cc.DelayTime:create(0.6),cc.CallFunc:create(setBgLayerClick)))
		self:addChild(bgLayer)
		display.commonUIParams(ico_dish, {po = cc.p(size.width/2,size.height/2)})
		view:addChild(ico_dish,1)
		ico_dish:setAnimation(0, 'play', false)
		ico_dish:registerSpineEventHandler(spinecallBack, sp.EventType.ANIMATION_COMPLETE)
		local  count = #rewardsTable
		local width = 105
		local Num = 0
		if count > 5 then
			Num = 5
		else
			Num = count
		end

		local goodsLayoutSize = cc.size(width* Num,120)
		local goodLayout =  CLayout:create(goodsLayoutSize)
		goodLayout:setAnchorPoint(display.CENTER)
		goodLayout:setPosition(cc.p(size.width/2,size.height/2))
		for i = 1, count do
			if count <=  5 then
				local itemNode = createGoods(rewardsTable[i],0.05*i+0.4)
				itemNode:setPosition(cc.p(width*(i - 0.5),60 - 150))
				goodLayout:addChild(itemNode)
			elseif  count >=5 then
				if i <= 5 then
					local itemNode = createGoods(rewardsTable[i],0.05*i+0.4)
					itemNode:setPosition(cc.p(width*(i - 0.5),120- 150 - 15))
					goodLayout:addChild(itemNode)
				else
					local itemNode = createGoods(rewardsTable[i],0.05*i+0.4)
					itemNode:setPosition(cc.p(width*(i -5- 0.5),10- 150 + 5))
					goodLayout:addChild(itemNode)

				end
			end
		end
		self.consumeView = createConumseView(self.consumeData)
		self.consumeView:setOpacity(0)
		self.consumeView:setVisible(true)
		self.consumeView:setPosition(cc.p(size.width/2,size.height/2 - 300))
		view:addChild(self.consumeView)
		self.consumeView:runAction(cc.Sequence:create(cc.DelayTime:create(1.05 ),
				cc.Spawn:create(
					cc.FadeIn:create(0.2),
					cc.JumpTo:create(0.2, cc.p(size.width/2,size.height/2 - 220) , 10,1)
				)
			)
		)
		view:addChild(goodLayout,2)
		self.closefunction = function ()
			ico_dish:setToSetupPose()
			self:runAction( cc.Sequence:create( cc.Hide:create(), cc.DelayTime:create(0.1),cc.Hide:create() ,cc.RemoveSelf:create()) )
		end
		return {
			view = view,
			ico_dish = ico_dish
		}
	end
	local bg = CLayout:create(cc.size(900, 652))
	bg:setPosition(utils.getLocalCenter(self))
	self:addChild(bg,2)
	xTry(function ()
			local dataTable = rewards
			self:setVisible(true)

			self.viewData = createSpineView(dataTable)

			self.viewData.view:setPosition(utils.getLocalCenter(bg))
			bg:addChild(self.viewData.view)
	end, __G__TRACKBACK__)



end

function AvatarPopUpReward:onEnter()
    PlayAudioClip(AUDIOS.UI.ui_mission.id)
end

return AvatarPopUpReward
