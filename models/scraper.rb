# Contains the methods which are to be shared
# among all scraping-type classes.

class Scraper
	def initialize
		@agent = get_agent
	end

	# To be used in future apps, in case we want to change the user agent.
	# Also including our rate-limiter to prevent us from geting **ahem** blocked.
	def get_agent
		agent = Mechanize.new do |agent| 
			agent.user_agent_alias = 'Mac Safari'
			# Don't forget this rate limit!!
			agent.history_added = Proc.new { sleep 0.5 }
		end
	end
end