classdef PTKDensityVsHeightCoronal < PTKPlugin
    % PTKDensityVsHeightCoronal. Plugin for showing a graph relating density to
    % distance along the anterior-posterior axis
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKDensityVsHeightCoronal opens a new window showing the graph.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        ButtonText = 'Density vs coronal distance'
        ToolTip = 'Shows a graph of the density vs distance along the anterior-posterior axis'
        Category = 'Analysis'
        
        AllowResultsToBeCached = false
        AlwaysRunPlugin = true
        PluginType = 'DoNothing'
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
        GeneratePreview = false
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            image_info = dataset.GetImageInfo;
            uid = image_info.ImageUid;
            template = dataset.GetTemplateImage(PTKContext.LungROI);
            patient_name = template.MetaHeader.PatientName.FamilyName;
            
            contexts = {PTKContextSet.SingleLung};
            results = dataset.GetResult('PTKCoronalAnalysis', contexts);
            
            table = PTKConvertMetricsToTable(results, patient_name, uid, PTKReportingDefault);
            
            results_directory = dataset.GetOutputPathAndCreateIfNecessary;
            
            figure_title = 'Density vs coronal distance';
            y_label = 'Distance along coronal axis (%)';
            
            context_list = [PTKContext.LeftLung, PTKContext.RightLung];
            
            figure_handle = PTKDrawMetricVsDistance(table, patient_name, 'MeanDensityGml', 'StdDensityGml', figure_title, y_label, context_list);
            
            figure_filename = fullfile(results_directory, 'DensityVsCoronalDistance');
            PTKDiskUtilities.SaveFigure(figure_handle, figure_filename);
            
            results = [];
        end
    end
end