module BrowserAutomation
  module Pokermon
    class LoginBaseRunner < BaseRunner
      attr_reader :email
      def initialize(email, password)
        initialize_page(email.split(".").first)
        @email = email
        @password = password
        @login_retry_count = 0
      end

      def login
        human_like_move_to_top
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
        if page.url == MY_URL
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
