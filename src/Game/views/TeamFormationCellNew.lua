---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
---@type PetManager
local petMgr = AppFacade.GetInstance():GetManager("PetManager")
local TeamFormationCellNew = class('TeamFormationCellNew', function ()
	local node = CLayout:create()
	return node
end)

--[[
	隐藏光圈图
--]]
function TeamFormationCellNew:RotateActionOff()
	if self.viewData.light then
		self.viewData.light:setVisible(false)
		self.viewData.light:stopAllActions()
	end
end
--[[
	显示光圈图
--]]
function TeamFormationCellNew:RotateActionOn()
	if self.viewData.light then
		self.viewData.light:setVisible(true)
        local action = cc.RotateBy:create(4, 90)
        self.viewData.light:runAction(cc.RepeatForever:create(action))
	end
end
--[[
	隐藏加号
--]]
function TeamFormationCellNew:BlinkActionOff()
	if self.viewData.imgAdd then
		self.viewData.labelAdd:setVisible(false)
		self.viewData.imgAdd:setVisible(false)
		-- self.viewData.imgAdd:stopAllActions()
	end
end
--[[
	显示加号
--]]
function TeamFormationCellNew:BlinkActionOn()
	if self.viewData.imgAdd then
		self.viewData.labelAdd:setVisible(true)
		self.viewData.imgAdd:setVisible(true)
		-- self.viewData.imgAdd:runAction(cc.RepeatForever:create(cc.Sequence:create(
		-- 		cc.FadeIn:create(1), cc.FadeOut:create(1)
		-- 	)))
	end
end

