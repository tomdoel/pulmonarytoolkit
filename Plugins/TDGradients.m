classdef TDGradients < TDPlugin
    % TDGradients. Plugin for showing image gradients using a quiver plot
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDGradients uses Matlab's gradient() function to compute finite
    %     difference image gradients in the i-j-k directions. These are returned
    %     as a 4D vector which can be illustrated as a quiver plot.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Gradient'
        ToolTip = 'Shows arrows in the direction of the gradient'
        Category = 'Lungs'
        
        AllowResultsToBeCached = false
        AlwaysRunPlugin = true
        PluginType = 'ReplaceQuiver'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, ~)
            image = dataset.GetResult('TDLungROI');
            [gi, gj, gk] = gradient(single(image.RawImage));
            results = image.BlankCopy;
            results.ChangeRawImage(cat(4, gi, gj, gk));
        end
    end
end