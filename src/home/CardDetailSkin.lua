--[[
卡牌皮肤
}
--]]
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local petMgr = AppFacade.GetInstance():GetManager("PetManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local CardDetailSkin = class('CardDetailSkin', function ()
	local node = CLayout:create()
	node.name = 'home.CardDetailSkin'
	node:enableNodeEvents()
	return node
end)

local acquiringQayConfig = {
	['1'] = '初始皮肤',
	['2'] = '满星皮肤',
	['3'] = '契约满级皮肤',
	['4'] = '其他获取途径',
}

function CardDetailSkin:ctor( ... )
	self.args = unpack({...}) or {}

	--------------------------------------


	--------------------------------------
	-- ui data

	--------------------------------------
	-- data
	-- dump(self.args.skin)--已拥有的皮肤id列表
	-- dump(self.args.defaultSkinId)--默认皮肤id

	self.cardData = CommonUtils.GetConfig('cards', 'card', self.args.cardId)

	-- dump(self.cardData.skin)--可拥有的全部皮肤id列表 key不同表示解锁条件不同

	self.chooseTag = 1

	-- dump(self.args)
	local tempData = {}
	self.unLockSkin = {}
	for k,v in pairs(self.cardData.skin) do
		for kk,vv in pairs(v) do
			local t = {skinId = vv, locktype = checkint(k)}
			if checkint(vv) == checkint(self.args.defaultSkinId) then
				table.insert(tempData,t)
				tempData = t
			else
				local skinConf = CardUtils.GetCardSkinConfig(vv)
				if skinConf then
					table.insert(self.unLockSkin, t)
		        end
			end
		end
	end

    --当前选择皮肤置为第一位
	if table.nums(tempData) > 0 then
		table.insert(self.unLockSkin,1,tempData)
	end

	-- dump(self.unLockSkin)--可拥有的全部皮肤id列表

	self:initUI()
