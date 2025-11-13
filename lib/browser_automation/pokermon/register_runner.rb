module BrowserAutomation
  module Pokermon
    class RegisterRunner < BaseRunner
      attr_reader :email, :options
      def initialize(email, options)
        initialize_page(email.split(".").first)
        @email = email
        @options = options
      end

      def run
        @retry_count = 0
        # 发送注册邮件
        click_register
        unless page.url.include? "www.pokemoncenter-online.com/temporary-customer-complete"
          logger.info "账号(#{email})发送注册邮失败"
          return false
        end
        logger.info "账号(#{email})发送注册邮成功，等待邮件..."
        human_mouse_idle_move
        sleep(rand(5..10))
        human_mouse_idle_move
        # 调接口查询邮件的注册链接
        link = get_register_link
        # 进行注册操作
        register(link)
      rescue Exception => e
        logger.error "账号(#{email})注册失败:#{e.message}"
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

      def register(register_link)
        page.goto register_link
        human_delay
        human_like_move_to_element(page.locator("#registration-form-birthdayyear"))
        # 填写姓名
        human_like_type_with_click("#registration-form-fname", options["name"])
        if rand < 0.5
          page.keyboard.press("Tab")
        else
          human_like_click("#registration-form-kana")
        end
        human_like_type("#registration-form-kana", options["jp_name"])
        human_like_move_to_element(page.locator("#registration-form-birthdayday"))
        birthday = options["birthday"].to_date
        # 选择生日
        page.locator("#registration-form-birthdayyear").select_option(value: birthday.year.to_s)
        human_delay
        page.locator("#registration-form-birthdaymonth").select_option(value: format("%02d", birthday.month))
        human_delay
        page.locator("#registration-form-birthdayday").select_option(value: format("%02d", birthday.day))
        human_delay

        human_like_move_to_element(page.locator('[name="dwfrm_profile_customer_gender"]'))
        # 选择性别
        page.locator('[name="dwfrm_profile_customer_gender"]').select_option(value: options["gender"] == "男" ? "1" : "2")
        human_delay

        # 填写地址
        human_like_move_to_element(page.locator("#registration-form-postcode"))
        human_like_type_with_click("#registration-form-postcode", options["postal_code"])

        human_like_move_to_element(page.locator("#registration-form-address-line1"))

        # 填写邮编后页面会触发事件，所以需要等待，否则会把填写的house_number清空
        human_delay(2.0, 5.0)
        page.wait_for_selector("#registration-form-address-line1:enabled")
        human_like_type_with_click("#registration-form-address-line1", options["street_number"])
        human_delay
        # human_like_click("#registration-form-address-line2")
        # page.locator("#registration-form-address-line2").type(params[:address], delay: rand(50..150))
        # human_delay

        human_like_move_to_element(page.locator('[name="dwfrm_profile_customer_phone"]'))
        # 填写手机号
        human_like_type_with_click('[name="dwfrm_profile_customer_phone"]', options["mobile"])
        human_delay

        human_like_move_to_element(page.locator('[name="dwfrm_profile_login_passwordconfirm"]'))
        # 输入密码
        human_like_type_with_click('[name="dwfrm_profile_login_password"]', options["password"])
        page.keyboard.press("Tab")
        human_like_type('[name="dwfrm_profile_login_passwordconfirm"]', options["password"])

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
          logger.info "账号(#{email})注册完毕！"
          true
        else
          logger.error "账号(#{email})注册失败(#{page.url})"
          false
        end
      end

      def get_register_link
        url = "#{MAILBOX_SERVER_HOST}/pokemon/register_link.json?email=#{email}"
        max_retries = 5

        max_retries.times do |attempt|
          begin
            logger.info "第#{attempt + 1}次获取注册链接"
            res = RestClient::Request.execute(
              method: :get, 
              url: url, 
              headers: {"accept" => "application/json", "Content-Type" => "application/json"}
            )
            json = JSON.parse(res)
            return json["captcha"] if json["captcha"] && !json["captcha"].empty?
          rescue Exception => e
            logger.error "获取注册链接失败：#{e.message}"
          end
          
          if attempt < max_retries - 1
            logger.warn("第 #{attempt + 1} 次获取注册链接失败，准备重试...")
            sleep(rand(3..7))
          end
        end
        logger.error "获取注册链接失败！"
        raise "获取注册链接失败！"
      end
    end # end class RegisterRunner
  end # end module Pokermon
end # end module BrowserAutomation
