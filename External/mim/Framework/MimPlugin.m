classdef MimPlugin < handle
    % MimPlugin. Base class for a Plugin used by MIM.
    %
    %     Plugins are classes you create to run your own routines from the
    %     MIM toolkit. When you create a plugin, it can automatically
    %     appear as a button in compatible guis, and is available to scripts and other
    %     plugins which use the MIM toolkit. The framework automatically
    %     handles result caching, dependency tracking and preview thumbnail
    %     generation.
    %
    %     To run a plugin from your own code, first create a suitable
    %     MimMain object, usually by using a specific application such as
    %     PTKMain for PTK. Then call CreateDatasetFromInfo() to create a MimDataset for the image files
    %     you wish to run the plugin with. Then call GetResult() on this dataset
    %     interface to run the plugin or fetch a previously cached result.
    %
    %     Example
    %     -------
    %     Replace <image path> and <filenames> with the path and filenames
    %     to your image data, and MyPluginName with the name of the plugin to
    %     run.
    %
    %         image_info = MimImageInfo( <image path>, <filenames>, [], [], [], []);
    %         ptk = PTKMain;
    %         dataset = ptk.CreateDatasetFromInfo(image_info);
    %         airways = dataset.GetResult('MyPluginName');
    %    
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    % You must set each of these properties in your plugin class
    properties (Abstract = true)
        % Should normally be set to true.
        % Specifies if the results of this plugin can be cached on disk. If you
        % set this to false, the results will never be cached and the plugin
        % will have to be run each time its result is requested. This will save
        % disk space but could substantially increase execution time.
        AllowResultsToBeCached
        
        % Should normally be set to false.
        % Set to true if you want to force the plugin to be run every time its
        % result is requested, ignoring any results in the disk cache. One
        % reason to set this to true is during plugin development, where you are
        % modifying the code and want to test your changes.
        AlwaysRunPlugin
        
        % Should normally be set to 'ReplaceOverlay'.
        % This specifies how the plugin result will be displayed to the user
        % when using the gui. Allowable values are:
        % 'ReplaceOverlay' - the result is displayed as an image overlay
        % 'ReplaceImage'   - the result replaces the image. Normally you would
        %                    only do this when creating a new image context 
        %                    (i.e. region of interest)
        % 'DoNothing'      - do not display any results. This option is
        %                    appropriate if your plugin displays its results in
        %                    its own window
        PluginType
        
        % Set to force the plugin to appear in a particular panel name in the gui.
        % If you leave blank, the panel name will be the subdirectory under
        % Plugins where the plugin is found
        Category
        
        % Should normally be set to false.
        % If true, this plugin will not have a button in the gui window
        HidePluginInDisplay
        
        % Should normally be set to 6.
        % The width (in units defined by the gui) of the button for this plugin
        ButtonWidth

        % Should normally be set to 2.
        % The height (in units defined by the gui) of the button for this plugin
        ButtonHeight
        
        % The text to appear in the gui when the user hovers the mouse over the
        % button for this plugin
        ToolTip

        % The text to appear on the button in the gui. Also used in reporting of
        % progress, so the text should make sense when displayed as "Calculating
        % <button text>", e.g. 'Airways by Lobe' will display as "Calculating
        % Airways by Lobe" in the progress dialog. Note that HTML tags are
        % allowed - use <BR> for a newline in the button text
        ButtonText
        
        % Should normaly be set to true.
        % Specifies in a preview thumnail should be generated from the plugin
        % result after the plugin has been run. This thumbnail will be displaued
        % in the button itself. Set this to false if the plugin does not
        % generate an image.
        GeneratePreview
        
        % Should normally be set to false.
        % Specifies whether a MIP will be used to generate the preview
        % thumbnail. Set to true for small structures such as airways which are
        % best visualised with the "flatten" plugin.
        FlattenPreviewImage
    end
    
    % Optional properties
    %   PluginInterfaceVersion - specifies the version of the plugin interface
    %   that your plugin implements
        

    methods (Abstract, Static)
        
        % Generates the results for this plugin.
        % The results can be a PTKImage or
        % any kind of Matlab structure. Plugins should generally return an
        % output image as their result, but some plugins (such as PTKAirways)
        % generate information which cannot be stored in a simple image. For
        % these types of plugin, you should return a custom data structure
        % containing your results, and then override the function 
        % GenerateImageFromResults below to produce an illustrative output
        % image.        
        results = RunPlugin(dataset, context, reporting)
        
    end
    
    methods (Static)

        function results = GenerateImageFromResults(results, ~, ~)
            % Generates a results image from the results returned by RunPlugin.
            % If the result is itself an image, there is no need to override this
            % function as this image will be returned. If the result is a data
            % structure, this function should generate an illustrative output image
            % based on the results. For example, the PTKAirways plugin returns a
            % heirarchical data structure describing the airway tree. This functin
            % is then used to turn the structure into an image.
        end
        
        
        function result = GetEditedResult(result, edited_result, ~)
            % Modifies a plugin result based on manual editing of the output image. 
            % The default behaviour is that the edited result replaces the
            % result, provided they are both of the same type.
            % However, plugins may choose to modify the original result based on
            % an edited result, in which case the plugin must override this
            % method and define its desired behaviour.
            if strcmp(class(result), class(edited_result))
                result = edited_result;
            end
        end
    end
end