clear all;
close all;

global DEBUG_PRINT_ENABLE;
DEBUG_PRINT_ENABLE = 0;
%%
setup = struct;
setup.fs = 100e9;
setup.regSNR   = 10;            % dB10
setup.fadeType = 'flat';
setup.rayleighVelocity= 0;
setup.flatAttenuation = 0;
setup.multiPathSetup = [[0.1,1e-9];[0.2,2e-9];[0.3,3e-9]];
%% symbol gen
tic
fprintf("Symbol Gen ");
data_test = [0 3 7 11 15 19 23 27 31];

n = 10; %10th order derivative
fs = 100e9; %sampling frequency
fc = 5e9; % center frequency
frame = 10e-9;% 10ns frame
an = 2e-114;% scaling factor
% frame_num = length(data_test);% frames of data
frame_num = 1000;
RBW = 1e-6/(frame*frame_num); %resolution bw in MHz
pulse_duration = 1.5e-9;% duration for each pulse
sigma_sync = 0.1;% sync pulse position uncertainty being 1*(1/fs)
sigma_data = 0.1;% data pulse position uncertainty being 1*(1/fs)
sigma_power = 0.01;% pulse data uncertainty being 1% nominal value
%sigma_sync = 1;% sync pulse position uncertainty being 1*(1/fs)
%sigma_data = 1;% data pulse position uncertainty being 1*(1/fs)
%sigma_power = 0.01;% pulse data uncertainty being 1% nominal value
tguard = 3.5e-9;% multipath guard time
tstep = 0.1e-9;% data step
r = 1; %transmitter and receiver are 1m away
random_data = [];
pulse = [];
% Generate a separate stream for locking dection
% Region Type
% 0~31: data code
% 32:   Sync
% 33:   tgl, Left Guard
% 34:   tgr, Right Guard
% todo: encode noidealities into this system
% The pattern is encoded in this way to better utilize the instruction cache
npulse     = round(frame*fs);
nstep_sync = pulse_duration/2*fs;
nstep_tgl  = (tguard)*fs;
nstep_data = (tstep*31*fs);
nstep_tgr  = (frame*fs)-nstep_sync-nstep_tgl-nstep_data;
%pattern    = zeros(2, 4*frame_num);
%pulse      = zeros(1, frame_num*(frame*fs));    % The speedup of this modification is not significant...
dtx        = zeros(1, frame_num);
progress   = 0;
pulse = [];
pattern = [];

impairment = struct;
parfor i = 1:frame_num
    %progress = progress+1;
    %if(progress==50)
    %    fprintf("%d ", i);
    %    progress = 0;
    %end
    data = randi(32)-1;
    % data = data_test(i);
    dtx(i) = data;
    %if(DEBUG_PRINT_ENABLE)
    %    fprintf("DB@%d:\t%X\n",i,data);    
    %end
    data_bits = de2bi(data,5,'left-msb');                            % Convert to binary
    impairment = struct;
    impairment.datapulse =     round(normrnd(0,sigma_data))*(1/fs);  % datapulse timing uncertainty
    impairment.syncpulse = abs(round(normrnd(0,sigma_sync))*(1/fs)); % syncpulse timing uncertainty
    impairment.power     = abs(normrnd(1,sigma_power)); % pulse power uncertainty
    %pulse((i-1)*npulse+1:i*npulse) = (DMPPM_symbol_gen(data_bits,tguard,tstep,frame,n,fs,fc,pulse_duration,an,impairment)); 
    pulse = [pulse (DMPPM_symbol_gen(data_bits,tguard,tstep,frame,n,fs,fc,pulse_duration,an,impairment))];
    patternlet = [[32 nstep_sync]' [33 nstep_tgl]' [data nstep_data]' [34 nstep_tgr]'];
    %pattern(:,(i-1)*4+1:(i)*4) = patternlet;
    pattern = [pattern patternlet];
end
toc
tic
%figure
pulse = FSPL(pulse,r,fs);
toc
%plot(pulse);

% sig = [];
% padding = round((10e-9 - pframe)*fs);
% for i = 1:frame_num
%     sig = [sig pulse zeros(1,padding)];
% end
% plot(sig);
%% Run it thru a channel
tic
fprintf("Channel Model... ");
figure(2);
%subplot(2,1,1);
sigout_rx = channel(pulse,setup);
%hold off;
plot(sigout_rx);
% Envelope Detection
figure(3);
yyaxis left;
sigout_hilbert = abs(hilbert(sigout_rx));
plot(sigout_hilbert);
yyaxis right;
%plot(sigout_rx_q);

%yyaxis right;
%plot(pattern);
%ylim([-1,4]);

% When testing, we can first force the TDC to start at a point where it's
% desynced. Transmit a load of random data encoded using DMPPM, and see how
% long it takes to recover to the synced state.
toc
%% TDC Test
tic
fprintf("RX...            ");
sigout_rx_q = hysteresis(lowpass(sigout_hilbert, 0.1), 2.0e-4, 1e-4);
dso = TDC_advanced(sigout_rx_q, pattern, fs, tstep, tguard/1.1, tguard/1.1, frame);
toc
drx       = (dso(1,:) - 35);
drx_valid = (dso(2,:) == 1);
dtrx_difference = find(drx~=dtx);
ber = (length(dtrx_difference)/frame_num);
fprintf("TRX cycle finished. Words sent: %d, BER: %e\n", frame_num, ber);


