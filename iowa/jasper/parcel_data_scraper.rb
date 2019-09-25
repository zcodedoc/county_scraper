require 'watir'
require 'nokogiri'
require 'pry'
require 'csv'

require_relative 'create_csv'
# create a list of only APNs - ONCE
# csv = CSV.read('scraped_apns.csv', headers: :first_row, return_headers: true)
# lot_numbs = Array.new
# csv.each {|row| lot_numbs << [row.field('APN')] unless row.header_row? }
# csv_tool(nil, lot_numbs)

# csv = CSV.read('Apns.csv')
# binding.pry
@scraper_data = []
@co_keywords = ['LLC', 'LLLP', 'LP', 'LTD', 'INC', 'CORP', 'COMPANY', 'DEPT', 'CITY', 'COUNCIL', 'TRUST', 'ESTATE', 'IRA', 'ASSOCIATES', 'ASSOCIATION', 'PARTNERS', 'PARTNERSHIP', 'COUNTY', 'VILLAGE', 'BANK', 'FOUNDATION', 'CLUB', 'STEWARDSHIP', 'DIST', 'TR', 'CO', 'DBA', 'MANAGEMENT']

# binding.pry
def open_page(web)
  # g2 page 2 search for parcel data - Jasper County
  web.goto "https://beacon.schneidercorp.com/Application.aspx?AppID=325&LayerID=3398&PageTypeID=2&PageID=2260"

  # authentiation via JS, so pausing browser to authentiation
  sleep(2)
end

def insert_lot_number(parcel_id, portal)
  begin
    # input number in Parcel ID Search form field
    portal.text_field(id: 'ctlBodyPane_ctl05_ctl01_txtParcelID').set "#{parcel_id}"

    # hit enter, involk JS
    portal.send_keys :return

    # scrape paracel data
    parcel_scraper(portal.html, parcel_id)
  rescue Watir::Exception::UnknownObjectException
    # close window
    portal.quit

    # open new window
    browser = Watir::Browser.new
    
    # open another browser & reauthenticate
    open_page(browser)

    # pry after opening in case need to authenticate w/browser server
    # prove not a robot
    binding.pry
    # go scrape data that errored
    insert_lot_number(parcel_id, browser)
  end
end

def parcel_scraper(html, id)
  parsed_page = Nokogiri::HTML(html)

  new_row = [id, 'JASPER']

  # unless there are NO tables on the page parse it
  # catching no result pages
  unless parsed_page.css('table').empty?
    # Summary table has property info, pulling tr w/
    summary_rows = parsed_page.css('#ctlBodyPane_ctl00_mSection tr')
    prop_addy_row = nil
    summary_rows.each do |tr|
        prop_addy_row = tr if tr.css('td').find {|td| td.text.strip == "Property Address"} != nil
    end


    # Property addy & Property City, State Zip
    if prop_addy_row.css('span').text != 'N/A'
        prop_addy = prop_addy_row.css('td span')[0].children.map {|node| node.text.strip unless node.text.strip.empty?}
        new_row << prop_addy.first
        new_row = formated_cit_st_zip( prop_addy.last, new_row)
    else
        new_row << 'ADDRESS UNKNOWN'
        new_row << 'N/A, IA N/A'
    end

        # Short Legal Description
    prop_descrip_node = nil
    summary_rows.each do |tr|
        tr.css('td').each {|td| prop_descrip_node = td.next_element if td.children.text.strip == "Brief Tax Description" }
    end

    if prop_descrip_node != nil
        new_row << prop_descrip_node.css('span').text
    else
        new_row << 'N/A'
    end

    # owner table has owner name & mailing addy
    owner_table = parsed_page.css('#ctlBodyPane_ctl01_mSection #ctlBodyPane_ctl01_ctl01_lstDeed')
    owner_mail_table = parsed_page.css('#ctlBodyPane_ctl01_mSection #ctlBodyPane_ctl01_ctl01_lstMailing span')

    # want the 2nd set of data, 1st is header info
    # Owner name
    # capture return of owner_info_setup, since added data in method
    new_row = owner_info_setup(owner_table.css('tr'), new_row, owner_mail_table)

    # Property Size
    prop_size_row = parsed_page.css('#ctlBodyPane_ctl03_mSection .tabular-data-two-column tr').last
    new_row << prop_size_row.css('td span').first.text

    # Market Value
    prop_value_tds = parsed_page.css('#ctlBodyPane_ctl10_mSection .double-total-line .value-column')

    new_row << prop_value_tds.first.text

    # Tag
    new_row << '20190923 - IA - Jasper Cty'
  else
    binding.pry
    new_row << 'NO DATA - CHECK RESULTS'
  end
  @scraper_data << new_row
  # binding.pry

  if @scraper_data.length.even?
    # headers = ['APN', 'JASPER', 'Property Address', 'Property City, State Zip', 'Short Legal Description', 'Note', 'Type', 'Company', 'Last Name', 'First Name', 'Address', 'City, State Zip', 'Property Size',	'Market Value', 'Tag']
    # I.E: Enew_row =["02.14.302.023", "107 RAILROAD ST", "BAXTER IA 50028", "RAILROAD HEIGHTS LOT 9", "Owner count: 2, has a DBA", "Individual", nil, "Kunkel", "Daniel G & Colette J", "PO Box 481", "Baxter IA 50028", "0.06", "$4,140", "20190923 - IA - Jasper Cty"]
    # csv_tool(headers, @scraper_data)

    # w/out header-row
    csv_tool(nil, @scraper_data)
    @scraper_data.clear
  end
end
#testing

def dba_note(data)
  note = data.pop
  data << note + ', has a DBA'
  data
end

