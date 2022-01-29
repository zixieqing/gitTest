--[[
摇钱树 MoneyTreeView
--]]
local GameScene = require( 'Frame.GameScene' )
local MoneyTreeView = class('MoneyTreeView', GameScene)
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local SKILL = 'skill1'

local getBuyGoldLimit = function ()
	return CommonUtils.getVipTotalLimitByField('buyGoldLimit')
end

function MoneyTreeView:ctor( ... )
    local arg = unpack({...})
    self.name = "Game.Views.MoneyTreeView"
    self.args = arg
    self.callback = arg.callback or nil
    self.backCallback = arg.backCallback or nil
 	self.showSpAction = false
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 180))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	eaterLayer:setPosition(cc.p(display.cx, display.height))
	self:addChild(eaterLayer, -1)
	eaterLayer:setOnClickScriptHandler(function (sender)
        eaterLayer:setTouchEnabled(false)
		if self.backCallback then
			self.backCallback()
		end
		self:close()
	end)
	self.eaterLayer = eaterLayer


	local function CreateView( ... )
		local view = display.newLayer(0, 0, {ap = display.CENTER})
		view:setContentSize(display.size)
		local bgSize = view:getContentSize()
		self:addChild(view)

		-- local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
		-- display.commonUIParams(backBtn, {po = cc.p(backBtn:getContentSize().width * 0.5 + 30, display.size.height - 18 - backBtn:getContentSize().height * 0.5)})
		-- view:addChild(backBtn)

		local spMoneyTree = sp.SkeletonAnimation:create('effects/moneyTree/moneyTree.json', 'effects/moneyTree/moneyTree.atlas', 1)
	    spMoneyTree:update(0)
	    spMoneyTree:setAnimation(0, 'idle', true)--idle  end open open2 play
	    spMoneyTree:setPosition(cc.p(display.size.width * 0.5, display.size.width * 0.18))
	    view:addChild(spMoneyTree,1)


		local spHero = AssetsUtils.GetCardSpineNode({confId = CARDID_TANGHULU, scale = 0.5})
	    spHero:update(0)
	    spHero:setAnimation(0, 'idle', true)--idle  end open open2 play
	    spHero:setPosition(cc.p(display.size.width * 0.36, display.size.width * 0.27))
	    view:addChild(spHero,2)


		local tempBtn = display.newButton(0, 0, {n = _res("ui/home/moneyTree/gold_egg_bg_shardow.png")})
		display.commonUIParams(tempBtn, {po = cc.p(display.size.width * 0.5, spMoneyTree:getPositionY() + 25 )})

	    display.commonLabelParams(tempBtn,{fontSize = 20, color = '#ffffff', text = __('你等级越高，你获得的金币也越多哦！' ), w = 440 , hAlign = display.TAC})
	    view:addChild(tempBtn)


		local buyBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_orange.png")})
		display.commonUIParams(buyBtn, {po = cc.p(display.size.width * 0.5, tempBtn:getPositionY() - 80)})
	    display.commonLabelParams(buyBtn,fontWithColor(14,{text =  '',offset = cc.p(-25,0)}))
	    view:addChild(buyBtn)

	    local freeLabel = display.newLabel(buyBtn:getContentSize().width*0.5, buyBtn:getContentSize().height*0.5,
	  		{text = __('免费'), fontSize = 22, color = 'ffffff', ttf = true, font = TTF_GAME_FONT})
	  	freeLabel:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	  	buyBtn:addChild(freeLabel)
	  	freeLabel:setVisible(false)

	    local payMoney = display.newImageView(_res('arts/goods/goods_icon_'..DIAMOND_ID..'.png'))
	    payMoney:setScale(0.25)
	    payMoney:setPosition(cc.p(90,buyBtn:getContentSize().height * 0.5))
	    buyBtn:addChild(payMoney)


	    -- local leftLabel = display.newLabel(display.size.width * 0.5  + 120, buyBtn:getPositionY() - 50,
   	 --  		{text = '', fontSize = 22, color = 'ffffff', ttf = true, font = TTF_GAME_FONT})
   	 --  	leftLabel:enableOutline(cc.c4b(0, 0, 0, 255), 1)
   	 --  	view:addChild(leftLabel)

		local leftLabel = display.newRichLabel(display.size.width * 0.5 , buyBtn:getPositionY() - 84,{ap = cc.p(0.5,0.5),c = {
					fontWithColor(10,{text = __('剩余砸蛋次数：'),fontSize = 22, color = 'f3c7a9', ttf = true, font = TTF_GAME_FONT}),
					fontWithColor(10,{text = "0",fontSize = 22, color = 'ffffff', ttf = true, font = TTF_GAME_FONT}),
					fontWithColor(10,{text = __('次'),fontSize = 22, color = 'f3c7a9', ttf = true, font = TTF_GAME_FONT})
				}})
		-- leftFreeLabel:reloadData()
		view:addChild(leftLabel)



		local leftFreeLabel = display.newRichLabel(display.size.width * 0.5 , buyBtn:getPositionY() - 50,{ap = cc.p(0.5,0.5),c = {
					fontWithColor(10,{text = __('今日免费次数：'),fontSize = 22, color = 'f3c7a9', ttf = true, font = TTF_GAME_FONT}),
					fontWithColor(10,{text = "0",fontSize = 22, color = 'ffffff', ttf = true, font = TTF_GAME_FONT})
				}})
		leftFreeLabel:reloadData()
		view:addChild(leftFreeLabel)
		-- captainDesLabel:setVisible(false)


		return {
			view        = view,
			-- backBtn		= backBtn,
			spMoneyTree = spMoneyTree,
			buyBtn 		= buyBtn,
			payMoney 	= payMoney,
			leftLabel 	= leftLabel,
			spHero 		= spHero,
			leftFreeLabel = leftFreeLabel,
			freeLabel = freeLabel,
		}
	end

	self.viewData_ = CreateView()
	display.commonUIParams(self.viewData_.view, {po = display.center})
	self.viewData_.buyBtn:setOnClickScriptHandler(function (sender)
		-- self.showSpAction = true
        -- self:UpdataUi({nums = 5000})
        if gameMgr:GetUserInfo().buyGoldRestTimes > 0 then
            local leftFreeNum = 0
            for k,v in pairs(gameMgr:GetUserInfo().freeGoldLeftTimes) do
                leftFreeNum = leftFreeNum + checkint(v)
            end
            if leftFreeNum > 0 then
                if self.callback then
                    self.viewData_.buyBtn:setTouchEnabled(false)
                    self.showSpAction = true
                    local scene = uiMgr:GetCurrentScene()
                    scene:AddViewForNoTouch()
                    self.callback()
                end
            else
                local needDiamond = (math.ceil((getBuyGoldLimit() - gameMgr:GetUserInfo().buyGoldRestTimes)/3.0) - 1) * 5 + 10
                if gameMgr:GetUserInfo().diamond >= needDiamond then
                    if self.callback then
                        self.viewData_.buyBtn:setTouchEnabled(false)
                        self.showSpAction = true
                        local scene = uiMgr:GetCurrentScene()
                        scene:AddViewForNoTouch()
                        self.callback()
                    end
				else
					if GAME_MODULE_OPEN.NEW_STORE then
						app.uiMgr:showDiamonTips(nil, nil, function()
							self:close()
						end)
					else
						local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('幻晶石不足是否去商城购买？'),
							isOnlyOK = false, callback = function ()
								app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
							end})
						CommonTip:setPosition(display.center)
						app.uiMgr:GetCurrentScene():AddDialog(CommonTip)
					end
                end
            end
        else
            uiMgr:ShowInformationTips(__('次数已用完'))
        end
	end)
	self:UpdataUi()
