# Required Gems
require 'sinatra'
require 'erb'
require 'json'
require 'mechanize'
require 'pry'
require 'csv'

# Require classes/helpers
require './scraper.rb'
require './saver.rb'

# Enable sessions
enable :sessions

# Set server to prevent error w/ mechanize
set :server, 'webrick'

# Routes
get '/' do
	scraper = Scraper.new
	results = scraper.search(params[:zip].to_i)
	scraper.save(results)
	erb :index
end
