--[[
 * author : 邢伟浩
 * descpt : 打boss界面
--]]
---@class PopBattleBossView:Node
local PopBattleBossView = class('PopBattleBossView', function ()
	local node = CLayout:create(display.size)
	node.name = 'activity.PopBattleBossView'
	node:enableNodeEvents()
	return node
end)
local RES_DICT = {
	POP_BOSS_BG_TABLE                        = _res("ui/link/popMain/pop_boss_bg_table.png"),
	POP_BOSS_BG_REWARD                       = _res("ui/link/popMain/pop_boss_bg_reward.png"),
	POP_BOSS_BG_NAME                         = _res("ui/link/popMain/pop_boss_bg_name.png"),
	POP_BOSS_BTN_BOSS_LIGHT                  = _res("ui/link/popMain/pop_boss_btn_boss_light.png"),
	POP_BOSS_PIC_BOSS_SMALL_2                = _res("ui/link/popMain/pop_boss_pic_boss_small_2.png"),
	POP_BOSS_BTN_LV_LIGHT                    = _res("ui/link/popMain/pop_boss_btn_lv_light.png"),
	POP_BOSS_BG_BOSS_GREY                    = _res("ui/link/popMain/pop_boss_bg_boss_grey.png"),
	POP_BOSS_BG_DOOR                         = _res("ui/link/popMain/pop_boss_bg_door.png"),
	GARDEN_BOSS_BTN_SEARCH                   = _res("ui/link/popMain/garden_boss_btn_search.png"),
	POP_BOSS_ICO_ACHIEVEMENT                 = _res("ui/home/allround/allround_ico_book_3.png"),
	POP_BOSS_BTN_BG                          = _res("ui/link/popMain/pop_boss_btn_bg.png"),
	POP_BOSS_BG_BOTTOM                       = _res("ui/link/popMain/pop_boss_bg_bottom.png"),
	POP_BOSS_NUMBERS_BG                      = _res("ui/link/popMain/pop_boss_numbers_bg.png"),
	KAPAI_FRAME_BG_NOCARD                    = _res('ui/common/kapai_frame_bg_nocard.png'),
	KAPAI_FRAME_NOCARD                       = _res('ui/common/kapai_frame_nocard.png'),
	COMMON_BTN_BACK                          = _res("ui/common/common_btn_back"),
	COMMON_BTN_ADD                           = _res("ui/common/common_btn_add"),
	MAPS_FIGHT_BTN_PET_ADD                   = _res('ui/common/maps_fight_btn_pet_add.png')
}
function PopBattleBossView:ctor(params )
	self.summaryId = params.summaryId
	self:InitUI()
end

