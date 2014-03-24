#!/usr/bin/env ruby

require 'typhoeus'
require 'nokogiri'
require 'open-uri'
require 'json'

url = "https://www.hr.gov.ge/eng/vacancy/jobs/georgia/"

def get_latest_id
  page = Nokogiri::HTML(open('https://www.hr.gov.ge/eng/'))
  id = page.css('td#vac_ldate').first['onclick'].split("'")[1].split("/").last
  id
end

def logger(type, status, date=Time.now)
  file = "logs/"
  File.open(file, "wa") do |f| 
    f << "#{type}"
    f.save
  end
end

# get end id
start_id = 903 
end_id = get_latest_id


#initiate hydra
hydra = Typhoeus::Hydra.new(max_concurrency: 20)

request = ''

#build hydra queue
(start_id.to_i..end_id.to_i).map do |i|
  puts "Getting: #{url.to_s + i.to_s}"
  request = Typhoeus::Request.new("#{url.to_s + i.to_s}", followlocation: true)
  hydra.queue(request)
end

request.on_complete do |response|
  if response.success?
    # put success callback here
  elsif response.timed_out?
    # aw hell no
    log("got a time out")
  elsif response.code == 0
    # Could not get an http response, something's wrong.
    log(response.return_message)
  else
    # Received a non-successful http response.
    log("HTTP request failed: " + response.code.to_s)
  end
end

hydra.run
