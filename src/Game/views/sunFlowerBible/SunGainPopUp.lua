--[[
获取途径界面
--]]
---@class SunGainPopUp
local SunGainPopUp    = class('SunGainPopUp', function()
	local clb = CLayout:create(cc.size(display.width, display.height))
	clb.name  = 'common.SunGainPopUp'
	clb:enableNodeEvents()
	return clb
end)
---@type UIManager
local uiMgr        = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr      = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local RES_DICT={
	COMMON_BG_LIST_2                         = _res("ui/common/common_bg_list_2.png"),
	COMMON_BTN_ORANGE                        = _res("ui/common/common_btn_orange.png"),
	COMMON_BTN_ORANGE_DISABLE                = _res("ui/common/common_btn_orange_disable.png"),
	COMMON_BG_FONT_NAME                      = _res("ui/common/common_bg_font_name.png")
}
--[[
]]
local jumpViewData = {
	[JUMP_MODULE_DATA.NORMAL_MAP]           = {
		['jumpView'] = 'MapMediator',
	},
	[JUMP_MODULE_DATA.DIFFICULTY_MAP]       = {
		['jumpView'] = 'MapMediator',
	},
	[JUMP_MODULE_DATA.TEAM_MAP]             = {
		['jumpView'] = 'MapMediator',
	},
	[JUMP_MODULE_DATA.RESEARCH]             = {
		['jumpView']    = 'RecipeDetailMediator',
		['jumpViewTwo'] = {  -- 如果不满足当前条件 需跳转到其他的界面
			['jumpView'] = 'RecipeResearchAndMakingMediator',
			['needData'] = { presStyleTag = 1002 }
		}
	},
	[JUMP_MODULE_DATA.RESTAURANT]           = {
		['jumpView'] = 'AvatarMediator',
		-- ['firstLayer']  = 1003,
	},
	[JUMP_MODULE_DATA.TAKEWAY]              = {
		['jumpView'] = '1',
		['jumpDes']  = __('返回主界面看看有什么可以发送的外卖吧')
	},
	[JUMP_MODULE_DATA.EXPLORATIN]           = {
		['jumpView'] = 'ExplorationMediator',
	},
	[JUMP_MODULE_DATA.DAILYTASK]            = {
		['jumpView'] = 'task.TaskHomeMediator',

	},
	[JUMP_MODULE_DATA.CAPSULE]              = {
		['jumpView'] = GAME_MODULE_OPEN.NEW_CAPSULE and 'drawCards.CapsuleNewMediator' or 'drawCards.CapsuleMediator'
	},
	[JUMP_MODULE_DATA.ACTIVITY]             = {
		['jumpView'] = '1',
	},
	[JUMP_MODULE_DATA.GUILD]                = {
		['jumpView'] = 'UnionLobbyMediator',
		['jumpViewTwo'] = {  -- 如果不满足当前条件 需跳转到其他的界面
			['jumpView'] = 'UnionCreateHomeMediator',
		}
	},
	[JUMP_MODULE_DATA.SHOP]                 = {
		['jumpView'] = 'ShopMediator',
	},
	[JUMP_MODULE_DATA.ARENA]                = {
		['jumpView'] = '1',
	},
	[JUMP_MODULE_DATA.PAY]                  = {
		['jumpView'] = 'CumulativeRechargeMediator',
	},
	[JUMP_MODULE_DATA.MONEYTREE]            = {
		['jumpView'] = '1',
	},
	[JUMP_MODULE_DATA.TALENT_BUSSINSS]      = {
		['jumpView'] = 'TalentMediator',
	},
	[JUMP_MODULE_DATA.TALENT_DAMAGE]        = {
		['jumpView'] = 'TalentMediator',
	},
	[JUMP_MODULE_DATA.TALENT_ASSIT]         = {
		['jumpView'] = 'TalentMediator',
	},
	[JUMP_MODULE_DATA.TALENT_CONTROL]       = {
		['jumpView'] = 'TalentMediator',
	},

	[JUMP_MODULE_DATA.HANDBOOK]             = {
		['jumpView'] = '1',
	},

	[JUMP_MODULE_DATA.MARKET]               = {
		['jumpView'] = 'MarketMediator',
	},

	[JUMP_MODULE_DATA.CARBARN]              = {
		['jumpView'] = '1',
	},

	[JUMP_MODULE_DATA.TOWER]                = {
		['jumpView'] = 'TowerQuestHomeMediator',
	},

	[JUMP_MODULE_DATA.PET]                  = {
		['jumpView'] = 'PetDevelopMediator',
	},
	[JUMP_MODULE_DATA.RECIPE_MAKE]          = {
		['jumpView']    = 'RecipeDetailMediator',
		['jumpViewTwo'] = {  -- 如果不满足当前条件 需跳转到其他的界面
			['jumpView'] = 'RecipeResearchAndMakingMediator',
			['needData'] = { presStyleTag = 1002 }
		}
		-- ['sencondLayer']  = 1,
	},
	[JUMP_MODULE_DATA.RECIPE_STUDY]         = {
		['jumpView']    = 'RecipeDetailMediator',
		['jumpViewTwo'] = {  -- 如果不满足当前条件 需跳转到其他的界面
			['jumpView'] = 'RecipeResearchAndMakingMediator',
			['needData'] = { presStyleTag = 1002 }
		}
		-- ['firstLayer']  = 1001,
		-- ['sencondLayer']  = 2,
	},
	[JUMP_MODULE_DATA.RECIPE_MASTER]        = {
		['jumpView']    = 'RecipeDetailMediator',
		['jumpViewTwo'] = {  -- 如果不满足当前条件 需跳转到其他的界面
			['jumpView'] = 'RecipeResearchAndMakingMediator',
			['needData'] = { presStyleTag = 1002 }
		}
		-- ['firstLayer']  = 1001,
		-- ['sencondLayer']  = 3,
	},
	[JUMP_MODULE_DATA.MATERIALCOMPOSE]      = {
		['jumpView'] = 'MaterialComposeMediator',
		['isPopup']  = 1
	},
	[JUMP_MODULE_DATA.CARDSFRAGMENTCOMPOSE] = {
		['jumpView'] = 'CardsFragmentComposeMediator',
		['isPopup']  = 1
	},
	[JUMP_MODULE_DATA.SHOP_TIPS]            = {
		['jumpView'] = 'ShopMediator',
		['jumpData'] = GAME_MODULE_OPEN.NEW_STORE and {storeType = GAME_STORE_TYPE.GROCERY, subType = GAME_STORE_TYPE.RESTAURANT} or { goShopIndex = 'restaurant' }
	},
	[JUMP_MODULE_DATA.AIR_TRANSPORTATION]   = {
		['jumpView'] = 'HomeMediator',
	},
	[JUMP_MODULE_DATA.ACHIEVEMENT]          = {
		['jumpView'] = 'task.TaskHomeMediator',
		['jumpData'] = { clickTag = 1002, isJumpRequest = true }
	},
	[JUMP_MODULE_DATA.MATERIAL_SCRIPT]      = {
		['jumpView'] = 'MaterialTranScriptMediator',
	},
	[JUMP_MODULE_DATA.PROMOTERS]            = {
		['jumpView'] = 'PromotersMediator'
	},
	[JUMP_MODULE_DATA.SKINSHOP]             = {
		['jumpView'] = 'ShopMediator',
		['jumpData'] = GAME_MODULE_OPEN.NEW_STORE and {storeType = GAME_STORE_TYPE.CARD_SKIN} or { goShopIndex = 'cardSkin' },
	},
	[JUMP_MODULE_DATA.PVC_ROYAL_BATTLE]             = {
		['jumpView'] = 'PVCMediator'
	},
	[JUMP_MODULE_DATA.TEAM_BATTLE_SCRIPT]          = {
		['jumpView'] = 'RaidHallMediator'
	},
	[JUMP_MODULE_DATA.UNION_SHOP]          = {
		['jumpView'] = 'UnionShopMediator',
		['jumpData'] = GAME_MODULE_OPEN.NEW_STORE and {storeType = GAME_STORE_TYPE.GROCERY, subType = GAME_STORE_TYPE.UNION} or nil,
	},
	[JUMP_MODULE_DATA.UNION_PARTY]          = {
		['jumpView'] = 'UnionShopMediator'
	},
	[JUMP_MODULE_DATA.DIAMOND_SHOP]          = {
		['jumpView'] = 'ShopMediator',
		['jumpData'] = GAME_MODULE_OPEN.NEW_STORE and {storeType = GAME_STORE_TYPE.DIAMOND} or { goShopIndex = 'diamond' },
	},
	[JUMP_MODULE_DATA.GIFT_SHOP]          = {
		['jumpView'] = 'ShopMediator',
		['jumpData'] = GAME_MODULE_OPEN.NEW_STORE and {storeType = GAME_STORE_TYPE.GIFTS} or { goShopIndex = 'chest' },
	},
	[JUMP_MODULE_DATA.GOODS_SHOP]          = {
		['jumpView'] = 'ShopMediator',
		['jumpData'] = GAME_MODULE_OPEN.NEW_STORE and {storeType = GAME_STORE_TYPE.PROPS} or { goShopIndex = 'goods' },
	},
	[JUMP_MODULE_DATA.MEDAL_SHOP]          = {
		['jumpView'] = 'ShopMediator',
		['jumpData'] = GAME_MODULE_OPEN.NEW_STORE and {storeType = GAME_STORE_TYPE.GROCERY, subType = GAME_STORE_TYPE.PVP_ARENA} or { goShopIndex = 'arena' },
	},
	[JUMP_MODULE_DATA.TASTING_TOUR]          = {
		['jumpView'] = "tastingTour.TastingTourChooseRecipeStyleMediator",
	},
	[JUMP_MODULE_DATA.CARD_GATHER]          = {
		['jumpView'] = "CardGatherRewardMediator",
	},
	[JUMP_MODULE_DATA.SMELTING_PET]  = {
		['jumpView'] = "PetSmeltingMediator"

	},
	[JUMP_MODULE_DATA.TAG_JEWEL_EVOL]  = {
		['jumpView'] = "artifact.JewelEvolutionMediator"
	},
	[JUMP_MODULE_DATA.ARTIFACT_TAG]  = {

	},
	[JUMP_MODULE_DATA.FISHING_GROUND] = {
		['jumpView'] = 'fishing.FishingGroundMediator',
		['jumpData'] = {queryPlayerId = app.gameMgr:GetUserInfo().playerId}
	} ,
	[JUMP_MODULE_DATA.FISHING_SHOP]           = {
		['jumpView'] = "fishing.FishingShopMeditor",
	},
	[JUMP_MODULE_DATA.FISHING_SHOP_ONE]           = {
		['jumpView'] = "fishing.FishingShopMeditor",
		['jumpData'] = { goShopIndex = 1 }
	},
	[JUMP_MODULE_DATA.FISHING_SHOP_TWO]           = {
		['jumpView'] = "fishing.FishingShopMeditor",
		['jumpData'] = { goShopIndex = 2 }
	},
	[JUMP_MODULE_DATA.FISHING_SHOP_THREE]           = {
		['jumpView'] = "fishing.FishingShopMeditor",
		['jumpData'] = { goShopIndex = 3 }
	},

	[JUMP_MODULE_DATA.EXPLORE_SYSTEM]           = {
		['jumpView'] = "exploreSystem.ExploreSystemMediator"
	},
	[JUMP_MODULE_DATA.WATER_BAR_MARKET]           = {
		['jumpView'] = "waterBar.WaterBarMarketMediator"
	},
	[JUMP_MODULE_DATA.WATER_BAR_SHOP]           = {
		['jumpView'] = "waterBar.WaterBarShopMediator"
	},
	[JUMP_MODULE_DATA.MEMORY_STORE]           = {
		['jumpView'] = "stores.MemoryStoreMediator"
	},
	[JUMP_MODULE_DATA.LUNA_TOWER]           = {
		['jumpView'] = "lunaTower.LunaTowerHomeMediator"
	},
	[JUMP_MODULE_DATA.UNION_TASK]           = {
		['jumpView'] = "task.TaskHomeMediator",
		['jumpData'] = { clickTag = 1003, isJumpRequest = true }
	},
	[JUMP_MODULE_DATA.ALL_ROUND]           = {
		['jumpView'] = "allRound.AllRoundHomeMediator"
	},
	[JUMP_MODULE_DATA.BOX]           = {
		['jumpView'] = "privateRoom.PrivateRoomHomeMediator"

	},


}

