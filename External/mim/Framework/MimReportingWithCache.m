classdef MimReportingWithCache < CoreReportingWithCache
    % MimReportingWithCache. Provides error, message and progress reporting.
    %
    %     MimReportingWithCache extends CoreReportingWithCache to provide
    %     additional, MIM-specific functions
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    

    properties (Access = private)
        ViewingPanel    % Handle to gui viewing panel
    end
    
    methods
        function obj = MimReportingWithCache(reporting)
            obj = obj@CoreReportingWithCache(reporting);
        end
        
        function ChangeViewingPosition(obj, coordinates)
            if isa(obj.Reporting, 'MimReporting');
                obj.Reporting.ChangeViewingPosition(coordinates);
            end
        end
        
        function ChangeViewingOrientation(obj, orientation)
            if isa(obj.Reporting, 'MimReporting');
                obj.Reporting.ChangeViewingOrientation(orientation);
            end
        end
        
        function UpdateOverlayImage(obj, new_image)
            if isa(obj.Reporting, 'MimReporting');
                obj.Reporting.UpdateOverlayImage(new_image);
            end
        end
        
        function UpdateOverlaySubImage(obj, new_image)
            if isa(obj.Reporting, 'MimReporting');
                obj.Reporting.UpdateOverlaySubImage(new_image);
            end
        end
        
        function SetViewerPanel(obj, viewer_panel)
            if isa(obj.Reporting, 'MimReporting');
                obj.Reporting.SetViewerPanel(viewer_panel);
            end
        end
    end
end

