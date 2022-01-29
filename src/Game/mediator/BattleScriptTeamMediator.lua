
---
--- Created by xingweihao.
--- DateTime: 27/10/2017 9:53 AM
---
local Mediator = mvc.Mediator
---@class BattleScriptTeamMediator :Mediator
local BattleScriptTeamMediator = class("BattleScriptTeamMediator", Mediator)
local NAME = "BattleScriptTeamMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local BATTLE_MAX_NUMS=  5 -- 上阵的队伍最大数量
local COST_DATA = {
    COST_TIMES =1 ,  -- 次数消耗
    COOS_GOODS =2 ,  -- 道具消耗
    NO_CONSUME =3 ,  -- 没有消耗
}
--[[ 传入参数的要求

    副本选卡通用编的界面的修改
    @param = {
        attendLeftTimes  副本剩余可挑战次数
        attendMaxTimes int 副本最大挑战次数
        goodsData = {
            {
                goodsId  =  111 ,
                num =111
             },
             {
                goodsId  =  111 ,
                num =111
             }
        }
        backCloseShow = true 
        battleTitle  '战斗标题'
        battleText "战斗的文本"
        isDisableHomeTopSignal  bool  是否禁止隐藏HomeTopLayer 信号
        battleFontSize "文字的大小"
        pattern  common.CommonBattleButton 的哪一种样式
        equipedPlayerSkills 当前副本所选的技能列表
        teamData   { id = "23213"  }
        callback   战斗的回调事件
        battleType  -- 副本战斗类型
        scriptType  = 2 --  1 ,为次数消耗 2 . 道具消耗
        limitCardsCareers table 限制卡牌职业
        limitCardsQualities table 限制品质
        allCards 所有卡牌
    }
-- ]]

local BUTTON_CLICK = {
    SKILL_ONE  = 11001, -- 选择的第一个更换按钮
    SKILL_TWO  = 11002, -- 选择的第二个更换按钮
    BATTLE_BTN = 11003, -- 战斗按钮
    ADD_TAG    = 10044, -- 添加的按钮的值 这里仅做标记
    CLOSE_TAG  = 10005, -- 关闭的tag
}


function BattleScriptTeamMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)
    param = param or {}
    self.teamData = param.teamData or {}  -- 卡牌的数据
    self.chooseTeamLayer = nil  -- 选卡界面
    self.equipedPlayerSkills = param.equipedPlayerSkills or {}
    self.backCloseShow = param.backCloseShow
    self.limitCardsCareers = param.limitCardsCareers or {}
    self.limitCardsQualities = param.limitCardsQualities or {}
    self.allCards = param.allCards or {}
    self.isDisableHomeTopSignal = param.isDisableHomeTopSignal
    self.callback = param.callback
    self.data = param
    self.allSkills = self:convertPlayerSkillData(gameMgr:GetUserInfo().allSkill)
    self.battleType = param.battleType
    -- 判断战斗消耗的的类型
    self.scriptType = checkint(param.scriptType) > 0 and checkint(param.scriptType)  or 1
    self:InitData()
end
--[[
    初始化数据
--]]
function BattleScriptTeamMediator:InitData()
    for i= 1 , BATTLE_MAX_NUMS do
        if not  self.teamData[i] then
            self.teamData[i] = {}
        end
    end
    for i =1 , 2 do
        if not  self.equipedPlayerSkills[i] then
            self.equipedPlayerSkills[i] = {}
        end
    end
end
function BattleScriptTeamMediator:InterestSignals()
    local signals = {
        "CHANGE_PLAYER_SKILL" , -- 改变队伍的技能
        "TEAM_CHANGE_NOTICE" ,  -- 改变队伍队伍的通知

    }
    return signals
end
function BattleScriptTeamMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == "CHANGE_PLAYER_SKILL" then
        local skillData = table.split(data.requestData.skills , ",")
        if data.responseCallback then
            data.responseCallback({
                skill = skillData
            })
        end
        for k ,v in pairs(skillData) do
            if checkint( v.skillId)  > 0 then
                if  self.equipedPlayerSkills[k] then
                    self.equipedPlayerSkills[k].skillId  =  v
                end
            else
                if  self.equipedPlayerSkills[k] then
                    self.equipedPlayerSkills[k].skillId  =  nil
                end
            end
        end
        self:UpdateSkillView(self.equipedPlayerSkills)
    elseif name == "TEAM_CHANGE_NOTICE" then
        for k , v in pairs(data.teamData or {}) do
            if v.id then
                if checkint(self.teamData[k]) then
                    self.teamData[k].id = v.id
                end
            end
        end
        if self.chooseTeamLayer and not  tolua.isnull(self.chooseTeamLayer) then
            -- 删除选卡界面
            self.chooseTeamLayer:runAction( cc.RemoveSelf:create())
        end
        self:UpdateTeamView(self.teamData)
    end