function SunGainPopUp:ctor(...)
	self.args = unpack({ ... })
	self:setName('common.SunGainPopUp')
	PlayAudioClip(AUDIOS.UI.ui_window_open.id)

	self.id      = self.args.id
	local strongerOneConf = CONF.SUN_FLOWR.STRONGER:GetValue(self.id)
	self.goodsId = strongerOneConf.goodsId
	self.datas        = CommonUtils.GetConfig('goods', 'goods', self.goodsId)
	-- dump(self.datas)
	-- ui
	self.selectTable  = {} -- 当前选中的好友
	self.bgLayer      = nil
	self.bgImg        = nil
	self.rewardBg     = nil
	self.friendList   = nil
	self.cd           = nil
	self.cell         = nil

	local contentView = CColorView:create(cc.c4b(0, 0, 0, 100))
	contentView:setContentSize(display.size)
	contentView:setOnClickScriptHandler(function(sender)
		self:runAction(cc.RemoveSelf:create())
	end)
	contentView:setTouchEnabled(true)
	display.commonUIParams(contentView, { po = display.center })
	self:addChild(contentView, -1)

	-- bg
	local bgImg   = display.newImageView(_res('ui/common/common_bg_3.png'))
	self.bgImg    = bgImg
	local bgSize  = bgImg:getContentSize()
	local bgLayer = display.newLayer(utils.getLocalCenter(self).x, utils.getLocalCenter(self).y, { size = bgSize, ap = cc.p(0.5, 0.5) })
	bgLayer:addChild(bgImg, 5)
	display.commonUIParams(bgImg, { po = cc.p(bgSize.width * 0.5, bgSize.height * 0.5) })
	self:addChild(bgLayer)
	local cover = CColorView:create(cc.c4b(0, 0, 0, 0))
	cover:setTouchEnabled(true)
	cover:setContentSize(bgSize)
	cover:setAnchorPoint(cc.p(0, 0))
	bgLayer:addChild(cover, -1)
	self.bgLayer = bgLayer
	-- 顶部背景
	local bgUp   = display.newButton(bgSize.width * 0.5, bgSize.height - 3,
									 { n = _res('ui/common/common_bg_title_2.png'), ap = cc.p(0.5, 1), enable = false })
	bgLayer:addChild(bgUp, 10)
	display.commonLabelParams(bgUp, { text = __('获取途径'), fontSize = 22, color = '#ffffff' })

	-- 图标背景
	if not self.datas or not self.datas.id then return end
	local iconBg = display.newImageView(_res(string.format('ui/common/common_frame_goods_' .. (self.datas.quality or 1) .. '.png')), bgSize.width * 0.2, bgSize.height * 0.8)
	bgLayer:addChild(iconBg, 10)
	local scaleValue = 0.55
	-- 物品icon
	local iconPath = CommonUtils.GetGoodsIconPathById(self.datas.id)
	local iconImg  = display.newImageView(iconPath, bgSize.width * 0.2, bgSize.height * 0.8)

	iconImg:setScale(scaleValue)
	bgLayer:addChild(iconImg, 11)

	-- 物品名称
	local goodName = display.newLabel(bgSize.width * 0.33, bgSize.height * 0.885,
									  { text = tostring(self.datas.name), fontSize = 22, color = '#ba5c5c', ap = cc.p(0, 1) })
	bgLayer:addChild(goodName, 10)

	-- 物品描述
	local goodDescr = display.newLabel(bgSize.width * 0.33, bgSize.height * 0.83,
									   { text = tostring(self.datas.descr or ' '), fontSize = 20, color = '#6c6c6c', ap = cc.p(0, 1), w = 320 })
	bgLayer:addChild(goodDescr, 10)

	-- 数量
	local numLabel = display.newRichLabel(bgSize.width * 0.115, bgSize.height * 0.71, { c                               = {
		{ text = __('拥有：'), fontSize = 20, color = '#6c6c6c' },
		{ text = tostring(checkint(gameMgr:GetAmountByGoodId(self.datas.id))), fontSize = 20, color = '#ba5c5c' } }, ap = cc.p(0, 1), r = true })
	bgLayer:addChild(numLabel, 10)

	-- 途径
	local wayLabel = display.newLabel(bgSize.width * 0.5, bgSize.height * 0.62,
									  { text = __('通过以下几种途径可以获取'), fontSize = 20, color = '#5b3c25' })
	bgLayer:addChild(wayLabel, 10)

	-- 列表背景
	local listBg = display.newImageView(_res('ui/home/gain/gain_bg_frame_gray_1.png'), bgSize.width * 0.5, bgSize.height * 0.31,
										{})
	bgLayer:addChild(listBg, 10)
	self.listBg = listBg

	-- 途径列表
	local listBgFrameSize        = listBg:getContentSize()
	local gainListSize     = cc.size(listBgFrameSize.width, listBgFrameSize.height)
	local gainListView     = CListView:create(gainListSize)
	gainListView:setDirection(eScrollViewDirectionVertical)
	gainListView:setBounceable(true)
	bgLayer:addChild(gainListView, 10)
	gainListView:setAnchorPoint(cc.p(0.5, 0))
	gainListView:setPosition(cc.p(bgSize.width * 0.5+5, 17))
	self.gainListView = gainListView
	self:InitListView()
