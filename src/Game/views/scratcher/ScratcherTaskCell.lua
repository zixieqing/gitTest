---@class ScratcherTaskCell : CGridViewCell
local ScratcherTaskCell = class('ScratcherTaskCell', function ()
    local ScratcherTaskCell = CGridViewCell:new()
    ScratcherTaskCell:enableNodeEvents()
    return ScratcherTaskCell
end)


local RES_DICT = {
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    COMMON_FRAME_GOODS_4            = _res('ui/common/common_frame_goods_4.png'),
    CARDMATCH_TASK_FRAME            = _res('ui/scratcher/cardmatch_task_frame.png'),
}

function ScratcherTaskCell:ctor( ... )
	self.args = unpack({...}) or {}

	self:InitUI()
end

function ScratcherTaskCell:InitUI()
    local function CreateView()
        self:setContentSize(cc.size(620, 122))
        local view = CLayout:create(cc.size(620, 122))
        view:setPosition(310, 61)
        self:addChild(view)

        local Image_2 = display.newImageView(RES_DICT.CARDMATCH_TASK_FRAME, 310, 58,
        {
            ap = display.CENTER,
        })
        view:addChild(Image_2)

        local drawBtn = display.newButton(546, 54,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        display.commonLabelParams(drawBtn, fontWithColor(14, {text = __('领取')}))
        view:addChild(drawBtn)

		local goodsIcon = require('common.GoodNode').new({id = DIAMOND_ID, amount = 1, showAmount = true})
		goodsIcon:setScale(0.75)
		goodsIcon:setPosition(415, 58)
		view:addChild(goodsIcon)

        local taskContent = display.newLabel(45, 55,
        {
            text = '',
            ap = display.LEFT_CENTER,
            fontSize = 24,
            color = '#5b3c25',
            w = 320
        })
        view:addChild(taskContent)

        return {
            view                    = view,
            Image_2                 = Image_2,
            drawBtn                 = drawBtn,
            goodsIcon               = goodsIcon,
            taskContent             = taskContent,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()

	end, __G__TRACKBACK__)
end

return ScratcherTaskCell
