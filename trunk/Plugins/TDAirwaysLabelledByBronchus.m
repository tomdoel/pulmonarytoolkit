classdef TDAirwaysLabelledByBronchus < TDPlugin
    % TDAirwaysLabelledByBronchus. Plugin to visualise the airway tree bronchus by bronchus
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDAirwaysLabelledByBronchus calls the TDAirways plugin to segment the
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
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(dataset, ~)
            results = dataset.GetResult('TDLungROI').BlankCopy;
            airway_results = dataset.GetResult('TDAirways');
            labeled_region = TDAirwaysLabelledByBronchus.GetLabeledSegmentedImageFromAirwayTree(airway_results.airway_tree, airway_results.image_size);
            results.ChangeRawImage(labeled_region);
            results.ImageType = TDImageType.Colormap;
        end
    end
    
    methods (Static, Access = private)

        function segmented_image = GetLabeledSegmentedImageFromAirwayTree(airway_tree, image_size)
            airway_tree.AddColourValues(1);
            segmented_image = zeros(image_size, 'uint8');
            
            segments_to_do = airway_tree;
            
            while ~isempty(segments_to_do)
                segment = segments_to_do(end);
                segments_to_do(end) = [];
                segmented_image(segment.GetAllAirwayPoints) = segment.Colour;
                segments_to_do = [segments_to_do segment.Children];
            end
        end
    end
end