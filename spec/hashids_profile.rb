# encoding: utf-8

# Profile with perftools.rb
#
#  CPUPROFILE=/tmp/hashids_profile \
#  RUBYOPT="-r`gem which 'perftools.rb' | tail -1`" \
#  ruby spec/hashids_profile.rb
#
# Generate diagram
#
#  pprof.rb --gif /tmp/hashids_profile > /tmp/hashids_profile.gif && \
#  open /tmp/hashids_profile.gif
#

require_relative "../lib/hashids"

h = Hashids.new('this is my salt')

10_000.times do |n|
  h.decrypt(h.encrypt(n))
end
