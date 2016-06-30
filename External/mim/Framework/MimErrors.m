classdef MimErrors < handle
    % MimErrors. Defines common error message identifiers to allow custom processing
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties (Constant, Transient)
        FileMissingErrorId = 'MimErrors:FileMissing'
        FileFormatUnknownErrorId = 'MimErrors:FileFormatUnknown'
        UidNotFoundErrorId = 'MimErrors:UidNotFound'
        RawFileNotFoundErrorId = 'MimErrors:RawFileNotFound'
    end

    methods (Static)
        function is_cancel_id = IsErrorCancel(error_id)
            is_cancel_id = strcmp(error_id, CoreReporting.CancelErrorId);
        end
        
        function is_error_missing_id = IsErrorFileMissing(error_id)
            is_error_missing_id = strcmp(error_id, MimErrors.FileMissingErrorId);
        end
        
        function is_error_missing_id = IsErrorUnknownFormat(error_id)
            is_error_missing_id = strcmp(error_id, MimErrors.FileFormatUnknownErrorId);
        end
        
        function is_error_missing_id = IsErrorUidNotFound(error_id)
            is_error_missing_id = strcmp(error_id, MimErrors.UidNotFoundErrorId);
        end
        
        function is_error_missing_id = IsErrorRawFileNotFound(error_id)
            is_error_missing_id = strcmp(error_id, MimErrors.RawFileNotFoundErrorId);
        end
    end
end

