require 'pry'

@info = %w(84714	Beryl	Iron County
84719	Brian Head	Iron County
84720	Pintura	Iron County
84720	Cedar City	Iron County
84720	Enoch	Iron County
84721	Cedar City	Iron County
84742	Kanarraville	Iron County
84753	Modena	Iron County
84756	Newcastle	Iron County
84760	Paragonah	Iron County
84761	Parowan	Iron County
84772	Summit	Iron County)


def extract_zipcodes
    @info.select{|el| el.match(/^[0-9]*$/)}
end

#testing
# zips = extract_zipcodes
# binding.pry