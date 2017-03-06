classdef MimSegmentationButton < GemButton
    % MimSegmentationButton. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     MimSegmentationButton is used to build a button control representing a plugin,
    %     with a backgroud image preview of the segmentation
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        RootButtonWidth = 20;
        RootButtonHeight = 20;
    end
    
    properties (Access = protected)
        LoadManualSegmentationCallback
    end
    
    methods
        function obj = MimSegmentationButton(parent, name, load_manual_segmentation_callback)
            tooltip_string = ['<HTML>' name];
            
            button_text = ['<HTML><P ALIGN = RIGHT>', name];
            tag = name;
            obj = obj@GemButton(parent, button_text, tooltip_string, tag, []);
            obj.LoadManualSegmentationCallback = load_manual_segmentation_callback;
            obj.Callback = @obj.ButtonPressed;
            
            % Calculate the button size, based on plugin properties
            obj.ButtonWidth = 6*obj.RootButtonWidth;
            obj.ButtonHeight = 2*obj.RootButtonHeight;
        end
        
        function AddPreviewImage(obj, preview_fetcher, window, level)
            if ~isempty(preview_fetcher)
                preview_image = preview_fetcher.GetPluginPreview(obj.Tag);
            else
                preview_image = [];
            end
            if isempty(obj.Position)
                button_size = [obj.ButtonWidth, obj.ButtonHeight];
            else
                button_size = obj.Position(3:4);
            end
            preview_image_raw = MimImageUtilities.GetButtonImage(preview_image, button_size(1), button_size(2), window, level, 1, obj.BackgroundColour, obj.UnSelectedColour);
            obj.ChangeImage(preview_image_raw);
        end
        
        function height = GetRequestedHeight(obj, width)
            % Returns a value for the height of the object
            
            height = obj.ButtonHeight;
        end
        
        function ButtonPressed(obj, name)
            obj.LoadManualSegmentationCallback(name);
        end
        
    end
end