end
function CardDetailSkin:initUI()
	local bgSize = cc.size(515,display.size.height - 200)
	self:setContentSize(bgSize)
	-- self:setBackgroundColor(cc.c4b(100, 100, 100, 100))

 	local titleBtn = display.newButton(0, 0, {n = _res('ui/common/common_title_3.png') , scale9 = true })
 	display.commonUIParams(titleBtn, {ap = cc.p(0.5,0), po = cc.p(bgSize.width*0.5,bgSize.height - 20)})
	if isElexSdk() then
		display.commonLabelParams(titleBtn, fontWithColor(6,{ paddingW = 25 ,text = string.fmt(__('_name_的皮肤'),{_name_ = self.cardData.name})}))
	else
		display.commonLabelParams(titleBtn, fontWithColor(6,{text = string.fmt(__('_name_的皮肤'),{_name_ = self.cardData.name})}))
	end

 	self:addChild(titleBtn,1)
 	self.titleBtn = titleBtn
	local zoomSliderList = require("common.ZoomSliderList").new()
    self:addChild(zoomSliderList)
    local cellSize = cc.size(200 , 540)
    zoomSliderList:setBasePoint(cc.p(bgSize.width*0.5, bgSize.height*0.5-20))
    zoomSliderList:setCellSize(cellSize)
    zoomSliderList:setScaleMin(0.8)
    -- zoomSliderList:setAlphaMin(150)
    zoomSliderList:setCellSpace(220)
    zoomSliderList:setCenterIndex(1)
    zoomSliderList:setDirection(2)
    zoomSliderList:setAlignType(3)
    zoomSliderList:setSideCount(1)
    zoomSliderList:setSwallowTouches(false)
    self.zoomSliderList = zoomSliderList

	self.zoomSliderList:setCellCount(#self.unLockSkin)
	local cellSize = cc.size(200 , 540)
    zoomSliderList:setCellChangeCB(function(p_cell, idx)
        local cell = p_cell
        if not cell then
            -- print('...create', idx)
            cell = display.newLayer(0, 0, {size = cellSize})--, color = cc.r4b(250)
            local tempCell = self:CreateSkinCell( )
            cell:addChild(tempCell.view)
            tempCell.view:setPosition(cc.p(cellSize.width/2 , cellSize.height/2))
            tempCell.view:setScale(0.9)
            cell:setCascadeOpacityEnabled(true)
        end

		local skinId   = checkint(self.unLockSkin[idx].skinId)
		local skinConf = CardUtils.GetCardSkinConfig(skinId) or {}
		local bgView   = cell:getChildByTag(1):getChildByTag(1)
		if bgView then
			-- update bgView
			bgView:setTexture(CardUtils.GetCardTeamBgPathBySkinId(skinId))
	
			-- update cell
			local imgHero = bgView:getChildByTag(1):getChildByTag(1)
			if imgHero then
				local cardDrawName = CardUtils.GetCardDrawNameBySkinId(skinId)
				imgHero:setTexture(AssetsUtils.GetCardDrawPath(cardDrawName))

				local locationInfo = CommonUtils.GetConfig('cards', 'coordinate', cardDrawName)
				if nil == locationInfo or not locationInfo[COORDINATE_TYPE_TEAM] then
					-- print('\n**************\n', '立绘坐标信息未找到', cardDrawName, '\n**************\n')
					locationInfo = {x = 0, y = 0, scale = 50, rotate = 0}
				else
					locationInfo = locationInfo[COORDINATE_TYPE_TEAM]
				end
				imgHero:setScale(locationInfo.scale/100)
				imgHero:setRotation( checkint(locationInfo.rotate))
				imgHero:setPosition(cc.p(locationInfo.x,(-1)*(locationInfo.y-540)))
				
				imgHero:setFilterName(filter.TYPES.GRAY)
				if app.cardMgr.IsHaveCardSkin(skinId) then
					imgHero:setFilterName()
				end

				if GAME_MODULE_OPEN.CARD_SKIN_SIGN then
					self:UpdateSkinSignState(cell:getChildByTag(1), skinConf)
				end
			end
		end
        return cell
	end)
	zoomSliderList:setCellUpdateCB(function(p_cell, idx)
		local cell = p_cell
		local changeBtn = cell:getChildByTag(1):getChildByTag(2)
        if changeBtn then
			if self.chooseTag == idx then
				changeBtn:setVisible(true)
				changeBtn:setTouchEnabled(true)
				changeBtn:setUserTag(checkint(idx))
				changeBtn:setOnClickScriptHandler(handler(self,self.CellButtonAction))
			else
				changeBtn:setVisible(false)
				changeBtn:setTouchEnabled(false)
			end
        end
	end)
    zoomSliderList:setIndexPassChangeCB(function(sender, idx)
        -- print(':::--->>', idx)
        self.chooseTag = idx
    end)
    zoomSliderList:setIndexOverChangeCB(function(sender, idx)
        -- print(':::===>>', idx)
        self.chooseTag = idx
        local skinConf = CardUtils.GetCardSkinConfig(self.unLockSkin[idx].skinId) or {}
        local des = skinConf.name or acquiringQayConfig[tostring(self.unLockSkin[idx].locktype)] or __('其他获取途径')
		if isElexSdk() then
			display.commonLabelParams(self.titleBtn  , {text = des , paddingW = 25  })
		else
			self.titleBtn:getLabel():setString(des)
		end


    end)
    zoomSliderList:reloadData()

end

--检测是否拥有该皮肤
function CardDetailSkin:checkHasSkin(skinId)
	local bool = false
	if gameMgr:GetUserInfo().cardSkins then
		for i,v in ipairs(gameMgr:GetUserInfo().cardSkins) do
			if checkint(skinId) == checkint(v) then
				bool = true
				break
			end
		end
	end
	return bool
end

function CardDetailSkin:CellButtonAction( sender)
    PlayAudioByClickNormal()
	local tag = sender:getUserTag()

	self.chooseTag = tag
	-- print(self.unLockSkin[tag].skinId)
	if app.cardMgr.IsHaveCardSkin(self.unLockSkin[tag].skinId) then
		if checkint(self.args.defaultSkinId) == checkint(self.unLockSkin[tag].skinId) then
			uiMgr:ShowInformationTips(__('替换成功'))
		else
			local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
			httpManager:Post("card/defaultSkin",SIGNALNAMES.Hero_ChooseSkin_Callback,{ playerCardId = self.args.id,skinId = self.unLockSkin[tag].skinId})
			-- AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Hero_ChooseSkin_Callback ,{defaultSkinId = self.unLockSkin[tag].skinId})
		end

	else
		uiMgr:ShowInformationTips(__('皮肤未解锁'))
	end
end

