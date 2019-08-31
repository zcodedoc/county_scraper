require 'pry'
require 'csv'

zips = %w(97701 97702 97707 97708 97709 97759 97712 97756 97739).uniq!

csv = CSV.read('Filter-List_OR.csv', headers: :first_row, return_headers: true)
# csv.by_row!
csv.delete_if do |row|
  # binding.pry
  zips.include?(row.field('Zipcode').split('-').first) unless row.header_row?
end

CSV.open("Filter-List_OR.csv","wb") do |csv_out|
    # csv.by_row!
    csv.each{ |row| csv_out << row }
end

#filter code minic
# https://www.ruby-forum.com/t/csv-delete-an-entry/242928/3
