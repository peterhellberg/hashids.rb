require "rake/testtask"
require "bundler/gem_tasks"

task :default => :spec

Rake::TestTask.new(:spec) do |t|
  t.test_files = FileList['spec/**/*_spec.rb']
end

task :profile do
  Bundler.with_clean_env do
    exec 'CPUPROFILE=/tmp/hashids_profile ' +
         'RUBYOPT="-r`gem which \'perftools.rb\' | tail -1`" ' +
         'ruby spec/hashids_profile.rb && ' +
         'pprof.rb --gif /tmp/hashids_profile > /tmp/hashids_profile.gif && ' +
         'open /tmp/hashids_profile.gif'
  end
end
