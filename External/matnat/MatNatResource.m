classdef MatNatResource < MatNatBase
    % MatNatResource An object representing an XNAT resource
    %
    %     Licence
    %     -------
    %     Part of MatNat. https://github.com/tomdoel/matnat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    properties (SetAccess = protected)
        Label
        FileCount
        Format
        
        ProjectId
        SubjectLabel
        SessionLabel
        ScanId
    end
    
    properties (Access = private)
        RestClient
    end
    
    methods
        function obj = MatNatResource(restClient)
            obj.RestClient = restClient;
        end
        
        function downloadScanToZipFile(obj, zipFile)
            % Downloads a scan as a zip file to the specified filename and
            % filepath
            obj.RestClient.downloadScanToZipFile(zipFile, obj.ProjectId, obj.SubjectLabel, obj.SessionLabel, obj.ScanId, obj.Label);
        end
    end
    
    methods (Static)
        function obj = createFromServerObject(restClient, serverObject, projectId, subjectLabel, sessionLabel, scanId)
            % Creates a MatNatScan based on the information
            % structure returned from the XNAT server
            
            obj = MatNatResource(restClient);
            obj.ProjectId = projectId;
            obj.SubjectLabel = subjectLabel;
            obj.SessionLabel = sessionLabel;
            obj.ScanId = scanId;
            
            obj.Label = MatNatBase.getOptionalProperty(serverObject, 'label');
            obj.FileCount = str2num(MatNatBase.getOptionalProperty(serverObject, 'file_count'));
            obj.Format = MatNatBase.getOptionalProperty(serverObject, 'format');
        end
    end
end

