---@class BackpackCell
local BackpackCell = class('home.BackpackCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'home.BackpackCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function BackpackCell:ctor(...)
    local arg = {...}
    local size = arg[1] or cc.size(108,115)
    self:setContentSize(size)

    local eventNode = CLayout:create(cc.size(108,115))
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode

    local toggleView = display.newButton(size.width * 0.5,size.height * 0.5,{--
        n = _res('ui/common/common_frame_goods_1.png')
    })
    toggleView:setScale(0.95)
    self.toggleView = toggleView
    self.eventnode:addChild(self.toggleView)

    local fragmentImg = display.newImageView(_res('ui/common/common_ico_fragment_5.png'),0,0,{as = false})
    fragmentImg:setPosition(cc.p(size.width * 0.5,size.height * 0.5))
    fragmentImg:setScale(0.92)
    self.eventnode:addChild(fragmentImg)
    self.fragmentImg = fragmentImg
    self.fragmentImg:setVisible(false)

    local selectImg = display.newImageView(_res('ui/common/common_bg_frame_goods_elected.png'),0,0,{as = false})
    selectImg:setScale(0.92)
    selectImg:setPosition(cc.p(size.width * 0.5,size.height * 0.5))
    self.eventnode:addChild(selectImg)
    self.selectImg = selectImg
    self.selectImg:setVisible(false)
    local fight_num = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')--
    fight_num:setAnchorPoint(cc.p(1, 1))
    fight_num:setHorizontalAlignment(display.TAR)
    fight_num:setPosition(size.width - 10 ,self.toggleView:getPositionY() - 20)
    -- fight_num:setScale(0.6)
    self.eventnode:addChild(fight_num,1)
    self.numLabel = fight_num


    local goodsImg = display.newImageView(_res('ui/common/common_ico_fragment_5.png'),0,0,{as = false})
    goodsImg:setPosition(cc.p(size.width * 0.5,size.height * 0.5 - 4))
    goodsImg:setScale(0.55)
    self.toggleView:addChild(goodsImg)
    self.goodsImg = goodsImg
    goodsImg:setVisible(false)


    local maskImg = display.newImageView(_res('ui/common/common_frame_mask.png'),0,0,{as = false})
    -- maskImg:setScale(0.92)
    maskImg:setPosition(cc.p(size.width * 0.5,size.height * 0.5))
    self.eventnode:addChild(maskImg,10)
    maskImg:setVisible(false)
    self.maskImg = maskImg

    -- 新的图标
    local newIcon = display.newImageView(_res('ui/card_preview_ico_new_2'),size.width - 20 ,size.height - 20,{ ap = cc.p(0.5,0.5)})
    self.eventnode:addChild(newIcon,2)
    self.newIcon = newIcon
    newIcon:setVisible(false)

    local feedStar = display.newImageView(_res('ui/common/card_love_feed_ico_star.png'),size.width - 20 ,size.height - 20,{ ap = cc.p(0.5,0.5)})
    self.eventnode:addChild(feedStar,2)
    self.feedStar = feedStar
    feedStar:setVisible(false)

    local checkBox = display.newButton(0,0,{--
        n = _res('ui/common/gut_task_ico_select.png')
    })
    display.commonUIParams(
        checkBox,
        {
            ap = cc.p(1, 1),
            po = cc.p(size.width,size.height)
        })
    checkBox:setTouchEnabled(false)
    self.eventnode:addChild(checkBox, 10)
    checkBox:setVisible(false)
    self.checkBox = checkBox

    -- level
    local levelBg = FilteredSpriteWithOne:create()
    levelBg:setCascadeOpacityEnabled(true)
    levelBg:setTexture(_res('ui/cards/head/kapai_zhiye_colour.png'))
    levelBg:setAnchorPoint(cc.p(0.5, 1))
    levelBg:setPosition(cc.p(size.width * 0.24, size.height - 2))
    levelBg:setScale(0.8)
    self.eventnode:addChild(levelBg)
    levelBg:setVisible(false)
    self.levelBg = levelBg

    -- level label
    local levelLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', "")
    display.commonUIParams(
        levelLabel,
        {
            ap = cc.p(0.5, 1),
            po = cc.p(utils.getLocalCenter(levelBg).x - 1, levelBg:getContentSize().height - 7)
        })
    levelBg:addChild(levelLabel)
    self.levelLabel = levelLabel

	local hasNumLabel = cc.Label:createWithBMFont('font/small/common_num_unused.fnt', '')
	hasNumLabel:setAnchorPoint(cc.p(1, 0.5))
	hasNumLabel:setHorizontalAlignment(display.TAR)
	hasNumLabel:setPosition(98, self.numLabel:getPositionY() - 15)
	self.eventnode:addChild(hasNumLabel,1)
	self.hasNumLabel = hasNumLabel

end
return BackpackCell
