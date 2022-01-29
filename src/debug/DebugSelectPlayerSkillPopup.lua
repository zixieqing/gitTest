--[[
主角技选择界面
@params table {
	allSkills table 所有可选的主动主角技
	equipedPlayerSkills table 当前装备的主角技
	slotIndex int 技能槽序号
	changeEndCallback function 替换成功的外部回调
}
--]]
local CommonDialog = require('common.CommonDialog')
local SelectPlayerSkillPopup = class('SelectPlayerSkillPopup', CommonDialog)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

--[[
override
initui
--]]
function SelectPlayerSkillPopup:InitialUI()

	self.slotIndex = checkint(self.args.slotIndex)
	self.selectedSkillIdx = nil
	self.changeEndCallback = self.args.changeEndCallback

	self.equipState = {
		['1'] = {name = __('装备'), tag = 1},
		['2'] = {name = __('替换'), tag = 2},
		['3'] = {name = __('卸下'), tag = 3}
	}

	self:InitPlayerSkillData()

	local function CreateView()

		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_2.png'), 0, 0)
		local bgSize = bg:getContentSize()

		-- bg view
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg, 5)

		-- title
		local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
		display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5)})
		display.commonLabelParams(titleBg,
			{text = __('更换料理天赋'),
			fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color,
			offset = cc.p(0, -2)})
        titleBg:setEnabled(false)
		bg:addChild(titleBg)

		local needShowHint = false
		local unlockPlayerSkill = true
		local hintStr = ''
		if not unlockPlayerSkill then
			hintStr = __('尚未解锁料理天赋')
			needShowHint = true
		elseif 0 == table.nums(self.playerSkillData) then
			hintStr = __('请去装备料理天赋')
			needShowHint = true
		end
		if needShowHint then
			--空白的内容区域的页面视图
			local emptyView = CLayout:create(bgSize)
			display.commonUIParams(emptyView, {ap = display.LEFT_BOTTOM, po = cc.p(0,0)})
			view:addChild(emptyView, 10)
			local dialogue_tips = display.newButton(0, 0, {ap = display.CENTER,n = _res('ui/common/common_bg_dialogue_tips.png')})
			display.commonUIParams(dialogue_tips, {ap = cc.p(0,0.5),po = cc.p(40,bgSize.height * 0.5)})
			display.commonLabelParams(dialogue_tips,{text = hintStr, fontSize = 24, color = '#4c4c4c'})
	        emptyView:addChild(dialogue_tips, 6)
	        -- 中间小人
		    local loadingCardQ = display.newImageView(_res(string.format('arts/cartoon/card_q_%d.png', 3)),
		    	dialogue_tips:getContentSize().width + 180, bgSize.height * 0.5)
		    emptyView:addChild(loadingCardQ, 6)
		    loadingCardQ:setScale(0.5)
			local Img_cartoon = display.newImageView(_res("ui/common/common_ico_cartoon_1.png"), 0, 0)
		    display.commonUIParams(Img_cartoon, {ap = cc.p(1,0), po = cc.p(70,10)})
		    view:addChild(Img_cartoon,11)

			return {
				view = view
			}
		end

		local mainSkillData = self.playerSkillData[1]
		local mainSkillConf = CommonUtils.GetSkillConf(mainSkillData.skillId)

		-- 顶部技能信息
		local skillIconPos = cc.p(bgSize.width * 0.84, bgSize.height - 135)
		local mainSkillIconBg = display.newImageView(_res('ui/battleready/team_lead_skill_bg_skill.png'), skillIconPos.x, skillIconPos.y)
		view:addChild(mainSkillIconBg, 10)

		local mainSkillIcon = require('common.PlayerSkillNode').new({id = mainSkillData.skillId})
		display.commonUIParams(mainSkillIcon, {po = skillIconPos})
		view:addChild(mainSkillIcon, 10)

		-- 技能说明区域
		local skillDescrBg = display.newImageView(_res('ui/battleready/team_lead_skill_bg_word.png'), 0, 0)
		local skillDescrBgSize = skillDescrBg:getContentSize()
		display.commonUIParams(skillDescrBg, {
			po = cc.p(skillIconPos.x - mainSkillIconBg:getContentSize().width * 0.5 - 15 - skillDescrBg:getContentSize().width * 0.5,
				skillIconPos.y + mainSkillIconBg:getContentSize().height * 0.5 - skillDescrBg:getContentSize().height * 0.5)
		})
		view:addChild(skillDescrBg, 10)

		local nextPos = cc.p(18, skillDescrBgSize.height - 15)
		local labelap = cc.p(0, 1)
		local skillNameLabel = display.newLabel(18, skillDescrBgSize.height - 15,
			{text = mainSkillConf.name, fontSize = 26, color = '#824325', ap = labelap})
		skillDescrBg:addChild(skillNameLabel)

		-- 能量消耗
		-- nextPos.y = nextPos.y - display.getLabelContentSize(skillNameLabel).height - 2
		nextPos.y = nextPos.y - 30
		local costEnergyLabel = display.newLabel(nextPos.x, nextPos.y,
			fontWithColor(6,{text = '', ap = labelap, fontSize = 20}))
		skillDescrBg:addChild(costEnergyLabel)

		if nil ~= mainSkillConf.triggerType[tostring(ConfigSkillTriggerType.ENERGY)] then
			display.commonLabelParams(costEnergyLabel, {text = string.format(__('消耗%s点能量'), tostring(mainSkillConf.triggerType[tostring(ConfigSkillTriggerType.ENERGY)]))})
		end

		-- cd 时间
		-- nextPos.y = nextPos.y - display.getLabelContentSize(costEnergyLabel).height - 2
		nextPos.y = nextPos.y - 25
		local skillCountdownLabel = display.newLabel(nextPos.x, nextPos.y,
			fontWithColor(6,{text = '', ap = labelap, fontSize = 20}))
		skillDescrBg:addChild(skillCountdownLabel)

		if nil ~= mainSkillConf.triggerType[tostring(ConfigSkillTriggerType.CD)] then
			display.commonLabelParams(skillCountdownLabel, {text = string.format(__('%s秒冷却时间'), tostring(mainSkillConf.triggerType[tostring(ConfigSkillTriggerType.CD)]))})
		end

		-- 描述
		-- nextPos.y = nextPos.y - display.getLabelContentSize(skillCountdownLabel).height - 2
		nextPos.y = nextPos.y - 25
		local skillDescrLabel = display.newLabel(nextPos.x, nextPos.y,
			fontWithColor(10, {text = mainSkillConf.skillDescr,ap = labelap, w = 425, fontSize = 18}))
		skillDescrBg:addChild(skillDescrLabel)

		-- 操作按钮
		local equipBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
		display.commonUIParams(equipBtn, {cb = handler(self, self.ChangeSkillCallback), po = cc.p(
			skillIconPos.x,
			skillIconPos.y - mainSkillIconBg:getContentSize().height * 0.5 - equipBtn:getContentSize().height * 0.5 - 10)})
		view:addChild(equipBtn, 10)

		local equipLabel = display.newLabel(utils.getLocalCenter(equipBtn).x, utils.getLocalCenter(equipBtn).y,
			fontWithColor(8,{text = __('装备')}))
		equipBtn:addChild(equipLabel)

		-- 主角技列表
		local gridViewBg = display.newImageView(_res('ui/battleready/team_lead_skill_bg_all_skill.png'), 0, 0)
		local gridViewBgSize = gridViewBg:getContentSize()
		display.commonUIParams(gridViewBg, {po = cc.p(bgSize.width * 0.5, 20 + gridViewBgSize.height * 0.5)})
		view:addChild(gridViewBg, 10)

		local gridViewBgTitle = display.newLabel(gridViewBgSize.width * 0.5, gridViewBgSize.height - 20,
			fontWithColor(8,{text = __('所有料理天赋')}))
		gridViewBg:addChild(gridViewBgTitle)

		-- 技能列表
		local gridViewSize = cc.size(gridViewBgSize.width - 20, gridViewBgSize.height - 40)
		local skillPerLine = 5
		local cellSize = cc.size(gridViewSize.width / skillPerLine, gridViewSize.width / skillPerLine)
		local gridView = CGridView:create(gridViewSize)
		gridView:setAnchorPoint(cc.p(0.5, 0))
		gridView:setPosition(cc.p(gridViewBg:getPositionX(), gridViewBg:getPositionY() - gridViewBgSize.height * 0.5 + 2))
		view:addChild(gridView, 15)
		-- gridView:setBackgroundColor(cc.c4b(255, 128, 0, 128))

		gridView:setCountOfCell(table.nums(self.playerSkillData))
		gridView:setColumns(skillPerLine)
		gridView:setSizeOfCell(cellSize)
		gridView:setAutoRelocate(false)
		gridView:setDataSourceAdapterScriptHandler(handler(self, self.GridViewDataAdapter))

		return {
			view = view,
			skillDescrBg = skillDescrBg,
			cellSize = cellSize,
			gridView = gridView,
			mainSkillIcon = mainSkillIcon,
			skillNameLabel = skillNameLabel,
			costEnergyLabel = costEnergyLabel,
			skillCountdownLabel = skillCountdownLabel,
			skillDescrLabel = skillDescrLabel,
			equipLabel = equipLabel,
			equipBtn = equipBtn
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

	if 0 ~= table.nums(self.playerSkillData) then
		self.viewData.gridView:reloadData()
		self:RefreshSelectedSkill(1)
	end

end
--[[
初始化数据
--]]
function SelectPlayerSkillPopup:InitPlayerSkillData()
	self.equipedPlayerSkills = self.args.equipedPlayerSkills
	self.playerSkillData = self.args.allSkills
	-- dump(self.args.allSkills)
	-- dump(self.equipedPlayerSkills)
	-- dump(self.playerSkillData)
end
--[[
刷新列表
--]]
function SelectPlayerSkillPopup:GridViewDataAdapter(c, i)
	local cell = c
	local index = i + 1
	local skillData = self.playerSkillData[index]

	local skillIcon = nil

	if nil == cell then
		cell = CGridViewCell:new()
		cell:setContentSize(self.viewData.cellSize)

		skillIcon = require('common.PlayerSkillNode').new({id = skillData.skillId})
		display.commonUIParams(skillIcon, {po = utils.getLocalCenter(cell), cb = handler(self, self.SkillIconCallback)})
		cell:addChild(skillIcon)
		skillIcon:setTag(3)
	else
		skillIcon = cell:getChildByTag(3)
		skillIcon:RefreshUI({id = skillData.skillId})
	end

	skillIcon:RefreshEquipState(self:isSkillEquipedBySkillId(skillData.skillId))
	skillIcon:RefreshSelectedState(index == self.selectedSkillIdx)

	cell:setTag(index)

	return cell
end
--[[
刷新选中状态
@params index int 选中序号
--]]
function SelectPlayerSkillPopup:RefreshSelectedSkill(index)
	if index == self.selectedSkillIdx then return end

	local skillData = self.playerSkillData[index]
	local skillConf = CommonUtils.GetSkillConf(skillData.skillId)
	local nextPos = cc.p(18, self.viewData.skillDescrBg:getContentSize().height - 15)

	-- 刷新顶部技能信息
	self.viewData.mainSkillIcon:RefreshUI({id = skillData.skillId})
	self.viewData.skillNameLabel:setString(skillConf.name)

	-- nextPos.y = nextPos.y - display.getLabelContentSize(self.viewData.skillNameLabel).height - 2
	nextPos.y = nextPos.y - 30

	local costEnergyStr = ''
	if nil ~= skillConf.triggerType[tostring(ConfigSkillTriggerType.ENERGY)] then
		costEnergyStr = string.format(__('消耗%s点能量'), tostring(skillConf.triggerType[tostring(ConfigSkillTriggerType.ENERGY)]))
	end
	self.viewData.costEnergyLabel:setString(costEnergyStr)
	display.commonUIParams(self.viewData.costEnergyLabel, {po = nextPos})

	-- nextPos.y = nextPos.y - display.getLabelContentSize(self.viewData.costEnergyLabel).height - 2
	nextPos.y = nextPos.y - 25

	local countdownStr = ''
	if nil ~= skillConf.triggerType[tostring(ConfigSkillTriggerType.CD)] then
		countdownStr = string.format(__('%s秒冷却时间'), tostring(skillConf.triggerType[tostring(ConfigSkillTriggerType.CD)]))
	end
	self.viewData.skillCountdownLabel:setString(countdownStr)
	display.commonUIParams(self.viewData.skillCountdownLabel, {po = nextPos})

	-- nextPos.y = nextPos.y - display.getLabelContentSize(self.viewData.skillCountdownLabel).height - 2
	nextPos.y = nextPos.y - 25

	self.viewData.skillDescrLabel:setString(skillConf.skillDescr)
	display.commonUIParams(self.viewData.skillDescrLabel, {po = nextPos})

	-- 刷新按钮状态
	local equipState = self:IsSkillEquipedByIndex(index)
	local equipInfo = self.equipState[tostring(equipState)]
	self.viewData.equipBtn:setTag(equipInfo.tag)
	display.commonLabelParams(self.viewData.equipLabel, {text = equipInfo.name})

	-- 刷新选中状态
	if nil ~= self.selectedSkillIdx then
		local preCell = self.viewData.gridView:cellAtIndex(self.selectedSkillIdx - 1)
		if nil ~= preCell then
			preCell:getChildByTag(3):RefreshSelectedState(false)
		end
	end

	local curCell = self.viewData.gridView:cellAtIndex(index - 1)
	if nil ~= curCell then
		curCell:getChildByTag(3):RefreshSelectedState(true)
	end

	self.selectedSkillIdx = index
end
--[[
技能icon点击回调
--]]
function SelectPlayerSkillPopup:SkillIconCallback(sender)
	PlayAudioByClickNormal()
	local index = sender:getParent():getTag()
	self:RefreshSelectedSkill(index)
end
--[[
换技能按钮回调
--]]
function SelectPlayerSkillPopup:ChangeSkillCallback(sender)
	local tag = sender:getTag()
	local curSelectedSkillId = self.playerSkillData[self.selectedSkillIdx].skillId

	uiMgr:ShowInformationTips(__('操作成功'))
	-- 刷新列表
	self.viewData.gridView:reloadData()
	-- 刷新按钮状态
	local equipState = self:IsSkillEquipedByIndex(self.selectedSkillIdx)
	local equipInfo = self.equipState[tostring(equipState)]
	self.viewData.equipBtn:setTag(equipInfo.tag)
	display.commonLabelParams(self.viewData.equipLabel, {text = equipInfo.name})

	if self.changeEndCallback then
		self.changeEndCallback(self.slotIndex, curSelectedSkillId)
	end





	-- PlayAudioByClickNormal()
	-- local tag = sender:getTag()
	-- local curSelectedSkillId = self.playerSkillData[self.selectedSkillIdx].skillId
	-- local requestFixedStr = self:GetFormattedRequestStr(curSelectedSkillId)
	-- local requestData = {skills = requestFixedStr}

	-- AppFacade.GetInstance():DispatchObservers("CHANGE_PLAYER_SKILL",{
	-- 	requestData = requestData,
	-- 	responseCallback = function (responseData)
	-- 		uiMgr:ShowInformationTips(__('操作成功'))

	-- 		for i,v in ipairs(responseData.skill) do
	-- 			self.equipedPlayerSkills[tostring(i)] = {skillId = checkint(v)}
	-- 		end

	-- 		-- 刷新列表
	-- 		self.viewData.gridView:reloadData()
	-- 		-- 刷新按钮状态
	-- 		local equipState = self:IsSkillEquipedByIndex(self.selectedSkillIdx)
	-- 		local equipInfo = self.equipState[tostring(equipState)]
	-- 		self.viewData.equipBtn:setTag(equipInfo.tag)
	-- 		display.commonLabelParams(self.viewData.equipLabel, {text = equipInfo.name})

	-- 		if self.changeEndCallback then
	-- 			self.changeEndCallback(responseData)
	-- 		end
	-- 	end
	-- })
end
--[[
指定序号的技能是否被装备
@params index int 技能序号
@return _ int 1 当前槽为未装备技能 2 装备了技能 需要替换 3 装备了该index对应的技能 需要卸下
--]]
function SelectPlayerSkillPopup:IsSkillEquipedByIndex(index)
	local curSlotEquipedSkillId = checkint(checktable(self.equipedPlayerSkills[tostring(self.slotIndex)]).skillId)
	if 0 == curSlotEquipedSkillId then
		return 1
	else
		local skillData = self.playerSkillData[index]
		if curSlotEquipedSkillId == skillData.skillId then
			return 3
		else
			return 2
		end
	end
end
--[[
获取请求需要的传参字符串
@params curSelectedSkillId int 当前选中需要操作的技能
@return result string 请求的字符串
--]]
function SelectPlayerSkillPopup:GetFormattedRequestStr(curSelectedSkillId)
	local result = ''
	for i = 1, 2 do
		if i > 1 then
			result = result .. ','
		end
        local originSkillId = checkint(checktable(self.equipedPlayerSkills[tostring(i)]).skillId)
		if i == self.slotIndex then
			if originSkillId == curSelectedSkillId then
				result = result .. '0'
			else
				result = result .. tostring(curSelectedSkillId)
			end
		else
			if originSkillId == curSelectedSkillId then
				result = result .. '0'
			else
				result = result .. tostring(originSkillId)
			end
		end
	end
	return result
end
--[[
判断传入的技能id是否被装备
@params skillId int 技能id
@return _ bool
--]]
function SelectPlayerSkillPopup:isSkillEquipedBySkillId(skillId)
	for k,v in pairs(self.equipedPlayerSkills) do
		if skillId == v.skillId then
			return true
		end
	end
	return false
end

return SelectPlayerSkillPopup
