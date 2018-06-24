classdef PTKAirwaysSimplePrunedImage < PTKPlugin
    % PTKAirwaysSimplePrunedImage. Plugin for creating an image of the
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
            
            % Fetch a template image
            results_image = dataset.GetTemplateImage(PTKContext.LungROI);

            % Get the segmented airway tree
            airway_results = dataset.GetResult('PTKAirways');
            airway_tree = airway_results.AirwayTree;
            
            % A simple segmental pruning based on generation number: 
            % This will (roughly speaking) keep the
            % segmental bronchi and remove bronchi below this, but it may
            % over-prune, especially in the right mid and lower lobes where
            % the generation numbers would be higher. Ths advantage of this
            % approach is it is very robust, whereas any attempt to
            % determine the lobar and segmental bronchi may fail in some
            % cases.            
            airway_tree.PruneDescendants(3);
            
            labeled_region = PTKAirwaysSimplePruneImage.GetLabeledSegmentedImageFromAirwayTree(airway_results.AirwayTree, results_image);
            results_image.ChangeRawImage(labeled_region);
            results_image.ImageType = PTKImageType.Colormap;
        end
    end
 
    methods (Static, Access = private)

        function segmented_image = GetLabeledSegmentedImageFromAirwayTree(airway_tree, template)
            airway_tree.AddColourValues(1);
            segmented_image = zeros(template.ImageSize, 'uint8');
            
            segments_to_do = airway_tree;
            
            while ~isempty(segments_to_do)
                segment = segments_to_do(end);
                segments_to_do(end) = [];
                segmented_image(template.GlobalToLocalIndices(segment.GetAllAirwayPoints)) = segment.Colour;
                segments_to_do = [segments_to_do segment.Children];
            end
        end
    end    
end