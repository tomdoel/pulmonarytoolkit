classdef PTKLungMaskForRegistration < PTKPlugin
    % PTKLungMaskForRegistration Plugin for finding a mask for the left or right lung suitable for registration.
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Lung mask<br>for registration'
        ToolTip = ''
        Category = 'Registration'
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        Context = PTKContextSet.SingleLung
        Visibility = 'Developer'
    end
    
    methods (Static)
        
        function results = RunPlugin(dataset, context, reporting)
            results = dataset.GetResult('PTKLeftAndRightLungs', PTKContext.LungROI);
            region = dataset.GetResult('PTKLungRegion', context);
            results.ResizeToMatch(region);
            if context == PTKContext.LeftLung
                lung_colour = 2;
            elseif context == PTKContext.RightLung
                lung_colour = 1;
            else
                reporting.Error('PTKLungMask:InvalidContext', 'PTKLungMask can only be called with the LeftLung or RightLung context');
            end
            results.ChangeRawImage(results.RawImage == lung_colour);
            results.AddBorder(10);
            results = PTKFillCoronalHoles(results, [], reporting);
            results.RemoveBorder(10);
        end 
    end    
end

