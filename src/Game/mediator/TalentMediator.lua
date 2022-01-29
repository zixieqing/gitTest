--[[
天赋Mediator
--]]
local Mediator = mvc.Mediator
local TalentMediator = class("TalentMediator", Mediator)
local NAME = "TalentMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local CONFIGNAME = {
	'talentDamage', -- 伤害系
	'talentAssist', -- 辅助系
	'talentControl', -- 控制系
	'talentBusiness'  -- 经营系
}
local TYPENAME = {
	__('伤害'), -- 伤害系
	__('辅助'), -- 辅助系
	__('控制'), -- 控制系
	__('经营')  -- 经营系
}
local DeviationX = (display.width - 1334)/2
local DeviationY = (display.height - 1002)/2
function TalentMediator:ctor( viewComponent )
	self.super:ctor(NAME, viewComponent)
	self.talentType = TalentType.DAMAGE
	self.talentDatas = {} -- 已点亮的天赋信息
	self.departMentDatas = {} -- 当前系别天赋信息
	self.selectSkill = 0 -- 当前选中的天赋
end

function TalentMediator:InterestSignals()
	local signals = {
	SIGNALNAMES.Talent_Talents_Callback,
	SIGNALNAMES.Talent_LightTalent_Callback,
	SIGNALNAMES.Talent_LevelUp_Callback,
	SIGNALNAMES.Talent_Reset_Callback,
	SIGNALNAMES.CACHE_MONEY_UPDATE_UI
}
return signals
end

function TalentMediator:ProcessSignal( signal )
	local name = signal:GetName()
	-- print(name)
	if name == SIGNALNAMES.Talent_Talents_Callback then
		-- dump(signal:GetBody())
        --显示进入的第一次引导
        if GuideUtils.HasModule(GUIDE_MODULES.MODULE_TALENT) then
            GuideUtils.SwitchModule(GUIDE_MODULES.MODULE_TALENT)
        end

		self.talentDatas = checktable(signal:GetBody())
		for k,v in pairs(self.talentDatas) do
			if not v.talents then
				v.talents = {}
			end
		end
		for i=1, 3 do
			self:UpdateTalentLevel(i)
		end
		self:RightButtonActions(self.talentType)
        local viewData = self:GetViewComponent().viewData
        if next(checktable(self.talentDatas[tostring(self.talentType)]).talents) ~= nil and (not viewData.upgradeBtn:isVisible()) then
            --表示有激活的数据
            GuideUtils.EnableShowSkip() --是否显示引导的逻辑
        end
	elseif name == SIGNALNAMES.Talent_LightTalent_Callback then -- 点亮天赋
		PlayAudioClip(AUDIOS.UI.ui_levelup.id)
		local data = signal:GetBody()

		local spread = false
		if next(self.talentDatas[tostring(self.talentType)].talents) == nil then
			spread = true
		end
		self.talentDatas[tostring(self.talentType)].talents[tostring(data.talentId)] = {
			cookingPoint = data.consumeCookingPoint,
			talentId 	 = data.talentId,
			level        = 1,
			type         = tostring(self.talentType)
		}

		local viewComponent = self:GetViewComponent()
		local point = tonumber(viewComponent.viewData.pointNum:getString()) - data.consumeCookingPoint
		viewComponent.viewData.pointNum:setString(tostring(point))
		self.talentDatas[tostring(self.talentType)].nextTalentCookingPoint = data.nextTalentCookingPoint
		self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
		uiMgr:ShowInformationTips(__('激活成功'))
		-- 更新天赋等级
		self.talentDatas[tostring(self.talentType)].talentLevel = tonumber(self.talentDatas[tostring(self.talentType)].talentLevel) + 1
		self:UpdateTalentLevel(self.talentType)
		-- 添加火焰效果
		self:GetViewComponent().viewData.skillPointBg_fire:stopAllActions()
		self:GetViewComponent().viewData.skillPointBg_fire:setOpacity(0)
		self:GetViewComponent().viewData.skillPointBg_fire:runAction(
			cc.Sequence:create(
				cc.FadeIn:create(0.4),
				cc.FadeOut:create(0.4)
			)
		)
		self:GetViewComponent().viewData.skillPointBg_effect:setToSetupPose()
		self:GetViewComponent().viewData.skillPointBg_effect:setAnimation(0, 'guo', false)
		if spread then
			local viewData = self:GetViewComponent().viewData
			viewData.upgradeBtn:setVisible(false)
			viewData.btnDescrLabel:setVisible(false)
			if viewData.cookImg then viewData.cookImg:setVisible(false) end
			viewData.skillName:setVisible(false)
			viewData.effectLabel:setVisible(false)
			viewData.descrLabel:setVisible(false)
			self:SpreadAction()
		else
			self:ChangeTalentTree(self.talentType)
			self:TalentIconCallback(tonumber(self.selectSkill))
			-- 添加升级特效
			self:AddUpgradeEffect(data.talentId)
		end

		-- 刷新本地技能数据
		local skillData = {
			skill = data.skill,
			allSkill = data.allSkill,
			cookingPoint = point
		}
		gameMgr:UpdatePlayer(skillData)
		self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, {cookingPoint = point})
		GuideUtils.DispatchStepEvent()
	elseif name == SIGNALNAMES.Talent_LevelUp_Callback then -- 天赋升级
		PlayAudioClip(AUDIOS.UI.ui_levelup.id)
		local data = signal:GetBody()
		self.talentDatas[tostring(self.talentType)].talents[tostring(data.talentId)].level = data.level
		self.talentDatas[tostring(self.talentType)].talents[tostring(data.talentId)].cookingPoint = self.talentDatas[tostring(self.talentType)].talents[tostring(data.talentId)].cookingPoint + data.consumeCookingPoint
		self.talentDatas[tostring(self.talentType)].talentLevel = tonumber(self.talentDatas[tostring(self.talentType)].talentLevel) + 1
		local viewComponent = self:GetViewComponent()
		local point = tonumber(viewComponent.viewData.pointNum:getString())- data.consumeCookingPoint
		viewComponent.viewData.pointNum:setString(tostring(point))
		self.talentDatas[tostring(self.talentType)].nextTalentCookingPoint = data.nextTalentCookingPoint
		uiMgr:ShowInformationTips(__('强化成功'))
		self:ChangeTalentTree(self.talentType)
		self:TalentIconCallback(tonumber(self.selectSkill))
		-- 更新天赋等级
		self:UpdateTalentLevel(self.talentType)
		-- 添加火焰效果
		self:GetViewComponent().viewData.skillPointBg_fire:stopAllActions()
		self:GetViewComponent().viewData.skillPointBg_fire:setOpacity(128)
		self:GetViewComponent().viewData.skillPointBg_fire:runAction(
			cc.Sequence:create(
				cc.FadeIn:create(0.4),
				cc.FadeOut:create(0.4)
			)
		)
		self:GetViewComponent().viewData.skillPointBg_effect:setToSetupPose()
		self:GetViewComponent().viewData.skillPointBg_effect:setAnimation(0, 'guo', false)
		-- 刷新本地技能数据
		local skillData = {
			cookingPoint = point,
			skill = data.skill,
			allSkill = data.allSkill
		}
		gameMgr:UpdatePlayer(skillData)
		self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, {cookingPoint = point})
		-- 添加升级特效
		self:AddUpgradeEffect(data.talentId)
		GuideUtils.DispatchStepEvent()
	elseif name == SIGNALNAMES.Talent_Reset_Callback then -- 重置天赋
		local data = signal:GetBody()
		self:GetViewComponent().viewData.pointNum:setString(tostring(data.cookingPoint))
		self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{diamond = data.diamond})
		self.talentDatas[tostring(self.talentType)].talentLevel = data.talentLevel
		self.talentDatas[tostring(self.talentType)].nextTalentCookingPoint = data.nextTalentCookingPoint
		self.talentDatas[tostring(self.talentType)].talents = {}
		self:UpdateTalentLevel(self.talentType)
		self:RightButtonActions(self.talentType)
		uiMgr:ShowInformationTips(__('重置成功'))

		-- 刷新本地技能数据
		local skillData = {
			skill = data.skill,
			allSkill = data.allSkill,
			cookingPoint = data.cookingPoint,
			diamond = data.diamond
		}
		gameMgr:UpdatePlayer(skillData)
		self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, {cookingPoint = data.cookingPoint, diamond = data.diamond})
	elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
		self:GetViewComponent().viewData.pointNum:setString(tostring(gameMgr:GetUserInfo().cookingPoint))
	end
