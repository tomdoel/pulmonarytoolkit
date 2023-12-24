classdef PTKReporting < MimReporting
    % Legacy support function. Replaced by MimReporting
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    methods
        function obj = PTKReporting(progress_dialog, verbose_mode, log_file_name)
            obj = obj@MimReporting(progress_dialog, verbose_mode, log_file_name);            
        end
    end
end
