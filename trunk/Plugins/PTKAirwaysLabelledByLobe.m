classdef PTKAirwaysLabelledByLobe < PTKPlugin
    % PTKAirwaysLabelledByLobe. Plugin to visualise the airway tree labelled
    % according to lobe
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKAirwaysLabelledByLobe calls the PTKAirways plugin to segment the
    %     airway tree and the PTKAirwayCentreline plguin to obtain the airway
    %     centreline. It then calls the library function PTKGetAirwaysLabelledByLobe
    %     to allocate each broncus to the unique lobe it serves. Bronchi serving
    %     more than one lobe are not displayed.
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
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
 
    properties
        ButtonText = 'Airways <br>by lobe'
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
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            results_image = dataset.GetTemplateImage(PTKContext.LungROI);
            [airway_results, airway_image] = dataset.GetResult('PTKAirways');
            centreline_results = dataset.GetResult('PTKAirwayCentreline');
            [airways_by_lobe, start_branches] = PTKGetAirwaysLabelledByLobe(results_image, airway_results, centreline_results.AirwayCentrelineTree, reporting);
            airway_image = 7*uint8(airway_image.RawImage == 1);
            airway_image(airways_by_lobe > 0) = airways_by_lobe(airways_by_lobe > 0);
            results_image.ChangeRawImage(airway_image);
            results_image.ImageType = PTKImageType.Colormap;
            results = [];
            results.AirwaysByLobeImage = results_image;
            results.StartBranches = start_branches;
        end
        
        function results = GenerateImageFromResults(airway_results, ~, ~)
            results = airway_results.AirwaysByLobeImage;
        end        
    end
end