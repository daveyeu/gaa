require 'dbus'

# Suppressing some warnings being emitted from DBus::Message.
# I know, I know, ugly.  I've submitted a ticket to the author so call off
# the cavalry.
module Kernel
  def silence_warnings
    old_verbose, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = old_verbose
  end
end

# Could use dbus-send, but that seems to fail intermittently.  No idea why.
class Autotest::Gaa
  def self.update(status, tooltip = '')
    silence_warnings do
      unless defined? @@applet
        bus = DBus::SessionBus.instance
        service = bus.service 'ruby.autotest'
        @@applet = service.object '/ruby/autotest/applet'
        @@applet.introspect
        @@applet.default_iface = 'ruby.autotest.applet.iface'
      end

      @@applet.send status, tooltip
    end
  end

  Autotest.add_hook :all_good do |at|
    update :green, "All tests passed"
  end

  Autotest.add_hook :green do |at|
    update :green, "#{at.files_to_test.size} tests passed"
  end

  Autotest.add_hook :quit do |at|
    update :idle
  end

  Autotest.add_hook :red do |at|
    update :red, "#{at.files_to_test.size} tests failed"
  end

  Autotest.add_hook :run do |at|
    update :running
  end

  Autotest.add_hook :run_command do |at|
    update :running
  end
end
