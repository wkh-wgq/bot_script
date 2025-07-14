module BrowserAutomation
  module Pokermon
    class OrderRunner < LoginBaseRunner
      def initialize(email, password:, products:)
        super(email, password)
        logger.info "用户(#{email})开始下单流程"
        @products = products
      end

      def run
        go_home_page
        %w[validate_network queue_up random_browse login validate_address clear_cart shopping fill_order_no].each do |method|
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

      def shopping
        add_carts
        human_like_click("text=レジに進む")
        human_like_move_to_element(page.locator(".submit-shipping"))
        human_like_click(".submit-shipping")
        human_delay(3, 5)
        human_like_move_to_element(page.locator("text=代金引換"))
        human_like_click("text=代金引換")
        human_like_move_to_element(page.locator("text=ご注文内容を確認する"))
        human_like_click("text=ご注文内容を確認する")
        human_delay(3, 5)
        human_like_move_to_element(page.locator("text=注文を確定する").last)
        human_like_click_of_element(page.locator("text=注文を確定する").last)
      end

      def add_carts
        @products.each do |product|
          add_cart(product[:link], product[:quantity])
        end
      end

      # 加入购物车
      def add_cart(link, quantity)
        page.goto link
        human_delay(0.2, 0.5)
        human_like_move_to_element(page.locator("text=カートに入れる"))
        # human_like_click("#quantity")
        page.select_option("#quantity", value: quantity.to_s)
        human_like_click("text=カートに入れる")
        human_delay(2, 5)
        human_like_click("text=注文手続きへ進む")
        human_delay(1, 3)
      end

      # 回填订单号
      def fill_order_no
        sleep 10
        human_like_move_to_element(page.locator("text=トップページへ"))
        @order_no = page.locator(".numberTxt .txt").inner_text
        logger.info "用户(#{email})订单号：#{@order_no}"
      end
    end # end class OrderRunner
  end # end module Pokermon
end # end module BrowserAutomation
