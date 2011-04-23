using Gst;

public class StreamPlayer 
{
    public dynamic Element player;
    private Element sink;
    private Element visualization;

    public StreamPlayer()
    {
        sink = ElementFactory.make("xvimagesink", "sink");
        visualization = ElementFactory.make("goom2k1", "visualization");
        player = ElementFactory.make("playbin", "player");
        player.video_sink = sink;
        player.vis_plugin = visualization;
        
        Gst.Bus bus = player.get_bus();
        bus.add_watch(bus_callback);

        player.set_state(State.NULL);
    }

    public void open(string stream) 
    {
        player.uri = stream;
        player.set_state(State.READY);
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
