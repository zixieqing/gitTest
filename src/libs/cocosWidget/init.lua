---@class ccw
ccw = ccw or {}


---@class ccw.WIDGET_TOUCH_MODEL
ccw.WIDGET_TOUCH_MODEL = {
	NONE      = 0,  -- no need to handle evnet
	TRANSIENT = 1,  -- need to handle a while, the parent layout can interrupt me.
	SUSTAINED = 2,  -- need handle event forever, interrupt self only
}


---@class ccw.PROGRESS_BAR_DIRECTION
ccw.PROGRESS_BAR_DIRECTION = {
	LEFT_TO_RIGHT = 0,
	RIGHT_TO_LEFT = 1,
	BOTTOM_TO_TOP = 2,
	TOP_TO_BOTTOM = 3,
}


---@class ccw.PROGRESS_BAR_LABEL_FORMAT
ccw.PROGRESS_BAR_LABEL_FORMAT = {
	PERCENT = 0,
	RATIO   = 1,
}


---@class ccw.SCROLL_VIEW_DIRECTION
ccw.SCROLL_VIEW_DIRECTION = {
	HORIZONTAL = 0,
	VERTICAL   = 1,
	BOTH       = 2,
}


--[[
	用 `ccw.xx = ccw.xx or xx` 的方式声明，是为了让lua文件重载后，全局声明保持继承。
	因为`Cxx`是c++层的声明，要保持引用不能丢失和改写。
]]

---@type CWidgetWindow @ 窗口控件
ccw.CWidgetWindow = ccw.CWidgetWindow or CWidgetWindow

---@type CScale9Sprite @ 九宫精灵
ccw.CScale9Sprite = ccw.CScale9Sprite or CScale9Sprite

---@type CProgressBar @ 进度条控件
ccw.CProgressBar = ccw.CProgressBar or CProgressBar

---@type CWidget @ 基础控件
ccw.CWidget = ccw.CWidget or CWidget

---@type CLayout @ 基础容器控件
ccw.CLayout = ccw.CLayout or CLayout

---@type CScrollView @ 基础滚动容器控件
ccw.CScrollView = ccw.CScrollView or CScrollView

---@type CScrollViewContainer @ 基础滚动容器控件 的容器
ccw.CScrollViewContainer = ccw.CScrollViewContainer or CScrollViewContainer

---@type CListView @ 列表滚动容器控件
ccw.CListView = ccw.CListView or CListView

---@type CExpandableListView @ 可伸展列表滚动容器控件
ccw.CExpandableListView = ccw.CExpandableListView or CExpandableListView

---@type CExpandableNode @ 可伸展列表滚动容器控件 的节点
ccw.CExpandableNode = ccw.CExpandableNode or CExpandableNode

---@type CGridView @ 网格列表滚动容器控件
ccw.CGridView = ccw.CGridView or CGridView

---@type CGridViewCell @ 网格列表滚动容器控件 的节点
ccw.CGridViewCell = ccw.CGridViewCell or CGridViewCell

---@type CTableView @ 表格列表滚动容器控件
ccw.CTableView = ccw.CTableView or CTableView

---@type CTableViewCell @ 表格列表滚动容器控件 的节点
ccw.CTableViewCell = ccw.CTableViewCell or CTableViewCell

---@type CPageView @ 页面滚动容器控件
ccw.CPageView = ccw.CPageView or CPageView

---@type CPageViewCell @ 页面滚动容器控件 的节点
ccw.CPageViewCell = ccw.CPageViewCell or CPageViewCell

---@type CGridPageView @ 网格页面滚动容器控件
ccw.CGridPageView = ccw.CGridPageView or CGridPageView

---@type CGridPageViewPage @ 网格页面滚动容器控件 的单页节点
ccw.CGridPageViewPage = ccw.CGridPageViewPage or CGridPageViewPage

---@type CGridPageViewCell @ 网格页面滚动容器控件 的网格节点
ccw.CGridPageViewCell = ccw.CGridPageViewCell or CGridPageViewCell

---@type CColorView @ 纯色块节点控件
ccw.CColorView = ccw.CColorView or CColorView

---@type CGradientView @ 渐变色块节点控件
ccw.CGradientView = ccw.CGradientView or CGradientView

---@type CButton @ 按钮控件
ccw.CButton = ccw.CButton or CButton

---@type CToggleView @ 开关控件
ccw.CToggleView = ccw.CToggleView or CToggleView

---@type CSlider @ 滑块控件
ccw.CSlider = ccw.CSlider or CSlider

---@type CCheckBox @ 选择框控件
ccw.CCheckBox = ccw.CCheckBox or CCheckBox

---@type CImageView @ 图片控件
ccw.CImageView = ccw.CImageView or CImageView

---@type CImageViewScale9 @ 九宫图片控件
ccw.CImageViewScale9 = ccw.CImageViewScale9 or CImageViewScale9

---@type CTextRich @ 富文本控件
ccw.CTextRich = ccw.CTextRich or CTextRich

---@type CLabel @ 文字控件
ccw.CLabel = ccw.CLabel or CLabel

---@type CLabelAtlas @ 文字图块控件
ccw.CLabelAtlas = ccw.CLabelAtlas or CLabelAtlas

---@type CLabelBMFont @ 图集文字控件
ccw.CLabelBMFont = ccw.CLabelBMFont or CLabelBMFont
