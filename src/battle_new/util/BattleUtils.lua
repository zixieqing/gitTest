--[[
战斗工具类
--]]
BattleUtils = {}

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- calc utils --
---------------------------------------------------
--[[
获取单条数据map的第一个key
@params t table
@return result string 
--]]
function BattleUtils.getFirstKey(t)
	return table.keys(t)[1]
end
--[[
获取目标map整数最大key
@params t table
@return result string 
--]]
function BattleUtils.GetMaxKey(t)
	if table.nums(t) == 0 then
		return 0
	else
		local keys = table.keys(t)
		table.sort(keys, function (a, b)
			return checkint(a) > checkint(b)
		end)
		return keys[1]
	end
end
--[[
获取两点组成向量相对于x正方向的夹角 顺时针为正 范围 -> [-180, 180]
sample --> BattleUtils.GetAngleByPoints(cc.p(0, 0), cc.p(0, -1)) = 90
--]]
function BattleUtils.GetAngleByPoints(startP, endP)
	local deltaVector = cc.pSub(endP, startP)
	local angle = -math.deg(math.atan(deltaVector.y / deltaVector.x))
	return angle
end
--[[
返回过滤配表空串 纯空格字符串的结果
@params s string 目标字符串
@return _ string 过滤后的字符串
--]]
function BattleUtils.GetFilteredStringBySpace(s)
	if nil == s then return nil end
	local ss = string.gsub(s, " ", "")
	local sLength = string.len(ss)
	if sLength < 1 then
		return nil
	else
		return s
	end
end
--[[
判断浮点数是否相等
@params float1 number 
@params float2 number
@return result bool 是否相等
--]]
function BattleUtils.isequalfloat(float1, float2)
	local accuracy = 1000
	local fixedfloat1 = float1 * accuracy
	local fixedfloat2 = float2 * accuracy
	return math.abs(fixedfloat1 - fixedfloat2) <= 1
end
--[[
获取统一格式化后展示层使用的时间
@params time number 时间
--]]
function BattleUtils.GetFormattedTimeForView(time)
	return math.ceil(time * 1000) * 0.001
end
--[[
判断一个table是否为空
--]]
function BattleUtils.IsTableEmpty(t)
	return nil == next(t)
end
--[[
判断一个值是否是table
--]]
function BattleUtils.IsTable(v)
	return 'table' == type(v)
end
--[[
判断是否是空串
@params str string输入字符串
@params spaceValid bool 空格是否视为有效字符
@params _ bool 是否是空串
--]]
function BattleUtils.IsStringEmpty(str, spaceValid)
	if spaceValid then
		return 0 >= string.len(str)
	else
		return 0 >= string.len(string.gsub(str, ' ', ''))
	end
end


---------------------------------------------------
-- card --
---------------------------------------------------
--[[
根据战斗物体职业获取战斗物体基础特征
@params career ConfigCardCareer 战斗物体职业
@return _ BattleObjectFeature 战斗物体基础特征
--]]
function BattleUtils.GetObjFeatureByCareer(career)
	if ConfigCardCareer.TANK == career or ConfigCardCareer.MELEE == career then

		return BattleObjectFeature.MELEE

	elseif ConfigCardCareer.RANGE == career then

		return BattleObjectFeature.REMOTE

	elseif ConfigCardCareer.HEALER == career then 	

		return BattleObjectFeature.HEALER

	else

		return BattleObjectFeature.BASE

	end
end



---------------------------------------------------
-- skill --
---------------------------------------------------
--[[
检查技能中是否存在特定的buff类型
@params btype ConfigBuffType buff 类型
@return _ bool 是否存在
--]]
function BattleUtils.IsSkillHaveBuffEffectByBuffType(skillId, btype)
	local skillConf = CommonUtils.GetSkillConf(skillId)
	return nil ~= skillConf.type[tostring(btype)]
end