end

function TalentMediator:Initial( key )
	self.super.Initial(self, key)
	-- local scene = uiMgr:GetCurrentScene()
	local viewComponent = uiMgr:SwitchToTargetScene('Game.views.TalentScene', {mediator = self})
	self:SetViewComponent(viewComponent)
	viewComponent.viewData.pointNum:setString(tostring(gameMgr:GetUserInfo().cookingPoint))
	viewComponent.viewData.upgradeBtn:setOnClickScriptHandler(handler(self, self.ButtonActions))
	viewComponent.viewData.resetTalentBtn:setOnClickScriptHandler(handler(self, self.ButtonActions))

	for i,v in ipairs(viewComponent.viewData.buttons) do
		v:setOnClickScriptHandler(handler(self,self.RightButtonActions))
	end
end
--[[
右边不同类型model按钮的事件处理逻辑
@param sender button对象
--]]
function TalentMediator:RightButtonActions( sender )
	local tag = 0
	if type(sender) == 'number' then
		tag = sender
	else
		tag = sender:getTag()%1000
		if self.talentType == tag then
			return
		end
	end
	-- 添加音效
	PlayAudioClip(AUDIOS.UI.ui_click_confirm.id)
	-----------------经营模式锁定------------------
	if tag == TalentType.BUSINESS then
		-- uiMgr:ShowInformationTips(__('暂未开放，敬请期待'))
		sender:setChecked(false)
	else
	-----------------经营模式锁定------------------
		self.selectSkill = nil
		local viewData = self:GetViewComponent().viewData
		for k, v in pairs( viewData.buttons ) do
			local curTag = v:getTag()%1000
			if tag == curTag then
				v:setChecked(true)
				v:setEnabled(false)
			else
				v:setChecked(false)
				v:setEnabled(true)
			end
		end
		viewData.resetTalentBtn:getLabel():setString(__('重置天赋'))
		viewData.view:getChildByTag(7000 + self.talentType):setLocalZOrder(-1)
		viewData.view:getChildByTag(7000 + tag):setLocalZOrder(10)
		self.talentType = tag
		self:ChangeTalentTree(tag)
		-- 添加选中动画
		local view = self:GetViewComponent().viewData.view
		if view:getChildByTag(9200) then
			view:getChildByTag(9200):removeFromParent()
		end
		local pos = {
			{x = 1360 + DeviationX, y = 738 + DeviationY},
			{x = 1420 + DeviationX, y = 624 + DeviationY},
			{x = 1430 + DeviationX, y = 510 + DeviationY},
			{x = 1410 + DeviationX, y = 393 + DeviationY}
		}
		local cloud = display.newImageView(_res('ui/home/talent/talent_btn_cloud.png'), pos[tag].x, pos[tag].y)
		cloud:setTag(9200)
		view:addChild(cloud, 10)
		cloud:runAction(
			cc.MoveBy:create(0.2, cc.p(-185, 0))
		)
	end

end
--[[
更新天赋树
@params int 天赋类型
--]]
function TalentMediator:ChangeTalentTree( talentType )
	local viewData = self:GetViewComponent().viewData
	viewData.upgradeBtn:setVisible(false)
	if viewData.cookImg then viewData.cookImg:setVisible(false) end
	viewData.btnDescrLabel:setVisible(false)
	viewData.skillName:setVisible(false)
	viewData.effectLabel:setVisible(false)
	viewData.descrLabel:setVisible(false)
	if viewData.view:getChildByTag(9999) then
		viewData.view:getChildByTag(9999):removeFromParent()
	end
	local skillDatas = CommonUtils.GetConfigAllMess(CONFIGNAME[talentType] , 'player')
	self.departMentDatas = skillDatas
	-- 判断当前天赋状态
	if next(self.talentDatas[tostring(talentType)].talents) == nil then
		self:AddRootTalent()
	else
		self:AddTalentTree()
	end
end
--[[
添加初始天赋
--]]
function TalentMediator:AddRootTalent()
	local viewData = self:GetViewComponent().viewData
	local  skillDatas = self.departMentDatas
	viewData.talentTreeBg:setTexture(_res('ui/home/talent/talent_bg_tree_' .. tostring(self.talentType) .. '_cover.png'))
	local layout = CLayout:create(viewData.bgSize)
    layout:setName('ROOT_TALENT')
	viewData.view:addChild(layout, 10)
	layout:setTag(9999)
	layout:setPosition(viewData.bgSize.width/2, viewData.bgSize.height/2)
	-- 添加天赋图标
	for k,v in pairs(skillDatas) do
		if v.beforeTalentId ==  nil then
			local skillIcon = FilteredSpriteWithOne:create()
	    	skillIcon:setTexture(_res('arts/talentskills/' .. tostring(v.icon) .. '.png'))
	    	skillIcon:setAnchorPoint(cc.p(0.5, 0.5))
	    	skillIcon:setTag(1111)
			local skillIconBtn = display.newButton(v.location.x + DeviationX , 1002 - v.location.y + DeviationY,
				{tag = tonumber(v.id), size = skillIcon:getContentSize()})
			layout:addChild(skillIconBtn)
            skillIconBtn:setName(string.format('TALENT_%d', checkint(v.id)))
			skillIconBtn:setOnClickScriptHandler(handler(self,self.TalentIconCallback))
			skillIconBtn:addChild(skillIcon)
			skillIcon:setPosition(cc.p(skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2))
			self:TalentIconCallback(v.id)
		end
	end
