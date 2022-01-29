---@class ScratcherSelectCell : CGridViewCell
local ScratcherSelectCell = class('ScratcherSelectCell', function ()
    local ScratcherSelectCell = CTableViewCell:new()
    ScratcherSelectCell:enableNodeEvents()
    return ScratcherSelectCell
end)

local RES_DICT = {
    CARDMATCH_CHOICE_CARD_BG        = _res('ui/scratcher/cardmatch_choice_card_bg.png'),
    CARDMATCH_CHOICE_CARD_BG_SELECT = _res('ui/scratcher/cardmatch_choice_card_bg_select.png'),
    CARDMATCH_CHOICE_CARD_BG_UP     = _res('ui/scratcher/cardmatch_choice_card_bg_up.png'),
}

function ScratcherSelectCell:ctor( ... )
	self.args = unpack({...}) or {}

	self:InitUI()
end

function ScratcherSelectCell:InitUI()
    local function CreateView()
        self:setContentSize(cc.size(260, 480))
        local view = CLayout:create(cc.size(260, 480))
        view:setPosition(136, 240)
        self:addChild(view)

        -- local Image_2 = display.newImageView(RES_DICT.CARDMATCH_CHOICE_CARD_BG, 123, 240,
        -- {
        --     ap = display.CENTER,
        -- })
        -- view:addChild(Image_2)

        local roleClippingNode = cc.ClippingNode:create()
        roleClippingNode:setContentSize(cc.size(210, 460))
        roleClippingNode:setAnchorPoint(0, 0)
        roleClippingNode:setPosition(cc.p(25, 10))
        roleClippingNode:setInverted(false)
        view:addChild(roleClippingNode)

        local stencilImage = display.newImageView(RES_DICT.CARDMATCH_CHOICE_CARD_BG, 98, 230,
        {
            ap = display.CENTER,
        })
        roleClippingNode:setStencil(stencilImage)

        local teamBg = AssetsUtils.GetCardTeamBgNode(0, 98, 230)
        teamBg:setScale(1.1)
        roleClippingNode:addChild(teamBg)
    
        local targetImage = AssetsUtils.GetCardDrawNode()
        targetImage:setAnchorPoint(display.LEFT_BOTTOM)
        roleClippingNode:addChild(targetImage)
    
        local selectToggle = display.newToggleView(123, 240,
        {
            ap = display.CENTER,
            n = RES_DICT.CARDMATCH_CHOICE_CARD_BG_UP,
            s = RES_DICT.CARDMATCH_CHOICE_CARD_BG_SELECT,
            enable = true,
        })
        view:addChild(selectToggle)

        return {
            view                    = view,
            teamBg                  = teamBg,
            targetImage             = targetImage,
            selectToggle            = selectToggle,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()

	end, __G__TRACKBACK__)
end

return ScratcherSelectCell
