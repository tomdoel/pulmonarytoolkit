classdef PTKMRIToGasMRIMatrix < PTKPlugin
    % PTKMRIToGasMRIMatrix. Computes the rigid translation matrix from proton MRI to
    % gas MRI datasets based on the patient position metadata
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
        ButtonText = 'MRI to gas <BR>MRI matrix'
        ToolTip = ''
        Category = 'Registration'
        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = 'ReplaceOverlay'
        HidePluginInDisplay = true
        FlattenPreviewImage = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = false
    end
    
    methods (Static)
        
        function results = RunPlugin(dataset, reporting)
            
            if ~dataset.IsGasMRI
                reporting.Error('PTKMRIToGasMRIMatrix:NotAGasMRIImage', 'PTKMRIToGasMRIMatrix is intended to be called on a gas MRI dataset but this does not appear to be a gas MRI dataset.');
            end
            
            % Fetch a proton MRI image
            mr_lung = dataset.GetResult('PTKLungROI', [], 'MR');
            
            % Fetch a gas MRI image
            gas_lung = dataset.GetResult('PTKLungROI', [], '');
            
            % Compute the translation matrix using the metadata from the images
            mr_to_gas_affine_matrix = PTKImageCoordinateUtilities.GetAffineTranslationFromPatientPosition(gas_lung, mr_lung);
            gas_to_mr_affine_matrix = PTKImageCoordinateUtilities.GetAffineTranslationFromPatientPosition(mr_lung, gas_lung);
            
            results = [];
            results.MrGasMrMatrix = mr_to_gas_affine_matrix;
            results.GasMrMrMatrix = gas_to_mr_affine_matrix;
        end
    end
end