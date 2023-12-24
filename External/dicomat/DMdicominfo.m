function metadata = DMdicominfo(fileName, dictionary)
    % DMdicominfo Reads metadata from a Dicom file
    %
    % Syntax:
    %     metadata = DMdicominfo(fileName);
    %     metadata = DMdicominfo(fileName, dictionary);
    %
    % Parameters:
    %     fileName: path and filename of the file to test
    %     dictionary: optional - Dicom dictionary specifying
    %         the tags to read. If not specified then common 
    %         tags will be read. To read all tags, use 
    %         DMDicomDictionary.CompleteDictionary. 
    %         See DMDicomDictionary for alternatives.
    %
    %  Returns:
    %     a structure containing the metadata from a Dicom file
    %
    %
    %
    % .. Licence
    %    -------
    %    Part of DicoMat. https://github.com/tomdoel/dicomat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the BSD 3-Clause license. Please see the file LICENSE for details.
    %

    if nargin < 2 || isempty(dictionary)
        dictionary = DMDicomDictionary.EssentialDictionaryWithoutPixelData;
    end
    
    metadata = DMReadDicomTags(fileName, dictionary);
    
    % The filename is not really part of the metadata but is included for
    % compatiblity with Matlab's image processing toolbox
    metadata.Filename = fileName;
end