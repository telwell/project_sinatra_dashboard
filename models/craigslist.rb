# Creating a CraigslistScraper class which will
# hold all of the methods related to scraping 
# Craigslist.

# Create Struct for our Craigslist listings
Listing = Struct.new(:name, :url, :email, :price, :location)

class CraigslistScraper < Scraper

	def initialize
		super
	end

	public

	# Search method for searching NYC craigslist for apartments
	# based on location, max, and min prices. Returns a results
	# array with all Listing Structs ready to
	# be sent to a CSV file.
	def search_craigslist(min_price, max_price, query)
		search_base_url = 'http://newyork.craigslist.org/search/aap'
		listing_base_url = 'http://newyork.craigslist.org'

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

	private

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
			url_temp = listing_url(listing_base_url, listing)
			listing_info[:url] = "<a href=\"#{url_temp}\" target=\"_blank\">Listing URL</a>" 
			listing_info[:price] = listing.search('.price').inner_text
			listing_info[:location] = listing_location(listing)
			all_info << listing_info
		end
		all_info
	end

	# Sometimes when the listing title is too long the URL and the 
	# location get screwed up. Because of this I've added these two
	# helper methods which will return nil if they don't find anything
	# and otherwise return the proper data. Fix for these long outliers.
	def listing_url(listing_base_url, listing)
		listing_url_match_data = listing.search('.pl').inner_html.match(/href=\"(.*?)\"/)
		listing_url_match_data ? listing_base_url + listing_url_match_data[1] : nil
	end

	def listing_location(listing)
		listing_location_match_data = listing.search('.pnr').inner_text.match(/\((.*?)\)/)
		listing_location_match_data ? listing_location_match_data[1] : nil

	end

end