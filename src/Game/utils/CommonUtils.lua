CommonUtils   = {}
require('battleEntry.BattleCommonUtils')

----------------------------------
-- config begin --
----------------------------------

--[[
获取指定配表的数据
@params jsonFileName string 对应要取的json文件名称
@params moduleName string 对应的模块名称，防止出现不同模块里面有同名的配表存在的问题
--]]
function CommonUtils.GetConfigAllMess(jsonFileName, moduleName)
    if moduleName == 'card' then
        moduleName = 'cards'
    end
    return app.dataMgr:GetConfigDataByFileName(jsonFileName, moduleName)
end

-- --==============================--
-- --desc:这个方法是用于设置UserDefault的值
-- --@param key 传入的键值
-- --@param value 传入值的类型
-- --==============================--
function CommonUtils.SetControlGameProterty(key, value)
    if CONTROL_GAME[key] then
        if type(value) == "boolean" then
            local mKey = app.gameMgr:GetUserInfo().playerId .. key
            cc.UserDefault:getInstance():setBoolForKey(mKey, value)

            if key == CONTROL_GAME.CONRROL_MUSIC then
                if value then
                    PlayBGMusic()
                else
                    StopBGMusic()
                end
            end
        end
        return
    end
    
    if CONTROL_GAME_VLUE[key] then
        if type(value) == "number" then
            local volueKey = app.gameMgr:GetUserInfo().playerId .. key
            cc.UserDefault:getInstance():setStringForKey(volueKey, tonumber(value))
            
            if CONTROL_GAME_VLUE[key] == CONTROL_GAME_VLUE.CONTREL_MUSIC_BIGORLITTLE then
                app.audioMgr:SetBGVolume(tonumber(value))
            elseif CONTROL_GAME_VLUE[key] == CONTROL_GAME_VLUE.CONTREL_GAME_EFFECT_BIGORLITTLE then
                app.audioMgr:SetAudioClipVolume(AUDIOS.UI.name, tonumber(value))
            end
        end
        return
    end
end


--==============================--
--desc: 获取游戏声音的相关设置
-- --@param key 传入的键值
-- --@param value 传入值的类型
--==============================--
function CommonUtils.GetControlGameProterty(key)
    if app.gameMgr:GetUserInfo().playerId then
        if CONTROL_GAME[key] then
            -- 添加玩家设置
            key = app.gameMgr:GetUserInfo().playerId .. key
            return cc.UserDefault:getInstance():getBoolForKey(key, true)
        end
        if CONTROL_GAME_VLUE[key] then
            key = app.gameMgr:GetUserInfo().playerId .. key
            return tonumber(cc.UserDefault:getInstance():getStringForKey(key, "1"))
        end
    end
    return nil
end


--[[
获取配表信息
@params mname string 模块名 -> 解析器前缀
@params tname string 配表名字
@params id int vo id
--]]
function CommonUtils.GetConfig(mname, tname, id)
    if tname == 'goods' then
        tname = CommonUtils.GetGoodsTableNameByGoodId(id)
        -- 寻找堕神配表
        -- if tname == 'pet' then
        -- 	mname = 'pet'
        -- end
    end
    if tname ~= 'error' then
        -- return app.dataMgr:GetParserByName(mname):GetVo(tname, id)
        -- 因为去掉了配表解析器的vo转义，所以配表有了 list 和 map 两种结构。优先索引列表，取不到再hashMap
        if mname == 'card' then
            mname = 'cards'
        end
        local parser = app.dataMgr:GetParserByName(mname)
        if parser and parser[tname] then
            return parser[tname](parser, tname, id)
        else
            local confFile = CommonUtils.GetConfigAllMess(tname, mname)
            return confFile[checkint(id)] or confFile[tostring(id)]
        end
    else
        return nil
    end
end

--[[
--获取不存在解析器的模块中的数据的逻辑
--@module 模块路径
--@tname 对应的配表名
--@id 数据id名称
--]]
function CommonUtils.GetConfigNoParser(module, tname, id)
    local datas = CommonUtils.GetConfigAllMess(tname, module)
    local t     = {}
    if datas then
        t = (datas[tostring(id)] or {})
    end
    return t
end

--[[
获取具体配表的名称
@params id int vo id
--]]
function CommonUtils.GetGoodsTableNameByGoodId( goodsId )
    local ttype = CommonUtils.GetGoodTypeById(goodsId)
    if ttype == GoodsType.TYPE_MONEY then
        return "money"
    else
        if ttype ~= '' then
            local typeRef = checktable(CommonUtils.GetConfig('goods', 'type', ttype)).ref
            return CommonUtils.GetGoodsTypeTrueRef(typeRef)
        else
            return 'error'
        end
    end
end


function CommonUtils.GetGoodsTypeTrueRef(typeRef)
    local ref = tostring(typeRef)
    local len = 5  -- is 'goods' len
    local pre = string.sub(ref, 0, len)
    local str = ''

    if pre == 'goods' then
        str = string.dcfirst(string.sub(ref, len + 1))
    else
        str = string.dcfirst(ref)
    end
    return str
end

--[[
    FIXME 已弃用，现在纯跳转
--]]
function CommonUtils.GetGoodTypeById(goodsId)
    return GoodsUtils.GetGoodsTypeById(goodsId)
end

--[[
    FIXME 已弃用，现在纯跳转
--]]
function CommonUtils.GetCacheProductNum(_id)
    return app.goodsMgr:GetGoodsAmountByGoodsId(_id)
end
--[[
    -- TODO ！！已经不用了，别往里面扩展了！！先保留一段时间，后面会删掉。
]]
--[[
function CommonUtils.GetCacheProductNum_(_id)
    local id = checkint(_id)
    if id == HP_ID then
        -- 体力
        return checkint(app.gameMgr:GetUserInfo().hp)
    elseif id == DIAMOND_ID then
        --幻晶石
        return checkint(app.gameMgr:GetUserInfo().diamond)
    elseif id == FREE_DIAMOND_ID then
        --免费幻晶石
        return checkint(app.gameMgr:GetUserInfo().freeDiamond)
    elseif id == PAID_DIAMOND_ID then
        --有偿幻晶石
        return checkint(app.gameMgr:GetUserInfo().paidDiamond)
    elseif id == GOLD_ID then
        --金币
        return checkint(app.gameMgr:GetUserInfo().gold)
    elseif id == COOK_ID then
        -- 厨力
        return checkint(app.gameMgr:GetUserInfo().cookingPoint)
    elseif id == EXP_ID then
        -- 主角经验
        return checkint(app.gameMgr:GetUserInfo().mainExp)
    elseif id == POPULARITY_ID then
        -- 知名度
		return checkint(app.gameMgr:GetUserInfo().popularity)
    elseif id == UNION_POINT_ID then
        -- 工会币
        return checkint(app.gameMgr:GetUserInfo().unionPoint)
    elseif id == UNION_CONTRIBUTION_POINT_ID then
        if nil ~= app.gameMgr:getUnionData() then
            return checkint(app.gameMgr:getUnionData().playerContributionPoint)
        end
        return 0
    elseif id == PVC_MEDAL_ID then
        return checkint(app.gameMgr:GetUserInfo().medal)
    elseif id == TIPPING_ID then
		return checkint(app.gameMgr:GetUserInfo().tip)
    elseif id == REPUTATION_ID then
        return checkint(app.gameMgr:GetUserInfo().commerceReputation)
    elseif id == ACTIVITY_QUEST_HP then
		return checkint(app.gameMgr:GetUserInfo().activityQuestHp)
    elseif id == app.summerActMgr:getTicketId() then
        local summerActivityMgr = app.summerActMgr
        local num = 0
        if summerActivityMgr then num = checkint(summerActivityMgr:GetActionPoint()) end
        return num
    elseif id == FISH_POPULARITY_ID then
        return checkint(app.gameMgr:GetUserInfo().fishPopularity)
    elseif id == MEMORY_CURRENCY_M_ID then
        return checkint(app.gameMgr:GetUserInfo().cardFragmentM)
    elseif id == MEMORY_CURRENCY_SP_ID then
        return checkint(app.gameMgr:GetUserInfo().cardFragmentSP)
    elseif id == app.anniversaryMgr:GetIncomeCurrencyID() then
        return checkint(app.gameMgr:GetUserInfo().voucherNum)
    elseif id == app.anniversaryMgr:GetRingGameID() then
        return checkint(app.gameMgr:GetUserInfo().voucherNum)
    elseif id == TTGAME_DEFINE.CURRENCY_ID then
        return checkint(app.gameMgr:GetUserInfo().battleCardPoint)
    elseif id == app.anniversary2019Mgr:GetSuppressHPId() then
        return checkint(app.anniversary2019Mgr:GetSuppressHP())
    elseif id == KOF_CURRENCY_ID then
        return checkint(app.gameMgr:GetUserInfo().kofPoint)
    elseif id == app.ptDungeonMgr:GetHPGoodsId() then
        local ptDungeonMgr = app.ptDungeonMgr
        local num = 0
        if ptDungeonMgr then num = checkint(ptDungeonMgr:GetHP()) end
        return num
    elseif id == app.murderMgr:GetMurderHpId() then
        local murderMgr = app.murderMgr
        local num = 0
        if murderMgr then num = checkint(murderMgr:GetHP()) end
        return num
    elseif id == app.anniversary2019Mgr:GetHPGoodsId() then
        local anniversary2019Mgr = app.anniversary2019Mgr
        local num = 0
        if anniversary2019Mgr then num = checkint(anniversary2019Mgr:GetHP()) end
        return num
    elseif id == FOOD.GOODS.DEFINE.WATER_BAR_CURRENCY_ID then  -- 水吧货币
        return app.waterBarMgr:getBarPoint()
    elseif id == FOOD.GOODS.DEFINE.WATER_BAR_POPULARITY_ID then  -- 水吧知名度
        return app.waterBarMgr:getBarPopularity()
    elseif id == app.springActivity20Mgr:GetBossTicketGoodsId() then
        return app.springActivity20Mgr:GetBossTicketAmount()
    elseif app.activityHpMgr:HasHpData(id) then
        return app.activityHpMgr:GetHpAmountByHpGoodsId(id) or 0
    else
        local gType = CommonUtils.GetGoodTypeById(id)
        --判断类型
        if gType == GoodsType.TYPE_CARD then
            --卡牌
            return 1

        elseif gType == GoodsType.TYPE_PET then
            --堕神
            local num = 0
            for i, v in pairs(app.gameMgr.userInfo.pets) do
                if checkint(v.petId) == id then
                    num = num + 1
                end
            end
            return num

        elseif gType == GoodsType.TYPE_WATERBAR_MATERIALS then -- 水吧材料
            return app.waterBarMgr:getMaterialNum(id)
        elseif gType == GoodsType.TYPE_WATERBAR_DRINKS then -- 水吧饮品
            return app.waterBarMgr:getDrinkNum(id)

        else
            --其他道具相关的逻辑
            local amount = 0
            for i,v in ipairs(app.gameMgr:GetUserInfo().backpack) do
                if checkint(v.goodsId) == id then
                    amount = checkint(v.amount)
                    break
                end
            end
            return amount
        end
    end
end
]]


--[[

--]]
function CommonUtils.GetSeverIntervalTextByTime(currentTime , lastTime)
    local timeData =  string.formattedTime(currentTime - lastTime)
    local str = ""
    if checkint(timeData.h) > 0 then
        local day  = math.floor(timeData.h/24)
        local hours = timeData.h%24
        if day > 0 then
            str = string.format(__('%s天') ,day )
        end
        if hours > 0 then
            str = string.format(__('%s%s小时') ,str,hours )
        end
    elseif checkint(timeData.m) > 0  then
        str = string.format(__('%s分钟') ,timeData.m )
    elseif checkint(timeData.s) > 0  then
        str = string.format(__('%s秒') ,timeData. s)
    end
    return str
end

--[[
    FIXME 已弃用，现在纯跳转
]]
function CommonUtils.GetCacheProductName( _goodsId )
    return GoodsUtils.GetGoodsNameById(_goodsId)
end


--[[
修正立绘展示位置
--]]
function CommonUtils.FixAvatarLocation(cardView, roleId, coordinateType)
    local cardDrawName = ''
    local goodsType = CommonUtils.GetGoodTypeById(roleId)
    if goodsType == GoodsType.TYPE_CARD_SKIN then
        cardDrawName = CardUtils.GetCardDrawNameBySkinId(roleId)
    else
        cardDrawName = CardUtils.GetCardDrawNameByCardId(roleId)
    end
    CommonUtils.FixAvatarLocationAtDrawId(cardView, cardDrawName, coordinateType)
end
function CommonUtils.FixAvatarLocationAtDrawId(cardView, cardDrawName, coordinateType)
    if not cardView then return end
    local coordinateType = coordinateType or COORDINATE_TYPE_CAPSULE

    -- 立绘坐标配表
    local cardLocationDef = nil
    local defaultLocation = {x = 0, y = 0, scale = 50, rotate = 0}
	local locationConf    = CommonUtils.GetConfig('cards', 'coordinate', cardDrawName)
    -- 1是主界面，2是编队， 3是头像调用逻辑
	if nil == locationConf or not locationConf[coordinateType] then
        print('\n**************\n', '立绘坐标信息未找到', cardDrawName, '\n**************\n')
        cardLocationDef = defaultLocation
    else
        cardLocationDef = locationConf[coordinateType]
    end

    local designSize = cc.size(1334, 750)
    local winSize = display.size
    local deltaHeight = (winSize.height - designSize.height) * 0.5
    local windowScale = 1
    if (winSize.width / winSize.height) <= (1024 / 768) then
        -- ipad尺寸 会将立绘额外再放大到ps中尺寸的115%
        windowScale = 1.15
    end

    local originalPointInPS = cc.p(0, designSize.height)
    local positionX = originalPointInPS.x + checkint(cardLocationDef.x)
    local positionY = originalPointInPS.y - checkint(cardLocationDef.y) + deltaHeight
    cardView:setAnchorPoint(cc.p(0, 0.5))
    cardView:setScale(checkint(cardLocationDef.scale) * 0.01 * windowScale)
    cardView:setPosition(cc.p(positionX, positionY))
    cardView:setRotation(checkint(cardLocationDef.rotate))
end

--[[
    FIXME 已弃用，现在纯跳转
--]]
function CommonUtils.RefreshDiamond(datas)
    GoodsUtils.RefreshDiamond(datas)
end


--[[
    FIXME 已弃用，现在纯跳转
--]]
function CommonUtils.DrawRewards(props, isDelayEvent, isGuide, isRefreshGoods)
    return app.goodsMgr:DrawRewards(props, isDelayEvent, isGuide, isRefreshGoods)