end
function BattleScriptTeamMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type BattleScriptTeamView
    local data = {}
    data.callback = handler(self, self.BattleCallBack)
    data.battleText = self.data.battleText
    data.battleFontSize = self.data.battleFontSize
    data.pattern  = self.data.pattern
    self.viewComponent = require('Game.views.BattleScriptTeamView').new(data)
    self.viewComponent:setPosition(display.center)
    self:SetViewComponent(self.viewComponent)
    uiMgr:GetCurrentScene():AddDialog(self.viewComponent )
    local viewData = self.viewComponent.viewData
    local allCardLayout = viewData.allCardLayout
    for i =1 ,BATTLE_MAX_NUMS do
        local node = allCardLayout:getChildByTag(i)
        if node and  (not tolua.isnull(node) )  then
            node:setOnClickScriptHandler(handler(self, self.AddCardClick))
        end
    end
    viewData.skillTwoLayout:setOnClickScriptHandler(handler(self,self.ButtonAction))
    viewData.skillOneLayout:setOnClickScriptHandler(handler(self, self.ButtonAction))

    self:UpdateView()
end
--[[
    更新界面的信息
--]]
function BattleScriptTeamMediator:UpdateView()
    local viewData = self.viewComponent.viewData
    if self.scriptType == COST_DATA.COST_TIMES then
        display.reloadRichLabel(viewData.battleLabel , {

            c= {
                { fontSize= 22 , color = "#ffffff"  ,
                  text =string.format( __('剩余次数:%s/%s'), checkint(self.data.attendLeftTimes)  , checkint(self.data.attendMaxTimes)) }
            }
        } )

    elseif self.scriptType == COST_DATA.COOS_GOODS then
        local data =  {}
        if self.data.goodsData  and table.nums( self.data.goodsData) > 0  then
            dump(self.data.goodsData)
            for i =1  , #self.data.goodsData do
                data[#data+1] =  { fontSize= 22 , color = "#ffffff"  ,
                                   text =string.format( __('消耗 %s'), tostring(self.data.goodsData[i].num)) }
                data[#data+1] = { img = CommonUtils.GetGoodsIconPathById(self.data.goodsData[i].goodsId) , scale = 0.15}
            end
            display.reloadRichLabel(viewData.battleLabel , {
                c = data
            })
        end
    elseif self.scriptType == COST_DATA.NO_CONSUME then

    end
    -- 跟新技能的显示,更新界面的显示
    self:UpdateSkillView(self.equipedPlayerSkills)
    self:UpdateTeamView(self.teamData)
end
-- 返回请求需要的数据
function BattleScriptTeamMediator:ReturnRequestSignalData()
    local cards = {}
    local skill = {}
    for i, v in pairs(self.teamData) do
        if v.id then
            cards[tostring(i)] = v.id
        end
    end
    for i, v in pairs(self.equipedPlayerSkills) do
        if v.skillId then
            skill[tostring(i)] = v.skillId
        end
    end

    local data ={
        cards = cards ,
        skill = skill
    }
    return data
end
--[[
    战斗的回调事件
]]
function BattleScriptTeamMediator:BattleCallBack(sender)
    if self.callback and type(self.callback) == "function" then
        local data = self:ReturnRequestSignalData()
        if table.nums(data.cards) > 0  then
            self.callback(data)
        else
            uiMgr:ShowInformationTips(__('请添加飨灵'))
        end

    end
end

--[[
转换激活的主角技数据结构
@params allSkill 所有激活的主角技数据
@return result table 转换后的数据结构
--]]
function BattleScriptTeamMediator:convertPlayerSkillData(allSkill)
    local skillId = 0
    local skillConf = nil

    local result = {
        activeSkill = {},
        passiveSkill = {}
    }

    for i,v in ipairs(allSkill) do
        skillId = checkint(v)
        skillConf = CommonUtils.GetSkillConf(skillId)
        local skillInfo = {skillId = skillId}
        if ConfigSkillType.SKILL_HALO == checkint(skillConf.property) then
            -- 被动技能
            table.insert(result.passiveSkill, skillInfo)
        else
            -- 主动技能
            table.insert(result.activeSkill, skillInfo)
        end
    end
    return result
end
function BattleScriptTeamMediator:AddCardClick(sender)
    local layer = require('Game.views.pvc.PVCChangeTeamScene').new({
        teamDatas = {[1] = self.teamData},
        title = self.data.battleTitle or   __('编辑防守队伍'),
        teamTowards = -1,
        avatarTowards = 1,
        teamChangeSingalName =  "TEAM_CHANGE_NOTICE" ,
        limitCardsCareers =  self.limitCardsCareers,
        limitCardsQualities =  self.limitCardsQualities,
        allCards = self.allCards ,
        isDisableHomeTopSignal =  self.isDisableHomeTopSignal,
        battleType  = self.battleType
    })
    layer:setAnchorPoint(cc.p(0.5, 0.5))
    layer:setPosition(display.center)
    layer:setTag(4001)
    uiMgr:GetCurrentScene():AddDialog(layer)
    self.chooseTeamLayer = layer
end
-- 更新编队页面的显示
function BattleScriptTeamMediator:UpdateTeamView(data)
    local viewData = self.viewComponent.viewData
    local allCardLayout = viewData.allCardLayout
    --local allData =
    local node = allCardLayout:getChildByTag(1)
    local nodeSize = node:getContentSize()

    for k ,v in pairs (data or {}) do
        node = allCardLayout:getChildByTag(checkint(k))
        nodeSize = node:getContentSize()
        -- 如果有该Node 直接删除 重新添加 
        local cardNode = node:getChildByName("cardNode")
        if cardNode and ( not tolua.isnull(cardNode) ) then
            cardNode:removeFromParent()
        end
        if v.id and checkint(v.id) > 0 then -- 判断该位置的id 是否存在
            local cardHeadNode = require('common.CardHeadNode').new({id = checkint(v.id), showActionState = false,isgrassColor = isHave })
            cardHeadNode:setPosition(cc.p(nodeSize.width/2, nodeSize.height/2 ))
            cardHeadNode:setName("cardNode")
            node:addChild(cardHeadNode)
            cardHeadNode:setScale(0.62)
            local cardAdd = node:getChildByName("cardAdd")
            cardAdd:setVisible(false)
        else
            local cardAdd = node:getChildByName("cardAdd")
            cardAdd:setVisible(true)
        end
    end
end
-- 更新技能的显示
function BattleScriptTeamMediator:UpdateSkillView(data)
    local viewData = self.viewComponent.viewData
    local skillSize  = viewData.skillOneLayout:getContentSize()
    for k ,v in pairs(data) do
        local node = nil
        local isHave = false
        if checkint(k) == 1 then
            node = viewData.skillOneLayout
            if checkint(v.skillId) > 0    then
                isHave = true
            end
        elseif checkint(k)  == 2 then
            node = viewData.skillTwoLayout
            if checkint(v.skillId) > 0   then
                isHave = true
            end
        end
        -- 技能在的话就删除
        local skillIcon = node:getChildByName("skillIcon")
        if skillIcon and not  tolua.isnull(skillIcon) then
            skillIcon:removeFromParent()
        end
        if isHave then
            local skillIcon = require('common.PlayerSkillNode').new({id = nil ~= v and v.skillId or 0})
            skillIcon:setPosition(cc.p(skillSize.width/2 , skillSize.height/2))
            skillIcon:setName("skillIcon")
            node:addChild(skillIcon ,10)
        end
    end
end
--[[
    动作按钮
--]]
function BattleScriptTeamMediator:ButtonAction(sender)
    local tag  = sender:getTag()
    if tag == BUTTON_CLICK.CLOSE_TAG then
        self.viewComponent:BottomRunAction(false)
        uiMgr:GetCurrentScene():runAction(
            cc.Sequence:create(    -- 获取队列的动画展示
                cc.DelayTime:create(0.2) ,
                cc.CallFunc:create(function ( )
                    self:GetFacade():UnRegsitMediator(NAME)
                end)
            )
        )

    elseif tag == BUTTON_CLICK.SKILL_ONE or tag ==BUTTON_CLICK.SKILL_TWO then
        local index =  tag - 11000
        local data ={
            equipedPlayerSkills = self.equipedPlayerSkills ,
            allSkills = self.allSkills.activeSkill,
            slotIndex = index
        }
        local tag = 4002
        data.tag = tag
        local layer = require('Game.views.SelectPlayerSkillPopup').new(data)
        display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
        layer:setTag(tag)
        uiMgr:GetCurrentScene():AddDialog(layer)
    end
end
--[[
    注册的通知
--]]
function BattleScriptTeamMediator:OnRegist()

end

function BattleScriptTeamMediator:OnUnRegist()
    if self.viewComponent and (not tolua.isnull(self.viewComponent)  )  then
        self.viewComponent:runAction( cc.RemoveSelf:create())
    end
end

return BattleScriptTeamMediator



