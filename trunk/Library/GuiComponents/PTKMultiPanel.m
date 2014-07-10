classdef PTKMultiPanel < PTKPanel
    % PTKMultiPanel. Graphical control holding multiple panels but only showing one at a time
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    

    properties (Access = protected)
        PanelMap
        CurrentPanelTag
    end
    
    events
        PanelChangedEvent
    end
    
    methods
        function obj = PTKMultiPanel(parent, reporting)
            obj = obj@PTKPanel(parent, reporting);
            
            obj.PanelMap = containers.Map;
        end
        
        function AddPanel(obj, panel, tag)
            obj.PanelMap(tag) = panel;
            obj.AddChild(panel);
            
            % If no current tab exists, then select this one
            if isempty(obj.CurrentPanelTag)
                obj.ChangeSelectedTab(tag);
            else
                panel.Disable;
            end
        end
        
        function Resize(obj, panel_position)
            Resize@PTKPanel(obj, panel_position);

            % ToDo: We should only need to resize the current tab
            for panel = obj.PanelMap.values
                panel{1}.Resize(panel_position);
            end
        end
        
        function ChangeSelectedTab(obj, tag)
            % Change the selected panel
            
            if ~strcmp(tag, obj.CurrentPanelTag)
                obj.CurrentPanelTag = tag;
                for panel_key = obj.PanelMap.keys
                    panel = obj.PanelMap(panel_key{1});
                    if strcmp(tag, panel_key{1})
                        panel.Enable(obj.Reporting);
                    else
                        panel.Disable;
                    end
                end
                notify(obj, 'PanelChangedEvent', PTKEventData(tag));
            end
        end
    end
end