local function CreateView(size)
	local view = CLayout:create(cc.size(size.width,size.height ))
	-- view:setBackgroundColor(cc.c4b(0, 128, 0, 100))
	view:setName('view')

	local urKuang = display.newImageView(_res('ui/home/teamformation/newCell/team_bg_pinzhi_orange.png'), size.width * 0.5, size.height * 0.5 + 12
		,{scale9 = true, size = cc.size(230 , 570)})--
	view:addChild(urKuang,2)

	local lastKuangBg = display.newImageView(_res('ui/home/teamformation/newCell/team_frame_tianjiawan1.png'), size.width * 0.5, size.height * 0.5 + 12 )
	view:addChild(lastKuangBg,2)

	-- local lastbg = display.newImageView(_res('ui/home/teamformation/newCell/team_bg_add.png'), size.width * 0.5, size.height * 0.5 + 12)
	-- view:addChild(lastbg,-1)
	-- lastbg:setVisible(false)

	local bg = AssetsUtils.GetCardTeamBgNode(0, size.width * 0.5 + 1, size.height * 0.5 + 12)
	view:addChild(bg)
	bg:setVisible(false)
	bg:setName('bg')


	--展开功能按钮
	local modelBtn = display.newCheckBox(size.width * 0.5,60 , {n = 'ui/home/teamformation/newCell/team_ico_guanbi.png',
		s = 'ui/home/teamformation/newCell/team_ico_zhankai.png'
		})
	view:addChild(modelBtn,10)

	--品质图标
	local qualityImg = display.newImageView(_res('ui/common/common_img_n.png'),size.width  , size.height  )
	qualityImg:setAnchorPoint(cc.p(1,1))
	view:addChild(qualityImg,2)


	local lsize = cc.size(200, 540)

	local roleClippingNode = cc.ClippingNode:create()
	roleClippingNode:setContentSize(cc.size(lsize.width - 7 , lsize.height - 10))
	roleClippingNode:setAnchorPoint(0.5, 1)
	roleClippingNode:setPosition(cc.p(lsize.width / 2, lsize.height  ))
	roleClippingNode:setInverted(false)
	bg:addChild(roleClippingNode, 1)
	-- cut layer
	local cutLayer = display.newLayer(
		0,
		0,
		{
			size = roleClippingNode:getContentSize(),
			ap = cc.p(0, 0),
			color = '#ffcc00'
		})
	local light = display.newImageView(_res('ui/home/teamformation/team_pet_bg_fangsheguang_white.png'), lsize.width * 0.5, lsize.height * 0.5)
	bg:addChild(light)
	light:setVisible(false)

	local imgHero = AssetsUtils.GetCardDrawNode()
	imgHero:setAnchorPoint(display.LEFT_BOTTOM)
	imgHero:setVisible(false)

	local particleSpine = nil

	roleClippingNode:setStencil(cutLayer)
	roleClippingNode:addChild(imgHero)

	local imgAdd = display.newImageView(_res('ui/home/teamformation/newCell/team_ico_add.png'), lsize.width * 0.5, lsize.height * 0.5)
	bg:addChild(imgAdd)
	imgAdd:setVisible(false)

 	local labelAdd = display.newLabel(lsize.width * 0.5, lsize.height * 0.375,
 		{text = __('添加飨灵'), fontSize = 24, color = '#ff8a0c', ap = cc.p(0.5, 0.5)})
 	bg:addChild(labelAdd, 10)
 	labelAdd:setVisible(false)

	local bgHeroDes = display.newImageView(_res('ui/home/teamformation/newCell/team_bg_font_tianjiawan.png'), view:getContentSize().width * 0.5, 57,{--
            --scale9 = true, size = cc.size(lsize.width , 164)--
        })
	bgHeroDes:setVisible(false)
	bgHeroDes:setAnchorPoint(cc.p(0.5, 0))
	view:addChild(bgHeroDes,3)

	local posX = bgHeroDes:getContentSize().width * 0.5 + 4
	local posY = bgHeroDes:getContentSize().height

	--卡牌昵称
	local nameLabel = display.newLabel(posX,posY - 20,
		{text = ' ',ttf = true, font = TTF_GAME_FONT, fontSize = 28, color = '#ffffff', ap = cc.p( 0.5, 0.5)})
	nameLabel:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	bgHeroDes:addChild(nameLabel)
	local nameLabelParams = {font = TTF_GAME_FONT, fontSize = 28, color = '#ffffff', outline = cc.c4b(0, 0, 0, 255), fontSizeN = 28, colorN = '#ffffff'}


	local  tiredBtn = display.newButton(posX,posY - nameLabel:getBoundingBox().height - 20 , {n = 'ui/home/teamformation/newCell/team_bg_font.png'})
	--display.commonLabelParams(tiredBtn, fontWithColor(8,{ap = cc.p(0,0.5),text = __('新鲜度'), offset = cc.p(-90,0)}))
	bgHeroDes:addChild(tiredBtn)
	local tiredBtnPos = cc.p(tiredBtn:getPosition())
	local tiredBtnLevel = display.newLabel(tiredBtnPos.x -90,tiredBtnPos.y , fontWithColor(8,{text =  __('新鲜度') , ap = display.LEFT_CENTER}) )
	bgHeroDes:addChild(tiredBtnLevel,8)
	local  fightBtn = display.newButton(posX,tiredBtn:getPositionY() - 30 , {n = 'ui/home/teamformation/newCell/team_bg_font.png'})
	--display.commonLabelParams(fightBtn, fontWithColor(8,{ap = cc.p(0,0.5),text = __('灵力'), offset = cc.p(-90,0)}))
	bgHeroDes:addChild(fightBtn)


	local fightBtnPos = cc.p(fightBtn:getPosition())
	local fightBtnLabel = display.newLabel(fightBtnPos.x -90,fightBtnPos.y , fontWithColor(8,{text =  __('灵力') , ap = display.LEFT_CENTER}) )
	bgHeroDes:addChild(fightBtnLabel,8)

	-- local  petBtn = display.newButton(posX,fightBtn:getPositionY() - 30 , {n = 'ui/home/teamformation/newCell/team_bg_font.png'})
	-- display.commonLabelParams(petBtn, fontWithColor(8,{ap = cc.p(0,0.5),text = __('堕神'), offset = cc.p(-90,0)}))
	-- bgHeroDes:addChild(petBtn)

    local operaProgressBar = CProgressBar:create(_res('ui/home/teamformation/newCell/team_img_leaf_red.png'))
    operaProgressBar:setBackgroundImage(_res('ui/home/teamformation/newCell/team_img_leaf_grey.png'))
    operaProgressBar:setDirection(eProgressBarDirectionLeftToRight)
    operaProgressBar:setAnchorPoint(cc.p(1, 0.5))
    operaProgressBar:setMaxValue(100)
    operaProgressBar:setValue(0)
    operaProgressBar:setPosition(cc.p(bgHeroDes:getContentSize().width - 5 , posY-nameLabel:getBoundingBox().height - 20))
    bgHeroDes:addChild(operaProgressBar,5)
    local vigourProgressBarTop =  display.newImageView(_res('ui/home/teamformation/newCell/team_img_leaf_free.png'),0,0,{as = false})
    vigourProgressBarTop:setAnchorPoint(cc.p(1,0.5))
    vigourProgressBarTop:setPosition(cc.p(bgHeroDes:getContentSize().width ,posY-nameLabel:getBoundingBox().height - 22))
    bgHeroDes:addChild(vigourProgressBarTop,6)

    -- local vigourLabel = display.newLabel(20 + operaProgressBar:getContentSize().width + 4, operaProgressBar:getPositionY(),{
    --     ap = display.LEFT_CENTER, fontSize = 18, color = 'ffffff', text = "1"
    -- })
    -- bgHeroDes:addChild(vigourLabel, 6)

	local  fightLabel = display.newLabel(bgHeroDes:getContentSize().width - 20 ,tiredBtn:getPositionY() - 30 ,
		fontWithColor(6,{text = '0', ap = cc.p(1, 0.5)}))
	bgHeroDes:addChild(fightLabel)

	-- local  petLabel = display.newLabel(bgHeroDes:getContentSize().width - 20 ,fightBtn:getPositionY() - 30 ,
	-- fontWithColor(6,{text = (''), ap = cc.p(1, 0.5)}))
	-- bgHeroDes:addChild(petLabel)


	--星级ui
	local starlayout = CLayout:create()
	starlayout:setAnchorPoint(cc.p(0.5,0.5))
	starlayout:setPosition(cc.p(50,220 ))
	view:addChild(starlayout,20)


	--连携技ui
	local teamCupImg = display.newImageView(_res('ui/home/teamformation/team_ico_captain.png'), 0, 0)
	teamCupImg:setAnchorPoint(cc.p(1,0.5))
	view:addChild(teamCupImg,9)
	teamCupImg:setPosition(cc.p(view:getContentSize().width - 20,bgHeroDes:getContentSize().height + 88))
	teamCupImg:setTouchEnabled(true)
	teamCupImg:setVisible(false)

	local teamCupRank = display.newImageView(_res('ui/home/teamformation/team_ico_skill_circle.png'), 0, 0)
	teamCupRank:setAnchorPoint(cc.p(1,0.5))
	teamCupRank:setScale(1.2)
	view:addChild(teamCupRank,10)
	teamCupRank:setPosition(cc.p(view:getContentSize().width - 15,bgHeroDes:getContentSize().height + 88))
	teamCupRank:setVisible(true)

	local bgHeroMes = display.newImageView(_res('ui/home/teamformation/newCell/team_bg_font_xiangxi.png'), lsize.width * 0.5 + 11, lsize.height + 57,{--
            scale9 = true, size = cc.size(193, 380)--
        })
	bgHeroMes:setTouchEnabled(true)
	bgHeroMes:setVisible(false)
	bgHeroMes:setAnchorPoint(cc.p(0.5, 1))
	view:addChild(bgHeroMes,1)

	local posY = bgHeroMes:getContentSize().height

	local  desBtn = display.newButton(posX,posY - 10 , {n = 'ui/home/teamformation/newCell/team_bg_font_xiangxi_biaoti.png'})
	desBtn:setAnchorPoint(cc.p(0.5,1))
	bgHeroMes:addChild(desBtn,2)
	local desBtnLabel = display.newLabel(posX,posY - 15 ,  {text = __('详情属性'), fontSize = 20, color = 'ffffff' , ap = display.CENTER_TOP})
	bgHeroMes:addChild(desBtnLabel,8)

	local  desBtn1 = display.newButton(posX,posY - 260 , {n = 'ui/home/teamformation/newCell/team_bg_font_xiangxi_biaoti.png'})
	desBtn1:setAnchorPoint(cc.p(0.5,1))
	bgHeroMes:addChild(desBtn1,2)
	local desBtn1Label = display.newLabel(posX,posY - 265 ,  {text = __('堕神装备'), fontSize = 20, color = 'ffffff' , ap = display.CENTER_TOP})
	bgHeroMes:addChild(desBtn1Label,8)

	--详情属性
	local tRichLabe = {}
	local tMessNumRichLabe = {}
	for i=1,6 do
		local line = display.newImageView(_res('ui/home/teamformation/newCell/team_img_xiangxi_line.png'), checkint(posX), checkint(posY) - 71.5 - 36 * (i-1),
				{ap = cc.p(0.5, 0.5)
			})
		bgHeroMes:addChild(line,25)

        local tempLabel = display.newLabel(10, posY - 60 - 35 * (i-1),fontWithColor(6,{ap = cc.p(0,0.5)}))
        bgHeroMes:addChild(tempLabel,8)
	    table.insert(tRichLabe,tempLabel)

   		local tempLabel = display.newLabel(bgHeroMes:getContentSize().width - 10, posY - 60 - 35 * (i-1),fontWithColor(10,{ap = cc.p(1,0.5)}))
	    bgHeroMes:addChild(tempLabel,8)
	    table.insert(tMessNumRichLabe,tempLabel)
	end




    local showPetBg = display.newImageView(_res('ui/common/common_frame_goods_5.png'), bgHeroMes:getContentSize().width*0.5, posY - 330)
    bgHeroMes:addChild(showPetBg)
    showPetBg:setScale(0.7)

    local petImage = display.newImageView(
        _res('ui/common/maps_fight_btn_pet_add.png'),
        showPetBg:getContentSize().width * 0.5,
        showPetBg:getContentSize().height * 0.5 )
    showPetBg:addChild(petImage)
    showPetBg:setVisible(false)
    local petEmptyLabel = display.newLabel(bgHeroMes:getContentSize().width*0.5, posY - 330,
        fontWithColor(14, {text = __('未装备')}))
    bgHeroMes:addChild(petEmptyLabel,20)




	--等级 team_dengji_captain
	local  lvBtn = display.newImageView('#kapai_zhiye_colour.png' , 44,size.height - 30)

	lvBtn:setAnchorPoint(cc.p(0.5,1))
	view:addChild(lvBtn,20)


	--卡牌类型
	local bgJob = display.newImageView("#kapai_zhiye_colour.png", 44 , size.height - 58 ,
			{ap = cc.p(0.5, 1)
		})
	view:addChild(bgJob,20)

	local jobImg = display.newImageView('#kapai_zhiye_colour.png',utils.getLocalCenter(bgJob).x - 8,  utils.getLocalCenter(bgJob).y - 4 ,
			{ap = cc.p(0.5, 0.5)
		})
	jobImg:setScale(0.7)
	bgJob:addChild(jobImg)


	local lvLabel = display.newLabel(44,size.height - 50,{fontSize = 20 , color = "ffffff"})
	view:addChild(lvLabel,21)

	return {
		view   		= view,
		-- lastbg 		= lastbg,
		bgView 		= bg,
		light 		= light,
		imgAdd 		= imgAdd,
		labelAdd 	= labelAdd,
		roleClippingNode = roleClippingNode,
		imgHero 	= imgHero,
		particleSpine = particleSpine,
		bgHeroDes 	= bgHeroDes,
		bgHeroMes   = bgHeroMes,
		teamCupImg 	= teamCupImg,
		nameLabel 	= nameLabel,
		nameLabelParams = nameLabelParams,
		starlayout 	= starlayout,
		tRichLabe 	= tRichLabe,
		tMessNumRichLabe = tMessNumRichLabe,
		bgJob 		= bgJob,
		jobImg 		= jobImg,
		lvLabel 		= lvLabel,
		-- bgTired 	= bgTired,
		-- tTiredNumImgs = tTiredNumImgs,
		-- tiredNumLabel = tiredNumLabel,
		-- tiredIcon 	  = tiredIcon,
		qualityImg 	   = qualityImg,
		lvBtn 		= lvBtn,
		modelBtn 	= modelBtn,
		fightBtn 	= fightBtn,
		tiredBtn	= tiredBtn,
		operaProgressBar = operaProgressBar,
		-- petBtn 		= petBtn,
		-- tiredLabel = tiredLabel,
		fightLabel = fightLabel,
		-- petLabel   = petLabel,
		urKuang 	= urKuang,

		teamCupRank =teamCupRank,
		lastKuangBg = lastKuangBg,
        showPetBg = showPetBg,
		petImage = petImage,
        petEmptyLabel = petEmptyLabel,
	}
