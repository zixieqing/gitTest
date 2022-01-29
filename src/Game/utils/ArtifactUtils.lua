--[[
神器工具类
--]]
ArtifactUtils = {}

------------ import ------------
------------ import ------------

------------ define ------------
TALENT_TYPE = {
    SMALL_TALENT        = 1, -- 小技能天赋
    GEM_TANLENT         = 2   -- 宝石技能天赋
}

GEM_STAGE = {
    LOWER               = 1, -- 低阶
    MIDDLE              = 2, -- 中阶
    HIGH                = 3, -- 高阶
    VERY_HIGH           = 4  -- 极高阶

}
------------ define ------------

-------------------------------------------------
-- artifact conf
-------------------------------------------------

--[[
根据卡牌id 天赋id 获取天赋的配表信息
@params cardId int 卡牌id
@params talentId int 天赋id
--]]
function ArtifactUtils.GetCardTalentConfig(cardId, talentId)
    local cardTalentConfig = ArtifactUtils.GetCardAllTalentConfig(cardId)
    if nil ~= cardTalentConfig then
        return cardTalentConfig[tostring(talentId)]
    else
        return nil
    end
end


--[[
根据卡牌id获取该卡牌所有的神器天赋
@params cardId int 卡牌id
@return _ talentData
--]]
function ArtifactUtils.GetCardAllTalentConfig(cardId)
    return CommonUtils.GetConfig('artifact', 'talentPoint', cardId)
end


--[[
根据宝石id获取宝石配置信息
@params gemstoneId int 宝石id
--]]
function ArtifactUtils.GetGemstoneConfig(gemstoneId)
	return CommonUtils.GetConfig('artifact', 'gemstone', gemstoneId)
end


--[[
获取宝石技能组的配表信息
@params skillGroupId int 技能组id
@return _ table 配表信息
--]]
function ArtifactUtils.GetGemstoneSkillGroupConfig(skillGroupId)
    return CommonUtils.GetConfig('artifact', 'gemstoneSkillGroup', skillGroupId)
end


--[[
根据宝石技能id获取宝石技能的ui显示描述
@params skillId int 技能id
@params isEmpty bool 该宝石是否为空 为空显示默认描述
@return descr string 技能显示的描述
--]]
function ArtifactUtils.GetArtifactGemSkillDescrBySkillId(skillId, isEmpty)
	local descr = ''

	local skillConfig = CommonUtils.GetSkillConf(checkint(skillId))
	if skillConfig then
		if true == isEmpty then
			descr = skillConfig.descr0
		else
			descr = skillConfig.descr
		end
	end

	return descr
end


--[[
获取天赋点被动增加的卡牌属性
@params cardId int 卡牌id
@params talentId int 天赋点id
@params level 天赋等级
@params gemstoneId int 插槽宝石id
@return ptype, pvalue ObjP, number 属性类型 属性值
--]]
function ArtifactUtils.GetArtifactTalentInnateProperty(cardId, talentId, level, gemstoneId)
    local ptype, pvalue = nil, nil
    local talentConfig = ArtifactUtils.GetCardTalentConfig(cardId, talentId)

    if nil ~= talentConfig then
        local propertyIndex = ArtifactUtils.GetArtifactTalentEffectIndex(cardId, talentId, level, gemstoneId)
        if nil ~= propertyIndex and nil ~= talentConfig.artifactAttrType[propertyIndex] then
            ptype = checkint(talentConfig.artifactAttrType[propertyIndex])
            pvalue = checknumber(talentConfig.artifactAttrNum[propertyIndex])
        end
    end

    return ptype, pvalue
end


