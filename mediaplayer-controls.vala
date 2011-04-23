/*
public class Controls 
{
    
    public Controls ()
    {
    
    
    }
    
    public bool key_press(Gdk.EventKey e) 
    {
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

}
*/
