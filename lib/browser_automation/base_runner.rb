require "playwright"
module BrowserAutomation
  class BaseRunner
    MU, SIGMA = 0.5, 0.15
    LOCATOR_TIMEOUT = 10_000

    PLAYWRIGHT_HOST = ENV.fetch("PLAYWRIGHT_HOST", "localhost")
    PLAYWRIGHT_PORT = ENV.fetch("PLAYWRIGHT_PORT", "8888")

    USER_AGENTS = [
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0",
      # "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36",
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0",
      # "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36",
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36 Edg/135.0.0.0",
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36 Edg/135.0.0.0",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36"
    ]
    VIEWPORTS = [
      { width: 1366, height: 768 },
      { width: 1440, height: 900 }
    ]

    attr_reader :page, :logger

    def initialize_page(account_dir_name)
      init_logger
      @logger.info "开始加载驱动"
      user_agent = USER_AGENTS.sample
      browser = user_agent.include?("Edg") ? "msedge" : "chrome"
      platform = user_agent.include?("Windows") ? '"Windows"' : '"macOS"'
      version = user_agent.split("Chrome/")[1].split(".").first
      ua = "\"Chromium\";v=\"#{version}\", \"#{browser == 'msedge' ? 'Microsoft Edge' : 'Google Chrome'}\";v=\"#{version}\", \"Not.A/Brand\";v=\"99\""
      @playwright_exec = Playwright.connect_to_playwright_server("ws://#{PLAYWRIGHT_HOST}:#{PLAYWRIGHT_PORT}/ws?browser=chromium")
      user_data_dir = File.join(Dir.pwd, "tmp", "user_data", account_dir_name)
      @context = @playwright_exec.playwright.chromium.launch_persistent_context(
        user_data_dir,
        channel: browser,
        headless: false,
        userAgent: user_agent,
        locale: "ja-JP",
        timezoneId: "Asia/Tokyo",
        args: [
          "--disable-blink-features=AutomationControlled",
          "--disable-dev-shm-usage",
          "--disable-gpu"
        ],
        extraHTTPHeaders: {
          "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6",
          "Sec-Ch-Ua": ua,
          "Sec-Ch-Ua-Mobile": "?0",
          "Sec-Ch-Ua-Platform": platform
        },
        ignoreDefaultArgs: [ "--enable-automation" ],
        viewport: VIEWPORTS.sample
      )
      @logger.info "驱动加载完成-浏览器(#{browser})-user_agent(#{user_agent})"
      @page = @context.pages.first
    end

    def close_page
      page.close
      @context.close
      @playwright_exec.stop
    end

    def human_like_click(selector, steps: 30, move_delay: (0.01..0.03), click_delay: (0.1..0.3), wait_for_navigation: false, navigation_timeout: 30_000)
      # 找到目标元素并获取它的位置信息
      element = page.wait_for_selector(selector, timeout: LOCATOR_TIMEOUT)
      human_like_click_of_element(
        element,
        steps: steps,
        move_delay: move_delay,
        click_delay: click_delay,
        wait_for_navigation: wait_for_navigation,
        navigation_timeout: navigation_timeout
      )
    end

    # 一点一点向下滚动，直到找到目标元素
    def human_like_move_to_element(element, scorll_length: (200..400), delay: (0.5..1.0))
      return if element_in_viewport?(element)
      while !element_in_viewport?(element) do
        break if at_page_bottom?
        human_like_move(scorll_length: scorll_length, delay: delay)
        sleep(rand(delay))
      end
      human_delay
    end

    def human_like_move(scorll_length: (200..400), delay: (0.5..1.0))
      page.evaluate <<~JS
        window.scrollBy({
          top: #{rand(scorll_length)},
          left: 0,
          behavior: 'smooth'
        });
      JS
    end

    def human_like_move_to_top
      return if at_page_top?
      while !at_page_top? do
        page.evaluate <<~JS
          window.scrollBy({
            top: #{rand(-500..-200)},
            left: 0,
            behavior: 'smooth'
          });
        JS
        sleep(rand(0.5..1.0))
      end
    end

    def human_like_move_to_bottom
      return if at_page_bottom?
      while !at_page_bottom? do
        page.evaluate <<~JS
          window.scrollBy({
            top: #{rand(200..500)},
            left: 0,
            behavior: 'smooth'
          });
        JS
        sleep(rand(0.5..1.0))
      end
    end

    # 判断是否到达页面底部
    def at_page_bottom?
      page.evaluate(<<~JS)
        () => {
          return (window.innerHeight + window.scrollY) >= document.body.scrollHeight;
        }
      JS
    end

    # 判断是否到达页面顶部
    def at_page_top?
      page.evaluate("window.scrollY === 0")
    end

    # 判断元素是否在视口内
    def element_in_viewport?(element)
      bounding_box = element.bounding_box
      raise "无法获取元素位置" unless bounding_box
      viewport_size = page.viewport_size
      # 检查元素是否在视口内(去掉上下各200px)
      bounding_box["y"] + bounding_box["height"] > 200 && bounding_box["y"] < (viewport_size[:height] - 200)
    end

    def human_like_click_of_element(element, steps: 30, move_delay: (0.01..0.03), click_delay: (0.1..0.3), wait_for_navigation: false, navigation_timeout: 30_000)
      box = element.bounding_box
      raise "无法获取元素位置" unless box

      # 目标点：元素内部某个随机点
      dx = [ [ gaussian_random, 0.2 ].max, 0.8 ].min
      dy = [ [ gaussian_random, 0.2 ].max, 0.8 ].min
      target_x = box["x"] + dx * box["width"]
      target_y = box["y"] + dy * box["height"]

      # 起始点：使用当前鼠标位置或屏幕左上角附近
      default_x = rand(30..100)
      default_y = rand(30..100)
      start = page.evaluate("() => ({ x: window._lastX || #{default_x}, y: window._lastY || #{default_y} })")
      start_x = start["x"]
      start_y = start["y"]

      # 控制点：模拟人类手部弯曲（增加随机Z轴旋转）
      rotation = (rand - 0.5) * 0.3  # ±17度的随机旋转
      cx = (start_x + target_x) / 2 + rand(-30..30) * Math.cos(rotation)
      cy = (start_y + target_y) / 2 + rand(-30..30) * Math.sin(rotation)

      # 移动鼠标：按贝塞尔轨迹插值并加入轻微抖动
      steps.times do |i|
        t = i.to_f / (steps - 1)
        # 三次贝塞尔曲线（更复杂轨迹）
        x_base = (1 - t)**3 * start_x + 3 * (1 - t)**2 * t * cx + 3 * (1 - t) * t**2 * target_x + t**3 * target_x
        y_base = (1 - t)**3 * start_y + 3 * (1 - t)**2 * t * cy + 3 * (1 - t) * t**2 * target_y + t**3 * target_y
        # 加入5-10Hz的高频抖动（更接近真实手部颤抖）
        jitter_x = Math.sin(t * Math::PI * (5 + rand(5))) * (0.3 + rand(0.3))
        jitter_y = Math.cos(t * Math::PI * (5 + rand(5))) * (0.3 + rand(0.3))
        x = x_base + jitter_x + rand(-0.5..0.5)
        y = y_base + jitter_y + rand(-0.5..0.5)

        page.mouse.move(x, y, steps: 1)
        page.evaluate("window._lastX = #{x}; window._lastY = #{y};")

        sleep(rand(move_delay))
        sleep(rand(0.03..0.15)) if rand < 0.15  # 随机小停顿
        human_delay
      end

      # 停顿后点击（更像人）
      sleep(rand(click_delay))
      if wait_for_navigation
        page.expect_navigation(timeout: navigation_timeout) do
          simulate_human_click(target_x, target_y)
        end
      else
        simulate_human_click(target_x, target_y)
      end
    end

    # 模拟人类点击（分离 mouse.down 和 mouse.up）
    def simulate_human_click(x, y)
      page.mouse.move(x, y)
      sleep(rand(0.05..0.15))
      page.mouse.down
      sleep(rand(0.05..0.15))
      page.mouse.up
    end

    # 模拟滚动页面
    # @param [Range] scroll_times 滚动次数
    # @param [Range] scorll_length 每次滚动的长度，正数向上，负数向下，单位像素
    # @param [Range] delay 每次滚动之间的延迟
    def human_like_scroll(scroll_times: (2..4), scorll_length: (-200..800), delay: (0.5..1.0))
      real_scroll_times = rand(scroll_times)
      real_scroll_times.times do |n|
        scroll_progress = n.to_f / real_scroll_times
        # 加速度曲线（easeOutQuad）
        acceleration = 1 - (1 - scroll_progress) ** 2
        page.evaluate <<~JS
          window.scrollBy({
            top: #{rand(scorll_length) * acceleration},
            left: 0,
            behavior: 'smooth'
          });
        JS
        # sleep(rand(delay))
        sleep(MU + gaussian_random * SIGMA + rand(0.2..0.5))
      end
    end

    # 采样函数（Box–Muller）
    def gaussian_random
      u1, u2 = rand, rand
      z0 = Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math::PI * u2)
      MU + z0 * SIGMA
    end

    def human_delay(min = 0.5, max = 2.0)
      sleep(rand(min..max))
    end

    def init_logger
      STDOUT.set_encoding('UTF-8')
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @logger.formatter = proc do |severity, datetime, _, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity} - #{msg}\n"
      end
    end
  end # end class BaseRunner
end # end module BrowserAutomation
