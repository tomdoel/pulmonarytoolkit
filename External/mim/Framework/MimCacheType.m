classdef MimCacheType
    % Used to select a particular cache for loading/saving
    %
    % Results are saved to different caches. Used with
    % MimDatasetCacheSelector to choose which cache to use
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    enumeration
        Results   % Automaticly generated plugin results
        Edited    % Edited results
        Manual    % Manual segmentations
        Markers   % Marker lists
        Framework % Framework files for internal use
    end
end

