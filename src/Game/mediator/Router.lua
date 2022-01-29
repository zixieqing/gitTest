local Mediator = mvc.Mediator
---@class Router : Mediator
local Router = class("Router", Mediator)

local NAME = "Router"
local SpecialMediator = {['IceRoomMediator'] = 1,['CardsListMediatorNew'] = 1,['AvatarMediator'] = 1,['MapMediator'] = 1}
--得到一个实例dispatcher实例的逻辑

function Router:ctor( viewComponent )
	self.super:ctor(NAME, viewComponent)
    self.routes = { --配置所有的路由信息调整的对应关系 Kitchen/home , path = "Lobby/home"  , path = "Lobby/home"
        ["IceRoomMediator"]                                      = {                                path = "IcePlace/home" },
        ["NoticeMediator"]                                       = { excludes = "HomeMediator" },                                                                               --path = "Prize/enter",
        ["drawCards.CapsuleMediator"]                            = { excludes = "HomeMediator",     path = POST.GAMBLING_ENTER.postUrl },
        ["drawCards.CapsuleNewMediator"]                         = { excludes = "HomeMediator",     path = POST.GAMBLING_HOME.postUrl },
        ["activity.AnniversaryEntryMediator"]                    = { excludes = "HomeMediator",     path = POST.GAMBLING_HOME.postUrl },
        ["task.TaskHomeMediator"]                                = {                                                                                 isPoup = true },
        ["TeamFormationMediator"]                                = { excludes = {"HomeMediator", "AvatarMediator"} },
        ["CardsFragmentComposeMediator"]                         = { excludes = "HomeMediator" },
        ["MaterialComposeMediator"]                              = { excludes = "HomeMediator" },
        ["SeasonLiveMediator"]                                   = {},
        ["BackPackMediator"]                                     = { excludes = "HomeMediator" },
        ["StoryMissionsMediator"]                                = { excludes = "HomeMediator",                                                      isPoup = true },
        ["StoryMissionsCollectionMediator"]                      = { excludes = "HomeMediator" },
        ["StoryMissionsMessageMediator"]                         = { excludes = "HomeMediator" },
        ["LimitGiftMediator"]                                    = { excludes = "LimitGiftMediator" },
        ["CardsListMediator"]                                    = {},
        ["AuthorTransMediator"]                                  = {},
        ["CardsListMediatorNew"]                                 = {},
        ["MapMediator"]                                          = {},
        ["HomelandMediator"]                                     = { excludes = "HomeMediator" },
        ["AvatarMediator"]                                       = {                                path = 'Restaurant/home' },
        ["fishing.FishingGroundMediator"]                        = {                                path = 'fishPlace/home' },
        ["HomeMediator"]                                         = {},
        ["BattleMediator"]                                       = {},
        ["RaidBattleMediator"]                                   = { excludes = "TeamQuestMediator" },
        ["TeamQuestReadyMediator"]                               = { excludes = "TeamQuestMediator" },
        ["RaidHallMediator"]                                     = {                                path = 'QuestTeam/home' },
        ["DeliveryMediator"]                                     = { excludes = "HomeMediator" },
        ["TalentMediator"]                                       = { excludes = "HomeMediator" },
        ["WorldMediator"]                                        = {},
        ["BossStoryMediator"]                                    = {},
        ["CardEncyclopediaMediator"]                             = {},
        ["CardGatherRewardMediator"]                             = {                                path = 'cardCollection/home' },
        ["PromotersMediator"]                                    = {                                                                                isPoup = true },
        ["MaterialTranScriptMediator"]                           = {},
        ["MarketMediator"]                                       = { excludes = "HomeMediator" , isPoup = true},
        ["RobberyDetailMediator"]                                = { excludes = "HomeMediator" },
        ["ExplorationMediator"]                                  = { excludes = {"HomeMediator", "AvatarMediator"},                                 isPoup = true },
        ["RecipeResearchAndMakingMediator"]                      = { excludes = "HomeMediator",                                                     isPoup = true },
        ["RecipeDetailMediator"]                                 = { excludes = "HomeMediator" },
        ["HandbookMediator"]                                     = { excludes = "HomeMediator" },
        ["NPCManualHomeMediator"]                                = {},
        ["ActivityMediator"]                                     = {},
        ["FacebookInviteMediator"]                               = {},
        ["RankingListMediator"]                                  = { excludes = {"HomeMediator", "AvatarMediator", "LobbyInformationMediator", "PVCMediator"} },
        ["MapOverviewMediator"]                                  = {},
        ["PetDevelopMediator"]                                   = {                                path = 'pet/home' },
        ["ShopMediator"]                                         = { excludes = "HomeMediator",     path = POST.GAME_STORE_HOME.postUrl,            isPoup = true },            -- Restaurant/mall
        ["UpgradeLevelMediator"]                                 = {},
        ["TowerQuestHomeMediator"]                               = {                                path = POST.TOWER_HOME.postUrl },
        ["ActivityNewPlayerSevenDayMediator"]                    = { excludes = "HomeMediator",     path = 'Activity/newbieTask' },
        ["AirShipHomeMediator"]                                  = { excludes = "HomeMediator",     path = POST.AIRSHIP_HOME.postUrl },
        ["PVCMediator"]                                          = {                                path = 'offlineArena/home' },
        ["MaterialTranScriptMediator"]                           = {},
        ["BattleAssembleExportMediator"]                         = {},
        ["DeliveryAndExploreMediator"]                           = { excludes = "HomeMediator" },
        ['FriendMediator']                                       = { excludes = "HomeMediator" },
        ["UnionCreateHomeMediator"]                              = { excludes = "HomeMediator" },
        ["UnionShopMediator"]                                    = { excludes = "UnionLobbyMediator" , isPoup = true},
        ["UnionLobbyMediator"]                                   = {                                path = POST.UNION_HOME.postUrl },
        ["unionWars.UnionWarsHomeMediator"]                      = {                                path = POST.UNION_WARS_HOME.postUrl },
        ["WorldBossMediator"]                                    = {},
        ["ActivityMapMediator"]                                  = {},
        ["activity.balloon.ActivityBalloonMediator"]             = {},
        ["tagMatch.TagMatchLobbyMediator"]                       = { excludes = {"HomeMediator", "ActivityMediator", "TagMatchMediator"}, path = POST.TAG_MATCH_HOME.postUrl },
        ["tagMatchNew.NewKofArenaLobbyMediator"]                    = { excludes = {"HomeMediator", "ActivityMediator", "NewKofArenaEnterMediator"}, path = POST.NEW_TAG_MATCH_HOME.postUrl },
        ["artifact.JewelCatcherPoolMediator"]                    = {                                path = POST.ARTIFACT_GEM_LUCKY_CONSUME.postUrl, isPoup = true},
        ["tastingTour.TastingTourLobbyMediator"]                 = {},
        ["tastingTour.TastingTourChooseRecipeStyleMediator"]     = {},
        ["CumulativeRechargeMediator"]                           = { excludes = "HomeMediator",     path = POST.CUMULATIVE_RECHARGE_HOME.postUrl },
        ["RecallMainMediator"]                                   = { excludes = "HomeMediator",     path = POST.RECALL_HOME.postUrl },
        ["saimoe.SaiMoeSupportMediator"]                         = { excludes = "HomeMediator",     path = POST.SAIMOE_HOME.postUrl },
        ["saimoe.SaiMoeRankMediator"]                            = {                                path = 'Rank/comparisonRank',                   isPoup = true},
        ["activity.ArtifactRoad.ArtifactRoadMediator"]           = {                                path = POST.ACTIVITY_ARTIFACT_ROAD.postUrl },
        ["ptDungeon.PTDungeonHomeMediator"]                      = {                                path = POST.PT_HOME.postUrl },
        ["ThreeToThreeRankMediator"]                             = {},
        ["artifact.ArtifactTalentMediator"]                      = {},
        ["artifact.ArtifactLockMediator"]                        = {},
        ["exploreSystem.ExploreSystemMediator"]                  = {                                path = POST.EXPLORE_SYSTEM_HOME.postUrl },
        ["ResourceDownloadMediator"]                             = {},
        ["summerActivity.SummerActivityHomeMediator"]            = {                                                                                isPoup = true },
        ["summerActivity.SummerActivityHomeMapMediator"]         = {                                path = POST.SUMMER_ACTIVITY_CHAPTER.postUrl },
        ["summerActivity.carnie.CarnieCapsuleMediator"]          = {                                path = POST.CARNIE_CAPSULE_HOME.postUrl },
        ["summerActivity.carnie.CarnieCapsulePoolMediator"]      = {                                                                                isPoup = true },
        ["summerActivity.carnie.CarnieCapsuleRewardMediator"]    = {                                                                                isPoup = true },
        ["summerActivity.carnie.CarnieExCapsuleMediator"]        = {                                                                                isPoup = true },
        ["summerActivity.carnie.CarnieRankMediator"]             = {                                                                                isPoup = true },
        ["fishing.FishingShopMeditor"]                           = {                                                                                isPoup = true },
        ["privateRoom.PrivateRoomHomeMediator"]                  = {                                path = POST.PRIVATE_ROOM_HOME.postUrl },
        ["privateRoom.PrivateRoomWallShowMediator"]              = {                                                                                isPoup = true },
        ["anniversary.AnniversaryMainMediator"]                  = {},
        ["anniversary.AnniversaryMainLineMapMediator"]           = {},
        ["specialActivity.SpActivityMediator"]                   = {                                path = "Activity/home" },
        ["allRound.AllRoundHomeMediator"]                        = {},
        ["castle.CastleMainMediator"]                            = {},
        ["castle.CastleBattleMapMediator"]                       = {},
        ["returnWelfare.ReturnWelfareMediator"]                  = {                                path = POST.BACK_HOME.postUrl },
        ["plotCollect.PlotCollectMediator"]                      = {                                                                                isPoup = true },
        ["activity.murder.MurderHomeMediator"]                   = {},
        ["activity.murder.MurderMailMediator"]                   = {                                                                                isPoup = true },
        ["activity.murder.MurderAdvanceMediator"]                = {                                                                                isPoup = true },
        ["activity.murder.MurderChessboardMediator"]             = {                                                                                isPoup = true },
        ["activity.murder.MurderStoreMediator"]                  = {                                                                                isPoup = true },
        ["activity.murder.MurderStoryMediator"]                  = {                                                                                isPoup = true },
        ["activity.murder.MurderPointRewardsMediator"]           = {                                                                                isPoup = true },
        ["activity.murder.MurderRewardPreviewMediator"]          = {                                                                                isPoup = true },
        ["activity.murder.MurderMirrorMediator"]                 = {},
        ["activity.murder.MurderMirrorPoolMediator"]             = {                                                                                isPoup = true },
        ["activity.murder.MurderCapsuleRewardMediator"]          = {                                                                                isPoup = true },
        ["activity.murder.MurderExCapsuleMediator"]              = {                                                                                isPoup = true },
        ["activity.murder.MurderRankMediator"]                   = {                                                                                isPoup = true },
        ["activity.murder.MurderInvestigationMediator"]          = {},
        ["woodenDummy.WoodenDummyMediator"]                      = {},
        ["blackGold.BlackGoldHomeMeditor"]                       = {},
        ["order.OrderMediator"]                                  = { excludes = "HomeMediator"},
        ["activity.skinCarnival.ActivitySkinCarnivalMediator"]   = {                                path = POST.SKIN_CARNIVAL_HOME.postUrl},
        ["lunaTower.LunaTowerHomeMediator"]                      = {                                path = 'LunaTower/home' },
        ["anniversary19.Anniversary19HomeMediator"]              = {                                path = POST.ANNIVERSARY2_HOME.postUrl},
        ["anniversary19.Anniversary19ExploreMainMediator"]       = {},
        ["anniversary19.Anniversary19DreamCircleMainMediator"]   = {},
        ['anniversary19.Anniversary19SuppressMediator']          = { excludes = "anniversary19.Anniversary19HomeMediator", path = POST.ANNIVERSARY2_BOSS.postUrl },             -- 对应传入的needKeepGameScene参数来添加exclude
        ["ttGame.TripleTriadGameHomeMediator"]                   = {                                path = POST.TTGAME_HOME.postUrl },
        ["waterBar.WaterBarHomeMediator"]                        = {                                path = POST.WATER_BAR_HOME.postUrl },
        ["waterBar.WaterBarMarketMediator"]                      = { isPoup = true},
        ["waterBar.WaterBarShopMediator"]                        = { isPoup = true},
        ["stores.MemoryStoreMediator"]                           = { isPoup = true},
        ["artifactGuide.ArtifactGuideMediator"]                  = {                                path = POST.ARTIFACT_GUIDE_HOME.postUrl,        isPoup = true },
        ["springActivity20.SpringActivity20HomeMediator"]        = {                                path = POST.SPRING_ACTIVITY_20_HOME.postUrl},
        ["springActivity20.SpringActivity20StageMediator"]       = {                                path = POST.SPRING_ACTIVITY_20_HOME.postUrl},
        ["springActivity20.SpringActivity20BossMediator"]        = {                                path = POST.SPRING_ACTIVITY_20_HOME.postUrl},
        ["link.popTeam.PopTeamStageMediator"]                    = {                                path = POST.POP_TEAM_HOME.postUrl},
        ["activity.chest.ActivityChestMediator"]                 = {},
        ["championship.ChampionshipHomeMediator"]                = {                                path = POST.CHAMPIONSHIP_HOME.postUrl },
        ["link.popMain.PopMainMediator"]                         = {                                path = POST.POP_TEAM_HOME.postUrl                    },
        ["activity.assemblyActivity.AssemblyActivityMediator"]   = {                                },
        ["anniversary20.Anniversary20HomeMediator"]              = {                                path = POST.ANNIV2020_MAIN_HOME.postUrl},
        ["anniversary20.Anniversary20ExploreMainMediator"]       = {},
        ["anniversary20.Anniversary20ExploreHomeMediator"]       = {},
        ["collection.skinCollection.SkinCollectionMainMediator"] = {                                path = POST.CARD_SKIN_COLLECT_COMPLETED_TASK.postUrl},
        ["collection.roleIntroduction.RoleIntroductionMainMediator"] = {},
        ["AccountMigrationMediator"]                             = { excludes = "HomeMediator",     path = POST.TRANSFER_GET_CODE.postUrl, isPoup = true},
        ["collection.cardAlbum.CardAlbumMediator"]               = {}, 
        ["catHouse.CatHouseHomeMediator"]                        = {                                path = POST.HOUSE_HOME_ENTER.postUrl },
    }
    self.records = {} --记录跳转信息 {from = {name = 'mediator', params = {}} to = {name = 'mediator', params = {}}}
    self.isBack = false
