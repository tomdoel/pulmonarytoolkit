classdef TDAirwayDistanceTransform < TDPlugin
    % TDAirwayDistanceTransform. Plugin for distance transform to blood vessels
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
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
        ButtonText = 'Airway DT'
        ToolTip = 'Computes a distance transform from airways'
        Category = 'Airways'
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        
        function results = RunPlugin(dataset, ~)    
            lung_mask = dataset.GetResult('TDLeftAndRightLungs');
            lung_mask.ChangeRawImage(uint8(lung_mask.RawImage > 0));
            [airways, airway_image] = dataset.GetResult('TDAirways');
            results = airway_image.BlankCopy;
            
            airways_dt = bwdist(airway_image.RawImage == 1);

            airways_dt(~(lung_mask.RawImage > 0)) = 0;
            results.ChangeRawImage(airways_dt);
            results.ImageType = TDImageType.Scaled;
        end
        
    end    
end