EXEC=valamediaplayer
PACKAGES=--pkg gtk+-3.0 --pkg gstreamer-interfaces-0.10 --pkg gdk-x11-3.0 --pkg glib-2.0 --pkg gstreamer-pbutils-0.10
SOURCES=mediaplayer-main.vala mediaplayer-streamplayer.vala mediaplayer-controls.vala
FLAGS=-DDEBUG

all:
	valac $(PACKAGES) -X $(FLAGS) $(SOURCES) -o $(EXEC)

