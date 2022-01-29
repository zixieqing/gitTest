--[[
    新天成演武
    赛季结算界面
--]]
local CommonDialog = require('common.CommonDialog')
local NewKofArenaSeasonResultView = class('NewKofArenaSeasonResultView', CommonDialog)

local RES_DICT = {
    BG_MASK    = _res('ui/common/common_bg_mask_2.png'),
    BG         = _res('ui/tagMatchNew/end/3v3_end_bg.png'),
    BAR        = _res('ui/tagMatchNew/end/3v3_end_bg_reward.png'),
    MARRY_SPN  = _spn('effects/marry/fly'),
    RANK_BG    = _res('ui/home/activity/tagMatchNew/activity_3v3_bg_number.png'),
    ICON_SCORE = _res('ui/home/activity/tagMatchNew/3v3_icon_point.png'),
    ICON_RANK  = _res('ui/home/activity/tagMatchNew/3v3_icon_ranking.png'),
}

local LEVEL_RES = {
    [1] = _res('ui/tagMatchNew/end/3v3_end_bg_up.png'),
    [2] = _res('ui/tagMatchNew/end/3v3_end_bg_same.png'),
    [3] = _res('ui/tagMatchNew/end/3v3_end_bg_down.png'),
}

local LEVEL_STR_FUNC = {
    [1] = function() return __('升级成功') end,
    [2] = function() return __('保级成功') end,
    [3] = function() return __('遭到降级') end,
}

local TITLE_STR_FUNC = {
    [1] = function() return __('升级') end,
    [2] = function() return __('保级') end,
    [3] = function() return __('降级') end,
}


local CreateView = nil

function NewKofArenaSeasonResultView:ctor( ... )
    local args = unpack({...})
    self.ctorArgs_ = args
	self.rewardsDatasConf = CONF.NEW_KOF.REWARDS:GetAll()
    self:initialUI()
end

function NewKofArenaSeasonResultView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self:getViewData().view)
	end, __G__TRACKBACK__)

    local segmentId = self.ctorArgs_.segmentId
    local sectionId = self.ctorArgs_.sectionAction
    local score = self.ctorArgs_.score
    local rank = self.ctorArgs_.rank
    self:setTitleLabel(sectionId)
    self:setSpineEffect(sectionId)
    self:createGoods(segmentId, sectionId)
    self:setScoreAndRank(score, rank)
    self:setColorBg(sectionId)
    ui.bindClick(self.viewData_.bgMask, function(sender)
        self:CloseSelf()
    end, false)
end

