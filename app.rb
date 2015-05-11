# Required Gems
require 'sinatra'
require 'mechanize'
require 'erb'
require 'json'

# Require classes/helpers
require './scraper.rb'

# Enable sessions
enable :sessions

# Routes
get '/' do
	erb :index
end