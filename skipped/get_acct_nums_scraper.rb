require 'watir'
require 'nokogiri'
require 'httparty'
require 'pry'
require 'csv'

skipped_taxlots = Array.new

f = File.open('SKIPPED_LOTs.csv', 'r')

f.each_line {|line| skipped_taxlots << line.split("\r")[0] }

@acct_numbers = []

def insert_lot_number(num)
  browser = Watir::Browser.new
  browser.goto 'http://dial.deschutes.org/'
  browser.text_field(id: 'value').set "#{num}"
  browser.send_keys :return

  get_acct_numbers(browser.url, browser)
  browser.quit
end

def get_acct_numbers(url, window)
  unparsed_page = HTTParty.get(url)
  parsed_page = Nokogiri::HTML(unparsed_page)

  parsed_page.css('tbody tr').each do |row|
    unless row.css('td')[3].text.include?('USA') || row.css('td')[7].text.include?('Cancelled')
      @acct_numbers << row.css('td')[2].text.split("\r\n ").each{|str| str.gsub!(/\s+/, '')}.delete_if{|el| el.length < 2}
      # @acct_numbers.flatten!
    end
  end

  # binding.pry
end

skipped_taxlots.each do |num|
  # binding.pry
  insert_lot_number(num)
end


def csv_tool(h, data)
  CSV.open('scraped_accts_nums.csv', 'wb') do |csv|
    csv << h
    data.each do |row|
      csv << row
    end
  end
end

csv_tool(['Account Number'], @acct_numbers)
