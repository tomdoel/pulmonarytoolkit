classdef PTKSaveADCAnalysisResults < PTKPlugin
    % PTKSaveADCAnalysisResults.
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
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Mean ADC analysis'
        ToolTip = 'Computes mean ADC over lung regions'
        Category = 'Multi-modal analysis'
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
            template = dataset.GetTemplateImage(PTKContext.LungROI);
            patient_name = dataset.GetPatientName;

            contexts = {PTKContextSet.Lungs, PTKContextSet.SingleLung, PTKContextSet.Lobe};
            results = dataset.GetResult('PTKADCAnalysis', contexts);
            
            table = PTKConvertMetricsToTable(results, patient_name, uid, reporting);
            
            dataset.SaveTableAsCSV('PTKSaveADCAnalysisResults', 'ADC analysis', 'ADCResults', 'Mean ADC', table, MimResultsTable.PatientDim, MimResultsTable.ContextDim, MimResultsTable.MetricDim, []);
        end
    end
end