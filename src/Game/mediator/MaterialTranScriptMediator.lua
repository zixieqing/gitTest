
---
--- Created by xingweihao.
--- DateTime: 27/10/2017 9:53 AM
---
local Mediator = mvc.Mediator
---@class MaterialTranScriptMediator :Mediator
local MaterialTranScriptMediator = class("MaterialTranScriptMediator", Mediator)
local NAME = "MaterialTranScriptMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local CELL_STATUS = {
    LOCK_STATUS = 1 , -- 未解锁
    UNLOCK_UNUSE = 2 , -- 已解锁 不可用
    UNLOCK_UNSELECT = 3 , -- 解锁未选中
    UNLOCK_SELECT = 4 , -- 选中状态

}
local DIFFICULTY_LEVEL = 4
local DIFFICULTY_LEVEL_TABEL = {
    __('简单'),
    __('中等'),
    __('困难'),
    __('极难')
}
local MATERIAL_SPRIT = {
    OPEN_HAVE_TIMES = 1 ,
    OPEN_NO_TIMES  =2 ,
    NOT_OPEN_UNLCOK = 3 ,
    LOCK = 4

}
local BUTTON_CLICK  = {
    GOOD_NODE_TAG = 10001 , -- 获取GoodNode 的标志
    CLOSE_TAG = 10002 , -- 关闭的tag 值


}
function MaterialTranScriptMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.preIndex = nil
    self.materialData = {} -- 材料副本的数据
    self.questData  = CommonUtils.GetConfigAllMess('quest' , 'materialQuest')
    self.countNum =  0
    self.outerParams = param
end
function MaterialTranScriptMediator:InterestSignals()
    local signals = {
        POST.MATERIAL_QUEST_HOME.sglName ,
        POST.MATERIAL_QUEST_SET_QUEST_CONFIG.sglName
    }
    return signals
end
--[[
    初次合并数据
--]]
function MaterialTranScriptMediator:FirstMerageData()
    local questTypeData = clone( CommonUtils.GetConfigAllMess('questType' , 'materialQuest'))
    local questData  = CommonUtils.GetConfigAllMess('quest' , 'materialQuest')
    for k ,v in pairs(questTypeData) do
        v.questData = {} --  qusetData 用于手机关卡数据  "type,difficultly" --拼接方式为材料副本类型和材料副本难度
    end
    local level = gameMgr:GetUserInfo().level
    for k, v in pairs(questData) do
        local data = {}
        data.questId = v.id -- 记录关卡的id
        data.recommendLevel = level -  v.recommendLevel -- 计算推荐等级 等级差距越小越值得推荐 ， 前提必须差值 大于零
        data.unlockLevel = v.unlockLevel  -- 记录解锁等级
        data.difficulty = v.difficulty
        if  not  questTypeData[tostring(v.type)] then
        else
            questTypeData[tostring(v.type)].questData[v.type .. "," .. v.difficulty] = data
        end

    end
    for k , v in pairs ( questTypeData) do
        local distanceLevel = 3000 -- 记录差距的level  默认为最简单的
        local  currentDifficultly = 1 -- 当前的默认难度
        for kk ,vv in pairs(v.questData) do
            if vv.recommendLevel <   distanceLevel and vv.recommendLevel >=0  then
                currentDifficultly =checkint(vv.difficulty)
                distanceLevel = checkint(vv.recommendLevel)
            end
        end
        v.currentDifficultly = currentDifficultly  --用于几录当前最匹配的难度
        v.recommendDifficultly = currentDifficultly  --用于几录当前最匹配的难度
    end

    for k ,v in pairs(questTypeData) do
        if checkint(v.unlockLevel) <= gameMgr:GetUserInfo().level then
            v.sortIndex = MATERIAL_SPRIT.OPEN_HAVE_TIMES -- 已经解锁的的排列在第一位
        else
            v.sortIndex = MATERIAL_SPRIT.LOCK  -- 没有解锁的为第三位
        end
    end
    return questTypeData
