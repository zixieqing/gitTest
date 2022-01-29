local Mediator = mvc.Mediator

local MapDetailOverviewMediator = class("MapDetailOverviewMediator", Mediator)


local NAME = "MapDetailOverviewMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function MapDetailOverviewMediator:ctor(param, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.cityId = nil
	self.chooseCityIndex = 1
	self.allOpenCityID = {}
	if param then
		self.cityId = param
	end
	self.cityData = {}
	self.historyData = {}
end

function MapDetailOverviewMediator:InterestSignals()
	local signals = {
	}

	return signals
end

function MapDetailOverviewMediator:ProcessSignal(signal )
	local name = signal:GetName()
	print(name)
end


function MapDetailOverviewMediator:Initial( key )
	self.super.Initial(self,key)

	local newestAreaId = checkint(gameMgr.userInfo.newestAreaId)
    local areaDatas = CommonUtils.GetConfigAllMess('worldMapCoordinate', 'collection')
    if areaDatas then
        for nId,val in orderedPairs(areaDatas) do
        	if checkint(nId) <= newestAreaId then
        		table.insert(self.allOpenCityID,nId)
        	end
        end
    end

	for i,v in ipairs(self.allOpenCityID) do
		if checkint(self.cityId) == checkint(v) then
			self.chooseCityIndex = i
			break
		end
	end

    -- dump(self.cityId)
    -- dump(self.chooseCityIndex)
    -- dump(self.allOpenCityID)

	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.MapDetailOverView' ).new(self.cityId)--self.cityData
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddGameLayer(viewComponent)


	-- backBtn
	viewComponent.viewData.backBtn:setOnClickScriptHandler(function( sender )
        PlayAudioByClickNormal()
		-- body
		self:GetFacade():UnRegsitMediator("MapDetailOverviewMediator")
	end)


	viewComponent.viewData.historyBtn:setOnClickScriptHandler(handler(self,self.HistoryButtonsCallBack))


	self.viewData = nil
	self.viewData = viewComponent.viewData


	self:UpdataCityPoint()
	local key = string.format('MapDetailOverviewMediator_%s_%s', tostring(self.cityId),tostring(gameMgr:GetUserInfo().playerId))
 	if not cc.UserDefault:getInstance():getBoolForKey(key) then
	 	cc.UserDefault:getInstance():setBoolForKey(key, true)
	 	self:CheckOpenHistoryUI(self.historyData )
	end

end



function MapDetailOverviewMediator:CheckOpenHistoryUI( showData ,sender )
	if not showData then
		showData = {}
	end
	if not showData.name then
		showData.name = '标题'
	end
	if not showData.descr then
		showData.descr = ' '
	end
	local showData = showData

	local scene = uiMgr:GetCurrentScene()
	if  scene:GetDialogByTag( 5000 ) then
		scene:RemoveDialogByTag( 5000 )
	end


	local pos = display.center
	local ap = cc.p(0.5,0.5)
	if sender then
		local pp = sender:convertToWorldSpaceAR(cc.p(0,0))

		if pp.x < display.size.width*0.5 then
			pos = cc.p(display.size.width - 50,display.center.y)
			ap = cc.p(1,0.5)
		else
			pos = cc.p(50,display.center.y)
			ap = cc.p(0, 0.5)
		end
		if sender:getChildByTag(2) then
         	sender:getChildByTag(2):setVisible(true)
      	end
	end

	local layer = require('Game.views.MapDetailMessView').new()
	layer:setTag(5000)
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = display.center})

	display.commonUIParams(layer.viewData_.view, {po = pos,ap = ap})

	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(layer)
	local viewData = layer.viewData_
	layer.eaterLayer:setOpacity(0)
	layer.eaterLayer:setOnClickScriptHandler(function()
		scene:RemoveDialog(layer)
		if sender then
			if sender:getChildByTag(2) then
	         	sender:getChildByTag(2):setVisible(false)
	      	end
		end
	end)


	viewData.title:getLabel():setString(showData.name)
    local lwidth = display.getLabelContentSize(viewData.title:getLabel()).width
    if lwidth < 186 then lwidth = 186 end
    viewData.title:setContentSize(cc.size(lwidth + 50, 32))
    -- local lineNo = 18
    -- local lines = math.floor((utf8len(showData.descr) + lineNo - 1) / lineNo)
    -- local h = (lines * 26 + (lines - 1) * 10)
	local descrLabel = display.newLabel(230, 0, {ap = cc.p(0.5, 0), w = 440, text = showData.descr, color = '#5b3c25', fontSize = 24, noScale = true, ttf = true, font = TTF_TEXT_FONT})
    local h = descrLabel:getContentSize().height
	local descrCell = CLayout:create(cc.size(460, h + 20))
	descrCell:addChild(descrLabel)
	viewData.listView:insertNodeAtLast(descrCell)
	local placeholderCell = CLayout:create(cc.size(460, 120))
	viewData.listView:insertNodeAtLast(placeholderCell)
	viewData.listView:setContentOffsetToTop()
	viewData.listView:reloadData()
