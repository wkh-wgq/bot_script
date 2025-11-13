require "playwright"
require "sys/filesystem"
require 'perlin_noise'
require 'json'
module BrowserAutomation
  class BaseRunner
    MU, SIGMA = 0.5, 0.15
    LOCATOR_TIMEOUT = 10_000

    PLAYWRIGHT_HOST = ENV.fetch("PLAYWRIGHT_HOST", "localhost")
    PLAYWRIGHT_PORT = ENV.fetch("PLAYWRIGHT_PORT", "8888")
    TEMPLATE_USER_DATA_DIR = File.join(Dir.pwd, "template", "initialize_user_data")
    VIEWPORTS = [
      { width: 1366, height: 768 },
      { width: 1440, height: 900 }
    ]

    attr_reader :page, :logger

    def initialize_page(account_dir_name)
      init_logger
      @logger.info "开始加载驱动"
      user_agents = File.read(File.join(Dir.pwd, "config", "user_agents.txt")).strip.split("\n")
      raise "请先在user_agents.txt文件中配置user_agent" if user_agents.empty?
      user_agent = user_agents.sample.strip
      raise "请配置正确的user_agent" if user_agent.empty?
      browser = user_agent.include?("Edg") ? "msedge" : "chrome"
      platform = user_agent.include?("Windows") ? '"Windows"' : '"macOS"'
      version = user_agent.split("Chrome/")[1].split(".").first
      ua = "\"Chromium\";v=\"#{version}\", \"#{browser == 'msedge' ? 'Microsoft Edge' : 'Google Chrome'}\";v=\"#{version}\", \"Not.A/Brand\";v=\"99\""
      @playwright_exec = Playwright.connect_to_playwright_server("ws://#{PLAYWRIGHT_HOST}:#{PLAYWRIGHT_PORT}/ws?browser=chromium")
      @context = @playwright_exec.playwright.chromium.launch_persistent_context(
        get_user_data(account_dir_name),
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
      config = self.class.load_config
      unless config["is_load_image"]
        @context.route("**/*.png", ->(route, request) { route.abort })
        @context.route("**/*.jpg", ->(route, request) { route.abort })
        @context.route("**/*.gif", ->(route, request) { route.abort })
      end
      @logger.info "驱动加载完成-浏览器(#{browser})-user_agent(#{user_agent})"
      @page = @context.pages.first
    end

    def close_page
      page.close
      @context.close
      @playwright_exec.stop
    end

    def human_like_click(selector, min_segments: 2, max_segments: 4, move_delay: (0.01..0.03), click_delay: (0.1..0.3), wait_for_navigation: false, navigation_timeout: 30_000)
      # 找到目标元素并获取它的位置信息
      element = page.wait_for_selector(selector, timeout: LOCATOR_TIMEOUT)
      human_like_click_of_element(
        element,
        min_segments: min_segments,
        max_segments: max_segments,
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
      raise "无法获取元素(#{get_element_selector(element)})位置" unless bounding_box
      viewport_size = page.viewport_size
      # 检查元素是否在视口内(去掉上下各200px)
      bounding_box["y"] + bounding_box["height"] > 200 && bounding_box["y"] < (viewport_size[:height] - 200)
    end

    def human_like_click_of_element(element, min_segments: 2, max_segments: 4, move_delay: (0.01..0.03), click_delay: (0.1..0.3), wait_for_navigation: false, navigation_timeout: 30_000)
      # 滚动干扰（确保元素可见 + 随机滚动）
      element_handle = element.is_a?(Playwright::ElementHandle) ? element : element.element_handle
      page.evaluate(<<~JS, arg: element_handle)
        (el) => {
          const rect = el.getBoundingClientRect();
          const isAbove = rect.top < 0;
          const isBelow = rect.bottom > window.innerHeight;

          // 如果不在视口中，滚动到可见位置
          if (isAbove || isBelow) {
            el.scrollIntoView({ behavior: "smooth", block: "center" });
          }

          // 有 20% 概率随机滚动干扰
          if (Math.random() < 0.2) {
            const delta = (Math.random() - 0.5) * 200;
            window.scrollBy({ top: delta, behavior: "smooth" });
          }
        }
      JS
      sleep(rand(0.3..0.8)) # 滚动后停顿

      box = element.bounding_box
      raise "无法获取元素(#{get_element_selector(element)})位置" unless box

      # 目标点（偏向中心）
      bias_center = 0.55 + (rand - 0.5) * 0.1
      dx = rand < 0.7 ? bias_center : rand(0.2..0.8)
      dy = rand < 0.7 ? bias_center : rand(0.2..0.8)
      target_x = box["x"] + dx * box["width"]
      target_y = box["y"] + dy * box["height"]

      # 起始点
      default_x = rand(30..100)
      default_y = rand(30..100)
      start = page.evaluate("() => ({ x: window._lastX || #{default_x}, y: window._lastY || #{default_y} })")
      start_x = start["x"]
      start_y = start["y"]

      # 生成多段贝塞尔路径
      segments = rand(min_segments..max_segments)
      points = [ [ start_x, start_y ] ]
      segments.times do
        points << [ target_x + rand(-40..40), target_y + rand(-40..40) ]
      end
      points << [ target_x, target_y ]

      # 中途路径修正（模拟“手动调整”）
      if rand < 0.15
        mid_index = points.size / 2
        adjust_x = target_x + rand(-60..60)
        adjust_y = target_y + rand(-60..60)
        points.insert(mid_index, [adjust_x, adjust_y])
      end

      # 插值路径
      steps_per_segment = 12
      total_points = []
      drift_x = rand(-20..20)
      drift_y = rand(-20..20)

      (0...(points.size - 1)).each do |i|
        p0 = points[i]
        p3 = points[i + 1]
        c1x = p0[0] + (p3[0] - p0[0]) * 0.3 + rand(-25..25)
        c1y = p0[1] + (p3[1] - p0[1]) * 0.3 + rand(-25..25)
        c2x = p0[0] + (p3[0] - p0[0]) * 0.6 + rand(-25..25)
        c2y = p0[1] + (p3[1] - p0[1]) * 0.6 + rand(-25..25)

        steps_per_segment.times do |step|
          t = step.to_f / (steps_per_segment - 1)
          t_sigmoid = 1 / (1 + Math.exp(-12 * (t - 0.5))) # 加减速
          t_curve = t_sigmoid + Math.sin(t * Math::PI * rand(0.8..1.2)) * 0.02

          x_base = (1 - t_curve)**3 * p0[0] + 3 * (1 - t_curve)**2 * t_curve * c1x + 3 * (1 - t_curve) * t_curve**2 * c2x + t_curve**3 * p3[0]
          y_base = (1 - t_curve)**3 * p0[1] + 3 * (1 - t_curve)**2 * t_curve * c1y + 3 * (1 - t_curve) * t_curve**2 * c2y + t_curve**3 * p3[1]

          # 高频抖动
          noise = Perlin::Noise.new(1)
          jitter_x = noise[t * 10] * 2
          jitter_y = noise[t * 10 + 100] * 2

          x = x_base + jitter_x + drift_x * t_curve + rand(-0.5..0.5)
          y = y_base + jitter_y + drift_y * t_curve + rand(-0.5..0.5)

          total_points << [ x, y ]
        end
      end

      # 执行鼠标移动
      total_points.each_with_index do |(x, y), idx|
        page.mouse.move(x, y, steps: 1)
        page.evaluate("window._lastX = #{x}; window._lastY = #{y};")

        sleep(gaussian_random((move_delay.min + move_delay.max) / 2.0, 0.005).clamp(0.005, 0.06))
        sleep(rand(0.03..0.15)) if rand < 0.15
      end

      # Hover 停顿
      # page.mouse.move(target_x, target_y)
      sleep(rand(0.15..0.4)) # 模拟人在点击前的短暂犹豫
      if rand < 0.3
        # 30% 概率在目标附近微调一下
        page.mouse.move(target_x + rand(-3..3), target_y + rand(-3..3))
        sleep(rand(0.05..0.15))
        page.mouse.move(target_x, target_y)
      end

      # 越界修正（模拟“校准”）
      if rand < 0.25
        page.mouse.move(target_x + rand(-5..5), target_y + rand(-5..5))
        sleep(rand(0.05..0.1))
        page.mouse.move(target_x, target_y)
      end

      # 点击
      sleep(rand(click_delay))
      if rand < 0.02
        # 模拟误点后补点
        page.mouse.click(target_x + rand(-6..6), target_y + rand(-6..6))
        sleep(rand(0.05..0.2))
      end

      if wait_for_navigation
        page.expect_navigation(timeout: navigation_timeout) do
          simulate_human_click(target_x, target_y)
        end
      else
        simulate_human_click(target_x, target_y)
      end
    end

    def simulate_human_click(x, y)
      page.mouse.move(x, y)
      sleep(rand(0.05..0.15))
      page.mouse.down
      sleep(rand(0.05..0.2))
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
    def gaussian_random(mean = MU, stddev = SIGMA)
      u1, u2 = rand, rand
      z0 = Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math::PI * u2)
      mean + z0 * stddev
    end

    def human_delay(min = 0.5, max = 2.0)
      sleep(rand(min..max))
    end

    def human_mouse_idle_move(duration: 5, min_steps: 5, max_steps: 20, delay_range: 0.01..0.05)
      viewport = page.viewport_size
      viewport_width = viewport[:width]
      viewport_height = viewport[:height]
      start_time = Time.now
      # 从当前鼠标位置或随机位置开始
      x = rand(0..viewport_width)
      y = rand(0..viewport_height)

      while Time.now - start_time < duration
        steps = rand(min_steps..max_steps)
        # 随机下一个目标点
        target_x = rand(0..viewport_width)
        target_y = rand(0..viewport_height)

        steps.times do |i|
          t = (i + 1).to_f / steps
          # 使用线性插值 + 随机微抖动
          x_next = x + (target_x - x) * t + rand(-1.0..1.0)
          y_next = y + (target_y - y) * t + rand(-1.0..1.0)

          page.mouse.move(x_next, y_next)
          sleep rand(delay_range)
        end

        # 更新当前位置
        x = target_x
        y = target_y
      end
    end

    # =========================
    #  拟人化悬停动作
    # =========================
    def human_like_hover(element_or_selector)
      element = element_or_selector.is_a?(Playwright::ElementHandle) ?
                  element_or_selector :
                  page.query_selector(element_or_selector)
      box = element.bounding_box
      raise "无法获取元素(#{get_element_selector(element)})位置" unless box
      # 悬停目标点（略偏中间）
      target_x = box["x"] + box["width"] * (0.4 + rand * 0.2)
      target_y = box["y"] + box["height"] * (0.4 + rand * 0.2)

      # 起始点为上次鼠标位置或屏幕某处
      start = page.evaluate("() => ({x: window._lastX || 50, y: window._lastY || 50})")
      start_x, start_y = start.values_at("x", "y")

      # 生成平滑路径（贝塞尔曲线）
      steps = 20
      cx = (start_x + target_x) / 2 + rand(-40..40)
      cy = (start_y + target_y) / 2 + rand(-40..40)
      path = (0..steps).map do |i|
        t = i.to_f / steps
        t_ease = 1 / (1 + Math.exp(-12 * (t - 0.5))) # sigmoid缓动
        x = (1 - t_ease)**2 * start_x + 2 * (1 - t_ease) * t_ease * cx + t_ease**2 * target_x
        y = (1 - t_ease)**2 * start_y + 2 * (1 - t_ease) * t_ease * cy + t_ease**2 * target_y
        [x + rand(-0.5..0.5), y + rand(-0.5..0.5)]
      end

      # 执行移动
      path.each do |x, y|
        page.mouse.move(x, y, steps: 1)
        page.evaluate("window._lastX = #{x}; window._lastY = #{y};")
        sleep(rand(0.01..0.03))
      end

      # 停顿观察（人类注视）
      page.mouse.move(target_x, target_y)
      sleep(rand(0.4..1.2))

      # 微抖动模拟注意力转移
      rand(2..4).times do
        dx = rand(-3..3)
        dy = rand(-3..3)
        page.mouse.move(target_x + dx, target_y + dy, steps: 1)
        sleep(rand(0.05..0.15))
      end

      # 可能再次悬停
      if rand < 0.2
        sleep(rand(0.5..1.0))
        page.mouse.move(target_x + rand(-2..2), target_y + rand(-2..2))
      end

      sleep(rand(0.4..1.0))
    end

    def human_like_hover_and_decide_click(element_or_selector, click_probability: 0.4, hesitation: (0.8..2.0))
      element = element_or_selector.is_a?(Playwright::ElementHandle) ?
                  element_or_selector :
                  page.query_selector(element_or_selector)

      box = element.bounding_box
      raise "无法获取元素(#{get_element_selector(element)})位置" unless box

      # 悬停 + 抖动
      human_like_hover(element)

      # 模拟“人眼观察 + 犹豫”
      sleep(rand(hesitation))

      # 模拟“在区域内轻微移动查看内容”
      rand(2..5).times do
        dx = rand(-5..5)
        dy = rand(-5..5)
        x = box["x"] + box["width"] / 2 + dx
        y = box["y"] + box["height"] / 2 + dy
        page.mouse.move(x, y, steps: 1)
        sleep(rand(0.05..0.2))
      end

      # 再次停顿（模拟考虑是否点击）
      sleep(rand(0.5..1.5))

      # 以概率点击
      if rand < click_probability
        simulate_human_click(
          box["x"] + box["width"] * (0.4 + rand * 0.2),
          box["y"] + box["height"] * (0.4 + rand * 0.2)
        )
        sleep(rand(1.0..2.5))
      else
        # 离开 hover 区域（模拟兴趣丧失）
        page.mouse.move(box["x"] + box["width"] + rand(30..60), box["y"] + rand(-20..20), steps: 3)
        sleep(rand(0.3..0.8))
      end
    end


    def get_element_selector(element)
      begin
        element.instance_variable_get('@impl').instance_variable_get('@selector')
      rescue Exception => _e
        nil
      end
    end

    # 拟人化点击并输入文本
    def human_like_type_with_click(selector, text, min_delay: 0.08, max_delay: 0.25)
      human_like_click(selector)
      human_like_type(text, min_delay: min_delay, max_delay: min_delay)
    end

    # 拟人化输入文本(每个字符随机延迟)
    def human_like_type(text, min_delay: 0.08, max_delay: 0.25)
      text.each_char do |char|
        page.keyboard.press(char)
        sleep(rand(min_delay..max_delay))
      end
    end

    def get_user_data(account_dir_name)
      user_data_dir_paths = File.read(File.join(Dir.pwd, "config", "user_data_dir.txt")).strip.split("\n")
      # 查找用户目录
      user_data_dir_paths.each do |user_data_dir_path|
        user_data_dir_path = File.join(user_data_dir_path, "user_data")
        FileUtils.mkdir_p(user_data_dir_path) unless File.exist?(user_data_dir_path)
        if Dir.children(user_data_dir_path).include? account_dir_name
          return File.join(user_data_dir_path, account_dir_name)
        end
      end
      config = self.class.load_config
      # 初次登陆的时候，确定使用哪个目录
      user_data_dir_paths.each do |user_data_dir_path|
        user_data_dir_path = File.join(user_data_dir_path, "user_data")
        stat = Sys::Filesystem.stat(user_data_dir_path)
        if stat.blocks_available.to_f / stat.blocks > config["disk_free_threshold"]
          user_data_dir = File.join(user_data_dir_path, account_dir_name)
          initialize_user_data(user_data_dir)
          return user_data_dir
        end
      end
      raise "磁盘空间不足"
    end

    # 初始化用户数据目录，如果是新用户，则将模版copy一份到用户目录下
    def initialize_user_data(user_data_dir)
      return if File.exist?(user_data_dir)
      FileUtils.cp_r(TEMPLATE_USER_DATA_DIR, user_data_dir)
      logger.info("copy模版用户目录: #{user_data_dir}")
    end

    def init_logger
      STDOUT.set_encoding('UTF-8')
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @logger.formatter = proc do |severity, datetime, _, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity} - #{msg}\n"
      end
    end

    def self.load_config
      return @config if @config
      json_text = File.read(File.join(Dir.pwd, "config", "bot_config.json"))
      begin
        @config = JSON.parse(json_text)
        min_interval_minutes, max_interval_minutes = @config["interval_minutes"].split("-").map{|i| i.to_i * 60}
        @config["min_interval_minutes"] = min_interval_minutes
        @config["max_interval_minutes"] = max_interval_minutes || min_interval_minutes
        
        min_failure_delay_minutes, max_failure_delay_minutes = @config["failure_delay_minutes"].split("-").map{|i| i.to_i * 60}
        @config["min_failure_delay_minutes"] = min_failure_delay_minutes
        @config["max_failure_delay_minutes"] = max_failure_delay_minutes || min_failure_delay_minutes

        @config["max_consecutive_failures"] = @config["max_consecutive_failures"].to_i
        @config["disk_free_threshold"] = @config["disk_free_threshold"].to_f
        @config
      rescue Exception => _e
        raise "bot_config.json 格式错误"
      end
    end
  end # end class BaseRunner
end # end module BrowserAutomation
