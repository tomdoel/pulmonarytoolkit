classdef PTKSaveSagittalAnalysisResults < PTKPlugin
    % PTKSaveSagittalAnalysisResults. Plugin for performing analysis of density using bins
    % along the left-right axis
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKSaveSagittalAnalysisResults divides the left-right axis into bins and
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
        ButtonText = 'Sagittal analysis'
        ToolTip = 'Performs density analysis in bins along the left-right axis'
        Category = 'Slice analysis'
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
            
            % Generate the results over the lungs and lobes
            contexts = {PTKContextSet.Lungs, PTKContextSet.SingleLung, PTKContextSet.Lobe};
            results = dataset.GetResult('PTKSagittalAnalysis', contexts);            
            
            % Convert the results into a PTKResultsTable
            image_info = dataset.GetImageInfo;
            uid = image_info.ImageUid;
            template = dataset.GetTemplateImage(PTKContext.LungROI);
            patient_name = [template.MetaHeader.PatientName.FamilyName '-'  template.MetaHeader.PatientID];
            table = PTKConvertMetricsToTable(results, patient_name, uid, reporting);

            % Save the results table as a series of CSV files
            dataset.SaveTableAsCSV('PTKSaveSagittalAnalysisResults', 'Sagittal analysis', 'SagittalResults', 'Density analysis in bins along the left-right axis', table, PTKResultsTable.ContextDim, PTKResultsTable.SliceNumberDim, PTKResultsTable.MetricDim, []);
            
            % Generate graphs of the results
            y_label = 'Distance along sagittal axis (%)';
            
            context_list_both_lungs = [PTKContext.Lungs];
            PTKSaveSagittalAnalysisResults.DrawGraphAndSave(dataset, table, y_label, context_list_both_lungs, '_CombinedLungs', reporting);

            context_list_single_lungs = [PTKContext.LeftLung, PTKContext.RightLung];
            PTKSaveSagittalAnalysisResults.DrawGraphAndSave(dataset, table, y_label, context_list_single_lungs, '_Lungs', reporting);
            
            context_list_lobes = [PTKContext.LeftLowerLobe, PTKContext.LeftUpperLobe, PTKContext.RightLowerLobe, PTKContext.RightMiddleLobe, PTKContext.RightUpperLobe];                        
            PTKSaveSagittalAnalysisResults.DrawGraphAndSave(dataset, table, y_label, context_list_lobes,  '_Lobes', reporting);
            
            results = [];
        end
    end
    
    methods (Static, Access = private)
        function DrawGraphAndSave(dataset, table, y_label, context_list, file_suffix, reporting)
            figure_handle = PTKGraphMetricVsDistance(table, 'MeanDensityGml', 'StdDensityGml', context_list, [], y_label, reporting);
            dataset.SaveFigure(figure_handle, 'PTKSaveSagittalAnalysisResults', 'Sagittal analysis', ['DensityVsSagittalDistance' file_suffix], 'Graph of density vs distance along the left-right axis');
            close(figure_handle);
            
            figure_handle = PTKGraphMetricVsDistance(table, 'EmphysemaPercentage', [], context_list, [], y_label, reporting);            
            dataset.SaveFigure(figure_handle, 'PTKSaveSagittalAnalysisResults', 'Sagittal analysis', ['EmphysemaVsSagittalDistance' file_suffix], 'Graph of emphysema vs distance along the left-right axis');
            close(figure_handle);
        end
    end        
end