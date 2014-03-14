classdef PTKTabControl < PTKPanel
    % PTKTabControl. Part of the gui for the Pulmonary Toolkit.
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
    

    properties (Access = protected)
        TabPanel
        TabMap
        CurrentPanelTag
    end
    
    events
        TabChangedEvent
    end
    
    methods
        function obj = PTKTabControl(parent, reporting)
            obj = obj@PTKPanel(parent, reporting);
            
            obj.TabPanel = PTKTabPanel(obj, reporting);
            obj.AddChild(obj.TabPanel);
            obj.TabMap = containers.Map;
        end
        
        function AddTab(obj, panel, name, tag, tooltip)
            obj.TabPanel.AddTab(name, tag, tooltip);
            obj.TabMap(tag) = panel;
            obj.AddChild(panel);
            
            % If no current tab exists, then select this one
            if isempty(obj.CurrentPanelTag)
                obj.ChangeSelectedTab(tag);
            else
                panel.Disable;
            end
            
            % Ensure tab panel will be created last
            obj.Reorder;
        end
        
        function Resize(obj, panel_position)
            Resize@PTKPanel(obj, panel_position);
            
            tab_panel_height = obj.TabPanel.GetRequestedHeight;
            tab_panel_y_position = panel_position(4) - tab_panel_height;
            obj.TabPanel.Resize([1, 1 + tab_panel_y_position, panel_position(3), tab_panel_height]);

            % ToDo: We should only need to resize the current tab
            for panel = obj.TabMap.values
                panel{1}.Resize([1, 1, panel_position(3), tab_panel_y_position]);
            end
        end
        
        function ChangeSelectedTab(obj, tag)
            if ~strcmp(tag, obj.CurrentPanelTag)
                obj.TabPanel.ChangeSelectedTab(tag);
            end
        end

        function TabChanged(obj, tag)
            obj.CurrentPanelTag = tag;
            for panel_key = obj.TabMap.keys
                tab = obj.TabMap(panel_key{1});
                if strcmp(tag, panel_key{1})
                    tab.Enable(obj.Reporting);
                else
                    tab.Disable;
                end
            end
            notify(obj, 'TabChangedEvent', PTKEventData(tag));
        end
    end
    
    methods (Access = private)
        function Reorder(obj)
            children = obj.Children;
            tab_panel = obj.TabPanel;
            other_children = {};
            for child = children
                if child{1} ~= tab_panel
                    other_children{end + 1} = child{1};
                end
            end
            
            other_children{end + 1} = tab_panel;
            obj.Children = other_children;
        end
    end
end