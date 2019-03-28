title: ListView实现仿知乎广告Item
date: 2017-08-27 16:45:39
category: android开发
---

# 前言
知乎APP有一个广告效果，是list在滑动的时候，在某一个item显示出一个远大于item的背景，给人一种item是空的感觉，网上已经有了demo，但我看了看全是拿RecyclerView写的，RecyclerView有一个好处就是，它滑动时的回调，可以准确的拿到dx dy。

```
 public void onScrolled(RecyclerView recyclerView, int dx, int dy)
```

但是结合我们的项目，还是使用的之前的ListView，如果整个修改成RecyclerView，成本太高，于是就在ListView上尝试的写了一次，稍微记录一下实现方法。

因为我们的Item里面，还有一个类似弹幕的东东，就没有像网上的demo一样直接画drawable，而是采用了LinearLayout来实现。

# 原理
ListView也有onScroll()方法，不它该方法的回调时给的参数是item的position

```
onScroll(AbsListView view, int firstVisibleItem, int visibleItemCount, int totalItemCount)
```

<!-- more -->

# 实现
整个item的布局比较简单，使用的是指定高度的FrameLayout，其内部再嵌套一个和ListView高度一样的LinearLayout（这里可以在adapter的getView中拿到ListView的高度），在onScroll方法中，对visibleItem进行遍历，凡是碰到是这种item的。

拿到该类型的item的view后，获取top bottom，就是当前view相对于父控件的度坐标，相当于拿到了RecyclerView中onScroll()的dx，dy。

根据top，bottom计算LinearLayout需要的偏移。因为在FrameLayout中，LinearLayout是在Item顶部对齐的，所以，这里需要调用LinearLayout的scrollTo(0,top)方法，将你的FrameLayout内部嵌套的LinearLayout滚动到top的位置。

# 放点伪代码

```
public void onScroll(AbsListView view, int firstVisibleItem, int visibleItemCount, int totalItemCount) {
    final int height = view.getHeight();
    final int width = view.getWidth();
    if (view instanceOf HollowView){
	HollowView itemView = (HollowView) view.getChildAt(i - firstVisibleItem);
	final int top = itemView.getTop();
	int bottom = itemView.getBottom();
	itemView.update(width,height, top, bottom);
	}
}
```

# 其它

我们还有其它一些动画，都是item里面的view需要跟着滑动来像弹幕一样移动，到达一定位置后，缩小，放大。

只要在update里面，setX  setScaleX setScaleY，写具体的方法就OK。初中学的知识，y=kx+b
b是初始化时的偏移，k就是速度了。x变量就是top的值。
