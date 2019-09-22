require 'csv'

def csv_tool(h = nil, data)
  # CSV.open('generated_desCo_skipped_accts.csv', 'wb') do |csv|
  CSV.open('scraped_data.csv', 'a+') do |csv|
    csv << h if !h.nil?
    data.each do |row|
      csv << row
    end
  end
end

# practice_data = [[" 1408000000500",
#   " **NO SITUS ADDRESS**",
#   nil,
#   " 316.20",
#   " 600 -- FORESTFOREST LAND POTENTIAL ADDITIONAL TAX LIABILITY",
#   "   FIRS HOLDINGS LLC",
#   "   PO BOX 99",
#   "   LYONS, OR 97358"],
#  ["1409000000100", nil, nil, nil, nil, "SKIPPED"],
#  [" 1409000000200",
#   " 71301 MCALLISTER RD, SISTERS, OR 97759",
#   " PP1992-46   Lot PARCEL 3 Block",
#   " 284.97",
#   " 600 -- FORESTFOREST LAND POTENTIAL ADDITIONAL TAX LIABILITY",
#   "   DAVID SCOTT GLYNN REVOCABLE TRUST",
#   "   3412 WASHINGTON ST",
#   "   SAN FRANCISCO, CA 94118"],
#  [" 1409000000201",
#   " 71271 MCALLISTER RD, SISTERS, OR 97759",
#   " PP1992-46   Lot PARCEL 2 Block",
#   " 244.52",
#   " 600 -- FORESTFOREST LAND POTENTIAL ADDITIONAL TAX LIABILITY",
#   "   MAX BOYER GLYNN REVOCABLE TRUST",
#   "   3412 WASHINGTON ST",
#   "   SAN FRANCISCO, CA 94118"],
#  [" 1409000000300",
#   " **NO SITUS ADDRESS**",
#   nil,
#   " 625.43 Property Class",
#   "   USA",
#   "   ",
#   "   , "]
# ]
#
# headers = ['Taxlot', 'Property Address', 'Short Legal Description', 'Property Size',
# 'Property Additional Info', 'Name', 'Address', 'City, State, Zipcode']
#
#
# csv_tool(headers, practice_data)
