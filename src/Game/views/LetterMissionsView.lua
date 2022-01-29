--[[
支线任务弹窗
--]]
local CommonDialog = require('common.CommonDialog')
local LetterMissionsView = class('LetterMissionsView', CommonDialog)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

--[[
override
initui
--]]
function LetterMissionsView:InitialUI()
	self.data = {}
	local function CreateView()
		-- bg
		local bg = display.newImageView(_res('ui/home/story/gut_task_bg_mail_1.png'), 0, 0)
		local bgSize =  cc.size(627,680)  --bg:getContentSize()

		-- bg view
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(bgSize.width*0.5,bgSize.height),ap = cc.p(0.5, 1)})
		view:addChild(bg,1)




		local bg1 = display.newImageView(_res('ui/home/story/gut_task_bg_mail_2.png'), 0, 0)
		display.commonUIParams(bg1, {po = cc.p(bgSize.width*0.5,bgSize.height - bg:getContentSize().height + 10),ap = cc.p(0.5, 1)})
		view:addChild(bg1)


		local messView = display.newLayer(bgSize.width* 0.5, bgSize.height* 0.5, {size = bgSize, ap = cc.p(0.5, 0.5)})
		view:addChild(messView,1)


		--用户名昵称
		local myNameLabel = display.newLabel(88,bgSize.height - 100,
			fontWithColor(6,{text = 'Dear 阿西吧呀君:',  ap = cc.p(0, 1)}))
		messView:addChild(myNameLabel,1)

		local line = display.newImageView(_res('ui/common/gut_task_line.png'), bgSize.width * 0.5, myNameLabel:getPositionY() - 28,
		{ap = cc.p(0.5, 1)})
		messView:addChild(line)
		--任务描述
		local desLabel = display.newLabel(bgSize.width * 0.5,line:getPositionY() - 20,
			fontWithColor(6,{text = '',  ap = cc.p(0.5, 1),w = bgSize.width - 200,h = 200}))
		messView:addChild(desLabel)

		local tempLabel = display.newLabel(bgSize.width - 180,340,
			fontWithColor(6,{text = ' ', ap = cc.p(1, 0)}))
		messView:addChild(tempLabel,1)

		--npc名字
		local npcLabel = display.newLabel(tempLabel:getPositionX(),340,
			fontWithColor(6,{text = '',ap = cc.p(0, 0)}))
		messView:addChild(npcLabel,1)

		local tempBtn = display.newButton(0, 0, {n = _res('ui/common/common_title_3.png')})
		display.commonUIParams(tempBtn, {ap = cc.p(0.5,0.5), po = cc.p(320,285)})
		display.commonLabelParams(tempBtn, fontWithColor(6,{text = __('奖励')}))
		messView:addChild(tempBtn,1)

		--奖励layout
		local rewardsLayout = CLayout:create(cc.size(320,100))
		rewardsLayout:setAnchorPoint(cc.p(0.5,0))
		rewardsLayout:setPosition(cc.p(bgSize.width * 0.5,167))
		messView:addChild(rewardsLayout,1)
		

		--前往button
		local goBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
		display.commonUIParams(goBtn, {ap = cc.p(0.5,0), po = cc.p(bgSize.width * 0.5 + 100,100)})
		display.commonLabelParams(goBtn, fontWithColor(14,{text = __('前往')}))
		goBtn:setTag(1)
		messView:addChild(goBtn,1)

		--以后再说button
		local cancelBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
		display.commonUIParams(cancelBtn, {ap = cc.p(0.5,0), po = cc.p(bgSize.width * 0.5 - 120,100)})
		display.commonLabelParams(cancelBtn, fontWithColor(14,{text = __('以后再说')}))
		cancelBtn:setTag(2)
		messView:addChild(cancelBtn,1)


		local mainExpLabel = display.newLabel(420,285,
			fontWithColor(6,{text = '', color = 'cb4c49', ap = cc.p(0, 0.5)}))
		messView:addChild(mainExpLabel, 6)


	 	-- q版图标
		local qIcon = display.newImageView(_res('ui/common/common_ico_cartoon_5.png'), 80,-20, {ap = cc.p(1, 0)})
		messView:addChild(qIcon, 5)

		return {
			view = view,
			myNameLabel = myNameLabel,
			desLabel = desLabel,
			npcLabel = npcLabel,
			rewardsLayout = rewardsLayout,
			goBtn		= goBtn,
			cancelBtn	= cancelBtn,
			bg1 = bg1,
			messView = messView,
			qIcon = qIcon,
			line = line,
			mainExpLabel = mainExpLabel,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)


	self.viewData.bg1:setScaleY(0)
	for i=1,10 do
		self.viewData.bg1:runAction(cc.Sequence:create(cc.DelayTime:create(i*0.03),cc.CallFunc:create(function ()
				self.viewData.bg1:setScaleY(i*0.1)
			end)))	
	end
	self.viewData.messView:setOpacity(0)
	self.viewData.messView:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.FadeIn:create(0.4)))


	self.viewData.rewardsLayout:removeAllChildren()
	self.viewData.rewardsLayout:setContentSize(cc.size(3*110,100))

	for i=1,3 do
		local function callBack(sender)
			AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = 900001, type = 1})
		end

		local goodsNode = require('common.GoodNode').new({id = 900001, amount = 1000, showAmount = false,callBack = callBack})
		goodsNode:setAnchorPoint(cc.p(0.5,0.5))
		goodsNode:setPosition(cc.p(50+105*(i-1),self.viewData.rewardsLayout:getContentSize().height*0.5 - 10))
		goodsNode:setScale(0.75)
		self.viewData.rewardsLayout:addChild(goodsNode, 5)
		goodsNode:setOpacity(0)
		goodsNode:runAction(cc.Sequence:create(
			cc.DelayTime:create(0.5+ i*(0.1)),
			cc.Spawn:create(
				cc.FadeIn:create(0.1),
				cc.MoveTo:create(0.1,cc.p(50+105*(i-1),self.viewData.rewardsLayout:getContentSize().height*0.5+10))
				),
			cc.MoveTo:create(0.1,cc.p(50+105*(i-1),self.viewData.rewardsLayout:getContentSize().height*0.5))
			))
	end

	self.viewData.goBtn:setScale(0.1)
	self.viewData.cancelBtn:setScale(0.1)
	
	self.viewData.goBtn:runAction(cc.Sequence:create(
		cc.DelayTime:create(0.8),
		cc.ScaleTo:create(0.3,1)
		))
	self.viewData.cancelBtn:runAction(cc.Sequence:create(
		cc.DelayTime:create(0.8),
		cc.ScaleTo:create(0.3,1)
		))


	self.viewData.qIcon:setOpacity(0)
	self.viewData.qIcon:runAction(cc.Sequence:create(
		cc.DelayTime:create(0.5),
		cc.Spawn:create(
			cc.FadeIn:create(0.1),
			cc.MoveTo:create(0.1,cc.p(120,70))
		)
		))


	self.viewData.line:setScale(0.1)
	self.viewData.line:runAction(cc.Sequence:create(
		cc.DelayTime:create(0.6),
		cc.ScaleTo:create(0.2,1)
		))

	self.viewData.goBtn:setOnClickScriptHandler(handler(self,self.ButtonActions))
	self.viewData.cancelBtn:setOnClickScriptHandler(handler(self,self.ButtonActions))



