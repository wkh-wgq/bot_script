module BrowserAutomation
  module Pokermon
    class LotteryWonPayRunner < LoginBaseRunner
      def initialize(email, password:)
        super(email, password)
        logger.info "用户(#{email})开始进行抽奖付款"
      end

      def run
        go_home_page
        %w[validate_network queue_up random_browse login clear_cart validate_address pay fill_order_no].each do |method|
          send(:execute_with_log, method)
        end
        logger.info "用户(#{email})下单完成"
        { success: true, email: email, order_no: @order_no }
      rescue CustomError => e
        { success: false, email: email, error_code: e.code }
      rescue Exception => _e
        logger.error "用户(#{email})下单流程异常结束"
        { success: false, email: email }
      ensure
        close_page
      end

      def pay
        human_like_click("text=抽選履歴")
        human_like_move_to_element(page.locator("text=抽選履歴一覧を見る"))
        human_like_click("text=抽選履歴一覧を見る")

        human_delay

        human_like_move_to_element(page.locator("text=注文へ進む"))
        human_like_click("text=注文へ進む")

        human_delay(7, 10)

        human_like_move_to_element(page.locator("text=予約する"))
        human_like_click("text=予約する")
        sleep(rand(5..7))
        human_like_click("text=注文手続きへ進む")
        human_delay

        human_like_click("text=レジに進む")
        human_like_move_to_element(page.locator(".submit-shipping"))
        human_like_click(".submit-shipping")

        human_delay(3, 5)

        if page.locator(".stored-card-number").inner_text[0..5] != "539502" || page.locator(".stored-card-expire").inner_text != "07/27"
          raise CustomError.new("信用卡信息不正确", :wrong_card)
        end

        human_like_move_to_element(page.locator("text=ご注文内容を確認する"))
        human_like_click("text=ご注文内容を確認する")

        human_delay(3, 5)

        human_like_move_to_element(page.locator("text=注文を確定する").last)
        human_like_click_of_element(page.locator("text=注文を確定する").last)
        human_delay
      end

      # 回填订单号
      def fill_order_no
        human_delay(15, 20)
        human_like_move_to_element(page.locator("text=トップページへ"))
        @order_no = page.locator(".numberTxt .txt").inner_text
        logger.info "用户(#{email})订单号：#{@order_no}"
      end
    end # end class OrderRunner
  end # end module Pokermon
end # end module BrowserAutomation
