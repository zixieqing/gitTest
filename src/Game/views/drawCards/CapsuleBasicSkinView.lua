--[[
 * author : liuzhipeng
 * descpt : 抽卡 常驻皮肤卡池View
--]]
local CapsuleBasicSkinView = class('CapsuleBasicSkinView', function ()
    local node = CLayout:create()
    node.name = 'home.CapsuleBasicSkinView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG                = _res('ui/home/capsuleNew/basicSkin/anni_activity_bg_newskini.jpg'),
    BOTTOM_BG         = _res('ui/home/capsuleNew/common/summon_activity_bg_.png'),
    COMMON_BTN_BIG    = _res('ui/common/common_btn_big_orange_2.png'),
    COMMON_BTN_BIG_D  = _res('ui/common/common_btn_big_orange_disabled_2.png'),
    FIRST_DRAW_BG     = _res('ui/home/capsuleNew/basicSkin/summon_skin_bg_ten.png'),
    MAIN_BTN_SHOP     = _res('ui/home/nmain/main_btn_shop'),
}
function CapsuleBasicSkinView:ctor( ... ) 
	local args = unpack({...})
    self.size = args.size
    self:InitUI()
end
 
function CapsuleBasicSkinView:InitUI()
    local size = self.size 
    self:setContentSize(size)
    local function CreateView()
        local view = CLayout:create(size)
        local bg = display.newImageView(RES_DICT.BG, size.width / 2 - 145, size.height / 2 + 40)
        view:addChild(bg, 1)
        -- 商店
	    local storeBtn = display.newButton(size.width - display.SAFE_L - 50, size.height - 140, {n = RES_DICT.MAIN_BTN_SHOP})
        display.commonLabelParams(storeBtn, fontWithColor(14, {fontSize = 20, hAlign = display.TAC, offset = cc.p(0, -20), text = __('兑换')}))
        view:addChild(storeBtn, 8)
        -- bottomLayout --
        local bottomLayoutSize = cc.size(size.width, 200)
        local bottomLayout = CLayout:create(bottomLayoutSize)
        bottomLayout:setPosition(cc.p(size.width / 2, 100))
        view:addChild(bottomLayout, 1)
        -- 背景
        local bottomBg = display.newImageView(RES_DICT.BOTTOM_BG, bottomLayoutSize.width / 2, bottomLayoutSize.height / 2)
        bottomLayout:addChild(bottomBg, 1)
        -- 抽奖按钮
        local drawOncePos = cc.p(size.width/2 - 200, 110)
        local drawOnceBtn = display.newButton(drawOncePos.x, drawOncePos.y, {n = RES_DICT.COMMON_BTN_BIG, d = RES_DICT.COMMON_BTN_BIG_D})
        display.commonLabelParams(drawOnceBtn, fontWithColor(14, {fontSize = 26, hAlign = display.TAC, text = string.fmt(__('召唤\nX_num_'), {_num_ = 1})}))
        bottomLayout:addChild(drawOnceBtn, 3)
        local onceConsumeRLable = display.newRichLabel(drawOncePos.x, drawOncePos.y - 62)
        bottomLayout:addChild(onceConsumeRLable, 5)

        local drawMuchPos = cc.p(size.width/2 + 200, drawOncePos.y)
        local drawMuchBtn = display.newButton(drawMuchPos.x, drawMuchPos.y, {n = RES_DICT.COMMON_BTN_BIG, d = RES_DICT.COMMON_BTN_BIG_D})
        display.commonLabelParams(drawMuchBtn, fontWithColor(14, {fontSize = 26, hAlign = display.TAC, text = string.fmt(__('召唤\nX_num_'), {_num_ = 10})}))
        bottomLayout:addChild(drawMuchBtn, 3)
        local muchConsumeRLable = display.newRichLabel(drawMuchPos.x, onceConsumeRLable:getPositionY())
        bottomLayout:addChild(muchConsumeRLable, 5)
        -- 每日首次奖励提醒
        local firstDrawTips = display.newImageView(RES_DICT.FIRST_DRAW_BG, size.width/2 + 200, drawOncePos.y + 60)
        bottomLayout:addChild(firstDrawTips, 5)
        local firstDrawLabel = display.newLabel(firstDrawTips:getContentSize().width / 2 - 10, firstDrawTips:getContentSize().height / 2, {fontSize = 20, color = '#ffd792', text = __('每日初次十连可获得'), reqW = 175})
        firstDrawTips:addChild(firstDrawLabel, 5)
        -- bottomLayout --
        return {      
            view              = view,
            drawOnceBtn       = drawOnceBtn,
            drawMuchBtn       = drawMuchBtn,
            firstDrawTips     = firstDrawTips,
            onceConsumeRLable = onceConsumeRLable,
            muchConsumeRLable = muchConsumeRLable,
            storeBtn          = storeBtn,
        }
    end
    xTry(function ( )
        self.viewData = CreateView()
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self:addChild(self.viewData.view, 1)
	end, __G__TRACKBACK__)
end
--[[
刷新抽卡消耗label
@params oneConsume map 抽一次的消耗
@params tenConsume map 抽十次的消耗
--]]
function CapsuleBasicSkinView:RefreshConsumeLabel( oneConsume, tenConsume )
    local viewData = self:GetViewData()
    display.reloadRichLabel(viewData.onceConsumeRLable, {c = {
        {text = string.fmt(__('消耗_num_'), {['_num_'] = oneConsume.num}), fontSize = 20, color = '#ffffff'},
        {img = GoodsUtils.GetIconPathById(oneConsume.goodsId), scale = 0.18}
    }})
    display.reloadRichLabel(viewData.muchConsumeRLable, {c = {
        {text = string.fmt(__('消耗_num_'), {['_num_'] = tenConsume.num}), fontSize = 20, color = '#ffffff'},
        {img = GoodsUtils.GetIconPathById(tenConsume.goodsId), scale = 0.18}
    }})
end
--[[
刷新首次抽卡的提示框
@params isFirst int 是否为首次抽卡，1为是，0为否
--]]
function CapsuleBasicSkinView:RefreshFirstDrawLabel( isFirst )
    local viewData = self:GetViewData()
    viewData.firstDrawTips:setVisible(checkint(isFirst) == 1)
end
--[[
获取viewData
--]]
function CapsuleBasicSkinView:GetViewData()
    return self.viewData
end
return CapsuleBasicSkinView
