classdef PTKSaveCoronalAnalysisResults < PTKPlugin
    % PTKSaveCoronalAnalysisResults. Plugin for performing analysis of density using bins
    % along the anterior-posterior axis
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKSaveCoronalAnalysisResults divides the cranial-caudal axis into bins and
    %     performs analysis of the tissue density, air/tissue fraction and
    %     emphysema percentage in each bin.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        ButtonText = 'Coronal metrics'
        ToolTip = 'Performs density analysis in bins along the anterior-posterior axis'
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
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            
            % Generate the results over the lungs and lobes
            contexts = {PTKContextSet.Lungs, PTKContextSet.SingleLung, PTKContextSet.Lobe};
            results = dataset.GetResult('PTKCoronalAnalysis', contexts);            
            
            % Convert the results into a PTKResultsTable
            image_info = dataset.GetImageInfo;
            uid = image_info.ImageUid;
            template = dataset.GetTemplateImage(PTKContext.LungROI);
            patient_name = [template.MetaHeader.PatientName.FamilyName '-'  template.MetaHeader.PatientID];
            table = PTKConvertMetricsToTable(results, patient_name, uid, reporting);

            % Save the results table as a series of CSV files
            results_directory = dataset.GetOutputPathAndCreateIfNecessary;            
            PTKSaveTableAsCSV(results_directory, 'CoronalResults', table, PTKResultsTable.ContextDim, PTKResultsTable.SliceNumberDim, PTKResultsTable.MetricDim, [], reporting);
            
            % Generate graphs of the results
            y_label = 'Distance along coronal axis (%)';
            
            context_list_both_lungs = [PTKContext.Lungs];
            PTKSaveCoronalAnalysisResults.DrawGraphAndSave(table, y_label, context_list_both_lungs, results_directory, '_CombinedLungs', reporting);

            context_list_single_lungs = [PTKContext.LeftLung, PTKContext.RightLung];
            PTKSaveCoronalAnalysisResults.DrawGraphAndSave(table, y_label, context_list_single_lungs, results_directory, '_Lungs', reporting);
            
            context_list_lobes = [PTKContext.LeftLowerLobe, PTKContext.LeftUpperLobe, PTKContext.RightLowerLobe, PTKContext.RightMiddleLobe, PTKContext.RightUpperLobe];                        
            PTKSaveCoronalAnalysisResults.DrawGraphAndSave(table, y_label, context_list_lobes, results_directory, '_Lobes', reporting);
            
            results = [];
        end
    end
    
    methods (Static, Access = private)
        function DrawGraphAndSave(table, y_label, context_list, results_directory, file_suffix, reporting)
            figure_handle = PTKGraphMetricVsDistance(table, 'MeanDensityGml', 'StdDensityGml', context_list, [], y_label, reporting);
            PTKDiskUtilities.SaveFigure(figure_handle, fullfile(results_directory, ['DensityVsCoronalDistance' file_suffix]));
            close(figure_handle);
            
            figure_handle = PTKGraphMetricVsDistance(table, 'EmphysemaPercentage', [], context_list, [], y_label, reporting);            
            PTKDiskUtilities.SaveFigure(figure_handle, fullfile(results_directory, ['EmphysemaVsCoronalDistance' file_suffix]));            
            close(figure_handle);
        end
    end        
end