# Create class to save CSV files

class CSVSaver
	def initialize(results)
		save(results)
	end

	def save(results)
		CSV.open('csv_file.csv', 'w') do |csv|
      results.each do |result|
      	buffer = []
      	args = [:month, :day, :year, :temp_low, :temp_high, :classification]
      	args.each {|arg| buffer << result[arg] }
      	csv << buffer
      end
    end
    true
	end
end