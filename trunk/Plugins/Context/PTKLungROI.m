classdef PTKLungROI < PTKPlugin
    % PTKLungROI. Plugin for finding the lung region of interest.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKLungROI runs the library function PTKGetLungROI to find the region of
    %     interest for the lung image.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Lungs & Airways<BR>ROI'
        ToolTip = 'Change the context to display the lungs and airways'
        Category = 'Context'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceImage'
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
                results = PTKGetLungROIForGasMRI(dataset.GetResult('PTKOriginalImage', PTKContext.OriginalImage), reporting);
            elseif strcmp(dataset.GetImageInfo.Modality, 'MR')
                lung_threshold = dataset.GetResult('PTKMRILungThreshold', PTKContext.OriginalImage);
                results = dataset.GetResult('PTKOriginalImage', PTKContext.OriginalImage);
                results.ResizeToMatch(lung_threshold.LungMask);                
            else            
                results = PTKGetLungROIForCT(dataset.GetResult('PTKOriginalImage', PTKContext.OriginalImage), reporting);
            end
        end
    end
end