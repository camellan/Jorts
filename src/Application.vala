/*
* Copyright (c) 2017-2024 Lains
* Copyright (c) 2025 Stella (teamcons on GitHub) and the Ellie_Commons community
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/


/*

General oversight of loading and supporting functions
At some point i may move this in its own file



*/



namespace jorts {
    public class Application : Gtk.Application {
        public Gee.ArrayList<MainWindow> open_notes = new Gee.ArrayList<MainWindow>();
        public static GLib.Settings gsettings;

        public Application () {
            Object (flags: ApplicationFlags.HANDLES_COMMAND_LINE,
                    application_id: jorts.Constants.RDNN);
        }

        // Changed whenever a note changes zoom
        // So we can adjust new notes to have whatever user feel is comfortable
	    public int latest_zoom;


        /*************************************************/
        public override void startup () {
            base.startup ();

            // The localization thingamabob
            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
            Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
            Intl.textdomain (GETTEXT_PACKAGE);


            // Force the eOS icon theme, and set the blueberry as fallback, if for some reason it fails for individual notes
            var granite_settings = Granite.Settings.get_default ();
            var gtk_settings = Gtk.Settings.get_default ();
            gtk_settings.gtk_icon_theme_name = "elementary";

            gtk_settings.gtk_theme_name =   "io.elementary.stylesheet." + jorts.Constants.DEFAULT_THEME.ascii_down();

            // Also follow dark if system is dark lIke mY sOul.
            gtk_settings.gtk_application_prefer_dark_theme = (
	                granite_settings.prefers_color_scheme == DARK
                );
	
            granite_settings.notify["prefers-color-scheme"].connect (() => {
                gtk_settings.gtk_application_prefer_dark_theme = (
                        granite_settings.prefers_color_scheme == DARK
                    );
            }); 

            //this.scribbly_mode_active = gsettings.get_boolean ("scribbly_mode_active");

            // build all the stylesheets
            jorts.Themer.init_all_themes();
        }



        /*************************************************/        
        static construct {
            gsettings = new GLib.Settings (jorts.Constants.RDNN);

        }


        /*************************************************/
        construct {

            var quit_action = new SimpleAction ("quit", null);
            set_accels_for_action ("app.quit", {"<Control>q"});
            add_action (quit_action);
            quit_action.activate.connect (() => {
                this.save_to_stash ();
                this.quit();
            });
            var new_action = new SimpleAction ("new", null);
            set_accels_for_action ("app.action_new", {"<Control>n"});
            add_action (new_action);
            new_action.activate.connect (() => {
                create_note(null);
            });
            var delete_action = new SimpleAction ("delete", null);
            set_accels_for_action ("app.action_delete", {"<Control>w"});
            add_action (delete_action);
            delete_action.activate.connect (() => {
                MainWindow note = (MainWindow)get_active_window ();
                remove_note(note);
            });
            var save_action = new SimpleAction ("save", null);
            set_accels_for_action ("app.save", {"<Control>s"});
            add_action (save_action);
            save_action.activate.connect (() => {
                this.save_to_stash ();
            });
            var zoom_out = new SimpleAction ("zoom_out", null);
            set_accels_for_action ("app.zoom_out", { "<Control>minus", "<Control>KP_Subtract", null });
            add_action (zoom_out);
            zoom_out.activate.connect (() => {
                MainWindow note = (MainWindow)get_active_window ();
                note.zoom_out ();
            });
            var zoom_default = new SimpleAction ("zoom_default", null);
            set_accels_for_action ("app.zoom_default", { "<control>0", "<Control>KP_0", null });
            add_action (zoom_default);
            zoom_default.activate.connect (() => {
                MainWindow note = (MainWindow)get_active_window ();
                note.set_zoom (jorts.Constants.DEFAULT_ZOOM);
            });
            var zoom_in = new SimpleAction ("zoom_in", null);
            set_accels_for_action ("app.zoom_in", { "<Control>plus", "<Control>equal", "<Control>KP_Add", null });
            add_action (zoom_in);
            zoom_in.activate.connect (() => {
                MainWindow note = (MainWindow)get_active_window ();
                note.zoom_in ();
            });
            var toggle_scribbly = new SimpleAction ("toggle_scribbly", null);
            set_accels_for_action ("app.toggle_scribbly", { "<Control>H", null });
            add_action (toggle_scribbly);
            toggle_scribbly.activate.connect (() => {
                this.toggle_scribbly();
            });


            //  gsettings.changed["scribbly-mode-active"].connect (() => {
            //      foreach (MainWindow note in this.open_notes) {
            //          note.on_scribbly_changed();
            //      }
            //  });

        }

