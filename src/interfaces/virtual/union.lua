--[[
 * author : kaishiqi
 * descpt : 关于 工会数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t

local UnionConfigParser     = require('Game.Datas.Parser.UnionConfigParser')
local UnionWarsModelFactory = require('Game.models.UnionWarsModelFactory')
local UnionWarsModel        = UnionWarsModelFactory.UnionWarsModel
local unionTaskConfs        = virtualData.getConf('union', UnionConfigParser.TYPE.TASK)
local unionRoomConfs        = virtualData.getConf('union', UnionConfigParser.TYPE.ROOM)
local unionLevelConfs       = virtualData.getConf('union', UnionConfigParser.TYPE.LEVEL)
local unionBuildConfs       = virtualData.getConf('union', UnionConfigParser.TYPE.BUILD)
local unionAvatarConfs      = virtualData.getConf('union', UnionConfigParser.TYPE.AVATAR)
local unionGodBeastConfs    = virtualData.getConf('union', UnionConfigParser.TYPE.GODBEAST)
local godBeastQueestConfs   = virtualData.getConf('union', UnionConfigParser.TYPE.GODBEASTQUEST)
local godBeastGrowConfs     = virtualData.getConf('union', UnionConfigParser.TYPE.GODBEASTGROW)
local godBeastEnergyConfs   = virtualData.getConf('union', UnionConfigParser.TYPE.PETENERGYLEVEL)
local godBeastSatietyConfs  = virtualData.getConf('union', UnionConfigParser.TYPE.PETSATIETYLEVEL)
local unionPartyTimeConfs   = virtualData.getConf('union', UnionConfigParser.TYPE.PARTY_TIME_LINE)
local unionPartyQuestConfs  = virtualData.getConf('union', UnionConfigParser.TYPE.PARTY_QUEST)
local unionWarsTimeConfs    = virtualData.getConf('union', UnionConfigParser.TYPE.WARS_TIME_LINE)
local unionWarsSiteConfs    = virtualData.getConf('union', UnionConfigParser.TYPE.WARS_SITE_INFO)
local warsBossQuestConfs    = virtualData.getConf('union', UnionConfigParser.TYPE.WARS_BOSS_QUEST)
local foodConfs             = virtualData.getConf('goods', 'food')
local cardConfs             = virtualData.getConf('card', 'card')
local foodIdList            = table.keys(foodConfs)
local cardIdList            = virtualData.validCardIdList


local stopUnionRoomAutoChatFunc = function()
    if virtualData.unionRoomAutoChatHandler_ then
        scheduler.unscheduleGlobal(virtualData.unionRoomAutoChatHandler_)
        virtualData.unionRoomAutoChatHandler_ = nil
    end
end
local begainUnionRoomAutoChatFunc = function()
    if virtualData.unionRoomAutoChatHandler_ then return end
    virtualData.unionRoomAutoChatHandler_ = scheduler.scheduleGlobal(function()
        if virtualData.union_ and virtualData.union_.roomMember then
            local roomMember = virtualData.union_.roomMember
            local memberData = roomMember[_r(#roomMember)]

            chatServer:sendAllClient(NetCmd.RequestChatroomGetMessage, {data = {
                sendTime    = os.time(),
                channel     = CHAT_CHANNELS.CHANNEL_UNION,
                messageId   = virtualData.generateUuid(),
                name        = memberData.playerName,
                playerId    = memberData.playerId,
                avatar      = memberData.avatar,
                avatarFrame = memberData.avatarFrame,
                message     = string.fmt('<desc>%1</desc><messagetype>1</messagetype>', virtualData.createName(_r(20,200))),
            }})
        end
    end, 5)
end


local stopUnionRoomAutoRunFunc = function()
    if virtualData.unionRoomAutoRunHandler_ then
        scheduler.unscheduleGlobal(virtualData.unionRoomAutoRunHandler_)
        virtualData.unionRoomAutoRunHandler_ = nil
    end
end
local begainUnionRoomAutoRunFunc = function()
    if virtualData.union.toFail then return end
    if virtualData.unionRoomAutoRunHandler_ then return end
    virtualData.unionRoomAutoRunHandler_ = scheduler.scheduleGlobal(function()
        if virtualData.union_ and virtualData.union_.roomMember then
            -- auto run
            local roomMember = virtualData.union_.roomMember
            local memberData = roomMember[_r(#roomMember)]
            if memberData.playerId ~= virtualData.playerData.playerId then
                local unionLobbyMdt = AppFacade.GetInstance():RetrieveMediator('UnionLobbyMediator')
                local lobbyViewData = unionLobbyMdt and unionLobbyMdt:getLobbyScene():getViewData() or nil
                if lobbyViewData then
                    gameServer:sendAllClient(NetCmd.UNION_AVATAR_MOVE_TAKE, {data = {
                        memberId = memberData.playerId,
                        pointX   = lobbyViewData.avatarLayerOrigin.x + _r(lobbyViewData.avatarLayerSize.width),
                        pointY   = lobbyViewData.avatarLayerOrigin.y + _r(lobbyViewData.avatarLayerSize.height),
                    }})
                end
            end
            
            -- change inUnionLobby
            local memberData = roomMember[_r(#roomMember)]
            if memberData.playerId ~= virtualData.playerData.playerId then
                gameServer:sendAllClient(NetCmd.UNION_AVATAR_LOBBY_CHANGE, {data = {
                    roomId         = virtualData.union_.roomId,
                    memberId       = memberData.playerId,
                    isInUnionLobby = _r(0,1)
                }})
            end
        end
    end, 3)
end


local stopPartyBossResultAutoRunFunc = function()
    if virtualData.partyBossResultAutoRunHandler_ then
        scheduler.unscheduleGlobal(virtualData.partyBossResultAutoRunHandler_)
        virtualData.partyBossResultAutoRunHandler_ = nil
    end
end
local begainPartyBossResultAutoRunFunc = function(bossQuestStepId, bossTotalSeconds)
    if virtualData.union.toFail then return end
    if virtualData.partyBossResultAutoRunHandler_ then return end
    virtualData.partyBossResultAutoRunData_ = {
        questStepId  = checkint(bossQuestStepId),
        totalTimes   = checkint(bossTotalSeconds),
        currentTimes = 0,
    }
    virtualData.partyBossResultAutoRunHandler_ = scheduler.scheduleGlobal(function()
        virtualData.partyBossResultAutoRunData_.currentTimes = virtualData.partyBossResultAutoRunData_.currentTimes + 1
        if virtualData.partyBossResultAutoRunData_.currentTimes <= virtualData.partyBossResultAutoRunData_.totalTimes then
            gameServer:sendAllClient(NetCmd.UNION_PARTY_BOSS_RESULT, {data = {
                questStepId    = virtualData.partyBossResultAutoRunData_.questStepId,
                memberWinTimes = virtualData.partyBossResultAutoRunData_.currentTimes,
            }})
        else
            stopPartyBossResultAutoRunFunc()
        end
    end, 1)
end


local stopPartyRollRewardsAutoRunFunc = function()
    if virtualData.partyRollRewardsAutoRunHandler_ then
        scheduler.unscheduleGlobal(virtualData.partyRollRewardsAutoRunHandler_)
        virtualData.partyRollRewardsAutoRunHandler_ = nil
    end
end
local begainPartyRollRewardsAutoRunFunc = function(endedTime)
    if virtualData.union.toFail then return end
    if virtualData.partyRollRewardsAutoRunHandler_ then return end
    virtualData.partyRollRewardsAutoRunData_ = {
        endedTime = checkint(endedTime),
    }
    virtualData.partyRollRewardsAutoRunHandler_ = scheduler.scheduleGlobal(function()
        if os.time() <= virtualData.partyRollRewardsAutoRunData_.endedTime then
            local partyMemberList = checktable(checktable(virtualData.unionPartyMember_).rollResult)
            local partyMemberData = partyMemberList[_r(#partyMemberList)] or {}
            
            partyMemberData.rollPoint = _r(999)
            gameServer:sendAllClient(NetCmd.UNION_PARTY_ROLL_NOTICE, {data = {
                playerId  = partyMemberData.playerId,
                rollPoint = partyMemberData.rollPoint,
            }})
        else
            stopPartyRollRewardsAutoRunFunc()
        end
    end, 1)
end


local stopWarsSiteStateAutoRunFunc = function()
    if virtualData.warsSiteStateRunHandler_ then
        scheduler.unscheduleGlobal(virtualData.warsSiteStateRunHandler_)
        virtualData.warsSiteStateRunHandler_ = nil
    end
end
local begainWarsSiteStateAutoRunFunc = function()
    if virtualData.warsSiteStateRunHandler_ then return end
    virtualData.warsSiteStateRunHandler_ = scheduler.scheduleGlobal(function()
        local unionWarsModel = app.unionMgr:getUnionWarsModel()
        if not unionWarsModel then return end

        local unionWarsStepId  = unionWarsModel:getWarsStepId()
        local warsMapBuildings = nil
        if unionWarsStepId == UNION_WARS_STEPS.FIGHTING then
            if unionWarsModel:isWatchEnemyMap() then
                warsMapBuildings = virtualData.unionWarsEnemyMap_ and virtualData.unionWarsEnemyMap_.warsBuildings or nil
            else
                warsMapBuildings = virtualData.unionWarsUnionMap_ and virtualData.unionWarsUnionMap_.warsBuildings or nil
            end
        end
        
        if warsMapBuildings then
            local warsMapSiteData = warsMapBuildings[_r(#warsMapBuildings)]
            if warsMapSiteData then
                if _r(100) > 50 then
                    -- to attack start
                    warsMapSiteData.isDefending = warsMapSiteData.isDefending == 1 and 0 or 1
                    
                    gameServer:sendAllClient(unionWarsModel:isWatchEnemyMap() and NetCmd.UNION_WARS_ATTACK_START or NetCmd.UNION_WARS_DEFEND_START, {data = {
                        warsBuildingId = warsMapSiteData.buildingId,
                    }})

                else
                    -- to attack ended
                    if _r(100) > 50 then
                        warsMapSiteData.playerHp = math.max(warsMapSiteData.playerHp - 1, 0)
                    else
                        warsMapSiteData.defendDebuff = math.min(warsMapSiteData.defendDebuff + 1, UnionWarsModel.DEBUFF_MAX)
                    end
                    
                    gameServer:sendAllClient(unionWarsModel:isWatchEnemyMap() and NetCmd.UNION_WARS_ATTACK_ENDED or NetCmd.UNION_WARS_DEFEND_ENDED, {data = {
                        warsBuildingId = warsMapSiteData.buildingId,
                        defendDebuff   = warsMapSiteData.defendDebuff,
                        playerHp       = warsMapSiteData.playerHp,
                    }})
                end
            end
        end
    end, 2)
end


virtualData.union = {}
virtualData.union.toFail = false

virtualData.union.lobbyAvatarMove = function(pointX, pointY, playerId)
    local playerId = playerId or virtualData.playerData.playerId
    if virtualData.union_ and virtualData.union_.roomMember then
        for i, memberData in ipairs(virtualData.union_.roomMember) do
            if memberData.playerId ~= playerId then
                gameServer:sendAllClient(NetCmd.RequestChatroomGetMessage, {data = {
                    memberId = checkint(playerId),
                    pointX   = checkint(pointX),
                    pointY   = checkint(pointY),
                }})
            end
        end
    end
end


-------------------------------------------------
-- 查找工会
virtualData['Union/search'] = function(args)
    local data = {
        unions = {}
    }
    local unionIconList = table.valuesAt(unionAvatarConfs, 'iconId')
    for i = 1, _r(20) do
        local unionLevel       = _r(10)
        local unionLevelConf   = unionLevelConfs[tostring(unionLevel)] or {}
        local unionJobDefine   = checktable(unionLevelConf.job)
        local unionMemberNum   = checkint(unionJobDefine[tostring(UNION_JOB_TYPE.COMMON)])
        local unionMemberCount = _r(10, unionMemberNum)
        table.insert(data.unions, {
            unionId      = virtualData.createPlayerId(),        -- 工会ID
            name         = virtualData.createName(_r(6,12)),    -- 工会名字
            level        = unionLevel,                          -- 工会等级
            avatar       = unionIconList[_r(#unionIconList)], -- 工会头像
            unionSign    = virtualData.createName(_r(40, 80)),  -- 工会描述
            memberNumber = unionMemberCount,                    -- 工会人数
            chairmanId   = virtualData.createPlayerId(),        -- 会长ID
            chairmanName = virtualData.createName(_r(6,12)),    -- 会长名称
            hasApplied   = _r(0,1),                             -- 是否已经申请过，0否，1是
        })
    end
    return t2t(data)
end


-- 申请加入工会
virtualData['Union/apply'] = function(args)
    return t2t({})
end


-- 工会创建
virtualData['Union/create'] = function(args)
    if not virtualData.union_ then
        virtualData.union_ = {
            unionId                 = _r(9999),              -- 工会id
            name                    = args.name,             -- 工会名字
            avatar                  = args.avatar,           -- 工会头像
            unionSign               = args.unionSign,        -- 工会描述
            level                   = 6,                     -- 工会等级
            member                  = {},                    -- 工会成员
            contributionPoint       = 0,                     -- 工会捐献
            playerContributionPoint = 0,                     -- 自己捐献
            applyPermission         = 1,                     -- 申请操作权限（ 1:无限制 2:会长副会长能操作 3:不允许加入）
            leftBuildTimes          = {},                    -- 工会建造次数（key：建造id，value：次数）
            leftFeedPetTimes        = 0,                     -- 剩余神兽喂养次数
            roomId                  = 0,                     -- 房间id
            job                     = UNION_JOB_TYPE.PRESIDENT, -- 自己的工会职位
            roomMember              = {},                    -- 房间成员
            roomMemberNumber        = {},                    -- 房间状态（key：房间id，value：人数）
        }
        
        -------------------------------------------------
        -- room conf
        local roomConfList = {}
        for _, roomConf in pairs(unionRoomConfs) do
            if checkint(roomConf.openLevel) <= virtualData.union_.level then
                table.insert(roomConfList, roomConf)
            end
        end

        -------------------------------------------------
        -- allot members
        local unionLevelConf   = unionLevelConfs[tostring(virtualData.union_.level)] or {}
        local unionJobDefine   = checktable(unionLevelConf.job)
        local unionCaptainNum  = checkint(unionJobDefine[tostring(UNION_JOB_TYPE.PRESIDENT)])
        local unionVCaptainNum = checkint(unionJobDefine[tostring(UNION_JOB_TYPE.VICE_PRESIDENT)])
        local unionMemberNum   = checkint(unionJobDefine[tostring(UNION_JOB_TYPE.COMMON)])
        local unionMemberCount = _r(10, unionMemberNum)
        local unionRoomCount   = #roomConfList

        for i = 1, unionMemberCount + 1 do -- +1 is self
            local roomConf = roomConfList[_r(#roomConfList)] or {}
            local roomId   = checkint(roomConf.id)
            local isSelf   = i == 1

            -- count room member
            local roomMemberNumber = checkint(virtualData.union_.roomMemberNumber[tostring(roomId)])
            if roomMemberNumber < UNION_ROOM_MEMBERS then
                -- add member count
                roomMemberNumber = roomMemberNumber + 1
                virtualData.union_.roomMemberNumber[tostring(roomId)] = roomMemberNumber
                
                -- create member
                local memberCardData = virtualData.createCardData(cardIdList[_r(#cardIdList)])
                local memberData = {
                    job                = UNION_JOB_TYPE.COMMON,
                    playerId           = isSelf and virtualData.playerData.playerId or virtualData.createPlayerId(),
                    playerName         = isSelf and virtualData.playerData.playerName or string.fmt('%2_%3)%1', virtualData.createName(_r(4,8)), roomId, roomMemberNumber),
                    playerAvatar       = isSelf and virtualData.playerData.avatar or virtualData.createAvatarId(),
                    playerAvatarFrame  = isSelf and virtualData.playerData.avatarFrame or virtualData.createAvatarFrameId(),
                    playerLevel        = isSelf and virtualData.playerData.level or _r(99),
                    contributionPoint_ = roomId * UNION_ROOM_MEMBERS + roomMemberNumber,
                    lastExitTime_      = os.time() - virtualData.createSecond('d:5:?,h:24:?,s:60:?'),
                    skinId_            = memberCardData.defaultSkinId,
                    cardId_            = memberCardData.cardId,
                    position_          = roomMemberNumber,
                    roomId_            = roomId,
                }
                table.insert(virtualData.union_.member, memberData)

                -- self setting
                if isSelf then
                    virtualData.union_.roomId = roomId
                    virtualData.union_.job    = UNION_JOB_TYPE.PRESIDENT
                end

                -- room member
                local isSameRoom = memberData.roomId_ == virtualData.union_.roomId
                if isSameRoom then
                    table.insert(virtualData.union_.roomMember, {
                        playerId        = memberData.playerId,
                        position        = memberData.position_,
                        playerName      = memberData.playerName,
                        defaultCardId   = memberData.cardId_,
                        defaultCardSkin = memberData.skinId_,
                        isInUnionLobby  = _r(0,1),
                    })
                end
            end
        end

        -------------------------------------------------
        -- union build
        for k, v in pairs(unionBuildConfs) do
            virtualData.union_.leftBuildTimes[k] = _r(9)
        end

    end
    local data = {
        unionId = virtualData.union_.unionId
    }
    return t2t(data)
end


-- 退出工会
virtualData['Union/quit'] = function(args)
    virtualData.union_ = nil
    return t2t({})
end


-------------------------------------------------
-- 工会首页
virtualData['Union/home'] = function(args)
    if not virtualData.union_ then
        local unionIconList = table.valuesAt(unionAvatarConfs, 'iconId')
        virtualData['Union/create']({
            name      = virtualData.createName(_r(6, 12)),
            avatar    = unionIconList[_r(#unionIconList)],
            unionSign = virtualData.createName(_r(40, 80)),
        })
    end
    begainUnionRoomAutoChatFunc()
    begainUnionRoomAutoRunFunc()
    return t2t(virtualData.union_)
end
-- 离开工会大厅
virtualData['Union/quitHome'] = function(args)
    stopUnionRoomAutoChatFunc()
    stopUnionRoomAutoRunFunc()
    return t2t({})
end


-- 切换房间
virtualData['Union/switchRoom'] = function(args)
    local oldRoomId     = virtualData.union_.roomId
    local switchRoomId  = checkint(args.roomId)
    local oldMemberNum  = checkint(virtualData.union_.roomMemberNumber[tostring(oldRoomId)])
    local roomMemberNum = checkint(virtualData.union_.roomMemberNumber[tostring(switchRoomId)])
    if roomMemberNum < UNION_ROOM_MEMBERS then
        virtualData.union_.roomId     = switchRoomId
        virtualData.union_.roomMember = {}
        virtualData.union_.roomMemberNumber[tostring(oldRoomId)]    = oldMemberNum - 1
        virtualData.union_.roomMemberNumber[tostring(switchRoomId)] = roomMemberNum + 1

        -- room member
        local selfMemberData  = nil
        local roomPositionMap = {}
        for _, memberData in ipairs(virtualData.union_.member) do
            if memberData.playerId == virtualData.playerData.playerId then
                selfMemberData           = memberData
                selfMemberData.roomId_   = switchRoomId
                selfMemberData.position_ = 0
            else
                if memberData.roomId_ == switchRoomId then
                    roomPositionMap[tostring(memberData.position_)] = true
                    table.insert(virtualData.union_.roomMember, {
                        playerId        = memberData.playerId,
                        position        = memberData.position_,
                        playerName      = memberData.playerName,
                        defaultCardId   = memberData.cardId_,
                        defaultCardSkin = memberData.skinId_,
                        isInUnionLobby  = _r(0,1),
                    })
                end
            end
        end

        -- self position
        for i = 1, UNION_ROOM_MEMBERS do
            if not roomPositionMap[tostring(i)] then
                selfMemberData.position_ = i
                break
            end
        end
        table.insert(virtualData.union_.roomMember, {
            playerId        = selfMemberData.playerId,
            position        = selfMemberData.position_,
            playerName      = selfMemberData.playerName,
            defaultCardId   = selfMemberData.cardId_,
            defaultCardSkin = selfMemberData.skinId_,
        })

        local data = {
            roomMember = virtualData.union_.roomMember
        }
        return t2t(data)
    else
        return t2t({}, -1, '该房间人数已满')
    end
end


-------------------------------------------------
-- 工会申请列表
virtualData['Union/applyList'] = function(args)
    virtualData.unionApplyList_ = {}
    for i = 1, _r(30) do
        table.insert(virtualData.unionApplyList_, {
            playerId           = virtualData.createPlayerId(),
            playerName         = virtualData.createName(_r(4,8)),
            playerAvatar       = virtualData.createAvatarId(),
            playerAvatarFrame  = virtualData.createAvatarFrameId(),
            playerLevel        = _r(99),
        })
    end
    local data = {
        applyList = virtualData.unionApplyList_
    }
    return t2t(data)
end


-- 清空申请列表
virtualData['Union/applyClear'] = function(args)
    return t2t({})
end


-- 工会拒绝申请
virtualData['Union/applyReject'] = function(args)
    return t2t({})
end


-- 工会接受申请
virtualData['Union/applyAgree'] = function(args)
    local agreePlayerData = nil
    for i, playerData in ipairs(virtualData.unionApplyList_) do
        if playerData.playerId == checkint(args.applyPlayerId) then
            agreePlayerData = playerData
            break
        end
    end
    if agreePlayerData then
        local enableRoomId = 0
        for roomId, number in pairs(virtualData.union_.roomMemberNumber) do
            if number < UNION_ROOM_MEMBERS then
                enableRoomId = checkint(roomId)
                break
            end
        end

        if enableRoomId > 0 then
            local enablePoint = 1
            local positionMap = {}
            for i, memberData in ipairs(virtualData.union_.member) do
                if memberData.roomId_ == enableRoomId then
                    positionMap[tostring(memberData.position_)] = true
                end
            end
            for i = 1, UNION_ROOM_MEMBERS do
                if not positionMap[tostring(i)] then
                    enablePoint = i
                    break
                end
            end

            -- add member
            local memberCardData = virtualData.createCardData(cardIdList[_r(#cardIdList)])
            local memberData = {
                job                = UNION_JOB_TYPE.COMMON,
                playerId           = agreePlayerData.playerId,
                playerName         = string.fmt('%2_%3)%1', agreePlayerData.playerName, enableRoomId, enablePoint),
                playerAvatar       = agreePlayerData.playerAvatar,
                playerAvatarFrame  = agreePlayerData.playerAvatarFrame,
                playerLevel        = agreePlayerData.playerLevel,
                contributionPoint_ = 0,
                lastExitTime_      = os.time() - virtualData.createSecond('d:5:?,h:24:?,s:60:?'),
                position_          = enablePoint,
                roomId_            = enableRoomId,
                cardId_            = memberCardData.cardId,
                skinId_            = memberCardData.defaultSkinId,
            }
            table.insert(virtualData.union_.member, memberData)
    
            -- add number
            local roomMember = checkint(virtualData.union_.roomMemberNumber[tostring(enableRoomId)])
            virtualData.union_.roomMemberNumber[tostring(enableRoomId)] = roomMember + 1
            
            if virtualData.union_.roomId == memberData.roomId_ then
                -- add room
                table.insert(virtualData.union_.roomMember, {
                    playerId = memberData.playerId,
                    position = memberData.position_
                })

                -- send 7007
                gameServer:sendAllClient(NetCmd.UNION_ROOM_APPEND, {data = {
                    roomId          = memberData.roomId_,
                    position        = memberData.position_,
                    memberId        = memberData.playerId,
                    memberName      = memberData.playerName,
                    defaultCardId   = memberData.cardId_,
                    defaultCardSkin = memberData.skinId_,
                }})
            else
                -- send 7003
                gameServer:sendAllClient(NetCmd.UNION_ROOM_MEMBER, {data = {
                    roomId    = memberData.roomId_,
                    memberNum = virtualData.union_.roomMemberNumber[tostring(memberData.roomId_)]
                }})
            end

            return t2t({})

        else
            return t2t({}, -1, '工会已满，没有可用的房间')
        end

    else
        return t2t({}, -1, '接受了一个不存在的玩家')
    end
end


-------------------------------------------------
-- 工会成员列表
virtualData['Union/member'] = function(args)
    local data = {
        member = {}
    }
    for i, memberData in ipairs(virtualData.union_.member) do
        table.insert(data.member, {
            job               = memberData.job,
            playerId          = memberData.playerId,
            playerName        = memberData.playerName,
            playerAvatar      = memberData.playerAvatar,
            playerAvatarFrame = memberData.playerAvatarFrame,
            playerLevel       = memberData.playerLevel,
            contributionPoint = memberData.contributionPoint_,
            lastExitTime      = memberData.lastExitTime_,
            isOnline          = _r(0,1),  -- 是否在线 1:在线 0:不在线
        })
    end
    return t2t(data)
end


-- 工会排行榜单
virtualData['Union/rank'] = function(args)
    local data = {
        member = {}
    }
    for i, memberData in ipairs(virtualData.union_.member) do
        table.insert(data.member, {
            playerId             = memberData.playerId,
            playerName           = memberData.playerName,
            playerLevel          = memberData.playerLevel,
            playerAvatar         = memberData.playerAvatar,
            playerAvatarFrame    = memberData.playerAvatarFrame,
            contributionPoint    = memberData.contributionPoint_,
            lastExitTime         = memberData.lastExitTime_,
            job                  = memberData.job,
            isOnline             = _r(0,1), -- 是否在线 1:在线 0:不在线
            buildTimes           = _r(99),  -- 建造次数(每周)
            dailyFeedPetTimes    = _r(99),  -- 喂养神兽次数(每日)
            dailyFeedPetSatiety  = _r(99),  -- 喂养获得饱食度(每日)
            feedPetTimes         = _r(99),  -- 喂养神兽次数(每周)
            worldBossDailyDamage = _r(99),  -- 世界boss伤害
        })
    end
    return t2t(data)
end


-- 修改工会信息
virtualData['Union/changeInfo'] = function(args)
    if args.name then
        virtualData.union_.name = tostring(args.name)
    end
    if args.avatar then
        virtualData.union_.avatar = args.avatar
    end
    if args.unionSign then
        virtualData.union_.unionSign = tostring(args.unionSign)
    end
    if args.applyPermission then
        virtualData.union_.applyPermission = checkint(args.applyPermission)
    end
    return t2t({})
end


-- 更改工会大厅形象
virtualData['Union/changeAvatar'] = function(args)
    for _, memberData in ipairs(virtualData.union_.roomMember) do
        if memberData.playerId == virtualData.playerData.playerId then
            memberData.defaultCardId   = args.defaultCardId
            memberData.defaultCardSkin = args.defaultCardSkin
            break
        end
    end
    return t2t({})
end


-- 工会认命职位
virtualData['Union/assignJob'] = function(args)
    local memberId  = checkint(args.memberId)
    local memberJob = checkint(args.job)
    for _, memberData in ipairs(virtualData.union_.member) do
        if memberData.playerId == memberId then
            memberData.job = memberJob
            break
        end
    end
    return t2t({})
end


-- 工会踢出成员
virtualData['Union/kickOut'] = function(args)
    local memberId    = checkint(args.memberId)
    local memberCount = #virtualData.union_.member
    for i = memberCount, 1, -1 do
        local memberData = virtualData.union_.member[i]
        if memberData.playerId == memberId then

            -- update member number
            local roomMemberNum = virtualData.union_.roomMemberNumber[tostring(memberData.roomId_)]
            virtualData.union_.roomMemberNumber[tostring(memberData.roomId_)] = roomMemberNum - 1

            -- check is current room
            if virtualData.union_.roomId == memberData.roomId_ then
                -- remove roomMember
                for j = #virtualData.union_.roomMember, 1, -1 do
                    local roomerData = virtualData.union_.roomMember[j]
                    if roomerData.playerId == memberId then
                        table.remove(virtualData.union_.roomMember, j)
                        break
                    end
                end
                
                -- send 7007
                gameServer:sendAllClient(NetCmd.UNION_ROOM_QUIT, {data = {
                    roomId   = memberData.roomId_,
                    memberId = memberData.playerId,
                    position = memberData.position_
                }})
            else
                -- send 7003
                gameServer:sendAllClient(NetCmd.UNION_ROOM_MEMBER, {data = {
                    roomId    = memberData.roomId_,
                    memberNum = virtualData.union_.roomMemberNumber[tostring(memberData.roomId_)]
                }})
            end
            
            -- remove member
            table.remove(virtualData.union_.member, i)
            break
        end
    end
    return t2t({})
end


-- 工会任务
virtualData['Union/task'] = function(args)
    local data = {
        tasks             = {},                                -- 任务列表
        refreshTime       = string.format('%0.2d:00', _r(10)), -- 刷新时间 05:00
        contributionPoint = _r(9999),                          -- 完成任务贡献度
    }
    for _, unionTaskConf in pairs(unionTaskConfs) do
        if virtualData.union_.level >= checkint(unionTaskConf.openUnionLevel) then
            table.insert(data.tasks, {
                taskId            = checkint(unionTaskConf.id),                -- 任务id
                taskName          = checkstr(unionTaskConf.name),              -- 名字
                taskType          = checkint(unionTaskConf.taskType),          -- 类型
                rewards           = checktable(unionTaskConf.rewards),         -- 奖励
                contributionPoint = checkint(unionTaskConf.contributionPoint), -- 贡献度
                targetNum         = checkint(unionTaskConf.taskNum),           -- 目标数量
                progress          = _r(checkint(unionTaskConf.taskNum)),       -- 进度
                hasDrawn          = _r(0,1),                                   -- 0:未领取 1:已领取
            })
        end
    end
    return t2t(data)
end
-- 工会任务领取
virtualData['Union/drawTask'] = function(args)
    local drawTaskId = checkint(args.taskId)
    local data = {
        rewards = {}
    }
    for _, unionTaskConf in pairs(unionTaskConfs) do
        if drawTaskId == checkint(unionTaskConf.id) then
            data.rewards = checktable(unionTaskConf.rewards)
            break
        end
    end
    return t2t(data)
end


-- 工会建造
virtualData['Union/build'] = function(args)
    local totalBuildTimes = virtualData.union_.leftBuildTimes[tostring(args.buildId)]
    local leftBuildTimes  = totalBuildTimes - checkint(args.times)
    virtualData.union_.leftBuildTimes[tostring(args.buildId)] = leftBuildTimes

    local unionBuildConf    = unionBuildConfs[tostring(args.buildId)] or {}
    local contributionPoint = checkint(unionBuildConf.contributionPoint) * checkint(args.times)
    virtualData.union_.contributionPoint       = virtualData.union_.contributionPoint + contributionPoint
    virtualData.union_.playerContributionPoint = virtualData.union_.playerContributionPoint + contributionPoint

    local playerUnionPoint = checkint(unionBuildConf.unionPoint) * checkint(args.times)
    virtualData.playerData.unionPoint = virtualData.playerData.unionPoint + playerUnionPoint

    local data = {
        unionPoint        = virtualData.playerData.unionPoint,
        contributionPoint = virtualData.union_.playerContributionPoint,
        leftBuildTimes    = leftBuildTimes,
    }
    return t2t(data)
end


-------------------------------------------------
-- 工会商城
-------------------------------------------------

-- 工会商城
virtualData['Union/mall'] = function(args)
    local data = {
        products               = {},      -- 商品列表
        refreshDiamond         = _r(99),  -- 刷新钻石单价
        refreshLeftTimes       = _r(9),   -- 手动刷新剩余次数
        nextRefreshLeftSeconds = _r(99),  -- 下一次自动刷新剩余秒数
    }
    
    local moneyConfs  = virtualData.getConf('goods', 'money')
    local moneyIdList = table.keys(moneyConfs)
    for i = 1, _r(6,10) do
        local goodsData = virtualData.createGoodsList(1)[1]
        table.insert(data.products, {
            productId        = virtualData.generateUuid(),    -- 商品id
            goodsId          = goodsData.goodsId,             -- 道具id
            goodsNum         = goodsData.num,                 -- 道具数量
            currency         = moneyIdList[_r(#moneyIdList)], -- 货币
            price            = _r(99),                        -- 价格
            leftPurchasedNum = _r(9),                         -- 剩余可购买次数
            stock            = _r(9),                         -- 可购买次数
            unlockType       = {
                [tostring(UnlockTypes.UNION_LEVEL)] = {targetNum = _r(0,3)}  -- @see unlockType.json
            }
        })
    end
    virtualData.unionMallList_ = data
    return t2t(data)
end
-- 商城刷新
virtualData['Union/mallRefresh'] = function(args)
    local data = {
        gold    = virtualData.playerData.gold,
        diamond = virtualData.playerData.diamond,
    }
    return t2t(data)
end
-- 商城购买
virtualData['Union/mallBuy'] = function(args)
    local data = {
        rewards = {}
    }
    local buyProductId = checkint(args.productId)
    for _, productData in ipairs(virtualData.unionMallList_.products) do
        if productData.productId == buyProductId then
            table.insert(data.rewards, {
                goodsId = productData.goodsId,
                num     = productData.goodsNum,
            })
            break
        end
    end
    return t2t(data)
end
-- 商城一键购买
virtualData['Union/mallBuyMulti'] = function(args)
    local data = {
        rewards = {}
    }
    for _, productId in ipairs(string.split2(args.products, ',')) do
        if checkint(productId) > 0 then
            local buyProductId = checkint(productId)
            for _, productData in ipairs(virtualData.unionMallList_.products) do
                if productData.productId == buyProductId then
                    table.insert(data.rewards, {
                        goodsId = productData.goodsId,
                        num     = productData.goodsNum,
                    })
                    break
                end
            end
        end
    end
    return t2t(data)
end


-------------------------------------------------
-- 工会狩猎
-------------------------------------------------

-- 工会狩猎
virtualData['Union/hunting'] = function(args)
    if not virtualData.unionHunting_ then
        virtualData.unionHunting_ = {
            godBeast = {}
        }
        for _, godBeastConf in pairs(unionGodBeastConfs) do
            local godBeastId  = checkint(godBeastConf.id)
            local petId       = checkint(godBeastConf.petId)
            local petGrowConf = godBeastGrowConfs[tostring(petId)] or {}
            local petMaxLevel = table.nums(petGrowConf)
            virtualData.unionHunting_.godBeast[tostring(godBeastId)] = {
                id             = godBeastId,                                      -- 神兽ID
                level          = _r(1, petMaxLevel),                              -- 神兽等级，0为幼体
                captured       = 0,                                               -- 1: 已获得 0: 未获得
                remainHp       = 12345,                                           -- 剩余血量
                leftHuntTimes  = 9,                                               -- 剩余猎杀次数
                leftSeconds    = virtualData.createSecond('d:5:?,h:24:?,s:60:?'), -- 剩余 刷新/恢复 时间(秒)
                leftBuyLiveNum = 3,                                               -- 剩余买活次数
                maxBuyLiveNum  = 5,                                               -- 最大买活次数
            }
        end
    end
    return t2t(virtualData.unionHunting_)
end
-- 工会狩猎战斗
virtualData['Union/huntingQuestAt'] = function(args)
    virtualData.unionHuntingQuestAt_ = {
        godBeastId = checkint(args.godBeastId),
        questCards = string.split2(args.cards, ';'),
    }
    local data = {
        maxCritDamageTimes = 0,
        maxSkillTimes      = 0,
    }
    return t2t(data)
end
-- 工会狩猎结算
virtualData['Union/huntingQuestGrade'] = function(args)
    local huntingGodBeastData = virtualData.unionHunting_ and checktable(virtualData.unionHunting_.godBeast) or {}
    local godBeastQueestConf  = godBeastQueestConfs[tostring(args.questId)] or {}
    local godBeastQueestData  = huntingGodBeastData[tostring(godBeastQueestConf.name)] or {}
    
    local godDamage = 10000
    local data = {
        remainHp  = checkint(godBeastQueestData.remainHp) - godDamage,
        rewards   = checktable(godBeastQueestConf.rewards),
        rankScore = godDamage,
        rank      = _r(9),
        energy    = _r(99),
    }
    return t2t(data)
end


-------------------------------------------------
-- 工会宠物
-------------------------------------------------

-- 公会宠物
virtualData['Union/pet'] = function(args)
    local data = {
        feedFavoriteFoodBonus = 0,  -- 工会宠物喜爱的菜加成
        pet = {},
    }

    for _, godBeastConf in pairs(unionGodBeastConfs) do
        local petId           = checkint(godBeastConf.petId)
        local petGrowConf     = godBeastGrowConfs[tostring(petId)] or {}
        local petMaxLevel     = table.nums(petGrowConf)
        local petLevel        = _r(1, petMaxLevel)
        local petEnergyLevel  = _r(1, petMaxLevel)
        local petSatietyLevel = _r(1, petMaxLevel)
        local petEnergyConf   = godBeastEnergyConfs[tostring(petEnergyLevel)] or {}
        local petSatietyConf  = godBeastSatietyConfs[tostring(petSatietyLevel)] or {}
        local petData         = {
            petId         = petId,                             -- 宠物ID
            energy        = checkint(petEnergyConf.totalExp),  -- 宠物 能量值
            energyLevel   = petEnergyLevel,                    -- 宠物 能量等级
            satiety       = checkint(petSatietyConf.totalExp), -- 宠物 饱食纸
            satietyLevel  = petSatietyLevel,                   -- 宠物 饱食等级
            favoriteFoods = {},                                -- 宠物喜爱的食物
        }
        table.insert(data.pet, petData)
    end
    return t2t(data)
end


-------------------------------------------------
-- 工会派对
-------------------------------------------------

-- 工会派对进行中
virtualData['Union/partyChop'] = function(args)
    if not virtualData.unionParty_ then
        virtualData.unionParty_ = {
            partyLevel = _r(1,4),
            unionLevel = math.max(3, _r(table.nums(unionLevelConfs))),
            foodGrade  = {},
            foodScore  = {},
            goldScore  = {},
            bossQuest  = {},
            bossResult = {},
            selfPassed = {},
        }
        
        -- foodGrade
        for _, foodId in ipairs(foodIdList) do
            virtualData.unionParty_.foodGrade[tostring(foodId)] = _r(100) > 30 and _r(1,4) or 5
        end

        -- foodScore / goldScore
        local dropFoodStepIdList  = {
            UNION_PARTY_STEPS.R1_DROP_FOOD_1,
            UNION_PARTY_STEPS.R1_DROP_FOOD_2,
            UNION_PARTY_STEPS.R2_DROP_FOOD_1,
            UNION_PARTY_STEPS.R2_DROP_FOOD_2,
            UNION_PARTY_STEPS.R3_DROP_FOOD_1,
            UNION_PARTY_STEPS.R3_DROP_FOOD_2,
        }
        for _, stepId in ipairs(dropFoodStepIdList) do
            virtualData.unionParty_.foodScore[tostring(stepId)] = _r(99)
            virtualData.unionParty_.goldScore[tostring(stepId)] = _r(999)
        end

        -- bossQuest
        local partyBossQuestIdList = table.keys(unionPartyQuestConfs)
        local bossQuestStepIdList  = {
            UNION_PARTY_STEPS.R1_BOSS_QUEST,
            UNION_PARTY_STEPS.R2_BOSS_QUEST,
            UNION_PARTY_STEPS.R3_BOSS_QUEST,
        }
        for _, stepId in ipairs(bossQuestStepIdList) do
            virtualData.unionParty_.bossQuest[tostring(stepId)]  = partyBossQuestIdList[_r(#partyBossQuestIdList)]
            virtualData.unionParty_.bossResult[tostring(stepId)] = virtualData.union.toFail and 0 or _r(20, 40)
            virtualData.unionParty_.selfPassed[tostring(stepId)] = _r(0,1)
        end
    end

    -------------------------------------------------
    local partyStepUpdateFunc = function(partyStepId)
        -- boss quest step
        if (partyStepId == UNION_PARTY_STEPS.R1_BOSS_QUEST or
            partyStepId == UNION_PARTY_STEPS.R2_BOSS_QUEST or
            partyStepId == UNION_PARTY_STEPS.R3_BOSS_QUEST) then
            local bossQuestStepId   = checkint(partyStepId)
            local bossQuestStepConf = unionPartyTimeConfs[tostring(bossQuestStepId)] or {}
            stopPartyBossResultAutoRunFunc()
            begainPartyBossResultAutoRunFunc(bossQuestStepId, bossQuestStepConf.seconds)
    
        -- boss resutl step
        elseif (partyStepId == UNION_PARTY_STEPS.R1_BOSS_RESULT or
                partyStepId == UNION_PARTY_STEPS.R2_BOSS_RESULT or
                partyStepId == UNION_PARTY_STEPS.R3_BOSS_RESULT) then
            local bossResultStepId   = checkint(partyStepId)
            local bossResultStepConf = unionPartyTimeConfs[tostring(bossResultStepId)] or {}
            stopPartyBossResultAutoRunFunc()
            begainPartyBossResultAutoRunFunc(bossResultStepId - 1, bossResultStepConf.seconds)

        -- boss resutl step
        elseif (partyStepId == UNION_PARTY_STEPS.R1_ROLL_REWARDS or
                partyStepId == UNION_PARTY_STEPS.R2_ROLL_REWARDS or
                partyStepId == UNION_PARTY_STEPS.R3_ROLL_REWARDS) then
            local rollRewardsStepId   = checkint(partyStepId)
            local rollRewardsStepConf = unionPartyTimeConfs[tostring(rollRewardsStepId)] or {}
            stopPartyRollRewardsAutoRunFunc()
            begainPartyRollRewardsAutoRunFunc(os.time() + rollRewardsStepConf.seconds)
        end
    end

    local unionManager = AppFacade.GetInstance():GetManager('UnionManager')
    partyStepUpdateFunc(unionManager:getPartyCurrentStepId())

    AppFacade.GetInstance():UnRegistObserver(SGL.UNION_PARTY_STEP_CHANGE, virtualData)
    AppFacade.GetInstance():RegistObserver(SGL.UNION_PARTY_STEP_CHANGE, mvc.Observer.new(function(_, signal)
        partyStepUpdateFunc(signal:GetBody().stepId)
    end, virtualData))

    return t2t(virtualData.unionParty_)
end


-- 工会派对掉菜
virtualData['Union/partyChopFoodAt'] = function(args)
    local partyTimeConf   = unionPartyTimeConfs[tostring(args.stepId)] or {}
    local dropConfSeconds = checkint(partyTimeConf.seconds)
    local TOTAL_TIME      = (dropConfSeconds - 3) * 1000
    local foodLength      = #foodIdList
    local AREA_COUNT      = 10

    -- create food
    local FOOD_COUNT   = dropConfSeconds * 5
    local dropFoodList = {}
    for i = 1, FOOD_COUNT do
        local dropTime   = checkint(TOTAL_TIME / FOOD_COUNT * i)
        local dropFoodId = checkint(foodIdList[_r(foodLength)])
        local dropAreaId = _r(AREA_COUNT)
        table.insert(dropFoodList, table.concat({dropTime, dropFoodId, dropAreaId}, ','))
    end

    -- create sprite
    local SPRITE_COUNT   = dropConfSeconds * 1
    local dropSpriteList = {}
    for i = 1, SPRITE_COUNT do
        local dropTime   = checkint(TOTAL_TIME / SPRITE_COUNT * i)
        local dropAreaId = _r(AREA_COUNT)
        table.insert(dropSpriteList, table.concat({dropTime, dropAreaId}, ','))
    end

    local data = {
        dropFoods  = table.concat(dropFoodList, ';'),
        dropRubies = table.concat(dropSpriteList, ';'),
    }
    return t2t(data)
end
virtualData['Union/partyChopFoodGrade'] = function(args)
    virtualData.playerData.gold = virtualData.playerData.gold + checkint(args.goldScore)
    local data = {
        foodScore  = args.foodScore,
        goldScore  = args.goldScore,
        playerGold = virtualData.playerData.gold
    }
    return t2t(data)
end


-- 工会派对战斗
virtualData['Union/partyChopQuestAt'] = function(args)
    local data = {
        maxSkillTimes      = 0,
        maxCritDamageTimes = 0,
    }
    return t2t(data)
end
virtualData['Union/partyChopQuestGrade'] = function(args)
    local isPassed = checkint(args.isPassed) == 1
    if isPassed then
    end
    return t2t({})
end
virtualData['Union/partyChopQuestResult'] = function(args)
    local data = {
        memberWinTimes = virtualData.union.toFail and 0 or _r(20, 40)
    }
    return t2t(data)
end


-- 工会派对ROLL点
virtualData['Union/partyChopRollHome'] = function(args)
    virtualData.unionPartyMember_ = {
        rollResult  = {},
        rollRewards = {}
    }
    for i = 1, 4 do
        virtualData.unionPartyMember_.rollRewards[tostring(i)] = virtualData.createGoodsList(1)[1]
    end

    for i = 1, 23 do
        virtualData.unionPartyMember_.rollResult[i] = {
            playerId   = virtualData.createPlayerId(),
            playerName = i .. ')' .. virtualData.createName(_r(8,16)),
            rollPoint  = _r(-1,2),
        }
    end
    table.insert(virtualData.unionPartyMember_.rollResult, {
        playerId   = virtualData.playerData.playerId,
        playerName = virtualData.playerData.playerName,
        rollPoint  = _r(-1,2),
    })
    return t2t(virtualData.unionPartyMember_)
    
end
virtualData['Union/partyChopRoll'] = function(args)
    local data = {
        rollPoint = 0
    }
    for i, memberData in ipairs(virtualData.unionPartyMember_.rollResult) do
        if memberData.playerId == virtualData.playerData.playerId then
            data.rollPoint = checkint(args.giveUp) == 1 and -1 or _r(99)
            memberData.rollPoint = data.rollPoint
            break
        end
    end
    return t2t(data)
end
virtualData['Union/partyChopRollResult'] = function(args)
    local data = {
        leftSeconds = _r(-3, 1),
        result = {}
    }
    for i = 1, 4 do
        data.result[tostring(i)] = {
            playerName = virtualData.createName(_r(8,16)),
            rewards    = virtualData.createGoodsList(1),
            rollPoint  = _r(999),
        }
    end
    return t2t(data)
end


-- 同步派对基础时间
virtualData['Union/partySyncBaseTime'] = function(args)
    virtualData.playerData.union.partyBaseTime = os.time()
    local data = {
        partyBaseTime = virtualData.playerData.union.partyBaseTime
    }
    return t2t(data)
end


-------------------------------------------------
-- 工会战
-------------------------------------------------

-- 工会战 主页
virtualData['Union/warsHome/appMediator'] = function(args)
    virtualData.unionWars_ = nil
    return virtualData['Union/warsHome'](args)
end
virtualData['Union/warsHome'] = function(args)
    if not virtualData.unionWars_ then
        local jumpToOffsetTime  = -2
        local jumpToTimeIndex   = 3
        local unionWarsBaseTime = os.time() - jumpToOffsetTime
        for i = 1, math.min(table.nums(unionWarsTimeConfs), jumpToTimeIndex) do
            local timeConf = unionWarsTimeConfs[tostring(i)] or {}
            unionWarsBaseTime = unionWarsBaseTime - checkint(timeConf.seconds)
        end
    
        virtualData.unionWars_ = {
            warsBaseTime    = unionWarsBaseTime, -- 工会战开启时间戳
            deadCards       = {},                -- 工会战 死亡队伍（逗号分隔）
            defendCards     = nil,               -- 工会战 防御队伍（逗号分隔）
            pastDefendCards = nil,               -- 工会战 以往的防御队伍（逗号分隔）
            leftAttachNum   = 3,                 -- 剩余挑战次数
            totalAttachNum  = 5,                 -- 总挑战次数
            passedBuildings = nil,               -- 自己打通的建筑id（逗号分隔）
            pastWarsResult  = {},                -- 过去的工会战结果
            joinRewards     = nil,--virtualData.createGoodsList(_r(1,8)),  -- 参与奖励
        }

        -- passedBuildings
        local passedBuildingList = {}
        for i = 1, 3 do
            table.insert(passedBuildingList, i)
        end
        virtualData.unionWars_.passedBuildings = table.concat(passedBuildingList, ',')

        -- pastWarsResult
        if virtualData.unionWars_.pastWarsResult then
            local unionIconList   = table.valuesAt(unionAvatarConfs, 'iconId')
            virtualData.unionWars_.pastWarsResult = {
                attackResult           = _r(0,1),                           -- 进攻的结果（1:赢 0:输）
                attackEnemyUnionName   = virtualData.createName(_r(6,12)),  -- 攻打敌方 工会名字
                attackEnemyUnionAvatar = unionIconList[_r(#unionIconList)], -- 攻打敌方 工会头像
                attackEnemyUnionLevel  = _r(10),                            -- 攻打敌方 工会等级
                defendResult           = _r(0,1),                           -- 进攻的结果（1:赢 0:输）
                defendEnemyUnionName   = virtualData.createName(_r(6,12)),  -- 防守敌方 工会名字
                defendEnemyUnionAvatar = unionIconList[_r(#unionIconList)], -- 防守敌方 工会头像
                defendEnemyUnionLevel  = _r(10),                            -- 防守敌方 工会等级
            }
        end

        -- dead cards
        local teamCards = {}
        local haveCards = table.keys(virtualData.playerData.cards)
        for i = 1, math.min(#haveCards, 5) do
            local cardId = table.remove(haveCards, _r(#haveCards))
            table.insert(teamCards, cardId)
        end
        virtualData.unionWars_.deadCards = table.concat(teamCards, ',')

        -- defend cards
        local isPreSetDefendCards =  true
        if isPreSetDefendCards then
            local teamCards = {}
            local haveCards = table.keys(virtualData.playerData.cards)
            for i = 1, math.min(#haveCards, 5) do
                local cardId = table.remove(haveCards, _r(#haveCards))
                table.insert(teamCards, cardId)
            end
            virtualData.unionWars_.defendCards = table.concat(teamCards, ',')
        end

        -- pastDefend Cards
        local teamCards = {}
        local haveCards = table.keys(virtualData.playerData.cards)
        for i = 1, math.min(#haveCards, 5) do
            local cardId = table.remove(haveCards, _r(#haveCards))
            table.insert(teamCards, cardId)
        end
        virtualData.unionWars_.pastDefendCards = table.concat(teamCards, ',')

        begainWarsSiteStateAutoRunFunc()
    end
    return t2t(virtualData.unionWars_)
end


-- 工会战 公会地图
virtualData['Union/warsUnionMap'] = function(args)
    if virtualData.unionWars_.defendCards then
        if not virtualData.unionWarsUnionMap_ then
            local bossQuestMap = {}
            for questId, questConf in pairs(warsBossQuestConfs) do
                local questType = checkint(questConf.type)
                bossQuestMap[tostring(questType)] = bossQuestMap[tostring(questType)] or {}
                table.insert(bossQuestMap[tostring(questType)], questConf)
            end

            local rQuestList   = bossQuestMap['1'] or {}
            local srQuestList  = bossQuestMap['2'] or {}
            local rQuestConf   = rQuestList[_r(1, #rQuestList)] or {}
            local srQuestConf  = srQuestList[_r(1, #srQuestList)] or {}
            local debuffIdList = UnionWarsModel.DEBUFF_LIST

            virtualData.unionWarsUnionMap_ = {
                warsBuildings     = {},             -- 工会战建筑
                warsBossRQuestId  = rQuestConf.id,  -- 工会boss R关卡id
                warsBossSRQuestId = srQuestConf.id, -- 工会boss SR关卡id
            }

            -- building data        
            local attendNum = _r(UnionWarsModel.ATTEND_MIN, UnionWarsModel.ATTEND_MAX)
            for i = 1, attendNum do
                local siteData = {
                    buildingId        = i,                                 -- 建筑id
                    playerId          = virtualData.createPlayerId(),      -- 玩家id
                    playerLevel       = _r(99),                            -- 玩家等级
                    playerName        = virtualData.createName(_r(4,8)),   -- 玩家名字
                    playerAvatar      = virtualData.createAvatarId(),      -- 玩家头像
                    playerAvatarFrame = virtualData.createAvatarFrameId(), -- 玩家头像框
                    playerCards       = {},                                -- 玩家卡牌阵容
                    playerHp          = 2,--_r(0, UnionWarsModel.SITE_HP_MAX), -- 玩家生命值
                    isDefending       = 0,--_r(0,1),                           -- 是否被攻击（0:正常，1:被攻击）
                    defendDebuff      = 0,--_r(0, #debuffIdList),              -- 防御debuff数量
                }
                -- 让自己参与报名
                if i == 1 then
                    siteData.playerId = virtualData.playerData.playerId
                end
                for i = 1, _r(1,5) do
                    table.insert(siteData.playerCards, virtualData.createCardData(nil, siteData.playerId))
                end
                table.insert(virtualData.unionWarsUnionMap_.warsBuildings, siteData)
            end
        end
        return t2t(virtualData.unionWarsUnionMap_)
    else
        return t2t({})
    end
end


-- 工会战 敌方地图
virtualData['Union/warsEnemyMap'] = function(args)
    if virtualData.unionWars_.defendCards then
        if not virtualData.unionWarsEnemyMap_ then
            local bossQuestMap = {}
            for questId, questConf in pairs(warsBossQuestConfs) do
                local questType = checkint(questConf.type)
                bossQuestMap[tostring(questType)] = bossQuestMap[tostring(questType)] or {}
                table.insert(bossQuestMap[tostring(questType)], questConf)
            end

            local rQuestList    = bossQuestMap['1'] or {}
            local srQuestList   = bossQuestMap['2'] or {}
            local rQuestConf    = rQuestList[_r(1, #rQuestList)] or {}
            local srQuestConf   = srQuestList[_r(1, #srQuestList)] or {}
            local unionIconList = table.valuesAt(unionAvatarConfs, 'iconId')
            local debuffIdList  = UnionWarsModel.DEBUFF_LIST

            virtualData.unionWarsEnemyMap_ = {
                unionName         = virtualData.createName(_r(6,12)),  -- 工会名字
                unionLevel        = _r(10),                            -- 工会等级
                unionAvatar       = unionIconList[_r(#unionIconList)], -- 工会头像
                warsBuildings     = {},                                -- 工会战建筑
                warsBossRQuestId  = rQuestConf.id,                     -- 工会boss R关卡id
                warsBossSRQuestId = srQuestConf.id,                    -- 工会boss SR关卡id
            }

            -- building data        
            local attendNum = _r(UnionWarsModel.ATTEND_MIN, UnionWarsModel.ATTEND_MAX)
            for i = 1, attendNum do
                local siteData = {
                    buildingId        = i,                                 -- 建筑id
                    playerId          = virtualData.createPlayerId(),      -- 玩家id
                    playerLevel       = _r(99),                            -- 玩家等级
                    playerName        = virtualData.createName(_r(4,8)),   -- 玩家名字
                    playerAvatar      = virtualData.createAvatarId(),      -- 玩家头像
                    playerAvatarFrame = virtualData.createAvatarFrameId(), -- 玩家头像框
                    playerCards       = {},                                -- 玩家卡牌阵容
                    playerHp          = 2,--_r(0, UnionWarsModel.SITE_HP_MAX), -- 玩家生命值
                    isDefending       = 0,--_r(0,1),                           -- 是否被攻击（0:正常，1:被攻击）
                    defendDebuff      = 0,--_r(0, #debuffIdList),              -- 防御debuff数量
                }
                for i = 1, _r(1,5) do
                    table.insert(siteData.playerCards, virtualData.createCardData(nil, siteData.playerId))
                end
                table.insert(virtualData.unionWarsEnemyMap_.warsBuildings, siteData)
            end
        end
        return t2t(virtualData.unionWarsEnemyMap_)
    else
        return t2t({})
    end
end


-- 工会战 设置防御队伍
virtualData['Union/setWarsDefendTeam'] = function(args)
    if virtualData.unionWars_ then
        virtualData.unionWars_.defendCards = args.teamCards
    end
    return t2t({})
end


-- 工会战 查看报名成员
virtualData['Union/warsApplyMembers'] = function(args)
    local data = {
        applyMembers = {}  -- 报名成员列表
    }
    for i = 1, UnionWarsModel.ATTEND_MAX + 5 do
        local memberData = {
            playerId          = virtualData.createPlayerId(),      -- 玩家id
            playerLevel       = _r(99),                            -- 玩家等级
            playerName        = virtualData.createName(_r(4,8)),   -- 玩家名字
            playerAvatar      = virtualData.createAvatarId(),      -- 玩家头像
            playerAvatarFrame = virtualData.createAvatarFrameId(), -- 玩家头像框
            playerCards       = {},                                -- 玩家卡牌阵容
            isJoin = _r(0,1), -- 是否参战（0:未参加，1:已参加）
        }
        for i = 1, _r(1,5) do
            table.insert(memberData.playerCards, virtualData.createCardData(nil, memberData.playerId))
        end
        table.insert(data.applyMembers, memberData)
    end
    return t2t(data)
end


-- 工会战 会长报名工会战
virtualData['Union/applyWars'] = function(args)
    scheduler.performWithDelayGlobal(function()
        virtualData.unionWars_.defendCards = args.members
        -- send 7017
        gameServer:sendAllClient(NetCmd.UNION_WARS_UNION_APPLY, {data = {}})
    end, 3)
    return t2t({})
end


-- 工会战 战报
virtualData['Union/warsReport'] = function(args)
    local seasonStartTime = os.time() - virtualData.createSecond('d:100:?,h:24:?,s:60:?')
    local seasonEndTime   = os.time() + virtualData.createSecond('d:100:?,h:24:?,s:60:?')
    local unionIconList   = table.valuesAt(unionAvatarConfs, 'iconId')
    local data = {
        unionWarScore          = _r(999),                                       -- 公会总积分
        unionWarRank           = _r(99),                                        -- 公会战排名
        attackReport           = {},                                            -- 进攻日志
        defendReport           = {},                                            -- 防守日志
        seasonStartTime        = virtualData.createFormatTime(seasonStartTime), -- 本赛季公会战 开始时间
        seasonEndTime          = virtualData.createFormatTime(seasonEndTime),   -- 本赛季公会战 截止时间
        attackEnemyUnionName   = virtualData.createName(_r(6,12)),              -- 攻打敌方 工会名字
        attackEnemyUnionLevel  = _r(10),                                        -- 攻打敌方 工会头像
        attackEnemyUnionAvatar = unionIconList[_r(#unionIconList)],             -- 攻打敌方 工会等级
        defendEnemyUnionName   = virtualData.createName(_r(6,12)),              -- 防守敌方 工会名字
        defendEnemyUnionLevel  = _r(10),                                        -- 防守敌方 工会头像
        defendEnemyUnionAvatar = unionIconList[_r(#unionIconList)],             -- 防守敌方 工会等级
    }

    for i = 1, _r(10) do
        local battleEndTime = os.time() - virtualData.createSecond('d:100:?,h:24:?,s:60:?')
        local attackData = {
            isPassed               = _r(0,1),                                     -- 对战结果（1: 过关 0: 未过关）
            enemyPlayerId          = virtualData.createPlayerId(),                -- 敌方玩家id
            enemyPlayerLevel       = _r(99),                                      -- 敌方玩家等级
            enemyPlayerName        = virtualData.createName(_r(4,8)),             -- 敌方玩家名字
            enemyPlayerAvatar      = virtualData.createAvatarId(),                -- 敌方玩家头像
            enemyPlayerAvatarFrame = virtualData.createAvatarFrameId(),           -- 敌方玩家头像框
            enemyPlayerCards       = {},                                          -- 敌方玩家卡牌阵容
            unionPlayerId          = virtualData.createPlayerId(),                -- 公会玩家id
            unionPlayerLevel       = _r(99),                                      -- 公会玩家等级
            unionPlayerName        = virtualData.createName(_r(4,8)),             -- 公会玩家名字
            unionPlayerAvatar      = virtualData.createAvatarId(),                -- 公会玩家头像
            unionPlayerAvatarFrame = virtualData.createAvatarFrameId(),           -- 公会玩家头像框
            unionPlayerCards       = {},                                          -- 公会玩家卡牌阵容
            unionBattleEndTime     = virtualData.createFormatTime(battleEndTime), -- 战斗结束时间
        }
        for i = 1, _r(1,5) do
            table.insert(attackData.enemyPlayerCards, virtualData.createCardData(nil, attackData.enemyPlayerId))
        end
        for i = 1, _r(1,5) do
            table.insert(attackData.unionPlayerCards, virtualData.createCardData(nil, attackData.unionPlayerId))
        end
        table.insert(data.attackReport, attackData)
    end

    for i = 1, _r(10) do
        local battleEndTime = os.time() - virtualData.createSecond('d:100:?,h:24:?,s:60:?')
        local defendData = {
            isPassed               = _r(0,1),                                     -- 对战结果（1: 过关 0: 未过关）
            enemyPlayerId          = virtualData.createPlayerId(),                -- 敌方玩家id
            enemyPlayerLevel       = _r(99),                                      -- 敌方玩家等级
            enemyPlayerName        = virtualData.createName(_r(4,8)),             -- 敌方玩家名字
            enemyPlayerAvatar      = virtualData.createAvatarId(),                -- 敌方玩家头像
            enemyPlayerAvatarFrame = virtualData.createAvatarFrameId(),           -- 敌方玩家头像框
            enemyPlayerCards       = {},                                          -- 敌方玩家卡牌阵容
            unionPlayerId          = virtualData.createPlayerId(),                -- 公会玩家id
            unionPlayerLevel       = _r(99),                                      -- 公会玩家等级
            unionPlayerName        = virtualData.createName(_r(4,8)),             -- 公会玩家名字
            unionPlayerAvatar      = virtualData.createAvatarId(),                -- 公会玩家头像
            unionPlayerAvatarFrame = virtualData.createAvatarFrameId(),           -- 公会玩家头像框
            unionPlayerCards       = {},                                          -- 公会玩家卡牌阵容
            unionBattleEndTime     = virtualData.createFormatTime(battleEndTime), -- 战斗结束时间
        }
        for i = 1, _r(1,5) do
            table.insert(defendData.enemyPlayerCards, virtualData.createCardData(nil, defendData.enemyPlayerId))
        end
        for i = 1, _r(1,5) do
            table.insert(defendData.unionPlayerCards, virtualData.createCardData(nil, defendData.unionPlayerId))
        end
        table.insert(data.defendReport, defendData)
    end
    return t2t(data)
end


-- 工会战 商城
virtualData['Union/warsMall'] = function(args)
    return virtualData['Union/mall'](args)
end
virtualData['Union/warsMallBuy'] = function(args)
    return virtualData['Union/mallBuy'](args)
end
virtualData['Union/warsMallBuyMulti'] = function(args)
    return virtualData['Union/mallBuyMulti'](args)
end
virtualData['Union/warsMallRefresh'] = function(args)
    return virtualData['Union/mallRefresh'](args)
end


-- 工会战 建筑点获胜货币
virtualData['Union/warsWinBuildGetCurrency'] = function(args)
    local data = {
        currency = args.buildingId
    }
    return t2t(data)
end
-- 工会战 攻击敌人
virtualData['Union/warsEnemyQuestAt'] = function(args)
    -- record quest buildingId
    virtualData.unionWars_.warsQuestAtEnemyBuildingId_ = args.warsBuildingId

    -- mark to defending
    if isPassed and virtualData.unionWarsEnemyMap_ or {} then
        for index, siteData in ipairs(virtualData.unionWarsEnemyMap_.warsBuildings) do
            if siteData.buildingId == virtualData.unionWars_.warsQuestAtEnemyBuildingId_ then
                siteData.isDefending = 0  
                break
            end
        end
    end

    local data = {
        maxSkillTimes      = 0,
        maxCritDamageTimes = 0,
    }
    return t2t(data)
end
-- 工会战 攻击敌人结算
virtualData['Union/warsEnemyQuestGrade'] = function(args)
    local isPassed = checkint(args.isPassed) == 1

    -- update leftAttackNum
    virtualData.unionWars_.leftAttachNum = virtualData.unionWars_.leftAttachNum - 1

    -- record dead cards
    if string.len(checkstr(args.deadCards)) > 0 then
        virtualData.unionWars_.deadCards = virtualData.unionWars_.deadCards .. ',' .. args.deadCards
    end

    -- cancel defending mark
    if isPassed and virtualData.unionWarsEnemyMap_ or {} then
        for index, siteData in ipairs(virtualData.unionWarsEnemyMap_.warsBuildings) do
            if siteData.buildingId == virtualData.unionWars_.warsQuestAtEnemyBuildingId_ then
                siteData.isDefending = 0

                -- check is win
                if isPassed then
                    siteData.playerHp = siteData.playerHp - 1
                else
                    siteData.defendDebuff = siteData.defendDebuff + 1
                end
                break
            end
        end
    end

    return t2t({})
end
-- 工会战 攻击BOSS
virtualData['Union/warsBossQuestAt'] = function(args)
    local data = {
        maxSkillTimes      = 0,
        maxCritDamageTimes = 0,
    }
    return t2t(data)
end
-- 工会战 攻击BOSS结算
virtualData['Union/warsBossQuestGrade'] = function(args)
    local isPassed = checkint(args.isPassed) == 1

    -- update leftAttackNum
    virtualData.unionWars_.leftAttachNum = virtualData.unionWars_.leftAttachNum - 1

    -- record dead cards
    if string.len(checkstr(args.deadCards)) > 0 then
        virtualData.unionWars_.deadCards = virtualData.unionWars_.deadCards .. ',' .. args.deadCards
    end

    return t2t({})
end