classdef PTKVolumeAnalysis < PTKPlugin
    % PTKVolumeAnalysis. Plugin for computing left and right lung volumes
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKVolumeAnalysis computes the volume of the left and right lungs using the 
    %     lung segmentations and voxel sizes. The vessels and bronchi are 
    %     excluded up to the point where they enter the lung region.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Volume analysis'
        ToolTip = 'Measures volumes of regions'
        Category = 'Analysis'
        Mode = 'Analysis'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = true
        PluginType = 'DoNothing'
        HidePluginInDisplay = true
        FlattenPreviewImage = true
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
        Context = PTKContextSet.Any
        PTKVersion = '2'
        
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            lung_mask = dataset.GetTemplateImage(context);
            if ~lung_mask.ImageExists
                lung_mask = dataset.GetTemplateImage(PTKContext.Lungs);
            end
            
            results = PTKComputeVolumeFromSegmentation(lung_mask, reporting);
        end
    end
end