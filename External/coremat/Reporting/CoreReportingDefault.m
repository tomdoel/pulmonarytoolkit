classdef CoreReportingDefault < CoreReporting
    % Provides error, message and progress reporting.
    %
    % CoreReporting. Implementation of CoreReportingInterface, which is used by
    % CoreMat and related libraries for progress and error/message reporting. This
    % is a convenient implementation with no constructor arguments which
    % creates a progress dialog and writes messages to the command window,
    % but which has no callbacks to the gui.
    %
    % This class is intended for use by CoreMat library functions
    % when no reporting object is given. It can also be used in your code
    % to create a default progress reporting implementation for input into
    % CoreMat and related libraries.
    %
    % See CoreReportingIntertface.m for details of the methods this class
    % implements.
    %
    %
    % .. Licence
    %    -------
    %    Part of CoreMat. https://github.com/tomdoel/coremat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    methods
        function obj = CoreReportingDefault
            obj = obj@CoreReporting(CoreProgressDialog);
        end        
    end
end