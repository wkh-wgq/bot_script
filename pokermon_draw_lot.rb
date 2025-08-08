require_relative './lib/browser_automation/pokermon'
require 'json'

json_path = ARGV[0]
json_text = File.read(json_path)
source_data = JSON.parse(json_text)

data = source_data.map do |email|
  {
    email: email,
    password: '1234qwer.'
  }
end

result = BrowserAutomation::Pokermon.draw_lot(data)
puts "成功：#{result[:succ_result]}"
puts "失败：#{result[:fail_result]}"
