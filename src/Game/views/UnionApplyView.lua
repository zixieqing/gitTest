---
--- Created by xingweihao.
--- DateTime: 25/10/2017 5:35 PM
---
---@class UnionApplyView
local UnionApplyView = class('home.UnionApplyView',function ()
    local node = CLayout:create( cc.size(1139,639))
    node.name = 'Game.views.UnionApplyView'
    node:enableNodeEvents()
    return node
end)
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local BUTTON_CLICK = {
    MEDAL_HONOR = 1009 , -- 勋章墙
    ENTERTAIN   = 1010 , -- 飨灵屋
    MESSAGE_BOARD = 1011 , -- 留言板
    CHANGE_DECR_TEXT = 1102 , -- 修改玩家的签名
    CHANGE_PLAYER_NAME  = 1103 , -- 修改玩家的签名
    CHANGE_PLAYER_HEADER = 1104 , -- 修改玩家的头像
    CHANGE_DECR = 1105 ,
    BINDING_TELL_NUM = 1106 , -- 绑定手机号
    THUMB_UP        = 1107 , --点赞按钮
    CHANGE_LAYOUT_TAG = 1108,--修改的layout
    CHANGE_HEAD = 1109,      -- 修改头像
    CHANGE_HEAD_FRAME = 1110, -- 修改头像框
    CHANGE_BG_CLOSE_LAYOUT = 1111 , -- 关闭修改layout

}

function UnionApplyView:ctor()
    self:initUI()
end

function UnionApplyView:initUI()
    local bgSize =  cc.size(1139,639)
    local bgLayout = display.newLayer(bgSize.width/2 , bgSize.height/2 , { ap = display.CENTER , size  = bgSize , color1 = cc.r4b() ,enable = true ,
       cb = function ()
           self:removeFromParent()
       end
    })
    local layoutSize = cc.size(1080,578)
    local layout = display.newLayer(bgSize.width/2 -3, 15,
                                    { ap =  display.CENTER_BOTTOM , size = layoutSize  , color1 = cc.r4b(), enable = true , cb = function ()
                                        self:removeFromParent()
                                    end})
    bgLayout:addChild(layout)
    self:addChild(bgLayout)

    local topSize = cc.size(1080, 60)
    -- 顶部的layout
    local topLayer =display.newLayer(layoutSize.width/2, layoutSize.height ,
                                     { ap =  display.CENTER_TOP , size = topSize  , color1 = cc.r4b(), enable = true })
    layout:addChild(topLayer)

    local narrateLabel = display.newLabel(0 ,  topSize.height/2 ,
         fontWithColor('16' , {ap = display.LEFT_CENTER , text = __('申请条目数量最多容纳100条，达到上限后无法接受新的申请')  }) )
    topLayer:addChild(narrateLabel)
    -- 申请设置
    local applySetUpBtn =  display.newButton(topSize.width   ,topSize.height/2 ,{
        ap = display.RIGHT_CENTER ,
        n = _res('ui/tower/library/btn_selection_unused.png')
    })
    display.commonLabelParams(applySetUpBtn , fontWithColor('18' ,{ text = __('申请设置')}))
    topLayer:addChild(applySetUpBtn)

    local bottomSize = cc.size(1080, 520)
    -- 底部的layout
    local bottomLayout = display.newLayer(layoutSize.width/2 , bottomSize.height -3 ,
          {ap = display.CENTER_TOP , size = bottomSize ,color1 = cc.r4b() })
    layout:addChild(bottomLayout)
    --
    local bgImage = display.newImageView(_res('ui/union/guild_establish_information_search_list_bg'),
                                         bottomSize.width/2 ,bottomSize.height/2 ,{ size = cc.size(1080 , 520 ) , scale9 = true })
    bottomLayout:addChild(bgImage)




    local grideSize = bottomSize
    local gridView = CGridView:create(grideSize)
    gridView:setSizeOfCell(cc.size(540,148))
    gridView:setColumns(2)
    bottomLayout:addChild(gridView)
    gridView:setAnchorPoint(cc.p(0.5, 0.5))
    gridView:setPosition(cc.p(grideSize.width/2, grideSize.height/2))
    -- 删除消息
    local deleteMessage = display.newButton(20,20,{ ap = display.CENTER ,
                                                  n = _res('ui/home/infor/friends_btn_empty.png') , s  = _res('ui/home/infor/friends_btn_empty.png')
    })
    display.commonLabelParams(deleteMessage , fontWithColor('14' ,{ offset = cc.p(0, -35) , fontSize = 22  ,text =__('全部拒绝'),reqW = 130}))
    bgLayout:addChild(deleteMessage)
    local richLabel = display.newRichLabel(bgSize.width/2, bgSize.height/2 ,{ r = true  ,c ={
        {
            img = _res('ui/home/infor/personal_information_ico_reply.png'), scale = 1 , ap = cc.p(0.3, 0.3)
        },
        fontWithColor('14',{text = __('暂无任何申请请求') , color = '5b3c25'  })
    }
    })
    richLabel:setVisible(false)
    bgLayout:addChild(richLabel)
    self.viewData = {
        gridView      = gridView,
        richLabel     = richLabel,
        bgLayout      = bgLayout,
        applySetUpBtn = applySetUpBtn,
        deleteMessage = deleteMessage
    }
