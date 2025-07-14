module BrowserAutomation
  module Pokermon
    class ModifyProfileRunner < BaseRunner
      def initialize(email, password:)
        initialize_page(email.split(".").first)
        @email = email
        @login_retry_count = 0
      end

      def modify_profile
        go_home_page
        random_browse
        login
        modify_address
        human_delay
        modify_password
        "#{@email}->#{@mobile}"
      rescue Exception => e
        logger.error "用户(#{@email})修改信息失败: #{e.message}"
        false
      ensure
        close_page
      end

      def modify_password
        human_like_move_to_element(page.locator("text=パスワード変更"))
        human_like_click("text=パスワード変更")
        human_like_click("#current-password")
        sleep(rand(0.4..0.8))
        page.locator("#current-password").type("!QAZ2wsx", delay: rand(50..150))
        human_like_click("#new-password01")
        sleep(rand(0.4..0.8))
        page.locator("#new-password01").type("1234qwer.", delay: rand(50..150))
        sleep(rand(0.4..0.8))
        page.keyboard.press("Tab")
        sleep(rand(0.4..0.8))
        page.locator("#new-password02").type("1234qwer.", delay: rand(50..150))
        human_like_move_to_element(page.locator("text=更新する"))
        human_like_click("text=更新する")
        sleep(rand(4..6))
        logger.info "#{@email}-密码修改完成"
      end

      def modify_address
        human_like_click("text=会員情報変更")
        human_like_move_to_element(page.locator("#postal-code"))
        human_update_type("#postal-code", "1690075")
        sleep(rand(2..5))
        human_like_move_to_element(page.locator("#address-line1"))
        human_update_type("#address-line1", "2-14-6")
        page.locator("#address-line2").type("アライビル５階", delay: rand(50..150))
        human_like_move_to_element(page.locator("text=入力内容確認へ進む"))
        @mobile = page.input_value('input[name="dwfrm_profile_customer_phone"]')
        logger.info "账号: #{@email}->#{@mobile}"
        human_like_click("text=入力内容確認へ進む")
        sleep(rand(2..5))
        human_like_move_to_element(page.locator("text=登録する"))
        human_like_click("text=登録する")
        sleep(rand(2..5))
        human_like_click("text=マイページ")
        sleep(rand(2..5))
        logger.info "#{@email}-修改地址完成"
      end

      def human_update_type(selector, value)
        human_like_click(selector)
        9.times { page.keyboard.press("Backspace"); sleep(0.1) }
        page.locator(selector).type(value, delay: rand(50..150))
      end

      def login
        human_like_click("text=ログイン ／ 会員登録", wait_for_navigation: true)
        human_like_move_to_element(page.locator("#current-password"))
        human_like_click("#login-form-email")
        sleep(rand(0.5..1.2))
        # 输入帐号
        page.locator("#login-form-email").type(@email, delay: rand(50..200))
        sleep(rand(0.4..0.8))
        # 点击tab键
        page.keyboard.press("Tab")
        sleep(rand(0.4..0.8))
        # 输入密码
        page.locator("#current-password").type("!QAZ2wsx", delay: rand(50..200))
        sleep(rand(0.6..1.2))
        page.keyboard.press("Enter")
        sleep(rand(5..10))
        unless page.url == MY_URL
          raise "登陆失败！" if @login_retry_count >= 3
          @login_retry_count += 1
          login
        end
      end

      def random_browse
        block = -> do
          # 随机向下滚动
          human_like_scroll(scroll_times: (3..5), scorll_length: (300..600))
          # 向上滚动到页面顶部
          human_like_move_to_top
        end
        block.call
        human_like_click("text=新商品", wait_for_navigation: true)
        block.call
      end

      def human_delay
        sleep(rand(0.5..2.0))
      end
    end
  end
end
