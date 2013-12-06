classdef PTKReportingDefault < PTKReporting
    % PTKReportingDefault. Provides error, message and progress reporting.
    %
    %     PTKReporting. Implementation of PTKReportingInterface, which is used by
    %     the Pulmonary Toolkit for progress and error/message reporting. This
    %     is a convenient implementation with no constructor arguments which
    %     creates a progress dialog and writes messages to the command window,
    %     but which has no callbacks to the gui.
    %
    %     This class is intended for use by Pulmonary Toolkit library functions
    %     when no reporting object is given. It can also be used in your code
    %     to create a default progress reporting implementation for input into
    %     Pulmonary Toolkit routines.
    %
    %     See PTKReportingIntertface.m for details of the methods this class
    %     implements.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    methods
        function obj = PTKReportingDefault
            obj = obj@PTKReporting(PTKProgressDialog, [], false);
        end        
    end
end