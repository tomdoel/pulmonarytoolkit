classdef PTKImageFileFormat
    % PTKImageFileFormat. An enumeration used to specify how a medical image is
    % stored
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    enumeration
        Dicom       (MimImageFileFormat.Dicom),      % DICOM format
        Metaheader  (MimImageFileFormat.Metaheader), % Metaheader (mha/mhd) plus raw data
        Matlab      (MimImageFileFormat.Matlab),     % Matlab matrix
        Analyze     (MimImageFileFormat.Analyze)     % Analyze format
    end
    
    properties (SetAccess = immutable)
        MimImageFileFormat
    end
    
    methods
        
        function obj = PTKImageFileFormat(mim_format)
            obj.MimImageFileFormat = mim_format;
        end
    end
end