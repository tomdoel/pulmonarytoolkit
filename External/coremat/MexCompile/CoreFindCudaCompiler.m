function cuda_compiler = CoreFindCudaCompiler
    % CoreFindCudaCompiler Attempts to locate the cuda compiler
    %
    %
    %
    %     Licence
    %     -------
    %     Part of CoreMat. https://github.com/tomdoel/coremat
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    if ispc
        [status, cuda_compiler] = system('where nvcc');

        if status ~= 0
            cuda_compiler = TryToFindCudaCompilerPc(fullfile(getenv('ProgramFiles'), 'NVIDIA GPU Computing Toolkit', 'CUDA'));
            if isempty(cuda_compiler)
                cuda_compiler = TryToFindCudaCompilerPc(fullfile(getenv('ProgramW6432'), 'NVIDIA GPU Computing Toolkit', 'CUDA'));
            end
            if isempty(cuda_compiler)
                cuda_compiler = TryToFindCudaCompilerPc(fullfile(getenv('ProgramFiles(x86)'), 'NVIDIA GPU Computing Toolkit', 'CUDA'));
            end
            if isempty(cuda_compiler)
                disp('Cannot find nvcc');
            end
        end
    else
        [status, cuda_compiler] = system('which nvcc');

        if status ~= 0
            if 2 == exist('/usr/local/cuda/bin/nvcc', 'file')
                cuda_compiler = '/usr/local/cuda/bin/nvcc';
            else
                disp('Cannot find nvcc');
                cuda_compiler = [];
            end
        end
    end
end

function compiler = TryToFindCudaCompilerPc(base_dir)
    compiler = [];
    directories = CoreDiskUtilities.GetListOfDirectories(base_dir);
    
    for dir_name = directories
        bin_dir = fullfile(base_dir, dir_name{1}, 'bin');
        if isdir(bin_dir)
            compiler = bin_dir;
            return;
        end
    end
end