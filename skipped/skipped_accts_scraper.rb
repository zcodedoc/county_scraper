require 'watir'
require 'nokogiri'
require 'httparty'
require 'pry'

require_relative 'create_csv'
#
# skipped_taxlots = Array.new
#
# f = File.open('SKIPPED_LOTs.csv', 'r')
#
# f.each_line {|line| skipped_taxlots << line.split("\r")[0] }

# @acct_numbers = []
#
# def insert_lot_number(num)
#   browser = Watir::Browser.new
#   browser.goto 'http://dial.deschutes.org/'
#   browser.text_field(id: 'value').set "#{num}"
#   browser.send_keys :return
#   # if browser.url.include?('Real/Index')
#   get_acct_numbers(browser.url, browser)
#   browser.quit
#   # else
#   #   @scraper_data << [num, nil, nil, nil, nil,'SKIPPED']
#   # end
# end
#
# def get_acct_numbers(url, window)
#   unparsed_page = HTTParty.get(url)
#   parsed_page = Nokogiri::HTML(unparsed_page)
#
#   parsed_page.css('tbody tr').each do |row|
#     unless row.css('td')[3].text.include?('USA') || row.css('td')[7].text.include?('Cancelled')
#       @acct_numbers << row.css('td')[2].text.split("\r\n ").each{|str| str.gsub!(/\s+/, '')}.delete_if{|el| el.length < 2}
#       # @acct_numbers.flatten!
#     end
#   end
#
#   # binding.pry
# end
#
# skipped_taxlots.each do |num|
#   # binding.pry
#   insert_lot_number(num)
# end

# csv_tool(['Account Number'], @acct_numbers)

#### scrape site w/acct number sites
skipped_accts = Array.new

f = File.open('scraped_acct_nums.csv', 'r')

f.each_line {|line| skipped_accts << line.split("\r")[0] }

# skipped_accts = [166256, 252552, 187686, 240222, 265272, 265853, 134973, 142771,135044,135041]
@scraper_data = []

def insert_acct_number(num)
  browser = Watir::Browser.new
  browser.goto 'http://dial.deschutes.org/'
  browser.text_field(id: 'value').set "#{num}"
  browser.send_keys :return
  # if browser.url.include?('Real/Index')
  scraper(browser.url, browser)
  browser.quit
  # else
  #   @scraper_data << [num, nil, nil, nil, nil,'SKIPPED']
  # end
end

def scraper(url, window)
  unparsed_page = HTTParty.get(url)
  parsed_page = Nokogiri::HTML(unparsed_page)
  acct_info = parsed_page.css('.uxAccountInformation').text.split("\r\n").delete_if(&:empty?)[1..-2]

  # these accts hv extra p tags in column of page
  # grab last p-tag & seperate info using 'Mailing To' text, get last el in arr
  addy_node = parsed_page.css('#uxReportLeftColumn p').last.text.split("Mailing To:").last
  ownership_addy = addy_node.strip.split("\r\n ").each{|str| str.gsub!(/\s+/, ' ')}.delete_if{|el| el.length < 2}[0..2]
  # binding.pry

  nodeset = nil
  p_tag_data = []

# puts url
  loop do
    nodeset = parsed_page.css('#uxReportMiddleColumn p.uxReportSectionHeader').last if nodeset.nil?
    # binding.pry
    # binding.pry
    nodeset = nodeset.next_element
    p_tag_data << nodeset.text.strip.split("\r\n").each{|str| str.gsub!(/\s+/, ' ')}.delete_if{|el| el.length < 2}
    # binding.pry
    break if nodeset.next_element.nil? #|| !nodeset.next_element.text.split("\r\n").any?{|str| str.match(/[A-Za-z]/)}
    #2nd conditonal checking 4 next nodeset text hving letters, not "" or "   "
  end

  #formatt assessment_info
   p_tag_data.flatten!
  unless p_tag_data.last.include?('Property Class')
    p_tag_data[-2].concat(p_tag_data.last)
    p_tag_data.pop
  end

  #  binding.pry
   assessment_info = p_tag_data
  # assessment_info = p_tag_data.flatten
  if assessment_info.length <= 3
    assessment_info.unshift(nil)
  elsif  assessment_info[0].include?('Assessor Property Description')
    assessment_info[1] += assessment_info[2]
    assessment_info.delete_at(2) #delete what was joined
    assessment_info.delete_at(0) #remove acct #
  end

  new_row = []
  (acct_info + assessment_info).each do |str|
    if !str.nil? && str.include?(':')
      key_value = str.strip.split(':')
      new_row << key_value[1] unless (key_value[0] == 'Account')
    else
      new_row << str
    end
  end

  # binding.pry


  new_row += ownership_addy unless ownership_addy.nil?
  @scraper_data << new_row

end

# binding.pry

skipped_accts[1..-1].each do |num| # binding.pry
  insert_acct_number(num)
end

headers = ['Taxlot', 'Property Address', 'Short Legal Description', 'Property Size',
'Property Additional Info', 'Name', 'Address', 'City, State, Zipcode']

csv_tool(headers, @scraper_data)

insert_acct_number('265853')
