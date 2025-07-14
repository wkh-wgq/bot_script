require_relative './lib/browser_automation/pokermon'
require 'json'

json_path = ARGV[0]
json_text = File.read(json_path)
source_data = JSON.parse(json_text)

data = source_data.map do |item|
  {
    email: item['email'],
    password: '1234qwer.',
    index: item['index'].to_i,
  }
end

result = data.map do |params|
  BrowserAutomation::Pokermon.draw_lot(params[:email], password: params[:password], index: params[:index])
end
