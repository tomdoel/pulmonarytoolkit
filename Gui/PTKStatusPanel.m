classdef PTKStatusPanel < PTKPanel
    % PTKStatusPanel. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKStatusPanel represents the panel holding the status text,
    %     which shows the current mouse coordinates and the values of the
    %     voxels under the mouse in the image and overlay.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Access = private)
        ViewerPanel
        StatusText
        StatusPanelHeight = 20;
    end
    
    methods
        function obj = PTKStatusPanel(parent, viewer_panel, reporting)
            obj = obj@PTKPanel(parent, reporting);
            
            obj.LeftBorder = true;
            obj.TopBorder = true;
            
            obj.ViewerPanel = viewer_panel;
            obj.StatusText = PTKText(obj, 'No Image', 'Coordinates of the voxel, relative to the image, the value of the voxel under the cursor, and the value of the overlay under the cursor', 'StatusText');
            obj.AddChild(obj.StatusText, obj.Reporting);
            obj.AddEventListener(viewer_panel, 'MouseCursorStatusChanged', @obj.MouseCursorStatusChangedCallback);                        
        end
        
        function Resize(obj, new_position)
            Resize@PTKPanel(obj, new_position);
            
            new_position = obj.InnerPosition;
            new_position(4) = new_position(4) - 1;
            obj.StatusText.Resize(new_position);
        end
        
        function height = GetRequestedHeight(obj, width)
            height = obj.StatusPanelHeight;
        end        
    end
    
    methods (Access = private)
        function MouseCursorStatusChangedCallback(obj, ~, ~)
            mouse_cursor_status = obj.ViewerPanel.MouseCursorStatus;
            orientation = obj.ViewerPanel.Orientation;
            
            if ~mouse_cursor_status.ImageExists
                status_text = 'No image';
            else
                rescale_text = '';
                
                i_text = int2str(mouse_cursor_status.GlobalCoordX);
                j_text = int2str(mouse_cursor_status.GlobalCoordY);
                k_text = int2str(mouse_cursor_status.GlobalCoordZ);
                
                if ~isempty(mouse_cursor_status.ImageValue)
                    voxel_value = mouse_cursor_status.ImageValue;
                    if isinteger(voxel_value)
                        value_text = int2str(voxel_value);
                    else
                        value_text = num2str(voxel_value, 3);
                    end
                    
                    value_combined_text = [' I:' value_text];
                    
                    rescaled_value = mouse_cursor_status.RescaledValue;
                    rescale_units = mouse_cursor_status.RescaleUnits;
                    if ~isempty(rescale_units) && ~isempty(rescaled_value)
                        rescale_text = [' ' rescale_units ':' int2str(rescaled_value)];
                    end
                    
                    if isempty(mouse_cursor_status.OverlayValue)
                        overlay_text = [];
                    else
                        overlay_value = mouse_cursor_status.OverlayValue;
                        if isinteger(overlay_value)
                            overlay_value_text = int2str(overlay_value);
                        else
                            overlay_value_text = num2str(overlay_value, 3);
                        end
                        overlay_text = [' O:' overlay_value_text];
                    end
                else
                    overlay_text = '';
                    value_combined_text = '';
                    switch orientation
                        case PTKImageOrientation.Coronal
                            j_text = '--';
                            k_text = '--';
                        case PTKImageOrientation.Sagittal
                            i_text = '--';
                            k_text = '--';
                        case PTKImageOrientation.Axial
                            i_text = '--';
                            j_text = '--';
                    end
                    
                end
                
                status_text = ['X:' j_text ' Y:' i_text ' Z:' k_text value_combined_text rescale_text overlay_text];
            end
            
            obj.SetStatus(status_text);
        end
        
        function SetStatus(obj, status_text)
            obj.StatusText.ChangeText(status_text);
        end
        
    end
end