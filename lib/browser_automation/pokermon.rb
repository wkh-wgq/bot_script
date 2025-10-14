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
      unexecuted_emails = data.map{|d| d[:email]}
      each_with_sleep(data) do |item|
        result = BrowserAutomation::Pokermon::LoginBaseRunner.new(
          item[:email], item[:password]
        ).run
        result ? succ_result << item[:email] : fail_result << item[:email]
        unexecuted_emails.delete(item[:email])
        result
      end
      {
        succ_result: succ_result,
        fail_result: fail_result.join(","),
        unexecuted_emails: unexecuted_emails.join(",")
      }
    end

    # 抽奖
    def self.draw_lot(data)
      succ_result = []
      fail_result = []
      unexecuted_emails = data.map{|d| d[:email]}
      each_with_sleep(data) do |item|
        result = BrowserAutomation::Pokermon::DrawLotRunner.new(
          item[:email], password: item[:password]
        ).run
        result ? succ_result << item[:email] : fail_result << item[:email]
        unexecuted_emails.delete(item[:email])
        result
      end
      {
        succ_result: succ_result,
        fail_result: fail_result.join(","),
        unexecuted_emails: unexecuted_emails.join(",")
      }
    end

    # 下单
    # data: [{email:, password:, products: [{link:, quantity:}]}]
    def self.order(data)
      succ_result = []
      fail_result = []
      error_address_result = []
      unexecuted_emails = data.map{|d| d[:email]}
      each_with_sleep(data) do |item|
        begin
          result = BrowserAutomation::Pokermon::OrderRunner.new(
            item[:email], password: item[:password], products: item[:products]
          ).run
          unexecuted_emails.delete(item[:email])
          if result[:success]
            succ_result << { email: result[:email], order_no: result[:order_no] }
            true
          elsif !result[:error_code].nil?
            error_address_result << result[:email]
            true
          else
            fail_result << result[:email]
            false
          end
        rescue Exception => e
          puts e
          false
        end
      end
      {
        succ_result: succ_result,
        fail_result: fail_result.join(","),
        error_address_result: error_address_result,
        unexecuted_emails: unexecuted_emails.join(",")
      }
    end

    def self.lottery_won_pay(emails)
      succ_result = []
      fail_result = []
      error_info_result = []
      unexecuted_emails = emails.dup
      each_with_sleep(emails) do |email|
        result = BrowserAutomation::Pokermon::LotteryWonPayRunner.new(
          email, password: "1234Asdf."
        ).run
        unexecuted_emails.delete(email)
        if result[:success]
          succ_result << { email: result[:email], order_no: result[:order_no] }
          true
        elsif !result[:error_code].nil?
          error_info_result << { email: result[:email], error_code: result[:error_code] }
          true
        else
          fail_result << result[:email]
          false
        end
      end
      {
        succ_result: succ_result,
        fail_result: fail_result.join(","),
        error_info_result: error_info_result,
        unexecuted_emails: unexecuted_emails.join(",")
      }
    end

    def self.modify_address(emails)
      succ_result = []
      fail_result = []
      unexecuted_emails = emails.dup
      each_with_sleep(emails) do |email|
        result = BrowserAutomation::Pokermon::ModifyAddressRunner.new(
          email, password: "1234Asdf."
        ).run
        unexecuted_emails.delete(email)
        if result[:success]
          succ_result << { email: result[:email], mobile: result[:mobile] }
        else
          fail_result << result[:email]
        end
        result[:success]
      end
      {
        succ_result: succ_result,
        fail_result: fail_result.join(","),
        unexecuted_emails: unexecuted_emails.join(",")
      }
    end

    def self.modify_password(emails)
      succ_result = []
      fail_result = []
      unexecuted_emails = emails.dup
      each_with_sleep(emails) do |email|
        result = BrowserAutomation::Pokermon::ModifyPasswordRunner.new(
          email, password: "1234Asdf."
        ).run
        unexecuted_emails.delete(email)
        if result[:success]
          succ_result << { email: result[:email] }
        else
          fail_result << result[:email]
        end
        result[:success]
      end
      {
        succ_result: succ_result,
        fail_result: fail_result.join(","),
        unexecuted_emails: unexecuted_emails.join(",")
      }
    end

    def self.each_with_sleep(data, &block)
      config = BrowserAutomation::BaseRunner.load_config
      consecutive_failures = 0
      data.each_with_index do |item, index|
        is_success = yield(item)
        puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] INFO - 执行结果：#{is_success}，当前进度：#{index + 1}/#{data.size}"
        if is_success
          consecutive_failures = 0
          sleep(rand(config["min_interval_minutes"]..config["max_interval_minutes"])) if index < data.size - 1
        else
          consecutive_failures += 1
          return puts("[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] INFO - 连续失败#{consecutive_failures}次，停止执行") if consecutive_failures >= config["max_consecutive_failures"]
          sleep(rand(config["min_failure_delay_minutes"]..config["max_failure_delay_minutes"])) if index < data.size - 1
        end
      end
    end
  end # end module Pokermon
end # end module BrowseAutomation
