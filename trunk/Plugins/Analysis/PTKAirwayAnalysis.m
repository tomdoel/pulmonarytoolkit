classdef PTKAirwayAnalysis < PTKPlugin
    % PTKAirwayAnalysis. Plugin for performing analysis of airways
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
        ButtonText = 'Airway<br>analysis'
        ToolTip = ''
        Category = 'Analysis'

        Context = PTKContextSet.Any
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
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
            bronchus = dataset.GetResult('PTKAirwayForContext', context);
            if numel(bronchus) > 1
                if bronchus(1).Radius >= bronchus(2).Radius
                    bronchus = bronchus(1);
                else
                    bronchus = bronchus(2);
                end
            end
            
            image_roi = dataset.GetResult('PTKLungROI', PTKContext.LungROI);
            bronchus_results = PTKGetWallThicknessForBranch(bronchus, image_roi, context, [], []);
            
            if isempty(bronchus_results)
                results = [];
            else
                results = PTKMetrics;
                results.AddMetric('Radius', bronchus_results.FWHMRadiusMean, 'Mean airway lumen radius (mm)');
                results.AddMetric('WallThickness', bronchus_results.FWHMWallThicknessMean, 'Mean airway wall thickness (mm)');
                results.AddMetric('RadiusStd', bronchus_results.FWHMRadiusStd, 'Std of airway lumen radius (mm)');
                results.AddMetric('WallThicknessStd', bronchus_results.FWHMWallThicknessStd, 'Std of airway wall thickness (mm)');
            end
        end
    end
end