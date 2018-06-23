classdef PTKAirwaysSimplePruneImage < PTKPlugin
    % PTKAirwaysSimplePruneImage. Plugin for creating an image of the
    % airways pruned at approximately the segmental bronchi level.
    %
    %     This plugin does not attempt to perform advanced segmental
    %     anlaysis of the tree; instead it prunes the tree after the child
    %     branches of the lobar bronchi. If there are no child branches for
    %     a lobar bronchus, it is not changed. Since there is no segmental
    %     anlaysis, this plugin is more robust to failures to find the
    %     pulmonary segments. But it is also means the level of pruning is
    %     not consistent between different images, as it depends on which
    %     airways were found for each.
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
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    properties
        ButtonText = 'Airways simple<br>segment pruning'
        ToolTip = 'Creates an airway tree with end branches approximately pruned at the segmental level or above'
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
        function results_image = RunPlugin(dataset, reporting)
            
            left_and_right_lungs = dataset.GetResult('PTKLeftAndRightLungs');
            lobes = dataset.GetResult('PTKLobes');
            [airway_results, airway_image] = dataset.GetResult('PTKAirways');
            airway_tree = airway_results.AirwayTree;
            template = airway_image;
            

            centreline_tree = dataset.GetResult('PTKAirwayCentreline');
            centreline_tree.AirwayCentrelineTree.GenerateBranchParameters;
            results_image_seg_bronchi = dataset.GetTemplateImage(PTKContext.LungROI);
            new_centreline_tree = PTKGetSegmentalBronchiCentrelinesForEachLobe(centreline_tree.AirwayCentrelineTree, lobes, results_image_seg_bronchi, reporting);
            
            unpruned_segmental_centreline_tree = new_centreline_tree;
            
            
            segmental_bronchi_for_lobes_start_branches = new_centreline_tree;
            [segment_image_map, labelled_segments] = PTKGetSegmentsByNearestBronchus(airway_tree, left_and_right_lungs, segmental_bronchi_for_lobes_start_branches, lobes, reporting);
            start_branches = labelled_segments;
            
            
            start_branches = PTKPruneAirwaysBySegment(start_branches);
            
            results_image = PTKGetPrunedSegmentalAirwayImageFromCentreline(start_branches, unpruned_segmental_centreline_tree, airway_tree, template, false);
            results_image.ImageType = PTKImageType.Colormap;
        end
        
        function results = GenerateImageFromResults(airway_results, image_templates, reporting)
            results = airway_results; %.PrunedSegmentsByLobeImage;            
        end        
    end
end