        // Clicked: Either show all windows, or rebuild from storage
        protected override void activate () {
            
            // Test Lang
            //GLib.Environment.set_variable ("LANGUAGE", "pt_br", true);
            if (get_windows ().length () > 0) {
                show_all();
            } else {
                this.init_all_notes ();
            }     
	    }


    // Create new instances of MainWindow
    // If we have data, nice, just load it into a new instance
    // Else we do a lil new note

	public void create_note(noteData? data) {
        MainWindow note;
        if (data != null) {
            note = new MainWindow(this, data);
        }
        else {

            // Skip theme from previous window, but use same text zoom
            MainWindow last_note = this.open_notes.last ();
            string skip_theme = last_note.theme;
            var random_data = jorts.Utils.random_note(skip_theme);

            // A chance at pulling the Golden Sticky
            random_data = jorts.Utils.golden_sticky(random_data);

            random_data.zoom = this.latest_zoom;
            note = new MainWindow(this, random_data);



        }
        this.open_notes.add(note);
        this.save_to_stash ();
	}

    // Simply remove from the list of things to save, and close
    public void remove_note(MainWindow note) {
            debug ("Removing a note…\n");
            this.open_notes.remove (note);
            this.save_to_stash ();
	}

    public void save_to_stash() {
        jorts.Stash.check_if_stash ();
        string json_data = jorts.Jason.jsonify (open_notes);
        jorts.Stash.overwrite_stash (json_data, jorts.Constants.FILENAME_STASH);
    }


    public void toggle_scribbly() {
        var scribbly_mode_active = Application.gsettings.get_boolean ("scribbly-mode-active");
        if (scribbly_mode_active) {
            gsettings.set_boolean ("scribbly-mode-active",false);
        } else {
            gsettings.set_boolean ("scribbly-mode-active",true);
        }
    }


    public void show_all() {
        foreach (var window in open_notes) {
            if (window.visible) {
                window.present ();
            }
        }
    }




    /*************************************************/
    public void init_all_notes() {
        Gee.ArrayList<noteData> loaded_data = jorts.Stash.load_from_stash();

        // Load everything we have
        foreach (noteData data in loaded_data) {
            print("Loaded: " + data.title + "\n");
            this.create_note(data);
        }


        if (jorts.Stash.need_backup(gsettings.get_string("last-backup"))) {
            print("Doing a backup! :)");

            jorts.Stash.check_if_stash ();
            string json_data = jorts.Jason.jsonify (this.open_notes);
            jorts.Stash.overwrite_stash (json_data, jorts.Constants.FILENAME_BACKUP);

            var now = new DateTime.now_utc ().to_string() ;
            gsettings.set_string("last-backup", now);
        }

    }




        /*************************************************/
        protected override int command_line (ApplicationCommandLine command_line) {
            PreferenceWindow preferences;
            string[] args = command_line.get_arguments ();

            activate ();
            switch (args[1]) {
                case "--new-note":
                    create_note(null);
                    break;
                case "--preferences":
                    preferences = new PreferenceWindow(this);
                    break;
                default: break;
            }
            return 0;

        }

        public static int main (string[] args) {
            var app = new Application();
            return app.run(args);
        }
    }
}
