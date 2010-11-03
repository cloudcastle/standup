require 'standup'

task :standup do
  puts
  bright_p "Standup scripts list:"
  offset = Standup.scripts.keys.map(&:length).max + 2
  Standup.scripts.each do |name, script|
    puts "  rake standup:\e[1m#{"%-#{offset}s" % name}\e[0m #{script.description}"
  end
  puts
end

namespace :standup do
  desc "Generate config file"
  task :create do
    FileUtils.copy File.expand_path('../../../standup.yml',  __FILE__),
                   File.expand_path('config',  Rails.root)
  end
  
  Standup.scripts.each do |name, _|
    desc "Run script #{name} for each node"
    task name.to_sym do
      Standup.nodes.each {|node| node.run_script name}
    end
  end
end
