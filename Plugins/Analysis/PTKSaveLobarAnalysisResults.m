classdef PTKSaveLobarAnalysisResults < PTKPlugin
    % PTKSaveLobarAnalysisResults. Plugin for performing analysis of lobe regions,
    % including airway, emphysema and volume analysis
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
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Lobar analysis'
        ToolTip = 'Performs density analysis over lungs and lobes'
        Category = 'Analysis'
        Mode = 'Analysis'

        Context = PTKContextSet.LungROI
        AllowResultsToBeCached = true
        AlwaysRunPlugin = true
        PluginType = 'DoNothing'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            image_info = dataset.GetImageInfo;
            uid = image_info.ImageUid;
            patient_name = dataset.GetPatientName;

            contexts = {PTKContextSet.Lungs, PTKContextSet.SingleLung, PTKContextSet.Lobe};
            results = dataset.GetResult('PTKDensityAnalysis', contexts);
            
            table = PTKConvertMetricsToTable(results, patient_name, uid, reporting);
            
            dataset.SaveTableAsCSV('PTKSaveLobarAnalysisResults', 'Lobar analysis', 'LobarResults', 'Analysis for lung and lobar regions', table, MimResultsTable.PatientDim, MimResultsTable.ContextDim, MimResultsTable.MetricDim, []);
        end
    end
end