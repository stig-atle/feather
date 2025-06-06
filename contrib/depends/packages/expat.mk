package=expat
$(package)_version=2.7.1
$(package)_download_path=https://github.com/libexpat/libexpat/releases/download/R_$(subst .,_,$($(package)_version))/
$(package)_file_name=$(package)-$($(package)_version).tar.gz
$(package)_sha256_hash=0cce2e6e69b327fc607b8ff264f4b66bdf71ead55a87ffd5f3143f535f15cfa2
$(package)_build_subdir=build

define $(package)_set_vars
  $(package)_config_opts := -DEXPAT_BUILD_TOOLS=OFF
  $(package)_config_opts += -DEXPAT_BUILD_EXAMPLES=OFF
  $(package)_config_opts += -DEXPAT_BUILD_TESTS=OFF
  $(package)_config_opts += -DBUILD_SHARED_LIBS=OFF
  $(package)_config_opts += -DCMAKE_POSITION_INDEPENDENT_CODE=ON
endef

define $(package)_config_cmds
  $($(package)_cmake) -S .. -B .
endef

define $(package)_build_cmds
  $(MAKE)
endef

define $(package)_stage_cmds
  $(MAKE) DESTDIR=$($(package)_staging_dir) install
endef

define $(package)_postprocess_cmds
  rm -rf share lib/cmake
endef
