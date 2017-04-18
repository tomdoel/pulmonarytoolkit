classdef GemListBoxWithTitle < GemPanel
    % GemListBoxWithTitle. A GEM scrolling listbox object with a title and add/remove buttons
    %
    %     GemListBoxWithTitle consists of a title panel with controls and a list box
    %     underneath
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        TitleLeftPadding = 0
    end
    
    properties (Access = protected)
        TitlePanel
        LowerPanel
        ListBox
    end
    
    properties (Constant, Access = private)
        ControlPanelHeight = 20
        LowerPanelHeight = 20
        LeftMargin = 0
        RightMargin = 0
        TopMargin = 0
        BottomMargin = 0
        InnerLeftMargin = 15
        InnerRightMargin = 5
        InnerTopMargin = 0
        InnerBottomMargin = 0
        SpacingBetweenItems = 1
    end
    
    methods
        function obj = GemListBoxWithTitle(parent, title_text, add_button_tooltip, delete_button_tooltip)
            obj = obj@GemPanel(parent);

            obj.ListBox = GemSlidingListBox(obj);
            obj.ListBox.SetBorders(obj.InnerLeftMargin, obj.InnerRightMargin, obj.InnerTopMargin, obj.InnerBottomMargin, obj.SpacingBetweenItems);
            obj.AddChild(obj.ListBox);
            
            obj.TitlePanel = GemListBoxControlPanel(obj, title_text, add_button_tooltip, delete_button_tooltip);
            obj.AddChild(obj.TitlePanel);
            obj.AddEventListener(obj.TitlePanel, 'AddButtonEvent', @obj.AddButtonClicked);
            obj.AddEventListener(obj.TitlePanel, 'DeleteButtonEvent', @obj.DeleteButtonClicked);
            
            obj.LowerPanel = GemText(obj, '', '', ''); %GemPanel(obj);
            obj.AddChild(obj.LowerPanel);
            
            % Ensure tab panel will be created last
            obj.Reorder;            
        end
        
        function CreateGuiComponent(obj, position)
            CreateGuiComponent@GemPanel(obj, position);
        end
        
        function Resize(obj, panel_position)
            Resize@GemPanel(obj, panel_position);
            panel_width = panel_position(3);
            panel_height = panel_position(4);
            list_box_width = max(1, panel_width - obj.LeftMargin - obj.RightMargin);
            list_box_height = max(1, panel_height - obj.ControlPanelHeight - obj.LowerPanelHeight - obj.TopMargin - obj.BottomMargin);
            title_panel_position = [1, panel_height - obj.ControlPanelHeight-1, panel_width, obj.ControlPanelHeight];
            lower_panel_position = [1, obj.BottomMargin, panel_width, obj.LowerPanelHeight];
            obj.TitlePanel.TitleLeftPadding = obj.TitleLeftPadding;
            obj.TitlePanel.Resize(title_panel_position);
            obj.ListBox.Resize([obj.LeftMargin, obj.BottomMargin + obj.LowerPanelHeight, list_box_width, list_box_height]);
            obj.LowerPanel.Resize(lower_panel_position);
        end
        
        function height = GetRequestedHeight(obj, width)
            height = obj.ListBox.GetRequestedHeight(width) + obj.ControlPanelHeight + obj.LowerPanelHeight + obj.TopMargin + obj.BottomMargin;
        end
        
        function num_items = GetNumItems(obj)
            num_items = obj.ListBox.NumItems;
        end        
    end

    methods (Access = protected)        
        function AddButtonClicked(obj, ~, event_data)
            % Override this method for actions on clicking the add button
        end
        
        function DeleteButtonClicked(obj, ~, event_data)
            % Override this method for actions on clicking the delete button
        end
    end
    
    methods (Access = private)
        
        function Reorder(obj)
            % Ensures the upper and lower panels are on top
            children = obj.Children;
            upper_panel = obj.TitlePanel;
            lower_panel = obj.LowerPanel;
            other_children = {};
            for child = children
                if (child{1} ~= lower_panel) && (child{1} ~= upper_panel)
                    other_children{end + 1} = child{1};
                end
            end
            
            other_children{end + 1} = lower_panel;
            other_children{end + 1} = upper_panel;
            obj.Children = other_children;
        end                
    end
end