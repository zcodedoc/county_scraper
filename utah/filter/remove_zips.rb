require_relative 'get_zips'
require 'pry'
require 'csv'

zips = extract_zipcodes.uniq

csv = CSV.read('Filter-List.csv', headers: :first_row, return_headers: true)
csv.delete_if do |row|
  # binding.pry
  zips.include?(row.field('Zip').split('-').first) unless row.header_row?
end


CSV.open("Filter-List.csv","wb") do |csv_out|
    # csv.by_row!
    csv.each{ |row| csv_out << row }
end

#filter code minic
# https://www.ruby-forum.com/t/csv-delete-an-entry/242928/3
