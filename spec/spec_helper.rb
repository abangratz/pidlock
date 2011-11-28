$: << '.'
require 'bundler/setup'
Bundler.setup(:default, :development)
require 'stringio'

require 'sys/proctable'
require 'lib/pidlock'

