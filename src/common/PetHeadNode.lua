--[[
堕神头像框
@params table 参数集 {
	------------ pattern 1 ------------
	id int 堕神数据库自增id 
	------------ pattern 1 ------------

	------------ pattern 2 ------------
	petData table 堕神信息 {
		petId int 堕神id
		level int 等级
		breakLevel int 强化等级
		lock bool 是否上锁
		character int 性格类型
	}
	------------ pattern 2 ------------

	showBaseState bool 显示基础信息 等级
	showLockState bool 显示加锁状态
}
--]]
local PetHeadNode = class('PetHeadNode', function ()
	local node = CButton:create()
	node.name = 'common.PetHeadNode'
	node:enableNodeEvents()
	return node
end)

------------ import ------------
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local petMgr = AppFacade.GetInstance():GetManager("PetManager")
------------ import ------------

--[[
constructor
--]]
function PetHeadNode:ctor( ... )
	local args = unpack({...})

	self:InitValue(args)
	self:InitUI()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化头像node需要的参数
@params args 外部参数
--]]
function PetHeadNode:InitValue(args)
	-- 首先重置所有的数据 防止数据出现污染问题
	self.id = nil
	self.petData = nil
	self.petId = nil

	self.id = args.id
	self.petData = args.petData or gameMgr:GetPetDataById(self.id)
	self.petId = nil ~= self.petData and checkint(self.petData.petId) or nil
	self.petData = self.petData or {}
	if nil == self.showBaseState then
		self.showBaseState = true
	end
	if nil ~= args.showBaseState then
		self.showBaseState = args.showBaseState
	end

	if nil == self.showLockState then
		self.showLockState = true
	end
	if nil ~= args.showLockState then
		self.showLockState = args.showLockState
	end

end
--[[
初始化节点
--]]
function PetHeadNode:InitUI()

	local function CreateView()

		------------ 堕神基本框架 ------------
		-- 底框
		local bgPath = string.format('ui/common/common_frame_goods_%d.png', 1)
		local bg = display.newImageView(_res(bgPath), 0, 0)

		local size = bg:getContentSize()

		self:setContentSize(size)
		display.commonUIParams(bg, {po = cc.p(size.width * 0.5, size.height * 0.5)})
		self:addChild(bg, 1)

		-- 头像
		-- local headPath = petMgr.GetPetHeadPathByPetId(petId)
		local headIcon = display.newImageView()
		headIcon:setScale((size.width - 14) / headIcon:getContentSize().width)
		display.commonUIParams(headIcon, {po = cc.p(size.width * 0.5, size.height * 0.5)})
		self:addChild(headIcon, 1)
		------------ 堕神基本框架 ------------

		------------ 锁 ------------
		local lockBg = display.newNSprite(_res('ui/pet/pet_info_bg_lock_icon.png'), 0, 0)
		display.commonUIParams(lockBg, {po = cc.p(
				size.width - lockBg:getContentSize().width * 0.5 - 6,
				lockBg:getContentSize().height * 0.5 + 5
		)})
		self:addChild(lockBg, 10)

		local lock = display.newNSprite(_res('ui/common/common_ico_lock.png'), 0, 0)
		lock:setScale(0.6)
		display.commonUIParams(lock, {po = utils.getLocalCenter(lockBg)})
		lockBg:addChild(lock)
		------------ 锁 ------------

		------------ 性格icon ------------
		local characterIconPath = 'ui/pet/pet_info_ico_charactor_1.png'
		local characterIcon = display.newNSprite(characterIconPath, 0, 0)
		display.commonUIParams(characterIcon, {po = cc.p(
				6 + characterIcon:getContentSize().width * 0.5,
				lockBg:getPositionY()
		)})
		self:addChild(characterIcon, 10)
		------------ 性格icon ------------

		------------ 附加信息 ------------
		-- 等级
		local levelBg = display.newNSprite(_res('ui/pet/pet_info_bg_level.png'), 0, 0)
		display.commonUIParams(levelBg, {po = cc.p(
				levelBg:getContentSize().width * 0.5 - 2,
				size.height - levelBg:getContentSize().height * 0.5 + 2
		)})
		self:addChild(levelBg, 9)

		local levelLabel = display.newLabel(0, 0, fontWithColor('9', {text = '88'}))
		display.commonUIParams(levelLabel, {po = cc.pAdd(utils.getLocalCenter(levelBg), cc.p(0, 2))})
		levelBg:addChild(levelLabel)

		-- 强化等级
		local breakLevelBg = display.newNSprite(_res('ui/pet/pet_promote_bg_number.png'), 0, 0)
		display.commonUIParams(breakLevelBg, {po = cc.p(
				size.width - breakLevelBg:getContentSize().width * 0.5 - 6,
				size.height - breakLevelBg:getContentSize().height * 0.5 - 5
		)})
		self:addChild(breakLevelBg, 10)

		local breakLevelLabel = display.newLabel(0, 0, fontWithColor('9', {text = '+10'}))
		display.commonUIParams(breakLevelLabel, {ap = cc.p(1, 0.5), po = cc.p(
				breakLevelBg:getContentSize().width,
				breakLevelBg:getContentSize().height * 0.5 - 2
		)})
		breakLevelBg:addChild(breakLevelLabel)
		------------ 附加信息 ------------

		return {
			bg = bg,
			headIcon = headIcon,
			lockBg = lockBg,
			levelBg = levelBg,
			levelLabel = levelLabel,
			breakLevelBg = breakLevelBg,
			breakLevelLabel = breakLevelLabel,
			characterIcon = characterIcon
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

	-- 非空版式 刷新一次头像
	if nil ~= self.id then
		self:RefreshPetUI()
	end
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
根据信息刷新头像
@params args table 参数集
--]]
function PetHeadNode:RefreshUI(args)
	self:InitValue(args)

	self:RefreshPetUI()
