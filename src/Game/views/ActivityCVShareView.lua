--[[
CV分享活动view
--]]
local ActivityCVShareView = class('ActivityCVShareView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.ActivityCVShareView'
    node:enableNodeEvents()
    return node
end)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function ActivityCVShareView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function ActivityCVShareView:InitUI()
    local function CreateView()
        local bgSize = cc.size(1104, 652)
        local view = CLayout:create(bgSize)
        view:enableNodeEvents()
        local bg = display.newImageView(_res('ui/home/activity/cvShare/activity_cv_bg.png'), bgSize.width/2, bgSize.height/2, {enable = true})
        view:addChild(bg)
        local tipsLabel = display.newLabel(24, bgSize.height - 34, {ap = cc.p(0, 0.5), fontSize = 24, color = '#fffffff', text = __('集齐所有插图并分享可获得丰厚奖励')})
        view:addChild(tipsLabel, 10)
        local tipsBtn = display.newButton(432, bgSize.height - 34, {n = _res('ui/common/common_btn_tips')})
        view:addChild(tipsBtn, 10)
        tipsBtn:setVisible(false)
        -- 列表
        local listBg = display.newImageView(_res('ui/home/activity/cvShare/activity_cv_card_bg.png'), bgSize.width/2, 418)
        view:addChild(listBg, 5)
        local gridlistSize = cc.size(1020, 342)
        local gridlistCellSize = cc.size(gridlistSize.width/6, 164)
        local gridView = CGridView:create(gridlistSize)
        gridView:setSizeOfCell(gridlistCellSize)
        gridView:setColumns(6)
        view:addChild(gridView, 10)
        gridView:setPosition(cc.p(bgSize.width/2, 418))

        -- 分享奖励
        local rewardTitle = display.newButton(450, 218, {n = _res('ui/common/common_title_5.png')})
        view:addChild(rewardTitle, 10)
        display.commonLabelParams(rewardTitle, fontWithColor(16, {text = __('分享奖励')}))
        local rewardLayout = CLayout:create(cc.size(784, 200))
        rewardLayout:setAnchorPoint(cc.p(0, 0))
        rewardLayout:setPosition(cc.p(0, 0))
        -- rewardLayout:setBackgroundColor(cc.c4b(100, 100, 100, 100))
        view:addChild(rewardLayout, 10)
        local chestIcon = {'191004', '191005', '191006'}
        local chestDatas = {}
        for i = 1, 3 do
            -- 宝箱
            local chestLayout = CLayout:create(cc.size(200, 200))
            chestLayout:setPosition(cc.p(76, 0))
            chestLayout:setAnchorPoint(cc.p(0.5, 0))
            chestLayout:setVisible(false)
            rewardLayout:addChild(chestLayout)
            local chestIcon = display.newImageView(_res(string.format('arts/goods/goods_icon_%s.png', chestIcon[i])), 140, 60, {ap = cc.p(0.5, 0)})
            chestIcon:setScale(0.8)
            chestIcon:setVisible(false)
            chestLayout:addChild(chestIcon, 10)
            local chestSpine =  sp.SkeletonAnimation:create(
                string.format('effects/xiaobaoxiang/box_%d.json', 13 + i),
                string.format('effects/xiaobaoxiang/box_%d.atlas', 13 + i),
                0.96)
            chestSpine:update(0)
            chestSpine:setToSetupPose()
            chestSpine:setAnimation(0, 'idle', true)
            chestSpine:setPosition(cc.p(140, 112))
            chestLayout:addChild(chestSpine, 10)
            chestLayout:setVisible(false)
            if i == 2 then
                chestSpine:setPositionY(118)
            elseif i == 3 then
                chestIcon:setPositionY(52)
            end
            local collectNum = display.newLabel(140, 34, fontWithColor(16, {text = ''}))
            chestLayout:addChild(collectNum, 10)
            local chestBtn = display.newButton(140, 132, {n = 'empty', size = cc.size(200, 130)})
            chestBtn:setTag(i)
            chestLayout:addChild(chestBtn, 10)
            table.insert(chestDatas, {chestLayout = chestLayout, chestIcon = chestIcon, chestSpine = chestSpine, collectNum = collectNum, chestBtn = chestBtn})
        end
        -- 进度条
        local progressLabel = display.newLabel(60, 72, fontWithColor(16, {text = __('分享进度') ,w = 130 ,hAlign= display.TAC , ap = display.CENTER_BOTTOM}))
        rewardLayout:addChild(progressLabel, 10)
        local progressNums = display.newLabel(58, 48, fontWithColor(16, {text = ''}))
        rewardLayout:addChild(progressNums, 10)
        local progressBar = CProgressBar:create(_res('ui/home/task/task_bar.png'))
        progressBar:setBackgroundImage(_res('ui/home/task/task_bar_bg.png'))
        progressBar:setDirection(eProgressBarDirectionLeftToRight)
        progressBar:setAnchorPoint(cc.p(0, 0.5))
        progressBar:setPosition(cc.p(110, 60))
        progressBar:setScale(0.88)
        rewardLayout:addChild(progressBar, 10)
        local progressBarWidth = 650
        -- 抽奖按钮
        local drawLayoutSize = cc.size(260, 240)
        local drawLayout = CLayout:create(drawLayoutSize)
        drawLayout:setAnchorPoint(cc.p(1, 0))
        drawLayout:setPosition(cc.p(bgSize.width, 0))
        view:addChild(drawLayout, 10)
        local drawBtn = display.newButton(drawLayoutSize.width/2, 130, {n = _res('ui/home/activity/cvShare/activity_cv_btn.png')})
        drawLayout:addChild(drawBtn, 5)
        local btnDrscr = display.newLabel(drawLayoutSize.width/2, 130, {text = __('抽一次'), fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
        drawLayout:addChild(btnDrscr, 10)
        local numLabel = display.newLabel(drawLayoutSize.width/2, 72, {text = '', fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
        drawLayout:addChild(numLabel, 10)
        local recoverRichLabel = display.newRichLabel(drawLayoutSize.width/2, 22)
        drawLayout:addChild(recoverRichLabel, 10)

        return {
            view             = view,
            gridView         = gridView,
            gridlistSize     = gridlistSize,
            gridlistCellSize = gridlistCellSize,
            drawBtn          = drawBtn,
            rewardLayout     = rewardLayout,
            progressNums     = progressNums,
            progressBar      = progressBar,
            chestDatas       = chestDatas,
            progressBarWidth = progressBarWidth,
            numLabel         = numLabel,
            recoverRichLabel = recoverRichLabel,
        }

    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function()
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator("ActivityCVShareMediator")
    end)
    xTry(function ( )
        self.viewData_ = CreateView( )
        self:addChild(self.viewData_.view)
        self.viewData_.view:setPosition(display.center)
    end, __G__TRACKBACK__)
end
return ActivityCVShareView