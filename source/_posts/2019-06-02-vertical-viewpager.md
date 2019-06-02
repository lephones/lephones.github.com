title: 垂直滚动的ViewPager存在滑动不灵敏的问题
date: 2019-06-02 17:49:00
category: android开发

tag: [android]
---

# 垂直滚动的ViewPager

凡是找到我这篇文章的，肯定都在网上看过这样一篇文章`[几行代码实现ViewPager垂直滚动]`，地址我就不上了，随便一搜，到处都是，原理也很简单，交换一下横竖坐标，再设置一个上下的`Transformer`。然而，事情并没有想像的那么简单。

<!-- more -->

# ViewPager滚动源码解析

在我提交上面的交换xy坐标代码后，测试拿着手机过来找我了，出现的问题就是，必须慢慢的将当前页滑动过页面的一半，松手时，才能滚到上一页或者下一页。这就导致如果是大屏手机，用户会很难去到下一页。我本来是以为x y坐标的问题，跟踪源码后，发现并不是。

在ViewPager中，滚动到上一页或者下一页的关键方法叫`determineTargetPage`，其中，如果是滚动到下一页，currentPage是当前页的position，如果是滚动到上一页，currentPage是上一页的position。

![image-20190602181111242](/image/20190602/viewpager-src.jpg)

第一个if的逻辑是，先计算滑动距离和滑动的速度，如果超过了`mFlingDistance`和`mMininumVelocity`，再根据速度的正负值来判断方向，如果velocity > 0，则说明是[向右滑]的手势（先不考虑更换xy坐标），也就是滑动到上一页，返回currentPage。(currentPage是上一页的position)。如果velocity < 0，那就是[向左滑]的手势（先不考虑更换xy坐标），则是去到下一页。(currentPage是当前页的position)

else中的逻辑是，当用户慢慢拖动后松开手，也就是滚动速度和滚动距离的条件没有同时满足。此时通过计算出的`truncator`来计算目标页，可以理解为`pageOffset`是`currentPage`进了屏幕多少多少，而truncator就是剩下多少时滑动的一个比例。举个例子：

假如我们向下滑，上一页只露出了40%，那么pageOffset就是0.6，此时，0.6+0.6取整就是1，targetPage = currentPage + 1，而因为此时currentPage是上一页，所以又回滚回去。同理，假如我们向上滑，currentPage是当前页，也需要把pageOffSet滑动到0.6的位置，才能到下一页。



# 修改速率不成功

找到了原理，就要修改了，起初我想着是，修改`mFlingDistance`和`mMininumVelocity`这两个值就好，因为这俩变量本身不支持修改，就把ViewPager的源码拷贝了一份。满心欢喜的做了个测试，失败，失败的原因，也比较蹊跷。

MotionEvent有一个方法，叫setLocation，交换xy坐标的方法，正是采用调用该方法实现的。但是在viewPager中，通过调用VelocityTracker的getXVelocity方法时，不论你如何执行setLocation，最终计算出的velocity永远都是指着真正在屏幕X方向上滑动的速度，也就是此时并没有把y轴的速度转到x上。这部分应该是跟native内部实现有关。

# 去掉速度，只判断距离

既然速度废了，那就不判断速率了，只判断距离。于是代码被我改成了这样子。

```java
 private int determineTargetPage(int currentPage, float pageOffset, int velocity, int deltaX) {
        int targetPage;
        if (Math.abs(deltaX) > mFlingDistance) {
            targetPage = velocity > 0 ? currentPage : currentPage + 1;
        } else {
            final float truncator = currentPage >= mCurItem ? 0.9f : 0.1f;
            targetPage = currentPage + (int) (pageOffset + truncator);
        }

       if (mItems.size() > 0) {
           final ItemInfo firstItem = mItems.get(0);
           final ItemInfo lastItem = mItems.get(mItems.size() - 1);

           // Only let the user target pages we have items for
           targetPage = Math.max(firstItem.position, Math.min(targetPage, lastItem.position));
       }

       return targetPage;
   }
```

此时，只判断了`mFlingDistance`，为了保险起见，我又将else中的代码，计算truncator时，改成了0.8和0.2。也就是当上一页或者下一页露出10%以上时，则滚动到相应的页面。代码是周末前提交的，写这篇博客是在周末，暂没有产品和测试的体验结果。



# 其它

复制ViewPager.java的时候，PagerAdapter有一个方法是setViewPagerObserver，因为这个方法是不允许访问的，这里可以改成registerDataSetObserver和unregisterDataSetObserver