end
--[[
添加天赋树
--]]
function TalentMediator:AddTalentTree()
	local viewData = self:GetViewComponent().viewData
	local skillDatas = self.departMentDatas
	local talentData = self.talentDatas[tostring(self.talentType)]
	viewData.talentTreeBg:setTexture(_res('ui/home/talent/talent_bg_tree_' .. tostring(self.talentType) .. '.png'))
	local layout = CLayout:create(viewData.bgSize)
	viewData.view:addChild(layout, 10)
	layout:setTag(9999)
    layout:setName('ROOT_TALENT')
	layout:setPosition(viewData.bgSize.width/2, viewData.bgSize.height/2)

	local function getNextSkill (talentId)
		local nextskill = {}
		for _,v in ipairs(skillDatas[tostring(talentId)].afterTalentId) do
			if tonumber(v) ~= 0 then
				if tonumber(skillDatas[tostring(v)].style) == 2 then
					table.insert(nextskill, v)
				else
					table.insert(nextskill, getNextSkill(v))
				end
			end
		end
		if next(nextskill) ~= nil then
			if #nextskill == 1 then
				return nextskill[1]
			else
				return nextskill
			end
		else
			return 0
		end
	end
	local nextSkillDatas = {} -- 天赋的下一个主动天赋
	for k,v in pairs(skillDatas) do
		if tonumber(v.style) == 2 then
			nextSkillDatas[tostring(v.id)] = getNextSkill(v.id)
		end
	end
	-- dump(nextSkillDatas)
	-- 添加天赋图标
	for k,v in pairs(skillDatas) do
		local skillIcon = FilteredSpriteWithOne:create()
	    skillIcon:setTexture(_res('arts/talentskills/' .. tostring(v.icon) .. '.png'))
	    skillIcon:setAnchorPoint(cc.p(0.5, 0.5))
	    skillIcon:setTag(1111)
	    -- if self.talentDatas[tostring(self.talentType)].talents and talentData.talents[tostring(v.id)] == nil then
	    	-- local grayFilter = GrayFilter:create()
      --  		skillIcon:setFilter(grayFilter)
       	-- else
       		-- if v.pathLocation.x ~= '' or v.pathLocation.y ~= '' then
       		-- 	local path = display.newImageView(_res('ui/home/talent/path/path_' .. tostring(v.id) .. '.png'), v.pathLocation.x, 1002 - v.pathLocation.y)
       		-- 	layout:addChild(path, 5)
       		-- end
    	-- end
		local skillIconBtn = display.newButton(v.location.x + DeviationX, 1002 - v.location.y + DeviationY,
			{tag = tonumber(v.id), size = skillIcon:getContentSize()})
		layout:addChild(skillIconBtn)
		skillIconBtn:setOnClickScriptHandler(handler(self,self.TalentIconCallback))
		skillIconBtn:addChild(skillIcon)
		skillIcon:setPosition(cc.p(skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2))
		skillIconBtn:setScale(v.scale)
        skillIconBtn:setName(string.format('TALENT_%d', v.id))

		-- 添加满级的技能框
		-- local talent = talentData.talents[tostring(v.id)]
		-- if talent and tonumber(talent.level) == tonumber(v.level) then -- 判断当前天赋是否满级
		-- 	if tonumber(v.style) == 1 then -- 被动天赋
		-- 		-- skillIcon:setTexture(_res('ui/home/talent/skill/' .. tostring(v.icon) .. '_1.png'))
		-- 	elseif tonumber(v.style) == 2 then -- 主动天赋
		-- 		local maxBg = display.newImageView(_res('ui/home/talent/talent_skill_max.png'), skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2)
		-- 		skillIconBtn:addChild(maxBg)
		-- 	elseif tonumber(v.style) == 3 then -- 特殊天赋
		-- 	end
		-- end
		-- 是否显示技能等级
		local skillLevel = 0
		if talentData.talents and talentData.talents[tostring(v.id)] then
			skillLevel = tonumber(talentData.talents[tostring(v.id)].level)
		end
		if skillLevel < tonumber(v.level) then
			if skillLevel == 0 then
				local canUpgrade = true
				for _,beforeTalentId in pairs(checktable(v.beforeTalentId)) do
					local beforeSkillLevel = tonumber(skillDatas[tostring(beforeTalentId)].level)
					if not talentData.talents[tostring(beforeTalentId)] or tonumber(talentData.talents[tostring(beforeTalentId)].level) ~= beforeSkillLevel then
						canUpgrade = false
						break
					end
				end
				if canUpgrade then
					-- 添加路径
					if v.pathLocation.x ~= '' or v.pathLocation.y ~= '' then
       					local path = display.newImageView(_res('ui/home/talent/path/path_' .. tostring(v.id) .. '.png'), v.pathLocation.x + DeviationX, 1002 - v.pathLocation.y + DeviationY)
       					layout:addChild(path, 5)
       				end
					local levelBg = display.newButton(v.location.x + DeviationX, 1002 - v.location.y + DeviationY - (skillIconBtn:getContentSize().height/2*v.scale),
						{n = _res('ui/home/talent/talent_bg_skill_number.png'), enable = false}
					)
					layout:addChild(levelBg, 10)
					display.commonLabelParams(levelBg, {text = string.fmt('(%1/%2)', skillLevel, v.level), fontSize = 22, color = '#ffffff'})
					-- 如果技能为被动技能更改技能图标
					if tonumber(v.style) == 1 then
						skillIcon:setTexture(_res('arts/talentskills/' .. tostring(v.icon) .. '_1.png'))
						local talent_effect = sp.SkeletonAnimation:create(
       					    'effects/talent/tf2.json',
       					    'effects/talent/tf2.atlas',
       					    1)
       					skillIconBtn:addChild(talent_effect)
       					talent_effect:setAnimation(0, 'xiaoqiu', true)
       					talent_effect:setPosition(cc.p(skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2))
					end
				else -- 不能升级的按钮变为灰色
						skillIcon:setOpacity(0)
					-- local grayFilter = GrayFilter:create()
     	  			-- skillIcon:setFilter(grayFilter)
				end
			else
				-- 添加可选技能框
				if tonumber(v.style) == 2 then
					local temp = nextSkillDatas[tostring(v.id)]
					if tolua.type(temp) == 'table' then
						if tonumber(temp[1]) == 0 then
							local maxBg = display.newImageView(_res('ui/home/talent/talent_skill_max.png'), skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2)
							skillIconBtn:addChild(maxBg)
							local talent_effect = sp.SkeletonAnimation:create(
       						    'effects/talent/tf2.json',
       						    'effects/talent/tf2.atlas',
       						    1)
       						skillIconBtn:addChild(talent_effect)
       						talent_effect:setAnimation(0, 'daqiu', true)
       						talent_effect:setPosition(cc.p(skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2))
						else
							local isShow = true
							for _,value in ipairs(temp) do
								if talentData.talents[tostring(value)] then
									isShow = false
									break
								end
							end
							if isShow then
								local maxBg = display.newImageView(_res('ui/home/talent/talent_skill_max.png'), skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2)
								skillIconBtn:addChild(maxBg)
								local talent_effect = sp.SkeletonAnimation:create(
       							    'effects/talent/tf2.json',
       							    'effects/talent/tf2.atlas',
       							    1)
       							skillIconBtn:addChild(talent_effect)
       							talent_effect:setAnimation(0, 'daqiu', true)
       							talent_effect:setPosition(cc.p(skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2))
							end
						end
					else
						if tonumber(temp) ~= 0 then
							if not talentData.talents[tostring(temp)] then
								local maxBg = display.newImageView(_res('ui/home/talent/talent_skill_max.png'), skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2)
								skillIconBtn:addChild(maxBg)
								local talent_effect = sp.SkeletonAnimation:create(
       							    'effects/talent/tf2.json',
       							    'effects/talent/tf2.atlas',
       							    1)
       							skillIconBtn:addChild(talent_effect)
       							talent_effect:setAnimation(0, 'daqiu', true)
       							talent_effect:setPosition(cc.p(skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2))
							end
						else
							local maxBg = display.newImageView(_res('ui/home/talent/talent_skill_max.png'), skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2)
							skillIconBtn:addChild(maxBg)
							local talent_effect = sp.SkeletonAnimation:create(
       						    'effects/talent/tf2.json',
       						    'effects/talent/tf2.atlas',
       						    1)
       						skillIconBtn:addChild(talent_effect)
       						talent_effect:setAnimation(0, 'daqiu', true)
       						talent_effect:setPosition(cc.p(skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2))
						end
					end
				end

				-- 添加路径
				if v.pathLocation.x ~= '' or v.pathLocation.y ~= '' then
       				local path = display.newImageView(_res('ui/home/talent/path/path_' .. tostring(v.id) .. '.png'), v.pathLocation.x + DeviationX, 1002 - v.pathLocation.y + DeviationY)
       				layout:addChild(path, 5)
       			end
				local levelBg = display.newButton(v.location.x + DeviationX, 1002 - v.location.y + DeviationY - (skillIconBtn:getContentSize().height/2*v.scale),
					{n = _res('ui/home/talent/talent_bg_skill_number.png'), enable = false}
				)
				layout:addChild(levelBg, 10)
				display.commonLabelParams(levelBg, {text = string.fmt('(%1/%2)', skillLevel, v.level), fontSize = 22, color = '#ffffff'})
				-- 如果技能为被动技能更改技能图标
				if tonumber(v.style) == 1 then
					skillIcon:setTexture(_res('arts/talentskills/' .. tostring(v.icon) .. '_1.png'))

					local talent_effect = sp.SkeletonAnimation:create(
       				    'effects/talent/tf2.json',
       				    'effects/talent/tf2.atlas',
       				    1)
       				skillIconBtn:addChild(talent_effect)
       				talent_effect:setAnimation(0, 'xiaoqiu', true)
       				talent_effect:setPosition(cc.p(skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2))
				end
			end
		else
			-- 添加可选技能框
			if tonumber(v.style) == 2 then
				local temp = nextSkillDatas[tostring(v.id)]
				if tolua.type(temp) == 'table' then
					if tonumber(temp[1]) == 0 then
						local maxBg = display.newImageView(_res('ui/home/talent/talent_skill_max.png'), skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2)
						skillIconBtn:addChild(maxBg)
						local talent_effect = sp.SkeletonAnimation:create(
       					    'effects/talent/tf2.json',
       					    'effects/talent/tf2.atlas',
       					    1)
       					skillIconBtn:addChild(talent_effect)
       					talent_effect:setAnimation(0, 'daqiu', true)
       					talent_effect:setPosition(cc.p(skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2))
					else
						local isShow = true
						for _,value in ipairs(temp) do
							if talentData.talents[tostring(value)] then
								isShow = false
								break
							end
						end
						if isShow then
							local maxBg = display.newImageView(_res('ui/home/talent/talent_skill_max.png'), skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2)
							skillIconBtn:addChild(maxBg)
							local talent_effect = sp.SkeletonAnimation:create(
       						    'effects/talent/tf2.json',
       						    'effects/talent/tf2.atlas',
       						    1)
       						skillIconBtn:addChild(talent_effect)
       						talent_effect:setAnimation(0, 'daqiu', true)
       						talent_effect:setPosition(cc.p(skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2))
						end
					end
				else
					if tonumber(temp) ~= 0 then
						if not talentData.talents[tostring(temp)] then
							local maxBg = display.newImageView(_res('ui/home/talent/talent_skill_max.png'), skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2)
							skillIconBtn:addChild(maxBg)
							local talent_effect = sp.SkeletonAnimation:create(
       						    'effects/talent/tf2.json',
       						    'effects/talent/tf2.atlas',
       						    1)
       						skillIconBtn:addChild(talent_effect)
       						talent_effect:setAnimation(0, 'daqiu', true)
       						talent_effect:setPosition(cc.p(skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2))
						end
					else
						local maxBg = display.newImageView(_res('ui/home/talent/talent_skill_max.png'), skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2)
						skillIconBtn:addChild(maxBg)
						local talent_effect = sp.SkeletonAnimation:create(
       					    'effects/talent/tf2.json',
       					    'effects/talent/tf2.atlas',
       					    1)
       					skillIconBtn:addChild(talent_effect)
       					talent_effect:setAnimation(0, 'daqiu', true)
       					talent_effect:setPosition(cc.p(skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2))
					end
				end
			end
			-- 添加路径
			if v.pathLocation.x ~= '' or v.pathLocation.y ~= '' then
       			local path = display.newImageView(_res('ui/home/talent/path/path_' .. tostring(v.id) .. '.png'), v.pathLocation.x + DeviationX, 1002 - v.pathLocation.y + DeviationY)
       			layout:addChild(path, 5)
       		end
		end
		-- 切换页面时默认选择第一个天赋
		if v.beforeTalentId ==  nil then
			if not self.selectSkill then
				self:TalentIconCallback(v.id)
			end
		end
	end
