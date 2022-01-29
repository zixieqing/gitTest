---@class UnionBattlefileReportMediator : Mediator
local UnionBattlefileReportMediator = class('UnionBattlefileReportMediator', mvc.Mediator)
local NAME = "UnionBattlefileReportMediator"
---@type UnionManager
local unionMgr = app.unionMgr
local BUTTON_CLICK = {
    BASE_REPORT    = 1001,  -- 基本的战报
    ATTACK_REPORT   = 1002,  -- 进攻的战报
    DEFENCES_REPORT = 1003   -- 防御的战报
}
function UnionBattlefileReportMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.baseData       = {} -- 基本的数据信息
    self.attackReport   = {}
    self.defendReport   = {}
    self.seasonStartTime = nil  -- 公会战开启时间
    self.seasonEndTime  = nil  -- 公会战结束时间
end


function UnionBattlefileReportMediator:InterestSignals()
    return {
        POST.UNION_WARS_REPORT.sglName
    }
end

function UnionBattlefileReportMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.UNION_WARS_REPORT.sglName then
        local rankStr = self:GetUnionWarRankStr(data.unionWarRank)
        self.attackEnemyUnionName = data.attackEnemyUnionName
        self.defendEnemyUnionName = data.defendEnemyUnionName
        self.attackReport    = data.attackReport
        self.defendReport    = data.defendReport
        self.seasonStartTime = data.seasonStartTime
        self.seasonEndTime   = data.seasonEndTime
        local startTimeStr   = self:GetUnionFormatStr(self.seasonStartTime)
        local endTimeStr     = self:GetUnionFormatStr(self.seasonEndTime)
        --local attackTotalTimes, attackWinTotalTimes   = self:GetAttackTimesAndWinTimes()
        --
        --local defenceTotalTimes, defenceWinTotalTimes = self:GetDefenceTimesAndWinTimes()
        local attackSuccessTimes = checkint(data.attackSuccessTimes)
        local defendSuccessTimes = checkint(data.defendSuccessTimes)
        local attackFailedTimes = checkint(data.attackFailedTimes)
        local defendFailedTimes = checkint(data.defendFailedTimes)
        self.baseData ={
            [1] = {
                title = __('本赛季工会战时间'),
                descr = string.fmt(__('_time1_ ~_time2_'),{ _time1_ = startTimeStr , _time2_ =  endTimeStr})
            },
            [2] = {
                title = __('当前工会总积分'),
                descr = data.unionWarScore or "0"
            },
            [3] = {
                title  = __('当前工会战排名'),
                descr = rankStr
            },
            [4] = {
                title = __('本赛季工会战战绩(进攻)'),
                descr = string.fmt(__('_num1_ 次进攻失败/ _num2_ 次进攻成功'), { _num1_ = attackFailedTimes  , _num2_ = attackSuccessTimes })
            },
            [5] = {
                title = __('本赛季工会战战绩(防守)'),
                descr = string.fmt(__('_num1_ 次防御失败/ _num2_ 次防守成功'), { _num1_ = defendFailedTimes , _num2_ = defendSuccessTimes })
            }
        }
        self:ButtonClick(BUTTON_CLICK.BASE_REPORT)
    end
end
-------------------------------------------------
-- inheritance method

function UnionBattlefileReportMediator:Initial(key)
    self.super.Initial(self, key)
    ---@type UnionBattlefileReportView
    local viewComponent = require('Game.views.unionWars.UnionBattlefileReportView').new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    local viewData = viewComponent.viewData
    for k, btn  in pairs(viewData.buttonTable) do
        --display.commonUIParams(btn , {cb = handler(self, self.ButtonClick)})
        btn:setOnClickScriptHandler(handler(self, self.ButtonClick))
    end
    viewComponent.viewData.eaterLayer:setOnClickScriptHandler(function()
        app:UnRegsitMediator(NAME)
    end)
    -- parse args

end
---==============================--
---@Description: 获取自己公会的名字
--==============================--
function UnionBattlefileReportMediator:GetUnionName()
    local unionHomeData = unionMgr:getUnionData()
    return unionHomeData.name or ""
