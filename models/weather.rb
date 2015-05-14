# Creating a WeatherScraper class which
# will hold all of the methods directly
# related to scraping info for the weather.

# Create struct for our weather results
Forecast = Struct.new(:day, :month, :year, :temp_low, :temp_high, :classification)

class WeatherScraper < Scraper
	
	def initialize
		super
	end

	public

	# Initiate searching WUNDERGROUND. Return an array full of 
	# FORECAST Structs for the 10-day forecast.
	def search_weather(zip)
		page = @agent.get('http://wunderground.com') do |page|
			area_page = search_by_zip(page, zip)
			calendar_page = find_calendar_page(area_page)
			return forecast_info(calendar_page)
		end
	end

	private

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