--[[
获取当前对应的是天赋点上第几条效果
@params cardId int 卡牌id
@params talentId int 天赋点id
@params level 天赋等级
@params gemstoneId int 插槽宝石id
@return index int 效果序号
--]]
function ArtifactUtils.GetArtifactTalentEffectIndex(cardId, talentId, level, gemstoneId)
    local index = nil
    local talentConfig = ArtifactUtils.GetCardTalentConfig(cardId, talentId)

    if nil ~= talentConfig then
        local talentStyle = checkint(talentConfig.style)

        if TALENT_TYPE.SMALL_TALENT == talentStyle then

            -- 小天赋 等级就是对应的效果序号
            index = checkint(level)

        elseif TALENT_TYPE.GEM_TANLENT == talentStyle then

            -- 插槽天赋 进一步判断
            if nil ~= gemstoneId then
                local gemstoneConfig = ArtifactUtils.GetGemstoneConfig(gemstoneId)
                if nil ~= gemstoneConfig then
                    local gemstoneColor = checkint(gemstoneConfig.color)

                    local colorJudge = false
                    for _, color in ipairs(talentConfig.gemstoneColor) do
                        if gemstoneColor == checkint(color) then
                            colorJudge = true
                            break
                        end
                    end

                    -- 判断是否满足color的条件
                    if not colorJudge then return index end

                    local gemstoneShape = checkint(gemstoneConfig.type)

                    -- 判断序号
                    for i, shape in ipairs(talentConfig.gemstoneShape) do
                        if gemstoneShape == checkint(shape) then
                            index = i
                            break
                        end
                    end
                end
            end

        end
    end

    return index
end


--[[
根据宝石id获取宝石的最终属性加成
@params gemstoneId int 宝石id
@return addition list 属性加成list
--]]
function ArtifactUtils.GetGemstonePropertyAddition(gemstoneId)
    local addition = {}
    local gemstoneConfig = ArtifactUtils.GetGemstoneConfig(gemstoneId)

    if nil ~= gemstoneConfig then
        for _, attrInfo in ipairs(gemstoneConfig.attr) do

            local ptype = checkint(attrInfo[1])
            local pvalueMulti = checknumber(attrInfo[2])
            local pvalue = 0

            table.insert(addition, {
                ptype = ptype,
                pvalueMulti = pvalueMulti,
                pvalue = pvalue
            })

        end
    end
    return addition
end


--[[
根据卡牌的神器信息获取神器对于卡牌的属性加成
@params cardId int 卡牌id
@params artifactData 神器的信息
@return result map 加成信息 {
	[ObjP] = {value = nil, valueMulti = nil},
	[ObjP] = {value = nil, valueMulti = nil},
	[ObjP] = {value = nil, valueMulti = nil},
	...
}
--]]
function ArtifactUtils.GetArtifactPropertyAddition(cardId, artifactData)
	local result = {}

	if nil ~= artifactData then

		local sk = sortByKey(artifactData)

		for _, talentId_ in ipairs(sk) do

			-- 天赋id
			local talentId = checkint(talentId_)
			-- 天赋数据
			local talentData = artifactData[talentId_]
			-- 天赋等级
			local level = checkint(talentData.level)
			-- 宝石id
			local gemstoneId = nil
			if nil ~= talentData.gemstoneId and 0 ~= checkint(talentData.gemstoneId) then
				gemstoneId = checkint(talentData.gemstoneId)
			end

			------------ 计算属性加成 天赋属性只有一种全部相加 ------------
			local talentptype, talentpvalue = ArtifactUtils.GetArtifactTalentInnateProperty(cardId, talentId, level, gemstoneId)
			if nil ~= talentptype then
				if nil == result[talentptype] then
					result[talentptype] = {value = 0, valueMulti = 0}
				end

				-- /***********************************************************************************************************************************\
				--  * 神器天赋目前只有加法系数
				-- \***********************************************************************************************************************************/
				result[talentptype].value = result[talentptype].value + talentpvalue
				result[talentptype].valueMulti = result[talentptype].valueMulti + 0
			end
			------------ 计算属性加成 天赋属性只有一种全部相加 ------------

			------------ 计算宝石属性加成 宝石属性有乘法和加法系数 ------------
			if nil ~= gemstoneId then
				local gemstonePAddition = ArtifactUtils.GetGemstonePropertyAddition(gemstoneId)
				for _, addition_ in ipairs(gemstonePAddition) do

					local gemstoneptype = addition_.ptype
					local gemstonepvalue = addition_.pvalue
					local gemstonepvaluemulti = addition_.pvalueMulti

					if nil ~= gemstoneptype then
						if nil == result[gemstoneptype] then
							result[gemstoneptype] = {value = 0, valueMulti = 0}
						end

						-- /***********************************************************************************************************************************\
						--  * 宝石增益目前只有乘法系数
						-- \***********************************************************************************************************************************/
						result[gemstoneptype].value = result[gemstoneptype].value + gemstonepvalue
						result[gemstoneptype].valueMulti = result[gemstoneptype].valueMulti + gemstonepvaluemulti
					end

				end
			end
			------------ 计算宝石属性加成 宝石属性有乘法和加法系数 ------------

		end

	end

	return result