end

---==============================--
---@Description: 获取进攻自己公会的工会名
--==============================--
function UnionBattlefileReportMediator:GetAtackUnionName()
    return self.defendEnemyUnionName
end

---==============================--
---@Description: 获取被自己公会进攻的工会名
--==============================--
function UnionBattlefileReportMediator:GetDefenceUnionName()
    return self.attackEnemyUnionName
end
--==============================--
---@Description: 获取到当前工会的排名
---@author : xingweihao
---@date : 2019/4/17 3:52 PM
--==============================--

function UnionBattlefileReportMediator:GetUnionWarsRank()
    return 1
end
---==============================--
---@Description: 获取公会战格式化字符串
--==============================--
function UnionBattlefileReportMediator:GetUnionFormatStr(time)
    local timeStr = os.date('%Y-%m-%d %H:%M:%S',time)
    return  timeStr
end
--l10nTimeData
--==============================--
---@Description: 获取到当前工会的积分
---@author : xingweihao
---@date : 2019/4/17 3:52 PM
--==============================--

function UnionBattlefileReportMediator:GetUnionWarsIntergralPoint()
    return 1
end
--==============================--
---@Description: 获取到进攻的总次数和胜利的次数
---@author : xingweihao
---@date : 2019/4/10 9:57 AM
--==============================--

function UnionBattlefileReportMediator:GetAttackTimesAndWinTimes()
    local winTimes = 0
    for i, v in ipairs(self.attackReport) do
        if  checkint(v.isPassed) > 0 then
            winTimes = winTimes + 1
        end
    end
    local totalTimes = #self.attackReport
    return totalTimes , winTimes
end
--==============================--
---@Description: 获取到防御的总次数和胜利的次数
---@author : xingweihao
---@date : 2019/4/10 9:57 AM
--==============================--

function UnionBattlefileReportMediator:GetDefenceTimesAndWinTimes()
    local winTimes = 0
    for i, v in ipairs(self.defendReport) do
        if  checkint(v.isPassed) == 0 then
            winTimes = winTimes + 1
        end
    end
    local totalTimes = #self.defendReport
    return totalTimes , winTimes
end
--==============================--
---@Description: 获取到工会的排名
---@author : xingweihao
---@date : 2019/4/10 10:12 AM
--==============================--

function UnionBattlefileReportMediator:GetUnionWarRankStr(unionWarRank)
    if  checkint(unionWarRank) > 0  then
        return string.fmt(__('第_num_名'  ) ,{ _num_ =  checkint(unionWarRank)})
    end
    return __('暂无排名')
end

function UnionBattlefileReportMediator:ButtonClick(sender)
    local tag = nil
    if type(sender) == 'number'  then
        tag = sender
    else
        PlayAudioByClickNormal()
        tag = sender:getTag()
    end

    ---@type UnionBattlefileReportView
    local viewComponent = self:GetViewComponent()
    if BUTTON_CLICK.BASE_REPORT == tag then
        if viewComponent.attackDefenceViewData and table.nums(viewComponent.attackDefenceViewData) > 0  then

            viewComponent.attackDefenceViewData.attackView:setVisible(false)
        end
        if  not  viewComponent.baseViewData then
            viewComponent:CreateBaseView()
        end
        self:UpdateBaseInfo(tag)
    elseif BUTTON_CLICK.DEFENCES_REPORT == tag or BUTTON_CLICK.ATTACK_REPORT == tag then
        if viewComponent.baseViewData and table.nums(viewComponent.baseViewData) > 0  then
            viewComponent.baseViewData.listView:setVisible(false)
        end
        if  not  viewComponent.attackDefenceViewData then
            viewComponent:CreateAttackAndDefencesView()
        else

        end
        self:UpdateAttackInfo(tag)
    end
    self:SetTabLabelColor(tag)
end
--==============================--
---@Description: 更新基本的信息
---@author : xingweihao
---@date : 2019/4/8 10:29 PM
--==============================--

function UnionBattlefileReportMediator:UpdateBaseInfo(tag)
    self:GetViewComponent():UpdateBaseView(self.baseData)
