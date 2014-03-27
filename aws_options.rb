module Options

  @options = {}

  OptionParser.new do |opts|

    opts.on("-n", "--name string", String, "name") do |name|
      @options[:name] = name 
    end

    opts.on("-i", "--ip string", String, "ip_address") do |i|
      @options[:ip] = i
    end

    opts.on("-s", "--size string", String, "size") do |s|
      @options[:size] = s
    end

    opts.on("-o", "--os string", String, "os") do |os|
      @options[:os] = os
    end

    opts.on("-k", "--keypair string", String, "keypair") do |keypair|
      @options[:keypair] = keypair
    end

    opts.on("-b", "--block string", String, "block") do |block|
      @options[:block] = []
      blocks = block.split(/\s?DeviceName\s?/)
      blocks.shift
      blocks.each do |b|
        h = {}
        t = b.split
        t.unshift 'DeviceName'
        until t.empty?
          a = t.shift(2)
          h[a[0]] = a[1]
        end
        @options[:block].push h unless h.nil?
      end
    end

    opts.on("-g", "--security_groups first,second,third", Array, "security groups") do |sg|
      @options[:security_groups] = sg
    end
  end.parse!

  @options[:block] = [] if @options[:block].nil?

  def valid_instance_options?
    if @options[:name].nil? || @options[:ip].nil? || @options[:size].nil? || @options[:os].nil? || @options[:security_groups].nil? || @options[:keypair].nil?
      puts @options[:banner]
      return false
    end
    true
  end

end