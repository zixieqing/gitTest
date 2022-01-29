---@class AnniversarySweepView
local AnniversarySweepView = class('home.AnniversarySweepView',function ()
	local node = display.newLayer(0, 0, { ap = display.CENTER , size = display.size})
	node.name = 'Game.views.AnniversarySweepView'
	node:enableNodeEvents()
	return node
end)
---@type AnniversaryManager
local anniversaryMgr = AppFacade.GetInstance():GetManager("AnniversaryManager")

---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local BUTTON_TAG = {
	ONETIME = 1 , -- 一次
	MUTI_TIMES = 2 -- 多次
}

--[[
主角技选择界面
@param table {
	isQuickSweep  是否为超级扫荡
	isCanQuickSweep 是否可以进行超级扫荡
	chapterType   章节类型
}
--]]
function AnniversarySweepView:ctor(param)
	self.isAction = false
	param = param or {}
	self.isQuickSweep = param.isQuickSweep
	self.isCanQuickSweep = param.isCanQuickSweep
	self.chapterType = param.chapterType
	local maxTimes = 1
	if param.isQuickSweep  then
		maxTimes = 10
	end
	self.maxTimes = maxTimes
	self.multiTimes = 1
	self:initUI()
	self:UpdateUI()
end

function AnniversarySweepView:initUI()
	local closeLayer = display.newLayer(display.cx, display.cy ,{ ap =  display.CENTER , size = display.size , color = cc.c4b(0,0,0,100 ) , enable  = true ,cb = function ()
		self:removeFromParent()
	end})
	self:addChild(closeLayer)
	local bgSize = cc.size(550 ,350)
	local bgLayout  = display.newLayer(display.cx, display.cy ,{ ap =  display.CENTER ,  size = bgSize})
	self:addChild(bgLayout)
	-- 吞噬层
	local swallowLayer = display.newLayer(bgSize.width/2 , bgSize.height/2 ,{ ap =  display.CENTER , size = bgSize , color =  cc.c4b(0,0,0,0 ), enable  = true })
	bgLayout:addChild(swallowLayer)
	-- 背景的图片
	local bgImage =  display.newImageView(_res("ui/common/common_bg_8.png"),bgSize.width/2 , bgSize.height/2 , {scale9 = true , size = bgSize})
	bgLayout:addChild(bgImage)
	closeLayer:setPosition(display.center)

	local sweepDescrLabel = display.newLabel(bgSize.width/2 , bgSize.height - 50 , fontWithColor(5,{ ap = display.CENTER_TOP , hAlign = display.TAC , w = 420}))
	bgLayout:addChild(sweepDescrLabel,2)
	local  oneTimesBtn = display.newButton(bgSize.width/ 2 - 90 , 70 ,
			{n = _res('ui/common/common_btn_big_orange')}
	)
	bgLayout:addChild(oneTimesBtn)
	oneTimesBtn:setScale(0.8)
	oneTimesBtn:setTag(BUTTON_TAG.ONETIME)
	local oneConsumeLabel = display.newRichLabel(bgSize.width /2 - 90 ,25 , {r = true , c = {
		fontWithColor('10', {text = ""})
	}
	})
	bgLayout:addChild(oneConsumeLabel)
	--- 普通扫荡显示
	local commonSweepSize = cc.size(bgSize.width , 100 )
	local commonSweepLayout = display.newLayer(bgSize.width/2 , bgSize.height/2- 20 , {ap = display.CENTER ,  size = commonSweepSize })
	local commonLabel = display.newLabel(commonSweepSize.width/2 , commonSweepSize.height * 3/4 , fontWithColor(8,  { fonntSize = 20 , text = app.anniversaryMgr:GetPoText(__('当前已通过的最高难度:'))}))
	commonSweepLayout:addChild(commonLabel)

	local hardBtn = display.newButton(commonSweepSize.width/2 , commonSweepSize.height /4, { n = app.anniversaryMgr:GetResPath('ui/anniversary/task/anni_task_label_grade.png') }  )
	commonSweepLayout:addChild(hardBtn)
	bgLayout:addChild(commonSweepLayout)
	commonSweepLayout:setVisible(false)
	-- 超级扫荡显示
	local quickSweepLabel =  display.newLabel(bgSize.width/2 , bgSize.height/2 - 50 , fontWithColor(10, { w = 420 ,  text = ''}))
	bgLayout:addChild(quickSweepLabel)
	quickSweepLabel:setVisible(false)

	-- 普通挑战
	local  mutiTimesBtn = display.newButton(bgSize.width/ 2 + 90 , 70 ,
			{n = _res('ui/common/common_btn_big_orange')}
	)
	mutiTimesBtn:setScale(0.8)
	bgLayout:addChild(mutiTimesBtn)
	mutiTimesBtn:setTag(BUTTON_TAG.MUTI_TIMES)
	local mutliConsumeLabel = display.newRichLabel(bgSize.width /2 + 90 ,25 , { r = true ,
																				c = {
																					fontWithColor('10', {text = ""})
																				}
	})
	bgLayout:addChild(mutliConsumeLabel)
	self.viewData = {
		oneConsumeLabel   = oneConsumeLabel,
		mutliConsumeLabel = mutliConsumeLabel,
		mutiTimesBtn      = mutiTimesBtn,
		oneTimesBtn       = oneTimesBtn,
		commonLabel       = commonLabel,
		commonSweepLayout  = commonSweepLayout ,
		quickSweepLabel  = quickSweepLabel ,
		sweepDescrLabel  = sweepDescrLabel ,
		hardBtn  = hardBtn ,
	}
