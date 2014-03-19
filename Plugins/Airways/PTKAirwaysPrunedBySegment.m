classdef PTKAirwaysPrunedBySegment < PTKPlugin
    % PTKAirwaysPrunedBySegment. Plugin for pruning end branches from an airway
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
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    properties
        ButtonText = 'Airways pruned<br>by segment'
        ToolTip = 'Creates an airway tree with end branches pruned'
        Category = 'Airways'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
        Visibility = 'Developer'
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            segmental_bronchi_for_each_lobe = dataset.GetResult('PTKSegmentalBronchi');
            unpruned_segmental_centreline_tree = segmental_bronchi_for_each_lobe.StartBranches;
            
            airways_by_segment = dataset.GetResult('PTKSegmentsByNearestBronchus');
            start_branches = airways_by_segment.AirwaysBySegment;
            [airway_results, airway_image] = dataset.GetResult('PTKAirways');
            
            start_branches = PTKPruneAirwaysBySegment(start_branches);
            template = airway_image;
            
            results_image = PTKGetPrunedSegmentalAirwayImageFromCentreline(start_branches, unpruned_segmental_centreline_tree, airway_results.AirwayTree, template, false);
            results_image.ImageType = PTKImageType.Colormap;
            
            % Store results and results image
            results = [];
            results.StartBranches = start_branches;
            results.PrunedSegmentsByLobeImage = results_image;
        end
        
        function results = GenerateImageFromResults(airway_results, image_templates, reporting)
            results = airway_results.PrunedSegmentsByLobeImage;            
        end        
    end
end