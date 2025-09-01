require_relative './pokermon/base_runner'
require_relative './pokermon/login_base_runner'
require_relative './pokermon/draw_lot_runner'
require_relative './pokermon/modify_profile_runner'
require_relative './pokermon/modify_password_runner'
require_relative './pokermon/modify_address_runner'
require_relative './pokermon/order_runner'
require_relative './pokermon/register_runner'
require_relative './pokermon/lottery_won_pay_runner'
require_relative '../custom_error'

module BrowserAutomation
  module Pokermon
    # 发送注册邮件
    def self.send_register_email(email)
      Pokermon::RegisterRunner.new(email: email).send_email
    end

    # 根据注册链接完成注册
    def self.register(email, register_link, name:, jp_name:, birthday:, gender:, postal_code:, street_number:, password:, mobile:)
      birthday = birthday.to_date if birthday.is_a?(String)
      Pokermon::RegisterRunner.new(email: email).register(
        register_link: register_link,
        name: name,
        jp_name: jp_name,
        birthday: birthday,
        gender: gender,
        postal_code: postal_code,
        street_number: street_number,
        password: password,
        mobile: mobile
      )
    end

    def self.batch_login(data)
      succ_result = []
      fail_result = []
      data.each_with_index do |item, index|
        result = BrowserAutomation::Pokermon::LoginBaseRunner.new(
          item[:email], item[:password]
        ).run
        result ? succ_result << item[:email] : fail_result << item[:email]
        sleep(rand(180..480)) if index < data.size - 1
      end
      {
        succ_result: succ_result,
        fail_result: fail_result
      }
    end

    # 抽奖
    def self.draw_lot(data)
      succ_result = []
      fail_result = []
      data.each_with_index do |item, index|
        result = BrowserAutomation::Pokermon::DrawLotRunner.new(
          item[:email], password: item[:password]
        ).run
        result ? succ_result << item[:email] : fail_result << item[:email]
        sleep(rand(180..480)) if index < data.size - 1
      end
      {
        succ_result: succ_result,
        fail_result: fail_result
      }
    end

    # 下单
    # data: [{email:, password:, products: [{link:, quantity:}]}]
    def self.order(data)
      succ_result = []
      fail_result = []
      error_address_result = []
      data.each do |item|
        begin
          result = BrowserAutomation::Pokermon::OrderRunner.new(
            item[:email], password: item[:password], products: item[:products]
          ).run
          if result[:success]
            succ_result << { email: result[:email], order_no: result[:order_no] }
          elsif !result[:error_code].nil?
            error_address_result << result[:email]
          else
            fail_result << result[:email]
          end
        rescue Exception => e
          puts e
        end
      end
      {
        succ_result: succ_result,
        fail_result: fail_result,
        error_address_result: error_address_result
      }
    end

    def self.lottery_won_pay(emails)
      succ_result = []
      fail_result = []
      error_info_result = []
      emails.each do |email|
        result = BrowserAutomation::Pokermon::LotteryWonPayRunner.new(
          email, password: "1234Asdf."
        ).run
        if result[:success]
          succ_result << { email: result[:email], order_no: result[:order_no] }
        elsif !result[:error_code].nil?
          error_info_result << result[:email]
        else
          fail_result << result[:email]
        end
      end
      {
        succ_result: succ_result,
        fail_result: fail_result,
        error_info_result: error_info_result
      }
    end

    def self.modify_address(emails)
      succ_result = []
      fail_result = []
      emails.each do |email|
        result = BrowserAutomation::Pokermon::ModifyAddressRunner.new(
          email, password: "1234Asdf."
        ).run
        if result[:success]
          succ_result << { email: result[:email], mobile: result[:mobile] }
        else
          fail_result << result[:email]
        end
      end
      {
        succ_result: succ_result,
        fail_result: fail_result
      }
    end

    def self.modify_password(emails)
      succ_result = []
      fail_result = []
      emails.each do |email|
        result = BrowserAutomation::Pokermon::ModifyPasswordRunner.new(
          email, password: "1234Asdf."
        ).run
        if result[:success]
          succ_result << { email: result[:email] }
        else
          fail_result << result[:email]
        end
      end
      {
        succ_result: succ_result,
        fail_result: fail_result
      }
    end
  end # end module Pokermon
end # end module BrowseAutomation
