#!/usr/bin/env ruby

require 'typhoeus'
require 'nokogiri'
require 'open-uri'
require 'json'

url = "http://civil.ge/eng/article.php?id="

def get_latest_id
  page = Nokogiri::HTML(open('http://civil.ge/eng/'))
  uri = page.css('div#top2 a').first
  id = uri['href'].split('=')[1]
  id
end

# get end id
id = get_latest_id

#initiate hydra
hydra = Typhoeus::Hydra.hydra

request = ''

#build hydra queue
(1..id.to_i).map do |i|
  puts "Getting: #{url.to_s + i.to_s}"
  request = Typhoeus::Request.new("#{url.to_s + i.to_s}", followlocation: true)
  hydra.queue(request)
end

Typhoeus::Hydra.new(max_concurrency: 20)

request.on_complete do |response|
  if response.success?
    puts "Yay"
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
