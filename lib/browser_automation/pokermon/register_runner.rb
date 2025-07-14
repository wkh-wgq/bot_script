module BrowserAutomation
  module Pokermon
    class RegisterRunner < BaseRunner
      attr_reader :email
      def initialize(email:)
        initialize_page("visitor")
        @email = email
      end

      # 发送注册链接的邮件
      def send_email
        @retry_count = 0
        click_register
        if page.url == "https://www.pokemoncenter-online.com/temporary-customer-complete/"
          logger.info "账号(#{email})发送注册邮完成"
          true
        else
          false
        end
      rescue Exception => e
        logger.error "账号(#{email})发送注册邮件失败:#{e.message}"
        false
      ensure
        close_page
      end

      # 发送注册链接
      def click_register
        page.goto(ROOT_URL)
        human_like_click("text=ログイン ／ 会員登録", wait_for_navigation: true)
        page.locator('[name="dwfrm_profile_confirmationEmail_email"]').type(email, delay: rand(100..300))
        human_like_click("#form2Button", wait_for_navigation: true)
        human_delay(4.0, 6.0)
        human_like_click("#send-confirmation-email", wait_for_navigation: true)
        human_delay(4.0, 6.0)
      rescue Exception => e
        raise e if @retry_count >= 3
        @retry_count += 1
        retry
      end

      def register(register_link:, name:, jp_name:, birthday:, gender:, postal_code:, street_number:, password:, mobile:)
        page.goto register_link
        human_delay
        human_like_move_to_element(page.locator("#registration-form-birthdayyear"))
        # 填写姓名
        human_like_click("#registration-form-fname")
        page.locator("#registration-form-fname").type(name, delay: rand(50..150))
        page.keyboard.press("Tab")
        page.locator("#registration-form-kana").type(jp_name, delay: rand(50..150))
        human_like_move_to_element(page.locator("#registration-form-birthdayday"))
        # 选择生日
        page.locator("#registration-form-birthdayyear").select_option(value: birthday.year.to_s)
        human_delay
        page.locator("#registration-form-birthdaymonth").select_option(value: format("%02d", birthday.month))
        human_delay
        page.locator("#registration-form-birthdayday").select_option(value: format("%02d", birthday.day))
        human_delay

        human_like_move_to_element(page.locator('[name="dwfrm_profile_customer_gender"]'))
        # 选择性别
        page.locator('[name="dwfrm_profile_customer_gender"]').select_option(value: gender == "男" ? "1" : "2")
        human_delay

        # 填写地址
        human_like_move_to_element(page.locator("#registration-form-postcode"))
        human_like_click("#registration-form-postcode")
        page.locator("#registration-form-postcode").type(postal_code, delay: rand(50..150))

        human_like_move_to_element(page.locator("#registration-form-address-line1"))

        # 填写邮编后页面会触发事件，所以需要等待，否则会把填写的house_number清空
        human_delay(2.0, 5.0)
        page.wait_for_selector("#registration-form-address-line1:enabled")
        # human_like_click("#registration-form-address-line1")
        page.locator("#registration-form-address-line1").type(street_number, delay: rand(50..150))
        human_delay
        # human_like_click("#registration-form-address-line2")
        # page.locator("#registration-form-address-line2").type(params[:address], delay: rand(50..150))
        # human_delay

        human_like_move_to_element(page.locator('[name="dwfrm_profile_customer_phone"]'))
        # 填写手机号
        human_like_click('[name="dwfrm_profile_customer_phone"]')
        page.locator('[name="dwfrm_profile_customer_phone"]').type(mobile, delay: rand(50..150))
        human_delay

        human_like_move_to_element(page.locator('[name="dwfrm_profile_login_passwordconfirm"]'))
        # 输入密码
        human_like_click('[name="dwfrm_profile_login_password"]')
        page.locator('[name="dwfrm_profile_login_password"]').type(password, delay: rand(50..150))
        page.keyboard.press("Tab")
        page.locator('[name="dwfrm_profile_login_passwordconfirm"]').type(password, delay: rand(50..150))

        human_like_click("text=受け取らない")

        human_delay

        human_like_move_to_element(page.locator("#terms"))
        # 同意条款
        page.locator("#terms").check
        human_delay
        page.locator("#privacyPolicy").check

        sleep 5
        human_like_click("#registration_button")

        # 等待注册完毕
        human_delay(6.0, 10.0)

        human_like_move_to_bottom

        human_like_click("text=登録する")

        human_delay(6.0, 10.0)

        if page.url == "https://www.pokemoncenter-online.com/new-customer-complete/"
          logger.info "(#{email})注册完毕！"
          true
        else
          false
        end
      rescue Exception => e
        logger.error "账号(#{email})注册失败:#{e.message}"
        logger.error e
        false
      ensure
        close_page
      end
    end # end class RegisterRunner
  end # end module Pokermon
end # end module BrowserAutomation
