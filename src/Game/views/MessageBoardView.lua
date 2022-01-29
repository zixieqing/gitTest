
--- Created by xingweihao.
--- DateTime: 25/10/2017 5:35 PM
---

---@class MessageBoardView
local MessageBoardView = class('home.MessageBoardView',function ()
    local node = CLayout:create( cc.size(603,496)) --cc.size(984,562)
    node.name = 'Game.views.MessageBoardView'
    node:enableNodeEvents()
    return node
end)
local  BUTTON_CLICK = {
    LEAEAL_WORDS = 1101  , -- 留言
    EDIT_MESSAGE = 1102  , -- 编辑留言
    DELETE_MESSAGE = 1103  , -- 删除留言
}
function MessageBoardView:ctor()
    self:initUI()
end

function MessageBoardView:initUI()
    local bgSize = cc.size(603,496)
    -- 背景内容
    local bgLayout  = display.newLayer(bgSize.width/2 , bgSize.height/2 , { ap = display.CENTER , size = bgSize })
    self:addChild(bgLayout)
    local gridSize = cc.size(591, 416)
    local gridLayout = display.newLayer(bgSize.width/2-3, bgSize.height - 7  , { ap = display.CENTER_TOP , size = gridSize})
    bgLayout:addChild(gridLayout)
    -- 背景图片
    local gridImage = display.newImageView( _res('ui/common/commcon_bg_text'),gridSize.width/2 ,  gridSize.height/2 , { ap = display.CENTER , size = gridSize , scale9 = true })
    gridLayout:addChild(gridImage)
    local gridViewCellSize = cc.size(589, 98)
    local gridView = CGridView:create(cc.size(gridSize.width, gridSize.height -5) )
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setAnchorPoint(display.CENTER_TOP)
    gridView:setColumns(1)
    gridView:setAutoRelocate(true)
    gridLayout:addChild(gridView, 10)
    gridView:setPosition(cc.p(gridSize.width/2  + 0.3, gridSize.height -2))


    -- 信息的message
    local messageSize = cc.size(591 , 60 )
    local messageLayout =  display.newLayer(bgSize.width/2 , 5 ,{ ap = display.CENTER_BOTTOM, size = messageSize })
    bgLayout:addChild(messageLayout)
    -- 留言的
    local sendMessage = display.newButton(messageSize.width -2 ,messageSize.height/2,{ ap = display.RIGHT_CENTER ,
        n = _res('ui/common/common_btn_orange.png') ,s  = _res('ui/common/common_btn_orange.png') , d = _res("ui/common/common_btn_orange_disable.png")
    })
    sendMessage:setTag(BUTTON_CLICK.LEAEAL_WORDS)
    display.commonLabelParams(sendMessage,fontWithColor(14,{text = __('留言')}))
    messageLayout:addChild(sendMessage)
    local editorMessageText = ccui.EditBox:create(cc.size(460, 56), _res('ui/home/infor/personal_information_bg_input.png'))
    display.commonUIParams(editorMessageText, {po = cc.p( -3 , messageSize.height/2+1) , ap = display.LEFT_CENTER} )
    messageLayout:addChild(editorMessageText)
    editorMessageText:setFontSize(fontWithColor('M2PX').fontSize)
    editorMessageText:setFontColor(ccc3FromInt('#9f9f9f'))
    editorMessageText:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
    editorMessageText:setPlaceHolder(__('请输入留言'))
    editorMessageText:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
    editorMessageText:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
    editorMessageText:setVisible(true)
    editorMessageText:setMaxLength(40)
    editorMessageText:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    editorMessageText:setTag(BUTTON_CLICK.EDIT_MESSAGE)
    self.viewData = {
        bgLayout = bgLayout ,
        editorMessageText = editorMessageText ,
        sendMessage = sendMessage ,
        gridView = gridView ,
    }

