--[[
宠物工具类
--]]
PetUtils = {}

------------ import ------------
------------ import ------------

------------ define ------------
-- 堕神属性定义
PetP = {
	ATTACK 			= 1,
	DEFENCE 		= 2,
	HP 				= 3,
	CRITRATE 		= 4,
	CRITDAMAGE 		= 5,
	ATTACKRATE 		= 6
}

-- 堕神类型
PetType = {
	NORMAL 				= 1, -- 小怪
	ELITE 				= 2, -- 精英
	BOSS 				= 3  -- boss
}

-- 堕神性格加成类型
PetCharacterAttrType = {
	MULTI 			= 1, 		-- 乘法系数
	ADDITION 		= 2 		-- 加法系数
}

-- 堕神属性品质
PetPQuality = {
	WHITE 				= 1, -- 白
	GREEN 				= 2, -- 绿
	BLUE 				= 3, -- 蓝
	PURPLE 				= 4, -- 紫
	ORANGE 				= 5  -- 橙
}
PetPQualityName = {
	[PetPQuality.WHITE] 			= 'white',
	[PetPQuality.GREEN] 			= 'green',
	[PetPQuality.BLUE] 				= 'blue',
	[PetPQuality.PURPLE] 			= 'purple',
	[PetPQuality.ORANGE] 			= 'orange'
}
------------ define ------------

-------------------------------------------------
-- pet conf
-------------------------------------------------

--[[
获取宠物的配表信息
@params petId int 宠物id
@return _ table 宠物配表信息
--]]
function PetUtils.GetPetConfig(petId)
	return CommonUtils.GetConfig('pet', 'pet', petId)
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
function PetUtils.GetPetFixedPByPetId(petId, ptype, basepvalue, pquality, breakLevel, characterId, activeExclusive, isEvolution)
	local result = 0

	-- 根据成长计算修正属性
	local petPGrow = 0
	if 0 < breakLevel then
		for i = 1, breakLevel do
			petPGrow = petPGrow + PetUtils.GetPetPropGrow(petId, pquality, i)
		end
	end

	result = basepvalue * (1 + petPGrow)

	-- 计算性格加成
	local characterIdConfig = CommonUtils.GetConfig('pet', 'petCharacter', characterId)

	local attrNum = nil
	local attrType = nil

	local attrInfo = {
		[PetCharacterAttrType.MULTI] = 0,
		[PetCharacterAttrType.ADDITION] = 0
	}

	if nil ~= characterIdConfig then
		for i,v in ipairs(characterIdConfig.effectAttrType) do
			if ptype == checkint(v) then
				-- 类型正确 受到加成
				attrNum = checknumber(characterIdConfig.effectAttrNum[i])
				attrType = checkint(characterIdConfig.numType[i])

				attrInfo[attrType] = attrInfo[attrType] + attrNum
			end
		end
	end

	result = result * (1 + attrInfo[PetCharacterAttrType.MULTI]) + attrInfo[PetCharacterAttrType.ADDITION]

	if activeExclusive then
		result = result * (1 + PetUtils.GetExclusiveAddition(petId, isEvolution))
	end

	return result
end

--[[
根据堕神配表id 属性品质 突破等级 获取堕神属性成长系数
@params petId int 堕神配表id
@params pquality int 属性品质
@params breakLevel int 突破等级
--]]
function PetUtils.GetPetPropGrow(petId, pquality, breakLevel)
	local petPGrowConfig = CommonUtils.GetConfig('pet', 'petBreak', breakLevel)
	return petPGrowConfig[tostring(PetUtils.GetPetPropGrowFieldName(petId, pquality))]
end

--[[
根据堕神配表id 属性品质获取堕神成长系数字段名
@params petId int 堕神id
@params pquality int 堕神属性品质
@return fieldName string 成长系数表字段名
--]]
function PetUtils.GetPetPropGrowFieldName(petId, pquality)
	local petConfig = PetUtils.GetPetConfig(petId)
	local petType = checkint(petConfig.type)
	local nameMapping = {
		[PetType.NORMAL] = '1',
		[PetType.ELITE] = '2',
		[PetType.BOSS] = '3',
	}
	return PetPQualityName[pquality] .. nameMapping[petType]
end