end
function TalentMediator:TalentIconCallback( sender )
	local tag = nil
	if type(sender) == 'number' then
		tag = sender
	else
		tag = sender:getTag()
		if tag == self.selectSkill then
			return
		end
		PlayAudioByClickNormal()
	end
	-- 添加音效
    GuideUtils.DispatchStepEvent()
	local skillData = self.departMentDatas[tostring(tag)]
	local viewData = self:GetViewComponent().viewData
	local view = viewData.view:getChildByTag(9999)
	if view:getChildByTag(9000) then
		view:getChildByTag(9000):removeFromParent()
	end
	if skillData ~= nil then
		-- 更新界面
		viewData.skillName:setVisible(true)
		viewData.effectLabel:setVisible(true)
		viewData.descrLabel:setVisible(true)
		-- 添加选中状态
		if tonumber(skillData.style) == 1 then -- 被动天赋
			viewData.effectLabel:setString(__('被动'))
			local icon = view:getChildByTag(tag)
			local checkBox = self:GetCheckBox()
			checkBox:setPosition(cc.p(icon:getPositionX(), icon:getPositionY()))
			view:addChild(checkBox)
			checkBox:setScale(0.36)
			checkBox:setTag(9000)
		elseif tonumber(skillData.style) == 2 then -- 主动天赋
			viewData.effectLabel:setString(__('主动'))
			local icon = view:getChildByTag(tag)
			local checkBox = self:GetCheckBox()
			checkBox:setPosition(cc.p(icon:getPositionX(), icon:getPositionY()))
			view:addChild(checkBox)
			checkBox:setScale(skillData.scale)
			checkBox:setTag(9000)
		elseif tonumber(skillData.style) == 3 then -- 特殊天赋
			viewData.effectLabel:setString(__('被动'))
			local icon = view:getChildByTag(tag)
			local checkBox = self:GetCheckBox()
			checkBox:setPosition(cc.p(icon:getPositionX(), icon:getPositionY()))
			view:addChild(checkBox)
			checkBox:setScale(0.52)
			if next(self.talentDatas[tostring(self.talentType)].talents) == nil then
				checkBox:setScale(0.75)
			else
				checkBox:setScale(0.60)
			end
			checkBox:setTag(9000)
		end
		local skillLevel = 0
		if self.talentDatas[tostring(self.talentType)].talents and self.talentDatas[tostring(self.talentType)].talents[tostring(tag)] then
			skillLevel = tonumber(self.talentDatas[tostring(self.talentType)].talents[tostring(tag)].level)
		end
		viewData.skillName:setString(skillData.name .. string.fmt('(%1/%2)', skillLevel, skillData.level))
		local skillId = skillData.skill[1]
		if skillLevel ~= 0 then
			skillId = skillData.skill[skillLevel]
			viewData.descrLabel:setString(CommonUtils.GetConfig('player', 'skill', skillId).descr)
			viewData.upgradeBtn:getLabel():setString(__('强化'))
		else
			viewData.descrLabel:setString(CommonUtils.GetConfig('player', 'skill', skillId).descr0)
			viewData.upgradeBtn:getLabel():setString(__('激活'))
		end
        local descrContainer = viewData.descrContainer
        local descrScrollTop = descrContainer:getViewSize().height - display.getLabelContentSize(viewData.descrLabel).height
        descrContainer:setContentOffset(cc.p(0, descrScrollTop))

		if skillLevel == tonumber(skillData.level) then -- 天赋已满级
			viewData.upgradeBtn:setVisible(false)
			viewData.btnDescrLabel:setVisible(true)
			viewData.btnDescrLabel:setString(__('天赋已满级'))
			if viewData.cookImg then viewData.cookImg:setVisible(false) end
		elseif skillLevel ~= 0 and skillLevel < tonumber(skillData.level) then -- 升级天赋
			viewData.upgradeBtn:setTag(8002)
			viewData.upgradeBtn:setVisible(true)
			viewData.btnDescrLabel:setVisible(true)
			viewData.upgradeBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
			viewData.upgradeBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
			viewData.btnDescrLabel:setString(string.fmt(__('消耗_num_点厨力点'), {['_num_'] = self.talentDatas[tostring(self.talentType)].nextTalentCookingPoint}))
			if viewData.cookImg then 
				viewData.cookImg:setVisible(true)
				viewData.cookImg:setPositionX(viewData.btnDescrLabel:getPositionX() - display.getLabelContentSize(viewData.btnDescrLabel).width / 2 - 15)
			end
		elseif skillLevel == 0 then -- 天赋未点亮
			viewData.upgradeBtn:setTag(8001)
			viewData.upgradeBtn:setVisible(true)
			viewData.btnDescrLabel:setVisible(true)
			viewData.upgradeBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
			viewData.upgradeBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
			viewData.btnDescrLabel:setString(string.fmt(__('消耗_num_点厨力点'), {['_num_'] = self.talentDatas[tostring(self.talentType)].nextTalentCookingPoint}))
			if viewData.cookImg then
				viewData.cookImg:setVisible(true)
				viewData.cookImg:setPositionX(viewData.btnDescrLabel:getPositionX() - display.getLabelContentSize(viewData.btnDescrLabel).width / 2 - 15)
			end
			for k,v in pairs(checktable(self.departMentDatas[tostring(tag)].beforeTalentId)) do
				if self.talentDatas[tostring(self.talentType)].talents and self.talentDatas[tostring(self.talentType)].talents[tostring(v)] then
					if tonumber(self.talentDatas[tostring(self.talentType)].talents[tostring(v)].level) < tonumber(self.departMentDatas[tostring(v)].level) then
						viewData.upgradeBtn:setTag(8003)
						viewData.upgradeBtn:setVisible(true)
						viewData.btnDescrLabel:setVisible(true)
						viewData.btnDescrLabel:setString(__('需前置天赋满级'))
						if viewData.cookImg then viewData.cookImg:setVisible(false) end
						viewData.upgradeBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
						viewData.upgradeBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
					end
				else
					viewData.upgradeBtn:setTag(8003)
					viewData.upgradeBtn:setVisible(true)
					viewData.btnDescrLabel:setVisible(true)
					viewData.btnDescrLabel:setString(__('需前置天赋满级'))
					if viewData.cookImg then viewData.cookImg:setVisible(false) end
					viewData.upgradeBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
					viewData.upgradeBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
					break
				end
			end
		end

		self.selectSkill = tag
	end
	if not isJapanSdk() then display.commonLabelParams(viewData.btnDescrLabel , { w  = 270 , hAlign = display.TAC }) end
