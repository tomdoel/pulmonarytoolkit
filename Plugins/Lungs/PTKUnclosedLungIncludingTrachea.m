classdef PTKUnclosedLungIncludingTrachea < PTKPlugin
    % PTKUnclosedLungIncludingTrachea. Plugin to segment the lung regions
    %     including the airways.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Lungs with trachea';
        ToolTip = 'Find unclosed lung region including the trachea and main bronchi'
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
            if dataset.IsGasMRI
                results = dataset.GetResult('PTKSegmentGasMRI');
                results.AddBorder(1);
                results = PTKGetMainRegionExcludingBorder(results, reporting);
                results.RemoveBorder(1);
            elseif strcmp(dataset.GetImageInfo.Modality, 'MR')
                lung_threshold = dataset.GetResult('PTKMRILungThreshold');
                results = lung_threshold.LungMask;
                
            else
                threshold_image = dataset.GetResult('PTKThresholdLungFiltered');
                threshold_image.ChangeRawImage(threshold_image.RawImage > 0);
                
                reporting.ShowProgress('Searching for largest connected region');
                
                % Find the main component, excluding any components touching the border
                threshold_image = PTKGetMainRegionExcludingBorder(threshold_image, reporting);
                
                results = threshold_image;
                results.ImageType = PTKImageType.Colormap;
            end
        end
    end
end