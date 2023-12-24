function isDicom = DMisdicom(fileName)
    % Test whether a file is in DICOM format
    %
    % Syntax:
    %     isDicom = DMisdicom(fileName)
    %
    % Parameters:
    %     fileName: path and filename of the file to test
    %
    % Returns:
    %     true if the file appears to be a Dicom file
    %
    %
    %
    % .. Licence
    %    -------
    %    Part of DicoMat. https://github.com/tomdoel/dicomat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
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