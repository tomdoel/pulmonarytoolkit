function MimSaveMarkerListAsXml(path_name, marker_list, patient_name, series_uid, template_image, reporting)
    % Export a marker set into an xml file
    %
    % Syntax:
    %     MimSaveMarkerListAsXml(path_name, marker_list, patient_name, series_uid, template_image, reporting);
    %
    % Parameters:
    %     path_name: path where the output file is to be stored
    %     marker_list: the marker set
    %     patient_name: the patient name string
    %     series_uid: Series UID
    %     template_image: A PTKImage providing voxel size and image size parameters
    %     reporting (CoreReportingInterface): an object implementing 
    %         for reporting progress and warnings
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %

    coords_global = marker_list(:, 1:3);
    coords_mm = MimImageCoordinateUtilities.PTKToDicomCoordinates(coords_global, template_image);
    labels = marker_list(:, 4);    
     
    marker_struct_list = MimMarkerPoint.empty();
    for marker_index = 1: size(coords_mm, 1)
        x = coords_mm(marker_index, 1);
        y = coords_mm(marker_index, 2);
        z = coords_mm(marker_index, 3);
        c = labels(marker_index);
        new_marker_point = MimMarkerPoint(x, y, z, c);
        marker_struct_list(end + 1) = new_marker_point;
    end
    
    st = struct;
    st.MarkerXmlFileVersion = '1';
    st.PatientName = patient_name;
    st.SeriesUid = series_uid;
    st.CoordinateSystem = char(MimCoordinateSystem.Dicom);
    st.Markers = marker_struct_list;

    MimSaveMarkersAs(st, path_name, reporting);
end
