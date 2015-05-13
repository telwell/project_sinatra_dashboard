# Required Gems
require 'sinatra'
require 'erb'
require 'json'
require 'mechanize'
require 'pry'

# Require classes/helpers
require './scraper.rb'
require './saver.rb'
require './helpers/dashboard_helper.rb'

# Register helper
helpers DashboardHelper

# Enable sessions
enable :sessions

# Set server to prevent error w/ mechanize
set :server, 'webrick'

# Set Constants
DEFAULT_ZIP = 10030
WEATHER_ARGS = [:month, :day, :year, :temp_low, :temp_high, :classification]
WEATHER_CSV_FILE = 'weather.csv'
CRAIGSLIST_ARGS = [:name, :url, :email, :price, :location]
CRAIGSLIST_CSV_FILE = 'craigslist.csv'

# Routes
get '/' do
	scraper = Scraper.new
	scraper.save_session(params, session)
	@weather_results = scraper.search_weather(whats_my_zip)
	@craigslist_results = scraper.search_craigslist(session[:min_price], session[:max_price], session[:query]) if craigslist_has_session?
	erb :index
end