function PopBattleBossView:InitUI ()
	local swallowLayer = display.newLayer(display.cx, display.cy ,{
		ap = display.CENTER,size = display.size ,
		enable = true , color = cc.c4b(0,0,0,175)
	})
	self:addChild(swallowLayer,0)
	local canvas = display.newLayer(display.cx, display.cy ,{
		ap = display.CENTER,size = display.size
	})
	self:addChild(canvas,0)
	local backBtn = display.newImageView(RES_DICT.COMMON_BTN_BACK, display.SAFE_L + 56, display.height + -55,
	                                     { ap = display.CENTER, tag = 210, enable = true})
	backBtn:setScale(1, 1)
	backBtn:setPosition(display.SAFE_L + 56, display.height + -55)
	self:addChild(backBtn,25)

	local bgTable = display.newImageView( RES_DICT.POP_BOSS_BG_TABLE ,display.cx + 0, 0,{ap = display.CENTER_BOTTOM})
	canvas:addChild(bgTable,0)
	local teamBgImage = display.newImageView( RES_DICT.POP_BOSS_BG_BOTTOM ,display.cx + 0, 0,{ap = display.CENTER_BOTTOM})
	canvas:addChild(teamBgImage,10)
	local rewardOne = display.newImageView( RES_DICT.POP_BOSS_BG_REWARD ,display.cx + -516, 75.5,{ap = display.CENTER_BOTTOM})
	canvas:addChild(rewardOne,1)
	local rewardTwo = display.newImageView( RES_DICT.POP_BOSS_BG_REWARD ,display.cx + 517, 75.5,{ap = display.CENTER_BOTTOM})
	canvas:addChild(rewardTwo,1)
	local higthText = display.newLabel(display.cx + 514, 336 , {fontSize = 24,ttf = true,font = TTF_GAME_FONT,text = __('最高伤害'),color = '#D2B68F',ap = display.CENTER_BOTTOM})
	canvas:addChild(higthText,4)
	local higntValueLabel = display.newButton(display.cx + 519, 275.5 , {n = RES_DICT.POP_BOSS_BG_NAME,ap = display.CENTER_BOTTOM,scale9 = true,size = cc.size(185,35)})
	canvas:addChild(higntValueLabel,3)
	display.commonLabelParams(higntValueLabel ,{fontSize = 20,text = '',color = '#ffffff',offset = cc.p(10 , 0),paddingW  = 20,safeW = 145})

	local doorImage = display.newImageView( RES_DICT.POP_BOSS_BG_DOOR ,display.cx + -2, 200,{ap = display.CENTER_BOTTOM,scaleX = 1})
	canvas:addChild(doorImage,11)

	local bossDetailBtn = display.newButton(display.cx + -188, 200 , { enable = true , n = RES_DICT.GARDEN_BOSS_BTN_SEARCH,ap = display.CENTER_BOTTOM,scale9 = true,size = cc.size(157,46)})
	canvas:addChild(bossDetailBtn,35)
	display.commonLabelParams(bossDetailBtn ,{fontSize = 20,text = __('boss详情'),color = '#ffffff',offset = cc.p(10 , 0),paddingW  = 20,safeW = 117})
	local bossAchieveBtn = display.newLayer(display.cx + -508.5928, 19 ,{ap = display.CENTER_BOTTOM,size = cc.size(170,190),color = cc.c4b(0,0,0,0),enable = true})
	canvas:addChild(bossAchieveBtn,11)
	local achievementImage = display.newImageView( RES_DICT.POP_BOSS_ICO_ACHIEVEMENT ,90.5928, 42.5,{ap = display.CENTER_BOTTOM,scaleX = 1})
	bossAchieveBtn:addChild(achievementImage,11)
	local titleBtn = display.newButton(85, 2 , {n = RES_DICT.POP_BOSS_BTN_BG,ap = display.CENTER_BOTTOM,scale9 = true,size = cc.size(157,46)})
	bossAchieveBtn:addChild(titleBtn,0)
	display.commonLabelParams(titleBtn ,fontWithColor(14, {fontSize = 24,text = __('战斗路线'),color = '#ffffff',paddingW  = 20,safeW = 117}))

	local battleCommonBtn = require('common.CommonBattleButton').new({
		                                                                 pattern = 1
                                                                 })
	canvas:addChild(battleCommonBtn,11)
	battleCommonBtn:setAnchorPoint(display.CENTER_BOTTOM)
	battleCommonBtn:setPosition(display.cx + 512, 54)

	local freeLabel = display.newLabel(display.cx + 512, 44 ,{ap = display.CENTER_TOP })
	canvas:addChild(freeLabel,11)

	local timeSize = cc.size(180, 45 )
	local timeLayout = display.newLayer(display.cx + 530, 50 ,{color = cc.c4b(0,0,0,0) , enable = true , size = timeSize , ap = display.CENTER_TOP })
	canvas:addChild(timeLayout,11)
	local numberBtn = display.newButton(timeSize.width/2 - 20 , timeSize.height/2 ,{ n = RES_DICT.POP_BOSS_NUMBERS_BG  })
	timeLayout:addChild(numberBtn)
	local addBtn = display.newImageView(RES_DICT.COMMON_BTN_ADD , timeSize.width/2 +60 , timeSize.height/2 )
	timeLayout:addChild(addBtn)
	timeLayout:setVisible(false)
	local middle = 2.5
	local width = 110
	local heightY = 73
	local cardDatas = {}
	local addCardLayer = display.newLayer(display.cx ,heightY,{ap = display.CENTER , size = cc.size(width* 5 , 100) ,color = cc.c4b(0,0,0,0) , enable = true} )
	canvas:addChild(addCardLayer , 25 )
	for i =1 , 5 do
		local cardHeadBg = display.newImageView(RES_DICT.KAPAI_FRAME_BG_NOCARD, display.cx +  (i -0.5 - middle) * width ,heightY, {ap = display.CENTER} )
		cardHeadBg:setScale(0.5)
		canvas:addChild(cardHeadBg,20)

		local cardHeadFrame = display.newImageView(RES_DICT.KAPAI_FRAME_NOCARD, display.cx + (i-0.5 - middle) * width,heightY, {ap = display.CENTER} )
		cardHeadFrame:setScale(0.5)
		canvas:addChild(cardHeadFrame,21)
		local addBtn = display.newImageView(RES_DICT.MAPS_FIGHT_BTN_PET_ADD, display.cx + (i-0.5 - middle) * width,heightY, {ap = display.CENTER} )
		canvas:addChild(addBtn,22)
		addBtn:setTag(i)
		cardDatas[i] = addBtn
	end

	self.viewData = {
		canvas                    = canvas,
		bgTable                   = bgTable,
		rewardOne                 = rewardOne,
		rewardTwo                 = rewardTwo,
		higthText                 = higthText,
		higntValueLabel           = higntValueLabel,
		doorImage                 = doorImage,
		bossDetailBtn             = bossDetailBtn,
		bossAchieveBtn            = bossAchieveBtn,
		achievementImage          = achievementImage,
		battleCommonBtn           = battleCommonBtn,
		titleBtn                  = titleBtn,
		backBtn                   = backBtn,
		cardDatas                 = cardDatas,
		addCardLayer              = addCardLayer,
		cardNodes                 = {false , false , false , false , false} ,
		timeLayout                = timeLayout,
		numberBtn                 = numberBtn,
		freeLabel                 = freeLabel,
		bossCellViewData          = {}
	}