end
--[[
    -- TODO ！！已经不用了，别往里面扩展了！！先保留一段时间，后面会删掉。
更新资产的本地数据信息的逻辑
props = {
	{goodsId = id, num = 数量, --其他的一些数据}
}
isDelayEvent 如果升级了 先弹出获取界面 后升级
isGuide 确实是否是是为了引导刚进入模块把道具插入背包
isRefreshGoods 是否发送刷新道具的事件
]]
--[[
function CommonUtils.DrawRewards_(props, isDelayEvent, isGuide, isRefreshGoods)
    local delayFuncList = {}
    if isRefreshGoods == nil then
        isRefreshGoods = true
    end
    if type(props) == 'table' and next(props) ~= nil then
        --存在数据，进行数据更新的逻辑
        for k, property in pairs(props) do
            if k ~= 'requestData' then
                if property.goodsId then
                    local num = nil
                    if property.num then
                        --如果存在数量的更新
                        num             = checkint(property.num)
                        property.amount = num
                    end
                    local ugType = CommonUtils.GetGoodTypeById(checkint(property.goodsId))
                    if ugType == GoodsType.TYPE_UN_STABLE then
                        if checkint(checktable(property).turnGoodsId) > 0 and checkint(checktable(property).turnGoodsNum) > 0 then
                            property.goodsId = checkint(checktable(property).turnGoodsId)
                            property.amount  = checkint(checktable(property).turnGoodsNum)
                            property.num     = checkint(checktable(property).turnGoodsNum)
                        end
                    end
                    local id  = checkint(property.goodsId)
                    -- 先判断道具是否不进背包
                    local hideConf = CommonUtils.GetConfigAllMess('hide' , 'goods')
                    if hideConf[tostring(id)] then
                        if id == app.ptDungeonMgr:GetHPGoodsId()  then
                            if next(app.ptDungeonMgr:GetHomeData()) then
                                app.ptDungeonMgr:UpdateHP(checkint(property.amount) + app.ptDungeonMgr:GetHP())
                                AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, {  })
                            end
                        end

                    elseif id == HP_ID then
                        --体力
                        -- app.gameMgr:GetUserInfo().hp = app.gameMgr:GetUserInfo().hp + checkint(property.amount)
                        app.gameMgr:UpdateHp(app.gameMgr:GetUserInfo().hp + checkint(property.amount))
                        -- 体力可以显示负数
                        -- if app.gameMgr:GetUserInfo().hp < 0 then
                        --     app.gameMgr:GetUserInfo().hp = 0
                        -- end
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, { hp = app.gameMgr:GetUserInfo().hp })
                    elseif id == CAPSULE_VOUCHER_ID then    -- 灵火种可以显示负数
                        if not app.gameMgr.userInfo.backpack then
                            app.gameMgr.userInfo.backpack = { property } --初始化数据
                        else
                            local has = 0
                            for i=#app.gameMgr.userInfo.backpack,1,-1 do
                                if checkint(app.gameMgr.userInfo.backpack[i].goodsId) == checkint(id) then
                                    app.gameMgr.userInfo.backpack[i].amount = checkint(app.gameMgr.userInfo.backpack[i].amount) + property.amount --变动后的结果
                                    has = 1
                                    break
                                end
                            end
                            if has == 0 then
                                table.insert(app.gameMgr.userInfo.backpack, {goodsId = checkint(id), amount = checkint(property.amount),IsNew = 1})
                                --判断新插入背包物品。显示仓库红点
                                app.dataMgr:AddRedDotNofication(tostring(RemindTag.BACKPACK), RemindTag.BACKPACK)
                            end
                        end
                    elseif id == DIAMOND_ID then
                        --幻晶石
                        app.gameMgr:GetUserInfo().diamond = app.gameMgr:GetUserInfo().diamond + checkint(property.amount)
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, { diamond = app.gameMgr:GetUserInfo().diamond })
                    elseif id == PAID_DIAMOND_ID then
                        --有偿幻晶石
                        app.gameMgr:GetUserInfo().paidDiamond = app.gameMgr:GetUserInfo().paidDiamond + checkint(property.amount)
                        --总幻晶石
                        app.gameMgr:GetUserInfo().diamond = app.gameMgr:GetUserInfo().diamond + checkint(property.amount)
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, { diamond = app.gameMgr:GetUserInfo().diamond })
                    elseif id == FREE_DIAMOND_ID then
                        app.gameMgr:GetUserInfo().freeDiamond = app.gameMgr:GetUserInfo().freeDiamond + checkint(property.amount)
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, { freeDiamond = app.gameMgr:GetUserInfo().freeDiamond })
                    elseif id == COOK_ID then
                        -- 厨力点
                        app.gameMgr:GetUserInfo().cookingPoint = app.gameMgr:GetUserInfo().cookingPoint + checkint(property.amount)
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, { cookingPoint = app.gameMgr:GetUserInfo().cookingPoint })

                    elseif id == GOLD_ID then
                        --金币
                        app.gameMgr:GetUserInfo().gold = app.gameMgr:GetUserInfo().gold + checkint(property.amount)
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, { gold = app.gameMgr:GetUserInfo().gold })
                    elseif id == UNION_POINT_ID then
                        app.gameMgr:GetUserInfo().unionPoint = checkint(app.gameMgr:GetUserInfo().unionPoint)  + checkint(property.amount)
                    elseif id == REPUTATION_ID then
                        app.gameMgr:GetUserInfo().commerceReputation = checkint(app.gameMgr:GetUserInfo().commerceReputation)  + checkint(property.amount)
                    elseif id == UNION_CONTRIBUTION_POINT_ID then

                    elseif id == EXP_ID then
                        local isLevel, oldLevel, newLevel = app.gameMgr:UpdateExpAndLevel(checkint(property.amount))
                        local func                        = function()
                            --主角经验值时的处理
                            AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.PlayerLevelUpExchange, { isLevel = isLevel, oldLevel = oldLevel, newLevel = newLevel })
                        end

                        if isDelayEvent then
                            table.insert(delayFuncList, func)
                        else
                            func()
                        end

                    elseif id == POPULARITY_ID then
                        app.gameMgr:GetUserInfo().popularity = app.gameMgr:GetUserInfo().popularity + checkint(property.amount)
                        app.gameMgr:UpdateHighestPopularity(app.gameMgr:GetUserInfo().popularity)
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, { popularity = app.gameMgr:GetUserInfo().popularity })
                    elseif id == HIGHESTPOPULARITY_ID then
                        local count = app.gameMgr:GetUserInfo().highestPopularity
                        count       = count + checkint(property.amount)
                        app.gameMgr:UpdateHighestPopularity(count)
                    elseif id == TIPPING_ID then
                        app.gameMgr:GetUserInfo().tip = app.gameMgr:GetUserInfo().tip + checkint(property.amount)
                        -- app.gameMgr:UpdateHighestPopularity(app.gameMgr:GetUserInfo().tip)
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, { tip = app.gameMgr:GetUserInfo().tip })
                    elseif id == ANNIVERSARY_INTEGRAL then

                    elseif id == PVC_MEDAL_ID then
                        app.gameMgr:GetUserInfo().medal = app.gameMgr:GetUserInfo().medal + checkint(property.amount)
                        -- app.gameMgr:UpdateHighestPopularity(app.gameMgr:GetUserInfo().tip)
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, { medal = app.gameMgr:GetUserInfo().medal })
                    elseif id == MAGIC_INK_ID then
                        if not app.gameMgr.userInfo.backpack then
                            app.gameMgr.userInfo.backpack = { property } --初始化数据
                        else
                            app.gameMgr:UpdateBackpackByGoodId(id, checkint(property.amount))
                        end
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MAGIC_INK_UPDATE)
                    elseif id == KOF_CURRENCY_ID then
                        app.gameMgr:GetUserInfo().kofPoint = app.gameMgr:GetUserInfo().kofPoint + checkint(property.amount)
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, { kofPoint = app.gameMgr:GetUserInfo().kofPoint })
                    elseif id == FISH_POPULARITY_ID  then  -- 钓场知名度
                        app.gameMgr:GetUserInfo().fishPopularity = app.gameMgr:GetUserInfo().fishPopularity + checkint(property.amount)
                    elseif id == app.anniversaryMgr:GetIncomeCurrencyID()  then
                        app.gameMgr:GetUserInfo().voucherNum = app.gameMgr:GetUserInfo().voucherNum + checkint(property.amount)
                    elseif id == app.anniversaryMgr:GetRingGameID()  then
                        app.gameMgr:GetUserInfo().voucherNum = app.gameMgr:GetUserInfo().voucherNum + checkint(property.amount)
                    elseif id == PASS_TICKET_ID then
                        if app.passTicketMgr and app.passTicketMgr.InitUpgradeData then
                            app.passTicketMgr:InitUpgradeData(checkint(property.amount))
                        end
                    elseif id == app.murderMgr:GetMurderHpId() then -- 杀人案体力处理
                        app.murderMgr:UpdateHP(app.murderMgr:GetHP() + checkint(property.amount))

                    elseif id == app.anniversary2019Mgr:GetHPGoodsId() then -- 周年庆2019体力处理
                        app.anniversary2019Mgr:UpdateHP(app.anniversary2019Mgr:GetHP() + checkint(property.amount))
                    elseif id == app.anniversary2019Mgr:GetSuppressHPId() then -- 周年庆2019讨伐体力处理
                        app.anniversary2019Mgr:UpdateSuppressHP(app.anniversary2019Mgr:GetSuppressHP() + checkint(property.amount))

                    elseif id == TTGAME_DEFINE.CURRENCY_ID then -- ttGame 专用货币
                        app.gameMgr:GetUserInfo().battleCardPoint = app.gameMgr:GetUserInfo().battleCardPoint + checkint(property.amount)
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, {})

                    elseif id == FOOD.GOODS.DEFINE.WATER_BAR_CURRENCY_ID then  -- 水吧货币
                        app.waterBarMgr:setBarPoint(app.waterBarMgr:getBarPoint() + checkint(property.amount))
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, {})

                    elseif id == FOOD.GOODS.DEFINE.WATER_BAR_POPULARITY_ID then  -- 水吧知名度
                        app.waterBarMgr:setBarPopularity(app.waterBarMgr:getBarPopularity() + checkint(property.amount))
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, {})
                    elseif id == MEMORY_CURRENCY_M_ID then
                        app.gameMgr:GetUserInfo().cardFragmentM = app.gameMgr:GetUserInfo().cardFragmentM + checkint(property.amount)
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, {})
                    elseif id == MEMORY_CURRENCY_SP_ID then
                        app.gameMgr:GetUserInfo().cardFragmentSP = app.gameMgr:GetUserInfo().cardFragmentSP + checkint(property.amount)
                        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI, {})
                    elseif app.activityHpMgr:HasHpData(id) then
                        app.activityHpMgr:UpdateHp(id, checkint(property.amount))
                    else
                        -- app.dataMgr:AddRedDotNofication(tostring(RemindTag.BACKPACK), RemindTag.BACKPACK)
                        -- AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, { countdown = 0, tag = RemindTag.BACKPACK })

                        local gType = CommonUtils.GetGoodTypeById(checkint(property.goodsId))
                        --判断类型
                        if gType == GoodsType.TYPE_CARD then
                            -- dump(property)
                            --卡牌
                            local cardConf = CommonUtils.GetConfig('cards', 'card', id)
                            if app.gameMgr:GetCardDataByCardId(id) then
                                --说明已经拥有该卡牌
                                local qualityId            = cardConf.qualityId or 1
                                local cardConversionConfig = CommonUtils.GetConfig('cards', 'cardConversion', qualityId) or { decomposition = 10 }
                                id                         = cardConf.fragmentId
                                property.amount            = cardConversionConfig.decomposition
                                if not app.gameMgr.userInfo.backpack then
                                    property.goodsId          = cardConf.fragmentId
                                    app.gameMgr.userInfo.backpack = { property } --初始化数据
                                else
                                    app.gameMgr:UpdateBackpackByGoodId(id, checkint(property.amount))
                                end
                            else
                                local data = clone(cardConf)
                                data.id     = property.playerCardId
                                data.cardId = id
                                app.gameMgr:UpdateCardDataByCardId(id, data)
                            end
                            -- elseif gType == GoodsType.TYPE_CARD_FRAGMENT then

                        elseif gType == GoodsType.TYPE_PET or gType == GoodsType.TYPE_APPOINT_PET then
                            -- 堕神
                            local goodsId = property.goodsId
                            local petData = property.playerPet or {}
                            local id      = checkint(petData.id)
                            local petId   = checkint(petData.petId)

                            app.gameMgr:UpdatePetDataById(id, petData)

                            if checkint(property.num) > 0 then
                                -- 检测该堕神是否是正值
                                app.petMgr:CheckMonsterIsLock(petId)
                            end
                        elseif gType == GoodsType.TYPE_RECIPE then
                            --菜谱
                            app.cookingMgr:UpdateCookingStyleDataById(id)

                        elseif gType == GoodsType.TYPE_TTGAME_CARD then
                            --ttGame卡牌
                            if not app.ttapp.GameMgr:hasBattleCardId(id) then
                                app.ttapp.GameMgr:addBattleCardId(id)
                            end

                        elseif gType == GoodsType.TYPE_WATERBAR_MATERIALS then -- 水吧材料
                            app.waterBarMgr:addMaterialNum(property.goodsId, property.amount)
                        elseif gType == GoodsType.TYPE_WATERBAR_DRINKS then -- 水吧饮品
                            app.waterBarMgr:addDrinkNum(property.goodsId, property.amount)
                        elseif gType == GoodsType.TYPE_WATERBAR_FORMULA then -- 水吧配方
                            app.waterBarMgr:setFormulaData(property.goodsId, {formulaId = property.goodsId})

                        elseif gType == GoodsType.TYPE_CARD_SKIN then
                            --卡牌皮肤
                            local isHave = app.cardMgr.IsHaveCardSkin(id)
                            if not isHave then
                                app.gameMgr:UpdateCardSkinsBySkinId(id)
                                -- 购买皮肤券大于一的时候就相当于已经拥有
                                if  property.num >1  then
                                    isHave = true
                                    property.num =  property.num  - 1
                                end
                            end
                            if  isHave then
                                local skinData = CommonUtils.GetConfig('goods','cardSkin',id) or {}
                                local data = clone(skinData.changeGoods)
                                for i, v in pairs(data) do
                                    v.num = checkint(v.num) * property.num
                                end
                                CommonUtils.DrawRewards(data)
                            end

                        elseif gType == GoodsType.TYPE_OTHER then
                            local goodData = CommonUtils.GetConfig('goods', 'other', id) or {}
                            -- effectType 不是 月卡类型
                            if goodData.effectType ~= USE_ITEM_TYPE_MEMBER then
                                --其他道具相关的逻辑
                                if not app.gameMgr.userInfo.backpack then
                                    app.gameMgr.userInfo.backpack = { property } --初始化数据
                                else
                                    app.gameMgr:UpdateBackpackByGoodId(id, checkint(property.amount))
                                end
                            end

                        elseif gType == GoodsType.TYPE_EXP then
                            local goodData = CommonUtils.GetConfig('goods', 'expBuff', id) or {}
                            local expBuff = app.gameMgr:GetUserInfo().expBuff
                            local expAddition = CommonUtils.GetConfig('player', 'expAddition', tostring(goodData.buff))
                            local increment = (goodData.buffTime or expAddition.duration) * 86400 * checkint(property.amount)
                            local max = (goodData.stack or expAddition.max) * increment
                            expBuff[tostring(goodData.buff)] = math.min(checkint(expBuff[tostring(goodData.buff)]) + increment, max)
                        else
                            --其他道具相关的逻辑
                            if not app.gameMgr.userInfo.backpack then
                                app.gameMgr.userInfo.backpack = { property } --初始化数据
                            else
                                app.gameMgr:UpdateBackpackByGoodId(id, checkint(property.amount))
                            end
                        end
                    end
                end
            else
                --不存在goodsId
                printInfo("不存在的goodsId项")
            end
        end
        if isRefreshGoods then
            AppFacade.GetInstance():DispatchObservers(SGL.REFRESH_NOT_CLOSE_GOODS_EVENT, { isGuide = isGuide })
        end
    end
    return delayFuncList

end
]]


--[[
--更新得到转换后的角色真实的id
--]]
function CommonUtils.GetSwapRoleId(roleId)
    local rInfo = app.gameMgr:GetRoleInfo(roleId)
    if rInfo then
        if rInfo.image and string.match(tostring(rInfo.image), '%w+') then
            roleId = tostring(rInfo.image)
        else
            roleId = rInfo.roleId
        end
    end
    return roleId
end
--[[
    设置node的缩放要求
    data ={
        width  宽度
        height 长度
        r = false  --是否为富文本
    }
--]]
function CommonUtils.SetNodeScale(node, data)
    if node and ( not tolua.isnull(node))  then
        local rect = node:getBoundingBox()
        local nodeSize =  node:getContentSize()
        local scaleLabel  = rect.width /nodeSize.width
        local scale = 1
        if data.width then
            scale = data.width/nodeSize.width
        end
        if data.height then
            scale = data.height/ nodeSize.height > scale and scale or data.height/ nodeSize.height
        end
        scale = scale > scaleLabel and  scaleLabel   or scale
        node:setScale(scale)
    end
end
--[[
--获取角色节点
--@params roleId string npc roleId
--@param expressionId int 角色表情id
--]]
function CommonUtils.GetRoleNodeById(roleId, expressionId, flippx)
    if not expressionId then
        expressionId = 1
    end
    -- if expressionId == 0 then expressionId = 1 end
    if not string.match(roleId, '^%d+') then
        local rInfo = app.gameMgr:GetRoleInfo(roleId)
        if rInfo then
            local drawPath = ""
            if rInfo.image and string.match(tostring(rInfo.image), '%w+') then
                drawPath = _res(string.format('arts/roles/%s.png', rInfo.image))
            else
                drawPath = _res(string.format('arts/roles/%s.png', roleId))
            end
            local roleView   = CLayout:create()
            local roleSprite = display.newImageView(drawPath, 0, 0)
            local size       = roleSprite:getContentSize()
            roleView:setContentSize(size)
            roleSprite:setPosition(utils.getLocalCenter(roleView))
            roleView:addChild(roleSprite)
            if expressionId > 0 then
                local expressionDatas = CommonUtils.GetConfigAllMess('roleExpressionLocation', 'quest')
                if expressionDatas then
                    local expRoleId = roleId
                    if rInfo.image and string.match(tostring(rInfo.image), '%w+') then
                        expRoleId = rInfo.image
                    end
                    local roleExpressId = string.format('%s_%d', expRoleId, expressionId)
                    local posData       = expressionDatas[roleExpressId]
                    if posData then
                        local size           = roleSprite:getContentSize()
                        local expressionNode = display.newImageView(_res(string.format('arts/roles/%s.png', posData.roleId)), checkint(posData.location.x), size.height - checkint(posData.location.y))
                        roleView:addChild(expressionNode, 1)
                    end
                end
            end
            if checkbool(flippx) == true then
                roleView:setScaleX(-1)
                -- roleSprite:setFlippedX(true)
            end

            return roleView
        end
    else
        local drawName = ''
        local goodsType = CommonUtils.GetGoodTypeById(roleId)
        if goodsType == GoodsType.TYPE_CARD_SKIN then
            drawName = CardUtils.GetCardDrawNameBySkinId(roleId)
        else
            drawName = CardUtils.GetCardDrawNameByCardId(roleId)
        end

        --是卡牌
        local cardView = AssetsUtils.GetCardDrawNode(drawName)
        local roleView = CLayout:create()
        local size     = cardView:getContentSize()
        roleView:setContentSize(size)
        cardView:setPosition(utils.getLocalCenter(roleView))
        if checkbool(flippx) == true then
            cardView:setScaleX(-1)
        end
        roleView:addChild(cardView)
        return roleView
    end
end


--销毁游戏重新进入
function CommonUtils.ExitGame()
    -- body
    if isQuickSdk() then
        --是quick渠道的逻辑
        local AppSDK = require('root.AppSDK')
        AppSDK.GetInstance():QuickExit()
    else
        cc.Director:getInstance():endToLua()
        os.exit()
    end
end
--[[
获取npc图标
@params id int npc id
@params imgType int 图标类型 1：整张立绘(因主角有表情这种方式有问题这个废弃)，2：头像 3：半身立绘
@return headPath string 道具图标路径
--]]
function CommonUtils.GetNpcIconPathById(id, imgType)
    local headPath = ''
    local roleConf = app.gameMgr:GetRoleInfo(id) or {}
    local headIcon = tostring(string.len(checkstr(roleConf.headIcon)) > 0 and roleConf.headIcon or id)
    if checkint(imgType) == NpcImagType.TYPE_HEAD then
        headPath = _res(string.format('arts/roles/head/%s_head_1.png', headIcon))
        if not utils.isExistent(headPath) then
            headPath = _res('arts/roles/head/role_1_head_1.png')
        end
    elseif checkint(imgType) == NpcImagType.TYPE_HALF_BODY then
        headPath = _res(string.format('arts/roles/uppart/%s_head_2.png', headIcon))
        if not utils.isExistent(headPath) then
            headPath = _res('arts/roles/uppart/role_1_head_2.png')
        end
    end
    return headPath
end


--[[
    判断是否开放手机号
--]]
function CommonUtils.GetIsOpenPhone()
    local OPEN_PHONE       = {
        ALL_NOT_OPEN_PHONE = 0, -- 所以的全部关闭
        ALL_OPEN_PHONE     = 1, -- 全部平台开放
        IOS_OPEN_PHONE     = 2, -- IOS  开放
        ANDORID_OPEN_PHONE = 3, -- Andorid 开放
    }
    local isOphone         = false
    local target           = cc.Application:getInstance():getTargetPlatform()
    local isOpenPhoneValue = app.gameMgr:GetUserInfo().isLockPhone
    if isOpenPhoneValue == OPEN_PHONE.ALL_NOT_OPEN_PHONE then
        isOphone = false
    elseif isOpenPhoneValue == OPEN_PHONE.ALL_OPEN_PHONE then
        isOphone = true
    elseif isOpenPhoneValue == OPEN_PHONE.IOS_OPEN_PHONE and ( target == cc.PLATFORM_OS_MAC or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD) then
        isOphone = true
    elseif isOpenPhoneValue == OPEN_PHONE.ANDORID_OPEN_PHONE and target == cc.PLATFORM_OS_ANDROID then
        isOphone = true
    end
    return isOphone
end


--[[
    FIXME 已弃用，现在纯跳转
--]]
function CommonUtils.GetGoodsIconPathById(id, isBig)
    return GoodsUtils.GetIconPathById(id, isBig)
end


--[[
    FIXME 已弃用，现在纯跳转
]]
function CommonUtils.GetGoodsIconNodeById(id, x, y, params)
    return GoodsUtils.GetIconNodeById(id, x, y, params)
end

--[[
    FIXME 已弃用，现在纯跳转
--]]
function CommonUtils.GetArtifiactPthByCardId(cardId , isBig )
    return ArtifactUtils.GetArtifiactPthByCardId(cardId, isBig)
end

--[[
    FIXME 已弃用，现在纯跳转
--]]
function CommonUtils.GetArtifactFragmentsIdByCardId(cardId)
    return ArtifactUtils.GetArtifactFragmentsIdByCardId(cardId)
end

--[[
获取技能图标路径
@params skillId int 技能id
@return path string 图片路径
--]]
function CommonUtils.GetSkillIconPath(skillId)
    local path = ''
    if 80000 < checkint(skillId) and 90000 > checkint(skillId) then
        -- 主角技技能
        local skillConf = CommonUtils.GetSkillConf(skillId)
        path            = string.format('arts/talentskills/%d.png', checkint(skillConf.icon))
    else
        -- 其他通用
        path = string.format('arts/skills/%d.png', checkint(skillId))
    end

    path = _res(path)
    if not utils.isExistent(path) then
        path = _res('arts/skills/10012.png')
    end

    return path
end

--[[
-- 通过id 检查 是否拥有该皮肤
--@id 道具id
--]]
function CommonUtils.CheckIsOwnSkinById(id)
    -- 1. 检查id是否为nil
    if id == nil then return false end
    -- 2. 检查id是否为皮肤
    local aType = CommonUtils.GetGoodTypeById(id)
    if aType ~= GoodsType.TYPE_CARD_SKIN then return false end
    -- 3. 检查是否拥有该皮肤
    return app.cardMgr.IsHaveCardSkin(id)
end

--[[
    获取到对应的avatarFrame
    这里面是防止 avatarFrame 为nil 为""
--]]
function CommonUtils.GetAvatarFrame(avatarFrame)
    if avatarFrame == "" then
        avatarFrame = InitalAvatarFrame
    elseif checkint(avatarFrame) <= 0 then
        avatarFrame = InitalAvatarFrame
    elseif avatarFrame then
        avatarFrame = avatarFrame
    end
    return avatarFrame
end

--[[
    判断是否为玩家本人
--]]
function CommonUtils.JuageMySelfOperation(playerId)
    return app.gameMgr:IsPlayerSelf(playerId)
end


--[[
获取队伍恢复新鲜度所需消耗的幻晶石
@params teamId int 编队id
--]]
function CommonUtils.GetTeamDiamondRecoverVigourCost( teamId )
    local teamFormationData = app.gameMgr:GetUserInfo().teamFormation[checkint(teamId)]
    local diamondCost       = 0
    if teamFormationData then
        for i, card in ipairs(teamFormationData.cards) do
            if card.id and checkint(card.id) ~= 0 then
                local MaxVigour       = app.restaurantMgr:GetMaxCardVigourById(card.id)
                local remainderVigour = checkint(app.gameMgr:GetCardDataById(card.id).vigour)
                diamondCost           = diamondCost + math.ceil(((MaxVigour - remainderVigour) / MaxVigour) / 0.2 * 1)
            end
        end
    end
    return diamondCost
end

--[[
获取编队卡牌数目
@params teamId int 编队id
--]]
function CommonUtils.GetTeamCardNums( teamId )
    local teamFormationData = app.gameMgr:GetUserInfo().teamFormation[checkint(teamId)]
    local cardNums          = 0
    if teamFormationData then
        for i, card in ipairs(teamFormationData.cards) do
            if card.id and checkint(card.id) ~= 0 then
                cardNums = cardNums + 1
            end
        end
    end
    return cardNums
end

--[[
    反复get配表会卡顿，所以加载一次缓存起来用。至少windows上表现明显
]]
function CommonUtils.GetGameModuleConf()
    if app.dataMgr.GAME_MODULE_CONF == nil then
        app.dataMgr.GAME_MODULE_CONF = CommonUtils.GetConfigAllMess('module')
    end
    return app.dataMgr.GAME_MODULE_CONF
