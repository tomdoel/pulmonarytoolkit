function dicom_series = PTKGetDicomSeries(file_path, file_name, tags_to_get, reporting)
    % PTKGetDicomSeries. Gets the series UID for a Dicom file
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    if nargin < 3
        reporting = PTKReportingDefault;
    end

    if isempty(tags_to_get)
        tags_to_get = PTKDicomDictionary.GroupingTags;
    end
    
    header = PTKFastReadDicomHeader(file_path, file_name, tags_to_get, reporting);
    if ~isempty(header)
        dicom_series = header.SeriesInstanceUID;
    end
end