function CardDetailSkin:CreateSkinCell( )
	local size = cc.size(200 , 540)
	local view = CLayout:create(cc.size(size.width,size.height ))
	-- view:setBackgroundColor(cc.c4b(0, 128, 0, 100))
	view:setTag(1)


	local lastKuangBg = display.newImageView(_res('ui/home/teamformation/newCell/team_frame_tianjiawan1.png'), size.width * 0.5, size.height * 0.5 + 12 )
	view:addChild(lastKuangBg,2)

	local bg = AssetsUtils.GetCardTeamBgNode(0, size.width * 0.5 + 1, size.height * 0.5 + 12)
	view:addChild(bg)
	bg:setTag(1)
	bg:setCascadeOpacityEnabled(true)
	local lsize = bg:getContentSize()

	local roleClippingNode = cc.ClippingNode:create()
	roleClippingNode:setContentSize(cc.size(lsize.width,lsize.height -2))
	roleClippingNode:setAnchorPoint(0.5, 1)
	roleClippingNode:setPosition(cc.p(lsize.width / 2,lsize.height))
	roleClippingNode:setInverted(false)
	bg:addChild(roleClippingNode, 1)
	roleClippingNode:setTag(1)

	roleClippingNode:setCascadeOpacityEnabled(true)

	-- cut layer
	local cutLayer = display.newLayer(
		0,
		0,
		{
			size = roleClippingNode:getContentSize(),
			ap = cc.p(0, 0),
			color = '#ffcc00'
		})


	local imgHero = AssetsUtils.GetCardDrawNode()
	imgHero:setAnchorPoint(display.LEFT_BOTTOM)
	imgHero:setTag(1)


	roleClippingNode:setStencil(cutLayer)
	roleClippingNode:addChild(imgHero)

	local  changeBtn = display.newButton(lsize.width*0.5,60 , {n = 'ui/common/common_btn_orange.png'})
	display.commonLabelParams(changeBtn, fontWithColor(14,{ap = cc.p(0.5,0.5),text = __('替换')}))
	view:addChild(changeBtn)
	changeBtn:setTag(2)
	
	return {
		view   		  = view,
		imgHero 	  = imgHero,
		changeBtn 	  = changeBtn,
		bg 			  = bg,
		
	}
end