end
--
function MessageBoardView:CreatGridCell(callback)
    local gridViewCell = CGridViewCell:new()
    local cellSize = cc.size(589, 98)
    gridViewCell:setContentSize(cellSize)
    -- 内容展示
    local gridLayout = display.newLayer(cellSize.width/2 , cellSize.height/2,{ ap = display.CENTER , size  = cellSize})
    gridViewCell:addChild(gridLayout)
    -- 背景图片
    local bgImage = display.newImageView(_res('ui/home/infor/personal_information_reply_bg_1.png') ,  cellSize.width/2 , cellSize.height/2)
    gridLayout:addChild(bgImage)
    local playerName = display.newLabel(100, cellSize.height -18 , { ap = display.LEFT_CENTER , color = "#5b3c25" , text = "231111133" , fontSize = 24} )
    gridLayout:addChild(playerName)

    local leaveWordsLabel = display.newRichLabel(100, cellSize.height - 40 ,{ w = 37, ap  = display.LEFT_TOP ,c = {fontWithColor( '6',{ ap = display.LEFT_TOP  , text = "" ,hAlign = display.TAL , w = 370 }) }  }   )
    gridLayout:addChild(leaveWordsLabel)

    -- 删除消息
    local deleteMessage = display.newButton(cellSize.width - 44 ,cellSize.height/2,{ ap = display.CENTER ,
        n = _res('ui/home/infor/friends_btn_empty.png') , s  = _res('ui/home/infor/friends_btn_empty.png')
    })
    deleteMessage:setTag(BUTTON_CLICK.DELETE_MESSAGE)
    gridLayout:addChild(deleteMessage,10)

    local headerNode = require('root.CCHeaderNode').new({bg = _res('ui/home/infor/setup_head_bg_2.png') ,  pre = CommonUtils.GetAvatarFrame(nil) , callback = callback })
    display.commonUIParams(headerNode,{po = cc.p(10, cellSize.height/2 ), ap = display.LEFT_CENTER})
    gridLayout:addChild(headerNode)
    headerNode:setScale(0.56)
    gridLayout:setVisible(false)
    local allDeleteMessage = display.newLayer(cellSize.width/2 , cellSize.height/2 , {
        size = cellSize ,  ap = display.CENTER
    })
    gridViewCell:addChild(allDeleteMessage)

    --local deleteLabel = display.newLabel(cellSize.width/2 , cellSize.height/2 , fontWithColor(14, {
    --    text = __('一键删除') , fontSize = 35
    --}))
    --allDeleteMessage:addChild(deleteLabel)

    local  delAllButton = display.newButton(cellSize.width/2 , cellSize.height, {size=cc.size(589, 60) , scale9 = true ,   ap  = display.CENTER_TOP,  s = _res('ui/home/infor/personal_information_btn_default.png') , n = _res('ui/home/infor/personal_information_btn_select.png') } )
    allDeleteMessage:addChild(delAllButton)
    display.commonLabelParams(delAllButton , fontWithColor(14, {text = __('一键删除') , fontSize = 35 }) )

    gridViewCell.bgImage = bgImage
    gridViewCell.delAllButton = delAllButton
    gridViewCell.allDeletMessage = allDeleteMessage
    gridViewCell.headerNode = headerNode

    gridViewCell.playerName = playerName
    gridViewCell.leaveWordsLabel = leaveWordsLabel
    gridViewCell.deleteMessage = deleteMessage
    gridViewCell.gridLayout = gridLayout
    return gridViewCell

end

-- 没有留言的时候
function MessageBoardView:CreateNoLeaveWords()
    local richLabel = display.newRichLabel(0, 0 ,{ r = true  ,c ={
        {
            img = _res('ui/home/infor/personal_information_ico_reply.png'), scale = 1 , ap = cc.p(0.3, 0.3)
        },
        fontWithColor('14',{text = __('暂无留言') , color = '5b3c25'  })
    }

    })
    return richLabel
end
return MessageBoardView