end
function SunGainPopUp:InitListView()
	local strongerConf = CONF.SUN_FLOWR.STRONGER:GetValue(self.id)
	local openId = strongerConf.openId
	local unopenId = strongerConf.unopenId
	for index, value in pairs(openId) do
		if  CommonUtils.UnLockModule(value)  then
			local isIn = false
			for i, value2 in pairs(unopenId) do
				if checkint(value2) == checkint(value) then
					isIn = true
					break
				end
			end

			local cell = self:CreateCellLayout()
			self.gainListView:insertNodeAtLast(cell)
			self:UpdateCellLayout(cell, value , not isIn )
		end
	end
	self.gainListView:reloadData()
end
function SunGainPopUp:CreateCellLayout()
	local cellLayout = display.newLayer(display.cx + -1, display.cy  + 1 ,{ap = display.CENTER,size = cc.size(493,102)})
	local bgImage = display.newImageView( RES_DICT.COMMON_BG_LIST_2 ,247.5, 50,{ap = display.CENTER})
	cellLayout:addChild(bgImage,0)
	local gotoBtn = display.newButton(400.5, 56 , {n = RES_DICT.COMMON_BTN_ORANGE,ap = display.CENTER,scale9 = true,size = cc.size(123,59)})
	cellLayout:addChild(gotoBtn,0)
	display.commonLabelParams(gotoBtn ,fontWithColor(14 , {fontSize = 20,text = __('前往'),color = '#ffffff',paddingW  = 20,safeW = 83}))
	local titleBgImage = display.newImageView( RES_DICT.COMMON_BG_FONT_NAME ,85.5, 78,{ap = display.CENTER})
	cellLayout:addChild(titleBgImage,0)
	local titleDescrLabel = display.newLabel(8.5, 35 , {fontSize = 20,text = '',color = '#6c6c6c', w = 300 , ap = display.LEFT_CENTER})
	cellLayout:addChild(titleDescrLabel,0)
	local titleLabel = display.newLabel(8.5, 79 , {fontSize = 22,text = '',color = '#502f0d',ap = display.LEFT_CENTER})
	cellLayout:addChild(titleLabel,0)
	local unlockLabel = display.newLabel(403, 19 , {fontSize = 20,text = '',color = '#BA5C3C',ap = display.CENTER})
	cellLayout:addChild(unlockLabel,0)
	cellLayout.viewData = {
		cellLayout                = cellLayout,
		bgImage                   = bgImage,
		gotoBtn                   = gotoBtn,
		titleBgImage              = titleBgImage,
		titleDescrLabel           = titleDescrLabel,
		titleLabel                = titleLabel,
		unlockLabel               = unlockLabel
	}
	return cellLayout
