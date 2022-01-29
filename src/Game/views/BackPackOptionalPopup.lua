--[[
 * author : liuzhipeng
 * descpt : 好友 好友切磋View
--]]
local BackPackOptionalPopup = class('BackPackOptionalPopup', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.friend.BackPackOptionalPopup'
	node:enableNodeEvents()
	return node
end)
local RES_DICT = {
    BG             = _res('ui/common/common_bg_7.png'),
    TITLE_BG       = _res("ui/common/common_bg_title_2.png"), 
    COMMMON_BTN    = _res('ui/common/common_btn_orange.png'), 
    SELECTED_FRAME = _res('ui/common/common_bg_frame_goods_elected.png'), 
}
function BackPackOptionalPopup:ctor( ... )
    local args = unpack({...})
    self.goodsId = checkint(args.goodsId)
    self.goodsConf = CommonUtils.GetConfig('goods', 'goods', self.goodsId)
    self.selectedUpperLimit = checkint(self.goodsConf.choiceLimit)
    self.selectedRewardsDict = {}
    self:InitUI()
end

function BackPackOptionalPopup:InitUI()
    local function CreateView( )
        local bg =  display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        local view = CLayout:create(size)

        -- mask --
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0, 0, 0, 0)})
        view:addChild(mask, -1)
        -- mask --

        -- bg 
        bg:setPosition(cc.p(size.width/2, size.height/2))
        view:addChild(bg, 1)
        -- title 
        local titleBg = display.newButton(size.width / 2, size.height - 20, {n = RES_DICT.TITLE_BG, animation = false})
        display.commonLabelParams(titleBg,
            {text = __('选择奖励'),
            fontSize = 24,color = fontWithColor('BC').color,ttf = true, font = TTF_GAME_FONT,
            offset = cc.p(0, -1)})
        view:addChild(titleBg, 2)
        -- tips
        local tipsLabel = display.newLabel(size.width / 2, size.height - 60, fontWithColor(6, {text = ''}))
        view:addChild(tipsLabel, 5)
        -- gridView
        local gridViewSize = cc.size(485, 364)
        local gridViewCellSize = cc.size(gridViewSize.width / 4, gridViewSize.height / 3)
        local gridView = CGridView:create(gridViewSize)
        gridView:setSizeOfCell(gridViewCellSize)
        gridView:setColumns(4)
        gridView:setBounceable(false)
        gridView:setPosition(cc.p(size.width / 2, size.height / 2 + 15))
        view:addChild(gridView, 5)
        -- drawBtn 
        local drawBtn = display.newButton(size.width / 2, 70, {n = RES_DICT.COMMMON_BTN})
        display.commonLabelParams(drawBtn, fontWithColor(14, {text = __('领取')}))
        view:addChild(drawBtn, 5)
        -- selectedAmountLabel
        local selectedAmountLabel = display.newLabel(size.width / 2, 28, fontWithColor(16, {text = ''}))
        view:addChild(selectedAmountLabel, 5)
    	return {  
            view                   = view,
            tipsLabel              = tipsLabel,
            gridViewCellSize       = gridViewCellSize,
            gridView               = gridView,
            drawBtn                = drawBtn,
            selectedAmountLabel    = selectedAmountLabel,
    	}
    end
    xTry(function ( )
        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setContentSize(display.size)
        eaterLayer:setPosition(utils.getLocalCenter(self))
        eaterLayer:setOnClickScriptHandler(function ( sender )
            PlayAudioByClickClose()
            self:Close()
        end)
        self:addChild(eaterLayer)

        self.viewData = CreateView( )
        self.viewData.view:setPosition(display.center)
        self:addChild(self.viewData.view)
        -- handler
        self.viewData.drawBtn:setOnClickScriptHandler(handler(self, self.DrawButtonCallback))
        self.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.GridViewDataSource))
        -- refreshUI
        self:RefreshUI()
        self:EnterAnimation()
    end, __G__TRACKBACK__)
end
--[[
初始化UI
--]]
function BackPackOptionalPopup:RefreshUI()
    local viewData = self:GetViewData()
    if not self.goodsConf then return end

    viewData.tipsLabel:setString(string.fmt(__('选择_num_个想要的道具'), {['_num_'] = self.selectedUpperLimit}))
    viewData.selectedAmountLabel:setString(string.fmt(__('已选择_num1_/_num2_'), {['_num1_'] = table.nums(self.selectedRewardsDict), ['_num2_'] = self.selectedUpperLimit}))

    self:ReloadGridView()
