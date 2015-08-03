function isDicom = DMisdicom(fileName)
    % DMisdicom. Tests whether a file is in DICOM format
    %
    % Usage:
    %     isDicom = DMisdicom(fileName)
    %
    %     fileName: path and filename of the file to test
    %
    %  Returns:
    %     true if the file appears to be a Dicom file
    %
    %
    %
    %     Licence
    %     -------
    %     Part of DicoMat. https://github.com/tomdoel/dicomat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    fileId = fopen(fileName);
    if fileId <= 0
        error('DMisdicom:OpenFileFailed', ['Unable to open file ' fileName]);
    end

    preamble = fread(fileId, 132, 'uint8');
    if numel(preamble) < 132
        isDicom = false;
        return;
    end
    dicomChars = char(preamble(129:132)');
    isDicom = strcmp(dicomChars, 'DICM');
    fclose(fileId);
end