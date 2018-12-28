#!/usr/bin/python3

# install this, if it can't find matplotlib:
# sudo pip3 install matplotlib

import serial
import numpy
from matplotlib import pyplot
from matplotlib import animation

display_size = 256

ser = serial.Serial('/dev/ttyUSB0', 1000000, timeout=0.5)

def plot_animation(display_size):
    drawer = DrawFunctions(display_size)
    drawer.start_animation()

class DrawFunctions:
    def __init__(self, display_size):
        self.display_size = display_size

        self.fig = pyplot.figure(figsize=(12, 8))
        self.fig.canvas.set_window_title('ADC4')
        self.fig.canvas.toolbar.pack_forget()
        ax = pyplot.axes(xlim=(0, display_size/25), ylim=(-10, 10))
        pyplot.xlabel('μs')
        pyplot.ylabel('Volt')
        pyplot.grid(True)
        self.line, = ax.plot([], [], lw=2)

    def init(self):
        self.line.set_data([], [])
        return self.line,

    def start_animation(self):
        ani = animation.FuncAnimation(self.fig,
                                      self.update,
                                      init_func=self.init,
                                      interval=33,
                                      blit=True)
        pyplot.subplots_adjust(top=0.98, right=0.99, left=0.07, bottom=0.06)
        pyplot.xticks(numpy.arange(0, 11, 1.0))
        pyplot.show()

    def update(self,i):
        # start measurement
        if True:
            ser.write('s'.encode())
        
            # wait until done
            x = ser.read()
            if len(x) == 0:
                raise Exception('timeout')
        
        # read back the data
        ser.write('r'.encode())
        data = b""
        while True:
            d = ser.read(100000)
            if len(d) == 0: break
            data = data + d
        frames = []
        min = 255
        max = 0
        for i in range(self.display_size):
            d = data[i*16+16]
            if d < min: min = d
            if d > max: max = d
            frames.append((float(d) / 256 - 0.5) * 20);
        x = numpy.arange(self.display_size)/25
        print("min: %d, max: %d" % (min, max))
        
        center = 0
        self.line.set_data(x, frames)
        return self.line,

plot_animation(display_size) 
