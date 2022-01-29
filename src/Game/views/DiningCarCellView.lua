---
--- Created by xingweihao.
--- DateTime: 27/09/2017 3:46 PM
---
---
--- Created by xingweihao.
--- DateTime: 18/08/2017 6:21 PM
---
---@class DiningCarCellView
local DiningCarCellView = class('Game.views.DiningCarCellView', function()
    local pageviewcell = CLayout:create(cc.size(550, 160))
    pageviewcell.name = 'Game.views.DiningCarCellView'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)
local shareFacade = AppFacade.GetInstance()
---@type TakeawayManager
local takeawayInstance = AppFacade.GetInstance():GetManager('TakeawayManager')

---
local DINGING_CAR_STATUS = {
    LOCK_CAR = 1,
    UNLOCK_CAR = 2,
    DELIVERY_CAR = 3,
    REWARD_CAR = 4,
    EXPLORE_DOING = 5, -- 正在探索中
    EXPLORE_DONE = 6, -- 探索已经完成
}
local RES_DICT = {
    LOCK_CAR_BG_IMAGE = _res('ui/home/carexplore/order_bg_lock_door.png'),
    UNLOCK_CAR_BG_IMAGE = _res('ui/home/carexplore/order_bg_rest.png'),
    REWARD_CAR_BG_IMAGE = _res('ui/home/carexplore/order_bg_task_finished_1.png'),
    REWARD_CAR_FORE_IMAGE = _res('ui/home/carexplore/order_bg_task_finished_2.png'),
    TASK_CARD_BG_IMAGE = _res('ui/home/carexplore/order_bg_task_doing_1.png'),
    TASK_CARD_FORE_IMAGE = _res('ui/home/carexplore/order_bg_task_doing_2.png'),
    SHARE_IAMGE = _res('ui/home/carexplore/order_bg_task_working_1.png'),
    LEFTSECOD_TIME = _res('ui/home/carexplore/order_bg_time.png'),
    REST_CAR_IMAGE = _res('ui/home/carexplore/order_ico_countdown_line.png'),
    REWARD_CAR_IMAGE = _res('ui/home/carexplore/order_ico_frame.png'),
    CAR_LEVELBTN = _res('ui/home/carexplore/order_rest_bg_name.png'),
    ORDER_MANAGE_LOCK_IMAGE = _res('ui/home/carexplore/order_manage_bg_lock.png'),
    ORDER_REST =  _res('ui/home/carexplore/car_bg_rest.jpg'),
}
function DiningCarCellView:ctor(...)
    local arg = { ... }
    self.index =  arg[1].index or 1
    self.type = arg[1].type or 1  --- type , 1.外卖车未解锁 2. 外卖车休息中 3. 外卖车配送中 ， 4. 外卖车领取奖励
    self.callback = nil        --回调事件
    self.datas = nil

    self:RefreshAndInitDiningCarView( )
