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
        browsing_style = rand < 0.4 ? :fast : :slow
        scroll_behavior = lambda do
          times = browsing_style == :fast ? (2..4) : (3..7)
          length = browsing_style == :fast ? (200..400) : (300..800)
          human_like_scroll(scroll_times: times, scorll_length: length, delay: (0.3..0.8))
        end

        def gaze_pause
          sleep(rand(0.8..2.0))
          human_mouse_idle_move if rand < 0.4
        end

        def maybe_click(text, probability: 0.5)
          return unless rand < probability
          logger.info "点击(#{text})开始"
          human_like_click("text=#{text}", wait_for_navigation: true)
          logger.info "点击(#{text})结束"
          sleep(rand(1.0..2.5))
        rescue => _e
        end

        def browsing_block(scroll_behavior)
          scroll_behavior.call
          gaze_pause
          human_like_move_to_top if rand < 0.6
        end

        def maybe_hover_random_element
          selectors = %w[a img .item .product button .card .nav-item]
          selector = selectors.sample
          elements = page.query_selector_all(selector)
          return if elements.empty?
          element = elements.sample
          human_like_hover(element) if rand < 0.7
        rescue => _e
        end

        def maybe_hover_and_decide_click
          selectors = %w[a img .product .card button]
          selector = selectors.sample
          elements = page.query_selector_all(selector)
          return if elements.empty?
          element = elements.sample
          human_like_hover_and_decide_click(element, click_probability: rand(0.2..0.6))
        rescue => e
        end

        # 开始浏览
        human_mouse_idle_move if rand < 0.5
        browsing_block(scroll_behavior)
        maybe_hover_random_element if rand < 0.8
        # maybe_hover_and_decide_click if rand < 0.6

        categories = [
          { text: "新商品", weight: 0.5 },
          { text: "ポケモンから探す", weight: 0.5 },
          { text: "おすすめ特集", weight: 0.5 }
        ]

        categories.shuffle.each do |cat|
          next unless rand < cat[:weight]

          # maybe_hover_and_decide_click if rand < 0.5
          maybe_hover_random_element if rand < 0.5
          maybe_click(cat[:text], probability: cat[:weight])
          gaze_pause
          browsing_block(scroll_behavior)
          # maybe_hover_and_decide_click if rand < 0.4
          maybe_hover_random_element if rand < 0.4

          if rand < 0.3
            page.go_back rescue nil
            sleep(rand(0.8..1.5))
            human_mouse_idle_move if rand < 0.3
          end
        end

        case rand
        when 0.0..0.3 then human_like_move_to_top
        when 0.3..0.6 then scroll_behavior.call
        else human_mouse_idle_move
        end

        sleep(rand(1.0..3.0))
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

