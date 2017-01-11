classdef PTKAirwayEndpointsLabelledByLobe < PTKPlugin
    % PTKAirwayEndpointsLabelledByLobe. Plugin to visualise parts of the airway tree labelled
    % according to lobe
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKAirwayEndpointsLabelledByLobe is based on
    %     PTKAirwaysLabelledByLob, but returns only the endpoints of each
    %     set of branches (determined by geodesic distance) in order to
    %     reduce the effect of the branches nearest the lobar bifurcation
    %     points.
    %
    %     The resulting image is a labelled image with nonzero values
    %     representing bronchi allocated to the following lobes:
    %         1 - Upper right lobe
    %         2 - Mid right lobe
    %         4 - Lower right lobe
    %         5 - Upper left lobe
    %         6 - Lower left lobe
    %         3 - Lobe could not be determined with certainty
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
 
    properties
        ButtonText = 'Airway endpoints <br>by lobe'
        ToolTip = 'Shows airways coloured by lobe, derived from analysis of the airway centreline'
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
        Version = 1
        
        EnableModes = MimModes.EditMode
        SubMode = MimSubModes.ColourRemapEditing
        EditRequiresPluginResult = true
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            airways_by_lobe = dataset.GetResult('PTKAirwaysLabelledByLobe');
            geodesic_distances = dataset.GetResult('PTKAirwaysGeodesicDistance');
            airway_mapped_image = airways_by_lobe.AirwaysByLobeImage;
            results_raw = airway_mapped_image.GetMappedRawImage;
            
            for element_colour = [PTKColormapLabels.LeftLowerLobe, PTKColormapLabels.LeftUpperLobe, ...
                    PTKColormapLabels.RightUpperLobe, PTKColormapLabels.RightMiddleLobe, PTKColormapLabels.RightLowerLobe]
                indices = find(results_raw == element_colour);
                distances = geodesic_distances.RawImage(indices);
                [~, sorted_distances_indices] = sort(distances, 'ascend');
                part_indices = sorted_distances_indices(1:ceil(numel(sorted_distances_indices)/2));
                results_raw(indices(part_indices)) = 0;
            end

            results = airway_mapped_image.BlankCopy;
            results.ChangeRawImage(results_raw);
        end
        
   
        
    end
end