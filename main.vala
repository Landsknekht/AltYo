/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 */

/*
 * Yet another terminal =)
 *
 * valac --pkg gtk+-3.0  ./main.vala ./hvbox.vala ...
 *
 * http://www.valadoc.org/gtk+-3.0/Gtk.Container.html
 * http://developer.gnome.org/gtk3/3.0/GtkContainer.html#gtk-container-get-resize-mode
 * http://developer.gnome.org/gtkmm-tutorial/3.0/sec-custom-containers.html.en
 * https://github.com/mdamt/blankon-panel
 * https://live.gnome.org/Vala/CustomWidgetSamples
 * http://git.xmms2.org/xmms2/abraca/tree/src/widgets/rating_entry.vala?id=ed5e182c4074f1bff56010658a36a75d95807921
 * http://git.freesmartphone.org/?p=vala-terminal.git;a=tree;f=src;h=fca9afcd911ef55db74734080894abfc84576f3c;hb=HEAD
 * http://live.gnome.org/Vala/GStreamerSample
 * http://zetcode.com/tutorials/gtktutorial/gtkevents/
 *
 * pool replace, In C, you can put your buttons and widgets in a GtkOffscreenWindow using gtk_widget_reparent() and then use gtk_offscreen_window_get_pixbuf() to render it onto a GdkPixbuf, which you can then save to a file. Sorry I don't have any Python code, but I don't think the offscreen window is available in PyGTK yet.
 * http://developer.gnome.org/gtk3/3.0/GtkStyleContext.html#gtk-render-frame
 * http://developer.gnome.org/gtk3/3.0/gtk-migrating-GtkApplication.html
 * https://gitorious.org/gnome-boxes/gnome-boxes/blobs/master/src/app.vala
 * http://live.gnome.org/Vala/GSettingsSample
 * http://code.valaide.org/content/example-program-using-keyfile-glib-class-readwrite-ini-files
 * http://developer.gnome.org/pango/stable/PangoMarkupFormat.html
 * http://developer.gnome.org/gcr/3.2/
 *
 * http://www.mono-project.com/GtkSharp_TreeView_Tutorial
 * http://www.kksou.com/php-gtk2/articles/finetune-interactive-search-in-GtkTreeView---Part-4---set-custom-compare-function.php
 * https://mail.gnome.org/archives/commits-list/2012-February/msg03582.html
 * about reparent http://developer.gnome.org/gtk-faq/stable/x635.html
 */

using Gtk;
using Posix;

struct Globals{
	static bool reload = false;
	static bool opt_help = false;
	static string? cmd_conf_file = null;
	static bool toggle = false;
	static string? app_id = null;
	static bool disable_hotkey = false;
	static bool standalone_mode = false;
	static string? path = null;
	static bool config_readonly = false;

	[CCode (array_length = false, array_null_terminated = true)]
	public static string[]? exec_file_with_args = null;

	public static const OptionEntry[] options = {
					/*allow show help from remote call*/
					{ "help", 'h', OptionFlags.HIDDEN, OptionArg.NONE, ref Globals.opt_help, null, null },
					{ "reload", 'r', 0, OptionArg.NONE, ref Globals.reload,N_("Reload configuration"), null },
					{ "cfg", 'c', 0, OptionArg.FILENAME, ref Globals.cmd_conf_file,N_("Read configuration from file"), N_("/path/to/config.ini") },
					/*The option takes a string argument, multiple uses of the option are collected into an array of strings. */
					{ "exec", 'e', 0, OptionArg.STRING_ARRAY, ref Globals.exec_file_with_args,N_("run command in new tab"), N_("\"command arg1 argN...\"") },
					{ "toggle", 0, 0, OptionArg.NONE, ref Globals.toggle,N_("show/hide window"), null },
					{ "id", 0, 0, OptionArg.STRING, ref Globals.app_id,N_("Set application id, none means disable application id"),"org.gtk.altyo_my,none" },
					{ "disable_hotkey", 0, 0, OptionArg.NONE, ref Globals.disable_hotkey,N_("Disable main hotkey"),null},
					{ "standalone", 0, 0, OptionArg.NONE, ref Globals.standalone_mode,N_("Disable control of window dimension, and set --id=none"),null},
					{ "default_path", 0, 0, OptionArg.STRING, ref Globals.path,N_("Set/update default path"),"/home/user/special" },
					{ "config_readonly", 0, 0, OptionArg.NONE, ref Globals.config_readonly, null, null },
					{ null }
			};

}//Globals

unowned Gtk.Window main_win;

static void signal_handler (int signum) {
	main_win.destroy();
}

static void null_handler(string? domain, LogLevelFlags flags, string message) {
	    }

static void print_handler(string? domain, LogLevelFlags flags, string message) {
		printf("domain:%s message:%s\n",domain,message);
	    }

static void configure_debug(MySettings conf){
				if(!conf.get_boolean("debug",false))
					Log.set_handler(null, LogLevelFlags.LEVEL_MASK & ~LogLevelFlags.LEVEL_ERROR, null_handler);
				else{
					var mask = conf.get_string_list("debug_level",{"debug","message","warning","info","critical"});
					LogLevelFlags log_mask = LogLevelFlags.LEVEL_ERROR;//for accerts
					if(mask!=null)
					foreach(var level in mask){
						log_mask = ((level == "debug") ?
						log_mask | LogLevelFlags.LEVEL_DEBUG :
						log_mask);
						log_mask = ((level == "message") ?
						log_mask | LogLevelFlags.LEVEL_MESSAGE :
						log_mask);
						log_mask = ((level == "warning") ?
						log_mask | LogLevelFlags.LEVEL_WARNING :
						log_mask);
						log_mask = ((level == "info") ?
						log_mask | LogLevelFlags.LEVEL_INFO :
						log_mask);
						log_mask = ((level == "critical") ?
						log_mask | LogLevelFlags.LEVEL_CRITICAL :
						log_mask);
					}
					//disable all except log_mask
					//Log.set_handler(null, LogLevelFlags.LEVEL_MASK & ~log_mask, null_handler);
					Log.set_handler(null, LogLevelFlags.LEVEL_MASK & log_mask, print_handler);
				}
}