end

function PopBattleBossView:CreateCell(index)
	local offsetH = 100 * (index - 1)
	local canvas = self.viewData.canvas
	local bossbgImage = display.newButton( display.cx + -515, 321.5-offsetH,{ap = display.CENTER_BOTTOM , n = RES_DICT.POP_BOSS_BTN_BOSS_LIGHT })
	canvas:addChild(bossbgImage,2)
	bossbgImage:setTag(index)
	local bossSamallIcon = display.newImageView( RES_DICT.POP_BOSS_PIC_BOSS_SMALL_2 ,display.cx + -515, 332.5-offsetH,{ap = display.CENTER_BOTTOM})
	canvas:addChild(bossSamallIcon,3)
	local bossName = display.newLabel(display.cx + -450, 363-offsetH ,fontWithColor(14 , {text = '',ap = display.CENTER_BOTTOM}))
	canvas:addChild(bossName,4)
	local bossSelectImage = display.newImageView( RES_DICT.POP_BOSS_BTN_LV_LIGHT ,display.cx + -515, 312.5-offsetH,{ap = display.CENTER_BOTTOM,scaleX = 0.95})
	canvas:addChild(bossSelectImage,5)
	bossSelectImage:setVisible(false)
	local notSelectImage = display.newImageView( RES_DICT.POP_BOSS_BG_BOSS_GREY ,display.cx + -515, 332.5-offsetH,{ap = display.CENTER_BOTTOM})
	canvas:addChild(notSelectImage,6)
	return {
		bossbgImage = bossbgImage ,
		bossSamallIcon = bossSamallIcon ,
		bossName = bossName ,
		bossSelectImage = bossSelectImage ,
		notSelectImage = notSelectImage ,
	}
end

