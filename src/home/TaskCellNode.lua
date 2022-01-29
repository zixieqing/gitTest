local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local TaskCellNode = class('TaskCellNode', function ()
	local node = CLayout:create()
	return node
end)

local RES_DIR = {
	BG_LIST            = _res('ui/common/common_bg_list.png'),
	BG_LIST_VIP        =  _res('ui/common/common_bg_list_vip.png'),
	BG_TITLE           =  _res('ui/home/task/task_bg_title.png'),
	BG_TITLE_VIP       =  _res('ui/home/task/task_bg_title_vip.png'),
	ICO_ACTIVE_POINT   =  _res('ui/home/task/task_ico_active_point.png'),
	ICO_EXP            =  _res('ui/common/common_ico_exp.png'),
	BG_FONT_NAME       =  _res('ui/common/common_bg_font_name.png'),
	IMG_SHUIBOWEN      =  _res('ui/home/task/task_img_shuibowen.png'),
	MIFAN_BY_ICO       = _res('ui/common/activity_mifan_by_ico.png'),
    BTN_ORANGE         = _res('ui/common/common_btn_orange.png'),
    BTN_ORANGE_DISABLE = _res('ui/common/common_btn_orange_disable.png'),
}


local function CreateView(size)
	local view = CLayout:create(size)
	local bg = display.newImageView(RES_DIR.BG_LIST, size.width * 0.5, size.height * 0.5,{scale9 = true,size = cc.size(size.width - 20,size.height - 10)})--
	view:addChild(bg)

	local bgVip = display.newImageView(RES_DIR.BG_LIST_VIP, size.width * 0.5, size.height * 0.5,{scale9 = true,size = cc.size(size.width - 20,size.height - 10)})--
	view:addChild(bgVip)
	bgVip:setVisible(false)
	local titleBgSize = cc.size(329, 55)
	if size.height >150  then
		titleBgSize = cc.size(329, 74)
	end
	local titleBg = display.newNSprite(RES_DIR.BG_TITLE, 0, 0, {ap = cc.p(0, 0.5) , scale9 = true , size = titleBgSize})
	view:addChild(titleBg)
	display.commonUIParams(titleBg, {po = cc.p(10, size.height - titleBg:getContentSize().height * 0.5 - 10)})
	local titleLabel = display.newLabel(titleBg:getPositionX() + 20, titleBg:getPositionY(),
	fontWithColor(4,{text = '', ap = cc.p(0, 0.5), hAlign = display.TAL}))
	view:addChild(titleLabel)

	--titleBg:getPositionX() + titleBg:getContentSize().width + 2
	local activePointLabel = display.newLabel(titleBg:getContentSize().width * 0.8, titleBg:getPositionY(),
		fontWithColor(10,{text = '', ap = cc.p(1, 0.5), hAlign = display.TAL}))
	view:addChild(activePointLabel)
	activePointLabel:setVisible(false)

	local icoActive = display.newImageView(RES_DIR.ICO_ACTIVE_POINT,activePointLabel:getPositionX() + 26,titleBg:getPositionY() + 5)	
	icoActive:setAnchorPoint(cc.p(0,0.5))
	view:addChild(icoActive)
	icoActive:setVisible(false)


	local expImg = display.newImageView(RES_DIR.ICO_EXP,titleBg:getPositionX() + titleBg:getContentSize().width - 20,titleBg:getPositionY())    
	expImg:setAnchorPoint(cc.p(0,0.5))
	expImg:setScale(0.2)
	view:addChild(expImg)


	local expBtn = display.newButton(0, 0, {n = RES_DIR.BG_FONT_NAME})
	display.commonUIParams(expBtn, {ap = cc.p(0, 0.5),po = cc.p(expImg:getPositionX() + 20, expImg:getPositionY())})
	display.commonLabelParams(expBtn, fontWithColor(10,{text = '',offset = cc.p(-40,0)}))
	view:addChild(expBtn)
	local expLabel = expBtn:getLabel()

	local expTipLabel = display.newLabel(50, 12, fontWithColor(7, {ap = display.LEFT_CENTER, fontSize = 20, color = '#572323'}))
	expTipLabel:setVisible(false)
	expBtn:addChild(expTipLabel)

	local icoDecorate = display.newImageView(RES_DIR.IMG_SHUIBOWEN, 11, 8)
	icoDecorate:setAnchorPoint(cc.p(0, 0))
	view:addChild(icoDecorate,1)

	local descLabel = display.newLabel(titleBg:getPositionX() + 20, titleBg:getPositionY() - titleBg:getContentSize().height * 0.5 - 15,
		fontWithColor(6,{text = '', ap = cc.p(0, 1), hAlign = display.TAL, w = bg:getContentSize().width*0.46,h=bg:getContentSize().height -50}))
	view:addChild(descLabel)

	local btn = display.newButton(0, 0, {n = RES_DIR.BTN_ORANGE , scale9 = true , size = cc.size(145, 70 ) })
	display.commonUIParams(btn, {po = cc.p(size.width - btn:getContentSize().width * 0.5 - 20, size.height * 0.55)})
	display.commonLabelParams(btn, fontWithColor(14 ,{fontSize = 22}))
	view:addChild(btn)

	local progressLabel = display.newLabel(btn:getPositionX(), btn:getPositionY() - btn:getContentSize().height * 0.5 - 10,
		{text = '', fontSize = 22, color = '#6c6c6c'})
	view:addChild(progressLabel)



	return {
		view          	 = view,
		bgView        	 = bg,
		bgVip         	 = bgVip,
		titleBg       	 = titleBg,
		titleLabel    	 = titleLabel,
		descrLabel    	 = descLabel,
		button        	 = btn,
		progressLabel 	 = progressLabel,
		activePointLabel = activePointLabel,
		icoActive        = icoActive,
		expBtn   		 = expBtn,
		expLabel  		 = expLabel,
		expImg   		 = expImg,
		expTipLabel      = expTipLabel,
	}
