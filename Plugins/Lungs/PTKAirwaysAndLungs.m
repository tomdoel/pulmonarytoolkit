classdef PTKAirwaysAndLungs < PTKPlugin
    % PTKAirwaysAndLungs. Plugin for displaying segented airways and lungs together
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
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Airways and Lungs'
        ToolTip = 'Shows a segmentation of the airways and lungs'
        Category = 'Lungs'

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
            
            % Get the airway results
            [airways_results, airways_image] = dataset.GetResult('PTKAirways');
            
            % Get the results for the left and right lung segmentations
            [left_and_right_lungs_results, left_and_right_lungs_image] = dataset.GetResult('PTKLeftAndRightLungs');
            
            % Make our output image the lung segmentation
            results = left_and_right_lungs_image.BlankCopy;
            
            % Make an image matrix with 1 for right lung, 2 for left lung and 3
            % for airways
            combined_image_raw = left_and_right_lungs_image.RawImage;
            combined_image_raw(airways_image.RawImage == 1) = 3;
            
            % Change the output image
            results.ChangeRawImage(combined_image_raw);
            
        end        
    end
end