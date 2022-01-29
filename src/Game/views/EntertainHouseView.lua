---
--- Created by xingweihao.
--- DateTime: 25/10/2017 3:29 PM
---
---@class EntertainHouseView
local EntertainHouseView = class('home.EntertainHouseView',function ()
    local node = CLayout:create(  cc.size(603,496) ) --cc.size(984,562)
    node.name = 'Game.views.EntertainHouseView'
    node:enableNodeEvents()
    return node
end)
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local contentTag = 1114 -- 内容的tag 值
local addCardTag = 1115 -- 添加卡牌的内容
local addTeamTag = 1116 -- 添加任务小加好显示
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
function EntertainHouseView:ctor()
    self:initUI()
end

function EntertainHouseView:initUI()
    local bgSize = cc.size(603,496)
    -- 背景内容
    local bgLayout  = display.newLayer(bgSize.width/2-3, bgSize.height/2 + 1 , { ap = display.CENTER , size = bgSize})
    self:addChild(bgLayout)

    local bgImage =   display.newImageView( _res('ui/home/infor/personal_information_bg_card.png'),bgSize.width/2 ,  bgSize.height/2 )
    bgLayout:addChild(bgImage)
    local sizee = cc.size(bgSize.width/3 , bgSize.height/2)
    local addLayoutSize  = cc.size(149 ,166 )
    for  i =1 , 6 do
        local layout = display.newLayer(sizee.width * ((i - 0.5) % 3) , sizee.height  * (2 - math.floor((i - 0.5) /3) - 0.5 )   , {ap = display.CENTER , size = sizee} )
        bgLayout:addChild(layout)
        layout:setTag(i)
        -- 把添加队伍的事件加入到主内容里面
        local personBaseImage =  display.newImageView( _res('ui/home/lobby/peopleManage/restaurant_manage_bg_people_base.png'), addLayoutSize.width/2 , 0 , { ap = display.CENTER_BOTTOM})
        local teamImage =   display.newImageView( _res('ui/tower/path/tower_btn_team_add.png') , addLayoutSize.width/2 ,addLayoutSize.height -20,{ap = display.CENTER_TOP })
        local petAddImage =   display.newImageView( _res('ui/common/maps_fight_btn_pet_add.png') , addLayoutSize.width/2,addLayoutSize.height,{ap = display.CENTER })
        local teamImageSize = teamImage:getContentSize()
        teamImage:setScale(0.8)
        personBaseImage:setScale(0.8)
        petAddImage:setPosition(cc.p(teamImageSize.width/2 , teamImageSize.height/2 +5))
        teamImage:addChild(petAddImage)
        teamImage:setTag(addTeamTag)
        --teamImage:setVisible(false)
        -- 添加队伍
        local addLayout = display.newLayer(sizee.width/2-5  , 27  , { ap = display.CENTER_BOTTOM, size = addLayoutSize , color = cc.c4b(0,0,0,0) ,enable = true  })
        addLayout:addChild(personBaseImage)
        addLayout:addChild(teamImage)
        layout:addChild(addLayout)
        addLayout:setTag(addCardTag)
    end

    self.viewData =  {
        bgLayout = bgLayout ,
        bgImage = bgImage,
    }
end
-- 创建飨灵

return EntertainHouseView