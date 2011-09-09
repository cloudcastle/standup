Standup.script :node do
  def run
    unless remoting.rvm_installed?
      install_package 'git-core'
      sudo 'bash < <(curl -s https://rvm.beginrescueend.com/install/rvm)'
      sudo 'usermod -a -G rvm ubuntu'
      sudo 'usermod -a -G rvm www-data'
      sudo 'cd /usr/local/bin && sudo ln -s /usr/local/rvm/bin/rvm-shell'
      upload script_file('rvmrc'), :to => '/etc/rvmrc', :sudo => true
      exec 'source /usr/local/rvm/scripts/rvm'
      remoting.instance_variable_set :@rvm_installed, true
    end

    unless exec('rvm list')[version]
      install_packages 'build-essential bison openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev'

      sudo "rvm install #{version}"
      sudo "rvm use #{version} --default"

      upload script_file('gemrc'),
             :to => '/etc/gemrc',
             :sudo => true
    end
  end

  def info
    @rvminfo ||= YAML.load(exec('rvm info')).values.first
    {
        :gem_dir => "#{@rvminfo['homes']['gem']}/gems",
        :bin_ruby => @rvminfo['binaries']['ruby'],
        :wrapper => "#{@rvminfo['homes']['ruby'].gsub('/rubies/', '/wrappers/')}/ruby"
    }
  end

  def version
    @version ||= begin
      files = Dir['**/.rvmrc']

      if files.empty?
        if params.version.present?
          params.version
        else
          puts "Cannot fine ruby version declaration neither in .rvmrc file or ruby script param"
          raise Exception.new('Cannot find ruby version declaration')
        end
      else
        declarations = files.map do |file|
          if (rvm_declaration = IO.read(file)).index('rvm') == 0
            rvm_declaration.split(' ').second.split('@').first
          else
            puts "Cannot parse .rvmrc declaration:\n#{rvm_declaration}"
            raise Exception.new("Cannot parse #{file}")
          end
        end.uniq

        if declarations.size > 1
          puts "Found different ruby version declarations #{declarations}"
          if params.version.present?
            params.version
          else
            raise Exception.new('Several ruby version declarations found')
          end
        else
          declarations.first
        end
      end
    end
  end
end