end

function MapDetailOverviewMediator:UpdataCityPoint( )
	self.cityData = {}
	self.historyData = {}
	self.viewData.cityPointView:removeAllChildren()
	local datas = CommonUtils.GetConfigAllMess('world', 'collection')
	-- dump(datas)
	for k,v in pairs(datas) do
		if checkint(v.areaId) ~= 999 and checkint(v.areaId) == checkint(self.cityId) then
			if checkint(v.type) == 2 then
				table.insert(self.cityData, v )
			elseif checkint(v.type) == 1 then
				self.historyData = v
			end
		end
	end
	-- dump(self.cityData)

    local cityPoint = {}
    if self.cityData then
        for i,val in ipairs(self.cityData) do
        	local pos = cc.p((val.location.x or display.width* 0.5),1002 - (val.location.y or display.height* 0.5))

			if CommonUtils.CheckLockCondition(val.unlockType) then

	            local buttonImage = display.newButton(pos.x, pos.y, {
	                n = _res('ui/manual/mapoverview/pokedex_maps_btn_scenic_spot_lock')
	            })
	            buttonImage:setTag(i)
	            self.viewData.cityPointView:addChild(buttonImage, 1)


				buttonImage:setOnClickScriptHandler(function( sender )
                    PlayAudioByClickNormal()
					-- body
					uiMgr:ShowInformationTips(__('现在还未知道更多的消息，请继续收集打探。'))
				end)

			else
		 	    -- q版立绘
				local qBg = display.newImageView(_res('ui/common/comon_bg_frame_gey.png'), 0, 0, {scale9 = true, size = cc.size(80, 80)})
				display.commonUIParams(qBg, {ap = cc.p(0.5, 0.5), po = cc.p(pos.x, pos.y)})
				self.viewData.cityPointView:addChild(qBg,16)
				qBg:setOpacity(0)
				qBg:setCascadeOpacityEnabled(true)

				local qAvatar = sp.SkeletonAnimation:create('effects/mapOver/anime_base.json', 'effects/mapOver/anime_base.atlas', 1)
			    qAvatar:update(0)
			    qAvatar:setTag(1)
			    qAvatar:setAnimation(0, 'idle', true)
			    qAvatar:setPosition(cc.p(qBg:getContentSize().width * 0.5, 15))
			    qBg:addChild(qAvatar)


	    	    qBg:setTouchEnabled(true)
			    qBg:setOnClickScriptHandler(function( sender )
                    PlayAudioByClickNormal()
			        xTry(function()
			            self:CheckOpenHistoryUI( val  ,qBg)
			        end,__G__TRACKBACK__)
			    end)


    		    local particle = cc.ParticleSystemQuad:create('effects/mapOver/diandian.plist')
			    particle:setAutoRemoveOnFinish(true)
			    particle:setPosition(cc.p(qBg:getContentSize().width /2, 12))
				qBg:addChild(particle,1)
				particle:setVisible(false)
				particle:setTag(2)
			end
        end
    end


	self.viewData.tabNameLabel:getLabel():setString(CommonUtils.GetConfigNoParser('common', 'area', self.cityId).name)
end

--[[
@param sender button对象
--]]
function MapDetailOverviewMediator:HistoryButtonsCallBack( sender )
    PlayAudioByClickNormal()
	-- if next(self.historyData) ~= nil  then
	-- 	uiMgr:ShowInformationTipsBoard({targetNode = sender, title = self.historyData.name, descr = self.historyData.descr, type = 5})
	-- end

	self:CheckOpenHistoryUI(self.historyData)
end

function MapDetailOverviewMediator:SwichButtonsCallBack( sender )
    PlayAudioByClickNormal()
	local tag = sender:getTag()
	if tag == 1 then--左
		self.chooseCityIndex = self.chooseCityIndex - 1
		if self.chooseCityIndex <= 0 then
			self.chooseCityIndex = table.nums(self.allOpenCityID)
		end
	else--右
		self.chooseCityIndex = self.chooseCityIndex + 1
		if self.chooseCityIndex > table.nums(self.allOpenCityID) then
			self.chooseCityIndex = 1
		end
	end
	-- dump(self.chooseCityIndex)
	-- dump(self.allOpenCityID[self.chooseCityIndex])
	if self.allOpenCityID[self.chooseCityIndex] then
		self.cityId = self.allOpenCityID[self.chooseCityIndex]
	end
	self:UpdataCityPoint()
end

function MapDetailOverviewMediator:OnRegist(  )
end


function MapDetailOverviewMediator:GoogleBack()
    local scene = uiMgr:GetCurrentScene()
	if  scene:GetDialogByTag( 5000 ) then
		scene:RemoveDialogByTag( 5000 )
        return false
	end
    return true
end

function MapDetailOverviewMediator:OnUnRegist(  )
	--称出命令
	local scene = uiMgr:GetCurrentScene()
	if self.viewComponent  and (not tolua.isnull(self.viewComponent)) then
		scene:RemoveDialog(self.viewComponent)
	end

end

return MapDetailOverviewMediator
