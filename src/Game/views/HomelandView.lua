local GameScene = require('Frame.GameScene')
local HomelandView = class('HomelandView', GameScene)

local RemindIcon     = require('common.RemindIcon')
local RES_DICT = {
	HOME_BG             = _res('ui/home/homeland/management_home_bg.jpg'),
	ICO_LOCK            = _res('ui/common/common_ico_lock.png'),
	HOME_NAME_BG        = _res('ui/home/homeland/management_home_name_bg.png'),
	BTN_PRIVATE_ROOM    = _res('ui/home/homeland/management_home_btn_box_1.png'),
	BTN_RESTAURANT      = _res('ui/home/homeland/management_home_btn_restaurant_1.png'),
	BTN_WATER_BAR       = _res('ui/home/homeland/management_home_btn_bar_1.png'),
	BTN_CAT_HOUSE       = _res('ui/home/homeland/management_home_btn_cat.png'),
	BTN_FISHING         = _res('ui/home/homeland/management_home_btn_fishing_1.png'),
	HOME_NAME_BG_UNLOCK = _res('ui/home/homeland/management_home_name_bg_unlock.png') ,
	COMMON_TITLE        = _res('ui/common/common_title.png'),
	COMMON_BTN_BACK     = _res("ui/common/common_btn_back"),
    IMG_TIPS            = _res('ui/common/common_btn_tips.png'),
}
--[[
　　---@Description:
　　---@param : params { playerId ： 玩家的id }
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/29 4:51 PM
--]]
function HomelandView:ctor(params )
	GameScene.ctor(self,'views.HomelandView')
	params = params or  {}
	self.isMySelf = CommonUtils.JuageMySelfOperation(params.playerId)
	self:InitUI()
end

