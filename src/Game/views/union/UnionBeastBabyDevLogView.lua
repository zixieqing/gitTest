--[[
养育记录弹窗
@params {
    feedPetLog list 数据
}
--]]
local CommonDialog = require('common.CommonDialog')
local UnionBeastBabyDevLogView = class('UnionBeastBabyDevLogView', CommonDialog)

------------ import ------------
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local unionMgr = AppFacade.GetInstance():GetManager("UnionManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
------------ import ------------

------------ define ------------
------------ define ------------

--[[
override
initui
--]]
function UnionBeastBabyDevLogView:InitialUI()

    self.datas = self.args.feedPetLog

    local function CreateView()
        -- bg
        local bg = display.newImageView(_res('ui/common/common_bg_2.png'), 0, 0)
        local size = bg:getContentSize()

        -- base view
        local view = display.newLayer(0, 0, {size = size, ap = cc.p(0.5, 0.5)})
        display.commonUIParams(bg, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        view:addChild(bg, 1)

        -- title
        local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
        display.commonUIParams(titleBg, {po = cc.p(size.width * 0.5, size.height - titleBg:getContentSize().height * 0.5)})
        display.commonLabelParams(titleBg, fontWithColor('14', {text = __('记录'), offset = cc.p(0, -2)}))
        titleBg:setEnabled(false)
        bg:addChild(titleBg)

        -- 空状态
        local emptyCardQScale = 0.5
        local emptyCardQ = AssetsUtils.GetCartoonNode(3, 0, 0)
        display.commonUIParams(emptyCardQ, {po = cc.p(
            view:getContentSize().width * 0.5 + 175,
            view:getContentSize().height * 0.5
        )})
        emptyCardQ:setScale(emptyCardQScale)
        view:addChild(emptyCardQ, 99)

        local emptyTipsBtn = display.newButton(0, 0, {n = _res('ui/common/common_bg_dialogue_tips.png')})
        display.commonUIParams(emptyTipsBtn, {po = cc.p(
            emptyCardQ:getPositionX() - 470 * 0.5 * emptyCardQScale - emptyTipsBtn:getContentSize().width * 0.5 + 35,
            emptyCardQ:getPositionY()
        )})
        display.commonLabelParams(emptyTipsBtn, {text = __('暂无记录'), fontSize = 24, color = '#4c4c4c'})
        view:addChild(emptyTipsBtn, 99)

        local listViewSize = cc.size(size.width, size.height - 52)
        local cellSize = cc.size(listViewSize.width, 115)

        local listView = CTableView:create(listViewSize)
        display.commonUIParams(listView, {ap = cc.p(0.5, 0.5), po = cc.p(
            size.width * 0.5,
            listViewSize.height * 0.5 + 7
        )})
        view:addChild(listView, 5)

        listView:setSizeOfCell(cellSize)
        listView:setCountOfCell(0)
        listView:setDirection(eScrollViewDirectionVertical)
        listView:setDataSourceAdapterScriptHandler(handler(self, self.ListViewDataAdapter))

        -- listView:setBackgroundColor(cc.c4b(0, 128, 255, 100))

        return {
            view = view,
            listView = listView,
            ShowNoLog = function (show)
                emptyCardQ:setVisible(show)
                emptyTipsBtn:setVisible(show)

                listView:setVisible(not show)
            end
        }
    end

    xTry(function ( )
        self.viewData = CreateView( )
    end, __G__TRACKBACK__)

    self:RefreshUI(self.datas)
end
---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
刷新界面
@params data list 数据
--]]
function UnionBeastBabyDevLogView:RefreshUI(data)
    self.datas = data
    self.richlabelc = self:ConvertData2RichLabelC(self.datas)

    self.viewData.ShowNoLog(0 >= #self.richlabelc)
    self.viewData.listView:setCountOfCell(#self.richlabelc)
    self.viewData.listView:reloadData()
end
--[[
data adapter
--]]
function UnionBeastBabyDevLogView:ListViewDataAdapter(c, i)
    local cell = c
    local index = i + 1

    local cellSize = self.viewData.listView:getSizeOfCell()
    local richlabelinfo = self:GetRichLabelInfoByIndex(index)

    local richLabel = nil
    local timeLabel = nil

    if nil == cell then
        cell = CTableViewCell:new()
        cell:setContentSize(cellSize)

        local bg = display.newImageView(_res('ui/union/guild_establish_information_title.png'), 0, 0 , {scale9 = true ,size  = cc.size(cellSize.width-60 ,cellSize.height-8 )})
        display.commonUIParams(bg, {po = cc.p(
            cellSize.width * 0.5,
            cellSize.height * 0.5
        )})
        cell:addChild(bg)

        richLabel = display.newRichLabel(0, 0, {w = 44})
        display.commonUIParams(richLabel, {ap = cc.p(0, 0.5), po = cc.p(
            bg:getPositionX() - bg:getContentSize().width * 0.5 + 20,
            bg:getPositionY()
        )})
        cell:addChild(richLabel)
        richLabel:setTag(3)

        timeLabel = display.newLabel(0, 0, fontWithColor('8', {text = '88h88m88spre'}))
        display.commonUIParams(timeLabel, {ap = cc.p(1, 0.5), po = cc.p(
            bg:getPositionX() + bg:getContentSize().width * 0.5 - 20,
            bg:getPositionY()
        )})
        cell:addChild(timeLabel)
        timeLabel:setTag(5)
    else
        richLabel = cell:getChildByTag(3)
        timeLabel = cell:getChildByTag(5)
    end

    display.reloadRichLabel(richLabel, {c = richlabelinfo.richlabelc})
    timeLabel:setString(richlabelinfo.timeStr)

    return cell
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
处理数据 将数据转换成richLabel显示的字符串
@params data list 源数据
@params c list 字符串数据
--]]
function UnionBeastBabyDevLogView:ConvertData2RichLabelC(data)
    local selfPlayerId = checkint(gameMgr:GetUserInfo().playerId)
    local c = {}

    for i,v in ipairs(data) do
        local needContinue = false
        local c_ = {}

        local beastBabyId = checkint(v.petId)
        local beastBabyFormConfig = cardMgr.GetBeastBabyFormConfig(beastBabyId, 1, 1)

        ------------ 名字 ------------
        if selfPlayerId == checkint(v.playerId) then
            -- 自己
            table.insert(c_, fontWithColor('8', {text = __('你'), fontSize = 22, color = '#f25a17'}))
        else
            -- 别人
            local playerData = unionMgr:GetUnionMemberDataPlayerId(checkint(v.playerId))
            if nil ~= playerData and 0 ~= checkint(playerData.playerId) then
                -- 职位
                local job = checkint(playerData.job)
                local jobConfig = CommonUtils.GetConfig('union', 'job', job)
                if nil ~= jobConfig then
                    table.insert(c_, fontWithColor('6', {text = tostring(jobConfig.name), fontSize = 22}))
                end
                table.insert(c_, fontWithColor('8', {text = tostring(playerData.playerName), fontSize = 22, color = '#2584f0'}))
            else
                needContinue = true
            end
        end
        ------------ 名字 ------------

        ------------ 捐菜信息 ------------
        if not needContinue then
            local foodAmount = 0
            for fid,famount in pairs(v.foods) do
                foodAmount = foodAmount + checkint(famount)
            end
            local petName = tostring(beastBabyFormConfig.name)
            local deltaSatiety = checkint(v.satiety)
            
            table.insert(c_, fontWithColor('6', {text = string.fmt(__('向_name_投食了_num_道菜，增加了'), {['_name_'] = petName, ['_num_'] = foodAmount}), fontSize = 22}))
            table.insert(c_, fontWithColor('8', {text = tostring(deltaSatiety), fontSize = 22, color = '#f25a17'}))
            table.insert(c_, fontWithColor('6', {text = __('点饱食度'), fontSize = 22}))
        end
        ------------ 捐菜信息 ------------

        if not needContinue then

            ------------ 时间 ------------
            local timeData = string.formattedTime(os.time() - v.createTime)
            local str = ''
            if checkint(timeData.h) > 0 then
                local day  = checkint(timeData.h / 24)
                local hours = timeData.h % 24
                if day > 0 then
                    str = string.format(__('%s天'), day)
                end
                if hours > 0 then
                    str = string.format(__('%s%s小时'), str, hours)
                end
            elseif checkint(timeData.m) > 0 then
                str = string.format(__('%s分钟'), timeData.m)
            elseif checkint(timeData.s) > 0  then
                str = string.format(__('%s秒'), timeData.s)
            end
            ------------ 时间 ------------

            table.insert(c, {richlabelc = c_, timeStr = str})
        end
    end

    return c
end
--[[
根据序号获取需要显示的文字信息
@params index int 序号
@return _ table 文字信息
--]]
function UnionBeastBabyDevLogView:GetRichLabelInfoByIndex(index)
    return self.richlabelc[index]
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return UnionBeastBabyDevLogView