end


--[[
获取天赋点激活的技能效果
@params cardId int 卡牌id
@params talentId int 天赋点id
@params level 天赋等级
@params gemstoneId int 插槽宝石id
@return skillId int 天赋点激活的技能id
--]]
function ArtifactUtils.GetArtifactTalentInnateSkill(cardId, talentId, level, gemstoneId)
    local skillId = nil
    local talentConfig = ArtifactUtils.GetCardTalentConfig(cardId, talentId) or {}
    if nil ~= talentConfig then
        local talentStyle = checkint(talentConfig.style)
        local propertyIndex = ArtifactUtils.GetArtifactTalentEffectIndex(cardId, talentId, level, gemstoneId)
        if nil ~= propertyIndex and nil ~= talentConfig.getSkill[propertyIndex] then
            if TALENT_TYPE.SMALL_TALENT == talentStyle then

                -- 小天赋点 直接返回技能id
                skillId = talentConfig.getSkill[propertyIndex] and checkint(talentConfig.getSkill[propertyIndex]) or nil

            elseif TALENT_TYPE.GEM_TANLENT == talentStyle then

                -- 插槽天赋
                local skillGroupId = checkint(talentConfig.getSkill[propertyIndex])
                skillId = ArtifactUtils.GetGemstoneActiveTalentSkillId(skillGroupId, gemstoneId)

            end
        end
    end

    return skillId
end


--[[
根据技能组id和宝石id获取技能id
@params skillGroupId int 技能组id
@params gemstoneId int 宝石id
@return skillId int 技能id
--]]
function ArtifactUtils.GetGemstoneActiveTalentSkillId(skillGroupId, gemstoneId)
    local skillId = nil

    local skillGroupConfig = ArtifactUtils.GetGemstoneSkillGroupConfig(skillGroupId)
    if nil ~= skillGroupConfig then
        local gemstoneConfig = ArtifactUtils.GetGemstoneConfig(gemstoneId)
        if nil ~= gemstoneConfig then
            local gemstoneGrade = checkint(gemstoneConfig.grade)
            if nil ~= skillGroupConfig[tostring(gemstoneGrade)] then
                skillId = checkint(skillGroupConfig[tostring(gemstoneGrade)])
            end
        end
    end

    return skillId
end


-------------------------------------------------
-- server data convert
-------------------------------------------------

