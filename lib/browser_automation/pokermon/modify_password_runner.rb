module BrowserAutomation
  module Pokermon
    class ModifyPasswordRunner < ModifyProfileRunner
      def run
        logger.info "用户(#{email})开始修改密码"
        go_home_page
        random_browse
        login
        modify_password
        { success: true, email: email }
      rescue Exception => e
        logger.error "用户(#{email})修改密码失败: #{e.message}"
        { success: false, email: email }
      ensure
        close_page
      end
    end # end class ModifyPasswordRunner
  end # end module Pokermon
end # end module BrowserAutomation
