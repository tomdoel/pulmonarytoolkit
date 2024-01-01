classdef PTKTutorial < MimScript
    % PTKTutorial. Script containing code from the tutorials
    %
    %     This script provides tohe code in the PTK Tutorials.
    %     
    %     The tutorial is not really meant to be run from this script; 
    %     it is intended to be run in the Matlab Command Window, or by creating your own script.
    %
    %     Hence this PTKScript is mainly for testing purposes, but you can run it if you like using PTK's RunScript() method.
    %     You will need to specify a path to some Dicom lung image volume files.
    %     For example::
    %
    %       PTKAddPaths()
    %       ptk_main = PTKMain();
    %       ptk_main.RunScript('PTKTutorial', source_path_dicom);
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        InterfaceVersion = '1'
        Version = '1'
        Category= 'Analysis'
    end
    
    methods (Static)
        function output = RunScript(ptk_obj, reporting, varargin)
            output = [];
            
            % Tutorial 3
            
            % 2. Starting the Toolkit using the API
            
            % In your own scripts you would create this using ptk_main = PTKMain(), 
            % but Scripts provide the ptk_object for you
            ptk_main = ptk_obj;
            
            source_path = varargin{1}; % First additional argument to RunScript is the source_path for your Dicom file series
            
            dataset = ptk_main.Load(source_path);
            file_infos = PTKDicomUtilities.GetListOfDicomFiles(source_path);
            dataset = ptk_main.CreateDatasetFromInfo(file_infos);
            
            % 3. Creating a PTKDataset using a UID
            uid = ptk_main.ImportData(source_path)
            d = ptk_main.CreateDatasetFromUid(uid);
            
            % 4. Running algorithms and getting results
            lobes = dataset.GetResult('PTKLobes');
            airway_centreline = dataset.GetResult('PTKAirwayCentreline')
            
            % 5. Documentation
            help PTKImage
            
            % 6. Viewing images with the PTKViewer
            PTKViewer(lobes);
            ct_image = dataset.GetResult('PTKLungROI');
            image_viewer = PTKViewer(ct_image);
            image_viewer.ViewerPanelHandle.Window = 1600;
            image_viewer.ViewerPanelHandle.Level = -600;
            image_viewer.ViewerPanelHandle.OverlayImage = lobes;
            
            % 7. Viewing images in 3D
            smoothing_size_mm = 4;
            PTKVisualiseIn3D([], lobes, smoothing_size_mm, false);

            % 8. Saving out image results
            PTKSaveAs(lobes, 'Patient Name', '~/Desktop');
            MimSaveAsNifti(lobes, '~/Desktop', 'lobes.nii');
            frame = image_viewer.ViewerPanelHandle.Capture();
            imwrite(frame.cdata, '~/Desktop/lung_and_lobes.tif');
            PTKShow2DSlicesInOneFigure(image_viewer.ViewerPanelHandle, PTKImageOrientation.Coronal, 20);
            
            % 9. Saving out airway results
            airway_centreline = dataset.GetResult('PTKAirwayCentreline')
            PTKSaveTreeAsVTK(airway_centreline.AirwayCentrelineTree, '~/Desktop', 'MyTreeFilename', PTKCoordinateSystem.DicomUntranslated, ct_image);
        end
    end
end