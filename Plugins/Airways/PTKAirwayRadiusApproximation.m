classdef PTKAirwayRadiusApproximation < PTKPlugin
    % PTKAirwayRadiusApproximation. Plugin to approximate radius of branches in
    %     the airway tree
    %
    % This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    % the gui, or through the interfaces provided by the Pulmonary Toolkit.
    % See PTKPlugin.m for more information on how to run plugins.
    %
    % Plugins should not be run directly from your code.
    %
    %     PTKAirwayRadiusApproximation uses a distance transform to estimate the
    %     radius of each branch in the airway tree. The results are shown as an
    %     output image.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
 
    properties
        ButtonText = 'Airway radius <BR>approximation'
        ToolTip = 'Shows airways coloured by their radius approximation'
        Category = 'Airways'
 
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        Visibility = 'Developer'
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            results = dataset.GetTemplateImage(PTKContext.LungROI);
            airway_results = dataset.GetResult('PTKAirways');
            results = PTKAirwayRadiusApproximation.GetRadiusApproximationFromAirwayTree(airway_results.AirwayTree, results, reporting);
        end
    end
    
    methods (Static, Access = private)

        function results = GetRadiusApproximationFromAirwayTree(airway_tree, template, reporting)
            airway_segmented_image = PTKGetImageFromAirwayResults(airway_tree, template, false, reporting);
            dt_image = airway_segmented_image.RawImage;
            dt_image = dt_image == 0;
            dt_image = bwdist(dt_image);
            
            segments_to_do = airway_tree;
            min_voxel_size_mm = min(airway_segmented_image.VoxelSize);

            segmented_image = zeros(template.ImageSize, 'single');
            
            while ~isempty(segments_to_do)
                segment = segments_to_do(end);
                segments_to_do(end) = [];
                airway_points_local = template.GlobalToLocalIndices(segment.GetAllAirwayPoints);
                max_radius = max(dt_image(airway_points_local))*min_voxel_size_mm;
                segmented_image(airway_points_local) = max_radius;
                segments_to_do = [segments_to_do segment.Children];
            end
            
            results = airway_segmented_image.BlankCopy();
            results.ChangeRawImage(segmented_image);
            results.ImageType = PTKImageType.Scaled;
        end
    end
end