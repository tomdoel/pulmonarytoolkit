classdef PTKGetContextForLungs < PTKPlugin
    % PTKGetContextForLungs. Plugin for finding the region of interest for the
    % lungs
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
        ButtonText = 'Lungs <BR>ROI'
        ToolTip = 'Change the context to the lungs'
        Category = 'Context'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        Context = PTKContextSet.Lungs
        PluginType = 'ReplaceImage'
        HidePluginInDisplay = true
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            results = dataset.GetResult('PTKLeftAndRightLungs', PTKContext.LungROI);
            results.ChangeRawImage(results.RawImage > 0);
        end
    end
end