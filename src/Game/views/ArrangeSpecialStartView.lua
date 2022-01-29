local ArrangeSpecialStartView = class('ArrangeSpecialStartView',
	function ()
		local node = CLayout:create(display.size)
		node.name = 'Game.views.ArrangeSpecialStartView'
		node:enableNodeEvents()
		return node
	end
)

local RES_DICT = {
	CELLBG       = _res('ui/home/kitchen/kitchen_bg_food_mastery.png'),
	CONTAINERBG  = _res('ui/home/kitchen/kitchen_bg_food_mastery_words.png'),
	Btn_Normal   = _res("ui/common/common_btn_sidebar_common.png"),
	BTN_SELECT   = _res("ui/common/common_btn_orange.png"),
	FONT_NAME_BG = _res("ui/common/common_title_5.png"),
    TITLE_IMAGE  = _res('ui/home/kitchen/kitchen_specialization_title.png')

}
local uiMgr  = AppFacade.GetInstance():GetManager("UIManager")
function ArrangeSpecialStartView:ctor()
    self.styleData = CommonUtils.GetConfigAllMess('style','cooking')
    self.recipeData = CommonUtils.GetConfigAllMess('recipe','cooking')
    self.cellsDatas = {}
    self:initUi()
end
function ArrangeSpecialStartView:initUi()
   local bgLayout = CLayout:create(display.size)
    bgLayout:setPosition(cc.p(display.cx, display.cy))
    local closeView = display.newLayer(display.cx ,display.cy , { ap = display.CENTER , color = cc.c4b(0,0,0 ,150) ,enable = true })

    self:addChild(closeView)
    bgLayout:setName('bgLayout')
    self:addChild(bgLayout)
    -- 头标题
    local titleImage = display.newImageView(RES_DICT.TITLE_IMAGE ,display.cx , display.cy+ 280  )
    local titleSize = titleImage:getContentSize()

    local titleLabel = display.newLabel(titleSize.width/2 , titleSize.height/2,fontWithColor(19, { text = __('选择你的起始料理专精')}) )
    bgLayout:addChild(titleImage)
    titleImage:addChild(titleLabel)
   
    local count    = table.nums(self.styleData)
    local listSize = cc.size(420*3,485)
    local  listView = CLayout:create(listSize)
    bgLayout:addChild(listView)
    listView:setName('listView')
    listView:setPosition(cc.p(display.cx , display.cy -40))

    local count = 0 
    for k , v in pairs(self.styleData) do
        if checkint(v.initial) == 1  and checkint(v.id) <= 3   then
            count = count +1 
            self.cellsDatas[#self.cellsDatas+1] = self:createCellView(v)
            self.cellsDatas[#self.cellsDatas].listCell:setPosition(cc.p(420*(count - 0.5 ) ,listSize.height/2 ))
            self.cellsDatas[#self.cellsDatas].listCell:setName(string.format('Cell_%d',k))
            listView:addChild( self.cellsDatas[#self.cellsDatas].listCell)
        end
    end
    self.bgLayout = bgLayout 
    self.closeView = closeView
end
function ArrangeSpecialStartView:createCellView(data)
    local name = data.name
    local contentName =  data.content

    local recipStartName =  ""
    --local bgImage = display.newImageView(RES_DICT.CELLBG , 0,0)
    local bgImage = display.newImageView(_res(string.format("ui/home/kitchen/kitchen_bg_food_mastery_%d.png" , checkint(data.id)) ))
    
    local bgSize = cc.size(380,485)
    local bgLayout = CLayout:create(bgSize)
    bgLayout:addChild(bgImage)
    bgLayout:setName('CellBg')
    bgImage:setPosition(cc.p(bgSize.width/2 ,bgSize.height/2))
    local arrangeSpecialLabel = display.newLabel(bgSize.width/2, bgSize.height - 60 , fontWithColor('14', {fontSize = 22 , color = "#5b3c25",text = name , outline  = false}) )
    bgLayout:addChild(arrangeSpecialLabel)

    local contentBgName = display.newImageView(RES_DICT.CONTAINERBG ,bgSize.width/2 ,bgSize.height - 88 , {scale9 =true, size = cc.size(315,115), ap = display.CENTER_TOP }  )
    bgLayout:addChild(contentBgName)
    local contentBgSize = contentBgName:getContentSize()

    local contentLabel =  display.newLabel(contentBgSize.width/2, contentBgSize.height - 10 , fontWithColor('6',{ fontSize = 20,text = contentName ,color = "#91591e", hAlign = display.TAL,w = 295}))
    local contentLabelSize = display.getLabelContentSize(contentLabel)
    local contentLayout = display.newLayer(0,0,{size = contentLabelSize,ap = display.CENTER_TOP  })
    contentLayout:addChild(contentLabel)
    contentLabel:setPosition(contentLabelSize.width/2 ,contentLabelSize.height/2)


    local contentList = CListView:create( cc.size(305,105))
    contentList:setDirection(eScrollViewDirectionVertical)
    contentList:setAnchorPoint(display.CENTER_TOP)
    contentList:setPosition(bgSize.width/2+5 ,bgSize.height - 95)
    bgLayout:addChild(contentList)
    contentList:insertNodeAtLast(contentLayout)
    contentList:reloadData()

    local titileBtn = display.newButton(bgSize.width/2 , bgSize.height - 235 , { n = RES_DICT.FONT_NAME_BG ,enable = false })
    bgLayout:addChild(titileBtn)
    display.commonLabelParams(titileBtn,fontWithColor('6', {fontSize = 20, text =  __('入门菜品')}))
    local selecctBtn = display.newButton(bgSize.width/2 , bgSize.height - 395 , { n = RES_DICT.BTN_SELECT ,enable = true})
    bgLayout:addChild(selecctBtn)
    local recipeData = CommonUtils.GetConfigAllMess('recipe','cooking')
    local goodsId = recipeData[ data.initialRecipe[1]].foods[1].goodsId
    local goodNode = require('common.GoodNode').new({id = goodsId, amount = 1, showAmount = false})
    display.commonUIParams(goodNode, {animate = false, cb = function (sender)
         uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = goodsId, type = 1})
    end})
    goodNode:setScale(0.8)
    goodNode:setAnchorPoint(cc.p(0.5,0.5))
    goodNode:setPosition(cc.p(bgSize.width/2 , bgSize.height  - 305 ))
    bgLayout:addChild(goodNode)
    display.commonLabelParams(selecctBtn,fontWithColor('14', { text = __('选择') }))
    selecctBtn:setTag(tonumber(data.id))
    selecctBtn:setName('Button')
    selecctBtn:setOnClickScriptHandler(handler(self,self.buttonAction))
    local listCell = CLayout:create(cc.size(400,600))
    listCell:addChild(bgLayout)
    bgLayout:setPosition(200,300)
    return { 
        selecctBtn = selecctBtn ,
        view = bgLayout,
        listCell  = listCell,
    }
end

function ArrangeSpecialStartView:buttonAction(sender)
    PlayAudioByClickNormal()
    sender:setEnabled(true)
    local  tag = sender:getTag()
    AppFacade.GetInstance():DispatchObservers("SELECT_STYLE_RECIPE", {cookingStyleId = tag })
end

return ArrangeSpecialStartView
