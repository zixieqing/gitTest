local Mediator = mvc.Mediator
---@class BossStoryMediator
local BossStoryMediator = class("BossStoryMediator", Mediator)
local NAME = "BossStoryMediator"
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
---@type DataManager
local dataMgr =  AppFacade.GetInstance():GetManager("DataManager")
local SELECT_BTNCHECK = {
    BOSS_TYPECASE = 4 ,  -- 特型
    BOSS_DISSMAILATION = 3, -- 异化
    BOSS_COMMON = 2 ,  -- 普通
    BOSS_ASSICAST = 1   -- 伴生
}
function BossStoryMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.preClickIndex = nil             -- 当前的点击
    self.bossAllKindsData = {}           -- 当前的boss 总数量的种类
    self.viewCollect = {}                -- 页面收集操作cd
    self.tipLayout =  nil
    self.tipsSelectIndex =  nil
    self.preCommonButton  =   nil
    self.preAsociateCell =  nil    -- 确定第上一次
    self.preCommonDetailOne = nil
    self.commonData = {}
end

function BossStoryMediator:Initial( key )
	self.super.Initial(self,key)
    self:SortOutBossKinds()
    self:KindsOfCommonData()
    local scene = uiMgr:SwitchToTargetScene("Game.views.BossStoryView")
	self:SetViewComponent(scene)
    self.viewData = scene.viewData
    for k,v in pairs(self.viewData.checkButtons) do
       v:setOnClickScriptHandler(handler(self, self.ButtonAction))
    end
    self:GetViewComponent():UpdateButtonDisplay(gameMgr:GetUserInfo().monster , self.bossAllKindsData)
    self:ButtonAction(self.viewData.checkButtons[tostring(SELECT_BTNCHECK.BOSS_TYPECASE)])

