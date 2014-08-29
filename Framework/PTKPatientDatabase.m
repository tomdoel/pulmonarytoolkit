classdef PTKPatientDatabase < PTKBaseClass
    % PTKPatientDatabase. Part of the internal framework of the Pulmonary Toolkit.
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
    
    properties (Access = private)
        PatientMap
        Reporting
    end
    
    methods
        function obj = PTKPatientDatabase(reporting)
            obj.Reporting = reporting;
            obj.PatientMap = containers.Map;
        end
        
        function [names, ids] = GetListOfPatientNames(obj)
            ids = obj.PatientMap.keys;
            values = obj.PatientMap.values;
            names = PTKContainerUtilities.GetFieldValuesFromSet(values, 'Name');
        end
        
        function [names, ids] = GetSortedListOfPatientNames(obj)
            ids = obj.PatientMap.keys;
            values = obj.PatientMap.values;
            names = PTKContainerUtilities.GetFieldValuesFromSet(values, 'Name');
        end
        
        function patient_info = GetPatientInfo(obj)
            patient_info = obj.PatientMap.values;
        end
        
        function AddDataset(obj, dataset_info)
            patient_id = dataset_info.PatientId;
            patient_name = dataset_info.PatientName;
            if ~obj.PatientMap.isKey(patient_id)
                obj.PatientMap(patient_id) = PTKPatientDetails(patient_id, patient_name);
            end
            obj.PatientMap(patient_id).AddDataset(dataset_info);
        end

    end
end