--[[
根据配置的神器天赋id (神器天赋解锁数量和宝石插槽数据) 格式化数据 本地配表神器天赋 -> 服务器返回的通用神器天赋
@params cardId int 卡牌id
@params artifactId 成套的神器天赋id
@return artifactData map 服务器返回的通用神器天赋数据
--]]
function ArtifactUtils.FormatArtifactDataByCustomizeId(cardId, artifactId)
	local artifactData = {}
	local customizeArtifactConfig = CommonUtils.GetConfig('battle', 'cardArtifact', artifactId)

	if nil == customizeArtifactConfig then return artifactData end

	-- 卡牌的固有神器天赋配置
	local cardArtifactConfig = ArtifactUtils.GetCardAllTalentConfig(cardId)
	if nil == cardArtifactConfig then return artifactData end
	local totalCardArtifactTalentPointAmount = table.nums(cardArtifactConfig)

	-- 配表控制的神器天赋解锁值
	local unlockTalentValue = checkint(customizeArtifactConfig.talentNum)
	-- 寻找起点天赋 暂时写死为id1的天赋点
	local startPoint = 1
	-- 终点天赋 暂时写死为id0
	local endPoint = 0	

	local leftUnlockTalentValue = unlockTalentValue
	local gemstoneItor = 1
	-- 记录分歧点 一条线走完再回头来走分歧点
	local diffPoints = {} -- 分歧点 -> list
	local meetPoints = {} -- 合流点 -> map

	-- 根据传入天赋点的数据构造服务器的格式
	local function GetFormattedArtifactTalent(talentPointConfig_, level_, gemstoneId_)
		local data_ = {
			talentId = checkint(talentPointConfig_.talentId),
			type = checkint(talentPointConfig_.style),
			level = level_,
			gemstoneId = gemstoneId_
		}
		return data_
	end

	-- 获取下一个分歧点
	local function GetNextDiffPoint()
		if 0 < #diffPoints then
			local nextDiffPoint = diffPoints[#diffPoints]
			table.remove(diffPoints, #diffPoints)
			return nextDiffPoint
		else
			return nil
		end
	end

	local function AddArtifactTalent(talentId_)

		local talentPointConfig = cardArtifactConfig[tostring(talentId_)]
		if nil == talentPointConfig then
			-- 天赋信息没找到 跳出
			return
		end

		-- 天赋等级
		local level = math.min(leftUnlockTalentValue, checkint(talentPointConfig.level))
		leftUnlockTalentValue = leftUnlockTalentValue - checkint(talentPointConfig.level)

		-- 天赋对应的宝石id
		local gemstoneId = nil
		if TALENT_TYPE.GEM_TANLENT == checkint(talentPointConfig.style) then
			if nil ~= customizeArtifactConfig.gemstone[gemstoneItor] then
				gemstoneId = checkint(customizeArtifactConfig.gemstone[gemstoneItor])
				gemstoneItor = gemstoneItor + 1
			end
		end

		-- 构造天赋数据
		local formattedTalentData = GetFormattedArtifactTalent(talentPointConfig, level, gemstoneId)
		artifactData[tostring(talentId_)] = formattedTalentData

		if 1 < #talentPointConfig.beforeTalentId then
			-- 合流点
			meetPoints[tostring(talentId_)] = true
		end

		-- 下一个天赋点
		local afterTalentIdInfo = talentPointConfig.afterTalentId
		local afterTalentId = nil

		if 1 < #afterTalentIdInfo then
			
			------------ 存在分歧!!! ------------
			-- /***********************************************************************************************************************************\
			--  * 按照优先走完先出现分歧的线 按照配表顺序走
			-- \***********************************************************************************************************************************/

			-- 取第一个 剩下的插入分歧点集合
			afterTalentId = checkint(afterTalentIdInfo[1])
			for i = 2, #afterTalentIdInfo do
				table.insert(diffPoints, 1, checkint(afterTalentIdInfo[i]))
			end
			------------ 存在分歧!!! ------------

		else

			------------ 直线 ------------
			afterTalentId = checkint(afterTalentIdInfo[1])
			------------ 直线 ------------

		end

		-- 判断是否需要再往下走
		if endPoint == afterTalentId then
			-- 到终点了 检查是否有分歧路线没走完
			if 0 >= #diffPoints then
				-- 全部走完 返回
				return
			else
				-- 存在分歧没走完 选一个分歧点
				afterTalentId = GetNextDiffPoint()
			end
		else
			-- 没到终点 判断下一个点是否走过 是不是分歧点的合流点
			local afterTalentConfig = cardArtifactConfig[tostring(afterTalentId)]
			if 1 < #afterTalentConfig.beforeTalentId then
				-- 分歧路线的合流点 判断该点是否走过
				if true == meetPoints[tostring(afterTalentId)] then
					-- 该合流点已经走过 选一个分歧点
					afterTalentId = GetNextDiffPoint()
				else
					-- 该合流点还没走过 不处理
				end
			else
				-- 下一个点是合法的点 继续
			end
		end

		-- 最后判断一次下一个点是否合法 合法就递归
		if nil ~= afterTalentId then
			AddArtifactTalent(afterTalentId)
		else
			-- 不合法 返回
			return
		end
		
	end

	-- 开始构造数据
	local function StartConstruct(startPoint_)
		AddArtifactTalent(startPoint_)
	end

	StartConstruct(startPoint)

	return artifactData
end


--[[
    根据cardId 获取图武器的图片路径
    ---@params isBig 是否是大图片
--]]
function ArtifactUtils.GetArtifiactPthByCardId(cardId , isBig )
    local path = _res('arts/goods/goods_icon_error')
    if isBig then
        local cardPath = _res( string.format('arts/artifact/big/core_icon_%s' , tostring(cardId)))
        if utils.isExistent(cardPath) then
            path = cardPath
        end
    else
        local cardPath = _res( string.format('arts/artifact/small/core_icon_%s' , checkint(cardId) + 90000))
        if utils.isExistent(cardPath) then
            path = cardPath
        end
    end
    return path
end


--[[
    ---@param 根据cardId 获取神器碎片的id
--]]
function ArtifactUtils.GetArtifactFragmentsIdByCardId(cardId)
    local artifactFragmentId = checkint(cardId) + 90000
    return artifactFragmentId
end
