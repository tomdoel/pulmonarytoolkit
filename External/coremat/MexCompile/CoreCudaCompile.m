classdef CoreCudaCompile < handle
    % CoreCudaCompile. Class for compiling mex files
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
            compile_arguments = ['"' compiler '" -ptx --output-directory ' output_directory ' ' src_fullfile, ' ' mex_file.OtherCompilerFiles];
            mex_result = system(compile_arguments);
        end
    end
end

