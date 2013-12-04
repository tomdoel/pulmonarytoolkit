function dicom_series = PTKGetDicomSeries(file_path, file_name, reporting)
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

    tic
    tags_to_get = PTKDicomDictionary.GroupingTags;
    tag_map = tags_to_get.TagMap;
    tag_list = tags_to_get.TagList;
    toc
    
    header = PTKFastReadDicomHeader(file_path, file_name, tag_list, tag_map, reporting);
    if ~isempty(header)
        dicom_series = header.SeriesInstanceUID;
    end
end