---------------------------------------------------
-- log --
---------------------------------------------------
--[[
输出配表逻辑错误信息
--]]
function BattleUtils.PrintConfigLogicError(content, ...)
	print('\n>>>>> error\n    config logic error: ' .. content .. '\n<<<<< error')
	-- logs('\n>>>>> error\n    config logic error: ' .. content .. '\n<<<<< error')
end
--[[
输出战斗行为信息
--]]
function BattleUtils.PrintBattleActionLog(content, ...)
	print('\n**************\n', content, '\n**************\n')
	-- logs('\n**************\n', content, '\n**************\n')
end
--[[
输出警告
--]]
function BattleUtils.PrintBattleWaringLog(content, ...)
	print('\n<<<<< waring >>>>>\n', content)
	-- logs('\n<<<<< waring >>>>>\n', content)
end


--[[
判断是否是spine动画
@params node cc.node 目标指针
@return _ bool 
--]]
function BattleUtils.IsSpineNode(node)
	return 'sp.SkeletonAnimation' == tolua.type(node)
end
--[[
输出一条行为的日志
@params obj BaseLogicModel
@params ... string
--]]
function BattleUtils.BattleObjectActionLog(obj, ...)
	-- local objName = obj:GetObjectName()
	-- local objTag = obj:GetOTag()
	-- logs(objName, objTag, ...)

	-- print('\n\27[31m*********\27[m\n', '\27[36m' .. objName .. '\27[m', '->', ...)
	-- print('\27[32m*********\27[m')
end
--[[
输出一条spine动画日志
@params otag int 宿主的tag
@params ... string
--]]
function BattleUtils.ObjectSpineActionLog(otag, ...)
	-- print('\n@@@@@@\n', 'spine owner tag', otag, '->', ...)
	-- print('@@@@@@')
	-- logs('~~~~~~~~~~~~~', otag, ...)
end



---------------------------------------------------
-- spine --
---------------------------------------------------
--[[
根据地图id 图层id获取地图spine的缓存名
@params mapId int 地图id
@params bgIdx int 图层id
--]]
function BattleUtils.GetBgSpineCacheName(mapId, bgIdx)
	return string.format('map_%d_%d', mapId, bgIdx)
end
--[[
根据spine文件id判断是否存在某个动画
@params spineId string spine文件的id
@parmas spineType SpineType spine动画的类型
@params animationName string 动画名
@return _ bool 是否存在
--]]
function BattleUtils.SpineHasAnimationByName(spineId, spineType, animationName)
	local spineData = nil
	if SpineType.AVATAR == spineType then
		spineData = CommonUtils.GetConfig('cards', 'avatarSpine', spineId)
	elseif SpineType.EFFECT == spineType then
		spineData = CommonUtils.GetConfig('cards', 'effectSpine', spineId)
	elseif SpineType.HURT == spineType then
		spineData = CommonUtils.GetConfig('cards', 'hurtSpine', spineId)
	end

	if nil ~= spineData then
		if nil ~= spineData.animations then
			return nil ~= spineData.animations[animationName]
		end
	end

	return false
end
--[[
根据spine id 类型获取spine战斗内使用的数据结构
@params spineId string spineid
@parmas spineType SpineType spine动画的类型
@params spineCreateScale number spine加载时的缩放比
@return struct ObjectSpineDataStruct spine数据信息
--]]
function BattleUtils.GetSpineDataStructBySpineId(spineId, spineType, spineCreateScale)
	if SpineType.AVATAR == spineType then

		return BattleUtils.GetAvatarSpineDataStructBySpineId(spineId, spineCreateScale)

	elseif SpineType.EFFECT == spineType then

		return BattleUtils.GetEffectSpineDataStructBySpineId(spineId, spineCreateScale)

	elseif SpineType.HURT == spineType then

		return BattleUtils.GetHurtSpineDataStructBySpineId(spineId, spineCreateScale)

	else

		return nil

	end
