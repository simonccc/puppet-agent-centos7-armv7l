Puppet::Type.type(:selboolean).provide(:getsetsebool) do
  desc 'Manage SELinux booleans using the getsebool and setsebool binaries.'

  commands getsebool: '/usr/sbin/getsebool'
  commands setsebool: '/usr/sbin/setsebool'

  def value
    debug "Retrieving value of selboolean #{@resource[:name]}"

    status = getsebool(@resource[:name])

    case status
    when %r{ off$}
      return :off
    when %r{ on$}
      return :on
    else
      status.chomp!
      raise Puppet::Error, "Invalid response '#{status}' returned from getsebool"
    end
  end

  def value=(new)
    persist = ''
    if @resource[:persistent] == :true
      debug 'Enabling persistence'
      persist = '-P'
    end
    execoutput("#{command(:setsebool)} #{persist} #{@resource[:name]} #{new}")
    :file_changed
  end

  # Required workaround, since SELinux policy prevents setsebool
  # from writing to any files, even tmp, preventing the standard
  # 'setsebool("...")' construct from working.

  def execoutput(cmd)
    output = ''
    begin
      execpipe(cmd) do |out|
        output = out.readlines.join('').chomp!
      end
    rescue Puppet::ExecutionFailure
      raise Puppet::ExecutionFailure, output.split("\n")[0], $ERROR_INFO.backtrace
    end
    output
  end
end