end

function Router:InterestSignals()
	local signals = {
	}

    for k,v in pairs(self.routes) do
        if v.path then --如果存在信息的逻辑
            table.insert(signals, k)
        end
    end
	return signals
end

function Router:Initial( key )
	self.super.Initial(self,key)
end

function Router:ProcessSignal( signal )
    local name = signal.name
    if not self.routes[name].isPoup then
        local x = {name}
        if type(self.routes[name].excludes) == 'string' then
            table.insert(x,self.routes[name].excludes)
        elseif type(self.routes[name].excludes) == 'table' then
            for k,v in pairs(self.routes[name].excludes) do
                table.insert(x, v)
            end
        end
        self:ClearMediators(x) --清除对象

        --前往页面需要主页面存在。
        if self.routes[name].excludes == 'HomeMediator' and not AppFacade.GetInstance().viewManager.mediatorMap['HomeMediator'] then
            local filepath = "Game.mediator.HomeMediator"
            local moduleM = require( filepath)
            local mediator = moduleM.new()
            AppFacade.GetInstance():RegistMediator(mediator)
        end
    end

    local filepath = string.format("Game.mediator.%s", name)
    local moduleM  = require(filepath)
    local mediator = moduleM.new(signal:GetBody())
    if checktable(signal:GetBody()).requestData then
        mediator.initLayerData = signal:GetBody().requestData
    end
    mediator.initArgs = self.initArgs_
    mediator.payload  = signal.body
    self.initArgs_    = nil
    AppFacade.GetInstance():RegistMediator(mediator)
