classdef PTKImageFileFormat
    % PTKImageFileFormat. An enumeration used to specify how a medical image is
    % stored
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    enumeration
        Dicom,      % DICOM format
        Metaheader, % Metaheader (mha/mhd) plus raw data
        Matlab,     % Matlab matrix
        Analyze     % Analyze format
    end
    
end

