classdef (Sealed) PTKUtils < handle
    % PTKUtils. A script to update the PTK codebase via git
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    methods (Static)
        function Clear()
            close all;
            clear all classes;
            path(pathdef);
        end
        
        function RunScript(script_name, varargin)
            m = PTKMain();
            m.RunScript(script_name, varargin{:});
        end
        
        function Recompile()
            m = PTKMain();
            m.Recompile();
        end
        
        function RebuildDatabase()
            m = PTKMain();
            m.RebuildDatabase();
        end
        
        function DeleteCacheForAllDatasets()
            m = PTKMain();
            m.DeleteCacheForAllDatasets();
        end
    end
    
    methods (Access = private)
        function obj = PTKUtils()
            disp('PTKUtils contains method to help maintain your PTK');
            disp('PTKUtils.RebuildDatabase() will reimport your imaging files and correct problems with the database');
            disp('PTKUtils.Recompile() will recompile your mex files');
            disp('PTKUtils.Clear() will clear all the memory caches');
        end
    end
    
end