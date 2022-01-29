--[[
扫荡奖励弹窗
@params rewardsData table
--]]
--local CommonDialog = require('common.CommonDialog')
local SweepRewardPopup = class('SweepRewardPopup' ,function ()
	local node = CLayout:create( display.size )
	node.name = 'Game.views.BindingTellNumberView'
	node:enableNodeEvents()
	return node
end)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local MaxLength = 10
--[[
override
initui
--]]
function SweepRewardPopup:ctor (...)
	self.args = unpack({...})

	if self.args.name then
		self.name = self.args.name
	end
	self.closefunction =  false
	self.isNeedCloseLayer = true
	if self.args.isNeedCloseLayer == false then
		self.isNeedCloseLayer = self.args.isNeedCloseLayergit
	end
	self.executeAction = self.args.executeAction
	self.delayFuncList_ = self.args.delayFuncList_
	self.passTicketPoint = checkint(self.args.passTicketPoint)
	--if self.args.tag then
	--	self:setTag(checkint(self.args.tag))
	--end
	self:InitialUI()
end
function SweepRewardPopup:InitialUI()

	self.rewardsData = self.args.rewardsData
	self.closefunction  =  nil
	local swallowLayer = display.newLayer(display.cx, display.cy , { size = display.size , color = cc.c4b(0,0,0,100) , ap = display.CENTER, enable = true , cb = function ()
		if self.closefunction then
			if self.delayFuncList_ then
				if table.nums(self.delayFuncList_ ) > 0 then
					if type(self.delayFuncList_[1])  == "function" then
						self.delayFuncList_[1]()
						self.delayFuncList_ = nil  -- 防止多次调用
					end
				end
			end
			self:removeFromParent()
		end
	end})
	self:addChild(swallowLayer)
	local size = cc.size(586, 550)
	local view = display.newLayer(0, 0, {size = size, ap = cc.p(0.5, 0.5) ,enable = true  })
	local swallViewTwo = display.newLayer(size.width/2, size.height/2, {size = size, ap = cc.p(0.5, 0.5),color = cc.c4b(0,0,0,0) ,enable = true  })
	view:addChild(swallViewTwo)
	local listSize = cc.size(size.width, size.height -20 )
	local rewardList = CListView:create(listSize)
	rewardList:setDirection(eScrollViewDirectionVertical)
	rewardList:setAnchorPoint(cc.p(0.5, 1))
	rewardList:setPosition(cc.p(size.width/2 , size.height -10 ))
	view:addChild(rewardList, 9)
	view:setPosition(display.cx , display.cy - 30)
	self:addChild(view)
	self.rewardList = rewardList

	-- 创建奖励cell
	local rewardsData = nil



	local spinecallBack = function ()
		-- body

	end
	local qAvatar = sp.SkeletonAnimation:create(
	'effects/rewardgoods/skeleton2.json',
	'effects/rewardgoods/skeleton2.atlas',
	1
	)
	--qAvatar:update(0)
	--
	--qAvatar:update(0)
	qAvatar:setTag(888)
	qAvatar:setAnimation(0, 'play', false)
	qAvatar:registerSpineEventHandler(spinecallBack, sp.EventType.ANIMATION_COMPLETE)
	view:addChild(qAvatar)
	qAvatar:setPosition(cc.p(size.width/2 ,size.height/2))
	local rewardImage = display.newImageView(_res('ui/common/common_words_congratulations.png'),display.cx, display.height+60)
	local height = 20
	local rewardPoint_Srtart =  cc.p(display.cx ,  display.height+94.6 + height)
	local rewardPoint_one = cc.p(display.cx ,  display.cy+300-35.5+height)
	local rewardPoint_Two = cc.p(display.cx ,  display.cy+300+24 +height)
	local rewardPoint_Three = cc.p(display.cx ,  display.cy+300-15 +height)
	local rewardPoint_Four = cc.p(display.cx ,  display.cy+300-15 + height)
	local rewardSequnece = cc.Sequence:create(    -- 获取队列的动画展示
	cc.DelayTime:create(0.3) ,cc.CallFunc:create(function ( )
		PlayAudioClip(AUDIOS.UI.ui_mission.id)
		rewardImage:setVisible(true)
		rewardImage:setOpacity(0)
		rewardImage:setPosition(rewardPoint_Srtart)
	end),
	cc.Spawn:create(cc.FadeIn:create(0.2),cc.MoveTo:create(0.2,rewardPoint_one)),
	cc.JumpTo:create(0.1,rewardPoint_Two,10,1) ,
	cc.MoveTo:create(0.1,rewardPoint_Three) ,
	cc.MoveTo:create(0.1,rewardPoint_Four)
	)
	self:addChild(rewardImage,2)
	rewardImage:runAction(rewardSequnece)
	for i = 1, table.nums(self.rewardsData.sweep) do
		rewardsData = self.rewardsData.sweep[tostring(i)]
		local cell = self:CreateRewardCell(i, rewardsData.gold, rewardsData.mainExp, rewardsData.rewards, self.passTicketPoint)
		local node = cell:getChildByTag(111)
		node:setOpacity(0)
		node:setScaleY(0)
		rewardList:insertNodeAtLast(cell)

	end

	self.viewData ={
		rewardList = rewardList
	}

	self:RunActionSeq()
end

function SweepRewardPopup:RunActionSeq()
	local rewardList = self.rewardList
	rewardList:reloadData()
	local nodes = rewardList:getNodes()
	local delayTime = 0.4
	for i =1 , #nodes do
		local 	node =  nodes[i]:getChildByTag(111)
		node:runAction(cc.Sequence:create(
				cc.DelayTime:create(delayTime + 0.1* (i -1)) ,
				cc.Spawn:create(
					cc.FadeIn:create(0.15) ,
					cc.ScaleTo:create(0.15,1,1)
				),
				cc.CallFunc:create(
				function ()
					self.closefunction = true
				end
				)
			)
		)
	end
