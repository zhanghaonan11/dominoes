import wave
import struct
import math
import os

def make_wav(name, freq_start, freq_end, duration, vol=0.5):
    f = wave.open(name, 'w')
    f.setnchannels(1)
    f.setsampwidth(2)
    f.setframerate(44100)
    num_samples = int(44100 * duration)
    for i in range(num_samples):
        t = float(i) / 44100
        freq = freq_start + (freq_end - freq_start) * (i / num_samples)
        value = int(vol * 32767.0 * math.sin(2.0 * math.pi * freq * t))
        data = struct.pack('<h', value)
        f.writeframesraw(data)
    f.close()

os.makedirs('dominoes/Sounds', exist_ok=True)
make_wav('dominoes/Sounds/roll.wav', 200, 300, 0.4, 0.3)
make_wav('dominoes/Sounds/hit.wav', 800, 400, 0.08, 0.4)
make_wav('dominoes/Sounds/explode.wav', 120, 40, 0.6, 0.8)
make_wav('dominoes/Sounds/click.wav', 800, 1000, 0.05, 0.3)
