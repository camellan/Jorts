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

// TODO: GTK4: This will all go away because gtk4 has an editablelabel
public class jorts.EditableLabel : Gtk.Box {
    public signal void changed (string new_title);
    public Gtk.Label title;
    private Gtk.Entry entry;
    private Gtk.Stack stack;
    private Gtk.Grid grid;

    public string text {
        get {
            return title.label;
        }

        set {
            title.label = value;
        }
    }

    private bool editing {
        set {
            if (value) {
                entry.text = title.label;
                stack.set_visible_child (entry);
                entry.grab_focus ();
            } else {
                if (entry.text.strip () != "" && title.label != entry.text) {
                    title.label = entry.text;
                    changed (entry.text);
                }

                stack.set_visible_child (grid);
            }
        }
    }

    public EditableLabel (string? title_name) {
        valign = Gtk.Align.CENTER;
        //  events |= Gdk.EventMask.ENTER_NOTIFY_MASK;
        //  events |= Gdk.EventMask.LEAVE_NOTIFY_MASK;
        //  events |= Gdk.EventMask.BUTTON_PRESS_MASK;

        this.get_style_context().add_class("editablelabel");

        title = new Gtk.Label (title_name);
        title.ellipsize = Pango.EllipsizeMode.END;
        title.hexpand = true;

        var edit_button = new Gtk.Button ();
        edit_button.set_icon_name ("edit-symbolic");
        edit_button.get_style_context ().add_class (Granite.STYLE_CLASS_FLAT);
        edit_button.set_tooltip_text (_("Edit title"));

        var button_revealer = new Gtk.Revealer ();
        button_revealer.valign = Gtk.Align.CENTER;
        button_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        button_revealer.set_child (edit_button);

        var dummy_spacer = new Gtk.Grid ();

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        size_group.add_widget (dummy_spacer);
        size_group.add_widget (edit_button);

        grid = new Gtk.Grid ();
        grid.valign = Gtk.Align.CENTER;
        grid.column_spacing = 6;
        grid.hexpand = false;
        grid.attach (dummy_spacer, 0, 0, 0, 0);
        grid.attach (title, 0, 0, 0, 0);
        grid.attach (button_revealer, 0, 0, 0, 0);

        entry = new Gtk.Entry ();
        entry.xalign = 0.5f;

        var entry_style_context = entry.get_style_context ();
        entry_style_context.add_class (Granite.STYLE_CLASS_FLAT);
        entry_style_context.add_class (Granite.STYLE_CLASS_TITLE);

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        stack.add_child(grid);
        stack.add_child(entry);
        this.append(stack);

        enter_notify_event.connect ((event) => {
            if (event.detail != Gdk.NotifyType.INFERIOR) {
                button_revealer.set_reveal_child (true);
                event.window.set_cursor (new Gdk.Cursor.from_name (Gdk.Display.get_default(), "text"));
            }

            return false;
        });

        leave_notify_event.connect ((event) => {
            if (event.detail != Gdk.NotifyType.INFERIOR) {
                button_revealer.set_reveal_child (false);
            }
            event.window.set_cursor (new Gdk.Cursor.from_name (Gdk.Display.get_default(), "default"));

            return false;
        });

        button_release_event.connect ((event) => {
            editing = true;
            return false;
        });

        edit_button.clicked.connect (() => {
            editing = true;
        });

        entry.activate.connect (() => {
            editing = false;
        });

        entry.focus_out_event.connect ((event) => {
            editing = false;
            return false;
        });

        entry.icon_release.connect ((p0, p1) => {
            if (p0 == Gtk.EntryIconPosition.SECONDARY) {
                editing = false;
            }
        });
    }
}
