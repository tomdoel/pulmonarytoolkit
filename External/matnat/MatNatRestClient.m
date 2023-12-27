classdef MatNatRestClient < handle
    % MatNatRestClient Provides an API for communicating with an XNAT server via REST calls
    %
    %     Licence
    %     -------
    %     Part of MatNat. https://github.com/tomdoel/matnat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        sessionCookie % The JSESSIONID cookie string for this session
        config % a MatNatConfiguration object used to get the server, username etc.
        authenticatedBaseUrl % The URL of the XNAT server for which the session cookie is valid
    end
    
    methods
        function obj = MatNatRestClient(config)
            % Creates a new MatNat object using the supplied configuraton
            
            if nargin < 1
                config = MatNatConfiguration;
            else
                if ~isa(config, 'MatNatConfiguration')
                    throw Exception('The configuration object must be of class MatNatConfiguration');
                end
            end
            
            obj.config = config;
        end
        
        function projectMap = getProjectMap(obj)
            % Returns a map of project IDs to MatNatProject objects containing project metadata
            
            structFromServer = obj.requestJson('REST/projects', 'format', 'json', 'owner', 'true', 'member', 'true');
            projectMap = containers.Map();
            
            if ~isempty(structFromServer)
                objectList = structFromServer.ResultSet.Result;
                
                for object = objectList'
                    newProject = MatNatProject.createFromServerObject(obj, object);
                    projectMap(newProject.Id) = newProject;
                end
            end
        end
        
        function subjectMap = getSubjectMap(obj, projectName)
            % Returns a map of subject IDs to MatNatSubject objects containing subject metadata
            
            structFromServer = obj.requestJson(['REST/projects/' projectName '/subjects'], 'format', 'json', 'owner', 'true', 'member', 'true', 'columns', 'DEFAULT');
            subjectMap = containers.Map();
            
            if ~isempty(structFromServer)
                objectList = structFromServer.ResultSet.Result;
                
                for object = objectList'
                    newSubject = MatNatSubject.createFromServerObject(obj, object, projectName);
                    subjectMap(newSubject.Id) = newSubject;
                end
            end
        end
        
        function sessionMap = getSessionMap(obj, projectName, subjectName)
            % Returns a map of session IDs to MatNatSession objects containing session metadata
            
            structFromServer = obj.requestJson(['REST/projects/' projectName '/subjects/' subjectName '/experiments'], 'format', 'json', 'owner', 'true', 'member', 'true');
            sessionMap = containers.Map();
            
            if ~isempty(structFromServer)
                objectList = structFromServer.ResultSet.Result;
                for object = objectList'
                    newSession = MatNatSession.createFromServerObject(obj, object, projectName, subjectName);
                    sessionMap(newSession.Id) = newSession;
                end
            end
        end
        
        function scanMap = getScanMap(obj, projectName, subjectName, sessionName)
            % Returns a map of scan IDs to MatNatScan objects containing scan metadata

            structFromServer = obj.requestJson(['REST/projects/' projectName '/subjects/' subjectName '/experiments/' sessionName '/scans'], 'format', 'json', 'owner', 'true', 'member', 'true');
            scanMap = containers.Map();
            
            if ~isempty(structFromServer)
                objectList = structFromServer.ResultSet.Result;
                for object = objectList'
                    newScan = MatNatScan.createFromServerObject(obj, object, projectName, subjectName, sessionName);
                    scanMap(newScan.Id) = newScan;
                end
            end
        end
        
        function resourceList = getResourceList(obj, projectName, subjectName, sessionName, scanLabel)
            % Returns an array of MatNatScans containing scan metadata

            structFromServer = obj.requestJson(['REST/projects/' projectName '/subjects/' subjectName '/experiments/' sessionName '/scans/' scanLabel '/resources'], 'format', 'json', 'owner', 'true', 'member', 'true');
            resourceList = MatNatResource.empty;
            
            if ~isempty(structFromServer)
                objectList = structFromServer.ResultSet.Result;
                for object = objectList'
                    resourceList(end + 1) = MatNatResource.createFromServerObject(obj, object, projectName, subjectName, sessionName, scanLabel);
                end
            end
        end        

        function downloadScanToZipFile(obj, zipfileName, projectName, subjectName, sessionName, scanName, resourceName)
            % Downloads a zip file containing the scans

            obj.requestAndSaveFile(zipfileName, ['REST/projects/' projectName '/subjects/' subjectName '/experiments/' sessionName '/scans/' scanName '/resources/' resourceName '/files'], 'format', 'zip');
        end
    end
    
    methods (Access = private)
        function returnValue = requestJson(obj, url, varargin)
            % Performs a request call
            
            returnValue = obj.request(url, varargin{:}, 'MediaType', 'application/json', 'ContentType', 'json');
        end
        
        function returnValue = request(obj, url, varargin)
            % Performs a request call
            
            if isempty(obj.sessionCookie)
                obj.forceAuthentication;
            end
            options = weboptions('RequestMethod', 'get', 'KeyName', 'Cookie', 'KeyValue', ['JSESSIONID=' obj.sessionCookie]);
            try
                returnValue = webread([obj.authenticatedBaseUrl url], varargin{:}, options);
            catch exception
                if strcmp(exception.identifier, 'MATLAB:webservices:HTTP404StatusCodeError')
                    returnValue = [];
                else
                    rethrow(exception);
                end
            end
        end
        
        function returnValue = requestAndSaveFile(obj, filePath, url, varargin)
            % Performs a request call to obtain and save a resource
            
            if isempty(obj.sessionCookie)
                obj.forceAuthentication;
            end
            options = weboptions('RequestMethod', 'get', 'KeyName', 'Cookie', 'KeyValue', ['JSESSIONID=' obj.sessionCookie]);
            try
                returnValue = websave(filePath, [obj.authenticatedBaseUrl url], varargin{:}, options);
            catch exception
                if strcmp(exception.identifier, 'MATLAB:webservices:HTTP404StatusCodeError')
                    returnValue = [];
                else
                    rethrow(exception);
                end
            end
        end        
        
        function forceAuthentication(obj)
            % Forces the server to initiate a new session and issue a new
            % session cookie
            
            baseUrl = deblank(obj.config.getBaseUrl);
            if baseUrl(end) ~= '/'
                baseUrl = [baseUrl '/'];
            end
            url = [baseUrl 'data/JSESSION'];
            options = weboptions('Username', obj.config.getUserName, 'Password', obj.config.getPassword);
            obj.sessionCookie = webread(url, options);
            obj.authenticatedBaseUrl = baseUrl;
        end
    end
    
end