end

function UnionApplyView:CreateGridCell()
    local gridCell = CGridViewCell:new()
    local bgImage = display.newImageView(_res('ui/union/guild_apply_bg'))
    local grideSize = cc.size(540, 148)
    gridCell:setContentSize(grideSize)
    local bgSize = bgImage:getContentSize()
    local bgLayout =  display.newLayer(grideSize.width/2 , grideSize.height/2, {size= bgSize , ap = display.CENTER })
    gridCell:addChild(bgLayout)
    bgImage:setPosition(cc.p(bgSize.width/2 ,bgSize.height/2))
    bgLayout:addChild(bgImage)

    local headerNode = require('root.CCHeaderNode').new(
            {bg = _res('ui/home/infor/setup_head_bg_2.png') , pre =  gameMgr:GetUserInfo().avatarFrame , isPre = true })
    display.commonUIParams(headerNode,{po = cc.p(10 ,bgSize.height/2), ap = display.LEFT_CENTER})
    bgLayout:addChild(headerNode)
    headerNode:setScale(0.8)
    -- 玩家名称
    local playerName = display.newLabel( 140 ,  bgSize.height/2 + 45  ,
                                         fontWithColor('16' , {ap = display.LEFT_CENTER ,text = "" }) )
    bgLayout:addChild(playerName)
    -- 玩家等级
    local playerLevel = display.newLabel(140 ,  bgSize.height/2 + 10,
                                         fontWithColor('16' , {ap = display.LEFT_CENTER , text = ""  }) )
    bgLayout:addChild(playerLevel)
    -- 退出工会的按钮
    local passBtn = display.newButton(bgSize.width - 70   ,bgSize.height/2 - 35,{
        n = _res('ui/common/common_btn_orange.png'),ap = display.CENTER
    })
    bgLayout:addChild(passBtn)
    display.commonLabelParams(passBtn , fontWithColor('14' ,{ text = __('通过')}))
    --拒绝按钮
    local refuseBtn =  display.newButton(bgSize.width - 70   ,bgSize.height/2 + 35,{
        n = _res('ui/common/common_btn_white_default.png'),ap = display.CENTER
    })
    bgLayout:addChild(refuseBtn)
    display.commonLabelParams(refuseBtn , fontWithColor('14' ,{ text = __('拒绝')}))
    gridCell.refuseBtn   = refuseBtn
    gridCell.headerNode  = headerNode
    gridCell.playerName  = playerName
    gridCell.playerLevel = playerLevel
    gridCell.passBtn     = passBtn
    gridCell.refuseBtn   = refuseBtn
    return gridCell
end
-- 没有留言的时候
function UnionApplyView:CreateNoLeaveWords()

    return richLabel
end
return UnionApplyView