end
--[[
    请求回来后 重新合并一次 本次主要用于排序和显示的使用
--]]
function MaterialTranScriptMediator:SecondMargeData(data)
    for k ,v in pairs(data.questInfo or {}) do

        if checkint(v.attendLeftTimes) > 0  and checkint(v.isOpen)  == 1  then

        else
            if  self.materialData[k] then
                if self.materialData[k].sortIndex == MATERIAL_SPRIT.OPEN_HAVE_TIMES then -- 次数没有但是已经解锁， 要排列在解锁的前面
                    if  checkint(v.isOpen)  == 1  then
                        self.materialData[k].sortIndex = MATERIAL_SPRIT.OPEN_NO_TIMES
                    else
                        self.materialData[k].sortIndex = MATERIAL_SPRIT.NOT_OPEN_UNLCOK
                    end
                end
            end
        end
        -- 合并数据
        if self.materialData[ k] then -- 判断该类型是否存在 如果不存在的话就不进行合并
            if checkint(v.lastDifficulty) > 0 then
                self.materialData[k ].currentDifficultly = checkint(v.lastDifficulty)
            end
            table.merge(self.materialData[k] , v)
        end
    end
end
--[[
    排列顺序 顺序 按照
    sortIndex 为
    1. 先解锁  挑战次数大于零 优先级第一位 相同按照等级从大到小
    2. 先解锁  挑战次数小于零 优先级第二位 相同按照等级从大到小
    3. 未解锁  最后一位 相同按照等级从小到大
--]]
function MaterialTranScriptMediator:SortData()
    local data = {}
    for k , v in pairs(self.materialData) do
        data[#data+1] = v
    end
    local count =  table.nums(data)
    local i =1
    while(i <= count )  do
        local j =1
        while( j <= count - i) do
            if data[j].sortIndex == data[j+1].sortIndex then
                if  data[j].sortIndex == MATERIAL_SPRIT.OPEN_HAVE_TIMES then
                    if data[j].unlockLevel <= data[j+1].unlockLevel then
                        data[j], data[j+1] = data[j+1] ,data[j]
                    end
                elseif  data[j].sortIndex == MATERIAL_SPRIT.OPEN_NO_TIMES then
                    if data[j].unlockLevel <= data[j+1].unlockLevel then
                        data[j], data[j+1] = data[j+1] ,data[j]
                    end
                elseif data[j].sortIndex == MATERIAL_SPRIT.NOT_OPEN_UNLCOK then
                    if data[j].unlockLevel >= data[j+1].unlockLevel then
                        data[j], data[j+1] = data[j+1] ,data[j]
                    end
                elseif data[j].sortIndex == MATERIAL_SPRIT.LOCK then
                    if data[j].unlockLevel >= data[j+1].unlockLevel then
                        data[j], data[j+1] = data[j+1] ,data[j]
                    end
                end
            else
                if data[j].sortIndex  >   data[j+1].sortIndex then
                    data[j], data[j+1] = data[j+1] ,data[j]
                end
            end
            j = j +1
        end
        i = i +1
    end
    self.materialData = data
end
function MaterialTranScriptMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type MaterialTranScriptView
    --获取排列材料本的拍了顺序

    self.materialData = self:FirstMerageData()
    self.viewComponent = require('Game.views.MaterialTranScriptView').new()
    self.viewComponent:setPosition(display.center)
    self.viewComponent.viewData.navBack:setOnClickScriptHandler(handler(self, self.BackMediatorSaveData))
    uiMgr:SwitchToScene( self.viewComponent)
end

function MaterialTranScriptMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.MATERIAL_QUEST_HOME.sglName then
        local viewData = self.viewComponent.viewData
        --self.materialData = data
        -- 第二次组合数据
        self:SecondMargeData(data)
        -- 排列数据
        self:SortData()
        self.countNum = table.nums(self.materialData)
        viewData.tableView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSource))
        viewData.tableView:setCountOfCell(table.nums(self.materialData))
        viewData.tableView:reloadData()
    elseif name == POST.MATERIAL_QUEST_SET_QUEST_CONFIG.sglName then
        local requestData  = data.requestData
        if checkint(requestData.isBattle)  == 1 then -- 如果为真的话就执行战斗操作
            local materialData = self.materialData and checktable(self.materialData[self.preIndex]) or {}
            local questData = checktable(materialData.questData)
            local difficultly = checkint(materialData.currentDifficultly)
            local type = checkint(materialData.id)
            local questId = checkint(checktable(questData[type .."," .. difficultly]).questId)
            if questId == 0 then
                app.uiMgr:ShowInformationTips(__('当前关卡不存在'))
                return
            end
            local dotLogEventStr = string.fmt("47-M_num_-01" , { _num_ = type})
            AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = dotLogEventStr})
            local dotLogEventStr = string.fmt("47-M_num_-02" , { _num_ = type})
            AppFacade.GetInstance():DispatchObservers("DOT_SET_LOG_EVENT" , {eventId = dotLogEventStr})
            ------------ 初始化战斗构造器 ------------
            -- 网络命令
            local serverCommand = BattleNetworkCommandStruct.New(
                POST.MATERIAL_QUEST_AT.cmdName,
                {questId = questId},
                POST.MATERIAL_QUEST_AT.sglName,
                POST.MATERIAL_QUEST_GRADE.cmdName,
                {questId = questId},
                POST.MATERIAL_QUEST_GRADE.sglName,
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
function MaterialTranScriptMediator:BackMediatorSaveData()
    if self.preIndex then
        ---@type BattleScriptTeamMediator
        local mediator =  self:GetFacade():RetrieveMediator("BattleScriptTeamMediator")
        if mediator then
            local data =  mediator:ReturnRequestSignalData() -- 获取到返回的数据
            self:SendSignal(POST.MATERIAL_QUEST_SET_QUEST_CONFIG.cmdName ,
            { cards = json.encode(data.cards) , skill = json.encode(data.skill) , typeId = self.materialData[self.preIndex].id,isBattle = 0  } )
            self:GetFacade():UnRegsitMediator("BattleScriptTeamMediator")
        end
    end

    -- 返回上一层
    app.router:Dispatch({name = NAME}, {name = self:GetBackToMediator()})

end
--[[
   副本刷新操作
--]]
function MaterialTranScriptMediator:OnDataSource(p_convertview, idx)
    local index = idx +1
    local pcell = p_convertview
    local data = self.materialData[index]
    if index > 0 and  index <=  self.countNum then
        if not  pcell then
            ---@type MaterialTranScriptCell
            pcell = require("Game.views.MaterialTranScriptCell").new()
        end
        xTry(function()
            local status = CELL_STATUS.UNLOCK_UNSELECT
            local viewData = pcell.viewData
            viewData.subcontentLayout:setTag(index)
            viewData.clickLayer:setTag(index)
            if self.preIndex then
                if  index == self.preIndex then
                    status = (data.sortIndex == MATERIAL_SPRIT.OPEN_HAVE_TIMES or data.sortIndex ==MATERIAL_SPRIT.OPEN_NO_TIMES  )  and   CELL_STATUS.UNLOCK_SELECT
                    viewData.cellLayout:setScale(1.05)
                    viewData.bgImageChosen:setVisible(true)
                end
            end
            if index ~= self.preIndex then  -- 关于没有选中状态的判断
                if checkint(data.isOpen)  ==1  then
                    if checkint(data.unlockLevel)  <=  gameMgr:GetUserInfo().level then
                        status = CELL_STATUS.UNLOCK_UNSELECT
                    else
                        status = CELL_STATUS.LOCK_STATUS
                    end
                else
                    if checkint(data.unlockLevel)  <=  gameMgr:GetUserInfo().level then
                        status = CELL_STATUS.UNLOCK_UNUSE
                    else
                        status = CELL_STATUS.LOCK_STATUS
                    end
                end

            end
            pcell:UpdateCellStatus(status)
            -- 更新cell 的逻辑

            display.commonLabelParams(viewData.materialScriptLabel ,{ text = data.name , reqW = 250 })
            display.commonLabelParams(viewData.introduceLabel ,{ text = data.descr , w = 350   , hAlign = display.TAC , reqW = 300   })
            viewData.clickLayer:setOnClickScriptHandler(handler(self, self.CellButtonClick))
            viewData.chooseDifficultyLayout:setOnClickScriptHandler(handler(self, self.SelectDifficultClick))
            if data.sortIndex == MATERIAL_SPRIT.LOCK then -- 如果没有解锁就是另外一种方式
                viewData.challengeLayout:setVisible(true)
                display.reloadRichLabel(viewData.leftTime, {  c = {
                    { img =_res("ui/common/common_ico_lock.png") ,ap = cc.p(0.5,0.15) } ,
                    fontWithColor('6' , { color = '#feedd8' ,fontSize = 22 ,  text = string.format( __('  主角等级%s级解锁') , tostring(data.unlockLevel) ) })
                }})
                viewData.leftTime:setPosition(cc.p(viewData.card_releasetTimeSize.width/2 , viewData.card_releasetTimeSize.height/2 +10  ))
            else
                viewData.challengeLayout:setVisible(true)
                if  data.sortIndex == MATERIAL_SPRIT.OPEN_HAVE_TIMES or data.sortIndex == MATERIAL_SPRIT.OPEN_NO_TIMES then
                    display.reloadRichLabel(viewData.leftTime, {   po = cc.p(viewData.card_releasetTimeSize.width/2 , viewData.card_releasetTimeSize.height/2 ),
                                                                   c = {
                                                                       fontWithColor('6' ,{ color = '#feedd8', text = string.format(__('剩余次数: %s/%s') , tostring(checkint(data.attendLeftTimes))   , tostring(checkint(data.attendMaxTimes) ))}) }})
                    viewData.leftTime:setPosition(cc.p(viewData.card_releasetTimeSize.width/2 , viewData.card_releasetTimeSize.height/2   ))
                else
                    viewData.challengeLayout:setVisible(false)
                end
            end
            local str = _res(string.format('ui/home/materialScript/material_card_ico_%s' ,data.id))
            local fileUtils = cc.FileUtils:getInstance()
            local isFileExist =  fileUtils:isFileExist(str)
            if not  isFileExist then
                str = _res('ui/home/materialScript/material_card_ico_1')
            end
            viewData.materialCard:setTexture(str)
            local difficultly =  data.currentDifficultly
            local type = data.id
            local questId = data.questData[type .. "," ..difficultly].questId
            self:CreateFallForReward( viewData.subcontentLayout , questId )
            if difficultly  == data.recommendDifficultly  then
                display.reloadRichLabel(viewData.difficultyLabel, { c= {
                    fontWithColor('14' , {text = __('(推荐)   ')  ..  DIFFICULTY_LEVEL_TABEL[checkint(difficultly)] }) ,
                    {img =  _res('ui/common/common_bg_tips_horn') , scale = -1 , ap = cc.p(1.2,1.2 ) }

                }})
            else
                display.reloadRichLabel(viewData.difficultyLabel, { c= {
                    fontWithColor('14' , {text =  DIFFICULTY_LEVEL_TABEL[checkint(difficultly)] }) ,
                    {img =  _res('ui/common/common_bg_tips_horn') , scale = -1 , ap = cc.p(1.2,1.2 ) }

                }})
            end
            display.commonLabelParams(viewData.openTimeLabel , {color = "ffffff", text  = data.OpenDescr or "" , reqW = 330   })
        end,__G__TRACKBACK__)
        return pcell
    end

end


--[[
    创建获得道具
    parentNode 为添加node的父类
    questId 出入当前关卡的Id
--]]
function MaterialTranScriptMediator:CreateFallForReward(parentNode, questId)
    local node = parentNode:getChildByTag(BUTTON_CLICK.GOOD_NODE_TAG)
    if node and tolua.isnull(node) then
        node:removeFromParent()
    end
    local parentNodeSize  = parentNode:getContentSize()
    local questOneData = self.questData[tostring(questId)] or {}
    local rewards = questOneData.rewards or {}
    local count = table.nums(rewards)
    local goodSize =  cc.size(100,100)
    local rewardsLayout = display.newLayer(parentNodeSize.width/2 ,parentNodeSize.height -200 ,
        { ap = display.CENTER , size = cc.size(goodSize.width * count , goodSize.height)}
    )
    rewardsLayout:setTag(BUTTON_CLICK.GOOD_NODE_TAG)
    parentNode:addChild(rewardsLayout)
    for i =1 , #rewards do
        local data = rewards[i]
        local goodNode = require('common.GoodNode').new({id = data.goodsId, amount = data.num, showAmount = true })
        display.commonUIParams(goodNode, {animate = false, cb = function (sender)
            PlayAudioByClickNormal()
            uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
        end})
        goodNode:setScale(0.7)
        goodNode:setPosition(cc.p(goodSize.width* (i - 0.5 ) , goodSize.height/2 ))
        rewardsLayout:addChild(goodNode,2)
    end
end

-- 选中某一个具体的选项
function MaterialTranScriptMediator:CellButtonClick(sender)
    local tag =  sender:getTag()
    local data = self.materialData[tag]
    PlayAudioByClickNormal()
    if data then
        if self.preIndex then
            if self.preIndex == tag then
                return
            end
            self:SetCellAction({index = self.preIndex , isAction = false})
            self.preIndex = nil
            ---@type BattleScriptTeamMediator
            local mediator = self:GetFacade():RetrieveMediator("BattleScriptTeamMediator")
            if mediator then
                mediator:GetViewComponent():BottomRunAction(false)
                -- uiMgr:GetCurrentScene():runAction(
                --     cc.Sequence:create(    -- 获取队列的动画展示
                --         cc.DelayTime:create(0.2) ,  -- 做动画过程中快速点击会有bug，所以关掉动画直接注销
                --         cc.CallFunc:create(function ( )
                            self:GetFacade():UnRegsitMediator("BattleScriptTeamMediator")
                --         end)
                --     )
                -- )
            end
            return
        end
        if checkint(self.materialData[tag].unlockLevel) > gameMgr:GetUserInfo().level  then
            uiMgr:ShowInformationTips(__('该副本尚未解锁'))
            return
        end
        if checkint(self.materialData[tag].isOpen) == 0 then
            uiMgr:ShowInformationTips(__('不在副本开放时间'))
            return
        end
        if checkint(self.materialData[tag].attendLeftTimes) <= 0 then
            uiMgr:ShowInformationTips(__('挑战次数已经用完'))
            return
        end
        local sendData = self:ProcessingSendData(data)
        local battleScriptTeamMediator = require("Game.mediator.BattleScriptTeamMediator")
        local mediator = battleScriptTeamMediator.new(sendData)
        self:GetFacade():RegistMediator(mediator)
        mediator:GetViewComponent():BottomRunAction(true)
        self:SetCellAction({index = tag , isAction = true})
        self.preIndex = tag
    end
    
end
--[[
传入参数 {
        isAction = false
        index = 1
    }
--]]
function MaterialTranScriptMediator:SetCellAction(data)
    local viewData = self.viewComponent.viewData
    local cell = nil
    if not  data.pcell then
        cell =  viewData.tableView:cellAtIndex(data.index -1)
    else
        cell  = data.pcell
    end
    if cell and not  tolua.isnull(cell) then
        cell.viewData.bgImageChosen:setVisible(data.isAction)
        local cellLayout = cell:getChildByName("cellLayout")
        if data.isAction then
            cell:UpdateCellStatus(CELL_STATUS.UNLOCK_SELECT)
            cellLayout:runAction(cc.Sequence:create(
                cc.ScaleTo:create(0.1, 0.9),
                cc.ScaleTo:create(0.1, 1.05)
            ) )
        else
            cellLayout:runAction(cc.Sequence:create(
                cc.ScaleTo:create(0.1, 0.95),
                cc.ScaleTo:create(0.1, 1)
            ) )
            cell:UpdateCellStatus(CELL_STATUS.UNLOCK_UNSELECT)
        end

    end

end
--[[
    向BattleScriptTeamMediator 传输数据
--]]
function MaterialTranScriptMediator:ProcessingSendData(data)

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
    local  needData = {
        teamData = teamData ,
        equipedPlayerSkills = equipedPlayerSkills ,
        attendLeftTimes = data.attendLeftTimes ,
        attendMaxTimes = data.attendMaxTimes ,
        callback = handler(self, self.BattleCallBack) ,-- 开启战斗的回调设置
        battleType = BATTLE_SCRIPT_TYPE.MATERIAL_TYPE
    }
    return needData
end
--[[
    战斗的回调
-- ]]
function MaterialTranScriptMediator:BattleCallBack(data)
    local mediator = self:GetFacade():RetrieveMediator("BattleScriptTeamMediator")
    if mediator then -- 如果存在就要删除战队编辑界面
        self:GetFacade():UnRegsitMediator("BattleScriptTeamMediator")
    end
    self:SendSignal(POST.MATERIAL_QUEST_SET_QUEST_CONFIG.cmdName ,
            { cards = json.encode(data.cards) , skill = json.encode(data.skill) ,typeId = self.materialData[self.preIndex].id  , isBattle = 1  } )
end

--[[
选择按钮回调事件
-- ]]
function MaterialTranScriptMediator:SelectDifficultClick(sender)
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
    PlayAudioByClickNormal()
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

    local materialOneTypeData= self.materialData[index]
    local type = materialOneTypeData.id
    local cellSize = cc.size(265 , 70)
    local questId = 0
    local questData = {}
    for i =1 ,DIFFICULTY_LEVEL do -- 困难的等级
        local node = display.newLayer(cellSize.width/2 , cellSize.height * (DIFFICULTY_LEVEL -   (i - 0.5 ) )  + 7 , {ap = display.CENTER , size = cellSize , enable = true ,color = cc.c4b(0,0,0,0)} )
        selectLayout:addChild(node)
        questData  = materialOneTypeData.questData[type ..",".. i]
        if questData and  table.nums(questData) > 0   then
            questId = checkint(questData.questId)
            node:setTag(i) --设置关卡的数据索引查询
            if i ~= 4 then -- 添加线条区分
                local image  = display.newImageView(_res('ui/home/materialScript/material_selectlist_line'), cellSize.width/2 , 0 )
                node:addChild(image ,2)
            end
            local cData= {}
            if  checkint(questData.unlockLevel)  <= gameMgr:GetUserInfo().level  then -- 两种方式的渲染节点不同

                local str =  DIFFICULTY_LEVEL_TABEL[i]
                if checkint(self.materialData[index].currentDifficultly) == i then
                    local image  = display.newImageView(_res("ui/home/materialScript/material_selectlist_label_chosen") ,
                            cellSize.width/2, cellSize.height/2)
                    node:addChild(image)
                end
                if i == self.materialData[index].recommendDifficultly then
                    str =  __('(推荐)   ')  ..   DIFFICULTY_LEVEL_TABEL[i]
                else
                    str =   DIFFICULTY_LEVEL_TABEL[i]
                end
                cData = {fontWithColor('14', {color = "#723737", text = str})}
            else
                local lockImage  = display.newImageView(_res('ui/common/common_ico_lock') , 35 , cellSize.height/2 )
                node:addChild(lockImage)
                local str =  DIFFICULTY_LEVEL_TABEL[i]
                cData = {
                    fontWithColor('14', {color = "#7c7c7c", text = str})
                }
            end
            local richLabel = display.newRichLabel(cellSize.width/2 , cellSize.height/2 , {r = true , c = cData})
            node:addChild(richLabel)
            node:setOnClickScriptHandler(function (sender)
                PlayAudioByClickNormal()
                local difficultly = sender:getTag() -- 获取到当前的tag 类型
                local index = parentNode:getTag()
                local materialOneTypeData= self.materialData[index]
                local type = materialOneTypeData.id
                local questData = materialOneTypeData.questData
                local questId = questData[type .. "," ..difficultly].questId
                local unlockLevel = questData[type .. "," ..difficultly].unlockLevel
                if unlockLevel > gameMgr:GetUserInfo().level then
                    uiMgr:ShowInformationTips(string.format('%s%s%d%s' ,materialOneTypeData.name, DIFFICULTY_LEVEL_TABEL[i], unlockLevel,__('级解锁') ))
                    selectLayer:removeFromParent()
                    currentNode:setChecked(false)
                    currentNode:setEnabled(true)
                    return
                end
                local questOneData = self.questData[tostring(questId)]
                if not  questOneData then -- 如果该关卡不存在就直接返回
                    return
                else
                    -- 添加类型
                    self:CreateFallForReward(parentNode , questId)
                    local nodeOne = currentNode:getParent()
                    local difficultyLabel = nodeOne:getChildByName("difficultyLabel")
                    if difficultyLabel and ( not tolua.isnull(difficultyLabel) ) then
                        if materialOneTypeData.recommendDifficultly  ==  difficultly then

                            display.reloadRichLabel(difficultyLabel , {
                                c = {
                                    fontWithColor('14', { text  =  __('(推荐)   ') ..  DIFFICULTY_LEVEL_TABEL[checkint(questOneData.difficulty) ] } ) ,
                                    { img = _res('ui/common/common_bg_tips_horn') ,scale = -1 , ap = cc.p(1.2,1.2 ) }
                                }
                            })
                        else
                            display.reloadRichLabel(difficultyLabel , {
                                c = {
                                    fontWithColor('14', { text  = DIFFICULTY_LEVEL_TABEL[checkint(questOneData.difficulty) ] } ) ,
                                    { img = _res('ui/common/common_bg_tips_horn') ,scale = -1 , ap = cc.p(1.2,1.2 ) }
                                }
                            })

                        end
                    end

                    --local recommendLevel =  parentNode:getChildByName("recommendLevel")
                    --if recommendLevel and ( not tolua.isnull(recommendLevel) ) then
                    --    recommendLevel:setString(string.format(__('推荐等级: %s' ) ,  questOneData.recommendLevel))
                    --end
                    materialOneTypeData.currentDifficultly = difficultly
                    -- 删除当前的界面
                    selectLayer:removeFromParent()
                    currentNode:setChecked(false)
                    currentNode:setEnabled(true)
                end
            end)
        end
    end

end

--[[
    进入的时候材料副本的请求
--]]
function MaterialTranScriptMediator:EnterLayer()
    self:SendSignal(POST.MATERIAL_QUEST_HOME.cmdName, {})
end

function MaterialTranScriptMediator:OnRegist()
    regPost(POST.MATERIAL_QUEST_HOME)
    regPost(POST.MATERIAL_QUEST_SET_QUEST_CONFIG)
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    self:EnterLayer()
end

function MaterialTranScriptMediator:OnUnRegist()

    unregPost(POST.MATERIAL_QUEST_HOME)
    unregPost(POST.MATERIAL_QUEST_SET_QUEST_CONFIG)
    if self.viewComponent and not  tolua.isnull(self.viewComponent) then
        self.viewComponent:runAction(cc.RemoveSelf:create())
    end
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")

end

--[[
获取返回的mediator信息
@return name string 返回的mediator名字
--]]
function MaterialTranScriptMediator:GetBackToMediator()
    local name = 'HomeMediator'
    if nil ~= self.outerParams and nil ~= self.outerParams.backMediatorName then
		name = self.outerParams.backMediatorName
	end
	return name
end

return MaterialTranScriptMediator



