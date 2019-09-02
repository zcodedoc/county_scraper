require 'watir'
require 'nokogiri'
require 'httparty'
require 'pry'
require 'csv'

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

  # binding.pry

  if browser.url.include?('AccountID')
    # view HTML of page - aka page source
    # pass to nokogiri to parse
    scraper(browser.html, browser)
  else
    @scraper_data << [num, nil,'SKIPPED']
    browser.quit
  end
end

def scraper(html, window)
  # source = "view-source:" + url
  # unparsed_page = HTTParty.get(source)
  parsed_page = Nokogiri::HTML(html)
  # binding.pry

  #row data [parcel_id, acct_num, owner, mailing_addy, mailing_city+, 'JEFFERSON ', nil, nil, link-to-summary-report]
  new_row = []

  #get tax_lot/parcel_id
  new_row << parsed_page.css('#ctl00_ContentPlaceHolder1_lblMapNumber').text

  #get acct#,
  new_row << parsed_page.css('#ctl00_ContentPlaceHolder1_lblAccountNumber').text

  #get owner,
  new_row << parsed_page.css('#ctl00_ContentPlaceHolder1_lblOwner').text

  #get owner_mailing_addy,
  full_o_addy = parsed_page.css('#ctl00_ContentPlaceHolder1_lblMailingAddress').text

  broken_addy = full_o_addy.split(' ')
  city_idx = broken_addy.find_index(broken_addy.find{|str| str.include?(',')})

  # 1st pt of addy ~ 3 dots 2 leave out city
  new_row <<  broken_addy[0...city_idx].join(' ')

  # add city, state zip
  new_row <<  broken_addy[city_idx..-1].join(' ')

  # add coutny
  new_row << 'JEFFERSON'

  # adding nils 4 'Property Address', 'Property City, State Zip
  2.times {new_row << nil}

  # get link to 'summary report' which contians RMV & site addy (maybe)
  part_summary_url = parsed_page.css('#ctl00_ContentPlaceHolder1_lnkReportLink1').attr('href').value.split('ReportViewer')[1]
  full_summary_url = 'http://query.co.jefferson.or.us/AandTWebQuery/ReportViewer' + part_summary_url

  # push summary_url into arr, has RVM & legal descrp
  new_row << full_summary_url

  #add acct status
  new_row << parsed_page.css('#ctl00_ContentPlaceHolder1_lblAccountStatus').text
  # binding.pry

  @scraper_data << new_row

  #close browser
  window.quit
end

def csv_tool(h, data)
  # CSV.open('generated_desCo_skipped_accts.csv', 'wb') do |csv|
  CSV.open('generated_jeff_info.csv', 'wb') do |csv|
    csv << h
    data.each do |row|
      csv << row
    end
  end
end


# binding.pry
lot_numbs[1..-1].each do |parcel_id|
  insert_lot_number(parcel_id)
end

headers = ['Parcel ID', 'Account #', 'Last Name, First Name', 'Address', 'City, State Zip', 'Property County', 'Property Address', 'Property City, State Zip', 'RMV_Total', 'Additional Property Info']

csv_tool(headers, @scraper_data)
