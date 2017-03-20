classdef MimMatNatDatabase < handle
    % MimMatNatDatabase. Part of the internal framework of the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the TD MIM Toolkit.
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        Database
    end
    
    events
        DatabaseHasChanged
        SeriesHasBeenDeleted
    end
    
    methods
        function obj = MimMatNatDatabase(mnConfig)
            restClient = MatNatRestClient(mnConfig);
            obj.Database = MatNatDatabase(restClient, mnConfig);
        end
        
        function datasets = GetAllSeriesForThisPatient(obj, project_id, patient_id)
            datasets = {};
            project = obj.Database.getProject(project_id);
            if ~isempty(project)
                subject = project.getSubject(patient_id);
                if ~isempty(subject)
                    for session = subject.getSessionMap.values
                        for scan = session{1}.getScanMap.values
                            scan_struct = [];
                            scan_struct.SeriesDescription = scan{1}.Id;
                            scan_struct.StudyDescription = session{1}.Label;
                            scan_struct.Modality = scan{1}.Modality.Name;
                            scan_struct.Date = [];
                            scan_struct.Time = [];
                            scan_struct.SeriesUid = scan{1}.Id;
                            scan_struct.StudyUid = session{1}.Id;
                            dataset = MimMatNatDatabaseSeries(scan{1}.Id, scan_struct, scan{1}.CountImages);
                            datasets{end + 1} = dataset;
                        end
                    end
                end
            end
        end
        
        function [names, ids, short_visible_names, patient_id_map] = GetListOfPatientNames(obj, project_id)
            names = {};
            ids = {};
            short_visible_names = {};
            patient_id_map = containers.Map;
            
            project = obj.Database.getProject(project_id);
            
            if ~isempty(project)
                for subject = project.getSubjectMap.values
                    names{end + 1} = subject{1}.Label;
                    short_visible_names{end + 1} = subject{1}.Label;
                    ids{end + 1} = subject{1}.Id;
                    patient_id_map(subject{1}.Id) = subject{1}.Id;
                end
            end
        end
        
        
        function [names, ids, short_visible_names, num_series, num_patients_combined, patient_id_map] = GetListOfPatientNamesAndSeriesCount(obj, project_id)
            names = {};
            ids = {};
            short_visible_names = {};
            num_series = [];
            num_patients_combined = [];
            patient_id_map = containers.Map;
            
            project = obj.Database.getProject(project_id);
            
            if ~isempty(project)
                for subject = project.GetSubjectMap.values
                    names{end + 1} = subject.Label;
                    short_visible_names{end + 1} = subject.Label;
                    ids{end + 1} = subject.Id;
                    
                    % We assume one series per scan, in order to avoid calling
                    % getResources which takes a long time if there are many
                    % scans
                    num_series(end + 1) = subject.CountScans;
                    
                    patient_id_map(subject.Id) = subject.Id;
                end
                
                num_patients_combined = ones(size(names));
            end
        end
        
        function [project_names, project_ids] = GetListOfProjects(obj)
            project_names = {};
            project_ids = {};
            for project = obj.Database.getProjectMap.values
                project_names{end + 1} = project{1}.Name;
                project_ids{end + 1} = project{1}.Id;
            end
        end
        
        function unzipDir = downloadScan(obj, project_id, patient_id, series_uid)
            unzipDir = obj.Database.downloadScan(project_id, patient_id, series_uid);
        end
        
    end
    
    methods (Access = private)
        function ImageDatabaseChanged(obj, ~, ~)
            notify(obj, 'DatabaseHasChanged');
        end
    end
    
end