require 'cgi'
require 'json'
require 'logger'
require 'pp'
require 'singleton'

require 'aws-sdk-core'
require 'ruby-progressbar'
require 'term/ansicolor'

module Miam; end
require 'miam/logger'
require 'miam/client'
require 'miam/driver'
require 'miam/dsl'
require 'miam/dsl/context'
require 'miam/dsl/context/group'
require 'miam/dsl/context/user'
require 'miam/dsl/converter'
require 'miam/exporter'
require 'miam/ext/string_ext'
require 'miam/password_manager'
require 'miam/utils'
require 'miam/version'
