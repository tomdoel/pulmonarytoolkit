classdef PTKEmphysemaImage < PTKPlugin
    % PTKEmphysemaImage. Plugin for computing the percentage of emphysema
    %     voxels
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
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Emphysema'
        ToolTip = 'Shows emphysema-like voxels'
        Category = 'Analysis'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        Context = PTKContextSet.LungROI
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function emphysema_results_image = RunPlugin(dataset, context, reporting)
            roi = dataset.GetResult('PTKLungROI');
            context_no_airways = dataset.GetResult('PTKGetMaskForContextExcludingAirways', context);
            roi.ResizeToMatch(context_no_airways);
            [~, emphysema_results_image] = PTKComputeEmphysemaFromMask(roi, context_no_airways);
            emphysema_results_image.ImageType = PTKImageType.Colormap;
        end
    end
end