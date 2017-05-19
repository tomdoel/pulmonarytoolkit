classdef PTKAnalyseAndCollate < MimScript
    % PTKAnalyseAndCollate. Script for importing and analysing a number of
    % datasets, and collating results into an output folder
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        InterfaceVersion = '1'
        Version = '1'
        Category= 'Analysis'
    end
    
    methods (Static)
        function output = RunScript(ptk_obj, reporting, varargin)
            
            failures = [];
            success = [];
            ignored = [];
            root_dir = varargin{1};
            output_folders = varargin{2};
            output_file_name = varargin{3};
            uids = ptk_obj.ImportData(root_dir);
            log_file = fopen(output_file_name, 'w');
            fprintf(log_file, '%s\n', 'Started...');
            fclose(log_file);
            
            
            for uid = uids
                this_uid = uid{1};
                dataset = [];
                try
                    dataset = ptk_obj.CreateDatasetFromUid(this_uid);
                    im_info = dataset.GetImageInfo;
                    if isempty(im_info.Modality) || strcmp(im_info.Modality, 'CT')
                        filenames = im_info.ImageFilenames;
                        if numel(filenames) >= 50
                            lobes = dataset.GetResult('PTKSaveLobarAnalysisResults');
                            success{end + 1} = this_uid;
                            
                            patient_name = CoreTextUtilities.MakeFilenameValid(dataset.GetPatientName());
                            dataset_base_folder = fullfile(output_folders, patient_name, this_uid);
                            mkdir(dataset_base_folder);
                            
                            image_base_folder = fullfile(dataset_base_folder, 'Data');
                            mkdir(image_base_folder);
                            roi = dataset.GetResult('PTKLungROI');
                            MimSaveAsNifti(roi, image_base_folder, 'image.nii', reporting);
                            
                            segmentations_base_folder = fullfile(dataset_base_folder, 'Segmentations');
                            mkdir(segmentations_base_folder);
                            
                            lungs = dataset.GetResult('PTKLeftAndRightLungs');
                            MimSaveAsNifti(lungs, segmentations_base_folder, 'lungs.nii', reporting);
                            
                            lobes = dataset.GetResult('PTKLobes');
                            MimSaveAsNifti(lobes, segmentations_base_folder, 'lobes.nii', reporting);
                            
                            analysis_base_folder = fullfile(dataset_base_folder, 'Analysis');
                            mkdir(analysis_base_folder);
                            output_path = dataset.GetOutputPath();
                            copyfile(output_path, analysis_base_folder);
                            
                            log_file = fopen(output_file_name, 'a');
                            fprintf(log_file, 'Success: %s\n', this_uid);
                            fclose(log_file);
                        else
                            ignored{end + 1} = this_uid;
                            log_file = fopen(output_file_name, 'a');
                            fprintf(log_file, 'Ignored: %s\n', this_uid);
                            fclose(log_file);
                        end
                    else
                        ignored{end + 1} = this_uid;                    
                        log_file = fopen(output_file_name, 'a');
                        fprintf(log_file, 'Ignored: %s\n', this_uid);
                        fclose(log_file);
                    end
                catch ex
                    failures{end + 1} = this_uid;
                    log_file = fopen(output_file_name, 'a');
                    fprintf(log_file, 'Failed: %s\n', this_uid);
                    fclose(log_file);
                    reporting.ShowWarning('PTKImportAndAnalyse:Failure', ['Failure on dataset ' this_uid ' : ' ex.message], ex);
                end
                if ~isempty(dataset)
                    dataset.ClearCacheForThisDataset(false);
                end
            end
            
            log_file = fopen(output_file_name, 'a');
            fprintf(log_file, '%s\n', '...Complete');
            fclose(log_file);
            output.Failures = failures;
            output.Success = success;
            output.Ignored = ignored;
        end
    end
end