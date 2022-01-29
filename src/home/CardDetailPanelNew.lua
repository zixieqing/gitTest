--[[
卡牌详情面板
@params table {
	id int card id
	lv int card level
	star int card star
}
--]]
local CardDetailPanelNew = class('CardDetailPanelNew', function ()
	local node = CLayout:create()
	node.name = 'home.CardDetailPanelNew'
	node:enableNodeEvents()
	return node
end)
function CardDetailPanelNew:ctor( ... )
	self.args = unpack({...}) or {}

	--------------------------------------
	-- ui

	self.cateTabBtns = {}
	self.detailContainers = {}
	self.bottomBg = nil
	--------------------------------------
	-- ui data
	self.selectedCateTag = 0
	self.categoryData = {
		{name = __('属性'), className = 'home.CardDetailPropertyNew',sImg = 'ui/cards/propertyNew/card_btn_tabs_star_selected.png',nImg = 'ui/cards/propertyNew/card_btn_tabs_star_default.png'},
		{name = __('技能'), className = 'home.CardDetailSkillNew',sImg = 'ui/cards/propertyNew/card_btn_tabs_skill_selected.png',nImg = 'ui/cards/propertyNew/card_btn_tabs_skill_default.png'},
		-- {name = __('我的堕神'), className = 'home.CardDetailPetNew',sImg = 'ui/cards/propertyNew/card_btn_tabs_pet_selected.png',nImg = 'ui/cards/propertyNew/card_btn_tabs_pet_default.png'},
		{name = __('皮肤'), className = 'home.CardDetailSkin',sImg = 'ui/cards/propertyNew/card_btn_tabs_skin_selected.png',nImg = 'ui/cards/propertyNew/card_btn_tabs_skin_default.png'}

	}
	if CommonUtils.GetModuleAvailable(MODULE_SWITCH.PET) then
		table.insert( self.categoryData,3, {name = __('我的堕神'), className = 'home.CardDetailPetNew',sImg = 'ui/cards/propertyNew/card_btn_tabs_pet_selected.png',nImg = 'ui/cards/propertyNew/card_btn_tabs_pet_default.png'} )
	end

	self:initUI()
end
function CardDetailPanelNew:initUI()
	local bgSize = cc.size(515, display.size.height - 90)-- display.size.height - 2*NAV_BAR_HEIGHT)
	local layerSize = cc.size(515, display.size.height - 90)
	self.layerSize = layerSize
	self:setContentSize(layerSize)
	-- self:setBackgroundColor(cc.c4b(0, 255, 128, 128))

	local bottomBg = display.newImageView(_res('ui/cards/propertyNew/card_bg_tabs_2.png'), 0, 0)
	self:addChild(bottomBg)
	bottomBg:setPosition(cc.p(layerSize.width * 0.5 - 5,-35))
	bottomBg:setAnchorPoint(cc.p(0.5,0))
	self.bottomBg = bottomBg

	local modelView = CLayout:create(cc.size(515,display.size.height - 200))
	modelView:setName('modelView')
	modelView:setAnchorPoint(cc.p(0.5,1))
	modelView:setPosition(cc.p(layerSize.width*0.5,layerSize.height))
	self:addChild(modelView)
	self.modelView = modelView

	-- cate btns
	self:createCategoryBtns()


	self:showComeLayerAction()

end

--执行进入卡牌详情页面时的动画表现
function CardDetailPanelNew:showComeLayerAction()
	self.bottomBg:stopAllActions()
	self.bottomBg:setPositionY(-35 - 100)
	self.bottomBg:runAction(
        cc.Sequence:create(--cc.DelayTime:create(0.02),
        	cc.EaseOut:create(cc.MoveTo:create(0.3, cc.p(self.layerSize.width * 0.5 - 5,0)), 1)
        ))


	for i,v in ipairs(self.categoryData) do
		local tabButton = self.cateTabBtns[tostring(i)]
		tabButton:stopAllActions()
		tabButton:setPositionY(2 - 100)
		tabButton:runAction(
	        cc.Sequence:create(--cc.DelayTime:create(0.02),
	        	cc.EaseOut:create(cc.MoveTo:create(0.3, cc.p(self.layerSize.width * 0.3 + 115*(i-1) - 115 ,2)), 1)
	        ))
		tabButton:getChildByTag(3):setPosition(utils.getLocalCenter(tabButton).x , 25)
	end
	-- self.detailContainers[tostring(self.selectedCateTag)]:runAction(cc.FadeIn:create(0.2))
end

--执行退出卡牌详情页面时的动画表现
function CardDetailPanelNew:showBackLayerAction()
	self.bottomBg:stopAllActions()
	self.bottomBg:runAction(
        cc.Sequence:create(--cc.DelayTime:create(0.02),
        	cc.EaseOut:create(cc.MoveTo:create(0.5, cc.p(self.layerSize.width * 0.5 - 5,-35 - 400)), 1)
        ))


	for i,v in ipairs(self.categoryData) do
		local tabButton = self.cateTabBtns[tostring(i)]
		tabButton:stopAllActions()
		tabButton:runAction(
	        cc.Sequence:create(--cc.DelayTime:create(0.02),
	        	cc.EaseOut:create(cc.MoveTo:create(0.5, cc.p(self.layerSize.width * 0.3 + 115*(i-1) - 115,2 - 400)), 1)
	        ))
		tabButton:getChildByTag(3):setPosition(utils.getLocalCenter(tabButton).x , 16)
	end

	-- self.detailContainers[tostring(self.selectedCateTag)]:runAction(cc.FadeOut:create(0.5))
