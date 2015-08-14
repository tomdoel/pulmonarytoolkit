classdef MatNatSession < MatNatBase
    % MatNatSession A Matlab class representing an XNAT session
    %
    %     Licence
    %     -------
    %     Part of MatNat. https://github.com/tomdoel/matnat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    properties (SetAccess = protected)
        Label
        Id
        ProjectId
        SubjectLabel
    end
    
    properties (Access = private)
        RestClient
        ScanMap
    end
    
    methods
        function obj = MatNatSession(restClient)
            obj.RestClient = restClient;
        end
        
        function scanMap = getScanMap(obj)
            % Returns a map of scan IDs to MatNatScan objects
            
            obj.populateScanMapIfNecessary;
            scanMap = obj.ScanMap;
        end
        
        function number_of_scans = CountScans(obj)
            % Returns the number of scans in this session
            
            obj.populateScanMapIfNecessary;
            number_of_scans = obj.ScanMap.Count;
        end
    end

    methods (Access = private)
        function populateScanMapIfNecessary(obj)
            if isempty(obj.ScanMap)
                obj.ScanMap = obj.RestClient.getScanMap(obj.ProjectId, obj.SubjectLabel, obj.Label);
            end
        end
    end
        
    methods (Static)
        function obj = createFromServerObject(restClient, serverObject, projectId, subjectLabel)
            % Creates a MatNatSession based on the information
            % structure returned from the XNAT server
            
            obj = MatNatSession(restClient);
            obj.ProjectId = projectId;
            obj.SubjectLabel = subjectLabel;
            obj.Label = MatNatBase.getOptionalProperty(serverObject, 'label');
            obj.Id = MatNatBase.getOptionalProperty(serverObject, 'ID');
        end
    end
end

