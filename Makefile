.PHONY: clean

all: ValaMediaPlayer

ValaMediaPlayer: ValaMediaPlayer.vala
	valac --pkg gstreamer-interfaces-0.10 --pkg gtk+-2.0 --pkg gdk-x11-2.0 ValaMediaPlayer.vala

clean:
	rm ValaMediaPlayer
