--[[
boss详情
--]]
local Mediator = mvc.Mediator
local BossDetailMediator = class("BossDetailMediator", Mediator)
local NAME = "BossDetailMediator"
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local CardManager = AppFacade.GetInstance():GetManager("CardManager")
local TowerConfigParser = require('Game.Datas.Parser.TowerConfigParser')
--==============================--
--desc:
--time:2017-07-06 01:57:01
--@params:
--[[
    {
        questId = 2  -- 关卡数 
    }
]]
--@viewComponent:
--@return 
--==============================--

local QUEST_BOSS_TYPE  = 1 
local EXPLOREQUEST_BOSS_TYPE = 2 
function BossDetailMediator:ctor( params, viewComponent )
	self.super.ctor(self, NAME, viewComponent)
    self.datas = params or {} 
    -- self.datas.type = params.type or 1 
    self.bossTabel = {} -- 里面存放当前boss的数据
    self.bossAllData = CommonUtils.GetConfigAllMess('monster','monster')
    self.preCilck = nil  -- 记录上一次的点击
    self.collectBtn = {} -- 按钮集合
    local monsterInfo = {}
    if self.datas.towerUnitId then
        self.questData = CommonUtils.GetConfigAllMess(TowerConfigParser.TYPE.UNIT ,'tower')[tostring(self.datas.towerUnitId)] or {}
        monsterInfo = self.questData.monsterInfo
    else
        self.questData = CommonUtils.GetQuestConf(self.datas.questId or 1) or {}--因为这个里面已经做了关卡的区分 所有不用处理type 的类型
        monsterInfo = self.questData.monsterInfo
    end
    local bossIdtable = checktable(monsterInfo)
    self:GetQuestBoss(bossIdtable)
end

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function BossDetailMediator:InterestSignals()
	local signals = {

	}
	return signals
