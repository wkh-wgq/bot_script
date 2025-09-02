require 'json'
require 'rest-client'
module BrowserAutomation
  module Pokermon
    class LoginBaseRunner < BaseRunner

      MAILBOX_SERVER_HOST = ENV.fetch("MAILBOX_SERVER_HOST", "https://auto.usingnow.tech/")

      attr_reader :email
      def initialize(email, password)
        initialize_page(email.split(".").first)
        @email = email
        @password = password
        @login_retry_count = 0
      end

      def run
        go_home_page
        %w[random_browse login].each do |method|
          send(:execute_with_log, method)
        end
        logger.info "用户(#{email})登陆完成"
        true
      rescue Exception => _e
        logger.error "用户(#{email})登陆流程异常结束"
        false
      ensure
        close_page
      end

      def login
        human_like_move_to_top
        # 鼠标随机移动
        human_mouse_idle_move
        human_like_click("text=ログイン ／ 会員登録", wait_for_navigation: true)
        human_like_move_to_element(page.locator("#form1Button"))
        human_like_click("#login-form-email")
        # 输入帐号
        page.locator("#login-form-email").type(email, delay: rand(50..200))
        sleep(rand(0.4..0.8))
        # 点击tab键
        page.keyboard.press("Tab")
        sleep(rand(0.4..0.8))
        # 输入密码
        page.locator("#current-password").type(@password, delay: rand(50..200))
        sleep(rand(0.6..1.2))
        page.keyboard.press("Enter")
        sleep(rand(7..10))
        if page.url.include? "https://www.pokemoncenter-online.com/login-mfa"
          logger.info "发送验证码，等待邮件..."
          sleep(rand(15..20))
          # 调接口查询邮件的验证码
          captcha = get_login_captcha
          page.locator("#authCode").type(captcha, delay: rand(50..200))
          human_like_click("#rememberMe")
          human_like_click("#authBtn")
          sleep(rand(5..7))
        end

        if page.url.include? MY_URL
          logger.info "登陆成功!"
        else
          logger.error "登陆报错：#{page.locator(".comErrorBox").inner_text}"
          if page.locator(".comErrorBox").inner_text.include?("メールアドレスまたはパスワードが一致しませんでした")
            @password = "1234qwer."
          end
          raise "登陆失败！" if @login_retry_count >= 2
          @login_retry_count += 1
          login
        end
      end

      def get_login_captcha
        url = "#{MAILBOX_SERVER_HOST}/captcha/pokemon.json?email=#{email}"
        max_retries = 5

        max_retries.times do |attempt|
          begin
            logger.info "第#{attempt + 1}次获取验证码"
            res = RestClient::Request.execute(
              method: :get, 
              url: url, 
              headers: {"accept" => "application/json", "Content-Type" => "application/json"}
            )
            json = JSON.parse(res)
            return json["captcha"] if json["captcha"] && !json["captcha"].empty?
          rescue Exception => e
            logger.error "获取验证码失败：#{e.message}"
          end
          
          if attempt < max_retries - 1
            logger.warn("第 #{attempt + 1} 次获取验证码失败，准备重试...")
            sleep(rand(3..7))
          end
        end
        logger.error "获取登陆验证码失败！"
        raise "获取登陆验证码失败！"
      end

      def execute_with_log(method)
        logger.debug "用户(#{email})-(#{method})流程开始"
        send(method)
        logger.debug "用户(#{email})-(#{method})流程结束"
      rescue Exception => e
        logger.error "用户(#{email})-(#{method})流程(#{page.url})异常：#{e.message}"
        logger.error e
        raise e
      end
    end # end class LoginBaseRunner
  end # end module Pokermon
end # end module BrowserAutomation
