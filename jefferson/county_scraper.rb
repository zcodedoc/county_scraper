require 'nokogiri'
require 'httparty'
require 'pry'

# property lookups:
# jefferson: http://199.48.41.18/AandTWebQuery/MainQueryPage.aspx?QueryMode=&Query=
# -click on Map & TaxLot link on left
# lane: http://apps.lanecounty.org/PropertyAccountInformation/#
# elmore: http://idahoparcels.us:8080/gm3/desktop/elmore.html#on=sketch/default;scalebar_feet/scalebar_feet;parcels/parcels;parcels1/parcels1;boundry/boundry;bing/roads&loc=0.29858214173896974;-12881402.949012272;5324187.540158878
#
# public records: https://publicrecords.netronline.com/

def scrape_list
  url = 'https://landgrid.com/us/or/jefferson/warm-springs#b=none&t=list'
  unparsed_page = HTTParty.get(url)
  parsed_page = Nokogiri::HTML(unparsed_page)
  binding.pry
  parsed_page.css('#pjax-container #waterfall').each do |node|

  end

end

scrape_list
