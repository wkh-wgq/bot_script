依赖ruby-3.3.4环境还node环境
需要提前安装chrome浏览器和edge浏览器

需要开启2个控制台，一个运行playwright，一个运行ruby脚本

playwright控制台
1.安装playwright
npm install playwright@1.51.1
2.运行playwright
npx playwright run-server --port 8888 --path /ws


开启另外一个控制台以运行ruby脚本
1.安装gem依赖
bundle install
2.运行脚本(其中的json文件路径和输出的log文件路径需要修改为自己的文件路径)

下单
ruby pokermon_order.rb ~/Downloads/order.json > ~/Downloads/order.log

抽奖
ruby pokermon_draw_lot.rb ～/Downloads/draw_lot.json > ～/Downloads/draw_lot.log

中奖付款
ruby pokermon_lottery_won_pay.rb ～/Downloads/emails.txt > ～/Downloads/result.log

修改地址(如果地址正确，则直接返回)
ruby pokermon_modify_address.rb ～/Downloads/emails.txt

修改密码(如果密码正确，则直接返回)
ruby pokermon_modify_password.rb ～/Downloads/emails.txt