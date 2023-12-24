classdef MatNatProject < MatNatBase
    % A Matlab class representing an XNAT project
    %
    % .. Licence
    %    -------
    %    Part of MatNat. https://github.com/tomdoel/matnat
    %    Author: Tom Doel, 2015.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    properties (SetAccess = protected)
        Name
        Id
        SecondaryId
        Description
    end
       
    properties (Access = private)
        RestClient
        SubjectMap
    end
    
    methods
        function obj = MatNatProject(restClient)
            obj.RestClient = restClient;
        end
        
        function subjectMap = getSubjectMap(obj)
            % Returns a map of subject identifiers to MatNatSubject objects
            
            obj.populateSubjectMapIfNecessary;
            subjectMap = obj.SubjectMap;
        end
        
        function subject = getSubject(obj, patient_id)
            % Returns the MatNatSubject object corresponding to the given
            % subject identifier
            
            if isempty(patient_id)
                subject = [];
                return;
            end
            
            obj.populateSubjectMapIfNecessary;
            if ~obj.SubjectMap.isKey(patient_id)
                subject = [];
            else
                subject = obj.SubjectMap(patient_id);
            end
        end
        
        function resource = GetResourceForSeriesUid(obj, patient_id, series_uid)
            % Gets the first resource for the series with this identifier
            
            subject = obj.getSubject(patient_id);
            if ~isempty(subject)
                scan = subject.FindScan(series_uid);
                if ~isempty(scan)
                    resources = scan.getResources;
                    if numel(resources) > 0
                        resource = resources(1);
                        return;
                    end
                end
            end
            resource = [];
        end        
    end
    
    methods (Access = private)
        function populateSubjectMapIfNecessary(obj)
            if isempty(obj.SubjectMap)
                obj.SubjectMap = obj.RestClient.getSubjectMap(obj.Id);
            end
        end
    end
    
    methods (Static)
        function obj = createFromServerObject(restClient, serverObject)
            % Creates a MatNatProject based on the project information
            % structure returned from the XNAT server
            
            obj = MatNatProject(restClient);
            obj.Name = MatNatBase.getOptionalProperty(serverObject, 'name');
            obj.Id = MatNatBase.getOptionalProperty(serverObject, 'id');
            obj.SecondaryId = MatNatBase.getOptionalProperty(serverObject, 'secondary_id');
            obj.Description = MatNatBase.getOptionalProperty(serverObject, 'description');
        end    
    end
end