end

function TaskCellNode:ctor( ... )
	local t = unpack({...})
	self.size = t.size
	self:setContentSize(self.size)
	self.viewData = CreateView(self.size)
	display.commonUIParams(self.viewData.view,{po = cc.p(self.size.width * 0.5,self.size.height * 0.5)})
	self:addChild(self.viewData.view)
end

function TaskCellNode:refreshUI(data)
	-- dump(data)
	--[[--]]
	if not data then return end
	self.viewData.button:setTag(checkint(data.id))
	--self.viewData.titleLabel:setString(data.name)
	display.commonLabelParams(self.viewData.titleLabel ,{text =  data.name , w  = 290 , reqH = 74})
	if data.targetId then
		local str = ''
		local LocalData = nil
		if checkint(data.taskType) == 30 then--卡牌强化等级

		elseif checkint(data.taskType) == 33 then--契约等级
			LocalData = CommonUtils.GetConfig('cards', 'favorabilityLevel', data.targetId)
		else--道具相关
			LocalData = CommonUtils.GetConfig('goods', 'goods', data.targetId)
		end

		if LocalData then
			str = string.gsub(data.descr, '_target_id_', LocalData.name or '')
		else
			str = string.gsub(data.descr, '_target_id_',data.targetId)
		end
		self.viewData.descrLabel:setString(str)
	else
		self.viewData.descrLabel:setString(data.descr)
	end


	self.viewData.expLabel:setString(data.mainExp)
	-- self.viewData.expImg:setPositionX(self.viewData.expLabel:getPositionX() + self.viewData.expLabel:getBoundingBox().width + 2)

	if checkint(data.mainExp) > 0 then
		self.viewData.expImg:setVisible(true)
		self.viewData.expLabel:getParent():setVisible(true)
	else
		self.viewData.expImg:setVisible(false)
		self.viewData.expLabel:getParent():setVisible(false)
	end

	if data.showProgress then
		if data.showProgress == 1  then
			self.viewData.progressLabel:setString(string.format(('(%d/%d)'),checkint(data.progress), checkint(data.targetNum)))
		else
			self.viewData.progressLabel:setString(' ')
		end
	else
		self.viewData.progressLabel:setString(string.format(('(%d/%d)'),checkint(data.progress), checkint(data.targetNum)))
	end

	if checkint(data.taskType) == 14 or checkint(data.taskType) == 20  then
		self.viewData.progressLabel:setString(' ')
	end
	local bool = true
	self.viewData.button:setScale(1)
	if data.hasDrawn then
		if data.hasDrawn == 1 then
			self.viewData.button:setNormalImage(RES_DIR.MIFAN_BY_ICO)
			self.viewData.button:setSelectedImage(RES_DIR.MIFAN_BY_ICO)
			display.commonLabelParams(self.viewData.button, fontWithColor(7,{fontSize = 22,text = __('已领取')}))
			self.viewData.button:setScale(0.85)
			-- self.viewData.button:setText(__('已领取'))
			self.viewData.progressLabel:setString(' ')
			bool = false
		end
	end
	if bool == true then
		-- 判断任务状态
		if checkint(data.progress) >= checkint(data.targetNum) then
			self.viewData.progressLabel:setVisible(false)
			self.viewData.button:setNormalImage(RES_DIR.BTN_ORANGE)
			self.viewData.button:setSelectedImage(RES_DIR.BTN_ORANGE)
			display.commonLabelParams(self.viewData.button, fontWithColor(14,{text = __('领取')}))
		else
			self.viewData.button:setNormalImage(RES_DIR.BTN_ORANGE_DISABLE)
			self.viewData.button:setSelectedImage(RES_DIR.BTN_ORANGE_DISABLE)
			display.commonLabelParams(self.viewData.button, fontWithColor(14,{text = __('未完成')}))
			self.viewData.progressLabel:setVisible(true)
		end
	end
	display.commonLabelParams(self.viewData.button , { w = 140 , hAlign = display.TAC})
	if data.taskType then
		if checkint(data.taskType) == 0 then--月卡

			self.viewData.bgView:setVisible(false)
			self.viewData.bgVip:setVisible(true)
			self.viewData.titleBg:setTexture(RES_DIR.BG_TITLE_VIP)

		else--正常任务

			self.viewData.bgView:setVisible(true)
			self.viewData.bgVip:setVisible(false)
			self.viewData.titleBg:setTexture(RES_DIR.BG_TITLE) 
		end
	end
end


return TaskCellNode