end

--==============================--
--desc:判断解锁的功能模块
--time:2017-06-24 04:21:39
--modify: yajie
--@modeuleNum: 传入的要解锁的功能模块的tag值
--@isTipsShow: 是否显示提示
--return  true string
--==============================--
function CommonUtils.UnLockModule(moduleTag, isTipsShow)
    local playerLevel = checkint(app.gameMgr:GetUserInfo().level)
    local restaurantLevel = checkint(app.gameMgr:GetUserInfo().restaurantLevel)
    local openRestaurantLevel = CommonUtils.GetModuleOpenRestaurantLevel(moduleTag)
    local openLevel   = CommonUtils.GetModuleOpenLevel(moduleTag)
    local isUnLock    = playerLevel >= openLevel and  restaurantLevel  >= openRestaurantLevel
    if isTipsShow == true and isUnLock == false then
        local moduleId   = MODULE_DATA[tostring(moduleTag)] or moduleTag
        local moduleConf = CommonUtils.GetGameModuleConf()[tostring(moduleId)] or {}
        local tipsString = ""
        if openRestaurantLevel >1 then
            tipsString = string.fmt(__('_moduleDescr_ _moduleLevel_级餐厅解锁'), { _moduleDescr_ = tostring(moduleConf.descr), _moduleLevel_ = openRestaurantLevel })
        else
            tipsString = string.fmt(__('_moduleDescr_ _moduleLevel_级解锁'), { _moduleDescr_ = tostring(moduleConf.descr), _moduleLevel_ = openLevel })
        end
        app.uiMgr:ShowInformationTips(tipsString)
    end
    return isUnLock
end
function CommonUtils.GetModuleOpenLevel(moduleTag)
    local openLevel = 0
    local moduleId  = MODULE_DATA[tostring(moduleTag)] or moduleTag
    if moduleId then
        local moduleConf = CommonUtils.GetGameModuleConf()[tostring(moduleId)] or {}
        openLevel        = checkint(moduleConf.openLevel)
    end
    return openLevel
end
function CommonUtils.GetModuleOpenRestaurantLevel(moduleTag)
    local openRestaurantLevel = 0
    local moduleId  = MODULE_DATA[tostring(moduleTag)] or moduleTag
    if moduleId then
        local moduleConf = CommonUtils.GetGameModuleConf()[tostring(moduleId)] or {}
        openRestaurantLevel = checkint(moduleConf.openRestaurantLevel)
    end
    return openRestaurantLevel
end
--[[
    --@params mediator 检测viewCompent 是否存在
 --]]
function CommonUtils.GetMediatorViewCompentIsExist(mediator)
    local isExist  = false
    if mediator then
        if mediator.viewComponent and (not tolua.isnull(mediator.viewComponent) )  then
            isExist = true
        end
    end
    return isExist
end
--[[
    检测模块是否存在
--]]
function CommonUtils.CheckModuleIsExitByMouduleTag(moduleTag)
    local moduleId  = MODULE_DATA[tostring(moduleTag)] or moduleTag
    return CommonUtils.CheckModuleIsExitByModuleId(moduleId)
end
function CommonUtils.CheckModuleIsExitByModuleId(moduleId)
    local moduleConf = CommonUtils.GetGameModuleConf()[tostring(moduleId)]
    if not  moduleConf then
        return false
    end
    return true
end




function CommonUtils.getTalentTableName(talentId)
    local x         = checkint(talentId)
    local tableName = ''
    if x > 0 and x <= 100 then
        tableName = 'talentDamage'
    elseif x >= 101 and x <= 200 then
        tableName = 'talentAssist'
    elseif x >= 201 and x <= 300 then
        tableName = 'talentControl'
    elseif x >= 301 and x <= 400 then
        tableName = 'talentBusiness'
    end
    return tableName
end

--[[
根据阿拉伯数字获取中文数字
@params storyData table {}
@return numStr string 中文数字 0~99
--]]
function CommonUtils.GetStoryTargetDes(storyData)
    local data = storyData
    local str  = ''
    -- dump(data)
    if data then
        if CommonUtils.GetConfig('quest', 'questPlotType', data.taskType) then
            if data.taskType == 1 then
                -- 在大堂招待_target_num_位客人
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
            elseif data.taskType == 2 then
                -- 在消灭_target_num_只_target_id_
                local str1        = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                local monsterConf = CommonUtils.GetConfig('monster', 'monster', data.target.targetId[1])
                str               = string.gsub(str1, '_target_id_', monsterConf.name)
            elseif data.taskType == 3 then
                --完成_target_id_地区的_target_num_个外卖订单
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                if CommonUtils.GetConfigAllMess('area', 'common')[data.target.targetId[1]] then
                    str = string.gsub(str1, '_target_id_', CommonUtils.GetConfigAllMess('area', 'common')[data.target.targetId[1]].name)
                end
            elseif data.taskType == 4 then
                --通过关卡_target_id_
                local questInfo = CommonUtils.GetConfig('quest', 'quest', checkint(data.target.targetId[1])) or {}
                if next(questInfo) == nil then
                    -- descr = string.format('%s-%s', tostring(questInfo.cityId),tostring(questInfo.id))
                    questInfo.name = 'quest表里没有data.target.targetId[1]'
                end
                -- str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType',data.taskType).descr, '_target_id_',(CommonUtils.GetConfig('quest', 'quest', data.target.targetId[1]).name or '') )
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_id_', questInfo.name)
            elseif data.taskType == 5 then
                --完成_target_num_个公众外卖订单
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
            elseif data.taskType == 6 then
                --消灭在_target_id_中盘踞着的_target_id_
                local questInfo = CommonUtils.GetConfig('quest', 'quest', checkint(data.target.targetId[1])) or {}
                --local descr = ''
                if next(questInfo) == nil then
                    -- descr = string.format('%s-%s', tostring(questInfo.cityId),tostring(questInfo.id))
                    questInfo.name = 'quest表里没有data.target.targetId[1]'
                end
                local str1        = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_id_', questInfo.name, 1)

                local monsterConf = CommonUtils.GetConfig('monster', 'monster', data.target.targetId[2])
                if monsterConf then
                    str = string.gsub(str1, '_target_id_', monsterConf.name)
                else
                    str = 'monster 里没找到' .. data.target.targetId[2]
                end
            elseif data.taskType == 7 then
                --消灭_target_num_个在_target_id_中盘踞着的_target_id_
                local questInfo = CommonUtils.GetConfig('quest', 'quest', checkint(data.target.targetId[1])) or {}
                --local descr = ''
                if next(questInfo) == nil then
                    -- descr = string.format('%s-%s', tostring(questInfo.cityId),tostring(questInfo.id))
                    questInfo.name = 'quest表里没有data.target.targetId[1]'
                end
                local str1        = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_id_', questInfo.name, 1)

                local monsterConf = CommonUtils.GetConfig('monster', 'monster', data.target.targetId[2])
                if monsterConf then
                    str2 = string.gsub(str1, '_target_id_', monsterConf.name)
                else
                    str2 = 'monster 里没找到' .. data.target.targetId[2]
                end

                str = string.gsub(str2, '_target_num_', data.target.targetNum)
            elseif data.taskType == 8 then
                --与_target_id_的_target_id_对话
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_id_', CommonUtils.GetConfigAllMess('area', 'common')[(data.target.targetId[1] or 1)].name, 1)
                str        = string.gsub(str1, '_target_id_', (CommonUtils.GetConfig('quest', 'role', data.target.targetId[2]).roleName or ''))
            elseif data.taskType == 9 then
                --"向_target_id_的_target_id_打听消息"
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_id_', CommonUtils.GetConfigAllMess('area', 'common')[(data.target.targetId[1] or 1)].name, 1)
                str        = string.gsub(str1, '_target_id_', (CommonUtils.GetConfig('quest', 'role', data.target.targetId[2]).roleName or ''))
            elseif data.taskType == 10 then
                --在周围打探一下消息
                -- str = __('在周围打探一下消息')
                str = CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr
            elseif data.taskType == 11 then
                --"帮助_target_id_完成心愿 支线任务id
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_id_', (CommonUtils.GetConfig('quest', 'role', data.target.targetId[1]).roleName or ''))
            elseif data.taskType == 12 then
                --收集_target_num_个_target_id_
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                str        = string.gsub(str1, '_target_id_', (CommonUtils.GetConfig('goods', 'goods', data.target.targetId[1]).name or ''))
            elseif data.taskType == 13 then
                --击败_target_id_
                local plotFightQuest = CommonUtils.GetConfig('quest', 'plotFightQuest', data.target.targetId[1])
                -- dump(plotFightQuest)
                if plotFightQuest then
                    str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_id_', plotFightQuest.name )
                else
                    str = 'plotFightQuest 里没找到' .. data.target.targetId[1]
                end

            elseif data.taskType == 14 then
                --挑战_target_id_
                local plotFightQuest = CommonUtils.GetConfig('quest', 'plotFightQuest', data.target.targetId[1])
                if plotFightQuest then
                    str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_id_', plotFightQuest.name )
                else
                    str = 'plotFightQuest 里没找到' .. data.target.targetId[1]
                end
            elseif data.taskType == 15 then
                --制作_target_num_道料理
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
            elseif data.taskType == 16 then
                --制作_target_num_道_target_id_
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                str        = string.gsub(str1, '_target_id_', (CommonUtils.GetConfig('goods', 'food', data.target.targetId[1]).name or ''))
            elseif data.taskType == 17 then
                --将_target_id_的等级提升至_target_num_级
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                str        = string.gsub(str1, '_target_id_', (CommonUtils.GetConfig('cards', 'card', data.target.targetId[1]).name or ''))
            elseif data.taskType == 18 then
                --将_target_id_的阶位提升至_target_num_星
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                str        = string.gsub(str1, '_target_id_', (CommonUtils.GetConfig('cards', 'card', data.target.targetId[1]).name or ''))
            elseif data.taskType == 19 then
                --激活技能_target_id_
                local tableName = CommonUtils.getTalentTableName(data.target.targetId[1])
                if tableName ~= '' then
                    str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_id_', (CommonUtils.GetConfig('player', tableName, data.target.targetId[1]).name or ''))
                end
            elseif data.taskType == 20 then
                --装备任意伤害系技能进行战斗
                str = CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr
                -- local tableName = CommonUtils.getTalentTableName(data.target.targetId[1])
                -- if tableName ~= '' then
                -- 	str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType',data.taskType).descr, '_target_id_', (CommonUtils.GetConfig('player', tableName, data.target.targetId[1]).name or ''))
                -- end
            elseif data.taskType == 21 then
                --强化任意天赋技能_target_num_次
                local tableName = CommonUtils.getTalentTableName(data.target.targetId[1])
                if tableName ~= '' then
                    local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_id_', (CommonUtils.GetConfig('player', tableName, data.target.targetId[1]).name or ''))
                    str        = string.gsub(str1, '_target_num_', data.target.targetNum)
                end
            elseif data.taskType == 22 then
                --"完成_target_num_次打劫"
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
            elseif data.taskType == 23 then
                --研究_target_id_的菜谱
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_id_', (CommonUtils.GetConfig('cooking', 'recipe', data.target.targetId[1]).name or ''))
            elseif data.taskType == 24 then
                --"制作num次id评价的菜品
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                str        = string.gsub(str1, '_target_id_', (CommonUtils.GetConfigNoParser('cooking', 'grade', data.target.targetId[1]).grade or ''))
            elseif data.taskType == 25 then
                --在冰场内放入任意_target_num_张卡牌
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
            elseif data.taskType == 26 then
                --"完成当日所有日常任务
                -- str = __('完成当日所有日常任务')
                str = CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr
            elseif data.taskType == 27 then
                --"装备辅助系天赋进行战斗
                -- str = __('装备辅助系天赋进行战斗')
                str = CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr
            elseif data.taskType == 28 then
                --"装备控制系天赋进行战斗
                -- str = __('装备控制系天赋进行战斗')
                str = CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr
            elseif data.taskType == 29 then
                --"升级_target_id_至_target_num_级
                -- local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                -- str = string.gsub(str1, '_target_id_', (CommonUtils.GetConfig('kitchen', 'stove', data.target.targetId[1]).name or ''))
            elseif data.taskType == 30 then
                --"完成功能引导:_name_
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_name_', data.name)
            elseif data.taskType == 31 then
                --前往_target_id_远征
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_id_', (CommonUtils.GetConfig('common', 'areaFixedPoint', data.target.targetId[1]).name or ''))
            elseif data.taskType == 32 then
                --前往_target_id_寻找_target_id_
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_id_', (CommonUtils.GetConfig('common', 'areaFixedPoint', data.target.targetId[1]).name or ''), 1)
                str        = string.gsub(str1, '_target_id_', (CommonUtils.GetConfig('quest', 'role', data.target.targetId[2]).roleName or ''))
            elseif data.taskType == 33 then
                --前往_target_id_击败_target_id_
                local str1        = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_id_', (CommonUtils.GetConfig('common', 'areaFixedPoint', data.target.targetId[1]).name or ''), 1)
                local monsterConf = CommonUtils.GetConfig('monster', 'monster', data.target.targetId[2])
                str               = string.gsub(str1, '_target_id_', monsterConf.name)
            elseif data.taskType == 34 then
                -- 34	在餐厅招待_target_num_位特需客人
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
            elseif data.taskType == 35 then
                -- 35	提升餐厅规模至_target_num_
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)

            elseif data.taskType == 36 then
                -- 36	改良_target_num_次任意菜品
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
            elseif data.taskType == 37 then
                -- 37	获得_target_num__target_id_
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                str        = string.gsub(str1, '_target_id_', (CommonUtils.GetConfig('goods', 'goods', data.target.targetId[1]).name or ''))
            elseif data.taskType == 38 then
                -- 38	升级_target_id_的任意战斗技能_target_num_次
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                str        = string.gsub(str1, '_target_id_', (CommonUtils.GetConfig('cards', 'card', data.target.targetId[1]).name or ''))
            elseif data.taskType == 39 then
                -- 39	研究菜谱_target_num_次
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
            elseif data.taskType == 40 then
                -- 40	提升_target_id_或_target_id_或_target_id_的评价至_target_id_级
                if data.target.targetId then
                    local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_id_', (CommonUtils.GetConfig('goods', 'goods', app.cookingMgr:GetStoryRecipeId(data.target.targetId)).name or ''), 1)
                    --local str2 = string.gsub(str1, '_target_id_', (CommonUtils.GetConfig('goods', 'goods', data.target.targetId[2]).name or ''), 1)
                    --local str3 = string.gsub(str2, '_target_id_', (CommonUtils.GetConfig('goods', 'goods', data.target.targetId[3]).name or ''), 1)
                    str        = string.gsub(str1, '_target_id_', (CommonUtils.GetConfigNoParser('cooking', 'grade', data.target.targetNum).grade or ''))
                end
                -- str = string.gsub(str3, '_target_id_', (CommonUtils.GetConfigNoParser('cooking', 'grade', data.target.targetNum).grade or ''))
            elseif data.taskType == 41 then
                -- 41	购买_target_num_个_target_id_
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                str        = string.gsub(str1, '_target_id_', (CommonUtils.GetConfig('goods', 'goods', data.target.targetId[1]).name or ''))
            elseif data.taskType == 42 then
                -- 42	装饰餐厅时放置_target_num_个_target_id_
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                str        = string.gsub(str1, '_target_id_', (CommonUtils.GetConfigNoParser('restaurant', 'avatar', data.target.targetId[1]).name or ''))
            elseif data.taskType == 43 then
                --开发_target_id_的_target_num_道菜谱
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                str        = string.gsub(str1, '_target_id_', (CommonUtils.GetConfigNoParser('cooking', 'style', data.target.targetId[1]).name or ''))
            elseif data.taskType == 44 then
                -- 44	在餐厅中进行_target_num_次备菜
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
            elseif data.taskType == 45 then
                -- 45	在餐厅中打败_target_num_次霸王餐食客
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)

            elseif data.taskType == 45 then
                --在餐厅中打败_target_num_次霸王餐食客
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)


            elseif data.taskType == 46 then
                --将_target_num_个飨灵升级至等级_target_id_
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                str        = string.gsub(str1, '_target_id_', data.target.targetId[1] or '')

            elseif data.taskType == 47 then
                --将_target_num_个飨灵阶位提升至_target_id_星
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                str        = string.gsub(str1, '_target_id_', data.target.targetId[1] or '')

            elseif data.taskType == 48 then
                --将_target_num_个飨灵任意战斗技能提升至等级_target_id
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                str        = string.gsub(str1, '_target_id_', data.target.targetId[1] or '')

            elseif data.taskType == 49 then
                --将_target_num_个飨灵任意经营技能提升至等级_target_id
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                str        = string.gsub(str1, '_target_id_', data.target.targetId[1] or '')

            elseif data.taskType == 50 then
                --收集_target_num_个_target_id_级别的卡牌
                local str1 = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
                str        = string.gsub(str1, '_target_id_', (CommonUtils.GetConfig('cards', 'quality', data.target.targetId[1]).quality or ''))


            elseif data.taskType == 51 then
                --拥有_target_num_个好友
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)


            elseif data.taskType == 52 then
                --竞技场战斗_target_num_次
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)

            elseif data.taskType == 53 then
                --竞技场获胜_target_num_次
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)

            elseif data.taskType == 54 then
                --通关邪神遗迹第_target_num_层
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
            elseif data.taskType == 59 then
                --通关邪神遗迹第_target_num_层
                str = string.gsub(CommonUtils.GetConfig('quest', 'questPlotType', data.taskType).descr, '_target_num_', data.target.targetNum)
            else

            end
        end
    end
    return str
end


--[[
--当前界面是否是打开的逻辑
--]]
function CommonUtils.ModulePanelIsOpen(isStore)
    local key    = string.format('%s_ModulePanelIsOpen', tostring(app.gameMgr:GetUserInfo().playerId))
    local isOpen = cc.UserDefault:getInstance():getBoolForKey(key, false)
    if isStore then
        cc.UserDefault:getInstance():setBoolForKey(key, (not isOpen))
        cc.UserDefault:getInstance():flush()
    end
    isOpen = cc.UserDefault:getInstance():getBoolForKey(key, false)
    return isOpen
end
--[[
--取得buffer类型的数据更换的描述的逻辑
--]]
function CommonUtils.GetBufferDescription(descr, configData)
    if descr then
        local target                  = descr
        local spans                   = {}
        local occurentNo, occurentNo2 = 0, 0
        for w in string.gmatch(descr, '_target_id_') do
            occurentNo = occurentNo + 1
        end
        for w in string.gmatch(descr, '_target_num_') do
            occurentNo2 = occurentNo2 + 1
        end
        spans['targetId']  = { id = '_target_id_', num = occurentNo }
        spans['targetNum'] = { id = '_target_num_', num = occurentNo2 }
        for key, val in pairs(spans) do
            if checkint(val.num) > 0 then
                for i = 1, checkint(val.num) do
                    if type(configData[key]) == 'table' then
                        if table.nums(checktable(configData[key])) > 0 then
                            target = string.gsub(target, tostring(val.id), configData[key][i], 1)
                        end
                    else
                        target = string.gsub(target, tostring(val.id), configData[key])
                    end
                end
            end
        end
        return target
    else
        return ''
    end
end

--[[
    FIXME 已弃用，现在纯跳转
--]]
function CommonUtils.GetGoodsQuality(goodsId)
    return GoodsUtils.GetGoodsQualityById(goodsId)
end
----------------------------------
-- config end --
----------------------------------

---------------------------------------------------
-- quest utils begin --
---------------------------------------------------


