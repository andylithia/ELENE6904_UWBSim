channel_tb;
%%
subplot(2,1,1);
hold off;
plot(sigout_rx);
hold on
plot(sigout_hilbert);

subplot(2,1,2);
hold off;
yyaxis left

% Low-pass using a filter with cutoff = 2GHz
% After this, pass it thru a differentiator
lpd = lowpass(diff(lowpass(sigout_hilbert,2e9,fs)),0.5e9,fs);
plot(lpd);
yyaxis right;
% Now the hyteresis comparator gived a more accurate timing result
plot(hysteresis(lpd,2e-3,0));
ylim([-0.5,1.5]);