---
layout: post
title: 金丝雀(金丝雀测试，金丝雀部署)了解一下
date: 2019-06-10 17:54:11
tags: 
  - 测试
---

在软件测试中，金丝雀([canary](https://whatis.techtarget.com/definition/canary-canary-testing))是将编程代码更改推送给不知道他们正在接收新代码的一小组最终用户。因为金丝雀只分发给少数用户，所以它的影响相对较小，如果新代码被证明是错误的，变化可以迅速逆转。通常自动化的金丝雀测试(canary test)在沙盒环境中的测试完成后运行。
 
对于增量代码更改，使用金丝雀([canary](https://whatis.techtarget.com/definition/canary-canary-testing))方法提供功能允许开发团队快速评估代码版本是否提供了所需的结果。选择“金丝雀”一词来描述向一部分用户推送的代码，是因为金丝雀曾被用于煤矿开采当有毒气体达到危险水平时提醒矿工。与煤矿中的金丝雀一样，被选中在金丝雀测试(canary test)中接收新代码的最终用户并不知道他被用来提供预警。
 
![金丝雀测试](/images/06-10/canary_testing.jpg)
> 在金丝雀([canary](https://whatis.techtarget.com/definition/canary-canary-testing))测试中，最终用户的一小部分用作更新的测试组。如果更新中的任何内容导致问题，它会在大量用户感受到影响之前向IT团队发出警报。

### *参考:*
- [wiki/Canary](https://en.wikipedia.org/wiki/Canary)
- [canary-canary-testing](https://whatis.techtarget.com/definition/canary-canary-testing)