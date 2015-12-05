function imageData = DMdicomread(fileName_or_metaHeader)
    % DMdicomread Reads image data from a Dicom file
    %
    % Usage:
    %     imageData = DMdicomread(fileName)
    %         fileName: path and filename of the file to test
    %
    %     imageData = DMdicomread(metaheader)
    %         metaheader: structure returned from DMdicominfo
    %
    %  Returns:
    %     The pixel data
    %
    %
    %
    %     Licence
    %     -------
    %     Part of DicoMat. https://github.com/tomdoel/dicomat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
    %

    if isstruct(fileName_or_metaHeader)
        fileName = fileName_or_metaHeader.Filename;
    else
        fileName = fileName_or_metaHeader;
    end
    
    header = DMReadDicomTags(fileName, DMDicomDictionary.EssentialDictionary);
    if isfield(header, 'PixelData')
        imageData = header.PixelData;
    else
        imageData = [];
    end
end