# arr = ALL rrows in first column table
def owner_info_setup(arr, new_csv_row, mail_arr)
  # arr contains all td's
  mailing_addy = mail_arr.first.children[1..-1].map(&:text).delete_if(&:empty?)
  # site has 2 rows for 1 owner, header & owner info
  if arr.count > 2
    # binding.pry
    # skip header row
    owners = arr.css("td")[1..-1].map do |td|
        a_tag_data = td.css("a").map(&:text).delete_if(&:empty?)
        # binding.pry
        # avoiding tds w/br tags, they return [] for a_tag_data
        # only want to enter if ther are NO a tags
        if a_tag_data.empty? && !td.children.map(&:name).include?('br')
          # if no a tags, target span class
          td.css("span").map(&:text).delete_if(&:empty?)
        else
          a_tag_data
        end
      # end.delete_if{|arr| arr == []}.join(' | ')
    end.delete_if(&:empty?)
    binding.pry
    # pull first el out of each array
    owners.map!(&:shift)

    new_csv_row = multi_owner_parser(owners, new_csv_row)
    # add mailing owner mailing address
    new_csv_row << mailing_addy[-2]
    # formate mailing city, state zip
    new_csv_row = formated_cit_st_zip(mailing_addy[-1], new_csv_row)
  else
    # get owner name & addy potntially
    owner_info = arr.last.css('td')[0].children.map do |node|
      node.text.strip unless node.text.strip.empty?
    end.compact!

    #note
    new_csv_row << "Owner count: 1"
    # if co is found & updated csv_row
    result_arr = find_companies([owner_info[0]], new_csv_row)
    # input type & single owner in arr/co info into csv_row
    new_csv_row = add_to_csv_row( result_arr[0], result_arr[1], [owner_info[0]])
    # add mailing owner mailing address
    new_csv_row << mailing_addy[-2]
    # formate mailing city, state zip
    new_csv_row = formated_cit_st_zip(mailing_addy[-1], new_csv_row)
  end
  # binding.pry
  new_csv_row
end

def multi_owner_parser(names_arr, row_info)
  #note
  row_info << "Owner count: #{names_arr.count}"

  results = find_companies(names_arr, row_info)

  # sending back return vale of #add_to_csv_row & 1st owner addy
  add_to_csv_row(results.first, results.last, names_arr)
end

def find_companies(name_arr, row_info)
  results = name_arr.find do |name|
      cap_name = name.upcase
      row_info = dba_note(row_info) if cap_name.include?('DBA')

      @co_keywords.any? {|word|cap_name.split(' ').include?(word)} unless  cap_name.include?('DBA')
    end
  [results, row_info]
end

def add_to_csv_row(comapny, csv_row, owner_names_arr)
  if comapny != nil
    csv_row << 'Company'
    # Company name
    csv_row << comapny
    # space for 'Last Name' 'First Name' (2 columns)
    2.times {csv_row << nil}
  else
    csv_row << 'Individual'
    # space for Company name column
    csv_row << nil

    # handle multiple owner names
    if owner_names_arr.count == 2
      csv_row = multi_owner_name(owner_names_arr, csv_row)
    else
      split_name = owner_names_arr.first.split(', ')
      # Owner Last name
      csv_row << split_name.first
      # Owner First name
      csv_row << split_name.last
    end
  end
  csv_row
end

def multi_owner_name(names_arr, row_info)
  if !names_arr.find{|str| str.upcase.include?('DBA')}.nil?
    o1_name = names_arr[0].split(', ')
    # add owner 1 last name
    row_info <<  o1_name.first
    # add formated name
    row_info <<  o1_name.last
    return row_info
  end

  # work with 1st 2 names in array, check 2 see if husband/wife
  # owner fullnames in arrays
  o1_name = names_arr[0].split(', ')
  o2_name = names_arr[1].split(', ')
  # owner last names
  o1_lname = o1_name.shift
  o2_lname = o2_name.shift
  # formte name for same & diff last names
  same_lname =  o1_name.join(' ') + ' & ' + o2_name.join(' ')
  diff_lname =  o1_name.join(' ') + ' & ' + o2_lname + ' ' +  o2_name.join(' ')
  # select name
  name = (o1_lname == o2_lname) ? same_lname : diff_lname
  # add owner 1 last name
  row_info <<  o1_lname
  # add formated name
  row_info <<  name
  row_info
end

def formated_cit_st_zip(mail_info, csv_row)
  # find words with exactly TWO capital letters
  state = mail_info.match(/\b[A-Z]{2}\b/)[0]
  # need to add comma in to seperate city & stat
  # delete anything that's NOT a word or number
  parsed_info = mail_info.split(/\b/).delete_if{|txt| !txt.match?(/[a-zA-Z]|\d/)}
  # get index of state
  idx = parsed_info.index(state)
  # find all text before state value
  before_state_txt = parsed_info[0...idx].join(' ') + ', '
  # find all text after state value
  state_and_after_txt = parsed_info[idx..-1].join(' ')
  # join info together again
  updated_cit_st_zip = before_state_txt + state_and_after_txt
  # add owner city, state zip
  csv_row << updated_cit_st_zip
  csv_row
end

# main link https://beacon.schneidercorp.com/Application.aspx?AppID=325&LayerID=3398&PageTypeID=2&PageID=2260

browser = Watir::Browser.new
open_page(browser)
CSV.read('Apns.csv').each.with_index(1) do |row, i|
  # iterating on CSV hv an arr w/info, why say row index 0
  # insert_lot_number(row[0], browser)
  insert_lot_number(row, browser)
  # follow index numbers
  puts i
  #add time for browser to site
  num = [0,1,3].sample
  sleep num
  # go back to search page
  browser.goto "https://beacon.schneidercorp.com/Application.aspx?AppID=325&LayerID=3398&PageTypeID=2&PageID=2260"
end
