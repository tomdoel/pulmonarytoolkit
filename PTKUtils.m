classdef (Sealed) PTKUtils < handle
    % PTKUtils. A script to update the PTK codebase via git
    %
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2015.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    methods (Static)
        function RunScript(script_name, varargin)
            % Runs a PTKScript from the Scripts folder
            
            m = PTKMain();
            m.RunScript(script_name, varargin{:});
        end
        
        
        function Recompile()
            % Forces recompilation of mex files

            m = PTKMain();
            m.Recompile();
        end
        
        function RebuildDatabase()
            % Forces a rebuild of the image database

            m = PTKMain();
            m.RebuildDatabase();
        end
        
        function ClearMemory()
            % Clears out memory caches

            close all;
            clear all classes;
            path(pathdef);
        end
                
        function ClearDisk()
            % Clears out disk and memory caches for temporary files

            m = PTKMain();
            m.DeleteCacheForAllDatasets();
        end
        
        function ReloadPlugins()
            % Forces reload of plugin information. Useful if you have modified properties of the plugin

            m = PTKMain();
            m.ReloadPlugins();
        end

        function Clear()
            PTKUtils.ClearMemory();
            PTKAddPaths();
        end

    end
    
    methods (Access = private)
        function obj = PTKUtils()
            disp('PTKUtils contains method to help maintain your PTK');
            disp('PTKUtils.RunScript(script_name, parameters) will run a PTKScript with the specified parameters');
            disp('PTKUtils.RebuildDatabase() will reimport your imaging files and correct problems with the database');
            disp('PTKUtils.ReloadPlugins() will reload plugins to fetch property changes');
            disp('PTKUtils.Recompile() will recompile your mex files');
            disp('PTKUtils.ClearMemory() will clear all the memory caches');
            disp('PTKUtils.ClearDisk() will clear the disk caches to retrieve disk space');
            ClearDisk
        end
    end
    
end