end
function TalentMediator:ButtonActions( sender )
	local tag = sender:getTag()
	PlayAudioByClickNormal()
	if tag == 8001 then -- 点亮天赋
		if gameMgr:GetUserInfo().cookingPoint >= tonumber(self.talentDatas[tostring(self.talentType)].nextTalentCookingPoint) then
			self:SendSignal(COMMANDS.COMMAND_Talent_LightTalent, {talentId = self.departMentDatas[tostring(self.selectSkill)].id})
		else
			uiMgr:ShowInformationTips(__('厨力不足'))
            GuideUtils.EnableShowSkip() --是否显示引导的逻辑
		end
	elseif tag == 8002 then -- 升级天赋
		if gameMgr:GetUserInfo().cookingPoint >= tonumber(self.talentDatas[tostring(self.talentType)].nextTalentCookingPoint) then
			self:SendSignal(COMMANDS.COMMAND_Talent_LevelUp, {talentId = self.departMentDatas[tostring(self.selectSkill)].id})
		else
			uiMgr:ShowInformationTips(__('厨力不足'))
            GuideUtils.EnableShowSkip() --是否显示引导的逻辑
		end
	elseif tag == 8003 then -- 不能点亮
		uiMgr:ShowInformationTips(__('需前置天赋满级'))
	elseif tag == 8010 then -- 重置按钮
		-- print('重置按钮')
		local layer = require('Game.views.TalentResetView').new({mediatorName = NAME, tag = tag})
		display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
		layer:setTag(tag)
		uiMgr:GetCurrentScene():AddDialog(layer)
		layer.viewData.freeResetBtn:setOnClickScriptHandler(handler(self, self.ResetButtonActions))
		layer.viewData.diamondResetBtn:setOnClickScriptHandler(handler(self, self.ResetButtonActions))
		local cookingPoint = 0
		for k,v in pairs(self.talentDatas[tostring(self.talentType)].talents) do
			cookingPoint = cookingPoint + tonumber(v.cookingPoint)
		end
		local strs = string.split(string.fmt(__('当前在|<_type_>|天赋中已投入|_num_|点厨力。\n|要用哪种方式重置呢?'),
			{['_type_'] = TYPENAME[self.talentType], ['_num_'] = tostring(cookingPoint)}), '|')
		display.reloadRichLabel(layer.viewData.descrLabel, {c =
			{
				{text = strs[1], fontSize = 24, color = '#5c5c5c'},
				{text = strs[2], fontSize = 24, color = '#c24242'},
				{text = strs[3], fontSize = 24, color = '#5c5c5c'},
				{text = strs[4], fontSize = 24, color = '#c24242'},
				{text = strs[5], fontSize = 24, color = '#5c5c5c'},
				{text = strs[6], fontSize = 24, color = '#5c5c5c'}
			}
		})
		CommonUtils.SetNodeScale(layer.viewData.descrLabel,{width = 530})
		local strs2 = string.split(string.fmt(__('损失|_num1_|点厨力\n|回收|_num2_|点厨力'),
			{['_num1_'] = tostring(cookingPoint - math.floor(cookingPoint*0.75 + 0.5)), ['_num2_'] = tostring(math.floor(cookingPoint*0.75 + 0.5))}), '|')
		display.reloadRichLabel(layer.viewData.freeDescrLabel, {c =
			{
				{text = strs2[1], fontSize = 24, color = '#5c5c5c'},
				{text = strs2[2], fontSize = 24, color = '#c24242'},
				{text = strs2[3], fontSize = 24, color = '#5c5c5c'},
				{text = strs2[4], fontSize = 24, color = '#5c5c5c'},
				{text = strs2[5], fontSize = 24, color = '#c24242'},
				{text = strs2[6], fontSize = 24, color = '#5c5c5c'}
			}
		})
		local strs3 = string.split(string.fmt(__('消耗|_num1_|幻晶石\n|回收全部厨力点'),{['_num1_'] = math.ceil(cookingPoint/100)}), '|')
		display.reloadRichLabel(layer.viewData.diamondDescrLabel, {c =
			{
				{text = strs3[1], fontSize = 24, color = '#5c5c5c'},
				{text = strs3[2], fontSize = 24, color = '#c24242'},
				{text = strs3[3], fontSize = 24, color = '#5c5c5c'},
				{text = strs3[4], fontSize = 24, color = '#5c5c5c'}
			}
		})
		CommonUtils.SetNodeScale(layer.viewData.diamondDescrLabel , {width = 250,height = 120 })
		CommonUtils.SetNodeScale(layer.viewData.freeDescrLabel , {width = 250  ,height = 120 })
	end
