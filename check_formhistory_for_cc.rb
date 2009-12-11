#!/usr/bin/env ruby

require 'rubygems'
require 'sqlite3'
require 'creditcard'

Dir.glob(File.expand_path("~") + "/.mozilla/firefox/*/formhistory.sqlite") do |d|
    db = SQLite3::Database.new(d)
    rows = db.execute("SELECT fieldname, value, firstUsed from moz_formhistory ORDER by firstUsed DESC")
    rows.select { |r| r[1].creditcard? && r[1].creditcard_type != 'unknown' }.each do |r|
        time = Time.at(r[2].to_f / 10**6).strftime("%Y/%m/%d %H:%M:%S")
        puts "Possible credit card found: "
        puts " #{r[1].creditcard_type.capitalize} #{r[1]}"
        puts " in form field #{r[0]}"
        puts " entered at #{time}" 
        puts
    end
end
