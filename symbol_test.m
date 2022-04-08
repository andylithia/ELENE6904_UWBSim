%% symbol gen
n = 10; %10th order derivative
fs = 100e9; %sampling frequency
fc = 5e9; % center frequency
frame = 10e-9;% 10ns frame
an = 1e-114;% scaling factor
frame_num = 100;% 100 frames of data
RBW = 1e-6/(frame*frame_num); %resolution bw in MHz
pulse_duration = 1.5e-9;
pulse = [];
random_data = [];
tguard = 3.5e-9;
tstep = 100e-12;
for i = 1:frame_num
    data = randi(32)-1;
    data_bits = de2bi(data,5,'left-msb');
    pulse = [pulse DMPPM_symbol_gen(data_bits,tguard,tstep,frame,n,fs,fc,pulse_duration,an)];
    random_data = [random_data data];
end
time = 0:1/fs:frame_num*frame-1/fs;
%% pulse plot
figure
plot(time,pulse);
title('Gaussian Pulse');
xlabel('Time(s)');
ylabel('Amplitude');
%% PSD plot
figure
L=length(pulse);
X = fftshift(fft(pulse));
Pxx=X.*conj(X)/(L*L); %computing power with proper scaling
Pxx = Pxx/50; % power is defined with a 50 ohm load
f = fs*(-L/2:1:L/2-1)/L; %Frequency Vector
f = f(L/2+1:end);
Pxx = 2*Pxx(L/2+1:end); % positive freqency
PSD = Pxx*1e6*1e3/(1/(frame*frame_num)); % PSD has the unit of dBm/MHz
plot(f*1e-9,10*log10(PSD),'.');
title('PSD of the Pulse');
xlabel(['Frequency (GHz), RBW=',num2str(RBW),'MHz'])
ylabel('Magnitude dBm/MHz');
xlim([0 10.6]);
ylim([-80 -30]);
%% FCC mask for Indoor communication plot
FCC_mask = [];
hold on
for i = 1:length(f)
    if(f(i)<=960e6)
        FCC_mask = [FCC_mask -41.3];
    else if(f(i)>960e6 && f(i)<=1610e6)
        FCC_mask = [FCC_mask -75.3];
    else if(f(i)>1610e6 && f(i)<=1990e6)
        FCC_mask = [FCC_mask -53.3];
    else if(f(i)>1990e6 && f(i)<=3100e6)
        FCC_mask = [FCC_mask -51.3];
    else if(f(i)>3100e6 && f(i)<=10600e6)
        FCC_mask = [FCC_mask -41.3];
    else if(f(i)>10600e6)
        FCC_mask = [FCC_mask -51.3];
        end
        end
        end
        end
        end
    end
end
plot(f*1e-9,FCC_mask);
legend('Pulse','FCC')
