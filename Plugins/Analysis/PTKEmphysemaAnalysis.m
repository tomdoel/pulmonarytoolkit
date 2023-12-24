classdef PTKEmphysemaAnalysis < PTKPlugin
    % PTKEmphysemaAnalysis. Plugin for computing emphysema metrics from CT
    %
    %     Returns a PTKMetrics structure with emphysema percentage and 
    %     percentile density. Can be used for any lung context including
    %     manually created regions.
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
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Emphysema<br>analysis'
        ToolTip = 'Measures percentages of emphysema-like voxels'
        Category = 'Analysis'

        AllowResultsToBeCached = true
        AlwaysRunPlugin = true
        Context = PTKContextSet.Any
        PluginType = 'DoNothing'
        HidePluginInDisplay = true
        FlattenPreviewImage = true
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
    end
    
    methods (Static)
        function emphysema_results = RunPlugin(dataset, context, reporting)
            
            roi = dataset.GetResult('PTKLungROI', PTKContext.LungROI);
            if ~roi.IsCT
                reporting.ShowMessage('PTKEmphysemaAnalysis:NotCTImage', 'Cannot perform density analysis as this is not a CT image');
                return;
            end
            
            % Create a region mask excluding the airways
            context_no_airways = dataset.GetResult('PTKGetMaskForContextExcludingAirways', context);            
            
            % Special case if this context doesn't exist for this dataset
            if isempty(context_no_airways) || ~context_no_airways.ImageExists
                emphysema_results = PTKMetrics.empty;
                return;
            end
            
            roi.ResizeToMatch(context_no_airways);
            
            emphysema_results = PTKComputeEmphysemaFromMask(roi, context_no_airways);
        end
    end
end