end


function CardDetailPanelNew:createCategoryBtns()
	local bgSize = self.layerSize
	local btnScale = 1
	for i,v in ipairs(self.categoryData) do
		local tabButton = display.newCheckBox(0,0,
			{n = _res(v.nImg),
			s = _res(v.sImg)})
		display.commonUIParams(
			tabButton,
			{
				ap = cc.p(0, 0),
				po = cc.p(bgSize.width * 0.3 + 115*(i-1)  - 115 ,2)
			})
		tabButton:setScale(btnScale)
		self:addChild(tabButton, 1)
		tabButton:setName('btn.'..v.className)
		tabButton:setTag(i)
		tabButton:setOnClickScriptHandler(handler(self, self.cateBtnCallback))


		local bottomBg = display.newImageView(_res('ui/cards/propertyNew/card_bar_bg.png'), 0, 0, {scale9 = true, ap =display.CENTER_BOTTOM })
		bottomBg:setContentSize(cc.size(120,50))
		tabButton:addChild(bottomBg)
		bottomBg:setPosition(cc.p(utils.getLocalCenter(tabButton).x ,2))

		local cateLabel = display.newLabel(utils.getLocalCenter(tabButton).x , 16,
			{ttf = true,font = TTF_GAME_FONT,text = v.name, hAlign = display.TAC, fontSize = 22, color= '#ffffff' , w = 140,reqW = 120 , ap =display.CENTER})
		tabButton:addChild(cateLabel,1)
		local cateLabelSize = display.getLabelContentSize(cateLabel)
		if cateLabelSize.height > 50  then
			local curentScale =  cateLabel:getScale()
			cateLabel:setScale(curentScale * 50 / cateLabelSize.height  )
		end
		cateLabel:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		cateLabel:setTag(3)

		self.cateTabBtns[tostring(i)] = tabButton
	end
	self:clickCateBtn(1)
end
function CardDetailPanelNew:cateBtnCallback(pSender)
    PlayAudioByClickNormal()
	local tag = pSender:getTag()
	self:clickCateBtn(tag)
end
function CardDetailPanelNew:clickCateBtn(tag)
	if tag ~= self.selectedCateTag then
		local preBtn = self.cateTabBtns[tostring(self.selectedCateTag)]
		if preBtn then
			preBtn:setChecked(false)
			-- local nameLabel = preBtn:getChildByTag(3)
			-- nameLabel:setPositionY(nameLabel:getPositionY() - 2)
		end
		local curBtn = self.cateTabBtns[tostring(tag)]
		if curBtn then
			curBtn:setChecked(true)
			-- local nameLabel = curBtn:getChildByTag(3)
			-- nameLabel:setPositionY(nameLabel:getPositionY() + 2)
		end
		self:refreshPanel(tag)
		self.selectedCateTag = tag
	else
		local curBtn = self.cateTabBtns[tostring(tag)]
		if curBtn then
			curBtn:setChecked(true)
		end
	end
	GuideUtils.DispatchStepEvent()
end


function CardDetailPanelNew:refreshPanel(tag)
	local prePanel = self.detailContainers[tostring(self.selectedCateTag)]
	if prePanel then
		prePanel:setVisible(false)
	end
	local name = self.categoryData[checkint(tag)].className
	if name ~=  'home.CardDetailSkillNew' then
		app:UnRegsitMediator("CardSkillMediator")
	else
		local mediator = require("Game.mediator.cardList.CardSkillMediator").new()
		app:RegistMediator(mediator)
	end

	if self.detailContainers[tostring(tag)] then
		if tag == 2 then
			self.detailContainers[tostring(tag)].clickTag = 1
		else
			app:UnRegsitMediator("CardSkillMediator")
		end
		self.detailContainers[tostring(tag)]:setVisible(true)
		self.detailContainers[tostring(tag)]:refreshUI(self.args,1)
	else
		local cateData = self.categoryData[checkint(tag)]
		local view = require(cateData.className).new(self.args)
		view:setName(cateData.className)
		view:setAnchorPoint(cc.p(0, 0))
		view:setPosition(cc.p(0,0))
		self.modelView:addChild(view, 5)
		self.detailContainers[tostring(tag)] = view
	end
	AppFacade.GetInstance():RetrieveMediator('CardsListMediatorNew'):ShowSkillUi({modelTag = tag})--  self.args, tag
	
end

function CardDetailPanelNew:updataPanel(data)--,index,bool,isShowAction
	-- print('*************')
    -- dump(data)
	self.args = data.data
	if data.isFirst and data.isFirst == true then
		--设置全部模块页面不可见
		for k,v in pairs(self.detailContainers) do
			if v then
				v:setVisible(false)
			end
		end
		--设置全部页签按钮为未点击状态
		for k,v in pairs(self.cateTabBtns) do
			if v then
				v:setChecked(false)
			end
		end
		self.selectedCateTag = 0
		self:clickCateBtn(1)
		if data.isShowAction then
			self:showComeLayerAction()
		end

	else
		self.detailContainers[tostring(self.selectedCateTag)]:refreshUI(data.data,data.showModel,data)
		AppFacade.GetInstance():RetrieveMediator('CardsListMediatorNew'):UpdataSkillUi_1(data.showSkillIndex,data.showModel)
	end

end

return CardDetailPanelNew
