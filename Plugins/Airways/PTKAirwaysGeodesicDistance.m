classdef PTKAirwaysGeodesicDistance < PTKPlugin
    % PTKAirwaysGeodesicDistance. Plugin for fetching the geodesic distance through airway tree
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Airways geodesic <br>distance'
        ToolTip = 'Finds the geodesic distance through the airways'
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
        Version = 1
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            [airways, airway_image] = dataset.GetResult('PTKAirways');
            start_point_global = airways.StartPoint;
            start_point_index_global = sub2ind(airways.ImageSize, start_point_global(1), start_point_global(2), start_point_global(3));
            start_point_index_local = airway_image.GlobalToLocalIndices(start_point_index_global);
            seed_image = airway_image.Copy;
            seed_image_raw = false(airway_image.ImageSize);
            seed_image_raw(start_point_index_local) = true;
            seed_image.ChangeRawImage(seed_image_raw);
            results_raw = bwdistgeodesic(airway_image.RawImage == 1, seed_image.RawImage, 'quasi-euclidean');
            results_raw(isnan(results_raw(:))) = 0;
            results = airway_image.BlankCopy;
            results.ChangeRawImage(results_raw);
            results.ImageType = PTKImageType.Scaled;
        end
    end
end