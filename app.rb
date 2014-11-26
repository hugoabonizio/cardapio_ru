require 'open-uri'
require 'nokogiri'
require 'sinatra'
require 'json'

class String
  def remove_r
    buffer = ''
    each_char do |c|
      buffer << c if c.ord != 160
    end
    buffer
  end
end

def raw_data
  days = []
  doc = Nokogiri::HTML(open("http://www.uel.br/ru/pages/cardapio.php"))
  doc.css('tbody > tr').each do |tr|
    tr.css('td').each do |td|
      days << td.text
    end
  end
  days
end

def parse(raw)
  lines = raw.split("\n").map { |l| l.split(' ') }
  util = []
  lines.each do |line|
    unless line.empty? or (line.first.size == 1 and line.first.ord == 160)
      util << line.map { |i| i.remove_r }
    end
  end
  util
end

data = raw_data.map { |day| parse(day) }
json_data = Hash.new
json_data[:RU] = []
data.each do |day|
  unless day.size == 1
    json_data[:RU] << {
      dia_semana: day[0].first,
      dia_mes: day[0][1],
      cardapio: day[1..day.size].map { |i| i.join ' ' }
    }
  end
end

set :bind, '0.0.0.0'
set :protection, expect: [:json_csrf]

p json_data.to_json

get '/' do
  content_type :text, 'charset' => 'utf-8'
  json_data.to_json
end