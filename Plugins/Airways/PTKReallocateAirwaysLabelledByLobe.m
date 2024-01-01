classdef PTKReallocateAirwaysLabelledByLobe < PTKPlugin
    % PTKReallocateAirwaysLabelledByLobe. Plugin to visualise the airway tree labelled
    % according to lobe
    %
    % This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    % the gui, or through the interfaces provided by the Pulmonary Toolkit.
    % See PTKPlugin.m for more information on how to run plugins.
    %
    % Plugins should not be run directly from your code.
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
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
 
    properties
        ButtonText = 'Reallocate Airways <br>by lobe'
        ToolTip = 'Shows airways coloured by lobe, derived from analysis of the airway centreline'
        Category = 'Airways'
 
        AllowResultsToBeCached = true
        AlwaysRunPlugin = true
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
            airways_by_lobe = dataset.GetResult('PTKAirwaysLabelledByLobe');
            lobes = dataset.GetResult('PTKLobes');
            [airway_results, airway_image] = dataset.GetResult('PTKAirways');

            new_start_branches = PTKReallocateAirwaysByLobe(airways_by_lobe.StartBranches, lobes, reporting);
            
    
            results_image_raw = PTKColourBranchesByLobe(new_start_branches, airway_results.AirwayTree, lobes);
            
            airway_image = 7*uint8(airway_image.RawImage == 1);
            airway_image(results_image_raw > 0) = results_image_raw(results_image_raw > 0);
            airways_by_lobe.StartBranches = new_start_branches;
            airways_by_lobe.AirwaysByLobeImage.ChangeRawImage(airway_image);
            results = airways_by_lobe;
        end
        
        function results = GenerateImageFromResults(airway_results, ~, ~)
            results = airway_results.AirwaysByLobeImage;
        end
    end
end