end
--[[
    刷新和初始化外卖车界面
--]]
function DiningCarCellView:RefreshAndInitDiningCarView(type)
    self.type = type or self.type
    local contentSize = cc.size(550, 160)

    local node = self:getChildByName("contentLayer")
    if node and (not tolua.isnull(node)) then
        node:stopAllActions()
        node:runAction(cc.RemoveSelf:create())
    end
    self:stopAllActions()

    local contentLayer = display.newLayer(contentSize.width * 3/ 2, contentSize.height / 2, { size = contentSize , ap = display.CENTER })
    contentLayer:setName("contentLayer")
    contentLayer:runAction(cc.Sequence:create(
        cc.DelayTime:create(0.1+ self.index * 0.05) ,
        cc.MoveTo:create(0.2,cc.p(contentSize.width /2, contentSize.height / 2))
    ))

    self:addChild(contentLayer)
    if self.type == DINGING_CAR_STATUS.LOCK_CAR then
        local bgImage = display.newImageView(RES_DICT.LOCK_CAR_BG_IMAGE, contentSize.width / 2, contentSize.height / 2)
        contentLayer:addChild(bgImage)
        local unLocakBtn = display.newButton(contentSize.width / 2, contentSize.height / 2, { n = RES_DICT.ORDER_MANAGE_LOCK_IMAGE, s = RES_DICT.ORDER_MANAGE_LOCK_IMAGE })
        display.commonLabelParams(unLocakBtn, fontWithColor('9', { text = __("点击解锁"), offset = cc.p(0, -50) }))

        -- 需要的金钱的数量

        local needGold = cc.Label:createWithBMFont('font/common_num_1.fnt', "")
        needGold:setAnchorPoint(display.LEFT_CENTER)
        needGold:setString("2133sdd3")
        local needGoldSize = needGold:getContentSize()
        local unLocakBtnSize = unLocakBtn:getContentSize()
        local iconPath = CommonUtils.GetGoodsIconPathById(GOLD_ID)
        -- 金币的图标
        local goldImage = display.newImageView(iconPath, unLocakBtnSize.width - 20, 40 )
        goldImage:setAnchorPoint(display.LEFT_CENTER)
        goldImage:setScale(0.3)
        needGold:setPosition(cc.p(0, needGoldSize.height / 2 ))
        -- 金币和图标的集中适配
        local goldSize = goldImage:getContentSize()
        goldSize = cc.size(goldSize.width * 0.3, goldSize.height * 0.3)
        local goldLayoutSize = cc.size(needGoldSize.width + goldSize.width, needGoldSize.height)
        local goldLayout = display.newLayer(unLocakBtnSize.width / 2, 40, { ap = display.CENTER, size = goldLayoutSize })
        goldLayout:addChild(needGold)
        goldLayout:addChild(goldImage)
        goldImage:setPosition(cc.p(needGoldSize.width, needGoldSize.height / 2))
        unLocakBtn:addChild(goldLayout)
        contentLayer:addChild(unLocakBtn)
        self.viewData = {
            contentLayer = contentLayer,
            unLocakBtn = unLocakBtn,
            needGold = needGold,
            goldImage = goldImage,
            goldLayout = goldLayout,

        }
    elseif self.type == DINGING_CAR_STATUS.UNLOCK_CAR then
        -- 背景图片
        local bgImage = display.newImageView(RES_DICT.UNLOCK_CAR_BG_IMAGE)
        local bgSize = bgImage:getContentSize()
        bgImage:setPosition(cc.p(bgSize.width / 2, bgSize.height / 2))
        local bgLayout = display.newLayer(contentSize.width / 2, contentSize.height / 2, { ap = display.CENTER, size = bgSize })
        bgLayout:addChild(bgImage, 2)
        contentLayer:addChild(bgLayout, 2)

        local clipSize = cc.size(520, 100)
        -- 中间的截图
        local clipLayout = display.newLayer(bgSize.width / 2, 10 + clipSize.height / 2, { ap = display.CENTER, size = clipSize })

        local clippingNode = cc.ClippingNode:create()
        local noticeImage = display.newImageView(RES_DICT.ORDER_REST)
        noticeImage:setPosition(cc.p(clipSize.width / 2, clipSize.height / 2))
        clippingNode:setAnchorPoint(cc.p(0.5, 0.5))
        clippingNode:setContentSize( cc.size(clipSize.width, clipSize.height))
        clippingNode:addChild(noticeImage)
        clippingNode:setPosition(cc.p(clipSize.width / 2, clipSize.height / 2))
        local stencilNode = display.newLayer(clipSize.width / 2, clipSize.height / 2, { ap = display.CENTER, size = clipSize, color = "#000000" })
        clippingNode:setStencil(stencilNode)
        clippingNode:setAlphaThreshold(1)
        clippingNode:setInverted(false)
        clipLayout:addChild(clippingNode)
        --- 等级的button
        local levelBtn = display.newButton(0, clipSize.height / 2, { ap = display.LEFT_CENTER, n = RES_DICT.CAR_LEVELBTN, enable = false })
        levelBtn:getLabel():setAnchorPoint(display.LEFT_CENTER)
        levelBtn:getLabel():setPositionX(25)
        display.commonLabelParams(levelBtn, fontWithColor('6', { color = "ffffff", text = "text", offset = cc.p(-20, 0) }))
        clipLayout:addChild(levelBtn)

        -- 阴影
        local shardow = display.newImageView(_res('ui/common/common_bg_btn_shardow.png'), clipSize.width - 80, clipSize.height / 2  )
        clipLayout:addChild(shardow, 2)
        -- 查看外卖车的信息
        local infoBtn = display.newButton(clipSize.width - 80, clipSize.height / 2, { n = _res('ui/common/common_btn_white_default.png'), s = _res('ui/common/common_btn_white_default.png') } )
        display.commonLabelParams(infoBtn, fontWithColor('14', { text = __('信息') }) )
        clipLayout:addChild(infoBtn, 2)
        bgLayout:addChild(clipLayout)

        -- 外卖车在休息中
        local carStatusLabel = display.newLabel(bgSize.width / 2, bgSize.height - 30, fontWithColor('5', { fontSize = 24, color = "#2b2017", text = __('停歇中...') }) )
        bgLayout:addChild(carStatusLabel,5)
        local spnPath = _spn(HOME_THEME_STYLE_DEFINE.LONGXIA_SPINE or 'ui/home/takeaway/longxiache')
        local qAvatar = sp.SkeletonAnimation:create(spnPath.json, spnPath.atlas, 1.0)
        qAvatar:setPosition(cc.p(clipSize.width / 2 - 40, clipSize.height / 2 - 40))
        clipLayout:addChild(qAvatar, 5)
        qAvatar:setToSetupPose()
        qAvatar:setAnimation(0, 'idle', true)
        --qAvatar:setTimeScale(0)
        qAvatar:setScaleX(-0.8)
        qAvatar:setScaleY(0.8)
        local foreBgImage = display.newImageView(RES_DICT.TASK_CARD_BG_IMAGE, bgSize.width / 2, bgSize.height / 2)
        bgLayout:addChild(foreBgImage, 4)
        self.viewData = {
            levelBtn = levelBtn,
            infoBtn = infoBtn
        }
    elseif self.type == DINGING_CAR_STATUS.DELIVERY_CAR then
        local bgImage = display.newImageView(RES_DICT.TASK_CARD_BG_IMAGE)
        local bgSize = bgImage:getContentSize()
        bgImage:setPosition(cc.p(bgSize.width / 2, bgSize.height / 2))
        local bgLayout = display.newLayer(contentSize.width / 2, contentSize.height / 2, { ap = display.CENTER, size = bgSize })
        bgLayout:addChild(bgImage)
        -- 查看订单和探索的属性
        local enterBtn = display.newLayer(contentSize.width/2 , contentSize.height/2 , { ap = display.CENTER , color = cc.c4b(0,0,0,0) ,enable = true})
        contentLayer:addChild(enterBtn,10)
        local foreBgImage = display.newImageView(RES_DICT.TASK_CARD_FORE_IMAGE, bgSize.width / 2, bgSize.height / 2)
        bgLayout:addChild(foreBgImage, 2)
        contentLayer:addChild(bgLayout, 2)
        local clipSize = cc.size(372, 102)
        -- 中间的截图
        local clipLayout = display.newLayer(10, clipSize.height / 2 + 5, { ap = display.LEFT_CENTER, size = clipSize })

        local clippingNode = cc.ClippingNode:create()
        local noticeImage = display.newImageView(RES_DICT.LOCK_CAR_BG_IMAGE)
        noticeImage:setPosition(cc.p(clipSize.width / 2, clipSize.height / 2))
        clippingNode:setAnchorPoint(cc.p(0.5, 0.5))
        clippingNode:setContentSize( cc.size(clipSize.width, clipSize.height))
        clippingNode:addChild(noticeImage)
        clippingNode:setPosition(cc.p(clipSize.width / 2, clipSize.height / 2))
        local stencilNode = display.newLayer(clipSize.width / 2, clipSize.height / 2, { ap = display.CENTER, size = clipSize, color = "#000000" })
        clippingNode:setStencil(stencilNode)
        clippingNode:setAlphaThreshold(1)
        clippingNode:setInverted(false)
        clipLayout:addChild(clippingNode)
        local frameImage = display.newImageView(RES_DICT.REWARD_CAR_IMAGE, clipSize.width / 2, clipSize.height / 2 )
        clipLayout:addChild(frameImage, 3)
        bgLayout:addChild(clipLayout)
        -- 编队信息
        local teamLabel = display.newLabel(20, bgSize.height - 20, fontWithColor('5', { fontSize = 24, color = "#2b2017", text = __('停歇中..'), ap = display.LEFT_CENTER }) )
        bgLayout:addChild(teamLabel, 3)

        -- 编队信息
        local teamStatusLabel = display.newLabel(150, bgSize.height - 20, fontWithColor('5', { text = 'xxxxxxxc', ap = display.LEFT_CENTER }) )
        bgLayout:addChild(teamStatusLabel, 2)

        --待机时刻的layout
        local coutDownSize = cc.size(156, 120)
        local coutDownLayout = display.newLayer(bgSize.width, 0, { size = coutDownSize, ap = display.RIGHT_BOTTOM })
        bgLayout:addChild(coutDownLayout, 3)
        -- 剩余时间
        local remainingLabel = display.newLabel(coutDownSize.width / 2, coutDownSize.height / 2 + 15, fontWithColor('6', { text = __('剩余时间') }))
        coutDownLayout:addChild(remainingLabel)
        --倒计时按钮
        local leftSecondBtn = display.newButton(coutDownSize.width / 2, coutDownSize.height / 2 - 15, { n = RES_DICT.LEFTSECOD_TIME, s = RES_DICT.LEFTSECOD_TIME, d = RES_DICT.LEFTSECOD_TIME, enable = false })
        coutDownLayout:addChild(leftSecondBtn)
        display.commonLabelParams(leftSecondBtn, fontWithColor('14', { text = "231332" }) )

        local spnPath = _spn(HOME_THEME_STYLE_DEFINE.WAIMAI_SPINE or 'ui/home/carexplore/waimai')
        local qAvatar = sp.SkeletonAnimation:create(spnPath.json, spnPath.atlas, 1.0)
        qAvatar:setPosition(cc.p(clipSize.width / 2, clipSize.height / 2 - 40))
        clipLayout:addChild(qAvatar, 5)
        qAvatar:setToSetupPose()
        qAvatar:setAnimation(0, 'idle', true)

        local robberyAvatar = sp.SkeletonAnimation:create("ui/home/carexplore/rob_ico_human.json", "ui/home/carexplore/rob_ico_human.atlas", 1.0)
        robberyAvatar:setPosition(cc.p(0, 0))
        robberyAvatar:setAnchorPoint(display.LEFT_BOTTOM)
        clipLayout:addChild(robberyAvatar, 5)
        robberyAvatar:setToSetupPose()
        robberyAvatar:setAnimation(0, 'idle', true)
        robberyAvatar:setVisible(false)
        local foreBgImage = display.newImageView(RES_DICT.SHARE_IAMGE, bgSize.width / 2, bgSize.height / 2)
        bgLayout:addChild(foreBgImage, 4)
        --qAvatar:setTimeScale(0)
        self.viewData = {
            qAvatar = qAvatar,
            enterBtn = enterBtn ,
            remainingLabel = remainingLabel,
            leftSecondBtn = leftSecondBtn,
            noticeImage = noticeImage,
            teamLabel = teamLabel ,
            teamStatusLabel = teamStatusLabel ,
            robberyAvatar = robberyAvatar
        }
    elseif self.type == DINGING_CAR_STATUS.REWARD_CAR then
        local bgImage = display.newImageView(RES_DICT.REWARD_CAR_BG_IMAGE)
        local bgSize = bgImage:getContentSize()
        bgImage:setPosition(cc.p(bgSize.width / 2, bgSize.height / 2))
        local bgLayout = display.newLayer(contentSize.width / 2, contentSize.height / 2, { ap = display.CENTER, size = bgSize })
        bgLayout:addChild(bgImage)
        local foreBgImage = display.newImageView(RES_DICT.REWARD_CAR_FORE_IMAGE, bgSize.width / 2, bgSize.height / 2)
        bgLayout:addChild(foreBgImage, 2)
        contentLayer:addChild(bgLayout, 2)
        local clipSize = cc.size(372, 102)
        -- 中间的截图
        local clipLayout = display.newLayer(15, clipSize.height / 2 + 10, { ap = display.LEFT_CENTER, size = clipSize })

        local clippingNode = cc.ClippingNode:create()
        local noticeImage = display.newImageView(RES_DICT.LOCK_CAR_BG_IMAGE)
        noticeImage:setPosition(cc.p(clipSize.width / 2, clipSize.height / 2))
        clippingNode:setAnchorPoint(cc.p(0.5, 0.5))
        clippingNode:setContentSize( cc.size(clipSize.width, clipSize.height))
        clippingNode:addChild(noticeImage)
        clippingNode:setPosition(cc.p(clipSize.width / 2, clipSize.height / 2))
        local stencilNode = display.newLayer(clipSize.width / 2, clipSize.height / 2, { ap = display.CENTER, size = clipSize, color = "#000000" })
        clippingNode:setStencil(stencilNode)
        clippingNode:setAlphaThreshold(1)
        clippingNode:setInverted(false)
        clipLayout:addChild(clippingNode)
        local frameImage = display.newImageView(RES_DICT.REWARD_CAR_IMAGE, clipSize.width / 2, clipSize.height / 2 )
        clipLayout:addChild(frameImage, 3)
        bgLayout:addChild(clipLayout)

        local teamLabel = display.newLabel(20, bgSize.height - 30, fontWithColor('5', { fontSize = 24, color = "#2b2017", text = __('停歇中..'), ap = display.LEFT_CENTER }) )
        bgLayout:addChild(teamLabel, 20)

        -- 编队信息
        local teamStatusLabel = display.newLabel(150, bgSize.height - 30, fontWithColor('5', { text = 'xxxxxxxc', ap = display.LEFT_CENTER }) )
        bgLayout:addChild(teamStatusLabel, 2)

        --倒计时按钮
        local infoBtn = display.newButton(bgSize.width - 80, 60, { n = _res('ui/common/common_btn_orange.png'), enable = true })
        bgLayout:addChild(infoBtn, 4)
        display.commonLabelParams(infoBtn, fontWithColor('14', { text = __('查看') }) )

        local qAvatar = sp.SkeletonAnimation:create("ui/home/takeaway/baoxiang.json","ui/home/takeaway/baoxiang.atlas", 0.62)
        qAvatar:setPosition(cc.p(clipSize.width / 2, clipSize.height / 2 - 40))
        clipLayout:addChild(qAvatar, 5)
        qAvatar:setAnimation(0, 'baoxiang2', true)
        local robberyAvatar = sp.SkeletonAnimation:create("ui/home/carexplore/rob_ico_human.json", "ui/home/carexplore/rob_ico_human.atlas", 1.0)
        robberyAvatar:setPosition(cc.p(0, 0))
        robberyAvatar:setAnchorPoint(display.LEFT_BOTTOM)
        clipLayout:addChild(robberyAvatar, 5)
        robberyAvatar:setToSetupPose()
        robberyAvatar:setAnimation(0, 'idle', true)
        robberyAvatar:setVisible(false)
        local foreBgImage = display.newImageView(RES_DICT.SHARE_IAMGE, bgSize.width / 2, bgSize.height / 2)
        bgLayout:addChild(foreBgImage, 4)
        self.viewData = {
            qAvatar = qAvatar,
            teamLabel = teamLabel,
            teamStatusLabel = teamStatusLabel,
            infoBtn = infoBtn,
            noticeImage = noticeImage,
            robberyAvatar = robberyAvatar
        }
    elseif self.type == DINGING_CAR_STATUS.EXPLORE_DOING then
        local bgImage = display.newImageView(RES_DICT.TASK_CARD_BG_IMAGE)
        local bgSize = bgImage:getContentSize()
        bgImage:setPosition(cc.p(bgSize.width / 2, bgSize.height / 2))
        local bgLayout = display.newLayer(contentSize.width / 2, contentSize.height / 2, { ap = display.CENTER, size = bgSize })
        bgLayout:addChild(bgImage)

        local foreBgImage = display.newImageView(RES_DICT.TASK_CARD_FORE_IMAGE, bgSize.width / 2, bgSize.height / 2)
        bgLayout:addChild(foreBgImage, 2)
        contentLayer:addChild(bgLayout, 2)
        local enterBtn = display.newLayer(contentSize.width/2 , contentSize.height/2 , { ap = display.CENTER , color = cc.c4b(0,0,0,0) ,enable = true})
        contentLayer:addChild(enterBtn,100)
        local clipSize = cc.size(372, 102)
        -- 中间的截图
        local clipLayout = display.newLayer(10, clipSize.height / 2 + 5, { ap = display.LEFT_CENTER, size = clipSize })

        local clippingNode = cc.ClippingNode:create()
        local noticeImage = display.newImageView(RES_DICT.LOCK_CAR_BG_IMAGE)
        noticeImage:setPosition(cc.p(clipSize.width / 2, clipSize.height / 2))
        clippingNode:setAnchorPoint(cc.p(0.5, 0.5))
        clippingNode:setContentSize( cc.size(clipSize.width, clipSize.height))
        clippingNode:addChild(noticeImage)
        clippingNode:setPosition(cc.p(clipSize.width / 2, clipSize.height / 2))
        local stencilNode = display.newLayer(clipSize.width / 2, clipSize.height / 2, { ap = display.CENTER, size = clipSize, color = "#000000" })
        clippingNode:setStencil(stencilNode)
        clippingNode:setAlphaThreshold(1)
        clippingNode:setInverted(false)
        clipLayout:addChild(clippingNode)
        local exploreLabel = display.newLabel(clipSize.width/2 + 40 , clipSize.height/2 , fontWithColor('14' , { text = __('探索中...') ,color = "#ffda82"  ,w  = 140, ap = display.LEFT_CENTER}))
        clippingNode:addChild(exploreLabel)
        local frameImage = display.newImageView(RES_DICT.REWARD_CAR_IMAGE, clipSize.width / 2, clipSize.height / 2 )
        clipLayout:addChild(frameImage, 3)
        bgLayout:addChild(clipLayout)
        -- 编队信息
        local teamLabel = display.newLabel(15, bgSize.height - 20, fontWithColor('5', { fontSize = 24, color = "#2b2017", text = 'cxxxxxxxx', ap = display.LEFT_CENTER }) )
        bgLayout:addChild(teamLabel, 3)

        -- 编队信息
        local teamStatusLabel = display.newLabel(150, bgSize.height - 20, fontWithColor('5', { text = 'xxxxxxxc', ap = display.LEFT_CENTER }) )
        bgLayout:addChild(teamStatusLabel, 2)

        --待机时刻的layout
        local coutDownSize = cc.size(156, 120)
        local coutDownLayout = display.newLayer(bgSize.width, 0, { size = coutDownSize, ap = display.RIGHT_BOTTOM })
        bgLayout:addChild(coutDownLayout, 3)
        -- 剩余时间
        local remainingLabel = display.newLabel(coutDownSize.width / 2, coutDownSize.height / 2 + 15, fontWithColor('6', { text = __('剩余时间') }))
        coutDownLayout:addChild(remainingLabel)
        --倒计时按钮
        local leftSecondBtn = display.newButton(coutDownSize.width / 2, coutDownSize.height / 2 - 15, { n = RES_DICT.LEFTSECOD_TIME, s = RES_DICT.LEFTSECOD_TIME, d = RES_DICT.LEFTSECOD_TIME, enable = false })
        coutDownLayout:addChild(leftSecondBtn)
        display.commonLabelParams(leftSecondBtn, fontWithColor('14', { text = "231332" }) )

        local qAvatar = sp.SkeletonAnimation:create("ui/home/carexplore/tansuo.json", "ui/home/carexplore/tansuo.atlas", 1.0)
        qAvatar:setPosition(cc.p(clipSize.width / 2, clipSize.height / 2 - 40))
        clipLayout:addChild(qAvatar, 5)
        qAvatar:setToSetupPose()
        qAvatar:setAnimation(0, 'idle', true)
        local foreBgImage = display.newImageView(RES_DICT.SHARE_IAMGE, bgSize.width / 2, bgSize.height / 2)
        bgLayout:addChild(foreBgImage, 4)
        --qAvatar:setTimeScale(0)
        self.viewData = {
            qAvatar = qAvatar,
            enterBtn = enterBtn ,
            teamLabel = teamLabel,
            teamStatusLabel = teamStatusLabel,
            remainingLabel = remainingLabel,
            leftSecondBtn = leftSecondBtn,
            noticeImage = noticeImage,
        }
    elseif self.type == DINGING_CAR_STATUS.EXPLORE_DONE then
        local bgImage = display.newImageView(RES_DICT.REWARD_CAR_BG_IMAGE)
        local bgSize = bgImage:getContentSize()
        bgImage:setPosition(cc.p(bgSize.width / 2, bgSize.height / 2))
        local bgLayout = display.newLayer(contentSize.width / 2, contentSize.height / 2, { ap = display.CENTER, size = bgSize })
        bgLayout:addChild(bgImage)
        local foreBgImage = display.newImageView(RES_DICT.REWARD_CAR_FORE_IMAGE, bgSize.width / 2, bgSize.height / 2)
        bgLayout:addChild(foreBgImage, 2)
        contentLayer:addChild(bgLayout, 2)
        local clipSize = cc.size(372, 102)
        -- 中间的截图
        local clipLayout = display.newLayer(15, clipSize.height / 2 + 10, { ap = display.LEFT_CENTER, size = clipSize })

        local clippingNode = cc.ClippingNode:create()
        local noticeImage = display.newImageView(RES_DICT.LOCK_CAR_BG_IMAGE)

        noticeImage:setPosition(cc.p(clipSize.width / 2, clipSize.height / 2))
        clippingNode:setAnchorPoint(cc.p(0.5, 0.5))
        clippingNode:setContentSize( cc.size(clipSize.width, clipSize.height))
        clippingNode:addChild(noticeImage)
        clippingNode:setPosition(cc.p(clipSize.width / 2, clipSize.height / 2))
        local stencilNode = display.newLayer(clipSize.width / 2, clipSize.height / 2, { ap = display.CENTER, size = clipSize, color = "#000000" })
        clippingNode:setStencil(stencilNode)
        clippingNode:setAlphaThreshold(1)
        clippingNode:setInverted(false)
        clipLayout:addChild(clippingNode)
        local frameImage = display.newImageView(RES_DICT.REWARD_CAR_IMAGE, clipSize.width / 2, clipSize.height / 2 )
        clipLayout:addChild(frameImage, 3)
        bgLayout:addChild(clipLayout)

        local teamLabel = display.newLabel(20, bgSize.height - 30, fontWithColor('5', { fontSize = 24, color = "#2b2017", text = __('停歇中...'), ap = display.LEFT_CENTER }) )
        bgLayout:addChild(teamLabel, 3)

        -- 编队信息
        local teamStatusLabel = display.newLabel(150, bgSize.height - 30, fontWithColor('5', { text = 'xxxxxxxc', ap = display.LEFT_CENTER }) )
        bgLayout:addChild(teamStatusLabel, 2)

        --倒计时按钮
        local infoBtn = display.newButton(bgSize.width - 80, 60, { n = _res('ui/common/common_btn_orange.png'), enable = true })
        bgLayout:addChild(infoBtn, 4)
        display.commonLabelParams(infoBtn, fontWithColor('14', { text = __('查看') }) )

        local qAvatar = sp.SkeletonAnimation:create("ui/home/carexplore/tansuo.json", "ui/home/carexplore/tansuo.atlas", 1.0)
        qAvatar:setPosition(cc.p(clipSize.width / 2, clipSize.height / 2 - 40))
        clipLayout:addChild(qAvatar, 5)
        qAvatar:setToSetupPose()
        qAvatar:setAnimation(0, 'bones', true)
        local foreBgImage = display.newImageView(RES_DICT.SHARE_IAMGE, bgSize.width / 2, bgSize.height / 2)
        bgLayout:addChild(foreBgImage, 4)

        self.viewData = {
            qAvatar = qAvatar,
            teamLabel = teamLabel,
            teamStatusLabel = teamStatusLabel,
            infoBtn = infoBtn,
            noticeImage = noticeImage,
        }
    end
