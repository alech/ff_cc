#!/usr/bin/env ruby

require 'rubygems'
require 'sqlite3'
require 'creditcard'

MIN_START = 5
MIN_END   = 5

def open_websites_at(time, d)
    time_start = (time.to_i - MIN_START*60) * 10**6 # MIN_START minutes before
    time_end   = (time.to_i +   MIN_END*60) * 10**6 # MIN_END   minutes after
    places_file = d.sub('formhistory.sqlite', 'places.sqlite')
    begin
        places_db = SQLite3::Database.new(places_file)
        query = "SELECT url, title from moz_places where last_visit_date > #{time_start} AND last_visit_date < #{time_end}"
        places_rows = places_db.execute(query)
        puts " Open websites at about that time:"
        places_rows.each do |r|
            puts "   #{r[1]} - #{r[0]}"
        end
    rescue SQLite3::BusyException
        STDERR.puts " WARNING: Can not show open websites because Firefox is running."
    end
end

def possible_cscs_at(time, db)
    time_start = (time.to_i - MIN_START*60) * 10**6 # MIN_START minutes before
    time_end   = (time.to_i +   MIN_END*60) * 10**6 # MIN_END   minutes after
    query = "SELECT fieldname, value, firstUsed, lastUsed from moz_formhistory where lastUsed > #{time_start} AND lastUsed < #{time_end}"
    db.execute(query).select { |r| r[1].match(%r| \A \d{3} \z |xms) }.each do |r|
        time = Time.at(r[2].to_f / 10**6).strftime("%Y/%m/%d %H:%M:%S")
        puts "Possible Card Security Code found: "
        puts " #{r[1]}"
        puts " in form field #{r[0]}"
        puts " entered at #{time}" 
        puts
    end
end
path = File.expand_path("~")
path = path + (RUBY_PLATFORM == 'i386-mswin32' ? '/Anwendungsdaten/Mozilla/Firefox/Profiles/' : '/.mozilla/firefox/')

Dir.glob(path + '*/formhistory.sqlite') do |d|
    puts "Inspecting #{d}"
    db = SQLite3::Database.new(d)
    rows = db.execute("SELECT fieldname, value, firstUsed, lastUsed from moz_formhistory ORDER by firstUsed DESC")
    rows.select { |r| r[1].creditcard? && r[1].creditcard_type != 'unknown' }.each do |r|
        time      = Time.at(r[2].to_f / 10**6)
        time_last = Time.at(r[2].to_f / 10**6)
        puts "Possible credit card found: "
        puts " #{r[1].creditcard_type.capitalize} #{r[1]}"
        puts " in form field #{r[0]}"
        puts " first entered at #{time.strftime("%Y/%m/%d %H:%M:%S")}" 
        possible_cscs_at(time, db)
        open_websites_at(time, d)
        if time_last != time then
            puts " last entered at #{time_last.strftime("%Y/%m/%d %H:%M:%S")}"
            open_websites_at(time_last, d)
        end
        puts
    end
end

if RUBY_PLATFORM == 'i386-mswin32' then
    print "Press enter to exit"
    gets
end

