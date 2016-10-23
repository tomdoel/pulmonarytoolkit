classdef PTKImportAndAnalyse < PTKScript
    % PTKImportAndAnalyse. Script for importing and analysing a number of
    % datasets
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
            output_file_name = varargin{2};
            uids = ptk_obj.ImportData(root_dir);
            fileID = fopen(output_file_name, 'w');
            fprintf(fileID, '%s\n', 'Started...');
            fclose(fileID);
            
            
            for uid = uids
                this_uid = uid{1};
                try
                    dataset = ptk_obj.CreateDatasetFromUid(this_uid);
                    im_info = dataset.GetImageInfo;
                    if isempty(im_info.Modality) || strcmp(im_info.Modality, 'CT')
                        filenames = im_info.ImageFilenames;
                        if numel(filenames) >= 50
                            lobes = dataset.GetResult('PTKSaveLobarAnalysisResults');
                            success{end + 1} = this_uid;
                            fileID = fopen(output_file_name, 'a');
                            fprintf(fileID, 'Success: %s\n', this_uid);
                            fclose(fileID);
                        else
                            ignored{end + 1} = this_uid;
                            fileID = fopen(output_file_name, 'a');
                            fprintf(fileID, 'Ignored: %s\n', this_uid);
                            fclose(fileID);
                        end
                    else
                        ignored{end + 1} = this_uid;                    
                        fileID = fopen(output_file_name, 'a');
                        fprintf(fileID, 'Ignored: %s\n', this_uid);
                        fclose(fileID);
                    end
                catch ex
                    failures{end + 1} = this_uid;
                    fileID = fopen(output_file_name, 'a');
                    fprintf(fileID, 'Failed: %s\n', this_uid);
                    fclose(fileID);
                    reporting.ShowWarning('PTKImportAndAnalyse:Failure', ['Failure on dataset ' this_uid ' : ' ex.message], ex);
                end
            end
            
            fileID = fopen(output_file_name, 'a');
            fprintf(fileID, '%s\n', '...Complete');
            fclose(fileID);
            output.Failures = failures;
            output.Success = success;
            output.Ignored = ignored;
        end
    end
end