end

--[[
    -- 刷新UI的界面
    local data = {
        callback  = function , -- 回调按钮 ,外卖车的升级, 外卖车的解锁
        Name = "TakeAway_1" -- 这个是用来识别当前的CELl
        areaId = 1
    }
--]]
function DiningCarCellView:RefreshCellUI(data)
    data = data or {}
    self.datas = data
    if self.type == DINGING_CAR_STATUS.LOCK_CAR then
        -- 解锁
        if data.Name then
            self.viewData.unLocakBtn:setName(data.Name)
            self:setName(data.Name)
            local x, y  = string.find(data.Name, "%d+")
            if x and y then
                local carId = checkint(string.sub(data.Name,x,y))

                local carConfig = CommonUtils.GetConfigAllMess('diningCar','takeaway')
                if carConfig[tostring(carId)] then
                    local types = carConfig[tostring(carId)].unlockType
                    local goods = {}
                    for k,v in pairs(types) do
                        if checkint(k) == UnlockTypes.GOLD then
                            table.insert( goods,{goodsId = GOLD_ID, num = checkint(v.targetNum)} )
                        elseif checkint(k) == UnlockTypes.DIAMOND then
                            table.insert( goods,{goodsId = DIAMOND_ID, num = checkint(v.targetNum)} )
                        elseif checkint(k) == UnlockTypes.GOODS then
                            table.insert( goods,{goodsId = checkint(v.targetId), num = checkint(v.targetNum)} )
                        end
                    end
                    local iconPath = ""
                    if table.nums(goods) >= 1 then  -- 首先是goods
                        self.viewData.needGold:setString(tostring(goods[1].num) )
                        iconPath = CommonUtils.GetGoodsIconPathById(goods[1].goodsId)
                        self.viewData.goldImage:setTexture(iconPath)
                        local needSize = self.viewData.needGold:getContentSize()
                        local goldSize = self.viewData.goldImage:getContentSize()
                        goldSize = cc.size(goldSize.width * 0.3 , goldSize.height * 0.3 )
                        local goldLayoutSize = cc.size(goldSize.width + needSize.width , needSize.height)
                        self.viewData.goldLayout:setContentSize(goldLayoutSize)
                        self.viewData.needGold:setPosition(cc.p(0, needSize.height/2))
                        self.viewData.goldImage:setPosition(cc.p(needSize.width , needSize.height/2))
                    end
                end
            end
        end
        if data.callback then -- 存在回调事件
            self.callback = data.callback
            self.viewData.unLocakBtn:setOnClickScriptHandler(data.callback)
        end
    elseif self.type == DINGING_CAR_STATUS.UNLOCK_CAR then
        -- 升级按钮
        if data.Name then  -- 传输的标志
            self:setName(data.Name)
            local diningCar = takeawayInstance:GetDatas().diningCar
            local x, y  = string.find(data.Name, "%d+")
            if x and y then
                local cardId = checkint(string.sub(data.Name,x,y))

                local level = nil
                for k , v in pairs(diningCar) do
                    if  checkint(v.diningCarId ) == cardId then
                        level = v.level
                    end
                end

                if  not  level then
                    return
                end

                -- 设置菜车的等级
                display.commonLabelParams(self.viewData.levelBtn, {text = string.format(__('%d级'), level)})
                self.viewData.infoBtn:setName(data.Name)
                -- 判断升级材料是否充足
            end
            if data.callback then -- 存在回调事件
                self.callback = data.callback
                self.viewData.infoBtn:setOnClickScriptHandler(data.callback)
                self.viewData.infoBtn:setName(data.Name)
            end
        end
    elseif self.type == DINGING_CAR_STATUS.DELIVERY_CAR then
        -- 订单配送
        if data.Name then  -- 传输的标志
            local diningCar = takeawayInstance:GetDatas().diningCar
            self:setName(data.Name)
            local x, y  = string.find(data.Name, "%d+")
            if x and y then
                local cardId = checkint(string.sub(data.Name,x,y))
                local level = nil
                local cardInfo = nil
                for k , v in pairs(diningCar) do
                    if  checkint(v.diningCarId)  == cardId then
                        level = v.level
                        cardInfo = v
                    end
                end
                if  not  level then
                    return
                end
                -- 设置菜车的等级
                local coutDown = checkint(cardInfo.leftSeconds)
                display.commonLabelParams(self.viewData.leftSecondBtn , {text = string.formattedTime(coutDown, '%02i:%02i:%02i')})
                local teamNum = cardInfo.teamId
                if teamNum then
                    self.viewData.teamLabel:setString(string.format(__('编队%s'),tostring(teamNum)) )
                    if data.mouldData.areaId then
                        local areaId = data.mouldData.areaId
                        local str = self:GetAreaName(areaId)
                        self.viewData.teamStatusLabel:setString(string.format( __('正在%s区域配送中') , str))

                    end
                end
                if checkint(data.mouldData.beRobbed)  == 1 then -- 被打劫
                    if checkint(data.mouldData.robberyResult) == 1  then
                        self.viewData.robberyAvatar:setVisible(true)

                    elseif checkint(data.mouldData.robberyResult) == 2  then
                        self.viewData.robberyAvatar:setVisible(true)

                    end
                else
                    self.viewData.robberyAvatar:setVisible(false)
                end
                local num = math.random(1,6)
                self.viewData.noticeImage:setTexture(_res(string.format('ui/home/carexplore/order_bg_%d_s.jpg' , num))  )
                self:AddTimeCountDown()
            end
            if data.callback then -- 存在回调事件
                self.callback = data.callback
                self.viewData.enterBtn:setName(data.Name)
                self.viewData.enterBtn:setOnClickScriptHandler(data.callback)
            end
        end
    elseif self.type == DINGING_CAR_STATUS.REWARD_CAR then
        -- 订单完成
        if data.Name then  -- 传输的标志
            local diningCar = takeawayInstance:GetDatas().diningCar
            self:setName(data.Name)
            local x, y  = string.find(data.Name, "%d+")
            if x and y then
                local cardId = checkint(string.sub(data.Name,x,y))
                local level = nil
                local cardInfo = nil
                for k , v in pairs(diningCar) do
                    if checkint(v.diningCarId ) == cardId then
                        level = v.level
                        cardInfo = v
                    end
                end
                if  not  level then
                    return
                end
                local teamNum = cardInfo.teamId
                if teamNum then
                    self.viewData.teamLabel:setString(string.format(__('编队%s'),tostring(teamNum)) )
                    if data.mouldData.areaId then
                        local areaId = data.mouldData.areaId
                        local str = self:GetAreaName(areaId)
                        self.viewData.teamStatusLabel:setString(string.format( __('在%s区域配送已经完成') , str))
                    end
                    --self.viewData.infoBtn:setString(__('领取奖励'))
                    display.commonLabelParams(self.viewData.infoBtn, {text = __('领取奖励')})
                end
            end
            if checkint(data.mouldData.beRobbed)  == 1 then -- 被打劫
                if checkint(data.mouldData.robberyResult) == 1  then
                    self.viewData.robberyAvatar:setVisible(true)
                    self.viewData.qAvatar:setToSetupPose()
                    self.viewData.qAvatar:setAnimation(0, "baoxiang2", true)
                elseif checkint(data.mouldData.robberyResult) == 2  then
                    self.viewData.robberyAvatar:setVisible(true)
                    self.viewData.qAvatar:setToSetupPose()
                    self.viewData.qAvatar:setAnimation(0, "baoxiang1", true)
                end
            else
                self.viewData.robberyAvatar:setVisible(false)
                self.viewData.qAvatar:setToSetupPose()
                self.viewData.qAvatar:setAnimation(0, "baoxiang1", true)
            end
            math.randomseed(tostring(os.time()):reverse() )
            local num = math.random(1,6)
            self.viewData.noticeImage:setTexture(_res(string.format('ui/home/carexplore/order_bg_%d_s.jpg' , num))  )
            if data.callback then -- 存在回调事件
                self.callback = data.callback
                self.viewData.infoBtn:setOnClickScriptHandler( data.callback)
                self.viewData.infoBtn:setName(data.Name)
            end
        end
    elseif self.type == DINGING_CAR_STATUS.EXPLORE_DOING then
        -- 正在探索中
        if data.Name then  -- 传输的标志
            self:setName(data.Name)
            local x, y  = string.find(data.Name, "%d+")
            if x and y then
                local fixId  = checkint(string.sub(data.Name,x,y))
                -- 设置菜车的等级
                local teamNum = fixId
                local teamId  =  self.datas.mouldData.teamId
                local areaId =   self.datas.mouldData.areaId
                self.viewData.noticeImage:setTexture(_res(string.format('ui/home/carexplore/order_bg_%d_s.jpg' , areaId))  )
                if teamNum then
                    self.viewData.teamLabel:setString(string.format(__('编队%s'),teamId) )
                    local str = self:GetAreaName(areaId)
                    self.viewData.teamStatusLabel:setString(string.format( __('在%s区域中探索') , str))
                end
            end

            local curTime = os.time()
            if not  self.datas.mouldData then
                return
            end
            local countdown = checkint(self.datas.mouldData.needTime)
            display.commonLabelParams(self.viewData.leftSecondBtn , {text = string.formattedTime(countdown, '%02i:%02i:%02i')})
            self.viewData.leftSecondBtn:runAction(
                cc.RepeatForever:create(
                    cc.Sequence:create(
                        cc.DelayTime:create(1),
                        cc.CallFunc:create(
                            function ()
                                local nowTime =  os.time()
                                local interval =  nowTime - curTime
                                curTime = nowTime
                                self.datas.mouldData.needTime = math.floor(self.datas.mouldData.needTime - interval + 0.5)
                                self.datas.mouldData.needTime =  self.datas.mouldData.needTime > 0 and  self.datas.mouldData.needTime or 0
                                -- 倒计时显示
                                display.commonLabelParams(self.viewData.leftSecondBtn , {text = string.formattedTime(self.datas.mouldData.needTime, '%02i:%02i:%02i')})
                                if self.datas.mouldData.needTime == 0  then
                                    self.viewData.leftSecondBtn:stopAllActions()
                                    self:RefreshAndInitDiningCarView(DINGING_CAR_STATUS.EXPLORE_DONE)
                                    self:RefreshCellUI(self.datas)
                                end
                            end
                        )
                    )

                )
            )
            if data.callback then -- 存在回调事件
                self.callback = data.callback
                self.viewData.enterBtn:setName(data.Name)
                self.viewData.enterBtn:setOnClickScriptHandler(data.callback)
            end
        end
    elseif self.type == DINGING_CAR_STATUS.EXPLORE_DONE then
        -- 探索已经完成
        -- 正在探索中
        if data.Name then  -- 传输的标志
            self:setName(data.Name)
            local x, y  = string.find(data.Name, "%d+")
            if x and y then
                local fixId  = checkint(string.sub(data.Name,x,y))
                -- 设置菜车的等级
                local teamNum = fixId
                local teamId  =  self.datas.mouldData.teamId
                local areaId =   self.datas.mouldData.areaId
                if teamNum then
                    self.viewData.teamLabel:setString(string.format(__('编队%s'),teamId) )
                    local str = self:GetAreaName(areaId)
                    display.commonLabelParams(self.viewData.teamStatusLabel , {text = string.format( __('在%s区域探索完成') , str) , reqW  =380 })
                end
                self.viewData.noticeImage:setTexture(_res(string.format('ui/home/carexplore/order_bg_%d_s.jpg' , areaId))  )
            end
            if data.callback then -- 存在回调事件
                self.callback = data.callback
                display.commonLabelParams(self.viewData.infoBtn, { text = __('查看')})
                --self.viewData.infoBtn:setString(__('探索完成'))
                self.viewData.infoBtn:setName(data.Name)
                self.viewData.infoBtn:setOnClickScriptHandler(data.callback)
            end
        end

    end
