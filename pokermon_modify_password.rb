require_relative './lib/browser_automation/pokermon'

file_path = ARGV[0]
string_text = File.read(file_path).strip
emails = string_text.split(',')

result = BrowserAutomation::Pokermon.modify_password(emails)
puts "成功：#{result[:succ_result]}"
puts "失败：#{result[:fail_result]}"