end
--[[
根据spine id获取avatar的数据信息
@params spineId string spineid
@params spineCreateScale number spine加载时的缩放比
@return struct ObjectSpineDataStruct spine数据信息
--]]
function BattleUtils.GetAvatarSpineDataStructBySpineId(spineId, spineCreateScale)
	local spineDataConfig = CommonUtils.GetConfig('cards', 'avatarSpine', spineId)
	if nil ~= spineDataConfig then
		return BattleUtils.GetSpineDataStructByConfig(spineId, spineCreateScale, spineDataConfig)
	else
		return nil
	end
end
--[[
根据spine id获取effect的数据信息
@params spineId string
@params spineCreateScale number spine加载时的缩放比
@return struct ObjectSpineDataStruct spine数据信息
--]]
function BattleUtils.GetEffectSpineDataStructBySpineId(spineId, spineCreateScale)
	local spineDataConfig = CommonUtils.GetConfig('cards', 'effectSpine', spineId)
	if nil ~= spineDataConfig then
		return BattleUtils.GetSpineDataStructByConfig(spineId, spineCreateScale, spineDataConfig)
	else
		return nil
	end
end
--[[
根据spine id获取hurt的数据信息
@params spineId string
@params spineCreateScale number spine加载时的缩放比
@return struct ObjectSpineDataStruct spine数据信息
--]]
function BattleUtils.GetHurtSpineDataStructBySpineId(spineId, spineCreateScale)
	local spineDataConfig = CommonUtils.GetConfig('cards', 'hurtSpine', spineId)
	if nil ~= spineDataConfig then
		return BattleUtils.GetSpineDataStructByConfig(spineId, spineCreateScale, spineDataConfig)
	else
		return nil
	end
end
--[[
根据id获取spine动画的缓存名
@params spineId string spineid
@parmas spineType SpineType spine动画的类型
@return _ string animation name in cache
--]]
function BattleUtils.GetCacheAniNameById(spineId, spineType)
	if SpineType.AVATAR == spineType then

		return BattleUtils.GetAvatarAniNameById(spineId)

	elseif SpineType.EFFECT == spineType then

		return BattleUtils.GetEffectAniNameById(spineId)

	elseif SpineType.HURT == spineType then

		return BattleUtils.GetHurtAniNameById(spineId)

	else

		return nil

	end
end
--[[
根据id获取spine avatar缓存名
@params id int 动画的id
@return _ string animation name in cache
--]]
function BattleUtils.GetAvatarAniNameById(id)
	return tostring(id)
end
--[[
根据id获取spine effect 缓存名
@params id int 动画的id
@return _ string animation name in cache
--]]
function BattleUtils.GetEffectAniNameById(id)
	return string.format('effect_%s', tostring(id))
end
--[[
根据id获取spine 被击 缓存名
@params id int 动画的id
@return _ string animation name in cache
--]]
function BattleUtils.GetHurtAniNameById(id)
	return string.format('hurt_%s', tostring(id))
end
--[[
根据动画id 特效类型判断是否load了该特效
@params spineId int spine动画id
@params spineType SpineType spine动画的类型
@params wave int 波数
@return _ bool 该资源是否在内存中
--]]
function BattleUtils.SpineInCache(spineId, spineType, wave)
	return G_BattleRenderMgr:SpineInCache(spineId, spineType, wave)
end
--[[
根据spine动画的cache name 反向获取对应的动画id
@params cacheName string 缓存名
@return id string 动画的id
--]]
function BattleUtils:GetAniIdByCacheName(cacheName)
	local id = nil
	if nil ~= tonumber(cacheName) then
		-- avatar的规则
		return cacheName
	else
		id = string.split(cacheName, '_')[2]
	end
	return id
end

---------------------------------------------------
-- res --
---------------------------------------------------
--[[
根据地图id获取整套地图的路径前缀
@params mapId int 地图id
@return bgFolderPath string 路径
--]]
function BattleUtils.GetBgFolderPath(mapId)
	local bgFolderPath = 'battle/map'
	-- 检查单个文件夹是否存在
	local mainBgPath = string.format('%s/%d/main_map_bg_%d_10.png', bgFolderPath, mapId, mapId)
	local fixedPath = app.fileUtils:fullPathForFilename(mainBgPath)
	if not BattleUtils.IsStringEmpty(fixedPath) then
		bgFolderPath = string.format('%s/%d', bgFolderPath, mapId)
	end
	return bgFolderPath
