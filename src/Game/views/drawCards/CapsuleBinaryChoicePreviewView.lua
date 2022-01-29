--[[
 * author : liuzhipeng
 * descpt : 新抽卡 双抉卡池卡池预览View
--]]
local CapsuleBinaryChoicePreviewView = class('CapsuleBinaryChoicePreviewView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.CapsuleBinaryChoicePreviewView'
    node:enableNodeEvents()
    return node
end)
local CapsuleBinaryChoiceCell = require("Game.views.drawCards.CapsuleBinaryChoiceCell")
local RES_DICT = {
    COMMON_BG_5              = _res('ui/common/common_bg_5.png'),
    LIST_BG                  = _res('ui/common/common_bg_input_lock.png')

}
function CapsuleBinaryChoicePreviewView:ctor( ... )
    local args = unpack({...})
    self.cards = checktable(args.cards)
    self:InitUI()
end
 
function CapsuleBinaryChoicePreviewView:InitUI() 
    local function CreateView()
        local bg = display.newImageView(RES_DICT.COMMON_BG_5, 0, 0)
        bg:setCascadeOpacityEnabled(true)
		local size = bg:getContentSize()

		local view = display.newLayer(0, 0, {size = size, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(size.width * 0.5, size.height * 0.5)})
		view:addChild(bg, 1)

		-- 标题
        local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
		display.commonUIParams(titleBg, {po = cc.p(size.width * 0.5, size.height - titleBg:getContentSize().height * 0.5)})
		display.commonLabelParams(titleBg, fontWithColor('14', {text = __('飨灵预览'), offset = cc.p(0, -2)}))
        titleBg:setEnabled(false)
        bg:addChild(titleBg)
        
        -- 列表 
        local listViewSize = cc.size(1070, 560)
        local listViewCellSize = cc.size(219, listViewSize.height)

        local listBg = display.newImageView(RES_DICT.LIST_BG, size.width / 2, 20, {scale9 = true, size = listViewSize, ap = display.CENTER_BOTTOM})
        view:addChild(listBg, 1)
        
        local listView = CTableView:create(listViewSize)
		listView:setSizeOfCell(listViewCellSize)
        listView:setPosition(cc.p(size.width / 2, 20))
        listView:setAnchorPoint(display.CENTER_BOTTOM)
		view:addChild(listView, 5)
        listView:setDirection(eScrollViewDirectionHorizontal)
        
        return {      
            view             = view,
            listView         = listView,
            listViewSize     = listViewSize,
            listViewCellSize = listViewCellSize,
        }
    end
    xTry(function ( )
        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setContentSize(display.size)
        eaterLayer:setPosition(utils.getLocalCenter(self))
        self:addChild(eaterLayer)
        eaterLayer:setOnClickScriptHandler(function () 
            self:runAction(cc.RemoveSelf:create())
        end)

        self.viewData = CreateView()
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self:addChild(self.viewData.view, 1)

        self.viewData.listView:setDataSourceAdapterScriptHandler(handler(self, self.ListViewBonusSource))
        self.viewData.listView:setCountOfCell(#self.cards)
        self.viewData.listView:reloadData()
        -- 显示动画
        self.viewData.view:setOpacity(0)
        self.viewData.view:runAction(
            cc.FadeIn:create(0.2)
        )
	end, __G__TRACKBACK__)
end
--[[
列表处理
--]]
function CapsuleBinaryChoicePreviewView:ListViewBonusSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = self.viewData.listViewCellSize

    if pCell == nil then
        pCell = CapsuleBinaryChoiceCell.new(cSize)
    end
    xTry(function()
        local cardId = self.cards[index]
        local drawPath = CardUtils.GetCardDrawPathByCardId(cardId)
        pCell.viewData.imgHero:setTexture(drawPath)

        local locationInfo = CommonUtils.GetConfig('cards', 'coordinate', cardId)
        if nil == locationInfo or not locationInfo[COORDINATE_TYPE_TEAM] then
            print('\n**************\n', '立绘坐标信息未找到', cardId, '\n**************\n')
            locationInfo = {x = 0, y = 0, scale = 50, rotate = 0}
        else
            locationInfo = locationInfo[COORDINATE_TYPE_TEAM]
        end
        pCell.viewData.imgHero:setScale(locationInfo.scale/100)
        pCell.viewData.imgHero:setRotation( (locationInfo.rotate))
        pCell.viewData.imgHero:setPosition(cc.p(locationInfo.x ,(-1)*(locationInfo.y-540) -8))

        pCell.viewData.heroBg:setTexture(CardUtils.GetCardTeamBgPathByCardId(cardId))
        --更新技能相关的图标
        pCell.viewData.bg:setTexture(CardUtils.GetCardTeamFramePathByCardId(cardId))
        pCell.viewData.skillFrame:setTexture(CardUtils.GetCardCareerIconFramePathByCardId(cardId))
        pCell.viewData.skillIcon:setTexture(CardUtils.GetCardCareerIconPathByCardId(cardId))
        pCell.viewData.qualityIcon:setTexture(CardUtils.GetCardQualityIconPathByCardId(cardId))
        pCell.viewData.entryHeadNode:RefreshUI({confId = cardId})
    end,__G__TRACKBACK__)
    return pCell
end
return CapsuleBinaryChoicePreviewView