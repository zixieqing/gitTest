--[[
堕神管理模块
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class ArtifactManager
local ArtifactManager = class('ArtifactManager',ManagerBase)

ArtifactManager.instances = {}

------------ import ------------
---@type GameManager
local ArtifactConfigParser = require('Game.Datas.Parser.ArtifactConfigParser')

local CARD_TYPE = {
    DEFEND = 1 ,
    ATTACK = 2,
    ARROW = 3,
    HEART = 4
}

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function ArtifactManager:ctor( key )
    self.super.ctor(self)
    if ArtifactManager.instances[key] ~= nil then
        funLog(Logger.INFO,"注册相关的facade类型" )
        return
    end
    self.stoneData = nil
    self.parseConfig = nil
    self.cardsTable  =  {}      -- 存储卡牌列表的顺序
    ArtifactManager.instances[key] = self
end
--[[
　　---@Description: 获取到ObjectPropertyInfo 的基础信息 多语言叙述 防止切换语言不生效问题
　　---@param :
　  ---@return : ObjectPropertyInfo  table类型
　　---@author : xingweihao
　　---@date : 2018/8/6 2:06 PM
--]]
function ArtifactManager.GetObjectPropertyInfo()
    -- 物体属性的一些信息
    local   ObjectPropertyInfo = {
        [ObjP.ATTACK]         = {name = __('攻击力')},
        [ObjP.DEFENCE]        = {name = __('防御力')},
        [ObjP.HP]             = {name = __('生命值')},
        [ObjP.CRITRATE]       = {name = __('暴击值')},
        [ObjP.CRITDAMAGE]     = {name = __('暴伤值')},
        [ObjP.ATTACKRATE]     = {name = __('攻速值')},
    }
    return  ObjectPropertyInfo
end

function ArtifactManager.GetInstance(key)
    key = (key or "ArtifactManager")
    if ArtifactManager.instances[key] == nil then
        ArtifactManager.instances[key] = ArtifactManager.new(key)
    end
    return ArtifactManager.instances[key]
end


function ArtifactManager.Destroy( key )
    key = (key or "ArtifactManager")
    if ArtifactManager.instances[key] == nil then
        return
    end
    --清除配表数据
    ArtifactManager.instances[key] = nil
end

---------------------------------------------------
-- utils end --
---------------------------------------------------
--[[
     根据goodsId 获取到宝石的品质
--]]
function ArtifactManager:GetGemStoneQualityByGoodsId(goodsId)
    local quality = 1
    -- TODO 标出来的时候要对表进行重新赋值
    local qualityConfig =  CommonUtils.GetConfigAllMess('gemstone', 'goods')
    local qualityOneConfig = qualityConfig[tostring(goodsId)] or {}
    quality = qualityOneConfig.quality or 1
    return checkint(quality)
end
---@return ArtifactConfigParser
function ArtifactManager:GetConfigParse()
    if not self.parseConfig then
        ---@type DataManager
        self.parseConfig = app.dataMgr:GetParserByName('artifact')
    end
    return self.parseConfig
end

function ArtifactManager:SetCardsList(cards)
    self.cardsTable  = cards
end
--[[
    获取到已经拥有的卡牌列表
--]]
function ArtifactManager:GetOnwerCards()
    local cards = {}
    for i, v in pairs(self.cardsTable) do
        if checkint(v.showFragment) ~= 1   then
            -- 不为碎片 而且等于一
            cards[#cards+1] = v
        end
    end
    return cards
end
function ArtifactManager:GetOwnerArtifactCards()
    local cards = {}
    for i, v in pairs(self.cardsTable) do
        if checkint(v.showFragment) ~= 1 and checkint(v.isArtifactUnlock) == 1 then
        -- 不为碎片 而且等于一
            cards[#cards+1] = v
        end
    end
    return cards
end
--[[
    根据playerCardId 获取到在飨灵列表界面的所在的位置
--]]
function ArtifactManager:GetListCardSelectCardIndex(cards ,  playerCardId )
    local index = 1
    if (not cards) then
        return index
    end
    playerCardId  =  checkint(playerCardId )
    for i, v in pairs(cards) do
        if checkint(v.id) == playerCardId  then
            index = i
        end
    end
    return index
end

--[[
    获取到 不同职业所用的天赋树配表
--]]
function ArtifactManager:GetTalentPosConfigByCareer(career)
    local parseConfig = self:GetConfigParse()
    if checkint(career) == CARD_TYPE.DEFEND then
        return self:GetConfigDataByName(parseConfig.TYPE.DAMAGE_COORDINATE)
    elseif checkint(career) == CARD_TYPE.ATTACK then
        return self:GetConfigDataByName(parseConfig.TYPE.COORDINATE_MELEEDPS)
    elseif checkint(career) == CARD_TYPE.ARROW then
        return self:GetConfigDataByName(parseConfig.TYPE.COORDINATE_REMOTEDPS)
    elseif checkint(career) == CARD_TYPE.HEART then
        return self:GetConfigDataByName(parseConfig.TYPE.ASSISTANT_COORDINATE)
    end
end
function ArtifactManager:GetConfigDataByName(name  )
    ---@type ArtifactConfigParser
    local parseConfig = self:GetConfigParse()
    local configData  = parseConfig:GetVoById(name)
    return configData
end

--[[
    获取到天赋技能表
--]]
function ArtifactManager:GetTalentIdPointConfigByCardId(cardId)
    if not  cardId then
        return
    end
    local parseConfig = self:GetConfigParse()
    local talentPointConfig =  self:GetConfigDataByName(parseConfig.TYPE.TALENT_POINT)
    return ( talentPointConfig[tostring(cardId)] or {})
end
--[[
    获取到神器解锁的消耗数据
    --@params cardId
--]]
function ArtifactManager:GetArtifactConsumeByCardId(cardId)
    local cardConfig = CommonUtils.GetConfigAllMess('card','card')
    local cardOneConfig = cardConfig[tostring(cardId)] or {}
    if next(cardOneConfig) == nil then
        return  { goodsId = checkint(cardOneConfig.artifactCostId) , num = 100 }
    else
        local num = checkint(cardOneConfig.artifactCost)
        return { goodsId = checkint(cardOneConfig.artifactCostId) , num = num }
    end
end
--[[
    获取到神器碎片试炼的关卡
--]]
function ArtifactManager:GetArtifactFragmentQuestId(cardId)
    local cardConfig = CommonUtils.GetConfigAllMess('card','card')
    local cardOneConfig = cardConfig[tostring(cardId)]
    if not  cardOneConfig then
        return 0
    else
        local questId = checkint(cardOneConfig.artifactQuestId)
        return questId
    end
end
--[[
    判断天赋升级所需要的碎片
    --@params cardData   卡牌的数据
    --@params talentId 天赋的id
--]]
function ArtifactManager:GetUpgradeNeedArtifactFragmentConsume(cardData ,talentId)
    local talents = cardData.artifactTalent
    local parseConfig = self:GetConfigParse()
    local talentOnePointConfig = self:GetTalentIdPointConfigByCardId(cardData.cardId)
    local num = 0
    local data = nil
    local talentIdStyle = checkint(talentOnePointConfig[tostring(talentId)].style)
    local artifactFragmentId = CommonUtils.GetArtifactFragmentsIdByCardId(cardData.cardId)
    local consumeConfig   =  nil
    if talentIdStyle == TALENT_TYPE.SMALL_TALENT then
        consumeConfig = self:GetConfigDataByName(parseConfig.TYPE.TALENT_CONSUME)
        for i, v in pairs(talents) do
            data = talentOnePointConfig[tostring(i)]
            if data then
                if checkint(data.style) == TALENT_TYPE.SMALL_TALENT  then
                    num = checkint(v.level)  + num
                end
            end
        end
        local   artifactFragmentNum = consumeConfig[tostring(num+1)].artifactFragment
        local comsumeData = {goodsId = artifactFragmentId , num = artifactFragmentNum }
        return comsumeData
    elseif talentIdStyle == TALENT_TYPE.GEM_TANLENT then
        consumeConfig = self:GetConfigDataByName(parseConfig.TYPE.GEM_STONE_CONSUME)
        local talentOnePointConfig = self:GetTalentIdPointConfigByCardId(cardData.cardId)
        local gemsTalentTable = {}
        for i, v in pairs(talentOnePointConfig) do
            if checkint(v.style) == TALENT_TYPE.GEM_TANLENT then
                gemsTalentTable[#gemsTalentTable+1] = v.talentId
            end
        end
        table.sort(gemsTalentTable , function(a, b )
            if checkint(a) >= checkint( b)  then
                return false
            end
            return true
        end)
        local sortIndex = 0
        for i = 1, #gemsTalentTable do
            if checkint(gemsTalentTable[i] ) == checkint(talentId)  then
                sortIndex = i
            end
        end
        local   artifactFragmentNum = consumeConfig[tostring(sortIndex) ].artifactFragment
        local comsumeData = {goodsId = artifactFragmentId , num = artifactFragmentNum }
        return comsumeData
    end
end

--[[
    根据cardId 获取到神器的名称
--]]
function ArtifactManager:GetArtifactName(cardId)
    local cardConfig = CommonUtils.GetConfigAllMess('card','card')
    local cardOneConfig = cardConfig[tostring(cardId)] or {}
    local artifactName = cardOneConfig.artifactName or ""
    return artifactName
end
--[[
    检测天赋是否允许升级 0 、 不可以升级 1、可以升级 、 2 、 已经满级
--]]
function ArtifactManager:CheckTalentIdAllowUpgradeId( cardData , talentId)
    cardData = cardData or {}
    local talents = cardData.artifactTalent or {}
    local talentOnePointConfig = self:GetTalentIdPointConfigByCardId(cardData.cardId)
    local talentIdData = talentOnePointConfig[tostring(talentId)] or {}
    if talents[tostring(talentId)]  and checkint(talents[tostring(talentId)].level) > 0  then
        if checkint(talentIdData.level) > checkint(talents[tostring(talentId)].level)  then
            return 1
        else
            return 2
        end
    else
        local data = nil
        local level = 0
        local beforeTalentId = talentIdData.beforeTalentId or {}
        for i = 1, #beforeTalentId do
            if checkint(beforeTalentId[i]) > 0   then -- 前置天赋的id 大于零
                data  =   talentOnePointConfig[tostring(beforeTalentId[i])]
                if talents[tostring(beforeTalentId[i])] then
                    if checkint(data.level) == 0  and  checkint(data.style) ==TALENT_TYPE.GEM_TANLENT  then
                        level  =1
                    else
                        level  =checkint( data.level)
                    end
                    if checkint(talents[tostring(beforeTalentId[i])].level) == level  then
                        return 1
                    end
                end
            else
                return 1
            end
        end
    end
    return 0
end

--[[
    根据宝石goodsId 获取到已经镶嵌的数量
--]]
function ArtifactManager:GetEquipGemNumByGoodsId(goodsId)
    return app.gameMgr:GetEquipGemNumByGoodsId(goodsId)
end
--[[
    获取到宝石的数据
--]]
function ArtifactManager:GetGemStoneData()
    local stoneData = {}
    local startId = 280001
    local endId   = 289999
    local goodsId =  0
    for i, v in pairs(app.gameMgr:GetUserInfo().backpack) do
        goodsId =checkint(v.goodsId)
        if  goodsId >= startId and goodsId <= endId   then
            stoneData[tostring(goodsId)] = v
        end
    end
    return stoneData
end
--[[
    删选出来不同的颜色
--]]
function ArtifactManager:GetGemStoneByColor(color )
    local stoneData = self:GetGemStoneData()
    local sameColor = {}
    local gemstone = self:GetConfigDataByName(self:GetConfigParse().TYPE.GEM_STONE)
    for k,v in pairs(stoneData) do
        if tostring(gemstone[k].color) == tostring(color) then
            sameColor[tostring(k)] = v.amount
        end
    end
    return sameColor
end
function ArtifactManager:ResetArtifactTalent(playerCardId , artifactTalent)
    local cardData = app.gameMgr:GetCardDataById(playerCardId)
    cardData.artifactTalent  = {}
    for i, v in pairs(artifactTalent) do
        if checkint(v.gemstoneId) > 0   then
            local data = {
                talentId = checkint( i),
                gemstoneId = checkint(v.gemstoneId)  ,
                playerCardId =  playerCardId
            }
            app.gameMgr:UpdateGemsTalentData(data , 0 )
        end
    end
end
--[[

--]]
function ArtifactManager:UpdateGemStoneId(requestData)
    local  playerCardId = requestData.playerCardId
    if checkint(playerCardId) > 0  then
        local operation = checkint(requestData.operation)
        local talentId = requestData.talentId
        if operation == 1  then --卸下宝石
            local cardData = app.gameMgr:GetCardDataById(playerCardId)
            -- 神器天赋是否存在
            local goodsId = cardData.artifactTalent[tostring(talentId)].gemstoneId
            cardData.artifactTalent[tostring(talentId)].gemstoneId = nil
            local data = {
                talentId = checkint( requestData.talentId),
                gemstoneId = goodsId ,
                playerCardId =  requestData.playerCardId
            }
            app.gameMgr:UpdateGemsTalentData(data , 0 )
        elseif operation == 2 then --装备宝石
            -- 从其他卡牌身上替换
            local cardData = app.gameMgr:GetCardDataById(playerCardId)
            if cardData.artifactTalent[tostring(talentId)].gemstoneId then
                local data = {
                    talentId = talentId ,
                    gemstoneId = cardData.artifactTalent[tostring(talentId)].gemstoneId ,
                    playerCardId =  requestData.playerCardId
                }
                app.gameMgr:UpdateGemsTalentData(data , 0 )
            end
            cardData.artifactTalent[tostring(talentId)].gemstoneId = requestData.gemstoneId
            local data = {
                talentId = talentId ,
                gemstoneId =  requestData.gemstoneId ,
                playerCardId =  requestData.playerCardId
            }
            app.gameMgr:UpdateGemsTalentData(data , 1 )
        elseif operation == 3 then
            if checkint(requestData.ownerPlayerCardId) > 0  and checkint(requestData.ownerTalentId) > 0   then
                -- 如果是替换操作
                local ownertalentId = checkint( requestData.ownerTalentId)
                local  ownerCardData = app.gameMgr:GetCardDataById(requestData.ownerPlayerCardId)
                local goodsId = ownerCardData.artifactTalent[tostring(ownertalentId)].gemstoneId
                ownerCardData.artifactTalent[tostring(ownertalentId)].gemstoneId = nil
                local data = {
                    talentId = ownertalentId,
                    gemstoneId = goodsId ,
                    playerCardId =  requestData.ownerPlayerCardId
                }
                app.gameMgr:UpdateGemsTalentData(data , 0 )
            end
            local cardData = app.gameMgr:GetCardDataById(requestData.playerCardId)
            -- 从自己的身上删除
            if  checkint(cardData.artifactTalent[tostring(talentId) ].gemstoneId) > 0      then

                local goodsId = cardData.artifactTalent[tostring(talentId)].gemstoneId
                cardData.artifactTalent[tostring(talentId)].gemstoneId = nil
                local data = {
                    talentId = talentId ,
                    gemstoneId = goodsId ,
                    playerCardId =  requestData.playerCardId
                }
                app.gameMgr:UpdateGemsTalentData(data , 0 )
            end
            cardData.artifactTalent[tostring(talentId)].gemstoneId = requestData.gemstoneId
            local data = {
                talentId = talentId ,
                gemstoneId =  requestData.gemstoneId ,
                playerCardId =  requestData.playerCardId
            }
            app.gameMgr:UpdateGemsTalentData(data , 1 )
        end
    end
end
--[[
    获取消耗总的总的神器碎片点
    卡牌的数据
--]]
function ArtifactManager:GetTalentAllConsume(cardData)
    local talents = cardData.artifactTalent or {}
    if table.nums(talents)  ==  0 then
        return 0
    end
    local parseConfig = self:GetConfigParse()
    local talentOnePointConfig = self:GetTalentIdPointConfigByCardId(cardData.cardId)
    local gemTalentNum  = 0 -- 计算总的宝石解锁消耗的次数
    local smallTalentNum = 0 -- 计算小天赋宝石消耗的次数
    local talentConsumeConfig = self:GetConfigDataByName(parseConfig.TYPE.TALENT_CONSUME)
    local gemConsumeConfig = self:GetConfigDataByName(parseConfig.TYPE.GEM_STONE_CONSUME)
    local data = nil
    for i, v in pairs(talents) do
        data = talentOnePointConfig[tostring(i)]
        if data then
            if checkint(data.style) == TALENT_TYPE.GEM_TANLENT  then
                gemTalentNum = gemTalentNum + checkint(v.level)
            elseif checkint(data.style) == TALENT_TYPE.SMALL_TALENT  then
                smallTalentNum = smallTalentNum + checkint(v.level)
            end
        end
    end
    local artifactFragmentCount = 0
    for i = 1, gemTalentNum do
        artifactFragmentCount = checkint(gemConsumeConfig[tostring(i)].artifactFragment) +  artifactFragmentCount
    end
    for i = 1, smallTalentNum do
        artifactFragmentCount = checkint(talentConsumeConfig[tostring(i)].artifactFragment) +  artifactFragmentCount
    end
    return artifactFragmentCount
end
function ArtifactManager:GetStyledByCardTalent(cardId, talentId)
    local talentConfig = ArtifactUtils.GetCardAllTalentConfig(cardId)
    local talentOneConf = talentConfig[tostring(talentId)]
    if talentOneConf.style then return checkint(talentOneConf.style) end
    return TALENT_TYPE.SMALL_TALENT
end
--[[
    更新天赋的等级
--]]
function ArtifactManager:UpdateTalentLevel(playrCardId , talentId ,talentLevel )
    local cardData = app.gameMgr:GetCardDataById(playrCardId) or {}
    if not  cardData.artifactTalent then
        cardData.artifactTalent = {}
    end
    if not  cardData.artifactTalent[tostring(talentId)] then
        cardData.artifactTalent[tostring(talentId)] = {}
    end
    cardData.artifactTalent[tostring(talentId)].level = talentLevel
    cardData.artifactTalent[tostring(talentId)].talentId = talentId
    cardData.artifactTalent[tostring(talentId)].type = self:GetStyledByCardTalent(cardData.cardId ,talentId)
end
function ArtifactManager:GetGemStageByLevel(level)
    level = checkint(level)
    if level <4 then
        return GEM_STAGE.LOWER
    elseif level >=4 and level <7 then
        return GEM_STAGE.MIDDLE
    elseif level >=7 and level <= 9 then
        return GEM_STAGE.HIGH
    elseif level >=10 then
        return GEM_STAGE.VERY_HIGH
    end
    return GEM_STAGE.LOWER
end
--[[
   根据宝石的技能Id 获取到天赋的技能叙述
--]]
function ArtifactManager:GetArtifactGemSkillDescrBySkillId(skillId)
    return ArtifactUtils.GetArtifactGemSkillDescrBySkillId(skillId)
end
--[[
    获取到宝石天赋的技能组
    ---@params level 宝石的等级
    ---@params cardId 卡牌CardId
    ---@params talentId 天赋Id
    -- 返回格式为宝石的形状 和宝石的叙述
    @return descrArray  key 宝石的形状 value 对应天赋等级的叙述
--]]
function ArtifactManager:GetArtifactGemSkillDescrArray(cardId,talentId ,level )
    local descrArray = {
        ["1"] = "" ,
        ["2"] = "" ,
        ["3"] = ""
    }
    local talentOnePointConfig = self:GetTalentIdPointConfigByCardId(cardId)
    local talentOneData = talentOnePointConfig[tostring(talentId)]
    if talentOneData then
        local style = checkint(talentOneData.style)
        if checkint(style ) == TALENT_TYPE.GEM_TANLENT then
            local parseConfig = self:GetConfigParse()
            local gemStoneSkillGroupConfig = self:GetConfigDataByName(parseConfig.TYPE.GEM_STONE_SKILL_GROUP)
            local getSkill = talentOneData.getSkill
            local gemstoneShape = talentOneData.gemstoneShape
            for i, v in pairs(gemstoneShape) do
               local groupSkill = getSkill[i]
                if groupSkill then
                    local gemSkillData = gemStoneSkillGroupConfig[tostring(groupSkill)] or {}
                    local gemSkillId = gemSkillData[tostring(level)]
                    descrArray[tostring(i)] = self:GetArtifactGemSkillDescrBySkillId(gemSkillId)
                end
            end
        end

    end
    return descrArray
end
--[[
    获取神器的天赋技能的叙
    ---@params cardId   卡牌等级
    ---@params talentId 天赋id
    ---@params level 天赋等级
    ---@params goodsId 道具
    ---@return descr string 描述
--]]
function ArtifactManager:GetArtifactTalentSkillDescr(cardId, talentId, level, goodsId)
    local descr = ''
    local talentConfig = ArtifactManager.GetCardTalentConfig(cardId, talentId)

    level = checkint(level or 0)

    if talentConfig then
        local talentStyle = checkint(talentConfig.style)

        if TALENT_TYPE.SMALL_TALENT == talentStyle then

            descr = ArtifactManager.GetSmallTalentDescr(cardId, talentId, level)

        elseif TALENT_TYPE.GEM_TANLENT == talentStyle then

            

        end
    else
        descr = 'cannot find card talent config -> cardId : ' .. tostring(cardId) .. ' , talentId : ' .. tostring(talentId)
    end

    return descr
end
--[[
　　---@Description: 根据神器的天赋技能id 获取天赋的叙述
　　---@param talentSkillId 天赋的技能id
　　---@param key  叙述的
　  ---@return
　　---@author  xingweihao
　　---@date  2018/8/6 1:55 PM
--]]
function ArtifactManager:GetArtifactTalentSkillDescrBySkillId(talentSkillId ,key )
    key = key or "descr"
    local parseConfig = self:GetConfigParse()
    local talentSkillConfig = self:GetConfigDataByName(parseConfig.TYPE.TALENT_SKILL)
    local descr = ""
    if talentSkillConfig[tostring(talentSkillId)]  then
        descr = talentSkillConfig[tostring(talentSkillId)][tostring(key)]
    end
    return descr
end
--[[
    获取宝石镶嵌的时候 userinfo gems 的数据
--]]
function ArtifactManager:GetUserInfoGemsData()
    local gems = app.gameMgr:GetUserInfo().gems
    if not  gems then
        app.gameMgr:GetUserInfo().gems = {}
    end
    return gems
end
--[[
    获得所有相同颜色的已镶嵌和未镶嵌宝石数据
--]]
function ArtifactManager:GetGemImbedStatusByColor( color, isIncludeImbeded )
    local gemstone = self:GetConfigDataByName(self.parseConfig.TYPE.GEM_STONE)
    local sameColorGemData = self:GetGemStoneByColor(color)
    local allGemData = {}
    local imbededGemData = self:GetUserInfoGemsData()
    for gemId, amount in pairs(sameColorGemData) do
        local gemData = gemstone[tostring(gemId)]
        local imbededCnt = 0
        if imbededGemData[gemId] then
            for playerCardId,v in pairs(imbededGemData[gemId]) do
                imbededCnt = imbededCnt + table.nums(v)
                if isIncludeImbeded then -- 包含已经镶嵌的宝石数据
                    for _,talentId in pairs(v) do
                        local goodData = CommonUtils.GetConfig('goods', 'goods', gemId) or {}
                        table.insert(allGemData, {goodsId = gemId, quality = goodData.quality, amount = 1, grade = checkint(gemData.grade), type = checkint(gemData.type), owner = {playerCardId = tostring(playerCardId), talentId = tostring(talentId)}})
                    end
                end
            end
        end
        if amount > imbededCnt then
            local goodData = CommonUtils.GetConfig('goods', 'goods', gemId) or {}
            table.insert( allGemData, {goodsId = gemId, quality = goodData.quality, amount = amount - imbededCnt, grade = checkint(gemData.grade), type = checkint(gemData.type)} )
        end
    end
    return allGemData
end
--[[
    获取宝石对应spine动画名字
--]]
function ArtifactManager:GetSpineNameById(gemId)
    local gemData = self:GetGemConfig(gemId)
    local level = self:GetGemStageByLevel(checkint(gemData.grade))
    local type = gemData.type
    return string.format('%02d_%02d', checkint(type), checkint(level))
end
function ArtifactManager:GetGemConfig(gemId)
    local gemstone = self:GetConfigDataByName(self.parseConfig.TYPE.GEM_STONE)
    local gemData = gemstone[tostring(gemId)] or {}
    return  gemData
end
--[[
    获取镶嵌幻晶石圆圈的动画
--]]
function ArtifactManager:GetCircleSpineByName(gemId)
    if checkint(gemId) > 0  then
        local gemData = self:GetGemConfig(gemId)
        local level = self:GetGemStageByLevel(checkint(gemData.grade)) or 1
        return string.format('play%d', checkint(level))
    else
        return 'idle'
    end

end
function ArtifactManager:GetCircleSpineNameByPlayerCardId(playerCardId , talentId)
    local cardData = app.gameMgr:GetCardDataById(playerCardId)
    local artifactTalent = cardData.artifactTalent or {}
    local level = artifactTalent[tostring(talentId)] and checkint(artifactTalent[tostring(talentId)].level) or 0
    if level > 0 then
        local gemId = artifactTalent[tostring(talentId)] and checkint(artifactTalent[tostring(talentId)].gemstoneId) or 0
        return self:GetCircleSpineByName(gemId)
    end
    return 'stop'
end
--[[
    由goodsId 获取到装备幻晶石的icon
--]]
function ArtifactManager:GetEquipGemIconByGemId(gemId)
    local gemstone = self:GetConfigDataByName(self.parseConfig.TYPE.GEM_STONE)
    local gemData = gemstone[tostring(gemId)]
    local color  = checkint(gemData.color)
    local level =checkint(gemData.grade)
    local path =  _res(string.format("arts/artifact/equipicon/diamond_icon_%02d_%02d",color , level ))
    if not  utils.isExistent(path)   then
        path =_res("arts/artifact/equipicon/diamond_icon_01_01")
    end
    return path
end
--[[
   --@params questId    关卡Id
   --@params times      挑战次数
   --@params questType  挑战类型
   根据挑战的类型获取到消耗值
--]]
function ArtifactManager:GetConsumedByQuestId(questId , times , questType)
    local questConfig = CommonUtils.GetQuestConf(questId)
    local BATTLE_TYPE = {
        COMMON_TYPE = 1 ,  -- 普通模式
        UNIVERSAL_TYPE = 2 -- 万能门票道具消耗
    }
    local data = {}
    if questType == BATTLE_TYPE.COMMON_TYPE then
        data = clone(questConfig.consumeGoods)
        data[1].num = -checkint(data[1].num)  * times
    else
        local comsumeData = {}
        local goodsId = checkint( questConfig.consumeTicket)
        if goodsId > 0 then
            comsumeData.goodsId = goodsId
            comsumeData.num = -checkint(questConfig.consumeTicketNum) * times
            data[#data+1] = comsumeData
        end
    end
    return data
end
--[[
    检测所有宝石天赋是否装备
--]]
function ArtifactManager:CheckGemTalentIsEquipByPlayerCardId(playerCardId)
    local cardData = app.gameMgr:GetCardDataById(playerCardId)
    local talentPointConfig =  self:GetTalentIdPointConfigByCardId(cardData.cardId)
    local isFull = true
    local artifactTalent = cardData.artifactTalent or {}
    for i, v in pairs(talentPointConfig ) do
        if checkint(v.style) ==TALENT_TYPE.GEM_TANLENT   then
            local goodsId = artifactTalent[tostring(i)] and checkint(artifactTalent[tostring(i)].gemstoneId)  or  0
            if goodsId ==  0 then
                isFull = false
                break
            end
        end
    end
    return isFull
end
--[[
    检测所有宝石天赋是否装备
--]]
function ArtifactManager:CheckGemTalentIsEquipByCardData(cardData)
    local talentPointConfig =  self:GetTalentIdPointConfigByCardId(cardData.cardId)
    local isFull = true
    local artifactTalent = cardData.artifactTalent or {}
    for i, v in pairs(talentPointConfig ) do
        if checkint(v.style) ==TALENT_TYPE.GEM_TANLENT   then
            local goodsId = artifactTalent[tostring(i)] and checkint(artifactTalent[tostring(i)].gemstoneId)  or  0
            if goodsId ==  0 then
                isFull = false
                break
            end
        end
    end
    return isFull
end

function ArtifactManager:GoToBattleReadyView(questId ,fromMediator , backMediator , playerCardId  )
    local cardData = app.gameMgr:GetCardDataById(playerCardId)
    local battleReadyData = BattleReadyConstructorStruct.New(
        2,
        app.gameMgr:GetUserInfo().localCurrentBattleTeamId,
        app.gameMgr:GetUserInfo().localCurrentEquipedMagicFoodId,
        questId,
        CommonUtils.GetQuestBattleByQuestId(questId),
        nil,
        POST.ARTIFACT_QUESTAT.cmdName,
        { questId = questId ,playerCardId = playerCardId},
        POST.ARTIFACT_QUESTAT.sglName,
        POST.ARTIFACT_QUESTGRADE.cmdName,
        { questId = questId  ,playerCardId = playerCardId },
        POST.ARTIFACT_QUESTGRADE.sglName,
        fromMediator,
        backMediator
    )
    ---@type UIManager
    local chooseView = require("Game.views.artifact.ArtifactBattleReadyView").new(battleReadyData)
    chooseView:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(chooseView)
end
--[[
    获取神器能量的星级
    ---@params questId 关卡的id
--]]
function ArtifactManager:GetArtifactQuestStarByQuestId(questId)
    local questOneData = self:GetArtifactQuestByQuestId(questId)
    local star = checkint(questOneData.grade)
    return star
end
function ArtifactManager:UpdateArtifactQuest(data)
    app.gameMgr:UpdateArtifactQuest(data)
end
function ArtifactManager:GetArtifactQuestByQuestId(questId)
    return app.gameMgr:GetArtifactQuestByQuestId(questId) or {}
end
--[[
    返回升级所有的核心天赋点
--]]
function ArtifactManager:GetCardArtifactAllPoint(cardId)
    local talentOnePointConfig = self:GetTalentIdPointConfigByCardId(cardId)
    local allPoint = 0
    for i, v in pairs(talentOnePointConfig) do
        allPoint = checkint(v.level) + allPoint
    end
    return allPoint
end

--[[
    返回升级所有的核心天赋点
--]]
function ArtifactManager:GetCardArtifactAllActivationPoint(playerCardId)
    local cardData = app.gameMgr:GetCardDataById(playerCardId)
    local artifactTalent = cardData.artifactTalent or {}
    local activationPoint = 0
    for i, v in pairs(artifactTalent) do
        activationPoint = checkint(v.level) + activationPoint
    end
    return activationPoint
end

--[[
    返回升级所有的核心天赋点
--]]
function ArtifactManager:GetCardArtifactAllActivaionPointCardData(cardData)
    local artifactTalent = cardData.artifactTalent or {}
    local activationPoint = 0
    for i, v in pairs(artifactTalent) do
        activationPoint = checkint(v.level) + activationPoint
    end
    return activationPoint
end
--[[
    返回所有的大核心天赋数量
--]]
function ArtifactManager:GetCardArtifactAllBigActivaionPointCardData(cardData)
    local artifactTalent = cardData.artifactTalent or {}
    local activationPoint = 0
    for i, v in pairs(artifactTalent) do
        if checkint(v.type) == 2 then
            activationPoint = activationPoint + 1
        end
    end
    return activationPoint
end
--[[
    获取到天赋已经解锁的技能
    --@params playerCardId  卡牌的唯一ID
--]]
function ArtifactManager:GetArtifactTalentUnLockSkillId(playerCardId)
    local cardData = app.gameMgr:GetCardDataById(playerCardId)
    return self:GetArtifactTalentUnLockSkillIdByCardData(cardData)
end

function ArtifactManager:GetArtifactTalentUnLockSkillIdByCardData(cardData)
    local artifactTalent = cardData.artifactTalent or  {}
    local talentOnePointConfig = self:GetTalentIdPointConfigByCardId(cardData.cardId)
    local artifactTalentSkill = {}
    local style = 1
    for i, v in pairs(artifactTalent) do
        style = checkint(talentOnePointConfig[tostring(i)].style)
        if style == TALENT_TYPE.SMALL_TALENT then
            --end
            local getSkill = talentOnePointConfig[tostring(i)].getSkill
            if checkint(v.level) > 0 and getSkill and  table.nums(getSkill) > 0 then

                local skillId = getSkill[checkint(v.level)]
                if CardUtils.IsArtifactTalentSkillBySkillId(skillId) then
                    artifactTalentSkill[#artifactTalentSkill+1] = skillId
                end
            end
        end
    end
    return artifactTalentSkill
end

---------------------------------------------------
-- 配表转换 begin --
---------------------------------------------------
--[[
获取天赋点被动增加的卡牌属性
@params cardId int 卡牌id
@params talentId int 天赋点id
@params level 天赋等级
@params gemstoneId int 插槽宝石id
@return ptype, pvalue ObjectProperty, number 属性类型 属性值
--]]
function ArtifactManager.GetArtifactTalentInnateProperty(cardId, talentId, level, gemstoneId)
    return ArtifactUtils.GetArtifactTalentInnateProperty(cardId, talentId, level, gemstoneId)
end
--[[
获取天赋点激活的技能效果
@params cardId int 卡牌id
@params talentId int 天赋点id
@params level 天赋等级
@params gemstoneId int 插槽宝石id
@return skillId int 天赋点激活的技能id
--]]
function ArtifactManager.GetArtifactTalentInnateSkill(cardId, talentId, level, gemstoneId)
    return ArtifactUtils.GetArtifactTalentInnateSkill(cardId, talentId, level, gemstoneId)
end
--[[
获取当前对应的是天赋点上第几条效果
@params cardId int 卡牌id
@params talentId int 天赋点id
@params level 天赋等级
@params gemstoneId int 插槽宝石id
@return index int 效果序号
--]]
function ArtifactManager.GetArtifactTalentEffectIndex(cardId, talentId, level, gemstoneId)
    return ArtifactUtils.GetArtifactTalentEffectIndex(cardId, talentId, level, gemstoneId)
end
--[[
根据技能组id和宝石id获取技能id
@params skillGroupId int 技能组id
@params gemstoneId int 宝石id
@return skillId int 技能id
--]]
function ArtifactManager.GetGemstoneActiveTalentSkillId(skillGroupId, gemstoneId)
    return ArtifactUtils.GetGemstoneActiveTalentSkillId(skillGroupId, gemstoneId)
end
--[[
根据宝石id获取宝石的最终属性加成
@params gemstoneId int 宝石id
@return addition list 属性加成list
--]]
function ArtifactManager.GetGemstonePropertyAddition(gemstoneId)
    return ArtifactUtils.GetGemstonePropertyAddition(gemstoneId)
end
--[[
获取卡牌宝石的附加属性点
@params propertyData  （修正属性 + 堕神属性 ）
@return map {
    [ObjectProperty] = number,
    [ObjectProperty] = number,
    [ObjectProperty] = number,
    ...
}
--]]
function ArtifactManager.GetAllGemsStonePropertyAddition(cardData ,propertyData )
    local artifactTalent = cardData.artifactTalent
    local addition = {}
    local additionPro = {}
    if artifactTalent  then
        for talentId  , talentData in pairs(artifactTalent) do
            if  checkint(talentData.gemstoneId) > 0  then
                local data = ArtifactManager.GetGemstonePropertyAddition(talentData.gemstoneId)
                for k , v in pairs(data) do
                    if not  addition[tostring(v.ptype)] then
                        addition[tostring(v.ptype)] = v
                    else
                        addition[tostring(v.ptype)].pvalueMulti = ( v.pvalueMulti  + addition[tostring(v.ptype)].pvalueMulti)
                    end
                end
            end
        end
        for k , v in pairs(addition) do
            additionPro[checkint(k)] =  checkint(tonumber(v.pvalueMulti)   * checkint(propertyData[checkint(k)]))
        end
    end
    return additionPro
end

--[[
根据卡牌id获取所有天赋的属性加成集合
@params playerCardId int 卡牌数据库id
@return map {
    [ObjectProperty] = number,
    [ObjectProperty] = number,
    [ObjectProperty] = number,
    ...
}
--]]
function ArtifactManager.GetArtifactTalentAllFixedPByPlayerCardId(playerCardId)
    local cardData = app.gameMgr:GetCardDataById(playerCardId)
    return ArtifactManager.GetArtifactTalentAllFixedPByCardData(cardData)
end
--[[
根据卡牌通用信息获取所有天赋的属性加成集合
@params cardData table 卡片信息
@return map {
    [ObjectProperty] = number,
    [ObjectProperty] = number,
    [ObjectProperty] = number,
    ...
}
--]]
function ArtifactManager.GetArtifactTalentAllFixedPByCardData(cardData)
    if nil ~= cardData and 0 ~= checkint(cardData.cardId) and nil ~= cardData.artifactTalent then
        return ArtifactManager.GetArtifactTalentAllFixedPByTalentData(checkint(cardData.cardId), cardData.artifactTalent)
    else
        local result = {}
        -- 初始化一次数据
        for k,v in pairs(CardUtils.GetCardInnatePConfig()) do
            result[tostring(v)] = 0
        end
        return result
    end
end
--[[
根据天赋信息获取天赋的固有属性加成
@params cardId int 卡牌id
@params talentData map 天赋信息
@return result map {
    [ObjectProperty] = number,
    [ObjectProperty] = number,
    [ObjectProperty] = number,
    ...
}
--]]
function ArtifactManager.GetArtifactTalentAllFixedPByTalentData(cardId, talentData)
    local result = {}
    -- 初始化一次数据
    for k,v in pairs(CardUtils.GetCardInnatePConfig()) do
        result[tostring(v)] = 0
    end

    for talentId, talentData in pairs(talentData) do
        if nil ~= talentData.talentId and 0 < checkint(talentData.level) then

            local ptype, pvalue = ArtifactManager.GetArtifactTalentInnateProperty(
                cardId,
                checkint(talentData.talentId),
                checkint(talentData.level),
                nil ~= talentData.gemstoneId and checkint(talentData.gemstoneId) or nil
            )

            if nil ~= ptype then
                result[tostring(ptype)] = result[tostring(ptype)] + pvalue
            end

        end
    end

    return result
end
---------------------------------------------------
-- 配表转换 end --
---------------------------------------------------

---------------------------------------------------
-- utils begin --
---------------------------------------------------
--[[
获取小天赋点的描述
@params cardId int 卡牌id
@params talentId int 天赋点id
@params level 天赋等级
@return descr string 描述
--]]
function ArtifactManager.GetSmallTalentDescr(cardId, talentId, level)
    local descr = ''

    local talentConfig = ArtifactManager.GetCardTalentConfig(cardId, talentId)
    if nil ~= talentConfig then

        local hasPropertyAddition = false
        ------------ 固有属性描述 ------------
        -- 当前属性
        local currentptype, currentpvalue = ArtifactManager.GetArtifactTalentInnateProperty(cardId, talentId, level, nil)
        if nil ~= currentptype then
            descr = descr .. ArtifactManager.GetTalentPropertyAdditionDescrPoint(currentptype, currentpvalue)
            hasPropertyAddition = true
        end

        -- 下一级属性
        local nextptype, nextpvalue = ArtifactManager.GetArtifactTalentInnateProperty(cardId, talentId, level + 1, nil)
        if nil ~= nextptype then
            descr = string.fmt(__('%1（下一级：%2）'), descr, ArtifactManager.GetTalentPropertyAdditionDescrPoint(nextptype, nextpvalue))
            hasPropertyAddition = true
        end
        ------------ 固有属性描述 ------------

        ------------ 附加技能描述 ------------
        local talentSkillId = ArtifactManager.GetArtifactTalentInnateSkill(cardId, talentId, level)
        if talentSkillId then
            if true == hasPropertyAddition then
                descr = descr .. '，'
            end
            descr = descr .. app.cardMgr.GetSkillDescr(talentSkillId, 1)
        end
       local nextTalentSkillId = ArtifactManager.GetArtifactTalentInnateSkill(cardId, talentId, level+1)
        if nextTalentSkillId then
            if true == hasPropertyAddition then
                descr = descr .. '，'
            end
            descr = string.fmt(__('%1（下一级：%2）'), descr, app.cardMgr.GetSkillDescr(nextTalentSkillId, 1))
        end
        ------------ 附加技能描述 ------------

    end

    return descr
end
--[[
根据属性类型和属性值获取属性加成(点数)的描述
@params ptype ObjectProperty 属性类型
@params pvalue number 属性值
@return str string 属性加成的描述
--]]
function ArtifactManager.GetTalentPropertyAdditionDescrPoint(ptype, pvalue)
    local str = ''
    if ptype then
        local ObjectPropertyInfo = ArtifactManager.GetObjectPropertyInfo()
        if pvalue > 0 then
            str = string.fmt(__("_name_ +_num_") ,{ _name_ = ObjectPropertyInfo[ptype].name ,_num_ = tostring(pvalue)} )
        elseif pvalue < 0 then
            str = string.fmt(__("_name_ -_num_") ,{ _name_ = ObjectPropertyInfo[ptype].name ,_num_ = tostring(pvalue)} )
        else
            return str
        end
    end
    return str
end
--[[
根据宝石id获取宝石的属性加成描述
@params gemstoneId int 宝石id
@return str string 描述
--]]
function ArtifactManager.GetGemstonePropertyAdditionDescr(gemstoneId)
    local str = ''
    local propertyAddition = ArtifactManager.GetGemstonePropertyAddition(gemstoneId)
    local ObjectPropertyInfo = ArtifactManager.GetObjectPropertyInfo()
    for i,v in ipairs(propertyAddition) do
        local ptype = v.ptype
        local pvalueMulti = v.pvalueMulti

        if 0 ~= checknumber(pvalueMulti) then
            -- 属性加成不为0时有效
            if 1 < i then
                str = str .. '，'
            end

            local signStr = '+'
            if 0 > pvalueMulti then
                signStr = '-'
            end
            local additionStr = string.fmt('%1%2%3%', ObjectPropertyInfo[ptype].name, signStr, pvalueMulti * 100)
            str = str .. additionStr
        end
    
    end

    return str
end
---------------------------------------------------
-- utils end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据卡牌id 天赋id 获取天赋的配表信息
@params cardId int 卡牌id
@params talentId int 天赋id
--]]
function ArtifactManager.GetCardTalentConfig(cardId, talentId)
    return ArtifactUtils.GetCardTalentConfig(cardId, talentId)
end
--[[
根据宝石id获取宝石的配表信息
@params gemstoneId int 宝石id
@return _ table 配表信息
--]]
function ArtifactManager.GetGemstoneConfig(gemstoneId)
    return ArtifactUtils.GetGemstoneConfig(gemstoneId)
end
--[[
获取宝石技能组的配表信息
@params skillGroupId int 技能组id
@return _ table 配表信息
--]]
function ArtifactManager.GetGemstoneSkillGroupConfig(skillGroupId)
    return CommonUtils.GetConfig('artifact', ArtifactConfigParser.TYPE.GEM_STONE_SKILL_GROUP, skillGroupId)
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return ArtifactManager