end
--==============================--
---@Description: 更新基本的信息
---@param tag number 区别更新的进攻还是防御
---@author : xingweihao
---@date : 2019/4/8 10:29 PM
--==============================--

function UnionBattlefileReportMediator:UpdateAttackInfo(tag)
    local dataSource = {}
    local attackUnionName = ""
    local defenceUnionName = ""
    if BUTTON_CLICK.ATTACK_REPORT == tag  then
        for k, v in pairs(self.attackReport) do
            dataSource[#dataSource+1] = {
                isPassed = v.isPassed ,
                unionBattleEndTime = v.unionBattleEndTime ,
                defenseData = {
                    playerId    = v.enemyPlayerId,
                    playerLevel = v.enemyPlayerLevel,
                    playerName  = v.enemyPlayerName,
                    avatar      = v.enemyPlayerAvatar,
                    avatarFrame = v.enemyPlayerAvatarFrame,
                    playerCards = v.enemyPlayerCards,
                },
                attackData = {
                    playerId    = v.unionPlayerId,
                    playerLevel = v.unionPlayerLevel,
                    playerName  = v.unionPlayerName,
                    avatar      = v.unionPlayerAvatar,
                    avatarFrame = v.unionPlayerAvatarFrame,
                    playerCards = v.unionPlayerCards,
                }
            }
        end
        -- 当自己主动进攻的时候 进攻方就是自己的工会
        attackUnionName = self:GetUnionName()
        defenceUnionName = self:GetDefenceUnionName()
    else
        for k, v in pairs(self.defendReport) do
            dataSource[#dataSource+1] = {
                isPassed = v.isPassed ,
                unionBattleEndTime = v.unionBattleEndTime ,
                attackData = {
                    playerId    = v.enemyPlayerId,
                    playerLevel = v.enemyPlayerLevel,
                    playerName  = v.enemyPlayerName,
                    avatar      = v.enemyPlayerAvatar,
                    avatarFrame = v.enemyPlayerAvatarFrame,
                    playerCards = v.enemyPlayerCards,
                },
                defenseData = {
                    playerId    = v.unionPlayerId,
                    playerLevel = v.unionPlayerLevel,
                    playerName  = v.unionPlayerName,
                    avatar      = v.unionPlayerAvatar,
                    avatarFrame = v.unionPlayerAvatarFrame,
                    playerCards = v.unionPlayerCards,
                }
            }
            -- 当自己被动防御的时候防御方就是自己的工会
            defenceUnionName = self:GetUnionName()
            attackUnionName = self:GetAtackUnionName()
        end
    end

    ---@type UnionBattlefileReportView
    local viewComponent = self:GetViewComponent()
    viewComponent:UpdateAttackAnDefenceView(dataSource , attackUnionName ,defenceUnionName)
    dataSource = nil
end

--==============================--
---@Description: 设置侧栏label 切换的颜色
---@author : xingweihao
---@date : 2019/4/8 5:45 PM
--==============================--
function UnionBattlefileReportMediator:SetTabLabelColor(tag)
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    for btnTag, btn  in pairs(viewData.buttonTable) do
        local tabLabel = btn:getChildByTag(111)
        if tag == checkint(btnTag) then
            btn:setChecked(true)
            display.commonLabelParams(tabLabel , fontWithColor(10 ,{text = tabLabel:getString()}))
        else
            btn:setChecked(false)
            display.commonLabelParams(tabLabel , fontWithColor(6 ,{text = tabLabel:getString()}))
        end
    end
end

function UnionBattlefileReportMediator:EnterLayer()
    self:SendSignal(POST.UNION_WARS_REPORT.cmdName, { })
end

function UnionBattlefileReportMediator:OnRegist()
    regPost(POST.UNION_WARS_REPORT)
    self:EnterLayer()
end

function UnionBattlefileReportMediator:OnUnRegist()
    self.defendReport = nil
    self.attackReport = nil
    unregPost(POST.UNION_WARS_REPORT)
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end




return UnionBattlefileReportMediator
