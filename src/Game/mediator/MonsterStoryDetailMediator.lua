local Mediator = mvc.Mediator
local MonsterStoryDetailMediator = class("MonsterStoryDetailMediator", Mediator)
local NAME = "MonsterStoryDetailMediator"
---@type  GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type CardManager 
local CardManager = AppFacade.GetInstance():GetManager("CardManager")
local dataMgr =  AppFacade.GetInstance():GetManager("DataManager")  
local BUTTON_TAG = {
    BOSS_STORY = 1001  , -- boss 的故事 
    BOSS_HABIT = 1002  , -- boss 的习性 
    BOSS_SKILL = 1003  , -- boss 的技能 
    BOSS_NEXT  = 1004 ,  -- 下一个boos
    BOSS_LAST  = 1005 ,  -- 上 一个boos
    BOSS_COMMENT  = 1006 ,  -- 上 一个boos
}
local NoObtainBoss = 2
local AlreadyObtainBoss =  3
function MonsterStoryDetailMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    local data = params or {}
    local bossId =   data.id

    self.runSequnece = {} -- 记录执行的动作
    self.monsterInfo = clone(CommonUtils.GetConfigAllMess('monster','collection')[tostring(bossId)]) 
    self.monsterInfo.status = gameMgr:GetUserInfo().monster[tostring(self.monsterInfo.id)]
    self.monsterInfo.storyStatus = (not  CommonUtils.CheckLockCondition( self.monsterInfo.unlockType)) 
    --- 检测是否遇见该堕神

    self.type = checkint(self.monsterInfo.type) 
    -- 查询出怪物的信息
    self.collectionView = {}
    self.preIndex = nil 
end

function MonsterStoryDetailMediator:Initial( key )
	self.super.Initial(self,key)
    local BossStoryDetailView = require("Game.views.BossStoryDetailView")
    local view  = BossStoryDetailView.new(self.monsterInfo)
    local scene = uiMgr:GetCurrentScene()
    view:setPosition(display.center)
    scene:AddDialog(view)
    self:SetViewComponent(view)
    view:UpdateMonsterUI(self.monsterInfo)
    self.viewData = view.viewData
    for k , v in pairs(self.viewData.buttons) do 
        v:setOnClickScriptHandler(handler(self ,self.ButtionAction))
    end 
    self:ButtionAction(self.viewData.buttons[1])
    self.viewData.navBackButton:setOnClickScriptHandler(handler(self,self.BackAction))
    self.viewData.commontBtn:setOnClickScriptHandler(handler(self,self.OtherButtionFunction))
    self.viewData.touchLayer:setOnClickScriptHandler(handler(self, self.CardButtonCallback))
end

