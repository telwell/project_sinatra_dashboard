# Creates the scraper class
require 'mechanize'

# Create struct for our weather results
Forecast = Struct.new(:day, :month, :year, :temp_low, :temp_high, :classification)

class Scraper
	def initialize
		@agent = get_agent
	end

	def search(zip = 10030)
		page = @agent.get('http://wunderground.com') do |page|
			area_page = search_by_zip(page, zip)
			calendar_page = find_calendar_page(area_page)
			forecast_info(calendar_page)
		end
	end

	private

	def get_agent
		agent = Mechanize.new { |agent| agent.user_agent_alias = 'Mac Safari' }
	end

	def search_by_zip(page, zip)
		page.form_with(:action => '/cgi-bin/findweather/getForecast') do |search|
			search.query = zip
		end.submit
	end

	def find_calendar_page(area_page)
		calendar_page = area_page.link_with(:href => /MonthlyCalendar/)
		calendar_page = calendar_page.click
	end

	def forecast_info(calendar_page)
		month = calendar_page.search('select.monthCal').inner_html.match(/selected value=\"(\d)\"/)[1]
		day = calendar_page.search('td.todayBorder').search('a.dateText').inner_text.strip
		year = calendar_page.search('select.yearCal').inner_html.match(/selected value=\"(.*?)\"/)[1]
		classification = calendar_page.search('td.todayBorder').search('td.show-for-large-up').inner_text.strip
		temp_low = calendar_page.search('td.todayBorder').search('td.highLow').inner_html.match(/\"low\">(.*?)</)[1]
		temp_high = calendar_page.search('td.todayBorder').search('td.highLow').inner_html.match(/\"high\">(.*?)</)[1] 
		binding.pry
	end
end