##
# Gnome Autotest Applet (gaa) is a GNOME panel applet that displays the
# results of Autotest runs.
#
# Autotest is part of ZenTest, available as a gem.  See:
#   http://rubyforge.org/projects/zentest/
#
# This little ditty was written using:
#  * Ruby-GNOME2 -- http://ruby-gnome2.sourceforge.jp/
#  * Ruby D-Bus  -- https://trac.luon.net/ruby-dbus/
#
# Both are required.

require 'gtk2'
require 'dbus'
require 'thread'
Thread.abort_on_exception = true

DBUS_INTERFACE = 'ruby.autotest.applet.iface'
DBUS_OBJECT    = '/ruby/autotest/applet'
DBUS_SERVICE   = 'ruby.autotest'

class DBusService < DBus::Object
  attr_accessor :applet

  dbus_interface DBUS_INTERFACE do
    dbus_method :green, 'in tooltip:s' do |tooltip|
      applet.tooltip = tooltip
      applet.file = Applet::GREEN_ICON
    end

    dbus_method :red, 'in tooltip:s' do |tooltip|
      applet.tooltip = tooltip
      applet.file = Applet::RED_ICON
    end

    dbus_method :idle, 'in tooltip:s' do |tooltip|
      applet.tooltip = 'Idle'
      applet.file = Applet::IDLE_ICON
    end

    dbus_method :running, 'in tooltip:s' do |tooltip|
      applet.tooltip = 'Running tests...'
      applet.file = Applet::RUNNING_ICON
    end
  end
end

class Applet
  ICONS_DIR = File.join File.dirname(__FILE__), '..', 'icons'

  GREEN_ICON   = File.join ICONS_DIR, 'green.png'
  IDLE_ICON    = File.join ICONS_DIR, 'grey.png'
  RED_ICON     = File.join ICONS_DIR, 'red.png'
  RUNNING_ICON = File.join ICONS_DIR, 'yellow.png'

  def self.run
    Applet.new.start
  end

  def initialize
    setup_menu
    setup_applet
    setup_dbus
  end

  def setup_applet
    @applet = Gtk::StatusIcon.new
    @applet.file = IDLE_ICON
    @applet.tooltip = 'Idle'

    @applet.signal_connect('popup-menu') do |applet, button, activate_time|
      @popup_menu.popup nil, nil, button, activate_time do |menu, x, y, push_in|
        applet.position_menu menu
      end
    end
  end

  def setup_dbus
    bus = DBus.session_bus
    service = bus.request_service DBUS_SERVICE

    obj = DBusService.new DBUS_OBJECT
    obj.applet = @applet
    service.export obj

    @main = DBus::Main.new
    @main << bus
  end

  def setup_menu
    @quit_menu_item = Gtk::MenuItem.new('Quit')

    @popup_menu = Gtk::Menu.new
    @popup_menu.append @quit_menu_item
    @popup_menu.show_all

    @quit_menu_item.signal_connect('activate') do
      Gtk.main_quit
      false
    end
  end

  # DBus loop is run in a separate thread; both are blocking loops
  def start
    Thread.new { @main.run }
    Gtk.main
  end
end
