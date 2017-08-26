---
title: databinding高级用法
date: 2017-08-26 23:48:29
tags: Android
category: Android

---
<Excerpt in index | 首页摘要>
### 前言

上篇说了Databinding的基础用法，这次，来点别的。

<!-- more -->
<The rest of contents | 余下全文>




### 双向绑定

什么是双向绑定呢，上篇的绑定中，data的数据变化能反应到ui上，但是ui的变化却反应不到我们的data。以EditText为例，双向绑定会使输入框中数据的变化也反映到data上，能够省去我们很多事情。那么，如何开启双向绑定呢？我们只需要将@{}，变为@={}即可。我在使用的过程中，发现as2.2版本编译不过，升级到最新版本之后裁编译通过。

双向绑定最常用的场景就是EditText了。这里就不举例了。

### 属性监听

这个又是什么呢？哦，说道这个，上篇貌似漏了个东西，要想使我们的数据变化能反应在ui上，那么我们的数据必须是可观察的，我们有两种方式实现，一种是继承BaseObservable，这种方式有个缺点，就是我们要显示的使用notifyPropertyChanged方法去通知属性变化，另外一种就是ObservableFields了。

那么属性监听是个什么鬼。当我们使用mvvm的时候，严格来讲，vm层和view层是隔离的，在google的android-architecture中，有这么一句话。
>In the MVVM architecture, Views react to changes in the ViewModel without being explicitly called. 

也就是说，viewmodel这一层中，并不能有显示的view调用，那么，有一些viewmodel无法反应到UI变化的业务场景怎么办，比如Toast、Snackbar之类的。这时候就需要用属性监听了。

viewmodel这一层声明一个变量。

```
public final ObservableField<Student> toastStr = new ObservableField<>();
```

然后，在Activity中。

```
        mViewModel.toastStr.addOnPropertyChangedCallback(new Observable.OnPropertyChangedCallback() {
            @Override
            public void onPropertyChanged(Observable sender, int propertyId) {
                Toast.makeText(MainActivity.this, mViewModel.toastStr.get(), Toast.LENGTH_SHORT).show();
            }
        });
```


### RecyclerView中使用

举个例子

```
public class RecyclerViewAdapter extends android.support.v7.widget.RecyclerView.Adapter<RecyclerViewAdapter.ViewHolder> {

    private Context context;
    private ObservableArrayList<User> users;

    public RecyclerViewAdapter(Context context, ObservableArrayList<User> users) {
        this.context = context;
        this.users = users;
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        ItemRecyclerBinding binding = DataBindingUtil.inflate(LayoutInflater.from(context),
                R.layout.item_recycler, parent, false);
        return new ViewHolder(binding);
    }

    @Override
    public void onBindViewHolder(ViewHolder holder, int position) {
        holder.dataBinding.setVariable(BR.user, users.get(position));
        holder.dataBinding.executePendingBindings();
    }

    @Override
    public int getItemCount() {
        return users.size();
    }

    public class ViewHolder<T extends ViewDataBinding> extends RecyclerView.ViewHolder {
        private T dataBinding;

        public ViewHolder(T dataBinding) {
            super(dataBinding.getRoot());
            this.dataBinding = dataBinding;
        }
    }
}
```

并不是有很大的难度，大家都看得明白。这里就不做过多解释。说下如何绑定数据把。

```
    @BindingAdapter("data")
    public void setData(final RecyclerView recyclerView, ObservableArrayList<Object> objects) {
        objects.addOnListChangedCallback(new ObservableList.OnListChangedCallback<ObservableList<Object>>() {
            @Override
            public void onChanged(ObservableList<Object> sender) {
                recyclerView.getAdapter().notifyDataSetChanged();
            }

            @Override
            public void onItemRangeChanged(ObservableList<Object> sender, int positionStart, int itemCount) {
                recyclerView.getAdapter().notifyItemRangeChanged(positionStart, itemCount);
            }

            @Override
            public void onItemRangeInserted(ObservableList<Object> sender, int positionStart, int itemCount) {
                recyclerView.getAdapter().notifyItemRangeInserted(positionStart, itemCount);
            }

            @Override
            public void onItemRangeMoved(ObservableList<Object> sender, int fromPosition, int toPosition, int itemCount) {
                recyclerView.getAdapter().notifyItemMoved(fromPosition, toPosition);
            }

            @Override
            public void onItemRangeRemoved(ObservableList<Object> sender, int positionStart, int itemCount) {
                recyclerView.getAdapter().notifyItemRangeRemoved(positionStart, itemCount);
            }
        });
    }
```

像这样，就能够绑定数据了，这样，我们的数据变化，我们也不需要显示的调用相应的notify方法，但是这里还有个问题就是，我用了OnListChangedCallback之后，clear数据，再添加，recyclerview会闪烁，原因，还没找出来，惭愧。

### 最近访客
<ul class="ds-recent-visitors" data-num-items="46" data-avatar-size="40"></ul>