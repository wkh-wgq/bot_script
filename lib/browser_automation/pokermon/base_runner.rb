require_relative '../base_runner'
module BrowserAutomation
  module Pokermon
    class BaseRunner < BrowserAutomation::BaseRunner
      # 排队的页面title
      QUEUE_UP_TITLE = "Queue-it"
      # 限制访问的页面title
      RESTRICTED_ACCESS_TITLE = "Restricted access"
      # 首页url
      ROOT_URL = "https://www.pokemoncenter-online.com"
      # 我的页面
      MY_URL = "https://www.pokemoncenter-online.com/mypage/"

      def go_home_page
        page.goto(ROOT_URL, waitUntil: "domcontentloaded")
      rescue => _e
        raise "当前网络异常！"
      end

      # 校验网络是否被限制访问
      def validate_network
        raise "网络被限制访问！" if page.title == RESTRICTED_ACCESS_TITLE
      end

      # 清空购物车
      def clear_cart
        human_like_click('a[href="/cart/"]', wait_for_navigation: true)
        while page.locator("ul.cart-list > li a.remove-product").count > 0
          element = page.locator("ul.cart-list > li a.remove-product").first
          element.click
          sleep(rand(1.0..2.0))
        end
        human_delay
        human_like_click("text=マイページ", wait_for_navigation: true)
        human_delay
      end

      def random_browse
        random_scroll
        if rand < 0.2
          human_like_click("text=新商品", wait_for_navigation: true)
          random_scroll
        end
      end

      def random_scroll
        human_mouse_idle_move
        human_like_scroll(scroll_times: (2..4), scorll_length: (0..800), delay: (0.5..1.0))
        human_like_scroll(scroll_times: (2..4), scorll_length: (-400..400), delay: (0.5..1.0))
        human_like_move_to_top
      end

      def queue_up
        return if page.title != QUEUE_UP_TITLE
        logger.info "开始排队"
        while true
          begin
            page.wait_for_load_state(state: "load")
            break if page.title != QUEUE_UP_TITLE
            sleep 5
          rescue Playwright::Error => _e
            sleep 2
          end
        end
        # while !page.locator("#buttonConfirmRedirect").visible?
        #   sleep 5
        # end
        logger.info "排队完成"
        sleep rand(4.0..8.0)
        # 点击进入网站按钮
        # page.locator("#buttonConfirmRedirect").click
        # logger.info "用户(#{account_no})进入网站"
      end

      def validate_address
        human_like_click("text=会員情報変更")
        human_like_move_to_element(page.locator("#address-level2"))
        if !page.locator("#address-line2").input_value.include?("アライビル５階") || !page.locator("#address-level2").input_value.include?("新宿区高田馬場")
          raise CustomError.new("收获地址错误", :incorrect_address)
        end
        human_like_move_to_top
        human_like_click("text=マイページ")
      end
    end
  end
end

