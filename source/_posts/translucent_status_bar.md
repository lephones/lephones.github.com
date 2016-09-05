title: Android沉浸式状态栏的实现
date: 2016-09-05 20：01:50
tags: [android,状态栏]
category: android开发
---
从API 19开始，也就是android 4.4 kitcat，android开始支持沉浸式状态栏。可以使状态栏看起来和我们的程序浑然一体，不再像之前那样突兀。几个月前，刚好做了个这方面的需求，记录一下踩了的坑。
<!-- more -->
# 需求概述
一共两种类型的沉浸式，一种是将view直接伸到statusbar里去，另一种是直接给statusbar设置一个背景色。其中，有些需要将伸到statusbar里的页面，顶部还有一个类似titlebar的view，有交互，必须保证操作区域没有进入到状态栏中。设置背景色的需求则比较简单，直接换个纯色的背景色。

# 实现
一顿的搜索前辈们的各种技术文章之后发现，一切效果都是：不理想。可以参考知乎上的一个问答[Android 5.0 如何实现将布局的内容延伸到状态栏](https://www.zhihu.com/question/31468556)，网上也找了一些开源类，大多修改状态栏颜色的和布局伸入状态栏的是分开的，没有在一起介绍的。而且发现有些方法中介绍的fitsSystemWindows属性的办法，对我来说简直就是噩梦，布局太复杂，试了好多遍都没成功。

## 修改状态栏颜色的方法
4.4的版本和5.x的版本，实现方式还有点区别。4.4是没有提供直接改状态栏的办法的，如果要修改状态栏颜色，就需要将状态栏直接隐藏，再在根布局上增加一个statusbar等高的view。

而在5.x的系统上，有一个方法叫，setStatusBarColor，可以直接修改状态栏的颜色。

4.4隐藏状态栏的代码如下，
```
Window window =  mActivity.getWindow();
window.addFlags(Window.FLAG_TRANSLUCENT_STATUS);
```

设置颜色比较简单，在4.4的系统，调用`addFlags(Window.FLAG_TRANSLUCENT_STATUS)`，然后在根布局add一个状态栏高度的view；在5.x以上的系统，调用`setStatusBarColor`，就OK了。

## 将布局延伸到状态栏
将布局延伸到状态栏，需要做的就是隐藏掉状态栏，最初我也是按照搜索到的资料介绍，在5.x的系统上使用以下代码：

```
window.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
window.addFlags(Window.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
window.setStatusBarColor(Color.TRANSPARENT);
```
结果，测试发现在华为EMUI 3.x的5.x系统上，沉浸式状态栏的效果失效了，在5.0的系统上，在调用`setStatusBarColor`之前，调用`addFlags(Window.FLAG_TRANSLUCENT_STATUS)`，没有使用上面的代码。

```
window.addFlags(Window.FLAG_TRANSLUCENT_STATUS);
window.setStatusBarColor(Color.TRANSPARENT);
```

实践发现```addFlag(FLAG_TRANSLUCENT_STATUS)```就能让状态栏隐藏，在4.4中，有一层由深变浅的渐变遮罩（这个貌似没办法），不会覆盖整个状态栏；在5.x的手机上，会有一个半透明的黑色遮罩，这个是覆盖的整个状态栏位置的。

为了解决5.0的黑色遮罩的问题，就需要调用```window.setStatusBarColor(Color.TRANSPARENT)```，将状态栏完全设置成全透明的。

## 布局复杂

但是，在隐藏掉以后，实际上，时间、wifi、通知等这些都会存在，顶部的titlebar就需要向下移动statusbar的高度，否则，时间，信号，wifi这些会覆盖在titlebar上面。

解决的办法就是，需要将titlebar的位置，向下移动一个statusbar高度。由于这种类型的页面比较少，所以直接在有titlebar的布局中，include增加了一个0dp高度的view，而在需要将其显示时，初始化时修改view的高度。

为了修改颜色和布局伸入状态栏可以统一处理，statusbar就完全隐藏掉，再增加一个statusbar高度的自定义背景色的view。

# 代码
因为项目sdk版本的原因，我直接把Window类一些字段复制出来了。调用方式：

```
StatusBarManager statusBarManager = new StatusBarManager(activity);
//这里如果要移动titlebar，则在布局中指定为include的自定义statusbar的view
//如果不指定，则调用setStatusBarView();会自动加一个view
statusBarManager.setStatusBarView(view);
```
另外，有些布局，在伸入到状态栏以后，给用户展示的区域就会变小，这个没办法，需要手动调整，只要调用```statusBarManager.getStatusBarHeight()```，此方法（注意这里不是静态方法，静态方法有参数，是获取系统状态栏的高度的）会返回view的高度，如果没有就是0，所以调用时不用做是否api 19+的版本判断。

```
public class StatusBarManager {

    private static final int BUILD_VERSION_KITKAT = 19;
    private static final int BUILD_VERSION_LOLLIPOP = 21;

    //WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS
    public static final int FLAG_TRANSLUCENT_STATUS = 0x04000000;

    //WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS
    public static final int FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS = 0x80000000;

    private Activity mActivity;
    private View statusBarView;
    private int statusBarHeight;

    public StatusBarManager(Activity activity) {
        this.mActivity = activity;
        statusBarHeight = getStatusBarHeight(activity);
    }

    public void setStatusBarView(View statusBarView) {
        this.statusBarView = statusBarView;
        setTransparent();
    }
    public void setStatusBarView() {
        setTransparent();
    }
    public int getStatusBarHeight() {
        return statusBarHeight;
    }

    /**
     * 设置状态栏全透明
     *
     */
    private void setTransparent() {
        if (Build.VERSION.SDK_INT < BUILD_VERSION_KITKAT) {
            return;
        }
        if(statusBarHeight <= 0){
            return;
        }
        transparentStatusBar();
        showStatusBarView();
    }
    @TargetApi(19)
    private void showStatusBarView() {
        int color = mActivity.getResources().getColor(R.color.main_color);
        if(statusBarView == null){
            statusBarView = new View(mActivity);
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                    getStatusBarHeight(mActivity));
            statusBarView.setLayoutParams(params);
            statusBarView.setBackgroundColor(color);
            ViewGroup decorView = (ViewGroup) mActivity.getWindow().getDecorView();
            FrameLayout content = (FrameLayout) decorView.findViewById(android.R.id.content);
            FrameLayout.LayoutParams layoutParams = (FrameLayout.LayoutParams) content.getChildAt(0).getLayoutParams();
            layoutParams.setMargins(0,statusBarHeight,0,0);
            decorView.addView(statusBarView);
        }else{
            ViewGroup.LayoutParams layoutParams = statusBarView.getLayoutParams();
            layoutParams.height = getStatusBarHeight(mActivity);
            statusBarView.setLayoutParams(layoutParams);
            statusBarView.setBackgroundColor(color);
        }

    }

    //参考上面注释掉的代码 因为需要用隐藏API 调用方式进行改成反射
    private void transparentStatusBar(){
        Window window =  mActivity.getWindow();
        if (Build.VERSION.SDK_INT >= BUILD_VERSION_LOLLIPOP) {
            //不add此条flag 会导致在EMUI3.1(华为)上失效，add这个flag 会导致在其它机型上面添加一个半透明黑条
            window.addFlags(FLAG_TRANSLUCENT_STATUS);
            //下面的代码段是不加上面的flag时，要显示纯色的状态栏时需要加的代码 不用了
/*            window.clearFlags(FLAG_TRANSLUCENT_STATUS);
            window.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
            window.addFlags(FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);*/
			//因为需要用隐藏API，没有重新编译5.x版本的android.jar，使用的还是18的api，这里用的反射
            try {
                Class[] argsClass=new Class[]{int.class};
                Method setStatusBarColorMethod = Window.class.getMethod("setStatusBarColor",argsClass);
                setStatusBarColorMethod.invoke(window, Color.TRANSPARENT);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }else{
            window.addFlags(FLAG_TRANSLUCENT_STATUS);
        }
    }


    /**
     * 获取状态栏高度
     *
     * @param context context
     * @return 状态栏高度
     */
    private static int getStatusBarHeight(Context context) {
        if (Build.VERSION.SDK_INT < BUILD_VERSION_KITKAT) {
            return 0;
        }
        // 获得状态栏高度
        int resourceId = context.getResources().getIdentifier("status_bar_height", "dimen", "android");
        return context.getResources().getDimensionPixelSize(resourceId);
    }

    public void setStatusbarVisibility(int visibility){
        if(statusBarView != null) {
            this.statusBarView.setVisibility(visibility);
        }
    }

    public void setColor(int color){
        if(statusBarView != null){
            this.statusBarView.setBackgroundColor(color);
        }
    }

}
```
