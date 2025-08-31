require_relative './lib/browser_automation/pokermon'
require 'json'

file_path = ARGV[0]
string_text = File.read(file_path).strip
emails = string_text.split(',')

data = emails.map do |email|
  {
    email: email,
    password: '1234Asdf.'
  }
end

result = BrowserAutomation::Pokermon.draw_lot(data)
puts "成功：#{result[:succ_result]}"
puts "失败：#{result[:fail_result]}"
