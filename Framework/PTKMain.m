classdef PTKMain < MimMain
    % Import and provide access to data from the Pulmonary Toolkit
    %
    % PTKMain is a specialist implementation of the MimMain class.
    % 
    % PTKMain provides access to data from the Pulmonary Toolkit, and allows 
    % you to import new data. Data is accessed through one or more MimDataset
    % objects. Your code should create a single PTKMain object, and then ask
    % it to create a MimDataset object for each dataset you wish to access. 
    % 
    % PTKMain is essentially a class factory for MimDatasets, but shares the 
    % MimReportingInterface (error/progress reporting) objects between all 
    % datasets, so you have a single error/progress reporting pipeline for 
    % your use of the Pulmonary Toolkit.
    % 
    % To import a new dataset, construct a PTKImageInfo object with the file
    % path and file name set to the image file. For DICOM files it is only
    % necessary to specify the path since all image files in that directory
    % will be imported. Then call CreateDatasetFromInfo. PTKMain will import
    % the data (if it has not already been imported) and return a new
    % MimDataset object for that dataset.
    % 
    % To access an existing dataset you can use CreateDatasetFromInfo as
    % above, or you can use CreateDatasetFromUid to retrieve a dataset which
    % has peviously been imported, using the UID that was associated with
    % that dataset.
    % 
    % Example:
    %     Replace <image path> and <filenames> with the path and filenames
    %     to your image data.
    % 
    %     image_info = PTKImageInfo( <image path>, <filenames>, [], [], [], []);
    %     ptk = PTKMain();
    %     dataset = ptk.CreateDatasetFromInfo(image_info);
    % 
    %     You can then obtain results from this dataset, e.g.
    % 
    %     airways = dataset.GetResult('PTKAirways');
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    methods
        function obj = PTKMain(reporting)
            % Constructor. If no error/progress reporting object is specified then a
            % default object is created.
            
            if nargin == 0
                reporting = CoreReportingDefault();
            end
            
            framework_def = PTKFrameworkAppDef;
            
            obj = obj@MimMain(framework_def, reporting);
        end
    end
end
