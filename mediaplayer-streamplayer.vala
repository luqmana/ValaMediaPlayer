using Gst;

public class StreamPlayer 
{
    public dynamic Element player;
    private Element sink;
    private Element visualization;
    
    public dynamic Discoverer discoverer;
    
    private static uint64 gst_timeout;
    
    public uint width { get; private set; default = 300; }
    public uint height { get; private set; default = 300; }

    public StreamPlayer()
    {
        gst_timeout = 10;
        
        sink = ElementFactory.make("xvimagesink", "sink");
        visualization = ElementFactory.make("goom2k1", "visualization");
        player = ElementFactory.make("playbin", "player");
        player.video_sink = sink;
        player.vis_plugin = visualization;
        
        Gst.Bus bus = player.get_bus();
        bus.add_watch(bus_callback);

        player.set_state(State.NULL);

        try
        {
            discoverer = new Discoverer((ClockTime)( gst_timeout * Gst.SECOND ));
        }
        catch (Error e)
        {
			error ("Unable to init Gst.Discoverer: " + e.message);
        }
    }
    
    public string validate_uri (string filename)
    {
        if ( Gst.uri_is_valid ("file://" + filename) && 
             GLib.FileUtils.test(filename, GLib.FileTest.IS_REGULAR) )
        {
            return "file://" + filename;
        }
        else if (Gst.uri_is_valid (filename) )
        {
            return filename;
        }

        warning ("%s is not a valid uri", filename);
        return "";
    }
    
    public bool load_file_info(string filename)
    {
        var uri = validate_uri(filename);
        
        if ( uri == "")
        {
            return false;
        }
        
        DiscovererInfo info;
        try
        {
            info = discoverer.discover_uri(uri);
        }
        catch (Error e)
        {
			error ("Unable discover_uri: " + e.message);
        }

        foreach (Gst.DiscovererStreamInfo i in info.get_stream_list())
        {
            if (i is DiscovererVideoInfo)
            {
                var v = (DiscovererVideoInfo) i;
                debug ("%s has Video", filename);
                debug ("width %u", v.get_width());
                debug ("height %u", v.get_height());
                height = v.get_height();
                width = v.get_width();
            }
            else if (i is DiscovererAudioInfo)
            {
                var a = (DiscovererAudioInfo) i;
                debug ("%s has Audio", filename);
            }
        }
        return true;
    }

    public bool open(string filename)
    {
        var uri = validate_uri(filename);
        
        if ( uri == "")
        {
            return false;
        }
        
        player.uri = uri;
        player.set_state(State.READY);
        return true;
    }

    public XOverlay get_player_sink() 
    {
        return player.video_sink;
    }

    public void play() 
    {
        player.set_state(State.PLAYING);
    }

    public void toggle_pause() 
    {
        Gst.State state;
        Gst.State pending;
        player.get_state(out state, out pending, 1000);
        
        if (state == State.PLAYING)
        {
            player.set_state(State.PAUSED);
        }
        else if (state == State.PAUSED)
        {
            player.set_state(State.PLAYING);
        }
    }

    public void stop() 
    {
        player.set_state(State.READY);
    }

    private void foreach_tag(Gst.TagList list, string tag) 
    {
        switch (tag) 
        {
            case "title":
                string tag_string;
                list.get_string (tag, out tag_string);
                stdout.printf ("tag: %s = %s\n", tag, tag_string);
                break;
        }
    }

    private bool bus_callback(Gst.Bus bus, Gst.Message message) 
    {
        switch (message.type) 
        {
            case Gst.MessageType.ERROR:
                GLib.Error err;
                string debug;
                message.parse_error (out err, out debug);
                stdout.printf ("Error: %s", err.message);
                break;

            case Gst.MessageType.EOS:
                debug ("end of stream");
                break;

               case Gst.MessageType.STATE_CHANGED:
                Gst.State oldstate;
                Gst.State newstate;
                Gst.State pending;
                message.parse_state_changed (out oldstate, out newstate,
                                             out pending);
/*                                             
                debug ("state changed: %s->%s:%s",
                               oldstate.to_string (), newstate.to_string (),
                               pending.to_string ());
*/                               
                break;

            case Gst.MessageType.TAG:
                Gst.TagList tag_list;
                message.parse_tag (out tag_list);
                tag_list.foreach (foreach_tag);
                break;

            default:
                debug(message.type.to_string());
                break;
        }
        return true;
    }
}
