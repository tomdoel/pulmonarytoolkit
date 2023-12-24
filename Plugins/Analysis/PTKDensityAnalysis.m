classdef PTKDensityAnalysis < PTKPlugin
    % PTKDensityAnalysis. Plugin for aggregated density and airway measurements from CT
    %
    %     Returns a PTKMetrics structure with combined density, emphysema 
    %     and airway measurements for the region defined by the specified 
    %     context. Can be used for any lung context including manually created regions.
    %
    % This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    % the gui, or through the interfaces provided by the Pulmonary Toolkit.
    % See PTKPlugin.m for more information on how to run plugins.
    %
    % Plugins should not be run directly from your code.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Density<br>analysis'
        ToolTip = 'Performs density analysis'
        Category = 'Analysis'

        Context = PTKContextSet.Any
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'DoNothing'
        HidePluginInDisplay = true
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            
            % Get density and air/tissue fraction measurements
            results = dataset.GetResult('PTKCTDensityAnalysis', context);
            if isempty(results)
                results = PTKMetrics.empty;
                return;
            end
            
            % Merge in emphysema results
            emphysema_results = dataset.GetResult('PTKEmphysemaAnalysis', context);
            results.Merge(emphysema_results);
            
            % Merge in airway results
            airway_metrics = dataset.GetResult('PTKAirwayAnalysis', context);
            if ~isempty(airway_metrics)
                results.Merge(airway_metrics, reporting);
            end
        end
    end
end