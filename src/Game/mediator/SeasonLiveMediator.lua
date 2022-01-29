
---
--- Created by xingweihao.
--- DateTime: 27/10/2017 9:53 AM
---
local Mediator = mvc.Mediator
---@class SeasonLiveMediator :Mediator
local SeasonLiveMediator = class("SeasonLiveMediator", Mediator)
local NAME = "SeasonLiveMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local DIFFICULTY_LEVEL = 4
local DIFFICULTY_LEVEL_TABEL = {
    __('简单'),
    __('中等'),
    __('困难'),
    __('极难')
}
local BUTTON_CLICK  = {
    GOOD_NODE_TAG = 10001 , -- 获取GoodNode 的标志
    CLOSE_TAG = 10002 , -- 关闭的tag 值
}
local COST_DATA = {
    COST_TIMES =1 ,  -- 次数消耗
    COOS_GOODS =2 ,  -- 道具消耗
}
local  seasonQuestData = CommonUtils.GetConfigAllMess('quest' , 'seasonActivity')
local  seasonQuestTypeData = CommonUtils.GetConfigAllMess('questType' , 'seasonActivity')

function SeasonLiveMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)
    param  = param or {}
    self.activityId = param.activityId
    self.preIndex = nil
    self.seasonData = {} -- 材料副本的数据
    self.questData  =  seasonQuestData
    self.countNum =  0
end
function SeasonLiveMediator:InterestSignals()
    local signals = {
        POST.SEASON_ACTIVITY_GET_QUEST_CONFIG.sglName,
        POST.SEASON_ACTIVITY_SET_QUEST_CONFIG.sglName,
        SIGNALNAMES.CACHE_MONEY_UPDATE_UI
    }
    return signals
end
--[[
    初次合并数据
--]]
function SeasonLiveMediator:FirstMerageData()
    local questTypeData = clone(seasonQuestTypeData)
    local questData  = seasonQuestData
    for k ,v in pairs(questTypeData) do
        v.questData = {}  --  qusetData 用于手机关卡数据  "type,difficultly" --拼接方式为材料副本类型和材料副本难度
    end
    for k, v in pairs(questData) do
        local data = {}
        data.questId = v.id -- 记录关卡的id
        data.difficulty = v.difficulty
        data.recommendLevel = v.recommendLevel
        questTypeData[tostring(v.type)].questData[v.type .. "," .. v.difficulty] = data
    end
    for k , v in pairs ( questTypeData) do
        local  currentDifficultly = 1 -- 当前的默认难度
        v.currentDifficultly = currentDifficultly  --用于几录当前最匹配的难度
    end
    return questTypeData
end
--[[
    请求回来后 重新合并一次 本次主要用于排序和显示的使用
--]]
function SeasonLiveMediator:SecondMargeData(data)
    for k ,v in pairs(data.questInfo or {}) do
        -- 合并数据
        if self.seasonData[ k] then -- 判断该类型是否存在 如果不存在的话就不进行合并
            if checkint(v.lastDifficulty) > 0 then
                self.seasonData[k ].currentDifficultly = checkint(v.lastDifficulty)
            end
            table.merge(self.seasonData[k] , v)
        end
    end
end
function SeasonLiveMediator:Initial( key )
    self.super.Initial(self,key)

    self.seasonData  = self:FirstMerageData()
    --获取排列材料本的拍了顺序
    ---@type SeasonLiveView
    self.viewComponent = require('Game.views.SeasonLiveView').new()
    self.viewComponent:setPosition(display.center)
    uiMgr:SwitchToScene( self.viewComponent)

    self:BindClickHandler()
    self:UpdateView()
end
--[[
    更新界面的信息
--]]
function SeasonLiveMediator:UpdateView()
    local topIconData =  CommonUtils.GetConfigAllMess('topIcon', 'seasonActivity')
    local viewData = self.viewComponent.viewData
    local exchangeLayout = nil
    for i =1 , #viewData.exchangeTable do   -- 交换的道具
        exchangeLayout = viewData.exchangeTable[i]
        local goodsImage = exchangeLayout:getChildByName("goodsImage")
        local goodsId = topIconData[tostring(i)].goodsId
        if goodsImage and not (tolua.isnull(goodsImage)) then
            local iconPath = CommonUtils.GetGoodsIconPathById(goodsId)
            goodsImage:setTexture(iconPath)
        end
        local goodsNum = exchangeLayout:getChildByName("goodsNum")
        if goodsNum and  ( not tolua.isnull(goodsNum)) then
            local num = CommonUtils.GetCacheProductNum(goodsId)
            goodsNum:setString(num)
        end
    end