end
--[[
创建选中框
--]]
function TalentMediator:GetCheckBox()
	local framePos = {
		{x = 208, y = 112, movePos = cc.p(- 10, 0)},
		{x = 112, y = 16, movePos = cc.p(0, 10)},
		{x = 16, y = 112, movePos = cc.p(10, 0)},
		{x = 112, y = 208, movePos = cc.p(0, -10)}
	}
	local checkBox = CLayout:create(cc.size(224, 224))
	for i=1,4 do
		local selectImg = display.newImageView(_res('ui/home/talent/talent_skill_select_ultimate.png'), framePos[i].x, framePos[i].y)
		checkBox:addChild(selectImg)
		selectImg:setRotation(90*i)
		local moveBy = cc.MoveBy:create(0.3, framePos[i].movePos)
		selectImg:runAction(
			cc.RepeatForever:create(
				cc.Sequence:create(
					moveBy,
					moveBy:reverse()
				)
			)
		)
	end
	return checkBox
end
function TalentMediator:ResetButtonActions( sender )
	local tag = sender:getTag()
	PlayAudioByClickNormal()
	if next(self.talentDatas[tostring(self.talentType)].talents) ~= nil then
		if tag == 8101 then
			-- print('免费重置')
			local scene = uiMgr:GetCurrentScene()
			local cookingPoint = 0
			for k,v in pairs(self.talentDatas[tostring(self.talentType)].talents) do
				cookingPoint = cookingPoint + tonumber(v.cookingPoint)
			end
			local strs = string.split(string.fmt(__('Tips:将损失|_num1_|点厨力，仅回收|_num2_|点厨力'),{['_num1_'] = tostring(cookingPoint - math.floor(cookingPoint*0.75 + 0.5)), ['_num2_'] = tostring(math.floor(cookingPoint*0.75 + 0.5))}), '|')
 			local CommonTip  = require( 'common.NewCommonTip' ).new({extra = {
 				{text = strs[1], fontSize = 20, color = '#5c5c5c'},
 				{text = strs[2], fontSize = 20, color = '#c24242'},
 				{text = strs[3], fontSize = 20, color = '#5c5c5c'},
 				{text = strs[4], fontSize = 20, color = '#c24242'},
 				{text = strs[5], fontSize = 20, color = '#5c5c5c'}
 				},
				text = __('确定要使用普通重置吗?'),
 				isOnlyOK = false, callback = function ()
 				self:SendSignal(COMMANDS.COMMAND_Talent_Reset, {talentType = self.talentType, resetType = 1})
 				uiMgr:GetCurrentScene():RemoveDialogByTag(8010)
			end,
			cancelBack = function ()
				print('返回')
			end})
			CommonTip:setPosition(display.center)
			scene:AddDialog(CommonTip)

		elseif tag == 8102 then
			local scene = uiMgr:GetCurrentScene()
			local cookingPoint = 0
			for k,v in pairs(self.talentDatas[tostring(self.talentType)].talents) do
				cookingPoint = cookingPoint + tonumber(v.cookingPoint)
			end
			local strs = string.split(string.fmt(__('Tips:将损失|_num1_|幻晶石，回收|_num2_|点厨力'),{['_num1_'] = tostring(math.ceil(cookingPoint/100)), ['_num2_'] = cookingPoint}), '|')
 			local CommonTip  = require( 'common.NewCommonTip' ).new({extra = {
 				{text = strs[1], fontSize = 20, color = '#5c5c5c'},
 				{text = strs[2], fontSize = 20, color = '#c24242'},
 				{text = strs[3], fontSize = 20, color = '#5c5c5c'},
 				{text = strs[4], fontSize = 20, color = '#c24242'},
 				{text = strs[5], fontSize = 20, color = '#5c5c5c'}
 				},
				text = __('确定要使用幻晶石重置吗?'),
 				isOnlyOK = false, callback = function ()
 				self:SendSignal(COMMANDS.COMMAND_Talent_Reset, {talentType = self.talentType, resetType = 2})
 				uiMgr:GetCurrentScene():RemoveDialogByTag(8010)
			end,
			cancelBack = function ()
				print('返回')
			end})
			CommonTip:setPosition(display.center)
			scene:AddDialog(CommonTip)

		end
		-- uiMgr:GetCurrentScene():RemoveDialogByTag(8010)
	else
		uiMgr:ShowInformationTips(__('还没有天赋被点亮'))
	end

