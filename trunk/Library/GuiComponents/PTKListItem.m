classdef PTKListItem < PTKVirtualPanel
    % PTKListItem. An item in a PTKListBox
    %
    %     Each item in a PTKListBox is of this type, and consists of one or more
    %     text items.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        TextHeight = 23
    end

    properties (SetAccess = private)
        Tag
        TextItems
    end
    
    methods
        function obj = PTKListItem(parent, tag, reporting)
            obj = obj@PTKVirtualPanel(parent, reporting);
            obj.Tag = tag;
            obj.TextItems = PTKText.empty;
        end
        
        function AddTextItem(obj, text_item, reporting)
            obj.AddChild(text_item, reporting);
            obj.TextItems(end + 1) = text_item;
            
            obj.AddEventListener(text_item, 'TextClicked', @obj.ItemLeftClicked);
            obj.AddEventListener(text_item, 'TextRightClicked', @obj.ItemRightClicked);
        end
        
        function Select(obj, selected)
            for item_index = 1 : numel(obj.TextItems)
                obj.TextItems(item_index).Select(selected);
            end
        end
        
        function Highlight(obj, highlighted)
            for item_index = 1 : numel(obj.TextItems)
                obj.TextItems(item_index).Highlight(highlighted);
            end
        end
        
        function Resize(obj, location)
            Resize@PTKVirtualPanel(obj, location);
            
            for text_item = obj.TextItems
                text_item.Resize(location);
            end            
        end
        
        function height = GetRequestedHeight(obj, width)
            height = obj.TextHeight;
        end
    end
    
    methods (Access = protected)
        function input_has_been_processed = MouseHasMoved(obj, click_point, selection_type, src)
            % This method is called when the mouse is moved

            obj.Highlight(true);
            input_has_been_processed = true;
        end

        function input_has_been_processed = MouseExit(obj, click_point, selection_type, src)
            % This method is called when the mouse exits a control which previously
            % processed a MouseHasMoved event
            
            obj.Highlight(false);
            input_has_been_processed = true;
        end
        
        function ItemLeftClicked(obj, ~, ~)
            obj.Parent.Deselect;
            obj.Select(true);
        end
        
        function ItemRightClicked(obj, ~, ~)
        end
        
        function SetContextMenu(obj, context_menu)
            for text_item = obj.TextItems
                set(text_item.GraphicalComponentHandle, 'uicontextmenu', context_menu);
            end
        end
    end
end