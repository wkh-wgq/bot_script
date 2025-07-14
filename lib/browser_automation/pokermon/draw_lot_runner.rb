module BrowserAutomation
  module Pokermon
    class DrawLotRunner < BaseRunner
      # 抽奖页面的链接
      LOTTERY_LINK = "https://www.pokemoncenter-online.com/lottery/landing-page.html"

      def initialize(email:, password:, index:)
        initialize_page(email.split(".").first)
        @login_retry_count = 0
        @email = email
        @password = password
        @index = index.to_i
      end

      def run
        go_home_page
        %w[random_browse login go_draw_lot_page draw_lot].each do |method|
          send(:execute_with_log, method)
        end
        logger.info "用户(#{@email})抽签完成，等待抽签结果"
        true
      rescue Exception => _e
        logger.error "用户(#{@email})抽签流程异常结束"
        false
      ensure
        close_page
      end

      def login
        human_like_click("text=ログイン ／ 会員登録", wait_for_navigation: true)
        human_like_click("#login-form-email")
        # 输入帐号
        page.locator("#login-form-email").type(@email, delay: rand(50..200))
        human_delay(0.4, 0.8)
        # 点击tab键
        page.keyboard.press("Tab")
        human_delay(0.4, 0.8)
        # 输入密码
        page.locator("#current-password").type(@password, delay: rand(50..200))
        human_delay(0.6, 1.2)
        page.keyboard.press("Enter")
        human_delay(5, 10)
        unless page.url == MY_URL
          raise "登陆失败！" if @login_retry_count >= 3
          @login_retry_count += 1
          login
        end
      end

      def go_draw_lot_page
        page.goto(LOTTERY_LINK, waitUntil: "domcontentloaded")
      end

      def queue_up
        return if page.title != QUEUE_UP_TITLE
        logger.info "用户(#{@email})开始排队"
        while (page.wait_for_load_state(state: "load"); page.title == QUEUE_UP_TITLE)
          sleep 5
        end
        # while !page.locator("#buttonConfirmRedirect").visible?
        #   sleep 5
        # end
        logger.info "用户(#{@email})排队完成"
        human_delay(4.0, 8.0)
        # 点击进入网站按钮
        # page.locator("#buttonConfirmRedirect").click
        # logger.info "用户(#{@email})进入网站"
      end

      # 抽奖
      def draw_lot
        human_delay(3.0, 5.0)
        human_like_click("text=抽選応募")
        human_delay(1.0, 3.0)
        human_like_click("#step3Btn")
        human_delay(5.0, 8.0)
        lis = page.locator("ul.comOrderList > li")
        raise "抽奖失败！" if lis.count == 0
        lis.count.times do |i|
          li = lis.nth(i)
          status = li.locator(".ttl").text_content
          logger.debug "第#{i + 1}个抽奖商品，状态为(#{status})"
          next if status == "受付完了"
          return if status == "受付終了"
          human_like_move(scorll_length: ((400 * i)..(450 * i))) if i > 0
          human_delay
          human_like_move_to_element(li.locator("text=詳しく見る"))
          human_like_click_of_element(li.locator("text=詳しく見る"))
          radio_lis = li.locator("ul.radioList > li")
          radio_element = radio_lis.nth(@index - 1).locator("p.radio label")
          human_like_move_to_element(radio_element)
          human_like_click_of_element(radio_element)
          human_like_move_to_element(li.get_by_label("応募要項に同意する"))
          human_like_click_of_element(li.get_by_label("応募要項に同意する"))
          human_like_click_of_element(li.locator("a.popup-modal.on"))
          human_like_click("#applyBtn")
          human_delay(6.0, 8.0)
          if li.locator(".ttl").text_content == "受付完了"
            logger.info "用户(#{@email})抽奖(#{i + 1})成功"
          else
            raise "用户(#{@email})抽奖(#{i + 1})失败!"
          end
        end
      end

      def execute_with_log(method)
        logger.debug "用户(#{@email})抽奖-(#{method})流程开始"
        send(method)
        logger.debug "用户(#{@email})抽奖-(#{method})流程结束"
      rescue Exception => e
        logger.error "用户(#{@email})抽奖-(#{method})流程(#{page.url})异常：#{e.message}"
        raise e
      end
    end # end class DrawLotRunner
  end # end module Pokermon
end # end module BroserAutomation
