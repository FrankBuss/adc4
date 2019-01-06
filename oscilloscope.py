#!/usr/bin/python3

# install this, if it can't find matplotlib:
# sudo pip3 install matplotlib

import adc4
import numpy
from matplotlib import pyplot
from matplotlib import animation

display_size = 256

def write_uint32(w):
    ser.write((w >> 24) & 0xff)
    ser.write((w >> 16) & 0xff)
    ser.write((w >> 8) & 0xff)
    ser.write(w & 0xff)

def plot_animation(display_size):
    drawer = DrawFunctions(display_size)
    drawer.start_animation()

class DrawFunctions:
    def __init__(self, display_size):
        self.display_size = display_size

        self.fig = pyplot.figure(figsize=(12, 8))
        self.fig.canvas.set_window_title('ADC4')
        self.fig.canvas.toolbar.pack_forget()
        ax = pyplot.axes(xlim=(0, 10), ylim=(-10.5, 10.5))
        ax.set_facecolor((0.1, 0.1, 0.1))
        pyplot.xlabel('μs')
        pyplot.ylabel('Volt')
        pyplot.grid(True, color=(0.3, 0.3, 0.3))
        line1, = ax.plot([], [], lw=2, color='yellow')
        line2, = ax.plot([], [], lw=2, color='green')
        line3, = ax.plot([], [], lw=2, color='cyan')
        line4, = ax.plot([], [], lw=2, color='red')
        self.lines = [ line1, line2, line3, line4 ]

    def start_animation(self):
        ani = animation.FuncAnimation(self.fig,
                                      self.update,
                                      interval=33,
                                      blit=True)
        pyplot.subplots_adjust(top=0.98, right=0.99, left=0.07, bottom=0.06)
        pyplot.xticks(numpy.arange(0, 11, 1.0))
        pyplot.yticks(numpy.arange(-10, 11, 1.0))
        pyplot.show()
        
    def update(self, i):
        data = adc4.record_and_read(sample_count = self.display_size * 2)
        volts = adc4.samples_to_voltages(data)

        # try to find zero crossing
        pos = 0
        old = volts[pos][0]
        for i in range(self.display_size):
            v = volts[pos + 1][0]
            if old < 0 and v >= 0:
                break
            old = v
            pos = pos + 1
        
        # update diagram
        for c in range(4):
            line = self.lines[c]
            frames = []
            for i in range(self.display_size):
                volt = volts[pos + i][c]
                frames.append(volt);
            x = numpy.arange(self.display_size)/25
            line.set_data(x, frames)
        
        center = 0
        return tuple(self.lines,)

plot_animation(display_size) 