end

function AnniversarySweepView:UpdateUI()
	local bgWidth =  550
	local viewData          = self.viewData
	local oneConsumeLabel   = viewData.oneConsumeLabel
	local mutiTimesBtn      = viewData.mutiTimesBtn
	local oneTimesBtn       = viewData.oneTimesBtn
	local mutliConsumeLabel = viewData.mutliConsumeLabel
	local commonLabel = viewData.commonLabel
	local commonSweepLayout = viewData.commonSweepLayout
	local hardBtn = viewData.hardBtn
	local quickSweepLabel   = viewData.quickSweepLabel
	local sweepDescrLabel   = viewData.sweepDescrLabel
	local chapterType       = self.chapterType
	local parserConfig      = anniversaryMgr:GetConfigParse()
	local chapterConf       = anniversaryMgr:GetConfigDataByName(parserConfig.TYPE.CHAPTER)
	local homeData          = app.anniversaryMgr:GetHomeData()
	local chapters          = homeData.chapters
	local chapterId           = chapters[tostring(chapterType)] or 11
	local consumeData = chapterConf[tostring(chapterId)].consume[1]
	if not  self.isQuickSweep then
		mutiTimesBtn:setVisible(false)
		quickSweepLabel:setVisible(false)
		mutliConsumeLabel:setVisible(false)
		commonSweepLayout:setVisible(true)
		oneTimesBtn:setPositionX(bgWidth/2)
		oneConsumeLabel:setPositionX(bgWidth/2)
		local chapterSort = app.anniversaryMgr:GetChapterSortByChapterIdChapterType(chapterId , chapterType)
		local text = string.fmt(app.anniversaryMgr:GetPoText(__('困难_num_')) , { _num_ =  chapterSort })
		display.commonLabelParams(hardBtn , fontWithColor(14 , {color = "#76553b" , outline = false , text = text }))
		display.commonLabelParams(commonLabel , fontWithColor(6 , {fontSize = 20 , text = app.anniversaryMgr:GetPoText(__('当前已通过的最高难度:')) }))
		display.commonLabelParams(sweepDescrLabel , { text = app.anniversaryMgr:GetPoText(__('快速挑战仅能挑战已通过的最高难度关卡，仅会获得通关收益'))})
	else
		commonSweepLayout:setVisible(false)
		display.commonLabelParams(sweepDescrLabel , { text = app.anniversaryMgr:GetPoText(__('全部支线关卡难度20通关可解锁快速游玩，快速游玩仅能获得难度20时关卡的通关奖励。'))})
		sweepDescrLabel:setVisible(true)
		if self.isCanQuickSweep then
			quickSweepLabel:setVisible(false)
		else
			quickSweepLabel:setVisible(true)
			display.commonLabelParams(quickSweepLabel , {text = app.anniversaryMgr:GetPoText(__('当前还有支线关卡未通关难度20')) })
			-- 不能进行超级扫荡的时候显示为灰色
			oneTimesBtn:setNormalImage(_res('ui/common/common_btn_orange_disable'))
			oneTimesBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable'))
			oneTimesBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable'))
			mutiTimesBtn:setNormalImage(_res('ui/common/common_btn_orange_disable'))
			mutiTimesBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable'))
		end
	end
	local num =  consumeData.num
	local goodsId =  consumeData.goodsId
	local owner = CommonUtils.GetCacheProductNum(goodsId)
	if math.floor(owner / num) > 1  then
		self.multiTimes = owner / num
		self.multiTimes = self.multiTimes > self.maxTimes and self.maxTimes or self.multiTimes
	else
		self.multiTimes = self.maxTimes
	end
	display.commonLabelParams(oneTimesBtn , fontWithColor('14' , {fontSize = 26 ,  text = string.fmt(app.anniversaryMgr:GetPoText(__('挑战_num_次')), {_num_ = 1 } )}))
	display.commonLabelParams(mutiTimesBtn , fontWithColor('14' , { fontSize = 26 ,  text = string.fmt(app.anniversaryMgr:GetPoText(__('挑战_num_次')), {_num_ = self.multiTimes  } ) }))
	display.reloadRichLabel(oneConsumeLabel , { c= {
		fontWithColor('6', {text = string.fmt(app.anniversaryMgr:GetPoText(__('消耗_num_')) , { _num_ = num }) }),
		{ img = CommonUtils.GetGoodsIconPathById(goodsId) , scale = 0.2 }
	}})
	display.reloadRichLabel(mutliConsumeLabel , { c= {
		fontWithColor('6', {text = string.fmt(app.anniversaryMgr:GetPoText(__('消耗_num_')) , { _num_ = num * self.multiTimes }) }),
		{ img = CommonUtils.GetGoodsIconPathById(goodsId) , scale = 0.2 }
	}})
	local callfunc = function(sender)
		if self.isQuickSweep and (not self.isCanQuickSweep) then
			app.uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('请先通关全部支线难度关卡')))
			return
		end
		local sweepType   = sender:getTag()
		local times = sweepType == BUTTON_TAG.ONETIME and 1 or self.multiTimes
		local ownNum = CommonUtils.GetCacheProductNum(goodsId)
		if ownNum  >= ( times *  num) then
			AppFacade.GetInstance():DispatchSignal(POST.ANNIVERSARY_SWEEP_BRANCH_CHAPTER.cmdName , { times =  times  } )
		else
			uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__("道具不足")))
		end
	end
	oneTimesBtn:setOnClickScriptHandler(callfunc)
	mutiTimesBtn:setOnClickScriptHandler(callfunc)
