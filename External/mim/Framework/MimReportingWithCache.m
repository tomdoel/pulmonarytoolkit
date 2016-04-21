classdef MimReportingWithCache < CoreReportingWithCache
    % MimReportingWithCache. Provides error, message and progress reporting.
    %
    %     MimReportingWithCache extends CoreReportingWithCache to provide
    %     additional, PTK-specific functions
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
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

