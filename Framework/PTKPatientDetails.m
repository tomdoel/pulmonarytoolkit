classdef PTKPatientDetails < PTKBaseClass
    % PTKPatientDetails. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (SetAccess = private)
        Id
        Name
    end
    
    properties (Access = private)
        DatasetMap
    end
    
    methods
        function obj = PTKPatientDetails(patient_id, name)
            obj.Id = patient_id;
            obj.Name = name;
            obj.DatasetMap = containers.Map;
        end
        
        function obj = AddDataset(obj, dataset_information)
            obj.DatasetMap(dataset_information.Uid) = dataset_information;
        end
        
        function num_datasets = GetNumberOfDatasets(obj)
           num_datasets = obj.DatasetMap.length;
        end
        
        function datasets = GetDatasets(obj)
            datasets = obj.DatasetMap.values;
        end
    end
end