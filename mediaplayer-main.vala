using Gtk;
using Gst;
using GLib;

// TEMP: This should be in the standard gdk-x11-3.0.vapi any day soon
// https://bugzilla.gnome.org/show_bug.cgi?id=639467
[CCode (cheader_filename = "gdk/gdkx.h")]
private static extern X.ID gdk_x11_window_get_xid (Gdk.Window window);


public class MediaPlayer
{
    static string[] filenames; 

	public Gtk.Builder builder;
	public Gtk.Window window;
	public Gtk.MenuBar menubar;

    private XOverlay player_sink;
    private StreamPlayer stream_player;

    const OptionEntry[] option_entries = {
        { "", 0, 0, OptionArg.FILENAME_ARRAY, ref filenames, null, "FILE" },
        { null }
    };

    public MediaPlayer () 
    {
        this.stream_player = new StreamPlayer();
        
		builder = new Gtk.Builder ();
		try 
		{
			builder.add_from_file ("mediaplayer.ui");
		} 
		catch (Error e) 
		{
			error ("Unable to load UI file: " + e.message);
		}
		window = builder.get_object ("window1") as Gtk.Window;
		window.destroy.connect (Gtk.main_quit);
		window.set_title("Vala Media Player");

        menubar = builder.get_object("menubar1") as Gtk.MenuBar;
		
        var menu_quit = builder.get_object("menu_quit") as Gtk.ImageMenuItem;
        menu_quit.activate.connect (Gtk.main_quit);

        var menu_open = builder.get_object("menu_open") as Gtk.ImageMenuItem;
        menu_open.activate.connect (on_open);

        var menu_open_loc = builder.get_object("menu_open_location") as Gtk.ImageMenuItem;
        menu_open_loc.activate.connect (on_open_location);
        
        window.key_press_event.connect(key_press);        
    }
    
    public bool key_press(Gdk.EventKey e) 
    {
        //FIXME: Move this stuff to mediaplayer-controls.vala
        debug ("keypress : %s", Gdk.keyval_name(e.keyval));
        switch (Gdk.keyval_name(e.keyval)) 
        {
            case "Left":
                return true;
            case "Right":
                return true;
            case "Up":
                return true;
            case "Down":
                return true;
            case "q":
            case "Escape":
                Gtk.main_quit();
                return true;
            case "Return":
            case "space":
                stream_player.toggle_pause();
                return true;
            default:
                return false;
        }
    }    
    
    private void open_file (string filename)
    {
        debug ("open_file (%s)", filename);

        stream_player.stop();

        if (stream_player.load_file_info(filename))
        {
            window.set_title( GLib.Path.get_basename(filename) );
            window.resize((int) stream_player.width, (int) stream_player.height);
            
            //FIXME: Figure out why Gst wont resize its video if i resize the gtk window.

            var viewport = builder.get_object("viewport1") as Gtk.Viewport;
            menubar.hide();
            
            stream_player.open(filename);
            player_sink = stream_player.get_player_sink();
            player_sink.set_xwindow_id(gdk_x11_window_get_xid( viewport.get_bin_window() ));
            
            stream_player.play();
        }
    }

    private void on_open_location () 
    {
        //FIXME: 
/*
        var msg_dialog = new MessageDialog(window, DialogFlags.MODAL,
                                           Gtk.MessageType.QUESTION,
                                           ButtonsType.OK_CANCEL, "");

        msg_dialog.set_markup("Please enter the uri:");

        var entry = new Entry();

        var hbox = new HBox(false, 0);
        hbox.pack_start(new Label("URI:"), false, true, 5);
        hbox.pack_end(entry, true, true, 0);

        msg_dialog.vbox.pack_end(hbox, true, true, 0);
        msg_dialog.show_all();

        msg_dialog.run();

        stream = entry.get_text();
        //window.on_stop_clicked();
        stream_player.open(this.stream);
        //window.on_play_clicked();

        msg_dialog.destroy();
*/
    }

    private void on_open () 
    {
        var file_chooser = new FileChooserDialog("Open File", window,
                                                 FileChooserAction.OPEN,
                                                 Stock.CANCEL, ResponseType.CANCEL,
                                                 Stock.OPEN, ResponseType.ACCEPT, null);

        if (file_chooser.run() == ResponseType.ACCEPT) 
        {
            var file = file_chooser.get_filename();
            open_file (file);
        }
        file_chooser.destroy();
    }


	public void run (string[] args) 
	{
		window.show_all ();
	    if (filenames != null)
	    {
            open_file(filenames[0]);
	    }
		Gtk.main ();
	}

    public static int main (string[] args) 
    {
        try 
        {
            var opt_context = new OptionContext("- File to Load");
            opt_context.set_help_enabled(true);
            opt_context.add_main_entries(option_entries, "pags");
            opt_context.parse(ref args);
        } 
        catch (OptionError e) 
        {
            error ("Option parsing failed: %s\n", e.message);
        }        

        Gtk.init(ref args);
        Gst.init(ref args);
        
		var app = new Gtk.Application ("org.gnome.valamediaplayer", 0);
		app.activate.connect ( () => 
		{
				weak GLib.List list = app.get_windows ();
				if (list == null) 
				{
					var mainwindow = new MediaPlayer ();
					mainwindow.run (args);
				} 
				else 
				{
					debug ("already running!");
				}
			});
		return app.run (args);
    }
}