int main (string[] args) {

	Intl.setlocale (LocaleCategory.ALL, "");
	Intl.bindtextdomain (GETTEXT_PACKAGE, null);
	Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
	Intl.textdomain (GETTEXT_PACKAGE);

	Gtk.init (ref args);
	Globals.app_id="org.gtk.altyo";//default app id
	string[] args2=args;//copy args for local use, original args will be used on remote side
	unowned string[] args3=args2;

	if(args.length>1 ){//show local help if needed
		   try {
				   OptionContext ctx2 = new OptionContext("AltYo");
				   ctx2.add_main_entries(Globals.options, null);
				   ctx2.parse(ref args3);
		   } catch (Error e) {
						   GLib.stderr.printf("Error initializing: %s\n", e.message);
		   }
	}
	args2=null;//destroy

	if(Globals.app_id == "none")
		Globals.app_id=null;
	else if(!GLib.Application.id_is_valid(Globals.app_id)){
		printf("Wrong application id \"%s\"\n",Globals.app_id);
		return 1;//stop on error
	}
	
	if(Globals.standalone_mode){
		Globals.disable_hotkey=true;
		Globals.app_id=null;
	}

    var app = new Gtk.Application(Globals.app_id, ApplicationFlags.HANDLES_COMMAND_LINE);

	//remote args usage
    app.command_line.connect((command_line)=>{//ApplicationCommandLine

			if(!command_line.get_is_remote() )//local command line was handled in app.startup
					return 0;//just ignore it

			string[] argv = command_line.get_arguments();
			debug("app.command_line.connect argv.length=%d",argv.length);

			OptionContext ctx = new OptionContext("AltYo");
			ctx.add_main_entries(Globals.options, null);

			if(argv.length==1 ){//no parameters
				unowned List<weak Window> list = app.get_windows();
				if(list!=null)
					((VTMainWindow)list.data).pull_down(); //another altyo already running, show it
				return 0;//ok
			}else{
				ctx.set_help_enabled (false);//disable exit from application if wrong parameters
				unowned string[] pargv=argv;
				Globals.exec_file_with_args=null;//clear array
				Globals.cmd_conf_file=null;
				Globals.reload=false;
				Globals.opt_help=false;
				Globals.toggle=false;
				Globals.path=null;

				try {
					if(!ctx.parse(ref pargv))return 3;
				} catch (Error e) {
						GLib.stderr.printf("Error initializing: %s\n", e.message);
				}
				debug("app.command_line.connect reload=%d",(int)Globals.reload);
				if(Globals.reload){
					unowned List<weak Window> list = app.get_windows();
					if(list!=null)
						((VTMainWindow)list.data).conf.load_config();
				}else
				if(Globals.exec_file_with_args!=null){
					unowned List<weak Window> list = app.get_windows();
					if(list!=null){
						//var S = string.joinv (" ", Globals.exec_file_with_args);
						string S ="";
						foreach(var s in Globals.exec_file_with_args){
							debug("exec %s",s);
							S+=" "+s;
						}
						VTMainWindow mwin = ((VTMainWindow)list.data);
						if(Globals.path!=null){
							mwin.conf.default_path=Globals.path;
						}
						mwin.ayobject.add_tab_with_title(S,S);
						if(mwin.current_state == WStates.HIDDEN)
							mwin.pull_down();
					}
				}else
				if (Globals.opt_help) {
					command_line.printerr (ctx.get_help (true, null));
					Globals.opt_help=false;
				}else
				if(Globals.toggle){
					unowned List<weak Window> list = app.get_windows();
					if(list!=null)
						((VTMainWindow)list.data).toggle_window();
				}

				Globals.reload=false;

				return 2;//exit status
			}
		});//app.command_line.connect

	app.startup.connect(()=>{//first run
				debug("app.startup.connect");

				var conf = new MySettings(Globals.cmd_conf_file,Globals.standalone_mode);
				conf.readonly=Globals.config_readonly;
				conf.disable_hotkey=Globals.disable_hotkey;
				conf.default_path=Globals.path;

				if(!conf.opened){
					printf("Unable to open configuration file!\n");
					exit(1);
				}

				configure_debug(conf);
				debug("git_hash=%s",AY_GIT_HASH);

				conf.on_load.connect(()=>{
					configure_debug(conf);
				});

				var win = new VTMainWindow (WindowType.TOPLEVEL);
				win.set_application(app);
				win.CreateVTWindow(conf);
				main_win=win;

				if(Globals.exec_file_with_args!=null){
					string S ="";
					foreach(var s in Globals.exec_file_with_args){
						debug("exec %s",s);
						S+=" "+s;
					}
					
					win.ayobject.add_tab_with_title(S,S);
				}
				
				sigaction_t action = sigaction_t ();
				action.sa_handler = signal_handler;
				/* Hook up signal handlers */
				sigaction (SIGINT, action, null);
				sigaction (SIGQUIT, action, null);
				//sigaction (SIGABRT, action, null);//something wrong! don't save file
				sigaction (SIGTERM, action, null);
				sigaction (SIGKILL, action, null);
				Gtk.main ();

		});//app.startup.connect
	var status = app.run(args);

    return status;
}
