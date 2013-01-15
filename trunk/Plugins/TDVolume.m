classdef TDVolume < TDPlugin
    % TDVolume. Plugin for computing left and right lung volumes
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDVolume computes the volume of the left and right lungs using the 
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
        ButtonText = 'Lung Volume'
        ToolTip = 'Measures lung volumes'
        Category = 'Analysis'

        AllowResultsToBeCached = false
        AlwaysRunPlugin = true
        PluginType = 'DoNothing'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            
            left_and_right_lungs = dataset.GetResult('TDLeftAndRightLungs');
            TDComputeVolumeFromLungMasks(left_and_right_lungs, reporting);

            results = [];
        end
    end
end