end

function Router:OnRegist()

end

function Router:OnUnRegist()

end


function Router:switchMdt(from, to, isBack, handleErrorSelf)
    local mediatorPath   = string.format('Game.mediator.%s', tostring(to.name))
    local mediatorClass  = require(mediatorPath)
    local mediatorParams = {
        from            = from,
        to              = to,
        isBack          = isBack,
        handleErrorSelf = handleErrorSelf
    }
    local switchMediator = function()
        if mediatorClass then
            self:Dispatch(mediatorParams.from, mediatorParams.to, mediatorParams.isBack, mediatorParams.handleErrorSelf)
        end
    end

    if DYNAMIC_LOAD_MODE then
        app.uiMgr:showDownloadResPopup({
            resDatas = mediatorClass and mediatorClass.RES_LIST or {},
            finishCB = switchMediator,
        })
    else
        switchMediator()
    end
end
function Router:loadMdt(mediatorPath, ...)
    local mediatorClass  = require(mediatorPath)
    local mediatorParams = {...}
    local createMediator = function()
        if mediatorClass then
            local mediatorObj = mediatorClass.new(unpack(mediatorParams))
            AppFacade.GetInstance():RegistMediator(mediatorObj)
        end
    end

    if DYNAMIC_LOAD_MODE then
        app.uiMgr:showDownloadResPopup({
            resDatas = mediatorClass and mediatorClass.RES_LIST or {},
            finishCB = createMediator,
        })
    else
        createMediator()
    end
