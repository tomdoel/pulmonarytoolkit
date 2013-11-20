classdef TestPatientDatabase < PTKTest
    % TestPatientDatabase. Tests for the PTKPatientDatabase class.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
        
    methods
        function obj = TestPatientDatabase
            mock_reporting = MockReporting;            
            patient_database = PTKPatientDatabase(mock_reporting);
            
            
            series_1 = PTKSeriesDatabaseInfo(PTKTestUtilities.CreateMetaData('Patient A', 'A', '1', 'MR', 'test 1', 'study des1', '1'), 10);
            series_2 = PTKSeriesDatabaseInfo(PTKTestUtilities.CreateMetaData('Patient A', 'A', '2', 'CT', 'test 2', 'study des2', '2'), 20);
            series_3 = PTKSeriesDatabaseInfo(PTKTestUtilities.CreateMetaData('Patient B', 'B', '3', 'MR', 'test 3', 'study des3', '3'), 30);
            series_4 = PTKSeriesDatabaseInfo(PTKTestUtilities.CreateMetaData('Patient B', 'B', '4', 'CT', 'test 4', 'study des4', '4'), 40);
            series_5 = PTKSeriesDatabaseInfo(PTKTestUtilities.CreateMetaData('Patient C', 'C', '5', 'CT', 'test 5', 'study des5', '5'), 50);
            
            patient_database.AddDataset(series_1);
            patient_database.AddDataset(series_2);
            patient_database.AddDataset(series_3);
            patient_database.AddDataset(series_4);
            patient_database.AddDataset(series_5);
            
            [patient_names, ids] = patient_database.GetListOfPatientNames;
            obj.Assert(isequal(ids, {'A', 'B', 'C'}), 'Patient IDs are grouped correctly');
            obj.Assert(isequal(patient_names, {'Patient A', 'Patient B', 'Patient C'}), 'Patient IDs are grouped correctly');
        end
    end
end

