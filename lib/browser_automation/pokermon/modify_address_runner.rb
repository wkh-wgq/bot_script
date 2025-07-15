module BrowserAutomation
  module Pokermon
    class ModifyAddressRunner < ModifyProfileRunner
      def run
        logger.info "用户(#{email})开始修改地址"
        go_home_page
        random_browse
        login
        modify_address
        { success: true, email: email, mobile: @mobile }
      rescue Exception => e
        logger.error "用户(#{email})修改地址失败: #{e.message}"
        { success: false, email: email }
      ensure
        close_page
      end
    end # end class ModifyAddressRunner
  end # end module Pokermon
end # end module BrowserAutomation
