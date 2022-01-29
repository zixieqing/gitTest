--[[
 * descpt : 新天成演武-入口界面
]]
local VIEW_SIZE = cc.size(1035, 637)
local NewKofArenaEnterView = class('NewKofArenaEnterView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.tagMatchNew.NewKofArenaEnterView'
	node:enableNodeEvents()
	return node
end)

local CreateView         = nil

local RES_DIR = {
    BG                    = _res("ui/home/activity/tagMatchNew/activity_3v3_bg.jpg"),
    TITLE_BG              = _res("ui/home/activity/tagMatchNew/activity_3v3_bg_enemyinfo.png"),
    TIP_BTN               = _res('ui/common/common_btn_tips.png'),
    TITLE                 = _res("ui/home/activity/tagMatchNew/activity_3v3_title.png"),
    MSG_BG                = _res('ui/home/activity/tagMatchNew/activity_3v3_bg_message.png'),
    MSG_ICON              = _res('ui/home/activity/tagMatchNew/activity_3v3_bg_icon.png'),
    RANK_BG               = _res('ui/home/activity/tagMatchNew/activity_3v3_bg_number.png'),
    ICON_SCORE            = _res('ui/home/activity/tagMatchNew/3v3_icon_point.png'),
    ICON_RANK             = _res('ui/home/activity/tagMatchNew/3v3_icon_ranking.png'),
    FIGHT_BTN_BG          = _res("ui/home/activity/tagMatchNew/activity_3v3_bg_fight.png"),
    -- WAIT_BTN              = _res("ui/home/activity/tagMatchNew/activity_3v3_btn_waitting.png"),
    LIGHT_BAR             = _res("ui/home/activity/tagMatchNew/activity_3v3_bg_message_light.png"),
}

local RANK_TAG_RES = {
    [1] = _res('ui/home/activity/tagMatchNew/activity_3v3_ico_up.png'),
    [2] = _res('ui/home/activity/tagMatchNew/activity_3v3_ico_same.png'),
    [3] = _res('ui/home/activity/tagMatchNew/activity_3v3_ico_down.png'),
}

local BUTTON_TAG = {
    RULE        = 100,
    FIGHT       = 101,
}

local IS_FIRST = {
    YES = 1,
    NO  = 0,
}

function NewKofArenaEnterView:ctor( ... )
    self.args = unpack({...})
    self:initialUI()
    self:initData()
end

function NewKofArenaEnterView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        display.commonUIParams(self:getViewData().view, {po = cc.p(0, 0), ap = display.LEFT_BOTTOM})
        self:addChild(self:getViewData().view)
	end, __G__TRACKBACK__)
end

function NewKofArenaEnterView:initData()
    self.initParamConf  = CONF.NEW_KOF.BASE_PARMS:GetAll()
end

function NewKofArenaEnterView:refreshUi(data,segmentConf,sectionAction)
    local status = data.status
    local leftSeconds = checkint(data.leftSeconds)
    local isFisrtEnter = data.first
    local segmentId = data.segmentId 
    local rankPercent = data.rankPercent
    local rank =  data.rank
    local score =  data.score

    --刷新排名与积分
    self:updateRankAndScore(isFisrtEnter, status, rank, score)

    --刷新段位
    self:updateSegmentName(segmentConf.name)
    
    --刷新排名百分比
    self:updateRankPercent(isFisrtEnter, status, rankPercent)

    --刷新升降保
    self:updateSectionAction(isFisrtEnter, segmentId, sectionAction)

    --根据阶段刷新Ui
    self:updateUiByStatus(status, leftSeconds)

    --更新按钮状态
    self:updateBtnState(status)
    
end

--[[
  @params status      阶段
  @params leftSeconds  剩余时间
]]
function NewKofArenaEnterView:updateUiByStatus(status, leftSeconds)
    if status == NEW_MATCH_BATTLE_3V3_TYPE.UNOPEN then
        self:updateCountDown(leftSeconds, __('结算中: '))
    elseif status == NEW_MATCH_BATTLE_3V3_TYPE.OPEN then
        self:updateCountDown(leftSeconds, __('剩余时间:'))
    end
end

--[[
  更新按钮状态 
  @params section      赛季状态     (1-开启, 2-结算)
]]
function NewKofArenaEnterView:updateBtnState(status, isApply)
    local viewData = self:getViewData()
    local isShowFightBtn    = status == NEW_MATCH_BATTLE_3V3_TYPE.OPEN 
    -- local waitImg           = viewData.waitImg
    local fightBtn          = viewData.fightBtn
    -- waitImg:setVisible(false)
    -- fightBtn:setVisible(isShowFightBtn)
    fightBtn:setEnabled(isShowFightBtn)
