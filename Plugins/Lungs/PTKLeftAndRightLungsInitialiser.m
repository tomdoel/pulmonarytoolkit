classdef PTKLeftAndRightLungsInitialiser < PTKPlugin
    % PTKLeftAndRightLungsInitialiser. Plugin to segment and label the left and right lungs.
    %
    % This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    % the gui, or through the interfaces provided by the Pulmonary Toolkit.
    % See PTKPlugin.m for more information on how to run plugins.
    %
    % Plugins should not be run directly from your code.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Initial Left and <br>Right Lungs'
        ToolTip = 'Separate and label left and right lungs'
        Category = 'Lungs'
        
        AllowResultsToBeCached = false
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        Visibility = 'Developer'
        Version = 3
        
        MemoryCachePolicy = 'Off'
        DiskCachePolicy = 'Off'        
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            reporting.ShowProgress('Separating lungs');
            
            if strcmp(dataset.GetImageInfo.Modality, 'MR')
                unclosed_lungs = dataset.GetResult('PTKUnclosedLungIncludingTrachea', PTKContext.LungROI);
            else
                unclosed_lungs = dataset.GetResult('PTKUnclosedLungExcludingTrachea', PTKContext.LungROI);
            end
            
            lung_roi = dataset.GetResult('PTKLungROI');
            trachea = dataset.GetResult('PTKTopOfTrachea');
            trachea_top = lung_roi.GlobalToLocalCoordinates(trachea.top_of_trachea);
            
            filtered_threshold_lung = dataset.GetResult('PTKThresholdLungFiltered', PTKContext.LungROI);
            
            results = PTKGetLeftAndRightLungs(unclosed_lungs, filtered_threshold_lung, lung_roi, trachea_top, reporting);
        end
    end
end