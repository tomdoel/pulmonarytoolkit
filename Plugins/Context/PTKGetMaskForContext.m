classdef PTKGetMaskForContext < PTKPlugin
    % PTKGetMaskForContext. Plugin for returning a mask corresponding to the
    %     current context
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
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Mask for context'
        ToolTip = 'Shows a mask corresponding to the current context'
        Category = 'Context'

        Context = PTKContextSet.Any
        AllowResultsToBeCached = false
        AlwaysRunPlugin = true
        PluginType = 'DoNothing'
        HidePluginInDisplay = true
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            % Get a mask for the current region to analyse
            results = dataset.GetTemplateImage(context);
            if ~results.ImageExists
                results = dataset.GetTemplateImage(PTKContext.Lungs);
            end
            
            results.CropToFit;
        end
    end
end