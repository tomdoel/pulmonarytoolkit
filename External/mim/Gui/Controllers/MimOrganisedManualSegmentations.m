classdef MimOrganisedManualSegmentations < CoreBaseClass
    % MimOrganisedManualSegmentations. Part of the internal framework of the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the TD MIM Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        AppDef
        PluginGroups
        GuiApp
        OrganisedPluginsModeList
    end
    
    methods
        function obj = MimOrganisedManualSegmentations(gui_app, app_def, reporting)
            obj.AppDef = app_def;
            obj.GuiApp = gui_app;
            obj.OrganisedPluginsModeList = MimOrganisedPluginsModeList(app_def, []);
            obj.Repopulate(reporting);
        end
        
        function Repopulate(obj, reporting)
            obj.OrganisedPluginsModeList.Clear;
            segmentation_list = obj.GetListOfPossibleSegmentationNames;
            obj.OrganisedPluginsModeList.AddSegmentationList(segmentation_list, obj.GuiApp, reporting);
        end

        function plugin_list = GetAllPluginsForMode(obj, mode)
            plugin_list = obj.OrganisedPluginsModeList.GetPlugins(mode);
        end
        
        function tool_list = GetOrderedPlugins(obj, mode)
            tool_maps = obj.GetAllPluginsForMode(mode);
            tool_maps = tool_maps.values;
            tool_list = [];
            for tool_map = tool_maps
                tool_list = horzcat(tool_list, tool_map{1}.values);
            end
            locations = CoreContainerUtilities.GetMatrixOfFieldValuesFromSet(tool_list, 'Location');
            [~, index] = sort(locations, 'ascend');
            tool_list = tool_list(index);
        end        
    end    
    
    methods (Access = private)
        
        function segmentation_name_list = GetListOfPossibleSegmentationNames(obj)
            % Obtains a list of segmentations found in the Manual Segmentations folder
            segmentation_name_list = obj.GuiApp.GetListOfManualSegmentations;
        end
    end
end