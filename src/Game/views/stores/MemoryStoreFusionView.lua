--[[
 * author : liuzhipeng
 * descpt : 新游戏商店 - 记忆商店 碎片融合View
]]
local MemoryStoreFusionView = class('MemoryStoreFusionView', function()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.stores.MemoryStoreFusionView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    COMMON_BG_11      = _res('ui/common/common_bg_11.png'),
    TITLE_BG          = _res('ui/common/common_bg_title_2.png'),
    CLOSE_BTN         = _res('ui/common/common_btn_quit.png'),
    ROLE_IMG          = _res("ui/common/common_ico_cartoon_1.png"),
    LEFT_LAYOUT_FRAME = _res("ui/backpack/bag_bg_describe_1.png"),
    LEFT_LAYOUT_BG    = _res('ui/home/teamformation/concertSkillMess/biandui_lianxieskill_fazheng.png'),	
    COMMON_TIPS_ICON  = _res('ui/common/common_btn_tips.png'),
    AMOUNT_BG         = _res('ui/stores/memory/commcon_bg_text.png'),
    COMMON_BTN        = _res('ui/common/common_btn_orange.png'),
    LIST_BG           = _res('ui/common/common_bg_goods.png'),
    ARROW_IMG         = _res('ui/stores/memory/shop_fusing_bg.png'),
    ARROW_SPINE       = _spn('ui/stores/memory/shop_fusing_arrow'),
}
local CreateListCell = nil
function MemoryStoreFusionView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function MemoryStoreFusionView:InitUI()
    local function CreateView()
        local bg = display.newImageView(RES_DICT.COMMON_BG_11, 0, 0)
    	local size = bg:getContentSize()
        local view = CLayout:create(size)
        bg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bg, 1)
        -- mask --
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- mask --

        -- 标题
        local titleLabel = display.newButton(size.width / 2, size.height - 30, {n = RES_DICT.TITLE_BG})
        display.commonLabelParams(titleLabel, fontWithColor(3, {text = __('碎片融合')}))
        view:addChild(titleLabel, 5)
        -- 关闭按钮
        local closeBtn = display.newButton(size.width - 2, size.height - 42, {n = RES_DICT.CLOSE_BTN})
        view:addChild(closeBtn, 10)
        -- 角色图片
        local roleImg = display.newImageView(RES_DICT.ROLE_IMG, -20, 80)
        view:addChild(roleImg, 10)
        ----------------------
        ----- leftLayout -----
        local leftLayoutSize = cc.size(388, 574)
        local leftLayout = CLayout:create(leftLayoutSize)
        leftLayout:setPosition(cc.p(size.width / 2 - 234, size.height / 2 - 20))
        view:addChild(leftLayout, 1)
        -- frame
        local leftLayoutFrame = display.newImageView(RES_DICT.LEFT_LAYOUT_FRAME, leftLayoutSize.width / 2, leftLayoutSize.height / 2 + 30)
        leftLayout:addChild(leftLayoutFrame, 1)
        -- bg 
        local leftLayoutBg = display.newImageView(RES_DICT.LEFT_LAYOUT_BG, leftLayoutSize.width / 2, leftLayoutSize.height / 2 + 30)
        leftLayout:addChild(leftLayoutBg, 1)
        -- 提示按钮
        local tipsBtn = display.newButton(45, leftLayoutSize.height - 50, {n = RES_DICT.COMMON_TIPS_ICON})
        leftLayout:addChild(tipsBtn, 5)
        -- 提示说明
        local tipsLabel = display.newLabel(65, leftLayoutSize.height - 50, fontWithColor(15, {text = __('规则说明'), ap = display.LEFT_CENTER}))
        leftLayout:addChild(tipsLabel, 5)
        -- 转换道具
        local currencyIcon = require('common.GoodNode').new({
			id = MEMORY_CURRENCY_M_ID,
			showAmount = false,
			callBack = function (sender)
			end
        })
        currencyIcon:setPosition(leftLayoutSize.width / 2, leftLayoutSize.height / 2 + 30)
        leftLayout:addChild(currencyIcon, 5)
        -- 转换数量
        local amountBg = display.newImageView(RES_DICT.AMOUNT_BG, leftLayoutSize.width / 2, 115)
        leftLayout:addChild(amountBg, 3)
        local amountLabel = display.newLabel(leftLayoutSize.width / 2, 115, fontWithColor(6, {text = ''}))
        leftLayout:addChild(amountLabel, 5)
        -- 融合按钮
        local fusionBtn = display.newButton(leftLayoutSize.width / 2, 40, {n = RES_DICT.COMMON_BTN})
        display.commonLabelParams(fusionBtn, fontWithColor(14, {text = __('融合')}))
        leftLayout:addChild(fusionBtn, 5)
        ----- leftLayout -----
        ----------------------

        -----------------------
        ----- rightLayout -----
        local rightLayoutSize = cc.size(495, 574)
        local rightLayout = CLayout:create(rightLayoutSize)
        rightLayout:setPosition(cc.p(size.width / 2 + 185, size.height / 2 - 20))
        view:addChild(rightLayout, 1)
        -- 列表背景
        local giewViewSize = cc.size(442, 535)
        local listBg = display.newImageView(RES_DICT.LIST_BG, rightLayoutSize.width / 2, rightLayoutSize.height / 2, {scale9 = true, size = giewViewSize})
        rightLayout:addChild(listBg, 1)
        -- 碎片列表
        local listView = display.newGridView(rightLayoutSize.width / 2, rightLayoutSize.height / 2, {cols = 4, size = giewViewSize, csize = cc.size(giewViewSize.width / 4, 110)})
        listView:setCellCreateHandler(CreateListCell)
        rightLayout:addChild(listView, 1)
        -- 箭头
        local arrowImg = display.newImageView(RES_DICT.ARROW_IMG, 22, rightLayoutSize.height / 2 + 30)
        rightLayout:addChild(arrowImg, -1)
        local arrowSpn = sp.SkeletonAnimation:create(
            RES_DICT.ARROW_SPINE.json,
            RES_DICT.ARROW_SPINE.atlas,
            1
        )
        arrowSpn:setAnimation(0, 'idle', true)
        rightLayout:addChild(arrowSpn, 3)
        arrowSpn:setPosition(0, rightLayoutSize.height / 2 + 30)
        
        ----- rightLayout -----
        -----------------------
        return {
            view                = view,
            closeBtn            = closeBtn,
            currencyIcon        = currencyIcon,
            amountLabel         = amountLabel,
            listView            = listView,
            tipsBtn             = tipsBtn,
            fusionBtn           = fusionBtn,
        }
    end
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
    end, __G__TRACKBACK__)
