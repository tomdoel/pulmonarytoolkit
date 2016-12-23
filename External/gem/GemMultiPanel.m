classdef GemMultiPanel < GemPanel
    % GemMultiPanel. Graphical control holding multiple panels but only showing one at a time
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    

    properties (Access = protected)
        PanelMap
        CurrentPanelTag
        OrderedTags
    end
    
    events
        PanelChangedEvent
    end
    
    methods
        function obj = GemMultiPanel(parent)
            obj = obj@GemPanel(parent);
            
            obj.PanelMap = containers.Map;
        end
        
        function AddPanel(obj, panel, tag)
            obj.PanelMap(tag) = panel;
            obj.AddChild(panel);
            obj.OrderedTags{end + 1} = tag;
            
            % If no current tab exists, then select this one
            if isempty(obj.CurrentPanelTag)
                obj.ChangeSelectedTab(tag);
            else
                panel.Disable;
            end
        end
        
        function Resize(obj, panel_position)
            Resize@GemPanel(obj, panel_position);

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
                        panel.Enable;
                    else
                        panel.Disable;
                    end
                end
                notify(obj, 'PanelChangedEvent', CoreEventData(tag));
            end
        end
    end
end