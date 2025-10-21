require_relative '../lib/browser_automation/pokermon'
require 'json'

json_path = ARGV[0]
json_text = File.read(json_path)
source_data = JSON.parse(json_text)

data = source_data.map do |d|
  products = d['products'].map do |product|
    {
      link: product['link'],
      quantity: product['qty'].to_i
    }
  end
  {
    email: d['email'],
    password: '1234Asdf.',
    products: products
  }
end

result = BrowserAutomation::Pokermon.order(data)
puts "成功：#{result[:succ_result]}"
puts "失败：#{result[:fail_result]}"
puts "地址错误：#{result[:error_address_result]}"
puts "未执行：#{result[:unexecuted_emails]}"