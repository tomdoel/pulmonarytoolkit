classdef PTKReporting < CoreReporting
    % PTKReporting. Provides error, message and progress reporting.
    %
    %     PTKReporting. Implementation of CoreReportingInterface, used by
    %     the Pulmonary Toolkit for progress and error/message reporting.
    %
    %     Usage
    %     -----
    %
    %     You can create a single PTKReporting object and pass it into all the
    %     Pulmonary Toolkit routines you use in order to provide error, warning,
    %     message and progress reporting during execution of routines.
    %
    %     If you are not writing a gui application but would like a standard
    %     pop-up progress dialog to appear while waiting for plugins to execute,
    %     consider creating a CoreReportingDefault object instead. Use CoreReporting
    %     if you want to specify your own progress dialog, or specify a gui
    %     viewing panel, or if you want no progress dialog at all.
    %
    %         reporting = PTKReporting(progress_dialog);
    %
    %             progress_dialog - a CoreProgressDialog or GemProgressPanel object
    %                 for displaying a progress bar. You can omit this argument
    %                 or replace it with [] if you are writing scripts to run 
    %                 in the background and do not want progress dialogs popping
    %                 up. Otherwise, you should create a PTKProgressDialog or
    %                 GemProgressPanel, or else implement your own progress class
    %                 with the same interface as PTKProgressDialog and pass this
    %                 in.
    %
    %         reorting.SetViewingPanel(viewing_panel)
    %             viewing_panel - if you are implementing a gui using a
    %                 PTKViewingPanel, then you can provide the class handle here
    %                 so that plugins can query which orientation the gui is in
    %                 and obtain the current marker image. Otherwise leave this
    %                 argment blank.
    %
    %     See CoreReportingIntertface.m for details of the methods this class
    %     implements.
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
        function obj = PTKReporting(progress_dialog, verbose_mode, log_file_name)
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
        
        function ErrorFromException(obj, identifier, message, ex)
            identifier = [ 'PTKMain:' identifier];
            ErrorFromException@CoreReporting(identifier, message, ex);
        end        
    end
end