end

--[[
  更新倒计时 
  @params leftSeconds    剩余时间
]]
function NewKofArenaEnterView:updateCountDown(leftSeconds, timeDesc)
    local viewData          = self:getViewData()
    local baseLayer         = viewData.baseLayer
    if timeDesc then
        baseLayer:setTimeTitleLabel(timeDesc)
    end
    if leftSeconds then
        baseLayer:setTimeLabel(checkint(leftSeconds))
    end
end

--[[
  更新规则
  @params rule    规则
]]
function NewKofArenaEnterView:updateRule(rule)
    local baseLayer = self:getBaseLayer()
    baseLayer:setRule(rule)
end

--更新当前升降保ui
function NewKofArenaEnterView:updateSectionAction(isFirst, segmentId, sectionAction)
    local viewData = self:getViewData()
    local sectionActionIcon  = viewData.changeIcon
    local sectionActionIconBg = viewData.changeIconBg
    local sectionImagePath = ''
    local isVisible = false
    if isFirst == IS_FIRST.NO and sectionAction then
        isVisible = true
        sectionImagePath = RANK_TAG_RES[sectionAction]
    end
    sectionActionIconBg:setVisible(isVisible)
    sectionActionIcon:setTexture(sectionImagePath)
end

--更新排名百分比
function NewKofArenaEnterView:updateRankPercent(isFirst, status, rankPercent)
    local percent = ''
    if isFirst == IS_FIRST.NO then
        if status == NEW_MATCH_BATTLE_3V3_TYPE.UNOPEN then
            percent = __('结算中')
        elseif status == NEW_MATCH_BATTLE_3V3_TYPE.OPEN then
            percent = string.fmt(__('当前排名：_num_%'), {_num_ = checknumber(rankPercent)})
        end
    end
    local viewData = self:getViewData()
    viewData.curRankPercent:setString(percent)
end

--刷新段位名称
function NewKofArenaEnterView:updateSegmentName(name)
    local viewData = self:getViewData()
    viewData.gradeText:setString(tostring(name)) 
end

--刷新排名
function NewKofArenaEnterView:updateRankAndScore(isFirst,status,rank, score)
    local noUseStr = '--'
    local viewData = self:getViewData()
    if  status == NEW_MATCH_BATTLE_3V3_TYPE.UNOPEN then
        rank = noUseStr
        score = noUseStr
    else
        if not rank  then
            rank = noUseStr
        end
        
        score = tostring(checkint(self:getInitScore()) + checkint(score))
    end
    viewData.curRankText:setString(rank)
    viewData.curScoreText:setString(score)
end