end



---------------------------------------------------
-- data convert config -> struct --
---------------------------------------------------
--[[
根据id获取镜头配置数据
@params cameraActionId int id
@return _ CameraActionStruct 镜头特效数据结构
--]]
function BattleUtils.GetCameraActionStructById(cameraActionId)
	local cameraActionConfig = CommonUtils.GetConfig('quest', 'lensControl', cameraActionId)
	if nil == cameraActionConfig then
		return nil
	else
		local struct = CameraActionStruct.New(
			checkint(cameraActionId),
			checkint(cameraActionConfig.type),
			checktable(cameraActionConfig.typeValue),
			checkint(cameraActionConfig.triggerType),
			checktable(cameraActionConfig.triggerValue),
			checknumber(cameraActionConfig.delayTime),
			checkint(cameraActionConfig.accelerate)
		)

		return struct
	end
end
--[[
根据技能id获取构造技能模型的技能数据
@params skillId int 技能id
@params skillLevel int 技能等级
@return skillInfo ConfigSkillInfoStruct 构造技能模型的数据
--]]
function BattleUtils.GetSkillInfoStructBySkillId(skillId, skillLevel)
	local skillInfo = nil
	local skillConfig = CommonUtils.GetSkillConf(skillId)

	if nil ~= skillConfig then

		local fixedEffect = nil

		------------ 构造buff数据 ------------
		local fixedBuffsEffect = CardUtils.GetFixedSkillEffect(skillId, skillLevel)

		local buffsInfo = {}
		local seekRulesInfo = {}
		local triggerActionInfo = {}
		local triggerConditionInfo = {}

		for buffType_, v in pairs(skillConfig.type) do

			local triggerActionInfos = {}

			-- 技能表中关于触发行为的数据
			-- buff的触发行为信息
			if nil ~= skillConfig.triggerAction and
				nil ~= skillConfig.triggerAction[tostring(buffType_)] and
				nil ~= skillConfig.triggerActionTarget and
				nil ~= skillConfig.triggerActionTarget[tostring(buffType_)] then

				local triggerActionConfig = skillConfig.triggerAction[tostring(buffType_)]
				local triggerActionTargetConfig = skillConfig.triggerActionTarget[tostring(buffType_)]

				for i, triggerActionConfig_ in ipairs(triggerActionConfig) do

					local triggerActionType = checkint(triggerActionConfig_.type)

					-- 过滤一次默认类型 默认类型不走触发逻辑
					if ConfigObjectTriggerActionType.BASE ~= triggerActionType then
						-- 触发行为的索敌规则
						local triggerActionSeekRule = SeekRuleStruct.New(
							checkint(triggerActionTargetConfig.type),
							checkint(triggerActionTargetConfig.sequence),
							checkint(triggerActionTargetConfig.num)
						)

						------------ buff触发内置cd ------------
						-- TODO --
						local buffTriggerInsideCD = 0
						if nil ~= skillConfig.triggerInsideCd and nil ~= skillConfig.triggerInsideCd[tostring(buffType_)] then
							buffTriggerInsideCD = checknumber(skillConfig.triggerInsideCd[tostring(buffType_)])
						end
						-- TODO --
						------------ buff触发内置cd ------------

						-- 触发行为数据
						local triggerActionInfo_ = BuffTriggerActionStruct.New(
							triggerActionType,
							triggerActionSeekRule,
							checknumber(triggerActionConfig_.time),
							checknumber(triggerActionConfig_.successRate),
							buffTriggerInsideCD
						)

						triggerActionInfos[triggerActionType] = triggerActionInfo_
					end
					
				end
			else
				-- 数据非法时
			end
			triggerActionInfo[tostring(buffType_)] = triggerActionInfos

			-- 技能表中关于触发条件的数据
			local triggerConditionInfo_ = nil
			if nil ~= skillConfig.triggerCondition and
				nil ~= skillConfig.triggerCondition[tostring(buffType_)] and
				nil ~= skillConfig.triggerConditionTarget and
				nil ~= skillConfig.triggerConditionTarget[tostring(buffType_)] then

				local triggerConditionConfig = skillConfig.triggerCondition[tostring(buffType_)]
				local triggerConditionTargetConfig = skillConfig.triggerConditionTarget[tostring(buffType_)]

				-- 触发条件的索敌规则
				local triggerConditionSeekRule = SeekRuleStruct.New(
					checkint(triggerConditionTargetConfig.type),
					checkint(triggerConditionTargetConfig.sequence),
					checkint(triggerConditionTargetConfig.num)
				)

				-- 触发条件的数据
				triggerConditionInfo_ = BuffTriggerConditionStruct.New(
					checkint(triggerConditionConfig.type),
					triggerConditionSeekRule,
					checktable(triggerConditionConfig.value),
					checkint(triggerConditionConfig.meetType)
				)
			else
				triggerConditionInfo_ = BuffTriggerConditionStruct.New()
			end
			triggerConditionInfo[tostring(buffType_)] = triggerConditionInfo_

			------------ 内置叠加上限 ------------
			local innerPileMax = 1
			if nil ~= skillConfig.innerPile and nil ~= skillConfig.innerPile[tostring(buffType_)] then
				innerPileMax = checkint(skillConfig.innerPile[tostring(buffType_)])
			end
			------------ 内置叠加上限 ------------

			local buffInfo = ConfigBuffInfoStruct.New(
				skillId,
				checkint(buffType_),
				checktable(fixedBuffsEffect[tostring(buffType_)].effect),
				checknumber(fixedBuffsEffect[tostring(buffType_)].effectTime),
				nil,
				innerPileMax,
				checknumber(v.effectSuccessRate),
				checkint(v.tapNum)
			)

			buffsInfo[buffType_] = buffInfo

			-- buff的索敌信息
			local seekRuleInfo = nil
			if nil ~= skillConfig.target[buffType_] then
				seekRuleInfo = SeekRuleStruct.New(
					checkint(skillConfig.target[buffType_].type),
					checkint(skillConfig.target[buffType_].sequence),
					checkint(skillConfig.target[buffType_].num)
				)
			end
			seekRulesInfo[buffType_] = seekRuleInfo
		end
		------------ 构造buff数据 ------------

		------------ 构造技能数据 ------------
		local infectSeekInfo = nil
		if nil ~= skillConfig.infectTarget then
			infectSeekInfo = SeekRuleStruct.New(
				checkint(skillConfig.infectTarget.type),
				checkint(skillConfig.infectTarget.sequence),
				checkint(skillConfig.infectTarget.num)
			)
		else
			infectSeekInfo = SeekRuleStruct.New()
		end

		skillInfo = ConfigSkillInfoStruct.New(
			skillId,
			checkint(skillConfig.property),
			buffsInfo,
			seekRulesInfo,
			infectSeekInfo,
			checknumber(skillConfig.infectTime),
			triggerActionInfo,
			triggerConditionInfo
		)
		------------ 构造技能数据 ------------

	end

	return skillInfo
