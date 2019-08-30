require 'watir'
require 'nokogiri'
require 'httparty'
require 'pry'

require_relative 'create_csv'

lot_numbs = Array.new

f = File.open('Deschutes_VACANT_LAND.csv', 'r')

f.each_line {|line| lot_numbs << line.split("\r")[0] }
# url = ''

@scraper_data = []

def insert_lot_number(num)
  browser = Watir::Browser.new
  browser.goto 'http://dial.deschutes.org/'
  browser.text_field(id: 'value').set "#{num}"
  browser.send_keys :return
  # binding.pry
  if browser.url.include?('Real/Index')
    scraper(browser.url, browser)
  else
    @scraper_data << [num, nil, nil, nil, nil,'SKIPPED']
    browser.quit
  end
end

def scraper(url, window)
  unparsed_page = HTTParty.get(url)
  parsed_page = Nokogiri::HTML(unparsed_page)
  acct_info = parsed_page.css('.uxAccountInformation').text.split("\r\n").delete_if(&:empty?)[1..-2]
  # => ["    Mailing Name: USA",
  #  "    Map and Taxlot: 1407000000100 ",
  #  "    Account: 150295",
  #  "        Situs Address: **NO SITUS ADDRESS**",
  # "    Tax Status: Non-Assessable"]

  txt = parsed_page.css('#uxReportLeftColumn p:nth-child(6)').text
  noko_txt = (txt != '') ? txt : parsed_page.css('#uxReportLeftColumn p:nth-child(4)').text
  ownership_addy = noko_txt.strip.split("\r\n ").each{|str| str.gsub!(/\s+/, ' ')}.delete_if{|el| el.length < 2}[2..-3]

  # assessment_info = parsed_page.css('#uxReportMiddleColumn p:nth-child(4)').text.strip.split("\r\n ").each{|str| str.gsub!(/\s+/, ' ')}.delete_if{|el| el.length < 2}
  # assessment_info = ''

  nodeset = nil
  p_tag_data = []
  loop do
    nodeset = parsed_page.css('#uxReportMiddleColumn p.uxReportSectionHeader').last if nodeset.nil?
    # binding.pry
    nodeset = nodeset.next_element
    p_tag_data << nodeset.text.strip.split("\r\n").each{|str| str.gsub!(/\s+/, ' ')}.delete_if{|el| el.length < 2}
    # binding.pry
    break if nodeset.next_element.nil?
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

  #close browser
  window.quit
end

# individual test
# insert_lot_number('1408000000100')
# insert_lot_number('1408000000202')
# insert_lot_number('1408000000200')
# insert_lot_number(' 140909B001900') # length 5

# array spread via csv files ~> 0..50, 51..150, 151..350, 351..500,501..1000
# 1001..1500, 1501..2000, 2001..2500, 2501..3000, 3001..3500, 3501..4000
lot_numbs[4501..5000].each do |num|
  # binding.pry
  insert_lot_number(num)
end

headers = ['Taxlot', 'Property Address', 'Short Legal Description', 'Property Size',
'Property Additional Info', 'Name', 'Address', 'City, State, Zipcode']

csv_tool(headers, @scraper_data)