end

function AnniversarySweepView:RefreshSweepTimesUI()
	self:UpdateUI()
end
function AnniversarySweepView:SweepCallBack(signal)
	local responseData = signal:GetBody()
	local rewards = responseData.rewards
	local requestData = responseData.requestData
	local times = requestData.times or 1
	local chapterType       = self.chapterType
	local parserConfig      = anniversaryMgr:GetConfigParse()
	local chapterConf       = anniversaryMgr:GetConfigDataByName(parserConfig.TYPE.CHAPTER)
	local homeData          = app.anniversaryMgr:GetHomeData()
	local chapters          = homeData.chapters
	local chapterId           = chapters[tostring(chapterType)]
	local consumeData = clone(chapterConf[tostring(chapterId)].consume)
	consumeData[1].num = - consumeData[1].num * times
	-- 先扣除道具 然后添加道具
	CommonUtils.DrawRewards(consumeData)
	anniversaryMgr.homeData.challengePoint = checkint(anniversaryMgr.homeData.challengePoint ) +  checkint(chapterConf[tostring(chapterId)].score) * times
	rewards[#rewards+1] = {
		num = checkint(chapterConf[tostring(chapterId)].score) * times   ,
		goodsId = app.anniversaryMgr:GetAnniversaryScoreId()
	}
	uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
	if not self.isQuickSweep then
		app.anniversaryMgr:SetHomeDataByKeyalue("chapterType" , 0 )
		app.anniversaryMgr:SetHomeDataByKeyalue("branchRefresh" , nil )
		self:stopAllActions()
		self:removeFromParent()
		local mediator = app:RetrieveMediator("BattleScriptTeamMediator")
		if mediator then -- 如果存在就要删除战队编辑界面
			app:UnRegsitMediator("BattleScriptTeamMediator")
		end
		mediator = AppFacade.GetInstance():RetrieveMediator("AnniversaryTeamMediator")
		if mediator then
			AppFacade.GetInstance():UnRegsitMediator("AnniversaryTeamMediator")
		end
	end
end
function AnniversarySweepView:onEnter()
	regPost(POST.ANNIVERSARY_SWEEP_BRANCH_CHAPTER)
	AppFacade.GetInstance():RegistObserver(SGL.REFRESH_NOT_CLOSE_GOODS_EVENT, mvc.Observer.new(self.RefreshSweepTimesUI , self) )
	AppFacade.GetInstance():RegistObserver(POST.ANNIVERSARY_SWEEP_BRANCH_CHAPTER.sglName, mvc.Observer.new(self.SweepCallBack , self) )
end

function AnniversarySweepView:UnregistSignal()
	AppFacade.GetInstance():UnRegistObserver(SGL.REFRESH_NOT_CLOSE_GOODS_EVENT , self)
	AppFacade.GetInstance():UnRegistObserver(POST.ANNIVERSARY_SWEEP_BRANCH_CHAPTER.sglName , self)
	unregPost(POST.ANNIVERSARY_SWEEP_BRANCH_CHAPTER)
end

function AnniversarySweepView:onCleanup()
	self:UnregistSignal()
end

return AnniversarySweepView
