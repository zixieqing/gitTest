--[[
选择堕神的cell
@params table {
	size cc.size cell大小
	id int 堕神数据库id
	callback function 按钮回调
}
--]]
local PetSelectCell = class('Game.views.pet.PetSelectCell', function ()
	local cell = CGridViewCell:new()
	cell.name = 'Game.views.pet.PetSelectCell'
	return cell
end)

------------ import ------------
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type PetManager
local petMgr = AppFacade.GetInstance():GetManager("PetManager")
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
------------ import ------------


--[[
constructor
--]]
function PetSelectCell:ctor( ... )
	local args = unpack({...})

	self.size = args.size
	self.id = args.id -- 堕神数据库id
	self.callback = args.callback

	self:InitUI()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function PetSelectCell:InitUI()

	local size = self.size
	self:setContentSize(size)

	local function CreateView()

		-- 初始化底图
		local bg = display.newImageView(_res('ui/pet/card_preview_bg_list_unslected.png'),
			size.width * 0.5,
			size.height * 0.5,
			{scale9 = true, size = cc.size(self.size.width - 10, self.size.height)})
		self:addChild(bg)

		------------ 初始化堕神头像 ------------
		local petIconScale = 0.9
		local petIcon = require('common.PetHeadNode').new({
			showBaseState = true,
			showLockState = true
		})
		petIcon:setScale(petIconScale)
		display.commonUIParams(petIcon, {po = cc.p(
			13 + petIcon:getContentSize().width * 0.5 * petIconScale,
			size.height * 0.5)})
		self:addChild(petIcon, 5)
		------------ 初始化堕神头像 ------------

		------------ 名字 ------------
		-- 名字
		local nameBgPath = string.format('ui/pet/pet_info_bg_rarity_%d.png', 1)
		-- print('here check fuck path>>>>>>>>>>>>>>>>>>>', nameBgPath)
		local nameBg = display.newImageView(_res(nameBgPath), 0, 0)
		display.commonUIParams(nameBg, {ap = cc.p(0, 0.5), po = cc.p(
			petIcon:getPositionX() + petIcon:getContentSize().width * 0.5 * petIconScale - 5,
			petIcon:getPositionY() + petIcon:getContentSize().height * 0.5 * petIconScale - nameBg:getContentSize().height * 0.5
		)})
		self:addChild(nameBg, 4)

		local nameLabel = display.newLabel(0, 0, fontWithColor('14', {text = ''}))
		display.commonUIParams(nameLabel, {ap = cc.p(0, 0.5), po = cc.p(
			nameBg:getPositionX() + 8,
			nameBg:getPositionY() - 2
		)})
		self:addChild(nameLabel, 5)
		------------ 名字 ------------

		------------ 性格 ------------
		local characterLabel = display.newLabel(0, 0, fontWithColor('16', {text = '性格:%s'}))
		display.commonUIParams(characterLabel, {ap = cc.p(0, 0.5), po = cc.p(
			nameLabel:getPositionX(),
			nameBg:getPositionY() - nameBg:getContentSize().height * 0.5 - 5 - display.getLabelContentSize(characterLabel).height * 0.5
		)})
		self:addChild(characterLabel, 5)
		------------ 性格 ------------

		------------ 强化等级 ------------
		-- local breakLevelLabel = display.newLabel(0, 0, fontWithColor('14', {text = '+5'}))
		local breakLevelLabel = CLabelBMFont:create(
			'+0',
			'font/common_num_1.fnt'
		)
		breakLevelLabel:setBMFontSize(24)
		breakLevelLabel:setAnchorPoint(cc.p(0, 0.5))
		breakLevelLabel:setPosition(cc.p(
			math.max(size.width * 0.525, nameLabel:getPositionX() + display.getLabelContentSize(nameLabel).width + 10),
			nameLabel:getPositionY() + 2
		))
		self:addChild(breakLevelLabel, 5)
		------------ 强化等级 ------------

		------------ 跟随状态 ------------
		local equipBg = display.newNSprite(_res('ui/pet/pet_info_bg_follow.png'), 0, 0)
		display.commonUIParams(equipBg, {po = cc.p(
			size.width - equipBg:getContentSize().width * 0.5 - 5,
			equipBg:getContentSize().height * 0.5 + 3
		)})
		self:addChild(equipBg, 10)

		local equipLabel = display.newLabel(10, equipBg:getContentSize().height * 0.525,
			fontWithColor('18', {text = '跟随:测试五个字', ap = cc.p(0, 0.5)}))
		equipBg:addChild(equipLabel)
		------------ 跟随状态 ------------

		------------ 选中状态 ------------
		local selectedBg = display.newImageView(_res('ui/pet/card_preview_bg_list_slected.png'), 0, 0,
			{scale9 = true, size = cc.size(bg:getContentSize().width + 20, bg:getContentSize().height + 20)})
		display.commonUIParams(selectedBg, {po = cc.p(bg:getPositionX(), bg:getPositionY())})
		self:addChild(selectedBg, 1)
		selectedBg:setTag(3)
		selectedBg:setVisible(false)
		------------ 选中状态 ------------

		------------ cell按钮 ------------
		local cellBtn = display.newButton(size.width * 0.5, size.height * 0.5, {size = size, animate = false, cb = function (sender)
			if nil ~= self.callback then
				self.callback(sender)
			end
		end})
		self:addChild(cellBtn, 20)


		local evolutionBtn  = display.newButton(size.width -60 , size.height/2 +5, { n = CommonUtils.GetGoodsIconPathById(EVOLUTION_STONE_ID) ,enable = false })
		self:addChild(evolutionBtn, 21)
		evolutionBtn:setScale(0.45)
	    local evolutionBtnSize = 	evolutionBtn:getContentSize()

		display.commonLabelParams(evolutionBtn , fontWithColor(8, {text = __('可异化') ,fontSize = 50}))

		evolutionBtn:getLabel():setPosition(cc.p(evolutionBtnSize.width/2 , -10) )
		evolutionBtn:setVisible(false)

		------------ cell按钮 ------------

		-- debug --

		-- debug --

		return {
			petIcon = petIcon,
			nameBg = nameBg,
			nameLabel = nameLabel,
			characterLabel = characterLabel,
			breakLevelLabel = breakLevelLabel,
			evolutionBtn   = evolutionBtn ,
			equipBg = equipBg,
			equipLabel = equipLabel,
			selectedBg = selectedBg
		}
	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