end
--==============================--
--desc:获取当前boss的
--time:2017-07-06 02:14:43
--@bossIdtable:这个里面存放的是 boss 的Id
--@return 
--==============================--
function BossDetailMediator:GetQuestBoss(bossIdtable)
    for i = 1 , #bossIdtable do 
        local data =  self.bossAllData[tostring(bossIdtable[i])]
        self.bossTabel[#self.bossTabel+1] = clone(data)
    end

end
--==============================--
--desc:查找boss 的相信信息
--drawId: 根据drawId 查找boss 的信息
--time:2017-07-07 10:20:35
--@return 
--==============================--
function BossDetailMediator:FindNowBossInfo(bossId)
    for i =1 , #self.bossTabel do 
        if bossId == checkint(self.bossTabel[i].id ) then
            return  self.bossTabel[i] 
        end 
    end 
    return {}
end

function BossDetailMediator:Initial( key )
	self.super:Initial(key)
    -- if #self.bossTabel == 0 then
    --     uiMgr:ShowInformationTips(__('当前关卡没有怪物'))
    --     self:BackAction()
    --     return 
    -- end 
    local BossDetailView = require('Game.views.BossDetailView')
    local layer = BossDetailView.new()
    layer:setPosition(display.center)
    self.viewData = layer.viewData
    uiMgr:GetCurrentScene():AddDialog(layer)
    self:SetViewComponent(layer)

    local headData =  layer:createBossHeadlayout(#self.bossTabel)
    for i =1 , #self.bossTabel do
        headData.headTable[i].headImage:setTexture(AssetsUtils.GetCardHeadPath(self.bossTabel[i].drawId))
        headData.headTable[i].headButton:setOnClickScriptHandler(handler(self,self.ButtonAction))
        headData.headTable[i].headButton:setTag(checkint(self.bossTabel[i].id))
        self.collectBtn[tostring(self.bossTabel[i].id)] = headData.headTable[i].headButton
    end
    layer:addChild(headData.bossCollectLayout)
    headData.bossCollectLayout:setPosition(cc.p(display.SAFE_L + 50,display.cy * 3/2))
    headData.bossCollectLayout:setAnchorPoint(display.LEFT_TOP)
    if  #self.bossTabel == 1 then
        headData.bossCollectLayout:setVisible(false)
    end
    local seq  = cc.Sequence:create(
        cc.CallFunc:create(function() 
            self.viewData.bossImage:setVisible(true)
            self.viewData.bossImage:setOpacity(0)
            self.viewData.bossImage:RefreshAvatar({confId = checkint(checktable(self.bossTabel[1]).id)})
            self.viewData.rightLayout:setVisible(true)
            self.viewData.rightLayout:setOpacity(0)
            self.viewData.navBackButton:setVisible(true)
            self.viewData.navBackButton:setOpacity(0)
        end) ,
        cc.Spawn:create(
            cc.TargetedAction:create(self.viewData.bossImage, cc.FadeIn:create(0.2)),
            cc.TargetedAction:create(self.viewData.navBackButton, cc.FadeIn:create(0.2))
        ) ,
         cc.CallFunc:create(function ()
            self.viewData.navBackButton:setOnClickScriptHandler(handler(self, self.BackAction))
            self:ButtonAction(self.collectBtn[tostring(checktable(self.bossTabel[1]).id)]) 
            
         end),
         cc.TargetedAction:create(self.viewData.rightLayout , cc.FadeIn:create(0.2))
    )
    layer:runAction(seq)
end
--==============================--
--desc: 加载boss介绍和技能的子项
--time:2017-07-06 02:55:57
--@return 
--==============================--
function BossDetailMediator:AddBossViewDetailCell()
    local layer = self:GetViewComponent()
    if self.bossTabel[1] then
        -- dump(self.bossTabel[1])
        local bossData  = self.bossTabel[1]
        local cellData = layer:CreateBossDetailCell()
        layer:UpdateBossDetailCell(cellData ,self.bossTabel[1])
        self.viewData.bossIntroduceList:insertNodeAtLast(cellData.celllayout)
        --self.bossTabel[1].showSkill = { "10039",  "20085"}
        for i =1 , #self.bossTabel[1].showSkill do 
            cellData = layer:CreateBossSkillCell()
            local skillData = CardUtils.GetSkillConfigBySkillId(self.bossTabel[1].showSkill[i])
            layer:UpdateeBossSkillCell(cellData,skillData)
            self.viewData.bossIntroduceList:insertNodeAtLast(cellData.cellLayout)
        end 
    end 
    self.viewData.bossIntroduceList:reloadData()
end
function BossDetailMediator:ButtonAction(sender)
    if not sender then return end
    local  tag = sender:getTag()
    local node =   self.collectBtn[tostring(self.preCilck)]
    if self.preCilck then
        if self.preCilck == tag   then -- 点击同一个按钮就返回 不做任何操作
            return 
        else -- 若为不同的点击按钮 将上次的点击按钮重置为可点击的状态
            node:setChecked(false)
            node:setEnabled(true)
            local parentNode = node:getParent()
            local heaButtonTop = parentNode:getChildByName("heaButtonTop")
            heaButtonTop:setVisible(false)
        end
    else  --- 表示第一次进入 
       
        self:AddBossViewDetailCell()
        sender:setChecked(true)
        sender:setEnabled(false)
        local parentNode = sender:getParent()
        local heaButtonTop = parentNode:getChildByName("heaButtonTop")
        heaButtonTop:setVisible(true )
        self.preCilck = tag 
        return 
    end 
    self.preCilck = tag 
    self:UpdateCellInfor()
    local parentNode = sender:getParent()
    local heaButtonTop = parentNode:getChildByName("heaButtonTop")
    heaButtonTop:setVisible(true )
    self.viewData.bossImage:RefreshAvatar({confId = tag})
end
--==============================--
--desc:更新怪物的显示信息
--time:2017-07-07 10:14:55
--@return 
--==============================--
function BossDetailMediator:UpdateCellInfor()
    local listView  = self:GetViewComponent().viewData.bossIntroduceList 
    local cellTable = listView:getNodes()
    local bossInfo = self:FindNowBossInfo(self.preCilck)
    if bossInfo.showSkill then
        if #bossInfo.showSkill +1 < #cellTable then -- 如果list 的子项比当前怪物的子项多 ，就删除多余的子项
            for i =  #cellTable , #bossInfo.showSkill+1+1 , -1 do 
                listView:removeNodeAtIndex(i -1)
            end 
        elseif  #(bossInfo.showSkill)+1 > #cellTable then -- 如果子项比当前怪物的少 ，就创建添加子项
           for i =  #cellTable+1 ,  #bossInfo.showSkill+1  do 
                local cellData =  self:GetViewComponent():CreateBossSkillCell()
                listView:insertNodeAtLast(cellData.cellLayout)
            end            
        end 
    end 
    local cellTable = listView:getNodes()
    local infoCell = listView:getNodeAtIndex(0) -- 因为第一项是固定介绍怪物的信息的
    self:GetViewComponent():UpdateBossDetailCell(infoCell.viewData,bossInfo)
    for i =2 , #cellTable do 
        local skillInfor = listView:getNodeAtIndex(i-1) -- 后面的都是技能介绍 因为c++ 中并没有做减一的操作 所以lua 这里要手动减一
        self:GetViewComponent():UpdateeBossSkillCell(skillInfor.viewData, CardUtils.GetSkillConfigBySkillId(bossInfo.showSkill[i-1]) )
    end 
    listView:reloadData()
end
function BossDetailMediator:OnRegist()
    
end
function BossDetailMediator:BackAction()
    PlayAudioByClickClose()
    AppFacade.GetInstance():UnRegsitMediator("BossDetailMediator")
end
function BossDetailMediator:OnUnRegist()
	-- 移除战斗音效
    local layer = self:GetViewComponent()
    if not layer then
        return 
    end  
    self:GetViewComponent():stopAllActions()
    
    self:GetViewComponent():runAction(cc.RemoveSelf:create())
end
return BossDetailMediator
