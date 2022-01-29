local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')

local RankRewardPopup = class('RankRewardPopup', function ()
    local clb = CLayout:create(cc.size(display.width, display.height))
    clb.name = 'common.RankRewardPopup'
    clb:enableNodeEvents()
    return clb
end)

function RankRewardPopup:ctor(...)
    self.args = unpack({...})
    self.title = self.args.title or __('赛季成绩')
    self.rankText = self.args.rankText or __('上赛季排名')
    self.scoreText = self.args.scoreText or __('上赛季得分')
    if checkint(self.args.rank) == 0 then
        self.rank = __('排行榜外')
    else
        self.rank = checkint(self.args.rank)
    end
    self.score = checkint(self.args.score) or 0
    self.rewards = checktable(self.args.rewards)
    local function CreateView()
        local bg = display.newImageView(_res('ui/common/common_bg_7.png'), 0, 0)
        local bgSize = bg:getContentSize()
        local view = CLayout:create(bgSize)
        view:addChild(bg)
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
        mask:setAnchorPoint(cc.p(0.5, 0.5))
        mask:setTouchEnabled(true)
        mask:setContentSize(bgSize)
        view:addChild(mask, -1)
        bg:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
        local titleBg = display.newButton(bgSize.width * 0.5, bgSize.height-5, {n = _res('ui/common/common_bg_title_2.png'), enable = false})
        display.commonUIParams(titleBg, {ap = display.CENTER_TOP})
        display.commonLabelParams(titleBg, fontWithColor(1,{fontSize = 24, text = self.title, color = 'ffffff',offset = cc.p(0, -2)}))
        bg:addChild(titleBg, 10)
        -- 排名
        local rankLabel = display.newLabel(bgSize.width/2, 460, fontWithColor(4, {text = self.rankText}))
        view:addChild(rankLabel, 10)
        local rankBg = display.newImageView(_res('ui/common/common_bg_goods_2.png'), bgSize.width/2, 415, {scale9 = true, size = cc.size(268, 46)})
        view:addChild(rankBg, 5)
        if type(self.rank) == 'number' then
            local strs = string.split(string.fmt(__('第|_num_|名'), {['_num_'] = self.rank}), '|')
            local rankNumsLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', strs[2])
            rankNumsLabel:setPosition(cc.p(bgSize.width/2, 415))
            rankNumsLabel:setScale(1.2)
            view:addChild(rankNumsLabel, 10)
            local descrLabelL = display.newLabel(bgSize.width/2 - rankNumsLabel:getContentSize().width/2 - 10, 415, fontWithColor(19, {text = strs[1], ap = cc.p(1, 0.5)}))
            view:addChild(descrLabelL, 10)
            local descrLabelR = display.newLabel(bgSize.width/2 + rankNumsLabel:getContentSize().width/2 + 10, 415, fontWithColor(19, {text = strs[3], ap = cc.p(0, 0.5)}))
            view:addChild(descrLabelR, 10)
        elseif type(self.rank) == 'string' then
            local rankNumsLabel = display.newLabel(bgSize.width/2, 415, fontWithColor(19, {text = self.rank}))
            view:addChild(rankNumsLabel, 10)
        end
        -- 得分
        local scoreLabel = display.newLabel(bgSize.width/2, 356, fontWithColor(4, {text = self.scoreText}))
        view:addChild(scoreLabel, 10)
        local scoreBg = display.newImageView(_res('ui/common/common_bg_goods_2.png'), bgSize.width/2, 311, {scale9 = true, size = cc.size(268, 46)})
        view:addChild(scoreBg, 5)
        local scoreNumsLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', self.score)
        scoreNumsLabel:setPosition(cc.p(bgSize.width/2, 311))
        scoreNumsLabel:setScale(1.2)
        view:addChild(scoreNumsLabel, 10)

        local line = display.newImageView(_res('ui/home/lobby/information/restaurant_info_ico_rank_prize_line.png'), bgSize.width/2, 261)
        view:addChild(line, 10)

        -- 奖励
        local rewardsBg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_season_prize.png'), bgSize.width/2, 160)
        view:addChild(rewardsBg, 5)
        local rewardTitle = display.newButton(bgSize.width/2, 210, {n = _res('ui/common/common_title_5.png')})
        view:addChild(rewardTitle, 10)
        display.commonLabelParams(rewardTitle, fontWithColor(4, {text = __('奖励')}))
        local rewardsLayout = CLayout:create(cc.size(80 + (#self.rewards-1)*100, 90))
        rewardsLayout:setPosition(cc.p(bgSize.width/2, 140))
        view:addChild(rewardsLayout, 10)
        for i,v in ipairs(self.rewards) do
            local goodsIcon = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true})
            goodsIcon:setAnchorPoint(0, 0.5)
            goodsIcon:setScale(0.83)
            goodsIcon:setPosition(cc.p((i-1)*100, 45))
            rewardsLayout:addChild(goodsIcon, 10)
            display.commonUIParams(goodsIcon, {animate = false, cb = function (sender)
                uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
            end})
        end
        -- 确定按钮
        local okBtn = display.newButton(bgSize.width/2, 40, {n = _res('ui/common/common_btn_orange.png')})
        view:addChild(okBtn, 10)
        display.commonLabelParams(okBtn, fontWithColor(14, {text = __('确定')}))

        return {
            view  = view,
            okBtn = okBtn
        }
    end
    local function closeCallback()
        self:runAction(cc.RemoveSelf:create())
    end
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setCascadeOpacityEnabled(true)
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(utils.getLocalCenter(self))
    eaterLayer:setOnClickScriptHandler(closeCallback)
    self:addChild(eaterLayer, -1)

    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)
    display.commonUIParams(self.viewData_.view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
    self.viewData_.okBtn:setOnClickScriptHandler(closeCallback)
end

return RankRewardPopup