end
-- 获取区域的名称
function DiningCarCellView:GetAreaName(areaId)
    local areaData = CommonUtils.GetConfigAllMess('area','common')
    local str = ""
    local areaOneData = areaData[tostring(areaId)] or {}
    str = areaOneData.name or tostring(areaId)
    return str
end
-- 添加倒计时
function DiningCarCellView:AddTimeCountDown()
    local name = self:getName()
    if name then
        if self.type == DINGING_CAR_STATUS.EXPLORE_DOING or self.type == DINGING_CAR_STATUS.EXPLORE_DONE then
            return
        end
        local x, y  = string.find(name,'%d+')

        if x and y then
            xTry(function()
                shareFacade:RegistObserver(COUNT_DOWN_ACTION_UI, mvc.Observer.new( function(item ,signal)
                    local body = signal:GetBody()
                    local orderType = checkint(body.orderType)
                    local orderInfo = body.datas
                    local cardId =checkint(string.sub(name,x, y))
                    local cardInfo = nil
                    for k , v in pairs(takeawayInstance:GetDatas().diningCar) do
                        if checkint(v.diningCarId) == cardId then
                            cardInfo = v
                        end
                    end

                    if checkint(cardInfo.orderId) == checkint(orderInfo.orderId) and checkint(cardInfo.orderType)  == orderType then
                        if cardInfo then
                            local countdown = checkint(body.countdown)
                            if countdown == 0 then
                                -- 由配送状态转化为正常领取状态
                                item:RefreshAndInitDiningCarView(DINGING_CAR_STATUS.REWARD_CAR)
                                item:RefreshCellUI(self.datas)
                                app:DispatchObservers('DELIVERY_ORDER_FINISHED', {diningCarId = self.datas.mouldData.diningCarId})
                            else
                                --显示计时器
                                display.commonLabelParams(item.viewData.leftSecondBtn , {text = string.formattedTime(countdown, '%02i:%02i:%02i') })
                            end
                        end

                    end

                end,self))
            end,__G__TRACKBACK__)

        end
    end
end
function DiningCarCellView:onCleanup()
    shareFacade:UnRegistObserver(COUNT_DOWN_ACTION_UI, self)
end



return DiningCarCellView