刷新cell
@params data table 堕神数据 {
	id int 堕神数据库id
}
--]]
function PetSelectCell:RefreshUI(data)
	self.id = data.id

	-- 刷新堕神头像
	self.viewData.petIcon:RefreshUI({
		id = self.id
	})

	local petData = gameMgr:GetPetDataById(self.id) or {}

	local petId = checkint(petData.petId)
	local petConfig = petMgr.GetPetConfig(petId) or {}
	self:RefreshEvolutionBtnByMainData(petData)

	-- 刷新其他信息
	self:RefreshPetBaseInfo(tostring(petConfig.name), petMgr.GetPetQualityById(self.id))
	self:RefreshPetCharacterInfo(checkint(petData.character))
	self:RefreshBreakLevel(checkint(petData.breakLevel))
	self:RefreshEquipState(nil)
end
--[[
刷新名字
@params name string 名字
@params quality int 品质
--]]
function PetSelectCell:RefreshPetBaseInfo(name, quality)
	-- 名字
	local nameBgPath = string.format('ui/pet/pet_info_bg_rarity_%d.png', quality)
	self.viewData.nameBg:setTexture(_res(nameBgPath))
	self.viewData.nameLabel:setString(name)

	-- 刷新强化等级位置
	local size = self:getContentSize()
	self.viewData.breakLevelLabel:setPosition(cc.p(
		math.max(size.width * 0.4, self.viewData.nameLabel:getPositionX() + display.getLabelContentSize(self.viewData.nameLabel).width + 10),
		self.viewData.nameLabel:getPositionY() + 2
	))
end

function PetSelectCell:RefreshEvolutionBtnByMainData(petData)
	petData = petData or {}
	local viewData =self.viewData
	local evolutionBtn = viewData.evolutionBtn
	local isEvolution = petData.isEvolution
	local breakLevel = petData.breakLevel
	local petConfig = petMgr.GetPetConfig(petData.petId) or {}
	if checkint(petConfig.type)  == PetType.BOSS then
		if checkint(isEvolution) == 0 and checkint(breakLevel) == 10 and CommonUtils.GetModuleAvailable(MODULE_SWITCH.PET_EVOL) then
			evolutionBtn:setVisible(true)
		else
			evolutionBtn:setVisible(false)
		end
	else
		evolutionBtn:setVisible(false)
	end
end
--[[
刷新性格
@params characterId int 性格id
--]]
function PetSelectCell:RefreshPetCharacterInfo(characterId)
	-- 性格
	local characterConfig = CommonUtils.GetConfig('pet', 'petCharacter', characterId)
	self.viewData.characterLabel:setString(string.format(__('性格:%s'), characterConfig.name))
end
--[[
刷新强化
--]]
function PetSelectCell:RefreshBreakLevel(breakLevel)
	self.viewData.breakLevelLabel:setVisible(not (0 >= breakLevel))
	self.viewData.breakLevelLabel:setString(string.format('+%d', breakLevel))
end
--[[
刷新跟随状态
@params ownerId int 卡牌数据库id
--]]
function PetSelectCell:RefreshEquipState(ownerId)
	if nil == ownerId or 0 == checkint(ownerId) then
		self.viewData.equipBg:setVisible(false)
	else
		self.viewData.equipBg:setVisible(true)
		local cardData = gameMgr:GetCardDataById(ownerId)
		local cardId = checkint(cardData.cardId)
		local cardConfig = CardUtils.GetCardConfig(cardId)
		self.viewData.equipBg:setString(string.format(__('跟随:%s'), cardConfig.name))
	end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

return PetSelectCell
