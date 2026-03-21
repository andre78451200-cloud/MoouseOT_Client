-- @docclass
UIScrollArea = extends(UIWidget, 'UIScrollArea')

-- Função auxiliar para encontrar um widget por ID de forma recursiva nos pais
local function findWidgetInParents(startWidget, widgetId)
    local current = startWidget
    while current do
        local widget = current:getChildById(widgetId)
        if widget then
            return widget
        end
        current = current:getParent()
    end
    return nil
end

-- Lista de scrollbars conhecidos que podem não existir (para evitar spam no console)
local optionalScrollbars = {
    ['ListBadgeScrollbar'] = true,
    ['preyScrollBar'] = true,
    ['taskHuntingScrollBar'] = true,
    ['miniwindowScrollBar'] = true
}

-- public functions
function UIScrollArea.create()
    local scrollarea = UIScrollArea.internalCreate()
    scrollarea:setClipping(true)
    scrollarea.inverted = false
    scrollarea.alwaysScrollMaximum = false
    return scrollarea
end

function UIScrollArea:onStyleApply(styleName, styleNode)
    for name, value in pairs(styleNode) do
        if name == 'vertical-scrollbar' then
            addEvent(function()
                -- Busca o scrollbar no parent atual e nos pais superiores
                local scrollbar = findWidgetInParents(self, value)
                if scrollbar then
                    self:setVerticalScrollBar(scrollbar)
                else
                    -- Só mostra warning se não for um scrollbar opcional conhecido
                    if not optionalScrollbars[value] then
                        print("UIScrollArea: vertical-scrollbar with id '" .. value .. "' not found in parent hierarchy")
                    end
                end
            end)
        elseif name == 'horizontal-scrollbar' then
            addEvent(function()
                -- Busca o scrollbar no parent atual e nos pais superiores
                local scrollbar = findWidgetInParents(self, value)
                if scrollbar then
                    self:setHorizontalScrollBar(scrollbar)
                else
                    -- Só mostra warning se não for um scrollbar opcional conhecido
                    if not optionalScrollbars[value] then
                        print("UIScrollArea: horizontal-scrollbar with id '" .. value .. "' not found in parent hierarchy")
                    end
                end
            end)
        elseif name == 'inverted-scroll' then
            self:setInverted(value)
        elseif name == 'always-scroll-maximum' then
            self:setAlwaysScrollMaximum(value)
        end
    end
end

function UIScrollArea:updateScrollBars()
    local scrollWidth = math.max(self:getChildrenRect().width - self:getPaddingRect().width, 0)
    local scrollHeight = math.max(self:getChildrenRect().height - self:getPaddingRect().height, 0)

    local scrollbar = self.verticalScrollBar
    if scrollbar then
        if self.inverted then
            scrollbar:setMinimum(-scrollHeight)
            scrollbar:setMaximum(0)
        else
            scrollbar:setMinimum(0)
            scrollbar:setMaximum(scrollHeight)
        end
    end

    local scrollbar = self.horizontalScrollBar
    if scrollbar then
        if self.inverted then
            scrollbar:setMinimum(-scrollWidth)
            scrollbar:setMaximum(0)
        else
            scrollbar:setMinimum(0)
            scrollbar:setMaximum(scrollWidth)
        end
    end

    if self.lastScrollWidth ~= scrollWidth then
        self:onScrollWidthChange()
    end
    if self.lastScrollHeight ~= scrollHeight then
        self:onScrollHeightChange()
    end

    self.lastScrollWidth = scrollWidth
    self.lastScrollHeight = scrollHeight
end

function UIScrollArea:setVerticalScrollBar(scrollbar)
    if not scrollbar then
        return
    end
    
    self.verticalScrollBar = scrollbar
    connect(self.verticalScrollBar, 'onValueChange', function(scrollbar, value)
        local virtualOffset = self:getVirtualOffset()
        virtualOffset.y = value
        self:setVirtualOffset(virtualOffset)
        signalcall(self.onScrollChange, self, virtualOffset)
    end)
    self:updateScrollBars()
end

function UIScrollArea:setHorizontalScrollBar(scrollbar)
    if not scrollbar then
        return
    end
    
    self.horizontalScrollBar = scrollbar
    connect(self.horizontalScrollBar, 'onValueChange', function(scrollbar, value)
        local virtualOffset = self:getVirtualOffset()
        virtualOffset.x = value
        self:setVirtualOffset(virtualOffset)
        signalcall(self.onScrollChange, self, virtualOffset)
    end)
    self:updateScrollBars()
end

function UIScrollArea:setInverted(inverted)
    self.inverted = inverted
end

function UIScrollArea:setAlwaysScrollMaximum(value)
    self.alwaysScrollMaximum = value
end

function UIScrollArea:onLayoutUpdate()
    self:updateScrollBars()
end

function UIScrollArea:onMouseWheel(mousePos, mouseWheel)
    if self.verticalScrollBar then
        if not self.verticalScrollBar:isOn() then
            return false
        end
        if mouseWheel == MouseWheelUp then
            local minimum = self.verticalScrollBar:getMinimum()
            if self.verticalScrollBar:getValue() <= minimum then
                return false
            end
            self.verticalScrollBar:decrement()
        else
            local maximum = self.verticalScrollBar:getMaximum()
            if self.verticalScrollBar:getValue() >= maximum then
                return false
            end
            self.verticalScrollBar:increment()
        end
    elseif self.horizontalScrollBar then
        if not self.horizontalScrollBar:isOn() then
            return false
        end
        if mouseWheel == MouseWheelUp then
            local maximum = self.horizontalScrollBar:getMaximum()
            if self.horizontalScrollBar:getValue() >= maximum then
                return false
            end
            self.horizontalScrollBar:increment()
        else
            local minimum = self.horizontalScrollBar:getMinimum()
            if self.horizontalScrollBar:getValue() <= minimum then
                return false
            end
            self.horizontalScrollBar:decrement()
        end
    end
    return true
end

function UIScrollArea:ensureChildVisible(child)
    if child then
        local paddingRect = self:getPaddingRect()
        if self.verticalScrollBar then
            local deltaY = paddingRect.y - child:getY()
            if deltaY > 0 then
                self.verticalScrollBar:decrement(deltaY)
            end

            deltaY = (child:getY() + child:getHeight()) - (paddingRect.y + paddingRect.height)
            if deltaY > 0 then
                self.verticalScrollBar:increment(deltaY)
            end
        elseif self.horizontalScrollBar then
            local deltaX = paddingRect.x - child:getX()
            if deltaX > 0 then
                self.horizontalScrollBar:decrement(deltaX)
            end

            deltaX = (child:getX() + child:getWidth()) - (paddingRect.x + paddingRect.width)
            if deltaX > 0 then
                self.horizontalScrollBar:increment(deltaX)
            end
        end
    end
end

function UIScrollArea:onChildFocusChange(focusedChild, oldFocused, reason)
    if focusedChild and (reason == MouseFocusReason or reason == KeyboardFocusReason) then
        self:ensureChildVisible(focusedChild)
    end
end

function UIScrollArea:onScrollWidthChange()
    if self.alwaysScrollMaximum and self.horizontalScrollBar then
        self.horizontalScrollBar:setValue(self.horizontalScrollBar:getMaximum())
    end
end

function UIScrollArea:onScrollHeightChange()
    if self.alwaysScrollMaximum and self.verticalScrollBar then
        self.verticalScrollBar:setValue(self.verticalScrollBar:getMaximum())
    end
end