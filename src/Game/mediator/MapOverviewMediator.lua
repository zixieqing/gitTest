local Mediator = mvc.Mediator

local MapOverviewMediator = class("MapOverviewMediator", Mediator)


local NAME = "MapOverviewMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function MapOverviewMediator:ctor( viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.str = ''
end

function MapOverviewMediator:InterestSignals()
	local signals = {
	}

	return signals
end

function MapOverviewMediator:ProcessSignal(signal )
	local name = signal:GetName()
	print(name)
end


function MapOverviewMediator:Initial( key )
	self.super.Initial(self,key)
    local viewComponent = uiMgr:SwitchToTargetScene('Game.views.MapOverView')
	self:SetViewComponent(viewComponent)

	-- backBtn
	viewComponent.viewData.backBtn:setOnClickScriptHandler(function( sender )
        PlayAudioByClickNormal()
		AppFacade.GetInstance():BackHomeMediator({showHandbook = true})
	end)
	self.viewData = nil
	self.viewData = viewComponent.viewData


	local datas = CommonUtils.GetConfigAllMess('world', 'collection')
	for k,v in pairs(datas) do
		if checkint(v.areaId) == 999 then
			self.str = self.str..v.descr
		end
	end

	-- local scrollView = self.viewData.scrollView
	-- local desLabel = self.viewData.desLabel
	-- desLabel:setString(self.str)
 --    scrollView:setContainerSize(cc.size(scrollView:getContentSize().width, desLabel:getBoundingBox().height+20))
 --    desLabel:setPositionY(scrollView:getContainerSize().height - 5)
 --    scrollView:setContentOffsetToTop()

 	self.viewData.historyBtn:setOnClickScriptHandler(function( sender )
        PlayAudioByClickNormal()
 		self:CheckOpenHistoryUI( )
 	end)


	local key = string.format('MapOverviewMediator_%s', tostring(gameMgr:GetUserInfo().playerId))
 	if not cc.UserDefault:getInstance():getBoolForKey(key) then
	 	cc.UserDefault:getInstance():setBoolForKey(key, true)
	 	self:CheckOpenHistoryUI( )
	end
end


function MapOverviewMediator:CheckOpenHistoryUI(  )
	local scene = uiMgr:GetCurrentScene()
	if  scene:GetDialogByTag( 5000 ) then
		scene:RemoveDialogByTag( 5000 )
	end

	local layer = require('Game.views.MapDetailMessView').new()
	layer:setTag(5000)

	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = display.center})
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(layer)
	local viewData = layer.viewData_
	layer.eaterLayer:setOnClickScriptHandler(function()
		scene:RemoveDialog(layer)
	end)


	viewData.title:getLabel():setString(__('历史'))
    -- local lineNo = 18
    -- local lines = math.floor((utf8len(self.str) + lineNo - 1) / lineNo)
    -- local h = (lines * 26 + (lines - 1) * 10)
	local descrLabel = display.newLabel(230, 0, {ap = cc.p(0.5, 0), w = 440, text = self.str, color = '#5b3c25', fontSize = 24, noScale = true,ttf = true, font = TTF_TEXT_FONT})
    local h = descrLabel:getContentSize().height
	local descrCell = CLayout:create(cc.size(460, h + 20))
	descrCell:addChild(descrLabel)
	viewData.listView:insertNodeAtLast(descrCell)
	local placeholderCell = CLayout:create(cc.size(460, 120))
	viewData.listView:insertNodeAtLast(placeholderCell)
	viewData.listView:setContentOffsetToTop()
	viewData.listView:reloadData()
end

--[[
@param sender button对象 MapDetailOverviewMediator
--]]
function MapOverviewMediator:CityButtonsCallBack( sender )
	local id = sender:getTag()
    local newestAreaId = checkint(gameMgr.userInfo.newestAreaId)

    if id > newestAreaId then
    	uiMgr:ShowInformationTips(__('该地区尚未到访过，请先前往解锁该地区'))
    else
		local FriendMediator = require( 'Game.mediator.MapDetailOverviewMediator' )
		local mediator = FriendMediator.new(id)
		self:GetFacade():RegistMediator(mediator)
    end
end

function MapOverviewMediator:OnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    local newestAreaId = checkint(gameMgr.userInfo.newestAreaId)
    local tempButton = nil
    for id,button in pairs(self.viewData.cityButtons) do
    	button:setOnClickScriptHandler(handler(self,self.CityButtonsCallBack))
        if checkint(id) > newestAreaId then
            --锁定的点
            button:setNormalImage(_res('ui/world/global_bg_name_area_lock'))
            button:setSelectedImage(_res('ui/world/global_bg_name_area_lock'))
             display.commonLabelParams(button,fontWithColor(6))
        else
            button:setNormalImage(_res('ui/world/global_bg_name_city_selected'))
            button:setSelectedImage(_res('ui/world/global_bg_name_city_selected'))
            display.commonLabelParams(button,fontWithColor(16))
            if checkint(id) == newestAreaId then
            	tempButton = button
            end
        end
    end
    local scene = uiMgr:GetCurrentScene()
   	scene:AddViewForNoTouch()
   	self.viewData.maskImg:setOpacity(0)
	self.viewData.bottomView:setScale(0.5)
    self.viewData.bottomView:runAction(cc.Sequence:create(
    cc.DelayTime:create(0.5),
	cc.Spawn:create(
		cc.CallFunc:create(function( )
			self.viewData.maskImg:runAction(cc.FadeTo:create(0.7,255))
		end),
		cc.ScaleTo:create(0.7, 1),
		cc.CallFunc:create(function ()
			if tempButton then
		       	local x,y = tempButton:getPosition()

		        local contentSize = self.viewData.mapScrollView:getContainerSize()
		        local p0 = utils.getLocalCenter(self.viewComponent)
		        local p1 = cc.p(x, y)
		        local p2 = self.viewData.mapScrollView:getContentOffset()
		        local deltaX = math.abs(p0.x - p2.x)
		        local deltaY = math.abs(p0.y - p2.y)
		        local x = p1.x - deltaX
		        local y = p1.y - deltaY
		        local tx,ty = p2.x,p2.y
		        if deltaX >= p0.x then
		            tx = p2.x - x
		        elseif deltaX < p0.x then
		            tx = p2.x + x
		        end
		        if deltaY >= p0.y then
		            ty = p2.y - y
		        elseif deltaY < p0.y then
		            ty = p2.y + y
		        end
		        self.viewData.mapScrollView:setContentOffsetInDuration(cc.p(tx,ty),0.7)
			end
			scene:RemoveViewForNoTouch()
	end))))
end

function MapOverviewMediator:GoogleBack()
    local scene = uiMgr:GetCurrentScene()
    if scene:GetDialogByTag( 5000 ) then
        scene:RemoveDialogByTag( 5000 )
        return false
    end
    return true
end

function MapOverviewMediator:OnUnRegist(  )
	--称出命令
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    local scene = uiMgr:GetCurrentScene()
    if  scene:GetDialogByTag( 5000 ) then
        scene:RemoveDialogByTag( 5000 )
    end
end

return MapOverviewMediator