end
function SunGainPopUp:UpdateCellLayout(cell ,  openId , isGoTo)
	local strongerJumpConf = CONF.SUN_FLOWR.STRONGER_JUMP:GetValue(openId)
	local name             = strongerJumpConf.name
	local descr            = strongerJumpConf.descr
	local openType         = tostring(strongerJumpConf.openType)
	local moduleConf       = CommonUtils.GetGameModuleConf()[tostring(openType)] or {}
	local openLevel        = checkint(moduleConf.openLevel)
	local cellLayout       = cell
	local viewData   = cellLayout.viewData
	viewData.gotoBtn:setVisible(isGoTo)
	if CommonUtils.GetJumpModuleAvailable(openType) and (not isGoTo) then
		if openType == JUMP_MODULE_DATA.NORMAL_MAP or openType == JUMP_MODULE_DATA.DIFFICULTY_MAP or openType == JUMP_MODULE_DATA.TEAM_MAP then
			--关卡系列能获得
			if self.datas.dropQuests then
				for i, vv in pairs(self.datas.dropQuests) do
					--可获得改物品的关卡id

					-- tempTab.exploreAreaFixedPointId = 0
					local canAdded = 1
					local tempStr  = ''
					if CommonUtils.GetConfig('quest', 'quest', vv) then
						local difficulty = CommonUtils.GetConfig('quest', 'quest', vv).difficulty
						local cityId     = CommonUtils.GetConfig('quest', 'quest', vv).cityId
						local tageNum    = 1
						if CommonUtils.GetConfig('quest', 'city', cityId) then
							for j, vvv in ipairs(CommonUtils.GetConfig('quest', 'city', cityId).quests[tostring(difficulty)]) do
								if vvv == vv then
									tageNum = j
									break
								end
							end
						end
						if checkint(difficulty) == 1 and checkint(cityId) == 1 and checkint(tageNum) == 1 then
							canAdded = 0
						end
					end
					if canAdded == 1 then
						viewData.gotoBtn:setUserTag(checkint(vv))
						break
					end
				end
			end
		end
	end
	display.commonLabelParams(viewData.titleLabel , {text = name })
	display.commonLabelParams(viewData.titleDescrLabel , {text = descr})
	display.commonLabelParams(viewData.unlockLabel , {text = string.fmt(__('_level_ 级以上'), {_level_ = openLevel})})
	if app.gameMgr:GetUserInfo().level >= openLevel then
		viewData.gotoBtn:setNormalImage(RES_DICT.COMMON_BTN_ORANGE)
		viewData.gotoBtn:setSelectedImage(RES_DICT.COMMON_BTN_ORANGE)
	else
		viewData.gotoBtn:setNormalImage(RES_DICT.COMMON_BTN_ORANGE_DISABLE)
		viewData.gotoBtn:setSelectedImage(RES_DICT.COMMON_BTN_ORANGE_DISABLE)
	end
	viewData.gotoBtn:setTag(checkint(openType))

	display.commonUIParams(viewData.gotoBtn , {cb  = handler(self, self.ButtonActions)})
