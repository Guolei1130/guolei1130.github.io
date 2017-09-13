
* autoconf  brew install autoconf
* autom4te
* autoheader
* automake  brew install automake
* aclocal
* libtoolize  brew install libtool
* gun m4

等等

buildconf

* 检查版本


#### 编译openssl静态库

像openssl这种三方库，如果我们想要在android中运行，我们需要先生成静态链接库，然后在链接到我们的native库中。那么如何生成对应的静态链接库呢。

##### 生成交叉工具链

交叉工具链这里，[文档在这里](https://developer.android.google.cn/ndk/guides/standalone_toolchain.html)

具体的介绍这里不说了。看下我的步骤

```
#首先终端进入NDK目录

cd /Users/guolei/Library/Android/sdk/ndk-bundle

#接着进入build/tools目录
cd build/tools

#生成交叉工具链

默认的，ndk的toolchain目录下是有预编译好的工具链的，但是为了灵活，我们自己生成。

./make-standalone-toolchain.sh \
--arch=arm --platform=android-21 --install-dir=/Users/guolei/my-android-toolchain

```

这样，就生成的交叉工具链。


##### 下载编译openssl

这里，我选择下载github源码。

```
#克隆源码
git clone xx

#配置环境变量
export TOOLCHAIN=/Users/guolei/my-android-toolchain
export CROSS_SYSROOT=$TOOLCHAIN/sysroot
export PATH=$TOOLCHAIN/bin:$PATH
export TOOL=arm-linux-androideabi
export CC=$TOOLCHAIN/bin/${TOOL}-gcc
export CXX=$TOOLCHAIN/bin/${TOOL}-g++
export LINK=${CXX}
export LD=$TOOLCHAIN/bin/${TOOL}-ld
export AR=$TOOLCHAIN/bin/${TOOL}-ar
export RANLIB=$TOOLCHAIN/bin/${TOOL}-ranlib
export STRIP=$TOOLCHAIN/bin/${TOOL}-strip
export ARCH_FLAGS="-mthumb"
export ARCH_LINK=
export CFLAGS="${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64"
export CXXFLAGS="${CFLAGS} -frtti -fexceptions"
export LDFLAGS="${ARCH_LINK}"


```

上面配置的环境变量只是临时的，大家需要改的地方就是TOOLCHAIN，这个根据你自己的toolchain路径写好就好，如果想长期有效，那么就把上面的内容写入到.bash_profile文件中。

```
make -j4
make install
```

经过场面之后，就在/Users/guolei/my-android-toolchain/sysroot/usr/local/lib 目录下就生成了libcrtpto.a 和libssl.a两个静态文件。



[参考文件](http://fucknmb.com/2017/05/24/openssl-NDK%E4%BA%A4%E5%8F%89%E7%BC%96%E8%AF%91/)