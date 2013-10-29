classdef PTKLungsExcludingSurface < PTKPlugin
    % PTKLungsExcludingSurface. Plugin to segment the lungs excluding surface points
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
        ButtonText = 'Lungs excluding<br>surface'
        ToolTip = 'Lungs excluding surface'
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
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            results = dataset.GetResult('PTKLeftAndRightLungs');
            results.ChangeRawImage(results.RawImage == 0);
            
            % Expand mask to include neighbouring voxels
            % NB. using the morph function allows us to remove the surface in a
            % scale-independent way
            results.BinaryMorph(@imdilate, 3);
    
            % Invert mask so it now represents the lung parenchyma
            results.ChangeRawImage(~results.RawImage);            
        end
    end
end