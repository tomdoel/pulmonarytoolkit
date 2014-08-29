classdef PTKFileSeriesGrouping < PTKBaseClass
    % PTKFileSeriesGrouping.
    %
    %        
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
        
    properties (SetAccess = private)
        SeriesUid
        Filenames
    end
    
    methods
        function obj = PTKFileSeriesGrouping(uid, filename)
            if nargin > 0
                obj.SeriesUid = uid;
                if ~isempty(filename)
                    obj.Filenames{1} = filename;
                end
            end
        end
        
        function AddFile(obj, filename)
            obj.Filenames{end + 1} = filename;
        end
    end
end

