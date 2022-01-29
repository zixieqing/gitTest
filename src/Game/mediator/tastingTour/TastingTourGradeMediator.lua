--[[
 * descpt : 品鉴之旅 评分 中介者
]]
local NAME = 'TastingTourGradeMediator'
local TastingTourGradeMediator = class(NAME, mvc.Mediator)

local AppFacadeInstance = AppFacade.GetInstance()
local uiMgr    = AppFacadeInstance:GetManager('UIManager')
local gameMgr  = AppFacadeInstance:GetManager("GameManager")
---@type TastingTourManager
local tastingTourMgr = AppFacadeInstance:GetManager("TastingTourManager")

local BUTTON_TAG = {
    hint    = 100, -- 作弊
    rule    = 101, -- 规则
    comment = 102, -- 评论
    next    = 103, -- 继续
}

function TastingTourGradeMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
 
end

-------------------------------------------------
-- inheritance method
function TastingTourGradeMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    
    -- create view
    local viewComponent = require('Game.views.tastingTour.TastingTourGradeView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    -- add layer
    self.ownerScene_ = uiMgr:GetCurrentScene()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:getOwnerScene():AddGameLayer(viewComponent)

    -- init data
    self:initData_()
    -- init view
    self:initView_()
    
end

function TastingTourGradeMediator:initData_()
    
    local data = self:getCtorArgs() or {}
    local score = checkint(data.score)

    -- 获取 食物属性总分数 和 评委心情总分数
    local baseScoreTotleScore = self:getFoodAttrAndMoodTotleScore()
    local starNum        = checkint(data.starNum)
    local questId = data.requestData.questId
    local secretStatus = checkint(tastingTourMgr:GetQuestOneDataByQuestId(questId).secretStatus)
    -- local rewards = data.rewards or {}
    local rewards = data.rewards
    if rewards == nil or next(rewards) == nil then
        -- 根据 questId 取 stageId 
        local questConf = tastingTourMgr:GetQuestConfigDataByQuestId(questId) or {}
        local stageId = questConf.stageId
        local stageConf = tastingTourMgr:GetStageConfByStageId(stageId)
        rewards = stageConf.rewards or {}
    end

    self.datas = {
        questId   = questId ,
        score     = score,        -- 关卡所得评分
        starNum   = starNum,      -- 关卡所得星数
        gradeAttr = {
            [1]   = baseScoreTotleScore,
            [2]   = checkint(data.avatarScore),
            [3]   = data.raterScore or 0,
            [4]   = checkint(data.differScore) * -1,
        },
        secretStatus = secretStatus,          -- 是否使用小本本
        rewards      = rewards
    }
end

function TastingTourGradeMediator:initView_()
    local viewData = self:getViewData()

    local shallowLayer = viewData.shallowLayer
    display.commonUIParams(shallowLayer, {cb = function ( ... )
        self:GetFacade():UnRegsitMediator(NAME)
    end})

    self:GetViewComponent():refreshUi(self.datas)
    
    local actionButtons = viewData.actionButtons
    for tag, button in pairs(actionButtons) do
        button:setTag(tag)
        display.commonUIParams(button, {cb = handler(self, self.onButtonAction)})
    end

end

function TastingTourGradeMediator:CleanupView()
    if self.ownerScene_ and self:getViewData().view:getParent() then
        self.ownerScene_:RemoveDialog(self:GetViewComponent())
        self.ownerScene_ = nil
    end
end


function TastingTourGradeMediator:OnRegist()
    self:enterLayer()
end
function TastingTourGradeMediator:OnUnRegist()
end


function TastingTourGradeMediator:InterestSignals()
    return {
     POST.CUISINE_QUESTSECRET.sglName
    }
end

function TastingTourGradeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    if name == POST.CUISINE_QUESTSECRET.sglName then
        local requestData = body.requestData or {}
        if checkint(self.datas.questId) == checkint(requestData.questId) then
            self:GetViewComponent():UpdateAlreadyBuySercet()
        end
    end
end

-------------------------------------------------
-- get / set

function TastingTourGradeMediator:getCtorArgs()
    return self.ctorArgs_
end

function TastingTourGradeMediator:getViewData()
    return self.viewData_
end

function TastingTourGradeMediator:getOwnerScene()
    return self.ownerScene_
end

-- 获取 食物属性总分数 和 评委心情总分数
function TastingTourGradeMediator:getFoodAttrAndMoodTotleScore()
    local data = self:getCtorArgs() or {}
    local foodsScore = data.foodsScore or {}
    local baseScoreTotleScore = 0
    -- local moodScoreTotleScore = 0
    local foodCount = math.max(table.nums(foodsScore), 1)
    for foodId, scoreData in pairs(foodsScore) do
        local baseScore  = tonumber(scoreData.baseScore)
        local raterScore = tonumber(scoreData.raterScore)
        baseScoreTotleScore = baseScore + baseScoreTotleScore
        -- moodScoreTotleScore = raterScore + moodScoreTotleScore
    end

    return math.floor(baseScoreTotleScore / foodCount)
end

-------------------------------------------------
-- public method
function TastingTourGradeMediator:enterLayer()
    
end

-------------------------------------------------
-- private method

-------------------------------------------------
-- check

-------------------------------------------------
-- handler
function TastingTourGradeMediator:onButtonAction(sender)
    if not self.isControllable_ then return end
    PlayAudioByClickNormal()
    
    local tag = sender:getTag()
    if tag == BUTTON_TAG.hint then
        self:GetFacade():DispatchObservers(SGL.LOOK_CUISINE_SECRET_EVENT , {questId = self.datas.questId})
    elseif tag == BUTTON_TAG.rule then
        --uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.TASTINGTOUR)]})
        local str = __('显示最符合当前题目要求的菜品，购买后永久生效，可反复使用。')
        local tipLabel = display.newLabel(0,0, fontWithColor(6,{text = str , w = 250 , ap = display.CENTER_TOP }))
        local contentSize = display.getLabelContentSize(tipLabel)
        contentSize = cc.size(contentSize.width + 40 , contentSize.height +50)
        tipLabel:setPosition(cc.p(contentSize.width/2 , contentSize.height -10 ))

        local layout = display.newLayer(contentSize.width/2, contentSize.height/2, { size = contentSize ,ap = display.RIGHT_BOTTOM ,color =cc.c4b(0,0,0,0)})
        layout:addChild(tipLabel ,2)
        local image  = display.newImageView( _res('ui/common/common_bg_tips_common'),contentSize.width/2,contentSize.height/2, { scale9 = true , ap =  display.CENTER, size = contentSize})
        layout:addChild(image)
        local tipImage = display.newImageView(_res('ui/common/common_bg_tips_horn') , contentSize.width/10 * 9 ,3  )
        layout:addChild(tipImage)
        tipImage:setScale(-1)
        local pos = cc.p(sender:getPosition())   -- sender:getParent():convertToWorldSpace(cc.p( sender:getPosition()))
        --layout:setPosition(cc.p(pos.x , pos.y + 30))
        local wordPos =  sender:getParent():convertToWorldSpace(pos)
        layout:setName("layout")

        local closeLayer = display.newLayer(display.cx, display.cy , {ap = display.CENTER , color = cc.c4b(0,0,0,0) , enable = true , cb = function(sender)
            sender:runAction(cc.RemoveSelf:create())
        end})
        uiMgr:GetCurrentScene():AddDialog(closeLayer)
        closeLayer:addChild(layout)
        local pos = closeLayer:convertToNodeSpace(wordPos)
        layout:setPosition(cc.p(pos.x + 20, pos.y +30 ) )

    elseif tag == BUTTON_TAG.comment then
        self:GetFacade():DispatchObservers(SGL.SEND_QUEST_COMMENT_EVENT , {})
    elseif tag == BUTTON_TAG.next then
        self:GetFacade():DispatchObservers(SGL.SEND_KEEP_ON_QUEST_EVENT , {})
    end
end


return TastingTourGradeMediator
