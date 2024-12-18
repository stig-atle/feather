package=zlib
$(package)_version=1.3.1
$(package)_download_path=https://github.com/madler/zlib/releases/download/v$($(package)_version)/
$(package)_file_name=$(package)-$($(package)_version).tar.xz
$(package)_sha256_hash=38ef96b8dfe510d42707d9c781877914792541133e1870841463bfa73f883e32
$(package)_patches=win-lib-name.patch

define $(package)_preprocess_cmds
  patch -p1 < $($(package)_patch_dir)/win-lib-name.patch
endef

define $(package)_config_cmds
  $($(package)_cmake) -DBUILD_SHARED_LIBS=OFF -DZLIB_BUILD_EXAMPLES=OFF
endef

define $(package)_build_cmds
  $(MAKE)
endef

define $(package)_stage_cmds
  $(MAKE) DESTDIR=$($(package)_staging_dir) install
endef

define $(package)_postprocess_cmds
  rm -f lib/libz.so* lib/libz.dll* && \
  rm -rf bin
endef
