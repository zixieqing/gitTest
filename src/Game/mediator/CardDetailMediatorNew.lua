local Mediator = mvc.Mediator

local CardDetailMediatorNew = class("CardDetailMediatorNew", Mediator)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance('AppFacade'):GetManager("CardManager")
local petMgr = AppFacade.GetInstance('AppFacade'):GetManager("PetManager")

local NAME = "CardDetailMediatorNew"
local MOVE_DUR        = 0.3
CardDetail_UpDataUI_Callback = 'CardDetail_UpDataUI_Callback'

function CardDetailMediatorNew:ctor( params,viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.data = params[1][params[2]] or {}
	self.allHereDates = params[1] or {}
	self.index = params[2] or 1
	self.rightView = params[3]
	-- self.showStar = true
	-- dump(self.data)
	-- dump(self.allHereDates)
end


function CardDetailMediatorNew:InterestSignals()
	local signals = {
		SIGNALNAMES.Hero_LevelUp_Callback,
		SIGNALNAMES.Hero_Break_Callback,
		SIGNALNAMES.Hero_SkillUp_Callback,
		SIGNALNAMES.Hero_EquipPet_Callback,
		SIGNALNAMES.Hero_AddVigour_Callback,
		SIGNALNAMES.Hero_ChooseSkin_Callback,
		CardDetail_UpDataUI_Callback,
		SIGNALNAMES.Hero_BusinessSkillUp_Callback,
		EVENT_UPGRADE_LEVEL,
		EVENT_UPGRADE_BREAK,
		EVENT_UPGRADE_PROP,
		SIGNALNAMES.MaterialCompose_Callback,
	}

	return signals
end

function CardDetailMediatorNew:ProcessSignal(signal )
	local name = signal:GetName()
	-- print(name)
	-- dump(signal:GetBody())
	--ssds
	if name == SIGNALNAMES.Hero_Break_Callback then--突破
		-- print(' 英雄突破 ')
		PlayAudioClip(AUDIOS.UI.ui_star.id)
		local data = checktable(checktable(signal:GetBody()))
		local gold = checkint(data.gold)
		gameMgr:UpdateCardDataById(self.data.id, {breakLevel = data.breakLevel,businessSkill = data.businessSkill})

		local num = checkint(data.goodsNum) - gameMgr:GetAmountByGoodId(checkint(data.goodsId))
		local goldNum = gold - gameMgr:GetUserInfo().gold
		CommonUtils.DrawRewards({{goodsId = checkint(data.goodsId), num = num},{goodsId = GOLD_ID, num = goldNum}})
		-- dump(self.data)
		self.data.breakLevel = data.breakLevel
		self.data.BshowStarUpAction = true
		if data.businessSkill then
			self.data.businessSkill = data.businessSkill
		end
		-- dump(self.data)

		--刷新星星ui
		self:GetFacade():DispatchObservers(CardsList_ChangeCenterContainer,'showStar')

		--刷新图鉴
		self:GetFacade():DispatchObservers(SGL.CARD_COLL_RED_DATA_UPDATE, {cardId = self.data.cardId, taskType = CardUtils.CARD_COLL_TASK_TYPE.STAR_NUM, addNum = 1})

		if checkint(self.data.breakLevel)+1 >= table.nums(CommonUtils.GetConfig('cards', 'card',self.data.cardId).breakLevel) then
			local data = CommonUtils.GetConfig('cards', 'card', self.data.cardId)
			for k,v in pairs(data.skin) do
				if k == '2' then
					for kk,vv in pairs(v) do
						-- table.insert(self.data.skin,vv)
						gameMgr:UpdateCardSkinsBySkinId(vv)
					end
					break
				end
			end
		end

		self:updataUi( {data = self.data} )
		self:GetFacade():DispatchObservers('Hero_Break_show_card_voice_word', {cardId = self.data.cardId})


		local scene = uiMgr:GetCurrentScene()
		scene:AddViewForNoTouch()

	elseif name == SIGNALNAMES.Hero_SkillUp_Callback then--技能升级
		-- print(' 英雄技能升级 ')
		PlayAudioClip(AUDIOS.UI.ui_levelup.id)
		xTry(function()
			CommonUtils.PlayCardSoundByCardId(self.data.cardId,SoundType.TYPE_UPGRADE_STAR , SoundChannel.CARD_MANUAL)
		end,__G__TRACKBACK__)
		local data = checktable(checktable(signal:GetBody()))
		local skillId = data.skillId
		local level = data.newLevel
		local gold = data.gold

		local tempData = {}
		if checkint(CardUtils.GetSkillConfigBySkillId(skillId).property) == 4 then
			tempData = CommonUtils.GetConfig('cards', 'skillLevel', level).cpConsume
		else
			tempData = CommonUtils.GetConfig('cards', 'skillLevel', level).consume
		end
		local tempData = clone(tempData)
		for i,v in ipairs(tempData) do
			v.num = v.num * (-1)
		end
		CommonUtils.DrawRewards(tempData)

		-- dump(self.data)
		-- dump(skillId)
		-- dump(gameMgr:GetCardDataById(self.data.id))
		gameMgr:GetCardDataById(self.data.id).skill[tostring(skillId)].level = level
		self.data.skill[tostring(skillId)].level = level


	    local TSkillDataTab = {}
		for i,v in pairs(self.data.skill) do
			local tablee = {}
			tablee.skillId = i
			tablee.skillLevel = v.level
			table.insert(TSkillDataTab,tablee)
		end

	 	table.sort(TSkillDataTab, function(a, b)
	        return checkint(a.skillId) < checkint(b.skillId)
	    end)
	 	local index =1
	    for i,v in ipairs(TSkillDataTab) do
	    	if checkint(skillId) == checkint(v.skillId) then
	    		index = i
	    		break
	    	end
	    end
		self:updataUi( {data = self.data,showSkillIndex = index,showModel = 1})-- self.data ,index

	elseif name == SIGNALNAMES.Hero_BusinessSkillUp_Callback then--经营技能升级
		-- dump(signal:GetBody())
        PlayAudioClip(AUDIOS.UI.ui_star.id)
        xTry(function()
            CommonUtils.PlayCardSoundByCardId(self.data.cardId,SoundType.TYPE_UPGRADE_STAR , SoundChannel.CARD_MANUAL)
        end,__G__TRACKBACK__)

		local data = checktable(checktable(signal:GetBody()))
		local skillId = data.skillId
		local level = data.newLevel
		local gold = data.gold

		local consumeType = CommonUtils.GetConfig('business', 'assistantSkill', skillId).consumeType
		local tempData = clone(CommonUtils.GetConfig('business', 'assistantSkillLevel', consumeType)[tostring(level)].consume)

		-- local tempData = clone(CommonUtils.GetConfig('cards', 'assistantSkillLevel', level).consume)
		for i,v in ipairs(tempData) do
			v.num = v.num * (-1)
		end
		CommonUtils.DrawRewards(tempData)

		if gameMgr:GetCardDataById(self.data.id) then
            local businessSkillSpecData = gameMgr:GetCardDataById(self.data.id).businessSkill
            if businessSkillSpecData and businessSkillSpecData[tostring(skillId)] and businessSkillSpecData[tostring(skillId)].level then
                businessSkillSpecData[tostring(skillId)].level = level
            end
		end
		if not  self.data.businessSkill[tostring(skillId)] then
			self.data.businessSkill[tostring(skillId)] = {}
		end
		self.data.businessSkill[tostring(skillId)].level = level
		local t = CommonUtils.GetBusinessSkillByCardId(self.data.cardId, {from = 3})
	 	table.sort(t, function(a, b)
	        return checkint(a.skillId) < checkint(b.skillId)
	    end)

	    local index =1
		for i,v in ipairs(t) do
	    	if checkint(skillId) == checkint(v.skillId) then
	    		index = i
	    		break
	    	end
		end

		self:updataUi( {data = self.data,showSkillIndex = index,showModel = 2})-- self.data ,index
	elseif name == SIGNALNAMES.Hero_EquipPet_Callback then--装备堕神
        -- dump(signal:GetBody().requestData)
		-- print(' 英雄装备堕神')
		local data = checktable(checktable(signal:GetBody()))
        -- dump(self.data)
		if data.errcode then
			self:updataUi({data = self.data}  )
		else
			if data.requestData.operation == 2 then--将对应卡牌的playerPetId 和堕神对应的playerCardId 都置nil
                --这里是一个卸载下的操作逻辑
                if self.data.pets then
                    self.data.pets = {}
                end
				gameMgr:GetCardDataById(self.data.id).playerPetId = nil
				gameMgr:GetPetDataById(data.requestData.playerPetId).playerCardId = nil
				self.data.playerPetId = nil
				gameMgr:GetCardDataById(self.data.id).pets = {}
			else
				-- dump(self.data.playerPetId)
				if data.requestData.oldPlayerCardId then--说明是从其他卡牌上拿下来给自己装备的 将playerPetId制为nil
					gameMgr:GetCardDataById(data.requestData.oldPlayerCardId).playerPetId = nil
					gameMgr:GetCardDataById(data.requestData.oldPlayerCardId).pets = {}
					for i,v in ipairs(self.allHereDates) do
						if checkint(v.id) == checkint(data.requestData.oldPlayerCardId) then
							self.allHereDates[i].playerPetId = nil
							self.allHereDates[i].pets = {}
							break
						end
					end

				end

				--当前卡牌是否装备堕神。如果有将该堕神的playerCardId置为nil
				if self.data.playerPetId then
					gameMgr:GetPetDataById(self.data.playerPetId).playerCardId = nil
				end
				--将当前卡牌playerPetId置于选中堕神的playerPetId
				gameMgr:GetCardDataById(self.data.id).playerPetId = data.requestData.playerPetId

				---------- 刷新一次堕神数据 ----------
				local p_id = checkint(data.requestData.playerPetId)
				local petData = gameMgr:GetPetDataById(p_id)
				if nil ~= petData then
					gameMgr:GetCardDataById(self.data.id).pets = {
						['1'] = petMgr.ConvertOldPetData2NewPetData(petData)
					}
				else
					gameMgr:GetCardDataById(self.data.id).pets = {}
				end
				---------- 刷新一次堕神数据 ----------

				--将选中的堕神的playerCardId置于当前卡牌的id
				gameMgr:GetPetDataById(data.requestData.playerPetId).playerCardId = self.data.id

				self.data.playerPetId = data.requestData.playerPetId
			end
			self:updataUi({data = self.data}  )--self.data
		end
	elseif name == SIGNALNAMES.Hero_AddVigour_Callback then--增加新鲜度
		-- print(' 增加疲劳值')
		local data = checktable(checktable(signal:GetBody()))
		gameMgr:UpdateCardDataById(self.data.id, {vigour = data.vigour})

		CommonUtils.DrawRewards({{goodsId = checkint(data.requestData.goodsId), num = - checkint(data.requestData.num)}})

		self.data.vigour = data.vigour
		self.pageview:reloadData()
		local scene = uiMgr:GetCurrentScene()
		if scene:GetDialogByTag(444) then
			scene:GetDialogByTag(444):refreshUI(self.data)
		end
	elseif name == SIGNALNAMES.Hero_ChooseSkin_Callback then--选择皮肤
		gameMgr:GetCardDataById(self.data.id).defaultSkinId = signal:GetBody().requestData.skinId
		self.data.defaultSkinId = signal:GetBody().requestData.skinId
		self:updataUi({data = self.data} )
		self:GetFacade():DispatchObservers(CardsList_ChangeCenterContainer)
	elseif name == CardDetail_UpDataUI_Callback then--刷新界面
		self:updataUi({data = self.data} )
	elseif name == EVENT_UPGRADE_LEVEL or
		name == EVENT_UPGRADE_BREAK or name == EVENT_UPGRADE_PROP then
		-- 堕神升级成功
		-- 堕神强化成功
		-- 堕神洗炼成功
		-- dump(signal:GetBody())
		-- dump(self.data)
		self:updataUi({data = self.data} )

	elseif name == SIGNALNAMES.MaterialCompose_Callback then--合成
		self:updataUi({data = self.data})
	end
end

--index 显示刷新当前卡牌第几个技能详情
--bool 是否显示默认属性页面
--isShowAction 是否执行进入页面动画action
function CardDetailMediatorNew:updataUi( data)
	self.data = data.data
	if self.tempView then
		self.tempView:updataPanel(data)
	end
end

function CardDetailMediatorNew:showBackLayerAction1()
	if self.tempView then
		self.tempView:showBackLayerAction()
	end
end


function CardDetailMediatorNew:Initial( key )
	self.super.Initial(self,key)
	local tempView  = require( 'home.CardDetailPanelNew' ).new(self.data)
	tempView:setName('CardDetailPanelNew')
	tempView:setAnchorPoint(cc.p(0.5, 0.5))
	tempView:setPosition(cc.p(self.rightView:getContentSize().width* 0.5,self.rightView:getContentSize().height* 0.5))
	self.rightView:addChild(tempView,4)
	self.tempView = tempView
end


function CardDetailMediatorNew:OnRegist(  )
end

function CardDetailMediatorNew:OnUnRegist(  )
	print( "OnUnRegist" )
end

return CardDetailMediatorNew
