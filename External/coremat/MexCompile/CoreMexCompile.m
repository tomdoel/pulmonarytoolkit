classdef CoreMexCompile < handle
    % CoreMexCompile. Class for compiling mex files
    %
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    methods (Static)
        function mex_result = Compile(compiler, mex_file, src_fullfile, output_directory)
            mex_arguments = [{'-outdir', output_directory}, mex_file.CompilerOptions, src_fullfile, mex_file.OtherCompilerFiles];
            mex_result = mex(mex_arguments{:});
        end
    end
end

