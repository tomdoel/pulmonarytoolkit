classdef MatNatSubject < MatNatBase
    % A Matlab class representing an XNAT subject
    %
    % .. Licence
    %    -------
    %    Part of MatNat. https://github.com/tomdoel/matnat
    %    Author: Tom Doel, 2015.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    properties (SetAccess = protected)
        Label
        Id
        ProjectId
    end
    
    properties (Access = private)
        RestClient
        SessionMap
    end

    methods
        function obj = MatNatSubject(restClient)
            obj.RestClient = restClient;
        end
        
        function session_map = getSessionMap(obj)
            % Returns a map of session IDs to MatNatSession objects
            
            obj.populateSessionMapIfNecessary;
            session_map = obj.SessionMap;
        end
        
        function scan = FindScan(obj, scan_id)
            % Finds a scan with the given scan id
            
            obj.populateSessionMapIfNecessary;
            for session = obj.SessionMap.values
                for scan_cell = session{1}.getScanMap.values
                    if strcmp(scan_cell{1}.Id, scan_id)
                        scan = scan_cell{1};
                        return;
                    end
                end
            end
            scan = [];
        end
        
        function scan_count = CountScans(obj)
            % Returns the total number of scans in all sessions for this subject 
            
            obj.populateSessionMapIfNecessary;
            scan_count = 0;
            for session = obj.sessionMap.values
                scan_count = scan_count + session{1}.CountScans;
            end
        end
    end
    
    methods (Access = private)
        function populateSessionMapIfNecessary(obj)
            if isempty(obj.SessionMap)
                obj.SessionMap = obj.RestClient.getSessionMap(obj.ProjectId, obj.Label);
            end
        end
    end
    
    methods (Static)
        function obj = createFromServerObject(restClient, serverObject, projectId)
            % Creates a MatNatSubject based on the prosubjectject information
            % structure returned from the XNAT server
            
            obj = MatNatSubject(restClient);
            obj.ProjectId = projectId;
            obj.Label = MatNatBase.getOptionalProperty(serverObject, 'label');
            obj.Id = MatNatBase.getOptionalProperty(serverObject, 'ID');
        end  
    end
end

