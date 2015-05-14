# DashboardHelper module

module DashboardHelper
	# Gets the default ZIP either from the session, 
	# params, or default constant.
	def whats_my_zip
		if session[:zip]
			session[:zip].to_i
		elsif params[:zip]
			params[:zip].to_i
		else
			DEFAULT_ZIP
		end
	end

	# If all of our session variables are set then yes, craigslist has 
	# the proper session variables.
	def craigslist_has_session?
		(session[:min_price] && session[:max_price] && session[:query]) ? true : false
	end

	# Save our parameters (GET variables) as session variables if they're set
	def save_session(params, session)
		session[:zip] = params[:zip] if params[:zip]
		session[:min_price] = params[:min_price].to_i if params[:min_price]
		session[:max_price] = params[:max_price].to_i if params[:max_price]
		session[:query] = params[:query].split(' ').join('+') if params[:query]
	end

end