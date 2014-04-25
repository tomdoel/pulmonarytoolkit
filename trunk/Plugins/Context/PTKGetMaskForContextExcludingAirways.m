classdef PTKGetMaskForContextExcludingAirways < PTKPlugin
    % PTKGetMaskForContextExcludingAirways. Plugin for returning a mask corresponding to the
    %     current context, excluding voxels in the airways
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
        ButtonText = 'Context mask<br>no airways'
        ToolTip = 'Shows a mask corresponding to the current context, excluding the airways'
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
        function context_no_airways = RunPlugin(dataset, context, reporting)
            context_mask = dataset.GetTemplateMask(context);
            if ~context_mask.ImageExists
                context_no_airways = [];
                return;
            end
            [~, airway_image] = dataset.GetResult('PTKAirways', PTKContext.LungROI);
            
            % Reduce all images to a consistent size
            airway_image.ResizeToMatch(context_mask);
            
            % Create a region mask excluding the airways
            context_no_airways = context_mask.BlankCopy;
            context_no_airways.ChangeRawImage(context_mask.RawImage & airway_image.RawImage ~= 1);            
        end
    end
end