--[[
根据神兽id和神兽等级换算神兽关卡id
@params id int 神兽id
@params level int 神兽等级
@return _ int 关卡id
--]]
function CommonUtils.GetBeastQuestIdByIdAndLevel(id, level)
    local beastQuestGroupConfig = CommonUtils.GetConfig('union', 'godBeastQuestGroup', id)
    if nil ~= beastQuestGroupConfig then
        local idx = math.max(1, math.min(#beastQuestGroupConfig, level + 1))
        local questId = beastQuestGroupConfig[idx]
        return questId
    end
    return nil
end
--[[
根据神兽id和神兽等级换算神兽关关卡id
@params id int 神兽id
@params level int 神兽等级
@return _ table 关卡信息
--]]
function CommonUtils.GetBeastQuestConfByIdAndLevel(id, level)
    local beastQuestGroupConfig = CommonUtils.GetConfig('union', 'godBeastQuestGroup', id)
    if nil ~= beastQuestGroupConfig then
        local idx = math.max(1, math.min(#beastQuestGroupConfig, level + 1))
        local questId = beastQuestGroupConfig[idx]
        return CommonUtils.GetQuestConf(questId)
    end
    return nil
end
--[[
根据关卡id获取打神兽奖励信息
@params stageId int 关卡id
@params captured bool 是否捕获
@return rewards list 奖励信息
--]]
function CommonUtils.GetBeastQuestRewards(stageId, captured)
    local rewards = {}
    local stageConfig = CommonUtils.GetQuestConf(stageId)

    if captured then
        -- 如果捕获 插入一个神兽能量
        local goodsInfo = {
            goodsId = UNION_BEAST_ENERGY_ID,
            num = 0,
            showAmount = false
        }
        table.insert(rewards, goodsInfo)
    end

    if nil == stageConfig then
        return rewards
    else
        if nil ~= stageConfig.unionPoint and 0 < checkint(stageConfig.unionPoint) then
            local goodsInfo = {
                goodsId = UNION_POINT_ID,
                num = checkint(stageConfig.unionPoint),
                showAmount = true
            }
            table.insert(rewards, goodsInfo)
        end

        if nil ~= stageConfig.contributionPoint and 0 < checkint(stageConfig.contributionPoint) then
            local goodsInfo = {
                goodsId = UNION_CONTRIBUTION_POINT_ID,
                num = checkint(stageConfig.contributionPoint),
                showAmount = true
            }
            table.insert(rewards, goodsInfo)
        end

        if stageConfig.rewards then
            for i,v in ipairs(stageConfig.rewards) do
                local goodsInfo = {
                    goodsId = checkint(v.goodsId),
                    num = checkint(v.num),
                    showAmount = true
                }
                table.insert(rewards, goodsInfo)
            end
        end
        return rewards
    end
end
--[[
根据关卡id判断是否能进入当前关卡
@params stageId int 关卡id
@return result, errLog bool, str 是否可以进入, 错误信息
--]]
function CommonUtils.CanEnterStageIdByStageId(stageId)
    local result, errLog = true, ''

    ------------ 非地图关卡直接返回true ------------
    if QuestBattleType.MAP ~= CommonUtils.GetQuestBattleByQuestId(stageId) then

        return true

    end
    ------------ 非地图关卡直接返回true ------------

    local stageConfig = CommonUtils.GetQuestConf(stageId)

    ------------ 判断所在章节是否解锁 ------------
    local chapterId   = checkint(stageConfig.cityId)
    local difficulty  = checkint(stageConfig.difficulty)
    result, errLog    = CommonUtils.CanEnterChapterByChapterIdAndDiff(chapterId, difficulty)
    if not result then

        -- 如果未解锁该章节 直接返回
        return result, errLog

    end
    ------------ 判断所在章节是否解锁 ------------

    ------------ 判断是否到达该关卡 ------------
    local newestStageId = app.gameMgr:GetNewestQuestIdByDifficulty(difficulty)
    if stageId > newestStageId then
        return false, __('请先通过前一关')
    end
    ------------ 判断是否到达该关卡 ------------


    return result, errLog
end
--[[
根据章节id和难度判断是否可以进入当前章节
@params chapterId int 章节id
@params difficulty int 难度
@return result, errLog bool, str 是否可以进入, 错误信息
--]]
function CommonUtils.CanEnterChapterByChapterIdAndDiff(chapterId, difficulty)
    local result, errLog      = true, ''
    local chapterConfig       = CommonUtils.GetConfig('quest', 'city', chapterId)

    -- tips 章节解锁两个条件 [1]-玩家等级 [2]-前置关卡

    local chapterUnlockConfig = chapterConfig.unlock[tostring(difficulty)]
    if nil == chapterUnlockConfig then
        return false, string.format('未找到章节%d-难度%d的解锁条件配置', chapterId, difficulty)
    else
        local limitLevel = chapterUnlockConfig[1]
        local limitStage = chapterUnlockConfig[2]

        ------------ 判断等级是否解锁 ------------
        if limitLevel and app.gameMgr:GetUserInfo().level < checkint(limitLevel) then

            result, errLog = false, string.format(__('该关卡需要角色等级达到%d解锁'), checkint(limitLevel))

            ------------ 判断前置关卡 ------------
        elseif limitStage then
            local limitStageConfig = CommonUtils.GetQuestConf(checkint(limitStage))
            if checkint(limitStage) >= app.gameMgr:GetNewestQuestIdByDifficulty(checkint(limitStageConfig.difficulty)) then

                -- result, errLog = false, string.format(
                -- __('请先通过%d-%d-%d'),
                -- checkint(limitStageConfig.cityId),
                -- checkint(limitStageConfig.position),
                -- checkint(limitStageConfig.difficulty))
                result, errLog = false, string.format(
                        __('请先通过%s-%d-%d'),
                        tostring(chapterConfig.name),
                        checkint(limitStageConfig.position),
                        checkint(limitStageConfig.difficulty))

            end
        end
    end

    return result, errLog
end


--[[
根据关卡id判断是否可以复刷
@params stageId int 关卡id
@return _ bool 是否可以复刷
--]]
function CommonUtils.IsRechallengeByStageId(stageId)
    local stageConf = CommonUtils.GetQuestConf(stageId)
    return QuestRechallenge.QR_CAN == checkint(stageConf.repeatChallenge)
end
--[[
根据关卡id获取剩余可以复刷次数
@params stageId int 关卡id
@return _ int 剩余复刷次数
--]]
function CommonUtils.GetRechallengeLeftTimesByStageId(stageId)
    if CommonUtils.IsRechallengeByStageId(stageId) then
        local stageConf = CommonUtils.GetQuestConf(stageId)

        if 0 == checkint(stageConf.challengeTime) then

            return QuestRechallengeTime.QRT_INFINITE

        elseif 0 < checkint(stageConf.challengeTime) and nil ~= app.gameMgr:GetUserInfo().allQuestChallengeTimes then

            return checkint(app.gameMgr:GetUserInfo().allQuestChallengeTimes[tostring(stageId)])

        end
    end
    return QuestRechallengeTime.NONE
end
--[[
根据关卡id获取剩余挑战购买消耗
@params stageId int 关卡id
@return _,_ int int 消耗 道具类型
--]]
function CommonUtils.GetBuyChallengeTimeCostByStageId(stageId)
    return 10, DIAMOND_ID
end
--[[
获取星级条件描述
@params clearData conf 星级条件数据
@params parameter string 外部参数
--]]
function CommonUtils.GetFixedClearDesc(clearData, parameter)
    local markString = '_target_num_'
    local descr      = clearData.descr
    -- 查找占位符 如果没有 快速返回
    if not string.find(descr, markString) then
        return descr
    else
        -- 存在占位符 判断类型
        local id     = checkint(clearData.id)
        local result = string.gsub(descr, markString, '%%s')
        if 2 == id then
            -- 在_target_num_秒内完成关卡
            result = string.format(result, parameter)
        elseif 4 == id then
            -- 不使用_target_num_职业的卡牌
            parameter = rangeId(checkint(parameter), 4)
            result    = string.format(result, CardUtils.GetCardCareerName(parameter))
        elseif 6 == id then
            -- 使用_target_num_卡牌
            local cardName = CommonUtils.GetConfig('cards', 'card', parameter).name
            result         = string.format(result, cardName)
        end
        return result
    end
end


--[[
检查该 mediator 是否能弹出
@params popMediator string 将要弹出的 mediator name
@return isCanPop 是否能弹出
--]]
function CommonUtils.checkPopMediatorIsCanPop(popMediator)
    local isCanPop = true
    if popMediator == 'summerActivity.SummerActivityHomeMediator' then
        isCanPop = app.gameMgr:GetUserInfo().summerActivity > 0
    end
    return isCanPop
end

--[[
通过道具id获得道具恢复key
@params goodsId int 道具id
@return isShow bool 是否显示
--]]
function CommonUtils.getCurrencyRestoreKeyByGoodsId(goodsId)
    return string.format('HP_MANAGER_COUNTDOWN_%d', checkint(goodsId))
end

--[[
根据关卡id 和关卡类型 获取买活消耗
@params stageId int 关卡id
@params questBattleType QuestBattleType 战斗类型
@params nextBuyRevivalTime 下一次买活次数
@return _ table 买活消耗
--]]
function CommonUtils.GetBattleBuyReviveCostConfig(stageId, questBattleType, nextBuyRevivalTime)
    if QuestBattleType.TOWER == questBattleType then
        return CommonUtils.GetConfig('tower', 'towerBuyLiveConsume', nextBuyRevivalTime)
    elseif QuestBattleType.UNION_BEAST == questBattleType then
        return CommonUtils.GetConfig('union', 'godBeastBuyLiveConsume', nextBuyRevivalTime)
    elseif QuestBattleType.WORLD_BOSS == questBattleType then
        return CommonUtils.GetConfig('worldBossQuest', 'buyLiveConsume', nextBuyRevivalTime)
    elseif QuestBattleType.PT_DUNGEON == questBattleType then
        local buyLiveConf = CommonUtils.GetConfig('pt', 'buyLive', app.ptDungeonMgr:GetHomeData().ptId) or {}
        return buyLiveConf[tostring(nextBuyRevivalTime)]
    end
    return nil
end
---------------------------------------------------
-- quest utils end --
---------------------------------------------------

----------------------------------
-- utils begin --
----------------------------------
--[[
--根据卡牌id获取卡的配音的路径文件
--@cardId 卡牌id
--@playType 播放的类别
--]]
CommonUtils.soundChannelMap_ = {}
function CommonUtils.PlayCardSoundByCardId(cardId, playType, soundChannel, isForcedPlay, soundId )
    local voiceDatas = CardUtils.GetVoiceLinesConfigByCardId(cardId)
    local sounds     = {}
    local pos          = 0
    local voiceType = ""
    if voiceDatas then
        if soundId then
            for name, val in pairs(voiceDatas) do
                if val.voiceId == soundId  then
                    table.insert(sounds, val)
                    pos = 1
                    voiceType = PLAY_VOICE_TYPE.JAPANESE
                    break
                end
                if val.voiceCodeCn == soundId then
                    table.insert(sounds, val)
                    pos = 1
                    voiceType = PLAY_VOICE_TYPE.CHINESE
                    break
                end
            end
        else
            for name, val in pairs(voiceDatas) do
                if val.type and table.nums(checktable(val.type)) > 0 then
                    for idx, vv in ipairs(checktable(val.type)) do
                        if checkint(vv) == playType then
                            table.insert(sounds, val)
                        end
                    end
                end
            end
            voiceType = app.audioMgr:GetVoiceType()
            if table.nums(sounds) > 0 then
                pos = math.random(1,table.nums(sounds) )
            end
        end

    end
    local len  = table.nums(sounds)
    local soundTime = 3
    if len > 0 then
        local data         = sounds[pos]
        -- local t = string.split(voiceCode, '_')
        -- local cueSheet = table.concat({t[1], t[2]}, '_')
        local cueSheet     = tostring(data.roleId)
        local cueName      = data.voiceId
        local preCueName = cueName
        ---@type AudioManager
        local audioMgr = app.audioMgr
        local acbFile  = audioMgr:GetVoicePathByName(cueSheet, PLAY_VOICE_TYPE.JAPANESE)
        if voiceType == PLAY_VOICE_TYPE.CHINESE then
            local cueSheetCn = tostring(data.roleIdCn)
            if data.roleIdCn  and string.len(tostring(data.roleIdCn) ) ==  0  then
                return soundTime, preCueName
            end
            if audioMgr:CheckChineseVoiceComplete(string.format('%s.acb', cueSheetCn) ) then
                acbFile = audioMgr:GetVoicePathByName(cueSheetCn, PLAY_VOICE_TYPE.CHINESE)
                if  (not isNewUSSdk()) and isElexSdk() then
                    cueName  = string.match(data.voiceCodeCn,"cn_(.+)")
                    cueSheet =string.match(data.roleIdCn ,"cn_(.+)")
                else
                    cueName  = data.voiceCodeCn
                    cueSheet = data.roleIdCn
                end
            end
        end
        if utils.isExistent(acbFile)  then
            audioMgr:AddCueSheet(cueSheet, acbFile)
            local time = app.audioMgr:GetPlayerCueTime(cueSheet, cueName)
            if time > 0 then
                soundTime = time
            end

            if soundChannel then
                local isForced = isForcedPlay ~= false
                local playData = checktable(CommonUtils.soundChannelMap_[tostring(soundChannel)])
                if isForced then
                    audioMgr:StopAudioClip(playData.sheetName)
                    CommonUtils.soundChannelMap_[tostring(soundChannel)] = { sheetName = cueSheet, timeLength = soundTime, playTime = os.time() }
                    audioMgr:PlayAudioClip(cueSheet, cueName)

                else
                    if os.time() - checkint(playData.playTime) - checkint(playData.timeLength) >= 0 then
                        CommonUtils.soundChannelMap_[tostring(soundChannel)] = { sheetName = cueSheet, timeLength = soundTime, playTime = os.time() }
                        audioMgr:PlayAudioClip(cueSheet, cueName)
                    end

                end
            else
                audioMgr:PlayAudioClip(cueSheet, cueName)
            end

            return soundTime, preCueName
        else
            return soundTime, preCueName
        end
    end
end

--[[
    播放主线语音
]]
CommonUtils.plotSoundChannelMap_ = {}
function CommonUtils.PlayCardPlotSoundById(cardId, soundId, soundChannel, isForcedPlay)
    local soundTime   = 1
    local acbFileName = string.fmt('SVoice_%1', tostring(cardId))
    local cueSheetId  = acbFileName
    local acbCueName  = soundId
    local acbFilePath = app.audioMgr:GetVoicePathByName(acbFileName, PLAY_VOICE_TYPE.CHINESE)
    if utils.isExistent(acbFilePath) then
        app.audioMgr:AddCueSheet(cueSheetId, acbFilePath)
        local time = app.audioMgr:GetPlayerCueTime(cueSheet, cueName)
        if time > 0 then
            soundTime = time
        end

        --
        if soundChannel then
            local isForced = isForcedPlay ~= false
            local playData = checktable(CommonUtils.plotSoundChannelMap_[tostring(soundChannel)])
            if isForced then
                app.audioMgr:StopAudioClip(playData.sheetName)
                CommonUtils.plotSoundChannelMap_[tostring(soundChannel)] = { sheetName = cueSheetId, timeLength = soundTime, playTime = os.time() }
                app.audioMgr:PlayAudioClip(cueSheetId, acbCueName)

            else
                if os.time() - checkint(playData.playTime) - checkint(playData.timeLength) >= 0 then
                    CommonUtils.plotSoundChannelMap_[tostring(soundChannel)] = { sheetName = cueSheetId, timeLength = soundTime, playTime = os.time() }
                    app.audioMgr:PlayAudioClip(cueSheetId, acbCueName)
                end
            end
        else
            app.audioMgr:PlayAudioClip(cueSheetId, acbCueName)
        end
    end
    return soundTime
end


--[[
    根据卡牌id 获取到cv 的名字
--]]
function CommonUtils.GetCurrentCvAuthorByCardId(cardId)
    local cardData =   CommonUtils.GetConfig('cards', 'card', cardId)
    if not  cardData then
        return "CV:--"
    end
    local cvName = 'CV:'..(cardData.cv or '--')
    if app.audioMgr:GetVoiceType() == PLAY_VOICE_TYPE.CHINESE then
        cvName =  'CV:'..(cardData.cvCn or '--')
    end
    return cvName
end


--[[
    根据卡牌id，语音id 获取到cv 的台词
--]]
function CommonUtils.GetCurrentCvLinesByVoiceId(cardId, voiceId)
    local voiceLineConf = CardUtils.GetVoiceLinesConfigByCardId(cardId) or {}
    local descr = ''
    if isElexSdk() then
        for name, val in pairs(voiceLineConf) do
            if val.voiceId == voiceId then
                descr = tostring(val.desk)
                break
            end
        end
        return descr
    end
    for name, val in pairs(voiceLineConf) do
        if val.voiceId == voiceId then
            if app.audioMgr:GetVoiceType() == PLAY_VOICE_TYPE.CHINESE then
                descr = tostring(val.deskCn)
            else
                descr = tostring(val.desk)
            end
            break
        end
    end
    return descr
end
--[[
    根据卡牌id，分组id 获取到cv 的台词
--]]
function CommonUtils.GetCurrentCvLinesByGroupType(cardId, groupType)
    local voiceLineConf = CardUtils.GetVoiceLinesConfigByCardId(cardId) or {}
    local descr = ''
    if isElexSdk() then
        for name, val in pairs(voiceLineConf) do
            if checkint(val.groupId) == groupType then
                descr = tostring(val.desk)
                break
            end
        end
        return descr
    end
    for name, val in pairs(voiceLineConf) do
        if checkint(val.groupId) == groupType then
            if app.audioMgr:GetVoiceType() == PLAY_VOICE_TYPE.CHINESE then
                descr = tostring(val.deskCn)
            else
                descr = tostring(val.desk)
            end
            break
        end
    end
    return descr
end

--[[
通过玩家id获取好友数据
@params friendId int 玩家id
--]]
function CommonUtils.GetFriendData(friendId)
    local friendData   = nil
    local findFriendId = checkint(friendId)
    local friendList = app.gameMgr:GetUserInfo().friendList
    for i, v in ipairs(friendList or {}) do
        if checkint(v.friendId) == findFriendId then
            friendData = v
            break
        end
    end
    return friendData
end
--[[
通过玩家id判断是否为好友
@params friendId int 玩家id
--]]
function CommonUtils.GetIsFriendById( friendId )
    return CommonUtils.GetFriendData(friendId) ~= nil
end
--[[
获取当前在线的好友数量
]]
function CommonUtils.GetOnlineFriendNum()
    local onlineCount = 0
    for _, friendData in ipairs(app.gameMgr:GetUserInfo().friendList) do
        if checkint(friendData.isOnline) == 1 then
            onlineCount = onlineCount + 1
        end
    end
    return onlineCount
end

--[[
通过玩家Id获取头像弹出框类型
--]]
function CommonUtils.GetHeadPopupTypeByPlayerId( playerId )
    if CommonUtils.GetIsFriendById(playerId) then
        return HeadPopupType.FRIEND
    else
        return HeadPopupType.STRANGER
    end
end
--[[
判断该玩家是否在黑名单中
--]]
function CommonUtils.IsInBlacklist( playerId )
    local userId = checkint(app.gameMgr:GetUserInfo().playerId)
    playerId = checkint(playerId)
    if userId == playerId then
        return false
    end

    local blacklist = app.gameMgr:GetUserInfo().blacklist
    for i, v in ipairs(blacklist) do
        if checkint(v.playerId) == playerId then
            return true
        end
    end
    return false
end

--[[
根据阿拉伯数字获取中文数字
@params i int 数字
@return numStr string 中文数字 0~99
--]]
function CommonUtils.GetChineseNumber(i)
    local chineseLang = {
        ['zh-cn'] = true
    }
    if true ~= chineseLang[i18n.getLang()] then
        -- 非中文地区直接返回数字
        return tostring(i)
    end

    local formattedNumber = {
        ['0']  = '零',
        ['1']  = '一',
        ['2']  = '二',
        ['3']  = '三',
        ['4']  = '四',
        ['5']  = '五',
        ['6']  = '六',
        ['7']  = '七',
        ['8']  = '八',
        ['9']  = '九',
        ['10'] = '十'
    }

    local numStr          = formattedNumber[tostring(i)]
    if i > 10 and i < 20 then
        numStr = formattedNumber['10'] .. formattedNumber[tostring(i % 10)]
    elseif i >= 20 and i <= 99 then
        local decade = math.floor(i / 10)
        local unit   = i - decade * 10
        numStr       = CommonUtils.GetChineseNumber(decade) .. formattedNumber['10'] .. (0 ~= unit and CommonUtils.GetChineseNumber(unit) or '')
    elseif i > 99 then
        numStr = '大于100的没实现'
    end
    return numStr
end
--[[
获取一个通用的领取奖励的spine动画
--]]
function CommonUtils.GetRrawRewardsSpineAnimation()
    local spineAnimation = sp.SkeletonAnimation:create(
            'effects/rewardgoods/skeleton.json',
            'effects/rewardgoods/skeleton.atlas',
            1
    )
    spineAnimation:update(0)
    return spineAnimation
end
--[[
根据int秒数以及间隔符号x获取时x分x秒字符串
example : CommonUtils.GetFormattedTimeBySecond(7201, ':') --> '02:00:01'
@params second int int秒数
@params splitMark string 间隔符号
@return result string 格式化后的时间字符串
--]]
function CommonUtils.GetFormattedTimeBySecond(second, splitMark)
    splitMark    = splitMark or ':'
    local h      = math.floor(second / 3600)
    local m      = math.floor((second - h * 3600) / 60)
    local s      = second - h * 3600 - m * 60
    local result = string.format('%02d%s%02d%s%02d', h, splitMark, m, splitMark, s)
    return result
end
----------------------------------
-- utils end --
----------------------------------

----------------------------------
-- view begin --
----------------------------------

--[[
--cardId获取该卡牌的经营技能
--@param cardId --卡牌id 非数据库自增id
"descr"    = "提高餐厅客流量10/小时" --技能描述
"employee" = {    -- 生效看板娘 1,主管,2厨师,3服务员,包厢服务员
    1 = "1"
    2 = "2"
    3 = "3"
    4 = "4"
}
"module"   = "1" --所属功能,0任何模块，1烹饪,2大堂,3外卖,4料理副本,5包厢
"name"     = "风靡一时" --技能名字
"skillId"  = "30074"	--技能id
"level"	   = 1
'maxLevel' = 10 --该技能可升级最大等级
"unlock"   = 0	--该技能是是否解锁 0：未解锁 1：解锁
--]]
--[[
--@extraData 是否存在传过来的特殊数据
{
from = 1 , 餐厅技能
from =2  , moduleId =  CARD_BUSINESS_SKILL_MODEL_COOKCHAPTER 或者  CARD_BUSINESS_SKILL_MODEL_PRIVATEROOM
from  = 3 所有
}
--{
--cardData = {} or
--}
--]]
function CommonUtils.GetBusinessSkillByCardId(cardId, extraData)
    local assistantInfos = CommonUtils.GetConfig('business', 'assistant', cardId)
    if assistantInfos and table.nums(assistantInfos) > 0 and assistantInfos.skill and table.nums(assistantInfos.skill) > 0 then
        local tempSkill = {}
        local skillData = assistantInfos.skill
        local cardData  = {}
        if extraData and extraData.cardData then
            cardData = extraData.cardData
        else
            cardData = app.gameMgr:GetCardDataByCardId(cardId)
        end
        local fromType = 1 --实始显示餐厅的技能类别
        if extraData and extraData.from then
            fromType = checkint(extraData.from)
        end
        local  moduleTable = nil
        if fromType == 1 then -- 只选取餐厅技能
            moduleTable = { CARD_BUSINESS_SKILL_MODEL_COOK  , CARD_BUSINESS_SKILL_MODEL_LOBBY , CARD_BUSINESS_SKILL_MODEL_TAKEWAY }
        elseif fromType == 2  then -- type 为2 只选取 料理副本  或者  包厢
            if not  extraData.moduleId  then --添加代码多老代码的兼容性
                moduleTable = {CARD_BUSINESS_SKILL_MODEL_COOKCHAPTER}
            else
                moduleTable = {extraData.moduleId }
            end
        elseif fromType == 3 then
            moduleTable = { CARD_BUSINESS_SKILL_MODEL_ALL }
        end
        for k, v in pairs(skillData) do
            local t   = {}
            t.skillId = v.skillId
            t.unlock  = 0
            if checkint(cardData.breakLevel) >= checkint(v.openBreakLevel) then
                t.unlock = 1
            end
            t.maxLevel                          = v.maxLevel
            t.openBreakLevel                    = v.openBreakLevel
            local assistantSkillData            = CommonUtils.GetConfig('business', 'assistantSkill', v.skillId)
            local descr       = assistantSkillData.descr
            local assistantSkillLevelEffectData = nil
            local _x , _y  = string.find(descr , '_client_num_')
            if _x then
                assistantSkillLevelEffectData  = CommonUtils.GetConfig('business', 'assistantSkillClientEffect', v.skillId)
            else
                assistantSkillLevelEffectData  = CommonUtils.GetConfig('business', 'assistantSkillEffect', v.skillId)
            end

            t.name                              = assistantSkillData.name
            local businessSkillLv               = 1
            if cardData.businessSkill[v.skillId] then
                businessSkillLv = checkint(cardData.businessSkill[v.skillId].level)
            end
            t.level             = businessSkillLv
            local allTargetId   = {}
            local allEffectNum  = {}
            local showEffectNum = {}
            if table.nums(checktable(assistantSkillData.type)) > 0 then
                local assistantTypes = assistantSkillData.type
                --当前一张卡的技能类型列表
                for i, v in ipairs(assistantTypes) do
                    local assistantSkillTypeData = CommonUtils.GetConfig('business', 'assistantSkillType', v.targetType)
                    if assistantSkillTypeData then
                        for index , moduleId  in pairs(moduleTable) do
                            if moduleId == CARD_BUSINESS_SKILL_MODEL_ALL or   checkint(assistantSkillTypeData.module)  ==  moduleId
                            or (fromType == 1  and CARD_BUSINESS_SKILL_MODEL_ALL ==  checkint(assistantSkillTypeData.module) ) then
                                t.module   = assistantSkillTypeData.module
                                t.employee = assistantSkillData.employee
                                showEffectNum.targetType = v.targetType
                                for j, vv in ipairs(v.targetId) do
                                    table.insert(allTargetId, vv)
                                end
                                if assistantSkillLevelEffectData  and assistantSkillLevelEffectData[i] then
                                    for k, vvv in pairs(assistantSkillLevelEffectData[i]) do
                                        if k == tostring(businessSkillLv) then
                                            local temp = {}
                                            for m, vvvv in ipairs(vvv) do
                                                table.insert(allEffectNum, vvvv)
                                                table.insert(temp, vvvv)
                                            end
                                            showEffectNum.effectNum = {}
                                            showEffectNum.effectNum = temp
                                            break
                                        end
                                    end
                                end
                                t.allEffectNum    = {}
                                t.allEffectNum    = showEffectNum

                                t.allTargetId     = {}
                                t.allTargetId     = allTargetId
                                local descr       = assistantSkillData.descr
                                local targetIdNum = table.nums(allTargetId)
                                if targetIdNum > 0 then
                                    if checkint(assistantSkillTypeData.module) == CARD_BUSINESS_SKILL_MODEL_PRIVATEROOM then
                                        local guestConf = CommonUtils.GetConfigAllMess('guest', 'privateRoom')
                                        if targetIdNum == 1 then
                                            descr = string.gsub(descr, '_target_id_', guestConf[tostring(allTargetId[1])].name)
                                        else
                                            for i = 1, targetIdNum do
                                                local str = descr
                                                descr     = string.gsub(descr, '_target_id_', guestConf[tostring(allTargetId[1])].name, 1)
                                            end
                                        end
                                    else
                                        if targetIdNum == 1 then
                                            descr = string.gsub(descr, '_target_id_', allTargetId[1])
                                        else
                                            for i = 1, targetIdNum do
                                                local str = descr
                                                descr     = string.gsub(str, '_target_id_', allTargetId[i], 1)
                                            end
                                        end
                                    end
                                end
                                local targetNum = table.nums(allEffectNum)
                                if targetNum > 0 then
                                    if targetNum == 1 then
                                        local x = allEffectNum[1]
                                        x       = tonumber(x)
                                        if x < 1 and x > 0 then
                                            x = x * 100
                                        end
                                        descr = string.gsub(descr, '_target_num_', tostring(x))
                                        descr = string.gsub(descr, '_client_num_', tostring(x))
                                    else
                                        for i = 1, targetNum do
                                            local x   = allEffectNum[i]
                                            x         = tonumber(x)
                                            if x < 1 and x > 0 then
                                                x = x * 100
                                            end
                                            descr = string.gsub(descr, '_target_num_', x, 1)
                                            descr = string.gsub(descr, '_client_num_', x, 1)
                                        end
                                    end
                                end
                                t.descr = descr
                                table.insert(tempSkill, t)
                                break
                            end
                        end
                    end
                end
            end
        end
        return tempSkill
    end
    return {}
end

--[[
    --@params cnDiscountNum 中文的折扣数据
    --@offNum 返回的off 折扣
--]]
function CommonUtils.GetDiscountOffFromCN(cnDiscountNum)
    cnDiscountNum = tonumber(cnDiscountNum)
    local offNum =  0
    if cnDiscountNum then
        cnDiscountNum  = cnDiscountNum > 1 and cnDiscountNum or  cnDiscountNum * 100
        -- if isElexSdk() then
            if i18n.getLang() == 'zh-tw' then
                offNum = math.floor(cnDiscountNum * 10)/100
            else
                offNum =  math.floor(100 - cnDiscountNum)
            end
        -- end
        return offNum
    end
    return  offNum
end

-- 创建顶部的icon
--[[{
       namePath = 'ui/home/nmain/main_btn_level_box.png',  -- 传入的参数
       tag = RemindTag.LEVEL_CHEST  , -- 设置跳转的tag 值
       name = "GIFT_"  ,  --
       font = __('等级礼包') ,
       countdown = 传入 , --传入证明有这一项 ,
       spineName ="" --有这一项的时候证明是有 spine 动画 否则默认为没有动画
    } ]]
-- 此处以封装一个创建顶部计时器的icon 一般的icon 不在内部处理
function CommonUtils.CreateTopIcon(data)
    if type(data) ~= "table" or table.nums(data) == 0 then
        -- 判断数据的合理性 添加容错的处理 注意自己的严谨性
        return
    end
    local btnSize   = cc.size(88, 110)
    local btn       = FilteredSpriteWithOne:create(_res(data.namePath))
    local btnLayout = display.newLayer(0, 0, { ap = display.CENTER_TOP, color1 = cc.r4b(), size = btnSize })
    btnLayout:addChild(btn)
    btn:setAnchorPoint(display.CENTER_TOP)
    btn:setPosition(cc.p(btnSize.width / 2, btnSize.height))
    btn:setName('btn')

    local touchLayer = display.newLayer(btnSize.width / 2, btnSize.height, {size = btn:getContentSize(), enable = true, color = cc.c4b(0, 0, 0, 0), ap = display.CENTER_TOP})
    btnLayout:addChild(touchLayer)
    if data.countdown and checkint(data.countdown) > 0 then
        -- 传入的倒计时 默认是认为不显示的 如果有先隐藏等刷新的时候显示出来
        local countdownImage = display.newImageView(_res('ui/home/nmain/main_maps_bg_countdown'))
        local imageSize      = countdownImage:getContentSize()
        local scale          = ( imageSize.width - 13 ) / imageSize.width -- 由于image是比较长的 所以要进行横向的缩放
        countdownImage:setScaleX(scale)
        -- 倒计时的容器
        local countdownLayoutSize = cc.size( ( imageSize.width - 13 ), imageSize.height)
        local countdownLayout     = display.newLayer(btnSize.width / 2, 15, { size = countdownLayoutSize, ap = display.CENTER } )
        countdownLayout:setName("countdownLayout")
        countdownLayout:setVisible(false)
        countdownLayout:addChild(countdownImage)
        btnLayout:addChild(countdownLayout)
        countdownImage:setPosition(cc.p(countdownLayoutSize.width / 2, countdownLayoutSize.height / 2 ))
        -- 倒计时的label
        local countdownLabel = display.newLabel(countdownLayoutSize.width / 2, countdownLayoutSize.height / 2, fontWithColor('10', { text = string.formattedTime(data.countdown, "%02i:%02i:%02i") }) )
        countdownLayout:addChild(countdownLabel)
        countdownLabel:setName("countdownLabel")
    end
    local tagNode = data.tag -- 当有tag 的时候 设置tag 值 没有tag的时候 设置name
    if tagNode and tonumber(tagNode) then
        tagNode = checkint(tagNode)
        btnLayout:setTag(tagNode )
        touchLayer:setTag(tagNode)
    end

    local nameNode = data.name
    if nameNode and type(nameNode) == 'string' then
        btnLayout:setName(nameNode )
        btn:setName(nameNode)
    end
    -- 根据spineName 加载spine 动画
    if data.spineName and type(data.spineName) == "string" and data.spineName ~= "" then
        local qAvatar = sp.SkeletonAnimation:create(string.format("%s.json", data.spineName), string.format("%s.atlas", data.spineName), 1.0)
        qAvatar:setPosition(utils.getLocalCenter(btn))
        qAvatar:setToSetupPose()
        qAvatar:setAnimation(0, 'idle', true)
        btn:addChild(qAvatar)
    end

    local iconImage = nil
    -- 根据icon 添加图片
    if data.iconData then
        local iconData = data.iconData
        local img      = iconData.img
        local offset   = iconData.offset or cc.p(0, 0)
        local scale    = iconData.scale or 1

        iconImage = FilteredSpriteWithOne:create(_res(img))
        iconImage:setPosition(cc.p(btnSize.width / 2 + offset.x, btnSize.height / 2 + offset.y))
        -- iconImage:setFilter(GrayFilter:create())
        iconImage:setScale(scale)
        btn:addChild(iconImage)
        iconImage:setName('iconImage')
    end

    -- dump(FilteredSpriteWithOne:create(_res(data.namePath)):getContentSize(), 'isNeedLockisNeedLock')
    if data.isNeedLock then
        local lockIcon = FilteredSpriteWithOne:create(_res('ui/common/common_ico_lock.png'))
        lockIcon:setPosition(cc.p(btnSize.width/2, btnSize.height/2 + 10))
        btnLayout:addChild(lockIcon)
        lockIcon:setName('lockIcon')

        btn:setFilter(GrayFilter:create())
        iconImage:setFilter(GrayFilter:create())
    end

    -- 设置显示字体的位置
    local label = display.newLabel(btnSize.width / 2, btnSize.height - btn:getContentSize().height - 7, fontWithColor(14, { text = data.font, fontSize = 24, outline = '4e2e1e' }))
    btn:addChild(label)
    -- local label       = btn:getLabel()
    local contentSize = display.getLabelContentSize(label)
    local scaleOne    = 88 / contentSize.width
    local scaleNum    = scaleOne > 1 and 1 or scaleOne
    label:setScale(scaleNum)

    return btnLayout

end
-- 设置顶部的倒计时 homeTop 的icon
function CommonUtils.SetHomeTopIconCountdownTime(btnLayout, countdown)
    if (not btnLayout and ( not talua.isnull(btnLayout)) and countdown  ) then
        -- 如果不满足下列条件就直接进行返回不做处理
        return
    end
    local nodeLayout = btnLayout:getChildByName("countdownLayout")
    if nodeLayout and (not tolua.isnull(nodeLayout)) then
        local label = nodeLayout:getChildByName("countdownLabel")
        display.commonLabelParams(label, { text = string.formattedTime(countdown, "%02i:%02i:%02i") } )
        nodeLayout:setVisible(true)
    end
end
-- 依据tag来删除list中的某一项
function CommonUtils.RemoveListViewNodeByTag(listView, tag)
    local typeNum = type(tag)
    if typeNum == "number" then
        local node = listView:getNodes()
        for i, v in pairs(node) do
            local tagNode = v:getTag()
            if tag == tagNode then
                -- 删除所要删除的node
                listView:removeNode(v)
                listView:reloadData()
                break
            end
        end
    end
end

-- 依据name来删除list中的某一项
function CommonUtils.RemoveListViewNodeByName(listView, name)
    local typeNum = type(name)
    if typeNum == "string" then
        local nodes = listView:getNodes()
        for i, v in pairs(nodes) do
            local nameNode = v:getName()
            if name == nameNode then
                -- 删除所要删除的node
                listView:removeNode(v)
                listView:reloadData()
                break
            end
        end
    end
end

--- 确定下次请求的时间倒计时
function CommonUtils.MakeSureNextRequestTime(time)
    local time = checkint(time)
    if time <= 0 then
        return time
    else
        if time < 300 then
            time = time + math.ceil(time / 60)
        end

    end
    return time
end


--- 开始时间 总时间  计算倒计时
function CommonUtils.DealWithCountTime(startTimes, countTimes)
    local socket       = require('socket')
    local curTime      = math.floor(socket.gettime())
    local distanceTime = math.floor(curTime - startTimes + 0.5)
    local countdown    = countTimes - distanceTime
    countdown          = countdown > 0 and countdown or countdown
    return countdown
end


--[[
保留n位小数
@params nNum int 需转换的数值
n int 保留小数的位数
--]]
function CommonUtils.GetPreciseDecimal(nNum, n)
    if type(nNum) ~= "number" then
        return nNum
    end
    local fmt = '%.' .. checkint(n) .. 'f'
    local nRet = tonumber(string.format(fmt, nNum))
    return nRet
end

--添加引导的封装   name 为模块的名称
function CommonUtils.GetGuideBtn(name)
    local guideBtn = display.newButton(0, 0, { n = _res('guide/guide_ico_book') })
    display.commonLabelParams(guideBtn, fontWithColor(14, { text = __('指南'), fontSize = 28, color = 'ffffff', offset = cc.p(10, -18) }))
    guideBtn:setOnClickScriptHandler(function(sender)
        if name then
            local guideNode = require('common.GuideNode').new({ tmodule = name })
            display.commonUIParams(guideNode, { po = display.center })
            sceneWorld:addChild(guideNode, GameSceneTag.Guide_GameSceneTag)
        end
    end)
    return guideBtn
end

--减少送外卖往返时间_target_num_秒
function CommonUtils.getReduceTakeWaysGoBackTime( reduceTime )
    -- body
    local reduceTime = reduceTime or 0
    local t          = app.restaurantMgr:GetAllAssistantBuff(CARD_BUSINESS_SKILL_MODEL_TAKEWAY)
    for i, v in ipairs(t) do
        for i, vv in ipairs(v) do
            if checkint(vv.allEffectNum.targetType) == RestaurantSkill.SKILL_TYPE_TAKEAWAY_DELIVERY_SPEED_UP_CONSTANT then
                local num  = CommonUtils.GetAssistantEffectNum( vv.allEffectNum )
                reduceTime = reduceTime - checkint(num)
            elseif checkint(vv.allEffectNum.targetType) == RestaurantSkill.SKILL_TYPE_TAKEAWAY_DELIVERY_SPEED_UP_PERCENT then
                local num  = CommonUtils.GetAssistantEffectNum( vv.allEffectNum )
                reduceTime = reduceTime * tonumber(num)
            end
        end
    end
    -- dump(reduceTime)
    return reduceTime
end
-- 处理魔法字符
--[[
    -- 参数
    data ={
        fontSize = "26"
        color = "#ffffff"
    }
    text = "" -- 文本的内容
--]]
function CommonUtils.dealWithEmoji(data, text )
    data            = data or {}
    data.color      = data.color or "#ffffff"
    data.fontSize   = data.fontSize or 24
    text            = text or " "
    local emojiData = nil

    if FTUtils.dealWithEmoji then
        local str = FTUtils:dealWithEmoji(text)
        emojiData = json.decode(str) or {}
        for k, v in pairs(emojiData) do
            v.fontSize = data.fontSize
            table.merge(v, clone(data) )
            v.text = v.text or ""
            if checkint(v.isEmoji) == 1 then
                v.color = "ffffff"
            end
        end
    else
        data.text = text
        emojiData = { data } -- 加工成c ={ { }}
    end
    if table.nums(emojiData) == 0 then
        data.text = text
        emojiData = {
            data
        }
    end
    return emojiData
end
-- 给richLabel 添加描边效果
function CommonUtils.AddRichLabelTraceEffect(richLable, color, outlinesize, indexData)
    if richLable and ( not tolua.isnull(richLable)) then
        color           = color or '#734441'
        outlinesize     = outlinesize or 2
        local nodeTable = richLable:getChildren()
        if indexData then
            for i = 1, #indexData do
                for k, v in pairs(nodeTable) do
                    if tolua.type(v) == "ccw.CLabel" and indexData[i] == k then
                        v:enableOutline(ccc4FromInt(color), outlinesize)
                        break
                    end
                end
            end
        else
            for k, v in pairs(nodeTable) do
                if tolua.type(v) == "ccw.CLabel" then
                    v:enableOutline(ccc4FromInt(color), outlinesize)
                end
            end
        end
    else
        return
    end
end
--[[
    ---@params richLable 富文本
    ---@params color 颜色
    ---@params outlinesize 描边宽度
    ---@params indexData 要描边字体的叙述集
--]]
function CommonUtils.AddRichLabelTraceEffectByStrings(richLable, color, outlinesize, indexData)
    if richLable and ( not tolua.isnull(richLable)) then
        color           = color or '#734441'
        outlinesize     = outlinesize or 2
        local nodeTable = richLable:getChildren()
        if indexData then
            for i = 1, #indexData do
                for k, v in pairs(nodeTable) do
                    if tolua.type(v) == "ccw.CLabel" then
                        local text = v:getString()
                        if text == tostring(indexData[i]) then
                            v:enableOutline(ccc4FromInt(color), outlinesize)
                        end
                        break
                    end
                end
            end
        else
            for k, v in pairs(nodeTable) do
                if tolua.type(v) == "ccw.CLabel" then
                    v:enableOutline(ccc4FromInt(color), outlinesize)
                end
            end
        end
    else
        return
    end
end


function CommonUtils.GetAssistantEffectNum( businessSkillData )
    -- dump(businessSkillData)
    local num               = 0
    local businessSkillType = checkint(businessSkillData.targetType)
    if businessSkillType == RestaurantSkill.SKILL_TYPE_RESTAURANT_TARGET_EVENT_DURATION_TIME_INCREASE then
        --4特殊事件_target_id_持续时间增加_target_num_秒
    elseif businessSkillType == RestaurantSkill.SKILL_TYPE_RESTAURANT_VIGOUR_MAX_INCREASE then
        --6在餐厅中工作的新鲜度提高_target_num_点
        num = tonumber(businessSkillData.effectNum[1])
    elseif businessSkillType == RestaurantSkill.SKILL_TYPE_TAKEAWAY_DELIVERY_SPEED_UP_CONSTANT then
        --7减少送外卖往返时间_target_num_秒
        num = tonumber(businessSkillData.effectNum[1])
    elseif businessSkillType == RestaurantSkill.SKILL_TYPE_TAKEAWAY_DELIVERY_SPEED_UP_PERCENT then
        --8减少送外卖往返时间_target_num_%秒
        num = tonumber(businessSkillData.effectNum[1])
    elseif businessSkillType == RestaurantSkill.SKILL_TYPE_RESTAURANT_WAITER_SWITCH_CD then
        --14作为服务员的准备时间降低_target_num_秒
        num = tonumber(businessSkillData.effectNum[1])

    elseif businessSkillType == RestaurantSkill.SKILL_TYPE_RESTAURANT_COOKING_STYLE_MAKING_LIMIT_INCREASE then
        --23;--飨灵在厨房使用_target_id_菜系中的食谱单次制作数量上限提高_target_num_个
        num = tonumber(businessSkillData.effectNum[1])
    elseif businessSkillType == RestaurantSkill.SKILL_TYPE_RESTAURANT_COOKING_STYLE_MAKING_TIME_DECREASE then
        --24;--飨灵在厨房使用_target_id_菜系中的食谱制作时间降低_target_num_%
        num = tonumber(businessSkillData.effectNum[1])

    elseif businessSkillType == RestaurantSkill.SKILL_TYPE_RESTAURANT_MAKING_LIMIT_INCREASE then
        --25；飨灵在厨房中制作食物时,单次制作数量上限提高_target_num_个
        num = tonumber(businessSkillData.effectNum[1])
    elseif businessSkillType == RestaurantSkill.SKILL_TYPE_RESTAURANT_MAKING_TIME_DECREASE then
        --26;--飨灵在厨房中制作食物时,制作时间降低_target_num_%
        num = tonumber(businessSkillData.effectNum[1])
    elseif businessSkillType == RestaurantSkill.SKILL_TYPE_RESTAURANT_SHOP_WINDOW_MAX_INCREASE then
        --27;--餐厅的橱窗出售食物数量上限提高_target_num_个
        num = tonumber(businessSkillData.effectNum[1])
    elseif businessSkillType == RestaurantSkill.SKILL_TYPE_TASTING_TOUR_ADD_JUDGE_MOOD_EFFECT then
        --减少料理副本再挑战时间_target_num_点
        num = tonumber(businessSkillData.effectNum[1])
    end
    -- dump(num)
    return num
end


--[[
按照品质 星级 等级 灵力刷一次排序
@params t 目标table
--]]
function CommonUtils.sortCard(t)
    table.sort(t, function (a, b)
		local acardId = checkint(a.cardId)
		local bcardId = checkint(b.cardId)

		local acardConf = CardUtils.GetCardConfig(acardId)
		local bcardConf = CardUtils.GetCardConfig(bcardId)

		if acardConf and bcardConf then
			if checkint(acardConf.qualityId) == checkint(bcardConf.qualityId) then
				if checkint(a.breakLevel) == checkint(b.breakLevel) then
					if checkint(a.level) == checkint(b.level) then
						return checkint(acardId) < checkint(bcardId)
					else
						return checkint(a.level) > checkint(b.level)
					end
				else
					return checkint(a.breakLevel) > checkint(b.breakLevel)
				end
			else
				return checkint(acardConf.qualityId) > checkint(bcardConf.qualityId)
			end
		else
			return checkint(acardId) < checkint(bcardId)
		end
	end)
end

--[[
--通用解锁条件判断的逻辑
--unlockInfos = {
--  '1' = {targetId = xx, targetNum = xx}
--}
--]]
function CommonUtils.CheckLockCondition(unlockInfos)
    local isLocked = false
    if not unlockInfos then
        unlockInfos = {}
    end
    for id, val in pairs(unlockInfos) do
        local pType = checkint(id)
        if pType == UnlockTypes.PLAYER then
            if checkint(app.gameMgr:GetUserInfo().level) < checkint(val.targetNum) then
                isLocked = true
                --一个条件不满足时直接锁定
                break
            end
        elseif pType == UnlockTypes.GOLD then
            if checkint(app.gameMgr:GetUserInfo().gold) < checkint(val.targetNum) then
                isLocked = true
                break
            end
        elseif pType == UnlockTypes.DIAMOND then
            if checkint(app.gameMgr:GetUserInfo().diamond) < checkint(val.targetNum) then
                isLocked = true
                break
            end
        elseif pType == UnlockTypes.GOODS then
            if checkint(val.targetId) > 0  then
                local num = CommonUtils.GetCacheProductNum(val.targetId)
                if num < checkint(val.targetNum) then
                    isLocked = true
                    break
                end
            end
        elseif pType == UnlockTypes.AS_LEVEL then
            if checkint(app.gameMgr:GetUserInfo().restaurantLevel) < checkint(val.targetNum) then
                isLocked = true
                break
            end
        elseif pType == UnlockTypes.TASK_QUEST then
            if checkint(app.gameMgr:GetUserInfo().newestPlotTask.taskId) < checkint(val.targetNum) then
                isLocked = true
                break
            elseif checkint(app.gameMgr:GetUserInfo().newestPlotTask.taskId) == checkint(val.targetNum) then
                if checkint(app.gameMgr:GetUserInfo().newestPlotTask.status) == 0 then
                    isLocked = true
                    break
                end
            end
        elseif pType == UnlockTypes.TASK_BRANCH then
            local data = app.gameMgr:GetUserInfo().branchList
            if not data or not data[tostring(val.targetNum)] or checkint(data[tostring(val.targetNum)].status) ~= 3 then
                isLocked = true
                break
            end
        elseif pType == UnlockTypes.AREA then
            if checkint(app.gameMgr:GetUserInfo().newestAreaId) < checkint(val.targetNum) then
                isLocked = true
                break
            end
        elseif pType == UnlockTypes.FAVORABILITY_LEVEL then
            local cardDatas = app.gameMgr:GetCardDataByCardId(val.targetId)
            if cardDatas and checkint(val.targetNum) > checkint(cardDatas.favorabilityLevel) then
                isLocked = true
                break
            end
        elseif pType == UnlockTypes.UNION_PLAYER_CONTRIBUTIONPOINT then
            if app.unionMgr:getUnionData() and app.unionMgr:getUnionData().contributionPoint then
                if checkint(val.targetNum) > checkint(app.unionMgr:getUnionData().contributionPoint) then
                    isLocked = true
                    break
                end
            else
                isLocked = true
                break
            end
        elseif pType == UnlockTypes.UNION_LEVEL then
            if app.unionMgr:getUnionData() and app.unionMgr:getUnionData().level then
                if checkint(val.targetNum) > checkint(app.unionMgr:getUnionData().level) then
                    isLocked = true
                    break
                end
            else
                isLocked = true
                break
            end
        end
    end
    -- if table.nums(unlockInfos) <= 0 then
    --     isLocked = true --直接锁定
    -- end
    return isLocked
end


--==============================--
--desc: 累积计算Vip表中的某个字段
--field: vip表中需要累积计算的 字段名称
--@return
--==============================--
function CommonUtils.getVipTotalLimitByField(field)
    if field == nil then
        print('传入的field 为nil')
        return field
    end
    local totalField = CommonUtils.GetConfig('player', 'vip', 1)[field]
    if totalField == nil then
        print(string.format('vip.json 中没有%s字段', field))
        return totalField
    end
    if type(totalField) ~= 'number' then
        if nil == tonumber(totalField) then
            print(string.format('从vip.json 获取的数据为 %s, 不是number 类型 不能累计计算', type(totalField)))
            return totalField
        end
    end
    local member = app.gameMgr:GetUserInfo().member
    if table.nums(member) > 0 then
        local config = CommonUtils.GetConfigAllMess('vip','player')

        for i, v in pairs(config) do
            if member[tostring(v.vipLevel)] then
                totalField = checknumber(totalField) + checknumber( v[field])
            end
        end
    end
    return totalField
end

--[[
根据卡牌id判断装备的堕神是否是专属堕神
解析指南描述
@params desc 描述
]]
function CommonUtils.parserGuideDesc(desc, fontSize)
    if desc == nil or desc == '' then return '' end

    local labelparser = require("Game.labelparser")
    local parsedtable = labelparser.parse(desc)
    local result = {}
    for name, val in ipairs(parsedtable) do
        table.insert(result, val.content)

    end
    return table.concat(result)
end


--==============================--
--desc:检测遇到怪物的条件
--time:2017-07-26 03:46:16
--@stage:
--type  1、伴生2、普通3、异化4、特型
--@return
--==============================--
function CommonUtils.CheckEncounterMonster(stageId)
    local questMonstion        = CommonUtils.GetConfigAllMess('questMonster', 'collection')
    local monsterInfo          = CommonUtils.GetConfigAllMess('monster', 'collection')
    -- 怪物信息表
    local questMonstionOneData = questMonstion[tostring(stageId)] or {}
    if #questMonstionOneData then
        for k, v in pairs(questMonstionOneData) do
            if app.gameMgr:GetUserInfo().monster[tostring(k)] then
                if app.gameMgr:GetUserInfo().monster[tostring(k)] ~= 3 then
                    if monsterInfo[tostring(k)] then
                        -- 检测该表中是否出现此怪物
                        if checkint(monsterInfo[tostring(k)].type ) == 1 then
                            app.gameMgr:GetUserInfo().monster[tostring(k)] = 3
                        end
                    end

                end
            else

                if monsterInfo[tostring(k)] then
                    if checkint(monsterInfo[tostring(k)].type ) == 1 then
                        app.gameMgr:GetUserInfo().monster[tostring(k)] = 3
                    else
                        app.gameMgr:GetUserInfo().monster[tostring(k)] = 2
                    end
                end

            end
        end
    end
end


--[[
根据类型 获得时间格式
@params seconds 秒
@params type_    类型
--]]
function CommonUtils.getTimeFormatByType(seconds, type_)
    type_ = checkint(type_)
    local c = ''
    local DAY = 86400
    local HOUR = 3600
    local MINUTES = 60
    if type_ == 0 then
        if seconds >= DAY then
            local day  = math.floor(seconds / DAY)
			local hour = math.floor((seconds % DAY) / HOUR)

            c = string.fmt(__('_num1_天_num2_小时'), {['_num1_'] = tostring(day), ['_num2_'] = tostring(hour)})
        else
            local hour   = math.floor(seconds / HOUR)
			local minute = math.floor((seconds - hour * HOUR) / MINUTES)
			local sec    = (seconds - hour * HOUR - minute * MINUTES)

            c = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
        end
    elseif type_ == 1 then
        if seconds >= DAY then
            c = string.fmt(__('_num1_天'), {['_num1_'] = math.floor(seconds / DAY)})
        elseif seconds < DAY and seconds >= HOUR then
            c =  string.fmt(__('_num1_小时'), {['_num1_'] = math.floor(seconds / HOUR)})
        elseif seconds < HOUR and seconds >= MINUTES then
            c =  string.fmt(__('_num1_分钟'), {['_num1_'] = math.floor((seconds / MINUTES) % MINUTES)})
        else
            c = string.fmt(__('_num1_秒'), {['_num1_'] = seconds})
        end
    elseif type_ == 2 then
        if seconds >= DAY then
            local day = math.floor(seconds / DAY)
            c = string.fmt(__('_num1_天'), {['_num1_'] = tostring(day)})
        else
            local hour   = math.floor(seconds / HOUR)
			local minute = math.floor((seconds - hour * HOUR) / MINUTES)
			local sec    = (seconds - hour * HOUR - minute * MINUTES)
            c = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
        end
    elseif type_ == 3 then
        if seconds >= DAY then
            local day = math.floor(seconds / DAY)
            local hour = math.floor((seconds % DAY) / HOUR)
            if hour > 0 then
                c = string.fmt(__('_num1_天_num2_小时'), {['_num1_'] = tostring(day), ['_num2_'] = tostring(hour)})
            else
                c = string.fmt(__('_num1_天'), {['_num1_'] = tostring(day)})
            end
        elseif seconds < DAY and seconds >= HOUR then
            local hour   = math.floor(seconds / HOUR)
			local minute = math.floor((seconds - hour * HOUR) / MINUTES)
            if minute > 0 then
                c = string.fmt(__('_num1_小时_num2_分钟'), {['_num1_'] = tostring(hour), ['_num2_'] = tostring(minute)})
            else
                c = string.fmt(__('_num1_小时'), {['_num1_'] = tostring(hour)})
            end
        else
            local hour   = math.floor(seconds / HOUR)
			local minute = math.floor((seconds - hour * HOUR) / MINUTES)
			local sec    = (seconds - hour * HOUR - minute * MINUTES)
            c = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
        end
    end
    return c
end

--[[
    跳转到指定的cell 下标位置
    @params listHeight    列表高度
    @params listLen       列表长度
    @params cellHeight    cell height
    @params cellIndex     cell index
    @params isTop         是否置顶
--]]
function CommonUtils.calcListContentOffset(listHeight, listLen, cellHeight, cellIndex, isTop)
    if listLen < cellIndex then return end
    isTop = isTop == nil and true or isTop
    local offsetH = math.min(listHeight - listLen * cellHeight, 0)
    local idx = cellIndex - 1
    local cellOffsetH = isTop and 0 or (cellHeight - listHeight)
    -- 列表容器总高度
    local needJumpCellTotalHeight = idx * cellHeight + cellOffsetH
    -- 被隐藏的容器高度
    if offsetH < 0 and needJumpCellTotalHeight > 0 then
        offsetH = math.min((offsetH + needJumpCellTotalHeight), 0)
    end
    return offsetH
end

function CommonUtils.checkIsExistsSpine(spineJson, spineAtlas)
    return utils.isExistent(spineJson) and utils.isExistent(spineAtlas)
end

--[[
本地保存的队伍信息
--]]
function CommonUtils.getLocalDatas(localTeamDataKey)
	local str = cc.UserDefault:getInstance():getStringForKey(tostring(app.gameMgr:GetUserInfo().playerId) .. localTeamDataKey, '')
	local teamMembers = json.decode(str)
	return teamMembers
end
function CommonUtils.setLocalDatas(data, localTeamDataKey)
	local str = json.encode(data)
	cc.UserDefault:getInstance():setStringForKey(tostring(app.gameMgr:GetUserInfo().playerId) .. localTeamDataKey, str)
	cc.UserDefault:getInstance():flush()
end

----------------------------------
-- ui

--[[
获得通用界面底层
@params params table {
    bgSize cc.size 底层大小
    contentBgSize cc.size 背景上的底大小
    po cc.p 背景上的底位置
    tag int 背景上的底的tag
}
@return bg CImageView
--]]
function CommonUtils.getCommonLayerBg(params)
    params       = params or {}
    local bgSize = params.bgSize or cc.size(626, 674)
    local view   = display.newLayer(0, 0, { size = bgSize, ap = cc.p(0.5, 0.5) })
    --local bgShadowWidth = 2
    -- local contentBgSize = cc.size(bgSize.width - 2 * bgShadowWidth, 511)
    -- if params.contentBgSize then
    -- 	contentBgSize = cc.size(params.contentBgSize.width - 2 * bgShadowWidth, params.contentBgSize.height)
    -- end
    -- local po = cc.p(bgSize.width * 0.5, bgSize.height * 0.47)
    -- if params.po then
    -- 	po = cc.p(bgSize.width * params.po.x, bgSize.height * params.po.y)
    -- end  property
    local bg     = display.newImageView(_res('ui/cards/property/common_bg_1.png'), utils.getLocalCenter(view).x, utils.getLocalCenter(view).y)
    -- ,{scale9 = true, size = bgSize})
    view:addChild(bg)

    -- local contentBg = display.newImageView(_res('ui/common/common_bg_botton-m.png'), po.x, po.y,
    -- 	{scale9 = true, size = contentBgSize, po = po})
    if params.tag then
        bg:setTag(params.tag)
    end
    -- view:addChild(contentBg)
    return view
end
--[[
获得通用弹窗底层
@params params table {
    bgSize cc.size 底层大小
    contentBgSize cc.size 背景上的底大小
    tag int 背景上的底的tag
    closeCallback function 关闭按钮回调
}
@return bg CImageView
--]]
function CommonUtils.getCommonPopupBg(params)
    params       = params or {}
    local bgSize = params.bgSize or cc.size(386, 300)
    -- local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})

    local view   = CLayout:create()
    view:setPosition(0, 0)
    view:setAnchorPoint(display.CENTER)
    view:setContentSize(bgSize)
    -- local bgShadowWidth = 2
    -- local contentBgSize = cc.size(bgSize.width - 2 * bgShadowWidth, bgSize.height * 0.85)
    -- if params.contentBgSize then
    -- 	contentBgSize = cc.size(params.contentBgSize.width - 2 * bgShadowWidth, params.contentBgSize.height)
    -- end

    local bg = display.newImageView(_res('ui/common/common_bg_10.png'), 0, 0,
                                    { ap = cc.p(0, 0) })--scale9 = true, size = bgSize,
    view:addChild(bg)
    bg:setTouchEnabled(true)

    -- local contentBg = display.newImageView(_res('ui/common/common_bg_botton-s.png'), bgSize.width * 0.5, 0,
    -- 	{scale9 = true, size = contentBgSize, ap = cc.p(0.5, 0)})
    -- view:addChild(contentBg)
    -- if params.tag then
    -- 	contentBg:setTag(params.tag)
    -- end
    -- local closeBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_white_off_l.png')})
    -- if params.closeCallback then
    -- 	display.commonUIParams(closeBtn, {cb = params.closeCallback})
    -- end
    -- display.commonUIParams(closeBtn, {po = cc.p(bgSize.width - closeBtn:getContentSize().width * 0.5 - 15,
    -- 	bgSize.height - closeBtn:getContentSize().height * 0.5 - 15)})
    -- view:addChild(closeBtn)
    return view
end

--[[
获得道具在列表中的下标
@params params table {
    index int 道具下标
    goodNodeSize cc.size 道具大小
    midPointX int 列表中点X坐标
    midPointY int 列表中点Y坐标
    col int 列数
    maxCol int 最大列数
    scale int 道具缩放比例
    goodGap int 道具之间间隔
}
@return pos
--]]
function CommonUtils.getGoodPos(data)
    local index        = data.index or 1
    local goodNodeSize = data.goodNodeSize or cc.size(0, 0)
    local midPointX    = data.midPointX or 0
    local midPointY    = data.midPointY or 0
    local col          = data.col or 1
    local maxCol       = data.maxCol or 1
    local scale        = data.scale or 1
    local goodGap      = data.goodGap or 10

    local goodW, goodH = goodNodeSize.width * scale + goodGap, goodNodeSize.height * scale + goodGap

    local realIndex    = (index - 1) % maxCol + 1
    local startX       = midPointX - (col - 1) * (goodW / 2)
    local x            = startX + (realIndex - 1) * goodW

    local curRow       = math.floor((index - 1) / maxCol)

    local goodOffsetY  = goodH
    local y            = midPointY - curRow * goodOffsetY
    return cc.p(x, y)
end

--[[
获得道具列表
@params params table {
    parent node 道具父视图
    midPointX int 列表中点X坐标
    midPointY int 列表中点Y坐标
    maxCol int 最大列数
    scale int 道具缩放比例
    hideDesc bool 隐藏点击 道具 时的弹窗
    hideAmount bool 隐藏道具数量
    rewards    table 奖励列表
    hideCustomizeLabel bool 隐藏 自定义底部标签
    showOwnNum bool 限制拥有数量为1的,如果已经拥有,显示拥有数量
}
@return goodNodes customizeLbs
--]]
function CommonUtils.createPropList(data)
    if data == nil then
        print('传入数据为空')
        return
    end
    local parent = data.parent
    if parent == nil then
        print('parent 为 nil')
        return
    end
    local goodNodeSize       = nil
    local goodCreateClass    = require('common.GoodNode')
    local midPointX          = checkint(data.midPointX)
    local midPointY          = checkint(data.midPointY)
    local maxCol             = data.maxCol or 1
    local scale              = data.scale or 1
    local hideDesc           = checkbool(data.hideDesc)
    local hideCustomizeLabel = checkbool(data.hideCustomizeLabel)
    local hideAmount         = checkbool(data.hideAmount)
    local rewards            = checktable(data.rewards)
    local isShowOwn          = checkbool(data.showOwnNum)
    local goodClickCallBack  = data.callBack
    local goodCount          = #rewards
    local col                = (goodCount > maxCol) and maxCol or goodCount
    local goodGap            = data.goodGap or 10
    local needScroll         = data.needScroll
    local customizeLabelH    = hideCustomizeLabel and 0 or 20

    local showAmount         = true
    if not hideCustomizeLabel then
        showAmount = false
    else
        showAmount = not hideAmount
    end

    -- 所有的道具节点
    local goodNodes    = {}
    -- 所有的 自定义标签
    local customizeLbs = {}

    -- calculate goodNodeSize
    if goodNodeSize == nil then
        local tempGoodNode  = goodCreateClass.new({})
        goodNodeSize        = tempGoodNode:getContentSize()
    end
    goodNodeSize = cc.size(goodNodeSize.width * scale, goodNodeSize.height * scale)

    -- calculate scrollViewSize
    local scrollView     = nil
    local goodParent     = parent
    local goodParentSize = parent:getContentSize()
    if needScroll then
        scrollView = ui.scrollView({size = cc.size(midPointX * 2, midPointY * 2 - 20), dir = display.SDIR_V})
        parent:addList(scrollView):alignTo(nil, ui.lb, {offsetY = 3})
        goodParent = scrollView:getContainer()

        -- calculate size
        goodNodeSize.height = goodNodeSize.height + customizeLabelH
        goodParentSize = cc.size(midPointX * 2, math.max(midPointY * 2 -20, 10 + (goodNodeSize.height + goodGap) * math.ceil(goodCount / col)))

        scrollView:setContainerSize(goodParentSize)
    end

    local function getGoodPos(index)
        local goodGap      = goodGap or 10
        local goodW, goodH = goodNodeSize.width + goodGap, goodNodeSize.height + goodGap

        local cellCol = (index - 1) % maxCol + 1
        local cellRow = math.floor((index - 1) / maxCol) + 1

        local startX = (goodParentSize.width - col * goodW + goodGap) * 0.5

        local x = startX + (cellCol - 1) * goodW + goodNodeSize.width * 0.5
        local y = goodParentSize.height - (cellRow - 0.5) * goodH - 4 + customizeLabelH / 2
        return cc.p(x, y)
    end

    for i, v in ipairs(rewards) do
        local goodNode = nil
        local goodsId  = v.goodsId

        local callBack = nil
        if not hideDesc then
            callBack = goodClickCallBack or function(sender)
                app.uiMgr:ShowInformationTipsBoard({ targetNode = sender, iconId = sender.goodId, type = 1 })
            end
        end

        goodNode = goodCreateClass.new({ id = goodsId, amount = v.num, showAmount = showAmount, callBack = callBack, scale = scale })
        local goodPos = needScroll and getGoodPos(i) or CommonUtils.getGoodPos({index = i, goodNodeSize = goodNodeSize, midPointX = midPointX, 
                        midPointY = midPointY, col = col, maxCol = maxCol, scale = 1, goodGap = goodGap})

        if not hideCustomizeLabel or isShowOwn then
            -- 1. 计算 父视图的高度
            local parentH = parent:getContentSize().height
            -- 2. lbposy (父视图的高度 - 道具高度) / 4
            local lbPosY  = (parentH - goodNodeSize.height * scale) / 4
            if needScroll then
                lbPosY = goodPos.y - goodNodeSize.height * 0.5 - goodGap
            else
                goodPos = cc.p(goodPos.x, goodPos.y + lbPosY)
            end
            
            local textLb = nil
            if not hideCustomizeLabel then
                textLb  = display.newRichLabel(goodPos.x, lbPosY + 5, { ap = display.CENTER, sp = 5 })
            else
                textLb = ui.label({fnt = FONT.D16, text = "--", fontSize = 18, p = cc.p(goodPos.x, lbPosY + 5)})
            end
            goodParent:addChild(textLb)

            table.insert(customizeLbs, { lb = textLb, amount = v.num, goodsId = goodsId })
        end
        goodNode:setPosition(goodPos)

        goodParent:addChild(goodNode)

        table.insert( goodNodes, goodNode)
    end

    if scrollView then
        scrollView:setContentOffsetToTop()
    end

    return goodNodes, customizeLbs

end


--[[
    设置推送的消息
--]]
function CommonUtils.SetPushNoticeStatus(isOpen)
    cc.UserDefault:getInstance():setStringForKey(app.gameMgr:GetUserInfo().playerId ..  'PUSH_NOTICE' , tostring(isOpen))
    cc.UserDefault:getInstance():flush()
    if checkint(isOpen ) > 0  then
        -- 设置打开的时候根据内存情况更新
        for k , v in pairs (PUSH_LOCAL_NOTICE_NAME_TYPE) do
            local isOpen = CommonUtils.GetPushLocalNoticeStatusByType(v)
            print(k  , isOpen)
            CommonUtils.SetPushLocalNoticeStatusByType(v ,isOpen and 1 or 0)
        end
    else
        for k , v in pairs (PUSH_LOCAL_NOTICE_NAME_TYPE) do
            print(k )
            -- 设置关闭的时候全部取消
            CommonUtils.CancelPushLocalNoticeByType(v )
        end
    end
end
--[[
    获取推送通知是否打开
--]]
function CommonUtils.GetPushNoticeIsOpen()
    local isOpenPush = false
    if device.platform == 'ios' then
        --isOpenPush = FTUtils:isIosNotificationEnabled()
        isOpenPush =  cc.UserDefault:getInstance():getStringForKey(app.gameMgr:GetUserInfo().playerId ..  'PUSH_NOTICE' , tostring(IS_OPEN.OPEN))
        if checkint(isOpenPush) > 0 then
            isOpenPush = true
        else
            isOpenPush = false
        end
    else
        isOpenPush =  cc.UserDefault:getInstance():getStringForKey(app.gameMgr:GetUserInfo().playerId ..  'PUSH_NOTICE' , tostring(IS_OPEN.OPEN))
        if checkint(isOpenPush) > 0 then
            isOpenPush = true
        else
            isOpenPush = false
        end
    end
    return isOpenPush
end

function CommonUtils.CancelLocalNotification(name)
    if device.platform == "android" then

    else
        FTUtils:cancelLocalNotification(name)
    end
end
--[[
    取消对应的推送id
--]]
function CommonUtils.CancelPushLocalNoticeByType(id )
    local name  = PUSH_LOCAL_NOTICE_TYPE_NAME[tostring(id)]
    local onePushTable = PUSH_LOCAL_TIME_NOTICE[name]
    for k , v in pairs(onePushTable) do
        CommonUtils.CancelLocalNotification(v.name)
    end
end
--[[
    设置游戏是否打开
--]]
function CommonUtils.SetPushLocalOneTypeNoticeByType(id)
    if not  CommonUtils.GetPushNoticeIsOpen() then
        return
    end
    local isOpen = CommonUtils.GetPushLocalNoticeStatusByType(id)
    if not isOpen then
        return
    end
    local name  = PUSH_LOCAL_NOTICE_TYPE_NAME[tostring(id)]
    local onePushTable = PUSH_LOCAL_TIME_NOTICE[name]
    for i , v in pairs(onePushTable) do
        CommonUtils.CancelLocalNotification(v.name)
        local titleText   = v.titleFunc and v.titleFunc() or '--'
        local messageText = v.messageFunc and v.messageFunc() or '---'
        if v.isRepeat then  -- 是每日推送还是之推送一次
            local hours =  l10nHours(v.time):fmt('%H')
            local pushData = { category = "fixTime" , message = messageText  , title = titleText or "" , id = v.name  ,isRepeat =   v.isRepeat ,  delayMs = checkint(hours)  }
            FTUtils:pushLocalNotification(json.encode(pushData))
        else
            local time = CommonUtils.GetPushCountDownTimesByType(id)
            if checkint(time) > 0   then
                local pushData = { category = "nofixTime" , message = messageText  , title = titleText or "" , id = v.name  ,isRepeat =   v.isRepeat ,  delayMs = time * 1000 }
                FTUtils:pushLocalNotification(json.encode(pushData))
            end
        end
    end
end
--[[
    根据推送的type
--]]
function CommonUtils.GetPushCountDownTimesByType(id)
    local time = nil
    if id == PUSH_LOCAL_NOTICE_NAME_TYPE.AIR_LIFT_RECOVER_TYPE then
        time =  app.gameMgr:GetUserInfo().nextAirshipArrivalLeftSeconds
    elseif id == PUSH_LOCAL_NOTICE_NAME_TYPE.HP_RECOVER_TYPE then
        local curHp = app.gameMgr:GetUserInfo().hp
        local hpMaxLimit = app.gameMgr:GetHpMaxLimit()
        local distance  =  hpMaxLimit - curHp
        if distance > 0 then
            time = app.gameMgr:GetUserInfo().nextHpSeconds + (distance - 1) * app.gameMgr:GetUserInfo().hpRecoverSeconds
        end
    end
    return  time
end
--[[
    根据id 存入本地标识
--]]
function CommonUtils.SetPushLocalNoticeStatusByType(id , isOpen )
    local playerId = app.gameMgr:GetUserInfo().playerId
    cc.UserDefault:getInstance():setStringForKey(playerId .. "_" .. PUSH_LOCAL_NOTICE_TYPE_NAME[tostring(id)] , tostring(isOpen))
    cc.UserDefault:getInstance():flush()
    -- 设置具体某一项的通知具体信息

    if isOpen > 0 then
        CommonUtils.SetPushLocalOneTypeNoticeByType(id)
    else
        CommonUtils.CancelPushLocalNoticeByType(id)
    end
end
--[[
    根据id 获取到通知的状态
--]]
function CommonUtils.GetPushLocalNoticeStatusByType(id)
    local playerId = app.gameMgr:GetUserInfo().playerId
    local isOpen =  cc.UserDefault:getInstance():getStringForKey(playerId .. "_" .. PUSH_LOCAL_NOTICE_TYPE_NAME[tostring(id)] ,  tostring(IS_OPEN.OPEN))
    if checkint(isOpen) > 0   then
        isOpen = true
    else
        isOpen = false
    end
    return isOpen
end
--[[
    获取到成就奖励的道具图片
--]]
function CommonUtils.GetAchieveRewardsGoodsSpineActionById(id)
    local achieveData = CommonUtils.GetConfigAllMess('achieveReward', 'goods')
    local achieveOneData = achieveData[tostring(id)]
    local  spineAnimation = nil
    if achieveOneData then
        if achieveOneData.specialEffectPath  then
            local length = string.len( achieveOneData.specialEffectPath)
            if length > 0 then
                local jsonPath = utils.isExistent(_res(string.format('ui/home/infor/effect/%s.json' ,achieveOneData.specialEffectPath )))
                local atlasPath =  utils.isExistent(_res(string.format('ui/home/infor/effect/%s.atlas' ,achieveOneData.specialEffectPath )))
                if atlasPath and jsonPath then
                    spineAnimation = sp.SkeletonAnimation:create(
                            string.format('ui/home/infor/effect/%s.json' ,achieveOneData.specialEffectPath ) ,
                            string.format('ui/home/infor/effect/%s.atlas' , achieveOneData.specialEffectPath)  ,
                            1
                    )
                    if achieveOneData.specialEffectId and string.len ( achieveOneData.specialEffectId) then
                        spineAnimation:setAnimation(0, achieveOneData.specialEffectId, true)
                        spineAnimation:setName("spineAnimation")
                    end
                end
            end
        end
    end
    return spineAnimation
end
--[[
    设置飨灵名字label的内容
    @param id 卡牌自增id
    @param params table {
        color:string            -- 3f color e.g:'#FFCC00'
        colorN:string           -- 3f color e.g:'#FFCC00' 系统字体颜色
        font:string             -- font地址
        fontSize:int            -- font size, @see ccDefines#FontsSize
        fontSizeN:int           -- font size, @see ccDefines#FontsSize 系统字体字号
        outline:string          -- 描边颜色
        outlineSize:int         -- 描边宽度
        outlineSizeN:int        -- 系统字体描边宽度
    }
    @param text 文字 固定使用ttf
--]]
function CommonUtils.SetCardNameLabelStringById(label, id, params, text)
    if text then
        CommonUtils.SetCardNameLabelStringByIdUseTTF(label, id, params, text)
        return
    end
    local curCardName  = CommonUtils.GetCardNameById(id)
    local cardId       = checkint(checktable(app.gameMgr:GetCardDataById(id)).cardId)
    local cardConf     = CONF.CARD.CARD_INFO:GetValue(cardId)
    local confCardName = tostring(cardConf.name)
    if confCardName ~= curCardName then
    -- if app.cardMgr.GetCouple(id) and (not app.cardMgr.IsLinkCardIdById(id)) then
        CommonUtils.SetCardNameLabelStringByIdUseSysFont(label, id, params, curCardName)
    else
        CommonUtils.SetCardNameLabelStringByIdUseTTF(label, id, params, curCardName)
    end
end
--[[
    使用系统字体设置飨灵名字label的内容
--]]
function CommonUtils.SetCardNameLabelStringByIdUseSysFont(label, id, params, text)
    label:setTTFConfig({})

    local fontSize = math.max(1, checkint(params.fontSize))
    if params.fontSizeN then
        fontSize = params.fontSizeN
    end
    label:setSystemFontSize(checkint(fontSize))

    if params.colorN then
        if type(params.colorN) == 'string' then
            label:setColor(ccc3FromInt(params.colorN))
        else
            label:setColor(params.colorN)
        end
    end
    if not params.colorN and params.color then
        if type(params.color) == 'string' then
            label:setColor(ccc3FromInt(params.color))
        else
            label:setColor(params.color)
        end
    end
    if params.outline then
        local outlineSize = math.max(1, checkint(params.outlineSize))
        if params.outlineSizeN then
            outlineSize = params.outlineSizeN
        end
        if type(params.outline) == 'string' then
            label:enableOutline(ccc4FromInt(params.outline), outlineSize)
        else
            label:enableOutline(params.outline, outlineSize)
        end
    end
    label:setString(text)
end

function CommonUtils.IsGoldSymbolToSystem()
    if i18n.getLang() == 'ru-ru' then
        return true
    end
end
--[[
    使用TTF设置飨灵名字label的内容
--]]
function CommonUtils.SetCardNameLabelStringByIdUseTTF(label, id, params, text)
    label:setTTFConfig({fontFilePath = params.font,fontSize = params.fontSize})
    if params.outline then
        local outlineSize = math.max(1, checkint(params.outlineSize))
        if type(params.outline) == 'string' then
            label:enableOutline(ccc4FromInt(params.outline), outlineSize)
        else
            label:enableOutline(params.outline, outlineSize)
        end
    end

    if params.color then
        if type(params.color) == 'string' then
            label:setColor(ccc3FromInt(params.color))
        else
            label:setColor(params.color)
        end
    end
    label:setString(text)
end
--[[
    获取飨灵名字
    @param id 卡牌自增id
--]]
function CommonUtils.GetCardNameById(id)
    local cardId   = checkint(checktable(app.gameMgr:GetCardDataById(id)).cardId)
    local cardConf = CommonUtils.GetConfig('cards', 'card', cardId) or {}
    if app.cardMgr.GetCouple(id) then
        local CardData = app.gameMgr:GetCardDataById(id)
        if CardData.cardName and '' ~= CardData.cardName then
            return CardData.cardName
        else
            return tostring(cardConf.name)
        end
    else
        return tostring(cardConf.name)
    end
end
--[[
    获取功能模块是否打开
--]]
function CommonUtils.GetModuleAvailable(moduleId)
    if not moduleId then
        return true
    end
    local moduleSplit = CommonUtils.GetConfigAllMess('functionsCut', 'common')
    if not next(moduleSplit) then
        return true
    end
    if not moduleSplit[moduleId] then
        return true
    end
    return 1 == checkint(moduleSplit[moduleId].status)
end
--[[
    获取跳转功能模块是否打开
--]]
function CommonUtils.GetJumpModuleAvailable( moduleId )
    if CommonUtils.CheckModuleIsExitByModuleId(moduleId) then
        if not MODULE_REFLECT[tostring(moduleId)] then
            return true
        end
        return CommonUtils.GetModuleAvailable(MODULE_REFLECT[tostring(moduleId)])
    end
    return false
end
--[[
获取展示的抽卡道具消耗
@params consume list 抽卡消耗 {
    goodsId int 道具id
    num     int 道具数量
}
--]]
function CommonUtils.GetCapsuleConsume( consume )
    if not consume or next(consume) == nil then return {} end
    local capsuleConsume = {}
    for i, v in ipairs(consume) do
        if i == #consume then
            capsuleConsume = v
            break
        else
            if app.gameMgr:GetAmountByGoodId(v.goodsId) >= checkint(v.num) then
                capsuleConsume = v
                break
            end
        end
    end
    return capsuleConsume
end
--[[

@params consume list 抽卡消耗 {
    priceData 商城的数据信息
}
--]]
function CommonUtils.GetCurrentAndOriginPriceDByPriceData(priceData)
    local currentPrice , OriginPrice
    if isElexSdk() then
        local sdkInstance = require("root.AppSDK").GetInstance()
        if sdkInstance.loadedProducts[tostring(priceData.channelProductId)] then
            currentPrice  = sdkInstance.loadedProducts[tostring(priceData.channelProductId)].priceLocale
            if  checkint(priceData.originalPrice) > 0  then
                local coinOp = string.match(currentPrice , "%a+" ) or  ""
                local currencyType =   cc.UserDefault:getInstance():getStringForKey('EATER_ELEX_CURRENCY_CODE')
                local currencyConf = CommonUtils.GetConfigAllMess('currency', 'activity')
                for i, v in pairs(currencyConf) do
                    if tonumber(v.USD) ==  tonumber(priceData.originalPrice)  then
                        OriginPrice = v[currencyType]
                        break
                    end
                end
                OriginPrice = OriginPrice or 0
                OriginPrice = OriginPrice .. coinOp
            end
            return currentPrice , OriginPrice
        end
    end
    currentPrice = string.format(__("￥%s") ,tostring(priceData.price)  )
    OriginPrice = string.format(__("￥%s") , tostring(checkint(priceData.originalPrice)))
    return currentPrice ,OriginPrice
end

-- 是否 需要额外请求 真实价格数据
function CommonUtils.IsNeedExtraGetRealPriceData()
    return isElexSdk()
end

--==============================--
-- @desc: check team data is empty
-- @params teamData table 卡牌阵容数据
-- @return errTip str 错误信息
--==============================--
function CommonUtils.ChecTeamIsEmpty(teamData)
    local isEmpty = true
    for i,v in ipairs(teamData) do
        if nil ~= v.id then
            isEmpty = false
            break
        end
    end
    if isEmpty then
        return __('队伍不能为空!!!')
    end
end

--[[
获取转换后传给服务器的阵容数据
@params teamData table
@return str string 阵容数据
--]]
function CommonUtils.ConvertTeamData2Str(teamData)
    local resultTable = {}
    for i = 1, MAX_TEAM_MEMBER_AMOUNT do
        local value = teamData[i]
        if value and nil ~= value.id then
            table.insert(resultTable, tostring(value.id))
        else
            table.insert(resultTable, '')
        end
    end

	return table.concat(resultTable, ',')
end

--[[
将服务器的阵容数据转换成通用数据结构
@params teamDataStr string 团队数据字符串
@return teamData list 队伍信息
--]]
function CommonUtils.ConvertTeamDataByStr(teamDataStr)
    local teamDataList = string.split2(checkstr(teamDataStr), ',')
	return CommonUtils.ConvertTeamDataByList(teamDataList)
end

--[[
将服务器的阵容数据转换成通用数据结构
@params teamDataList list 团队数据列表
@return teamData list 队伍信息
--]]
function CommonUtils.ConvertTeamDataByList(teamDataList)
    local teamData = {}
    for i = 1, MAX_TEAM_MEMBER_AMOUNT do
        local id = teamDataList[i]
        if id then
            local cardData = app.gameMgr:GetCardDataById(id)
			if next(cardData) then
                teamData[i] = {id = checkint(cardData.id)}
            else
                table.insert(teamData, {})
			end
        else
            table.insert(teamData, {})
        end
    end
	return teamData
end


-- 禁用打字日（中国式敏感时期特色）
function CommonUtils.CheckIsDisableInputDay(isTips)
    local isDisableInputDay = false
    if isChinaSdk() then
        local disableInputDays = {
            '2021-07-01',
            -- '2021-08-01',
            -- '2021-10-01',
        }
        local currentDay = os.date('%Y-%m-%d', getLoginServerTime())
        for _, disableDay in ipairs(disableInputDays) do
            if currentDay == disableDay then
                isDisableInputDay = true
                break
            end
        end
        if isDisableInputDay and isTips ~= false then
            app.uiMgr:ShowInformationTips(__('该功能正在优化中，请明日再试'))
        end
    end
    return isDisableInputDay
end

----------------------------------
-- old
----------------------------------

--[[
    为滚动视图附加鼠标滚轮滚动功能
]]
function CommonUtils.AdditionToMouseScrollEvent(scrollView, scrollSpeed)
    if scrollView and scrollView.setContentOffset then
        local mouseEventListener = cc.EventListenerMouse:create()
        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        mouseEventListener:registerScriptHandler(function(event)
            local boundingBox = scrollView:getBoundingBox()
            local worldPoint  = scrollView:convertToWorldSpace(PointZero)
            local mousePoint  = cc.p(checkint(event:getCursorX()), checkint(event:getCursorY()))
            local regionRect  = cc.rect(checkint(worldPoint.x), checkint(worldPoint.y), checkint(boundingBox.width), checkint(boundingBox.height))
            if cc.rectContainsPoint(regionRect, mousePoint) then
                local offsetPos = scrollView:getContentOffset()
                local offsetMin = scrollView:getMinOffset()
                local offsetMax = scrollView:getMaxOffset()
                local direction = scrollView:getDirection()
                local offsetGap = scrollSpeed or 15
                local targetPos = cc.p(0, 0)
                if direction == display.SDIR_H or direction == display.SDIR_B then
                    targetPos.x = math.max(offsetPos.x + event:getScrollX() * offsetGap)     -- update posX
                    targetPos.x = math.max(offsetMin.x, math.min(targetPos.x, offsetMax.x))  -- fixed limit
                end
                if direction == display.SDIR_V or direction == display.SDIR_B then
                    targetPos.y = math.max(offsetPos.y + event:getScrollY() * offsetGap)     -- update posY
                    targetPos.y = math.max(offsetMin.y, math.min(targetPos.y, offsetMax.y))  -- fixed limit
                end
                scrollView:setContentOffset(targetPos)
            end
        end, cc.Handler.EVENT_MOUSE_SCROLL)
        eventDispatcher:addEventListenerWithSceneGraphPriority(mouseEventListener, scrollView)
    end
end

----=======================----
--@author : xingweihao
--@date : 2020/3/18 5:42 PM
--@Description 获取GameId
--@params
--@return
---=======================----
function CommonUtils.GetGameId()
    local channelId = checkint(Platform.id)
    if channelId == BetaAndroid or channelId == BetaIos then
        -- 如果是beta 服
        return "7595f1c67332d802b7e13b49a5046a68"
    elseif channelId == PreAndroid or  channelId == PreIos then
        -- 如果pre服
        return "4508f34c8e3df82fa2f7c0fab578393f"
    elseif channelId == AppStore or channelId == Fondant or channelId == TapTap or
            ( channelId >= 2101 and channelId < 2199)  or channelId == 2010 or channelId == 2011 then
        -- 如果官服
        return "d4969fc5e3ef2425d49c1a7ee6c69c16"
    -- elseif channelId == QuickVirtualChannel then
    --     -- 如果渠道
    --     return "38350718d5735e4a674412916f418ec9"
    elseif channelId == XipuNewAndroid or channelId == XipuAndroid then
        -- 如果喜扑服
        return "32aabf6c4732c4c173e238d94e4e8e1d"
    else
        -- 渠道服 channelId 是动态获取的 默认返回渠道的 gameid
        return "38350718d5735e4a674412916f418ec9"
    end
end

function CommonUtils.GetPresetTeamModuleUnlockList()
    local types = PRESET_TEAM_TYPE
    local moduleUnlockList = {}

    for key, moduleType in pairs(types) do
        if CommonUtils.UnLockModule(moduleType, false) then
            table.insert(moduleUnlockList, checkint(moduleType))
        end
    end
    return moduleUnlockList
end
--[[
获取任务跳转配置
--]]
function CommonUtils.GetTaskJumpModuleConfig()
    local  MODULE_TO_DATA = {
        [tostring(COMMON_TASK_TYPE.SUMMON_TARGET_NUM_TIME_CARD_TASKS)] = {
            jumpView = "drawCards.CapsuleNewMediator",
            openType = JUMP_MODULE_DATA.CAPSULE
        },
        [tostring(COMMON_TASK_TYPE.UPGRADE_PET_NUM_TASKS)] = {
            jumpView = "PetDevelopMediator",
            openType = JUMP_MODULE_DATA.PET
        },
        [tostring(COMMON_TASK_TYPE.RESTAURANTS_GUSET_NUM_TASKS)] = {
            jumpView = "AvatarMediator",
            openType = JUMP_MODULE_DATA.RESTAURANT
        },
        [tostring(COMMON_TASK_TYPE.COMPLETE_TAKEAWAY_ORDER_TASKS)] = {
            jumpView = "HomeMediator",
            openType = JUMP_MODULE_DATA.PUBLIC_ORDER
        },
        [tostring(COMMON_TASK_TYPE.COMPLETE_EXPLORE_TASKS)] = {
            jumpView = "exploreSystem.ExploreSystemMediator",
            openType = JUMP_MODULE_DATA.EXPLORE_SYSTEM
        },
        [tostring(COMMON_TASK_TYPE.COLLOECT_PET_NUM_TASKS)] = {
            jumpView = "PetDevelopMediator",
            openType = JUMP_MODULE_DATA.PET
        },
        [tostring(COMMON_TASK_TYPE.COMPLETE_NORMAL_QUEST_TASKS)] = {
            jumpView = "MapMediator",
            openType = JUMP_MODULE_DATA.NORMAL_MAP
        },
        [tostring(COMMON_TASK_TYPE.COMPLETE_HARD_QUEST_TASKS)] = {
            jumpView = "MapMediator",
            openType = JUMP_MODULE_DATA.DIFFICULTY_MAP
        },
        [tostring(COMMON_TASK_TYPE.IMPROVE_RESTAURANTS_LEVEL_TASKS)] = {
            jumpView = "AvatarMediator",
            openType = JUMP_MODULE_DATA.RESTAURANT
        },
        [tostring(COMMON_TASK_TYPE.IMPROVE_RECIPE_NUM_TASKS)] = {
            jumpView = "RecipeResearchAndMakingMediator",
            openType = JUMP_MODULE_DATA.RESEARCH
        },
        [tostring(COMMON_TASK_TYPE.COLLECT_PET_EGGS_NUM_TASKS)] = {
            jumpView = "TowerQuestHomeMediator",
            openType = JUMP_MODULE_DATA.TOWER
        },
        [tostring(COMMON_TASK_TYPE.PURIFICATION_PET_EGG_NUM_TASKS)] = {
            jumpView = "PetDevelopMediator",
            openType = JUMP_MODULE_DATA.PET
        },
        [tostring(COMMON_TASK_TYPE.COMPLETE_TOWER_NUM_TASKS)] = {
            jumpView = "TowerQuestHomeMediator",
            openType = JUMP_MODULE_DATA.TOWER
        },
        [tostring(COMMON_TASK_TYPE.TO_OVERCOME_OVERLORD_MEAL_NUM_TASKS)] = {
            jumpView = "AvatarMediator",
            openType = JUMP_MODULE_DATA.RESTAURANT
        },
        [tostring(COMMON_TASK_TYPE.RESTAURANTS_COMPLETE_NUM_TASKS)] = {
            jumpView = "AvatarMediator",
            openType = JUMP_MODULE_DATA.RESTAURANT
        },
        [tostring(COMMON_TASK_TYPE.RESTAURANTS_COMPLETE_NUM_TASKS)] = {
            jumpView = "AvatarMediator",
            openType = JUMP_MODULE_DATA.RESTAURANT
        },
        [tostring(COMMON_TASK_TYPE.CUMULATIVE_CUSTOMS_CLEARANCE_TOWER_NUM_TASKS)] = {
            jumpView = "TowerQuestHomeMediator",
            openType = JUMP_MODULE_DATA.TOWER
        },
        [tostring(COMMON_TASK_TYPE.COMPLETE_AIRS_NUM_TASKS)] = {
            jumpView = "HomeMediator",
            openType = JUMP_MODULE_DATA.AIR_TRANSPORTATION,
            jumpViewTwo = {
                jumpView = 'AirShipHomeMediator'
            }
        },
        [tostring(COMMON_TASK_TYPE.GOD_TARGET_ID_PET_IMPROVED_LEVEL_TASKS)] = {
            jumpView = "PetDevelopMediator",
            openType = JUMP_MODULE_DATA.PET
        },
        [tostring(COMMON_TASK_TYPE.AREANA_BATTLE_NUMS_TASKS)] = {
            jumpView = "PVCMediator",
            openType = JUMP_MODULE_DATA.PVC_ROYAL_BATTLE
        },
        [tostring(COMMON_TASK_TYPE.AREANA_BATTLE_WIN_NUMS_TASKS)] = {
            jumpView = "PVCMediator",
            openType = JUMP_MODULE_DATA.PVC_ROYAL_BATTLE
        },
        [tostring(COMMON_TASK_TYPE.COMPLETE_MATERIAL_COPY_NUM_TASKS)] = {
            jumpView = "MaterialTranScriptMediator",
            openType = JUMP_MODULE_DATA.MATERIAL_SCRIPT
        },
        [tostring(COMMON_TASK_TYPE.COMPLETE_DAILY_TASKS)] = {
            jumpView = "HomeMediator",
            openType = JUMP_MODULE_DATA.DAILYTASK,
            jumpViewTwo = {
                jumpView = 'task.TaskHomeMediator',
            }
        },
        [tostring(COMMON_TASK_TYPE.SWEEP_TOWER_TASKS)] = {
            jumpView = "TowerQuestHomeMediator",
            openType = JUMP_MODULE_DATA.TOWER

        },
        [tostring(COMMON_TASK_TYPE.SERVE_PRIVATE_ROOM_GUEST_TASKS)] = {
            jumpView = "privateRoom.PrivateRoomHomeMediator",
            openType = JUMP_MODULE_DATA.BOX
        },
        [tostring(COMMON_TASK_TYPE.FISH_REWARDS_NUM_TASKS)] = {
            jumpView = "fishing.FishingGroundMediator",
            openType = JUMP_MODULE_DATA.FISHING_GROUND ,
            params = {queryPlayerId =app.gameMgr:GetUserInfo().playerId }
        },
        [tostring(COMMON_TASK_TYPE.RESTAURANTS_SELL_RECIPE_NUM_TASKS)] = {
            jumpView = "AvatarMediator",
            openType = JUMP_MODULE_DATA.RESTAURANT
        },
        [tostring(COMMON_TASK_TYPE.WATERING_PET_EGGS_NUM_TASKS)] = {
            jumpView = "PetDevelopMediator",
            openType = JUMP_MODULE_DATA.PET
        },
        [tostring(COMMON_TASK_TYPE.STRENGTHENING_PET_NUM_TASKS)] = {
            jumpView = "PetDevelopMediator",
            openType = JUMP_MODULE_DATA.PET
        },
        [tostring(COMMON_TASK_TYPE.EVOLUTION_PET_NUM_TASKS)] = {
            jumpView = "PetDevelopMediator",
            openType = JUMP_MODULE_DATA.PET
        },
        [tostring(COMMON_TASK_TYPE.ADD_UP_BIRTH_PET_NUM_TASKS)] = {
            jumpView = "PetDevelopMediator",
            openType = JUMP_MODULE_DATA.PET
        } ,
        [tostring(COMMON_TASK_TYPE.UPGRADE_RECIPE_TO_S)] = {
            jumpView = "RecipeResearchAndMakingMediator",
            openType = JUMP_MODULE_DATA.RESEARCH
        } ,
        [tostring(COMMON_TASK_TYPE.UPGRADE_RECIPE_TO_A)] = {
            jumpView = "RecipeResearchAndMakingMediator",
            openType = JUMP_MODULE_DATA.RESEARCH
        } ,
        [tostring(COMMON_TASK_TYPE.UPGRADE_RECIPE_TO_B)] = {
            jumpView = "RecipeResearchAndMakingMediator",
            openType = JUMP_MODULE_DATA.RESEARCH
        } ,
        [tostring(COMMON_TASK_TYPE.UPGRADE_RECIPE_TO_C)] = {
            jumpView = "RecipeResearchAndMakingMediator",
            openType = JUMP_MODULE_DATA.RESEARCH
        } ,
        [tostring(COMMON_TASK_TYPE.UPGRADE_CARD_SKILL_LEVEL)] = {
            jumpView = "CardsListMediatorNew",
            openType = JUMP_MODULE_DATA.CARDLEVELUP
        } ,
        [tostring(COMMON_TASK_TYPE.UPGRADE_CARD_LEVEL)] = {
            jumpView = "CardsListMediatorNew",
            openType = JUMP_MODULE_DATA.CARDLEVELUP
        } ,
        [tostring(COMMON_TASK_TYPE.ACQUIRE_CARD)] = {
            jumpView = "drawCards.CapsuleNewMediator",
            openType = JUMP_MODULE_DATA.CAPSULE
        } ,
        [tostring(COMMON_TASK_TYPE.ACTIVATE_ARTIFACT)] = {
            jumpView = "CardsListMediatorNew",
            openType = JUMP_MODULE_DATA.CAPSULE
        } ,
        [tostring(COMMON_TASK_TYPE.UPGRADE_CARD_STAR)] = {
            jumpView = "CardsListMediatorNew",
            openType = JUMP_MODULE_DATA.CAPSULE
        } ,
    }
    return MODULE_TO_DATA
end
--[[
通过任务数据跳转到指定模块
@params taskData map 任务数据
@params isInHomeScene bool 跳转功能主体是否处于主界面之上
--]]
function CommonUtils.JumpModuleByTaskData( taskData, isInHomeScene )
    local MODULE_TO_DATA = CommonUtils.GetTaskJumpModuleConfig()
    local taskType = taskData.taskType
    -- 模块的前往
    if  MODULE_TO_DATA[tostring(taskType)] then
        local jumpView =  MODULE_TO_DATA[tostring(taskType)].jumpView
        local jumpViewTwo =  MODULE_TO_DATA[tostring(taskType)].jumpViewTwo
        local openType = MODULE_TO_DATA[tostring(taskType)].openType
        local params = MODULE_TO_DATA[tostring(taskType)].params
        if CommonUtils.UnLockModule(openType,true) then
            if jumpView == "HomeMediator" then
                if isInHomeScene then
                    app:BackMediator()
                else
                    app:BackHomeMediator()
                end
                if jumpViewTwo then
                    app:RetrieveMediator('Router'):Dispatch({}, {name = jumpViewTwo.jumpView, params = jumpViewTwo.params})
                end
            elseif jumpView == "MapMediator" then
                CommonUtils.ShowEnterStageView(taskConfigData.targetNum)
            elseif jumpView == "RecipeResearchAndMakingMediator" then
                app:BackMediator()
                local router = app:RetrieveMediator('Router')
                router:Dispatch({}, {name = jumpView, params = {recipeStyle = RECIPE_STYLE.ACTIVITY_RECIPE_STYLE } })
            elseif jumpView == "CardsListMediatorNew" then
                app:RetrieveMediator('Router'):Dispatch({}, {name = jumpView , params = {cardId = taskData.targetId} })
            else
                app:RetrieveMediator('Router'):Dispatch({}, {name = jumpView , params = params })
            end
        end
    else
        app.uiMgr:ShowInformationTips(__('暂无前往方式'))
    end
end
--[[
获取任务描述
--]]    
function CommonUtils.GetTaskDescrByTaskData( taskData )
    if not taskData then return end
    local CONVERT_QUEST = {
        [tostring(COMMON_TASK_TYPE.COMPLETE_NORMAL_QUEST_TASKS)] = true,
        [tostring(COMMON_TASK_TYPE.COMPLETE_HARD_QUEST_TASKS)]   = true,
    }
    local CONVERT_RECIPE = {
        [tostring(COMMON_TASK_TYPE.UPGRADE_RECIPE_TO_S)] = true,
        [tostring(COMMON_TASK_TYPE.UPGRADE_RECIPE_TO_A)] = true,
        [tostring(COMMON_TASK_TYPE.UPGRADE_RECIPE_TO_B)] = true,
        [tostring(COMMON_TASK_TYPE.UPGRADE_RECIPE_TO_C)] = true,
    }
    local CONVERT_CARD = {
        [tostring(COMMON_TASK_TYPE.UPGRADE_CARD_SKILL_LEVEL)] = true,
        [tostring(COMMON_TASK_TYPE.UPGRADE_CARD_LEVEL)]       = true,
        [tostring(COMMON_TASK_TYPE.ACQUIRE_CARD)]             = true,
        [tostring(COMMON_TASK_TYPE.ACTIVATE_ARTIFACT)]        = true,
        [tostring(COMMON_TASK_TYPE.UPGRADE_CARD_STAR)]        = true,
    }
    local descr = taskData.taskName
    if CONVERT_QUEST[tostring(taskData.taskType)] then -- 转换关卡名
        local conf = CommonUtils.GetQuestConf(taskData.targetNum) or {}
        local name = conf.name or ""
        descr = string.gsub(descr , '_target_num_' ,tostring(taskData.targetNum))
        descr = string.gsub(descr, '_target_id_', name)
    elseif CONVERT_RECIPE[tostring(taskData.taskType)] then -- 转换菜品名
        local conf = CommonUtils.GetConfig('goods', 'goods', taskData.targetId)
        local name = conf.name or ""
        descr = string.gsub(descr , '_target_num_' , tostring(taskData.targetNum))
        descr = string.gsub(descr, '_target_id_', name)
    elseif CONVERT_CARD[tostring(taskData.taskType)] then -- 转换卡牌名
        local conf = CommonUtils.GetConfig('card', 'card', taskData.targetId)
        local name = conf.name or ""
        descr = string.gsub(descr , '_target_num_' ,tostring(taskData.targetNum))
        descr = string.gsub(descr, '_target_id_', name)
    else
        descr = string.gsub(descr, '_target_id_', tostring(taskData.targetId))
        descr = string.gsub(descr, '_target_num_', tostring(taskData.targetNum))
    end
    return descr
end
--[[
关卡跳转
@params stageId int 关卡id
--]]
function CommonUtils.ShowEnterStageView(stageId)
    PlayAudioByClickNormal()
    local stageId = checkint(stageId)
    local stageConf = CommonUtils.GetConfig('quest', 'quest', stageId)
    local questType = checkint(stageConf.questType)
    --------------- 初始化战斗传参 ---------------
    local battleReadyData = BattleReadyConstructorStruct.New(
            2,
            app.gameMgr:GetUserInfo().localCurrentBattleTeamId,
            app.gameMgr:GetUserInfo().localCurrentEquipedMagicFoodId,
            stageId,
            CommonUtils.GetQuestBattleByQuestId(stageId),
            nil,
            POST.QUEST_AT.cmdName,
            {questId = stageId},
            POST.QUEST_AT.sglName,
            POST.QUEST_GRADE.cmdName,
            {questId = stageId},
            POST.QUEST_GRADE.sglName,
            'allRound.AllRoundHomeMediator',
            "allRound.AllRoundHomeMediator"
    )
    --------------- 初始化战斗传参 ---------------
    if questType == QUEST_DIFF_NORMAL then
        if checkint(stageId)  > app.gameMgr:GetUserInfo().newestQuestId then
           uiMgr:ShowInformationTips(__('先通关前置关卡'))
            return
        end
    elseif questType == QUEST_DIFF_HARD then
        if checkint(stageId)  > app.gameMgr:GetUserInfo().newestHardQuestId then
           uiMgr:ShowInformationTips(__('先通关前置关卡'))
            return
        end
    end
    local layer = require('Game.views.BattleReadyView').new(battleReadyData)
    layer:setPosition(cc.p(display.cx,display.cy))
    uiMgr:GetCurrentScene():AddDialog(layer)
    --addChild(layer, battleReadyViewZOrder - 1)
end
return CommonUtils

