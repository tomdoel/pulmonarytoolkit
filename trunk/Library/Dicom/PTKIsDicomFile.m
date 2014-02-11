function is_dicom = PTKIsDicomFile(file_path, file_name, reporting)
    % PTKIsDicomFile. Tests whether a file is in DICOM format
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    

    
    full_file_name = [file_path, filesep, file_name];
    
    file_id = fopen(full_file_name);
    if file_id <= 0
        if nargin < 3
            reporting = PTKReportingDefault;
        end
        reporting.Error('PTKIsDicomFile:OpenFileFailed', ['Unable to open file ' full_file_name]);
    end

    preamble = fread(file_id, 132, 'uint8');
    if numel(preamble) < 132
        is_dicom = false;
        return;
    end
    dicom_chars = char(preamble(129:132)');
    is_dicom = strcmp(dicom_chars, 'DICM');
    fclose(file_id);
end