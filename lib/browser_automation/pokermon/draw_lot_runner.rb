module BrowserAutomation
  module Pokermon
    class DrawLotRunner < LoginBaseRunner
      # 抽奖页面的链接
      LOTTERY_LINK = "https://www.pokemoncenter-online.com/lottery/landing-page.html"

      def initialize(email, password:)
        super(email, password)
        logger.info "用户(#{email})开始抽奖流程"
      end

      def run
        go_home_page
        %w[random_browse login go_draw_lot_page queue_up draw_lot].each do |method|
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

      def go_draw_lot_page
        page.goto(LOTTERY_LINK, waitUntil: "domcontentloaded")
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
        logger.info "排队完成"
        sleep rand(4.0..8.0)
        # 点击进入网站按钮
        page.locator("#buttonConfirmRedirect").click
        logger.info "用户(#{account_no})进入网站"
      end

      # 抽奖
      def draw_lot
        positions = [
          { product_index: 0, radio_index: 0 },
          { product_index: 4, radio_index: 0 },
          { product_index: 5, radio_index: 0 }
        ]
        human_delay(3.0, 5.0)
        human_like_click("text=抽選応募")
        human_delay(1.0, 3.0)
        human_like_click("#step3Btn")
        human_delay(5.0, 8.0)
        lis = page.locator("ul.comOrderList > li")
        raise "抽奖失败！" if lis.count == 0
        positions.each do |position|
          product_index = position[:product_index]
          li = lis.nth(product_index)
          status = li.locator(".ttl").text_content
          logger.debug "抽奖商品#{product_index}，状态为(#{status})"
          next if status == "受付完了"
          return if status == "受付終了"
          human_delay
          human_like_move_to_element(li.locator("text=詳しく見る"))
          human_like_click_of_element(li.locator("text=詳しく見る"))
          radio_lis = li.locator("ul.radioList > li")
          radio_element = radio_lis.nth(position[:radio_index]).locator("p.radio label")
          human_like_move_to_element(radio_element)
          human_like_click_of_element(radio_element)
          human_like_move_to_element(li.get_by_label("応募要項に同意する"))
          human_like_click_of_element(li.get_by_label("応募要項に同意する"))
          human_like_click_of_element(li.locator("a.popup-modal.on"))
          human_like_click("#applyBtn")
          human_delay(6.0, 8.0)
          if li.locator(".ttl").text_content == "受付完了"
            logger.info "用户(#{@email})抽奖(#{product_index})成功"
          else
            raise "用户(#{@email})抽奖(#{product_index})失败!"
          end
        end
      end
    end # end class DrawLotRunner
  end # end module Pokermon
end # end module BroserAutomation
