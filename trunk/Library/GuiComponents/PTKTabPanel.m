classdef PTKTabPanel < PTKPanel
    % PTKTabPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        FontSize
        FontColour
        TabHeight
    end

    properties (Access = protected)
        OrderedTabs
        Tabs
        TabControl
    end
    
    properties (Constant, Access = private)
        LeftMargin = 10
        RightMargin = 10
        TabSpacing = 10
        BottomMargin = 10;
        TopMargin = 10;
    end
    
    properties (Access = private)
        BlankText
    end

    methods
        function obj = PTKTabPanel(tab_control, reporting)
            obj = obj@PTKPanel(tab_control, reporting);
            obj.TabControl = tab_control;
            obj.FontSize = 16;
            obj.TabHeight = 26;
            obj.FontColour = [1 1 1];
            obj.BottomBorder = true;
            
            obj.Tabs = containers.Map;
            
            obj.BlankText = PTKText(obj, '', '', 'blank');
            
            obj.BlankText.Clickable = false;
            obj.AddChild(obj.BlankText, reporting);
            
            obj.OrderedTabs = {};
            
            % Add listener for switching modes when the tab is changed
            obj.AddEventListener(tab_control, 'PanelChangedEvent', @obj.TabChanged);
        end
        
        function AddTab(obj, name, tag, tooltip)
            tab_text_control = PTKText(obj, name, tooltip, tag);
            tab_text_control.FontColour = PTKSoftwareInfo.TextSecondaryColour;
            tab_text_control.FontSize = obj.FontSize;
            tab_text_control.HorizontalAlignment = 'center';
            obj.AddChild(tab_text_control, obj.Reporting);
            obj.Tabs(tag) = tab_text_control;
            obj.OrderedTabs{end + 1} = tag;
            
            obj.AddEventListener(tab_text_control, 'TextClicked', @obj.TabClicked);
        end
        
        function height = GetRequestedHeight(obj, width)            
            height = obj.TopMargin + obj.BottomMargin + obj.TabHeight;
        end
        
        function Resize(obj, panel_position)
            Resize@PTKPanel(obj, panel_position);
            
            inner_position = obj.InnerPosition;
            obj.ResizePreTabEnable(inner_position, '');
        end
        
        function number_of_tabs = GetNumberOfEnabledTabs(obj)
            number_of_tabs = 0;
            for tab = obj.Tabs.values
                if tab{1}.Enabled
                    number_of_tabs = number_of_tabs + 1;
                end
            end
        end
        
        function EnableTab(obj, tag)
            tab = obj.Tabs(tag);
            if ~tab.Enabled
                obj.Resize(obj.Position);
                obj.ResizePreTabEnable(obj.InnerPosition, tag);
                tab.Enable(obj.Reporting);
                obj.TabControl.Reorder;
            end
            obj.Resize(obj.Position);
        end
        
        function DisableTab(obj, tag)
            tab = obj.Tabs(tag);
            if tab.Enabled
                tab.Disable;
            end
            if ~isempty(obj.Position)
                obj.Resize(obj.Position);
            end
        end
        
        function enabled = IsTabEnabled(obj, tag)
            tab = obj.Tabs(tag);
            enabled = tab.Enabled;
        end
    end
    
    methods (Access = private)
        
        function TabChanged(obj, ~, event_data)
            tag = event_data.Data;
            for tab_key = obj.Tabs.keys
                tab = obj.Tabs(tab_key{1});
                if strcmp(tab_key{1}, tag)
                    tab.Select(true);
                else
                    tab.Select(false);
                end
            end
        end
        
        function TabClicked(obj, ~, tag_data)
            obj.TabControl.ChangeSelectedTab(tag_data.Data);
        end
        
        function ResizePreTabEnable(obj, panel_position, tab_to_enable)
            number_of_tabs = double(obj.Tabs.Count);
            number_of_enabled_tabs = obj.GetNumberOfEnabledTabs;
            tab_width = (panel_position(3) - obj.LeftMargin - obj.RightMargin - (number_of_tabs - 1)*obj.TabSpacing)/number_of_enabled_tabs;
            tab_height = panel_position(4) - obj.TopMargin - obj.BottomMargin;
            tab_width = max(1, tab_width);
            enabled_tab_index = 1;
            for all_tab_index = 1 : number_of_tabs
                tab_tag = obj.OrderedTabs{all_tab_index};
                tab = obj.Tabs(tab_tag);
                if tab.Enabled || strcmp(tab_tag, tab_to_enable)
                    tab_x = round(obj.LeftMargin + (enabled_tab_index-1)*(tab_width + obj.TabSpacing));
                    tab.Resize([panel_position(1) + tab_x, panel_position(2) + obj.BottomMargin, tab_width, tab_height]);
                    enabled_tab_index = enabled_tab_index + 1;
                end
            end
            
            obj.BlankText.Resize([panel_position(1), panel_position(2), panel_position(3), panel_position(4)]);
        end
        
    end    
end