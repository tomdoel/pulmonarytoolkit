classdef PTKAirwayDistanceTransform < PTKPlugin
    % PTKAirwayDistanceTransform. Plugin for distance transform to blood vessels
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
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
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
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        Visibility = 'Developer'
    end
    
    methods (Static)
        
        function results = RunPlugin(dataset, ~)    
            lung_mask = dataset.GetResult('PTKLeftAndRightLungs');
            lung_mask.ChangeRawImage(uint8(lung_mask.RawImage > 0));
            [airways, airway_image] = dataset.GetResult('PTKAirways');
            results = airway_image.BlankCopy();
            
            airways_dt = bwdist(airway_image.RawImage == 1);

            airways_dt(~(lung_mask.RawImage > 0)) = 0;
            results.ChangeRawImage(airways_dt);
            results.ImageType = PTKImageType.Scaled;
        end
        
    end    
end