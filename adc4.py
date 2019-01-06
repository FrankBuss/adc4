#!/usr/bin/python3

import serial
import time
import zipfile
import io
import struct
import crc8

def write_uint32(w):
    ser.write([(w >> 24) & 0xff, (w >> 16) & 0xff, (w >> 8) & 0xff, w & 0xff])

ser = serial.Serial('/dev/ttyUSB0', 1000000, timeout=5)

samplerate_divider = 0
ignore = 512

def read_block(start_address, sample_count):
    sample_count = sample_count + ignore
    ser.timeout = 0.1
    checksum_error = ""
    for t in range(3):
        ser.write('r'.encode())
        start_address = start_address
        write_uint32(start_address)
        write_uint32(sample_count)
        data = b""
        while True:
            d = ser.read(100000)
            if len(d) == 0: break
            data = data + d
        if len(data) == 0:
            raise Exception('no data')

        # test checksum
        crc8.init()
        for i in range(len(data) - 1):
            crc8.update(data[i])
        checksum = data[len(data) - 1]
        if crc8.checksum != checksum:
            print('CRC8 error, expected CRC8: %02x, actual CRC8: %02x' % (crc8.checksum, checksum))
        else:
            return data[ignore * 4:len(data) - 1]
    raise Exception('3 times checksum error')

# record data and read
def record_and_read(sample_count, testing = False):
    ser.timeout = sample_count * 4 * 8 / ser.baudrate * 2
    
    # cancel any previous transfer and sync communication
    ser.write('............'.encode())
    
    # set samplerate divider
    ser.write('d'.encode())
    ser.write([samplerate_divider])

    # start recording, use 't' for internal DDR RAM test
    print("start recording...")
    if testing:
        ser.write('t'.encode())
    else:
        ser.write('s'.encode())
    write_uint32(sample_count + ignore)

    # wait until done
    x = ser.read()
    if len(x) == 0:
        raise Exception('timeout')
    print("recording done")
       
    # read the data in blocks of 10240 bytes
    data = b""
    start_address = 0
    block_size = 10240
    i = 0
    while len(data) < sample_count * 4:
        data = data + read_block(start_address, block_size)
        start_address = start_address + block_size
        if len(data) // 1000000 > i:
            i = i + 1
            print("%d million bytes read" % i)

    return data[:sample_count * 4]

def to_float_bytes(data):
    return struct.pack('%sf' % len(data), *data)

def sample_to_voltage(sample):
    return -(sample * 8 - 1024) / 100.0

def samples_to_voltages(data):
    result = []
    for i in range(0, len(data), 4):
        d = []
        for c in range(4):
            d.append(sample_to_voltage(data[i + c]))
        result.append(d)
    return result

# save data as sigrok file
def save_as_sigrok(filename, volts):
    mf = io.BytesIO()

    with zipfile.ZipFile(mf, mode='w', compression=zipfile.ZIP_DEFLATED) as zf:
        meta = '[global]\n'
        meta = meta + 'sigrok version=0.5.1\n'
        meta = meta + '\n'
        meta = meta + '[device 1]\n'
        meta = meta + "samplerate=%f MHz\n" % (25 / (samplerate_divider + 1))
        meta = meta + 'total analog=4\n'
        for i in range(4):
            c = i + 1
            meta = meta + ("analog%d=CH%d\n" % (c, c))
            data = []
            for vs in volts:
                data.append(vs[i])
            zf.writestr("analog-1-%d-1" % c, to_float_bytes(data))
        zf.writestr('metadata', meta)
        zf.writestr('version', '2')
        
    with open(filename, "wb") as f: # use `wb` mode
        f.write(mf.getvalue())    

# save data as csv file
def save_as_csv(filename, volts):
    with open(filename, 'w') as f:
        f.write('"CH1","CH2","CH3","CH4"')
        f.write("\n")
        for vs in volts:
            f.write(",".join(map(str, vs)))
            f.write("\n")
