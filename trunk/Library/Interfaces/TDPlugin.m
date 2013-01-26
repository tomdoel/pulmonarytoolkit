classdef TDPlugin < handle
    % TDPlugin. Base class for a Plugin used by the Pulmonary Toolkit.
    %
    %     Plugins are classes you create to run your own routines from the
    %     Pulmonary Toolkit. When you create a plugin, it will automatically
    %     appear as a button in the gui, and is available to scripts and other
    %     plugins which use the Pulmonay Toolkit. The framework automatically
    %     handles result caching, dependency tracking and preview thumbnail
    %     generation.
    %
    %     To run a plugin from the gui, first start up the gui using the script
    %     ptk.m. Load in the dataset you wish to run the plugin with, and then
    %     click on the plugin button which is automatically created in the
    %     plugins panel on the right.
    %
    %     To run a plugin from your own code, first create a TDPTK object. Then
    %     call CreateDatasetFromInfo() to create a TDDataset for the image files
    %     you wish to run the plugin with. Then call GetResult() on this dataset
    %     interface to run the plugin or fetch a previously cached result.
    %
    %     Example
    %     -------
    %     Replace <image path> and <filenames> with the path and filenames
    %     to your image data, and MyPluginName with the name of the plugin to
    %     run.
    %
    %         image_info = TDImageInfo( <image path>, <filenames>, [], [], [], []);
    %         ptk = TDPTK;
    %         dataset = ptk.CreateDatasetFromInfo(image_info);
    %         airways = dataset.GetResult('MyPluginName');
    %    
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    % You must set each of these properties in your plugin class
    properties (Abstract = true)
        
        % Set this to the value in TDSoftwareInfo.
        % This specifies the version of the Pulmonary Toolkit the plugin was
        % developed with.
        PTKVersion
        
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
        
        % Set to the panel name in the gui you wish the plugin to appear under
        % Examples include "Airways', 'Lungs', 'Analysis' or you can create your
        % own
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
    
    methods (Abstract, Static)
        
        % Generates the results for this plugin. The results can be a TDImage or
        % any kind of Matlab structure. Plugins should generally return an
        % output image as their result, but some plugins (such as TDAirways)
        % generate information which cannot be stored in a simple image. For
        % these types of plugin, you should return a custom data structure
        % containing your results, and then override the function 
        % GenerateImageFromResults below to produce an illustrative output
        % image.        
        results = RunPlugin(application, reporting)
        
    end
    
    methods (Static)

        % Generates a results image from the results returned by RunPlugin. If
        % the result is itself an image, there is no need to override this
        % function as this image will be returned. If the result is a data
        % structure, this function should generate an illustrative output image
        % based on the results. For example, the TDAirways plugin returns a
        % heirarchical data structure describing the airway tree. This functin
        % is then used to turn the structure into an image.
        function results = GenerateImageFromResults(results, ~, ~)
        end
    end
end