end
--[[
创建奖励cell
@params index int 序号
@params gold int 金币
@params exp int 经验
@params rewardsData table 奖励集
@return cell cc.Node 奖励cell
--]]


function SweepRewardPopup:CreateRewardCell(index, gold, exp, rewardsData, passTicketPoint)
	local rewardsAmount = table.nums(rewardsData)
	local rewardNumPerLine = 8
	local rewardNodeHeight = 75
	local cellBgSize = cc.size(567, 111 + rewardNodeHeight * (math.ceil(rewardsAmount / rewardNumPerLine) - 1))
	local cellSize = cc.size(cellBgSize.width + 20, cellBgSize.height+5 )

	-- bg
	local rewardBg = display.newImageView(_res('ui/common/sweep_bg.png'), cellSize.width * 0.5, cellSize.height * 0.5,
		{scale9 = true, size = cellBgSize})

	-- cell
	local cell = display.newLayer(0, 0, {size = cellSize}) 
	cell:addChild(rewardBg)

	-- title
	local titleBg =CLayout:create(cc.size(161,28))
	display.commonUIParams(titleBg, {ap = cc.p(0, 1), po = cc.p(1, cellBgSize.height - 1)})
	rewardBg:addChild(titleBg)

	local title = display.newLabel(10 , titleBg:getContentSize().height * 0.5 -5,
		fontWithColor(8,{color = "#ffffff", ap = display.LEFT_CENTER, text = string.format(__('第%s次扫荡'), CommonUtils.GetChineseNumber(index)),}))
	titleBg:addChild(title)

	
	-- pass ticket point
	local scale = 0.18
	local width = 30
	local height  =5
	if passTicketPoint > 0 then
		local passTicketIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(PASS_TICKET_ID)), 0, 0)
		passTicketIcon:setScale(scale)
		display.commonUIParams(passTicketIcon, {po = cc.p(cellBgSize.width * 0.385 + width, cellBgSize.height - passTicketIcon:getContentSize().height * scale * 0.5 - 1 -height )  })
		rewardBg:addChild(passTicketIcon)

		local passTicketLabel = display.newLabel(
			passTicketIcon:getPositionX() + passTicketIcon:getContentSize().width * scale * 0.5 + 2 ,
			passTicketIcon:getPositionY() - 1 ,
			fontWithColor(8,{color = "#ffffff",text = string.format('+%s', tostring(passTicketPoint)),ap = cc.p(0, 0.5)}))
		rewardBg:addChild(passTicketLabel)
	end
	-- gold
	local goldIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(GOLD_ID)), 0, 0)
	goldIcon:setScale(scale)
	display.commonUIParams(goldIcon, {po = cc.p(cellBgSize.width * 0.585 + width, cellBgSize.height - goldIcon:getContentSize().height * scale * 0.5 - 1 -height )  })
	rewardBg:addChild(goldIcon)

	local goldLabel = display.newLabel(
		goldIcon:getPositionX() + goldIcon:getContentSize().width * scale * 0.5 + 2 ,
		goldIcon:getPositionY() - 1 ,
		fontWithColor(8,{color = "#ffffff",text = string.format('+%s', tostring(gold)),ap = cc.p(0, 0.5)}))
	rewardBg:addChild(goldLabel)

	if nil == gold or 0 == checkint(gold) then
		goldIcon:setVisible(false)
		goldLabel:setVisible(false)
	else
		goldIcon:setVisible(true)
		goldLabel:setVisible(true)
	end

	-- exp
	local expIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(EXP_ID)), 0, 0)
	expIcon:setScale(scale)
	display.commonUIParams(expIcon, {po = cc.p(cellBgSize.width * 0.815  + width , cellBgSize.height - expIcon:getContentSize().height * scale * 0.5 - 1 - height)})
	rewardBg:addChild(expIcon)

	local expLabel = display.newLabel(
		expIcon:getPositionX() + expIcon:getContentSize().width * scale * 0.5 + 2 ,
		expIcon:getPositionY() - 1,
		fontWithColor(8,{color = "#ffffff" ,text = string.format('+%s', tostring(exp)), ap = cc.p(0, 0.5)}))
	rewardBg:addChild(expLabel)

	if nil == exp or 0 == checkint(exp) then
		expIcon:setVisible(false)
		expLabel:setVisible(false)
	else
		expIcon:setVisible(true)
		expLabel:setVisible(true)
	end

	-- rewards
	local goodNodeScale = 0.6
	local paddingX = 5
	for i,v in ipairs(rewardsData) do
		local goodNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true})
		display.commonUIParams(goodNode, {animate = false, cb = function (sender)
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
		end})
		goodNode:setScale(goodNodeScale)
		display.commonUIParams(goodNode, {ap = cc.p(0.5, 1),
			po = cc.p(paddingX + (cellBgSize.width - paddingX * 2) / (rewardNumPerLine) * ((i - 1) % rewardNumPerLine + 0.5) + (cellSize.width - cellBgSize.width) * 0.5,
				cellBgSize.height - 25 - ((math.ceil(i / rewardNumPerLine) - 1)) * rewardNodeHeight -12)})
		cell:addChild(goodNode, 5)
	end
	cell:setTag(111)
	cell:setAnchorPoint(display.CENTER)
	cell:setPosition(cc.p(cellSize.width/2 ,cellSize.height/2))
	local cellParent = display.newLayer(cellSize.width/2 ,cellSize.height/2 ,{ap = display.CENTER , size = cellSize})
	cellParent:addChild(cell)

	return cellParent

end


return SweepRewardPopup