end
--==============================--
--desc:把当前boss类做一下整理
--time:2017-07-19 03:34:07
--@return
--==============================--
function BossStoryMediator:SortOutBossKinds()
    local collectMonster  = CommonUtils.GetConfigAllMess('monster','collection')
    -- 这个里面存放着图鉴的类别
    self.bossAllKindsData = {}
    for k , v in pairs(collectMonster) do
        if v.type then
            local type = tostring( v.type)
            if not  self.bossAllKindsData[type] then -- 如果当前种类不存在
                self.bossAllKindsData[type] = {}
            end
            self.bossAllKindsData[type][#self.bossAllKindsData[type]+1] = clone(v)
            local value  = gameMgr:GetUserInfo().monster[tostring(k)]
            if value then
                self.bossAllKindsData[type][#self.bossAllKindsData[type]].status = value
                if checkint(type) == SELECT_BTNCHECK.BOSS_TYPECASE or checkint(type) == SELECT_BTNCHECK.BOSS_DISSMAILATION then
                     if checkint(value) == 3  then  -- 3 是表示已经获得
                        local num =  dataMgr:GetRedDotNofication("boss",v.id)
                        if num == 0 then --如果没有证明是第一次出现
                           self.bossAllKindsData[type][#self.bossAllKindsData[type]].newIcon = true
                        end
                     end
                end
            else
                self.bossAllKindsData[type][#self.bossAllKindsData[type]].status = 1 --未知
            end
        end
    end
end
-- 给普通怪物分类
function BossStoryMediator:KindsOfCommonData()
    for k , v  in pairs(self.bossAllKindsData[tostring(SELECT_BTNCHECK.BOSS_COMMON)]) do
        if not  self.commonData[tostring(v.familyId)] then
            self.commonData[tostring(v.familyId)] = {}

        end
        self.commonData[tostring(v.familyId)][#self.commonData[tostring(v.familyId)]+1] = v
    end
end
function BossStoryMediator:ButtonAction(sender)
    local tag = sender:getTag()
    if self.preClickIndex == tag  then -- 如果点击同一个按钮不做更新处理
        return
    end
    self.isAction = false
    if  tag == SELECT_BTNCHECK.BOSS_TYPECASE then --特型
        --dump(self.bossAllKindsData[tostring(tag)])

        if not  self.viewCollect[tostring(tag)] then
            local gridView = self:GetViewComponent():CreateBossTypecaseAndMailAtion(tag)
            self.viewCollect[tostring(SELECT_BTNCHECK.BOSS_TYPECASE)] = gridView
            gridView:setDataSourceAdapterScriptHandler(handler(self,self.onMakeTypeCastDataSourceAction))
            self.viewData.middleLayout:addChild(gridView)
            gridView:setCountOfCell(table.nums(  self.bossAllKindsData[tostring(tag)]  or {}))
            gridView:reloadData()
        end
    elseif tag == SELECT_BTNCHECK.BOSS_DISSMAILATION then -- 异化
        if not  self.viewCollect[tostring(tag)] then
            local gridView = self:GetViewComponent():CreateBossTypecaseAndMailAtion(tag)
            self.viewCollect[tostring(SELECT_BTNCHECK.BOSS_DISSMAILATION)] = gridView
            gridView:setDataSourceAdapterScriptHandler(handler(self,self.onMakeDissDataSourceAction))
            self.viewData.middleLayout:addChild(gridView)
            gridView:setCountOfCell(table.nums( self.bossAllKindsData[tostring(tag)] or {}))
            gridView:reloadData()
        end
    elseif tag == SELECT_BTNCHECK.BOSS_COMMON then -- 普通
        if not  self.viewCollect[tostring(tag)] then
            local view = self:GetViewComponent():CreateBossCommonView()
            self.viewCollect[tostring(tag)] = view
            local middleSize = self.viewData.middleLayout:getContentSize()
            view:setPosition(cc.p(middleSize.width/2 , middleSize.height/2))
            self.viewData.middleLayout:addChild(view)
            local buttonTable = view.viewData.kindsList:getNodes()
            local introduceLayout = view.viewData.introduceLayout
            introduceLayout:setVisible(false)
            introduceLayout:runAction(cc.Sequence:create(
            cc.MoveBy:create(0, cc.p(0,-625)) ,
            cc.DelayTime:create(0.05 * checkint(i)),
            cc.CallFunc:create(function ()
                introduceLayout:setVisible(true)
                introduceLayout:setOpacity(0)
            end) ,
            cc.Spawn:create( cc.FadeIn:create(0.2) ,
            cc.JumpBy:create(0.2, cc.p(0, 625) ,10,1)
            )
            ))
            for k , v in pairs(buttonTable) do

                local node = v:getChildByName("kindsButton")
                node:setVisible(false)
                node:runAction(cc.Sequence:create(
                cc.MoveBy:create(0, cc.p(-100,0)) ,
                cc.DelayTime:create(0.05 * checkint(k)),
                cc.CallFunc:create(function ()
                    node:setVisible(true)
                    node:setOpacity(0)
                end) ,
                cc.Spawn:create( cc.FadeIn:create(0.2) ,
                cc.JumpBy:create(0.2, cc.p(100, 0) ,0,1)
                )
                ))
                if node then
                    node:setOnClickScriptHandler(handler(self, self.UpdateComonView))
                end

            end
            if buttonTable and buttonTable[1] then
                local node = buttonTable[1]:getChildByName("kindsButton")
                if node then
                    self:UpdateComonView(node)
                end
            end

        end
    elseif tag == SELECT_BTNCHECK.BOSS_ASSICAST then -- 伴生

        if not  self.viewCollect[tostring(tag)] then
            local view =  self:GetViewComponent():CreateAssociateView()
            self.viewCollect[tostring(tag)] = view
            local middleSize = self.viewData.middleLayout:getContentSize()
            view:setPosition(cc.p(middleSize.width/2 , middleSize.height/2))
            self.viewData.middleLayout:addChild(view)
            for i =1 , #self.bossAllKindsData[tostring(tag)] do
                v =  self.bossAllKindsData[tostring(tag)][i]
                local pCell = require("Game.views.BossStoryCellView").new()
                pCell:setVisible(false)
                pCell:runAction(cc.Sequence:create(
                    cc.MoveBy:create(0, cc.p(0,-625)) ,
                    cc.DelayTime:create(0.05 * checkint(i)),
                    cc.CallFunc:create(function ()
                        pCell:setVisible(true)
                        pCell:setOpacity(0)
                    end) ,
                    cc.Spawn:create( cc.FadeIn:create(0.2) ,
                    cc.JumpBy:create(0.2, cc.p(0, 625) ,10,1)
                    )
                ))
                pCell:UpdateCommonCell(v)
                pCell.viewData.clickLayer:setTag(i)
                pCell.viewData.clickLayer:setOnClickScriptHandler(handler(self,self.UpdateAssociateCell))
                view.viewData.associateList:insertNodeAtLast(pCell)


            end
            view.viewData.associateList:reloadData()
        end
    end
    self:DealWithClickButton(tag)
    if  self.preClickIndex then
        self.viewCollect[tostring(self.preClickIndex)]:runAction(cc.RemoveSelf:create())
        self.viewCollect[tostring(self.preClickIndex)] = nil
    end

    self.preClickIndex = tag
end

function BossStoryMediator:UpdateAssociateCell(sender)
    if self.isAction then
        return
    end
    local tag = sender:getTag()

    local data = self.bossAllKindsData[tostring(SELECT_BTNCHECK.BOSS_ASSICAST)][tag]

    if  self.viewCollect[tostring(SELECT_BTNCHECK.BOSS_ASSICAST)]  then
        if  self.preAsociateCell and (not tolua.isnull(self.preAsociateCell)) then
            local preTag =   self.preAsociateCell:getTag()
            local view =  self.viewCollect[tostring(SELECT_BTNCHECK.BOSS_ASSICAST)]
            local cell =   self.preAsociateCell:getParent()
            local node = cell:getChildByName("bossIdImage")
            if  node  and  (not tolua.isnull(node))then
                node:stopAllActions()
                local cellSize = cell:getContentSize()
                node:setPosition(cc.p(cellSize.width/2 , cellSize.height/2))
            end
            view.viewData.associateList:removeNodeAtIndex(preTag)
            -- 如果存在了介绍的内容，并且点击的是相同的位置 就刷新数据直接返回
            if tag == preTag then
                view.viewData.associateList:reloadData()
                self.preAsociateCell = nil
                return
            end
        end
        if checkint(data.status)  > 1 then
            self.preAsociateCell = sender
            local cell =   self.preAsociateCell:getParent()
            local node = cell:getChildByName("bossIdImage")

            local introduceLayout = self:GetViewComponent():AssociatedIntroduce()
            local view = self.viewCollect[tostring(SELECT_BTNCHECK.BOSS_ASSICAST)]
            view.viewData.associateList:insertNode(introduceLayout, tag)

            introduceLayout.viewData.introduceLabel:setString(data.descr)
            view.viewData.associateList:reloadData()
            local commonCell = view.viewData.associateList:getNodeAtIndex(tag)
            if  node  and  (not tolua.isnull(node))then

                commonCell:stopAllActions()
                commonCell:setOpacity(0)
                introduceLayout.viewData.introduceLabel:setOpacity(0)
                introduceLayout.viewData.introduceImage:setOpacity(0)
                introduceLayout.viewData.titleImage:setOpacity(0)
                introduceLayout.viewData.titleLabel:setOpacity(0)
                self.isAction = true
                commonCell:runAction(
                cc.Sequence:create(
                cc.Spawn:create(
                cc.Sequence:create( cc.DelayTime:create(0.15),cc.FadeIn:create(0.25)  ),
                cc.TargetedAction:create(introduceLayout.viewData.introduceLabel ,  cc.Sequence:create( cc.DelayTime:create(0.15),cc.FadeIn:create(0.25)  ) ),
                cc.TargetedAction:create(introduceLayout.viewData.introduceImage ,  cc.Sequence:create( cc.DelayTime:create(0.15),cc.FadeIn:create(0.25)  ) ),
                cc.TargetedAction:create(introduceLayout.viewData.titleImage ,  cc.Sequence:create( cc.DelayTime:create(0.15),cc.FadeIn:create(0.25)  ) ),
                cc.TargetedAction:create(introduceLayout.viewData.titleLabel ,  cc.Sequence:create( cc.DelayTime:create(0.15),cc.FadeIn:create(0.25)  ) ),
                cc.Sequence:create( cc.EaseBackIn:create(cc.MoveBy:create(0.4,cc.p(400,0))) )
                ) ,
                cc.CallFunc:create(function ()
                    --if  self.preSureAsociateCell and  (not tolua.isnull(self.preSureAsociateCell))   and  ( self.preSureAsociateCell:getTag() == sender:getTag()) then
                    --    return
                    --end
                    local nodes =  view.viewData.associateList:getNodes()
                    for k , v in pairs(nodes) do
                        v:stopAllActions()
                        local cellLayout = v:getChildByName("cellLayout")
                        if cellLayout and (not tolua.isnull(cellLayout) ) then
                            local bossIdImage = cellLayout:getChildByName("bossIdImage")
                            if bossIdImage and (not tolua.isnull(bossIdImage) ) then
                                self:StopPreSpineAction(v.viewData.clickLayer,false )
                            end
                        end

                    end
                    self:CreateOrUpdateSpineAction(data.id, sender,false)
                end)
                )
                )
            end
        else
            local view = self.viewCollect[tostring(SELECT_BTNCHECK.BOSS_ASSICAST)]
            self.preAsociateCell = nil
            view.viewData.associateList:reloadData()
            local nodes =  view.viewData.associateList:getNodes()
            for k , v in pairs(nodes) do
                v:stopAllActions()
                local cellLayout =  v:getChildByName("cellLayout")
                if cellLayout and (not tolua.isnull(cellLayout) ) then
                    local bossIdImage = cellLayout:getChildByName("bossIdImage")
                    if bossIdImage and (not tolua.isnull(bossIdImage) ) then
                        self:StopPreSpineAction(v.viewData.clickLayer,true )
                    end
                end
            end
            uiMgr:ShowInformationTips(__('探索更多关卡可获得更多堕神信息~'))
        end

    end
end
function BossStoryMediator:UpdateComonView(sender)
    self.commonData[tostring(tag)] = self.commonData[tostring(tag)] or {}
    local tag = sender:getTag()

    if   self.preCommonButton and not  tolua.isnull(self.preCommonButton) then
        PlayAudioByClickNormal()
        local preTag =  self.preCommonButton:getTag()
        if preTag == tag then
            return
        else
            self.preCommonButton:setEnabled(true)
            self.preCommonButton:setChecked(false)
        end
    end
    sender:setEnabled(false)
    sender:setChecked(true)
    self.preCommonButton = sender
    local  monsterFamily  = CommonUtils.GetConfigAllMess("monsterFamily", 'collection')
    local view = self.viewCollect[tostring(SELECT_BTNCHECK.BOSS_COMMON)]
    view.viewData.introduceLabel:setString(monsterFamily[tostring(tag)].descr)
    view.viewData.commonList:removeAllNodes()

    for k , v in pairs(self.commonData[tostring(tag)] or {}) do
        local pCell = require("Game.views.BossStoryCellView").new()
        local pCell = require("Game.views.BossStoryCellView").new()
        pCell:setVisible(false)
        pCell:runAction(cc.Sequence:create(
        cc.MoveBy:create(0, cc.p(0,-625)) ,
        cc.DelayTime:create(0.05 * checkint(k)),
        cc.CallFunc:create(function ()
            pCell:setVisible(true)
            pCell:setOpacity(0)
        end) ,
        cc.Spawn:create( cc.FadeIn:create(0.2) ,
        cc.JumpBy:create(0.2, cc.p(0, 625) ,10,1)
        )
        ))
        pCell:UpdateCommonCell(v)
        pCell.viewData.clickLayer:setTag(checkint(k))
        pCell.viewData.clickLayer:setOnClickScriptHandler(handler(self,self.JudgeCommonBossExist) )
        view.viewData.commonList:insertNodeAtLast(pCell)
    end
    view.viewData.commonList:reloadData()
end


function BossStoryMediator:JudgeCommonBossExist(sender)
    local tag = sender:getTag()
    if  self.isAction  then
        return
    end

    if self.preCommonButton then
        PlayAudioByClickNormal()
        local kindIndex =self.preCommonButton:getTag()
        local data = self.commonData[tostring(kindIndex)][tag]

        if self.preCommonDetailOne and (not tolua.isnull(self.preCommonDetailOne) )  then
            self:StopPreSpineAction(self.preCommonDetailOne)
            local view = self.viewCollect[tostring(SELECT_BTNCHECK.BOSS_COMMON)]
            local preTag = self.preCommonDetailOne:getTag()
            view.viewData.commonList:removeNodeAtIndex(preTag)
            -- 如果存在了介绍的内容，并且点击的是相同的位置 就刷新数据直接返回
            if tag == preTag then
                view.viewData.commonList:reloadData()
                self.preCommonDetailOne = nil
                return
            end
        end
        local isUnObtain = false
        if checkint(data.status)  <=1  then
            uiMgr:ShowInformationTips(__('探索更多关卡可获得更多堕神信息~'))
            self.preCommonDetailOne = nil
            isUnObtain = true
        elseif checkint(data.status)  <=2  then
            uiMgr:ShowInformationTips(__("尚未获得该堕神"))
            self.preCommonDetailOne = nil
            isUnObtain = true

        end
        if isUnObtain then
            local view = self.viewCollect[tostring(SELECT_BTNCHECK.BOSS_COMMON)]
            self.preCommonDetailOne = nil
            view.viewData.commonList:reloadData()
            local nodes =  view.viewData.commonList:getNodes()
            for k , v in pairs(nodes) do
                v:stopAllActions()
                local cellLayout =  v:getChildByName("cellLayout")
                if cellLayout and (not tolua.isnull(cellLayout) ) then
                    local bossIdImage = cellLayout:getChildByName("bossIdImage")
                    if bossIdImage and (not tolua.isnull(bossIdImage) ) then
                        self:StopPreSpineAction(v.viewData.clickLayer,true )
                    end
                end
            end
            return
            --uiMgr:ShowInformationTips(__('探索更多关卡可获得更多堕神信息~'))
        end
        self.preCommonDetailOne = sender
        local cell =   self.preCommonDetailOne:getParent()
        local node = cell:getChildByName("bossIdImage")

        local introduceLayout = self:GetViewComponent():AssociatedIntroduce()
        local view = self.viewCollect[tostring(SELECT_BTNCHECK.BOSS_COMMON)]
        view.viewData.commonList:insertNode(introduceLayout, tag)

        introduceLayout.viewData.introduceLabel:setString(data.descr)
        view.viewData.commonList:reloadData()

        local commonCell = view.viewData.commonList:getNodeAtIndex(tag)

        if  node  and  (not tolua.isnull(node))then

            commonCell:stopAllActions()
            commonCell:setOpacity(0)
            introduceLayout.viewData.introduceLabel:setOpacity(0)
            introduceLayout.viewData.introduceImage:setOpacity(0)
            introduceLayout.viewData.titleImage:setOpacity(0)
            introduceLayout.viewData.titleLabel:setOpacity(0)
            self.isAction = true
            commonCell:runAction(
            cc.Sequence:create(
            cc.CallFunc:create(function ()
                local cellSize = cell:getParent():getContentSize()
                local introduceLayoutSize =  introduceLayout:getContentSize()
                local allWith = introduceLayoutSize.width  + (cellSize.width * tag)
                local offsetWidth = view.viewData.commonList:getContentSize().width  -  allWith
                if offsetWidth <    0 then
                    view.viewData.commonList:setContentOffsetInDuration(cc.p(offsetWidth ,0 )  , 0.2)
                end
            end),
            cc.Spawn:create(
            cc.Sequence:create( cc.DelayTime:create(0.15),cc.FadeIn:create(0.25)  ),
            cc.TargetedAction:create(introduceLayout.viewData.introduceLabel ,  cc.Sequence:create( cc.DelayTime:create(0.15),cc.FadeIn:create(0.25)  ) ),
            cc.TargetedAction:create(introduceLayout.viewData.introduceImage ,  cc.Sequence:create( cc.DelayTime:create(0.15),cc.FadeIn:create(0.25)  ) ),
            cc.TargetedAction:create(introduceLayout.viewData.titleImage ,  cc.Sequence:create( cc.DelayTime:create(0.15),cc.FadeIn:create(0.25)  ) ),
            cc.TargetedAction:create(introduceLayout.viewData.titleLabel ,  cc.Sequence:create( cc.DelayTime:create(0.15),cc.FadeIn:create(0.25)  ) ),
            cc.Sequence:create( cc.EaseBackIn:create(cc.MoveBy:create(0.4,cc.p(400,0))) )
            ) ,
            cc.CallFunc:create(function ()
                --if  self.preSureAsociateCell and  (not tolua.isnull(self.preSureAsociateCell))   and  ( self.preSureAsociateCell:getTag() == sender:getTag()) then
                --    return
                --end
                local nodes =  view.viewData.commonList:getNodes()
                for k , v in pairs(nodes) do
                    v:stopAllActions()
                    local cellLayout = v:getChildByName("cellLayout")
                    if cellLayout and (not tolua.isnull(cellLayout) ) then
                        local bossIdImage = cellLayout:getChildByName("bossIdImage")
                        if bossIdImage and (not tolua.isnull(bossIdImage) ) then
                            self:StopPreSpineAction(v.viewData.clickLayer,false )
                        end
                    end

                end
                self:CreateOrUpdateSpineAction(data.id, sender,false)
            end)
            )
            )
        end
        self:CreateOrUpdateSpineAction(data.id, sender,kindIndex)

    end

end
--- 创建spine 动画 cradId 点击选择的id sender 点击的图片
function BossStoryMediator:CreateOrUpdateSpineAction(cardId ,sender,kindIndex ,isScale )
    if isScale ~= false then
        isScale = -1
    else
        isScale = 1
    end
    local parentNode =sender:getParent()
    local node = parentNode:getChildByName("spine")
    if  tolua.isnull(node ) then
        local parentNodeSize = parentNode:getContentSize()
        local scale = 0.7
        if checkint(kindIndex)  == 1 then
            scale = 0.4
        end
        local qAvatar = AssetsUtils.GetCardSpineNode({confId = cardId, scale = scale})
        qAvatar:setAnimation(0, 'idle', true)
        qAvatar:setPosition(cc.p(parentNodeSize.width/2, parentNodeSize.height/2-63))
        qAvatar:setName("spine")
        qAvatar:setVisible(true)
        qAvatar:setScaleX(isScale)
        local parentSize = parentNode:getContentSize()
        parentNode:addChild(qAvatar,10)
        node = qAvatar
    end
    node:setOpacity(0)
    local bossIdImage =  parentNode:getChildByName("bossIdImage")
    parentNode:runAction(
        cc.Spawn:create(
            cc.Sequence:create(cc.TargetedAction:create(node  ,cc.FadeIn:create(0.2)) ,cc.CallFunc:create(function() self.isAction = false end)),
            cc.TargetedAction:create( bossIdImage  ,cc.FadeOut:create(0.2))
        )
    )
    --return qAvatar
end

--- 暂停当前的spine 动画
function BossStoryMediator:StopPreSpineAction(sender,isDirect)
    local parentNode =sender:getParent()
    local node = parentNode:getChildByName("spine")
    if isDirect then
        if node and not  tolua.isnull(node )  then
            node:setAnimation(0, 'idle', true)
            local bossIdImage =  parentNode:getChildByName("bossIdImage")
            node:setOpacity(0)
            bossIdImage:setOpacity(255)
        end
    else
        if node and not  tolua.isnull(node )  then
            node:setAnimation(0, 'idle', true)
            local bossIdImage =  parentNode:getChildByName("bossIdImage")
            parentNode:runAction(
            cc.Spawn:create(
            cc.TargetedAction:create(bossIdImage  ,cc.FadeIn:create(0.2)) ,
            cc.TargetedAction:create( node  ,cc.FadeOut:create(0.2))
            )
            )
        end
    end

end
--[[
    特性刷新
]]
function BossStoryMediator:onMakeTypeCastDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local index = idx + 1
    local  sizee = cc.size(195,625)
    if pCell == nil then
        ---@type BossStoryCellView
        pCell  = require('Game.views.BossStoryCellView').new()
        pCell.viewData.clickLayer:setTag(index)
        pCell.viewData.clickLayer:setOnClickScriptHandler(handler(self, self.JumpToBossBossStoryDetail))
        pCell.bgLayout:setPosition(cc.p(sizee.width* 0.5,sizee.height * 0.5))
        pCell:setVisible(false)
        pCell:runAction(cc.Sequence:create(
        cc.MoveBy:create(0, cc.p(0,-625)) ,
        cc.DelayTime:create(0.05 * checkint(index)),
        cc.CallFunc:create(function ()
            pCell:setVisible(true)
            pCell:setOpacity(0)
        end) ,
        cc.Spawn:create( cc.FadeIn:create(0.2) ,
        cc.JumpBy:create(0.2, cc.p(0, 625) ,10,1)
        )
        ))
    end
    if self.bossAllKindsData[tostring(SELECT_BTNCHECK.BOSS_TYPECASE)] and index <= table.nums(self.bossAllKindsData[tostring(SELECT_BTNCHECK.BOSS_TYPECASE)]) then

        xTry(function()
            if  self.bossAllKindsData[tostring(SELECT_BTNCHECK.BOSS_DISSMAILATION)][index] then
                pCell.viewData.bossImage:setTag(index)
                pCell:UpdateView(self.bossAllKindsData[tostring(SELECT_BTNCHECK.BOSS_TYPECASE)][index])
            end
        end,__G__TRACKBACK__)
    end
    return pCell

end
--[[
    异化的刷新
--]]
function BossStoryMediator:onMakeDissDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local index = idx + 1
    local  sizee = cc.size(195,625)
    if pCell == nil then
        ---@type BossStoryCellView
        pCell  = require('Game.views.BossStoryCellView').new()
        pCell.viewData.clickLayer:setTag(index)
        pCell.viewData.clickLayer:setOnClickScriptHandler(handler(self, self.JumpToBossBossStoryDetail))
        pCell.bgLayout:setPosition(cc.p(sizee.width* 0.5,sizee.height * 0.5))
        pCell:setVisible(false)
        pCell:runAction(cc.Sequence:create(
        cc.MoveBy:create(0, cc.p(0,-625)) ,
        cc.DelayTime:create(0.05 * checkint(index)),
        cc.CallFunc:create(function ()
            pCell:setVisible(true)
            pCell:setOpacity(0)
        end) ,
        cc.Spawn:create( cc.FadeIn:create(0.2) ,
        cc.JumpBy:create(0.2, cc.p(0, 625) ,10,1)
        )
        ))
    end
    if self.bossAllKindsData[tostring(SELECT_BTNCHECK.BOSS_DISSMAILATION)] and index <= table.nums(self.bossAllKindsData[tostring(SELECT_BTNCHECK.BOSS_DISSMAILATION)]) then
        xTry(function()
            if  self.bossAllKindsData[tostring(SELECT_BTNCHECK.BOSS_DISSMAILATION)][index]  then
                pCell.viewData.bossImage:setTag(index)
                pCell:UpdateView(self.bossAllKindsData[tostring(SELECT_BTNCHECK.BOSS_DISSMAILATION)][index])
            end
        end,__G__TRACKBACK__)
    end
    return pCell

end
--==============================--
--desc: 用于跳转显示
--time:2017-07-19 05:34:47
--@sender:
--@return
--==============================--
function BossStoryMediator:JumpToBossBossStoryDetail(sender)
    --PlayAudioByClickNormal()
    local tag = sender:getTag()
     if  self.bossAllKindsData[tostring(self.preClickIndex)][tag].status  == 1 then --没有遇到过该飨灵就
        uiMgr:ShowInformationTips(__('探索更多关卡可获得更多堕神信息~'))
        return
     end
    if self.bossAllKindsData[tostring(self.preClickIndex)][tag].newIcon  then
        dataMgr:AddRedDotNofication('boss',self.bossAllKindsData[tostring(self.preClickIndex)][tag].id)
        self.bossAllKindsData[tostring(self.preClickIndex)][tag].newIcon = nil
        local parent = sender:getParent():getParent()
        parent.viewData.bossImage:setVisible(false)
        parent.viewData.newIcon:setVisible(false)
    end
    local MonsterStoryDetailMediator = require('Game.mediator.MonsterStoryDetailMediator')
    local mediator = MonsterStoryDetailMediator.new({ id = self.bossAllKindsData[tostring(self.preClickIndex)][tag].id})
    self:GetFacade():RegistMediator(mediator)
end
--==============================--
--desc:处理关于点击后 button 的状态
-- tag 当前点击按钮的tag值
--time:2017-07-19 04:57:49
--@return
--==============================--
function BossStoryMediator:DealWithClickButton(tag)
    local btn =  self.viewData.checkButtons[tostring(tag)]
    if  btn.bossKindsName then
        display.commonLabelParams(btn.bossKindsName,{ fontSize = 26,reqW = 130})
    end
    if  btn.prograssName then
        display.commonLabelParams(btn.prograssName,{ fontSize = 24})
        --display.commonLabelParams(btn.collectLabel,{ fontSize = 24})
        self:UpdateOneButton(btn)
    end
    self.viewCollect[tostring(tag)]:setVisible(true)
    -- 显示当前点击按钮的界面
    btn:setNormalImage( _res( 'ui/home/handbook/pokedex_monster_tab_select.png'))
    btn:setEnabled(false)
    if self.preClickIndex then
        PlayAudioByClickNormal()
        local btn =  self.viewData.checkButtons[tostring(self.preClickIndex)] 
        if  btn.bossKindsName then
            display.commonLabelParams(btn.bossKindsName,{ fontSize = 24,reqW = 130})
        end
        if  btn.prograssName then
            --display.commonLabelParams(btn.prograssName,{ fontSize = 22})
            --display.commonLabelParams(btn.collectLabel,{ fontSize = 22})
            display.commonLabelParams(btn.prograssName,{ fontSize = 22})
            self:UpdateOneButton(btn)
        end
        self.viewCollect[tostring(self.preClickIndex)]:setVisible(false)
        -- 设置当前按钮的状态为隐藏状态
        btn:setNormalImage(_res( 'ui/home/handbook/pokedex_monster_tab_default.png'))
        btn:setEnabled(true)
    end
end
-- 更新收集显示的字体
function BossStoryMediator:UpdateOneButton(btn)
    --local v = btn
    --local prograssNameSize = display.getLabelContentSize(v.prograssName)
    --local collectLabelSize = display.getLabelContentSize(v.collectLabel)
    --local contentSize = cc.size(prograssNameSize.width + collectLabelSize.width , collectLabelSize.height)
    --v.prograssNameLayout:setContentSize(contentSize)
    --v.collectLabel:setPosition(0,contentSize.height/2)
    --v.prograssName:setPosition(cc.p(collectLabelSize.width , contentSize.height/2 ))
end
function BossStoryMediator:BackAction()
    display.removeUnusedSpriteFrames()
    AppFacade.GetInstance():BackHomeMediator({showHandbook = true})
end
function BossStoryMediator:OnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
end

function BossStoryMediator:OnUnRegist()
    --self:GetViewComponent():runAction(cc.RemoveSelf:create())
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
    ---@type GameScene


end
return BossStoryMediator