end
--[[
刷新头像信息
--]]
function PetHeadNode:RefreshPetUI()
	self:RefreshAvatar(self.petId)
	self:RefreshBaseState(checkint(self.petData.level), checkint(self.petData.breakLevel), checkint(self.petData.character))
	self:RefreshLockState(checkint(self.petData.isProtect))
end
--[[
刷新头像
@params petId int 堕神id
--]]
function PetHeadNode:RefreshAvatar(petId)
	--local petConfig = petMgr.GetPetConfig(petId)
	local qualityId = 1
	qualityId = self.id and  petMgr.GetPetQualityById(self.id) or  petMgr.GetPetQualityByPetId(petId)
	-- 外框
	self.viewData.bg:setTexture(_res(string.format('ui/common/common_frame_goods_%d.png',qualityId )))

	-- 头像
	self.viewData.headIcon:setTexture(petMgr.GetPetHeadPathByPetId(petId))
	self.viewData.headIcon:setScale((self.viewData.bg:getContentSize().width - 14) / self.viewData.headIcon:getContentSize().width)
end
--[[
刷新等级和强化等级
@params level int 堕神等级
@params breakLevel int 堕神强化等级
@params character int 堕神性格
--]]
function PetHeadNode:RefreshBaseState(level, breakLevel, character)
	self.viewData.levelBg:setVisible(self.showBaseState)

	self.viewData.levelLabel:setString(tostring(level))

	self.viewData.breakLevelBg:setVisible(0 < breakLevel and self.showBaseState)
	self.viewData.breakLevelLabel:setString(string.format('+%d', breakLevel))

	self.viewData.characterIcon:setTexture(_res(petMgr.GetCharacterIconPath(character)))
end
--[[
刷新锁状态
@params lock int 是否上锁 0 否 1 是
--]]
function PetHeadNode:RefreshLockState(lock)
	if not self.showLockState then
		self.viewData.lockBg:setVisible(false)
		return
	end

	self.viewData.lockBg:setVisible(1 == lock)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

return PetHeadNode
