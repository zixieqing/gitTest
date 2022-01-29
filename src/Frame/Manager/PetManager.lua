--[[
堕神管理模块
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class PetManager
local PetManager = class('PetManager',ManagerBase)

PetManager.instances = {}

------------ define ------------
-- 堕神影响属性配置
PetPConfig = {
	[PetP.ATTACK] 		= {objp = PetP.ATTACK, 			 key = ('attack'),		iconPath = 'ui/common/role_main_att_ico.png'},
	[PetP.DEFENCE] 		= {objp = PetP.DEFENCE, 		 key = ('defence'),		iconPath = 'ui/common/role_main_def_ico.png'},
	[PetP.HP] 			= {objp = PetP.HP, 				 key = ('hp'),		iconPath = 'ui/common/role_main_hp_ico.png'},
	[PetP.CRITRATE] 	= {objp = PetP.CRITRATE, 		 key = ('critRate'),		iconPath = 'ui/common/role_main_baoji_ico.png'},
	[PetP.CRITDAMAGE] 	= {objp = PetP.CRITDAMAGE, 		 key = ('critDamage'),		iconPath = 'ui/common/role_main_baoshangi_ico.png'},
	[PetP.ATTACKRATE] 	= {objp = PetP.ATTACKRATE, 		 key = ('attackRate'),		iconPath = 'ui/common/role_main_speed_ico.png'}
}
for k,v in pairs(PetPConfig) do
	setmetatable(v, {
		__index = function(myTable, key)
			if key == 'name' then
				if myTable.objp == PetP.ATTACK then
					return __('攻击')
				elseif myTable.objp == PetP.DEFENCE then
					return __('防御')
				elseif myTable.objp == PetP.HP then
					return __('生命')
				elseif myTable.objp == PetP.CRITRATE then
					return __('暴率')
				elseif myTable.objp == PetP.CRITDAMAGE then
					return __('暴伤')
				elseif myTable.objp == PetP.ATTACKRATE then
					return  __('攻速')
				else
					return  ""
				end
			else
				return nil
			end
		end
	})
end

------------ define ------------

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function PetManager:ctor( key )
	self.super.ctor(self)
	if PetManager.instances[key] ~= nil then
		funLog(Logger.INFO,"注册相关的facade类型" )
		return
	end

	PetManager.instances[key] = self
end

function PetManager.GetInstance(key)
	key = (key or "PetManager")
	if PetManager.instances[key] == nil then
		PetManager.instances[key] = PetManager.new(key)
	end
	return PetManager.instances[key]
end


function PetManager.Destroy( key )
	key = (key or "PetManager")
	if PetManager.instances[key] == nil then
		return
	end
	--清除配表数据
	PetManager.instances[key] = nil
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

---------------------------------------------------
-- utils begin --
---------------------------------------------------
--[[
/***********************************************************************************************************************************\
 * pet egg utils
\***********************************************************************************************************************************/
--]]
--[[
根据id获取堕神蛋配置
@params petEggId int 堕神蛋id
@return _ table 堕神蛋配置
--]]
function PetManager.GetPetEggConfigById(petEggId)
	return CommonUtils.GetConfig('pet', 'petEgg', petEggId)
end
--[[
根据id获取堕神蛋道具配置
@params petEggId int 堕神蛋id
@return _ table 堕神蛋道具配置
--]]
function PetManager.GetPetEggGoodsConfigById(petEggId)
	return CommonUtils.GetConfig('goods', 'petEgg', petEggId)
end
--[[
根据id获取堕神蛋净化时间
@params petEggId int 堕神蛋id
@return time int 净化时间 秒
--]]
function PetManager.GetPetEggCleanTimeById(petEggId)
	local time = 0
	local petEggConfig = PetManager.GetPetEggConfigById(petEggId)
	if nil ~= petEggConfig then
		time = checkint(petEggConfig.cleanTime)
		-- 计算会员的增益
		time = math.max(0, time - CommonUtils.getVipTotalLimitByField('petCleanDecrease'))
	end
	return time
end
--[[
根据id获取堕神蛋直接唤醒的成功率
@params petEggId int 堕神蛋id
@return rate number 成功率 真实值
--]]
function PetManager.GetPetEggAwakeSuccessRateById(petEggId)
	local rate = 0
	-- 配表概率为千分数
	local petEggConfig = PetManager.GetPetEggConfigById(petEggId)
	if nil ~= petEggConfig then
		rate = checkint(petEggConfig.rouseRate) * 0.001
		rate = math.min(1, rate + CommonUtils.getVipTotalLimitByField('petAwakenRateIncrease'))
	end
	return rate
end
--[[
根据id获取灵体头像路径
@params petEggId int 灵体id
@return _ string 灵体头像id
--]]
function PetManager.GetPetEggHeadPathByPetEggId(petEggId)
	return CommonUtils.GetGoodsIconPathById(petEggId)
end
--[[
根据id获取灵体spine路径
@params petEggId int 灵体id
@return path string 灵体spine路径
--]]
function PetManager.GetPetEggSpinePathByPetEggId(petEggId)
	local petEggConfig = CommonUtils.GetConfig('pet', 'petEgg', petEggId)
	local spineId = checkint(petEggConfig.drawId)
	local path = string.format('pet/spine/%d', spineId)
	if not utils.isExistent(_res(path .. '.json')) then
		path = string.format('pet/spine/%d', 240001)
	end
	return path
end
--[[
/***********************************************************************************************************************************\
 * pet utils
\***********************************************************************************************************************************/
--]]
--[[
根据id获取堕神头像路径
@params petId int 堕神id
@return _ string 堕神头像id
--]]
function PetManager.GetPetHeadPathByPetId(petId)
	if not  petId  then
		return CardUtils.GetCardHeadPathByCardId(300006)
	end
	local petConfig = PetManager.GetPetConfig(petId)
	return AssetsUtils.GetCardHeadPath(petConfig.drawId)
end
--[[
根据id获取堕神立绘路径
@params petId int 堕神id
@return _ string 堕神立绘路径
--]]
function PetManager.GetPetDrawNodeByPetId(petId)
	local petConfig = PetManager.GetPetConfig(petId)
	return AssetsUtils.GetCardDrawNode(checkint(petConfig.drawId))
end
--[[
根据id获取堕神spine路径
@params petId int 堕神id
--]]
function PetManager.GetPetSpineAvatarPathByPetId(petId)
	local petConfig = PetManager.GetPetConfig(petId)
	return AssetsUtils.GetCardSpinePath(petConfig.drawId)
end
--[[
根据堕神id获取堕神q版id
@params petId int 堕神id
--]]
function PetManager.GetPetDrawIdByPetId(petId)
	local petConfig = PetManager.GetPetConfig(petId)
	local path = AssetsUtils.GetCartoonPath(petConfig.drawId)
	if not app.gameResMgr:isExistent(path) then
		return 390001
	else
		return checkint(petConfig.drawId)
	end
end
--[[
根据堕神id获取堕神配表信息
@params petId int 堕神id
@return _ table 堕神配表信息
--]]
function PetManager.GetPetConfig(petId)
	return PetUtils.GetPetConfig(petId)
end
--[[
根据性格id和外部传参获取堕神性格描述
@params id int 性格id
@return descr string 描述文字
--]]
function PetManager.GetFixedPetCharacterDescr(id)
	local characterIdConfig = CommonUtils.GetConfig('pet', 'petCharacter', id)
	local mark = '_target_num_'
	local descr = characterIdConfig.descr
	local s_ = string.split(descr, mark)
	local result = ''

	for i,v in ipairs(characterIdConfig.effectAttrType) do
		local str = ''
		local attrNum = checknumber(characterIdConfig.effectAttrNum[i])
		local attrType = checknumber(characterIdConfig.numType[i])

		if PetCharacterAttrType.MULTI == attrType then
			if attrNum > 0 then
				str = string.format(__('提升%d%%'), attrNum * 100)
			else
				str = string.format(__('降低%d%%'), math.abs(attrNum) * 100)
			end
		elseif PetCharacterAttrType.ADDITION == attrType then
			if attrNum > 0 then
				str = string.format(__('提升%d点'), attrNum)
			else
				str = string.format(__('降低%d点'), math.abs(attrNum))
			end
		end

		if nil ~= s_[i] then
			result = result .. s_[i] .. str
		end
	end

	result = result .. s_[#s_]

	return result
end
--[[
获取堕神全属性解锁配置
@return _ table 堕神全属性配置
--]]
function PetManager.GetPetPInfo()
	return PetUtils.GetPetPInfo()
end
--[[
根据堕神id获取全部基础属性信息
@params id int pet id not config id
@return result table {
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	...
}
--]]
function PetManager.GetPetAllBaseProps(id)
	local result = {}
	local petData = app.gameMgr:GetPetDataById(id)

	if nil == petData then
		return result
	end

	local pinfo = PetManager.GetPetPInfo()
	for i, v in ipairs(pinfo) do
		local ptype = petData[v.ptypeName]
		if nil ~= ptype and 0 ~= checkint(ptype) then
			-- 堕神id
			local petId = checkint(petData.petId)
			-- 属性类型
			ptype = checkint(ptype)
			-- 属性值
			local pvalue = checknumber(petData[v.pnumName])
			-- 属性品质
			local quality = checkint(petData[v.pqualityName] or PetPQuality.WHITE)
			-- 是否解锁
			local unlock = checkint(petData.level) >= v.unlockLevel

			table.insert(result, {ptype = ptype, pvalue = pvalue, pquality = quality, unlock = unlock})
		else
			table.insert(result, {ptype = 1, pvalue = -1})
		end
	end

	return result
end
--[[
根据堕神id和堕神属性序号获取单条基础属性信息
@params id int pet id not config id
@params index int prop index
@return result table {
	ptype = PetP
	pvalue = number
	pquality = PetPQuality
	unlock = bool
}
--]]
function PetManager.GetPetABaseProp(id, index)
	local petData = app.gameMgr:GetPetDataById(id)

	if nil == petData then
		return nil
	end

	local pinfo = PetManager.GetPetPInfo()[index]
	local ptype = petData[pinfo.ptypeName]

	if nil ~= ptype and 0 ~= checkint(ptype) then
		-- 堕神id
		local petId = checkint(petData.petId)
		-- 属性类型
		ptype = checkint(ptype)
		-- 属性值
		local pvalue = checknumber(petData[pinfo.pnumName])
		-- 属性品质
		local quality = checkint(petData[pinfo.pqualityName] or PetPQuality.WHITE)
		-- 是否解锁
		local unlock = checkint(petData.level) >= pinfo.unlockLevel

		return {ptype = ptype, pvalue = pvalue, pquality = quality, unlock = unlock}
	else
		return nil
	end
end
--[[
根据堕神id获取所有堕神修正后的属性
@params id int pet id not config id
@params activeExclusive bool 是否激活对本命卡牌的加成
@return result table {
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	...
}
--]]
function PetManager.GetPetAllFixedProps(id, activeExclusive)
	local petData = app.gameMgr:GetPetDataById(id)
	return PetManager.GetPetAllFixedPropsByPetData(petData, activeExclusive)
end
--[[
根据堕神信息获取所有堕神修正后的属性(old)
@params petData table 堕神数据
@params activeExclusive bool 是否激活对本命卡牌的加成
@return result table {
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	...
}
--]]
function PetManager.GetPetAllFixedPropsByPetData(petData, activeExclusive)
	local result = {}

	if nil == petData then
		return result
	end

	local pinfo = PetManager.GetPetPInfo()
	for i,v in ipairs(pinfo) do
		local pdata = PetManager.GetPetAFixedPropByPetData(petData, i, activeExclusive)
		if nil ~= pdata then
			table.insert(result, {ptype = pdata.ptype, pvalue = pdata.pvalue, pquality = pdata.pquality, unlock = pdata.unlock})
		else
			table.insert(result, {ptype = 1, pvalue = -1, pquality = 1, unlock = true})
		end
	end
	return result
end
--[[
根据堕神信息获取单条堕神修正后的属性(old)
@params petData table 堕神数据
@params activeExclusive bool 是否激活对本命卡牌的加成
@return result table {
	ptype = PetP
	pvalue = number
	pquality = PetPQuality
	unlock = bool
}
--]]
function PetManager.GetPetAFixedPropByPetData(petData, index, activeExclusive)
	if nil == petData then
		return nil
	end

	local pinfo = PetManager.GetPetPInfo()[index]
	local ptype = petData[pinfo.ptypeName]

	if nil ~= ptype and 0 ~= checkint(ptype) then
		-- 堕神id
		local petId = checkint(petData.petId)
		-- 属性类型
		ptype = checkint(ptype)
		-- 属性值
		local pvalue = checknumber(petData[pinfo.pnumName])
		-- 属性品质
		local quality = checkint(petData[pinfo.pqualityName] or PetPQuality.WHITE)
		-- 是否解锁
		local unlock = checkint(petData.level) >= pinfo.unlockLevel

		-- 计算修正后的属性值
		pvalue = PetManager.GetPetFixedPByPetId(
			petId,
			ptype,
			pvalue,
			quality,
			checkint(petData.breakLevel),
			checkint(petData.character),
			activeExclusive,
			checkint(petData.isEvolution)
		)

		return {ptype = ptype, pvalue = pvalue, pquality = quality, unlock = unlock}
	else
		return nil
	end
end
--[[
根据堕神id和堕神属性序号获取单条修正属性信息
@params id int pet id not config id
@params index int prop index
@params activeExclusive bool 是否激活对本命卡牌的加成
@return result table {
	ptype = PetP
	pvalue = number
	pquality = PetPQuality
	unlock = bool
}
--]]
function PetManager.GetPetAFixedProp(id, index, activeExclusive)
	local petData = app.gameMgr:GetPetDataById(id)
	return PetManager.GetPetAFixedPropByPetData(petData, index, activeExclusive)
end
--[[
将服务器返回的堕神信息转换为客户端使用的堕神属性
@params serverPetData table 服务器返回的堕神信息
@params activeExclusive bool 是否激活本命堕神
@return result table {
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	...
}
--]]
function PetManager.ConvertPetPropertyDataByServerData(petData, activeExclusive)
	return PetUtils.ConvertPetPropertyDataByServerData(petData, activeExclusive)
end
--[[
将老的堕神数据转换为新的堕神数据
@params oldPetData table 老的堕神数据
@return newPetData table 新的堕神数据
--]]
function PetManager.ConvertOldPetData2NewPetData(oldPetData)
	local newPetData = nil
	if nil ~= oldPetData then
		newPetData = {
			attr = {},
			petId = checkint(oldPetData.petId),
			level = checkint(oldPetData.level),
			breakLevel = checkint(oldPetData.breakLevel),
			character = checkint(oldPetData.character),
			playerPetId = (nil ~= oldPetData.id and checkint(oldPetData.id or nil)),
			isEvolution = checkint(oldPetData.isEvolution)
		}

		-- 转换属性数据
		for i, pinfo in ipairs(PetManager.GetPetPInfo()) do
			local ptype = checkint(oldPetData[pinfo.ptypeName])
			local pvalue = checknumber(oldPetData[pinfo.pnumName])
			local pquality = checkint(oldPetData[pinfo.pqualityName] or PetPQuality.WHITE)

			table.insert(newPetData.attr, {
				type = ptype,
				num = pvalue,
				quality = pquality
			})
		end
	end
	return newPetData
end
--[[
根据堕神配表id 属性类型 基础属性值 突破等级 获取修正后的属性值
@params petId int 堕神id
@params ptype PetP 属性类型
@params basepvalue number 基础属性值
@params pquality int 属性品质
@params breakLevel int 强化等级
@params characterId int 性格id
@params activeExclusive bool 激活对本命卡牌的加成
@params isEvolution int 是否异化 1 是 0 否
@return result number 修正后的属性值
--]]
function PetManager.GetPetFixedPByPetId(petId, ptype, basepvalue, pquality, breakLevel, characterId, activeExclusive, isEvolution)
	return PetUtils.GetPetFixedPByPetId(petId, ptype, basepvalue, pquality, breakLevel, characterId, activeExclusive, isEvolution)
end
--[[
根据堕神配表id 属性品质 突破等级 获取堕神属性成长系数
@params petId int 堕神配表id
@params pquality int 属性品质
@params breakLevel int 突破等级
--]]
function PetManager.GetPetPropGrow(petId, pquality, breakLevel)
	return PetUtils.GetPetPropGrow(petId, pquality, breakLevel)
end
--[[
根据堕神配表id 属性品质获取堕神成长系数字段名
@params petId int 堕神id
@params pquality int 堕神属性品质
@return fieldName string 成长系数表字段名
--]]
function PetManager.GetPetPropGrowFieldName(petId, pquality)
	return PetUtils.GetPetPropGrowFieldName(petId, pquality)
end
--[[
根据喂养堕神信息获取变化的强化等级
--]]
function PetManager.GetDeltaBreakLevel()
	return 1
end
-- --[[
-- 根据堕神id 属性类型id 属性基础值获取该条属性品质
-- @params petId int 堕神配表id
-- @params propIndex int 属性序号
-- @params propId PetP 属性id
-- @params propValue number 属性值
-- @return quality int 品质
-- --]]
-- function PetManager.GetPetPQuailty(petId, propIndex, propId, propValue)
-- 	local petConfig = PetManager.GetPetConfig(petId)

-- 	local propConfig = petConfig.attr[tostring(propIndex)]

-- 	for quality, values in ipairs(propConfig.attrNum) do
-- 		if checknumber(values[propId]) == checknumber(propValue) then
-- 			return quality
-- 		end
-- 	end
-- 	return 1
-- end
--[[
根据堕神属性品质获取词缀字体
@params propQuality int 词缀品质
@return _ string 词缀字体路径
--]]
function PetManager.GetPetPropFontPath(propQuality)
	local info = {
		[1] = 'font/small/common_text_num.fnt',
		[2] = 'font/small/common_text_num_2.fnt',
		[3] = 'font/small/common_text_num_3.fnt',
		[4] = 'font/small/common_text_num_4.fnt',
		[5] = 'font/small/common_text_num_5.fnt'
	}
	return info[checkint(propQuality)]
end
--[[
根据堕神id获取堕神品质
@params petId int 堕神id
@return quality int 品质
--]]
function PetManager.GetPetQualityByPetId(petId)
	local petConfig = PetManager.GetPetConfig(petId) or {}
	local quality = 1
	if PetType.NORMAL == checkint(petConfig.type) then
		quality = 1
	elseif PetType.ELITE == checkint(petConfig.type) then
		quality = 3
	elseif PetType.BOSS == checkint(petConfig.type) then
		quality = 4
	end
	return quality
end

--[[
根据堕神自增id获取堕神品质
@params petId int 堕神id
@return quality int 品质
--]]
function PetManager.GetPetQualityById(id)
	local petData = app.gameMgr:GetPetDataById(id) or {}
	local quality = 1
	if checkint(petData.isEvolution) == 1  then
		quality = PetPQuality.ORANGE
	else
		if  petData.petId then
			quality = PetManager.GetPetQualityByPetId(petData.petId)
		end
	end
	return quality
end
--[[
根据等级获取当前等级升级所需的经验 以当前等级为起点 不是计算总经验
@params level int 等级
@return _ int 升级所需的经验
--]]
function PetManager.GetLevelUpNeedExpByLevel(level)
	local nextLvConfig = CommonUtils.GetConfig('pet', 'level', level + 1)
	if nil ~= nextLvConfig then
		return checkint(nextLvConfig.exp)
	else
		return -1
	end
end
--[[
根据等级和经验值计算当前升级已经获得多少经验 以当前等级为起点 不是计算总经
@params level int 等级
@params totalExp int 总经验
@return result int 已经获得的经验
--]]
function PetManager.GetHasExpByLevelAndTotalExp(level, totalExp)
	local nextLvConfig = CommonUtils.GetConfig('pet', 'level', level + 1)
	local curLvConfig = CommonUtils.GetConfig('pet', 'level', level)

	if not (nextLvConfig or curLvConfig) then return -1 end

	return totalExp - checkint(curLvConfig.totalExp)
end
--[[
获取堕神最高等级
--]]
function PetManager.GetPetMaxLevel()
	return table.nums(CommonUtils.GetConfigAllMess('level', 'pet'))
end


--[[
获取堕神升级最多能放置的狗粮数
@return _ int
--]]
function PetManager.GetPetLevelUpMaxMaterialAmount()
	return 8
end
--[[
获取堕神强化最多能放置的狗粮数
@return _ int
--]]
function PetManager.GetPetBreakUpMaxMaterialAmountByBreakLevel(breakLevel)
	local petBreakConfig =  CommonUtils.GetConfig('pet', 'petBreak',breakLevel) or {}
	local consumePetNum = checkint(petBreakConfig.consumePetNum)
	return consumePetNum
end
--[[
根据堕神id 堕神等级获取作为狗粮的经验值 -> 堕神基础经验值 + 到达该等级所需要的经验值的一半
@params petId int pet id
@params level int 等级
@return exp int 经验
--]]
function PetManager.GetPetExpByPetIdAndLevel(petId, level)
	-- 基础经验值
	local petConfig = PetManager.GetPetConfig(petId)
	local baseExp = checkint(petConfig.baseExp)
	-- 惩罚经验值
	local bounusExp = math.round(checkint(CommonUtils.GetConfig('pet', 'level', level).totalExp) * 0.5)
	return baseExp + bounusExp
end
--[[
获取洗炼需要的资源
@return goodsId int 道具id
@return num int 数量
--]]
function PetManager.GetPropRecastCostConfig()
	return {
		goodsId = 890004,
		num = 1
	}
end
--[[
根据强化等级获取强化需要的资源
@params breakLevel int 强化等级
--]]
function PetManager.GetBreakCostConfig(breakLevel)
	local c_ = CommonUtils.GetConfig('pet', 'petBreak', breakLevel)
	return c_.consume
end

--[[
根据强化等级获取强化需要的资源
@params breakLevel int 强化等级
--]]
function PetManager.GetEvoltuionCostConfig(petId)
	local c_ = CommonUtils.GetConfig('pet', 'pet',petId) or {}
	return c_.evolutionConsume   or {}
end
--[[
根据强化等级获取强化成功率
@params breakLevel int 强化等级
return  10%
--]]
function PetManager.GetBreakProbabilityConfig(breakLevel)
	local c_ = CommonUtils.GetConfig('pet', 'petBreak', breakLevel)
	-- dump(c_)
	if not c_ then
		return 0
	else
		return checknumber(c_.rate1) * 100
	end
end


--[[
获取最高强化等级
@return _ int 最高强化等级
--]]
function PetManager.GetPetMaxBreakLevelById(id)
	local breakLevel = 10
	local mainData = app.gameMgr:GetPetDataById(id) or {}
	if mainData.petId then
		breakLevel = PetManager.GetPetMaxBreakLevelByPetId(mainData.petId)
	end
	return  breakLevel
end

function PetManager.GetPetMaxBreakLevelByPetId(petId)
	local breakLevel = 10
	local petConfig = PetManager.GetPetConfig(petId) or {}
	if CommonUtils.CheckModuleIsExitByModuleId(JUMP_MODULE_DATA.SMELTING_PET) then
		if checkint(petConfig.type)  == PetType.BOSS then
			breakLevel = 20
		end
	end
	return  breakLevel
end


function PetManager.GetPaxMaxBreakLevelTipById(id)
	local isReturn  = ""
	local mainPetData = app.gameMgr:GetPetDataById(id)
	if checkint(mainPetData.breakLevel) >= PetManager.GetPetMaxBreakLevelById(id) then
		-- 强化等级已满 无法添加

		local petConfig = PetManager.GetPetConfig(mainPetData.petId) or {}
		if checkint(petConfig.type)  ==  PetType.BOSS  and  checkint(mainPetData.isEvolution) == 0  then
			isReturn =__('当前强化等级已达上限，通过异化可提升强化等级。')
		else
			isReturn = __('!!!已经强化到最高等级 无法添加!!!')
		end
	end
	return isReturn
end
--[[
获取一个随机的属性类型
@params petId int 堕神配表id
@params pIndex int 属性序号
@return ptype PetP 堕神属性类型
--]]
function PetManager.GetRandomPropType(petId, pIndex)
	local ptype = math.random(table.nums(PetP))
	return ptype
end
--[[
获取一个随机的属性值
@params petId int 堕神配表id
@params pIndex int 属性序号
@return _, _, _ number, PetPQuality, PetP
--]]
function PetManager.GetRandomPropValue(petId, pIndex)
	local petConfig = PetManager.GetPetConfig(petId)
	local pquality = math.random(table.nums(PetPQuality))
	local props = petConfig.attr[tostring(pIndex)].attrNum[pquality]
	local ptype = math.random(#props)
	local pvalue = props[ptype]
	return pvalue, pquality, ptype
end
--[[
获取堕神对卡牌加成的战斗力
@params pData table 堕神属性信息{
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	...
}
@return result int 战斗力
--]]
function PetManager.GetPetStaticBattlePoint(pData)
	local result = 0

	for i,v in ipairs(pData) do
		if v.unlock then
			if PetP.ATTACK == v.ptype then

				result = result + v.pvalue * 10

			elseif PetP.DEFENCE == v.ptype then

				result = result + v.pvalue * 16.7

			elseif PetP.HP == v.ptype then

				result = result + v.pvalue * 1

			elseif PetP.CRITRATE == v.ptype then

				result = result + (v.pvalue - 100) * 0.17

			elseif PetP.CRITDAMAGE == v.ptype then

				result = result + (v.pvalue - 100) * 0.118

			elseif PetP.ATTACKRATE == v.ptype then

				result = result + (v.pvalue - 100) * 0.109

			end
		end
	end

	result = math.floor(result)

	return result
end
--[[
根据性格id获取性格icon
@params character int 性格id
@return _ string 性格图标
--]]
function PetManager.GetCharacterIconPath(character)
	return string.format('ui/pet/pet_info_ico_charactor_%d.png', checkint(character))
end
--[[
获取本命加成
@params petId int 堕神id 
@params isEvolution int 是否异化 1 是 0 否
@return _ number 本命加成
--]]
function PetManager.GetExclusiveAddition(petId, isEvolution)
	return PetUtils.GetExclusiveAddition(petId, isEvolution)
end
---------------------------------------------------
-- utils end --
---------------------------------------------------


--[[
根据卡牌id判断装备的宠物是否是专属宠物
playerCardId 数据库自增id
]]
function PetManager:checkIsExclusivePet(playerCardId)
    local bool = false
    local data = app.gameMgr:GetCardDataById(playerCardId)
    if data then
        if data.playerPetId then
            local cardData = CommonUtils.GetConfig('cards', 'card', data.cardId)
            local petData  = app.gameMgr:GetPetDataById(data.playerPetId)
            -- dump(petData.petId)
            if petData then
                local sss = string.split(cardData.exclusivePet, ';')
                for i, v in ipairs(sss) do
                    -- dump(v)
                    if checkint(v) == checkint(petData.petId) then
                        bool = true
                        break
                    end
                end
            end
        end
    end

    return bool
end

--==============================--
--desc:记录当前堕神的id
--petId 输入堕神的petId
--time:2017-07-26 02:42:28
--@return
--==============================--
function PetManager:CheckMonsterIsLock(petId)
    petId                 = petId or "210001"
    local monsterId = CommonUtils.GetConfigAllMess('pet', 'collection')[tostring(petId)]
    local monsterInfo = CommonUtils.GetConfigAllMess('monster', 'collection')
    if monsterId and  monsterInfo[tostring(monsterId)] then
        -- 检测该怪物是否在表中存在
        app.gameMgr:GetUserInfo().monster[tostring(monsterId)] = 3
    end
end

return PetManager