end
--[[
更新天赋总等级
@params int 天赋类型
--]]
function TalentMediator:UpdateTalentLevel( talentType )
	local view = self:GetViewComponent().viewData.view
	local layout = view:getChildByTag(talentType+7000)
	local levelLabel = layout:getChildByTag(7100)
	display.commonLabelParams(levelLabel , { text = string.fmt(__('_num_级'), {['_num_'] = self.talentDatas[tostring(talentType)].talentLevel})})
	local numBg = layout:getChildByTag(7101)
	local numBgSize = numBg:getContentSize()
	numBg:setContentSize(cc.size(display.getLabelContentSize(levelLabel).width +20 , numBgSize.height ))
end
--[[
切换动画
--]]
function TalentMediator:SpreadAction()
	local viewData = self:GetViewComponent().viewData
	local layout = viewData.view:getChildByTag(9999)

	for k,v in pairs(self.departMentDatas) do
		if v.beforeTalentId == nil then
			local btn = layout:getChildByTag(v.id)
			btn:getChildByTag(1111):clearFilter()
			if layout:getChildByTag(9000) then -- 移除选中框
				layout:getChildByTag(9000):removeFromParent()
				self.selectSkill = nil
			end
			local bottomBg = display.newImageView(_res('ui/home/talent/talent_bg_tree_' .. tostring(self.talentType) .. '_cover.png'), layout:getContentSize().width/2, layout:getContentSize().height/2)
			viewData.view:addChild(bottomBg)
			viewData.talentTreeBg:setTexture(_res('ui/home/talent/talent_bg_tree_' .. tostring(self.talentType) .. '.png'))
			viewData.talentTreeBg:setOpacity(0)
			viewData.talentTreeBg:runAction(
				cc.Sequence:create(
					cc.FadeIn:create(1),
					cc.TargetedAction:create(bottomBg, cc.RemoveSelf:create())
				)
			)
			local effectSpine = sp.SkeletonAnimation:create(
   			    'effects/talent/tianfu.json',
   			    'effects/talent/tianfu.atlas',
   			    1)
   			effectSpine:setAnimation(0, 'play', false)
   			effectSpine:setTag(9100)
   			layout:addChild(effectSpine, 5)
   			effectSpine:setPosition(cc.p(v.location.x + DeviationX, 1002 - v.location.y + DeviationY))
			effectSpine:registerSpineEventHandler(handler(self, self.spineEndHandler), sp.EventType.ANIMATION_END)
			effectSpine:registerSpineEventHandler(handler(self, self.spineEventHandler), sp.EventType.ANIMATION_EVENT)
			local effectSpine2 = sp.SkeletonAnimation:create(
   			    'effects/talent/tianfu.json',
   			    'effects/talent/tianfu.atlas',
   			    1)
   			effectSpine2:setAnimation(0, 'play2', false)
   			layout:addChild(effectSpine2, 5)
   			effectSpine2:setPosition(cc.p(DeviationX, DeviationY))
			effectSpine2:registerSpineEventHandler(function()
					effectSpine2:runAction(cc.RemoveSelf:create())
				end, sp.EventType.ANIMATION_END)
			break
		end
	end
end
function TalentMediator:spineEndHandler( event )
	local viewData = self:GetViewComponent().viewData
	local layout = viewData.view:getChildByTag(9999)
	layout:getChildByTag(9100):runAction(cc.RemoveSelf:create())
end

