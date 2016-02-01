function metadata = DMdicominfo(fileName, dictionary)
    % DMdicominfo Reads metadata from a Dicom file
    %
    % Usage:
    %     metadata = DMdicominfo(fileName)
    %
    %     fileName: path and filename of the file to test
    %
    %  Returns:
    %     a structure containing the metadata from a Dicom file
    %
    %
    %
    %     Licence
    %     -------
    %     Part of DicoMat. https://github.com/tomdoel/dicomat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
    %

    if nargin < 2 || isempty(dictionary)
        dictionary = DMDicomDictionary.EssentialDictionaryWithoutPixelData;
    end
    
    metadata = DMReadDicomTags(fileName, dictionary);
    
    % The filename is not really part of the metadata but is included for
    % compatiblity with Matlab's image processing toolbox
    metadata.Filename = fileName;
end