end


function TeamFormationCellNew:ctor( ... )
	local t = unpack({...})
	self.size = t.size
	-- self:setBackgroundColor(cc.c4b(0, 128, 0, 100))
	self:setContentSize(self.size)
	self.viewData = CreateView(self.size)
	display.commonUIParams(self.viewData.view,{po = cc.p(self.size.width * 0.5,self.size.height * 0.5 )})
	self:addChild(self.viewData.view)
	---- TODO ----
	self.isCommon = t.isCommon or false
	---- TODO ----
end

function TeamFormationCellNew:refreshUI(data,showpet)
	local teaminfo = data
	self:BlinkActionOff()
	self:RotateActionOff()
	self.viewData.bgView:setVisible(true)
	local lsize = self.viewData.bgView:getContentSize()
	self.viewData.bgHeroDes:setVisible(false)
	self.viewData.bgHeroMes:setVisible(false)
	self.viewData.imgHero:setVisible(false)
	if self.viewData.particleSpine then
		self.viewData.particleSpine:setVisible(false)
	end
	-- self.viewData.lastbg:setVisible(true)
	self.viewData.bgView:setTouchEnabled(true)
	self.viewData.imgHero:setScale(1)
	self.viewData.imgHero:setRotation(0)
	self.viewData.qualityImg:setVisible(false)
	self.viewData.teamCupImg:setVisible(false)
	self.viewData.teamCupRank:setVisible(false)
	self.viewData.lvBtn:setVisible(false)
	self.viewData.lvLabel:setVisible(false)
	self.viewData.bgJob:setVisible(false)
	self.viewData.modelBtn:setVisible(false)
	self.viewData.starlayout:setVisible(false)
	self.viewData.urKuang:setVisible(false)
	self.viewData.operaProgressBar:setVisible(false)
	if teaminfo then
		local id = teaminfo.id
		if id == nil then--说明该栏位没有上阵英雄
			self:BlinkActionOn()
			-- self.viewData.lastbg:setVisible(false)
			self.viewData.bgView:setTexture(_res('ui/home/teamformation/newCell/team_bg_add.png'))
			self.viewData.lastKuangBg:setTexture(_res('ui/home/teamformation/newCell/team_frame_tianjiawan1.png'))
		else
			local CardData = gameMgr:GetCardDataById(id)
			local LocalCardData = CommonUtils.GetConfig('cards', 'card', CardData.cardId)
			local name = LocalCardData.name or ' '
			local qualityId = checkint(LocalCardData.qualityId)
			local career = checkint(LocalCardData.career)
			local allrank = CardData.breakLevel or 2

			self.viewData.lvBtn:setVisible(true)
			self.viewData.lvLabel:setVisible(true)
			self.viewData.lvLabel:setString(CardData.level)

			---- TODO ----
			-- self.viewData.modelBtn:setVisible(true)
			if self.isCommon then
				self.viewData.modelBtn:setVisible(false)
			else
				self.viewData.modelBtn:setVisible(true)
			end
			---- TODO ----
			--英雄图片
			self.viewData.imgHero:setVisible(true)

			local cardSkinId   = app.cardMgr.GetCardSkinIdByCardId(CardData.cardId)
			local cardDrawName = CardUtils.GetCardDrawNameBySkinId(cardSkinId)
			self.viewData.imgHero:setTexture(AssetsUtils.GetCardDrawPath(cardDrawName))

			if cardMgr.GetCouple(id) then
				if self.viewData.particleSpine then
					self.viewData.particleSpine:setVisible(true)
				else
					local particleSpine =  display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly')
					-- particleSpine:setTimeScale(2.0 / 3.0)
					particleSpine:setAnimation(0, 'idle2', true)
					particleSpine:update(0)
					particleSpine:setToSetupPose()

					self.viewData.roleClippingNode:addChild(particleSpine)
					self.viewData.particleSpine = particleSpine
				end
			else
				if self.viewData.particleSpine then
					self.viewData.particleSpine:setVisible(false)
				end
			end

			local cardDrawName = CardData.cardId
			local skinData = CommonUtils.GetConfig('goods', 'cardSkin', cardSkinId)
			if skinData then
				cardDrawName = skinData.photoId
			end

			local locationInfo = CommonUtils.GetConfig('cards', 'coordinate', cardDrawName)
			if nil == locationInfo or not locationInfo[COORDINATE_TYPE_TEAM] then
				print('\n**************\n', '立绘坐标信息未找到', cardDrawName, '\n**************\n')
				locationInfo = {x = 0, y = 0, scale = 50, rotate = 0}
			else
				locationInfo = locationInfo[COORDINATE_TYPE_TEAM]
			end
			self.viewData.imgHero:setScale(locationInfo.scale/100)
			self.viewData.imgHero:setRotation( (locationInfo.rotate))
			self.viewData.imgHero:setPosition(cc.p(locationInfo.x,(-1)*(locationInfo.y-540)))

			--英雄信息栏
            self.viewData.bgHeroDes:setVisible(true)
            -- self.viewData.bgHeroMes:setVisible(true)
            self.viewData.teamCupImg:setVisible(true)
            self.viewData.teamCupRank:setVisible(true)
            if next(LocalCardData.concertSkill) == nil then
                self.viewData.teamCupImg:setVisible(false)
                self.viewData.teamCupRank:setVisible(false)
            end
            self.viewData.teamCupImg:setColor(cc.c4b(100, 100, 100, 100))
			self.viewData.teamCupImg:setScale(0.4)
			local skillId = CardUtils.GetCardConnectSkillId(CardData.cardId)--CommonUtils.GetConfig('cards', 'card', CardData.cardId).skill[3]
			if skillId then
				local skillIconPath = CommonUtils.GetSkillIconPath(CardUtils.GetSkillConfigBySkillId(skillId).id)
				self.viewData.teamCupImg:setTexture(skillIconPath)
			end

			self.viewData.urKuang:setVisible(qualityId == 4)
			self.viewData.qualityImg:setVisible(true)
			self.viewData.qualityImg:setTexture(CardUtils.GetCardQualityIconPathByCardId(CardData.cardId))
			self.viewData.lastKuangBg:setTexture(CardUtils.GetCardTeamFramePathByCardId(CardData.cardId))
			self.viewData.bgView:setTexture(CardUtils.GetCardTeamBgPathBySkinId(cardSkinId))

			--英雄疲劳值栏
		 	self.viewData.operaProgressBar:setVisible(true)
            local ratio = (checkint(CardData.vigour) /app.restaurantMgr:getCardVigourLimit(CardData.id))* 100
		    self.viewData.operaProgressBar:setValue(rangeId(ratio, 100))
		   	if (ratio > 40 and (ratio <= 60)) then
		      	self.viewData.operaProgressBar:setProgressImage('ui/home/teamformation/newCell/team_img_leaf_yellow.png')
		   	elseif ratio > 60 then
		      	self.viewData.operaProgressBar:setProgressImage('ui/home/teamformation/newCell/team_img_leaf_green.png')
		   	end

			--英雄卡牌属性
			self.viewData.bgJob:setVisible(true)
			local bgJobStr = basename(CardUtils.GetCardCareerIconFramePathByCardId(CardData.cardId))
			local jobImgStr = basename(CardUtils.GetCardCareerIconPathByCardId(CardData.cardId))
			if bgJobStr and string.len(bgJobStr) > 0 then
				self.viewData.bgJob:setSpriteFrame(bgJobStr)
			end
			if jobImgStr and string.len(jobImgStr) > 0  then
				self.viewData.jobImg:setSpriteFrame(jobImgStr)
			end
			--英雄星级显示
			self.viewData.starlayout:setVisible(true)
			self.viewData.starlayout:removeAllChildren()
			self.viewData.starlayout:setContentSize(cc.size(20*checkint(allrank),20))
			for i=1,checkint(allrank) do
				local lightStar = display.newImageView("#kapai_star_colour.png", 0, 0,{ap = cc.p(0.5, 0.5)})
				self.viewData.starlayout:addChild(lightStar,checkint(allrank) - i)
				lightStar:setPosition(cc.p(8+15*(i-1),10))
				lightStar:setScale(0.75 + 0.05 * i)
			end

			--英雄名字
			-- self.viewData.nameLabel:setString(name)
			CommonUtils.SetCardNameLabelStringById(self.viewData.nameLabel, id, self.viewData.nameLabelParams)
			-- 战斗力
			local playCardId = checkint(id)
			self.viewData.fightLabel:stopAllActions()
			self.viewData.fightLabel:runAction(
				cc.Sequence:create(
					cc.DelayTime:create(0.2),
					cc.CallFunc:create(function ()
						local fightNum = cardMgr.GetCardStaticBattlePointById(playCardId)
						self.viewData.fightLabel:setString(fightNum)
					end)
				)
			)
 			-- self.viewData.petLabel:setString(fightNum)
 			if CardData.playerPetId then
				local petDatas = gameMgr:GetPetDataById(CardData.playerPetId)
			-- 	local petData = CommonUtils.GetConfig('pet', 'pet', petDatas.petId)
			-- 	self.viewData.petLabel:setString(petData.name)

				local headIconPath = CommonUtils.GetGoodsIconPathById(petDatas.petId)
                self.viewData.showPetBg:setVisible(true)
                self.viewData.petEmptyLabel:setVisible(false)
				self.viewData.petImage:setTexture(headIconPath)
				self.viewData.petImage:setScale(0.55)
			else
                self.viewData.showPetBg:setVisible(false)
                self.viewData.petEmptyLabel:setVisible(true)
			-- 	self.viewData.petLabel:setString(__('暂无'))
				self.viewData.petImage:setTexture(_res('ui/common/maps_fight_btn_pet_add.png'))
				self.viewData.petImage:setScale(1)
			end


            --英雄属性描述
			local mesTab = {
				{pName = ObjP.ATTACK,		name = __('攻击力')},
				{pName = ObjP.DEFENCE,		name = __('防御力')},
				{pName = ObjP.HP, 			name = __('生命值')},
				{pName = ObjP.CRITRATE, 	name = __('暴击率')},
				{pName = ObjP.CRITDAMAGE,	name = __('暴伤值')},
				{pName = ObjP.ATTACKRATE,	name = __('攻击速度')},
			}

			local allAddP = app.cardMgr.GetCardAllFixedPById(CardData.id)

			for i,v in ipairs(mesTab) do
				local num = checknumber(allAddP[v.pName])
				local richlabel = self.viewData.tRichLabe[i]
				local richMesslabel = self.viewData.tMessNumRichLabe[i]
			 	richlabel:setString(v.name)
			  	richMesslabel:setString(tostring(num))
			end

		end
	end
end


return TeamFormationCellNew