function TalentMediator:spineEventHandler( event )
	local eventName = event.eventData.name
	local skillDatas = self.departMentDatas
	if not skillDatas then return end
	if eventName == 'play' then
		local viewData = self:GetViewComponent().viewData
		local layout = viewData.view:getChildByTag(9999)
		local talentData = self.talentDatas[tostring(self.talentType)]
		-- 获取当前天赋的顺序
		local function GetSeq( beforeData, index )
			local seq = index or 0
			local temp = seq
			for i,id in ipairs(beforeData) do
				if self.departMentDatas[tostring(id)] then
					local beforeData = self.departMentDatas[tostring(id)].beforeTalentId or {}
					newNum = GetSeq(beforeData, temp+1)
					if seq < newNum then
						seq = newNum
					end
				end
			end
			return seq
		end

		for i,v in pairs(self.departMentDatas) do
			if v.beforeTalentId == nil then
				local btn = layout:getChildByTag(v.id)
				local lightRing = sp.SkeletonAnimation:create(
   				    'effects/talent/quan.json',
   				    'effects/talent/quan.atlas',
   				    1)
   				lightRing:setAnimation(0, v.color, false)
   				layout:addChild(lightRing, 5)
   				lightRing:setPosition(cc.p(v.location.x + DeviationX, 1002 - v.location.y + DeviationY))
				lightRing:registerSpineEventHandler(function()
					lightRing:runAction(cc.RemoveSelf:create())
				 end, sp.EventType.ANIMATION_END)
				btn:runAction(cc.ScaleTo:create(0.05, v.scale))

				-- 添加技能等级
				local skillLevel = 0
				if talentData.talents[tostring(v.id)] then
					skillLevel = tonumber(talentData.talents[tostring(v.id)].level)
				end
				if skillLevel < tonumber(v.level) then
					local levelBg = display.newButton(v.location.x + DeviationX, 1002 - v.location.y + DeviationY - (btn:getContentSize().height/2*v.scale),
						{n = _res('ui/home/talent/talent_bg_skill_number.png'), enable = false}
					)
					layout:addChild(levelBg, 10)
					display.commonLabelParams(levelBg, {text = string.fmt('(%1/%2)', skillLevel, v.level), fontSize = 22, color = '#ffffff'})
				end
			else
				local skillIcon = FilteredSpriteWithOne:create()
	    		skillIcon:setTexture(_res('arts/talentskills/' .. tostring(v.icon) .. '.png'))
	    		skillIcon:setAnchorPoint(cc.p(0.5, 0.5))
	    		skillIcon:setTag(1111)

				local skillIconBtn = display.newButton(v.location.x + DeviationX, 1002 - v.location.y + DeviationY,
					{tag = tonumber(v.id), size = skillIcon:getContentSize()})
				layout:addChild(skillIconBtn)
				skillIconBtn:setOnClickScriptHandler(handler(self,self.TalentIconCallback))
				skillIconBtn:addChild(skillIcon)
                skillIconBtn:setName(string.format('TALENT_%d',checkint(v.id)))
				skillIcon:setPosition(cc.p(skillIconBtn:getContentSize().width/2, skillIconBtn:getContentSize().height/2))
				skillIconBtn:setScale(v.scale*0.5)
				skillIconBtn:setVisible(false)
				-- 执行动作
				layout:runAction(
					cc.Sequence:create(
						cc.DelayTime:create(GetSeq(v.beforeTalentId)*0.05),
						cc.CallFunc:create(function ()
							skillIconBtn:setVisible(true)
							skillIconBtn:setScale(v.scale)
							-- 添加光圈
							local lightRing = sp.SkeletonAnimation:create(
   							    'effects/talent/quan.json',
   							    'effects/talent/quan.atlas',
   							    1)
   							lightRing:setAnimation(0, v.color, false)
   							layout:addChild(lightRing, 5)
   							lightRing:setPosition(cc.p(v.location.x + DeviationX, 1002 - v.location.y + DeviationY))
							lightRing:registerSpineEventHandler(function()
								lightRing:runAction(cc.RemoveSelf:create())
							 end, sp.EventType.ANIMATION_END)
							if tonumber(v.style) == 1 then -- 被动天赋
								lightRing:setScale(0.44)
							elseif tonumber(v.style) == 2 then -- 主动天赋
								lightRing:setScale(v.scale)
							elseif tonumber(v.style) == 3 then -- 特殊天赋
								lightRing:setScale(0.69)
							end
							skillIconBtn:runAction(
								cc.Sequence:create(
									cc.ScaleTo:create(0.1, v.scale*1.2),
									cc.ScaleTo:create(0.7, v.scale*1.3),
									cc.CallFunc:create(function()
										for _,beforeTalentId in pairs(checktable(v.beforeTalentId)) do
											local beforeSkillLevel = tonumber(skillDatas[tostring(beforeTalentId)].level)
											if not talentData.talents[tostring(beforeTalentId)] or tonumber(talentData.talents[tostring(beforeTalentId)].level) ~= beforeSkillLevel then
												skillIconBtn:runAction(cc.FadeOut:create(0.3))
												-- local grayFilter = GrayFilter:create()
       					-- 						skillIcon:setFilter(grayFilter)
												break
											end
										end
       									-- local fadeIcon = display.newImageView(_res('arts/talentskills/' .. tostring(v.icon) .. '.png'), v.location.x + DeviationX, 1002 - v.location.y + DeviationY)
       									-- fadeIcon:setScale(1.3*v.scale)
       									-- layout:addChild(fadeIcon, 10)
       									-- fadeIcon:runAction(
       									-- 	cc.Sequence:create(
       									-- 		cc.Spawn:create(
       									-- 			cc.ScaleTo:create(0.3, v.scale),
       									-- 			cc.FadeOut:create(0.3)
       									-- 		),
       									-- 		cc.RemoveSelf:create()
       									-- 	)
       									-- )
									end),
									cc.ScaleTo:create(0.3, v.scale),
									cc.ScaleTo:create(0.05, v.scale*1.05),
									cc.ScaleTo:create(0.05, v.scale),
									cc.CallFunc:create(function()
										-- 是否显示技能等级
										local skillLevel = 0
										if talentData.talents[tostring(v.id)] then
											skillLevel = tonumber(talentData.talents[tostring(v.id)].level)
										end
										if skillLevel < tonumber(v.level) then
											if skillLevel == 0 then
												local canUpgrade = true
												for _,beforeTalentId in pairs(checktable(v.beforeTalentId)) do
													local beforeSkillLevel = tonumber(skillDatas[tostring(beforeTalentId)].level)
													if not talentData.talents[tostring(beforeTalentId)] or tonumber(talentData.talents[tostring(beforeTalentId)].level) ~= beforeSkillLevel then
														canUpgrade = false
														break
													end
												end
												if canUpgrade then
													local levelBg = display.newButton(v.location.x + DeviationX, 1002 - v.location.y + DeviationY - (skillIconBtn:getContentSize().height/2*v.scale),
														{n = _res('ui/home/talent/talent_bg_skill_number.png'), enable = false}
													)
													layout:addChild(levelBg, 10)
													display.commonLabelParams(levelBg, {text = string.fmt('(%1/%2)', skillLevel, v.level), fontSize = 22, color = '#ffffff'})
													-- 如果技能为被动技能更改技能图标
													if tonumber(v.style) == 1 then
														skillIcon:setTexture(_res('arts/talentskills/' .. tostring(v.icon) .. '_1.png'))
													end
												end
											else
												local levelBg = display.newButton(v.location.x + DeviationX, 1002 - v.location.y + DeviationY - (skillIconBtn:getContentSize().height/2*v.scale),
													{n = _res('ui/home/talent/talent_bg_skill_number.png'), enable = false}
												)
												layout:addChild(levelBg, 10)
												display.commonLabelParams(levelBg, {text = string.fmt('(%1/%2)', skillLevel, v.level), fontSize = 22, color = '#ffffff'})
												-- 如果技能为被动技能更改技能图标
												if tonumber(v.style) == 1 then
													skillIcon:setTexture(_res('arts/talentskills/' .. tostring(v.icon) .. '_1.png'))
												end
											end
										end
									end)
								)
							)
						end)
					)
				)
			end
		end
	end
end
--[[
添加技能升级特效
@params talentId int 技能Id
--]]
function TalentMediator:AddUpgradeEffect( talentId )
	local datas = self.departMentDatas[tostring(talentId)]
	local effect = sp.SkeletonAnimation:create(
		'effects/talent/dianji.json',
		'effects/talent/dianji.atlas',
		1)
	effect:update(0)
	effect:setToSetupPose()
	effect:setAnimation(0, 'idle', false)
	effect:setPosition(cc.p(datas.location.x + DeviationX, 1002 - datas.location.y + DeviationY))
	effect:registerSpineEventHandler(function ()
		effect:runAction(cc.RemoveSelf:create())
	end, sp.EventType.ANIMATION_END)
	local layout = self:GetViewComponent().viewData.view:getChildByTag(9999)
	layout:addChild(effect)
	if tonumber(datas.style) == 1 then
		effect:setScale(0.44)
	elseif tonumber(datas.style) == 2 then
		effect:setScale(datas.scale)
	elseif tonumber(datas.style) == 3 then
		effect:setScale(0.69)
	end
end
function TalentMediator:EnterLayer(  )
	self:SendSignal(COMMANDS.COMMAND_Talent_Talents)
end

function TalentMediator:OnRegist(  )
	self:GetFacade():UnRegsitMediator("HomeMediator")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
	local TalentCommand = require( 'Game.command.TalentCommand' )
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Talent_Talents, TalentCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Talent_LightTalent, TalentCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Talent_LevelUp, TalentCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Talent_Reset, TalentCommand)
	self:EnterLayer()
end

function TalentMediator:OnUnRegist(  )
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Talent_Talents)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Talent_LightTalent)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Talent_LevelUp)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Talent_Reset)

end
return TalentMediator








