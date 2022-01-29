--[[
通用奖励界面
@params {
    addBackpack = true -是否添加到背包，初始为true
	rewards table 道具列表
    mainExp int 主角经验数值
	closeCallback function 动画结束回调
}
--]]
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local gameMgr = AppFacade.GetInstance():GetManager('GameManager')

local RewardPopup = class('RewardPopup', function ()
	local clb = CLayout:create(cc.size(display.width, display.height))
    clb.name = 'common.RewardPopup'
    clb:enableNodeEvents()
    return clb
end)

function RewardPopup:ctor(...)
	self.args = unpack({...})
	self.delayTime = self.args.delayTime 
	self.msg = self.args.msg 
	self.type = self.args.type or 1  --  1 常规图片 ，2 菜谱研发type  
	self.blingLimit = self.args.blingLimit -- 抽宝石保底显示闪光
	self.showConfirmBtn = self.args.showConfirmBtn or false -- 是否显示确定按钮
	self.capsuleRewards = self.args.capsuleRewards or false -- 是否为抽卡奖励
	self.args.rewards = self.args.rewards or {}
    if GuideUtils.GetDirector() then
        GuideUtils.GetDirector():TouchDisable(true)
    end
    self.addBackpack = true
    self.consumePartyGood = self.args.consumePartyGood
    if self.args.addBackpack == false then
        self.addBackpack = self.args.addBackpack or false
    end
	self.args.rewards = self.args.rewards or {}
    local rewards = checktable(self.args.rewards)
	-- rewards  = { {goodsId = DIAMOND_ID , num  =100 } }
	local rewardsTableCounts = {}  --这个适用于知名度之前的一个克隆
    local deltaExp = 0
	if  self.args.tag then 
		if type(self.args.tag)  == 'number' then
			self:setTag(self.args.tag)
		end
	end
	if self.args.delayFuncList_ then
	 	self.delayFuncList_ = self.args.delayFuncList_ 
	end
	-- 先转化数据数据后加入到背包中
	local isdebris = false  -- 获取的道具奖励里面是否含有碎片
	self.activityChestData = {}
	for i = #self.args.rewards ,1 ,-1 do
		local v = self.args.rewards[i]
		if v.turnGoodsId and checkint(v.turnGoodsNum)  > 0   then
			v.turnGoodsId , v.goodsId =v.goodsId  , v.turnGoodsId
			v.turnGoodsNum , v.num =v.num , v.turnGoodsNum
			isdebris = true
		else
			local ugType = CommonUtils.GetGoodTypeById(checkint(v.goodsId))
			if ugType ==  GoodsType.TYPE_CARD_SKIN  then -- 如果是皮肤 而且已经具有了
				local isHave = app.cardMgr.IsHaveCardSkin(v.goodsId)
				if isHave then
					isdebris = true
					local skinData = CommonUtils.GetConfig('goods','cardSkin',v.goodsId) or {}
					local data = clone(skinData.changeGoods)
					if table.nums(skinData.changeGoods)  > 0   then
						v.turnGoodsId , v.goodsId = v.goodsId  , data[1].goodsId
						v.turnGoodsNum , v.num = v.num , v.num * checkint(data[1].num)
					end
				end
			elseif ugType == GoodsType.TYPE_PRIVATEROOM_SOUVENIR  then
				local num  = checkint(CommonUtils.GetCacheProductNum(v.goodsId))
				if num > 0 then
					isdebris = true
					local privateRoomGiftData = CommonUtils.GetConfig('goods','privateRoomGift',v.goodsId) or {}
					local data = clone(privateRoomGiftData.changeGoods)
					if table.nums(privateRoomGiftData.changeGoods)  > 0   then
						v.turnGoodsId , v.goodsId = v.goodsId  , data[1].goodsId
						v.turnGoodsNum , v.num = v.num , v.num * checkint(data[1].num)
					end
				end
			elseif ugType == GoodsType.TYPE_TTGAME_PACK  then
				local battleCardId = checkint(v.turnGoodsId)
				if app.ttGameMgr:hasBattleCardId(battleCardId) then
					isdebris = true
					local cardConfInfo  = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.CARD_DEFINE, battleCardId)
					local turnGoodsInfo = checktable(cardConfInfo.exchange)[1] or {}
					v.turnGoodsId  = checkint(turnGoodsInfo.goodsId)
					v.turnGoodsNum = checkint(turnGoodsInfo.num)
				else
					isdebris = true
					v.turnGoodsNum = checkint(v.num)
				end
				v.turnGoodsId,  v.goodsId = v.goodsId, v.turnGoodsId
				v.turnGoodsNum, v.num     = v.num,     v.turnGoodsNum
			elseif ugType == GoodsType.TYPE_ACTIVITY_CHEST then
				self.activityChestData[#self.activityChestData+1] = table.remove(self.args.rewards , i )
			end
		end
	end
    if self.args.mainExp then
        if checkint(self.args.mainExp) > 0 then
            deltaExp = self.args.mainExp - gameMgr:GetUserInfo().mainExp
            if deltaExp > 0 then
            	table.insert(rewards, {goodsId = EXP_ID, num = deltaExp})
            end      
        end
    end
	if self.args.popularity then
        if checkint(self.args.popularity) > 0 then
            local  popularityNum  = self.args.popularity - gameMgr:GetUserInfo().popularity
            if popularityNum > 0 then
            	table.insert(rewards, {goodsId = POPULARITY_ID, num = popularityNum})
            end      
        end
    end
	rewardsTableCounts = clone(rewards) -- 最高知名度的更新
	local crystalTable  = {}
	for i, v in pairs(rewardsTableCounts) do
		if checkint(v.type)  == checkint(GoodsType.TYPE_CG_FRAGMENT)   then
			crystalTable[#crystalTable+1] = v
		end
	end
	for i, v in pairs(rewardsTableCounts) do
		local uType = CommonUtils.GetGoodTypeById(v.goodsId )
		if uType  ==  GoodsType.TYPE_CG_FRAGMENT   then
			if v.turnGoodsId then
				v.type = GoodsType.TYPE_CG_FRAGMENT
				crystalTable[#crystalTable+1] = v
			else
				crystalTable[#crystalTable+1] = v
			end
		end
	end
	if #crystalTable > 0  then
		if not self.args.closeCallback then
			self.args.closeCallback = function()
				local cgRewardsLayer = require('Game.views.collectCG.CGRewardsLayer').new({data = crystalTable} )
				cgRewardsLayer:setPosition(display.center)
				app.uiMgr:GetCurrentScene():AddDialog(cgRewardsLayer)
				-- 此处添加cg 碎片的转化播放
			end
		end
	end
	if self.args.highestPopularity then
		if checkint(self.args.highestPopularity) > 0 then
			local highestPopularityNum  = self.args.highestPopularity - gameMgr:GetUserInfo().highestPopularity
			if highestPopularityNum > 0 then
				table.insert(rewardsTableCounts, {goodsId = HIGHESTPOPULARITY_ID, num = highestPopularityNum})
			end
		end
	end

	self.rewardsTableCounts = rewardsTableCounts
    if self.addBackpack == true and  table.nums(rewardsTableCounts) > 0 then
		self.delayFuncList_ = CommonUtils.DrawRewards(rewardsTableCounts,true)
    end
    self:setVisible(false)
	-------------------------------
	-- ui
	local isBox = false 
	if self.args.rewards.requestData then
		if self.args.rewards.requestData.goodsId then
			if CommonUtils.GetGoodTypeById(self.args.rewards.requestData.goodsId) == GoodsType.TYPE_GOODS_CHEST  then
				local boxDatas = CommonUtils.GetConfig('goods','goods',self.args.rewards.requestData.goodsId)
				if checkint(boxDatas.chestActId) == 0  then
					isBox = false
				else
					isBox = true
				end
			end
		end
	end


	self.closefunction = nil 
	local function CreateView()

		local size = cc.size(586, 652)

		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_4.png'), 0, 0, {scale9 = true, size = size})

		-- view
		local view = display.newLayer(0, 0, {size = size, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = utils.getLocalCenter(bg)})
		view:addChild(bg, 1)

		-- title 
		local titleBg = display.newImageView(_res('ui/common/result_reward_title_bg.png'), size.width * 0.5, size.height + 15)
		bg:addChild(titleBg)

		local title = display.newNSprite(_res('ui/common/result_reward_title.png'), utils.getLocalCenter(titleBg).x, utils.getLocalCenter(titleBg).y - 15)
		titleBg:addChild(title)

		-- shine 
		local rewardShine = display.newNSprite(_res('ui/common/common_light.png'), size.width * 0.5, size.height * 0.85)
		view:addChild(rewardShine)

		-- line
		local line = display.newNSprite(_res('ui/common/kitchen_tool_split_line.png'), size.width * 0.5, 85)
		view:addChild(line, 10)

		-- confirm btn
		local confirmBtn = display.newButton(size.width * 0.5 - 8, 40, {n = _res('ui/common/common_btn_orange.png'), cb = function (sender)
			if self.args.closeCallback then
				self.args.closeCallback()
			end
			self:runAction(cc.RemoveSelf:create())
		end})
		view:addChild(confirmBtn, 10)
		display.commonLabelParams(confirmBtn, fontWithColor(14,{text = __('确定')}))

		-- rewards list
		local listSize = cc.size(size.width, size.height - 115)
		local rewardList = CListView:create(listSize)
		rewardList:setDirection(eScrollViewDirectionVertical)
		rewardList:setAnchorPoint(cc.p(0.5, 0))
		rewardList:setPosition(size.width * 0.5 - 2, line:getPositionY() - 6)
		view:addChild(rewardList, 11)
		-- rewardList:setBackgroundColor(cc.c4b(255, 0, 0, 128))

		-- 创建奖励cell
		local data = {}
		local Columns = 8
		for i = 1 , table.nums(self.args.rewards) do
			local Remainder = (i%Columns)
			local Multiple = math.ceil(i/Columns) 
			if not data[Multiple]  then
				data[Multiple] = {}
			end
			local positionY = 0
			if Remainder ~= 0 then
				positionY = Remainder
			else
				positionY = Columns
			end 
			data[Multiple][positionY] = clone(self.args.rewards[i]) 
		end
		local seqTable ={}
		for i = 1, #data do

			local cell = nil 

			if i <= 5  then
				cell = self:CreateRewardCell(data[i])
				rewardList:insertNodeAtLast(cell)
			else
				seqTable[#seqTable+1] = cc.DelayTime:create(0.1)
				if i%5 == 0 then
					seqTable[#seqTable+1] = cc.CallFunc:create(function ()
						rewardList:reloadData()
					end)
				end
				seqTable[#seqTable+1] = cc.CallFunc:create(function ()
					cell = self:CreateRewardCell(data[i])
					rewardList:insertNodeAtLast(cell)
				end)

			end
			if i == (#data) then
				seqTable[#seqTable+1] = cc.CallFunc:create(function ( )
					rewardList:reloadData()
				end)
				local seqAction =  transition.sequence(seqTable)
				rewardList:runAction(seqAction)
			end

		end	 
		rewardList:reloadData()
		-- 	rewardList:insertNodeAtLast(cell)
		-- for i = 1, table.nums(self.args.rewards) do
		-- 	Count = Count  + 1
		-- 	local CountNum = Count
		-- 	local remainder = (CountNum%8) 

		-- 	if remainder == 0 then
		-- 		lineTrue = true
		-- 	end
		-- 	local data = {} 
		-- 	data.rewards = {}
		-- 	data.rewards[#data.rewards + 1] = self.args.rewards[i] 
		-- 	rewardsData = self.rewardsData.sweep[tostring(i)]
		-- end

		

		return {
			view = view,
			rewardList = rewardList
		}

	end

	
	local createGoods  = function (data,delayTime)
		local goodNode = nil
		local goodsId = checkint(data.goodsId)
		local goodsType = CommonUtils.GetGoodTypeById(goodsId)
		if GoodsType.TYPE_PET == goodsType  and nil ~= data.playerPet then
			-- 获得堕神使用特殊的icon
			local petData = {
				petId = checkint(data.playerPet.petId),
				level = 1,
				breakLevel = 0,
				character = checkint(data.playerPet.character)
			}
			goodNode = require('common.PetHeadNode').new({
				showLockState = false,
				showBaseState = false
			})
			goodNode:RefreshUI({petData = petData})
		elseif GoodsType.TYPE_CARD == goodsType then
			goodNode = self:CreateGoodsNode({goodsId = data.goodsId, goodsNum = data.num, showAmount = true, showRemindIcon = true})
		elseif GoodsType.TYPE_TTGAME_CARD == goodsType then
			local cardNode = TTGameUtils.GetBattleCardNode({cardId = data.goodsId, zoomModel = 's'})
			cardNode:setAnchorPoint(display.LEFT_BOTTOM)
			goodNode = display.newButton(0, 0, {n = _res('ui/common/story_tranparent_bg.png'), scale9 = true, size = cardNode:getContentSize()})
			goodNode:setCascadeOpacityEnabled(true)
			goodNode:addChild(cardNode)
		else
			goodNode = require('common.GoodNode').new({id = data.goodsId, amount = data.num, showAmount = true, blingLimit = self.blingLimit })
		end

		display.commonUIParams(goodNode, {animate = false, cb = function (sender)
			self:ShowInformationTips(sender, data.goodsId)
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
		-- goodNode:setScale(spriteScale)
		-- display.commonUIParams(goodNode, {ap = cc.p(0.5, 0),
		-- 	po = cc.p((i-0.5-Middle) * (spriteWidth + paddingX) * spriteScale+size.width/2,size.height *13/30)})
		-- view:addChild(goodNode, 5)
		-- goodNodeTable[#goodNodeTable+1] = goodNode
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

		local view = display.newLayer(0, 0, {size = size, ap = cc.p(0.5, 0.5)})
		local swallView = display.newLayer(size.width/2,size.height/2,{ ap = display.CENTER , size = cc.size(900 ,300),  color = cc.c4b(0,0,0,0) ,enable = true})
		view:addChild(swallView)
		local  bgLayer = display.newLayer(0, 0, {size = cc.size(display.width,display.height), ap = cc.p(0.5, 0.5), color = cc.c4b(0,0,0,100), enable = true})
		bgLayer:setPosition(utils.getLocalCenter(self))
		self.isTouble  = false
		self:setVisible(true)
		if not self.showConfirmBtn then
			bgLayer:setOnClickScriptHandler(function(sender)
				PlayAudioByClickNormal()
				if self.isTouble then
					self.isTouble = false
					if self.closefunction then
						self.closefunction()
					end
				end
			end)
		end
		local rewardImage = display.newImageView(_res('ui/common/common_words_congratulations.png'),display.cx, display.height+60)
		if self.type == 2  then
			rewardImage:setTexture(_res('ui/common/cooking_words_fail.png'))
		end
    	self:addChild(rewardImage,2)
		local rewardPoint_Srtart =  cc.p(display.cx ,  display.height+94.6-110)
        local rewardPoint_one = cc.p(display.cx ,  display.cy+300-35.5-110)
        local rewardPoint_Two = cc.p(display.cx ,  display.cy+300+24-110)
        local rewardPoint_Three = cc.p(display.cx ,  display.cy+300-15-110)
        local rewardPoint_Four = cc.p(display.cx ,  display.cy+300-15-110)
        local rewardSequnece = cc.Sequence:create(    -- 获取队列的动画展示
            cc.DelayTime:create(0.3) ,
				cc.CallFunc:create(function ( )
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
		local setBgLayerClick = function ()
			self.isTouble = true
			-- bgLayer:setTouchEnabled(true)
		end

		if self.msg and self.msg ~="" then
			local count  = table.nums(rewardsTable)
			local posY = 80
			if count > 5 then
				posY = 100
			end
			local  msgLabel = display.newLabel(size.width/2,size.height/2+posY,fontWithColor('9',{ fontSize = 24 ,text = self.msg }) )
			msgLabel:setOpacity(0)
			msgLabel:runAction( cc.Sequence:create(cc.DelayTime:create(1.2), cc.FadeIn:create(0.3)) )
			view:addChild(msgLabel,2)
		end
		local descrScrollView = cc.ScrollView:create(cc.size(size.width, 400))
		descrScrollView:setDirection(eScrollViewDirectionVertical)
		--descrScrollView:setViewSize(cc.size(display.width/2, 400))
		descrScrollView:setPosition(cc.p(0,size.height*3/4-25))
		descrScrollView:setAnchorPoint(display.CENTER)
		view:addChild(descrScrollView,0)
		local lightCircle1 = display.newImageView(_res('ui/common/common_reward_light.png'),{ap = display.CENTER})
		lightCircle1:setPosition(cc.p(size.width/2,0))
		descrScrollView:addChild(lightCircle1)
		local delayAction = cc.DelayTime:create(0.3)
		lightCircle1:setOpacity(0)
		local callfun2 = function ()
			PlayAudioClip(AUDIOS.UI.ui_mission.id)
			lightCircle1:stopAllActions()
			lightCircle1:runAction(cc.RepeatForever:create(cc.Spawn:create(cc.Sequence:create(cc.FadeTo:create(2.25,100),cc.FadeTo:create(2.25,255)), cc.RotateBy:create(4.5,180))))
		end
    	local seqAction1 = cc.Sequence:create(delayAction ,cc.FadeIn:create(0.25),cc.CallFunc:create(callfun2))
    	lightCircle1:runAction(seqAction1)
		bgLayer:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),cc.CallFunc:create(setBgLayerClick)))
		self:addChild(bgLayer)
		display.commonUIParams(ico_dish, {po = cc.p(size.width/2,size.height/2)})
		view:addChild(ico_dish,1)
		ico_dish:setAnimation(0, 'play', false)
		ico_dish:registerSpineEventHandler(spinecallBack, sp.EventType.ANIMATION_COMPLETE)
		
		local  count = #rewardsTable
		local width = 105
		local Num  = 0
		if count > 5 then
			Num = 5
		else
			Num = count
		end

		local goodsLayoutSize = cc.size(width* Num,120)
		local goodLayout = CLayout:create(goodsLayoutSize)
		goodLayout:setAnchorPoint(display.CENTER)
		goodLayout:setPosition(cc.p(size.width/2,size.height/2))
		for i = 1, count do
			if count <=  5 then
				local itemNode = createGoods(rewardsTable[i],0.05*i + 0.4 )
				itemNode:setPosition(cc.p(width*(i - 0.5),60 - 150))
				goodLayout:addChild(itemNode)
			elseif  count >=5 then
				if i <= 5 then
					local itemNode = createGoods(rewardsTable[i],0.05*i+ 0.4)
					itemNode:setPosition(cc.p(width*(i - 0.5),120- 150))
					goodLayout:addChild(itemNode)
				else
					local itemNode = createGoods(rewardsTable[i],0.05*i+  0.4)
					itemNode:setPosition(cc.p(width*(i -5- 0.5),10- 150))
					goodLayout:addChild(itemNode)

				end
			end
		end

		view:addChild(goodLayout,2)
		self.closefunction = function ()
			if self.args.closeCallback then
				self.args.closeCallback()
			end
			ico_dish:setToSetupPose()
			self:runAction( cc.Sequence:create( cc.Hide:create(), cc.DelayTime:create(0.1),cc.Hide:create() ,cc.RemoveSelf:create()) )
		end
		-- 返回按钮
		if self.showConfirmBtn then
			local confirmBtn = display.newButton(size.width * 0.5 - 8, 40, {n = _res('ui/common/common_btn_orange.png'), cb = function(sender)
				PlayAudioByClickNormal()
				if self.isTouble then
					self.isTouble = false
					if self.closefunction then
						self.closefunction()
					end
				end
			end})
			confirmBtn:setOpacity(0)
			confirmBtn:setVisible(false)
			confirmBtn:runAction(cc.Sequence:create(
				cc.DelayTime:create(1),
				cc.Show:create(),
				cc.FadeIn:create(0.5)
			))
			view:addChild(confirmBtn, 10)
			display.commonLabelParams(confirmBtn, fontWithColor(14,{text = __('确定')}))
		end
		return {
			view = view,
			ico_dish = ico_dish
		}
	end

	local createBoxGoods  = function (data,delayTime,endPos)
		local goodNode = self:CreateGoodsNode({goodsId = data.goodsId, goodsNum = data.num, showAmount = true})
		display.commonUIParams(goodNode, {animate = false, cb = function (sender)
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
		end})
		local goodSize =  cc.size(108,108)
		local goodLayout = CLayout:create(goodSize)
		goodNode:setPosition(cc.p(goodSize.width/2 , goodSize.height/2))
		goodNode:setScale(0.7)
		goodLayout:addChild(goodNode,2)
		local lightCircle = display.newImageView(_res(string.format("effects/dabaoxiang/box_reward_light_%d.png" ,goodNode.goodData.quality or 1 )),goodSize.width/2 , goodSize.height /2 )
		goodLayout:addChild(lightCircle)
		goodLayout:setScale(0.1)
		goodLayout:setOpacity(125)
		local num = 2
		local callback =  function ( )
			lightCircle:setOpacity(125)
			lightCircle:runAction( cc.RepeatForever:create(cc.Sequence:create(cc.FadeTo:create(2,255) ,
				cc.FadeTo:create(2, 125)
			)))
		end
		 goodLayout:runAction( 
			cc.Sequence:create(cc.DelayTime:create(delayTime) , 
			cc.Spawn:create(cc.FadeTo:create(0.1*num ,255),cc.MoveTo:create(0.1*num, endPos ),cc.ScaleTo:create(0.1*num, 1)) ,
			cc.CallFunc:create(callback)))
		return goodLayout
	end

	local createBoxGoods = function (data)
	 	self:setVisible(true)
		local   closeView = display.newLayer(display.cx, display.cy ,{ ap = display.CENTER ,size = display.size, color = cc.c4b(0,0,0,100) , enable =true })
		self:addChild(closeView)
		
		local goodWidth = 108
		local goodHeight = 135
		local goodsNodeSize = cc.size(goodWidth * 5 , (math.ceil(#data/5 ) ) * goodHeight)
		local goodsNodeLayout = CLayout:create(goodsNodeSize)
		goodsNodeLayout:setPosition(cc.p(display.cx, display.cy+100))
		-- goodsNodeLayout:setBackgroundColor(cc.c3b(100,100,100))
		self:addChild(goodsNodeLayout,1)

		local  closeBtn = display.newButton(display.cx , display.cy -  250 ,{n = _res('ui/common/common_btn_orange.png') , s = _res('ui/commmon/common_btn_orange.png') 
		, cb = function ( )
			PlayAudioByClickNormal()
			if self.args.closeCallback then
				self.args.closeCallback()
			end
			self:runAction(cc.RemoveSelf:create())
		end})
		local callback = function ( )
			closeBtn:setEnabled(true)
		end
		closeBtn:setEnabled(false)
		closeBtn:setVisible(false)
		closeBtn:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(callback)))
		display.commonLabelParams(closeBtn, fontWithColor(14,{text = __('确 定')}))
		self:addChild(closeBtn,2)
		local boxDatas = CommonUtils.GetConfig('goods','goods',self.args.rewards.requestData.goodsId)
		local Num = checkint(boxDatas.chestActId)  
		--Num = Num >= 1 and  Num <=8 and  Num  or 1
		local rewardLight = display.newImageView(_res('effects/dabaoxiang/box_reward_light.png'),display.cx,  display.cy -  250 , { ap = display.CENTER_BOTTOM})
		self:addChild(rewardLight)
		rewardLight:setOpacity(0)
		local spinecallBack = function ()
			PlayAudioClip(AUDIOS.UI.ui_explore_treasure.id)
			closeBtn:setVisible(true)
			rewardLight:runAction(cc.FadeIn:create(0.1))
			local pos = goodsNodeLayout:convertToNodeSpace(cc.p(display.cx , display.cy - 150 ))    --cc.p(goodsNodeSize.width/2 , goodsNodeSize.height/2 - display.cy + 200)
			local count = math.ceil(#data/5) 
			for i =1 , #data do 
				local  num = math.abs((i - 0.5)) 
				local  endPosition =  cc.p((num > 5  and num - 5  or num) * goodWidth , (count - (math.ceil( i/5 ) - 0.5))  * goodHeight ) 
				local goodLayout =  createBoxGoods(data[i], 0.01*i , endPosition)
				goodLayout:setPosition(pos)
				goodsNodeLayout:addChild(goodLayout)
			end
		end

		local qAvatar = sp.SkeletonAnimation:create( string.format( 'effects/dabaoxiang/box_%d.json',Num)  ,  string.format('effects/dabaoxiang/box_%d.atlas' ,Num ) , 1)
        qAvatar:update(0)
        qAvatar:setTag(888)
        qAvatar:setAnimation(0, 'idle', false)
        qAvatar:setPosition(cc.p(display.cx, display.cy +50))
        self:addChild(qAvatar)
		qAvatar:registerSpineEventHandler(spinecallBack, sp.EventType.ANIMATION_COMPLETE)
	end
	local showRwardFunction  =  function ()
		local swallowLyer = display.newLayer(0,0, { color = cc.c4b(0, 0, 0, 100) , size = display.size , enable  = true })
		self:addChild(swallowLyer)
		local bg = CLayout:create(cc.size(900, 652))
		bg:setPosition(utils.getLocalCenter(self))
		self:addChild(bg,2)
		xTry(function ()
			local dataTable = rewards
			if table.nums(rewards)<= 10 then
				if self.delayTime then
					local callback1 =  function()
						self:setVisible(false)
					end
					local callback2 = function ()
						if isdebris then
							self.viewData = self:RewardGoodsAndDebris(dataTable)
						else
							self.viewData =  createSpineView(dataTable)
						end
						self.viewData.view:setPosition(utils.getLocalCenter(bg))
						bg:addChild(self.viewData.view)
					end
					local seqTable = {}
					seqTable[#seqTable+1] =  cc.CallFunc:create(callback1)
					seqTable[#seqTable+1] = cc.DelayTime:create(self.delayTime)
					seqTable[#seqTable+1] = cc.CallFunc:create(callback2)
					local seqAction  = cc.Sequence:create(seqTable)
					self:runAction(seqAction)	
				else
					self:setVisible(true)
					if isdebris then
						self.viewData = self:RewardGoodsAndDebris(dataTable)
					else
						self.viewData =  createSpineView(dataTable)
					end
					self.viewData.view:setPosition(utils.getLocalCenter(bg))
					bg:addChild(self.viewData.view)
				end
			else  -- 超过十个的时候
				--if isdebris then
				local callback1 =  function()
					self:setVisible(false)
				end
				local callback2 = function ()
					--if isdebris then
						self.viewData = self:RewardGoodsAndDebris(dataTable)
					--else
					--	self.viewData =  createSpineView(dataTable)
					--end
					self.viewData.view:setPosition(utils.getLocalCenter(bg))
					bg:addChild(self.viewData.view)
				end
				local seqTable = {}
				seqTable[#seqTable+1] =  cc.CallFunc:create(callback1)
				seqTable[#seqTable+1] = cc.DelayTime:create(checkint(self.delayTime) )
				seqTable[#seqTable+1] = cc.CallFunc:create(callback2)
				local seqAction  = cc.Sequence:create(seqTable)
				self:runAction(seqAction)
				--else
				--	self:setVisible(true)
				--	self.viewData = CreateView(dataTable)
				--	self.viewData.view:setPosition(utils.getLocalCenter(bg))
				--	bg:addChild(self.viewData.view)
				--end

			end 
		end, __G__TRACKBACK__)
	end
	if isBox then
		xTry(function () 
			if table.nums(rewards)<= 10 then
				createBoxGoods(rewards)
			else
				showRwardFunction()
			end

		end, __G__TRACKBACK__)
	else
		showRwardFunction()
	end

	if self.consumePartyGood and type(self.consumePartyGood) == "table"   and table.nums(self.consumePartyGood) > 0  then
		local bottomSize = cc.size(500, 150 )
		local layout =   display.newLayer(display.cx , display.cy - 210 , { size  = bottomSize   , ap = display.CENTER })
		self:addChild(layout ,20 )
		-- 吞噬层
		local swallowLyer =  display.newLayer(bottomSize.width/2  , bottomSize.height/2, { size  = bottomSize , color = cc.c4b(0,0,0,0)  , ap = display.CENTER  , enable = true })
		layout:addChild(swallowLyer)
		local labelMap = {}
		for i = 1  , #self.consumePartyGood do
			local data = self.consumePartyGood[i]
			local goodsData = CommonUtils.GetConfig('goods', 'goods' ,data.goodsId )
			if checkint( data.goodsId) > 0 and checkint(data.goodsId) == DIAMOND_ID and goodsData  then
				local consumNum = data.num
				local richLabel = display.newRichLabel(0,0,{ ap = display.CENTER , r = true ,  c= {
                    {fontSize = 24 , color = "#ffffff" , text =  __('本次筹备消耗') } ,
					fontWithColor( '14',{fontSize = 24 , color = "#fffeb40" , text =   " " .. consumNum ..  "  "  }) ,
					{img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID) , scale = 0.2   }
				}})
                CommonUtils.AddRichLabelTraceEffect(richLabel, nil , nil  , { 2})
                table.insert(labelMap , #labelMap+1 , richLabel)
			elseif goodsData then
                local consumNum = data.num
                local name = goodsData.name
                local richLabel = display.newRichLabel(0,0,{ r = true , ap = display.CENTER , c= {
                    {fontSize = 22 , color = "#ffffff" , text =    __('本次筹备消耗菜品') } ,
                    fontWithColor( '14',{fontSize = 24 , color = "#ffb821" , text = " " ..  name  }) ,
                    fontWithColor( '14',{fontSize = 24 , color = "#ffe4b0" , text = " " ..   consumNum }) ,
                    {fontSize = 22 , color = "#ffffff" , text = " " ..  __('个') } ,
                }})
                CommonUtils.AddRichLabelTraceEffect(richLabel, nil , nil  , { 2,3})
                table.insert(labelMap , 1 , richLabel)
			end
		end
        local height = 30
        local consumeSize =  cc.size(500, height *#labelMap )
        local consumeLayout  = display.newLayer(bottomSize.width/2 , bottomSize.height , { ap = display.CENTER_TOP ,
                                                                                           size = consumeSize })
        layout:addChild(consumeLayout)
        for i = 1, #labelMap  do
            labelMap[i]:setPosition(cc.p(consumeSize.width/2 , consumeSize.height - (i - 0.5 ) * height - 10))
            consumeLayout:addChild(labelMap[i])
        end
        -- 关闭的确认按钮
        local closeBtn   =  display.newButton(bottomSize.width/2 , 30 , {
            n =  _res('ui/common/common_btn_orange.png')
        })
        layout:add(closeBtn)
        display.commonLabelParams(closeBtn ,  fontWithColor('14' , { text = __('确定') }))
        local closefunction = self.closefunction
        self.closefunction = nil
        closeBtn:setOnClickScriptHandler(closefunction)
        layout:setOpacity(0)
        layout:runAction(cc.Sequence:create(
                cc.DelayTime:create(1.1),
                cc.FadeIn:create(0.5)
        ))
	end
end
--- 获取碎片和道具
function RewardPopup:RewardGoodsAndDebris(rewardsTable)
	-- 由于会有碎片的ID 所以要根据不同的碎片去判断产生的物品
	local createGoods  = function (data,delayTime)
		local goodsId = nil
		local num = nil
		local goodNodeTwo =  nil
		local goodsSize = cc.size(110 , 120)
		local goodLayout = CLayout:create(goodsSize)
		local showRemindIcon = true -- 道具icon是否显示小红点
		if data.turnGoodsId then
			showRemindIcon = false
			goodsId = checkint(data.turnGoodsId)
			num = checkint(data.num)
			goodNodeTwo = self:CreateGoodsNode({goodsId = data.goodsId, goodsNum = data.num, showAmount = true })
			display.commonUIParams(goodNodeTwo, {animate = false, cb = function (sender)
				self:ShowInformationTips(sender, data.goodsId, data.num)
			end})
			goodNodeTwo:setScale(0.8)
			goodNodeTwo:setVisible(false)
			goodLayout:addChild(goodNodeTwo)
			goodNodeTwo:setPosition(cc.p(goodsSize.width/2 , goodsSize.height/2))
		else
			goodsId = data.goodsId

		end
		local goodsNum = data.turnGoodsId  and data.turnGoodsNum or data.num
		local goodNode = self:CreateGoodsNode({goodsId = goodsId, goodsNum = goodsNum, showAmount = true, showRemindIcon = showRemindIcon})
		display.commonUIParams(goodNode, {animate = false, cb = function (sender)
			self:ShowInformationTips(sender, goodsId)
		end})
		goodNode:setPosition(cc.p(goodsSize.width/2 , goodsSize.height/2))
		goodNode:setScale(0.8)
		goodLayout:setOpacity(0)
		local seqAction = nil
		local seqTable = {}
		local seqTableOne = {}
		local seqTableTwo = {}

		local fadeIn = cc.FadeIn:create(0.25)
		local jumpBy = cc.JumpBy:create(0.25,cc.p(0,150),60,1)
		local spwanTable = {}
		spwanTable[#spwanTable+1] =  jumpBy
		spwanTable[#spwanTable+1] =  fadeIn
		--spwanTable[#spwanTable+1] =  cc.TargetedAction:create( goodNode,
		--cc.FadeIn:create(0.25)
		--)
		--if  data.turnGoodsId then
		--	spwanTable[#spwanTable+1] =  cc.TargetedAction:create( goodNodeTwo,
		--	cc.FadeIn:create(0.25)
		--	)
		--end
		local spawn = cc.Spawn:create(spwanTable)
		seqTable[#seqTable+1] = cc.DelayTime:create(delayTime)
		seqTable[#seqTable+1] = spawn

		if data.turnGoodsId then
			seqTableOne[#seqTableOne +1 ] = cc.DelayTime:create(0.2)
			seqTableOne[#seqTableOne +1 ] = cc.ScaleTo:create(0.5, 0,0.8)
			seqTableOne[#seqTableOne +1 ] = cc.CallFunc:create(
				function ()
					goodNodeTwo:setScaleX(0)
					goodNode:setVisible(false)
					goodNodeTwo:setVisible(true)
				end
			)

			seqTableTwo[#seqTableTwo+1] = cc.ScaleTo:create(0.5,0.8,0.8)
			local seqActionOne = cc.Sequence:create(seqTableOne)
			local seqActionTwo = cc.Sequence:create(seqTableTwo)

			local targetOneAction = cc.TargetedAction:create(goodNode , seqActionOne)
			local targetTwoAction = cc.TargetedAction:create(goodNodeTwo , seqActionTwo)
			seqAction = cc.Sequence:create({cc.Sequence:create(seqTable) ,  targetOneAction , targetTwoAction}  )
		else
			seqAction = cc.Sequence:create(seqTable)
		end
		goodLayout:runAction(seqAction)
		goodLayout:addChild(goodNode)
		return goodLayout
	end
	local size = cc.size(900, 652)
	local ico_dish = CommonUtils.GetRrawRewardsSpineAnimation()
	-- view
	local  spinecallBack = function (event)
		if event.animation ==  'play' then
			ico_dish:setToSetupPose()
		end
	end

	local view = display.newLayer(0, 0, {size = size, ap = cc.p(0.5, 0.5)})
	local swallView = display.newLayer(size.width/2,size.height/2,{ ap = display.CENTER , size = cc.size(900 ,300),  color = cc.c4b(0,0,0,0) ,enable = true})
	view:addChild(swallView)
	local  bgLayer = display.newLayer(0, 0, {size = cc.size(display.width,display.height), ap = cc.p(0.5, 0.5), color = cc.c4b(0,0,0,100), enable = true})
	bgLayer:setPosition(utils.getLocalCenter(self))
	self.isTouble  = false
	self:setVisible(true)
	if not self.showConfirmBtn then
		bgLayer:setOnClickScriptHandler(function(sender)
			if self.isTouble then
				self.isTouble = false
				if self.closefunction then
					self.closefunction()
				end
			end
		end)
	end
	local rewardImage = display.newImageView(_res('ui/common/common_words_congratulations.png'),display.cx, display.height+60)
	if self.type == 2  then
		rewardImage:setTexture(_res('ui/common/cooking_words_fail.png'))
	end
	self:addChild(rewardImage,2)
	local rewardPoint_Srtart =  cc.p(display.cx ,  display.height+94.6-110)
	local rewardPoint_one = cc.p(display.cx ,  display.cy+300-35.5-110)
	local rewardPoint_Two = cc.p(display.cx ,  display.cy+300+24-110)
	local rewardPoint_Three = cc.p(display.cx ,  display.cy+300-15-110)
	local rewardPoint_Four = cc.p(display.cx ,  display.cy+300-15-110)
	local rewardSequnece = cc.Sequence:create(    -- 获取队列的动画展示
		cc.DelayTime:create(1),
		cc.CallFunc:create(function ( )
			PlayAudioClip(AUDIOS.UI.ui_mission.id)
			rewardImage:setVisible(true)
			rewardImage:setOpacity(0)
			rewardImage:setPosition(rewardPoint_Srtart)
		end),
		cc.Spawn:create(
			cc.FadeIn:create(0.2),
			cc.MoveTo:create(0.2,rewardPoint_one)
		),
		cc.JumpTo:create(0.1,rewardPoint_Two,10,1) ,
		cc.MoveTo:create(0.1,rewardPoint_Three) ,
		cc.MoveTo:create(0.1,rewardPoint_Four)
	)
	rewardImage:runAction(rewardSequnece)
	local setBgLayerClick = function ()
		self.isTouble = true
		-- bgLayer:setTouchEnabled(true)
	end

	if self.msg and self.msg ~="" then
		local count  = table.nums(rewardsTable)
		local posY = 80
		if count > 5 then
			posY = 100
		end
		local  msgLabel = display.newLabel(size.width/2,size.height/2+posY,fontWithColor('9',{ fontSize = 24 ,text = self.msg }) )
		msgLabel:setOpacity(0)
		msgLabel:runAction( cc.Sequence:create(cc.DelayTime:create(1.2), cc.FadeIn:create(0.3)) )
		view:addChild(msgLabel,2)
	end
	local descrScrollView = cc.ScrollView:create()
	descrScrollView:setDirection(eScrollViewDirectionVertical)
	descrScrollView:setViewSize(cc.size(size.width, 400))
	descrScrollView:setPosition(cc.p(0,size.height*3/4-25))
	descrScrollView:setAnchorPoint(display.CENTER)
	view:addChild(descrScrollView,0)
	local lightCircle1 = display.newImageView(_res('ui/common/common_reward_light.png'),{ap = display.CENTER})
	lightCircle1:setPosition(cc.p(size.width/2,0))
	descrScrollView:addChild(lightCircle1)
	local delayAction = cc.DelayTime:create(1)
	lightCircle1:setOpacity(0)
	local callfun2 = function ()
		lightCircle1:stopAllActions()
		lightCircle1:runAction(cc.RepeatForever:create(cc.Spawn:create(cc.Sequence:create(cc.FadeTo:create(2.25,100),cc.FadeTo:create(2.25,255)), cc.RotateBy:create(4.5,180))))
	end
	local seqAction1 = cc.Sequence:create(delayAction ,cc.FadeIn:create(0.25),cc.CallFunc:create(callfun2))
	lightCircle1:runAction(seqAction1)
	local  count = #rewardsTable
	local delayNum =  count <=10 and count  or 10
	bgLayer:runAction(cc.Sequence:create(cc.DelayTime:create(0.5 + 0.12 * delayNum),cc.CallFunc:create(setBgLayerClick)))
	self:addChild(bgLayer)
	display.commonUIParams(ico_dish, {po = cc.p(size.width/2,size.height/2)})
	view:addChild(ico_dish,1)
	ico_dish:setAnimation(0, 'play', false)
	ico_dish:registerSpineEventHandler(spinecallBack, sp.EventType.ANIMATION_COMPLETE)

	local  count = #rewardsTable
	local width = 105
	local  Num  = 0
	if count > 5 then
		Num = 5
	else
		Num = count
	end
	if count > 5 then -- 大于五的时候采用的是GrideView
		local cellHight = 110
		local gradSize = cc.size(110 * 5   ,  120 * 2)
		local gridViewCellSize = cc.size(110, cellHight)
		local gridView = CGridView:create(gradSize)
		gridView:setSizeOfCell(gridViewCellSize)
		gridView:setAnchorPoint(display.CENTER)
		gridView:setColumns(5)
		gridView:setAutoRelocate(true)
		view:addChild(gridView, 2)
		gridView:setPosition(cc.p(size.width/2, size.height/2))
		gridView:setCountOfCell(count)
		gridView:setDataSourceAdapterScriptHandler(function ( cell,idx)
			local index = idx +1
			local pcell = cell
			local cellSize = gridViewCellSize
			xTry(function ()
				if index >=1  and index <= count then
					if not pcell then
						pcell = CGridViewCell:new()
						pcell:setContentSize(cellSize)
						if index <= 15 then
							local goodNode = createGoods(rewardsTable[index],0.05*index+1)
							pcell:addChild(goodNode)
							goodNode:setPosition(cc.p(gridViewCellSize.width/2 , cellSize.height/2 -150))
						else
							local data = rewardsTable[index]
							local goodNode = self:CreateGoodsNode({goodsId = data.goodsId, goodsNum = data.num, showAmount = true })
							display.commonUIParams(goodNode, {animate = false, cb = function (sender)
								self:ShowInformationTips(sender, data.goodsId, data.num)
							end})
							goodNode:setScale(0.8)
							goodNode:setVisible(true)
							goodNode:setPosition(cc.p(gridViewCellSize.height/2 , gridViewCellSize.width/2))
							pcell:addChild(goodNode)
						end
					else
						pcell:removeAllChildren()
						local data = rewardsTable[index]
						local goodNode = self:CreateGoodsNode({goodsId = data.goodsId, goodsNum = data.num, showAmount = true })
						display.commonUIParams(goodNode, {animate = false, cb = function (sender)
							self:ShowInformationTips(sender, data.goodsId, data.num)
						end})
						goodNode:setScale(0.8)
						goodNode:setPosition(cc.p(cellSize.height/2 , cellSize.width/2))
						pcell:addChild(goodNode)
					end
				end
			end
			, __G__TRACKBACK__)
			return pcell
		end)
		gridView:reloadData()
	else
		local goodsLayoutSize = cc.size(width* Num,120)
		local goodLayout = CLayout:create(goodsLayoutSize)
		goodLayout:setAnchorPoint(display.CENTER)
		goodLayout:setPosition(cc.p(size.width/2,size.height/2))

		for i = 1, count do
			local itemNode = createGoods(rewardsTable[i],0.05*i+1)
			itemNode:setPosition(cc.p(width*(i - 0.5),60 - 150))
			goodLayout:addChild(itemNode)
		end

		view:addChild(goodLayout,2)
	end

	self.closefunction = function ()
		if self.args.closeCallback then
			self.args.closeCallback()
		end
		ico_dish:setToSetupPose()
		self:runAction( cc.Sequence:create( cc.Hide:create(), cc.DelayTime:create(0.1),cc.Hide:create() ,cc.RemoveSelf:create()) )
	end
	-- 返回按钮
	if self.showConfirmBtn then
		local confirmBtn = display.newButton(size.width * 0.5 - 8, 40, {n = _res('ui/common/common_btn_orange.png'), cb = function(sender)
			PlayAudioByClickNormal()
			if self.isTouble then
				self.isTouble = false
				if self.closefunction then
					self.closefunction()
				end
			end
		end})
		view:addChild(confirmBtn, 10)
		display.commonLabelParams(confirmBtn, fontWithColor(14,{text = __('确定')}))
		confirmBtn:setVisible(false)
		confirmBtn:setOpacity(0)
		confirmBtn:runAction(cc.Sequence:create(
			cc.DelayTime:create(2),
			cc.Show:create(),
			cc.FadeIn:create(0.5)
		))
	end
	return {
		view = view,
		ico_dish = ico_dish
	}
end

function RewardPopup:CreateRewardCell(rewardsData)
	local rewardsAmount = table.nums(rewardsData)
	local rewardNumPerLine = 8
	local rewardNodeHeight = 75
	local cellBgSize = cc.size(567+20,rewardNodeHeight)
	local cellSize = cc.size(cellBgSize.width + 20, cellBgSize.height + 20)

	-- bg
	local rewardBg = display.newImageView(_res('ui/common/common_bg_list.png'), cellSize.width * 0.5-5, cellSize.height * 0.5,
		{scale9 = true, size = cellBgSize})

	-- cell
	local cell = display.newLayer(0, 0, {size = cellSize})
	-- local cell = CLayout:create(cellSize)
	-- cell:setAnchorPoint(cc.p(0.5,0))

	cell:addChild(rewardBg)
	-- rewards
	-- cell:setBackgroundColor(cc.c4b(255, 255, 255, 255))
	local goodNodeScale = 0.6
	local paddingX = 5

	for i,v in ipairs(rewardsData) do
		local goodNode = self:CreateGoodsNode({goodsId = v.goodsId, goodsNum = v.num, showAmount = true })
		display.commonUIParams(goodNode, {animate = false, cb = function (sender)
			self:ShowInformationTips(sender, v.goodsId)
		end})
		goodNode:setScale(goodNodeScale)
		display.commonUIParams(goodNode, {ap = cc.p(0.5, 0.5),
			po = cc.p((i-1)*paddingX + (i-0.5)*68+3,cellSize.height/2)})
		cell:addChild(goodNode, 5)
	end

	return cell

end

function RewardPopup:onCleanup()
	-- TODO 
	--- 升级引导需要处理

	if self.delayFuncList_ then
		if table.nums(self.delayFuncList_ ) > 0 then
			if type(self.delayFuncList_[1])  == "function" then
				self.delayFuncList_[1]()
				self.delayFuncList_ = nil  -- 防止多次调用
			end
		end
	end
	--local isHave = false
	--for k ,v in pairs(self.args.rewards) do
	--	if CommonUtils.GetGoodTypeById(v.goodsId) == GoodsType.TYPE_CARD_SKIN then
	--		isHave = true
	--		local callback =  nil
	--		if self.delayFuncList_ then
	--			if table.nums(self.delayFuncList_ ) > 0 then
	--				if type(self.delayFuncList_[1])  == "function" then
	--					callback = self.delayFuncList_[1]
	--				end
    --
	--			end
	--		end
	--		local  view  = require("common.CommonCardGoodsShareView").new({goodsId = v.goodsId , confirmCallback = callback })
	--		view:setPosition(display.center)
	--		uiMgr:GetCurrentScene():AddDialog(view)
	--		break
	--	end
	--end
	--if not  isHave then
	--	if self.delayFuncList_ then
	--		if table.nums(self.delayFuncList_ ) > 0 then
	--			if type(self.delayFuncList_[1])  == "function" then
	--				self.delayFuncList_[1]()
	--				self.delayFuncList_ = nil  -- 防止多次调用
	--			end
	--		end
	--	end
	--end
    if GuideUtils.GetDirector() then
        --恢复事件
        GuideUtils.GetDirector():TouchDisable(false)
    end
	if #self.activityChestData > 0 then
		app:DispatchObservers(ACTIVITY_CHEST_REWARD_EVENT , self.activityChestData )
	end
end

function RewardPopup:initRewardIcons()
	-- local size = self.bgLayer:getContentSize()
	-- local tempNum = 0

	-- for i,v in ipairs(self.args.rewards) do
	-- 	if type(v) == 'table' and next(v) ~= nil then
	-- 		tempNum = tempNum + 1
	-- 	end
	-- end

	-- local rewardsAmount = tempNum--table.nums(self.args.rewards)
	-- local perLine = math.min(rewardsAmount, 5)
	-- local lines = math.ceil(rewardsAmount / perLine)
	-- local scrollSize = cc.size(size.width - 10, size.height / 1.6 - 4)
	-- local containerSize = cc.size(scrollSize.width, math.max(scrollSize.height, scrollSize.height + (lines - 1) * (175)))

	-- local scrollView = CScrollView:create(scrollSize)
	-- scrollView:setDirection(eScrollViewDirectionVertical)
	-- scrollView:setContainerSize(containerSize)
	-- scrollView:setPosition(cc.p(size.width / 2, size.height / 2 + 60))
	-- self.bgLayer:addChild(scrollView, 20)--, self.bgImg:getLocalZOrder() + 1
	-- -- scrollView:getContainer():setBackgroundColor(cc.c4b(200, 200, 0, 100))
	-- scrollView:setContentOffset(cc.p(0, math.min(0, scrollSize.height - containerSize.height)))


	-- for i,v in ipairs(self.args.rewards) do
	-- 	if type(v) == 'table' and next(v) ~= nil then
	-- 		local function callBack(sender)
	-- 			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = checkint(v.id or v.goodsId or 900001), type = 1})
	-- 		end
	-- 		v.callBack = callBack
	-- 		v.showName = true
	-- 		local goodNode = require('common.GoodNode').new(v)
	-- 		local nodeSize = cc.size(goodNode:getContentSize().width + 15, goodNode:getContentSize().height + 55)
	-- 		local x = scrollSize.width / 2 + nodeSize.width * (-(perLine / 2) + (((i - 1) % perLine + 1) - 0.5))
	-- 		local y = (containerSize.height - scrollSize.height * 0.50) + nodeSize.height *  -(-(lines / 1) + (((math.ceil(i / perLine) - 1) % lines + 1) ))
	-- 		if lines >= 2 then
	-- 			y = (containerSize.height - scrollSize.height * 0.50)  - ((math.floor((i - 1) / perLine) + 1) - 1) * nodeSize.height --+ nodeSize.height * 0.5
	-- 		end
	-- 		goodNode:setPosition(cc.p(x, y))
	-- 		scrollView:getContainer():addChild(goodNode)
	-- 	end
	-- end
end
--[[
物品点击展示
--]]
function RewardPopup:ShowInformationTips( targetNode, iconId, num )
	if self.capsuleRewards then
		local goodsType = CommonUtils.GetGoodTypeById(checkint(iconId))
		if goodsType == GoodsType.TYPE_CARD or goodsType == GoodsType.TYPE_CARD_FRAGMENT then
			local capsuleCardView  = require( 'Game.views.drawCards.CapsuleCardViewNew' ).new({
				data = {goodsId = checkint(iconId), num = checkint(num)}, 
				skipAnimation = true,
			})
			capsuleCardView:setPosition(display.center)
			app.uiMgr:GetCurrentScene():AddDialog(capsuleCardView)
		else
			uiMgr:ShowInformationTipsBoard({targetNode = targetNode, iconId = iconId, type = 1})
		end
	else
		uiMgr:ShowInformationTipsBoard({targetNode = targetNode, iconId = iconId, type = 1})
	end
end
--[[
创建道具node
@params {
	goodsId    int  道具id
	goodsNum   int  道具数量
	showAmount bool 显示数量
}
--]]
function RewardPopup:CreateGoodsNode( params )
	local goodsId = checkint(params.goodsId)
	local goodsNum = checkint(params.goodsNum)
	local showAmount = params.showAmount == nil and true or params.showAmount
	local goodsType = CommonUtils.GetGoodTypeById(goodsId)
	local quality = CommonUtils.GetGoodsQuality(goodsId)
	local showRemindIcon = params.showRemindIcon == nil and true or params.showRemindIcon
	local highlight = 0
	if quality == 5 or quality == 7 or quality == 8 then
		highlight = 1
	end
	local goodsNode = nil 
	if self.capsuleRewards then
		if goodsType == GoodsType.TYPE_CARD then
			goodsNode = require('common.GoodNode').new({id = goodsId, amount = goodsNum, showAmount = showAmount, showRemindIcon = showRemindIcon, highlight = highlight})
		elseif goodsType == GoodsType.TYPE_CARD_FRAGMENT then
			goodsNode = require('common.GoodNode').new({id = goodsId, amount = goodsNum, showAmount = showAmount, highlight = highlight})
		else
			goodsNode = require('common.GoodNode').new({id = goodsId, amount = goodsNum, showAmount = showAmount })
		end
	else
		if GoodsType.TYPE_TTGAME_CARD == goodsType then
			local cardNode = TTGameUtils.GetBattleCardNode({cardId = goodsId, zoomModel = 's'})
			cardNode:setAnchorPoint(display.LEFT_BOTTOM)
			goodsNode = display.newButton(0, 0, {n = _res('ui/common/story_tranparent_bg.png'), scale9 = true, size = cardNode:getContentSize()})
			goodsNode:setCascadeOpacityEnabled(true)
			goodsNode:addChild(cardNode)
		else
			goodsNode = require('common.GoodNode').new({id = goodsId, amount = goodsNum, showAmount = showAmount })
		end
	end
	return goodsNode
end
return RewardPopup
