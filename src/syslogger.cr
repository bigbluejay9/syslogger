require "log"
require "./syslog/*"

module Syslog
  VERSION = "0.1.0"

  enum Facility
    Authorization = LibC::LOG_AUTH
    Privilage     = LibC::LOG_AUTHPRIV
    Cron          = LibC::LOG_CRON
    Daemon        = LibC::LOG_DAEMON
    FTP           = LibC::LOG_FTP
    Kernal        = LibC::LOG_KERN
    LPR           = LibC::LOG_LPR
    Mail          = LibC::LOG_MAIL
    News          = LibC::LOG_NEWS
    Syslog        = LibC::LOG_SYSLOG
    User          = LibC::LOG_USER
    UUCP          = LibC::LOG_UUCP
    Local0        = LibC::LOG_LOCAL0
    Local1        = LibC::LOG_LOCAL1
    Local2        = LibC::LOG_LOCAL2
    Local3        = LibC::LOG_LOCAL3
    Local4        = LibC::LOG_LOCAL4
    Local5        = LibC::LOG_LOCAL5
    Local6        = LibC::LOG_LOCAL6
    Local7        = LibC::LOG_LOCAL7
  end

  enum Priority
    Emergency = LibC::LOG_EMERG
    Alert     = LibC::LOG_ALERT
    Critical  = LibC::LOG_CRIT
    Error     = LibC::LOG_ERR
    Warning   = LibC::LOG_WARNING
    Notice    = LibC::LOG_NOTICE
    Info      = LibC::LOG_INFO
    Debug     = LibC::LOG_DEBUG

    # Returns a log mask that only allows this Priority level to be logged.
    # See also LOG_MASK in man syslog(3).
    def only_mask : UInt8
      1 << (self.value)
    end

    # Returns a log mask that allows all log messages up to and including this priority.
    # See also LOG_UPTO in man syslog(3).
    def up_to_mask : UInt8
      (1 << (self.value + 1)) - 1
    end
  end

  @[Flags]
  enum Options
    Console    = LibC::LOG_CONS
    NoDelay    = LibC::LOG_NDELAY
    Delay      = LibC::LOG_ODELAY
    PrintError = LibC::LOG_PERROR
    PID        = LibC::LOG_PID
  end
end

enum Log::Severity
  def to_syslog_priority : Syslog::Priority
    case self
    when Debug, Verbose then Syslog::Priority::Debug
    when Info           then Syslog::Priority::Info
    when Warning        then Syslog::Priority::Warning
    when Error          then Syslog::Priority::Error
    when Fatal          then Syslog::Priority::Critical
    else
      # None
      Syslog::Priority::Info
    end
  end
end

# All methods are threadsafe.
# Only the first instantiated SyslogBackend applies @facility and @options values.
class Log::SyslogBackend < Log::Backend
  @@initialized = false        # Guarded by @@initialized_mu.
  @@identifier : String? = nil # Guarded by @@initialized_mu
  @@initialized_mu : Mutex = Mutex.new

  property formatter : Formatter? = nil
  getter facility : Syslog::Facility
  getter options : Syslog::Options

  # Only the first created SyslogBackend applies @facility and @options.
  # Subsequent instances of SyslogBackend simply reuses the initial value.
  def initialize(identifier = PROGRAM_NAME,
                 @facility = Syslog::Facility::User,
                 @options = Syslog::Options::None, mask : UInt8 = 0) : Nil
    @@initialized_mu.synchronize do
      next if @@initialized
      @@initialized = true
      @@identifier = identifier
      LibC.openlog(@@identifier.not_nil!, @options.value, @facility.value)
      self.mask = mask
    end

    nil
  end

  @mask : UInt8 = 0

  # Sets the log mask. Returns the previously set mask.
  def mask=(mask : UInt8) : Nil
    raise "Invalid mask given #{mask}" if 0 > mask > 255
    @mask = mask
    LibC.setlogmask(mask)
  end

  # Returns the current log mask.
  def mask : UInt8
    @mask
  end

  def write(entry : Entry) : Nil
    LibC.syslog(entry.severity.to_syslog_priority, format_entry(entry))
  end

  private def format_entry(entry : Entry) : String
    builder = String::Builder.new
    if formatter = @formatter
      formatter.call(entry, builder)
    else
      default_format(entry, builder)
    end
    builder.to_s
  end

  # Similar to Log::IOBackend#default_format.
  private def default_format(entry : Entry, io : IO)
    io << entry.source << ": " unless entry.source.empty?
    io << entry.message
    if entry.context.size > 0
      io << " -- " << entry.context
    end
    if ex = entry.exception
      io << " -- " << ex.class << ": " << ex
    end
  end
end
