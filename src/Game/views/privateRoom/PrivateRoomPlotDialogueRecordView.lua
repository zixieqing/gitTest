--[[
包厢功能 剧情对话记录 view
--]]
local CommonDialog = require('common.CommonDialog')
local PrivateRoomPlotDialogueRecordView = class('PrivateRoomPlotDialogueRecordView', CommonDialog)

local CreateView     = nil
local CreateCell_    = nil

local RES_DIR = {
    BG_JVQING        = _res('ui/privateRoom/guestInfo/viphandbook_bg_jvqing.png'),
    BG_QIPAO         = _res('ui/privateRoom/guestInfo/viphandbook_bg_qipao.png'),
    AVATAR_FRAME_BG  = _res('ui/common/common_avatar_frame_bg'),
    AVATAR_FRAME     = _res('ui/common/common_avatar_frame_default.png'),
}

function PrivateRoomPlotDialogueRecordView:InitialUI()
    self.viewData = CreateView()

    self:initView()
end

function PrivateRoomPlotDialogueRecordView:initView()
    local title   = self.args.title
    self:updateTitle(title)
    
    local storyData = self.args.storyData
    -- logInfo.add(5, tableToString(storyData))
    local npcId    = self.args.npcId
    local guestId    = self.args.guestId
    local dialogueConf = storyData.dialogueConf or {}
    local id = dialogueConf.id
    if id then
        local assistantId = checktable(storyData.dialogue).assistantId
        
        self:updateList(id, guestId, npcId, assistantId)
    end

end

--==============================--
--desc: 更新标题
--@params title  string  标题
--==============================--
function PrivateRoomPlotDialogueRecordView:updateTitle(title)
    local viewData   = self:getViewData()
    local titleLabel = viewData.titleLabel
    display.commonLabelParams(titleLabel, {text = tostring(title)})
end

--==============================--
--desc: 更新标题
--@params storyId  int   剧情id
--@params guestId  int   贵宾id
--@params npcId    int   对话npcid
--@params assistantId  int  服务员id
--==============================--
function PrivateRoomPlotDialogueRecordView:updateList(storyId, guestId, npcId, assistantId)
    local viewData   = self:getViewData()
    local listView = viewData.listView
    local dialogueContent = app.privateRoomMgr:GetGuestDialogueContentByStoryId( storyId ) or {}
    -- logInfo.add(5, tableToString(dialogueContent))
    for i, conf in ipairs(dialogueContent) do
        local headPath = app.privateRoomMgr:GetSpeakerHeadPath(conf.speaker, guestId, npcId, assistantId)
        local cell = CreateCell_(conf, headPath)
        listView:insertNodeAtLast(cell)
    end
    listView:reloadData()
end

CreateView = function ()
    local size = cc.size(539, 595)
    local view = display.newLayer(0, 0, {size = size})
    
    local bg = display.newImageView(RES_DIR.BG_JVQING, size.width / 2, size.height / 2, {ap = display.CENTER})
    view:addChild(bg)

    local titleLabel = display.newLabel(size.width / 2, size.height - 36, 
        fontWithColor(4, {color = '#936441', ap = display.CENTER}))
    view:addChild(titleLabel)

    local listViewSize = cc.size(size.width - 60, size.height - 100)
    local listView = CListView:create(listViewSize)
    listView:setDirection(eScrollViewDirectionVertical)
    display.commonUIParams(listView, {po = cc.p(size.width / 2, size.height - 80), ap = display.CENTER_TOP})
    -- listView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    view:addChild(listView)

    return {
        view       = view,
        titleLabel = titleLabel,
        listView   = listView,
    }
end

CreateCell_ = function (data, headPath)
    local size = cc.size(479, 110)
    local view = display.newLayer(0, 0, {size = size})

    local speaker = checkint(data.speaker)

    local headFrameScale = 0.66
    local headFrame = display.newImageView(RES_DIR.AVATAR_FRAME, 0, 0, {ap = display.CENTER_TOP})
    headFrame:setScale(headFrameScale)

    local headBg = display.newImageView(RES_DIR.AVATAR_FRAME_BG, 0, 0, {ap = display.CENTER})

    local head = display.newImageView(headPath, 0, 0, {ap = display.CENTER})
    head:setScale(0.52)

    local dialogueBgMaxW = 330
    local content = data.content
    local dialogueBgSize = cc.size(261, 50)
    local dialogueBg = display.newImageView(RES_DIR.BG_QIPAO, 0, 0, {scale9 = true, size = dialogueBgSize, ap = display.LEFT_TOP})
    local label = display.newLabel(0, 0, fontWithColor(16, {ap = display.LEFT_TOP, w = 290, text = tostring(content)}))
    local labelSize = display.getLabelContentSize(label)
    if (labelSize.width - 20) > dialogueBgSize.width then
        dialogueBgSize = cc.size(dialogueBgMaxW, labelSize.height + 26)
        dialogueBg:setContentSize(dialogueBgSize)

        if dialogueBgSize.height > size.height then
            size = cc.size(size.width, dialogueBgSize.height + 13)
            view:setContentSize(size)
        end
    end

    display.commonUIParams(headFrame, {po = cc.p(65, size.height - 14)})
    display.commonUIParams(headBg, {po = cc.p(65, headFrame:getPositionY() - 72 * headFrameScale)})
    display.commonUIParams(head, {po = cc.p(65, headFrame:getPositionY() - 72 * headFrameScale)})
    display.commonUIParams(dialogueBg, {po = cc.p(130, size.height - 16)})
    display.commonUIParams(label, {po = cc.p(150, size.height - 26)})

    view:addChild(headFrame)
    view:addChild(headBg)
    view:addChild(head)
    view:addChild(dialogueBg)
    view:addChild(label)
    
    
    return view
end

function PrivateRoomPlotDialogueRecordView:getViewData()
	return self.viewData
end

return PrivateRoomPlotDialogueRecordView