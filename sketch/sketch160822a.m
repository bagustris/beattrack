clear all, close all, clc

% Memuat file suara
nama_seri = 'open_001';
namafile = [nama_seri,'.wav'];
[x, fs] = audioread(namafile); 	% wavread untuk matlab versi 2015 dan lebih lama
if size(x,2) == 2 x = x(:,1); end	% mengambil hanya satu channel suara
if fs == 44100 x = downsample(x,3); fs = 44100/3; end % mengecilkan fs jika terlalu besar
x = x(1:10*fs); % mencuplik 10 detik saja (kepentingan penelitian aja)

% Normalisasi suara
maks = abs(max(x));
x = x/maks;

% Parameter Short Time Fourier Transform (STFT)
xlen = length(x); 	% panjang sinyal suara
nfft = 1024;
wlen = nfft; 		% lebar windowing
h = wlen/4; 		% hop size

% Melakukan STFT sepanjang sinyal suara
[s, f, t] = stft(x, wlen, h, nfft, fs);
s = abs(s/nfft); % magnitudo frekuensi
s = 20*log10(s/(10^-6)); % daya dalam dB dengan nilai minimum -120 dB
s_hwr = (s+abs(s))/2; % half wave rectified
s_os = mapstdev(sum(s_hwr)); % normalisasi data
s_os = map(s_os); % normalisasi data
s_d = gradient(s_os); % spectral fluks turunan pertama
% s_dd = gradient(s_d); % spectral fluks turunan kedua (nggak jadi dipake)

% Memuat beat acuan dataset
t_real_beat = csvread([nama_seri,'.txt']);

%% Pengambilan peak
%periode = 0.1;
%toleransi = 0.175;
%d_threshold = 0.01;
%t_track_beat = ones(size(t));
%t_track_beat(s_d < d_threshold) = 0;
%t_track_beat = find(t_track_beat);
%t_track_beat = t(t_track_beat)';

%% Pengambilan puncak-puncak lokal
% Untuk Spektrum Energi
rect_s_os = s_os;
rect_s_os(rect_s_os < 0) = 0;
[val_peak1,pos_peak1] = findpeaks(rect_s_os);
t_peak1 = t(pos_peak1);

% Untuk Turunannya
rect_s_d = s_d;
rect_s_d(rect_s_d < 0) = 0;
[val_peak2,pos_peak2] = findpeaks(rect_s_d);
t_peak2 = t(pos_peak2);

t_p0 = t_peak1(val_peak1 > 0.4);
t_p0 = t_p0(1:5);
t_p0 = mean(abs(diff(t_p0))); % Dugaan posisi beat awal
t_gen = t_p0; % generate beat
ii = t_p0;
count = 1;
npeak = 5;
while ii < (xlen/fs)
	if count == 1
		count = count + 1;
		ii = ii + t_p0;
		idx = findnn(ii,t_peak2,npeak);
		pex = val_peak2(idx);
		[~,temp] = max(pex);
		idx = idx(temp);
		t_gen = [t_gen; t_peak2(idx)];
	elseif count == 2
		ii = ii + abs(t_gen(count)-t_gen(count-1));
		count = count + 1;
		idx = findnn(ii,t_peak2,npeak);
		pex = val_peak2(idx);
		[~,temp] = max(pex);
		idx = idx(temp);
		t_gen = [t_gen; t_peak2(idx)];
	else
		ii = ii + abs((t_gen(count)-t_gen(count-1))+(t_gen(count-1)-t_gen(count-2)))/2;
		count = count + 1;
		idx = findnn(ii,t_peak2,npeak);
		pex = val_peak2(idx);
		[~,temp] = max(pex);
		idx = idx(temp);
		t_gen = [t_gen; t_peak2(idx)];
	end
end
t_gen = unique(t_gen);

figure(1)
subplot(4,1,1)
plot((1:length(x))/fs,x)
title(['Sinyal Suara ',nama_seri,'_.wav'])
ylim([-1,1]); ylabel('Amplitudo (a.u.)');
xlabel('Waktu (detik)');
pv = vline(t_real_beat(t_real_beat<10));
legend(pv,'Beat dataset')

subplot(4,1,2)
imagesc(t,f,s)
title('Spektrogram')
ylabel('Frekuensi (Hz)'); xlabel('Waktu (detik)');
%ylabel(colorbar,'Magnitudo (dB)');

subplot(4,1,3)
plot(t,s_os)
title('Energi Spektrum'); xlabel('Waktu (detik)');
ylabel('a.u.');
pv = vline(t_peak1,'red');
legend(pv,'Local Maxima')

subplot(4,1,4)
plot(t,s_d)
title('Turunan Pertama Energi Spektrum'); xlabel('Waktu (detik)');
ylabel('a.u.');
pv = vline(t_peak2,'red');
legend(pv,'Local Maxima')

figure(2)
subplot(2,1,1)
plot((1:length(x))/fs,x)
title(['Beat Dataset ',nama_seri,'.wav'])
ylim([-1,1]); ylabel('Amplitudo (a.u.)');
xlabel('Waktu (detik)');
t_real_cuplik = t_real_beat(t_real_beat<10);
pv = vline(t_real_cuplik);
legend(pv,'Beat dataset')

subplot(2,1,2)
plot((1:length(x))/fs,x)
title(['Hasil Tracking Beat ',nama_seri,'.wav'])
xlim([0, 10]);
ylim([-1,1]); ylabel('Amplitudo (a.u.)');
xlabel('Waktu (detik)');
%pv = vline(t_gen(t_gen<10),'red');
%legend(pv,'Beat terdeteksi')
pv = vline(t_peak2,'red');
legend(pv,'Local Maxima')