--- 创建叙述的Layout
function MonsterStoryDetailMediator:CreateDesrLayout(str , width)
    local strTable = table.split(str, "|") -- 将叙述拆分
    dump(strTable)
    local labelTable = {}
    local ap  = display.CENTER
    for i =1 , #strTable  do
        local label = nil
        if i %2 == 0 then
            ap = display.RIGHT_CENTER
            label= display.newLabel(0, 0,  fontWithColor('14', { text = strTable[i]    ,color = "302015"  , ap = ap , outline = false }))
        else
            ap = display.CENTER
            label= display.newLabel(0, 0,  fontWithColor('14', { text = strTable[i]    , w = width  ,color = "302015"  , ap = ap , outline = false }))
        end

        table.insert(labelTable, #labelTable+1, label)
    end
    local contentSize = cc.size(width, 0)

    local descrLayout =  display.newLayer(0, 0, { size = contentSize , ap = display.LEFT_BOTTOM })
    local po = cc.p(0,0)
    local labelSizeTable = {}
    for i =1 ,  #labelTable do
        local  oneSize = display.getLabelContentSize(labelTable[i])
        contentSize = cc.size(width, oneSize.height + contentSize.height)
        if i %2 == 0 then
            display.commonLabelParams(labelTable[i], fontWithColor(14, { text = strTable[i] ,color = "302015"  , ap = display.RIGHT_CENTER , outline = false }))
        else
            display.commonLabelParams(labelTable[i], fontWithColor(14, { text = strTable[i]  , w = width  ,color = "302015"  , ap = display.CENTER , outline = false }))
        end
        descrLayout:addChild(labelTable[i])
        labelSizeTable[#labelSizeTable+1] = oneSize
    end
    descrLayout:setContentSize(contentSize)
    for i =1 , #labelSizeTable do
        if i %2 == 0 then
            labelTable[i]:setPosition(cc.p(contentSize.width - 20,contentSize.height - labelSizeTable[i].height/2 ))
            contentSize = cc.size(contentSize.width, contentSize.height -labelSizeTable[i].height)
        else
            labelTable[i]:setPosition(cc.p(contentSize.width/2 ,contentSize.height - labelSizeTable[i].height/2 ))
            contentSize = cc.size(contentSize.width, contentSize.height -labelSizeTable[i].height)
        end
    end
    return descrLayout
end
--==============================--
--desc:记录点击事件
--time:2017-07-26 11:29:40
--@sender:
--@return 
--==============================--
function MonsterStoryDetailMediator:ButtionAction(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if tag == self.preIndex then  --点击相同的按钮 就返回
        return 
    end 
    if not  self.collectionView[tostring(tag)] then
        ---@type BossStoryDetailView
        local view =  self:GetViewComponent()

        if tag == BUTTON_TAG.BOSS_STORY then
            self.collectionView[tostring(tag)] = view:CreateStoryView()
            view:addChild( self.collectionView[tostring(tag)].bgLayout)
            view:UpdateStoryView( self.collectionView[tostring(tag)], self.monsterInfo)
        elseif  tag == BUTTON_TAG.BOSS_HABIT then
            self.collectionView[tostring(tag)] = view:CreateHabitView()
            view:addChild( self.collectionView[tostring(tag)].bgLayout)
            local monsterData = gameMgr:GetMonsterData()
            local listSize = self.collectionView[tostring(tag)].habitListView:getContentSize()
            if  checkint(monsterData[tostring(self.monsterInfo.id)])  ~= AlreadyObtainBoss then
                local contentLayer = display.newLayer(0, 0,{  size = listSize })
                self.collectionView[tostring(tag)].habitListView:insertNodeAtLast(contentLayer)
                local decrLabel  = display.newLabel(listSize.width/2,listSize.height/2, fontWithColor('14', { size = listSize , color = "302015" ,text = __('尚未获得该堕神'), w = 400, hAlign =display.TAC ,  outline = false}) )
                contentLayer:addChild(decrLabel)
                self.collectionView[tostring(tag)].habitListView:reloadData()
            else
                local bossId = self.monsterInfo.id
                local isExist = false
                for k , v in pairs(self.monsterInfo.picture) do
                    local filename = v.filename
                    if filename ~= "" then
                        local str = string.format(_res('ui/home/handbook/monsterhabit/%s.png' ),filename)
                        local fileUtils = cc.FileUtils:getInstance()
                        local isFileExist =  fileUtils:isFileExist(str)
                        if isFileExist then
                            isExist = true
                            break
                        end
                    end
                end
                if not  isExist then
                    local contentLayer = display.newLayer(0, 0,{  size = listSize })
                    self.collectionView[tostring(tag)].habitListView:insertNodeAtLast(contentLayer)
                    local decrLabel  = display.newLabel(listSize.width/2,listSize.height/2 , fontWithColor('14', { size = listSize , color = "302015" ,text = __('该图文暂未开放'), outline = false}) )
                    contentLayer:addChild(decrLabel)
                    self.collectionView[tostring(tag)].habitListView:reloadData()
                else
                    for k , v in pairs(self.monsterInfo.picture) do
                        local filename = v.filename
                        if filename ~= "" then
                            local str = string.format(_res('ui/home/handbook/monsterhabit/%s.png' ),filename)
                            local fileUtils = cc.FileUtils:getInstance()
                            local isFileExist =  fileUtils:isFileExist(str)
                            if isFileExist then
                                local monsterImage =  display.newImageView(str)
                                local monsterSize = monsterImage:getContentSize()
                                local monsterSize = cc.size( listSize.width, monsterSize.height)
                                local monsterLayout = display.newLayer(monsterSize.width/2, monsterSize.height/2, {ap = display.CENTER , size = monsterSize   })
                                monsterLayout:addChild(monsterImage)
                                monsterImage:setPosition(cc.p(monsterSize.width/2 , monsterSize.height/2))
                                self.collectionView[tostring(tag)].habitListView:insertNodeAtLast(monsterLayout)
                                --local monsterLabel = display.newLabel(0, 0,  fontWithColor('14', { text = v.descr  , w = listSize.width -20  ,color = "302015"  , ap = display.CENTER , outline = false }))
                                --local monsterLabelsize = display.getLabelContentSize(monsterLabel)
                                --monsterLabel:setPosition(cc.p(monsterLabelsize.width/2 ,monsterLabelsize.height/2))
                                --local monsterLabelLayout = display.newLayer(0, 0  , {size =  monsterLabelsize})
                                --monsterLabelLayout:addChild(monsterLabel)
                                if v.descr and v.descr ~="" then
                                    local  monsterLabelLayout = self:CreateDesrLayout(v.descr ,listSize.width -20  )
                                    self.collectionView[tostring(tag)].habitListView:insertNodeAtLast(monsterLabelLayout)
                                end
                            end
                        end
                    end
                    self.collectionView[tostring(tag)].habitListView:reloadData()
                end
            end

        elseif  tag == BUTTON_TAG.BOSS_SKILL then
            self.collectionView[tostring(tag)] = view:CreateSkillView()
            view:addChild( self.collectionView[tostring(tag)].bgLayout)
            --dump( self.monsterInfo)
            if #self.monsterInfo.attack > 0 then
                for i =1 , #self.monsterInfo.attack do 
                    local cellData =  view:CreateBossSkillCell()
                    view:UpdateeBossSkillCell(cellData, self.monsterInfo.attack[i])
                    self.collectionView[tostring(tag)].skillListView:insertNodeAtLast(cellData.cellLayout)
                    cellData.skillLayout:setTag(checkint(self.monsterInfo.attack[i].actionId) )
                    cellData.skillLayout:setOnClickScriptHandler(handler(self,self.RunActionSpine))

                end 
                self.collectionView[tostring(tag)].skillListView:reloadData()
            end 
        end 
    end 
    self.preIndex = tag 
    self:SetCheckedStatus()
end
--==============================--
--desc:
--time:2017-07-26 04:42:11
--@return 
--==============================--
function MonsterStoryDetailMediator:OtherButtionFunction(sender)

end

function MonsterStoryDetailMediator:CardButtonCallback( sender)
    local obtain = false
    if checkint(gameMgr:GetUserInfo().monster[tostring(self.monsterInfo.id)] ) == 3 then
        obtain = true
    else
        uiMgr:ShowInformationTips(__("尚未获得该堕神"))
        return
    end
	local layer = require('Game.views.CardManualDrawView').new({cardId = self.monsterInfo.id ,obtain = obtain})
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = display.center})
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(layer)
	layer:setClickCallback(function() 
		scene:RemoveDialog(layer)
	end)
	-- 动作
	layer:setOpacity(0)
	layer:runAction(cc.FadeIn:create(0.2))
end
--==============================--
--desc:执行对应的spine动画
--time:2017-07-26 02:08:08
--@sender:
--@return 
--==============================--
function MonsterStoryDetailMediator:RunActionSpine(sender)
    local index = sender:getTag()
    local str = CardManager.ConvertValue2SpineAnimationName(index)
        self.viewData.qAvatar:registerSpineEventHandler(function (event)
            self.viewData.qAvatar:setAnimation(0, 'idle',  true)
		end,sp.EventType.ANIMATION_COMPLETE)
    -- end 
    local qAvatar = self.viewData.qAvatar
    self.viewData.bossImage:setVisible(false)
    self.viewData.qAvatar:setVisible(true)
    qAvatar:setToSetupPose()
    qAvatar:setAnimation(0, str, false)
    self.runSequnece[#self.runSequnece+1] =  str

end
--==============================--
--desc:
--time:2017-07-26 02:37:18
--@return 
--==============================--
function MonsterStoryDetailMediator:BackAction()
    self:GetFacade():UnRegsitMediator('MonsterStoryDetailMediator')
end
--==============================--
--desc:设置点击按钮的状态
--time:2017-07-26 01:23:36
--@return 
--==============================--
function MonsterStoryDetailMediator:SetCheckedStatus()
    if self.preIndex == BUTTON_TAG.BOSS_SKILL then
        self.viewData.bossImage:setVisible(false)
        self.viewData.qAvatar:setVisible(true)
        self.viewData.qAvatar:setToSetupPose()
        self.viewData.qAvatar:setAnimation(0, 'idle',  true)
    else
        if not   self.viewData.bossImage:isVisible() then
            self.viewData.qAvatar:setVisible(false)
            self.viewData.bossImage:setVisible(true)
            --self.viewData.bossImage:setScale(0.2)
            --self.viewData.bossImage:setOpacity(0)
            --self.viewData.bossImage:runAction(cc.Spawn:create(
            --cc.ScaleTo:create(0.2,1) , cc.FadeIn:create(0.2)
            --))
        end
    end

    for k , v  in pairs(self.viewData.buttons) do 
        if v.setChecked then
            if v:getTag() == self.preIndex then
                v:setChecked(true)
                v:setEnabled(false)
                if  self.collectionView[tostring( self.preIndex)] then
                    self.collectionView[tostring( self.preIndex)].bgLayout:setVisible(true)
                end 
            else 
                v:setChecked(false)
                v:setEnabled(true)
                if  self.collectionView[tostring(v:getTag())] then
                    self.collectionView[tostring(v:getTag())].bgLayout:setVisible(false)
                end 
            end 
        end 
    end 
end

function MonsterStoryDetailMediator:OnUnRegist()
    self:GetViewComponent():runAction(cc.RemoveSelf:create())   
end
return MonsterStoryDetailMediator