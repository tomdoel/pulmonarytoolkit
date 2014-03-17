classdef PTKLungInteriorNonParenchymaPoints < PTKPlugin
    % PTKLungInteriorNonParenchymaPoints. Plugin to show points inside the lung
    %     which are not parenchymal tissue (larger airways and vessels)
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
        ButtonText = 'Non-Parenchyma'
        ToolTip = 'Points inside the lungs which are not part of the parenchyma'
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
        Visibility = 'Developer'
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            lungs = dataset.GetResult('PTKLungsExcludingSurface');
            roi = dataset.GetResult('PTKLungROI');
            
            [~, airways_image] = dataset.GetResult('PTKAirways');
            airways_image.ChangeRawImage(airways_image.RawImage == 1);
            airways_image.BinaryMorph(@imdilate, 3);
            
            pruned_airways = dataset.GetResult('PTKAirwaysPrunedBySegment').PrunedSegmentsByLobeImage;
            pruned_airways.ChangeRawImage(pruned_airways.RawImage > 0);
            pruned_airways.BinaryMorph(@imdilate, 6);

            threshold_roi = (roi.RawImage > 0) & (roi.RawImage < roi.HounsfieldToGreyscale(-400));
            results = lungs.BlankCopy;
            
            vesselness_dilated = dataset.GetResult('PTKVesselnessDilated');
            
            results_raw = lungs.RawImage & ((~threshold_roi) | pruned_airways.RawImage | airways_image.RawImage | vesselness_dilated.RawImage);
            
            results.ChangeRawImage(results_raw);
        end
    end
end