CreateView = function ()
    local view = CLayout:create(VIEW_SIZE)
    local actionBtns = {}

    local baseLayer = require("common.CommonBaseActivityView").new({bg = RES_DIR.BG})
    display.commonUIParams(baseLayer, {po = cc.p(0, 0), ap = display.LEFT_BOTTOM})
    view:addChild(baseLayer)
    -------------------------------------
    -- 顶部标题(左上)
    local titleBg = display.newImageView(RES_DIR.TITLE_BG, 3, VIEW_SIZE.height - 60, {ap = display.LEFT_CENTER})
    view:addChild(titleBg)
    local title = display.newImageView(RES_DIR.TITLE, 180, VIEW_SIZE.height - 90, {ap = display.CENTER_BOTTOM})
	view:addChild(title)

    -- 规则
    local ruleBtn = display.newButton(title:getPositionX() + 200, title:getPositionY() + 20, {n = RES_DIR.TIP_BTN, ap = display.CENTER})
    actionBtns[tostring(BUTTON_TAG.RULE)] = ruleBtn
    view:addChild(ruleBtn)
    
    -------------------------------------
    -- 背景框
    local msgBg = display.newImageView(RES_DIR.MSG_BG, 0, VIEW_SIZE.height - 270, {ap = display.LEFT_CENTER})
    local bgSize = msgBg:getContentSize()
    view:addChild(msgBg)

    -- 战斗按钮装饰框（右下）
    local fightBtnBg = display.newImageView(RES_DIR.FIGHT_BTN_BG, VIEW_SIZE.width - 3, 0, {ap = display.RIGHT_BOTTOM})
    view:addChild(fightBtnBg)

    --段位（皇家演武场）
    local gradeText = display.newLabel(bgSize.width/2 - 30, bgSize.height - 63 , {ap = display.CENTER_BOTTOM, fontSize = 30, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#471c21', outlineSize = 1})
    msgBg:addChild(gradeText)

    --升降保
    local changeIconBg =  display.newImageView(RES_DIR.MSG_ICON , 35, bgSize.height - 45, {ap = display.LEFT_CENTER})
    local changeIcon = display.newImageView(RANK_TAG_RES.RANK_TAG_UP , 35, bgSize.height - 45, {ap = display.LEFT_CENTER})
    display.commonUIParams(changeIcon, {po = cc.p(utils.getLocalCenter(changeIconBg).x - 25, 25)})
    msgBg:addChild(changeIconBg)
    changeIconBg:addChild(changeIcon)

    --排名百分比
    local lightBar = display.newImageView(RES_DIR.LIGHT_BAR, 0, bgSize.height - 85, {ap = display.LEFT_CENTER})
    msgBg:addChild(lightBar)
    local barSize = lightBar:getContentSize()
    local params = {ap = display.CENTER, color = "#a37b28", text = __('当前排名: 10%'), fontSize = 20,ttf = true,font = TTF_TEXT_FONT}
    local curRankPercent = display.newLabel(barSize.width/2, barSize.height/2, params)
    lightBar:addChild(curRankPercent)

    --公用UI参数（排名，积分）
    local titleParams = {ap = display.CENTER, fontSize = 22, color = '#873b12', font = TTF_TEXT_FONT, ttf = true}
    local textParams  = {ap = display.CENTER, fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#471c21', outlineSize = 1}
    local upOffset = 20
    local downOffset = 16
    local rankBgX = 50

    --当前排名
    local curRankBg = display.newImageView(RES_DIR.RANK_BG, rankBgX, bgSize.height - 170, {ap = display.LEFT_CENTER})
    msgBg:addChild(curRankBg)
    local rankBgSize = curRankBg:getContentSize()
    local icon = display.newImageView(RES_DIR.ICON_RANK, 0, rankBgSize.height/2, {ap = display.CENTER, scale = 0.5})
    curRankBg:addChild(icon)
    local curRankTitle = display.newLabel(rankBgSize.width/2, rankBgSize.height / 2 + upOffset, titleParams)
    curRankTitle:setString(__('当前名次'))
    curRankBg:addChild(curRankTitle)
    local curRankText = display.newLabel(rankBgSize.width/2, rankBgSize.height / 2 - downOffset, textParams)
    curRankText:setString("1000")
    curRankBg:addChild(curRankText)

    --当前积分
    local curScoreBg = display.newImageView(RES_DIR.RANK_BG, rankBgX, bgSize.height - 260, {ap = display.LEFT_CENTER})
    msgBg:addChild(curScoreBg)
    local rankBgSize = curScoreBg:getContentSize()
    local icon = display.newImageView(RES_DIR.ICON_SCORE, 0, rankBgSize.height/2, {ap = display.CENTER, scale = 0.5})
    curScoreBg:addChild(icon)
    local curScoreTitle = display.newLabel(rankBgSize.width/2, rankBgSize.height / 2 + upOffset, titleParams)
    curScoreTitle:setString(__('当前积分'))
    curScoreBg:addChild(curScoreTitle)
    local curScoreText = display.newLabel(rankBgSize.width/2, rankBgSize.height / 2 - downOffset, textParams)
    curScoreText:setString("1000")
    curScoreBg:addChild(curScoreText)

    --备战中（战斗）
    -- local waitImg = ui.title({n = RES_DIR.WAIT_BTN})
    -- view:addList(waitImg):alignTo(nil, ui.rb, {offsetX = -43, offsetY = 30})

    local fightBtn = require('common.CommonBattleButton').new()
    fightBtn:setPosition(VIEW_SIZE.width - 120, 100)
    view:addChild(fightBtn)
    fightBtn:setVisible(true)
    actionBtns[tostring(BUTTON_TAG.FIGHT)] = fightBtn

    return {
        view           = view,
        baseLayer      = baseLayer,
        gradeText      = gradeText,
        changeIconBg   = changeIconBg,
        changeIcon     = changeIcon,
        curRankPercent = curRankPercent,
        curRankText    = curRankText,
        curScoreText   = curScoreText,
        actionBtns     = actionBtns,
        fightBtn       = fightBtn,
        -- waitImg        = waitImg,
    }
end

function NewKofArenaEnterView:getViewData()
	return self.viewData_
end

function NewKofArenaEnterView:getBaseLayer()
    return self:getViewData().baseLayer
end

--获取初始积分
function NewKofArenaEnterView:getInitScore()
    return self.initParamConf.initIntegral
end

return NewKofArenaEnterView