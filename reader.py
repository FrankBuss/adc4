#!/usr/bin/python3

import adc4

test = False

adc4.samplerate_divider = 4
print("samplerate: %i MHz" % (25 / (adc4.samplerate_divider + 1)))

# measure and read data
data = adc4.record_and_read(sample_count = 5*1000*1000, testing = test)

# print data
max_lines = 50
words_per_line = 16
step = 4
line_length = words_per_line * step
length = min(max_lines * line_length, len(data))
print("sample count: %i" % length)
print(len(data))
for line in range(0, length, line_length):
    items = []
    for i in range(line, min(line + line_length, length), step):
        d = data[i] + (data[i + 1] << 8) + (data[i + 2] << 16) + (data[i + 3] << 24)
        items.append("%08x" % d)
    print(" ".join(items))

# test for gaps
if test:
    length = len(data)
    print("length: %i" % length)
    last = 0
    for i in range(0, length - step, step):
        d = data[i] + (data[i + 1] << 8) + (data[i + 2] << 16) + (data[i + 3] << 24)
        dx = d - last
        if dx > 1:
            print("position: %i, delta: %i" % (i // step, dx))
        last = d

# convert to volts
volts = adc4.samples_to_voltages(data)

# ignore first 512 bytes
volts = volts[512:]

# save samples
adc4.save_as_sigrok("data.sr", volts)
adc4.save_as_csv("data.csv", volts)