end
--[[
创建列表cell
--]]
CreateListCell = function( cellParent )
    local view = cellParent
    local size = cellParent:getContentSize()
    local goodsNode = require('common.GoodNode').new({id = GOLD_ID, amount = 1, showAmount = true})
    goodsNode:setPosition(cc.p(size.width / 2, size.height / 2))
    goodsNode:setScale(0.9)
    view:addChild(goodsNode, 1)
    return {
        view              = view,
        goodsNode         = goodsNode,
    }
end
--[[
刷新货币
@params currency int 货币id
@params convertAmount int 转换数量
--]]
function MemoryStoreFusionView:RefreshCurrency( currency, convertAmount )
    local viewData = self:GetViewData()
    viewData.currencyIcon:RefreshSelf({
        goodsId = currency,
        callBack = function ( sender )
            app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = currency, type = 1})
        end
    })
    local currencyConf = CommonUtils.GetConfig('goods', 'goods', currency)
    display.commonLabelParams(viewData.amountLabel, fontWithColor(6, {text = string.fmt(__('本次融合将获得_name_:_num_'), {['_name_'] = currencyConf.name, ['_num_'] = convertAmount}), reqW = 300}))
end
--[[
获取viewData
--]]
function MemoryStoreFusionView:GetViewData()
    return self.viewData
end
return MemoryStoreFusionView
                                                                                                                                                                                