function CardDetailSkin:refreshUI( data )
	if data then
		self.args = data
	end
	self.cardData = CommonUtils.GetConfig('cards', 'card', self.args.cardId)
	self.chooseTag = 1


	local tempData = {}
	self.unLockSkin = {}
	for k,v in pairs(self.cardData.skin) do
		for kk,vv in pairs(v) do
			local t = {skinId = vv,locktype = checkint(k)}
			if checkint(vv) == checkint(self.args.defaultSkinId) then
				table.insert(tempData,t)
				tempData = t
			else
				local skinConf = CardUtils.GetCardSkinConfig(vv)
				if skinConf then
					table.insert(self.unLockSkin, t)
		        end
			end
		end
	end
    --当前选择皮肤置为第一位
	if table.nums(tempData) > 0 then
		table.insert(self.unLockSkin,1,tempData)
	end

	self.zoomSliderList:setCenterIndex(1)
	self.zoomSliderList:setCellCount(#self.unLockSkin)
	self.zoomSliderList:reloadData()

end

function CardDetailSkin:CreateSkinSignLayer(view)
	local size = cc.size(200 , 540)
	local skinSignLayerSize = cc.size(211, 65)
	local skinSignLayer = display.newLayer(size.width / 2, 130, {ap = display.CENTER, size = skinSignLayerSize})
	skinSignLayer:setName('skinSignLayer')
	view:addChild(skinSignLayer, 2)

	if GAME_MODULE_OPEN.CARD_LIVE2D then
		local liveBtn = display.newButton( size.width/2+5 , size.height - 90 , {ap = display.CENTER_TOP , n = _res('ui/common/sp_brand_live2d') ,   })
		liveBtn:setTag(20 )
		liveBtn:setScale(1.15)
		skinSignLayer:addChild(liveBtn)

		liveBtn:setVisible(false)
		liveBtn:setName('liveBtn')
		display.commonLabelParams(liveBtn , {text = "Live2D" , fontSize = 20 })
	end

	local skinSignImg = display.newImageView('', skinSignLayerSize.width / 2, skinSignLayerSize.height / 2)
	skinSignImg:setName('skinSignImg')
	skinSignLayer:addChild(skinSignImg)

	local skinSignTitle = display.newLabel(skinSignImg:getPositionX(), skinSignImg:getPositionY() - 2, {text = __('史诗'), ap = display.CENTER_BOTTOM, fontSize = 22, color = '#ffe9ae', font = TTF_GAME_FONT, ttf = true, outline = '#892f08', outlineSize = 2})
	skinSignTitle:setName('skinSignTitle')
	skinSignLayer:addChild(skinSignTitle)
		
	local limitTitle = display.newLabel(skinSignImg:getPositionX(), skinSignImg:getPositionY() - 2, {text = __('限定'), ap = display.CENTER_TOP, fontSize = 22, color = '#ad77ff', font = TTF_GAME_FONT, ttf = true, outline = '#420080', outlineSize = 2})
	limitTitle:setName('limitTitle')
	skinSignLayer:addChild(limitTitle)
	limitTitle:setVisible(false)

	local spineJsonPath  = 'cards/skinsign/spine/xiandinpifu.json'
	local spineAtlasPath = 'cards/skinsign/spine/xiandinpifu.atlas'
	if utils.isExistent(spineJsonPath) and utils.isExistent(spineAtlasPath) then
		local skinSignSpine = sp.SkeletonAnimation:create(
			spineJsonPath,
			spineAtlasPath,
			1
		)
		skinSignSpine:update(0)
		skinSignSpine:setName('skinSignSpine')
		skinSignSpine:setVisible(false)
		display.commonUIParams(skinSignSpine, {po = cc.p(skinSignLayerSize.width / 2, skinSignLayerSize.height / 2)})
		skinSignLayer:addChild(skinSignSpine)
		
	end

	return skinSignLayer
end

function CardDetailSkin:UpdateSkinSignState(view, skinConf)
	local skinConf = checktable(skinConf)
	local iconId = skinConf.iconId
	local iconTitle = skinConf.iconTitle

	local isOwnIconId = (iconId ~= nil and iconId ~= '') or checkint(skinConf.showLive2d) > 0

	local skinSignLayer = view:getChildByName('skinSignLayer')
	if skinSignLayer then
		skinSignLayer:setVisible(isOwnIconId)
	end
	if isOwnIconId then
		if skinSignLayer == nil then
			skinSignLayer = self:CreateSkinSignLayer(view)
		end

		local liveBtn = skinSignLayer:getChildByName('liveBtn')
		if liveBtn then
			if checkint(skinConf.showLive2d) > 0  then
				liveBtn:setVisible(true)
			else
				liveBtn:setVisible(false)
			end
		end

		local skinSignImg = skinSignLayer:getChildByName('skinSignImg')
		if skinSignImg then
			skinSignImg:setTexture(_res(string.format('cards/skinsign/%s.png', iconId)))
		end

		local limitTitle = skinSignLayer:getChildByName('limitTitle')
		if limitTitle then
			limitTitle:setVisible(iconId == 'card_avatar_mark_limited')
		end

		local skinSignTitle = skinSignLayer:getChildByName('skinSignTitle')
		if skinSignTitle then
			local conf = self:GetSkinSignTitleConf(iconId)
			conf.text = tostring(iconTitle)

			display.commonLabelParams(skinSignTitle, conf)
		end

		local skinSignSpine = skinSignLayer:getChildByName('skinSignSpine')
		if skinSignSpine then
			local idleName = self:GetSkinSignSpineIdleName(iconId)
			if idleName ~= '' then
				skinSignSpine:setVisible(true)
				skinSignSpine:setAnimation(0, idleName, true)
			else
				skinSignSpine:setVisible(false)
			end
		end
	end

end

function CardDetailSkin:GetSkinSignTitleConf(imgName)
	local conf = nil
	if imgName == 'card_avatar_mark_2' then
		conf = {ap = display.CENTER, fontSize = 22, color = '#fffaad', font = TTF_GAME_FONT, ttf = true, outline = '#892f08', outlineSize = 2, hAlign = display.TAC, w = 140}
	elseif imgName == 'card_avatar_mark_3' then
		conf = {ap = display.CENTER, fontSize = 22, color = '#ffba27', font =TTF_GAME_FONT, ttf = true, outline = '#892f08', outlineSize = 2, hAlign = display.TAC, w = 140}
	elseif imgName == 'card_avatar_mark_4' then
		conf = {ap = display.CENTER, fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#790d0a', outlineSize = 2, hAlign = display.TAC, w = 140}
	elseif imgName == 'card_avatar_mark_limited' then
		conf = {ap = display.CENTER_BOTTOM, fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#007dc5', outlineSize = 2, hAlign = display.TAC, w = 140}
	else
		conf = {ap = display.CENTER, fontSize = 22, color = '#ffe9ae', font =TTF_GAME_FONT, ttf = true, outline = '#892f08', outlineSize = 2, hAlign = display.TAC, w = 140}
	end

	return conf
end

function CardDetailSkin:GetSkinSignSpineIdleName(imgName)
	local idleName = ''
	if  imgName == 'card_avatar_mark_limited' or 
		imgName == 'card_avatar_mark_4' or 
		imgName == 'card_avatar_mark_3' then

		idleName = 'idle1'

	elseif imgName == 'card_avatar_mark_2' then
		idleName = 'idle2'
	end
	return idleName
end

return CardDetailSkin