CreateView = function()

    local view = display.newLayer()
    
    local layerSize = view:getContentSize()
    -- 遮罩
    local bgMask = ui.image({img = RES_DICT.BG_MASK, p = display.center, enable = true, scale9 = true, size = display.size})
    view:add(bgMask)

    -- 背景
    local bg = ui.image({img = RES_DICT.BG,p = display.center})
    local bgSize = bg:getContentSize()
    view:addChild(bg)
    local bgX,bgY = bg:getPosition()
    local goodsLayer = display.newLayer(bgX - bgSize.width/2 + 100,bgY - bgSize.height/2 + 60,{size = {width = 200, height= 100},ap = cc.p(0.5,0.5)})
    view:addChild(goodsLayer,999)


    local colorbg = ui.image({img = _res('ui/tagMatchNew/end/3v3_end_bg_up.png'),p = display.center,y = layerSize.height/2 + 55})
    local colorbgSize = colorbg:getContentSize()
    view:add(colorbg)

    --公用UI参数（排名，积分）
    local titleParams = {ap = display.CENTER, fontSize = 22, color = '#873b12', font = TTF_TEXT_FONT, ttf = true}
    local textParams  = {ap = display.CENTER, fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#471c21', outlineSize = 1}
    local upOffset = 20
    local downOffset = 16
    local rankBgX = colorbgSize.width/2
    local rankBgY = colorbgSize.height + 120

    --当前排名
    local curRankBg = display.newImageView(RES_DICT.RANK_BG, rankBgX, rankBgY - 170, {ap = display.CENTER})
    colorbg:addChild(curRankBg)
    local rankBgSize = curRankBg:getContentSize()
    local icon = display.newImageView(RES_DICT.ICON_RANK, 0, rankBgSize.height/2, {ap = display.CENTER, scale = 0.5})
    curRankBg:addChild(icon)
    local curRankTitle = display.newLabel(rankBgSize.width/2, rankBgSize.height / 2 + upOffset, titleParams)
    curRankTitle:setString(__('当前名次'))
    curRankBg:addChild(curRankTitle)
    local curRankText = display.newLabel(rankBgSize.width/2, rankBgSize.height / 2 - downOffset, textParams)
    curRankText:setString("1000")
    curRankBg:addChild(curRankText)

    --当前积分
    local curScoreBg = display.newImageView(RES_DICT.RANK_BG, rankBgX, rankBgY - 260, {ap = display.CENTER})
    colorbg:addChild(curScoreBg)
    local rankBgSize = curScoreBg:getContentSize()
    local icon = display.newImageView(RES_DICT.ICON_SCORE, 0, rankBgSize.height/2, {ap = display.CENTER, scale = 0.5})
    curScoreBg:addChild(icon)
    local curScoreTitle = display.newLabel(rankBgSize.width/2, rankBgSize.height / 2 + upOffset, titleParams)
    curScoreTitle:setString(__('当前积分'))
    curScoreBg:addChild(curScoreTitle)
    local curScoreText = display.newLabel(rankBgSize.width/2, rankBgSize.height / 2 - downOffset, textParams)
    curScoreText:setString("1000")
    curScoreBg:addChild(curScoreText)
    
    --标题提示
    local tipsLabel = display.newLabel(bgSize.width/2, bgSize.height - 15,{ap = display.CENTER_TOP, fontSize = 24, color = 'e5caa2'})
    bg:add(tipsLabel)

    --顶部标题
    local params = {ap = display.CENTER_BOTTOM, text = '', fontSize = 45,  font = TTF_GAME_FONT, ttf = true, outlineSize = 2}
    local titleLabel = display.newLabel(bgSize.width/2, bgSize.height + 8,params)
    bg:add(titleLabel,999)

    --奖励一览
    local lookBg = display.newImageView(RES_DICT.BAR, 0, 130, {ap = display.LEFT_CENTER})
    bg:addChild(lookBg)
    local lookTitle = display.newLabel(0, 0,{ap = display.CENTER_TOP, text = __('奖励一览'), fontSize = 22, color = '5123qa'})
    display.commonUIParams(lookTitle, {po = cc.p(utils.getLocalCenter(lookBg).x, utils.getLocalCenter(lookBg).y + 10)})
    lookBg:addChild(lookTitle)

    --邮箱提示
    local mailTitle = display.newLabel(bgSize.width, 55,{ap = display.RIGHT_CENTER, text = __('请前往邮箱领取'), fontSize = 24, color = '#a67860'})
    bg:add(mailTitle)

    return {
        view         = view,
        bgMask       = bgMask,
        tipsLabel    = tipsLabel,
        goodsLayer   = goodsLayer,
        colorbg      = colorbg,
        curScoreText = curScoreText,
        curRankText  = curRankText,
        bg           = bg,
        titleLabel   = titleLabel
    }
end

function NewKofArenaSeasonResultView:createGoods(segmentId,sectionId)
    local viewData = self:getViewData()
    local parent = viewData.goodsLayer
    local goodsData = self:getRewardDataById(segmentId,sectionId)
    local goods = {}
	for i,v in ipairs(goodsData) do
		local goodsIcon = require('common.GoodNode').new({
			id = checkint(v.goodsId),
			amount = checkint(v.num),
			showAmount = true,
            scale = 0.8,
            callBack = function (sender)
				AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
			end
		})
		parent:addChild(goodsIcon, 99)
		table.insert(goods, goodsIcon)
	end
	display.setNodesToNodeOnCenter(parent, goods, {spaceW = 15, y = 50})
end

function NewKofArenaSeasonResultView:setTitleLabel(sectionId)
    local id = checkint(sectionId)
    local segmentName = self:getSegmentNameById(self.ctorArgs_.segmentId)
    local text = self:getTitleText(segmentName, id)
    local viewData = self:getViewData()
    display.commonLabelParams(viewData.tipsLabel,{text = text})
    local color = {'ffea75','fdae7f','e37d7d'}
    local outlinecolor = {'884006','5c2cdc','4a1313'}
    display.commonLabelParams(viewData.titleLabel,{text = TITLE_STR_FUNC[id](),color = color[id], outline = outlinecolor[id]})
end

function NewKofArenaSeasonResultView:setSpineEffect(sectionId)
    local effect = sp.SkeletonAnimation:create(
        'effects/tagMatchNew/3v3_end_light.json',
        'effects/tagMatchNew/3v3_end_light.atlas',
        1
    )
    local viewData = self:getViewData()
    local bg = viewData.bg
    local size = bg:getContentSize()
    bg:addChild(effect, 100)
    effect:setToSetupPose()
    effect:setPosition(cc.p(size.width/2,size.height/2 + 40))
    effect:setAnchorPoint(cc.p(0.5,0))
    local type = "play"..sectionId
    effect:setAnimation(0, type, true)
end

function NewKofArenaSeasonResultView:getTitleText(segmentName, sectionId)
    local strFunc = LEVEL_STR_FUNC[checkint(sectionId)]
	return string.fmt(__('你在【_name_】中_result_'), {_name_ = segmentName, _result_ = strFunc()})
end

function NewKofArenaSeasonResultView:setScoreAndRank(score, rank)
    local viewData = self:getViewData()
    display.commonLabelParams(viewData.curRankText,{text = tostring(rank)})
    display.commonLabelParams(viewData.curScoreText,{text = tostring(score)})
end

function NewKofArenaSeasonResultView:setColorBg(sectionId)
    local viewData = self:getViewData()
    local bgImagePath = LEVEL_RES[checkint(sectionId)]
    viewData.colorbg:setTexture(bgImagePath)
end

function NewKofArenaSeasonResultView:CloseSelf()
    self:removeFromParent()
end

--获取段位名称
function NewKofArenaSeasonResultView:getSegmentNameById(segment)
    self.segmentConf  = CONF.NEW_KOF.SEGMENT:GetAll()
    segment = checkint(segment)
    for k, v in pairs(self.segmentConf) do
        if segment == checkint(v.id) then
           return v.name
        end
    end
end

--获取所属段位的奖励数据
function NewKofArenaSeasonResultView:getRewardDataById(segmentId,sectionId)
    local rewards = {}
	for k, v in pairs(self.rewardsDatasConf) do
		for _, p in pairs(v) do
			if checkint(segmentId) == checkint(p.segmentId) and checkint(sectionId) == checkint(p.section) then
				rewards = p.rewards
			end
		end
	end
    return rewards
end

function NewKofArenaSeasonResultView:getViewData()
    return self.viewData_
end

return NewKofArenaSeasonResultView
