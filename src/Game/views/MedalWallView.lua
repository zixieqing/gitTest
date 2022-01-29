---
--- Created by xingweihao.
--- DateTime: 26/10/2017 7:37 PM
---
---
--- Created by xingweihao.
--- DateTime: 25/10/2017 5:35 PM
---

---@class MedalWallView
local MedalWallView = class('home.MedalWallView',function ()
    local node = CLayout:create( cc.size(603,496)) --cc.size(984,562)
    node.name = 'Game.views.MedalWallView'
    node:enableNodeEvents()
    return node
end)
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local BUTTON_CLICK = {
    ADD_TROPHY_TAG = 1105 , -- 添加奖杯的Tag
    TROPHY_LAYOUT_TAG = 1106 , -- 奖杯内容弄的显示
    TROPHY_LAYOUT_BG = 1107
}

function MedalWallView:ctor()
    self:initUI()
end

function MedalWallView:initUI()
    -- 背景内容
    local bgSize = cc.size(603,496)
    -- 背景内容
    local bgLayout  = display.newLayer(bgSize.width/2-3, bgSize.height/2 + 1 , { ap = display.CENTER , size = bgSize})
    self:addChild(bgLayout)

    local bgImage =   display.newImageView( _res('ui/home/infor/personal_information_badge_bg.png'),bgSize.width/2 ,  bgSize.height/2 )
    bgLayout:addChild(bgImage)
    local contentLayoutSize = cc.size(572,496)
    local contentLayout = display.newLayer(bgSize.width/2, bgSize.height/2  , { ap = display.CENTER , size = contentLayoutSize})
    bgLayout:addChild(contentLayout)
    local sizee = cc.size(contentLayoutSize.width/3 , contentLayoutSize.height/2)
    for  i =1 , 6 do
        local layout = display.newLayer(sizee.width * ((i - 0.5) % 3) , sizee.height  * (2 - math.floor((i - 0.5) /3) - 0.5 ) + 5  , {ap = display.CENTER , size = sizee , color = cc.c4b(0,0,0,0) , enable = true } )
        contentLayout:addChild(layout)
        layout:setTag(i)
        -- 把添加队伍的事件加入到主内容里面
        local TrophyBgImage = display.newImageView(_res('ui/home/infor/personal_information_btn_badge.png') ,sizee.width/2 , sizee.height /2  )
        layout:addChild(TrophyBgImage)
        TrophyBgImage:setTag(BUTTON_CLICK.TROPHY_LAYOUT_BG)
        local TrophyBgImageSize = TrophyBgImage:getContentSize()
        local addTrophyBtn  = display.newButton(TrophyBgImageSize.width/2 , TrophyBgImageSize.height /2  , { n =_res('ui/home/infor/personal_information_ico_badge_add.png'),s =_res('ui/home/infor/personal_information_ico_badge_add.png')  })
        TrophyBgImage:addChild(addTrophyBtn)
        addTrophyBtn:setTag(BUTTON_CLICK.ADD_TROPHY_TAG)
    end

    self.viewData =  {
        bgLayout = bgLayout ,
        bgImage = bgImage,
        contentLayout = contentLayout,
    }
end

return MedalWallView