end


--[[
-- 跳转的逻辑
-- @from  从哪里
--  {name = "mediatorName", params = {}, request = {}} 带的上要返回时回传的参数
-- @to   到哪里
--  {name = "mediatorName", params = {}, request = {}} 目标控制器所需要带的参数
-- @handleErrorSelf 自己处理错误码
--]]
function Router:Dispatch( from, to, isBack, handleErrorSelf)
    if type(from) ~= 'table' or type(to) ~= 'table' then
        funLog(Logger.ERROR, "当前所需参数的类型不存确")
        return
    end
    if isBack == nil then
        self.isBack = {isBack = false}
    else
        self.isBack = isBack
    end
    --正常的跳转的逻辑
    --HomeMediator/IceRoomMediator
    --IceRoomMediator/HomeMediator
    -- local store = string.format( "%s/%s",from.name, to.name )
    -- if not self.records[tostring(store)] then
        -- self.records[tostring(store)] = {from = from, to = to,isBack = self.isBack}
    -- end
    -- self.records = {}
    table.insert(self.records,{from = from, to = to,isBack = self.isBack})
    --判断是否有请求如果有请求先请求，所功后再跳转
    print("to.name  = " , to.name)
    if not self.routes[to.name] then
        funLog(Logger.INFO, "当前要跳转的控制器未注册")
        logs("当前要跳转的控制器未注册", to.name)
        return
    end
    local params = to.params or {}
    local isJumpRequest = params.isJumpRequest -- 是否跳过请求
    if self.routes[to.name].path and (not  isJumpRequest) then
        self.initArgs_ = to.initArgs
        --需要请求
        local requestData = (to.request or {})
        local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
        if to.params then
            httpManager:Post(self.routes[to.name].path, to.name, to.params, handleErrorSelf)
        else
            httpManager:Post(self.routes[to.name].path, to.name, nil, handleErrorSelf)
        end
    else
        --直接跳转的逻辑
        if to.name == "HomeMediator" then
            --要

            -- if SpecialMediator[tostring(to.name)] then
            --     self:ClearMediators(tostring(from.name))
            -- end
            self:ClearMediators(to.name) --清除对象
            -- self.records = {} --请除记录数据

            local homeParms = to.params or {}
            homeParms.from = from.name
            local filepath = string.format( "Game.mediator.%s", to.name )
            local moduleM  = require( filepath)
            local mediator = moduleM.new(homeParms)
            -- mediator.payload = to.params
            AppFacade.GetInstance():RegistMediator(mediator)
        else
            if not self.routes[to.name].isPoup then
                local x = {}
                if to.params then
                    if to.params.x then
                        x = {to.name,to.params.x}
                    else
                        x = {to.name}
                    end
                else
                    x = {to.name}
                end
                -- if SpecialMediator[tostring(to.name)] then
                --     self:ClearMediators()
                -- end
                if type(self.routes[to.name].excludes) == 'string' then
                    table.insert(x,self.routes[to.name].excludes)
                elseif type(self.routes[to.name].excludes) == 'table' then
                    for k,v in pairs(self.routes[to.name].excludes) do
                        table.insert(x, v)
                    end
                end
                self:ClearMediators(x) --清除对象
            end
            local filepath = string.format( "Game.mediator.%s",to.name )
            local moduleM = require( filepath)
            local mediator = moduleM.new(to.params)
            -- mediator.payload = to.params
            AppFacade.GetInstance():RegistMediator(mediator)

        end
    end
