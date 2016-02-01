classdef MatNatScan < MatNatBase
    % MatNatScan A Maplab class representing an XNAT scan
    %
    %     Licence
    %     -------
    %     Part of MatNat. https://github.com/tomdoel/matnat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    properties (SetAccess = protected)
        Id
        Modality
        
        ProjectId
        SubjectLabel
        SessionLabel
    end
    
    properties (Access = private)
        RestClient
        ResourceList
    end
    
    methods
        function obj = MatNatScan(restClient)
            obj.RestClient = restClient;
        end
                
        function resources = getResources(obj)
            % Returns an array of MatNatResource objects for this scan
            
            obj.populateResourceListIfNecessary;
            resources = obj.ResourceList;
        end
        
        function number_of_images = CountImages(obj)
            % Returns the number of images in this scan
            
            obj.populateResourceListIfNecessary;
            number_of_images = 0;
            for resource = obj.ResourceList
                number_of_images = number_of_images + resource.FileCount;
            end
        end
    end
    
    methods (Access = private)
        function populateResourceListIfNecessary(obj)
            if isempty(obj.ResourceList)
                obj.ResourceList = obj.RestClient.getResourceList(obj.ProjectId, obj.SubjectLabel, obj.SessionLabel, obj.Id);
            end
        end
    end
    
    methods (Static)
        function obj = createFromServerObject(restClient, serverObject, projectId, subjectLabel, sessionLabel)
            % Creates a MatNatScan based on the information
            % structure returned from the XNAT server
            
            obj = MatNatScan(restClient);
            obj.ProjectId = projectId;
            obj.SubjectLabel = subjectLabel;
            obj.SessionLabel = sessionLabel;
            obj.Id = MatNatBase.getOptionalProperty(serverObject, 'ID');
            obj.Modality = MatNatModality.getModalityFromXnatString(MatNatBase.getOptionalProperty(serverObject, 'xsiType'));
        end
    end
end

