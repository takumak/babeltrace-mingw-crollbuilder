#!/bin/sh

set -xe

cd $(dirname $0)

ROOT=$(pwd)
SRCDIR_CROSSTOOL_NG="$ROOT"/src/crosstool-ng
SRCDIR_GLIB="$ROOT"/src/glib
SRCDIR_BT2="$ROOT"/src/babeltrace
BUILDDIR="$ROOT"/_build
BUILDDIR_MINGW="$BUILDDIR"/mingw
BUILDDIR_GLIB="$BUILDDIR"/glib
BUILDDIR_BT2="$BUILDDIR"/babeltrace
PREFIX="$ROOT"/_target

export PKG_CONFIG_PATH="$PREFIX"/lib/pkgconfig
export ACLOCAL_PATH="$PREFIX"/share/aclocal
export WINEPATH="$PREFIX"/bin

## ct-ng
CT_NG="$SRCDIR_CROSSTOOL_NG"/ct-ng
if [ ! -f "$CT_NG" ]; then
  (
    cd "$SRCDIR_CROSSTOOL_NG"
    git reset --hard
    git clean -dfx
    ./bootstrap
    ./configure --enable-local
    make -j4
  )
fi
export CT_PREFIX="$BUILDDIR"

## i686-w64-mingw32
export PATH="$CT_PREFIX"/i686-w64-mingw32/bin:"$PATH"
CROSS_COMPILE="$CT_PREFIX"/i686-w64-mingw32/bin/i686-w64-mingw32-
if [ ! -f "$CROSS_COMPILE"gcc ]; then
  mkdir -p "$BUILDDIR_MINGW"
  cp ct-ng_i686-w64-mingw32_defconfig "$BUILDDIR_MINGW"/defconfig
  (
    cd "$BUILDDIR_MINGW"
    "$CT_NG" defconfig
    "$CT_NG" build
  )
fi

## glib
if [ ! -f "$PREFIX"/bin/libglib-2.0-0.dll ]; then
  (
    cd "$SRCDIR_GLIB"
    git reset --hard
    git clean -dfx
  )
  (
    rm -rf "$BUILDDIR_GLIB"
    mkdir -p "$BUILDDIR_GLIB"
    cd "$BUILDDIR_GLIB"
    meson						\
      --default-library both				\
      --cross-file "$ROOT"/meson_i686-w64-mingw32.txt	\
      --prefix="$PREFIX"				\
      -Dinternal_pcre=true				\
      .							\
      "$SRCDIR_GLIB"

    ninja install
  )
fi

## babeltrace
if [ ! -f "$PREFIX"/bin/babeltrace.exe ]; then
  (
    cd "$SRCDIR_BT2"
    git reset --hard
    git clean -dfx
    ./bootstrap
    sed -i -e '/^babeltrace2_bin_LDADD/s/ -liconv / /' \
      src/cli/Makefile.am
  )

  (
    mkdir -p "$BUILDDIR_BT2"
    cd "$BUILDDIR_BT2"
    "$SRCDIR_BT2"/configure \
      --host=i686-w64-mingw32 \
      --prefix="$PREFIX" \
      --disable-man-pages
    make install
  )
fi