end

function Router:ClearMediators( excludes )
    local defaultExcludes = {
        "Router", "AppMediator", "HomeChatSystemMediator", 'TowerQuestRootMediator',
        'UpgradeLevelMediator','HomeUnlockFunctionMediator'
    }

    if not excludes then
        excludes = defaultExcludes
    else
        if type(excludes) == 'string' then
            table.insert(defaultExcludes, excludes)
            excludes = defaultExcludes

        elseif type(excludes) == 'table' then
            for i,v in ipairs(defaultExcludes) do
                table.insert(excludes, v)
            end
        end
    end

    local map = AppFacade.GetInstance().viewManager.mediatorMap
    for k,v in pairs(map) do
        if not table.indexof(excludes, k) then
            AppFacade.GetInstance():UnRegsitMediator(k) --移出不需要的管理者
        end
    end
end

--关闭指定页面
function Router:ClearAssignMediators( mediators )
    AppFacade.GetInstance():UnRegsitMediator(mediators)
end

function Router:RegistBackMediators(isNeedParams)
    -- dump(self.records)
    for i = table.nums(self.records), 1, -1 do
        local record = self.records[i]
        if record.isBack.isBack == true then
            record.isBack.isBack = false
            if isNeedParams == nil or isNeedParams == false then
                self:Dispatch({name = "HomeMediator"}, {name = record.from.name})
            else
                table.remove(self.records, i)
                if type(isNeedParams) == 'table' then
                    record.from.params = record.from.params or {}
                    table.merge(record.from.params, isNeedParams)
                end
                dump(record.from)
                self:Dispatch({}, record.from)
                return
            end
            break
        end
    end
    self.records = {}
end
--[[
清除指定的facade实例
@param key 指定的key类型
]]
function Router:Destroy( )

end

return Router
