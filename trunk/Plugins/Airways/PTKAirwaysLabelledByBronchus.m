classdef PTKAirwaysLabelledByBronchus < PTKPlugin
    % PTKAirwaysLabelledByBronchus. Plugin to visualise the airway tree bronchus by bronchus
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKAirwaysLabelledByBronchus calls the PTKAirways plugin to segment the
    %     airway tree. It then cretes an output labelled image where each 
    %     bronchus is labelled with contrasting colour values, starting with 1
    %     for the trachea. The child segments of each bronchus are labelled
    %     consecutively starting from the parent bronchus plus 1. Eg. if a
    %     parent is labeled 3, then its children will be labelled 4,5,6 etc.
    %     This makes the heirarcy clear from the image.
    
    %     The output image is intended to be visualised using the Lines
    %     colourmap; for this reason the grey colours (multiples of 7) are
    %     skipped to avoid confusion when used as an overlay on top of a
    %     greyscale image.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
 
    properties
        ButtonText = 'Airways <BR>by bronchus'
        ToolTip = 'Shows airways coloured by bronchus'
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
        function results = RunPlugin(dataset, ~)
            results = dataset.GetTemplateImage(PTKContext.LungROI);
            airway_results = dataset.GetResult('PTKAirways');
            labeled_region = PTKAirwaysLabelledByBronchus.GetLabeledSegmentedImageFromAirwayTree(airway_results.AirwayTree, results);
            results.ChangeRawImage(labeled_region);
            results.ImageType = PTKImageType.Colormap;
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