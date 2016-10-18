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
        function output = RunScript(ptk_obj, parameters, reporting)
            failures = [];
            success = [];
            ignored = [];
            root_dir = parameters;
            uids = ptk_obj.ImportData(root_dir);
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
                        else
                            ignored{end + 1} = this_uid;
                        end
                    else
                        ignored{end + 1} = this_uid;                    
                    end
                catch ex
                    failures{end + 1} = this_uid;
                    reporting.ShowWarning('PTKImportAndAnalyse:Failure', ['Failure on dataset ' this_uid ' : ' ex.message], ex);
                end
            end
            
            output.Failures = failures;
            output.Success = success;
            output.Ignored = ignored;
        end
    end
end