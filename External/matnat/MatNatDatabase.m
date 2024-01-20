classdef MatNatDatabase < handle
    % Contains the database of subjects and data on an XNAT server
    %
    % .. Licence
    %    -------
    %    Part of MatNat. https://github.com/tomdoel/matnat
    %    Author: Tom Doel, 2015.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        RestClient
        Config
        ProjectMap
    end
    
    methods
        function obj = MatNatDatabase(restClient, config)
            obj.Config = config;
            obj.RestClient = restClient;
        end
        
        function projects = getProjectMap(obj)
            % Returns a map of project IDs to MatNatProject objects
            
            obj.populateProjectMapIfNecessary;
            projects = obj.ProjectMap;
        end
        
        function project = getProject(obj, projectId)
            % Returns the MatNatProject object corresponding to the given ID
            
            obj.populateProjectMapIfNecessary;
            if obj.ProjectMap.isKey(projectId)
                project = obj.ProjectMap(projectId);
            else
                project = [];
            end
        end
        
        function scan_directory = downloadScan(obj, projectName, subjectName, scanName)
            % Downloads a scan and returns a temporary directory containing
            % the files
            
            fileNames = {};
            project = obj.getProject(projectName);
            
            if ~isempty(project)
                resource = project.GetResourceForSeriesUid(subjectName, scanName);
                
                uid = CoreSystemUtilities.GenerateUid;
                
                zipDir = fullfile(MatNatDatabase.getTempDir, 'zipped');
                if ~exist(zipDir, 'dir')
                    mkdir(zipDir);
                end
                
                unzipDir = fullfile(MatNatDatabase.getTempDir, 'unzipped');
                if ~exist(unzipDir, 'dir')
                    mkdir(unzipDir);
                end
                
                zipFile = fullfile(zipDir, [uid '.zip']);
                
                resource.downloadScanToZipFile(zipFile);
                unzippedFileNames = unzip(zipFile, unzipDir);
                delete(zipFile);
                rmdir(zipDir);
                
                scan_directory = obj.getScanDirectory(obj.Config.getServerName, projectName, subjectName, scanName);
                
                for fileName = unzippedFileNames
                    [~, namePart, extPart] = fileparts(fileName{1});
                    movefile(fileName{1}, scan_directory);
                    fileNames{end + 1} = fullfile(scan_directory, [namePart extPart]);
                end
            end
        end

        function application_directory = getApplicationDirectoryAndCreateIfNecessary(obj)
            home_directory = MatNatDatabase.getUserDirectory();
            application_directory = fullfile(home_directory, obj.Config.getApplicationDirectory);  
            if ~exist(application_directory, 'dir')
                mkdir(application_directory);
            end
        end

        function data_directory = getDataDirectoryAndCreateIfNecessary(obj)
            % Get the parent folder in which dataset cache folders are stored
            
            application_directory = obj.getApplicationDirectoryAndCreateIfNecessary;
            data_directory = fullfile(application_directory, 'Data');
            if ~exist(data_directory, 'dir')
                mkdir(data_directory);
            end
        end

        function scan_directory = getScanDirectory(obj, serverName, projectName, subjectName, scanName)
            % Get the parent folder in which dataset image files are stored
            
            data_directory = obj.getDataDirectoryAndCreateIfNecessary;
            scan_directory = fullfile(data_directory, serverName, projectName, subjectName, scanName);
            if ~exist(scan_directory, 'dir')
                mkdir(scan_directory);
            end
        end              
    end
    
    methods (Access = private)
        function populateProjectMapIfNecessary(obj)
            if isempty(obj.ProjectMap)
                obj.ProjectMap = obj.RestClient.getProjectMap;
            end
        end
    end
    
    methods (Static, Access = private)
        function temp_directory = getTempDir
            temp_directory = fullfile(tempdir, 'MatNat');
            if ~exist(temp_directory, 'dir')
                mkdir(temp_directory);
            end
        end
        
        function home_directory = getUserDirectory()
            % Returns a path to the user's home folder
            if (ispc)
                home_directory = getenv('USERPROFILE');
            else
                home_directory = getenv('HOME');
            end
        end
        
    end
end