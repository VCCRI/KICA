% CLASS DESCRIPTION 
% The class contains methods for signal filtering
% NOTES:
%
% RELEASE VERSION: 0.6
%
% AUTHOR: Anton Shpak (a.shpak@victorchang.edu.au)
%
% DATE: February 2020
classdef Filter
    
    methods (Static)
        
        function outSignal = LP_HammingWindow(fs, fLP, inSignal, showPlot)
            b = blackman(round((1/fLP)/(1/fs)));
            b = b./sum(abs(b));
            outSignal = filtfilt(b, 1, inSignal);

            if showPlot
                figure();
                plot(outSignal);
                title(strcat("Low-pass Hamming Window filtered at ", num2str(fLP), " Hz"));
            end
        end
        
        function outSignal = LP_BlackmanWindow(fs, fLP, inSignal, showPlot)
            b = blackman(round((1/fLP)/(1/fs)));
            b = b./sum(abs(b));
            outSignal = filtfilt(b, 1, inSignal);

            if showPlot
                figure();
                plot(outSignal);
                title(strcat("Low-pass Blackman Window filtered at ", num2str(fLP), " Hz"));
            end
        end
        
        function outSignal = LP_FIR(fs, fLP, inSignal, showPlot)

            order = 100;
            a0 = [1 1 0 0];
            f0 = [0 fLP fLP*1.25 fs/2]./(fs/2);
            b = firpm(order, f0, a0);
            a = 1;

            outSignal = filtfilt(b, a, inSignal); % needed to create 0 phase offset

            if showPlot
                figure();
                plot(outSignal);
                title(strcat("Low-pass FIR filtered at ", num2str(fLP), " Hz"));
            end        
        end
        
        
        function outSignal = LP_IIR(fs, fLP, inSignal, showPlot)

            n = 5;
            Rp = 0.5;
            Rs = 80;
            %fLP = 15; % low-pass frequency
            Wp = fLP/(fs/2); % Hz
            [b, a] = ellip(n, Rp, Rs, Wp, 'low');

            outSignal = filtfilt(b, a, inSignal);

            if showPlot
                figure(3);
                plot(outSignal);
                title(strcat("Low-pass IIR filtered at ", num2str(fLP), " Hz"));
            end   
        end
        
        function outSignal = HP_IIR(fs, fHP, inSignal, showPlot)

            n = 5;
            Rp = 0.5;
            Rs = 80;
            Wp = fHP/(fs/2); % Hz
            [b, a] = ellip(n, Rp, Rs, Wp, 'high');

            outSignal = filtfilt(b, a, inSignal);

            if showPlot
                figure();
                plot(outSignal);
                title(strcat("High-pass filtered at ", num2str(fHP), " Hz"));
            end        
        end
        
        function outSignal = Bandpass_IIR(fs, fLP, fHP, inSignal, showPlot)    

            Wn(1) = fLP/(fs/2); % cutt off based on fs
            Wn(2) = fHP/(fs/2);

            n = 5; % order 

        %     [b,a] = butter(n, Wn, 'bandpass'); %bandpass filter
        %     outSignal = filtfilt(b, a, inSignal);

            n = 3;
            Rs = 40;
            Ws = [fLP fHP]/(fs/2);
            ftype = 'bandpass';
            [b, a] = cheby2(n, Rs, Ws, ftype);
            outSignal = filtfilt(b, a, inSignal);

            fvtool(b,a);

            if showPlot
                figure();
                plot(outSignal);
                title(strcat("Band-pass filtered at LP ", num2str(fLP), " and HP ",  num2str(fHP), " Hz"));
            end
        end        
        
        
    end
end

