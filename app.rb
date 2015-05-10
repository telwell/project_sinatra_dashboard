# Required Gems
require 'sinatra'
require 'erb'
require 'json'

# Enable sessions
enable :sessions

# Routes
get '/' do
	'Hello world!'
end