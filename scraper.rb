# Create struct for our weather results
Forecast = Struct.new(:day, :month, :year, :temp_low, :temp_high, :classification)
Listing = Struct.new(:name, :url, :email, :price, :location)

class Scraper
	def initialize
		@agent = get_agent
	end

	# Initiate searching WUNDERGROUND. Return an array full of 
	# FORECAST Structs for the 10-day forecast.
	def search_weather(zip)
		page = @agent.get('http://wunderground.com') do |page|
			area_page = search_by_zip(page, zip)
			calendar_page = find_calendar_page(area_page)
			return forecast_info(calendar_page)
		end
	end

	# Search method for searching NYC craigslist for apartments
	# based on location, max, and min prices. Returns a results
	# array with all Listing Structs ready to
	# be sent to a CSV file.
	def search_craigslist(min_price, max_price, query)
		search_base_url = 'http://newyork.craigslist.org/search/aap'
		listing_base_url = 'http://newyork.craigslist.org'
		login_page = nil
		begin
		  page = @agent.get(search_base_url)
		rescue Mechanize::ResponseCodeError => exception
		  if exception.response_code == '403'
		    page = exception.page
		  else
		    raise # Some other error, re-raise
		  end
		end
		results_listings = craigslist_results_listings(page, min_price, max_price, query)
		all_craigslist_listings = scrape_craigslist_listings(results_listings, listing_base_url)
		return all_craigslist_listings
	end

	# Create a new CSVSaver and then pass it what we want to save.
	def save(results, file_name, args)
		CSVSaver.new(results, file_name, args)
	end

	# Save our parameters (GET variables) as session variables if they're set
	def save_session(params, session)
		session[:zip] = params[:zip] if params[:zip]
		session[:min_price] = params[:min_price].to_i if params[:min_price]
		session[:max_price] = params[:max_price].to_i if params[:max_price]
		session[:query] = params[:query].split(' ').join('+') if params[:query]
	end

	private

	# To be used in future apps, in case we want to change the user agent.
	def get_agent
		agent = Mechanize.new do |agent| 
			agent.user_agent_alias = 'Mac Safari'
			# Don't forget this rate limit!!
			agent.history_added = Proc.new { sleep 0.5 }
		end
	end

	# Method to find and return all of the results elements for a 
	# particular Craigslist search. There should be 100 per page.
	# Each of these listings will be scraped further later.
	def craigslist_results_listings(page, min_price, max_price, query)
		results_page = page.form_with(:id => 'searchform') do |search|
			search.query = query
			search.maxAsk = max_price
			search.minAsk = min_price
		end.submit
		results_page.search('.row')
	end

	# Takes an array of all of the Mechnize elements which are 
	# Craigslist listings, creates a new Listing Struct with them, scrapes
	# the relevant information (sans email, that's on another page), and
	# then returns an array with all of these Listing Structs.
	def scrape_craigslist_listings(results_listings, listing_base_url)
		all_info = []
		results_listings.each do |listing|
			listing_info = Listing.new
			listing_info[:name] = listing.search('.hdrlnk').inner_text
			url_temp = listing_base_url + listing.search('.pl').inner_html.match(/href=\"(.*?)\"/)[1]
			listing_info[:url] = "<a href=\"#{url_temp}\" target=\"_blank\">Listing URL</a>" 
			listing_info[:price] = listing.search('.price').inner_text
			listing_info[:location] = listing.search('.pnr').inner_text.match(/\((.*?)\)/)[1]
			all_info << listing_info
		end
		all_info
	end

	# To initiate the area page we need to enter in a zip code.
	# I'll use NYC by default.
	def search_by_zip(page, zip)
		page.form_with(:action => '/cgi-bin/findweather/getForecast') do |search|
			search.query = zip
		end.submit
	end

	# Since the main area page loads the 10-day forecast through JS 
	# we can't use it. Therefore, we want to use the calendar page
	# which shows us more info sans JS.
	def find_calendar_page(area_page)
		calendar_page = area_page.link_with(:href => /MonthlyCalendar/)
		calendar_page = calendar_page.click
	end

	# Now that we're on teh calendar page, let's scrape the info for it.
	# First getting the info for Today then the other forecast days.
	def forecast_info(calendar_page)
		all_forecasts = []
		scrape_info_today(calendar_page, all_forecasts)
		scrape_info_forecasts(calendar_page, all_forecasts)
		all_forecasts 
	end

	# WUNDERGROUND has a 'today' section which is slightly different
	# than the 'forecast' sections- we need special queries to get the 
	# required information here.
	def scrape_info_today(calendar_page, all_forecasts)
		forecast = Forecast.new	
		forecast[:month] = calendar_page.search('select.monthCal').inner_html.match(/selected value=\"(\d)\"/)[1]
		forecast[:day] = calendar_page.search('td.todayBorder').search('a.dateText').inner_text.strip
		forecast[:year] = calendar_page.search('select.yearCal').inner_html.match(/selected value=\"(.*?)\"/)[1]
		forecast[:classification] = calendar_page.search('td.todayBorder').search('td.show-for-large-up').inner_text.strip
		forecast[:temp_low] = calendar_page.search('td.todayBorder').search('td.highLow').inner_html.match(/\"low\">(.*?)</)[1]
		forecast[:temp_high] = calendar_page.search('td.todayBorder').search('td.highLow').inner_html.match(/\"high\">(.*?)</)[1]
		all_forecasts << forecast
	end

	# After scraping the 'today' class, let's get the remaining 9 days
	# which are seen in the td.forecast area.
	def scrape_info_forecasts(calendar_page, all_forecasts)
		# Go through each forecast td
		calendar_page.search('td.forecast').each do |day|
			forecast = Forecast.new	
			forecast[:month] = calendar_page.search('select.monthCal').inner_html.match(/selected value=\"(\d)\"/)[1]
			forecast[:day] = day.search('a.dateText').inner_text.strip
			forecast[:year] = calendar_page.search('select.yearCal').inner_html.match(/selected value=\"(.*?)\"/)[1]
			forecast[:classification] = day.search('td.show-for-large-up').inner_text.strip
			forecast[:temp_low] = day.search('td.highLow').inner_html.match(/\"low\">(.*?)</)[1]
			forecast[:temp_high] = day.search('td.highLow').inner_html.match(/\"high\">(.*?)</)[1]
			all_forecasts << forecast
		end
	end
end