end

function LetterMissionsView:UpdataUi(data)
	if data then
		self.data = {}
		self.data = data
		local myNameLabel = self.viewData.myNameLabel
		local desLabel = self.viewData.desLabel
		local npcLabel = self.viewData.npcLabel
		local rewardsLayout = self.viewData.rewardsLayout
		local goBtn		= self.viewData.goBtn
		local cancelBtn	= self.viewData.cancelBtn
		
		local mainExpLabel	= self.viewData.mainExpLabel
		mainExpLabel:setString(string.fmt(__('主角经验+__num__'),{__num__ = data.mainExp}))
		myNameLabel:setString('Dear '..gameMgr:GetUserInfo().playerName)
		npcLabel:setString(CommonUtils.GetConfig('quest', 'role', data.roleId).roleName)
		desLabel:setString(tostring(data.descr))
		if data.rewards then
			rewardsLayout:removeAllChildren()
		 	rewardsLayout:setContentSize(cc.size(table.nums(data.rewards)*110,100))
			for i,v in ipairs(data.rewards) do
				local function callBack(sender)
					AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
				end

				local goodsNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true,callBack = callBack})
				goodsNode:setAnchorPoint(cc.p(0.5,0.5))
				goodsNode:setPosition(cc.p(50+105*(i-1),rewardsLayout:getContentSize().height*0.5))
				goodsNode:setScale(0.75)
				rewardsLayout:addChild(goodsNode, 5)
			end
		end
	end
end

---------------------------------------------------
-- touch logic begin --
---------------------------------------------------
--[[
点击回调
--]]
function LetterMissionsView:ButtonActions(sender)
	local tag = sender:getTag()
	dump(self.data)
	if tag == 1 then--前往
		local taskType = self.data.taskType
		if taskType == 1 then
			-- 在大堂招待_target_num_位客人
			AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'RecipeResearchAndMakingMediator'})--,{isBack = true}		
		elseif taskType == 2 then
			-- 在消灭_target_num_只_target_id_
			-- self:GetFacade():UnRegsitMediator("StoryMissionsMediator")	
			AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'MapMediator'})--,{isBack = true}	
			
		elseif taskType == 3 then	
			--完成_target_id_地区的_target_num_个外卖订单	
			-- AppFacade:GetInstance():UnRegsitMediator("StoryMissionsMediator")
			self:runAction(cc.RemoveSelf:create())
		elseif taskType == 4 then	
			--通过关卡_target_id_
			AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'MapMediator'})
		elseif taskType == 5 then	
			--完成_target_num_个公众外卖订单
			-- AppFacade:GetInstance():UnRegsitMediator("StoryMissionsMediator")
			self:runAction(cc.RemoveSelf:create())
		elseif taskType == 6 then	
			--消灭在_target_id_中盘踞着的_target_id_
			AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'MapMediator'})
		elseif taskType == 7 then	
			AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'MapMediator'})
		elseif taskType == 8 then	
			--与_target_id_的_target_id_对话

			AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.REFRESH_HOMEMAP_STORY_LAYER)
		elseif taskType == 9 then 
			AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.REFRESH_HOMEMAP_STORY_LAYER)

		elseif taskType == 10 then
			self:runAction(cc.RemoveSelf:create())
		elseif taskType == 11 then	
			self:runAction(cc.RemoveSelf:create())
		elseif data.taskType == 12 then
			AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'MapMediator'})
		elseif data.taskType == 13 then	
			--击败_target_id_
			AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'MapMediator'})
		elseif data.taskType == 14 then	
			--挑战_target_id_	
			AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'MapMediator'})
		end	
		self:runAction(cc.RemoveSelf:create())
	elseif tag == 2 then---以后再说
		self:runAction(cc.RemoveSelf:create())
	end
end
---------------------------------------------------
-- touch logic end --
---------------------------------------------------

return LetterMissionsView
