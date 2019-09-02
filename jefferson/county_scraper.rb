require 'watir'
require 'nokogiri'
require 'httparty'
require 'pry'

# property lookups:
# list from: https://landgrid.com
# jefferson: http://199.48.41.18/AandTWebQuery/MainQueryPage.aspx?QueryMode=&Query=
# -click on Map & TaxLot link on left
# lane: http://apps.lanecounty.org/PropertyAccountInformation/#
# elmore: http://idahoparcels.us:8080/gm3/desktop/elmore.html#on=sketch/default;scalebar_feet/scalebar_feet;parcels/parcels;parcels1/parcels1;boundry/boundry;bing/roads&loc=0.29858214173896974;-12881402.949012272;5324187.540158878
#
# public records: https://publicrecords.netronline.com/
lot_numbs = Array.new

f = File.open('test-parcel-ids.csv', 'r')

f.each_line {|line| lot_numbs << line.split("\r")[0] }
# url = ''

@scraper_data = []

def insert_lot_number(num)
  browser = Watir::Browser.new
  browser.goto 'http://query.co.jefferson.or.us/AandTWebQuery/ExternalLogin.aspx'

  #no button on page, used input tag, so find tag w/name & tell 2 click
  browser.input(:name => 'ctl00$ContentPlaceHolder1$btnContinue').click

  link = browser.link text: 'Map & Taxlot'

  # click if check if exits
  link.click if link.exist?

  # input number in form field
  browser.text_field(id: 'ctl00_ContentPlaceHolder1_WuctlQueryMapAndTaxlot1_WuctlMapAndTaxlot1_txtMapAndTaxlot').set "#{num}"
  browser.send_keys :return

  binding.pry

  if browser.url.include?('Real/Index')
    scraper(browser.url, browser)
  else
    @scraper_data << [num, nil, nil, nil, nil,'SKIPPED']
    browser.quit
  end
end

# binding.pry
lot_numbs[1..-1].each do |parcel_id|
  insert_lot_number(parcel_id)
end

# def scrape_list
#   url = '/us/or/jefferson/warm-springs#b=none&t=list'
#   unparsed_page = HTTParty.get(url)
#   parsed_page = Nokogiri::HTML(unparsed_page)
#   binding.pry
#   parsed_page.css('#pjax-container #waterfall').each do |node|
#
#   end
#
# end

# scrape_list