end


function SunGainPopUp:ButtonActions(sender)
	local tag     = sender:getTag()
	local userTag = sender:getUserTag()
	if tag == checkint(JUMP_MODULE_DATA.UNION_PARTY) then
		uiMgr:ShowInformationTips(__('功能正在加速建造中，敬请期待。'))
		return
	end
	if not  CommonUtils.UnLockModule(tag , true)  then
		return
	end

	if tag == checkint(JUMP_MODULE_DATA.UNION_SHOP) or tag == checkint(JUMP_MODULE_DATA.UNION_PARTY) or tag == checkint(JUMP_MODULE_DATA.UNION_TASK) then
		if not app.gameMgr:hasUnion() then
			uiMgr:ShowInformationTips(__('暂无工会'))
			return
		end
	end
	if tag == checkint(JUMP_MODULE_DATA.NORMAL_MAP) or tag == checkint(JUMP_MODULE_DATA.DIFFICULTY_MAP) or tag == checkint(JUMP_MODULE_DATA.TEAM_MAP) then
		if userTag >= 0 and userTag < 2000 then
			if gameMgr:GetUserInfo().newestQuestId < userTag then
				uiMgr:ShowInformationTips(__('该关卡未解锁'))
				return
			end
		elseif userTag >= 2000 and userTag < 3000 then
			if gameMgr:GetUserInfo().newestHardQuestId < userTag then
				uiMgr:ShowInformationTips(__('该关卡未解锁'))
				return
			end
		else
			if gameMgr:GetUserInfo().newestInsaneQuestId < userTag then
				uiMgr:ShowInformationTips(__('该关卡未解锁'))
				return
			end
		end
		local mediator = AppFacade.GetInstance():RetrieveMediator("StoryMissionsMessageNewMediator")
		if mediator then
			mediator.data =  mediator.data or {}
			if checkint(mediator.data.taskType) == 37 then -- 新增道具获取
				AppFacade.GetInstance():UnRegsitMediator("StoryMissionsMediator")
			end
		end
		if self.args.toParams then
			self.args.toParams.stageId = userTag
		else
			self.args.toParams         = {}
			self.args.toParams.stageId = userTag
		end

		---------- 此处调出战斗准备界面 ----------
		local battleReadyData = BattleReadyConstructorStruct.New(
				2,
				gameMgr:GetUserInfo().localCurrentBattleTeamId,
				gameMgr:GetUserInfo().localCurrentEquipedMagicFoodId,
				self.args.toParams.stageId,
				CommonUtils.GetQuestBattleByQuestId(self.args.toParams.stageId),
				nil,
				POST.QUEST_AT.cmdName,
				{ userTag },
				POST.QUEST_AT.sglName,
				POST.QUEST_GRADE.cmdName,
				{ userTag },
				POST.QUEST_GRADE.sglName,
				'HomeMediator', --self.args.isFrom or
				'HomeMediator'--self.args.isFrom or
		)
		AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_UI_Create_Battle_Ready, battleReadyData)
		self:runAction(cc.RemoveSelf:create())
		return
		---------- 此处调出战斗准备界面 ----------
	elseif tag == checkint(JUMP_MODULE_DATA.SHOP) then
		if GAME_MODULE_OPEN.NEW_STORE then
			self:JumpToShopMediator({jumpData = {storeType = GAME_STORE_TYPE.SEARCH_PROP, searchGoodsId = checkint(self.goodsId)} })
		else
			if self.goodsId == UNION_HIGH_ROLL_ID or checkint(self.goodsId ) == CAPSULE_VOUCHER_ID then
				self:JumpToShopMediator(jumpViewData[tostring(JUMP_MODULE_DATA.GOODS_SHOP)])
			else
				self:JumpToShopMediator(jumpViewData[tostring(JUMP_MODULE_DATA.DIAMOND_SHOP)])
			end
		end
		return
	elseif tag == checkint(JUMP_MODULE_DATA.DIAMOND_SHOP) or
			tag == checkint(JUMP_MODULE_DATA.SKINSHOP) or
			tag == checkint(JUMP_MODULE_DATA.SHOP_TIPS) or
			tag == checkint(JUMP_MODULE_DATA.GIFT_SHOP) or
			tag == checkint(JUMP_MODULE_DATA.GOODS_SHOP) or
			tag == checkint(JUMP_MODULE_DATA.MEDAL_SHOP) then
		self:JumpToShopMediator(jumpViewData[tostring(tag)])
		return
	elseif tag == checkint(JUMP_MODULE_DATA.SMELTING_PET) then
		local chooesePetListView =  uiMgr:GetCurrentScene():GetDialogByName("ChooesePetListView")
		if  chooesePetListView then
			chooesePetListView:runAction(cc.RemoveSelf:create())
			chooesePetListView = nil
		end
		local petUpgradeMediator = AppFacade.GetInstance():RetrieveMediator("PetUpgradeMediator")
		if petUpgradeMediator then
			local viewComponent = petUpgradeMediator:GetViewComponent()
			if viewComponent and (not tolua.isnull(viewComponent)) then
				viewComponent:CloseHandler()
			end
		end
		if self and (not tolua.isnull(self)) then
			self:runAction(cc.RemoveSelf:create())
		end
		local petDevelopMediator = AppFacade.GetInstance():RetrieveMediator("PetDevelopMediator")
		if not  petDevelopMediator then
			AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'PetDevelopMediator'})
			petDevelopMediator = AppFacade.GetInstance():RetrieveMediator("PetDevelopMediator")
		end
		if petDevelopMediator  then
			petDevelopMediator:RefreshMuduleByModuleType(1,false )
			AppFacade.GetInstance():DispatchObservers( SGL.GO_TO_SMELTING_EVENT ,{})
		end
		return
	elseif tag == checkint(JUMP_MODULE_DATA.TOWER) then
		local chooesePetListView =  uiMgr:GetCurrentScene():GetDialogByName("ChooesePetListView")
		if  chooesePetListView then
			chooesePetListView:runAction(cc.RemoveSelf:create())
			chooesePetListView = nil
		end
		local petUpgradeMediator = AppFacade.GetInstance():RetrieveMediator("PetUpgradeMediator")
		if petUpgradeMediator then
			local viewComponent = petUpgradeMediator:GetViewComponent()
			if viewComponent and (not tolua.isnull(viewComponent)) then
				viewComponent:CloseHandler()
			end
		end
	elseif   tag == checkint(JUMP_MODULE_DATA.ARTIFACT_TAG) then
		---@type ArtifactManager
		local artifactMgr = AppFacade.GetInstance():GetManager("ArtifactManager")
		local questId =   artifactMgr:GetQuestIdByArtifactFragmentId(self.goodsId)
		if checkint(questId) > 0 then
			artifactMgr:GoToBattleReadyView(
					questId ,    'HomeMediator','HomeMediator' , nil
			)
		end
		return
	elseif  tag == checkint(JUMP_MODULE_DATA.FISHING_SHOP) or
			tag == checkint(JUMP_MODULE_DATA.FISHING_SHOP_ONE)
			or   tag == checkint(JUMP_MODULE_DATA.FISHING_SHOP_THREE)
			or tag == checkint(JUMP_MODULE_DATA.FISHING_SHOP_TWO) then
		local mediator = app:RetrieveMediator("BackPackMediator")
		if mediator then
			app:UnRegsitMediator("BackPackMediator")
		end
		local goShopIndex = nil
		if jumpViewData[tostring(tag)].jumpData then
			goShopIndex = jumpViewData[tostring(tag)].jumpData.goShopIndex
		end
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = jumpViewData[tostring(tag)].jumpView , params = {goodsId = self.goodsId , goShopIndex = goShopIndex } })
		self:runAction(cc.RemoveSelf:create())
		return
	elseif  tag == checkint(JUMP_MODULE_DATA.WATER_BAR_MARKET) then
		local materialConf = CONF.BAR.MATERIAL:GetAll()
		local materialOneConf = materialConf[tostring(self.goodsId)]
		self:JumpToMediator(jumpViewData[tostring(tag)].jumpView , {initType = checkint(materialOneConf.materialType) ,goodsId = self.goodsId  })
		self:runAction(cc.RemoveSelf:create())
		return
	end

	print("tag  == " , tag)
	if jumpViewData[tostring(tag)].jumpView then
		if jumpViewData[tostring(tag)].isPopup then
			local mediator    = require('Game.mediator.' .. jumpViewData[tostring(tag)].jumpView)
			local oneMediator = mediator.new()
			AppFacade.GetInstance():RegistMediator(oneMediator)
		else
			if jumpViewData[tostring(tag)].jumpView == '1' then
				local descr = jumpViewData[tostring(tag)].jumpDes or '返回主界面'
				if tag == checkint(JUMP_MODULE_DATA.ACTIVITY) then
					local moduleData = CommonUtils.GetConfigAllMess('module')[tostring(tag)]
					if moduleData and moduleData.descr then
						descr = moduleData.descr
					end
				end
				uiMgr:ShowInformationTips(descr)
			else
				if checkint(tag) == checkint(JUMP_MODULE_DATA.AIR_TRANSPORTATION) then
					local key = string.format('%s_ModulePanelIsOpen', tostring(gameMgr:GetUserInfo().playerId))
					cc.UserDefault:getInstance():setBoolForKey(key, false)
					cc.UserDefault:getInstance():flush()
				end
				AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({ name = self.args.isFrom, params = self.args.fromParams or {} }, { name = jumpViewData[tostring(tag)].jumpView, params = jumpViewData[tostring(tag)].jumpData or {} }, { isBack = self.args.isBack or false })
			end
		end
	end

	self:runAction(cc.RemoveSelf:create())
end

function SunGainPopUp:JumpToShopMediator(data)
	local jumpData = checktable(data)
	if GAME_MODULE_OPEN.NEW_STORE then
		app.uiMgr:showGameStores(jumpData.jumpData)
	else
		app:RetrieveMediator("Router"):Dispatch({name = self.args.isFrom, params = self.args.fromParams or {}}, {name = tostring(jumpData.jumpView), params  = jumpData.jumpData or {}})
	end

	if app:RetrieveMediator('BackPackMediator') then
		app:UnRegsitMediator("BackPackMediator")
	end
	if self and (not tolua.isnull(self)) then
		self:runAction(cc.RemoveSelf:create())
	end
end

-- 跳转到对应的mediator 里面
function SunGainPopUp:JumpToMediator(name, data)
	local mediator    = require('Game.mediator.' .. name)
	local oneMediator = mediator.new(data)
	AppFacade.GetInstance():RegistMediator(oneMediator)
end

return SunGainPopUp