function PopBattleBossView:CreateBossInfo(boss)
	for i = 1, #boss do
		local viewData = self:CreateCell(i)
		self.viewData.bossCellViewData[#self.viewData.bossCellViewData+1] = viewData
	end
end

function PopBattleBossView:UpdateAllBossInfo(boss , selectIndex)
	for i = 1, #boss do
		self:UpdateBossIndex(boss[i] , i , selectIndex)
	end
end

function PopBattleBossView:UpdateBossIndex(boss , index , selectIndex)
	local farmBossConf = CONF.ACTIVITY_POP.FARM_BOSS:GetAll()
	local farmBossOneConf = farmBossConf[tostring(boss.bossId)]
	local viewData = self.viewData.bossCellViewData[index]
	viewData.bossSamallIcon:setTexture(_res(string.format('ui/link/popMain/pop_boss_pic_boss_small_%d.png',index)))
	local isVisible = selectIndex == index
	viewData.notSelectImage:setVisible(not isVisible)
	viewData.bossSelectImage:setVisible(isVisible)
	display.commonLabelParams(viewData.bossName , {text = farmBossOneConf.name })
end
-- 更新spine 的显示
function PopBattleBossView:UpdateBossSpine(bossId)
	local farmBossOneConf = CONF.ACTIVITY_POP.FARM_BOSS:GetValue(bossId)
	local showMonster = farmBossOneConf.showMonster
	local viewData = self.viewData
	if #showMonster > 0 then
		local cardSkinNode = viewData.canvas:getChildByName("cardSkinNode")
		if cardSkinNode and (not tolua.isnull(cardSkinNode)) then
			cardSkinNode:runAction(cc.Sequence:create(
				cc.Hide:create() ,
				cc.CallFunc:create(function()
					cardSkinNode:setToSetupPose()
				end),
				cc.RemoveSelf:create()
			))
		end
		local monsterId = showMonster[1]
		local skinId = CardUtils.GetCardSkinId(monsterId)
		local qAvatar = AssetsUtils.GetCardSpineNode({skinId = skinId, scale = 1})
		qAvatar:setAnimation(0, 'idle', true)
		qAvatar:setPosition(cc.p(display.cx + -2, 200))
		viewData.canvas:addChild(qAvatar,11)
		qAvatar:setName("cardSkinNode")
	end
end
function PopBattleBossView:GetSummaryId()
	return self.summaryId
end
function PopBattleBossView:UpdateChallegeTimes(times)
	local viewData = self.viewData
	display.commonLabelParams(viewData.numberBtn , fontWithColor(14, {text = table.concat({
        times , 1 } , "/")}))
end
function PopBattleBossView:UpdateCardNodes(data)
	local cardNodes = self.viewData.cardNodes
	local cardDatas = self.viewData.cardDatas
	local gameMgr = app.gameMgr
	for i , v in pairs(data) do
		if  checkint(v.id)  > 0  then
			if not cardNodes[i] then
				-- 不显示本地的数据 ， 需要传入完整的cardData
				local cardData = gameMgr:GetCardDataById(v.id)
				local cardHeadNode = require('common.CardHeadNode').new({
					cardData = cardData,
					showBaseState = true
				})
				local addBtn =  cardDatas[i]
				local addBtnPos = cc.p(addBtn:getPosition())
				cardHeadNode:setPosition(addBtnPos)
				cardHeadNode:setScale(0.5)
				self.viewData.canvas:addChild(cardHeadNode   , 24)
				cardNodes[i] = cardHeadNode
			else
				print(v.id)
				cardNodes[i]:RefreshUI(v)
			end
			cardNodes[i]:setVisible(true)
		else
			if cardNodes[i] then
				cardNodes[i]:setVisible(false)
			end
		end
	end
end
function PopBattleBossView:UpdateView(boss, selectIndex)
	local bossData = boss[selectIndex]
	local bossId = bossData.bossId
	-- 更新boss 的spine
	self:UpdateBossSpine(bossId)
	self:UpdateAllBossInfo(boss , selectIndex)

	local viewData = self.viewData
	local maxDamage = bossData.maxDamage
	display.commonLabelParams(viewData.higntValueLabel , {text = maxDamage})
	if checkint(bossData.leftFreeChallengeTimes) > 0  then
		viewData.freeLabel:setVisible(true)
		display.commonLabelParams(viewData.freeLabel , {fontSize = 24 ,  text = __('每日首次免费')})
		viewData.timeLayout:setVisible(false)
	else
		viewData.freeLabel:setVisible(false)
		display.commonLabelParams(viewData.numberBtn , fontWithColor(14,{text = string.fmt("_num1_/_num2_" , {
			_num1_ = checkint(bossData.leftBuyChallengeTimes) , _num2_ = 1
		})}))
		viewData.timeLayout:setVisible(true)
	end
end

return PopBattleBossView