--[[
获取堕神全属性解锁配置
@return _ table 堕神全属性配置
--]]
function PetUtils.GetPetPInfo()
	return {
		{unlockLevel = 0, ptypeName = 'extraAttrType1', pnumName = 'extraAttrNum1', pqualityName = 'extraAttrQuality1'},
		{unlockLevel = 10, ptypeName = 'extraAttrType2', pnumName = 'extraAttrNum2', pqualityName = 'extraAttrQuality2'},
		{unlockLevel = 20, ptypeName = 'extraAttrType3', pnumName = 'extraAttrNum3', pqualityName = 'extraAttrQuality3'},
		{unlockLevel = 30, ptypeName = 'extraAttrType4', pnumName = 'extraAttrNum4', pqualityName = 'extraAttrQuality4'}
	}
end


--[[
获取堕神属性和卡牌属性加成对应的映射
@params ptype PetP 属性类型
@return _ ObjP 卡牌属性
--]]
function PetUtils.GetPetP2CardP(ptype)
	local config = {
		[PetP.ATTACK] 			= ObjP.ATTACK,
		[PetP.DEFENCE] 			= ObjP.DEFENCE,
		[PetP.HP] 				= ObjP.HP,
		[PetP.CRITRATE] 		= ObjP.CRITRATE,
		[PetP.CRITDAMAGE] 		= ObjP.CRITDAMAGE,
		[PetP.ATTACKRATE] 		= ObjP.ATTACKRATE
	}

	return config[ptype]
end


--[[
获取本命加成
@params petId int 堕神id 
@params isEvolution int 是否异化 1 是 0 否
@return _ number 本命加成
--]]
function PetUtils.GetExclusiveAddition(petId, isEvolution)
	if isEvolution and 1 == checkint(isEvolution) then
		return 0.2
	else
		return 0.1
	end
end


--[[
根据宠物信息获取宠物对于卡牌属性的加成
@params cardId int 卡牌id
@params petsData table 宠物属性
@return result map 加成信息 {
	[ObjP] = {value = nil, valueMulti = nil},
	[ObjP] = {value = nil, valueMulti = nil},
	[ObjP] = {value = nil, valueMulti = nil},
	...
}
--]]
function PetUtils.GetPetPropertyAddition(cardId, petsData)
	local result = {}

	if nil ~= petsData then

		for index, petData in pairs(petsData) do

			if nil ~= petData.petId and 0 ~= checkint(petData.petId) then

				local petId = checkint(petData.petId)
				local petLevel = checkint(petData.level)
				local petBreakLevel = checkint(petData.breakLevel)
				local petCharacter = checkint(petData.character)
	
				-- 是否激活本命效果
				local activeExclusive = PetUtils.IsActiveExclusive(petId, cardId)
	
				for i, pinfo in ipairs(petData.attr) do
					-- 是否解锁
					local unlock = petLevel >= PetUtils.GetPetPInfo()[i].unlockLevel
	
					if unlock then
						-- 属性类型
						local ptype = checkint(pinfo.type)
						-- 属性基础值
						local pbasevalue = checknumber(pinfo.num)
						-- 属性品质
						local pquality = checkint(pinfo.quality)
						
						-- 计算修正后的属性值
						local pvalue = PetUtils.GetPetFixedPByPetId(
							petId,
							ptype,
							pbasevalue,
							pquality,
							petBreakLevel,
							petCharacter,
							activeExclusive,
							checkint(petData.isEvolution)
						)
	
						-- /***********************************************************************************************************************************\
						--  * 宠物属性增益目前只有加法系数
						-- \***********************************************************************************************************************************/
						local cardptype = PetUtils.GetPetP2CardP(ptype)
						if cardptype then
							if nil == result[cardptype] then
								result[cardptype] = {value = 0, valueMulti = 0}
							end
							
							-- 递增加法系数
							result[cardptype].value = result[cardptype].value + pvalue
							-- 递增乘法系数
							result[cardptype].valueMulti = result[cardptype].valueMulti + 0
						end
					end
				end

			else

				-- 非法数据 不处理 存在checkin的脏数据

			end

		end

	end
	
	return result
end


--[[
判断是否激活本命效果
@params petId int 宠物id
@params cardId int 卡牌id
@return result bool 是否激活本命
--]]
function PetUtils.IsActiveExclusive(petId, cardId)
	local result = false
	local petConfig = PetUtils.GetPetConfig(petId)
	if nil ~= petConfig and petConfig.exclusiveCard then
		for _, ecid in ipairs(petConfig.exclusiveCard) do
				if checkint(ecid) == checkint(cardId) then
				result = true
				break
			end
		end
	end
	return result
end


