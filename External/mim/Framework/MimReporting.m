classdef MimReporting < CoreReporting
    % MimReporting. Provides error, message and progress reporting.
    %
    %     MimReporting is an extension of CoreReporting. CoreReporting
    %     provides error, progress and warning methods for MIM routines.
    %     MimReporting provides additional methods allowing updates to a
    %     MIM viewer if it exists.
    %
    %     The purpose of MimReporting is to allow algorithms to manipulate
    %     the viewer for the benefit of the user (e.g. updating the
    %     segmentatino in real time) while fully supporting non-gui modes.
    %
    %     Usage
    %     -----
    %
    %     Normally you would not create MimReporting directly. If you are
    %     implementing a MimPlugin then a suitable MimReporting object is
    %     passed in when your plugin is called, and that is the object you
    %     should pass to any library function that requires a MimReporting.
    %
    %     If you are directly calling a library function from outside of
    %     the Mim Framework, you can create a CoreReportingDefault object
    %     for default erorr and progress reporting.
    %
    %     See CoreReporting.m and CoreReportingIntertface.m for details of
    %     the methods this class implements.
    %
    %     You only need to create your own MimReporting class if you want
    %     to customise error and progress reporting.
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
        function obj = MimReporting(progress_dialog, verbose_mode, log_file_name)
            obj = obj@CoreReporting(progress_dialog, verbose_mode, log_file_name);            
        end
        
        function ChangeViewingPosition(obj, coordinates)
            if ~isempty(obj.ViewingPanel)
                obj.ViewingPanel.SliceNumber = coordinates;
            end
        end
        
        function ChangeViewingOrientation(obj, orientation)
            if ~isempty(obj.ViewingPanel)
                obj.ViewingPanel.Orientation = orientation;
            end
        end
        
        function UpdateOverlayImage(obj, new_image)
            if ~isempty(obj.ViewingPanel)
                obj.ViewingPanel.OverlayImage.ChangeSubImage(new_image);
                obj.ViewingPanel.OverlayImage.ImageType = new_image.ImageType;
            end
        end
        
        function UpdateOverlaySubImage(obj, new_image)
            if ~isempty(obj.ViewingPanel)
                obj.ViewingPanel.OverlayImage.ChangeSubImage(new_image);
            end
        end
        
        function SetViewerPanel(obj, viewer_panel)
            obj.ViewingPanel = viewer_panel;
        end
        
        function OpenPath(obj, file_path, message)
            % If there is a viewing panel, we assume this is a GUI-based application, and so
            % it is acceptable to open a window to the file path. Otherwise we display a
            % message
            
            if isempty(obj.ViewingPanel)
                disp([message, ': ', file_path]);
            else
                CoreDiskUtilities.OpenDirectoryWindow(file_path);
            end
        end
    end
end