end
--[[
领取按钮点击回调
--]]
function BackPackOptionalPopup:DrawButtonCallback( sender )
    PlayAudioByClickNormal()
    if self:IsSelectedUpperLimit() then
        if self:GetSelectedAmount() == self.selectedUpperLimit then
            local str = ''
            for k, v in pairs(self.selectedRewardsDict) do
                if str == '' then
                    str = v
                else
                    str = str .. ',' .. v
                end
            end
            app:DispatchObservers(BACKPACK_OPTIONAL_OPTIONAL_CHEST_DRAW, {goodsId = self.goodsId, choices = str})
            self:Close()
        else
            app.uiMgr:ShowInformationTips(__('数量错误'))
        end
    else
        app.uiMgr:ShowInformationTips(string.fmt(__('选择_num_个想要的道具'), {['_num_'] = self.selectedUpperLimit}))
    end
end
--[[
列表处理
--]]
function BackPackOptionalPopup:GridViewDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    if not pCell then
        local cSize = self:GetViewData().gridViewCellSize
        pCell = CGridViewCell:new()
        pCell:setContentSize(cSize)
        local goodsNode = require('common.GoodNode').new({id = GOLD_ID, callBack = handler(self, self.CellBtnCallback)})
        goodsNode:setPosition(cc.p(cSize.width / 2, cSize.height / 2))
        pCell:addChild(goodsNode, 5)
        pCell.goodsNode = goodsNode
        local selectedFrame = display.newImageView(RES_DICT.SELECTED_FRAME, cSize.width / 2, cSize.height / 2)
        pCell:addChild(selectedFrame, 5)
        selectedFrame:setVisible(false)
        pCell.selectedFrame = selectedFrame
    end
    xTry(function()
        local cellData = self.goodsConf.rewards[index]
        pCell.goodsNode:RefreshSelf({goodsId = cellData.goodsId, num = cellData.num, showAmount = true})
        if self.selectedRewardsDict[tostring(index)] then
            pCell.selectedFrame:setVisible(true)
            pCell.goodsNode:setOpacity(255)
        else
            pCell.selectedFrame:setVisible(false)
            if self:IsSelectedUpperLimit() then
                -- 已达到选中上限
                pCell.goodsNode:setOpacity(255 * 0.6)
            else
                -- 未达到选中上限
                pCell.goodsNode:setOpacity(255)
            end
        end
        pCell.goodsNode:setTag(index)
	end,__G__TRACKBACK__)	
	return pCell
end
--[[
cell点击回调
--]]
function BackPackOptionalPopup:CellBtnCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if self.selectedRewardsDict[tostring(tag)] then
        self.selectedRewardsDict[tostring(tag)] = nil 
        self:RefreshUI()
        return 
    end
    if not self:IsSelectedUpperLimit() then
        self.selectedRewardsDict[tostring(tag)] = tostring(tag)
        self:RefreshUI()
    end
end
--[[
重载gridView
--]]
function BackPackOptionalPopup:ReloadGridView()
    local viewData = self:GetViewData()
    
    local offset = viewData.gridView:getContentOffset()
    viewData.gridView:setCountOfCell(#self.goodsConf.rewards)
    viewData.gridView:reloadData()
    viewData.gridView:setContentOffset(offset)
end
--[[
进入动画
--]]
function BackPackOptionalPopup:EnterAnimation()
    local viewData = self:GetViewData()
	viewData.view:setScale(0.8)
	viewData.view:runAction(
		cc.Sequence:create(
			cc.EaseBackOut:create(
				cc.ScaleTo:create(0.2, 1)
			)
		)
	)
end
--[[
关闭界面
--]]
function BackPackOptionalPopup:Close()
    local viewData = self:GetViewData()
	viewData.view:runAction(
		cc.Sequence:create(
			cc.EaseBackIn:create(
				cc.ScaleTo:create(0.2, 0.8)
            ),
            cc.CallFunc:create(function()
                app.uiMgr:GetCurrentScene():RemoveDialog(self)
            end)
		)
	)
end
--[[
是否达到最大选中限制
@return isLimit bool 是否受限
--]]
function BackPackOptionalPopup:IsSelectedUpperLimit()
    return self:GetSelectedAmount() >= self.selectedUpperLimit
end
--[[
获取选中数量
@return selectedAmount int 选中奖励数目
--]]
function BackPackOptionalPopup:GetSelectedAmount()
    return table.nums(self.selectedRewardsDict)
end
--[[
获取viewData
--]]
function BackPackOptionalPopup:GetViewData()
    return self.viewData
end
return BackPackOptionalPopup