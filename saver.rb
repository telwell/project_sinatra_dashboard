# Create class to save CSV files

class CSVSaver
	def initialize(results, file_name, args)
		save(results, file_name, args)
	end

	def save(results, file_name, args)
		CSV.open(file_name, 'w') do |csv|
      results.each do |result|
      	buffer = []
      	args.each {|arg| buffer << result[arg] }
      	csv << buffer
      end
    end
    true
	end
end