end

local checkGoldNum = {
	['2'] = 2,
	['5'] = 2,
	['10'] = 2,
}

function MoneyTreeView:UpdataUi(updatauiCallback)
	-- dump(gameMgr:GetUserInfo().freeGoldLeftTimes)
	-- dump(gameMgr:GetUserInfo().member)
	local needLabel = self.viewData_.buyBtn:getLabel()
	local leftLabel = self.viewData_.leftLabel
	local leftFreeLabel = self.viewData_.leftFreeLabel
	local spMoneyTree = self.viewData_.spMoneyTree
	local spHero = self.viewData_.spHero
	local freeLabel = self.viewData_.freeLabel
	local payMoney = self.viewData_.payMoney
	local buyLabel = self.viewData_.buyBtn:getLabel()

	-- local limitData  = CommonUtils.GetConfig('player', 'vip',1)


	local leftFreeNum = 0
	for k,v in pairs(gameMgr:GetUserInfo().freeGoldLeftTimes) do
		leftFreeNum = leftFreeNum + checkint(v)
	end

	if leftFreeNum > 0 then
		freeLabel:setVisible(true)
		payMoney:setVisible(false)
		buyLabel:setVisible(false)
	else
		freeLabel:setVisible(false)
		payMoney:setVisible(true)
		buyLabel:setVisible(true)
	end

	if self.showSpAction == true then
		AppFacade.GetInstance():DispatchObservers(GET_MONEY_CALLBACK)
		self.showSpAction = false

		local str = SKILL
		spHero:setToSetupPose()
		spHero:setAnimation(0, str, false)
		spHero:registerSpineEventHandler(function (event)
			if event.animation == str then
				local num = string.format("%0.2f", math.floor(checkint(gameMgr:GetUserInfo().level) * 100 / 30) / 100)
				local getGold = tonumber(num) * 10000 * math.floor(checkint(gameMgr:GetUserInfo().level) / 30) + 15000
				local str = 'play'
				local nums = 1
				if updatauiCallback.nums then
					local x = checkint(updatauiCallback.nums / getGold)
					if checkGoldNum[tostring(x)] then
						str = str..'x'..x
						nums = checkint(x)
					end
				end
				spMoneyTree:setToSetupPose()
				spMoneyTree:setAnimation(0, str, false)

			end
		end,sp.EventType.ANIMATION_EVENT)

		spHero:registerSpineEventHandler(function (event)
			if event.animation == str then
				-- spHero:setToSetupPose()
				spHero:setAnimation(0, 'idle', true)
			end
		end,sp.EventType.ANIMATION_COMPLETE)


		spMoneyTree:registerSpineEventHandler(function (event)
			if event.animation == "play" or event.animation == "playx2" or event.animation == "playx5" or event.animation == "playx10" then
				local num = string.format("%0.2f", math.floor(checkint(gameMgr:GetUserInfo().level) * 100 / 30) / 100)

				local getGold = tonumber(num) * 10000 * math.floor(checkint(gameMgr:GetUserInfo().level) / 30) + 15000
				local nums = 1
				if updatauiCallback.nums then
					local x = checkint(updatauiCallback.nums / getGold)
					if checkGoldNum[tostring(x)] then
						nums = checkint(x)
					end
				end
				uiMgr:ShowInformationTips(string.fmt(__('恭喜获得金币__gold__'),{__gold__ = getGold*nums}))

				local posTab = {
					cc.p(0,60),
					cc.p(-20,30),
					cc.p(25,30),
					cc.p(-30,-30),
					cc.p(30,-30),
					cc.p(math.random(10),math.random(90)),
					cc.p(math.random(30),math.random(70)),
					cc.p(math.random(50),math.random(50)),
					cc.p(math.random(70),math.random(30)),
					cc.p(math.random(90),math.random(10))
				}

				-- local point = spMoneyTree:convertToWorldSpace(utils.getLocalCenter(spMoneyTree))
				local point = cc.p(display.size.width * 0.55, display.size.width * 0.35)
				local scene = uiMgr:GetCurrentScene()
				for i=1,table.nums(posTab) do
					local iconPath = CommonUtils.GetGoodsIconPathById(GOLD_ID)
					local img= display.newImageView(_res(iconPath),0,0,{as = false})

					img:setPosition(point)
					img:setTag(555)
					scene:AddDialog(img,10)

				 	--    local particle = cc.ParticleSystemQuad:create('effects/jinbi.plist')
				 	--    particle:setAutoRemoveOnFinish(true)
				 	--    particle:setPosition(cc.p(img:getContentSize().width* 0.5,img:getContentSize().height* 0.5))
					--    img:addChild(particle,10)
					local scale = 0.4
					if tostring(self.useId) == '120002' or tostring(self.useId) == '120004' then
						scale = 0.3
					end
					img:setScale(0)
					local actionSeq = cc.Sequence:create(
						cc.Spawn:create(
							cc.ScaleTo:create(0.2, scale),
							cc.MoveBy:create(0.3,posTab[i])
							),
						cc.MoveBy:create(0.1+i*0.11,cc.p(math.random(15),math.random(15))),
						cc.DelayTime:create(i*0.01),
						cc.Spawn:create(
							cc.MoveTo:create(0.4,cc.p(display.width - 400,display.height - 50) ),
							cc.ScaleTo:create(0.4, 0.2)
							),
						cc.CallFunc:create(function ()
								if i == table.nums(posTab) then
									if updatauiCallback.updatauiCallback then
                                        updatauiCallback.updatauiCallback()
									end
								end
		          			end),
						cc.RemoveSelf:create())
					img:runAction(actionSeq)
			    end





				spMoneyTree:setToSetupPose()
				spMoneyTree:setAnimation(0, 'open2', false)
				if gameMgr:GetUserInfo().buyGoldRestTimes <= 0 then
				    gameMgr:GetUserInfo().buyGoldRestTimes = 0
				    needLabel:setString('--')
				else
				    local needDiamond = (math.ceil((getBuyGoldLimit()-gameMgr:GetUserInfo().buyGoldRestTimes)/3.0) - 1) * 5 + 10
				    needLabel:setString(tostring(needDiamond))
				end

				display.reloadRichLabel(leftLabel, {c = {
					fontWithColor(10,{text = __('剩余砸蛋次数：'),fontSize = 22, color = 'f3c7a9', ttf = true, font = TTF_GAME_FONT}),
					fontWithColor(10,{text = gameMgr:GetUserInfo().buyGoldRestTimes,fontSize = 22, color = 'ffffff', ttf = true, font = TTF_GAME_FONT}),
					fontWithColor(10,{text = __('次'),fontSize = 22, color = 'f3c7a9', ttf = true, font = TTF_GAME_FONT})}
				})

				display.reloadRichLabel(leftFreeLabel, {c = {
					fontWithColor(10,{text = __('今日免费次数：'),fontSize = 22, color = 'f3c7a9', ttf = true, font = TTF_GAME_FONT}),
					fontWithColor(10,{text = leftFreeNum,fontSize = 22, color = 'ffffff', ttf = true, font = TTF_GAME_FONT})}
				})

			elseif event.animation == "open2" then
				spMoneyTree:setToSetupPose()
				spMoneyTree:setAnimation(0, 'idle', true)
				self.viewData_.buyBtn:setTouchEnabled(true)
				local scene = uiMgr:GetCurrentScene()
    			scene:RemoveViewForNoTouch()
			end
		end,sp.EventType.ANIMATION_COMPLETE)
	else
		if gameMgr:GetUserInfo().buyGoldRestTimes <= 0 then
		    gameMgr:GetUserInfo().buyGoldRestTimes = 0
		    needLabel:setString('--')
		else
		    local needDiamond = (math.ceil((getBuyGoldLimit()-gameMgr:GetUserInfo().buyGoldRestTimes)/3.0) - 1) * 5 + 10
		    needLabel:setString(tostring(needDiamond))
		end
		display.reloadRichLabel(leftLabel, {c = {
			fontWithColor(10,{text =__('剩余砸蛋次数：'),fontSize = 22, color = 'f3c7a9', ttf = true, font = TTF_GAME_FONT}),
			fontWithColor(10,{text = gameMgr:GetUserInfo().buyGoldRestTimes,fontSize = 22, color = 'ffffff', ttf = true, font = TTF_GAME_FONT}),
			fontWithColor(10,{text =__('次'),fontSize = 22, color = 'f3c7a9', ttf = true, font = TTF_GAME_FONT})}
		})


		display.reloadRichLabel(leftFreeLabel, {c = {
			fontWithColor(10,{text =__('今日免费次数：'),fontSize = 22, color = 'f3c7a9', ttf = true, font = TTF_GAME_FONT}),
			fontWithColor(10,{text = leftFreeNum,fontSize = 22, color = 'ffffff', ttf = true, font = TTF_GAME_FONT})}
		})

	end
end


function MoneyTreeView:close()
	self:runAction(cc.RemoveSelf:create())
end

function MoneyTreeView:onEnter()
end

function MoneyTreeView:onExit()
end

return MoneyTreeView
