module BrowserAutomation
  module Pokermon
    class ModifyProfileRunner < LoginBaseRunner
      MODIFY_PASSWORD = "1234Asdf."

      def initialize(email, password:)
        super(email, password)
      end

      def modify_profile
        logger.info "用户(#{email})开始修改密码和地址信息"
        go_home_page
        random_browse
        login
        modify_address
        human_delay
        modify_password
        { success: true, email: email, mobile: @mobile }
      rescue Exception => e
        logger.error "用户(#{email})修改信息失败: #{e.message}"
        { success: false, email: email }
      ensure
        close_page
      end

      def modify_password
        if @password == MODIFY_PASSWORD
          return logger.warn "#{email}-密码无误，跳过修改操作"
        end
        human_like_move_to_element(page.locator("text=パスワード変更"))
        human_like_click("text=パスワード変更")
        human_like_click("#current-password")
        human_delay(0.4, 0.8)
        page.locator("#current-password").type(@password, delay: rand(50..150))
        human_like_click("#new-password01")
        human_delay(0.4, 0.8)
        page.locator("#new-password01").type(MODIFY_PASSWORD, delay: rand(50..150))
        human_delay(0.4, 0.8)
        page.keyboard.press("Tab")
        human_delay(0.4, 0.8)
        page.locator("#new-password02").type(MODIFY_PASSWORD, delay: rand(50..150))
        human_like_move_to_element(page.locator("text=更新する"))
        human_like_click("text=更新する")
        human_delay(4, 6)
        raise "修改密码失败" if page.url != "https://www.pokemoncenter-online.com/regist-complete/"
        logger.info "#{email}-修改密码完成"
      end

      def modify_address
        human_like_click("text=会員情報変更")
        if page.locator("#address-line2").input_value.include?("アライビル５階") && page.locator("#address-level2").input_value.include?("新宿区高田馬場")
          return logger.warn "#{email}-地址无误，跳过修改操作"
        end
        modify_postal_code
        if !page.locator("#address-level2").input_value.include?("新宿区高田馬場")
          modify_postal_code
        end
        human_delay
        human_update_type("#address-line2", "アライビル５階")
        human_like_move_to_element(page.locator("text=入力内容確認へ進む"))
        @mobile = page.input_value('input[name="dwfrm_profile_customer_phone"]')
        logger.info "账号: #{email}->#{@mobile}"
        human_like_click("text=入力内容確認へ進む")
        human_delay(2, 5)
        human_like_move_to_element(page.locator("text=登録する"))
        human_like_click("text=登録する")
        human_delay(3, 5)
        raise "修改地址失败" if page.url != "https://www.pokemoncenter-online.com/regist-complete/"
        logger.info "#{email}-修改地址完成"
        human_like_click("text=マイページ")
        human_delay(2, 5)
      end

      def modify_postal_code
        human_like_move_to_element(page.locator("#postal-code"))
        human_update_type("#postal-code", "1690075")
        human_delay(2, 5)
        human_like_move_to_element(page.locator("#address-line1"))
        human_update_type("#address-line1", "2-14-6")
      end

      def human_update_type(selector, value)
        element = page.locator(selector)
        human_like_click_of_element(element)
        element.input_value.size.times { page.keyboard.press("Backspace"); sleep(0.1) }
        page.locator(selector).type(value, delay: rand(50..150))
      end
    end # end class ModifyProfileRunner
  end # end module Pokermon
end # end module BrowserAutomation