--[[
获取宠物属性的基础值
@params petId int 宠物id
@params index int 属性序号
@params type PetP 宠物属性类型
@params quality PetPQuality 宠物属性品质
@return baseValue number 宠物属性基础值
--]]
function PetUtils.GetPetBaseProperty(petId, index, type, quality)
	local baseValue = 0
	local petConfig = PetUtils.GetPetConfig(petId)
	if nil ~= petConfig then

		if nil ~= petConfig.attr[tostring(index)] and
			nil ~= petConfig.attr[tostring(index)].attrNum[quality] then

			baseValue = petConfig.attr[tostring(index)].attrNum[quality][type]

		end

	end
	return baseValue
end


-------------------------------------------------
-- server data convert
-------------------------------------------------

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
function PetUtils.ConvertPetPropertyDataByServerData(petData, activeExclusive)
	if nil == petData or 0 == checkint(petData.petId) then return nil end

	local result = {}

	local petId = checkint(petData.petId)
	local petLevel = checkint(petData.level)
	local petBreakLevel = checkint(petData.breakLevel)
	local petCharacter = checkint(petData.character)

	for i, pinfo in ipairs(petData.attr) do
		-- 属性类型
		local ptype = checkint(pinfo.type)
		-- 属性基础值
		local pbasevalue = checknumber(pinfo.num)
		-- 属性品质
		local pquality = checkint(pinfo.quality)
		-- 是否解锁
		local unlock = petLevel >= PetUtils.GetPetPInfo()[i].unlockLevel

		-- 计算修正后的属性值
		local pvalue = PetUtils.GetPetFixedPByPetId(
			petId,
			ptype,
			pbasevalue,
			pquality,
			petBreakLevel,
			petCharacter,
			activeExclusive,
			checkint(petData.isEvolution)
		)

		table.insert(result, {
			ptype = ptype,
			pvalue = pvalue,
			pquality = pquality,
			unlock = unlock
		})
	end
	
	return result
end


--[[
根据转换成客户端使用的宠物数据获取卡牌的属性加成信息
@params convertedData 转换后的数据 {
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	{ptype = PetP, pvalue = number, pquality = PetPQuality, unlock = bool},
	...
}
@return result map 加成信息 {
	[ObjP] = {value = nil, valueMulti = nil},
	[ObjP] = {value = nil, valueMulti = nil},
	[ObjP] = {value = nil, valueMulti = nil},
	...
}
--]]
function PetUtils.GetPetPropertyAdditionByConvertedData(convertedData)
	local result = {}

	for _,v in ipairs(convertedData) do
		if v.unlock then

			-- /***********************************************************************************************************************************\
			--  * 宠物属性增益目前只有加法系数
			-- \***********************************************************************************************************************************/
			local cardptype = PetUtils.GetPetP2CardP(v.ptype)
			if nil == result[cardptype] then
				result[cardptype] = {value = 0, valueMulti = 0}
			end

			-- 递增加法系数
			result[cardptype].value = result[cardptype].value + v.pvalue
			-- 递增乘法系数
			result[cardptype].valueMulti = result[cardptype].valueMulti + 0

		end
	end

	return result
end


--[[
根据指定堕神id格式化服务器返回的堕神数据
@params petConvertId int 指定堕神id
@return petData map 类似服务器返回的宠物数据
--]]
function PetUtils.FormatPetDataByCustomizeId(petConvertId)
	local petConvertConfig = CommonUtils.GetConfig('goods', 'petConvert', petConvertId)
	if nil == petConvertConfig or nil == petConvertConfig.pet then return nil end

	local petDataConfig = petConvertConfig.pet
	local petId = checkint(petDataConfig.petId)

	-- 修正宠物的属性
	local attr = {}
	local attrInfo = nil
	local attrType = nil

	local petptype = nil
	local petpquality = nil

	for i = 1, table.nums(petDataConfig.extraAttr) do
		attrInfo = petDataConfig.extraAttr[tostring(i)]
		petptype = checkint(attrInfo.attrId)
		petpquality = checkint(attrInfo.attrQualityId)

		local petp = {
			type = petptype,
			quality = petpquality,
			num = PetUtils.GetPetBaseProperty(petId, i, petptype, petpquality)
		}
		attr[i] = petp
	end

	local petData = {
		petId = petId,
		level = checkint(petDataConfig.level),
		breakLevel = checkint(petDataConfig.breakLevel),
		character = checkint(petDataConfig.character),
		isEvolution = checkint(petDataConfig.isEvolution),
		attr = attr
	}

	return petData
end






























