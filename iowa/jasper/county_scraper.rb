require 'watir'
require 'nokogiri'
# require 'httparty'
require 'pry'

require_relative 'create_csv'

@scraper_data = []

def get_county_tables(web, url)
  begin
    web.goto url
    #creating url for final page
    base_url = 'https://jasper.iowaassessors.com/'
    parsed_page = Nokogiri::HTML(web.html)

    # binding.pry
    if !parsed_page.css('div#navButtons a').empty?

      # url id different then finall webpages, conditional didn't work
      # final_page_url =  base_url + parsed_page.css('div#navButtons a').last.attr('href')
      # while web.url != final_page_url

      # potential fix
      final_page_img_text = parsed_page.css('div#navButtons a').last.css('img').attr('alt').value

      # binding.pry
      while final_page_img_text != "Previous Page " #check for this b/c there's NO nxt page
        scrape_apns(web.html)

        # find a tag w/img alt as next page
        a_tag = parsed_page.css('div#navButtons a').find{|node| node.css('img').attr('alt').value == "Next Page "}

        # binding.pry
        # create url & g2 next page
        next_page_url = base_url + a_tag.attr('href')
        get_county_tables(web, next_page_url)
      end

      # scrape last page from site
      scrape_apns(web.html)

      web.quit
    else
      authenticate_browser(web, url)
    end
  rescue Watir::Exception::UnknownObjectException
    # close window
    web.quit

    # open new window
    browser = Watir::Browser.new

    # binding.pry
    # send new window to be authenticated in
    authenticate_browser(browser, url)
  end
end

def authenticate_browser(webpage, cpu_addy)
  # binding.pry
  authenticate_site = "https://jasper.iowaassessors.com/showResSaleSearch.php"
  webpage.goto authenticate_site

  # click agree button for disclaimer form
  webpage.input(name: "agree").click

  sleep(2)
  # g2 url that creates tables of VL to view
  webpage.goto "https://jasper.iowaassessors.com/showVacantSaleSearch.php"

  #click search display results
  webpage.input(type: "submit").click
  # binding.pry
  get_county_tables(webpage, cpu_addy)
end

# def table_scraper(html, webpage)
#   parsed_page = Nokogiri::HTML(html)
#
#   # binding.pry
#
#   parsed_page.css('tbody tr')[1..-1].each do |tr|
#     # new_data = []
#
#     #parcel Number
#     num = tr.css('td a').text
#     @scraper_data << num

    # if tr.css('td').count == 11
    #   addy = tr.css('td:nth-child(5)').text.split(', ')
    #   # 'Property Address'
    #   new_data << addy.first
    #
    #   # 'Property City, State Zip'
    #   new_data << addy.last + ', OR N/A'
    #
    #   # 'Lot Area'
    #   new_data << tr.css('td:nth-child(9)').text
    #
    #   # 'Appraised Value'
    #   new_data << tr.css('td:nth-child(10)').text
    #
    #   webpage.link(text: num).click
    #   parcel_scraper(webpage.html, new_data)
    # else
    #   binding.pry
    #   webpage.link(text: num).click
    #   parcel_scraper(webpage.html, new_data)
    # end
    # binding.pry
#
#   end
# end

# link https://beacon.schneidercorp.com/Application.aspx?AppID=325&LayerID=3398&PageTypeID=2&PageID=2260
def parcel_scraper(parcel_html, data)
  parsed_page = Nokogiri::HTML(html)

  if data.count == 5
    binding.pry

  else
    binding.pry

  end

end

browser = Watir::Browser.new
authenticate_browser(browser, "https://jasper.iowaassessors.com/results.php?sort_options=0&sort=0&mode=vacantsale&sale_date1=&sale_date2=&sale_amt1=&sale_amt2=&recording1=&ilegal=&nutc1=21%2C34%2C137%2C153%2C321%2C334&ttlacre1=&ttlacre2=&location1=&class1=&maparea1=&dist1=&appraised1=&appraised2=")