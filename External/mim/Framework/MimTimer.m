classdef MimTimer < CoreBaseClass
    % Used to time plugin execution
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    

    properties (Access = private)
        StartTicId       % ID from the tic function called at Start()
        PauseTicId       % ID from the tic function called at Resume()
        Reporting        % error/progress reporting
    end
    
    properties (SetAccess = private)
        SelfTime         % After Stop() is called, contains elapsed time in seconds, excluding when the timer was paused
        TotalElapsedTime % After Stop() is called, contains elapsed time in seconds, ignoring any Pause() calls
    end
    
    methods
        function obj = MimTimer(reporting)
            obj.Reporting = reporting;
        end
        
        function Start(obj)
            if ~isempty(obj.StartTicId)
                reporting.Error('MimTimer:TimerAlreadyStarted', 'The Start() method was called but the clock has already been started.');
            end
            obj.StartTicId = tic;
            obj.PauseTicId = obj.StartTicId;
        end

        function Stop(obj)
            if isempty(obj.StartTicId)
                reporting.Error('MimTimer:TimerNotStarted', 'The Stop() method was called but the clock has not been started.');
            end
            if ~isempty(obj.TotalElapsedTime)
                reporting.Error('MimTimer:ClockAlreadyStopped', 'The Stop() method was called but the clock has already been stopped.');
            end
            obj.TotalElapsedTime = toc(obj.StartTicId);
            elapsed_time_since_resume = toc(obj.PauseTicId);
            if isempty(obj.SelfTime)
                obj.SelfTime = elapsed_time_since_resume;
            else
                obj.SelfTime = obj.SelfTime + elapsed_time_since_resume;
            end
        end
        
        function Pause(obj)
            if isempty(obj.StartTicId)
                reporting.Error('MimTimer:TimerNotStarted', 'The Pause() method was called but the clock has not been started.');
            end
            if isempty(obj.PauseTicId)
                reporting.Error('MimTimer:TimerNotStarted', 'The Pause() method was called but the clock is already paused.');
            end
            if ~isempty(obj.TotalElapsedTime)
                reporting.Error('MimTimer:ClockAlreadyStopped', 'The Pause() method was called but the clock has already been stopped.');
            end
            elapsed_time_since_resume = toc(obj.PauseTicId);
            if isempty(obj.SelfTime)
                obj.SelfTime = elapsed_time_since_resume;
            else
                obj.SelfTime = obj.SelfTime + elapsed_time_since_resume;
            end
            obj.PauseTicId = [];
        end
        
        function Resume(obj)
            if isempty(obj.StartTicId)
                obj.Reporting.Error('MimTimer:TimerNotStarted', 'The Resume() method was called but the clock has not been started.');
            end
            if ~isempty(obj.TotalElapsedTime)
                obj.Reporting.Error('MimTimer:ClockAlreadyStopped', 'The Resume() method was called but the clock has already been stopped.');
            end
            if ~isempty(obj.PauseTicId)
                obj.Reporting.Error('MimTimer:NotPaused', 'The Resume() method was called but the clock has not been paused.');
            end
            obj.PauseTicId = tic;
        end
    end
end
