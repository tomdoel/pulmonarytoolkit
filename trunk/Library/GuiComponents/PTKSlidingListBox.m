classdef PTKSlidingListBox < PTKSlidingPanel
    % PTKSlidingListBox. A scolling listbox
    %
    %     PTKSlidingListBox is a scrolling panel containing a PTKListBox.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    methods
        function obj = PTKSlidingListBox(parent, reporting)
            obj = obj@PTKSlidingPanel(parent, reporting);
            
            obj.FloatingPanel = PTKListBox(obj, reporting);
            obj.AddChild(obj.FloatingPanel, obj.Reporting);
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
        
        function ClearItems(obj)
            obj.FloatingPanel.ClearItems;
        end
        
        function AddItem(obj, item)
            obj.FloatingPanel.AddItem(item);
        end
        
        function list_box_handle = GetListBox(obj)
            list_box_handle = obj.FloatingPanel;
        end
    end
end