classdef PTKDivideLungsIntoSagittalBins < PTKPlugin
    % PTKDivideLungsIntoSagittalBins. Plugin for dividing the lungs into bins along
    % the left-right axis
    %
    % This is a plugin for the Pulmonary Toolkit. Plugins can be run using
    % the gui, or through the interfaces provided by the Pulmonary Toolkit.
    % See PTKPlugin.m for more information on how to run plugins.
    %
    % Plugins should not be run directly from your code.
    %
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2014.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Sagittal<br>bins'
        ToolTip = 'Divides the lungs into bins along the left-right axis'
        Category = 'Lungs'
        
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        Context = PTKContextSet.Lungs
        Visibility = 'Developer'
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            whole_lung_mask = dataset.GetTemplateImage(PTKContext.Lungs);
            orientation = PTKImageOrientation.Sagittal;            
            results = PTKDivideVolumeIntoSlices(whole_lung_mask, orientation, reporting);
            results.BinImage.SetPreferredOrientation(PTKImageOrientation.Coronal);
            results.BinImage.SetPreferredSliceNumber(round(results.BinImage.ImageSize/2));
        end
        
        function results = GenerateImageFromResults(bins_results, image_templates, reporting)
            results = bins_results.BinImage;
            results.SetPreferredOrientation(PTKImageOrientation.Coronal);
            results.SetPreferredSliceNumber(round(results.ImageSize/2));
        end
    end
end