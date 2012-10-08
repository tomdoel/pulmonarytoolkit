classdef PTKConfig
    % PTKConfig. User-definable settings for the Pulmonary Toolkit
    %
    %     You should modify this file if you need to change settings in the
    %     Toolkit, such as where the cache folder is stored
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Constant)
        % Leave empty unless you want the application settings 
        % and cache to be stored in a specific location
        CacheFolder = ''
    end
end

