using Gst;
using Gtk;

/* Whether or not to output debug messages */
public bool debug = false;

public class MediaPlayer : Window {

    private string stream;
    private DrawingArea drawing_area;
    private StreamPlayer stream_player;

    public MediaPlayer() {

        this.set_title("Media Player");

        this.destroy.connect(Gtk.main_quit);

        // Create UI
        create_ui();

        this.stream_player = new StreamPlayer();

    }

    private void create_ui() {

        var vbox = new VBox(false, 0);

        MenuBar menu_bar = new MenuBar();

        Menu file_menu = new Menu();

        MenuItem open_item = new MenuItem();
        open_item.set_label("Open");
        open_item.activate.connect(on_open_clicked);

        MenuItem open_loc_item = new MenuItem();
        open_loc_item.set_label("Open Location");
        open_loc_item.activate.connect(on_file_loc_activated);

        MenuItem quit_item = new MenuItem();
        quit_item.set_label("Quit");
        quit_item.activate.connect(Gtk.main_quit);

        file_menu.append(open_item);
        file_menu.append(open_loc_item);
        file_menu.append(quit_item);

        MenuItem file_item = new MenuItem();
        file_item.set_label("File");
        file_item.set_submenu(file_menu);

        menu_bar.append(file_item);

        vbox.pack_start(menu_bar, false, true, 0);

        this.drawing_area = new DrawingArea();
        this.drawing_area.set_size_request(400, 300);

        var black = Gdk.Color() {
            red = 0,
            green = 0,
            blue = 0
        };

        this.drawing_area.modify_bg(Gtk.StateType.NORMAL, black);

        vbox.pack_start(this.drawing_area, true, true, 0);

        var open_button = new Button.from_stock(Stock.OPEN);
        open_button.clicked.connect(on_open_clicked);

        var play_button = new Button.from_stock(Stock.MEDIA_PLAY);
        play_button.clicked.connect(on_play_clicked);

        var stop_button = new Button.from_stock(Stock.MEDIA_STOP);
        stop_button.clicked.connect(on_stop_clicked);

        var button_box = new HButtonBox();
        button_box.add(open_button);
        button_box.add(play_button);
        button_box.add(stop_button);

        vbox.pack_start(button_box, false, true, 0);

        add(vbox);

    }

    private void on_file_loc_activated() {

        var msg_dialog = new MessageDialog(this, DialogFlags.MODAL,
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

        this.stream = entry.get_text();
        this.on_stop_clicked();
        this.stream_player.open(this.stream);
        this.on_play_clicked();

        msg_dialog.destroy();

    }

    private void on_open_clicked() {

        var file_chooser = new FileChooserDialog("Open File", this,
                                                 FileChooserAction.OPEN,
                                                 Stock.CANCEL, ResponseType.CANCEL,
                                                 Stock.OPEN, ResponseType.ACCEPT, null);

        if (file_chooser.run() == ResponseType.ACCEPT) {
            this.stream = file_chooser.get_uri();
            this.on_stop_clicked();
            this.stream_player.open(this.stream);
            this.on_play_clicked();
        }

        file_chooser.destroy();

    }

    private void on_play_clicked() {

        var xoverlay = this.stream_player.get_player_sink();
        xoverlay.set_xwindow_id(Gdk.x11_drawable_get_xid(this.drawing_area.window));

        Gst.State state;
        Gst.State pending;
        Gst.ClockTime timeout = 1000;

        this.stream_player.player.get_state(out state, out pending, timeout);

        if (state == State.READY ||
            state == State.PAUSED) {

            this.stream_player.play();

        } else if (state == State.PLAYING) {

            this.stream_player.pause();

        } else if (state == State.NULL) {

            stdout.printf("Need to load a stream of sorts!\n");

        }

    }

    private void on_stop_clicked() {

        this.stream_player.stop();

    }

    public static int main (string[] args) {

        Gtk.init(ref args);
        Gst.init(ref args);

        var media_player = new MediaPlayer();
        media_player.show_all();

        Gtk.main();

        return 0;

    }

}

public class StreamPlayer {

    public dynamic Element player;
    private Element sink;
    private Element visualization;

    public StreamPlayer() {

        this.sink = ElementFactory.make("xvimagesink", "sink");
        this.visualization = ElementFactory.make("goom2k1", "visualization");
        this.player = ElementFactory.make("playbin", "player");
        this.player.video_sink = this.sink;
        this.player.vis_plugin = this.visualization;

        Gst.Bus bus = this.player.get_bus();
        bus.add_watch(bus_callback);

        this.player.set_state(State.NULL);

    }

    public void open(string stream) {

        this.player.uri = stream;

        this.player.set_state(State.READY);

    }

    public XOverlay get_player_sink() {

        return this.player.video_sink;

    }

    public void play() {

        this.player.set_state(State.PLAYING);

    }

    public void pause() {

        this.player.set_state(State.PAUSED);

    }

    public void stop() {

        this.player.set_state(State.READY);

    }

    private void foreach_tag(Gst.TagList list, string tag) {
        switch (tag) {
        case "title":
            string tag_string;
            list.get_string (tag, out tag_string);
            stdout.printf ("tag: %s = %s\n", tag, tag_string);
            break;
        default:
            break;
        }
    }

    private bool bus_callback(Gst.Bus bus, Gst.Message message) {

        switch (message.type) {

            case Gst.MessageType.ERROR:

                GLib.Error err;
                string debug;
                message.parse_error (out err, out debug);
                stdout.printf ("Error: %s\n", err.message);

                break;

            case Gst.MessageType.EOS:

                stdout.printf ("end of stream\n");

                break;

               case Gst.MessageType.STATE_CHANGED:

                Gst.State oldstate;
                Gst.State newstate;
                Gst.State pending;
                message.parse_state_changed (out oldstate, out newstate,
                                             out pending);
                if (debug) {
                    stdout.printf ("state changed: %s->%s:%s\n",
                                   oldstate.to_string (), newstate.to_string (),
                                   pending.to_string ());
                }

                break;

            case Gst.MessageType.TAG:

                Gst.TagList tag_list;
                stdout.printf ("taglist found\n");
                message.parse_tag (out tag_list);
                tag_list.foreach ((TagForeachFunc) foreach_tag);

                break;

            default:
                break;

        }

        return true;

    }

}
