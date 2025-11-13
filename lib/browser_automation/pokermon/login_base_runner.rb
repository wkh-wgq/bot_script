require 'json'
require 'rest-client'
module BrowserAutomation
  module Pokermon
    class LoginBaseRunner < BaseRunner

      MAILBOX_SERVER_HOST = ENV.fetch("MAILBOX_SERVER_HOST", "https://auto.usingnow.tech/")
      CAPTCHA_PAGE_URL = "www.pokemoncenter-online.com/login-mfa"

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
        human_like_type_email_and_password
        human_like_click("#form1Button")
        sleep(rand(7..10))
        # 如果没有到填写验证码的页面，就解析错误信息
        if page.url.include? CAPTCHA_PAGE_URL
          logger.info "发送验证码，等待邮件..."
          # 填写验证码
          fill_in_captcha
        else
          need_retry = extract_login_error
          if need_retry
            logger.info "有错误信息，登陆重试"
            @login_retry_count += 1
            login
          end
        end
        sleep(rand(3..5)) if page.url.include? CAPTCHA_PAGE_URL
        if page.url.include? CAPTCHA_PAGE_URL
          logger.info "验证码页面无法跳转，进行重试"
          @login_retry_count += 1
          login
        end
        if page.url.include? "www.pokemoncenter-online.com/re-agree-to-terms"
          human_like_move_to_element(page.locator("#terms"))
          human_like_click("#terms")
          human_like_click("text=次へ進む")
          sleep(rand(7..10))
        end
        return logger.info "登陆成功!" if page.url.include? MY_URL
        sleep(rand(3..5))
        return logger.info "登陆成功!" if page.url.include? MY_URL
        raise "登陆失败！" if @login_retry_count >= 2
        logger.info "确认页面无法跳转，进行重试"
        @login_retry_count += 1
        login
      end

      def get_login_captcha
        # url = "#{MAILBOX_SERVER_HOST}/pokemon/captcha.json?email=#{email}"
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

      # 填写验证码
      def fill_in_captcha
        human_mouse_idle_move
        sleep(rand(5..10))
        human_mouse_idle_move
        # 调接口查询邮件的验证码
        captcha = get_login_captcha
        page.locator("#authCode").type(captcha, delay: rand(50..200))
        human_like_click("#rememberMe")
        human_like_click("#authBtn")
        sleep(rand(7..10))
      end

      # 提取登陆的错误信息
      def extract_login_error
        logger.info "解析错误信息"
        @extract_login_error_retry_count = 0
        begin
          @extract_login_error_retry_count += 1
          error_message = page.locator(".comErrorBox").inner_text
        rescue Exception => _e
          sleep(rand(3..5))
          return false if page.url.include? CAPTCHA_PAGE_URL
          return true if @extract_login_error_retry_count > 2
          retry
        end
        logger.error "登陆报错：#{error_message}"
        if error_message.include?("メールアドレスまたはパスワードが一致しませんでした")
          @password = "1234qwer."
        elsif error_message.include?("アカウントが一時的にロックされました。しばらく経ってから、ログインをお試しください")
          raise "账号被锁定！"
        end
        true
      end

      # 输入邮箱和密码
      def human_like_type_email_and_password
        # 输入帐号
        human_like_type_with_click("#login-form-email", email)
        sleep(rand(0.4..0.8))
        if rand < 0.5
          # 点击tab键
          page.keyboard.press("Tab")
        else
          human_like_click("#current-password")
        end
        sleep(rand(0.4..0.8))
        if rand < 0.2
          # 输入错误密码，然后删除，重新输入正确密码
          wrong_password = @password.dup
          wrong_password[rand(0..(wrong_password.size - 1))] = ''
          human_like_type(wrong_password)
          wrong_password.length.times do
            page.keyboard.press("Backspace")
            sleep rand(0.05..0.18)
          end
        end
        # 输入密码
        human_like_type(@password)
        sleep(rand(0.6..1.2))
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