end
--[[
根据spine的解表数据获取spine的数据信息
@params spineId string spineid
@params spineCreateScale number spine加载时的缩放比
@params spineDataConfig table spine json的解表数据
@return struct ObjectSpineDataStruct spine数据信息
--]]
function BattleUtils.GetSpineDataStructByConfig(spineId, spineCreateScale, spineDataConfig)
	------------ 处理动画的信息 ------------
	local animationsData = {}
	for animationName, animationData in pairs(spineDataConfig.animations) do

		local eventsData = {}
		if nil ~= animationData.events then
			for eventName, eventInfo in pairs(animationData.events) do

				eventsData[eventName] = {}

				for _, timeInfo in ipairs(eventInfo) do

					table.insert(eventsData[eventName], {
						time = checknumber(timeInfo.time),
						intValue = checkint(timeInfo.intValue),
						floatValue = checknumber(timeInfo.floatValue),
						stringValue = timeInfo.stringValue
					})

				end
			end
		end

		animationsData[animationName] = ObjectSpineAnimationDataStruct.New(
			animationName,
			checknumber(animationData.duration),
			eventsData
		)

	end
	------------ 处理动画的信息 ------------

	------------ 计算边界框 ------------
	local minx, miny = nil, nil
	local maxx, maxy = nil, nil
	local x, y = nil, nil
	local viewBox = cc.rect(0, 0, 0, 0)

	-- ui框
	if nil ~= spineDataConfig.viewBox and not BattleUtils.IsTableEmpty(spineDataConfig.viewBox) then
		for _, p in ipairs(spineDataConfig.viewBox) do
			x = checknumber(p.x)
			y = checknumber(p.y)
			if nil == minx then
				minx = x
			end
			if nil == miny then
				miny = y
			end
			if nil == maxx then
				maxx = x
			end
			if nil == maxy then
				maxy = y
			end
			minx = math.min(minx, x)
			miny = math.min(miny, y)
			maxx = math.max(maxx, x)
			maxy = math.max(maxy, y)
		end

		viewBox = cc.rect(minx, miny, maxx - minx, maxy - miny)
	end

	-- 碰撞框
	minx, miny = nil, nil
	maxx, maxy = nil, nil
	local collisionBox = cc.rect(0, 0, 0, 0)

	if nil ~= spineDataConfig.collisionBox and not BattleUtils.IsTableEmpty(spineDataConfig.collisionBox) then
		for _, p in ipairs(spineDataConfig.collisionBox) do
			x = checknumber(p.x)
			y = checknumber(p.y)
			if nil == minx then
				minx = x
			end
			if nil == miny then
				miny = y
			end
			if nil == maxx then
				maxx = x
			end
			if nil == maxy then
				maxy = y
			end
			minx = math.min(minx, x)
			miny = math.min(miny, y)
			maxx = math.max(maxx, x)
			maxy = math.max(maxy, y)
		end

		collisionBox = cc.rect(minx, miny, maxx - minx, maxy - miny)
	end

	local struct = ObjectSpineDataStruct.New(
		spineId,
		spineId,
		spineCreateScale or 1,
		1,
		viewBox,
		collisionBox,
		animationsData
	)

	return struct
	------------ 计算边界框 ------------
