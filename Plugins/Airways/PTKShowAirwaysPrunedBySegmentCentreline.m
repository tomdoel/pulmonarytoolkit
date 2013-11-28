classdef PTKShowAirwaysPrunedBySegmentCentreline < PTKPlugin
    % PTKShowAirwaysPrunedBySegmentCentreline. Plugin for pruning end branches from an airway
    %     tree according to the pulmonary segments
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    properties
        ButtonText = 'Show pruned<br>centreline'
        ToolTip = 'Visualises a smoothed centreline for the airways pruned by segmental bronchi'
        Category = 'Airways'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = true
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            results = dataset.GetResult('PTKAirwaysPrunedBySegment');
        end
        
        function results = GenerateImageFromResults(airway_results, image_templates, reporting)
            results = airway_results.PrunedSegmentsByLobeImage;            

            template_image = image_templates.GetTemplateImage(PTKContext.LungROI);
            start_tree = airway_results.StartBranches.Trachea;
            PTKVisualiseTreeModelCentreline(start_tree, template_image.VoxelSize, true);
        end        
    end
end