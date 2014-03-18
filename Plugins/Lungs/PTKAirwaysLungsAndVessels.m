classdef PTKAirwaysLungsAndVessels < PTKPlugin
    % PTKAirwaysLungsAndVessels. Plugin for displaying segented airways, lungs and vessels together
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
        ButtonText = 'Airways, Lungs<BR> and vesssels'
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
            
            % Get the vessel results
            vesselness_image = dataset.GetResult('PTKVesselness');

            % Make our output image the lugn segmentation
            results = left_and_right_lungs_image.BlankCopy;
            
            % Make an image matrix with 1 for right lung, 2 for left lung and 3
            % for airways
            combined_image_raw = uint8(left_and_right_lungs_image.RawImage > 0);
            combined_image_raw(vesselness_image.RawImage > 0.3) = 3;
            combined_image_raw(airways_image.RawImage == 1) = 6;
            
            % Change the output image
            results.ChangeRawImage(combined_image_raw);
            
        end        
    end
end