end



---------------------------------------------------
-- screen record --
---------------------------------------------------
--[[
是否在录像中
@return _ bool 是否在录像中
--]]
function BattleUtils.IsInScreenRecord()
	if BattleConfigUtils.IsScreenRecordEnable() then
		local AppSDK = require('root.AppSDK')
		return AppSDK:isReplayKitAvailable()
	else
		return false
	end
end
--[[
开始录像
@return _ bool 是否开始成功
--]]
function BattleUtils.StartScreenRecord()
	if not BattleConfigUtils.IsScreenRecordEnable() then
		print('!!! not enable screen record !!!')
		return false
	end

	if BattleUtils.IsInScreenRecord() then
		print('!!! already in screen record !!!')
		return false
	end

	local AppSDK = require('root.AppSDK')
	AppSDK:StartRecord()
	print('!!! start screen record !!!')

	return true
end
--[[
结束录像
@return _ bool 是否结束成功
--]]
function BattleUtils.StopScreenRecord()
	if not BattleConfigUtils.IsScreenRecordEnable() then
		print('!!! not enable screen record !!!')
		return false
	end

	if not BattleUtils.IsInScreenRecord() then
		print('!!! not in screen record !!!')
		return false
	end

	local AppSDK = require('root.AppSDK')
	AppSDK:StopRecord()
	print('!!! stop screen record !!!')

	return true
end
