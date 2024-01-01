classdef PTKSaveUserAnalysisResults < PTKPlugin
    % PTKSaveUserAnalysisResults. Plugin for performing analysis of 
    % user-defined regions
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
        ButtonText = 'Manual regions analysis'
        ToolTip = 'Performs density analysis over manual segmentation regions'
        Category = 'CT regional'
        Visibility = 'Dataset'
        Mode = 'Analysis'

        Context = PTKContextSet.LungROI
        AllowResultsToBeCached = false
        AlwaysRunPlugin = true
        PluginType = 'DoNothing'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
        
        Icon = 'user_analysis.png'
        Location = 6        
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            image_info = dataset.GetImageInfo();
            patient_name = dataset.GetPatientName();
            uid = image_info.ImageUid;
            contexts = dataset.GetAllContextsForManualSegmentations();
            if isempty(contexts)
                results = [];
            else
                results_in = dataset.GetResult('PTKManualSegmentationDensityAnalysis', contexts);
                if isstruct(results_in)
                    % For multiple segmentations and/or labels we get
                    % multiple contexts and therefore multiple results;
                    % these are returned as fields of a struct
                    results = results_in;
                else
                    % This deals with the situation where there is only one
                    % context, in which case the PTK API will return the
                    % result rather than a structure containing the
                    % results as fields. But to label the table correctly
                    % we need to assemble into a struct
                    results = struct;
                    context_valid = CoreTextUtilities.CreateValidFieldName(char(contexts{1}));
                    results.(context_valid) = results_in;
                end

                table = PTKConvertMetricsToTable(results, patient_name, uid, CoreReportingDefault());            
                dataset.SaveTableAsCSV('PTKSaveUserAnalysisResults', 'User-defined analysis', 'ManualSegmentationResults', 'Analysis for manually segmented regions', table, MimResultsTable.PatientDim, MimResultsTable.ContextDim, MimResultsTable.MetricDim, []);
            end
        end

        function enabled = IsEnabled(gui_app)
            enabled = gui_app.IsDatasetLoaded() && gui_app.IsCT() && ~isempty(gui_app.GetListOfManualSegmentations());
        end
        
        function is_selected = IsSelected(gui_app)
            is_selected = false;
        end        
    end
end    