function HomelandView:InitUI(  )
    -- local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 100))
    -- eaterLayer:setTouchEnabled(true)
    -- eaterLayer:setContentSize(display.size)
    -- eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
    -- eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
    -- self:addChild(eaterLayer, -1)

	local function CreateView()
		local view = CLayout:create(display.size)
        view:setAnchorPoint(cc.p(0, 0))
		view:setName('view')
		self:addChild(view, 1)
		local bg = display.newImageView(RES_DICT.HOME_BG, display.cx, display.cy)
        self:addChild(bg)
		-- title bar
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.size.height,{n = RES_DICT.COMMON_TITLE,ap = cc.p(0, 1.0)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('家园'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
		self:addChild(tabNameLabel,10)
        -- tips
        local tipsBtn = display.newButton(tabNameLabel:getContentSize().width - 50, tabNameLabel:getContentSize().height/2 - 10, {n = RES_DICT.IMG_TIPS})
        tabNameLabel:addChild(tipsBtn, 10)
		local tabNameLabelPos = cc.p(tabNameLabel:getPosition())
		tabNameLabel:setPositionY(display.height + 100)
		local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
		tabNameLabel:runAction( action )
		-- back button
		local backBtn = display.newButton(0, 0, {n = RES_DICT.COMMON_BTN_BACK })
		backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
		self:addChild(backBtn, 5)
		local moudleTable = {
			{name = __('钓场') , img = RES_DICT.BTN_FISHING      , tag = RemindTag.FISH_GROUP , size = cc.size(200 ,200 ) , bottomHeight = 0  },
			{name = __('餐厅') , img = RES_DICT.BTN_RESTAURANT   , tag = RemindTag.MANAGER    , size = cc.size(536 ,404 ) , bottomHeight = 30 },
			{name = __('包厢') , img = RES_DICT.BTN_PRIVATE_ROOM , tag = RemindTag.BOX_MODULE , size = cc.size(335 ,335 ) , bottomHeight = 10 },
			{name = __('水吧') , img = RES_DICT.BTN_WATER_BAR    , tag = RemindTag.WATER_BAR  , size = cc.size(335 ,335 ) , bottomHeight = 10 },
			{name = __('御屋') , img = RES_DICT.BTN_CAT_HOUSE    , tag = RemindTag.CAT_HOUSE  , size = cc.size(335 ,335 ) , bottomHeight = 10 },
		}

		local createMouleBtn = function(data)
			local moudleSize = data.size
			local mouldeBtn =CButton:create()
			mouldeBtn:setContentSize(moudleSize)
			mouldeBtn:setAnchorPoint(display.LEFT_BOTTOM)
			local moudleImage = FilteredSpriteWithOne:create(data.img)
			mouldeBtn:addChild(moudleImage)
			moudleImage:setName("moudleImage")
			moudleImage:setPosition(moudleSize.width/2 , moudleSize.height/2)
			local moudleImageSize = moudleImage:getContentSize()
			local moudleNameBtn = display.newButton(moudleImageSize.width /2 , data.bottomHeight , {ap = display.CENTER_BOTTOM , n =  RES_DICT.HOME_NAME_BG  } )
			moudleImage:addChild(moudleNameBtn)
			moudleImage:setCascadeOpacityEnabled(true)
			moudleNameBtn:setCascadeOpacityEnabled(true)
			display.commonLabelParams(moudleNameBtn , fontWithColor(14,{color = "#5b3c25", fontSize =22 ,  text = data.name , outline = false}))
			moudleNameBtn:setName("moudleNameBtn")
			
			local moudleNameBtnSize = moudleNameBtn:getContentSize()
			moudleNameBtn:getLabel():setPosition(moudleNameBtnSize.width/2 , moudleNameBtnSize.height /2 -5 )
			local  moudleNameBlock = display.newImageView(RES_DICT.HOME_NAME_BG_UNLOCK ,  moudleNameBtnSize.width/2 ,moudleNameBtnSize.height/2)
			moudleNameBtn:addChild(moudleNameBlock,9)
			moudleNameBlock:setName("moudleNameBlock")
			moudleNameBlock:setVisible(false)
			local lockBtn = display.newImageView(RES_DICT.ICO_LOCK,moudleNameBtnSize.width/2, moudleNameBtnSize.height/2 )
			lockBtn:setName("lockBtn")
			lockBtn:setVisible(false)
			moudleNameBtn:addChild(lockBtn,10)
			if self.isMySelf  then
				RemindIcon.addRemindIcon({parent = mouldeBtn, tag = data.tag, po = cc.p(moudleSize.width/2 + 40, moudleSize.height/2 + 28)})
			end
			-- debug use
			-- mouldeBtn:addChild(display.newLayer(0,0,{size = moudleSize, color = cc.r4b(150)})) 
			mouldeBtn.moduleName = tostring(data.name)
			return mouldeBtn
		end
		local designWithMiddle =  667 
		local designHightMiddle = 375 

		-- fishing
		local fishingGroundBtn = createMouleBtn(moudleTable[1])
		view:addChild(fishingGroundBtn)
		fishingGroundBtn:setPosition(display.cx+280 , display.cy - 300 )

		-- restaurant
		local restaurantBtn = createMouleBtn(moudleTable[2])
		view:addChild(restaurantBtn)
		restaurantBtn:setPosition(display.cx + 151 -  designWithMiddle   , display.cy + 351 -   designHightMiddle)

		-- privateRoom
		local boxBtn = createMouleBtn(moudleTable[3])
		view:addChild(boxBtn)
		boxBtn:setPosition(display.cx + 635 -  designWithMiddle   , display.cy + 184 -   designHightMiddle)

		-- waterBar
		local waterBarBtn = createMouleBtn(moudleTable[4])
		view:addChild(waterBarBtn)
		waterBarBtn:setPosition(display.cx + 935 -  designWithMiddle   , display.cy + 350 -   designHightMiddle)

		-- catHouseBtn
		local catHouseBtn = createMouleBtn(moudleTable[5])
		view:addChild(catHouseBtn)
		catHouseBtn:setPosition(display.cx + 200 -  designWithMiddle   , display.cy + 50 -   designHightMiddle)

		return {
			view             = view,
			fishingGroundBtn = fishingGroundBtn,
			restaurantBtn    = restaurantBtn,
			waterBarBtn      = waterBarBtn,
			catHouseBtn      = catHouseBtn,
			boxBtn           = boxBtn,
			backBtn          = backBtn,
			bg               = bg,
			tabNameLabel	 = tabNameLabel,
		}
	end
	xTry(function ( )
		self.viewData = CreateView()

        self.viewData.tabNameLabel:setOnClickScriptHandler(function( sender )
            AppFacade.GetInstance():GetManager("UIManager"):ShowIntroPopup({moduleId = JUMP_MODULE_DATA.HOME_LAND})
        end)
	end, __G__TRACKBACK__)
end

return HomelandView
