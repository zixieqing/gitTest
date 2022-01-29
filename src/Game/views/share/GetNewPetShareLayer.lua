--[[
获得新堕神的分享界面
@params table {
	petId int 堕神id
	petCharacterId int 堕神性格id
}
--]]
local CommonShareFrameLayer = require('Game.views.share.CommonShareFrameLayer')
local GetNewPetShareLayer = class('GetNewPetShareLayer', CommonShareFrameLayer)

------------ import ------------
local petMgr = AppFacade.GetInstance():GetManager("PetManager")
------------ import ------------

------------ define ------------
------------ define ------------

--[[
@override
constructor
--]]
function GetNewPetShareLayer:ctor(...)

	local args = unpack({...})

	self.petId = args.petId
	self.petCharacterId = args.petCharacterId

	CommonShareFrameLayer.ctor(self,'Game.views.share.GetNewPetShareLayer')
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化ui
--]]
function GetNewPetShareLayer:InitUI()
	local petConfig = CommonUtils.GetConfig('goods', 'goods', self.petId)

	local function CreateView()

		local bg = display.newImageView(_res('ui/share/main_bg_16.jpg'), 0, 0, {isFull = true})
		display.commonUIParams(bg, {po = utils.getLocalCenter(self)})
		self:addChild(bg)

		local petIconLight = display.newImageView(_res('ui/share/share_bg_pet_light.png'), 0, 0)
		display.commonUIParams(petIconLight, {po = utils.getLocalCenter(self)})
		self:addChild(petIconLight)

		local petIcon = petMgr.GetPetDrawNodeByPetId(self.petId)
		petIcon:setScale(0.65)
		display.commonUIParams(petIcon, {po = utils.getLocalCenter(self)})
		self:addChild(petIcon, 10)

		local petNameLabelBg = display.newImageView(_res('ui/share/share_bg_name_card.png'), 0, 0)
		display.commonUIParams(petNameLabelBg, {po = cc.p(
			display.SAFE_RECT.width - 10 - petNameLabelBg:getContentSize().width * 0.5,
			display.SAFE_RECT.height - 200
		)})
		self:addChild(petNameLabelBg)

		local petNameLabel = display.newLabel(0, 0, fontWithColor('19', {text = petConfig.name}))
		display.commonUIParams(petNameLabel, {po = cc.p(
			petNameLabelBg:getContentSize().width * 0.5,
			petNameLabelBg:getContentSize().height * 0.5
		)})
		petNameLabelBg:addChild(petNameLabel)

		local characterConfig = CommonUtils.GetConfig('pet', 'petCharacter', self.petCharacterId)
		if nil ~= characterConfig then
			local characterStr = string.format(__('性格:%s'), characterConfig.name)
			local characterLabel = display.newLabel(0, 0, fontWithColor('18', {text = characterStr}))
			display.commonUIParams(characterLabel, {ap = cc.p(0.5, 1), po = cc.p(
				petNameLabelBg:getPositionX(),
				petNameLabelBg:getPositionY() - 5 - petNameLabelBg:getContentSize().height * 0.5
			)})
			self:addChild(characterLabel)
		end

		return {

		}
	end

	xTry(function ( )
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

end
---------------------------------------------------
-- init end --
---------------------------------------------------












return GetNewPetShareLayer
