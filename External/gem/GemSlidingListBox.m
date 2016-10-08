classdef GemSlidingListBox < GemSlidingPanel
    % GemSlidingListBox GEM class for a scrolling panel containing a GemListBox.
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    methods
        function obj = GemSlidingListBox(parent)
            obj = obj@GemSlidingPanel(parent);
            
            obj.FloatingPanel = GemListBox(obj);
            obj.AddChild(obj.FloatingPanel);
        end
        
        function SetBorders(obj, left, right, top, bottom, spacing_between_items)
            obj.FloatingPanel.SpacingBetweenItems = spacing_between_items;
            obj.FloatingPanel.TopMargin = top;
            obj.FloatingPanel.BottomMargin = bottom;
            obj.FloatingPanel.LeftMargin = left;
            obj.FloatingPanel.RightMargin = right;
        end
        
        function height = GetRequestedHeight(obj, width)
            height = obj.FloatingPanel.GetRequestedHeight(width);
        end
        
        function SelectItem(obj, tag, selected)
            obj.FloatingPanel.SelectItem(tag, selected);
            
            if ~isempty(tag)
                [min_y_from_base, max_y_from_base] = obj.FloatingPanel.GetYPositionForItem(tag);
                
                if ~isempty(obj.Position) && ~isempty(min_y_from_base)
                    fp_height = obj.FloatingPanel.GetRequestedHeight(obj.Position(3));
                    min_y = fp_height - max_y_from_base;
                    max_y = fp_height - min_y_from_base;
                    
                    obj.ScrollToShow(min_y, max_y);
                end
            end
        end

        function id = GetNextItemId(obj)
            id = obj.FloatingPanel.GetNextItemId;
        end

        function id = GetPreviousItemId(obj)
            id = obj.FloatingPanel.GetPreviousItemId;
        end
        
        function ClearItems(obj)
            obj.FloatingPanel.ClearItems;
        end
        
        function AddItem(obj, item)
            obj.FloatingPanel.AddItem(item);
        end
        
        function list_box_handle = GetListBox(obj)
            list_box_handle = obj.FloatingPanel;
        end
                
        function num_items = NumItems(obj)
            num_items = obj.FloatingPanel.NumItems;
        end
        
        function item = GetItem(obj, tag)
            item = obj.FloatingPanel.GetItem(tag);
        end
    end
end