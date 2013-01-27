classdef PTKInvertImage < PTKPlugin
    % PTKInvertImage. Plugin for returning inverted image data.
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
        ButtonText = 'Invert Image'
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
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            if dataset.IsGasMRI
                results = dataset.GetResult('PTKOriginalImage');
                results = PTKImageUtilities.InvertImage(results);
            else
                reporting.Error('PTKInvertImage:InvalidModality', 'This plugin is only for use with gas MRI images');
            end
        end
    end
end