end
--[[
    获取到特殊字体的id

--]]


--[[
    绑定按钮的事件
--]]
function SeasonLiveMediator:BindClickHandler()
    local viewData = self.viewComponent.viewData
    viewData.navBack:setOnClickScriptHandler(handler(self, self.BackMediatorSaveData))
    local seasonLiveCell = require("Game.views.SeasonLiveCell")
    local scriptType =1
    local sortkey = {}
    for k ,v in pairs(self.seasonData) do
        sortkey[#sortkey+1] =  k
    end
    table.sort(sortkey , function (a,b)
        if checkint(a)> checkint(b) then
            return false
        end
        return true

    end)
    for  i =1 ,#sortkey  do -- 副本的数据
        scriptType = self.seasonData[sortkey[i]].themeType
        local cell = seasonLiveCell.new({type =  checkint(scriptType) })
        self:UpdateCell(cell , sortkey[i])
        viewData.gainListView:insertNodeAtLast(cell)
    end
    viewData.gainListView:reloadData()
    local containerSize = viewData.gainListView:getContainer():getContentSize()
    viewData.gainListView:setContentSize(containerSize)
    viewData.gainListView:setAnchorPoint(display.CENTER)
    viewData.gainListView:setPosition(cc.p(display.cx, display.cy))

end
---
function SeasonLiveMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.SEASON_ACTIVITY_GET_QUEST_CONFIG.sglName then
        -- 第二次组合数据
        local viewData = self.viewComponent.viewData
        local gainListView = viewData.gainListView
        self:SecondMargeData(data)
        local nodes = gainListView:getNodes()
        for k, v in pairs(nodes) do
            self:UpdateCell(v, k)
        end
    elseif name ==  SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
        if self.viewComponent then
            self.viewComponent:UpdateCountUI()
        end
    elseif name == POST.SEASON_ACTIVITY_SET_QUEST_CONFIG.sglName then
        local requestData  = data.requestData
        if checkint(requestData.isBattle)  == 1 then -- 如果为真的话就执行战斗操作
            self.preIndex = requestData.index
            local questData = self.seasonData[tostring(self.preIndex) ].questData
            local difficultly = self.seasonData[tostring(self.preIndex)].currentDifficultly
            local type = self.seasonData[tostring(self.preIndex)].id
            local questId = questData[type .."," .. difficultly].questId

            ------------ 初始化战斗构造器 ------------
            -- 网络命令
            local serverCommand = BattleNetworkCommandStruct.New(
                    POST.SEASON_ACTIVITY_QUEST_AT.cmdName,
                    {questId = questId},
                    POST.SEASON_ACTIVITY_QUEST_AT.sglName,
                    POST.SEASON_ACTIVITY_QUEST_GRADE.cmdName,
                    {questId = questId},
                    POST.SEASON_ACTIVITY_QUEST_GRADE.sglName,
                    nil,
                    nil,
                    nil
            )

            -- 跳转信息
            local fromToStruct = BattleMediatorsConnectStruct.New(
                    NAME,
                    NAME
            )

            -- 阵容信息
            local  teamData = {}
            for k, v in pairs(json.decode(requestData.cards)) do
                teamData[checkint(k)] = checkint(v)
            end
            -- 选择的主角技信息
            local playerSkillData = {
                0, 0

            }
            for k , v in pairs( json.decode(requestData.skill)  or {}) do
                playerSkillData[checkint(k)] = v
            end
            -- 创建战斗构造器
            local battleConstructor = require('battleEntry.BattleConstructor').new()

            battleConstructor:InitStageDataByNormalEvent(
                    checkint(questId),
                    serverCommand,
                    fromToStruct,
                    teamData,
                    playerSkillData
            )

            battleConstructor:OpenBattle()
            ------------ 初始化战斗构造器 ------------

        end
    end
end
-- 退出保存数据
function SeasonLiveMediator:BackMediatorSaveData()
    if self.preIndex then
        ---@type BattleScriptTeamMediator
        local mediator =  self:GetFacade():RetrieveMediator("BattleScriptTeamMediator")
        if mediator then
            local data =  mediator:ReturnRequestSignalData() -- 获取到返回的数据
            self:SendSignal(POST.SEASON_ACTIVITY_SET_QUEST_CONFIG.cmdName ,
                    { cards = json.encode(data.cards) , skill = json.encode(data.skill) , typeId = self.seasonData[tostring(self.preIndex) ].id,isBattle = 0  } )
        end
        self:GetFacade():UnRegsitMediator("BattleScriptTeamMediator")
    end
    if not self.activityId then
        self.activityId = app.activityMgr:GetActivityIdByType(ACTIVITY_TYPE.SEASONG_LIVE)
    end 
    AppFacade.GetInstance():RetrieveMediator('Router'):Dispatch( {name = "HomeMediator"  }, { name = "ActivityMediator"  , params = { activityId =  self.activityId}  })
end
--[[
   副本刷新操作
--]]
function SeasonLiveMediator:UpdateCell(p_convertview, idx)

    local index = checkint(idx)
    ---@type SeasonLiveCell
    local pcell = p_convertview
    local data = self.seasonData[tostring(index)]
    xTry(function()
        local viewData = pcell.viewData
        viewData.subcontentLayout:setTag(index)
        viewData.clickLayer:setTag(index)
        display.commonLabelParams(viewData.desrLabel , {text = data.descr ,color =  "#926341" , fontSize = 20 } )
        display.commonLabelParams(viewData.titleBtn ,{ text = data.name})
        viewData.clickLayer:setOnClickScriptHandler(handler(self, self.CellButtonClick))
        viewData.chooseDifficultyLayout:setOnClickScriptHandler(handler(self, self.SelectDifficultClick))
        viewData.challengeLayout:setVisible(true)
        local str = _res(string.format('ui/home/activity/seasonlive/season_battle_ico_%s' , tostring(data.iconId) ))
        viewData.scriptTypeImage:setTexture(str)
        local difficultly =  data.currentDifficultly
        local type = data.id
        local questOneData = data.questData[type .. "," ..difficultly] or {}
        local recommendLevel =checkstr(questOneData.recommendLevel)
        display.commonLabelParams(viewData.recommendLevel , {text = string.format(__('推荐等级:%s') , tostring(recommendLevel))   })
        local questId = questOneData.questId
        self:CreateFallForReward( viewData.subcontentLayout , questId )
        local difficultly =  data.currentDifficultly
        display.reloadRichLabel(viewData.difficultyLabel, { c= {
            fontWithColor('14' , {text =  DIFFICULTY_LEVEL_TABEL[checkint(difficultly)] }) ,
            {img =  _res('ui/common/common_bg_tips_horn') , scale = -1 , ap = cc.p(1.2,1.2 ) }

        }})
        local questOneData =seasonQuestData[tostring(questId)]
        local consumeGoodsLose  =  questOneData.consumeGoodsLose
        local data = {}
        if checkint(consumeGoodsLose.goodsId)  > 0 then
            data[#data+1]  = consumeGoodsLose
        end
        if checkint(questOneData.consumeHpLose) > 0 then
            data[#data+1] = { goodsId = HP_ID , goodsNum = questOneData.consumeHpLose    }
        end
        local cData = {}
        for  k ,v in pairs(data) do
            cData[#cData+1] = fontWithColor('3' ,{text = string.format(__('消耗 %s') , tostring(v.goodsNum) )})
            cData[#cData+1] = {img = CommonUtils.GetGoodsIconPathById(v.goodsId) ,scale  = 0.2 }
        end
        display.reloadRichLabel(viewData.costLabel ,{ c = cData})
    end,__G__TRACKBACK__)
end


--[[
    创建获得道具
    parentNode 为添加node的父类
    questId 出入当前关卡的Id
--]]
function SeasonLiveMediator:CreateFallForReward(parentNode, questId)
    local node = parentNode:getChildByTag(BUTTON_CLICK.GOOD_NODE_TAG)
    if node and not  tolua.isnull(node) then
        node:removeFromParent()
    end
    local parentNodeSize  = parentNode:getContentSize()
    local questOneData = self.questData[tostring(questId)] or {}
    local rewards = questOneData.rewards or {}
    local count = table.nums(rewards)
    local goodSize =  cc.size(100,100)
    local rewardsLayout = display.newLayer(parentNodeSize.width/2 ,parentNodeSize.height -190 ,
            { ap = display.CENTER , size = cc.size(goodSize.width * count , goodSize.height)}
    )
    rewardsLayout:setTag(BUTTON_CLICK.GOOD_NODE_TAG)
    parentNode:addChild(rewardsLayout)
    for i =1 , #rewards do
        local data = rewards[i]
        local goodNode = require('common.GoodNode').new({id = data.goodsId, amount = data.num, showAmount = true })
        display.commonUIParams(goodNode, {animate = false, cb = function (sender)
            uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
        end})
        goodNode:setScale(0.8)
        goodNode:setPosition(cc.p(goodSize.width* (i - 0.5 ) , goodSize.height/2 ))
        rewardsLayout:addChild(goodNode,2)
    end
end

-- 选中某一个具体的选项
function SeasonLiveMediator:CellButtonClick(sender)
    local tag =  sender:getTag()
    local data = self.seasonData[tostring(tag) ]

    if data then
        if self.preIndex then
            if  checkint(self.preIndex)  == tag then
                return
            end
            self:SetCellAction({index =checkint(self.preIndex)   , isAction = false})
            self.preIndex = nil
            ---@type BattleScriptTeamMediator
            local mediator = self:GetFacade():RetrieveMediator("BattleScriptTeamMediator")
            if mediator then
                mediator:GetViewComponent():BottomRunAction(false)
                uiMgr:GetCurrentScene():runAction(
                        cc.Sequence:create(    -- 获取队列的动画展示
                                cc.DelayTime:create(0.2) ,
                                cc.CallFunc:create(function ( )
                                    self:GetFacade():UnRegsitMediator("BattleScriptTeamMediator")
                                end)
                        )
                )
            end
            return
        end
        self.preIndex = tag
        local sendData = self:ProcessingSendData(data)
        local battleScriptTeamMediator = require("Game.mediator.BattleScriptTeamMediator")
        local mediator = battleScriptTeamMediator.new(sendData)
        self:GetFacade():RegistMediator(mediator)
        mediator:GetViewComponent():BottomRunAction(true)
        self:SetCellAction({index = tag , isAction = true})
    end

end
--[[
传入参数 {
        isAction = false
        index = 1
    }
--]]
function SeasonLiveMediator:SetCellAction(data)
    local viewData = self.viewComponent.viewData
    local cell = nil
    if not  data.pcell then
        cell =  viewData.gainListView:getNodeAtIndex(data.index -1)
    else
        cell  = data.pcell
    end
    if cell and not  tolua.isnull(cell) then
        cell.viewData.bgImageChosen:setVisible(data.isAction)
        local cellLayout = cell:getChildByName("cellLayout")
        if data.isAction then

            cellLayout:runAction(cc.Sequence:create(
                    cc.ScaleTo:create(0.1, 0.9),
                    cc.ScaleTo:create(0.1, 1.05)
            ) )
        else
            cellLayout:runAction(cc.Sequence:create(
                    cc.ScaleTo:create(0.1, 0.95),
                    cc.ScaleTo:create(0.1, 1)
            ) )
        end

    end

end
--[[
    向BattleScriptTeamMediator 传输数据
--]]
function SeasonLiveMediator:ProcessingSendData(data)

    local teamData = { -- 加工具有的基本卡牌数据格式
        {},
        {},
        {},
        {},
        {},
    }
    local equipedPlayerSkills = { -- 加工具有的基本的技能的数据格式
        ["1"] =  {},
        ["2"] =  {}
    }
    if type ( data.cards) == "string" then
        data.cards = json.decode(data.cards)
    end
    for k , v in pairs ( data.cards or {}) do
        if teamData[checkint(k)] then
            teamData[checkint(k)].id = v
        end
    end
    if type ( data.skill) == "string" then
        data.skill = json.decode(data.skill)
    end
    for k , v in  pairs (data.skill or {}) do
        if equipedPlayerSkills[tostring(k)] then
            equipedPlayerSkills[tostring(k)].skillId = v
        end
    end
    local goodsData = {}
    local questData = self.seasonData[tostring(self.preIndex) ].questData
    local difficultly = self.seasonData[tostring(self.preIndex)].currentDifficultly
    local type = self.seasonData[tostring(self.preIndex)].id
    local questId = questData[type .."," .. difficultly].questId
    local seasonQuestOneData =  seasonQuestData[tostring(questId)]
    if checkint(seasonQuestOneData.consumeHpLose) > 0 then
        goodsData[#goodsData+1] =  {goodsId = HP_ID , num =  checkint(seasonQuestOneData.consumeHpLose) }
    end
    if  checkint(seasonQuestOneData.consumeGoodsLose.goodsNum) > 0 and checkint(seasonQuestOneData.consumeGoodsLose.goodsId) > 0 then
        goodsData[#goodsData+1] =  {goodsId = seasonQuestOneData.consumeGoodsLose.goodsId , num =  checkint(seasonQuestOneData.consumeGoodsLose.goodsNum) }
    end
    local  needData = {
        goodsData = goodsData ,
        teamData = teamData ,
        equipedPlayerSkills = equipedPlayerSkills ,
        callback = handler(self, self.BattleCallBack) ,-- 开启战斗的回调设置
        battleType = BATTLE_SCRIPT_TYPE.MATERIAL_TYPE ,
        scriptType = COST_DATA.COOS_GOODS
    }
    return needData
end
--[[
    战斗的回调
-- ]]
function SeasonLiveMediator:BattleCallBack(data)
    local questData = self.seasonData[tostring(self.preIndex) ].questData
    local difficultly = self.seasonData[tostring(self.preIndex)].currentDifficultly
    local type = self.seasonData[tostring(self.preIndex)].id
    local questId = questData[type .."," .. difficultly].questId
    local seasonQuestOneData =  seasonQuestData[tostring(questId)]
    if seasonQuestOneData then
        if checkint(seasonQuestOneData.consumeHpLose) > 0 then
            local num = CommonUtils.GetCacheProductNum(HP_ID)
            if num < checkint(seasonQuestOneData.consumeHpLose) then
                uiMgr:ShowInformationTips(__('体力不足'))
                return
            end
        end
        if  checkint(seasonQuestOneData.consumeGoodsLose.goodsNum)> 0
                and  checkint(seasonQuestOneData.consumeGoodsLose.goodsId)> 0  then
            if checkint(seasonQuestOneData.consumeGoodsLose.goodsNum) > CommonUtils.GetCacheProductNum(seasonQuestOneData.consumeGoodsLose.goodsId ) then
                if GAME_MODULE_OPEN.NEW_STORE and checkint(seasonQuestOneData.consumeGoodsLose.goodsId) == DIAMOND_ID then
                    app.uiMgr:showDiamonTips()
                else
                    local goodData  = CommonUtils.GetConfig('goods','goods',seasonQuestOneData.consumeGoodsLose.goodsId)
                    local  name =  goodData.name
                    uiMgr:ShowInformationTips(string.format(__('%s不足') , name) )
                end
                return
            end
        end
    else
        uiMgr:ShowInformationTips(__('当前关卡不存在'))
        return
    end
    -- 判断是否需要加载资源
    if 0 < checkint(SUBPACKAGE_LEVEL) and cc.UserDefault:getInstance():getBoolForKey('SubpackageRes_' .. tostring(FTUtils:getAppVersion()), false) == false then
        local gameManager   = self:GetFacade():GetManager('GameManager')
        local playerLevel   = checkint(gameManager:GetUserInfo().level)
        if playerLevel >= checkint(SUBPACKAGE_LEVEL) then
            local uiMgr = self:GetFacade():GetManager("UIManager")
            local scene = uiMgr:GetCurrentScene()
            local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('您已经初步体验了我们的游戏，如需体验更多更优质的游戏内容，还需继续下载完整游戏包～'),
                callback = function ()
                    if cc.UserDefault:getInstance():getBoolForKey('SubpackageRes_' .. tostring(FTUtils:getAppVersion()), false) == false then
                        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'ResourceDownloadMediator', params = {
                            closeFunc = function (  )
                                AppFacade.GetInstance():BackHomeMediator()
                            end
                        }})
                    end
                end})
            CommonTip:setPosition(display.center)
            scene:AddDialog(CommonTip)
        end
        return 
    end
    local mediator = self:GetFacade():RetrieveMediator("BattleScriptTeamMediator")
    if mediator then -- 如果存在就要删除战队编辑界面
        self:GetFacade():UnRegsitMediator("BattleScriptTeamMediator")
    end
    local gameMgr = AppFacade.GetInstance():GetManager('GameManager')

    local isFirstOpen = true
    local operaId = 2
    local key = ""
    if type < 3 then
        key = string.format("%s_IS_FIRST_SEASOING_LIVE_SMALL_MONSTER" , tostring(gameMgr:GetUserInfo().playerId) )
        isFirstOpen = cc.UserDefault:getInstance():getBoolForKey(key, true)
        operaId = 2
    else
        key = string.format("%s_IS_FIRST_SEASOING_LIVE_BIG_MONSTER" , tostring(gameMgr:GetUserInfo().playerId) )
        isFirstOpen = cc.UserDefault:getInstance():getBoolForKey(key, true)
        operaId = 3
    end
    local index = self.preIndex
    if isFirstOpen then
        cc.UserDefault:getInstance():getBoolForKey(key, false)
        cc.UserDefault:getInstance():flush()
        local storyStage = require('Frame.Opera.OperaStage').new({id = checkint(operaId), path = string.format("conf/%s/seasonActivity/springStory.json",i18n.getLang()), guide = true, cb = function(sender)
            cc.UserDefault:getInstance():setBoolForKey(key, false)
            cc.UserDefault:getInstance():flush()

            self:SendSignal(POST.SEASON_ACTIVITY_SET_QUEST_CONFIG.cmdName ,
                            { cards = json.encode(data.cards) , skill = json.encode(data.skill) ,typeId = self.seasonData[tostring(index) ].id  , isBattle = 1 , index = index  } )
        end})
        storyStage:setPosition(display.center)
        sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
    else
        self:SendSignal(POST.SEASON_ACTIVITY_SET_QUEST_CONFIG.cmdName ,
                        { cards = json.encode(data.cards) , skill = json.encode(data.skill) ,typeId = self.seasonData[tostring(index) ].id  , isBattle = 1 , index = index  } )
    end

end

--[[
选择按钮回调事件
-- ]]
function SeasonLiveMediator:SelectDifficultClick(sender)
    local parentNode = sender:getParent() -- 获取中部的Layout
    local childNode = sender:getChildByName("chooseDifficultyBtn")
    local index = parentNode:getTag()
    if self.preIndex ~= index then  --  如果不相同 就直接相当于选择其他页面
        self:CellButtonClick(parentNode)
        childNode:setChecked(false)
        return
    end
    childNode:setChecked(true)
    childNode:setEnabled(false)
    local currentNode = childNode
    local selectLayer =  display.newLayer(display.cx , display.cy , { ap  = display.CENTER ,size = display.size  })
    uiMgr:GetCurrentScene():AddDialog(selectLayer)
    local swallyerLayer = display.newLayer(display.cx , display.cy ,
            { ap  = display.CENTER , size = display.size, color = cc.c4b(0,0,0,0) , enable = true , cb = function ()
                childNode:setChecked(false)
                childNode:setEnabled(true)
                selectLayer:removeFromParent()
            end})
    selectLayer:addChild(swallyerLayer)
    local selectBgImage = display.newImageView(_res('ui/home/materialScript/material_selectlist_bg'))
    local selectBgImageSize = selectBgImage:getContentSize()
    selectBgImage:setPosition(cc.p(selectBgImageSize.width/2 ,selectBgImageSize.height/2))
    -- 选择的Layout
    local selectLayout = display.newLayer(selectBgImageSize.width/2 ,selectBgImageSize.height/2 , {
        ap = display.CENTER_TOP,
        size = selectBgImageSize
    })
    selectLayout:addChild(selectBgImage)
    selectLayer:addChild(selectLayout)

    local  pos  = cc.p(currentNode:getPosition())
    pos = currentNode:getParent():convertToWorldSpace(pos)
    pos = cc.p(pos.x , pos.y - 20)
    selectLayout:setPosition(pos)

    local seasonOneTypeData= self.seasonData[tostring(index)]
    local type = seasonOneTypeData.id
    local cellSize = cc.size(265 , 70)
    local questId = 0
    local questData = {}
    for i =1 ,DIFFICULTY_LEVEL do -- 困难的等级
        local node = display.newLayer(cellSize.width/2 , cellSize.height * (DIFFICULTY_LEVEL -   (i - 0.5 ) )  + 7 ,
                                      {ap = display.CENTER , size = cellSize , enable = true ,color = cc.c4b(0,0,0,0)} )

        selectLayout:addChild(node)
        questData  = seasonOneTypeData.questData[type ..",".. i] or i
        questId = checkint(questData.questId)
        node:setTag(i) --设置关卡的数据索引查询
        if i ~= 4 then -- 添加线条区分
            local image  = display.newImageView(_res('ui/home/materialScript/material_selectlist_line'), cellSize.width/2 , 0 )
            node:addChild(image ,2)
        end
        local cData= {}
        local str =  DIFFICULTY_LEVEL_TABEL[i]
        if checkint(self.seasonData[tostring(index)].currentDifficultly) == i then
            local image  = display.newImageView(_res("ui/home/materialScript/material_selectlist_label_chosen") ,
                    cellSize.width/2, cellSize.height/2)
            node:addChild(image)
        end
        cData = {fontWithColor('14', {color = "#723737", text = str})}
        local richLabel = display.newRichLabel(cellSize.width/2 , cellSize.height/2 , {r = true , c = cData})
        node:addChild(richLabel)
        node:setOnClickScriptHandler(function (sender)
            local difficultly = sender:getTag() -- 获取到当前的tag 类型
            local index = parentNode:getTag()
            local seasonOneTypeData= self.seasonData[tostring(index)]
            local type = seasonOneTypeData.id
            local questData = seasonOneTypeData.questData
            local questId = questData[type .. "," ..difficultly].questId
            local recommendLevel = questData[type .. "," ..difficultly].recommendLevel
            local questOneData = self.questData[tostring(questId)]
            if not  questOneData then -- 如果该关卡不存在就直接返回
                return
            else
                -- 添加类型
                self:CreateFallForReward(parentNode , questId)
                local nodeOne = currentNode:getParent()
                local difficultyLabel = nodeOne:getChildByName("difficultyLabel")
                if difficultyLabel and ( not tolua.isnull(difficultyLabel) ) then
                    display.reloadRichLabel(difficultyLabel , {
                        c = {
                            fontWithColor('14', { text  = DIFFICULTY_LEVEL_TABEL[checkint(questOneData.difficulty) ] } ) ,
                            { img = _res('ui/common/common_bg_tips_horn') ,scale = -1 , ap = cc.p(1.2,1.2 ) }
                        }
                    })
                end
                local subcontentLayout = nodeOne:getParent()
                local recommendLevelLabel  = subcontentLayout:getChildByName("recommendLevel")
                if recommendLevelLabel and ( not tolua.isnull(recommendLevelLabel) ) then
                    display.commonLabelParams(recommendLevelLabel , { text = string.format(__('推荐等级:%d') , checkint(recommendLevel))})
                end
                seasonOneTypeData.currentDifficultly = difficultly
                local consumeGoodsLose  =  questOneData.consumeGoodsLose
                local data = {}
                if checkint(consumeGoodsLose.goodsId)  > 0 then
                    data[#data+1]  = consumeGoodsLose
                end
                if checkint(questOneData.consumeHpLose) > 0 then
                    data[#data+1] = { goodsId = HP_ID , goodsNum = questOneData.consumeHpLose    }
                end
                local cData = {}
                for  k ,v in pairs(data) do
                    cData[#cData+1] = fontWithColor('3' ,{text = string.format(__('消耗 %s') , tostring(v.goodsNum) )})
                    cData[#cData+1] = {img = CommonUtils.GetGoodsIconPathById(v.goodsId) ,scale  = 0.2 }
                end
                local cellLayout = subcontentLayout:getParent()
                local challengeLayout =cellLayout:getChildByName('challengeLayout')
                local costLabel = challengeLayout:getChildByName("costLabel")
                display.reloadRichLabel(costLabel ,{ c = cData})
                -- 删除当前的界面
                selectLayer:removeFromParent()
                currentNode:setChecked(false)
                currentNode:setEnabled(true)
            end
        end)
    end

end

--[[
    进入的时候材料副本的请求
--]]
function SeasonLiveMediator:EnterLayer()
    self:SendSignal(POST.SEASON_ACTIVITY_GET_QUEST_CONFIG.cmdName, {})
end

function SeasonLiveMediator:OnRegist()
    regPost(POST.SEASON_ACTIVITY_GET_QUEST_CONFIG)
    regPost(POST.SEASON_ACTIVITY_SET_QUEST_CONFIG)
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    self:EnterLayer()
end

function SeasonLiveMediator:OnUnRegist()
    unregPost(POST.SEASON_ACTIVITY_GET_QUEST_CONFIG)
    unregPost(POST.SEASON_ACTIVITY_SET_QUEST_CONFIG)
    if self.viewComponent and not  tolua.isnull(self.viewComponent) then
        self.viewComponent:runAction(cc.RemoveSelf:create())
    end
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
end

return SeasonLiveMediator



